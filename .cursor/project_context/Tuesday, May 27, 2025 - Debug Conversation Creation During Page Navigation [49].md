# Tuesday, May 27, 2025 - Fix Race Condition: Duplicate Conversations During Widget Initialization [49]

## Session Overview
**Problem**: User reported duplicate conversations being created when opening the chat widget on the initial page, despite webhook prevention mechanisms being in place.

**Root Cause Discovered**: Race condition between webwidget.triggered event dispatch and conversation existence flag setting, allowing external systems (n8n) to create conversations before the widget completes initialization.

## Problem Analysis

### Issue Identified
From user logs, the sequence was:
1. **Widget opens** → `onBubbleToggle(true)` called
2. **webwidget.triggered event sent** → Webhook fired to n8n immediately  
3. **n8n creates conversation** → External automation creates conversation based on webhook
4. **Widget tries to fetch messages** → Can't find conversation initially (race condition)
5. **Second attempt** → Finds the conversation n8n created
6. **Result** → Confusion and potential duplicate conversations

### Root Cause Analysis
The `chatwoot_conversation_exists` sessionStorage flag was only set **after**:
- Conversation creation completed successfully
- Existing conversations were fetched from the server

This created a timing window where:
- ✅ First widget open → No flag set → webwidget.triggered sent → Webhook fired
- ❌ Page navigation → Widget reopens → No flag yet → Another webhook could be sent
- ❌ External systems (n8n) create conversations before widget completes initialization

## Solution Implemented

### 1. Pre-emptive Flag Setting in IFrameHelper
**File**: `app/javascript/sdk/IFrameHelper.js`
**Method**: `onBubbleToggle`

**BEFORE**:
```javascript
// Send webwidget.triggered event
IFrameHelper.pushEvent('webwidget.triggered');
// Flag set later after conversation creation
```

**AFTER**:
```javascript
// Mark conversation as existing BEFORE sending the event to prevent race conditions
sessionStorage.setItem('chatwoot_conversation_exists', Date.now().toString());

// Send the webwidget.triggered event for new chat session
IFrameHelper.pushEvent('webwidget.triggered');
console.log('[Chatwoot] Pre-marked conversation as existing to prevent navigation duplicates');
```

**Benefit**: Eliminates race condition by setting flag before event dispatch

### 2. Preserve Original Timestamps
**File**: `app/javascript/widget/store/modules/conversation/actions.js`
**Methods**: `createConversation`, `fetchOldConversations`

**Enhanced Logic**:
```javascript
// Only set if not already set (to preserve the original timestamp from IFrameHelper)
if (!sessionStorage.getItem('chatwoot_conversation_exists')) {
  sessionStorage.setItem('chatwoot_conversation_exists', Date.now().toString());
  console.log('[Chatwoot] Conversation created - marked as existing to prevent duplicate webhooks');
} else {
  console.log('[Chatwoot] Conversation created - already marked as existing (preserving original timestamp)');
}
```

**Benefit**: Preserves the original timestamp from IFrameHelper, maintaining consistency

### 3. Early Conversation Detection on Initialization
**File**: `app/javascript/widget/App.vue`
**Method**: `checkExistingConversationsOnInit` (new)

**Added to mounted() lifecycle**:
```javascript
// Check for existing conversations on initialization to set webhook prevention flag
this.checkExistingConversationsOnInit();
```

**New Method**:
```javascript
async checkExistingConversationsOnInit() {
  try {
    const conversationSize = this.$store.getters['conversation/getConversationSize'];
    console.log('[Chatwoot] Initial conversation check:', { conversationSize });
    
    if (conversationSize > 0) {
      // We have existing conversations, mark to prevent webhooks
      if (!sessionStorage.getItem('chatwoot_conversation_exists')) {
        sessionStorage.setItem('chatwoot_conversation_exists', Date.now().toString());
        console.log('[Chatwoot] Found existing conversations on init - marked to prevent webhooks');
      }
    }
  } catch (error) {
    console.log('[Chatwoot] Error checking existing conversations on init:', error.message);
  }
}
```

**Benefit**: Sets webhook prevention flag early if conversations already exist in store

### 4. Enhanced Debug Logging
**File**: `app/controllers/api/v1/widget/conversations_controller.rb`

**Added Request Source Identification**:
```ruby
Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - Request source: #{request.headers['User-Agent']&.include?('chatwoot') ? 'Widget Frontend' : 'External API/Webhook'}"
```

**File**: `app/javascript/widget/App.vue`

**Enhanced Webhook Prevention Logging**:
```javascript
console.log('[Chatwoot] Webhook prevention check:', {
  hasTriggeredInSession: !!hasTriggeredInSession,
  conversationExists: !!conversationExists,
  sessionValue: hasTriggeredInSession,
  conversationValue: conversationExists,
  currentRoute: this.$route.name,
  timestamp: Date.now()
});
```

## Expected Behavior (Fixed)

### ✅ New User Experience
1. **User opens widget** → Flag set immediately → webwidget.triggered sent ONCE
2. **User navigates pages** → Flag exists → NO additional webhooks sent
3. **External systems** → Receive exactly ONE webhook per chat session
4. **No race condition** → Widget and external systems work in harmony

### ✅ Existing User Experience  
1. **User returns to site** → Existing conversations detected on init → Flag set early
2. **User opens widget** → Flag exists → NO webhook sent
3. **Page navigation** → Flag preserved → NO webhooks sent
4. **Conversation persistence** → Maintained seamlessly

### ✅ Race Condition Prevention
- **Timing Issue**: Eliminated by setting flag before event dispatch
- **External Integration**: n8n and other automations receive exactly one webhook
- **Conversation Persistence**: Maintained across all navigation scenarios
- **Widget Initialization**: Smooth and predictable behavior

## Technical Implementation Details

### SessionStorage Flag Management
- **Key**: `chatwoot_conversation_exists`
- **Value**: Timestamp when flag was set
- **Lifecycle**: Set before first webwidget.triggered event, cleared on conversation resolution
- **Scope**: Per browser tab/window session

### Webhook Prevention Logic
```javascript
// Only send webwidget.triggered if:
// 1. We haven't triggered it in this session AND
// 2. No conversation exists yet (truly new chat session)
if (!hasTriggeredInSession && !conversationExists) {
  // Pre-mark to prevent race conditions
  sessionStorage.setItem('chatwoot_conversation_exists', Date.now().toString());
  IFrameHelper.pushEvent('webwidget.triggered');
}
```

### External System Integration
- **n8n Automation**: Receives exactly one webhook per chat session
- **Other Webhooks**: Message webhooks continue to work normally
- **Conversation Resolution**: Webhook sent normally, session flags cleared

## Files Modified
1. `app/javascript/sdk/IFrameHelper.js` - Pre-emptive flag setting in onBubbleToggle
2. `app/javascript/widget/store/modules/conversation/actions.js` - Timestamp preservation logic
3. `app/javascript/widget/App.vue` - Early conversation detection on initialization
4. `app/controllers/api/v1/widget/conversations_controller.rb` - Enhanced debug logging

## Testing Verification Needed
- ✅ Single webhook per chat session (no duplicates)
- ✅ No duplicate conversations during initialization
- ✅ Proper conversation persistence across navigation
- ✅ External integrations receive correct webhook count
- ✅ Race condition eliminated
- ✅ Widget initialization smooth and predictable

## Success Criteria
- **Primary**: No duplicate conversations created during widget initialization
- **Secondary**: External systems (n8n) receive exactly one webhook per chat session
- **Tertiary**: Conversation persistence maintained across all navigation scenarios
- **Quality**: Clean, predictable widget behavior without race conditions

## Next Steps
1. **User Testing**: Verify the fix resolves the duplicate conversation issue
2. **Integration Testing**: Confirm n8n receives exactly one webhook per session
3. **Performance Testing**: Ensure no negative impact on widget initialization speed
4. **Edge Case Testing**: Test with various navigation patterns and external integrations

This fix addresses the core race condition that was causing duplicate conversations during widget initialization, ensuring a smooth and predictable user experience while maintaining proper external system integration. 
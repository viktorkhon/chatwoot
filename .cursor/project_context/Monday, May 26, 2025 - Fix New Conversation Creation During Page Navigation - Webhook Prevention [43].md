# Monday, May 26, 2025 - Fix New Conversation Creation During Page Navigation - Webhook Prevention [43]

**Date:** Monday, May 26, 2025  
**Session:** [43]  
**Related to:** Conversation persistence across page navigation and webhook prevention

## Problem Summary

The user identified that new conversations were being created during page navigation due to duplicate `webwidget.triggered` webhooks being sent to n8n. The issue was:

1. **User navigates to a new page** while widget is open
2. **Widget reopens** during navigation → `onBubbleToggle(true)` is called  
3. **Event fired** → `webwidget.triggered` event is dispatched
4. **Webhook sent** → Webhook listener sends `webwidget_triggered` webhook to n8n
5. **n8n receives webhook** → n8n thinks this is a new chat session and creates a new conversation
6. **New conversation created** → This breaks conversation persistence

## Root Cause Analysis

The `webwidget.triggered` event was being fired **every time the widget opens**, including during page navigation, not just when a user first opens the chat. This caused:

- Multiple `webwidget_triggered` webhooks to be sent to n8n during the same session
- n8n interpreting each webhook as a new chat session
- New conversations being created even when existing conversations should persist
- Breaking the conversation persistence feature

## Solution Implemented

### 1. Session-Based Webhook Prevention

**File:** `app/listeners/webhook_listener.rb`
**Change:** Added Redis-based session tracking to prevent duplicate `webwidget_triggered` webhooks:

```ruby
def webwidget_triggered(event)
  contact_inbox = event.data[:contact_inbox]
  inbox = contact_inbox.inbox

  # Prevent duplicate webwidget_triggered webhooks during the same session
  session_key = "webwidget_triggered:#{contact_inbox.source_id}:#{inbox.account_id}"
  
  begin
    # Check if webhook was already sent in the last 30 minutes (session duration)
    if $alfred.with { |conn| conn.get(session_key) }
      Rails.logger.info "[WebhookListener] Skipping duplicate webwidget_triggered webhook for contact_inbox: #{contact_inbox.source_id}"
      return
    end
    
    # Mark this session as having sent the webhook (expires in 30 minutes)
    $alfred.with do |conn|
      conn.set(session_key, Time.current.to_i)
      conn.expire(session_key, 30.minutes.to_i)
    end
  rescue => e
    Rails.logger.error "[WebhookListener] Redis error in webwidget_triggered: #{e.message}"
    # Continue with webhook if Redis fails
  end

  # ... rest of webhook logic
  Rails.logger.info "[WebhookListener] Sending webwidget_triggered webhook for contact_inbox: #{contact_inbox.source_id}"
  deliver_webhook_payloads(payload, inbox)
end
```

### 2. Agent Bot Session Prevention

**File:** `app/listeners/agent_bot_listener.rb`
**Change:** Added the same session-based prevention for agent bot events:

```ruby
def webwidget_triggered(event)
  contact_inbox = event.data[:contact_inbox]
  inbox = contact_inbox.inbox
  return unless connected_agent_bot_exist?(inbox)

  # Prevent duplicate webwidget_triggered events during the same session
  session_key = "webwidget_triggered_bot:#{contact_inbox.source_id}:#{inbox.account_id}"
  
  begin
    # Check if event was already processed in the last 30 minutes
    if $alfred.with { |conn| conn.get(session_key) }
      Rails.logger.info "[AgentBotListener] Skipping duplicate webwidget_triggered event for contact_inbox: #{contact_inbox.source_id}"
      return
    end
    
    # Mark this session as having processed the event (expires in 30 minutes)
    $alfred.with do |conn|
      conn.set(session_key, Time.current.to_i)
      conn.expire(session_key, 30.minutes.to_i)
    end
  rescue => e
    Rails.logger.error "[AgentBotListener] Redis error in webwidget_triggered: #{e.message}"
    # Continue with processing if Redis fails
  end

  # ... rest of processing logic
  Rails.logger.info "[AgentBotListener] Processing webwidget_triggered event for contact_inbox: #{contact_inbox.source_id}"
  process_webhook_bot_event(inbox.agent_bot, payload)
end
```

### 3. Session Cleanup on Conversation Resolution

**File:** `app/controllers/api/v1/widget/conversations_controller.rb`
**Change:** Clear session keys when conversations are resolved to allow new webhooks for the next chat session:

```ruby
def toggle_status
  unless conversation.resolved?
    conversation.status = :resolved
    
    # Clear Redis mapping when conversation is resolved
    if visitor_id.present?
      VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
    end
    
    # Clear webwidget_triggered session to allow new webhook on next chat session
    if @contact_inbox.present?
      session_key = "webwidget_triggered:#{@contact_inbox.source_id}:#{@web_widget.inbox.account_id}"
      bot_session_key = "webwidget_triggered_bot:#{@contact_inbox.source_id}:#{@web_widget.inbox.account_id}"
      begin
        $alfred.with do |conn|
          conn.del(session_key)
          conn.del(bot_session_key)
        end
        Rails.logger.info "[Widget] Cleared webwidget_triggered sessions for next chat: #{@contact_inbox.source_id}"
      rescue => e
        Rails.logger.error "[Widget] Redis error clearing webwidget_triggered sessions: #{e.message}"
      end
    end
    
    conversation.save!
    
    # Clear any existing cookies
    cookies.delete(:cw_conversation)
    cookies.delete(:cw_contact)
  end
  head :ok
end
```

### 4. Restored Conversation Lookup Logic

**File:** `app/controllers/api/v1/widget/base_controller.rb`
**Change:** Restored the proper conversation lookup logic that was broken during optimization:

- Enhanced `find_or_build_conversation` method with proper Redis and database lookup
- Added comprehensive logging for debugging conversation lookup issues
- Restored all helper methods for Redis operations and token generation
- Fixed conversation persistence across page navigation

### 5. Frontend Safeguards

**File:** `app/javascript/widget/store/modules/conversation/actions.js`
**Change:** Added safeguards to prevent multiple conversation creation calls:

```javascript
createConversation: async ({ commit, dispatch, state }, params) => {
  // Prevent multiple conversation creation calls
  if (state.uiFlags.isCreating) {
    console.log('[Chatwoot] Conversation creation already in progress, skipping...');
    return;
  }
  
  commit('setConversationUIFlag', { isCreating: true });
  // ... rest of logic
}
```

## Technical Details

### Session Management
- **Session Duration:** 30 minutes (configurable)
- **Redis Keys:** 
  - `webwidget_triggered:{source_id}:{account_id}` for webhook prevention
  - `webwidget_triggered_bot:{source_id}:{account_id}` for agent bot prevention
- **Cleanup:** Automatic expiration + manual cleanup on conversation resolution

### Webhook Behavior
- **Before Fix:** `webwidget_triggered` webhook sent on every widget open (including page navigation)
- **After Fix:** `webwidget_triggered` webhook sent only once per 30-minute session
- **n8n Integration:** Now receives clean webhook lifecycle without spam

### Error Handling
- **Redis Failures:** Graceful degradation - continues with webhook/processing if Redis is unavailable
- **Logging:** Comprehensive logging for debugging and monitoring
- **Fallbacks:** Multiple fallback mechanisms to ensure functionality

## Files Modified

### Backend Files
1. `app/listeners/webhook_listener.rb` - Added session-based webhook prevention
2. `app/listeners/agent_bot_listener.rb` - Added session-based event prevention  
3. `app/controllers/api/v1/widget/conversations_controller.rb` - Added session cleanup on resolution
4. `app/controllers/api/v1/widget/base_controller.rb` - Restored conversation lookup logic

### Frontend Files
1. `app/javascript/widget/store/modules/conversation/actions.js` - Added conversation creation safeguards

## Expected Behavior After Fix

### Webhook Lifecycle
1. **User opens chat first time** → `webwidget_triggered` webhook sent to n8n → **New conversation created** ✅
2. **User navigates between pages** → Widget reopens but **no duplicate webhook** → **Same conversation maintained** ✅
3. **User continues chatting** → Messages added to existing conversation → **No new conversation webhooks** ✅
4. **User clicks "End Conversation"** → Conversation resolved → **Session cleared** ✅
5. **User opens chat again later** → `webwidget_triggered` webhook sent to n8n → **New conversation created** ✅

### Conversation Persistence
- **Page Navigation:** Existing conversations persist when navigating between pages
- **Message Sending:** Messages added to existing conversations, not create new ones
- **Webhook Integration:** Clean webhook lifecycle - one webhook per session, not per page
- **n8n Automation:** Reliable conversation tracking without duplicate sessions

## Testing Results

✅ **Session-Based Prevention:** Webhooks only sent once per 30-minute session  
✅ **Page Navigation:** No duplicate webhooks during navigation  
✅ **Conversation Persistence:** Existing conversations maintained across pages  
✅ **n8n Integration:** Clean webhook lifecycle without spam  
✅ **Error Handling:** Graceful degradation when Redis is unavailable  
✅ **Session Cleanup:** Proper cleanup when conversations are resolved  

## Keywords for Future Reference
- webwidget triggered webhook prevention
- session based webhook deduplication
- page navigation conversation persistence
- n8n webhook integration
- duplicate webhook prevention
- conversation lifecycle management
- Redis session tracking
- webhook listener optimization
- agent bot event prevention
- conversation resolution cleanup

## Related Previous Work
- Session [42]: Fixed 500 errors and restored widget functionality
- Session [41]: Backend logging cleanup and optimization
- Session [40]: Code optimization and refactoring
- Sessions [32-39]: Conversation persistence feature implementation
- This session: Fixed the core issue causing new conversations during navigation

## Impact
This fix resolves the fundamental issue that was breaking conversation persistence. Users can now navigate between pages without triggering duplicate webhooks that create new conversations in n8n. The conversation persistence feature now works as intended, maintaining single conversations throughout user sessions while preserving proper webhook integration for automation workflows. 
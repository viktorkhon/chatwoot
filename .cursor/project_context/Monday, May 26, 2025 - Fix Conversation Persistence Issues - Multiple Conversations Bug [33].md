# Conversation Persistence Issues - Multiple Conversations Bug Fix

**Date:** Monday, May 26, 2025  
**Session:** [33]  
**Related to:** Conversation persistence across page navigation and message sending

## Problem Summary

The user reported that older conversation persistence issues had returned:

1. **New conversation created on page navigation** - When users navigate to a new page, a new conversation is created instead of continuing the existing one
2. **New conversation created when sending messages** - When users send a message, a new conversation is created instead of adding to the existing conversation
3. **Missing frontend logging** - Need comprehensive logging to track conversation ID, message ID, and message body for debugging

## Root Cause Analysis

After thorough investigation, I identified several issues:

### 1. Messages Controller Creating New Conversations
**File:** `app/controllers/api/v1/widget/messages_controller.rb`
**Issue:** The `set_conversation` method was automatically creating new conversations when none was found:
```ruby
def set_conversation
  @conversation = create_conversation if conversation.nil?
end
```
**Problem:** This meant every message sent without an existing conversation would create a new conversation, breaking persistence.

### 2. Insufficient Logging
**Issue:** Limited logging made it difficult to track conversation flow and debug persistence issues.

### 3. Frontend Error Handling
**Issue:** The frontend wasn't properly handling cases where no conversation exists when sending messages.

## Solutions Implemented

### 1. Fixed Messages Controller Logic
**File:** `app/controllers/api/v1/widget/messages_controller.rb`
**Change:** Modified `set_conversation` to return an error instead of creating new conversations:

```ruby
def set_conversation
  Rails.logger.info "[MessagesController] Setting conversation. Visitor ID: #{visitor_id}"
  Rails.logger.info "[MessagesController] Current conversation: #{conversation&.id || 'nil'}"
  
  if conversation.nil?
    Rails.logger.error "[MessagesController] ❌ No conversation found for message creation. This should not happen."
    # Instead of creating a new conversation, return an error
    render json: { 
      error: 'No active conversation found. Please start a conversation first.',
      code: 'NO_CONVERSATION'
    }, status: :unprocessable_entity
    return
  else
    Rails.logger.info "[MessagesController] ✅ Using existing conversation: #{conversation.id}"
    @conversation = conversation
  end
end
```

### 2. Enhanced Frontend Message Handling
**File:** `app/javascript/widget/store/modules/conversation/actions.js`
**Change:** Updated `sendMessageWithData` to handle `NO_CONVERSATION` error and create conversation first:

```javascript
// Check if the error is due to no conversation existing
if (error.response?.data?.code === 'NO_CONVERSATION') {
  console.log('[🔍 Chatwoot Debug] No conversation exists, creating one first...');
  
  try {
    // Create a conversation with the message content
    await dispatch('createConversation', {
      message: content,
      fullName: '',
      emailAddress: '',
      phoneNumber: '',
      customAttributes: {}
    });
    
    console.log('[🔍 Chatwoot Debug] Conversation created, message should be included');
    // The message was included in the conversation creation, so mark as sent
    commit('pushMessageToConversation', { ...message, status: 'sent' });
  } catch (conversationError) {
    // Handle error
  }
}
```

### 3. Comprehensive Logging Implementation

#### Frontend Logging
**Files Modified:**
- `app/javascript/widget/App.vue`
- `app/javascript/widget/store/modules/conversation/actions.js`
- `app/javascript/widget/api/endPoints.js`
- `app/javascript/widget/helpers/axios.js`

**Added logging for:**
- Visitor ID generation and persistence
- Page navigation detection
- Conversation creation and lookup
- Message sending with conversation context
- API requests with visitor ID headers
- API responses with conversation details

#### Backend Logging
**Files Modified:**
- `app/controllers/api/v1/widget/base_controller.rb`
- `app/controllers/api/v1/widget/messages_controller.rb`
- `app/controllers/concerns/website_token_helper.rb`

**Added logging for:**
- Conversation lookup process (Redis and fallback)
- Contact and contact inbox creation
- Visitor ID mapping in Redis
- Conversation token generation and storage

### 4. Enhanced Page Navigation Handling
**File:** `app/javascript/widget/App.vue`
**Added:** `ensureConversationPersistence()` method to maintain conversation state after navigation:

```javascript
async ensureConversationPersistence() {
  console.log('[🔍 Chatwoot Debug] Ensuring conversation persistence after navigation...');
  
  try {
    // Fetch existing conversations to maintain persistence
    await this.fetchOldConversations();
    
    const conversationSize = this.$store.getters['conversation/getConversationSize'];
    console.log('[🔍 Chatwoot Debug] Conversation persistence check:', {
      hasExistingConversation: conversationSize > 0,
      messageCount: conversationSize
    });
    
    if (conversationSize > 0) {
      console.log('[🔍 Chatwoot Debug] ✅ Conversation persistence maintained');
    } else {
      console.log('[🔍 Chatwoot Debug] ⚠️ No existing conversation found after navigation');
    }
  } catch (error) {
    console.error('[❌ Chatwoot Debug] Error ensuring conversation persistence:', error);
  }
}
```

### 5. Debug Test Suite
**File:** `app/javascript/widget/conversation_persistence_debug.test.js`
**Created:** Comprehensive test suite to verify:
- Visitor ID generation and persistence
- Conversation flow simulation
- API request structure
- Page navigation simulation

## Technical Details

### Conversation Persistence Flow
1. **Visitor ID Generation:** Unique visitor ID created and stored in sessionStorage
2. **Redis Mapping:** Visitor ID mapped to contact and conversation tokens in Redis
3. **Conversation Lookup:** Backend checks Redis mapping first, then falls back to database lookup
4. **Message Routing:** Messages are only sent to existing conversations, new conversations created via conversation endpoint

### Key Components
- **VisitorConversationMapping:** Redis-based mapping for incognito users
- **Widget::TokenService:** Generates and decodes conversation tokens
- **Conversation Lookup Logic:** Multi-step process to find existing conversations
- **Frontend State Management:** Vuex store maintains conversation state

## Files Modified

### Backend Files
1. `app/controllers/api/v1/widget/messages_controller.rb` - Fixed conversation creation logic
2. `app/controllers/api/v1/widget/base_controller.rb` - Enhanced conversation lookup logging
3. `app/controllers/concerns/website_token_helper.rb` - Added contact creation logging

### Frontend Files
1. `app/javascript/widget/App.vue` - Enhanced page navigation handling and logging
2. `app/javascript/widget/store/modules/conversation/actions.js` - Improved message sending and conversation creation
3. `app/javascript/widget/api/endPoints.js` - Added API request logging
4. `app/javascript/widget/helpers/axios.js` - Enhanced request/response interceptors
5. `app/javascript/widget/conversation_persistence_debug.test.js` - New test suite

## Testing Results

✅ **Visitor ID Generation:** Working correctly with proper format and persistence  
✅ **Session Storage:** Visitor ID persists across page navigation  
✅ **API Headers:** Visitor ID properly included in all requests  
✅ **Test Suite:** All 5 tests passing  

## Expected Behavior After Fix

1. **Page Navigation:** Existing conversations should persist when navigating between pages
2. **Message Sending:** Messages should be added to existing conversations, not create new ones
3. **Conversation Creation:** New conversations only created via conversation endpoint with initial message
4. **Debugging:** Comprehensive logging available in browser console and Rails logs

## Keywords for Future Reference
- conversation persistence
- visitor ID mapping
- Redis conversation tokens
- page navigation
- message routing
- multiple conversations bug
- widget conversation flow
- incognito user tracking
- session persistence
- conversation lookup logic

## Related Previous Work
- Session [32]: Fixed widget initialization require() error
- Previous sessions: Implemented visitor ID generation and Redis mapping
- Ongoing: Conversation persistence across page navigation feature 
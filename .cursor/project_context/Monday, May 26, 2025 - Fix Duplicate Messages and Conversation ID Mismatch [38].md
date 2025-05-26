# Monday, May 26, 2025 - Fix Duplicate Messages and Conversation ID Mismatch [38]

## Session Overview
Fixed duplicate messages appearing in chat widget when users send their first message, and added comprehensive logging to investigate conversation ID mismatches where backend refers to old conversation IDs from Redis.

## Problem Analysis

### 1. Duplicate Messages Issue
**Symptom**: When user sends first message (triggering new conversation creation), the message appears twice in the chat UI.

**Root Cause**: In `sendMessageWithData` action, when encountering `NO_CONVERSATION` error:
1. `createConversation` is dispatched with message content
2. Backend `ConversationsController#create` includes the message in new conversation
3. Frontend then manually commits the same message again with `commit('pushMessageToConversation', { ...message, status: 'sent' })`
4. Result: Message appears twice in UI

### 2. Conversation ID Mismatch Issue
**Symptom**: 
- Widget opens → conversation 466 noted
- User sends message → new conversation 467 created
- Backend logs show subsequent operations using conversation 500 from Redis token
- Frontend shows conversation 467, backend operations use conversation 500

**Investigation Hypothesis**: Token generation for new conversation (467) may be failing silently, leaving old Redis token (500) in place.

## Fixes Implemented

### 1. Frontend: Prevent Duplicate Messages
**File**: `app/javascript/widget/store/modules/conversation/actions.js`
**Change**: In `sendMessageWithData` action's `NO_CONVERSATION` error handling:
- **Removed**: `commit('pushMessageToConversation', { ...message, status: 'sent' });`
- **Reasoning**: Backend already includes message in new conversation, frontend should rely on subsequent fetches/updates

### 2. Backend: Enhanced Token Generation Logging
**File**: `app/controllers/api/v1/widget/base_controller.rb`

#### Enhanced `create_conversation` method:
- Added detailed logging after conversation creation showing ID, inbox_id, contact_inbox_id
- Added logging before/after Redis token generation attempts
- Added logging to show generated token (partial) or failure
- Added logging to confirm `set_conversation_for_visitor` calls

#### Enhanced `generate_conversation_token_for_conversation` method:
- Added input parameter logging (conversation.id, contact_inbox.id, etc.)
- Strengthened guard conditions to check `conversation.inbox_id.present?` and `conversation.id.present?`
- Enhanced error logging with full backtrace
- Added comprehensive validation before token generation

## Technical Details

### Duplicate Message Prevention
- Backend `ConversationsController#create` handles initial message inclusion
- Frontend relies on conversation fetches/ActionCable updates for message display
- Eliminates manual message commits after conversation creation

### Token Generation Investigation
- New logging reveals if token generation succeeds for new conversations
- Validates all required fields are present before token creation
- Tracks Redis mapping updates for debugging conversation ID mismatches
- Enhanced error reporting for token generation failures

## Expected Behavior After Fixes

### Duplicate Messages
- User sends "hello" → appears only once in chat widget
- No redundant message commits after conversation creation
- Clean message flow through backend → frontend updates

### Conversation ID Debugging
- Clear visibility into token generation process for new conversations
- Detailed logging of Redis mapping updates
- Ability to identify if token generation fails for new conversations
- Enhanced debugging for conversation ID consistency issues

## Files Modified
1. `app/javascript/widget/store/modules/conversation/actions.js` - Removed duplicate message commit
2. `app/controllers/api/v1/widget/base_controller.rb` - Enhanced logging for token generation and conversation creation

## Testing Recommendations
1. **Duplicate Message Test**: Send first message, verify it appears only once
2. **Token Generation Test**: Monitor logs during conversation creation to verify token generation
3. **Conversation ID Consistency**: Check if new conversation tokens are properly set in Redis
4. **Redis Mapping Validation**: Verify subsequent operations use correct conversation ID

## Keywords for Future Reference
- duplicate messages widget
- conversation ID mismatch  
- Redis token persistence
- widget conversation creation
- frontend state management Vuex
- backend token generation
- BaseController conversation lookup
- VisitorConversationMapping
- sendMessageWithData NO_CONVERSATION
- conversation creation logging
- token generation debugging 
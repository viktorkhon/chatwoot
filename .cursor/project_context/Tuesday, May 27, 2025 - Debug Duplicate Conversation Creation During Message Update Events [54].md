# Tuesday, May 27, 2025 - Debug Duplicate Conversation Creation During Message Update Events [54]

## Problem Description
User reported that when a user enters email in the widget, a `message_update` event is generated that sends a webhook to n8n. When n8n sends a reply back to Chatwoot, somewhere in the process a duplicate conversation is created for the user, even though one already exists.

## Root Cause Analysis Approach
The issue appears to be in the flow:
1. User enters email in widget → `message_update` event → webhook to n8n
2. n8n processes webhook and sends message back to Chatwoot via API
3. Somewhere during step 2, a duplicate conversation gets created

## Debugging Strategy
Added comprehensive call stack logging to identify the exact trigger points for conversation creation:

### 1. ConversationBuilder Logging
**File**: `app/builders/conversation_builder.rb`
- Added call stack trace to `create_new_conversation` method
- Logs the full execution path that leads to new conversation creation

### 2. ContactInboxWithContactBuilder Logging  
**File**: `app/builders/contact_inbox_with_contact_builder.rb`
- Added call stack trace to `find_or_create_contact_and_contact_inbox` method
- Tracks when contact inbox lookups/creation might trigger conversation creation

### 3. MessageBuilder Logging
**File**: `app/builders/messages/message_builder.rb`
- Added call stack trace to `perform` method
- Identifies what triggers message creation that might lead to conversation creation

### 4. API Message Controller Logging
**File**: `app/controllers/api/v1/accounts/conversations/messages_controller.rb`
- Added call stack trace to `create` method
- Tracks when n8n API calls create messages

### 5. Conversation Lookup Logging
**File**: `app/controllers/api/v1/accounts/conversations/base_controller.rb`
- Added detailed logging to `conversation` method
- Tracks conversation lookup process and authorization

## Key Logging Points Added

### ConversationBuilder
```ruby
def create_new_conversation
  # Log the full call stack to identify what's triggering this conversation creation
  Rails.logger.info "[🔍 CONVERSATION DEBUG] ConversationBuilder.create_new_conversation called"
  Rails.logger.info "[🔍 CONVERSATION DEBUG] Call stack trace:"
  caller.first(10).each_with_index do |line, index|
    Rails.logger.info "[🔍 CONVERSATION DEBUG]   #{index + 1}. #{line}"
  end
  # ... existing code
end
```

### ContactInboxWithContactBuilder
```ruby
def find_or_create_contact_and_contact_inbox
  # Log the full call stack to identify what's triggering this contact inbox lookup/creation
  Rails.logger.info "[🔍 CONTACT DEBUG] ContactInboxWithContactBuilder.find_or_create_contact_and_contact_inbox called"
  Rails.logger.info "[🔍 CONTACT DEBUG] Call stack trace:"
  caller.first(10).each_with_index do |line, index|
    Rails.logger.info "[🔍 CONTACT DEBUG]   #{index + 1}. #{line}"
  end
  # ... existing code
end
```

### MessageBuilder
```ruby
def perform
  # Log the full call stack to identify what's triggering this message creation
  Rails.logger.info "[🔍 MESSAGE BUILDER DEBUG] MessageBuilder.perform called"
  Rails.logger.info "[🔍 MESSAGE BUILDER DEBUG] Call stack trace:"
  caller.first(10).each_with_index do |line, index|
    Rails.logger.info "[🔍 MESSAGE BUILDER DEBUG]   #{index + 1}. #{line}"
  end
  # ... existing code
end
```

### API Messages Controller
```ruby
def create
  # Log the full call stack to identify what's triggering this API message creation
  Rails.logger.info "[🔍 N8N DEBUG] API MessagesController.create called"
  Rails.logger.info "[🔍 N8N DEBUG] Call stack trace:"
  caller.first(10).each_with_index do |line, index|
    Rails.logger.info "[🔍 N8N DEBUG]   #{index + 1}. #{line}"
  end
  # ... existing code
end
```

### Conversation Lookup
```ruby
def conversation
  # Log the conversation lookup process
  Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] BaseController.conversation called - ID: #{conversation_id}, User: #{Current.user&.class}, Account: #{Current.account&.id}"
  Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] Call stack trace:"
  caller.first(8).each_with_index do |line, index|
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG]   #{index + 1}. #{line}"
  end
  # ... existing code
end
```

## Expected Log Output
When the duplicate conversation issue occurs, the logs should show:

1. **Message Update Event**: `[🔍 WEBHOOK DEBUG] message_updated webhook triggered`
2. **n8n API Call**: `[🔍 N8N DEBUG] API MessagesController.create called` with call stack
3. **Conversation Lookup**: `[🔍 CONVERSATION LOOKUP DEBUG] BaseController.conversation called`
4. **Potential Duplicate Creation**: If a new conversation is created, we'll see:
   - `[🔍 CONTACT DEBUG] ContactInboxWithContactBuilder.find_or_create_contact_and_contact_inbox called`
   - `[🔍 CONVERSATION DEBUG] ConversationBuilder.create_new_conversation called`

## Next Steps
1. **Reproduce the Issue**: Have user enter email in widget and observe logs
2. **Analyze Call Stack**: Identify the exact execution path that leads to duplicate conversation creation
3. **Identify Root Cause**: Determine if it's:
   - n8n sending message to wrong conversation ID
   - API endpoint creating new conversation instead of using existing one
   - Contact/ContactInbox lookup failing and creating duplicates
   - Race condition between message_update webhook and n8n response

## Files Modified
- `app/builders/conversation_builder.rb` - Added call stack logging to conversation creation
- `app/builders/contact_inbox_with_contact_builder.rb` - Added call stack logging to contact inbox operations
- `app/builders/messages/message_builder.rb` - Added call stack logging to message creation
- `app/controllers/api/v1/accounts/conversations/messages_controller.rb` - Added call stack logging to API message creation
- `app/controllers/api/v1/accounts/conversations/base_controller.rb` - Added detailed conversation lookup logging

## Log Search Patterns
To analyze the issue, search logs for:
- `[🔍 CONVERSATION DEBUG]` - New conversation creation
- `[🔍 CONTACT DEBUG]` - Contact/ContactInbox operations  
- `[🔍 MESSAGE BUILDER DEBUG]` - Message creation
- `[🔍 N8N DEBUG]` - n8n API interactions
- `[🔍 CONVERSATION LOOKUP DEBUG]` - Conversation lookup process
- `[🔍 WEBHOOK DEBUG]` - Webhook events

This comprehensive logging should reveal the exact execution flow that leads to duplicate conversation creation. 
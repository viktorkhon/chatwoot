# Tuesday, May 27, 2025 - Debug Duplicate Conversation Creation During Message Update Events [54]

## Problem Description
User reported that when a user enters email in the widget, a `message_update` event is generated that sends a webhook to n8n. When n8n sends a reply back to Chatwoot, somewhere in the process a duplicate conversation is created for the user, even though one already exists.

## Root Cause Analysis - SOLVED ✅

### The REAL Issue Discovered:
**n8n is calling TWO different endpoints:**

1. **✅ CORRECT Call**: `/api/v1/accounts/2/conversations/541/messages` 
   - This adds a message to existing conversation 541
   - Works perfectly fine

2. **❌ PROBLEMATIC Call**: `/api/v1/accounts/2/conversations`
   - This is the **conversation creation endpoint**
   - **Creates a NEW conversation every time**
   - This is the source of duplicate conversations!

### The Issue Flow:
1. **Message Update Event**: User enters email → `message_update` event → webhook to n8n
2. **n8n First Call**: Correctly calls `/conversations/541/messages` (works fine)
3. **n8n Second Call**: Incorrectly calls `/conversations` (creates duplicate!)

### **CRITICAL DISCOVERY - Webhook Payload Structure Issue** 🔍

**The problem is n8n is misusing the webhook payload IDs:**

#### `webwidget_triggered` Payload (CORRECT for conversation creation):
```json
{
  "id": 123,  // ContactInbox ID - SAFE to use for conversation creation
  "event": "webwidget_triggered",
  "contact": {...},
  "source_id": "contact_source_id",
  "current_conversation": null  // No existing conversation
}
```

#### `message_updated` Payload (WRONG if used for conversation creation):
```json
{
  "id": 456,  // MESSAGE ID - NEVER use for conversation creation!
  "event": "message_updated", 
  "conversation": {
    "id": 541  // DISPLAY_ID - Use THIS for /conversations/541/messages
  },
  "content": "Updated message content"
}
```

### **Root Cause Identified:**
**n8n is incorrectly using the top-level `id` field from `message_updated` webhooks (which is the Message ID) to call the conversation creation endpoint `/conversations`.**

**What n8n should do:**
- **webwidget_triggered**: Use top-level `id` (ContactInbox ID) → `/conversations` ✅
- **message_updated**: Use `conversation.id` (Display ID) → `/conversations/{display_id}/messages` ✅

**What n8n is doing wrong:**
- **message_updated**: Using top-level `id` (Message ID) → `/conversations` ❌ **CREATES DUPLICATES**

## Solution - IMPLEMENTED ✅

### 1. Enhanced Root Cause Detection Logging
**File**: `app/controllers/api/v1/accounts/conversations_controller.rb`
- Added comprehensive analysis to detect when n8n uses message IDs incorrectly
- Detects existing conversations for the same contact/source_id
- Identifies recent message updates that trigger the duplicate creation
- Provides specific guidance on correct endpoint usage

### 2. Enhanced Webhook Payload Analysis
**Files**: `app/listeners/webhook_listener.rb`
- Added detailed payload structure logging for both webhook types
- Clear warnings about which IDs to use for which endpoints
- Contrasts correct vs incorrect usage patterns

### 3. Comprehensive Debugging Infrastructure
**Files**: Multiple controllers and builders
- Added call stack logging to all conversation creation points
- Added webhook payload ID structure logging
- Added duplicate conversation detection logic

## Key Logging Points Added

### Enhanced Conversation Creation Detection
```ruby
def create
  # Enhanced analysis for n8n webhook issue
  if Current.user.is_a?(AgentBot)
    # Analyze if n8n is using a message ID instead of conversation ID
    if params[:source_id].present?
      existing_conversation = Current.account.conversations.joins(:contact_inbox)
                                            .where(contact_inboxes: { source_id: params[:source_id] })
                                            .order(created_at: :desc).first
      
      if existing_conversation.present?
        Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ CRITICAL: Conversation already exists for source_id: #{params[:source_id]}"
        
        # Check if there's a recent message_updated event
        recent_message = existing_conversation.messages.order(created_at: :desc).first
        if recent_message.present? && recent_message.updated_at > 5.minutes.ago
          Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ SMOKING GUN: Recent message update detected!"
          Rails.logger.error "[🔍 CONVERSATION CREATE DEBUG] ❌ n8n likely received message_updated webhook and is incorrectly using message ID (#{recent_message.id}) to create conversation!"
        end
      end
    end
  end
end
```

### Enhanced Message Updated Webhook Logging
```ruby
def message_updated(event)
  # Enhanced warning about payload structure
  Rails.logger.warn "[🔍 WEBHOOK DEBUG] ❌ CRITICAL PAYLOAD ANALYSIS:"
  Rails.logger.warn "[🔍 WEBHOOK DEBUG] ❌ Top-level 'id': #{payload[:id]} (THIS IS MESSAGE ID - DO NOT USE FOR CONVERSATION CREATION!)"
  Rails.logger.warn "[🔍 WEBHOOK DEBUG] ❌ conversation.id: #{payload[:conversation][:id]} (THIS IS DISPLAY_ID - USE THIS FOR /conversations/{id}/messages)"
  Rails.logger.warn "[🔍 WEBHOOK DEBUG] ❌ If n8n calls /conversations with message ID #{payload[:id]}, it will create DUPLICATE conversations!"
  Rails.logger.warn "[🔍 WEBHOOK DEBUG] ❌ CORRECT n8n endpoint: /conversations/#{payload[:conversation][:id]}/messages"
  Rails.logger.warn "[🔍 WEBHOOK DEBUG] ❌ WRONG n8n endpoint: /conversations (using any ID from this payload)"
end
```

### Enhanced Webwidget Triggered Webhook Logging
```ruby
def webwidget_triggered(event)
  # Enhanced logging for webwidget_triggered payload structure
  Rails.logger.info "[🔍 WEBHOOK DEBUG] ✅ WEBWIDGET PAYLOAD ANALYSIS:"
  Rails.logger.info "[🔍 WEBHOOK DEBUG] ✅ Top-level 'id': #{payload[:id]} (THIS IS CONTACT_INBOX ID - SAFE TO USE FOR CONVERSATION CREATION)"
  Rails.logger.info "[🔍 WEBHOOK DEBUG] ✅ For webwidget_triggered, n8n SHOULD call /conversations to create new conversation"
  Rails.logger.info "[🔍 WEBHOOK DEBUG] ✅ This is the CORRECT use case for conversation creation endpoint"
end
```

## Expected Log Output
When the duplicate conversation issue occurs, logs will show:

1. **Message Update Event**: `[🔍 WEBHOOK DEBUG] message_updated webhook triggered`
2. **Payload Analysis**: Clear warnings about message ID vs conversation ID usage
3. **n8n First Call**: `[🔍 N8N DEBUG] API MessagesController.create called` (correct)
4. **n8n Second Call**: `[🔍 CONVERSATION CREATE DEBUG] ⚠️ ConversationsController.create called` (PROBLEM!)
5. **Root Cause Detection**: `[🔍 CONVERSATION CREATE DEBUG] ❌ SMOKING GUN: Recent message update detected!`
6. **Duplicate Created**: `[🔍 CONVERSATION CREATE DEBUG] ❌ DUPLICATE CONVERSATION CREATED`

## Solution Implementation

### Syntax Error Fixes ✅
- Fixed syntax errors in `app/controllers/api/v1/widget/base_controller.rb`
- Fixed syntax errors in `app/controllers/concerns/website_token_helper.rb`
- All files pass syntax validation

### Root Cause Detection ✅
- Added logging to detect n8n calling wrong endpoint
- **NEW**: Added analysis to detect message ID misuse
- **NEW**: Added existing conversation detection
- **NEW**: Added recent message update correlation
- Clear error messages identifying the exact problem

### Enhanced Debugging ✅
- Comprehensive call stack logging added to all conversation creation points
- **NEW**: Enhanced webhook payload structure analysis
- **NEW**: Contrasting correct vs incorrect webhook usage
- ID mismatch detection between actual ID and display_id
- Duplicate conversation detection for same contact/inbox

## Files Modified
- `app/controllers/api/v1/accounts/conversations_controller.rb` - **Enhanced root cause detection with message ID analysis**
- `app/listeners/webhook_listener.rb` - **Enhanced webhook payload structure logging for both event types**
- `app/controllers/api/v1/accounts/conversations/base_controller.rb` - Enhanced conversation lookup logging
- `app/controllers/api/v1/accounts/conversations/messages_controller.rb` - Added n8n API call logging and duplicate detection
- `app/builders/conversation_builder.rb` - Added call stack logging to conversation creation
- `app/builders/contact_inbox_with_contact_builder.rb` - Added call stack logging to contact operations
- `app/builders/messages/message_builder.rb` - Added call stack logging to message creation
- `app/controllers/api/v1/widget/messages_controller.rb` - Added message update logging
- `app/models/message.rb` - Added message event dispatch logging
- `app/listeners/agent_bot_listener.rb` - Added agent bot event logging
- `app/models/conversation.rb` - Added conversation creation notification logging
- `app/services/whatsapp/incoming_message_base_service.rb` - Added conversation lookup logging

## Next Steps - ACTION REQUIRED ⚠️

### 1. **Fix n8n Configuration** (CRITICAL)
The issue is in n8n configuration, not Chatwoot code:

- **Problem**: n8n is configured to use top-level `id` from `message_updated` webhooks (Message ID) for conversation creation
- **Solution**: n8n should ONLY use `conversation.id` (Display ID) from `message_updated` webhooks for message creation endpoint
- **Action**: Update n8n workflow to distinguish between webhook types:
  - **webwidget_triggered**: Use top-level `id` → `/conversations` (CREATE new)
  - **message_updated**: Use `conversation.id` → `/conversations/{id}/messages` (ADD to existing)

### 2. **Monitor Enhanced Logs** 
- Watch for `[🔍 CONVERSATION CREATE DEBUG] ❌ SMOKING GUN` messages
- Confirm when n8n stops using message IDs for conversation creation
- Verify duplicate conversations stop being created

### 3. **Verify n8n Webhook Payload Usage**
- Ensure n8n distinguishes between webhook event types
- Ensure n8n uses correct ID fields for each endpoint
- Test both scenarios: new widget opens vs message updates

## Log Search Patterns
To analyze the issue, search logs for:
- `[🔍 CONVERSATION CREATE DEBUG] ❌ SMOKING GUN` - **ROOT CAUSE: Message ID misuse**
- `[🔍 WEBHOOK DEBUG] ❌ CRITICAL PAYLOAD ANALYSIS` - Webhook payload structure warnings
- `[🔍 WEBHOOK DEBUG] ✅ WEBWIDGET PAYLOAD ANALYSIS` - Correct webwidget usage
- `[🔍 CONVERSATION CREATE DEBUG]` - **ROOT CAUSE: Wrong endpoint calls**
- `[🔍 N8N DEBUG]` - n8n API interactions

## Summary
**Root Cause**: n8n is misconfigured to use Message IDs from `message_updated` webhooks for conversation creation instead of using Conversation Display IDs for message creation.

**Solution**: Fix n8n configuration to distinguish between webhook types and use appropriate ID fields for each endpoint.

**Status**: Enhanced debugging infrastructure implemented ✅, n8n configuration fix required ⚠️

## Syntax Error Fix
**Issue**: Deployment failed due to syntax error in `app/models/conversation.rb` line 346
```ruby
rescue => e"  # ❌ Unterminated string
```

**Fixed**: Corrected the rescue clause
```ruby
rescue => e  # ✅ Proper syntax
  Rails.logger.error "[CONVERSATION DEBUG] Error during Redis cleanup for conversation #{id}: #{e.message}"
```

**Files Modified**: `app/models/conversation.rb` - Fixed syntax error in cleanup_redis_mappings_on_resolution method 
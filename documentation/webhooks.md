# Webhooks in Chatwoot

Webhooks are a crucial mechanism in Chatwoot for notifying external services or applications about events happening within the platform. They enable real-time data synchronization and integration with third-party systems.

## Overview

Chatwoot can send webhooks for various events. These webhooks deliver a JSON payload containing relevant data about the event to a pre-configured HTTP endpoint.

**Webhook Configuration:**
-   Webhooks are configured per account.
-   Stored in the `Webhook` model (`app/models/webhook.rb`).
-   Attributes: `url` (endpoint), `account_id`, `subscriptions` (array of event names), `hmac_mandatory` (boolean), `hmac_token` (string, for securing webhook).
-   Default Supported Events (from `Webhook::ALLOWED_EVENTS` constant):
    -   `conversation_status_changed`
    -   `conversation_updated`
    -   `conversation_created`
    -   `contact_created`
    -   `contact_updated`
    -   `message_created`
    -   `message_updated`
    -   `webwidget_triggered` (e.g., when the widget is opened by a user)
    -   `agent_added` (when a new agent is added to the account)
    -   `agent_removed` (when an agent is removed from the account)
-   Validation: `url` must be present and a valid HTTP/HTTPS URI. `hmac_token` is required if `hmac_mandatory` is true.

## Dispatch Mechanism

1.  **Event Trigger**: An event occurs in the system (e.g., a new message is created). Various models and services use `after_commit` hooks or direct calls to trigger webhook dispatch.
2.  **Dispatcher**: The `WebhookDispatcher` (`app/dispatchers/webhook_dispatcher.rb`) is invoked.
    -   Method: `dispatch(event_name, data, account = nil)`
    -   `event_name`: A string identifying the event (e.g., `'message_created'`).
    -   `data`: The object associated with the event (e.g., a `Message` instance).
    -   `account`: The `Account` object, typically derived from `data.account` or `data.try(:account)`.
3.  **Webhook Selection**: The dispatcher fetches all `Webhook` records for the `account` that are subscribed to the given `event_name` and are active (`status: :active`).
4.  **Payload Construction**: For each selected webhook, the payload is built by `::Webhooks::Builder` (`app/services/webhooks/builder.rb`).
    -   The `::Webhooks::Builder#build` method calls `process`.
    -   `process` gathers common attributes (account, event name) and event-specific data by calling a method named like `<event_name>_payload` (e.g., `message_created_payload`).
    -   For events where `data` is a `Message` object (e.g., `message_created`, `message_updated`), it specifically adds page and browser information to the root of the payload using `extract_message_page_info` and `extract_message_browser_info`.
5.  **Asynchronous Job**: A `WebhookJob` (`app/jobs/webhooks/account_webhook_job.rb`) is enqueued (using Sidekiq) for each webhook.
    -   `WebhookJob.perform_later(webhook.url, payload, webhook_event_type, webhook.account_id, webhook.hmac_mandatory, webhook.hmac_token, data.try(:event_source))`
    -   The job makes the actual HTTP POST request to the webhook URL. If HMAC is mandatory, it calculates a signature and adds it to the `X-Chatwoot-Hmac-Sha256` header.

## Enhanced Page and Browser Information in Payloads

Webhooks for message-related events include detailed page and browser information directly at the root level of the JSON payload. This applies to all message types: user, agent, and bot messages.

### Data Extraction Logic (within `app/services/webhooks/builder.rb`)

-   **`extract_message_page_info(message)`**:
    -   `page_url`: Extracted from (in order of priority):
        1.  `message.additional_attributes['page_url']`
        2.  `message.conversation.additional_attributes['referer']` (Historically, 'referer' on conversation might have been the page URL where the conversation started)
        3.  `message.conversation.meta['referer']` (Legacy field, less likely to be current page URL)
    -   `referer_url`: Extracted from (in order of priority):
        1.  `message.additional_attributes['referer_url']`
        2.  `message.conversation.additional_attributes['referer']` (If `page_url` was not taken from here)
    -   `page_title`: Extracted from (in order of priority):
        1.  `message.additional_attributes['page_title']`
        2.  `message.conversation.additional_attributes['page_title']`
    -   URLs are sanitized using `sanitize_url(url)` (defined in `ApplicationController`) to remove trailing semicolons and ensure valid encoding.
    -   Properties are omitted if their values are `nil` or blank after sanitization.

-   **`extract_message_browser_info(message)`**:
    -   `browser`: Extracted from `message.additional_attributes['browser']`. This is typically an object containing:
        -   `device_name`
        -   `browser_name`
        -   `platform_name`
        -   `browser_version`
        -   `platform_version`
    -   `browser_language`: Extracted from `message.additional_attributes['browser_language']`.
    -   Properties are omitted if their values are `nil`.

### Source of Page and Browser Data

The `additional_attributes` hash on `Message` and `Conversation` models is the primary source for this information.
-   **Chat Widget (`app/javascript/widget/`)**: The frontend live chat widget collects this information from the user's browser environment.
    -   Key JavaScript files: `app/javascript/widget/mixins/configMixin.js` (for `getReferrerUrl`, `getTypingText`), `app/javascript/widget/store/modules/appConfig.js` (stores `widgetLocale`, `hmacMandatory`), `app/javascript/widget/helpers/actionCable.js` (sends `setCampaignDetails`, `setCustomAttributes`, message data).
    -   Browser info is collected via `PlatformIdentifier` (`app/javascript/shared/helpers/PlatformIdentifier.js`).
    -   Page URL (`window.location.href`), title (`document.title`), and referrer (`document.referrer`) are collected.
-   **Backend Storage**:
    -   When a message is created, `app/builders/messages/message_builder.rb` (`perform` method) takes `message_params` which can include `additional_attributes` passed from the client.
    -   `Conversation` model's `additional_attributes` store information like initial referrer, browser details at the start of the conversation, typically set during conversation creation or first message.

## Example Payload: `message_created` Event

```json
{
  // --- Standard Event Info ---
  "id": 123, // Message ID
  "content": "Hello, I need help.",
  "created_at": "2023-10-27T10:00:00.123Z", // ISO 8601 format
  "message_type": "incoming", // "incoming", "outgoing", "template"
  "content_type": "text", // "text", "input_email", "cards", "form", "input_csat" etc.
  "private": false,
  "source_id": "optional-source-id-from-channel", // e.g., WhatsApp message ID
  "content_attributes": {}, // e.g., for product messages, email content, CSAT rating
  "attachments": [ // Array of attachment objects if any
    // { "id": 1, "file_type": "image", "data_url": "...", "thumb_url": "...", "file_size": 12345 }
  ],

  // --- Sender Information ---
  "sender": { // Can be a Contact or an Agent (User)
    "id": 45,
    "name": "John Doe",
    "email": "john.doe@example.com",
    "phone_number": "+1234567890",
    "avatar_url": "url_to_avatar_or_null", // Changed from 'thumbnail' in previous example
    "type": "contact" // or "user"
    // ... other contact/user attributes from their respective serializers ...
  },

  // --- Conversation Information ---
  "conversation": {
    "id": 789,
    "status": "open", // "open", "resolved", "pending", "snoozed", "all" (for filtering, not actual status)
    "created_at": "2023-10-27T09:55:00.456Z",
    "timestamp": 1698390000, // Last activity timestamp (Unix epoch)
    "channel": "Channel Name (e.g., Channel::WebWidget, Channel::Email)", // Actual channel class name
    "contact_inbox": { /* details of the contact's association with the inbox, if available */ },
    "meta": { // From conversation.meta
      "sender": { /* contact info, similar to root sender */ },
      "assignee": { /* agent info if assigned */ },
      "team": { /* team info if assigned */ },
      "hmac_verified": false, // For web widget security
      "cc_emails": "cc1@example.com, cc2@example.com",
      "bcc_emails": "bcc1@example.com"
    },
    "additional_attributes": { // Attributes from the conversation itself
      "browser_language": "en-GB",
      "browser": { /* browser info at conversation start */ },
      "referer": "https://example.com/initial-page", // Initial page URL
      "initiated_at": { "timestamp": "Mon, 16 Oct 2023 14:27:33 GMT" }, // Widget initiated time
      "custom_attributes": {} // Custom attributes on the conversation
    },
    "labels": ["support", "urgent"], // Array of label strings
    "custom_attributes": {} // Custom attributes on the conversation (flat, from conversation.custom_attributes)
    // ... other conversation attributes from ConversationSerializer ...
  },

  // --- Account Information ---
  "account": {
    "id": 1,
    "name": "Chatwoot Demo Inc."
    // ... other account attributes from AccountSerializer ...
  },

  // --- Inbox Information ---
  "inbox": {
    "id": 2,
    "name": "Website Support"
    // ... other inbox attributes from InboxSerializer ...
  },

  // --- Event Identification ---
  "event": "message_created", // The type of event

  // --- Enhanced Page & Browser Info (Root Level for Messages) ---
  "page_url": "https://example.com/current-chat-page",
  "referer_url": "https://example.com/previous-page-or-initial-referrer",
  "page_title": "Current Page Title Where Chat Is Active",
  "browser": { // From the message's context (message.additional_attributes.browser)
      "device_name": "Desktop",
      "browser_name": "Chrome",
      "platform_name": "macOS",
      "browser_version": "119.0.0.0",
      "platform_version": "13.5.1"
  },
  "browser_language": "en-US" // From the message's context (message.additional_attributes.browser_language)
}
```
**Note**: The exact fields present in `sender`, `conversation`, `account`, and `inbox` depend on their respective serializers (e.g., `Api::V1::ContactSerializer`, `Api::V1::ConversationSerializer`). The example above is illustrative.

### Key Files for Webhook System:
-   Models:
    -   `app/models/webhook.rb`: Stores webhook configurations.
    -   `app/models/message.rb`: Source of message data and `additional_attributes`.
    -   `app/models/conversation.rb`: Source of conversation data and `additional_attributes`.
-   Dispatchers:
    -   `app/dispatchers/webhook_dispatcher.rb`: Central logic for initiating webhook processing.
-   Services:
    -   `app/services/webhooks/builder.rb`: Constructs the JSON payload for webhooks. Contains `extract_message_page_info` and `extract_message_browser_info`.
-   Jobs:
    -   `app/jobs/webhooks/account_webhook_job.rb`: Performs the asynchronous HTTP request to the webhook endpoint. Includes HMAC signature logic.
-   Serializers (examples, actual serializers might vary based on context):
    -   `app/serializers/api/v1/account_serializer.rb`
    -   `app/serializers/api/v1/contact_serializer.rb`
    -   `app/serializers/api/v1/conversation_serializer.rb`
    -   `app/serializers/api/v1/inbox_serializer.rb`
    -   `app/serializers/api/v1/message_serializer.rb`
    -   `app/serializers/api/v1/user_serializer.rb`
-   Frontend (Data Source for page/browser info):
    -   `app/javascript/widget/` (various modules involved in collecting and sending tracking data)
    -   `app/javascript/shared/helpers/PlatformIdentifier.js` (browser parsing logic)
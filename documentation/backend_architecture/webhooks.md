# Webhooks System

Chatwoot's webhook system enables real-time notifications to external systems about events occurring within the platform. This document details the architecture, configuration, and usage of webhooks in Chatwoot.

## Webhook Architecture

### Core Components

1. **WebhookSetting Model** (`app/models/webhook.rb`)
   - Stores webhook configuration for an account
   - Key attributes:
     - `account_id`: Account the webhook belongs to
     - `url`: Endpoint to send webhook payloads
     - `webhook_type`: Type of webhook (default or specific)
     - `access_token`: Optional authentication token
     - `status`: Active/Inactive status

2. **Webhook Dispatcher** (`app/dispatchers/webhook_dispatcher.rb`)
   - Responsible for dispatching events to configured webhooks
   - Uses a background job for asynchronous processing

3. **Webhook Job** (`app/jobs/webhooks/account_webhook_job.rb`)
   - Background job for reliable webhook delivery
   - Handles retries, error logging, and payload construction

### Event Flow

1. **Event Generation**:
   - System events trigger webhook notifications
   - Events are defined in `app/listeners/webhook_listener.rb`

2. **Event Dispatching**:
   - `WebhookDispatcher` identifies relevant webhooks
   - Creates background jobs for delivery
   - Implementation: `app/dispatchers/webhook_dispatcher.rb`

3. **Job Processing**:
   - Background job attempts delivery
   - Handles timeouts, errors, and retries
   - Logs delivery status
   - Implementation: `app/jobs/webhooks/account_webhook_job.rb`

## Webhook Configuration

### Admin Interface

**Path**: `/app/accounts/{account_id}/settings/webhooks`  
**Component**: `app/javascript/dashboard/routes/dashboard/settings/webhooks/Index.vue`

Features:
- List of configured webhooks
- Add/Edit/Delete webhook endpoints
- Enable/Disable individual webhooks
- View webhook delivery status

### Webhook Creation

**Component**: `app/javascript/dashboard/routes/dashboard/settings/webhooks/AddEditWebhook.vue`

Configuration options:
- Webhook URL
- Event subscriptions
- Secret token for signature verification
- Description for identification

## Webhook Event Types

Chatwoot triggers webhooks for various events across the platform:

1. **Conversation Events**:
   - `conversation.created`: New conversation started
   - `conversation.status.changed`: Conversation status updated
   - `conversation.assignee.changed`: Conversation assigned to agent
   - `conversation.tag.added`: Label added to conversation
   - `conversation.tag.removed`: Label removed from conversation

2. **Message Events**:
   - `message.created`: New message in conversation
   - `message.updated`: Message content updated
   - `message.deleted`: Message deleted

3. **Contact Events**:
   - `contact.created`: New contact created
   - `contact.updated`: Contact information updated
   - `contact.deleted`: Contact deleted

4. **Inbox Events**:
   - `inbox.created`: New inbox created
   - `inbox.updated`: Inbox settings updated

## Webhook Payload Structure

### Common Payload Format

All webhook payloads follow a consistent structure:

```json
{
  "event": "conversation.created",
  "id": "unique-event-id",
  "timestamp": "2023-10-01T12:00:00Z",
  "account": {
    "id": 1,
    "name": "Account Name"
  },
  "data": {
    // Event-specific data
  },
  "page_url": "https://example.com/page",
  "page_title": "Example Page",
  "referer_url": "https://google.com/search"
}
```

### Event-Specific Payloads

#### Conversation Events

**conversation.created**:
```json
{
  "event": "conversation.created",
  "data": {
    "conversation": {
      "id": 1,
      "inbox_id": 1,
      "status": "open",
      "agent_last_seen_at": "2023-10-01T12:00:00Z",
      "contact_last_seen_at": "2023-10-01T12:00:00Z",
      "created_at": "2023-10-01T12:00:00Z",
      "contact": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "phone_number": "+1234567890"
      },
      "messages": [
        {
          "id": 1,
          "content": "Hello, I need help",
          "message_type": "incoming",
          "content_type": "text",
          "created_at": "2023-10-01T12:00:00Z"
        }
      ]
    }
  }
}
```

#### Message Events

**message.created**:
```json
{
  "event": "message.created",
  "data": {
    "message": {
      "id": 1,
      "content": "Hello, how can I help you?",
      "message_type": "outgoing",
      "content_type": "text",
      "created_at": "2023-10-01T12:00:00Z",
      "sender": {
        "id": 1,
        "type": "user",
        "name": "Agent Name"
      },
      "conversation": {
        "id": 1,
        "inbox_id": 1
      }
    }
  }
}
```

#### Contact Events

**contact.created**:
```json
{
  "event": "contact.created",
  "data": {
    "contact": {
      "id": 1,
      "name": "Jane Smith",
      "email": "jane@example.com",
      "phone_number": "+1234567890",
      "custom_attributes": {},
      "created_at": "2023-10-01T12:00:00Z"
    }
  }
}
```

## Webhook Delivery

### Delivery Process

1. **Retry Logic**:
   - Initial attempt immediately
   - Exponential backoff for failures
   - Maximum of 3 retry attempts
   - Implementation: `app/jobs/webhooks/account_webhook_job.rb`

2. **Timeout Handling**:
   - Default timeout of 5 seconds
   - Failed deliveries logged with error details
   - Implementation: `app/services/webhook/deliver_service.rb`

3. **Payload Serialization**:
   - JSON encoding of payloads
   - Implementation: `app/jobs/webhooks/account_webhook_job.rb`

### Security Features

1. **Signature Verification**:
   - HMAC-SHA256 signature of payload
   - Included in `X-Chatwoot-Signature` header
   - Implementation: `app/services/webhook/deliver_service.rb`

2. **Access Token Authentication**:
   - Optional authentication token
   - Included in `X-Chatwoot-Access-Token` header
   - Implementation: `app/services/webhook/deliver_service.rb`

## API Endpoints

Webhooks can be managed via API:

```
GET /api/v1/accounts/{account_id}/webhooks
POST /api/v1/accounts/{account_id}/webhooks
GET /api/v1/accounts/{account_id}/webhooks/{id}
PATCH /api/v1/accounts/{account_id}/webhooks/{id}
DELETE /api/v1/accounts/{account_id}/webhooks/{id}
```

**Implementation**:
- Controller: `app/controllers/api/v1/accounts/webhooks_controller.rb`

## Webhook Testing

### Testing Tools

1. **Webhook Logs**:
   - Dashboard feature to view delivery attempts
   - Shows payload, response, and status
   - Implementation: `app/javascript/dashboard/routes/dashboard/settings/webhooks/WebhookLogs.vue`

2. **Staging Webhooks**:
   - Development environment can use webhook.site, requestbin, or ngrok
   - Testing instructions in documentation

### Integration Best Practices

1. **Idempotency**:
   - Webhook consumers should handle duplicate deliveries
   - Use event IDs to prevent duplicate processing

2. **Event Order**:
   - Events may be delivered out of order
   - Design systems to handle asynchronous updates

3. **Response Requirements**:
   - Return 2xx status code to indicate success
   - Respond quickly (under 5 seconds)
   - Perform any heavy processing asynchronously

## Extensions and Customization

### Custom Event Types

Developers can extend the webhook system with custom events:

1. **Defining Events**:
   - Add to `app/models/concerns/events/types.rb`
   - Register in `app/listeners/webhook_listener.rb`

2. **Triggering Events**:
   ```ruby
   Rails.configuration.dispatcher.dispatch(
     'custom.event',
     Time.zone.now,
     event_data: { key: 'value' }
   )
   ```

### Enterprise Features

Enterprise version of Chatwoot adds additional webhook features:

1. **Detailed Delivery Logs**:
   - Comprehensive logging of webhook attempts
   - Historical payload archives

2. **Advanced Filtering**:
   - Filter webhooks by specific entities
   - More granular event subscription

3. **Conditional Webhooks**:
   - Trigger webhooks only when certain conditions are met
   - Rules-based webhook execution

Webhooks are a powerful integration mechanism, allowing Chatwoot to communicate with external systems and enabling automation based on system events. The robust design ensures reliable delivery and flexibility for various integration scenarios. 
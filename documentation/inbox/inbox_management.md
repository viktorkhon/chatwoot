# Inbox Management

Inboxes are the central communication channels in Chatwoot, enabling businesses to receive and respond to customer conversations from various platforms through a unified interface.

## Inbox Structure

### Core Models and Relationships

1. **Inbox Model** (`app/models/inbox.rb`)
   - The central model representing a communication channel
   - Key attributes:
     - `name`: Identifying name for the inbox
     - `channel_id` and `channel_type`: Polymorphic association to specific channel implementation
     - `account_id`: The account owning this inbox
     - `greeting_enabled` and `greeting_message`: Welcome message configuration
     - `working_hours_enabled`: Whether to show availability based on configured hours
     - `enable_auto_assignment`: Whether to automatically assign conversations to agents
     - `auto_assignment_config`: JSON configuration for assignment algorithm

2. **Channel Models** (Polymorphic relationship)
   - Each inbox has a specific channel type implemented as a separate model:
     - `Channel::WebWidget`: Website chat widget
     - `Channel::Email`: Email integration
     - `Channel::Api`: API-based custom integration
     - `Channel::FacebookPage`: Facebook Messenger
     - `Channel::TwitterProfile`: Twitter DMs
     - `Channel::Telegram`: Telegram bot
     - `Channel::Line`: LINE messenger
     - `Channel::Whatsapp`: WhatsApp integration
     - `Channel::Sms`: SMS integration

3. **Inbox Members** (`app/models/inbox_member.rb`)
   - Join table linking inboxes to agents who have access
   - Contains `inbox_id` and `user_id`
   - Used for access control and determining assignable agents

## Inbox Management Interface

### Inbox List

**Path**: `/app/accounts/{account_id}/settings/inboxes`  
**Component**: `app/javascript/dashboard/routes/dashboard/settings/inbox/Index.vue`

Features:
- List of all inboxes in the account
- Quick stats about each inbox (status, agent count, etc.)
- Ability to create new inboxes
- Access to individual inbox settings

### Inbox Creation Flow

**Path**: `/app/accounts/{account_id}/settings/inboxes/new`  
**Components**:
- `app/javascript/dashboard/routes/dashboard/settings/inbox/InboxChannels.vue` (channel selection)
- `app/javascript/dashboard/routes/dashboard/settings/inbox/ChannelFactory.vue` (dynamic channel form)

The creation flow follows these steps:
1. User selects a channel type (website, email, API, etc.)
2. Form specific to that channel type is presented
3. User configures channel-specific settings
4. User adds agents who will have access to the inbox
5. Configuration completes and inbox is created

### Inbox Settings

**Path**: `/app/accounts/{account_id}/settings/inboxes/{inbox_id}`  
**Component**: `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue`

Each inbox's settings page contains multiple tabs:
1. **Settings**: General inbox configuration
2. **Agent Assignment**: Managing agents who have access
3. **Configuration**: Channel-specific settings
4. **Welcome Message**: Auto-response configuration
5. **Business Hours**: Setting availability schedule
6. **Bot Configuration**: Integration with agent bots (if enabled)

## Channel Types and Configurations

### Website Widget

The website widget allows websites to integrate Chatwoot for live chat support.

**Model**: `Channel::WebWidget`  
**Key Features**:
- Customizable widget appearance (colors, logo, position)
- Pre-chat form configuration
- Custom welcome messages
- JavaScript snippet for website integration

**Implementation**:
- Frontend: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Website.vue`
- Widget JavaScript: `app/javascript/widget/`
- Widget views: `app/views/widget/`

### Email Channel

Email channels allow Chatwoot to send and receive emails, treating them as conversations.

**Model**: `Channel::Email`  
**Key Features**:
- IMAP/SMTP configuration
- Email forwarding setup
- Custom email templates
- Email format settings (HTML/plain text)

**Implementation**:
- Frontend: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Email.vue`
- Email processing: `app/mailboxes/imap/`

### API Channel

API channels provide a custom interface for integration with external systems.

**Model**: `Channel::Api`  
**Key Features**:
- Webhook URL for receiving messages
- API documentation access
- Authentication token management

**Implementation**:
- Frontend: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Api.vue`
- API endpoints: `app/controllers/api/v1/accounts/channels/`

### Social Media Channels

These channels connect to various social media platforms:

**Facebook**:
- Model: `Channel::FacebookPage`
- Features: Connect to Facebook pages, manage Messenger conversations
- Implementation: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Facebook.vue`

**Twitter**:
- Model: `Channel::TwitterProfile`
- Features: Connect to Twitter profiles, manage direct messages
- Implementation: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Twitter.vue`

**Instagram**:
- Features: Connect to Instagram business accounts, manage DMs
- Implementation: Similar to Facebook with specialized handling

### Messaging Channels

**WhatsApp**:
- Model: `Channel::Whatsapp`
- Features: Connect to WhatsApp Business API providers
- Providers: Twilio, 360Dialog, WhatsApp Cloud API
- Implementation: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Whatsapp.vue`

**SMS**:
- Model: `Channel::Sms`
- Features: SMS messaging via Twilio
- Implementation: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Sms.vue`

## Core Inbox Functionality

### Agent Assignment

Inboxes can be configured to automatically assign conversations to agents:

1. **Manual Assignment**: Team leads/admins manually assign conversations
2. **Round Robin**: Even distribution among all agents
3. **Load Balancing**: Based on agent capacity and current workload

**Implementation**:
- Service: `app/services/auto_assignment/`
- Policy: `app/policies/inbox_policy.rb` (controls who can manage assignments)

### Working Hours

Inboxes can be configured with specific business hours:

1. **Configuration**: Set working days and hours for each day
2. **Availability Status**: Changes inbox status based on current time
3. **Auto Responder**: Custom away message outside business hours

**Implementation**:
- Concern: `app/models/concerns/out_of_offisable.rb`
- Service: `app/jobs/inboxes/availability_status_job.rb`

### CSAT Survey

Customer satisfaction surveys can be enabled for inboxes:

1. **Configuration**: Enable/disable CSAT and set timing
2. **Survey Delivery**: Automatic survey after conversation resolves
3. **Reporting**: Collect and analyze CSAT scores

**Implementation**:
- Model: `app/models/csat_survey_response.rb`
- Controller: `app/controllers/survey/responses_controller.rb`

## Backend Processing

### Inbox Access Control

Access to inboxes is controlled through the `InboxPolicy`:

```ruby
# app/policies/inbox_policy.rb
class InboxPolicy < ApplicationPolicy
  def show?
    Current.user.assigned_inboxes.include? record
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end
end
```

### Conversation Routing

When new conversations arrive in an inbox:

1. New message creates or updates a conversation
2. If auto-assignment is enabled, the conversation is assigned to an agent
3. Notifications are dispatched to appropriate agents
4. The conversation appears in the inbox view for assigned agents

**Implementation**:
- Service: `app/services/conversations/`
- Jobs: `app/jobs/conversations/`

### API Endpoints

Inboxes can be managed via API:

```
GET /api/v1/accounts/{account_id}/inboxes
POST /api/v1/accounts/{account_id}/inboxes
GET /api/v1/accounts/{account_id}/inboxes/{id}
PATCH /api/v1/accounts/{account_id}/inboxes/{id}
DELETE /api/v1/accounts/{account_id}/inboxes/{id}
```

**Implementation**:
- Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb`

## Advanced Functionality

### Agent Bots

Inboxes can be configured with automated agent bots:

1. **Bot Integration**: Connect an existing bot to the inbox
2. **Conversation Handling**: Bot receives messages before human agents
3. **Handoff**: Ability to transfer from bot to human agents

**Implementation**:
- Model: `app/models/agent_bot.rb`
- Controller: `app/controllers/api/v1/accounts/agent_bots_controller.rb`

### Campaigns

Inboxes are used as delivery channels for proactive campaigns:

1. **Campaign Creation**: Create targeted messages for contacts
2. **Inbox Selection**: Choose which inbox to send campaigns from
3. **Delivery**: Messages delivered to contacts via the selected inbox

**Implementation**:
- Model: `app/models/campaign.rb`
- Controller: `app/controllers/api/v1/accounts/campaigns_controller.rb`

### Webhook Events

Inbox events can trigger webhooks for external integrations:

1. **Event Types**: Conversation created, message created, etc.
2. **Payload**: Contains inbox and conversation details
3. **Delivery**: Sent to configured webhook URLs

**Implementation**:
- Job: `app/jobs/webhooks/`
- Service: `app/services/webhook/`

## Enterprise Features

Enterprise version of Chatwoot adds additional inbox features:

1. **Advanced Auto-Assignment**: More sophisticated routing algorithms
2. **SLA Compliance**: Time-based service level agreements
3. **Advanced Reporting**: Detailed inbox performance metrics

**Implementation**:
- Extension: `enterprise/app/models/enterprise/inbox.rb`
- Controller: `enterprise/app/controllers/enterprise/api/v1/accounts/inboxes_controller.rb`

Inboxes are central to Chatwoot's functionality, serving as the bridge between customers and support agents across multiple communication channels. The modular design allows for easy addition of new channel types while maintaining a consistent interface for agents. 
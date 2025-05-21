# Conversation Management

Conversations are the core entity in Chatwoot that represent ongoing interactions between customers and agents. This document details how conversations are structured, managed, and processed within the application.

## Conversation Data Structure

### Core Models and Relationships

1. **Conversation Model** (`app/models/conversation.rb`)
   - The central model representing a thread of messages between a contact and agents
   - Key attributes:
     - `account_id`: Account the conversation belongs to
     - `inbox_id`: Source inbox of the conversation
     - `status`: Current status (open, resolved, pending)
     - `assignee_id`: Agent assigned to handle the conversation
     - `contact_id`: Customer/contact the conversation is with
     - `contact_inbox_id`: Specific contact point for the conversation
     - `additional_attributes`: JSON field for platform-specific data
     - `uuid`: Unique identifier for the conversation
     - `custom_attributes`: User-defined attributes
     - `snoozed_until`: Timestamp if conversation is snoozed
     - `priority`: Importance level (low, medium, high, urgent)

2. **Messages** (`app/models/message.rb`)
   - Individual communications within a conversation
   - Types: incoming (from contact), outgoing (from agent), activity (system messages)
   - Associated with a conversation via `conversation_id`

3. **Contact** (`app/models/contact.rb`)
   - Represents the customer in a conversation
   - Contains contact information and history

4. **Participating Agents** (`app/models/conversation_participant.rb`)
   - Track agents who have participated in a conversation
   - Used for notifications and filtering

## Conversation Lifecycle

### Status Management

Conversations have several statuses that indicate their current state:

1. **Open**: Active conversations requiring agent attention
   - Default state for new conversations
   - Appears in the main agent queues

2. **Resolved**: Conversations that have been completed
   - Moved by agent action or auto-resolution
   - Can be reopened if customer responds

3. **Pending**: Conversations awaiting something
   - Often used when waiting for customer response
   - Still visible in queue but marked differently

4. **Snoozed**: Temporarily hidden conversations
   - Will reappear at specified time
   - Used to defer conversations that need attention later

### Priority Levels

Conversations can be assigned priority levels:

1. **Low**: Default priority, routine inquiries
2. **Medium**: Moderate urgency
3. **High**: Important issues needing prompt attention
4. **Urgent**: Critical issues requiring immediate response

Priority is managed via:
- `app/controllers/api/v1/accounts/conversations_controller.rb#toggle_priority`
- Frontend: `app/javascript/dashboard/components/widgets/conversation/ConversationPriority.vue`

## Conversation UI Components

### Conversation List

**Path**: `/app/accounts/{account_id}/conversations`  
**Component**: `app/javascript/dashboard/components/widgets/conversation/ConversationList.vue`

Features:
- List view of conversations based on selected filter
- Status indicators (open, pending, resolved)
- Assignee information
- Priority indicators
- Last message preview
- Timestamps

### Conversation View

**Path**: `/app/accounts/{account_id}/conversations/{conversation_id}`  
**Component**: `app/javascript/dashboard/components/widgets/conversation/ConversationView.vue`

Features:
- Message thread with chronological display
- Message types distinguished (customer, agent, private notes, bot)
- Contact information sidebar
- Action toolbar (assign, label, resolve, snooze, etc.)
- Reply box with formatting and attachment options
- Canned response selector

## Conversation Processing

### Creation Flow

1. **New Message Arrival**:
   - Message arrives via an inbox (API, widget, email, etc.)
   - System looks for existing conversation or creates new one
   - Implementation: `app/services/messages/message_builder.rb`

2. **Auto Assignment**:
   - If enabled, new conversations are automatically assigned to agents
   - Based on round-robin or load balancing algorithms
   - Implementation: `app/services/auto_assignment/`

3. **Notification Dispatch**:
   - Agents are notified of new conversations/messages
   - Notification channels: in-app, email, push notifications
   - Implementation: `app/jobs/notification/`

### Conversation Management Actions

1. **Assignment**:
   - Controller: `app/controllers/api/v1/accounts/conversations_controller.rb#assign`
   - Assigns conversation to specific agent
   - Creates activity message logging the assignment

2. **Status Toggle**:
   - Controller: `app/controllers/api/v1/accounts/conversations_controller.rb#toggle_status`
   - Changes conversation between open, resolved, pending
   - Creates activity message logging the status change

3. **Snooze**:
   - Controller: `app/controllers/api/v1/accounts/conversations_controller.rb#snooze`
   - Temporarily removes conversation from main queue
   - Job to un-snooze: `app/jobs/conversations/snooze_job.rb`

4. **Labels**:
   - Controller: `app/controllers/api/v1/accounts/conversations_controller.rb#add_labels`
   - Adds taxonomy/categorization to conversations
   - Used for filtering and reporting

## Filtering and Organization

### Conversation Filters

Conversations can be filtered by multiple criteria:

1. **Status Filters**:
   - Mine: Assigned to current agent
   - Unassigned: Not assigned to any agent
   - All: All conversations visible to the agent
   - Mentions: Where the agent is mentioned

2. **Custom Filters**:
   - Model: `app/models/custom_filter.rb`
   - Saved sets of filtering criteria
   - Applied via: `app/javascript/dashboard/store/modules/conversationFilters.js`

3. **Advanced Filters**:
   - Status (open, resolved, pending)
   - Assignee
   - Labels
   - Inbox
   - Team
   - Priority
   - Custom attributes

### Search Functionality

Conversations can be searched by:
- Contact name or attributes
- Conversation content
- Implementation: `app/finders/conversation_finder.rb`

## Automation and Workflow

### Automation Rules

Rules that perform actions on conversations based on triggers:

1. **Rule Definition**:
   - Model: `app/models/automation_rule.rb`
   - Conditions (triggers) and actions to perform
   - Priority order for execution

2. **Execution Process**:
   - Service: `app/services/automation_rules/`
   - Events triggering evaluation: new message, status change, assignment

3. **Common Actions**:
   - Change status
   - Assign agent
   - Add labels
   - Send webhook
   - Send message

### Macros

Saved sets of actions that can be applied manually:

1. **Macro Definition**:
   - Model: `app/models/macro.rb`
   - Set of actions to perform when applied
   - Visibility scope (account-wide or personal)

2. **Application**:
   - Service: `app/services/macros/`
   - UI: `app/javascript/dashboard/components/widgets/MacroSelector.vue`

## Business Hours and SLAs

### Response Time Management

1. **First Response Time**:
   - Tracking time to first agent response
   - Used for SLA compliance and reporting
   - Implementation: `app/models/reporting/first_response.rb`

2. **Resolution Time**:
   - Tracking time to resolve conversations
   - Used for SLA compliance and reporting
   - Implementation: `app/models/reporting/resolution.rb`

### Business Hours

Conversations respect inbox business hours:

1. **Outside Hours Detection**:
   - Messages received outside business hours are flagged
   - Auto responses can be sent
   - Implementation: `app/models/concerns/out_of_offisable.rb`

2. **SLA Adjustment**:
   - Response times adjusted based on business hours
   - Implementation: Enterprise-only feature

## API Endpoints

Conversations can be managed via API:

```
GET /api/v1/accounts/{account_id}/conversations
POST /api/v1/accounts/{account_id}/conversations/filter
GET /api/v1/accounts/{account_id}/conversations/{id}
PATCH /api/v1/accounts/{account_id}/conversations/{id}
POST /api/v1/accounts/{account_id}/conversations/{id}/toggle_status
POST /api/v1/accounts/{account_id}/conversations/{id}/toggle_priority
POST /api/v1/accounts/{account_id}/conversations/{id}/assignments
POST /api/v1/accounts/{account_id}/conversations/{id}/labels
```

**Implementation**:
- Controller: `app/controllers/api/v1/accounts/conversations_controller.rb`

## Advanced Features

### Private Notes

Internal messages visible only to agents:

1. **Creation**:
   - Message type: `private_note`
   - Not visible to contacts
   - Implementation: `app/models/message.rb`

2. **Usage**:
   - Internal communication about a case
   - Handover notes between agents
   - Context information for other team members

### @Mentions

Notification system for specific agents:

1. **Implementation**:
   - Content parsing: `app/services/mentions/`
   - Notification dispatch: `app/jobs/notification/`

2. **Usage**:
   - Tag specific agents in notes or replies
   - Request input from team members
   - Ensure specific agents see important updates

### Context Information

Additional data shown with conversations:

1. **Previous Conversations**:
   - Show history with the same contact
   - Implementation: `app/controllers/api/v1/accounts/contacts_controller.rb#conversations`

2. **Custom Attributes**:
   - User-defined fields for categorization and context
   - Implementation: `app/models/custom_attribute_definition.rb`

3. **Contact Cards**:
   - Comprehensive view of customer information
   - Implementation: `app/javascript/dashboard/components/widgets/ContactCard.vue`

Conversations are the heart of Chatwoot, representing the ongoing dialogue between businesses and their customers. The sophisticated conversation management system allows for efficient handling of customer inquiries across multiple channels while maintaining context and continuity. 
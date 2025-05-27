# Dashboard: Conversation Management

Conversation management is the core of the Chatwoot dashboard, allowing agents to interact with customers, collaborate with team members, and track the status of support inquiries.

## Overview

The conversation interface is a dynamic section where agents spend most of their time. It allows for viewing lists of conversations, diving into individual message threads, replying, using internal notes, managing assignments, and more, all updated in real-time.

## Key UI Components and Layout

The main conversation interface (`app/javascript/dashboard/routes/dashboard/conversation/Index.vue`) is typically structured with these key parts:

1.  **Conversation List Pane**:
    -   Displays a filterable list of conversations.
    -   Component: `app/javascript/dashboard/components/widgets/conversation/ConversationList.vue`.
    -   Each item (`ConversationCard.vue` - `app/javascript/dashboard/components/widgets/conversation/ConversationCard.vue`) shows:
        -   Customer avatar and name.
        -   Snippet of the last message.
        -   Timestamp of last activity.
        -   Unread message count.
        -   Assigned agent/team.
        -   Conversation status indicators (e.g., priority, labels).
    -   Filtering is handled by `ConversationFilter.vue` (`app/javascript/dashboard/components/widgets/conversation/ConversationFilter.vue`) and `AdvancedFilters.vue` (`app/javascript/dashboard/components-next/search/AdvancedFilters.vue`).

2.  **Conversation Detail Pane (`ConversationView.vue`)**:
    -   Component: `app/javascript/dashboard/routes/dashboard/conversation/ConversationView.vue`.
    -   Displayed when a conversation is selected. Contains:
        -   **Conversation Header (`ConversationHeader.vue`)**: `app/javascript/dashboard/components/widgets/conversation/ConversationHeader.vue`. Displays contact name, status, and action buttons (resolve, re-open, assign, snooze, more options).
        -   **Message List (`MessageList.vue`)**: `app/javascript/dashboard/components/widgets/conversation/MessageList.vue`. Shows the chronological history of messages.
            -   Individual messages rendered by `Message.vue` (`app/javascript/dashboard/components/widgets/conversation/Message.vue`).
        -   **Reply Area (`ReplyBox.vue`)**: `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue`. For composing and sending messages.

3.  **Reply Area Details (`ReplyBox.vue`)**:
    -   Rich text editor (uses Tiptap editor, configured in `app/javascript/dashboard/components/widgets/WootWriter.vue`).
    -   Options for:
        -   Attachments (`app/javascript/dashboard/components/widgets/WootAttachment.vue`).
        -   Emojis.
        -   Canned Responses (`app/javascript/dashboard/components/widgets/conversation/CannedResponse.vue`).
        -   Private/Public message toggle.
    -   Typing indicators (`ConversationTypingIndicator.vue` - `app/javascript/dashboard/components/widgets/conversation/ConversationTypingIndicator.vue`).

4.  **Conversation Sidebar/Info Panel (`ConversationInfoPanel.vue`)**:
    -   `app/javascript/dashboard/components-next/conversations/ConversationInfoPanel.vue`.
    -   Displays detailed information about the contact (`ContactInfo.vue`), previous conversations (`ContactConversations.vue`), custom attributes, labels, and other contextual data.

## Core Functionalities

### 1. Viewing and Filtering Conversations
-   **Fetching Conversations**:
    -   Vuex action: `conversations/fetchConversations` (`app/javascript/dashboard/store/modules/conversations.js`).
    -   API: `GET /api/v1/accounts/{account_id}/conversations` via `ConversationsAPI.get()` (`app/javascript/dashboard/api/conversations.js`).
    -   Parameters: `page`, `inbox_id`, `team_id`, `assignee_type`, `status`, `q` (search), `labels[]`, `sort_by`, `custom_attributes`.
-   **Real-time Updates**: New conversations and updates are pushed via ActionCable.
    -   Vuex store (`conversations.js`) listens for events like `CONVERSATION_CREATED`, `MESSAGE_CREATED`, `CONVERSATION_UPDATED`.
    -   See `actionCableCallback` in `conversations.js` store module.
-   **Filtering**:
    -   Uses `ConversationFilter.vue` and `AdvancedFilters.vue`.
    -   Filters are stored in Vuex (`conversations/setConversationFilters`, `conversations/setAdvFilters`).
    -   Custom views (saved filter sets) are managed via `customViews` Vuex module (`app/javascript/dashboard/store/modules/customViews.js`) and `CustomViewsAPI.js`.

### 2. Replying to Conversations
-   **Sending Messages**:
    -   `ReplyBox.vue` dispatches `messages/create` Vuex action (`app/javascript/dashboard/store/modules/messages.js`).
    -   API: `POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages` via `MessagesAPI.create()` (`app/javascript/dashboard/api/messages.js`).
    -   Payload: `content`, `private` (boolean), `attachments[]`, `echo_id` (for optimistic updates), `content_attributes`.
    -   Backend: `app/controllers/api/v1/accounts/messages_controller.rb#create` uses `Messages::NewMessageService` (`app/services/messages/new_message_service.rb`).
-   **Private Notes**: Toggled in `ReplyBox.vue`, sets `private: true` in the message payload.
-   **Canned Responses**: Accessed via `/` command in `WootWriter.vue` or button.
    -   Vuex: `cannedResponses` module (`app/javascript/dashboard/store/modules/cannedResponses.js`).
    -   API: `CannedResponsesAPI.js` (`app/javascript/dashboard/api/cannedResponses.js`).
-   **Attachments**: Handled by `WootAttachment.vue`. Files are uploaded, and their signed IDs are sent with the message.

### 3. Conversation Management Actions
-   **Assigning Conversations**:
    -   UI: `ConversationHeader.vue` or bulk actions.
    -   Vuex action: `assignAgent` in `conversations.js` module.
    -   API: `POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/assignments` via `ConversationsAPI.assignAgent()`.
    -   Controller: `app/controllers/api/v1/accounts/conversations/assignments_controller.rb#create`.
-   **Changing Status** (Open, Resolved, Pending, Snoozed):
    -   UI: `ConversationHeader.vue`.
    -   Vuex action: `toggleStatus` in `conversations.js` module.
    -   API: `POST /api/v1/accounts/{account_id}/conversations/{id}/toggle_status` via `ConversationsAPI.toggleStatus()`.
    -   Controller: `app/controllers/api/v1/accounts/conversations_controller.rb#toggle_status`.
    -   Snoozing involves setting status to `pending` and providing `snoozed_until` timestamp.
-   **Labeling Conversations**:
    -   UI: `ConversationLabels.vue` (`app/javascript/dashboard/components/widgets/conversation/ConversationLabels.vue`) in `ConversationInfoPanel.vue`.
    -   Vuex action: `updateLabels` in `conversations.js`.
    -   API: `POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/labels` via `ConversationsAPI.updateLabels()`.
    -   Controller: `app/controllers/api/v1/accounts/conversations/labels_controller.rb#update`.
-   **Merging Conversations**:
    -   UI: `MergeContacts.vue` (`app/javascript/dashboard/components/widgets/conversation/MergeContactsModal.vue`) initiated from contact options.
    -   API: `POST /api/v1/accounts/{account_id}/contacts/{contact_id}/merge` (merges contacts, which implicitly merges their conversations if from same inbox).
    -   A direct conversation merge API might also exist or be part of this flow.
-   **Toggling Typing Indicators**:
    -   `WootWriter.vue` sends typing status.
    -   ActionCable: `ConversationChannel.toggle_typing` (`app/channels/application_cable/conversation_channel.rb`).
    -   Payload: `{ conversation_id: ..., typing_status: 'on'/'off', user_type: 'agent' }`.
    -   Displayed by `ConversationTypingIndicator.vue`.

### 4. Collaboration
-   **@mentions**: In `WootWriter.vue`, typing `@` triggers a user suggestion list (`app/javascript/dashboard/components/widgets/mentions/MentionUser.vue`).
    -   Mentions are processed by `Messages::NewMessageService` to create notifications.
-   **Private Notes**: As described in Replying section.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/conversations.js`**:
    -   Manages list of conversations, active conversation ID, filters, loading states, custom views.
    -   Actions: `fetchConversations`, `setActiveConversation`, `assignAgent`, `toggleStatus`, `updateLabels`, `sendEmailTranscript`, etc.
    -   Mutations: `SET_CONVERSATIONS_UI_FLAG`, `SET_ALL_CONVERSATIONS`, `ADD_CONVERSATION`, `UPDATE_CONVERSATION`, `REMOVE_CONVERSATION`, `SET_ACTIVE_CONVERSATION`, `UPDATE_CONVERSATION_CONTACT`, `SET_CONVERSATION_FILTERS`.
-   **`app/javascript/dashboard/store/modules/messages.js`**:
    -   Manages messages for the active conversation, loading states.
    -   Actions: `fetchMessages`, `create`, `deleteMessage`.
    -   Mutations: `SET_MESSAGES_UI_FLAG`, `SET_MESSAGES`, `ADD_MESSAGE`, `DELETE_MESSAGE`.
-   **`app/javascript/dashboard/store/modules/customViews.js`**: Manages saved conversation filter sets.

## Backend API Endpoints & Models

-   **Models**:
    -   `app/models/conversation.rb`: Core model for conversations. Attributes: `status`, `assignee_id`, `team_id`, `inbox_id`, `contact_id`, `priority`, `snoozed_until`, `custom_attributes`, `additional_attributes`.
        -   Scopes: `pubsub_scope`, `filter_by_assignee_type`, `filter_by_status`, `filter_by_team`, etc.
        -   Methods: `update_assignee`, `update_status`, `push_event_data` (for ActionCable), `resolve`, `reopen`.
    -   `app/models/message.rb`: Core model for messages. Attributes: `content`, `sender_id`, `sender_type`, `private`, `attachments`, `source_id`, `content_type`, `content_attributes`.
        -   Callbacks: `after_create_commit :execute_after_create_commit_callbacks` which includes dispatching events and notifications.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/conversations_controller.rb`: CRUD, list (with filtering), status toggling, bulk actions, transcript sending.
    -   `app/controllers/api/v1/accounts/messages_controller.rb`: CRUD for messages.
    -   `app/controllers/api/v1/accounts/conversations/assignments_controller.rb`: Handles assignment/unassignment.
    -   `app/controllers/api/v1/accounts/conversations/labels_controller.rb`: Handles label updates for conversations.
-   **Services**:
    -   `Messages::NewMessageService` (`app/services/messages/new_message_service.rb`): Business logic for new message creation, notifications, mentions, webhook dispatches.
    -   `Conversations::UpdateService` (`app/services/conversations/update_service.rb`): Logic for updating conversation attributes.
    -   `Conversations::FilterService` (`app/services/conversations/filter_service.rb`): Handles complex filtering logic.

## Real-time Communication (ActionCable)

-   Channel: `app/channels/application_cable/conversation_channel.rb`.
    -   Handles subscriptions (`subscribed`, `unsubscribed`).
    -   Actions: `toggle_typing`, `mark_message_read`, `update_presence`.
    -   Broadcasts: `message_created`, `message_updated`, `conversation_updated`, `typing_on`, `typing_off`, `presence_update`.
-   Client-side:
    -   `app/javascript/dashboard/helper/actionCable.js` provides `subscribe` and `perform` methods.
    -   Vuex stores (e.g., `conversations.js`) subscribe to relevant channels and events.

This detailed breakdown covers many aspects of conversation management. Further refinement can be done by exploring specific sub-features like the "Command Bar" interactions or different message types (cards, forms).
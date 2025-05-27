# Dashboard: Inbox Settings (Channel Management)

Inbox Settings in Chatwoot are where users create, configure, and manage their various communication channels. Each "Inbox" represents a distinct source of customer conversations, such as a website live chat, an email address, a Facebook page, or a WhatsApp number.

## Overview

This section is critical for connecting Chatwoot to the outside world. Administrators set up how Chatwoot ingests messages from different platforms and how agents will interact with these channels.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/inboxes`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/inbox/Index.vue`. This component lists existing inboxes and provides a way to add new ones.
    -   **Inbox List**: Displays cards or a table of configured inboxes, showing channel type, name, and status. Each item usually links to a detailed settings page for that specific inbox.
        -   Individual inbox items rendered by components like `InboxCard.vue` (`app/javascript/dashboard/components/widgets/InboxCard.vue`).
    -   **"Add Inbox" / "Create an Inbox" Button**: Initiates the channel creation flow. This often leads to `app/javascript/dashboard/routes/dashboard/settings/inbox/New.vue` or a modal sequence.

-   **Inbox Creation Flow (`New.vue` or Modals)**:
    -   A multi-step process where the user first selects the channel type (Website, Facebook, Email, Twitter, WhatsApp, etc.).
    -   Component: `app/javascript/dashboard/components/widgets/CreateInbox.vue` or similar.
    -   Based on the channel type, specific forms are presented to gather necessary credentials and configuration details (e.g., API keys, page IDs, email server settings).
        -   Example for Website Channel: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WebWidget.vue`.
        -   Example for Facebook: `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/Facebook.vue`.

-   **Individual Inbox Settings Page**:
    -   Route: `/app/accounts/{account_id}/settings/inboxes/{inbox_id}`
    -   Component: Often a dynamic component or a layout like `app/javascript/dashboard/routes/dashboard/settings/inbox/Settings.vue` which then loads channel-specific settings components.
    -   This page has sub-sections/tabs for:
        -   **General Settings**: Inbox name, greeting messages, agent assignment rules (e.g., auto-assign to specific team/agent).
        -   **Configuration**: Channel-specific settings (e.g., for website widget: widget design, pre-chat form; for email: IMAP/SMTP settings).
        -   **Collaborators/Agents**: Manage which agents have access to this inbox.
        -   **Business Hours**: Configure working hours for the inbox and auto-reply messages outside these hours.
        -   **Other specific features**: Pre-chat form configuration (for web widget), auto-assignment rules specific to the inbox.

## Key Functionalities

### 1. Listing and Viewing Inboxes
-   **Fetching Inboxes**:
    -   Vuex action: `inboxes/get` (`app/javascript/dashboard/store/modules/inboxes.js`).
    -   API: `GET /api/v1/accounts/{account_id}/inboxes` via `InboxesAPI.get()` (`app/javascript/dashboard/api/inbox.js`).
    -   Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb#index`.

### 2. Creating a New Inbox (Channel Setup)
-   This is a multi-step process involving both frontend and backend.
-   **Frontend**:
    -   User selects channel type.
    -   Relevant form (`WebWidget.vue`, `Facebook.vue`, `Email.vue`, etc.) collects data.
    -   Data is submitted to the backend.
    -   Vuex action: `inboxes/create`.
-   **Backend**:
    -   API: `POST /api/v1/accounts/{account_id}/inboxes`.
    -   Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb#create`.
    -   This controller action typically:
        -   Creates an `Inbox` record.
        -   Creates an associated channel record (e.g., `Channel::WebWidget`, `Channel::FacebookPage`, `Channel::Email`). The `channel_type` parameter in the request determines which specific channel model is instantiated.
        -   Example: For a website channel, a `Channel::WebWidget` (`app/models/channel/web_widget.rb`) record is created.
        -   May involve calls to third-party APIs for validation or setup (e.g., Facebook Graph API).
    -   Models: `Inbox` (`app/models/inbox.rb`) and specific channel models like:
        -   `app/models/channel/web_widget.rb`
        -   `app/models/channel/facebook_page.rb`
        -   `app/models/channel/twitter_profile.rb`
        -   `app/models/channel/twilio_sms.rb`
        -   `app/models/channel/whatsapp.rb` (often linked to a provider like Twilio, 360Dialog)
        -   `app/models/channel/email.rb`
        -   `app/models/channel/api.rb` (for custom API channels)
        -   `app/models/channel/telegram.rb`
        -   `app/models/channel/line.rb`

### 3. Updating Inbox Settings
-   **General Settings (Name, Greeting, etc.)**:
    -   UI: Forms within the individual inbox settings page.
    -   Vuex action: `inboxes/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/inboxes/{inbox_id}`.
    -   Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb#update`.
        -   Updates attributes on both the `Inbox` model and its associated `channel` model (e.g., `inbox.channel.update(...)`).
-   **Channel-Specific Configuration**:
    -   Example for `Channel::WebWidget`: Widget color, welcome messages, continuity of conversations, pre-chat form fields.
        -   The `channel` object associated with the `Inbox` holds these settings (e.g., `inbox.channel.widget_color`).
        -   Frontend components like `app/javascript/dashboard/routes/dashboard/settings/inbox/channels/WebWidgetChannelSettings.vue`.
-   **Managing Collaborators (Inbox Members)**:
    -   UI: A section to add or remove agents from an inbox.
    -   Model: `InboxMember` (`app/models/inbox_member.rb`) join table between `User` and `Inbox`.
    -   API: `POST /api/v1/accounts/{account_id}/inbox_members` or updates via the `InboxesController` with `member_ids` params.
    -   Controller: `app/controllers/api/v1/accounts/inbox_members_controller.rb#create`, `#update`, `#destroy`.

### 4. Business Hours Configuration
-   UI: `BusinessHours.vue` (`app/javascript/dashboard/routes/dashboard/settings/inbox/components/BusinessHours.vue`).
-   Vuex action: `inboxes/updateBusinessHours`.
-   API: `POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/set_business_hours`.
-   Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb#set_business_hours`.
-   Model: `Inbox` attributes like `working_hours_enabled`, `out_of_office_message`, `business_hours` (JSON or serialized array of time slots). Also, `AvailabilityStatusJob` (`app/jobs/inboxes/availability_status_job.rb`) might be used to toggle inbox availability based on business hours.

### 5. Deleting an Inbox
-   UI: Delete button on the inbox settings page.
-   Vuex action: `inboxes/delete`.
-   API: `DELETE /api/v1/accounts/{account_id}/inboxes/{inbox_id}`.
-   Controller: `app/controllers/api/v1/accounts/inboxes_controller.rb#destroy`.
    -   This will also delete the associated channel record and inbox members.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/inboxes.js`**:
    -   Manages the list of inboxes for the account and UI flags.
    -   Actions: `get`, `create`, `update`, `delete`, `updateBusinessHours`, `getCampaigns` (related to campaigns within an inbox), `getAgentBots`.
    -   Mutations: `SET_INBOXES_UI_FLAG`, `SET_INBOXES`, `ADD_INBOX`, `EDIT_INBOX`, `DELETE_INBOX`, `SET_INBOX_AGENT_BOT`.
-   **Channel-specific state**: Might be handled within components or a dedicated module if complex.

## Backend API Endpoints & Models

-   **Models**:
    -   `Inbox` (`app/models/inbox.rb`): Core model. Attributes: `name`, `account_id`, `channel_type`, `channel_id` (polymorphic association to the specific channel model), `greeting_enabled`, `greeting_message`, `enable_auto_assignment`, `auto_assignment_config`.
        -   Polymorphic association: `belongs_to :channel, polymorphic: true, dependent: :destroy`.
    -   Specific Channel Models (e.g., `Channel::WebWidget`, `Channel::FacebookPage`, etc.) located in `app/models/channel/`. These store configuration specific to that channel type.
        -   `Channel::WebWidget` attributes: `website_url`, `widget_color`, `welcome_title`, `welcome_tagline`, `hmac_mandatory`, `hmac_token`, `pre_chat_form_enabled`, `pre_chat_form_options`.
    -   `InboxMember` (`app/models/inbox_member.rb`): Links `User` (agents) to `Inbox`.
    -   `AgentBot` (`app/models/agent_bot.rb`) and `AgentBotInbox` (`app/models/agent_bot_inbox.rb`): For CSAT survey bots or Dialogflow integrations linked to inboxes.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/inboxes_controller.rb`: CRUD for inboxes, business hours settings, agent bot linking.
    -   `app/controllers/api/v1/accounts/inbox_members_controller.rb`: Manages agent assignments to inboxes.
    -   Platform specific controllers for callbacks during channel setup (e.g., `app/controllers/facebook_callbacks_controller.rb`).

## Important Considerations for Channels

-   **Authentication & Authorization**: Many channels require OAuth flows (Facebook, Twitter) or API key management. The backend handles these secure interactions.
-   **Webhook Ingestion**: For channels like Facebook, WhatsApp, Telegram, Chatwoot needs to receive incoming messages via webhooks. Controllers like `app/controllers/webhooks/facebook_controller.rb`, `app/controllers/webhooks/whatsapp_controller.rb` handle these.
-   **Message Processing**: Once a message is received (via webhook or polling for email), it's processed, a `Contact` and `Conversation` are found/created, and the `Message` is saved. Services like `Messages::NewMessageService` are involved.

This documentation outlines the structure and key elements of Inbox/Channel management in Chatwoot. Each channel type has its own specific setup and configuration nuances.
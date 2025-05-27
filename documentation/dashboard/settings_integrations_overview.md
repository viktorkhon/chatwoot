# Dashboard: Integrations Overview

The Integrations section in Chatwoot's settings allows administrators to connect their Chatwoot account with various third-party applications and services. This extends Chatwoot's functionality and enables seamless workflows between different tools.

## Overview

Integrations can range from communication platforms (like Slack), CRM systems, analytics tools, AI services (like Dialogflow), to e-commerce platforms (like Shopify). Each integration typically requires specific configuration steps and authentication.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/integrations`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/integrations/Index.vue`. This page usually displays a list or grid of available integrations, indicating which ones are active or configurable.
    -   **Integration List/Grid**: Shows available integrations, often with logos and short descriptions.
        -   Component: `IntegrationList.vue` or similar (e.g., using `IntegrationItem.vue` cards).
        -   Each item might show a "Connect" or "Configure" button.
    -   **"Add Integration" or specific integration buttons**: Leads to the configuration page for that specific integration.

-   **Individual Integration Configuration Page/Modal**:
    -   The UI for configuring each integration is specific to that integration's requirements.
    -   Examples:
        -   Slack: `app/javascript/dashboard/routes/dashboard/settings/integrations/Slack.vue`
        -   Dialogflow: `app/javascript/dashboard/routes/dashboard/settings/integrations/Dialogflow.vue`
        -   Dashboard Apps: `app/javascript/dashboard/routes/dashboard/settings/integrations/DashboardApps/Index.vue`
    -   These pages handle inputting API keys, authenticating via OAuth, setting preferences, etc.

## Key Functionalities

### 1. Listing Available and Active Integrations
-   **Fetching Integration Status**:
    -   The frontend often has a predefined list of supported integrations.
    -   API calls are made to check the status or configuration of each (e.g., `GET /api/v1/accounts/{account_id}/integrations/slack` to get Slack integration details).
    -   Controller: `app/controllers/api/v1/accounts/integrations_controller.rb` might have a general status endpoint, or individual controllers per integration type exist (e.g., `app/controllers/api/v1/accounts/integrations/slack_controller.rb`).
    -   Model: `IntegrationHook` (`app/models/integration_hook.rb`) stores details about active integrations, including settings and API tokens. `Hook` (`app/models/hook.rb`) is a more general model for various types of hooks, including integrations.

### 2. Connecting/Configuring an Integration
-   This process is highly specific to each integration.
-   **General Steps**:
    1.  User selects an integration to connect.
    2.  Frontend displays a form for API keys, or redirects to an OAuth flow provided by the third-party service.
    3.  User provides necessary credentials or authorizes access.
    4.  Backend receives credentials/tokens, validates them, and stores them securely (often encrypted, e.g., `attr_encrypted` on the `IntegrationHook` or `Hook` model for fields like `access_token`).
    5.  A `Hook` or `IntegrationHook` record is created or updated for the account, with `status: :enabled`.
-   **Example: Slack**
    -   User clicks "Connect to Slack".
    -   Redirected to Slack's OAuth page.
    -   After authorization, Slack redirects back to a Chatwoot callback URL (`slack_callbacks_controller.rb`).
    -   Chatwoot exchanges the code for an access token and stores it.
-   **Example: API Key Based (e.g., Dialogflow, OpenAI)**
    -   User inputs API key and project ID into a form.
    -   Backend validates (if possible) and stores the key.

### 3. Updating Integration Settings
-   For active integrations, users can often modify certain settings (e.g., which Slack channel to post notifications to, which Dialogflow agent to use for an inbox).
-   API: `PATCH /api/v1/accounts/{account_id}/integrations/{integration_name}`.
-   Controller: Specific controller for the integration (e.g., `SlackController#update`).

### 4. Disconnecting/Deleting an Integration
-   User chooses to disconnect an active integration.
-   API: `DELETE /api/v1/accounts/{account_id}/integrations/{integration_name}`.
-   Controller: Specific controller (e.g., `SlackController#destroy`).
-   Backend deletes the `IntegrationHook` or `Hook` record, or sets its status to `disabled`. Any stored tokens are usually cleared.

## Common Integration Types and Their Purpose

-   **Communication (Slack)**: Notify about new conversations or messages in Slack channels.
-   **AI & Chatbots (Dialogflow, Rasa, OpenAI via Captain)**: Connect AI agents to handle conversations in specific inboxes.
-   **CRM**: Sync contact data (less common as a direct integration, often done via webhooks or Zapier/Pipedream).
-   **E-commerce (Shopify)**: View customer order details directly within the Chatwoot dashboard when talking to a Shopify customer.
-   **Analytics**: Send Chatwoot event data to analytics platforms.
-   **Dashboard Apps**: Embed custom web applications directly into the Chatwoot conversation sidebar for agents to use.
-   **Linear**: Create and track Linear issues from Chatwoot conversations.
-   **Calendly**: Allow agents to share Calendly links easily.
-   **Dyte**: For video call integration.

## State Management (Vuex)

-   There isn't usually a single "integrations" Vuex module for all data.
-   Each integration might have its state managed by its specific configuration component or a dedicated small Vuex module if complex (e.g., `app/javascript/dashboard/store/modules/integrations/dialogflow.js`).
-   A general `integrations` module might hold the list of available integrations and their basic status.

## Backend API Endpoints & Models

-   **Models**:
    -   `Hook` (`app/models/hook.rb`): A central model for various types of hooks, including integrations. Stores `settings` (JSONB), `access_token` (encrypted), `account_id`, `app_id` (identifies the integration type), `status`.
    -   `IntegrationHook` (`app/models/integration_hook.rb`): Potentially a more specific model or used interchangeably/alongside `Hook` for integrations.
    -   `App` (`app/models/app.rb`): Defines available integration types (e.g., `slack`, `dialogflow`). `App.find_by(name: 'slack')`.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/integrations_controller.rb`: May handle general listing or common actions.
    -   Specific controllers for each integration:
        -   `app/controllers/api/v1/accounts/integrations/slack_controller.rb`
        -   `app/controllers/api/v1/accounts/integrations/dialogflow_controller.rb`
        -   `app/controllers/api/v1/accounts/integrations/dashboard_apps_controller.rb`
        -   etc.
    -   Callback controllers for OAuth flows:
        -   `app/controllers/integrations/slack_callbacks_controller.rb`
-   **Services**: Specific services in `app/services/integrations/` (e.g., `app/services/integrations/slack/send_on_slack_service.rb`) might handle the actual logic of interacting with the third-party API.
-   **Libraries**: Code under `lib/integrations/` (e.g., `lib/integrations/slack/chatwoot_channel_listener.rb`, `lib/integrations/dialogflow/processor_service.rb`) often contains the core integration logic.

Integrations are key to making Chatwoot a central hub for customer communication by connecting it with other essential business tools. The specific implementation details can vary significantly between integrations.
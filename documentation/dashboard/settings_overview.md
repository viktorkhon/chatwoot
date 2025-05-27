# Dashboard: Settings Overview

The Settings area in the Chatwoot dashboard is a comprehensive section allowing administrators and agents (with appropriate permissions) to configure various aspects of their Chatwoot account, channels, team, and operational workflows.

## Access and Layout

-   **Main Route**: `/app/accounts/{account_id}/settings`
-   **Layout Component**: `app/javascript/dashboard/routes/dashboard/settings/SettingsLayout.vue`. This component typically provides a sub-navigation sidebar for different settings categories.
-   **Sidebar Navigation**: The specific items in the settings sidebar are often defined in `app/javascript/dashboard/components/layout/sidebar/menu/settings.js` or dynamically generated based on account features and user roles.

## Key Settings Categories

The settings are generally grouped into logical categories. While the exact structure can evolve, common categories include:

1.  **Account Settings**:
    -   **Profile**: Basic account information, avatar, notification settings, password changes.
    -   **Agents**: Managing agent users (inviting, editing roles, deleting).
    -   **Teams**: Creating and managing groups of agents.
    -   **Labels**: Creating and managing global labels for conversations and contacts. ([See Label Management](./settings_labels.md))
    -   **Inboxes**: Adding and configuring communication channels (Website, Email, Facebook, etc.). ([See Inbox Settings](./settings_inboxes.md))
    -   **Canned Responses**: Creating and managing predefined replies. ([See Canned Response Management](./settings_canned_responses.md))
    -   **Integrations**: Connecting Chatwoot with third-party applications (Slack, Dialogflow, etc.). ([See Integrations Overview](./settings_integrations_overview.md))
    -   **Automation Rules**: Setting up rules to automate workflows (e.g., assign conversation, add label). ([See Automation Rules](./settings_automation_rules.md))
    -   **Custom Attributes**: Defining custom data fields for conversations and contacts. ([See Custom Attribute Management](./settings_custom_attributes.md))
    -   **Webhooks**: Configuring webhook endpoints for event notifications. ([See Webhook Configuration UI](./settings_webhooks_ui.md))
    -   **Security**: (If applicable) Settings related to security, API access.
    -   **Billing / Subscription**: (Enterprise Edition) Managing subscription and payment details.
    -   **Audit Logs**: (Enterprise Edition) Viewing a log of actions performed within the account.

2.  **Application Settings** (less common for regular users, might be part of super admin or general config):
    -   These might include instance-level configurations if the dashboard also serves some admin functions beyond a single account.

## General Frontend Structure for Settings Pages

Most settings pages follow a similar pattern:

-   **Vue Components**: Located within `app/javascript/dashboard/routes/dashboard/settings/` (e.g., `Index.vue` for general account settings, `AgentList.vue` for agent management) or within `app/javascript/dashboard/modules/settings/` for more modularized settings.
    -   Example: `app/javascript/dashboard/modules/settings/agents/Index.vue`
    -   Example: `app/javascript/dashboard/routes/dashboard/settings/inbox/Index.vue`
-   **Vuex Store Modules**: Often, each major settings category will have its own Vuex module to manage its state, fetch data, and handle updates.
    -   Examples: `app/javascript/dashboard/store/modules/accounts.js`, `app/javascript/dashboard/store/modules/agents.js`, `app/javascript/dashboard/store/modules/inboxes.js`, `app/javascript/dashboard/store/modules/labels.js`, etc.
-   **API Clients**: Specific API client files in `app/javascript/dashboard/api/` are used to interact with the backend.
    -   Examples: `AgentsAPI.js`, `InboxesAPI.js`, `LabelsAPI.js`.
-   **Forms and Modals**: Used extensively for creating and editing settings. Common components like `Modal.vue` (`app/javascript/dashboard/components/Modal.vue`) or `woot-modal` from shared components are used.

## Backend Structure for Settings

-   **Controllers**: API endpoints for managing settings are typically found in `app/controllers/api/v1/accounts/`.
    -   `app/controllers/api/v1/accounts_controller.rb` (for general account settings).
    -   `app/controllers/api/v1/accounts/agents_controller.rb`.
    -   `app/controllers/api/v1/accounts/inboxes_controller.rb`.
    -   `app/controllers/api/v1/accounts/labels_controller.rb`.
    -   And so on for other settings entities.
-   **Models**: Rails models define the data structure for each setting entity (e.g., `Account`, `User` for agents, `Inbox`, `Label`, `Team`, `CannedResponse`).
-   **Services**: Business logic for complex operations (e.g., inviting an agent, creating a channel) might be encapsulated in service objects.

This overview provides a general map of the settings area. Subsequent documents will delve into specific settings sections like Account Settings, Inbox Management, Agent Management, etc., detailing their frontend components, Vuex interactions, and backend API endpoints.
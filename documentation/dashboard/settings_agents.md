# Dashboard: Agent Management

Agent Management in Chatwoot is where administrators add, manage, and define roles for the users (agents) who will interact with customers and use the platform.

## Overview

This section allows for controlling user access, assigning roles (Administrator, Agent), and maintaining the list of support staff within a Chatwoot account.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/agents`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue`. This page typically displays a list of current agents and provides options to invite new agents or edit existing ones.
    -   **Agent List**: Usually a table or a list of cards, showing agent name, email, role, status (e.g., active, pending invitation), and last activity.
        -   Component: `app/javascript/dashboard/components/widgets/ManageAgents.vue` or a more specific list component like `AgentsTable.vue` within the settings module.
    -   **"Add Agent" / "Invite Agent" Button**: Opens a modal or form for inviting new users.
        -   Modal Component: `AddAgentModal.vue` or `InviteAgentModal.vue` (e.g., `app/javascript/dashboard/routes/dashboard/settings/agents/AddAgent.vue`).

-   **Edit Agent View/Modal**:
    -   Accessed by clicking an "Edit" button next to an agent in the list.
    -   Allows modification of agent details, primarily their role.
    -   Component: `EditAgent.vue` or similar, often reusing parts of the add/invite modal.

## Key Functionalities

### 1. Listing Agents
-   **Fetching Agents**:
    -   Vuex action: `agents/get` (`app/javascript/dashboard/store/modules/agents.js`).
    -   API: `GET /api/v1/accounts/{account_id}/agents` via `AgentsAPI.get()` (`app/javascript/dashboard/api/agents.js`).
    -   Controller: `app/controllers/api/v1/accounts/agents_controller.rb#index`.
    -   Displays: Name, Email, Role, Availability Status, Last Activity.

### 2. Inviting/Adding New Agents
-   **Frontend Process**:
    -   Admin fills out a form with the new agent's email address and selects a role (Administrator or Agent).
    -   Vuex action: `agents/create`.
    -   API: `POST /api/v1/accounts/{account_id}/agents` via `AgentsAPI.create()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/agents_controller.rb#create`.
    -   This action:
        -   Checks if a user with the given email already exists in the system.
        -   If not, it creates a new `User` record with a pending confirmation status.
        -   Creates an `AccountUser` record to link the `User` to the current `Account` with the specified role.
        -   Sends an invitation email to the new agent using `AgentMailer.agent_added_to_account` or `AgentMailer.invitation_to_set_password`.
    -   Models:
        -   `User` (`app/models/user.rb`): Stores global user profiles (name, email, password, etc.). Uses `devise` for authentication.
        -   `AccountUser` (`app/models/account_user.rb`): Join model linking `User` and `Account`, storing the `role` (e.g., `administrator`, `agent`).
-   **Agent Onboarding**: The invited agent receives an email with a link to set their password and complete their profile.

### 3. Editing Agent Roles
-   **Frontend Process**:
    -   Admin selects a new role for an existing agent.
    -   Vuex action: `agents/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/agents/{agent_id}` via `AgentsAPI.update()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/agents_controller.rb#update`.
    -   Updates the `role` attribute on the `AccountUser` record for that agent within the specific account.

### 4. Deleting/Removing Agents
-   **Frontend Process**:
    -   Admin confirms the deletion of an agent from the account.
    -   Vuex action: `agents/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/agents/{agent_id}` via `AgentsAPI.delete()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/agents_controller.rb#destroy`.
    -   This action typically deletes the `AccountUser` record, effectively removing the agent's access to that specific account. The global `User` record might remain if the user is part of other accounts.
    -   Consideration: Conversations assigned to the deleted agent might need to be unassigned or reassigned. `AccountUser#destroy_action_for_contact_assignment` handles unassigning conversations.

### 5. Agent Profile Settings (Individual Agent's View)
-   While bulk agent management is done by admins, individual agents can manage their own profiles:
    -   Route: `/app/accounts/{account_id}/profile/settings`
    -   Component: `app/javascript/dashboard/routes/dashboard/settings/profile/Index.vue`.
    -   Functionalities:
        -   Update name, display name, email.
        -   Change password.
        -   Configure notification preferences (`User#notification_settings`).
        -   Set auto-offline status.
        -   Enable/Disable 2FA for their own account.
    -   API: `PUT /api/v1/profile` handled by `app/controllers/api/v1/profile_controller.rb#update`.

### 6. Agent Availability Status
-   Agents can set their availability (Online, Busy, Offline).
-   UI: Typically a dropdown in the main dashboard header/sidebar (`app/javascript/dashboard/components/layout/sidebar/AgentAvailability.vue`).
-   Vuex: `app/javascript/dashboard/store/modules/auth.js` (e.g., `updateAvailability` action).
-   API: `POST /api/v1/profile/availability` via `ProfileAPI.updateAvailability()`.
-   Controller: `app/controllers/api/v1/profile_controller.rb#availability`.
-   Backend: Updates `User#availability` and `User#auto_offline`. Broadcasts presence updates via ActionCable.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/agents.js`**:
    -   Manages the list of agents for the current account, their roles, and UI flags.
    -   State: `records` (array of agent objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`.
    -   Mutations: `SET_AGENTS_UI_FLAG`, `SET_AGENTS`, `ADD_AGENT`, `EDIT_AGENT`, `DELETE_AGENT`.
-   **`app/javascript/dashboard/store/modules/auth.js`**:
    -   Manages the currently logged-in user's state, including their availability.

## Backend API Endpoints & Models

-   **Models**:
    -   `User` (`app/models/user.rb`): Global user information, Devise authentication, `name`, `email`, `display_name`, `password`, `notification_settings` (JSONB), `availability`, `available_name`.
    -   `AccountUser` (`app/models/account_user.rb`): Links `User` to `Account`. Attributes: `user_id`, `account_id`, `role` (enum: `administrator`, `agent`), `inviter_id`.
        -   Defines `ROLE_ADMINISTRATOR` and `ROLE_AGENT` constants.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/agents_controller.rb`: CRUD operations for agents within an account.
    -   `app/controllers/api/v1/profile_controller.rb`: Handles updates to the current user's profile and availability.
-   **Mailers**:
    -   `app/mailers/agent_mailer.rb`: Sends invitation emails (`agent_added_to_account`, `invitation_to_set_password`).

This documentation covers the primary aspects of agent management. The system ensures that only authorized users can access account data and perform actions based on their assigned roles.
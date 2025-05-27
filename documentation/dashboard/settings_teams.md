# Dashboard: Team Management

Team Management in Chatwoot allows administrators to group agents together. Teams can be used for organizing agents, assigning conversations to a group rather than an individual, and for reporting purposes.

## Overview

Teams provide a way to structure the support workforce, especially in larger organizations. Conversations can be assigned to a team, and agents within that team can then pick up or be assigned those conversations.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/teams`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/teams/Index.vue`. This page lists existing teams and provides options to create new teams or edit existing ones.
    -   **Team List**: Displays a list of teams, often showing team name, description, and number of members.
        -   Component: `TeamsTable.vue` or similar within `app/javascript/dashboard/components-next/teams/` or `app/javascript/dashboard/routes/dashboard/settings/teams/`.
    -   **"Add Team" / "Create Team" Button**: Opens a modal or form for creating a new team.
        -   Modal Component: `AddTeam.vue` or `CreateTeamModal.vue` (e.g., `app/javascript/dashboard/components-next/teams/AddTeam.vue`).

-   **Edit Team View/Modal**:
    -   Accessed by clicking an "Edit" or "Settings" button for a team.
    -   Allows modification of team name, description, and managing team members.
    -   Component: `EditTeam.vue` or `TeamSettings.vue` (e.g., `app/javascript/dashboard/components-next/teams/EditTeam.vue`).
    -   Includes functionality to add/remove agents from the team (`TeamMembers.vue` - `app/javascript/dashboard/components-next/teams/TeamMembers.vue`).

## Key Functionalities

### 1. Listing Teams
-   **Fetching Teams**:
    -   Vuex action: `teams/get` (`app/javascript/dashboard/store/modules/teams.js`).
    -   API: `GET /api/v1/accounts/{account_id}/teams` via `TeamsAPI.get()` (`app/javascript/dashboard/api/teams.js`).
    -   Controller: `app/controllers/api/v1/accounts/teams_controller.rb#index`.

### 2. Creating a New Team
-   **Frontend Process**:
    -   Admin fills out a form with team name, description, and selects initial members.
    -   Vuex action: `teams/create`.
    -   API: `POST /api/v1/accounts/{account_id}/teams` via `TeamsAPI.create()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/teams_controller.rb#create`.
    -   Payload: `name`, `description`, `allow_auto_assign`, `agent_ids[]`.
    -   Creates a new `Team` record.
    -   Creates `TeamMember` records to link selected agents to the new team.
    -   Models:
        -   `Team` (`app/models/team.rb`): Stores team information. Attributes: `name`, `description`, `account_id`, `allow_auto_assign`.
        -   `TeamMember` (`app/models/team_member.rb`): Join model linking `User` (agents) and `Team`.

### 3. Editing Team Details
-   **Frontend Process**:
    -   Admin modifies team name, description, or auto-assignment setting.
    -   Vuex action: `teams/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/teams/{team_id}` via `TeamsAPI.update()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/teams_controller.rb#update`.
    -   Updates attributes on the `Team` record.

### 4. Managing Team Members
-   **Adding/Removing Agents from a Team**:
    -   UI: Typically in the "Edit Team" view, a multi-select dropdown or a list with add/remove options (`TeamMembers.vue`).
    -   Vuex action: `teams/updateMembers` (or similar, might be part of `teams/update` if the API supports updating members along with other team details).
    -   API: `PATCH /api/v1/accounts/{account_id}/teams/{team_id}` (if `agent_ids` are part of the update payload) or potentially a dedicated endpoint like `POST /api/v1/accounts/{account_id}/teams/{team_id}/members`.
        -   The `TeamsAPI.update()` in `app/javascript/dashboard/api/teams.js` sends `agent_ids` in the payload.
    -   Controller: `app/controllers/api/v1/accounts/teams_controller.rb#update` handles adding/removing `TeamMember` records based on the provided `agent_ids`.
        -   The `update_members` private method in the controller is responsible for this logic.

### 5. Deleting a Team
-   **Frontend Process**:
    -   Admin confirms the deletion.
    -   Vuex action: `teams/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/teams/{team_id}` via `TeamsAPI.delete()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/teams_controller.rb#destroy`.
    -   Deletes the `Team` record. Associated `TeamMember` records are also typically deleted due to database foreign key constraints or model `dependent: :destroy_async` callbacks.
    -   Conversations assigned to the team may need to be unassigned or reassigned. `Team#update_conversation_assignment` handles unassigning conversations.

### 6. Using Teams in Conversation Assignment
-   Teams can be selected as assignees for conversations.
-   This is handled in the conversation assignment UI (`ConversationHeader.vue`, assignment modals).
-   When a conversation is assigned to a team, its `team_id` attribute is set.
-   Agents who are members of that team can see and potentially take ownership of the conversation.
-   Auto-assignment rules can also use teams as targets.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/teams.js`**:
    -   Manages the list of teams, their members, and UI flags.
    -   State: `records` (array of team objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`. (Note: `update` action handles member changes as well).
    -   Mutations: `SET_TEAMS_UI_FLAG`, `SET_TEAMS`, `ADD_TEAM`, `EDIT_TEAM`, `DELETE_TEAM`.

## Backend API Endpoints & Models

-   **Models**:
    -   `Team` (`app/models/team.rb`):
        -   Attributes: `name`, `description`, `account_id`, `allow_auto_assign`.
        -   Associations: `has_many :team_members, dependent: :destroy_async`, `has_many :users, through: :team_members` (aliased as `members`), `has_many :conversations`.
        -   Callbacks: `after_destroy :notify_deletion`, `after_destroy :update_conversation_assignment`.
    -   `TeamMember` (`app/models/team_member.rb`):
        -   Attributes: `user_id`, `team_id`.
        -   Associations: `belongs_to :user`, `belongs_to :team`.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/teams_controller.rb`: CRUD operations for teams and their members.

Team management is a key feature for organizing support operations, enabling efficient routing and handling of customer conversations within larger agent groups.
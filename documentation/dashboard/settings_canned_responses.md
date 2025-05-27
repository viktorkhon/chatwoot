# Dashboard: Canned Response Management

Canned Responses in Chatwoot are predefined message templates that agents can quickly insert into conversations. They are used to save time, ensure consistency in replies, and answer frequently asked questions efficiently.

## Overview

This settings section allows administrators and agents (depending on permissions) to create, edit, organize, and delete canned responses. These responses can then be easily searched and used from the conversation reply box.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/canned-responses`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/cannedResponse/Index.vue`. This page displays a list of existing canned responses and provides options to add new ones or edit/delete existing ones.
    -   **Canned Response List**: Typically a table showing the short code, content snippet, and actions (Edit, Delete).
        -   Component: `CannedResponseTable.vue` or similar (e.g., `app/javascript/dashboard/components/widgets/CannedResponse/Table.vue`).
    -   **"Add Canned Response" Button**: Opens a modal for creating a new canned response.
        -   Modal Component: `AddCannedResponseModal.vue` or similar (e.g., `app/javascript/dashboard/components/widgets/CannedResponse/AddCannedResponseModal.vue`).

-   **Edit Canned Response Modal**:
    -   Accessed by clicking an "Edit" button for a canned response.
    -   Allows modification of the short code and content.
    -   Component: `EditCannedResponse.vue` often reusing the structure of the add modal.

## Key Functionalities

### 1. Listing Canned Responses
-   **Fetching Canned Responses**:
    -   Vuex action: `cannedResponses/get` (`app/javascript/dashboard/store/modules/cannedResponses.js`).
    -   API: `GET /api/v1/accounts/{account_id}/canned_responses` via `CannedResponsesAPI.get()` (`app/javascript/dashboard/api/cannedResponses.js`).
    -   Controller: `app/controllers/api/v1/accounts/canned_responses_controller.rb#index`.

### 2. Creating a New Canned Response
-   **Frontend Process**:
    -   User fills out a form with:
        -   `short_code`: A unique, memorable code to quickly find the response (e.g., "greeting", "pricing").
        -   `content`: The full text of the response. Can include dynamic variables like `{{ contact.name }}`.
    -   Vuex action: `cannedResponses/create`.
    -   API: `POST /api/v1/accounts/{account_id}/canned_responses` via `CannedResponsesAPI.create()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/canned_responses_controller.rb#create`.
    -   Payload: `short_code`, `content`.
    -   Creates a new `CannedResponse` record.
    -   Model: `CannedResponse` (`app/models/canned_response.rb`).

### 3. Editing Canned Response Details
-   **Frontend Process**:
    -   User modifies `short_code` or `content`.
    -   Vuex action: `cannedResponses/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/canned_responses/{canned_response_id}` via `CannedResponsesAPI.update()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/canned_responses_controller.rb#update`.
    -   Updates attributes on the `CannedResponse` record.

### 4. Deleting a Canned Response
-   **Frontend Process**:
    -   User confirms the deletion.
    -   Vuex action: `cannedResponses/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/canned_responses/{canned_response_id}` via `CannedResponsesAPI.delete()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/canned_responses_controller.rb#destroy`.
    -   Deletes the `CannedResponse` record.

### 5. Using Canned Responses in Conversations
-   **Access**: In the conversation reply box (`WootWriter.vue` - `app/javascript/dashboard/components/widgets/WootWriter.vue`), typing `/` followed by the short code or keywords triggers a search.
-   **Search and Selection**: A dropdown list of matching canned responses appears.
    -   Component: `app/javascript/dashboard/components/widgets/conversation/CannedResponse.vue` (likely part of the mention/command suggestion system in `WootWriter`).
-   **Insertion**: Selecting a response inserts its content into the reply box.
-   **Dynamic Variables**: If the canned response content includes variables like `{{ conversation.id }}`, `{{ contact.name }}`, `{{ agent.name }}`, these are replaced with actual values before insertion.
    -   The variable replacement logic is handled frontend-side, likely in `WootWriter.vue` or a helper function it uses. It accesses current conversation, contact, and agent data from the Vuex store.
    -   See `app/javascript/dashboard/helper/VariableHelper.js` for available variables.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/cannedResponses.js`**:
    -   Manages the list of canned responses for the account and UI flags.
    -   State: `records` (array of canned response objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`.
    -   Mutations: `SET_CANNED_UI_FLAG`, `SET_CANNED`, `ADD_CANNED`, `EDIT_CANNED`, `DELETE_CANNED`.

## Backend API Endpoints & Models

-   **Model**: `CannedResponse` (`app/models/canned_response.rb`)
    -   Attributes: `account_id`, `short_code`, `content`.
    -   Validations: `validates :content, :short_code, presence: true`, uniqueness of `short_code` scoped to `account_id`.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/canned_responses_controller.rb`: CRUD operations for canned responses.

Canned responses significantly improve agent productivity and response consistency across the support team.
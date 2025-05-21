# Dashboard: Label Management

Label Management in Chatwoot allows administrators to create, edit, and delete labels that can be applied to conversations and contacts. Labels are used for categorization, filtering, and reporting.

## Overview

Labels are tags that help organize and add context to customer interactions and profiles. They are a flexible tool for segmenting data and triggering workflows.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/labels`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/labels/Index.vue`. This page displays a list of existing labels and provides options to add new labels or edit/delete existing ones.
    -   **Label List**: Usually a table showing label title, color, description, and potentially usage count.
        -   Component: `LabelList.vue` or `LabelsTable.vue` (e.g., `app/javascript/dashboard/components/widgets/LabelManagement/LabelsTable.vue`).
    -   **"Add Label" / "Create Label" Button**: Opens a modal for creating a new label.
        -   Modal Component: `AddLabelModal.vue` or `NewLabelModal.vue` (e.g., `app/javascript/dashboard/components/widgets/LabelManagement/AddLabelModal.vue`).

-   **Edit Label Modal**:
    -   Accessed by clicking an "Edit" button for a label.
    -   Allows modification of label title, description, and color.
    -   Component: `EditLabelModal.vue`, often similar to the "Add Label" modal.

## Key Functionalities

### 1. Listing Labels
-   **Fetching Labels**:
    -   Vuex action: `labels/get` (`app/javascript/dashboard/store/modules/labels.js`).
    -   API: `GET /api/v1/accounts/{account_id}/labels` via `LabelsAPI.get()` (`app/javascript/dashboard/api/labels.js`).
    -   Controller: `app/controllers/api/v1/accounts/labels_controller.rb#index`.

### 2. Creating a New Label
-   **Frontend Process**:
    -   Admin fills out a form with label title, description (optional), and selects a color.
    -   Vuex action: `labels/create`.
    -   API: `POST /api/v1/accounts/{account_id}/labels` via `LabelsAPI.create()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/labels_controller.rb#create`.
    -   Payload: `title`, `description`, `color`, `show_on_sidebar`.
    -   Creates a new `Label` record.
    -   Model: `Label` (`app/models/label.rb`).

### 3. Editing Label Details
-   **Frontend Process**:
    -   Admin modifies title, description, or color.
    -   Vuex action: `labels/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/labels/{label_id}` via `LabelsAPI.update()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/labels_controller.rb#update`.
    -   Updates attributes on the `Label` record.

### 4. Deleting a Label
-   **Frontend Process**:
    -   Admin confirms the deletion.
    -   Vuex action: `labels/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/labels/{label_id}` via `LabelsAPI.delete()`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/labels_controller.rb#destroy`.
    -   Deletes the `Label` record.
    -   Associated `conversations_labels` and `contacts_labels` join records are typically deleted due to database foreign key constraints or `dependent: :destroy` on the associations in the `Label` model.

### 5. Using Labels
-   **Applying to Conversations**:
    -   UI: `ConversationLabels.vue` (`app/javascript/dashboard/components/widgets/conversation/ConversationLabels.vue`) within the `ConversationInfoPanel.vue`.
    -   API: `POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/labels` (handled by `app/controllers/api/v1/accounts/conversations/labels_controller.rb#update`).
-   **Applying to Contacts**:
    -   UI: `ContactLabels.vue` (`app/javascript/dashboard/components-next/contacts/ContactLabels.vue`).
    -   API: `POST /api/v1/accounts/{account_id}/contacts/{contact_id}/labels` (handled by `app/controllers/api/v1/accounts/contacts_controller.rb#update_labels`).
-   **Filtering**: Conversations and contacts can be filtered by labels in their respective list views.
-   **Reporting**: Label reports provide insights into how frequently labels are used and on which conversations. (`app/javascript/dashboard/routes/dashboard/reports/LabelReport.vue`).

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/labels.js`**:
    -   Manages the list of labels for the account and UI flags.
    -   State: `records` (array of label objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`.
    -   Mutations: `SET_LABELS_UI_FLAG`, `SET_LABELS`, `ADD_LABEL`, `EDIT_LABEL`, `DELETE_LABEL`.

## Backend API Endpoints & Models

-   **Model**: `Label` (`app/models/label.rb`)
    -   Attributes: `title`, `description`, `color` (e.g., hex code), `account_id`, `show_on_sidebar` (boolean).
    -   Associations:
        -   `has_many :conversations_labels, dependent: :destroy`
        -   `has_many :conversations, through: :conversations_labels`
        -   `has_many :contacts_labels, dependent: :destroy`
        -   `has_many :contacts, through: :contacts_labels`
    -   Validations: `validates :title, presence: true`, uniqueness scoped to `account_id`.
-   **Join Models**:
    -   `ConversationsLabel` (`app/models/conversations_label.rb`): Joins `Conversation` and `Label`.
    -   `ContactsLabel` (`app/models/contacts_label.rb`): Joins `Contact` and `Label`.
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/labels_controller.rb`: CRUD operations for labels.
    -   `app/controllers/api/v1/accounts/conversations/labels_controller.rb`: Handles assigning/unassigning labels to conversations.
    -   `app/controllers/api/v1/accounts/contacts_controller.rb#update_labels`: Handles assigning/unassigning labels to contacts.

Labels are a simple yet powerful feature for enhancing organization and data analysis within Chatwoot.
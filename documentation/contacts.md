# Dashboard: Contact Management

Contact management in Chatwoot provides a centralized repository for all customer information, interaction history, and associated metadata. This allows agents to have a comprehensive view of the customer they are interacting with and for the system to track customers across sessions and channels.

## Overview

The contact management section in the dashboard allows users to view lists of contacts, search for specific contacts, view detailed contact profiles, create, edit, and merge contacts, add notes, and see their conversation history. Contacts are automatically created when new conversations are initiated from unidentified users, or can be managed manually.

## Key UI Components and Layout

1.  **Contact List View**:
    -   Route: `/app/accounts/{account_id}/contacts`
    -   Main component: `app/javascript/dashboard/routes/dashboard/contacts/Index.vue`.
        -   Uses `ContactsView.vue` (`app/javascript/dashboard/components-next/contacts/ContactsView.vue`) which includes:
            -   `ContactsTable.vue` (`app/javascript/dashboard/components-next/contacts/ContactsTable.vue`) to display contacts.
            -   Filtering and sorting options.
            -   "New Contact" button (`NewContactForm.vue` - `app/javascript/dashboard/components-next/contacts/NewContactForm.vue`).
    -   Each contact row shows: Name, Email, Phone, Company, Last Activity.

2.  **Contact Detail View (`ContactContent.vue`)**:
    -   Route: `/app/accounts/{account_id}/contacts/{contact_id}`
    -   Main component: `app/javascript/dashboard/routes/dashboard/contacts/Show.vue` which uses `ContactContentPage.vue` (`app/javascript/dashboard/components-next/contacts/ContactContentPage.vue`).
    -   This view includes several tabs/sections:
        -   **Contact Profile Pane (`ContactHeader.vue`, `ContactAttributes.vue`)**:
            -   `app/javascript/dashboard/components-next/contacts/ContactHeader.vue`: Displays avatar, name, actions (Edit, Merge, Delete).
            -   `app/javascript/dashboard/components-next/contacts/ContactAttributes.vue`: Shows core and custom attributes.
            -   Editing is done via `EditContact.vue` (`app/javascript/dashboard/components-next/contacts/EditContact.vue`).
        -   **Related Conversations (`ContactConversations.vue`)**:
            -   `app/javascript/dashboard/components-next/contacts/ContactConversations.vue`: Lists past conversations with the contact.
        -   **Contact Notes (`ContactNotes.vue`)**:
            -   `app/javascript/dashboard/components-next/contacts/ContactNotes.vue`: Section to add and view internal notes.
        -   **Contact Labels (`ContactLabels.vue`)**:
            -   `app/javascript/dashboard/components-next/contacts/ContactLabels.vue`: Allows applying and viewing labels.

## Core Functionalities

### 1. Viewing and Searching Contacts
-   **Listing Contacts**:
    -   Vuex action: `contacts/get` (`app/javascript/dashboard/store/modules/contacts.js`).
    -   API: `GET /api/v1/accounts/{account_id}/contacts` via `ContactsAPI.get()` (`app/javascript/dashboard/api/contacts.js`).
    -   Supports pagination, sorting (`sort_attribute`), search query (`q`), and filtering by labels.
-   **Searching Contacts**: Input field in `ContactsTable.vue` triggers API search.
-   **Filtering Contacts**: By labels using `ContactLabelsFilter.vue` (`app/javascript/dashboard/components-next/contacts/ContactLabelsFilter.vue`).

### 2. Viewing Contact Profile
-   **Fetching Contact Details**:
    -   Vuex action: `contacts/show` or `contacts/getSingleContact`.
    -   API: `GET /api/v1/accounts/{account_id}/contacts/{contact_id}` via `ContactsAPI.show()`.
-   **Displaying Information**: Avatar, name, email, phone, bio, location, company, social profiles, custom attributes, labels, conversation history, notes.

### 3. Creating and Updating Contacts
-   **Creating Contacts**:
    -   UI: `NewContactForm.vue`.
    -   Vuex action: `contacts/create`.
    -   API: `POST /api/v1/accounts/{account_id}/contacts` via `ContactsAPI.create()`.
    -   Payload: `name`, `email`, `phone_number`, `company_name`, `country_code`, `city`, `custom_attributes`.
-   **Updating Contacts**:
    -   UI: `EditContact.vue`.
    -   Vuex action: `contacts/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/contacts/{contact_id}` via `ContactsAPI.update()`.
    -   Avatar upload is part of this, handled by `w-uploader` in `EditContactAvatar.vue`.
-   **Avatar Management**:
    -   `app/models/contact.rb` uses `has_one_attached :avatar` (ActiveStorage).
    -   `ContactsController#update` handles `avatar` param.

### 4. Contact Merging
-   **Identifying and Merging**:
    -   UI: `MergeContacts.vue` (`app/javascript/dashboard/components-next/contacts/MergeContacts.vue`) modal, initiated from `ContactHeader.vue`.
    -   Vuex action: `contacts/merge`.
    -   API: `POST /api/v1/accounts/{account_id}/contacts/{base_contact_id}/merge/{other_contact_id}` via `ContactsAPI.merge()`.
    -   Backend: `app/controllers/api/v1/accounts/contacts_controller.rb#merge`. Uses `Contacts::MergeService` (`app/services/contacts/merge_service.rb`).

### 5. Contact Notes
-   **Adding and Viewing Notes**:
    -   UI: `ContactNotes.vue`.
    -   Vuex actions: `contacts/addNote`, `contacts/deleteNote`.
    -   API: `POST /api/v1/accounts/{account_id}/contacts/{contact_id}/notes` and `DELETE /api/v1/accounts/{account_id}/contacts/{contact_id}/notes/{note_id}` via `ContactsAPI.addNote()`, `ContactsAPI.deleteNote()`.
    -   Controller: `app/controllers/api/v1/accounts/contacts/notes_controller.rb`.
    -   Model: `Note` (`app/models/note.rb`) with `record_type: 'Contact', record_id: contact.id`.

### 6. Contact Labels
-   **Applying Labels**:
    -   UI: `ContactLabels.vue`.
    -   Vuex action: `contacts/updateLabels`.
    -   API: `POST /api/v1/accounts/{account_id}/contacts/{contact_id}/labels` (same as conversations, but context is contact) via `ContactsAPI.updateLabels()`.
    -   Controller: `app/controllers/api/v1/accounts/contacts_controller.rb#update_labels`. (Note: This seems to be the correct controller action for contacts, not a separate `labels_controller` under contacts).
    -   Labels themselves are managed globally (`app/controllers/api/v1/accounts/labels_controller.rb`).

### 7. Custom Attributes
-   **Storing Additional Data**:
    -   Stored in `custom_attributes` JSONB field on `Contact` model.
    -   Displayed and editable in `ContactAttributes.vue` and `EditContact.vue`.
    -   Configuration of available custom attributes (`attribute_model: 'contact_attribute'`) is done in Account Settings (`CustomAttributes.vue` under settings).

### 8. Contact Import/Export
-   **Importing Contacts**:
    -   UI: `ImportContacts.vue` (`app/javascript/dashboard/components-next/contacts/ImportContacts.vue`).
    -   API: `POST /api/v1/accounts/{account_id}/contacts/import` via `ContactsAPI.import()`.
    -   Controller: `app/controllers/api/v1/accounts/contacts_controller.rb#import`.
    -   Uses background job `Contacts::ImportJob` (`app/jobs/account/contacts/import_job.rb`).
-   **Exporting Contacts**:
    -   Not explicitly visible as a UI button in the standard list view, but the API supports it.
    -   `ContactsController#index` action responds to `format: :csv` for exporting.
    -   `Contacts::ExportService` (`app/services/contacts/export_service.rb`) generates the CSV.

### 9. Deleting Contacts
-   UI: Option in `ContactHeader.vue`.
-   Vuex action: `contacts/delete`.
-   API: `DELETE /api/v1/accounts/{account_id}/contacts/{contact_id}` via `ContactsAPI.delete()`.
-   Controller: `app/controllers/api/v1/accounts/contacts_controller.rb#destroy`.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/contacts.js`**:
    -   Manages list of contacts, individual contact details, UI flags (loading states), notes.
    -   Actions: `get`, `show`, `create`, `update`, `delete`, `merge`, `addNote`, `deleteNote`, `updateLabels`, `import`, `fetchAllContacts`.
    -   Mutations: `SET_CONTACTS_UI_FLAG`, `SET_CONTACTS`, `SET_CONTACT_ITEM`, `ADD_CONTACT`, `EDIT_CONTACT`, `DELETE_CONTACT`, `ADD_CONTACT_NOTE`, `DELETE_CONTACT_NOTE`, `SET_CONTACT_META`.

## Backend API Endpoints & Models

-   **Model**: `app/models/contact.rb`
    -   Attributes: `name`, `email`, `phone_number`, `identifier` (for external systems), `custom_attributes`, `additional_attributes`, `company_id`, `country_code`, `city`, `bio`.
    -   Associations: `belongs_to :account`, `belongs_to :company, optional: true`, `has_many :conversations`, `has_many :contact_inboxes`, `has_many :inboxes, through: :contact_inboxes`, `has_one_attached :avatar`, `has_many :notes, as: :record, dependent: :destroy_async`.
    -   Methods: `search_on_email_and_phone_number`, `search_by_name_or_identifier`, `merged_contacts_ids_with_self`.
    -   Uses `Labelable` concern for label associations (`app/models/concerns/labelable.rb`).
-   **Controllers**:
    -   `app/controllers/api/v1/accounts/contacts_controller.rb`: Handles CRUD, search, import, merge, label updates, filtering.
    -   `app/controllers/api/v1/accounts/contacts/notes_controller.rb`: Manages notes associated with contacts.
    -   `app/controllers/api/v1/accounts/contacts/conversations_controller.rb`: Lists conversations for a specific contact (`index` action).
    -   `app/controllers/api/v1/accounts/contacts/contact_inboxes_controller.rb`: Manages `ContactInbox` records, linking contacts to inboxes.
-   **Services**:
    -   `Contacts::MergeService` (`app/services/contacts/merge_service.rb`): Logic for merging two contact profiles.
    -   `Contacts::FilterService` (`app/services/contacts/filter_service.rb`): Handles complex filtering logic for contacts (used by `ContactsController#index`).
    -   `Contacts::ExportService` (`app/services/contacts/export_service.rb`): Generates CSV for export.
    -   `Contacts::IdentifyService` (`app/services/contacts/identify_service.rb`): Finds or creates contacts based on identifiers, email, phone.

This provides a comprehensive overview of contact management in the Chatwoot dashboard.
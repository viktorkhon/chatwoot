# Dashboard: Custom Attribute Management

Custom Attributes in Chatwoot allow administrators to define additional data fields that can be associated with conversations or contacts. This enables businesses to store and track specific information relevant to their workflows and customer interactions.

## Overview

Custom attributes extend the standard data model of Chatwoot, providing flexibility to capture domain-specific information. For example, an e-commerce business might add attributes like "Order ID" or "Subscription Plan" to conversations or contacts.

## Access and UI Components

-   **Route**: `/app/accounts/{account_id}/settings/custom-attributes`
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/attributes/Index.vue`. This page typically has tabs or sections for "Conversation Attributes" and "Contact Attributes".
    -   **Attribute List**: Displays existing custom attributes for the selected type (Conversation or Contact). Shows attribute display name, key, type, and description.
        -   Component: `AttributesTable.vue` or similar (e.g., within `app/javascript/dashboard/components/ui/settings/customAttributes/`).
    -   **"Add Attribute" Button**: Opens a modal for creating a new custom attribute.
        -   Modal Component: `AddAttributeModal.vue` or similar (e.g., `app/javascript/dashboard/components/ui/settings/customAttributes/AddAttributeModal.vue`).

-   **Edit Attribute Modal**:
    -   Accessed by clicking an "Edit" button for an attribute.
    -   Allows modification of display name, description, and potentially other settings (though type and key are usually fixed after creation).

## Key Functionalities

### 1. Listing Custom Attributes
-   **Fetching Attributes**:
    -   Vuex action: `customAttributes/get` (`app/javascript/dashboard/store/modules/customAttributes.js`).
    -   API: `GET /api/v1/accounts/{account_id}/custom_attribute_definitions` via `CustomAttributesAPI.get()` (`app/javascript/dashboard/api/customAttributes.js`).
        -   Parameter: `attribute_model` (0 for Conversation, 1 for Contact).
    -   Controller: `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb#index`.

### 2. Creating a New Custom Attribute Definition
-   **Frontend Process**:
    -   Admin fills out a form:
        -   `attribute_display_name`: User-friendly name shown in the UI.
        -   `attribute_key`: Unique machine-readable key (e.g., "order_id", "customer_tier"). Automatically generated from display name if not provided, or user-defined.
        -   `attribute_model`: "Conversation" or "Contact".
        -   `attribute_display_type`: Data type (Text, Number, Currency, Percent, Link, Date, List, Checkbox).
        -   `attribute_description`: Optional description.
        -   For "List" type: `attribute_values` (array of possible options).
        -   `default_value` (for checkbox type).
    -   Vuex action: `customAttributes/create`.
    -   API: `POST /api/v1/accounts/{account_id}/custom_attribute_definitions`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb#create`.
    -   Creates a new `CustomAttributeDefinition` record.
    -   Model: `CustomAttributeDefinition` (`app/models/custom_attribute_definition.rb`).

### 3. Editing Custom Attribute Definition
-   **Frontend Process**:
    -   Admin modifies display name, description, list values.
    -   Vuex action: `customAttributes/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/custom_attribute_definitions/{definition_id}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb#update`.
    -   Updates the `CustomAttributeDefinition` record.

### 4. Deleting a Custom Attribute Definition
-   **Frontend Process**:
    -   Admin confirms deletion.
    -   Vuex action: `customAttributes/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/custom_attribute_definitions/{definition_id}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb#destroy`.
    -   Deletes the `CustomAttributeDefinition` record.
    -   **Data Impact**: Deleting a definition does not automatically delete the attribute *values* already stored on existing conversations or contacts. These values might become orphaned or no longer editable/filterable through the standard UI. This behavior should be noted.

### 5. Using Custom Attributes (Setting Values)

-   **On Conversations**:
    -   UI: In the conversation sidebar (`ConversationInfoPanel.vue` - `app/javascript/dashboard/components-next/conversations/ConversationInfoPanel.vue`), there's usually a section for custom attributes.
        -   Component: `CustomAttributes.vue` (`app/javascript/dashboard/components/conversations/customAttributes/CustomAttributes.vue`).
    -   Agents can view and edit values for defined conversation attributes.
    -   Data is stored in the `custom_attributes` JSONB field of the `Conversation` model (`app/models/conversation.rb`).
    -   Updating values typically goes through the Conversation update API: `PATCH /api/v1/accounts/{account_id}/conversations/{conversation_id}` with a `custom_attributes` hash in the payload.
-   **On Contacts**:
    -   UI: In the contact profile view (`ContactAttributes.vue` - `app/javascript/dashboard/components-next/contacts/ContactAttributes.vue` or `EditContact.vue`).
    -   Agents can view and edit values for defined contact attributes.
    -   Data is stored in the `custom_attributes` JSONB field of the `Contact` model (`app/models/contact.rb`).
    -   Updating values typically goes through the Contact update API: `PATCH /api/v1/accounts/{account_id}/contacts/{contact_id}` with a `custom_attributes` hash in the payload.

### 6. Filtering and Automation
-   Custom attributes can often be used as conditions in Automation Rules.
-   Conversation and contact lists can be filtered based on custom attribute values (e.g., using advanced filters).

## Custom Attribute Definition Structure (Model Level)

-   `app/models/custom_attribute_definition.rb`:
    -   `attribute_display_name` (string)
    -   `attribute_key` (string, unique per account and model type)
    -   `attribute_display_type` (integer enum: `text`, `number`, `currency`, `percent`, `link`, `date`, `list`, `checkbox`)
    -   `attribute_description` (text)
    -   `attribute_model` (integer enum: `conversation_attribute`, `contact_attribute`)
    -   `default_value` (string, for checkbox default state)
    -   `attribute_values` (JSONB array, for 'list' type options)
    -   `account_id`

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/customAttributes.js`**:
    -   Manages custom attribute definitions for the account.
    -   State: `records` (array of definitions), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`.
    -   Mutations: `SET_CUSTOM_ATTRIBUTES_UI_FLAG`, `SET_CUSTOM_ATTRIBUTES`, `ADD_CUSTOM_ATTRIBUTE`, `EDIT_CUSTOM_ATTRIBUTE`, `DELETE_CUSTOM_ATTRIBUTE`.

## Backend Structure

-   **Model**: `CustomAttributeDefinition` (`app/models/custom_attribute_definition.rb`).
-   **Controller**: `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb`.
-   **Value Storage**:
    -   `Conversation.custom_attributes` (JSONB field on `app/models/conversation.rb`).
    -   `Contact.custom_attributes` (JSONB field on `app/models/contact.rb`).

Custom attributes provide significant power to tailor Chatwoot to specific business needs by capturing and utilizing relevant contextual data.
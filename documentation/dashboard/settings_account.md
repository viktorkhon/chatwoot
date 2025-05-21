# Dashboard: Account Settings

Account Settings in Chatwoot allow administrators to manage core configurations related to their organization's Chatwoot instance, including profile information, general preferences, and security options.

## Overview

This section is central to personalizing the Chatwoot experience for the entire account. It typically covers aspects like account name, locale, auto-resolution duration, and other global parameters.

## Access and UI Components

-   **Route**: Usually part of `/app/accounts/{account_id}/settings/general` or a similar sub-route under the main settings layout. The specific route might be `/app/accounts/{account_id}/settings/profile` for the user's own profile, and `/app/accounts/{account_id}/settings/account` for overarching account settings.
-   **Main Component**: `app/javascript/dashboard/routes/dashboard/settings/account/Index.vue` (or a similarly named component like `AccountSettings.vue`). This component houses the forms and logic for displaying and updating account settings.
    -   It often includes `SettingsSection.vue` or similar wrapper components for structuring the page.

## Key Functionalities and Settings

### 1. General Account Information
-   **Account Name**:
    -   UI: Input field in the account settings form.
    -   Vuex: State managed in `accounts` module (`app/javascript/dashboard/store/modules/accounts.js`), potentially `state.records[accountId].name`.
    -   Action: `accounts/update` (or similar).
    -   API: `PUT /api/v1/accounts/{account_id}`.
    -   Controller: `app/controllers/api/v1/accounts_controller.rb#update`.
    -   Model: `Account` model (`app/models/account.rb`), `name` attribute.
-   **Locale (Default Language)**:
    -   UI: Dropdown selector.
    -   Vuex: `accounts` module, `state.records[accountId].locale`.
    -   API: Part of the `PUT /api/v1/accounts/{account_id}` payload.
    -   Model: `Account` model, `locale` attribute. This sets the default language for the account.
-   **Domain**:
    -   UI: Input field, often for custom domain mapping or identification.
    -   Model: `Account` model, `domain` attribute.
-   **Support Email**:
    -   UI: Input field.
    -   Model: `Account` model, `support_email` attribute.

### 2. Auto Resolution Duration
-   **Conversation Auto-resolve Duration**:
    -   UI: Input for number of days. If a conversation remains in `open` status with no activity for this duration, it might be automatically resolved.
    -   Vuex: `accounts` module, e.g., `state.records[accountId].auto_resolve_duration`.
    -   API: Part of the `PUT /api/v1/accounts/{account_id}` payload.
    -   Model: `Account` model, `auto_resolve_duration` attribute (integer, number of days).
    -   Backend Logic: A background job (`Conversations::ResolutionJob` - `app/jobs/conversations/resolution_job.rb`) likely runs periodically to check and resolve stale conversations based on this setting.

### 3. In-App Notifications Settings (Account-wide defaults)
-   **Email Notifications for new conversations/messages**:
    -   UI: Toggles for enabling/disabling these for the account.
    -   Vuex: `accounts` module, possibly attributes like `state.records[accountId].notifications_config.email_conversation_creation`, etc.
    -   Model: `Account` model, storing these preferences (perhaps in a JSONB field like `feature_flags` or specific columns).
    -   Backend: This influences the behavior of notification mailers.

### 4. Chat Widget Appearance (Default for new web widgets)
-   **Widget Color**:
    -   UI: Color picker.
    -   Model: `Account` model, attribute like `widget_color`. This sets a default color for new web widget inboxes created for this account. Individual inboxes can override this.
-   **Other widget defaults**: Such as `welcome_title`, `welcome_tagline`.

### 5. Security Settings (May vary based on edition)
-   **Two-Factor Authentication (2FA) enforcement for all users**:
    -   UI: A toggle for administrators to enforce 2FA.
    -   Model: `Account` model, a flag like `enforce_2fa`.
    -   Backend Logic: This would affect the login flow for all users under the account.
-   **IP Whitelisting/Restrictions**: (Enterprise feature)
    -   UI: Interface to manage allowed IP addresses.

### 6. Data Management
-   **Account Deletion**:
    -   UI: A "Delete Account" button, often with confirmations.
    -   Vuex Action: `accounts/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}`.
    -   Controller: `app/controllers/api/v1/accounts_controller.rb#destroy`.
    -   Backend Logic: This is a destructive operation and will trigger cascading deletions or data anonymization based on compliance requirements. A background job (`Account::DeleteJob` - `app/jobs/account/delete_job.rb`) likely handles the actual deletion.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/accounts.js`**:
    -   Manages the current account's data.
    -   State: `records` (object mapping account ID to account data), `uiFlags`.
    -   Actions: `get` (fetches current account details), `update` (updates account settings).
    -   Mutations: `SET_ACCOUNTS_UI_FLAG`, `SET_ACCOUNT`, `UPDATE_ACCOUNT`.

## Backend API Endpoints & Models

-   **Model**: `app/models/account.rb`
    -   Core model for all account-specific data and settings.
    -   Attributes mentioned above: `name`, `locale`, `auto_resolve_duration`, `widget_color`, `support_email`, `domain`, `feature_flags` (JSONB, often used for various toggles), `limits` (JSONB for feature limits).
    -   Callbacks: `after_create :notify_creation`, `after_create :setup_defaults`.
-   **Controller**: `app/controllers/api/v1/accounts_controller.rb`
    -   `show`: Retrieves current account details.
    -   `update`: Modifies account settings.
    -   `destroy`: Deletes the account.
-   **Jobs**:
    -   `Conversations::ResolutionJob`: Handles auto-resolution of conversations.
    -   `Account::DeleteJob`: Handles the asynchronous deletion of an account and its associated data.

This documentation provides a foundational understanding of the Account Settings section. Specific implementations can vary, especially with enterprise features, but the core concepts of updating the `Account` model via the `AccountsController` remain consistent.
# Dashboard: Help Center - Portal Settings Management

Portal Settings Management in Chatwoot allows administrators to create and configure individual Help Center portals. Each portal acts as a distinct knowledge base instance with its own branding, content, and access settings.

## Overview

An account can have multiple portals, enabling businesses to cater to different products, brands, or languages with separate Help Centers. This section of the dashboard focuses on the setup and customization of these portals.

## Access and UI Components

-   **Route for Listing Portals (if multiple exist)**: `/app/accounts/{account_id}/settings/help-center` (or a similar central settings page for Help Centers).
    -   Component: `app/javascript/dashboard/routes/dashboard/settings/helpCenter/Index.vue` or `PortalsList.vue`.
    -   Displays existing portals with options to "Add Portal", "Edit Settings", or "Manage Content".

-   **Route for Specific Portal Settings**: Accessed by editing a portal from the list, or via a "Settings" tab within a portal's content management view (e.g., `/app/accounts/{account_id}/portals/{portal_slug}/settings` or `/app/accounts/{account_id}/portals/{portal_slug}/general-settings`).
    -   Component: `PortalSettings.vue` or similar, likely within `app/javascript/dashboard/routes/dashboard/portal/settings/` or `app/javascript/dashboard/components/portal/settings/`.
    -   This form-based view allows configuration of:
        -   Portal Name
        -   Slug (URL identifier)
        -   Custom Domain
        -   Default Locale (language)
        -   Header Text / Welcome Message
        -   Homepage Link
        -   Color Theme / Branding options (e.g., logo, primary color)
        -   Archiving/Activating a portal.

-   **"Add Portal" / "New Portal" Form/Modal**:
    -   Component: `AddPortalModal.vue` or a dedicated page like `app/javascript/dashboard/routes/dashboard/settings/helpCenter/NewPortal.vue`.
    -   Collects initial portal details like name, slug, and locale.

## Key Functionalities

### 1. Listing Portals
-   **Fetching Portals**:
    -   Vuex action: `portals/get` (`app/javascript/dashboard/store/modules/portals.js`).
    -   API: `GET /api/v1/accounts/{account_id}/portals`.
    -   Controller: `app/controllers/api/v1/accounts/portals_controller.rb#index`.

### 2. Creating a New Portal
-   **Frontend Process**:
    -   Admin fills out the new portal form (name, slug, locale).
    -   Vuex action: `portals/create`.
    -   API: `POST /api/v1/accounts/{account_id}/portals`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/portals_controller.rb#create`.
    -   Payload: `name`, `slug`, `default_locale`, `config` (for color, header text etc.).
    -   Creates a new `Portal` record.
    -   Model: `Portal` (`app/models/portal.rb`).

### 3. Editing Portal Settings
-   **Frontend Process**:
    -   Admin modifies portal details (name, slug, custom domain, locale, color, header text, homepage link).
    -   Vuex action: `portals/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/portals/{portal_id_or_slug}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/portals_controller.rb#update`.
    -   Updates the `Portal` record, including its `config` JSONB field for branding settings.
    -   Custom domain setup might involve DNS configuration instructions for the user.

### 4. Archiving/Unarchiving a Portal
-   **Functionality**: Instead of outright deletion, portals can often be archived, making them inaccessible publicly but retaining their content and configuration.
-   **Frontend Process**: Toggle or button in portal settings.
-   **Backend Process**:
    -   Updates a `status` or `archived` attribute on the `Portal` model.
    -   Archived portals won't be served by the public controllers.

### 5. Deleting a Portal (If supported directly, otherwise Archive is common)
-   **Frontend Process**:
    -   Admin confirms deletion.
    -   Vuex action: `portals/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/portals/{portal_id_or_slug}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/portals_controller.rb#destroy`.
    -   Deletes the `Portal` record.
    -   **Data Impact**: This is a destructive action. All associated categories and articles within that portal will also be deleted due to `dependent: :destroy` associations.

## Portal Model Details

-   `app/models/portal.rb`:
    -   `name` (string)
    -   `slug` (string, unique per account)
    -   `custom_domain` (string, optional)
    -   `default_locale` (string, e.g., 'en')
    -   `color` (string, for theme) - This might be part of `config`.
    -   `header_text` (string) - This might be part of `config`.
    -   `homepage_link` (string) - This might be part of `config`.
    -   `page_title` (string) - This might be part of `config`.
    -   `logo` (ActiveStorage attachment) - This might be part of `config` if using URLs, or directly attached.
    -   `config` (JSONB): Stores various settings like:
        -   `allowed_locales` (array of supported languages for this portal)
        -   `theme_color`
        -   `navigation_title`
        -   `custom_script_url`
    -   `account_id`
    -   `archived` (boolean, default false)
    -   Associations: `has_many :categories, dependent: :destroy`, `has_many :articles, dependent: :destroy`, `belongs_to :account`.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/portals.js`**:
    -   Manages portal data for the account.
    -   State: `records` (array of portal objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`.
    -   Mutations: `SET_PORTALS_UI_FLAG`, `SET_PORTALS`, `ADD_PORTAL`, `EDIT_PORTAL`, `DELETE_PORTAL`.

## Backend API

-   `app/controllers/api/v1/accounts/portals_controller.rb`: Provides CRUD operations for portals.

Portal settings are fundamental to customizing the look, feel, and accessibility of each Help Center instance provided by Chatwoot.
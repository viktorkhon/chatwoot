# Chatwoot Dashboard: Overview

The Chatwoot Dashboard is the primary interface for agents and administrators to manage customer interactions, configure settings, and analyze support performance. It's a modern Single Page Application (SPA) built primarily using Vue.js (version 3).

## Access and Entry Point

-   **Backend Controller**: Served by `app/controllers/dashboard_controller.rb` through its `index` action. This action renders the main HTML page (`app/views/dashboard/index.html.erb`) which then loads the Vue.js application.
-   **Frontend Main File**: The JavaScript application is initialized from `app/javascript/dashboard/main.js`. This file sets up the Vue app instance, router, store (Vuex), i18n, and mounts the root `App.vue` component.
-   **Core Vue Application**: The root Vue component is `app/javascript/dashboard/App.vue`. It sets up the main layout, including global components like notifications, command bar, and sidebar navigation, and uses `<router-view />` to render page-specific content.

## Key Sections and Functionality (High-Level)

The dashboard is organized into several key areas, typically accessible via a dynamic sidebar navigation menu (`app/javascript/dashboard/components/layout/sidebar/Index.vue` which uses `app/javascript/dashboard/components/layout/sidebar/menu.js` to define menu items):

1.  **Conversations View**: (`/app/accounts/:account_id/conversations/:conversation_id?`)
    -   Central hub for managing customer conversations from all channels.
    -   Includes filtering, searching, and assignment.
    -   Displays lists of conversations and a dedicated view for individual interactions.

2.  **Contacts**: (`/app/accounts/:account_id/contacts/:contact_id?`)
    -   Management of customer profiles, interaction history, notes, and labels.
    -   Segmentation capabilities through filtering.

3.  **Reports**: (`/app/accounts/:account_id/reports`)
    -   Provides insights into support operations (agent, conversation, CSAT, label, inbox, team reports).
    -   Includes a Live View (`/app/accounts/:account_id/live_reports`).

4.  **Campaigns**: (`/app/accounts/:account_id/campaigns`)
    -   Creating and managing outbound messaging campaigns.

5.  **Help Center**: (`/app/accounts/:account_id/portals/:portal_slug?`)
    -   Managing articles, categories, and settings for the customer-facing help center.

6.  **Settings**: (`/app/accounts/:account_id/settings`)
    -   This is a broad area, with sub-sections typically including:
        -   Account Settings (`profile`, `agents`, `teams`, `inboxes`, `labels`, `canned_responses`, `integrations`, `automation`, `custom_attributes`, `billing` [if EE], `sla` [if EE], etc.)

## Core Technologies and Architecture (Frontend)

-   **Framework**: Vue.js 3.
    -   Utilizes the Composition API (`app/javascript/dashboard/composables/`).
-   **Routing**: `vue-router` (version 4). Routes are defined in `app/javascript/dashboard/routes/index.js` and further organized by feature in nested `routes.js` files (e.g., `app/javascript/dashboard/routes/dashboard/conversation/routes.js`).
-   **State Management**: Vuex (version 4). The global store is configured in `app/javascript/dashboard/store/index.js`, with modules for different features (e.g., `app/javascript/dashboard/store/modules/conversations.js`, `app/javascript/dashboard/store/modules/contacts.js`).
-   **API Communication**: Axios. A pre-configured Axios instance is available as `this.$http` in components, or imported directly. API client services are often grouped in `app/javascript/dashboard/api/` (e.g., `ContactsAPI.js`, `ConversationsAPI.js`).
-   **Real-time Updates**: Uses ActionCable via `CableProvider` (`app/javascript/shared/helpers/actionCable.js` and `app/javascript/dashboard/helper/actionCable.js`). Vuex modules subscribe to events to update data in real-time (e.g., new messages, presence updates).
-   **UI Components**:
    -   Primarily custom-built components located in `app/javascript/dashboard/components/` and `app/javascript/dashboard/components-next/`.
    -   Styling is done using Tailwind CSS (see `tailwind.config.js` and `app/javascript/dashboard/assets/scss/tailwind.scss`).
    -   A set of base UI elements and design tokens might be part of `app/javascript/design-system/` (though this folder seems more focused on images currently).
    -   Uses `vite-svg-loader` for SVG icons.
-   **Internationalization (i18n)**: `vue-i18n` is used for multi-language support. Translations are in `app/javascript/dashboard/i18n/` (e.g., `locale/en.json`). The setup is in `app/javascript/dashboard/i18n/index.js`.
-   **Forms and Validation**: Uses `vee-validate` for form validation, as seen in `main.js` and various form components.
-   **Command Bar**: A global command bar (`CmdKHotKeys` component - `app/javascript/dashboard/components/CmdKHotKeys.vue`) for quick navigation and actions.

## Key Frontend Directories

-   `app/javascript/dashboard/`: Root directory for the dashboard SPA.
    -   `api/`: API client services/modules.
    -   `assets/`: Static assets like SCSS files, images.
    -   `components/`: Reusable Vue components (older and general).
    -   `components-next/`: Potentially newer or refactored components, often feature-specific.
    -   `composables/`: Vue 3 Composition API functions.
    -   `constants/`: Application-wide constants (e.g., `routes.js`, `dashboardApps.js`).
    -   `helper/`: Utility functions specific to the dashboard.
    -   `i18n/`: Localization files and setup.
    -   `modules/`: Contains self-contained feature modules (Vuex store, routes, components), e.g., `settings/custom_attributes`.
    -   `routes/`: Vue Router configuration, with sub-directories for route groups.
    -   `store/`: Vuex store setup and modules.
    -   `views/` (Implicitly, these are the main components linked in the router files, e.g., `app/javascript/dashboard/routes/dashboard/settings/SettingsLayout.vue`).
-   `app/javascript/shared/`: JavaScript code shared across different frontend applications (dashboard, widget, etc.).
    -   `components/`: Shared Vue components.
    -   `composables/`: Shared Vue 3 composables.
    -   `helpers/`: Shared utility functions.
-   `app/javascript/v3/`: Appears to be a newer section or a gradual rewrite, potentially for specific parts of the UI, also using Vue 3.

This overview sets the stage for more detailed documentation of specific dashboard features like Conversation Management, Contact Management, Reports, and various Settings sections.
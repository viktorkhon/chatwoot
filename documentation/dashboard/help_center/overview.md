# Dashboard: Help Center Overview

Chatwoot includes a built-in Help Center feature that allows businesses to create and publish a self-service knowledge base for their customers. This section of the dashboard is where administrators manage the content and settings of their Help Center portal(s).

## Overview

The Help Center consists of one or more Portals. Each Portal can have its own branding, custom domain, and a collection of Categories and Articles. This allows businesses to provide targeted self-help resources, reduce common support queries, and empower customers to find answers independently.

## Access and Main Layout

-   **Main Route for Portals List**: `/app/accounts/{account_id}/settings/help-center` (or a similar settings path that lists all portals).
-   **Route to a Specific Portal's Content Management**: `/app/accounts/{account_id}/portals/{portal_slug}`. This is the primary area for managing categories and articles for a specific portal.
-   **Key UI Components**:
    -   **Portal List View** (if multiple portals are supported and managed from a central settings page):
        -   Lists created portals with options to edit settings or navigate to content management.
        -   `app/javascript/dashboard/routes/dashboard/settings/helpCenter/Index.vue` (or similar).
    -   **Portal Content Management View**:
        -   Main layout component: `app/javascript/dashboard/routes/dashboard/portal/Index.vue`.
        -   This view typically has a sidebar for navigating Categories and Articles, and a main content area for listing and editing them.
        -   It also provides access to the settings of the currently selected portal.

## Core Components of the Help Center

1.  **Portals**:
    -   The top-level container for a Help Center. An account can have one or more portals.
    -   Each portal has its own:
        -   Name, Slug (URL identifier).
        -   Custom domain (optional).
        -   Header text, homepage link.
        -   Color theme/branding.
        -   Locale (language).
    -   Managed via [Portal Settings](./help_center_portals.md).

2.  **Categories**:
    -   Organizational units within a portal to group related articles.
    -   Each category has a name, description, slug, and belongs to a specific portal.
    -   Categories can have a position/order.
    -   Managed via [Category Management](./help_center_categories.md).

3.  **Articles**:
    -   The actual help content (FAQs, guides, tutorials).
    -   Each article has a title, content (rich text), author, status (draft, published), and belongs to a category within a portal.
    -   Articles have an associated `slug`.
    -   Views and votes (upvote/downvote) are tracked.
    -   Managed via [Article Management](./help_center_articles.md).

## Key Functionalities (Managed from Dashboard)

-   **Portal Management**: Creating new portals, configuring domain, branding, and locale.
-   **Category Management**: Creating, editing, deleting, and reordering categories within a portal.
-   **Article Management**: Creating, editing (with a rich text editor), publishing, unpublishing, and deleting articles. Associating articles with categories.
-   **Settings**: Configuring portal-specific settings.
-   **Preview**: Viewing the public-facing Help Center.

## Frontend Structure (Dashboard - Portal Management)

-   **Main Portal Routes**: `app/javascript/dashboard/routes/dashboard/portal/routes.js`.
-   **Vuex Store Modules**:
    -   `app/javascript/dashboard/store/modules/portals.js`: Manages portal data.
    -   `app/javascript/dashboard/store/modules/categories.js`: Manages category data for the selected portal.
    -   `app/javascript/dashboard/store/modules/articles.js`: Manages article data.
-   **API Clients**:
    -   `app/javascript/dashboard/api/portals.js`
    -   `app/javascript/dashboard/api/categories.js`
    -   `app/javascript/dashboard/api/articles.js`
-   **Components**:
    -   Located under `app/javascript/dashboard/routes/dashboard/portal/` and `app/javascript/dashboard/components/portal/`.
    -   Rich Text Editor: Likely `WootWriter.vue` or a similar Tiptap-based editor for article content.

## Backend Structure

-   **Models**:
    -   `Portal` (`app/models/portal.rb`): Represents a Help Center portal.
    -   `Category` (`app/models/category.rb`): Represents a category within a portal.
    -   `Article` (`app/models/article.rb`): Represents a help article.
        -   `author_id` (User who created it), `folder_id` (deprecated, use `category_id`), `category_id`.
        -   `content` (ActionText rich text).
-   **Controllers (API for Dashboard Management)**:
    -   `app/controllers/api/v1/accounts/portals_controller.rb`
    -   `app/controllers/api/v1/accounts/categories_controller.rb` (scoped under portal)
    -   `app/controllers/api/v1/accounts/articles_controller.rb` (scoped under portal)
-   **Controllers (Public Facing Help Center)**:
    -   `app/controllers/public/portals_controller.rb`
    -   `app/controllers/public/categories_controller.rb`
    -   `app/controllers/public/articles_controller.rb`
    -   These controllers serve the actual Help Center pages to the public, using views in `app/views/public/`.

The Help Center feature provides a comprehensive solution for businesses to offer self-service support, with its content and structure managed directly within the Chatwoot dashboard.
# Dashboard: Help Center - Article Management

Article Management is where users create, edit, and organize the content for their Help Center portal(s) within the Chatwoot dashboard. Articles are the core informational pieces (FAQs, guides, troubleshooting steps) provided to customers.

## Overview

Users can write articles using a rich text editor, assign them to categories, set their status (draft or published), and manage their metadata.

## Access and UI Components

-   **Route**: Typically accessed within a specific portal's management area, e.g., `/app/accounts/{account_id}/portals/{portal_slug}/articles` or by navigating through categories.
-   **Main UI**: Part of the `app/javascript/dashboard/routes/dashboard/portal/Index.vue` layout.
    -   **Article List**: Displays articles, often filterable by category or status. Shows title, category, author, status, last updated.
        -   Component: `ArticleList.vue` or similar (e.g., `app/javascript/dashboard/components/portal/ArticleTable.vue`).
    -   **"Add Article" / "New Article" Button**: Navigates to the article creation form/page.
        -   Route: `/app/accounts/{account_id}/portals/{portal_slug}/articles/new`
        -   Component: `NewArticle.vue` or `ArticleEditor.vue` (e.g., `app/javascript/dashboard/routes/dashboard/portal/articles/New.vue`).

-   **Article Editor View (Create/Edit)**:
    -   Route: `/app/accounts/{account_id}/portals/{portal_slug}/articles/{article_id}/edit`
    -   Component: `EditArticle.vue` or `ArticleEditor.vue` (e.g., `app/javascript/dashboard/routes/dashboard/portal/articles/Edit.vue`).
    -   **Key elements**:
        -   **Title**: Input field for the article title.
        -   **Content Editor**: Rich text editor (likely Tiptap-based, e.g., `WootWriter.vue`) for writing and formatting the article content.
        -   **Category Selector**: Dropdown to assign the article to a category within the current portal.
        -   **Author**: Usually pre-filled with the current agent, might be editable.
        -   **Status**: Dropdown or toggle for "Draft" or "Published".
        -   **Meta Description**: Optional field for SEO.
        -   **Slug**: URL-friendly identifier, often auto-generated from the title but can be editable.
        -   **Save/Publish/Update Buttons**.

## Key Functionalities

### 1. Listing Articles
-   **Fetching Articles**:
    -   Vuex action: `articles/get` (`app/javascript/dashboard/store/modules/articles.js`), often scoped by portal or category.
    -   API: `GET /api/v1/accounts/{account_id}/portals/{portal_slug}/articles` (or per category: `GET /api/v1/accounts/{account_id}/portals/{portal_slug}/categories/{category_slug}/articles`).
    -   Controller: `app/controllers/api/v1/accounts/articles_controller.rb#index`.

### 2. Creating a New Article
-   **Frontend Process**:
    -   User fills out the article editor form (title, content, category, status, etc.).
    -   Vuex action: `articles/create`.
    -   API: `POST /api/v1/accounts/{account_id}/portals/{portal_slug}/articles`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/articles_controller.rb#create`.
    -   Payload includes: `title`, `content`, `category_id`, `author_id`, `status`, `meta_description`, `slug`.
    -   Creates a new `Article` record.
    -   Content is saved using ActionText.
    -   Model: `Article` (`app/models/article.rb`).

### 3. Editing an Existing Article
-   **Frontend Process**:
    -   User modifies details in the article editor.
    -   Vuex action: `articles/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/portals/{portal_slug}/articles/{article_id}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/articles_controller.rb#update`.
    -   Updates the `Article` record.

### 4. Changing Article Status (Draft/Published)
-   This is typically part of the edit functionality. Setting the `status` field and saving the article.
-   Published articles are visible on the public Help Center portal. Draft articles are only visible in the dashboard.

### 5. Deleting an Article
-   **Frontend Process**:
    -   User confirms deletion.
    -   Vuex action: `articles/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/portals/{portal_slug}/articles/{article_id}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/articles_controller.rb#destroy`.
    -   Deletes the `Article` record.

### 6. Associating with Category
-   During creation or editing, an article must be assigned to a `Category` within the same `Portal`.
-   The `category_id` field on the `Article` model stores this association.

## Article Model Details

-   `app/models/article.rb`:
    -   `title` (string)
    -   `content` (ActionText rich text: `has_rich_text :content`)
    -   `account_id`
    -   `portal_id`
    -   `category_id`
    -   `author_id` (references `User` model)
    -   `slug` (string, unique per portal)
    -   `status` (integer enum: `draft`, `published`, `archived`)
    -   `views` (integer, counter cache)
    -   `meta_title`, `meta_description`, `meta_tags` (for SEO)
    -   `position` (integer, for ordering within a category)

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/articles.js`**:
    -   Manages articles, usually scoped to the currently selected portal and category.
    -   State: `records` (array of article objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`, `reorder`.
    -   Mutations: `SET_ARTICLES_UI_FLAG`, `SET_ARTICLES`, `ADD_ARTICLE`, `EDIT_ARTICLE`, `DELETE_ARTICLE`.

## Backend API

-   `app/controllers/api/v1/accounts/articles_controller.rb`: Provides CRUD operations for articles, typically scoped under a portal (and sometimes a category).
    -   Handles parameters like `portal_slug` and `category_id` or `category_slug`.

The article management interface is central to populating the Help Center with useful information for customers.
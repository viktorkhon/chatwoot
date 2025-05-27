# Dashboard: Help Center - Category Management

Category Management in Chatwoot's Help Center allows administrators to organize articles into logical groups within a specific portal. This structuring helps customers navigate the knowledge base more easily.

## Overview

Categories act as folders or sections within a Help Center portal. Each category can contain multiple articles related to a common theme or topic.

## Access and UI Components

-   **Route**: Accessed within a specific portal's management area, e.g., `/app/accounts/{account_id}/portals/{portal_slug}/categories`.
-   **Main UI**: Part of the `app/javascript/dashboard/routes/dashboard/portal/Index.vue` layout.
    -   **Category List**: Displays categories for the current portal, often in a sidebar or a main list view. Shows category name, description, number of articles.
        -   Component: `CategoryList.vue` or `CategoriesTable.vue` (e.g., `app/javascript/dashboard/components/portal/CategoriesList.vue`).
        -   Allows reordering of categories.
    -   **"Add Category" / "New Category" Button**: Opens a modal or form for creating a new category.
        -   Component: `AddCategoryModal.vue` or similar (e.g., `app/javascript/dashboard/components/portal/AddCategoryModal.vue`).

-   **Edit Category Modal/Form**:
    -   Accessed by clicking an "Edit" button for a category.
    -   Allows modification of category name, description, and slug.
    -   Component: `EditCategoryModal.vue`.

## Key Functionalities

### 1. Listing Categories
-   **Fetching Categories**:
    -   Vuex action: `categories/get` (`app/javascript/dashboard/store/modules/categories.js`), scoped by the current portal.
    -   API: `GET /api/v1/accounts/{account_id}/portals/{portal_slug}/categories`.
    -   Controller: `app/controllers/api/v1/accounts/categories_controller.rb#index`.

### 2. Creating a New Category
-   **Frontend Process**:
    -   User fills out a form with:
        -   `name`: The display name of the category.
        -   `description`: Optional description.
        -   `locale`: The language of the category (usually inherits from portal, but can be specific if portal supports multiple locales for categories).
        -   `slug`: URL-friendly identifier (often auto-generated from name).
        -   `position`: For ordering (can be auto-assigned or set via drag-and-drop).
    -   Vuex action: `categories/create`.
    -   API: `POST /api/v1/accounts/{account_id}/portals/{portal_slug}/categories`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/categories_controller.rb#create`.
    -   Payload: `name`, `description`, `portal_id` (derived from `portal_slug`), `locale`, `slug`, `position`.
    -   Creates a new `Category` record.
    -   Model: `Category` (`app/models/category.rb`).

### 3. Editing an Existing Category
-   **Frontend Process**:
    -   User modifies name, description, slug.
    -   Vuex action: `categories/update`.
    -   API: `PATCH /api/v1/accounts/{account_id}/portals/{portal_slug}/categories/{category_id_or_slug}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/categories_controller.rb#update`.
    -   Updates the `Category` record.

### 4. Deleting a Category
-   **Frontend Process**:
    -   User confirms deletion.
    -   Vuex action: `categories/delete`.
    -   API: `DELETE /api/v1/accounts/{account_id}/portals/{portal_slug}/categories/{category_id_or_slug}`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/categories_controller.rb#destroy`.
    -   Deletes the `Category` record.
    -   **Impact on Articles**: Articles within a deleted category might become uncategorized or there might be a prompt to reassign them. The `dependent: :nullify` or `dependent: :destroy` on the `Category#articles` association in `app/models/category.rb` determines this behavior (`has_many :articles, dependent: :nullify`). If `nullify`, articles' `category_id` becomes `nil`.

### 5. Reordering Categories
-   **UI**: Drag-and-drop functionality in the category list.
-   **Frontend Process**:
    -   When order changes, a Vuex action like `categories/reorder` is dispatched.
    -   API: `POST /api/v1/accounts/{account_id}/portals/{portal_slug}/categories/reorder` (or similar, possibly a batch update). The `ArticlesController` has a `reorder` action which might be a pattern. The `CategoriesController` has `update_positions`.
    -   API: `POST /api/v1/accounts/{account_id}/categories/update_positions` - This seems to be the one, `categories_controller.rb`.
-   **Backend Process**:
    -   Controller: `app/controllers/api/v1/accounts/categories_controller.rb#update_positions`.
    -   Receives an array of category IDs in the new order.
    -   Updates the `position` attribute on the `Category` records.

## Category Model Details

-   `app/models/category.rb`:
    -   `name` (string)
    -   `slug` (string, unique per portal and locale)
    -   `description` (text)
    -   `account_id`
    -   `portal_id`
    -   `locale` (string, e.g., 'en', 'es')
    -   `position` (integer, for ordering)
    -   `articles_count` (integer, counter cache for number of articles)
    -   Associations: `belongs_to :portal`, `belongs_to :account`, `has_many :articles, dependent: :nullify`.

## State Management (Vuex)

-   **`app/javascript/dashboard/store/modules/categories.js`**:
    -   Manages categories for the currently selected portal.
    -   State: `records` (array of category objects), `uiFlags`.
    -   Actions: `get`, `create`, `update`, `delete`, `update_positions`.
    -   Mutations: `SET_CATEGORIES_UI_FLAG`, `SET_CATEGORIES`, `ADD_CATEGORY`, `EDIT_CATEGORY`, `DELETE_CATEGORY`.

## Backend API

-   `app/controllers/api/v1/accounts/categories_controller.rb`: Provides CRUD operations for categories, scoped under a portal. Also handles reordering.

Categories are essential for structuring the Help Center content and improving its usability for end-users.
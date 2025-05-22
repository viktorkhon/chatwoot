# Project Context History

## Session History

<!-- New sessions will be added at the top -->

### Fix Chatwoot widget persistence across page navigation - [Date: 2025-05-21]

- Fixed issue with duplicate webhook firing during page navigation
- Added conversation context preservation across pages
- Improved cookie handling to ensure site-wide accessibility
- Added automatic domain detection for proper cookie scoping
- Prevented widget reinitialization during regular page navigation
- Fixed detection of returning users to maintain conversation state

### Shopify Integration 404 Error Fix - [Date: 2025-05-20]
- Fixed 404 error when accessing Shopify integration despite having environment variables set
- Identified that `check_cloud_env` filter was blocking access because it specifically checks database config
- Discovered that Chatwoot uses `InstallationConfig` database records rather than direct ENV variables for some settings
- Created migration to update `DEPLOYMENT_ENV` to 'cloud' in the database (not just environment variables)
- Documented three alternative solutions:
  1. Database migration to set the deployment environment to 'cloud'
  2. Direct database update through SQL
  3. Adding environment variable (with caveat that it still requires application to be restarted)
- Added explanation of how Chatwoot's enterprise features are gated by deployment environment settings that must be in the database

### Shopify Integration Environment Variables Fix - [Date: 2025-05-20]
- Fixed issue where Shopify integration was not visible despite environment variables being set in Railway.com
- Created migration to properly sync environment variables to database configuration:
  - Copies `SHOPIFY_CLIENT_ID` and `SHOPIFY_CLIENT_SECRET` from environment to `InstallationConfig`
  - Ensures proper caching and configuration loading
- Added documentation for Railway.com deployment configuration
- This complements the previous Shopify integration default fix to ensure both feature flags and credentials are properly configured

### Shopify Integration Default Fix - [Date: 2025-05-20]
- Addressed issue where Shopify integration was not enabled by default for new accounts or existing accounts.
- Identified that `ACCOUNT_LEVEL_FEATURE_DEFAULTS` in `InstallationConfig` was not automatically enabling `shopify_integration`.
- Created a migration to:
  - Enable `shopify_integration` for all existing accounts.
  - Update `ACCOUNT_LEVEL_FEATURE_DEFAULTS` to include `shopify_integration` as enabled by default for new accounts.
- This ensures Shopify integration is active for the user's current account and all future accounts.

### Account Settings Field Visibility Fix - [Date: 2025-05-20]
- Fixed issue where Support Email and Incoming Email Domain fields were missing from Account Settings UI
- Identified that these fields are conditionally displayed based on specific feature flags
- Created migration to enable required feature flags (`inbound_emails`, `custom_reply_email`, `custom_reply_domain`)
- Updated default feature configuration to ensure new accounts have these fields visible by default
- Added documentation explaining the issue and solution

### Railway Deployment Fix - [Date: 2025-05-17]
- Fixed database migration issues for Railway.com deployment
- Modified Rails entrypoint script to handle existing databases properly
- Updated database migration approach to try `db:migrate` first before `db:chatwoot_prepare`
- Added essential environment variables to the Dockerfile
- Updated Railway configuration with appropriate restart policies

### Initial Setup - [Date: 2023-06-12]
- Created project context tracking system
- Established structure for maintaining persistent context between Cursor AI sessions
- Added initial Cursor rule to incorporate this context file
- Implemented update scripts for Windows and Unix systems
- Added archive functionality to manage context size

## Current Focus
- Successfully deploying the application to Railway.com
- Improving context retention between Cursor AI chat sessions
- Ensuring all account settings fields and integrations (like Shopify) are properly visible and enabled in the UI by default where appropriate.

## Project Overview
- Chatwoot is an open-source customer engagement suite
- Main components include dashboard, widget, API services, and various integrations

## Key Files and Directories
- `app/`: Main application code
- `app/javascript/`: Frontend code (Vue.js)
- `app/controllers/`: Backend controllers
- `app/models/`: Data models
- `config/`: Application configuration
- `docker/`: Docker configuration for containerized deployment
- `docker/entrypoints/`: Container entrypoint scripts

## Notes
- This file is automatically referenced by Cursor AI at the start of each session
- Recent sessions are kept at the top for relevance
- Older sessions may be archived or summarized to maintain manageable context size 
# Project Context History

## Session History

<!-- New sessions will be added at the top -->

### Account Settings Field Visibility Fix - [Date: 2024-07-04]
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
- Ensuring all account settings fields are properly visible in the UI

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
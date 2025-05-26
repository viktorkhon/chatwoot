# Project Context History

## Session History

<!-- New sessions will be added at the top -->

### SASS Import Fix - [Date: 2025-05-26]
- Fixed critical SASS import errors in widget build system
- Corrected import paths in `app/javascript/widget/assets/scss/woot.scss`
- Changed relative imports to use Vite's configured path resolution:
  - `@import 'reset'` → `@import 'widget/assets/scss/reset'`
  - `@import 'views/conversation'` → `@import 'widget/assets/scss/views/conversation'`
  - `@import 'custom_card'` → `@import 'widget/assets/scss/custom_card'`
- Build system now successfully compiles all assets without SASS import errors
- Aligned widget SASS imports with patterns used in survey and portal modules
- Resolved "Can't find stylesheet to import" errors that were blocking builds

### Conversation Persistence Implementation - [Date: 2025-05-24]
- Completed implementation of conversation persistence feature for web widget using Redis
- Added comprehensive visitor mapping system with 30-day TTL
- Implemented frontend visitor ID generation using sessionStorage for page navigation persistence
- Enhanced backend controllers with Redis lookup and conversation token management
- Ensured 'Live chat widget opened' webhook fires only once per session, not on page navigation
- Added full support for incognito users without cookie dependencies
- Maintained backward compatibility with existing conversation/message functionality
- Fixed PowerShell development script emoji encoding issues
- All Ruby syntax checks passed; Docker environment needs base image configuration
- Successfully addresses all original requirements for conversation persistence

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
- Conversation persistence feature is fully implemented and ready for testing
- Docker environment needs configuration for local development testing
- Monitoring and optimization of Redis performance may be needed post-deployment

## Project Overview
- Chatwoot is an open-source customer engagement suite
- Main components include dashboard, widget, API services, and various integrations
- Recently added conversation persistence using Redis for improved user experience

## Key Files and Directories
- `app/`: Main application code
- `app/javascript/`: Frontend code (Vue.js)
- `app/controllers/`: Backend controllers
- `app/models/`: Data models
- `config/`: Application configuration
- `docker/`: Docker configuration for containerized deployment
- `docker/entrypoints/`: Container entrypoint scripts
- `lib/redis/`: Redis key definitions and utilities
- `app/listeners/`: Event listeners for application events

## Notes
- This file is automatically referenced by Cursor AI at the start of each session
- Recent sessions are kept at the top for relevance
- Older sessions may be archived or summarized to maintain manageable context size
- Conversation persistence feature represents a significant enhancement to widget functionality 
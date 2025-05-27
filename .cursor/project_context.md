# Project Context History

## Session History

<!-- New sessions will be added at the top -->

### Windows Husky Pre-commit Hook Fix - [Date: 2025-01-27]
- Fixed WSL-related error when using Husky pre-commit hooks on Windows with GitHub Desktop
- Updated `.husky/pre-commit` script to be more Windows-compatible with error handling and fallbacks
- Enhanced `.husky/_/husky.sh` to detect WSL environments and handle missing bash gracefully
- Created alternative Windows batch file `.husky/pre-commit.bat` for Windows users
- Added `precommit` npm script as manual alternative to automatic hooks
- Created `WINDOWS_HUSKY_FIX.md` documentation with multiple solutions for Windows users
- Resolved "CreateProcessCommon:640: execvpe(/bin/bash) failed" error

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

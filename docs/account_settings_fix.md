# Account Settings Fields Visibility Fix

## Problem

Two important fields are missing from the Account Settings UI in some environments:

1. Support Email (`support_email`)
2. Incoming Email Domain (`domain`)

These fields exist in the database schema but are conditionally displayed in the Account Settings UI based on specific feature flags. The fields are only visible when:

- `inbound_emails` feature flag is enabled (base requirement)
- `custom_reply_email` feature flag is enabled (for Support Email field)
- `custom_reply_domain` feature flag is enabled (for Incoming Email Domain field)

The fields are important for email functionality in Chatwoot, particularly for:
- Email reply functionality
- Conversation continuity with email
- Custom domain email support
- Message IDs and threading

## Solution

We've created a migration that enables the necessary feature flags to make these fields visible in the UI:

```bash
rails db:migrate
```

The migration `20240704175720_enable_email_features_for_accounts.rb` will:
1. Enable the required feature flags for all existing accounts
2. Update the default feature flags configuration so that new accounts will have these enabled by default

## How It Works

For each account, the migration:
1. Enables `inbound_emails` feature flag (base requirement)
2. Enables `custom_reply_email` feature flag (shows Support Email field)
3. Enables `custom_reply_domain` feature flag (shows Incoming Email Domain field)

It also updates the `ACCOUNT_LEVEL_FEATURE_DEFAULTS` configuration to ensure these feature flags are enabled by default for new accounts.

## Verification

To verify that the fix worked:
1. Go to your Account Settings in the Chatwoot dashboard
2. You should now see both the "Support Email" and "Incoming Email Domain" fields
3. You can update these fields and save your changes

## Technical Details

The following files have been modified:
- `db/migrate/20240704175720_enable_email_features_for_accounts.rb` - Migration to enable feature flags
- `app/builders/account_builder.rb` - Updates to ensure new accounts have these fields
- `lib/tasks/account_settings_fix.rake` - Rake task for manual fixing

The `support_email` and `domain` fields are important for:
- Email reply functionality
- Conversation continuity
- Proper email routing
- Custom domain support 
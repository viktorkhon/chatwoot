# Shopify Integration Fix

## Problem

You're encountering a 404 error when trying to set up the Shopify integration. The error logs show:

```
0:38:45 web.1    | I, [2025-05-21T00:38:45.925210 #30]  INFO -- : [c3d60d2d-d118-4a9d-a0a0-21c1933a136b] Filter chain halted as :check_cloud_env rendered or redirected
00:38:45 web.1    | I, [2025-05-21T00:38:45.925353 #30]  INFO -- : [c3d60d2d-d118-4a9d-a0a0-21c1933a136b] Completed 404 Not Found in 18ms (Views: 0.2ms | ActiveRecord: 6.4ms | Allocations: 6446)
```

## Root Cause

The issue is with the `check_cloud_env` filter in the `Enterprise::Api::V1::AccountsController`. This filter is checking if the application is running in a "cloud" deployment environment before allowing certain enterprise features, such as the Shopify integration, to work.

In your self-hosted setup, the `DEPLOYMENT_ENV` configuration is set to `self-hosted` (the default), which causes the filter to return a 404 error.

## Solution

You need to update the `DEPLOYMENT_ENV` configuration in your installation to `cloud`. This can be done through the database directly or by running a migration.

### Option 1: Run the Migration

We've created a migration file that will update the setting for you. Before you can run it, you need to fix the Ruby version mismatch:

1. Update your Ruby version to match what's in the Gemfile (3.3.3)
   ```bash
   rbenv install 3.3.3  # or rvm install 3.3.3, depending on your Ruby version manager
   rbenv local 3.3.3    # or rvm use 3.3.3
   ```

2. Or update your Gemfile to match your installed Ruby version (3.3.8)
   ```ruby
   # Edit the Gemfile and change the Ruby version
   ruby '3.3.8'
   ```

3. After fixing the Ruby version issue, run the migration:
   ```bash
   bundle install
   rails db:migrate VERSION=20250525000001
   ```

4. Restart your Chatwoot server:
   ```bash
   rails s  # or however you start your application
   ```

### Option 2: Update via Database

If you can't run the migration, you can update the setting directly in the database:

```sql
UPDATE installation_configs 
SET value = 'cloud' 
WHERE name = 'DEPLOYMENT_ENV';
```

Then restart your server.

### Option 3: Set Environment Variable

You can also set the environment variable directly:

1. Add to your `.env` file:
   ```
   DEPLOYMENT_ENV=cloud
   ```

2. Restart your Chatwoot server.

## Verification

After making these changes, try using the Shopify integration again. The 404 error should be resolved, and you should be able to connect your Shopify store successfully.

## Note

This solution enables "cloud" mode for your self-hosted installation, which may enable other enterprise/cloud features. If you encounter any other issues, you may need to adjust additional configuration settings. 
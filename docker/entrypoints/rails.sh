#!/bin/sh
set -x # Keep for debugging on Railway for now

# Remove any pre-existing server.pid and clear cache.
rm -rf /app/tmp/pids/server.pid

if [ -n "$DATABASE_URL" ]; then
  export POSTGRES_HOST=$(echo "$DATABASE_URL" | sed -n 's#.*@\([^:/]\+\).*#\1#p')
  export POSTGRES_PORT=$(echo "$DATABASE_URL" | sed -n 's#.*:\([0-9]\+\)/.*#\1#p')
  export POSTGRES_USERNAME=$(echo "$DATABASE_URL" | sed -n 's#.*//\([^:]*\):.*#\1#p')
fi

if [ -n "$POSTGRES_HOST" ] && [ -n "$POSTGRES_PORT" ] && [ -n "$POSTGRES_USERNAME" ]; then
  PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"
  until $PG_READY; do
    echo "Postgres is unavailable - sleeping"
    sleep 2
  done
  echo "Database ready to accept connections."
else
  echo "PostgreSQL connection details not fully available. Skipping pg_isready check."
fi

# Gems should already be installed in the base image.
# bundle install # REMOVE THIS LINE

# Ensure gems are available.
# BUNDLE="bundle check" # This can still be useful
# until $BUNDLE; do
#  echo "Bundle check failed - sleeping" # Should not happen if base image is correct
#  sleep 2
# done
# echo "Bundle check successful." #

echo "Running database migrations (db:chatwoot_prepare)..."
bundle exec rails db:chatwoot_prepare

# Ensure all directories exist and have proper permissions
mkdir -p /app/tmp/pids /app/public/assets /app/public/packs /app/app/assets/builds/images

# Verify assets were correctly compiled
if [ ! -d "/app/public/assets" ] || [ ! "$(ls -A /app/public/assets 2>/dev/null)" ]; then
  echo "Warning: Assets directory appears to be empty or missing. Attempting to recompile..."
  SECRET_KEY_BASE=temporarykey_for_assets_precompile RAILS_LOG_TO_STDOUT=true bundle exec rake assets:precompile --trace
fi

# Finally, execute the main process (passed as CMD)
echo "Executing CMD: $@"
exec "$@"

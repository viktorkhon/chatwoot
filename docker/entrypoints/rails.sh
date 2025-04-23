#!/bin/sh
set -x # Keep for debugging if needed

echo "Waiting for postgres to become ready...."
# If DATABASE_URL is set, parse out connection details.
if [ -n "$DATABASE_URL" ]; then
  export POSTGRES_HOST=$(echo "$DATABASE_URL" | sed -n 's#.*@\([^:/]\+\).*#\1#p')
  export POSTGRES_PORT=$(echo "$DATABASE_URL" | sed -n 's#.*:\([0-9]\+\)/.*#\1#p')
  export POSTGRES_USERNAME=$(echo "$DATABASE_URL" | sed -n 's#.*//\([^:]*\):.*#\1#p')
fi
PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME"
until $PG_READY; do
  echo "Postgres is unavailable - sleeping"
  sleep 2
done
echo "Database ready to accept connections."

# Remove bundle install/check - should be done in Docker build
# Remove db:chatwoot_prepare - should be done in release phase

# Remove pid file just in case
rm -f /app/tmp/pids/server.pid

# Execute the main process (passed as CMD)
exec "$@"
#!/bin/sh
set -x # Keep for debugging in development

echo "🚀 Starting Vite development server with optimized caching..."

# Only clear specific caches if they're corrupted, not on every startup
# Remove server PID if exists
rm -f /app/tmp/pids/server.pid

echo "Waiting for postgres to become ready...."

# Parse DATABASE_URL directly in shell if available
if [ -n "$DATABASE_URL" ]; then
  # Extract components from DATABASE_URL
  export POSTGRES_HOST=$(echo "$DATABASE_URL" | sed -n 's#.*@\([^:/]\+\).*#\1#p')
  export POSTGRES_PORT=$(echo "$DATABASE_URL" | sed -n 's#.*:\([0-9]\+\)/.*#\1#p')
  export POSTGRES_USERNAME=$(echo "$DATABASE_URL" | sed -n 's#.*//\([^:]*\):.*#\1#p')
elif [ -n "$DATABASE_HOST" ]; then
  # Use individual environment variables if DATABASE_URL is not set
  export POSTGRES_HOST="$DATABASE_HOST"
  export POSTGRES_PORT="${DATABASE_PORT:-5432}"
  export POSTGRES_USERNAME="$DATABASE_USERNAME"
else
  echo "No database configuration found. Skipping database check."
  export POSTGRES_HOST=""
fi

# Only check database if we have connection details (with timeout)
if [ -n "$POSTGRES_HOST" ] && [ -n "$POSTGRES_PORT" ] && [ -n "$POSTGRES_USERNAME" ]; then
  PG_READY="pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME -t 3"
  max_attempts=10
  attempt=0
  
  until $PG_READY || [ $attempt -eq $max_attempts ]
  do
    attempt=$((attempt + 1))
    echo "Database check attempt $attempt/$max_attempts..."
    sleep 2;
  done
  
  if [ $attempt -eq $max_attempts ]; then
    echo "⚠️  Database not ready after $max_attempts attempts, continuing anyway for development..."
  else
    echo "✅ Database ready to accept connections."
  fi
else
  echo "Database connection details not available. Skipping database check."
fi

# Quick bundle check (don't reinstall unless necessary)
echo "Checking gem dependencies..."
if ! bundle check > /dev/null 2>&1; then
  echo "Installing missing gems..."
  bundle install --quiet
else
  echo "✅ All gems are satisfied."
fi

# Quick npm dependency check (don't reinstall unless necessary)
echo "Checking npm dependencies..."
if [ ! -d "node_modules" ] || [ ! -f "node_modules/.package-lock.json" ]; then
  echo "Installing npm dependencies..."
  npm install --silent
else
  echo "✅ npm dependencies satisfied."
fi

echo "🔥 Starting Vite development server with hot reloading..."

# Execute the main process of the container
exec "$@" 
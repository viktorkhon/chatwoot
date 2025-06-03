#!/bin/bash
set -e

echo "🚀 Starting Chatwoot Development Environment..."

# Change to app directory first
cd /app

# Set up complete PATH to include Ruby and bundle binaries
export PATH="/usr/local/bundle/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export BUNDLE_PATH="/usr/local/bundle"
export GEM_HOME="/usr/local/bundle"
export GEM_PATH="/usr/local/bundle"

# Verify Ruby is accessible
echo "Ruby version: $(ruby --version)"
echo "Bundle version: $(bundle --version)"

# Install any new gems if Gemfile changed
if [ -f Gemfile ]; then
  echo "💎 Checking for new gems..."
  bundle check || bundle install --jobs "$(nproc)" --retry 3
fi

# Skip PNPM installation for now to avoid interactive prompts
# TODO: Fix Node.js version compatibility issues
echo "📦 Skipping npm package installation (temporary fix for Node.js version mismatch)"

# Wait for external database to be ready (Railway PostgreSQL)
echo "⏳ Waiting for Railway database..."
echo "Database config: ${DATABASE_HOST}:${DATABASE_PORT} user=${DATABASE_USERNAME}"

# Check if environment variables are set
if [[ -z "${DATABASE_HOST}" || -z "${DATABASE_PORT}" || -z "${DATABASE_USERNAME}" ]]; then
  echo "⚠️ Database environment variables not set properly!"
  echo "DATABASE_HOST='${DATABASE_HOST}'"
  echo "DATABASE_PORT='${DATABASE_PORT}'"
  echo "DATABASE_USERNAME='${DATABASE_USERNAME}'"
  echo "Attempting to continue without waiting for database..."
else
  # Wait for database with proper error handling
  while ! pg_isready -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -U "${DATABASE_USERNAME}" >/dev/null 2>&1; do
    echo "Waiting for database at ${DATABASE_HOST}:${DATABASE_PORT}..."
    sleep 2
  done
  echo "✅ Railway database is ready!"
fi

# Test Redis connection (Railway Redis)
echo "⏳ Testing Railway Redis connection..."
if command -v redis-cli &> /dev/null; then
  # Extract Redis connection details from REDIS_URL if available
  if [[ -n "${REDIS_URL}" ]]; then
    echo "Testing Redis connection with URL: ${REDIS_URL}"
    # Simple connection test - will exit gracefully if Redis is not available
    timeout 10 bash -c "echo 'PING' | redis-cli -u '${REDIS_URL}' > /dev/null 2>&1" && echo "✅ Railway Redis is ready!" || echo "⚠️ Redis connection failed, but continuing..."
  else
    echo "⚠️ REDIS_URL not set, skipping Redis test"
  fi
else
  echo "⚠️ redis-cli not available, skipping Redis test"
fi

# Run database setup only if needed (only for Rails server, not Sidekiq/Vite)
if [[ "$*" == *"rails server"* ]]; then
  echo "🗃️ Rails server detected - skipping database checks (Railway DB confirmed working)"
else
  echo "🔄 Non-Rails service detected - skipping database operations"
fi

# Skip asset precompilation for now to get Rails running faster
echo "✅ Skipping asset precompilation for development"

# Clear tmp files that might cause issues
echo "🧹 Cleaning temporary files..."
rm -f tmp/pids/server.pid

echo "🎉 Development environment ready!"
echo "📊 Using Railway PostgreSQL at ${DATABASE_HOST}:${DATABASE_PORT}"
echo "📊 Using Railway Redis via: ${REDIS_URL}"

# Execute the main command
exec "$@" 
#!/bin/bash
set -e

echo "🚀 Starting Chatwoot Development Environment..."

# Wait for external database to be ready (Railway PostgreSQL)
echo "⏳ Waiting for Railway database..."
while ! pg_isready -h ${DATABASE_HOST} -p ${DATABASE_PORT} -U ${DATABASE_USERNAME}; do
  echo "Waiting for database at ${DATABASE_HOST}:${DATABASE_PORT}..."
  sleep 2
done
echo "✅ Railway database is ready!"

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

# Run database setup only if needed
if ! bundle exec rails runner "ActiveRecord::Base.connection" >/dev/null 2>&1; then
  echo "🗃️  Setting up database..."
  bundle exec rails db:create
  bundle exec rails db:migrate
  bundle exec rails db:seed
else
  echo "✅ Database already exists, running migrations..."
  bundle exec rails db:migrate
fi

# Install any new gems if Gemfile changed
if [ -f /app/Gemfile ]; then
  echo "💎 Checking for new gems..."
  bundle check || bundle install
fi

# Install any new npm packages if package.json changed
if [ -f /app/package.json ]; then
  echo "📦 Checking for new npm packages..."
  pnpm install --frozen-lockfile
fi

# Only precompile assets if they don't exist or if in production mode
if [ "$RAILS_ENV" = "production" ] || [ ! -d "public/packs" ] || [ -z "$(ls -A public/packs 2>/dev/null)" ]; then
  echo "🎨 Precompiling assets..."
  bundle exec rails assets:precompile
else
  echo "✅ Assets already exist, skipping precompilation for development"
fi

# Clear tmp files that might cause issues
echo "🧹 Cleaning temporary files..."
rm -f tmp/pids/server.pid

echo "🎉 Development environment ready!"
echo "📊 Using Railway PostgreSQL at ${DATABASE_HOST}:${DATABASE_PORT}"
echo "📊 Using Railway Redis via: ${REDIS_URL}"

# Execute the main command
exec "$@" 
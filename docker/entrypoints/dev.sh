#!/bin/bash
set -e

echo "🚀 Starting Chatwoot Development Environment..."

# Wait for database to be ready
echo "⏳ Waiting for database..."
while ! pg_isready -h ${DATABASE_HOST:-postgres} -p ${DATABASE_PORT:-5432} -U ${DATABASE_USERNAME:-postgres}; do
  sleep 1
done
echo "✅ Database is ready!"

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

# Execute the main command
exec "$@" 
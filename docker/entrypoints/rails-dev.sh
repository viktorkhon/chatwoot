#!/bin/bash
set -e

echo "Starting Rails development server..."

# Remove any pre-existing server.pid
rm -rf /app/tmp/pids/server.pid

# Wait for database to be ready
echo "Waiting for database..."
until bundle exec rails runner "ActiveRecord::Base.connection" >/dev/null 2>&1; do
  echo "Database is unavailable - sleeping"
  sleep 2
done
echo "Database is ready!"

# Setup database if it doesn't exist
echo "Setting up database..."
bundle exec rails db:create db:migrate || bundle exec rails db:migrate

# Install dependencies if they don't exist
if [ ! -d "/app/node_modules" ]; then
  echo "Installing Node.js dependencies..."
  pnpm install
fi

# Start the Rails server
echo "Starting Rails server on port 3000..."
exec "$@" 
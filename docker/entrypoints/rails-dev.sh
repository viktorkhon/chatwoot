#!/bin/sh
set -e

# Remove a potentially pre-existing server.pid for Rails.
if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
# This script will be the command in docker-compose.yaml for the rails service.
echo "🚀 Starting Rails development server..."
bundle exec rails server -b 0.0.0.0 -p 3000 
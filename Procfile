release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare && echo ${RAILWAY_GIT_COMMIT_SHA:-unknown} > /app/.git_sha
web: bundle exec rails ip_lookup:setup && bin/rails server -p $PORT -e $RAILS_ENV
worker: bundle exec rails ip_lookup:setup && bundle exec sidekiq -C config/sidekiq.yml
# Dockerfile (for Railway CI/CD)

# --- Build Arguments ---
# These allow you to specify your Docker Hub username and base image tag during build.
# Railway doesn't directly use these for *its* build, but they are good for local testing.
# For Railway, the FROM line will be used as is.
ARG YOUR_DOCKERHUB_USERNAME="yourdockerhubusername" # Replace with your Docker Hub username
ARG BASE_IMAGE_TAG="latest" # Replace with your specific tag, e.g., v1.0.0

# --- Base Image ---
FROM ${YOUR_DOCKERHUB_USERNAME}/my-chatwoot-base:${BASE_IMAGE_TAG}

# --- Environment Arguments and Variables ---
# These can be overridden by Railway's service environment variables at runtime.
# RAILS_ENV is crucial for asset precompilation.
ARG RAILS_ENV_ARG="production"
ARG RAILS_SERVE_STATIC_FILES_ARG="true"
ARG EXECJS_RUNTIME_ARG="Disabled" # From your original final stage
ARG BUNDLE_FORCE_RUBY_PLATFORM_ARG="1" # From your original final stage

ENV RAILS_ENV=${RAILS_ENV_ARG}
ENV NODE_ENV=${RAILS_ENV_ARG} # Keep NODE_ENV consistent
ENV RAILS_SERVE_STATIC_FILES=${RAILS_SERVE_STATIC_FILES_ARG}
ENV EXECJS_RUNTIME=${EXECJS_RUNTIME_ARG}
ENV BUNDLE_FORCE_RUBY_PLATFORM=${BUNDLE_FORCE_RUBY_PLATFORM_ARG}
# BUNDLE_PATH, PNPM_HOME, PATH, etc., are inherited from the base image.

WORKDIR /app

# --- Copy Application Code ---
# Ensure you have a good .dockerignore file to exclude .git, tmp, local .env,
# node_modules (already in base), vendor/bundle (already in base), etc.
COPY . .

# --- Asset Precompilation ---
# This step runs if RAILS_ENV is production.
# A dummy SECRET_KEY_BASE is sufficient for assets:precompile.
# RAILS_LOG_TO_STDOUT=true helps in debugging asset compilation.
RUN if [ "$RAILS_ENV" = "production" ]; then \
    echo "Precompiling assets for production..." && \
    SECRET_KEY_BASE_DUMMY= blanchâtre RAILS_LOG_TO_STDOUT=true bundle exec rake assets:precompile --trace && \
    echo "Asset precompilation complete." && \
    # Clean up files not needed in the final production image after precompilation
    # Be CAREFUL with removing ./node_modules. If any runtime JS execution (not frontend)
    # depends on it, do not remove it. For Chatwoot, assets are typically self-contained.
    rm -rf ./tmp/cache/* ./node_modules ./spec ./app/assets/builds/*.*; \
  fi

# --- Generate .git_sha ---
# RAILWAY_GIT_COMMIT_SHA is automatically provided by Railway's build environment.
# For local builds, you might want to pass it as a build-arg or let it default.
ARG RAILWAY_GIT_COMMIT_SHA_ARG=${RAILWAY_GIT_COMMIT_SHA:-unknown}
RUN echo "${RAILWAY_GIT_COMMIT_SHA_ARG}" > /app/.git_sha

# --- Final Cleanup (if any specific to app code) ---
# Most heavy cleanup (gem caches etc) is done in the base image.
# Remove .git directory and .gitignore if they were copied by `COPY . .`
RUN rm -rf .git .gitignore

# --- Port Exposure ---
EXPOSE 3000

# --- Entrypoint & CMD ---
# Ensure 'docker/entrypoints/rails.sh' exists in your repository at this path.
COPY docker/entrypoints/rails.sh /usr/bin/rails.sh
RUN chmod +x /usr/bin/rails.sh

ENTRYPOINT ["/usr/bin/rails.sh"]
# Default command, often overridden by the entrypoint script or Procfile.
CMD ["bundle", "exec", "foreman", "start"]
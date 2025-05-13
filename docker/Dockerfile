# Dockerfile (for Railway, using your pushed base image)

# Directly specify the base image you pushed to Docker Hub
FROM vkhon00/my-chatwoot-base:v1.0.0

ENV RAILS_ENV="production"
ENV NODE_ENV="production"
ENV RAILS_SERVE_STATIC_FILES="true"
ENV RAILS_LOG_TO_STDOUT="true"
# Other necessary ENVs inherited or set here

WORKDIR /app

COPY . . # Copy your application code on top of the base image

# Asset Precompilation (should already be done in my-chatwoot-base IF it was built from the full app source)
# If my-chatwoot-base only contains dependencies, and not app code + assets, then run it here:
RUN if [ "$RAILS_ENV" = "production" ]; then \
    echo "Precompiling assets for production..." && \
    SECRET_KEY_BASE_DUMMY=temporarykey RAILS_LOG_TO_STDOUT=true bundle exec rake assets:precompile --trace && \
    echo "Asset precompilation complete." && \
    rm -rf ./tmp/cache/* ./node_modules ./spec ./app/assets/builds/*.*; \
  fi

ARG RAILWAY_GIT_COMMIT_SHA_ARG=${RAILWAY_GIT_COMMIT_SHA:-unknown}
RUN echo "${RAILWAY_GIT_COMMIT_SHA_ARG}" > /app/.git_sha

# Copy your production entrypoint script
COPY entrypoints/rails.sh /usr/bin/rails.sh
RUN chmod +x /usr/bin/rails.sh

EXPOSE 3000

ENTRYPOINT ["/usr/bin/rails.sh"]
# This CMD will be executed by `exec "$@"` in rails.sh
CMD ["bundle", "exec", "foreman", "start"]
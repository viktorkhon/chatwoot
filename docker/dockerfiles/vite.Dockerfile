# Vite Development Dockerfile
FROM vkhon00/my-chatwoot-base:latest

ENV RAILS_ENV="development"
ENV NODE_ENV="development"

WORKDIR /app

# Copy application code needed for Vite first
# This ensures Vite has access to its config and the frontend source files.
COPY . .

# Install missing development dependencies for Vite after copying code
# The base image is missing esbuild and other dev dependencies
RUN pnpm install -D esbuild @esbuild/linux-x64 \
    && pnpm install

# Expose the Vite development server port
EXPOSE 3036

# Clear any entrypoint from base image
ENTRYPOINT []

# The command to run Vite dev server
CMD ["pnpm", "exec", "vite", "dev", "--host", "0.0.0.0", "--port", "3036"]

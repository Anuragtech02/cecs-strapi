# Dockerfile for Strapi Application
# This should be placed in the app/ directory alongside your Strapi code

FROM node:18-alpine

# Install system dependencies
RUN apk update && apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    nasm \
    bash \
    vips-dev \
    git \
    curl

# Set working directory
WORKDIR /opt/app

# Copy package files first (for better Docker layer caching)
COPY package*.json ./
COPY yarn.lock* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm ci && npm cache clean --force; fi

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p public/uploads

# Build the application (only if in production)
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}

# Build Strapi admin and app if in production
RUN if [ "$NODE_ENV" = "production" ]; then \
    npm run build; \
    fi

# Set proper permissions
RUN chown -R node:node /opt/app

# Switch to non-root user
USER node

# Expose the port Strapi runs on
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:1337/_health || exit 1

# Create entrypoint script to handle development vs production
COPY --chown=node:node <<'EOF' /opt/app/docker-entrypoint.sh
#!/bin/bash
set -e

echo "Starting Strapi in $NODE_ENV mode..."

if [ "$NODE_ENV" = "production" ]; then
    # Production mode - build if dist doesn't exist, then start
    if [ ! -d "dist" ]; then
        echo "Building Strapi for production..."
        npm run build
    fi
    echo "Starting Strapi in production mode..."
    exec npm start
else
    # Development mode - use develop command
    echo "Starting Strapi in development mode..."
    exec npm run develop
fi
EOF

RUN chmod +x /opt/app/docker-entrypoint.sh

# Start Strapi
ENTRYPOINT ["/opt/app/docker-entrypoint.sh"]
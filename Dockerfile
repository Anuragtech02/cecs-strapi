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
    git

# Set working directory
WORKDIR /opt/app

# Copy package files first (for better Docker layer caching)
COPY package*.json ./
COPY yarn.lock* ./

# Install dependencies
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm ci --only=production && npm cache clean --force; fi

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p public/uploads

# Set proper permissions
RUN chown -R node:node /opt/app

# Switch to non-root user
USER node

# Expose the port Strapi runs on
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:1337/_health || exit 1

# Start Strapi
CMD ["npm", "start"]
# Stage 1: Build stage
FROM node:18-alpine as build

# Install build dependencies
RUN apk update && apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    nasm \
    vips-dev \
    git \
    curl \
    > /dev/null 2>&1

# Set environment for build
ENV NODE_ENV=production

# Set working directory for dependencies
WORKDIR /opt/

# Copy package files
COPY package*.json ./
COPY yarn.lock* ./

# Install yarn globally and configure
RUN yarn global add node-gyp
RUN yarn config set network-timeout 600000 -g && yarn install --production

# Set PATH to include node_modules/.bin
ENV PATH=/opt/node_modules/.bin:$PATH

# Set working directory for app
WORKDIR /opt/app

# Copy application code
COPY . .

# Build the Strapi application
RUN yarn build

# Stage 2: Production runtime image
FROM node:18-alpine

# Install only runtime dependencies
RUN apk add --no-cache vips-dev curl

# Set production environment
ENV NODE_ENV=production

# Set working directory for dependencies
WORKDIR /opt/

# Copy node_modules from build stage
COPY --from=build /opt/node_modules ./node_modules

# Set working directory for app
WORKDIR /opt/app

# Copy built application from build stage
COPY --from=build /opt/app ./

# Set PATH to include node_modules/.bin
ENV PATH=/opt/node_modules/.bin:$PATH

# Ensure node user owns everything
RUN chown -R node:node /opt/app

# Switch to non-root user
USER node

# Expose the port Strapi runs on
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:1337/_health || exit 1

# Start Strapi in production mode
CMD ["yarn", "start"]
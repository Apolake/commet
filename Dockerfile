# syntax=docker/dockerfile:1

ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:stable

# ==============================================================================
# Stage 1: Build Flutter Web application from source
# ==============================================================================
FROM ${FLUTTER_IMAGE} AS builder
WORKDIR /app

# Disable analytics and enable web
RUN flutter config --no-analytics --enable-web

# Copy workspace configuration and pubspecs
COPY pubspec.yaml pubspec.lock* Cargo.toml* Cargo.lock* ./
COPY tiamat/ tiamat/
COPY widgets/ widgets/
COPY rust/ rust/
COPY commet/ commet/

# Fetch dependencies across the monorepo workspace
RUN flutter pub get

WORKDIR /app/commet

# Run procedural code generation (localization, build_runner, etc.)
RUN dart run scripts/codegen.dart

# Build optimized production Flutter Web bundle
ARG VERSION_TAG=v0.0.0
ARG GIT_HASH=docker
RUN flutter build web --release \
    --dart-define PLATFORM=web \
    --dart-define BUILD_MODE=release \
    --dart-define VERSION_TAG=${VERSION_TAG} \
    --dart-define GIT_HASH=${GIT_HASH} \
    --dart-define FLUTTER_WEB_CANVASKIT_URL=canvaskit/ \
    --source-maps

# ==============================================================================
# Stage 2: Production Web Server (Ultra-lightweight Nginx Alpine)
# ==============================================================================
FROM nginx:alpine AS runner

# Install curl, jq, bash for healthchecks and dynamic runtime configuration
RUN apk add --no-cache curl jq bash

# Custom Nginx configuration with MIME types, Gzip, and SPA routing
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Runtime entrypoint for dynamic homeserver configuration
COPY docker/entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Copy built web assets from builder stage
COPY --from=builder /app/commet/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

# ==============================================================================
# Optional Stage: Prebuilt Runner
# Allows deploying pre-compiled build/web assets directly without compiling in Docker
# ==============================================================================
FROM nginx:alpine AS prebuilt

RUN apk add --no-cache curl jq bash
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
COPY commet/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]

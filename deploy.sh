#!/usr/bin/env bash
set -e

echo "=========================================="
echo "  Deploying Commet Web Matrix Client      "
echo "=========================================="

# Check for Docker
if ! command -v docker &>/dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Ensure docker compose is available (either 'docker compose' or 'docker-compose')
if docker compose version &>/dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "Error: docker compose plugin or docker-compose is not installed."
    exit 1
fi

# Setup .env if missing
if [ ! -f .env ]; then
    echo "No .env file found. Creating .env from .env.example..."
    cp .env.example .env
    echo "Created .env. You can customize settings in .env as needed."
fi

# Source .env
export $(grep -v '^#' .env | xargs -d '\n' 2>/dev/null || true)

COMMET_PORT=${COMMET_PORT:-${PORT:-8080}}
HTTP_PORT=${HTTP_PORT:-80}
HTTPS_PORT=${HTTPS_PORT:-443}
DEFAULT_HOMESERVER=${DEFAULT_HOMESERVER:-matrix.org}

echo "Building and starting container(s)..."
$DOCKER_COMPOSE up -d --build

echo ""
echo "=========================================="
echo "  Commet successfully started!            "
echo "=========================================="
echo "Web URL (Direct):    http://localhost:${COMMET_PORT}"
echo "HTTP Port:           ${HTTP_PORT}"
echo "HTTPS Port:          ${HTTPS_PORT}"
echo "Default Homeserver:  ${DEFAULT_HOMESERVER}"
echo ""
echo "To view logs:        $DOCKER_COMPOSE logs -f commet"
echo "To stop:             $DOCKER_COMPOSE down"
echo "=========================================="

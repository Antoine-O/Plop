#!/bin/bash
set -e

echo "Starting server..."
docker compose -f docker-compose-server.yml up -d --build

echo "Running integration tests..."
# Use -d linux to run on Linux desktop (headless or visible)
flutter test -d linux integration_test/app_test.dart

echo "Stopping server..."
docker compose -f docker-compose-server.yml down

echo "Done!"

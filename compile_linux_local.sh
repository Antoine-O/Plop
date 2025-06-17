#!/bin/bash
docker compose  -f docker-compose-build-linux.yml build
docker compose  -f docker-compose-build-linux.yml create
docker compose cp compile-linux:/app ./build_output

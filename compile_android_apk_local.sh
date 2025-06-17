#!/bin/bash
SUBVERSION=$(date +%N) docker compose  -f docker-compose-build-android.yml build
docker compose  -f docker-compose-build-android.yml create
docker compose cp compile-android:/app ./build_output

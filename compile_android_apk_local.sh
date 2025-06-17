#!/bin/bash
docker compose  -f docker-compose-build-android.yml build
docker compose  -f docker-compose-build-android.yml create
docker compose cp compile-android:/app/app-release.apk ./build_output/plop-release.apk

#!/usr/bin/env bash

# Check the variables passed in to Docker build and/or created in the Dockerfile
echo "Path is: $PATH"
echo "Build time is: $BUILD_TIME"

# Periodically output something so we know container is still running.
while true; do
    date -Iseconds # --iso-8601=seconds
    sleep 1m
done
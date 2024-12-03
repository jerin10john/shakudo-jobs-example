#!/bin/bash

echo "Starting Docker build process..."

# Build the Docker image
if docker build -t my-app . ; then
    echo "✅ Docker build completed successfully!"
    echo "You can now run the container using: docker run my-app"
else
    echo "❌ Docker build failed!"
    exit 1
fi

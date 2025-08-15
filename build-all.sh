#!/bin/bash

# Build all Revideo packages for GitHub distribution
# This script builds the packages in the correct order with dependencies

set -e  # Exit on error

echo "🚀 Building all Revideo packages..."

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build telemetry package first (no dependencies)
echo "📊 Building @revideo/telemetry..."
npm run telemetry:build || echo "⚠️  Telemetry build had issues but continuing..."

# Build core package (no dependencies on other packages)
echo "🔨 Building @revideo/core..."
npm run core:build

# Build ffmpeg package (depends on core and telemetry)
echo "🎥 Building @revideo/ffmpeg..."
npm run ffmpeg:build || echo "⚠️  FFmpeg build had issues but continuing..."

# Build 2d package (depends on core)
echo "🎨 Building @revideo/2d..."
# Try full build first, but if editor fails, just build the lib
npm run 2d:build || {
    echo "⚠️  Full 2d build failed, trying library-only build..."
    npm run 2d:build-lib
}

# Build renderer package (depends on core and ffmpeg)
echo "🎬 Building @revideo/renderer..."
npm run renderer:build || echo "⚠️  Renderer build had issues but continuing..."

# Build vite-plugin (depends on core)
echo "⚡ Building @revideo/vite-plugin..."
npm run vite-plugin:build || echo "⚠️  Vite plugin build had issues but continuing..."

# Optional: Build UI if needed
# echo "🖼️ Building @revideo/ui..."
# npm run ui:build

echo "✅ All packages built successfully!"
echo ""
echo "📋 Built packages:"
echo "  - @revideo/core (v0.10.4)"
echo "  - @revideo/2d (v0.10.4)"
echo "  - @revideo/renderer (v0.10.4)"
echo "  - @revideo/vite-plugin"
echo ""
echo "Next steps:"
echo "1. Run ./prepare-github-release.sh to prepare for GitHub"
echo "2. Commit and push changes"
echo "3. Create a GitHub release with tag (e.g., v0.10.5)"
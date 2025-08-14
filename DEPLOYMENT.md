# Revideo Package Deployment Guide

This guide documents how to build and deploy patched Revideo packages to another project.

## Overview

When making fixes to Revideo packages (especially for issues like the IBR context bug), you need to:
1. Build the packages locally
2. Clear any caching in the target project
3. Deploy the built packages to the target project's node_modules

## Prerequisites

- Node.js and npm installed
- Access to both the Revideo source repository and target project

## Build Process

### 1. Install Dependencies

First, ensure all dependencies are installed in the Revideo repository:

```bash
npm install
```

### 2. Build Packages

Build the core and 2d packages (or any packages you've modified):

```bash
# Build core package
npm run core:build

# Build 2d package  
npm run 2d:build

# Or build both together
npm run core:build && npm run 2d:build
```

**Note**: The editor build may fail, but the library builds (which contain the runtime code) should succeed. This is usually fine for deployment.

## Deployment Process

### 1. Clear Vite Cache (if target uses Vite)

Vite caches dependencies in `.vite` folders. Clear these to ensure your changes take effect:

```bash
rm -rf /path/to/target/project/node_modules/.vite
```

### 2. Remove Old Packages

Remove the existing Revideo packages from the target project:

```bash
rm -rf /path/to/target/project/node_modules/@revideo/core
rm -rf /path/to/target/project/node_modules/@revideo/2d
```

### 3. Copy Built Packages

Copy the built packages to the target project:

```bash
# Create @revideo directory if it doesn't exist
mkdir -p /path/to/target/project/node_modules/@revideo

# Copy packages
cp -r packages/core /path/to/target/project/node_modules/@revideo/core
cp -r packages/2d /path/to/target/project/node_modules/@revideo/2d
```

### 4. Restart Dev Server

After deployment, restart the development server in your target project to load the new packages.

## Example: Full Deployment Script

Here's a complete example for deploying to a project at `/Users/username/Desktop/shader`:

```bash
# From the revideo repository root
TARGET="/Users/username/Desktop/shader"

# Build packages
npm run core:build && npm run 2d:build

# Clear cache and old packages
rm -rf "$TARGET/node_modules/.vite"
rm -rf "$TARGET/node_modules/@revideo/core"
rm -rf "$TARGET/node_modules/@revideo/2d"

# Deploy new packages
mkdir -p "$TARGET/node_modules/@revideo"
cp -r packages/core "$TARGET/node_modules/@revideo/core"
cp -r packages/2d "$TARGET/node_modules/@revideo/2d"

echo "Deployment complete! Restart the dev server in $TARGET"
```

## Fixes Applied

### IBR Context Issue Fix - Motion Canvas Synchronous Approach

The IBR (Incremental Build & Render) context issue was fixed by adopting Motion Canvas's synchronous rendering approach:

**Key Change**: Converted all rendering methods from async to synchronous to match Motion Canvas exactly.

**Files Modified**:
- `/packages/2d/src/lib/components/Node.ts` (lines 1637-1686)

**Changes Made**:
1. `public async render()` → `public render()` (line 1637)
2. `protected async draw()` → `protected draw()` (line 1678)  
3. `protected async drawChildren()` → `protected drawChildren()` (line 1682)
4. `protected async cachedCanvas()` → `protected cachedCanvas()` (line 1363)
5. Removed all `await` calls from these methods

**Motion Canvas Reference**: `/motion-canvas/packages/2d/src/lib/components/Node.ts:1649`
- Motion Canvas uses synchronous `public render(context: CanvasRenderingContext2D)` 
- This preserves scene context during rendering, preventing "scene not available" errors

### Application Context Fix

Removed fallback code from context hooks to match Motion Canvas:

**Files Modified**:
- `/packages/ui/src/contexts/application.tsx` (lines 27-29)
- `/packages/ui/src/contexts/panels.tsx` (lines 25-27)

**Changes**: Direct context return without fallbacks, matching Motion Canvas's approach.

### Shader System Fix

Fixed shader compilation by using proper file imports with preprocessor:

**Root Cause**: Inline strings don't support `#include` directives - requires Vite preprocessor.

**Solution**: Create `.glsl` files and import them instead of inline strings:
```ts
// Wrong: const shader = `#include "..."`;
// Right: import shader from './shader.glsl';
```

## Troubleshooting

### Build Errors

- **Editor build fails**: This is often okay - the library builds contain the runtime code
- **TypeScript errors**: Ensure all dependencies are installed with `npm install`

### Runtime Errors

- **"Scene not available" errors**: Make sure you've cleared Vite cache and restarted dev server
- **Shader compilation errors**: Verify GLSL version directives and variable names match

### Verification

To verify the deployment worked:

```bash
# Check if files exist
test -f "$TARGET/node_modules/@revideo/core/lib/scenes/GeneratorScene.js" && echo "Core deployed"
test -f "$TARGET/node_modules/@revideo/2d/lib/components/Node.js" && echo "2D deployed"
```

## Related Documentation

- [Motion Canvas Documentation](https://motioncanvas.io/docs/) - Revideo is based on Motion Canvas
- [WebGL2 Specification](https://www.khronos.org/webgl/wiki/WebGL_2_Specification)
- [GLSL ES 3.00 Specification](https://www.khronos.org/files/opengles_shading_language.pdf)
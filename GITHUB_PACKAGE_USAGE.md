# Using Revideo Packages from GitHub

This guide shows how to use the Revideo packages directly from GitHub in your projects.

## Method 1: Using Git URLs with npm (Recommended)

Since this is a monorepo with workspaces, you need to reference the specific workspace packages:

```json
{
  "dependencies": {
    "@revideo/core": "git+https://github.com/raghavaadi/revideo.git#v0.10.5",
    "@revideo/2d": "git+https://github.com/raghavaadi/revideo.git#v0.10.5",
    "@revideo/renderer": "git+https://github.com/raghavaadi/revideo.git#v0.10.5"
  }
}
```

### Important: Post-install Setup

Since npm will install the source repository, you need to build the packages after installation. Add this to your project's package.json:

```json
{
  "scripts": {
    "postinstall": "cd node_modules/@revideo && npm install && npm run core:build && npm run 2d:build && npm run renderer:build"
  }
}
```

## Method 2: Using GitHub Releases (After Setup)

Once you've built and tagged a release:

```json
{
  "dependencies": {
    "@revideo/core": "github:raghavaadi/revideo#v0.10.5",
    "@revideo/2d": "github:raghavaadi/revideo#v0.10.5",
    "@revideo/renderer": "github:raghavaadi/revideo#v0.10.5"
  }
}
```

## Method 3: Direct Installation Commands

```bash
# Install specific version
npm install github:raghavaadi/revideo#v0.10.5

# Or install from a branch
npm install github:raghavaadi/revideo#video-shader-fixes

# Or with explicit git URL
npm install git+https://github.com/raghavaadi/revideo.git#v0.10.5
```

## Method 4: Using Workspace Packages (Advanced)

If you want to install individual workspace packages, you'll need to:

1. First install the entire repository
2. Then link the specific packages

```bash
# Install the monorepo
npm install github:raghavaadi/revideo#v0.10.5

# The packages will be available at:
# node_modules/@revideo/core
# node_modules/@revideo/2d
# node_modules/@revideo/renderer
```

## Troubleshooting

### Issue: Packages not found after installation

**Solution**: The monorepo structure requires building after installation. Ensure you have the postinstall script.

### Issue: TypeScript types not found

**Solution**: Make sure the built `.d.ts` files are included. Run the build scripts:
```bash
cd node_modules/@revideo
npm run core:build
npm run 2d:build
```

### Issue: Vite cache issues

**Solution**: Clear Vite's dependency cache:
```bash
rm -rf node_modules/.vite
```

## Example Project Setup

Here's a complete example `package.json` for a project using Revideo from GitHub:

```json
{
  "name": "my-revideo-project",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "postinstall": "node scripts/build-revideo.js"
  },
  "dependencies": {
    "@revideo/core": "github:raghavaadi/revideo#v0.10.5",
    "@revideo/2d": "github:raghavaadi/revideo#v0.10.5",
    "@revideo/renderer": "github:raghavaadi/revideo#v0.10.5"
  },
  "devDependencies": {
    "vite": "^4.5.2",
    "typescript": "^5.2.2"
  }
}
```

And the `scripts/build-revideo.js` helper:

```javascript
// scripts/build-revideo.js
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const revideoPath = path.join(__dirname, '..', 'node_modules', '@revideo');

if (fs.existsSync(revideoPath)) {
  console.log('Building Revideo packages...');
  
  try {
    // Install dependencies in the monorepo
    execSync('npm install', { 
      cwd: revideoPath,
      stdio: 'inherit'
    });
    
    // Build packages in order
    execSync('npm run core:build', {
      cwd: revideoPath,
      stdio: 'inherit'
    });
    
    execSync('npm run 2d:build', {
      cwd: revideoPath,
      stdio: 'inherit'
    });
    
    execSync('npm run renderer:build', {
      cwd: revideoPath,
      stdio: 'inherit'
    });
    
    console.log('✅ Revideo packages built successfully!');
  } catch (error) {
    console.error('Failed to build Revideo packages:', error);
    process.exit(1);
  }
}
```

## Using Pre-built Packages

For the best experience, you should:

1. Fork the repository
2. Set up GitHub Actions to build on push
3. Create releases with built artifacts
4. Reference the releases in your projects

This avoids the need for post-install builds in consuming projects.
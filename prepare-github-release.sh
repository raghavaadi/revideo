#!/bin/bash

# Prepare Revideo packages for GitHub distribution
# This script prepares the built packages to be consumable from GitHub

set -e  # Exit on error

echo "📦 Preparing packages for GitHub distribution..."

# Ensure packages are built
if [ ! -d "packages/core/lib" ] || [ ! -d "packages/2d/lib" ] || [ ! -d "packages/renderer/lib" ]; then
    echo "❌ Error: Packages not built. Run ./build-all.sh first"
    exit 1
fi

# Update package.json files to ensure they work when installed from GitHub
echo "📝 Updating package.json files for GitHub distribution..."

# Function to update version in package.json
update_version() {
    local package_path=$1
    local new_version=$2
    
    if [ -f "$package_path/package.json" ]; then
        echo "  Updating $package_path to version $new_version..."
        # Use a temporary file for safety
        node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$package_path/package.json', 'utf8'));
        pkg.version = '$new_version';
        fs.writeFileSync('$package_path/package.json', JSON.stringify(pkg, null, 2) + '\\n');
        "
    fi
}

# Get version from command line or use default
VERSION=${1:-0.10.5}

echo "🏷️  Setting version to: $VERSION"

# Update versions
update_version "packages/core" "$VERSION"
update_version "packages/2d" "$VERSION"
update_version "packages/renderer" "$VERSION"
update_version "packages/ui" "$VERSION"
update_version "packages/vite-plugin" "$VERSION"
update_version "packages/player" "$VERSION"
update_version "packages/ffmpeg" "$VERSION"

# Update inter-package dependencies
echo "🔗 Updating inter-package dependencies..."

node -e "
const fs = require('fs');
const version = '$VERSION';

// Update 2d package dependencies
const pkg2d = JSON.parse(fs.readFileSync('packages/2d/package.json', 'utf8'));
if (pkg2d.dependencies['@revideo/core']) {
    pkg2d.dependencies['@revideo/core'] = version;
}
if (pkg2d.devDependencies['@revideo/ui']) {
    pkg2d.devDependencies['@revideo/ui'] = version;
}
fs.writeFileSync('packages/2d/package.json', JSON.stringify(pkg2d, null, 2) + '\\n');

// Update renderer package dependencies
const pkgRenderer = JSON.parse(fs.readFileSync('packages/renderer/package.json', 'utf8'));
if (pkgRenderer.dependencies['@revideo/ffmpeg']) {
    pkgRenderer.dependencies['@revideo/ffmpeg'] = version;
}
if (pkgRenderer.devDependencies['@revideo/core']) {
    pkgRenderer.devDependencies['@revideo/core'] = version;
}
fs.writeFileSync('packages/renderer/package.json', JSON.stringify(pkgRenderer, null, 2) + '\\n');

console.log('✅ Inter-package dependencies updated');
"

# Create a dist-info file for tracking
echo "📄 Creating distribution info..."
cat > GITHUB_DIST_INFO.md << EOF
# GitHub Distribution Info

## Version: $VERSION
## Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
## Branch: $(git branch --show-current)
## Commit: $(git rev-parse --short HEAD)

## Packages Included:
- @revideo/core@$VERSION
- @revideo/2d@$VERSION  
- @revideo/renderer@$VERSION
- @revideo/vite-plugin@$VERSION
- @revideo/ui@$VERSION
- @revideo/player@$VERSION
- @revideo/ffmpeg@$VERSION

## Installation:

To use these packages from GitHub, add to your package.json:

\`\`\`json
{
  "dependencies": {
    "@revideo/core": "github:raghavaadi/revideo#v$VERSION",
    "@revideo/2d": "github:raghavaadi/revideo#v$VERSION",
    "@revideo/renderer": "github:raghavaadi/revideo#v$VERSION"
  }
}
\`\`\`

Or install directly:

\`\`\`bash
npm install github:raghavaadi/revideo#v$VERSION
\`\`\`

## Notes:
- Packages are pre-built and ready to use
- No compilation required on install
- Compatible with npm/yarn/pnpm
EOF

echo "✅ Package preparation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review changes: git status"
echo "2. Commit changes: git add -A && git commit -m 'Build packages for v$VERSION'"
echo "3. Push to GitHub: git push origin $(git branch --show-current)"
echo "4. Create release: gh release create v$VERSION --title 'Release v$VERSION' --notes 'Built packages for distribution'"
echo ""
echo "🎯 After release, use in other projects with:"
echo "   npm install github:raghavaadi/revideo#v$VERSION"
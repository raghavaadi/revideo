#!/bin/bash

# Automated release script for Revideo packages
# This script builds, prepares, commits, and releases in one command

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from command line or prompt
VERSION=${1}

if [ -z "$VERSION" ]; then
    echo -e "${YELLOW}Enter the version number (e.g., 0.10.5):${NC}"
    read VERSION
    
    if [ -z "$VERSION" ]; then
        echo -e "${RED}❌ Version is required${NC}"
        exit 1
    fi
fi

# Ensure version doesn't start with 'v' for consistency
VERSION=${VERSION#v}

echo -e "${BLUE}🚀 Starting automated release for version $VERSION${NC}"
echo ""

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    echo "Do you want to continue? (y/n)"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Release cancelled${NC}"
        exit 1
    fi
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}📍 Current branch: $CURRENT_BRANCH${NC}"

# Step 1: Build all packages
echo ""
echo -e "${GREEN}Step 1/5: Building all packages...${NC}"
./build-all.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

# Step 2: Prepare for release
echo ""
echo -e "${GREEN}Step 2/5: Preparing packages for GitHub release...${NC}"
./prepare-github-release.sh $VERSION

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Release preparation failed${NC}"
    exit 1
fi

# Step 3: Commit changes
echo ""
echo -e "${GREEN}Step 3/5: Committing changes...${NC}"
git add -A
git commit -m "Build packages for v$VERSION" || {
    echo -e "${YELLOW}⚠️  No changes to commit (packages might already be up to date)${NC}"
}

# Step 4: Push to current branch
echo ""
echo -e "${GREEN}Step 4/5: Pushing to $CURRENT_BRANCH...${NC}"
git push origin $CURRENT_BRANCH

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Push failed. Please check your git configuration${NC}"
    exit 1
fi

# Step 5: Create and push tag
echo ""
echo -e "${GREEN}Step 5/5: Creating and pushing tag v$VERSION...${NC}"

# Check if tag already exists
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Tag v$VERSION already exists${NC}"
    echo "Do you want to delete and recreate it? (y/n)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "v$VERSION"
        git push origin --delete "v$VERSION" 2>/dev/null || true
    else
        echo -e "${RED}❌ Release cancelled${NC}"
        exit 1
    fi
fi

git tag -a "v$VERSION" -m "Release v$VERSION - Built packages for distribution"
git push --tags

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to push tags${NC}"
    exit 1
fi

# Success!
echo ""
echo -e "${GREEN}✅ Release v$VERSION completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  • Built all packages"
echo "  • Updated versions to $VERSION"
echo "  • Committed changes"
echo "  • Pushed to branch: $CURRENT_BRANCH"
echo "  • Created and pushed tag: v$VERSION"
echo ""
echo -e "${YELLOW}📦 To use in other projects, add to package.json:${NC}"
echo ""
echo "  \"dependencies\": {"
echo "    \"@revideo/core\": \"github:raghavaadi/revideo#v$VERSION\","
echo "    \"@revideo/2d\": \"github:raghavaadi/revideo#v$VERSION\","
echo "    \"@revideo/renderer\": \"github:raghavaadi/revideo#v$VERSION\""
echo "  }"
echo ""
echo -e "${BLUE}🎉 GitHub Actions will now automatically create a release!${NC}"
echo ""
echo "View your release at:"
echo "https://github.com/raghavaadi/revideo/releases/tag/v$VERSION"
#!/bin/bash
#
# Manual Release Creation Script
# Use this if GitHub Actions isn't enabled
#

set -e

VERSION="1.0.0"
TAG="v${VERSION}"
REPO="elblanco2/painttwits-artist"

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              CREATE GITHUB RELEASE FOR PAINTTWITS-ARTIST                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Version: ${VERSION}"
echo "Tag: ${TAG}"
echo "Repo: ${REPO}"
echo ""

# Check if tag exists
if ! git rev-parse ${TAG} >/dev/null 2>&1; then
    echo "Creating tag ${TAG}..."
    git tag ${TAG}
    git push origin ${TAG}
    echo "✅ Tag created and pushed!"
else
    echo "✅ Tag ${TAG} already exists"
fi

echo ""
echo "Creating release ZIP..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
RELEASE_DIR="${TEMP_DIR}/painttwits-artist-${VERSION}"
ZIP_FILE="painttwits-artist-v${VERSION}.zip"

# Copy files (exclude dev files)
mkdir -p "${RELEASE_DIR}"
rsync -av --progress \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='node_modules' \
  --exclude='artist_config.php' \
  --exclude='.DS_Store' \
  --exclude='*.log' \
  --exclude='logs/*' \
  --exclude='uploads/*' \
  --exclude='dzi/*' \
  --exclude='backups/*' \
  --exclude='create_release_manual.sh' \
  . "${RELEASE_DIR}/"

# Update version.php
cat > "${RELEASE_DIR}/version.php" << EOF
<?php
/**
 * Painttwits Artist Gallery - Version Information
 *
 * This file is auto-generated during releases.
 * Used by the update system to check for new versions.
 */

return [
    'version' => '${VERSION}',
    'release_date' => '$(date -u +%Y-%m-%d)',
    'changelog_url' => 'https://github.com/${REPO}/releases/tag/${TAG}',
    'min_php_version' => '7.4.0',
    'github_repo' => '${REPO}'
];
EOF

# Create ZIP
cd "${TEMP_DIR}"
zip -r "${ZIP_FILE}" "painttwits-artist-${VERSION}"
mv "${ZIP_FILE}" "${OLDPWD}/"
cd "${OLDPWD}"

# Cleanup
rm -rf "${TEMP_DIR}"

echo "✅ Release ZIP created: ${ZIP_FILE}"
echo ""

# Generate release notes
RELEASE_NOTES=$(cat << 'EOF'
## First Release

Initial release of the Painttwits Artist Gallery with automatic update system.

### Features

- Masonry grid gallery layout with deep zoom viewer
- Email-to-gallery uploads
- Google OAuth authentication
- Location-based discovery via painttwits network
- Social sharing (Bluesky, Twitter, Pinterest)
- **NEW:** One-click software updates (self-hosted only)
- **NEW:** Automatic backups before updates
- **NEW:** One-click rollback system
- Dark mode support
- Mobile responsive
- SEO-friendly

### Installation

#### Self-Hosted Setup
1. Download the ZIP file below
2. Extract to your web server directory
3. Run `setup.php` in your browser to configure
4. Follow the setup wizard

#### Requirements
- PHP 7.4 or higher
- MySQL 5.7+ or MariaDB 10.2+
- Web server (Apache/Nginx)
- SSL certificate (recommended)

### Updating

If you have the update system installed:
1. Go to Settings → Software Updates
2. Click "Update Now"
3. Automatic backup will be created

Or manually:
1. Backup your current installation
2. Download and extract this release
3. Preserve your `artist_config.php` file
4. Copy new files over existing installation

For more details, see [README.md](https://github.com/elblanco2/painttwits-artist/blob/main/README.md)
EOF
)

# Create release on GitHub
echo "Creating GitHub release..."
echo ""

if command -v gh >/dev/null 2>&1; then
    # Use GitHub CLI
    echo "${RELEASE_NOTES}" | gh release create "${TAG}" \
        --repo "${REPO}" \
        --title "Version ${VERSION}" \
        --notes-file - \
        "${ZIP_FILE}"

    echo ""
    echo "✅ Release created successfully!"
    echo ""
    echo "View it at: https://github.com/${REPO}/releases/tag/${TAG}"
else
    echo "GitHub CLI (gh) not found."
    echo ""
    echo "Please create the release manually:"
    echo "  1. Go to: https://github.com/${REPO}/releases/new"
    echo "  2. Tag: ${TAG}"
    echo "  3. Title: Version ${VERSION}"
    echo "  4. Upload: ${ZIP_FILE}"
    echo "  5. Release notes:"
    echo ""
    echo "${RELEASE_NOTES}"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        RELEASE CREATION COMPLETE! ✅                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"

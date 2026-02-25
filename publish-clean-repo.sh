#!/bin/bash
set -e

# ============================================================================
# NixOS Repository Clean Publisher
# Creates a new repository with no git history, removing all tracked secrets
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO_PATH="${1:-.}"
OUTPUT_DIR="${2:-../nixos-public}"

echo -e "${GREEN}=== NixOS Public Repository Generator ===${NC}\n"

if [ ! -d "$REPO_PATH/.git" ]; then
    echo -e "${RED}Error: Not a git repository: $REPO_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5]${NC} Validating git-crypt status..."
cd "$REPO_PATH"

# Check encrypted files
ENCRYPTED_FILES=$(git-crypt ls-files 2>/dev/null | wc -l)
echo "  ✓ Found $ENCRYPTED_FILES encrypted files (git-crypt)"

echo -e "\n${YELLOW}[2/5]${NC} Checking for unencrypted secrets..."

# Search for common patterns (warning only, not fatal)
SUSPECT_FILES=$(git ls-files | xargs grep -l -E "password|api.key|secret|token" 2>/dev/null | grep -v ".example" || true)
if [ -n "$SUSPECT_FILES" ]; then
    echo -e "${RED}  ⚠ Possible unencrypted secrets found:${NC}"
    echo "$SUSPECT_FILES" | sed 's/^/    - /'
    echo -e "\n${YELLOW}Review these files before publishing!${NC}\n"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo -e "\n${YELLOW}[3/5]${NC} Checking .gitignore compliance..."
IGNORED_PATTERNS=(
    "Pulumi.dev.yaml"
    "hacompanion.toml"
    "\.key$"
    "\.pem$"
    "\.secret$"
)

for pattern in "${IGNORED_PATTERNS[@]}"; do
    COUNT=$(git ls-files | grep -c "$pattern" || true)
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${RED}  ✗ Found tracked files matching '$pattern':${NC}"
        git ls-files | grep "$pattern" | sed 's/^/    - /'
        exit 1
    fi
done
echo "  ✓ No sensitive files in tracking"

echo -e "\n${YELLOW}[4/5]${NC} Creating clean repository..."

if [ -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}  Output directory already exists: $OUTPUT_DIR${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"

# Copy files, excluding .git and other artifacts
rsync -av \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='venv' \
    --exclude='.venv' \
    --exclude='*.pyc' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    --exclude='.dirlocal' \
    --exclude='Pulumi.dev.yaml' \
    --exclude='.terraform' \
    --exclude='*.tfstate*' \
    "$REPO_PATH/" "$OUTPUT_DIR/"

echo "  ✓ Files copied to $OUTPUT_DIR"

echo -e "\n${YELLOW}[5/5]${NC} Initializing new git repository..."

cd "$OUTPUT_DIR"
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Copy git-crypt configuration if present
if [ -f "$REPO_PATH/.git/config" ]; then
    git-crypt init
    echo "  ✓ Initialized git-crypt"
fi

git add -A
git commit -m "Initial commit: Clean NixOS configuration"

echo -e "\n${GREEN}✓ Success!${NC}"
echo -e "\n${GREEN}New repository created at: $OUTPUT_DIR${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the configuration:"
echo "     cd $OUTPUT_DIR"
echo "     git log --oneline"
echo "     git ls-files"
echo ""
echo "  2. Add git-crypt keys (if needed):"
echo "     git-crypt add-user YOUR_GPG_KEY"
echo ""
echo "  3. Add remote and push:"
echo "     git remote add origin https://github.com/YOUR_USER/nixos.git"
echo "     git branch -M main"
echo "     git push -u origin main"
echo ""
echo "  4. Tag the release:"
echo "     git tag -a v1.0 -m 'Initial public release'"
echo "     git push origin v1.0"

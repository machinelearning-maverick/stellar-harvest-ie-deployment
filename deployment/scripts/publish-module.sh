#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# deployment/scripts/publish-module.sh
# ------------------------------------------------------------
# Usage:
#   ./publish-module.sh [<path-to-your-project>]
#
# Version is ALWAYS read from pyproject.toml - no --version flag.
# If the version already exists on devpi, this script fails loudly
# rather than silently re-publishing (which would poison Docker
# layer caches downstream).
# ------------------------------------------------------------

PROJECT_DIR="${1:-$(pwd)}"
cd "$PROJECT_DIR"

# load .env
if [[ -f "$PROJECT_DIR/.env" ]]; then
  # shellcheck disable=SC1090
  source "$PROJECT_DIR/.env"
else
  echo "No .env found in $PROJECT_DIR" >&2
  exit 1
fi

: "${TWINE_REPOSITORY_URL:?Need TWINE_REPOSITORY_URL in .env}"
: "${TWINE_USERNAME:?Need TWINE_USERNAME in .env}"
: "${TWINE_PASSWORD:?Need TWINE_PASSWORD in .env}"

# ------------------------------------------------------------
# Extract name + version from pyproject.toml (single source of truth)
# ------------------------------------------------------------
MODULE_NAME=$(python3 -c "
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
with open('pyproject.toml','rb') as f:
    print(tomllib.load(f)['project']['name'])
")

MODULE_VERSION=$(python3 -c "
import sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
with open('pyproject.toml','rb') as f:
    print(tomllib.load(f)['project']['version'])
")

echo "Module:  $MODULE_NAME"
echo "Version: $MODULE_VERSION"

# ------------------------------------------------------------
# Duplicate-version guard: fail before we build, not after.
# This is the single most important check in the script.
# ------------------------------------------------------------
DEVPI_VERSION_URL="${TWINE_REPOSITORY_URL%/}/${MODULE_NAME}/${MODULE_VERSION}/"
HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" \
  -u "$TWINE_USERNAME:$TWINE_PASSWORD" \
  -H "Accept: application/json" \
  "$DEVPI_VERSION_URL" || echo "000")

if [[ "$HTTP_CODE" == "200" ]]; then
  echo "" >&2
  echo "ERROR: ${MODULE_NAME}==${MODULE_VERSION} already exists on devpi." >&2
  echo "       Bump 'version' in ${PROJECT_DIR}/pyproject.toml before publishing." >&2
  echo "       Re-publishing the same version silently poisons Docker layer caches." >&2
  exit 2
elif [[ "$HTTP_CODE" != "404" ]]; then
  echo "WARNING: devpi check returned HTTP $HTTP_CODE (expected 404 for new versions)." >&2
  echo "         Proceeding anyway — verify your devpi URL if this looks wrong." >&2
fi

# ------------------------------------------------------------
# venv + build (unchanged from your original)
# ------------------------------------------------------------
if [[ ! -d ".venv" ]]; then
  echo "Creating virtual environment..."
  python3 -m venv .venv
fi
source .venv/bin/activate

echo "Installing locally and building artifacts..."
rm -rf dist/
pip install -r requirements.txt --upgrade
pip install --quiet --upgrade -e . build twine
python3 -m build

# ------------------------------------------------------------
# Upload — always filter to exactly the version in pyproject.toml
# ------------------------------------------------------------
FILES=(dist/*"${MODULE_VERSION}"*)
if [[ ${#FILES[@]} -eq 0 ]] || [[ ! -e "${FILES[0]}" ]]; then
  echo "ERROR: No dist files found matching version ${MODULE_VERSION}" >&2
  exit 1
fi

echo "Uploading ${#FILES[@]} file(s):"
printf "   %s\n" "${FILES[@]}"

TWINE_REPOSITORY_URL="$TWINE_REPOSITORY_URL" \
TWINE_USERNAME="$TWINE_USERNAME" \
TWINE_PASSWORD="$TWINE_PASSWORD" \
twine upload \
  --repository-url "$TWINE_REPOSITORY_URL" \
  "${FILES[@]}"

echo "Published ${MODULE_NAME}==${MODULE_VERSION}"
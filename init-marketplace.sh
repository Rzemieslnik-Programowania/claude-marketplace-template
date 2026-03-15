#!/usr/bin/env bash
set -euo pipefail

# --- Idempotency guard ---
if ! grep -q '__MARKETPLACE_NAME__' create-plugin.sh 2>/dev/null; then
  echo "Error: This marketplace has already been initialized (no placeholders found in create-plugin.sh)."
  echo "If you want to re-initialize, restore the template placeholders first."
  exit 1
fi

# --- Cross-platform sed detection ---
if sed --version 2>/dev/null | grep -q 'GNU'; then
  sedi() { sed -i "$@"; }
else
  sedi() { sed -i '' "$@"; }
fi

# --- Escape sed special characters in user input ---
escape_sed() {
  printf '%s' "$1" | sed 's/[&\|/]/\\&/g'
}

# --- Title-case a kebab-case string ---
title_case() {
  echo "$1" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g'
}

echo "=== Claude Code Plugin Marketplace Setup ==="
echo ""

# --- Prompt: Marketplace name ---
while true; do
  read -rp "Marketplace name (kebab-case, e.g. acme-claude-marketplace): " MARKETPLACE_NAME
  if [[ "$MARKETPLACE_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    break
  fi
  echo "  Invalid: must start with a lowercase letter and contain only lowercase letters, digits, and hyphens."
done

# --- Prompt: GitHub repo ---
while true; do
  read -rp "GitHub repo (owner/repo, e.g. AcmeCorp/acme-marketplace): " MARKETPLACE_REPO
  # Strip https://github.com/ prefix if pasted
  MARKETPLACE_REPO="${MARKETPLACE_REPO#https://github.com/}"
  # Strip trailing slashes and .git suffix
  MARKETPLACE_REPO="${MARKETPLACE_REPO%.git}"
  MARKETPLACE_REPO="${MARKETPLACE_REPO%/}"
  if [[ "$MARKETPLACE_REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    break
  fi
  echo "  Invalid: must be in owner/repo format (e.g. AcmeCorp/acme-marketplace)."
done

# --- Prompt: Author name ---
while true; do
  read -rp "Author name (e.g. Jane Smith): " AUTHOR_NAME
  if [[ -n "$AUTHOR_NAME" ]]; then
    break
  fi
  echo "  Invalid: author name cannot be empty."
done

# --- Prompt: Display name ---
DEFAULT_DISPLAY_NAME="$(title_case "$MARKETPLACE_NAME")"
read -rp "Display name [$DEFAULT_DISPLAY_NAME]: " MARKETPLACE_DISPLAY_NAME
MARKETPLACE_DISPLAY_NAME="${MARKETPLACE_DISPLAY_NAME:-$DEFAULT_DISPLAY_NAME}"

# --- Prompt: Description ---
DEFAULT_DESCRIPTION="A collection of Claude Code plugins"
read -rp "Description [$DEFAULT_DESCRIPTION]: " MARKETPLACE_DESCRIPTION
MARKETPLACE_DESCRIPTION="${MARKETPLACE_DESCRIPTION:-$DEFAULT_DESCRIPTION}"

echo ""
echo "--- Configuration Summary ---"
echo "  Marketplace name:    $MARKETPLACE_NAME"
echo "  GitHub repo:         $MARKETPLACE_REPO"
echo "  Author:              $AUTHOR_NAME"
echo "  Display name:        $MARKETPLACE_DISPLAY_NAME"
echo "  Description:         $MARKETPLACE_DESCRIPTION"
echo ""
read -rp "Proceed? [Y/n] " CONFIRM
if [[ "${CONFIRM:-Y}" =~ ^[Nn] ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Configuring marketplace..."

# --- Escape values for sed ---
E_NAME="$(escape_sed "$MARKETPLACE_NAME")"
E_REPO="$(escape_sed "$MARKETPLACE_REPO")"
E_AUTHOR="$(escape_sed "$AUTHOR_NAME")"
E_DISPLAY="$(escape_sed "$MARKETPLACE_DISPLAY_NAME")"
E_DESC="$(escape_sed "$MARKETPLACE_DESCRIPTION")"

# --- Files to process ---
FILES=(
  "create-plugin.sh"
  ".claude-plugin/marketplace.json"
  "README.md"
  "CLAUDE.md"
)

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    sedi "s|__MARKETPLACE_NAME__|${E_NAME}|g" "$file"
    sedi "s|__MARKETPLACE_REPO__|${E_REPO}|g" "$file"
    sedi "s|__AUTHOR_NAME__|${E_AUTHOR}|g" "$file"
    sedi "s|__MARKETPLACE_DISPLAY_NAME__|${E_DISPLAY}|g" "$file"
    sedi "s|__MARKETPLACE_DESCRIPTION__|${E_DESC}|g" "$file"
    echo "  Updated: $file"
  fi
done

# --- Remove template instructions block from README ---
# Everything from the first line up to and including the "---" separator line
if head -1 README.md | grep -q '^>'; then
  # Find the line number of the first "---" separator
  SEPARATOR_LINE=$(grep -n '^---$' README.md | head -1 | cut -d: -f1)
  if [[ -n "$SEPARATOR_LINE" ]]; then
    # Remove lines 1 through SEPARATOR_LINE (the --- line), plus any blank line after
    NEXT_LINE=$((SEPARATOR_LINE + 1))
    NEXT_CONTENT=$(sed -n "${NEXT_LINE}p" README.md)
    if [[ -z "$NEXT_CONTENT" ]]; then
      # Also remove the blank line after ---
      sedi "1,${NEXT_LINE}d" README.md
    else
      sedi "1,${SEPARATOR_LINE}d" README.md
    fi
    echo "  Removed template instructions block from README.md"
  fi
fi

# --- Remove init-marketplace.sh reference from CLAUDE.md Key Commands ---
sedi '/# Initialize the marketplace/d' CLAUDE.md
sedi '/\.\/init-marketplace\.sh/d' CLAUDE.md
# Remove blank line left behind if any
sedi '/^$/N;/^\n$/d' CLAUDE.md 2>/dev/null || true
# Also remove init-marketplace.sh from Architecture section
sedi '/\*\*`init-marketplace.sh`\*\*/d' CLAUDE.md
echo "  Cleaned up CLAUDE.md references to init-marketplace.sh"

# --- Delete this script ---
rm -- "$0"
echo "  Removed init-marketplace.sh"

echo ""
echo "=== Marketplace initialized! ==="
echo ""
echo "Next steps:"
echo "  1. Review the generated files (README.md, CLAUDE.md, create-plugin.sh)"
echo "  2. Create your first plugin:"
echo "       ./create-plugin.sh my-plugin \"Short description\""
echo "  3. Commit and push to $MARKETPLACE_REPO"

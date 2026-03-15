#!/usr/bin/env bash
set -euo pipefail

MARKETPLACE_NAME="__MARKETPLACE_NAME__"
MARKETPLACE_REPO="__MARKETPLACE_REPO__"
AUTHOR_NAME="__AUTHOR_NAME__"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Usage ---
usage() {
  echo "Usage: $0 <plugin-name> <description>"
  echo ""
  echo "Scaffold a new plugin with the standard directory structure,"
  echo "boilerplate files."
  echo ""
  echo "Arguments:"
  echo "  plugin-name    Short identifier (lowercase, hyphens ok). Becomes the directory name"
  echo "                 and the plugin identifier (<plugin-name>@${MARKETPLACE_NAME})."
  echo "  description    One-line description of the plugin (quoted)."
  echo ""
  echo "Example:"
  echo "  $0 my-plugin \"Tools for backend development with Claude Code\""
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

PLUGIN_NAME="$1"
PLUGIN_DESC="$2"
PLUGIN_DIR="$SCRIPT_DIR/plugins/$PLUGIN_NAME"

# --- Validation ---
if [[ ! "$PLUGIN_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Error: Plugin name must start with a lowercase letter and contain only lowercase letters, digits, and hyphens."
  exit 1
fi

if [[ -d "$PLUGIN_DIR" ]]; then
  echo "Error: Directory plugins/$PLUGIN_NAME/ already exists."
  exit 1
fi

echo "=== Creating plugin: $PLUGIN_NAME ==="

# --- Directory structure ---
mkdir -p "$PLUGIN_DIR/.claude-plugin"
mkdir -p "$PLUGIN_DIR/agents"
mkdir -p "$PLUGIN_DIR/commands"
mkdir -p "$PLUGIN_DIR/docs"
mkdir -p "$PLUGIN_DIR/skills"

touch "$PLUGIN_DIR/agents/.gitkeep"
touch "$PLUGIN_DIR/commands/.gitkeep"
touch "$PLUGIN_DIR/skills/.gitkeep"

# --- plugin.json ---
cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" <<EOF
{
  "name": "$PLUGIN_NAME",
  "description": "$PLUGIN_DESC",
  "version": "0.0.1",
  "author": {
    "name": "$AUTHOR_NAME"
  },
  "repository": "https://github.com/$MARKETPLACE_REPO"
}
EOF

# --- docs/FEATURES.md ---
cat > "$PLUGIN_DIR/docs/FEATURES.md" <<EOF
# Feature Reference

Quick reference to all agents and skills in the \`$PLUGIN_NAME\` plugin.

> **Keep this file up-to-date** whenever you add, modify, or remove a feature.

## Agents

| Name | Description |
|------|-------------|
| —    | No agents yet. |

## Skills

| Name | Trigger | Description |
|------|---------|-------------|
| —    | —       | No skills yet. |
EOF

# --- CHANGELOG.md ---
cat > "$PLUGIN_DIR/CHANGELOG.md" <<EOF
# Changelog

All notable changes to the \`$PLUGIN_NAME\` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - $(date +%Y-%m-%d)

### Added
- Initial plugin scaffolding
EOF

# --- README.md ---
cat > "$PLUGIN_DIR/README.md" <<EOF
# $PLUGIN_NAME Plugin

$PLUGIN_DESC

## Prerequisites

The \`$MARKETPLACE_NAME\` marketplace must be registered first. If you installed via the root \`install.sh\`, this is already done. Otherwise:

\`\`\`bash
claude plugin marketplace add $MARKETPLACE_REPO
\`\`\`

## Installation

### From GitHub

\`\`\`bash
claude plugin marketplace add $MARKETPLACE_REPO
claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME}
\`\`\`

### From a local clone

\`\`\`bash
claude plugin marketplace add ./path/to/__MARKETPLACE_NAME__
claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME}
\`\`\`

### From a remote URL

\`\`\`bash
claude plugin marketplace add https://example.com/marketplace.json
claude plugin install ${PLUGIN_NAME}@${MARKETPLACE_NAME}
\`\`\`

> **Private repos:** Uses your existing git credentials. For background auto-updates, set \`GITHUB_TOKEN\` or \`GH_TOKEN\` in your environment.

## Update

\`\`\`bash
claude plugin marketplace update $MARKETPLACE_REPO
claude plugin update ${PLUGIN_NAME}@${MARKETPLACE_NAME}
\`\`\`

## Uninstall

\`\`\`bash
claude plugin uninstall ${PLUGIN_NAME}@${MARKETPLACE_NAME}
\`\`\`

## Directory Structure

\`\`\`
$PLUGIN_NAME/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest (name, version, metadata)
├── agents/               # Agent definitions (empty)
├── CHANGELOG.md          # Plugin changelog
├── commands/             # Command definitions (empty)
├── docs/
│   └── FEATURES.md       # Feature catalog for this plugin
├── skills/               # Skill definitions (empty)
└── README.md             # This file
\`\`\`

## Adding Features

- **Agents** — Add agent definition files to \`agents/\`
- **Skills** — Add skill definition files to \`skills/\`
- **Commands** — Add command definition files to \`commands/\`

After adding any feature, update both this \`README.md\` and \`docs/FEATURES.md\` to keep the documentation current.
EOF

# --- Register in marketplace.json ---
MARKETPLACE_JSON="$SCRIPT_DIR/.claude-plugin/marketplace.json"

# Check for duplicate plugin name
if grep -q "\"name\": \"$PLUGIN_NAME\"" "$MARKETPLACE_JSON"; then
  echo "Error: Plugin $PLUGIN_NAME already exists in marketplace.json" >&2
  exit 1
fi

# Build the new plugin JSON entry (indentation matches marketplace.json's 4-space style)
NEW_ENTRY='        {
            "name": "'"$PLUGIN_NAME"'",
            "description": "'"$PLUGIN_DESC"'",
            "version": "0.0.1",
            "author": {
                "name": "'"$AUTHOR_NAME"'"
            },
            "source": "./plugins/'"$PLUGIN_NAME"'",
            "category": "development"
        }'

# Insert into the plugins array
TEMP_FILE=$(mktemp)
if grep -q '"plugins": \[\]' "$MARKETPLACE_JSON"; then
  # Empty array: expand [] into array with new entry
  while IFS= read -r line; do
    if [[ "$line" == *'"plugins": []'* ]]; then
      echo '    "plugins": ['
      echo "$NEW_ENTRY"
      echo '    ]'
    else
      echo "$line"
    fi
  done < "$MARKETPLACE_JSON" > "$TEMP_FILE"
else
  # Non-empty array: add comma after last entry, insert new entry before ]
  mapfile -t lines < "$MARKETPLACE_JSON"
  for i in "${!lines[@]}"; do
    line="${lines[$i]}"
    next_line="${lines[$((i+1))]:-}"
    if [[ "$line" == "        }" && "$next_line" == "    ]" ]]; then
      echo "${line},"
      echo "$NEW_ENTRY"
    else
      echo "$line"
    fi
  done > "$TEMP_FILE"
fi
mv "$TEMP_FILE" "$MARKETPLACE_JSON"

echo ""
echo "Done! Created plugins/$PLUGIN_NAME/ with:"
echo "  .claude-plugin/plugin.json"
echo "  agents/ (empty)"
echo "  CHANGELOG.md"
echo "  commands/ (empty)"
echo "  docs/FEATURES.md"
echo "  skills/ (empty)"
echo "  README.md"
echo ""
echo "Plugin registered in .claude-plugin/marketplace.json"
echo ""
echo "Next steps:"
echo "  1. Add agents, skills, or commands to plugins/$PLUGIN_NAME/"
echo "  2. Update the root README.md 'Available Plugins' table"

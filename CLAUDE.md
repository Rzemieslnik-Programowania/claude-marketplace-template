# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Claude Code plugin marketplace** — a repository that hosts and distributes Claude Code plugins. It contains no application code; instead it provides plugin scaffolding and a marketplace registry.

## Key Commands

```bash
# Initialize the marketplace (first-time setup, removes itself after running)
./init-marketplace.sh

# Scaffold a new plugin (validates name, creates full directory structure, registers in marketplace.json)
./create-plugin.sh <plugin-name> "Short description"
```

## Architecture

- **`.claude-plugin/marketplace.json`** — Central marketplace registry. `create-plugin.sh` auto-registers new plugins here. Each entry has name, description, version, author, source path, and category.
- **`plugins/<name>/`** — Each plugin follows a standard layout:
  - `.claude-plugin/plugin.json` — Plugin manifest (name, version, author, repo)
  - `agents/` — Agent definition files
  - `skills/` — Skill definition files
  - `commands/` — Command definition files
  - `docs/FEATURES.md` — Feature catalog (agents, skills, commands)
- **`create-plugin.sh`** — Scaffolding script. Plugin names must match `^[a-z][a-z0-9-]*$`. No external dependencies beyond standard Unix tools.
- **`init-marketplace.sh`** — One-time setup script that replaces `__PLACEHOLDER__` tokens with user-provided values. Deletes itself after running.

## Conventions

- Plugin names: lowercase letters, digits, and hyphens only, starting with a letter
- Marketplace name: `__MARKETPLACE_NAME__`; plugins are referenced as `<plugin-name>@__MARKETPLACE_NAME__`
- After creating a plugin, update the root `README.md` "Available Plugins" section
- After adding agents/skills/commands to a plugin, update both the plugin's `README.md` and `docs/FEATURES.md`

## Platform Note

`create-plugin.sh` and `init-marketplace.sh` detect GNU vs BSD `sed` automatically and work on both Linux and macOS.

## Development

- Update README.md with new features, especially sections "Available Plugins" and "Repository Structure"
- Update CLAUDE.md with crucial points of new features

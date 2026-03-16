> **This is a template repository.** To create your own Claude Code plugin marketplace:
>
> 1. Click "Use this template" on GitHub (or clone this repo)
> 2. Run `./init-marketplace.sh`
> 3. Follow the prompts to configure your marketplace
> 4. The script configures all files and removes itself
> 5. Start adding plugins with `./create-plugin.sh`

---

# __MARKETPLACE_DISPLAY_NAME__

__MARKETPLACE_DESCRIPTION__

## Available Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| *None yet* | Run `./create-plugin.sh` to add your first plugin | — |

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and available as `claude`

## Installation

```bash
# Register the marketplace
claude plugin marketplace add https://github.com/__MARKETPLACE_REPO__
```

After installing, run `/plugin` in Claude Code to install plugins located in this marketplace

## Repository Structure

```
.
├── .claude-plugin/
│   └── marketplace.json    # Central marketplace registry
├── plugins/                # All plugins live here
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json # Plugin manifest
│       ├── agents/         # Agent definitions
│       ├── commands/       # Command definitions
│       ├── docs/
│       │   └── FEATURES.md # Feature catalog
│       ├── skills/         # Skill definitions
│       ├── CHANGELOG.md
│       └── README.md
├── create-plugin.sh        # Plugin scaffolding script
├── CLAUDE.md               # Claude Code instructions
└── README.md               # This file
```

## Adding a New Plugin

First, ensure the script is executable:

```bash
chmod +x create-plugin.sh
```

Then run it:

```bash
./create-plugin.sh my-plugin "Short description of the plugin"
```

This scaffolds the full directory structure, boilerplate files, and registers the plugin in `marketplace.json`. After running it, update this `README.md` with the new plugin in the "Available Plugins" table.


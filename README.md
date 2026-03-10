# multigravity-pro

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/Pulkit7070/multigravity-pro)
[![GitHub Profile](https://img.shields.io/badge/GitHub-Profile-blue?logo=github)](https://github.com/Pulkit7070)
![Stars](https://img.shields.io/github/stars/Pulkit7070/multigravity-pro?style=social)

<img src="assets/multigravity-logo.jpg" alt="Multigravity" width="80">

## Multigravity

**Run multiple Antigravity IDE profiles at the same time — each with its own accounts, settings, and extensions.**

No more logging in and out. Just switch profiles instantly or use them all at once.

> Supported OS: macOS, Windows, and Linux.

---

## Install

### macOS / Linux

Open your terminal and paste this:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pulkit7070/multigravity-pro/main/install.sh)"
```

### Windows

Open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/Pulkit7070/multigravity-pro/main/install.ps1 | iex
```

That's it. Multigravity is now installed.

---

## Getting Started

### 1. Create a profile

Give it any name you like — your name, a project, a client, anything:

```bash
multigravity new work
multigravity new personal
```

This also creates a clickable launcher:

- macOS: `~/Applications/Multigravity <name>.app`
- Windows: **Start Menu** shortcut
- Linux: `~/.local/share/applications/multigravity-<name>.desktop`

### 2. Open a profile

```bash
multigravity work
```

Antigravity will open using that profile's isolated settings, accounts, and extensions.

You can also pass normal Antigravity arguments through:

```bash
multigravity work --new-window
multigravity work .
multigravity work path/to/file.py
```

---

## Auth-Only Profiles

Most people just need separate logins, not separate extensions. Auth-only profiles share your existing extensions and settings via symlinks — only the account is isolated.

```bash
multigravity new client-a --auth-only
multigravity new client-b --auth-only
```

|  | Full Profile | Auth-Only |
|---|---|---|
| Extensions | Separate copy | Shared (symlink) |
| Settings | Separate copy | Shared (symlink) |
| Account / Auth | Isolated | Isolated |
| Disk usage | ~500 MB | ~2 MB |

---

## Templates

Set up one perfect environment, reuse it forever.

```bash
# Save your configured profile as a template
multigravity template save work python-dev

# See all templates
multigravity template list

# Create a new profile from it — instant setup
multigravity new new-client --from python-dev

# Remove a template
multigravity template delete python-dev
```

---

## Status

See what's happening across all your profiles:

```bash
multigravity status
```

```
PROFILE          STATUS     TYPE         LAST USED            SIZE
-------          ------     ----         ---------            ----
client-a         running    auth-only    2026-03-10 14:30     2 MB
client-b         stopped    auth-only    2026-03-08 09:15     1 MB
personal         stopped    full         2026-03-09 20:00     487 MB
work             running    full         2026-03-10 14:32     523 MB
```

---

## Export / Import

Move profiles between machines, share with teammates, or back up.

```bash
# Export
multigravity export work ~/Desktop/work.tar.gz     # macOS/Linux
multigravity export work C:\backup\work.zip          # Windows

# Import (auto-detects profile name from the file)
multigravity import work.tar.gz
multigravity import work.zip client-setup            # custom name
```

---

## All Commands

```
multigravity new <name> [--auth-only] [--from <template>]
multigravity <name> [args...]         Launch a profile
multigravity list                     List all profiles
multigravity status                   Show running/stopped, type, last used, size
multigravity clone <src> <dest>       Copy a profile
multigravity rename <old> <new>       Rename a profile
multigravity delete <name>            Delete a profile (with confirmation)
multigravity template save <profile> <name>
multigravity template list
multigravity template delete <name>
multigravity export <name> [path]
multigravity import <archive> [name]
multigravity doctor                   Check environment health
multigravity stats                    Disk usage per profile
multigravity update                   Self-update
multigravity completion               Shell autocompletion setup
multigravity help
```

---

## Profile Name Rules

- Letters, numbers, and hyphens only
- Must start with a letter or number
- Valid: `work`, `client-a`, `test1`
- Invalid: `-name`, `my_profile`, `has spaces`

---

## What's New in Pro

| Feature | Command | What it does |
|---|---|---|
| Auth-only profiles | `new work --auth-only` | Share extensions and settings across profiles, isolate only the login. Near-zero disk usage. |
| Profile templates | `template save work py-dev` | Save a configured profile as a reusable starting point. `new x --from py-dev` to stamp out copies. |
| Status dashboard | `status` | See which profiles are running, their type, last used time, and disk size — at a glance. |
| Export / Import | `export work ./work.zip` | Pack a profile into one portable file. Move between machines, share with teammates, back up. |

Everything from the original [multigravity-cli](https://github.com/sujitagarwal/multigravity-cli) still works — `new`, `list`, `clone`, `rename`, `delete`, `doctor`, `stats`, `update`, `completion`.

---

## Credits

Multigravity Pro is built on top of [multigravity-cli](https://github.com/sujitagarwal/multigravity-cli) by [Sujit Agarwal](https://github.com/sujitagarwal).

- Original project: [sujitagarwal/multigravity-cli](https://github.com/sujitagarwal/multigravity-cli)
- Windows support: [Samin Yeasar](https://github.com/Solez-ai)
- Linux support: [Md Rayyan Nawaz](https://github.com/therayyanawaz)

## License

MIT

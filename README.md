# Multigravity Pro

**Run multiple Antigravity IDE profiles at the same time — each with its own accounts, settings, and extensions.**

No more logging in and out. Just switch profiles instantly or use them all at once.

> Built on top of [multigravity-cli](https://github.com/sujitagarwal/multigravity-cli) by [Sujit Agarwal](https://github.com/sujitagarwal). Original Windows support by [Samin Yeasar](https://github.com/Solez-ai), Linux support by [Md Rayyan Nawaz](https://github.com/therayyanawaz).

> Supported OS: macOS, Windows, and Linux.

---

## What's new in Pro

| Feature | Command | What it does |
|---|---|---|
| Auth-only profiles | `new work --auth-only` | Share extensions & settings across profiles, isolate only the login. Near-zero disk usage. |
| Profile templates | `template save work py-dev` | Save a configured profile as a reusable starting point. `new x --from py-dev` to stamp out copies. |
| Status dashboard | `status` | See which profiles are running, their type, last used time, and disk size — at a glance. |
| Export / Import | `export work ./work.zip` | Pack a profile into one portable file. Move between machines, share with teammates, back up. |

Everything from the original multigravity-cli still works — `new`, `list`, `clone`, `rename`, `delete`, `doctor`, `stats`, `update`, `completion`.

---

## Install

### macOS / Linux

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Pulkit7070/multigravity-pro/main/install.sh)"
```

### Windows

Open **PowerShell** and paste:

```powershell
irm https://raw.githubusercontent.com/Pulkit7070/multigravity-pro/main/install.ps1 | iex
```

---

## Quick Start

### Create a profile

```bash
multigravity new work
multigravity new personal
```

This creates the profile + a clickable launcher (macOS app, Windows Start Menu shortcut, or Linux .desktop file).

### Launch a profile

```bash
multigravity work
```

Antigravity opens with that profile's isolated settings, accounts, and extensions. Pass any Antigravity args through:

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

Full profile = ~500MB each. Auth-only = near zero.

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

## Credits

Multigravity Pro is a fork of [multigravity-cli](https://github.com/sujitagarwal/multigravity-cli) by [Sujit Agarwal](https://github.com/sujitagarwal) with added features for auth-only profiles, templates, status dashboard, and export/import.

- Original project: [sujitagarwal/multigravity-cli](https://github.com/sujitagarwal/multigravity-cli)
- Windows support: [Samin Yeasar](https://github.com/Solez-ai)
- Linux support: [Md Rayyan Nawaz](https://github.com/therayyanawaz)

## License

MIT

[![GitHub repository](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/sujitagarwal/multigravity-cli)
[![GitHub profile](https://img.shields.io/badge/GitHub-Profile-lightgrey?logo=github)](https://github.com/sujitagarwal)
[![GitHub stars](https://img.shields.io/github/stars/sujitagarwal/multigravity-cli?style=social)](https://github.com/sujitagarwal/multigravity-cli/stargazers)

![Multigravity](assets/multigravity-logo.jpg)
# Multigravity


**Run multiple Antigravity IDE profiles at the same time — each with its own accounts, settings, and extensions.**

No more logging in and out. Just switch profiles instantly or use them all at once!

> Note: Suported OS: macOS, Windows and Linux.

---

## Install

### macOS / Linux

Open your terminal and paste this:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sujitagarwal/multigravity-cli/main/install.sh)"
```

### Windows

Open **PowerShell** and paste this:

```powershell
irm https://raw.githubusercontent.com/sujitagarwal/multigravity-cli/main/install.ps1 | iex
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

### 3. See all your profiles

```bash
multigravity list
```

### 4. Clone a profile

Duplicate an existing setup to a new profile:

```bash
multigravity clone work work-copy
```

---

## Power User Features

### Shell Autocompletion

Enable tab-completion for commands and profile names:

```bash
multigravity completion
```

Follow the instructions shown to add the setup to your shell profile (`.zshrc`, `.bashrc`, or PowerShell `$PROFILE`).

### Self-Update

Keep multigravity up to date with one command:

```bash
multigravity update
```

### System Diagnosis

Check if your environment is set up correctly:

```bash
multigravity doctor
```

### Storage Stats

See how much space your profiles are taking up:

```bash
multigravity stats
```

---

## Other Commands

### Rename a profile

```bash
multigravity rename work freelance
```

### Delete a profile

```bash
multigravity delete personal
```

You'll be asked to confirm before anything is deleted.

### Get help

```bash
multigravity help
```

---

## Profile Name Rules

- Letters, numbers, and hyphens only
- Must start with a letter or number
- ✅ `work`, `client-a`, `test1`
- ❌ `-name`, `my_profile`

---

## App Shortcuts

Every profile automatically gets a clickable launcher so you can open profiles directly without using the terminal:

- **macOS**: App bundle in `~/Applications`
- **Windows**: Shortcut in **Start Menu > Programs**
- **Linux**: Desktop entry in `~/.local/share/applications`

---

## Credits

- **Windows support** contributed by [Samin Yeasar](https://github.com/Solez-ai).
- **Linux support** contributed by [Md Rayyan Nawaz](https://github.com/therayyanawaz).

---

## Links

- [Repository](https://github.com/sujitagarwal/multigravity-cli)
- [Profile](https://github.com/sujitagarwal)
- [Star the Repository](https://github.com/sujitagarwal/multigravity-cli/stargazers)

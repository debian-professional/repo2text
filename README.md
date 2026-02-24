# repo2text

> **Export any GitHub repository as a single text file — purpose-built for LLM context windows.**

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)
[![Platform: Linux | macOS | Windows](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#)

---

## The Problem

Working with AI assistants like ChatGPT, Claude, or local LLMs requires giving the model full context about your codebase. But how do you pass an entire repository into a chat window cleanly, reliably, and without noise?

Copy-pasting individual files is tedious. Zipping the repo is unreadable. There was no simple, professional solution — until now.

## The Solution

`repo2text` clones any GitHub repository and exports all its text-based files into **one clean, structured output file** — ready to paste into any AI assistant, use in automated pipelines, or archive for documentation purposes.

Available for **all major platforms**:

| Platform | Script | Requirements |
|----------|--------|-------------|
| Linux / macOS | `repo2text.sh` | Bash, git, jq, pv, zip |
| Windows | `repo2text.ps1` | PowerShell 5.1+, git |

No installation. No exotic frameworks. Just run it.

---

## Features

- **Cross-platform** — Native Bash script for Linux/macOS, native PowerShell script for Windows
- **Multiple output formats** — Export as plain text (`.txt`), JSON, or Markdown
- **Intelligent file detection** — Multi-stage check ensures only real text files are included
- **Automatic ZIP archive** — Every export automatically produces a compressed `.zip` alongside the text file
- **SSH → HTTPS conversion** — Works seamlessly with both SSH and HTTPS remote URLs
- **Smart Git integration** — Auto-detects the remote URL when run inside an existing Git repository
- **Git status warning** — Warns you if there are uncommitted or unpushed changes before exporting
- **Selective export** — Export only a specific subdirectory
- **Flat mode** — Strip directory paths from filenames for a simplified output
- **MD5 checksums** — Optionally compute and include an MD5 hash for every exported file
- **Configurable exclusions** — Easily extend the list of ignored file extensions
- **Progress display** — Visual progress output for large repositories
- **Clean output** — Cloned repositories are automatically deleted after export

---

## Linux / macOS

### Requirements

| Tool | Purpose | Install (Debian/Ubuntu) |
|------|---------|------------------------|
| `git` | Cloning repositories | `apt install git` |
| `file` | MIME type detection | pre-installed |
| `grep` | Binary file detection | pre-installed |
| `jq` | JSON output format | `apt install jq` |
| `pv` | Progress display | `apt install pv` |
| `zip` | Archive creation | `apt install zip` |
| `md5sum` | Checksum generation (optional) | pre-installed |

### Installation

```bash
# Clone the repository
git clone https://github.com/debian-professional/repo2text.git

# Make the script executable
chmod +x repo2text/repo2text.sh

# Optional: make it globally available
sudo cp repo2text/repo2text.sh /usr/local/bin/repo2text
```

### Usage

```bash
./repo2text.sh [OPTIONS] [GitHub-Repository-URL]
```

If no URL is provided, the script prompts for one interactively. When run inside a Git repository, the current remote URL is detected and suggested automatically.

### Options

| Option | Description |
|--------|-------------|
| `-f, --format FORMAT` | Output format: `txt` (default), `json`, `md` / `markdown` |
| `--flat` | Use filenames only, without directory paths |
| `-o, --only PATH` | Export only the specified subdirectory (relative to repository root) |
| `-md5, --md5` | Compute and include an MD5 checksum for each file |
| `-h, --help` | Display help information |

### Examples

```bash
# Basic export — interactive URL prompt
./repo2text.sh

# Export a specific repository as plain text
./repo2text.sh https://github.com/debian-professional/repo2text.git

# Export as Markdown — ideal for AI assistants
./repo2text.sh -f md https://github.com/your-username/your-repo.git

# Export as JSON — ideal for automated pipelines
./repo2text.sh -f json https://github.com/your-username/your-repo.git

# Export only a specific subdirectory
./repo2text.sh -o src https://github.com/your-username/your-repo.git

# Export with flat filenames (no directory structure)
./repo2text.sh --flat https://github.com/your-username/your-repo.git

# Export with MD5 checksums for integrity verification
./repo2text.sh -md5 https://github.com/your-username/your-repo.git

# Combine options — Markdown export of a subdirectory with checksums
./repo2text.sh -f md -o lib -md5 https://github.com/your-username/your-repo.git

# Auto-detect URL when run inside a Git repository
cd ~/projects/my-repo
./repo2text.sh -f md
# The script automatically detects and suggests the current remote URL
```

### How File Detection Works (Linux/macOS)

`repo2text.sh` uses a three-stage verification process:

1. **MIME type check** — `file --mime-type` must return a `text/*` type
2. **Extension exclusion** — Files with extensions like `lock`, `log`, `tmp`, `bak`, `swp`, `cache` are skipped
3. **Binary safety check** — `grep -Iq` confirms the file contains no binary data

---

## Windows (PowerShell)

### Requirements

- **PowerShell 5.1 or higher** — pre-installed on Windows 10 and Windows 11
- **Git for Windows** — download from [git-scm.com](https://git-scm.com/download/win)

No additional tools required. Everything else uses built-in .NET functionality.

### First-Time Setup

Windows restricts the execution of PowerShell scripts by default. The following two steps are required **once** before first use.

**Step 1 — Allow script execution:**

Open PowerShell and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Confirm with `Y` when prompted.

**Step 2 — Unblock the downloaded script:**

Because the script was downloaded from the internet, Windows marks it as potentially unsafe. Unblock it with:

```powershell
Unblock-File .\repo2text.ps1
```

These two steps are only required once per machine.

### Installation

```powershell
# Clone the repository
git clone https://github.com/debian-professional/repo2text.git

# Navigate into the directory
cd repo2text

# Unblock the script (required once after download)
Unblock-File .\repo2text.ps1
```

### Usage

```powershell
.\repo2text.ps1 [OPTIONS] [GitHub-Repository-URL]
```

If no URL is provided, the script prompts for one interactively. When run inside a Git repository, the current remote URL is detected and suggested automatically — just press Enter to confirm.

### Options

| Option | Description |
|--------|-------------|
| `-Format` | Output format: `txt` (default), `json`, `md` / `markdown` |
| `-Flat` | Use filenames only, without directory paths |
| `-Only PATH` | Export only the specified subdirectory (relative to repository root) |
| `-Md5` | Compute and include an MD5 checksum for each file |

### Examples

```powershell
# Basic export — interactive URL prompt
.\repo2text.ps1

# Export a specific repository as plain text
.\repo2text.ps1 https://github.com/debian-professional/repo2text.git

# Export as Markdown — ideal for AI assistants
.\repo2text.ps1 -Format md https://github.com/your-username/your-repo.git

# Export as JSON — ideal for automated pipelines
.\repo2text.ps1 -Format json https://github.com/your-username/your-repo.git

# Export only a specific subdirectory
.\repo2text.ps1 -Only src https://github.com/your-username/your-repo.git

# Export with flat filenames (no directory structure)
.\repo2text.ps1 -Flat https://github.com/your-username/your-repo.git

# Export with MD5 checksums for integrity verification
.\repo2text.ps1 -Md5 https://github.com/your-username/your-repo.git

# Combine options — Markdown export of a subdirectory with checksums
.\repo2text.ps1 -Format md -Only lib -Md5 https://github.com/your-username/your-repo.git

# Auto-detect URL when run inside a Git repository
cd C:\projects\my-repo
.\repo2text.ps1 -Format md
# The script automatically detects and suggests the current remote URL
```

### How File Detection Works (Windows/PowerShell)

`repo2text.ps1` uses a three-stage verification process adapted for Windows:

1. **Extension exclusion** — Files with extensions like `lock`, `log`, `tmp`, `bak`, `exe`, `dll`, `bin` are skipped
2. **Null-byte check** — The first 8192 bytes are scanned for null bytes, which reliably identifies binary files
3. **UTF-8 read test** — The file is opened as UTF-8 text; if it fails, the file is excluded

This approach achieves the same reliability as the Linux MIME-type check without requiring any additional tools.

---

## Output Format Examples

### Plain Text (`.txt`)
```
=========================================================================
Repository Export | Files: 12
Date: 2026-02-24 10:00:00 | URL: https://github.com/user/repo
=========================================================================

FILE: src/main.py
---------------------------------------------------------
# content of main.py
...

FILE: README.md
---------------------------------------------------------
# content of README.md
...
```

### Markdown (`.md`)
```markdown
# Repo Export

- **URL:** https://github.com/user/repo
- **Files:** 12
- **Date:** 2026-02-24 10:00:00

---

## `src/main.py`
```python
# content of main.py
```
```

### JSON (`.json`)
```json
{
  "metadata": {
    "url": "https://github.com/user/repo",
    "date": "2026-02-24 10:00:00",
    "file_count": 12
  },
  "files": [
    {
      "path": "src/main.py",
      "content": "# content of main.py\n..."
    }
  ]
}
```

---

## Use Cases

### 1. AI-Assisted Code Review
Export your repository and paste the output directly into ChatGPT, Claude, or any LLM. The model receives the full codebase as a single, structured input — no file switching, no fragmented context.

```bash
# Linux/macOS
repo2text -f md https://github.com/your-username/your-repo.git
```
```powershell
# Windows
.\repo2text.ps1 -Format md https://github.com/your-username/your-repo.git
```

### 2. Feeding Context to Local LLMs
When working with local models via Ollama, LM Studio, or similar tools, context window management is critical. Export only the relevant subdirectory to stay within token limits.

```bash
repo2text -o backend/api -f txt https://github.com/your-username/your-repo.git
```

### 3. Automated Documentation Pipelines
Integrate `repo2text` into CI/CD workflows to generate up-to-date codebase snapshots as part of your documentation process.

```bash
repo2text.sh -f json https://github.com/org/project.git
```

### 4. Code Archiving and Snapshots
Create a human-readable, single-file snapshot of any repository at any point in time — ideal for audits, handovers, or long-term archiving.

```bash
repo2text -md5 https://github.com/your-username/your-repo.git
# MD5 checksums allow you to verify file integrity later
```

### 5. Cross-Repository Analysis
Export multiple repositories and compare their structure and content without switching between directories.

```bash
repo2text https://github.com/org/service-a.git
repo2text https://github.com/org/service-b.git
# Both exports are now plain text files — diff them, grep them, feed them to AI
```

### 6. Security Audits
Export a repository and run automated or AI-assisted security reviews against the complete, unfiltered text.

```bash
repo2text -f txt https://github.com/vendor/library.git
grep -i "api_key\|password\|secret" repo_export_*.txt
```

### 7. Onboarding New Team Members
Generate a structured Markdown export of a codebase and share it with new developers as a reading-friendly overview of the entire project.

```bash
repo2text -f md https://github.com/org/main-product.git
```

---

## Self-Referential Demo

This script was used to export its own repository and provide the full codebase context to an AI assistant during development. The file you are reading now is a direct result of that workflow.

```bash
# Linux/macOS
./repo2text.sh -f md https://github.com/debian-professional/repo2text.git
```
```powershell
# Windows
.\repo2text.ps1 -Format md https://github.com/debian-professional/repo2text.git
```

---

## Contributing

Contributions, bug reports, and feature requests are welcome. Please open an issue or submit a pull request.

---

## License

This project is licensed under the **GNU General Public License v2.0**. See the [LICENSE](LICENSE) file for details.

---

## Author

Developed by **[debian-professional](https://github.com/debian-professional)**  
A tool born out of real-world AI-assisted development workflows.

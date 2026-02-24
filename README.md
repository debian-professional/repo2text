# repo2text

> **Export any GitHub repository as a single text file — purpose-built for LLM context windows.**

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)](https://kernel.org/)

---

## The Problem

Working with AI assistants like ChatGPT, Claude, or local LLMs requires giving the model full context about your codebase. But how do you pass an entire repository into a chat window cleanly, reliably, and without noise?

Copy-pasting individual files is tedious. Zipping the repo is unreadable. There was no simple, professional solution — until now.

## The Solution

`repo2text.sh` is a single Bash script that clones any GitHub repository and exports all its text-based files into **one clean, structured output file** — ready to paste into any AI assistant, use in automated pipelines, or archive for documentation purposes.

No installation. No dependencies beyond standard Linux tools. Just run it.

---

## Features

- **Multiple output formats** — Export as plain text (`.txt`), JSON, or Markdown
- **Intelligent file detection** — Three-stage check: MIME type, file extension, and binary detection ensure only real text files are included
- **Automatic ZIP archive** — Every export automatically produces a compressed `.zip` alongside the text file
- **SSH → HTTPS conversion** — Works seamlessly with both SSH and HTTPS remote URLs
- **Smart Git integration** — Auto-detects the remote URL when run inside an existing Git repository
- **Git status warning** — Warns you if there are uncommitted or unpushed changes before exporting
- **Selective export** — Export only a specific subdirectory with `--only`
- **Flat mode** — Strip directory paths from filenames for a simplified output
- **MD5 checksums** — Optionally compute and include an MD5 hash for every exported file
- **Configurable exclusions** — Easily extend the list of ignored file extensions (`lock`, `log`, `tmp`, `bak`, etc.)
- **Progress display** — Visual progress output via `pv` for large repositories
- **Clean output** — Cloned repositories are automatically deleted after export

---

## Requirements

The following tools must be available on your system:

| Tool | Purpose | Install (Debian/Ubuntu) |
|------|---------|------------------------|
| `git` | Cloning repositories | `apt install git` |
| `file` | MIME type detection | pre-installed |
| `grep` | Binary file detection | pre-installed |
| `jq` | JSON output format | `apt install jq` |
| `pv` | Progress display | `apt install pv` |
| `zip` | Archive creation | `apt install zip` |
| `md5sum` | Checksum generation (optional) | pre-installed |

---

## Installation

```bash
# Clone the repository
git clone https://github.com/debian-professional/repo2text.git

# Make the script executable
chmod +x repo2text/repo2text.sh

# Optional: make it globally available
sudo cp repo2text/repo2text.sh /usr/local/bin/repo2text
```

---

## Usage

```bash
./repo2text.sh [OPTIONS] [GitHub-Repository-URL]
```

If no URL is provided, the script prompts for one interactively. When run inside a Git repository, the current remote URL is suggested automatically.

### Options

| Option | Description |
|--------|-------------|
| `-f, --format FORMAT` | Output format: `txt` (default), `json`, `md` / `markdown` |
| `--flat` | Use filenames only, without directory paths |
| `-o, --only PATH` | Export only the specified subdirectory (relative to repository root) |
| `-md5, --md5` | Compute and include an MD5 checksum for each file |
| `-h, --help` | Display help information |

---

## Examples

### Basic export (interactive URL prompt)
```bash
./repo2text.sh
```

### Export a specific repository as plain text
```bash
./repo2text.sh https://github.com/debian-professional/repo2text.git
```

### Export as Markdown — ideal for AI assistants
```bash
./repo2text.sh -f md https://github.com/your-username/your-repo.git
```

### Export as JSON — ideal for automated pipelines
```bash
./repo2text.sh -f json https://github.com/your-username/your-repo.git
```

### Export only a specific subdirectory
```bash
./repo2text.sh -o src https://github.com/your-username/your-repo.git
```

### Export with flat filenames (no directory structure)
```bash
./repo2text.sh --flat https://github.com/your-username/your-repo.git
```

### Export with MD5 checksums for integrity verification
```bash
./repo2text.sh -md5 https://github.com/your-username/your-repo.git
```

### Combine options — Markdown export of a subdirectory with checksums
```bash
./repo2text.sh -f md -o lib -md5 https://github.com/your-username/your-repo.git
```

### Auto-detect URL (run inside a Git repository)
```bash
cd ~/projects/my-repo
repo2text -f md
# The script automatically suggests the current repository's remote URL
```

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
# Repository Export
**Files:** 12 | **Date:** 2026-02-24 | **URL:** https://github.com/user/repo

---

## `src/main.py`
```python
# content of main.py
```
```

### JSON (`.json`)
```json
{
  "meta": {
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
repo2text -f md https://github.com/your-username/your-repo.git
# Open the .md file, copy its contents, paste into your AI assistant
```

### 2. Feeding Context to Local LLMs
When working with local models via Ollama, LM Studio, or similar tools, context window management is critical. Export only the relevant subdirectory to stay within token limits:

```bash
repo2text -o backend/api -f txt https://github.com/your-username/your-repo.git
```

### 3. Automated Documentation Pipelines
Integrate `repo2text` into CI/CD workflows to generate up-to-date codebase snapshots as part of your documentation process.

```bash
# In a CI pipeline
repo2text.sh -f json https://github.com/org/project.git
# Process the JSON output with your documentation tool
```

### 4. Code Archiving and Snapshots
Create a human-readable, single-file snapshot of any repository at any point in time — ideal for audits, handovers, or long-term archiving.

```bash
repo2text -md5 https://github.com/your-username/your-repo.git
# The MD5 checksums allow you to verify file integrity later
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

## How File Detection Works

`repo2text.sh` uses a three-stage verification process to ensure only genuine text files are included in the export:

1. **MIME type check** — `file --mime-type` must return a `text/*` type
2. **Extension exclusion** — Files with extensions like `lock`, `log`, `tmp`, `bak`, `swp`, `cache` are skipped
3. **Binary safety check** — `grep -Iq` confirms the file contains no binary data

This prevents garbage output from accidentally included binaries, compiled files, or cached data — even if their extensions look like text files.

---

## Self-Referential Demo

This script was used to export its own repository and provide the full codebase context to an AI assistant during development. The file you are reading now is a direct result of that workflow.

```bash
./repo2text.sh -f md https://github.com/debian-professional/repo2text.git
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

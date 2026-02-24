# repo2text

> **Exportiert jedes GitHub-Repository als einzelne Textdatei — entwickelt für LLM-Kontextfenster.**

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![PowerShell: 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://microsoft.com/powershell)
[![Platform: Linux | macOS | Windows](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey.svg)](#)

---

## Das Problem

Wer mit KI-Assistenten wie ChatGPT, Claude oder lokalen LLMs arbeitet, muss dem Modell vollständigen Kontext über die eigene Codebasis geben. Doch wie übergibt man ein gesamtes Repository sauber, zuverlässig und ohne Rauschen in ein Chatfenster?

Einzelne Dateien manuell kopieren ist mühsam. Das Repository als ZIP weiterzugeben ist für KI-Modelle unlesbar. Eine einfache, professionelle Lösung fehlte — bis jetzt.

## Die Lösung

`repo2text` klont jedes GitHub-Repository und exportiert alle textbasierten Dateien in **eine einzige, strukturierte Ausgabedatei** — bereit zum Einfügen in jeden KI-Assistenten, zur Nutzung in automatisierten Pipelines oder zur Archivierung als Dokumentation.

Verfügbar für **alle gängigen Plattformen**:

| Plattform | Skript | Voraussetzungen |
|-----------|--------|-----------------|
| Linux / macOS | `repo2text.sh` | Bash, git, jq, pv, zip |
| Windows | `repo2text.ps1` | PowerShell 5.1+, git |

Keine Installation. Keine exotischen Frameworks. Einfach ausführen.

---

## Features

- **Plattformübergreifend** — Natives Bash-Skript für Linux/macOS, natives PowerShell-Skript für Windows
- **Mehrere Ausgabeformate** — Export als Klartext (`.txt`), JSON oder Markdown
- **Intelligente Dateierkennung** — Mehrstufige Prüfung stellt sicher, dass nur echte Textdateien exportiert werden
- **Automatisches ZIP-Archiv** — Jeder Export erzeugt zusätzlich eine komprimierte `.zip`-Datei
- **SSH → HTTPS-Konvertierung** — Funktioniert nahtlos mit SSH- und HTTPS-Remote-URLs
- **Smarte Git-Integration** — Erkennt die Remote-URL automatisch, wenn das Skript innerhalb eines Git-Repositories ausgeführt wird
- **Git-Status-Warnung** — Warnt vor dem Export, wenn uncommittete oder nicht gepushte Änderungen vorhanden sind
- **Selektiver Export** — Nur ein bestimmtes Unterverzeichnis exportieren
- **Flat-Modus** — Verzeichnispfade aus Dateinamen entfernen für eine vereinfachte Ausgabe
- **MD5-Prüfsummen** — Optional wird für jede exportierte Datei ein MD5-Hash berechnet und ausgegeben
- **Konfigurierbare Ausschlüsse** — Liste ignorierter Dateiendungen leicht erweiterbar
- **Fortschrittsanzeige** — Visuelle Fortschrittsausgabe bei großen Repositories
- **Saubere Ausgabe** — Geklonte Repositories werden nach dem Export automatisch gelöscht

---

## Linux / macOS

### Voraussetzungen

| Werkzeug | Zweck | Installation (Debian/Ubuntu) |
|----------|-------|------------------------------|
| `git` | Repository klonen | `apt install git` |
| `file` | MIME-Typ-Erkennung | vorinstalliert |
| `grep` | Binärdatei-Erkennung | vorinstalliert |
| `jq` | JSON-Ausgabeformat | `apt install jq` |
| `pv` | Fortschrittsanzeige | `apt install pv` |
| `zip` | Archiv-Erstellung | `apt install zip` |
| `md5sum` | Prüfsummen (optional) | vorinstalliert |

### Installation

```bash
# Repository klonen
git clone https://github.com/debian-professional/repo2text.git

# Skript ausführbar machen
chmod +x repo2text/repo2text.sh

# Optional: global verfügbar machen
sudo cp repo2text/repo2text.sh /usr/local/bin/repo2text
```

### Verwendung

```bash
./repo2text.sh [OPTIONEN] [GitHub-Repository-URL]
```

Wird keine URL angegeben, fragt das Skript interaktiv nach. Wird es innerhalb eines Git-Repositories ausgeführt, wird die aktuelle Remote-URL automatisch erkannt und als Vorschlag angeboten.

### Optionen

| Option | Beschreibung |
|--------|-------------|
| `-f, --format FORMAT` | Ausgabeformat: `txt` (Standard), `json`, `md` / `markdown` |
| `--flat` | Nur Dateinamen ohne Verzeichnispfade verwenden |
| `-o, --only PATH` | Nur das angegebene Unterverzeichnis exportieren (relativ zum Repository-Stamm) |
| `-md5, --md5` | MD5-Prüfsumme für jede Datei berechnen und ausgeben |
| `-h, --help` | Hilfe anzeigen |

### Beispiele

```bash
# Einfacher Export — interaktive URL-Abfrage
./repo2text.sh

# Export eines bestimmten Repositories als Klartext
./repo2text.sh https://github.com/debian-professional/repo2text.git

# Export als Markdown — ideal für KI-Assistenten
./repo2text.sh -f md https://github.com/ihr-benutzername/ihr-repo.git

# Export als JSON — ideal für automatisierte Pipelines
./repo2text.sh -f json https://github.com/ihr-benutzername/ihr-repo.git

# Nur ein bestimmtes Unterverzeichnis exportieren
./repo2text.sh -o src https://github.com/ihr-benutzername/ihr-repo.git

# Flat-Modus — ohne Verzeichnisstruktur
./repo2text.sh --flat https://github.com/ihr-benutzername/ihr-repo.git

# Export mit MD5-Prüfsummen zur Integritätsprüfung
./repo2text.sh -md5 https://github.com/ihr-benutzername/ihr-repo.git

# Optionen kombinieren — Markdown-Export eines Unterverzeichnisses mit Prüfsummen
./repo2text.sh -f md -o lib -md5 https://github.com/ihr-benutzername/ihr-repo.git

# Automatische URL-Erkennung innerhalb eines Git-Repositories
cd ~/projekte/mein-repo
./repo2text.sh -f md
# Das Skript erkennt die Remote-URL automatisch und schlägt sie vor
```

### Wie die Dateierkennung funktioniert (Linux/macOS)

`repo2text.sh` verwendet einen dreistufigen Verifizierungsprozess:

1. **MIME-Typ-Prüfung** — `file --mime-type` muss einen `text/*`-Typ zurückgeben
2. **Endungs-Ausschluss** — Dateien mit Endungen wie `lock`, `log`, `tmp`, `bak`, `swp`, `cache` werden übersprungen
3. **Binär-Sicherheitscheck** — `grep -Iq` bestätigt, dass die Datei keine Binärdaten enthält

---

## Windows (PowerShell)

### Voraussetzungen

- **PowerShell 5.1 oder höher** — auf Windows 10 und Windows 11 vorinstalliert
- **Git for Windows** — herunterladen von [git-scm.com](https://git-scm.com/download/win)

Keine weiteren Werkzeuge erforderlich. Alles weitere nutzt eingebaute .NET-Funktionalität.

### Ersteinrichtung

Windows schränkt die Ausführung von PowerShell-Skripten standardmäßig ein. Die folgenden zwei Schritte sind **einmalig** vor der ersten Verwendung erforderlich.

**Schritt 1 — Skriptausführung erlauben:**

PowerShell öffnen und folgenden Befehl ausführen:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Mit `J` bestätigen wenn Windows nachfragt.

**Schritt 2 — Heruntergeladenes Skript entsperren:**

Da das Skript aus dem Internet heruntergeladen wurde, markiert Windows es als potenziell unsicher. Entsperren mit:

```powershell
Unblock-File .\repo2text.ps1
```

Diese beiden Schritte sind pro Computer nur einmal erforderlich.

### Installation

```powershell
# Repository klonen
git clone https://github.com/debian-professional/repo2text.git

# In das Verzeichnis wechseln
cd repo2text

# Skript entsperren (einmalig nach dem Download erforderlich)
Unblock-File .\repo2text.ps1
```

### Verwendung

```powershell
.\repo2text.ps1 [OPTIONEN] [GitHub-Repository-URL]
```

Wird keine URL angegeben, fragt das Skript interaktiv nach. Wird es innerhalb eines Git-Repositories ausgeführt, wird die aktuelle Remote-URL automatisch erkannt — einfach Enter drücken zum Bestätigen.

### Optionen

| Option | Beschreibung |
|--------|-------------|
| `-Format` | Ausgabeformat: `txt` (Standard), `json`, `md` / `markdown` |
| `-Flat` | Nur Dateinamen ohne Verzeichnispfade verwenden |
| `-Only PATH` | Nur das angegebene Unterverzeichnis exportieren (relativ zum Repository-Stamm) |
| `-Md5` | MD5-Prüfsumme für jede Datei berechnen und ausgeben |

### Beispiele

```powershell
# Einfacher Export — interaktive URL-Abfrage
.\repo2text.ps1

# Export eines bestimmten Repositories als Klartext
.\repo2text.ps1 https://github.com/debian-professional/repo2text.git

# Export als Markdown — ideal für KI-Assistenten
.\repo2text.ps1 -Format md https://github.com/ihr-benutzername/ihr-repo.git

# Export als JSON — ideal für automatisierte Pipelines
.\repo2text.ps1 -Format json https://github.com/ihr-benutzername/ihr-repo.git

# Nur ein bestimmtes Unterverzeichnis exportieren
.\repo2text.ps1 -Only src https://github.com/ihr-benutzername/ihr-repo.git

# Flat-Modus — ohne Verzeichnisstruktur
.\repo2text.ps1 -Flat https://github.com/ihr-benutzername/ihr-repo.git

# Export mit MD5-Prüfsummen zur Integritätsprüfung
.\repo2text.ps1 -Md5 https://github.com/ihr-benutzername/ihr-repo.git

# Optionen kombinieren — Markdown-Export eines Unterverzeichnisses mit Prüfsummen
.\repo2text.ps1 -Format md -Only lib -Md5 https://github.com/ihr-benutzername/ihr-repo.git

# Automatische URL-Erkennung innerhalb eines Git-Repositories
cd C:\projekte\mein-repo
.\repo2text.ps1 -Format md
# Das Skript erkennt die Remote-URL automatisch und schlägt sie vor
```

### Wie die Dateierkennung funktioniert (Windows/PowerShell)

`repo2text.ps1` verwendet einen dreistufigen Verifizierungsprozess, angepasst für Windows:

1. **Endungs-Ausschluss** — Dateien mit Endungen wie `lock`, `log`, `tmp`, `bak`, `exe`, `dll`, `bin` werden übersprungen
2. **Null-Byte-Check** — Die ersten 8192 Bytes werden auf Null-Bytes geprüft, was Binärdateien zuverlässig erkennt
3. **UTF-8-Lesetest** — Die Datei wird als UTF-8-Text geöffnet; schlägt das fehl, wird die Datei ausgeschlossen

Dieser Ansatz erreicht die gleiche Zuverlässigkeit wie der Linux-MIME-Typ-Check — ohne zusätzliche Werkzeuge zu benötigen.

---

## Ausgabeformat-Beispiele

### Klartext (`.txt`)
```
=========================================================================
Repository Export | Files: 12
Date: 2026-02-24 10:00:00 | URL: https://github.com/user/repo
=========================================================================

FILE: src/main.py
---------------------------------------------------------
# Inhalt von main.py
...

FILE: README.md
---------------------------------------------------------
# Inhalt von README.md
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
# Inhalt von main.py
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
      "content": "# Inhalt von main.py\n..."
    }
  ]
}
```

---

## Anwendungsfälle

### 1. KI-gestützte Code-Reviews
Repository exportieren und die Ausgabe direkt in ChatGPT, Claude oder ein beliebiges LLM einfügen. Das Modell erhält die vollständige Codebasis als einzelne, strukturierte Eingabe — kein Dateiwechsel, kein fragmentierter Kontext.

```bash
# Linux/macOS
repo2text -f md https://github.com/ihr-benutzername/ihr-repo.git
```
```powershell
# Windows
.\repo2text.ps1 -Format md https://github.com/ihr-benutzername/ihr-repo.git
```

### 2. Kontext für lokale LLMs
Beim Arbeiten mit lokalen Modellen über Ollama, LM Studio oder ähnliche Werkzeuge ist das Kontextfenster-Management entscheidend. Nur das relevante Unterverzeichnis exportieren, um innerhalb der Token-Grenzen zu bleiben.

```bash
repo2text -o backend/api -f txt https://github.com/ihr-benutzername/ihr-repo.git
```

### 3. Automatisierte Dokumentations-Pipelines
`repo2text` in CI/CD-Workflows integrieren, um aktuelle Codebasis-Snapshots als Teil des Dokumentationsprozesses zu erzeugen.

```bash
repo2text.sh -f json https://github.com/org/projekt.git
```

### 4. Code-Archivierung und Snapshots
Einen menschenlesbaren Einzel-Datei-Snapshot eines beliebigen Repositories zu jedem Zeitpunkt erstellen — ideal für Audits, Übergaben oder Langzeitarchivierung.

```bash
repo2text -md5 https://github.com/ihr-benutzername/ihr-repo.git
# Die MD5-Prüfsummen ermöglichen spätere Integritätsprüfungen
```

### 5. Repository-übergreifende Analyse
Mehrere Repositories exportieren und ihre Struktur sowie ihren Inhalt vergleichen, ohne zwischen Verzeichnissen zu wechseln.

```bash
repo2text https://github.com/org/service-a.git
repo2text https://github.com/org/service-b.git
# Beide Exporte sind nun Klartextdateien — diff, grep oder KI-Analyse
```

### 6. Sicherheits-Audits
Ein Repository exportieren und automatisierte oder KI-gestützte Sicherheitsprüfungen gegen den vollständigen, ungefilterten Text durchführen.

```bash
repo2text -f txt https://github.com/vendor/bibliothek.git
grep -i "api_key\|password\|secret" repo_export_*.txt
```

### 7. Onboarding neuer Teammitglieder
Einen strukturierten Markdown-Export einer Codebasis erstellen und neuen Entwicklern als lesbaren Überblick über das gesamte Projekt zur Verfügung stellen.

```bash
repo2text -f md https://github.com/org/hauptprodukt.git
```

---

## Selbstreferenzieller Demo

Dieses Skript wurde verwendet, um sein eigenes Repository zu exportieren und der KI während der Entwicklung vollständigen Codebasis-Kontext bereitzustellen. Die Datei, die Sie gerade lesen, ist ein direktes Ergebnis dieses Workflows.

```bash
# Linux/macOS
./repo2text.sh -f md https://github.com/debian-professional/repo2text.git
```
```powershell
# Windows
.\repo2text.ps1 -Format md https://github.com/debian-professional/repo2text.git
```

---

## Mitwirken

Beiträge, Fehlerberichte und Feature-Anfragen sind willkommen. Bitte ein Issue eröffnen oder einen Pull Request einreichen.

---

## Lizenz

Dieses Projekt steht unter der **GNU General Public License v2.0**. Details in der [LICENSE](LICENSE)-Datei.

---

## Autor

Entwickelt von **[debian-professional](https://github.com/debian-professional)**  
Ein Werkzeug, entstanden aus realen KI-gestützten Entwicklungs-Workflows.

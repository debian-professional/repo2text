#!/bin/bash

# === Konfiguration ===
OUTPUT_FILE_PREFIX="repo_export"

# Liste der Dateiendungen, die ignoriert werden sollen (Regex-Format)
# Hier kannst du einfach weitere hinzufügen, z.B. |lock|tmp|bak
EXCLUDE_EXTENSIONS="lock|log|tmp|bak|swp|cache"

# === Funktion: Zeige Hilfe an ===
show_help() {
    echo "Verwendung: $0 [OPTIONEN] [GitHub-Repository-URL]"
    echo ""
    echo "Beschreibung:"
    echo "  Klont ein GitHub-Repository, extrahiert den Text aller Textdateien"
    echo "  und schreibt sie mit deutlichen Trennern in eine Ausgabedatei."
    echo "  Unterstützte Formate: txt (Standard), json, md (Markdown)."
    echo "  Anschließend wird zusätzlich ein ZIP-Archiv dieser Datei erstellt."
    echo "  Das neu erzeugte Repository wird nach der Extraktion automatisch gelöscht."
    echo ""
    echo "Optionen:"
    echo "  -f, --format FORMAT   Ausgabeformat: txt, json, md (oder markdown)"
    echo "  --flat                Nur Dateinamen ohne Pfad verwenden (flat)"
    echo "  -o, --only PATH       Nur den angegebenen Pfad (relativ zum Repository-Stamm) exportieren"
    echo "  -md5, --md5           Für jede Datei eine MD5-Prüfsumme berechnen und ausgeben"
    echo "  -h, --help            Diese Hilfe anzeigen"
    echo ""
    echo "Argumente:"
    echo "  [GitHub-Repository-URL]  Optional: Die HTTPS- oder SSH-URL des Repos."
    echo "                            Wenn keine URL angegeben wird, erfolgt eine interaktive Eingabe."
    echo "                            Wird das Skript innerhalb eines Git-Repos ausgeführt,"
    echo "                            wird automatisch die Remote-URL als Vorschlag verwendet."
}

# === Funktion: Lese Remote-URL des aktuellen Git-Repos ===
get_git_remote_url() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        return 
    fi
    local remote=$(git remote | head -n1)
    [ -z "$remote" ] && echo "" && return
    echo "$(git config --get "remote.$remote.url")"
}

# === Funktion: Prüfe Git-Status ===
check_git_cleanliness() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then return 0; fi
    local dirty=0
    local unpushed=0
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if ! git diff --quiet || ! git diff --cached --quiet; then dirty=1; fi
    if [ -n "$branch" ]; then
        local remote=$(git config "branch.$branch.remote" 2>/dev/null)
        local merge=$(git config "branch.$branch.merge" 2>/dev/null)
        if [ -n "$remote" ] && [ -n "$merge" ]; then
            local upstream="${remote}/${merge#refs/heads/}"
            unpushed=$(git rev-list --count "$upstream..$branch" 2>/dev/null || echo 0)
        fi
    fi
    if [ $dirty -eq 1 ] || [ "$unpushed" -gt 0 ]; then
        echo -e "\nWARNUNG: Das aktuelle Git-Repository ist nicht sauber."
        read -p "Trotzdem fortfahren? (j/N): " confirm
        [[ ! "$confirm" =~ ^[jJ]$ ]] && echo "Abbruch." && exit 1
    fi
}

# === Funktion: SSH zu HTTPS ===
convert_ssh_to_https() {
    local url="$1"
    if [[ "$url" =~ ^git@([^:]+):(.+)$ ]]; then
        echo "https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo "$url"
    fi
}

# === Funktion: Textdatei-Prüfung ===
is_text_file() {
    local file="$1"
    # 1. MIME-Check
    if ! file -b --mime-type "$file" | grep -q "^text/"; then return 1; fi
    # 2. Ausschluss über Endungen (Regex gegen Dateiname)
    if [[ "$file" =~ \.($EXCLUDE_EXTENSIONS)$ ]]; then return 1; fi
    # 3. Binär-Check
    if ! grep -Iq . "$file" 2>/dev/null; then return 1; fi
    return 0
}

# ============================================
# Ausgabefunktionen (angepasst für optionale MD5)
# ============================================

write_txt_header() {
    cat > "$1" <<EOF
=========================================================================
Repository Export | Dateien: $2
Datum: $(date '+%Y-%m-%d %H:%M:%S') | URL: $REPO_URL
=========================================================================

EOF
}

write_txt_file() {
    local out="$1"
    local disp="$2"
    local file="$3"
    local md5="${4:-}"
    if [ -n "$md5" ]; then
        { echo "FILE: $disp (MD5: $md5)"; echo "---------------------------------------------------------"; cat "$file"; echo -e "\n\n"; } >> "$out"
    else
        { echo "FILE: $disp"; echo "---------------------------------------------------------"; cat "$file"; echo -e "\n\n"; } >> "$out"
    fi
}

write_md_header() {
    { echo "# Repo Export"; echo -e "\n- **URL:** $REPO_URL\n- **Dateien:** $2\n\n---\n"; } >> "$1"
}

write_md_file() {
    local out="$1"
    local disp="$2"
    local file="$3"
    local md5="${4:-}"
    local lang="${disp##*.}"
    if [ -n "$md5" ]; then
        { echo "## \`$disp\` (MD5: $md5)"; echo -e "\n\`\`\`$lang"; cat "$file"; echo -e "\n\`\`\`\n"; } >> "$out"
    else
        { echo "## \`$disp\`"; echo -e "\n\`\`\`$lang"; cat "$file"; echo -e "\n\`\`\`\n"; } >> "$out"
    fi
}

write_json_final() {
    jq -n --arg date "$(date)" --arg url "$REPO_URL" --argjson count "$3" --slurpfile files "$1" \
    '{metadata: {date: $date, url: $url, file_count: $count}, files: $files}' > "$2"
}

# ============================================
# Hauptprogramm
# ============================================

# Optionen initialisieren
OUTPUT_FORMAT="txt"
REPO_URL=""
flat=false
ONLY_PATH=""
INCLUDE_MD5=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--format) OUTPUT_FORMAT="$2"; shift 2 ;;
        --flat) flat=true; shift ;;
        -o|--only) ONLY_PATH="$2"; shift 2 ;;
        -md5|--md5) INCLUDE_MD5=true; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) REPO_URL="$1"; shift ;;
    esac
done

[[ ! "$OUTPUT_FORMAT" =~ ^(txt|json|md)$ ]] && echo "Format-Fehler" && exit 1

# Abhängigkeiten prüfen (jetzt mit Kenntnis der MD5-Option)
MISSING_PKGS=()
for pkg in git file zip jq pv; do
    command -v "$pkg" &>/dev/null || MISSING_PKGS+=("$pkg")
done
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "Fehler: Pakete fehlen: ${MISSING_PKGS[*]}"; exit 1
fi

# MD5-Befehl festlegen, falls gewünscht
if $INCLUDE_MD5; then
    if command -v md5sum &>/dev/null; then
        compute_md5() { md5sum "$1" | cut -d' ' -f1; }
    elif command -v md5 &>/dev/null; then
        compute_md5() { md5 -q "$1"; }
    else
        echo "Fehler: Für MD5 wird md5sum oder md5 benötigt." >&2
        exit 1
    fi
fi

# Repository-URL ermitteln
if [[ -z "$REPO_URL" ]]; then
    check_git_cleanliness
    DEFAULT_URL=$(get_git_remote_url)
    read -p "Repository-URL [${DEFAULT_URL}]: " input_url
    REPO_URL=${input_url:-$DEFAULT_URL}
fi

[ -z "$REPO_URL" ] && exit 1

REPO_URL=$(convert_ssh_to_https "$REPO_URL")
REPO_NAME=$(basename "$REPO_URL" .git)
TEMP_DIR="temp_repo_$(date +%s)"

echo "Klone $REPO_URL ..."
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &>/dev/null || exit 1

cd "$TEMP_DIR" && COMMIT_HASH=$(git rev-parse HEAD) && BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD) && cd ..

# Prüfe, ob ein Teilbaum angegeben wurde
START_DIR="$TEMP_DIR"
if [ -n "$ONLY_PATH" ]; then
    START_DIR="$TEMP_DIR/$ONLY_PATH"
    if [ ! -d "$START_DIR" ]; then
        echo "Fehler: Der angegebene Pfad '$ONLY_PATH' existiert nicht im Repository." >&2
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

OUTPUT_FILE="${OUTPUT_FILE_PREFIX}_${REPO_NAME}_$(date +%Y%m%d_%H%M%S).${OUTPUT_FORMAT}"
file_count=0

echo "Analysiere..."
total_files=$(find "$START_DIR" -type f \( -path "$TEMP_DIR/.gitignore" -o -path "$TEMP_DIR/.gitattributes" -o -not -path '*/.*' \) | wc -l)

echo "Extrahiere..."
while IFS= read -r -d '' full_path; do
    rel_path="${full_path#$TEMP_DIR/}"

    display_path="$rel_path"
    if $flat; then
        display_path=$(basename "$rel_path")
    fi

    if is_text_file "$full_path"; then
        # MD5 berechnen falls gewünscht
        md5_sum=""
        if $INCLUDE_MD5; then
            md5_sum=$(compute_md5 "$full_path")
        fi

        case "$OUTPUT_FORMAT" in
            txt) write_txt_file "$OUTPUT_FILE" "$display_path" "$full_path" "$md5_sum" ;;
            md)  write_md_file  "$OUTPUT_FILE" "$display_path" "$full_path" "$md5_sum" ;;
            json)
                if [ -n "$md5_sum" ]; then
                    jq -n --arg p "$display_path" --arg c "$(cat "$full_path")" --arg m "$md5_sum" '{path: $p, content: $c, md5: $m}' >> "json.tmp"
                else
                    jq -n --arg p "$display_path" --arg c "$(cat "$full_path")" '{path: $p, content: $c}' >> "json.tmp"
                fi
                ;;
        esac
        ((file_count++))
    fi
done < <(find "$START_DIR" -type f \( -path "$TEMP_DIR/.gitignore" -o -path "$TEMP_DIR/.gitattributes" -o -not -path '*/.*' \) -print0 | pv -0 -p -t -e -r -s "$total_files" -l)

# Nachbereitung je nach Format
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    write_json_final "json.tmp" "$OUTPUT_FILE" "$file_count" && rm "json.tmp"
else
    TEMP_H="h.tmp"
    [[ "$OUTPUT_FORMAT" == "txt" ]] && write_txt_header "$TEMP_H" "$file_count" || write_md_header "$TEMP_H" "$file_count"
    cat "$OUTPUT_FILE" >> "$TEMP_H" && mv "$TEMP_H" "$OUTPUT_FILE"
fi

zip -q "${OUTPUT_FILE}.zip" "$OUTPUT_FILE"
rm -rf "$TEMP_DIR"

echo "==============================================="
echo "Fertig! $file_count Dateien extrahiert."
if [ -n "$ONLY_PATH" ]; then
    echo "Exportierter Pfad: $ONLY_PATH"
fi
if $INCLUDE_MD5; then
    echo "MD5-Prüfsummen wurden berechnet."
fi
echo "Output: $(pwd)/$OUTPUT_FILE"
echo "==============================================="


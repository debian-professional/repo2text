#!/bin/bash

# === Configuration ===
OUTPUT_FILE_PREFIX="repo_export"

# List of file extensions to ignore (regex format)
# Add more extensions here as needed, e.g. |lock|tmp|bak
EXCLUDE_EXTENSIONS="lock|log|tmp|bak|swp|cache"

# === Function: Show help ===
show_help() {
    echo "Usage: $0 [OPTIONS] [GitHub-Repository-URL]"
    echo ""
    echo "Description:"
    echo "  Clones a GitHub repository, extracts the text of all text-based files"
    echo "  and writes them with clear separators into a single output file."
    echo "  Supported formats: txt (default), json, md (Markdown)."
    echo "  A ZIP archive of the output file is created automatically."
    echo "  The cloned repository is deleted after extraction."
    echo ""
    echo "Options:"
    echo "  -f, --format FORMAT   Output format: txt, json, md (or markdown)"
    echo "  --flat                Use filenames only, without directory paths"
    echo "  -o, --only PATH       Export only the specified path (relative to repository root)"
    echo "  -md5, --md5           Compute and include an MD5 checksum for each file"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Arguments:"
    echo "  [GitHub-Repository-URL]  Optional: The HTTPS or SSH URL of the repository."
    echo "                            If no URL is provided, the script prompts interactively."
    echo "                            When run inside a Git repository,"
    echo "                            the current remote URL is suggested automatically."
}

# === Function: Read remote URL of current Git repository ===
get_git_remote_url() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        return
    fi
    local remote=$(git remote | head -n1)
    [ -z "$remote" ] && echo "" && return
    echo "$(git config --get "remote.$remote.url")"
}

# === Function: Check Git status ===
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
        echo -e "\nWARNING: The current Git repository is not clean."
        read -p "Continue anyway? (y/N): " confirm
        [[ ! "$confirm" =~ ^[yY]$ ]] && echo "Aborted." && exit 1
    fi
}

# === Function: Convert SSH to HTTPS ===
convert_ssh_to_https() {
    local url="$1"
    if [[ "$url" =~ ^git@([^:]+):(.+)$ ]]; then
        echo "https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    else
        echo "$url"
    fi
}

# === Function: Check if file is a text file ===
is_text_file() {
    local file="$1"
    # 1. MIME type check
    if ! file -b --mime-type "$file" | grep -q "^text/"; then return 1; fi
    # 2. Extension exclusion (regex against filename)
    if [[ "$file" =~ \.($EXCLUDE_EXTENSIONS)$ ]]; then return 1; fi
    # 3. Binary check
    if ! grep -Iq . "$file" 2>/dev/null; then return 1; fi
    return 0
}

# ============================================
# Output functions
# ============================================

write_txt_header() {
    cat > "$1" <<EOF
=========================================================================
Repository Export | Files: $2
Date: $(date '+%Y-%m-%d %H:%M:%S') | URL: $REPO_URL
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
    { echo "# Repo Export"; echo -e "\n- **URL:** $REPO_URL\n- **Files:** $2\n\n---\n"; } >> "$1"
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
# Main program
# ============================================

# Initialize options
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

[[ ! "$OUTPUT_FORMAT" =~ ^(txt|json|md)$ ]] && echo "ERROR: Invalid format. Use txt, json or md." && exit 1

# Check dependencies
MISSING_PKGS=()
for pkg in git file zip jq pv; do
    command -v "$pkg" &>/dev/null || MISSING_PKGS+=("$pkg")
done
if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
    echo "ERROR: Missing required packages: ${MISSING_PKGS[*]}"; exit 1
fi

# Set MD5 command if requested
if $INCLUDE_MD5; then
    if command -v md5sum &>/dev/null; then
        compute_md5() { md5sum "$1" | cut -d' ' -f1; }
    elif command -v md5 &>/dev/null; then
        compute_md5() { md5 -q "$1"; }
    else
        echo "ERROR: MD5 computation requires md5sum or md5." >&2
        exit 1
    fi
fi

# Determine repository URL
if [[ -z "$REPO_URL" ]]; then
    check_git_cleanliness
    DEFAULT_URL=$(get_git_remote_url)
    if [ -n "$DEFAULT_URL" ]; then
        echo "Detected repository: $DEFAULT_URL"
        read -p "Repository URL [Enter to confirm]: " input_url
        REPO_URL=${input_url:-$DEFAULT_URL}
    else
        read -p "Repository URL: " input_url
        REPO_URL="$input_url"
    fi
fi

[ -z "$REPO_URL" ] && echo "ERROR: No repository URL provided." && exit 1

REPO_URL=$(convert_ssh_to_https "$REPO_URL")
REPO_NAME=$(basename "$REPO_URL" .git)
TEMP_DIR="temp_repo_$(date +%s)"

echo "Cloning $REPO_URL ..."
git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &>/dev/null || { echo "ERROR: Failed to clone repository."; exit 1; }

cd "$TEMP_DIR" && COMMIT_HASH=$(git rev-parse HEAD) && BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD) && cd ..

# Check if a subdirectory was specified
START_DIR="$TEMP_DIR"
if [ -n "$ONLY_PATH" ]; then
    START_DIR="$TEMP_DIR/$ONLY_PATH"
    if [ ! -d "$START_DIR" ]; then
        echo "ERROR: The specified path '$ONLY_PATH' does not exist in the repository." >&2
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

OUTPUT_FILE="${OUTPUT_FILE_PREFIX}_${REPO_NAME}_$(date +%Y%m%d_%H%M%S).${OUTPUT_FORMAT}"
file_count=0

echo "Analysing..."
total_files=$(find "$START_DIR" -type f \( -path "$TEMP_DIR/.gitignore" -o -path "$TEMP_DIR/.gitattributes" -o -not -path '*/.*' \) | wc -l)

echo "Extracting..."
while IFS= read -r -d '' full_path; do
    rel_path="${full_path#$TEMP_DIR/}"

    display_path="$rel_path"
    if $flat; then
        display_path=$(basename "$rel_path")
    fi

    if is_text_file "$full_path"; then
        # Compute MD5 if requested
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

# Post-processing
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
echo "Done! $file_count files extracted."
if [ -n "$ONLY_PATH" ]; then
    echo "Exported path: $ONLY_PATH"
fi
if $INCLUDE_MD5; then
    echo "MD5 checksums included."
fi
echo "Output: $(pwd)/$OUTPUT_FILE"
echo "ZIP:    $(pwd)/${OUTPUT_FILE}.zip"
echo "==============================================="


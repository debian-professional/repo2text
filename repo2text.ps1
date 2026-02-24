#Requires -Version 5.1
<#
.SYNOPSIS
    repo2text.ps1 - Exports any GitHub repository as a single text file.

.DESCRIPTION
    Clones a GitHub repository, extracts the content of all text-based files
    and writes them with clear separators into a single output file.
    Supported formats: txt (default), json, md (Markdown).
    A ZIP archive of the output file is created automatically.
    The cloned repository is deleted after extraction.

.PARAMETER RepoUrl
    Optional: The HTTPS or SSH URL of the GitHub repository.
    If not provided, the script will prompt for input interactively.
    When run inside a Git repository, the current remote URL is suggested automatically.

.PARAMETER Format
    Output format: txt (default), json, md

.PARAMETER Flat
    Use filenames only, without directory paths.

.PARAMETER Only
    Export only the specified subdirectory (relative to repository root).

.PARAMETER Md5
    Compute and include an MD5 checksum for each file.

.EXAMPLE
    .\repo2text.ps1

.EXAMPLE
    .\repo2text.ps1 -Format md https://github.com/debian-professional/repo2text.git

.EXAMPLE
    .\repo2text.ps1 -Only src -Format txt https://github.com/your-user/your-repo.git

.EXAMPLE
    .\repo2text.ps1 -Md5 -Format json https://github.com/your-user/your-repo.git

.NOTES
    Requirements: Git must be installed and available in PATH.
    Author: debian-professional | https://github.com/debian-professional/repo2text
    License: GNU General Public License v2.0
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$RepoUrl = "",

    [Parameter()]
    [ValidateSet("txt", "json", "md", "markdown")]
    [string]$Format = "txt",

    [Parameter()]
    [switch]$Flat,

    [Parameter()]
    [string]$Only = "",

    [Parameter()]
    [switch]$Md5
)

# ============================================
# Configuration
# ============================================

$OUTPUT_FILE_PREFIX = "repo_export"
$EXCLUDE_EXTENSIONS = @("lock", "log", "tmp", "bak", "swp", "cache", "exe", "dll", "bin", "obj", "class", "pyc")

# Normalize "markdown" to "md"
if ($Format -eq "markdown") { $Format = "md" }

# ============================================
# Helper Functions
# ============================================

function Get-GitRemoteUrl {
    try {
        $null = git rev-parse --git-dir 2>&1
        if ($LASTEXITCODE -ne 0) { return "" }
        $remote = git remote 2>/dev/null | Select-Object -First 1
        if (-not $remote) { return "" }
        return (git config --get "remote.$remote.url" 2>/dev/null)
    } catch {
        return ""
    }
}

function Test-GitCleanliness {
    try {
        $null = git rev-parse --git-dir 2>&1
        if ($LASTEXITCODE -ne 0) { return }

        $dirty = $false
        $unpushed = 0

        git diff --quiet 2>/dev/null
        if ($LASTEXITCODE -ne 0) { $dirty = $true }

        git diff --cached --quiet 2>/dev/null
        if ($LASTEXITCODE -ne 0) { $dirty = $true }

        $branch = git symbolic-ref --short HEAD 2>/dev/null
        if ($branch) {
            $upstream = git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null
            if ($upstream) {
                $unpushed = [int](git rev-list --count "$upstream..HEAD" 2>/dev/null)
            }
        }

        if ($dirty -or $unpushed -gt 0) {
            Write-Host ""
            Write-Warning "The current Git repository is not clean."
            $confirm = Read-Host "Continue anyway? (y/N)"
            if ($confirm -notmatch "^[yY]$") {
                Write-Host "Aborted."
                exit 1
            }
        }
    } catch {
        # Not inside a Git repo — no problem
    }
}

function Convert-SshToHttps {
    param([string]$Url)
    if ($Url -match "^git@([^:]+):(.+)$") {
        return "https://$($Matches[1])/$($Matches[2])"
    }
    return $Url
}

function Test-IsTextFile {
    param([string]$FilePath)

    # 1. Extension exclusion
    $ext = [System.IO.Path]::GetExtension($FilePath).TrimStart(".").ToLower()
    if ($EXCLUDE_EXTENSIONS -contains $ext) { return $false }

    # 2. Binary check — read first 8192 bytes and look for null bytes
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath) | Select-Object -First 8192
        foreach ($byte in $bytes) {
            if ($byte -eq 0) { return $false }
        }
    } catch {
        return $false
    }

    # 3. Try reading as UTF-8 text
    try {
        $null = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
        return $true
    } catch {
        return $false
    }
}

function Get-Md5Hash {
    param([string]$FilePath)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $stream = [System.IO.File]::OpenRead($FilePath)
    $hash = $md5.ComputeHash($stream)
    $stream.Close()
    return ([BitConverter]::ToString($hash) -replace "-", "").ToLower()
}

# ============================================
# Output Writers
# ============================================

function Write-TxtHeader {
    param([string]$OutputFile, [int]$FileCount, [string]$RepoUrl)
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $header = @"
=========================================================================
Repository Export | Files: $FileCount
Date: $date | URL: $RepoUrl
=========================================================================

"@
    [System.IO.File]::WriteAllText($OutputFile, $header, [System.Text.Encoding]::UTF8)
}

function Write-TxtFile {
    param([string]$OutputFile, [string]$DisplayPath, [string]$FilePath, [string]$Md5Sum = "")
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    $separator = "---------------------------------------------------------"
    if ($Md5Sum) {
        $block = "FILE: $DisplayPath (MD5: $Md5Sum)`n$separator`n$content`n`n`n"
    } else {
        $block = "FILE: $DisplayPath`n$separator`n$content`n`n`n"
    }
    [System.IO.File]::AppendAllText($OutputFile, $block, [System.Text.Encoding]::UTF8)
}

function Write-MdHeader {
    param([string]$OutputFile, [int]$FileCount, [string]$RepoUrl)
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $header = "# Repo Export`n`n- **URL:** $RepoUrl`n- **Files:** $FileCount`n- **Date:** $date`n`n---`n`n"
    [System.IO.File]::WriteAllText($OutputFile, $header, [System.Text.Encoding]::UTF8)
}

function Write-MdFile {
    param([string]$OutputFile, [string]$DisplayPath, [string]$FilePath, [string]$Md5Sum = "")
    $content = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
    $ext = [System.IO.Path]::GetExtension($DisplayPath).TrimStart(".")
    if ($Md5Sum) {
        $block = "## ``$DisplayPath`` (MD5: $Md5Sum)`n`n``````$ext`n$content`n```````n`n"
    } else {
        $block = "## ``$DisplayPath```n`n``````$ext`n$content`n```````n`n"
    }
    [System.IO.File]::AppendAllText($OutputFile, $block, [System.Text.Encoding]::UTF8)
}

# ============================================
# Main Program
# ============================================

# Check Git availability
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "ERROR: Git is not installed or not available in PATH."
    exit 1
}

# Determine repository URL
if (-not $RepoUrl) {
    Test-GitCleanliness
    $defaultUrl = Get-GitRemoteUrl
    if ($defaultUrl) {
        $inputUrl = Read-Host "Repository URL [$defaultUrl]"
        $RepoUrl = if ($inputUrl) { $inputUrl } else { $defaultUrl }
    } else {
        $RepoUrl = Read-Host "Repository URL"
    }
}

if (-not $RepoUrl) {
    Write-Error "ERROR: No repository URL provided."
    exit 1
}

# Convert SSH to HTTPS if needed
$RepoUrl = Convert-SshToHttps -Url $RepoUrl

# Derive repository name
$repoName = [System.IO.Path]::GetFileNameWithoutExtension(($RepoUrl -split "/" | Select-Object -Last 1))
$tempDir = "temp_repo_$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

# Clone repository
Write-Host "Cloning $RepoUrl ..."
git clone --depth 1 $RepoUrl $tempDir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: Failed to clone repository."
    exit 1
}

# Determine start directory
$startDir = $tempDir
if ($Only) {
    $startDir = Join-Path $tempDir $Only
    if (-not (Test-Path $startDir -PathType Container)) {
        Write-Error "ERROR: The specified path '$Only' does not exist in the repository."
        Remove-Item -Recurse -Force $tempDir
        exit 1
    }
}

# Prepare output file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFile = "${OUTPUT_FILE_PREFIX}_${repoName}_${timestamp}.${Format}"

# Collect all files
Write-Host "Analysing..."
$allFiles = Get-ChildItem -Path $startDir -Recurse -File |
    Where-Object {
        $_.FullName -notmatch [regex]::Escape((Join-Path $tempDir ".git")) -and
        $_.DirectoryName -notmatch "[\\/]\."
    }

$totalFiles = $allFiles.Count
$fileCount = 0
$processedCount = 0

Write-Host "Extracting..."

# JSON accumulator
$jsonFiles = [System.Collections.Generic.List[object]]::new()

foreach ($file in $allFiles) {
    $processedCount++

    # Progress bar
    $percent = [math]::Round(($processedCount / $totalFiles) * 100)
    Write-Progress -Activity "Extracting files" `
                   -Status "$processedCount / $totalFiles" `
                   -PercentComplete $percent

    $relPath = $file.FullName.Substring((Resolve-Path $tempDir).Path.Length + 1)
    $displayPath = if ($Flat) { $file.Name } else { $relPath }

    if (Test-IsTextFile -FilePath $file.FullName) {
        $md5Sum = ""
        if ($Md5) {
            $md5Sum = Get-Md5Hash -FilePath $file.FullName
        }

        switch ($Format) {
            "txt" { Write-TxtFile -OutputFile $outputFile -DisplayPath $displayPath -FilePath $file.FullName -Md5Sum $md5Sum }
            "md"  { Write-MdFile  -OutputFile $outputFile -DisplayPath $displayPath -FilePath $file.FullName -Md5Sum $md5Sum }
            "json" {
                $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
                $entry = [PSCustomObject]@{ path = $displayPath; content = $content }
                if ($md5Sum) { $entry | Add-Member -NotePropertyName "md5" -NotePropertyValue $md5Sum }
                $jsonFiles.Add($entry)
            }
        }
        $fileCount++
    }
}

Write-Progress -Activity "Extracting files" -Completed

# Post-processing
switch ($Format) {
    "json" {
        $jsonOutput = [PSCustomObject]@{
            metadata = [PSCustomObject]@{
                date       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                url        = $RepoUrl
                file_count = $fileCount
            }
            files = $jsonFiles
        }
        $jsonOutput | ConvertTo-Json -Depth 10 | 
            [System.IO.File]::WriteAllText((Resolve-Path ".").Path + "\$outputFile", $_, [System.Text.Encoding]::UTF8)
    }
    "txt" {
        # Prepend header
        $bodyContent = if (Test-Path $outputFile) { [System.IO.File]::ReadAllText($outputFile, [System.Text.Encoding]::UTF8) } else { "" }
        Write-TxtHeader -OutputFile $outputFile -FileCount $fileCount -RepoUrl $RepoUrl
        [System.IO.File]::AppendAllText($outputFile, $bodyContent, [System.Text.Encoding]::UTF8)
    }
    "md" {
        $bodyContent = if (Test-Path $outputFile) { [System.IO.File]::ReadAllText($outputFile, [System.Text.Encoding]::UTF8) } else { "" }
        Write-MdHeader -OutputFile $outputFile -FileCount $fileCount -RepoUrl $RepoUrl
        [System.IO.File]::AppendAllText($outputFile, $bodyContent, [System.Text.Encoding]::UTF8)
    }
}

# Create ZIP archive
$zipFile = "$outputFile.zip"
Compress-Archive -Path $outputFile -DestinationPath $zipFile -Force

# Cleanup
Remove-Item -Recurse -Force $tempDir

# Summary
Write-Host ""
Write-Host "==============================================="
Write-Host "Done! $fileCount files extracted."
if ($Only) { Write-Host "Exported path: $Only" }
if ($Md5)  { Write-Host "MD5 checksums included." }
Write-Host "Output: $(Resolve-Path $outputFile)"
Write-Host "ZIP:    $(Resolve-Path $zipFile)"
Write-Host "==============================================="

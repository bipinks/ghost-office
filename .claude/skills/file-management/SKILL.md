---
name: file-management
description: Use when organizing files, bulk renaming, finding duplicates, cleaning disk space, managing permissions, or performing any local filesystem operations safely.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "mcp__filesystem__list_directory", "mcp__filesystem__list_directory_with_sizes", "mcp__filesystem__directory_tree", "mcp__filesystem__get_file_info", "mcp__filesystem__move_file", "mcp__filesystem__create_directory", "mcp__filesystem__search_files"]
---

# File Management

## Organize Files by Type

Sort files from a flat directory into categorized subdirectories:

```bash
#!/bin/bash
# Organize files by extension into subdirectories
SOURCE_DIR="${1:-.}"

declare -A TYPE_MAP=(
  # Documents
  ["pdf"]="Documents" ["doc"]="Documents" ["docx"]="Documents"
  ["xls"]="Documents" ["xlsx"]="Documents" ["ppt"]="Documents"
  ["pptx"]="Documents" ["txt"]="Documents" ["csv"]="Documents"
  ["md"]="Documents" ["rtf"]="Documents"
  # Images
  ["jpg"]="Images" ["jpeg"]="Images" ["png"]="Images"
  ["gif"]="Images" ["svg"]="Images" ["webp"]="Images"
  ["bmp"]="Images" ["ico"]="Images" ["heic"]="Images"
  # Videos
  ["mp4"]="Videos" ["mkv"]="Videos" ["avi"]="Videos"
  ["mov"]="Videos" ["wmv"]="Videos" ["flv"]="Videos"
  # Audio
  ["mp3"]="Audio" ["wav"]="Audio" ["flac"]="Audio"
  ["aac"]="Audio" ["ogg"]="Audio" ["m4a"]="Audio"
  # Archives
  ["zip"]="Archives" ["tar"]="Archives" ["gz"]="Archives"
  ["rar"]="Archives" ["7z"]="Archives" ["bz2"]="Archives"
  # Code
  ["js"]="Code" ["ts"]="Code" ["py"]="Code" ["rb"]="Code"
  ["go"]="Code" ["rs"]="Code" ["java"]="Code" ["c"]="Code"
  ["cpp"]="Code" ["h"]="Code" ["sh"]="Code" ["php"]="Code"
)

for file in "$SOURCE_DIR"/*; do
  [ -f "$file" ] || continue
  ext="${file##*.}"
  ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
  dest="${TYPE_MAP[$ext]:-Other}"
  mkdir -p "$SOURCE_DIR/$dest"
  mv "$file" "$SOURCE_DIR/$dest/"
done
```

## Organize Files by Date

Move files into YYYY/MM directories based on modification date:

```bash
#!/bin/bash
SOURCE_DIR="${1:-.}"

for file in "$SOURCE_DIR"/*; do
  [ -f "$file" ] || continue
  # Get modification date
  if [[ "$(uname)" == "Darwin" ]]; then
    mod_date=$(stat -f "%Sm" -t "%Y/%m" "$file")
  else
    mod_date=$(date -r "$file" "+%Y/%m")
  fi
  mkdir -p "$SOURCE_DIR/$mod_date"
  mv "$file" "$SOURCE_DIR/$mod_date/"
done
```

## Bulk Rename Patterns

### Sequential numbering
```bash
# Rename files with sequential numbers: photo_001.jpg, photo_002.jpg, ...
DIR="${1:-.}"
PREFIX="${2:-file}"
counter=1
for file in "$DIR"/*; do
  [ -f "$file" ] || continue
  ext="${file##*.}"
  printf -v num "%03d" $counter
  mv "$file" "$DIR/${PREFIX}_${num}.${ext}"
  ((counter++))
done
```

### Replace spaces and special characters
```bash
# Replace spaces with underscores and lowercase filenames
for file in *; do
  [ -f "$file" ] || continue
  newname=$(echo "$file" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/_/g')
  [ "$file" != "$newname" ] && mv "$file" "$newname"
done
```

### Date prefix from metadata
```bash
# Prefix files with their modification date: 2024-01-15_filename.ext
for file in *; do
  [ -f "$file" ] || continue
  if [[ "$(uname)" == "Darwin" ]]; then
    date_prefix=$(stat -f "%Sm" -t "%Y-%m-%d" "$file")
  else
    date_prefix=$(date -r "$file" "+%Y-%m-%d")
  fi
  mv "$file" "${date_prefix}_${file}"
done
```

## Find Duplicate Files

### By content hash (most accurate)
```bash
# Find duplicate files by MD5 hash
find "${1:-.}" -type f -exec md5 -r {} + 2>/dev/null | \
  sort | awk '{print $1, $2}' | \
  uniq -d -w 32 | \
  while read hash file; do
    echo "DUPLICATE (hash: $hash): $file"
  done

# Cross-platform version using sha256
find "${1:-.}" -type f -print0 | xargs -0 shasum -a 256 | \
  sort | uniq -d -w 64
```

### By name and size (fast scan)
```bash
# Quick duplicate scan by filename
find "${1:-.}" -type f | awk -F/ '{print $NF}' | sort | uniq -d | while read name; do
  echo "--- Duplicate name: $name ---"
  find "${1:-.}" -type f -name "$name" -exec ls -lh {} \;
done
```

## Disk Space Cleanup

### Find largest files
```bash
# Top 20 largest files in a directory
find "${1:-.}" -type f -exec du -h {} + 2>/dev/null | sort -rh | head -20
```

### Find old files (not accessed in N days)
```bash
# Files not modified in 90 days
find "${1:-.}" -type f -mtime +90 -exec ls -lh {} \; | sort -k5 -rh
```

### Find empty directories
```bash
# List empty directories
find "${1:-.}" -type d -empty
# Remove empty directories (with confirmation)
find "${1:-.}" -type d -empty -print  # preview first
# find "${1:-.}" -type d -empty -delete  # uncomment to delete
```

### Find common space wasters
```bash
# node_modules directories and their sizes
find "${1:-.}" -name "node_modules" -type d -prune -exec du -sh {} \;

# .DS_Store files (macOS)
find "${1:-.}" -name ".DS_Store" -type f

# Temporary files
find "${1:-.}" -type f \( -name "*.tmp" -o -name "*.temp" -o -name "*.swp" -o -name "*~" -o -name "*.bak" \)

# Log files over 100MB
find "${1:-.}" -name "*.log" -type f -size +100M -exec ls -lh {} \;
```

## Directory Structure Planning

### Create a project directory tree
```bash
# Create a standard project structure
PROJECT="${1:-my-project}"
mkdir -p "$PROJECT"/{src,docs,tests,config,scripts,data/{raw,processed},logs,backups}
```

### Mirror a directory structure (without files)
```bash
# Copy directory tree structure only
SOURCE="${1}"
DEST="${2}"
cd "$SOURCE" && find . -type d -exec mkdir -p "$DEST/{}" \;
```

## File Permission Audit

### Find world-writable files
```bash
find "${1:-.}" -type f -perm -o=w -exec ls -la {} \;
```

### Find files with no owner
```bash
find "${1:-.}" -nouser -o -nogroup 2>/dev/null
```

### Fix common permission issues
```bash
# Set standard permissions: 755 for dirs, 644 for files
find "${1:-.}" -type d -exec chmod 755 {} \;
find "${1:-.}" -type f -exec chmod 644 {} \;
# Make scripts executable
find "${1:-.}" -type f -name "*.sh" -exec chmod 755 {} \;
```

## File Comparison

### Diff two directories
```bash
# Compare directory contents (files present/missing)
diff <(cd "$DIR1" && find . -type f | sort) <(cd "$DIR2" && find . -type f | sort)

# Compare with content differences
diff -rq "$DIR1" "$DIR2"
```

## Safe Operation Patterns

### Dry-run wrapper
Always preview before executing. Use this pattern:
```bash
DRY_RUN=true  # set to false after user confirms

for file in "$SOURCE_DIR"/*; do
  [ -f "$file" ] || continue
  dest="$TARGET_DIR/$(basename "$file")"
  if $DRY_RUN; then
    echo "[DRY RUN] Would move: $file -> $dest"
  else
    mv "$file" "$dest"
    echo "Moved: $file -> $dest"
  fi
done
```

### Backup before bulk operations
```bash
BACKUP_DIR="/tmp/file-ops-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
# Copy originals before modifying
cp -a "$SOURCE_DIR"/* "$BACKUP_DIR/"
echo "Backup created at: $BACKUP_DIR"
```

## Best Practices
1. **Always dry-run first** — preview every bulk operation before executing
2. **Backup before destructive ops** — copy files before renaming/moving/deleting
3. **Use absolute paths** — avoid ambiguity with relative paths in scripts
4. **Handle spaces in filenames** — quote variables, use `find -print0 | xargs -0`
5. **Check before overwrite** — use `mv -n` (no-clobber) to prevent accidental overwrites
6. **Log operations** — redirect output to a log file for audit trail
7. **Test on a small subset** — run on 5-10 files before applying to thousands
8. **Avoid system directories** — never bulk-operate on `/usr`, `/bin`, `/etc`, `/System`

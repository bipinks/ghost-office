---
name: file-manage
description: Organize, search, clean up, rename, or manage files on the local filesystem
argument-hint: "[operation and target, e.g. 'organize ~/Downloads by type']"
---

# /file-manage — File Management

Perform file operations for $ARGUMENTS using the **file-manager** agent with the **file-management** skill:

1. Survey target files and directories
2. Present a dry-run preview of proposed changes
3. Confirm before executing any modifications
4. Execute and report results

## Usage
```
/file-manage "organize ~/Downloads by file type"
/file-manage "find duplicate files in ~/Documents"
/file-manage "clean up files older than 90 days in ~/logs"
/file-manage "bulk rename photos in ~/Pictures with date prefix"
/file-manage "find the 20 largest files on my system"
/file-manage "remove all .DS_Store files from ~/Projects"
/file-manage "fix permissions in ~/scripts to make .sh files executable"
```

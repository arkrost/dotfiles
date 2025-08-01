---
allowed-tools: [Bash, Read, Glob, TodoWrite, Edit]
description: "Git commit with intelligent message"
---

## Purpose
Execute Git commit with intelligent message

## Execution
Follow this workflow:

1. **Check git status**: Run `git status --porcelain` to see what files are staged
2. **Auto-stage if needed**: If no files are staged, automatically stage all modified and new files
3. **Analyze changes**: Run `git diff --cached` to understand what changes are being committed
4. **Extract context**:
   - Analyze the diff to determine the nature of changes
   - Determine if multiple distinct logical changes are present
5. **Generate commit message**: Create a commit message following the format below
6. **Execute commit**: Run `git commit` with the generated message

## Important notes
- If specific files are already staged, the command will only commit those files
- If no files are staged, it will automatically stage all modified and new files
- The commit message will be constructed based on the changes detected
- NEVER add coauthored text to commit message

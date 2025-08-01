---
allowed-tools: [Bash, Read, Glob, TodoWrite, Edit]
description: "Git commit with intelligent message"
---

## Execution
1. **Check staging area**: Run `git status --porcelain` and interpret output
2. **Auto-stage changes** if nothing is staged for commit
2. **Analyze changes**: Run `git diff --cached` to understand what will be committed
3. **Extract context**:
   - Analyze the diff to determine the nature of changes
   - Determine if multiple distinct logical changes are present
3. **Generate message**: Create commit message:
   - Based on change analysis
   - Concise summary focusing on what and why
   - Maintain Git best practices and conventions
4. **Commit**: Execute `git commit` with generated message (no coauthored text)

## Claude Code Integration
- Uses Bash for Git command execution
- Leverages Read for repository analysis
- Applies TodoWrite for operation tracking

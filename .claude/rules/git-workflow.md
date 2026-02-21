# Git Workflow Guidelines

This file defines the git workflow, commit conventions, and PR guidelines for this project.

---

## Branching Strategy

### Main Branches

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready code | Require PR, require approval |
| `develop` | Integration branch for features | Require PR |

### Feature Branches

```
feature/ticket-number-feature-name
example: feature/001-add-pdf-library-screen
example: feature/002-implement-search-functionality
```

### Fix Branches

```
fix/ticket-number-bug-description
example: fix/003-memory-leak-in-pdf-viewer
example: fix/004-crash-on-empty-library
```

### Hotfix Branches

```
hotfix/ticket-number-urgent-fix
example: hotfix/005-critical-security-patch
```

### Branch Naming Rules

- Use kebab-case (`add-pdf-search`, not `add_pdf_search`)
- Always include ticket number if available
- Keep names descriptive but concise (max 50 characters)
- No spaces or special characters

---

## Commit Message Convention

Follow **Conventional Commits** specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | When to Use | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(reader): add page jump functionality` |
| `fix` | Bug fix | `fix(library): prevent crash on empty PDF list` |
| `refactor` | Code change without functionality change | `refactor(settings): extract theme switcher to widget` |
| `style` | Formatting, missing semicolons, etc. | `style: format code with dart format` |
| `docs` | Documentation only | `docs(readme): update setup instructions` |
| `test` | Adding or updating tests | `test(library): add coverage for PDF filter` |
| `chore` | Maintenance, dependencies, config | `chore: upgrade flutter to 3.38.5` |
| `perf` | Performance improvements | `perf(library): lazy load PDF thumbnails` |
| `ci` | CI/CD changes | `ci: add github actions workflow` |

### Scopes

Common scopes in this project:

- `library` - Library feature
- `reader` - PDF reader feature
- `settings` - Settings feature
- `scanner` - Document scanner feature
- `core` - Core shared code
- `router` - Navigation/routing
- `theme` - App theming
- `build` - Build configuration

### Examples

```bash
# Feature
git commit -m "feat(reader): add bookmark functionality"

# Bug fix
git commit -m "fix(library): prevent duplicate PDF imports"

# Refactor
git commit -m "refactor(core): extract result type to shared module"

# Breaking change
git commit -m "feat(api)!: remove deprecated sync methods

BREAKING CHANGE: The sync methods have been removed.
Use async methods instead."

# Fix with issue reference
git commit -m "fix(reader): handle corrupted PDF files

Closes #123"
```

---

## Workflow Process

### 1. Start a Feature

```bash
# From develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/006-add-pdf-bookmarks
```

### 2. Development Workflow

```bash
# Make changes and stage
git add lib/features/reader/

# Commit with conventional message
git commit -m "feat(reader): add bookmark persistence"

# Pull latest develop
git pull origin develop --rebase

# Push to origin
git push origin feature/006-add-pdf-bookmarks
```

### 3. Create Pull Request

#### PR Title Format

```
[type] Short description

Refs: #ticket-number
```

Examples:
- `[feat] Add PDF bookmark functionality`
- `[fix] Prevent crash on corrupted PDF files`

#### PR Description Template

```markdown
## Summary
<!-- Brief description of changes -->

## Changes
- Added bookmark feature to reader
- Implemented bookmark persistence with Hive
- Added UI for managing bookmarks

## Testing
- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Manually tested on device
- [ ] Dark mode tested
- [ ] Light mode tested

## Screenshots
<!-- Add before/after screenshots if UI changes -->

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed the code
- [ ] Added/updated tests
- [ ] Updated documentation if needed
- [ ] No merge conflicts
- [ ] Commits follow conventional format
- [ ] Squashed to reasonable number of commits
```

### 4. Review Process

```bash
# After review, make changes
git add .
git commit -m "fix(reader): address review feedback"

# Rebase with develop if needed
git fetch origin develop
git rebase origin/develop

# Force push (careful!)
git push origin feature/006-add-pdf-bookmarks --force-with-lease
```

### 5. Merge PR

1. Ensure all checks pass (CI, tests, review)
2. Squash and merge to `develop`
3. Delete feature branch after merge

```bash
# Delete local branch
git branch -d feature/006-add-pdf-bookmarks

# Delete remote branch
git push origin --delete feature/006-add-pdf-bookmarks
```

---

## Conventional Commits with Git Hooks

Install commitlint for commit message validation:

```bash
# Add to dev_dependencies in pubspec.yaml
dev_dependencies:
  commitizen_cli: ^0.1.0

# Or use npm if available
npm install -g commitizen @commitlint/config-conventional
```

### Commit Message Linting (Optional)

Add `.git/hooks/commit-msg`:

```bash
#!/bin/sh
# Check commit message format
commit_regex='^(feat|fix|refactor|style|docs|test|chore|perf|ci)(\(.+\))?: .{1,50}'
if ! grep -qE "$commit_regex" "$1"; then
  echo "Invalid commit message format"
  echo "Expected: <type>(<scope>): <description>"
  exit 1
fi
```

---

## Git Ignore Patterns

Ensure `.gitignore` includes:

```gitignore
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# IDE
.idea/
.vscode/
*.iml
*.swp
*.swo

# Generated files
*.g.dart
*.freezed.dart

# macOS
.DS_Store

# Local configuration
.env
*.local

# Android/iOS
android/.gradle/
android/app/release/
ios/Pods/
```

---

## Common Git Commands

```bash
# Check current branch
git branch --show-current

# See all branches
git branch -a

# Switch branch
git checkout develop
git switch develop  # Newer command

# Create and switch to new branch
git checkout -b feature/new-feature
git switch -c feature/new-feature

# Stash changes
git stash
git stash pop

# View commit history
git log --oneline --graph --all

# See changes in file
git diff lib/main.dart

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Cherry-pick commit
git cherry-pick abc1234

# Interactive rebase (clean up commits)
git rebase -i HEAD~3  # Last 3 commits
```

---

## Merge vs Rebase

### When to Merge

- Merging PRs to main/develop
- Preserving history

### When to Rebase

- Updating feature branch with latest develop
- Keeping linear history
- Before opening PR

```bash
# Rebase feature branch with develop
git checkout feature/my-feature
git fetch origin develop
git rebase origin/develop
```

---

## Release Workflow

```bash
# 1. Merge develop to main
git checkout main
git merge develop

# 2. Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"

# 3. Push tags
git push origin main --tags

# 4. Build release
flutter build apk --release
flutter build ios --release
```

---

## Troubleshooting

### Resolve Merge Conflicts

```bash
# During rebase
git rebase --continue   # After resolving conflicts
git rebase --abort      # Cancel rebase

# During merge
git merge --continue    # After resolving conflicts
git merge --abort       # Cancel merge
```

### Undo Pushed Commit

```bash
# Safe way - revert
git revert abc1234
git push

# Dangerous - force reset (use --force-with-lease)
git reset --hard HEAD~1
git push --force-with-lease
```

---

## Git Configuration

Set your local git config:

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Set default branch name
git config init.defaultBranch main

# Set rebase as default for pull
git config pull.rebase true

# Set autocrlf (macOS/Linux)
git config core.autocrlf input
```

---

## Checklist Before Commit

- [ ] Code formatted with `dart format`
- [ ] No lint errors (`flutter analyze`)
- [ ] Tests pass (`flutter test`)
- [ ] Commit message follows convention
- [ ] Only relevant files staged
- [ ] Large files (assets) are in LFS if needed
- [ ] No sensitive data committed

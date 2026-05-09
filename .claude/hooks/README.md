# Hooks Documentation

Dokumentasi untuk hooks yang tersedia di project PDF Reader App.

## Overview

Hooks adalah scripts yang berjalan otomatis pada trigger tertentu untuk:
- **Mencegah errors** sebelum operasi berbahaya
- **Otomasi validasi** code quality
- **Logging** perubahan
- **Optimasi workflow** development & deployment

## Available Hooks

### Pre-Hooks (Sebelum Operasi)

| Hook | Trigger | Fungsi |
|------|---------|--------|
| `pre-bash-safety.sh` | Bash tool | Cegah command berbahaya (`rm -rf`, `git reset --hard`) + track dependency |
| `pre-write-check.sh` | Write tool | Validasi struktur file, snake_case naming, info test file |
| `pre-test-validate.sh` | Test/Build | Cek build_runner, test coverage, architecture violations |
| `pre-commit.sh` | Git commit | Full validation: format, analyze, test, TODOs check |
| `pre-git-push.sh` | Git push | Safety check, sensitive data detection, large files |
| `pre-device-connect.sh` | Device connect | Auto-detect device, suggest emulator |
| `pre-firebase-deploy.sh` | Firebase deploy | Validasi Firebase CLI, TypeScript, login status |

### Post-Hooks (Setelah Operasi)

| Hook | Trigger | Fungsi |
|------|---------|--------|
| `post-edit-format.sh` | Edit tool | Auto-format file .dart |
| `post-bash-dependency.sh` | Bash (`flutter pub`) | Track dependency changes ke log |
| `post-edit-build-runner.sh` | Edit tool | Cek apakah perlu run build_runner |
| `post-write-test-suggest.sh` | Write tool | Suggest test file untuk new features |
| `post-build-apk.sh` | APK build | Copy APK ke releases/, notify success, size diff |
| `post-firebase-deploy.sh` | Firebase deploy | Log deploy, notify success/failure |

## Quick Start

### Activate All Hooks

```bash
.claude/scripts/manage-hooks.sh activate
```

### Check Status

```bash
.claude/scripts/manage-hooks.sh status
```

### Enable Specific Hook

```bash
.claude/scripts/manage-hooks.sh enable pre-commit
```

### Disable Specific Hook

```bash
.claude/scripts/manage-hooks.sh disable post-build-apk
```

### Deactivate All

```bash
.claude/scripts/manage-hooks.sh deactivate
```

## Hook Details

### pre-commit.sh

Validasi lengkap sebelum git commit:

1. **Format Check** - `dart format --set-exit-if-changed`
2. **Analyze** - `flutter analyze`
3. **Build Runner Check** - Pastikan generated files up-to-date
4. **Tests** - Run unit tests
5. **TODO/FIXME Check** - Warning untuk unresolved TODOs

**Exit Codes:**
- `0` - Semua check passed
- `1` - Ada issue yang perlu difix

### pre-git-push.sh

Safety check sebelum push ke remote:

1. Uncommitted changes warning
2. Extra caution untuk main/master branch
3. Sensitive data detection (keys, tokens, .env)
4. Large files detection (>5MB)
5. Firebase config detection
6. Quick flutter analyze

### post-build-apk.sh

Setelah APK build selesai:

1. Copy APK ke `releases/` folder
2. Calculate size diff dari previous build
3. macOS notification (Glass sound)
4. Save path untuk comparison next build

**Usage:**
```bash
flutter build apk
# hook auto-triggered via pre-device-connect check
```

### pre-firebase-deploy.sh

Validasi sebelum deploy Firebase functions:

1. Firebase CLI check
2. Login status check
3. Functions directory validation
4. TypeScript compilation check
5. Flutter analyze

### post-firebase-deploy.sh

Setelah deploy selesai:

1. Log deploy details ke `logs/`
2. Cleanup old logs (keep last 10)
3. macOS notification
4. Show deploy URL

## Customization

### Add New Hook

1. Buat script di `.claude/hooks/`
2. Buat executable: `chmod +x .claude/hooks/new-hook.sh`
3. Update `manage-hooks.sh` dengan hook baru di array `HOOKS`
4. Activate: `.claude/scripts/manage-hooks.sh enable new-hook`

### Modify Existing Hook

Edit langsung file di `.claude/hooks/`. Perubahan langsung aktif.

### Skip Hook Temporarily

```bash
# Dengan environment variable
SKIP_HOOKS=1 flutter test

# Atau gunakan --no-hooks flag (jika didukung)
```

## Integration

Hooks terintegrasi dengan Claude Code via file `.claude/hooks/` dan otomatis dipanggil sesuai trigger:

- **Write tool** → `pre-write-check.sh`, `post-write-test-suggest.sh`
- **Edit tool** → `pre-test-validate.sh`, `post-edit-format.sh`, `post-edit-build-runner.sh`
- **Bash tool** → `pre-bash-safety.sh`, `post-bash-dependency.sh`
- **Git operations** → `pre-commit.sh`, `pre-git-push.sh` (via manage-hooks.sh)

## Logs

Hook logs disimpan di:
- Dependency tracking: `.claude/dependency-log.txt`
- Build APK logs: `releases/`
- Firebase deploy logs: `.claude/logs/firebase_deploy_*.log`

## Troubleshooting

### Hook tidak jalan?

```bash
# Check permissions
ls -la .claude/hooks/

# Re-activate
.claude/scripts/manage-hooks.sh deactivate
.claude/scripts/manage-hooks.sh activate
```

### False positive warnings?

Edit hook script untuk adjust thresholds/rules sesuai kebutuhan.

### Want to see hook output?

Jalankan manual untuk debug:
```bash
bash .claude/hooks/pre-test-validate.sh
```

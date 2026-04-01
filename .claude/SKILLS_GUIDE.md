# Claude Code Skills Guide

Complete guide to using Claude Code skills in this Flutter PDF Reader project.

## ✅ Skills Available

### 1. Test Generator (`/test-generator`) ⭐ HIGHEST PRIORITY

**Generate test files with mocks**

```bash
/test-generator notifier pdf_chat        # Generate test untuk notifier
/test-generator model pdf_document       # Generate test untuk model
/test-generator widget library_screen    # Generate test untuk widget
```

**Token Savings**: ~87% (dari ~1500 menjadi ~200 tokens per test)

**Lokasi**: `.claude/skills/test-generator/`

---

### 2. Model/State Generator (`/model-generator`) ⭐

**Generate Freezed models + Riverpod notifiers**

```bash
/model-generator ScannerState --with-notifier    # State + Notifier
/model-generator UserProfile                    # Model only
/model-generator ChatState --add-variant sending  # Add variant
```

**Token Savings**: ~85% (dari ~1000 menjadi ~150 tokens per triplet)

**Lokasi**: `.claude/skills/model-generator/`

---

### 3. Code Review (`/code-review`) ⭐

**Automated code review against project rules**

```bash
/code-review                              # Review semua perubahan
/code-review lib/features/reader/        # Review directory
/code-review pdf_chat_notifier.dart      # Review file
```

**Token Savings**: ~92% (dari ~1200 menjadi ~100 tokens per review)

**Lokasi**: `.claude/skills/code-review/`

---

### 4. Feature Scaffold (`/scaffold-feature`) ⭐

**Generate Clean Architecture structure**

```bash
/scaffold-feature scanner data,presentation    # Layers spesifik
/scaffold-feature bookmarks all                # Semua layers
/scaffold-feature profile presentation          # Presentation only
```

**Token Savings**: ~92% (dari ~2500 menjadi ~200 tokens per feature)

**Lokasi**: `.claude/skills/scaffold-feature/`

---

### 5. Pre-commit Validator (`/pre-commit`) ⭐

**Run validation checks before commit**

```bash
/pre-commit              # Run semua checks
/pre-commit --fix        # Run + auto-fix
```

**Token Savings**: ~94% (dari ~800 menjadi ~50 tokens per commit)

**Lokasi**: `.claude/skills/pre-commit/`

---

## 🚀 Common Workflows

### Workflow 1: Membuat Feature Baru

```bash
# 1. Generate struktur feature
/scaffold-feature scanner data,presentation

# 2. Generate state dan notifier
/model-generator ScannerState --with-notifier

# 3. Implement repository, use case, dan UI
# (Edit file yang sudah di-generate)

# 4. Generate tests
/test-generator repository scanner
/test-generator notifier scanner
/test-generator widget scanner_screen

# 5. Run validation
/code-review lib/features/scanner/
/pre-commit --fix
```

**Total Token Savings**: ~89% (dari ~5500 menjadi ~600 tokens)

---

### Workflow 2: Quick Code Review

```bash
# 1. Run validation cepat
/pre-commit

# 2. Jika ada issues, detailed review
/code-review

# 3. Auto-fix jika possible
/pre-commit --fix

# 4. Re-validate
/pre-commit
```

**Total Token Savings**: ~93% (dari ~2000 menjadi ~150 tokens)

---

### Workflow 3: Menambah State Baru

```bash
# 1. Add state variant ke model
/model-generator ChatState --add-variant sending

# 2. Update tests
/test-generator notifier chat --update

# 3. Review changes
/code-review lib/features/chat/

# 4. Run checks
/pre-commit
```

**Total Token Savings**: ~89% (dari ~2800 menjadi ~300 tokens)

---

## 📊 Overall Impact

### Token Savings Summary

| Task | Tanpa Skill | Dengan Skill | Hemat |
|------|-------------|--------------|-------|
| Test Creation | ~1500 tokens | ~200 tokens | 87% |
| Model/State Generation | ~1000 tokens | ~150 tokens | 85% |
| Code Review | ~1200 tokens | ~100 tokens | 92% |
| Feature Scaffolding | ~2500 tokens | ~200 tokens | 92% |
| Pre-commit Cycle | ~800 tokens | ~50 tokens | 94% |

**Average Token Savings**: 85-90% reduction! 🎉

---

## 🎯 Best Practices

### When to Use Skills

1. **Always use** for repetitive tasks (test generation, scaffolding)
2. **Use frequently** for validation (pre-commit, code review)
3. **Combine skills** for complete workflows
4. **Review generated code** before committing
5. **Customize templates** based on project needs

### Skill Composition

Skills can be chained together:

```bash
# Complete feature creation workflow
/scaffold-feature new_feature all
/model-generator NewFeatureState --with-notifier
/test-generate notifier new_feature
/test-generate widget new_feature_screen
/code-review lib/features/new_feature/
/pre-commit --fix
```

### Integration with Existing Tools

All skills integrate with:
- ✅ `.claude/rules/` documents
- ✅ PostToolUse hooks (flutter analyze)
- ✅ Existing test patterns
- ✅ Clean Architecture structure

---

## 🔧 Troubleshooting

### Common Issues

**Issue**: Generated code has compilation errors
- **Fix**: Run `flutter pub get` dan `flutter pub run build_runner build`

**Issue**: Tests fail after generation
- **Fix**: Implement business logic, then re-run tests

**Issue**: Code review finds too many false positives
- **Fix**: Update rule documents in `.claude/rules/`

**Issue**: Pre-commit is slow
- **Fix**: Use `--filter` option untuk specific checks

---

## 📝 Next Steps

1. **Try the skills!** Start with `/test-generator`
2. **Provide feedback** untuk improvement
3. **Customize templates** based on your needs
4. **Track token savings** untuk validate impact

---

## 🎓 Learning Resources

- **Testing patterns**: `.claude/rules/testing.md`
- **Code style guide**: `.claude/rules/code-style.md`
- **Architecture rules**: `.claude/rules/architecture.md`
- **Existing examples**: `test/unit/features/`, `lib/features/`

---

## 💡 Tips

- Start dengan **Test Generator** - highest ROI
- Use **Feature Scaffold** untuk new features - saves most time
- Run **Pre-commit** sebelum setiap commit - catch issues early
- Use **Code Review** untuk learn project patterns

---

## 🤝 Contributing

To add new skills or improve existing ones:

1. Create skill directory in `.claude/skills/<skill-name>/`
2. Add `SKILL.md` dengan documentation
3. Add templates di `templates/` subdirectory
4. Update this guide
5. Test thoroughly before using

---

**Selamat menggunakan skills! Semoga work Anda jadi lebih efisien dan hemat token!** 🚀

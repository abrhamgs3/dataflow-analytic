# Git Guidelines: What to Commit vs. Ignore

This document clarifies what files should be in the GitHub repository and what should be excluded.

## ✅ TRACKED (Commit These)

### Essential Project Files
```
models/                          # All .sql and .yml files
├── staging/
├── intermediate/
└── marts/

macros/                          # All .sql macros
omni/                            # BI view definitions
.github/workflows/               # CI/CD automation

dbt_project.yml                  # Project config (sanitized)
packages.yml                     # Dependencies
```

### Documentation
```
README.md                        # Project overview
SETUP.md                         # Setup instructions
DATA_DICTIONARY.md              # Data reference
GITHUB_SETUP.md                 # GitHub configuration
PROJECT_SUMMARY.md              # Project history
GIT_GUIDELINES.md              # This file
```

### Configuration & Templates
```
profiles.yml.example            # Template (credentials removed)
.gitignore                       # Git exclusions (this keeps repo clean!)
.github/workflows/*.yml         # Automation workflows
```

---

## ❌ NOT TRACKED (In .gitignore)

### Build Artifacts (Generated, never commit)
```
target/                         # Compiled dbt output
dbt_modules/                    # Downloaded packages
logs/                           # dbt run logs
manifest.json                   # dbt manifest
run_results.json               # dbt execution results
```

**Why:** These are generated from source files. They're recreated on every `dbt run`.

### Secrets & Credentials (CRITICAL - NEVER COMMIT)
```
profiles.yml                    # ❌ NEVER commit! Contains passwords
.env*                          # ❌ NEVER commit! Contains API keys
credentials.json               # ❌ NEVER commit! Cloud credentials
*.pem, *.key                   # ❌ NEVER commit! Private keys
```

**Why:** Exposing secrets compromises security. If accidentally committed:
1. Immediately revoke the credentials
2. Rotate all exposed secrets
3. Force push to remove from history (if not yet public)

### IDE & Editor Files (Developer-specific)
```
.vscode/                        # VS Code workspace
.idea/                          # JetBrains IDE settings
*.swp, *~                      # Vim/editor backups
.DS_Store                       # macOS metadata
Thumbs.db                       # Windows thumbnails
```

**Why:** These are personal to each developer. Committing them creates conflicts and clutter.

### Development Artifacts (Work in progress)
```
.todo, .review, .comment       # Development notes
NOTES.md, SCRATCH.md           # Personal scratch files
_scratch/, temp/               # Temporary work
.pytest_cache/                 # Test caches
```

**Why:** These are for development only, not part of the codebase. Keep them locally.

### Python & Dependencies
```
__pycache__/                    # Python cache
.venv/, venv/                   # Virtual environments
*.egg-info/                     # Package metadata
```

**Why:** Recreated locally. Virtual environments are machine-specific.

### Data Files (Usually excluded)
```
data/raw/                       # Raw data (often large or sensitive)
*.csv, *.parquet               # Data exports
```

**Why:** Data files are often large and shouldn't live in git. Use data warehouses instead.

---

## 📋 Quick Reference

### Before Committing

```bash
# Check what you're about to commit
git status

# Review changes
git diff

# Common mistakes to avoid:
# ❌ Don't commit: profiles.yml, .env, .DS_Store, target/, logs/
# ✅ Do commit:    models/, macros/, *.md, .github/workflows/
```

### If You Accidentally Committed a Secret

```bash
# 1. IMMEDIATELY revoke the credential in your service
# 2. Remove from history (careful - destructive)
git rm --cached profiles.yml
echo "profiles.yml" >> .gitignore
git commit --amend -m "Remove profiles.yml from history"
git push origin main --force-with-lease

# 3. Rotate all exposed credentials
```

---

## 🚀 Final Repository Structure

```
sql_permit/
├── .github/
│   └── workflows/                    ✅ Tracked
│       ├── dbt_run.yml
│       └── dbt_pr.yml
├── models/                           ✅ Tracked
│   ├── staging/
│   ├── intermediate/
│   └── marts/
├── macros/                           ✅ Tracked
├── omni/                             ✅ Tracked
├── dbt_project.yml                   ✅ Tracked
├── packages.yml                      ✅ Tracked
├── profiles.yml.example              ✅ Tracked (template)
├── profiles.yml                      ❌ NOT tracked (.gitignore)
├── .env                              ❌ NOT tracked (.gitignore)
├── README.md                         ✅ Tracked
├── SETUP.md                          ✅ Tracked
├── DATA_DICTIONARY.md                ✅ Tracked
├── GIT_GUIDELINES.md                 ✅ Tracked (this file)
├── .gitignore                        ✅ Tracked
└── target/                           ❌ NOT tracked (.gitignore)
```

---

## 🔒 Security Checklist

Before pushing code:

- [ ] No `profiles.yml` with real credentials
- [ ] No `.env` files with API keys
- [ ] No `credentials.json` or service account keys
- [ ] No private keys (`.pem`, `.key`)
- [ ] No AWS/GCP configs with credentials
- [ ] dbt artifacts removed (target/, logs/)
- [ ] IDE files excluded (.vscode/, .idea/)
- [ ] No data files with sensitive information

---

## 💡 Best Practices

1. **Use .env template, not .env file**
   ```bash
   # Commit this (template):
   .env.example
   
   # Never commit this (secrets):
   .env
   ```

2. **Use profiles.yml.example template**
   ```bash
   # Commit this (example):
   profiles.yml.example
   
   # Never commit this (real credentials):
   profiles.yml
   ```

3. **Keep .gitignore updated**
   - Review .gitignore regularly
   - Add new artifact types as needed
   - Comment entries to explain why

4. **Review before committing**
   ```bash
   git diff --staged
   git status
   ```

---

## Questions?

- **Accidentally committed a secret?** → Immediately revoke credentials, see "If You Accidentally" section above
- **What should be in the repo?** → See ✅ TRACKED section
- **What shouldn't be?** → See ❌ NOT TRACKED section

**Golden Rule:** When in doubt, put it in `.gitignore`. A clean repo is better than overstuffed.

---

**Last Updated:** 2026-10-09  
**Maintained By:** Project Contributors  
**Security:** Keep credentials out of git, always.

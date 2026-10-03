# Pushing SQL-Permit to GitHub

Your local git repository is ready! Follow these steps to push to GitHub.

## Step 1: Create Repository on GitHub

1. Go to [github.com](https://github.com/new)
2. Click "New repository"
3. Enter repository name: `sql-permit` (or your choice)
4. Description: "dbt analytics project for permit lifecycle tracking and customer performance analysis"
5. Choose **Public** or **Private**
6. Do **NOT** initialize with README (we already have one)
7. Click "Create repository"

## Step 2: Add Remote & Push

After creating the repository, GitHub will show you commands. Use them or follow these:

```powershell
cd "C:\Users\Lenovo\Desktop\Courses\SQL-permit"

# Add remote (replace YOUR_USERNAME and REPO_NAME)
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

### Example:
```powershell
git remote add origin https://github.com/abrish/sql-permit.git
git branch -M main
git push -u origin main
```

## Step 3: Verify Push

Check your repository on GitHub to confirm all files are there:
- ✅ All models (.sql files)
- ✅ Documentation (.md files)
- ✅ Workflows (.github/workflows/)
- ✅ Macros (.sql functions)

## Step 4: Configure GitHub Secrets (for CI/CD)

If you want to use the automated workflows, add these secrets:

1. Go to GitHub → Your repo → **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `DBT_ACCOUNT` - Your Snowflake account ID
   - `DBT_USER` - dbt service account username
   - `DBT_PASSWORD` - dbt service account password
   - `DBT_ROLE` - dbt role (e.g., analytics_prod)
   - `DBT_DATABASE` - Analytics database name
   - `DBT_WAREHOUSE` - Warehouse name
   - `SLACK_WEBHOOK` - (Optional) Slack webhook for notifications

Without these, workflows will fail. You can disable workflows temporarily:

**Settings** → **Actions** → **General** → **Disable all actions** (or allow specific workflows)

## Step 5: Protect Main Branch (Recommended)

In GitHub repository settings:

1. Go to **Settings** → **Branches**
2. Add branch protection rule for `main`:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
   - ✅ Include administrators

This ensures code quality before merging.

## Troubleshooting

### "fatal: 'origin' does not appear to be a 'git' repository"
Your GitHub URL is wrong. Check the repo URL again:
```powershell
git remote -v  # Check current remotes
git remote remove origin  # Remove wrong remote
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git
```

### "fatal: Authentication failed"
GitHub requires authentication. Use one of these:
- **Personal Access Token** (recommended)
- **SSH Key** (advanced)
- **GitHub CLI** (easiest)

**Using GitHub CLI (Easiest):**
```powershell
gh auth login
# Then retry: git push -u origin main
```

### "error: src refspec main does not match any"
You're not on the main branch:
```powershell
git branch -M main
git push -u origin main
```

## Next Steps

1. ✅ Share repo link with team
2. ✅ Configure branch protection
3. ✅ Add collaborators in Settings
4. ✅ (Optional) Add GitHub Secrets for automation
5. ✅ Create issues/PRs for feature development

---

**Questions?** See README.md or SETUP.md in the repository.

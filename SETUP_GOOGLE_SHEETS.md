# Google Sheets API Setup Guide - SECURE METHOD

⚠️ **SECURITY NOTICE:** This guide uses **OAuth2 with Application Default Credentials** (ADC) instead of service account keys, following security best practices.

## Why This Approach is Secure

✅ **No service account keys on your laptop** (security risk)  
✅ **Uses your user credentials** via OAuth2  
✅ **Leverages existing GCP project** (no new project needed)  
✅ **Complies with security policies** (uses official Google tools)

## Prerequisites

- Google Account with access to existing GCP project
- `gcloud` CLI installed (part of Google Cloud SDK)
- Python 3 with pip (already installed)

## Recommended Setup (OAuth2 via gcloud)

### 1. Use Existing GCP Project

**DO NOT create a new project.** Use your team's existing GCP project.

```bash
# List your available projects
gcloud projects list

# Set your project (replace with your actual project)
gcloud config set project YOUR-EXISTING-PROJECT-ID
```

### 2. Enable Google Sheets API

```bash
# Enable the API in your existing project
gcloud services enable sheets.googleapis.com
```

### 3. Authenticate with OAuth2 (Application Default Credentials)

**This is the secure method recommended by security teams:**

```bash
# Authenticate using your user credentials (NOT service account)
gcloud auth application-default login --disable-quota-project

# This will:
# 1. Open a browser for OAuth2 consent
# 2. Store credentials in ~/.config/gcloud/application_default_credentials.json
# 3. Use YOUR user permissions (not a service account key file)
```

**Why this is better:**
- ✅ No service account key files sitting on your laptop
- ✅ Uses your existing permissions
- ✅ Can be revoked centrally
- ✅ Follows security best practices

### 4. Test Authentication

```bash
# Verify authentication works
gcloud auth application-default print-access-token

# You should see an access token (means it's working)
```

### 5. Test Authentication

```bash
cd /Users/aybueke.kayaci/woowa_search_analysis
source venv/bin/activate

# Test the upload script
python3 upload_to_sheets.py 2026-05-27
```

**What happens:**
1. Script uses Application Default Credentials from gcloud
2. Creates/updates Google Sheet automatically
3. No browser popup needed (already authenticated in step 3)
4. Returns the spreadsheet URL

**Credentials location:**
- Stored at: `~/.config/gcloud/application_default_credentials.json`
- Managed by gcloud (no manual token files)
- Uses your user permissions

### 6. Configure Email Address

Set your email address for notifications:

**Option A: Environment variable**
```bash
export AB_TEST_EMAIL="your.email@example.com"
```

**Option B: Edit the script directly**
```bash
# Edit line 16 in run_daily_ab_test_report.sh
USER_EMAIL="your.email@example.com"
```

### 7. Test the Full Report

Run the complete report pipeline:

```bash
cd /Users/aybueke.kayaci/woowa_search_analysis
./run_daily_ab_test_report.sh
```

**Expected output:**
- ✓ All three queries run successfully
- ✓ CSV files created in `reports/` directory
- ✓ Data uploaded to Google Sheets (new spreadsheet created)
- ✓ Email notification generated (saved to file)
- ✓ Spreadsheet URL displayed

## Troubleshooting

### "Google Cloud credentials not found"

```bash
# Authenticate using gcloud (SECURE METHOD)
gcloud auth application-default login --disable-quota-project

# Test authentication
gcloud auth application-default print-access-token
```

### "Permission denied" or "Access token expired"

```bash
# Re-authenticate (refreshes your OAuth token)
gcloud auth application-default login --disable-quota-project

# Or revoke and re-authenticate
gcloud auth application-default revoke
gcloud auth application-default login --disable-quota-project
```

### "BigQuery authentication failed"

```bash
# Authenticate with Google Cloud
gcloud auth application-default login

# Test BigQuery access
bq ls
```

### "ModuleNotFoundError: No module named 'google'"

```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Verify packages are installed
pip list | grep google
```

## File Locations

| File | Purpose | Location |
|------|---------|----------|
| **gcloud credentials** | OAuth2 token (managed by gcloud) | `~/.config/gcloud/application_default_credentials.json` |
| Spreadsheet ID | Reuse same sheet | `~/.claude/woowa_ab_test_sheet_id.txt` |
| CSV reports | Query results | `/Users/aybueke.kayaci/woowa_search_analysis/reports/` |
| Email drafts | Notification text | `/Users/aybueke.kayaci/woowa_search_analysis/reports/email_*.txt` |

**Note:** No manual credential files needed! Everything is managed by `gcloud auth`.

## Security Notes ⚠️

### What This Method Does RIGHT ✅

- ✅ **Uses OAuth2 with Application Default Credentials** (official Google method)
- ✅ **No service account keys** stored on your laptop (major security risk)
- ✅ **Uses your user permissions** (can be revoked centrally)
- ✅ **Uses existing GCP project** (no cost allocation issues)
- ✅ **Follows security best practices** (compliant with company policies)
- ✅ **Credentials managed by gcloud** (automatic refresh)

### What to AVOID ❌

- ❌ **Service account JSON keys** - These are a security risk if leaked
- ❌ **Creating new GCP projects** - Cost allocation and maintenance issues
- ❌ **Unofficial/unsupported tools** - May violate security policies
- ❌ **Committing credentials to git** - Never store credentials in code
- ❌ **Sharing credential files** - Each person should authenticate individually

### Why Service Accounts are Bad for Local Development

**Problem:** Service account keys are JSON files with credentials that:
- Can be leaked via git commits, backups, or screenshots
- Live on your laptop (lost/stolen laptop = compromised credentials)
- Have broad permissions that can't be easily revoked
- Require manual rotation and key management

**Solution:** Use Application Default Credentials (ADC) via gcloud:
- No key files stored locally
- Uses your personal Google account permissions
- Can be revoked instantly from central admin console
- Automatically refreshes tokens
- Audit trail tied to your user account

## Daily Automation

The report is scheduled to run daily at 5am via Claude Code cron job.

**View scheduled jobs:**
```bash
# In Claude Code
User: /tasks
```

**Manual run:**
```bash
cd /Users/aybueke.kayaci/woowa_search_analysis
./run_daily_ab_test_report.sh
```

## Google Sheets Output

Each daily run creates/updates a spreadsheet with three tabs:

1. **Overall** - High-level metrics by search vertical
2. **Tier Analysis** - Head/Torso/Tail breakdown
3. **Query Detail** - Per-query comprehensive analysis

The same spreadsheet is reused daily, with data being replaced each run.

## Next Steps

After setup is complete:
1. ✅ Test manual run of the report
2. ✅ Verify Google Sheets upload works
3. ✅ Check email notification is generated
4. ✅ Wait for first scheduled run at 5am
5. ✅ Review results in Google Sheets

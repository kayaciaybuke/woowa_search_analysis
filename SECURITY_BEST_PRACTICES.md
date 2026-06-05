# Security Best Practices for Google Sheets Integration

This document outlines the **secure, compliant approach** for connecting Claude Code to Google Sheets, based on security team guidance.

---

## ⚠️ The Problem: Service Accounts Are a Security Risk

**What people often do (INSECURE):**
- Create a service account in Google Cloud
- Download a JSON key file
- Store it on their laptop
- Use it in scripts

**Why this is dangerous:**
1. **Leaked credentials** - Key files can be committed to git, backed up, or screenshotted
2. **Lost/stolen laptop** - If your laptop is compromised, so are the credentials
3. **Broad permissions** - Service accounts often have more permissions than needed
4. **Manual rotation** - Keys don't auto-expire and must be manually rotated
5. **No audit trail** - Hard to trace actions back to individual users

---

## ✅ The Solution: Application Default Credentials (ADC)

**What you should do (SECURE):**
- Use OAuth2 with Application Default Credentials via `gcloud auth`
- Use your personal Google account permissions
- No key files stored locally
- Credentials managed centrally

**Why this is better:**
1. ✅ **No key files** - Credentials are stored securely by gcloud
2. ✅ **Personal permissions** - Uses YOUR Google account (can be revoked centrally)
3. ✅ **Auto-refresh** - Tokens refresh automatically
4. ✅ **Audit trail** - All actions tied to your user account
5. ✅ **Least privilege** - Only the permissions you actually have

---

## How to Set Up (Secure Method)

### 1. Use Existing GCP Project

**DO NOT create a new project.** This causes:
- Cost allocation issues (which team pays?)
- Maintenance overhead
- Security review requirements

**Instead:**
```bash
# List your available projects
gcloud projects list

# Use your team's existing project
gcloud config set project YOUR-TEAM-PROJECT-ID
```

### 2. Enable Required APIs

```bash
# Enable Google Sheets API in your existing project
gcloud services enable sheets.googleapis.com
```

### 3. Authenticate with OAuth2

```bash
# Authenticate using Application Default Credentials
gcloud auth application-default login --disable-quota-project
```

**What this does:**
- Opens a browser for OAuth2 consent
- Stores credentials at `~/.config/gcloud/application_default_credentials.json`
- Uses YOUR user permissions (not a service account)
- Can be revoked from Google Admin Console

### 4. Test Authentication

```bash
# Verify it works
gcloud auth application-default print-access-token

# You should see an access token (means it's working)
```

---

## Policy Compliance

Based on security team guidance:

### ✅ Allowed (Compliant)

- **Official Google Cloud tools** (gcloud, bq, gsutil)
- **Tools covered by GCP Terms of Service**
- **OAuth2 with user credentials**
- **Using existing team GCP projects**

### ❌ Not Allowed (Non-Compliant)

- **Unofficial/unsupported tools** without security review
- **Service account keys on local machines**
- **Creating new GCP projects without approval**
- **Tools marked as "not officially supported by Google"**
- **Extensions not covered by GCP Terms of Service**

---

## Red Flags to Watch For

🚩 **If a guide tells you to:**
- Download a JSON key file → **STOP** (service account key risk)
- Create a new GCP project → **STOP** (cost allocation issue)
- Use a tool that says "not officially supported" → **STOP** (policy violation)
- Store credentials in your code or `.env` file → **STOP** (security risk)

✅ **Instead:**
- Use `gcloud auth application-default login`
- Use your team's existing GCP project
- Use officially supported Google Cloud tools
- Let gcloud manage credentials

---

## Code Example (Python)

**BAD (Insecure - Service Account):**
```python
# ❌ DO NOT DO THIS
from google.oauth2 import service_account

credentials = service_account.Credentials.from_service_account_file(
    'service-account-key.json'  # ← Security risk!
)
```

**GOOD (Secure - Application Default Credentials):**
```python
# ✅ DO THIS INSTEAD
import google.auth

# Uses Application Default Credentials from gcloud auth
credentials, project = google.auth.default()
```

---

## Troubleshooting

### "Google Cloud credentials not found"

```bash
# Authenticate (or re-authenticate)
gcloud auth application-default login --disable-quota-project
```

### "Permission denied"

```bash
# Check which project you're using
gcloud config get-value project

# Make sure you have access to this project
gcloud projects get-iam-policy YOUR-PROJECT-ID

# If you don't have access, ask your team admin
```

### "Access token expired"

```bash
# Revoke and re-authenticate
gcloud auth application-default revoke
gcloud auth application-default login --disable-quota-project
```

---

## Summary: Quick Comparison

| Method | Service Account Key | Application Default Credentials |
|--------|---------------------|--------------------------------|
| **Security** | ❌ High risk | ✅ Secure |
| **Compliance** | ❌ Violates policy | ✅ Compliant |
| **Key files** | ❌ Yes (on laptop) | ✅ No |
| **Audit trail** | ❌ Generic account | ✅ Your user account |
| **Revocation** | ❌ Manual | ✅ Central admin |
| **Auto-refresh** | ❌ No | ✅ Yes |
| **Setup** | ❌ Complex | ✅ Simple |

---

## References

**Secure authentication:**
- [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)
- [Best practices for managing credentials](https://cloud.google.com/docs/authentication/best-practices)

**What to avoid:**
- [Why you shouldn't use service account keys](https://cloud.google.com/iam/docs/best-practices-for-using-and-managing-service-account-keys)

**Policy compliance:**
- Use tools covered by GCP Terms of Service
- Avoid "not officially supported" extensions
- Go through SAM process for non-Google tools

---

## Questions?

**Q: Can I use service accounts for automation?**  
A: Only if they run on GCP infrastructure (Cloud Run, GKE, etc.) where keys aren't stored locally. For local development, use ADC.

**Q: What if I need to share credentials with my team?**  
A: Don't share credentials. Each person should authenticate individually with `gcloud auth application-default login`.

**Q: Can I commit the credentials file to git?**  
A: **NEVER.** The ADC file at `~/.config/gcloud/application_default_credentials.json` should never be committed. It's automatically in your home directory, which shouldn't be in git anyway.

**Q: What about CI/CD pipelines?**  
A: For CI/CD, use Workload Identity Federation or service accounts with proper RBAC. This guidance is specifically for local development on your laptop.

---

**Last Updated:** 2026-05-28  
**Status:** ✅ Compliant with security policies  
**Method:** Application Default Credentials via gcloud auth

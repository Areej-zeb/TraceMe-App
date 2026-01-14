# Security & Credentials Setup

## 🔐 Required Credentials (NOT included in repository)

This repository does **NOT** include sensitive credentials for security reasons. You must create and configure your own:

### 1. Firebase Service Account (Optional - for Admin/Backend)
**File**: `service-account.json`  
**Location**: Project root (already gitignored)

To create:
1. Go to [Firebase Console](https://console.firebase.google.com/) → Your Project
2. Click ⚙️ Settings → Service Accounts
3. Click "Generate New Private Key"
4. Save as `service-account.json` in the project root

⚠️ **NEVER commit this file to git!**

### 2. Google Services Configuration

#### Android
**File**: `android/app/google-services.json`  
**Already gitignored**: ✅

To create:
1. Firebase Console → Project Settings → General
2. Under "Your apps" → Android app
3. Download `google-services.json`
4. Place in `android/app/`

#### iOS (if supporting iOS)
**File**: `ios/Runner/GoogleService-Info.plist`  
**Already gitignored**: ✅

To create:
1. Firebase Console → Project Settings → General
2. Under "Your apps" → iOS app
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/`

### 3. Google Maps API Key

**File**: `android/app/src/main/AndroidManifest.xml`

Current placeholder in code:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_REAL_API_KEY_HERE" />
```

To get your API key:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable "Maps SDK for Android"
3. Go to APIs & Services → Credentials
4. Create/Copy your API Key
5. Replace `YOUR_REAL_API_KEY_HERE` with your actual key

⚠️ **Important**: Restrict your API key to Android apps only with package name `com.traceme.traceme`

## 📋 Files Protected by .gitignore

The following sensitive files are automatically excluded from version control:

```
service-account.json
service-account/
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
*.keystore
*.jks
*.p12
*.key
.env*
android/local.properties
```

## ✅ Security Checklist

Before contributing or deploying:

- [ ] Verified `service-account.json` is NOT in git (`git ls-files | grep service-account` should return nothing)
- [ ] Checked `google-services.json` is NOT in git
- [ ] Maps API key is restricted to your app's package name
- [ ] No hardcoded API keys or tokens in source code
- [ ] Firebase security rules are properly deployed
- [ ] All `.env` files are gitignored

## 🚨 If You Accidentally Committed Secrets

1. **Immediately rotate** the compromised credentials
2. Remove from git history:
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/secret/file" \
     --prune-empty --tag-name-filter cat -- --all
   ```
3. Force push: `git push origin --force --all`
4. Notify your team if it's a shared repository

## 📞 Questions?

If you have security concerns, please open a private security advisory on GitHub rather than a public issue.

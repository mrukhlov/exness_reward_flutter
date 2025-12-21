# Security Best Practices for API Keys

## ⚠️ Important Security Notes

### Google Maps API Key Security

**The Reality:**
- Any API key embedded in a mobile app **can be extracted** from the app bundle (IPA/APK)
- `Info.plist` files are bundled with the app and easily readable
- Even compiled code can be reverse-engineered

**What Actually Protects You:**
1. **API Key Restrictions** (Most Important!)
   - Restrict your Google Maps API key to your iOS bundle ID
   - Set usage quotas and billing limits
   - Monitor usage in Google Cloud Console
   - This prevents unauthorized use even if the key is extracted

2. **Secrets.swift Approach** (Better than Info.plist)
   - File is gitignored (won't be committed to version control)
   - Still extractable from IPA, but better than committing to git
   - Use for development and team sharing

3. **Environment Variables** (For CI/CD)
   - Use for automated builds
   - Never hardcode in scripts

## Best Practices

### ✅ DO:
- ✅ Use API key restrictions (bundle ID, IP, referrer)
- ✅ Set usage quotas and billing alerts
- ✅ Monitor API usage regularly
- ✅ Use Secrets.swift (gitignored) for development
- ✅ Rotate keys if compromised
- ✅ Use separate keys for dev/staging/production

### ❌ DON'T:
- ❌ Commit API keys to version control
- ❌ Share keys in public repositories
- ❌ Use unrestricted API keys
- ❌ Use the same key for multiple apps
- ❌ Ignore usage alerts

## How to Restrict Your Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Select your API key
3. Under "Application restrictions":
   - Select "iOS apps"
   - Add your bundle ID: `com.exness.rewardFlutter`
4. Under "API restrictions":
   - Select "Restrict key"
   - Choose "Maps SDK for iOS"
5. Save changes

## If Your Key is Compromised

1. Immediately regenerate the key in Google Cloud Console
2. Update Secrets.swift with the new key
3. Review usage logs for unauthorized access
4. Consider implementing additional monitoring

## Additional Resources

- [Google Maps API Key Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Securing API Keys](https://cloud.google.com/docs/authentication/api-keys)


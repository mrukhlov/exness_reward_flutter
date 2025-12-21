# Google Maps Troubleshooting Guide

## Issue: White Screen with Markers but No Map Tiles

If you see markers but no map tiles (white/gray background), this indicates:
- ✅ Flutter/Google Maps SDK is working (markers render)
- ❌ Google Maps API authentication is failing (tiles don't load)

## Common Causes & Solutions

### 1. API Key Restrictions Too Strict

**Problem:** Your API key is restricted but the bundle ID doesn't match.

**Solution:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Click on your API key
3. Under "Application restrictions":
   - Select "iOS apps"
   - Add bundle ID: `com.exness.rewardFlutter`
   - Make sure it matches exactly (case-sensitive)
4. Save changes
5. Wait 5-10 minutes for changes to propagate

### 2. Maps SDK for iOS Not Enabled

**Problem:** The API key exists but Maps SDK for iOS isn't enabled.

**Solution:**
1. Go to [Google Cloud Console APIs](https://console.cloud.google.com/apis/library)
2. Search for "Maps SDK for iOS"
3. Click "Enable"
4. Wait a few minutes

### 3. API Key Not Initialized

**Problem:** The API key isn't being set before the map loads.

**Check:**
- Look in Xcode console for: `✅ Google Maps API key initialized: AIzaSyD0Hz...`
- If you see `⚠️ ERROR: Google Maps API key not found!`, the key isn't being read

**Solution:**
- Verify `ios/Runner/Secrets.swift` has the correct key
- Make sure `Secrets.swift` is added to Xcode project
- Check that the key isn't the placeholder value

### 4. Bundle ID Mismatch

**Problem:** Your app's bundle ID doesn't match the API key restriction.

**Check:**
1. Open Xcode
2. Select your project → Target "Runner" → General tab
3. Check "Bundle Identifier" (should be `com.exness.rewardFlutter`)
4. Verify this matches your API key restriction exactly

### 5. Network Issues

**Problem:** Device can't reach Google Maps servers.

**Check:**
- Device has internet connection
- No firewall blocking Google Maps API
- Try on different network (WiFi vs cellular)

## Debug Steps

1. **Check Console Logs:**
   - Look for `✅ Google Maps API key initialized` message
   - Look for any Google Maps error messages
   - Check for network errors

2. **Verify API Key:**
   ```bash
   # Check if Secrets.swift has real key (not placeholder)
   grep -v "YOUR_GOOGLE_MAPS_API_KEY_HERE" ios/Runner/Secrets.swift
   ```

3. **Test API Key:**
   - Go to Google Cloud Console
   - Check API key usage/errors
   - Verify it's being used (should see requests)

4. **Check Restrictions:**
   - Bundle ID: `com.exness.rewardFlutter`
   - API restrictions: "Maps SDK for iOS" only
   - No IP restrictions (unless needed)

## Quick Fix Checklist

- [ ] API key is set in `ios/Runner/Secrets.swift` (not placeholder)
- [ ] `Secrets.swift` is added to Xcode project
- [ ] Maps SDK for iOS is enabled in Google Cloud Console
- [ ] API key restriction includes bundle ID: `com.exness.rewardFlutter`
- [ ] Bundle ID in Xcode matches: `com.exness.rewardFlutter`
- [ ] Device has internet connection
- [ ] Rebuilt app after making changes

## Still Not Working?

1. **Remove restrictions temporarily** (for testing only):
   - Set API key restriction to "None"
   - Test if map loads
   - If it works, the issue is with restrictions
   - Re-add restrictions properly

2. **Check API key quota:**
   - Go to Google Cloud Console
   - Check if you've exceeded daily quota
   - Check billing is enabled

3. **Try a new API key:**
   - Create a new API key
   - Don't add restrictions initially
   - Test if map loads
   - Then add restrictions one by one

## Expected Console Output

When working correctly, you should see:
```
✅ Google Maps API key initialized: AIzaSyD0Hz...
✅ Google Map controller created
```

If you see errors, they'll help identify the issue.


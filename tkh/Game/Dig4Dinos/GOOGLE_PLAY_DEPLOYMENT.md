# Google Play Console Deployment Guide

## 🚀 Export Configuration Complete!

Your project is now configured to build an **Android App Bundle (AAB)** file required for Google Play Console deployment.

## 📋 Prerequisites

### 1. Install Android SDK & Build Tools
- Download Android Studio or Android SDK Command Line Tools
- Install SDK platforms for API 21 (minimum) and 34 (target)
- Install Android SDK Build Tools (latest version)

### 2. Configure Godot Android Export
In Godot Editor:
1. Go to **Editor > Editor Settings > Export > Android**
2. Set **Android SDK Path** (e.g., `/Users/[username]/Library/Android/sdk`)
3. Set **Debug Keystore** path (Godot will create one if needed)

## 🔑 Signing Your App Bundle

### For Testing (Debug Build):
1. In Godot: **Project > Export**
2. Select **Android** preset
3. Click **Export Project**
4. Choose filename: `Dig4Dinos-debug.aab`
5. Export without signing for testing

### For Production (Release Build):
You need a **Release Keystore**:

```bash
# Generate release keystore (one-time setup)
keytool -genkey -v -keystore dig4dinos-release.keystore -alias dig4dinos -keyalg RSA -keysize 2048 -validity 10000

# Store this keystore file securely - you'll need it for ALL future updates!
```

Then in `export_presets.cfg`, update:
```properties
keystore/release="path/to/dig4dinos-release.keystore"
keystore/release_user="dig4dinos"
keystore/release_password="your_password"
```

## 📦 Building the App Bundle

### Method 1: Godot Editor
1. Open **Project > Export**
2. Select **Android** preset
3. Check **Export With Debug** is OFF for production
4. Click **Export Project**
5. Save as `Dig4Dinos.aab`

### Method 2: Command Line
```bash
# From your project directory
godot --headless --export "Android" build/Dig4Dinos.aab
```

## 📱 Current Export Configuration

✅ **Export Format**: Android App Bundle (AAB)  
✅ **Target SDK**: API 34 (Android 14)  
✅ **Minimum SDK**: API 21 (Android 5.0)  
✅ **Architecture**: ARM64-v8a (64-bit required by Google Play)  
✅ **Package Name**: `com.yourstudio.dig4dinos`  
✅ **Version**: 1.0 (Code: 1)

## 🏪 Google Play Console Upload

### 1. Create Google Play Developer Account
- Pay $25 one-time registration fee
- Complete account verification

### 2. Create New App
1. Go to [Google Play Console](https://play.google.com/console/)
2. Click **Create App**
3. Fill in app details:
   - **App Name**: Dig 4 Dinos
   - **Default Language**: English
   - **App Type**: Game
   - **Category**: Casual/Arcade

### 3. Upload App Bundle
1. Go to **Release > Production**
2. Click **Create New Release**
3. Upload your `Dig4Dinos.aab` file
4. Fill in release notes
5. Review and rollout

## 📝 Required Assets for Play Store

Before publishing, you'll need:

### Store Listing Assets:
- **App Icon**: 512x512 PNG
- **Feature Graphic**: 1024x500 PNG
- **Screenshots**: At least 2 phone screenshots
- **Privacy Policy URL** (required for games)

### App Content:
- **Content Rating**: Complete questionnaire
- **Target Audience**: Age groups
- **App Category**: Games > Casual

## 🔍 Testing Before Release

1. **Internal Testing**: Upload AAB and test with internal testers
2. **Closed Testing**: Test with limited users
3. **Open Testing**: Public beta (optional)
4. **Production**: Full release

## 🚨 Important Notes

- **Keep Your Keystore Safe**: You cannot update your app without the same keystore
- **Version Management**: Increment `version/code` for each update
- **64-bit Requirement**: Google Play requires 64-bit builds (already configured)
- **Play Console Review**: First submissions take 1-7 days for review

## 🎮 Your Game is Ready!

Your Dig 4 Dinos game includes:
- ✅ Complete gameplay loop
- ✅ Professional UI/UX
- ✅ Audio system
- ✅ Mobile optimization
- ✅ Android export configuration

Ready to deploy to Google Play Store! 🚀
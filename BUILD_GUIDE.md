# Audley Achievers — Build Guide
## From Source Code to APK (Android) & IPA (iOS)

This guide assumes **zero app development experience**. Follow each step exactly.

---

## PART 0: What You Need

| What | For | Cost |
|------|-----|------|
| A computer (Windows, Mac, or Linux) | Building the Android APK | Free |
| A Mac (MacBook, iMac, or Mac Mini) | Building the iOS IPA | Free (hardware) |
| Google Play Developer Account | Publishing on Play Store | $25 one-time |
| Apple Developer Account | Publishing on App Store | $99/year |
| Firebase Account | Push Notifications | Free |

> **No Mac?** You can still build the Android APK on any computer. For iOS, you'll need access to a Mac — even a friend's Mac for a few hours, or a cloud Mac service like [MacStadium](https://www.macstadium.com/) or [GitHub Actions with macOS runners](https://github.com/features/actions).

---

## PART 1: Install Flutter (One-Time Setup)

### On Windows

1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows/mobile
2. Extract the zip to `C:\flutter`
3. Add `C:\flutter\bin` to your system PATH:
   - Search "Environment Variables" in Start menu
   - Under System Variables, find `Path`, click Edit
   - Click New, type `C:\flutter\bin`
   - Click OK on all dialogs
4. Open Command Prompt and run:
   ```
   flutter doctor
   ```

### On Mac

1. Open Terminal and run:
   ```bash
   # Install Homebrew if you don't have it
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Install Flutter
   brew install flutter
   ```
2. Run:
   ```bash
   flutter doctor
   ```

### Install Android Studio (for Android builds)

1. Download from https://developer.android.com/studio
2. Install it, open it once, and let it download the Android SDK
3. Go to **Settings → Plugins → Marketplace** → search "Flutter" → Install
4. Accept Android licenses:
   ```
   flutter doctor --android-licenses
   ```
   Press `y` for each prompt.

### Install Xcode (for iOS builds — Mac only)

1. Open the Mac App Store → search "Xcode" → Install (it's ~12 GB, takes a while)
2. After install, open Terminal and run:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

### Verify Everything

Run `flutter doctor` again. You should see checkmarks ✓ for:
- Flutter (Channel stable)
- Android toolchain
- Xcode (if on Mac)

---

## PART 2: Prepare the Project

### 2a. Apply Backend Changes FIRST

Before building the app, you must upload the backend API additions to your live server.
See `BACKEND_SETUP.md` in the `backend-additions/` folder:

1. Upload `api/content.php` to your server's `/api/` folder
2. Upload `api/notifications.php` to your server's `/api/` folder
3. Create `data/fcm_tokens.json` with content `[]`
4. Apply the CORS fix to `includes/Security.php`

**Test it:** Open this URL in your browser:
```
https://www.distantfrontiers.in/audleyachievers/api/content.php?action=get_app_config
```
You should see JSON output. If you get an error, fix the backend first.

### 2b. Set Up the Flutter Project

1. Copy the entire `audley_achievers/` folder to your computer (e.g., to your Desktop)
2. Open a Terminal/Command Prompt
3. Navigate to the project folder:
   ```
   cd Desktop/audley_achievers
   ```
4. Get dependencies:
   ```
   flutter pub get
   ```
   This downloads all required packages. Wait for it to finish.

### 2c. Add an App Icon (Optional but Recommended)

1. Create a 1024×1024 PNG image for your app icon
2. Save it as `assets/icon.png` inside the project folder
3. Run:
   ```
   dart run flutter_launcher_icons
   ```

---

## PART 3: Build Android APK

### 3a. Quick Build (Debug APK — for testing)

This is the **fastest way** to get an APK on your phone:

```bash
flutter build apk --debug
```

The APK file will be at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

**To install on your phone:**
1. Transfer the APK file to your Android phone (via email, USB, Google Drive, etc.)
2. On your phone, tap the file
3. If prompted, allow "Install from unknown sources"
4. Tap Install

### 3b. Release APK (for distribution)

For a production-quality, smaller, faster APK:

**Step 1: Create a signing key** (one-time, takes 30 seconds):

```bash
keytool -genkey -v -keystore ~/audley-keystore.jks -keyalias audley -keyalg RSA -keysize 2048 -validity 10000 -storepass YOUR_PASSWORD_HERE -keypass YOUR_PASSWORD_HERE
```

Replace `YOUR_PASSWORD_HERE` with a password you'll remember. It will ask you some questions (name, organization, etc.) — you can press Enter to skip most of them, just type `yes` at the end.

> ⚠️ **SAVE THIS KEYSTORE FILE AND PASSWORD.** You need them for every future update. If you lose them, you cannot update your app on the Play Store.

**Step 2: Tell the project about your key.**

Create a file called `android/key.properties` with this content:
```
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=audley
storeFile=/Users/YOURUSERNAME/audley-keystore.jks
```

(On Windows, use the full path like `C:\\Users\\YourName\\audley-keystore.jks`)

**Step 3: Build the signed release APK:**

```bash
flutter build apk --release
```

The signed APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 3c. Build AAB (for Google Play Store)

Google Play requires AAB format (not APK):

```bash
flutter build appbundle --release
```

The AAB file will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## PART 4: Build iOS IPA (Mac Only)

### 4a. Quick Build (for your own iPhone/TestFlight testing)

**Step 1: Open the iOS project in Xcode:**
```bash
open ios/Runner.xcworkspace
```

**Step 2: In Xcode:**
1. Click "Runner" in the left sidebar
2. Under "Signing & Capabilities":
   - Check "Automatically manage signing"
   - Select your Team (your Apple ID — you can use a free Apple ID for testing)
   - If you don't see a team, click "Add Account" and sign in with your Apple ID
3. Change the Bundle Identifier to something unique:
   ```
   com.distantfrontiers.audleyachievers
   ```

**Step 3: Build from Terminal:**
```bash
flutter build ipa --release
```

The IPA will be at:
```
build/ios/ipa/audley_achievers.ipa
```

### 4b. Install on Your iPhone (without App Store)

1. Connect your iPhone to your Mac with a USB cable
2. Open Xcode
3. Go to **Window → Devices and Simulators**
4. Select your iPhone
5. Click the **+** button under "Installed Apps"
6. Select the `.ipa` file
7. The app will install on your phone

### 4c. Upload to App Store via TestFlight

1. Open **Transporter** app on your Mac (download from Mac App Store if needed)
2. Sign in with your Apple Developer account
3. Drag and drop the `.ipa` file into Transporter
4. Click "Deliver"
5. Go to https://appstoreconnect.apple.com → My Apps → TestFlight
6. The build will appear in ~15 minutes after processing

---

## PART 5: Firebase Push Notifications (Optional)

This enables push notifications to users' phones.

### 5a. Create a Firebase Project

1. Go to https://console.firebase.google.com/
2. Click "Add Project"
3. Name it "Audley Achievers"
4. Follow the setup wizard (you can disable Google Analytics)

### 5b. Add Android App to Firebase

1. In Firebase console, click "Add app" → Android
2. Package name: `com.distantfrontiers.audleyachievers`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`
5. In `android/app/build.gradle`, uncomment this line:
   ```
   // id "com.google.gms.google-services"
   ```
   → becomes:
   ```
   id "com.google.gms.google-services"
   ```

### 5c. Add iOS App to Firebase

1. In Firebase console, click "Add app" → iOS
2. Bundle ID: `com.distantfrontiers.audleyachievers`
3. Download `GoogleService-Info.plist`
4. Open Xcode, right-click the `Runner` folder → "Add Files"
5. Select `GoogleService-Info.plist`

### 5d. Enable in Code

In `lib/main.dart`, uncomment these two lines:
```dart
// import 'package:firebase_core/firebase_core.dart';  ← uncomment
// await Firebase.initializeApp();                       ← uncomment
```

Then rebuild the app.

---

## PART 6: Publish to Stores

### Google Play Store

1. Go to https://play.google.com/console
2. Create a developer account ($25 one-time fee)
3. Create a new app → fill in the details
4. Under "Release" → "Production" → "Create new release"
5. Upload the `.aab` file
6. Fill in the listing (description, screenshots, icon)
7. Submit for review (takes 1-7 days)

### Apple App Store

1. Go to https://appstoreconnect.apple.com
2. Log in with your Apple Developer account ($99/year)
3. Click "My Apps" → "+" → "New App"
4. Fill in app details
5. Upload the IPA via Transporter (see Part 4c)
6. Fill in the listing (description, screenshots, icon)
7. Submit for review (takes 1-3 days)

---

## EASIEST OPTION: Use a Cloud Build Service

If the steps above feel overwhelming, use **Codemagic** — it builds Flutter apps in the cloud with a visual interface (no Terminal needed for builds):

1. Go to https://codemagic.io/ and sign up (free tier: 500 build minutes/month)
2. Connect your code repository (push your project to GitHub first)
3. Codemagic will detect it's a Flutter project
4. Click "Start Build" → it builds both APK and IPA in the cloud
5. Download the APK and IPA from the Codemagic dashboard

**This is the easiest way if you don't want to install any development tools.**

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `flutter doctor` shows errors | Follow the specific instructions it shows for each error |
| "No connected devices" | Connect a phone via USB, or start an Android emulator in Android Studio |
| APK installs but shows white screen | Check that backend API changes are deployed and working |
| "Signing failed" on iOS | Make sure you selected a Team in Xcode signing settings |
| Network errors in app | Verify the CORS fix was applied to Security.php on your server |
| Build fails with dependency errors | Run `flutter clean` then `flutter pub get` then try again |

---

## File Quick Reference

```
Your project folder:
audley_achievers/
├── lib/                 ← All Dart source code (the app)
├── android/             ← Android-specific config
├── ios/                 ← iOS-specific config
├── assets/              ← App icon, etc.
├── pubspec.yaml         ← Dependencies list
└── BUILD_GUIDE.md       ← This file

Output files after building:
├── build/app/outputs/flutter-apk/app-release.apk    ← Android APK
├── build/app/outputs/bundle/release/app-release.aab  ← Android AAB (Play Store)
└── build/ios/ipa/audley_achievers.ipa                ← iOS IPA
```

# ⚡ QUICKSTART — Fastest Path to APK & IPA

## THE ABSOLUTE EASIEST WAY (No coding tools needed)

### Option A: Use Codemagic (Cloud Build — Recommended for beginners)

1. **Create a free GitHub account** at https://github.com (if you don't have one)
2. **Upload this project** to a new GitHub repository:
   - Go to https://github.com/new
   - Name it `audley-achievers-app`
   - Upload all files from the `audley_achievers/` folder
3. **Go to https://codemagic.io** → Sign up with your GitHub account (free)
4. **Add your repository** → Codemagic detects it as a Flutter project
5. **Click "Start new build"** → Select Android + iOS
6. **Download the APK and IPA** from the build results

That's it. No installs, no Terminal commands.

---

### Option B: Build on your computer (5 commands)

#### Step 1: Install Flutter (one time)

**Windows:** Download from https://docs.flutter.dev/get-started/install
**Mac:** Open Terminal, run: `brew install flutter`

Then install Android Studio from https://developer.android.com/studio

#### Step 2: Deploy backend changes

Upload the 2 files from `backend-additions/api/` to your web server's `/api/` folder.
(See BACKEND_SETUP.md for details — this takes 5 minutes.)

#### Step 3: Build APK (copy-paste these 3 commands)

Open Terminal / Command Prompt, then:

```bash
cd path/to/audley_achievers

flutter pub get

flutter build apk --debug
```

Your APK is now at: `build/app/outputs/flutter-apk/app-debug.apk`

Transfer it to any Android phone and install.

#### Step 4: Build IPA (Mac only — copy-paste these 3 commands)

```bash
cd path/to/audley_achievers

flutter pub get

flutter build ipa --release
```

Your IPA is at: `build/ios/ipa/audley_achievers.ipa`

---

### ⚠️ IMPORTANT: First-time Flutter setup

If `flutter build` fails, run these first:

```bash
flutter doctor --android-licenses    # Accept all with 'y'
flutter doctor                       # Check what's missing
```

Fix whatever `flutter doctor` flags, then try building again.

See `BUILD_GUIDE.md` for the full detailed guide with screenshots-level detail.

# Fix App Name in Drawer

The app drawer shows "audley_achievers" because Flutter auto-generates it from the package name.

## Quick Fix — Change ONE line in your existing project:

Open: `android/app/src/main/AndroidManifest.xml`

Find this line:
```
android:label="audley_achievers"
```

Change it to:
```
android:label="Audley's Top Performers Incentive"
```

## For iOS:

Open: `ios/Runner/Info.plist`

Add inside the `<dict>` block:
```xml
<key>CFBundleDisplayName</key>
<string>Audley's Top Performers Incentive</string>
```

Then rebuild the app.

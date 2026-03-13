# Safe Scales

A gamified education app for teaching social media literacy and safety.

## Download

📱 [Download for Android](https://khalilfadi.github.io/safeScales-App/) - Download the latest version directly to your Android device.

## Development

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio / Android SDK
- Xcode (for iOS development)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/khalilfadi/safeScales-App.git
cd safeScales-App
```

2. Install dependencies:
```bash
flutter pub get
```

3. For local Android builds, create a keystore file:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

4. Create `android/key.properties` (not tracked in git):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=~/upload-keystore.jks
```

5. Run the app:
```bash
flutter run
```

## Releases

This project uses GitHub Actions to automate releases. When you push a tag, it automatically builds and releases a signed APK.

### Creating a Release

1. Update version in `pubspec.yaml`:
```yaml
version: 0.9.3+5
```

2. Commit changes:
```bash
git add pubspec.yaml
git commit -m "Bump version to 0.9.3"
```

3. Create and push a tag:
```bash
git tag v0.9.3
git push origin v0.9.3
```

4. GitHub Actions will automatically:
   - Build the release APK
   - Sign it with your keystore
   - Create a GitHub Release
   - Upload the APK

### Required GitHub Secrets

For automated releases, you need to configure these secrets in your GitHub repository (Settings → Secrets):

- `ANDROID_KEYSTORE_BASE64`: Base64-encoded keystore file
  - Encode: `base64 -i ~/upload-keystore.jks | pbcopy` (macOS/Linux)
- `KEYSTORE_PASSWORD`: Your keystore password
- `KEY_ALIAS`: Your key alias (usually "upload")
- `KEY_PASSWORD`: Your key password

### Enabling GitHub Pages

To host the download page:

1. Go to repository Settings → Pages
2. Source: Deploy from a branch
3. Branch: `main` (or `master`)
4. Folder: `/docs`
5. Save

Your download page will be available at:
```
https://khalilfadi.github.io/safeScales-App/
```

## Building Locally

### Android (APK or App Bundle for Play Store)
```bash
flutter build apk --release
# or for Play Store upload:
flutter build appbundle --release
```

- **APK** output: `build/app/outputs/flutter-apk/app-release.apk`
- **App Bundle** (Play Store): `build/app/outputs/bundle/release/app-release.aab`

If no release keystore is configured, the release build uses the debug keystore so the build succeeds. **Play Store rejects debug-signed bundles**; you must sign in release mode.

**Signing for Play Store (release mode):**

1. **Create a release keystore (one-time).** From a terminal:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Use a strong password and remember it; you need it for every future release of this app.

2. **Create `android/key.properties`** (file is gitignored). Copy from `android/key.properties.example` and set:
   - `storeFile`: absolute path to the keystore (e.g. `/Users/yourname/upload-keystore.jks`; use the real path, not `~`)
   - `storePassword`, `keyAlias`, `keyPassword`: the values you used in step 1 (alias is often `upload`)

3. **Rebuild and upload:**
   ```bash
   flutter build appbundle --release
   ```
   Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

### iOS (requires Mac)
```bash
flutter build ipa --release
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[Your License Here]
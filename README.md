# Safe Scales

A gamified education app for teaching social media literacy and safety.

## Download

- **GitHub Pages** (recommended for **public** repositories): enable Pages in the repo settings (see [Enabling GitHub Pages](#enabling-github-pages)), then share: [https://BYU-STAPL.github.io/SafeScales/](https://BYU-STAPL.github.io/SafeScales/). No tokens required; the page uses GitHub’s public API for the latest release and APK link.
- **Vercel** (useful for **private** repos or custom domains): see [Hosting the download page on Vercel](#hosting-the-download-page-on-vercel).

## Development

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio / Android SDK
- Xcode (for iOS development)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/BYU-STAPL/SafeScales.git
cd SafeScales
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

### Troubleshooting: 404 on the APK download link

URLs like `https://github.com/ORG/REPO/releases/latest/download/app-release.apk` only work after there is a **published** GitHub Release whose assets include a file named **`app-release.apk`** (this repo’s workflow uploads that name when the build succeeds).

If you see **404**, there is usually **no successful release** yet: the tag workflow did not run, failed (check **Actions**), or required secrets were missing so the APK was never uploaded.

**What to do:** Push a version tag (`v1.0.0`, etc.), wait for **Build and Release APK** to finish green, then open **Releases** on the repo and confirm the APK appears under **Assets**. After that, the download page can resolve the correct link via the GitHub API.

### Hosting the download page on Vercel

Use this when the GitHub repository is **private** (or whenever you prefer Vercel over GitHub Pages). The static files in [`docs/`](docs/) are copied into `public/` at build time; serverless routes in [`api/`](api/) call the GitHub API with a secret token so release metadata and APK downloads work without making the repo public.

1. Push the repository to GitHub and [import it on Vercel](https://vercel.com/new) using the GitHub integration (private repos are supported).
2. Vercel picks up [`vercel.json`](vercel.json): install runs `npm install`, build runs `npm run build` (copies `docs/` to `public/`), and static output is served from `public/`.
3. In the Vercel project, open **Settings → Environment Variables** and add:
   - **`GITHUB_TOKEN`** — a [GitHub personal access token](https://github.com/settings/tokens) that can read this repository’s releases. For a private repo, a **classic** token with the `repo` scope is typical; a **fine-grained** token should include **Contents** and **Metadata** read access for this repository.
4. Apply the variable to **Production** (and **Preview** if you want preview deployments to work), then trigger a new deployment.

Optional variables if the defaults are wrong: **`GITHUB_REPO_OWNER`**, **`GITHUB_REPO_NAME`**, or **`GITHUB_REPOSITORY`** (`owner/name`). Otherwise the app uses `BYU-STAPL` / `SafeScales` or Vercel’s Git metadata when available.

**Avoiding GitHub in the browser (recommended for a clean download UX):** Vercel cannot stream large APKs through a serverless function (response size limits), so the default flow redirects the browser to GitHub’s file URL after a server-side API call. To **never** send users to `github.com` for the file, host the APK on a **public URL** you control and set:

- **`PUBLIC_APK_URL`** — full HTTPS URL to the `.apk` file (for example [Vercel Blob](https://vercel.com/docs/storage/vercel-blob), AWS S3, Cloudflare R2, or any static host). The download button and `/api/download-apk` will point there instead of GitHub.
- **`RELEASE_TAG`** (optional) — e.g. `v0.9.3`, shown on the page as the version. If omitted, the server still uses **`GITHUB_TOKEN`** only to read the latest release tag (no GitHub URL in the user’s browser). If you set **`RELEASE_TAG`** and **`PUBLIC_APK_URL`** but omit **`GITHUB_TOKEN`**, the page shows the version without calling GitHub at all.

**How it works (default):** `/api/latest-release` returns the release tag for the page. `/api/download-apk` uses the token server-side and responds with **302** to GitHub’s temporary asset URL so the APK is not streamed through Vercel’s function response size limit.

**How it works (with `PUBLIC_APK_URL`):** The download link goes straight to your hosted file; GitHub is not involved in the browser request.

Local preview: install the [Vercel CLI](https://vercel.com/docs/cli) and run `vercel dev` from the repo root (set `GITHUB_TOKEN` in `.env.local` for testing).

### Enabling GitHub Pages

Repository maintainers enable hosting once (this cannot be done from git alone). Use **one** of these (not both):

**Option A — Deploy from a branch**

1. **Settings** → **Pages**
2. **Build and deployment** → **Source:** **Deploy from a branch**
3. **Branch:** `main`, **Folder:** `/docs`
4. Save and wait a few minutes

**Option B — GitHub Actions** (uses [`.github/workflows/pages.yml`](.github/workflows/pages.yml))

1. **Settings** → **Pages**
2. **Source:** **GitHub Actions**
3. Push to `main` (or run the **Deploy GitHub Pages** workflow manually). The workflow uploads the [`docs/`](docs/) folder as the site root.

If you switch sources, pick only one; leaving two mechanisms fighting each other can cause confusing results.

**404 on the Pages URL?**

- Confirm the URL includes the **repository name**: `https://byu-stapl.github.io/SafeScales/` (hostname is lowercase; trailing slash is fine).
- Under **Pages**, check **Build and deployment** for errors and that the selected source matches how you deploy (`/docs` on `main` *or* the Actions workflow above).
- Ensure `docs/index.html` exists on the branch you deploy (usually `main`).
- After changing settings, wait a few minutes and try a private/incognito window (cached 404s happen).

Your download page will be available at:

```
https://BYU-STAPL.github.io/SafeScales/
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
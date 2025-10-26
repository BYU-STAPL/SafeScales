# GitHub Repository Setup Guide

This guide walks you through setting up automated Android releases using GitHub Actions.

## Step 1: Generate Android Keystore

First, create a keystore file for signing your Android app:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted to enter:
- A password for the keystore (remember this!)
- Your name, organization, city, state, country
- A password for the key alias (can be the same as keystore password)

**Important:** Keep this file safe! You'll need it for future releases.

## Step 2: Encode Keystore for GitHub Secrets

Encode your keystore to base64:

```bash
base64 -i ~/upload-keystore.jks | pbcopy
```

This copies the encoded keystore to your clipboard.

## Step 3: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

   ### ANDROID_KEYSTORE_BASE64
   - Name: `ANDROID_KEYSTORE_BASE64`
   - Value: Paste the base64-encoded keystore from Step 2

   ### KEYSTORE_PASSWORD
   - Name: `KEYSTORE_PASSWORD`
   - Value: Your keystore password

   ### KEY_ALIAS
   - Name: `KEY_ALIAS`
   - Value: `upload`

   ### KEY_PASSWORD
   - Name: `KEY_PASSWORD`
   - Value: Your key alias password (usually same as KEYSTORE_PASSWORD)

## Step 4: Update Repository Placeholders

Replace the placeholders in these files with your actual GitHub repository details:

### Files to Update:

1. **docs/index.html**
   - Replace `YOUR_USERNAME` with your GitHub username
   - Replace `YOUR_REPO` with your repository name

2. **README.md**
   - Replace `YOUR_USERNAME` with your GitHub username
   - Replace `YOUR_REPO` with your repository name

## Step 5: Enable GitHub Pages

1. Go to repository **Settings** → **Pages**
2. Under **Source**, select **Deploy from a branch**
3. Select branch: `main` (or `master`)
4. Select folder: `/docs`
5. Click **Save**

Your download page will be available at:
```
https://YOUR_USERNAME.github.io/YOUR_REPO/
```

## Step 6: Create Your First Release

1. Make sure your code is committed and pushed:
   ```bash
   git add .
   git commit -m "Initial release setup"
   git push origin main
   ```

2. Update version in `pubspec.yaml`:
   ```yaml
   version: 0.9.2+4
   ```

3. Commit the version change:
   ```bash
   git add pubspec.yaml
   git commit -m "Bump version to 0.9.2"
   git push origin main
   ```

4. Create and push a tag:
   ```bash
   git tag v0.9.2
   git push origin v0.9.2
   ```

5. Monitor the GitHub Actions workflow:
   - Go to **Actions** tab in your repository
   - Watch the workflow build and create the release
   - Once complete, the release will be available on the **Releases** page

## Testing the Download Page

After your first release is created:

1. Visit: `https://YOUR_USERNAME.github.io/YOUR_REPO/`
2. Verify the download button works
3. Test downloading the APK on an Android device

## Troubleshooting

### Build Fails
- Verify all GitHub Secrets are set correctly
- Check that the keystore base64 encoding is correct
- Ensure Flutter version matches in workflow file

### Download Button Not Working
- Verify GitHub Pages is enabled
- Check that the JavaScript can fetch release info
- Make sure a release exists with an APK attached

### Keystore Issues
- Ensure keystore file path is correct
- Verify passwords match what's in GitHub Secrets
- Check that key alias is "upload"

## Future Releases

For each new release:

1. Update `pubspec.yaml` version
2. Commit and push
3. Create and push a new tag (e.g., `git tag v0.9.3`)
4. GitHub Actions handles the rest!

## Security Notes

- Never commit the keystore file to git (it's in .gitignore)
- Keep your keystore file secure and backed up
- Don't share GitHub Secrets
- Rotate secrets if they're compromised

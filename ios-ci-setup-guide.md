# iOS CI/CD Setup Guide (No Mac Required for Setup)

This explains how to generate everything the GitHub Actions workflow needs.
You do **not** need a physical Mac for any of this — `openssl` works fine on
Linux/Windows, and everything else happens on Apple's website or the runner itself.

## 1. Generate a Certificate Signing Request (CSR) with openssl

```bash
openssl genrsa -out ios_distribution.key 2048
openssl req -new -key ios_distribution.key -out ios_distribution.csr \
  -subj "/emailAddress=you@example.com, CN=Your Name, C=US"
```

This gives you `ios_distribution.csr` (upload to Apple) and `ios_distribution.key`
(keep this private — you'll need it later).

## 2. Create a Distribution Certificate

1. Go to **developer.apple.com → Certificates, Identifiers & Profiles → Certificates → "+"**.
2. Choose **Apple Distribution**.
3. Upload `ios_distribution.csr`.
4. Download the resulting `.cer` file.

## 3. Convert the certificate to a `.p12` file

```bash
openssl x509 -in distribution.cer -inform DER -out distribution.pem -outform PEM
openssl pkcs12 -export -inkey ios_distribution.key -in distribution.pem \
  -out distribution.p12 -passout pass:YOUR_P12_PASSWORD
```

## 4. Register your App ID and create a Provisioning Profile

1. **Identifiers → "+"** — register your Bundle ID (must match `pubspec.yaml`/Xcode project, e.g. `com.yourcompany.yourapp`).
2. **Profiles → "+" → App Store Connect distribution** — select your App ID and the distribution certificate from step 2. Download the `.mobileprovision` file.

## 5. Create an App Store Connect API Key (for automated uploads)

1. Go to **App Store Connect → Users and Access → Integrations → App Store Connect API**.
2. Click **"+"**, give it **App Manager** access.
3. Download the `.p8` key file **immediately** — Apple only lets you download it once.
4. Note the **Key ID** and **Issuer ID** shown on that page.

## 6. Base64-encode everything for GitHub Secrets

```bash
base64 -i distribution.p12 | pbcopy        # macOS
base64 -w 0 distribution.p12               # Linux (prints to terminal)
```

Do the same for:
- `distribution.p12` → `BUILD_CERTIFICATE_BASE64`
- `profile.mobileprovision` → `BUILD_PROVISION_PROFILE_BASE64`
- `AuthKey_XXXXXXXXXX.p8` → `APP_STORE_CONNECT_API_KEY_BASE64`

## 7. Add GitHub Secrets

In your repo: **Settings → Secrets and variables → Actions → New repository secret**

| Secret name | Value |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | base64 of `distribution.p12` |
| `P12_PASSWORD` | the password you set in step 3 |
| `BUILD_PROVISION_PROFILE_BASE64` | base64 of `.mobileprovision` |
| `KEYCHAIN_PASSWORD` | any password — used only to lock the temporary CI keychain |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID from step 5 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from step 5 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | base64 of the `.p8` file |

## 8. Update `ios/ExportOptions.plist`

Fill in your actual:
- `teamID` (found in Apple Developer portal → Membership)
- Bundle ID → provisioning profile name mapping

## 9. Trigger the workflow

- Push a tag like `v1.0.0`, or
- Run it manually from the **Actions** tab (`workflow_dispatch`)

The build will land in **TestFlight** automatically once the workflow succeeds.
From there, promoting to a full App Store release is still done manually in
App Store Connect (add release notes, submit for review).

## Notes & gotchas

- **Certificate expiry**: Distribution certificates last 1 year — you'll need to repeat steps 1–3 (and re-update the secret) annually.
- **Provisioning profile expiry**: Also expires; same story.
- **Flutter version pin**: Match the `flutter-version` in the workflow to what your project actually uses (`flutter --version` locally) to avoid subtle build differences.
- **First build will be slow**: CocoaPods + Xcode indexing on a fresh runner takes a few minutes; subsequent builds can be sped up with caching (`actions/cache` on `~/.pub-cache`, `ios/Pods`, and CocoaPods cache) if you want to optimize later.
- **Alternative to `altool`**: Apple is deprecating `altool` in favor of `xcrun notarytool`/newer upload tools for some flows — for TestFlight uploads specifically, `altool` still works as of this writing, but consider using **Fastlane's `pilot`/`deliver`** actions instead if you want more robust error handling and retry logic long-term.

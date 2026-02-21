# Google OAuth Setup for Civic Contribution + Supabase

Complete end-to-end guide to enable Google Sign-In on your Flutter app.

---

## Part 1: Google Cloud Console Setup

### 1.1 Create/Select a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. At the top, click the **Project Selector** dropdown
3. Click **NEW PROJECT**
4. Name: `Civic Contribution` (or your preferred name)
5. Click **CREATE**
6. Wait ~1 minute for the project to initialize

### 1.2 Enable Google+ API

1. In left sidebar, click **APIs & Services** → **Library**
2. Search for `Google+ API`
3. Click the result and then click **ENABLE**
4. Wait a few seconds for it to activate

### 1.3 Create OAuth 2.0 Credentials

1. In left sidebar, click **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** (top)
3. Select **OAuth client ID**
4. A dialog may say "Configure the OAuth consent screen first" → click **CONFIGURE CONSENT SCREEN**

#### 1.3.1 Configure OAuth Consent Screen

1. Choose **External** for User Type, click **CREATE**
2. **App name**: `Civic Contribution`
3. **User support email**: use your email
4. **Developer contact information**: use your email
5. Click **SAVE AND CONTINUE**
6. On "Scopes" page: click **SAVE AND CONTINUE** (defaults are fine)
7. On "Test users" page: click **ADD USERS** and add your test Gmail address, then **SAVE AND CONTINUE**
8. Review and click **BACK TO DASHBOARD**

#### 1.3.2 Create Android OAuth Client

1. Go back to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Application type: **Android**
4. Name: `Civic Contribution Android`
5. Under "Package name", enter: `com.hackathon.civic_contribution`
6. Under "SHA-1 certificate fingerprint", run this command on your PC:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA1** value (looks like `AA:BB:CC:DD:...`)

7. Paste into the SHA-1 field (without colons, e.g., `AABBCCDD...`)
8. Click **CREATE**
9. A popup shows your **Client ID** (looks like `123456789-abcd...apps.googleusercontent.com`)
10. **Copy this Client ID** — you'll need it for Supabase

---

## Part 2: Supabase Configuration

### 2.1 Enable Google Provider

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Left sidebar: **Authentication** → **Providers**
4. Find **Google** and click it
5. Toggle **Enabled** to ON
6. In **Client ID** field, paste the Google Client ID from Part 1.3.2 step 9
7. In **Client Secret** field:
   - Go back to Google Cloud Console
   - **APIs & Services** → **Credentials**
   - Click the Android OAuth client you just created
   - Copy the **Client Secret** (looks like `gcp_...`)
   - Paste into Supabase **Client Secret**
8. Click **SAVE**

### 2.2 Configure Redirect URLs

1. In Supabase, left sidebar: **Authentication** → **URL Configuration**
2. Under **Redirect URLs**, click **+ Add URL**
3. Add this URL:
   ```
   io.supabase.flutter://login-callback
   ```
4. Click **Add URL** again and add:
   ```
   https://<your-project-ref>.supabase.co/auth/v1/callback
   ```
   (Replace `<your-project-ref>` with your actual Supabase project reference from the dashboard URL)
5. Click **Save**

### 2.3 Configure Site URL

1. Still in **URL Configuration**, find **Site URL**
2. Set it to your app's deep link base:
   ```
   io.supabase.flutter://
   ```
3. Click **Save**

---

## Part 3: Verify Your Setup

### 3.1 Check Supabase Project Details

1. In Supabase Dashboard, click **Project Settings** (gear icon, top-right)
2. Copy your **Project Reference** (e.g., `abcdefgh123456`)
3. Copy your **Project URL** (e.g., `https://abcdefgh123456.supabase.co`)

These should already be in your `lib/core/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://abcdefgh123456.supabase.co';
  static const String anonKey = '...your-anon-key...';
  
  static SupabaseClient get client => Supabase.instance.client;
}
```

If not, update them now.

### 3.2 Verify Android Manifest Deep Link

Check [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml):

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="io.supabase.flutter" android:host="login-callback"/>
</intent-filter>
```

Should already be present; if not, add it inside the `<activity>` block.

### 3.3 Verify Auth Service OAuth Call

Check [lib/data/services/auth_service.dart](lib/data/services/auth_service.dart):

```dart
Future<AuthUser?> signInWithGoogle() async {
  await _client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
  );
  return currentUser;
}
```

Should be present; if not, update it.

---

## Part 4: Test Google Sign-In

### 4.1 Build and Run

```powershell
cd D:\Webathon4.0\civic-contribution

# Kill any lingering ADB
adb kill-server
adb start-server

# Confirm device is authorized (not "unauthorized")
adb devices

# Clean and rebuild
flutter clean
flutter pub get
flutter run --debug
```

### 4.2 Test on Phone

1. Open the app
2. Tap **Continue with Google**
3. You should be redirected to Google Login (browser or native dialog)
4. Sign in with your test Gmail (the one you added in Part 1.3.1)
5. After successful sign-in, the browser/dialog should close and the app should show the home screen (if user data exists in Supabase)

### 4.3 Debug If Sign-In Fails

If sign-in doesn't work:

1. **Check logcat**:
   ```powershell
   adb logcat | grep -i "oauth\|supabase\|auth"
   ```

2. **Check Supabase Auth Logs**:
   - Supabase Dashboard → **Authentication** → **Users**
   - Look for your test user or error logs

3. **Common Issues**:
   - **"Redirect URI mismatch"**: Ensure `io.supabase.flutter://login-callback` is in Supabase URL Configuration
   - **"OAuth client not found"**: Verify Client ID in Supabase matches Google Cloud Console
   - **"Invalid Client Secret"**: Ensure Client Secret is copied correctly (no extra spaces)
   - **"Phone unauthorized"**: Revoke USB debugging auth, reconnect, tap "Always allow"

---

## Part 5: Optional — Add Debug Logging

To see OAuth errors in your app, update [lib/data/services/auth_service.dart](lib/data/services/auth_service.dart):

```dart
Future<AuthUser?> signInWithGoogle() async {
  try {
    debugPrint('[AuthService] Starting Google OAuth...');
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
    );
    final user = currentUser;
    debugPrint('[AuthService] OAuth success: ${user?.email}');
    return user;
  } catch (e) {
    debugPrint('[AuthService] OAuth failed: $e');
    rethrow;
  }
}
```

Then check Flutter console output for `[AuthService]` messages.

---

## Summary Checklist

- [ ] Google Cloud Project created
- [ ] Google+ API enabled
- [ ] Android OAuth Client created with correct SHA1
- [ ] Google Client ID copied
- [ ] Google Client Secret copied
- [ ] Supabase Google provider enabled with Client ID + Secret
- [ ] Redirect URLs configured in Supabase (`io.supabase.flutter://login-callback`)
- [ ] Site URL set in Supabase
- [ ] Supabase config (URL + anonKey) updated in app
- [ ] Android Manifest deep-link intent filter present
- [ ] Auth Service OAuth call checking
- [ ] Phone authorized via ADB
- [ ] App built and deployed

Once all are checked, run the app and test sign-in!

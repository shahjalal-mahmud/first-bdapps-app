# BDApps Subscription Backend — Deployment Guide

A complete, step-by-step walkthrough for deploying the `bdapps_api/`
PHP wrapper to a shared hosting account via cPanel, plugging in your
real BDApps credentials, and verifying that the full SMS / OTP /
subscription / unsubscribe flow works end to end.

> **Read this guide end-to-end before you start.** Skipping the
> preparation steps (especially the ones about SSL, allow_url_fopen
> and outbound HTTPS) is the single most common reason deployments
> fail on shared hosting.

---

## Table of contents

1. [What you will have when you finish](#1-what-you-will-have-when-you-finish)
2. [Before you start — checklist](#2-before-you-start--checklist)
3. [Get your BDApps credentials from BDApps](#3-get-your-bdapps-credentials-from-bdapps)
4. [Locally test the backend (optional but strongly recommended)](#4-locally-test-the-backend-optional-but-strongly-recommended)
5. [Deploy to cPanel](#5-deploy-to-cpanel)
6. [Configure the backend on the server](#6-configure-the-backend-on-the-server)
7. [Update the Flutter client to point at the live backend](#7-update-the-flutter-client-to-point-at-the-live-backend)
8. [Smoke-test every endpoint](#8-smoke-test-every-endpoint)
9. [End-to-end SMS test from your phone](#9-end-to-end-sms-test-from-your-phone)
10. [Troubleshooting](#10-troubleshooting)
11. [Security hardening for production](#11-security-hardening-for-production)
12. [FAQ](#12-faq)

---

## 1. What you will have when you finish

```
https://yourdomain.com/bdapps_api/
├── index.php                     ← Self-documenting landing page
├── config.php                    ← Credentials (you will edit this)
├── bootstrap.php                 ← Helpers
├── subscribers.txt               ← Auto-created local cache
└── api/subscription/
    ├── register.php              ← POST /api/subscription/register
    ├── verify.php                ← POST /api/subscription/verify
    ├── check.php                 ← POST /api/subscription/check
    ├── unsubscribe.php           ← POST /api/subscription/unsubscribe
    └── info.php                  ← GET  /api/subscription/info
```

The Flutter app on your phone will hit these URLs through
`lib/config/app_config.dart::baseUrl`.

---

## 2. Before you start — checklist

Make sure every item below is ticked before you upload anything.

- [ ] A cPanel hosting account with **PHP 7.4 or newer** (the code uses
      `declare(strict_types=1)` and typed signatures — anything older
      than 7.4 will refuse to run).
- [ ] The hosting account has **SSL** enabled and you can reach the
      site via `https://yourdomain.com`. The Flutter app will only
      talk to `https://` URLs in release builds; using `http://` is
      fine for local development only.
- [ ] **Outbound HTTPS is allowed** to `developer.bdapps.com`. Most
      shared hosts allow this by default; some lock it down. See
      [§10 Troubleshooting](#10-troubleshooting) if you see a
      "cURL error 6/7/35" in your logs.
- [ ] The PHP extensions listed below are enabled (cPanel defaults
      include all of them — only check if your host is unusual):
  - `curl`
  - `json`
  - `mbstring`
  - `openssl`
- [ ] You have your BDApps account credentials ready (see
      [§3](#3-get-your-bdapps-credentials-from-bdapps)).
- [ ] A working terminal with `curl` installed (for testing). On
      Windows you can use **PowerShell** (already has `curl`) or
      **Git Bash**.

---

## 3. Get your BDApps credentials from BDApps

You will get four values from the BDApps developer portal. Keep this
page open while you deploy.

| Field in code          | Where to find it                                                                                                                     |
|------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| `BDAPPS_APP_ID`        | BDApps developer portal → your app → "Application ID" (e.g. `APP_138927`)                                                            |
| `BDAPPS_PASSWORD`      | BDApps developer portal → your app → "Application Password" (a 32-character hex string)                                              |
| `BDAPPS_APP_HASH`      | BDApps developer portal → your app → "Application Hash" (a short string you defined when you registered the app — e.g. `Quiz Shell`) |
| `BDAPPS_PRICE_BDT`     | Your product's monthly price (e.g. `30`). The code defaults to `30`; change only if your BDApps product uses a different price.      |
| `BDAPPS_DURATION_DAYS` | Default subscription validity, e.g. `30` days. The code defaults to `30`.                                                            |

> **Important:** when BDApps support gives you a *new* set of
> credentials, the **APP_ID** and **PASSWORD** change too. Always
> update both at once.

---

## 4. Locally test the backend (optional but strongly recommended)

If you can install PHP on your laptop, you can validate the wrapper
before uploading it to cPanel. This is the fastest way to catch typos
in your credentials.

### 4.1 Start PHP's built-in server

```bash
cd path/to/Quiz-Chatbot/bdapps_api
php -S 127.0.0.1:8080 -t .
```

You should see `PHP X.Y.Z Development Server (http://127.0.0.1:8080) started`.

### 4.2 Open the landing page

Visit <http://127.0.0.1:8080/> in your browser. You should see the
self-documenting page listing all five endpoints.

### 4.3 Hit `/api/subscription/info`

```bash
curl http://127.0.0.1:8080/api/subscription/info
```

You should get:

```json
{"success":true,"product":{...},"plan":{"priceBdt":30,...},"operators":[...]}
```

If you see that JSON, the wrapper is wired up correctly. If you see a
blank page or a PHP error, jump to [§10 Troubleshooting](#10-troubleshooting).

---

## 5. Deploy to cPanel

There are two ways to upload the files. **Method A (File Manager) is
easiest for first-time deploys.** Method B (FTP) is faster when you
need to redeploy later.

### Method A — cPanel File Manager (recommended for first deploy)

1. Log in to your cPanel account (usually
   `https://yourdomain.com/cpanel` or `https://yourdomain.com:2083`).
2. Open **File Manager**.
3. In the top-right directory picker, choose **`public_html`**
   (this is your web root). *Do not put the API in a folder above
   `public_html` — it must be reachable from the internet.*
4. Click **`+ Folder`** in the toolbar and create a folder named
   `bdapps_api`. Enter it.
5. Inside `bdapps_api`, create a subfolder named `api`. Enter it.
6. Inside `api`, create a subfolder named `subscription`. Enter it.
7. **Upload** each file to the right location:

   | Local file (from the repo)                    | Upload to (in cPanel)                                     |
   |-----------------------------------------------|-----------------------------------------------------------|
   | `bdapps_api/index.php`                        | `public_html/bdapps_api/index.php`                        |
   | `bdapps_api/config.php`                       | `public_html/bdapps_api/config.php`                       |
   | `bdapps_api/bootstrap.php`                    | `public_html/bdapps_api/bootstrap.php`                    |
   | `bdapps_api/README.md` *(optional)*           | `public_html/bdapps_api/README.md`                        |
   | `bdapps_api/api/subscription/register.php`    | `public_html/bdapps_api/api/subscription/register.php`    |
   | `bdapps_api/api/subscription/verify.php`      | `public_html/bdapps_api/api/subscription/verify.php`      |
   | `bdapps_api/api/subscription/check.php`       | `public_html/bdapps_api/api/subscription/check.php`       |
   | `bdapps_api/api/subscription/unsubscribe.php` | `public_html/bdapps_api/api/subscription/unsubscribe.php` |
   | `bdapps_api/api/subscription/info.php`        | `public_html/bdapps_api/api/subscription/info.php`        |

   > **Tip:** When uploading through File Manager you can drag and drop
   > multiple files at once. After upload, right-click each file →
   > **Permissions** → set to `0644` (the File Manager usually does
   > this automatically).

8. After all files are uploaded, your structure should look like this
   in File Manager:

   ```
   public_html/
   └── bdapps_api/
       ├── api/subscription/{register,verify,check,unsubscribe,info}.php
       ├── bootstrap.php
       ├── config.php
       ├── index.php
       └── README.md
   ```

### Method B — FTP / SFTP

If you have FTP credentials (ask your host or create one under
**cPanel → FTP Accounts**):

1. Open your FTP client (FileZilla, WinSCP, Cyberduck…).
2. Connect to `ftp.yourdomain.com` (or the hostname cPanel shows)
   using **FTP over TLS / SFTP** (port 21 with explicit TLS, or 22
   for SFTP).
3. Navigate to `public_html` and create the same `bdapps_api/api/subscription/`
   folder structure as above.
4. Drag-and-drop the `bdapps_api/` folder from your computer into
   `public_html/`.

### Method C — Git (advanced)

If your host supports SSH and you want automatic deployments, you can
clone the repo into `public_html/bdapps_api/`:

```bash
cd ~/public_html
git clone https://github.com/your-org/Quiz-Chatbot.git temp
cp -r temp/bdapps_api ./bdapps_api
rm -rf temp
```

Then whenever you change credentials, edit
`public_html/bdapps_api/config.php` directly via SSH.

---

## 6. Configure the backend on the server

You have **two options** for plugging in your BDApps credentials.
**Pick one — don't set the same credential in both places.**

### Option 1 — Edit `config.php` directly (simplest)

1. In cPanel File Manager, navigate to `public_html/bdapps_api/`.
2. Right-click `config.php` → **Edit**.
3. Replace the values after `?:` with your real ones from BDApps:

   ```php
   return [
       'app_id'     => 'APP_123456',                   // your real APP_ID
       'password'   => 'your-32-char-hex-password',    // your real password
       'app_hash'   => 'Your App Hash',                // your real hash
       'price_bdt'  => 30,
       'duration_days' => 30,
       'subscribers_file' => __DIR__ . '/subscribers.txt',
   ];
   ```

4. **Save**. File permissions on `config.php` should be `0644`
   (the default after editing through cPanel).

### Option 2 — Set environment variables (more secure)

If your host gives you a "MultiPHP INI Editor" or allows `.user.ini`
uploads (most cPanel hosts do):

1. In cPanel File Manager, go to `public_html/bdapps_api/`.
2. Create a new file called `.user.ini` (note the leading dot).
3. Put this inside it:

   ```ini
   ; BDApps credentials - loaded by config.php via getenv().
   ; Note: cPanel's getenv() returns false for variables set in
   ; .user.ini. The wrapper falls back to the hard-coded defaults
   ; in config.php, so for shared hosting Option 1 is usually easier.
   ```

   > **Reality check:** PHP's `getenv()` does **not** read from
   > `.user.ini` on most shared hosts. For real environment-variable
   > support, you need a VPS / dedicated server where you can edit
   > the Apache/Nginx config or use a `.htaccess` `SetEnv` directive.
   >
   > **On shared hosting, just edit `config.php` directly (Option 1).**
   > Move on to the next step.

### 6.1 Verify the file is reachable

Open this URL in your browser:

```
https://yourdomain.com/bdapps_api/
```

You should see the dark-themed landing page that lists every endpoint.
If you get a `404`, double-check the folder name and that the file
exists at `public_html/bdapps_api/index.php`.

### 6.2 Verify PHP version

cPanel lets you choose the PHP version per folder:

1. In cPanel, open **MultiPHP Manager** (or **Select PHP Version**
   on some hosts).
2. Tick `public_html/bdapps_api` (or set the version for the whole
   `public_html` if you don't have other PHP apps there).
3. Choose **PHP 7.4 or newer** (PHP 8.x is recommended).
4. Click **Apply**.

### 6.3 Allow outbound HTTPS to BDApps (rarely needed)

Most cPanel hosts allow outbound HTTPS by default. If you see cURL
errors later, ask your host to whitelist `developer.bdapps.com` on
outbound port 443.

---

## 7. Update the Flutter client to point at the live backend

1. Open `lib/config/app_config.dart` in your editor.
2. Replace the `baseUrl`:

   ```dart
   /// Production URL - use https in release builds.
   static const String baseUrl = 'https://yourdomain.com/bdapps_api';
   ```

3. Rebuild the Flutter app:

   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release      # Android
   # or
   flutter build ios --release      # iOS (if you have a Mac)
   ```

4. Install the new APK on your phone and open the app. You should see
   the splash screen, then the phone-registration screen.

> **iOS note:** if you ship an iOS build, Apple requires HTTPS for
> arbitrary URLs. If your hosting account is on a shared IP that does
> not have its own SSL certificate yet, install one through cPanel
> (**SSL/TLS Status** → **Run AutoSSL**). Most hosts (Hostinger,
> Bluehost, SiteGround, Namecheap) issue free Let's Encrypt certs.

> **Android cleartext note:** if you ever need to use `http://` for
> debugging on the Android emulator (e.g. `http://10.0.2.2/...`),
> the `usesCleartextTraffic="true"` flag must be enabled in
> `android/app/src/main/AndroidManifest.xml`. The release build should
> always point at `https://`.

---

## 8. Smoke-test every endpoint

Use `curl` from your laptop. Replace `YOURDOMAIN` with your real
domain.

### 8.1 `GET /api/subscription/info` — sanity check

```bash
curl https://yourdomain.com/bdapps_api/api/subscription/info
```

Expected response (200 OK):

```json
{
  "success": true,
  "product": { "name": "Amar Proshno", "description": "..." },
  "plan": { "priceBdt": 30, "currency": "BDT", "durationDays": 30, "autoRenews": true },
  "operators": [
    { "id": "robi",   "label": "Robi",   "prefixes": ["018"] },
    { "id": "airtel", "label": "Airtel", "prefixes": ["016"] }
  ],
  "subscriptionTermsUrl": "https://amarproshno.app/terms"
}
```

If you get this, the wrapper is reachable and PHP is working.

### 8.2 `POST /api/subscription/register` — request OTP

```bash
curl -X POST https://yourdomain.com/bdapps_api/api/subscription/register \
     -H "Content-Type: application/json" \
     -d '{"phone":"01812345678"}'
```

You should immediately get an SMS on that phone number from BDApps
("Your subscription activation code is …"). The response from the API
should be:

```json
{
  "success": true,
  "transactionId": "REF-XXXX-XXXX-XXXX",
  "phone": "01812345678",
  "operator": "robi",
  "message": "OTP request sent. Awaiting subscriber confirmation.",
  "statusCode": "S1000",
  "statusDetail": "Success"
}
```

**Save the `transactionId` for the next step.**

If you get an error, see [§10 Troubleshooting](#10-troubleshooting).

### 8.3 `POST /api/subscription/verify` — confirm OTP

Take the 6-digit OTP from the SMS and run:

```bash
curl -X POST https://yourdomain.com/bdapps_api/api/subscription/verify \
     -H "Content-Type: application/json" \
     -d '{"transactionId":"PASTE_REF_HERE","otp":"123456"}'
```

Expected response:

```json
{
  "success": true,
  "subscriptionActive": true,
  "phone": "01812345678",
  "operator": "robi",
  "expiryDate": "2025-08-15T10:00:00+00:00",
  "subscriptionDate": "2025-07-16T10:00:00+00:00",
  "transactionId": "REF-XXXX",
  "message": "Subscription activated."
}
```

You should also see a `subscribers.txt` file appear next to
`config.php` — it contains your phone number, expiry, and registration
timestamp.

### 8.4 `POST /api/subscription/check` — re-validate

```bash
curl -X POST https://yourdomain.com/bdapps_api/api/subscription/check \
     -H "Content-Type: application/json" \
     -d '{"phone":"01812345678"}'
```

Expected response:

```json
{
  "success": true,
  "subscriptionActive": true,
  "phone": "01812345678",
  "operator": "robi",
  "expiryDate": "2025-08-15T10:00:00+00:00",
  "source": "cache"
}
```

The `"source": "cache"` means the wrapper found your number in
`subscribers.txt` and short-circuited the gateway call. If you delete
the file or wait for the cache to expire, the next call will show
`"source": "gateway"`.

### 8.5 `POST /api/subscription/unsubscribe` — cancel

```bash
curl -X POST https://yourdomain.com/bdapps_api/api/subscription/unsubscribe \
     -H "Content-Type: application/json" \
     -d '{"phone":"01812345678"}'
```

Expected response:

```json
{
  "success": true,
  "phone": "01812345678",
  "operator": "robi",
  "statusCode": "S1000",
  "statusDetail": "...",
  "subscriptionStatus": "UNREGISTERED",
  "message": "Subscription cancelled."
}
```

The corresponding line should be gone from `subscribers.txt`.

### 8.6 Run `/check` again — should be inactive

```bash
curl -X POST https://yourdomain.com/bdapps_api/api/subscription/check \
     -H "Content-Type: application/json" \
     -d '{"phone":"01812345678"}'
```

Expected response:

```json
{
  "success": true,
  "subscriptionActive": false,
  "phone": "01812345678",
  "operator": "robi",
  "expiryDate": null,
  "statusCode": "...",
  "statusDetail": "...",
  "source": "gateway"
}
```

If all five checks pass, your backend is live.

---

## 9. End-to-end SMS test from your phone

This is the real test — the user-visible flow on a physical device.

1. Install the freshly-built APK on a **Robi or Airtel SIM**.
2. Open the app.
3. You should see the splash → phone registration screen.
4. Pick **Robi** or **Airtel**, type your 8-digit local part (the
   screen shows the prefix as `+880 18` / `+880 16`).
5. Tap **CONTINUE**.
6. The subscription screen appears. Tap **SUBSCRIBE NOW**.
7. Within 5–10 seconds you should receive an SMS from BDApps with the
   OTP. (If you don't, see [§10 Troubleshooting](#10-troubleshooting).)
8. Type the OTP into the 6 cells. The first cell auto-focuses.
9. The app verifies the OTP and lands on **Home**.
10. Open the **Settings** screen (top-right gear icon on Home) — you
    should see your phone number, operator, subscription status
    (ACTIVE), subscription date, expiry date, and last validation.
11. Tap **Refresh** — last validation timestamp should update.
12. Tap **Unsubscribe** → confirm. You should be kicked back to the
    subscription screen, and the cache should be empty.

If all of these work, the deployment is complete.

---

## 10. Troubleshooting

### 10.1 "cURL error 6: Could not resolve host" or "error 7: Failed to connect"

**Cause:** the PHP `curl` extension cannot reach
`developer.bdapps.com`. Almost always because outbound DNS / HTTPS is
blocked.

**Fix:**

1. From cPanel → **Terminal** (or SSH), run:
   ```bash
   curl -v https://developer.bdapps.com/subscription/getStatus
   ```
   If you get a response, your host can reach BDApps — the issue is
   inside the PHP script (usually missing `cacert.pem`).
2. Contact your host and ask them to enable outbound HTTPS to
   `developer.bdapps.com:443`.
3. As a workaround, you can try adding this to the top of
   `bootstrap.php` (not recommended for production):
   ```php
   curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
   curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
   ```

### 10.2 "500 Internal Server Error" with no body

**Cause:** PHP fatal error — usually a typo in `config.php` or
missing file permissions.

**Fix:**

1. cPanel → **MultiPHP INI Editor** → set `display_errors = On` and
   `log_errors = On` for the `bdapps_api` folder.
2. cPanel → **Error Log** (under Metrics). Reload the page and read
   the most recent error.
3. Common causes:
   - Missing `subscribers.txt` permissions (the script tries to write
     to it — make the parent folder writable: `chmod 755 bdapps_api`).
   - Missing `mbstring` extension. Enable it under **MultiPHP INI
     Editor → Extensions**.

### 10.3 "Invalid phone number format"

**Cause:** the phone number didn't pass the BDApps validator.

**Fix:** make sure the phone you pass is in `01XXXXXXXXX` format and
starts with `018` (Robi) or `016` (Airtel). The Flutter registration
screen does this normalisation automatically.

### 10.4 OTP not received on the phone

**Cause:** most often **the credentials are wrong** — the BDApps
gateway accepts the request but doesn't actually send the SMS.

**Fix:**

1. Re-check `config.php::password` — every character counts.
2. Make sure `app_id` matches what BDApps gave you. The default
   `APP_138927` is for the SDK sample — your real one will be
   different.
3. Try a different Robi/Airtel number — the gateway may rate-limit
   OTP sends per number per hour.
4. Check `subscribers.txt` — if your number is already there, BDApps
   treats you as "already subscribed" and won't send another OTP.
   Delete the line, or run `/unsubscribe` first, then `/register`
   again.

### 10.5 "OTP verification failed"

**Cause:** the OTP you sent doesn't match what BDApps issued, or it
expired (BDApps OTPs are usually valid for 2 minutes).

**Fix:**

1. Use the OTP within 2 minutes of receiving the SMS.
2. Re-run `/register` to get a fresh OTP if the old one expired.
3. Make sure the JSON you POST contains exactly `"otp":"123456"` (six
   digits, no spaces).

### 10.6 `/check` returns `"subscriptionActive":false` right after `/verify`

**Cause:** the local cache wrote the subscriber, but the BDApps
gateway hasn't propagated the registration yet (it can take a few
seconds).

**Fix:** wait 30 seconds and try `/check` again. The wrapper will then
hit the gateway (because the cache hasn't expired yet — wait until
after the expiry date for the cache to be skipped).

### 10.7 CORS errors from the Flutter web build

**Cause:** the wrapper sets `Access-Control-Allow-Origin: *` so any
origin is allowed — if you still see CORS errors, the browser is
probably trying to hit `OPTIONS` first and the server is rejecting
it.

**Fix:** `bootstrap.php` already handles the `OPTIONS` preflight and
returns `200`. If you still see this error, ensure no plugin / WAF in
cPanel is intercepting `OPTIONS` requests.

### 10.8 The app shows "No internet connection"

**Cause:** the phone cannot reach your cPanel URL.

**Fix:**

1. Confirm the URL is reachable from your laptop's browser.
2. Make sure `lib/config/app_config.dart::baseUrl` uses `https://`
   and matches the deployed URL exactly (no trailing slash).
3. Rebuild the APK after editing `app_config.dart`.

---

## 11. Security hardening for production

These are **strongly recommended** before you ship to real users.

1. **Move `config.php` outside `public_html`** if your host allows
   it. Create `private/bdapps_config.php` at the same level as
   `public_html`, then in `bdapps_api/config.php`:
   ```php
   return require __DIR__ . '/../../private/bdapps_config.php';
   ```
2. **Restrict CORS.** Change `*` in `bootstrap.php` to your app's
   domain (only relevant if you build a web client).
3. **Add basic rate limiting.** Drop a `fail2ban`-style rule in
   `.htaccess` so a single IP can't hammer `/register`:
   ```apache
   <IfModule mod_rewrite.c>
       RewriteEngine On
       RewriteCond %{REQUEST_METHOD} POST
       RewriteRule .* - [E=rate-limited:1]
   </IfModule>
   ```
   For more complete protection, use cPanel's **ModSecurity** with
   the OWASP ruleset (already on by default on most hosts).
4. **Keep `subscribers.txt` private.** It contains user phone
   numbers. Make sure it's `chmod 644` (owner read/write, group and
   others read) — writeable by PHP, but not writable by the world.
5. **Rotate the BDApps password** every quarter. Update
   `config.php` after rotation and redeploy.
6. **Enable HSTS** in cPanel → **SSL/TLS Status** → **HSTS**.

---

## 12. FAQ

**Q: I have a different URL for testing and production. How do I keep
both?**
A: Use Flutter's `--dart-define` to override the base URL at build
time:
```dart
static const String baseUrl = String.fromEnvironment(
  'BDAPPS_BASE_URL',
  defaultValue: 'https://yourdomain.com/bdapps_api',
);
```
Then build with:
```bash
flutter build apk --release --dart-define=BDAPPS_BASE_URL=https://staging.yourdomain.com/bdapps_api
```

**Q: Can I deploy this to a non-cPanel host?**
A: Yes. The wrapper has zero cPanel-specific code. Drop
`bdapps_api/` into any PHP 7.4+ web root (Apache, Nginx + PHP-FPM,
Litespeed, OpenLiteSpeed, IIS).

**Q: Do I need to import `BDApps_SDK/` into `bdapps_api/`?**
A: No. The wrapper makes outbound HTTPS calls directly to
`developer.bdapps.com`. The `BDApps_SDK/` folder is for reference
only and stays in your repo untouched.

**Q: My host blocks outbound HTTPS. What now?**
A: You'll need to switch to a host that allows outbound HTTPS to
BDApps. Almost all mainstream shared hosts (Hostinger, Bluehost,
SiteGround, Namecheap, A2Hosting, Dreamhost, GoDaddy) allow it by
default. If yours doesn't, contact support before switching.

**Q: How do I check the BDApps gateway is reachable from my host?**
A: From cPanel → **Terminal**:
```bash
curl -I https://developer.bdapps.com/subscription/getStatus
```
If you see `HTTP/2 405` (Method Not Allowed is expected because we
sent `HEAD` not `POST`), the gateway is reachable.

**Q: How long does an OTP stay valid?**
A: BDApps sets this. Typical validity is 1–2 minutes. Always tell
users to enter the OTP quickly.

**Q: How do I add a new operator (e.g. Grameenphone)?**
A: Update `bdapps_operator_from_phone()` in `bootstrap.php` and the
list in `info.php`, then redeploy.

**Q: The phone number 014XXXXXXXX works locally but not on the
server. Why?**
A: Because the wrapper currently only accepts Robi/Airtel numbers.
If you need GP/Banglalink/Teletalk, ask BDApps to enable those
operators on your app and update the regex in
`bdapps_normalise_phone()`.

---

### You're done!

If every step above succeeded, your production backend is live at
`https://yourdomain.com/bdapps_api/`, your Flutter app talks to it
over HTTPS, and the full BDApps subscription flow (phone registration
→ OTP → home → settings → unsubscribe → re-subscribe) works end to
end.

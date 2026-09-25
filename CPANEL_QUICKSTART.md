# CrowdCAD cPanel Quick Start

This deployment keeps CrowdCAD's supported **Firebase backend** and packages its existing Next.js standalone output so the web application can run under cPanel/Passenger without compiling on the hosting account.

## A. One-time GitHub preparation

1. This repository is already the CrowdCAD fork.
2. In GitHub, open **Settings > Secrets and variables > Actions > Variables**.
3. Add the Firebase Web App values:
   - `NEXT_PUBLIC_FIREBASE_API_KEY`
   - `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
   - `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
   - `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
   - `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
   - `NEXT_PUBLIC_FIREBASE_APP_ID`
   - `NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID` (optional)
4. Open **Actions > Build cPanel deployment > Run workflow**.
5. When green, download the `crowdcad-cpanel` artifact and extract it locally.

The workflow is manual-only until you choose to enable automatic rebuilds. This avoids failed builds before the Firebase variables have been configured.

## B. cPanel first install

1. Create a subdomain, for example `cad.example.org`, and enable HTTPS/AutoSSL.
2. Open **Setup Node.js App** (sometimes called **Application Manager**).
3. Create the application:
   - Node.js: `20.x`
   - Mode: `Production`
   - Application root: `crowdcad`
   - Application URL: the chosen subdomain
   - Startup file: `server.js`
4. In File Manager, open the application root (for example `/home/CPANELUSER/crowdcad`).
5. Upload the contents of the GitHub Actions artifact **into that directory**. `server.js` must be directly inside the application root, not one folder deeper.
6. Add cPanel environment variables:
   - `NODE_ENV=production`
   - `HOSTNAME=0.0.0.0`
   - `NEXT_TELEMETRY_DISABLED=1`
   - `DISABLE_TELEMETRY=true`
7. Do not manually set `PORT`; Passenger/cPanel supplies it.
8. Restart the application from cPanel.

If cPanel provides a Terminal, verify the upload:

```bash
cd ~/crowdcad
bash scripts/verify-cpanel-bundle.sh .
```

## C. Firebase setup that must also exist

The cPanel web server does not replace CrowdCAD's backend. For this build, Firebase provides authentication, Firestore and Storage. Follow CrowdCAD's official Firebase setup guide for the Firebase project and rules. Use a dedicated Firebase project for this deployment. Never put service-account private keys into `NEXT_PUBLIC_*` variables.

## D. First smoke test

After restart:

1. Browse to the HTTPS application URL.
2. Confirm the login/sign-up screen loads and CSS/images render.
3. Create a test account.
4. Create a test event/venue.
5. Create and edit a dispatch log/item.
6. Open a second browser/private window and verify changes sync.
7. Upload/open an attachment if that feature is enabled in your workflow.
8. Check cPanel **Errors**, application logs, and browser developer console for errors.

## E. Updating later

1. Sync upstream CrowdCAD changes into this fork.
2. Run **Build cPanel deployment** again.
3. Download the new `crowdcad-cpanel` artifact.
4. Back up the existing cPanel application directory/environment configuration.
5. Replace the runtime files with the new artifact.
6. Restart the app.
7. Repeat the smoke test.

Do not copy `.git`, Docker data, Playwright browsers, test reports or a full development `node_modules` tree to cPanel. The standalone artifact already contains the minimal production runtime.

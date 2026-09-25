# CrowdCAD — cPanel deployment port

This repository includes a deployment flow for shared cPanel hosting with **Setup Node.js App / Application Manager**.

## Why this approach

CrowdCAD is Next.js 15 and already has `output: 'standalone'` in `next.config.js`. The standalone build contains the production server plus the minimal `node_modules` required to run it. This means cPanel does **not** need Docker and does not need to compile the full application on the hosting account.

The deployment layout is:

1. Keep source in this GitHub fork.
2. GitHub Actions builds the application on Ubuntu/Node 20.
3. The action creates `dist-cpanel/` from `.next/standalone` and adds `.next/static` + `public`.
4. Download the `crowdcad-cpanel` action artifact.
5. Upload/extract that artifact into the cPanel Node app root.
6. cPanel launches the included `server.js`.

This is materially lighter and more reliable than `npm install && npm run build` on shared hosting.

## 1. Configure GitHub repository variables

Open **Settings → Secrets and variables → Actions → Variables** and create:

- `NEXT_PUBLIC_FIREBASE_API_KEY`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET`
- `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID`
- `NEXT_PUBLIC_FIREBASE_APP_ID`
- `NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID` (optional)

These are Firebase web-client configuration values. `NEXT_PUBLIC_*` values are embedded at build time by Next.js.

Do **not** place SMTP passwords or service-account private keys in public `NEXT_PUBLIC_*` variables.

## 2. Build

Open **Actions → Build cPanel deployment → Run workflow**.

On success, download the artifact named:

`crowdcad-cpanel`

The extracted artifact should contain at least:

- `server.js`
- `package.json`
- `node_modules/` (minimal standalone runtime dependencies)
- `.next/`
- `public/`
- `tmp/`
- `CPANEL_RUNTIME.txt`

## 3. Create the cPanel Node application

In **Setup Node.js App** / **Application Manager**:

- Node.js version: **20.x** (use the closest supported Node 20 release)
- Application mode: **Production**
- Application root: e.g. `crowdcad`
- Application URL: your chosen domain/subdomain
- Application startup file: **`server.js`**

Upload/extract the artifact contents directly into that application root so that `server.js` is at the root.

Do not run `npm install` against the deployment bundle unless you have intentionally removed the bundled standalone `node_modules`.

## 4. Runtime environment variables in cPanel

Set:

```env
NODE_ENV=production
HOSTNAME=0.0.0.0
NEXT_TELEMETRY_DISABLED=1
DISABLE_TELEMETRY=true
```

Optional contact-form email configuration:

```env
SMTP_HOST=mail.yourdomain.tld
SMTP_PORT=587
SMTP_USER=cad@yourdomain.tld
SMTP_PASS=your-mailbox-password-or-app-password
CONTACT_FROM=CrowdCAD <cad@yourdomain.tld>
CONTACT_TO=admin@yourdomain.tld
```

The `PORT` value should normally be left to cPanel/Passenger. Next's generated standalone `server.js` respects `process.env.PORT`.

## 5. Restart

Use the cPanel **Restart** control. On Passenger-based hosting, touching `tmp/restart.txt` is also commonly supported:

```bash
mkdir -p tmp
touch tmp/restart.txt
```

## 6. Smoke test

Test in this order:

1. Root page loads without a 500/502 error.
2. Static images/styles load.
3. Login works.
4. Create a test event.
5. Create/update a dispatch item.
6. Open a second browser/device and confirm real-time updates through Firebase.
7. If configured, test the contact form and inspect cPanel application logs for SMTP errors.

## Updating CrowdCAD

When upstream changes are synced into this fork, run the cPanel workflow again to create a new artifact. Replace the previous deployment bundle in cPanel and restart the application.

Do not copy `.git`, tests, Playwright browsers, Docker images or development dependencies into the cPanel runtime folder.

## Backend position

This cPanel port intentionally keeps CrowdCAD's existing, tested **Firebase backend** for the first deployment. The UI/runtime is hosted on cPanel, while authentication/data/storage remain in your Firebase project.

A native cPanel backend is feasible because CrowdCAD already exposes `IAuthService`, `IDbService`, and `IStorageService` adapters. A future `mysql` adapter can target cPanel MySQL/MariaDB, with uploaded files stored in a private application directory. That is a larger backend implementation and migration project and should be developed/tested separately rather than mixed into the initial hosting port.

## Security notes

- Use HTTPS only.
- Never commit `.env.local`, SMTP passwords, Firebase Admin service-account JSON or database passwords.
- Apply CrowdCAD's backend security rules before using real operational or patient data.
- Review cPanel logs and backups for sensitive data exposure.
- If the system will contain health information, determine the applicable Australian privacy, records-retention, hosting and contractual requirements for your organisation and hosting provider before production use.

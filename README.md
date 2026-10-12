# Muslim Essentials Pro — affiliate management starter

## What this delivers
- Mobile-first public affiliate directory with category browsing, search and sorting.
- Separate product and affiliate-program records in Supabase Postgres.
- Admin email/password login using Supabase Auth (no public sign-up form).
- Admin-only CRUD and publish/unpublish for products and affiliate programs, enforced by Row Level Security (RLS).
- Product details, comparison-ready fields, verified-only price/commission fields, ethical-screening labels, SEO fields and review/verification dates.
- JSON and CSV export; CSV/JSON import.
- Optional privacy-minimal outbound click counter: stores product ID and timestamp only, not IP address, referrer or user agent.
- Public pages display only published listings; private application and tracking URLs remain in the database and are not rendered as public program links.
- Sample CSV templates.

## Important deployment status
This package is ready for you to configure and deploy, but it is **not yet a live hosted website**: no Supabase project credentials or hosting account can be created on your behalf here. Do not describe it as deployed until you complete the steps below. The app's admin writes require Supabase RLS and an admin row; without them, it must not be used to manage live data.

## Files
- `index.html` — public website and admin UI.
- `schema.sql` — database tables, RLS policies, admin helper and click-count RPC.
- `affiliate-programs-template.csv` — sample/template rows for program import.
- `products-template.csv` — sample/template rows for product import.
- `README.md` — this guide.

## Free-tier setup
1. Create a Supabase account and a new project at https://supabase.com/. Select a strong database password and save it privately. Free-tier limits, pausing rules, quotas and terms may change; check the current Supabase pricing page before relying on the free tier.
2. In Supabase, open **SQL Editor → New query**, paste all of `schema.sql`, and run it.
3. In **Authentication → Users**, create your admin user with your email and a strong password. Do not add an open sign-up page to this site.
4. Copy that user's UUID from Authentication → Users.
5. In SQL Editor, run the following, replacing the UUID with your actual user UUID:
   ```sql
   insert into public.admins (user_id)
   values ('PASTE-YOUR-AUTH-USER-UUID-HERE');
   ```
   Never guess the UUID. Verify the user exists first. Only an owner-controlled SQL session should insert admin rows.
6. Open **Project Settings → API** (or API Keys, depending on dashboard version). Copy the Project URL and the public anon/publishable key. Do **not** use `service_role` or any secret key in the browser.
7. Open `index.html` locally and go to **Admin**. Paste the Project URL and public key. These are saved in this browser's local storage. This configuration does not store your password.
8. Sign in using the admin user created in step 3. If sign-in works but access is denied, check that the exact Auth user UUID was added to `public.admins`.
9. Add products/programs in the dashboard. Keep `published = false` until details, eligibility, links and disclosures have been checked.
10. Test public pages in a private/incognito browser window to confirm unpublished items are hidden.

## Deploy to a free subdomain (GitHub Pages)
1. Create a GitHub account at https://github.com/ and create a public repository, for example `muslim-essentials`.
2. Upload `index.html` to the repository root. You may also upload `schema.sql`, CSV templates and README, but do not upload private credentials or database passwords.
3. In the repository, open **Settings → Pages**. Select **Deploy from a branch**, branch `main`, folder `/(root)`, then Save.
4. Wait for the deployment to finish. The URL normally resembles `https://YOUR-USERNAME.github.io/muslim-essentials/`.
5. Open the public URL, go to Admin, and enter your Supabase Project URL and public anon/publishable key. Each browser/device must configure the public key once. The anon/publishable key is not a secret; RLS protects data. Never put a service-role key in frontend code.
6. Test login, product CRUD, program CRUD, publish/unpublish, import/export, and public browsing.

## Android workflow
- Use Chrome and a file manager to open/extract the ZIP.
- For editing source files on Android, a code editor with HTML support is convenient; source changes are not required for routine product/program management after Supabase setup.
- Once deployed, open the public URL in Chrome and bookmark it. Use the **Admin** link to manage data.
- Keep CSV/JSON backups in a private folder; exports may contain affiliate tracking links and private notes.

## CSV import notes
- Admin → Affiliate programs → Backup/import → Import CSV imports program records.
- Admin → Products → Backup/import → Import CSV imports product records.
- Header names must match the database column names. The provided templates contain examples and blank fields.
- Rows without IDs receive a database UUID on insert. To update a record by import, include its existing UUID in the `id` column.
- Do not import arbitrary CSV files from unknown sources. CSV cells are data; still verify URLs, rates, countries, and claims.
- For products, a price is stored as verified only when `price_verified=true`, and requires price, currency and `price_verification_date`.
- For programs, commission data is stored as verified only when `commission_verified=true`, and requires both commission type and rate.
- Never put private keys or account passwords in CSVs.

## Security model
- Supabase Auth authenticates the admin.
- `public.admins` is an allowlist of user UUIDs. Users cannot self-promote through the frontend.
- RLS enforces admin-only create/update/delete, and public select of published products/programs.
- The public key can be exposed in frontend code; a Supabase service-role key must never be exposed.
- The site stores the project URL and public key in browser local storage. On a shared device, clear site data after use and sign out.
- If you later add more staff, only add explicitly authorized UUIDs to `admins`; periodically review access.
- The click counter records product ID and timestamp only. It is approximate and may be affected by bots, repeated clicks or blockers; do not treat it as audited analytics.
- For higher-risk production use, consider rate limiting and abuse monitoring for click counting. This starter intentionally does not collect IP addresses or user profiles.

## Known limitations / honest status
- This is a compact single-file frontend using the Supabase JS CDN. It requires internet access and the Supabase service.
- Public product detail pages are rendered in a modal and hash routes are not yet generated as dedicated server-rendered URLs. Metadata is site-wide; per-product SEO pages and dynamic sitemap require a static build or server-side rendering upgrade.
- The program management list shows program data to authenticated admins. Public program cards deliberately do not reveal private application URLs or tracking URLs.
- CSV import is functional for standard CSV files with quoted cells. Complex custom spreadsheet exports should be normalized to UTF-8 CSV first.
- I can package code here but cannot provision your external Supabase/GitHub accounts or truthfully claim a live end-to-end deployment without your project credentials and running tests in that environment.

## Before launch checklist
- [ ] Run `schema.sql` in the intended Supabase project.
- [ ] Create Auth user and add its UUID to `public.admins`.
- [ ] Configure public project URL and anon/publishable key.
- [ ] Test admin login from Android.
- [ ] Test add, edit, delete, publish and unpublish for both tables.
- [ ] Test public visitor cannot write or read unpublished records.
- [ ] Test import/export using the sample CSV files.
- [ ] Verify outbound click counts increment without exposing raw click rows.
- [ ] Verify affiliate program approval, country eligibility, payout method and traffic source rules.
- [ ] Keep price and commission fields blank unless current official evidence supports them.
- [ ] Review and localize privacy/terms/contact pages before launch.

# Deployment runbook: WordPress → static site

> **Bluehost era, kept as a record.** This is how the site was first deployed, in
> September 2026. It now deploys to GitHub Pages: every push to `main` runs
> `.github/workflows/deploy.yml`, which builds and publishes `_site`. There is no zip
> and no cPanel. Pages ignores `.htaccess`, so the redirects below now live in
> `src/404.njk` as well. The steps here still apply to the Bluehost copy for as long
> as DNS points at it.

Step-by-step for the cutover of `george.digiovanni.ca` on Bluehost. Written to be
followed cold, on any machine, without reference to the conversation that produced it.

Work top to bottom. Steps 6–9 are the only ones with downtime, and they are all
server-side and fast. **Step 4 is the one that can do real damage if rushed.**

---

## 0. Before you start

**Two files to upload.** Both are in the repo:

| File | Where it goes |
|---|---|
| `site/site.zip` | Document root, then extract |
| `site/deploy/htaccess` | Document root, **renamed to `.htaccess`** |

**If more than a few days have passed, or anything in `src/` changed, rebuild first:**

```bash
cd <repo>/site
npm install          # only needed on a fresh machine
find _site -mindepth 1 -delete && npm run build   # empty _site, don't delete it (see README)
find _site -type f | wc -l          # expect 30
chmod -R u=rwX,go=rX _site      # else owner-only files extract as 403 Forbidden
rm -f site.zip && (cd _site && zip -rq ../site.zip .)
unzip -l site.zip | head            # must show index.html / assets/, NOT _site/
```

That last check matters. Zip the *contents* of `_site`, not the folder, or every file
lands one level too deep and the site 404s.

**Allow about an hour.** Do not start with fifteen minutes before a meeting — the risky
window is between deleting WordPress and extracting the new site.

---

## 1. Get into cPanel

Go to **`https://digiovanni.ca/cpanel`** and log in with the hosting username and
password.

Use that address specifically. It is served directly by the account's own Apache and
returns a login page. Two things that do not work:

- `digiovanni.ca:2083` — port 2083 is blocked on the work network.
- Starting from `bluehost.com` and clicking through — that route authenticates via
  `my.bluehost.com`, which sits behind Cloudflare and answers with `cf-mitigated:
  challenge`. On a corporate network the shared egress IP has poor reputation and the
  challenge can loop without ever letting you through. **This is the likely reason cPanel
  keeps failing on the work computer, and it is not something wrong with the machine.**

If the login still will not complete, the reliable fix is a different network — a home
machine, or tethering to a phone hotspot for the duration. Everything in this runbook is
browser-based, so any machine will do; nothing here depends on the development setup.

---

## 2. Two settings, before touching anything

cPanel → **File Manager** → **Settings** (top right):

- ☑ **Show Hidden Files (dotfiles)** — without this `.htaccess` is invisible, and this
  cutover both deletes one and creates another.
- Note where **Trash** is. File Manager sends deletions to `~/.trash` by default. For the
  withdrawn papers that is relocation, not deletion. Tick **Skip the trash** in each
  delete dialog, or empty the trash at the end and confirm it is empty.

---

## 3. Find the real document root

`george.digiovanni.ca` is probably an addon domain or subdomain, so its files are in a
**subdirectory** — likely `public_html/george/` or `george.digiovanni.ca/` — not the
account's main `public_html`.

cPanel → **Domains** lists each domain with its document root. Find the row for
`george.digiovanni.ca` and note the path. Everything below calls it `<docroot>`.

**Confirm before deleting anything.** The correct directory contains **both**:

- `wp-config.php`
- a `Papers/` folder

If a directory has WordPress but no `Papers/`, it belongs to a different site on the same
account. Stop and re-check. Deleting the wrong one destroys someone else's site.

---

## 4. Write down the database name

Open `<docroot>/wp-config.php` with File Manager's **Edit** (or **View**). Find and copy:

```php
define( 'DB_NAME', '...' );
define( 'DB_USER', '...' );
```

Write both down somewhere outside the browser. Once the file is deleted, working out
which of the account's databases belonged to this site is guesswork.

---

## 5. Back up — nothing below is reversible without this

**Files.** File Manager → open `<docroot>` → **Select All** → **Compress** → *Zip
Archive* → Compress. Then select the resulting `.zip` → **Download**. Save it to a dated
folder on your machine, kept *outside* the Dropbox site directory so it is never confused
with the source.

**Database.** cPanel → **phpMyAdmin** → select the `DB_NAME` database from the left →
**Export** tab → **Go**. Save the `.sql`.

**Check both files exist locally and are not zero bytes before continuing.**

Then delete the `.zip` from the server — it sits in the web root and would otherwise be
publicly downloadable.

This backup is also the retention copy of the 10 papers George keeps. The six withdrawn
ones additionally exist as originals in the parent Dropbox folder.

---

## 6. Upload the new site, still packed

File Manager → `<docroot>` → **Upload** → choose `site.zip` (about 75 MB, most of it the
video) → wait for 100%.

**Do not extract yet.** Return to `<docroot>` and confirm `site.zip` is listed.

The old site is still live and completely unaffected — a stray zip next to WordPress
changes nothing. Doing the slow upload now means the actual downtime is only steps 7–9,
which are near-instant.

---

## 7. Remove WordPress

**Preferred:** find Bluehost's WordPress manager in the panel (wording varies — *My
Sites*, *WordPress Tools*, *Installatron*) and remove the installation. It deletes files
and database together and de-registers the install, so the panel stops trying to manage
and auto-update a site that no longer exists.

⚠️ If it offers to wipe the whole directory, `site.zip` goes with it. Either move the zip
up one level first, or skip step 6 and upload after this step instead.

**Manual fallback**, in File Manager, inside `<docroot>`:

Delete these folders — `wp-admin/`, `wp-includes/`, `wp-content/`

Delete these files — every `wp-*.php` (there are about a dozen: `wp-config.php`,
`wp-load.php`, `wp-login.php`, `wp-settings.php`, and so on), plus `xmlrpc.php`,
`index.php`, `readme.html`, `license.txt`, and `.htaccess`.

Then drop the database in phpMyAdmin: select `DB_NAME` → **Operations** → *Drop the
database (DROP)*.

`index.php` and the old `.htaccess` are the two that **must** go. Leaving either beside
the new `index.html` gives a half-broken state where Apache may keep serving the old
WordPress homepage.

Keep `site.zip`. Keep the `Papers/` folder for now — it goes next, deliberately and
separately.

---

## 8. Delete the old papers directory — the step that matters

Delete **`<docroot>/Papers/`** entirely, and **`<docroot>/CV.GdiGiovani.2021.pdf`**.

☑ **Tick *Skip the trash*.**

### Why this step exists

The WordPress site served PDFs from `/Papers/`, a plain directory at the web root with
Apache's directory listing switched on — anyone could browse the whole folder. It was
never part of WordPress and is not part of the new site, so **removing WordPress does not
remove it, and uploading the new site does not overwrite it.**

Six of those PDFs are withdrawn under George's contract with Routledge. Until this folder
is gone they remain live and downloadable at their old addresses. Every other step in
this runbook is housekeeping; this is the one that honours the contract.

All 10 papers George keeps are already inside `site.zip` under `assets/pdf/`, and the
`.htaccess` in step 10 forwards the old URLs to them, so nothing is lost.

Afterwards: confirm `Papers/` is **gone**, not merely emptied, and that the Trash is
empty.

---

## 9. Extract the new site

Select `site.zip` → **Extract** → extract into `<docroot>` → confirm.

Then **delete `site.zip`** from the server.

`<docroot>` should now contain exactly:

```
index.html   googleb8fc2c9df817cee0.html   assets/   books/   cv/   notes/   papers/   research/   video/
```

Each of those folders holds a single `index.html`. If instead you see one `_site/`
folder, the zip was built from the wrong level: open it, select all, **Move** the
contents up into `<docroot>`, and delete the empty folder.

The site is live again from this moment.

---

## 10. Install the redirects

Upload `deploy/htaccess` into `<docroot>`, then **Rename** it to `.htaccess`.

(Alternatively: **+ File** → name it `.htaccess` → **Edit** → paste the contents of
`deploy/htaccess`. If you do it this way, do not retype the two awkward filenames —
paste them. One contains a space after `The`, one contains an apostrophe, and the editor
may silently convert a straight `'` into a curly `'`, which breaks the rule with no
error.)

Uploading and renaming avoids that risk entirely, so prefer it.

This file does three things: forces HTTPS, switches off directory listings so
`/assets/pdf/` never becomes browsable the way `/Papers/` was, and forwards all 17 old
paper URLs — the 10 kept papers to their new filenames, the 6 withdrawn ones to
`/papers/`, where the titles still appear, and the dropped *Dehak* interview there too.

---

## 11. Verify

From any terminal:

```bash
# Every page loads
for p in / /books/ /papers/ /notes/ /cv/; do
  printf '%-12s %s\n' "$p" "$(curl -sS -o /dev/null -w '%{http_code}' "https://george.digiovanni.ca$p")"
done

# THE ONE THAT MATTERS — all six must be 301, and NONE may be 200
for f in "1992_CryptoCatholicism-Hegel-in-dialogue-with-the-Enlightenment.pdf" \
         "2000_KantAndHegelOnReligion.pdf" "2009_HowIntimateTrulyWasHegel.pdf" \
         "2009_TheVocationOfHumankinf.pdf" "2013_The DevilAndTheBeautifulSoul.pdf" \
         "2014_KantianVersusHegelianMyth.pdf"; do
  enc=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$f")
  printf '%-4s %s\n' "$(curl -sS -o /dev/null -w '%{http_code}' "https://george.digiovanni.ca/Papers/$enc")" "$f"
done

# Old links still reach the kept papers
curl -sS -o /dev/null -w '%{http_code} -> %{redirect_url}\n' \
  "https://george.digiovanni.ca/Papers/PopularPhilosophy.pdf"

# No listing, no internal docs, no WordPress
for p in /assets/pdf/ /assets/img/CREDITS.md /wp-login.php /Research; do
  printf '%-28s %s\n' "$p" "$(curl -sS -o /dev/null -w '%{http_code}' "https://george.digiovanni.ca$p")"
done
```

Expected: all `200` in the first block. All `301` in the second, **with no `200`
anywhere** — a `200` there means a withdrawn paper is still being served, so go back to
step 8. A `301` to an `/assets/pdf/` name in the third. In the fourth: `403`, `404`,
`404`, `301`.

Then open the site in a browser. If it looks unstyled, the files extracted at the wrong
level — see step 9.

**Then follow `docs/after-launch.md`** for the same-day and within-the-week items.

---

## If something goes wrong

**The site is broken and you want the old one back.** Delete everything in `<docroot>`,
upload and extract the backup zip from step 5, and re-import the database in phpMyAdmin
(select the database → **Import** → choose the `.sql`). This is why step 5 is not
optional.

**Pages 404 but the homepage works.** The zip extracted a level too deep. See step 9.

**Everything is unstyled.** Same cause. The site uses root-absolute asset paths
(`/assets/...`), so it only renders correctly when the files sit at the document root.

**Redirects do nothing.** `.htaccess` is missing, misnamed, or in the wrong directory.
Turn on *Show Hidden Files* and check it is there, named exactly `.htaccess`, in
`<docroot>`.

**One specific redirect fails.** Almost certainly the apostrophe or the space. Re-upload
`deploy/htaccess` rather than editing by hand.

**You get locked out of cPanel partway through.** Nothing is in an unsafe state between
steps as long as you have the step 5 backup. Come back on a different network — see
step 1.

# After the launch

Written at the 2026-09 cutover from WordPress to this static site. The steps below are
the ones most easily dropped, because by the time they come round the site is visibly
working and the pressure is off.

The cutover itself is in **`docs/deploy-runbook.md`** — back up, remove WordPress,
delete the old `Papers/` directory, extract the new build, upload `deploy/htaccess` as
`.htaccess`, all through cPanel File Manager. This file picks up where that one ends.

## Why the old paper directory mattered

The WordPress site served PDFs from `/Papers/`, a plain directory at the web root with
Apache's directory listing switched on. It was not part of WordPress and not part of
this site, so nothing about replacing the site would have removed it. Six of those PDFs
are withdrawn under George's Routledge contract. Deleting that directory is the step
that honoured the contract; everything else was housekeeping.

That is worth remembering, because the same trap can reappear: **a file can be live on
the server without being referenced by anything in this repo.**

## Same day, in order

1. **Run the verification block below.** Check 2 is the one that matters.
2. **Load every page in a browser.** CSS and the portrait must render — that is the real
   test that the root-absolute asset paths resolved. A page that looks unstyled means
   the files landed at the wrong level.
3. **Check `/papers/`** — the six withdrawn titles should still be listed, each with no
   Read link, and the 2014 myth paper should still show its DOI.
4. **Empty File Manager's Trash.** It deletes to `~/.trash` unless *Skip the trash* was
   ticked. A trashed PDF is still on the account.
5. **Delete the backup archive from the server** if one was left in the docroot during
   the backup step. Keep the local copy.

## Verification

```bash
# 1. Every page returns 200
for p in / /books/ /papers/ /notes/ /cv/ /video/; do
  printf '%-12s %s\n' "$p" "$(curl -sS -o /dev/null -w '%{http_code}' "https://george.digiovanni.ca$p")"
done

# 2. THE ONE THAT MATTERS — all six must be 301, never 200
for f in "1992_CryptoCatholicism-Hegel-in-dialogue-with-the-Enlightenment.pdf" \
         "2000_KantAndHegelOnReligion.pdf" "2009_HowIntimateTrulyWasHegel.pdf" \
         "2009_TheVocationOfHumankinf.pdf" "2013_The DevilAndTheBeautifulSoul.pdf" \
         "2014_KantianVersusHegelianMyth.pdf"; do
  enc=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$f")
  printf '%-4s %s\n' "$(curl -sS -o /dev/null -w '%{http_code}' "https://george.digiovanni.ca/Papers/$enc")" "$f"
done

# 1b. The video is served as video/mp4 (Firefox refuses a wrong type)
curl -sSI "https://george.digiovanni.ca/assets/video/hegel-250-2020.mp4" | grep -i '^HTTP\|^content-type\|^content-length'

# 3. Old links still reach the kept papers
curl -sS -o /dev/null -w '%{http_code} -> %{redirect_url}\n' \
  "https://george.digiovanni.ca/Papers/PopularPhilosophy.pdf"

# 4. No directory listing, no internal docs, no WordPress left
for p in /assets/pdf/ /assets/img/CREDITS.md /wp-login.php /Research; do
  printf '%-28s %s\n' "$p" "$(curl -sS -o /dev/null -w '%{http_code}' "https://george.digiovanni.ca$p")"
done
```

Expected: all `200` in check 1; `200`, `video/mp4` and a length near 70 MB in check 1b. All `301` in check 2, **and no `200` anywhere in it** — a
`200` there means a withdrawn paper is still being served. A `301` to the new
`/assets/pdf/` name in check 3. In check 4, `403` for the directory, `404` for
`CREDITS.md` and `wp-login.php`, `301` for `/Research`.

Re-run check 2 after any edit to `.htaccess`. Two of those filenames are fragile: one
contains a space after `The`, one an apostrophe, and File Manager's editor will happily
turn a straight apostrophe into a curly one and break the match without telling you.

## Within the week

6. **Google Search Console → Removals.** Request removal for each of the six withdrawn
   PDF URLs, then *URL Inspection → Request indexing* on `/papers/`. The 301s deindex
   them eventually; for contract-bound files, ask explicitly rather than wait for a
   crawl. Cached copies are the loose end here.
7. **Tell George his old links still work**, bar the six — anything in an email
   signature or a circulated CV is safe.
8. **Correct these docs if the cutover went differently in practice** — the README's
   Deploy section, `deploy-runbook.md`, and this file were all written before anyone had
   done it once. Bluehost panel wording in particular is a guess.

## Every future update

**Now: push to `main`.** The site deploys to GitHub Pages through
`.github/workflows/deploy.yml`, so an update is a commit and a push, nothing more. The
zip route below is how it worked on Bluehost, and still applies to the Bluehost copy
until DNS moves.

```bash
npm run build
cd _site && chmod -R u=rwX,go=rX . && zip -r ../site.zip . && cd ..
```

Keep the `chmod`: without it, files with owner-only permissions extract as 403
Forbidden. If a PDF ever returns 403 on the live site, select it in File Manager →
**Permissions** → `0644`.

Upload `site.zip` through File Manager, extract into the document root, overwrite, then
delete the zip. For small edits a zip of only the changed files works the same way (see
the README's Deploy section); the 2026-09-16 update shipped like that. Once the video is on the server, later zips can skip it with
`-x 'assets/video/*'` — see the README. Zip the *contents* of `_site`, not the folder — otherwise everything
lands one level too deep inside a `_site/` directory.

**Leave `.htaccess` alone.** It is not produced by the build. An extract that overwrites
it silently undoes every redirect, and nothing looks broken until someone follows an old
link. If it is ever lost, upload `deploy/htaccess` again and re-run check 2.

## Getting back in

Two access problems were diagnosed on the work machine. Both have workarounds, and
neither is a fault of the computer. `deploy-runbook.md` steps 1 and 2 carry the detail;
in short:

- **cPanel login fails or loops.** Go direct to `https://digiovanni.ca/cpanel`, never in
  via `bluehost.com` — that route authenticates through `my.bluehost.com`, which sits
  behind Cloudflare and answers `cf-mitigated: challenge`. From a corporate egress IP
  the challenge can loop forever. A home network or phone hotspot clears it.
- **FileZilla connects then hangs on every directory listing.** The work network runs an
  FTP gateway that reads the plaintext control channel to find the passive data port;
  encrypting that channel (FileZilla's default) hides the port and the data connection
  never completes. Measured three runs each: plain FTP 3/3 succeeded, FTP over TLS 3/3
  timed out at 20s with zero bytes. Active vs Passive is irrelevant. Use File Manager,
  or SFTP on port 22, which has no separate data channel.

Two File Manager settings, under *Settings* top-right:

- **Show Hidden Files (dotfiles)** — on, or `.htaccess` is invisible.
- **Trash** — deletions go to `~/.trash` unless *Skip the trash* is ticked. Not real
  deletion, which matters when the reason for deleting is a contract.

## If a paper is ever cleared for release

The original PDFs are in the parent Dropbox folder, under their old names. To restore
one:

1. Copy the file into `src/assets/pdf/` with a slugified name matching the convention.
2. Restore that paper's `"pdf"` key in `src/_data/papers.json`.
3. Remove its redirect line from `deploy/htaccess` and re-upload as `.htaccess`.
4. Rebuild, redeploy, and confirm the Read link is back on `/papers/`.

The template drops the actions line entirely when an entry has neither `pdf` nor `doi`,
so adding the key back is all that is needed to make the link reappear.

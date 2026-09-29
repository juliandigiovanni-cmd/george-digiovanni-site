# george.digiovanni.ca

Static site for George di Giovanni, Professor of Philosophy Emeritus at McGill
University. Built with [Eleventy](https://www.11ty.dev/). No database, no plugins —
the build produces plain HTML that can be uploaded anywhere.

> **The title is "Professor of Philosophy Emeritus", in that order.** At McGill this
> names a current appointment — one under which he still sits as Pro-Dean at doctoral
> defences — not a note that he has retired. "Emeritus Professor of Philosophy" is a
> different thing and is wrong. Keep the order when editing any copy on the site.

## Build

```sh
npm install
npm start     # dev server with live reload at http://localhost:8080/
npm run build # writes _site/
```

## Preview

`npm start` is the way to look at the site. It rebuilds and reloads the browser on
every save under `src/`.

Do **not** preview by double-clicking `_site/index.html`. Asset paths are
root-absolute (`/assets/...`), so opening the file over `file://` renders an unstyled
page with no images — the build is fine, the paths just have no domain root to resolve
against. Previewing always needs a server.

That same root-absolute rule is why `_site/` must be uploaded to the web root rather
than a subdirectory.

## Deploy

**GitHub Pages, from `main`.** Every push to `main` runs `.github/workflows/deploy.yml`,
which runs `npm ci` and `npm run build` and publishes `_site`. There is nothing to
upload by hand. The custom domain comes from `src/CNAME`, which the passthrough in
`.eleventy.js` copies to the root of `_site`.

Pages ignores `.htaccess`. The old paper redirects are in `src/404.njk` instead:
Pages serves that page for any missing path, and a short script on it forwards the
old URLs with `location.replace`. `deploy/htaccess` stays as the record of the rules
and for the Bluehost copy, which keeps serving the site until DNS moves. Change a
redirect in both places until then.

### Bluehost (until DNS moves)

Everything from here to *Documentation* is how the site was deployed on Bluehost.

`_site/` is the deployable artifact, but it is not the whole deployment: `.htaccess` is
load-bearing and is **not** produced by the build. It lives at `deploy/htaccess` and
carries the redirects that keep the old WordPress paper URLs working. Leave it alone on
the server when redeploying — an extract that overwrites it silently undoes every
redirect, and nothing looks broken until someone follows an old link.

```bash
npm run build
cd _site && chmod -R u=rwX,go=rX . && zip -r ../site.zip . && cd ..
```

The `chmod` is load-bearing. Files copied out of Dropbox can carry owner-only
permissions (`-rw-------`); the zip preserves them, cPanel's extract keeps them, and
Apache then answers 403 Forbidden. At the 2026-09-11 launch that blocked the CV and
all ten kept papers while the Notes PDFs, which happened to be `644`, loaded fine.

For a small change, a partial zip is enough: zip only the files that changed (paths
relative to `_site`, e.g. `zip ../update.zip index.html notes/index.html
assets/pdf/note-3-one-more-note.pdf`) and extract it the same way. Remember that the
footer is on every page, so a change to `site.json` touches every `index.html`.

Upload `site.zip` through cPanel File Manager at `https://digiovanni.ca/cpanel`, extract
into the document root, then delete the zip. Zip the *contents* of `_site`, not the
folder, or everything lands a level too deep.

The video makes the zip about 70 MB larger. Once it is on the server, later redeploys can
leave it out — `zip -r ../site.zip . -x 'assets/video/*'` — because extracting over the
docroot overwrites files but never deletes the ones already there.

Use File Manager rather than a desktop FTP client. FileZilla connects and then hangs on
directory listings from the work network, which runs an FTP gateway that cannot read the
passive data port out of an encrypted control channel — plain FTP works, FTP over TLS
times out, and toggling Active/Passive changes nothing. SFTP on port 22 also works if
SSH is enabled on the account.

Reach cPanel at `https://digiovanni.ca/cpanel` directly, not by signing in through
`bluehost.com`. That route authenticates via `my.bluehost.com`, which sits behind
Cloudflare; from a corporate IP its bot challenge can loop without ever admitting you.

## Documentation

| File | What it covers |
|---|---|
| `docs/deploy-runbook.md` | Step-by-step for the WordPress cutover. Written to be followed cold, on any machine |
| `docs/after-launch.md` | What to do once it is live, and how to verify it |
| `docs/image-credits.md` | Provenance and licence of every image; which book jackets are still missing |
| `deploy/htaccess` | The redirects, as Bluehost ran them. Pages ignores it; the same rules are in `src/404.njk` |
| `.github/workflows/deploy.yml` | Builds and publishes to GitHub Pages on every push to `main` |

## Pages

| URL | Template | What it holds |
|---|---|---|
| `/` | `index.njk` | Portrait hero, research tags, the biographical description, George's three most recent books, and four lines of his under them: the translation errata, two papers, the video, the CV |
| `/books/` | `books.njk` | All monographs, translations and edited volumes, with abstracts |
| `/papers/` | `papers.njk` | Papers grouped by decade. Most link to a PDF; the withdrawn six are listed by title alone — see *Papers withdrawn* |
| `/notes/` | `notes.njk` | The *Science of Logic* errata |
| `/cv/` | `cv.njk` | Education, monographs and translations, selected essays, and a link to the abbreviated CV as a PDF |
| `/video/` | `video.njk` | George's presentation for the 250th anniversary of Hegel's birth, August 2020. Linked from the homepage, deliberately not in the nav |
| `/research/` | `research-redirect.njk` | Redirect only — see below |
| `/404.html` | `404.njk` | Pages serves it for any missing path. Carries the old `/Papers/` redirects, since Pages ignores `.htaccess` |

`/research/` exists because that is the URL the old WordPress site used. It serves a
small page that forwards to `/papers/`, so anything already linking there keeps
working. It is an HTML redirect rather than an `.htaccess` rule so it behaves the same
on Bluehost and on GitHub Pages. Don't delete it, and don't add it to the nav.

Contact is not a page. The footer on every page carries George's two email
addresses and nothing else — no department, no postal address. See the note below.

## Where the content lives

All content is data, not markup. To change what appears on the site, edit the JSON in
`src/_data/` — the templates render whatever is there. The one exception is the four
lines under the homepage books, which are George's own sentences and sit directly in
`index.njk`.

| File | Contents |
|---|---|
| `site.json` | Name, title, contact details, nav, external links |
| `books.json` | Monographs, translations and edited volumes. `featured: true` puts a book on the homepage |
| `papers.json` | Downloadable papers on the Papers page |
| `notes.json` | The *Science of Logic* errata |
| `essays.json` | The CV essay list, generated from `CV for webpage.2026.docx` via `textutil -convert txt` (text after "Essays and Criticism", one entry per paragraph, verbatim; the dead `thesgir.org` and `springerlink.com` URLs dropped). See *Internal notes in the CV* |
| `education.json` | Degrees |

PDFs go in `src/assets/pdf/` with slugified filenames; the display title lives in the
data file, so filenames never need to be pretty.

A paper entry may omit `pdf` entirely. The title, year and venue still render; only the
Read link disappears, and if the entry has no `doi` either, the actions line is dropped
altogether. This is how a withdrawn paper stays in the record without being
downloadable — see *Papers withdrawn* below.

### Book covers

The three featured books on the homepage currently render as typographic title cards.
The machinery for real cover images is in place but unused: drop a jacket image in
`src/assets/img/` and add `"cover": "<filename>"` to that book's entry in
`books.json`, and the card switches to the image variant automatically.

Switch all three or none. One photographed jacket beside two typographic cards reads
as a missing image rather than a design choice. `docs/image-credits.md` records
which jackets are still needed and why they could not be obtained.

### The video

`src/assets/video/hegel-250-2020.mp4` is **in git**, at about 70 MB. It was gitignored
while the site was deployed by hand from Dropbox, but the Pages workflow builds from a
fresh checkout, and a file that is not in the repo does not ship. 70 MB is under
GitHub's 100 MB per-file limit. Don't replace it casually: every version stays in the
history for good. To regenerate it from the original, `DI.GIOVANNI.hEGEL.bERLIN2020.mov`
in the parent Dropbox folder (452 MB, 1080p, recorded in George's apartment by a
neighbour):

```sh
mkdir -p src/assets/video
swift tools/transcode-video.swift ../DI.GIOVANNI.hEGEL.bERLIN2020.mov \
  src/assets/video/hegel-250-2020.mp4 2500000 30
```

That is 720p, 30 fps H.264 (High profile, level 4.0) at 2.5 Mbps with AAC audio and
fast-start, which plays in every browser. The original is 60 fps; the script keeps every
other frame. Don't use `avconvert`'s presets instead: `Preset1280x720` kept an 11 Mbps
bitrate and produced 318 MB. Don't switch to HEVC either — Firefox, George's browser,
can't be relied on to play it. The poster is a frame 15 seconds in, made with
`swift tools/poster-frame.swift <mov> /tmp 15`.

The old public link to this presentation (`5minutenhegel.de`) now throws a browser
security warning and is blocked by Bitdefender — George believes someone is
impersonating it. That is why the video is hosted here rather than linked.

## Waiting on George

- **A fresher CV.** He means to add the book now in production.
- **The new book.** Forthcoming from Routledge in 2027. Add it to `books.json` once it
  has a title, subtitle, and date. The homepage description already comes from its
  author blurb.

## Notes

- **Google Search Console.** The site is verified as a URL-prefix property
  (`https://george.digiovanni.ca/`) by `src/googleb8fc2c9df817cee0.html`, which
  `.eleventy.js` copies to the site root untouched. Don't delete or rename it — Google
  rechecks it, and the property is where the removal requests for the six withdrawn
  papers were filed (2026-09-11).
- **The 2026-09-11 review.** The homepage section is "Most recent books" — George has
  earlier ones — followed by four lines of his copy. His draft said the video marked the
  "200th anniversary of Hegel's death, August 2020"; Hegel was born in August 1770 and
  died in 1831, so with Julian's agreement it reads "250th anniversary of Hegel's birth".
  The same review dropped the homepage list of recent papers (the Papers page and its nav
  item stay), the footer link to the McGill exit interview, and the *Dehak* interview,
  whose PDF was deleted and whose old URL now redirects to `/papers/`. The "previews" he
  mentioned were old WordPress links with no counterpart here.
- **Internal notes in the CV.** George's CV carries bookkeeping meant for McGill rather
  than readers. The one found so far was a second copy of the *Hegel's Linguistic Turn*
  entry marked "[not declared in merit exercise of 2016]". At Julian's request
  (2026-09-11) he removed it in Word. The same day the CV's typos were corrected
  (Foreword, Kingston, Palgrave, Metaphysics, the Spinoza book's 1831, a missing
  quotation mark) and its two dead links deleted. The current source is
  `CV for webpage.2026.docx`; the site serves its PDF export, and `essays.json` is
  generated from the same file.
  When a fresher CV arrives, check it for anything similar before it goes up; both the
  essay list and the PDF are public.
- **Papers withdrawn.** George's contract with Routledge bars six papers from appearing
  elsewhere. On 2026-09-09 he named them, and their `pdf` keys and files were both
  removed — dropping the link alone would have left the files reachable by direct URL.
  The titles remain on `/papers/`. The originals are still in the parent Dropbox folder
  if they are ever cleared for release. The six: *Kantian versus Hegelian Myth* (2014,
  which he cited under the title of its 2017 *Hegel-Jahrbuch* version, whose DOI link is
  kept), *The Devil and the Beautiful Soul* (2013), *The Year 1786* (2011),
  *How Intimate an "Intimate of Lessing"* (2010), *Faith Without Religion, Religion
  Without Faith* (2003), and *Crypto-Catholicism* (1992). He cited the last four by
  earlier years than the site carries — he appears to have been working from an older
  CV — but the titles matched unambiguously.
- `docs/image-credits.md` records the provenance and licence of every image. It lives
  in `docs/` rather than beside the images because anything under `src/assets/` is
  copied verbatim into the build and would be published.
- **The site is light-only, on purpose.** There is no dark palette and no
  `prefers-color-scheme` rule anywhere. One shipped; George asked for it to go —
  "can we throw more light on the subject? That black is lugubrious." Don't add it
  back. `theme-george.css` carries the same note where the block used to be.
- The homepage hero was once a triptych — Kant, George, Hegel — alluding to *Between
  Kant and Hegel* without naming it. George read it as clutter rather than as an
  allusion ("one is already too much"), and the two paintings were removed along with
  their image files. It is now a single portrait beside his name and description.
- **The portrait** is the studio photograph George sent on 2026-09-16 (original
  900×1200, in `../16sept26/34-2.jpg`), served as `george-portrait.jpg` at 720×960 —
  enough for a high-density screen at the capped panel width. It replaced the 2003
  snapshot (`george.jpg`, original `../George.2003.jpg`). The file was renamed rather
  than overwritten so browsers could not keep showing a cached copy of the old one.
- That hero portrait is the site's only photograph. A second one sat beside the CV
  heading and came off at George's request; the CV is text now.
- The homepage description is George's own author blurb for his forthcoming Routledge
  book, put into third person at his request. Treat it as his copy, not ours.
- **Contact is two email addresses and nothing else.** The footer used to carry a
  Department of Philosophy postal address; George is attached to no department or
  school any more and asked for every such reference to go. Keep the McGill address —
  "one of my privileges as Professor Emeritus" — and don't reinstate the mailing
  address or an affiliation line anywhere.
- **The 2026-09-16 review.** George asked for: the new portrait; "even though" → "but"
  in the first paragraph of the homepage description; "Archived original entry 2001…"
  in the footer's Stanford Encyclopedia line; a replacement Note 3, which he had
  rewritten (source now `../notes/Note3.docx`; the previous version is kept beside it
  as `Note3.2025-superseded.docx`); and a fix for Note 2, whose p. 235 equation was
  drawn over the line above it. He also asked that the notes reached from the homepage
  and from the *Science of Logic* entry on `/books/` be the same corrected ones. They
  already were, because both link to `/notes/`.
- **How the notes PDFs are made.** Export them from Microsoft Word (File → Save As →
  PDF, or AppleScript `save as … file format format PDF`), not with `textutil` or any
  other macOS converter, which drop superscripts and field codes. Note 2 needs more
  than that. Its p. 235 fraction, (f(x+1) − fx)/i = P, is a legacy *Microsoft
  Equation 2.0* object whose stored preview image is clipped, so even Word draws it
  garbled. `../notes/Note2-equation-fixed.docx` is a copy of `Note2.docx` with that
  one object swapped for a native Word equation; export Note 2 from that file.
- The *Science of Logic* errata are linked as PDFs rather than reset as web text. They
  depend on exact page references and mathematical notation, and a typo introduced
  into a list of corrections would be worse than useless.
- **The Notes page intro is George's own sentence**, the same one the homepage uses,
  without "see here". An earlier intro framed two of his sentences with invented
  first-person copy ("Because they turn on exact page references…"), and on
  2026-09-12 George flagged it as "Claude language". Don't add explanatory copy in his
  voice around it.
- **Publisher links break when publishers re-map their URLs.** On 2026-09-12 the old
  MQUP link for the Jacobi translation (`…products-9780773511651.php`) was redirecting
  to an unrelated book, and the Springer link for the Reinhold volume (print ISBN
  DOI `978-90-481-3226-6`) was a 404. Both now use the publishers' current pages. When
  checking these links from the terminal, follow redirects and read the page title,
  because a 200 doesn't prove it's the right book. `cambridge.org` answers curl with
  403 (bot protection), so check those links in a browser.
- Two external links found in George's 2021 CV were dead and were dropped rather than
  shipped: `5minutenhegel.de` (its TLS certificate no longer matches the host, so the
  link throws a browser security warning) and `thesgir.org/sgir-review.html` (404). The
  first was his 2020 Hegel presentation; George supplied the original recording, which
  is now self-hosted at `/video/` — see *The video*. Don't reinstate the old link.
- `node_modules/` and `_site/` are marked Dropbox-ignored (`xattr -w com.dropbox.ignored 1
  node_modules _site`) so Dropbox doesn't sync them. Re-apply after a fresh clone. To
  clear stale build output, empty the folder (`find _site -mindepth 1 -delete`) rather
  than `rm -rf _site`: the flag lives on the folder, and deleting and recreating it
  under Dropbox leaves "conflicted copy" duplicates. A `node_modules 2/`, a `_site 2/`
  and a second 74 MB video inside `_site` all turned up that way and were deleted.
- This repo lives inside Dropbox. Work on it from one machine at a time — Dropbox
  syncing `.git` from two machines at once can corrupt the repository.

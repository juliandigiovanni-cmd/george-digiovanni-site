# Image credits

## george-portrait.jpg
George di Giovanni, studio portrait. Sent by George via OneDrive on 2026-09-16 for use
on the site. The homepage hero. Original `16sept26/34-2.jpg` in the parent Dropbox
folder, 900×1200 — already 3:4, so it is used uncropped, resized to 720×960 and
re-encoded.

It replaced `george.jpg`, a 2003 family photograph at 480×640 (original
`George.2003.jpg`; the copy the site used is in `16sept26/superseded/`).

This is the only photograph of George on the site. Three others were removed in the
same pass: public-domain portraits of Kant (Wikimedia, artist unknown) and Hegel
(Wikimedia, Schlesinger 1831), which flanked him in the old triptych hero, and
`george-81.jpg`, a family photograph that floated beside the CV heading. Wikimedia
still has the paintings; the original of the third is `George at 81.JPG` in the parent
Dropbox folder.

## video-poster-2020.jpg
A frame 15 seconds into George's own 2020 video (`DI.GIOVANNI.hEGEL.bERLIN2020.mov` in
the parent Dropbox folder), 1280×720. Family recording, made in his apartment by a
neighbour. The poster on `/video/`. Regenerate with `tools/poster-frame.swift`.

## cover-freedom-and-religion.jpg — held, not yet used

Cover of *Freedom and Religion in Kant and His Immediate Successors* (Cambridge
University Press, 2005). Publisher cover art, used on the author's own site to
represent his own book.
Source: https://covers.openlibrary.org/b/id/359062-L.jpg (331×500)

Not referenced by any page. The homepage shows typographic title cards for all three
featured books, because jackets for the other two could not be obtained.

### Jackets still needed

| Book | ISBN | Why it is missing |
|---|---|---|
| *Hegel and the Challenge of Spinoza* | 9781108842242 | Not on Open Library — the cover endpoint returns a 43-byte placeholder, re-confirmed 2026-09-09. `cambridge.org` and Cambridge Core were serving error pages on 2026-09-06 under an announced service suspension — "we have implemented additional assurance measures to protect our systems" |
| *The Science of Logic* | 9780521832557 | Open Library holds a scanned **title page** for this ISBN, not the jacket. Sibling editions grouped under the same work return the cover of Pinkard's *Phenomenology of Spirit* — a different book by a different translator. Check any Open Library cover before using it |

Cambridge's own book pages carry the jackets, and are the place to retry. As of
2026-09-09 `cambridge.org` answers a command-line request with a 403 and a 1.3 KB body,
which could equally be the suspension continuing or ordinary bot protection — the two
are indistinguishable from `curl`, so **check in a browser** before concluding anything.

George may also hold the jacket files from his publication correspondence, which would
settle it without Cambridge.

### Adding a cover

Drop the file in `src/assets/img/` and add `"cover": "<filename>"` to that book's
entry in `src/_data/books.json`. The template and CSS already handle it — the card switches
to a 2:3 image variant using `object-fit: contain`, so a jacket is never cropped
through its title.

Switch all three featured books or none. A single photographed jacket beside two
typographic cards reads as a broken image rather than a design choice; this was tried
and reverted.

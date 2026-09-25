# AGENTS.md — working rules for this repository

Personal academic website of Jinge (Kenneth) Guo. Plain HTML/CSS/vanilla JS, **no build step**,
deployed by GitHub Pages straight from `main` at the repository root.

Read `README.md` first — it is the authoritative description of every file, feature and
convention. This file only covers what an agent needs in order to work here safely.

## Coordinates

| | |
|---|---|
| Local clone | `E:\Codex\2026.09\Personal_Website` |
| Remote | `https://github.com/Gjinge/Personal_Website.git` (`Gjinge/Personal_Website`) |
| Branch | `main` — Pages serves `main` / root |
| Live URL | https://jinge.space (custom domain, `CNAME`) |
| Legacy URL | https://gjinge.github.io/Personal_Website/ |
| Related repo | `E:\Codex\2026.09\notes-api` — Cloudflare Worker backing likes/comments; deployed separately with `npx wrangler deploy`. Never redeploy it for a content change. |

## Deploy

Every visible change must be committed and pushed, or it does not exist:

```powershell
cd "E:\Codex\2026.09\Personal_Website"
git pull --rebase
# ...edit...
git add -A
git commit -m "<what changed>"
git push
```

`tools\publish.ps1` and `tools\rollback.ps1` wrap this; `E:\Codex\2026.09\scripts\deploy_personal_website.ps1`
is the owner's own deploy script (gh CLI config lives in `%LOCALAPPDATA%\CodexWebsiteGitHubAuth`).
Any of the three is fine — pick one and say which you used.

Pages takes ~1 minute to rebuild. The URL resolving is **not** proof the deploy finished;
check the repository's Actions/Pages status when it matters.

Local preview: `python -m http.server 8000 --bind 127.0.0.1`.

## Hard rules

1. **Do not renumber reading-note entry IDs.** `notes/chaowendao.html` has fixed ids
   (`eyes-01` … `cloud-20`, 113 total). Likes and comments in Cloudflare KV are keyed on them;
   reordering or renumbering silently corrupts live data. Only ever append new ids.
2. **Nothing private ships.** No student ID numbers, no source-photo filenames (`IMG_…`) in
   markup or data, no location metadata in published photos, no account credentials.
3. **Never overstate research status.** Submitted or under-review work is never described as
   accepted. Dates and venues go in only when confirmed.
4. **No invented content.** No demo photos, no placeholder social accounts, no sample reading
   notes. Empty sections keep their honest empty state until the owner supplies real material.
5. **`Claude outputs/` is gitignored** — scratch from the Claude desktop app, not part of the site.

## Conventions that bite

**Four languages.** English / 简体中文 / Français / Español, English is the source of truth.
Translations live in `assets/js/i18n/{zh,fr,es}.js`, keyed by a **10-hex FNV-1a hash of the
English text with whitespace collapsed** — the markup carries no translation attributes.
So: *any edit to English copy silently reverts that string to English* until you rehash the new
text and update all three language files. Runtime strings go through `window.jgT()`.
Language choice is stored in `localStorage['jg-lang']` and switching always reloads the page.

**Reading-note pages are self-contained.** Everything under `notes/` inlines its own CSS and JS
and does *not* use `assets/css/styles.css` or `assets/js/i18n.js` — but it must read/write the
same `localStorage['jg-lang']`, and it does its own four-language switching. Dark palette
`#080d17`. Top-left `← Reading Notes` links back to `../reading.html`.

**Note pages stay clean.** Content only — no "how this page was made" commentary: no photo
filenames, no transcription notes, no legend row, no methodology footer. The header fact row has
exactly two cells (reading period, print edition). Keep: back link, title/author, language
switcher, translation provenance box, section filter, entry cards with page numbers and `kinds`
tags, signature footer.

**Translation provenance.** Every translated note page carries a `.provenance` block naming the
AI-translation notice and the statement that the Chinese original governs where the translation differs.
Do not display the original-language, source-text, translator/model, or translation-date detail rows
(owner request, 2026-09-20).
In non-Chinese modes every quotation shows the Chinese original beneath it (`.orig`).

**Adding a book.** New self-contained page under `notes/` → one entry appended to
`window.readingNotes` in `assets/js/reading-data.js`
(`{title, author, date:'YYYY-MM-DD', tags:[], summary, url}`; a bad `url` makes `reading.js`
drop the entry) → commit and deploy.

**Shared chrome.** The Pac-Man reading-progress rail and the header nav are duplicated in every
content page — update them together. `assets/js/i18n.js` deliberately skips the rail and
`.source-code` blocks.

## Known open items

- The `CNAME` is `jinge.space`, but `README.md` and some metadata still reference
  `gjinge.github.io/Personal_Website`. Whoever does the address change must update the canonical
  URL, `og:url`, `og:image` and the Schema.org `url` in `index.html` *and* this README together.
- Homepage hero: the owner wants a full-bleed photographic hero (Samuel F. B. Morse's
  *Gallery of the Louvre*) replacing the decorative `.research-visual` SVG.
- Photography, Social and Reading-Notes-beyond-the-first-book are still awaiting real material.

## Before you finish

- Check desktop **and** mobile width, and keyboard focus, after any CSS change.
- Check the page still works with JavaScript disabled (it must stay readable, in English).
- If you touched English copy, confirm the three translation files were rehashed.
- Commit, push, and report the commit hash and what the owner should look at on the live site.

## Approved visual system (2026-09-20)
Read `design.md` before visual changes — especially its "Warm layer" section, which is the current look
(`assets/css/warm.css`, linked last on every main page). Earlier main-site overrides live in `assets/css/hallmark.css`,
loaded after the original stylesheet; tokens live in `tokens.css`. Cream reading pages embed
scoped overrides and have noscript fallbacks. Keep those fallbacks synchronized with entry data.
The mobile menu is created in main.js and uses the same translation hashes as other runtime labels.

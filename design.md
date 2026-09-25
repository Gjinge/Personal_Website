# Design — Jinge Guo

Approved 2026-09-20. A restrained academic site: existing identity first.

## Genre and structure
Main site: atmospheric, inherited Midnight/cyan. Homepage: Marquee Hero with the existing Louvre painting. Project index: image-and-description rows; research: article columns. Nav N9, footer Ft2. The complete Louvre painting is contained without cropping in the opening viewport, with the original greeting layout. Navigation follows the cover in document flow and sticks above the content with a full-width solid background. Expanded mobile menus use a solid background. Reading pages: editorial Long Document, cream variant; shelf retains Gallery/Table. All routes and content ownership stay intact.

## Tokens and typography
`tokens.css` defines the active system. Local Segoe UI display/body, existing serif for reading, Consolas for code. Roman headings. No external font or UI framework. New palette values are OKLCH; existing illustration and Pac-Man colours remain intentional legacy assets.

## Spacing
Named 4px-based scale, 16–96px. Prose is approximately 65–72ch; small viewports use available width. No content-reveal animation. Smaller research artwork allows the biography to lead.

## Motion and interactions
Preserve the user-requested typewriter speed and Pac-Man seeking. Disable decorative orbit rotation. Menus are instant disclosures with aria-expanded, Escape, outside click and link-close behaviour. Focus rings appear instantly. Reduced-motion remains supported. Do not add fake loading/success/error states to synchronous menus.

## Variants
Dark is the homepage entry default. Light remains a user control. Reading uses cream regardless of the main-site theme. Reading pages embed their token subset and remain self-contained; maintain it alongside tokens.css. Four-language choice remains shared through jg-lang.

## Content constraints
No changed claims, fabricated material, IDs or downloads. All 216 note IDs must stay stable. Notes retain Chinese originals and existing translation notice. Noscript fallbacks mirror existing English quotes and originals; regenerate them if entries change.

## Maintenance
Main routes link assets/css/hallmark.css after the original stylesheet. Original styles.css remains untouched for rollback. Keep new rules in the design layer. Reading pages embed their scoped rules. No file deletion. Existing redirects and API behaviour are unchanged.

## Hallmark scope decisions
User-approved existing fonts, cyan palette, painting and Pac-Man take precedence over catalog rotation and anti-default-font suggestions. This is a preservation redesign, not a strict replacement of all legacy code. No claim of a blanket 58/58 audit: typography gate 1 and legacy ornamental/caret/motion rules are intentional exceptions. Safety, responsive overflow and content-integrity checks are verified separately.

## Exports
### CSS
Use `tokens.css` directly, including the light variant. Self-contained reading token blocks use the same named reading colours.

### Tailwind v4 (optional; not installed)
```css
@theme inline {
  --color-background: var(--color-paper);
  --color-foreground: var(--color-ink);
  --color-primary: var(--color-accent);
  --font-sans: var(--font-body);
  --font-serif: var(--font-reading);
}
```

### DTCG (portable core)
```json
{"color":{"paper":{"$type":"color","$value":{"colorSpace":"oklch","components":[0.16,0.025,260],"alpha":1}},"ink":{"$type":"color","$value":{"colorSpace":"oklch","components":[0.95,0.012,250],"alpha":1}},"accent":{"$type":"color","$value":{"colorSpace":"oklch","components":[0.84,0.10,195],"alpha":1}}}}
```

### shadcn variables (optional; not installed)
```css
:root {
  --background: var(--color-paper);
  --foreground: var(--color-ink);
  --primary: var(--color-accent);
  --primary-foreground: var(--color-accent-ink);
  --border: var(--color-rule);
  --ring: var(--color-focus);
  --radius: .25rem;
}
```

## Warm layer (2026-09-25, supersedes the Midnight/cyan palette)
Owner feedback: the site "felt AI-generated". `assets/css/warm.css` is linked last on every main-site page and overrides colours and type; `styles.css`, `hallmark.css` and `tokens.css` stay untouched underneath (rollback = remove that one `<link>` per page).
- Palette from the Louvre cover and the cream reading pages. Dark (default): bg `#15110d`, ink `#ece4d6`, muted `#ada28f`, rule `#352c23`, accent ochre `#d9ae62`. Light: bg `#faf8f3`, ink `#1b1a17`, muted `#625c52`, rule `#e4ded2`, accent `#8a6a12`. All text pairs ≥ 4.7:1.
- Serif headings (Iowan / Palatino Linotype / TeX Gyre Pagella → Songti / Noto Serif CJK → YaHei), sans body. No monospace outside code blocks.
- Removed on purpose — do not reintroduce: research-constellation SVG, JG monogram box, uppercase mono eyebrows, 01–06 section numbers, coloured trailing periods on headings, slogan headings ("Explore, create, reflect." etc.), research-interest pill tags, keyword lines, card chrome/glows/grid background, ↗ on internal links (external links keep it).
- Photography and Social are unlinked from the nav/homepage until they have real content; the pages still exist.
- Header text over the cover painting is always light, in both themes.

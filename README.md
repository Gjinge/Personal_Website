# Jinge Guo — Academic website

Static academic homepage, designed for GitHub Pages. A dark technology theme with a light alternative, an animated research illustration, and an asynchronous MapMyVisitors widget. Plain HTML, CSS, and small vanilla JavaScript; no build step or external fonts.

Expected public URL: https://gjinge.github.io/Personal_Website/

## Files

```text
index.html                  Page content and metadata
projects/index.html         Main project cards at /projects/
projects/unity/index.html   Unity overview: two games and grouped code notes
projects/fpga-gomoku/index.html  FPGA Gomoku (VHDL) project page
projects/*/index.html       Game details and redirects for former exercise pages
projects.html, unity-*.html  Redirects for older project URLs
source/unity/               Project Assets, Packages, ProjectSettings, and manifests
source/fpga-gomoku/         VHDL sources, constraints, .coe image data, Vivado reports, bitstream, project file
assets/downloads/           Per-project source ZIPs and the FPGA project report
photography.html            Photo collections and fullscreen viewer
social.html                 Personal social accounts and channels
reading.html                Searchable reading notes index
assets/js/reading-data.js    Published note metadata and links
assets/js/reading.js         Note cards, search, topic filter, date ordering
videos.html                 Redirect for the former page URL
assets/js/portfolio-data.js  Real photos and public account entries
assets/js/portfolio.js       Collection filters, photo viewer, account cards
assets/css/styles.css       Responsive styles
assets/js/main.js           Theme, motion controls, and navigation feedback
assets/js/visitors.js       Map loading, timeout recovery, and resizing
assets/img/favicon.svg      JG favicon
assets/img/og-image.png      Social sharing preview
cv.pdf                      Public curriculum vitae
.nojekyll                   Disable Jekyll processing
README.md                   Maintenance and deployment
```

## Local preview

From this directory, run `python -m http.server 8000 --bind 127.0.0.1`, then open http://127.0.0.1:8000/.

## Update content

- **News:** edit the `#news` section in `index.html`. Add one `<li>` per announcement, newest first, with a `.news-date` label and a paragraph containing at least one relevant link (university, paper, project, or venue). The first entry announces the Fall 2026 UW–Madison visiting semester. Future submission and acceptance news should use confirmed dates and exact statuses; do not describe submitted or under-review work as accepted. Use a term or month label when no exact date is known.
- **CV:** replace `cv.pdf` with a reviewed, public version. Check both the PDF text and embedded links for private information before publishing.
- **Research and manuscripts:** edit the corresponding sections in `index.html`. Preserve the exact status of submitted work; add authors or paper links only when confirmed. Update the footer date when content changes.
- **Hero illustration:** `.research-visual` in `index.html` is a decorative SVG research constellation with a JG monogram. It represents research themes, not measured results. Replace it with a real photograph if desired and provide descriptive alt text.
- **Links:** edit existing links in `index.html`. Add academic profiles only after verifying their URLs.
- **Address change:** update the canonical URL, `og:url`, `og:image`, and Schema.org `url` in `index.html`, plus this README.
- **Appearance:** edit `assets/css/styles.css`; check desktop and mobile layouts and keyboard focus after changes.
- **Display preferences:** the header provides theme and motion controls. `jg-theme` and `jg-motion` in localStorage retain only these preferences. The default is dark; reduced-motion system preferences disable decorative animation. The page remains readable when JavaScript or localStorage is unavailable. Print styles use a light background.
- **Reading progress:** the shared top rail is a Pac-Man maze row drawn in CSS. Pac-Man tracks the scroll position, faces the direction of travel, and chomps only while scrolling; three ghosts trail behind him and turn frightened blue once the page is fully read. Small pellets mark the remaining page; larger glowing power pellets sit at each section, are spaced at least 26px apart, and disappear as they are passed. Clicking any pellet or position on the rail, or dragging, jumps to that reading position, and hovering shows the section name at that point. A native range control backs the rail for keyboard navigation and exposes the current percentage to screen readers. Position and pellets rebuild when the page height changes, such as after images load or code notes expand. All animation respects the motion toggle and the reduced-motion preference. The rail is hidden in print and without JavaScript; seeking is disabled on pages that fit entirely in the viewport.

## Photography and social accounts

The header links to About, Publications, Projects, CV, Photography, Social, and Reading Notes. Social is a directory of the owner's social media accounts and channels. The former `videos.html` URL redirects to `social.html`. Existing research, education, honors, and contact sections remain on the homepage. The old `#manuscripts` link remains available; review status must not be represented as an accepted publication.

Both pages initially show an honest empty state. Add real photos and user-provided public account links to `assets/js/portfolio-data.js`. No demo images or invented accounts are published. The following is a schema example, not an existing account or work:

```js
window.portfolio = {
  photos: [{
    src: 'assets/photos/your-photo.webp',
    full: 'assets/photos/your-photo-large.jpg', // optional
    alt: 'Describe what is visible in this photograph',
    title: 'Your photo title',
    collection: 'Your series name',
    caption: 'Optional place, date, or short story'
  }],
  accounts: [{
    url: 'https://your-platform.example/your-profile',
    name: 'Your account display name',
    handle: '@your-handle', // optional
    description: 'What you share on this account',
    avatar: 'assets/social/your-avatar.webp', // optional
    platform: 'Your social platform'
  }]
};
```

- Photos retain their proportions in a responsive column layout. Series names create filters automatically. Click to open the modal viewer; use Previous/Next, arrow keys, or Escape to close. The modal restores keyboard focus to the opening photo.
- Export web-sized photos before adding them; include descriptive alt text. Publish only selected images and captions. Strip location metadata if you do not want it exposed.
- Account cards display the platform, account name, optional handle/avatar, and content focus. HTTPS profile links open in a new tab. Missing avatars use a neutral @ symbol.
- Use account/channel homepages rather than individual video URLs. No account credentials are needed in this repository, and this page does not preload platform feeds or players.
- Update shared navigation in all content HTML pages together. Theme controls use the same preferences across pages.
- Photos and account cards require JavaScript for rendering; an explanatory message is shown when it is disabled.

## Unity projects

`projects/` lists one card per main project. **FPGA Gomoku** (`projects/fpga-gomoku/`) is a four-person Digital System Design course project in VHDL: 640x480 VGA rendering, PS/2 mouse input, a 15x15 board held in two 225-bit vectors, undo via a move stack, win detection, and a heuristic AI opponent, targeting a Nexys 4 DDR board (Artix-7 `xc7a100tcsg324-1`, Vivado 2020.2, top module `vga_ctrl`). The page carries two photographs of the VGA output, the module and implementation tables, an AI scoring excerpt, a link to `source/fpga-gomoku/`, a source ZIP, and the project report.

Resource, timing, and power figures on that page are read from the Vivado reports of the final build in `source/fpga-gomoku/reports/`, which includes the start-screen image ROM; the written report analyses an earlier build and its tables differ. Source comments were originally GBK and are stored here converted to UTF-8, logic unchanged. The Block Memory Generator IP is not committed and is re-created from `source/fpga-gomoku/ip/fmxxx_rgb444.coe`. The report PDF is published with the four authors credited and their student ID numbers removed from page 1; that page is therefore a rendered image while pages 2-5 remain text. Third-party Gomoku projects collected as course reference material are not included.

The Projects navigation opens `projects/`, where Unity Game Development is one main project with the original Apple Picker gameplay image as its cover. The cover and title open `projects/unity/`. This overview links to the two game pages, `projects/apple-picker/` and `projects/mission-demolition/`, and groups Collections, Hello World, and Boids under Code & scene notes. These exercises have collapsible code excerpts, file links, and ZIP downloads rather than standalone project cards.

The former `projects/{collections,hello-world,boids}/` and matching `unity-*.html` URLs redirect to the corresponding `#practice-<slug>` anchors on the Unity overview, preserving query strings. Other legacy project URLs retain their existing redirects. Game pages return to the Unity overview. Original source files and downloads are unchanged.

Card images use a shared 16:9 frame, capped at 300 px high. Detail images retain their full proportions, fit a 930 px gallery column, and are capped at 540 px high. Clicking a detail image opens the original image. Images are not cropped to fit the frame.

- Exports include each project's Assets, Packages, and ProjectSettings: the 23 coursework C# scripts plus original supporting assets, scenes, textures, audio, materials, fonts, and notices. Per-project `manifest.json` files record original and exported SHA-256 hashes. ZIP contents match the published source directories.
- Add an extracted project folder in Unity Hub using its recorded editor version. Registry packages are restored on first import. These exports preserve existing prototype bugs and missing references; complete clean-import/gameplay validation has not been performed.
- Library, Temp, Logs, obj, UserSettings, builds, credentials, and local IDE files are excluded. Cloud account associations and signing fields are cleared in exported settings, and cloud connections disabled. The optional Boids Code Assist editor plugin is excluded and its lock entry removed. Gameplay C# source remains unchanged. Original comments, tutorial context, and third-party notices are preserved; no broad new source license is assigned.
- `assets/img/unity/apple-picker-game.png` is a real Unity 6000.0.44f1 play-mode camera capture from an isolated copy. The screen-space UI was attached to the capture camera; the original background and game assets are visible.
- `mission-demolition-game.png` is an edit-mode rendering of the original scene with a wider camera and a neutral background, excluding UI. The runtime check exposed missing UI references and an empty level list. The page labels it an editor overview and records limitations.
- Other previews are labelled SVG source excerpts, not gameplay screenshots. Boids has scene/prefab files but no custom behavior scripts in the supplied Assets, so no flocking implementation is claimed.
- Original projects were not modified. No Unity capture scripts or test logs are published. Hash manifests and code excerpt graphics were generated from the supplied project files.
- The homepage `#projects` entry links to the Unity overview. Adding another main project requires its own cover card on the Projects index and a detail page; related games and exercises belong inside that project.

## Reading notes

`reading.html` shows a notebook empty state until real entries are added. It supports full-text matching across title, author, summary, and tags, combined with topic filtering. Entries appear newest first using ISO dates (`YYYY-MM-DD`); undated entries appear last. No sample notes are published.

Put the reviewed note PDF or HTML under `notes/` (create the folder when adding the first note), then add its metadata to `assets/js/reading-data.js`. External HTTPS article links also work. This is an example schema only:

```js
window.readingNotes = [{
  title: 'Book title — chapter or note title',
  author: 'Book author',
  date: '2026-09-09',
  tags: ['Your topic'],
  summary: 'A short introduction to your reflections.',
  url: 'notes/your-reading-note.pdf'
}];
```

Use an HTML page or PDF for directly readable notes; Markdown can be converted to HTML before publishing. Clicking a note title opens its document. External links open in a new tab. Relative document links work on both GitHub Pages and the local HTTP preview. The site has no upload backend: add files and update the data array, then deploy normally. Search only covers the listed metadata, not the full text inside linked files.

## Visitor map

The `Visitors` section near the footer loads the MapMyVisitors interactive map. Its public statistics page is https://mapmyvisitors.com/web/1c84z and is registered for this website. The embed identifier is public, not an account credential.

- `assets/js/visitors.js` inserts exactly one `id="mapmyvisitors"` script. Do not add another embed in the HTML.
- The HTTPS script loads asynchronously. `w=a` sizes the map to its parent, which is limited to 780 px and fits mobile screens.
- MapMyVisitors processes visitor IP addresses for approximate geolocation and statistics. The page includes attribution and a privacy-policy link. Ad blockers or network restrictions can prevent the map or counting from working.
- Public-page checks and local previews with the widget enabled can contribute test visits. Do not interpret pageviews as distinct people.
- If the script fails or the interactive map is not ready within 10 seconds, the page tries the provider's official static map once. If that also fails or times out, it displays an unavailable message and retains the statistics link. Recovery from a partial load can produce an additional recorded request; no automatic retry loop runs.
- The map's aspect ratio, background, and marker projection adapt when the browser or side panel changes width. The injected statistics link is normalized to HTTPS.
- To replace the widget, obtain its new complete embed code from MapMyVisitors, update the identifier and statistics URL in `assets/js/visitors.js`, and update the statistics link in `index.html`.

## Deploy through GitHub Pages

1. Commit these files to `main` and push to `Gjinge/Personal_Website`.
2. Open the repository **Settings**.
3. Select **Pages**.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select branch **main** and directory **/ (root)**, then **Save**.
6. Wait for the Pages deployment to succeed, then open the public URL above.
7. Confirm the page, navigation, images, and `cv.pdf` load over HTTPS.

Deployment status is shown in the repository's Actions and Pages settings. The expected URL is not proof that deployment has completed.

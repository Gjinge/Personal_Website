# Jinge Guo — Academic website

Static academic homepage, designed for GitHub Pages. A dark technology theme with a light alternative, an animated research illustration, and an asynchronous MapMyVisitors widget. Plain HTML, CSS, and small vanilla JavaScript; no build step or external fonts.

Expected public URL: https://gjinge.github.io/Personal_Website/

## Files

```text
index.html                  Page content and metadata
photography.html            Photo collections and fullscreen viewer
videos.html                 Video portfolio with external work links
assets/js/portfolio-data.js  Real photo and video entries
assets/js/portfolio.js       Collection filters, photo viewer, video cards
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

- **CV:** replace `cv.pdf` with a reviewed, public version. Check both the PDF text and embedded links for private information before publishing.
- **Research and manuscripts:** edit the corresponding sections in `index.html`. Preserve the exact status of submitted work; add authors or paper links only when confirmed. Update the footer date when content changes.
- **Hero illustration:** `.research-visual` in `index.html` is a decorative SVG research constellation with a JG monogram. It represents research themes, not measured results. Replace it with a real photograph if desired and provide descriptive alt text.
- **Links:** edit existing links in `index.html`. Add academic profiles only after verifying their URLs.
- **Address change:** update the canonical URL, `og:url`, `og:image`, and Schema.org `url` in `index.html`, plus this README.
- **Appearance:** edit `assets/css/styles.css`; check desktop and mobile layouts and keyboard focus after changes.
- **Display preferences:** the header provides theme and motion controls. `jg-theme` and `jg-motion` in localStorage retain only these preferences. The default is dark; reduced-motion system preferences disable decorative animation. The page remains readable when JavaScript or localStorage is unavailable. Print styles use a light background.

## Photography and video portfolio

The header links to About, Publications, Projects, CV, Photography, and Videos. Existing research, education, honors, and contact sections remain on the homepage. The old `#manuscripts` link remains available; review status must not be represented as an accepted publication.

Both creative pages initially show an honest empty state. Add real works to `assets/js/portfolio-data.js`. No demo images or invented video links are published. The following is a schema example, not an existing work:

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
  videos: [{
    url: 'https://your-video-platform.example/your-work',
    title: 'Your video title',
    description: 'A short description of the work',
    poster: 'assets/videos/your-cover.webp', // optional
    platform: 'Your video platform'
  }]
};
```

- Photos retain their proportions in a responsive column layout. Series names create filters automatically. Click to open the modal viewer; use Previous/Next, arrow keys, or Escape to close. The modal restores keyboard focus to the opening photo.
- Export web-sized photos before adding them; include descriptive alt text. Publish only selected images and captions. Strip location metadata if you do not want it exposed.
- Video cards use local covers and HTTPS links. A missing cover uses a neutral play panel. The player opens on the original platform in a new tab; this site does not preload external players.
- Keep actual video files on the selected video platform, and store their public work links here. No account credentials are needed in this repository.
- Update shared navigation in all three HTML pages together. Theme controls use the same preferences across pages.
- Photos and videos require JavaScript for rendering; an explanatory message is shown when it is disabled.

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

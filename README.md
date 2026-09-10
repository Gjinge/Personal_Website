# Jinge Guo — Academic website

Static academic homepage, designed for GitHub Pages. A dark technology theme with a light alternative, an animated research illustration, and an asynchronous MapMyVisitors widget. Plain HTML, CSS, and small vanilla JavaScript; no build step or external fonts.

Expected public URL: https://gjinge.github.io/Personal_Website/

## Files

```text
index.html                  Page content and metadata
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

# Jinge Guo — Academic website

Static academic homepage, designed for GitHub Pages. Plain HTML and CSS; no build step, JavaScript, external fonts, analytics, or cookies.

Expected public URL: https://gjinge.github.io/Personal_Website/

## Files

```text
index.html                  Page content and metadata
assets/css/styles.css       Responsive styles
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
- **Photograph:** the initial design uses a CSS JG monogram. To add a real photograph, place it in `assets/img/`, replace `.hero-monogram` with an image with descriptive alt text, and size it responsively.
- **Links:** edit existing links in `index.html`. Add academic profiles only after verifying their URLs.
- **Address change:** update the canonical URL, `og:url`, `og:image`, and Schema.org `url` in `index.html`, plus this README.
- **Appearance:** edit `assets/css/styles.css`; check desktop and mobile layouts and keyboard focus after changes.

## Deploy through GitHub Pages

1. Commit these files to `main` and push to `Gjinge/Personal_Website`.
2. Open the repository **Settings**.
3. Select **Pages**.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select branch **main** and directory **/ (root)**, then **Save**.
6. Wait for the Pages deployment to succeed, then open the public URL above.
7. Confirm the page, navigation, images, and `cv.pdf` load over HTTPS.

Deployment status is shown in the repository's Actions and Pages settings. The expected URL is not proof that deployment has completed.

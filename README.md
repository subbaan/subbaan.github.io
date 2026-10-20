# Subbaan website

Version: 1.2.5

The source for **https://subbaan.github.io**, a static portfolio of Subbaan's software, with a Ko-fi link.
It has no framework, CDN, cookies or backend. On the live site only, a small footer counter uses [GoatCounter](https://www.goatcounter.com) (`subbaan.goatcounter.com`), which sets no cookies and stores nothing in the browser. The page is `index.html`; `build.sh` refreshes the generated assets.

## Layout

| Path | What it is |
|---|---|
| `index.html` | The whole page: markup, CSS, and the `PROJECTS` / `WORKSHOP` lists (hand-edited) |
| `assets/releases.js` | Latest version, date, licence and download link per repo. **Generated** by `build.sh` |
| `assets/img/<project>/` | Screenshots (`name.webp`) and card thumbnails (`name-thumb.webp`). **Generated** by `build.sh` |
| `assets/og.png` | The 1200×630 link-preview image. **Generated** by `build.sh` |
| `build.sh` | Refreshes all generated assets |
| `assets/video/` | Bunzi gameplay loop and full demo, cut from `bunzi.mp4`. **Generated** by `build.sh` |
| `assets/brand/` | Logo and favicons, made from your full-size profile picture (not published; see `./build.sh --help`). **Generated** by `build.sh` |
| `.nojekyll` | Tells GitHub Pages to serve files as-is |

## Updating

```bash
./build.sh              # everything
./build.sh --releases   # only release info (after you publish a new release)
./build.sh --images     # only screenshots + preview image
./build.sh --videos     # only the Bunzi video clips (about a minute)
./build.sh --help
```

- Screenshots are read from the sibling project folders (`../bunzi/docs/screenshots/…` and so on). To change which ones appear, edit `IMAGES` in `build.sh`, then the matching `images:` entry in `index.html`.
- Release data comes from `gh` for the public repos listed in `REPOS` in `build.sh`. Private repos are skipped even if listed.
- To add a project, add it to `REPOS` (and `IMAGES`) in `build.sh` and to `PROJECTS` in `index.html`, then run `./build.sh`.
- The original recording `bunzi.mp4` (89 MB) stays in this folder for rebuilding, but `.gitignore` keeps it out of the published site. The loop segments and crop areas are set at the top of `build.sh`.
- `build.sh` only writes inside `assets/` and never deletes anything. Remove old screenshots by hand.

## Preview locally

Open `index.html` directly in a browser, or run `python -m http.server 8000` and visit `http://localhost:8000`.
Project popups have shareable links, e.g. `https://subbaan.github.io/#/radiowave`.

## Publish with GitHub Pages

1. Create a **public** repo named exactly `subbaan.github.io`.
2. Push this folder's contents to its `main` branch.
3. In the repo, go to Settings › Pages and set Source to "Deploy from a branch", branch `main`, folder `/ (root)`.
4. The site appears at https://subbaan.github.io within a minute or two.

## Changelog

- **1.2.5**: Added Prowal, the pop-up app launcher, with six screenshots and its v1.0.1 download.
- **1.2.4**: Removed the bottom Support section and its nav link. The side box now says "buy me a coffee".
- **1.2.3**: The Support section is now a small, quiet strip instead of a big panel.
- **1.2.2**: Small cookie-free visit counter in the footer (GoatCounter, live site only).
- **1.2.1**: Bunzi copy mentions its real RGBA rendering, parallax backgrounds and the dissolving-terminal intro.
- **1.2.0**: Bunzi gameplay video: an 18 s silent loop in the Featured box and on the Bunzi card, and the full demo with sound in the Bunzi popup. Animations are replaced by still images when the visitor prefers reduced motion. `build.sh --videos` makes the clips.
- **1.1.2**: The full-size profile picture is no longer kept in the site; `build.sh` reads it from `SUBBAAN_ICON` when you want to regenerate the logo.
- **1.1.1**: Ko-fi profile picture as the logo and favicon. The Radiowave card and gallery now lead with the animated RGBA visualizer clip.
- **1.1.0**: Real content for all nine public projects, with screenshots, a gallery popup, live release versions and direct downloads. Added a Bunzi featured slideshow, an "In the workshop" section (LatticeFM, Plica, Gruvbox), a "Latest releases" box, Ko-fi gift wording, a link-preview image, and `build.sh`.
- **1.0.0**: Initial static template.

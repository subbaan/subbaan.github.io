#!/usr/bin/env bash
# build.sh — refresh the Subbaan website's generated assets.
#
#   assets/img/<project>/<name>.webp        full-size screenshots
#   assets/img/<project>/<name>-thumb.webp  card thumbnails
#   assets/releases.js                      latest release data from GitHub
#   assets/og.png                           link-preview image
#   assets/brand/*                          logo + favicons from $SUBBAAN_ICON
#   assets/video/bunzi-*.mp4                web clips cut from $SUBBAAN_BUNZI_VIDEO
#
# Screenshots are read from sibling project folders (see IMAGES below).
# Release data comes from `gh`, for the PUBLIC repos listed in REPOS only.
# This script only ever writes inside ./assets; it never deletes anything.

set -euo pipefail

VERSION="1.2.2"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS="${SUBBAAN_PROJECTS:-$(dirname "$ROOT")}"
GH_USER="subbaan"

# site-id  repo-name  (public repos only)
REPOS=(
  "bunzi bunzi"
  "radiowave radiowave"
  "1cheri 1cheri"
  "nordtui nordtui"
  "litreader litreader"
  "blitz-cipher blitz_cipher"
  "ytseries ytseries"
  "notes notes"
  "waste-tui waste-tui"
  "prowal prowal"
)

# site-id  source-path (relative to $PROJECTS)  [lossy]
IMAGES=(
  "bunzi bunzi/docs/screenshots/title.png lossy"
  "bunzi bunzi/docs/screenshots/moonlit_ruins.png lossy"
  "bunzi bunzi/docs/screenshots/sunset_lake.png lossy"
  "bunzi bunzi/docs/screenshots/tropical_island.png lossy"
  "bunzi bunzi/docs/screenshots/crystal_caverns.png lossy"
  "bunzi bunzi/docs/screenshots/results.png lossy"
  "radiowave radiowave/images/player-normal.png"
  "radiowave radiowave/images/manager-trending.png"
  "radiowave radiowave/images/manager-favorites.png"
  "radiowave radiowave/images/genre-picker.png"
  "radiowave radiowave/images/settings.png"
  "nordtui nordtui/images/nordtui01.png"
  "nordtui nordtui/images/nordtui02.png"
  "litreader litreader/images/mainmenu.png"
  "litreader litreader/images/story.png"
  "litreader litreader/images/explore_view.png"
  "litreader litreader/images/config.png"
  "blitz-cipher games/blitz_cipher/images/titlepage.png"
  "blitz-cipher games/blitz_cipher/images/levelpreview1.png"
  "blitz-cipher games/blitz_cipher/images/levelpreview2.png"
  "ytseries ytseries/images/mainmenu.png"
  "ytseries ytseries/images/browsemenu.png"
  "ytseries ytseries/images/configmenu.png"
  "notes notes/images/mainmenu.png"
  "notes notes/images/notecontent.png"
  "notes notes/images/notesconfig.png"
  "waste-tui waste/images/network.png"
  "waste-tui waste/images/chat.png"
  "waste-tui waste/images/keymanager.png"
  "waste-tui waste/images/settings.png"
  "prowal prowal/docs/screenshots/popup.png"
  "prowal prowal/docs/screenshots/popup-group.png"
  "prowal prowal/docs/screenshots/popup-panel.png"
  "prowal prowal/docs/screenshots/editor.png"
  "prowal prowal/docs/screenshots/icon-picker.png"
  "prowal prowal/docs/screenshots/preferences.png"
  "gruvbox gruvbox/artifacts/desktop-phrase-main.png"
  "gruvbox gruvbox/artifacts/desktop-fx.png"
)

# Bunzi demo recording (1580x916, 60 fps). The game picture sits at 1440x810+66+64
# (3x the native 480x270); the whole terminal window at 1538x876+18+20.
BUNZI_GAME_CROP="1440:810:66:64"
BUNZI_WINDOW_CROP="1538:876:18:20"
# Loop segments, "start duration" in seconds: one from each level.
BUNZI_LOOP=("42 4.5" "57 4.5" "76 4.5" "92 4.5")

# Files copied verbatim (already web-ready): site-id  source  dest-name
COPIES=(
  "radiowave radiowave/images/radiowave_rgba_vis.webp rgba-visualizer.webp"
)

usage() {
  cat <<EOF
Usage: ./build.sh [OPTIONS]

Refresh the website's generated assets (screenshots, release data, preview image).
With no options, does everything.

Options:
  --images      Only rebuild screenshots and the preview image
  --releases    Only refresh assets/releases.js from GitHub (needs gh)
  --videos      Only rebuild the Bunzi video clips (needs ffmpeg; slow)
  -h, --help    Show this help and exit
  -V, --version Show version and exit

Environment:
  SUBBAAN_PROJECTS  Folder holding the project checkouts
                    (default: the parent of this site folder)
  SUBBAAN_ICON      Full-size profile picture for the logo and favicons
                    (default: assets/subbaan_icon.png; skipped if missing)
  SUBBAAN_BUNZI_VIDEO  Full-quality Bunzi demo recording
                    (default: ./bunzi.mp4; skipped if missing)
EOF
}

do_images=0 do_releases=0 do_videos=0
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -V|--version) echo "subbaan-site build.sh $VERSION"; exit 0 ;;
    --images) do_images=1 ;;
    --releases) do_releases=1 ;;
    --videos) do_videos=1 ;;
    *) echo "build.sh: unknown option '$arg' (try --help)" >&2; exit 2 ;;
  esac
done

(( do_images + do_releases + do_videos )) || do_images=1 do_releases=1 do_videos=1

need() { command -v "$1" >/dev/null || { echo "build.sh: '$1' is required" >&2; exit 1; }; }

build_images() {
  need magick
  local id src mode name out
  for entry in "${IMAGES[@]}"; do
    read -r id src mode <<<"$entry"
    if [[ ! -f "$PROJECTS/$src" ]]; then
      echo "  ! missing $PROJECTS/$src (skipped)" >&2; continue
    fi
    name="$(basename "$src" .png)"; name="${name//_/-}"
    out="$ROOT/assets/img/$id"; mkdir -p "$out"
    if [[ "$mode" == "lossy" ]]; then
      magick "$PROJECTS/$src" -resize '1400x>' -quality 90 "$out/$name.webp"
    else
      magick "$PROJECTS/$src" -resize '1400x>' -define webp:lossless=true "$out/$name.webp"
    fi
    magick "$PROJECTS/$src" -resize '720x>' -quality 82 "$out/$name-thumb.webp"
    echo "  img $id/$name"
  done
  local dest
  for entry in "${COPIES[@]}"; do
    read -r id src dest <<<"$entry"
    [[ -f "$PROJECTS/$src" ]] || { echo "  ! missing $PROJECTS/$src (skipped)" >&2; continue; }
    mkdir -p "$ROOT/assets/img/$id"
    cp -f "$PROJECTS/$src" "$ROOT/assets/img/$id/$dest"
    echo "  cp  $id/$dest"
  done

  # Logo and favicons, from the full-size Ko-fi profile picture.
  # The original isn't published; keep it elsewhere and point SUBBAAN_ICON at it if needed.
  local icon="${SUBBAAN_ICON:-$ROOT/assets/subbaan_icon.png}"
  if [[ -f "$icon" ]]; then
    mkdir -p "$ROOT/assets/brand"
    magick "$icon" -resize 128x128 -quality 90 "$ROOT/assets/brand/logo.webp"
    magick "$icon" -resize 64x64 "$ROOT/assets/brand/favicon.png"
    magick "$icon" -resize 180x180 "$ROOT/assets/brand/apple-touch-icon.png"
    echo "  ico assets/brand/"
  else
    echo "  - no $icon, keeping the existing assets/brand files"
  fi

  # 1200x630 link-preview card: Bunzi title art with a dark band and the site name.
  local og="$PROJECTS/bunzi/docs/screenshots/title.png"
  if [[ -f "$og" ]]; then
    magick "$og" -filter point -resize 1200x675^ -gravity center -extent 1200x630 \
      \( -size 1200x150 xc:'#1d2021e6' \) -gravity south -composite \
      -font DejaVu-Sans-Bold -pointsize 54 -fill '#ebdbb2' -gravity southwest -annotate +48+62 'Subbaan.' \
      -font DejaVu-Sans -pointsize 26 -fill '#fabd2f' -gravity southwest -annotate +48+28 'Free Linux software, terminal tools and games' \
      -define png:exclude-chunks=date,time "$ROOT/assets/og.png"
    echo "  og  assets/og.png"
  fi
}

build_releases() {
  need gh; need jq
  local tmp; tmp="$(mktemp)"
  echo '{}' >"$tmp"
  local id repo info rel
  for entry in "${REPOS[@]}"; do
    read -r id repo <<<"$entry"
    info="$(gh repo view "$GH_USER/$repo" --json isPrivate,licenseInfo,stargazerCount,primaryLanguage,pushedAt,url)"
    if [[ "$(jq -r .isPrivate <<<"$info")" != "false" ]]; then
      echo "  ! $repo is private, left out" >&2; continue
    fi
    rel="$(gh release view -R "$GH_USER/$repo" --json tagName,publishedAt,url,assets 2>/dev/null || echo null)"
    jq --arg id "$id" --argjson info "$info" --argjson rel "$rel" '
      .[$id] = {
        repo: $info.url,
        license: ($info.licenseInfo.key // null | if . then ascii_upcase else null end),
        stars: $info.stargazerCount,
        language: ($info.primaryLanguage.name // null),
        updated: $info.pushedAt[0:10],
        version: ($rel.tagName // null),
        released: ($rel.publishedAt // "" | .[0:10] | if . == "" then null else . end),
        releaseUrl: ($rel.url // null),
        download: (($rel.assets // []) | map(select(.name | test("linux|x86_64|amd64|^[^.]+$"; "i")) | select(.name | test("source"; "i") | not)) | first
                   | if . then {name: .name, url: .url, size: .size} else null end)
      }' "$tmp" >"$tmp.n" && mv "$tmp.n" "$tmp"
    echo "  rel $repo $(jq -r --arg id "$id" '.[$id].version // "no release"' "$tmp")"
  done
  {
    echo "// Generated by build.sh $VERSION on $(date -u +%Y-%m-%d). Do not edit by hand; run ./build.sh --releases"
    printf 'window.RELEASES = '; jq -S . "$tmp"; echo ';'
    echo "window.RELEASES_BUILT = \"$(date -u +%Y-%m-%d)\";"
  } >"$ROOT/assets/releases.js"
  rm -f "$tmp"
  echo "  wrote assets/releases.js"
}

build_videos() {
  local src="${SUBBAAN_BUNZI_VIDEO:-$ROOT/bunzi.mp4}"
  if [[ ! -f "$src" ]]; then
    echo "  - no $src, keeping the existing assets/video files"; return
  fi
  need ffmpeg
  local out="$ROOT/assets/video"; mkdir -p "$out"
  local enc=(-c:v libx264 -preset slow -pix_fmt yuv420p -movflags +faststart)

  # Silent featured loop: game picture only, at 2x native size, hard cuts between levels.
  local inputs=() chain="" n=0 seg start dur
  for seg in "${BUNZI_LOOP[@]}"; do
    read -r start dur <<<"$seg"
    inputs+=(-ss "$start" -t "$dur" -i "$src")
    chain+="[$n:v]crop=$BUNZI_GAME_CROP,scale=960:540:flags=area,setsar=1,fps=60[v$n];"
    n=$((n + 1))
  done
  for ((k = 0; k < n; k++)); do chain+="[v$k]"; done
  chain+="concat=n=$n:v=1:a=0[out]"
  ffmpeg -v error -y "${inputs[@]}" -filter_complex "$chain" -map '[out]' -an "${enc[@]}" -crf 27 "$out/bunzi-loop.mp4"
  ffmpeg -v error -y -i "$out/bunzi-loop.mp4" -frames:v 1 -q:v 3 "$out/bunzi-loop.jpg"
  echo "  vid assets/video/bunzi-loop.mp4 ($(du -h "$out/bunzi-loop.mp4" | cut -f1))"

  # Full demo with sound: the whole terminal window, so the text-to-game dissolve shows.
  ffmpeg -v error -y -i "$src" -vf "crop=$BUNZI_WINDOW_CROP,scale=1280:-2:flags=area,setsar=1" \
    "${enc[@]}" -crf 28 -c:a aac -b:a 112k "$out/bunzi-demo.mp4"
  ffmpeg -v error -y -ss 40 -i "$out/bunzi-demo.mp4" -frames:v 1 -q:v 3 "$out/bunzi-demo.jpg"
  echo "  vid assets/video/bunzi-demo.mp4 ($(du -h "$out/bunzi-demo.mp4" | cut -f1))"
}

cd "$ROOT"
(( do_images )) && { echo "Screenshots from $PROJECTS"; build_images; }
(( do_releases )) && { echo "Releases from github.com/$GH_USER"; build_releases; }
(( do_videos )) && { echo "Videos"; build_videos; }
echo "Done (build.sh $VERSION)."

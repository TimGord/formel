#!/usr/bin/env bash
# Builds the WebAssembly module into web/pkg (via formel-wasm/build-wasm.sh) and fills in its size in
# the demo's header.
# Needs: rustup target add wasm32-unknown-unknown; cargo install wasm-bindgen-cli --version 0.2.100
# Also needs python3 (renders the font license page).
# Optional: wasm-opt from binaryen on PATH (applied when present).
# Serve afterwards with e.g.: python3 -m http.server -d web 8000
set -euo pipefail
cd "$(dirname "$0")/.."

# The cargo, wasm-bindgen and wasm-opt steps live in formel-wasm/build-wasm.sh, shared with the npm
# package (`.github/workflows/npm.yml`), so the demo and the package cannot drift apart.
formel-wasm/build-wasm.sh --out-dir "$PWD/web/pkg"

wasm=web/pkg/formel_wasm_bg.wasm

# The header states the download size, so compute it from the file just built rather than keeping a
# number in the source. Replacing the element's text (not a placeholder) keeps rebuilds idempotent.
gzip -9 -c "$wasm" > "$wasm.gz"
size=$(awk -v n="$(stat -c%s "$wasm")" -v g="$(stat -c%s "$wasm.gz")" \
  'BEGIN { printf "%.1f MB of WebAssembly (%d KB gzipped)", int(n / 100000) / 10, int(g / 1000) }')
rm "$wasm.gz"
sed -i -E "s|(<p class=\"moduleinfo\" id=\"moduleinfo\">)[^<]*</p>|\1$size</p>|" web/index.html

# The footer links to an HTML rendering of the font license list, not to the raw Markdown.
python3 web/render_licenses.py

echo "built web/pkg ($size); serve with: python3 -m http.server -d web 8000"

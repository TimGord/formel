#!/usr/bin/env bash
# Builds the WebAssembly module with wasm-bindgen, and shrinks it with wasm-opt when that is on PATH.
#
# Usage: formel-wasm/build-wasm.sh --out-dir DIR [--typescript] [--no-opt]
#
# --typescript writes the module's `.d.ts` files: the demo does not need them, the npm package does.
#
# Needs: rustup target add wasm32-unknown-unknown;
#        cargo install wasm-bindgen-cli --version 0.2.100 (must match formel-wasm/Cargo.toml).
set -euo pipefail
cd "$(dirname "$0")/.."

out_dir=
typescript=0
opt=1
while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir) out_dir=${2:?--out-dir needs a directory}; shift 2 ;;
    --typescript) typescript=1; shift ;;
    --no-opt) opt=0; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
if [ -z "$out_dir" ]; then
  echo "usage: $0 --out-dir DIR [--typescript] [--no-opt]" >&2
  exit 2
fi

bindgen_flags=()
if [ "$typescript" = 0 ]; then
  bindgen_flags+=(--no-typescript)
fi

cargo build -p formel-wasm --target wasm32-unknown-unknown --release
wasm-bindgen --target web "${bindgen_flags[@]}" --out-dir "$out_dir" \
  target/wasm32-unknown-unknown/release/formel_wasm.wasm

# Shrink the module after wasm-bindgen has added its glue. Do NOT pass `--all-features`: binaryen then
# enables proposals it can encode but browsers reject, and the output fails to instantiate with
# "unknown import kind 0x7f". Enable exactly the features rustc emits for wasm32-unknown-unknown.
wasm="$out_dir/formel_wasm_bg.wasm"
if [ "$opt" = 1 ] && command -v wasm-opt >/dev/null 2>&1; then
  wasm-opt -Oz \
    --enable-mutable-globals --enable-sign-ext --enable-bulk-memory \
    --enable-nontrapping-float-to-int --enable-multivalue --enable-reference-types \
    --enable-extended-const \
    "$wasm" -o "$wasm.opt"
  mv "$wasm.opt" "$wasm"
  # A minified module no browser can instantiate is worse than a large one, so check it right here,
  # where a failure names the stage that produced it.
  if command -v node >/dev/null 2>&1; then
    node -e "new WebAssembly.Module(require('fs').readFileSync('$wasm'))" \
      || { echo "wasm-opt produced a module that does not instantiate" >&2; exit 1; }
  fi
fi

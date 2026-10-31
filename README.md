# VRAVIO

One workspace for raster, vector, audio and video editing. A compact strip switches between the four environments; each environment keeps its own document tabs and editing state. The shell uses VRAVIO branding, icons and accent colors. Each editor currently runs in its own embedded web frame so its engine and tools remain upstream code.

## Build

Requires Rust 1.95+, `wasm32-unknown-unknown`, [Trunk](https://trunkrs.dev/), and `wasm-bindgen-cli` 0.2.129 for the video editor. Clone with `git clone --recurse-submodules` or run `git submodule update --init --recursive`.

On Windows:

```powershell
rustup target add wasm32-unknown-unknown
cargo install trunk --locked
cargo install wasm-bindgen-cli --version 0.2.129 --locked
npm ci
.\build-web.ps1
python -m http.server 8080 --directory dist
```

Open `http://localhost:8080/`. To build a Windows desktop installer, install Node.js and the [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/), then run `npm install` and `npm run build:desktop`.

The launcher alone can be built quickly with `.\build-web.ps1 -ShellOnly`, though the editor frames require the full build.

## Current integration boundary

Each environment gets one live editor frame. The launcher preserves it while changing environments and restores the environment strip after restart; the editors retain their own document persistence, internal document tabs and file formats. Opening an environment already in the shell selects that frame. Closing an environment unloads its editor after a save reminder. A single cross-environment document tab strip, cross-environment copy/paste, one shared document model, and a shell-level unsaved-changes check are not implemented yet. The build-time branding pass changes the main UI labels, accent tokens and visible community links; engine diagnostics and less common screens still need a branding audit.

In the raster editor, Filter → Restore Old Photos exports the active document as PNG to an embedded, local-processing restorer. Its result opens as a separate raster document when applied. The processing code is taken from the user's Vetor Studio project; large model weights are requested on demand from `vetor-studio.ru` and are not bundled in the installer. The classic mode also loads open models from Hugging Face on demand. Processing and cached weights stay in the browser; the image is not uploaded. The restorer currently processes the flattened image rather than editing the original layer stack in place.

The four sources are Git submodules pinned to specific commits. Their MIT/Apache-2.0 license texts and notices are copied into `dist/third-party-notices/` for distribution. VRAVIO's launcher is separate code; `brand-editors.ps1` makes UI-only changes in the local build checkout without changing the pinned upstream commits.

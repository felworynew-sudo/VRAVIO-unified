# VRAVIO

One workspace for raster, vector, audio and video editing. A compact strip switches between the four environments; document tabs belong to each editor. The shell uses VRAVIO branding, icons and accent colors. Each editor runs in its own embedded web frame so its engine and tools remain upstream code.

## Build

Requires Rust 1.95+, `wasm32-unknown-unknown`, [Trunk](https://trunkrs.dev/), PowerShell 7 (`pwsh`), and `wasm-bindgen-cli` 0.2.129 for the video editor. Clone with `git clone --recurse-submodules` or run `git submodule update --init --recursive`.

On Windows:

```powershell
rustup target add wasm32-unknown-unknown
cargo install trunk --locked
cargo install wasm-bindgen-cli --version 0.2.129 --locked
npm ci
pwsh -File .\build-web.ps1
python -m http.server 8080 --directory dist
```

Open `http://localhost:8080/`. To build a Windows desktop installer, install Node.js and the [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/), then run `npm install` and `npm run build:desktop`.

The launcher alone can be built quickly with `npm run build:shell`, though the editor frames require the full build.

## Current integration boundary

Each environment gets one live editor frame. Switching environments keeps the other frames mounted and preserves their in-memory edits. Raster and vector display their native document tabs; the shell displays only environment tabs. The editors retain their native file formats. Unsaved raster documents have layered recovery snapshots in the browser, and the vector editor can send an embedded image to Raster and receive its saved result. Raster and vector exchange rendered image selections through the shared clipboard bridge. Closing an environment asks before unloading it when documents are unsaved or their state is unknown. The four editors do not share one document model. The shell synchronizes supported theme and language changes; SoundCraft's internal controls remain English because its upstream UI has no locale catalogue. Engine diagnostics and less common screens still need a branding audit.

For a Russian project overview and publication instructions, see [PROJECT_RU.md](PROJECT_RU.md) and [PUBLISH_GITHUB_RU.md](PUBLISH_GITHUB_RU.md). A macOS universal DMG is built by GitHub Actions; see [MACOS_RU.md](MACOS_RU.md).

In the raster editor, Filter → Restore Old Photos sends the active document to an embedded Vetor Restore dialog. The default texture, repair, face and color models are bundled in this repository and published at `models/restore/`; weights load on demand and are cached in the browser. Advanced settings can skip individual steps or choose an optional third-party face model. The result can be placed into the current document or opened in a new document with original and restored layers. Processing stays in the browser; the image is not uploaded. The restorer works on a flattened input image, so it does not preserve the original layer stack inside the result.

The four sources are Git submodules pinned to specific commits. Their MIT/Apache-2.0 license texts and notices are copied into `dist/third-party-notices/` for distribution. VRAVIO's launcher is separate code; `brand-editors.ps1` applies branding and integration patches in the local build checkout without changing the pinned upstream commits.

## Return-to-source bridge

A web app can open `/#bridge=<32 lowercase hex characters>` in a new VRAVIO window. VRAVIO sends `vravio-bridge:ready` (version 1, token) to its opener. The opener replies with `vravio-bridge:open` and PNG bytes using `postMessage` to VRAVIO's exact origin. VRAVIO opens the image in Raster. File → Save / Ctrl+S exports the active bridge document as PNG and sends `vravio-bridge:saved` back to the pinned opener origin with the same token. The caller must validate the sender window, origin, token, PNG signature, dimensions, and its current record before applying the result. The token lives in the URL fragment and is never sent to the Pages server. The experimental caller is `D:\restore-lab\app\static\app.js`.

The bridge is a browser-window protocol, not an OS-wide `vravio://` handler. It keeps the caller responsible for persistence; it does not grant VRAVIO direct file-system access. Save As retains the editor's ordinary behavior. The returned PNG is a flattened result, so the caller does not receive layers or history.

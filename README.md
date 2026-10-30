# VRAVIO

One workspace for raster, vector, audio and video editing. A document tab chooses an environment, and tabs from different environments can remain open together. The shell uses VRAVIO branding, icons and accent colors. Each editor currently runs in its own embedded web frame so its engine and tools remain upstream code.

## Build

Requires Rust 1.95+, `wasm32-unknown-unknown`, [Trunk](https://trunkrs.dev/), and `wasm-bindgen-cli` 0.2.129 for the video editor. Clone with `git clone --recurse-submodules` or run `git submodule update --init --recursive`.

On Windows:

```powershell
rustup target add wasm32-unknown-unknown
cargo install trunk --locked
cargo install wasm-bindgen-cli --version 0.2.129 --locked
.\build-web.ps1
python -m http.server 8080 --directory dist
```

Open `http://localhost:8080/`. To build a Windows desktop installer, install Node.js and the [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/), then run `npm install` and `npm run build:desktop`.

The launcher alone can be built quickly with `.\build-web.ps1 -ShellOnly`, though the editor frames require the full build.

## Current integration boundary

Each environment gets one live editor frame. The launcher preserves it while changing tabs, mirrors the active document title where the editor exposes one, and restores the tab list after restart; the editors retain their own document persistence, internal document tabs and file formats. Opening an environment already in the shell selects that frame. Closing a tab unloads its editor after a save reminder. Cross-environment copy/paste, one shared document model, simultaneous shell tabs for multiple documents of the same environment, and a shell-level unsaved-changes check are not implemented yet. The build-time branding pass changes the main UI labels, accent tokens and visible community links; engine diagnostics and less common screens still need a branding audit.

The four sources are Git submodules pinned to specific commits. Their own MIT/Apache-2.0 license texts and notices remain in their repositories. VRAVIO's launcher is separate code; `brand-editors.ps1` makes UI-only changes in the local build checkout without changing the pinned upstream commits.

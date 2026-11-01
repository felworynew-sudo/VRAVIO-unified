$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

foreach ($repo in @('photocraft','vectorcraft','filmcraft','soundcraft')) {
  Copy-Item (Join-Path $root 'src-tauri/icons/128x128.png') (Join-Path $root "upstream/$repo/assets/vravio-icon.png") -Force
}
Copy-Item (Join-Path $root 'assets/wordmark-white.png') (Join-Path $root 'upstream/filmcraft/assets/vravio-wordmark-white.png') -Force
Copy-Item (Join-Path $root 'assets/wordmark-black.png') (Join-Path $root 'upstream/filmcraft/assets/vravio-wordmark-black.png') -Force

function Replace-Exact([string]$relative, [string]$old, [string]$new) {
  $file = Join-Path $root $relative
  $old = $old.Replace("`r`n", "`n")
  $new = $new.Replace("`r`n", "`n")
  $text = [IO.File]::ReadAllText($file).Replace("`r`n", "`n")
  if ($new -ne '' -and $new.Contains($old) -and $text.Contains($new)) { return }
  if (-not $text.Contains($old) -and -not $text.Contains($new)) { throw "Branding anchor changed: $relative [$old]" }
  if ($new -eq '') {
    if ($old.Contains("`n")) { $next = $text.Replace($old, '') }
    else {
      $line = [regex]::Escape($old.Trim())
      $next = [regex]::Replace($text, "(?m)^[ \t]*$line[ \t]*\n", '')
    }
  } else {
    $next = $text.Replace($old, $new)
  }
  if ($next -ne $text) { [IO.File]::WriteAllText($file, $next, [Text.UTF8Encoding]::new($false)) }
}

function Insert-Before-Once([string]$relative, [string]$anchor, [string]$marker, [string]$snippet) {
  $file = Join-Path $root $relative
  $source = [IO.File]::ReadAllText($file).Replace("`r`n", "`n")
  if ($source.Contains($marker)) { return }
  if (-not $source.Contains($anchor)) { throw "Missing insertion anchor: $relative [$anchor]" }
  [IO.File]::WriteAllText($file, $source.Replace($anchor, "$snippet`n$anchor"), [Text.UTF8Encoding]::new($false))
}

function Insert-After-Once([string]$relative, [string]$anchor, [string]$marker, [string]$snippet) {
  $file = Join-Path $root $relative
  $source = [IO.File]::ReadAllText($file).Replace("`r`n", "`n")
  if ($source.Contains($marker)) { return }
  if (-not $source.Contains($anchor)) { throw "Missing insertion anchor: $relative [$anchor]" }
  [IO.File]::WriteAllText($file, $source.Replace($anchor, "$anchor`n$snippet"), [Text.UTF8Encoding]::new($false))
}

# Only UI color tokens are adjusted. Engines and document formats remain pinned upstream.
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(139, 124, 246)' 'accent: Color32::from_rgb(161, 0, 255)'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' "    #[default]`n    ProMedium," "    ProMedium,"
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' "    Studio,`n    StudioLight," "    #[default]`n    Studio,`n    StudioLight,"
Replace-Exact 'upstream/photocraft/crates/engine/src/prefs.rs' 'default ProMedium);' 'default Studio);'
Replace-Exact 'upstream/photocraft/crates/engine/src/prefs.rs' 'theme: Theme::ProMedium,' 'theme: Theme::Studio,'
Replace-Exact 'upstream/photocraft/crates/engine/src/prefs.rs' 'dark_theme: DarkTheme::ProMedium,' 'dark_theme: DarkTheme::Studio,'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'PhotocraftApp::setup_context(&cc.egui_ctx, ThemeKind::Pro);' 'PhotocraftApp::setup_context(&cc.egui_ctx, ThemeKind::Studio);'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'app.set_theme(&cc.egui_ctx, ThemeKind::Pro);' 'app.set_theme(&cc.egui_ctx, ThemeKind::Studio);'
# Give the four embedded editors the same neutral dark surfaces. Their tools and
# environment-specific accent colours remain upstream-defined.
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' 'dock: Color32::from_rgb(17, 17, 18),' 'dock: Color32::from_rgb(29, 29, 31),'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' 'app_bar: hex(0x0b0d12),' 'app_bar: hex(0x141415),'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' 'panel: hex(0x181b22),' 'panel: hex(0x1d1d1f),'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' 'panel_darker: hex(0x13161c),' 'panel_darker: hex(0x141415),'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' 'pasteboard: hex(0x101217),' 'pasteboard: hex(0x0e0e0f),'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'window_bg: Color32::from_rgb(30, 30, 30),' 'window_bg: Color32::from_rgb(20, 20, 21),'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'panel_bg: Color32::from_rgb(37, 37, 38),' 'panel_bg: Color32::from_rgb(29, 29, 31),'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'toolbar_bg: Color32::from_rgb(30, 30, 31),' 'toolbar_bg: Color32::from_rgb(20, 20, 21),'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'app_bg: Color32::from_rgb(0, 0, 0),' 'app_bg: Color32::from_rgb(14, 14, 15),'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'header_bg: Color32::from_rgb(0x1d, 0x1d, 0x1d),' 'header_bg: Color32::from_rgb(0x14, 0x14, 0x15),'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'panel_bg: Color32::from_rgb(0x1d, 0x1d, 0x1d),' 'panel_bg: Color32::from_rgb(0x1d, 0x1d, 0x1f),'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'tab_bg: Color32::from_rgb(0x1d, 0x1d, 0x1d),' 'tab_bg: Color32::from_rgb(0x1d, 0x1d, 0x1f),'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' "    #[default]`n    Coral,`n    Blue," "    Coral,`n    #[default]`n    Blue,"
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' '(0x5b96ff, 0x2f74f0)' '(0x0068ff, 0x005ce6)'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' '(0x2563eb, 0x1f5ad6)' '(0x0068ff, 0x005ce6)'
Replace-Exact 'upstream/vectorcraft/crates/engine/src/prefs.rs' 'ui_accent: s("coral"),' 'ui_accent: s("blue"),'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(64, 132, 196)' 'accent: Color32::from_rgb(255, 182, 0)'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(62, 116, 180)' 'accent: Color32::from_rgb(255, 182, 0)'

# A soft selection glow stays inside the mask. Limit its line count so intricate masks keep
# PhotoCraft's fast marching-ants path and do not stall the editor.
$glow = @'
/// A subtle white glow inside the selected pixels, measured in screen pixels.
pub(super) fn selection_glow_segments(painter: &egui::Painter, xf: &ViewXform, segs: &[crate::outline::Segment], mask: &photocraft_raster::Surface, mask_scale: u32) {
    if segs.len() > 4096 { return; }
    let k = mask_scale.max(1) as i32;
    let ppp = painter.pixels_per_point();
    for (a, b) in segs {
        let mx = (i64::from(a[0]) + i64::from(b[0])).div_euclid(2) as i32;
        let my = (i64::from(a[1]) + i64::from(b[1])).div_euclid(2) as i32;
        let (minus, plus, nx, ny) = if a[1] == b[1] {
            let x = mx.div_euclid(k);
            let y = a[1].div_euclid(k);
            (mask.sample_channel(x, y - 1, 0), mask.sample_channel(x, y, 0), 0.0, 1.0)
        } else if a[0] == b[0] {
            let x = a[0].div_euclid(k);
            let y = my.div_euclid(k);
            (mask.sample_channel(x - 1, y, 0), mask.sample_channel(x, y, 0), 1.0, 0.0)
        } else { continue };
        if (minus > 0.5) == (plus > 0.5) { continue; }
        let sign = if plus > 0.5 { 1.0 } else { -1.0 };
        let centre = xf.to_screen(mx as f32, my as f32);
        let toward = xf.to_screen(mx as f32 + nx * sign, my as f32 + ny * sign) - centre;
        let length = toward.length();
        if length < 1e-4 { continue; }
        let unit = toward / length;
        let start = xf.to_screen(a[0] as f32, a[1] as f32);
        let end = xf.to_screen(b[0] as f32, b[1] as f32);
        for (offset, width, alpha) in [(2.0, 3.0, 42), (4.0, 4.0, 20), (6.0, 4.0, 8)] {
            let delta = unit * (offset / ppp);
            painter.line_segment([start + delta, end + delta], egui::Stroke::new(width / ppp, Color32::from_rgba_unmultiplied(255, 255, 255, alpha)));
        }
    }
}
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/canvas/paint.rs' '/// Draw boundary segments as marching ants:' 'pub(super) fn selection_glow_segments' $glow
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/canvas.rs' '                marching_ants_segments(input.painter, &shown, segs, time);' 'paint::selection_glow_segments(input.painter, &shown, segs, sel, k);' '                paint::selection_glow_segments(input.painter, &shown, segs, sel, k);'
$restoreItem = @'
    items.push(MenuItem {
        id: "filter.vravio.photoRestore".into(),
        label: "Реставрация старых фото…".into(),
        path: vec!["Filter".into()],
        shortcut: None,
        enabled: app.session.active().is_some() && app.services.export.is_some() && app.services.write.is_some(),
        checked: None,
        color: None,
    });
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/items.rs' '    crate::plugin_ui::insert_menu_items(app, &mut items);' 'filter.vravio.photoRestore' $restoreItem
$restoreCommand = @'
    if id == "filter.vravio.photoRestore" || (id == "layer.removeBackground" && app.services.write_unconfirmed) {
        let cutout = id == "layer.removeBackground";
        let path = if cutout { "vravio-cutout-input.png" } else { "vravio-restoration-input.png" };
        let doc = app.session.active().ok_or("no document is open".to_string());
        return Some(doc.and_then(|doc| {
            let export = app.services.export.as_ref().ok_or("PNG export is unavailable")?;
            let (bytes, _) = export(&doc.doc, path, &crate::ExportSettings::default())?;
            let write = app.services.write.as_ref().ok_or("browser bridge is unavailable")?;
            write(path, &bytes)?;
            Ok(json!({"sent": true}))
        }));
    }
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '    if id == "help.checkForUpdates" {' 'if id == "filter.vravio.photoRestore"' $restoreCommand
$bridgeSaveCommand = @'
    if id == "file.save" {
        let bridge_token = app.session.active().and_then(|st| {
            let suffix = st.doc.name.strip_prefix("vravio-bridge-")?;
            let token = suffix.get(..32)?;
            token.bytes().all(|c| c.is_ascii_hexdigit()).then(|| token.to_owned())
        });
        if let Some(token) = bridge_token {
            let path = format!("vravio-bridge-result-{token}.png");
            let doc = app.session.active().ok_or("no document is open".to_string());
            return Some(doc.and_then(|doc| {
                let export = app.services.export.as_ref().ok_or("PNG export is unavailable")?;
                let (bytes, _) = export(&doc.doc, &path, &crate::ExportSettings::default())?;
                let write = app.services.write.as_mut().ok_or("browser bridge is unavailable")?;
                write(&path, &bytes)?;
                Ok(json!({"sent": true}))
            }));
        }
    }
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '    if id == "filter.vravio.photoRestore"' 'let bridge_token = app.session.active()' $bridgeSaveCommand
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' 'let write = app.services.write.as_ref().ok_or("browser bridge is unavailable")?;' 'let write = app.services.write.as_mut().ok_or("browser bridge is unavailable")?;'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' 'if id == "filter.vravio.photoRestore" {' 'if id == "filter.vravio.photoRestore" || (id == "layer.removeBackground" && app.services.write_unconfirmed) {'
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '        let doc = app.session.active().ok_or("no document is open".to_string());' 'let cutout = id == "layer.removeBackground";' '        let cutout = id == "layer.removeBackground";'
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '        let doc = app.session.active().ok_or("no document is open".to_string());' 'let path = if cutout' '        let path = if cutout { "vravio-cutout-input.png" } else { "vravio-restoration-input.png" };'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' 'export(&doc.doc, "vravio-restoration-input.png", &crate::ExportSettings::default())?' 'export(&doc.doc, path, &crate::ExportSettings::default())?'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' 'write("vravio-restoration-input.png", &bytes)?;' 'write(path, &bytes)?;'
$restoreBridge = @'
fn notify_bridge_ready() {
    let Some(window) = web_sys::window() else { return };
    let Ok(parent) = js_sys::Reflect::get(window.as_ref(), &"parent".into()) else { return };
    let Ok(post) = js_sys::Reflect::get(&parent, &"postMessage".into()) else { return };
    let Ok(post) = post.dyn_into::<js_sys::Function>() else { return };
    let message = js_sys::Object::new();
    let _ = js_sys::Reflect::set(&message, &"type".into(), &"vravio-bridge:raster-ready".into());
    if let Ok(origin) = window.location().origin() { let _ = post.call2(&parent, &message, &origin.into()); }
}

fn send_bridge_result(path: &str, bytes: &[u8]) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let token = path.strip_prefix("vravio-bridge-result-").and_then(|s| s.strip_suffix(".png")).ok_or("invalid bridge path")?;
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    js_sys::Reflect::set(&message, &"type".into(), &"vravio-bridge:saved".into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"token".into(), &token.into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"bytes".into(), &js_sys::Uint8Array::from(bytes).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}

fn send_restore_input(path: &str, bytes: &[u8]) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    let kind = if path.ends_with("vravio-cutout-input.png") { "vravio-cutout-open" } else { "vravio-restorer-open" };
    js_sys::Reflect::set(&message, &"type".into(), &kind.into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"bytes".into(), &js_sys::Uint8Array::from(bytes).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}

fn listen_restore_result(inbox: Inbox, cutout_inbox: CutoutInbox, restore_inbox: RestoreInbox, place_inbox: Inbox, snapshot_requested: Arc<AtomicBool>, tab_action: TabAction, ctx: egui::Context) {
    use wasm_bindgen::closure::Closure;
    let Some(window) = web_sys::window() else { return };
    let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event: web_sys::MessageEvent| {
        let Some(window) = web_sys::window() else { return };
        if window.location().origin().ok().as_deref() != Some(event.origin().as_str()) { return }
        let data = event.data();
        let kind = js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string());
        if kind.as_deref() == Some("vravio-bridge:open") {
            let name = js_sys::Reflect::get(&data, &"name".into()).ok().and_then(|v| v.as_string()).unwrap_or_default();
            if !name.starts_with("vravio-bridge-") || !name.ends_with(".png") { return }
            let bytes = js_sys::Uint8Array::new(&js_sys::Reflect::get(&data, &"bytes".into()).unwrap_or_default()).to_vec();
            if bytes.len() > 100_000_000 || !bytes.starts_with(b"\x89PNG\r\n\x1a\n") { return }
            inbox.lock().unwrap_or_else(PoisonError::into_inner).push((name, bytes));
            ctx.request_repaint();
            return;
        }
        if !matches!(kind.as_deref(), Some("vravio-restorer-result" | "vravio-cutout-result")) { return }
        let bytes = js_sys::Uint8Array::new(&js_sys::Reflect::get(&data, &"bytes".into()).unwrap_or_default()).to_vec();
        if kind.as_deref() == Some("vravio-cutout-result") {
            cutout_inbox.lock().unwrap_or_else(PoisonError::into_inner).push(bytes);
            ctx.request_repaint();
            return;
        }
        let name = js_sys::Reflect::get(&data, &"name".into()).ok().and_then(|v| v.as_string()).unwrap_or_else(|| "restored.png".into());
        if !bytes.starts_with(b"\x89PNG\r\n\x1a\n") { return }
        let mode = js_sys::Reflect::get(&data, &"mode".into()).ok().and_then(|v| v.as_string());
        if mode.as_deref() == Some("current") {
            place_inbox.lock().unwrap_or_else(PoisonError::into_inner).push((name, bytes));
        } else if mode.as_deref() == Some("new") {
            let original = js_sys::Uint8Array::new(&js_sys::Reflect::get(&data, &"original".into()).unwrap_or_default()).to_vec();
            if !original.starts_with(b"\x89PNG\r\n\x1a\n") { return }
            restore_inbox.lock().unwrap_or_else(PoisonError::into_inner).push((name, original, bytes));
        } else { return }
        ctx.request_repaint();
    });
    if window.add_event_listener_with_callback("message", cb.as_ref().unchecked_ref()).is_ok() { cb.forget(); }
}
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '/// Trigger a browser download of `bytes` named after the last component of `path`.' 'fn send_restore_input(' $restoreBridge
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'if js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string()).as_deref() != Some("vravio-restorer-result") { return }' 'let kind = js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string());'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        let bytes = js_sys::Uint8Array::new(&js_sys::Reflect::get(&data, &"bytes".into()).unwrap_or_default()).to_vec();' 'if !matches!(kind.as_deref()' '        if !matches!(kind.as_deref(), Some("vravio-restorer-result" | "vravio-cutout-result")) { return }'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        let name = js_sys::Reflect::get(&data, &"name".into())' 'cutout_inbox.lock().unwrap_or_else' "        if kind.as_deref() == Some(`"vravio-cutout-result`") {`n            cutout_inbox.lock().unwrap_or_else(PoisonError::into_inner).push(bytes);`n            ctx.request_repaint();`n            return;`n        }"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' "type Inbox = Arc<Mutex<Vec<(String, Vec<u8>)>>>;`n`n" "type Inbox = Arc<Mutex<Vec<(String, Vec<u8>)>>>;`ntype CutoutInbox = Arc<Mutex<Vec<Vec<u8>>>>;`ntype RestoreInbox = Arc<Mutex<Vec<(String, Vec<u8>, Vec<u8>)>>>;`ntype TabAction = Arc<Mutex<Option<(String, usize)>>>;`n`n"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'WebShell { app, inbox, place_inbox, unsaved' 'WebShell { app, inbox, cutout_inbox, restore_inbox, place_inbox, snapshot_requested, snapshot_revisions: HashMap::new(), tab_action, tab_state: String::new(), unsaved'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '    /// Dropped files to place on the active document' '    cutout_inbox: CutoutInbox,' '    cutout_inbox: CutoutInbox,'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '    /// Dropped files to place on the active document' '    restore_inbox: RestoreInbox,' '    restore_inbox: RestoreInbox,'
$applyAiMask = @'
fn apply_ai_cutout(app: &mut PhotocraftApp, bytes: &[u8]) -> Result<(), String> {
    let imported = photocraft_io::import("ai-cutout.png", bytes).map_err(|e| e.to_string())?.document;
    let alpha = imported.layers.first().and_then(|layer| layer.surface()).ok_or("AI result has no pixels")?;
    if alpha.channels() < 4 { return Err("AI result has no alpha channel".into()); }
    let bounds = imported.bounds();
    let width = bounds.width() as i32;
    let height = bounds.height() as i32;
    app.session.edit("AI Remove Background", |doc, active| {
        if doc.bounds() != bounds { return Err(photocraft_engine::EngineError::Other("document size changed during AI cutout".into())); }
        let id = (*active).ok_or(photocraft_engine::EngineError::NoDocument)?;
        let background = doc.is_background(id);
        let layer = doc.layer_mut(id).ok_or(photocraft_engine::EngineError::NoLayer(id))?;
        if background {
            layer.locks.transparency = false;
            layer.locks.position = false;
            layer.name = "Layer 0".into();
        }
        let mut mask = photocraft_doc::LayerMask::hide_all();
        let mut row = vec![0.0f32; width as usize];
        for y in 0..height {
            for x in 0..width { row[x as usize] = alpha.sample_channel(x, y, 3); }
            mask.surface.write_region(photocraft_geom::Rect::new(0, y, width, y + 1), &row);
        }
        layer.mask = Some(mask);
        doc.selection = None;
        Ok(())
    }).map_err(|e| e.to_string())
}
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn send_restore_input' 'fn apply_ai_cutout(app:' $applyAiMask
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        self.serve_fonts(ctx);' 'std::mem::take(&mut *self.cutout_inbox' "        let masks = std::mem::take(&mut *self.cutout_inbox.lock().unwrap_or_else(PoisonError::into_inner));`n        for bytes in masks {`n            if let Err(error) = apply_ai_cutout(&mut self.app, &bytes) { self.app.ui.status = format!(`"AI cutout failed: {error}`"); }`n        }`n        let restorations = std::mem::take(&mut *self.restore_inbox.lock().unwrap_or_else(PoisonError::into_inner));`n        for (name, original, restored) in restorations {`n            let result = self.app.open_bytes(&name, &original).and_then(|_| self.app.place_bytes(`"Восстановлено.png`", restored, None).map(|_| Vec::new()));`n            if let Err(error) = result { self.app.ui.status = format!(`"Restoration failed: {error}`"); }`n        }"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' "photocraft-doc = { workspace = true }`nphotocraft-ui-egui" "photocraft-doc = { workspace = true }`nphotocraft-geom = { workspace = true }`nphotocraft-ui-egui"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'self.app.open_bytes(&name, &original).and_then(|_| self.app.place_bytes("Восстановлено.png", restored, None).map(|_| Vec::new()))' 'self.app.open_bytes(&name, &original).map(|_| ()).and_then(|_| self.app.place_bytes("Восстановлено.png", restored, None).map(|_| ()))'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn send_restore_input(bytes: &[u8])' 'fn send_restore_input(path: &str, bytes: &[u8])'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'js_sys::Reflect::set(&message, &"type".into(), &"vravio-restorer-open".into()).map_err(js)?;' "    let kind = if path.ends_with(`"vravio-cutout-input.png`") { `"vravio-cutout-open`" } else { `"vravio-restorer-open`" };`n    js_sys::Reflect::set(&message, &`"type`".into(), &kind.into()).map_err(js)?;"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'move |event| {' 'move |event: web_sys::MessageEvent| {'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' '"BeforeUnloadEvent", "AbortController"' '"BeforeUnloadEvent", "MessageEvent", "AbortController"'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: Inbox = Arc::default();' 'let cutout_inbox: CutoutInbox' "                    let cutout_inbox: CutoutInbox = Arc::default();`n                    let restore_inbox: RestoreInbox = Arc::default();"
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: Inbox = Arc::default();' 'listen_restore_result(inbox.clone(),' '                    listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), place_inbox.clone(), snapshot_requested.clone(), tab_action.clone(), cc.egui_ctx.clone());'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: Inbox = Arc::default();' 'notify_bridge_ready();' '                    notify_bridge_ready();'
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn download(path: &str, bytes: &[u8]) -> Result<(), String> {' 'return send_restore_input(path, bytes);' '    if path.ends_with("vravio-restoration-input.png") || path.ends_with("vravio-cutout-input.png") { return send_restore_input(path, bytes); }'
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn download(path: &str, bytes: &[u8]) -> Result<(), String> {' 'return send_bridge_result(path, bytes);' '    if path.starts_with("vravio-bridge-result-") && path.ends_with(".png") { return send_bridge_result(path, bytes); }'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(0x2f, 0x6b, 0xdf)' 'accent: Color32::from_rgb(0xff, 0x00, 0x00)'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'accent_hover: Color32::from_rgb(0x3f, 0x7c, 0xe8)' 'accent_hover: Color32::from_rgb(0xff, 0x44, 0x44)'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/state.rs' 'brightness: Brightness::MediumDark,' 'brightness: Brightness::Dark,'
Replace-Exact 'upstream/vectorcraft/crates/engine/src/prefs.rs' 'ui_brightness: s("mediumDark"),' 'ui_brightness: s("dark"),'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/file_open.rs' '    pub(crate) fn place_bytes(&mut self, name: &str, bytes: Vec<u8>, linked: Option<String>)' '    pub fn place_bytes(&mut self, name: &str, bytes: Vec<u8>, linked: Option<String>)'
$webSaveDialog = @'
            // No save dialog on the web: the suggested name becomes the download name.
            FileDialogRequest::Save { suggested } => {
                let name = std::path::Path::new(&suggested).file_name().map_or_else(|| suggested.clone(), |n| n.to_string_lossy().to_string());
                reply.send(Some(FileDialogAnswer::SaveTo(name)));
            }
'@
$vravioSaveDialog = @'
            FileDialogRequest::Save { suggested } => {
                let name = std::path::Path::new(&suggested).file_name().map_or_else(|| suggested.clone(), |n| n.to_string_lossy().to_string());
                let answer = web_sys::window().and_then(|window| window
                    .prompt_with_message_and_default("Имя и формат файла (.psd, .ora, .png, .jpg, .tif):", &name)
                    .ok()
                    .flatten());
                reply.send(answer.map(FileDialogAnswer::SaveTo));
            }
'@
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' $webSaveDialog $vravioSaveDialog
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/canvas/home.rs' '    ui.label(egui::RichText::new(tl!("Community")).font(theme::semibold(14.0)).color(t.text));' ''
$audioAppMenu = @'
                ui.menu_button("SoundCraft", |ui| {
                    if ui.button("About SoundCraft").clicked() {
                        app.ui.show_about = true;
                    }
                    if ui.button("Check for Updates…").clicked() {
                        let _ = app.run("app.checkForUpdates", json!({}));
                    }
                    if ui.button("Session Info").clicked() {
                        app.ui.show_session_info = true;
                    }
                    if ui.button("Session Audio Health").clicked() {
                        let _ = app.run("window.audio_health", json!({"value": true}));
                    }
                    ui.separator();
                    if ui.button("Quit").clicked() {
                        let _ = crate::dialogs::run_or_ask(app, "app.quit", json!({}));
                    }
                });
'@
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/menus.rs' $audioAppMenu ''
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/lib.rs' 'assets/app-icon/hicolor/128x128/apps/ai.storyteller.photocraft.png' 'assets/vravio-icon.png'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/panels/brand.rs' 'assets/app-icon/hicolor/128x128/apps/ai.storyteller.photocraft.png' 'assets/vravio-icon.png'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/lib.rs' 'assets/app-icon/hicolor/128x128/apps/ai.storyteller.vectorcraft.png' 'assets/vravio-icon.png'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/brand.rs' 'assets/app-icon/hicolor/128x128/apps/ai.storyteller.vectorcraft.png' 'assets/vravio-icon.png'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/lib.rs' 'assets/app-icon/hicolor/128x128/apps/ai.storyteller.filmcraft.png' 'assets/vravio-icon.png'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/brand.rs' 'docs/brand/artcraft-logo-white.png' 'assets/vravio-wordmark-white.png'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/brand.rs' 'docs/brand/artcraft-logo.png' 'assets/vravio-wordmark-black.png'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/lib.rs' 'assets/app-icon/hicolor/128x128/apps/ai.storyteller.soundcraft.png' 'assets/vravio-icon.png'
Replace-Exact 'upstream/soundcraft/apps/soundcraft-web/index.html' '../../assets/app-icon/hicolor/64x64/apps/ai.storyteller.soundcraft.png' '../../assets/vravio-icon.png'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/panels/about.rs' 'An open-source digital audio workstation from the ArtCraft team.' 'An open-source digital audio workstation built with Rust.'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/dialogs/about.rs' 'Part of ArtCraft. MIT OR Apache-2.0. Fonts: Source Sans 3, Inter, JetBrains Mono (OFL). Icons: Lucide (ISC) + VectorCraft.' 'Open-source software. MIT OR Apache-2.0. Fonts: Source Sans 3, Inter, JetBrains Mono (OFL). Icons: Lucide (ISC) plus original artwork.'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/panels/dialogs.rs' 'A clean-room, pure-Rust non-linear video editor. Part of the ArtCraft family.' 'A clean-room, pure-Rust non-linear video editor.'

$names = @{ 'PhotoCraft'='VRAVIO'; 'VectorCraft'='VRAVIO'; 'FilmCraft'='VRAVIO'; 'SoundCraft'='VRAVIO'; 'ArtCraft'='VRAVIO' }
foreach ($repo in @('photocraft','vectorcraft','filmcraft','soundcraft')) {
  $ui = Join-Path $root "upstream/$repo/crates/ui-egui/src"
  $web = Join-Path $root "upstream/$repo/apps/$repo-web/src"
  if ($repo -eq 'filmcraft') { $web = Join-Path $root 'upstream/filmcraft/apps/filmcraft-web/src' }
  if ($repo -eq 'soundcraft') { $web = Join-Path $root 'upstream/soundcraft/apps/soundcraft-web/src' }
  foreach ($dir in @($ui,$web)) {
    if (-not (Test-Path $dir)) { throw "Missing UI source: $dir" }
    foreach ($file in (Get-ChildItem $dir -Recurse -File | Where-Object { $_.Extension -in @('.rs','.tsv') })) {
      $original = [IO.File]::ReadAllText($file.FullName)
      $next = $original
      foreach ($name in $names.Keys) { $next = $next.Replace($name, $names[$name]) }
      if ($next -ne $original) { [IO.File]::WriteAllText($file.FullName, $next, [Text.UTF8Encoding]::new($false)) }
    }
  }
}

# Suppress community and project navigation in the embedded editors. License notices stay in source.
foreach ($file in @('upstream/photocraft/crates/ui-egui/src/canvas/start_screen.rs','upstream/photocraft/crates/ui-egui/src/dialogs.rs')) {
  Replace-Exact $file 'crate::links::discord_button(app, ui, 190.0);' ''
  Replace-Exact $file 'crate::links::discord_button(app, ui, 220.0);' ''
  Replace-Exact $file 'crate::links::link_row(app, ui);' ''
}
foreach ($line in @(
  '    ("help.discord", "Join the ArtCraft Discord…", &["Help"], None),',
  '    ("help.website", "PhotoCraft Website", &["Help"], None),',
  '    ("help.artcraftWebsite", "ArtCraft Website", &["Help"], None),',
  '    ("help.github", "PhotoCraft on GitHub", &["Help"], None),',
  '    ("help.reportIssue", "Report an Issue…", &["Help"], None),'
)) { Replace-Exact 'upstream/photocraft/crates/engine/src/shell_commands.rs' $line '' }
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/chrome.rs' 'let discord = search && room >= ws_w + 8.0 + gap + icon + 10.0 + gap + crate::community::discord_width(ui, false);' 'let discord = false;'
foreach ($file in @('upstream/vectorcraft/crates/ui-egui/src/dialogs/about.rs','upstream/vectorcraft/crates/ui-egui/src/canvas/home.rs')) {
  Replace-Exact $file 'crate::community::links(app, ui);' ''
}
foreach ($line in @(
  '                c("Join Our Discord", "help.discord"),',
  '                c("VRAVIO Website", "help.website"),',
  '                c("VRAVIO on getartcraft.com", "help.appPage"),',
  '                c("VRAVIO on GitHub", "help.github"),'
)) { Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/menus/tree.rs' $line '' }
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/menus/tree.rs' 'vec![c("About VRAVIO", "help.about"), c("Join Our Discord", "help.discord")],' 'vec![c("About VRAVIO", "help.about")],'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/header.rs' 'let label = "Discord";' 'let label = "";'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/header.rs' 'let w = g.size().x + 34.0;' 'let w = 0.0;'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/header.rs' 'icons::paint(ui.painter(), Rect::from_center_size(pos2(r.min.x + 14.0, r.center().y), vec2(14.0, 14.0)), Icon::Chat, Color32::WHITE);' ''
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/panels/import_mode.rs' 'crate::links::ALL.iter().take(4).enumerate()' 'crate::links::ALL.iter().take(0).enumerate()'
foreach ($line in @(
  '    link(ui, "discord", Icon::Chat, tl!("Join the VRAVIO Discord"), links::DISCORD, true);',
  '    link(ui, "website", Icon::Globe, "getartcraft.com", links::WEBSITE, false);',
  '    link(ui, "appPage", Icon::Globe, tl!("VRAVIO on getartcraft.com"), links::APP_PAGE, false);',
  '    link(ui, "github", Icon::Code, tl!("Source code on GitHub"), links::GITHUB, false);',
  '    link(ui, "reportIssue", Icon::Code, tl!("Report an issue"), links::ISSUES, false);'
)) { Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/panels/dialogs.rs' $line '' }
foreach ($line in @(
  '    uic!("help.discord", "Join the VRAVIO Discord…", ["Help"], None),',
  '    uic!("help.website", "VRAVIO Website", ["Help"], None),',
  '    uic!("help.appPage", "VRAVIO on getartcraft.com", ["Help"], None),',
  '    uic!("help.github", "VRAVIO on GitHub", ["Help"], None),',
  '    uic!("help.reportIssue", "Report an Issue…", ["Help"], None),'
)) { Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/menus.rs' $line '' }
foreach ($line in @(
  'ui.hyperlink_to("getartcraft.com/apps/soundcraft", "https://getartcraft.com/apps/soundcraft");',
  'ui.hyperlink_to("Join us on Discord", "https://discord.gg/artcraft");'
)) { Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/panels/about.rs' $line '' }

# The browser raster editor periodically exports changed documents in its native,
# layered format. The parent shell owns durable IndexedDB storage and recovery UI.
$rasterWeb = 'upstream/photocraft/apps/photocraft-web/src/web.rs'
Replace-Exact $rasterWeb 'fn listen_restore_result(inbox: Inbox, cutout_inbox: CutoutInbox, restore_inbox: RestoreInbox, place_inbox: Inbox, snapshot_requested: Arc<AtomicBool>, ctx: egui::Context)' 'fn listen_restore_result(inbox: Inbox, cutout_inbox: CutoutInbox, restore_inbox: RestoreInbox, place_inbox: Inbox, snapshot_requested: Arc<AtomicBool>, tab_action: TabAction, ctx: egui::Context)'
Replace-Exact $rasterWeb 'type RestoreInbox = Arc<Mutex<Vec<(String, Vec<u8>, Vec<u8>)>>>;' "type RestoreInbox = Arc<Mutex<Vec<(String, Vec<u8>, Vec<u8>)>>>;`ntype TabAction = Arc<Mutex<Option<(String, usize)>>>;"
Insert-After-Once $rasterWeb '                    PhotocraftApp::setup_context(&cc.egui_ctx, ThemeKind::Studio);' 'vravio-unified-tabs' '                    cc.egui_ctx.data_mut(|data| data.insert_temp(egui::Id::new("vravio-unified-tabs"), true));'
Insert-Before-Once $rasterWeb '                    notify_bridge_ready();' 'let tab_action: TabAction' '                    let tab_action: TabAction = Arc::default();'
Replace-Exact $rasterWeb 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), place_inbox.clone(), snapshot_requested.clone(), cc.egui_ctx.clone());' 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), place_inbox.clone(), snapshot_requested.clone(), tab_action.clone(), cc.egui_ctx.clone());'
Replace-Exact $rasterWeb 'place_inbox, snapshot_requested, snapshot_revisions: HashMap::new(), unsaved' 'place_inbox, snapshot_requested, snapshot_revisions: HashMap::new(), tab_action, tab_state: String::new(), unsaved'
Insert-After-Once $rasterWeb '    restore_inbox: RestoreInbox,' '    tab_state: String,' "    snapshot_requested: Arc<AtomicBool>,`n    snapshot_revisions: HashMap<u64, u64>,`n    tab_action: TabAction,`n    tab_state: String,"
$tabStateMethod = @'
    fn sync_document_tabs(&mut self) {
        let documents: Vec<_> = self.app.session.documents().iter().map(|state| serde_json::json!({
            "id": state.doc.id.0.to_string(), "name": state.doc.name, "dirty": state.is_dirty()
        })).collect();
        let payload = serde_json::json!({"type": "vravio-documents:state", "documents": documents, "activeIndex": self.app.session.active_index()});
        let next = payload.to_string();
        if next == self.tab_state { return; }
        if send_document_tabs(&next).is_ok() { self.tab_state = next; }
    }
'@
Insert-Before-Once $rasterWeb '    fn save_presets(&mut self, ctx: &egui::Context) {' 'fn sync_document_tabs(&mut self)' $tabStateMethod
Insert-After-Once $rasterWeb '        self.app.ui_frame(ui, frame);' 'self.sync_document_tabs();' '        self.sync_document_tabs();'
$tabSender = @'
fn send_document_tabs(payload: &str) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::JSON::parse(payload).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}
'@
Insert-Before-Once $rasterWeb 'fn send_bridge_result(path: &str, bytes: &[u8])' 'fn send_document_tabs(' $tabSender
$tabReceiver = @'
        if matches!(kind.as_deref(), Some("vravio-documents:activate" | "vravio-documents:close")) {
            let index = js_sys::Reflect::get(&data, &"index".into()).ok().and_then(|v| v.as_f64()).filter(|v| v.fract() == 0.0 && *v >= 0.0 && *v < 1000.0);
            if let Some(index) = index {
                *tab_action.lock().unwrap_or_else(PoisonError::into_inner) = Some((kind.unwrap_or_default(), index as usize));
                ctx.request_repaint();
            }
            return;
        }
'@
Insert-Before-Once $rasterWeb '        if !matches!(kind.as_deref(), Some("vravio-restorer-result" | "vravio-cutout-result"))' '*tab_action.lock().unwrap_or_else' $tabReceiver
$tabActionMethod = @'
    fn apply_tab_action(&mut self) {
        let action = self.tab_action.lock().unwrap_or_else(PoisonError::into_inner).take();
        let Some((kind, index)) = action else { return };
        if kind == "vravio-documents:activate" { self.app.session.set_active(index); return; }
        if kind == "vravio-documents:close" && self.app.session.documents().get(index).is_some() {
            if self.app.session.documents()[index].is_dirty() {
                self.app.ui.status = "Сначала сохраните документ перед закрытием".into();
                self.app.session.set_active(index);
            } else {
                self.app.session.set_active(index);
                if let Err(error) = self.app.run("file.close", serde_json::json!({"save": false})) { self.app.ui.status = error; }
            }
        }
    }
'@
Insert-Before-Once $rasterWeb '    fn save_presets(&mut self, ctx: &egui::Context) {' 'fn apply_tab_action(&mut self)' $tabActionMethod
Insert-Before-Once $rasterWeb '        self.app.logic_frame(ctx, frame);' 'self.apply_tab_action();' '        self.apply_tab_action();'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/canvas/tabs.rs' 'if !app.ui.view.hides_tabs() || opening {' 'if (!app.ui.view.hides_tabs() || opening) && !ui.ctx().data(|data| data.get_temp::<bool>(egui::Id::new("vravio-unified-tabs")).unwrap_or(false)) {'
Insert-After-Once 'upstream/vectorcraft/apps/vectorcraft-web/src/web.rs' '                let ctx = &cc.egui_ctx;' 'vravio-unified-tabs' '                ctx.data_mut(|data| data.insert_temp(egui::Id::new("vravio-unified-tabs"), true));'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/app.rs' 'if self.ui.screen_mode < 3 {' 'if self.ui.screen_mode < 3 && !ui.ctx().data(|data| data.get_temp::<bool>(egui::Id::new("vravio-unified-tabs")).unwrap_or(false)) {'
$clipboardSender = @'
fn send_clipboard_image(width: u32, height: u32, pixels: &[u8]) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    js_sys::Reflect::set(&message, &"type".into(), &"vravio-clipboard:image".into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"width".into(), &wasm_bindgen::JsValue::from_f64(width as f64)).map_err(js)?;
    js_sys::Reflect::set(&message, &"height".into(), &wasm_bindgen::JsValue::from_f64(height as f64)).map_err(js)?;
    js_sys::Reflect::set(&message, &"pixels".into(), &js_sys::Uint8Array::from(pixels).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}
'@
Insert-Before-Once $rasterWeb 'fn send_bridge_result(path: &str, bytes: &[u8])' 'fn send_clipboard_image(' $clipboardSender
Insert-Before-Once $rasterWeb '        import: Some(Box::new(|name: &str, bytes: &[u8], opts: &photocraft_io::ImportOptions|' 'clipboard_set_image: Some(Box::new(|width, height, pixels|' '        clipboard_set_image: Some(Box::new(|width, height, pixels| send_clipboard_image(width, height, pixels))),'
Insert-Before-Once $rasterWeb '                    notify_bridge_ready();' 'let snapshot_requested = Arc::new(AtomicBool::new(false));' '                    let snapshot_requested = Arc::new(AtomicBool::new(false));'
Replace-Exact $rasterWeb 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), place_inbox.clone(), cc.egui_ctx.clone());' 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), place_inbox.clone(), snapshot_requested.clone(), tab_action.clone(), cc.egui_ctx.clone());'
Insert-After-Once $rasterWeb '    restore_inbox: RestoreInbox,' '    snapshot_revisions: HashMap<u64, u64>,' "    snapshot_requested: Arc<AtomicBool>,`n    snapshot_revisions: HashMap<u64, u64>,"
$snapshotMethod = @'
    fn snapshot_dirty(&mut self) {
        if !self.snapshot_requested.swap(false, Ordering::Relaxed) { return; }
        for state in self.app.session.documents() {
            if !state.is_dirty() || self.snapshot_revisions.get(&state.doc.id.0) == Some(&state.revision) { continue; }
            let recovery_name = format!("{}.pcraft", state.doc.name.trim_end_matches(".pcraft"));
            match photocraft_io::export(&state.doc, &recovery_name, &photocraft_io::ExportOptions::default()) {
                Ok(encoded) => match send_recovery_snapshot(state.doc.id.0, &state.doc.name, state.revision, &encoded.bytes) {
                    Ok(()) => { self.snapshot_revisions.insert(state.doc.id.0, state.revision); }
                    Err(error) => log::error!("recovery snapshot delivery failed: {error}"),
                },
                Err(error) => log::error!("recovery snapshot export failed: {error}"),
            }
        }
    }
'@
Insert-Before-Once $rasterWeb '    fn save_presets(&mut self, ctx: &egui::Context) {' 'fn snapshot_dirty(&mut self)' $snapshotMethod
Insert-After-Once $rasterWeb '        self.app.logic_frame(ctx, frame);' 'self.snapshot_dirty();' '        self.snapshot_dirty();'
$snapshotSender = @'
fn send_recovery_snapshot(id: u64, name: &str, revision: u64, bytes: &[u8]) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    js_sys::Reflect::set(&message, &"type".into(), &"vravio-recovery:snapshot".into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"id".into(), &id.to_string().into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"name".into(), &name.into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"revision".into(), &revision.to_string().into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"bytes".into(), &js_sys::Uint8Array::from(bytes).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}
'@
Insert-Before-Once $rasterWeb 'fn send_bridge_result(path: &str, bytes: &[u8])' 'fn send_recovery_snapshot(' $snapshotSender
$snapshotReceiver = @'
        if kind.as_deref() == Some("vravio-recovery:snapshot-request") {
            snapshot_requested.store(true, Ordering::Relaxed);
            ctx.request_repaint();
            return;
        }
        if kind.as_deref() == Some("vravio-recovery:open") {
            let name = js_sys::Reflect::get(&data, &"name".into()).ok().and_then(|v| v.as_string()).unwrap_or_default();
            if !name.ends_with(".pcraft") || name.len() > 200 { return }
            let bytes = js_sys::Uint8Array::new(&js_sys::Reflect::get(&data, &"bytes".into()).unwrap_or_default()).to_vec();
            if bytes.len() > 500_000_000 || bytes.is_empty() { return }
            inbox.lock().unwrap_or_else(PoisonError::into_inner).push((name, bytes));
            ctx.request_repaint();
            return;
        }
'@
Insert-Before-Once $rasterWeb '        if kind.as_deref() == Some("vravio-bridge:open") {' 'vravio-recovery:snapshot-request' $snapshotReceiver
Write-Output 'VRAVIO branding applied to UI sources.'

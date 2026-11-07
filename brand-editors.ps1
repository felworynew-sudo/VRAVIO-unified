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
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/canvas.rs' '            ants = boxed.unwrap_or_else(|| marching_ants_segment_shapes(input.painter, &shown, segs, time));' 'paint::selection_glow_segments(input.painter, &shown, segs, sel, k);' '            paint::selection_glow_segments(input.painter, &shown, segs, sel, k);'
$restoreItem = @'
    items.push(MenuItem {
        id: "filter.vravio.photoRestore".into(),
        label: "Restore Old Photos…".into(),
        path: vec!["Filter".into(), "AI".into()],
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
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'type PlaceInbox = photocraft_ui_egui::PlaceInbox;' 'type CutoutInbox' "type CutoutInbox = Arc<Mutex<Vec<Vec<u8>>>>;`ntype RestoreInbox = Arc<Mutex<Vec<(String, Vec<u8>, Vec<u8>)>>>;`ntype TabAction = Arc<Mutex<Option<(String, usize)>>>;`ntype UnifiedSettings = Arc<Mutex<Option<(Option<String>, Option<String>)>>>;"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'WebShell { app, inbox, place_inbox, unsaved' 'WebShell { app, inbox, cutout_inbox, restore_inbox, vravio_place, place_inbox, snapshot_requested, snapshot_revisions: HashMap::new(), tab_action, tab_state: String::new(), unified_settings, unsaved'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '    /// Dropped files to place on the active document' '    cutout_inbox: CutoutInbox,' '    cutout_inbox: CutoutInbox,'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '    /// Dropped files to place on the active document' '    vravio_place: Inbox,' "    /// VRAVIO: AI results placed on the active document (``mode: current``).`n    vravio_place: Inbox,"
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
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        self.serve_fonts(ctx);' 'std::mem::take(&mut *self.cutout_inbox' "        let masks = std::mem::take(&mut *self.cutout_inbox.lock().unwrap_or_else(PoisonError::into_inner));`n        for bytes in masks {`n            if let Err(error) = apply_ai_cutout(&mut self.app, &bytes) { self.app.ui.status = format!(`"AI cutout failed: {error}`"); }`n        }`n        let restorations = std::mem::take(&mut *self.restore_inbox.lock().unwrap_or_else(PoisonError::into_inner));`n        for (name, original, restored) in restorations {`n            let result = self.app.open_bytes(&name, &original).and_then(|_| self.app.place_bytes(&format!(`"{}.png`", photocraft_ui_egui::i18n::t(if name.ends_with(`"x4.png`") { `"Upscaled ×4`" } else { `"Restored`" })), restored, None).map(|_| Vec::new()));`n            if let Err(error) = result { self.app.ui.status = format!(`"Restoration failed: {error}`"); }`n        }"
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        self.serve_fonts(ctx);' 'self.vravio_place.lock()' "        let places = std::mem::take(&mut *self.vravio_place.lock().unwrap_or_else(PoisonError::into_inner));`n        for (name, bytes) in places {`n            if let Err(error) = self.app.place_bytes(&name, bytes, None) { self.app.ui.status = format!(`"Place failed: {error}`"); }`n        }"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' "photocraft-doc = { workspace = true }`nphotocraft-ui-egui" "photocraft-doc = { workspace = true }`nphotocraft-geom = { workspace = true }`nphotocraft-ui-egui"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'self.app.open_bytes(&name, &original).and_then(|_| self.app.place_bytes(&format!("{}.png", photocraft_ui_egui::i18n::t(if name.ends_with("x4.png") { "Upscaled ×4" } else { "Restored" })), restored, None).map(|_| Vec::new()))' 'self.app.open_bytes(&name, &original).map(|_| ()).and_then(|_| self.app.place_bytes(&format!("{}.png", photocraft_ui_egui::i18n::t(if name.ends_with("x4.png") { "Upscaled ×4" } else { "Restored" })), restored, None).map(|_| ()))'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn send_restore_input(bytes: &[u8])' 'fn send_restore_input(path: &str, bytes: &[u8])'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'js_sys::Reflect::set(&message, &"type".into(), &"vravio-restorer-open".into()).map_err(js)?;' "    let kind = if path.ends_with(`"vravio-cutout-input.png`") { `"vravio-cutout-open`" } else { `"vravio-restorer-open`" };`n    js_sys::Reflect::set(&message, &`"type`".into(), &kind.into()).map_err(js)?;"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'move |event| {' 'move |event: web_sys::MessageEvent| {'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' '"BeforeUnloadEvent", "AbortController"' '"BeforeUnloadEvent", "MessageEvent", "AbortController"'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: PlaceInbox = Arc::default();' 'let cutout_inbox: CutoutInbox' "                    let cutout_inbox: CutoutInbox = Arc::default();`n                    let restore_inbox: RestoreInbox = Arc::default();`n                    let vravio_place: Inbox = Arc::default();"
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: PlaceInbox = Arc::default();' 'listen_restore_result(inbox.clone(),' '                    listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), vravio_place.clone(), snapshot_requested.clone(), tab_action.clone(), cc.egui_ctx.clone());'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: PlaceInbox = Arc::default();' 'notify_bridge_ready();' '                    notify_bridge_ready();'
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn download(path: &str, bytes: &[u8]) -> Result<(), String> {' 'return send_restore_input(path, bytes);' '    if path.ends_with("vravio-restoration-input.png") || path.ends_with("vravio-cutout-input.png") { return send_restore_input(path, bytes); }'
# AI depth map and x4 upscale (restorer/ai): own menu item, own bridge message; restore/cutout lines stay untouched.
$aiToolsItem = @'
    items.push(MenuItem {
        id: "filter.vravio.aiTools".into(),
        label: "Depth Map and Upscale…".into(),
        path: vec!["Filter".into(), "AI".into()],
        shortcut: None,
        enabled: app.session.active().is_some() && app.services.export.is_some() && app.services.write.is_some(),
        checked: None,
        color: None,
    });
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/items.rs' '    crate::plugin_ui::insert_menu_items(app, &mut items);' 'filter.vravio.aiTools' $aiToolsItem
$aiCutoutItem = @'
    items.push(MenuItem {
        id: "filter.vravio.removeBackground".into(),
        label: "Remove Background…".into(),
        path: vec!["Filter".into(), "AI".into()],
        shortcut: None,
        enabled: app.session.active().is_some() && app.services.export.is_some() && app.services.write.is_some(),
        checked: None,
        color: None,
    });
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/items.rs' '    crate::plugin_ui::insert_menu_items(app, &mut items);' 'filter.vravio.removeBackground' $aiCutoutItem
$aiCutoutCommand = @'
    if id == "filter.vravio.removeBackground" {
        let doc = app.session.active().ok_or("no document is open".to_string());
        return Some(doc.and_then(|doc| {
            let export = app.services.export.as_ref().ok_or("PNG export is unavailable")?;
            let (bytes, _) = export(&doc.doc, "vravio-cutout-input.png", &crate::ExportSettings::default())?;
            let write = app.services.write.as_mut().ok_or("browser bridge is unavailable")?;
            write("vravio-cutout-input.png", &bytes)?;
            Ok(json!({"sent": true}))
        }));
    }
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '    if id == "filter.vravio.photoRestore"' 'if id == "filter.vravio.removeBackground" {' $aiCutoutCommand
# AI noise reduction (SCUNet): the same AI dialog, opened on its denoise tool.
$aiDenoiseItem = @'
    items.push(MenuItem {
        id: "filter.vravio.aiDenoise".into(),
        label: "Noise Reduction…".into(),
        path: vec!["Filter".into(), "AI".into()],
        shortcut: None,
        enabled: app.session.active().is_some() && app.services.export.is_some() && app.services.write.is_some(),
        checked: None,
        color: None,
    });
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/items.rs' '    crate::plugin_ui::insert_menu_items(app, &mut items);' 'filter.vravio.aiDenoise' $aiDenoiseItem
$aiDenoiseCommand = @'
    if id == "filter.vravio.aiDenoise" {
        let doc = app.session.active().ok_or("no document is open".to_string());
        return Some(doc.and_then(|doc| {
            let export = app.services.export.as_ref().ok_or("PNG export is unavailable")?;
            let (bytes, _) = export(&doc.doc, "vravio-ai-denoise.png", &crate::ExportSettings::default())?;
            let write = app.services.write.as_mut().ok_or("browser bridge is unavailable")?;
            write("vravio-ai-denoise.png", &bytes)?;
            Ok(json!({"sent": true}))
        }));
    }
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '    if id == "filter.vravio.photoRestore"' 'if id == "filter.vravio.aiDenoise" {' $aiDenoiseCommand
# AI Denoise in Camera Raw's Detail panel (checkbox + amount, like Camera Raw's Denoise): on OK the
# layer goes as 16-bit RGBA to the shell's small progress window (restorer/denoise, SCUNet), and the
# result comes back into the same layer as one history step.
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/dialogs/camera_raw_ui.rs' 'const PROXY_SIDE: usize = 900;' 'VRAVIO_AI_DENOISE:' @'
/// VRAVIO: AI Denoise in Detail: the checkbox and its amount (Camera Raw's default 50).
pub static VRAVIO_AI_DENOISE: std::sync::Mutex<(bool, f32)> = std::sync::Mutex::new((false, 50.0));
/// Set on OK with AI Denoise on: the layer (`None`: the opened raw's active layer) and the amount.
pub static VRAVIO_AI_DENOISE_RUN: std::sync::Mutex<Option<(Option<LayerId>, f32)>> = std::sync::Mutex::new(None);

'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/dialogs/camera_raw_ui/controls.rs' '                widgets::section_label(ui, tl!("Sharpening"));' 'vravio-ai-denoise' @'
                // VRAVIO: AI Denoise (SCUNet in the browser), applied after OK like Camera Raw's Denoise.
                ui.push_id("vravio-ai-denoise", |ui| {
                    let mut state = super::VRAVIO_AI_DENOISE.lock().unwrap_or_else(std::sync::PoisonError::into_inner);
                    let smart = matches!(d.target, Target::SmartFilter(_));
                    ui.add_enabled_ui(!smart, |ui| {
                        widgets::checkbox(ui, &mut state.0, tl!("AI Denoise"));
                        ui.add_enabled_ui(state.0, |ui| {
                            let mut quiet = false;
                            row(ui, &mut quiet, "Amount", &mut state.1, 0.0..=100.0, None);
                        });
                    });
                    let note = if smart { tl!("AI Denoise isn't available for smart filters") } else { tl!("Applied after OK; a large photo can take a few minutes") };
                    ui.label(egui::RichText::new(note).small().weak());
                    ui.add_space(6.0);
                });
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/dialogs/camera_raw_ui/controls.rs' "    match action {`n        Some(`"ok`") => {" 'vravio_denoise_target =' @'
    // VRAVIO: AI Denoise runs after OK (the shell's progress window); the checkbox resets either way.
    let vravio_denoise_target = match action {
        Some("ok") | Some("cancel") => {
            let mut state = super::VRAVIO_AI_DENOISE.lock().unwrap_or_else(std::sync::PoisonError::into_inner);
            let on = std::mem::take(&mut state.0);
            let amount = state.1;
            app.camera_raw.as_ref().filter(|_| on && action == Some("ok")).and_then(|d| match d.target {
                Target::NewFilter => Some((Some(d.layer), amount)),
                Target::OpenRaw => Some((None, amount)),
                Target::SmartFilter(_) => None,
            })
        }
        _ => None,
    };
'@
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/dialogs/camera_raw_ui/controls.rs' @'
        Some("ok") => {
            if let Err(e) = commit(app) {
                app.ui.status = e;
            }
        }
'@ @'
        Some("ok") => {
            if let Err(e) = commit(app) {
                app.ui.status = e;
            } else if let Some(run) = vravio_denoise_target {
                *super::VRAVIO_AI_DENOISE_RUN.lock().unwrap_or_else(std::sync::PoisonError::into_inner) = Some(run);
            }
        }
'@
$aiDenoiseRun = @'
// VRAVIO: AI Denoise from Camera Raw's Detail panel. On OK the layer goes to the shell's small
// progress window (SCUNet in the browser) as 16-bit RGBA; the result comes back into the same
// layer as one history step ("AI Denoise").
thread_local! {
    static VRAVIO_DENOISE_JOB: std::cell::RefCell<Option<(photocraft_doc::DocId, photocraft_doc::LayerId, photocraft_geom::Rect)>> = const { std::cell::RefCell::new(None) };
    static VRAVIO_DENOISE_INBOX: std::cell::RefCell<Option<Result<Vec<u16>, String>>> = const { std::cell::RefCell::new(None) };
    static VRAVIO_DENOISE_LISTENING: Cell<bool> = const { Cell::new(false) };
}

fn vravio_listen_denoise(ctx: &egui::Context) {
    use wasm_bindgen::closure::Closure;
    if VRAVIO_DENOISE_LISTENING.with(|l| l.replace(true)) {
        return;
    }
    let Some(window) = web_sys::window() else { return };
    let ctx = ctx.clone();
    let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event: web_sys::MessageEvent| {
        let Some(window) = web_sys::window() else { return };
        if window.location().origin().ok().as_deref() != Some(event.origin().as_str()) {
            return;
        }
        let data = event.data();
        let get = |key: &str| js_sys::Reflect::get(&data, &key.into()).ok().filter(|v| !v.is_undefined() && !v.is_null());
        if get("type").and_then(|v| v.as_string()).as_deref() != Some("vravio-denoise-result") {
            return;
        }
        let result = if let Some(pixels) = get("data") {
            Ok(js_sys::Uint16Array::new(&pixels).to_vec())
        } else if get("cancelled").and_then(|v| v.as_bool()) == Some(true) {
            Err(String::new())
        } else {
            Err(get("error").and_then(|v| v.as_string()).unwrap_or_else(|| "no result".into()))
        };
        VRAVIO_DENOISE_INBOX.with(|i| *i.borrow_mut() = Some(result));
        ctx.request_repaint();
    });
    if window.add_event_listener_with_callback("message", cb.as_ref().unchecked_ref()).is_ok() {
        cb.forget();
    }
}

/// Sends the layer (`None`: the active one) to the shell's AI Denoise window.
fn vravio_start_denoise(app: &PhotocraftApp, ctx: &egui::Context, layer: Option<photocraft_doc::LayerId>, amount: f32) -> Result<(), String> {
    if VRAVIO_DENOISE_JOB.with(|j| j.borrow().is_some()) {
        return Err("AI Denoise is already running".into());
    }
    let st = app.session.active().ok_or("no document is open")?;
    let doc = &st.doc;
    if doc.mode != photocraft_doc::ColorMode::Rgb {
        return Err("AI Denoise works on RGB images".into());
    }
    let id = layer.or(st.active_layer).ok_or("no layer is selected")?;
    let surface = doc.layer(id).and_then(|l| match &l.content {
        photocraft_doc::LayerContent::Raster(s) => Some(s),
        _ => None,
    });
    let surface = surface.ok_or("AI Denoise needs a pixel layer")?;
    let n = surface.channels();
    if n < 3 {
        return Err("AI Denoise works on RGB images".into());
    }
    let bounds = doc.bounds();
    let (w, h) = (bounds.width().max(0) as usize, bounds.height().max(0) as usize);
    if w == 0 || h == 0 {
        return Err("the layer is empty".into());
    }
    let mut pixels = vec![0u16; w * h * 4];
    let mut row = Vec::new();
    for y in 0..h {
        surface.read_region_into(photocraft_geom::Rect::new(bounds.x0, bounds.y0 + y as i32, bounds.x1, bounds.y0 + y as i32 + 1), &mut row);
        for x in 0..w {
            let o = (y * w + x) * 4;
            for c in 0..3 {
                pixels[o + c] = (row[x * n + c].clamp(0.0, 1.0) * 65535.0).round() as u16;
            }
            pixels[o + 3] = if n > 3 { (row[x * n + 3].clamp(0.0, 1.0) * 65535.0).round() as u16 } else { 65535 };
        }
    }
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    js_sys::Reflect::set(&message, &"type".into(), &"vravio-denoise-run".into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"width".into(), &wasm_bindgen::JsValue::from_f64(w as f64)).map_err(js)?;
    js_sys::Reflect::set(&message, &"height".into(), &wasm_bindgen::JsValue::from_f64(h as f64)).map_err(js)?;
    js_sys::Reflect::set(&message, &"amount".into(), &wasm_bindgen::JsValue::from_f64(f64::from(amount))).map_err(js)?;
    js_sys::Reflect::set(&message, &"data".into(), &js_sys::Uint16Array::from(pixels.as_slice()).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    VRAVIO_DENOISE_JOB.with(|j| *j.borrow_mut() = Some((doc.id, id, bounds)));
    vravio_listen_denoise(ctx);
    Ok(())
}

/// The shell's answer: the denoised RGB goes into the layer (its alpha stays), one history step.
fn vravio_finish_denoise(app: &mut PhotocraftApp) {
    let Some(result) = VRAVIO_DENOISE_INBOX.with(|i| i.borrow_mut().take()) else { return };
    let Some((doc_id, id, bounds)) = VRAVIO_DENOISE_JOB.with(|j| j.borrow_mut().take()) else { return };
    let pixels = match result {
        Ok(p) => p,
        Err(e) if e.is_empty() => {
            app.ui.status = i18n::t("AI Denoise cancelled").to_string();
            return;
        }
        Err(e) => {
            app.ui.status = format!("{}: {e}", i18n::t("AI Denoise failed"));
            return;
        }
    };
    let (w, h) = (bounds.width().max(0) as usize, bounds.height().max(0) as usize);
    if pixels.len() != w * h * 4 {
        app.ui.status = format!("{}: wrong result size", i18n::t("AI Denoise failed"));
        return;
    }
    if app.session.active().map(|st| st.doc.id) != Some(doc_id) {
        let Some(index) = app.session.documents().iter().position(|st| st.doc.id == doc_id) else {
            app.ui.status = format!("{}: the document was closed", i18n::t("AI Denoise failed"));
            return;
        };
        app.session.set_active(index);
    }
    let result = app.session.edit("AI Denoise", |doc, _active| {
        if doc.bounds() != bounds {
            return Err(photocraft_engine::EngineError::Other("the document size changed".into()));
        }
        let layer = doc.layer_mut(id).ok_or(photocraft_engine::EngineError::NoLayer(id))?;
        let surface = layer.surface_mut().ok_or_else(|| photocraft_engine::EngineError::Other("the layer is no longer a pixel layer".into()))?;
        let n = surface.channels();
        let mut row = Vec::new();
        for y in 0..h {
            let r = photocraft_geom::Rect::new(bounds.x0, bounds.y0 + y as i32, bounds.x1, bounds.y0 + y as i32 + 1);
            surface.read_region_into(r, &mut row);
            for x in 0..w {
                for c in 0..3 {
                    row[x * n + c] = f32::from(pixels[(y * w + x) * 4 + c]) / 65535.0;
                }
            }
            surface.write_region(r, &row);
        }
        Ok(())
    });
    app.ui.status = match result {
        Ok(()) => i18n::t("AI Denoise applied").to_string(),
        Err(e) => format!("{}: {e}", i18n::t("AI Denoise failed")),
    };
}
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'const CANVAS_ID:' 'fn vravio_start_denoise(' $aiDenoiseRun
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        self.serve_fonts(ctx);' 'VRAVIO_AI_DENOISE_RUN' @'
        if let Some((layer, amount)) = photocraft_ui_egui::camera_raw_ui::VRAVIO_AI_DENOISE_RUN.lock().unwrap_or_else(PoisonError::into_inner).take() {
            if let Err(error) = vravio_start_denoise(&self.app, ctx, layer, amount) { self.app.ui.status = format!("{}: {error}", i18n::t("AI Denoise failed")); }
        }
        vravio_finish_denoise(&mut self.app);
'@
$aiToolsCommand = @'
    if id == "filter.vravio.aiTools" {
        let doc = app.session.active().ok_or("no document is open".to_string());
        return Some(doc.and_then(|doc| {
            let export = app.services.export.as_ref().ok_or("PNG export is unavailable")?;
            let (bytes, _) = export(&doc.doc, "vravio-ai-input.png", &crate::ExportSettings::default())?;
            let write = app.services.write.as_mut().ok_or("browser bridge is unavailable")?;
            write("vravio-ai-input.png", &bytes)?;
            Ok(json!({"sent": true}))
        }));
    }
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '    if id == "filter.vravio.photoRestore"' 'if id == "filter.vravio.aiTools" {' $aiToolsCommand
$aiToolsBridge = @'
fn send_ai_input(bytes: &[u8], tool: &str) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    js_sys::Reflect::set(&message, &"type".into(), &"vravio-ai-open".into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"tool".into(), &tool.into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"bytes".into(), &js_sys::Uint8Array::from(bytes).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn send_restore_input(' 'fn send_ai_input(' $aiToolsBridge
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn download(path: &str, bytes: &[u8]) -> Result<(), String> {' 'vravio-ai-input.png' '    if path.ends_with("vravio-ai-input.png") { return send_ai_input(bytes, "depth"); }'
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn download(path: &str, bytes: &[u8]) -> Result<(), String> {' 'vravio-ai-denoise.png' '    if path.ends_with("vravio-ai-denoise.png") { return send_ai_input(bytes, "denoise"); }'
# VRAVIO raster strings are English in code; Russian and Ukrainian come from the editor's catalogs
# (other languages show the English text, like any untranslated string).
foreach ($catalog in @(
  @('ru', @(
    @('Restore Old Photos…', 'Реставрация старых фото…'),
    @('AI', 'ИИ'),
    @('Remove Background…', 'Удалить фон…'),
    @('Noise Reduction…', 'Шумоподавление…'),
    @('AI Denoise', 'ИИ-шумоподавление'),
    @('Applied after OK; a large photo can take a few minutes', 'Применяется после «ОК»; большой снимок может обрабатываться несколько минут'),
    @('AI Denoise isn''t available for smart filters', 'ИИ-шумоподавление недоступно для смарт-фильтров'),
    @('AI Denoise applied', 'ИИ-шумоподавление применено'),
    @('AI Denoise cancelled', 'ИИ-шумоподавление отменено'),
    @('AI Denoise failed', 'Ошибка ИИ-шумоподавления'),
    @('Depth Map and Upscale…', 'Карта глубины и увеличение…'),
    @('Restored', 'Восстановлено'),
    @('Upscaled ×4', 'Увеличено ×4'),
    @('File name and format (.psd, .ora, .png, .jpg, .tif):', 'Имя и формат файла (.psd, .ora, .png, .jpg, .tif):'),
    @('Save the document before closing it', 'Сначала сохраните документ перед закрытием'))),
  @('uk', @(
    @('Restore Old Photos…', 'Реставрація старих фото…'),
    @('AI', 'ШІ'),
    @('Remove Background…', 'Видалити фон…'),
    @('Noise Reduction…', 'Зменшення шуму…'),
    @('AI Denoise', 'ШІ-шумозаглушення'),
    @('Applied after OK; a large photo can take a few minutes', 'Застосовується після «OK»; великий знімок може оброблятися кілька хвилин'),
    @('AI Denoise isn''t available for smart filters', 'ШІ-шумозаглушення недоступне для смарт-фільтрів'),
    @('AI Denoise applied', 'ШІ-шумозаглушення застосовано'),
    @('AI Denoise cancelled', 'ШІ-шумозаглушення скасовано'),
    @('AI Denoise failed', 'Помилка ШІ-шумозаглушення'),
    @('Depth Map and Upscale…', 'Карта глибини та збільшення…'),
    @('Restored', 'Відновлено'),
    @('Upscaled ×4', 'Збільшено ×4'),
    @('File name and format (.psd, .ora, .png, .jpg, .tif):', "Ім'я та формат файлу (.psd, .ora, .png, .jpg, .tif):"),
    @('Save the document before closing it', 'Спершу збережіть документ перед закриттям')))
)) {
  $file = Join-Path $root "upstream/photocraft/crates/ui-egui/src/i18n/$($catalog[0]).tsv"
  $text = [IO.File]::ReadAllText($file)
  $add = ''
  foreach ($pair in $catalog[1]) { if (-not $text.Contains("`t$($pair[0])`t")) { $add += "`t$($pair[0])`t$($pair[1])`n" } }
  if ($add -ne '') { [IO.File]::WriteAllText($file, $text.TrimEnd("`r", "`n") + "`n" + $add, [Text.UTF8Encoding]::new($false)) }
}
# Raster on the web: the system clipboard. Copy also puts the pixels on the browser clipboard as PNG;
# Ctrl+V takes an image from the paste event (held until it is decoded), and a paste that finds no
# image asks the browser for the clipboard. So pixels move between browser tabs and from other apps.
$clipboardPage = @'
  <script>
    // VRAVIO: the browser clipboard for the raster editor (images between tabs and from other apps).
    (() => {
      const state = { image: null, decoding: false, reading: false, held: null, pending: null, inPlace: false, keyAt: 0, pasteAt: 0, own: false, mirrored: false };
      const decode = async blob => {
        const bitmap = await createImageBitmap(blob, { premultiplyAlpha: 'none', colorSpaceConversion: 'none' });
        const canvas = document.createElement('canvas');
        canvas.width = bitmap.width; canvas.height = bitmap.height;
        const context = canvas.getContext('2d', { willReadFrequently: true });
        context.drawImage(bitmap, 0, 0); bitmap.close?.();
        const pixels = context.getImageData(0, 0, canvas.width, canvas.height).data;
        return { width: canvas.width, height: canvas.height, data: new Uint8Array(pixels.buffer, pixels.byteOffset, pixels.byteLength) };
      };
      const readSystem = async () => {
        if (!navigator.clipboard?.read) return undefined;
        for (const item of await navigator.clipboard.read()) {
          const type = item.types.find(t => t.startsWith('image/'));
          if (type) return decode(await item.getType(type));
        }
        return null;
      };
      const command = () => state.inPlace && performance.now() - state.keyAt < 2000 ? 'edit.pasteSpecial.pasteInPlace' : 'edit.paste';
      addEventListener('keydown', e => { if ((e.ctrlKey || e.metaKey) && e.code === 'KeyV') { state.inPlace = e.shiftKey; state.keyAt = performance.now(); } }, true);
      addEventListener('paste', e => {
        state.pasteAt = performance.now();
        const items = [...(e.clipboardData?.items || [])];
        const file = items.find(i => i.kind === 'file' && i.type.startsWith('image/'))?.getAsFile();
        if (!file) {
          // Ctrl+Shift+V pastes as plain text in browsers and never carries the image; otherwise
          // a paste without an image means the clipboard holds none now. Our own copy that the
          // browser refused to put on the clipboard stays: it is still the last thing copied here.
          if (!state.inPlace && items.length && !(state.own && !state.mirrored)) { state.image = null; state.own = false; }
          return;
        }
        state.decoding = true; state.held = command();
        decode(file).then(image => { state.image = image; state.own = false; }).catch(() => { state.held = null; }).finally(() => { state.decoding = false; });
      }, true);
      // With clipboard access already granted, keep the cached image current when the tab is entered.
      addEventListener('focus', () => {
        navigator.permissions?.query({ name: 'clipboard-read' }).then(p => {
          if (p.state === 'granted') readSystem().then(image => { if (image !== undefined && !(state.own && !state.mirrored)) { state.image = image; state.own = false; } }).catch(() => {});
        }).catch(() => {});
      });
      window.__vravioClipboard = {
        // The image a paste should use. With none cached (a menu paste, or Ctrl+Shift+V), ask the
        // browser once; the paste then runs again when the image arrives.
        peek() {
          const keyboardPaste = performance.now() - state.pasteAt < 1000 && !state.inPlace;
          if (!state.image && !state.decoding && !state.reading && !keyboardPaste) {
            state.reading = true; state.held = null;
            const id = command();
            readSystem().then(image => { if (image) { state.image = image; state.own = false; state.pending = id; } }).catch(() => {}).finally(() => { state.reading = false; });
          }
          return state.image;
        },
        write(width, height, data) {
          state.image = { width, height, data }; state.own = true; state.mirrored = false;
          if (!navigator.clipboard?.write || !window.ClipboardItem) return;
          const png = new Promise((resolve, reject) => {
            const canvas = document.createElement('canvas');
            canvas.width = width; canvas.height = height;
            canvas.getContext('2d').putImageData(new ImageData(new Uint8ClampedArray(data.buffer, data.byteOffset, data.byteLength), width, height), 0, 0);
            canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error('PNG')), 'image/png');
          });
          navigator.clipboard.write([new ClipboardItem({ 'image/png': png })]).then(() => { if (state.image?.data === data) state.mirrored = true; }).catch(() => {});
        },
        busy() { return state.decoding || state.reading; },
        // The paste keys were held back while decoding: run that paste when the image is ready.
        defer() { if (state.held) { state.pending = state.held; state.held = null; } },
        takePending() {
          if (state.decoding || state.reading || !state.pending) return null;
          const id = state.pending; state.pending = null; return id;
        },
      };
    })();
  </script>
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/index.html' '</head>' '__vravioClipboard' $clipboardPage.TrimEnd("`r", "`n")
$clipboardBridge = @'
/// VRAVIO: the page's clipboard helper (`window.__vravioClipboard`, in index.html).
fn web_clipboard_call(name: &str, args: &[wasm_bindgen::JsValue]) -> Option<wasm_bindgen::JsValue> {
    let window = web_sys::window()?;
    let clip = js_sys::Reflect::get(window.as_ref(), &"__vravioClipboard".into()).ok().filter(|v| v.is_object())?;
    let function = js_sys::Reflect::get(&clip, &name.into()).ok()?.dyn_into::<js_sys::Function>().ok()?;
    let list = js_sys::Array::new();
    for arg in args {
        list.push(arg);
    }
    function.apply(&clip, &list).ok()
}

/// Keeps frames coming while the helper decodes or reads an image, so a held paste runs.
static WEB_CLIPBOARD_CTX: std::sync::OnceLock<egui::Context> = std::sync::OnceLock::new();

fn web_clipboard_poll() {
    if web_clipboard_call("busy", &[]).and_then(|v| v.as_bool()).unwrap_or(false) {
        if let Some(ctx) = WEB_CLIPBOARD_CTX.get() {
            ctx.request_repaint_after(std::time::Duration::from_millis(30));
        }
    }
}

fn web_clipboard_peek() -> Result<Option<(u32, u32, Vec<u8>)>, String> {
    let image = web_clipboard_call("peek", &[]).filter(|v| v.is_object());
    web_clipboard_poll();
    let Some(image) = image else { return Ok(None) };
    let size = |key: &str| js_sys::Reflect::get(&image, &key.into()).ok().and_then(|v| v.as_f64()).unwrap_or(0.0) as u32;
    let (width, height) = (size("width"), size("height"));
    let data = js_sys::Reflect::get(&image, &"data".into()).map_err(|e| format!("{e:?}"))?;
    let bytes = js_sys::Uint8Array::new(&data).to_vec();
    Ok((width > 0 && height > 0 && bytes.len() == width as usize * height as usize * 4).then_some((width, height, bytes)))
}

fn web_clipboard_write(width: u32, height: u32, pixels: &[u8]) {
    let args = [wasm_bindgen::JsValue::from_f64(width as f64), wasm_bindgen::JsValue::from_f64(height as f64), js_sys::Uint8Array::from(pixels).into()];
    let _ = web_clipboard_call("write", &args);
}
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' 'fn send_ai_input(' 'fn web_clipboard_call(' $clipboardBridge
$clipboardHold = @'
        // VRAVIO: an image from the paste event is still being decoded: hold the paste keys, the
        // paste runs in `logic` once the image is ready.
        if web_clipboard_call("busy", &[]).and_then(|v| v.as_bool()).unwrap_or(false) {
            let before = raw_input.events.len();
            raw_input.events.retain(|e| {
                !matches!(e, egui::Event::Key { key: egui::Key::V, pressed: true, modifiers, .. } if modifiers.command)
                    && !matches!(e, egui::Event::Paste(_) | egui::Event::PasteImage(_))
            });
            if raw_input.events.len() != before {
                web_clipboard_call("defer", &[]);
            }
            ctx.request_repaint_after(std::time::Duration::from_millis(30));
        }
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '        eframe::App::raw_input_hook(&mut self.app, ctx, raw_input);' 'web_clipboard_call("defer"' $clipboardHold.TrimEnd("`r", "`n")
$clipboardRun = @'
        // VRAVIO: a paste held for a clipboard image, or one that had to ask the browser for it.
        let _ = WEB_CLIPBOARD_CTX.get_or_init(|| ctx.clone());
        if let Some(id) = web_clipboard_call("takePending", &[]).and_then(|v| v.as_string()) {
            self.app.ui.status.clear();
            self.app.ui.status_error = false;
            if let Err(error) = self.app.run(&id, serde_json::json!({})) {
                self.app.ui.status = error;
            }
            ctx.request_repaint();
        }
        web_clipboard_poll();
'@
Insert-After-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '    fn logic(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {' 'web_clipboard_call("takePending"' $clipboardRun.TrimEnd("`r", "`n")
# Audio: AudioSuite > Other > Separate Stems (AI). The selected audio clip goes to the stems dialog of the
# unified shell (restorer/stems, HTDemucs in the browser); the stems come back as new tracks at the clip.
Insert-After-Once 'upstream/soundcraft/crates/engine/catalog/menus.txt' 'AudioSuite > Other > Time Compression Expansion' 'Separate Stems (AI)' 'AudioSuite > Other > Separate Stems (AI)...'
Insert-Before-Once 'upstream/soundcraft/crates/ui-egui/src/menus.rs' '    ("ui.theme", "Appearance", "", None),' '"vravio.stems"' '    ("vravio.stems", "Separate Stems (AI)…", "AudioSuite > Other > Separate Stems (AI)...", None),'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/menus.rs' 'matches!(i, "audiosuite.process" | "ui.dock" | "ui.dock.reset")' 'matches!(i, "audiosuite.process" | "ui.dock" | "ui.dock.reset" | "vravio.stems")'
Insert-Before-Once 'upstream/soundcraft/crates/ui-egui/src/menus.rs' '/// Handle UI-layer commands. Returns None when `id` is not a UI command.' 'VRAVIO_STEMS_REQUEST:' @'
/// VRAVIO: Separate Stems (AI) was chosen. The web shell takes the selected clip to the stems dialog.
pub static VRAVIO_STEMS_REQUEST: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);

'@.TrimEnd("`r", "`n")
Insert-Before-Once 'upstream/soundcraft/crates/ui-egui/src/menus.rs' '        "app.checkForUpdates" | "help.checkForUpdates" => {' '"vravio.stems" => {' @'
        "vravio.stems" => {
            VRAVIO_STEMS_REQUEST.store(true, std::sync::atomic::Ordering::Relaxed);
            json!({})
        }
'@.TrimEnd("`r", "`n")
$audioStems = @'
// VRAVIO: AudioSuite > Separate Stems (AI). The selected audio clip goes to the stems dialog in the
// unified shell; the stems it sends back become new tracks at the clip's position, as one undo step.
thread_local! {
    static VRAVIO_STEMS: RefCell<Vec<(String, Vec<u8>)>> = const { RefCell::new(Vec::new()) };
    static VRAVIO_STEMS_AT: std::cell::Cell<i64> = const { std::cell::Cell::new(0) };
    static VRAVIO_STEMS_LISTENING: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

fn vravio_listen_stems(ctx: &egui::Context) {
    use wasm_bindgen::closure::Closure;
    if VRAVIO_STEMS_LISTENING.with(|l| l.replace(true)) {
        return;
    }
    let Some(window) = web_sys::window() else { return };
    let ctx = ctx.clone();
    let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event: web_sys::MessageEvent| {
        let Some(window) = web_sys::window() else { return };
        if window.location().origin().ok().as_deref() != Some(event.origin().as_str()) {
            return;
        }
        let data = event.data();
        if js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string()).as_deref() != Some("vravio-stems-result") {
            return;
        }
        let Ok(list) = js_sys::Reflect::get(&data, &"stems".into()) else { return };
        let mut stems = Vec::new();
        for item in js_sys::Array::from(&list).iter() {
            let name = js_sys::Reflect::get(&item, &"name".into()).ok().and_then(|v| v.as_string()).unwrap_or_else(|| "Stem.wav".into());
            let Ok(bytes) = js_sys::Reflect::get(&item, &"bytes".into()) else { continue };
            stems.push((name, js_sys::Uint8Array::new(&bytes).to_vec()));
        }
        VRAVIO_STEMS.with(|s| s.borrow_mut().extend(stems));
        ctx.request_repaint();
    });
    if window.add_event_listener_with_callback("message", cb.as_ref().unchecked_ref()).is_ok() {
        cb.forget();
    }
}

/// Send the selected audio clip's samples (its source audio under the clip, before clip gain and
/// fades) to the stems dialog.
fn vravio_open_stems(app: &mut SoundApp, ctx: &egui::Context) {
    let s = app.engine.session();
    let found = s.edit.selected_clips.iter().filter_map(|id| s.find_clip(*id)).find(|(_, c)| matches!(c.content, soundcraft_model::ClipContent::Audio { .. }));
    let Some((_, clip)) = found else {
        app.ui.status = "Select an audio clip to separate into stems".into();
        return;
    };
    let soundcraft_model::ClipContent::Audio { source, offset } = clip.content else { return };
    let Some(audio) = s.pool.get(source) else {
        app.ui.status = "The clip's audio is not loaded".into();
        return;
    };
    let Some(first) = audio.buffer.channels.first() else { return };
    let from = usize::try_from(offset.max(0)).unwrap_or(0).min(first.len());
    let to = usize::try_from(offset.saturating_add(clip.length).max(0)).unwrap_or(0).min(first.len());
    if to <= from {
        app.ui.status = "The clip has no audio".into();
        return;
    }
    let left = &first[from..to];
    let right = audio.buffer.channels.get(1).filter(|c| c.len() >= to).map_or(left, |c| &c[from..to]);
    let send = || -> Result<(), String> {
        let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
        let window = web_sys::window().ok_or("no window")?;
        let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
        let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
        let message = js_sys::Object::new();
        js_sys::Reflect::set(&message, &"type".into(), &"vravio-stems-open".into()).map_err(js)?;
        js_sys::Reflect::set(&message, &"name".into(), &clip.name.as_str().into()).map_err(js)?;
        js_sys::Reflect::set(&message, &"sampleRate".into(), &wasm_bindgen::JsValue::from_f64(f64::from(audio.buffer.sample_rate))).map_err(js)?;
        js_sys::Reflect::set(&message, &"left".into(), &js_sys::Float32Array::from(left).into()).map_err(js)?;
        js_sys::Reflect::set(&message, &"right".into(), &js_sys::Float32Array::from(right).into()).map_err(js)?;
        post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
        Ok(())
    };
    let start = clip.start;
    match send() {
        Ok(()) => {
            VRAVIO_STEMS_AT.with(|a| a.set(start));
            app.ui.status.clear();
            vravio_listen_stems(ctx);
        }
        Err(error) => app.ui.status = format!("Separate Stems: {error}"),
    }
}

/// Stems back from the dialog: one new track each at the clip's position, one undo step.
fn vravio_place_stems(app: &mut SoundApp) {
    let stems = VRAVIO_STEMS.with(|s| std::mem::take(&mut *s.borrow_mut()));
    if stems.is_empty() {
        return;
    }
    let at = VRAVIO_STEMS_AT.with(std::cell::Cell::get);
    let e = &mut app.engine;
    let before = e.session_arc();
    let mut added = 0usize;
    let mut failed = None;
    for (name, bytes) in &stems {
        match io::import_audio_bytes(e, name, bytes, None, None, at) {
            Ok(_) => added += 1,
            Err(error) => failed = Some(error.to_string()),
        }
    }
    if added > 0 {
        e.push_undo("Separate Stems", before);
    }
    app.ui.status = failed.unwrap_or_else(|| format!("Added {added} stem tracks"));
}
'@
Insert-Before-Once 'upstream/soundcraft/apps/soundcraft-web/src/web.rs' 'const CANVAS_ID:' 'fn vravio_open_stems(' $audioStems
Insert-After-Once 'upstream/soundcraft/apps/soundcraft-web/src/web.rs' '    fn logic(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {' 'VRAVIO_STEMS_REQUEST.swap' @'
        if soundcraft_ui_egui::menus::VRAVIO_STEMS_REQUEST.swap(false, std::sync::atomic::Ordering::Relaxed) {
            vravio_open_stems(&mut self.app, ctx);
        }
        vravio_place_stems(&mut self.app);
'@.TrimEnd("`r", "`n")
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
                    .prompt_with_message_and_default(photocraft_ui_egui::i18n::t("File name and format (.psd, .ora, .png, .jpg, .tif):"), &name)
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
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' 'log = { workspace = true }' "log = { workspace = true }`nserde_json = { workspace = true }"
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' "[dev-dependencies]`nserde_json = { workspace = true }" '[dev-dependencies]'
Replace-Exact $rasterWeb 'fn listen_restore_result(inbox: Inbox, cutout_inbox: CutoutInbox, restore_inbox: RestoreInbox, place_inbox: Inbox, snapshot_requested: Arc<AtomicBool>, ctx: egui::Context)' 'fn listen_restore_result(inbox: Inbox, cutout_inbox: CutoutInbox, restore_inbox: RestoreInbox, place_inbox: Inbox, snapshot_requested: Arc<AtomicBool>, tab_action: TabAction, ctx: egui::Context)'
Replace-Exact $rasterWeb 'type RestoreInbox = Arc<Mutex<Vec<(String, Vec<u8>, Vec<u8>)>>>;' "type RestoreInbox = Arc<Mutex<Vec<(String, Vec<u8>, Vec<u8>)>>>;`ntype TabAction = Arc<Mutex<Option<(String, usize)>>>;"
Replace-Exact $rasterWeb '                    cc.egui_ctx.data_mut(|data| data.insert_temp(egui::Id::new("vravio-unified-tabs"), true));' ''
Insert-Before-Once $rasterWeb '                    notify_bridge_ready();' 'let tab_action: TabAction' '                    let tab_action: TabAction = Arc::default();'
Replace-Exact $rasterWeb 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), vravio_place.clone(), snapshot_requested.clone(), cc.egui_ctx.clone());' 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), vravio_place.clone(), snapshot_requested.clone(), tab_action.clone(), cc.egui_ctx.clone());'
Replace-Exact $rasterWeb 'place_inbox, snapshot_requested, snapshot_revisions: HashMap::new(), unsaved' 'place_inbox, snapshot_requested, snapshot_revisions: HashMap::new(), tab_action, tab_state: String::new(), unified_settings, unsaved'
Insert-After-Once $rasterWeb '    restore_inbox: RestoreInbox,' '    tab_state: String,' "    snapshot_requested: Arc<AtomicBool>,`n    snapshot_revisions: HashMap<u64, u64>,`n    tab_action: TabAction,`n    tab_state: String,"
$tabStateMethod = @'
    fn sync_document_tabs(&mut self) {
        let documents: Vec<_> = self.app.session.documents().iter().map(|state| serde_json::json!({
            "id": state.doc.id.0.to_string(), "name": state.doc.name, "dirty": state.is_dirty()
        })).collect();
        let payload = serde_json::json!({"type": "vravio-documents:state", "documents": documents, "activeIndex": self.app.session.active_index(), "language": photocraft_ui_egui::i18n::current().code()});
        let next = payload.to_string();
        if next == self.tab_state { return; }
        if send_document_tabs(&next).is_ok() { self.tab_state = next; }
    }
'@
Insert-Before-Once $rasterWeb '    fn save_presets(&mut self, ctx: &egui::Context) {' 'fn sync_document_tabs(&mut self)' $tabStateMethod
Insert-After-Once $rasterWeb '        self.app.ui_frame(ui, frame);' 'self.sync_document_tabs();' '        self.sync_document_tabs();'
$rasterSettingsListener = @'
fn listen_unified_settings(settings: UnifiedSettings, ctx: egui::Context) {
    use wasm_bindgen::closure::Closure;
    let Some(window) = web_sys::window() else { return };
    let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event: web_sys::MessageEvent| {
        let Some(window) = web_sys::window() else { return };
        if window.location().origin().ok().as_deref() != Some(event.origin().as_str()) { return }
        let data = event.data();
        if js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string()).as_deref() != Some("vravio-settings:apply") { return }
        let language = js_sys::Reflect::get(&data, &"language".into()).ok().and_then(|v| v.as_string()).filter(|v| v.len() <= 16);
        let appearance = js_sys::Reflect::get(&data, &"appearance".into()).ok().and_then(|v| v.as_string()).filter(|v| v == "dark" || v == "light");
        *settings.lock().unwrap_or_else(PoisonError::into_inner) = Some((language, appearance));
        ctx.request_repaint();
    });
    if window.add_event_listener_with_callback("message", cb.as_ref().unchecked_ref()).is_ok() { cb.forget(); }
}
'@
Insert-Before-Once $rasterWeb 'fn listen_restore_result(' 'fn listen_unified_settings(' $rasterSettingsListener
Insert-After-Once $rasterWeb 'type TabAction = Arc<Mutex<Option<(String, usize)>>>;' 'type UnifiedSettings =' 'type UnifiedSettings = Arc<Mutex<Option<(Option<String>, Option<String>)>>>;'
Insert-After-Once $rasterWeb '                    let tab_action: TabAction = Arc::default();' 'let unified_settings: UnifiedSettings' "                    let unified_settings: UnifiedSettings = Arc::default();`n                    listen_unified_settings(unified_settings.clone(), cc.egui_ctx.clone());"
Insert-After-Once $rasterWeb '    tab_state: String,' '    unified_settings: UnifiedSettings,' '    unified_settings: UnifiedSettings,'
Replace-Exact $rasterWeb '"language": photocraft_ui_egui::i18n::current().code()' '"language": photocraft_ui_egui::i18n::current().code(), "theme": self.app.ui.theme.id()'
Insert-After-Once $rasterWeb '    fn logic(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {' 'let settings = self.unified_settings' @'
        let settings = self.unified_settings.lock().unwrap_or_else(PoisonError::into_inner).take();
        if let Some((language, appearance)) = settings {
            if let Some(language) = language {
                if let Err(error) = self.app.run("prefs.set", serde_json::json!({"path":"interface.language","value":language})) { self.app.ui.status = error; }
            }
            if let Some(appearance) = appearance {
                self.app.set_theme(ctx, if appearance == "light" { ThemeKind::StudioLight } else { ThemeKind::Studio });
            }
        }
'@
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
                self.app.ui.status = photocraft_ui_egui::i18n::t("Save the document before closing it").into();
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
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/canvas/tabs.rs' 'if (!app.ui.view.hides_tabs() || opening) && !ui.ctx().data(|data| data.get_temp::<bool>(egui::Id::new("vravio-unified-tabs")).unwrap_or(false)) {' 'if !app.ui.view.hides_tabs() || opening {'
Replace-Exact 'upstream/vectorcraft/apps/vectorcraft-web/src/web.rs' '                ctx.data_mut(|data| data.insert_temp(egui::Id::new("vravio-unified-tabs"), true));' ''
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/app.rs' 'if self.ui.screen_mode < 3 && !ui.ctx().data(|data| data.get_temp::<bool>(egui::Id::new("vravio-unified-tabs")).unwrap_or(false)) {' 'if self.ui.screen_mode < 3 {'

# A sound session and a video project are single documents. Publish their live
# name/dirty state to the same shell strip used by raster and vector documents.
$audioWeb = 'upstream/soundcraft/apps/soundcraft-web/src/web.rs'
$audioSettingsListener = @'
type UnifiedAppearance = Rc<RefCell<Option<String>>>;
fn listen_unified_appearance(settings: UnifiedAppearance, ctx: egui::Context) {
    use wasm_bindgen::closure::Closure;
    let Some(window) = web_sys::window() else { return };
    let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event: web_sys::MessageEvent| {
        let Some(window) = web_sys::window() else { return };
        if window.location().origin().ok().as_deref() != Some(event.origin().as_str()) { return }
        let data = event.data();
        if js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string()).as_deref() != Some("vravio-settings:apply") { return }
        let appearance = js_sys::Reflect::get(&data, &"appearance".into()).ok().and_then(|v| v.as_string()).filter(|v| v == "dark" || v == "light");
        *settings.borrow_mut() = appearance;
        ctx.request_repaint();
    });
    if window.add_event_listener_with_callback("message", cb.as_ref().unchecked_ref()).is_ok() { cb.forget(); }
}
'@
Insert-Before-Once $audioWeb 'const CANVAS_ID:' 'fn listen_unified_appearance(' $audioSettingsListener
Replace-Exact $audioWeb 'let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event| {' 'let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event: web_sys::MessageEvent| {'
Replace-Exact 'upstream/soundcraft/apps/soundcraft-web/Cargo.toml' '"CssStyleDeclaration"]' '"CssStyleDeclaration", "MessageEvent", "EventTarget"]'
Insert-After-Once $audioWeb '    samples: SampleInbox,' 'tab_state: String,' '    tab_state: String,'
Replace-Exact $audioWeb 'WebShell { app, inbox: Rc::default(), samples: Rc::default() }' 'WebShell { app, inbox: Rc::default(), samples: Rc::default(), tab_state: String::new(), unified_appearance }'
Insert-After-Once $audioWeb '    tab_state: String,' '    unified_appearance: UnifiedAppearance,' '    unified_appearance: UnifiedAppearance,'
Insert-After-Once $audioWeb '                    let app = SoundApp::new(engine, Some(player), Services::default());' 'let unified_appearance: UnifiedAppearance' "                    let unified_appearance: UnifiedAppearance = Rc::default();`n                    listen_unified_appearance(unified_appearance.clone(), cc.egui_ctx.clone());"
$audioTabSender = @'
fn vravio_send_tab(payload: &str) -> Result<(), String> {
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(|e| format!("{e:?}"))?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(|e| format!("{e:?}"))?
        .dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::JSON::parse(payload).map_err(|e| format!("{e:?}"))?;
    post.call2(&parent, &message, &window.location().origin().map_err(|e| format!("{e:?}"))?.into())
        .map_err(|e| format!("{e:?}"))?;
    Ok(())
}
'@
Insert-Before-Once $audioWeb 'const CANVAS_ID:' 'fn vravio_send_tab(' $audioTabSender
$audioTabMethod = @'
    fn vravio_sync_tab(&mut self) {
        let session = self.app.engine.session();
        let payload = serde_json::json!({"type":"vravio-documents:state","documents":[{
            "id":"session", "name":session.name, "dirty":self.app.engine.is_dirty()
        }], "activeIndex":0, "appearance":self.app.ui.theme.id()}).to_string();
        if payload != self.tab_state && vravio_send_tab(&payload).is_ok() { self.tab_state = payload; }
    }
'@
Insert-Before-Once $audioWeb '    /// File > Open Session…' 'fn vravio_sync_tab(&mut self)' $audioTabMethod
Insert-After-Once $audioWeb '        self.app.ui(ui);' 'self.vravio_sync_tab();' '        self.vravio_sync_tab();'
Insert-After-Once $audioWeb '    fn logic(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {' 'self.unified_appearance.borrow_mut().take()' @'
        if let Some(appearance) = self.unified_appearance.borrow_mut().take() {
            if let Err(error) = self.app.run("ui.theme", serde_json::json!({"mode":appearance})) { self.app.ui.status = error; }
        }
'@

$videoWeb = 'upstream/filmcraft/apps/filmcraft-web/src/lib.rs'
Insert-After-Once $videoWeb '    pub autosave: recovery::Autosave,' 'tab_state: String,' '    tab_state: String,'
Replace-Exact $videoWeb 'WebApp { app, audio, autosave: recovery::Autosave::default(), host: host_for_app }' 'WebApp { app, audio, autosave: recovery::Autosave::default(), host: host_for_app, tab_state: String::new() }'
$videoTabSender = @'
fn vravio_send_tab(payload: &str) -> Result<(), String> {
    use wasm_bindgen::JsCast as _;
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(|e| format!("{e:?}"))?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(|e| format!("{e:?}"))?
        .dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::JSON::parse(payload).map_err(|e| format!("{e:?}"))?;
    post.call2(&parent, &message, &window.location().origin().map_err(|e| format!("{e:?}"))?.into())
        .map_err(|e| format!("{e:?}"))?;
    Ok(())
}
'@
Insert-Before-Once $videoWeb '/// The eframe app:' 'fn vravio_send_tab(' $videoTabSender
$videoTabMethod = @'
    fn vravio_sync_tab(&mut self) {
        let payload = serde_json::json!({"type":"vravio-documents:state","documents":[{
            "id":"project", "name":self.app.session.project.name, "dirty":self.app.session.is_dirty()
        }], "activeIndex":0, "language":self.app.session.prefs.general.interface_language, "appearance":self.app.session.prefs.appearance.appearance_mode}).to_string();
        if payload != self.tab_state && vravio_send_tab(&payload).is_ok() { self.tab_state = payload; }
    }
'@
Insert-Before-Once $videoWeb 'impl eframe::App for WebApp {' 'fn vravio_sync_tab(&mut self)' ('impl WebApp {' + "`n" + $videoTabMethod + "`n}")
Insert-After-Once $videoWeb '        self.app.ui(ui, frame);' 'self.vravio_sync_tab();' '        self.vravio_sync_tab();'

# An embedded raster image can be opened in the raster editor from its own context
# menu or the Properties panel. The web host forwards this request to the unified
# shell; the Rust UI remains independent of browser APIs and desktop builds work.
$vectorContext = 'upstream/vectorcraft/crates/ui-egui/src/menus/context.rs'
Insert-Before-Once $vectorContext '        v.extend([c("Make Guides", "view.guides.make"), Sep, sub("Transform", transform_items())]);' 'vravio.editInRaster' @'
        if matches!(roots.as_slice(), [node] if matches!(&node.kind, NodeKind::Image(image) if image.link.is_none())) {
            v.extend([Sep, c("Edit in Raster", "vravio.editInRaster")]);
        }
'@
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/menus/state.rs' '    match id {
        // Save is off for a clean document that already has its own file.' '    match id {
        "vravio.editInRaster" => selected_image(app, |image| image.link.is_none()),
        // Save is off for a clean document that already has its own file.'
$vectorCanvasContext = 'upstream/vectorcraft/crates/ui-egui/src/canvas/context.rs'
Replace-Exact $vectorCanvasContext '        crate::menus::invoke(app, &id, p);' '        if id == "vravio.editInRaster" {
            resp.ctx.data_mut(|data| data.insert_temp(egui::Id::new("vravio-edit-in-raster"), true));
        } else {
            crate::menus::invoke(app, &id, p);
        }'
$vectorProps = 'upstream/vectorcraft/crates/ui-egui/src/panels/properties.rs'
Insert-After-Once $vectorProps '        crate::panels::image_trace::trace_button(app, ui, ui.available_width());' 'vravio-edit-in-raster' @'
        if crate::menus::enabled(app, "vravio.editInRaster")
            && widgets::flat_button(ui, tl!("Edit in Raster"), ui.available_width()).clicked()
        {
            ui.ctx().data_mut(|data| data.insert_temp(egui::Id::new("vravio-edit-in-raster"), true));
        }
'@
Replace-Exact $vectorProps 'widgets::flat_button(ui, "Редактировать в растре", ui.available_width())' 'widgets::flat_button(ui, tl!("Edit in Raster"), ui.available_width())'
$vectorWeb = 'upstream/vectorcraft/apps/vectorcraft-web/src/web.rs'
Insert-After-Once $vectorWeb '            app.ui(ui);' 'vravio-edit-in-raster' @'
            if ctx.data(|data| data.get_temp::<bool>(egui::Id::new("vravio-edit-in-raster")).unwrap_or(false)) {
                ctx.data_mut(|data| data.insert_temp(egui::Id::new("vravio-edit-in-raster"), false));
                if let Some(window) = web_sys::window() {
                    if let Ok(parent) = js_sys::Reflect::get(window.as_ref(), &"parent".into()) {
                        if let Ok(post) = js_sys::Reflect::get(&parent, &"postMessage".into()) {
                            if let Ok(post) = post.dyn_into::<js_sys::Function>() {
                                let message = js_sys::Object::new();
                                let _ = js_sys::Reflect::set(&message, &"type".into(), &"vravio-vector:edit-in-raster".into());
                                if let Ok(origin) = window.location().origin() {
                                    let _ = post.call2(&parent, &message, &origin.into());
                                }
                            }
                        }
                    }
                }
            }
'@
Insert-After-Once 'upstream/vectorcraft/crates/ui-egui/src/i18n/ru.tsv' "`tEdit Original`tРедактировать оригинал" "`tEdit in Raster`tРедактировать в растре" "`tEdit in Raster`tРедактировать в растре"
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
Insert-Before-Once $rasterWeb '        import: Some(Box::new(|name: &str, bytes: &[u8], opts: &photocraft_io::ImportOptions|' 'clipboard_set_image: Some(Box::new(|width, height, pixels|' "        clipboard_set_image: Some(Box::new(|width, height, pixels| { web_clipboard_write(width, height, pixels); send_clipboard_image(width, height, pixels) })),`n        clipboard_get_image: Some(Box::new(web_clipboard_peek)),"
Insert-Before-Once $rasterWeb '                    notify_bridge_ready();' 'let snapshot_requested = Arc::new(AtomicBool::new(false));' '                    let snapshot_requested = Arc::new(AtomicBool::new(false));'
Replace-Exact $rasterWeb 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), vravio_place.clone(), cc.egui_ctx.clone());' 'listen_restore_result(inbox.clone(), cutout_inbox.clone(), restore_inbox.clone(), vravio_place.clone(), snapshot_requested.clone(), tab_action.clone(), cc.egui_ctx.clone());'
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
# Cloud font catalog (font-catalog/manifest.txt, copied next to each web editor as fonts/manifest.txt).
# Its files are `gfonts/<commit>/<licence>/<family>/<file>`: pinned TTFs of the google/fonts repository on
# raw.githubusercontent.com (jsDelivr refuses the files of this repository it hasn't cached: the
# repository is over its 50 MB limit). The editors' served-fonts loader fetches a family when it is
# picked or hovered; this lets it read those paths cross-origin (CORS) while every other path stays
# same-origin.
$cloudFetchOld = @'
    let window = web_sys::window().ok_or("no window")?;
    let init = web_sys::RequestInit::new();
    init.set_mode(web_sys::RequestMode::SameOrigin);
'@
$cloudFetchNew = @'
    let window = web_sys::window().ok_or("no window")?;
    // VRAVIO: `gfonts/<commit>/<licence>/<family>/<file>` is a pinned file of google/fonts (cloud font
    // catalog); `fspreview/<id>/<subset>` a family's light preview (a Fontsource script subset).
    let cloud = url.strip_prefix("gfonts/").map(|rest| format!("https://raw.githubusercontent.com/google/fonts/{rest}")).or_else(|| {
        url.strip_prefix("fspreview/").and_then(|rest| rest.split_once('/')).map(|(id, subset)| format!("https://cdn.jsdelivr.net/fontsource/fonts/{id}@latest/{subset}-400-normal.woff"))
    });
    let init = web_sys::RequestInit::new();
    init.set_mode(if cloud.is_some() { web_sys::RequestMode::Cors } else { web_sys::RequestMode::SameOrigin });
'@
Replace-Exact $rasterWeb $cloudFetchOld $cloudFetchNew
Replace-Exact $rasterWeb 'let request = window.fetch_with_str_and_init(url, &init);' 'let request = window.fetch_with_str_and_init(cloud.as_deref().unwrap_or(url), &init);'

# Cloud font catalog for the vector editor: the same fonts/manifest.txt as the raster editor. Its
# families join the font menu; when text first asks for one that isn't loaded, the web shell fetches
# its files (pinned google/fonts TTFs) and adds them to the font database.
$vectorText = 'upstream/vectorcraft/crates/text/src'
$cloudRs = @'
//! Cloud font catalog (VRAVIO): families the web build fetches on demand. The site lists them in
//! `fonts/manifest.txt` (`family | style | file`, one file per line). A family is requested the
//! first time text asks for it and isn't loaded; the web shell fetches its files and adds them
//! with `FontDb::add_font`.

use std::collections::{HashMap, HashSet};
use std::sync::{LazyLock, Mutex, MutexGuard, PoisonError};

#[derive(Default)]
struct State {
    /// The families the catalog lists, in manifest order.
    families: Vec<String>,
    /// Each family's files (paths relative to the site root).
    files: HashMap<String, Vec<String>>,
    /// Families asked for, not yet taken by [`take_requests`].
    requested: Vec<String>,
    /// Families already asked for.
    asked: HashSet<String>,
    /// Families whose files couldn't be fetched: not asked for again this session (a font menu
    /// draws its rows every frame, and would ask again each time).
    failed: HashSet<String>,
    /// Each family's class (the manifest's 9th field) and format, for the font menu's filters
    /// before its files arrive.
    traits: HashMap<String, crate::FontTraits>,
}

static STATE: LazyLock<Mutex<State>> = LazyLock::new(|| Mutex::new(State::default()));

fn state() -> MutexGuard<'static, State> {
    STATE.lock().unwrap_or_else(PoisonError::into_inner)
}

/// Lists the families of a manifest (`family | style | file | … | class`; `#` comments and
/// malformed lines are skipped; the 9th field is a font class key such as `sansSerif`). Returns how
/// many new families were added; the font menus refresh when it is above 0.
pub fn add_manifest(text: &str) -> usize {
    let mut added = 0;
    {
        let mut guard = state();
        let s = &mut *guard;
        for line in text.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            let mut fields = line.split(" | ").map(str::trim);
            let (Some(family), Some(_style), Some(file)) = (fields.next(), fields.next(), fields.next()) else { continue };
            if family.is_empty() || file.is_empty() || file.starts_with('/') || file.contains("..") || file.contains('\\') {
                continue;
            }
            let entry = s.files.entry(family.to_string()).or_default();
            if entry.is_empty() {
                s.families.push(family.to_string());
                added += 1;
            }
            entry.push(file.to_string());
            // A `[axes]` file name (percent-encoded) is a variable font.
            if let Some(class) = fields.nth(5).and_then(class_of) {
                s.traits.entry(family.to_string()).or_insert(crate::FontTraits { class, variable: file.contains("%5B"), ..Default::default() });
            }
        }
    }
    if added > 0 {
        crate::FontDb::global().changed();
    }
    added
}

/// The font menu class of a manifest class key.
fn class_of(key: &str) -> Option<crate::FontClass> {
    Some(match key {
        "serif" | "slabSerif" => crate::FontClass::Serif,
        "sansSerif" => crate::FontClass::Sans,
        "monospace" => crate::FontClass::Monospaced,
        "script" | "handwritten" => crate::FontClass::Script,
        "decorative" | "blackletter" => crate::FontClass::Decorative,
        _ => return None,
    })
}

/// A catalog family's class and format, as the manifest gives them (any case).
pub fn traits(family: &str) -> Option<crate::FontTraits> {
    state().traits.iter().find(|(f, _)| f.eq_ignore_ascii_case(family)).map(|(_, t)| *t)
}

/// Whether `family` is a catalog family (`Some`), and then whether its files were added.
pub fn download_state(family: &str) -> Option<bool> {
    contains(family).then(|| crate::FontDb::global().is_loaded(family))
}

/// The families the catalog lists.
pub fn families() -> Vec<String> {
    state().families.clone()
}

/// Does the catalog list `family` (any case)?
pub fn contains(family: &str) -> bool {
    state().families.iter().any(|f| f.eq_ignore_ascii_case(family))
}

/// Asks for a catalog family's files; once per family, and only for families the catalog lists.
pub fn request(family: &str) {
    let mut guard = state();
    let s = &mut *guard;
    let Some(name) = s.families.iter().find(|f| f.eq_ignore_ascii_case(family)).cloned() else { return };
    if s.asked.insert(name.clone()) {
        s.requested.push(name);
    }
}

/// The families asked for since the last call, each with its files.
pub fn take_requests() -> Vec<(String, Vec<String>)> {
    let mut guard = state();
    let s = &mut *guard;
    let asked = std::mem::take(&mut s.requested);
    asked
        .into_iter()
        .map(|f| {
            let files = s.files.get(&f).cloned().unwrap_or_default();
            (f, files)
        })
        .collect()
}

/// A family's files couldn't be fetched: text set in it keeps the fallback font.
pub fn failed(family: &str) {
    state().failed.insert(family.to_string());
}

/// Is `family` a catalog family on its way (listed, not loaded, not failed)? Text set in it draws
/// with the fallback font meanwhile, so a font menu doesn't keep a sample of it yet.
pub fn pending(family: &str) -> bool {
    let listed = {
        let s = state();
        s.families.iter().find(|f| f.eq_ignore_ascii_case(family)).is_some_and(|f| !s.failed.contains(f))
    };
    listed && !crate::FontDb::global().is_loaded(family)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Requests are process-wide: the tests that take them run one at a time.
    static SERIAL: Mutex<()> = Mutex::new(());

    #[test]
    fn a_manifest_lists_its_families_once_and_skips_bad_lines() {
        let added = add_manifest(
            "# comment\nCloud Test A | Regular | gfonts/c/ofl/a/A%5Bwght%5D.ttf |  |  |  |  |  | sansSerif\nCloud Test A | Bold | gfonts/c/ofl/a/A-Bold.ttf\nbroken line\nCloud Test B | Regular | /etc/passwd\nCloud Test C | Regular | gfonts/../x.ttf\n",
        );
        assert_eq!(added, 1);
        assert!(contains("cloud test a"));
        assert!(!contains("Cloud Test B") && !contains("Cloud Test C"));
        assert!(crate::FontDb::global().families().iter().any(|f| f == "Cloud Test A"), "the font menus list it");
        assert!(crate::FontDb::global().has_family("Cloud Test A"), "a document naming it isn't missing a font");
        let sans = crate::FontTraits { class: crate::FontClass::Sans, variable: true, ..Default::default() };
        assert_eq!(traits("cloud test a"), Some(sans));
        assert_eq!(crate::FontDb::global().family_traits("Cloud Test A"), sans, "the menu filters see its class before it is fetched");
        assert_eq!(class_of("handwritten"), Some(crate::FontClass::Script));
        assert_eq!(class_of("nonsense"), None);
    }

    #[test]
    fn a_family_is_requested_once_with_its_files_until_it_fails() {
        let _serial = SERIAL.lock().unwrap_or_else(PoisonError::into_inner);
        add_manifest("Cloud Test D | Regular | gfonts/c/ofl/d/D.ttf\nCloud Test D | Bold | gfonts/c/ofl/d/D-Bold.ttf\n");
        request("Not In The Catalog");
        request("cloud test d");
        request("Cloud Test D");
        let got: Vec<_> = take_requests().into_iter().filter(|(f, _)| f.starts_with("Cloud Test") || f.starts_with("Not In")).collect();
        assert_eq!(got, vec![("Cloud Test D".to_string(), vec!["gfonts/c/ofl/d/D.ttf".to_string(), "gfonts/c/ofl/d/D-Bold.ttf".to_string()])]);
        request("Cloud Test D");
        assert!(take_requests().iter().all(|(f, _)| f != "Cloud Test D"), "asked once");
        assert!(pending("Cloud Test D"), "on its way");
        failed("Cloud Test D");
        request("Cloud Test D");
        assert!(take_requests().iter().all(|(f, _)| f != "Cloud Test D"), "not asked again after a failed fetch");
        assert!(!pending("Cloud Test D"), "a failed family isn't waited for");
        assert!(!pending("Not In The Catalog"));
    }

    #[test]
    fn text_asking_for_an_unloaded_cloud_family_requests_it() {
        let _serial = SERIAL.lock().unwrap_or_else(PoisonError::into_inner);
        add_manifest("Cloud Test E | Regular | gfonts/c/ofl/e/E.ttf\n");
        // The fallback font draws the text meanwhile (or nothing, without bundled fonts).
        let _ = crate::FontDb::global().face("Cloud Test E", "Regular");
        assert!(take_requests().iter().any(|(f, _)| f == "Cloud Test E"));
    }
}
'@
$cloudFile = Join-Path $root "$vectorText/cloud.rs"
$cloudText = $cloudRs.Replace("`r`n", "`n")
$cloudNow = if (Test-Path $cloudFile) { [IO.File]::ReadAllText($cloudFile).Replace("`r`n", "`n") } else { '' }
if ($cloudNow -ne $cloudText) { [IO.File]::WriteAllText($cloudFile, $cloudText, [Text.UTF8Encoding]::new($false)) }
Insert-Before-Once "$vectorText/lib.rs" 'mod bitmap;' 'pub mod cloud;' 'pub mod cloud;'
Replace-Exact "$vectorText/fontdb/db.rs" 'pub(super) fn changed(&self) {' 'pub(crate) fn changed(&self) {'
$familyListOld = @'
        v.dedup_by(|a, b| a.eq_ignore_ascii_case(b));
        let list: Arc<[String]> = v.into();
'@
$familyListNew = @'
        v.dedup_by(|a, b| a.eq_ignore_ascii_case(b));
        // VRAVIO: the cloud catalog's families after the installed ones (a downloaded one is installed).
        let mut cloud: Vec<String> = crate::cloud::families().into_iter().filter(|f| !v.iter().any(|g| g.eq_ignore_ascii_case(f))).collect();
        cloud.sort_by_key(|a| a.to_lowercase());
        v.extend(cloud);
        let list: Arc<[String]> = v.into();
'@
Replace-Exact "$vectorText/fontdb/db.rs" $familyListOld.TrimEnd("`r", "`n") $familyListNew.TrimEnd("`r", "`n")
Replace-Exact "$vectorText/fontdb/lookup.rs" "        found`n            .or_else(|| self.find(FALLBACK_FAMILY, style))" "        if found.is_none() {`n            crate::cloud::request(family);`n        }`n        found`n            .or_else(|| self.find(FALLBACK_FAMILY, style))"
Replace-Exact "$vectorText/fontdb/lookup.rs" 'self.is_loaded(&family) || self.read_catalog().contains_key(&family.to_ascii_lowercase())' 'self.is_loaded(&family) || self.read_catalog().contains_key(&family.to_ascii_lowercase()) || crate::cloud::contains(&family)'
$cloudShell = @'

/// VRAVIO: the cloud font catalog (`fonts/manifest.txt`, see `vectorcraft_text::cloud`). Most hosts
/// serve none: a missing manifest is the normal case, not an error.
pub fn spawn_cloud_catalog(ctx: egui::Context) {
    wasm_bindgen_futures::spawn_local(async move {
        let Ok(bytes) = fetch("fonts/manifest.txt", "", STARTUP_TIMEOUT_MS).await else { return };
        let Ok(text) = String::from_utf8(bytes) else { return };
        if vectorcraft_text::cloud::add_manifest(&text) > 0 {
            ctx.request_repaint();
        }
    });
}

/// `gfonts/<commit>/<licence>/<family>/<file>` is a pinned file of google/fonts; other paths stay
/// relative to the page.
fn cloud_url(file: &str) -> String {
    match file.strip_prefix("gfonts/") {
        Some(rest) => format!("https://raw.githubusercontent.com/google/fonts/{rest}"),
        None => file.to_string(),
    }
}

/// Fetches the cloud families text asked for since the last frame and adds them to the font
/// database. Called every frame.
pub fn serve_cloud_fonts(ctx: &egui::Context) {
    for (family, files) in vectorcraft_text::cloud::take_requests() {
        let ctx = ctx.clone();
        wasm_bindgen_futures::spawn_local(async move {
            let mut loaded = false;
            for file in files {
                match fetch(&cloud_url(&file), "", BACKGROUND_TIMEOUT_MS).await {
                    Ok(bytes) => loaded |= FontDb::global().add_font(bytes) > 0,
                    Err(e) => log::warn!("cloud font {family}: {e}"),
                }
            }
            if loaded {
                ctx.request_repaint();
            } else {
                vectorcraft_text::cloud::failed(&family);
            }
        });
    }
}
'@
$vectorFonts = Join-Path $root 'upstream/vectorcraft/apps/vectorcraft-web/src/fonts.rs'
$fontsSrc = [IO.File]::ReadAllText($vectorFonts).Replace("`r`n", "`n")
if (-not $fontsSrc.Contains('pub fn spawn_cloud_catalog')) { [IO.File]::WriteAllText($vectorFonts, $fontsSrc.TrimEnd("`n") + "`n" + $cloudShell.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false)) }
Insert-After-Once $vectorWeb '                crate::fonts::spawn_background_fonts(ctx.clone());' 'spawn_cloud_catalog' '                crate::fonts::spawn_cloud_catalog(ctx.clone());'
Insert-After-Once $vectorWeb '    fn logic(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {' 'serve_cloud_fonts' '        crate::fonts::serve_cloud_fonts(ctx);'

Insert-After-Once 'upstream/vectorcraft/crates/ui-egui/src/font_menu.rs' '    let key: Key = (family.to_string(), style.unwrap_or("Regular").to_string(), sample.unwrap_or_default().to_string(), px);' 'cloud::pending(family)' @'
    // VRAVIO: a cloud family not downloaded yet has no sample (its row shows a cloud): drawing one
    // would download the whole family for a row the user may never pick, and a sample set in the
    // fallback font would be kept once it arrives.
    if vectorcraft_text::cloud::pending(family) {
        return None;
    }
'@
# Font menu class filters for cloud families before their files arrive: the class from the
# manifest's 9th field, the format from the file name.
Replace-Exact "$vectorText/fontdb/lookup.rs" '            None => scanned(&self.read_catalog()).unwrap_or_default(),' '            None => scanned(&self.read_catalog()).or_else(|| crate::cloud::traits(family)).unwrap_or_default(),'
$servedClasses = @'
/// VRAVIO: the class and format of the cloud catalog's families, from the manifest's 9th field (a
/// `FontClass` key) and file name (a `[axes]` file is variable), so the font menu's class filters
/// list them before their files are fetched.
static CLASSES: Mutex<Vec<(String, photocraft_text::FamilyTraits)>> = Mutex::new(Vec::new());

/// Reads the classes of a served font manifest (see [`CLASSES`]).
pub fn add_classes(manifest: &str) {
    let mut classes = CLASSES.lock().unwrap_or_else(PoisonError::into_inner);
    for line in manifest.lines() {
        let f: Vec<&str> = line.split(" | ").map(str::trim).collect();
        let (Some(family), Some(file), Some(class)) = (f.first(), f.get(2), f.get(8).and_then(|k| photocraft_text::FontClass::from_key(k))) else { continue };
        if family.starts_with('#') || classes.iter().any(|(n, _)| n == family) {
            continue;
        }
        let format = if file.contains("%5B") { photocraft_text::FontFormat::Variable } else { photocraft_text::FontFormat::TrueType };
        classes.push((family.to_string(), photocraft_text::FamilyTraits { class: Some(class), format, panose: [0; 10], weight: 400 }));
    }
}

/// A served family's traits from the manifest, until its fonts are installed.
pub fn served_traits(family: &str) -> Option<photocraft_text::FamilyTraits> {
    CLASSES.lock().unwrap_or_else(PoisonError::into_inner).iter().find(|(n, _)| n == family).map(|(_, t)| t.clone())
}

'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/text/served_fonts.rs' '#[cfg(test)]' 'pub fn add_classes' $servedClasses
Insert-Before-Once $rasterWeb '        served_fonts::add_fonts(&fonts);' 'served_fonts::add_classes(&text);' '        served_fonts::add_classes(&text);'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/text/font_filters.rs' '    let generation = photocraft_text::fonts::shared_generation();' '    let generation = photocraft_text::fonts::shared_generation().wrapping_add(photocraft_text::served::generation() << 32);'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/text/font_filters.rs' '.fonts.family_traits(family);' '.fonts.family_traits(family).or_else(|| super::served_fonts::served_traits(family));'
# Draw again once served fonts are installed: the font menu's samples and the canvas preview of a
# hovered cloud family otherwise wait for the next input event, so a still pointer shows nothing.
$repaintOld = '        served_fonts::install(&mut self.app, ctx, arrived);'
$repaintNew = @'
        let installed = !arrived.is_empty();
        served_fonts::install(&mut self.app, ctx, arrived);
        if installed {
            // VRAVIO: the font menu's samples and the canvas preview show the fonts on the next frames.
            ctx.request_repaint();
            ctx.request_repaint_after(std::time::Duration::from_millis(200));
        }
'@
Replace-Exact $rasterWeb $repaintOld $repaintNew.TrimEnd("`r", "`n")
# Raster font menu: a cloud filter button beside the others, icons instead of the format badges
# (a cloud for a cloud font not downloaded yet, a check once it is, the variable-font mark), and
# the installed families listed before the cloud catalog's.
$rasterFonts = 'upstream/photocraft/crates/ui-egui/src/text/served_fonts.rs'
$rasterFilters = 'upstream/photocraft/crates/ui-egui/src/text/font_filters.rs'
$rasterMenu = 'upstream/photocraft/crates/ui-egui/src/tools/type_tool/fonts.rs'
$cloudState = @'
/// VRAVIO: the cloud families downloaded this session (their files installed).
static DOWNLOADED: Mutex<Vec<String>> = Mutex::new(Vec::new());

fn remember_downloaded(families: &[String]) {
    let mut downloaded = DOWNLOADED.lock().unwrap_or_else(PoisonError::into_inner);
    for f in families {
        if !downloaded.contains(f) {
            downloaded.push(f.clone());
        }
    }
}

/// Whether `family` is a cloud catalog family (`Some`), and then whether its files were downloaded.
/// `None` for the bundled and installed fonts.
pub fn cloud_state(family: &str) -> Option<bool> {
    let listed = CLASSES.lock().unwrap_or_else(PoisonError::into_inner).iter().any(|(n, _)| n == family);
    listed.then(|| DOWNLOADED.lock().unwrap_or_else(PoisonError::into_inner).iter().any(|n| n == family))
}

'@
Insert-Before-Once $rasterFonts '#[cfg(test)]' 'pub fn cloud_state' $cloudState
Insert-After-Once $rasterFonts '        let families: Vec<String> = delivered.iter().map(|(f, _)| f.clone()).collect();' 'remember_downloaded(&families);' '        remember_downloaded(&families);'
Insert-After-Once $rasterFilters '    pub hide_classes: bool,' 'pub cloud: bool,' "    /// VRAVIO: only the cloud catalog's fonts (downloaded or not).`n    pub cloud: bool,"
Replace-Exact $rasterFilters '        self.class.is_some() || self.favorites || self.variable || self.similar' '        self.class.is_some() || self.favorites || self.variable || self.similar || self.cloud'
Insert-Before-Once $rasterFilters '    if filters.favorites {' 'if filters.cloud {' "    if filters.cloud {`n        rows.retain(|(f, _)| super::served_fonts::cloud_state(f).is_some());`n    }"
$cloudButton = @'
    // VRAVIO: the cloud catalog's fonts alone, downloaded (a check) or not (a cloud).
    if crate::icons::button(ui, "cloud", 22.0, filters.cloud, tl!("Show Cloud Fonts")).clicked() {
        filters.cloud = !filters.cloud;
    }
'@
Insert-Before-Once $rasterFilters '    *filters != before' 'tl!("Show Cloud Fonts")' $cloudButton.TrimEnd("`r", "`n")
$badgeOld = @'
                        // The format badge (O, TT, VAR) just left of the sample.
                        if let Some(format) = format {
                            let center = egui::pos2(response.rect.right() - 8.0 - slot - FONT_BADGE_WIDTH / 2.0, response.rect.center().y);
                            let t = crate::theme::Tokens::get(ui.ctx());
                            ui.painter().text(center, egui::Align2::CENTER_CENTER, format.badge(), egui::FontId::proportional(10.0), t.text_dim);
                            let tip = egui::Rect::from_center_size(center, egui::vec2(FONT_BADGE_WIDTH, 14.0));
                            ui.interact(tip, ui.scope_id().with(("font-format", f, recent_row)), egui::Sense::hover())
                                .on_hover_text(crate::font_filters::format_tip(format));
                        }
'@
$badgeNew = @'
                        // VRAVIO: an icon just left of the sample instead of the format badge (O, TT,
                        // VAR): a cloud for a cloud font not downloaded yet, a check once it is, the
                        // variable-font mark for an installed variable font; none for other fonts.
                        let badge = match (visible.then(|| crate::text::served_fonts::cloud_state(f)).flatten(), format) {
                            (Some(false), _) => Some(("cloud", tl!("Cloud font: downloads when you pick it"))),
                            (Some(true), _) => Some(("check", tl!("Cloud font, downloaded"))),
                            (None, Some(photocraft_text::FontFormat::Variable)) => Some(("font-variable", tl!("Variable font: its weight can be set freely"))),
                            _ => None,
                        };
                        if let Some((icon, tip_text)) = badge {
                            let center = egui::pos2(response.rect.right() - 8.0 - slot - FONT_BADGE_WIDTH / 2.0, response.rect.center().y);
                            let t = crate::theme::Tokens::get(ui.ctx());
                            let tip = egui::Rect::from_center_size(center, egui::vec2(FONT_BADGE_WIDTH, 14.0));
                            crate::icons::paint(ui, tip, icon, 13.0, t.text_dim);
                            ui.interact(tip, ui.scope_id().with(("font-format", f, recent_row)), egui::Sense::hover()).on_hover_text(tip_text);
                        }
'@
Replace-Exact $rasterMenu $badgeOld.TrimEnd("`r", "`n") $badgeNew.TrimEnd("`r", "`n")
$orderOld = @'
    for f in photocraft_text::served::families() {
        if !v.contains(&f) {
            v.push(f);
        }
    }
    v.sort_by_key(|s| s.to_lowercase());
'@
$orderNew = @'
    // VRAVIO: the installed families (bundled, system, downloaded) first, then the cloud catalog's.
    v.sort_by_key(|s| s.to_lowercase());
    let installed = v.len();
    for f in photocraft_text::served::families() {
        if !v.contains(&f) {
            v.push(f);
        }
    }
    if let Some(cloud) = v.get_mut(installed..) {
        cloud.sort_by_key(|s| s.to_lowercase());
    }
'@
Replace-Exact $rasterMenu $orderOld.TrimEnd("`r", "`n") $orderNew.TrimEnd("`r", "`n")
# Russian labels for the cloud font strings.
$rasterRu = Join-Path $root 'upstream/photocraft/crates/ui-egui/src/i18n/ru.tsv'
$ruText = [IO.File]::ReadAllText($rasterRu)
$ruAdd = ''
foreach ($pair in @(
  @('Show Cloud Fonts', 'Показать шрифты из облака'),
  @('Cloud font: downloads when you pick it', 'Шрифт из облака: скачается при выборе'),
  @('Cloud font, downloaded', 'Шрифт из облака, скачан'),
  @('Variable font: its weight can be set freely', 'Вариативный шрифт: толщину можно менять плавно')
)) {
  if (-not $ruText.Contains("`t$($pair[0])`t")) { $ruAdd += "`t$($pair[0])`t$($pair[1])`n" }
}
if ($ruAdd -ne '') { [IO.File]::WriteAllText($rasterRu, $ruText.TrimEnd("`r", "`n") + "`n" + $ruAdd, [Text.UTF8Encoding]::new($false)) }
# Style rows of an expanded family read from the left, as the family rows do (an empty right part
# keeps the label at the start instead of centred).
Replace-Exact $rasterMenu 'egui::Button::selectable(false, style_label(style)).truncate().stroke(egui::Stroke::NONE),' 'egui::Button::selectable(false, style_label(style)).right_text("").truncate().stroke(egui::Stroke::NONE),'
# Vector font menu: a Cloud chip beside the favourites chip, and each cloud family's mark before
# its star (a cloud until it is downloaded, a check after).
$vectorMenu = 'upstream/vectorcraft/crates/ui-egui/src/font_menu.rs'
Insert-After-Once $vectorMenu '    favorites_only: bool,' 'cloud_only: bool,' "    /// VRAVIO: only the cloud catalog's families.`n    cloud_only: bool,"
Replace-Exact $vectorMenu 'type RowsKey = (String, usize, Option<FontClass>, bool, bool, bool, Vec<String>, Vec<String>, Vec<String>, u64);' 'type RowsKey = (String, usize, Option<FontClass>, bool, bool, bool, Vec<String>, Vec<String>, Vec<String>, u64, bool);'
Replace-Exact $vectorMenu "        db.generation(),`n    );" "        db.generation(),`n        st.cloud_only,`n    );"
$cloudChip = @'
        if ui.selectable_label(st.cloud_only, egui::RichText::new(tl!("Cloud")).size(11.0)).on_hover_text(tl!("Show Cloud Fonts")).clicked() {
            st.cloud_only = !st.cloud_only;
            refilter = true;
        }
'@
Insert-Before-Once $vectorMenu '        if ui.selectable_label(st.class.is_none(), egui::RichText::new(tl!("Any Kind")).size(11.0)).clicked() {' 'tl!("Show Cloud Fonts")' $cloudChip.TrimEnd("`r", "`n")
$wantedOld = @'
    if st.favorites_only && !look.favorites.iter().any(|x| x.eq_ignore_ascii_case(f)) {
        return false;
    }
'@
$wantedNew = @'
    if st.favorites_only && !look.favorites.iter().any(|x| x.eq_ignore_ascii_case(f)) {
        return false;
    }
    if st.cloud_only && !vectorcraft_text::cloud::contains(f) {
        return false;
    }
'@
Replace-Exact $vectorMenu $wantedOld.TrimEnd("`r", "`n") $wantedNew.TrimEnd("`r", "`n")
$markOld = '        let sample_rect = egui::Rect::from_min_max(rect.min + vec2(name_w, 2.0), rect.max - vec2(STAR + 2.0, 2.0));'
$markNew = @'
        // VRAVIO: a cloud family's mark just before the star (a cloud until it is downloaded, a check
        // after); the sample makes room for it.
        let cloud = if let Row::Family(f) = row { vectorcraft_text::cloud::download_state(f) } else { None };
        let mark_w = if cloud.is_some() { 18.0 } else { 0.0 };
        if let Some(downloaded) = cloud {
            let mark = egui::Rect::from_center_size(egui::pos2(star.min.x - 10.0, rect.center().y), vec2(14.0, 14.0));
            if downloaded {
                let a = mark.left_center() + vec2(2.0, 0.0);
                let b = mark.center_bottom() + vec2(-1.0, -3.0);
                let c = mark.right_top() + vec2(-2.0, 3.0);
                p.line_segment([a, b], egui::Stroke::new(1.5, t.text_dim));
                p.line_segment([b, c], egui::Stroke::new(1.5, t.text_dim));
            } else {
                crate::icons::paint(ui, "cloud", mark, t.text_dim);
            }
            let tip = if downloaded { tl!("Cloud font, downloaded") } else { tl!("Cloud font: downloads when you pick it") };
            ui.interact(mark, ui.scope_id().with(("vravio-cloud-mark", i)), Sense::hover()).on_hover_text(tip);
        }
        let sample_rect = egui::Rect::from_min_max(rect.min + vec2(name_w, 2.0), rect.max - vec2(STAR + 2.0 + mark_w, 2.0));
'@
Replace-Exact $vectorMenu $markOld $markNew.TrimEnd("`r", "`n")
$vectorRu = Join-Path $root 'upstream/vectorcraft/crates/ui-egui/src/i18n/ru.tsv'
$vruText = [IO.File]::ReadAllText($vectorRu)
$vruAdd = ''
foreach ($pair in @(
  @('Cloud', 'Облако'),
  @('Show Cloud Fonts', 'Показать шрифты из облака'),
  @('Cloud font: downloads when you pick it', 'Шрифт из облака: скачается при выборе'),
  @('Cloud font, downloaded', 'Шрифт из облака, скачан')
)) {
  if (-not $vruText.Contains("`t$($pair[0])`t")) { $vruAdd += "`t$($pair[0])`t$($pair[1])`n" }
}
if ($vruAdd -ne '') { [IO.File]::WriteAllText($vectorRu, $vruText.TrimEnd("`r", "`n") + "`n" + $vruAdd, [Text.UTF8Encoding]::new($false)) }
# Vector font menu: hovering a cloud family not downloaded yet ends the canvas preview instead of
# previewing it (which would download the whole family); picking it downloads it.
Insert-Before-Once $vectorMenu '        Some(pick) if st.previewed.as_ref() != Some(&pick) => {' 'cloud::pending(&f) =>' '        Some((f, _)) if vectorcraft_text::cloud::pending(&f) => st.previewed.take().map(|_| FontPick::EndPreview),'
# Raster: light previews of cloud families. The font menu's samples, its preview line and the
# canvas preview of a hovered cloud family use a script subset of it (Fontsource, 15-40 KB, latin or
# cyrillic), registered under a hidden alias; the whole family downloads only once it is picked.
$rasterTextFonts = 'upstream/photocraft/crates/text/src/fonts.rs'
$registerAs = @'

    /// VRAVIO: registers font data (TTF/OTF, or a WOFF 1.0 file) under `family`, whatever its own
    /// name: the font menu's light previews of cloud families, kept apart from the families
    /// themselves (a leading '.' keeps the alias out of the font lists). Returns the families added.
    pub fn register_font_data_as(&mut self, bytes: Vec<u8>, family: &str) -> Vec<String> {
        let bytes = if bytes.starts_with(b"wOFF") {
            let Some(sfnt) = woff_to_sfnt(&bytes) else { return Vec::new() };
            sfnt
        } else {
            bytes
        };
        self.register_blob(Blob::new(Arc::new(bytes)), Some(family))
    }
'@
Insert-After-Once $rasterTextFonts "    pub fn register_font_data(&mut self, bytes: Vec<u8>) -> Vec<String> {`n        self.register_blob(Blob::new(Arc::new(bytes)), None)`n    }" 'pub fn register_font_data_as' $registerAs.TrimEnd("`r", "`n")
$woff = @'
/// VRAVIO: a WOFF 1.0 file's font data (TTF/OTF): its tables, each zlib-compressed or stored,
/// behind a 44-byte header. `None` when `d` isn't a well-formed WOFF file.
fn woff_to_sfnt(d: &[u8]) -> Option<Vec<u8>> {
    const MAX_OUT: usize = 64 << 20;
    let be32 = |o: usize| -> Option<u32> { Some(u32::from_be_bytes(d.get(o..o.checked_add(4)?)?.try_into().ok()?)) };
    let be16 = |o: usize| -> Option<u16> { Some(u16::from_be_bytes(d.get(o..o.checked_add(2)?)?.try_into().ok()?)) };
    if d.get(..4)? != b"wOFF" {
        return None;
    }
    let flavor = be32(4)?;
    let n = usize::from(be16(12)?);
    if n == 0 || n > 256 {
        return None;
    }
    let mut tables = Vec::with_capacity(n);
    let mut total = 12 + 16 * n;
    for i in 0..n {
        let e = 44 + 20 * i;
        let tag = d.get(e..e + 4)?;
        let (off, comp, orig, sum) = (be32(e + 4)? as usize, be32(e + 8)? as usize, be32(e + 12)? as usize, be32(e + 16)?);
        let raw = d.get(off..off.checked_add(comp)?)?;
        let data = if comp < orig {
            let mut out = Vec::with_capacity(orig.min(MAX_OUT));
            let mut reader = std::io::Read::take(flate2::read::ZlibDecoder::new(raw), orig as u64 + 1);
            std::io::Read::read_to_end(&mut reader, &mut out).ok()?;
            if out.len() != orig {
                return None;
            }
            out
        } else if comp == orig {
            raw.to_vec()
        } else {
            return None;
        };
        total = total.checked_add(data.len().checked_add(3)? & !3)?;
        if total > MAX_OUT {
            return None;
        }
        tables.push((tag.to_vec(), sum, data));
    }
    let mut selector = 0u16;
    while (1usize << (selector + 1)) <= n {
        selector += 1;
    }
    let range = 16u16 << selector;
    let count = u16::try_from(n).ok()?;
    let mut out = Vec::with_capacity(total);
    out.extend_from_slice(&flavor.to_be_bytes());
    out.extend_from_slice(&count.to_be_bytes());
    out.extend_from_slice(&range.to_be_bytes());
    out.extend_from_slice(&selector.to_be_bytes());
    out.extend_from_slice(&(count * 16 - range).to_be_bytes());
    let mut offset = 12 + 16 * n;
    for (tag, sum, data) in &tables {
        out.extend_from_slice(tag);
        out.extend_from_slice(&sum.to_be_bytes());
        out.extend_from_slice(&u32::try_from(offset).ok()?.to_be_bytes());
        out.extend_from_slice(&u32::try_from(data.len()).ok()?.to_be_bytes());
        offset += (data.len() + 3) & !3;
    }
    for (_, _, data) in &tables {
        out.extend_from_slice(data);
        out.resize((out.len() + 3) & !3, 0);
    }
    Some(out)
}

'@
Insert-Before-Once $rasterTextFonts 'pub fn is_hidden_family(name: &str) -> bool {' 'fn woff_to_sfnt(' $woff
$previews = @'
/// VRAVIO: light previews of cloud families (the font menu's samples, its preview line and the
/// canvas preview of a hovered family): a script subset of the family (latin or cyrillic, from
/// Fontsource), registered under a hidden alias, so the whole family downloads only once picked.
struct Previews {
    /// Each catalog family's Fontsource id (the manifest's 10th field).
    ids: Vec<(String, String)>,
    /// Subsets asked for, `(family, subset)`; `wanted` are those the web shell hasn't taken yet.
    asked: Vec<(String, &'static str)>,
    wanted: Vec<(String, &'static str)>,
    /// Subsets that arrived, waiting to be registered.
    arrived: Vec<(String, &'static str, Vec<u8>)>,
    /// Subsets registered.
    loaded: Vec<(String, &'static str)>,
}

static PREVIEWS: Mutex<Previews> = Mutex::new(Previews { ids: Vec::new(), asked: Vec::new(), wanted: Vec::new(), arrived: Vec::new(), loaded: Vec::new() });

/// Reads the Fontsource ids of a served font manifest (its 10th field).
pub fn add_previews(manifest: &str) {
    let mut p = PREVIEWS.lock().unwrap_or_else(PoisonError::into_inner);
    for line in manifest.lines() {
        let f: Vec<&str> = line.split(" | ").map(str::trim).collect();
        let (Some(family), Some(id)) = (f.first(), f.get(9)) else { continue };
        let valid = !id.is_empty() && id.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-');
        if family.starts_with('#') || !valid || p.ids.iter().any(|(n, _)| n == family) {
            continue;
        }
        p.ids.push((family.to_string(), id.to_string()));
    }
}

fn preview_alias(family: &str, subset: &str) -> String {
    format!(".VRAVIO Preview {subset} {family}")
}

/// The family to draw `text` set in `family` with: the family itself unless it is a cloud family
/// not downloaded yet, else its light preview for the text's script once that arrived (asked for
/// here; until then nothing is drawn).
pub fn shown_family(family: &str, text: &str) -> String {
    if cloud_state(family) != Some(false) {
        return family.to_string();
    }
    let subset = if text.chars().any(|c| ('\u{0400}'..='\u{04FF}').contains(&c)) { "cyrillic" } else { "latin" };
    let mut p = PREVIEWS.lock().unwrap_or_else(PoisonError::into_inner);
    let key = (family.to_string(), subset);
    if p.loaded.contains(&key) {
        return preview_alias(family, subset);
    }
    if !p.asked.contains(&key) && p.ids.iter().any(|(n, _)| n == family) {
        p.asked.push(key.clone());
        p.wanted.push(key);
    }
    family.to_string()
}

/// The light previews asked for since the last call, `(family, subset, path)`; the path is read by
/// the web shell's fetch (`fspreview/<id>/<subset>`).
pub fn take_preview_requests() -> Vec<(String, &'static str, String)> {
    let mut p = PREVIEWS.lock().unwrap_or_else(PoisonError::into_inner);
    let wanted = std::mem::take(&mut p.wanted);
    wanted
        .into_iter()
        .filter_map(|(family, subset)| {
            let id = p.ids.iter().find(|(n, _)| *n == family)?.1.clone();
            Some((family, subset, format!("fspreview/{id}/{subset}")))
        })
        .collect()
}

/// A light preview the web shell fetched.
pub fn preview_arrived(family: String, subset: &'static str, bytes: Vec<u8>) {
    PREVIEWS.lock().unwrap_or_else(PoisonError::into_inner).arrived.push((family, subset, bytes));
}

/// Registers the light previews that arrived. True when any did: the menu draws them next.
pub fn install_previews() -> bool {
    let arrived = std::mem::take(&mut PREVIEWS.lock().unwrap_or_else(PoisonError::into_inner).arrived);
    if arrived.is_empty() {
        return false;
    }
    let mut done = Vec::new();
    {
        let mut eng = photocraft_text::shared().lock().unwrap_or_else(PoisonError::into_inner);
        for (family, subset, bytes) in arrived {
            if eng.fonts.register_font_data_as(bytes, &preview_alias(&family, subset)).is_empty() {
                log::warn!("the {subset} preview of {family:?} is not a readable font");
            } else {
                done.push((family, subset));
            }
        }
    }
    PREVIEWS.lock().unwrap_or_else(PoisonError::into_inner).loaded.extend(done);
    true
}

'@
Insert-Before-Once $rasterFonts '#[cfg(test)]' 'pub fn shown_family' $previews
Insert-Before-Once $rasterWeb '        served_fonts::add_fonts(&fonts);' 'served_fonts::add_previews(&text);' '        served_fonts::add_previews(&text);'
$previewFetch = @'
        // VRAVIO: the light previews of cloud families the font menu asked for.
        for (family, subset, path) in served_fonts::take_preview_requests() {
            let ctx = ctx.clone();
            wasm_bindgen_futures::spawn_local(async move {
                match fetch_bytes(&path, None).await {
                    Ok(bytes) => {
                        served_fonts::preview_arrived(family, subset, bytes);
                        ctx.request_repaint();
                    }
                    Err(e) => log::warn!("couldn't fetch the preview of {family}: {e}"),
                }
            });
        }
        // Draw a few more frames once previews or fonts arrive: the canvas preview of a hovered
        // family shows them a frame or two after the menu does.
        static MORE_FRAMES: std::sync::atomic::AtomicU8 = std::sync::atomic::AtomicU8::new(0);
        if served_fonts::install_previews() || !arrived.is_empty() {
            MORE_FRAMES.store(8, std::sync::atomic::Ordering::Relaxed);
        }
        if MORE_FRAMES.load(std::sync::atomic::Ordering::Relaxed) > 0 {
            MORE_FRAMES.fetch_sub(1, std::sync::atomic::Ordering::Relaxed);
            ctx.request_repaint_after(std::time::Duration::from_millis(80));
        }
'@
Insert-Before-Once $rasterWeb '        let installed = !arrived.is_empty();' 'served_fonts::take_preview_requests()' $previewFetch.TrimEnd("`r", "`n")
$rasterPreview = 'upstream/photocraft/crates/ui-egui/src/text/font_preview.rs'
Insert-After-Once $rasterPreview 'pub(crate) fn paint(ui: &egui::Ui, family: &str, row: Rect, size: f32) {' 'shown_family(family, SAMPLE)' "    // VRAVIO: a cloud family not downloaded yet is drawn from its light preview.`n    let family = &super::served_fonts::shown_family(family, SAMPLE);"
Insert-After-Once $rasterPreview 'pub(crate) fn paint_text(ui: &egui::Ui, family: &str, text: &str, rect: Rect, size: f32) {' 'shown_family(family, text)' "    // VRAVIO: a cloud family not downloaded yet is drawn from its light preview.`n    let family = &super::served_fonts::shown_family(family, text);"
$typePreview = 'upstream/photocraft/crates/ui-egui/src/tools/type_font_preview.rs'
$setOld = '    photocraft_text::served::request(&family);'
$setNew = @'
    // VRAVIO: a cloud family not downloaded yet is previewed from its light preview
    // (`display_doc`); its files download when it is picked.
    if crate::text::served_fonts::cloud_state(&family) != Some(false) {
        photocraft_text::served::request(&family);
    }
'@
Replace-Exact $typePreview $setOld $setNew.TrimEnd("`r", "`n")
$displayOld = @'
    if !photocraft_text::shared().lock().unwrap_or_else(|e| e.into_inner()).fonts.has_family(family) {
        return None;
    }
'@
$displayNew = @'
    // VRAVIO: a cloud family not downloaded yet is previewed from its light preview for the layer's script.
    let layer_text = st.doc.layer(p.layer).and_then(|l| if let LayerContent::Text(t) = &l.content { Some(t.text.clone()) } else { None }).unwrap_or_default();
    let shown_family = crate::text::served_fonts::shown_family(family, &layer_text);
    let family = shown_family.as_str();
    if !photocraft_text::shared().lock().unwrap_or_else(|e| e.into_inner()).fonts.has_family(family) {
        return None;
    }
'@
Replace-Exact $typePreview $displayOld.TrimEnd("`r", "`n") $displayNew.TrimEnd("`r", "`n")
Write-Output 'VRAVIO branding applied to UI sources.'

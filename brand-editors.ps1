$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

foreach ($repo in @('photocraft','vectorcraft','filmcraft','soundcraft')) {
  Copy-Item (Join-Path $root 'src-tauri/icons/128x128.png') (Join-Path $root "upstream/$repo/assets/vravio-icon.png") -Force
}
Copy-Item (Join-Path $root 'assets/wordmark-white.png') (Join-Path $root 'upstream/filmcraft/assets/vravio-wordmark-white.png') -Force
Copy-Item (Join-Path $root 'assets/wordmark-black.png') (Join-Path $root 'upstream/filmcraft/assets/vravio-wordmark-black.png') -Force

function Replace-Exact([string]$relative, [string]$old, [string]$new) {
  $file = Join-Path $root $relative
  $text = [IO.File]::ReadAllText($file).Replace("`r`n", "`n")
  if (-not $text.Contains($old) -and -not $text.Contains($new)) { throw "Branding anchor changed: $relative" }
  if ($new -eq '') {
    $line = [regex]::Escape($old.Trim())
    $next = [regex]::Replace($text, "(?m)^[ \t]*$line[ \t]*\n", '')
  } else {
    $next = $text.Replace($old, $new)
  }
  if ($next -ne $text) { [IO.File]::WriteAllText($file, $next, [Text.UTF8Encoding]::new($false)) }
}

function Insert-Before-Once([string]$relative, [string]$anchor, [string]$marker, [string]$snippet) {
  $file = Join-Path $root $relative
  $source = [IO.File]::ReadAllText($file).Replace("`r`n", "`n")
  if ($source.Contains($marker)) { return }
  if (-not $source.Contains($anchor)) { throw "Missing insertion anchor: $relative" }
  [IO.File]::WriteAllText($file, $source.Replace($anchor, "$snippet`n$anchor"), [Text.UTF8Encoding]::new($false))
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
    if id == "filter.vravio.photoRestore" {
        let doc = app.session.active().ok_or("no document is open".to_string());
        return Some(doc.and_then(|doc| {
            let export = app.services.export.as_ref().ok_or("PNG export is unavailable")?;
            let (bytes, _) = export(&doc.doc, "vravio-restoration-input.png", &crate::ExportSettings::default())?;
            let write = app.services.write.as_ref().ok_or("browser bridge is unavailable")?;
            write("vravio-restoration-input.png", &bytes)?;
            Ok(json!({"sent": true}))
        }));
    }
'@
Insert-Before-Once 'upstream/photocraft/crates/ui-egui/src/menus/invoke.rs' '    if id == "help.checkForUpdates" {' 'if id == "filter.vravio.photoRestore"' $restoreCommand
$restoreBridge = @'
fn send_restore_input(bytes: &[u8]) -> Result<(), String> {
    let js = |e: wasm_bindgen::JsValue| format!("{e:?}");
    let window = web_sys::window().ok_or("no window")?;
    let parent = js_sys::Reflect::get(window.as_ref(), &"parent".into()).map_err(js)?;
    let post = js_sys::Reflect::get(&parent, &"postMessage".into()).map_err(js)?.dyn_into::<js_sys::Function>().map_err(|_| "no postMessage")?;
    let message = js_sys::Object::new();
    js_sys::Reflect::set(&message, &"type".into(), &"vravio-restorer-open".into()).map_err(js)?;
    js_sys::Reflect::set(&message, &"bytes".into(), &js_sys::Uint8Array::from(bytes).into()).map_err(js)?;
    post.call2(&parent, &message, &window.location().origin().map_err(js)?.into()).map_err(js)?;
    Ok(())
}

fn listen_restore_result(inbox: Inbox, ctx: egui::Context) {
    use wasm_bindgen::closure::Closure;
    let Some(window) = web_sys::window() else { return };
    let cb = Closure::<dyn FnMut(web_sys::MessageEvent)>::new(move |event| {
        let Some(window) = web_sys::window() else { return };
        if window.location().origin().ok().as_deref() != Some(event.origin().as_str()) { return }
        let data = event.data();
        if js_sys::Reflect::get(&data, &"type".into()).ok().and_then(|v| v.as_string()).as_deref() != Some("vravio-restorer-result") { return }
        let bytes = js_sys::Uint8Array::new(&js_sys::Reflect::get(&data, &"bytes".into()).unwrap_or_default()).to_vec();
        let name = js_sys::Reflect::get(&data, &"name".into()).ok().and_then(|v| v.as_string()).unwrap_or_else(|| "restored.png".into());
        inbox.lock().unwrap_or_else(PoisonError::into_inner).push((name, bytes));
        ctx.request_repaint();
    });
    if window.add_event_listener_with_callback("message", cb.as_ref().unchecked_ref()).is_ok() { cb.forget(); }
}
'@
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '/// Trigger a browser download of `bytes` named after the last component of `path`.' 'fn send_restore_input(bytes: &[u8])' $restoreBridge
Replace-Exact 'upstream/photocraft/apps/photocraft-web/Cargo.toml' '"BeforeUnloadEvent", "AbortController"' '"BeforeUnloadEvent", "MessageEvent", "AbortController"'
Insert-Before-Once 'upstream/photocraft/apps/photocraft-web/src/web.rs' '                    let place_inbox: Inbox = Arc::default();' 'listen_restore_result(inbox.clone(), cc.egui_ctx.clone());' '                    listen_restore_result(inbox.clone(), cc.egui_ctx.clone());'
Replace-Exact 'upstream/photocraft/apps/photocraft-web/src/web.rs' "fn download(path: &str, bytes: &[u8]) -> Result<(), String> {`n" "fn download(path: &str, bytes: &[u8]) -> Result<(), String> {`n    if path.ends_with(`"vravio-restoration-input.png`") { return send_restore_input(bytes); }`n"
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(0x2f, 0x6b, 0xdf)' 'accent: Color32::from_rgb(0xff, 0x00, 0x00)'
Replace-Exact 'upstream/filmcraft/crates/ui-egui/src/theme.rs' 'accent_hover: Color32::from_rgb(0x3f, 0x7c, 0xe8)' 'accent_hover: Color32::from_rgb(0xff, 0x44, 0x44)'
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
Write-Output 'VRAVIO branding applied to UI sources.'

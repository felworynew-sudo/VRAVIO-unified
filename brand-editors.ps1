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

# Only UI color tokens are adjusted. Engines and document formats remain pinned upstream.
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(139, 124, 246)' 'accent: Color32::from_rgb(161, 0, 255)'
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' "    #[default]`n    ProMedium," "    ProMedium,"
Replace-Exact 'upstream/photocraft/crates/ui-egui/src/theme.rs' "    Studio,`n    StudioLight," "    #[default]`n    Studio,`n    StudioLight,"
Replace-Exact 'upstream/photocraft/crates/engine/src/prefs.rs' 'default ProMedium);' 'default Studio);'
Replace-Exact 'upstream/photocraft/crates/engine/src/prefs.rs' 'theme: Theme::ProMedium,' 'theme: Theme::Studio,'
Replace-Exact 'upstream/photocraft/crates/engine/src/prefs.rs' 'dark_theme: DarkTheme::ProMedium,' 'dark_theme: DarkTheme::Studio,'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' "    #[default]`n    Coral,`n    Blue," "    Coral,`n    #[default]`n    Blue,"
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' '(0x5b96ff, 0x2f74f0)' '(0x0068ff, 0x005ce6)'
Replace-Exact 'upstream/vectorcraft/crates/ui-egui/src/theme.rs' '(0x2563eb, 0x1f5ad6)' '(0x0068ff, 0x005ce6)'
Replace-Exact 'upstream/vectorcraft/crates/engine/src/prefs.rs' 'ui_accent: s("coral"),' 'ui_accent: s("blue"),'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(64, 132, 196)' 'accent: Color32::from_rgb(255, 182, 0)'
Replace-Exact 'upstream/soundcraft/crates/ui-egui/src/theme.rs' 'accent: Color32::from_rgb(62, 116, 180)' 'accent: Color32::from_rgb(255, 182, 0)'
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

# Builds one environment as its own native app (the upstream desktop editor with the VRAVIO
# patches), with that environment's icon, and packs it for the current OS:
#   Windows  dist/native/VRAVIO-<Name>-windows-x64.zip       (portable folder)
#   macOS    dist/native/VRAVIO-<Name>-macos-<arch>.zip      ("VRAVIO <Name>.app", ad-hoc signed)
#   Linux    dist/native/VRAVIO-<Name>-linux-x86_64.tar.gz   (bin/, share/applications, icons)
# The VRAVIO menu finds these by the `VRAVIO-<Name>-<platform>` prefix in the latest release.
#
#   ./build-native.ps1 -Kind raster -Icons <dir from scripts/native-icons.py>
param(
  [Parameter(Mandatory = $true)][ValidateSet('raster', 'vector', 'audio', 'video')][string]$Kind,
  [Parameter(Mandatory = $true)][string]$Icons
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$map = @{
  raster = @{ repo = 'photocraft'; name = 'Raster' }
  vector = @{ repo = 'vectorcraft'; name = 'Vector' }
  audio  = @{ repo = 'soundcraft'; name = 'Audio' }
  video  = @{ repo = 'filmcraft'; name = 'Video' }
}
$repoName = $map[$Kind].repo
$name = $map[$Kind].name
$title = "VRAVIO $name"
$slug = "VRAVIO-$name"
$repo = Join-Path $root "upstream/$repoName"
$out = Join-Path $root 'dist/native'
New-Item -ItemType Directory -Force $out | Out-Null

& (Join-Path $root 'brand-editors.ps1')
# The environment's icon replaces the upstream one under the same file names.
Copy-Item (Join-Path $Icons '*') (Join-Path $repo 'assets/app-icon') -Recurse -Force

$version = ([regex]::Match((Get-Content (Join-Path $repo 'Cargo.toml') -Raw), '(?ms)^\[workspace\.package\].*?^version\s*=\s*"([^"]+)"')).Groups[1].Value
if (-not $version) { $version = '0.0.0' }
Push-Location $repo
try {
  cargo build --release -p $repoName
  if ($LASTEXITCODE -ne 0) { throw "$Kind native build failed" }
} finally { Pop-Location }
$target = if ($env:CARGO_TARGET_DIR) { $env:CARGO_TARGET_DIR } else { Join-Path $repo 'target' }
$docs = @('LICENSE-MIT', 'LICENSE-APACHE', 'NOTICE', 'ATTRIBUTION.md') | ForEach-Object { Join-Path $repo $_ } | Where-Object { Test-Path $_ }
$stage = Join-Path $root "dist/native-stage/$slug"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force $stage | Out-Null

if ($IsWindows) {
  $dir = Join-Path $stage $title
  New-Item -ItemType Directory -Force $dir | Out-Null
  Copy-Item (Join-Path $target "release/$repoName.exe") (Join-Path $dir "$title.exe")
  Copy-Item $docs $dir
  $zip = Join-Path $out "$slug-windows-x64.zip"
  if (Test-Path $zip) { Remove-Item $zip }
  Compress-Archive -Path $dir -DestinationPath $zip
} elseif ($IsMacOS) {
  $arch = if ((uname -m) -eq 'arm64') { 'arm64' } else { 'x86_64' }
  $app = Join-Path $stage "$title.app"
  New-Item -ItemType Directory -Force (Join-Path $app 'Contents/MacOS'), (Join-Path $app 'Contents/Resources') | Out-Null
  Copy-Item (Join-Path $target "release/$repoName") (Join-Path $app "Contents/MacOS/$repoName")
  Copy-Item (Join-Path $Icons "$repoName.icns") (Join-Path $app 'Contents/Resources/app.icns')
  Copy-Item $docs (Join-Path $app 'Contents/Resources')
  @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$title</string>
  <key>CFBundleDisplayName</key><string>$title</string>
  <key>CFBundleIdentifier</key><string>com.vravio.$Kind</string>
  <key>CFBundleExecutable</key><string>$repoName</string>
  <key>CFBundleIconFile</key><string>app.icns</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
"@ | Set-Content (Join-Path $app 'Contents/Info.plist') -Encoding utf8NoBOM
  # Apple Silicon refuses unsigned code: an ad-hoc signature lets it start (Gatekeeper still asks once).
  codesign --force --deep --sign - $app
  if ($LASTEXITCODE -ne 0) { throw 'codesign failed' }
  $zip = Join-Path $out "$slug-macos-$arch.zip"
  if (Test-Path $zip) { Remove-Item $zip }
  Push-Location $stage
  try { ditto -c -k --keepParent "$title.app" $zip; if ($LASTEXITCODE -ne 0) { throw 'ditto failed' } } finally { Pop-Location }
} else {
  $lower = $slug.ToLower()
  $dir = Join-Path $stage $lower
  New-Item -ItemType Directory -Force (Join-Path $dir 'bin'), (Join-Path $dir 'share/applications'), (Join-Path $dir 'share/doc') | Out-Null
  Copy-Item (Join-Path $target "release/$repoName") (Join-Path $dir "bin/$lower")
  chmod +x (Join-Path $dir "bin/$lower")
  Copy-Item (Join-Path $Icons 'hicolor') (Join-Path $dir 'share/icons/hicolor') -Recurse
  Get-ChildItem (Join-Path $dir 'share/icons/hicolor') -Recurse -Filter '*.png' | ForEach-Object { Rename-Item $_.FullName "com.vravio.$Kind.png" }
  Copy-Item $docs (Join-Path $dir 'share/doc')
  @"
[Desktop Entry]
Type=Application
Name=$title
Exec=$lower %F
Icon=com.vravio.$Kind
Categories=Graphics;AudioVideo;
Terminal=false
"@ | Set-Content (Join-Path $dir "share/applications/com.vravio.$Kind.desktop") -Encoding utf8NoBOM
  $tgz = Join-Path $out "$slug-linux-x86_64.tar.gz"
  tar -czf $tgz -C $stage $lower
  if ($LASTEXITCODE -ne 0) { throw 'tar failed' }
}
Get-ChildItem $out | Where-Object Name -like "$slug-*" | ForEach-Object { "$($_.Name)  $([math]::Round($_.Length / 1MB, 1)) MB" }

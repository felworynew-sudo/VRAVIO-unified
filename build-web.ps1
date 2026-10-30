param([switch]$ShellOnly)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $dist, (Join-Path $dist 'src'), (Join-Path $dist 'assets'), (Join-Path $dist 'editors') | Out-Null
Copy-Item (Join-Path $root 'index.html') $dist -Force
Copy-Item (Join-Path $root 'src\*') (Join-Path $dist 'src') -Force
Copy-Item (Join-Path $root 'assets\logo.svg') (Join-Path $dist 'assets') -Force
foreach ($kind in @('raster','vector','audio','video')) { Copy-Item (Join-Path $root "assets\$kind.svg") (Join-Path $dist 'assets') -Force }
if ($ShellOnly) { Write-Output "Shell built: $dist"; return }
if (-not (Get-Command trunk -ErrorAction SilentlyContinue)) { throw 'Install Trunk: cargo install trunk --locked' }
& (Join-Path $root 'brand-editors.ps1')
$apps = @(
  @{ kind='raster'; repo='photocraft'; app='photocraft-web' },
  @{ kind='vector'; repo='vectorcraft'; app='vectorcraft-web' },
  @{ kind='audio'; repo='soundcraft'; app='soundcraft-web' }
)
foreach ($item in $apps) {
  $repo = Join-Path $root "upstream\$($item.repo)"
  if (-not (Test-Path (Join-Path $repo 'Cargo.toml'))) { throw "Missing source: $repo. Run git submodule update --init --recursive." }
  Push-Location (Join-Path $repo "apps\$($item.app)")
  try { trunk build --release; if ($LASTEXITCODE -ne 0) { throw "Build failed: $($item.repo)" } }
  finally { Pop-Location }
  $source = Join-Path $repo 'dist\web'
  if (-not (Test-Path $source)) { throw "Missing web bundle: $source" }
  $target = Join-Path $dist "editors\$($item.kind)"
  New-Item -ItemType Directory -Force $target | Out-Null
  Copy-Item (Join-Path $source '*') $target -Recurse -Force
}
$film = Join-Path $root 'upstream\filmcraft'
if (-not (Test-Path (Join-Path $film 'Cargo.toml'))) { throw "Missing source: $film. Run git submodule update --init --recursive." }
Push-Location $film
try { cargo xtask web; if ($LASTEXITCODE -ne 0) { throw 'Build failed: video' } }
finally { Pop-Location }
$filmSource = Join-Path $film 'target\web\dist'
if (-not (Test-Path $filmSource)) { throw "Missing web bundle: $filmSource" }
$filmTarget = Join-Path $dist 'editors\video'
New-Item -ItemType Directory -Force $filmTarget | Out-Null
Copy-Item (Join-Path $filmSource '*') $filmTarget -Recurse -Force
foreach ($page in (Get-ChildItem (Join-Path $dist 'editors') -Recurse -Filter '*.html' -File)) {
  $html = [IO.File]::ReadAllText($page.FullName)
  foreach ($sourceName in @('PhotoCraft','VectorCraft','FilmCraft','SoundCraft','ArtCraft')) {
    $html = $html.Replace($sourceName, 'VRAVIO')
  }
  [IO.File]::WriteAllText($page.FullName, $html, [Text.UTF8Encoding]::new($false))
}
if (Test-Path (Join-Path $root 'src-tauri\icons\icon.png')) {
  Copy-Item (Join-Path $root 'src-tauri\icons\icon.png') (Join-Path $filmTarget 'favicon.png') -Force
}
Write-Output "VRAVIO web bundle built: $dist"

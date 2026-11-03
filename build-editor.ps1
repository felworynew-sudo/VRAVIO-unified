param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('raster','vector','audio','video')]
  [string]$Kind
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$map = @{
  raster = @{ repo='photocraft'; app='photocraft-web' }
  vector = @{ repo='vectorcraft'; app='vectorcraft-web' }
  audio = @{ repo='soundcraft'; app='soundcraft-web' }
  video = @{ repo='filmcraft'; app='filmcraft-web' }
}
$item = $map[$Kind]
$repo = Join-Path $root "upstream/$($item.repo)"
if (-not (Test-Path (Join-Path $repo 'Cargo.toml'))) { throw "Missing source: $repo" }
& (Join-Path $root 'brand-editors.ps1')
if ($Kind -eq 'video') {
  Push-Location $repo
  try { cargo xtask web; if ($LASTEXITCODE -ne 0) { throw 'Video build failed' } }
  finally { Pop-Location }
  $source = Join-Path $repo 'target/web/dist'
} else {
  if (-not (Get-Command trunk -ErrorAction SilentlyContinue)) { throw 'Missing Trunk' }
  Push-Location (Join-Path $repo "apps/$($item.app)")
  try { trunk build --release; if ($LASTEXITCODE -ne 0) { throw "$Kind build failed" } }
  finally { Pop-Location }
  $source = Join-Path $repo 'dist/web'
}
if (-not (Test-Path $source)) { throw "Missing bundle: $source" }
$target = Join-Path $root "dist/editors/$Kind"
New-Item -ItemType Directory -Force $target | Out-Null
Copy-Item (Join-Path $source '*') $target -Recurse -Force
# Cloud font catalog: the raster and vector editors list these families and fetch one when it is used.
if (@('raster','vector') -contains $Kind) { $fontsDir = Join-Path $target 'fonts'; New-Item -ItemType Directory -Force $fontsDir | Out-Null; Copy-Item (Join-Path $root 'font-catalog/manifest.txt') $fontsDir -Force }
foreach ($page in (Get-ChildItem $target -Recurse -Filter '*.html' -File)) {
  $html = [IO.File]::ReadAllText($page.FullName)
  foreach ($sourceName in @('PhotoCraft','VectorCraft','FilmCraft','SoundCraft','ArtCraft')) {
    $html = $html.Replace($sourceName, 'VRAVIO')
  }
  [IO.File]::WriteAllText($page.FullName, $html, [Text.UTF8Encoding]::new($false))
}
if ($Kind -eq 'video') {
  Copy-Item (Join-Path $root 'src-tauri/icons/icon.png') (Join-Path $target 'favicon.png') -Force
}
if ($Kind -eq 'vector') {
  $icons = Join-Path $target 'icons'
  if (Test-Path $icons) {
    Copy-Item (Join-Path $root 'assets/логотип цветная плашка.svg') (Join-Path $icons 'ai.storyteller.vectorcraft.svg') -Force
    Copy-Item (Join-Path $root 'src-tauri/icons/32x32.png') (Join-Path $icons '32/ai.storyteller.vectorcraft.png') -Force
    Copy-Item (Join-Path $root 'src-tauri/icons/128x128@2x.png') (Join-Path $icons '256/ai.storyteller.vectorcraft.png') -Force
  }
}
Write-Output "Built $Kind editor: $target"

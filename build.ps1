param(
    [switch]$dev,
    [switch]$help
)

if ($help) {
    Write-Host "Usage: .\build.ps1 [-dev] [-help]" -ForegroundColor Green
    Write-Host "-dev   : Deploys the build to the Kingdom Come Deliverance 2 Mods folder for in-game development testing." -ForegroundColor Green
    Write-Host "-help  : Displays this help message." -ForegroundColor Green
    exit 0
}

$srcDir = Resolve-Path ".\src"
$manifestPath = "$srcDir\mod.manifest"
$tempDir = ".\temp_build"
$zipPath = "$srcDir\*.zip"

# Clean up any existing output files and directories
Remove-Item $tempDir -Force -Recurse -ErrorAction Ignore
Remove-Item $zipPath -Force -ErrorAction Ignore

New-Item -ItemType Directory -Path $tempDir | Out-Null

if (-Not (Test-Path $manifestPath)) {
    Write-Host "ERROR: mod.manifest not found in src!" -ForegroundColor Red
    exit 1
}

[xml]$manifest = Get-Content $manifestPath
$modID = $manifest.kcd_mod.info.modid
$modVersion = $manifest.kcd_mod.info.version
$zipPath = ".\$modID-$modVersion.zip"

Copy-Item "$srcDir\*" -Destination $tempDir -Recurse

$dataDir = "$tempDir\Data"
$pakPath = "$dataDir\$modID.pak"

if (-Not (Test-Path $dataDir)) {
    Write-Host "ERROR: Data directory not found in src!" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force
    exit 1
}

Compress-Archive -Path "$dataDir\*" -DestinationPath "$dataDir\temp.zip" -Force
Rename-Item -Path "$dataDir\temp.zip" -NewName "$modID.pak"

Get-ChildItem $dataDir -Exclude "$modID.pak" | Remove-Item -Recurse -Force

Write-Host "Data successfully packed: $pakPath"

Remove-Item "$tempDir\original_shop.xml" -Force -ErrorAction Ignore
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
Write-Host "Mod successfully compressed: $zipPath"

if ($dev) {
    $steamModPath = "C:\Steam\steamapps\common\KingdomComeDeliverance2\Mods\adaptive_hud"
    if (Test-Path $steamModPath) {
        Remove-Item $steamModPath -Recurse -Force -ErrorAction Ignore
    }
    New-Item -ItemType Directory -Path $steamModPath | Out-Null
    Copy-Item "$tempDir\*" -Destination $steamModPath -Recurse
    Write-Host "Mod deployed to Steam mods directory for development: $steamModPath"
}

Remove-Item $tempDir -Recurse -Force

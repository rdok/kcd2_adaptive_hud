param(
    [switch]$dev,
    [switch]$help
)

if ($help) {
    Write-Host "Usage: .\build.ps1 [-dev] [-help]" -ForegroundColor Green
    Write-Host "-dev   : Deploys the build to the Kingdom Come Deliverance 2 Mods folder for in-game development testing." -ForegroundColor Green
    Write-Host "-help  : Displays this help message." -ForegroundColor Green
    exit -1
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
    exit 0
}

[xml]$manifest = Get-Content $manifestPath
$modID = $manifest.kcd_mod.info.modid
$modVersion = $manifest.kcd_mod.info.version
$zipPath = ".\$modID-$modVersion.zip"
$modName = $manifest.kcd_mod.info.name  # Get the name from XML

Copy-Item "$srcDir\*" -Destination $tempDir -Recurse

$dataDir = "$tempDir\Data"
$pakPath = "$dataDir\$modID.pak"

if (-Not (Test-Path $dataDir)) {
    Write-Host "ERROR: Data directory not found in src!" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force
    exit 0
}

Compress-Archive -Path "$dataDir\*" -DestinationPath "$dataDir\temp.zip" -Force
Rename-Item -Path "$dataDir\temp.zip" -NewName "$modID.pak"

Get-ChildItem $dataDir -Exclude "$modID.pak" | Remove-Item -Recurse -Force

Write-Host "Data successfully packed: $pakPath"

Remove-Item "$tempDir\original_shop.xml" -Force -ErrorAction Ignore
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipPath -Force
Write-Host "Mod successfully compressed: $zipPath"

if ($dev) {
    $steamModPath = "C:\Steam\steamapps\common\KingdomComeDeliverance2\Mods\$modName"
    $modOrderPath = "C:\Steam\steamapps\common\KingdomComeDeliverance2\Mods\mod_order.txt"

    if (Test-Path $steamModPath) {
        Remove-Item $steamModPath -Recurse -Force -ErrorAction Ignore
    }
    New-Item -ItemType Directory -Path $steamModPath | Out-Null
    Copy-Item "$tempDir\*" -Destination $steamModPath -Recurse
    Write-Host "Mod deployed to Steam mods directory for development: $steamModPath"

    # Check if mod_order.txt exists and if our mod name is in it
    if (Test-Path $modOrderPath) {
        $modOrderContent = Get-Content $modOrderPath -Raw
        $modOrderContent = ($modOrderContent -split "`r?`n" | ForEach-Object { $_.Trim() }) -join "`n"

        if ($modOrderContent -notmatch [regex]::Escape($modName)) {
            Set-Content -Path $modOrderPath -Value ($modOrderContent + "`n" + $modName).Trim()
            Write-Host "Added $modName to mod_order.txt correctly"
        }
        else {
            Write-Host "$modName is already listed in mod_order.txt"
        }
    }
    else {
        # If mod_order.txt does not exist, create it with our mod name on a new line
        New-Item -Path $modOrderPath -ItemType File
        Set-Content -Path $modOrderPath -Value $modName
        Write-Host "Created mod_order.txt with $modName"
    }
}

Remove-Item $tempDir -Recurse -Force
param(
    [Parameter(Mandatory = $true)][string]$Root,
    [Parameter(Mandatory = $true)][string]$IsoPath,
    [int]$RoundsMax = 3,
    [int]$WaitSecondsPerRound = 720,
    [string]$CaptureDir = 'build\vu1_capture',
    [switch]$ForceCapture
)
$ErrorActionPreference = 'Stop'
$rootFull = (Resolve-Path $Root).Path
$exe = Join-Path $rootFull 'build\port\bin\sotc.exe'
$capDir = Join-Path $rootFull $CaptureDir
$vuo = Join-Path $rootFull 'Port\generated\vu1'
$recomp = Join-Path $rootFull 'build\port\External\PS2Recomp\ps2xTest\vu1_recomp.exe'
$waitSecPerRound = $WaitSecondsPerRound
$genDir = $vuo

if (-not (Test-Path $exe)) { Write-Output "[capture] ERROR: $exe missing"; exit 1 }
if (-not (Test-Path $capDir)) { New-Item -ItemType Directory -Path $capDir | Out-Null }
New-Item -ItemType Directory -Force -Path $genDir | Out-Null

if (-not (Test-Path $recomp)) {
    Write-Output "[capture] building vu1_recomp tool (few minutes, once)..."
    & (Join-Path $rootFull 'configure.bat') -DPS2X_BUILD_TEST=ON | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Output '[capture] ERROR: configure failed'; exit 1 }
    & (Join-Path $rootFull 'build.bat') vu1_recomp | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $recomp)) { Write-Output '[capture] ERROR: vu1_recomp build failed'; exit 1 }
}

if (-not $ForceCapture) {
    $alreadyPresent = (Test-Path (Join-Path $vuo 'vu1_programs.cpp'))
    if ($alreadyPresent) { Write-Output '[capture] programs already generated - nothing to do'; exit 0 }
}

function New-BinCount { @(Get-ChildItem -Path $capDir -Filter 'vu1_*.bin' -ErrorAction SilentlyContinue).Count }

$prevCount = New-BinCount
$round = 0
while ($round -lt $RoundsMax) {
    $round++
    $env:SOTC_HEADLESS = '1'
    $env:PS2X_VU1_CAPTURE = $capDir
    if ($IsoPath) { $env:SOTC_ISO = $IsoPath }
    Write-Output "[capture] round $round starting the game headless (no window, no sound, up to $waitSecPerRound s)..."
    $p = Start-Process -FilePath $exe -WorkingDirectory $rootFull -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds($waitSecPerRound)
    try {
        while (-not $p.HasExited -and (Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 30
            $now = New-BinCount
            $elapsed = [int](((Get-Date) - $p.StartTime).TotalSeconds)
            Write-Output ("[capture] {0} programs so far ({1}s elapsed)" -f $now, $elapsed)
        }
    } finally {
        if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; Wait-Process -Id $p.Id -ErrorAction SilentlyContinue }
    }
    $after = New-BinCount
    if ($after -eq 0) {
        Write-Output '[capture] no VU1 programs captured (game exited early?) - skipping regeneration'
        exit 1
    }
    if ($after -le $prevCount) { Write-Output "[capture] round $round captured nothing new - stopping capture"; break }
    $prevCount = $after
    Write-Output "[capture] round $round captured $after programs total - regenerating..."
    & $recomp $capDir $vuo | ForEach-Object { Write-Output "[capture]   $_" }
    if ($LASTEXITCODE -ne 0) { Write-Output '[capture] ERROR: vu1_recomp failed'; exit 1 }
    Write-Output '[capture] rebuilding the port with the new programs...'
    & (Join-Path $rootFull 'build.bat') | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Output '[capture] ERROR: port rebuild failed'; exit 1 }
}

$final = if (Test-Path (Join-Path $vuo 'vu1_programs.cpp')) { 'done' } else { 'MISSING' }
Write-Output "[capture] finished: programs $final, $prevCount microcode programs captured"
if ($final -ne 'done') { exit 1 }
exit 0

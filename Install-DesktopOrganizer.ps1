# Install-DesktopOrganizer.ps1
# 바탕화면 정리 도구 설치 마법사

$ErrorActionPreference = 'Stop'

# 1. 설치 폴더 결정
$appName = "DesktopOrganizer"
$installDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$appName"

# 2. 설치 폴더 생성
if (-not (Test-Path -LiteralPath $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# 3. 스크립트 파일 복사
$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$files = @("DesktopOrganizer.ps1", "update_organize.ps1", "organize.ps1", "restore.ps1")
foreach ($file in $files) {
    $src = Join-Path $sourceDir $file
    $dst = Join-Path $installDir $file
    if (Test-Path -LiteralPath $src) {
        Copy-Item -Path $src -Destination $dst -Force
    }
}

# 4. 환경 설정 폴더 생성 (%APPDATA%\DesktopOrganizer\)
$configDir = Join-Path $env:APPDATA 'DesktopOrganizer'
if (-not (Test-Path -LiteralPath $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# 복원 기록은 PC별 데이터이므로 소스 폴더의 기존 기록을 복사하지 않고
# 현재 PC에서 사용할 빈 기록으로 초기화합니다.
$recordPath = Join-Path $configDir '복원 기록.json'
if (-not (Test-Path -LiteralPath $recordPath)) {
    $emptyRecord = [pscustomobject]@{ items = @() } | ConvertTo-Json -Depth 3
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($recordPath, $emptyRecord, $utf8Bom)
}

# 5. 처음 실행할 때 사용자가 카테고리를 선택하도록 초기 상태를 생성합니다.
$categoryPath = Join-Path $configDir '카테고리.json'
if (-not (Test-Path -LiteralPath $categoryPath)) {
    $initialCategories = [pscustomobject]@{
        setupComplete = $false
        categories = @()
        rules = @()
    }
    $jsonForSave = $initialCategories | ConvertTo-Json -Depth 3
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($categoryPath, $jsonForSave, $utf8Bom)
}

# 6. 바탕화면 바로가기 생성
$desktop = [Environment]::GetFolderPath('Desktop')
$lnkPath = Join-Path $desktop "바로 가기 - 바탕화면 정리 도구.lnk"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($lnkPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\DesktopOrganizer.ps1`""
$shortcut.WorkingDirectory = $installDir
$shortcut.Description = "바탕화면 정리 도구 - 카테고리별 파일 정리 앱"
$shortcut.Save()

# 7. 작업표시줄/시작 메뉴 바로가기 생성
$startMenuPrograms = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$lnkStartMenu = Join-Path $startMenuPrograms "$appName\DesktopOrganizer.lnk"
if (-not (Test-Path -LiteralPath (Join-Path $startMenuPrograms $appName))) {
    New-Item -ItemType Directory -Path (Join-Path $startMenuPrograms $appName) -Force | Out-Null
}
$shortcutStartMenu = $wsh.CreateShortcut($lnkStartMenu)
$shortcutStartMenu.TargetPath = "powershell.exe"
$shortcutStartMenu.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\DesktopOrganizer.ps1`""
$shortcutStartMenu.Save()

Write-Host ""
Write-Host "=== 설치 완료 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "설치된 위치: $installDir" -ForegroundColor Green
Write-Host "설정 폴더: $configDir" -ForegroundColor Green
Write-Host "바탕화면 바로가기: 바탕화면 '바로 가기 - 바탕화면 정리 도구'" -ForegroundColor Green
Write-Host "시작 메뉴 바로가기: 시작 메뉴 > 프로그램 > DesktopOrganizer" -ForegroundColor Green
Write-Host ""
Write-Host "실행 방법:" -ForegroundColor Yellow
Write-Host "  - 바탕화면 '바로 가기 - 바탕화면 정리 도구' 더블클릭" -ForegroundColor White
Write-Host "  - 또는 PowerShell에서 직접 실행:" -ForegroundColor White
Write-Host "    powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\DesktopOrganizer.ps1`"" -ForegroundColor White

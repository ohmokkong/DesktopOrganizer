$ErrorActionPreference = 'Stop'

# 콘솔 갱신도 GUI와 같은 사용자별 설정과 기록을 사용합니다.
$configDir = Join-Path $env:APPDATA 'DesktopOrganizer'
$categoryPath = Join-Path $configDir '카테고리.json'
$recordPath = Join-Path $configDir '복원 기록.json'

if (-not (Test-Path -LiteralPath $categoryPath)) {
    Write-Host '카테고리 설정이 없습니다. 바탕화면 정리 도구를 먼저 실행하여 카테고리를 선택하세요.'
    return
}
$categoryConfig = Get-Content -LiteralPath $categoryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$categories = @($categoryConfig.categories | Where-Object { -not [string]::IsNullOrWhiteSpace($_.name) })
if ($categoryConfig.setupComplete -ne $true -or $categories.Count -eq 0) {
    Write-Host '카테고리 설정이 완료되지 않았습니다. 바탕화면 정리 도구를 먼저 실행하세요.'
    return
}
if (-not (Test-Path -LiteralPath $recordPath)) {
    Write-Host '복원 기록이 없습니다. 설치 프로그램을 실행하거나 바탕화면 정리 도구를 먼저 실행하세요.'
    return
}
$data = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $data -or $null -eq $data.items) { throw '복원 기록에 items 목록이 없습니다.' }

$desktop = [Environment]::GetFolderPath('Desktop')
$publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
$organizedRoot = Join-Path $desktop '바탕화면 정리'
$excludedNames = @(
    'desktop.ini', 'organize.ps1', 'restore.ps1', '복원.ps1', 'update_organize.ps1',
    '갱신 실행.cmd', '복원 실행.cmd', '정리 실행.cmd', 'DesktopOrganizer.ps1',
    'DesktopOrganizer.exe', 'Install-DesktopOrganizer.ps1', '설치 마법사',
    '바탕화면 정리 도구', '바로 가기 - 바탕화면 정리 도구',
    '바로 가기 - 바탕화면 정리 도구.lnk', 'DesktopOrganizer.lnk', 'Desktop Organizer.lnk'
)
# 비활성 기록도 보존합니다. 기존 기록의 재활성화는 메인 프로그램이 처리합니다.
$recordedPaths = @($data.items | ForEach-Object { $_.original })
$currentItems = @()
foreach ($directory in @($desktop, $publicDesktop) | Select-Object -Unique) {
    if ([string]::IsNullOrWhiteSpace($directory) -or -not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
    $currentItems += @(Get-ChildItem -LiteralPath $directory -Force | Where-Object {
        -not ($_.Attributes -band [IO.FileAttributes]::Hidden) -and
        -not ($_.Attributes -band [IO.FileAttributes]::System) -and
        $_.FullName -ne $organizedRoot -and
        $_.Name -notin $excludedNames -and
        $_.FullName -notin $recordedPaths
    })
}
if ($currentItems.Count -eq 0) {
    Write-Host '새로운 항목이 없습니다.'
    return
}

$registeredCount = 0
foreach ($item in $currentItems) {
    Write-Host ""
    Write-Host "[$($item.Name)] 카테고리를 선택하세요."
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host ("  {0}. {1}" -f ($i + 1), $categories[$i].name)
    }
    Write-Host '  r. 새 카테고리 이름 입력'
    Write-Host '  s. 건너뛰기'
    $choice = (Read-Host '선택').Trim()
    $number = 0
    $categoryName = $null
    if ([int]::TryParse($choice, [ref]$number) -and $number -ge 1 -and $number -le $categories.Count) {
        $categoryName = [string]$categories[$number - 1].name
    } elseif ($choice -eq 'r') {
        $categoryName = (Read-Host '새 카테고리 이름').Trim()
    } elseif ($choice -eq 's') {
        continue
    } else {
        Write-Host '잘못된 선택이므로 건너뜁니다.'
        continue
    }
    if ([string]::IsNullOrWhiteSpace($categoryName) -or $categoryName -in @('.', '..') -or
        $categoryName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or
        $categoryName.EndsWith('.') -or $categoryName.EndsWith(' ')) {
        Write-Host '사용할 수 없는 카테고리 이름이므로 건너뜁니다.'
        continue
    }

    $destDir = Join-Path $organizedRoot $categoryName
    $destPath = Join-Path $destDir $item.Name
    $stem = [IO.Path]::GetFileNameWithoutExtension($item.Name)
    $extension = [IO.Path]::GetExtension($item.Name)
    $number = 2
    while ((Test-Path -LiteralPath $destPath) -or @($data.items | Where-Object { $_.organized -eq $destPath }).Count -gt 0) {
        $destPath = Join-Path $destDir ("{0} ({1}){2}" -f $stem, $number, $extension)
        $number++
    }
    $data.items = @($data.items) + [pscustomobject]@{ original = $item.FullName; organized = $destPath }
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [IO.File]::WriteAllText($recordPath, ($data | ConvertTo-Json -Depth 10), $utf8Bom)
    $registeredCount++
    Write-Host "등록됨: $($item.Name) → $categoryName"
}
Write-Host ""
Write-Host "갱신 완료: $($registeredCount)개 등록됨. 실제 이동은 정리 실행 시 수행됩니다."

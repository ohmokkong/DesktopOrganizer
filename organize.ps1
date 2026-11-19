$ErrorActionPreference = 'Stop'
$record = Join-Path $env:APPDATA 'DesktopOrganizer\복원 기록.json'
if (!(Test-Path -LiteralPath $record)) {
  Write-Host "현재 PC의 복원 기록이 없습니다. 먼저 설치 또는 갱신을 실행하세요."
  Read-Host 'Enter 키를 누르면 닫습니다'
  exit 0
}
$data = Get-Content -LiteralPath $record -Raw -Encoding UTF8 | ConvertFrom-Json
$desktop = [Environment]::GetFolderPath('Desktop')
$publicDesktop = Join-Path $env:PUBLIC 'Desktop'
$errorsFound = $false
foreach ($item in $data.items) {
  $source = $item.original
  if (!(Test-Path -LiteralPath $source) -and $source.StartsWith($publicDesktop + '\', [StringComparison]::OrdinalIgnoreCase)) {
    $personal = Join-Path $desktop (Split-Path $source -Leaf)
    if (Test-Path -LiteralPath $personal) { $source = $personal }
  }
  if (!(Test-Path -LiteralPath $source)) { Write-Host "찾을 수 없음: $source"; $errorsFound = $true; continue }
  if (Test-Path -LiteralPath $item.organized) { Write-Host "정리 폴더에 같은 이름이 있어 건너뜀: $($item.organized)"; $errorsFound = $true; continue }
  try {
    $dir = Split-Path $item.organized -Parent
    if (!(Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if ($item.original -ne $source) {
      $item.original = $source
      $data | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $record -Encoding UTF8
    }
    Move-Item -LiteralPath $source -Destination $item.organized -ErrorAction Stop
    Write-Host "정리: $source"
  } catch { Write-Host "정리 실패: $source - $_"; $errorsFound = $true }
}
if ($errorsFound) { Write-Host '일부 항목을 정리하지 못했습니다. 위 내용을 확인하세요.' } else { Write-Host '정리가 완료되었습니다. 복원하려면 복원 실행.cmd를 사용하세요.' }
Read-Host 'Enter 키를 누르면 닫습니다'

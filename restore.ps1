$ErrorActionPreference = 'Stop'
$record = Join-Path $env:APPDATA 'DesktopOrganizer\복원 기록.json'
if (!(Test-Path -LiteralPath $record)) {
 Write-Host "현재 PC의 복원 기록이 없습니다. 복원할 항목이 없습니다."
 Read-Host 'Enter 키를 누르면 닫습니다'
 exit 0
}
$data = Get-Content -LiteralPath $record -Raw -Encoding UTF8 | ConvertFrom-Json
$failed = $false
foreach ($item in $data.items) {
 if (!(Test-Path -LiteralPath $item.organized)) { Write-Host "찾을 수 없음: $($item.organized)"; $failed=$true; continue }
 if (Test-Path -LiteralPath $item.original) { Write-Host "같은 이름이 있어 건너뜀: $($item.original)"; $failed=$true; continue }
 try { Move-Item -LiteralPath $item.organized -Destination $item.original -ErrorAction Stop; Write-Host "복원: $($item.original)" } catch { Write-Host "실패: $($item.original) - $_"; $failed=$true }
}
if ($failed) { Write-Host '일부 항목을 복원하지 못했습니다. 위 내용을 확인하세요.' } else { Write-Host '복원이 완료되었습니다. 정리 폴더는 확인 후 직접 삭제할 수 있습니다.' }
Read-Host 'Enter 키를 누르면 닫습니다'

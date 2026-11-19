#@.
# 바탕화면 정리 도구 - Windows Forms UI
# 정리 / 복원 / 갱신 3가지 기능 제공
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 설정 - 사용자별 APPDATA에만 저장합니다.
# 소스 폴더의 복원 기록을 fallback으로 사용하지 않아 다른 PC의 데이터를
# 실수로 읽거나 이동하는 일을 방지합니다.
$scriptPath = $PSScriptRoot
if (-not $scriptPath) { $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path }

$appDataDir = Join-Path $env:APPDATA 'DesktopOrganizer'
$recordPath = Join-Path $appDataDir '복원 기록.json'
$categoriesPath = Join-Path $appDataDir '카테고리.json'

if (-not (Test-Path -LiteralPath $appDataDir)) {
    New-Item -ItemType Directory -Path $appDataDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $recordPath)) {
    $emptyRecord = [pscustomobject]@{ items = @() } | ConvertTo-Json -Depth 3
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($recordPath, $emptyRecord, $utf8Bom)
}

# 카테고리 설정 파일 경로
# 카테고리 로드: JSON 파일을 읽고, 없거나 형식이 잘못되면 기본값 사용
$defaultCategories = @(
    [pscustomobject]@{ Id=1; Name='개발·학습'; Icon='💻'; Color='60,130,220' },
    [pscustomobject]@{ Id=2; Name='업무 문서'; Icon='📋'; Color='220,160,60' },
    [pscustomobject]@{ Id=3; Name='연결·공유'; Icon='🔗'; Color='150,100,220' },
    [pscustomobject]@{ Id=4; Name='임시 보관'; Icon='📦'; Color='150,150,150' },
    [pscustomobject]@{ Id=5; Name='웹·AI 바로가기'; Icon='🌐'; Color='60,180,120' },
    [pscustomobject]@{ Id=6; Name='프로그램 바로가기'; Icon='🚀'; Color='220,100,100' },
    [pscustomobject]@{ Id=7; Name='기존 바로가기 폴더'; Icon='📁'; Color='180,120,60' }
)

$loadedCategories = @()
$categorySetupComplete = $false
if (Test-Path -LiteralPath $categoriesPath) {
    try {
        $categoryConfig = Get-Content -LiteralPath $categoriesPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($categoryConfig.setupComplete -eq $true -and $categoryConfig.categories) {
            $loadedCategories = @($categoryConfig.categories | ForEach-Object {
                [pscustomobject]@{
                    Id = $_.id
                    Name = $_.name
                    Icon = $_.icon
                    Color = $_.color
                }
            })
            $categorySetupComplete = $true
        }
    } catch {
        $loadedCategories = @()
    }
}
$categories = @($loadedCategories | ForEach-Object { $_.Name })

function Show-CategorySetupDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '카테고리 설정'
    $dialog.Size = New-Object System.Drawing.Size(430, 430)
    $dialog.StartPosition = 'CenterScreen'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = [System.Drawing.Color]::White

    $title = New-Object System.Windows.Forms.Label
    $title.Text = '사용할 카테고리를 선택하세요'
    $title.Font = New-Object System.Drawing.Font('맑은 고딕', 12, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(20, 18)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = '처음 한 번만 설정하며, 나중에 설정 파일에서 변경할 수 있습니다.'
    $hint.AutoSize = $true
    $hint.Location = New-Object System.Drawing.Point(20, 50)

    $list = New-Object System.Windows.Forms.CheckedListBox
    $list.Location = New-Object System.Drawing.Point(20, 82)
    $list.Size = New-Object System.Drawing.Size(370, 220)
    $list.Font = New-Object System.Drawing.Font('맑은 고딕', 10)
    foreach ($category in $defaultCategories) {
        [void]$list.Items.Add($category.Name, $true)
    }

    $save = New-Object System.Windows.Forms.Button
    $save.Text = '저장'
    $save.Size = New-Object System.Drawing.Size(90, 34)
    $save.Location = New-Object System.Drawing.Point(205, 325)
    $save.DialogResult = 'OK'

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = '취소'
    $cancel.Size = New-Object System.Drawing.Size(90, 34)
    $cancel.Location = New-Object System.Drawing.Point(305, 325)
    $cancel.DialogResult = 'Cancel'

    $dialog.Controls.AddRange(@($title, $hint, $list, $save, $cancel))
    $dialog.AcceptButton = $save
    $dialog.CancelButton = $cancel
    $result = $dialog.ShowDialog()
    if ($result -ne 'OK' -or $list.CheckedItems.Count -eq 0) {
        return $null
    }

    return @($defaultCategories | Where-Object { $list.CheckedItems -contains $_.Name })
}

if (-not $categorySetupComplete) {
    $selectedCategories = Show-CategorySetupDialog
    if (-not $selectedCategories) {
        [System.Windows.Forms.MessageBox]::Show('카테고리를 하나 이상 선택해야 프로그램을 사용할 수 있습니다.', '카테고리 설정', 'OK', 'Warning') | Out-Null
        exit 0
    }
    $loadedCategories = @($selectedCategories)
    $categories = @($loadedCategories | ForEach-Object { $_.Name })
    $categoryConfig = [pscustomobject]@{
        setupComplete = $true
        categories = @($loadedCategories | ForEach-Object {
            [pscustomobject]@{
                id = $_.Id
                name = $_.Name
                icon = $_.Icon
                color = $_.Color
                target = $_.Name
            }
        })
        rules = @()
    }
    $jsonForSave = $categoryConfig | ConvertTo-Json -Depth 5
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($categoriesPath, $jsonForSave, $utf8Bom)
}

$desktopPath = [Environment]::GetFolderPath('Desktop')
$organizedRoot = Join-Path $desktopPath '바탕화면 정리'
$publicDesktop = Join-Path $env:PUBLIC 'Desktop'

# JSON 읽기
function Get-Record {
    try {
        $json = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 -ErrorAction Stop
        $data = $json | ConvertFrom-Json -ErrorAction Stop
        if ($null -eq $data -or $null -eq $data.items) { throw 'items 목록이 없습니다.' }
        $changed = $false
        foreach ($item in @($data.items)) {
            if ($item.inactive -eq $true) {
                if (Test-Path -LiteralPath $item.original) {
                    $otherOwners = @($data.items | Where-Object { $_ -ne $item -and $_.inactive -ne $true -and $_.organized -eq $item.organized })
                    if ($otherOwners.Count -gt 0) {
                        $directory = Split-Path $item.organized -Parent
                        $item.organized = Get-AvailableOrganizedPath -directory $directory -name (Split-Path $item.original -Leaf) -items $data.items
                    }
                    $item.inactive = $false
                    $changed = $true
                } elseif ($item.inactiveReason -eq 'missing' -and (Test-Path -LiteralPath $item.organized)) {
                    $otherOwners = @($data.items | Where-Object { $_ -ne $item -and $_.inactive -ne $true -and $_.organized -eq $item.organized })
                    if ($otherOwners.Count -eq 0) {
                        $item.inactive = $false
                        $changed = $true
                    }
                }
                continue
            }
            if ((Test-Path -LiteralPath $item.original) -or (Test-Path -LiteralPath $item.organized)) { continue }
            $other = @($data.items | Where-Object {
                $_ -ne $item -and $_.inactive -ne $true -and $_.organized -eq $item.organized -and
                (Test-Path -LiteralPath $_.original)
            })
            if ($other.Count -gt 0) {
                $item | Add-Member -NotePropertyName inactive -NotePropertyValue $true -Force
                $item | Add-Member -NotePropertyName inactiveReason -NotePropertyValue 'duplicate' -Force
                $changed = $true
            } elseif ((Test-Path -LiteralPath (Split-Path $item.original -Parent) -PathType Container) -and
                      (Test-Path -LiteralPath (Split-Path $item.organized -Parent) -PathType Container)) {
                $item | Add-Member -NotePropertyName inactive -NotePropertyValue $true -Force
                $item | Add-Member -NotePropertyName inactiveReason -NotePropertyValue 'missing' -Force
                $changed = $true
            }
        }
        if ($changed) { Save-Record $data }
        return $data
    } catch {
        throw "복원 기록을 읽을 수 없습니다: $($_.Exception.Message)"
    }
}

# JSON 저장
function Save-Record($data) {
    $json = $data | ConvertTo-Json -Depth 10
    # UTF-8 BOM으로 저장
    $utf8Bom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($recordPath, $json, $utf8Bom)
}

# 폴더 이동 (하위 포함)
function Move-Directory($source, $dest) {
    if (Test-Path -LiteralPath $dest) {
        throw "대상 위치에 같은 이름이 있습니다: $dest"
    }
    Move-Item -LiteralPath $source -Destination $dest -ErrorAction Stop
}

# 양쪽에 항목이 있으면 대상의 기존 항목을 별도 보관하고 요청한 방향으로 이동합니다.
# 보관 파일은 자동 삭제하지 않으며 전체 경로를 로그에 남깁니다.
function Resolve-MoveConflict($source, $destination) {
    $backupDir = Join-Path $organizedRoot '충돌 보관'
    New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction Stop | Out-Null
    $name = [System.IO.Path]::GetFileName($destination)
    $backupPath = Join-Path $backupDir ("{0}_{1}" -f [guid]::NewGuid().ToString('N'), $name)
    Move-Item -LiteralPath $destination -Destination $backupPath -ErrorAction Stop
    try {
        Move-Item -LiteralPath $source -Destination $destination -ErrorAction Stop
    } catch {
        $moveError = $_
        try {
            if (-not (Test-Path -LiteralPath $destination)) {
                Move-Item -LiteralPath $backupPath -Destination $destination -ErrorAction Stop
            }
        } catch {
            Write-Log "✗ 원래 위치로 되돌리지 못했습니다. 보관 위치: $backupPath"
        }
        throw $moveError
    }
    Write-Log "✓ 기존 항목 보관: $backupPath"
}

function Test-OrganizerShortcut($item) {
    $shortcut = Join-Path $desktopPath '바로 가기 - 바탕화면 정리 도구.lnk'
    return [string]::Equals($item.original, $shortcut, [StringComparison]::OrdinalIgnoreCase)
}

# 현재 디스크 상태를 기준으로 정리와 복원에 공통으로 사용할 목록을 만듭니다.
function Get-RecordState($items, [ValidateSet('Organize', 'Restore')]$direction) {
    $pending = @()
    $conflicts = @()
    $missing = @()
    foreach ($item in $items) {
        if ($item.inactive -eq $true -or (Test-OrganizerShortcut $item)) { continue }
        $originalExists = Test-Path -LiteralPath $item.original
        $organizedExists = Test-Path -LiteralPath $item.organized
        if ($originalExists -and $organizedExists) { $conflicts += $item }
        elseif (-not $originalExists -and -not $organizedExists) { $missing += $item }
        elseif (($direction -eq 'Organize' -and $originalExists) -or
                ($direction -eq 'Restore' -and $organizedExists)) { $pending += $item }
    }
    return [pscustomobject]@{ Pending = $pending; Conflicts = $conflicts; Missing = $missing }
}

# 이미 기록되었거나 존재하는 정리 위치를 피하여 각 항목의 복원 경로를 분리합니다.
function Get-AvailableOrganizedPath($directory, $name, $items) {
    $candidate = Join-Path $directory $name
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($name)
    $extension = [System.IO.Path]::GetExtension($name)
    $number = 2
    while ((Test-Path -LiteralPath $candidate) -or @($items | Where-Object { $_.organized -eq $candidate }).Count -gt 0) {
        $candidate = Join-Path $directory ("{0} ({1}){2}" -f $stem, $number, $extension)
        $number++
    }
    return $candidate
}

# 로그 기록
$script:logItems = @()
function Write-Log($message) {
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $entry = "[$timestamp] $message"
    $script:logItems = @($entry) + $script:logItems
    if ($lstLog) {
        $lstLog.Items.Insert(0, $entry)
        $lstLog.SelectedIndex = 0
    }
    if ($lblStatus) {
        $lblStatus.Text = $message
    }
    [System.Windows.Forms.Application]::DoEvents()
}

# 폼 생성
$form = New-Object System.Windows.Forms.Form
$form.Text = '바탕화면 정리 도구'
$form.Size = New-Object System.Drawing.Size(520, 460)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font('맑은 고딕', 9)

# 상단 패널
$panelTop = New-Object System.Windows.Forms.Panel
$panelTop.Dock = 'Top'
$panelTop.Height = 110
$panelTop.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)
$panelTop.Padding = New-Object System.Windows.Forms.Padding(20)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = '바탕화면 정리 도구'
$titleLabel.Font = New-Object System.Drawing.Font('맑은 고딕', 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = '바탕화면을 카테고리별로 정리·복원·갱신합니다'
$subtitleLabel.Font = New-Object System.Drawing.Font('맑은 고딕', 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 120)
$subtitleLabel.AutoSize = $true
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 58)

$panelTop.Controls.AddRange(@($titleLabel, $subtitleLabel))

# 버튼 패널
$panelButtons = New-Object System.Windows.Forms.Panel
$panelButtons.Dock = 'Top'
$panelButtons.Height = 85
$panelButtons.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 10)
$panelButtons.BackColor = [System.Drawing.Color]::White

function New-Button {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Creates an in-memory UI control without changing system state.')]
    param($text, $location, $backColor)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(140, 55)
    $btn.Location = $location
    $btn.Font = New-Object System.Drawing.Font('맑은 고딕', 10, [System.Drawing.FontStyle]::Bold)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.BackColor = $backColor
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 0
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

$btnOrganize = New-Button -text '🗂  정리' -location (New-Object System.Drawing.Point(20, 15)) -backColor ([System.Drawing.Color]::FromArgb(60, 130, 220))
$btnRestore = New-Button -text '↩  복원' -location (New-Object System.Drawing.Point(175, 15)) -backColor ([System.Drawing.Color]::FromArgb(220, 160, 60))
$btnUpdate = New-Button -text '🔄  갱신' -location (New-Object System.Drawing.Point(330, 15)) -backColor ([System.Drawing.Color]::FromArgb(60, 180, 120))

$panelButtons.Controls.AddRange(@($btnOrganize, $btnRestore, $btnUpdate))

# 구분선
$separator = New-Object System.Windows.Forms.Panel
$separator.Dock = 'Top'
$separator.Height = 1
$separator.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 230)

# 로그 패널
$panelLog = New-Object System.Windows.Forms.Panel
$panelLog.Dock = 'Fill'
$panelLog.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 20)
$panelLog.BackColor = [System.Drawing.Color]::White

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = '대기 중...'
$lblStatus.Font = New-Object System.Drawing.Font('맑은 고딕', 9)
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 100)
$lblStatus.AutoSize = $true
$lblStatus.Dock = 'Top'
$lblStatus.Height = 25

$lstLog = New-Object System.Windows.Forms.ListBox
$lstLog.Dock = 'Fill'
$lstLog.Font = New-Object System.Drawing.Font('Consolas', 9)
$lstLog.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 255)
$lstLog.BorderStyle = 'FixedSingle'

$panelLog.Controls.AddRange(@($lstLog, $lblStatus))

# 폼에 추가
$form.Controls.AddRange(@($panelLog, $separator, $panelButtons, $panelTop))

# 환경 확인
function Test-Environment {
    if (-not (Test-Path -LiteralPath $organizedRoot)) {
        New-Item -ItemType Directory -Path $organizedRoot -Force | Out-Null
        Write-Log "✓ 정리 폴더를 생성했습니다: $organizedRoot"
    }
    if (-not (Test-Path -LiteralPath $recordPath)) {
        Write-Log "⚠ 복원 기록 파일이 없습니다: $recordPath"
        $btnOrganize.Enabled = $false
        $btnRestore.Enabled = $false
        $btnUpdate.Enabled = $false
        return $false
    }
    $data = Get-Record
    Write-Log "✓ 환경 확인 완료 - 기록된 항목: $($data.items.Count)개"
    return $true
}

# 정리
function Invoke-Organize {
    param($Items = $null, [switch]$Quiet)
    if ($null -eq $Items) { $Items = @((Get-Record).items | Where-Object { $_.inactive -ne $true }) }
    $states = Get-RecordState $Items 'Organize'
    $pending = $states.Pending
    $conflicts = $states.Conflicts
    $missing = $states.Missing
    if ($pending.Count -eq 0 -and $conflicts.Count -eq 0 -and $missing.Count -eq 0) {
        if (-not $Quiet) {
            $message = if (@($Items).Count -eq 0) { '등록된 정리 항목이 없습니다. 갱신을 눌러 항목을 등록하세요.' } else { '이미 정리된 상태입니다.' }
            Write-Log $message
            [System.Windows.Forms.MessageBox]::Show($message, '정리', 'OK', 'Information') | Out-Null
        }
        return
    }
    foreach ($item in $missing) { Write-Log "⊘ 양쪽 위치에서 찾을 수 없음: $($item.original)" }
    $count = 0
    $failed = 0
    foreach ($item in $conflicts) {
        try {
            Resolve-MoveConflict $item.original $item.organized
            $count++
        } catch {
            $failed++
            Write-Log "✗ 충돌 처리 실패: $($item.original) - $($_.Exception.Message)"
        }
    }
    foreach ($item in $pending) {
        $source = $item.original
        if (-not (Test-Path -LiteralPath $source)) {
            Write-Log "⊘ 찾을 수 없음: $(Split-Path $item.original -Leaf)"
            continue
        }
        if (Test-Path -LiteralPath $item.organized) {
            Write-Log "⊘ 대상에 동일 이름 존재: $(Split-Path $item.organized -Leaf)"
            continue
        }
        try {
            $destDir = Split-Path $item.organized -Parent
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            if ((Get-Item -LiteralPath $source).PSIsContainer) {
                Move-Directory $source $item.organized
            } else {
                Move-Item -LiteralPath $source -Destination $item.organized -ErrorAction Stop
            }
            Write-Log "→ $(Split-Path $item.original -Leaf)"
            $count++
        } catch {
            $failed++
            Write-Log "✗ $(Split-Path $item.original -Leaf): $($_.Exception.Message)"
        }
    }
    $summary = "정리: $($count)개, 찾을 수 없음: $($missing.Count)개, 실패: $($failed)개. 자세한 내용은 로그를 확인하세요."
    Write-Log $summary
    if (-not $Quiet -and $failed -gt 0) { [System.Windows.Forms.MessageBox]::Show($summary, '정리 결과', 'OK', 'Warning') | Out-Null }
}

# 복원
function Invoke-Restore {
    $data = Get-Record
    $states = Get-RecordState $data.items 'Restore'
    $pending = $states.Pending
    $conflicts = $states.Conflicts
    $missing = $states.Missing
    if ($pending.Count -eq 0 -and $conflicts.Count -eq 0 -and $missing.Count -eq 0) {
        $message = if (@($data.items).Count -eq 0) { '등록된 복원 항목이 없습니다.' } else { '이미 복원이 완료된 상태입니다.' }
        Write-Log $message
        [System.Windows.Forms.MessageBox]::Show($message, '복원', 'OK', 'Information') | Out-Null
        return
    }
    foreach ($item in $missing) { Write-Log "⊘ 양쪽 위치에서 찾을 수 없음: $($item.original)" }
    $count = 0
    $skipped = $missing.Count
    $failed = 0
    foreach ($item in $conflicts) {
        try {
            Resolve-MoveConflict $item.organized $item.original
            $count++
        } catch {
            $failed++
            Write-Log "✗ 충돌 처리 실패: $($item.original) - $($_.Exception.Message)"
        }
    }
    foreach ($item in $pending) {
        if (-not (Test-Path -LiteralPath $item.organized)) {
            $skipped++
            Write-Log "⊘ 정리 위치에 없음: $(Split-Path $item.organized -Leaf)"
            continue
        }
        if (Test-Path -LiteralPath $item.original) {
            $skipped++
            Write-Log "⊘ 원본 위치에 동일 이름 존재: $(Split-Path $item.original -Leaf)"
            continue
        }
        try {
            $destDir = Split-Path $item.original -Parent
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            if ((Get-Item -LiteralPath $item.organized).PSIsContainer) {
                Move-Directory $item.organized $item.original
            } else {
                Move-Item -LiteralPath $item.organized -Destination $item.original -ErrorAction Stop
            }
            Write-Log "↩ $(Split-Path $item.original -Leaf)"
            $count++
        } catch {
            $failed++
            Write-Log "✗ $(Split-Path $item.original -Leaf): $($_.Exception.Message)"
        }
    }
    $summary = "복원: $($count)개, 찾을 수 없음: $($skipped)개, 실패: $($failed)개. 자세한 내용은 로그를 확인하세요."
    Write-Log $summary
    if ($failed -gt 0) {
        [System.Windows.Forms.MessageBox]::Show($summary, '복원 결과', 'OK', 'Warning') | Out-Null
    }
}

# 갱신 - 새 항목 감지 후 카테고리 등록(이동 보류)
function Invoke-Update {
    $currentItems = @()
    $desktopEntries = @([System.IO.Directory]::GetFileSystemEntries($desktopPath))
    if ((Test-Path -LiteralPath $publicDesktop -PathType Container) -and $publicDesktop -ne $desktopPath) {
        try {
            $desktopEntries += [System.IO.Directory]::GetFileSystemEntries($publicDesktop)
        } catch {
            Write-Log "✗ 공용 바탕화면을 읽지 못했습니다: $($_.Exception.Message)"
        }
    }
    foreach ($path in $desktopEntries) {
        $name = [System.IO.Path]::GetFileName($path)
        if ($name -eq 'desktop.ini') { continue }
        $attr = (Get-Item -LiteralPath $path).Attributes
        if ($attr -band [System.IO.FileAttributes]::Hidden) { continue }
        if ($attr -band [System.IO.FileAttributes]::System) { continue }
        if ($path -eq $organizedRoot) { continue }
        $currentItems += [pscustomobject]@{
            FullPath = $path
            Name = $name
            IsDirectory = (Test-Path -LiteralPath $path -PathType Container)
        }
    }

    $data = Get-Record

    $recordedPaths = @($data.items | Where-Object { $_.inactive -ne $true } | ForEach-Object { $_.original })

    $excludeNames = @('desktop.ini', 'organize.ps1', 'restore.ps1', '복원.ps1', 'update_organize.ps1', '갱신 실행.cmd', '복원 실행.cmd', '정리 실행.cmd', 'DesktopOrganizer.ps1', 'DesktopOrganizer.exe', 'Install-DesktopOrganizer.ps1', '설치 마법사', '바탕화면 정리 도구', '바로 가기 - 바탕화면 정리 도구', '바로 가기 - 바탕화면 정리 도구.lnk', 'DesktopOrganizer.lnk', 'Desktop Organizer.lnk')

    $newItems = @()
    foreach ($item in $currentItems) {
        if ($recordedPaths -contains $item.FullPath) { continue }
        if ($excludeNames -contains $item.Name) { continue }
        $newItems += $item
    }

    if ($newItems.Count -eq 0) {
        Write-Log '새로운 항목이 없습니다.'
        [System.Windows.Forms.MessageBox]::Show('새로운 항목이 없습니다.', '갱신', 'OK', 'Information')
        return
    }

    Write-Log "새 항목 $($newItems.Count)개 감지됨 - 카테고리 등록 후 정리 버튼으로 이동합니다"

    $registeredCount = 0
    foreach ($item in $newItems) {
        $selected = Show-CategoryDialog $item.Name $item.IsDirectory
        if (-not $selected) {
            Write-Log "⊘ 건너뜀: $($item.Name)"
            continue
        }

        try {
            # 즉시 이동하지 않고 기록에만 추가 (대기열)
            $destDir = Join-Path $organizedRoot $selected
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            $destPath = Get-AvailableOrganizedPath -directory $destDir -name $item.Name -items $data.items

            $newRec = [pscustomobject]@{
                original = $item.FullPath
                organized = $destPath
            }
            # 기존 항목이 있으면 건너뜀, 없으면 추가
            if (-not ($data.items | Where-Object { $_.original -eq $item.FullPath })) {
                $data.items += $newRec
                Write-Log "✓ 등록됨: $($item.Name) → $selected (대기열)"
            } else {
                Write-Log "~ 이미 등록된 항목: $($item.Name)"
            }
            $registeredCount++
        } catch {
            Write-Log "✗ $($item.Name): $($_.Exception.Message)"
        }
    }

    # 기록 저장
    if ($registeredCount -gt 0) {
        Save-Record $data
    }
    Write-Log "=== 갱신 완료: $registeredCount개 항목 등록됨. 이동하려면 정리를 누르세요. ==="
}

# 카테고리 선택 다이얼로그
function Show-CategoryDialog($itemName, $isDirectory) {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = '카테고리 선택'
    $dialog.Size = New-Object System.Drawing.Size(400, 460)
    $dialog.StartPosition = 'CenterParent'
    $dialog.FormBorderStyle = 'FixedDialog'
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = [System.Drawing.Color]::White
    $dialog.ShowInTaskbar = $false

    # 상단
    $panelTop = New-Object System.Windows.Forms.Panel
    $panelTop.Dock = 'Top'
    $panelTop.Height = 90
    $panelTop.BackColor = [System.Drawing.Color]::FromArgb(248, 249, 252)
    $panelTop.Padding = New-Object System.Windows.Forms.Padding(20)

    $icon = if ($isDirectory) { '📁' } else { '📄' }
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = $icon
    $iconLabel.Font = New-Object System.Drawing.Font('Segoe UI Emoji', 20)
    $iconLabel.Location = New-Object System.Drawing.Point(20, 10)
    $iconLabel.AutoSize = $true

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = $itemName
    $nameLabel.Font = New-Object System.Drawing.Font('맑은 고딕', 11, [System.Drawing.FontStyle]::Bold)
    $nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(40, 40, 60)
    $nameLabel.AutoSize = $true
    $nameLabel.Location = New-Object System.Drawing.Point(65, 12)
    $nameLabel.MaximumSize = New-Object System.Drawing.Size(300, 0)

    $typeLabel = New-Object System.Windows.Forms.Label
    $typeLabel.Text = if ($isDirectory) { '폴더' } else { '파일' }
    $typeLabel.Font = New-Object System.Drawing.Font('맑은 고딕', 9)
    $typeLabel.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 140)
    $typeLabel.AutoSize = $true
    $typeLabel.Location = New-Object System.Drawing.Point(65, 42)

    $instrLabel = New-Object System.Windows.Forms.Label
    $instrLabel.Text = '어디로 이동할까요?'
    $instrLabel.Font = New-Object System.Drawing.Font('맑은 고딕', 9)
    $instrLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 120)
    $instrLabel.AutoSize = $true
    $instrLabel.Location = New-Object System.Drawing.Point(20, 68)

    $panelTop.Controls.AddRange(@($iconLabel, $nameLabel, $typeLabel, $instrLabel))

    # 리스트
    $lv = New-Object System.Windows.Forms.ListView
    $lv.Dock = 'Fill'
    $lv.View = 'Details'
    $lv.FullRowSelect = $true
    $lv.MultiSelect = $false
    $lv.HeaderStyle = 'None'
    $lv.BorderStyle = 'None'
    $lv.Font = New-Object System.Drawing.Font('맑은 고딕', 10)
    $lv.Columns.Add('Category', 320) | Out-Null

    $script:dialogResult = $null
    $script:customName = ''

    for ($i = 0; $i -lt $categories.Count; $i++) {
        $item = New-Object System.Windows.Forms.ListViewItem("  $($categories[$i])")
        $item.Tag = $categories[$i]
        $lv.Items.Add($item) | Out-Null
    }

    $newItem = New-Object System.Windows.Forms.ListViewItem('  ✎  새 카테고리 만들기...')
    $newItem.Tag = '__NEW__'
    $newItem.ForeColor = [System.Drawing.Color]::FromArgb(60, 130, 220)
    $newItem.Font = New-Object System.Drawing.Font('맑은 고딕', 10, [System.Drawing.FontStyle]::Underline)
    $lv.Items.Add($newItem) | Out-Null

    # 하단
    $panelBottom = New-Object System.Windows.Forms.Panel
    $panelBottom.Dock = 'Bottom'
    $panelBottom.Height = 55
    $panelBottom.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 15)
    $panelBottom.BackColor = [System.Drawing.Color]::White

    $txtCustom = New-Object System.Windows.Forms.TextBox
    $txtCustom.Visible = $false
    $txtCustom.Width = 220
    $txtCustom.Location = New-Object System.Drawing.Point(20, 10)
    $txtCustom.Font = New-Object System.Drawing.Font('맑은 고딕', 10)

    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = '이동'
    $btnOK.Size = New-Object System.Drawing.Size(80, 32)
    $btnOK.Location = New-Object System.Drawing.Point(280, 10)
    $btnOK.Font = New-Object System.Drawing.Font('맑은 고딕', 10, [System.Drawing.FontStyle]::Bold)
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.BackColor = [System.Drawing.Color]::FromArgb(60, 180, 120)
    $btnOK.FlatStyle = 'Flat'
    $btnOK.FlatAppearance.BorderSize = 0
    $btnOK.Enabled = $false

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = '취소'
    $btnCancel.Size = New-Object System.Drawing.Size(80, 32)
    $btnCancel.Location = New-Object System.Drawing.Point(195, 10)
    $btnCancel.Font = New-Object System.Drawing.Font('맑은 고딕', 10)
    $btnCancel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 100)
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 0
    $btnCancel.DialogResult = 'Cancel'

    $lv.Add_SelectedIndexChanged({
        $btnOK.Enabled = $false
        $txtCustom.Visible = $false
        if ($lv.SelectedItems.Count -gt 0) {
            $tag = $lv.SelectedItems[0].Tag
            if ($tag -eq '__NEW__') {
                $txtCustom.Visible = $true
                $txtCustom.Focus()
            } else {
                $btnOK.Enabled = $true
            }
        }
    })

    $btnOK.Add_Click({
        $tag = $lv.SelectedItems[0].Tag
        if ($tag -eq '__NEW__') {
            if (-not [string]::IsNullOrWhiteSpace($txtCustom.Text)) {
                $script:dialogResult = $txtCustom.Text.Trim()
                $dialog.Close()
            }
        } else {
            $script:dialogResult = $tag
            $dialog.Close()
        }
    })

    $txtCustom.Add_KeyDown({
        if ($_.KeyCode -eq 'Enter') {
            if (-not [string]::IsNullOrWhiteSpace($txtCustom.Text)) {
                $script:dialogResult = $txtCustom.Text.Trim()
                $dialog.Close()
            }
        }
    })

    $panelBottom.Controls.AddRange(@($txtCustom, $btnOK, $btnCancel))

    $dialog.Controls.AddRange(@($lv, $panelBottom, $panelTop))
    $dialog.AcceptButton = $btnOK
    $dialog.CancelButton = $btnCancel

    $dialog.ShowDialog() | Out-Null
    return $script:dialogResult
}

# 버튼 이벤트
$btnOrganize.Add_Click({
    $btnOrganize.Enabled = $false
    try {
        Invoke-Organize
    } catch {
        Write-Log "✗ 정리 실패: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("정리 중 오류:`n$($_.Exception.Message)", '오류', 'OK', 'Error')
    } finally {
        $btnOrganize.Enabled = $true
    }
})

$btnRestore.Add_Click({
    $btnRestore.Enabled = $false
    try {
        Invoke-Restore
    } catch {
        Write-Log "✗ 복원 실패: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("복원 중 오류:`n$($_.Exception.Message)", '오류', 'OK', 'Error')
    } finally {
        $btnRestore.Enabled = $true
    }
})

$btnUpdate.Add_Click({
    $btnUpdate.Enabled = $false
    try {
        Invoke-Update
    } catch {
        Write-Log "✗ 갱신 실패: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("갱신 중 오류:`n$($_.Exception.Message)", '오류', 'OK', 'Error')
    } finally {
        $btnUpdate.Enabled = $true
    }
})

# 시작
Test-Environment | Out-Null
[void]$form.ShowDialog()

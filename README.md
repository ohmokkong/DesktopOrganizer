# 바탕화면 정리 도구 (Desktop Organizer)

## 📋 개요

바탕화면 파일을 카테고리별로 정리·복원·갱신하는 Windows Forms UI 앱.

## 🚀 설치

### 설치 프로그램 사용

배포 ZIP을 풀고 `DesktopOrganizer-Setup.exe`를 실행합니다. 설치 마법사에서 바탕화면 바로가기를 선택할 수 있으며, 설치 후 시작 메뉴의 `Desktop Organizer`에서도 실행할 수 있습니다. 설치 화면은 영어로 표시됩니다.

Windows 설정의 **앱 > 설치된 앱 > Desktop Organizer > 제거**에서 프로그램을 삭제할 수 있습니다. 제거해도 `%APPDATA%\DesktopOrganizer`의 설정·복원 기록과 바탕화면의 정리된 파일은 보존됩니다. 기록을 삭제하기 전에 필요한 파일을 먼저 복원하세요.

작업표시줄 고정은 설치 후 시작 메뉴에서 바로가기를 마우스 오른쪽 버튼으로 눌러 직접 선택합니다. Windows는 설치 프로그램이 사용자 확인 없이 작업표시줄에 고정하는 방식을 지원하지 않습니다. 이 프로그램은 PowerShell로 실행되므로 Windows 버전에 따라 작업표시줄에 PowerShell로 표시될 수 있습니다.

기존 PowerShell 설치본이 있으면 별도로 남습니다. 이전 버전의 수동 삭제는 아래 삭제 절차를 참고하세요. 기존 사용자 설정은 새 설치에서도 그대로 사용됩니다.

### 소스에서 PowerShell로 설치

1. PowerShell에서 다음 실행:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\Install-DesktopOrganizer.ps1
   ```
2. 바탕화면에 생성된 바로가기로 실행합니다. 공용 바탕화면의 항목은 권한에 따라 이동이 제한될 수 있습니다.

## 프로그램 삭제 및 초기화

1. 프로그램이 열려 있으면 종료합니다. 정리된 항목을 원래 위치로 되돌리려면 삭제 전에 `복원`을 실행하고, 로그에서 복원 결과를 확인합니다.
2. 파일 탐색기 주소창에 아래 경로를 입력한 뒤 `DesktopOrganizer` 폴더를 삭제합니다. 시작 메뉴 바로가기도 함께 삭제됩니다.

   ```text
   %APPDATA%\Microsoft\Windows\Start Menu\Programs\DesktopOrganizer
   ```

3. 바탕화면의 `바로 가기 - 바탕화면 정리 도구` 바로가기를 삭제합니다. 여기까지는 사용자 설정과 복원 기록이 유지되며, 재설치할 때 다시 사용됩니다.
4. 카테고리와 복원 기록까지 초기화하려면 아래 폴더도 삭제합니다. 복원 기록을 보존하려면 삭제 대신 다른 위치에 백업하세요.

   ```text
   %APPDATA%\DesktopOrganizer
   ```

5. 바탕화면의 `바탕화면 정리` 폴더는 자동으로 삭제되지 않습니다. `충돌 보관`을 포함해 안에 필요한 파일이 남아 있는지 확인하고, 필요한 항목은 다른 위치에 옮긴 후 폴더를 삭제합니다. 이 폴더를 삭제하면 안에 남은 사용자 파일도 함께 삭제됩니다.

삭제한 항목을 휴지통에 보낸 경우 휴지통을 비우기 전까지 복원할 수 있습니다. 완전 초기화 후 재설치하려면 위 설정 폴더까지 삭제한 다음 설치 절차를 다시 진행합니다.

## ▶️ 실행

- **바로가기**: 바탕화면 '바로 가기 - 바탕화면 정리 도구' 더블클릭
- **PowerShell에서 직접**: `& "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\DesktopOrganizer\DesktopOrganizer.ps1"`

## ⚙️ 기능

1. **정리**: 등록된 항목들을 바탕화면에서 정리 폴더로 일괄 이동
2. **복원**: 정리된 항목들을 바탕화면 원위치로 복원
3. **갱신**: 새 파일/폴더 감지 → 카테고리 선택 및 등록. 실제 이동은 `정리` 실행 시 수행

삭제된 항목의 기록은 보존하되 비활성화하며, 같은 위치에 다시 나타나면 기존 분류를 사용합니다. 이름이 충돌하면 기존 대상은 `바탕화면 정리\충돌 보관`에 보관됩니다.

처음 실행하면 사용할 카테고리를 선택하는 설정 창이 표시됩니다. 선택 결과는 현재 PC의 `%APPDATA%\DesktopOrganizer\카테고리.json`에 저장됩니다.

## 🔧 설정

- 카테고리: `%APPDATA%\DesktopOrganizer\카테고리.json` (현재 PC별 설정)
- 기록: `%APPDATA%\DesktopOrganizer\복원 기록.json` (현재 PC별 데이터)

## 📁 저장 위치

- 앱: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\DesktopOrganizer\`
- 설정: `%APPDATA%\DesktopOrganizer\`
- 바탕화면 정리: Windows에서 지정한 현재 사용자의 바탕화면 아래 `바탕화면 정리` (OneDrive 등으로 위치가 바뀔 수 있음)
- 기록: `%APPDATA%\DesktopOrganizer\복원 기록.json`

> 소스 폴더의 JSON 파일은 빈 초기값입니다. 프로그램은 현재 PC의 `%APPDATA%\DesktopOrganizer`에 별도 설정과 기록을 사용합니다. 설치 시 기존 파일이 있으면 초기화하거나 덮어쓰지 않습니다.

## 테스트

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-DesktopOrganizer.ps1`을 실행하면 임시 폴더에서 기록 상태와 경로 처리를 검사합니다.

콘솔 갱신 동작은 `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-ConsoleUpdate.ps1`로 검사합니다.

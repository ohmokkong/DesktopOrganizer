#define AppName "Desktop Organizer"
#define AppVersion "1.0.0"

[Setup]
AppId={{7BEFA878-8C68-4C63-AE8D-A6A857E9BC81}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\DesktopOrganizer
DefaultGroupName={#AppName}
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=DesktopOrganizer-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#AppName}

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: checkedonce

[Files]
Source: "..\DesktopOrganizer.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\organize.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\restore.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\update_organize.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\복원 기록.json"; DestDir: "{userappdata}\DesktopOrganizer"; Flags: onlyifdoesntexist uninsneveruninstall
Source: "..\카테고리.json"; DestDir: "{userappdata}\DesktopOrganizer"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{group}\Desktop Organizer"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\DesktopOrganizer.ps1"""; WorkingDir: "{app}"
Name: "{userdesktop}\Desktop Organizer"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\DesktopOrganizer.ps1"""; WorkingDir: "{app}"; Tasks: desktopicon

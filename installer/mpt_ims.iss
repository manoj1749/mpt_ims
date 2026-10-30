#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef Company
  #define Company "MPT"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\installer\app"
#endif
#ifndef OutputDir
  #define OutputDir "..\build\installer"
#endif
#ifndef VCRedistPath
  #define VCRedistPath "..\build\installer\vc_redist.x64.exe"
#endif

#if Company == "MPT"
  #define AppName "Magnet Power Tech IMS"
  #define AppPublisher "Magnet Power Tech"
  #define AppInstallDir "Magnet Power Tech IMS"
  #define AppOutputName "Magnet-IMS-Setup"
#else
  #define AppName "Aimant Industries IMS"
  #define AppPublisher "Aimant Industries"
  #define AppInstallDir "Aimant Industries IMS"
  #define AppOutputName "Aimant-IMS-Setup"
#endif
#define AppExeName "mpt_ims.exe"

[Setup]
#if Company == "MPT"
AppId={{2D8C7C1B-8B8C-4CC2-9C67-52D00ED7C3E3}
#else
AppId={{53F2BBA7-20D7-44C5-A09A-A12B39FD13EA}
#endif
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppInstallDir}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64os
ArchitecturesInstallIn64BitMode=x64os
PrivilegesRequired=admin
OutputDir={#OutputDir}
OutputBaseFilename={#AppOutputName}-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#AppName}
MinVersion=10.0

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#VCRedistPath}"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Microsoft Visual C++ runtime..."; Flags: runhidden waituntilterminated; Check: not IsVCRuntimeInstalled
Filename: "{app}\{#AppExeName}"; Description: "Launch {#AppName}"; WorkingDir: "{app}"; Flags: postinstall nowait skipifsilent

[Code]
function IsVCRuntimeInstalled: Boolean;
var
  Installed: Cardinal;
begin
  Result := RegQueryDWordValue(
    HKLM,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed',
    Installed
  ) and (Installed = 1);
end;


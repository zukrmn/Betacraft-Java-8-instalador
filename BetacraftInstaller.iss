[Setup]
AppId={{A1F8A7C2-3B4E-4A3E-9D5E-BCF6D7E12ABC}
AppName=Betacraft Launcher + Java 8
AppVersion=1.0.0
DefaultDirName={commonpf}\Betacraft
DefaultGroupName=Betacraft
OutputDir=.
OutputBaseFilename=Betacraft-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
DisableDirPage=no
DisableProgramGroupPage=no
SetupLogging=yes

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: desktopicon; Description: "Criar atalho na Área de Trabalho"; GroupDescription: "Atalhos:"; Flags: unchecked

[Icons]
Name: "{group}\Betacraft Launcher"; Filename: "{app}\launcher-1.09_17.exe"
Name: "{commondesktop}\Betacraft Launcher"; Filename: "{app}\launcher-1.09_17.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\launcher-1.09_17.exe"; Description: "Abrir Betacraft agora"; Flags: nowait postinstall skipifsilent

[Code]
const
  JavaInstallerName = 'jre8_offline.exe';
  JavaDownloadUrl = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252627_99a6cb9582554a09bd4ac60f73f9b8e6';
  BetacraftExeName = 'launcher-1.09_17.exe';
  BetacraftUrl = 'https://github.com/betacraftuk/betacraft-launcher/releases/download/1.09_17/launcher-1.09_17.exe';

function IsJava8Installed(var JavaHome: string): Boolean;
var
  Ver, JavaKey, JavaHomeVal: string;
begin
  Result := False;
  if RegQueryStringValue(HKLM64, 'SOFTWARE\JavaSoft\Java Runtime Environment', 'CurrentVersion', Ver) then
  begin
    if Copy(Ver, 1, 3) = '1.8' then
    begin
      JavaKey := 'SOFTWARE\JavaSoft\Java Runtime Environment\' + Ver;
      if RegQueryStringValue(HKLM64, JavaKey, 'JavaHome', JavaHomeVal) then
      begin
        JavaHome := JavaHomeVal;
        Result := True;
        exit;
      end;
    end;
  end;
  if not Result then
  begin
    if RegQueryStringValue(HKLM, 'SOFTWARE\JavaSoft\Java Runtime Environment', 'CurrentVersion', Ver) then
    begin
      if Copy(Ver, 1, 3) = '1.8' then
      begin
        JavaKey := 'SOFTWARE\JavaSoft\Java Runtime Environment\' + Ver;
        if RegQueryStringValue(HKLM, JavaKey, 'JavaHome', JavaHomeVal) then
        begin
          JavaHome := JavaHomeVal;
          Result := True;
          exit;
        end;
      end;
    end;
  end;
end;

function OnDlProgress(const Url, FileName: String; const Progress, ProgressMax: Int64): Boolean;
begin
  Result := True;
end;

// Baixa para %TEMP% - argumento deve ser APENAS o nome (sem path).
function DownloadToTemp(const Url, FileName: string): string;
var
  TempPath: string;
  Bytes: Int64;
begin
  Bytes := DownloadTemporaryFile(Url, FileName, '', @OnDlProgress);
  if Bytes <= 0 then
    RaiseException('Falha no download de: ' + Url);
  TempPath := ExpandConstant('{tmp}\') + FileName;
  if not FileExists(TempPath) then
    RaiseException('Arquivo não encontrado após download: ' + TempPath);
  Result := TempPath;
end;

procedure InstallJavaIfNeeded();
var
  JavaHome: string;
  JavaInstallerPath: string;
  ResultCode: Integer;
begin
  if IsJava8Installed(JavaHome) then
  begin
    Log('Java 8 detectado: ' + JavaHome);
    exit;
  end;
  MsgBox('Java 8 não foi detectado. O instalador será baixado e instalado em modo silencioso.', mbInformation, MB_OK);
  JavaInstallerPath := DownloadToTemp(JavaDownloadUrl, JavaInstallerName);
  if not Exec(JavaInstallerPath, '/s', '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
    RaiseException('Falha ao iniciar instalador do Java 8. Código: ' + IntToStr(ResultCode));
  if ResultCode <> 0 then
    RaiseException('Instalação do Java 8 retornou código: ' + IntToStr(ResultCode));
  if not IsJava8Installed(JavaHome) then
    RaiseException('Java 8 não detectado após instalar. Verifique conectividade e permissões.');
end;

procedure DownloadAndPlaceBetacraft();
var
  TempExePath, DestExePath: string;
begin
  TempExePath := DownloadToTemp(BetacraftUrl, BetacraftExeName);
  DestExePath := ExpandConstant('{app}\') + BetacraftExeName;
  ForceDirectories(ExpandConstant('{app}'));
  if not CopyFile(TempExePath, DestExePath, False) then
    RaiseException('Falha ao copiar Betacraft para: ' + DestExePath);
  if not FileExists(DestExePath) then
    RaiseException('Falha ao salvar o Betacraft Launcher em: ' + DestExePath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    InstallJavaIfNeeded();
    DownloadAndPlaceBetacraft();
  end;
end;

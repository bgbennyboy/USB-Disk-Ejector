 {
******************************************************
  USB Disk Ejector
  Copyright (c) 2006 - 2010 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}
{
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}
{
Based on uObjetos.pas by Sebastián Mayorá 
(DelphiHelper@Yahoo.com.ar)
For more information see http://delphi.about.com/library/bluc/text/uc090302a.htm
}


unit uDiskEjectOptions;

interface
uses
  Classes, Sysutils, forms, inifiles, JCLFileUtils, JCLSysInfo, JCLStrings,
  uDiskEjectConst, uCustomHotKeyManager;

type
  TOptions = class (TComponent)
  private
    fOptionsFilename: string; //Filename to store the ini
    fIniFile: TMemIniFile;

    //Internal properties

    fUseWindowsNotifications: boolean;	//Show windows' eject message rather than the apps.
	  //fShowNoEjectMessage: boolean;		    //Show no eject message at all
	  fPreserveWindowLocation: boolean;
	  fPreserveWindowSize: boolean;
    fAutoResize: boolean;               //Automatically resize to show all drives
    fWindowHeight: integer;
    fWindowWidth: integer;
    fWindowLeftPos: integer;
    fWindowTopPos: integer;
	  fStartAppMinimised: boolean;
	  fCloseToTray: boolean;				      //Cross/exit button makes app minimize to tray rather than exit
    fMinimizeToTray: boolean;
    fBalloonMessages: boolean;          //Stops balloon messages from appearing when the program is run in GUI mode
    fCardPolling: boolean;              //If devices are polled every x seconds to see if they have card media loaded
    fAfterEject: integer;               //After a successful eject do 0 - nothing, 1 - exit, 2 - minimize
    fAudioNotifications: boolean;
    fCloseRunningApps_Ask: boolean;
    fCloseRunningApps_Force: boolean;
    fSnapTo: integer;
    fHotKeys: TCustomHotKeyManager;

    //function GetCommandLine_UseWindowsNotifications: boolean;
    function GetMobileMode: boolean;
    function GetCommandLine_NoSave: boolean;
    function GetCommandLine_RemoveLetter: boolean;
    function GetCommandLine_RemoveLabel: boolean;
    function GetCommandLine_RemoveMountPoint: boolean;
    function GetCommandLine_RemoveName: boolean;
    function GetCommandLine_RemoveThis: boolean;
    //function GetCommandLine_CloseApps: boolean;
    //function GetCommandLine_CloseAppsForce: boolean;
    //function GetCommandLine_Param_UseWindowsNotifications: string;
    function GetCommandLine_Param_RemoveLetter: string;
    function GetCommandLine_Param_RemoveLabel: string;
    function GetCommandLine_Param_RemoveMountPoint: string;
    function GetCommandLine_Param_RemoveName: string;
    //function GetCommandLine_Param_CloseApps: string;
    //function GetCommandLine_Param_CloseAppsForce: string;
    function FindParamIndex(Param: string): integer;

  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;

    procedure ReadConfig;
    procedure SaveConfig;

    procedure RebuildHotkeys;

    //These arent Saved
    property CommandLine_NoSave:                  boolean read GetCommandLine_NoSave;
    property CommandLine_RemoveThis:              boolean read GetCommandLine_RemoveThis;
    property CommandLine_RemoveLetter:            boolean read GetCommandLine_RemoveLetter;
    property CommandLine_RemoveLabel:            boolean read GetCommandLine_RemoveLabel;
    property CommandLine_RemoveMountPoint:        boolean read GetCommandLine_RemoveMountPoint;
    property CommandLine_RemoveName:              boolean read GetCommandLine_RemoveName;
    //property CommandLine_CloseApps:               boolean read GetCommandLine_CloseApps;
   // property CommandLine_CloseAppsForce:          boolean read GetCommandLine_CloseAppsForce;
   //property CommandLine_UseWindowsNotifications: boolean read GetCommandLine_UseWindowsNotifications;
    property InMobileMode:                        boolean read GetMobileMode; //if running from temp folder
    property CommandLine_Param_RemoveLetter:            string  read GetCommandLine_Param_RemoveLetter;
    property CommandLine_Param_RemoveLabel:            string  read GetCommandLine_Param_RemoveLabel;
    property CommandLine_Param_RemoveMountPoint:        string  read GetCommandLine_Param_RemoveMountPoint;
    property CommandLine_Param_RemoveName:              string  read GetCommandLine_Param_RemoveName;
    //property CommandLine_Param_CloseApps:               string  read GetCommandLine_Param_CloseApps;
    //property CommandLine_Param_CloseAppsForce:          string  read GetCommandLine_Param_CloseAppsForce;
    //property CommandLine_Param_UseWindowsNotifications: string  read GetCommandLine_Param_UseWindowsNotifications;  //returns the text switch for use with relaunching the program

    //These are saved
    property UseWindowsNotifications  : boolean   read  fUseWindowsNotifications  write fUseWindowsNotifications;
    //property ShowNoEjectMessage     : boolean   read  fShowNoEjectMessage       write fShowNoEjectMessage;
    property PreserveWindowLocation   : boolean   read  fPreserveWindowLocation   write fPreserveWindowLocation;
    property PreserveWindowSize       : boolean   read  fPreserveWindowSize       write fPreserveWindowSize;
    property AutoResize               : boolean   read  fAutoResize               write fAutoResize;
    property StartAppMinimised        : boolean   read  fStartAppMinimised        write fStartAppMinimised;
    property CloseToTray              : boolean   read  fCloseToTray              write fCloseToTray;
    property MinimizeToTray           : boolean   read  fMinimizeToTray           write fMinimizeToTray;
    property BalloonMessages          : boolean   read  fBalloonMessages          write fBalloonMessages;
    property CloseRunningApps_Ask     : boolean   read  fCloseRunningApps_Ask     write fCloseRunningApps_Ask;
    property CloseRunningApps_Force   : boolean   read  fCloseRunningApps_Force   write fCloseRunningApps_Force;
    property AudioNotifications       : boolean   read  fAudioNotifications       write fAudioNotifications;
    property WindowHeight             : integer   read  fWindowHeight             write fWindowHeight;
    property WindowWidth              : integer   read  fWindowWidth              write fWindowWidth;
    property WindowLeftPos            : integer   read  fWindowLeftPos            write fWindowLeftPos;
    property WindowTopPos             : integer   read  fWindowTopPos             write fWindowTopPos;
    property CardPolling              : boolean   read  fCardPolling              write fCardPolling;
    property AfterEject               : integer   read  fAfterEject               write fAfterEject;
    property SnapTo                   : integer   read  fSnapTo                   write fSnapTo;

    property HotKeys     : TCustomHotKeyManager   read  fHotKeys                  write fHotKeys;
  end;

var
  Options: TOptions;

implementation

constructor TOptions.Create(aOwner: TComponent);
begin
  inherited Create(AOWner);

  {if CommandLine_NoSave then
    fOptionsFilename:=''
  else}
    fOptionsFilename:= ExtractFilePath(ParamStr(0)) + str_Ini_FileName;
end;

destructor TOptions.Destroy;
begin
  //SaveConfig

  if fIniFile <> nil then
    fIniFile.Free;

  inherited Destroy;
end;

procedure TOptions.ReadConfig;
begin
  try
    fIniFile:=TMemIniFile.Create(fOptionsFilename);

    fUseWindowsNotifications:= fIniFile.ReadBool('Preferences', 'ShowWindowsEjectMessage', false);
    //fShowNoEjectMessage:=    fIniFile.ReadBool('Preferences', 'ShowNoEjectMessage', true);
    fPreserveWindowLocation:=  fIniFile.ReadBool('Preferences', 'PreserveWindowLocation', false);
    fPreserveWindowSize:=      fIniFile.ReadBool('Preferences', 'PreserveWindowSize', false);
    fAutoResize:=              fIniFile.ReadBool('Preferences', 'AutoResize', true);
    fStartAppMinimised:=       fIniFile.ReadBool('Preferences', 'StartAppMinimised', false);
    fCloseToTray:=             fIniFile.ReadBool('Preferences', 'CloseToTray', false);
    fMinimizeToTray:=          fIniFile.ReadBool('Preferences', 'MinimizeToTray', true);
    fBalloonMessages:=         fIniFile.ReadBool('Preferences', 'BalloonMessages', true);
    fCardPolling:=             fIniFile.ReadBool('Preferences', 'CardPolling', true);
    fCloseRunningApps_Ask:=    fIniFile.ReadBool('Preferences', 'CloseRunningApps', false);
    fCloseRunningApps_Force:=  fIniFile.ReadBool('Preferences', 'ForceAppsClose', false);
    fAudioNotifications:=      fIniFile.ReadBool('Preferences', 'AudioNotifications', false);

    fAfterEject:=              fIniFile.ReadInteger('Preferences', 'AfterEject', 0);

    fWindowHeight:=            fIniFile.ReadInteger('Preferences', 'WindowHeight', 233);
    fWindowWidth:=             fIniFile.ReadInteger('Preferences', 'WindowWidth', 345);
    fWindowLeftPos:=           fIniFile.ReadInteger('Preferences', 'WindowLeftPos', 200);
    fWindowTopPos:=            fIniFile.ReadInteger('Preferences', 'WindowTopPos', 200);

    fSnapTo:=                  fIniFile.ReadInteger('Preferences', 'SnapTo', 1);
  except
    //Report error - cant find options file
  end
end;

procedure TOptions.SaveConfig;
var
  i: integer;
  break: boolean;
begin
  if CommandLine_NoSave then exit;

  fIniFile.WriteBool('Preferences', 'ShowWindowsEjectMessage',  fUseWindowsNotifications);
  //fIniFile.WriteBool('Preferences', 'ShowNoEjectMessage',       fShowNoEjectMessage);
  fIniFile.WriteBool('Preferences', 'PreserveWindowLocation',   fPreserveWindowLocation);
  fIniFile.WriteBool('Preferences', 'PreserveWindowSize',       fPreserveWindowSize);
  fIniFile.WriteBool('Preferences', 'AutoResize',               fAutoResize);
  fIniFile.WriteBool('Preferences', 'StartAppMinimised',        fStartAppMinimised);
  fIniFile.WriteBool('Preferences', 'CloseToTray',              fCloseToTray);
  fIniFile.WriteBool('Preferences', 'MinimizeToTray',           fMinimizeToTray);
  fIniFile.WriteBool('Preferences', 'BalloonMessages',          fBalloonMessages);
  fIniFile.WriteBool('Preferences', 'CardPolling',              fCardPolling);
  fIniFile.WriteBool('Preferences', 'CloseRunningApps',         fCloseRunningApps_Ask);
  fIniFile.WriteBool('Preferences', 'ForceAppsClose',           fCloseRunningApps_Force);
  fIniFile.WriteBool('Preferences', 'AudioNotifications',       fAudioNotifications);

  fIniFile.WriteInteger('Preferences', 'AfterEject',            fAfterEject);

  fIniFile.WriteInteger('Preferences', 'WindowHeight',          fWindowHeight);
  fIniFile.WriteInteger('Preferences', 'WindowWidth',           fWindowWidth);
  fIniFile.WriteInteger('Preferences', 'WindowLeftPos',         fWindowLeftPos);
  fIniFile.WriteInteger('Preferences', 'WindowTopPos',          fWindowTopPos);

  fIniFile.WriteInteger('Preferences', 'SnapTo',                fSnapTo);

  //First find and delete any existing hotkeys in the ini file
  break:=false;
  i:=0;
  while break = false do
  begin
    if fIniFile.SectionExists('Hotkey' + inttostr(i)) then
      fIniFile.EraseSection('Hotkey' + inttostr(i))
    else
      break:=true;

    inc(i);
  end;
  
  //Then save no of hotkeys and the hotkeys sections
  if fHotKeys <> nil then
  begin
    if fHotKeys.HotKeys.Count > 0 then
      fIniFile.WriteInteger('Hotkeys', 'NumHotkeys', fHotKeys.HotKeys.Count)
    else
      fIniFile.WriteInteger('Hotkeys', 'NumHotkeys', 0);

    for I := 0 to fHotKeys.HotKeys.Count - 1 do
    begin
      fIniFile.WriteInteger('Hotkey' + inttostr(i), 'Hotkey',
                            TCustomHotKey(fHotKeys.HotKeys[i]).HotKey);
      fIniFile.WriteInteger('Hotkey' + inttostr(i), 'HotKeyType',
                            Integer(TCustomHotKey(fHotKeys.HotKeys[i]).HotKeyType));
      fIniFile.WriteString('Hotkey' + inttostr(i), 'HotKeyParam',
                            TCustomHotKey(fHotKeys.HotKeys[i]).HotKeyParam);
    end;

  end
  else
    fIniFile.WriteInteger('Hotkeys', 'NumHotkeys', 0);


  fIniFile.UpdateFile;
end;

procedure TOptions.RebuildHotkeys;
var
  numHotKeys, i: integer;
begin
  if fHotKeys = nil then exit;
  

  numHotkeys:=fIniFile.ReadInteger('Hotkeys', 'NumHotkeys', 0);
  if numHotKeys = 0 then exit;

  for I := 0 to numHotKeys - 1 do
  begin
    fHotKeys.AddHotKey(
        fIniFile.ReadInteger('Hotkey' + inttostr(i), 'Hotkey', 0),
        TCustomHotkeyAction(fIniFile.ReadInteger('Hotkey' + inttostr(i), 'HotKeyType', 0)),
        fIniFile.ReadString('Hotkey' + inttostr(i), 'HotKeyParam', '')
    );
  end;
end;


{****************************Command Line Functions****************************}

{function TOptions.GetCommandLine_CloseApps: boolean;
begin
  if FindCmdLineSwitch('CLOSEAPPS', true) or FindCmdLineSwitch('CLOSEAPPSFORCE', true) then
    result:=true
  else
    result:=false
end;

function TOptions.GetCommandLine_CloseAppsForce: boolean;
begin
  if FindCmdLineSwitch('CLOSEAPPSFORCE', true) then
    result:=true
  else
    result:=false
end;}

function TOptions.GetCommandLine_RemoveMountPoint: boolean;
begin
  if FindCmdLineSwitch('REMOVEMOUNTPOINT', true) then
    result:=true
  else
    result:=false;
end;

function TOptions.GetCommandLine_NoSave: boolean;
begin
  if FindCmdLineSwitch('NOSAVE', true) then
    result:=true
  else
    result:=false
end;

function TOptions.GetCommandLine_RemoveLabel: boolean;
begin
  if FindCmdLineSwitch('REMOVELABEL', true) then
    result:=true
  else
    result:=false;
end;

function TOptions.GetCommandLine_RemoveLetter: boolean;
begin
  if FindCmdLineSwitch('REMOVELETTER', true) then
    result:=true
  else
    result:=false;
end;

function TOptions.GetCommandLine_RemoveName: boolean;
begin
  if FindCmdLineSwitch('REMOVENAME', true) then
    result:=true
  else
    result:=false;
end;

function TOptions.GetCommandLine_RemoveThis: boolean;
begin
  if FindCmdLineSwitch('REMOVETHIS', true) then
    result:=true
  else
    result:=false;
end;

{function TOptions.GetCommandLine_UseWindowsNotifications: boolean;
begin
  if FindCmdLineSwitch('USEWINDOWSNOTIFICATIONS', true) then
    result:=true
  else
    result:=false
end;}

function TOptions.GetCommandLine_Param_RemoveLabel: string;
var
  intTemp: integer;
begin
  intTemp:=FindParamIndex('/REMOVELABEL');
  if (intTemp <> -1) and (ParamCount >= intTemp + 1) then
  begin
    result:=Uppercase(ParamStr(intTemp + 1));
  end
  else
    result:='';

end;

function TOptions.GetCommandLine_Param_RemoveLetter: string;
var
  intTemp: integer;
  tempParam: string;
begin
  //Get the params for removeletter and removename
  //It should be the param straight after the /whatever switch
  //So first find what number param the switch is
  intTemp:=FindParamIndex('/REMOVELETTER');
  if (intTemp <> -1) and (ParamCount >= intTemp + 1) then
  begin
    tempParam:=ParamStr(intTemp + 1);
    result:=Uppercase(tempParam[1]); //Just return the letter
  end
  else
    result:='';
end;

function TOptions.GetCommandLine_Param_RemoveMountPoint: string;
var
  intTemp: integer;
  tempParam: string;
begin
  //First find what number param the switch is
  intTemp:=FindParamIndex('/REMOVEMOUNTPOINT');
  if (intTemp <> -1) and (ParamCount >= intTemp + 1) then
  begin
    tempParam:=ParamStr(intTemp + 1); //Paramstr automatically parses out speech marks
    result:=IncludeTrailingPathDelimiter(tempParam) ;
  end
  else
    result:='';
end;

function TOptions.GetCommandLine_Param_RemoveName: string;
var
  intTemp: integer;
begin
  //First find what number param the switch is
  intTemp:=FindParamIndex('/REMOVENAME');
  if intTemp <> -1 then
    result:=ParamStr(intTemp + 1)
  else
    result:='';
end;

{function TOptions.GetCommandLine_Param_UseWindowsNotifications: string;
begin
  if CommandLine_UseWindowsNotifications then
    result:='/USEWINDOWSNOTIFICATIONS '
  else
    result:='';
end;

function TOptions.GetCommandLine_Param_CloseApps: string;
begin
  if CommandLine_CloseApps then
    result:='/CLOSEAPPS '
  else
    result:='';
end;

function TOptions.GetCommandLine_Param_CloseAppsForce: string;
begin
  if CommandLine_CloseAppsForce then
    result:='/CLOSEAPPSFORCE '
  else
    result:='';
end;}

function TOptions.GetMobileMode: boolean;
begin
  //Check if running from temp folder
  if IncludeTrailingPathDelimiter(PathGetShortName(extractfilepath(application.ExeName))) = IncludeTrailingPathDelimiter( pathgetshortname(GetWindowsTempFolder) ) then
    result:=true
  else
    result:=false;
end;

function TOptions.FindParamIndex(Param: string): integer;
var  //Remember to include / in param when calling this, since ParamStr returns the /
  i: integer;
begin
  result:=-1;

  for i := 1 to ParamCount do
  begin
    if Uppercase(Param) = Uppercase(ParamStr(i)) then
    begin
      result:=i;
      break;
    end;
  end;
end;

{******************************************************************************}


initialization
{-----------------------------------------------------------------------------
  Creating the object in this section allow us using it from anywhere and anytime.
  Even from .DPR file and before forms creation.
  Object Options is available from the beginning of the application
-----------------------------------------------------------------------------}
  Options := TOptions.Create(nil);
  Options.ReadConfig;

finalization
//If we create it in Initialization, we destroy it here
  Options.Free;
end.

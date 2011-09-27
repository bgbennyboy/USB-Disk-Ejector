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

unit uDiskEjectUtils;

interface

uses Classes, sysutils, windows, forms, jclsysinfo, jclfileutils, jclshell,
     JCLRegistry, dialogs, ShellAPI, JwaWindows,
     uDiskEjectConst, uDriveEjector;

type
  TTaskBarPos = (_TOP, _BOTTOM, _LEFT, _RIGHT, _NONE);

procedure CreateCleanupBatFileAndRun;
procedure StartInMobileMode(Parameters: string);
procedure RemoveReadOnlyFileAttribute(FileName: string);
function GetTaskBarHeight: integer;
function GetTaskBarWidth: integer;
function GetTaskBarPos: TTaskBarPos;
function IsTaskbarAutoHideOn: Boolean;
function MatchNameToMountPoint(Name: string): string; overload;
function MatchNameToMountPoint(Name: string; Ejector: TDriveEjector): string; overload;
function MatchLabelToMountPoint(DiskLabel: string): string; overload;
function MatchLabelToMountPoint(DiskLabel: string; Ejector: TDriveEjector): string; overload;
function ConvertDriveLetterToMountpoint(DriveLetter: string): string;
function ConvertMountPointToDriveLetter(MountPoint: string): string;
function BalloonTipsEnabled: boolean;
function IsWindowsVistaorLater : Boolean;
function FindMountPoint(Directory: string): string;
function IsAppRunningFromThisLocation(MountPoint: string): boolean;

implementation

procedure RemoveReadOnlyFileAttribute(FileName: string);
var
  Attributes: cardinal;
begin
  if FileName = '' then exit;

  Attributes:=FileGetAttr(FileName);
  if Attributes = INVALID_FILE_ATTRIBUTES then exit;

  if Attributes and faReadOnly = faReadOnly then
    FileSetAttr(FileName, Attributes xor faReadOnly);
end;

procedure CreateCleanupBatFileAndRun;
var
  BatFile: TStringList;
  CmdLine: string;
begin
  CmdLine:=IncludeTrailingPathDelimiter( Getwindowstempfolder)  + 'USB_Eject_Cleanup.bat';
  BatFile := TStringList.Create;
  try
    BatFile.Add(':redo');
    BatFile.Add(Format('@del "%s"', [Application.ExeName]));
    BatFile.Add('if EXIST "'+Application.ExeName+'" GOTO redo');
    BatFile.Add(Format('@del "%s"', [IncludeTrailingPathDelimiter( Getwindowstempfolder)  + str_Ini_FileName]));
    BatFile.Add(Format('@del "%s"', [CmdLine]));
    BatFile.SaveToFile(CmdLine);
  finally
    BatFile.Free;
  end;

  ShellExec(0, 'open', 'USB_Eject_Cleanup.bat', '', IncludeTrailingPathDelimiter( GetWindowsTempFolder), SW_HIDE);
end;

procedure StartInMobileMode(Parameters: string);
var
  CopyResult : boolean;
begin
  CopyResult := true;
  //Copy the exe and the ini file to the temp folder and start the exe
  if FileExists( ExtractFilePath(Application.ExeName) + str_Ini_FileName ) then
    CopyResult := FileCopy(ExtractFilePath(Application.ExeName) + str_Ini_FileName, IncludeTrailingPathDelimiter(GetWindowsTempFolder) + str_Ini_FileName, true);

  if CopyResult = true then
    CopyResult := FileCopy(Application.ExeName, IncludeTrailingPathDelimiter(GetWindowsTempFolder) + extractfilename(application.ExeName), true);


  if CopyResult = true then
  begin
    //Check if files are read only and if it is - change it so it can be deleted later
    RemoveReadOnlyFileAttribute(  IncludeTrailingPathDelimiter(GetWindowsTempFolder) + ExtractFileName(application.ExeName) );
    RemoveReadOnlyFileAttribute(  IncludeTrailingPathDelimiter(GetWindowsTempFolder) + str_Ini_FileName );

    ShellExec(0, 'open', IncludeTrailingPathDelimiter(GetWindowsTempFolder) + ExtractFileName(application.ExeName), Parameters,  IncludeTrailingPathDelimiter(GetWindowsTempFolder), SW_SHOWNORMAL);
  end
  else
  begin
    ShowMessage(str_Temp_Folder_Write_Error);
  end;
end;

function MatchNameToMountPoint(Name: string): string;
var
  i, DrivesCount: integer;
  Ejector: TDriveEjector;
begin
  result:='';

  Ejector:=TDriveEjector.Create;
  try
    DrivesCount:=Ejector.DrivesCount;
    if DrivesCount = 0 then exit;

    if Name[1] = '*' then  //wildcard - partial name match
    begin
      for I := 0 to DrivesCount -1 do
      begin
        if pos(Uppercase(copy(Name, 2, length(name) - 1 )), Trim(Uppercase(Ejector.RemovableDrives[i].VendorId) + ' ' + Trim(Uppercase(Ejector.RemovableDrives[i].ProductID)))) <> 0 then //found
        begin
          result:=Ejector.RemovableDrives[i].DriveMountPoint;
          break;
        end;
      end;
    end
    else
    for I := 0 to DrivesCount -1 do
    begin
      if Uppercase(Name) = Trim(Uppercase(Ejector.RemovableDrives[i].VendorId) + ' ' + Trim(Uppercase(Ejector.RemovableDrives[i].ProductID))) then
        result:=Ejector.RemovableDrives[i].DriveMountPoint;
    end;
  finally
    Ejector.free;
  end;
end;

function MatchNameToMountPoint(Name: string; Ejector: TDriveEjector): string;
var
  i, DrivesCount: integer;
begin
  result:='';

  if Ejector = nil then exit;

  DrivesCount:=Ejector.DrivesCount;
  if DrivesCount = 0 then exit;

  if Name[1] = '*' then  //wildcard - partial name match
  begin
    for I := 0 to DrivesCount -1 do
    begin
      if pos(Uppercase(copy(Name, 2, length(name) - 1 )), Trim(Uppercase(Ejector.RemovableDrives[i].VendorId) + ' ' + Trim(Uppercase(Ejector.RemovableDrives[i].ProductID)))) <> 0 then //found
      begin
        result:=Ejector.RemovableDrives[i].DriveMountPoint;
        break;
      end;
    end;
  end
  else
  for I := 0 to DrivesCount -1 do
  begin
    if Uppercase(Name) = Trim(Uppercase(Ejector.RemovableDrives[i].VendorId) + ' ' + Trim(Uppercase(Ejector.RemovableDrives[i].ProductID))) then
      result:=Ejector.RemovableDrives[i].DriveMountPoint;
  end;
end;

function MatchLabelToMountPoint(DiskLabel: string): string;
var
  i, DrivesCount: integer;
  Ejector: TDriveEjector;
begin
  result:='';

  Ejector:=TDriveEjector.Create;
  try
    DrivesCount:=Ejector.DrivesCount;
    if DrivesCount = 0 then exit;

    if DiskLabel[1] = '*' then  //wildcard - partial name match
    begin
      for I := 0 to DrivesCount -1 do
      begin
        if pos(Uppercase(copy(DiskLabel, 2, length(DiskLabel) - 1 )), Trim(Uppercase(Ejector.RemovableDrives[i].VolumeLabel))) <> 0 then //found
        begin
          result:=Ejector.RemovableDrives[i].DriveMountPoint;
          break;
        end;
      end;
    end
    else
    for I := 0 to DrivesCount -1 do
    begin
      if Uppercase(DiskLabel) = Trim(Uppercase(Ejector.RemovableDrives[i].VolumeLabel)) then
        result:=Ejector.RemovableDrives[i].DriveMountPoint;
    end;
  finally
    Ejector.free;
  end;
end;

function MatchLabelToMountPoint(DiskLabel: string; Ejector: TDriveEjector): string;
var
  i, DrivesCount: integer;
begin
  result:='';

  if Ejector = nil then exit;

  DrivesCount:=Ejector.DrivesCount;
  if DrivesCount = 0 then exit;

  if DiskLabel[1] = '*' then  //wildcard - partial name match
  begin
    for I := 0 to DrivesCount -1 do
    begin
      if pos(Uppercase(copy(DiskLabel, 2, length(DiskLabel) - 1 )), Trim(Uppercase(Ejector.RemovableDrives[i].VolumeLabel))) <> 0 then //found
      begin
        result:=Ejector.RemovableDrives[i].DriveMountPoint;
        break;
      end;
    end;
  end
  else
  for I := 0 to DrivesCount -1 do
  begin
    if Uppercase(DiskLabel) = Trim(Uppercase(Ejector.RemovableDrives[i].VolumeLabel)) then
      result:=Ejector.RemovableDrives[i].DriveMountPoint;
  end;
end;

function GetTaskBarHeight: integer;
var
  hTB: HWND; //taskbar handle
  TBRect: TRect; //taskbar rectangle
begin
  hTB:= FindWindow('Shell_TrayWnd', '');
  if hTB = 0 then
    Result := 0
  else
  begin
    GetWindowRect(hTB, TBRect);
    Result := TBRect.Bottom - TBRect.Top;
  end;
end;

function GetTaskBarWidth: integer;
var
  hTB: HWND; //taskbar handle
  TBRect: TRect; //taskbar rectangle
begin
  hTB:= FindWindow('Shell_TrayWnd', '');
  if hTB = 0 then
    Result := 0
  else
  begin
    GetWindowRect(hTB, TBRect);
    Result := TBRect.right - TBRect.left;
  end;
end;

function IsTaskbarAutoHideOn: Boolean;
var
  ABData: TAppBarData;
begin
  ABData.cbSize := SizeOf(ABData);
  Result := (SHAppBarMessage(ABM_GETSTATE, ABData) and ABS_AUTOHIDE) > 0;
end;

function GetTaskBarPos: TTaskBarPos;
var
  hTaskbar: HWND;
  T: TRect;
  scrW, scrH: integer;
begin
  hTaskBar := FindWindow('Shell_TrayWnd', nil);
  if hTaskbar <> 0 then
  begin
    GetWindowRect(hTaskBar, T);
    ScrW := Screen.Width;
    ScrH := Screen.Height;
    if (T.Top > scrH div 2) and (T.Right >= scrW) then
      Result := _BOTTOM
    else
    if (T.Top < scrH div 2) and (T.Bottom <= scrW div 2) then
      Result := _TOP
    else
    if (T.Left < scrW div 2) and (T.Top <= 0) then
      Result := _LEFT
    else // the last "if" is not really needed
    if T.Left >= ScrW div 2 then
      Result := _RIGHT
    else
      Result := _NONE;
  end
  else
    Result := _NONE;
end;

function ConvertDriveLetterToMountpoint(
  DriveLetter: string): string;
var
  UpperDrive: string;
begin
  result := '';
  if DriveLetter = '' then exit;

  UpperDrive := Uppercase( DriveLetter[1] );
  if not ( CharInSet(UpperDrive[1], ['A'..'Z']) ) then exit;

  Result := UpperDrive + ':\';
end;

function ConvertMountPointToDriveLetter(
  MountPoint: string): string;
begin
  result := '';
  if MountPoint = '' then exit;

  Result := Uppercase( MountPoint[1] );
end;

function BalloonTipsEnabled: boolean;
begin
  try
    if RegReadDWord( HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced', 'EnableBalloonTips' ) = 0 then
      result := false
    else
      result := true;
  except on EJCLRegistryError do
    result := true;
  end;
end;

function IsWindowsVistaOrLater : Boolean;
const
  Condition = VER_GREATER_EQUAL;
var
  OSInfo : TOSVersionInfoEx;
  ConditionMask : Int64;
begin
  ZeroMemory(@OsInfo, sizeof(OSInfo));
  OSInfo.dwOSVersionInfoSize := SizeOf(OSInfo);
  OSInfo.dwMajorVersion := 6;
  OSInfo.dwMinorVersion := 0;
  OSInfo.wServicePackMajor := 0;
  OSInfo.wServicePackMinor := 0;

  ConditionMask := 0;
  ConditionMask := VerSetConditionMask(ConditionMask, VER_MAJORVERSION, Condition);
  ConditionMask := VerSetConditionMask(ConditionMask, VER_MINORVERSION, Condition);
  ConditionMask := VerSetConditionMask(ConditionMask, VER_SERVICEPACKMAJOR, Condition);
  ConditionMask := VerSetConditionMask(ConditionMask, VER_SERVICEPACKMINOR, Condition);

  result := VerifyVersionInfo(OSInfo, VER_MAJORVERSION or VER_MINORVERSION or
     VER_SERVICEPACKMAJOR or VER_SERVICEPACKMINOR,
     ConditionMask);
end;

function FindMountPoint(Directory: string): string;
var
  CurrPath: string;
  Attributes: cardinal;
begin
  result := '';
  {See IsAppRunningFromThisLocation for full explanation.
   Need to walk up the folders testing if each is a mountpoint as we go}
  CurrPath := IncludeTrailingPathDelimiter( Directory );
  while CurrPath <> '' do
  begin
    Attributes := GetFileAttributes( PChar(CurrPath) );
    if ( (Attributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0 )  //its a mountpoint
    or ( length( CurrPath ) = 2 )  then //or its a drive letter
    begin
      result :=  IncludeTrailingPathDelimiter( CurrPath );
      break;
    end;

    if length(CurrPath) <= 2 then //at the root - escape
      break;

    //Otherwise get the parent folder
    CurrPath := ExtractFilePath( ExcludeTrailingPathDelimiter( CurrPath ) );
  end;

end;

function IsAppRunningFromThisLocation(MountPoint: string): boolean;
var
  CurrPath: string;
  Attributes: cardinal;
  CurrentVolumeName, SearchVolumeName: array[0..MAX_PATH] of Char;
begin
  result := false;
  {Cant just do ExtractFileDrive because the volume might be mounted in a folder
  on C. Also have to be careful because a drive might have more than one mountpoint.
  Could have a drive letter and be mounted in a folder. So we have to look at where
  the app is running from and walk up the folders, testing as we go if a folder
  is a mountpoint. If it is, then we find its volume identifier and see if thats
  the same volume identifier as the mountpoint we're trying to eject.}


  //Get the GUID volume name for the volume we're searching for
  GetVolumeNameForVolumeMountPoint( PChar(MountPoint), SearchVolumeName, MAX_PATH);

  //Need to walk up the folders testing if each is a mountpoint as we go
  CurrPath := ExtractFilePath(Application.ExeName);
  while CurrPath <> '' do
  begin
    Attributes := GetFileAttributes( PChar(CurrPath) );
    if ( (Attributes and FILE_ATTRIBUTE_REPARSE_POINT) <> 0 )  //its a mountpoint
    or ( length( CurrPath ) = 2 )  then //or its a drive letter
    begin
      //Get the GUID volume name for the mountpoint
      GetVolumeNameForVolumeMountPoint( PChar(IncludeTrailingPathDelimiter(CurrPath)), CurrentVolumeName, MAX_PATH);

      //ShowMessage( CurrentVolumeName) ;
      //Showmessage( SearchVolumeName);

      if string(CurrentVolumeName) = string(SearchVolumeName) then //the app is running off the same volume
      begin
        result := true;
        break;
      end;
    end;

    if length(CurrPath) <= 2 then //at the root
      break;

    //Otherwise get the parent folder
    CurrPath := ExtractFilePath( ExcludeTrailingPathDelimiter( CurrPath ) );
  end;

end;

end.

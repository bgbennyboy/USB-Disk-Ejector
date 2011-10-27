 {
******************************************************
  USB Disk Ejector
  Copyright (c) 2006 - 2011 Bgbennyboy
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

unit uProcessAndWindowUtils;

interface

uses Windows, Messages, sysutils, JCLSysInfo, JwaWindows, TlHelp32, classes, strutils;

function EnumWindowsAndCloseFunc (Handle: THandle; MountPoint: string): BOOL; stdcall;
function EnumChildWindowsAndCloseFunc (Handle: THandle; DriveString: string): BOOL; stdcall;
function CloseAppsRunningFrom(MountPoint: String; ForceClose: Boolean): boolean;
procedure ListAllHandleNames(DosDeviceName: string; OutList: TStringlist);
procedure FindOpenHandlesTest(MountPoint: string);

implementation

var
  TopWindow: hwnd;

{*****************************************************NEW TEST STUFF**********************}
//Match it to the dos device name! check that name with listusbdrives util - get handle or processid and close it!

procedure NTSetPrivilege(Privilege: string; Enabled: Boolean);
var
  Token: THandle;
  TokenPriv: TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
begin
  if OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, Token) then
    try
      if LookupPrivilegeValue(nil, PChar(Privilege), TokenPriv.Privileges[0].Luid) then
        begin
          TokenPriv.PrivilegeCount := 1;

          case Enabled of
            True: TokenPriv.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
            False: TokenPriv.Privileges[0].Attributes := 0;
          end;

          ReturnLength := 0;
          PrevTokenPriv := TokenPriv;

          AdjustTokenPrivileges(Token, False, @TokenPriv, SizeOf(PrevTokenPriv), @PrevTokenPriv, @ReturnLength);
      end;
    finally
      CloseHandle(Token);
    end;
end;

procedure ListAllHandleNames(DosDeviceName: string; OutList: TStringlist);
const
  MaximumHandleCount = 100000;
var
  Buffer : Pointer;
  MemoryNeeded : ULong;
  Unused : ULong;
  HandleInformation : PSystemHandleInformation;
  HandleCount : PULong;
  ObjectName : PObjectNameInformation;
  LocalHandle : THandle;
  ProcessHandle : THandle;
  ObjectString : string;
  i : Integer;
begin

  // Initialisierung
  MemoryNeeded := MaximumHandleCount * SizeOf(TSystemHandleInformation);

  // Handle Liste holen
  GetMem(Buffer, MemoryNeeded);
  if not NT_SUCCESS(NtQuerySystemInformation(SystemHandleInformation, Buffer, MemoryNeeded, nil)) then
    begin
      writeln('NtQuerySystemInformation fehlgeschlagen (Handle Array zu klein?).');
      FreeMem(Buffer);
      Exit;
    end;

  HandleCount := Buffer;
  HandleInformation := Pointer(LongWord(Buffer) + 4);
  for i := 0 to HandleCount^ - 1 do
    begin
      ProcessHandle := OpenProcess(PROCESS_DUP_HANDLE, false, HandleInformation^.ProcessId);
      if ProcessHandle <> 0 then
        begin
          // Spezielle Named Pipes machen Probleme bei der Abfrage. Diese Pipes haben
          // als Access Mask 0x12019F. Entsprechend werden nur Handles abgefragt, die
          // nicht 0x12019F als Access Mask haben.
          if HandleInformation^.GrantedAccess <> $12019F then
            begin
              GetMem(ObjectName, 65536);
              if DuplicateHandle(ProcessHandle, HandleInformation^.Handle, GetCurrentProcess(), @LocalHandle, 0, false, DUPLICATE_SAME_ACCESS) and (ObjectName^.Name.Buffer <> nil)then
                begin
                  if NT_SUCCESS(NtQueryObject(LocalHandle, ObjectNameInformation, ObjectName, 65536, @Unused)) and (ObjectName^.Name.Buffer <> nil) then
                    begin
                      ObjectString := LowerCase(WideString(ObjectName^.Name.Buffer));
                      //OutputDebugString(pChar((Format('Process: %.8x - Handle: %.8x ObjectName: %s', [HandleInformation^.ProcessId, HandleInformation^.Handle, ObjectString]))));

                      if AnsiContainsText(ObjectString, DosDeviceName) then
                        OutList.Add(Format('Process: %.8x - Handle: %.8x ObjectName: %s', [HandleInformation^.ProcessId, HandleInformation^.Handle, ObjectString]))

                    end;
                  CloseHandle(LocalHandle);
                end;
              FreeMem(ObjectName);
            end;
          CloseHandle(ProcessHandle);
        end;
      inc(HandleInformation);
    end;
  FreeMem(Buffer);
end;

procedure FindOpenHandlesTest(MountPoint: string);
var
  szDosDeviceName, VolumeName: array[0..MAX_PATH-1] of Char;
  funcResult, i: integer;
  szDevicePath, szVolumeAccessPath: string;
  FoundHandles: TStringList;
begin

  GetVolumeNameForVolumeMountPoint(pchar(MountPoint), VolumeName, MAX_PATH);
  szDevicePath:=ExcludeTrailingPathDelimiter( VolumeName );
  szVolumeAccessPath:=ExcludeTrailingPathDelimiter( VolumeName );
  szDevicePath:=Copy(szVolumeAccessPath, 5, length(szVolumeAccessPath) -4);
  szDosDeviceName[0]:=#0;

	//Get the dos device name
	funcResult := QueryDosDevice(PChar(szDevicePath), szDosDeviceName,  MAX_PATH);
  if funcResult = 0 then
  else
  OutputDebugString(pchar('OI!!!!!!!!!!!!!!!!!!!******************************************************* ' + szDosDeviceName));

  FoundHandles := TStringList.Create;
  try
    ListAllHandleNames(szDosDeviceName, FoundHandles);

    if FoundHandles.count > 0 then
    for I := 0 to FoundHandles.Count - 1 do
      OutputDebugString( PChar( FoundHandles[i] ));

  finally
    FoundHandles.Free;
  end;

end;
{*******************************************************************************************************************************************************}





{******************Close Explorer Windows For A Specified Drive****************}

function EnumChildWindowsAndCloseFunc(Handle: THandle;
  DriveString: string): BOOL;
var
  WindowText : array[0.. MAX_PATH - 1] of Char;
  FoundPos: integer;
begin
  PostMessage(Handle, WM_GETTEXT, sizeof(WindowText), integer(@WindowText[0]));

  FoundPos:= pos(DriveString, WindowText);
  if FoundPos > 0 then
  begin
    PostMessage (TopWindow, WM_CLOSE, 0, 0);
  end;

  Result:=true;
end;

function EnumWindowsAndCloseFunc(Handle: THandle;
  MountPoint: string): BOOL;
var
  WindowHandle: HWND;
  WindowName, WindowText: array[0..MAX_PATH] of Char;
  FoundPos: integer;
  DriveString: string;
begin
  //Build the search string
  DriveString:= ExcludeTrailingPathDelimiter ( MountPoint );

  //Get the window caption
  PostMessage(Handle, WM_GETTEXT, SizeOf(WindowName), integer(@WindowName[0]));

  //Look for CabinetWClass in all windows
  WindowHandle := FindWindow('CabinetWClass', WindowName);
  if WindowHandle > 0 then //Found an explorer window
  begin
    //Get its caption and see if its got drive letter in it
    GetWindowText(WindowHandle, WindowText, MAX_PATH);
    FoundPos:= pos(DriveString, WindowText);
    if Foundpos > 0 then
    begin
      PostMessage (WindowHandle, WM_CLOSE, 0, 0);
    end;

    //Search all its hidden child windows
    TopWindow:=WindowHandle;
    EnumChildWindows(WindowHandle, @EnumChildWindowsAndCloseFunc, LParam(DriveString));
  end;

  Result :=True;
end;




{*******************Close Apps Running From A Specified Drive******************}

Function InstanceToWnd( Const TgtPID:DWORD):HWND;
Var
  ThisHWnd :HWND;
  ThisPID :DWORD;
Begin
  Result := 0;
  ThisPID := 0;
  // Find the first Top Level Window
  ThisHWnd := FindWindow( Nil, Nil);
  ThisHWnd := GetWindow( ThisHWnd, GW_HWNDFIRST );
  While ThisHWnd <> 0 Do
  Begin
    //Check if the window isn't a child (redundant?)
    If GetParent( ThisHWnd ) = 0 Then
    Begin
      //Get the window's thread & ProcessId
      GetWindowThreadProcessId( ThisHWnd, Addr(ThisPID) );
      If ThisPID = TgtPID Then
      Begin
        Result := ThisHWnd;
        Break;
      End;
    End;
  // 'retrieve the next window
  ThisHWnd := GetWindow( ThisHWnd, GW_HWNDNEXT );
  End;
End;

procedure CloseWindowByID(ID: Cardinal);
var
  wind: hwnd;
begin
  wind:=InstanceToWnd(ID);
  if wind <> 0 then
  begin
    //postMessage (wind, WM_CLOSE, 0, 0);
    sendMessage (wind, WM_CLOSE, 0, 0); //wait to return
    sleep(3000);
  end;
end;

procedure TerminateProcessById(ID: Cardinal);
var
  HndProcess : THandle;
begin
  HndProcess := OpenProcess(PROCESS_TERMINATE,TRUE, ID);
  if HndProcess <> 0 then
  try
    TerminateProcess(HndProcess,0);
  finally
    CloseHandle(HndProcess);
  end;
end;

function GetProcessFileName(PID: DWORD): string;
var
  Handle: THandle;
begin
  Result := '';
  Handle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
  if Handle <> 0 then
    try
      SetLength(Result, MAX_PATH);
      begin
        if GetModuleFileNameEx(Handle, 0, PChar(Result), MAX_PATH) > 0 then
          SetLength(Result, StrLen(PChar(Result)))
        else
          Result := '';
      end
    finally
      CloseHandle(Handle);
    end;
end;

function KillAppsFromDrive_NT(DriveString: string; ForceClose: Boolean): Boolean;
const
  RsSystemIdleProcess = 'System Idle Process';
  RsSystemProcess = 'System Process';
var
  SnapProcHandle: THandle;
  ProcEntry: TProcessEntry32;
  NextProc: Boolean;
  FileName: string;
begin
  SnapProcHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  Result := (SnapProcHandle <> INVALID_HANDLE_VALUE);
  if Result then
    try
      ProcEntry.dwSize := SizeOf(ProcEntry);
      NextProc := Process32First(SnapProcHandle, ProcEntry);
      while NextProc do
      begin
        if ProcEntry.th32ProcessID = 0 then
        begin
          // PID 0 is always the "System Idle Process" but this name cannot be
          // retrieved from the system and has to be fabricated.
          FileName := RsSystemIdleProcess;
        end
        else
        begin
          if GetWindowsVersion >= wvWin2000 then //IsWin2k or IsWinXP then
          begin
            FileName := GetProcessFileName(ProcEntry.th32ProcessID);
            if FileName = '' then
              FileName := ProcEntry.szExeFile;
          end
          else
          begin
            FileName := ProcEntry.szExeFile;
          end;
        end;

        //If running from the drive - then close it
        if (ExtractFileDrive(Filename) = DriveString) or (Copy(FileName, 0, Length(DriveString)) = DriveString ) then
          if ForceClose then  
            TerminateProcessById(ProcEntry.th32ProcessID)
          else
            CloseWindowById(ProcEntry.th32ProcessID);

        NextProc := Process32Next(SnapProcHandle, ProcEntry);
      end;
    finally
      CloseHandle(SnapProcHandle);
    end;
end;

function CloseAppsRunningFrom(MountPoint: String; ForceClose: Boolean): boolean;
var
  DriveString: string;
begin
  result:=false;
  if GetWindowsVersion < wvWin2000 then exit;

  if length(MountPoint) > 1 then
    DriveString:=MountPoint
  else
  begin
    //Driveletter must be upper case
    MountPoint:=UpCase(MountPoint[1]);

    //Build the search string
    DriveString:=MountPoint + ':';
  end;

  result:=KillAppsFromDrive_NT(DriveString, ForceClose);
end;


end.

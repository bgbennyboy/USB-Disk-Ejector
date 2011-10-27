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

//TODO - rewrite with tlist instead of arrays

unit uDriveEjector;

interface

uses
  Classes, Windows, forms, SysUtils, extctrls,
  JwaWindows, jclsysinfo,
  uProcessAndWindowUtils, uDiskEjectConst;

type
  TRemovableDrive = packed record
    DriveMountPoint: string;
    VolumeLabel: string;
    VendorId: string;
    ProductID: string;
    ProductRevision: string;
    IsCardReader: boolean;
    HasSiblings: boolean;
    CardMediaPresent: boolean;
    BusType: integer;
    ParentDevInst: integer;
  end;

  TDriveEjector = class
  private
    PollTimer: TTimer;
    FOnCardMediaChanged: TNotifyEvent;
    FPollTimerInterval: cardinal;
    FPolling: boolean;
    FBusy: boolean;
    FOnDrivesChanged:TNotifyEvent;

    function GetDrivesCount: integer;
    function GetBusy: boolean;
    function GetDrivesDevInstByDeviceNumber(DeviceNumber: Integer; DriveType: UINT; szDosDeviceName: PCHAR): DEVINST;
    function EjectDevice(MountPoint: string; var EjectErrorCode: integer; ShowEjectMessage: boolean = false): boolean;
    function EjectCard(MountPoint: string; var EjectErrorCode: integer): boolean;
    function GetParentDriveDevInst(MountPoint: string; var ParentInstNum: integer): boolean;
    function GetNoDevicesWithSameParentInst(ParentDevInst: integer): integer;
    function GetNoDevicesWithSameProductId(ProductId: string): integer;
    function CheckIfDriveHasMedia(MountPoint: string): boolean;
    function GetCardPolling: boolean;
    procedure SetCardPolling(Value: boolean);
    function GetCardPollingInterval: cardinal;
    procedure SetCardPollingInterval(value: cardinal);
    procedure FindRemovableDrives;
    procedure ScanDrive(GUIDVolumeName: String);

    procedure CheckForCardReaders;
    procedure CheckForSiblings;
    procedure OnTimer (Sender:TObject);
    procedure SetBusy(const Value: boolean);
    procedure DeleteFromDrivesArray(const Index: Cardinal);
  public
    RemovableDrives: array of TRemovableDrive;
    constructor Create;
    destructor Destroy; override;
    function RemoveDrive(MountPoint: string; var EjectErrorCode: integer; ShowEjectMessage: boolean = false; CardEject: boolean = false; CloseRunningApps: boolean = false; ForceRunningAppsClosure: boolean = false): boolean; overload;
    procedure RescanAllDrives;
    procedure ClearDriveList;
    procedure SetDriveAsCardReader(Index: Integer; CardReader: boolean);

    property DrivesCount: integer read GetDrivesCount;
    property OnCardMediaChanged: TNotifyEvent read FOnCardMediaChanged write FOnCardMediaChanged;
    property CardPollingInterval: cardinal read GetCardPollingInterval write SetCardPollingInterval;
    property CardPolling: boolean read GetCardPolling write SetCardPolling;
    property Busy: boolean read GetBusy write SetBusy;
    property OnDrivesChanged: TNotifyEvent read FOnDrivesChanged write FOnDrivesChanged;
  end;

  TEventsThread = class(TThread)
  private
    fEjector: TDriveEjector;
  protected
    procedure Execute; override;
  public
    constructor Create(Ejector: TDriveEjector);
  end;

implementation


var
  fPrevWndProc: TFNWndProc = nil;
  fChangeMessageCount: integer = 0;
  CriticalSection: TCriticalSection;
  EventsThread: TEventsThread;
  GetVolumePathNamesForVolumeNameW: Function(VolumeName, VolumePathNames: PWideChar;
      BufferLength: LongWord; ReturnLength: PLongWord): LongBool; StdCall;


{--------------------------Windows 2000 workaround-----------------------------}
//This workaround by htmisu
//http://www.delphipraxis.net/topic89088.html
Function _GetVolumePathNamesForVolumeNameW(VolumeName, VolumePathNames: PWideChar; BufferLength: LongWord; ReturnLength: PLongWord): LongBool; StdCall;
Var
  LogicalDriveStrings, SearchBuffer, ResultS: WideString;
  ResultBuffer: Array[0..MAX_PATH-1] of WideChar;

  Procedure SearchRecursiv(Const SearchBuffer2: WideString);
  Var
    SearchHandle: THandle;
    SearchBuffer3: WideString;

  Begin
    SearchHandle := FindFirstVolumeMountPointW(@ResultBuffer, @ResultBuffer, MAX_PATH);
    If SearchHandle = INVALID_HANDLE_VALUE Then Exit;
    Repeat
      SearchBuffer3 := SearchBuffer2 + ResultBuffer;
      If GetVolumeNameForVolumeMountPointW(PWideChar(SearchBuffer3), @ResultBuffer, MAX_PATH) Then
      Begin
        If CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, VolumeName, -1, @ResultBuffer, -1) = 2 Then
          ResultS := ResultS + Copy(SearchBuffer3, 5, MAX_PATH) + #0;
          SearchRecursiv(SearchBuffer3);
      End;
    Until not FindNextVolumeMountPointW(SearchHandle, @ResultBuffer, MAX_PATH);

    FindVolumeMountPointClose(SearchHandle);
  End;

  Begin
    ResultS := '';
    SetLength(LogicalDriveStrings, GetLogicalDriveStringsW(0, nil));
    GetLogicalDriveStringsW(255, @LogicalDriveStrings[1]);
    LogicalDriveStrings := Trim(LogicalDriveStrings);
    While LogicalDriveStrings <> '' do
    Begin
      SearchBuffer := '\\.\' + PWideChar(LogicalDriveStrings);
      System.Delete(LogicalDriveStrings, 1, Length(SearchBuffer) - 4);
      LogicalDriveStrings := TrimLeft(LogicalDriveStrings);
      If (SearchBuffer[5] <= 'B') and (SearchBuffer[6] = ':') Then
        Continue;
      If GetVolumeNameForVolumeMountPointW(PWideChar(SearchBuffer), @ResultBuffer, MAX_PATH) Then
      Begin
        If CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, VolumeName, -1, @ResultBuffer, -1) = 2 Then
          ResultS := ResultS + Copy(SearchBuffer, 5, MAX_PATH) + #0;
        SearchRecursiv(SearchBuffer);
      End;
    End;

    ResultS := ResultS + #0;
    If (BufferLength >= LongWord(Length(ResultS))) and (VolumePathNames <> nil) Then
    Begin
      Move(ResultS[1], VolumePathNames^, 2*Length(ResultS));
      If ReturnLength <> nil Then
        ReturnLength^ := Length(ResultS);
      Result := True;
    End
    Else
    If (BufferLength = 0) and (VolumePathNames = nil) Then
    Begin
      If ReturnLength <> nil Then
        ReturnLength^ := Length(ResultS);
      Result := True;
    End
    Else
    Begin
      If VolumePathNames <> nil Then
        VolumePathNames^ := #0;
      If ReturnLength <> nil Then
        ReturnLength^ := 1;

       Result := False;
    End;
  End;
{-----------------------------------------------------------------------------}


{------------------------Hook events in dummy window--------------------------}
function UsbWndProc(hWnd: HWND; Msg: UINT; wParam, lParam: Longint): Longint; stdcall;
begin
  Result := CallWindowProc(fPrevWndProc, hWnd, Msg, wParam, lParam);

  if (Msg = WM_DEVICECHANGE) and
      (((wParam = DBT_DEVICEARRIVAL) and
      (PDevBroadcastHeader(lParam).dbcd_devicetype = DBT_DEVTYP_VOLUME)) or
      (wParam = DBT_DEVICEREMOVECOMPLETE)) then
    begin
      EnterCriticalSection(CriticalSection);
      inc(fChangeMessageCount);
      LeaveCriticalSection(CriticalSection);
      if EventsThread.Suspended then EventsThread.Resume;
    end;
end;

{-----------------------------------------------------------------------------}

//Event thread
constructor TEventsThread.Create(Ejector: TDriveEjector);
begin
  fEjector:=Ejector;
  inherited create(false);
end;

procedure TEventsThread.Execute;
begin
  while not terminated do
  begin
    if self.Terminated then break;

    if (fChangeMessageCount > 0) and (fEjector.Busy = false) then
    begin
      sleep(500);  //gives extra time for devices with multi volumes/partitions - sometimes theres only 1 message but it takes a moment for windows to mount both partitions
      EnterCriticalSection(CriticalSection);
      fChangeMessageCount:=0; //set it back to 0 because we're about to scan
      LeaveCriticalSection(CriticalSection);
      fEjector.RescanAllDrives;
      //messagebeep(0);
    end
    else
      self.Suspend;
  end;
end;

{-----------------------------------------------------------------------------}

constructor TDriveEjector.Create;
begin
  LoadSetupApi;
  LoadConfigManagerApi;

  PollTimer:=TTimer.Create(nil);
  fPolling:=false;
  PollTimer.OnTimer:=OnTimer;
  fPollTimerInterval:=5000;
  PollTimer.Interval:=fPollTimerInterval;

  //Setup dummy window to catch messages
  if not Assigned(fPrevWndProc) then
  begin
    fPrevWndProc := TFNWndProc(GetWindowLong(Application.Handle, GWL_WNDPROC));
    SetWindowLong(Application.Handle, GWL_WNDPROC, LongInt(@UsbWndProc));
  end;

  InitializeCriticalSection(CriticalSection);

  fBusy := false;
  //Create a thread to keep polling fChangeMessageCount
  EventsThread:=TEventsThread.Create(self);

  FindRemovableDrives;
//  FindOpenHandlesTest( RemovableDrives[0].DriveMountPoint);
end;

destructor TDriveEjector.Destroy;
begin
  EventsThread.Terminate;
  if EventsThread.Suspended then EventsThread.Resume;
  EventsThread.Free;

  DeleteCriticalSection(CriticalSection);

  PollTimer.free;
  SetLength(RemovableDrives, 0);

  UnloadConfigManagerApi;
  UnloadSetupApi;
  inherited;
end;

procedure TDriveEjector.DeleteFromDrivesArray(const Index: Cardinal);
var
  ALength: Cardinal;
  TailElements: Cardinal;
begin
  ALength := Length(RemovableDrives);
  Assert(ALength > 0);
  Assert(Index < ALength);
  Finalize(RemovableDrives[Index]);
  TailElements := ALength - Index;

  if TailElements > 0 then
    Move(RemovableDrives[Index + 1], RemovableDrives[Index], SizeOf(TRemovableDrive) * TailElements);

  Initialize(RemovableDrives[ALength - 1]);
  SetLength(RemovableDrives, ALength - 1);
end;


procedure TDriveEjector.FindRemovableDrives;
var
  FindRec: cardinal;
  VolumeUniqueName: array[0..MAX_PATH] of Char;
begin
  SetBusy(true);
  SetLength(RemovableDrives, 0);

  FindRec := FindFirstVolume(VolumeUniqueName, MAX_PATH);
  while FindRec <> INVALID_HANDLE_VALUE do
  begin
    ScanDrive(VolumeUniqueName);

    if not (FindNextVolume(FindRec, VolumeUniqueName, MAX_PATH)) then
      break;
  end;
  FindVolumeClose(FindRec);

  SetBusy(false);

  //Finally check if any are card readers
  CheckForCardReaders;

  //Check if it has siblings (multiple partitions but 1 drive)
  CheckForSiblings;

  {--------------------------------------------------------------------------------------}
  //HACK - delete card readers
  {for i := DrivesCount - 1 downto 0 do
  begin
    if RemovableDrives[i].IsCardReader then
      DeleteFromDrivesArray(i);
  end;}
  {--------------------------------------------------------------------------------------}


  if assigned(FOnDrivesChanged) then
    FOnDrivesChanged(nil);
end;

procedure TDriveEjector.ScanDrive(GUIDVolumeName: String);
type
  PCharArray = ^TCharArray;
  TCharArray = array[0..32767] of AnsiChar;

STORAGE_PROPERTY_QUERY = packed record
  PropertyId: DWORD;
  QueryType: DWORD;
  AdditionalParameters: array[0..3] of Byte;
end;

STORAGE_DEVICE_DESCRIPTOR = packed record
  Version: ULONG;
  Size: ULONG;
  DeviceType: Byte;
  DeviceTypeModifier: Byte;
  RemovableMedia: Boolean;
  CommandQueueing: Boolean;
  VendorIdOffset: ULONG;
  ProductIdOffset: ULONG;
  ProductRevisionOffset: ULONG;
  SerialNumberOffset: ULONG;
  STORAGE_BUS_TYPE: DWORD;
  RawPropertiesLength: ULONG;
  RawDeviceProperties: array[0..511] of Byte;
end;

const
  IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;
var
  Returned, FFileHandle, MaxCompLen, FSFlags, ReturnLength: Cardinal;
  DriveBuf, VolumeName: array[0..MAX_PATH] of Char;
  Status: LongBool;
  PropQuery: STORAGE_PROPERTY_QUERY;
  DeviceDescriptor: STORAGE_DEVICE_DESCRIPTOR;
  PCh: PAnsiChar;
  Inst: integer;
  DriveMountPoint: string;
begin
  FFileHandle:=INVALID_HANDLE_VALUE;
  try
    FFileHandle := CreateFile(
                     PChar( ExcludeTrailingPathDelimiter(GUIDVolumeName) ),
                     0,
                     FILE_SHARE_READ or FILE_SHARE_WRITE,
                     nil,
                     OPEN_EXISTING,
                     0,
                     0
                   );

    if FFileHandle = INVALID_HANDLE_VALUE then exit;

    ZeroMemory(@PropQuery, SizeOf(PropQuery));
    ZeroMemory(@DeviceDescriptor, SizeOf(DeviceDescriptor));
    DeviceDescriptor.Size := SizeOf(DeviceDescriptor);

    Status := DeviceIoControl(
                FFileHandle,
                IOCTL_STORAGE_QUERY_PROPERTY,
                @PropQuery,
                SizeOf(PropQuery),
                @DeviceDescriptor,
                DeviceDescriptor.Size,
                @Returned,
                nil
              );

    if not Status then exit;

    if DeviceDescriptor.STORAGE_BUS_TYPE <= 0 then exit;

    if (DeviceDescriptor.STORAGE_BUS_TYPE = 7) or
       (DeviceDescriptor.STORAGE_BUS_TYPE = 4) then  //7 is USB, 4 is firewire
        SetLength(RemovableDrives, length(RemovableDrives) + 1) //enlarge the array for another item
    else
      exit;


    //Error handling needed here  - use SysErrorMessage  to return string of error
    Status:=GetVolumeInformation(PChar(GUIDVolumeName), VolumeName, MAX_PATH,
                            nil, MaxCompLen, FSFlags, nil, 0);
    if not Status then VolumeName := ''; //exit; //getlasterror;
    //outputdebugstring(pansichar(inttostr(getlasterror)));

    Status:=GetVolumePathNamesForVolumeNameW(PChar(GUIDVolumeName), DriveBuf,
                                            MAX_PATH, @ReturnLength);
    if not Status then exit; //getlasterror;
    //outputdebugstring(pansichar(inttostr(getlasterror)));

    //Drivebuf is length of drive string + 2 trailing #0's - can be more than one separated by null
    //The list is an array of null-terminated strings terminated by an additional NULL character
    //Eg g:\00
    //Eg c:\my_usb_stick_mountpoint00

    {if temp = 5 then //Drive letter
      DriveMountPoint:=DriveBuf[0]
    else}            //Mount point
    DriveMountPoint:=trim( copy(DriveBuf, 0, ReturnLength) );

    //Drive Letter
    RemovableDrives[high(RemovableDrives)].DriveMountPoint := DriveMountPoint;

    //Volume Name                                                 
    RemovableDrives[high(RemovableDrives)].VolumeLabel :=VolumeName;

    //Vendor Id
    if DeviceDescriptor.VendorIdOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.VendorIdOffset];
      RemovableDrives[high(RemovableDrives)].VendorId := Trim(String(Pch));
    end;

    //Product Id
    if DeviceDescriptor.ProductIdOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductIdOffset];
      RemovableDrives[high(RemovableDrives)].ProductID := Trim(String(PCh));
    end;

    //Product Revision
    if DeviceDescriptor.ProductRevisionOffset <> 0 then
    begin
      PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductRevisionOffset];
      RemovableDrives[high(RemovableDrives)].ProductRevision := Trim(String(PCh));
    end;

    //Is Card Reader   //This is checked and changed later
    RemovableDrives[high(RemovableDrives)].IsCardReader := false;

    //Has siblings  //This is checked and changed later
    RemovableDrives[high(RemovableDrives)].HasSiblings := false;

    //Does Card Reader have media in it?
    if CheckIfDriveHasMedia(DriveMountPoint) then
      RemovableDrives[high(RemovableDrives)].CardMediaPresent:=true
    else
      RemovableDrives[high(RemovableDrives)].CardMediaPresent:=false;

    //Bus Type
    RemovableDrives[high(RemovableDrives)].BusType:= DeviceDescriptor.STORAGE_BUS_TYPE;

    //Parents Device Instance
    if GetParentDriveDevInst(DriveMountPoint, Inst) then
      RemovableDrives[high(RemovableDrives)].ParentDevInst:=Inst;

  finally
    if FFileHandle <> INVALID_HANDLE_VALUE then CloseHandle(FFileHandle);
  end;
end;

function TDriveEjector.GetBusy: boolean;
begin
  result := fBusy;
end;

function TDriveEjector.GetCardPolling: boolean;
begin
  result:=fPolling;
end;

function TDriveEjector.GetCardPollingInterval: cardinal;
begin
  result := FPollTimerInterval;
end;

procedure TDriveEjector.SetBusy(const Value: boolean);
begin
  fBusy := Value;
end;

procedure TDriveEjector.SetCardPolling(Value: boolean);
begin
  fPolling:=Value;
  PollTimer.Enabled:=fPolling;
end;

procedure TDriveEjector.SetCardPollingInterval(value: cardinal);
begin
  FPollTimerInterval := Value;
  PollTimer.Interval:=fPollTimerInterval;
end;

procedure TDriveEjector.SetDriveAsCardReader(Index: Integer; CardReader: boolean);
begin
  RemovableDrives[Index].IsCardReader := CardReader;
end;

function TDriveEjector.GetDrivesCount: integer;
begin
  if fBusy then
  while fBusy = true do
  begin
  end;

  result:=Length(RemovableDrives);
end;

//This version returns an error code on failure
function TDriveEjector.RemoveDrive(MountPoint: string;
  var EjectErrorCode: integer; ShowEjectMessage, CardEject, CloseRunningApps, ForceRunningAppsClosure: boolean): boolean;
var
  DriveIndex, i: integer;
begin
  result:=false;
  EjectErrorCode:=REMOVE_ERROR_NONE;
  DriveIndex:=-1;

  //First find the MountPoint
  if DrivesCount = 0 then
  begin
    EjectErrorCode:=REMOVE_ERROR_DRIVE_NOT_FOUND;
    exit;
  end;

  for I := 0 to DrivesCount - 1 do
  begin
    if RemovableDrives[i].DriveMountPoint=MountPoint then
    begin
      DriveIndex:=i;
      break;
    end;
  end;

  if DriveIndex <> -1 then
  begin
    //First try and close explorer windows
    EnumWindows(@EnumWindowsAndCloseFunc, LParam(MountPoint));
    //Then try and close any programs that might be running from the drive
    if CloseRunningApps then
      CloseAppsRunningFrom(MountPoint, ForceRunningAppsClosure);


    //CHECK - stop card style eject if device isnt a card
    if RemovableDrives[DriveIndex].IsCardReader = false then
      CardEject:=false;

    if CardEject then //keep the card reader device - eject the media
    begin
      if EjectCard(MountPoint, EjectErrorCode) then
      begin
        RemovableDrives[i].CardMediaPresent:=false;
        result:=true
      end;
    end
    else
    if EjectDevice(MountPoint, EjectErrorCode, ShowEjectMessage) then
    begin
      //DeleteArrayItem(DriveIndex);  //On devices with multiple partitions only 1 item would get deleted
      FindRemovableDrives;
      result:=true;
    end;
  end
  else
    EjectErrorCode:=REMOVE_ERROR_DRIVE_NOT_FOUND;

end;

procedure TDriveEjector.RescanAllDrives;
begin
  FindRemovableDrives;
end;

procedure TDriveEjector.ClearDriveList;
begin
  SetLength(RemovableDrives, 0);
end;

procedure TDriveEjector.CheckForCardReaders;
var
  i: integer;
begin
  if DrivesCount = 0 then exit;

  for i := 0 to DrivesCount - 1 do
  begin
    if GetNoDevicesWithSameParentInst(RemovableDrives[i].ParentDevInst) > 1 then
      if GetNoDevicesWithSameProductID(RemovableDrives[i].ProductId) > 1 then //Hard drive partitions
        RemovableDrives[i].IsCardReader:=False
      else
        RemovableDrives[i].IsCardReader:=True //Matching devices with parent inst but differing device names are likely to be card readers
  end;
end;

procedure TDriveEjector.CheckForSiblings;
var
  i: integer;
begin
  for I := 0 to DrivesCount - 1 do
  begin
    if GetNoDevicesWithSameParentInst(RemovableDrives[i].ParentDevInst) > 0 then
      if GetNoDevicesWithSameProductID(RemovableDrives[i].ProductId) > 0 then //Hard drive partitions
        RemovableDrives[i].HasSiblings := true
      else
        RemovableDrives[i].HasSiblings := false;
  end;

end;

function TDriveEjector.CheckIfDriveHasMedia(MountPoint: string): boolean;
var
  Returned, DriveHandle: cardinal;
  VolumeName: array[0..MAX_PATH-1] of Char;
begin
  result:=false;

  GetVolumeNameForVolumeMountPoint(pchar(MountPoint), VolumeName, MAX_PATH);

                            //GENERIC_READ or GENERIC_WRITE
  DriveHandle := CreateFile(PChar(ExcludeTrailingPathDelimiter( VolumeName )),
                          FILE_READ_ATTRIBUTES,
                          FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  try
    if DeviceIoControl(DriveHandle, IOCTL_STORAGE_CHECK_VERIFY2, nil, 0, nil, 0, @Returned, nil) then
      result:=true; //Card is in reader

  finally
    CloseHandle(Drivehandle);
  end;
end;

function TDriveEjector.EjectCard(MountPoint: string; var EjectErrorCode: integer): boolean;
var
  Returned, DriveHandle: cardinal;
  VolumeName: array[0..MAX_PATH-1] of Char;
begin
  result:=false;

  GetVolumeNameForVolumeMountPoint(pchar(MountPoint), VolumeName, MAX_PATH);

  DriveHandle := CreateFile(PChar(ExcludeTrailingPathDelimiter( VolumeName )),
                          GENERIC_READ or GENERIC_WRITE,
                          FILE_SHARE_READ or FILE_SHARE_WRITE,  nil, OPEN_EXISTING, 0, 0);
  try
    if DriveHandle = INVALID_HANDLE_VALUE then
    begin
      if GetLastError = 32 then
        EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE
      else
        EjectErrorCode:=REMOVE_ERROR_UNKNOWN_ERROR;

      exit;
    end;

    if DeviceIoControl(DriveHandle, IOCTL_STORAGE_CHECK_VERIFY2, nil, 0, nil, 0, @Returned, nil) = false then
    begin
      EjectErrorCode:=REMOVE_ERROR_NO_CARD_MEDIA;
      exit; //No card in reader
    end;


    result:=DeviceIoControl(Drivehandle, IOCTL_STORAGE_EJECT_MEDIA, nil, 0, nil, 0, @Returned, nil);

    if result=false then
    begin
      if GetLastError = 32 then
        EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE
      else
        EjectErrorCode:=REMOVE_ERROR_UNKNOWN_ERROR;
    end;
    
  finally
    CloseHandle(Drivehandle);
  end;
end;

function TDriveEjector.EjectDevice(MountPoint: string; var EjectErrorCode: integer; ShowEjectMessage: boolean = false): boolean;
var
  szRootPath, szDevicePath, szVolumeAccessPath: string;
  dwBytesReturned: DWord;
  DriveType: UINT;
  hVolume: THandle;
  SDN: STORAGE_DEVICE_NUMBER;
  funcResult, tries, DeviceNumber: integer;
  funcResultBool: boolean;
  DeviceInst, DevInstParent: DEVINST;
  szDosDeviceName, VetoNameW, VolumeName: array[0..MAX_PATH-1] of Char;
  VetoType: PNP_VETO_TYPE;
begin
  Result:=false;

  GetVolumeNameForVolumeMountPoint(pchar(MountPoint), VolumeName, MAX_PATH);
  szRootPath:=VolumeName;
  szDevicePath:=ExcludeTrailingPathDelimiter( VolumeName );
  szVolumeAccessPath:=ExcludeTrailingPathDelimiter( VolumeName );
  szDevicePath:=Copy(szVolumeAccessPath, 5, length(szVolumeAccessPath) -4);
  DeviceNumber:=-1;

  hVolume:=INVALID_HANDLE_VALUE;
  try
    //Open the storage volume
    hVolume:=CreateFile(PChar(szVolumeAccessPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if hVolume = INVALID_HANDLE_VALUE then
    begin
      if GetLastError = 32 then
        EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE
      else
        EjectErrorCode:=REMOVE_ERROR_UNKNOWN_ERROR;

      exit;
    end;


    //Get the volume's device number
    dwBytesReturned:=0;
    funcResultBool:=DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @SDN, SizeOf(SDN), @dwBytesReturned, nil);
    if funcResultBool = true  then
      DeviceNumber:=SDN.DeviceNumber;

  finally
    CloseHandle(hVolume);
  end;

  if DeviceNumber = -1 then
  begin
    EjectErrorCode:=REMOVE_ERROR_WINAPI_ERROR;
    exit;
  end;
    

	//Get the drive type
	DriveType := GetDriveType(PChar(szRootPath));
  szDosDeviceName[0]:=#0;

	//Get the dos device name (like \deviceloppy0)
	funcResult := QueryDosDevice(PChar(szDevicePath), szDosDeviceName,  MAX_PATH);
	if funcResult = 0 then
  begin
    EjectErrorCode:=REMOVE_ERROR_WINAPI_ERROR;
    exit;
  end;
    

	//Get the device instance handle of the storage volume through a SetupDi enum and matching the device number
	DeviceInst:= GetDrivesDevInstByDeviceNumber(DeviceNumber, DriveType, szDosDeviceName);
	if ( DeviceInst = 0 ) then
  begin
    EjectErrorCode:=REMOVE_ERROR_WINAPI_ERROR;
    exit;
  end;
    

	VetoType := PNP_VetoTypeUnknown;
	VetoNameW[0] := #0;

	//Get drives's parent - this is what gets ejected
	DevInstParent := 0;
	CM_Get_Parent(DevInstParent, DeviceInst, 0);

  //Try and eject 3 times
  for tries := 0 to 2 do
  begin
		VetoNameW[0] := #0;

    if ShowEjectMessage then
      funcResult := CM_Request_Device_EjectW(DevInstParent, nil, nil, 0, 0) //With messagebox (W2K, Vista) or balloon (XP)
    else
		  funcResult := CM_Request_Device_EjectW(DevInstParent, @VetoType, VetoNameW, MAX_PATH, 0);

		if (funcResult=CR_SUCCESS) and (VetoType=PNP_VetoTypeUnknown) then
    begin
      Result:=true;
			break;
    end;

		Sleep(500); //Wait and then try again
	 end;

   if result=false then
   begin
    if GetLastError = 32 then
      EjectErrorCode:=REMOVE_ERROR_DISK_IN_USE
    else
      EjectErrorCode:=REMOVE_ERROR_UNKNOWN_ERROR;
   end;
end;

function TDriveEjector.GetDrivesDevInstByDeviceNumber(DeviceNumber: Integer;
  DriveType: UINT; szDosDeviceName: PCHAR): DEVINST;
var
  IsFloppy, DoLoop: boolean;
  myGUID: TGUID;
  myhDevInfo: HDEVINFO;
  dwIndex, dwSize, dwBytesReturned: DWORD;
  //Buf: array[0..1024-1] of BYTE;
  FunctionResult: boolean;
  pspdidd: PSPDeviceInterfaceDetailData;
	spdid: SP_DEVICE_INTERFACE_DATA;
	spdd: SP_DEVINFO_DATA;
  hDrive: THandle;
  SDN: STORAGE_DEVICE_NUMBER;
begin
  Result:=0;
  IsFloppy:=true;

  if StrPos(szDosDeviceName, '\Floppy') = nil then
    IsFloppy:=false;

	case (DriveType)  of
    DRIVE_REMOVABLE:
		  if ( IsFloppy ) then
      begin
			  myguid := GUID_DEVINTERFACE_FLOPPY;
      end
      else
      begin
			  myguid := GUID_DEVINTERFACE_DISK;
      end;

    DRIVE_FIXED:
		  myguid := GUID_DEVINTERFACE_DISK;

    DRIVE_CDROM:
		  myguid := GUID_DEVINTERFACE_CDROM;

    else
      exit;

  end;

	//Get device interface info set handle for all devices attached to system
	myhDevInfo := SetupDiGetClassDevs(@myguid, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);

	if (cardinal(myhDevInfo) = INVALID_HANDLE_VALUE) then
    exit;

	//Retrieve a context structure for a device interface of a device information set
	dwIndex := 0;

	//pspdidd :=PSP_DEVICE_INTERFACE_DETAIL_DATA(@Buf);
  ZeroMemory(@spdd, SizeOf(spdd));
	spdid.cbSize := SizeOf(spdid);

  DoLoop:=True;
	while (DoLoop=true)	do
  begin
		FunctionResult := SetupDiEnumDeviceInterfaces(myhDevInfo, nil, myGUID, dwIndex, spdid);
		if FunctionResult= false then
			break;

		dwSize := 0;
		SetupDiGetDeviceInterfaceDetail(myhDevInfo, @spdid, nil, 0, dwSize, nil); //Check the buffer size

		if ( dwSize <> 0)  and  (dwSize <= 1024) {SizeOf(Buf))} then
    begin
      GetMem(pspdidd, dwSize);
      try
			  pspdidd.cbSize := SizeOf(pspdidd^); //SizeOf(TSPDeviceInterfaceDetailData)
			  ZeroMemory(@spdd, SizeOf(spdd));
			  spdd.cbSize := SizeOf(spdd);

			  FunctionResult := SetupDiGetDeviceInterfaceDetail(myhDevInfo, @spdid, pspdidd, dwSize, dwSize, @spdd);
			  if FunctionResult then
        begin
          //Open the disk or cdrom or floppy
          hDrive:=INVALID_HANDLE_VALUE;
          try
            hDrive := CreateFile(pspdidd.DevicePath, 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
				    if ( hDrive <> INVALID_HANDLE_VALUE ) then
            begin
					    //Get its device number
					    dwBytesReturned := 0;
					    FunctionResult := DeviceIoControl(hDrive, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn, SizeOf(sdn), @dwBytesReturned, nil);
					    if FunctionResult  then
              begin
						    if DeviceNumber = LongInt(sdn.DeviceNumber) then
                begin  //Match the device number with that of the current device
							    result:= spdd.DevInst;
                  break;
						    end;
				      end;
            end;
          finally
            CloseHandle(hDrive);
          end;
			  end;

      finally
        FreeMem(pspdidd);
      end;
	  end;

    dwIndex:= dwIndex + 1;
  end;

	SetupDiDestroyDeviceInfoList(myhDevInfo);
end;

function TDriveEjector.GetNoDevicesWithSameParentInst(
  ParentDevInst: integer): integer;
var
  i: integer;
begin
  result:=-1; //will be inc'ed once when it goes through the one we're comparing to
  for I := 0 to DrivesCount - 1 do
  begin
    if RemovableDrives[i].ParentDevInst = ParentDevInst then
      inc(result);
  end;
end;

function TDriveEjector.GetNoDevicesWithSameProductId(
  ProductId: string): integer;
var
  i: integer;
begin
  result:=-1; //will be inc'ed once when it goes through the one we're comparing to
  for I := 0 to DrivesCount - 1 do
  begin
    if RemovableDrives[i].ProductID = ProductID then
      inc(result);
  end;
end;

function TDriveEjector.GetParentDriveDevInst(MountPoint: string;
  var ParentInstNum: integer): boolean;
var
  szRootPath, szDevicePath, szVolumeAccessPath: string;
  DeviceNumber: longint;
  hVolume: THandle;
  dwBytesReturned: DWord;
  DriveType: UINT;
  SDN: STORAGE_DEVICE_NUMBER;
  FunctionResultInt: integer;
  FunctionResultBool: boolean;
  DeviceInst, DevInstParent: DEVINST;
  szDosDeviceName, VolumeName: array[0..MAX_PATH-1] of Char;
begin
  Result:=false;

  GetVolumeNameForVolumeMountPoint(pchar(MountPoint), VolumeName, MAX_PATH);
  szRootPath:=VolumeName;
  szDevicePath:=ExcludeTrailingPathDelimiter( VolumeName );
  szVolumeAccessPath:=ExcludeTrailingPathDelimiter( VolumeName );
  szDevicePath:=Copy(szVolumeAccessPath, 5, length(szVolumeAccessPath) -4);
  DeviceNumber:=-1;

  hVolume:= INVALID_HANDLE_VALUE;
  try
    //Open the storage volume
    hVolume:=CreateFile(PChar(szVolumeAccessPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if hVolume = INVALID_HANDLE_VALUE then
      exit;

    //Get the volume's device number
    dwBytesReturned:=0;
    FunctionResultBool:=DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @SDN, SizeOf(SDN), @dwBytesReturned, nil);
    if FunctionResultBool then
      DeviceNumber:=SDN.DeviceNumber;

  finally
    CloseHandle(hVolume);
  end;

  if DeviceNumber = -1 then
    exit;

	//Get the drive type which is required to match the device numbers correctely
	DriveType := GetDriveType(PChar(szRootPath));
  szDosDeviceName[0]:=#0;

	//Get the dos device name (like \deviceloppy0) to decide if it's a floppy or not
	FunctionResultInt := QueryDosDevice(PChar(szDevicePath), szDosDeviceName,  MAX_PATH);
	if FunctionResultInt = 0 then
    exit;

	//Get the device instance handle of the storage volume by means of a SetupDi enum and matching the device number
	DeviceInst:= GetDrivesDevInstByDeviceNumber(DeviceNumber, DriveType, szDosDeviceName);

	if (DeviceInst = 0) then
    exit;

	//Get drives's parent
	DevInstParent:=0;
	CM_Get_Parent(DevInstParent, DeviceInst, 0);

  if DevInstParent > 0 then
  begin
    ParentInstNum:=DevInstParent;
    result:=true;
  end;

end;

procedure TDriveEjector.OnTimer(Sender: TObject);
var
  i: integer;
begin
  //sysutils.Beep;
  if GetDrivesCount = 0 then exit;
  if fPolling = false then exit;


  for I := 0 to GetDrivesCount - 1 do
  begin
    if RemovableDrives[i].IsCardReader then
    begin
      if CheckIfDriveHasMedia(RemovableDrives[i].DriveMountPoint) then
      begin
        if RemovableDrives[i].CardMediaPresent=false then //Has changed - generate event
        begin
          RemovableDrives[i].CardMediaPresent:=true;
          if assigned(foncardmediachanged) then
            foncardmediachanged(nil);
        end;
      end
      else
      begin
        if RemovableDrives[i].CardMediaPresent=true then  //Has changed - generate event
        begin
          RemovableDrives[i].CardMediaPresent:=false;
          if assigned(foncardmediachanged) then
            foncardmediachanged(nil);
        end;
      end;
    end;
  end;

end;

Initialization
  //Windows 2000 workaround
  GetVolumePathNamesForVolumeNameW := GetProcAddress(GetModuleHandle('kernel32.dll'), 'GetVolumePathNamesForVolumeNameW');
  If @GetVolumePathNamesForVolumeNameW = nil Then
    GetVolumePathNamesForVolumeNameW := @_GetVolumePathNamesForVolumeNameW;

End.

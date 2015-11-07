 {
******************************************************
  USB Disk Ejector
  Copyright (c) 2006 - 2015 Bennyboy
  Http://quickandeasysoftware.net
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
  A wrapper for the excellent Hotkeymanager unit.
  Written VERY quickly. Its not elegant but it works. A better approach would
  be to extend the original Hotkeymanager unit.

  Provides a list of hotkeys, which are accessed by list index
  The OnHotkeyPressed event returns the index of the hotkey in the list, unlike
  the original Hotkeymanager which returns the key's atom.
}

unit uCustomHotKeyManager;

interface

uses
  SysUtils, Contnrs, System.Classes, HotKeyManager;

type
  TCustomHotKeyAction = (
    RestoreApp,
    EjectByDriveLabel,
    EjectByDriveLetter,
    EjectByMountPoint,
    EjectByDriveName
  );

  TCustomHotKey = class
    HotKey: cardinal;
    HotKeyAtom: word;
    HotKeyType: TCustomHotKeyAction;
    HotKeyParam: string;
    constructor Create(AHotKey: Cardinal; AHotKeyAtom: word; AHotKeyType: TCustomHotKeyAction; AHotKeyParam: string);
  end;

  EHotKeyAlreadyExists = class (exception);

  TCustomHotKeyManager = class //(TComponent)
  private
    FOnHotKeyPressed: TOnHotKeyPressed;
    fOriginalHotKeyManager: THotKeyManager;
    function GetItemIndexByAtom(Atom: word): integer;
    procedure HotKeyPressed(HotKey: Cardinal; Index: Word); //returns index instead of atom
  public
    HotKeys: TObjectList;
    constructor Create;
    destructor Destroy; override;
    function AddHotKey(AHotKey: Cardinal; AHotKeyType: TCustomHotKeyAction; AHotKeyParam: string = ''): boolean;
    function RemoveHotKeyByListIndex(Index: integer): boolean;
    function HotKeyToText(HotKey: Cardinal; Localized: Boolean): String;
    function HotKeyExists(AHotKey: cardinal): boolean;
    function HotKeyAvailable(HotKey: Cardinal): Boolean;
    function TextToHotKey(Text: String): Cardinal;
    property OnHotKeyPressed: TOnHotKeyPressed read FOnHotKeyPressed write FOnHotKeyPressed;
  end;

implementation

constructor TCustomHotKey.Create(AHotKey: Cardinal; AHotKeyAtom: word; AHotKeyType: TCustomHotKeyAction; AHotKeyParam: string);
begin
  HotKey:=AHotKey;
  HotKeyAtom:=AHotKeyAtom;
  HotKeyType:=AHotKeyType;
  HotKeyParam:=AHotKeyParam;
end;

constructor TCustomHotKeyManager.Create;
begin
  HotKeys:=TObjectList.Create(true);
  fOriginalHotKeyManager:=THotKeyManager.Create(nil);

  //if Assigned(FOnHotKeyPressed) then
    fOriginalHotKeyManager.OnHotKeyPressed:=HotKeyPressed;
end;

destructor TCustomHotKeyManager.Destroy;
begin
  HotKeys.Free;
  fOriginalHotKeyManager.Free;
  inherited;
end;

//Original version returns the atom as index - here we return the list index instead
function TCustomHotKeyManager.GetItemIndexByAtom(Atom: word): integer;
var
  i: integer;
begin
  result:= -1;
  if HotKeys.Count = 0 then exit;

    for i:= 0 to HotKeys.Count - 1 do
    begin
      if TCustomHotKey(HotKeys[i]).HotKeyAtom = Atom then
      begin
        result:=i;
        exit;
      end;
    end;
end;


function TCustomHotKeyManager.HotKeyAvailable(HotKey: Cardinal): Boolean;
begin
  result := HotKeyManager.HotKeyAvailable(HotKey);
end;

function TCustomHotKeyManager.HotKeyExists(AHotKey: cardinal): boolean;
var
  i: integer;
begin
  result := false;

  if HotKeys.Count > 0 then
    for i:= 0 to HotKeys.Count - 1 do
    begin
      if TCustomHotKey(HotKeys[i]).HotKey = AHotKey then
      begin
        result := true;
        break;
      end;
    end;
end;

procedure TCustomHotKeyManager.HotKeyPressed(HotKey: Cardinal; Index: Word);
var
  TempIndex: integer;
begin
  TempIndex:=GetItemIndexByAtom(Index);
  if TempIndex = -1 then
  begin
    raise Exception.Create('Error! Atom Index not found - THIS SHOULD NEVER HAPPEN');
    exit;
  end;

  if Assigned(fonHotkeyPressed) then
    FonHotKeyPressed(HotKey, TempIndex);
end;

//Pass it through here
function TCustomHotKeyManager.HotKeyToText(HotKey: Cardinal;
  Localized: Boolean): String;
begin
  result:=HotKeyManager.HotKeyToText(HotKey, Localized);
end;

function TCustomHotKeyManager.AddHotKey(AHotKey: Cardinal; AHotKeyType: TCustomHotKeyAction;
  AHotKeyParam: string): boolean;
var
  i: integer;
  AtomNo: word;
begin
  result:=false;

  if HotKeys.Count > 0 then
    for i:= 0 to HotKeys.Count - 1 do
    begin
      if TCustomHotKey(HotKeys[i]).HotKey = AHotKey then
      begin
        raise EHotKeyAlreadyExists.Create('Hotkey ' + HotKeyManager.HotKeyToText(AHotKey, true)
              + ' already in use!' + #13 + 'Please select a different hotkey and try again.');
        exit;
      end;
    end;

  AtomNo:=fOriginalHotKeyManager.AddHotKey(AHotKey);
  if AtomNo > 0 then //Hotkey added successfully
  begin
    HotKeys.Add(TCustomHotKey.Create(AHotKey, AtomNo, AHotKeyType, AHotKeyParam));
    Result:=true;
  end;
end;

function TCustomHotKeyManager.RemoveHotKeyByListIndex(Index: integer): boolean;
var
  AtomNo: word;
begin
  result:=false;

  if Index > HotKeys.Count then exit;
  if Index < 0 then exit;

  AtomNo:=TCustomHotKey(HotKeys[Index]).HotKeyAtom;
  if fOriginalHotKeyManager.RemoveHotKeyByIndex(AtomNo) then
  begin
    HotKeys.Delete(Index);
    Result:=true;
  end

end;

function TCustomHotKeyManager.TextToHotKey(Text: String): Cardinal;
begin
  result := HotKeyManager.TextToHotKey(Text, true);
end;

end.

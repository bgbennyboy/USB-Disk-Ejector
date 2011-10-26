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

unit formOptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons, ExtCtrls, CategoryButtons, ImgList,
  JvExComCtrls, JvHotKey,
  {uVistaFuncs,}
  uDiskEjectOptions, uCustomHotKeyManager, uDiskEjectConst;

type
  TOptionsfrm = class(TForm)
    CategoryButtons1: TCategoryButtons;
    ImageList1: TImageList;
    PanelBack: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    ScrollBox1: TScrollBox;
    GroupBox2: TGroupBox;
    CheckBox4: TCheckBox;
    TabSheet2: TTabSheet;
    ScrollBox2: TScrollBox;
    GroupBox4: TGroupBox;
    Label1: TLabel;
    chkboxSaveWindowSize: TCheckBox;
    chkBoxAutosizeWindow: TCheckBox;
    chkboxSaveWindowPosition: TCheckBox;
    comboboxDockTo: TComboBox;
    TabSheet3: TTabSheet;
    ScrollBox3: TScrollBox;
    TabSheet4: TTabSheet;
    ScrollBox4: TScrollBox;
    GroupBox5: TGroupBox;
    comboBoxHotKeyAction: TComboBox;
    hotKey1: TJvHotKey;
    btnAddHotKey: TBitBtn;
    btnRemoveHotKey: TBitBtn;
    listViewHotkeys: TListView;
    comboboxHotKeyParams: TComboBox;
    PanelBottom: TPanel;
    lblNoSaveMode: TLabel;
    BitBtn2: TBitBtn;
    BitBtn1: TBitBtn;
    Label2: TLabel;
    GroupBox6: TGroupBox;
    chkboxStartAppMinimized: TCheckBox;
    GroupBox1: TGroupBox;
    chkBoxShowWindowsEject: TCheckBox;
    radiogroupCloseApps: TRadioGroup;
    radiogroupAfterEject: TRadioGroup;
    GroupBox3: TGroupBox;
    chkboxCloseToTray: TCheckBox;
    chkboxMinimizeToTray: TCheckBox;
    chkboxShowBalloonMessages: TCheckBox;
    CheckBoxAudioNotifications: TCheckBox;
    TabSheet5: TTabSheet;
    GroupBox7: TGroupBox;
    chkBoxHideCardReaders: TCheckBox;
    chkboxCardPolling: TCheckBox;
    GroupBox8: TGroupBox;
    comboboxCardReaderChoose: TComboBox;
    btnAddCardReader: TBitBtn;
    btnRemoveCardReader: TBitBtn;
    listviewCardReaders: TListView;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure btnAddHotKeyClick(Sender: TObject);
    procedure btnRemoveHotKeyClick(Sender: TObject);
    procedure comboBoxHotKeyActionChange(Sender: TObject);
    procedure listViewHotkeysChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure listViewHotkeysDblClick(Sender: TObject);
    procedure chkBoxAutosizeWindowClick(Sender: TObject);
    procedure chkboxSaveWindowSizeClick(Sender: TObject);
    procedure comboboxDockToChange(Sender: TObject);
    procedure chkboxSaveWindowPositionClick(Sender: TObject);
    procedure CategoryButtons1CategoryCollapase(Sender: TObject;
      const Category: TButtonCategory);
    procedure CategoryButtons1ButtonClicked(Sender: TObject;
      const Button: TButtonItem);
    procedure btnRemoveCardReaderClick(Sender: TObject);
    procedure listviewCardReadersChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure btnAddCardReaderClick(Sender: TObject);
  private
    procedure PopulateDriveLetters;
    procedure PopulateDriveNames;
    procedure PopulateDriveLabels;
    procedure PopulateMountPoints;
    procedure PopulateCardReaderChooseBox;
    procedure UpdateListViewHotKeys;
    procedure UpdateListViewCardReaders;
    procedure AddListviewItem(fListView: TListView; fCaption : string; fSubItems : Array of string);
    procedure RemoveCustomCardReaders(VendorID, ProductID, ProductRevision: string);
  public
    { Public declarations }
  end;

var
  Optionsfrm: TOptionsfrm;

implementation

uses formAbout, formMain;

{$R *.dfm}

procedure TOptionsfrm.RemoveCustomCardReaders(VendorID, ProductID, ProductRevision: string);
var
  i: integer;
begin
  if CardReaders = nil then exit;
  //if CardReaders.CardReadersCount = 0 then exit;

  for I := 0 to Ejector.DrivesCount - 1 do
  begin
    if (Trim(Ejector.RemovableDrives[i].VendorId) = VendorID) and
       (Trim(Ejector.RemovableDrives[i].ProductID) = ProductID) and
       (Trim(Ejector.RemovableDrives[i].ProductRevision) = ProductRevision) then
       begin
        Ejector.SetDriveAsCardReader(i, false);
        break;
       end;
  end;
end;

procedure TOptionsfrm.FormCreate(Sender: TObject);
var
  i: integer;
begin
  //Disable all tabs
  for i := 0 to PageControl1.PageCount -1 do
    PageControl1.Pages[i].TabVisible := false;
  //Switch to first page
  PageControl1.ActivePage := PageControl1.Pages[0];

  CategoryButtons1.SelectedItem := CategoryButtons1.Categories[0].Items[0];

  Options.HotKeys:=HotKeys;
  Options.RebuildHotKeys;

  Options.CardReaders := CardReaders;
  Options.RebuildCardReaders;
  Mainfrm.AddCustomCardReaders; //Have to do this here - cant do it in Main form as it runs from FillDriveList which is called by Create() - which runs before options or anything else is created
end;

procedure TOptionsfrm.FormShow(Sender: TObject);
var
  i: integer;
begin
  with Options do
  begin
    chkBoxShowWindowsEject.Checked      := UseWindowsNotifications;
    chkboxSaveWindowPosition.Checked    := PreserveWindowLocation;
    chkboxSaveWindowSize.Checked        := PreserveWindowSize;
    chkBoxAutosizeWindow.Checked        := AutoResize;
    chkboxStartAppMinimized.Checked     := StartAppMinimised;
    chkboxCloseToTray.Checked           := CloseToTray;
    chkboxShowBalloonMessages.Checked   := BalloonMessages;
    CheckBoxAudioNotifications.Checked  := AudioNotifications;
    chkboxMinimizeToTray.Checked        := MinimizeToTray;
    chkboxCardPolling.Checked           := CardPolling;
    radiogroupAfterEject.ItemIndex      := AfterEject;
    comboboxDockTo.ItemIndex            := SnapTo;
    chkBoxHideCardReaders.Checked       := HideCardReadersWithNoMedia;

    if (CloseRunningApps_Ask = true) and (CloseRunningApps_Force = false) then
      radioGroupCloseApps.ItemIndex:=1
    else
    if (CloseRunningApps_Ask = true) and (CloseRunningApps_Force = true) then
      radioGroupCloseApps.ItemIndex:=2
    else
      radioGroupCloseApps.ItemIndex:=0;
  end;

  
  if Options.CommandLine_NoSave then
    lblNoSaveMode.Visible:=true
  else
    lblNoSaveMode.Visible:=false;

  listViewHotkeys.Clear;
  if HotKeys.HotKeys.Count > 0 then
  begin
    for I := 0 to HotKeys.HotKeys.Count - 1 do
    begin
        case TCustomHotKey(HotKeys.HotKeys[i]).HotKeyType of
          RestoreApp:           AddListviewItem(listViewHotkeys, str_Hotkey_Restore_Window, ['',HotKeys.HotKeyToText(TCustomHotKey(HotKeys.HotKeys[i]).HotKey, true)]);
          EjectByDriveLabel:    AddListviewItem(listViewHotkeys, str_Hotkey_Eject_Label, [TCustomHotKey(HotKeys.HotKeys[i]).HotKeyParam, HotKeys.HotKeyToText(TCustomHotKey(HotKeys.HotKeys[i]).HotKey, true)]);
          EjectByDriveLetter:   AddListviewItem(listViewHotkeys, str_Hotkey_Eject_Letter, [TCustomHotKey(HotKeys.HotKeys[i]).HotKeyParam, HotKeys.HotKeyToText(TCustomHotKey(HotKeys.HotKeys[i]).HotKey, true)]);
          EjectByMountPoint:    AddListviewItem(listViewHotkeys, str_Hotkey_Eject_MountPoint, [TCustomHotKey(HotKeys.HotKeys[i]).HotKeyParam, HotKeys.HotKeyToText(TCustomHotKey(HotKeys.HotKeys[i]).HotKey, true)]);
          EjectByDriveName:     AddListviewItem(listViewHotkeys, str_Hotkey_Eject_Name,   [TCustomHotKey(HotKeys.HotKeys[i]).HotKeyParam, HotKeys.HotKeyToText(TCustomHotKey(HotKeys.HotKeys[i]).HotKey, true)]);
        end;
    end;
  end;


  listViewCardReaders.Clear;
  if CardReaders.CardReadersCount > 0 then
  begin
    for I := 0 to CardReaders.CardReadersCount - 1 do
    begin
      AddListviewItem(listViewCardReaders,  CardReaders.CardReaders[i].VendorID,  [ CardReaders.CardReaders[i].ProductID, CardReaders.CardReaders[i].ProductRevision ]);
    end;
  end;


  PopulateCardReaderChooseBox;
end;

procedure TOptionsfrm.listviewCardReadersChange(Sender: TObject;
  Item: TListItem; Change: TItemChange);
begin
  UpdateListViewCardReaders;
end;

procedure TOptionsfrm.listViewHotkeysChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  UpdateListViewHotKeys;
end;

procedure TOptionsfrm.listViewHotkeysDblClick(Sender: TObject);
begin
  if listViewHotKeys.ItemIndex <> -1 then
    ShowMessage(listViewHotkeys.Items[listViewHotKeys.ItemIndex].Caption +
      ': ' +
      listViewHotkeys.Items[listViewHotKeys.ItemIndex].SubItems.Strings[0] +
      #13 + str_Hotkey +
      listViewHotkeys.Items[listViewHotKeys.ItemIndex].SubItems.Strings[1]
    );
end;

procedure TOptionsfrm.PopulateCardReaderChooseBox;
var
  i: integer;
begin
  comboboxCardReaderChoose.Clear;
  comboboxCardReaderChoose.ItemIndex := -1;

  if Ejector.DrivesCount = 0 then exit;

  for I := 0 to Ejector.DrivesCount - 1 do
  begin
    if Ejector.RemovableDrives[i].DriveMountPoint <> '' then
      comboboxCardReaderChoose.Items.Add(Trim(Ejector.RemovableDrives[i].VendorId) + ' ' +
                                         Trim(Ejector.RemovableDrives[i].ProductID + ' ' +
                                         Trim(Ejector.RemovableDrives[i].ProductRevision)));
  end;

end;

procedure TOptionsfrm.PopulateDriveLabels;
var
  i: integer;
begin
  comboboxHotKeyParams.Clear;
  comboboxHotKeyParams.Style := csDropDown;

  if Ejector.DrivesCount = 0 then exit;

  for I := 0 to Ejector.DrivesCount - 1 do
  begin
    if Ejector.RemovableDrives[i].VolumeLabel <> '' then
      comboboxHotKeyParams.Items.Add(Trim(Ejector.RemovableDrives[i].VolumeLabel));
  end;
end;

procedure TOptionsfrm.PopulateDriveLetters;
const
  MAX_DRIVES = 26;
var
  DriveName: string;
  i: integer;
begin
  comboboxHotKeyParams.Clear;
  comboboxHotKeyParams.Style := csDropDownList;

  DriveName := 'A:';

  for i := 0 to MAX_DRIVES - 1 do
  begin
    DriveName[1] := 'A';
    Inc(DriveName[1], I);
    comboboxHotKeyParams.Items.Add(DriveName);
  end;

  comboboxHotKeyParams.ItemIndex:=0;
end;

procedure TOptionsfrm.PopulateDriveNames;
var
  i: integer;
begin
  comboboxHotKeyParams.Clear;
  comboboxHotKeyParams.Style := csDropDown;

  if Ejector.DrivesCount = 0 then exit;

  for I := 0 to Ejector.DrivesCount - 1 do
  begin
    if Ejector.RemovableDrives[i].VendorId = '' then
      comboboxHotKeyParams.Items.Add(Trim(Ejector.RemovableDrives[i].ProductID))
    else
      comboboxHotKeyParams.Items.Add(Trim(Ejector.RemovableDrives[i].VendorId) + ' ' + Trim(Ejector.RemovableDrives[i].ProductID));
  end;
end;

procedure TOptionsfrm.PopulateMountPoints;
var
  i: integer;
begin
  comboboxHotKeyParams.Clear;
  comboboxHotKeyParams.Style := csDropDown;

  if Ejector.DrivesCount = 0 then exit;

  for I := 0 to Ejector.DrivesCount - 1 do
  begin
    if Ejector.RemovableDrives[i].DriveMountPoint <> '' then
      comboboxHotKeyParams.Items.Add(Trim(Ejector.RemovableDrives[i].DriveMountPoint));
  end;
end;

procedure TOptionsfrm.UpdateListViewCardReaders;
begin
  if listViewCardReaders.Items.Count > 0 then
    btnRemoveCardReader.Visible := true
  else
    btnRemoveCardReader.Visible := false;
end;

procedure TOptionsfrm.UpdateListViewHotKeys;
begin
  if listViewHotkeys.Items.Count > 0 then
    btnRemoveHotkey.Visible := true
  else
    btnRemoveHotkey.Visible := false;
end;

procedure TOptionsfrm.AddListViewItem(fListView: TListView; fCaption : string; fSubItems : Array of string);
var
  i : Integer;
  listitem: tlistitem;
begin
  ListItem := Tlistview(fListView).Items.Add;
  ListItem.Caption := fCaption;
  for i := 0 to High(fSubItems) do
    ListItem.SubItems.Add(fSubItems[i]);
end;

procedure TOptionsfrm.btnAddCardReaderClick(Sender: TObject);
begin
  if comboboxCardReaderChoose.ItemIndex < 0 then
  begin
    ShowMessage(str_Hotkey_NoParam);
    exit;
  end;

  if CardReaders.AddCardReader(Trim(Ejector.RemovableDrives[comboboxCardReaderChoose.ItemIndex].VendorId), Trim(Ejector.RemovableDrives[comboboxCardReaderChoose.ItemIndex].ProductID), Trim(Ejector.RemovableDrives[comboboxCardReaderChoose.ItemIndex].ProductRevision)) = false then
  begin
    ShowMessage('Couldnt add card reader. Maybe its already in the list?');
    exit;
  end;

  AddListviewItem(listViewCardReaders,  Trim(Ejector.RemovableDrives[comboboxCardReaderChoose.ItemIndex].VendorId),  [ Trim(Ejector.RemovableDrives[comboboxCardReaderChoose.ItemIndex].ProductID), Trim(Ejector.RemovableDrives[comboboxCardReaderChoose.ItemIndex].ProductRevision) ]);
end;

procedure TOptionsfrm.btnAddHotKeyClick(Sender: TObject);
var
  TempHotKeyAction: TCustomHotkeyAction;
  HotKeyParam: string;
begin
  if hotkey1.HotKey = 0 then exit;
  if (comboboxHotkeyAction.Style = csDropDown) and (comboboxHotKeyParams.Text='') then
  begin
    ShowMessage(str_Hotkey_NoParam);
    exit;
  end;

  HotKeyParam:='';

  case comboboxHotkeyAction.ItemIndex of
    0: TempHotKeyAction:=RestoreApp;
    1: begin
        TempHotKeyAction:=EjectByDriveLabel;
        HotKeyParam:=comboboxHotKeyParams.Text;
       end;
    2: begin
        TempHotKeyAction:=EjectByDriveLetter;
        HotKeyParam:=comboboxHotKeyParams.Items[comboboxHotKeyParams.ItemIndex][1];
       end;
    3: begin
        TempHotKeyAction:=EjectByMountPoint;
        HotKeyParam:=comboboxHotKeyParams.Text;
       end;
    4: begin
        TempHotKeyAction:=EjectByDriveName;
        HotKeyParam:=comboboxHotKeyParams.Text;
       end
  else
       TempHotKeyAction:=RestoreApp;
  end;

  try
    if formMain.HotKeys.AddHotKey(HotKey1.HotKey, TempHotKeyAction, HotKeyParam) = false then
      ShowMessage('Couldnt assign hotkey')
    else
    begin
      case TCustomHotKey(HotKeys.HotKeys[listViewHotkeys.Items.Count]).HotKeyType of
        RestoreApp:           AddListviewItem(listViewHotkeys, str_Hotkey_Restore_Window, ['',HotKeys.HotKeyToText(HotKey1.HotKey, true)]);
        EjectByDriveLabel:    AddListviewItem(listViewHotkeys, str_Hotkey_Eject_Label,   [TCustomHotKey(HotKeys.HotKeys[listViewHotkeys.Items.Count]).HotKeyParam, HotKeys.HotKeyToText(HotKey1.HotKey, true)]);
        EjectByDriveLetter:   AddListviewItem(listViewHotkeys, str_Hotkey_Eject_Letter, [TCustomHotKey(HotKeys.HotKeys[listViewHotkeys.Items.Count]).HotKeyParam, HotKeys.HotKeyToText(HotKey1.HotKey, true)]);
        EjectByMountPoint:    AddListviewItem(listViewHotkeys, str_Hotkey_Eject_MountPoint,   [TCustomHotKey(HotKeys.HotKeys[listViewHotkeys.Items.Count]).HotKeyParam, HotKeys.HotKeyToText(HotKey1.HotKey, true)]);
        EjectByDriveName:     AddListviewItem(listViewHotkeys, str_Hotkey_Eject_Name,   [TCustomHotKey(HotKeys.HotKeys[listViewHotkeys.Items.Count]).HotKeyParam, HotKeys.HotKeyToText(HotKey1.HotKey, true)]);
      end;

    end;
  except on E: EHotKeyAlreadyExists do
    ShowMessage(E.Message);
  end;
end;

procedure TOptionsfrm.btnRemoveCardReaderClick(Sender: TObject);
begin
  if listViewCardReaders.Items.Count = 0 then exit;
  if listViewCardReaders.ItemIndex =-1 then exit;

  RemoveCustomCardReaders(CardReaders.CardReaders[listViewCardReaders.ItemIndex].VendorID, CardReaders.CardReaders[listViewCardReaders.ItemIndex].ProductID, CardReaders.CardReaders[listViewCardReaders.ItemIndex].ProductRevision);
  CardReaders.DeleteCardReader(listViewCardReaders.ItemIndex);
  listViewCardReaders.Items.Delete(listViewCardReaders.ItemIndex);

  UpdateListViewCardReaders;
end;

procedure TOptionsfrm.btnRemoveHotKeyClick(Sender: TObject);
begin
  if listViewHotkeys.Items.Count = 0 then exit;
  if listViewHotkeys.ItemIndex =-1 then exit;

  if HotKeys.RemoveHotKeyByListIndex(listViewHotkeys.ItemIndex)= false then
    Showmessage(str_Hotkey_Remove_Error)
  else
    listViewHotkeys.Items.Delete(listViewHotkeys.ItemIndex);

  UpdateListviewHotKeys;
end;

procedure TOptionsfrm.CategoryButtons1ButtonClicked(Sender: TObject;
  const Button: TButtonItem);
begin
  PageControl1.ActivePage := PageControl1.Pages[Button.Index];
end;

procedure TOptionsfrm.CategoryButtons1CategoryCollapase(Sender: TObject;
  const Category: TButtonCategory);
begin
  If Category.Caption = CategoryButtons1.Categories[0].Caption then
  begin
    CategoryButtons1.Categories[0].Collapsed := False;
  end;
end;

procedure TOptionsfrm.chkBoxAutosizeWindowClick(Sender: TObject);
begin
  if chkBoxAutosizeWindow.Checked then chkboxSaveWindowSize.Checked:=false;
end;

procedure TOptionsfrm.chkboxSaveWindowSizeClick(Sender: TObject);
begin
  if chkboxSaveWindowSize.Checked then chkBoxAutosizeWindow.Checked:=false;
end;

procedure TOptionsfrm.chkboxSaveWindowPositionClick(Sender: TObject);
begin
  if chkboxSaveWindowPosition.Checked then comboboxDockTo.ItemIndex := 0;
end;

procedure TOptionsfrm.comboboxDockToChange(Sender: TObject);
begin
  if comboboxDockTo.itemindex > 0 then
  begin
    chkboxSaveWindowPosition.Checked := false;
  end;
end;

procedure TOptionsfrm.comboBoxHotKeyActionChange(Sender: TObject);
begin
  case comboBoxHotKeyAction.ItemIndex of
    0:  begin //Restore window
          comboboxHotKeyParams.Visible:=false;
        end;
    1:  begin //Label
          comboboxHotKeyParams.Visible:=true;
          PopulateDriveLabels;
        end;
    2:  begin //Letter
          comboboxHotKeyParams.Visible:=true;
          PopulateDriveLetters;
        end;

    3:  begin //Mountpoint
          comboboxHotKeyParams.Visible:=true;
          PopulateMountPoints;
        end;

    4:  begin //Name
          comboboxHotKeyParams.Visible:=true;
          PopulateDriveNames;
        end;
  end;
end;

procedure TOptionsfrm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i, KeyCount, CardReaderCount: integer;
begin 
  if ModalResult <> mrOk then
  begin
    //Delete any new hotkeys and revert to the old ones
    if HotKeys.HotKeys.Count > 0 then
    begin
      KeyCount := HotKeys.HotKeys.Count - 1;
      for I := KeyCount downto  0 do  
        HotKeys.RemoveHotKeyByListIndex(i);
    end;

    Options.RebuildHotkeys;


    //Delete any new card readers and revert to the old ones
    if CardReaders.CardReadersCount > 0 then
    begin
      CardReaderCount := CardReaders.CardReadersCount - 1;
      for I := CardReaderCount downto  0 do
        CardReaders.DeleteCardReader(i);
    end;

    Options.RebuildCardReaders;


    Exit;
  end;
  with Options do
  begin
    UseWindowsNotifications := chkBoxShowWindowsEject.Checked;


    PreserveWindowLocation      := chkboxSaveWindowPosition.Checked;
    PreserveWindowSize          := chkboxSaveWindowSize.Checked;
    AutoResize                  := chkBoxAutosizeWindow.Checked;
    StartAppMinimised           := chkboxStartAppMinimized.Checked;
    CloseToTray                 := chkboxCloseToTray.Checked;
    BalloonMessages             := chkboxShowBalloonMessages.Checked;
    AudioNotifications          := CheckBoxAudioNotifications.Checked;
    MinimizeToTray              := chkboxMinimizeToTray.Checked;
    CardPolling                 := chkboxCardPolling.Checked;
    HideCardReadersWithNoMedia  := chkBoxHideCardReaders.Checked;
    AfterEject                  := radiogroupAfterEject.ItemIndex;
    SnapTo                      := comboboxDockTo.ItemIndex;

    if radioGroupCloseApps.ItemIndex = 0 then
    begin
      CloseRunningApps_Ask:=false;
      CloseRunningApps_Force:=false
    end
    else
    if radioGroupCloseApps.ItemIndex = 1 then
    begin
      CloseRunningApps_Ask:=true;
      CloseRunningApps_Force:=false
    end
    else
    if radioGroupCloseApps.ItemIndex = 2 then
    begin
      CloseRunningApps_Ask:=true;
      CloseRunningApps_Force:=true;
    end;

    SaveConfig;
  end;

  Ejector.CardPolling:=chkboxCardPolling.Checked;

end;

end.

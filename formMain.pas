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

{
DO BEFORE RELEASE:
  DISABLE ReportMemoryLeaksOnShutdown in project's .dpr
  Change build configuration from debug to release
  Update readme
  Compress with UPX
  Update version string in uDiskEjectConst
  Update version info in project
  Jedi API - change compiler def to Win2000 and up
  JwaWindows - check which version its pointing to - release/debug static/dynamic
}

{
Added since last stable release:
  App instances - now only 1 allowed - launching second instance restores the first - only tested on vista
  Made 'search for memory cards' enabled by default
  DiskEjectUtils - CreateCleanupBatFileAndRun - removed legacy winexec and replaced with shellexec
  Docking to screen corners
  Supports mountpoints - drives mapped to folders
  Global communications - uses balloon hints if available and enabled - else uses messagebox
  Options dialog rewritten
  Added audio notifications - for sound if ejections succeeds/fails
  Notifications - if balloon hints disabled or not available displays a messagebox dialog that autocloses after 5 seconds
  Command line switches - big changes
  No switches for GUI Mode features - all controlled by options now
  design change - command line options reduced - all settings inherited from options file
    if nosave is used, they are read but not saved
  Added /removelabel
  Updated hotkey support with new commands
  Fixed hotkeys still being removed in options dialog if cancel was pressed
  Firewire support - in gui + command line
  Autosize window - resize doesnt go behind taskbar - sizes up if necessary - always stays on screen. Smart resizing
  Autosize option
  Detects card readers
  Card reader polling
  Ejects card by default  - not the device
  Fixed options XP font size
  Docking - will resize correctly and stay in corners
  Different icons - card reader/reader with card in - firewire drive
  Double right clicking opens explorer window
  Better notifications - for different types of removal problem
  Notifications - when eject is successful
  Closes explorer windows before eject - no more vista problems
  Successful eject ballon tips added
  Closes running apps - ask or force - NOT if app has file open from drive
  New - no disks found icon
  Tray - right click removal of devices
  Removed 'website' link on main form
  Added eject by right click menu in tray
  Hotkeys - eject by drive name (with wildcard support), drive letter, bring to front
  Threads - stop very rare issue where device with many partitions or card reader device supporting multiple devices - not all drives were detected
  Card readers - specify which ones are readers in options - match by various fields
  Option to hide card readers with no media in
  Option to set card polling time - default is 5 seconds
  Option to hide all card readers
  Option to show drives with multiple partitions as one entry - with different icon to indicate this
  Option to set max width of form - useful eg if mountpoint in a deeply nested folder
  Fixed - problem with commandline - if drive letter called as lower case ExtractFilePath - would pass the letter as lower case
  Fixed - EmumWindows - problem - explorer windows are now closed successfully again
  Fixed - Ejecting mountpoint from command line - case mattered - even when doing /REMOVETHIS - now looks up the correctly cased mountpoint name
  Fixed - quotes around params when restarting in mobile mode
  Fixed - /REMOVELETTER not restarting in mobile mode when attempting to eject self
  Fixed - EnumWindowAndClose and CloseAppsRunningFrom - now take into account partitions on same drive
  Fixed - Slightly clearer error codes - show code if its unknown (and not 0)

TODO Before Release:
  Update credits in readme and about form

  COMMAND LINE:
        Need switch for command line card reader device - will eject card by default but not reader
        Need to fix in start in mobile mode - need switch for eject card or card reader device

  OTHER:
     For grouped drives show mountpoint/drive letters somehow

        Cant tab to the move label on main form
        Windows 2000 support is broken

Optional/Possibilities/Non-critical:
        See mindmap for full list
        Timer for ejection? - eg if running from pstart menu - run command to eject stick in 5 secs - gives time to close the menu
        Intercept shutdown/restart message and warn that usb stick is still in the drive. Dont forget it.
        REMOVEALL switch - eject every usb drive it finds?
        Hide certain drives when specified by user?
        Since last stable release I've disabled 'program is still running message' when app is minimized- re-enable this?
        Use new Delph 2010 hints for all controls in options
        If restarts in mobile mode and eject fails - load main app back up again somehow?
        Customise what is displayed for each drive? Icon, colour, label etc
        Hotkeys - need to know when restoring from ini - rebuildhotkeys - if hotkey active or not + to show this in options
        Localisation
        Card readers possible alternate detection? Use same method as windows rather than polling - is this available on all versions of windows though?
}

unit formMain;

interface

uses
  Forms, Sysutils, Controls, Classes, ExtCtrls, ImgList,
  graphics, JwaWindows, types,
  JvExControls, JvLabel, JvAppInst,
  JclSysInfo, JclShell, JCLStrings,
  Menus, VirtualTrees, Generics.Collections,

  uDiskEjectConst, uDiskEjectUtils, uDiskEjectOptions,
  uCustomHotKeyManager, uCardReaderManager, uDriveEjector, uCommunicationManager, JvMenus;

type
  TMainfrm = class(TForm)
    Tree: TVirtualStringTree;
    TrayIcon1: TTrayIcon;
    pnlBottom: TPanel;
    popupmenuTray: TPopupMenu;
    popupExit: TMenuItem;
    popupOptions: TMenuItem;
    popupAbout: TMenuItem;
    lblMore: TJvLabel;
    popupEjectMenu: TMenuItem;
    JvAppInstances1: TJvAppInstances;
    ImageList1: TImageList;
    ImageList2: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: Integer);
    procedure TreeDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TrayIcon1Click(Sender: TObject);
    procedure TreeKeyPress(Sender: TObject; var Key: Char);
    procedure popupExitClick(Sender: TObject);
    procedure popupOptionsClick(Sender: TObject);
    procedure popupmenuTrayPopup(Sender: TObject);
    procedure popupAboutClick(Sender: TObject);
    procedure lblMoreMouseEnter(Sender: TObject);
    procedure lblMoreMouseLeave(Sender: TObject);
    procedure lblMoreClick(Sender: TObject);
    procedure TreeMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure JvAppInstances1Rejected(Sender: TObject);
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure TreeDrawText(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
      Node: PVirtualNode; Column: TColumnIndex; const Text: string;
      const CellRect: TRect; var DefaultDraw: Boolean);
  private
    DrivePopups: array of TMenuItem;
    Procedure MinimizeClick(Sender:TObject);
    Procedure MinimizeToTray;
    procedure FillDriveList;
    procedure CloseProgram; //Use this rather than form.close because this prevents the CloseToTray option stopping it closing
    procedure HotKeyPressed(HotKey: Cardinal; Index: Word);
    procedure ResizeTree;
    procedure OnCardMediaChanged (Sender: TObject);
    procedure OnDrivesChanged (Sender: TObject);
    procedure DrivePopupMenuHandler(Sender: TObject);
    procedure AddDrivePopups;
    procedure ChangeDriveVisibility;
    procedure UpdateFormStrings;
    procedure GUIRemoveDrive(MountPoint: String; RemoveCard: boolean);
  public
  end;

var
  Mainfrm: TMainfrm;
  Ejector: TDriveEjector;
  Communicator: TCommunicationManager;
  HotKeys: TCustomHotKeyManager;
  CardReaders: TCardReaderManager;
  ForceClose: boolean = false; //Used by CloseProgram() to prevent the CloseToTray option stopping the app closing

implementation

uses formOptions, formAbout;

{$R *.dfm}

procedure TMainfrm.FormCreate(Sender: TObject);
begin
  {Set font on Vista/Windows7}
  if IsWindowsVistaOrLater and (Screen.Fonts.IndexOf('Segoe UI') > 0)then
  begin
    Application.DefaultFont.Name := 'Segoe UI';
    Application.DefaultFont.Size := 9; //Segoe UI default is size 9
    Tree.ParentFont:=false;
    Tree.Font.Size:=10;
    Tree.Header.ParentFont:=true;
    Tree.Header.Font.Size:=9;
  end
  else
  begin
    //Resize tree fonts
    Tree.ParentFont:=false;
    Tree.Font.Size:=10;
    Tree.Header.ParentFont:=true;
    Tree.Header.Font.Size:=8;
  end;

  //Load strings
  UpdateFormStrings;

  if Options.MaxWidth >0 then
    Mainfrm.Constraints.MaxWidth := options.MaxWidth;

  if options.PreserveWindowSize then
  begin
    mainfrm.Height:=options.WindowHeight;
    mainfrm.Width:=options.WindowWidth;
  end;

  if options.PreserveWindowLocation then
  begin
    mainfrm.top:=options.WindowTopPos;
    mainfrm.left:=options.WindowLeftPos;
  end;

  Communicator := TCommunicationManager.Create(TrayIcon1);
  Ejector:=TDriveEjector.Create;


  Application.hintpause:=0800;
  Application.OnMinimize := MinimizeClick;

  HotKeys:=TCustomHotKeyManager.Create;
  HotKeys.OnHotKeyPressed:=HotKeyPressed;

  CardReaders := TCardReaderManager.Create;

  Ejector.OnCardMediaChanged:=OnCardMediaChanged;
  Ejector.OnDrivesChanged:=OnDrivesChanged;
  Ejector.CardPolling:=Options.CardPolling;
  Ejector.CardPollingInterval := Options.CardPollingInterval;

  FillDriveList;
end;

procedure TMainfrm.FormDestroy(Sender: TObject);
var
  i: integer;
begin
  if DrivePopups <> nil then
  begin
    for i:=low(DrivePopups) to high(DrivePopups) do
      DrivePopups[i].Free;

    DrivePopups:=nil;
  end;
  
  HotKeys.Free;
  CardReaders.Free;
  Ejector.Free;
  Communicator.Free;
end;

procedure TMainfrm.HotKeyPressed(HotKey: Cardinal; Index: Word);
var
  EjectCard: boolean;
  TempMountPoint, TempParam: string;
begin
  //Stop hotkeys if options form or about form are showing
  if Optionsfrm.Showing then exit;
  if Aboutfrm.Showing then exit;

  //TODO - fix this
  EjectCard:=false;

  case TCustomHotKey(HotKeys.HotKeys[Index]).HotKeyType of
    RestoreApp:             TrayIcon1Click(Mainfrm);

    EjectByDriveLetter:     GUIRemoveDrive(ConvertDriveLetterToMountPoint(TCustomHotKey(
                                HotKeys.HotKeys[Index]).HotKeyParam), EjectCard);

    EjectByMountPoint:      GUIRemoveDrive(TCustomHotKey(
                                HotKeys.HotKeys[Index]).HotKeyParam, EjectCard);

    EjectByDriveName:       begin
                              TempParam:=TCustomHotKey(HotKeys.HotKeys[Index]).HotKeyParam;
                              TempMountPoint:=MatchNameToMountPoint(TempParam, Ejector);

                              if TempMountPoint = '' then
                              begin
                                if options.UseWindowsNotifications = false then
                                  Communicator.DoMessage('"' + TempParam + '" ' + str_REMOVE_ERROR_NAME_NOT_FOUND, bfError);
                              end
                              else
                                GUIRemoveDrive(TempMountPoint, EjectCard);
                            end;

    EjectByDriveLabel:      begin
                              TempParam:=TCustomHotKey(HotKeys.HotKeys[Index]).HotKeyParam;
                              TempMountPoint:=MatchLabelToMountPoint(TempParam, Ejector);

                              if TempMountPoint = '' then
                              begin
                                if options.UseWindowsNotifications = false then
                                  Communicator.DoMessage('"' + TempParam + '" ' + str_REMOVE_ERROR_LABEL_NOT_FOUND, bfError);
                              end
                              else
                                GUIRemoveDrive(TempMountPoint, EjectCard);
                            end;
  end;
end;

procedure TMainfrm.JvAppInstances1Rejected(Sender: TObject);
begin
   trayicon1.Visible:=false;
end;

procedure TMainfrm.CloseProgram;
begin
  ForceClose:=true;
  Mainfrm.Close;
end;

procedure TMainfrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ForceClose then //Stops CloseToTray option preventing closure if we really need to close the app
  begin
    ForceClose:=false
  end
  else
  if options.CloseToTray then
  begin
    Action:=caNone;
    MinimizeToTray;
  end;

  if options.PreserveWindowSize then
  begin
    options.WindowHeight:=mainfrm.Height;
    options.WindowWidth:=mainfrm.Width;
    options.SaveConfig;
  end;

  if options.PreserveWindowLocation then
  begin
    options.WindowTopPos:=mainfrm.top;
    options.WindowLeftPos:=mainfrm.left;
    options.SaveConfig;
  end;

  if options.InMobileMode=false then exit;

  CreateCleanupBatFileAndRun;
end;

procedure TMainfrm.lblMoreClick(Sender: TObject);
var
  pt: TPoint;
begin
  pt:=lblMore.ClientToScreen( Point( 0, lblMore.Height+1 ));
  if assigned( lblMore.popupmenu ) then
  begin
    popupEjectMenu.Visible:=false; //Hide ejection popups when clicking label
    lblMore.popupmenu.popup( pt.x, pt.y );
    popupEjectMenu.Visible:=true;
  end;

 //popupmenutray.Popup(mainfrm.Left + pnlBottom.Left, mainfrm.Top + pnlBottom.Top + pnlBottom.Height);
end;

procedure TMainfrm.lblMoreMouseEnter(Sender: TObject);
begin
  lblMore.Font.style:=[fsunderline];
end;

procedure TMainfrm.lblMoreMouseLeave(Sender: TObject);
begin
  lblMore.Font.style:=[];
end;

Procedure TMainfrm.MinimizeClick(Sender:TObject);
begin
  if Options.MinimizeToTray = false then exit;

  MinimizeToTray;
end;

procedure TMainfrm.MinimizeToTray;
begin
  Hide;
  if IsWindowVisible(Application.Handle) then //hide the taskbar button
    ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TMainfrm.OnCardMediaChanged(Sender: TObject);
var
  i: integer;
begin
  //beep;

  ChangeDriveVisibility;

  //CHECK if this causes problems when form is minimized
  tree.FullExpand;

  //Change icons if necessary
  for i:=low(DrivePopups) to high(DrivePopups) do
  begin
    if Ejector.RemovableDrives[i].IsCardReader then
    begin
      if Ejector.RemovableDrives[i].CardMediaPresent then
        popupEjectMenu.Items[i].ImageIndex:=6
      else
        popupEjectMenu.Items[i].ImageIndex:=5
    end;
  end;

  ResizeTree;
end;

procedure TMainfrm.popupAboutClick(Sender: TObject);
begin
  Aboutfrm.ShowModal;
end;

procedure TMainfrm.popupExitClick(Sender: TObject);
begin
  CloseProgram;
end;

procedure TMainfrm.popupmenuTrayPopup(Sender: TObject);
var
  i: integer;
begin
  if (fsModal in Aboutfrm.FormState) or (fsModal in Optionsfrm.FormState) then
  begin
    for I := 0 to popupmenuTray.Items.Count - 1 do
      popupmenuTray.Items[i].Enabled:=false;

    popupExit.Enabled:=true;
  end
  else
  begin
    for I := 0 to popupmenuTray.Items.Count - 1 do
      popupmenuTray.Items[i].Enabled:=true;
  end;

  //If there are no drive popups then disable the submenu
  if Length(DrivePopups) > 0 then
    popupEjectMenu.Enabled:=true
  else
    popupEjectMenu.Enabled:=false;

end;

procedure TMainfrm.popupOptionsClick(Sender: TObject);
begin
  Optionsfrm.showmodal;

  Communicator.RefreshOptions;

  Ejector.CardPollingInterval := Options.CardPollingInterval;
  Ejector.CardPolling:=Options.CardPolling;

  if Options.MaxWidth >0 then
    Mainfrm.Constraints.MaxWidth := options.MaxWidth
  else
    Mainfrm.Constraints.MaxWidth := null;

  AddCustomCardReaders(CardReaders, Ejector);

  FillDriveList; //Options probably changed - rather than lots of checking what option has changed just rescan no matter what
  ResizeTree;
end;

procedure TMainfrm.GUIRemoveDrive(MountPoint: String; RemoveCard: boolean);
var
  EjectError: integer;
begin
  //Check if trying to eject drive that its running from
  if IsAppRunningFromThisLocation( MountPoint ) then
  begin
    StartInMobileMode('/NOSAVE ' + '/REMOVEMOUNTPOINT ' + StrQuote(MountPoint, '"'));
    CloseProgram;
    Exit;
  end;

  //Otherwise just eject
  Tree.Enabled:=false;
  if Ejector.RemoveDrive(MountPoint, EjectError, options.UseWindowsNotifications, RemoveCard, options.CloseRunningApps_Ask, options.CloseRunningApps_Force) = false then
  begin;
    Tree.Enabled:=true;
    if options.UseWindowsNotifications = false then  //If true then windows shows its own error messagebox
    begin
      case EjectError of
        REMOVE_ERROR_UNKNOWN_ERROR:   Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
        REMOVE_ERROR_DRIVE_NOT_FOUND: Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_DRIVE_NOT_FOUND, bfError);
        REMOVE_ERROR_DISK_IN_USE:     Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_DISK_IN_USE, bfError);
        REMOVE_ERROR_NO_CARD_MEDIA:   Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_NO_CARD_MEDIA, bfError);
        REMOVE_ERROR_WINAPI_ERROR:    Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_WINAPI_ERROR, bfError)
        else
        if EjectError = 0 then Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError) //error code 0 means successful!
        else
        Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR_REPORT_CODE + inttostr(EjectError), bfError);
      end;
    end;

    exit;
  end
  else //Eject successful
  begin
    if options.UseWindowsNotifications = false then  //If true then windows shows its own message
    Communicator.DoMessage( '(' + MountPoint + ':) ' + str_REMOVE_SUCCESSFUL, bfInfo );
  end;

  if RemoveCard then //No WMDeviceChange fired for cards
  begin
    ChangeDriveVisibility;
    ResizeTree;
    tree.Enabled:=true;
  end;

  if options.AfterEject= int_AFTER_EJECT_DO_CLOSE then CloseProgram;
  if options.AfterEject= int_AFTER_EJECT_DO_MINIMIZE then Application.Minimize;
end;

procedure TMainfrm.ResizeTree;
var
  i, NodeWidth, NodesHeight: integer;
  TempNode, PrevNode: pVirtualNode;
  statictext: string;
const
  VertFormPadding: integer = 100;
  HorizFormPadding: integer = 140; //This could be wrong  140
begin
  if Tree.RootNodeCount = 0 then exit;
  if Options.AutoResize = false then exit;
  if tree.Enabled = false then exit;

  Tree.BeginUpdate;

  NodesHeight:=Tree.NodeHeight[tree.GetFirst] * Tree.VisibleCount; {RootNodeCount;} //All nodes same height

  NodeWidth:=0;
  TempNode:=tree.GetFirst;
  for I := 0 to Tree.RootNodeCount - 1 do
  begin
    if Tree.IsVisible[TempNode] = false then continue; //ignore hidden drives

    if Ejector.DrivesCount > 0 then
      statictext:=Ejector.RemovableDrives[TempNode.Index].VolumeLabel
    else
      statictext:='';

    //Account for Multiline - first line and second line
    if mainfrm.Canvas.TextWidth( StrBefore(#13#10, tree.Text[TempNode, 0]) )  > NodeWidth then
      NodeWidth := mainfrm.Canvas.TextWidth( StrBefore(#13#10, tree.Text[TempNode, 0] ) );

    if mainfrm.Canvas.TextWidth( StrAfter(#13#10, tree.Text[TempNode, 0]) )  > NodeWidth then
      NodeWidth := mainfrm.Canvas.TextWidth( StrAfter(#13#10, tree.Text[TempNode, 0] ) );

    prevNode:=TempNode;
    TempNode:=Tree.GetNext(PrevNode);
  end;

  mainfrm.Width:=NodeWidth + HorizFormPadding;
  mainfrm.Height:=NodesHeight + VertFormPadding;

{--------------------------------Docking---------------------------------------}
  case Options.SnapTo of
    //Snapping disabled
    0:
    begin
      //Assume position is screen center or last saved position

      //Correct width and check if already docked at right
      if mainfrm.Left = screen.Width - mainfrm.Width then
      begin
        mainfrm.Width:=NodeWidth + HorizFormPadding;
        mainfrm.Left:= screen.Width - mainfrm.Width
      end
      else
        mainfrm.Width:=NodeWidth + HorizFormPadding;

      //Correct height and check if already docked at bottom
      if mainfrm.Top = screen.Height - mainfrm.Height - GetTaskBarHeight then
      begin
        mainfrm.Height:=NodesHeight + VertFormPadding;
        mainfrm.top:= screen.Height - mainfrm.Height - GetTaskBarHeight;
      end
      else
        mainfrm.Height:=NodesHeight + VertFormPadding;

      //Check and correct position if resolution different
      if mainfrm.Left < 0 then
        mainfrm.Left:=0;

      if mainfrm.Left + mainfrm.Width > screen.Width then
        mainfrm.Left:=screen.Width - mainfrm.Width;

      if mainfrm.Top < 0 then
        mainfrm.Top:=0;


      //Stop form resizing so its below taskbar if its docked at the bottom
      //Also corrects for different resolution - if it was previously docked at bottom
      if (mainfrm.Top + mainfrm.Height) > (screen.Height - GetTaskBarHeight)  then
        mainfrm.Top := screen.Height - mainfrm.Height - GetTaskBarHeight;
    end;

    1:
    //Bottom right
    begin
      if GetTaskBarPos = _RIGHT then
        mainfrm.Left := (screen.Width - mainfrm.Width) - GetTaskBarWidth
      else
        mainfrm.Left:=screen.Width - mainfrm.Width;

      if GetTaskBarPos = _BOTTOM then
        mainfrm.top:= screen.Height - mainfrm.Height - GetTaskBarHeight
      else
        mainfrm.top:= screen.Height - mainfrm.Height;
      end;

    //Top right
    2:
    begin
      if GetTaskBarPos = _RIGHT then
        mainfrm.Left := (screen.Width - mainfrm.Width) - GetTaskBarWidth
      else
        mainfrm.Left:=screen.Width - mainfrm.Width;

      if GetTaskBarPos = _TOP then
        mainfrm.Top := GetTaskBarHeight
      else
        mainfrm.top:= 0;
    end;

    //Top left
    3:
    begin
      if GetTaskBarPos = _LEFT then
        mainfrm.Left := GetTaskBarWidth
      else
        mainfrm.Left:= 0;

      if GetTaskBarPos = _TOP then
        mainfrm.Top := GetTaskBarHeight
      else
        mainfrm.top:= 0;
    end;

    //Bottom left
    4:
    begin
      if GetTaskBarPos = _LEFT then
        mainfrm.Left := GetTaskBarWidth
      else
        mainfrm.Left:= 0;

      if GetTaskBarPos = _BOTTOM then
        mainfrm.Top := screen.Height - mainfrm.Height - GetTaskBarHeight
      else
       mainfrm.top:= screen.Height - mainfrm.Height;
    end;

  end;

{------------------------------------------------------------------------------}


  //Stops the occasional statictext glitches where they arent fully repainted
  tree.ReinitChildren(tree.RootNode, true);
  Tree.EndUpdate;
end;

procedure TMainfrm.TrayIcon1Click(Sender: TObject);
begin
  //SendMessage(handle, WM_SYSCOMMAND, SC_RESTORE, 0);
  Application.Restore;  {restore the application}
  if WindowState = wsMinimized then WindowState := wsNormal;  {Reset minimized state}
  Visible:=true;
  ResizeTree;
  SetForegroundWindow(Application.Handle); {Force form to the foreground }
end;

procedure TMainfrm.TreeDblClick(Sender: TObject);
var
  RemoveCard: boolean;
  MountPoint: String;
begin
  if Ejector.DrivesCount = 0 then exit;

  if Tree.SelectedCount = 0 then exit;

  //TODO - make switch for this and add it to startinmobilemode below
  //TODO - sort this out for hotkey press too
  RemoveCard:=Ejector.RemovableDrives[Tree.focusednode.Index].IsCardReader;

  MountPoint:=Ejector.RemovableDrives[Tree.focusednode.Index].DriveMountPoint;

  GUIRemoveDrive(MountPoint, RemoveCard);
end;

procedure TMainfrm.TreeDrawText(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
  Node: PVirtualNode; Column: TColumnIndex; const Text: string;
  const CellRect: TRect; var DefaultDraw: Boolean);
var
  DrawRect: TRect;
  DrawFlags: Cardinal;
  DrawParams: TDrawTextParams;
  TextEnds: integer;
  TempText: string;
begin
  defaultdraw:=false;

  DrawRect := CellRect;
  DrawFlags := DT_END_ELLIPSIS or DT_NOPREFIX {or DT_WORDBREAK} or DT_EDITCONTROL;
  DrawText(TargetCanvas.Handle, PChar(Text), -1, DrawRect, DrawFlags or DT_CALCRECT);
  DrawRect.Right := CellRect.Right;
  if DrawRect.Bottom < CellRect.Bottom then
    OffsetRect(DrawRect, 0, (CellRect.Bottom - DrawRect.Bottom) div 2)
  else
    DrawRect.Bottom := CellRect.Bottom;

  ZeroMemory(@DrawParams, SizeOf(DrawParams));
  DrawParams.cbSize := SizeOf(DrawParams);

  //See if there's a newline character
  TextEnds := AnsiPos(#13#10, Text);
  if TextEnds > 0 then
  begin
    //Draw the top line
    TempText:=Copy(Text, 1, TextEnds);
    DrawTextEx(TargetCanvas.Handle, PChar(TempText), -1, DrawRect, DrawFlags, @DrawParams);

    //Draw the bottom line in bold
    TempText:=Copy(Text, TextEnds, length(text));
    TargetCanvas.Font.Style :=[fsBold];
    DrawTextEx(TargetCanvas.Handle, PChar(TempText), -1, DrawRect, DrawFlags, @DrawParams);
  end
  else //draw normally
  begin
    DrawTextEx(TargetCanvas.Handle, PChar(Text), -1, DrawRect, DrawFlags, @DrawParams);
  end;
end;

procedure TMainfrm.DrivePopupMenuHandler(Sender: TObject);
var
  MountPoint: string;
  EjectCard: boolean;
begin
  with Sender as TMenuItem do
  begin
    MountPoint:=Ejector.RemovableDrives[tag].DriveMountPoint;
    EjectCard:=Ejector.RemovableDrives[tag].IsCardReader;
    GUIRemoveDrive(MountPoint, EjectCard);
  end;
end;

procedure TMainfrm.FillDriveList;
begin
  Tree.BeginUpdate;

  if Ejector.DrivesCount = 0 then
  begin
    Tree.RootNodeCount:=1
  end
  else
  begin
    Tree.RootNodeCount:=Ejector.DrivesCount;
    Tree.FocusedNode:=Tree.GetFirst;
    Tree.Selected[Tree.GetFirst]:=true;
  end;

  AddCustomCardReaders(CardReaders, Ejector);
  ChangeDriveVisibility;
  AddDrivePopups;
  Tree.EndUpdate;

  //if tree is resized when form is minimised then form partially restores itself
  if WindowState <> wsMinimized then
    ResizeTree;
end;

procedure TMainfrm.ChangeDriveVisibility;
var
  i: integer;
  List: TList<Integer>;
  TempNode, PrevNode: pVirtualNode;
begin
  if Ejector.DrivesCount = 0 then //Make that first node visible again
  begin
    Tree.IsVisible[Tree.GetFirst] := true;
    exit;
  end;

  //Make all drives visible again to start with
  TempNode:=tree.GetFirst;
  for I := 0 to Tree.RootNodeCount - 1 do
  begin
    Tree.IsVisible[TempNode] := true;
    prevNode:=TempNode;
    TempNode:=Tree.GetNext(PrevNode);
  end;

  List := TList<Integer>.Create();
  try
    TempNode:=tree.GetFirst;
    for I := 0 to Tree.RootNodeCount - 1 do
    begin //First check if all card readers should be hidden
      if Options.ShowCardReaders = false then
      begin
        if Ejector.RemovableDrives[i].IsCardReader then
          Tree.IsVisible[TempNode] := false;
      end
      else //If not check if card readers with no media in should be hidden
      if Options.HideCardReadersWithNoMedia then
      begin
        if Ejector.RemovableDrives[i].IsCardReader then
          if Ejector.RemovableDrives[i].CardMediaPresent = false then
            Tree.IsVisible[TempNode] := false;
      end;

      if Options.ShowPartitionsAsOne then
      begin
        if Ejector.RemovableDrives[i].IsCardReader = false then  //Dont group card readers
        begin
          if Ejector.RemovableDrives[i].HasSiblings then
            if List.IndexOf(Ejector.RemovableDrives[i].ParentDevInst) <> -1 then //drive with same is already found and visible
              Tree.IsVisible[TempNode] := false
            else
              List.Add(Ejector.RemovableDrives[i].ParentDevInst);
            end;
      end;

      prevNode:=TempNode;
      TempNode:=Tree.GetNext(PrevNode);
    end;
  finally
    List.Free;
  end;

end;

procedure TMainfrm.AddDrivePopups;
var
  i: integer;
  TempNode, PrevNode: pVirtualNode;
begin
  if DrivePopups <> nil then
  for i:=low(DrivePopups) to high(DrivePopups) do
  begin
    DrivePopups[i].Free;
  end;

  if Ejector.DrivesCount = 0 then
  begin
    DrivePopups:=nil;
    exit;
  end;

  TempNode:=tree.GetFirst;
  SetLength(DrivePopups, Ejector.DrivesCount);
  for i:=low(DrivePopups) to high(DrivePopups) do
  begin
    DrivePopups[i]:=TMenuItem.Create(Self);
    DrivePopups[i].Caption:=Ejector.RemovableDrives[i].DriveMountPoint + ':   ' +
      Ejector.RemovableDrives[i].VendorId + ' ' +
      Ejector.RemovableDrives[i].ProductID;

    if Ejector.RemovableDrives[i].VolumeLabel > '' then
      DrivePopups[i].Caption:=DrivePopups[i].Caption + '  (' +
      Ejector.RemovableDrives[i].VolumeLabel + ')';


    DrivePopups[i].Tag:=i; //Store drive index for eject later

    begin  //Image index
      if pos('IPOD', Uppercase(Ejector.RemovableDrives[i].ProductID )) > 0  then
        DrivePopups[i].ImageIndex:=4
      else
      if Ejector.RemovableDrives[i].BusType = 4 then //firewire
        DrivePopups[i].ImageIndex:=7
      else
      if Ejector.RemovableDrives[i].IsCardReader then
      begin
        if Ejector.RemovableDrives[i].CardMediaPresent then
          DrivePopups[i].ImageIndex:=6
        else
          DrivePopups[i].ImageIndex:=5
      end
      else
      if Options.ShowPartitionsAsOne and Ejector.RemovableDrives[i].HasSiblings then
        DrivePopups[i].ImageIndex:=8
      else
        DrivePopups[i].ImageIndex:=3;
    end;

    popupMenuTray.Items[2].add(DrivePopups[i]); //Add to the eject submenu
    DrivePopups[i].OnClick:=DrivePopupMenuHandler;


    //Show/hide popups - match to whether node is visible in the tree
    if Tree.IsVisible[TempNode] then
      DrivePopups[i].Visible := true
    else
    DrivePopups[i].Visible := false;

    prevNode:=TempNode;
    TempNode:=Tree.GetNext(PrevNode);
  end;
end;

procedure TMainfrm.TreeGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
begin
  if Ejector.Busy then exit;

  if Kind <> ikOverlay then //fix for vt bug
  begin
    if Ejector.DrivesCount = 0 then
      ImageIndex:=1
    else
    if pos('IPOD', Uppercase(Ejector.RemovableDrives[node.index].ProductID )) > 0  then
      ImageIndex:=2
    else
    if Ejector.RemovableDrives[node.index].BusType = 4 then //firewire
      ImageIndex:=5
    else
    if Ejector.RemovableDrives[node.index].IsCardReader then
    begin
      if Ejector.RemovableDrives[node.index].CardMediaPresent then
        ImageIndex:=4
      else
        ImageIndex:=3
    end
    else
    if Options.ShowPartitionsAsOne and Ejector.RemovableDrives[node.Index].HasSiblings then
      ImageIndex:=6
    else
      ImageIndex:=0;
  end;

end;

procedure TMainfrm.TreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := 0;
end;

procedure TMainfrm.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  if Ejector.Busy then exit;

  if Ejector.DrivesCount = 0 then
  case texttype of
    ttNormal: CellText:= str_No_Drive;
    ttStatic: CellText:= '';
  end
  else
  if TextType = ttNormal then
  begin
    if Options.ShowPartitionsAsOne and Ejector.RemovableDrives[Node.Index].HasSiblings then //Just show name not mountpoint
      CellText:=Ejector.RemovableDrives[Node.Index].VendorId + ' ' + Ejector.RemovableDrives[Node.Index].ProductID
    else
    begin  //Build a string - trying to avoid orphaned newline characters - tre bug means they show up as rectangles in xp
      if Ejector.RemovableDrives[Node.Index].VolumeLabel > '' then                   //Trim because VendorId is empty sometimes - so there ends up being a space then productid
        CellText:='(' + Ejector.RemovableDrives[Node.Index].DriveMountPoint + ') ' + Trim( Ejector.RemovableDrives[Node.Index].VendorId + ' ' + Ejector.RemovableDrives[Node.Index].ProductID) + #13#10 + Ejector.RemovableDrives[Node.Index].VolumeLabel
      else
        CellText:='(' + Ejector.RemovableDrives[Node.Index].DriveMountPoint + ') ' + Trim( Ejector.RemovableDrives[Node.Index].VendorId + ' ' + Ejector.RemovableDrives[Node.Index].ProductID);
    end;
  end;

end;

procedure TMainfrm.TreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
begin
  Include(InitialStates, ivsMultiline);
end;

procedure TMainfrm.TreeKeyPress(Sender: TObject; var Key: Char);
begin
  if key = #13 then
    Tree.OnDblClick(Mainfrm);
end;

procedure TMainfrm.TreeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Ejector.DrivesCount = 0 then exit;
  if Tree.SelectedCount = 0 then exit;

  if (ssDouble in Shift) and (Button = mbRight) then
    ShellExec(0, 'open', Ejector.RemovableDrives[Tree.focusednode.Index].DriveMountPoint, '', '', SW_SHOWNORMAL);
end;

procedure TMainfrm.UpdateFormStrings;
begin
  mainFrm.Caption               := str_Main_Caption;
  lblMore.Caption               := str_Main_Bottom_Popup;
  tree.Header.Columns[0].Text   := str_Main_Tree_Header;
  //tree.Hint                     := str_Tree_Hint;
  popupAbout.Caption            := str_Main_Popup_About;
  popupOptions.Caption          := str_Main_Popup_Options;
  popupEjectMenu.Caption        := str_Main_Popup_Eject;
  popupExit.Caption             := str_Main_Popup_Exit;
end;

procedure TMainfrm.OnDrivesChanged(Sender: TObject);
begin
  Tree.Enabled:=true;

  FillDriveList;
end;

end.

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
  Manages communication between the program and the user, switching between
  different methods of communication depending on whats available.
}

unit uCommunicationManager;

interface

uses
  classes, extctrls, dialogs, sysutils, windows, forms,
  uDiskEjectUtils, uDiskEjectOptions;

type
  TCommunicationManager = class
  private
    fUseBalloonMessages: boolean;
    fTrayIcon: TTrayIcon;
  public
    constructor Create(TrayIcon: TTrayIcon);
    destructor Destroy; override;
    procedure RefreshOptions;
    procedure DoMessage(Text: string; Flags: TBalloonFlags);
  end;

implementation

const
  MB_TIMEDOUT = 32000;

function MessageBoxTimeOut(hWnd: HWND; lpText: PChar; lpCaption: PChar; uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall; external user32 name 'MessageBoxTimeoutW';

constructor TCommunicationManager.Create(TrayIcon: TTrayIcon);
begin
  if TrayIcon = nil then
    raise Exception.Create('Tray Icon passed to communicator is nil!');

  fTrayIcon := TrayIcon;

  if (uDiskEjectUtils.BalloonTipsEnabled) and (Options.BalloonMessages) then
    fUseBalloonMessages := true
  else
    fUseBalloonMessages := false;
end;

destructor TCommunicationManager.Destroy;
begin

  inherited;
end;

procedure TCommunicationManager.DoMessage(Text: string; Flags: TBalloonFlags);
const
  TimeoutMilliSecs: integer = 5000;
var
  //DlgFlags: TMsgDlgType;
  iFlags: Integer;
begin
  {First perform the audio notification, determine the type by using the flag
   its a bit hacky but it works}
  if options.AudioNotifications then
  begin
    if fUseBalloonMessages then
      case Flags of
        bfInfo: MessageBeep(MB_ICONEXCLAMATION);
        bfError: MessageBeep(MB_ICONSTOP);
      end

    //Otherwise we use MsgDlg which generates its own sounds
  end;


  if fUseBalloonMessages then
  begin
    fTrayIcon.BalloonHint := Text;
    fTrayIcon.BalloonFlags := Flags;
    fTrayIcon.ShowBalloonHint;
  end
  else
  begin
    {if options.AudioNotifications = false then
      DlgFlags := mtCustom //mtCustom stops the beep caused by messagedlg
    else}
    {case Flags of
      bfNone:     DlgFlags := mtCustom;
      bfInfo:     DlgFlags := mtInformation;
      bfWarning:  DlgFlags := mtWarning;
      bfError:    DlgFlags := mtError;
    else          DlgFlags := mtCustom;
    end;

    MessageDlg( Text, DlgFlags, [mbOK], 0);}

    case Flags of
      bfNone:     iFlags := MB_OK or MB_SETFOREGROUND or MB_SYSTEMMODAL or MB_USERICON;
      bfInfo:     iFlags := MB_OK or MB_SETFOREGROUND or MB_SYSTEMMODAL or MB_ICONINFORMATION;
      bfWarning:  iFlags := MB_OK or MB_SETFOREGROUND or MB_SYSTEMMODAL or MB_ICONWARNING;
      bfError:    iFlags := MB_OK or MB_SETFOREGROUND or MB_SYSTEMMODAL or MB_ICONERROR;
    else          iFlags := MB_OK or MB_SETFOREGROUND or MB_SYSTEMMODAL or MB_USERICON;
    end;

    //Message box that automatically closes after x seconds
    MessageBoxTimeout(Application.Handle, PChar(Text), 'USB Disk Ejector', iFlags, 0, TimeoutMilliSecs);
  end;
end;

procedure TCommunicationManager.RefreshOptions;
begin
  if (uDiskEjectUtils.BalloonTipsEnabled) and (Options.BalloonMessages) then
    fUseBalloonMessages := true
  else
    fUseBalloonMessages := false;
end;

end.



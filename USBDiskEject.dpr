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


program USBDiskEject;

{$R *.res}

uses
  Forms,
  sysutils,
  dialogs,
  extctrls,
  windows,
  formMain in 'formMain.pas' {Mainfrm},
  uDriveEjector in 'uDriveEjector.pas',
  uDiskEjectConst in 'uDiskEjectConst.pas',
  formOptions in 'formOptions.pas' {Optionsfrm},
  formAbout in 'formAbout.pas' {Aboutfrm},
  uCustomHotKeyManager in 'uCustomHotKeyManager.pas',
  uDiskEjectOptions in 'uDiskEjectOptions.pas',
  uProcessAndWindowUtils in 'uProcessAndWindowUtils.pas',
  uDiskEjectUtils in 'uDiskEjectUtils.pas',
  uCommunicationManager in 'uCommunicationManager.pas';

var
  strTempMountPoint: string;
  Ejector: TDriveEjector;
  EjectErrorCode: integer;
  CardEject: boolean;
  MyTrayIcon: TTrayIcon;
  Communicator: TCommunicationManager;

begin
  Application.Initialize;

  //TODO!!!!!!!!!!!!!!!!!!  Fix this with proper switches ************************
  CardEject:= true;
  //******************************************************************************

  // ? Param
  if FindCmdLineSwitch('?', true) then
  begin
    showMessage(str_Question);
    exit;
  end;

  // RemoveThis Param
  if options.CommandLine_RemoveThis then
  begin
    StartInMobileMode('/NOSAVE ' + '/REMOVEMOUNTPOINT ' + FindMountPoint( ExtractFilePath(Application.ExeName) ) );
    exit;
  end;


  // RemoveLetter Param
  if options.CommandLine_RemoveLetter then
  begin
    {Check if trying to eject drive that program is running from
    and check if mobile is false - in case somehow temp folder is on the drive
    you're trying to eject}
    if (IsAppRunningFromThisLocation(options.CommandLine_Param_RemoveLetter) ) and
       (options.InMobileMode = false) then
    begin
      StartInMobileMode('/NOSAVE ' + '/REMOVELETTER ' + options.CommandLine_Param_RemoveLetter);
      exit;
    end;

    if options.InMobileMode then //Wait for the program that started this one to exit
      Sleep(1500);

    Ejector:=TDriveEjector.Create;
    try

      MyTrayIcon := TTrayIcon.Create(application);
      try
        MyTrayIcon.Visible := true;
        MyTrayIcon.BalloonTitle := 'USB Disk Ejector';
        MyTrayIcon.BalloonTimeout := 4000;

        Communicator := TCommunicationManager.Create(MyTrayIcon);
        try
          if Ejector.RemoveDrive(ConvertDriveLetterToMountPoint(options.CommandLine_Param_RemoveLetter), EjectErrorCode, options.UseWindowsNotifications, CardEject, options.CloseRunningApps_Ask, options.CloseRunningApps_Force) then
          begin //Eject succeeded
            if options.UseWindowsNotifications = false then  //If true then windows shows its own message
            begin
              Communicator.DoMessage('(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_SUCCESSFUL, bfInfo);
              Sleep(4000); // Give notification time to be shown
            end;
          end
          else //Eject failed
          if options.UseWindowsNotifications=false then //if its true then windows shows its own message
          begin
            case EjectErrorCode of
              REMOVE_ERROR_UNKNOWN_ERROR:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
              REMOVE_ERROR_DRIVE_NOT_FOUND: Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_ERROR_DRIVE_NOT_FOUND, bfError);
              REMOVE_ERROR_DISK_IN_USE:     Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_ERROR_DISK_IN_USE, bfError);
              REMOVE_ERROR_NO_CARD_MEDIA:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_ERROR_NO_CARD_MEDIA, bfError);
              REMOVE_ERROR_WINAPI_ERROR:    Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_ERROR_WINAPI_ERROR, bfError);
              else
              Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLetter + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
            end;
            Sleep(4000); // Give notification time to be shown
          end;

        finally
          Communicator.Free;
        end;

      finally
        MyTrayIcon.Free;
      end;

    finally
      Ejector.free;
    end;


    if options.InMobileMode then //Cleanup
      CreateCleanupBatFileAndRun;

    Exit;
  end;


  // RemoveMountPoint Param
  if options.CommandLine_RemoveMountPoint then
  begin
    {Check if trying to eject drive that program is running from
    and check if mobile is false - in case somehow temp folder is on the drive
    you're trying to eject}
    if ( IsAppRunningFromThisLocation( options.CommandLine_Param_RemoveMountPoint ) ) and
       (options.InMobileMode = false) then
    begin
      StartInMobileMode('/NOSAVE ' + '/REMOVEMOUNTPOINT ' + options.CommandLine_Param_RemoveMountPoint);
      exit;
    end;

    if options.InMobileMode then //Wait for the program that started this one to exit
      Sleep(1500);

    Ejector:=TDriveEjector.Create;
    try

      MyTrayIcon := TTrayIcon.Create(application);
      try
        MyTrayIcon.Visible := true;
        MyTrayIcon.BalloonTitle := 'USB Disk Ejector';
        MyTrayIcon.BalloonTimeout := 4000;

        Communicator := TCommunicationManager.Create(MyTrayIcon);
        try
          if Ejector.RemoveDrive(options.CommandLine_Param_RemoveMountPoint, EjectErrorCode, options.UseWindowsNotifications, CardEject, options.CloseRunningApps_Ask, options.CloseRunningApps_Force) then
          begin //Eject succeeded
            if options.UseWindowsNotifications = false then  //If true then windows shows its own message
            begin
              Communicator.DoMessage('(' + options.CommandLine_Param_RemoveMountPoint + ') ' + str_REMOVE_SUCCESSFUL, bfInfo);
              Sleep(4000); // Give notification time to be shown
            end;
          end
          else //Eject failed
          if options.UseWindowsNotifications=false then //if its true then windows shows its own message
          begin
            case EjectErrorCode of
              REMOVE_ERROR_UNKNOWN_ERROR:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveMountPoint + ') ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
              REMOVE_ERROR_DRIVE_NOT_FOUND: Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveMountPoint + ') ' + str_REMOVE_ERROR_DRIVE_NOT_FOUND, bfError);
              REMOVE_ERROR_DISK_IN_USE:     Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveMountPoint + ') ' + str_REMOVE_ERROR_DISK_IN_USE, bfError);
              REMOVE_ERROR_NO_CARD_MEDIA:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveMountPoint + ') ' + str_REMOVE_ERROR_NO_CARD_MEDIA, bfError);
              REMOVE_ERROR_WINAPI_ERROR:    Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveMountPoint + ') ' + str_REMOVE_ERROR_WINAPI_ERROR, bfError);
              else
              Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveMountPoint + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
            end;
            Sleep(4000); // Give notification time to be shown
          end;

        finally
          Communicator.Free;
        end;

      finally
        MyTrayIcon.Free;
      end;

    finally
      Ejector.free;
    end;


    if options.InMobileMode then //Cleanup
      CreateCleanupBatFileAndRun;

    Exit;
  end;



  // REMOVENAME Param
  if options.CommandLine_RemoveName then
  begin
    if options.InMobileMode then  //wait 1.5 seconds for program that started this one to exit
      Sleep(1500);

    strTempMountPoint:=MatchNameToMountPoint(options.CommandLine_Param_RemoveName);
    {Check if trying to eject drive that program is running from
    and check if mobile is false - in case somehow temp folder is on the drive
    you're trying to eject}
    if ( IsAppRunningFromThisLocation( strTempMountPoint ) ) and
       (options.InMobileMode = false) and (strTempMountPoint <> '')then
    begin
      StartInMobileMode('/NOSAVE ' + '/REMOVEMOUNTPOINT ' + strTempMountPoint);
      exit;
    end
    else
    begin
      MyTrayIcon := TTrayIcon.Create(application);
      try
        MyTrayIcon.Visible := true;
        MyTrayIcon.BalloonTitle := 'USB Disk Ejector';
        MyTrayIcon.BalloonTimeout := 4000;

        Communicator := TCommunicationManager.Create(MyTrayIcon);
        try
          if strTempMountPoint = '' then //Drive not found
          begin
            Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ':) ' + str_REMOVE_ERROR_NAME_NOT_FOUND, bfError);
            Sleep(4000); // Give notification time to be shown
          end
          else
          begin
            Ejector:=TDriveEjector.Create;
            try
              if Ejector.RemoveDrive(strTempMountPoint, EjectErrorCode, options.UseWindowsNotifications, CardEject, options.CloseRunningApps_Ask, options.CloseRunningApps_Force) then
              begin //Eject succeeded
                if options.UseWindowsNotifications = false then  //If true then windows shows its own message
                begin
                  Communicator.DoMessage('(' + options.CommandLine_Param_RemoveName + ') ' + str_REMOVE_SUCCESSFUL, bfInfo);
                  Sleep(4000); // Give notification time to be shown
                end;
              end
              else //Eject failed
              if options.UseWindowsNotifications=false then //if its true then windows shows its own message
              begin
                case EjectErrorCode of
                  REMOVE_ERROR_UNKNOWN_ERROR:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ') ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
                  REMOVE_ERROR_DRIVE_NOT_FOUND: Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ') ' + str_REMOVE_ERROR_DRIVE_NOT_FOUND, bfError);
                  REMOVE_ERROR_DISK_IN_USE:     Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ') ' + str_REMOVE_ERROR_DISK_IN_USE, bfError);
                  REMOVE_ERROR_NO_CARD_MEDIA:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ') ' + str_REMOVE_ERROR_NO_CARD_MEDIA, bfError);
                  REMOVE_ERROR_WINAPI_ERROR:    Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ') ' + str_REMOVE_ERROR_WINAPI_ERROR, bfError);
                  else
                  Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveName + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
                end;
                Sleep(4000); // Give notification time to be shown
              end;
            finally
              Ejector.Free;
            end;
          end;
        finally
          Communicator.Free;
        end;
      finally
        MyTrayIcon.Free;
      end;
    end;

    if options.InMobileMode then //Cleanup
      CreateCleanupBatFileAndRun;

    exit;
  end;



  //RemoveLabel Param
  if options.CommandLine_RemoveLabel then
  begin
    if options.InMobileMode then  //wait 1.5 seconds for program that started this one to exit
      Sleep(1500);

    strTempMountPoint:=MatchLabelToMountPoint(options.CommandLine_Param_RemoveLabel);
    {Check if trying to eject drive that program is running from
    and check if mobile is false - in case somehow temp folder is on the drive
    you're trying to eject}
    if ( IsAppRunningFromThisLocation( strTempMountPoint ) ) and
       (options.InMobileMode = false) and (strTempMountPoint <> '')then
    begin
      StartInMobileMode('/NOSAVE ' + '/REMOVEMOUNTPOINT ' + strTempMountPoint);
      exit;
    end
    else
    begin
      MyTrayIcon := TTrayIcon.Create(application);
      try
        MyTrayIcon.Visible := true;
        MyTrayIcon.BalloonTitle := 'USB Disk Ejector';
        MyTrayIcon.BalloonTimeout := 4000;

        Communicator := TCommunicationManager.Create(MyTrayIcon);
        try
          if strTempMountPoint = '' then //Drive not found
          begin
            Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ':) ' + str_REMOVE_ERROR_LABEL_NOT_FOUND, bfError);
            Sleep(4000); // Give notification time to be shown
          end
          else
          begin
            Ejector:=TDriveEjector.Create;
            try
              if Ejector.RemoveDrive(strTempMountPoint, EjectErrorCode, options.UseWindowsNotifications, CardEject, options.CloseRunningApps_Ask, options.CloseRunningApps_Force) then
              begin //Eject succeeded
                if options.UseWindowsNotifications = false then  //If true then windows shows its own message
                begin
                  Communicator.DoMessage('(' + options.CommandLine_Param_RemoveLabel + ') ' + str_REMOVE_SUCCESSFUL, bfInfo);
                  Sleep(4000); // Give notification time to be shown
                end;
              end
              else //Eject failed
              if options.UseWindowsNotifications=false then //if its true then windows shows its own message
              begin
                case EjectErrorCode of
                  REMOVE_ERROR_UNKNOWN_ERROR:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ') ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
                  REMOVE_ERROR_DRIVE_NOT_FOUND: Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ') ' + str_REMOVE_ERROR_DRIVE_NOT_FOUND, bfError);
                  REMOVE_ERROR_DISK_IN_USE:     Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ') ' + str_REMOVE_ERROR_DISK_IN_USE, bfError);
                  REMOVE_ERROR_NO_CARD_MEDIA:   Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ') ' + str_REMOVE_ERROR_NO_CARD_MEDIA, bfError);
                  REMOVE_ERROR_WINAPI_ERROR:    Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ') ' + str_REMOVE_ERROR_WINAPI_ERROR, bfError);
                  else
                  Communicator.DoMessage( '(' + options.CommandLine_Param_RemoveLabel + ':) ' + str_REMOVE_ERROR_UNKNOWN_ERROR, bfError);
                end;
                Sleep(4000); // Give notification time to be shown
              end;
            finally
              Ejector.Free;
            end;
          end;
        finally
          Communicator.Free;
        end;
      finally
        MyTrayIcon.Free;
      end;
    end;

    if options.InMobileMode then //Cleanup
      CreateCleanupBatFileAndRun;

    exit;
  end;



  //*******************Disable this before release !!!!*************************
  ReportMemoryLeaksOnShutdown:=true;
  //****************************************************************************


  Application.Title := 'USB Disk Ejector';
  Application.CreateForm(TMainfrm, Mainfrm);
  Application.CreateForm(TAboutfrm, Aboutfrm);
  if options.StartAppMinimised then
    Mainfrm.WindowState:=wsMinimized;

  if options.PreserveWindowLocation then
    mainfrm.Position:=poDesigned
  else
    mainfrm.Position:=poScreenCenter;

  if options.SnapTo > 0 then
    mainfrm.Position:=poDesigned;

   
  Application.CreateForm(TOptionsfrm, Optionsfrm);
  Application.Run;
end.

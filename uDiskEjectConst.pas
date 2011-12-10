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

unit uDiskEjectConst;

interface

const
  str_App_Version: string             = '1.3.0.3';
  str_Ini_FileName: string            = 'USB_Disk_Eject.cfg';
  str_No_Drive: string                = 'No disks found.';
  str_Temp_Folder_Write_Error: string = 'Could not write to windows temp dir!' + #13 + 'The program will now exit';
  str_Minimize: string                = ' The program is still running! Click on the icon to restore the program.';

  str_Question: string = '/?'           +  #13 + 'Displays this message.' + #13#13 +
                        '/NOSAVE'       +  #13 + 'Options are not saved, no cfg file will be created. But if theres USB_Disk_Eject.cfg in the path, options will be read from it.' + #13#13 +

                        //'/NONOTIFICATIONS' + #13 + 'No eject notifications are displayed and no audio notifications are heard. You will get NO feedback from the program about whether an ejection has succeeded or failed' + #13#13 +
                        //'/NOVISUALNOTIFICATIONS' + #13 + 'No messageboxes or balloon hints will be displayed to notify that an ejection has succeeded or failed. Audio notifications are still enabled though' + #13#13 +
                        //'/NOAUDIONOTIFICATIONS' + #13 + 'No audio notifications will sound to notify that an ejection has succeeded or failed. Visual notifications are still enabled though' + #13#13 +
                        //'/USEWINDOWSNOTIFICATIONS' + #13 + 'Use Windows'' notifications instead of the programs own notifications' + #13#13 +
                        //'/CLOSEAPPS'    +  #13 + 'If any applications have been launched from the drive, ask them to close. If any applications refuse to close then the eject will fail. This switch is considered relatively safe and should mean that no unsaved data is lost.' + #13#13 +
                        //'/CLOSEAPPSFORCE' + #13 + 'If any applications have been launched from the drive, force them to close. This will mean that any unsaved data in those programs will be lost. This has the same effect as ending a task/process.'
                        '/REMOVETHIS'   +  #13 + 'Ejects the drive that the program is running from.' + #13 +  'Eg if the program is run from a usb stick on drive G then drive G would be ejected.' + #13#13 +
                        '/REMOVELABEL'  +  #13 + 'Ejects the drive with the specified label.'  + #13 +  'Partial label matching is possible if a wildcard (*) is used. Eg /REMOVELABEL *BEN would eject a drive that had Ben in its label (eg Ben''s Pen Drive).' + #13#13 +
                        '/REMOVELETTER' +  #13 + 'Ejects the drive with the specified drive letter.' + #13#13 +
                        '/REMOVEMOUNTPOINT' + #13 + 'Ejects the drive with the specified mountpoint.' + #13#13 +
                        '/REMOVENAME'   +  #13 + 'Ejects the drive with the specified name.' + #13 +  'Partial name matching is possible if a wildcard (*) is used. Eg /REMOVENAME *SANDISK would eject a drive that had Sandisk in its name.' + #13#13
                        ;



  str_Remove_Error_Drive_Not_Found           = 'The disk could not be ejected - the corresponding drive letter/mountpoint could not be found.';
  str_Remove_Error_Name_Not_Found            = 'The disk could not be ejected - the corresponding drive name could not be found.';
  str_Remove_Error_Label_Not_Found           = 'The disk could not be ejected - the corresponding drive label could not be found.';
  str_Remove_Error_Disk_In_Use               = 'The disk could not be ejected because it is in use.' + #13 + 'Close any programs that might be using the disk and try again.';
  str_Remove_Error_No_Card_Media             = 'No memory card was found in the specified drive.';
  str_Remove_Error_Winapi_Error              = 'The disk could not be ejected - a winapi error was encountered.' + #13#13 + 'This shouldn''t happen!';
  str_Remove_Error_Unknown_Error_Report_Code = 'The disk could not be ejected - an unknown error was encountered.' + #13#13 + 'Error code: ';
  str_Remove_Error_Unknown_Error             = 'The disk could not be ejected.' + #13 + 'Close any programs that might be using the disk and try again.';
  str_Remove_Error_None                      = 'The disk could not be ejected - but no errors were detected.' + #13#13 + 'The last error code was: ';

  str_Remove_Successful             = 'The disk was ejected successfully!';

  int_After_Eject_Do_Nothing        = 0;
  int_After_Eject_Do_Close          = 1;
  int_After_Eject_Do_Minimize       = 2;

  //Eject Error Codes
  REMOVE_ERROR_NONE                 = 0;
  REMOVE_ERROR_UNKNOWN_ERROR        = 1;
  REMOVE_ERROR_DRIVE_NOT_FOUND      = 2;
  REMOVE_ERROR_DISK_IN_USE          = 3;
  REMOVE_ERROR_NO_CARD_MEDIA        = 4;
  REMOVE_ERROR_WINAPI_ERROR         = 5;

  //Main form
  str_Main_Caption                  = 'USB Disk Ejector'; //'Safely Remove Disks';
  str_Main_Bottom_Popup             = 'More >>>';
  str_Main_Tree_Header              = 'Double click or press enter to safely remove a disk';
  str_Tree_Hint                     = 'Double click or press enter to remove a disk';
  str_Main_Popup_About              = 'About';
  str_Main_Popup_Options            = 'Options';
  str_Main_Popup_Eject              = 'Eject';
  str_Main_Popup_Exit               = 'Exit';

  //Options form
  str_Hotkey_Restore_Window         = 'Restore program window';
  str_Hotkey_Eject_Label            = 'Eject drive by label';
  str_Hotkey_Eject_Letter           = 'Eject drive by letter';
  str_Hotkey_Eject_MountPoint       = 'Eject drive by mountpoint';
  str_Hotkey_Eject_Name             = 'Eject drive by name';
  str_Hotkey_NoParam                = 'No parameter given! Select or type an item into the combobox and try again.';
  str_Hotkey                        = 'Hotkey: ';
  str_Hotkey_Remove_Error           = 'Error - could not remove hotkey!';
  str_Hotkey_Assign_Error           = 'Couldnt assign hotkey';
  str_Hotkey_Cannot_Restore: string = 'Hotkey cannot be restored!' + #13 + 'Please report this.';
  str_CardReader_Remove_Error       = 'Error - could not remove card reader from list!';
  str_CardReader_Add_Error          = 'Couldnt add card reader. Maybe its already in the list?';

implementation

end.


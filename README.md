# USB-Disk-Ejector
A program that allows you to quickly remove drives in Windows. It can eject USB disks, Firewire disks and memory cards. It is a quick, flexible, portable alternative to using Windows' `Safely Remove Hardware` dialog.

It will work on any version of Windows from XP onwards, that includes:

Windows XP, Vista, 7, 8, 10  (32 and 64 bit)

## What makes this so useful?

**It is quick.** Rather than clicking through the `Safely Remove Hardware` dialog you can very quickly remove drives or card media. You can even create shortcuts or hotkeys to eject a drive.

**It is simple.** The program is designed to be easy to use and its advanced options are hidden so that they dont get in the way.

**It is portable.** It can be stored and used on a removable device like a pen drive. It can even eject the disk that it is running from. It doesnt require administrator rights and doesnt need installing.

**It is flexible.** There are many features that can be customised such as hotkeys, positioning, notifications and post-eject actions.

**It can be run as a command line program.** The command line options are very flexible, they can be used to:

* Eject the drive that the program is running from.
* Eject a drive by specifying a drive letter.
* Eject a drive by specifying a drive name.
* Eject a drive by specifying a mountpoint
* Eject a drive by specifying a partial drive name.

So you could setup a hotkey, desktop shortcut or bat file to eject a drive. Or if you use a menu such as PStart or the Portable Apps launcher you could use the command line switches so that with one click the menu will exit, the program will run and the drive will be ejected. See the ‘Command Line’ section in the `readme` for more information.

**It can eject disks when Vista cant.** On Windows Vista, disks often cant be ejected because they have an open explorer window. Other versions of Windows will close any explorer windows belonging to a disk but Vista often doesnt – so USB Disk Ejector closes it before ejecting.

**It can eject disks when Windows sometimes cant.** If any applications are running from a disk then Windows wont be able to eject it. USB Disk Ejector can detect and auto-close any applications running from the disk before ejecting. Please note this closes applications that were launched from the disk not applications that have opened a file on the disk. See the limitations section in the `readme` for more information.

**It is small.** Less than 1.5MB (when UPX compressed)

**It is open source.** All source code can be found on my Github.

## What do I need to use this?

A removable USB or Firewire device such as a flash drive, digital camera or external hard drive. Any USB or Firewire device that shows as a disk should be removable by this.

For ejecting card media - such as flash memory cards any internal or external card reader should work.

# Using the program

1. Load the program, if you have any removable USB/Firewire drives or memory cards they will be shown in the list.
2. If you plug in any additional devices while the program is running then the list will automatically update to show them.
3. Double click on a device to remove it.
4. Unplug the device from your computer.

## More features:

*   Double right clicking on a drive opens an Explorer window for that disk.

*   Drives mounted in a folder [like this](http://lifehacker.com/373389/mount-usb-drives-in-assigned-folders-to-keep-them-straight) are also supported.

*   If your card reader is shown as a drive not a card reader then you can change this. In `options` go to the `Card Readers` tab. There you can define a particular drive as a card reader, it will then be treated and shown as a card reader.

*   The program has a system tray icon - you can right click this to eject disks. This is similar to the behaviour of the Windows `Safely Remove Hardware` tray icon.

*   Settings are saved in a file called `USB_Disk_Eject.cfg` - but this wont be created unless you change a setting in the options. It will always be saved into the same place as the program itself.

*   If you have a disk that has multiple drives (eg. a hard drive with multiple partitions) then this can be set to only show one entry in the program. To enable this tick `show drives with partitions as one entry` in the options. If you enable this option, then hovering your mouse over the disk will being up a tooltip showing what disks 'belong' to that entry.

*   There are many more features - click on `More` and go to `Options` to see the full list.

# Command Line

When using the program on the command line, settings that have been created when using the program normally may still be used. If `USB_Disk_Eject.cfg` is found in the same folder as the program then it will read and use settings from it. Settings such as removal notifications will be dictated by what has been set in options if this file is present.

This is particularly important when dealing with memory cards and card readers. For example, if a device has been defined as a card reader in `options` then when ejecting the program will honor this and eject the card media not the card reader device.

If you dont want the program to inherit options then make sure that `USB_Disk_Eject.cfg` is not present in the same folder.

The following command line options are available:

*   `/?` 
    Displays a dialog that shows all command line options.

*   `/NOSAVE`  
    Settings are not saved, no cfg file will be created. But if theres `USB_Disk_Eject.cfg` in the same place as the program, options will be read from it. Use this if you want to launch the program but stop it saving settings or overwriting existing settings.

*   `/CFGDIR` 
     Specify a different path for the cfg file (the file where settings are stored). Eg `/CFGDIR "c:\users\ben\desktop\stuff"`

*   `/REMOVETHIS`  
    Ejects the drive that the program is running from. Eg if the program is run from a usb stick on drive G then drive G would be ejected.

*   `/REMOVELETTER`  
    Ejects the specified drive letter. Eg `/REMOVELETTER G`

*   `/REMOVEMOUNTPOINT`  
    Ejects the specified mountpoint. Eg `/REMOVEMOUNTPOINT "C:\Test USB Disk Mount"`

*   `/REMOVENAME`  
    Ejects the drive with the specified name. Eg `/REMOVEDRIVE "Sandisk U3 Titanium"`  
    Partial name matching is possible if a wildcard (`*`) is used. Eg `/REMOVENAME "*SANDISK"` would eject a drive that had Sandisk in its name.

*   `/REMOVELABEL`  
    Ejects the drive with the specified label. Eg `/REMOVLABEL "Work Drive"`  
    Partial name matching is possible if a wildcard (`*`) is used. Eg `/REMOVELABEL "*BEN"` would eject a drive that had Ben in its label (eg Ben's Pen Drive).  
	
*   `/EJECTCARD`  
    Ejects the card media from a drive rather than trying to eject the drive itself.  
    Combine it with other switches Eg `/REMOVELETTER G /EJECTCARD` would eject an SD card in drive G.  	

The command line switches could be used to eject a drive from the command prompt, a bat file, a desktop shortcut or as part of a script or menu.

# Upgrading From Previous Versions (before v1.3)

If you are upgrading from a version before 1.3 then be aware that some command line switches have been removed:

*   `/SILENT`
*   `/SHOWEJECT`
*   `/CLOSEAPPS`
*   `/CLOSEAPPSFORCE`

These settings are now set in the `options` menu. If you are using the program from the command line and `USB_Disk_Eject.cfg` is found in the same folder as the program then it will read and use settings from it. If its not found then the default settings will be used.

Using these switches with this new version of the program won't cause any problems - they will just be ignored.

# Limitations/Bugs

Please [contact me](http://quickandeasysoftware.net/contact) or create an issue on Github if you spot any bugs or problems that arent listed below.

*   If you have balloon tips turned on in Windows XP then Windows shows a balloon tip when a device is removed (`device x can now be safely removed from the system`). If you remove one device and then try to remove another, the second device will not be removed until you close the balloon tip. If this irritates you, then you can try disabling balloon tips altogether. See [this](http://support.microsoft.com/default.aspx?scid=kb;en-us;307729) link for information on how to do this.

*   A disk eject can fail when there is still an application or process accessing the drive.  
    If the application that is accessing the drive is running from the drive that you're trying to eject then USB Disk Ejector can detect this and close it (see the options menu to enable this). Eg if you launch Portable Firefox from a USB flash drive and then try and eject that flash drive then USB Disk Ejector will close Portable Firefox and then successfully eject the drive.  

    If the program accessing the disk is one installed on your computer (eg if Microsoft Word has opened a document on a flash drive that you are trying to eject) - then USB Disk Ejector wont be able to detect this and wont be able to close it. Doing this reliably requires administrator rights and a kernel driver - something beyond the scope of this program.  
    You may be able to use [Process Explorer](http://www.microsoft.com/technet/sysinternals/utilities/ProcessExplorer.mspx) or [Unlocker](http://www.emptyloop.com/unlocker/) to find and stop whatever program or process is accessing a drive.

# Acknowledgements And Thanks

*   Ejection code is based upon C code by Uwe_Sieber.
*   Ipod icon unknown - please contact me if you are/know the author.
*   Options unit based on code by Sebastián Mayorá
*   Program and drive icon is from the Snow.E2 set by Sascha Höhne.
*   Uses the Jedi Code Library and the JEDI Setup and Config Manager API  
    Uses PNG ImageList by Martijn Saly  

*   Uses Virtual Treeview by Mike Lischke (and others)

# Disclaimer

The software is provided "as-is" and without warranty of any kind, express, implied or otherwise, including without limitation, any warranty of merchantability or fitness for a particular purpose. In no event shall the initial developer or any other contributor be liable for any special, incidental, indirect or consequential damages of any kind, or any damages whatsoever resulting from loss of use, data or profits, whether or not advised of the possibility of damage, and on any theory of liability, arising out of or in connection with the use or performance of this software.

# Support

[Contact me](http://quickandeasysoftware.net/contact).  

All my software is completely free. If you find this program useful please consider making a donation. This can be done on my [website.](http://quickandeasysoftware.net)

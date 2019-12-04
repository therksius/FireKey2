# FireKey2

##### Version 2.2.2.0

#### Create system wide hotkeys to run programs or perform other tasks.

Created by Rob Saunders ([http://therks.com](http://therks.com))  
Written in the AutoIt (v3) scripting language ([http://www.autoitscript.com](http://www.autoitscript.com))

-----

#### Contents:

1. [Creating a hotkey (quick and easy)](#create1)
2. [Creating a hotkey (detailed explanation)](#create2)
3. [Options menu](#options)
4. [Limitations](#limit)
5. [Version History](#history)
6. [Special thanks](#thanks)
7. [Background](#background)

-----

<a name="create1"></a>

#### Creating a hotkey (quick and easy):

1. Double click the FireKey2 icon in the system tray.
2. Click ``Add HotKey``
3. Click ``Choose`` and choose a key combination.
4. In the Path field, enter the path to file you want to run.
5. Click ``OK``.

-----

<a name="create2"></a>

#### Creating a hotkey (detailed explanation):

1. Double click the FireKey2 icon in your system tray (the area near the clock). The main FireKey2 window will appear.
2. Click the ``Add HotKey`` button at the bottom of the window. The **Add/Edit HotKey** window will appear.
3. Click the ``Choose`` button at the top of the window and decide what key combination you'd like to use.  
	If the ``Detect Key`` button is selected then the program will try to auto select whatever key combination you press (some combinations cannot be detected).  
	Otherwise, click the buttons for each modifier (Win, Alt, etc) you want to use and then choose the base key from the drop down list.  
	> For example, if you want to use the number pad asterisk (*) plus the Windows and Control keys you would click ``Win``, ``Ctrl``, and then choose _**NumPad Multiply**_ from the list.  
	
	Then click ``OK``.  
	Now the key combination you chose should be displayed in the box at the top of the window.  
	**Note:** Some hotkey combinations (Win+R, Win+E, etc) will be in use and blocked by Windows or other applications.  
	If the program detects you have chosen a blocked hotkey it will warn you and you may choose another.  
	**Alternatively**, you can try to use the virtual key method which is explained further below.

4. If you are worried about accidentally pressing this hotkey and doing something you don't want (like shut down your computer or start a slow program) then you can check the box for _Confirm before performing function_ and you will be shown a confirmation dialog when you press the hotkey. This is recommended for functions like _**Hibernate**_ or _**Shutdown**_.
5. Sometimes you may want to use a hotkey combination that is already in use by another program or by Windows itself. In this case try checking off the _Use virtual key hook_ box as you define your hotkey. Most hotkeys will work using this method but the program may have issues if you press the key repeatedly, or if something makes the program delay (like a confirmation prompt) and the original hotkey may leak through. Unfortunately I have no fix for this.  
	> _ie:_ If you set a virtual hotkey to Win+E, then spam the hotkey, Windows Explorer will probably open a few times.
6. Now choose the function you want to execute when you press your hotkey. There are a variety of functions here like volume adjust (raise/lower, mute), window manipulation (maximize, minimize), power options (log off, shutdown, hibernate) and some functions specific for FireKey (open/toggle the key list, shutdown FireKey).
7. Some function details:
	1. If you want to launch a program or open a file/folder, choose _**Run**_.  
		In the _Path_ field below, type the location of whatever you want to run, or click one of the buttons on the end to browse for it.  
		> If you want to browse for a file click the first button, if you want to browse for a folder click the second.
		
		If you are launching a program and not a file then any command line options you want to specify must be entered in the _Parameters_ field.  
		The working directory, or "Start in" folder, can be specified in the _Working Dir_ field, and the _Window_ drop down list will allow you to select how the window should appear when the program is launched (not all programs respect this setting).
	2. If you want to raise, lower or mute the system volume, choose _**Volume Adjust**_.  
		If you want to adjust the volume, check the _Amount_ selector below and then enter how much you want the volume to change on each key press.  
		The amount is based on 100 being full volume and 0 being silent. So if you want to go from full volume to silence in 4 key presses then you could enter -25.  
		If you want a visible meter that shows the volume level whenever the adjustment is made you can check the _Display Meter_ box.  
		If you just want to toggle muting the volume then check the _Toggle Mute_ selector.
8. When you have finished selecting and configuring the function for your hotkey click ``OK`` and your hotkey will now be usable and you will be returned to the key list window.

-----

<a name="options"></a>

#### Options menu:

* _Version info_
* View ReadMe (F1)  
	Opens readme HTML.
* Reload Keys (F5)  
	Manually reload the hotkey data file.
* More Options
	* Run on Login  
		Add a shortcut to the Startup folder.
	* Confirm Shutdown  
		Show a prompt when you exit FireKey via menus.
	* Confirm Key Delete  
		Show a prompt when you delete hotkeys.
	* Remember Window Size/Position  
		Remember the main window's position when exited and restore it when reopening the program.
	* Show Tray Icon  
		Show the FireKey icon in the system tray and do not exit when closing the main window.
	* Warn If Key Is Taken  
		Show a warning in the key editor if a hotkey is in use when created.
	* Show Tray Tip On Key Error  
		Display a popup on launch if a hotkey is in use by another application.
	* Show Splash Screen  
		Display the splash screen on launch.
	* Set Priority  
		Set the main program priority.  
		> Low is the default, and recommended, but if the program or your hotkeys seem unresponsive then you can try a higher priority.
	* Advanced Options
		* _AutoIt version compiled with_
		* View Source Code  
			Opens a text file with the source code.
		* View Error Log  
			Opens the error log for viewing.
		* View Data Folder  
			Opens the data file folder (config files, error log, etc).
		* Delete All FireKey Data  
			Delete all FireKey2 config data, use this if you are removing the program or just want a clean start.
	* Exit (Alt+X)  
		Shuts down FireKey - this will disable your hotkeys.

-----

<a name="limit"></a>

#### Limitations:

The number pad Enter key cannot be differentiated from the normal Enter key so any hotkey that uses Enter can be triggered by both the number pad and main Enter keys.

The following keys/combos cannot be used:

* Ctrl+Alt+Del - You can use the virtual key option and the command will execute but the normal Windows menu will appear first.
* Two or more "base" keys (Q+W, F2+D, Down+Delete+Enter, etc).
* Any modifiers (Alt/Ctrl/Shift/Win) without a "base" key.

-----

<a name="history"></a>

#### Version History:

* 2.2.2.0
	* Github release.
* 2.2.1.4
	* Fixed WM_CONTEXTMENU to only apply to listview.
* 2.2.1.3
	* Changed "Execute" context menu option to "Test".
* 2.2.1.0
	* Fixed "Run As Admin" option in run command (previously unimplemented).
	* Fixed "Disable Key" size (wasn't big enough)
	* Fixed "No Tray Icon" option for main program (was ignoring the option).
	* Fixed window size memory and added option to enable/disable.
* 2.2.0.5
	* Changed config directory.
* 2.2.0.4
	* Set minimum window size for Add/Edit window.
	* Fixed "Disable key" checkbox movement (sticks to bottom of window now).
	* Removed cmd line param for source since it's provided in a menu option.
* 2.2.0.3
	* Removed tooltip on file run.
	* Changed priority magic numbers to $PROCESS_* constants.
* 2.2.0.2
	* Red color for disabled hotkeys.
	* Changed item details for in-use hotkeys.
* 2.2.0.1
	* Removed 64 bit auto-run.
	* Changed compiled names: 32 bit is now "FireKey (x86).exe" and 64 bit is "FireKey.exe".
* 2.2.0.0
	* Added disable key option.
	* Added accelerators to key list context menu.
* 2.1.1.0
	* Fixed bug with saving/restoring window position.
	* Changed window fade function from DllCall to UDF.
* 2.1.0.7
	* Rearranged Options menu.
* 2.1.0.6
	* AutoIt line now has a full edit box (merged to single line on execution).
	* Main window size/pos is now remembered.
	* Listview is focused after key add/edit.
	* Default sort keys in order of creation/update.
* 2.1.0.5
	* Changes to _FileGetIcon, added new icons for "AutoIt commands".
* 2.1.0.4
	* Fixed double click working in listview.
* 2.1.0.3
	* Added context menu trigger for listview using WM_CONTEXTMENU (For Shift+F10).

-----

<a name="thanks"></a>

#### Special thanks:

* The AutoIt developers.
* Erik Pilsits (wraithdu) for "_AudioEndpointVolume.au3" ([Link](https://www.autoitscript.com/forum/topic/84834-control-vista-master-volume/)) which provides volume control in Vista+ systems.
* Austin Beer (asbeer450) for "_SoundGetSetQuery.au3" (Link no longer available) which provides volume control in pre-Vista systems.
* Yashied for "_Yashied_HotKey_21b.au3" ([Link](https://www.autoitscript.com/forum/topic/90492-hotkey-udf/)) which provides the virtual key hotkey method.

-----

<a name="background"></a>

#### Background:

I wrote the first FireKey for myself to replace a program called WinKey. WinKey was nice, but limited in that it only had support for a preset list of key combinations.  
> For example, you couldn't create hotkeys with punctuation or the Alt key. FireKey allowed just about any combination of modifiers and a base key.  

I originally started rewriting FireKey back in late 2006 but kept losing interest and motivation and instead patched in hacky fixes to the original code.  
I worked on it off and on for a while and finally "finished" it at work during a rather long and boring night shift.  
I still tinker with it now and then, but there's not much left I can do with it.

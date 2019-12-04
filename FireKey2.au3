#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=1_firekey.ico
#AutoIt3Wrapper_Outfile=FireKey2 (x86).exe
#AutoIt3Wrapper_Outfile_x64=FireKey2.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Manage your computer with hotkeys
#AutoIt3Wrapper_Res_Description=FireKey2
#AutoIt3Wrapper_Res_Fileversion=2.2.1.5
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Icon_Add=5_editor.ico
#AutoIt3Wrapper_Res_Icon_Add=6_keyboard.ico
#AutoIt3Wrapper_Res_Icon_Add=7_windows.ico
#AutoIt3Wrapper_Res_Icon_Add=8_power.ico
#AutoIt3Wrapper_Res_Icon_Add=9_volume.ico
#AutoIt3Wrapper_Res_Icon_Add=10_autoit.ico
#AutoIt3Wrapper_Res_Icon_Add=11_autoitline.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
--- Version history ---
2.2.1.4 - Fixed WM_CONTEXTMENU to only apply to listview.
2.2.1.3 - Changed "Execute" context menu option to "Test".
2.2.1.0 - Fixed "Run As Admin" option in run command (previously unimplemented).
....... - Fixed "Disable Key" size (wasn't big enough)
....... - Fixed "No Tray Icon" option for main program (was ignoring the option).
....... - Fixed window size memory and added option to enable/disable.
2.2.0.5 - Changed config directory.
2.2.0.4 - Set minimum window size for Add/Edit window.
....... - Fixed "Disable key" checkbox movement (sticks to bottom of window now).
....... - Removed cmd line param for source since it's provided in a menu option.
2.2.0.3 - Removed tooltip on file run.
....... - Changed priority magic numbers to $PROCESS_* constants.
2.2.0.2 - Red color for disabled hotkeys.
....... - Changed item details for in-use hotkeys.
2.2.0.1 - Removed 64 bit auto-run.
....... - Changed compiled names: 32 bit is now "FireKey (x86).exe" and 64 bit is "FireKey.exe".
2.2.0.0 - Added disable key option.
....... - Added accelerators to key list context menu.
2.1.1.0 - Fixed bug with saving/restoring window position.
....... - Changed window fade function from DllCall to UDF.
2.1.0.7 - Rearranged Options menu.
2.1.0.6 - AutoIt line now has a full edit box (merged to single line on execution).
....... - Main window size/pos is now remembered.
....... - Listview is focused after key add/edit.
....... - Default sort keys in order of creation/update.
2.1.0.5 - Changes to _FileGetIcon, added new icons for "AutoIt commands".
2.1.0.4 - Fixed double click working in listview.
2.1.0.3 - Added context menu trigger for listview using WM_CONTEXTMENU (For Shift+F10).
#ce

#pragma compile(AutoItExecuteAllowed, true)

#region - Includes

Opt('MustDeclareVars', 1)
Opt('GUIDataSeparatorChar', @CR)

; Standard AutoIt includes
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <GUIListView.au3>
#include <GUIMenu.au3>
#include <StaticConstants.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <Misc.au3>
#include <File.au3>

; My personal includes
#include <vkConstants.au3>
#include <_FileGetIcon().au3>
#include <_MySingleton().au3>
#include <_WinFade().au3>

; Application specific includes
#include "_Yashied_HotKey_21b.au3"
#include "_HotKey_Mod_Yashied.au3"
#include "_SoundGetSetQuery.au3"
#include "_AudioEndpointVolume.au3"
#endregion

#region - Constants required for prechecks
Global Const $APP_NAME = 'FireKey2'
Global Const $FK_INTERACT_STR = 'FIREKEY2_INTERACT'
Global Const $FK_INTERACT_MSG = _WinAPI_RegisterWindowMessage($FK_INTERACT_STR)
Global Enum $FK_MSG_OPENLIST
#endregion

#region - Run-once logic
; FireKey v1 check. If running: warn user
Global Const $sFireKey1DetectorWin = 'AutoIt3.FireKey.Window'
If WinExists($sFireKey1DetectorWin) Then
	MsgBox(0x30, $APP_NAME, 'FireKey version 1 is currently running. You should exit that program before using this one.')
	ControlSetText($sFireKey1DetectorWin, '', 'Edit1', 'Show Yourself')
EndIf

; FireKey 2 check. If already running open list from previous instance and exit
If Not _MySingleton($FK_INTERACT_STR, 1) Then
	_SendMessage(WinGetHandle($FK_INTERACT_STR), $FK_INTERACT_MSG, $FK_MSG_OPENLIST)
	Exit @ScriptLineNumber
EndIf
#endregion

#region - Constants & global vars
Global $TMP
Global Const $TRAY_DEFAULT = 512

Global $BIT_VERSION = 32
If @AutoItX64 Then $BIT_VERSION = 64

Global Const $OLD_DATA_DIR = @AppDataDir & '\' & $APP_NAME
Global Const $DATA_DIR = @AppDataDir & '\therkSoft\' & $APP_NAME
If FileExists($OLD_DATA_DIR) Then DirMove($OLD_DATA_DIR, $DATA_DIR)
DirCreate($DATA_DIR)

Global Const $STARTUP_LINK = @StartupDir & '\' & $APP_NAME & '.lnk'
Global Const $CONFIG_FILE = $DATA_DIR & '\Config.ini'
Global Const $KEY_FILE = $DATA_DIR & '\Keys.ini'
Global Const $ERROR_LOG = $DATA_DIR & '\Error Log.txt'
Global Const $README = $DATA_DIR & '\ReadMe.html'
Global Const $SOURCE = $DATA_DIR & '\Source.txt'

Global $MASTER_KEY_LIST, $KEY_LIST_REVLOOKUP[16]
Global Enum $MKL_HOTKEY, $MKL_VKEY, $MKL_DATA, $MKL_CTRLID, $MKL_UBOUND

Global Const $INI_CFG_TITLE = 'Config', $INI_CFG_SPLASH = 'Splash', $INI_CFG_TRAYICON = 'Tray', $INI_CFG_MEMWINPOS = 'MemWinPos', $INI_CFG_WINPOS = 'WinPos', _
	$INI_CFG_PRIORITY = 'Priority', $INI_CFG_CONFDELETE = 'ConfDel', $INI_CFG_KEYTAKEN = 'KeyTaken', $INI_CFG_CONFEXIT = 'ConfExit', $INI_CFG_TRAYTIP = 'TrayTip', _
	$INI_KEY_FUNC = 'Function', $INI_KEY_PROMPT = 'Prompt', $INI_KEY_VIRTKEY = 'IsVK', $INI_KEY_DISABLED = 'Disabled', $INI_KEY_COMMENT = 'Comment', _
	$INI_KEY_PATH = 'Path', $INI_KEY_PARAMS = 'Params', $INI_KEY_WORKDIR = 'WorkDir', $INI_KEY_WINSTYLE = 'Window', $INI_KEY_RUNADMIN = 'RunAsAdmin', _
	$INI_KEY_VOLADJUST = 'Adjust', $INI_KEY_VOLDISPLAY = 'Display', $INI_KEY_MUTE = 'Mute'

Global Enum $FTBL_COL_ID, $FTBL_COL_STR, $FTBL_COL_ICO, $FTBL_COL_UBOUND
Global Enum $FTBL_ROW_RUN, $FTBL_ROW_BREAK_1, _
	$FTBL_ROW_VOLUME, $FTBL_ROW_BREAK_2, _
	$FTBL_ROW_TOGGLEICONS, $FTBL_ROW_WINCLOSE, $FTBL_ROW_WINMIN, $FTBL_ROW_WINMAX, $FTBL_ROW_WINRESTORE, $FTBL_ROW_WINMINALL, $FTBL_ROW_WINMINALLUNDO, $FTBL_ROW_BREAK_3, _
	$FTBL_ROW_MONOFF, $FTBL_ROW_LOGOFF, $FTBL_ROW_SHUTDOWN, $FTBL_ROW_REBOOT, $FTBL_ROW_SLEEP, $FTBL_ROW_HIBERNATE, $FTBL_ROW_BREAK_4, _
	$FTBL_ROW_OPENLIST, $FTBL_ROW_CLOSELIST, $FTBL_ROW_TOGGLELIST, $FTBL_ROW_RELOADKEYS, $FTBL_ROW_EXITHANDLER, $FTBL_ROW_BREAK_5, _
	$FTBL_ROW_AUTOIT, $FTBL_ROW_AUTOITLINE, $FTBL_ROW_UBOUND
Global Const $FUNCTIONS_TABLE[$FTBL_ROW_UBOUND][$FTBL_COL_UBOUND] = [ _
	[ 'Run',           'Run' ], _
	[ '' ], _
	[ 'Volume',        'Volume Adjust',             -9 ], _
	[ '' ], _
	[ 'ToggleIcons',   'Hide/Show Desktop Icons',   -7 ], _
	[ 'WinClose',      'Close Active Window',       -7 ], _
	[ 'WinMinimize',   'Minimize Active Window',    -7 ], _
	[ 'WinMaximize',   'Maximize Active Window',    -7 ], _
	[ 'WinRestore',    'Restore Active Window',     -7 ], _
	[ 'WinMinAll',     'Minimize All Windows',      -7 ], _
	[ 'WinMinAllUndo', 'Undo Minimize All Windows', -7 ], _
	[ '' ], _
	[ 'MonitorOff',    'Monitor to Sleep',          -8 ], _
	[ 'LogOff',        'Log Off User',              -8 ], _
	[ 'Shutdown',      'Shutdown Computer',         -8 ], _
	[ 'Reboot',        'Reboot Computer',           -8 ], _
	[ 'Sleep',         'Sleep Computer',            -8 ], _
	[ 'Hibernate',     'Hibernate Computer',        -8 ], _
	[ '' ], _
	[ 'OpenList',      'Open FireKey Window',       -5 ], _
	[ 'CloseList',     'Close FireKey Window',      -5 ], _
	[ 'ToggleList',    'Toggle FireKey Window',     -5 ], _
	[ 'ReloadKeys',    'Reload FireKey Keys',       -5 ], _
	[ 'ExitHandler',   'Shutdown FireKey',          -6 ], _
	[ '' ], _
	[ 'AutoIt',        'AutoIt3 Script',            -10 ], _
	[ 'AutoItLine',    'AutoIt3 Line',              -11 ] _
]
Global Const $FK_WINSTYLES[4] = [ @SW_SHOW, @SW_MINIMIZE, @SW_MAXIMIZE ]

Global $g_sHotKeyAdding, $g_sHotKeyEditing, _
	$g_iShowSplash 		= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_SPLASH, 1)), _
	$g_iTrayIcon 		= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_TRAYICON, 1)), _
	$g_iConfDelete 		= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_CONFDELETE, 1)), _
	$g_iKeyTakenNotice 	= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_KEYTAKEN, 1)), _
	$g_iConfExit 		= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_CONFEXIT, 1)), _
	$g_iTrayTip 		= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_TRAYTIP, 1)), _
	$g_iPriority 		= Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_PRIORITY, 0)), _
	$g_iWinPosMem       = Int(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_MEMWINPOS, 1)), _
	$g_aLaunchSize[4]   = [ (@DesktopWidth - 640) / 2, (@DesktopHeight - 480) / 2, 640, 480 ], _
	$g_sComboList 		= $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_STR]
	For $i = 1 To $FTBL_ROW_UBOUND-1
		$g_sComboList &= @CR & $FUNCTIONS_TABLE[$i][$FTBL_COL_STR]
	Next

If $g_iWinPosMem Then
	$TMP = StringSplit(IniRead($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_WINPOS, ''), '|', 2)
	If UBound($TMP) = 4 Then $g_aLaunchSize = $TMP
EndIf

#endregion - Constants & global vars

#region - Splash window
Global $g_hGUISplash, $lb_Splash, $sTempIcon = $DATA_DIR & '\icon.ico'
If $g_iShowSplash = 1 Then
	FileInstall('1_firekey.ico', $sTempIcon)
	$g_hGUISplash = GUICreate($APP_NAME & ' - Loading...', 150, 75, Default, Default, BitOR($WS_POPUP, $WS_DLGFRAME), BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
		GUICtrlCreateIcon($sTempIcon, 0, 51, 5, 48, 48)
		$lb_Splash = GUICtrlCreateLabel('Loading...', 5, 58, 140, 15, $SS_CENTER)
	_WinFade($g_hGUISplash, '', @SW_SHOWNA, 500)
	Sleep(500)
EndIf
#endregion - Splash window

GUICtrlSetData($lb_Splash, 'Creating message hooks')

Global Const $FK_INTERACT_HWND = GUICreate($FK_INTERACT_STR)
GUIRegisterMsg($FK_INTERACT_MSG, '_FK_INTERACT_MSG')

GUICtrlSetData($lb_Splash, 'Setup volume handler')

#region - Setup volume settings. Vista+ uses .dll plugin. Otherwise handled by script.
Global $USE_VISTA_FUNCS
If Not StringRegExp(@OSVersion, 'WIN_(2003|XP|XPe|2000)') Then $USE_VISTA_FUNCS = 1

Global $VOLUME_HWND = GUICreate('FK2VolumeDisplay', 100, 100, 0, 0, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
GUISetBkColor(0xff00)
WinSetTrans($VOLUME_HWND, '', 200)
GUISetState(@SW_DISABLE)
#endregion

GUICtrlSetData($lb_Splash, 'Building interfaces')

Opt('GUIOnEventMode', 1)
Opt('GUIResizeMode', $GUI_DOCKSTATEBAR)

#region - Main List Window
Global $g_hGUIMain, $cm_ItemsMenu, $mi_MenuEdit, $mi_MenuCopy, $mi_MenuDisable, $mi_MenuDelete, $mi_MenuRun, $lv_KeyList, $bt_Add, $bt_Edit, $bt_Delete, $bt_Options, _
	$cm_Options, $mi_Startup, $mi_Reload, $mi_Exit, $me_MoreOptions, $mi_Readme, $mi_Source, $mi_TrayIcon, $mi_TrayTip, $mi_Splash, $mi_ConfExit, $mi_ConfDel, _
	$mi_KeyTaken, $mi_WinPosMem, $me_Priority, $mi_PriLow, $mi_PriNorm, $mi_PriHigh, $mi_Log, $mi_DataDir, $me_AdvOptions, $mi_DeleteData

$g_hGUIMain = GUICreate($APP_NAME, 400, 270, Default, Default, $WS_OVERLAPPEDWINDOW)
	GUISetIcon(@AutoItExe, -5)
	GUISetOnEvent($GUI_EVENT_CLOSE, '_MainHandler')

$cm_ItemsMenu = GUICtrlCreateContextMenu(GUICtrlCreateDummy())
	$mi_MenuEdit = GUICtrlCreateMenuItem('&Edit' &@TAB& 'Enter', $cm_ItemsMenu)
		GUICtrlSetState(-1, $GUI_DEFBUTTON)
		GUICtrlSetOnEvent(-1, '_MainHandler')
	$mi_MenuCopy = GUICtrlCreateMenuItem('Dupli&cate' &@TAB& 'Ctrl+C', $cm_ItemsMenu)
		GUICtrlSetOnEvent(-1, '_MainHandler')
	$mi_MenuDisable = GUICtrlCreateMenuItem('Dis&able' &@TAB& 'Ctrl+D', $cm_ItemsMenu)
		GUICtrlSetOnEvent(-1, '_MainHandler')
	$mi_MenuDelete = GUICtrlCreateMenuItem('&Delete' &@TAB& 'Del', $cm_ItemsMenu)
		GUICtrlSetOnEvent(-1, '_MainHandler')
	GUICtrlCreateMenuItem('', $cm_ItemsMenu)
	$mi_MenuRun = GUICtrlCreateMenuItem('&Test' &@TAB& 'Ctrl+T', $cm_ItemsMenu)
		GUICtrlSetOnEvent(-1, '_MainHandler')

$lv_KeyList = GUICtrlCreateListView('Key' &@CR& 'Function' &@CR& 'Details', 5, 5, 390, 210, BitOR($LVS_SHOWSELALWAYS, $LVS_SINGLESEL))
	GUICtrlSetOnEvent($lv_KeyList, '_MainHandler')
	_GUICtrlListView_RegisterSortCallBack($lv_KeyList)
	GUICtrlSetImage(-1, 'shell32.dll', 0)
	GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)

$bt_Add = GUICtrlCreateButton('&Add HotKey', 5, 220, 90, 30)
	GUICtrlSetFont(-1, 10)
	GUICtrlSetOnEvent(-1, '_MainHandler')
$bt_Edit = GUICtrlCreateButton('&Edit HotKey', 105, 220, 90, 30)
	GUICtrlSetFont(-1, 10)
	GUICtrlSetOnEvent(-1, '_MainHandler')
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
$bt_Delete = GUICtrlCreateButton('&Delete HotKey', 205, 220, 90, 30)
	GUICtrlSetFont(-1, 10)
	GUICtrlSetOnEvent(-1, '_MainHandler')
$bt_Options = GUICtrlCreateButton('&Options', 305, 220, 90, 30)
	GUICtrlSetFont(-1, 10)
	GUICtrlSetOnEvent(-1, '_MainHandler')

GUICtrlCreateLabel('¹ Confirm before execute. ² Using virtual key hook.', 5, 255, 390, 15, $SS_RIGHT)
	GUICtrlSetResizing(-1, $GUI_DOCKSIZE+$GUI_DOCKBOTTOM+$GUI_DOCKRIGHT)

$cm_Options = GUICtrlCreateContextMenu(GUICtrlCreateDummy())
	GUICtrlCreateMenuItem('Version ' & FileGetVersion(@ScriptFullPath) & ' ' & $BIT_VERSION & '-bit', $cm_Options)
		GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlCreateMenuItem('', $cm_Options)
	$mi_Readme = GUICtrlCreateMenuItem('&View ReadMe' &@TAB& 'F1', $cm_Options)
		GUICtrlSetOnEvent(-1, '_MainHandler')
	$mi_Reload = GUICtrlCreateMenuItem('&Reload Keys' &@TAB& 'F5', $cm_Options)
		GUICtrlSetOnEvent(-1, '_MainHandler')
	$me_MoreOptions = GUICtrlCreateMenu('More &Options', $cm_Options)
		$mi_Startup = GUICtrlCreateMenuItem('Run on &Login', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If FileExists($STARTUP_LINK) Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_ConfExit = GUICtrlCreateMenuItem('Confirm Sh&utdown', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iConfExit = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_ConfDel = GUICtrlCreateMenuItem('Confirm Key &Delete', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iConfDelete = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_KeyTaken = GUICtrlCreateMenuItem('Warn If Key Is &Taken', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iConfDelete = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_WinPosMem = GUICtrlCreateMenuItem('&Remember Window Size/Position', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iWinPosMem = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_TrayIcon = GUICtrlCreateMenuItem('Show Tray &Icon', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iTrayIcon = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_TrayTip = GUICtrlCreateMenuItem('Show Tray &Tip On Key Error', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iTrayTip = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$mi_Splash = GUICtrlCreateMenuItem('Show &Splash Screen', $me_MoreOptions)
			GUICtrlSetOnEvent(-1, '_MainHandler')
			If $g_iShowSplash = 1 Then GUICtrlSetState(-1, $GUI_CHECKED)
		$me_Priority = GUICtrlCreateMenu('Set &Priority', $me_MoreOptions)
			$mi_PriLow = GUICtrlCreateMenuItem('&Low/Idle', $me_Priority, 0, 1)
				GUICtrlSetOnEvent(-1, '_MainHandler')
			$mi_PriNorm = GUICtrlCreateMenuItem('&Normal', $me_Priority, 1, 1)
				GUICtrlSetOnEvent(-1, '_MainHandler')
			$mi_PriHigh = GUICtrlCreateMenuItem('&High', $me_Priority, 2, 1)
				GUICtrlSetOnEvent(-1, '_MainHandler')
			Switch $g_iPriority
				Case 0
					GUICtrlSetState($mi_PriLow, $GUI_CHECKED)
				Case 2
					GUICtrlSetState($mi_PriNorm, $GUI_CHECKED)
				Case 4
					GUICtrlSetState($mi_PriHigh, $GUI_CHECKED)
			EndSwitch
		GUICtrlCreateMenuItem('', $me_MoreOptions)

		$me_AdvOptions = GUICtrlCreateMenu('Advanced &Options', $me_MoreOptions)
			GUICtrlCreateMenuItem('AutoIt Version ' & @AutoItVersion, $me_AdvOptions)
				GUICtrlSetState(-1, $GUI_DISABLE)
			$mi_Source = GUICtrlCreateMenuItem('View Source &Code', $me_AdvOptions)
				GUICtrlSetOnEvent(-1, '_MainHandler')
			GUICtrlCreateMenuItem('', $me_AdvOptions)

			$mi_Log = GUICtrlCreateMenuItem('View Error &Log', $me_AdvOptions)
				GUICtrlSetOnEvent(-1, '_MainHandler')
			$mi_DataDir = GUICtrlCreateMenuItem('View Data &Folder', $me_AdvOptions)
				GUICtrlSetOnEvent(-1, '_MainHandler')
			$mi_DeleteData = GUICtrlCreateMenuItem('Delete All FireKey Data', $me_AdvOptions)
				GUICtrlSetOnEvent(-1, '_MainHandler')
	GUICtrlCreateMenuItem('', $cm_Options)
	$mi_Exit = GUICtrlCreateMenuItem('E&xit' &@TAB& 'Alt+X', $cm_Options)
		GUICtrlSetOnEvent(-1, '_MainHandler')

	Global $aMainAccel = [ [ '{f1}', $mi_Readme ], [ '{f5}', $mi_Reload ], [ '!x', $mi_Exit ], [ '^c', $mi_MenuCopy ], [ '^d', $mi_MenuDisable ], [ '^t', $mi_MenuRun ], [ '{del}', $mi_MenuDelete ] ]
	GUISetAccelerators($aMainAccel)
#endregion

#region - HotKey Editor Window
Global $g_hGUIEditor, $in_Ed_HotKey, $bt_Ed_HotKeyChoose, $ch_Ed_Prompt, $ch_Ed_VirtKey, $cb_Ed_Functions, $tb_Ed_Functions, $tbi_Ed_Run, _
	$tbi_Ed_AutoIt, $tbi_Ed_AutoItLine, $tbi_Ed_Volume, $tbi_Ed_Blank, $in_Ed_Path, $bt_Ed_BrFile, $bt_Ed_BrFolder, $in_Ed_Params, _
	$in_Ed_WorkDir, $cb_Ed_WinStyle, $ch_Ed_RunAdmin, $in_Ed_AutoItPath, $in_Ed_AutoItParams, $in_Ed_AutoItLine, $bt_Ed_BrAutoItFile, $ra_Ed_VolAmount, _
	$in_Ed_VolAdjust, $ch_Ed_VolDisplay, $ra_Ed_VolMute, $in_Ed_Comment, $ch_Ed_Disabled, $bt_Ed_OK, $bt_Ed_Cancel

$g_hGUIEditor = GUICreate('Add/Edit HotKey', 300, 255, Default, Default, BitOR($WS_CAPTION, $WS_POPUP, $WS_SYSMENU, $WS_SIZEBOX), $WS_EX_ACCEPTFILES, $g_hGUIMain)
	GUISetOnEvent($GUI_EVENT_CLOSE, '_EditHandler')
	GUISetOnEvent($GUI_EVENT_DROPPED, '_EditHandler')
Opt('GUIResizeMode', $GUI_DOCKALL)
GUICtrlCreateLabel('HotKey:', 5, 5, 40, 20, $SS_CENTERIMAGE)
$in_Ed_HotKey = GUICtrlCreateInput('', 45, 5, 190, 20, BitOR($ES_LEFT, $ES_AUTOHSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
$bt_Ed_HotKeyChoose = GUICtrlCreateButton('&Choose', 235, 5, 60, 20)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKTOP, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
	GUICtrlSetOnEvent(-1, '_EditHandler')
GUICtrlCreateLabel('', 5, 29, 290, 2, $SS_SUNKEN)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))

$ch_Ed_Prompt = GUICtrlCreateCheckbox('C&onfirm before execute.', 5, 35, 140, 15)
$ch_Ed_VirtKey = GUICtrlCreateCheckbox('Use &virtual key hook.', 145, 35, 290, 15)
	GUICtrlSetTip(-1, 'Can allow some normally restricted hotkeys (ie: Win+R) but may sometimes fail to execute.')

GUICtrlCreateLabel('Choose &Function:', 5, 55, 85, 20, $SS_CENTERIMAGE)
$cb_Ed_Functions = GUICtrlCreateCombo('', 95, 55, 200, 200, $CBS_DROPDOWNLIST)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	GUICtrlSetData(-1, $g_sComboList)
	GUICtrlSetOnEvent($cb_Ed_Functions, '_EditHandler')

$tb_Ed_Functions = GUICtrlCreateTab(-100, 1, 1, 1)
	GUICtrlSetState(-1, $GUI_DISABLE)
$tbi_Ed_Run = GUICtrlCreateTabItem('-')
	GUICtrlCreateGroup('', 5, 75, 290, 120)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	GUICtrlCreateLabel('&Path:', 15, 90, 30, 20, $SS_CENTERIMAGE)
	$in_Ed_Path = GUICtrlCreateInput('', 50, 90, 195, 20)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
		GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	$bt_Ed_BrFile = GUICtrlCreateButton('', 245, 90, 20, 20, $BS_ICON)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
		GUICtrlSetTip(-1, 'Browse for file...')
		GUICtrlSetImage(-1, 'shell32.dll', 0, 0)
		GUICtrlSetOnEvent(-1, '_EditHandler')
	$bt_Ed_BrFolder = GuiCtrlCreateButton('', 265, 90, 20, 20, $BS_ICON)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
		GUICtrlSetTip(-1, 'Browse for folder...')
		GUICtrlSetImage(-1, 'shell32.dll', -4, 0)
		GUICtrlSetOnEvent(-1, '_EditHandler')
	GUICtrlCreateLabel('Pa&rameters:', 15, 115, 60, 20, $SS_CENTERIMAGE)
	$in_Ed_Params = GUICtrlCreateInput('', 80, 115, 205, 20)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	GUICtrlCreateLabel('Working &Dir:', 15, 140, 60, 20, $SS_CENTERIMAGE)
	$in_Ed_WorkDir = GUICtrlCreateInput('', 80, 140, 205, 20)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	GUICtrlCreateLabel('&Window:', 15, 165, 60, 20, $SS_CENTERIMAGE)
	$cb_Ed_WinStyle = GUICtrlCreateCombo('', 80, 165, 100, 200, $CBS_DROPDOWNLIST)
		GUICtrlSetData(-1, 'Normal' &@CR& 'Minimized' &@CR& 'Maximized')
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	$ch_Ed_RunAdmin = GUICtrlCreateCheckbox('Run as &Admin', 190, 165, 95, 20)
		GUICtrlSetTip(-1, 'Only works with executable files. Other files will produce an error.')
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
$tbi_Ed_AutoIt = GUICtrlCreateTabItem('-')
	GUICtrlCreateGroup('', 5, 75, 290, 70)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	GUICtrlCreateLabel('&Path:', 15, 90, 30, 20, $SS_CENTERIMAGE)
	$in_Ed_AutoItPath = GUICtrlCreateInput('', 50, 90, 215, 20)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
		GUICtrlSetState(-1, $GUI_DROPACCEPTED)
	$bt_Ed_BrAutoItFile = GUICtrlCreateButton('', 265, 90, 20, 20, $BS_ICON)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
		GUICtrlSetTip(-1, 'Browse for file...')
		GUICtrlSetImage(-1, 'shell32.dll', 0, 0)
		GUICtrlSetOnEvent(-1, '_EditHandler')
	GUICtrlCreateLabel('Pa&rameters:', 15, 115, 60, 20, $SS_CENTERIMAGE)
	$in_Ed_AutoItParams = GUICtrlCreateInput('', 80, 115, 205, 20)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
$tbi_Ed_AutoItLine = GUICtrlCreateTabItem('-')
	GUICtrlCreateGroup('Co&de:', 5, 75, 290, 120)
		GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
	$in_Ed_AutoItLine = GUICtrlCreateEdit('', 15, 90, 270, 95)
		GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
		GUICtrlSetTip(-1, 'This code will be merged to one line when executed.' & @LF & 'Make sure to end lines appropriately.', 'Notice:', 1, 1+2)
$tbi_Ed_Volume = GUICtrlCreateTabItem('-')
	GUICtrlCreateGroup('', 5, 75, 290, 65)
		GUICtrlSetResizing(-1, BitOR($GUI_DOCKMENUBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))
	$ra_Ed_VolAmount = GUICtrlCreateRadio('&Amount (-100 to 100):', 15, 90, 125, 20)
	$in_Ed_VolAdjust = GUICtrlCreateInput('', 145, 90, 30, 20)
		GUICtrlSetLimit(-1, 4)
	$ch_Ed_VolDisplay = GUICtrlCreateCheckbox('D&isplay Meter', 180, 90, 85, 20)
	$ra_Ed_VolMute = GUICtrlCreateRadio('&Toggle Mute', 15, 110, 85, 20)
$tbi_Ed_Blank = GUICtrlCreateTabItem('-')
GUICtrlCreateTabItem('')

GUICtrlCreateLabel('Co&mment:', 5, 200, 50, 20, $SS_CENTERIMAGE)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKSTATEBAR, $GUI_DOCKSIZE, $GUI_DOCKLEFT))
$in_Ed_Comment = GUICtrlCreateInput('', 60, 200, 235, 20)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKSTATEBAR, $GUI_DOCKLEFT, $GUI_DOCKRIGHT))

$ch_Ed_Disabled = GUICtrlCreateCheckbox('Disable Hot&Key', 5, 225, 100, 25)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKSTATEBAR, $GUI_DOCKSIZE, $GUI_DOCKLEFT))

$bt_Ed_OK = GUICtrlCreateButton('OK', 170, 225, 60, 25)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKSTATEBAR, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	GUICtrlSetOnEvent(-1, '_EditHandler')
$bt_Ed_Cancel = GUICtrlCreateButton('Cancel', 235, 225, 60, 25)
	GUICtrlSetResizing(-1, BitOR($GUI_DOCKSTATEBAR, $GUI_DOCKSIZE, $GUI_DOCKRIGHT))
	GUICtrlSetOnEvent(-1, '_EditHandler')
#endregion

GUIRegisterMsg($WM_NOTIFY, WM_NOTIFY)
GUIRegisterMsg($WM_CONTEXTMENU, WM_CONTEXTMENU)
GUIRegisterMsg($WM_GETMINMAXINFO, WM_GETMINMAXINFO)
GUIRegisterMsg($WM_SIZE, WM_SIZENMOVE)
GUIRegisterMsg($WM_MOVE, WM_SIZENMOVE)

Opt('TrayMenuMode', 1+2+8)
Opt('TrayOnEventMode', 1)

TraySetClick(8)
TrayCreateItem('&Open Key List')
	TrayItemSetState(-1, $TRAY_DEFAULT)
	TrayItemSetOnEvent(-1, '_OpenKeyList')
TrayCreateItem('E&xit')
	TrayItemSetOnEvent(-1, '_ExitPrompt')

OnAutoItExitRegister('_OnExit')

GUICtrlSetData($lb_Splash, 'Loading / registering key list')
_MasterKeyLoadList()

GUICtrlSetData($lb_Splash, 'Enjoy :)')
If $g_iShowSplash = 1 Then
	_WinFade($g_hGUISplash, '', @SW_HIDE, 500)
	GUIDelete($g_hGUISplash)
EndIf

If $g_iTrayIcon Then
	TraySetState()
	_TraySetTip()
Else
	_OpenKeyList()
EndIf

If Not @Compiled Then _OpenKeyList()

ProcessSetPriority(@AutoItPID, $g_iPriority)

ProcessWaitClose(@AutoItPID)

#region - Master key functions

#cs
Example usage:
	$sFunctionString = _FuncLookup('WinClose') ; Returns 'Close Active Window'
	$sFunctionID = _FuncLookup('Close Active Window') ; Returns 'WinClose'
#ce
Func _FuncLookup($sLookup, $bGetID = 0)
	For $for = 0 To UBound($FUNCTIONS_TABLE)-1
		If $bGetID And $FUNCTIONS_TABLE[$for][$FTBL_COL_STR] = $sLookup Then Return SetExtended($for, $FUNCTIONS_TABLE[$for][$FTBL_COL_ID])
		If Not $bGetID And $FUNCTIONS_TABLE[$for][$FTBL_COL_ID] = $sLookup Then Return SetExtended($for, $FUNCTIONS_TABLE[$for][$FTBL_COL_STR])
	Next
	Return SetError(1, 0, $sLookup)
EndFunc

Func _MasterKeyLoadList()
	Local $bErrorNotice
	_GUICtrlListView_BeginUpdate($lv_KeyList)
	_GUICtrlListView_DeleteAllItems($lv_KeyList)
	If IsArray($MASTER_KEY_LIST) Then
		; If the keylist is already created then HotKeys have already been set and we need to clear them
		_HotKey_Release()
		For $for = 1 To $MASTER_KEY_LIST[0][0]
			HotKeySet($MASTER_KEY_LIST[$for][$MKL_HOTKEY])
		Next
	EndIf

	Local $aSections = IniReadSectionNames($KEY_FILE)
	If @error Then
		; If the config file is empty then we'll just clear up the master list
		Global $MASTER_KEY_LIST
	Else
		Global $MASTER_KEY_LIST[$aSections[0]+1][$MKL_UBOUND]
		For $forKeyID = $aSections[0] To 1 Step -1
			; Setup/reset icon and details for listview items
			Local $sFunction = '', $sDetails = '', $aIcon[2], $bDisabled = False, $bKeySetError = False

			$MASTER_KEY_LIST[0][0] += 1
			; We changed ] char into ) because it's used for Section declarations.
			$MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_HOTKEY] = StringReplace($aSections[$forKeyID], ')', ']')
			$MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_DATA] = IniReadSection($KEY_FILE, $aSections[$forKeyID])

			If _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_DISABLED) Then $bDisabled = True

			If Not $bDisabled Then
				If _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_VIRTKEY) Then ; If virtual key
					_HotKey_Assign(_HotKeyToVirtKey($MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_HOTKEY]), '_MasterKeyVirtKeyFunc', $HK_FLAG_EXTENDEDCALL)
				Else
					$bKeySetError = Not HotKeySet($MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_HOTKEY], '_MasterKeyHotKeyFunc')
				EndIf
			EndIf

			If $bKeySetError Then
				_ErrorLog('Key in use: ' & _HotKeyToString($MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_HOTKEY]))
				$bDisabled = True

				$sDetails = '(Disabled: Key in use) '
				$bErrorNotice = True
			EndIf

			; Lookup info for listview item text
			$sFunction = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_FUNC)
			If @error Then
				$sFunction = 'Error'
				$sDetails &= 'Invalid data.'
				$bErrorNotice = True
			EndIf

			Switch $sFunction
				Case 'Error'
					$aIcon[0] = @AutoItExe
					$aIcon[1] = -3
				Case $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_ID]
					; If the function is Run
					Local $sPath = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_PATH)
					Local $sParams = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_PARAMS)
					If $sParams Then $sParams = ' / Params: ' & $sParams
					Local $sWorkDir = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_WORKDIR)
					If $sWorkDir Then $sWorkDir = ' / Work dir: ' & $sWorkDir

					$sDetails &= $sPath & $sWorkDir & $sParams
					$aIcon = _FileGetIcon($sPath, 'shell32.dll', 0)

				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOIT][$FTBL_COL_ID]
					Local $sPath = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_PATH)
					Local $sParams = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_PARAMS)
					If $sParams Then $sParams = ' / Params: ' & $sParams
					$sDetails &= $sPath & $sParams
					$aIcon[0] = @AutoItExe
					$aIcon[1] = $FUNCTIONS_TABLE[$FTBL_ROW_AUTOIT][$FTBL_COL_ICO]

				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOITLINE][$FTBL_COL_ID]
					Local $sParams = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_PARAMS)
					$sDetails &= StringReplace(StringStripCR(StringFormat($sParams)), '\n', '')
					$aIcon[0] = @AutoItExe
					$aIcon[1] = $FUNCTIONS_TABLE[$FTBL_ROW_AUTOITLINE][$FTBL_COL_ICO]

				Case $FUNCTIONS_TABLE[$FTBL_ROW_VOLUME][$FTBL_COL_ID]
					Local $iAdjAmount = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_VOLADJUST)
					If $iAdjAmount = $INI_KEY_MUTE Then
						$sDetails &= 'Toggle mute'
					Else
						If $iAdjAmount < 0 Then
							$sDetails &= 'Lower volume ' & -$iAdjAmount & '%'
						Else
							$sDetails &= 'Raise volume ' & $iAdjAmount & '%'
						EndIf
						If _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_VOLDISPLAY) Then $sDetails &= ' and show display.'
					EndIf

					$aIcon[0] = @AutoItExe
					$aIcon[1] = $FUNCTIONS_TABLE[$FTBL_ROW_VOLUME][$FTBL_COL_ICO]
				Case Else
					$aIcon[0] = @AutoItExe
					For $forFunc = 0 To $FTBL_ROW_UBOUND-1
						If $sFunction = $FUNCTIONS_TABLE[$forFunc][$FTBL_COL_ID] Then
							$aIcon[1] = $FUNCTIONS_TABLE[$forFunc][$FTBL_COL_ICO]
							ExitLoop
						EndIf
					Next
			EndSwitch

			Local $sPrompt = ''
			If _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_PROMPT) Then
				$sPrompt = '¹'
			EndIf

			Local $sVirtKey = ''
			If _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_VIRTKEY) Then
				$sVirtKey = '²'
			EndIf

			Local $sComment = _MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_COMMENT)
			$sComment &= ($sComment And $sDetails) ? ' --- ' : ''

			Local $lvi_Entry = GUICtrlCreateListViewItem( _
				($bDisabled ? ' Disabled; ':'') & _HotKeyToString($MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_HOTKEY]) & $sPrompt & $sVirtKey & @CR & _
				_FuncLookup($sFunction) & (_MasterKeyDataRead($MASTER_KEY_LIST[0][0], $INI_KEY_RUNADMIN) ? ' (as Admin)' : '' ) & @CR & _
				$sComment & $sDetails, $lv_KeyList)

				GUICtrlSetImage(-1, $aIcon[0], $aIcon[1])
				If $bDisabled Then GUICtrlSetColor(-1, 0xff0000)

			If $lvi_Entry >= UBound($KEY_LIST_REVLOOKUP) Then ReDim $KEY_LIST_REVLOOKUP[$lvi_Entry * 2]
			$KEY_LIST_REVLOOKUP[$lvi_Entry] = $MASTER_KEY_LIST[0][0]
			$MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_CTRLID] = $lvi_Entry
		Next
		_GUICtrlListView_SetColumnWidth($lv_KeyList, 0, $LVSCW_AUTOSIZE)
		_GUICtrlListView_SetColumnWidth($lv_KeyList, 1, $LVSCW_AUTOSIZE)
		_GUICtrlListView_SetColumnWidth($lv_KeyList, 2, $LVSCW_AUTOSIZE)
	EndIf
	If $g_iTrayTip = 1 And $bErrorNotice Then
		TraySetState()
		TrayTip('Notice', 'One or more hotkeys are not functioning properly. Check key list for more detail.', 3, 3)
		AdlibRegister('_HideTray', 5000)
	EndIf
	_TraySetTip()
	_GUICtrlListView_EndUpdate($lv_KeyList)
EndFunc

#cs
Example usage:
	$sHotKey = _MasterKeyDataRead($iKeyID)

	$sFunction = _MasterKeyDataRead($sHotKey, $INI_KEY_FUNC)
	$iKeyID = @extended
#ce
Func _MasterKeyDataRead($iKeyID, $sName = Default, $LL = @ScriptLineNumber)
	If Not IsArray($MASTER_KEY_LIST) Then Return SetError(-1, -1, '')
	; Lookup function for reading data in the keylist by value name
	If IsString($iKeyID) Then
		; If the given key ID was a string then lookup it's index number
		For $for = 1 To $MASTER_KEY_LIST[0][0]
			If $iKeyID = $MASTER_KEY_LIST[$for][$MKL_HOTKEY] Then
				$iKeyID = $for
				ExitLoop
			EndIf
		Next
		; If the key string was not found:
		If IsString($iKeyID) Then Return SetError(1, -1, '')
	EndIf

	If $iKeyID < 1 Or $iKeyID > $MASTER_KEY_LIST[0][0] Then
		; The key lookup was invalid
		Return SetError(2, $iKeyID, '')
	Else
		; Return the hotkey string
		If $sName = Default Then Return SetExtended($iKeyID, $MASTER_KEY_LIST[$iKeyID][$MKL_HOTKEY])

		Local $aKeyData = $MASTER_KEY_LIST[$iKeyID][$MKL_DATA]

		; For grabbing the raw array - might remove this after debugging
		If $sName = '*' Then Return SetExtended($iKeyID, $aKeyData)

		For $for = 1 To $aKeyData[0][0]
			If $sName = $aKeyData[$for][0] Then
				Return SetExtended($iKeyID, $aKeyData[$for][1])
			EndIf
		Next
		; The named value was not found in the key data
		Return SetError(3, $iKeyID, '')
	EndIf
EndFunc


Func _MasterKeyVirtKeyFunc($iVirtKey)
	__HK_KeyUp($iVirtKey)
	#cs
	https://www.autoitscript.com/forum/topic/90492-hotkey-udf/?do=findComment&comment=1337982

	If another window is granted focus immediately, then the script will not recognize that the
	key has been released and will block all other keys from being typed.
	This seems to be because __HK_KeyUp() is not being called properly. I assume because it
	should be called on the WM_KEYUP or WM_SYSKEYUP message, and the monitoring window is not
	receiving that message because a different window is active when the key is released. I
	tried looking through the code to figure out where I could maybe force a check but I'm
	very lost.
	#ce

	_MasterKeyDataRead(_VirtKeyToHotKey($iVirtKey))
	Local $iKeyID = @extended
	If Not @error Then
		Sleep(100)
		_MasterKeyExecutor($iKeyID)
		_HotKey_Assign(_HotKeyToVirtKey($MASTER_KEY_LIST[$MASTER_KEY_LIST[0][0]][$MKL_HOTKEY]), '_MasterKeyVirtKeyFunc', $HK_FLAG_EXTENDEDCALL)
	Else
		MsgBox(0x2010, $APP_NAME, 'Invalid key data format. (' & $iVirtKey & ':' & _VirtKeyToHotKey($iVirtKey) & ')')
		_ErrorLog('Invalid key data format. (' & $iVirtKey & ':' & _VirtKeyToHotKey($iVirtKey) & ')')
	EndIf
EndFunc

Func _MasterKeyHotKeyFunc()
	Local $sHotKey = @HotKeyPressed
	_MasterKeyDataRead($sHotKey)
	Local $iKeyID = @extended
	If Not @error Then
		HotKeySet($sHotKey)
		_MasterKeyExecutor($iKeyID)
		HotKeySet($sHotKey, '_MasterKeyHotKeyFunc')
	Else
		MsgBox(0x2010, $APP_NAME, 'Invalid key data format. (' & @HotKeyPressed & ')')
		_ErrorLog('Invalid key data format. (' & @HotKeyPressed & ')')
	EndIf
EndFunc

Func _MasterKeyExecutor($iKeyID)
	If Not _PromptFirst($iKeyID) Then Return
	Local $bPrompted = @extended
	Local $sCommandFunction = _MasterKeyDataRead($iKeyID, $INI_KEY_FUNC)

	Switch $sCommandFunction
		#region - FireKey functions
		Case $FUNCTIONS_TABLE[$FTBL_ROW_EXITHANDLER][$FTBL_COL_ID]
			Exit @ScriptLineNumber
		Case $FUNCTIONS_TABLE[$FTBL_ROW_OPENLIST][$FTBL_COL_ID]
			_OpenKeyList()
		Case $FUNCTIONS_TABLE[$FTBL_ROW_TOGGLELIST][$FTBL_COL_ID]
			If WinActive($g_hGUIMain) Then
				GUISetState(@SW_HIDE, $g_hGUIMain)
			Else
				_OpenKeyList()
			EndIf
		Case $FUNCTIONS_TABLE[$FTBL_ROW_CLOSELIST][$FTBL_COL_ID]
			GUISetState(@SW_HIDE, $g_hGUIMain)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_RELOADKEYS][$FTBL_COL_ID]
			_MasterKeyLoadList()
		#endregion

		#region - Window functions
		Case $FUNCTIONS_TABLE[$FTBL_ROW_WINCLOSE][$FTBL_COL_ID]
			WinClose('[active]')
		Case $FUNCTIONS_TABLE[$FTBL_ROW_WINMIN][$FTBL_COL_ID]
			WinSetState('[active]', '', @SW_MINIMIZE)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_WINMAX][$FTBL_COL_ID]
			WinSetState('[active]', '', @SW_MAXIMIZE)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_WINRESTORE][$FTBL_COL_ID]
			WinSetState('[active]', '', @SW_RESTORE)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_WINMINALL][$FTBL_COL_ID]
			WinMinimizeAll()
		Case $FUNCTIONS_TABLE[$FTBL_ROW_WINMINALLUNDO][$FTBL_COL_ID]
			WinMinimizeAllUndo()
		Case $FUNCTIONS_TABLE[$FTBL_ROW_TOGGLEICONS][$FTBL_COL_ID]
			Local $hDesktop = ControlGetHandle('[CLASS:Progman]', '', 'SysListView321')
			If Not $hDesktop Then
				Local $aWorkerW = WinList('[CLASS:WorkerW]')
				For $i = 1 to $aWorkerW[0][0]
					If ControlGetHandle($aWorkerW[$i][1], '', 'SHELLDLL_DefView1') Then
						$hDesktop = ControlGetHandle($aWorkerW[$i][1], '', 'SysListView321')
						If $hDesktop Then ExitLoop
					EndIf
				Next
			EndIf

			If $hDesktop Then
				If BitAND(WinGetState($hDesktop), 2) Then
					WinSetState($hDesktop, '', @SW_HIDE)
				Else
					WinSetState($hDesktop, '', @SW_SHOW)
				EndIf
			Else
				MsgBox(0x2010, $APP_NAME, 'Cannot find desktop control.')
			EndIf
		#endregion

		#region - Power functions
		Case $FUNCTIONS_TABLE[$FTBL_ROW_MONOFF][$FTBL_COL_ID]
			Local $WM_SYSCOMMAND = 274
			Local $SC_MONITORPOWER = 61808

			Local $hWnd = WinGetHandle('[CLASS:Progman]')
			Sleep(500)
			_SendMessage($hWnd, $WM_SYSCOMMAND, $SC_MONITORPOWER, 2)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_LOGOFF][$FTBL_COL_ID]
			Shutdown(0)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_SHUTDOWN][$FTBL_COL_ID]
			Shutdown(9)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_REBOOT][$FTBL_COL_ID]
			Shutdown(2)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_SLEEP][$FTBL_COL_ID]
			Shutdown(32)
		Case $FUNCTIONS_TABLE[$FTBL_ROW_HIBERNATE][$FTBL_COL_ID]
			Shutdown(64)
		#endregion

		#region - Volume functions
		Case $FUNCTIONS_TABLE[$FTBL_ROW_VOLUME][$FTBL_COL_ID]
			Local $iAdjAmount = _MasterKeyDataRead($iKeyID, $INI_KEY_VOLADJUST)
			If $iAdjAmount = $INI_KEY_MUTE Then
				_ToggleMute()
			Else
				_AdjustVolume(Int($iAdjAmount), _MasterKeyDataRead($iKeyID, $INI_KEY_VOLDISPLAY))
			EndIf
		#endregion

		; Run file function
		Case $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_ID]
			Local $sPath = _MasterKeyDataRead($iKeyID, $INI_KEY_PATH)
			Local $sParams = _MasterKeyDataRead($iKeyID, $INI_KEY_PARAMS)
			Local $sWorkDir = _MasterKeyDataRead($iKeyID, $INI_KEY_WORKDIR)
			Local $iWinStyle = Abs(Int(_MasterKeyDataRead($iKeyID, $INI_KEY_WINSTYLE)))
			If $iWinStyle >= UBound($FK_WINSTYLES) Then $iWinStyle = 0
			_ShellExecute($sPath, $sParams, $sWorkDir, $FK_WINSTYLES[$iWinStyle], _MasterKeyDataRead($iKeyID, $INI_KEY_RUNADMIN))

		; AutoIt script file function
		Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOIT][$FTBL_COL_ID]
			Local $sPath = _MasterKeyDataRead($iKeyID, $INI_KEY_PATH)
			Local $sParams = _MasterKeyDataRead($iKeyID, $INI_KEY_PARAMS)
			_ShellExecute(@AutoItExe, '/AutoIt3ExecuteScript "' & $sPath & '" ' & $sParams)

		; AutoIt script line function
		Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOITLINE][$FTBL_COL_ID]
			Local $sParams = _MasterKeyDataRead($iKeyID, $INI_KEY_PARAMS)
			$sParams = StringRegExpReplace($sParams, '(\\r|\\n)', '')
			$sParams = StringFormat($sParams)
			$sParams = StringReplace($sParams, '"', '""')
			_ShellExecute(@AutoItExe, '/AutoIt3ExecuteLine "' & $sParams & '"')
	EndSwitch
EndFunc

#endregion

#region - Helper functions

Func _OpenKeyList()
	GUISetState(@SW_SHOW, $g_hGUIMain)
	If UBound($g_aLaunchSize) = 4 Then
		If $g_aLaunchSize[0] + $g_aLaunchSize[2] < 0 Then $g_aLaunchSize[0] = 100
		If $g_aLaunchSize[0] > @DesktopWidth Then $g_aLaunchSize[0] = @DesktopWidth - 100
		If $g_aLaunchSize[1] < -10 Then $g_aLaunchSize[1] = 0
		If $g_aLaunchSize[1] > @DesktopHeight Then $g_aLaunchSize[1] = @DesktopHeight - $g_aLaunchSize[3]/2

		WinMove($g_hGUIMain, '', $g_aLaunchSize[0], $g_aLaunchSize[1], $g_aLaunchSize[2], $g_aLaunchSize[3])
		$g_aLaunchSize = Null
	EndIf
	WinActivate($g_hGUIMain)
EndFunc

Func _ShellExecute($sPath, $sParam = '', $sWorkDir = '', $iShowFlag = @SW_SHOW, $bAsAdmin = False)
	ProcessSetPriority(@AutoItPID, $PROCESS_NORMAL)
	If Not ShellExecute($sPath, $sParam, $sWorkDir, $bAsAdmin ? 'RunAs' : '', $iShowFlag) Then
		_ErrorLog(StringFormat('ShellExecute failed:\r\n\tPath: %s\r\n\tParams: %s\r\n\tWorkDir: %s\r\n\tAdmin: %s', $sPath, $sParam, $sWorkDir, $bAsAdmin ? 'Yes' : 'No'))
	EndIf
	ProcessSetPriority(@AutoItPID, $g_iPriority)
EndFunc

Func _PromptFirst($iKeyID)
	If _MasterKeyDataRead($iKeyID, $INI_KEY_PROMPT) Then
		Local $sPromptText = 'Continue with command?' & @LF
		Local $sHint = _FuncLookup(_MasterKeyDataRead($iKeyID, $INI_KEY_FUNC))
		If $sHint = $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_STR] Then
			$sHint &= ' ' & _MasterKeyDataRead($iKeyID, $INI_KEY_PATH)
		EndIf
		If MsgBox(0x42124, $APP_NAME, $sPromptText & ' > ' & $sHint, 0, $g_hGUIMain) = 6 Then
			Return SetExtended(1, True)
		Else
			Return False
		EndIf
	EndIf
	Return True
EndFunc

Func _AdjustVolume($iAdjAmount, $bDisplay)
	Local $iSetVolume
	If $USE_VISTA_FUNCS Then
		$iSetVolume = Round(_GetMasterVolumeLevelScalar()) + $iAdjAmount
		If $iSetVolume > 100 Then $iSetVolume = 100
		If $iSetVolume < 0 Then $iSetVolume = 0
		_SetMasterVolumeLevelScalar($iSetVolume)
	Else
		$iSetVolume = _SoundGetMasterVolume() + $iAdjAmount
		If $iSetVolume > 100 Then $iSetVolume = 100
		If $iSetVolume < 0 Then $iSetVolume = 0
		_SoundSetMasterVolume($iSetVolume)
	EndIf

	If $bDisplay Then
		AdlibRegister('_HideVolumeDisplay', 750)
		Local $iMaxWidth = @DesktopWidth - 80
		Local $iMaxHeight = @DesktopHeight / 10
		Local $iWidth = Round($iMaxWidth*(($iSetVolume+1)/101))
		WinMove($VOLUME_HWND, '', 40, @DesktopHeight - $iMaxHeight - 40, $iWidth, $iMaxHeight)

		GUISetState(@SW_SHOWNA, $VOLUME_HWND)
		WinSetOnTop($VOLUME_HWND, '', 1)
	EndIf
EndFunc

Func _ToggleMute()
	If $USE_VISTA_FUNCS Then
		If _GetMute() Then
			_SetMute(0)
		Else
			_SetMute(1)
		EndIf
	Else
		If _SoundGetMasterMute() Then
			_SoundSetMasterMute(0)
		Else
			_SoundSetMasterMute(1)
		EndIf
	EndIf
EndFunc

Func _HideVolumeDisplay()
	AdlibUnRegister('_HideVolumeDisplay')
	GUISetState(@SW_HIDE, $VOLUME_HWND)
EndFunc

Func _HideTray()
	AdlibUnRegister('_HideTray')
	If $g_iTrayIcon = 0 Then
		TraySetState(2)
	EndIf
EndFunc

Func _TraySetTip()
	If IsArray($MASTER_KEY_LIST) Then
		TraySetToolTip($APP_NAME & ' - ' & $MASTER_KEY_LIST[0][0] & ' hotkeys set')
	Else
		TraySetToolTip($APP_NAME & ' - No hotkeys set')
	EndIf
EndFunc

Func _ErrorLog($sErrorMsg)
	Local $hErrorLog = FileOpen($ERROR_LOG, 1)
	If $hErrorLog <> -1 Then
		$sErrorMsg = StringFormat('[%02d-%02d-%02d %02d:%02d:%02d] %s', @YEAR, @MON, @MDAY, @HOUR, @MIN, @SEC, $sErrorMsg)
		FileWriteLine($hErrorLog, $sErrorMsg)
		FileClose($hErrorLog)
	EndIf
EndFunc

Func _ExitPrompt()
	If $g_iConfExit = 1 And MsgBox(0x2124, $APP_NAME, 'Are you sure you want to shutdown ' & $APP_NAME & '?' & @LF & 'This will disable all hotkeys.', 0, $g_hGUIMain) <> 6 Then Return
	Exit @ScriptLineNumber
EndFunc

Func _ToolTipClear()
	AdlibUnRegister('_ToolTipClear')
	ToolTip('')
EndFunc

Func _StringEscape($sString)
	$sString = StringReplace($sString, '%', '%%')
	$sString = StringReplace($sString, '\', '\\')
	$sString = StringReplace($sString, @CR, '')
	$sString = StringReplace($sString, @LF, '\n')
	$sString = StringReplace($sString, @TAB, '\t')
	Return $sString
EndFunc

#endregion

#region - GUI functions

Func _MainHandler()
	Switch @GUI_CtrlId
		Case $GUI_EVENT_CLOSE
			If $g_iTrayIcon Then
				GUISetState(@SW_HIDE, $g_hGUIMain)
			Else
				_ExitPrompt()
			EndIf
		Case $lv_KeyList
			_GUICtrlListView_SortItems($lv_KeyList, GUICtrlGetState($lv_KeyList))
		Case $bt_Add
			_KeyDialog()
		Case $bt_Edit, $mi_MenuEdit
			_KeyDialog(1)
		Case $mi_MenuCopy
			_KeyDialog(2)
		Case $mi_MenuDisable
			_KeyDisable()
		Case $bt_Delete, $mi_MenuDelete
			_KeyDelete()
		Case $mi_MenuRun
			Local $iSelCount = _GUICtrlListView_GetSelectedCount($lv_KeyList)
			If $iSelCount < 1 Then Return

			Local $iParam = _GUICtrlListView_GetItemParam($lv_KeyList, _GUICtrlListView_GetNextItem($lv_KeyList))
			If $iParam < UBound($KEY_LIST_REVLOOKUP) Then
				_MasterKeyExecutor($KEY_LIST_REVLOOKUP[$iParam])
			EndIf
		Case $bt_Options
			Local $aPos = WinGetPos(GUICtrlGetHandle($bt_Options))
			If Not @error Then _GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($cm_Options), $g_hGUIMain, $aPos[0], $aPos[1] + $aPos[3])
		Case $mi_Readme
			FileInstall('inc_readme.html', $README, 1)
			_ShellExecute($README)
		Case $mi_Source
			FileInstall(@ScriptFullPath, $SOURCE, 1)
			_ShellExecute($SOURCE)
		Case $mi_Log
			_ShellExecute($ERROR_LOG)
		Case $mi_DataDir
			_ShellExecute($DATA_DIR)
		Case $mi_ConfExit
			If $g_iConfExit = 1 Then
				$g_iConfExit = 0
				GUICtrlSetState($mi_ConfExit, $GUI_UNCHECKED)
			Else
				$g_iConfExit = 1
				GUICtrlSetState($mi_ConfExit, $GUI_CHECKED)
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_CONFEXIT, $g_iConfExit)
		Case $mi_ConfDel
			If $g_iConfDelete = 1 Then
				$g_iConfDelete = 0
				GUICtrlSetState($mi_ConfDel, $GUI_UNCHECKED)
			Else
				$g_iConfDelete = 1
				GUICtrlSetState($mi_ConfDel, $GUI_CHECKED)
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_CONFDELETE, $g_iConfDelete)
		Case $mi_KeyTaken
			If $g_iKeyTakenNotice = 1 Then
				$g_iKeyTakenNotice = 0
				GUICtrlSetState($mi_KeyTaken, $GUI_UNCHECKED)
			Else
				$g_iKeyTakenNotice = 1
				GUICtrlSetState($mi_KeyTaken, $GUI_CHECKED)
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_KEYTAKEN, $g_iKeyTakenNotice)
		Case $mi_WinPosMem
			If $g_iWinPosMem = 1 Then
				$g_iWinPosMem = 0
				GUICtrlSetState($mi_WinPosMem, $GUI_UNCHECKED)
			Else
				$g_iWinPosMem = 1
				GUICtrlSetState($mi_WinPosMem, $GUI_CHECKED)
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_MEMWINPOS, $g_iWinPosMem)
		Case $mi_Splash
			If $g_iShowSplash = 1 Then
				$g_iShowSplash = 0
				GUICtrlSetState($mi_Splash, $GUI_UNCHECKED)
			Else
				$g_iShowSplash = 1
				GUICtrlSetState($mi_Splash, $GUI_CHECKED)
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_SPLASH, $g_iShowSplash)
		Case $mi_TrayIcon
			If $g_iTrayIcon = 1 Then
				$g_iTrayIcon = 0
				GUICtrlSetState($mi_TrayIcon, $GUI_UNCHECKED)
				TraySetState(2)
			Else
				$g_iTrayIcon = 1
				GUICtrlSetState($mi_TrayIcon, $GUI_CHECKED)
				TraySetState()
				_TraySetTip()
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_TRAYICON, $g_iTrayIcon)
		Case $mi_TrayTip
			If $g_iTrayTip = 1 Then
				$g_iTrayTip = 0
				GUICtrlSetState($mi_TrayTip, $GUI_UNCHECKED)
			Else
				$g_iTrayTip = 1
				GUICtrlSetState($mi_TrayTip, $GUI_CHECKED)
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_TRAYTIP, $g_iTrayTip)
		Case $mi_Startup
			If FileExists($STARTUP_LINK) Then
				If FileDelete($STARTUP_LINK) Then
					GUICtrlSetState($mi_Startup, $GUI_UNCHECKED)
				Else
					MsgBox(0x2030, $APP_NAME, 'Unable to remove shortcut from Startup folder.', 0, $g_hGUIMain)
				EndIf
			Else
				If FileCreateShortcut(@ScriptFullPath, $STARTUP_LINK, @ScriptDir) Then
					GUICtrlSetState($mi_Startup, $GUI_CHECKED)
				Else
					MsgBox(0x2030, $APP_NAME, 'Unable to create shortcut in Startup folder.', 0, $g_hGUIMain)
				EndIf
			EndIf
		Case $mi_PriLow, $mi_PriNorm, $mi_PriHigh
			If @GUI_CtrlId = $mi_PriHigh Then
				$g_iPriority = $PROCESS_HIGH
			ElseIf @GUI_CtrlId = $mi_PriNorm Then
				$g_iPriority = $PROCESS_NORMAL
			Else
				$g_iPriority = $PROCESS_LOW
			EndIf
			IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_PRIORITY, $g_iPriority)
			ProcessSetPriority(@AutoItExe, $g_iPriority)
		Case $mi_DeleteData
			If MsgBox(0x2134, $APP_NAME, 'Warning!' & @LF & _
				'This will exit FireKey and delete all of your hotkeys.' & @LF & _
				'Are you sure you wish to continue?', 0, $g_hGUIMain) <> 6 Then Return
			If Not DirRemove($DATA_DIR, 1) Then
				If MsgBox(0x2134, $APP_NAME, 'Could not perform cleanup. Manual removal may be necessary.' & @LF & 'View folder?', 0, $g_hGUIMain) = 6 Then
					_ShellExecute('"' & $DATA_DIR & '"')
				EndIf
			Else
				Exit
			EndIf
		Case $mi_Reload
			_MasterKeyLoadList()
		Case $mi_Exit
			_ExitPrompt()
	EndSwitch
EndFunc

Func _EditHandler()
	_ToolTipClear()
	Switch @GUI_CtrlId
		Case $bt_Ed_HotKeyChoose
			_KeyChoose()
		Case $cb_Ed_Functions
			Local $sFuncName = GUICtrlRead($cb_Ed_Functions)
			Switch $sFuncName
				Case $FUNCTIONS_TABLE[$FTBL_ROW_BREAK_1][$FTBL_COL_STR], _
						$FUNCTIONS_TABLE[$FTBL_ROW_BREAK_2][$FTBL_COL_STR], _
						$FUNCTIONS_TABLE[$FTBL_ROW_BREAK_3][$FTBL_COL_STR], _
						$FUNCTIONS_TABLE[$FTBL_ROW_BREAK_4][$FTBL_COL_STR]
					GUICtrlSetState($bt_Ed_OK, $GUI_DISABLE)
				Case Else
					GUICtrlSetState($bt_Ed_OK, $GUI_ENABLE)
			EndSwitch
			Switch $sFuncName
				Case $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_STR]
					GUICtrlSetState($tbi_Ed_Run, $GUI_SHOW)
				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOIT][$FTBL_COL_STR]
					GUICtrlSetState($tbi_Ed_AutoIt, $GUI_SHOW)
				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOITLINE][$FTBL_COL_STR]
					GUICtrlSetState($tbi_Ed_AutoItLine, $GUI_SHOW)
				Case $FUNCTIONS_TABLE[$FTBL_ROW_VOLUME][$FTBL_COL_STR]
					GUICtrlSetState($tbi_Ed_Volume, $GUI_SHOW)
				Case Else
					GUICtrlSetState($tbi_Ed_Blank, $GUI_SHOW)
			EndSwitch
		Case $bt_Ed_BrFile
			Local $T = FileOpenDialog('Select file:', '', 'Applications (*.exe)|All Files (*.*)', 0, '', $g_hGUIEditor)
			If Not @error Then GUICtrlSetData($in_Ed_Path, $T)
		Case $bt_Ed_BrAutoItFile
			Local $T = FileOpenDialog('Select file:', '', 'AutoIt Script Files (*.au3;*.a3x)|All Files (*.*)', 0, '', $g_hGUIEditor)
			If Not @error Then GUICtrlSetData($in_Ed_AutoItPath, $T)
		Case $bt_Ed_BrFolder
			Local $T = FileSelectFolder('Select folder:', '', 1+2+4, '', $g_hGUIEditor)
			If Not @error Then GUICtrlSetData($in_Ed_Path, $T)
		Case $bt_Ed_OK
			If Not $g_sHotKeyAdding Then Return MsgBox(0x2030, $APP_NAME, 'You have not chosen a key combination.', 0, $g_hGUIEditor)

			; Disable the editor
			GUISetState(@SW_DISABLE, $g_hGUIEditor)

			; We change ] char into ) because it's used for Ini Section declarations
			Local $sIniKey = StringReplace($g_sHotKeyAdding, ']', ')')

			; Clear previous hotkey settings if they were there
			IniDelete($KEY_FILE, $sIniKey)

			If $g_sHotKeyEditing Then
				; If editing then remove the old hotkey
				IniDelete($KEY_FILE, StringReplace($g_sHotKeyEditing, ']', ')'))
			EndIf

			; Get the function type
			Local $sFunc = GUICtrlRead($cb_Ed_Functions)

			; Write the function type and if prompt is enabled
			IniWrite($KEY_FILE, $sIniKey, $INI_KEY_FUNC, _FuncLookup($sFunc, 1))
			If BitAND(GUICtrlRead($ch_Ed_Prompt), $GUI_CHECKED) Then
				IniWrite($KEY_FILE, $sIniKey, $INI_KEY_PROMPT, 'Yes')
			EndIf

			If BitAND(GUICtrlRead($ch_Ed_VirtKey), $GUI_CHECKED) Then
				IniWrite($KEY_FILE, $sIniKey, $INI_KEY_VIRTKEY, 'Yes')
			EndIf

			If BitAND(GUICtrlRead($ch_Ed_Disabled), $GUI_CHECKED) Then
				IniWrite($KEY_FILE, $sIniKey, $INI_KEY_DISABLED, 'Yes')
			EndIf

			IniWrite($KEY_FILE, $sIniKey, $INI_KEY_COMMENT, GUICtrlRead($in_Ed_Comment))

			Switch $sFunc
				Case $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_STR]
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_PATH, StringReplace(GUICtrlRead($in_Ed_Path), '"', '')) ; I was going to do a blank string check for this but then I took an error in the knee.
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_PARAMS, GUICtrlRead($in_Ed_Params))
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_WORKDIR, StringReplace(GUICtrlRead($in_Ed_WorkDir), '"', ''))
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_WINSTYLE, _SendMessage(GUICtrlGetHandle($cb_Ed_WinStyle), $CB_GETCURSEL))
					If BitAND(GUICtrlRead($ch_Ed_RunAdmin), $GUI_CHECKED) Then
						IniWrite($KEY_FILE, $sIniKey, $INI_KEY_RUNADMIN, 'Yes')
					EndIf

				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOIT][$FTBL_COL_STR]
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_PATH, StringReplace(GUICtrlRead($in_Ed_AutoItPath), '"', ''))
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_PARAMS, GUICtrlRead($in_Ed_AutoItParams))

				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOITLINE][$FTBL_COL_STR]
					IniWrite($KEY_FILE, $sIniKey, $INI_KEY_PARAMS, _StringEscape(GUICtrlRead($in_Ed_AutoItLine)))

				Case $FUNCTIONS_TABLE[$FTBL_ROW_VOLUME][$FTBL_COL_STR]
					If BitAND(GUICtrlRead($ra_Ed_VolAmount), $GUI_CHECKED) Then
						IniWrite($KEY_FILE, $sIniKey, $INI_KEY_VOLADJUST, Int(GUICtrlRead($in_Ed_VolAdjust)))
						If BitAND(GUICtrlRead($ch_Ed_VolDisplay), $GUI_CHECKED) Then IniWrite($KEY_FILE, $sIniKey, $INI_KEY_VOLDISPLAY, 'Yes')
					Else
						IniWrite($KEY_FILE, $sIniKey, $INI_KEY_VOLADJUST, $INI_KEY_MUTE)
					EndIf
			EndSwitch

			; Reload the keys in the handler and rebuild the listview in the main window
			_MasterKeyLoadList()

			; Re-enable the main window first (seems to prevent flashing), also hide the editor window
			GUISetState(@SW_ENABLE, $g_hGUIMain)
			GUISetState(@SW_HIDE, $g_hGUIEditor)

			; Re-enable and reset the cursor of the editor window
			GUISetState(@SW_ENABLE, $g_hGUIEditor)
			GUISetCursor(Default, 0, $g_hGUIEditor)
			WinActivate($g_hGUIMain)

			GUICtrlSetState($lv_KeyList, $GUI_FOCUS)
			_GUICtrlListView_SetItemSelected($lv_KeyList, 0, 1, 1)
			_GUICtrlListView_EnsureVisible($lv_KeyList, 0)

		Case $GUI_EVENT_DROPPED
			If @GUI_DropId = $in_Ed_Path Then
				GUICtrlSetData($in_Ed_Path, @GUI_DragFile)
			EndIf

		Case $GUI_EVENT_CLOSE, $bt_Ed_Cancel
			GUISetState(@SW_ENABLE, $g_hGUIMain)
			GUISetState(@SW_HIDE, $g_hGUIEditor)
			WinActivate($g_hGUIMain)
	EndSwitch
EndFunc

Func _ResetEditor()
	$g_sHotKeyAdding = ''
	$g_sHotKeyEditing = ''
	GUICtrlSetData($in_Ed_HotKey, '')
	GUICtrlSetState($ch_Ed_Prompt, $GUI_UNCHECKED)
	GUICtrlSetState($ch_Ed_VirtKey, $GUI_UNCHECKED)

	ControlCommand($g_hGUIEditor, '', $cb_Ed_Functions, 'SetCurrentSelection', 0)
	GUICtrlSetState($tbi_Ed_Run, $GUI_SHOW)

	ControlCommand($g_hGUIEditor, '', $cb_Ed_WinStyle, 'SetCurrentSelection', 0)

	Local $aClearFields = [ $in_Ed_Path, $in_Ed_Params, $in_Ed_WorkDir, $in_Ed_AutoItPath, $in_Ed_AutoItParams, $in_Ed_AutoItLine, $in_Ed_Comment ]
	For $i = 0 To UBound($aClearFields)-1
		GUICtrlSetData($aClearFields[$i], '')
	Next

	GUICtrlSetState($ch_Ed_RunAdmin, $GUI_UNCHECKED)
	GUICtrlSetState($ra_Ed_VolAmount, $GUI_CHECKED)
	GUICtrlSetState($ra_Ed_VolMute, $GUI_UNCHECKED)
	GUICtrlSetData($in_Ed_VolAdjust, '0')
	GUICtrlSetState($ch_Ed_VolDisplay, $GUI_CHECKED)

	GUICtrlSetState($ch_Ed_Disabled, $GUI_UNCHECKED)
	GUICtrlSetState($bt_Ed_OK, $GUI_ENABLE)
EndFunc

Func _KeyDisable()
	Local $iSelCount = _GUICtrlListView_GetSelectedCount($lv_KeyList)
	If $iSelCount < 1 Then Return

	Local $iParam = _GUICtrlListView_GetItemParam($lv_KeyList, _GUICtrlListView_GetNextItem($lv_KeyList))
	If $iParam < UBound($KEY_LIST_REVLOOKUP) Then
		Local $iKeyID = $KEY_LIST_REVLOOKUP[$iParam]
		Local $sKey = _MasterKeyDataRead($iKeyID)
		If @error Then Return

		If _MasterKeyDataRead($iKeyID, $INI_KEY_DISABLED) Then
			IniDelete($KEY_FILE, StringReplace($sKey, ']', ')'), $INI_KEY_DISABLED)
		Else
			IniWrite($KEY_FILE, StringReplace($sKey, ']', ')'), $INI_KEY_DISABLED, 'Yes')
		EndIf
	EndIf

	_MasterKeyLoadList()
EndFunc

Func _KeyDelete()
	Local $iSelCount = _GUICtrlListView_GetSelectedCount($lv_KeyList)
	If $iSelCount < 1 Then Return

	Local $iParam = _GUICtrlListView_GetItemParam($lv_KeyList, _GUICtrlListView_GetNextItem($lv_KeyList))
	If $iParam < UBound($KEY_LIST_REVLOOKUP) Then
		Local $iKeyID = $KEY_LIST_REVLOOKUP[$iParam]
		Local $sKey = _MasterKeyDataRead($iKeyID)
		If @error Then Return

		If $g_iConfDelete = 1 And MsgBox(0x2124, $APP_NAME, 'Are you sure you want to delete this hotkey?', 0, $g_hGUIMain) <> 6 Then Return
		IniDelete($KEY_FILE, StringReplace($sKey, ']', ')'))

		_GUICtrlListView_DeleteItemsSelected($lv_KeyList)
	EndIf
EndFunc

Func _KeyDialog($iEditKey = 0)
	_ResetEditor()
	If $iEditKey Then
		Local $iSelCount = _GUICtrlListView_GetSelectedCount($lv_KeyList)
		If $iSelCount < 1 Then Return

		Local $iParam = _GUICtrlListView_GetItemParam($lv_KeyList, _GUICtrlListView_GetNextItem($lv_KeyList))
		If $iParam < UBound($KEY_LIST_REVLOOKUP) Then
			Local $iKeyID = $KEY_LIST_REVLOOKUP[$iParam]
			$g_sHotKeyAdding = _MasterKeyDataRead($iKeyID)
			If @error Then Return
			$g_sHotKeyEditing = $g_sHotKeyAdding

			GUICtrlSetData($in_Ed_HotKey, _HotKeyToString($g_sHotKeyAdding))
			GUICtrlSetData($in_Ed_Comment, _MasterKeyDataRead($iKeyID, $INI_KEY_COMMENT))

			If _MasterKeyDataRead($iKeyID, $INI_KEY_PROMPT) Then GUICtrlSetState($ch_Ed_Prompt, $GUI_CHECKED)
			If _MasterKeyDataRead($iKeyID, $INI_KEY_VIRTKEY) Then GUICtrlSetState($ch_Ed_VirtKey, $GUI_CHECKED)
			If _MasterKeyDataRead($iKeyID, $INI_KEY_DISABLED) Then GUICtrlSetState($ch_Ed_Disabled, $GUI_CHECKED)

			Local $sFunc = _MasterKeyDataRead($iKeyID, $INI_KEY_FUNC)
			_FuncLookup($sFunc)
			ControlCommand($g_hGUIEditor, '', $cb_Ed_Functions, 'SetCurrentSelection', @extended)
			Switch $sFunc
				Case $FUNCTIONS_TABLE[$FTBL_ROW_RUN][$FTBL_COL_ID]
					GUICtrlSetState($tbi_Ed_Run, $GUI_SHOW)
					GUICtrlSetData($in_Ed_Path, _MasterKeyDataRead($iKeyID, $INI_KEY_PATH))
					GUICtrlSetData($in_Ed_Params, _MasterKeyDataRead($iKeyID, $INI_KEY_PARAMS))
					GUICtrlSetData($in_Ed_WorkDir, _MasterKeyDataRead($iKeyID, $INI_KEY_WORKDIR))
					ControlCommand($g_hGUIEditor, '', $cb_Ed_WinStyle, 'SetCurrentSelection', Int(_MasterKeyDataRead($iKeyID, $INI_KEY_WINSTYLE)))
					If _MasterKeyDataRead($iKeyID, $INI_KEY_RUNADMIN) Then GUICtrlSetState($ch_Ed_RunAdmin, $GUI_CHECKED)


				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOIT][$FTBL_COL_ID]
					GUICtrlSetState($tbi_Ed_AutoIt, $GUI_SHOW)
					GUICtrlSetData($in_Ed_AutoItPath, _MasterKeyDataRead($iKeyID, $INI_KEY_PATH))
					GUICtrlSetData($in_Ed_AutoItParams, _MasterKeyDataRead($iKeyID, $INI_KEY_PARAMS))

				Case $FUNCTIONS_TABLE[$FTBL_ROW_AUTOITLINE][$FTBL_COL_ID]
					GUICtrlSetState($tbi_Ed_AutoItLine, $GUI_SHOW)
					GUICtrlSetData($in_Ed_AutoItLine, StringAddCR(StringFormat(_MasterKeyDataRead($iKeyID, $INI_KEY_PARAMS))))

				Case $FUNCTIONS_TABLE[$FTBL_ROW_VOLUME][$FTBL_COL_ID]
					GUICtrlSetState($tbi_Ed_Volume, $GUI_SHOW)
					If _MasterKeyDataRead($iKeyID, $INI_KEY_VOLADJUST) = $INI_KEY_MUTE Then
						GUICtrlSetState($ra_Ed_VolAmount, $GUI_UNCHECKED)
						GUICtrlSetState($ra_Ed_VolMute, $GUI_CHECKED)
					Else
						GUICtrlSetData($in_Ed_VolAdjust, _MasterKeyDataRead($iKeyID, $INI_KEY_VOLADJUST))
						If Not _MasterKeyDataRead($iKeyID, $INI_KEY_VOLDISPLAY) Then
							GUICtrlSetState($ch_Ed_VolDisplay, $GUI_UNCHECKED)
						EndIf
					EndIf
				Case Else
					GUICtrlSetState($tbi_Ed_Blank, $GUI_SHOW)
			EndSwitch

			If $iEditKey = 2 Then
				$g_sHotKeyAdding = ''
				$g_sHotKeyEditing = ''
				GUICtrlSetData($in_Ed_HotKey, '')
			EndIf
		Else
			Return
		EndIf
	EndIf
	GUISetState(@SW_DISABLE, $g_hGUIMain)
	GUISetState(@SW_SHOW, $g_hGUIEditor)
EndFunc

Func _KeyChoose()
	Local $sNewHotKey = $g_sHotKeyAdding
	While 1
		$sNewHotKey = _ChooseHotKeyDialog($sNewHotKey, 'Choose HotKey:', Default, Default, $g_hGUIEditor)
		If Not $sNewHotKey Then Return

		_MasterKeyDataRead($sNewHotKey)
		If Not @error Then
			If MsgBox(0x2124, $APP_NAME, 'That hotkey is already being used and will be replaced, continue anyway?', 0, $g_hGUIEditor) = 7 Then ContinueLoop
		ElseIf Not BitAND(GUICtrlRead($ch_Ed_VirtKey), $GUI_CHECKED) Then
			If HotKeySet($sNewHotKey, '_Dummy') Then
				HotKeySet($sNewHotKey)
			ElseIf $g_iKeyTakenNotice Then
				Local $aTipPos = WinGetPos(GUICtrlGetHandle($in_Ed_HotKey))
				ToolTip('This hotkey is in use by Windows or another application.' & @LF & _
					'It may work if you check "Use virtual key hook" below.', $aTipPos[0]+$aTipPos[2]-$aTipPos[3]/2, $aTipPos[1]+$aTipPos[3]/2, 'Notice', 1, 1)
				AdlibRegister('_ToolTipClear', 5000)
			EndIf
		EndIf

		$g_sHotKeyAdding = $sNewHotKey
		GUICtrlSetData($in_Ed_HotKey, _HotKeyToString($g_sHotKeyAdding))
		Return
	WEnd
EndFunc

#endregion

#region - Message handlers

Func WM_SIZENMOVE($hWnd, $iMsg, $iWParam, $iLParam)
	If $g_iWinPosMem Then
		If $hWnd = $g_hGUIMain Then
			If Not BitAND(WinGetState($g_hGUIMain), 16 + 32) Then
				Local $aPos = WinGetPos($g_hGUIMain)
				IniWrite($CONFIG_FILE, $INI_CFG_TITLE, $INI_CFG_WINPOS, $aPos[0] & '|' & $aPos[1] & '|' & $aPos[2] & '|' & $aPos[3])
			EndIf
		EndIf
	EndIf
EndFunc


Func WM_CONTEXTMENU($hWnd, $iMsg, $iWParam, $iLParam)
	If $iWParam = GUICtrlGetHandle($lv_KeyList) Then
		If _GUICtrlListView_GetSelectedCount($lv_KeyList) > 0 Then
			Local $iParam = _GUICtrlListView_GetItemParam($lv_KeyList, _GUICtrlListView_GetNextItem($lv_KeyList))
			If $iParam < UBound($KEY_LIST_REVLOOKUP) Then
				Local $bDisabled = _MasterKeyDataRead($KEY_LIST_REVLOOKUP[$iParam], $INI_KEY_DISABLED)

				If $bDisabled Then
					GUICtrlSetData($mi_MenuDisable, 'En&able' &@TAB& 'Ctrl+D')
				Else
					GUICtrlSetData($mi_MenuDisable, 'Dis&able' &@TAB& 'Ctrl+D')
				EndIf
			EndIf

			If $iLParam = -1 Then
				Local $iSelItem = _GUICtrlListView_GetNextItem($lv_KeyList)
				Local $aCtrlPos = WinGetPos($iWParam)
				_GUICtrlListView_EnsureVisible($lv_KeyList, $iSelItem)
				Local $aItemRect = _GUICtrlListView_GetItemRect($lv_KeyList, $iSelItem, 2)
				$aItemRect[0] = $aItemRect[0] < 0 ? 0 : $aItemRect[0] + ($aItemRect[2] - $aItemRect[0]) / 2
				$aItemRect[1] = $aItemRect[1] < 0 ? 0 : $aItemRect[1] + ($aItemRect[3] - $aItemRect[1]) / 2
				_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($cm_ItemsMenu), $g_hGUIMain, $aCtrlPos[0] + $aItemRect[0], $aCtrlPos[1] + $aItemRect[1])
			Else
				_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($cm_ItemsMenu), $g_hGUIMain)
			EndIf
		EndIf
	EndIf
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $iWParam, $iLParam)
	Local Const $tagNMHDR = 'struct;hwnd hWndFrom;uint_ptr IDFrom;INT Code;endstruct'
	Local Const $NM_DBLCLK = -3

	Local $iIDFrom = BitAND($iWParam, 0xFFFF)

	If $iIDFrom = $lv_KeyList Then
		Local $tNMHDR = DllStructCreate($tagNMHDR, $iLParam)
		Local $iCode = DllStructGetData($tNMHDR, 'Code')
		If $iCode = $NM_DBLCLK Then
			_KeyDialog(1)
		EndIf
		$tNMHDR = 0
		$iCode = 0
	EndIf

	$iLParam = 0
	Return $GUI_RUNDEFMSG
EndFunc

Func WM_GETMINMAXINFO($hWnd, $iMsg, $wParam, $lParam)
	Local $tMinMaxInfo = DllStructCreate('int;int;int;int;int;int;int;int;int;int', $lParam)
	If $hWnd = $g_hGUIMain Then
		DllStructSetData($tMinMaxInfo, 7, 360+14); min width
		DllStructSetData($tMinMaxInfo, 8, 200+7); min height
		Return
	ElseIf $hWnd = $g_hGUIEditor Then
		DllStructSetData($tMinMaxInfo, 7, 302+14); min width
		DllStructSetData($tMinMaxInfo, 8, 262+7); min height
		Return
	EndIf
EndFunc

#endregion

Func _FK_INTERACT_MSG($hWnd, $iMsg, $iWParam, $iLParam)
	Switch $iWParam
		Case $FK_MSG_OPENLIST
			_OpenKeyList()
		Case Else
			Return -1
	EndSwitch
	Return 1
EndFunc

Func _OnExit()
	GUIDelete($g_hGUIEditor)
	GUIDelete($g_hGUIMain)
EndFunc

Func _Dummy()
EndFunc
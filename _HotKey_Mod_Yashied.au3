#include-once

#cs

This is a version of my _HotKey.au3 include, modified to work with the _Yashied_HotKey_21b.au3 include
(original HotKey_21b.au3 from Yashied > https://www.autoitscript.com/forum/topic/90492-hotkey-udf/).
It requires that file, as well as vkConstants.au3.

#ce

; #INDEX# =======================================================================================================================
; Title .........: _HotKey
; AutoIt Version : 3.3.8.1
; Language ......: English
; Description ...: Functions for dealing with hotkeys.
; Author(s) .....: Rob Saunders (therks)
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
;_ChooseHotKeyDialog
;_HotKeyToString
; ===============================================================================================================================

Global Const $HOTKEY_MODKEYS[4][3] = [ [ '#', 'Win+', $CK_WIN ], [ '^', 'Ctrl+', $CK_CONTROL ], [ '+', 'Shift+', $CK_SHIFT ], [ '!', 'Alt+', $CK_ALT ] ]
Global $HOTKEY_VKCODES = StringSplit('A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|1|2|3|4|5|6|7|8|9|0|' & _
	'OEM_PLUS|OEM_MINUS|OEM_COMMA|OEM_PERIOD|OEM_1|OEM_2|OEM_3|OEM_4|OEM_5|OEM_6|OEM_7|' & _
	'SPACE|RETURN|ESCAPE|BACK|DELETE|UP|DOWN|LEFT|RIGHT|HOME|END|INSERT|PRIOR|NEXT|' & _
	'F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|TAB|SNAPSHOT|PAUSE|CAPITAL|SCROLL|NUMLOCK|' & _
	'DIVIDE|MULTIPLY|SUBTRACT|ADD|DECIMAL|NUMPAD0|NUMPAD1|NUMPAD2|NUMPAD3|NUMPAD4|NUMPAD5|NUMPAD6|NUMPAD7|NUMPAD8|NUMPAD9|' & _
	'APPS|SLEEP|PAUSE|BROWSER_BACK|BROWSER_FORWARD|BROWSER_REFRESH|BROWSER_STOP|BROWSER_SEARCH|BROWSER_FAVORITES|BROWSER_HOME|' & _
	'VOLUME_MUTE|VOLUME_DOWN|VOLUME_UP|MEDIA_NEXT_TRACK|MEDIA_PREV_TRACK|MEDIA_STOP|MEDIA_PLAY_PAUSE|LAUNCH_MEDIA_SELECT|LAUNCH_MAIL|LAUNCH_APP1|LAUNCH_APP2', '|')

Global $HOTKEY_AUCODES = StringSplit('a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z|1|2|3|4|5|6|7|8|9|0|=|-|,|.|;|/|`|[|\|]|''|' & _
	'{space}|{enter}|{esc}|{bs}|{del}|{up}|{down}|{left}|{right}|{home}|{end}|{ins}|{pgup}|{pgdn}|' & _
	'{f1}|{f2}|{f3}|{f4}|{f5}|{f6}|{f7}|{f8}|{f9}|{f10}|{f11}|{f12}|{tab}|{printscreen}|{pause}|{capslock}|{scrolllock}|{numlock}|' & _
	'{numpaddiv}|{numpadmult}|{numpadsub}|{numpadadd}|{numpaddot}|{numpad0}|{numpad1}|{numpad2}|{numpad3}|{numpad4}|{numpad5}|{numpad6}|{numpad7}|{numpad8}|{numpad9}|' & _
	'{appskey}|{sleep}|{break}|{browser_back}|{browser_forward}|{browser_refresh}|{browser_stop}|{browser_search}|{browser_favorites}|{browser_home}|' & _
	'{volume_mute}|{volume_down}|{volume_up}|{media_next}|{media_prev}|{media_stop}|{media_play_pause}|{launch_media}|{launch_mail}|{launch_app1}|{launch_app2}', '|')

Global $HOTKEY_STRINGS_JOIN = 'A|B|C|D|E|F|G|H|I|J|K|L|M|N|O|P|Q|R|S|T|U|V|W|X|Y|Z|1|2|3|4|5|6|7|8|9|0|=|-|,|.|;|/|`|[|\|]|''|' & _
	'Space|Enter|Escape|Backspace|Delete|Up|Down|Left|Right|Home|End|Insert|Page Up|Page Down|F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12|' & _
	'Tab|PrintScreen|Pause|CapsLock|ScrollLock|NumLock|NumPad Divide|NumPad Multiply|NumPad Subtract|NumPad Add|NumPad Period|' & _
	'NumPad 0|NumPad 1|NumPad 2|NumPad 3|NumPad 4|NumPad 5|NumPad 6|NumPad 7|NumPad 8|NumPad 9|Application|Sleep|Break|' & _
	'Browser: Back|Browser: Forward|Browser: Refresh|Browser: Stop|Browser: Search|Browser: Favorites|Browser: Web/Home|' & _
	'Volume: Mute|Volume: Down|Volume: Up|Media: Next|Media: Previous|Media: Stop|Media: Play/pause|' & _
	'Launch: Media player|Launch: E-mail program|Launch: User App1|Launch: User App2'
Global $HOTKEY_STRINGS = StringSplit($HOTKEY_STRINGS_JOIN, '|')

Global $HOTKEY_LOOKUP_TABLE[255][2]
For $i = 1 to $HOTKEY_VKCODES[0]
	$HOTKEY_VKCODES[$i] = Eval('VK_' & $HOTKEY_VKCODES[$i])
	$HOTKEY_LOOKUP_TABLE[$HOTKEY_VKCODES[$i]][0] = $HOTKEY_AUCODES[$i]
	$HOTKEY_LOOKUP_TABLE[$HOTKEY_VKCODES[$i]][1] = $HOTKEY_STRINGS[$i]
Next

; #FUNCTION# ====================================================================================================================
; Name...........: _ChooseHotKeyDialog
; Description ...: Displays a dialog for choosing a hotkey combination.
; Syntax.........: _ChooseHotKeyDialog($sDefaultKey = '', $sTitle = Default, $iLeft = Default, $iTop = Default, $hParent = Default)
; Parameters ....: $sDefaultKey - Preselected key in valid HotKeySet format.
;                  $sTitle      - Title for dialog window.
;                  $iLeft       - Left position of dialog window.
;                  $iTop        - Top position of dialog window.
;                  $hParent     - Handle to parent window.
; Return values .: Success: AutoIt hotkey string.
;                  Failure: "" (empty string).
; Author ........: Rob Saunders (rob at therks dot com)
; ===============================================================================================================================

;~ $h = _ChooseHotKeyDialog()
;~ $v = _HotKeyToVirtKey($h)
;~ $s = _HotKeyToString($h)
;~ $vh = _VirtKeyToHotKey($v)
;~ ConsoleWrite($h & @CRLF)
;~ ConsoleWrite($s & @CRLF)
;~ ConsoleWrite($v & @CRLF)
;~ ConsoleWrite($vh & @CRLF)

Func _ChooseHotKeyDialog($sDefaultKey = '', $sTitle = Default, $iLeft = Default, $iTop = Default, $hParent = Default)
	Local $iGUIOnEventMode	= Opt('GUIOnEventMode', 0)
	Local $iGUICoordMode	= Opt('GUICoordMode', 1)
	Local $sGUIDataSepChar	= Opt('GUIDataSeparatorChar', '|')
	Local $iGUICloseOnEsc	= Opt('GUICloseOnEsc', 1)

	Local Const $GUI_EVENT_CLOSE	= -3
	Local Const $GUI_CHECKED		= 0x00001001
	Local Const $GUI_UNCHECKED		= 0x00001004
	Local Const $CBS_DROPDOWNLIST	= 0x00001003
	Local Const $BS_PUSHLIKE		= 0x00001000
	Local Const $SS_CENTERIMAGE		= 0x00000200
	Local Const $BS_DEFPUSHBUTTON	= 0x00000001

	Local Const $WS_POPUP			= 0x80000000
	Local Const $WS_CAPTION			= 0x00C00000
	Local Const $WS_VSCROLL			= 0x00200000

	Local $aAccelModCombos = StringSplit('|^|+|!|^+|^!|+!|^+!', '|')

	Local $hGUIHotKey, $achModKeys[4], $cbKeyName, $chDetect, $btOK, $btCancel, $dmDefaultKey
	Local $aGUIGetMsg, $sRead, $sReturnKey, $aSplit, $iLookup, $iKeyCount, _
		$aAccelTable[$HOTKEY_AUCODES[0]*$aAccelModCombos[0]][2]

	If IsHWnd($hParent) And WinExists($hParent) Then WinSetState($hParent, '', @SW_DISABLE)
	If $sTitle = Default Then $sTitle = 'Choose hotkey:'

	$hGUIHotKey = GUICreate($sTitle, 270, 70, $iLeft, $iTop, BitOR($WS_POPUP, $WS_CAPTION), Default, $hParent)

	$dmDefaultKey = GUICtrlCreateDummy()

	For $forCombos = 1 To $aAccelModCombos[0]
		For $forKeys = 1 to $HOTKEY_AUCODES[0]
			$aAccelTable[$iKeyCount][0] = $aAccelModCombos[$forCombos] & $HOTKEY_AUCODES[$forKeys]
			$aAccelTable[$iKeyCount][1] = GUICtrlCreateDummy()
			GUICtrlSendToDummy($aAccelTable[$iKeyCount][1], $aAccelModCombos[$forCombos] & $HOTKEY_AUCODES[$forKeys])
			$iKeyCount += 1
		Next
	Next

	$achModKeys[0] = GUICtrlCreateCheckbox('&Win', 5, 5, 30, 20, $BS_PUSHLIKE)
	$achModKeys[1] = GUICtrlCreateCheckbox('&Ctrl', 35, 5, 30, 20, $BS_PUSHLIKE)
	$achModKeys[2] = GUICtrlCreateCheckbox('&Shift', 65, 5, 30, 20, $BS_PUSHLIKE)
	$achModKeys[3] = GUICtrlCreateCheckbox('&Alt', 95, 5, 30, 20, $BS_PUSHLIKE)
	$cbKeyName = GUICtrlCreateCombo('', 130, 5, 135, 200, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
		GUICtrlSetData(-1, $HOTKEY_STRINGS_JOIN, 'A')
	$chDetect = GUICtrlCreateCheckbox('&Detect Key', 5, 40, 120, 25, $BS_PUSHLIKE)
		GUICtrlSetState(-1, $GUI_CHECKED)
	$btOK = GUICtrlCreateButton('OK', 135, 40, 60, 25, $BS_DEFPUSHBUTTON)
	$btCancel = GUICtrlCreateButton('Cancel', 200, 40, 60, 25)

	GUISetState()
	GUISetAccelerators($aAccelTable, $hGUIHotKey)
	ControlFocus($hGUIHotKey, '', $cbKeyName)

	If $sDefaultKey Then GUICtrlSendToDummy($dmDefaultKey, $sDefaultKey)

	While 1
		$aGUIGetMsg = GUIGetMsg(1)
		If $aGUIGetMsg[1] = $hGUIHotKey Then
			Switch $aGUIGetMsg[0]
				Case $chDetect
					If BitAND(GUICtrlRead($chDetect), $GUI_CHECKED) Then
						GUISetAccelerators($aAccelTable, $hGUIHotKey)
					Else
						GUISetAccelerators(0, $hGUIHotKey)
					EndIf

				Case $dmDefaultKey, $aAccelTable[0][1] to $aAccelTable[$iKeyCount-1][1]
					$sDefaultKey = GUICtrlRead($aGUIGetMsg[0])

					If $aGUIGetMsg[0] <> $dmDefaultKey And (__HK_IsPressed(0x5B) Or __HK_IsPressed(0x5C)) Then
						; Add # when Win is detected for Accel keys, but ignore when passed a default key
						$sDefaultKey &= '#'
					EndIf

					For $for = 0 To 3
						GUICtrlSetState($achModKeys[$for], $GUI_UNCHECKED)
						If StringInStr($sDefaultKey, $HOTKEY_MODKEYS[$for][0]) Then
							$sDefaultKey = StringReplace($sDefaultKey, $HOTKEY_MODKEYS[$for][0], '', 1)
							GUICtrlSetState($achModKeys[$for], $GUI_CHECKED)
						EndIf
					Next

					For $for = 1 To $HOTKEY_AUCODES[0]
						If $HOTKEY_AUCODES[$for] = $sDefaultKey Then
							GUICtrlSetData($cbKeyName, $HOTKEY_STRINGS[$for])
							ExitLoop
						EndIf
					Next

					GUISetAccelerators(0, $hGUIHotKey)
					GUICtrlSetState($chDetect, $GUI_UNCHECKED)
				Case $btOK
					$sReturnKey = ''

					For $for = 0 To 3
						If BitAND(GUICtrlRead($achModKeys[$for]), $GUI_CHECKED) Then
							$sReturnKey &= $HOTKEY_MODKEYS[$for][0]
						EndIf
					Next

					$sRead = GUICtrlRead($cbKeyName)
					$iLookup = 0
					For $for = 1 To $HOTKEY_STRINGS[0]
						If $HOTKEY_STRINGS[$for] = $sRead Then
							$iLookup = $for
							ExitLoop
						EndIf
					Next

					If $iLookup Then
						$sReturnKey &= $HOTKEY_AUCODES[$iLookup]
						ExitLoop
					EndIf

				Case $btCancel, $GUI_EVENT_CLOSE
					$sReturnKey = ''
					ExitLoop
			EndSwitch
		EndIf
	WEnd
	GUIDelete($hGUIHotKey)

	Opt('GUICloseOnEsc', $iGUICloseOnEsc)
	Opt('GUIOnEventMode', $iGUIOnEventMode)
	Opt('GUICoordMode', $iGUICoordMode)
	Opt('GUIDataSeparatorChar', $sGUIDataSepChar)

	If IsHWnd($hParent) And WinExists($hParent) Then
		WinSetState($hParent, '', @SW_ENABLE)
		WinActivate($hParent)
	EndIf

	Return $sReturnKey
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _HotKeyToString
; Description ...: Returns a user-friendly string representation of a hotkey combination.
; Syntax.........: _HotKeyToString($sHotKey)
; Parameters ....: $sHotKey - Preselected key in valid HotKeySet format.
; Return values .: Success: Returns string
;                  Failure: Returns "" (blank string)
; Author ........: Rob Saunders (rob at therks dot com)
; ===============================================================================================================================

Func _HotKeyToString($sHotKey)
	Local $bValid, $sReturnKey
	For $for = 0 To 3
		If StringInStr($sHotKey, $HOTKEY_MODKEYS[$for][0]) Then
			$sHotKey = StringReplace($sHotKey, $HOTKEY_MODKEYS[$for][0], '', 1)
			$sReturnKey &= $HOTKEY_MODKEYS[$for][1]
		EndIf
	Next
	For $for = 1 To $HOTKEY_AUCODES[0]
		If $HOTKEY_AUCODES[$for] = $sHotKey Then
			$sReturnKey &= $HOTKEY_STRINGS[$for]
			$bValid = True
			ExitLoop
		EndIf
	Next
	If $bValid Then
		Return $sReturnKey
	Else
		Return SetError(1, 0, '')
	EndIf
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _HotKeyToVirtKey
; Description ...: Converts AutoIt hotkey to Virtual hotkey.
; Syntax.........: _HotKeyToVirtKey($sHotKey)
; Parameters ....: $sHotKey - Hotkey string.
; Return values .: Success: Virtual key code
;                  Failure: 0, sets @error to 1
; Author ........: Rob Saunders (rksaunders gmail)
; ===============================================================================================================================

Func _HotKeyToVirtKey($sHotKey)
	Local $bValid, $iReturnKey
	For $for = 0 To 3
		If StringInStr($sHotKey, $HOTKEY_MODKEYS[$for][0]) Then
			$sHotKey = StringReplace($sHotKey, $HOTKEY_MODKEYS[$for][0], '', 1)
			$iReturnKey += $HOTKEY_MODKEYS[$for][2]
		EndIf
	Next
	For $for = 1 To $HOTKEY_AUCODES[0]
		If $HOTKEY_AUCODES[$for] = $sHotKey Then
			$iReturnKey += $HOTKEY_VKCODES[$for]
			$bValid = True
			ExitLoop
		EndIf
	Next
	If $bValid Then
		Return $iReturnKey
	Else
		Return SetError(1, 0, 0)
	EndIf
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _VirtKeyToHotKey
; Description ...: Converts Virtual hotkey to AutoIt hotkey
; Syntax.........: _VirtKeyToHotKey($iHotKey)
; Parameters ....: $iHotKey - Virtual hotkey
; Return values .: Success: AutoIt hotkey string.
;                  Failure: '', sets @error to 1
; Author ........: Rob Saunders (rksaunders gmail)
; ===============================================================================================================================

Func _VirtKeyToHotKey($iHotKey)
	Local $bValid, $sReturnKey
	For $for = 0 To 3
		If BitAND($HOTKEY_MODKEYS[$for][2], $iHotKey) = $HOTKEY_MODKEYS[$for][2] Then
			$iHotKey = BitXOR($iHotKey, $HOTKEY_MODKEYS[$for][2])
			$sReturnKey &= $HOTKEY_MODKEYS[$for][0]
		EndIf
	Next

	If $iHotKey > 0 And $iHotKey <= 255 Then
		$sReturnKey &= $HOTKEY_LOOKUP_TABLE[$iHotKey][0]
		Return $sReturnKey
	EndIf
	Return SetError(1, 0, '')
EndFunc
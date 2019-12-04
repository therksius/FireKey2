; #FUNCTION# =====================================================================================================================
; Name...........: _WinFade
; Description ...: Non-blocking transition a window from/to transparency.
; Syntax.........: _WinFade ( [ $sTitle [, $sText = '' [, $bShow = True [, $iTime = 500 ] ] ] ] )
; Parameters ....: $sTitle        - The title/hWnd/class of the window to change.
;                                   Leave blank (Default) to check if transition in progress.
;                  $sText         - The text of the window to change
;                  $iFlag         - The show flag of the window.
;                                   If @SW_HIDE, window will fadeout, otherwise will fade in and set state to $iFlag.
;                  $iTime         - How long the fade transition will take (in msec)
; Return values .: Success        - The handle to the window.
;                  Failure        - Return and @error value from WinGetHandle().
; Remarks .......: This function starts an Adlib function (_WinFade_Adlib) so as not to block script execution while the
;                  transition is taking place. If the function is called again the previous transition is completed instantly
;                  before starting the new transition. If the function is called with no parameters (or Default for $sTitle)
;                  the return will be a boolean indicating if a previous transition is still in progress.
; Author ........: Rob @ therks.com
; ================================================================================================================================

Global $WIN_FADE

Func _WinFade($sTitle = Default, $sText = '', $iFlag = @SW_SHOW, $iTime = 500)
	If $sTitle = Default Then
		Return UBound($WIN_FADE) <> 0
	EndIf

	If UBound($WIN_FADE) Then
		AdlibUnRegister(_WinFade_Adlib)
		; Force previous fade to finish
		Int($WIN_FADE[1] ? GUISetState($WIN_FADE[2], $WIN_FADE[0]) : WinSetState($WIN_FADE[0], '', $WIN_FADE[2]))
		WinSetTrans($WIN_FADE[0], '', 255)
	EndIf

	Local $hWnd = IsHWnd($sTitle) ? $sTitle : WinGetHandle($sTitle, $sText)
	If @error Then Return SetError(@error, $hWnd)

	Local $bIsGUI = GUISwitch($hWnd) ; Test if window is AutoIt GUI
	If $bIsGUI Then
		GUISwitch($bIsGUI)
		$bIsGUI = True
	EndIf

	Local $iStep = (2550 / $iTime)

	If $iFlag = @SW_HIDE Then
		Global $WIN_FADE = [ $hWnd, $bIsGUI, $iFlag, 255, -$iStep ]
		WinSetTrans($hWnd, '', 255)
		Int($bIsGUI ? GUISetState(@SW_SHOWNA, $hWnd) : WinSetState($hWnd, '', @SW_SHOWNA))
	Else
		Global $WIN_FADE = [ $hWnd, $bIsGUI, $iFlag, 0, $iStep ]
		WinSetTrans($hWnd, '', 0)
		Int($bIsGUI ? GUISetState($iFlag, $hWnd) : WinSetState($hWnd, '', $iFlag))
	EndIf
	AdlibRegister(_WinFade_Adlib, 10)
	Return $hWnd
EndFunc

Func _WinFade_Adlib()
	Local Enum $WF_HWND, $WF_ISGUI, $WF_FLAG, $WF_IDX, $WF_STEP

	If $WIN_FADE[$WF_STEP] < 0 Then
		If $WIN_FADE[$WF_IDX] >= 0 Then
			WinSetTrans($WIN_FADE[$WF_HWND], '', Int($WIN_FADE[$WF_IDX]))
			$WIN_FADE[$WF_IDX] += $WIN_FADE[$WF_STEP]
		Else
			AdlibUnRegister(_WinFade_Adlib)
			Int($WIN_FADE[$WF_ISGUI] ? GUISetState(@SW_HIDE, $WIN_FADE[$WF_HWND]) : WinSetState($WIN_FADE[$WF_HWND], '', @SW_HIDE))
			WinSetTrans($WIN_FADE[$WF_HWND], '', 255)
			$WIN_FADE = Null
		EndIf
	Else
		If $WIN_FADE[$WF_IDX] <= 255 Then
			WinSetTrans($WIN_FADE[$WF_HWND], '', Int($WIN_FADE[$WF_IDX]))
			$WIN_FADE[$WF_IDX] += $WIN_FADE[$WF_STEP]
		Else
			AdlibUnRegister(_WinFade_Adlib)
			$WIN_FADE = Null
		EndIf
	EndIf
EndFunc
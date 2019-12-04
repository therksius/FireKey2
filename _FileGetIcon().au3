#include-once

#include <WinAPIReg.au3>
#include <WinAPISys.au3>
#include <WinAPIShPath.au3>
#include <WinAPIShellEx.au3>

; #INDEX# =======================================================================================================================
; Title .........: _FileGetIcon
; AutoIt Version : 3.3.14.5
; Language ......: English
; Description ...: Function for getting file icons.
; Author(s) .....: Rob Saunders (therks)
; ===============================================================================================================================

; #FUNCTION# ====================================================================================================================
; Name...........: _FileGetIcon
; Description ...: Get icon location for a file path/type.
; Syntax.........: _FileGetIcon($sFilePath)
; Parameters ....: $sFilePath - Path to file, folder, URL, etc.
; Return values .: Returns 2 element array: [0] = Icon file path, [1] = icon index/ordinal.
;                  Failure: Sets @error:
;                  |1 - Path is drive root but cannot determine drive type
;                  |2 - Path is shortcut file but unable to read it
;                  |3 - The extension is not registered
;                  |4 - The filetype is not registered or has no DefaultIcon set
;                  |5 - Icon file does not exist and cannot be found
;                  |6 - Icon is invalid and cannot be loaded
; Author ........: Rob Saunders (rob at therks dot com)
; Modified.......: Rewrite to use more reliable WinAPI functions
; ===============================================================================================================================


Func _FileGetIcon($sFilePath, $sDefaultIcon = '', $sDefaultIndex = '')
	Local $t_SHFILEINFO = DllStructCreate($tagSHFILEINFO) ; ptr hIcon;int iIcon;dword Attributes;wchar DisplayName[260];wchar TypeName[80]

	_WinAPI_ShellGetFileInfo($sFilePath, $SHGFI_ICONLOCATION, $FILE_ATTRIBUTE_NORMAL, $t_SHFILEINFO) ; #include <WinAPIShellEx.au3>

	Local $aReturnIcon = [ DllStructGetData($t_SHFILEINFO, 'DisplayName'), DllStructGetData($t_SHFILEINFO, 'iIcon') ] ; Initialize $aReturnIcon
	If Not $aReturnIcon[0] Then
		; If no icon from ShellGetFileInfo, try AssocQueryString
		Local $sExt, $sIconData
		Local $aCheckProtocol = StringRegExp($sFilePath, '^(.+?)://', 1) ; check for protocol style path (ie: http://, file://, ftp://, etc)
		If Not @error Then
			If $aCheckProtocol[0] = 'file' Then
				; If path is a file URL, convert to normal file path and pass to function
				Return _FileGetIcon(_WinAPI_PathCreateFromUrl($sFilePath)) ; #include <WinAPIShPath.au3>
			Else
				; Get registry data for the protocol
				$sIconData = _WinAPI_AssocQueryString($aCheckProtocol[0], $ASSOCSTR_DEFAULTICON) ; #include <WinAPIReg.au3>
				$aReturnIcon = _WinAPI_PathParseIconLocation($sIconData) ; #include <WinAPIShPath.au3>
			EndIf
		Else
			$sExt = _WinAPI_PathFindExtension($sFilePath) ; #include <WinAPIShPath.au3>
			; Special case extension processing
			Switch $sExt
				Case '.lnk'
					; Analyze shortcut files to get the icon
					Local $aShortcut = FileGetShortcut($sFilePath)
					If Not @error Then
						If $aShortcut[4] Then
							; If the shortcut has a custom icon
							Local $aReturnIcon = [ $aShortcut[4], $aShortcut[5] ]
						Else
							; If no custom icon, pass shortcut target to function
							Return _FileGetIcon($aShortcut[0])
						EndIf
					EndIf
				Case '.url'
					; Analyze .URL file data for custom icons
					$aReturnIcon[0] = IniRead($sFilePath, 'InternetShortcut', 'IconFile', '')
					$aReturnIcon[1] = IniRead($sFilePath, 'InternetShortcut', 'IconIndex', '')
				Case '.scr', '.exe'
					; .exe is good for returning %1, but .scr seems to return blank
					$aReturnIcon[0] = $sFilePath
			EndSwitch
			If Not $aReturnIcon[0] Then
				; We put this outside the switch in case one of the special case methods returned an empty icon
				; We can still maybe get an icon by filetype
				$sIconData = _WinAPI_AssocQueryString($sExt, $ASSOCSTR_DEFAULTICON) ; #include <WinAPIReg.au3>
				$aReturnIcon = _WinAPI_PathParseIconLocation($sIconData) ; #include <WinAPIShPath.au3>
			EndIf
		EndIf
	EndIf

	If $aReturnIcon[0] = '%1' Then
		$aReturnIcon[0] = $sFilePath
	Else
		If $aReturnIcon[1] < 0 Then
			$aReturnIcon[1] = -$aReturnIcon[1]
		Else
			$aReturnIcon[1] = -($aReturnIcon[1]+1)
		EndIf
	EndIf

	If UBound($aReturnIcon) <> 2 Or Not $aReturnIcon[0] Then
		Local $aReturnIcon = [ $sDefaultIcon, $sDefaultIndex ]
		Return SetError(1, 0, $aReturnIcon)
	Else
		$aReturnIcon[0] = _WinAPI_PathFindOnPath(FileGetLongName(_WinAPI_ExpandEnvironmentStrings($aReturnIcon[0]))) ; #include <WinAPIShPath.au3> / #include <WinAPISys.au3>
		Return $aReturnIcon
	EndIf
EndFunc
#Include-once

#Region Global Variables and Constants

; http://msdn.microsoft.com/en-us/library/ms645540.aspx

Global Const $VK_LBUTTON = 0x01
Global Const $VK_RBUTTON = 0x02
Global Const $VK_CANCEL = 0x03
Global Const $VK_MBUTTON = 0x04
Global Const $VK_XBUTTON1 = 0x05
Global Const $VK_XBUTTON2 = 0x06
; 0x07 - Undefined
Global Const $VK_BACK = 0x08
Global Const $VK_TAB = 0x09
Global Const $VK_SHIFT = 0x10
; 0x0A - 0x0B - Reserved
Global Const $VK_CLEAR = 0x0C
Global Const $VK_RETURN = 0x0D
; 0x0E - 0x0F - Undefined
Global Const $VK_CONTROL = 0x11
Global Const $VK_MENU = 0x12
Global Const $VK_PAUSE = 0x13
Global Const $VK_CAPITAL = 0x14
; 0x15
; 0x16 - Undefined
; 0x17
; 0x18
; 0x19
; 0x1A - Undefined
Global Const $VK_ESCAPE = 0x1B
; 0x1C
; 0x1D
; 0x1E
; 0x1F
Global Const $VK_SPACE = 0x20
Global Const $VK_PRIOR = 0x21
Global Const $VK_NEXT = 0x22
Global Const $VK_END = 0x23
Global Const $VK_HOME = 0x24
Global Const $VK_LEFT = 0x25
Global Const $VK_UP = 0x26
Global Const $VK_RIGHT = 0x27
Global Const $VK_DOWN = 0x28
Global Const $VK_SELECT = 0x29
Global Const $VK_PRINT = 0x2A
Global Const $VK_EXECUTE = 0x2B
Global Const $VK_SNAPSHOT = 0x2C
Global Const $VK_INSERT = 0x2D
Global Const $VK_DELETE = 0x2E
Global Const $VK_HELP = 0x2F
Global Const $VK_0 = 0x30
Global Const $VK_1 = 0x31
Global Const $VK_2 = 0x32
Global Const $VK_3 = 0x33
Global Const $VK_4 = 0x34
Global Const $VK_5 = 0x35
Global Const $VK_6 = 0x36
Global Const $VK_7 = 0x37
Global Const $VK_8 = 0x38
Global Const $VK_9 = 0x39
; 0x3A - 0x40 - Undefined
Global Const $VK_A = 0x41
Global Const $VK_B = 0x42
Global Const $VK_C = 0x43
Global Const $VK_D = 0x44
Global Const $VK_E = 0x45
Global Const $VK_F = 0x46
Global Const $VK_G = 0x47
Global Const $VK_H = 0x48
Global Const $VK_I = 0x49
Global Const $VK_J = 0x4A
Global Const $VK_K = 0x4B
Global Const $VK_L = 0x4C
Global Const $VK_M = 0x4D
Global Const $VK_N = 0x4E
Global Const $VK_O = 0x4F
Global Const $VK_P = 0x50
Global Const $VK_Q = 0x51
Global Const $VK_R = 0x52
Global Const $VK_S = 0x53
Global Const $VK_T = 0x54
Global Const $VK_U = 0x55
Global Const $VK_V = 0x56
Global Const $VK_W = 0x57
Global Const $VK_X = 0x58
Global Const $VK_Y = 0x59
Global Const $VK_Z = 0x5A
Global Const $VK_LWIN = 0x5B
Global Const $VK_RWIN = 0x5C
; 0x5E - Reserved
Global Const $VK_APPS = 0x5D
Global Const $VK_SLEEP = 0x5F
Global Const $VK_NUMPAD0 = 0x60
Global Const $VK_NUMPAD1 = 0x61
Global Const $VK_NUMPAD2 = 0x62
Global Const $VK_NUMPAD3 = 0x63
Global Const $VK_NUMPAD4 = 0x64
Global Const $VK_NUMPAD5 = 0x65
Global Const $VK_NUMPAD6 = 0x66
Global Const $VK_NUMPAD7 = 0x67
Global Const $VK_NUMPAD8 = 0x68
Global Const $VK_NUMPAD9 = 0x69
Global Const $VK_MULTIPLY = 0x6A
Global Const $VK_ADD = 0x6B
Global Const $VK_SEPARATOR = 0x6C
Global Const $VK_SUBTRACT = 0x6D
Global Const $VK_DECIMAL = 0x6E
Global Const $VK_DIVIDE = 0x6F
Global Const $VK_F1 = 0x70
Global Const $VK_F2 = 0x71
Global Const $VK_F3 = 0x72
Global Const $VK_F4 = 0x73
Global Const $VK_F5 = 0x74
Global Const $VK_F6 = 0x75
Global Const $VK_F7 = 0x76
Global Const $VK_F8 = 0x77
Global Const $VK_F9 = 0x78
Global Const $VK_F10 = 0x79
Global Const $VK_F11 = 0x7A
Global Const $VK_F12 = 0x7B
Global Const $VK_F13 = 0x7C
Global Const $VK_F14 = 0x7D
Global Const $VK_F15 = 0x7E
Global Const $VK_F16 = 0x7F
Global Const $VK_F17 = 0x80
Global Const $VK_F18 = 0x81
Global Const $VK_F19 = 0x82
Global Const $VK_F20 = 0x83
Global Const $VK_F21 = 0x84
Global Const $VK_F22 = 0x85
Global Const $VK_F23 = 0x86
Global Const $VK_F24 = 0x87
; 0x88 - 0x8F - Unassigned
Global Const $VK_NUMLOCK = 0x90
Global Const $VK_SCROLL = 0x91
; 0x92 - 0x96 - OEM specific
; 0x97 - 0x9F - Unassigned
Global Const $VK_LSHIFT = 0xA0
Global Const $VK_RSHIFT = 0xA1
Global Const $VK_LCONTROL = 0xA2
Global Const $VK_RCONTROL = 0xA3
Global Const $VK_LMENU = 0xA4
Global Const $VK_RMENU = 0xA5
Global Const $VK_BROWSER_BACK = 0xA6
Global Const $VK_BROWSER_FORWARD = 0xA7
Global Const $VK_BROWSER_REFRESH = 0xA8
Global Const $VK_BROWSER_STOP = 0xA9
Global Const $VK_BROWSER_SEARCH = 0xAA
Global Const $VK_BROWSER_FAVORITES = 0xAB
Global Const $VK_BROWSER_HOME = 0xAC
Global Const $VK_VOLUME_MUTE = 0xAD
Global Const $VK_VOLUME_DOWN = 0xAE
Global Const $VK_VOLUME_UP = 0xAF
Global Const $VK_MEDIA_NEXT_TRACK = 0xB0
Global Const $VK_MEDIA_PREV_TRACK = 0xB1
Global Const $VK_MEDIA_STOP = 0xB2
Global Const $VK_MEDIA_PLAY_PAUSE = 0xB3
Global Const $VK_LAUNCH_MAIL = 0xB4
Global Const $VK_LAUNCH_MEDIA_SELECT = 0xB5
Global Const $VK_LAUNCH_APP1 = 0xB6
Global Const $VK_LAUNCH_APP2 = 0xB7
; 0xB8 - 0xB9 - Reserved
Global Const $VK_OEM_1 = 0xBA; ';:'
Global Const $VK_OEM_PLUS = 0xBB; '=+'
Global Const $VK_OEM_COMMA = 0xBC; ',<'
Global Const $VK_OEM_MINUS = 0xBD; '-_'
Global Const $VK_OEM_PERIOD = 0xBE; '.>'
Global Const $VK_OEM_2 = 0xBF; '/?'
Global Const $VK_OEM_3 = 0xC0; '`~'
; 0xC1 - 0xD7 - Reserved
; 0xD8 - 0xDA - Unassigned
Global Const $VK_OEM_4 = 0xDB; '[{'
Global Const $VK_OEM_5 = 0xDC; '\|'
Global Const $VK_OEM_6 = 0xDD; ']}'
Global Const $VK_OEM_7 = 0xDE; ''"'
Global Const $VK_OEM_8 = 0xDF
; 0xE0 - Reserved
; 0xE1 - OEM specific
Global Const $VK_OEM_102 = 0xE2
; 0xE3 - 0xE4 - OEM specific
; 0xE5
; 0xE6 - OEM specific
; 0xE7
; 0xE8 - Unassigned
; 0xE9 - 0xF5 - OEM specific
Global Const $VK_ATTN = 0xF6
Global Const $VK_CRSEL = 0xF7
Global Const $VK_EXSEL = 0xF8
Global Const $VK_EREOF = 0xF9
Global Const $VK_PLAY = 0xFA
Global Const $VK_ZOOM = 0xFB
Global Const $VK_NONAME = 0xFC
Global Const $VK_PA1 = 0xFD
Global Const $VK_OEM_CLEAR = 0xFE

#EndRegion Global Variables and Constants

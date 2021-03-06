include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc

; ��������� ������������ ������
STD_INPUT_HANDLE equ -10
STD_OUTPUT_HANDLE equ -11
STD_ERROR_HANDLE equ -12

; ��������� ���������
COORD STRUC
	X DW ?
	Y DW ?
COORD ENDS

;���� ���� �������
FOREGROUND_BLUE equ 1h ; ����� ���� ����
FOREGROUND_GREEN equ 2h ; ������� ���� ����
FOREGROUND_RED equ 4h ; ������� ���� ����
FOREGROUND_INTENSITY equ 8h ; ���������� �������������
BACKGROUND_BLUE equ 10h ; ����� ���� ����
BACKGROUND_GREEN equ 20h ; ������� ���� ����
BACKGROUND_RED equ 40h ; ������� ���� ����
BACKGROUND_INTENSITY equ 80h ; ���������� �������������

; ��� �������
KEY_EV equ 1h ; ������������ �������
MOUSE_EV equ 2h ; ������� � �����
WINDOW_BUFFER_SIZE_EV equ 4h ; ��������� ������ ����
MENU_EV equ 8h ; ���������������
FOCUS_EV equ 10h ; ���������������

; ��������� - ��������� ����������
RIGHT_ALT_PRESSED equ 1h
LEFT_ALT_PRESSED equ 2h
RIGHT_CTRL_PRESSED equ 4h
LEFT_CTRL_PRESSED equ 8h
SHIFT_PRESSED equ 10h
NUMLOCK_ON equ 20h
SCROLLLOCK_ON equ 40h
CAPSLOCK_ON equ 80h
ENHANCED_KEY equ 100h

; ������� ����
MOUSE_MOVED equ 1h; ���� �������� ����
DOUBLE_CLICK equ 2h; ��� ������� ������

; �������� ������� ��������� PINPUT_RECORD
; ������� ����
MOUSE_EVENT_RECORD STRUCT
	dwMousePosition COORD <>
	dwButtonState DWORD ?
	dwControlKeyState DWORD ?
	dwEventFlags DWORD ?
MOUSE_EVENT_RECORD ENDS

; ������� ����������
KEY_EVENT_RECORD STRUCT
	bKeyDown DD ?
	wRepeatCount DW ?
	wVirtualKeyCode DW ?
	wVirtualScanCode DW ?
	UNION
		UnicodeChar DW ?
		AsciiChar DB ?
	ENDS
	dwControlKeyState DD ?
KEY_EVENT_RECORD ENDS

; ��������� ������� ���� �������
WINDOW_BUFFER_SIZE_RECORD STRUCT
	dwSize COORD <>
WINDOW_BUFFER_SIZE_RECORD ENDS

MENU_EVENT_RECORD STRUCT
	dwCommandId DWORD ?
MENU_EVENT_RECORD ENDS

FOCUS_EVENT_RECORD STRUCT
	bSetFocus DWORD ?
FOCUS_EVENT_RECORD ENDS

; ��������� PINPUT_RECORD
INPUT_RECORD STRUCT
	EventType DW ?
	DW ?
	UNION
		KeyEvent KEY_EVENT_RECORD <>
		MouseEvent MOUSE_EVENT_RECORD <>
		WindowBufferSizeEvent WINDOW_BUFFER_SIZE_RECORD <>
		MenuEvent MENU_EVENT_RECORD <>
		FocusEvent FOCUS_EVENT_RECORD <>
	ENDS
	INPUT_RECORD ENDS

; ������ ������ �������� ��������� ����������
.data
@CO DD ?
@numBytes DD ?
KeyEvent INPUT_RECORD <>
@SYMBOL DB ?

.code
;-------------------------------------------------------------------
; ������� ���������� ������� � �������
; consoleInHandle - ���������� ������ ������� �����
; consoleOutHandle - ���������� ������ ������� ������
; Display - ���������� ������������ �������:
; 0 - ������ ������������
; 1 - ������ �� ������������
; ������� ���������� ��������� ������ � �������� al

ReadSymbol proc consoleInHandle:DWORD, consoleOutHandle:DWORD, Display:DWORD
@L1:
	INVOKE ReadConsoleInputA, consoleInHandle, offset KeyEvent, 1, offset @CO
	CMP KeyEvent.EventType, KEY_EV
	JNE @L1
	; ���������� ���������� �������
	MOV AL, KeyEvent.KeyEvent.AsciiChar
	MOV @SYMBOL, AL
	CMP Display, 0
	JNE @L2
	;����� �������
	INVOKE WriteConsoleA, consoleOutHandle, OFFSET @SYMBOL, 1, OFFSET @numBytes, 0
	; ���������� ������� ���������� ���������� �������
@L2:
	INVOKE ReadConsoleInputA, consoleInHandle, offset KeyEvent, 1, offset @CO
	CMP KeyEvent.EventType, KEY_EV
	JNE @L2
	mov eax,0
	mov al, @SYMBOL
	ret
ReadSymbol endp

;-------------------------------------------------------------------
; ������������� ������ ����� � ��������� �����
; Number - ����� �����
; Str1 - ��������� �� ������, � ������� ����� �������� ������������� �����
; ������� ���������� ����� ������ �������� � �������� EAX
IntToStr proc Number:DWORD, Str1:DWORD
	MOV EAX, Number
	MOV EDI,Str1
	MOV ECX, 0
	CMP EAX,0
	JGE @I1
	MOV DL, '-'
	MOV [EDI],DL
	INC EDI
	NOT EAX
	INC EAX
@I1:
	MOV EBX, 10
	MOV EDX, 0
	IDIV EBX
	PUSH EDX
	INC ECX
	CMP EAX,0
	JG @I1
@I2:
	POP EDX
	ADD DL, 30h
	MOV [EDI],DL
	INC EDI
	LOOP @I2
	MOV DL,0
	MOV [EDI], DL
	INC EDI
	MOV EAX, EDI
	SUB EAX, Str1
	ret
IntToStr endp

;-------------------------------------------------------------------
; ����������� ����� ������
; Str1 - ��������� �� ������
; ������� ���������� ����� ������ �������� � �������� EAX
LENSTR PROC Str1:DWORD
	CLD
	CLD
	MOV EDI, Str1
	MOV EBX,EDI
	MOV ECX,100 ; ���������� ����� ������
	MOV EAX, 0
	REPNE SCASB ; ����� ������ 0
	SUB EDI, EBX ; ����� ������, ������� 0
	MOV EAX,EDI
	DEC EAX
	RET
LENSTR ENDP

;-------------------------------------------------------------------
; ����� ������ � ���� �������
; StrPtr - ��������� �� ��������� ������, �������������� 0
; consoleOutHandle - ���������� ������ ������� ������
PrintStr proc StrPtr:DWORD, Handle:DWORD
	INVOKE CharToOem, StrPtr, StrPtr
	INVOKE LENSTR, StrPtr ; ����������� ����� ������
	INVOKE WriteConsole, Handle, StrPtr, eax, OFFSET @numBytes, 0
	ret
PrintStr endp
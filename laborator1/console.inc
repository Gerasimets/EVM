include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc

; константы дескрипторов буфера
STD_INPUT_HANDLE equ -10
STD_OUTPUT_HANDLE equ -11
STD_ERROR_HANDLE equ -12

; структура координат
COORD STRUC
	X DW ?
	Y DW ?
COORD ENDS

;Цвет окна консоли
FOREGROUND_BLUE equ 1h ; синий цвет букв
FOREGROUND_GREEN equ 2h ; зеленый цвет букв
FOREGROUND_RED equ 4h ; красный цвет букв
FOREGROUND_INTENSITY equ 8h ; повышенная интенсивность
BACKGROUND_BLUE equ 10h ; синий свет фона
BACKGROUND_GREEN equ 20h ; зеленый цвет фона
BACKGROUND_RED equ 40h ; красный цвет фона
BACKGROUND_INTENSITY equ 80h ; повышенная интенсивность

; тип события
KEY_EV equ 1h ; клавиатурное событие
MOUSE_EV equ 2h ; событие с мышью
WINDOW_BUFFER_SIZE_EV equ 4h ; изменился размер окна
MENU_EV equ 8h ; зарезервировано
FOCUS_EV equ 10h ; зарезервировано

; константы - состояния клавиатуры
RIGHT_ALT_PRESSED equ 1h
LEFT_ALT_PRESSED equ 2h
RIGHT_CTRL_PRESSED equ 4h
LEFT_CTRL_PRESSED equ 8h
SHIFT_PRESSED equ 10h
NUMLOCK_ON equ 20h
SCROLLLOCK_ON equ 40h
CAPSLOCK_ON equ 80h
ENHANCED_KEY equ 100h

; события мыши
MOUSE_MOVED equ 1h; было движение мыши
DOUBLE_CLICK equ 2h; был двойной щелчок

; описание событий структуры PINPUT_RECORD
; событие мыши
MOUSE_EVENT_RECORD STRUCT
	dwMousePosition COORD <>
	dwButtonState DWORD ?
	dwControlKeyState DWORD ?
	dwEventFlags DWORD ?
MOUSE_EVENT_RECORD ENDS

; событие клавиатуры
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

; изменение размера окна консоли
WINDOW_BUFFER_SIZE_RECORD STRUCT
	dwSize COORD <>
WINDOW_BUFFER_SIZE_RECORD ENDS

MENU_EVENT_RECORD STRUCT
	dwCommandId DWORD ?
MENU_EVENT_RECORD ENDS

FOCUS_EVENT_RECORD STRUCT
	bSetFocus DWORD ?
FOCUS_EVENT_RECORD ENDS

; Структура PINPUT_RECORD
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

; Секция данных содержит временные переменные
.data
@CO DD ?
@numBytes DD ?
KeyEvent INPUT_RECORD <>
@SYMBOL DB ?

.code
;-------------------------------------------------------------------
; Функция считывание символа в консоли
; consoleInHandle - дескриптор буфера консоли ввода
; consoleOutHandle - дескриптор буфера консоли вывода
; Display - управление отображением символа:
; 0 - символ отображается
; 1 - символ не отображается
; функция возвращает считанный символ в регистре al

ReadSymbol proc consoleInHandle:DWORD, consoleOutHandle:DWORD, Display:DWORD
@L1:
	INVOKE ReadConsoleInputA, consoleInHandle, offset KeyEvent, 1, offset @CO
	CMP KeyEvent.EventType, KEY_EV
	JNE @L1
	; сохранение введенного символа
	MOV AL, KeyEvent.KeyEvent.AsciiChar
	MOV @SYMBOL, AL
	CMP Display, 0
	JNE @L2
	;вывод символа
	INVOKE WriteConsoleA, consoleOutHandle, OFFSET @SYMBOL, 1, OFFSET @numBytes, 0
	; Считывание события клавиатуры отпускания клавиши
@L2:
	INVOKE ReadConsoleInputA, consoleInHandle, offset KeyEvent, 1, offset @CO
	CMP KeyEvent.EventType, KEY_EV
	JNE @L2
	mov eax,0
	mov al, @SYMBOL
	ret
ReadSymbol endp

;-------------------------------------------------------------------
; Представление целого числа в текстовой форме
; Number - целое число
; Str1 - указатель на строку, в которую будет помещено представление числа
; функция возвращает длину строки символов в регистре EAX
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
; Определение длины строки
; Str1 - указатель на строку
; функция возвращает длину строки символов в регистре EAX
LENSTR PROC Str1:DWORD
	CLD
	CLD
	MOV EDI, Str1
	MOV EBX,EDI
	MOV ECX,100 ; ограничить длину строки
	MOV EAX, 0
	REPNE SCASB ; найти символ 0
	SUB EDI, EBX ; длина строки, включая 0
	MOV EAX,EDI
	DEC EAX
	RET
LENSTR ENDP

;-------------------------------------------------------------------
; Вывод строки в окно консоли
; StrPtr - указатель на выводимую строку, оканчивающуюся 0
; consoleOutHandle - дескриптор буфера консоли вывода
PrintStr proc StrPtr:DWORD, Handle:DWORD
	INVOKE CharToOem, StrPtr, StrPtr
	INVOKE LENSTR, StrPtr ; определение длины строки
	INVOKE WriteConsole, Handle, StrPtr, eax, OFFSET @numBytes, 0
	ret
PrintStr endp
.586
.MODEL FLAT, stdcall
include console.inc

.DATA
consoleOutHandle DD ? ; ���������� ��������� ������
consoleInHandle DD ? ; ���������� �������� ������
numBytes DD ?
IN_STR Db "������� ������ �� 10 ����� ����� ������", 10, 0
space dw 32 ; ������
TITL Db "� ������� �� 10 ����� ����������� �������� � ���������� �������.", 0
n dw 10 ; \n
SymCount Dw 10 dup(?) ; ������ � ����������� ��������
CRD COORD <?> ; ��������� ���������
MASS DD 10 dup (?) ; ������

.CODE
START proc

	; ���������� �������, ������� ���������� ��� ������������
	INVOKE FreeConsole
	INVOKE AllocConsole

	; �������� �����������
	INVOKE GetStdHandle, STD_INPUT_HANDLE
	MOV consoleInHandle, EAX
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	MOV consoleOutHandle, EAX

	; ������ ��������� ���� �������
	INVOKE CharToOem, OFFSET TITL, OFFSET TITL
	INVOKE SetConsoleTitle, OFFSET TITL

	; ������ ������ ���� �������
	MOV CRD.X, 80
	MOV CRD.Y, 25
	mov eax, CRD
	INVOKE SetConsoleScreenBufferSize, consoleOutHandle, EAX

	;INVOKE FillConsoleOutputAttribute, consoleOutHandle, BACKGROUND_RED + BACKGROUND_GREEN, 3000, 0, offset numBytes ; ������ ���� ���� �������

	; ���������� ������� �������
	MOV CRD.X,0
	MOV CRD.Y,0
	mov eax, CRD
	INVOKE SetConsoleCursorPosition, consoleOutHandle, EAX

	;INVOKE SetConsoleTextAttribute, consoleOutHandle, FOREGROUND_BLUE + BACKGROUND_GREEN ; ������ �������� �������� ���������� ������

	INVOKE PrintStr, offset IN_STR, consoleOutHandle ; ����� ��������� ������� ������:

	;��������� ������

	lea EDI, MASS ; ����� ������ �������
	xor ebx, ebx ; �������� ebx, ��� ��� ����� ������������ ��� ��� �������
	jmp start11 ; ����� ���� �� ��� �����

spacer: ; ���� ������� ������
	add edi, 4 ; ��������� � ���������� ���������� ��������
	add ebx, 1 ; �������� ebx �� 1
start11: ; ��������� ���� ������ � ����� ������
	xor esi, esi ; �������� ������� ������ �����
	cmp ebx, 10 ; ���������� � 10,
	je exit ; ���� �����, �� �� �����

NewSymb: ; ������������ ����, ��� ������ ������ �������

	INVOKE ReadSymbol, consoleInHandle, consoleOutHandle, 0 ; ������ ������ � eax
	cmp eax, 32 ; ���� ��� ������, ��
	je spacer ; ���������� ���

	cmp eax, 45 ; ���� �� ������� '-'
	JNE standart ; ���� ��� ������
	mov eax, -1 ; ���� �������, �� �������� �� ������� �� -1
	mov [EDI], eax ; � ������ � ������
	jmp NewSymb ; ������� ��������� ������

standart: ; ��������
	sub eax, 48 ; ��� ��� ���� ��� ASCII
	cmp esi, 0 ; ���� ��� ������ ����� �����
	jne NotOtr ; ���� ��� ������
	mov ecx, [edi] ; ���� ������� ������� �������
	cmp ecx, -1 ; ����� -1
	jne NotOtr ; ���� ��� ������
	imul ecx ; �������� �� �������� �����
NotOtr:
	cmp esi, 0 ; ������� ����� ��� ����� � �����
	je Not1Symb ; ���� ��� ������ �����, �� ���������
	mov ecx, [EDI] ; ���� ��� �� ������ �����, �� ������� ����� ���������
	mov esi, eax ; ��������� ����� ���� ���������
	mov eax, 10 ; ��������� 10
	imul ecx ; �������� ������� ����� �� 10
	cmp eax, 0 ; ���� ������� ����� �������������
	JNGE Otrz ; ������
	add eax, esi ; ������� ������� x10 �� ���������
	jmp Not1Symb ; ����������
Otrz: ; ���� ������� ����� �������������
	mov ecx, eax ; ��������� �����
	mov eax, -1 ; �������� -1
	imul esi ; �������� ��������� ����� �� -1
	add eax, ecx ; ������� ��� ������������� �����
Not1Symb:
	mov esi, 1 ; ������� ����
	mov [EDI], eax ; � �������� ������� � ������ ��� �� ������ �����
	jmp NewSymb ; ������������ ��� ������ ������ �������

exit:

	INVOKE PrintStr, offset n, consoleOutHandle ; ������ �������� ������ \n

	; ���� ������������ �������

	lea edi, mass ; ����� ����� ������ �������
    xor ecx, ecx ; �������� ������ ���������
    mov ebx, [edi] ; ������ ������� ������� � ebx � ��� ��������� �� ������������
	add edi, 4 ; ��������� � ���������� ��������

    start1: ; ���� ������ �� ��� ��������
    inc ecx ; ������� ����� �������, ������� ��������� �������
    cmp ebx, [edi] ; ���������� ������� ������������ ������� � �������
    JNL end1 ; ���� ������� ������� ������ ��� �����, �� ������� ���������
    JNGE new_max ; ���� ������� ������� ������, �� ������������ ���� ��������

    new_max: ; ������ ������������
    mov ebx, [edi] ; ������ ������� ������� � ebx, ������ �� ������������
    jmp end1 ; ����������� ������������ �������� ��������

    end1: ; ���� ������� ������� �������
    add edi, 4 ; ����������� edi �� 4, �� ������� �������
    cmp ecx, 10 ; ������� ���������� ���������� ���������
    je end2 ; ���� �� 10, �� �������
    jmp start1 ; ���� ������ 10, ���������� �����

    end2: ; ����� ������ �������������
    sub edi, 4 ; ������������ � 10� (���������) �������
    xor ecx, ecx ; �������� �������

    start2: ; ���� �� ������� ��� 10 ���������
    inc ecx ; ����������� �������
	mov esi, [edi] ; ������ ������� ������� � esi
    cmp esi, 0 ; ���������� ������� � �����
    JNGE divis ; ���� ������� ������ ����, �� ����� �� ������������
    jmp end3 ; ���� ���, ����������� ������������� ����� �������� � ��������� � ����������

    divis: ; ����� ������ ������� �� ������������
    mov eax, [edi] ; ������� ������� � eax
    cdq ; ��������� ������� (EAX) �� EDX:EAX
    idiv ebx ; ����� ������������� �� ������������
    mov [edi], eax ; �������� ������ � ������� �������

    end3:
    sub edi, 4 ; ���� � ���� �������� � �������� �������
    cmp ecx, 10 ; ������� ���������� ���������� ���������
    JNE start2 ; ���� �� ����� 10, �� ��������� �� start2

	; ����� �������
	xor esi, esi ; �������� esi (��������)
start3: ; ������������ ���� ���� �� ������� ���� ������
	lea EDI, MASS ; ����� ������ �������
	add edi, esi ; ���������� ��������
	INVOKE IntToStr, [EDI], offset SymCount ; ��������� � ���
	INVOKE PrintStr, offset SymCount, consoleOutHandle ; �������
	INVOKE PrintStr, offset space, consoleOutHandle ; ������
	add esi, 4 ; ����������� �������� �� 4
	cmp esi, 40 ; ���� �������� �� ������ ������ 40
	jne start3 ; ����� ������������

	INVOKE ReadSymbol, consoleInHandle, consoleOutHandle, 1 ; ����� �� ����������� �������
	INVOKE ExitProcess, 0 ; ����� �������
	RET
	START ENDP
END START
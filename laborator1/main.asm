.586
.MODEL FLAT, stdcall
include console.inc

.DATA
consoleOutHandle DD ? ; дескриптор выходного буфера
consoleInHandle DD ? ; дескриптор входного буфера
numBytes DD ?
IN_STR Db "Введите массив из 10 чисел через пробел", 10, 0
space dw 32 ; пробел
TITL Db "В массиве из 10 чисел переставить элементы в зеркальном порядке.", 0
n dw 10 ; \n
SymCount Dw 10 dup(?) ; строка с количеством символов
CRD COORD <?> ; структура координат
MASS DD 10 dup (?) ; массив

.CODE
START proc

	; образовать консоль, вначале освободить уже существующую
	INVOKE FreeConsole
	INVOKE AllocConsole

	; получить дескрипторы
	INVOKE GetStdHandle, STD_INPUT_HANDLE
	MOV consoleInHandle, EAX
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	MOV consoleOutHandle, EAX

	; задать заголовок окна консоли
	INVOKE CharToOem, OFFSET TITL, OFFSET TITL
	INVOKE SetConsoleTitle, OFFSET TITL

	; задать размер окна консоли
	MOV CRD.X, 80
	MOV CRD.Y, 25
	mov eax, CRD
	INVOKE SetConsoleScreenBufferSize, consoleOutHandle, EAX

	;INVOKE FillConsoleOutputAttribute, consoleOutHandle, BACKGROUND_RED + BACKGROUND_GREEN, 3000, 0, offset numBytes ; задать цвет окна консоли

	; установить позицию курсора
	MOV CRD.X,0
	MOV CRD.Y,0
	mov eax, CRD
	INVOKE SetConsoleCursorPosition, consoleOutHandle, EAX

	;INVOKE SetConsoleTextAttribute, consoleOutHandle, FOREGROUND_BLUE + BACKGROUND_GREEN ; задать цветовые атрибуты выводимого текста

	INVOKE PrintStr, offset IN_STR, consoleOutHandle ; Вывод сообщения Введите массив:

	;ЗАПОЛНЯЕМ МАССИВ

	lea EDI, MASS ; берем адресс массива
	sub edi, 4 ; потом прибавим
	xor ebx, ebx ; обнуляем ebx, так как будем использовать его как счетчик
	sub ebx, 1 ; потом прибавим

@spacer:
	xor esi, esi ; обнуляем признак нового числа
	add edi, 4 ; переходим к заполнению следующего элемента
	add ebx, 1 ; сдвигаем ebx на 1
	cmp ebx, 10 ; сравниваем с 10,
	je @exit ; если равно, то на выход

@NewSymb: ; возвращаемся сюда, для чтения нового символа

	INVOKE ReadSymbol, consoleInHandle, consoleOutHandle, 0 ; читаем символ в eax
	cmp eax, 32 ; если это пробел, то
	je @spacer ; пропускаем его

	cmp eax, 45 ; если не поймали '-'
	JNE @standart ; идем как обычно
	mov eax, -1 ; если поймали, то заменяем на единицу на -1
	mov [EDI], eax ; и кладем в массив
	jmp @NewSymb ; смотрим следующий символ

@standart: ; классика
	sub eax, 48 ; так как ввод был ASCII
	cmp esi, 0 ; если это первая цифра числа
	jne @NotOtr ; если нет уходим
	mov ecx, [edi] ; если текущий элемент массива
	cmp ecx, -1 ; равен -1
	jne @NotOtr ; если нет уходим
	mov ecx, [EDI] ; вынимаем этот -1 и 
	imul ecx ; умножаем на считаную цифру
@NotOtr:
	cmp esi, 0 ; смотрим какая это цифра в числе
	je @Not1Symb ; если это первая цифра, то переходим
	mov ecx, [EDI] ; если это не первая цифра, то прошлое число сохраняем
	mov esi, eax ; считанное число тоже сохраняем
	mov eax, 10 ; запомнили 10
	imul ecx ; умножили прошлое число на 10
	cmp eax, 0 ; если текущее число отрицательное
	JNGE @Otrz ; уходим
	add eax, esi ; сложили прошлое x10 со считанным
	jmp @Not1Symb ; продолжаем
@Otrz: ; если текущее число отрицательное
	mov ecx, eax ; запомнили число
	mov eax, -1 ; положили -1
	imul esi ; умножили считанное число на -1
	add eax, ecx ; сложили два отрицательных числа
@Not1Symb:
	mov esi, 1 ; подняли флаг
	mov [EDI], eax ; и положили обратно в массив уже со знаком число
	jmp @NewSymb ; возвращаемся для чтения нового символа

@exit:

	INVOKE PrintStr, offset n, consoleOutHandle ; массив заполнен ставим \n


	;

	    lea edi, mass


        xor ecx, ecx


        mov ebx, [edi]

        start1:
        inc ecx
        cmp ebx, [edi]
        JNL end1
        JNGE new_max

        new_max:
        mov ebx, [edi]
        jmp end1

        end1:
        add edi, 4
        cmp ecx, 10
        je end2
        jmp start1

        end2:
        sub edi, 4
        xor ecx, ecx

        start2:
        inc ecx
		mov esi, [edi]
        cmp esi, 0
        JNGE divis
        jmp end3

        divis:
        xor edx, edx
        mov eax, [edi]
        cdq ;// расширяем делимое (EAX) до EDX:EAX
        idiv ebx
        mov [edi], edx

        end3:
        sub edi, 4
        cmp ecx, 10
        JNE start2

	xor esi, esi ; обнуляем esi (смещение)
@start2: ; возвращаемся сюда пока не выведем весь массив
	lea EDI, MASS ; берем адресс первого
	add edi, esi ; прибавляем смещение
	INVOKE IntToStr, [EDI], offset SymCount ; переводим в стр
	INVOKE PrintStr, offset SymCount, consoleOutHandle ; выводим
	INVOKE PrintStr, offset space, consoleOutHandle ; пробел
	add esi, 4 ; увеличиваем смещение на 4
	cmp esi, 40 ; пока смещение не станет равным 40
	jne @start2 ; будем возвращаться

	INVOKE ReadSymbol, consoleInHandle, consoleOutHandle, 1 ; чтобы не закрывалась консоль
	INVOKE ExitProcess, 0 ; конец веселья
	RET
	START ENDP
END START
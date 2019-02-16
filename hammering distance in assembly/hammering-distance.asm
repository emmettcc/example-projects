	;;  File: hammering-distance.asm
	;;  By Emmett Cummings
	;;
	;;  Outputs the Hamming Distance between
	;;  two strings.
	;;	

	%define STDIN 0			; standard out for read sys call
	%define STDOUT 1		; standard in for write sys call
	%define SYSCALL_EXIT  1	; System call to exit
	%define SYSCALL_READ  3	; system call to read buffer
	%define SYSCALL_WRITE 4	; system call to write
	%define BUFLEN 256		; length of input buffers
	
        SECTION .data		; initialized data section

		msg1:	   db "Enter first string: "	; user prompt
		len1:	   equ $-msg1		; length of first message

		msg2:	   db "Enter second string: "	; user prompt
		len2:	   equ $-msg2		; length of second message
		
		msg3:	   db 10, "Read error", 10 ; error message
		len3:	   equ $-msg3		; length of error message
		
		msg4:      db 'The Hamming Distance is %d',10,0 ;
									; output message to user
		len4:	   equ $-msg4		; length of output message
		
	        SECTION .bss	; uninitialized data section
		buf1:	    resb BUFLEN		; buffer for read
		bufLen1:	resb 4			; Length of buffer
		buf2:	    resb BUFLEN		; buffer for read
		bufLen2:	resb 4			; Length of buffer
		
	        SECTION .text	; Code section.
	        global  main	; let loader see entry point
			extern printf	; import printf c command

	main    :		; Entry point.

	;;  prompt user for first input
	;;
	        mov     eax, SYSCALL_WRITE ; write function
	        mov     ebx, STDOUT	   ; Arg1: file descriptor
	        mov     ecx, msg1	   ; Arg2: addr of message
	        mov     edx, len1	   ; Arg3: length of message
	        int     080h		   ; ask kernel to write
			
			
	;;  read user input
	;;
	        mov     eax, SYSCALL_READ ; read function
	        mov     ebx, STDIN	  ; Arg 1: file descriptor
	        mov     ecx, buf1	  ; Arg 2: address of buffer
	        mov     edx, BUFLEN	  ; Arg 3: buffer length
	        int     080h		  ; ask kernel to read
			
	;;  error check
	;;
			dec		eax			; dec to disregard enter
	        mov     [bufLen1], eax ; save length of string read
	        cmp     eax, 0	    ; check if any chars read
	        je     read_error   ; jump to error message, 
								; if no chars read
	
	;;  prompt user for second input
	;;
	        mov     eax, SYSCALL_WRITE ; write function
	        mov     ebx, STDOUT	   ; Arg1: file descriptor
	        mov     ecx, msg2	   ; Arg2: addr of message
	        mov     edx, len2	   ; Arg3: length of message
	        int     080h		   ; ask kernel to write			
			
	;;  read user input
	;;
	        mov     eax, SYSCALL_READ ; read function
	        mov     ebx, STDIN	  ; Arg 1: file descriptor
	        mov     ecx, buf2	  ; Arg 2: address of buffer
	        mov     edx, BUFLEN	  ; Arg 3: buffer length
	        int     080h		  ; ask kernel to read
			
	;;  error check
	;;
			dec		eax			; dec to disregard enter
	        mov     [bufLen2], eax ; save length of string read
	        cmp     eax, 0	    ; check if any chars read
	        je     read_error   ; jump to error message, 
								; if no chars read

	;;	compare length of strings read, use shorter length
	;;
			mov		eax,	[bufLen2]	; move second string length
			mov		ebx,	[bufLen1]	; move first string length
			cmp		eax,	ebx		;
			jge		L1_init	; jump if bufLen2 >= bufLen1
			mov		[bufLen1],	eax		; set bufLen1 to bufLen2
										; because bufLen2 is shorter
								
L1_init:
        mov     ecx, [bufLen1]   ; initialize count
        mov     esi, buf1        ; point to start of buffer1
        mov     edi, buf2	     ; point to start of buffer1
		mov 	edx, 0			 ; clear edx


L1_top:
        mov     al, [esi] 		; get buf1 character
        mov     ah, [edi] 		; get buf2 character		
		xor 	al, ah			; hamming number in 1 bits
		
L2_init:		
		mov		ebx, 8			; number of bits to loop
L2_top:
		shr 	al,	1			; move a bit into carry
		jnc		L2_cont			; jump if bit 0 aka not 
								; adding to the hamming num
		inc 	edx				; no jump, add 1 to hamming num
L2_cont:
		dec		ebx				; update bite count
		jnz		L2_top			; loop to top if more bits
L2_end:
		
L1_cont:
        inc     esi             ; update buf1 pointer
        inc     edi             ; update buf2 pointer
        dec     ecx             ; update char count
        jnz     L1_top          ; loop to top if more chars
L1_end:
		
	mov eax, edx 		; move hamming num into eax
	push eax			; push eax on the stack
	push dword msg4		; push output message on the stack
	call printf			; call printf
	add esp, byte 8		; remove the parameters from the stack

exit:	   mov     EAX, SYSCALL_EXIT ; exit function
	       int     080h	     ; ask kernel to take over
		   
read_error:

	;;	read error output and exit
	;;
	        mov     eax, SYSCALL_WRITE ; write function
	        mov     ebx, STDOUT	; Arg1: file descriptor
	        mov     ecx, msg3	; Arg2: addr of message
	        mov     edx, len3	; Arg3: length of message
	        int     080h	; ask kernel to take over
	        jmp     exit	; skip to exit function
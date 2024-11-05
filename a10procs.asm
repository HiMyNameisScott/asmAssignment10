; *****************************************************************
;  Name: Scott T.Koss
;  NSHE_ID: 1013095342
;  Section: 1002
;  Assignment: 10
;  Description:  This program gets values from the input stream, checks their validity
;  Then passes the value by reference to be used for drawing a spirography by doing 
;  magic, aka math to provide x and ys to plot onto the screen

; -----
;  Function: getRadii
;	Gets, checks, converts, and returns command line arguments.

;  Function: drawSpiro()
;	Plots spirograph formulas

; ---------------------------------------------------------

;	MACROS (if any) GO HERE

; ---------------------------------------------------------

section  .data

; -----
;  Define standard constants.

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; successful operation
NOSUCCESS	equ	1

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; code for read
SYS_write	equ	1			; code for write
SYS_open	equ	2			; code for file open
SYS_close	equ	3			; code for file close
SYS_fork	equ	57			; code for fork
SYS_exit	equ	60			; code for terminate
SYS_creat	equ	85			; code for file open/create
SYS_time	equ	201			; code for get time

LF		equ	10
SPACE		equ	" "
NULL		equ	0
ESC		equ	27

; -----
;  OpenGL constants

GL_COLOR_BUFFER_BIT	equ	16384
GL_POINTS		equ	0
GL_POLYGON		equ	9
GL_PROJECTION		equ	5889

GLUT_RGB		equ	0
GLUT_SINGLE		equ	0

; -----
;  Define program specific constants.

R1_MIN		equ	0
R1_MAX		equ	250			; 250(10) = 1054(6)

R2_MIN		equ	1			; 1(10) = 1(13)
R2_MAX		equ	250			; 250(10) = 1054(6)

OP_MIN		equ	1			; 1(10) = 1(13)
OP_MAX		equ	250			; 250(10) = 1054(6)

SP_MIN		equ	1			; 1(10) = 1(13)
SP_MAX		equ	100			; 100(10) = 244(6)

X_OFFSET	equ	320
Y_OFFSET	equ	240


; -----
;  Variables for getRadii procedure.

errUsage	db	"Usage:  ./spiro -r1 <senary number> "
		db	"-r2 <senary number> -op <senary number> "
		db	"-sp <senary number> -cl <b/g/r/y/p/w>"
		db	LF, NULL
errBadCL	db	"Error, invalid or incomplete command line arguments."
		db	LF, NULL

errR1sp		db	"Error, radius 1 specifier incorrect."
		db	LF, NULL
errR1value	db	"Error, radius 1 value must be between 0 and 1054(6)."
		db	LF, NULL

errR2sp		db	"Error, radius 2 specifier incorrect."
		db	LF, NULL
errR2value	db	"Error, radius 2 value must be between 1 and 1054(6)."
		db	LF, NULL

errOPsp		db	"Error, offset position specifier incorrect."
		db	LF, NULL
errOPvalue	db	"Error, offset position value must be between 1 and 1054(6)."
		db	LF, NULL

errSPsp		db	"Error, speed specifier incorrect."
		db	LF, NULL
errSPvalue	db	"Error, speed value must be between 1 and 244(6)."
		db	LF, NULL

errCLsp		db	"Error, color specifier incorrect."
		db	LF, NULL
errCLvalue	db	"Error, color value must be b, g, r, p, or w. "
		db	LF, NULL

; -----
;  Variables for spirograph routine.

fltOne		dd	1.0
fltZero		dd	0.0
fltTmp1		dd	0.0
fltTmp2		dd	0.0

t			dd	0.0			; loop variable
s			dd	1.0			; phase variable
tStep		dd	0.005		; t step
sStep		dd	0.0			; s step
x			dd	0			; current x
y			dd	0			; current y

r1			dd	0.0			; radius 1 (float)
r2			dd	0.0			; radius 2 (float)
ofp			dd	0.0			; offset position (float)
radii		dd	0.0			; tmp location for (radius1+radius2)

scale		dd	5000.0		; speed scale
limit		dd	360.0		; for loop limit
iterations	dd	0			; set to 360.0/tStep

red			db	0			; 0-255
green		db	0			; 0-255
blue		db	0			; 0-255

ddSix		dd	6			; used by function for division

; ------------------------------------------------------------

section  .text

; -----
;  External references for openGL routines.

extern	glutInit, glutInitDisplayMode, glutInitWindowSize, glutInitWindowPosition
extern	glutCreateWindow, glutMainLoop
extern	glutDisplayFunc, glutIdleFunc, glutReshapeFunc, glutKeyboardFunc
extern	glutSwapBuffers, gluPerspective, glutPostRedisplay
extern	glClearColor, glClearDepth, glDepthFunc, glEnable, glShadeModel
extern	glClear, glLoadIdentity, glMatrixMode, glViewport
extern	glTranslatef, glRotatef, glBegin, glEnd, glVertex3f, glColor3f
extern	glVertex2f, glVertex2i, glColor3ub, glOrtho, glFlush, glVertex2d

extern	cosf, sinf

; ******************************************************************
;  Function getRadii()
;	Gets radius 1, radius 2, offset positionm and rottaion
;	speedvalues and color code letter from the command line.

;	Performs error checking, converts ASCII/senary string
;	to integer.  Required ommand line format (fixed order):
;	  "-r1 <senary numberl> -r2 <senary number> -op <senary number> 
;			-sp <senary number> -cl <color>"

; HLL
;	stat = getRadii(argc, argv, &radius1, &radius2, &offPos,
;						&speed, &color);

; -----
;  Arguments:
;	1 ARGC - rdi
;	2 ARGV - esi - saved
;	3 radius 1, double-word, address - rdx
;	4 radius 2, double-word, address - rcx -saved
;	5 offset Position, double-word, address -r8 -saved
;	6 speed, double-word, address - r9 -saved
;	7 circle color, byte, address - stack[1]

;	YOUR CODE GOES HERE

global getRadii
getRadii:
	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14
	push r15

	mov r12, rsi ; ARGV
	mov r13, rcx ; Radius 2
	mov r14, r8 ; OffSet
	mov r15, r9 ; Speed

;===================================================================
;==============Check the # ofArgs===================================
;===================================================================

	cmp rdi, 1
	je errUsageMessage

	cmp rdi, 11
	jne errBadCLMessage

;===================================================================
;================Check Color========================================
; This was done to keep everything in 4 preserved registers
;===================================================================

	mov rbx, qword[r12+72]	; Grab value at starting address + 72
	
	mov al, byte[rbx]		; move 1 byte to al
	cmp al, '-'				; cmp al to character
	jne errCLspMessage		; if != go to error handling

	mov al, byte[rbx+1]		; move 1 byte to al
	cmp al, 'c'				; cmp al to char
	jne errCLspMessage		; go to error handling if not equal

	mov al, byte[rbx+2]		; move 1 byte to al
	cmp al, 'l'				; cmp al to char
	jne errCLspMessage		; jmp to error if !=

	mov al, byte[rbx+3]		; check for null
	cmp al, NULL
	jne errCLspMessage
	
	mov rbx, qword[r12+80]	; grab the color value
	mov al, byte[rbx]

	cmp al, 'r'				; checks for rgbpyw, and jumps to set color
	je redSet

	cmp al, 'g'
	je greenSet

	cmp al, 'b'
	je blueSet

	cmp al, 'p'
	je purpleSet

	cmp al, 'y'
	je yellowSet

	cmp al, 'w'
	je whiteSet
	jmp colorFail


	;===============================================================
	; Area to set the Colors =======================================
	;===============================================================

	redSet:
		mov byte[red], 255
		mov byte[green], 0
		mov byte[blue], 0
		jmp colorSuccess

	greenSet:
		mov byte[red], 0
		mov byte[green], 255
		mov byte[blue], 0
		jmp colorSuccess

	blueSet:
		mov byte[red], 0
		mov byte[green], 0
		mov byte[blue], 255
		jmp colorSuccess

	purpleSet:
		mov byte[red], 255
		mov byte[green], 0
		mov byte[blue], 255
		jmp colorSuccess

	yellowSet:
		mov byte[red], 255
		mov byte[green], 255
		mov byte[blue], 0
		jmp colorSuccess

	whiteSet:
		mov byte[red], 255
		mov byte[green], 255
		mov byte[blue], 255
		jmp colorSuccess

	colorFail:
		jmp errCLValueMessage
	colorSuccess:



;===================================================================
;======================= Value Checking Time =======================
;===================================================================

	mov rbx, qword[r12+8]

	mov al, byte[rbx]
	cmp al, '-'
	jne errR1spMessage

	mov al, byte[rbx+1]
	cmp al, 'r'
	jne errR1spMessage

	mov al, byte[rbx+2]
	cmp al, '1'
	jne errR1spMessage

	mov al, byte[rbx+3]
	cmp al, NULL
	jne errR1spMessage

	; Check Value of arg

	mov rdi, qword[r12+16]		; Move the address to rdi
	mov rsi, rdx				; Move return Address stored into rsi
	call senary2int

	cmp eax, R1_MAX				; cmp value to max
	ja errR1ValueMessage

	cmp eax, R1_MIN				; cmp value to min
	jb errR1ValueMessage

;===================================================================
;=======================Value 2 Check===============================
;===================================================================

	mov rbx, qword[r12+24]

	mov al, byte[rbx]
	cmp al, '-'
	jne errR2spMessage

	mov al, byte[rbx+1]
	cmp al, 'r'
	jne errR2spMessage

	mov al, byte[rbx+2]
	cmp al, '2'
	jne errR2spMessage

	mov al, byte[rbx+3]
	cmp al, NULL
	jne errR2spMessage

	; Check Value of Arg

	
	mov rdi, qword[r12+32]
	mov rsi, r13
	call senary2int

	cmp eax, R2_MAX
	ja errR2valueMessage

	cmp eax, R2_MIN
	jb errR2valueMessage

;===================================================================
;=============================Value 3 check=========================
;===================================================================

	mov rbx, qword[r12+40]

	mov al, byte[rbx]
	cmp al, '-'
	jne errOPspMessage

	mov al, byte[rbx+1]
	cmp al, 'o'
	jne errOPspMessage

	mov al, byte[rbx+2]
	cmp al, 'p'
	jne errOPspMessage

	mov al, byte[rbx+3]
	cmp al, NULL
	jne errOPspMessage

	; Value Check

	mov rdi, qword[r12+48]
	mov rsi, r14
	call senary2int

	cmp eax, OP_MAX
	ja errOPvalueMessage

	cmp eax, OP_MIN
	jb errOPvalueMessage

;===================================================================
;=============================Value 4 check=========================
;===================================================================

	mov rbx, qword[r12+56]

	mov al, byte[rbx]
	cmp al, '-'
	jne errSPspMessage

	mov al, byte[rbx+1]
	cmp al, 's'
	jne errSPspMessage

	mov al, byte[rbx+2]
	cmp al, 'p'
	jne errSPspMessage

	mov al, byte[rbx+3]
	cmp al, NULL
	jne errSPspMessage

	mov rdi, qword[r12+64]
	mov rsi, r15
	call senary2int

	cmp eax, SP_MAX
	ja errSPvalueMessage

	cmp eax, SP_MIN
	jb errSPvalueMessage

jmp inputsCorrect
;==============================================================================
;======================= Error Handling =======================================
;==============================================================================

	errUsageMessage:
		mov rdi, errUsage
		jmp printError

	errBadCLMessage:
		mov rdi, errBadCL
		jmp printError

	errR1spMessage:
		mov rdi, errR1sp
		jmp printError

	errR1ValueMessage:
		mov rdi, errR1value
		jmp printError

	errR2spMessage:
		mov rdi, errR2sp
		jmp printError

	errR2valueMessage:
		mov rdi, errR2value
		jmp printError

	errOPspMessage:
		mov rdi, errOPsp
		jmp printError

	errOPvalueMessage:
		mov rdi, errOPvalue
		jmp printError

	errSPspMessage:
		mov rdi, errSPsp
		jmp printError

	errSPvalueMessage:
		mov rdi, errSPvalue
		jmp printError

	errCLspMessage:
		mov rdi, errCLsp
		jmp printError

	errCLValueMessage:
		mov rdi, errCLvalue
		jmp printError

	printError:
		call printString
		mov rax, FALSE

inputsCorrect:

pop r15
pop r14
pop r13
pop r12
pop rbp

ret
; ******************************************************************
;  Spirograph Plotting Function.

; -----
;  Color Code Conversion:
;	'r' -> red=255, green=0, blue=0
;	'g' -> red=0, green=255, blue=0
;	'b' -> red=0, green=0, blue=255
;	'p' -> red=255, green=0, blue=255
;	'y' -> red=255 green=255, blue=0
;	'w' -> red=255, green=255, blue=255
;  Note, set color before plot loop.

; -----
;  The loop is from 0.0 to 360.0 by tStep, can calculate
;  the number if iterations via:  iterations = 360.0 / tStep
;  This eliminates needing a float compare (a hassle).

; -----
;  Basic flow:
;	Set openGL drawing initializations [X]
;	Loop initializations ? What is loop init?
;		Set draw color (i.e., glColor3ub) [x]
;		Convert integer values to float for calculations []
;		set 'sStep' variable []
;		set 'iterations' variable []
;	Plot the following spirograph equations: []
;	     for (t=0.0; t<360.0; t+=step) { []
;	         radii = (r1+r2) []
;	         x = (radii * cos(t)) + (offPos * cos(radii * ((t+s)/r2))) []
				; Order of Ops
				; set radii
				; (t+s)
				; (t+s) / r2
				; call cos(^result 530)
				; mul offPos - Save Value
				; cos(t)
				; ^ * radi
				; add to save value

;	         y = (radii * sin(t)) + (offPos * sin(radii * ((t+s)/r2))) []
;	         t += tStep []
;	         plot point (x, y) []
;	     }
;	Close openGL plotting (i.e., glEnd and glFlush)
;	Update s for next call (s += sStep)
;	Ensure openGL knows to call again (i.e., glutPostRedisplay)

; -----
;  The animation is accomplished by plotting a static
;	image, exiting the routine, and replotting a new
;	slightly different image.  The 's' variable controls
;	the phase or animation.

; -----
;  Global variables accessed
;	There are defined and set in the main, accessed herein by
;	name as per the below declarations.

common	radius1		1:4		; radius 1, dword, integer value
common	radius2		1:4		; radius 2, dword, integer value
common	offPos		1:4		; offset position, dword, integer value
common	speed		1:4		; rortation speed, dword, integer value
common	color		1:1		; color code letter, byte, ASCII value

global drawSpiro
drawSpiro:
	push	r12

; -----
;  Prepare for drawing
	; glClear(GL_COLOR_BUFFER_BIT);
	mov	rdi, GL_COLOR_BUFFER_BIT
	call	glClear

	; glBegin();
	mov	rdi, GL_POINTS
	call	glBegin

; -----
;  Set draw color(r,g,b)
;	Convert color letter to color values
;	Note, only legal color letters should be
;		passed to this procedure
;	Note, color values should be store in local
;		variables red, green, and blue

;	YOUR CODE GOES HERE

	mov dil, byte[red]			; move red into dil
	mov sil, byte[green]		; move green into sil
	mov dl,  byte[blue]			; move byte into dl
	call glColor3ub

	; red/green/blue rax
; -----
;  Loop initializations and main plotting loop

;	YOUR CODE GOES HERE
;	Convert Values to xmm
	cvtsi2ss xmm0, dword[radius1]	; Convert Radius 1 from int to float
	movss dword[r1], xmm0			; Move value into r1

	cvtsi2ss xmm1, dword[radius2]	; Convert Radius 2 from into to float
	movss dword[r2], xmm1			; move value into r2


		; They are converted first, then added is my thought prcoess

	addss xmm0, xmm1				; Add r1(xmm0) + r2(xmm1)
	movss dword[radii], xmm0		; store result into radii

	cvtsi2ss xmm0, dword[offPos]	; convert -> offPOS to float
	movss dword[ofp], xmm0			; Store value into ofp 

	cvtsi2ss xmm0, dword[speed]		; convert  speed to float
	divss xmm0, dword[scale]		; div by scale, is scale
	movss dword[sStep], xmm0


	; Set Iterations
	; Find iterations by dividing 360/0.005
		movss xmm0, dword[limit]	; loop limit in xmm0
		divss xmm0, dword[tStep]	; div limit
		cvtss2si r12, xmm0			; store iterations into r12

		movss xmm0, dword[fltZero]
		movss dword[t], xmm0
	; mov answers into register
	andWeLoopinYaWeLoopin:
	cmp r12, 0
	je plotDone
		; Do the math=======================================================
		;	x = (radii * cos(t)) + (offPos * cos(radii * ((t+s)/r2))) []
			; Order of Ops
			; (t+s)
			movss xmm0, dword[t]		; T
			addss xmm0, dword[s]		; T + S = A
			divss xmm0, dword[r2]		; A / 2 = B
			mulss xmm0, dword[radii]	; B * Raddii = A1
			; call cos(^result 530)
			call cosf					; Cos(A1)
			; mul offPos - Save Value
			mulss xmm0, dword[ofp]		; Cos(A1) * offPos = ans
			movss dword[fltTmp1], xmm0	; Store ans
			; cos(t)
			movss xmm0, dword[t]		; t
			call cosf					; cos(t)
			mulss xmm0, dword[radii]	; mul radii
			addss xmm0, dword[fltTmp1]	; add to fltTmp1
			; asdf
			movss dword[x], xmm0		; store math into x


		;===========================
		;============= X ===========
		;===========================
		;	y = (radii * cos(t)) + (offPos * cos(radii * ((t+s)/r2))) []
			movss xmm0, dword[t]
			addss xmm0, dword[s]
			; (t+s) / r2
			divss xmm0, dword[r2]
			mulss xmm0, dword[radii]
			; call cos(^result 530)
			call sinf
			; mul offPos - Save Value
			mulss xmm0, dword[ofp]
			movss dword[fltTmp2], xmm0
			; cos(t)
			movss xmm0, dword[t]
			call sinf
			mulss xmm0, dword[radii]
			addss xmm0, dword[fltTmp2]
			; ^ * radi
			; add to save value
			movss dword[y], xmm0

		; End the Math=======================================================

		; plot the values for xy, call function

		movss xmm0, dword[x]
		movss xmm1, dword[y]
		call glVertex2f

		; update t-step t = t+tstep
		movss xmm0, dword[t]
		addss xmm0, dword[tStep]
		movss dword[t], xmm0

	; Dec Reg
	dec r12
	jmp andWeLoopinYaWeLoopin
plotDone:
; -----
;  Plotting done.

	call	glEnd
	call	glFlush

; -----
;  Update s for next call.

;	YOUR CODE GOES HERE

	movss xmm0, dword[s]
	addss xmm0, dword[sStep]
	movss dword[s], xmm0

; -----
;  Ensure openGL knows to call again

	call	glutPostRedisplay

pop r12

ret


; ******************************************************************
;  Generic function to display a string to the screen.
;  String must be NULL terminated.

;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

;  Arguments:
;	- address, string
;  Returns:
;	nothing

global	printString
printString:

; -----
;  Count characters in string.

	mov	rbx, rdi			; str addr
	mov	rdx, 0
strCountLoop:
	cmp	byte [rbx], NULL
	je	strCountDone
	inc	rbx
	inc	rdx
	jmp	strCountLoop
strCountDone:

	cmp	rdx, 0
	je	prtDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; EDX=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

prtDone:
	ret

; ******************************************************************


; Function used for converting a number from senary to int
; rdi is the address to the data to process
; rsi is the return address of where to store the processed number

; ******************************************************************
global Senary2int

senary2int:
	mov rax, 0		; used to do our maths in
	mov rbx, rdi	; the address for grabbing data
	mov r8d, 0		; used for adding/storing the value
	mov r9,  0		; used for a counter to grab byte data

	CharacterLoop:

		mov al, byte[rbx+r9]	; Grab value for processing
	
		cmp al, NULL			; cmp to null
		je conversionDone		; if null we are done

		cmp al, '0'				; check if < 0
		jb didntWork			; move to error if < 0

		cmp al, '5'				; check if > 5
		ja didntWork			; move to error if > 5

		sub al, '0'				; sub '0' from al to get the right value
		;mov eax, al				

		inc r9					; move to the next byte
		mov cl, byte[rbx+r9]	; check for a null
		dec r9					; fix r9
		cmp cl, NULL			; cmp cl to null
		je conversionDone		; move to done if cl == null

		add eax, r8d			; add r8d to eax
		mul dword[ddSix]		; mul by 6 to get val
		mov r8d, eax			; mov the value  to r8d
		inc r9					; inc r9 for next value
		jmp CharacterLoop		; jmp to start the loop over again

	didntWork:				
		mov rax, -1				; rax == -1 if failed
		jmp end

	conversionDone:				; return total  
		add eax, r8d
		mov dword[esi], eax

	end:
ret

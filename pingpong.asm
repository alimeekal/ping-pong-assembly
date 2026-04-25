[org 0x0100]
jmp start
welcome: db 'Welcome to Ping Pong!'
made_by: db 'Made by:'
ali: db 'Ali Meekal 23F-0574'
rayyan: db 'Rayyan Asim 23F-0535'
instructions1: db 'Instructions'
instructions2: db 'Left Paddle: w to move up and s to move down'
instructions3: db 'Right Paddle: up arrow to move up and down arrow to down'
escape: db 'ESC to exit'
p_pause: db 'p to pause'
player1: db 'Player 1: '
player2: db 'Player 2: '
paddle_part: db ' '
space: db ' '
oldisr: dd 0
player1wins: db 'Player 1 Wins!'
player2wins: db 'Player 2 Wins!'
exited: db 'Exited...'

choose1: db 'Winning Score'
choose2: db '1. 5 Points'
choose3: db '2. 7 Points'
choose4: db '3. 9 Points'

left_up: dw 1924
left_mid: dw 2084
left_down: dw 2244

right_up: dw 2074
right_mid: dw 2234
right_down: dw 2394

score1: db 0
score2: db 0
score_win: db 0

terminate_flag: db 0

ball_direction: dw -156
reset_ball_direction: dw -156
pause_flag: db 0

	; delay to show ball movement

delay:
push cx       
push dx

mov cx, 0xFF 
delay_loop:
mov dx, 0xFF 
delay_loop2:
dec dx         
jnz delay_loop2
dec cx         
jnz delay_loop

pop dx
pop cx
ret

	; display winning score choice

winning_score:
mov ah, 0x13
mov bh, 0
mov bl, 5
mov dx, 0x0A21
mov cx, 13
push cs
pop es
mov bp, choose1
int 0x10

mov bl, 7
mov dx, 0x0B22
mov cx, 11
mov bp, choose2
int 0x10

mov bl, 15
mov dx, 0x0C22
mov cx, 11
mov bp, choose3
int 0x10

mov bl, 6
mov dx, 0x0D22
mov cx, 11
mov bp, choose4
int 0x10
ret

	; welcome screen

print_messages:
mov ah, 0x13
mov bh, 0
mov bl, 5
mov dx, 0x071E
mov cx, 21
push cs
pop es
mov bp, welcome
int 0x10

mov bl, 11
mov dx, 0x0824
mov cx, 8
mov bp, made_by
int 0x10

mov bl, 6
mov dx, 0x091E
mov cx, 19
mov bp, ali
int 0x10

mov bl, 9
mov dx, 0x0A1E
mov cx, 20
mov bp, rayyan
int 0x10

mov bl, 14
mov dx, 0x0B22
mov cx, 12
mov bp, instructions1
int 0x10

mov bl, 10
mov dx, 0x0C12
mov cx, 44
mov bp, instructions2
int 0x10

mov bl, 15
mov dx, 0x0D0C
mov cx, 56
mov bp, instructions3
int 0x10

mov bl, 4
mov dx, 0x0E22
mov cx, 11
mov bp, escape
int 0x10

mov bl, 12
mov dx, 0x0F22
mov cx, 10
mov bp, p_pause
int 0x10
ret

	; display winner

player_wins:
mov bh, 0
mov bl, 13
mov dx, 0x0C21
mov cx, 14
push cs
pop es
mov al, [score_win]
cmp [score1], al
je player1won
jmp player2won

player1won:
mov al, 0
mov ah, 0x13
mov bp, player1wins
int 0x10
jmp ended

player2won:
mov al, 0
mov ah, 0x13
mov bp, player2wins
int 0x10

ended:
ret

	; display when exited

display_exit:
mov ah, 0x13
mov bh, 0
mov bl, 4
mov dx, 0x0C23
mov cx, 9
push cs
pop es
mov bp, exited
int 0x10
ret

	; ball movement and reflection

ball_movement:
mov ax, 0xb800
mov es, ax
mov di, 2000

move_loop:
mov si, [right_up]
sub si, 162
cmp si, di
je right_reflect
add si, 160

cmp si, di
je right_reflect
add si, 160

cmp si, di
je right_reflect
add si, 160

cmp si, di
je right_reflect
jmp check_left_reflect

right_reflect:
sub word [ball_direction], 8
jmp next2

check_left_reflect:
mov si, [left_up]
cmp si, di
je left_reflect
add si, 160

cmp si, di
je left_reflect
add si, 160

cmp si, di
je left_reflect
add si, 160

cmp si, di
je left_reflect
jmp skip

left_reflect:
add word [ball_direction], 8
jmp next2

skip:
mov ah, 0x02
mov al, 0x6F
mov [es:di], ax

mov al, [pause_flag]
cmp al, 1
je pause_game
jmp go

pause_game:
wait_unpause:
mov al, [pause_flag]
cmp al, 0
je go
jmp wait_unpause

go:
call delay

mov al, [terminate_flag]
cmp al, 1
je terminate_movement
jmp continue

terminate_movement:
ret

continue:
mov ax, di
xor dx, dx
mov cx, 160
div cx
cmp dx, 156
jne check_left

mov ax, 0x0720
mov [es:di], ax
mov di, 2000
mov ax, [reset_ball_direction]
mov [ball_direction], ax
add byte [score1], 1
call prntscore1
mov al, [score_win]
cmp [score1], al
je terminate_movement
jmp next

check_left:
mov ax, di
xor dx, dx
mov cx, 160
div cx
cmp dx, 4
jne check_bounds

mov ax, 0x0720
mov [es:di], ax
mov di, 2000
mov ax, [reset_ball_direction]
mov [ball_direction], ax
add byte [score2], 1
call prntscore2
mov al, [score_win]
cmp [score2], al
je terminate_movement
jmp next

check_bounds:
cmp di, 480
jge bottom_reflection
add word [ball_direction], 320
jmp next

bottom_reflection:
cmp di, 3680
jle next
sub word [ball_direction], 320

next:
mov ax, 0x0720
mov [es:di], ax

next2:
add di, [ball_direction]
jmp move_loop

    ; keyboard interrupt service routine

kbisr: 
push ax
push bx
push cx
push dx
push ds
push es

in al, 0x60
mov bl, al

cmp bl, 0x11
je w_key

cmp bl, 0x1F
je s_key

cmp bl, 0x48
je up_arrow

cmp bl, 0x50
je down_arrow

cmp bl, 0x19
je toggle_pause

cmp bl, 0x01
je terminate_program

done:
pop es
pop ds
pop dx
pop cx
pop bx
pop ax

mov al, 0x20
out 0x20, al
jmp far [cs:oldisr]

w_key:
call move_left_up
jmp done

s_key:
call move_left_down
jmp done

up_arrow:
call move_right_up
jmp done

down_arrow:
call move_right_down
jmp done

toggle_pause:
mov al, [pause_flag]
xor al, 1
mov [pause_flag], al
jmp done

terminate_program:
mov byte [terminate_flag], 1
jmp done

	; clear screen sub-routine

clear:
mov ah, 0x06
mov al, 0
mov bh, 7
mov cx, 0x0000
mov dx, 0x184F
int 0x10
ret

	; hide cursor

cursor_settings:
mov ah, 0x01
mov ch, 0x20
mov cl, 0x20
int 0x10
ret

	; horizontal walls

prntborder_horizontal:
push bp
mov bp, sp

mov ax, 0xb800
mov es, ax
mov bx, [bp + 6]
mov cl, [bp + 4]

mov al, 80
mul cl
add ax, bx
shl ax, 1

mov di, ax
mov ax, 0x0423

l1:
mov [es:di], ax

add di, 2
add bx, 1
cmp bx, 80
jne l1

pop bp
ret 4

	; vertical walls

prntborder_vertical:
push bp
mov bp, sp

mov ax, 0xb800
mov es, ax
mov bx, [bp + 6]
mov cl, [bp + 4]

mov al, 80
mul cl
add ax, bx
shl ax, 1

mov di, ax
mov ax, 0x0423

l2:
mov [es:di], ax

add di, 160
add cx, 1
cmp cx, 24
jne l2

pop bp
ret 4

	; player 1

prntplayer1: 
mov ah, 0x13
mov bh, 0
mov bl, 7
mov dx, 0x0000
mov cx, 10
push cs
pop es
mov bp, player1
int 0x10
ret

	; player 1 score

prntscore1:
push di
push ax
push es

mov ax, 0xb800
mov es, ax
mov di, 20
mov ah, 0x07
mov al, 0x30
add al, [score1]
mov word [es:di], ax

pop es
pop ax
pop di
ret

	; player 2

prntplayer2: 
mov ah, 0x13
mov bh, 0
mov bl, 7
mov dx, 0x0045
mov cx, 10
push cs
pop es
mov bp, player2
int 0x10
ret

	; player 2 score

prntscore2:
push di
push ax
push es

mov ax, 0xb800
mov es, ax
mov di, 158
mov ah, 0x07
mov al, 0x30
add al, [score2]
mov word [es:di], ax

pop es
pop ax
pop di
ret

	; left paddle

print_paddle_left:
push ax
push es
push di

mov ax, 0xb800
mov es, ax
mov ax, 0x7723
mov di, [left_up]
mov [es:di], ax

mov di, [left_mid]
mov [es:di], ax

mov di, [left_down]
mov [es:di], ax

pop di
pop es
pop ax
ret

	; left paddle up

move_left_up:
push es
push ax
push di

mov ax, [left_up]
cmp ax, 324
je top_reached1
sub ax, 160
mov [left_up], ax

mov ax, [left_mid]
sub ax, 160
mov [left_mid], ax

mov ax, 0xb800
mov es, ax
mov ax, 0x0023
mov di, [left_down]
mov [es:di], ax

sub di, 160
mov [left_down], di

call print_paddle_left

top_reached1:
pop di
pop ax
pop es
ret

	; left paddle down

move_left_down:
push es
push ax
push di

mov ax, [left_down]
cmp ax, 3684
je bottom_reached1
add ax, 160
mov [left_down], ax

mov ax, [left_mid]
add ax, 160
mov [left_mid], ax

mov ax, 0xb800
mov es, ax
mov ax, 0x0023
mov di, [left_up]
mov [es:di], ax

add di, 160
mov [left_up], di

call print_paddle_left

bottom_reached1:
pop di
pop ax
pop es
ret

	; right paddle

print_paddle_right:
push ax
push es
push di

mov ax, 0xb800
mov es, ax
mov ax, 0x7723
mov di, [right_up]
mov [es:di], ax

mov di, [right_mid]
mov [es:di], ax

mov di, [right_down]
mov [es:di], ax

pop di
pop es
pop ax
ret

	; right paddle up

move_right_up:
push es
push ax
push di

mov ax, [right_up]
cmp ax, 474
je top_reached2
sub ax, 160
mov [right_up], ax

mov ax, [right_mid]
sub ax, 160
mov [right_mid], ax

mov ax, 0xb800
mov es, ax
mov ax, 0x0023
mov di, [right_down]
mov [es:di], ax

sub di, 160
mov [right_down], di

call print_paddle_right

top_reached2:
pop di
pop ax
pop es
ret

	; right paddle down

move_right_down:
push es
push ax
push di

mov ax, [right_down]
cmp ax, 3834
je bottom_reached2
add ax, 160
mov [right_down], ax

mov ax, [right_mid]
add ax, 160
mov [right_mid], ax

mov ax, 0xb800
mov es, ax
mov ax, 0x0023
mov di, [right_up]
mov [es:di], ax

add di, 160
mov [right_up], di

call print_paddle_right

bottom_reached2:
pop di
pop ax
pop es
ret

	; restore original ISR

restore_isr:
cli
mov ax, 0
mov es, ax
mov ax, [oldisr]
mov [es:9*4], ax 
mov ax, [oldisr+2]
mov [es:9*4+2], ax
sti
ret

	; main

start:
call clear
call cursor_settings
call winning_score

choose:
mov ah, 0
int 0x16

cmp al, 0x31
je first

cmp al, 0x32
je second

cmp al, 0x33
je third
jmp choose

first:
mov byte [score_win], 5
jmp going

second:
mov byte [score_win], 7
jmp going

third:
mov byte [score_win], 9

going:
call clear
call print_messages

mov ah, 0
int 0x16
call clear

call print_paddle_left
call print_paddle_right

call prntplayer1
call prntplayer2
call prntscore1
call prntscore2

mov ax, 0
push ax
mov ax, 1
push ax
call prntborder_horizontal

mov ax, 0
push ax
mov ax, 24
push ax
call prntborder_horizontal

mov ax, 79
push ax
mov ax, 1
push ax
call prntborder_vertical

mov ax, 0
push ax
mov ax, 1
push ax
call prntborder_vertical

xor ax, ax
mov es, ax
mov ax, [es:9*4]
mov [oldisr], ax
mov ax, [es:9*4+2]
mov [oldisr+2], ax
cli
mov word [es:9*4], kbisr
mov [es:9*4+2], cs
sti

call ball_movement

exit_program:
call restore_isr
call clear
cmp byte [terminate_flag], 1
je skip_win
call player_wins
jmp finish

skip_win:
call display_exit

finish:
mov ax, 0x4c00
int 0x21
; FILE: video.asm | Module 2: Video Mode & Drawing

; ------------------------------------------------------------
; Name     : SetVideoMode
; Purpose  : switches the screen to VGA graphics mode 13h
;            (320 pixels wide x 200 pixels tall, 256 colours)
; Inputs   : none
; Outputs  : screen changes to graphics mode
; Changes  : none (AX is saved and restored)
; ------------------------------------------------------------
SetVideoMode:
    push ax                     ; save old AX on the stack
    mov ax, 0013h               ; BIOS function 00h, mode 13h = 320x200 graphics
    int 10h                     ; call BIOS to switch the screen mode
    pop ax                      ; put old AX back
    ret                         ; go back to caller

; ------------------------------------------------------------
; Name     : SetTextMode
; Purpose  : switches the screen back to normal DOS text mode
;            before quitting the program
; Inputs   : none
; Outputs  : screen returns to 80x25 text mode
; Changes  : none (AX is saved and restored)
; ------------------------------------------------------------
SetTextMode:
    push ax                     ; save old AX on the stack
    mov ax, 0003h               ; BIOS function 00h, mode 03h = normal text screen
    int 10h                     ; call BIOS to switch back to text
    pop ax                      ; put old AX back
    ret                         ; go back to caller

; ------------------------------------------------------------
; Name     : PutPixel
; Purpose  : draws one coloured dot at (x, y) on the screen
; Inputs   : pushed on the stack before calling:
;              [bp+8] = x position (0 to 319)
;              [bp+6] = y position (0 to 199)
;              [bp+4] = colour number (0 to 255)
; Outputs  : writes 1 byte into video memory at 0A000h
; Changes  : none (all used registers are saved and restored)
; ------------------------------------------------------------
PutPixel:
    push bp                     ; save caller's base pointer
    mov bp, sp                  ; point BP to stack so we can read our inputs
    push ax                     ; save AX
    push bx                     ; save BX
    push di                     ; save DI (will hold the memory offset)
    push es                     ; save ES (will point to video memory)

    ; step 1: check that x is on the screen (0 to 319)
    mov bx, [bp+8]              ; load x from stack into BX
    cmp bx, SCREEN_W            ; compare x with 320
    jae .skip                   ; if x >= 320 (or negative), skip so we don't write off-screen

    ; step 2: check that y is on the screen (0 to 199)
    mov ax, [bp+6]              ; load y from stack into AX
    cmp ax, SCREEN_H            ; compare y with 200
    jae .skip                   ; if y >= 200 (or negative), skip

    ; step 3: find memory offset DI = (y * 320) + x using shifts
    ; 320 = 256 + 64, so (y * 320) = (y shifted left 8) + (y shifted left 6)
    mov di, ax                  ; copy y into DI
    shl ax, 8                   ; AX = y * 256
    shl di, 6                   ; DI = y * 64
    add di, ax                  ; DI = (y * 256) + (y * 64) = y * 320
    add di, bx                  ; DI = (y * 320) + x (exact byte location on screen)

    ; step 4: put the colour byte into video memory
    mov ax, VIDEO_SEG           ; load 0A000h into AX
    mov es, ax                  ; point ES to the screen segment
    mov al, [bp+4]              ; load the colour byte from stack into AL
    mov [es:di], al             ; draw the pixel onto the screen

.skip:
    pop es                      ; restore ES
    pop di                      ; restore DI
    pop bx                      ; restore BX
    pop ax                      ; restore AX
    pop bp                      ; restore BP
    ret 6                       ; return and clean up 3 word inputs (3 x 2 = 6 bytes)

; ------------------------------------------------------------
; Name     : FillRect
; Purpose  : draws a solid filled box of size w x h at (x, y)
; Inputs   : pushed on the stack before calling:
;              [bp+12] = left x position
;              [bp+10] = top y position
;              [bp+8]  = width w in pixels
;              [bp+6]  = height h in pixels
;              [bp+4]  = colour number (0 to 255)
; Outputs  : draws w * h pixels on the screen
; Changes  : none (all used registers are saved and restored)
; ------------------------------------------------------------
FillRect:
    push bp                     ; save caller's base pointer
    mov bp, sp                  ; point BP to stack to read inputs
    push ax                     ; save AX
    push bx                     ; save BX (tracks current x)
    push cx                     ; save CX (loop counter)
    push dx                     ; save DX (tracks current y)

    mov cx, [bp+6]              ; load height h into CX
    cmp cx, 0                   ; check if height is 0 or less
    jle .done                   ; if nothing to draw, jump to end

    mov dx, [bp+10]             ; load starting top y into DX

.row_loop:
    push cx                     ; save outer row counter on stack

    mov cx, [bp+8]              ; load width w into CX
    cmp cx, 0                   ; check if width is 0 or less
    jle .next_row               ; if 0 wide, skip this row

    mov bx, [bp+12]             ; reset BX back to left x for this new row

.col_loop:
    push bx                     ; input 1: current x
    push dx                     ; input 2: current y
    mov ax, [bp+4]              ; get colour from stack
    push ax                     ; input 3: colour
    call PutPixel               ; draw this single pixel

    inc bx                      ; move 1 pixel right (x = x + 1)
    loop .col_loop              ; subtract 1 from CX and repeat until row is done

.next_row:
    inc dx                      ; move 1 row down (y = y + 1)
    pop cx                      ; get outer row counter back
    loop .row_loop              ; subtract 1 from CX and repeat until all rows are done

.done:
    pop dx                      ; restore DX
    pop cx                      ; restore CX
    pop bx                      ; restore BX
    pop ax                      ; restore AX
    pop bp                      ; restore BP
    ret 10                      ; return and clean up 5 word inputs (5 x 2 = 10 bytes)
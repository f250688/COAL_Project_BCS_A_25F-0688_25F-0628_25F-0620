; FILE: level.asm | Module 3: Level Map Data & Tile Renderer

; =============================================================================
; LEVEL MAP BUFFERS (60 columns x 12 rows = 720 bytes each)
; =============================================================================
; map_original holds the clean starting level; map_working is copied from it
; at the start of every game/life so broken bricks and '?' blocks reset cleanly.

map_original:
    ; Row 0: HUD strip row (y = 0..15)
    times 60 db TILE_SKY
    ; Row 1: Sky (y = 16..31)
    times 60 db TILE_SKY
    ; Row 2: High platforms & flagpole top (y = 32..47)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,0
    ; Row 3: Upper floating bricks / coins & flagpole shaft (y = 48..63)
    db 0,0,0,0,0,0,0,0,0,0,0,0,11,11,11,0,0,0,0,0
    db 0,0,0,0,0,0,2,2,3,2,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,0
    ; Row 4: Flagpole shaft (y = 64..79)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,12,0,0,0,0
    ; Row 5: Stair top & flagpole shaft (y = 80..95)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,10,0,0,12,0,0,0,0
    ; Row 6: '?' blocks, bricks, floating coins, stairs, flagpole (y = 96..111)
    db 0,0,0,0,0,0,3,0,0,2,4,2,3,2,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,11,11,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,10,10,0,0,12,0,0,0,0
    ; Row 7: Tall pipe top (cols 22-23), stairs, flagpole (y = 112..127)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,6,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,10,10,10,0,0,12,0,0,0,0
    ; Row 8: Short pipe top (cols 16-17), tall pipe body, stairs, flagpole (y = 128..143)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,7,0,0
    db 0,0,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,6,7
    db 0,0,0,0,0,0,0,0,0,10,10,10,10,0,0,12,0,0,0,0
    ; Row 9: Pipe bases, stairs, flagpole base (y = 144..159)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9,0,0
    db 0,0,8,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,9
    db 0,0,0,0,0,0,0,0,10,10,10,10,10,0,0,10,0,0,0,0
    ; Row 10: Ground top layer with 2 pits at cols 26-27 and 44-45 (y = 160..175)
    times 26 db TILE_GROUND
    db TILE_SKY, TILE_SKY
    times 16 db TILE_GROUND
    db TILE_SKY, TILE_SKY
    times 14 db TILE_GROUND
    ; Row 11: Ground bottom layer matching the 2 pits (y = 176..191)
    times 26 db TILE_GROUND
    db TILE_SKY, TILE_SKY
    times 16 db TILE_GROUND
    db TILE_SKY, TILE_SKY
    times 14 db TILE_GROUND

map_working:
    times MAP_COLS * MAP_ROWS db 0

; ------------------------------------------------------------
; Name     : ResetMap
; Purpose  : copies the 720-byte map_original into map_working
; Inputs   : none
; Outputs  : map_working is restored to initial level state
; Changes  : none (AX, CX, SI, DI, ES are saved and restored)
; ------------------------------------------------------------
ResetMap:
    push ax
    push cx
    push si
    push di
    push es

    push ds
    pop es                      ; ES = DS for rep movsb
    mov si, map_original        ; source = clean template
    mov di, map_working         ; destination = active working map
    mov cx, MAP_COLS * MAP_ROWS ; 720 bytes
    cld
    rep movsb

    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret

; ------------------------------------------------------------
; Name     : GetTileAt
; Purpose  : returns the Tile ID from map_working at world pixel (x, y)
; Inputs   : AX = world X (pixels, 0..959), BX = world Y (pixels, 0..191)
; Outputs  : AL = Tile ID (0..12), AH = 0
; Changes  : AX (all other registers saved and restored)
; ------------------------------------------------------------

;it is getting the tile e.g if mario collected a coin it will-
; -give the id of that tile where the coin was
GetTileAt:
    push bx
    push cx
    push si

    cmp bx, 0                   ; above screen?
    jl .empty
    cmp bx, VISIBLE_H           ; below row 11 (y >= 192, pit)?
    jge .empty
    cmp ax, 0                   ; left of level?
    jl .empty
    cmp ax, LEVEL_W_PX          ; past right edge (x >= 960)?
    jge .empty

    ; col = AX >> 4, row = BX >> 4
    mov cx, ax
    shr cx, 4                   ; CX = col (0..59)
    shr bx, 4                   ; BX = row (0..11)

    ; index = row * 60 + col = (row * 64) - (row * 4) + col
    mov si, bx
    shl si, 6                   ; row * 64
    shl bx, 2                   ; row * 4
    sub si, bx                  ; row * 60
    add si, cx                  ; + col

    mov al, [map_working + si]
    xor ah, ah
    jmp .done

.empty:
    mov ax, TILE_SKY

.done:
    pop si
    pop cx
    pop bx
    ret

; ------------------------------------------------------------
; Name     : SetTileAt
; Purpose  : sets a tile in map_working at grid coordinates (col, row)
; Inputs   : CX = col (0..59), BX = row (0..11), AL = new Tile ID
; Outputs  : updates map_working[row * 60 + col]
; Changes  : none (all registers saved and restored)
; ------------------------------------------------------------

;it sets the tile to the new state e.g it will then turn that tile where the -
;coin was and which was then collected by Mario into 0 like that tile will disappear -
;as that coin was collected
SetTileAt:
    push bx
    push si

    cmp cx, MAP_COLS
    jae .skip
    cmp bx, MAP_ROWS
    jae .skip

    mov si, bx
    shl si, 6                   ; row * 64
    shl bx, 2                   ; row * 4
    sub si, bx                  ; row * 60
    add si, cx
    mov [map_working + si], al

.skip:
    pop si
    pop bx
    ret

; ------------------------------------------------------------
; Name     : IsSolidTile
; Purpose  : checks whether a Tile ID blocks Mario and enemies
; Inputs   : AL = Tile ID (0..12)
; Outputs  : Carry Flag (CF) = 1 if solid (1..10), CF = 0 if passable (0, 11, 12)
; Changes  : Flags only (all registers preserved)
; ------------------------------------------------------------

;you cannot pass when tile id's are between 1 to 10
IsSolidTile:
    cmp al, TILE_GROUND         ; 1 = first solid tile 
    jb .passable                ; if below 1 then you can pass
    cmp al, TILE_STAIR          ; 10 = last solid tile (1..10 are solid)
    ja .passable                ; if above 10 then you ca still pass
    stc                         ; CF = 1 (solid)
    ret
.passable:
    clc                         ; CF = 0 (passable)
    ret

; ------------------------------------------------------------
; Name     : DrawBox
; Purpose  : helper to call stack-based FillRect using registers
; Inputs   : BX = x, DX = y, CX = width, SI = height, AL = colour
; Outputs  : draws filled rectangle via FillRect
; Changes  : none (all registers saved and restored)
; ------------------------------------------------------------
DrawBox:
    push ax
    xor ah, ah
    push bx                     ; [bp+12] = x
    push dx                     ; [bp+10] = y
    push cx                     ; [bp+8]  = width
    push si                     ; [bp+6]  = height
    push ax                     ; [bp+4]  = colour
    call FillRect
    pop ax
    ret

; Jump table mapping Tile ID (0..12) to its drawing handler
tile_draw_table:
    dw DrawTile.t_sky           ; 0  = TILE_SKY
    dw DrawTile.t_ground        ; 1  = TILE_GROUND
    dw DrawTile.t_brick         ; 2  = TILE_BRICK
    dw DrawTile.t_qblock        ; 3  = TILE_QCOIN
    dw DrawTile.t_qblock        ; 4  = TILE_QMUSH
    dw DrawTile.t_empty         ; 5  = TILE_EMPTY
    dw DrawTile.t_pipe_tl       ; 6  = TILE_PIPE_TL
    dw DrawTile.t_pipe_tr       ; 7  = TILE_PIPE_TR
    dw DrawTile.t_pipe_bl       ; 8  = TILE_PIPE_BL
    dw DrawTile.t_pipe_br       ; 9  = TILE_PIPE_BR
    dw DrawTile.t_stair         ; 10 = TILE_STAIR
    dw DrawTile.t_coin          ; 11 = TILE_COIN
    dw DrawTile.t_flag          ; 12 = TILE_FLAG

; ------------------------------------------------------------
; Name     : DrawTile
; Purpose  : draws one 16x16 detailed tile at screen coordinates (BX, DX)
; Inputs   : AL = Tile ID (0..12), BX = screen X, DX = screen Y
; Outputs  : draws 16x16 tile onto VGA screen
; Changes  : none (all registers saved and restored)
; ------------------------------------------------------------
DrawTile:
    push ax
    push bx
    push cx
    push dx
    push si

    cmp bx, -16
    jle near .dt_done
    cmp bx, SCREEN_W
    jge near .dt_done

    xor ah, ah
    cmp ax, TILE_FLAG
    ja near .t_sky

    mov si, ax
    shl si, 1                   ; word index = Tile ID * 2
    jmp [tile_draw_table + si]

.t_sky:
    mov cx, 16
    mov si, 16
    mov al, COL_SKY
    call DrawBox
    jmp .dt_done

; --- TILE 1: GROUND (grass top + brown dirt + dark specks) ---
.t_ground:
    mov cx, 16
    mov si, 16
    mov al, COL_GROUND
    call DrawBox
    mov cx, 16
    mov si, 4
    mov al, COL_PIPE            ; green grass layer
    call DrawBox
    mov cx, 16
    mov si, 1
    mov al, 10                  ; light green grass top edge
    call DrawBox
    add bx, 3
    add dx, 7
    mov cx, 2
    mov si, 2
    mov al, 0                   ; dark soil pebble
    call DrawBox
    add bx, 8
    add dx, 4
    call DrawBox
    jmp .dt_done

; --- TILE 2: BRICK (red/terracotta with black mortar lines) ---
.t_brick:
    mov cx, 16
    mov si, 16
    mov al, COL_BRICK
    call DrawBox
    mov cx, 16
    mov si, 1
    mov al, COL_HERO            ; bright top brick highlight
    call DrawBox
    add dx, 7
    mov cx, 16
    mov si, 1
    mov al, 0                   ; horizontal mortar line
    call DrawBox
    add dx, 8
    call DrawBox
    sub dx, 15
    add bx, 7
    mov cx, 1
    mov si, 7
    call DrawBox                ; upper vertical mortar
    sub bx, 7
    add dx, 8
    call DrawBox                ; lower-left vertical mortar
    add bx, 15
    call DrawBox                ; lower-right vertical mortar
    jmp .dt_done

; --- TILES 3 & 4: '?' BLOCK (yellow block with '?' symbol) ---
.t_qblock:
    mov cx, 16
    mov si, 16
    mov al, 14                  ; bright yellow
    call DrawBox
    mov cx, 15
    mov si, 1
    mov al, COL_TEXT            ; white top/left highlight
    call DrawBox
    mov cx, 1
    mov si, 15
    call DrawBox
    ; '?' glyph in brown (COL_GROUND)
    add bx, 6
    add dx, 3
    mov cx, 4
    mov si, 2
    mov al, COL_GROUND
    call DrawBox
    add bx, 3
    add dx, 2
    mov cx, 2
    mov si, 3
    call DrawBox
    sub bx, 2
    add dx, 3
    mov cx, 3
    mov si, 2
    call DrawBox
    add dx, 3
    mov cx, 2
    mov si, 2
    call DrawBox
    jmp .dt_done

; --- TILE 5: USED '?' BLOCK ---
.t_empty:
    mov cx, 16
    mov si, 16
    mov al, 8                   ; dark grey frame
    call DrawBox
    add bx, 1
    add dx, 1
    mov cx, 14
    mov si, 14
    mov al, COL_GROUND
    call DrawBox
    jmp .dt_done

; --- TILE 6: PIPE TOP-LEFT LIP ---
.t_pipe_tl:
    mov cx, 16
    mov si, 16
    mov al, COL_PIPE
    call DrawBox
    mov cx, 1
    mov si, 16
    mov al, 0
    call DrawBox
    mov cx, 16
    mov si, 1
    call DrawBox
    add dx, 15
    call DrawBox
    sub dx, 15
    add bx, 3
    mov cx, 3
    mov si, 16
    mov al, 10                  ; bright green highlight
    call DrawBox
    jmp .dt_done

; --- TILE 7: PIPE TOP-RIGHT LIP ---
.t_pipe_tr:
    mov cx, 16
    mov si, 16
    mov al, COL_PIPE
    call DrawBox
    mov cx, 16
    mov si, 1
    mov al, 0
    call DrawBox
    add dx, 15
    call DrawBox
    sub dx, 15
    add bx, 15
    mov cx, 1
    mov si, 16
    call DrawBox
    jmp .dt_done

; --- TILE 8: PIPE BODY-LEFT ---
.t_pipe_bl:
    mov cx, 16
    mov si, 16
    mov al, COL_SKY
    call DrawBox
    add bx, 2
    mov cx, 14
    mov si, 16
    mov al, COL_PIPE
    call DrawBox
    mov cx, 1
    mov al, 0
    call DrawBox
    add bx, 2
    mov cx, 3
    mov al, 10
    call DrawBox
    jmp .dt_done

; --- TILE 9: PIPE BODY-RIGHT ---
.t_pipe_br:
    mov cx, 16
    mov si, 16
    mov al, COL_SKY
    call DrawBox
    mov cx, 14
    mov si, 16
    mov al, COL_PIPE
    call DrawBox
    add bx, 13
    mov cx, 1
    mov al, 0
    call DrawBox
    jmp .dt_done

; --- TILE 10: STAIR / HARD BLOCK ---
.t_stair:
    mov cx, 16
    mov si, 16
    mov al, 7                   ; light grey
    call DrawBox
    add bx, 2
    add dx, 2
    mov cx, 12
    mov si, 12
    mov al, 8                   ; dark grey inner bevel
    call DrawBox
    add bx, 1
    add dx, 1
    mov cx, 10
    mov si, 10
    mov al, 7
    call DrawBox
    jmp .dt_done

; --- TILE 11: COLLECTIBLE COIN ---
.t_coin:
    mov cx, 16
    mov si, 16
    mov al, COL_SKY
    call DrawBox
    add bx, 5
    add dx, 3
    mov cx, 6
    mov si, 10
    mov al, 14                  ; yellow coin oval
    call DrawBox
    add bx, 2
    add dx, 2
    mov cx, 2
    mov si, 6
    mov al, COL_GROUND          ; inner coin shine slot
    call DrawBox
    jmp .dt_done

; --- TILE 12: GOAL FLAGPOLE ---
.t_flag:
    mov cx, 16
    mov si, 16
    mov al, COL_SKY
    call DrawBox
    add bx, 7
    mov cx, 2
    mov si, 16
    mov al, COL_TEXT            ; white pole
    call DrawBox

.dt_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ------------------------------------------------------------
; Name     : RenderLevel
; Purpose  : draws visible map rows 1..11 (21x11 tiles) at camera_x
; Inputs   : [camera_x] = horizontal camera offset (0..640)
; Outputs  : draws level tiles and bottom border on VGA screen
; Changes  : none (all registers saved and restored)
; ------------------------------------------------------------
RenderLevel:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Fill bottom 8-pixel border strip (y = 192..199)
    xor bx, bx
    mov dx, VISIBLE_H           ; y = 192
    mov cx, SCREEN_W
    mov si, 8
    mov al, 0
    call DrawBox

    ; Calculate starting column and sub-tile horizontal offset
    mov ax, [camera_x]
    mov cx, ax
    shr cx, 4                   ; CX = start_col = camera_x / 16
    and ax, 0Fh                 ; AX = fine scroll (0..15)
    neg ax                      ; AX = initial screen_x (-15..0)
    mov [rl_start_x], ax
    mov [rl_start_col], cx

    ; Loop rows 1..11 (row 0 is reserved for HUD_HEIGHT = 16)
    mov di, 1
.row_loop:
    cmp di, MAP_ROWS
    jge .rl_done

    ; offset = row * 60 + start_col = (row * 64) - (row * 4) + start_col
    mov si, di
    shl si, 6                   ; row * 64
    mov ax, di
    shl ax, 2                   ; row * 4
    sub si, ax                  ; row * 60
    add si, [rl_start_col]

    mov dx, di
    shl dx, 4                   ; screen_y = row * 16

    mov bx, [rl_start_x]        ; screen_x
    mov cx, VISIBLE_COLS + 1    ; 21 columns for smooth scrolling

.col_loop:
    mov al, [map_working + si]
    call DrawTile

    inc si
    add bx, TILE_SIZE
    loop .col_loop

    inc di
    jmp .row_loop

.rl_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

rl_start_x      dw 0
rl_start_col    dw 0
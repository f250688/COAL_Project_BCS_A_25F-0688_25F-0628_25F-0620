ORG 100h
jmp start                       ; skip the data below, start running at "start"
; ============================================================
; ===== CONSTANTS =====
; A constant is just a name for a number. It takes NO memory,
; NASM swaps the name for the number while assembling.
; ============================================================

; ---- screen and level ----
VIDEO_SEG       EQU 0A000h      ; the screen lives here in memory (VGA mode 13h)
SCREEN_W        EQU 320         ; screen is 320 pixels wide
SCREEN_H        EQU 200         ; screen is 200 pixels tall
TILE_SIZE       EQU 16          ; every tile and sprite is 16 x 16 pixels
HUD_HEIGHT      EQU 16          ; top 16 pixels show score, coins, time (map row 0)
VISIBLE_H       EQU 192         ; game area height = 12 rows x 16 pixels
VISIBLE_COLS    EQU 20          ; 20 tiles fit across the screen (20 x 16 = 320)
MAP_COLS        EQU 60          ; the whole level is 60 tiles wide
MAP_ROWS        EQU 12          ; and 12 tiles tall
LEVEL_W_PX      EQU 960         ; level width in pixels (60 x 16)
CAMERA_MAX      EQU 640         ; camera can't go further than this (960 - 320)
CAMERA_FOLLOW_X EQU 160         ; once Mario is past screen x 160, the camera follows
START_X         EQU 32          ; Mario begins at x = 32 in the level
START_Y         EQU 10*TILE_SIZE ; Mario's feet start at y = 160 (top of ground row 10)
PIT_Y           EQU 192         ; if Mario's feet reach y = 192 he fell in a pit
LEFT_BEHIND     EQU 32          ; enemy 32 pixels left of the screen gets removed
ACTIVATE_DIST   EQU 16          ; enemy starts walking 1 tile before it enters the screen

; ---- sprite sizes ----
SMALL_H         EQU 16          ; small Mario is 16 pixels tall
SUPER_H         EQU 32          ; super Mario is 32 pixels tall
HIT_W           EQU 12          ; hitbox is 12 wide (sprite is 16) so hits feel fair

; ---- tile codes: each number in the map means one kind of tile ----
TILE_SKY        EQU 0           ; empty sky, you walk through it
TILE_GROUND     EQU 1           ; ground, solid
TILE_BRICK      EQU 2           ; brick, solid
TILE_QCOIN      EQU 3           ; ? block that gives a coin
TILE_QMUSH      EQU 4           ; ? block that gives a mushroom
TILE_EMPTY      EQU 5           ; ? block after it was hit (used up)
TILE_PIPE_TL    EQU 6           ; pipe top-left part
TILE_PIPE_TR    EQU 7           ; pipe top-right part
TILE_PIPE_BL    EQU 8           ; pipe body-left part
TILE_PIPE_BR    EQU 9           ; pipe body-right part
TILE_STAIR      EQU 10          ; stair block, solid
TILE_COIN       EQU 11          ; coin lying in the level, you pick it up by touching
TILE_FLAG       EQU 12          ; flag pole, touching it wins the level

; ---- colours: numbers from the default VGA palette ----
; 0 is never used here because 0 means "transparent" in sprites
COL_SKY         EQU 9           ; light blue
COL_GROUND      EQU 6           ; brown
COL_BRICK       EQU 4           ; red
COL_PIPE        EQU 2           ; green
COL_HERO        EQU 12          ; light red (Mario)
COL_ENEMY       EQU 5           ; magenta (enemies)
COL_TEXT        EQU 15          ; white (letters and digits)
COL_HUD         EQU 1           ; blue (strip at the top)

; ---- keyboard scan codes: the number the keyboard sends for each key ----
SC_ESC          EQU 01h         ; Esc = go back / exit
SC_ENTER        EQU 1Ch         ; Enter = choose in menu, continue
SC_P            EQU 19h         ; P = pause / resume
SC_LSHIFT       EQU 2Ah         ; Left Shift = run
SC_SPACE        EQU 39h         ; Space = jump
SC_UP           EQU 48h         ; Up arrow = move menu up
SC_DOWN         EQU 50h         ; Down arrow = move menu down
SC_LEFT         EQU 4Bh         ; Left arrow = walk left
SC_RIGHT        EQU 4Dh         ; Right arrow = walk right

; ---- physics ----
; 8.8 fixed point: the high byte is the whole part, the low byte is the
; fraction. So 0100h = 1.0 and 0080h = 0.5. Speeds are pixels per frame.
WALK_ACCEL      EQU 0020h       ; each frame a key is held, speed grows by 0.125
FRICTION        EQU 0010h       ; each frame with no key, speed shrinks by 0.0625
MAX_WALK        EQU 0180h       ; fastest walking speed = 1.5 pixels/frame
MAX_RUN         EQU 0280h       ; fastest running speed (Shift) = 2.5 pixels/frame
GRAVITY         EQU 0040h       ; every frame we add 0.25 to the downward speed
JUMP_START      EQU 0FA80h      ; speed at the start of a jump = -5.5 (negative = up)
JUMP_CUTOFF     EQU 0FE00h      ; if Space is let go early, upward speed is cut to -2.0
MAX_FALL        EQU 0400h       ; falling can't get faster than 4.0 pixels/frame
STOMP_BOUNCE    EQU 0FD00h      ; bounce after jumping on an enemy = -3.0 (up)
GOOMBA_SPEED    EQU 0080h       ; Goomba walks 0.5 pixel per frame (slow)
KOOPA_SPEED     EQU 00C0h       ; Koopa walks 0.75 pixel per frame (a bit faster)
SHELL_SPEED     EQU 0300h       ; sliding shell moves 3 pixels per frame (fast)
MUSHROOM_SPEED  EQU 0100h       ; mushroom moves 1 pixel per frame

; ---- game limits ----
START_LIVES     EQU 3           ; you start a new game with 3 lives
MAX_LIVES       EQU 99          ; lives never go above 99
LEVEL_TIME      EQU 300         ; the clock starts at 300 seconds
COINS_FOR_LIFE  EQU 100         ; every 100 coins gives 1 extra life
MAX_HP          EQU 2           ; health: Small Mario = 1, Super Mario = 2
MAX_ENEMIES     EQU 8           ; at most 8 enemies are active at once
MAX_SCORE_HI    EQU 000Fh       ; 999,999 doesn't fit in 16 bits, so we split it:
MAX_SCORE_LO    EQU 423Fh       ; 999,999 = 000F423Fh -> high word 000Fh, low word 423Fh

; ---- points (how much each event adds to the score) ----
PTS_COIN        EQU 200         ; picking a coin, or a coin from a ? block
PTS_KICK        EQU 400         ; kicking a shell that is lying still
PTS_SHELL_KILL  EQU 500         ; a sliding shell knocks out an enemy
PTS_MUSHROOM    EQU 1000        ; picking up a mushroom
PTS_BRICK       EQU 50          ; Super Mario breaking a brick
PTS_PER_SECOND  EQU 50          ; at the end, each second left on the clock gives 50
STOMP_MAX       EQU 10          ; stomps 1 to 10 give points, the 11th gives a free life

; ---- timings ----
; The manual gives times in seconds. The game works in frames, so we
; multiply seconds x FRAME_RATE. Change FRAME_RATE and all of these follow.
FRAME_RATE      EQU 30          ; frames per second (30 only if Module 8 speeds up the timer, else 18)
TICKS_PER_SEC   EQU FRAME_RATE          ; 1 timer tick = 1 frame
INVULN_FRAMES   EQU 2*FRAME_RATE        ; blinking safe time after being hurt = 2 s
FLAT_FRAMES     EQU FRAME_RATE          ; a squashed Goomba stays visible 1 s
KICK_GRACE      EQU 8                   ; after a kick the shell ignores Mario for 8 frames
DEATH_FRAMES    EQU FRAME_RATE*3/2      ; death animation = 1.5 s
LIFELOST_FRAMES EQU 2*FRAME_RATE        ; "life lost" screen = 2 s
SLIDE_FRAMES    EQU FRAME_RATE          ; sliding down the flag pole = 1 s
WALK_FRAMES     EQU FRAME_RATE          ; walking to the castle = 1 s
DEATH_HOP       EQU 48                  ; when Mario dies he jumps up 48 pixels first

; ---- game states: which screen / mode the game is in right now ----
STATE_TITLE     EQU 0           ; title screen with START / EXIT
STATE_PLAYING   EQU 1           ; the actual game
STATE_PAUSED    EQU 2           ; frozen because P was pressed
STATE_DYING     EQU 3           ; Mario's death animation
STATE_LIFELOST  EQU 4           ; "life lost" screen
STATE_WIN       EQU 5           ; slide down the pole and walk to the castle
STATE_LEVELDONE EQU 6           ; "level complete" screen
STATE_GAMEOVER  EQU 7           ; "game over" screen
STATE_EXIT      EQU 8           ; quit and go back to DOS

; ---- enemy types ----
ENEMY_NONE      EQU 0           ; this slot in the table is empty (no enemy)
ENEMY_GOOMBA    EQU 1           ; a Goomba
ENEMY_KOOPA     EQU 2           ; a Koopa Troopa (the turtle)
ENEMY_SHELL     EQU 3           ; a Koopa shell

; ---- enemy states (our own list, kept in the EN_STATE field) ----
ENS_WAIT        EQU 0           ; standing still, waiting until it is near the screen
ENS_WALK        EQU 1           ; walking around
ENS_FLAT        EQU 2           ; squashed Goomba, shown for a moment then removed
ENS_SHELL_STILL EQU 3           ; shell lying still
ENS_SHELL_SLIDE EQU 4           ; shell sliding fast

; ---- enemy record layout ----
; Every enemy is one record of EN_SIZE bytes. These numbers say where each
; field sits inside the record (counted from the start of the record).
EN_TYPE         EQU 0           ; byte 0: which enemy (ENEMY_...)
EN_STATE        EQU 1           ; byte 1: what it is doing (ENS_...)
EN_X            EQU 2           ; bytes 2-3: x position in the level (8.8)
EN_Y            EQU 4           ; bytes 4-5: y position (8.8)
EN_SPEED        EQU 6           ; bytes 6-7: walking speed (8.8)
EN_DIR          EQU 8           ; byte 8: which way it walks (left or right)
EN_TIMER        EQU 9           ; byte 9: countdown timer (flat time, kick grace)
EN_VY           EQU 10          ; bytes 10-11: falling speed (8.8, signed)
EN_SIZE         EQU 12          ; one record is 12 bytes in total

; ============================================================
; ===== VARIABLES =====
; A variable reserves memory. db = 1 byte, dw = 2 bytes, dd = 4 bytes.
; The number after it is the value it starts with.
; ============================================================

; ---- hero (Mario) ----
mario_x         dw START_X*256  ; Mario's x in the level, 8.8 (32 x 256 = 2000h)
mario_y         dw START_Y*256  ; y of Mario's feet, 8.8, unsigned (wraps after 256 px, so the death fall must stop before that)
mario_vx        dw 0            ; sideways speed, 8.8, can be negative (going left)
mario_vy        dw 0            ; up/down speed, 8.8, negative = going up
facing          db 0            ; which way Mario looks: 0 = right, 1 = left
on_ground       db 0            ; 1 = standing on something, 0 = in the air
form            db 0            ; 0 = Small Mario, 1 = Super Mario
hp              db 1            ; health: 1 (Small) or 2 (Super), never more than 2
invuln_timer    dw 0            ; frames left of being safe after a hit (Mario blinks)
stomp_chain     db 0            ; enemies stomped in one jump, back to 0 on landing
pose            db 0            ; which picture to draw: standing, running or jumping

; ---- camera ----
camera_x        dw 0            ; level x of the left edge of the screen (whole pixels)

; ---- score and status ----
score_lo        dw 0            ; score, lower 16 bits
score_hi        dw 0            ; score, upper 16 bits (together they are one 32-bit number)
coins           db 0            ; coins collected, 0 to 99 (100 gives a life, back to 0)
lives           db START_LIVES  ; lives Mario has left

; ---- clock ----
time_left       dw LEVEL_TIME   ; seconds left on the level clock, counts down
tick_count      dw 0            ; the timer interrupt adds 1 to this on every tick
last_tick       dw 0            ; tick_count from the last frame, to see if a new tick came
sec_ticks       db 0            ; ticks counted so far toward one second

; ---- keys ----
key_state       times 128 db 0  ; 128 bytes, one per scan code: 1 = key held, 0 = not held
key_extended    db 0            ; 1 right after the E0h byte that arrow keys send first

; ---- saved interrupt vectors ----
old_int09       dd 0            ; original keyboard handler (4 bytes), put back on exit
old_int08       dd 0            ; original timer handler (4 bytes), put back on exit

; ---- game control ----
game_state      db STATE_TITLE  ; which state the game is in, starts at the title screen
fb_seg          dw 0            ; segment of the hidden frame buffer we draw into first
menu_choice     db 0            ; title menu highlight: 0 = START, 1 = EXIT
win_timer       dw 0            ; frames passed in the win sequence
death_timer     dw 0            ; frames passed in the death animation

; ---- enemies ----
enemies         times MAX_ENEMIES*EN_SIZE db 0  ; table of 8 records x 12 bytes, all zero = empty

; ---- score tables ----
stomp_points    dw 100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000  ; points for stomp 1..10 in one jump
flag_points     dw 5000, 2000, 800, 400, 100  ; flag pole points: top zone first, bottom zone last
; Row of Mario's feet (0 to 11) -> which flag_points entry to use:
flag_zone       db 0,0,0,0,1,2,3,3,4,4,4,4    ; rows 2-3 = 5000, 4 = 2000, 5 = 800, 6-7 = 400, 8 = 100

; map_original and map_working (720 bytes each) will be added in Module 3

; ============================================================
; ===== CODE =====
; ============================================================

; ------------------------------------------------------------
; Name     : start
; Purpose  : where the program begins; for now it only sets text mode
;            and quits to DOS (the real game code comes later)
; Inputs   : none
; Outputs  : none (we end up back at the DOS prompt)
; Changes  : AX
; ------------------------------------------------------------
start:
    mov ax, 0003h               ; BIOS function 00h, mode 03h = normal text screen
    int 10h                     ; call BIOS to do it
    mov ah, 4Ch                 ; DOS function 4Ch = end program
    int 21h                     ; call DOS to do it
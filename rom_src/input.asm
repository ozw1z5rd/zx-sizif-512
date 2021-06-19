; OUT -  A - 0 - no key, 32 - exit, 16 - action, 8 - up, 4 - down, 2 - left, 1 - right
input_key_get:
    ld a, (var_input_key)
    ret


; OUT -  B - {0, action, up, down, left, right}
; OUT - AF - garbage
; OUT -  C - garbage
input_read:
    ld b, 0
.kempston:
    ld a, #ff     ; read kempston
    in a, (#1f)   ; ...
    bit 7, a      ; detect presence by 7th bit
    jr nz, .enter ; ...
    and #1f       ; mask useless bits
    ld b, a       ; ...
.enter:
    ld a, #bf     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle Enter (ACTION) key
    jr nz, .qwert ; ...
    set 4, b      ; ...
    ret
.qwert:
    ld a, #fb     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle Q (UP) key
    jr nz, .asdfg ; ...
    set 3, b      ; ...
    ret
.asdfg:
    ld a, #fd     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle A (DOWN) key
    jr nz, .poiuy ; ...
    set 2, b      ; ...
    ret
.poiuy:
    ld a, #df     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle P (RIGHT) key
    jr nz, .poiuy1 ; ...
    set 0, b      ; ...
    ret
.poiuy1:
    bit 1, a      ; handle O (LEFT) key
    jr nz, .cszxcv ; ...
    set 1, b      ; ...
    ret
.cszxcv:
    ld a, #fe     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle CS key. if pressed - assume cursor key. else - assume sinclair joystick
    jr z, .space_break ; ...
.space:
    ld a, #7f     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle Space (ACTION) key
    jr nz, .sinclair_09876 ; ...
    set 4, b      ; ...
    ret
.sinclair_09876:
    ld a, #ef     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle 0 (ACTION) key
    jr nz, .sinclair_09876_9 ; ...
    set 4, b     ; ...
    ret
.sinclair_09876_9:
    bit 1, a      ; handle 9 (UP) key
    jr nz, .sinclair_09876_8 ; ...
    set 3, b      ; ...
    ret
.sinclair_09876_8:
    bit 2, a      ; handle 8 (DOWN) key
    jr nz, .sinclair_09876_7 ; ...
    set 2, b      ; ...
    ret
.sinclair_09876_7:
    bit 3, a      ; handle 7 (RIGHT) key
    jr nz, .sinclair_09876_6 ; ...
    set 0, b      ; ...
    ret
.sinclair_09876_6:
    bit 4, a      ; handle 6 (LEFT) key
    jr nz, .return ; ...
    set 1, b      ; ...
    ret
.space_break:
    ld a, #7f     ; read keys
    in a, (#fe)   ; ...
    bit 0, a      ; handle Space (EXIT) key
    jr nz, .cursor_09876_7 ; ...
    set 5, b      ; ...
    ret
.cursor_09876_7:
    ld a, #ef     ; read keys
    in a, (#fe)   ; ...
    bit 3, a      ; handle 7 (UP) key
    jr nz, .cursor_09876_6 ; ...
    set 3, b      ; ...
    ret
.cursor_09876_6:
    bit 4, a      ; handle 6 (DOWN) key
    jr nz, .cursor_09876_8 ; ...
    set 2, b      ; ...
    ret
.cursor_09876_8:
    bit 2, a      ; handle 8 (RIGHT) key
    jr nz, .cursor_12345_5 ; ...
    set 0, b      ; ...
    ret
.cursor_12345_5:
    ld a, #f7     ; read keys
    in a, (#fe)   ; ...
    bit 4, a      ; handle 5 (LEFT) key
    jr nz, .return ; ...
    set 1, b      ; ...
    ret
.return:
    ret


; IN  -  A - current pressed key
; OUT - AF - garbage
; OUT - BC - garbage
input_beep:
    or a
    jr z, .return
    IFDEF TEST_BUILD
        ld a, #10            ; blink border
        out (#fe), a         ; ...
    ENDIF
    xor a                    ; blink border
    ld bc, #01ff             ; ...
    out (c), a               ; ...
    ld b, INPUT_BEEP_DELAY
.loop:
    djnz .loop
    ld a, 1                  ; blink border back
    ld bc, #01ff             ; ...
    out (c), a               ; ...
.return:
    ret


; OUT -  B - current pressed key mask
; OUT - AF - garbage
; OUT -  C - garbage
input_process:
    call input_read              ; read keys
    ld a, (var_input_key_last)   ;
    cp b                         ; if (current_pressed_key == last_pressed_key) {input_key = current_pressed_key; timer = X}
    jr z, .repeat                ; ...
    ld a, b                      ; 
    ld (var_input_key), a        ; input_key = current_pressed_key
    ld (var_input_key_last), a   ; last_pressed_ley = current_pressed_key
    call input_beep
    ld a, INPUT_REPEAT_FIRST     ; timer = INPUT_REPEAT_FIRST
    ld (var_input_key_hold_timer), a ; ...
    ret
.repeat:
    ld a, (var_input_key_hold_timer)  ; ...
    dec a                             ; timer--
    jr nz, .repeat_wait               ; if (timer == 0) input_key = current_pressed_key
    ld a, (var_input_key_last)        ; ...
    ld (var_input_key), a             ; ...
    call input_beep
    ld a, INPUT_REPEAT                ; timer = INPUT_REPEAT
    ld (var_input_key_hold_timer), a  ; ...
    ret
.repeat_wait:
    ld (var_input_key_hold_timer), a  ; timer--
    xor a                             ; input_key = none
    ld (var_input_key), a             ; ...
    ret


;var_input_key: DB 0
;var_input_key_last: DB 0
;var_input_key_hold_timer: DB 0

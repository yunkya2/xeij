'echo off

'if exist optitest.log del optitest.log

echo ================================>>optitest.log

echo [ABCD]>>optitest.log
optime -i "abcd.b d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;abcd.b -(a0),-(a0)">>optitest.log

echo [ADD]>>optitest.log
optime -i "add.b d0,d0">>optitest.log
optime -i "add.b (a5),d0">>optitest.log
optime -i "add.w d0,d0">>optitest.log
optime -i "add.w (a5),d0">>optitest.log
optime -i "add.l d0,d0">>optitest.log
optime -i "add.l (a5),d0">>optitest.log
optime -i "add.b d0,-8(a5)">>optitest.log
optime -i "add.w d0,-8(a5)">>optitest.log
optime -i "add.l d0,-8(a5)">>optitest.log

echo [ADDA]>>optitest.log
optime -i "adda.w d0,a0">>optitest.log
optime -i "adda.w (a5),a0">>optitest.log
optime -i "adda.l d0,a0">>optitest.log
optime -i "adda.l (a5),a0">>optitest.log

echo [ADDI]>>optitest.log
optime -i "addi.b #0,d0">>optitest.log
optime -i "addi.b #0,-8(a5)">>optitest.log
optime -i "addi.w #0,d0">>optitest.log
optime -i "addi.w #0,-8(a5)">>optitest.log
optime -i "addi.l #0,d0">>optitest.log
optime -i "addi.l #0,-8(a5)">>optitest.log

echo [ADDQ]>>optitest.log
optime -i "addq.b #1,d0">>optitest.log
optime -i "addq.b #1,-8(a5)">>optitest.log
optime -i "addq.w #1,d0">>optitest.log
optime -i "addq.w #1,a0">>optitest.log
optime -i "addq.w #1,-8(a5)">>optitest.log
optime -i "addq.l #1,d0">>optitest.log
optime -i "addq.l #1,a0">>optitest.log
optime -i "addq.l #1,-8(a5)">>optitest.log

echo [ADDX]>>optitest.log
optime -i "addx.b d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;addx.b -(a0),-(a0)">>optitest.log
optime -i "addx.w d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;addx.w -(a0),-(a0)">>optitest.log
optime -i "addx.l d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;addx.l -(a0),-(a0)">>optitest.log

echo [ALINE]>>optitest.log
'line 1010 emulator
optime -i "lea.l $0028.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;.dc.w $A000;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [AND]>>optitest.log
optime -i "and.b d0,d0">>optitest.log
optime -i "and.b (a5),d0">>optitest.log
optime -i "and.w d0,d0">>optitest.log
optime -i "and.w (a5),d0">>optitest.log
optime -i "and.l d0,d0">>optitest.log
optime -i "and.l (a5),d0">>optitest.log
optime -i "and.b d0,-8(a5)">>optitest.log
optime -i "and.w d0,-8(a5)">>optitest.log
optime -i "and.l d0,-8(a5)">>optitest.log

echo [ANDI]>>optitest.log
optime -i "andi.b #-1,d0">>optitest.log
optime -i "andi.b #-1,-8(a5)">>optitest.log
optime -i "andi.w #-1,d0">>optitest.log
optime -i "andi.w #-1,-8(a5)">>optitest.log
optime -i "andi.l #-1,d0">>optitest.log
optime -i "andi.l #-1,-8(a5)">>optitest.log

echo [ANDI to CCR]>>optitest.log
optime -i "andi.b #-1,ccr">>optitest.log

echo [ANDI to SR]>>optitest.log
optime -i "andi.w #-1,sr">>optitest.log

echo [ASL]>>optitest.log
optime -i "asl.b #1,d0">>optitest.log
optime -i "asl.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;asl.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;asl.b d0,d0">>optitest.log
optime -i "asl.w #1,d0">>optitest.log
optime -i "asl.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;asl.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;asl.w d0,d0">>optitest.log
optime -i "asl.l #1,d0">>optitest.log
optime -i "asl.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;asl.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;asl.l d0,d0">>optitest.log
optime -i "asl.w -8(a5)">>optitest.log

echo [ASR]>>optitest.log
optime -i "asr.b #1,d0">>optitest.log
optime -i "asr.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;asr.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;asr.b d0,d0">>optitest.log
optime -i "asr.w #1,d0">>optitest.log
optime -i "asr.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;asr.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;asr.w d0,d0">>optitest.log
optime -i "asr.l #1,d0">>optitest.log
optime -i "asr.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;asr.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;asr.l d0,d0">>optitest.log
optime -i "asr.w -8(a5)">>optitest.log

echo [Bcc]>>optitest.log
optime -i "clr.b d0;bcc.s @f;nop;@@:">>optitest.log
optime -i "clr.b d0;bcc.w @f;@@:">>optitest.log
optime -i "clr.b d0;bcs.s @f;nop;@@:">>optitest.log
optime -i "clr.b d0;bcs.w @f;@@:">>optitest.log

echo [BCHG]>>optitest.log
optime -i "moveq.l #0,d0;bchg.l d0,d0">>optitest.log
optime -i "moveq.l #16,d0;bchg.l d0,d0">>optitest.log
optime -i "bchg.b d0,-8(a5)">>optitest.log
optime -i "bchg.l #0,d0">>optitest.log
optime -i "bchg.l #16,d0">>optitest.log
optime -i "bchg.b #0,-8(a5)">>optitest.log

echo [BCLR]>>optitest.log
optime -i "moveq.l #0,d0;bclr.l d0,d0">>optitest.log
optime -i "moveq.l #16,d0;bclr.l d0,d0">>optitest.log
optime -i "bclr.b d0,-8(a5)">>optitest.log
optime -i "bclr.l #0,d0">>optitest.log
optime -i "bclr.l #16,d0">>optitest.log
optime -i "bclr.b #0,-8(a5)">>optitest.log

echo [BRA]>>optitest.log
optime -i "bra.s @f;nop;@@:">>optitest.log
optime -i "bra.w @f;@@:">>optitest.log

echo [BSET]>>optitest.log
optime -i "moveq.l #0,d0;bset.l d0,d0">>optitest.log
optime -i "moveq.l #16,d0;bset.l d0,d0">>optitest.log
optime -i "bset.b d0,-8(a5)">>optitest.log
optime -i "bset.l #0,d0">>optitest.log
optime -i "bset.l #16,d0">>optitest.log
optime -i "bset.b #0,-8(a5)">>optitest.log

echo [BSR]>>optitest.log
optime -i "bsr.s 1f;bra.s 2f;1:;rts;2:">>optitest.log
optime -i "bsr.w 1f;bra.s 2f;1:;rts;2:">>optitest.log

echo [BTST]>>optitest.log
optime -i "moveq.l #0,d0;btst.l d0,d0">>optitest.log
optime -i "moveq.l #16,d0;btst.l d0,d0">>optitest.log
optime -i "btst.b d0,-8(a5)">>optitest.log
optime -i "btst.l #0,d0">>optitest.log
optime -i "btst.l #16,d0">>optitest.log
optime -i "btst.b #0,-8(a5)">>optitest.log

echo [CHK]>>optitest.log
optime -i "moveq.l #0,d0;chk.w d0,d0">>optitest.log
'chk instruction
optime -i "lea.l $0018.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;moveq.l #1,d0;chk.w #0,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [CLR]>>optitest.log
optime -i "clr.b d0">>optitest.log
optime -i "clr.b -8(a5)">>optitest.log
optime -i "clr.w d0">>optitest.log
optime -i "clr.w -8(a5)">>optitest.log
optime -i "clr.l d0">>optitest.log
optime -i "clr.l -8(a5)">>optitest.log

echo [CMP]>>optitest.log
optime -i "cmp.b d0,d0">>optitest.log
optime -i "cmp.b (a5),d0">>optitest.log
optime -i "cmp.w d0,d0">>optitest.log
optime -i "cmp.w (a5),d0">>optitest.log
optime -i "cmp.l d0,d0">>optitest.log
optime -i "cmp.l (a5),d0">>optitest.log

echo [CMPA]>>optitest.log
optime -i "cmpa.w d0,a0">>optitest.log
optime -i "cmpa.w (a5),a0">>optitest.log
optime -i "cmpa.l d0,a0">>optitest.log
optime -i "cmpa.l (a5),a0">>optitest.log

echo [CMPI]>>optitest.log
optime -i "cmpi.b #0,d0">>optitest.log
optime -i "cmpi.b #0,(a5)">>optitest.log
optime -i "cmpi.w #0,d0">>optitest.log
optime -i "cmpi.w #0,(a5)">>optitest.log
optime -i "cmpi.l #0,d0">>optitest.log
optime -i "cmpi.l #0,(a5)">>optitest.log

echo [CMPM]>>optitest.log
optime -i "movea.l a5,a0;cmpm.b (a0)+,(a0)+">>optitest.log
optime -i "movea.l a5,a0;cmpm.w (a0)+,(a0)+">>optitest.log
optime -i "movea.l a5,a0;cmpm.l (a0)+,(a0)+">>optitest.log

echo [DBcc]>>optitest.log
optime -i "moveq.l #2,d0;@@:;dbra.w d0,@b">>optitest.log
optime -i "moveq.l #2,d0;@@:;dbcc.w d0,@b">>optitest.log
optime -i "moveq.l #2,d0;@@:;dbcs.w d0,@b">>optitest.log

echo [DIVS]>>optitest.log
'divide by zero
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$00000000,d0;divs.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$00000001,d0;divs.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$80000000,d0;divs.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$FFFFFFFF,d0;divs.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
'unsigned overflow
optime -i "move.l #$00010000,d0;divs.w #$0001,d0">>optitest.log
optime -i "move.l #$00010000,d0;divs.w #$FFFF,d0">>optitest.log
optime -i "move.l #$FFFF0000,d0;divs.w #$0001,d0">>optitest.log
optime -i "move.l #$FFFF0000,d0;divs.w #$FFFF,d0">>optitest.log
'signed overflow
optime -i "move.l #$00008000,d0;divs.w #$0001,d0">>optitest.log
optime -i "move.l #$00008001,d0;divs.w #$FFFF,d0">>optitest.log
optime -i "move.l #$FFFF8001,d0;divs.w #$0001,d0">>optitest.log
optime -i "move.l #$FFFF8000,d0;divs.w #$FFFF,d0">>optitest.log
'normal
optime -i "move.l #$0CE6D17C,d0;divs.w #$7685,d0">>optitest.log
optime -i "move.l #$0CE6D17C,d0;divs.w #$897B,d0">>optitest.log
optime -i "move.l #$F3192E84,d0;divs.w #$7685,d0">>optitest.log
optime -i "move.l #$F3192E84,d0;divs.w #$897B,d0">>optitest.log
optime -i "move.l #$55BFA3AB,d0;divs.w #$5FC7,d0">>optitest.log
optime -i "move.l #$55BFA3AB,d0;divs.w #$A039,d0">>optitest.log
optime -i "move.l #$AA405C55,d0;divs.w #$5FC7,d0">>optitest.log
optime -i "move.l #$AA405C55,d0;divs.w #$A039,d0">>optitest.log
optime -i "move.l #$43231558,d0;divs.w #$71E3,d0">>optitest.log
optime -i "move.l #$43231558,d0;divs.w #$8E1D,d0">>optitest.log
optime -i "move.l #$BCDCEAA8,d0;divs.w #$71E3,d0">>optitest.log
optime -i "move.l #$BCDCEAA8,d0;divs.w #$8E1D,d0">>optitest.log

echo [DIVU]>>optitest.log
'divide by zero
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$00000000,d0;divu.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$00000001,d0;divu.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$80000000,d0;divu.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
optime -i "lea.l $0014.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.l #$FFFFFFFF,d0;divu.w #$0000,d0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log
'overflow
optime -i "move.l #$00010000,d0;divu.w #$0001,d0">>optitest.log
optime -i "move.l #$FFFF0000,d0;divu.w #$FFFF,d0">>optitest.log
'normal
optime -i "move.l #$1E691B17,d0;divu.w #$4E77,d0">>optitest.log
optime -i "move.l #$463D7C24,d0;divu.w #$7EC1,d0">>optitest.log
optime -i "move.l #$8BDD77D2,d0;divu.w #$F728,d0">>optitest.log
optime -i "move.l #$927F70B1,d0;divu.w #$D849,d0">>optitest.log
optime -i "move.l #$A1107346,d0;divu.w #$E9CF,d0">>optitest.log
optime -i "move.l #$50D44D54,d0;divu.w #$A2B7,d0">>optitest.log

echo [EOR]>>optitest.log
optime -i "eor.b d0,d0">>optitest.log
optime -i "eor.b d0,-8(a5)">>optitest.log
optime -i "eor.w d0,d0">>optitest.log
optime -i "eor.w d0,-8(a5)">>optitest.log
optime -i "eor.l d0,d0">>optitest.log
optime -i "eor.l d0,-8(a5)">>optitest.log

echo [EORI]>>optitest.log
optime -i "eori.b #0,d0">>optitest.log
optime -i "eori.b #0,-8(a5)">>optitest.log
optime -i "eori.w #0,d0">>optitest.log
optime -i "eori.w #0,-8(a5)">>optitest.log
optime -i "eori.l #0,d0">>optitest.log
optime -i "eori.l #0,-8(a5)">>optitest.log

echo [EORI to CCR]>>optitest.log
optime -i "eori.b #0,ccr">>optitest.log

echo [EORI to SR]>>optitest.log
optime -i "eori.w #0,sr">>optitest.log

echo [EXG]>>optitest.log
optime -i "exg.l d0,d0">>optitest.log
optime -i "exg.l a0,a0">>optitest.log
optime -i "exg.l d0,a0">>optitest.log

echo [EXT]>>optitest.log
optime -i "ext.w d0">>optitest.log
optime -i "ext.l d0">>optitest.log

echo [FLINE]>>optitest.log
'line 1111 emulator
optime -i "lea.l $002C.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;.dc.w $FF00;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [ILLEGAL]>>optitest.log
'illegal instruction
optime -i "lea.l $0010.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;illegal;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [JMP]>>optitest.log
optime -i "lea.l @f(pc),a0;jmp (a0);@@:">>optitest.log
optime -i "jmp @f;@@:">>optitest.log
optime -i "jmp @f(pc);@@:">>optitest.log
'address error
optime -i "lea.l $000C.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;jmp $0001.w;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [JSR]>>optitest.log
optime -i "lea.l 1f(pc),a0;jsr (a0);bra.s 2f;1:;rts;2:">>optitest.log
optime -i "jsr 1f;bra.s 2f;1:;rts;2:">>optitest.log
optime -i "jsr 1f(pc);bra.s 2f;1:;rts;2:">>optitest.log

echo [LEA]>>optitest.log
optime -i "lea.l -8(a5),a0">>optitest.log
optime -i "lea.l @f,a0;@@:">>optitest.log
optime -i "lea.l @f(pc),a0;@@:">>optitest.log

echo [LINK]>>optitest.log
optime -i "link.w a0,#-4;addq.l #8,sp">>optitest.log

echo [LSL]>>optitest.log
optime -i "lsl.b #1,d0">>optitest.log
optime -i "lsl.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;lsl.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;lsl.b d0,d0">>optitest.log
optime -i "lsl.w #1,d0">>optitest.log
optime -i "lsl.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;lsl.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;lsl.w d0,d0">>optitest.log
optime -i "lsl.l #1,d0">>optitest.log
optime -i "lsl.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;lsl.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;lsl.l d0,d0">>optitest.log
optime -i "lsl.w -8(a5)">>optitest.log

echo [LSR]>>optitest.log
optime -i "lsr.b #1,d0">>optitest.log
optime -i "lsr.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;lsr.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;lsr.b d0,d0">>optitest.log
optime -i "lsr.w #1,d0">>optitest.log
optime -i "lsr.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;lsr.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;lsr.w d0,d0">>optitest.log
optime -i "lsr.l #1,d0">>optitest.log
optime -i "lsr.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;lsr.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;lsr.l d0,d0">>optitest.log
optime -i "lsr.w -8(a5)">>optitest.log

echo [MOVE]>>optitest.log
optime -i "move.b d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0),d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0)+,d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.b -(a0),d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.b d0,(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0),(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0)+,(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b -(a0),(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b d0,(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0),(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0)+,(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.b -(a0),(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.b d0,-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0),-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b (a0)+,-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.b -(a0),-(a0)">>optitest.log
optime -i "move.w d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0),d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0)+,d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.w -(a0),d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.w d0,(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0),(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0)+,(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w -(a0),(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w d0,(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0),(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0)+,(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.w -(a0),(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.w d0,-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0),-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w (a0)+,-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.w -(a0),-(a0)">>optitest.log
optime -i "move.l d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0),d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0)+,d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.l -(a0),d0">>optitest.log
optime -i "lea.l -8(a5),a0;move.l d0,(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0),(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0)+,(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l -(a0),(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l d0,(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0),(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0)+,(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.l -(a0),(a0)+">>optitest.log
optime -i "lea.l -8(a5),a0;move.l d0,-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0),-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l (a0)+,-(a0)">>optitest.log
optime -i "lea.l -8(a5),a0;move.l -(a0),-(a0)">>optitest.log

echo [MOVE from SR]>>optitest.log
optime -i "move.w sr,d0">>optitest.log
optime -i "move.w sr,-8(a5)">>optitest.log

echo [MOVE to CCR]>>optitest.log
optime -i "move.w d0,ccr">>optitest.log
optime -i "move.w -8(a5),ccr">>optitest.log

echo [MOVE to SR]>>optitest.log
optime -i "move.w sr,d0;move.w d0,sr">>optitest.log
optime -i "move.w sr,-8(a5);move.w -8(a5),sr">>optitest.log

echo [MOVE from USP]>>optitest.log
optime -i "move.l usp,a0">>optitest.log

echo [MOVE to USP]>>optitest.log
optime -i "move.l a0,usp">>optitest.log

echo [MOVEA]>>optitest.log
optime -i "movea.w d0,a0">>optitest.log
optime -i "lea.l -8(a5),a0;movea.w (a0),a0">>optitest.log
optime -i "lea.l -8(a5),a0;movea.w (a0)+,a0">>optitest.log
optime -i "lea.l -8(a5),a0;movea.w -(a0),a0">>optitest.log
optime -i "movea.l d0,a0">>optitest.log
optime -i "lea.l -8(a5),a0;movea.l (a0),a0">>optitest.log
optime -i "lea.l -8(a5),a0;movea.l (a0)+,a0">>optitest.log
optime -i "lea.l -8(a5),a0;movea.l -(a0),a0">>optitest.log

echo [MOVEM]>>optitest.log
optime -i "movem.w d0,-8(a5)">>optitest.log
optime -i "movem.w d0-d1,-8(a5)">>optitest.log
optime -i "movem.l d0,-8(a5)">>optitest.log
optime -i "movem.l d0-d1,-8(a5)">>optitest.log
optime -i "movem.w (a5),d0">>optitest.log
optime -i "movem.w (a5),d0-d1">>optitest.log
optime -i "movem.l (a5),d0">>optitest.log
optime -i "movem.l (a5),d0-d1">>optitest.log

echo [MOVEP]>>optitest.log
optime -i "movep.w (a5),d0">>optitest.log
optime -i "movep.l (a5),d0">>optitest.log
optime -i "movep.w d0,-8(a5)">>optitest.log
optime -i "movep.l d0,-8(a5)">>optitest.log

echo [MOVEQ]>>optitest.log
optime -i "moveq.l #0,d0">>optitest.log
optime -i "moveq.l #-1,d0">>optitest.log

echo [MULS]>>optitest.log
optime -i "move.w #$0000,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$000F,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$00FF,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$0FFF,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$FFFF,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$0005,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$0055,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$0555,d0;muls.w d0,d0">>optitest.log
optime -i "move.w #$5555,d0;muls.w d0,d0">>optitest.log

echo [MULU]>>optitest.log
optime -i "move.w #$0000,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$000F,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$00FF,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$0FFF,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$FFFF,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$0005,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$0055,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$0555,d0;mulu.w d0,d0">>optitest.log
optime -i "move.w #$5555,d0;mulu.w d0,d0">>optitest.log

echo [NBCD]>>optitest.log
optime -i "nbcd.b d0">>optitest.log
optime -i "nbcd.b -8(a5)">>optitest.log

echo [NEG]>>optitest.log
optime -i "neg.b d0">>optitest.log
optime -i "neg.b -8(a5)">>optitest.log
optime -i "neg.w d0">>optitest.log
optime -i "neg.w -8(a5)">>optitest.log
optime -i "neg.l d0">>optitest.log
optime -i "neg.l -8(a5)">>optitest.log

echo [NEGX]>>optitest.log
optime -i "negx.b d0">>optitest.log
optime -i "negx.b -8(a5)">>optitest.log
optime -i "negx.w d0">>optitest.log
optime -i "negx.w -8(a5)">>optitest.log
optime -i "negx.l d0">>optitest.log
optime -i "negx.l -8(a5)">>optitest.log

echo [NOP]>>optitest.log
optime -i "nop">>optitest.log

echo [NOT]>>optitest.log
optime -i "not.b d0">>optitest.log
optime -i "not.b -8(a5)">>optitest.log
optime -i "not.w d0">>optitest.log
optime -i "not.w -8(a5)">>optitest.log
optime -i "not.l d0">>optitest.log
optime -i "not.l -8(a5)">>optitest.log

echo [OR]>>optitest.log
optime -i "or.b d0,d0">>optitest.log
optime -i "or.b (a5),d0">>optitest.log
optime -i "or.w d0,d0">>optitest.log
optime -i "or.w (a5),d0">>optitest.log
optime -i "or.l d0,d0">>optitest.log
optime -i "or.l (a5),d0">>optitest.log
optime -i "or.b d0,-8(a5)">>optitest.log
optime -i "or.w d0,-8(a5)">>optitest.log
optime -i "or.l d0,-8(a5)">>optitest.log

echo [ORI]>>optitest.log
optime -i "ori.b #0,d0">>optitest.log
optime -i "ori.b #0,-8(a5)">>optitest.log
optime -i "ori.w #0,d0">>optitest.log
optime -i "ori.w #0,-8(a5)">>optitest.log
optime -i "ori.l #0,d0">>optitest.log
optime -i "ori.l #0,-8(a5)">>optitest.log

echo [ORI to CCR]>>optitest.log
optime -i "ori.b #0,ccr">>optitest.log

echo [ORI to SR]>>optitest.log
optime -i "ori.w #0,sr">>optitest.log
'privilege violation
optime -i "lea.l $0020.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.w #0,sr;rte;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [PEA]>>optitest.log
optime -i "pea.l -8(a5);addq.l #4,sp">>optitest.log
optime -i "pea.l @f;@@:;addq.l #4,sp">>optitest.log
optime -i "pea.l @f(pc);@@:;addq.l #4,sp">>optitest.log

echo [ROL]>>optitest.log
optime -i "rol.b #1,d0">>optitest.log
optime -i "rol.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;rol.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;rol.b d0,d0">>optitest.log
optime -i "rol.w #1,d0">>optitest.log
optime -i "rol.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;rol.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;rol.w d0,d0">>optitest.log
optime -i "rol.l #1,d0">>optitest.log
optime -i "rol.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;rol.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;rol.l d0,d0">>optitest.log
optime -i "rol.w -8(a5)">>optitest.log

echo [ROR]>>optitest.log
optime -i "ror.b #1,d0">>optitest.log
optime -i "ror.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;ror.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;ror.b d0,d0">>optitest.log
optime -i "ror.w #1,d0">>optitest.log
optime -i "ror.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;ror.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;ror.w d0,d0">>optitest.log
optime -i "ror.l #1,d0">>optitest.log
optime -i "ror.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;ror.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;ror.l d0,d0">>optitest.log
optime -i "ror.w -8(a5)">>optitest.log

echo [ROXL]>>optitest.log
optime -i "roxl.b #1,d0">>optitest.log
optime -i "roxl.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;roxl.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;roxl.b d0,d0">>optitest.log
optime -i "roxl.w #1,d0">>optitest.log
optime -i "roxl.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;roxl.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;roxl.w d0,d0">>optitest.log
optime -i "roxl.l #1,d0">>optitest.log
optime -i "roxl.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;roxl.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;roxl.l d0,d0">>optitest.log
optime -i "roxl.w -8(a5)">>optitest.log

echo [ROXR]>>optitest.log
optime -i "roxr.b #1,d0">>optitest.log
optime -i "roxr.b #8,d0">>optitest.log
optime -i "moveq.l #0,d0;roxr.b d0,d0">>optitest.log
optime -i "moveq.l #31,d0;roxr.b d0,d0">>optitest.log
optime -i "roxr.w #1,d0">>optitest.log
optime -i "roxr.w #8,d0">>optitest.log
optime -i "moveq.l #0,d0;roxr.w d0,d0">>optitest.log
optime -i "moveq.l #31,d0;roxr.w d0,d0">>optitest.log
optime -i "roxr.l #1,d0">>optitest.log
optime -i "roxr.l #8,d0">>optitest.log
optime -i "moveq.l #0,d0;roxr.l d0,d0">>optitest.log
optime -i "moveq.l #31,d0;roxr.l d0,d0">>optitest.log
optime -i "roxr.w -8(a5)">>optitest.log

echo [RTE]>>optitest.log
optime -i "movea.l sp,a0;clr.w -(sp);pea.l @f(pc);move.w sr,-(sp);rte;@@:movea.l a0,sp">>optitest.log

echo [RTS]>>optitest.log
optime -i "pea.l @f(pc);rts;@@:">>optitest.log

echo [RTR]>>optitest.log
optime -i "pea.l @f(pc);move.w sr,-(sp);rtr;@@:">>optitest.log

echo [SBCD]>>optitest.log
optime -i "sbcd.b d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;sbcd.b -(a0),-(a0)">>optitest.log

echo [Scc]>>optitest.log
optime -i "sf.b d0">>optitest.log
optime -i "sf.b -8(a5)">>optitest.log
optime -i "st.b d0">>optitest.log
optime -i "st.b -8(a5)">>optitest.log
optime -i "clr.b d0;scc.b d0">>optitest.log
optime -i "clr.b d0;scc.b -8(a5)">>optitest.log
optime -i "clr.b d0;scs.b d0">>optitest.log
optime -i "clr.b d0;scs.b -8(a5)">>optitest.log

echo [SUB]>>optitest.log
optime -i "sub.b d0,d0">>optitest.log
optime -i "sub.b (a5),d0">>optitest.log
optime -i "sub.w d0,d0">>optitest.log
optime -i "sub.w (a5),d0">>optitest.log
optime -i "sub.l d0,d0">>optitest.log
optime -i "sub.l (a5),d0">>optitest.log
optime -i "sub.b d0,-8(a5)">>optitest.log
optime -i "sub.w d0,-8(a5)">>optitest.log
optime -i "sub.l d0,-8(a5)">>optitest.log

echo [SUBA]>>optitest.log
optime -i "suba.w d0,a0">>optitest.log
optime -i "suba.w (a5),a0">>optitest.log
optime -i "suba.l d0,a0">>optitest.log
optime -i "suba.l (a5),a0">>optitest.log

echo [SUBI]>>optitest.log
optime -i "subi.b #0,d0">>optitest.log
optime -i "subi.b #0,-8(a5)">>optitest.log
optime -i "subi.w #0,d0">>optitest.log
optime -i "subi.w #0,-8(a5)">>optitest.log
optime -i "subi.l #0,d0">>optitest.log
optime -i "subi.l #0,-8(a5)">>optitest.log

echo [SUBQ]>>optitest.log
optime -i "subq.b #1,d0">>optitest.log
optime -i "subq.b #1,-8(a5)">>optitest.log
optime -i "subq.w #1,d0">>optitest.log
optime -i "subq.w #1,a0">>optitest.log
optime -i "subq.w #1,-8(a5)">>optitest.log
optime -i "subq.l #1,d0">>optitest.log
optime -i "subq.l #1,a0">>optitest.log
optime -i "subq.l #1,-8(a5)">>optitest.log

echo [SUBX]>>optitest.log
optime -i "subx.b d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;subx.b -(a0),-(a0)">>optitest.log
optime -i "subx.w d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;subx.w -(a0),-(a0)">>optitest.log
optime -i "subx.l d0,d0">>optitest.log
optime -i "lea.l -8(a5),a0;subx.l -(a0),-(a0)">>optitest.log

echo [SWAP]>>optitest.log
optime -i "swap.w d0">>optitest.log

echo [TAS]>>optitest.log
optime -i "tas.b d0">>optitest.log
optime -i "tas.b -8(a5)">>optitest.log

echo [TRAP]>>optitest.log
'trap instruction
optime -i "lea.l $0080.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;trap #0;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [TRAPV]>>optitest.log
optime -i "move.w #0,ccr;trapv">>optitest.log
'trapv instruction
optime -i "lea.l $001C.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;move.w #2,ccr;trapv;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [TST]>>optitest.log
optime -i "tst.b d0">>optitest.log
optime -i "tst.b (a5)">>optitest.log
optime -i "tst.w d0">>optitest.log
optime -i "tst.w (a5)">>optitest.log
optime -i "tst.l d0">>optitest.log
optime -i "tst.l (a5)">>optitest.log
'main memory
optime -i "tst.w $00000000.l">>optitest.log
'graphic vram
optime -i "tst.w $00C00000.l">>optitest.log
'text vram
optime -i "tst.w $00E00000.l">>optitest.log
'crtc
optime -i "tst.w $00E80000.l">>optitest.log
optime -i "tst.w $00E80480.l">>optitest.log
'vicon
optime -i "tst.w $00E82000.l">>optitest.log
optime -i "tst.w $00E82400.l">>optitest.log
'dmac ch0 csr
optime -i "tst.b $00E84000.l">>optitest.log
'mfp gpdr
optime -i "tst.b $00E88001.l">>optitest.log
'rtc 1s
optime -i "tst.b $00E8A001.l">>optitest.log
'prnport data
optime -i "tst.b $00E8C001.l">>optitest.log
'sysport contrast
optime -i "tst.b $00E8E001.l">>optitest.log
'opm status
optime -i "tst.b $00E90003.l">>optitest.log
'adpcm status
optime -i "tst.b $00E92001.l">>optitest.log
'fdc status
optime -i "tst.b $00E94001.l">>optitest.log
'fdd status
optime -i "tst.b $00E94005.l">>optitest.log
'hdc status
optime -i "tst.b $00E96003.l">>optitest.log
'scc channel b rr0
optime -i "tst.b $00E98001.l">>optitest.log
'ppi port a
optime -i "tst.b $00E9A001.l">>optitest.log
'ioi status
optime -i "tst.b $00E9C001.l">>optitest.log
'spr bg0 scroll x
optime -i "tst.w $00EB0800.l">>optitest.log
'sram
optime -i "tst.w $00ED0000.l">>optitest.log
'cgrom
optime -i "tst.w $00F00000.l">>optitest.log
'iplrom
optime -i "tst.w $00FF0000.l">>optitest.log
'bus error
optime -i "lea.l $0008.w,a0;movea.l (a0),a1;move.l #@f,(a0);movea.l sp,a2;tst.b $00E80400;@@:;movea.l a2,sp;move.l a1,(a0)">>optitest.log

echo [UNLK]>>optitest.log
optime -i "subq.l #4,sp;movea.l sp,a0;unlk a0">>optitest.log

type optitest.log

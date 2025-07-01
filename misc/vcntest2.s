;========================================================================================
;  vcntest2.s
;  Copyright (C) 2003-2021 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac
	.include	iocscall.mac



	moveq.l	#-1,d1
	IOCS	_CRTMOD
	move.l	d0,-(sp)

	moveq.l	#6,d1			;256x256 dots, 16 colors, 4 plane
	IOCS	_CRTMOD

	IOCS	_B_CUROFF

	IOCS	_G_CLR_ON

	moveq.l	#%1111,d1
	IOCS	_VPAGE

	IOCS	_SP_INIT

	IOCS	_SP_ON

	moveq.l	#0,d1			;pattern number=0
	moveq.l	#0,d2			;size=8x8
	lea.l	sp_pat0,a1		;pattern
	IOCS	_SP_DEFCG

	moveq.l	#0,d1			;BG page number=0
	moveq.l	#0,d2			;BG text area=0
	move.l	#1,d3			;on
	IOCS	_BGCTRLST

	moveq.l	#0,d1			;4bit palet=0
	moveq.l	#0,d2			;palet block=0
	move.l	#%00000_00000_00000_0,d3	;wait=no, color=transparent
	IOCS	_SPALET

	moveq.l	#0,d1			;4bit palet=0
	moveq.l	#1,d2			;palet block=1
	move.l	#0<<31|%11111_11111_00000_0,d3	;wait=no, color=yellow
	IOCS	_SPALET

	moveq.l	#0,d1			;palet=0
	move.l	#%00000_00000_00000_0,d2	;color=black
	IOCS	_TPALET

	moveq.l	#1,d1			;palet=1
	move.l	#%10000_10000_10000_0,d2	;color=gray
	IOCS	_TPALET

	moveq.l	#0,d1			;palet=0
	move.l	#%00000_00000_00000_0,d2	;color=black
	IOCS	_GPALET

	moveq.l	#1,d1			;palet=1
	move.l	#%11111_00000_00000_0,d2	;color=lime
	IOCS	_GPALET

	moveq.l	#2,d1			;palet=2
	move.l	#%00000_11111_00000_0,d2	;color=red
	IOCS	_GPALET

	moveq.l	#3,d1			;palet=3
	move.l	#%00000_00000_11111_0,d2	;color=blue
	IOCS	_GPALET

	moveq.l	#4,d1			;palet=4
	move.l	#%00000_11111_11111_0,d2	;color=fuchsia
	IOCS	_GPALET

	moveq.l	#5,d1			;palet=5
	move.l	#%11111_00000_11111_0,d2	;color=aqua
	IOCS	_GPALET



;SE1T
;	A1	BG=$10(yellow) > GR=2(red) > TX=$0(black) = yellow
;	A2	BG=$10(yellow) > GR=2(red) > TX=$1(gray) = red
;		     Sp Tx Gr G4 G3 G2 G1
	move.l	#%00_00_10_01_11_10_01_00,d1	;S>G>T
	IOCS	_PRIORITY
;		  15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		  YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	move.w	#%_0__0__0__0__0__0__0__0__0__1__1__0__0__0__0__1,d1
	IOCS	_CRTMOD2
	moveq.l	#2,d1			;palet=2
	move.l	#%00000_11111_00000_0,d2	;color=red
	IOCS	_GPALET
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
;
	move.w	#2,-(sp)		;graphic palet=red
	pea.l	text_a1
	bsr	draw_text
	addq.l	#6,sp
	move.w	#%0000,-(sp)		;text palet=0
	bsr	copy_text
	addq.l	#2,sp
	bsr	wait_esc
	beq	exit
;
	move.w	#2,-(sp)		;graphic palet=red
	pea.l	text_a2
	bsr	draw_text
	addq.l	#6,sp
	move.w	#%0001,-(sp)		;text palet=1
	bsr	copy_text
	addq.l	#2,sp
	bsr	wait_esc
	beq	exit



;E2_XHPG
;	B1	1st:2(red) + 2nd:2(red) = red
;	B2	1st:2(red) + 2nd:3(blue) = red
;	B3	1st:3(blue) + 2nd:2(red) = purple
;	B4	1st:3(blue) + 2nd:3(blue) = purple
;		     Sp Tx Gr G4 G3 G2 G1
	move.l	#%00_00_01_10_11_10_01_00,d1	;S>T>G
	IOCS	_PRIORITY
;		  15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		  YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	move.w	#%_0__0__0__1__1__1__1__0__0__0__0__0__0__0__1__1,d1
	IOCS	_CRTMOD2
	moveq.l	#2,d1			;palet=2
	move.l	#%00000_11111_00000_0,d2	;color=red
	IOCS	_GPALET
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red
	pea.l	text_b1
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red
	pea.l	text_b1
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red
	pea.l	text_b2
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_b2
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_b3
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red
	pea.l	text_b3
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_b4
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_b4
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit



;E2_XHCG
;	C1	1st:2(red(even)) + 2nd:2(red(even)) = red
;	C2	1st:2(red(even)) + 2nd:3(blue) = red
;	C3	1st:2(red(even)) + 2nd:4(fuchsia) = red
;	C4	1st:2(red(even)) + 2nd:5(aqua) = red
;	C5	1st:3(blue) + 2nd:2(red(even)) = blue
;	C6	1st:3(blue) + 2nd:3(blue) = blue
;	C7	1st:3(blue) + 2nd:4(fuchsia) = aqua
;	C8	1st:3(blue) + 2nd:5(aqua) = aqua
;	D1	1st:2(red(odd)) + 2nd:2(red(odd)) = purple
;	D2	1st:2(red(odd)) + 2nd:3(blue) = purple
;	D3	1st:2(red(odd)) + 2nd:4(fuchsia) = gray
;	D4	1st:2(red(odd)) + 2nd:5(aqua) = gray
;	D5	1st:3(blue) + 2nd:2(red(odd)) = purple
;	D6	1st:3(blue) + 2nd:3(blue) = purple
;	D7	1st:3(blue) + 2nd:4(fuchsia) = gray
;	D8	1st:3(blue) + 2nd:5(aqua) = gray
;		     Sp Tx Gr G4 G3 G2 G1
	move.l	#%00_00_01_10_11_10_01_00,d1	;S>T>G
	IOCS	_PRIORITY
;		  15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		  YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	move.w	#%_0__0__0__1__1__0__1__0__0__0__0__0__0__0__1__1,d1
	IOCS	_CRTMOD2
;
	moveq.l	#2,d1			;palet=2
	move.l	#%00000_11111_00000_0,d2	;color=red(even)
	IOCS	_GPALET
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(even)
	pea.l	text_c1
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(even)
	pea.l	text_c1
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(even)
	pea.l	text_c2
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_c2
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(even)
	pea.l	text_c3
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#4,-(sp)		;graphic palet=fuchsia
	pea.l	text_c3
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(even)
	pea.l	text_c4
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#5,-(sp)		;graphic palet=aqua
	pea.l	text_c4
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_c5
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(even)
	pea.l	text_c5
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_c6
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_c6
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_c7
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#4,-(sp)		;graphic palet=fuchsia
	pea.l	text_c7
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_c8
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#5,-(sp)		;graphic palet=aqua
	pea.l	text_c8
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#2,d1			;palet=2
	move.l	#%00000_11111_00000_1,d2	;color=red(odd)
	IOCS	_GPALET
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(odd)
	pea.l	text_d1
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(odd)
	pea.l	text_d1
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(odd)
	pea.l	text_d2
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_d2
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(odd)
	pea.l	text_d3
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#4,-(sp)		;graphic palet=fuchsia
	pea.l	text_d3
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(odd)
	pea.l	text_d4
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#5,-(sp)		;graphic palet=aqua
	pea.l	text_d4
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_d5
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#2,-(sp)		;graphic palet=red(odd)
	pea.l	text_d5
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_d6
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_d6
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_d7
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#4,-(sp)		;graphic palet=fuchsia
	pea.l	text_d7
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit
;
	moveq.l	#0,d1			;1st
	IOCS	_APAGE
	move.w	#3,-(sp)		;graphic palet=blue
	pea.l	text_d8
	bsr	draw_text
	addq.l	#6,sp
	moveq.l	#1,d1			;2nd
	IOCS	_APAGE
	move.w	#5,-(sp)		;graphic palet=aqua
	pea.l	text_d8
	bsr	draw_text
	addq.l	#6,sp
	bsr	wait_esc
	beq	exit



exit:
	moveq.l	#0,d1			;palet=0
	moveq.l	#-2,d2			;color=system
	IOCS	_TPALET

	moveq.l	#1,d1			;palet=1
	moveq.l	#-2,d2			;color=system
	IOCS	_TPALET

	IOCS	_B_CURON

	move.l	(sp)+,d1
	IOCS	_CRTMOD

	DOS	_EXIT



wait_esc:
@@:	IOCS	_B_KEYINP
	tst.b	d0
	beq	@b
	cmp.b	#27,d0
	rts



draw_text:
	link.w	a6,#0
;<8+4(a6).w:graphic palet
;<8+0(a6).l:text
	movem.l	d1-d7/a0-a5,-(sp)

	move.w	#%00000_00000_00000_0,-(sp)	;palet=black
	move.w	#256,-(sp)		;height=256
	move.w	#256,-(sp)		;width=256
	move.w	#0,-(sp)		;y=0
	move.w	#0,-(sp)		;x=0
	movea.l	sp,a1
	IOCS	_FILL
	lea.l	10(sp),sp

	move.w	#1<<8|0,-(sp)		;font size=16, angle=0
	move.w	8+4(a6),-(sp)		;palet
	move.w	#8<<8|8,-(sp)		;scale=8x8
	move.l	8+0(a6),-(sp)		;text
	move.w	#64,-(sp)		;y=64
	move.w	#0,-(sp)		;x=0
	movea.l	sp,a1
	IOCS	_SYMBOL
	lea.l	14(sp),sp

	movem.l	(sp)+,d1-d7/a0-a5
	unlk	a6
	rts



copy_text:
	link.w	a6,#0
;<8+0(a6).w:plane select
	movem.l	d1-d7/a0-a5,-(sp)

	moveq.l	#0,d1			;BG text area=0
	move.l	#0<<15|0<<14|0<<8|0,d2	;hrev=0, vrev=0, palet block=0, pattern number=0
	IOCS	_BGTEXTCL

	moveq.l	#3,d1
1:	move.w	#$0000,-(sp)		;line style
	move.w	#256,-(sp)		;height=256
	move.w	#256,-(sp)		;width=256
	move.w	#0,-(sp)		;y=0
	move.w	#0,-(sp)		;x=0
	move.w	d1,-(sp)		;plane select
	movea.l	sp,a1
	IOCS	_TXFILL
	lea.l	12(sp),sp
	dbra	d1,1b

	moveq.l	#0,d6			;y
6:	moveq.l	#0,d5			;x
5:
	clr.w	-(sp)			;buffer
	move.w	d6,-(sp)		;y
	move.w	d5,-(sp)		;x
	movea.l	sp,a1
	IOCS	_POINT
	tst.w	4(sp)
	addq.l	#6,sp
	beq	8f

	moveq.l	#0,d1			;BG text area=0
	move.l	d5,d2			;x
	lsr.w	#3,d2			;BG x
	move.l	d6,d3			;y
	lsr.w	#3,d3			;BG y
	move.l	#0<<15|0<<14|1<<8|0,d4	;hrev=0, vrev=0, palet block=1, pattern number=0
	IOCS	_BGTEXTST

	moveq.l	#3,d1
1:	move.w	8+0(a6),d0		;plane select
	btst.l	d1,d0
	beq	2f
	move.w	#$FFFF,-(sp)		;line style
	move.w	#8,-(sp)		;height=8
	move.w	#8,-(sp)		;width=8
	move.w	d6,-(sp)		;y
	move.w	d5,-(sp)		;x
	move.w	d1,-(sp)		;plane select
	movea.l	sp,a1
	IOCS	_TXFILL
	lea.l	12(sp),sp
2:	dbra	d1,1b

8:	addq.w	#8,d5
	cmp.w	#256,d5
	blo	5b
	addq.w	#8,d6
	cmp.w	#256,d6
	blo	6b

	movem.l	(sp)+,d1-d7/a0-a5
	unlk	a6
	rts



sp_pat0:
	.dcb.l	8*4,$00000000		;top left, bottom left, top right, bottom right

text_a1:	.dc.b	'A1',$89,$A9,0		;yellow
text_a2:	.dc.b	'A2',$90,$D4,0		;red
text_b1:	.dc.b	'B1',$90,$D4,0		;red
text_b2:	.dc.b	'B2',$90,$D4,0		;red
text_b3:	.dc.b	'B3',$8E,$87,0		;purple
text_b4:	.dc.b	'B4',$8E,$87,0		;purple
text_c1:	.dc.b	'C1',$90,$D4,0		;red
text_c2:	.dc.b	'C2',$90,$D4,0		;red
text_c3:	.dc.b	'C3',$90,$D4,0		;red
text_c4:	.dc.b	'C4',$90,$D4,0		;red
text_c5:	.dc.b	'C5',$90,$C2,0		;blue
text_c6:	.dc.b	'C6',$90,$C2,0		;blue
text_c7:	.dc.b	'C7',$90,$85,0		;aqua
text_c8:	.dc.b	'C8',$90,$85,0		;aqua
text_d1:	.dc.b	'D1',$8E,$87,0		;purple
text_d2:	.dc.b	'D2',$8E,$87,0		;purple
text_d3:	.dc.b	'D3',$8A,$44,0		;gray
text_d4:	.dc.b	'D4',$8A,$44,0		;gray
text_d5:	.dc.b	'D5',$8E,$87,0		;purple
text_d6:	.dc.b	'D6',$8E,$87,0		;purple
text_d7:	.dc.b	'D7',$8A,$44,0		;gray
text_d8:	.dc.b	'D8',$8A,$44,0		;gray
	.even



	.end

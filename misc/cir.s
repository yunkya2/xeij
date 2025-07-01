;========================================================================================
;  cir.s
;  Copyright (C) 2003-2019 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	マザーボードコプロセッサのCIRを読み書きする簡易ツール
;
;	> cir オフセット .またはデータ …
;
;	実行例はCIRのソースコードの注釈を参照
;
;----------------------------------------------------------------

	.include	doscall.mac

	.text

	clr.l	-(sp)
	DOS	_SUPER
	move.l	d0,(sp)

	cmpi.b	#6,$0CBC.w
	bne	9f			;not MC68060

	lea.l	1(a2),a0

	bsr	stoh			;offset
	bcs	9f
	cmp.l	#31,d0
	bhi	9f

;read word
;	$00(response)
;	$04(save)
;	$06(restore)
;	$08(operation word)
;	$14(register select)
;read long
;	$10(operand)
;	$1C(operand address)
;write word
;	$02(control)
;	$06(restore)
;	$08(operation word)
;	$0A(command)
;	$0E(condition)
;write long
;	$10(operand)
;	$18(instruction address)
;	$1C(operand address)

;		  00000000000000001111111111111111
;		  0123456789ABCDEF0123456789ABCDEF
	move.l	#%10101010101000101000100010001000,d1
	lsl.l	d0,d1
	bpl	9f			;cannot access

;		  00000000000000001111111111111111
;		  0123456789ABCDEF0123456789ABCDEF
	move.l	#%10001010100000001000100000001000,d1
	lsl.l	d0,d1
	smi.b	d2			;can read

;		  00000000000000001111111111111111
;		  0123456789ABCDEF0123456789ABCDEF
	move.l	#%00100010101000101000000010001000,d1
	lsl.l	d0,d1
	smi.b	d3			;can write

;		  00000000000000001111111111111111
;		  0123456789ABCDEF0123456789ABCDEF
	move.l	#%00000000000000001000000010001000,d1
	lsl.l	d0,d1
	smi.b	d4			;long

	.cpu	68060

	movea.l	a0,a2
	lea.l	$00022000,a1
	adda.l	d0,a1

	moveq.l	#7,d0
	movec.l	d0,sfc
	movec.l	d0,dfc

1:	move.b	(a2)+,d1
	beq	8f
	cmp.b	#' ',d1
	beq	1b
	cmp.b	#9,d1
	beq	1b
	cmp.b	#'.',d1
	bne	4f
;read
	tst.b	d2
	beq	8f			;cannot read
	tst.b	d4
	bne	2f			;read long
;read word
	moves.w	(a1),d0
	lea.l	buffer(pc),a0
	bsr	htos4
	bra	3f

;read long
2:	moves.l	(a1),d0
	lea.l	buffer(pc),a0
	bsr	htos8
3:	move.b	#' ',(a0)+
	sf.b	(a0)
	pea.l	buffer(pc)
	DOS	_PRINT
	addq.l	#4,sp
	bra	1b

;write
4:	subq.l	#1,a2
	movea.l	a2,a0
	bsr	stoh			;data
	bcs	8f
	movea.l	a0,a2
	tst.b	d3
	beq	8f			;cannot write
	tst.b	d4
	bne	5f			;write long
;write word
	moves.w	d0,(a1)
	bra	1b

;write long
5:	moves.l	d0,(a1)
	bra	1b

8:	pea.l	crlf
	DOS	_PRINT
	addq.l	#4,sp

	.cpu	68000

9:	DOS	_SUPER
	addq.l	#4,sp

	DOS	_EXIT

crlf:
	.dc.b	13,10,0
	.even

	.bss

buffer:
	.ds.b	1024

	.text

htos4:
	movem.l	d1-d2,-(sp)
	moveq.l	#4-1,d2
1:	rol.w	#4,d0
	moveq.l	#$0F,d1
	and.b	d0,d1
	move.b	2f(pc,d1.w),(a0)+
	dbra	d2,1b
	sf.b	(a0)
	movem.l	(sp)+,d1-d2
	rts

htos8:
	movem.l	d1-d2,-(sp)
	moveq.l	#8-1,d2
1:	rol.l	#4,d0
	moveq.l	#$0F,d1
	and.b	d0,d1
	move.b	2f(pc,d1.w),(a0)+
	dbra	d2,1b
	sf.b	(a0)
	movem.l	(sp)+,d1-d2
	rts

2:	.dc.b	'0123456789ABCDEF'

stoh:
	movem.l	d1,-(sp)
	moveq.l	#0,d0
1:	move.b	(a0)+,d1
	cmp.b	#' ',d1
	beq	1b
	cmp.b	#9,d1
	beq	1b
	tst.b	d1
	beq	2f
	cmp.b	#'0',d1
	blo	2f
	cmp.b	#'9',d1
	bls	4f
	and.b	#$DF,d1
	cmp.b	#'A',d1
	blo	2f
	cmp.b	#'F',d1
	bls	3f
2:	move.w	#1,ccr
	bra	7f

3:	subq.b	#'A'-('9'+1),d1
4:	sub.b	#'0',d1
	cmp.l	#$0FFFFFFF,d0
	bhi	2b
	lsl.l	#4,d0
	or.b	d1,d0
5:	move.b	(a0)+,d1
	cmp.b	#'0',d1
	blo	6f
	cmp.b	#'9',d1
	bls	4b
	and.b	#$DF,d1
	cmp.b	#'A',d1
	blo	6f
	cmp.b	#'F',d1
	bls	3b
6:	tst.l	d0
7:	subq.l	#1,a0
	movem.l	(sp)+,d1
	rts


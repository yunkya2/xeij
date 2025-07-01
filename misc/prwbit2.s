;========================================================================================
;  prwbit2.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;--------------------------------------------------------------------------------
;スプライトスクロールレジスタの4ワード目(プライオリティ)のビット2の動作を確認します
;--------------------------------------------------------------------------------
PALET_BLOCK	equ	8
	.include	doscall.mac
	.include	iocscall.mac
	clr.l	-(sp)
	DOS	_SUPER
	move.l	d0,(sp)
	moveq.l	#2,d1			;256x256
	IOCS	_CRTMOD
	IOCS	_SP_INIT
	IOCS	_SP_ON
	move.l	#0,d1			;バックグラウンド0
	move.l	#0,d2			;テキストエリア0
	move.l	#1,d3			;表示あり
	IOCS	_BGCTRLST
	move.l	#1,d1			;バックグラウンド1
	move.l	#1,d2			;テキストエリア1
	move.l	#1,d3			;表示あり
	IOCS	_BGCTRLST
;青1
	move.l	#1,d1			;パレットコード1
	move.l	#PALET_BLOCK,d2		;パレットブロック
	move.l	#$003E,d3		;カラーコード青
	IOCS	_SPALET
;赤2
	move.l	#2,d1			;パレットコード2
	move.l	#PALET_BLOCK,d2		;パレットブロック
	move.l	#$07C0,d3		;カラーコード赤
	IOCS	_SPALET
;緑3
	move.l	#3,d1			;パレットコード3
	move.l	#PALET_BLOCK,d2		;パレットブロック
	move.l	#$F800,d3		;カラーコード緑
	IOCS	_SPALET
;明るい灰色15
	move.l	#15,d1			;パレットコード15
	move.l	#PALET_BLOCK,d2		;パレットブロック
	move.l	#%10101_10101_10101_0,d3	;カラーコード明るい灰色
	IOCS	_SPALET
;パターン1
	move.l	#1,d1			;パターン1
	move.l	#1,d2			;16x16
	lea.l	pattern_1,a1		;パターンデータ1
	IOCS	_SP_DEFCG
;パターン2
	move.l	#2,d1			;パターン2
	move.l	#1,d2			;16x16
	lea.l	pattern_2,a1		;パターンデータ2
	IOCS	_SP_DEFCG
;パターン3
	move.l	#3,d1			;パターン3
	move.l	#1,d2			;16x16
	lea.l	pattern_3,a1		;パターンデータ3
	IOCS	_SP_DEFCG
;バックグラウンド0
	move.l	#0,d1			;テキストエリア0
	move.l	#0,d2			;X座標
	move.l	#2,d3			;Y座標
	move.l	#PALET_BLOCK<<8|4*1,d4	;パレットブロック,パターン1
@@:
	IOCS	_BGTEXTST
	addq.l	#1,d2
	cmp.l	#16,d2
	blo	@b
;バックグラウンド1
	move.l	#1,d1			;テキストエリア1
	move.l	#0,d2			;X座標
	move.l	#3,d3			;Y座標
	move.l	#PALET_BLOCK<<8|4*2,d4	;パレットブロック,パターン2
@@:
	IOCS	_BGTEXTST
	add.l	#1,d2
	cmp.l	#16,d2
	blo	@b
;スプライト
	move.l	#1,d1			;スプライト1
	move.l	#16,d2			;X座標
	move.l	#32+4,d3		;Y座標
	move.l	#PALET_BLOCK<<8|3,d4	;パレットブロック、パターン3
	move.l	#0,d5			;プライオリティ
@@:
  .if 0
	IOCS	_SP_REGST
  .else
	movem.l	d1/a0,-(sp)
	lea.l	$00EB0000,a0
	lsl.w	#3,d1
	movem.w	d2-d5,(a0,d1.w)
	movem.l	(sp)+,d1/a0
  .endif
	add.l	#1,d1
	add.l	#16,d2
	add.l	#1,d5
	cmp.l	#8,d5
	blo	@b
	DOS	_SUPER
	addq.l	#4,sp
	DOS	_EXIT
pattern_1:
  .rept 8
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$11001100
	.dc.l	$11001100
  .endm
pattern_2:
  .rept 8
	.dc.l	$00220022
	.dc.l	$00220022
	.dc.l	$22002200
	.dc.l	$22002200
  .endm
pattern_3:
  .rept 4
	.dc.l	$00003333
	.dc.l	$00003333
	.dc.l	$00003333
	.dc.l	$00003333
	.dc.l	$33330000
	.dc.l	$33330000
	.dc.l	$33330000
	.dc.l	$33330000
  .endm

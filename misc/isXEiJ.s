;========================================================================================
;  isXEiJ.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	isXEiJ.x
;		XEiJ上で動作しているか調べます。
;
;	最終更新
;		2024-08-08
;
;	作り方
;		has060 -i include -o isXEiJ.o -w isXEiJ.s
;		lk -o isXEiJ.x isXEiJ.o
;
;	使い方
;		>isXEiJ
;
;	終了コード
;		0	XEiJではない
;		1	XEiJ
;
;----------------------------------------------------------------

	.include	doscall.mac

;XEiJか調べる
;>d0.l:0=XEiJではない,1=XEiJ
_isXEiJ::
	clr.l	-(sp)			;書き込む場所
	move.w	#4,-(sp)		;サイズ。ロングワード
	pea.l	2(sp)			;書き込むアドレス。書き込む場所
	move.l	#$00E9F03C,-(sp)	;読み出すアドレス。HFSのROMの末尾
	DOS	_BUS_ERR		;ROMの内容をコピーする
	lea.l	10(sp),sp
	cmpi.l	#'JHFS',(sp)+		;確認する
	seq.b	-(sp)			;$00=読み出せなかった/不一致,$FF=一致
	moveq.l	#1,d0
	and.b	(sp)+,d0		;0=XEiJではない,1=XEiJ
	rts

;開始位置
start:
;空白を読み飛ばす
	addq.l	#1,a2			;a2=コマンドライン
	moveq.l	#0,d0
10:	move.b	(a2)+,d0
	beq	20f			;引数がない。XEiJか調べる
	cmpi.b	#' ',d0
	beq	10b
	cmpi.b	#9,d0
	beq	10b
	bra	40f			;文法エラー。使用法を表示して終了

;XEiJか調べる
20:	bsr	_isXEiJ
;結果を表示して終了コードで返す
	move.w	d0,-(sp)		;0=XEiJではない,1=XEiJ
	lea.l	no(pc),a0		;XEiJではありません
	beq	30f
	lea.l	yes(pc),a0		;XEiJです
30:	move.l	a0,-(sp)		;XEiJではありません/XEiJです
	DOS	_PRINT
	addq.l	#4,sp
	DOS	_EXIT2

;使用法を表示して終了する
40:	pea.l	usage(pc)		;使用法
	DOS	_PRINT
	move.w	#-1,(sp)
	DOS	_EXIT2

usage:	.dc.b	'isXEiJ.x',13,10
	.dc.b	'  XEiJか調べます',13,10
	.dc.b	'  使用法: isXEiJ',13,10
	.dc.b	'  終了コード: 0=XEiJではない 1=XEiJ',13,10,0
no:	.dc.b	'XEiJではありません',13,10,0
yes:	.dc.b	'XEiJです',13,10,0

	.end	start

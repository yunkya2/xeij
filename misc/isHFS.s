;========================================================================================
;  isHFS.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	isHFS.x
;		カレントドライブまたは指定されたドライブがHFSか調べます。
;
;	最終更新
;		2024-08-08
;
;	作り方
;		has060 -i include -o isHFS.o -w isHFS.s
;		lk -o isHFS.x isHFS.o
;
;	使い方
;		>isHFS [ドライブ名]
;		A: … Z:
;		a: … z:
;			ドライブ名
;		@:
;			カレントドライブ
;		省略時はカレントドライブ
;
;	終了コード
;		0	HFSではない
;		1	HFS
;
;----------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac

;ドライブがHFSか調べる
;<(sp).l:ドライブ番号。0=カレント,1=A:,…,26=Z:
;>d0.l:0=HFSではない,1=HFS
_isHFS::
	move.l	a1,-(sp)
	lea.l	-94(sp),sp		;DPBテーブルの領域を確保する
;DPBテーブルを取り出す
	move.l	sp,-(sp)		;DPBテーブルのアドレス
	move.w	4+94+4+4+2(sp),-(sp)	;ドライブ番号。0=カレント,1=A:,…,26=Z:
	DOS	_GETDPB
	addq.l	#6,sp
	tst.l	d0
	bmi	10f			;取り出せなかった
;デバイスドライバへ進む
	lea.l	18(sp),a1		;デバイスドライバのアドレスのアドレス
	IOCS	_B_LPEEK
	movea.l	d0,a1			;デバイスドライバのアドレス
;デバイス名を確認する
	lea.l	14(a1),a1		;デバイス名のアドレス
	IOCS	_B_LPEEK
	cmp.l	#$01_000000+'XEI',d0
	bne	10f			;違う
	IOCS	_B_LPEEK
	cmp.l	#'JHFS',d0
	bne	10f			;違う
;結果を返す
	moveq.l	#1,d0			;HFS
	bra	20f

10:	moveq.l	#0,d0			;HFSではない
20:	lea.l	94(sp),sp
	movea.l	(sp)+,a1
	rts

;開始位置
start:
;空白を読み飛ばす
	addq.l	#1,a2			;a2=コマンドライン
	moveq.l	#0,d0
10:	move.b	(a2)+,d0
	beq	20f			;引数がない。カレントドライブを調べる
	cmpi.b	#' ',d0
	beq	10b			;空白を読み飛ばす
	cmpi.b	#9,d0
	beq	10b			;空白を読み飛ばす
;ドライブ名を読み取る
	cmp.b	#'@',d0
	beq	20f			;@:。カレントドライブを調べる
	and.b	#$DF,d0			;大文字化する
	sub.b	#'A',d0			;'A',…,'Z'を0=A:,…,25=Z:にする
	blo	50f			;文法エラー。使用法を表示して終了する
	cmp.b	#'Z'-'A',d0
	bhi	50f			;文法エラー。使用法を表示して終了する
	move.l	d0,d1			;d1=ドライブ番号。0=A:,…,25=Z:
	bra	30f			;ドライブがHFSか調べる

;カレントドライブを調べる
20:	DOS	_CURDRV			;カレントドライブを取り出す
	move.l	d0,d1			;d1=ドライブ番号。0=A:,…,25=Z:
;ドライブがHFSか調べる
30:	addq.b	#1,d1			;d1=ドライブ番号。1=A:,…,26=Z:
	move.l	d1,-(sp)
	bsr	_isHFS			;ドライブがHFSか調べる
	addq.l	#4,sp
;結果を表示して終了コードで返す
	move.w	d0,-(sp)		;0=HFSではない,1=HFS
	lea.l	no(pc),a0		;:はHFSではありません
	beq	40f
	lea.l	yes(pc),a0		;:はHFSです
40:	pea.l	drive(pc)		;ドライブ
	DOS	_PRINT
	moveq.l	#'A'-1,d0
	add.b	d1,d0			;ドライブ名。'A',…,'Z'
	move.w	d0,(sp)
	DOS	_PUTCHAR
	move.l	a0,(sp)			;:はHFSではありません/:はHFSです
	DOS	_PRINT
	addq.l	#4,sp
	DOS	_EXIT2

;使用法を表示して終了する
50:	pea.l	usage(pc)		;使用法
	DOS	_PRINT
	move.w	#-1,(sp)
	DOS	_EXIT2

usage:	.dc.b	'isHFS.x',13,10
	.dc.b	'  ドライブがHFSか調べます',13,10
	.dc.b	'  使用法: isHFS [ドライブ名]',13,10
	.dc.b	'  終了コード: 0=HFSではない 1=HFS',13,10,0
drive:	.dc.b	'ドライブ',0
no:	.dc.b	':はHFSではありません',13,10,0
yes:	.dc.b	':はHFSです',13,10,0

	.end	start

;========================================================================================
;  vperiod.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;	vperiod.x
;	垂直周期(垂直同期信号の周期)を計測します
;----------------------------------------------------------------------------------------

TITLE		reg	'vperiod.x (2024-02-17)'

	.include	control2.mac
	.include	doscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac

;グローバルレジスタ
dZERO	reg	d7
	moveq.l	#0,dZERO
aTCDCR	reg	a6
	lea.l	MFP_TCDCR,aTCDCR

;スーパーバイザモード
	supervisormode

;割り込み禁止
	di

;タイマ保存
	move.b	MFP_IERB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	MFP_TCDCR-MFP_TCDCR(aTCDCR),-(sp)

;タイマ設定
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み禁止
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み停止。IPRBクリア

;カウント停止
	move.b	dZERO,(aTCDCR)		;Timer-C/Dカウント停止
	do
	while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ

;V-DISPの1→0を待つ
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;?→1を待つ
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;1→0を待つ

;カウント開始
	moveq.l	#0,d2			;neg(TCDR)のbit7の1→0の回数
	moveq.l	#0,d3			;前回のneg(TCDR)
	move.b	dZERO,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタクリア
	move.b	dZERO,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
	move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/Dカウント開始
					;Timer-Cは1/200プリスケール(50us)
					;Timer-Dは1/4プリスケール(1us)

;V-DISPの1→0を待つ
	do
		moveq.l	#0,d0
		sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;neg(TCDR)
		eor.b	d0,d3
		ifand	<>,mi,<tst.b d0>,pl	;neg(TCDR)のbit7が1→0
			addq.w	#1,d2			;数える
		endif
		move.b	d0,d3
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;V-DISPの?→1を待つ
	do
		moveq.l	#0,d0
		sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;neg(TCDR)
		eor.b	d0,d3
		ifand	<>,mi,<tst.b d0>,pl	;neg(TCDR)のbit7が1→0
			addq.w	#1,d2			;数える
		endif
		move.b	d0,d3
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;V-DISPの1→0を待つ

;カウント停止
	move.b	dZERO,(aTCDCR)		;Timer-C/Dカウント停止
	do
	while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ

;タイマ取得
	moveq.l	#0,d0
	moveq.l	#0,d1
	sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-Cカウント数
	sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-Dカウント数(オーバーフローあり)
	eor.b	d0,d3
	ifand	<>,mi,<tst.b d0>,pl	;neg(TCDR)のbit7が1→0
		addq.w	#1,d2			;数える
	endif

;タイマ復元
	move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタ復元
	move.b	dZERO,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
	move.b	(sp)+,(aTCDCR)
	move.b	(sp)+,MFP_IMRB-MFP_TCDCR(aTCDCR)
	move.b	(sp)+,MFP_IERB-MFP_TCDCR(aTCDCR)

;割り込み許可
	ei

;カウンタ合成
	mulu.w	#50,d0
	if	<cmp.b d1,d0>,hi
		add.w	#256,d0
	endif
	move.b	d1,d0
	mulu.w	#50*256,d2
	add.l	d2,d0			;垂直周期(us)
	move.l	d0,d1

;ユーザモード
	usermode

;結果を表示する
	lea.l	buffer(pc),a0
	leastrdata	<TITLE,13,10,'obs_VP='>,a1
	bsr	strcpy
	move.l	d1,d0
	bsr	utos
	bsr	crlf
	lea.l	buffer(pc),a0
	bsr	print

;終了
	DOS	_EXIT

	.bss
buffer:
	.ds.b	256
	.text



;----------------------------------------------------------------
;改行をコピーする
;<a0.l:コピー先
;>a0.l:コピー先の0の位置
crlf::
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;文字列を表示する
;<a0.l:文字列
print::
	push	d0
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts

;----------------------------------------------------------------
;文字列をコピーする
;<a0.l:コピー先
;<a1.l:コピー元
;>a0.l:コピー先の0の位置
;>a1.l:コピー元の0の次の位置
strcpy::
	do
		move.b	(a1)+,(a0)+
	while	ne			;0でなければ繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	rts

;----------------------------------------------------------------
;文字列の長さを数える
;<a0.l:文字列
;>d0.l:長さ
strlen::
	move.l	a0,d0			;d0=先頭
	do
		tst.b (a0)+
	while	ne			;0でなければ繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る。a0=末尾
	exg.l	d0,a0			;d0=末尾,a0=先頭
	sub.l	a0,d0			;d0=末尾-先頭=長さ
	rts

;----------------------------------------------------------------
;32ビット符号なし整数を10進数の文字列に変換する
;<d0.l:符号なし整数
;<a0.l:バッファ。10進数の文字列の先頭
;>a0.l:10進数の文字列の末尾の0の位置
utos::
	if	<tst.l d0>,eq		;0
		move.b	#'0',(a0)+
	else				;0以外
		push	d0-d2/a1
		lea.l	utos_table(pc),a1
		do
			move.l	(a1)+,d1
		while	<cmp.l d1,d0>,lo	;引けるところまで進む。ゼロサプレス
		do
			moveq.l	#'0'-1,d2
			do
				addq.b	#1,d2
				sub.l	d1,d0
			while	hs			;引ける回数を数える
			move.b	d2,(a0)+
			add.l	d1,d0			;引き過ぎた分を加え戻す
			move.l	(a1)+,d1
		while	ne
		pop
	endif
	clr.b	(a0)
	rts

utos_table::
	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0




;========================================================================================
;  zkeytest.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	zkeytest.x
;		ZキーボードLED制御のテスト
;
;	最終更新
;		2023-04-15
;
;	作り方
;		has060 -i include -o zkeytest.o -w zkeytest.s
;		lk -o zkeytest.x zkeytest.o
;
;	使い方
;		zkeytest.x
;
;	更新履歴
;		2023-04-15
;			初版。
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac

	.text

;定数
N	equ	55			;輝度の数
dCOUNT	reg	d7			;ループカウンタ。0～2*N-1
aGPDR	reg	a4			;MFP GPDR
aFILTER	reg	a5			;カウンタ→輝度変換テーブル
aPORT	reg	a6			;Zキーボード制御I/Oポート
	lea.l	MFP_GPDR,aGPDR
	lea.l	brightness_filter,aFILTER
	lea.l	$00E9F040,aPORT

;スーパーバイザモード
	supervisormode

;設定を保存する
	lea.l	port_temporary,a0
	movea.l	aPORT,a1
	moveq.l	#9-1,d1
	for	d1
		move.b	(a1)+,(a0)+
	next

;プログラマブルモードに切り替える
	bset.b	#0,8(aPORT)

;ループ開始
	clr.w	dCOUNT
	do

	;ループカウンタから輝度を作る
		if	<cmp.w #N,dCOUNT>,lo	;0～N-1
			move.w	dCOUNT,d1	;0～N-1
		else				;N～2*N-1
			move.w	#2*N-1,d1
			sub.w	dCOUNT,d1	;N-1～0
		endif
		move.b	(aFILTER,d1.w),d0	;d0.b=輝度

	;輝度を設定する
		movea.l	aPORT,a0
		moveq.l	#7-1,d1
		for	d1
			move.b	d0,(a0)+
		next

	;送信する
		bset.b	#1,8(aPORT)

	;インクリメント
		addq.w	#1,dCOUNT
		if	<cmp.w #N*2,dCOUNT>,eq
			moveq.l	#0,dCOUNT
		endif

	;垂直帰線期間を待つ
		do
		while	<btst.b #MFP_G_VDISP_BIT,(aGPDR)>,eq
		do
		while	<btst.b #MFP_G_VDISP_BIT,(aGPDR)>,ne

	;キー入力を待つ
		bsr	inkey0
	while	eq

;設定を復元する
	movea.l	aPORT,a0
	lea.l	port_temporary,a1
	moveq.l	#9-1,d1
	for	d1
		move.b	(a1)+,(a0)+
	next

;ユーザモード
	usermode

;終了
	DOS	_EXIT

brightness_filter:
k = 0
  .rept N
	.dc.b	k*k*255/((N-1)*(N-1))
k = k+1
  .endm
	.even

	.bss
	.even
port_temporary:
	.ds.b	9
	.text

;----------------------------------------------------------------
;文字コードが0でないキーを入力する。押されていなくても待たない
;>d0.l:文字コード。0=押されていない
inkey0::
	dostart
		IOCS	_B_KEYINP		;キーバッファから取り除く
		break	<tst.b d0>,ne		;文字コードが0でないキーが押されたとき終了
	start
		IOCS	_B_KEYSNS		;キーバッファを先読みする
	while	<tst.l d0>,ne		;何か押されているとき繰り返す
	and.l	#$000000FF,d0		;文字コード
	rts


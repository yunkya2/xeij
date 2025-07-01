;========================================================================================
;  spr256test.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	spr256test.x
;		XEiJのスプライト256枚表示機能の動作を確認します。
;		他のエミュレータでもスプライト256枚表示機能があれば動くかも知れません。
;		X68000実機では動きません。
;
;	最終更新
;		2023-02-09
;
;	作り方
;		has060 -i include -o spr256test.o -w spr256test.s
;		lk -o spr256test.x spr256test.o
;
;	使い方
;		XEiJの改造メニューでスプライト256枚表示をONにします。
;		XEiJの改造メニューでラスタあたりのスプライトの枚数を256に変更します。
;		必要ならばリセットします。
;		spr256test.xを実行します。
;		何かキーを押すと終了します。
;
;	更新履歴
;		2023-02-09
;			初版。
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	vicon.equ

;開始

;512x512
	moveq.l	#0,d1
	IOCS	_CRTMOD

;カーソルOFF
	IOCS	_B_CUROFF

;スーパーバイザモード
	supervisormode

;スプライト初期化
	IOCS	_SP_INIT

;スプライト128～255をクリア
	lea.l	$00EB0000+8*128,a0
	moveq.l	#0,d0
	moveq.l	#128-1,d1
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;スプライトON
	IOCS	_SP_ON

;パレットを設定する
;	パレットコード$x0は黒。パレットコード$x1～$xFの240色を用いる
;	n=0～239
;	t=n/240
;	H=floor(192*t)
;	S=31
;	V=31	floor(15+8*cos(2*pi*t)+0.5)
	lea.l	VICON_TSPALET,a0	;パレットレジスタ
	suba.l	a1,a1			;a1=n
	do
		clr.w	(a0)+			;パレットコード$x0は黒
		moveq.l	#15-1,d7		;パレットコード$x1～$xF
		for	d7
			move.l	#240,d0
			FPACK	__LTOD			;d0-d1=240
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=240
			move.l	a1,d0
			FPACK	__LTOD			;d0-d1=n
			FPACK	__DDIV			;d0-d1=n/240=t
			move.l	d0,d4
			move.l	d1,d5			;d4-d5=t
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=t
			move.l	#192,d0
			FPACK	__LTOD			;d0-d1=192
			FPACK	__DMUL			;d0-d1=192*t
			FPACK	__DFLOOR		;H=floor(192*t)
			FPACK	__DTOL
			move.l	d0,d6
			swap.w	d6
			move.w	#31.shl.8,d6		;S=31
			move.l	d4,d0
			move.l	d5,d1			;d0-d1=t
			FPACK	__NPI			;d0-d1=pi*t
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=pi*t
			move.l	#2*15,d0
			FPACK	__LTOD			;d0-d1=2*15
			FPACK	__DMUL			;d0-d1=2*pi*10*t
			FPACK	__COS			;d0-d1=cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=cos(2*pi*t)
			moveq.l	#8,d0
			FPACK	__LTOD			;d0-d1=8
			FPACK	__DMUL			;d0-d1=8*cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=8*cos(2*pi*t)
			moveq.l	#15,d0
			FPACK	__LTOD			;d0-d1=15
			FPACK	__DADD			;d0-d1=15+8*cos(2*pi*t)
			move.l	#$3FE00000,d2
			moveq.l	#$00000000,d3		;d2-d3=0.5
			FPACK	__DADD			;d0-d1=15+8*cos(2*pi*t)+0.5
			FPACK	__DFLOOR		;V=floor(15+8*cos(2*pi*t)+0.5)
			FPACK	__DTOL
			move.b	d0,d6
			move.l	d6,d1			;d1=H<<16|S<<8|V
			IOCS	_HSVTORGB
			move.w	d0,(a0)+
			addq.l	#1,a1			;n++
		next
	while	<cmpa.l #VICON_TSPALET+2*256,a0>,lo

;スプライトを表示する
;	スプライトパターンを定義する前に表示して定義している様子を見せる
;	スプライト番号とパターン番号は同じ
;	スプライト番号の上位4ビットをパレットブロックとする
	moveq.l	#0,d7			;スプライト番号/パターン番号
	lea.l	$00EB0000,a0		;スプライトスクロールレジスタ
	movea.l	#16,a6			;Y座標
	do
		movea.l	#16,a5			;X座標
		do
			move.w	a5,(a0)+		;X座標
			move.w	a6,(a0)+		;Y座標
			move.w	d7,d0
			and.w	#$00F0,d0		;パレットブロック
			lsl.w	#4,d0
			move.b	d7,d0			;パターン番号
			move.w	d0,(a0)+		;パレットブロック<<8|パターン番号
			move.w	#3,(a0)+		;プライオリティ
			addq.l	#1,d7			;スプライト番号
			adda.l	#16,a5			;X座標
		while	<cmpa.l #16+16*16,a5>,lo
		adda.l	#16,a6			;Y座標
	while	<cmpa.l #16+16*16,a6>,lo

;スプライトパターンを定義する
;	パターン番号0～255に漢字を定義する
;	パターン番号の下位4ビットをパレットコードとする。ただし0を1に読み替える
	move.l	#'亜',d1
	moveq.l	#8,d2
	IOCS	_FNTADR
	movea.l	d0,a6			;a6=フォントアドレス
	moveq.l	#0,d7			;d7=パターン番号
	do
		lea.l	sprbuf,a0
		moveq.l	#15,d3
		and.b	d7,d3		;パターン番号の下位4ビット
		if	eq
			moveq.l	#1,d3		;0を1に読み替える
		endif
		moveq	#16-1,d4
		for	d4
			move.b	(a6)+,d0	;左半分
			addq.l	#1,a6
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d3,d1
				endif
			next
			move.l	d1,(a0)+
		next
		lea.l	-2*16(a6),a6
		moveq	#16-1,d4
		for	d4
			addq.l	#1,a6
			move.b	(a6)+,d0	;右半分
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d3,d1
				endif
			next
			move.l	d1,(a0)+
		next
		move.l	d7,d1		;パターン番号
		moveq.l	#1,d2		;パターンサイズ
		lea.l	sprbuf,a1	;パターンデータ
		IOCS	_SP_DEFCG
		addq.l	#1,d7
	while	<cmp.l #256,d7>,lo

;軌道を作る
;	{x=3sin(t)-sin(3t/2)
;	{y=3cos(t)+cos(3t/2)　　(0≦t<4π)
;	-4<=x,y<=4
;	https://twitter.com/sukannpi2/status/860126933606047745
;	垂直55.458Hzなので1周30秒とすると垂直同期1664回で1周
;	dt=4π/1664
;	スプライトの間隔を4π/256にすると1周繋がるがテーブルを作りにくい
;	6周期遅れにするか

GAP		equ	30	;文字の間隔
ORBIT_LENGTH	equ	GAP*256	;軌道の位置の数
COEFF_N		equ	3	;3*sin(t)の3
COEFF_T		equ	13	;3*t/2の3 大きくすると角が増えて尖る
COEFF_S		equ	2	;3*t/2の2
COEFF_P		equ	4	;4*piの4
RADIUS_X	equ	50	;X方向の半径
RADIUS_Y	equ	60	;Y方向の半径

	lea.l orbit,a0

	move.l	#ORBIT_LENGTH,d0
	FPACK	__LTOD
	move.l	d0,d2		;d2-d3=ORBIT_LENGTH
	move.l	d1,d3
	moveq.l	#COEFF_P,d0
	FPACK	__LTOD
	FPACK	__NPI		;d0-d1=4*pi
	FPACK	__DDIV		;d0-d1=4*pi/ORBIT_LENGTH=dt
	movea.l	d0,a4		;a4-a5=dt
	movea.l	d1,a5

	move.l	a4,d2		;d2-d3=dt
	move.l	a5,d3
	move.l	#COEFF_T,d0
	FPACK	__LTOD		;d0-d1=3
	FPACK	__DMUL		;d0-d1=3*dt
	move.l	d0,d2		;d2-d3=3*dt
	move.l	d1,d3
	move.l	#COEFF_S,d0
	FPACK	__LTOD		;d0-d1=2
	exg.l	d0,d2		;d0-d1=3*dt
	exg.l	d1,d3		;d2-d3=2
	FPACK	__DDIV		;d0-d1=3*dt/2
	movea.l	d0,a2		;a2-a3=3*dt/2
	movea.l	d1,a3

	moveq.l	#0,d6		;d6-d7=0=t
	moveq.l	#0,d7
	moveq.l	#0,d4		;d4-d5=0=3*t/2
	moveq.l	#0,d5

	movea.l	#0,a1		;n=0..1663
	do

		moveq.l	#COEFF_N,d0
		FPACK	__LTOD		;d0-d1=3
		move.l	d0,d2		;d2-d3=3
		move.l	d1,d3
		move.l	d6,d0		;d0-d1=t
		move.l	d7,d1
		FPACK	__SIN		;d0-d1=sin(t)
		FPACK	__DMUL		;d0-d1=3*sin(t)
		move.l	d0,d2		;d2-d3=3*sin(t)
		move.l	d1,d3
		move.l	d4,d0		;d0-d1=3*t/2
		move.l	d5,d1
		FPACK	__SIN		;d0-d1=sin(3*t/2)
		exg.l	d0,d2		;d0-d1=3*sin(t)
		exg.l	d1,d3		;d2-d3=sin(3*t/2)
		FPACK	__DSUB		;d0-d1=3*sin(t)-sin(3*t/2)=x
		move.l	d0,d2		;d2-d3=x
		move.l	d1,d3
		move.l	#RADIUS_X,d0
		FPACK	__LTOD		;d0-d1=60
		FPACK	__DMUL		;d0-d1=60*x
		move.l	d0,d2		;d2-d3=60*x
		move.l	d1,d3
		move.l	#16+256-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DADD		;d0-d1=16+256-8+60*x
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8+60*x+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8+60*x+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+512,d0>,ge
			moveq.l	#0,d0
		endif
		move.w	d0,(a0)+

		moveq.l	#COEFF_N,d0
		FPACK	__LTOD		;d0-d1=3
		move.l	d0,d2		;d2-d3=3
		move.l	d1,d3
		move.l	d6,d0		;d0-d1=t
		move.l	d7,d1
		FPACK	__COS		;d0-d1=cos(t)
		FPACK	__DMUL		;d0-d1=3*cos(t)
		move.l	d0,d2		;d2-d3=3*cos(t)
		move.l	d1,d3
		move.l	d4,d0		;d0-d1=3*t/2
		move.l	d5,d1
		FPACK	__COS		;d0-d1=cos(3*t/2)
		exg.l	d0,d2		;d0-d1=3*cos(t)
		exg.l	d1,d3		;d2-d3=cos(3*t/2)
		FPACK	__DADD		;d0-d1=3*cos(t)+cos(3*t/2)=y

		move.l	d0,d2		;d2-d3=y
		move.l	d1,d3
		move.l	#RADIUS_Y,d0
		FPACK	__LTOD		;d0-d1=60
		FPACK	__DMUL		;d0-d1=60*y
		move.l	d0,d2		;d2-d3=60*y
		move.l	d1,d3
		move.l	#16+256-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DSUB		;d0-d1=16+256-8-60*y
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8-60*y+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8-60*y+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+512,d0>,ge
			moveq.l	#0,d0
		endif
		move.w	d0,(a0)+

		move.l	d6,d0		;d0-d1=t
		move.l	d7,d1
		move.l	a4,d2		;d2-d3=dt
		move.l	a5,d3
		FPACK	__DADD		;d0-d1=t+dt
		move.l	d0,d6		;d6-d7=t+dt
		move.l	d1,d7

		move.l	d4,d0		;d0-d1=3*t/2
		move.l	d5,d1
		move.l	a2,d2		;d2-d3=3*dt/2
		move.l	a3,d3
		FPACK	__DADD		;d0-d1=3*(t+dt)/2
		move.l	d0,d4		;d4-d5=3*(t+dt)/2
		move.l	d1,d5

		addq.l	#1,a1
	while	<cmpa.l #ORBIT_LENGTH,a1>,lo

;動かす
	lea.l	orbit,a4		;a4=軌道データの配列の先頭
	lea.l	4*ORBIT_LENGTH(a4),a5	;a5=軌道データの配列の末尾
	lea.l	$00EB0000,a6		;スプライト0のスプライトスクロールレジスタ
	movea.l	a4,a3			;スプライト0の軌道データの位置
	do
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;垂直空白期間を待つ
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;垂直帰線期間を待つ

		movea.l	a3,a1		;軌道データ
		movea.l	a6,a2		;スプライトスクロールレジスタ
		move.w	#256-1,d0
		for	d0
			move.l	(a1),(a2)	;軌道データをスプライトスクロールレジスタへ
			lea.l	-4*GAP(a1),a1	;軌道データの位置を6戻す
			if	<cmpa.l a4,a1>,lo
				lea.l	4*ORBIT_LENGTH(a1),a1
			endif
			addq.l	#8,a2		;次のスプライトのスプライトスクロールレジスタ
		next

		addq.l	#4,a3		;スプライト0の軌道データの位置を1進める
		if	<cmpa.l a5,a3>,hs
			lea.l	-4*ORBIT_LENGTH(a3),a3
		endif

		bsr	inkey0
	while	eq

;ユーザモード
	usermode

;768x512
;	moveq.l	#16,d1
	moveq.l	#0,d1
	IOCS	_CRTMOD

;カーソルON
	IOCS	_B_CURON

;終了
	DOS	_EXIT

;キー入力(待たない)
;>d0.l:文字コード。0=なし
inkey0:
	do
		IOCS	_B_KEYSNS
		break	<tst.l d0>,eq
		IOCS	_B_KEYINP
		and.l	#$FF,d0
	while	eq
	rts

;キー入力(待つ)
;>d0.l:文字コード
inkey1:
	do
		do
			IOCS	_B_KEYSNS
		while	<tst.l d0>,eq
		IOCS	_B_KEYINP
		and.l	#$FF,d0
	while	eq
	rts

	.bss
	.even
sprbuf:
	.ds.l	2*16
orbit:
	.ds.w	2*ORBIT_LENGTH


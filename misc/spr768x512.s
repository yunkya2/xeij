;========================================================================================
;  spr768x512.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;  spr768x512.x
;	XEiJの256枚のスプライトと4096個のパターンと768x512でスプライトを表示をテストします。
;	改造メニューの256枚のスプライトチェックボックスと4096個のパターンチェックボックスと
;	768x512でスプライトを表示チェックボックスをONにしてリセットしてから実行します。
;	何かキーを押すと終了します。
;	X68000実機では動きません。
;----------------------------------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ
	.include	vicon.equ

;開始

;画面モードを変更
	move.w	#-1,screen_mode
	moveq.l	#-1,d1
	IOCS	_CRTMOD
	if	<cmp.w #16,d0>,ne	;CRTMOD 16でないとき
		move.w	#3,-(sp)		;ファンクションキー表示なし
		move.w	#14,-(sp)
		DOS	_CONCTRL
		move.w	d0,function_mode
		clr.w	-(sp)			;768x512グラフィックなし
		move.w	#16,-(sp)
		DOS	_CONCTRL
		move.w	d0,screen_mode
		addq.l	#8,sp
	endif

;スーパーバイザモード
	supervisormode

;スプライトコントローラ初期化
	move.w	#28+4,SPRC_H_BACK_END	;水平バックポーチ終了カラム。R02+4
	move.w	#255,SPRC_H_FRONT_END	;水平フロントポーチ終了カラム。255。ウェイトは省略
	move.w	#40,SPRC_V_BACK_END	;垂直バックポーチ終了ラスタ。R06
	move.w	#%10101,SPRC_RESOLUTION	;解像度。--------|---|高解像度|垂直サイズ##|水平サイズ##
	moveq.l	#0,d0
	move.l	d0,SPRC_BG_0_X		;BG0スクロールX座標,BG0スクロールY座標
	move.l	d0,SPRC_BG_1_X		;BG1スクロールX座標,BG1スクロールY座標
	move.w	d0,SPRC_CONTROL		;コントロール。------|スプライト画面ON|---|BG1テキスト##|BG1表示ON|BG0テキスト##|BG0表示ON

;パターン4096枚定義ON
	move.w	#$0005,$00EB0812
	move.w	#$0000,$00EB0814

;スプライトをクリア
	lea.l	$00EB0000,a0
	moveq.l	#0,d0
	move.w	#256-1,d1
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;パターンをクリア
	moveq.l	#0,d0
	moveq.l	#0,d2			;バンク
	do
		move.w	d2,$00EB0814		;バンク番号
		lea.l	$00EB8000,a0
		move.w	#32768/8-1,d1
		for	d1
			move.l	d0,(a0)+
			move.l	d0,(a0)+
		next
		add.w	#$0100,d2
	while	<cmp.w #$0F00,d2>,ls

;スプライト表示ON
	move.w	#SPRC_SPRITE_ON,SPRC_CONTROL
	ori.w	#VICON_SPON_MASK,VICON_VISIBLE
	move.w	#%00_00_01_10_11_10_01_00,VICON_PRIORITY

;パレットを設定する
;	パレットコード$0xは使用しない。$x0は黒。残りの225色を用いる
;	n=0～224
;	t=n/225
;	H=floor(192*t)
;	S=31
;	V=31	floor(15+8*cos(2*pi*t)+0.5)
	lea.l	VICON_TSPALET+2*$10,a0	;パレットレジスタ。$10から
	suba.l	a1,a1			;a1=n
	do
		clr.w	(a0)+			;パレットコード$x0は黒
		moveq.l	#15-1,d7		;パレットコード$x1～$xF
		for	d7
			move.l	#225,d0
			FPACK	__LTOD			;d0d1=225
			move.l	d0,d2
			move.l	d1,d3			;d2d3=225
			move.l	a1,d0
			FPACK	__LTOD			;d0d1=n
			FPACK	__DDIV			;d0d1=n/225=t
			move.l	d0,d4
			move.l	d1,d5			;d4d5=t
			move.l	d0,d2
			move.l	d1,d3			;d2d3=t
			move.l	#192,d0
			FPACK	__LTOD			;d0d1=192
			FPACK	__DMUL			;d0d1=192*t
			FPACK	__DFLOOR		;H=floor(192*t)
			FPACK	__DTOL
			move.l	d0,d6
			swap.w	d6
			move.w	#31.shl.8,d6		;S=31
  .if 0
			move.b	#31,d6			;V=31
  .else
			move.l	d4,d0
			move.l	d5,d1			;d0d1=t
			FPACK	__NPI			;d0d1=pi*t
			move.l	d0,d2
			move.l	d1,d3			;d2d3=pi*t
			move.l	#2*15,d0
			FPACK	__LTOD			;d0d1=2*15
			FPACK	__DMUL			;d0d1=2*pi*10*t
			FPACK	__COS			;d0d1=cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2d3=cos(2*pi*t)
			moveq.l	#8,d0
			FPACK	__LTOD			;d0d1=8
			FPACK	__DMUL			;d0d1=8*cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2d3=8*cos(2*pi*t)
			moveq.l	#15,d0
			FPACK	__LTOD			;d0d1=15
			FPACK	__DADD			;d0d1=15+8*cos(2*pi*t)
			move.l	#$3FE00000,d2
			moveq.l	#$00000000,d3		;d2d3=0.5
			FPACK	__DADD			;d0d1=15+8*cos(2*pi*t)+0.5
			FPACK	__DFLOOR		;V=floor(15+8*cos(2*pi*t)+0.5)
			FPACK	__DTOL
			move.b	d0,d6
  .endif
			move.l	d6,d1			;d1=H<<16|S<<8|V
			IOCS	_HSVTORGB
			move.w	d0,(a0)+
			addq.l	#1,a1			;n++
		next
	while	<cmpa.l #VICON_TSPALET+2*256,a0>,lo

;スプライトパターンを定義する
;	パターン番号0～4095に漢字を定義する
;	パターン番号の下位8ビットを256から225に減らしてパレットコードを作る
	lea.l	conv225(pc),a3
	move.l	#'亜',d1
	moveq.l	#8,d2
	IOCS	_FNTADR
	movea.l	d0,a6			;a6=フォントアドレス
	moveq.l	#0,d7			;d7=パターン番号
	do
	;空白を読み飛ばす
		dostart
			lea.l	32(a6),a6
		start
			movea.l	a6,a0
			moveq.l	#0,d0
			moveq.l	#8-1,d6
			for	d6
				or.l	(a0)+,d0
			next
		while	eq
		if	<tst.b d7>,eq		;パターン番号が256の倍数のとき
		;スプライトを表示する
		;	スプライトパターンを定義する前に表示して定義している様子を見せる
		;	スプライト番号とパターン番号は同じ
		;	スプライト番号の上位4ビットをパレットブロックとする
			moveq.l	#0,d6			;スプライト番号/パターン番号
			lea.l	$00EB0000,a0		;スプライトスクロールレジスタ
			movea.l	#16,a4			;Y座標
			do
				movea.l	#16,a5			;X座標
				do
					move.w	a5,(a0)+		;X座標
					move.w	a4,(a0)+		;Y座標
					moveq.l	#0,d3
					move.b	d6,d3			;スプライト番号
					move.b	(a3,d3.l),d3		;パレットコード
					move.w	d7,d0			;バンク番号<<8|?
					move.b	d3,d0			;バンク番号<<8|パレットコード
					lsl.w	#4,d0			;バンク番号<<12|パレットコード<<4
					move.b	d6,d0			;バンク番号<<12|パレットブロック<<8|パターン番号
					move.w	d0,(a0)+
					move.w	#3,(a0)+		;プライオリティ
					addq.l	#1,d6			;スプライト番号
					adda.l	#16,a5			;X座標
				while	<cmpa.l #16+16*16,a5>,lo
				adda.l	#16,a4			;Y座標
			while	<cmpa.l #16+16*16,a4>,lo
		endif
		lea.l	sprbuf,a0
		moveq.l	#0,d3
		move.b	d7,d3
		move.b	(a3,d3.l),d3		;パレットコード
		and.b	#15,d3			;パレットコードの下位4bit
		moveq	#16-1,d4
		for	d4
			move.b	(a6)+,d0	;左半分
		;	not.b	d0		;反転
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
		;	not.b	d0		;反転
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
		move.w	d7,$00EB0814	;バンク番号
		moveq.l	#0,d1
		move.b	d7,d1		;パターン番号
	;	moveq.l	#1,d2		;パターンサイズ
		lea.l	sprbuf,a1	;パターンデータ
	;	IOCS	_SP_DEFCG
		lea.l	$00EB8000,a0
		lsl.w	#7,d1
		adda.l	d1,a0
		moveq.l	#64/2-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
	;
		addq.l	#1,d7
	while	<cmp.l #4096,d7>,lo

;軌道を作る
;	{x=3sin(t)-sin(3t/2)
;	{y=3cos(t)+cos(3t/2)　　(0≦t<4π)
;	-4<=x,y<=4
;	https://twitter.com/sukannpi2/status/860126933606047745
;	垂直55.458Hzなので1周30秒とすると垂直同期1664回で1周
;	dt=4π/1664
;	スプライトの間隔を4π/256にすると1周繋がるがテーブルを作りにくい
;	6周期遅れにするか

FLIP		equ	15	;バンクを切り替える間隔
GAP		equ	FLIP*2	;文字の間隔
ORBIT_LENGTH	equ	GAP*256	;軌道の位置の数
COEFF_N		equ	3	;3*sin(t)の3
COEFF_T		equ	13	;3*t/2の3 大きくすると角が増えて尖る
COEFF_S		equ	2	;3*t/2の2
COEFF_P		equ	4	;4*piの4
RADIUS_X	equ	90	;半径
RADIUS_Y	equ	60	;
CENTER_X	equ	384	;中心
CENTER_Y	equ	256	;
WIDTH		equ	768	;画面のサイズ
HEIGHT		equ	512	;

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
		move.l	#16+CENTER_X-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DADD		;d0-d1=16+256-8+60*x
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8+60*x+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8+60*x+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+WIDTH,d0>,ge
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
		move.l	#16+CENTER_Y-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DSUB		;d0-d1=16+256-8-60*y
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8-60*y+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8-60*y+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+HEIGHT,d0>,ge
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
	moveq.l	#0,d7			;バンク番号を増やすスプライトの下位4bit
	do
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;垂直表示期間を待つ
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;垂直帰線期間を待つ

	;バンク番号を増やす
		moveq.l	#5-1,d1
		for	d1
			addi.w	#$1000,4(a6,d7.w)
			add.w	#8*33,d7
			and.w	#8*(256-1),d7
		next

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

;スプライト表示OFF
	move.w	#$0000,SPRC_CONTROL	;コントロール。------|スプライト画面ON|---|BG1テキスト##|BG1表示ON|BG0テキスト##|BG0表示ON
	andi.w	#.notw.VICON_SPON_MASK,VICON_VISIBLE

;パターン4096枚定義OFF
	move.w	#$0000,$00EB0812
	move.w	#$0000,$00EB0814

;ユーザモード
	usermode

;画面モードを復元
	if	<tst.w screen_mode>,pl
		move.w	screen_mode,-(sp)
		move.w	#16,-(sp)
		DOS	_CONCTRL
		move.w	function_mode,-(sp)
		move.w	#14,-(sp)
		DOS	_CONCTRL
		addq.l	#8,sp
	endif

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

conv225:
n = 0
	.rept	256
l = (n*225+128)>>8
h = l/15
l = l-(15*h)
		.dc.b	((1+h)<<4)|(1+l)
n = n+1
	.endm

	.bss
	.even
sprbuf:
	.ds.l	2*16
orbit:
	.ds.w	2*ORBIT_LENGTH

	.even
function_mode:
	.ds.w	1
screen_mode:
	.ds.w	1

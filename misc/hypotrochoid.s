;========================================================================================
;  hypotrochoid.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;  hypotrochoid.x
;	XEiJの疑似グラフィック画面(4096個のパターンを敷き詰めたバックグラウンド)にハイポトロコイドを描きます。
;	青(S)と紫(S)はスプライト画面(BG0とBG1)、赤(T)はテキスト画面、緑(G)はグラフィック画面です。
;	改造メニューの4096個のパターンチェックボックスと768x512でスプライトを表示チェックボックスと
;	512x512でBG1を表示チェックボックスをONにしてリセットしてから実行します。
;	BREAK/CTRL+C/ESCキーで終了、動作中はその他のキーで停止。停止中はENTERキーで再開、その他のキーでコマ送りします。
;	X68000実機では動きません。
;----------------------------------------------------------------

;----------------------------------------------------------------
;ハイポトロコイド
;	定円の内側に沿って動円が転がるとき、動円に固定された点の軌跡をハイポトロコイドと呼びます。
;	定円の中心を(0,0)、半径をR、動円の半径をr、動円の中心から点までの距離をdとします。
;	定円と動円の周の長さの比から、動円が左に1周する間に動円は接線に対して右にR/r回転します。
;	同時に接線が左に1回転するので、合わせて動円は右に(R-r)/r回転します。
;	動円の中心の方向をtとすると、点の位置は((R-r)*cos(t)+d*cos((R-r)/r*t),(R-r)*sin(t)-d*sin((R-r)/r*t))となります。
;	動円が左にn周する間に動円は右に(R-r)/r*n回転します。
;	R,rが整数のとき、点が最初の位置に戻るまでの周期n0は(R-r)/r*nが整数になる最小のn、すなわちn0=r/gcd(R-r,r)です。
;	https://en.wikipedia.org/wiki/Hypotrochoid
;----------------------------------------------------------------

	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ
	.include	vicon.equ

;引数
	lea.l	1(a2),a0
	do
	;R 定円の半径
		bsr	nextword
		break	eq			;指定なし。既定値を使う
		FPACK	__STOL
		goto	cs,error		;整数がない。エラー終了
		goto	<tst.l d0>,le,error	;1より小さい。エラー終了
		goto	<cmp.l #1000000,d0>,gt,error	;1000000より大きい。エラー終了
		move.l	d0,int_R
	;r 動円の半径
		bsr	nextword
		break	eq			;指定なし。既定値を使う
		FPACK	__STOL
		goto	cs,error		;整数がない。エラー終了
		goto	<tst.l d0>,le,error	;1より小さい。エラー終了
		goto	<cmp.l #1000000,d0>,gt,error	;1000000より大きい。エラー終了
		goto	<cmp.l int_R,d0>,ge,error	;rがRと等しいかより大きい。エラー終了
		move.l	d0,int_r
	;d 動円の中心から点までの距離
		bsr	nextword
		break	eq			;指定なし。既定値を使う
		FPACK	__STOD
		goto	cs,error		;数値がない。エラー終了
		FPACK	__DTST
		goto	lt,error		;0より小さい。エラー終了
		move.l	d0,d2
		move.l	d1,d3
		move.l	#1000000,d0
		FPACK	__LTOD
		FPACK	__DCMP
		goto	lt,error		;1000000より大きい。エラー終了
		movem.l	d2-d3,dbl_d
	;f 1周(≠1周期)の点の数
		bsr	nextword
		break	eq			;指定なし。既定値を使う
		FPACK	__STOL
		goto	cs,error		;数値がない。エラー終了
		goto	<tst.l d0>,le,error	;1より小さい。エラー終了
		goto	<cmp.l #1000000,d0>,gt,error	;1000000より大きい。エラー終了
		move.l	d0,int_f
	while	f

;引数で決まる値
;R 定円の半径
	move.l	int_R,d0
	FPACK	__LTOD
	movem.l	d0-d1,dbl_R
;r 動円の半径
	move.l	int_r,d0
	FPACK	__LTOD
	movem.l	d0-d1,dbl_r
;Rr=R-r 定円の中心から動円の中心までの距離
	move.l	int_R,d0
	sub.l	int_r,d0
	move.l	d0,int_Rr
	FPACK	__LTOD
	movem.l	d0-d1,dbl_Rr
;Rrr=(R-r)/r 点の速度
;	movem.l	dbl_Rr,d0-d1
	movem.l	dbl_r,d2-d3
	FPACK	__DDIV
	movem.l	d0-d1,dbl_Rrr
;n0=r/gcd(R-r,r) 周期
	move.l	int_Rr,d0		;d0=前回の余り=R-r。0ではない
	move.l	int_r,d1		;d1=前回の除数=r。0ではない
	do
					;d0=前回の余り,d1=前回の除数
					;前回の除数→被除数,前回の余り→除数
		exg.l	d0,d1		;d0=被除数,d1=除数
		FPACK	__LMOD		;d0=余り,d1=除数
	while	<tst.l d0>,ne		;余りが0になるまで繰り返す
					;余りが0になったときの除数=gcd(R-r,r)
	move.l	int_r,d0		;d0=r
	FPACK	__LDIV			;d0=n0=r/gcd(R-r,r)
	move.l	d0,int_n0
;fn0=f*n0 n0周(=1周期)の点の数
	move.l	int_f,d0
	move.l	int_n0,d1
	FPACK	__LMUL
	move.l	d0,int_fn0
;s=RR/(R-r+d) 倍率
	movem.l	dbl_Rr,d0-d1
	movem.l	dbl_d,d2-d3
	FPACK	__DADD
	move.l	d0,d2
	move.l	d1,d3
	movem.l	dbl_RR,d0-d1
	FPACK	__DDIV
	movem.l	d0-d1,dbl_s
;f 1周(≠1周期)の点の数
	move.l	int_f,d0
	FPACK	__LTOD
	movem.l	d0-d1,dbl_f
;dt=2*pi/f 角度の増分
	moveq.l	#2,d0
	FPACK	__LTOD
	FPACK	__NPI
	movem.l	dbl_f,d2-d3
	FPACK	__DDIV
	movem.l	d0-d1,dbl_dt

;スクロールの軌道を作る
;	中心(128,256)半径(128,256)の円
orbit_length	equ	(orbit_end-orbit)/4
	move.l	#orbit_length,d0
	FPACK	__LTOD
	move.l	d0,d2			;d2d3=n
	move.l	d1,d3
	moveq.l	#2,d0
	FPACK	__LTOD
	FPACK	__NPI			;d0d1=2*pi
	FPACK	__DDIV			;d0d1=2*pi/n=dt
	movea.l	d0,a4			;a4a5=dt
	movea.l	d1,a5
	move.l	#128,d0
	FPACK	__LTOD
	movea.l	d0,a0			;a0a1=128
	movea.l	d1,a1
	move.l	#256,d0
	FPACK	__LTOD
	movea.l	d0,a2			;a2a3=256
	movea.l	d1,a3
	moveq.l	#0,d4			;d4d5=t
	moveq.l	#0,d5
	lea.l	orbit,a6
	move.w	#orbit_length-1,d7
	for	d7
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__COS			;d0d1=cos(t)
		move.l	a0,d2			;d2d3=128
		move.l	a1,d3
		FPACK	__DMUL			;d0d1=128*cos(t)
		exg.l	d0,d2			;d0d1=128
		exg.l	d1,d3			;d2d3=128*cos(t)
		FPACK	__DSUB			;d0d1=128-128*cos(t)
		FPACK	__DTOL			;d0=128-128*cos(t)
		move.w	d0,(a6)+		;x
	;
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__SIN			;d0d1=sin(t)
		move.l	a2,d2			;d2d3=256
		move.l	a3,d3
		FPACK	__DMUL			;d0d1=256*sin(t)
		FPACK	__DADD			;d0d1=256+256*sin(t)
		FPACK	__DTOL			;d0=256+256*sin(t)
		move.w	d0,(a6)+		;y
	;
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		move.l	a4,d2			;d2d3=dt
		move.l	a5,d3
		FPACK	__DADD			;d0d1=t+dt
		move.l	d0,d4			;d4d5=t+dt
		move.l	d1,d5
	next

;画面モードを変更
	move.w	#3,-(sp)		;ファンクションキー表示なし
	move.w	#14,-(sp)
	DOS	_CONCTRL
	move.w	d0,function_mode
	move.w	#1,-(sp)		;768x512グラフィックあり
	move.w	#16,-(sp)
	DOS	_CONCTRL
	move.w	d0,screen_mode
	addq.l	#8,sp

;カーソルOFF
	IOCS	_B_CUROFF

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

;テキストエリアにパターンを敷き詰める
	lea.l	$00EB4000,a0		;開始位置(0,0)
	moveq.l	#0,d4			;パターン番号上位4bit<<12
	move.w	#1<<8,d5		;パレットブロック<<8。パレットブロック1から
	moveq.l	#0,d6			;パターン番号下位8bit
	do
		moveq.l	#16-1,d3		;Y方向ループ上位16回
		for	d3
			moveq.l	#4-1,d2			;Y方向ループ下位4回
			for	d2
				moveq.l	#64-1,d1		;X方向ループ64回
				for	d1
					move.w	d4,d0			;パターン番号上位4bit<<12
					add.w	d5,d0			;パレットブロック<<8
					add.w	d6,d0			;パターン番号下位8bit
					move.w	d0,(a0)+
					addq.b	#1,d6			;パターン番号下位8bit
				next
			next
			add.w	#1<<12,d4		;パターン番号上位4bit<<12
		next
		add.w	#1<<8,d5		;パレットブロック<<8
	while	<cmp.w #2<<8,d5>,ls	;パレットブロック2まで

;スプライト表示ON
;	BG0にテキストエリア0、BG1にテキストエリア1を割り当てて表示
	move.w	#SPRC_SPRITE_ON|SPRC_BG_1_TEXT_1|SPRC_BG_1_ON|SPRC_BG_0_TEXT_0|SPRC_BG_0_ON,SPRC_CONTROL
	ori.w	#VICON_SPON_MASK,VICON_VISIBLE
	move.w	#%00_00_01_10_11_10_01_00,VICON_PRIORITY

;パレットを設定する
	movehsv	104,31,31,VICON_TSPALET+2*$11	;青。BG0。スプライトパレット$11
	movehsv	152,31,31,VICON_TSPALET+2*$21	;紫。BG1。スプライトパレット$21
	movehsv	8,31,31,VICON_TSPALET+2*1	;赤。テキスト画面。テキストパレット1
	movehsv	56,31,31,VICON_GPALET+2*1	;緑。グラフィック画面。グラフィックパレット1

;開始位置までスクロールする
	lea.l	orbit,a0
	move.w	(a0),SPRC_BG_0_X	;BG0を動かす
	move.w	2(a0),SPRC_BG_0_Y
	move.w	4*(orbit_length*1/4)(a0),SPRC_BG_1_X	;BG1を動かす
	move.w	4*(orbit_length*1/4)+2(a0),SPRC_BG_1_Y
	move.w	4*(orbit_length*2/4)(a0),CRTC_TEXT_X	;テキスト画面を動かす
	move.w	4*(orbit_length*2/4)+2(a0),CRTC_TEXT_Y
	move.w	4*(orbit_length*3/4)(a0),CRTC_GRAPHIC_X_0	;グラフィック画面を動かす
	move.w	4*(orbit_length*3/4)+2(a0),CRTC_GRAPHIC_Y_0

;文字を描く
	lea.l	moji(pc),a0		;a0=文字
	moveq.l	#2,d7			;2=S,1=T,0=G
	for	d7
	;文字コードを取り出す。SJISに限る
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.b	(a0)+,d0		;sh
		move.b	(a0)+,d1		;sl
	;94区94点の通し番号を求める
	;	((sh - (sh < 0xe0 ? 0x81 : 0xe0 - (0xa0 - 0x81))) * 188 +
	;	 (sl - (sl < 0x80 ? 0x40 : 0x80 - (0x7f - 0x40))))
		moveq.l	#$81,d2
		if	<cmp.b #$E0,d0>,hs
			moveq.l	#$E0-($A0-$81),d2
		endif
		sub.b	d2,d0
		moveq.l	#$40,d2
		if	<cmp.b #$80,d1>,hs
			moveq.l	#$80-($7F-$40),d2
		endif
		sub.b	d2,d1
		mulu.w	#188,d0
		add.w	d1,d0
	;9区から15区までないので詰める
		if	<cmp.w #94*(16-1),d0>,hs	;16区～
			sub.w	#94*(16-9),d0		;16区→9区
		endif
	;フォントアドレスを求める
		mulu.w	#3*24,d0
		add.l	#$00F40000,d0		;24x24
		movea.l	d0,a1
	;点を並べる
		moveq.l	#1,d3			;色
		move.w	#512-12,d2		;Y座標
		moveq.l	#24-1,d6		;24ライン
		for	d6
			move.w	#512-12,d1		;X座標
			moveq.l	#3-1,d5			;3バイト
			for	d5
				move.b	(a1)+,d0
				moveq.l	#8-1,d4			;8ドット
				for	d4
					add.b	d0,d0
					if	cs
						if	<cmp.w #1,d7>,hi	;2=S
							bsr	sp_pset
						elif	eq			;1=T
							bsr	tx_pset
						else				;0=G
							bsr	gr_pset
						endif
					endif
					addq.w	#1,d1			;X座標を進める
				next
			next
			sub.w	#24,d1			;X座標を戻して
			addq.w	#1,d2			;Y座標を進める
		next
	next

;ハイポトロコイドを描く
;	t=0
;	for i=1 to fn0
;		pset(floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t))),
;		     floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t))))
;		t=t+dt
;	next
	moveq.l	#0,d4			;d4d5=t
	moveq.l	#0,d5
	move.l	int_fn0,d7
	forlong	d7
		movem.l	dbl_Rrr,d0-d1		;d0d1=Rrr
		move.l	d4,d2			;d2d3=t
		move.l	d5,d3
		FPACK	__DMUL			;d0d1=Rrr*t
		movea.l	d0,a4			;a4a5=Rrr*t
		movea.l	d1,a5
		FPACK	__COS			;d0d1=cos(Rrr*t)
		movem.l	dbl_d,d2-d3		;d2d3=d
		FPACK	__DMUL			;d0d1=d*cos(Rrr*t)
		movea.l	d0,a2			;a2a3=d*cos(Rrr*t)
		movea.l	d1,a3
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__COS			;d0d1=cos(t)
		movem.l	dbl_Rr,d2-d3		;d2d3=Rr
		FPACK	__DMUL			;d0d1=Rr*cos(t)
		move.l	a2,d2			;d2d3=d*cos(Rrr*t)
		move.l	a3,d3
		FPACK	__DADD			;d0d1=Rr*cos(t)+d*cos(Rrr*t)
		movem.l	dbl_s,d2-d3		;d2d3=s
		FPACK	__DMUL			;d0d1=s*(Rr*cos(t)+d*cos(Rrr*t))
		movem.l	dbl_ox,d2-d3	;d2d3=ox
		FPACK	__DADD			;d0d1=ox+s*(Rr*cos(t)+d*cos(Rrr*t))
		FPACK	__DFLOOR		;d0d1=floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t)))
		FPACK	__DTOL			;d0=floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t)))
		movea.l	d0,a0			;a0=floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t))) X座標
	;
		move.l	a4,d0
		move.l	a5,d1			;d0d1=Rrr*t
		FPACK	__SIN			;d0d1=sin(Rrr*t)
		movem.l	dbl_d,d2-d3		;d2d3=d
		FPACK	__DMUL			;d0d1=d*sin(Rrr*t)
		movea.l	d0,a2			;a2a3=d*sin(Rrr*t)
		movea.l	d1,a3
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__SIN			;d0d1=sin(t)
		movem.l	dbl_Rr,d2-d3		;d2d3=Rr
		FPACK	__DMUL			;d0d1=Rr*sin(t)
		move.l	a2,d2			;d2d3=d*sin(Rrr*t)
		move.l	a3,d3
		FPACK	__DSUB			;d0d1=Rr*sin(t)-d*sin(Rrr*t)
		movem.l	dbl_s,d2-d3		;d2d3=s
		FPACK	__DMUL			;d0d1=s*(Rr*sin(t)-d*sin(Rrr*t))
		move.l	d0,d2			;d2d3=s*(Rr*sin(t)-d*sin(Rrr*t))
		move.l	d1,d3
		movem.l	dbl_oy,d0-d1	;d0d1=oy
		FPACK	__DSUB			;d0d1=oy-s*(Rr*sin(t)-d*sin(Rrr*t))
		FPACK	__DFLOOR		;d0d1=floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t)))
		FPACK	__DTOL			;d0=floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t)))
		movea.l	d0,a1			;a1=floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t))) Y座標
	;
		move.l	a0,d1
		move.l	a1,d2
		moveq.l	#1,d3
		bsr	sp_pset
		bsr	tx_pset
		bsr	gr_pset
	;
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		movem.l	dbl_dt,d2-d3		;d2d3=dt
		FPACK	__DADD			;d0d1=t+dt
		move.l	d0,d4			;d4d5=t+dt
		move.l	d1,d5
	next

;動かす
	lea.l	orbit,a0
	movea.l	a0,a1
	lea.l	4*(orbit_length*1/4)(a0),a2
	lea.l	4*(orbit_length*2/4)(a0),a3
	lea.l	4*(orbit_length*3/4)(a0),a4
	lea.l	orbit_end-orbit(a0),a5
	moveq.l	#0,d1			;-1=停止中,0=動作中,1=コマ送り
	dostart
		ifand	<tst.l d1>,mi,<cmp.b #13,d0>,eq	;停止中にENTERキーが押されたとき
			moveq.l	#0,d1			;動作中にする
		elif	<tst.b d0>,ne		;停止中にENTER以外のキーが押されたか、動作中に何かキーが押されたとき
			moveq.l	#1,d1			;コマ送りにする
		endif
	start
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;垂直表示期間を待つ
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;垂直帰線期間を待つ
		if	<tst.l d1>,pl		;動作中またはコマ送りのとき
			if	ne			;コマ送りのとき
				moveq.l	#-1,d1			;停止中にする
			endif
			move.w	(a1)+,SPRC_BG_0_X	;BG0を動かす
			move.w	(a1)+,SPRC_BG_0_Y
			if	<cmpa.l a5,a1>,eq
				movea.l	a0,a1
			endif
			move.w	(a2)+,SPRC_BG_1_X	;BG1を動かす
			move.w	(a2)+,SPRC_BG_1_Y
			if	<cmpa.l a5,a2>,eq
				movea.l	a0,a2
			endif
			move.w	(a3)+,CRTC_TEXT_X	;テキスト画面を動かす
			move.w	(a3)+,CRTC_TEXT_Y
			if	<cmpa.l a5,a3>,eq
				movea.l	a0,a3
			endif
			move.w	(a4)+,CRTC_GRAPHIC_X_0	;グラフィック画面を動かす
			move.w	(a4)+,CRTC_GRAPHIC_Y_0
			if	<cmpa.l a5,a4>,eq
				movea.l	a0,a4
			endif
		endif
		bsr	inkey0
	whileand	<cmp.b #27,d0>,ne,<cmp.b #3,d0>,ne	;ESCまたはCTRL+Cが押されるまで繰り返す

;スプライト表示OFF
	move.w	#$0000,SPRC_CONTROL
	andi.w	#.notw.VICON_SPON_MASK,VICON_VISIBLE

;パターン4096枚定義OFF
	move.w	#$0000,$00EB0812
	move.w	#$0000,$00EB0814

;ユーザモード
	usermode

;カーソルON
	IOCS	_B_CURON

;画面モードを復元
	move.w	screen_mode,-(sp)
	move.w	#16,-(sp)
	DOS	_CONCTRL
	move.w	function_mode,-(sp)
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.l	#8,sp

;終了
exit:
	DOS	_EXIT

moji:		.dc.w	'Ｓ','Ｔ','Ｇ'

;エラー終了
error:
	pea.l	usage(pc)
	DOS	_PRINT
	addq.l	#4,sp
	move.w	#1,-(sp)
	DOS	_EXIT2

usage:		.dc.b	'>hypotrochoid.x R r d f',13,10
		.dc.b	'                               既定値  最小値   最大値',13,10
		.dc.b	'  R  定円の半径(整数)              97     r+1  1000000',13,10
		.dc.b	'  r  動円の半径(整数)              47       1      R-1',13,10
		.dc.b	'  d  動円の中心から点までの距離    37       1  1000000',13,10
		.dc.b	'  f  1周(≠1周期)の点の数(整数)   720       1  1000000',13,10
		.dc.b	0
	.even

;sp_pset
;	バックグラウンド画面に点を描く
;	1024x1024ドットの画面が64x64個の16x16ドット(128バイト)のパターンに分割されている
;	画面座標(%LLLLLLSTXX,%BBBBHHYYYY)
;	パターン座標(%LLLLLL,%BBBBHH) パターン内座標(%STXX,%YYYY)
;	パターン番号%BBBBHHLLLLLL バンク番号%BBBB バンク内パターン番号%HHLLLLLL
;	ワードアドレス$00EB8000+%HHLLLLLLSYYYYT0 ワード内ビット番号%XX00^%1100
;<d1.w:X座標。0～1023。範囲外のとき何もしない
;<d2.w:Y座標。0～1023。範囲外のとき何もしない
;<d3.w:パレットコード。0～15。下位4bitを使う
sp_pset:
	ifand	<cmp.w #1023,d1>,ls,<cmp.w #1023,d2>,ls
		push	d1-d5/a0
		moveq.l	#%1111,d4		;d1.w=%LLLLLLSTXX
		moveq.l	#%1111,d5		;d2.w=%BBBBHHYYYY
		and.w	d4,d3			;d3.w=%PPPP
		and.w	d1,d4			;d4.l=%STXX
		and.w	d2,d5			;d5.l=%YYYY
		lsr.w	#4,d1			;d1.w=%LLLLLL
		lsr.w	#4,d2			;d2.w=%BBBBHH
		lsl.w	#6,d2			;d2.w=%BBBBHH000000
		or.w	d2,d1			;d1.w=%BBBBHHLLLLLL パターン番号
		move.w	d1,$00EB0814		;%BBBB バンク番号
		moveq.l	#0,d2
		move.b	d1,d2			;d2.l=%HHLLLLLL
		lsl.b	#5,d4			;d4.b=%TXX00000,x=S
		addx.w	d2,d2			;d2.l=%HHLLLLLLS
		lsl.w	#4,d2			;d2.l=%HHLLLLLLS0000
		or.w	d5,d2			;d2.l=%HHLLLLLLSYYYY
		add.b	d4,d4			;d4.b=%XX000000,x=T
		addx.w	d2,d2			;d2.l=%HHLLLLLLSYYYYT
		add.w	d2,d2			;d2.l=%HHLLLLLLSYYYYT0
		lea.l	$00EB8000,a0
		adda.l	d2,a0			;a0=$00EB8000+%HHLLLLLLSYYYYT0 ワードアドレス
		lsr.b	#4,d4			;d4.b=%XX00
		eor.b	#%1100,d4		;d4.b=%XX00^%1100 ワード内ビット番号
		move.w	(a0),d2			;ワードを読み出す
		ror.w	d4,d2			;目的の位置を下位4bitへ移動する
		and.w	#%1111111111110000,d2	;下位4bitを消す
		or.w	d3,d2			;下位4bitにパレットコードを入れる
		rol.w	d4,d2			;元の位置に戻す
		move.w	d2,(a0)			;ワードを書き戻す
		pop
	endif
	rts

tx_pset:
	ifand	<cmp.w #1023,d1>,ls,<cmp.w #1023,d2>,ls
		push	d0-d3/a0
		move.w	CRTC_ACCESS,-(sp)
		move.w	#$0200,CRTC_ACCESS	;マスクON,同時OFF
		move.w	CRTC_MASK,-(sp)
		lea.l	$00E60000,a0		;プレーン3から
		ext.l	d2
		lsl.l	#7,d2			;y*128
		adda.l	d2,a0
		moveq.l	#15,d0
		and.w	d1,d0			;xの下位4bit
		move.w	#$8000,d2
		lsr.w	d0,d2			;書き込むビットだけ1
		not.w	d2			;書き込むビットだけ0
		move.w	d2,CRTC_MASK
		lsr.w	#4,d1
		add.w	d1,d1			;x/16*2
		adda.w	d1,a0
		ror.w	#4,d3			;bit3を最上位に
		moveq.l	#4-1,d2
		for	d2
			add.w	d3,d3			;押し出す
			subx.w	d0,d0			;全ビットに展開
			move.w	d0,(a0)			;書き込む
			suba.l	#$00020000,a0
		next
		move.w	(sp)+,CRTC_MASK
		move.w	(sp)+,CRTC_ACCESS
		pop
	endif
	rts

gr_pset:
	ifand	<cmp.w #1023,d1>,ls,<cmp.w #1023,d2>,ls
		push	d1-d2/a0
		lea.l	$00C00000,a0
		swap.w	d2
		clr.w	d2
		lsr.l	#5,d2			;y*2048
		adda.l	d2,a0
		add.w	d1,d1			;x*2
		move.w	d3,(a0,d1.w)
		pop
	endif
	rts

	.data
	.even
;定数
dbl_ox:		.dc.d	512.0		;ox 中心のX座標
dbl_oy:		.dc.d	512.0		;oy 中心のY座標
dbl_RR:		.dc.d	510.0		;RR 表示半径
;引数
int_R:		.dc.l	97		;R 定円の半径
int_r:		.dc.l	47		;r 動円の半径
dbl_d:		.dc.d	37.0		;d 動円の中心から点までの距離
int_f:		.dc.l	720		;f 1周(≠1周期)の点の数

	.bss
	.even
;引数で決まる値
dbl_R:		.ds.d	1		;R 定円の半径
dbl_r:		.ds.d	1		;r 動円の半径
int_Rr:		.ds.l	1		;Rr=R-r 定円の中心から動円の中心までの距離
dbl_Rr:		.ds.d	1		;Rr=R-r 定円の中心から動円の中心までの距離
dbl_Rrr:	.ds.d	1		;Rrr=(R-r)/r 点の速度
int_n0:		.ds.l	1		;n0=r/gcd(R-r,r) 周期
int_fn0:	.ds.l	1		;fn0=f*n0 n0周(=1周期)の点の数
dbl_s:		.ds.d	1		;s=RR/(R-r+d) 倍率
dbl_f:		.ds.d	1		;f 1周(≠1周期)の点の数
dbl_dt:		.ds.d	1		;dt=2*pi/f 角度の増分

;保存した画面モード
function_mode:	.ds.w	1
screen_mode:	.ds.w	1

;スクロールの軌道
orbit:		.ds.w	2*720
orbit_end:

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

;----------------------------------------------------------------
;空白を読み飛ばす
;<a0.l:文字列
;>d0.l:最初の空白以外の文字または0
;>a0.l:最初の空白以外の文字または0の位置
;>z:ne=空白以外の文字がある,eq=空白以外の文字がない
nextword::
	moveq.l	#0,d0
	do
		move.b	(a0)+,d0		;次の文字
		break	eq			;0ならば終了
		redo	<cmp.b #' ',d0>,eq	;' 'ならば繰り返す
	whileand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\rならば繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	tst.l	d0
	rts

	.end

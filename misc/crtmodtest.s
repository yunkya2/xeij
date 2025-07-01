;========================================================================================
;  crtmodtest.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	crtmodtest.x
;		IOCS _CRTMODの実装とモニタの性能を確認するための画面を表示します。
;		IPLROM 1.6/crtmod16.xで拡張された画面モードに対応しています。
;
;	最終更新
;		2025-04-13
;
;	作り方
;		has060 -i include -o crtmodtest.o -w crtmodtest.s
;		lk -o crtmodtest.x crtmodtest.o
;
;	使い方
;		-l CRTorLCDモード
;			CRTorLCDモードを指定します。
;			0を指定するとCRT向けの同期周波数に、1を指定するとLCD向けの同期周波数になります。
;			-lを指定して-sを指定しなかったときはCRTorLCDモードを元に戻して終了します。
;			-lを指定して-sも指定したときはCRTorLCDモードを変更したまま終了します。
;			-lを指定しなかったときは現在のCRTorLCDモードを用います。
;			-lを指定しなかったときは-sは指定できません。
;		-m 画面モード
;			画面モードを0～47の範囲で指定します。
;			画面モードの一覧は使用法に書いてあります。
;		-s
;			-lで指定されたCRTorLCDモードをSRAMに保存します。
;		画面を表示してキー入力待ちになります。
;		何かキーを押すと画面モードを元に戻して終了します。
;		ESCキーが押されたときは画面モードを変更したまま終了します。
;
;	更新履歴
;		2022-02-21
;			公開。
;		2023-01-10
;			長いヘルプメッセージをページ毎に区切って表示するようにしました。
;		2023-11-14
;			-lを指定したときCRTorLCDモードを変更したまま終了していましたが、元に戻して終了するようにしました。
;			-sを追加しました。-sを指定すると-lで指定されたCRTorLCDモードに変更したまま終了します。
;		2024-08-25
;			画面モード40～47に対応しました。
;		2024-08-26
;			IPLROM 1.0～1.3のIOCS _SP_INITのバグを踏まないようにしました。
;			ESCキーで終了したとき、スプライトとグラフィックを非表示に、テキストを消去、テキストパレットを復元します。
;			コードを整理しました。
;		2025-04-01
;			IPLROM 1.6/CRTMOD16.X以外の環境で動かすと画面が乱れる問題を修正しました。
;		2025-04-13
;			stouを修正しました。
;
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ

TITLE_STRING	reg	'crtmodtest.x for IPLROM 1.6/crtmod16.x (2025-04-13)'

MAX_SCREEN_MODE	equ	47		;画面モードの最大値

TEXT_LINE	equ	3
GRAPHIC_LINE	equ	4		;4,5,6,7
SPRITE_LINE	equ	8
BG_LINE		equ	9		;9,10

	.text

base:
	lea.l	base(pc),a6
r	reg	-base(a6)

;オプションを確認する
	moveq.l	#-1,d6			;CRTorLCDモードは指定されていない
	moveq.l	#-1,d7			;画面モードは指定されていない
	sf.b	(save_to_sram)r		;CRTorLCDモードをSRAMに保存しない
	lea.l	1(a2),a0
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;-,/以外
		addq.l	#1,a0
		move.b	(a0)+,d0
		goto	eq,usage_exit		;-,/の後に文字がない
		bsr	tolower
		if	<cmp.b #'l',d0>,eq	;-l
			goto	<tst.l d6>,pl,usage_exit	;CRTorLCDモードは既に指定されている
			bsr	nextword
			bsr	stou
			gotoor	<>,cs,<cmp.l #1,d0>,hi,usage_exit	;10進数がないか範囲外
			move.l	d0,d6			;CRTorLCDモードが指定された
		elif	<cmp.b #'m',d0>,eq	;-m
			goto	<tst.l d7>,pl,usage_exit	;画面モードは既に指定されている
			bsr	nextword
			bsr	stou
			gotoor	<>,cs,<cmp.l #MAX_SCREEN_MODE,d0>,hi,usage_exit	;10進数がないか範囲外
			move.l	d0,d7			;画面モードが指定された
		elif	<cmp.b #'s',d0>,eq	;-s
			st.b	(save_to_sram)r		;CRTorLCDモードをSRAMに保存する
		else				;-l,-m,-s以外
			goto	usage_exit
		endif
	start
		bsr	nextword
	while	ne
	goto	<tst.l d7>,mi,usage_exit	;画面モードが指定されていない
	gotoand	<tst.l d6>,mi,<tst.b (save_to_sram)r>,ne,usage_exit	;CRTorLCDモードが指定されていないのでSRAMに保存できない
;<d6.l:CRTorLCDモード。0=CRT向け,1=LCD向け,-1=指定されていない
;<d7.l:画面モード

;スーパーバイザモードへ移行する
	supervisormode

;CRTorLCDモードを保存する
	move.w	#$16FF,d1
	IOCS	_CRTMOD
	rol.l	#8,d0
	cmp.b	#$96,d0
	seq.b	(saved_crtlcd)r

;CRTorLCDモードを変更する
	if	<tst.l d6>,pl		;CRTorLCDモードが指定されている
		if	eq			;CRT向け
			move.w	#$43FF,d1
		else				;LCD向け
			move.w	#$4CFF,d1
		endif
		IOCS	_CRTMOD			;CRTorLCDモードを変更する
	endif

;画面モードを設定する
	move.l	d7,d1			;画面モード
	IOCS	_CRTMOD
	IOCS	_G_CLR_ON

;情報を集める
;画面モード
	moveq.l	#0,d0
	move.b	BIOS_CRTMOD.w,(screen_mode)r
;CRTorLCDモード
	move.w	#$16FF,d1
	IOCS	_CRTMOD
	rol.l	#8,d0
	cmp.b	#$96,d0
	seq.b	(crtlcd_mode)r
;グラフィックページ数
	move.b	BIOS_GRAPHIC_PAGES.w,d0
	move.b	d0,(pages)r
;BGサイズ
	move.w	SPRC_RESOLUTION,d0
	btst.l	#0,d0
	sne.b	(bg_size)r
;スプライト画面の有無
	moveq.l	#%10010,d0
	and.w	CRTC_MODE_RESOLUTION,d0
	cmp.w	#%10010,d0
	sne.b	(sprite_exists)r
;画面の幅
	move.w	BIOS_GRAPHIC_RIGHT.w,d0
	addq.w	#1,d0
	move.w	BIOS_CONSOLE_RIGHT.w,d1
	addq.w	#1,d1
	lsl.w	#3,d1
	if	<cmp.w d1,d0>,lo
		move.w	d1,d0
	endif
	move.w	d0,(screen_width)r
;画面の高さ
	moveq.l	#0,d0
	move.w	BIOS_GRAPHIC_BOTTOM.w,d0
	addq.l	#1,d0
	moveq.l	#0,d1
	move.w	BIOS_CONSOLE_BOTTOM.w,d1
	addq.w	#1,d1
	lsl.w	#4,d1
	if	<cmp.l d1,d0>,lo
		move.l	d1,d0
	endif
	move.w	d0,(screen_height)r
;スプライト画面の高さ
	move.w	(screen_height)r,(sprite_height)r
	ifand	<cmpi.b #44,(screen_mode)r>,hs,<cmpi.b #MAX_SCREEN_MODE,(screen_mode)r>,ls
		lsl.w	(sprite_height)r	;画面モード44～47はスプライト画面の高さを2倍にする
	endif
;実画面サイズ
	move.l	BIOS_GRAPHIC_Y_OFFSET.w,d0
	lsr.l	#1,d0
	move.w	d0,(real_size)r
;グラフィック色数
	moveq.l	#0,d0
	move.w	BIOS_GRAPHIC_PALETS.w,d0
	addq.l	#1,d0
	move.l	d0,(palets)r

;ユーザモードへ復帰する
	usermode

;テキスト画面を描く
;パレットを設定する
	moveq.l	#3,d1			;パレットコード
	move.w	(text_color)r,d2	;カラーコード
	IOCS	_TPALET
;画面モードを表示する
	lea.l	(string_buffer)r,a0
	movestr	'CRTMOD(',a1
	bsr	strcpy
	moveq.l	#0,d0
	move.b	(screen_mode)r,d0
	bsr	utos
	if	<tst.b (crtlcd_mode)r>,eq
		movestr	') CRT',a1
	else
		movestr	') LCD',a1
	endif
	bsr	strcpy
	moveq.l	#3,d1			;パレットコード
	moveq.l	#2,d2			;X座標
	moveq.l	#TEXT_LINE-2,d3		;Y座標
	lea.l	(string_buffer)r,a1	;文字列
	move.l	a0,d4
	sub.l	a1,d4
	subq.w	#1,d4			;桁数-1
	IOCS	_B_PUTMES
;画面サイズを表示する
	lea.l	(string_buffer)r,a0
	moveq.l	#0,d0
	move.w	(screen_width)r,d0
	bsr	utos
	move.b	#'x',(a0)+
	moveq.l	#0,d0
	move.w	(screen_height)r,d0
	bsr	utos
	move.b	#'/',(a0)+
	moveq.l	#0,d0
	move.w	(real_size)r,d0
	bsr	utos
	move.b	#'x',(a0)+
	moveq.l	#0,d0
	move.w	(real_size)r,d0
	bsr	utos
	move.b	#' ',(a0)+
	move.l	(palets)r,d0
	bsr	utos
	move.b	#' ',(a0)+
	moveq.l	#0,d0
	move.b	(pages)r,d0
	bsr	utos
	moveq.l	#3,d1			;パレットコード
	moveq.l	#2,d2			;X座標
	moveq.l	#TEXT_LINE-1,d3		;Y座標
	lea.l	(string_buffer)r,a1	;文字列
	move.l	a0,d4
	sub.l	a1,d4
	subq.w	#1,d4			;桁数-1
	IOCS	_B_PUTMES
;TEXTと書く
	moveq.l	#3,d1			;パレットコード
	moveq.l	#2,d2			;X座標
	moveq.l	#TEXT_LINE,d3		;Y座標
	moveq.l	#8-1,d4			;桁数-1
	movestr	'ＴＥＸＴ',a1		;文字列
	IOCS	_B_PUTMES

;グラフィック画面を描く
;パレットを設定する
	if	<cmp.l #65536,(palets)r>,lo
		moveq.l	#0,d1			;パレットコード0
		moveq.l	#0,d2			;カラーコード
		IOCS	_GPALET
		lea.l	(graphic_color)r,a0
		moveq.l	#1,d3
		do
			move.w	d3,d1			;パレットコード1～4
			move.w	(a0)+,d2		;カラーコード
			IOCS	_GPALET
			addq.w	#1,d3
		while	<cmp.w #4,d3>,ls
	endif
;枠を描く
	move.w	#$F0F0,-(sp)		;ラインスタイル
	moveq.l	#1,d0
	if	<cmp.l #65536,(palets)r>,eq
		move.w	(graphic_color)r,d0
	endif
	move.w	d0,-(sp)		;パレットコード
	move.w	(screen_height)r,d0
	subq.w	#1,d0
	move.w	d0,-(sp)		;終点Y座標
	move.w	(screen_width)r,d0
	subq.w	#1,d0
	move.w	d0,-(sp)		;終点X座標
	clr.w	-(sp)			;始点Y座標
	clr.w	-(sp)			;始点X座標
	moveq.l	#2-1,d1			;外側,内側
	for	d1
		movea.l	sp,a1
		IOCS	_BOX
		addq.w	#4,(sp)			;始点X座標
		addq.w	#4,2(sp)		;始点Y座標
		subq.w	#4,4(sp)		;終点X座標
		subq.w	#4,6(sp)		;終点Y座標
	next
	lea.l	12(sp),sp
;GRAPHIC PAGE 0/1/2/3と書く
	moveq.l	#0,d5			;ページ番号 0,1,2,3
	do
	;文字列を作る
		lea.l	(string_buffer)r,a0
		movestr	'ＧＲＡＰＨＩＣ　ＰＡＧＥ　',a1
		bsr	strcpy
		move.w	#'０',d0
		add.w	d5,d0
		rol.w	#8,d0
		move.b	d0,(a0)+
		rol.w	#8,d0
		move.b	d0,(a0)+
		clr.b	d0
	;ページを選択する
		move.l	d5,d1
		IOCS	_APAGE
	;描く
		move.w	#1<<8|0,-(sp)		;サイズ:角度
		moveq.l	#1,d0
		add.w	d5,d0
		if	<cmp.l #65536,(palets)r>,eq
			move.w	d5,d0
			lea.l	(graphic_color)r,a0
			add.w	d0,d0
			move.w	(a0,d0.w),d0
		endif
		move.w	d0,-(sp)		;パレットコード
		move.w	#1<<8|1,-(sp)		;X方向の倍率:Y方向の倍率
		pea.l	(string_buffer)r	;文字列
		moveq.l	#GRAPHIC_LINE,d0
		add.w	d5,d0
		lsl.w	#4,d0
		move.w	d0,-(sp)		;Y座標
		move.w	#8*2,-(sp)		;X座標
		movea.l	sp,a1
		IOCS	_SYMBOL
		lea.l	14(sp),sp
		addq.w	#1,d5
	while	<cmp.b (pages)r,d5>,lo

;スプライト画面を描く
	if	<tst.b (sprite_exists)r>,ne	;スプライト画面あり
	;初期化する
		IOCS	_SP_INIT
		IOCS	_SP_ON
	;パレットを設定する
		lea.l	(sprite_color)r,a0
		moveq.l	#1,d4			;パレットブロック 1,2,3
		do
			moveq.l	#0,d1			;パレットコード
			move.l	d4,d2			;パレットブロック
			moveq.l	#0,d3			;カラーコード
			IOCS	_SPALET
			moveq.l	#1,d1			;パレットコード
			move.l	d4,d2			;パレットブロック
			move.w	(a0)+,d3		;カラーコード
			IOCS	_SPALET
			addq.w	#1,d4
		while	<cmp.w #3,d4>,ls
	;図形パターンを定義する
		moveq.l	#2,d1			;パターン番号 2
		moveq.l	#1,d2			;サイズ 16x16
		lea.l	(sprite_pattern)r,a1	;スプライトパターン
		IOCS	_SP_DEFCG		;パターンを定義する
	;文字パターンを定義する
	;		  3 4 5 6 7 8 910111213141516171819202122
		movestr	'ＳＰＲＩＴＥＢＡＣＫ－ＧＲＯＵＮＤ　０１',a4
		moveq.l	#3,d6			;パターン番号
		dostart
			lsl.w	#8,d1
			move.b	(a4)+,d1		;文字コード下位
			moveq.l	#8,d2			;サイズ 16x16
			lea.l	(font_buffer)r,a1	;フォントバッファ
			IOCS	_FNTGET			;フォントデータを取り出す
			lea.l	(pattern_buffer)r,a0	;パターンバッファ
			moveq.l	#0,d7			;0固定
			moveq.l	#-2,d5			;-2=左半分,-1=右半分
			do
				lea.l	(font_buffer+4)r,a1	;フォントデータの本体
				moveq.l	#16-1,d3		;縦16ドット
				for	d3
				;	moveq.l	#0,d0
					move.b	2(a1,d5.w),d1		;左半分または右半分
					moveq.l	#8-1,d2			;横8ドット
					for	d2
						lsl.l	#4,d0			;0を0000に、1を0001にする
						add.b	d1,d1			;d1.bの上位から押し出して
						addx.b	d7,d0			;d0.lの下位へ押し込む
					next
					move.l	d0,(a0)+		;パターンデータ
					addq.l	#2,a1
				next
				addq.w	#1,d5
			while	ne
			move.w	d6,d1			;パターン番号
			moveq.l	#1,d2			;サイズ 16x16
			lea.l	(pattern_buffer)r,a1	;パターンデータ
			IOCS	_SP_DEFCG		;パターンを定義する
			addq.w	#1,d6			;次のパターン番号
		start
			moveq.l	#0,d1
			move.b	(a4)+,d1		;文字コード上位
		while	ne
	;四隅のスプライトを表示する
		moveq.l	#0,d6			;位置=スプライト番号 0=左上,1=右上,2=左下,3=右下
		do
			move.l	d6,d1			;スプライト番号 0,1,2,3
			moveq.l	#16,d2			;X座標左端
			if	<btst.l #0,d6>,ne
				move.w	(screen_width)r,d2	;X座標右端
			endif
			moveq.l	#16,d3			;Y座標上端
			if	<btst.l #1,d6>,ne
				move.w	(sprite_height)r,d3	;Y座標下端
			endif
			move.w	#1<<8|2,d4		;パレットブロック:パターン番号 1:2
			moveq.l	#3,d5			;プライオリティ 3
			IOCS	_SP_REGST
			addq.w	#1,d6			;次の位置=スプライト番号
		while	<cmp.w #3,d6>,ls
	;SPRITEと書く
		moveq.l	#16+16*1,d2
		movea.l	d2,a2			;X座標
		moveq.l	#SPRITE_LINE,d3
		move.w	(screen_height)r,d0
		if	<cmp.w (sprite_height)r,d0>,ne
			add.w	d3,d3
		endif
		lsl.w	#4,d3
		add.w	#16,d3
		movea.l	d3,a3			;Y座標
	;		 S P R I T E
		movestr	<3,4,5,6,7,8>,a4	;パターン番号
		moveq.l	#4,d7			;スプライト番号
		dostart
			move.l	d7,d1			;スプライト番号
			move.w	a2,d2			;X座標
			move.w	a3,d3			;Y座標
			move.w	#1<<8,d4
			move.b	d0,d4			;パレットブロック:パターン番号
			moveq.l	#3,d5			;プライオリティ 3
			IOCS	_SP_REGST
			addq.w	#1,d7			;次のスプライト番号
			adda.w	#16,a2			;次のX座標
		start
			moveq.l	#0,d0
			move.b	(a4)+,d0		;パターン番号
		while	ne
	;BGを描く
		if	<tst.b (bg_size)r>,eq	;8x8/512x512x2
			moveq.l	#0,d5			;BGテキストエリア 0,1
			do
			;枠のパターンを定義する
				move.l	d5,d1
				addq.w	#2,d1			;パターン番号 2,3
				moveq.l	#0,d2			;サイズ 8x8
				lea.l	(bg_pattern_8x8)r,a1
				move.l	d5,d0
				lsl.w	#5,d0
				adda.l	d0,a1			;パターンデータ
				IOCS	_SP_DEFCG
			;枠のパターンで塗り潰す
				move.l	d5,d1			;BGテキストエリア 0,1
				move.l	d5,d2
				addq.w	#2,d2			;パターン番号=パレットブロック 2,3
				move.b	d2,d0
				lsl.w	#8,d2
				move.b	d0,d2			;パレットブロック:パターン番号 2:2,3:3
				IOCS	_BGTEXTCL
			;枠を残して内側をくり抜く
				move.l	d5,d1			;BGテキストエリア 0,1
				moveq.l	#0<<8|0,d4		;パレットブロック:パターン番号 0:0
				moveq.l	#1,d3			;BGテキストY座標。枠の1個
				move.w	(sprite_height)r,d7
				lsr.w	#3,d7			;8x8が縦に並ぶ数
				subq.w	#2+1,d7			;枠の2個
				for	d7			;縦
					moveq.l	#1,d2			;BGテキストX座標。枠の1個
					move.w	(screen_width)r,d6
					lsr.w	#3,d6			;8x8が横に並ぶ数
					subq.w	#2+1,d6			;枠の2個
					for	d6			;横
						IOCS	_BGTEXTST
						addq.w	#1,d2			;次のBGテキストX座標
					next
					addq.w	#1,d3			;次のBGテキストY座標
				next
			;BACK-GROUND 0/1と書く
				moveq.l	#2*1,d2
				movea.l	d2,a2			;X座標
				moveq.l	#BG_LINE,d3
				add.w	d5,d3
				move.w	(screen_height)r,d0
				if	<cmp.w (sprite_height)r,d0>,ne
					add.w	d3,d3
				endif
				add.w	d3,d3
				movea.l	d3,a3			;Y座標
			;		 B  A  C  K  -  G  R  O  U  N  D     0
				movestr	<9,10,11,12,13,14,15,16,17,18,19,20,21>,a4	;パターン番号
				dostart
					move.l	d5,d4
					addq.b	#2,d4			;パレットブロック 2,3
					lsl.w	#8,d4
					if	<cmp.b #21,d0>,eq	;0/1
						add.b	d5,d0			;21(0)→22(1)
					endif
					move.b	d0,d4			;パレットブロック:16x16パターン番号
					lsl.b	#2,d4			;パレットブロック:8x8パターン番号
					moveq.l	#4-1,d6			;左上,左下,右上,右下
					for	d6
						move.l	d5,d1			;BGテキストエリア 0,1
						moveq.l	#2,d2
						and.b	d4,d2
						lsr.w	#1,d2
						add.w	a2,d2			;BGテキストX座標
						moveq.l	#1,d3
						and.b	d4,d3
						add.w	a3,d3			;BGテキストY座標
						IOCS	_BGTEXTST
						addq.b	#1,d4			;次の8x8パターン番号
					next
					addq.w	#2,a2			;BGテキストX座標
				start
					moveq.l	#0,d0
					move.b	(a4)+,d0		;パターン番号
				while	ne
			;表示ON
				move.l	d5,d1			;BGページ 0,1
				move.l	d5,d2			;BGテキストエリア 0,1
				moveq.l	#1,d3			;表示ON
				IOCS	_BGCTRLST
			;
				addq.w	#1,d5			;次のBGテキストエリア
			while	<cmp.w #1,d5>,ls
		else				;16x16/1024x1024x1
		;枠のパターンを定義する
			moveq.l	#1,d1			;パターン番号 1
			moveq.l	#1,d2			;サイズ 16x16
			lea.l	(bg_pattern_16x16)r,a1	;パターンデータ
			IOCS	_SP_DEFCG
		;枠のパターンで塗り潰す
			moveq.l	#0,d1			;BGテキストエリア 0
			move.w	#2<<8|1,d2		;パレットブロック:パターン番号 2:1
			IOCS	_BGTEXTCL
		;枠を残して内側をくり抜く
			moveq.l	#0,d1			;BGテキストエリア 0
			move.w	#0<<8|0,d4		;パレットブロック:パターン番号 0:0
			moveq.l	#1,d3			;BGテキストY座標。枠の1個
			move.w	(sprite_height)r,d7
			lsr.w	#4,d7			;16x16が縦に並ぶ数
			subq.w	#2+1,d7			;枠の2個
			for	d7			;縦
				moveq.l	#1,d2			;BGテキストX座標。枠の1個
				move.w	(screen_width)r,d6
				lsr.w	#4,d6			;16x16が横に並ぶ数
				subq.w	#2+1,d6			;枠の2個
				for	d6			;横
					IOCS	_BGTEXTST
					addq.w	#1,d2			;次のBGテキストX座標
				next
				addq.w	#1,d3			;次のBGテキストY座標
			next
		;BACK-GROUND 0と書く
			moveq.l	#1*1,d2
			move.l	d2,a2			;X座標
			moveq.l	#BG_LINE,d3
			move.w	(screen_height)r,d0
			if	<cmp.w (sprite_height)r,d0>,ne
				add.w	d3,d3
			endif
			movea.l	d3,a3			;Y座標
		;		 B  A  C  K  -  G  R  O  U  N  D     0
			movestr	<9,10,11,12,13,14,15,16,17,18,19,20,21>,a4	;パターン番号
			dostart
				move.w	#2<<8,d4
				move.b	d0,d4			;パレットブロック:パターン番号
				moveq.l	#0,d1			;BGテキストエリア 0
				move.w	a2,d2			;BGテキストX座標
				move.w	a3,d3			;BGテキストY座標
				IOCS	_BGTEXTST
				addq.w	#1,a2			;BGテキストX座標
			start
				moveq.l	#0,d0
				move.b	(a4)+,d0		;パターン番号
			while	ne
		;表示ON
			moveq.l	#0,d1			;BGページ 0
			moveq.l	#0,d2			;BGテキストエリア 0
			moveq.l	#1,d3			;表示ON
			IOCS	_BGCTRLST
		endif
	endif

;キー入力を待ってから画面モードを復元する
	IOCS	_B_CUROFF
	DOS	_GETC
	if	<cmp.b #27,d0>,eq	;ESCキーが押されたとき
	;スプライト画面とグラフィック画面をOFFにする
		moveq.l	#$0020,d1
		IOCS	_CRTMOD2
	;テキスト画面を消去する
		moveq.l	#2,d1
		IOCS	_B_CLR_ST
	;テキストパレットを復元する
		moveq.l	#3,d1
		moveq.l	#-2,d2
		IOCS	_TPALET
	else				;ESCキー以外が押されたとき
	;CRTorLCDモードを復元する
		if	<tst.b (save_to_sram)r>,eq	;CRTorLCDモードをSRAMに保存しない
			if	<tst.b (saved_crtlcd)r>,eq	;CRT向けだった
				move.w	#$43FF,d1
			else				;LCD向けだった
				move.w	#$4CFF,d1
			endif
			IOCS	_CRTMOD			;CRTorLCDモードを復元する
		endif
	;OSの画面モードを復元する
		move.l	#(16<<16)|$FFFF,-(sp)
		DOS	_CONCTRL
		move.w	d0,2(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
	endif
	IOCS	_B_CURON

;終了する
exit:
	DOS	_EXIT

;タイトルと使用法を表示して終了する
usage_exit:
	lea.l	title_usage(pc),a0
	bsr	more
	goto	exit

;タイトルと使用法
title_usage:
	.dc.b	TITLE_STRING,13,10
	.dc.b	'オプション',13,10
	.dc.b	'  -l 0-1   CRTorLCDモード。0=CRT向け,1=LCD向け',13,10
	.dc.b	'  -m 0-47  画面モード',13,10
	.dc.b	'  -s       -lで指定したCRTorLCDモードをSRAMに保存する',13,10
	.dc.b	'  ┌───┬───────────┬───────────────────────────┐',13,10
	.dc.b	'  │CRTMOD│実画面サイズ 色 ページ│        水平同期  垂直同期  画面サイズ      備考      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │   0  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │   4  │  512x512      16  4  │  CRT  31.500kHz  55.458Hz   512x512                  │',13,10
	.dc.b	'  │   8  │  512x512     256  2  │  LCD  35.341kHz  56.546Hz   512x512                  │',13,10
	.dc.b	'  │  12  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │   1  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │   5  │  512x512      16  4  │  CRT  15.980kHz  61.463Hz   512x480   インターレース │',13,10
	.dc.b	'  │   9  │  512x512     256  2  │  LCD  35.341kHz  56.546Hz   512x480                  │',13,10
	.dc.b	'  │  13  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │   2  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │   6  │  512x512      16  4  │  CRT  31.500kHz  55.458Hz   256x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  10  │  512x512     256  2  │  LCD  34.500kHz  55.200Hz   256x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  14  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │   3  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │   7  │  512x512      16  4  │  CRT  15.980kHz  61.463Hz   256x240                  │',13,10
	.dc.b	'  │  11  │  512x512     256  2  │  LCD  34.500kHz  55.200Hz   256x240   ラスタ2度読み  │',13,10
	.dc.b	'  │  15  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  16  │ 1024x1024     16  1  │  CRT  31.500kHz  55.458Hz   768x512                  │',13,10
	.dc.b	'  │  20  │  512x512     256  2  │  LCD  35.056kHz  56.090Hz   768x512                  │',13,10
	.dc.b	'  │  24  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  17  │ 1024x1024     16  1  │  CRT  24.699kHz  53.116Hz  1024x424                  │',13,10
	.dc.b	'  │  21  │  512x512     256  2  │  LCD  35.056kHz  56.090Hz   768x600                  │',13,10
	.dc.b	'  │  25  │  512x512   65536  1  │                               変形                   │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  18  │ 1024x1024     16  1  │  CRT  24.699kHz  53.116Hz  1024x848   インターレース │',13,10
	.dc.b	'  │  22  │  512x512     256  2  │  LCD  35.056kHz  56.090Hz   768x1024  インターレース │',13,10
	.dc.b	'  │  26  │  512x512   65536  1  │                               変形                   │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  19  │ 1024x1024     16  1  │  CRT  31.500kHz  55.458Hz   640x480   VGAではない    │',13,10
	.dc.b	'  │  23  │  512x512     256  2  │  LCD  31.469kHz  59.940Hz   640x480   VGA            │',13,10
	.dc.b	'  │  27  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  28  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │  29  │  512x512      16  4  │  CRT  31.963kHz  56.273Hz   384x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  30  │  512x512     256  2  │  LCD  31.963kHz  51.141Hz   384x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  31  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  32  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │  33  │  512x512      16  4  │  CRT  31.500kHz  55.458Hz   512x512                  │',13,10
	.dc.b	'  │  34  │  512x512     256  2  │  LCD  35.056kHz  56.090Hz   512x512                  │',13,10
	.dc.b	'  │  35  │  512x512   65536  1  │                              正方形                  │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  36  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │  37  │  512x512      16  4  │  CRT  31.963kHz  56.273Hz   256x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  38  │  512x512     256  2  │  LCD  31.963kHz  51.141Hz   256x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  39  │  512x512   65536  1  │                              正方形                  │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  40  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │  41  │  512x512      16  4  │  CRT  31.500kHz  55.458Hz   512x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  42  │  512x512     256  2  │  LCD  35.341kHz  56.546Hz   512x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  43  │  512x512   65536  1  │                                                      │',13,10
	.dc.b	'  ├───┼───────────┼───────────────────────────┤',13,10
	.dc.b	'  │  44  │ 1024x1024     16  1  │                                                      │',13,10
	.dc.b	'  │  45  │  512x512      16  4  │  CRT  31.500kHz  55.458Hz   512x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  46  │  512x512     256  2  │  LCD  35.341kHz  56.546Hz   512x256   ラスタ2度読み  │',13,10
	.dc.b	'  │  47  │  512x512   65536  1  │                       スプライトは512x512            │',13,10
	.dc.b	'  └───┴───────────┴───────────────────────────┘',13,10
	.dc.b	0
	.even

;色
text_color:	dchsv	0,24,31
graphic_color:	dchsv	24,24,31
		dchsv	48,24,31
		dchsv	72,24,31
		dchsv	96,24,31
sprite_color:	dchsv	120,24,31
		dchsv	144,24,31
		dchsv	168,24,31

;BGパターン
bg_pattern_8x8:
	.dc.l	$00110011		;BG0
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000

	.dc.l	$00000000		;BG1
	.dc.l	$00000000
	.dc.l	$11001100
	.dc.l	$11001100
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$11001100
	.dc.l	$11001100

bg_pattern_16x16:
	.dc.l	$00110011		;左半分
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000

	.dc.l	$00110011		;右半分
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000

;スプライトパターン
sprite_pattern:
	.dc.l	$00001111		;左半分
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000

	.dc.l	$00001111		;右半分
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000

	.bss

save_to_sram:	.ds.b	1		;CRTorLCDモードをSRAMに保存するか。0=しない,-1=する
saved_crtlcd:	.ds.b	1		;元の画面モード
screen_mode:	.ds.b	1		;画面モード
crtlcd_mode:	.ds.b	1		;CRTorLCDモード。0=CRT向け,-1=LCD向け
pages:		.ds.b	1		;グラフィックページ数
bg_size:	.ds.b	1		;BGサイズ。0=8x8/512x512x2,-1=16x16/1024x1024x1
sprite_exists:	.ds.b	1		;スプライト画面の有無。0=なし,-1=あり
	.even
screen_width:	.ds.w	1		;画面の幅
screen_height:	.ds.w	1		;画面の高さ
sprite_height:	.ds.w	1		;スプライト画面の高さ
real_size:	.ds.w	1		;実画面サイズ
palets:		.ds.l	1		;グラフィック色数
font_buffer:	.ds.w	2+2+3*24	;フォントバッファ
pattern_buffer:	.ds.l	8*4		;スプライトパターンバッファ
string_buffer:	.ds.b	256		;文字列バッファ

	.text



;----------------------------------------------------------------
;-more-を挟みながら文字列を表示する
;<a0.l:文字列
more::
	push	d0-d5/a0-a2
;標準入力を確認する
	clr.l	-(sp)			;(0<<16)|0
	DOS	_IOCTRL
	addq.l	#4,sp
;<d0.b:標準入力のFCBフラグ
	and.b	#$81,d0			;キャラクタデバイス、標準入力
	goto	<cmp.b #$81,d0>,ne,90f	;標準入力がリダイレクトされている。moreしない
;標準出力を確認する
	pea.l	1.w			;(0<<16)|1
	DOS	_IOCTRL
	addq.l	#4,sp
;<d0.b:標準出力のFCBフラグ
	and.b	#$82,d0			;キャラクタデバイス、標準出力
	goto	<cmp.b #$82,d0>,ne,90f	;標準出力がリダイレクトされている。moreしない
;CONDRV.SYSを確認する
	move.w	#$0100+_KEY_INIT,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	movea.l	d0,a1
	subq.l	#4,a1
	IOCS	_B_LPEEK
	goto	<cmp.l #'hmk*',d0>,eq,90f	;CONDRV.SYSが組み込まれている。moreしない
;画面の大きさを確認する
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	IOCS	_B_CONSOL
;<d2.l:右端の桁座標<<16|下端の行座標
	move.w	d2,d3
	swap.w	d2
	addq.w	#1,d2
;<d2.w:画面の桁数
;<d3.w:下端の行座標。-more-の行を除いた画面の行数
	gotoor	<cmp.w #8,d2>,lo,<tst.w d3>,eq,90f	;画面が狭すぎる。moreしない。タブを含めて1文字以上書けなければならないので8桁x1行が下限
;ページループ
	do
		move.l	#0,d4			;桁座標
		move.l	#0,d5			;行座標
		movea.l	a0,a2			;ページ先頭
	;文字ループ
		do
			movea.l	a0,a1			;文字先頭
			move.b	(a0)+,d0		;1バイト目
			if	eq			;00 終了
				subq.l	#1,a0
				break
			elif	<cmp.b #$09,d0>,eq	;09 タブ
				moveq.l	#7,d1
				and.w	d4,d1
				subq.w	#8,d1
				neg.w	d1		;タブの桁数
			elif	<cmp.b #$0A,d0>,eq	;0A 改行
				moveq.l	#0,d4		;左端へ
				addq.w	#1,d5		;次の行へ
				break	<cmp.w d3,d5>,eq	;下端。ページ終わり
				continue
			elif	<cmp.b #$0C,d0>,eq	;0C 改ページ
				break
			elif	<cmp.b #$1F,d0>,ls	;01-08,0B,0D-1F 無視する
				continue
			else				;20-FF
				do
					moveq.l	#1,d1			;半角の桁数
					break	<tst.b d0>,pl		;20-7F アスキー
					breakand	<cmp.b #$A0,d0>,hs,<cmp.b #$DF,d0>,ls	;A0-DF 半角カタカナ
					addq.l	#1,a0			;2バイト目
					break	<cmp.b #$80,d0>,eq	;8000-80FF 半角ひらがな
					break	<cmp.b #$F0,d0>,hs	;F000-FFFF 1/4角、半角外字
					moveq.l	#2,d1			;全角の桁数
				while	f
			endif
			add.w	d1,d4			;表示した後の桁座標
			if	<cmp.w d2,d4>,hi	;はみ出す
				sub.w	d1,d4			;進み過ぎた分戻る
				movea.l	a1,a0
				addq.w	#1,d5			;次の行へ
				break	<cmp.w d3,d5>,eq	;下端。ページ終わり
				moveq.l	#0,d4			;左端へ
			endif
		while	t
	;1ページ表示する
		move.l	a0,d0			;末尾
		sub.l	a2,d0			;末尾-先頭=長さ
		move.l	d0,-(sp)		;長さ
		move.l	a2,-(sp)		;先頭
		move.w	#1,-(sp)		;標準出力
		DOS	_WRITE
		lea.l	10(sp),sp
	;続きがなければ終了する
		break	<tst.b (a0)>,eq
	;必要ならば改行する
		ifand	<tst.w d4>,ne,<cmp.w d2,d4>,ne	;左端でも右端でもない
			bsr	printcrlf
		endif
	;-more-を表示する
		pea.l	6.w
		pea.l	100f(pc)		;'-more-'
		move.w	#1,-(sp)
		DOS	_WRITE
		lea.l	10(sp),sp
	;キー入力を待つ
		DOS	_GETC
		move.l	d0,d1
	;改行する
		bsr	printcrlf
	whileand	<cmp.b #$1B,d1>,ne,<cmp.b #'Q',d1>,ne,<cmp.b #'q',d1>,ne	;ESCまたはQが押されたときは終了する
99:	pop
	rts

;moreしない
90:	bsr	print
	goto	99b

100:	.dc.b	'-more-'
	.even

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
;改行を表示する
printcrlf::
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	bsr	print
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;10進数の文字列を符号なし整数に変換する
;<a0.l:10進数の文字列。先頭の空白は認めない
;>d0.l:(ccのとき)符号なし整数。(csのとき)0=10進数の文字がない,-1=オーバーフロー
;>a0.l:(ccのとき)10進数の文字列の次の位置。(csのとき)変化しない
;>z:(ccのとき)eq=符号なし整数が0
;>v:(csのとき)vc=10進数の文字がない,vs=オーバーフロー
;>c:cs=10進数の文字がないまたはオーバーフロー
stou::
	push	d1-d2/a1
	moveq.l	#0,d0			;符号なし整数
	moveq.l	#0,d1			;文字
	movea.l	a0,a1			;開始位置
	dostart
		goto	<cmp.l #$1999999A,d0>,hs,20f	;10倍したらオーバーフローする
		move.l	d0,d2			;1倍
		lsl.l	#2,d0			;4倍
		add.l	d2,d0			;5倍
		add.l	d0,d0			;10倍して
		add.l	d1,d0			;1桁加える
		goto	cs,20f			;オーバーフローした
	start
		move.b	(a0)+,d1		;次の文字
		sub.b	#'0',d1			;整数にする
	whileand	<>,hs,<cmp.b #10,d1>,lo	;10進数の文字ならば繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	goto	<cmpa.l a1,a0>,eq,30f	;進んでいない。10進数の文字がない
	tst.l	d0			;ne/eq,vc,cc
10:	pop
	rts

;オーバーフロー
20:
  .if 0
	do
		move.b	(a0)+,d1		;次の文字
		sub.b	#'0',d1			;整数にする
	whileand	<>,hs,<cmp.b #10,d1>,lo	;10進数の文字を読み飛ばす
	subq.l	#1,a0			;進み過ぎた分戻る
  .else
	movea.l	a1,a0			;開始位置に戻る
  .endif
	moveq.l	#-1,d0			;オーバーフロー
	move.w	#%00011,ccr		;ne,vs,cs
	goto	10b

;10進数の文字がない
30:
;	moveq.l	#0,d0			;10進数の文字がない
	move.w	#%00101,ccr		;eq,vc,cs
	goto	10b

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
;小文字にする
;<d0.b:文字
;>d0.b:文字
tolower::
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;大文字
		add.b	#'a'-'A',d0		;小文字にする
	endif
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



	.end

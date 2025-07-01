;========================================================================================
;  r00bit0test.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;	r00bit0test.x
;	CRTC R00のbit0が1に固定されていることを確認します
;	384x256の画面を水平トータルが68、69、70の場合について作り、それぞれ垂直周期を計測します
;	X68030実機では69の垂直周期が70の垂直周期と同じになることから、CRTC R00のbit0が1に固定されていることが分かります
;	CRTC R00のbit0が1に固定されていないエミュレータでは、69の垂直周期が68の垂直周期と70の垂直周期の中間になります
;----------------------------------------------------------------------------------------

TITLE		reg	'r00bit0test.x (2024-02-17)'
TESTS		equ	14

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ
	.include	sram.equ
	.include	sysport.equ
	.include	vicon.equ

;スーパーバイザモード
	supervisormode

;計測する
	lea.l	results(pc),a2
	moveq.l	#28,d1
	moveq.l	#0,d2
	moveq.l	#TESTS-1,d3
	for	d3
		bsr	iocs_10_CRTMOD
		bsr	measure
		move.l	d0,(a2)+
		addq.w	#1,d2
	next

;ユーザモード
	usermode

;標準の画面に戻す
	moveq.l	#16,d1
	IOCS	_CRTMOD
	move.l	#(16<<16)|$FFFF,-(sp)
	DOS	_CONCTRL
	move.w	d0,2(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

;結果を表示する
;	オシレータ…OSC=69.552(MHz)
;	分周比…DIV=4
;	水平トータル…HT=69(理想)
;	垂直トータル…VT=568
;	垂直周期…VP=18032(us)(理想)
;	VP=8*HT*VT*DIV/OSC
;	  =HT*(8*VT*DIV/OSC)
;	  =HT*(8*VT*DIV/OSC)
;	  =HT*(8*VT*DIV/OSC*2**7)/2**7
;	  =HT*(33450.1955...)/2**7
;	  =round(HT*33450/2**7)
;	HT=VP*OSC/8/VT/DIV
;	  =VP*(OSC/8/VT/DIV*2**24)/2**24
;	  =VP*(64199.4348...)/2**24
;	  =round(VP*64199/2**24)
	lea.l	buffer(pc),a0		;a0=buffer
	leastrdata	<TITLE,13,10>,a1
	bsr	strcpy
	lea.l	results(pc),a2		;a2=results
	moveq.l	#TESTS-1,d1		;d1=count
	for	d1
		if	<cmp.w #TESTS-1,d1>,eq	;最初
			moveq.l	#68,d2			;d2=HTin
			moveq.l	#68,d3			;d3=exp_HTout
		elif	<tst.w d1>,hi		;問題のケース
			moveq.l	#69,d2			;d2=HTin
			moveq.l	#70,d3			;d3=exp_HTout
		else				;最後
			moveq.l	#70,d2			;d2=HTin
			moveq.l	#70,d3			;d3=exp_HTout
		endif
		move.l	d3,d4
		mulu.w	#33450,d4
		add.l	#$00000040,d4
		lsr.l	#7,d4			;d4=exp_VP
		move.l	(a2)+,d5		;d5=obs_VP
		move.l	d5,d6
		mulu.w	#64199,d6
		add.l	#$00800000,d6
		and.l	#$FF000000,d6
		rol.l	#8,d6			;d6=obs_HTout
		leastrdata	<'TEST '>,a1
		bsr	strcpy
		moveq.l	#TESTS,d0
		sub.w	d1,d0			;d1=count
		bsr	utos
		leastrdata	<': HTin='>,a1
		bsr	strcpy
		move.l	d2,d0			;d2=HTin
		bsr	utos
		leastrdata	<' exp_HTout='>,a1
		bsr	strcpy
		move.l	d3,d0			;d3=exp_HTout
		bsr	utos
		leastrdata	<' exp_VP='>,a1
		bsr	strcpy
		move.l	d4,d0			;d4=exp_VP
		bsr	utos
		leastrdata	<' obs_VP='>,a1
		bsr	strcpy
		move.l	d5,d0			;d5=obs_VP
		bsr	utos
		leastrdata	<' obs_HTout='>,a1
		bsr	strcpy
		move.l	d6,d0			;d6=obs_HTout
		bsr	utos
		if	<cmp.w d3,d6>,eq
			leastrdata	<' OK'>,a1
		else
			leastrdata	<' ERROR'>,a1
		endif
		bsr	strcpy
		bsr	crlf
	next
	lea.l	buffer(pc),a0
	bsr	print

;終了
	DOS	_EXIT

	.bss
	.even
results:
	.ds.l	TESTS
buffer:
	.ds.b	4096
	.text



;垂直周期を計測する
;>d0.l:垂直周期(us)
measure:
	push	d1/d2/d3/d7/a0/a1/a6

;グローバルレジスタ
dZERO	reg	d7
	moveq.l	#0,dZERO
aTCDCR	reg	a6
	lea.l	MFP_TCDCR,aTCDCR

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

;終了
	pop
	rts



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



CRTMOD_VERSION	equ	$16_231115	;_CRTMODのバージョン



;----------------------------------------------------------------
;IOCSコール$10 _CRTMOD 画面モードの取得と設定
;<d1.w:設定後の画面モード
;	$01xx	初期化しない
;	$16FF	バージョン確認。$16_xxxxxx(CRT向け)または$96_xxxxxx(LCD向け)を返す
;	$43xx	CRT向け。SRAMに保存する。$43FFはSRAMの変更のみ
;	$4Cxx	LCD向け。SRAMに保存する。$4CFFはSRAMの変更のみ
;	$56FF	バージョン確認。$16_xxxxxxを返す
;	$FFFF	取得のみ
  .if TESTS
;<d2.w:384x256のCRTC R00
;	0	HT=68,R00=67
;	1	HT=69,R00=68
;	2	HT=70,R00=69
  .endif
;>d0.l:設定前の画面モード。バージョン確認は$16_xxxxxxまたは$96_xxxxxxを返す
;----------------------------------------------------------------
;	画面モード
;
;	画面モード	解像度	画面サイズ	実画面サイズ	色数	ページ数
;	0		高	512x512		1024x1024	16	1
;	1		低	512x512		1024x1024	16	1
;	2		高	256x256		1024x1024	16	1
;	3		低	256x256		1024x1024	16	1
;	4		高	512x512		512x512		16	4
;	5		低	512x512		512x512		16	4
;	6		高	256x256		512x512		16	4
;	7		低	256x256		512x512		16	4
;	8		高	512x512		512x512		256	2
;	9		低	512x512		512x512		256	2
;	10		高	256x256		512x512		256	2
;	11		低	256x256		512x512		256	2
;	12		高	512x512		512x512		65536	1
;	13		低	512x512		512x512		65536	1
;	14		高	256x256		512x512		65536	1
;	15		低	256x256		512x512		65536	1
;	16		高	768x512		1024x1024	16	1
;	17		中	1024x424	1024x1024	16	1
;	18		中	1024x848	1024x1024	16	1
;	19		VGA	640x480		1024x1024	16	1
;	20		高	768x512		512x512		256	2
;	21		中	1024x424	512x512		256	2
;	22		中	1024x848	512x512		256	2
;	23		VGA	640x480		512x512		256	2
;	24		高	768x512		512x512		65536	1
;	25		中	1024x424	512x512		65536	1
;	26		中	1024x848	512x512		65536	1
;	27		VGA	640x480		512x512		65536	1
;	$100+(0～27)	初期化しない
;	-1	取得のみ
;
;	以下は拡張
;	28		高	384x256		1024x1024	16	1
;	29		高	384x256		512x512		16	4
;	30		高	384x256		512x512		256	2
;	31		高	384x256		512x512		65536	1
;	32		高	512x512(正方形)	1024x1024	16	1
;	33		高	512x512(正方形)	512x512		16	4
;	34		高	512x512(正方形)	512x512		256	2
;	35		高	512x512(正方形)	512x512		65536	1
;	36		高	256x256(正方形)	1024x1024	16	1
;	37		高	256x256(正方形)	512x512		16	4
;	38		高	256x256(正方形)	512x512		256	2
;	39		高	256x256(正方形)	512x512		65536	1
;
;----------------------------------------------------------------
;	いろいろ
;
;	CRT向けとLCD向け
;		各画面モードの同期周波数をそれぞれCRT向けとLCD向けに分ける
;		SRAM_XEIJのSRAM_XEIJ_LCD_BITが0のときCRT向け、1のときLCD向けの同期周波数で出力する
;
;	画面モード17
;		水平24.699kHz、垂直53.116Hz、1024x424、実画面1024x1024、16色
;		X68000初代からあるが未公開
;		LCD向けのときは画面モード16の上下を削る
;
;	画面モード18
;		水平24.699kHz、垂直53.116Hz、1024x848(インターレース)、実画面1024x1024、16色
;		X68000初代からあるが未公開
;		LCD向けのときは画面モード16の上下を削ってインターレースにする
;
;	画面モード19(VGAモード)
;		水平31.469kHz、垂直59.940Hz、640x480、実画面1024x1024、16色
;		X68000 Compactで追加された
;		CRT向けのときは画面モード16の周囲を削る
;		LCD向けのときはそのまま
;
;	画面モード20～23
;		画面モード16～19を実画面512x512、256色に変更したもの
;		X68030で追加された。未公開
;
;	画面モード24～27
;		画面モード16～19を実画面512x512、65536色に変更したもの
;		X68030で追加された。未公開
;
;	グラフィックパレットのバグ(IPLROM 1.0～1.3)
;		_CRTMODが指定された画面モードと異なる色数でグラフィックパレットを初期化する
;			https://stdkmd.net/bugsx68k/#rom_crtmod_gpalet
;		256x256は16色、512x512は256色、それ以外は65536色になる
;
;	画面モード20～27のバグ(IPLROM 1.3)
;		画面モードに20～27が指定されたとき画面モードを16～19にしてから256色または65536色に変更しているが、
;		このときBIOSワークエリアの画面モードを16～19のまま放置している
;		続けて_G_CLR_ONを呼び出すと画面モードが16～19なので16色に戻ってしまう
;
;	クリッピングエリアのバグ(IPLROM 1.3)
;		_CRTMODで画面モードを22または26にするとクリッピングエリアが512x848になる
;
;	VGAオシレータの問題
;		初代～XVIにはVGAオシレータがないのでVGAモードが正しい同期周波数で出力されない
;		VGAオシレータがある場合
;			(50.350MHz/2)/(8*100)=31.469kHz
;			(50.350MHz/2)/(8*100*525)=59.940Hz
;		VGAオシレータがない場合
;			(69.552MHz/3)/(8*100)=28.980kHz
;			(69.552MHz/3)/(8*100*525)=55.200Hz
;		大きく外れるわけではないのでマルチスキャンモニタは追従できるが気持ち悪い
;
;	VGAオシレータの有無の判別
;		VGAモードの垂直周期はVGAオシレータがあるとき16.683ms、ないとき18.116ms
;		垂直同期割り込みの間にTimer-Cが1周10msと7.5ms進んだかどうかでVGAオシレータの有無を判別できるはず
;		後で試す？
;
;----------------------------------------------------------------
;	同期信号とCRTC設定値の関係
;
;	HT	水平周期カラム数
;	HS	水平同期パルスカラム数
;	HB	水平バックポーチカラム数
;	HD	水平映像期間カラム数
;	HF	水平フロントポーチカラム数
;	VT	垂直周期ラスタ数
;	VS	垂直同期パルスラスタ数
;	VB	垂直バックポーチラスタ数
;	VD	垂直映像期間ラスタ数
;	VF	垂直フロントポーチラスタ数
;
;	R00	HT-1=HS+HB+HD+HF-1	水平フロントポーチ終了カラム
;	R01	HS-1			水平同期パルス終了カラム
;	R02	HS+HB-5			水平バックポーチ終了カラム-4
;	R03	HS+HB+HD-5		水平映像期間終了カラム-4
;	R04	VT-1=VS+VB+VD+VF-1	垂直フロントポーチ終了ラスタ
;	R05	VS-1			垂直同期パルス終了ラスタ
;	R06	VS+VB-1			垂直バックポーチ終了ラスタ
;	R07	VS+VB+VD-1		垂直映像期間終了ラスタ
;
;----------------------------------------------------------------
;	オシレータと分周比とR20LとHRLの関係
;
;	OSC/DIV	R20L	HRL
;	38/8	%0**00	*
;	38/4	%0**01	*
;	38/8	%0**1*	*
;	69/6	%1**00	0
;	69/8	%1**00	1
;	69/3	%1**01	0
;	69/4	%1**01	1
;	69/2	%1**10	*	スプライト不可
;	50/2	%1**11	*	スプライト不可。Compactから
;
;----------------------------------------------------------------
;	CRTC設定値(CRT向け)
;
;	CRT 0/4/8/12: 512x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   91   9  17  81      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   92  10  12  64   6  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*92)=31.500kHz (69.552MHz/3)/(8*92*568)=55.458Hz
;	  64/92=0.696 512/568=0.901 (0.696/0.901)/(512/512)=0.772
;	  31k
;
;	CRT 1/5/9/13: 512x512 15.980kHz 61.463Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %00101   0   75   3   5  69      259   2  16 256     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 38.864   4   76   4   6  64   2  260   3  14 240   3 |
;	  +------------------------------------------------------+
;	  (38.864MHz/4)/(8*76)=15.980kHz (38.864MHz/4)/(8*76*260)=61.463Hz
;	  64/76=0.842 240/260=0.923 (0.842/0.923)/(512/512)=0.912
;	  15k インターレース
;
;	CRT 2/6/10/14: 256x256 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   45   4   6  38      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   46   5   6  32   3  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*46)=31.500kHz (69.552MHz/6)/(8*46*568)=55.458Hz
;	  32/46=0.696 512/568=0.901 (0.696/0.901)/(256/256)=0.772
;	  31k ラスタ2度読み
;
;	CRT 3/7/11/15: 256x256 15.980kHz 61.463Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %00000   0   37   1   0  32      259   2  16 256     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 38.864   8   38   2   3  32   1  260   3  14 240   3 |
;	  +------------------------------------------------------+
;	  (38.864MHz/8)/(8*38)=15.980kHz (38.864MHz/8)/(8*38*260)=61.463Hz
;	  32/38=0.842 240/260=0.923 (0.842/0.923)/(256/256)=0.912
;	  15k
;
;	CRT 16/20/24: 768x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  28 124      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  18  96   9  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  96/138=0.696 512/568=0.901 (0.696/0.901)/(768/512)=0.514
;	  31k
;
;	CRT 17/21/25: 1024x424 24.699kHz 53.116Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  175  15  31 159      464   7  32 456     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  176  16  20 128  12  465   8  25 424   8 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*176)=24.699kHz (69.552MHz/2)/(8*176*465)=53.116Hz
;	  128/176=0.727 424/465=0.912 (0.727/0.912)/(1024/424)=0.330
;	  24k
;
;	CRT 18/22/26: 1024x848 24.699kHz 53.116Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %11010   0  175  15  31 159      464   7  32 456     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  176  16  20 128  12  465   8  25 424   8 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*176)=24.699kHz (69.552MHz/2)/(8*176*465)=53.116Hz
;	  128/176=0.727 424/465=0.912 (0.727/0.912)/(1024/848)=0.661
;	  24k インターレース
;
;	CRT 19/23/27: 640x480 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  36 116      567   5  56 536     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  26  80  17  568   6  51 480  31 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  80/138=0.580 480/568=0.845 (0.580/0.845)/(640/480)=0.514
;	  31k
;
;	CRT 28/29/30/31: 384x256 31.963kHz 56.273Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  11  59      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7   9  48   4  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*568)=56.273Hz
;	  48/68=0.706 512/568=0.901 (0.706/0.901)/(384/256)=0.522
;	  31k ラスタ2度読み
;
;	CRT 32/33/34/35: 512x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  44 108      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  34  64  25  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  64/138=0.464 512/568=0.901 (0.464/0.901)/(512/512)=0.514
;	  31k
;
;	CRT 36/37/38/39: 256x256 31.963kHz 56.273Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  19  51      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7  17  32  12  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*568)=56.273Hz
;	  32/68=0.471 512/568=0.901 (0.471/0.901)/(256/256)=0.522
;	  31k ラスタ2度読み
;
;----------------------------------------------------------------
;	CRTC設定値(LCD向け)
;
;	LCD 0/4/8/12: 512x512 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   81   5  11  75      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 512/625=0.819 (0.780/0.819)/(512/512)=0.953
;	  SVGA
;
;	LCD 1/5/9/13: 512x512 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   81   5  11  75      624   1  83 563     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  82 480  61 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 480/625=0.768 (0.780/0.768)/(512/512)=1.016
;	  SVGA
;
;	LCD 2/6/10/14: 256x256 34.500kHz 55.200Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   41   2   3  35      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   42   3   5  32   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*42)=34.500kHz (69.552MHz/6)/(8*42*625)=55.200Hz
;	  32/42=0.762 512/625=0.819 (0.762/0.819)/(256/256)=0.930
;	  SVGA ラスタ2度読み
;
;	LCD 3/7/11/15: 256x256 34.500kHz 55.200Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   41   2   3  35      624   1  83 563     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   42   3   5  32   2  625   2  82 480  61 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*42)=34.500kHz (69.552MHz/6)/(8*42*625)=55.200Hz
;	  32/42=0.762 480/625=0.768 (0.762/0.768)/(256/256)=0.992
;	  SVGA ラスタ2度読み
;
;	LCD 16/20/24: 768x512 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  19 115      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 512/625=0.819 (0.774/0.819)/(768/512)=0.630
;	  SVGA
;
;	LCD 17/21/25: 768x600 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  19 115      624   1  23 623     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  22 600   1 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 600/625=0.960 (0.774/0.960)/(768/600)=0.630
;	  SVGA
;
;	LCD 18/22/26: 768x1024 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %11010   0  123   8  19 115      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 512/625=0.819 (0.774/0.819)/(768/1024)=1.260
;	  SVGA インターレース
;
;	LCD 19/23/27: 640x480 31.469kHz 59.940Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10111   0   99  11  13  93      524   1  34 514     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 50.350   2  100  12   6  80   2  525   2  33 480  10 |
;	  +------------------------------------------------------+
;	  (50.350MHz/2)/(8*100)=31.469kHz (50.350MHz/2)/(8*100*525)=59.940Hz
;	  80/100=0.800 480/525=0.914 (0.800/0.914)/(640/480)=0.656
;	  VGA
;
;	LCD 28/29/30/31: 384x256 31.963kHz 51.141Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  11  59      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7   9  48   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*625)=51.141Hz
;	  48/68=0.706 512/625=0.819 (0.706/0.819)/(384/256)=0.574
;	  ラスタ2度読み
;
;	LCD 32/33/34/35: 512x512 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  35  99      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  31  64  20  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  64/124=0.516 512/625=0.819 (0.516/0.819)/(512/512)=0.630
;	  SVGA
;
;	LCD 36/37/38/39: 256x256 31.963kHz 51.141Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  19  51      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7  17  32  12  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*625)=51.141Hz
;	  32/68=0.471 512/625=0.819 (0.471/0.819)/(256/256)=0.574
;	  ラスタ2度読み
;
;	【参考】VGA: 640x480 31.469kHz 59.940Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 25.175      100  12   6  80   2  525   2  33 480  10 |
;	  +------------------------------------------------------+
;	  25.175MHz/(8*100)=31.469kHz (25.175MHz/1)/(8*100*525)=59.940Hz
;	  80/100=0.800 480/525=0.914 (0.800/0.914)/(640/480)=0.656
;
;	【参考】SVGA: 800x600 35.156kHz 56.250Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 36.000      128   9  16 100   3  625   2  22 600   1 |
;	  +------------------------------------------------------+
;	  36.000MHz/(8*128)=35.156kHz (36.000MHz/1)/(8*128*625)=56.250Hz
;	  100/128=0.781 600/625=0.960 (0.781/0.960)/(800/600)=0.610
;
;	【参考】SVGA: 800x600 37.879kHz 60.317Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 40.000      132  16  11 100   5  628   4  23 600   1 |
;	  +------------------------------------------------------+
;	  40.000MHz/(8*132)=37.879kHz (40.000MHz/1)/(8*132*628)=60.317Hz
;	  100/132=0.758 600/628=0.955 (0.758/0.955)/(800/600)=0.595
;
;	【参考】SVGA: 800x600 46.875kHz 75.000Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 49.500      132  10  20 100   2  625   3  21 600   1 |
;	  +------------------------------------------------------+
;	  49.500MHz/(8*132)=46.875kHz (49.500MHz/1)/(8*132*625)=75.000Hz
;	  100/132=0.758 600/625=0.960 (0.758/0.960)/(800/600)=0.592
;
;----------------------------------------------------------------

;パラメータ1
	.offset	0
crtmod_param_1_width:	.ds.w	1
crtmod_param_1_height:	.ds.w	1
crtmod_param_1_r20h:	.ds.b	1
			.ds.b	1
crtmod_param_1_2nd:	.ds.w	1
crtmod_param_1_size:
	.text

;パラメータ2
	.offset	0
crtmod_param_2_r20l:	.ds.b	1
crtmod_param_2_hrl:	.ds.b	1
crtmod_param_2_r00:	.ds.w	1
crtmod_param_2_r01:	.ds.w	1
crtmod_param_2_r02:	.ds.w	1
crtmod_param_2_r03:	.ds.w	1
crtmod_param_2_r04:	.ds.w	1
crtmod_param_2_r05:	.ds.w	1
crtmod_param_2_r06:	.ds.w	1
crtmod_param_2_r07:	.ds.w	1
crtmod_param_2_r08:	.ds.w	1
crtmod_param_2_size:
	.text

crtmod_param_1	.macro	width,height,r20h,offset2nd
	.dc.w	width
	.dc.w	height
	.dc.b	r20h			;R20H
	.dc.b	0
	.dc.w	crtmod_param_2_size*offset2nd
	.endm

crtmod_param_2	.macro	r20l,hrl,ht,hs,hb,hd,hf,vt,vs,vb,vd,vf,r08
  .if TESTS
;	.fail	(ht.and.1)!=0
  .else
	.fail	(ht.and.1)!=0
  .endif
	.fail	ht!=hs+hb+hd+hf
	.fail	vt!=vs+vb+vd+vf
	.dc.b	r20l			;R20L
	.dc.b	hrl			;HRL
	.dc.w	hs+hb+hd+hf-1		;R00
	.dc.w	hs-1			;R01
	.dc.w	hs+hb-5			;R02
	.dc.w	hs+hb+hd-5		;R03
	.dc.w	vs+vb+vd+vf-1		;R04
	.dc.w	vs-1			;R05
	.dc.w	vs+vb-1			;R06
	.dc.w	vs+vb+vd-1		;R07
	.dc.w	r08			;R08
	.endm

crtmod_modes	equ	(crtmod_table_1_crt_end-crtmod_table_1_crt)/crtmod_param_1_size	;画面モードの数

	.text
	.even
iocs_10_CRTMOD:

;バージョン確認
	move.l	#CRTMOD_VERSION,d0
	goto	<cmp.w #$56FF,d1>,eq,@f
	if	<cmp.w #$16FF,d1>,eq
		if	<btst.b #SRAM_XEIJ_LCD_BIT,SRAM_XEIJ>,ne
			bset.l	#31,d0
		endif
@@:		rts
	endif

	push	d1/d2/d3/d7/a0/a1/a3/a4/a5/a6

;(～)OOでアクセスする
;	$00E80000	CRTC
;	$00E82000	VICON
;	$00E84000	DMAC
;	$00E86000	SUPERAREA
;	$00E88000	MFP
;	$00E8A000	RTC
;	$00E8C000	PRNPORT
;	$00E8E000	SYSPORT
	lea.l	$00E88000,a6
OO	reg	-$00E88000(a6)
;<a6.l:(～)OOのベースアドレス

;(～)SSでアクセスする
;	$00EB0000	SPRC
	lea.l	$00EB8000,a3
SS	reg	-$00EB8000(a3)
;<a3.l:(～)SSのベースアドレス

;設定前の画面モードを確認する
	moveq.l	#0,d7
	move.b	BIOS_CRTMOD.w,d7	;設定前の画面モード
	swap.w	d7
;<d7.l:設定前の画面モード<<16

;初期化するか
	move.w	d1,d7
	clr.b	d7
	sub.w	d7,d1
;<d1.w:画面モード
;<d7.w:$0000=初期化する,$0100=初期化しない,$4300=CRT向け,$4C00=LCD向け

;CRT向けとLCD向けのスイッチの切り替え
	if	<cmp.w #$4300,d7>,eq	;CRT向け
		unlocksram
		bclr.b	#SRAM_XEIJ_LCD_BIT,SRAM_XEIJ
		locksram
		clr.w	d7			;初期化する
	elif	<cmp.w #$4C00,d7>,eq	;LCD向け
		unlocksram
		bset.b	#SRAM_XEIJ_LCD_BIT,SRAM_XEIJ
		locksram
		clr.w	d7			;初期化する
	endif
;<d7.w:$0000=初期化する,$0100=初期化しない

;取得のみか
;	IPLROM 1.0～1.3は$FFFFを除いて設定後の画面モードが範囲外のとき何もしない
;	ここでは$FFFFを含めて設定後の画面モードが範囲外のとき取得のみとする
;	ただし$43FFと$4CFFはCRT向けとLCD向けのスイッチの切り替えだけ行う
	goto	<cmp.w #crtmod_modes,d1>,hs,crtmod_end	;設定後の画面モードが範囲外

;設定する

;パラメータ1のアドレスを求める
	lea.l	crtmod_table_1_crt(pc),a4
	if	<btst.b #SRAM_XEIJ_LCD_BIT,SRAM_XEIJ>,ne	;LCD向け
		lea.l	crtmod_table_1_lcd(pc),a4
	endif
	move.w	d1,d0
  .if crtmod_param_1_size=8
	lsl.w	#3,d0
  .else
	mulu.w	#crtmod_param_1_size,d0
  .endif
	adda.w	d0,a4
;<a4.l:パラメータ1のアドレス

;パラメータ2のアドレスを求める
	lea.l	crtmod_table_2(pc),a5
  .if TESTS
	lsl.l	#2,d2
	movea.l	(a5,d2.w),a5
  .endif
	adda.w	crtmod_param_1_2nd(a4),a5
;<a5.l:パラメータ2のアドレス

;メモリモードを確認する
	moveq.l	#7,d3
	and.b	crtmod_param_1_r20h(a4),d3	;メモリモード。0～7
;<d3.w:メモリモード。0～7

;初期化するか
	if	<tst.w d7>,eq

	;初期化する

	;設定後の画面モードを保存する
		move.b	d1,BIOS_CRTMOD.w	;設定後の画面モード

	;グラフィック画面OFF、テキスト画面OFF、スプライト画面OFF
		clr.w	(VICON_VISIBLE)OO

	;テキストカーソルOFF
		IOCS	_B_CUROFF

	;テキストプレーン0～1をクリアする
	;	ラスタコピーを使うと速いがコードが長くなる
	;	初回はCRTCが動いていないのでラスタコピーが終わらない
		move.w	#$0133,(CRTC_ACCESS)OO	;同時アクセス開始
		moveq.l	#0,d0
		lea.l	$00E00000,a0		;テキストVRAM
		move.w	#($00E20000-$00E00000)/(4*2)-1,d1	;16384回
		for	d1
			move.l	d0,(a0)+
			move.l	d0,(a0)+
		next
		move.w	#$0033,(CRTC_ACCESS)OO	;同時アクセス終了

	;グラフィック画面使用不可
		clr.w	BIOS_GRAPHIC_PALETS.w	;グラフィック画面の色数-1。0=グラフィック画面使用不可

	;初期化する/しない共通
		bsr	crtmod_common

	;CRTCコマンド停止
		clr.w	(CRTC_ACTION)OO

	;グラフィックパレットを初期化する
		move.w	d3,d0			;メモリモード。0～7
		bsr	initialize_gpalet	;グラフィックパレットを初期化する

	;グラフィックストレージON
	;	IPLROM 1.0～1.3の_CRTMODはグラフィックストレージONの状態で復帰する
		bset.b	#CRTC_GRAPHIC_STORAGE_BIT,(CRTC_MODE_BYTE)OO	;グラフィックストレージON

	;テキストカーソルON
		IOCS	_B_CURON

	;テキストパレットを初期化する
		lea.l	SRAM_TEXT_PALET_0,a0
		lea.l	(VICON_TSPALET)OO,a1
		move.l	(a0)+,(a1)+		;0,1
		move.l	(a0)+,(a1)+		;2,3
		move.l	(a0),d0			;d0=4|8
		move.l	d0,d1			;d1=4|8
		swap.w	d0			;d0=8|4
		move.w	d0,(a1)+		;4
		move.w	d0,(a1)+		;5
		move.w	d0,(a1)+		;6
		move.w	d0,(a1)+		;7
		move.w	d1,d0			;d0=8|8
		move.l	d0,(a1)+		;8,9
		move.l	d0,(a1)+		;10,11
		move.l	d0,(a1)+		;12,13
		move.l	d0,(a1)+		;14,15

	;コントラストを初期化する
		move.b	SRAM_CONTRAST,(SYSPORT_CONTRAST)OO

	;スプライトコントローラを設定する
~i = SPRC_SPRITE_OFF|SPRC_BG_1_TEXT_1|SPRC_BG_1_OFF|SPRC_BG_0_TEXT_0|SPRC_BG_0_OFF
		move.w	#~i,SPRC_CONTROL

	;テキスト画面ON
		move.w	#VICON_TXON_MASK,(VICON_VISIBLE)OO

	;優先順位を設定する
~i = 0<<VICON_SPPR_BIT|1<<VICON_TXPR_BIT|2<<VICON_GRPR_BIT			;SP>TX>GR
~j = 3<<VICON_G4TH_BIT|2<<VICON_G3RD_BIT|1<<VICON_G2ND_BIT|0<<VICON_G1ST_BIT	;G1>G2>G3>G4
		move.w	#~i|~j,(VICON_PRIORITY)OO

	else

	;初期化しない

	;設定後の画面モードを保存する
		move.b	d1,BIOS_CRTMOD.w	;設定後の画面モード

	;グラフィック画面使用不可
		clr.w	BIOS_GRAPHIC_PALETS.w	;グラフィック画面の色数-1。0=グラフィック画面使用不可

	;初期化する/しない共通
		bsr	crtmod_common

	;グラフィック画面が表示されているか
		moveq.l	#VICON_GXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,d0
		and.w	(VICON_VISIBLE)OO,d0
		if	ne			;グラフィック画面が表示されているとき

		;メモリモードを設定する
		;	ストレージは変化しない
			andi.b	#.notb.7,(CRTC_MODE_BYTE)OO
			or.b	d3,(CRTC_MODE_BYTE)OO
			move.w	d3,(VICON_MEMORY_MODE)OO

		;BIOSワークエリアを初期化する
			move.l	#$00C00000,BIOS_GRAPHIC_PAGE.w
			if	<cmp.w #4,d3>,lo	;メモリモード0～3。512x512ドット
				move.l	#2*512,BIOS_GRAPHIC_Y_OFFSET.w
				if	<cmp.w #1,d3>,lo	;メモリモード0。512x512ドット、16色、4ページ
					move.w	#16-1,BIOS_GRAPHIC_PALETS.w
				elif	eq			;メモリモード1。512x512ドット、256色、2ページ
					move.w	#256-1,BIOS_GRAPHIC_PALETS.w
				else				;メモリモード2～3。512x512ドット、65536色、1ページ
					move.w	#65536-1,BIOS_GRAPHIC_PALETS.w
				endif
			else					;メモリモード4～7。1024x1024ドット、16色、1ページ
				move.l	#2*1024,BIOS_GRAPHIC_Y_OFFSET.w
				move.w	#16-1,BIOS_GRAPHIC_PALETS.w
			endif

		endif

	endif

;終了
;<d7.l:設定前の画面モード<<16
crtmod_end:
	clr.w	d7
	swap.w	d7			;設定前の画面モード
	move.l	d7,d0
	pop
	rts

;初期化する/しない共通
crtmod_common:

;CRTCとシステムポートのR20,HRL,R00～R07を設定する
;	すべての画面モードがメモリモード3になる
;	ストレージはOFFになる
	move.w	#3<<8,d2		;R20H(新)
	move.b	crtmod_param_2_r20l(a5),d2	;R20L(新)
;<d2.w:R20(新)
	lea.l	dot_clock_rank(pc),a0
	moveq.l	#%00011111,d0
	and.b	(CRTC_RESOLUTION_BYTE)OO,d0	;R20L(古)
	moveq.l	#SYSPORT_HRL,d1
	and.b	(SYSPORT_MISC)OO,d1
	neg.b	d1
	addx.b	d0,d0				;R20L<<1|HRL(古)
	move.b	(a0,d0.w),d0			;古いドットクロックのランク
	moveq.l	#%00011111,d1
	and.b	d2,d1				;R20L(新)
	add.b	d1,d1
	add.b	crtmod_param_2_hrl(a5),d1	;R20L<<1|HRL(新)
	move.b	(a0,d1.w),d1			;新しいドットクロックのランク
	if	<cmp.b d0,d1>,lo	;ドットクロックが下がる
		move.w	d2,(CRTC_MODE_RESOLUTION)OO	;R20
		tst.b	crtmod_param_2_hrl(a5)
		bsne.b	#SYSPORT_HRL_BIT,(SYSPORT_MISC)OO	;HRL
		lea.l	(CRTC_H_SYNC_END)OO,a0	;R01
		lea.l	crtmod_param_2_r01(a5),a1
		move.w	(a1)+,(a0)+		;R01
		move.l	(a1)+,(a0)+		;R02,R03
		move.l	(a1)+,(a0)+		;R04,R05
		move.l	(a1)+,(a0)+		;R06,R07
		move.w	crtmod_param_2_r00(a5),(CRTC_H_FRONT_END)OO	;R00
	else				;ドットクロックが同じか上がる
		lea.l	(CRTC_H_FRONT_END)OO,a0	;R00
		lea.l	crtmod_param_2_r00(a5),a1
		move.l	(a1)+,(a0)+		;R00,R01
		move.l	(a1)+,(a0)+		;R02,R03
		move.l	(a1)+,(a0)+		;R04,R05
		move.l	(a1)+,(a0)+		;R06,R07
		move.w	d2,(CRTC_MODE_RESOLUTION)OO	;R20
		tst.b	crtmod_param_2_hrl(a5)
		bsne.b	#SYSPORT_HRL_BIT,(SYSPORT_MISC)OO	;HRL
	endif

;CRTCのR08を設定する
;	外部同期水平アジャスト
;	スーパーインポーズするときビデオの映像とX68000の映像を重ねるために、
;	ビデオとX68000の水平同期パルスの先頭の時間差を38.863632MHzのサイクル数で指定する
;	低解像度512x512のとき
;		水平同期パルス幅は4キャラクタ。R01=4-1=3
;		水平バックポーチは6キャラクタ。R02=4+6-5=5
;		外部同期水平アジャストは44
;		perl -e "print((4.7+4.7)*38.863632-(4*8*(4+6))-1)"
;		44.3181408
;	低解像度256x256のとき。1ドット追加する
;		水平同期パルス幅は2キャラクタ。R01=2-1=1
;		水平バックポーチは3キャラクタ。R02=2+3-5=0
;		外部同期水平アジャストは36
;		perl -e "print((4.7+4.7)*38.863632-(8*(8*(2+3)+1))-1)"
;		36.3181408
	move.w	crtmod_param_2_r08(a5),(CRTC_ADJUST)OO	;R08

;CRTCのR09～R19,R21～R24を初期化する
	moveq.l	#0,d0
	lea.l	(CRTC_RASTER)OO,a0	;R09
	move.w	d0,(a0)+		;R09
	move.l	d0,(a0)+		;R10,R11
	move.l	d0,(a0)+		;R12,R13
	move.l	d0,(a0)+		;R14,R15
	move.l	d0,(a0)+		;R16,R17
	move.l	d0,(a0)+		;R18,R19
	addq.l	#2,a0
	move.w	#$0033,(a0)+		;R21
	move.l	d0,(a0)+		;R22,R23
	move.w	d0,(a0)+		;R24

;ビデオコントローラのメモリモードを設定する
;	すべての画面モードがメモリモード3になる
	move.w	#3,(VICON_MEMORY_MODE)OO

;スプライトコントローラを初期化する
;	スプライトはR20Lの下位5ビットが%1_??_1?のとき無効
	moveq.l	#%1_00_10,d0
	and.b	crtmod_param_2_r20l(a5),d0	;R20L
	if	<cmp.w #%1_00_10,d0>,eq	;スプライトが無効
		move.w	#255,d1
		move.w	d1,(SPRC_H_BACK_END)SS	;スプライト水平バックポーチ終了カラム
		moveq.l	#500/50,d0		;500us
		bsr	wait_50us		;50us単位のウェイト
		move.w	d1,(SPRC_H_FRONT_END)SS	;スプライト水平フロントポーチ終了カラム
		move.w	d1,(SPRC_V_BACK_END)SS	;スプライト垂直バックポーチ終了ラスタ
		move.w	d1,(SPRC_RESOLUTION)SS	;スプライト解像度。--------|---|高解像度|垂直サイズ##|水平サイズ##
	else				;スプライトが有効
	;解像度
		moveq.l	#%1_11_11,d1
		and.b	crtmod_param_2_r20l(a5),d1	;R20L
	;<d1.w:解像度
	;水平バックポーチ終了カラム
		moveq.l	#4,d0
		add.w	crtmod_param_2_r02(a5),d0
		move.w	d0,(SPRC_H_BACK_END)SS	;スプライト水平バックポーチ終了カラム。R02+4
	;水平フロントポーチ終了カラム
	;	水平バックポーチ終了カラムを設定後130us待ってから水平フロントポーチ終了カラムを設定する
	;	水平フロントポーチ終了カラムは水平256ドットのときはR00と同じ値、それ以外は255
	;		Inside X68000に低解像度256x256のときだけR00と同じ値を、それ以外は255を設定すると書かれているが、
	;		高解像度256x256のときも255にするとスプライトが崩れる場合がある
	;		水平512ドットのときは255にしないと水平256ドットから水平512ドットに切り替えたときスプライトの水平方向の位置がずれることがある
	;	IPLROM 1.3はdbraでX68030 25MHzのとき500us待っている。060turboのときウエイトが不足する
		moveq.l	#500/50,d0		;500us
		bsr	wait_50us		;50us単位のウェイト
		moveq.l	#%0_00_11,d0
		and.b	d1,d0
		if	eq			;水平256ドット
			move.w	crtmod_param_2_r00(a5),(SPRC_H_FRONT_END)SS	;スプライト水平フロントポーチ終了カラム。R00
		else				;水平256ドット以外
			move.w	#255,(SPRC_H_FRONT_END)SS	;スプライト水平フロントポーチ終了カラム。255
		endif
	;垂直バックポーチ終了ラスタ
		move.w	crtmod_param_2_r06(a5),(SPRC_V_BACK_END)SS	;スプライト垂直バックポーチ終了ラスタ。R06
	;解像度
		ifand	<cmp.w #%10001,d1>,eq,<cmpi.w #256,crtmod_param_1_width(a4)>,eq	;解像度が512x256で幅が256のとき
			moveq.l	#%10000,d1		;スプライトを256x256にする
		endif
		move.w	d1,(SPRC_RESOLUTION)SS	;スプライト解像度。--------|---|高解像度|垂直サイズ##|水平サイズ##
	endif

;グラフィック画面のクリッピングエリア
;	画面モード20～27は表示画面が実画面より大きいことに注意する
	move.w	crtmod_param_1_width(a4),d0	;幅
	move.w	crtmod_param_1_height(a4),d1	;高さ
	if	<cmp.w #4,d3>,lo	;メモリモード0～3。512x512まで
		move.w	#512,d2
		if	<cmp.w d2,d0>,hi
			move.w	d2,d0
		endif
		if	<cmp.w d2,d1>,hi
			move.w	d2,d1
		endif
	endif
	subq.w	#1,d0			;X最大
	subq.w	#1,d1			;Y最大
	clr.l	BIOS_GRAPHIC_LEFT.w	;BIOS_GRAPHIC_TOP
	move.w	d0,BIOS_GRAPHIC_RIGHT.w
	move.w	d1,BIOS_GRAPHIC_BOTTOM.w

;グラフィックVRAMのY方向のオフセット
					;d3=0 1 2 3 4 5 6 7
	moveq.l	#4,d0			;d0=4 4 4 4 4 4 4 4
	and.w	d3,d0			;d0=0 0 0 0 4 4 4 4
	addq.w	#4,d0			;d0=4 4 4 4 8 8 8 8
	lsl.w	#8,d0			;d0=1024 1024 1024 1024 2048 2048 2048 2048
	move.l	d0,BIOS_GRAPHIC_Y_OFFSET.w

;グラフィック画面のページ数
					;d3=0 1 2  3  4  5  6  7
	moveq.l	#4,d0			;d0=4 4 4  4  4  4  4  4
	lsr.b	d3,d0			;d0=4 2 1  0  0  0  0  0
	seq.b	d1			;d1=0 0 0 -1 -1 -1 -1 -1
	sub.b	d1,d0			;d0=4 2 1  1  1  1  1  1
	move.b	d0,BIOS_GRAPHIC_PAGES.w

;テキスト画面の位置
	move.l	#$00E00000,BIOS_TEXT_PLANE.w
	clr.l	BIOS_CONSOLE_OFFSET.w

;テキスト画面の大きさ
	move.w	crtmod_param_1_width(a4),d0	;幅
	move.w	crtmod_param_1_height(a4),d1	;高さ
	lsr.w	#3,d0			;幅/8
	lsr.w	#4,d1			;高さ/16。424は16で割り切れないことに注意
	subq.w	#1,d0			;幅/8-1
	subq.w	#1,d1			;高さ/16-1
	move.w	d0,BIOS_CONSOLE_RIGHT.w
	move.w	d1,BIOS_CONSOLE_BOTTOM.w

;テキストカーソルの位置
	clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW

;マウスカーソルの移動範囲
	clr.l	d1
	move.l	BIOS_GRAPHIC_RIGHT,d2	;BIOS_GRAPHIC_BOTTOM
	IOCS	_MS_LIMIT		;IOCSコール$77 _MS_LIMIT マウスカーソルの移動範囲を設定する

	rts

;パラメータ1(CRT向け)
crtmod_table_1_crt:
;			 WIDTH HEIGHT R20H  2ND    1ST
	crtmod_param_1	   512,   512,   4,   0  ; CRT 0
	crtmod_param_1	   512,   512,   4,   1  ; CRT 1
	crtmod_param_1	   256,   256,   4,   2  ; CRT 2
	crtmod_param_1	   256,   256,   4,   3  ; CRT 3
	crtmod_param_1	   512,   512,   0,   0  ; CRT 4
	crtmod_param_1	   512,   512,   0,   1  ; CRT 5
	crtmod_param_1	   256,   256,   0,   2  ; CRT 6
	crtmod_param_1	   256,   256,   0,   3  ; CRT 7
	crtmod_param_1	   512,   512,   1,   0  ; CRT 8
	crtmod_param_1	   512,   512,   1,   1  ; CRT 9
	crtmod_param_1	   256,   256,   1,   2  ; CRT 10
	crtmod_param_1	   256,   256,   1,   3  ; CRT 11
	crtmod_param_1	   512,   512,   3,   0  ; CRT 12
	crtmod_param_1	   512,   512,   3,   1  ; CRT 13
	crtmod_param_1	   256,   256,   3,   2  ; CRT 14
	crtmod_param_1	   256,   256,   3,   3  ; CRT 15
	crtmod_param_1	   768,   512,   4,   4  ; CRT 16
	crtmod_param_1	  1024,   424,   4,   5  ; CRT 17
	crtmod_param_1	  1024,   848,   4,   6  ; CRT 18
	crtmod_param_1	   640,   480,   4,   7  ; CRT 19
	crtmod_param_1	   768,   512,   1,   4  ; CRT 20
	crtmod_param_1	  1024,   424,   1,   5  ; CRT 21
	crtmod_param_1	  1024,   848,   1,   6  ; CRT 22
	crtmod_param_1	   640,   480,   1,   7  ; CRT 23
	crtmod_param_1	   768,   512,   3,   4  ; CRT 24
	crtmod_param_1	  1024,   424,   3,   5  ; CRT 25
	crtmod_param_1	  1024,   848,   3,   6  ; CRT 26
	crtmod_param_1	   640,   480,   3,   7  ; CRT 27
	crtmod_param_1	   384,   256,   4,   8  ; CRT 28
	crtmod_param_1	   384,   256,   0,   8  ; CRT 29
	crtmod_param_1	   384,   256,   1,   8  ; CRT 30
	crtmod_param_1	   384,   256,   3,   8  ; CRT 31
	crtmod_param_1	   512,   512,   4,   9  ; CRT 32
	crtmod_param_1	   512,   512,   0,   9  ; CRT 33
	crtmod_param_1	   512,   512,   1,   9  ; CRT 34
	crtmod_param_1	   512,   512,   3,   9  ; CRT 35
	crtmod_param_1	   256,   256,   4,  10  ; CRT 36
	crtmod_param_1	   256,   256,   0,  10  ; CRT 37
	crtmod_param_1	   256,   256,   1,  10  ; CRT 38
	crtmod_param_1	   256,   256,   3,  10  ; CRT 39
crtmod_table_1_crt_end:

;パラメータ1(LCD向け)
crtmod_table_1_lcd:
;			 WIDTH HEIGHT R20H  2ND    1ST
	crtmod_param_1	   512,   512,   4,  11  ; LCD 0
	crtmod_param_1	   512,   512,   4,  12  ; LCD 1
	crtmod_param_1	   256,   256,   4,  13  ; LCD 2
	crtmod_param_1	   256,   256,   4,  14  ; LCD 3
	crtmod_param_1	   512,   512,   0,  11  ; LCD 4
	crtmod_param_1	   512,   512,   0,  12  ; LCD 5
	crtmod_param_1	   256,   256,   0,  13  ; LCD 6
	crtmod_param_1	   256,   256,   0,  14  ; LCD 7
	crtmod_param_1	   512,   512,   1,  11  ; LCD 8
	crtmod_param_1	   512,   512,   1,  12  ; LCD 9
	crtmod_param_1	   256,   256,   1,  13  ; LCD 10
	crtmod_param_1	   256,   256,   1,  14  ; LCD 11
	crtmod_param_1	   512,   512,   3,  11  ; LCD 12
	crtmod_param_1	   512,   512,   3,  12  ; LCD 13
	crtmod_param_1	   256,   256,   3,  13  ; LCD 14
	crtmod_param_1	   256,   256,   3,  14  ; LCD 15
	crtmod_param_1	   768,   512,   4,  15  ; LCD 16
	crtmod_param_1	   768,   600,   4,  16  ; LCD 17
	crtmod_param_1	   768,  1024,   4,  17  ; LCD 18
	crtmod_param_1	   640,   480,   4,  18  ; LCD 19
	crtmod_param_1	   768,   512,   1,  15  ; LCD 20
	crtmod_param_1	   768,   600,   1,  16  ; LCD 21
	crtmod_param_1	   768,  1024,   1,  17  ; LCD 22
	crtmod_param_1	   640,   480,   1,  18  ; LCD 23
	crtmod_param_1	   768,   512,   3,  15  ; LCD 24
	crtmod_param_1	   768,   600,   3,  16  ; LCD 25
	crtmod_param_1	   768,  1024,   3,  17  ; LCD 26
	crtmod_param_1	   640,   480,   3,  18  ; LCD 27
	crtmod_param_1	   384,   256,   4,  19  ; LCD 28
	crtmod_param_1	   384,   256,   0,  19  ; LCD 29
	crtmod_param_1	   384,   256,   1,  19  ; LCD 30
	crtmod_param_1	   384,   256,   3,  19  ; LCD 31
	crtmod_param_1	   512,   512,   4,  20  ; LCD 32
	crtmod_param_1	   512,   512,   0,  20  ; LCD 33
	crtmod_param_1	   512,   512,   1,  20  ; LCD 34
	crtmod_param_1	   512,   512,   3,  20  ; LCD 35
	crtmod_param_1	   256,   256,   4,  21  ; LCD 36
	crtmod_param_1	   256,   256,   0,  21  ; LCD 37
	crtmod_param_1	   256,   256,   1,  21  ; LCD 38
	crtmod_param_1	   256,   256,   3,  21  ; LCD 39

;パラメータ2
crtmod_table_2:
  .if TESTS
n=0
    .rept TESTS
	.dc.l	crtmod_table_2_%n
n=n+1
    .endm
n=0
    .rept TESTS
crtmod_table_2_%n:
;			   R20L  HRL    HT   HS   HB   HD   HF    VT   VS   VB   VD   VF   R08    2ND  1ST
	crtmod_param_2	 %10101,   0,   92,  10,  12,  64,   6,  568,   6,  35, 512,  15,   27  ;   0  CRT 0/4/8/12
	crtmod_param_2	 %00101,   0,   76,   4,   6,  64,   2,  260,   3,  14, 240,   3,   44  ;   1  CRT 1/5/9/13
	crtmod_param_2	 %10000,   0,   46,   5,   6,  32,   3,  568,   6,  35, 512,  15,   27  ;   2  CRT 2/6/10/14
	crtmod_param_2	 %00000,   0,   38,   2,   3,  32,   1,  260,   3,  14, 240,   3,   36  ;   3  CRT 3/7/11/15
	crtmod_param_2	 %10110,   0,  138,  15,  18,  96,   9,  568,   6,  35, 512,  15,   27  ;   4  CRT 16/20/24
	crtmod_param_2	 %10110,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   5  CRT 17/21/25
	crtmod_param_2	 %11010,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   6  CRT 18/22/26
	crtmod_param_2	 %10110,   0,  138,  15,  26,  80,  17,  568,   6,  51, 480,  31,   27  ;   7  CRT 19/23/27
      .if n=0
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=1
	crtmod_param_2	 %10001,   1, 68+1, 7-1,   9,  48, 4+2,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=2
	crtmod_param_2	 %10001,   1, 68+1, 7-1, 9+1,  48, 4+1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=3
	crtmod_param_2	 %10001,   1, 68+1, 7-1, 9+2,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=4
	crtmod_param_2	 %10001,   1, 68+1,   7, 9-1,  48, 4+2,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=5
	crtmod_param_2	 %10001,   1, 68+1,   7,   9,  48, 4+1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=6
	crtmod_param_2	 %10001,   1, 68+1,   7, 9+1,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=7
	crtmod_param_2	 %10001,   1, 68+1,   7, 9+2,  48, 4-1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=8
	crtmod_param_2	 %10001,   1, 68+1, 7+1, 9-1,  48, 4+1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=9
	crtmod_param_2	 %10001,   1, 68+1, 7+1,   9,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=10
	crtmod_param_2	 %10001,   1, 68+1, 7+1, 9+1,  48, 4-1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=11
	crtmod_param_2	 %10001,   1, 68+1, 7+2, 9-1,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=12
	crtmod_param_2	 %10001,   1, 68+1, 7+2,   9,  48, 4-1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .elif n=13
	crtmod_param_2	 %10001,   1, 68+2, 7+1,   9,  48, 4+1,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
      .endif
	crtmod_param_2	 %10110,   0,  138,  15,  34,  64,  25,  568,   6,  35, 512,  15,   27  ;   9  CRT 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  568,   6,  35, 512,  15,   27  ;  10  CRT 36/37/38/39
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  66, 512,  45,   27  ;  11  LCD 0/4/8/12
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  82, 480,  61,   27  ;  12  LCD 1/5/9/13
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  66, 512,  45,   27  ;  13  LCD 2/6/10/14
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  82, 480,  61,   27  ;  14  LCD 3/7/11/15
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  15  LCD 16/20/24
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  22, 600,   1,   27  ;  16  LCD 17/21/25
	crtmod_param_2	 %11010,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  17  LCD 18/22/26
	crtmod_param_2	 %10111,   0,  100,  12,   6,  80,   2,  525,   2,  33, 480,  10,   27  ;  18  LCD 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  625,   2,  66, 512,  45,   27  ;  19  LCD 28/29/30/31
	crtmod_param_2	 %10110,   0,  124,   9,  31,  64,  20,  625,   2,  66, 512,  45,   27  ;  20  LCD 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  625,   2,  66, 512,  45,   27  ;  21  LCD 36/37/38/39
n=n+1
    .endm
  .else
;			   R20L  HRL    HT   HS   HB   HD   HF    VT   VS   VB   VD   VF   R08    2ND  1ST
	crtmod_param_2	 %10101,   0,   92,  10,  12,  64,   6,  568,   6,  35, 512,  15,   27  ;   0  CRT 0/4/8/12
	crtmod_param_2	 %00101,   0,   76,   4,   6,  64,   2,  260,   3,  14, 240,   3,   44  ;   1  CRT 1/5/9/13
	crtmod_param_2	 %10000,   0,   46,   5,   6,  32,   3,  568,   6,  35, 512,  15,   27  ;   2  CRT 2/6/10/14
	crtmod_param_2	 %00000,   0,   38,   2,   3,  32,   1,  260,   3,  14, 240,   3,   36  ;   3  CRT 3/7/11/15
	crtmod_param_2	 %10110,   0,  138,  15,  18,  96,   9,  568,   6,  35, 512,  15,   27  ;   4  CRT 16/20/24
	crtmod_param_2	 %10110,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   5  CRT 17/21/25
	crtmod_param_2	 %11010,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   6  CRT 18/22/26
	crtmod_param_2	 %10110,   0,  138,  15,  26,  80,  17,  568,   6,  51, 480,  31,   27  ;   7  CRT 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
	crtmod_param_2	 %10110,   0,  138,  15,  34,  64,  25,  568,   6,  35, 512,  15,   27  ;   9  CRT 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  568,   6,  35, 512,  15,   27  ;  10  CRT 36/37/38/39
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  66, 512,  45,   27  ;  11  LCD 0/4/8/12
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  82, 480,  61,   27  ;  12  LCD 1/5/9/13
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  66, 512,  45,   27  ;  13  LCD 2/6/10/14
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  82, 480,  61,   27  ;  14  LCD 3/7/11/15
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  15  LCD 16/20/24
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  22, 600,   1,   27  ;  16  LCD 17/21/25
	crtmod_param_2	 %11010,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  17  LCD 18/22/26
	crtmod_param_2	 %10111,   0,  100,  12,   6,  80,   2,  525,   2,  33, 480,  10,   27  ;  18  LCD 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  625,   2,  66, 512,  45,   27  ;  19  LCD 28/29/30/31
	crtmod_param_2	 %10110,   0,  124,   9,  31,  64,  20,  625,   2,  66, 512,  45,   27  ;  20  LCD 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  625,   2,  66, 512,  45,   27  ;  21  LCD 36/37/38/39
  .endif

;R20L<<1|HRL→ドットクロックのランク
;	rank	R20L	HRL	osc	div	dotclk	mode
;	7	1**10	*	69.552	2	34.776	768x512(高)
;	6	1**11	*	50.350	2	25.175	640x480
;	5	1**01	0	69.552	3	23.184	512x512(高)
;	4	1**01	1	69.552	4	17.388	384x256
;	3	1**00	0	69.552	6	11.592	256x256(高)
;	2	0**01	*	38.864	4	9.716	512x512(低)
;	1	1**00	1	69.552	8	8.694
;	0	0**00	*	38.864	8	4.858	256x256(低)
;	0	0**1*	*	38.864	8	4.858
dot_clock_rank:
  .rept 4
	.dc.b	0	;0**00 0
	.dc.b	0	;0**00 1
	.dc.b	2	;0**01 0
	.dc.b	2	;0**01 1
	.dc.b	0	;0**10 0
	.dc.b	0	;0**10 1
	.dc.b	0	;0**11 0
	.dc.b	0	;0**11 1
  .endm
  .rept 4
	.dc.b	3	;1**00 0
	.dc.b	1	;1**00 1
	.dc.b	5	;1**01 0
	.dc.b	4	;1**01 1
	.dc.b	7	;1**10 0
	.dc.b	7	;1**10 1
	.dc.b	6	;1**11 0
	.dc.b	6	;1**11 1
  .endm



;----------------------------------------------------------------
;IOCSコール$90 _G_CLR_ON グラフィック画面の消去とパレット初期化と表示ON
;パラメータなし
	.text
	.even
iocs_90_G_CLR_ON:
	push	d0/d1/d3/a0/a4/a6

;(～)OOでアクセスする
;	$00E80000	CRTC
;	$00E82000	VICON
;	$00E84000	DMAC
;	$00E86000	SUPERAREA
;	$00E88000	MFP
;	$00E8A000	RTC
;	$00E8C000	PRNPORT
;	$00E8E000	SYSPORT
	lea.l	$00E88000,a6
OO	reg	-$00E88000(a6)
;<a6.l:(～)OOのベースアドレス

;現在の画面モードを確認する
	moveq.l	#0,d1
	move.b	BIOS_CRTMOD.w,d1	;現在の画面モード
	if	<cmp.w #crtmod_modes,d1>,hs	;現在の画面モードが範囲外のとき
		move.b	SRAM_CRTMOD,d1		;起動時の画面モードを使う
		if	<cmp.w #crtmod_modes,d1>,hs	;起動時の画面モードも範囲外のとき
			moveq.l	#16,d1			;16を使う
  .if 0
			unlocksram
			move.b	d1,SRAM_CRTMOD
			locksram
  .endif
		endif
	endif

;パラメータ1のアドレスを求める
	lea.l	crtmod_table_1_crt(pc),a4
	if	<btst.b #SRAM_XEIJ_LCD_BIT,SRAM_XEIJ>,ne	;LCD向け
		lea.l	crtmod_table_1_lcd(pc),a4
	endif
	move.w	d1,d0
  .if crtmod_param_1_size=8
	lsl.w	#3,d0
  .else
	mulu.w	#crtmod_param_1_size,d0
  .endif
	adda.w	d0,a4
;<a4.l:パラメータ1のアドレス

;メモリモードを確認する
	moveq.l	#7,d3
	and.b	crtmod_param_1_r20h(a4),d3	;メモリモード。0～7
;<d3.w:メモリモード。0～7

;テキスト画面のみON
	move.w	#VICON_TXON_MASK,(VICON_VISIBLE)OO

;グラフィックストレージON
	bset.b	#CRTC_GRAPHIC_STORAGE_BIT,(CRTC_MODE_BYTE)OO	;グラフィックストレージON

;グラフィックVRAMをクリアする
	lea.l	$00C00000,a0
	moveq.l	#0,d0
	moveq.l	#-1,d1			;1024*512/8=65536回
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;グラフィックストレージOFF
;メモリモードを設定する
	move.b	d3,(CRTC_MODE_BYTE)OO
	move.w	d3,(VICON_MEMORY_MODE)OO

;BIOSワークエリアを初期化する
	move.l	#$00C00000,BIOS_GRAPHIC_PAGE.w
	if	<cmp.w #4,d3>,lo	;メモリモード0～3。512x512ドット
		move.l	#2*512,BIOS_GRAPHIC_Y_OFFSET.w
		if	<cmp.w #1,d3>,lo	;メモリモード0。512x512ドット、16色、4ページ
			move.w	#16-1,BIOS_GRAPHIC_PALETS.w
		elif	eq			;メモリモード1。512x512ドット、256色、2ページ
			move.w	#256-1,BIOS_GRAPHIC_PALETS.w
		else				;メモリモード2～3。512x512ドット、65536色、1ページ
			move.w	#65536-1,BIOS_GRAPHIC_PALETS.w
		endif
	else					;メモリモード4～7。1024x1024ドット、16色、1ページ
		move.l	#2*1024,BIOS_GRAPHIC_Y_OFFSET.w
		move.w	#16-1,BIOS_GRAPHIC_PALETS.w
	endif

;グラフィックパレットを初期化する
	move.w	d3,d0
	bsr	initialize_gpalet

;テキスト画面ON、グラフィック画面ON
;	if	<cmp.w #4,d3>,lo	;メモリモード0～3。512x512ドット
;		move.w	#VICON_TXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,(VICON_VISIBLE)OO
;	else				;メモリモード4～7。1024x1024ドット
;		move.w	#VICON_TXON_MASK|VICON_GXON_MASK,(VICON_VISIBLE)OO
;	endif
;	IPLROM 1.0～1.3は1024x1024ドットと512x512ドットを両方ONにしている
	move.w	#VICON_TXON_MASK|VICON_GXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,(VICON_VISIBLE)OO

	pop
	rts

;----------------------------------------------------------------
;グラフィックパレットを初期化する
;<d0.w:メモリモード。0～7
	.text
	.even
initialize_gpalet:
	push	d0/d1/d2/d3/d4/a0/a1
	lea.l	VICON_GPALET,a0
	ifor	<tst.w d0>,eq,<cmp.w #4,d0>,hs	;メモリモード0。512x512ドット、16色、4ページ
						;メモリモード4～7。1024x1024ドット、16色、1ページ
		lea.l	gpalet_16_array(pc),a1
		moveq.l	#16/2-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
	elif	<cmp.w #1,d0>,eq	;メモリモード1。512x512ドット、256色、2ページ
		move.l	#%0000000000010010_0000000000010010,d1
		moveq.l	#%0000000000000000_0000000000000000,d4
		do
			moveq.l	#%0000000000000000_0000000000001000,d3
			moveq.l	#8-1,d2
			for	d2
				move.l	d4,d0
				and.l	#%1111101111111111_1111101111111111,d0
				or.l	d3,d0
				and.l	#%1111111111011111_1111111111011111,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	#%0000000100100000_0000000100100000,d3
			next
			add.l	#%0101010000000000_0101010000000000,d4
		while	cc
	else				;メモリモード2～3。512x512ドット、65536色、1ページ
		move.l	#$00_01_00_01,d0
		move.l	#$02_02_02_02,d1
		moveq.l	#256/2-1,d2
		for	d2
			move.l	d0,(a0)+
			add.l	d1,d0
		next
	endif
	pop
	rts

;グラフィック16色パレット
gpalet_16_array:
	dcrgb	0,0,0
	dcrgb	10,10,10
	dcrgb	0,0,16
	dcrgb	0,0,31
	dcrgb	16,0,0
	dcrgb	31,0,0
	dcrgb	16,0,16
	dcrgb	31,0,31
	dcrgb	0,16,0
	dcrgb	0,31,0
	dcrgb	0,16,16
	dcrgb	0,31,31
	dcrgb	16,16,0
	dcrgb	31,31,0
	dcrgb	21,21,21
	dcrgb	31,31,31

;----------------------------------------------------------------
;50us単位のウェイト
;<d0.l:時間(50us単位)
	.text
	.even
wait_50us:
  .if 0
;Timer-Cを使う
;	Timer-Cが1/200プリスケール(50us)で動作していなければならない
aTCDR	reg	a0
	push	d0-d2/aTCDR
	lea.l	MFP_TCDR,aTCDR
	moveq.l	#0,d1
	move.b	(aTCDR),d1
	move.b	(aTCDR),d1
	do
		moveq.l	#0,d2
		move.b	(aTCDR),d2
		redo	<cmp.b (aTCDR),d2>,cs
		sub.w	d2,d1
		if	cs
			add.w	#200,d1
		endif
		exg.l	d1,d2
		sub.l	d2,d0
	while	hi
	pop
	rts
  .else
;dbra空ループを使う
;	BIOS_MPU_SPEED_ROM.wとBIOS_MPU_TYPE.wが設定されていなければならない
	push	d0-d2
	subq.l	#1,d0
	if	cc
		move.w	BIOS_MPU_SPEED_ROM.w,d1	;000/010はMHz値*1000/12、020/030/040/060はMHz値*1000/6
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;000/010/020/030
			mulu.w	#3277,d1		;65536*50/1000
		elif	eq			;040
			mulu.w	#4915,d1		;65536*50/1000*6/4
		else				;060
			mulu.w	#19661,d1		;65536*50/1000*6/1
		endif
		swap.w	d1			;回/50us
		move.w	d1,d2
		swap.w	d0
		for	d0
			swap.w	d0
			for	d0
				move.w	d2,d1
				for	d1
				next
			next
			swap.w	d0
		next
	endif
	pop
	rts
  .endif




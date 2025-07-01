;========================================================================================
;  stupsnd.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;	stupsnd.x
;		X68030以上とIPLROM 1.6の起動音をon/offする
;	オプション
;		off
;			起動音を鳴らさない
;		on
;			起動音をキーコード76(o5c)で鳴らす
;		2..127
;		$02..$7F
;		o5cなど
;			起動音を指定されたキーコードで鳴らす
;		play
;			今すぐ起動音を再生する
;			FM音源ドライバを外しておくこと
;	音色パラメータ
;		kc,kf,tm,va[0],...,va[54]
;			音色パラメータを指定する
;			kc	キーコード
;			kf	キーフラクション
;			tm	キーオンからキーオフまでの時間(単位は1万分の1秒)
;			va	OPMDRV.Xと共通の音色パラメータ
;		save
;			レジスタデータをstupsnd.datに保存する
;			起動音に反映させるには、データをIPLROM 1.6へ埋め込む必要がある
;----------------------------------------------------------------------------------------

TITLE	reg	'stupsnd.x (2025-04-13)'

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sram.equ
	.include	sysport.equ

;グローバルレジスタを決める
dPREV	reg	d6			;変更前の設定。0=off,1..255=on,2..127=kc
dMODE	reg	d7			;変更後の設定。-1=なし,0=off,1..255=on,2..127=kc
aBASE	reg	a6			;相対アクセスベースアドレス
base:
	lea.l	base(pc),aBASE
r	reg	-base(aBASE)

;引数を読み取る
	addq.l	#1,a2			;コマンドライン
	moveq.l	#-1,dMODE		;変更後の設定なし
	clr.b	(param_array)r		;音色パラメータなし
	sf.b	(play_flag)r		;今すぐ起動音を再生しない
	sf.b	(save_flag)r		;レジスタデータを保存しない
	dostart
		lea.l	buffer(pc),a0
		movestr	<'play'>,a1
		bsr	stricmp
		if	eq
			st.b	(play_flag)r		;今すぐ起動音を再生する
			restart
		endif
		movestr	<'save'>,a1
		bsr	stricmp
		if	eq
			st.b	(save_flag)r		;レジスタデータを保存する
			restart
		endif
		moveq.l	#$20,d0
		or.b	(a0),d0
		if	<cmp.b #'o',d0>,eq	;off,on,o5cなど
			addq.l	#1,a0
			moveq.l	#$20,d0
			or.b	(a0),d0
			if	<cmp.b #'f',d0>,eq
				addq.l	#1,a0
				moveq.l	#$20,d0
				or.b	(a0),d0
				if	<cmp.b #'f',d0>,eq
					addq.l	#1,a0
					moveq.l	#0,d0			;off
				else
					goto	help
				endif
			elif	<cmp.b #'n',d0>,eq
				addq.l	#1,a0
				moveq.l	#1,d0			;on
			else
				moveq.l	#-'0',d0
				add.b	(a0)+,d0
				goto	<cmp.b #'8'-'0',d0>,hi,help
				moveq.l	#0,d1
				move.b	d0,d1
				mulu.w	#12,d1			;番号
				moveq.l	#$20,d0
				or.b	(a0)+,d0
				sub.b	#'a',d0
				goto	<cmp.b #'g'-'a',d0>,hi,help
				lea.l	note_to_number(pc),a1
				add.b	(a1,d0.w),d1
				ifor	<cmpi.b #'#',(a0)>,eq,<cmpi.b #'+',(a0)>,eq	;シャープ
					addq.l	#1,a0
					addq.b	#1,d1
				elif	<cmpi.b #'-',(a0)>,eq	;フラット
					addq.l	#1,a0
					subq.b	#1,d1
				endif
				goto	<tst.b d1>,mi,help
				move.l	d1,d0			;x1
				divu.w	#3,d1			;x1/3
				add.b	d1,d0			;x4/3。キーコード
				gotoor	<cmp.b #2,d0>,lo,<tst.b d0>,mi,help
			endif
		elif	<cmp.b #'$',(a0)>,eq	;$02..$7F
			addq.l	#1,a0
			bsr	stoh
			goto	cs,help
			moveq.l	#2,d1
			goto	<cmp.l d1,d0>,lo,help
			moveq.l	#127,d1
			goto	<cmp.l d1,d0>,hi,help
		elifand	<cmp.b #'0',(a0)>,hs,<cmp.b #'9',(a0)>,ls	;2..127
			bsr	stou
			goto	cs,help
			moveq.l	#2,d1
			goto	<cmp.l d1,d0>,lo,help
			moveq.l	#127,d1
			goto	<cmp.l d1,d0>,hi,help
		else
			goto	help
		endif
		if	<cmpi.b #',',(a0)>,ne	;','がない。変更後の設定
			move.l	d0,dMODE
		else				;','がある。音色パラメータ
			gotoor	<cmp.b #2,d0>,lo,<tst.b d0>,mi,help	;kc以外は不可
			lea.l	param_array(pc),a1
			move.b	d0,(a1)+		;0:kc
			moveq.l	#57-1,d2
			for	d2
				goto	<cmpi.b #',',(a0)>,ne,help
				addq.l	#1,a0
				if	<cmp.b #'$',(a0)>,eq
					addq.l	#1,a0
					bsr	stoh
				elifand	<cmp.b #'0',(a0)>,hs,<cmp.b #'9',(a0)>,ls
					bsr	stou
				else
					goto	help
				endif
				goto	cs,help
				if	<cmp.w #56-1,d2>,hi	;1:kf
					moveq.l	#63,d1
					goto	<cmp.l d1,d0>,hi,help
					move.b	d0,(a1)+
				elif	eq			;2..3:tm
					goto	<cmp.l #65535,d0>,hi,help
					move.w	d0,(a1)+		;tmは2バイト。偶数アドレスに配置すること
				else				;4..58:va[0],...,va[54]
					goto	<cmp.l #255,d0>,hi,help
					move.b	d0,(a1)+
				endif
			next
		endif
		goto	<tst.b (a0)>,ne,help
	start
		lea.l	buffer(pc),a0
		movea.l	a2,a1
		bsr	argcpy
		movea.l	a1,a2
	while	ne			;引数がある

;音色パラメータをレジスタデータに変換する
	lea.l	param_array(pc),a0
	move.b	(a0)+,d0		;kc
	if	ne
		if	<tst.l dMODE>,mi	;音色パラメータがあり変更後の設定がないとき
			moveq.l	#0,dMODE
			move.b	d0,dMODE		;音色パラメータのkcを変更後の設定にする
		endif
		move.b	(a0)+,d1		;kf
		move.w	(a0)+,d2		;tmは2バイト。偶数アドレスに配置すること
		bsr	stupsnd_conv
	endif

;スーパーバイザモードへ移行する
	supervisormode

;変更前の設定を保存する
	moveq.l	#0,dPREV
	move.b	SRAM_STARTUP_SOUND,dPREV	;変更前の設定
;<dPREV.l:変更前の設定。0=off,1..255=on,2..127=kc

;設定を変更する
	ifand	<tst.l dMODE>,pl,<cmp.b dPREV,dMODE>,ne	;変更後の設定があり、変更前と変更後の設定が異なる
		unlocksram			;SRAM書き込み許可
		move.b	dMODE,SRAM_STARTUP_SOUND	;変更後の設定
		locksram			;SRAM書き込み禁止
	endif

;今すぐ起動音を再生する
	if	<tst.b (play_flag)r>,ne
		bsr	play_stupsnd
	endif

;設定を表示する
	lea.l	buffer(pc),a0
	movestr	<'startup sound switch is '>,a1
	bsr	strcpy
	move.l	dMODE,d0
	if	mi
		move.l	dPREV,d0
	endif
	if	eq			;0=off
		move.b	#'o',(a0)+
		move.b	#'f',(a0)+
		move.b	#'f',(a0)+
	else				;1..255=on
		move.b	#'o',(a0)+
		move.b	#'n',(a0)+
		if	<cmp.b #2,d0>,ge	;2..127=kc。キーコードが指定されている
			movestr	<' with key code '>,a1
			bsr	strcpy
			bsr	utos
			move.b	#' ',(a0)+
			move.b	#'(',(a0)+
			move.b	d0,d1			;x1
			lsr.b	#2,d1			;x1/4
			sub.b	d1,d0			;x3/4。番号
			divu.w	#12,d0			;ノート|オクターブ
			move.l	d0,d1
			swap.w	d1			;ノート
			if	<cmp.w #9,d1>,hs	;c c# dは
				addq.w	#1,d0			;1つ上のオクターブ
			endif
			move.b	#'o',(a0)+
			add.b	#'0',d0
			move.b	d0,(a0)+
			add.w	d1,d1
			lea.l	number_to_note(pc),a1
			adda.w	d1,a1
			move.b	(a1)+,(a0)+
			move.b	(a1),d0
			if	ne
				move.b	d0,(a0)+
			endif
			move.b	#')',(a0)+
		endif
	endif
	bsr	crlf
	lea.l	buffer(pc),a0
	bsr	print

;IPLROMのバージョンを確認する
	IOCS	_ROMVER
	move.l	#$13000000,d1		;IPLROM 1.3以上
	if	<cmp.b #2,dMODE>,ge	;2..127=kc。キーコードが指定されている
		move.l	#$16240226,d1		;IPLROM 1.6 (24-02-26)以上
	endif
	if	<cmp.l d1,d0>,lo		;IPLROMのバージョンが合っていない
		ifand	<tst.b dMODE>,pl,<cmp.b dPREV,dMODE>,ne	;変更後の設定があり、変更前と変更後の設定が異なる
			unlocksram			;SRAM書き込み許可
			move.b	dPREV,SRAM_STARTUP_SOUND	;変更前の設定を復元する
			locksram			;SRAM書き込み禁止
		endif
		movestr	<'unsupported IPLROM version',13,10>,a0
		bsr	print
	endif

;ユーザモードへ復帰する
	usermode

;レジスタデータを保存する
	if	<tst.b (save_flag)r>,ne
		move.w	#$0020,-(sp)
		pea.l	data_name(pc)
		DOS	_CREATE
		addq.l	#6,sp
		move.l	d0,d1
		if	mi
			movestr	<'create error',13,10>,a0
			bsr	print
		else
			moveq.l	#42,d2			;42バイト
			move.l	d2,-(sp)
			pea.l	stupsnd_data(pc)	;レジスタデータ
			move.w	d1,-(sp)
			DOS	_WRITE
			move.l	d0,d3
			DOS	_CLOSE
			lea.l	10(sp),sp
			if	<cmp.l d2,d3>,ne	;ディスクフル？
				pea.l	data_name(pc)
				DOS	_DELETE
				addq.l	#4,sp
				movestr	<'write error',13,10>,a0
				bsr	print
			endif
		endif
	endif

;終了する
	DOS	_EXIT

;オプションを表示してエラー終了する
help:
	lea.l	options(pc),a0
	bsr	print
	move.w	#1,-(sp)
	DOS	_EXIT2

;オプション
options:
	.dc.b	TITLE,13,10
	.dc.b	'  turn on/off startup sound switch of X68030 or higher and IPLROM 1.6',13,10
	.dc.b	'options',13,10
	.dc.b	'  off',13,10
	.dc.b	'    turn off startup sound switch',13,10
	.dc.b	'  on',13,10
	.dc.b	'    turn on startup sound switch with key code 76 (o5c)',13,10
	.dc.b	'  2..127',13,10
	.dc.b	'  $02..$7F',13,10
	.dc.b	'  o5c etc.',13,10
	.dc.b	'    turn on startup sound switch with specified key code',13,10
	.dc.b	'  play',13,10
	.dc.b	'    play startup sound right now',13,10
	.dc.b	'    FM sound driver must be removed',13,10
	.dc.b	'tone parameters',13,10
	.dc.b	'  kc,kf,tm,va[0],...,va[54]',13,10
	.dc.b	'    specify tone parameters',13,10
	.dc.b	'    kc -- key code',13,10
	.dc.b	'    kf -- key fraction',13,10
	.dc.b	'    tm -- time from key-on to key-off (unit is 1/10,000 of a second)',13,10
	.dc.b	'    va -- tone parameters common to OPMDRV.X',13,10
	.dc.b	'  save',13,10
	.dc.b	'    save register data to stupsnd.dat',13,10
	.dc.b	'    to reflect in the startup sound, inserting data into IPLROM 1.6 is required',13,10
	.dc.b	0

;ノートの変換表
note_to_number:
	.dc.b	6			;a
	.dc.b	8			;b
	.dc.b	-3			;c
	.dc.b	-1			;d
	.dc.b	1			;e
	.dc.b	2			;f
	.dc.b	4			;g
number_to_note:
	.dc.b	'd#'			;0
	.dc.b	'e',0			;1
	.dc.b	'f',0			;2
	.dc.b	'f#'			;3
	.dc.b	'g',0			;4
	.dc.b	'g#'			;5
	.dc.b	'a',0			;6
	.dc.b	'a#'			;7
	.dc.b	'b',0			;8
	.dc.b	'c',0			;9
	.dc.b	'c#'			;10
	.dc.b	'd',0			;11

data_name:
	.dc.b	'stupsnd.dat',0

	.bss
	.even
param_array:
	.ds.b	59			;音色パラメータ。kc,kf,tmH,tmL,va[0],...,va[54]。偶数アドレスに配置すること
play_flag:
	.ds.b	1			;-1=今すぐ起動音を再生する
save_flag:
	.ds.b	1			;-1=音色パラメータを保存する
buffer:
	.ds.b	1024			;文字列バッファ

	.text
	.even



;----------------------------------------------------------------
;起動音

CH	equ	0

KC	equ	76
KF	equ	5
TM	equ	2500/100

FLCON	equ	(1<<3)|3		;|FL###|CON###|
SLOT	equ	%1101			;|C2|M2|C1|M1|
WAVE	equ	0
SYNC	equ	1
SPEED	equ	0
PMD	equ	0
AMD	equ	0
PMS	equ	0
AMS	equ	0
PAN	equ	%11			;|R|L|

M1AR	equ	6
M1D1R	equ	11
M1D2R	equ	4
M1RR	equ	4
M1D1L	equ	0
M1TL	equ	29
M1KS	equ	0
M1MUL	equ	0
M1DT1	equ	0
M1DT2	equ	3
M1AMSEN	equ	1

C1AR	equ	31
C1D1R	equ	6
C1D2R	equ	0
C1RR	equ	2
C1D1L	equ	2
C1TL	equ	40
C1KS	equ	2
C1MUL	equ	1
C1DT1	equ	0
C1DT2	equ	3
C1AMSEN	equ	1

M2AR	equ	3
M2D1R	equ	2
M2D2R	equ	7
M2RR	equ	2
M2D1L	equ	3
M2TL	equ	28
M2KS	equ	1
M2MUL	equ	3
M2DT1	equ	0
M2DT2	equ	1
M2AMSEN	equ	1

C2AR	equ	31
C2D1R	equ	21
C2D2R	equ	6
C2RR	equ	4
C2D1L	equ	2
C2TL	equ	2
C2KS	equ	1
C2MUL	equ	1
C2DT1	equ	0
C2DT2	equ	0
C2AMSEN	equ	1

play_stupsnd:
	push	d0-d4/a0
	move.b	SRAM_STARTUP_SOUND,d3	;0=off,1..255=on,2..127=kc
	if	ne			;on
		moveq.l	#$08,d1			;KeyOff
		moveq.l	#(0<<3)|CH,d2		;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
		lea.l	stupsnd_data(pc),a0	;レジスタデータの配列
		moveq.l	#$20+CH,d1		;レジスタアドレス
		moveq.l	#28-1,d4		;0..27
		for	d4
			move.b	(a0)+,d2		;レジスタデータ
			ifand	<cmp.b #$28+CH,d1>,eq,<cmp.b #2,d3>,ge	;2..127=kc。キーコードが指定されている
				move.b	d3,d2
			endif
			bsr	stupsnd_opmset
			addq.b	#8,d1			;次のレジスタアドレス
		next
		moveq.l	#6-1,d4			;28..39
		for	d4
			move.b	(a0)+,d1		;レジスタアドレス
			move.b	(a0)+,d2		;レジスタデータ
			bsr	stupsnd_opmset
		next
		moveq.l	#$08,d1			;KeyOn
		moveq.l	#(SLOT<<3)|CH,d2	;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
		moveq.l	#0,d0
		move.w	(a0)+,d0		;40..41。tm@100us
		add.l	d0,d0			;tm@50us
		jsr	wait_50us		;50us単位のウェイト
	;	moveq.l	#$08,d1			;KeyOff
		moveq.l	#(0<<3)|CH,d2		;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
	endif
	pop
	rts

stupsnd_opmset:
	IOCS	_OPMSET
	rts

;レジスタデータ(42バイト)。偶数アドレスに配置すること
	.even
stupsnd_data:
  .ifdef STUPSNDDAT
	.insert	stupsnd.dat
  .else
	.dc.b	(PAN<<6)|FLCON		;0 $20+CH |PAN##|FL###|CON###|
	.dc.b	KC			;1 $28+CH |-|KC#######|
	.dc.b	KF<<2			;2 $30+CH |KF######|--|
	.dc.b	(PMS<<4)|AMS		;3 $38+CH |-|PMS###|--|AMS##|
	.dc.b	(M1DT1<<4)|M1MUL	;4 $40+CH M1 |-|DT1###|MUL####|
	.dc.b	(M2DT1<<4)|M2MUL	;5 $48+CH M2
	.dc.b	(C1DT1<<4)|C1MUL	;6 $50+CH C1
	.dc.b	(C2DT1<<4)|C2MUL	;7 $58+CH C2
	.dc.b	M1TL			;8 $60+CH M1 |-|TL#######|
	.dc.b	M2TL			;9 $68+CH M2
	.dc.b	C1TL			;10 $70+CH C1
	.dc.b	C2TL			;11 $78+CH C2
	.dc.b	(M1KS<<6)|M1AR		;12 $80+CH M1 |KS##|-|AR#####|
	.dc.b	(M2KS<<6)|M2AR		;13 $88+CH M2
	.dc.b	(C1KS<<6)|C1AR		;14 $90+CH C1
	.dc.b	(C2KS<<6)|C2AR		;15 $98+CH C2
	.dc.b	(M1AMSEN<<7)|M1D1R	;16 $A0+CH M1 |AMSEN|--|D1R#####|
	.dc.b	(M2AMSEN<<7)|M2D1R	;17 $A8+CH M2
	.dc.b	(C1AMSEN<<7)|C1D1R	;18 $B0+CH C1
	.dc.b	(C2AMSEN<<7)|C2D1R	;19 $B8+CH C2
	.dc.b	(M1DT2<<6)|M1D2R	;20 $C0+CH M1 |DT2##|-|D2R#####|
	.dc.b	(M2DT2<<6)|M2D2R	;21 $C8+CH M2
	.dc.b	(C1DT2<<6)|C1D2R	;22 $D0+CH C1
	.dc.b	(C2DT2<<6)|C2D2R	;23 $D8+CH C2
	.dc.b	(M1D1L<<4)|M1RR		;24 $E0+CH M1 |D1L####|RR####|
	.dc.b	(M2D1L<<4)|M2RR		;25 $E8+CH M2
	.dc.b	(C1D1L<<4)|C1RR		;26 $F0+CH C1
	.dc.b	(C2D1L<<4)|C2RR		;27 $F8+CH C2
	.dc.b	$18,SPEED		;28,29 $18 |LFRQ########|
	.dc.b	$19,(0<<7)|AMD		;30,31 $19 |0|AMD#######|
	.dc.b	$19,(1<<7)|PMD		;32,33 $19 |1|PMD#######|
	.dc.b	$1B,WAVE		;34,35 $1B |CT1|CT2|----|WAVE##|
	.dc.b	$01,SYNC<<1		;36,37 $01 |------|LFORESET|-|
	.dc.b	$01,0<<1		;38,39 $01 |------|LFORESET|-|
	.dc.w	TM			;40,41 tm@100us
					;42
	.even
  .endif



;----------------------------------------------------------------
;音色パラメータをレジスタデータに変換する
;<d0.b:kc
;<d1.b:kf
;<d2.w:tm
;<a0.l:音色パラメータ(55バイト)。va[0],...,va[54]
;		+0	+1	+2	+3	+4	+5	+6	+7	+8	+9	+10
;	0	FLCON	SLOT	WAVE	SYNC	SPEED	PMD	AMD	PMS	AMS	PAN	0
;	11	M1AR	M1D1R	M1D2R	M1RR	M1D1L	M1TL	M1KS	M1MUL	M1DT1	M1DT2	M1AMSEN
;	22	C1AR	C1D1R	C1D2R	C1RR	C1D1L	C1TL	C1KS	C1MUL	C1DT1	C1DT2	C1AMSEN
;	33	M2AR	M2D1R	M2D2R	M2RR	M2D1L	M2TL	M2KS	M2MUL	M2DT1	M2DT2	M2AMSEN
;	44	C2AR	C2D1R	C2D2R	C2RR	C2D1L	C2TL	C2KS	C2MUL	C2DT1	C2DT2	C2AMSEN
;	55	kc	kf
stupsnd_conv:
	push	d0-d4/a0-a2,58
	movea.l	sp,a1
	moveq.l	#55-1,d3
	for	d3
		move.b	(a0)+,(a1)+
	next
	move.b	d0,(a1)+		;kc
	move.b	d1,(a1)+		;kf
	movea.l	sp,a0			;音色パラメータ+kc+kf(57バイト)。va[0],...,va[54],kc,kf
	tas.b	5(a0)			;|1|PMD#######|
	lea.l	stupsnd_data(pc),a1	;レジスタデータ(42バイト)
	lea.l	100f(pc),a2		;音色パラメータ→レジスタデータ変換表
	moveq.l	#0,d1
	moveq.l	#28+6-1,d3
	for	d3
		if	<cmp.b #6-1,d3>,ls	;最後の6個
			move.b	(a2)+,(a1)+		;レジスタアドレス
		endif
		moveq.l	#0,d0			;レジスタデータ
		dostart
			move.b	(a0,d1.w),d1		;音色パラメータ+kc+kfに含まれるレジスタデータの部品
			and.b	(a2)+,d1		;マスク
			move.b	(a2)+,d4		;シフトカウント
			lsl.b	d4,d1
			or.b	d1,d0			;部品を並べる
		start
			move.b	(a2)+,d1		;音色パラメータ+kc+kfのインデックス
		while	pl
		move.b	d0,(a1)+		;レジスタデータ
	next
	move.w	d2,(a1)+		;40,41 tm
	pop
	rts

;音色パラメータ→レジスタデータ変換表
100:
;音色パラメータ+kc+kfのインデックス,マスク,シフトカウント,…,-1
	.dc.b	9,3,6,0,63,0,-1		;0 $20+CH |PAN##|FL###|CON###|
	.dc.b	55+0,127,0,-1		;1 $28+CH |-|KC#######|
	.dc.b	55+1,63,2,-1		;2 $30+CH |KF######|--|
	.dc.b	7,7,4,6,3,0,-1		;3 $38+CH |-|PMS###|--|AMS##|
	.dc.b	11+8,7,4,11+7,15,0,-1	;4 $40+CH M1 |-|DT1###|MUL####|
	.dc.b	33+8,7,4,33+7,15,0,-1	;5 $48+CH M2
	.dc.b	22+8,7,4,22+7,15,0,-1	;6 $50+CH C1
	.dc.b	44+8,7,4,44+7,15,0,-1	;7 $58+CH C2
	.dc.b	11+5,127,0,-1		;8 $60+CH M1 |-|TL#######|
	.dc.b	33+5,127,0,-1		;9 $68+CH M2
	.dc.b	22+5,127,0,-1		;10 $70+CH C1
	.dc.b	44+5,127,0,-1		;11 $78+CH C2
	.dc.b	11+6,3,6,11+0,31,0,-1	;12 $80+CH M1 |KS##|-|AR#####|
	.dc.b	33+6,3,6,33+0,31,0,-1	;13 $88+CH M2
	.dc.b	22+6,3,6,22+0,31,0,-1	;14 $90+CH C1
	.dc.b	44+6,3,6,44+0,31,0,-1	;15 $98+CH C2
	.dc.b	11+10,1,7,11+1,31,0,-1	;16 $A0+CH M1 |AMSEN|--|D1R#####|
	.dc.b	33+10,1,7,33+1,31,0,-1	;17 $A8+CH M2
	.dc.b	22+10,1,7,22+1,31,0,-1	;18 $B0+CH C1
	.dc.b	44+10,1,7,44+1,31,0,-1	;19 $B8+CH C2
	.dc.b	11+9,3,6,11+2,31,0,-1	;20 $C0+CH M1 |DT2##|-|D2R#####|
	.dc.b	33+9,3,6,33+2,31,0,-1	;21 $C8+CH M2
	.dc.b	22+9,3,6,22+2,31,0,-1	;22 $D0+CH C1
	.dc.b	44+9,3,6,44+2,31,0,-1	;23 $D8+CH C2
	.dc.b	11+4,15,4,11+3,15,0,-1	;24 $E0+CH M1 |D1L####|RR####|
	.dc.b	33+4,15,4,33+3,15,0,-1	;25 $E8+CH M2
	.dc.b	22+4,15,4,22+3,15,0,-1	;26 $F0+CH C1
	.dc.b	44+4,15,4,44+3,15,0,-1	;27 $F8+CH C2
;レジスタアドレス,音色パラメータ+kc+kfのインデックス,マスク,シフトカウント,…,-1
	.dc.b	$18,4,255,0,-1		;28,29 $18 |LFRQ########|
	.dc.b	$19,6,127,0,-1		;30,31 $19 |0|AMD#######|
	.dc.b	$19,5,127,0,-1		;32,33 $19 |1|PMD#######|
	.dc.b	$1B,2,3,0,-1		;34,35 $1B |CT1|CT2|----|WAVE##|
	.dc.b	$01,3,1,1,-1		;36,37 $01 |------|LFORESET|-|
	.dc.b	$01,3,0,1,-1		;38,39 $01 |------|LFORESET|-|
	.even



;----------------------------------------------------------------
;引数をコピーする
;	空白を読み飛ばしてから次の空白の手前までコピーする
;	"～"または'～'で囲むと引数に空白を含めることができる
;	""または''と書くと長さが0の引数を与えることができる
;<a0.l:コピー先のバッファの先頭
;<a1.l:コピー元の文字列の先頭
;>d0.l:0=引数がない,1=引数がある
;>a0.l:コピー先の文字列の末尾の0の位置
;>a1.l:コピー元の引数の直後。なければコピー元の文字列の末尾の0の位置
;>eq=引数がない,ne=引数がある
argcpy::
	exg.l	a0,a1
	bsr	nextword		;空白を読み飛ばす
	exg.l	a0,a1
	if	eq			;引数がない
		clr.b	(a0)
		moveq.l	#0,d0
		rts
	endif
	dostart
		if	<cmp.b #'"',d0>,eq	;"～"
			dostart
				move.b	d0,(a0)+		;書き込む
			start
				move.b	(a1)+,d0		;次の文字
				break2	eq			;引数が終わった
			while	<cmp.b #'"',d0>,ne
		elif	<cmp.b #39,d0>,eq	;'～'
			dostart
				move.b	d0,(a0)+		;書き込む
			start
				move.b	(a1)+,d0		;次の文字
				break2	eq			;引数が終わった
			while	<cmp.b #$39,d0>,ne
		else
			move.b	d0,(a0)+		;書き込む
		endif
	start
		move.b	(a1)+,d0		;次の文字
		break	eq			;引数が終わった
		breakand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\rならば終了
	while	<cmp.b #' ',d0>,ne	;空白でなければ繰り返す
	subq.l	#1,a1			;進み過ぎた分戻る
	clr.b	(a0)
	moveq.l	#1,d0
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
;16進数の文字を整数に変換する
;<d0.b:文字
;>d0.l:0～16。-1=16進数の文字ではない
;>n:mi=16進数の文字ではない
fromxdigit::
	sub.b	#'0',d0
	blo	1f			;x<0
	sub.b	#('9'+1)-'0',d0
	blo	3f			;0<=x<=9
	subq.b	#'A'-('9'+1),d0
	blo	1f			;9<x<A
	subq.b	#('F'+1)-'A',d0
	blo	2f			;A<=x<=F
	sub.b	#'a'-('F'+1),d0
	blo	1f			;F<x<A
	subq.b	#('f'+1)-'a',d0
	blo	2f			;a<=x<=f
1:	moveq.l	#-1,d0			;x<0||9<x<A||F<x<a||f<x
	rts
2:	addq.b	#6,d0			;A<=x<=F||a<=x<=f
3:	add.b	#10,d0			;0<=x<=9
	ext.w	d0
	ext.l	d0
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
;16進数の文字列を符号なし整数に変換する
;<a0.l:16進数の文字列。先頭の空白は認めない
;>d0.l:符号なし整数。(csのとき)下位32ビット
;>a0.l:16進数ではない文字または0の位置
;>c:cc=成功,cs=16進数の文字がないまたはオーバーフロー
;>v:(csのとき)vc=16進数の文字がない,vs=オーバーフロー
stoh::
	push	d1-d2/a1
	moveq.l	#0,d1			;符号なし整数
	moveq.l	#0,d2			;オーバーフロー判定用
	movea.l	a0,a1			;開始位置
	dostart
		or.l	d1,d2			;16倍する直前の値のOR
		lsl.l	#4,d1			;16倍して
		or.b	d0,d1			;1桁加える
	start
		move.b	(a0)+,d0		;次の文字
		bsr	fromxdigit
	while	pl			;16進数の文字ならば繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	add.l	#$F0000000,d2
	subx.w	d2,d2			;16倍する直前の値のORの上位4ビットが0でないすなわちオーバーフローのとき-1、さもなくば0
	and.w	#%00011,d2		;オーバーフローのときvs,cs、さもなくばvc,cc
	if	<cmpa.l a1,a0>,eq	;進んでいない
		or.w	#%00001,d2		;16進数の文字がないときcs
	endif
	move.l	d1,d0			;符号なし整数
	move.w	d2,ccr
	popm
	rts

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
;小文字化しながら文字列比較
;	'['<'A'となることに注意。SJISは正しく比較できないことに注意
;<a0.l:文字列0。引かれる
;<a1.l:文字列1。引く
;>ccr:eq=文字列0==文字列1,lo=文字列0<文字列1,hi=文字列1<文字列0
stricmp::
	push	d0-d1/a0-a1
	do
		move.b	(a0)+,d0
		if	eq
			cmp.b	(a1)+,d0
			break
		endif
		move.b	(a1)+,d1
		ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls
			or.b	#$20,d0
		endif
		ifand	<cmp.b #'A',d1>,hs,<cmp.b #'Z',d1>,ls
			or.b	#$20,d1
		endif
		cmp.b	d1,d0
	while	eq
	pop
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

;----------------------------------------------------------------
;50us単位のウェイト
;<d0.l:待ち時間(50us単位)
wait_50us::
aTCDR	reg	a0
	push	d0-d2/aTCDR
	lea.l	MFP_TCDR,aTCDR		;Timer-Cデータレジスタ。200,199,…,2,1,0→200,199,…(50us単位)
	moveq.l	#0,d1
	move.b	(aTCDR),d1
	move.b	(aTCDR),d1		;d1=前回の値
	do
		moveq.l	#0,d2
		move.b	(aTCDR),d2		;d2=今回の値
		redo	<cmp.b (aTCDR),d2>,lo	;0→200のとき読み直す
		sub.w	d2,d1			;d1=前回の値-今回の値=経過時間
		if	lo			;0→200を跨いだとき
			add.w	#200,d1			;今回の値が200増えた分経過時間が200減るので加え戻す
		endif
		exg.l	d1,d2			;d1=今回の値=次回の前回の値,d2=経過時間
		sub.l	d2,d0			;d0=待ち時間-経過時間=次回の待ち時間
	while	hi			;待ち時間がなくなるまで繰り返す
	pop
	rts



	.end

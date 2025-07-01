;========================================================================================
;  set232c.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	set232c.x
;		RS-232Cの設定を変更します。
;
;	最終更新
;		2024-05-04
;
;	作り方
;		has060 -i include -o set232c.o -w set232c.s
;		lk -o set232c.x set232c.o
;
;	使い方
;		set232c オプション …
;
;	オプション
;		-5
;			5MHzの場合のボーレートを表示します。(デフォルト)
;		-7
;			7.3728MHzの場合のボーレートを表示します。
;		-c
;			SPEED.Xと同様に、現在の設定を変更します。(デフォルト)
;		-i
;			初期値$4E07 9600 b8 pn s1 xonを使います。
;		-q
;			設定を表示しません。
;		-s
;			SWITCH.Xと同様に、起動時の設定を変更します。
;		$xxxx
;			設定値を4桁の16進数で指定します。
;		75
;		150
;		300
;		600
;		1200
;		2400
;		4800
;		9600
;		19200
;		38400
;		76800
;			5MHzの場合のボーレートを指定します。
;		112.5
;		225
;		450
;		900
;		1800
;		3600
;		7200
;		14400
;		28800
;		57600
;		115200
;			7.3728MHzの場合のボーレートを指定します。
;		b5
;		b6
;		b7
;		b7s
;		b8
;			データ長を指定します。b7sはSI/SOを有効にします。
;		pn
;		po
;		pe
;			パリティを指定します。
;		s1
;		s1.5
;		s2
;			ストップビットを指定します。
;		none
;		xon
;		rts
;			フロー制御を指定します。
;
;	更新履歴
;		2024-02-07
;			作成。
;		2024-02-08
;			7.5MHzの場合のボーレートの指定と表示を追加。
;		2024-05-04
;			7.5MHzの表記を7.3728MHzに変更。
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	iocscall.mac
	.include	push2.mac
	.include	sram.equ
	.include	sysport.equ

TITLE_STRING	reg	'set232c.x (2024-05-04)'

	.text

;大域レジスタを初期化する
aBUF	reg	a6
	lea.l	buffer(pc),aBUF		;文字列バッファ
r	reg	-buffer(aBUF)		;文字列バッファ以外も(～)rで相対アクセスできる
;<a6.l:文字列バッファ。相対アクセスのベースアドレス

;引数を読み取る
	sf.b	(seven_flag)r
	sf.b	(initial_flag)r
	sf.b	(quiet_flag)r
	sf.b	(startup_flag)r
	moveq.l	#0,d6			;変更する項目のマスク
	moveq.l	#0,d7			;変更後の設定値
	addq.l	#1,a2			;コマンドライン
	dostart
		move.b	(aBUF),d0		;引数の1文字目
		if	<cmp.b #'-',d0>,eq	;1文字目が'-'
			move.b	1(aBUF),d0		;2文字目
			bsr	tolower
			if	<cmp.b #'5',d0>,eq		;-5
				sf.b	(seven_flag)r
			elif	<cmp.b #'7',d0>,eq		;-7
				st.b	(seven_flag)r
			elif	<cmp.b #'c',d0>,eq		;-c
				sf.b	(startup_flag)r
			elif	<cmp.b #'i',d0>,eq		;-i
				st.b	(initial_flag)r
			elif	<cmp.b #'q',d0>,eq		;-q
				st.b	(quiet_flag)r
			elif	<cmp.b #'s',d0>,eq		;-s
				st.b	(startup_flag)r
			else
				goto	error_exit
			endif
		elif	<cmp.b #'$',d0>,eq	;1文字目が'$'
			lea.l	1(aBUF),a0		;2文字目
			bsr	stoh			;16進数を読み取る
			goto	cs,error_exit		;16進数の文字がない
			goto	<cmp.l #$0000FFFF,d0>,hi,error_exit	;範囲外
			goto	<tst.w d0>,eq,error_exit	;未初期化
			goto	<cmp.w #$FFFF,d0>,eq,error_exit	;問い合わせ
			moveq.l	#-1,d6			;すべてのビットを変更する
			move.w	d0,d7			;16進数の値
		else				;キーワードを探す
			do
				lea.l	(keywords)r,a3
				dostart
					move.l	(a3)+,d2		;周波数|マスク
					move.w	(a3)+,d3		;設定値
					movea.l	aBUF,a0
					movea.l	a3,a1			;キーワードと
					bsr	stricmp			;比較する
					if	eq			;一致したら
						or.w	d2,d6			;項目のマスクを追加する
						not.w	d2
						and.w	d2,d7			;変更する項目を消して
						or.w	d3,d7			;書き換える
						break2	t			;この引数は終わり
					endif
					adda.w	d1,a3			;次のキーワードへ
				start
					move.w	(a3)+,d1		;キーワードの長さ
				while	ne
				goto	error_exit		;キーワードが見つからなかった
			while	f			;一致したときの出口
		endif
	start
		movea.l	aBUF,a0		;文字列バッファへ
		movea.l	a2,a1		;コマンドラインの
		bsr	argcpy		;引数をコピーする
		movea.l	a1,a2
	while	ne
;<d6.w:変更する項目のマスク
;<d7.w:変更後の設定値

;設定を読み出す
	if	<tst.b (initial_flag)r>,ne	;初期値を使う
;			  FE DC BA 9 8 7 6543210
		move.w	#%01_00_11_1_0_0_0000111,d0	;$4E07 9600 b8 pn s1 xon
;			  || || || | | | 9600bps
;			  || || || | | RTSなし(RSDRV.SYS)
;			  || || || | SISOなし
;			  || || || XONあり
;			  || || 8ビット
;			  || パリティなし
;			  ストップ1
	elif	<tst.b (startup_flag)r>,ne	;起動時の設定を読み出す
		lea.l	SRAM_AUX_MODE,a1
		IOCS	_B_WPEEK
	else				;現在の設定を読み出す
		moveq.l	#-1,d1
		IOCS	_SET232C
	endif
	move.w	d0,d4			;変更前の設定値
;<d4.w:変更前の設定値

;設定を変更する
	move.w	d4,d5			;変更後の設定値
	not.w	d6
	and.w	d6,d5			;変更する項目を消して
	or.w	d7,d5			;書き換える
;<d5.w:変更後の設定値

;設定を書き込む
	if	<tst.b (startup_flag)r>,ne	;起動時の設定を書き込む
		moveq.l	#$31,d1
		lea.l	SYSPORT_SRAM,a1
		IOCS	_B_BPOKE
		move.w	d5,d1
		lea.l	SRAM_AUX_MODE,a1
		IOCS	_B_WPOKE
		moveq.l	#$00,d1
		lea.l	SYSPORT_SRAM,a1
		IOCS	_B_BPOKE
	else				;現在の設定を書き込む。初期化を伴うので変化しなくても書き込む
		move.w	d5,d1
		IOCS	_SET232C
	endif

;設定を表示する
	if	<tst.b (quiet_flag)r>,eq
		movea.l	aBUF,a0
		lea.l	(current_message)r,a1
		if	<tst.b (startup_flag)r>,ne
			lea.l	(startup_message)r,a1
		endif
		bsr	strcpy
		lea.l	(five_message)r,a1
		if	<tst.b (seven_flag)r>,ne
			lea.l	(seven_message)r,a1
		endif
		bsr	strcpy
		move.w	d5,d0			;設定値
		bsr	h4tos
		move.b	#' ',(a0)+
		lea.l	(keywords)r,a3
		dostart
			move.l	(a3)+,d2		;周波数|マスク
			move.w	(a3)+,d3		;設定値
			moveq.l	#17,d0			;5MHzの場合は周波数が%10のキーワードを表示しない
			if	<tst.b (seven_flag)r>,ne
				moveq.l	#16,d0			;7.3728MHzの場合は周波数が%01のキーワードを表示しない
			endif
			if	<btst.l d0,d2>,eq	;表示するとき
				move.w	d5,d0
				and.w	d2,d0			;項目を取り出して
				if	<cmp.w d3,d0>,eq	;比較して一致したら
					movea.l	a3,a1			;キーワードを
					bsr	strcpy			;コピーする
					move.b	#' ',(a0)+
				endif
			endif
			adda.w	d1,a3				;次のキーワードへ
		start
			move.w	(a3)+,d1		;キーワードの長さ
		while	ne
		if	<cmpi.b #' ',-1(a0)>,eq	;最後が' 'ならば
			subq.l	#1,a0			;1文字戻る
		endif
		bsr	crlf
		movea.l	aBUF,a0
		bsr	print			;表示する
	endif

;終了
	DOS	_EXIT

error_exit:
	lea.l	(how_to_use)r,a0
	bsr	more
	move.w	#1,-(sp)
	DOS	_EXIT2

how_to_use:
	.dc.b	TITLE_STRING,13,10
	.dc.b	'Change current or startup RS-232C settings',13,10
	.dc.b	'    -5      Display baud rate at 5 MHz (default)',13,10
	.dc.b	'    -7      Display baud rate at 7.3728 MHz',13,10
	.dc.b	'    -c      Change current RS-232C settings as in SPEED.X (default)',13,10
	.dc.b	'    -i      Use initial setting value $4E07 9600 b8 pn s1 xon',13,10
	.dc.b	'    -q      Do not display settings',13,10
	.dc.b	'    -s      Change startup RS-232C settings as in SWITCH.X',13,10
	.dc.b	'    $xxxx   Specify setting value by 4-digit hexadecimal number',13,10
	.dc.b	'  Baud rate at 5 MHz',13,10
	.dc.b	'    75',13,10
	.dc.b	'    150',13,10
	.dc.b	'    300',13,10
	.dc.b	'    600',13,10
	.dc.b	'    1200',13,10
	.dc.b	'    2400',13,10
	.dc.b	'    4800',13,10
	.dc.b	'    9600',13,10
	.dc.b	'    19200',13,10
	.dc.b	'    38400',13,10
	.dc.b	'    76800',13,10
	.dc.b	'  Baud rate at 7.3728 MHz',13,10
	.dc.b	'    112.5',13,10
	.dc.b	'    225',13,10
	.dc.b	'    450',13,10
	.dc.b	'    900',13,10
	.dc.b	'    1800',13,10
	.dc.b	'    3600',13,10
	.dc.b	'    7200',13,10
	.dc.b	'    14400',13,10
	.dc.b	'    28800',13,10
	.dc.b	'    57600',13,10
	.dc.b	'    115200',13,10
	.dc.b	'  Data',13,10
	.dc.b	'    b5      5-bit',13,10
	.dc.b	'    b6      6-bit',13,10
	.dc.b	'    b7      7-bit',13,10
	.dc.b	'    b7s     7-bit with SI/SO',13,10
	.dc.b	'    b8      8-bit',13,10
	.dc.b	'  Parity',13,10
	.dc.b	'    pn      Non-parity',13,10
	.dc.b	'    po      Odd parity',13,10
	.dc.b	'    pe      Even parity',13,10
	.dc.b	'  Stop bit',13,10
	.dc.b	'    s1      Stop 1-bit',13,10
	.dc.b	'    s1.5    Stop 1.5-bit',13,10
	.dc.b	'    s2      Stop 2-bit',13,10
	.dc.b	'  Flow control',13,10
	.dc.b	'    none    No flow control',13,10
	.dc.b	'    xon     XON/XOFF flow control',13,10
	.dc.b	'    rts     RTS/CTS flow control',13,10
	.dc.b	0
current_message:
	.dc.b	'Current RS-232C settings at ',0
startup_message:
	.dc.b	'Startup RS-232C settings at ',0
five_message:
	.dc.b	'5 MHz are: $',0
seven_message:
	.dc.b	'7.3728 MHz are: $',0
	.even

;キーワードのリスト
keyword	.macro	freq,mask,value,string
	.dc.w	@tail-@head
	.dc.w	freq			;周波数
	.dc.w	mask			;マスク
	.dc.w	value			;設定値
@head:	.dc.b	string,0		;キーワード
	.even
@tail:
	.endm
keywords:
	keyword	%01,$001F,$0000,'75'	;ボーレート(5MHz)
	keyword	%01,$001F,$0001,'150'
	keyword	%01,$001F,$0002,'300'
	keyword	%01,$001F,$0003,'600'
	keyword	%01,$001F,$0004,'1200'
	keyword	%01,$001F,$0005,'2400'
	keyword	%01,$001F,$0006,'4800'
	keyword	%01,$001F,$0007,'9600'
	keyword	%01,$001F,$0008,'19200'
	keyword	%01,$001F,$0009,'38400'
	keyword	%01,$001F,$000A,'76800'
	keyword	%10,$001F,$0000,'112.5'	;ボーレート(7.3728MHz)
	keyword	%10,$001F,$0001,'225'
	keyword	%10,$001F,$0002,'450'
	keyword	%10,$001F,$0003,'900'
	keyword	%10,$001F,$0004,'1800'
	keyword	%10,$001F,$0005,'3600'
	keyword	%10,$001F,$0006,'7200'
	keyword	%10,$001F,$0007,'14400'
	keyword	%10,$001F,$0008,'28800'
	keyword	%10,$001F,$0009,'57600'
	keyword	%10,$001F,$000A,'115200'
	keyword	%00,$0D00,$0000,'b5'	;データ
	keyword	%00,$0D00,$0400,'b6'
	keyword	%00,$0D00,$0800,'b7'
	keyword	%00,$0D00,$0900,'b7s'	;SISO
	keyword	%00,$0D00,$0C00,'b8'
	keyword	%00,$3000,$0000,'pn'	;パリティ。IPLROMの$00ED001AとSPEED.Xの$0926のpnは00
	keyword	%00,$3000,$1000,'po'
	keyword	%00,$3000,$2000,'pn'	;SWITCH.Xの$00ED001Aのpnは10
	keyword	%00,$3000,$3000,'pe'
	keyword	%00,$C000,$4000,'s1'	;ストップビット
	keyword	%00,$C000,$8000,'s1.5'
	keyword	%00,$C000,$C000,'s2'
	keyword	%00,$0280,$0000,'none'	;フロー制御
	keyword	%00,$0280,$0200,'xon'
	keyword	%00,$0280,$0080,'rts'
	.dc.w	0			;番兵

	.bss
seven_flag:
	.dc.b	1			;-7 7.3728MHzのときのボーレートを表示する
initial_flag:
	.ds.b	1			;-i 初期値を使う
quiet_flag:
	.ds.b	1			;-q 設定を表示しない
startup_flag:
	.ds.b	1			;-s 起動時の設定を変更する
buffer:
	.ds.b	1024			;文字列バッファ
	.text

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
;符号なし整数を16進数4桁の文字列に変換する
;<d0.w:符号なし整数
;<a0.l:バッファ。16進数4桁の文字列の先頭
;>a0.l:16進数4桁の文字列の末尾の0の位置
h4tos::
	push	d1-d2
	moveq.l	#4-1,d1
	for	d1
		rol.w	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	100f(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

100:	.dc.b	'0123456789ABCDEF'

;----------------------------------------------------------------
;文字の種類を確認する
;<d0.b:文字
;>c:cc=成功,cs=失敗
isgraph::
	gotoand	<cmp.b #'!',d0>,hs,<cmp.b #'~',d0>,ls,2f
	goto	1f
isupper::
	gotoand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls,2f
	goto	1f
isalnum::
	gotoand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls,2f
isalpha::
	gotoand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls,2f
islower::
	gotoand	<cmp.b #'a',d0>,hs,<cmp.b #'z',d0>,ls,2f
	goto	1f
isbdigit::
	gotoand	<cmp.b #'0',d0>,hs,<cmp.b #'1',d0>,ls,2f
	goto	1f
isodigit::
	gotoand	<cmp.b #'0',d0>,hs,<cmp.b #'7',d0>,ls,2f
	goto	1f
isxdigit::
	gotoand	<cmp.b #'A',d0>,hs,<cmp.b #'F',d0>,ls,2f
	gotoand	<cmp.b #'a',d0>,hs,<cmp.b #'f',d0>,ls,2f
isdigit::
	gotoand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls,2f
	goto	1f
isspace::
	goto	<cmp.b #' ',d0>,eq,2f
	gotoand	<cmp.b #$09,d0>,hs,<cmp.b #$0D,d0>,ls,2f
1:	move.w	#%00001,ccr		;cs=失敗
	rts
2:	move.w	#%00000,ccr		;cc=成功
	rts

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
;小文字にする
;<d0.b:文字
;>d0.b:文字
tolower::
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;大文字
		add.b	#'a'-'A',d0		;小文字にする
	endif
	rts

	.end

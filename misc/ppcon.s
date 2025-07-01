;========================================================================================
;  ppcon.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	dosconst.equ
	.include	doswork.equ
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sram.equ

DEVICE_NAME	reg	'CON     '
TITLE_STRING	reg	'Proportional-Pitch CONsole'
VERSION_STRING	reg	'0.11'
MAGIC_STRING	reg	'PPCON011'

;----------------------------------------------------------------
;プログラムの先頭
	.text
program_head:

;デバイスヘッダ
	.dc.l	-1			;次のデバイスヘッダ。-1=デバイスヘッダのリストの末尾
	.dc.w	$8003			;デバイスタイプ。キャラクタデバイス、標準出力、標準入力
	.dc.l	strategy_routine	;ストラテジルーチン
	.dc.l	interrupt_routine	;インタラプトルーチン
	.dc.b	DEVICE_NAME		;デバイス名

;----------------------------------------------------------------
;マジック
magic:
	.dc.b	MAGIC_STRING

;ベクタテーブル
vector_table:
;カーソル点滅処理ルーチン
	.dc.w	BIOS_TC_CURSOR_HANDLE	;オフセット
	.dc.l	timer_c_cursor		;新しいベクタ
	.dc.l	0			;古いベクタ
;_B_CURON
	.dc.w	4*($100+_B_CURON)
	.dc.l	iocs_1E_B_CURON
	.dc.l	0
;_B_CUROFF
	.dc.w	4*($100+_B_CUROFF)
	.dc.l	iocs_1F_B_CUROFF
	.dc.l	0
;_B_PUTC
	.dc.w	4*($100+_B_PUTC)
	.dc.l	iocs_20_B_PUTC
	.dc.l	0
;_B_PRINT
	.dc.w	4*($100+_B_PRINT)
	.dc.l	iocs_21_B_PRINT
	.dc.l	0
;_B_COLOR
	.dc.w	4*($100+_B_COLOR)
	.dc.l	iocs_22_B_COLOR
	.dc.l	0
;_B_LOCATE
	.dc.w	4*($100+_B_LOCATE)
	.dc.l	iocs_23_B_LOCATE
	.dc.l	0
;_B_DOWN_S
	.dc.w	4*($100+_B_DOWN_S)
	.dc.l	iocs_24_B_DOWN_S
	.dc.l	0
;_B_UP_S
	.dc.w	4*($100+_B_UP_S)
	.dc.l	iocs_25_B_UP_S
	.dc.l	0
;_B_UP
	.dc.w	4*($100+_B_UP)
	.dc.l	iocs_26_B_UP
	.dc.l	0
;_B_DOWN
	.dc.w	4*($100+_B_DOWN)
	.dc.l	iocs_27_B_DOWN
	.dc.l	0
;_B_RIGHT
	.dc.w	4*($100+_B_RIGHT)
	.dc.l	iocs_28_B_RIGHT
	.dc.l	0
;_B_LEFT
	.dc.w	4*($100+_B_LEFT)
	.dc.l	iocs_29_B_LEFT
	.dc.l	0
;_B_CLR_ST
	.dc.w	4*($100+_B_CLR_ST)
	.dc.l	iocs_2A_B_CLR_ST
	.dc.l	0
;_B_ERA_ST
	.dc.w	4*($100+_B_ERA_ST)
	.dc.l	iocs_2B_B_ERA_ST
	.dc.l	0
;_B_INS
	.dc.w	4*($100+_B_INS)
	.dc.l	iocs_2C_B_INS
	.dc.l	0
;_B_DEL
	.dc.w	4*($100+_B_DEL)
	.dc.l	iocs_2D_B_DEL
	.dc.l	0
;_B_CONSOL
	.dc.w	4*($100+_B_CONSOL)
	.dc.l	iocs_2E_B_CONSOL
	.dc.l	0
;_OS_CURON
	.dc.w	4*($100+_OS_CURON)
	.dc.l	iocs_AE_OS_CURON
	.dc.l	0
;_OS_CUROF
	.dc.w	4*($100+_OS_CUROF)
	.dc.l	iocs_AF_OS_CUROF
	.dc.l	0
;_PUTCHAR
	.dc.w	$1800+4*(_PUTCHAR-$FF00)
	.dc.l	dos_FF02_PUTCHAR
old_putchar:
	.dc.l	0
;_INPOUT
	.dc.w	$1800+4*(_INPOUT-$FF00)
	.dc.l	dos_FF06_INPOUT
old_inpout:
	.dc.l	0
;_PRINT
	.dc.w	$1800+4*(_PRINT-$FF00)
	.dc.l	dos_FF09_PRINT
old_print:
	.dc.l	0
;_FPUTC
	.dc.w	$1800+4*(_FPUTC-$FF00)
	.dc.l	dos_FF1D_FPUTC
old_fputc:
	.dc.l	0
;_FPUTS
	.dc.w	$1800+4*(_FPUTS-$FF00)
	.dc.l	dos_FF1E_FPUTS
old_fputs:
	.dc.l	0
;_CONCTRL
	.dc.w	$1800+4*(_CONCTRL-$FF00)
	.dc.l	dos_FF23_CONCTRL
old_conctrl:
	.dc.l	0
;_WRITE
	.dc.w	$1800+4*(_WRITE-$FF00)
	.dc.l	dos_FF40_WRITE
old_write:
	.dc.l	0
	.dc.w	0

;----------------------------------------------------------------
;リクエストヘッダのアドレス
request_header:
	.dc.l	0

;ストラテジルーチン
strategy_routine:
	move.l	a5,request_header
	rts

;インタラプトルーチン
interrupt_routine:
	push	d0-d7/a0-a6
	movea.l	request_header(pc),a5
	moveq.l	#0,d0
	move.b	2(a5),d0		;コマンド番号
	if	<cmp.w #(jump_table_end-jump_table)/2,d0>,hs	;範囲外
		moveq.l	#(jump_table_end-jump_table)/2,d0
	endif
	add.w	d0,d0
	move.w	jump_table(pc,d0.w),d0
	jsr	jump_table(pc,d0.w)
	move.b	d0,3(a5)		;エラーコード下位
	lsr.w	#8,d0
	move.b	d0,4(a5)		;エラーコード上位
	pop
	rts

;デバイスコマンドのジャンプテーブル
jump_table:
	.dc.w	initialize-jump_table		;デバイスコマンド0 初期化
	.dc.w	command_error-jump_table	;デバイスコマンド1 ディスク交換チェック
	.dc.w	command_error-jump_table	;デバイスコマンド2 BPBテーブルの再構築
	.dc.w	ioctrl_input-jump_table		;デバイスコマンド3 _IOCTRLによる入力
	.dc.w	input-jump_table		;デバイスコマンド4 入力
	.dc.w	control_sense-jump_table	;デバイスコマンド5 コントロール/センス
	.dc.w	input_status-jump_table		;デバイスコマンド6 入力ステータス
	.dc.w	input_flush-jump_table		;デバイスコマンド7 入力バッファフラッシュ
	.dc.w	output-jump_table		;デバイスコマンド8 出力(ベリファイなし)
	.dc.w	output-jump_table		;デバイスコマンド9 出力(ベリファイあり)
	.dc.w	output_status-jump_table	;デバイスコマンド10 出力ステータス
	.dc.w	no_error-jump_table		;デバイスコマンド11 正常終了
	.dc.w	ioctrl_output-jump_table	;デバイスコマンド12 _IOCTRLによる出力
jump_table_end:
	.dc.w	command_error-jump_table	;範囲外 コマンドエラー

;デバイスコマンド1 ディスク交換チェック
;デバイスコマンド2 BPBテーブルの再構築
;コマンドエラー
command_error:
	move.w	#IGNORE|ABORT|UNKNOWN_COMMAND,d0	;無視(I) 中止(A) デバイスドライバに無効なコマンドを指定しました
	rts

;デバイスコマンド3 _IOCTRLによる入力
ioctrl_input:
;	movea.l	14(a5),a1		;アドレス
	goto	command_error

;デバイスコマンド4 入力
input:
	movea.l	14(a5),a1		;アドレス
	move.l	18(a5),d3		;長さ
	dostart
		clr.w	-(sp)			;1文字入力
  .if 0
		DOS	_KEYCTRL
  .else
		movea.l	sp,a6
		movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
		jsr	(a0)
  .endif
		addq.l	#2,sp
		move.b	d0,(a1)+		;文字コード
  .if 0
		break	<cmp.b #13,d0>,eq
  .endif
	start
		subq.l	#1,d3
	while	cc
;	move.l	18(a5),18(a5)		;入力した長さ
	moveq.l	#0,d0			;常に成功する(終わるまで復帰しない)
	rts

;デバイスコマンド5 コントロール/センス
control_sense:
	move.w	#1,-(sp)		;1文字センス
  .if 0
	DOS	_KEYCTRL
  .else
	movea.l	sp,a6
	movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
	jsr	(a0)
  .endif
	addq.l	#2,sp
	move.b	d0,13(a5)		;文字コード
	moveq.l	#0,d0			;常に成功する
	rts

;デバイスコマンド6 入力ステータス
input_status:
	move.w	#1,-(sp)		;1文字センス
  .if 0
	DOS	_KEYCTRL
  .else
	movea.l	sp,a6
	movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
	jsr	(a0)
  .endif
	addq.l	#2,sp
	if	<tst.b d0>,ne
		moveq.l	#0,d0			;0=入力バッファが空ではないので入力できる
	else
		moveq.l	#1,d0			;1=入力バッファが空なので入力できない
	endif
	rts

;デバイスコマンド7 入力バッファフラッシュ
input_flush:
	dostart
		clr.w	-(sp)			;1文字入力
  .if 0
		DOS	_KEYCTRL
  .else
		movea.l	sp,a6
		movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
		jsr	(a0)
  .endif
		addq.l	#2,sp
	start
		move.w	#1,-(sp)		;1文字センス
  .if 0
		DOS	_KEYCTRL
  .else
		movea.l	sp,a6
		movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
		jsr	(a0)
  .endif
		addq.l	#2,sp
	while	<tst.b d0>,ne
	moveq.l	#0,d0			;常に成功する
	rts

;デバイスコマンド8 出力(ベリファイなし)
;デバイスコマンド9 出力(ベリファイあり)
output:
	movea.l	14(a5),a1		;アドレス
	move.l	18(a5),d3		;長さ
	dostart
		moveq.l	#0,d1
		move.b	(a1)+,d1		;文字コード
  .if 0
		move.w	d1,-(sp)
		clr.w	-(sp)			;1文字表示
		DOS	_CONCTRL
		addq.l	#4,sp
  .else
		bsr	putc			;1文字表示
  .endif
	start
		subq.l	#1,d3
	while	cc
;	move.l	18(a5),18(a5)		;出力した長さ
	moveq.l	#0,d0			;常に成功する(終わるまで復帰しない)
	rts

;デバイスコマンド10 出力ステータス
output_status:
	moveq.l	#0,d0			;0=出力バッファが満杯ではないので出力できる
;	moveq.l	#1,d0			;1=出力バッファが満杯なので出力できない
	rts

;デバイスコマンド11 正常終了
no_error:
	moveq.l	#0,d0			;常に成功する
	rts

;デバイスコマンド12 _IOCTRLによる出力
ioctrl_output:
;	movea.l	14(a5),a1		;アドレス
	goto	command_error



;hiocs.xが高速化するDOSコールは$FF02,$FF06,$FF09,$FF1D,$FF1E,$FF23,$FF40。すべて上書きする

;----------------------------------------------------------------
;DOSコール$FF02 _PUTCHAR 標準出力に1バイト出力
;<(a6).w:1バイトデータ
dos_FF02_PUTCHAR:
;標準出力はCONか
	bsr	is_stdout_con		;標準出力はCONか
	if	pl			;エラーなし
		if	ne			;CONではない
		;元の処理へ
			movea.l	old_putchar(pc),a0
			jmp	(a0)
		endif
	;出力する
		moveq.l	#0,d1
		move.b	1(a6),d1
		bsr	putchar_to_con		;CONへ1バイト出力する。プリンタ出力,^S,^P,^N,^Cを処理する
		moveq.l	#0,d0
	endif
	rts

;----------------------------------------------------------------
;CONへ1バイト出力する。プリンタ出力,^S,^P,^N,^Cを処理する
;<d1.l:1バイトデータ
putchar_to_con:
	push	d0-d7/a0-a6
;CONへ出力する
	bsr	putc			;1文字表示
;標準プリンタへ出力する
	if	<tst.b DOS_CTRL_P_MODE.w>,ne
		move.w	#STDPRN,-(sp)		;標準プリンタ出力
		move.w	d1,-(sp)
		movea.l	sp,a6
		movea.l	old_fputc(pc),a0
		jsr	(a0)
		addq.l	#2+2,sp
	endif
;^Sを処理する
	move.w	#$00FE,-(sp)		;$00FE。標準入力の先読み。0でも戻る。BREAKチェックあり
	movea.l	sp,a6
	movea.l	old_inpout(pc),a0
	jsr	(a0)
	addq.l	#2,sp
	if	<cmp.w DOS_CTRL_S_CODE.w,d1>,eq	;^Sが押された
		move.w	#$00FF,-(sp)		;$00FF。標準入力から入力。0でも戻る。BREAKチェックあり
		movea.l	sp,a6
		movea.l	old_inpout(pc),a0
		jsr	(a0)
		addq.l	#2,sp
  .if 0
		DOS	_INKEY
  .else
		movea.l	$1800+4*(_INKEY-$FF00).w,a0
		jsr	(a0)
  .endif
	endif
;^P,^N,^Cを処理する
  .if 0
	DOS	_KEYSNS
  .else
	movea.l	$1800+4*(_KEYSNS-$FF00).w,a0
	jsr	(a0)
  .endif
	pop
	rts

;----------------------------------------------------------------
;DOSコール$FF06 _INPOUT 標準ハンドラへの入出力
;<(a6).w:1バイトデータ
;	$FE	標準入力の先読み。0でも戻る。BREAKチェックあり
;	$FF	標準入力から入力。0でも戻る。BREAKチェックあり
;	その他	標準出力へ1バイト出力
;>d0.l:入力した1バイトデータ
dos_FF06_INPOUT:
;先読みまたは入力か
	if	<cmp.b #$FE,1(a6)>,hs	;先読みまたは入力
	;元の処理へ
		movea.l	old_inpout(pc),a0
		jmp	(a0)
	endif
;標準出力はCONか
	bsr	is_stdout_con		;標準出力はCONか
	if	pl			;エラーなし
		if	ne			;CONではない
		;元の処理へ
			movea.l	old_inpout(pc),a0
			jmp	(a0)
		endif
	;CONへ出力する
		moveq.l	#0,d1
		move.b	1(a6),d1
		bsr	putc			;1文字表示
	;標準プリンタへ出力する
		if	<tst.b DOS_CTRL_P_MODE.w>,ne
			move.w	#STDPRN,-(sp)		;標準プリンタ出力
			move.w	d1,-(sp)
			movea.l	sp,a6
			movea.l	old_fputc(pc),a0
			jsr	(a0)
			addq.l	#2+2,sp
		endif
		moveq.l	#0,d0
	;^S,^P,^N,^Cは処理しない
	endif
	rts

;----------------------------------------------------------------
;DOSコール$FF09 _PRINT 標準出力に文字列を出力
;<(a6).l:文字列
dos_FF09_PRINT:
;標準出力はCONか
	bsr	is_stdout_con		;標準出力はCONか
	if	pl			;エラーなし
		if	ne			;CONではない
		;元の処理へ
			movea.l	old_print(pc),a0
			jmp	(a0)
		endif
	;CONへ出力する
		movea.l	(a6),a1			;文字列
		dostart
			bsr	putchar_to_con		;CONへ1バイト出力する。プリンタ出力,^S,^P,^N,^Cを処理する
		start
			moveq.l	#0,d1
			move.b	(a1)+,d1
		while	ne
		moveq.l	#0,d0
	endif
	rts

;----------------------------------------------------------------
;DOSコール$FF1D _FPUTC ハンドラへ1バイト出力
;<(a6).w:文字
;<2(a6).w:ハンドラ番号
;>d0.l:出力した長さまたはエラーコード
dos_FF1D_FPUTC:
;ハンドラはCONか
	move.w	2(a6),d0		;ハンドラ番号
	bsr	is_handle_con		;ハンドラはCONか
	if	pl			;エラーなし
		if	ne			;CONではない
		;元の処理へ
			movea.l	old_fputc(pc),a0
			jmp	(a0)
		endif
	;書き込めるか
		moveq.l	#$0F,d0
		and.b	14(a0),d0		;ファイルオープンモード
		if	ne			;書き込める
		;CONへ出力する。プリンタ出力,^S,^P,^N,^Cは処理しない
			moveq.l	#0,d1
			move.b	1(a6),d1		;文字
			bsr	putc			;1文字表示
			moveq.l	#1,d0			;出力した長さ
		else				;書き込めない
			moveq.l	#INVALID_ACCESS_MODE,d0	;オープンのアクセスモードが異常
		endif
	endif
	rts

;----------------------------------------------------------------
;DOSコール$FF1E _FPUTS ハンドラへ文字列を出力
;<(a6).l:文字列
;<4(a6).w:ハンドラ番号
;>d0.l:出力した長さまたはエラーコード
dos_FF1E_FPUTS:
;文字列の長さは0か
	movea.l	(a6),a0			;文字列
	tst.b	(a0)
	if	eq			;文字列の長さは0
	;ハンドラ番号に関係なく正常終了する
		moveq.l	#0,d0			;出力した長さ
	else				;文字列の長さは0ではない
	;ハンドラはCONか
		move.w	4(a6),d0		;ハンドラ番号
		bsr	is_handle_con		;ハンドラはCONか
		if	pl			;エラーなし
			if	ne			;CONではない
			;元の処理へ
				movea.l	old_fputs(pc),a0
				jmp	(a0)
			endif
		;書き込めるか
			moveq.l	#$0F,d0
			and.b	14(a0),d0		;ファイルオープンモード
			if	ne			;書き込める
			;CONへ出力する。プリンタ出力,^S,^P,^N,^Cは処理しない
				movea.l	(a6),a1			;文字列
				move.l	a1,d0
				dostart
					bsr	putc			;1文字表示
				start
					moveq.l	#0,d1
					move.b	(a1)+,d1
				while	ne
				subq.l	#1,a1
				exg.l	d0,a1
				sub.l	a1,d0			;出力した長さ
			else				;書き込めない
				moveq.l	#INVALID_ACCESS_MODE,d0	;オープンのアクセスモードが異常
			endif
		endif
	endif
	rts

;----------------------------------------------------------------
;DOSコール$FF23 _CONCTRL コンソール出力の制御
;<(a6).w:モード
;	0	1文字表示
;			<2(a6).w:1バイトデータ
;	1	文字列表示
;			<2(a6).l:文字列
;	2	文字属性の設定
;			<2(a6).w:属性
;	3	カーソルの移動
;			<2(a6).w:X座標
;			<4(a6).w:Y座標
;	4	カーソルを1行下へ移動(下端ではスクロールアップ)
;	5	カーソルを1行上へ移動(上端ではスクロールダウン)
;	6	カーソルをN行上へ移動
;			<2(a6).w:N
;	7	カーソルをN行下へ移動
;			<2(a6).w:N
;	8	カーソルをN桁右へ移動
;			<2(a6).w:N
;	9	カーソルをN桁左へ移動
;			<2(a6).w:N
;	10	画面消去
;			<2(a6).w:モード
;				0
;				1
;				2
;	11	行消去
;			<2(a6).w:モード
;				0
;				1
;				2
;	12	N行挿入
;			<2(a6).w:N
;	13	N行削除
;			<2(a6).w:N
;	14	ファンクション表示行のモードの取得と設定
;			<2(a6).w:モード
;				-1	取得
;				0	ノーマル
;				1	シフト
;				2	表示しない
;				3	普通の行
;	15	スクロール範囲の設定
;			<2(a6).w:スクロール範囲の開始行のY座標
;			<4(a6).w:スクロール範囲の行数
;	16	画面モードの設定
;			<2(a6).w:画面モード
;				0	768x512,グラフィックなし
;				1	768x512,グラフィック16色
;				2	512x512,グラフィックなし
;				3	512x512,グラフィック16色
;				4	512x512,グラフィック256色
;				5	512x512,グラフィック65536色
;	17	カーソル表示
;	18	カーソル消去
dos_FF23_CONCTRL:
	move.w	(a6),d0			;モード
	if	<cmp.w #13,d0>,hi	;IOCSコール以外
	;元の処理へ
		movea.l	old_conctrl(pc),a0
		jmp	(a0)
	endif
	movea.l	2(a6),a1
	move.l	a1,d1
	swap.w	d1
	move.l	a1,d2
	add.w	d0,d0
	move.w	100f(pc,d0.w),d0
	jmp	100f(pc,d0.w)
100:
	.dc.w	iocs_20_B_PUTC-100b
	.dc.w	iocs_21_B_PRINT-100b
	.dc.w	iocs_22_B_COLOR-100b
	.dc.w	iocs_23_B_LOCATE-100b
	.dc.w	iocs_24_B_DOWN_S-100b
	.dc.w	iocs_25_B_UP_S-100b
	.dc.w	iocs_26_B_UP-100b
	.dc.w	iocs_27_B_DOWN-100b
	.dc.w	iocs_28_B_RIGHT-100b
	.dc.w	iocs_29_B_LEFT-100b
	.dc.w	iocs_2A_B_CLR_ST-100b
	.dc.w	iocs_2B_B_ERA_ST-100b
	.dc.w	iocs_2C_B_INS-100b
	.dc.w	iocs_2D_B_DEL-100b

;----------------------------------------------------------------
;DOSコール$FF40 _WRITE ハンドラへ指定されたサイズのデータを書き込む
;<(a6).w:ハンドラ番号
;<2(a6).l:文字列
;<6(a6).l:文字列の長さ
;>d0.l:出力した長さ
dos_FF40_WRITE:
;ハンドラはCONか
	move.w	(a6),d0			;ハンドラ番号
	bsr	is_handle_con		;ハンドラはCONか
	if	pl			;エラーなし
		if	ne			;CONではない
		;元の処理へ
			movea.l	old_write(pc),a0
			jmp	(a0)
		endif
	;書き込めるか
		moveq.l	#$0F,d0
		and.b	14(a0),d0		;ファイルオープンモード
		if	ne			;書き込める
		;CONへ出力する。プリンタ出力,^S,^P,^N,^Cを処理する
			movea.l	2(a6),a1		;文字列
			move.l	6(a6),d0		;文字列の長さ
			move.l	d0,d2
			dostart
				moveq.l	#0,d1
				move.b	(a1)+,d1
				bsr	putchar_to_con		;CONへ1バイト出力する。プリンタ出力,^S,^P,^N,^Cを処理する
			start
				subq.l	#1,d2
			while	cc
		else				;書き込めない
			moveq.l	#INVALID_ACCESS_MODE,d0	;オープンのアクセスモードが異常
		endif
	endif
	rts

;----------------------------------------------------------------
;標準出力はCONか
;>d0.l:FCBテーブルまたはエラーコード
;>a0.l:FCBテーブル
;>n:pl=エラーなし,mi=エラーあり
;>z:ne=CONではない,eq=CON
;?d1-d7/a1-a5
is_stdout_con:
	moveq.l	#1,d0
;----------------------------------------------------------------
;ハンドラはCONか
;<d0.w:ハンドラ番号
;>d0.l:FCBテーブルまたはエラーコード
;>a0.l:FCBテーブル
;>n:pl=エラーなし,mi=エラーあり
;>z:ne=CONではない,eq=CON
;?d1-d7/a1-a5
is_handle_con:
  .if 0
	move.w	d0,-(sp)
	DOS	_GETFCB
	addq.l	#2,sp
  .else
	push	a6
	move.w	d0,-(sp)
	movea.l	sp,a6
	movea.l	$1800+4*(_GETFCB-$FF00).w,a0
	jsr	(a0)
	addq.l	#2,sp
	pop
  .endif
	if	<tst.l d0>,pl		;エラーなし
		movea.l	d0,a0			;FCBテーブル
		if	<tst.b 1(a0)>,mi	;キャラクタデバイス
			cmpi.l	#'CON ',36(a0)		;デバイス名またはファイル名1
		endif
	endif
	rts



;コンソール拡張
BIOS_ATTRIBUTE_2	equ	$0D30		;.b 文字属性2。-|上付き|下付き|上線|丸囲み|四角囲み|プロポーショナル|波線
BIOS_SUPERSCRIPT_BIT	equ	 6		;上付き
BIOS_SUPERSCRIPT	equ	%01000000
BIOS_SUBSCRIPT_BIT	equ	  5		;下付き
BIOS_SUBSCRIPT		equ	%00100000
BIOS_OVERLINE_BIT	equ	    4		;上線
BIOS_OVERLINE		equ	%00010000
BIOS_ENCIRCLE_BIT	equ	     3		;丸囲み
BIOS_ENCIRCLE		equ	%00001000
BIOS_FRAME_BIT		equ	      2		;四角囲み
BIOS_FRAME		equ	%00000100
BIOS_PROPORTIONAL_BIT	equ	       1	;プロポーショナル
BIOS_PROPORTIONAL	equ	%00000010
BIOS_WAVELINE_BIT	equ	        0	;波線
BIOS_WAVELINE		equ	%00000001
BIOS_CURSOR_FRACTION	equ	$0D31		;.b カーソルの桁座標の端数。0～7
BIOS_SAVED_ATTRIBUTE_2	equ	$0D32		;.b ESC [sで保存された文字属性2
BIOS_SAVED_FRACTION	equ	$0D33		;.b ESC [sで保存されたカーソルの桁座標の端数
BIOS_BUFFER_REQUEST	equ	$0D34		;.w バッファの文字列を表示する領域のドット幅。0=バッファ出力中ではない
BIOS_BUFFER_WIDTH	equ	$0D36		;.w バッファの文字列のドット幅
BIOS_BUFFER_POINTER	equ	$0D38		;.l バッファの書き込み位置
BIOS_BUFFER_ARRAY	equ	$0D3C		;.w[64] バッファ。右寄せ、中央寄せで使う
BIOS_CONSOLE_STATUS	equ	$0DBC		;.b コンソールの状態。----|左寄せ|中央寄せ|右寄せ|連結
BIOS_ALIGN_LEFT_BIT	equ	     3		;左寄せ
BIOS_ALIGN_LEFT		equ	%00001000
BIOS_ALIGN_CENTER_BIT	equ	      2		;中央寄せ
BIOS_ALIGN_CENTER	equ	%00000100
BIOS_ALIGN_RIGHT_BIT	equ	       1	;右寄せ
BIOS_ALIGN_RIGHT	equ	%00000010
BIOS_CONNECTION_BIT	equ	        0	;連結。最後に描画した文字は斜体でその後カーソルを動かしていない。次も斜体ならば詰めて描画する
BIOS_CONNECTION		equ	%00000001
;				$0DBD		;.b[3]

;----------------------------------------------------------------
;カーソル点滅処理ルーチン
;	Timer-C割り込みルーチンから500ms間隔で呼ばれる
timer_c_cursor:
	if	<tst.b BIOS_CURSOR_ON.w>,ne	;カーソルを表示するとき
		ifor	<tst.w BIOS_CURSOR_NOT_BLINK.w>,eq,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;点滅させるか、描かれていないとき
			if	<btst.b #1,CRTC_ACCESS>,eq	;CRTCのマスクが使用中でないとき
				bsr	toggle_cursor		;カーソルを反転させる
				not.b	BIOS_CURSOR_DRAWN.w	;カーソルが描かれているか。0=描かれていない,-1=描かれている
			endif
		endif
	endif
	rts

;----------------------------------------------------------------
;カーソルを反転させる
toggle_cursor:
	push	d0-d2/a0-a2
	move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
	swap.w	d0
	clr.w	d0			;65536*行座標
	lsr.l	#5,d0			;128*16*行座標
	move.w	BIOS_CURSOR_COLUMN.w,d1	;カーソルの桁座標
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d1	;右端で止まる
	endif
	add.w	d1,d0
	add.l	BIOS_CONSOLE_OFFSET.w,d0
	add.l	#$00E00000,d0		;カーソルのアドレス
	movea.l	d0,a2
	move.w	CRTC_ACCESS,-(sp)
	bclr.b	#0,CRTC_ACCESS		;同時アクセスOFF
***	move.w	BIOS_CURSOR_PATTERN.w,d1
***	if	eq
***		moveq.l	#-1,d1
***	endif
	moveq.l	#$80,d1
	move.b	BIOS_CURSOR_FRACTION.w,d0
	lsr.b	d0,d1
	bsr	toggle_cursor_1		;プレーン0を反転
***	lsr.w	#8,d1
	adda.l	#$00020000,a2
	bsr	toggle_cursor_1		;プレーン1を反転
	move.w	(sp)+,CRTC_ACCESS
	pop
	rts

toggle_cursor_1:
	move.w	BIOS_CURSOR_START.w,d2	;カーソル描画開始ライン*4
	jmp	@f(pc,d2.w)
@@:	eor.b	d1,(a2)
	movea.l	a0,a0			;nop
  .irp row,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	eor.b	d1,128*row(a2)
  .endm
	rts

;----------------------------------------------------------------
;IOCSコール$1E _B_CURON カーソルを表示する
iocs_1E_B_CURON:
	ifand	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq,<tst.b BIOS_CURSOR_ON.w>,eq	;許可されていて表示していないとき
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;タイマカウンタ。1回目を10ms*5=50ms後に発生させる
		st.b	BIOS_CURSOR_ON.w	;表示している
		clr.b	BIOS_CURSOR_DRAWN.w	;描かれていない
	endif
	rts

;----------------------------------------------------------------
;IOCSコール$1F _B_CUROFF カーソルを表示しない
iocs_1F_B_CUROFF:
	if	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq	;許可されているとき
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;タイマカウンタ。1回目を10ms*5=50ms後に発生させる
		clr.b	BIOS_CURSOR_ON.w	;表示していない
		if	<tst.b BIOS_CURSOR_DRAWN.w>,ne	;描かれているとき
			bsr	toggle_cursor		;カーソルを反転させる
			clr.b	BIOS_CURSOR_DRAWN.w	;描かれていない
		endif
	endif
	rts

;----------------------------------------------------------------
;IOCSコール$20 _B_PUTC 文字を表示する
;<d1.w:文字コード
;>d0.l:表示後のカーソルの桁座標<<16|カーソルの行座標
iocs_20_B_PUTC:
	bsr	putc			;1文字表示
	move.l	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標<<16|カーソルの行座標
	rts

;----------------------------------------------------------------
;IOCSコール$21 _B_PRINT 文字列を表示する
;<a1.l:文字列のアドレス
;>d0.l:表示後のカーソルの桁座標<<16|カーソルの行座標
;>a1.l:文字列の末尾の0の次のアドレス。マニュアルに書いてある。変更不可
iocs_21_B_PRINT:
	push	d1
	dostart
		bsr	putc			;1文字表示
	start
		moveq.l	#0,d1
		move.b	(a1)+,d1
	while	ne
	pop
	move.l	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標<<16|カーソルの行座標
	rts

;----------------------------------------------------------------
;IOCSコール$22 _B_COLOR 文字属性を設定する
;<d1.w:文字属性。-1=取得のみ
;	0	黒
;	1	水色
;	2	黄色
;	3	白
;	4+	太字
;	8+	反転
;>d0.l:設定前の文字属性。-1=設定値が範囲外
iocs_22_B_COLOR:
	push	d1
	moveq.l	#0,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;文字属性2。-|上付き|下付き|上線|丸囲み|四角囲み|プロポーショナル|波線
	lsl.w	#8,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;文字属性1。取り消し線|下線|斜体|細字|反転|太字|プレーン##
	if	<cmp.w #-1,d1>,ne	;設定するとき
		if	<cmp.w #$7FFF,d1>,ls	;設定値が範囲内のとき
			move.b	d1,BIOS_ATTRIBUTE_1.w
			lsr.w	#8,d1
			move.b	d1,BIOS_ATTRIBUTE_2.w
		else				;設定値が範囲外のとき
			moveq.l	#-1,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$23 _B_LOCATE カーソルの座標を設定する
;<d1.w:カーソルの桁座標の端数<<8|カーソルの桁座標。-1=取得のみ
;<d2.w:カーソルの行座標
;>d0.l:設定前のカーソルの座標。カーソルの桁座標の端数<<24|カーソルの桁座標<<16|カーソルの行座標。-1=設定値が範囲外
;>d1.l:(IOCS.X,1.3以上)取得のみのときd0.lと同じ
iocs_23_B_LOCATE:
	moveq.l	#0,d0
	move.b	BIOS_CURSOR_FRACTION.w,d0
	ror.l	#8,d0
	or.l	BIOS_CURSOR_COLUMN.w,d0	;BIOS_CURSOR_ROW。カーソルの桁座標の端数<<24|カーソルの桁座標<<16|カーソルの行座標
	if	<cmp.w #-1,d1>,eq	;取得のみ
		move.l	d0,d1
		rts
	endif
	push	d1/d3
	move.w	d1,d3
	and.w	#$00FF,d1		;カーソルの桁座標
	lsr.w	#8,d3			;カーソルの桁座標の端数
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls,<cmp.w #7,d3>,ls	;設定値が範囲内のとき
;		push	d0
		bsr	iocs_1F_B_CUROFF
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		move.b	d3,BIOS_CURSOR_FRACTION.w
		bsr	iocs_1E_B_CURON
;		pop	d0
	else				;設定値が範囲外のとき
		moveq.l	#-1,d0
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$24 _B_DOWN_S カーソルを1行下へ。下端ではスクロールアップ
;>d0.l:0
iocs_24_B_DOWN_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$25 _B_UP_S カーソルを1行上へ。上端ではスクロールダウン
;>d0.l:0
iocs_25_B_UP_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi	;上端ではないとき
		subq.w	#1,d0			;1行上へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;上端のとき
		moveq.l	#0,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;コピー元の下端の行座標
		moveq.l	#1,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		moveq.l	#0,d0			;上端の行座標
		moveq.l	#0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$26 _B_UP カーソルをn行上へ。上端を超えるときは動かない
;<d1.b:移動する行数。0=1行
;>d0.l:0=成功,-1=失敗。上端を超える。このときカーソルは動かない
iocs_26_B_UP:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
	sub.w	d1,d0			;n行上へ
	if	mi			;上端を超える
		moveq.l	#-1,d1
	else				;上端を超えない
		move.w	d0,BIOS_CURSOR_ROW.w
		moveq.l	#0,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$27 _B_DOWN カーソルをn行下へ。下端で止まる
;<d1.b:移動する行数。0=1行
;>d0.l:0
iocs_27_B_DOWN:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
	add.w	d1,d0			;n行下へ
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;下端を超える
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;下端で止まる
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$28 _B_RIGHT カーソルをn桁右へ。右端で止まる
;<d1.w:移動する桁数。0=1桁
;>d0.l:0
iocs_28_B_RIGHT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標
	add.w	d1,d0			;n行右へ
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;右端を超える
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;右端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$29 _B_LEFT カーソルをn桁左へ。左端で止まる
;<d1.w:移動する桁数。0=1桁
;>d0.l:0
iocs_29_B_LEFT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標
	sub.w	d1,d0			;n行左へ
	if	mi			;左端を超える
		clr.w	d0			;左端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$2A _B_CLR_ST 範囲を選択して画面を消去
;<d1.b:範囲。0=カーソルから右下まで,1=左上からカーソルまで,2=左上から右下まで。カーソルを左上へ
;>d0.l:0=成功,-1=失敗。引数がおかしい
iocs_2A_B_CLR_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=カーソルから右下まで
		bsr	putc_csi_0J		;ESC [0J カーソルから右下まで消去する
		moveq.l	#0,d1
	elif	eq			;1=左上からカーソルまで
		bsr	putc_csi_1J		;ESC [1J 左上からカーソルまで消去する
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=左上から右下まで
		bsr	putc_csi_2J		;ESC [2J 左上から右下まで消去する。カーソルを左上へ
		moveq.l	#0,d1
	else
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2B _B_ERA_ST 範囲を選択して行を消去
;<d1.b:範囲。0=カーソルから右端まで,1=左端からカーソルまで,2=左端から右端まで
;>d0.l:0=成功,-1=失敗。引数がおかしい
iocs_2B_B_ERA_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=カーソルから右端まで
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
		moveq.l	#0,d1
	elif	eq			;1=左端からカーソルまで
		bsr	putc_csi_1K		;ESC [1K 左端からカーソルまで消去する
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=左端から右端まで
		bsr	putc_csi_2K		;ESC [2K 左端から右端まで消去する
		moveq.l	#0,d1
	else				;引数がおかしい
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2C _B_INS カーソルから下にn行挿入。カーソルを左端へ
;<d1.w:挿入する行数。0=1行
;>d0.l:0
iocs_2C_B_INS:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_L		;ESC [nL カーソルから下にn行挿入。カーソルを左端へ
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2D _B_DEL カーソルから下をn行削除。カーソルを左端へ
;<d1.w:削除する行数。0=1行
;>d0.l:0
iocs_2D_B_DEL:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_M		;ESC [nM カーソルから下をn行削除。カーソルを左端へ
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2E _B_CONSOL コンソールの範囲を設定。カーソルを左上へ
;<d1.l:左上Xドット座標<<16|左上Yドット座標。-1=取得のみ。左上Xドット座標は8の倍数、左上Yドット座標は4の倍数
;<d2.l:右端の桁座標<<16|下端の行座標。-1=取得のみ
;>d0.l:0
;>d1.l:設定前の左上Xドット座標<<16|左上Yドット座標
;>d2.l:設定前の右端の桁座標<<16|下端の行座標
iocs_2E_B_CONSOL:
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CONSOLE_OFFSET.w,d0
	if	<cmp.l #-1,d1>,ne
		and.l	#($03F8<<16)|$03FC,d1
		move.l	d1,d0
		swap.w	d0		;左上Xドット座標
		lsr.w	#3,d0		;左上Xドット座標/8
		ext.l	d1
		lsl.l	#7,d1		;左上Yドット座標*128
		add.w	d0,d1
		move.l	BIOS_CONSOLE_OFFSET.w,d0
		move.l	d1,BIOS_CONSOLE_OFFSET.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w。カーソルを左上へ
	endif
	moveq.l	#127,d1
	and.w	d0,d1			;左上Xドット座標/8
	lsl.w	#3,d1			;左上Xドット座標
	swap.w	d1
	lsr.l	#7,d0			;左上Yドット座標
	move.w	d0,d1			;設定前の左上Xドット座標<<16|左上Yドット座標
	move.l	BIOS_CONSOLE_RIGHT.w,d0	;BIOS_CONSOLE_BOTTOM.w
	if	<cmp.l #-1,d2>,ne
		and.l	#127<<16|63,d2
		move.l	d2,BIOS_CONSOLE_RIGHT.w	;BIOS_CONSOLE_BOTTOM.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w。カーソルを左上へ
	endif
	move.l	d0,d2			;設定前の右端の桁座標<<16|下端の行座標
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$AE _OS_CURON カーソルの表示を許可する
iocs_AE_OS_CURON:
	move.w	BIOS_TC_CURSOR_PERIOD.w,BIOS_TC_CURSOR_COUNTER.w	;タイマカウンタを初期値にする
	di				;割込み禁止
	ifor	<tst.b BIOS_CURSOR_PROHIBITED.w>,ne,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;禁止されているか描かれていないとき
		bsr	toggle_cursor		;カーソルを反転させる
		st.b	BIOS_CURSOR_DRAWN.w	;描かれている
	endif
	st.b	BIOS_CURSOR_ON.w		;表示している
	sf.b	BIOS_CURSOR_PROHIBITED.w	;許可されている
	ei				;割り込み許可
	rts

;----------------------------------------------------------------
;IOCSコール$AF _OS_CUROF カーソルの表示を禁止する
iocs_AF_OS_CUROF:
	bsr	iocs_1F_B_CUROFF
	st.b	BIOS_CURSOR_PROHIBITED.w	;禁止されている
	rts

;----------------------------------------------------------------
;1文字表示
;<d1.w:文字コード
putc:
	push	d0-d1
	if	<move.b BIOS_PUTC_POOL.w,d0>,eq	;1バイト目のとき
		if	<cmp.w #$001F,d1>,ls	;$0000～$001Fのとき
			bsr	putc_control		;制御文字を処理する
		elif	<cmp.w #$007F,d1>,ls	;$0020～$007Fのとき
			if	<cmp.w #$005C,d1>,eq	;$005Cのとき
				if	<btst.b #0,SRAM_XCHG>,ne	;文字変換フラグ。-----|$7C｜/$82￤|$7E￣/$81～|$5C￥/$80＼
					move.w	#$0080,d1		;$5C→$80
				endif
			elif	<cmp.w #$007E,d1>,eq	;$007Eのとき
				if	<btst.b #1,SRAM_XCHG>,ne	;文字変換フラグ。-----|$7C｜/$82￤|$7E￣/$81～|$5C￥/$80＼
					move.w	#$0081,d1		;$7E→$81
				endif
			elif	<cmp.w #$007C,d1>,eq	;$007Cのとき
				if	<btst.b #2,SRAM_XCHG>,ne	;文字変換フラグ。-----|$7C｜/$82￤|$7E￣/$81～|$5C￥/$80＼
					move.w	#$0082,d1		;$7C→$82
				endif
			endif
			bsr	putc_output		;画面に描くまたはバッファに出力する
		elif	<cmp.w #$009F,d1>,ls	;$0080～$009Fのとき
			move.b	d1,BIOS_PUTC_POOL.w	;1バイト目のプール
		elif	<cmp.w #$00DF,d1>,ls	;$00A0～$00DFのとき
			bsr	putc_output		;画面に描くまたはバッファに出力する
		elif	<cmp.w #$00FF,d1>,ls	;$00E0～$00FFのとき
			move.b	d1,BIOS_PUTC_POOL.w	;1バイト目のプール
		else				;$0100～$FFFFのとき
			bsr	putc_output		;画面に描くまたはバッファに出力する
		endif
	else				;2バイト目のとき
		if	<cmp.b #$1B,d0>,eq	;1バイト目が$1Bのとき。エスケープシーケンスの出力中
			bsr	putc_escape		;エスケープシーケンスを処理する
		else				;1バイト目が$1Bではないとき
			clr.b	BIOS_PUTC_POOL.w	;1バイト目を消費する
			lsl.w	#8,d0			;1バイト目<<8
			move.b	d1,d0			;1バイト目<<8|2バイト目
			move.w	d0,d1			;1バイト目<<8|2バイト目。1バイト目があるときd1.wの上位バイトは無視される
			bsr	putc_output		;画面に描くまたはバッファに出力する
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;バッファ出力を終了する
putc_finish_buffer:
	push	d0-d6/a0-a1
	move.w	BIOS_BUFFER_REQUEST.w,d0
	goto	eq,putc_finish_buffer_end	;バッファ出力中ではない
;<d0.w:バッファの文字列を表示する領域のドット幅
	move.w	BIOS_BUFFER_WIDTH.w,d1
;<d1.w:バッファの文字列のドット幅
	movea.l	BIOS_BUFFER_POINTER.w,a0
;<a0.l:バッファの書き込み位置=文字列の直後
	lea.l	BIOS_BUFFER_ARRAY.w,a1
;<a1.l:バッファ=文字列の先頭
	clr.w	BIOS_BUFFER_REQUEST.w	;バッファ出力終了。再帰呼び出しで表示するのでその前に終了すること
	clr.w	BIOS_BUFFER_WIDTH.w
	move.l	a1,BIOS_BUFFER_POINTER.w
	sub.w	d1,d0			;余るドット数
;<d0.w:余るドット数
	if	ls			;余らないとき
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;左寄せで余るとき
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;右側の余った範囲を消去する
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	elif	<bclr.b #BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;右寄せで余るとき
	;左側の余った範囲を消去する
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w>,ne	;中央寄せで余るとき
	;左側の余った範囲を消去する
		move.w	d0,d6
		lsr.w	#1,d0			;左側の余った範囲のドット幅
		sub.w	d0,d6			;右側の余った範囲のドット幅
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;右側の余った範囲を消去する
		move.w	d6,d0
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	endif
putc_finish_buffer_end:
	pop
	rts

;----------------------------------------------------------------
;制御文字を処理する
;<d1.w:文字コード
putc_control:
	push	d0-d1
;バッファ出力を終了する
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;バッファ出力中
		bsr	putc_finish_buffer	;バッファ出力を終了する
	endif
;カーソルが右端からはみ出しているときBSでなければ改行する
	move.w	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi,<cmp.w #$0008,d1>,ne	;カーソルが右端からはみ出しているかつBSではないとき
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;制御文字を処理する
	add.w	d1,d1
	move.w	putc_control_jump_table(pc,d1.w),d1
	jsr	putc_control_jump_table(pc,d1.w)
	pop
	rts

putc_control_jump_table:
	.dc.w	putc_00_NL-putc_control_jump_table	;制御文字$00 NL 
	.dc.w	putc_01_SH-putc_control_jump_table	;制御文字$01 SH 
	.dc.w	putc_02_SX-putc_control_jump_table	;制御文字$02 SX 
	.dc.w	putc_03_EX-putc_control_jump_table	;制御文字$03 EX 
	.dc.w	putc_04_ET-putc_control_jump_table	;制御文字$04 ET 
	.dc.w	putc_05_EQ-putc_control_jump_table	;制御文字$05 EQ 
	.dc.w	putc_06_AK-putc_control_jump_table	;制御文字$06 AK 
	.dc.w	putc_07_BL-putc_control_jump_table	;制御文字$07 BL ベルを鳴らす
	.dc.w	putc_08_BS-putc_control_jump_table	;制御文字$08 BS カーソルを1桁左へ。左端では1行上の右端へ。上端では何もしない
	.dc.w	putc_09_HT-putc_control_jump_table	;制御文字$09 HT カーソルを次のタブ桁へ。なければ1行下の左端へ。下端ではスクロールアップして左端へ
	.dc.w	putc_0A_LF-putc_control_jump_table	;制御文字$0A LF カーソルを1行下へ。下端ではスクロールアップ
	.dc.w	putc_0B_VT-putc_control_jump_table	;制御文字$0B VT カーソルを1行上へ。上端では何もしない
	.dc.w	putc_0C_FF-putc_control_jump_table	;制御文字$0C FF カーソルを1桁右へ。右端では1行下の左端へ。下端ではスクロールアップして左端へ
	.dc.w	putc_0D_CR-putc_control_jump_table	;制御文字$0D CR カーソルを左端へ
	.dc.w	putc_0E_SO-putc_control_jump_table	;制御文字$0E SO 
	.dc.w	putc_0F_SI-putc_control_jump_table	;制御文字$0F SI 
	.dc.w	putc_10_DE-putc_control_jump_table	;制御文字$10 DE 
	.dc.w	putc_11_D1-putc_control_jump_table	;制御文字$11 D1 
	.dc.w	putc_12_D2-putc_control_jump_table	;制御文字$12 D2 
	.dc.w	putc_13_D3-putc_control_jump_table	;制御文字$13 D3 
	.dc.w	putc_14_D4-putc_control_jump_table	;制御文字$14 D4 
	.dc.w	putc_15_NK-putc_control_jump_table	;制御文字$15 NK 
	.dc.w	putc_16_SN-putc_control_jump_table	;制御文字$16 SN 
	.dc.w	putc_17_EB-putc_control_jump_table	;制御文字$17 EB 
	.dc.w	putc_18_CN-putc_control_jump_table	;制御文字$18 CN 
	.dc.w	putc_19_EM-putc_control_jump_table	;制御文字$19 EM 
	.dc.w	putc_1A_SB-putc_control_jump_table	;制御文字$1A SB 左上から右下まで消去。カーソルを左上へ
	.dc.w	putc_1B_EC-putc_control_jump_table	;制御文字$1B EC エスケープシーケンス開始
	.dc.w	putc_1C_FS-putc_control_jump_table	;制御文字$1C FS 
	.dc.w	putc_1D_GS-putc_control_jump_table	;制御文字$1D GS 
	.dc.w	putc_1E_RS-putc_control_jump_table	;制御文字$1E RS カーソルを左上へ
	.dc.w	putc_1F_US-putc_control_jump_table	;制御文字$1F US 

;----------------------------------------------------------------
;制御文字$00 NL 
putc_00_NL:
	rts

;----------------------------------------------------------------
;制御文字$01 SH 
putc_01_SH:
	rts

;----------------------------------------------------------------
;制御文字$02 SX 
putc_02_SX:
	rts

;----------------------------------------------------------------
;制御文字$03 EX 
putc_03_EX:
	rts

;----------------------------------------------------------------
;制御文字$04 ET 
putc_04_ET:
	rts

;----------------------------------------------------------------
;制御文字$05 EQ 
putc_05_EQ:
	rts

;----------------------------------------------------------------
;制御文字$06 AK 
putc_06_AK:
	rts

;----------------------------------------------------------------
;制御文字$07 BL ベルを鳴らす
putc_07_BL:
	push	d0-d2/a0-a1
	move.l	BIOS_BEEP_DATA.w,d0	;BEEP音のADPCMデータのアドレス。-1=BIOS_BEEP_EXTENSIONを使う
	moveq.l	#-1,d1
	if	<cmp.l d1,d0>,eq
		movea.l	BIOS_BEEP_EXTENSION.w,a0	;BEEP処理まるごと差し換えルーチンのアドレス。BIOS_BEEP_DATA=-1のとき有効
		jsr	(a0)
	else
		move.w	#4<<8|3,d1
		moveq.l	#0,d2
		move.w	BIOS_BEEP_LENGTH.w,d2	;BEEP音のADPCMデータのバイト数。0=無音
		movea.l	d0,a1
		IOCS	_ADPCMOUT
	endif
	pop
	rts

;----------------------------------------------------------------
;制御文字$08 BS カーソルを1桁左へ。左端では1行上の右端へ。上端では何もしない
putc_08_BS:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	ne
		subq.w	#1,d0			;1桁左へ
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else
		move.w	BIOS_CURSOR_ROW.w,d0
		if	ne
			subq.w	#1,d0			;1行上へ
			move.w	d0,BIOS_CURSOR_ROW.w
			move.w	BIOS_CONSOLE_RIGHT.w,BIOS_CURSOR_COLUMN.w	;右端へ
			clr.b	BIOS_CURSOR_FRACTION.w
		endif
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$09 HT カーソルを次のタブ桁へ。なければ1行下の左端へ。下端ではスクロールアップして左端へ
putc_09_HT:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	addq.w	#8,d0
	and.w	#-8,d0			;次のタブ桁へ
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,ls	;範囲内
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;範囲外
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0A LF カーソルを1行下へ。下端ではスクロールアップ
putc_0A_LF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0B VT カーソルを1行上へ。上端では何もしない
putc_0B_VT:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	hi
		subq.w	#1,d0			;1行上へ
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0C FF カーソルを1桁右へ。右端では1行下の左端へ。下端ではスクロールアップして左端へ
putc_0C_FF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,lo	;右端ではないとき
		addq.w	#1,d0			;1桁右へ
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;右端のとき
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0D CR カーソルを左端へ
putc_0D_CR:
	push	d0
	bsr	iocs_1F_B_CUROFF
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0E SO 
putc_0E_SO:
	rts

;----------------------------------------------------------------
;制御文字$0F SI 
putc_0F_SI:
	rts

;----------------------------------------------------------------
;制御文字$10 DE 
putc_10_DE:
	rts

;----------------------------------------------------------------
;制御文字$11 D1 
putc_11_D1:
	rts

;----------------------------------------------------------------
;制御文字$12 D2 
putc_12_D2:
	rts

;----------------------------------------------------------------
;制御文字$13 D3 
putc_13_D3:
	rts

;----------------------------------------------------------------
;制御文字$14 D4 
putc_14_D4:
	rts

;----------------------------------------------------------------
;制御文字$15 NK 
putc_15_NK:
	rts

;----------------------------------------------------------------
;制御文字$16 SN 
putc_16_SN:
	rts

;----------------------------------------------------------------
;制御文字$17 EB 
putc_17_EB:
	rts

;----------------------------------------------------------------
;制御文字$18 CN 
putc_18_CN:
	rts

;----------------------------------------------------------------
;制御文字$19 EM 
putc_19_EM:
	rts

;----------------------------------------------------------------
;制御文字$1A SB 左上から右下まで消去。カーソルを左上へ
putc_1A_SB:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;上端の行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	clr.l	BIOS_CURSOR_COLUMN.w	;左上へ
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$1B EC エスケープシーケンス開始
putc_1B_EC:
	move.b	#$1B,BIOS_PUTC_POOL.w	;1バイト目のプール
	move.l	#BIOS_ESCAPE_BUFFER,BIOS_ESCAPE_POINTER.w	;エスケープシーケンスバッファの書き込み位置
	rts

;----------------------------------------------------------------
;制御文字$1C FS 
putc_1C_FS:
	rts

;----------------------------------------------------------------
;制御文字$1D GS 
putc_1D_GS:
	rts

;----------------------------------------------------------------
;制御文字$1E RS カーソルを左上へ
putc_1E_RS:
	bsr	iocs_1F_B_CUROFF
	clr.l	BIOS_CURSOR_COLUMN.w
	bsr	iocs_1E_B_CURON
	rts

;----------------------------------------------------------------
;制御文字$1F US 
putc_1F_US:
	rts

;----------------------------------------------------------------
;エスケープシーケンスを処理する
;<d1.w:文字コード
putc_escape:
	push	d0/a0
	movea.l	BIOS_ESCAPE_POINTER.w,a0
	move.b	d1,(a0)+
	if	<cmpa.l #BIOS_ESCAPE_BUFFER+10,a0>,lo
		move.l	a0,BIOS_ESCAPE_POINTER.w
	endif
	move.b	BIOS_ESCAPE_BUFFER.w,d0	;エスケープシーケンスの最初の文字
	if	<cmp.b #'[',d0>,eq	;ESC [
		moveq.l	#$20,d0
		or.b	d1,d0
		ifand	<cmp.b #'`',d0>,hs,<cmp.b #'z',d0>,ls	;'@'～'Z','`'～'z'
			bsr	putc_csi
		endif
	elif	<cmp.b #'*',d0>,eq	;ESC *
		bsr	putc_esc_ast
	elif	<cmp.b #'=',d0>,eq	;ESC =
		if	<cmpa.l #BIOS_ESCAPE_BUFFER+3,a0>,eq
			bsr	putc_esc_equ
		endif
	elif	<cmp.b #'D',d0>,eq	;ESC D
		bsr	putc_esc_D
	elif	<cmp.b #'E',d0>,eq	;ESC E
		bsr	putc_esc_E
	elif	<cmp.b #'M',d0>,eq	;ESC M
		bsr	putc_esc_M
	else				;その他
		clr.b	BIOS_PUTC_POOL.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC *
;	左上から右下まで消去。カーソルを左上へ
putc_esc_ast:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;上端の行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	clr.l	BIOS_CURSOR_COLUMN.w	;カーソルを左上へ
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC = r c
;	カーソルをr-' '行,c-' '桁へ。rとcは文字
putc_esc_equ:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	moveq.l	#0,d1
	moveq.l	#0,d2
	move.b	BIOS_ESCAPE_BUFFER+2.w,d1	;桁。' '=0
	move.b	BIOS_ESCAPE_BUFFER+1.w,d2	;行。' '=0
	moveq.l	#' ',d0
	sub.w	d0,d1			;桁座標
	sub.w	d0,d2			;行座標
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls	;コンソールの範囲内のとき
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC D
;	カーソルを1行下へ。下端ではスクロールアップ
;	_B_DOWN_Sと同じ
putc_esc_D:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC E
;	カーソルを1行下の左端へ。下端ではスクロールアップ
putc_esc_E:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC M
;	カーソルを1行上へ。上端ではスクロールダウン
;	_B_UP_Sと同じ
putc_esc_M:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi		;上端ではないとき
		subq.w	#1,d0			;1行上へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;上端のとき
		moveq.l	#0,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;コピー元の下端の行座標
		moveq.l	#1,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		moveq.l	#0,d0			;上端の行座標
		moveq.l	#0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC [
;	https://en.wikipedia.org/wiki/ANSI_escape_code
;	http://nanno.dip.jp/softlib/man/rlogin/ctrlcode.html
putc_csi:
	push	d0-d3/a0
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CSI_EXTENSION.w,d0	;エスケープシーケンス丸ごと差し替えルーチン
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	else
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		move.w	(a0)+,d0
		if	<cmp.w #'[>',d0>,eq	;ESC [>
			move.w	(a0)+,d0
			if	<cmp.w #'5l',d0>,eq	;ESC [>5l カーソルON
				sf.b	BIOS_CURSOR_PROHIBITED.w
			elif	<cmp.w #'5h',d0>,eq	;ESC [>5h カーソルOFF
				st.b	BIOS_CURSOR_PROHIBITED.w
			else
				bsr	putc_csi_extension
			endif
		elif	<cmp.w #'[?',d0>,eq	;ESC [?
			move.w	(a0)+,d0
			if	<cmp.w #'4l',d0>,eq	;ESC [?4l ジャンプスクロール
				clr.w	BIOS_SMOOTH_SCROLL.w
			elif	<cmp.w #'4h',d0>,eq	;ESC [?4h 8ドットスムーススクロール
				move.w	#2,BIOS_SMOOTH_SCROLL.w
			else
				bsr	putc_csi_extension
			endif
		else
			lea.l	BIOS_ESCAPE_BUFFER+1.w,a0	;[の次
			moveq.l	#0,d0
			moveq.l	#-1,d1			;1番目の数値
			moveq.l	#-1,d2			;2番目の数値
			moveq.l	#-1,d3			;3番目の数値
			do
				move.b	(a0)+,d0
			while	<cmp.b #' ',d0>,eq
			ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				moveq.l	#0,d1
				do
					sub.b	#'0',d0
					mulu.w	#10,d1
					add.w	d0,d1
					move.b	(a0)+,d0
				whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				if	<cmp.b #';',d0>,eq
					do
						move.b	(a0)+,d0
					while	<cmp.b #' ',d0>,eq
					ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						moveq.l	#0,d2
						do
							sub.b	#'0',d0
							mulu.w	#10,d2
							add.w	d0,d2
							move.b	(a0)+,d0
						whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						if	<cmp.b #';',d0>,eq
							do
								move.b	(a0)+,d0
							while	<cmp.b #' ',d0>,eq
							ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
								moveq.l	#0,d3
								do
									sub.b	#'0',d0
									mulu.w	#10,d3
									add.w	d0,d3
									move.b	(a0)+,d0
								whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
							endif
						endif
					endif
				endif
			endif
			if	<cmp.b #'@',d0>,eq
				bsr	putc_csi_at		;ESC [n@ カーソルから右にn桁挿入
			elif	<cmp.b #'A',d0>,eq
				bsr	putc_csi_A		;ESC [nA カーソルをn行上へ。上端を超えるときは動かない
			elif	<cmp.b #'B',d0>,eq
				bsr	putc_csi_B		;ESC [nB カーソルをn行下へ。下端で止まる
			elif	<cmp.b #'C',d0>,eq
				bsr	putc_csi_C		;ESC [nC カーソルをn桁右へ。右端で止まる
			elif	<cmp.b #'D',d0>,eq
				bsr	putc_csi_D		;ESC [nD カーソルをn桁左へ。左端で止まる
			elif	<cmp.b #'H',d0>,eq
				bsr	putc_csi_H		;ESC [r;cH カーソルをr-1行,c-1桁へ
			elif	<cmp.b #'J',d0>,eq
				bsr	putc_csi_J		;ESC [nJ 画面を消去する
			elif	<cmp.b #'K',d0>,eq
				bsr	putc_csi_K		;ESC [nK 行を消去する
			elif	<cmp.b #'L',d0>,eq
				bsr	putc_csi_L		;ESC [nL カーソルから下にn行挿入。カーソルを左端へ
			elif	<cmp.b #'M',d0>,eq
				bsr	putc_csi_M		;ESC [nM カーソルから下をn行削除。カーソルを左端へ
			elif	<cmp.b #'P',d0>,eq
				bsr	putc_csi_P		;ESC [nP カーソルから右をn桁削除
			elif	<cmp.b #'R',d0>,eq
				bsr	putc_csi_R		;ESC [r;cR CSR(Cursor Position Report)
			elif	<cmp.b #'X',d0>,eq
				bsr	putc_csi_X		;ESC [nX カーソルから右をn桁消去
			elif	<cmp.b #'c',d0>,eq
				bsr	putc_csi_c		;ESC [nc 中央寄せ
			elif	<cmp.b #'f',d0>,eq
				bsr	putc_csi_f		;ESC [r;cf カーソルをr-1行,c-1桁へ
			elif	<cmp.b #'l',d0>,eq
				bsr	putc_csi_l		;ESC [nl 左寄せ
			elif	<cmp.b #'m',d0>,eq
				bsr	putc_csi_m		;ESC [nm 文字属性を設定する
			elif	<cmp.b #'n',d0>,eq
				bsr	putc_csi_n		;ESC [nn DSR(Device Status Report)
			elif	<cmp.b #'r',d0>,eq
				bsr	putc_csi_r		;ESC [nr 右寄せ
			elif	<cmp.b #'s',d0>,eq
				bsr	putc_csi_s		;ESC [ns カーソルの座標と文字属性を保存する
			elif	<cmp.b #'u',d0>,eq
				bsr	putc_csi_u		;ESC [nu カーソルの座標と文字属性を復元する
			else
				bsr	putc_csi_extension
			endif
		endif
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;拡張エスケープシーケンス処理ルーチンを呼び出す
putc_csi_extension:
	push	d0/a0
	move.l	BIOS_ESCAPE_EXTENSION.w,d0
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [n@ カーソルから右にn桁挿入
;<d1.w:挿入する桁数。0=1桁
putc_csi_at:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
;
;	ＡＢＣＤＥＦＧＨＩ
;	ＡＢＣ　　　　ＤＥ
;
	move.w	BIOS_CURSOR_COLUMN.w,d4
	add.w	d1,d4			;カーソルの桁座標+挿入する桁数=移動先の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3
	sub.w	d4,d3			;コンソールの右端-移動先の桁座標=移動する部分の桁数-1
	if	lo			;すべて押し出される
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
	else				;移動する部分がある
		move.w	BIOS_CURSOR_ROW.w,d0	;行座標
		swap.w	d0
		clr.w	d0			;65536*行座標
		lsr.l	#5,d0			;128*16*行座標
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;行の左端のアドレス
		movea.l	a2,a3
		adda.w	BIOS_CURSOR_COLUMN.w,a2	;カーソルのアドレス
		adda.w	d3,a2			;移動元の右端のアドレス
		adda.w	BIOS_CONSOLE_RIGHT.w,a3	;行の右端のアドレス=移動先の右端のアドレス
		do				;プレーンのループ
			moveq.l	#16-1,d2
			for	d2			;ラスタのループ
				lea.l	1(a2),a0		;移動元の右端のアドレス+1
				lea.l	1(a3),a1		;移動先の右端のアドレス+1
				move.w	d3,d1			;移動する部分の桁数-1
				for	d1			;桁のループ
					move.b	-(a0),-(a1)
				next
				lea.l	128(a2),a2		;次のラスタ
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;次のプレーン
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
		move.w	d4,d3
		subq.w	#1,d3			;右端の桁座標
		moveq.l	#0,d4			;左端の桁座標の端数
		moveq.l	#7,d5			;右端の桁座標の端数
		bsr	putc_clear		;行を消去する
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nA カーソルをn行上へ。上端を超えるときは動かない
;<d1.w:移動する行数。0=1行
putc_csi_A:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	sub.w	d1,d0			;n行上へ
	if	hs			;上端を超えないとき
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nB カーソルをn行下へ。下端で止まる
;<d1.w:移動する行数。0=1桁
putc_csi_B:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	add.w	d1,d0			;n行下へ
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;下端を超えるとき
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;下端で止まる
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nC カーソルをn桁右へ。右端で止まる
;<d1.w:移動する桁数。0=1桁
putc_csi_C:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	add.w	d1,d0			;n桁右へ
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;右端を超えるとき
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;右端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nD カーソルをn桁左へ。左端で止まる
;<d1.w:移動する桁数。0=1桁
putc_csi_D:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	sub.w	d1,d0			;n桁左へ
	if	lo			;左端を超えるとき
		moveq.l	#0,d0			;左端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cf カーソルをr-1行,c-1桁へ
;<d1.w:移動先の行座標+1。0=上端。下端で止まる
;<d2.w:移動先の桁座標+1。0=左端。右端で止まる
putc_csi_f:
;----------------------------------------------------------------
;ESC [r;cH カーソルをr-1行,c-1桁へ
;<d1.w:移動先の行座標+1。0=上端。下端で止まる
;<d2.w:移動先の桁座標+1。0=左端。右端で止まる
putc_csi_H:
	push	d1-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=上端
	endif
	subq.w	#1,d1
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d1>,hi
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端で止まる
	endif
	ifor	<cmp.w #-1,d2>,eq,<tst.w d2>,eq
		moveq.l	#1,d2			;0=左端
	endif
	subq.w	#1,d2
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d2>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d2	;右端で止まる
	endif
	move.w	d2,BIOS_CURSOR_COLUMN.w
	move.w	d1,BIOS_CURSOR_ROW.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nJ 画面を消去する
;<d1.w:0=カーソルから右下まで,1=左上からカーソルまで,2=左上から右下まで。カーソルを左上へ
putc_csi_J:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0J		;ESC [0J カーソルから右下まで消去する
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1J		;ESC [1J 左上からカーソルまで消去する
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2J		;ESC [2J 左上から右下まで消去する。カーソルを左上へ
	endif
	rts

;----------------------------------------------------------------
;ESC [0J カーソルから右下まで消去する
putc_csi_0J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0
	move.w	BIOS_CONSOLE_BOTTOM.w,d1
	if	<cmp.w d1,d0>,lo		;下端ではないとき
	;	move.w	BIOS_CURSOR_ROW.w,d0
		addq.w	#1,d0			;上端の行座標
	;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
	moveq.l	#0,d4
	move.b	BIOS_CURSOR_FRACTION.w,d4	;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [1J 左上からカーソルまで消去する
putc_csi_1J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d1
	if	<tst.w d1>,hi			;上端ではないとき
		clr.w	d0			;上端の行座標
	;	move.w	BIOS_CURSOR_ROW.w,d1
		subq.w	#1,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	moveq.l	#0,d2			;左端の桁座標
	move.w	BIOS_CURSOR_COLUMN.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5
	add.b	BIOS_CURSOR_FRACTION.w,d5	;右端の桁座標の端数
	if	<cmp.w #7,d5>,hi	;次の桁のとき
		if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,lo	;右端ではないとき
			addq.w	#1,d3
			subq.w	#8,d5
		else				;右端のとき
			moveq.l	#7,d5
		endif
	endif
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [2J 左上から右下まで消去する。カーソルを左上へ
putc_csi_2J:
	push	d0-d1
	moveq.l	#0,d0			;上端の行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	clr.l	BIOS_CURSOR_COLUMN.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nK 行を消去する
;<d1.w:0=カーソルから右端まで,1=左端からカーソルまで,2=左端から右端まで
putc_csi_K:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1K		;ESC [1K 左端からカーソルまで消去する
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2K		;ESC [2K 左端から右端まで消去する
	endif
	rts

;----------------------------------------------------------------
;ESC [0K カーソルから右端まで消去する
putc_csi_0K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [1K 左端からカーソルまで消去する
putc_csi_1K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	moveq.l	#0,d2			;左端の桁座標
	move.w	BIOS_CURSOR_COLUMN.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [2K 左端から右端まで消去する
putc_csi_2K:
	push	d0-d1
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [nL カーソルから下にn行挿入。カーソルを左端へ
;<d1.w:挿入する行数。0=1行
putc_csi_L:
	push	d0-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:カーソルの行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d2	;コンソールの行数-1
	addq.w	#1,d2			;コンソールの行数
	sub.w	d0,d2			;カーソルから下の行数
	sub.w	d1,d2			;画面内に残る行数
;<d2.w:画面内に残る行数
	if	ls			;画面内に残る行がない。すべて画面外に押し出される
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│□□□│
	;  │▲▲▲│  │□□□│
	;  │■■■│  │□□□│
	;  └───┘  └───┘
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	else				;画面内に残る行がある
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│□□□│\d1
	;  │▲▲▲│  │□□□│/
	;  │■■■│  │●●●│)d2
	;  └───┘  └───┘
		add.w	d0,d2
		subq.w	#1,d2			;コピー元の下端の行座標
		add.w	d0,d1			;コピー先の上端の行座標
		exg.l	d1,d2
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;コピー元の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		exg.l	d1,d2
		subq.w	#1,d1			;下端の行座標
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nM カーソルから下をn行削除。カーソルを左端へ
;<d1.w:削除する行数。0=1行
putc_csi_M:
	push	d0-d3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:カーソルの行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d3	;コンソールの行数-1
	addq.w	#1,d3			;コンソールの行数
	sub.w	d0,d3			;カーソルから下の行数
	sub.w	d1,d3			;画面内に残る行数
;<d3.w:画面内に残る行数
	if	ls			;画面内に残る行がない。すべて削除される
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│□□□│
	;  │▲▲▲│  │□□□│
	;  │■■■│  │□□□│
	;  └───┘  └───┘
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	else				;画面内に残る行がある
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│■■■│)d3
	;  │▲▲▲│  │□□□│\d1
	;  │■■■│  │□□□│/
	;  └───┘  └───┘
	;;;	move.w	BIOS_CURSOR_ROW.w,d0
		move.w	d0,d2			;コピー先の上端の行座標
		add.w	d1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	d2,d0
		add.w	d3,d0			;上端の行座標
	;;;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nP カーソルから右をn桁削除
;<d1.w:削除する桁数。0=1桁
putc_csi_P:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
;
;	ＡＢＣＤＥＦＧＨＩ
;	ＡＢＣＨＩ　　　　
;
	move.w	BIOS_CURSOR_COLUMN.w,d4	;カーソルの桁座標
	add.w	d1,d4			;カーソルの桁座標+削除する桁数=移動元の左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;コンソールの右端の桁座標=移動元の右端の桁座標
	sub.w	d4,d3			;移動元の右端の桁座標-移動元の左端の桁座標=移動する部分の桁数-1
	if	lo			;すべて削除される
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
	else				;移動する部分がある
		move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
		swap.w	d0
		clr.w	d0			;65536*カーソルの行座標
		lsr.l	#5,d0			;128*16*カーソルの行座標
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;カーソルの行の左端のアドレス
		movea.l	a2,a3
		adda.w	d4,a2			;カーソルの行の左端のアドレス+移動元の左端の桁座標=移動元の左端のアドレス
		adda.w	BIOS_CURSOR_COLUMN.w,a3	;カーソルの行の左端のアドレス+カーソルの桁座標=カーソルのアドレス=移動先の左端のアドレス
		do				;プレーンのループ
			moveq.l	#16-1,d2
			for	d2			;ラスタのループ
				movea.l	a2,a0			;移動元の左端のアドレス
				movea.l	a3,a1			;移動先の左端のアドレス
				move.w	d3,d1			;移動する部分の桁数-1
				for	d1			;桁のループ
					move.b	(a0)+,(a1)+
				next
				lea.l	128(a2),a2		;次のラスタ
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;次のプレーン
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標=消去する範囲の上端の行座標
		move.w	d0,d1			;カーソルの行座標=消去する範囲の下端の行座標
		move.w	BIOS_CURSOR_COLUMN.w,d2	;カーソルの桁座標
		add.w	d3,d2			;カーソルの桁座標+移動する範囲の桁数-1
		addq.w	#1,d2			;カーソルの桁座標+移動する範囲の桁数=消去する範囲の左端の桁座標
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;コンソールの右端の桁座標=消去する範囲の右端の桁座標
		moveq.l	#0,d4			;消去する範囲の左端の桁座標の端数
		moveq.l	#7,d5			;消去する範囲の右端の桁座標の端数
		bsr	putc_clear		;行を消去する
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cR CPR(Cursor Position Report)
;	DSR(Device Status Report)の返答。ここでは何もしない
putc_csi_R:
	rts

;----------------------------------------------------------------
;ESC [nX カーソルから右をn桁消去
;<d1.w:消去する桁数。0=1桁
putc_csi_X:
	push	d0-d5
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
	move.w	d2,d3
	add.w	d1,d3
	subq.w	#1,d3			;右端の桁座標
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,hi	;右端を超えるとき
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端で止まる
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	moveq.l	#7,d4
	and.b	BIOS_CURSOR_FRACTION.w,d4	;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [nc 中央寄せ
;<d1.w:ドット幅
putc_csi_c:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	if	<cmp.w d0,d1>,ls	;大きすぎない
		bset.b	#BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w	;中央寄せ
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;バッファ出力開始
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nl 左寄せ
;<d1.w:ドット幅
putc_csi_l:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	if	<cmp.w d0,d1>,ls	;大きすぎない
		bset.b	#BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w	;左寄せ
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;バッファ出力開始
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nm 文字属性を設定する
;	0	リセット
;	1	太字
;	2	細字
;	3	斜体
;	4	下線
;	5	(遅い点滅)
;	6	(速い点滅)
;	7	反転
;	8	(秘密)
;	9	取り消し線
;	11～19	(代替フォント1～9)
;	20	(ブラックレター)
;	21	波線
;	22	太字、細字解除
;	23	斜体解除、(ブラックレター解除)
;	24	下線、波線解除
;	25	(遅い点滅解除、速い点滅解除)
;	26	プロポーショナル
;	27	反転解除
;	28	(秘密解除)
;	29	取り消し線解除
;	30	黒
;	31	水色
;	32	黄色
;	33	白
;	34	太字、黒
;	35	太字、水色
;	36	太字、黄色
;	37	太字、白
;	40	反転、黒
;	41	反転、水色
;	42	反転、黄色
;	43	反転、白
;	44	反転、太字、黒
;	45	反転、太字、水色
;	46	反転、太字、黄色
;	47	反転、太字、白
;	50	プロポーショナル解除
;	51	四角囲み
;	52	丸囲み
;	53	上線
;	54	四角囲み、丸囲み解除
;	55	上線解除
;	73	上付き
;	74	下付き
;	75	上付き、下付き解除
;<d1.w:属性。-1=指定なし
;<d2.w:属性。-1=指定なし
;<d3.w:属性。-1=指定なし
putc_csi_m:
	push	d1
	bsr	putc_csi_m_1
	if	<cmp.w #-1,d2>,ne
		move.w	d2,d1
		bsr	putc_csi_m_1
	endif
	if	<cmp.w #-1,d3>,ne
		move.w	d3,d1
		bsr	putc_csi_m_1
	endif
	pop
	rts

;?d1
putc_csi_m_1:
;太字と反転のみトグル動作。その他はONまたはOFFのどちらか
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		move.b	#3,BIOS_ATTRIBUTE_1.w	;文字属性1。取り消し線|下線|斜体|細字|反転|太字|プレーン##
		clr.b	BIOS_ATTRIBUTE_2.w	;文字属性2。-|上付き|下付き|上線|丸囲み|四角囲み|プロポーショナル|波線
	elif	<cmp.w #1,d1>,eq
		bchg.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;太字
		if	eq			;OFF→ONのとき
			bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;細字解除
		endif
	elif	<cmp.w #2,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;太字解除
		bset.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;細字
	elif	<cmp.w #3,d1>,eq
		bset.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;斜体
	elif	<cmp.w #4,d1>,eq
		bset.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;下線
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;波線解除
	elif	<cmp.w #7,d1>,eq
		bchg.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;反転
	elif	<cmp.w #9,d1>,eq
		bset.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;取り消し線
	elif	<cmp.w #21,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;下線解除
		bset.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;波線
	elif	<cmp.w #22,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;太字解除
		bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;細字解除
	elif	<cmp.w #23,d1>,eq
		bclr.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;斜体解除
	elif	<cmp.w #24,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;下線解除
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;波線解除
	elif	<cmp.w #26,d1>,eq
		bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;プロポーショナル
	elif	<cmp.w #27,d1>,eq
		bclr.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;反転解除
	elif	<cmp.w #29,d1>,eq
		bclr.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;取り消し線解除
	elifand	<cmp.w #30,d1>,hs,<cmp.w #37,d1>,ls
		sub.w	#30,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elifand	<cmp.w #40,d1>,hs,<cmp.w #47,d1>,ls
		sub.w	#40,d1
		addq.b	#8,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elif	<cmp.w #50,d1>,eq
		bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;プロポーショナル解除
	elif	<cmp.w #51,d1>,eq
		bset.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;四角囲み
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;丸囲み解除
	elif	<cmp.w #52,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;四角囲み解除
		bset.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;丸囲み
	elif	<cmp.w #53,d1>,eq
		bset.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;上線
	elif	<cmp.w #54,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;四角囲み解除
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;丸囲み解除
	elif	<cmp.w #55,d1>,eq
		bclr.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;上線解除
	elif	<cmp.w #73,d1>,eq
		bset.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;上付き
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;下付き解除
	elif	<cmp.w #74,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;上付き解除
		bset.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;下付き
	elif	<cmp.w #75,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;上付き解除
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;下付き解除
	endif
	rts

;----------------------------------------------------------------
;ESC [nn DSR(Device Status Report)
;<d1.w:6
putc_csi_n:
	push	d0-d2/a0
	if	<cmp.w #6,d1>,eq	;CPR(Cursor Position Report)
		move.w	#$0100+27,d2
		bsr	20f
		move.w	#$1C00+'[',d2
		bsr	20f
		move.w	BIOS_CURSOR_ROW.w,d0
		bsr	10f
		move.w	#$2700+';',d2
		bsr	20f
		move.w	BIOS_CURSOR_COLUMN.w,d0
		bsr	10f
		move.w	#$1400+'R',d2
		bsr	20f
	endif
	pop
	rts

;数値+1を文字列に変換してキー入力バッファに書き込む
;<d0.b:数値。255は不可。ここでは1を省略しない
;?d0-d2/a0
10:	addq.b	#1,d0
	move.l	#(1<<24)+(10<<16)+(100<<8),d1
	do
		lsr.l	#8,d1
	while	<cmp.b d1,d0>,lo
	do
		moveq.l	#-2,d2
		do
			addq.w	#2,d2
			sub.b	d1,d0
		while	hs
		move.w	15f(pc,d2.w),d2
		bsr	20f
		add.b	d1,d0
		lsr.l	#8,d1
	while	<tst.b d1>,ne
	rts

15:	.dc.w	$0B00+'0'
	.dc.w	$0200+'1'
	.dc.w	$0300+'2'
	.dc.w	$0400+'3'
	.dc.w	$0500+'4'
	.dc.w	$0600+'5'
	.dc.w	$0700+'6'
	.dc.w	$0800+'7'
	.dc.w	$0900+'8'
	.dc.w	$0A00+'9'

;キー入力バッファに書き込む
;<d2.w:(スキャンコード<<8)+文字コード
;?a0
20:	di
	if	<cmpi.w #64,BIOS_KEY_REMAINING.w>,lo	;キー入力バッファに残っているデータの数が64未満のとき
		movea.l	BIOS_KEY_WRITTEN.w,a0	;最後に書き込んだ位置
		addq.l	#2,a0			;今回書き込む位置
		if	<cmpa.w #BIOS_KEY_BUFFER+2*64.w,a0>,hs	;末尾を超えたら
			lea.l	BIOS_KEY_BUFFER.w,a0	;先頭に戻る
		endif
		move.w	d2,(a0)			;書き込む
		move.l	a0,BIOS_KEY_WRITTEN.w	;最後に書き込んだ位置
		addq.w	#1,BIOS_KEY_REMAINING.w	;キー入力バッファに残っているデータの数
	endif
	ei
	rts

;----------------------------------------------------------------
;ESC [nr 右寄せ
;<d1.w:ドット幅
putc_csi_r:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	if	<cmp.w d0,d1>,ls	;大きすぎない
		bset.b	#BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w	;右寄せ
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;バッファ出力開始
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [ns カーソルの座標と文字属性を保存する
;<d1.w:-1
putc_csi_s:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_CURSOR_ROW.w,BIOS_SAVED_ROW.w
		move.w	BIOS_CURSOR_COLUMN.w,BIOS_SAVED_COLUMN.w
		move.b	BIOS_CURSOR_FRACTION.w,BIOS_SAVED_FRACTION.w
		move.b	BIOS_ATTRIBUTE_1.w,BIOS_SAVED_ATTRIBUTE_1.w
		move.b	BIOS_ATTRIBUTE_2.w,BIOS_SAVED_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;ESC [nu カーソルの座標と文字属性を復元する
;<d1.w:-1
putc_csi_u:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_SAVED_ROW.w,BIOS_CURSOR_ROW.w
		move.w	BIOS_SAVED_COLUMN.w,BIOS_CURSOR_COLUMN.w
		move.b	BIOS_SAVED_FRACTION.w,BIOS_CURSOR_FRACTION.w
		move.b	BIOS_SAVED_ATTRIBUTE_1.w,BIOS_ATTRIBUTE_1.w
		move.b	BIOS_SAVED_ATTRIBUTE_2.w,BIOS_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;画面に描くまたはバッファに出力する
;<d1.w:文字コード
putc_output:
	push	d0-d7/a0-a2
	lea.l	-4*16-4*16(sp),sp	;フォントデータとマスクデータ
;<(sp).l[16]:フォントデータ
;<4*16(sp).l[16]:マスクデータ
	move.w	d1,d7
;<d7.w:文字コード
;----------------
;フォントアドレスとドット幅を求める
	ifand	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne,<cmp.w #$0020,d1>,hs,<cmp.w #$0082,d1>,ls	;プロポーショナルにする
		lea.l	proportional_font(pc),a0	;プロポーショナルフォント($20～$82)
		sub.w	#$0020,d1
		mulu.w	#2+2*16,d1
		adda.l	d1,a0			;フォントアドレス
		move.w	(a0)+,d6		;ドット幅。1～16
		moveq.l	#1,d2			;16ドットデータ
	else				;プロポーショナルにしない
		moveq.l	#8,d2
		IOCS	_FNTADR
	;<d0.l:フォントアドレス
	;<d1.w:横方向のドット数<<16|横方向のバイト数-1
	;<d2.w:縦方向のドット数-1
		movea.l	d0,a0			;フォントアドレス
		move.w	d1,d2			;0=8ドットデータ,1=16ドットデータ
		swap.w	d1
		move.w	d1,d6			;ドット幅。1～16
	endif
;<d2.w:0=8ドットデータ,1=16ドットデータ
;<d6.w:ドット幅。1～16
;<(a0).b[16]:8ドットデータ
;または
;<(a0).w[16]:16ドットデータ
;----------------
;バッファに出力するか
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;バッファ出力中
		movea.l	BIOS_BUFFER_POINTER.w,a0	;バッファの書き込み位置
		goto	<cmpa.l #BIOS_BUFFER_ARRAY+2*64,a0>,hs,putc_output_end	;バッファが一杯のときは無視する
		move.w	d7,(a0)+		;文字コード
		move.l	a0,BIOS_BUFFER_POINTER.w	;書き込み位置を進める
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;プロポーショナルのとき
			if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;太字のとき
				addq.w	#1,d6			;幅が1ドット増える
			endif
			if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;斜体のとき
				addq.w	#3,d6			;幅が3ドット増える
				bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
				if	ne	;連結のとき
					subq.w	#3,BIOS_BUFFER_WIDTH.w	;3ドット詰める
					if	cs
						clr.w	BIOS_BUFFER_WIDTH.w	;念の為
					endif
				endif
			else				;斜体ではないとき
				bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			endif
		endif
		add.w	d6,BIOS_BUFFER_WIDTH.w	;幅を加える
		goto	putc_output_end
	endif
;----------------
;カーソルOFF
;	斜体のとき位置がずれるのでその前にカーソルを消す
	bsr	iocs_1F_B_CUROFF
;----------------
;フォントデータを作る
	movea.l	sp,a1			;フォントデータ
	moveq.l	#0,d0
	if	<tst.w d2>,eq		;8ドットデータのとき
		moveq.l	#16-1,d3
		for	d3
			move.b	(a0)+,(a1)+
			move.b	d0,(a1)+		;clr
			move.w	d0,(a1)+		;clr
		next
	else				;16ドットデータのとき
		moveq.l	#16-1,d3
		for	d3
			move.w	(a0)+,(a1)+
			move.w	d0,(a1)+		;clr
		next
	endif
;<(sp).l[16]:フォントデータ
;----------------
;太字
;	全体を右に1ドットずらしてORする
;	プロポーショナルのときは幅が1ドット増える
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
;>d6.w:ドット幅。1～17
	if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;太字のとき
		movea.l	sp,a1			;フォントデータ
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;プロポーショナルのとき
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;右に1ドットずらして
				or.l	d1,d0			;ORする
				move.l	d0,(a1)+
			next
			addq.w	#1,d6			;幅が1ドット増える
		else				;プロポーショナルではないとき
			moveq.l	#1,d2
			ror.l	d6,d2
			neg.l	d2
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;右に1ドットずらして
				or.l	d1,d0			;ORする
				and.l	d2,d0			;幅を増やさない
				move.l	d0,(a1)+
			next
		endif
	endif
;----------------
;細字
;	上下左右のいずれかが1で、メッシュが1のとき、1を0にする
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w>,ne	;細字のとき
		movea.l	sp,a1			;フォントデータ
		move.l	#$AAAAAAAA,d2
		moveq.l	#1,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
		rol.l	d0,d2
		moveq.l	#16-1,d3
		for	d3
			move.l	(a1),d0
			move.l	d0,d1
			lsr.l	#1,d1			;左
			lsl.l	#1,d0			;右
			or.l	d1,d0
			if	<cmpa.l sp,a1>,ne
				or.l	-4(a1),d0	;上
			endif
			if	<tst.w d3>,ne
				or.l	4(a1),d0	;下
			endif
			and.l	d2,d0			;メッシュ
			not.l	d0
			and.l	d0,(a1)+
			rol.l	#1,d2
		next
	endif
;----------------
;下線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;下線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*15(a1)
	endif
;----------------
;取り消し線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w>,ne	;取り消し線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*8(a1)
	endif
;----------------
;波線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;波線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d2
		ror.l	d6,d2
		neg.l	d2
		moveq.l	#3,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
  .if 0
		move.l	#$CCCCCCCC,d1
		rol.l	d0,d1
		move.l	d1,d0			;11001100
		not.l	d1			;00110011
		and.l	d2,d0
		and.l	d2,d1
		or.l	d0,4*14(a1)
		or.l	d1,4*15(a1)
  .else
		move.l	#$88888888,d1
		move.l	#$55555555,d3
		rol.l	d0,d1			;10001000
		rol.l	d0,d3			;01010101
		move.l	d1,d0
		rol.l	#2,d0			;00100010
		and.l	d2,d0
		and.l	d2,d1
		and.l	d2,d3
		or.l	d0,4*13(a1)
		or.l	d3,4*14(a1)
		or.l	d1,4*15(a1)
  .endif
	endif
;----------------
;四角囲み
	if	<btst.b #BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w>,ne	;四角囲みのとき
	;16x16の中央に寄せる
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16を12x12に縮小する
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16の中央に寄せる
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;四角を付ける
		movea.l	sp,a0
		or.l	#$FFFF0000,(a0)+
		moveq.l	#14-1,d3
		for	d3
			or.l	#$80010000,(a0)+
		next
		or.l	#$FFFF0000,(a0)+
	endif
;----------------
;丸囲み
	if	<btst.b #BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;丸囲みのとき
	;16x16の中央に寄せる
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16を12x12に縮小する
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16の中央に寄せる
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;丸を付ける
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tandi.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print($t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tori.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print(7**2<=$t&&$t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		ori.l	#%0000011111100000_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0000011111100000_0000000000000000,(a0)+
	endif
;----------------
;上線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;上線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*0(a1)
	endif
;----------------
;下付き
;	4x4の上2ドットと左2ドットをそれぞれORで1ドットにすることで、4x4を3x3に縮小する
;	SX-Windowと同じ方法
;	縦16ドットを12ドットに縮小し、下から1ドットの高さに配置する
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
;>d6.w:ドット幅。1～12
	if	<btst.b #BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;下付きのとき
		lea.l	subscript_pattern(pc),a2
		lea.l	4*16(sp),a0
		lea.l	4*15(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			subq.l	#8,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
		clr.l	4*2(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;上付き
;	4x4の上2ドットと左2ドットをそれぞれORで1ドットにすることで、4x4を3x3に縮小する
;	SX-Windowと同じ方法
;	縦16ドットを12ドットに縮小し、上から0ドットの高さに配置する
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
;>d6.w:ドット幅。1～12
	if	<btst.b #BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;上付きのとき
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;反転
;	全体を反転させる
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;反転のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		moveq.l	#16-1,d3
		for	d3
			eor.l	d0,(a1)+
		next
	endif
;----------------
;マスクデータを作る
;<d6.w:ドット幅。1～17
;>4*16(sp).l[16]:マスクデータ
	lea.l	4*16(sp),a1		;マスクデータ
	moveq.l	#1,d0
	ror.l	d6,d0
	neg.l	d0
	moveq.l	#16-1,d3
	for	d3
		move.l	d0,(a1)+
	next
;----------------
;斜体
;	全体を右に0～3ドットずらす
;	プロポーショナルのとき幅が3ドット増える
;	斜体を続けて描画するときカーソルが動かなかったら3ドット詰める
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
;<4*16(sp).l[16]:マスクデータ
;>d6.w:ドット幅。1～20
	if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;斜体のとき
		movea.l	sp,a0			;フォントデータ
		lea.l	4*16(sp),a1		;マスクデータ
*		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;プロポーショナルのとき
			moveq.l	#3,d3
			do
				moveq.l	#4-1,d2
				for	d2
					move.l	(a0),d0
					lsr.l	d3,d0
					move.l	d0,(a0)+
					move.l	(a1),d0
					lsr.l	d3,d0
					move.l	d0,(a1)+
				next
				subq.w	#1,d3
			while	ne
			addq.w	#3,d6			;幅が3ドット増える
			bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			if	ne			;連結のとき
				subq.b	#3,BIOS_CURSOR_FRACTION.w	;3ドット詰める
				if	cs
					addq.b	#8,BIOS_CURSOR_FRACTION.w
					subq.w	#1,BIOS_CURSOR_COLUMN.w
					if	cs
						clr.w	BIOS_CURSOR_COLUMN.w	;念の為
						clr.b	BIOS_CURSOR_FRACTION.w
					endif
				endif
			endif
*		else				;プロポーショナルではないとき
*			moveq.l	#1,d4
*			ror.l	d6,d4
*			neg.l	d4
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a1)+
*			next
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a1)+
*			next
*			lea.l	4*4(a0),a0
*			lea.l	4*4(a1),a1
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsl.l	#1,d0
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsl.l	#1,d0
*				move.l	d0,(a1)+
*			next
*		endif
	else				;斜体ではないとき
		bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
	endif
;----------------
;現在の行に入り切らなければ改行する
;<d6.w:ドット幅
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	move.w	BIOS_CURSOR_COLUMN.w,d1
	lsl.w	#3,d1
	add.b	BIOS_CURSOR_FRACTION.w,d1	;カーソルのXドット座標
	sub.w	d1,d0			;コンソールのドット幅-カーソルのXドット座標=残りドット幅
	if	le			;残りドット幅<=0。既にはみ出している
	;改行する
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	elif	<cmp.w d6,d0>,lt	;残りドット幅<ドット幅。入り切らない
	;残りを空白で埋める
		move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
		moveq.l	#7,d4
		and.b	BIOS_CURSOR_FRACTION.w,d4	;左端の桁座標の端数
		moveq.l	#7,d5			;右端の桁座標の端数
		bsr	putc_clear		;消去する
		;改行する
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;----------------
;文字を描く
;<d6.w:ドット幅
;<(sp).l[16]:フォントデータ
;<4*16(sp).l[16]:マスクデータ
	move.w	BIOS_CURSOR_ROW.w,d0	;行座標
	move.w	BIOS_CURSOR_COLUMN.w,d1	;桁座標
	moveq.l	#7,d2
	and.b	BIOS_CURSOR_FRACTION.w,d2	;桁座標の端数
	move.w	d6,d3			;ドット幅
	moveq.l	#3,d4
	and.b	BIOS_ATTRIBUTE_1.w,d4	;プレーン
	movea.l	sp,a0			;フォントデータ
	lea.l	4*16(sp),a1		;マスクデータ
	bsr	putc_draw		;文字を描く
;----------------
;カーソルを進める
;<d6.w:ドット幅
	add.b	BIOS_CURSOR_FRACTION.w,d6	;カーソルの桁座標の端数+ドット幅
	moveq.l	#7,d0
	and.w	d6,d0
	move.b	d0,BIOS_CURSOR_FRACTION.w	;カーソルの桁座標の端数
	lsr.w	#3,d6
	add.w	d6,BIOS_CURSOR_COLUMN.w	;カーソルの桁座標。ちょうど右端になる場合があるがここでは改行しない
;----------------
;カーソルON
	bsr	iocs_1E_B_CURON
;----------------
putc_output_end:
	lea.l	4*16+4*16(sp),sp	;フォントデータとマスクデータ
	pop
	rts

;----------------------------------------------------------------
;下付きで使うパターン
;	□□■□■■□■
subscript_pattern:
  .irp ff,%00000000,%10000000,%10000000,%10000000
    .irp ee,%00000000,%01000000
      .irp dd,%00000000,%00100000
        .irp cc,%00000000,%00010000,%00010000,%00010000
          .irp bb,%00000000,%00001000
            .irp aa,%00000000,%00000100
	.dc.b	ff+ee+dd+cc+bb+aa
            .endm
          .endm
        .endm
      .endm
    .endm
  .endm

;----------------------------------------------------------------
;文字を描く
;<d0.l:行座標
;<d1.l:桁座標
;<d2.l:桁座標の端数
;<d3.l:ドット幅
;<d4.l:プレーン。文字属性1の下位2ビット
;<(a0).l[16]:フォントデータ。左寄せ。リバースを含めて加工済み
;<(a1).l[16]:マスクデータ。左寄せ。書き込むビットが1
putc_draw:
	push	d0-d5/a0-a4
;----------------
;アドレスを求める
	swap.w	d0
	clr.w	d0			;65536*行座標
	lsr.l	#5,d0			;128*16*行座標
	add.w	d1,d0			;128*16*行座標+桁座標
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;描き始めるアドレスのオフセット
	add.l	#$00E00000,d0		;描き始めるアドレス
	bclr.l	#0,d0			;偶数にする
	if	ne
		addq.w	#8,d2
	endif
;<d2.w:桁座標の端数。0～15
	movea.l	d0,a4
;<a4.l:描き始めるアドレス。偶数
;?d0-d1
;----------------
	add.w	d2,d3			;桁座標の端数+ドット幅
;<d3.w:桁座標の端数+ドット幅
;----------------
;1ワードに収まるか、2ワードに跨るか、3ワードに跨るか
	if	<cmp.w #16,d3>,ls
	;----------------
	;1ワードに収まるとき
		do				;プレーンのループ
			lsr.b	#1,d4
			if	cs			;プレーンに描画するとき
				movea.l	a0,a2			;フォントデータ
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.w	(a2)+,d0		;フォント
					move.w	(a3)+,d1		;マスク
					lsr.w	d2,d0
					lsr.w	d2,d1
					not.w	d1
					and.w	(a4),d1			;くり抜いて
					or.w	d1,d0			;合わせて
					move.w	d0,(a4)+		;書き込む
					addq.l	#4-2,a2
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;次のラスタ
				next
			else				;プレーンを消去するとき
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.w	(a3)+,d1		;マスク
					lsr.w	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;くり抜く
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;次のラスタ
				next
			endif
			adda.l	#-128*16+128*1024,a4	;次のプレーン
		while	<cmpa.l #$00E40000,a4>,lo
	elif	<cmp.w #32,d3>,ls
	;----------------
	;2ワードに跨るとき
		do				;プレーンのループ
			lsr.b	#1,d4
			if	cs			;プレーンに描画するとき
				movea.l	a0,a2			;フォントデータ
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a2)+,d0		;フォント
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;くり抜いて
					or.l	d1,d0			;合わせて
					move.l	d0,(a4)+		;書き込む
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;次のラスタ
				next
			else				;プレーンを消去するとき
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;くり抜く
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;次のラスタ
				next
			endif
			adda.l	#-128*16+128*1024,a4	;次のプレーン
		while	<cmpa.l #$00E40000,a4>,lo
	else
	;----------------
	;3ワードに跨るとき
		do				;プレーンのループ
			lsr.b	#1,d4
			if	cs			;プレーンに描画するとき
				movea.l	a0,a2			;フォントデータ
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a2)+,d0		;フォント
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;くり抜いて
					or.l	d1,d0			;合わせて
					move.l	d0,(a4)+		;書き込む
					move.w	-2(a2),d0		;フォント
					move.w	-2(a3),d1		;マスク
					swap.w	d0
					swap.w	d1
					clr.w	d0
					clr.w	d1
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.w	d1
					and.w	(a4),d1			;くり抜いて
					or.w	d1,d0			;合わせて
					move.w	d0,(a4)+		;書き込む
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;次のラスタ
				next
			else				;プレーンを消去するとき
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;くり抜く
					move.w	-2(a3),d1		;マスク
					swap.w	d1
					clr.w	d1
					lsr.l	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;くり抜く
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;次のラスタ
				next
			endif
			adda.l	#-128*16+128*1024,a4	;次のプレーン
		while	<cmpa.l #$00E40000,a4>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;行をコピーする
;	  ┌─────┐  ┌─────┐
;	  │          │┌├─────┤
;	  ├─────┤┘│    ↓    │d2
;	d0│    ↓    │  │    ↓    │
;	  │    ↓    │  │    ↓    │
;	d1│    ↓    │┌├─────┤
;	  ├─────┤┘│          │
;	  └─────┘  └─────┘
;	  ┌─────┐  ┌─────┐
;	  ├─────┤┐│          │
;	d0│    ↑    │└├─────┤
;	  │    ↑    │  │    ↑    │d2
;	d1│    ↑    │  │    ↑    │
;	  ├─────┤┐│    ↑    │
;	  │          │└├─────┤
;	  └─────┘  └─────┘
;<d0.w:コピー元の上端の行座標
;<d1.w:コピー元の下端の行座標
;<d2.w:コピー先の上端の行座標
putc_copy_rows:
	push	d0-d3/a0
	move.l	BIOS_CONSOLE_OFFSET.w,d3	;コンソールの左上のアドレスのオフセット
	lsr.l	#7,d3			;コンソールの上端のYドット座標
	lsr.w	#2,d3			;コンソールの上端のラスタブロック番号
	sub.w	d0,d1			;コピー元の下端の行座標-コピー元の上端の行座標=コピーする行数-1
	lsl.w	#2,d1			;コピーするラスタブロック数-4
	addq.w	#3,d1			;コピーするラスタブロック数-1
;<d1.w:コピーするラスタブロック数-1
	lsl.w	#2,d0
	add.w	d3,d0			;コピー元の上端のラスタブロック番号
;<d0.w:コピー元の上端のラスタブロック番号
	lsl.w	#2,d2
	add.w	d3,d2			;コピー先の上端のラスタブロック番号
;<d2.w:コピー先の上端のラスタブロック番号
	if	<cmp.w d0,d2>,ls	;上にずらすとき
		move.w	#$0101,d3		;ラスタブロック番号の増分
	else				;下にずらすとき
		add.w	d1,d0			;コピー元の下端のラスタブロック番号
		add.w	d1,d2			;コピー先の下端のラスタブロック番号
		move.w	#$FEFF,d3		;ラスタブロック番号の増分
	endif
;<d0.w:コピー元のラスタブロック番号
;<d2.w:コピー先のラスタブロック番号
;<d3.w:ラスタブロック番号の増分
	lsl.w	#8,d0			;コピー元のラスタブロック番号<<8
	move.b	d2,d0			;コピー元のラスタブロック番号<<8|コピー先のラスタブロック番号
;<d0.w:コピー元のラスタブロック番号<<8|コピー先のラスタブロック番号
aGPDR	reg	a0
	lea.l	MFP_GPDR,aGPDR		;GPIPデータレジスタ。HSYNC|RINT|-|VDISP|OPMIRQ|POWER|EXPWON|ALARM
	move.w	sr,d2
	for	d1			;ラスタブロックのループ
		do
		while	<tst.b (aGPDR)>,mi	;水平表示期間を待つ
		ori.w	#$0700,sr		;割り込みを禁止する
		do
		while	<tst.b (aGPDR)>,pl	;水平帰線期間を待つ
		move.w	d0,CRTC_BLOCK-MFP_GPDR(aGPDR)	;ラスタブロック番号を設定する
		move.w	#$0008,CRTC_ACTION-MFP_GPDR(aGPDR)	;ラスタコピーをONにする。2回目以降は不要
		move.w	d2,sr			;割り込みを許可する
		add.w	d3,d0			;次のラスタブロックへ
	next
	do
	while	<tst.b (aGPDR)>,mi	;水平表示期間を待つ
	ori.w	#$0700,sr		;割り込みを禁止する
	do
	while	<tst.b (aGPDR)>,pl	;水平帰線期間を待つ
	move.w	d2,sr			;割り込みを許可する
	clr.w	CRTC_ACTION-MFP_GPDR(aGPDR)	;ラスタコピーをOFFにする。必要
	pop
	rts

;----------------------------------------------------------------
;行を消去する
;<d0.w:上端の行座標
;<d1.w:下端の行座標
putc_clear_rows:
	push	d2-d5
	moveq.l	#0,d2			;左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;消去する
;	消去は空白の描画と同じ。背景色で塗り潰す
;		文字属性		文字色	背景色
;		0			黒	黒
;		1			水色	黒
;		2			黄色	黒
;		3			白	黒
;		4		太字	黒	黒
;		5		太字	水色	黒
;		6		太字	黄色	黒
;		7		太字	白	黒
;		8	反転		黒	黒
;		9	反転		黒	水色
;		10	反転		黒	黄色
;		11	反転		黒	白
;		12	反転	太字	黒	黒
;		13	反転	太字	黒	水色
;		14	反転	太字	黒	黄色
;		15	反転	太字	黒	白
;<d0.w:上端の行座標
;<d1.w:下端の行座標
;<d2.w:左端の桁座標
;<d3.w:右端の桁座標
;<d4.w:左端の桁座標の端数。0～7。これを含む
;<d5.w:右端の桁座標の端数。0～7。これを含む
putc_clear:
	push	d0-d7/a0-a3
;----------------
;ラスタ数を求める
	sub.w	d0,d1			;下端の行座標-上端の行座標=行数-1
	addq.w	#1,d1			;行数
	lsl.w	#4,d1			;16*行数=ラスタ数
	subq.w	#1,d1			;ラスタ数-1
	movea.w	d1,a3
;<a3.w:ラスタ数-1
;?d1
;----------------
;アドレスを求める
	swap.w	d0
	clr.w	d0			;65536*行座標
	lsr.l	#5,d0			;128*16*行座標
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;上端の行の左上のアドレスのオフセット
	add.l	#$00E00000,d0		;上端の行の左上のアドレス
	ext.l	d2
	ext.l	d3
	add.l	d0,d2			;左上のアドレス
	add.l	d0,d3			;右上のアドレス
;<d2.l:左上のアドレス
;<d3.l:右上のアドレス
;?d0
;----------------
;アドレスを偶数にする
;	桁座標ではなくアドレスを偶数にする
;	_B_CONSOLはコンソールの左端のアドレスを偶数に制限していない
	bclr.l	#0,d2
	if	ne
		addq.w	#8,d4
	endif
;<d2.l:左上のアドレス。偶数
;<d4.w:左端の桁座標の端数。0～15
	bclr.l	#0,d3
	if	ne
		addq.w	#8,d5
	endif
;<d3.l:右上のアドレス。偶数
;<d5.w:右端の桁座標の端数。0～15
	movea.l	d2,a2
;<a2.l:左上のアドレス。偶数
;----------------
;ワード数を求める
	sub.w	d2,d3			;右端のアドレス-左端のアドレス=2*(ワード数-1)
	lsr.w	#1,d3			;ワード数-1
;<d3.w:ワード数-1
;?d2
;----------------
;マスクを作る
	moveq.l	#-1,d6
	move.w	#$8000,d7
	lsr.w	d4,d6			;左端の書き込む部分が1のマスク。$FFFF,$7FFF,…,$0003,$0001
	asr.w	d5,d7			;右端の書き込む部分が1のマスク。$8000,$C000,…,$FFFE,$FFFF
;<d6.w:左端の書き込む部分が1のマスク。$FFFF,$7FFF,…,$0003,$0001
;<d7.w:右端の書き込む部分が1のマスク。$8000,$C000,…,$FFFE,$FFFF
;?d4-d5
;----------------
;データを作る
	moveq.l	#%1111,d0
	and.b	BIOS_ATTRIBUTE_1.w,d0	;プレーン##
;		  111111
;		  5432109876543210
	move.w	#%1100110000000000,d2	;背景色が黄色または白。プレーン1を塗り潰す
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
	swap.w	d2
;		  111111
;		  5432109876543210
	move.w	#%1010101000000000,d2	;背景色が水色または白。プレーン0を塗り潰す
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
;<d2.l:プレーン1のデータ<<16|プレーン0のデータ
;----------------
;1ワードか1ワードではないか
	if	<tst.w d3>,eq
	;----------------
	;1ワードのとき
		and.w	d7,d6
	;<d6.w:書き込む部分が1のマスク
		and.w	d6,d2
		swap.w	d2
		and.w	d6,d2
		swap.w	d2
	;<d2.l:プレーン1のデータ<<16|プレーン0のデータ
		not.w	d6
	;<d6.w:書き込まない部分が1のマスク
		do				;プレーンのループ
			movea.l	a2,a0			;左上のアドレス→左端のアドレス
			move.w	a3,d1			;ラスタ数-1
			for	d1			;ラスタのループ
				move.w	(a0),d0
				and.w	d6,d0			;マスク
				or.w	d2,d0			;データ
				move.w	d0,(a0)
				lea.l	128(a0),a0		;次の左端のアドレス
			next
			swap.w	d2			;次のプレーンのデータ
			adda.l	#128*1024,a2		;次のプレーンの左上のアドレス
		while	<cmpa.l #$00E40000,a2>,lo
	else
	;----------------
	;1ワードではないとき
		subq.w	#1,d3
	;<d3.w:左端と右端の間のワード数。0～
		move.l	d2,d4
		move.l	d2,d5
	;<d4.l:プレーン1のデータ<<16|プレーン0のデータ
	;<d5.l:プレーン1のデータ<<16|プレーン0のデータ
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
	;<d4.l:プレーン1の左端のデータ<<16|プレーン0の左端のデータ
	;<d5.l:プレーン1の右端のデータ<<16|プレーン0の右端のデータ
		not.w	d6
		not.w	d7
	;<d6.w:左端の書き込まない部分が1のマスク。$0000,$8000,…,$FFFC,$FFFE
	;<d7.w:右端の書き込まない部分が1のマスク。$7FFF,$3FFF,…,$0001,$0000
		do				;プレーンのループ
			movea.l	a2,a1			;左上のアドレス→左端のアドレス
			move.w	a3,d1			;ラスタ数-1
			for	d1			;ラスタのループ
				movea.l	a1,a0			;左端のアドレス→桁のアドレス
			;左端
				move.w	(a0),d0
				and.w	d6,d0			;左端のマスク
				or.w	d4,d0			;左端のデータ
				move.w	d0,(a0)+
			;左端と右端の間
				move.w	d3,d0			;左端と右端の間のワード数。0～
				forcontinue	d0
					move.w	d2,(a0)+		;データ
				next
			;右端
				move.w	(a0),d0
				and.w	d7,d0			;右端のマスク
				or.w	d5,d0			;右端のデータ
				move.w	d0,(a0)+
				lea.l	128(a1),a1		;次の左端のアドレス
			next
			swap.w	d2			;次のプレーンのデータ
			swap.w	d4			;次のプレーンの左端のデータ
			swap.w	d5			;次のプレーンの右端のデータ
			adda.l	#128*1024,a2		;次のプレーンの左上のアドレス
		while	<cmpa.l #$00E40000,a2>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;プロポーショナルフォント($20～$82)
proportional_font:
	.dc.w	6	;$20   
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$21 ！
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$22 ”
	.dc.w	%0000000000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0010001000000000
	.dc.w	%0010001000000000
	.dc.w	%0100010000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$23 ＃
	.dc.w	%0000000000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0111111100000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%1111111000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$24 ＄
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%1001001000000000
	.dc.w	%1101000000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%0001011000000000
	.dc.w	%1001001000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$25 ％
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001000010000000
	.dc.w	%1001000100000000
	.dc.w	%1001001000000000
	.dc.w	%0110010000000000
	.dc.w	%0000100000000000
	.dc.w	%0001001100000000
	.dc.w	%0010010010000000
	.dc.w	%0100010010000000
	.dc.w	%1000010010000000
	.dc.w	%0000001100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$26 ＆
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%0101000000000000
	.dc.w	%0011000000000000
	.dc.w	%0100100100000000
	.dc.w	%1000010100000000
	.dc.w	%1000001000000000
	.dc.w	%1000010100000000
	.dc.w	%0111100010000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$27 ’
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$28 （
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$29 ）
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2A ＊
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%1001001000000000
	.dc.w	%0101010000000000
	.dc.w	%0011100000000000
	.dc.w	%0101010000000000
	.dc.w	%1001001000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2B ＋
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%1111111000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$2C ，
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2D －
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2E ．
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2F ／
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$30 ０
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$31 １
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001100000000000
	.dc.w	%0011100000000000
	.dc.w	%0111100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$32 ２
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100000000000000
	.dc.w	%1111111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$33 ３
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0001110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$34 ４
	.dc.w	%0000000000000000
	.dc.w	%0000001000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111000000000
	.dc.w	%0001111000000000
	.dc.w	%0011011000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1111111100000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$35 ５
	.dc.w	%0000000000000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$36 ６
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%1110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$37 ７
	.dc.w	%0000000000000000
	.dc.w	%1111111100000000
	.dc.w	%1100001100000000
	.dc.w	%1100011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$38 ８
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$39 ９
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011111000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3A ：
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3B ；
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3C ＜
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3D ＝
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3E ＞
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3F ？
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$40 ＠
	.dc.w	%0000000000000000
	.dc.w	%0001111100000000
	.dc.w	%0010000010000000
	.dc.w	%0100000001000000
	.dc.w	%1000111001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001110110000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0011111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$41 Ａ
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0010001100000000
	.dc.w	%0010001100000000
	.dc.w	%0011111100000000
	.dc.w	%0100000110000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$42 Ｂ
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$43 Ｃ
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$44 Ｄ
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$45 Ｅ
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$46 Ｆ
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$47 Ｇ
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100001111000000
	.dc.w	%1100000010000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$48 Ｈ
	.dc.w	%0000000000000000
	.dc.w	%1111001111000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%1111001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$49 Ｉ
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$4A Ｊ
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%1100110000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4B Ｋ
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111110000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4C Ｌ
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	13	;$4D Ｍ
	.dc.w	%0000000000000000
	.dc.w	%1110000001110000
	.dc.w	%0110000001100000
	.dc.w	%0111000001100000
	.dc.w	%0111000011100000
	.dc.w	%0111100011100000
	.dc.w	%0101100101100000
	.dc.w	%0101110101100000
	.dc.w	%0100111001100000
	.dc.w	%0100111001100000
	.dc.w	%0100010001100000
	.dc.w	%1110010011110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	12	;$4E Ｎ
	.dc.w	%0000000000000000
	.dc.w	%1100000011100000
	.dc.w	%0110000001000000
	.dc.w	%0111000001000000
	.dc.w	%0111100001000000
	.dc.w	%0101110001000000
	.dc.w	%0100111001000000
	.dc.w	%0100011101000000
	.dc.w	%0100001111000000
	.dc.w	%0100000111000000
	.dc.w	%0100000011000000
	.dc.w	%1110000001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$4F Ｏ
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%0110000110000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$50 Ｐ
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$51 Ｑ
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1101110011000000
	.dc.w	%1111011110000000
	.dc.w	%0110001100000000
	.dc.w	%0001111100000000
	.dc.w	%0000000110000000
	.dc.w	%0000000011000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$52 Ｒ
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110111000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001110000000
	.dc.w	%1111000111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$53 Ｓ
	.dc.w	%0000000000000000
	.dc.w	%0001110100000000
	.dc.w	%0110001100000000
	.dc.w	%1100000100000000
	.dc.w	%1110000000000000
	.dc.w	%0111000000000000
	.dc.w	%0011110000000000
	.dc.w	%0000111000000000
	.dc.w	%0000011100000000
	.dc.w	%1000001100000000
	.dc.w	%1100011000000000
	.dc.w	%1011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$54 Ｔ
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100110011000000
	.dc.w	%1000110001000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0011111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$55 Ｕ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0000111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$56 Ｖ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	16	;$57 Ｗ
	.dc.w	%0000000000000000
	.dc.w	%1111000110001110
	.dc.w	%0110000110000100
	.dc.w	%0011000111000100
	.dc.w	%0011000111000100
	.dc.w	%0011001011001000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$58 Ｘ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000111000000000
	.dc.w	%0001001100000000
	.dc.w	%0010001100000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$59 Ｙ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$5A Ｚ
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100000011000000
	.dc.w	%1000000110000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000001000000
	.dc.w	%1100000011000000
	.dc.w	%1111111111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5B ［
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5C ￥
	.dc.w	%0000000000000000
	.dc.w	%1000001000000000
	.dc.w	%1000001000000000
	.dc.w	%0100010000000000
	.dc.w	%0100010000000000
	.dc.w	%0010100000000000
	.dc.w	%0010100000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5D ］
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5E ＾
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010100000000000
	.dc.w	%0100010000000000
	.dc.w	%1000001000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5F ＿
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$60 ｀
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$61 ａ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110000000000
	.dc.w	%1100111000000000
	.dc.w	%0000011000000000
	.dc.w	%0011111000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100111000000000
	.dc.w	%0111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$62 ｂ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111001100000000
	.dc.w	%1101111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$63 ｃ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$64 ｄ
	.dc.w	%0000000000000000
	.dc.w	%0000011100000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%0011101100000000
	.dc.w	%0110011100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011101110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$65 ｅ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$66 ｆ
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$67 ｇ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110100000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%0111110000000000
	.dc.w	%1100000000000000
	.dc.w	%0111111000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$68 ｈ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$69 ｉ
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$6A ｊ
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%1101100000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6B ｋ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111000000000000
	.dc.w	%0111100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110011000000000
	.dc.w	%1111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$6C ｌ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	15	;$6D ｍ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1101111011110000
	.dc.w	%0111011110111000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%1111011110111100
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$6E ｎ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6F ｏ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$70 ｐ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0111011100000000
	.dc.w	%0110111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$71 ｑ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111011100000000
	.dc.w	%1110111000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111100000000
	.dc.w	%0000000000000000
	.dc.w	9	;$72 ｒ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$73 ｓ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111101000000000
	.dc.w	%1100011000000000
	.dc.w	%1100001000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%1000011000000000
	.dc.w	%1100011000000000
	.dc.w	%1011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$74 ｔ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110110000000000
	.dc.w	%0011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$75 ｕ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011110110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$76 ｖ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0011010000000000
	.dc.w	%0011100000000000
	.dc.w	%0011100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	14	;$77 ｗ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001000111000
	.dc.w	%0110001100010000
	.dc.w	%0110001100010000
	.dc.w	%0011010110100000
	.dc.w	%0011010110100000
	.dc.w	%0001110011100000
	.dc.w	%0001100011000000
	.dc.w	%0000100001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$78 ｘ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0011010000000000
	.dc.w	%0001100000000000
	.dc.w	%0001110000000000
	.dc.w	%0010011000000000
	.dc.w	%0100001100000000
	.dc.w	%1110011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$79 ｙ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110000100000000
	.dc.w	%0011001000000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0001110000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7A ｚ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%1000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7B ｛
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7C ｜
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7D ｝
	.dc.w	%0000000000000000
	.dc.w	%1100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%1100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7E ￣
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7F DL
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$80 ＼
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$81 ～
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001001000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$82 ￤
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000



;----------------------------------------------------------------
;デバイスドライバの末尾
device_tail:

;----------------------------------------------------------------
;デバイスコマンド0 初期化
initialize:

;パラメータを確認する
	movea.l	18(a5),a0		;パラメータ。区切りは0、末尾は0,0。先頭はデバイスファイル名
	do
	while	<tst.b (a0)+>,ne	;デバイスファイル名を読み飛ばす
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,parameter_error	;-,/以外
		move.b	(a0)+,d0
		goto	eq,parameter_error	;-,/の後に文字がない
		st.b	option_flag		;オプションあり
		bsr	tolower
		if	<cmp.b #'f',d0>,eq	;-f
			st.b	fixed_flag
			sf.b	proportional_flag
		elif	<cmp.b #'p',d0>,eq	;-p
			sf.b	fixed_flag
			st.b	proportional_flag
		elif	<cmp.b #'q',d0>,eq	;-q
			st.b	quiet_flag
			sf.b	verbose_flag
		elif	<cmp.b #'s',d0>,eq	;-s
			st.b	sample_flag
		elif	<cmp.b #'v',d0>,eq	;-v
			sf.b	quiet_flag
			st.b	verbose_flag
		else
			goto	parameter_error
		endif
		tst.b	(a0)+			;区切り
		goto	ne,parameter_error	;余分な文字がある
	start
		move.b	(a0)+,d0
	while	ne

;ワークエリアを初期化する
	bsr	initialize_workarea	;ワークエリアを初期化する

;ベクタを変更する
	IOCS	_OS_CUROF
	lea.l	vector_table(pc),a0	;ベクタテーブル
	bsr	set_vector		;ベクタを変更する
	IOCS	_OS_CURON

;固定ピッチまたはプロポーショナルピッチを設定する
	if	<tst.b fixed_flag>,ne	;固定ピッチ
		bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
	elif	<tst.b proportional_flag>,ne	;プロポーショナルピッチ
		bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
	endif

;改行とタイトルを表示する
	if	<tst.b quiet_flag>,eq
		lea.l	crlf_title(pc),a0
		bsr	print
	endif

;サンプルを表示する
	if	<tst.b sample_flag>,ne
		lea.l	sample(pc),a0
		bsr	print
	endif

;デバイスドライバの末尾を設定する
	move.l	#device_tail,14(a5)	;デバイスドライバの末尾

;デバイスドライバを組み込む
	moveq.l	#0,d0
	rts

;パラメータエラー
parameter_error:

;改行とタイトルとエラーメッセージを表示する
	lea.l	crlf_title(pc),a0
	bsr	print
	lea.l	parameter_message(pc),a0
	bsr	print

;デバイスドライバを組み込まない
	move.w	#ABORT|MISCELLANEOUS_ERROR,d0	;中止(A) エラーが発生しました
	rts

;----------------------------------------------------------------
;実行開始
execution_start:

;オプションを確認する
	lea.l	1(a2),a0		;コマンドライン
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;-,/以外
		addq.l	#1,a0
		move.b	(a0)+,d0
		goto	eq,usage_exit		;-,/の後に文字がない
		st.b	option_flag		;オプションあり
		bsr	tolower
		if	<cmp.b #'f',d0>,eq	;-f
			st.b	fixed_flag
			sf.b	proportional_flag
		elif	<cmp.b #'k',d0>,eq	;-k
			st.b	keeppr_flag
			sf.b	release_flag
		elif	<cmp.b #'p',d0>,eq	;-p
			sf.b	fixed_flag
			st.b	proportional_flag
		elif	<cmp.b #'q',d0>,eq	;-q
			st.b	quiet_flag
			sf.b	verbose_flag
		elif	<cmp.b #'r',d0>,eq	;-r
			sf.b	keeppr_flag
			st.b	release_flag
		elif	<cmp.b #'s',d0>,eq	;-s
			st.b	sample_flag
		elif	<cmp.b #'v',d0>,eq	;-v
			sf.b	quiet_flag
			st.b	verbose_flag
		else
			goto	usage_exit
		endif
		move.b	(a0),d0
		break	eq
		bsr	isspace
		goto	ne,usage_exit		;余分な文字がある
	start
		bsr	nonspace
	while	ne
	goto	<tst.b option_flag>,eq,usage_exit	;オプションなし

;スーパーバイザモードへ移行する
	supervisormode

;----------------------------------------------------------------
;デバイスドライバを探す
	movea.l	DOS_HUMAN_MEMORY.w,a2	;Human68kの先頭
	do
		addq.l	#2,a2
	whileor	<cmpi.l #'NUL ',DH_NAME(a2)>,ne,<cmpi.l #'    ',DH_NAME+4(a2)>,ne,<cmpi.w #$8024,DH_TYPE(a2)>,ne	;NULデバイスドライバを探す。必ずある
;<a2.l:NULデバイスドライバの先頭
	dostart
		lea.l	magic-program_head(a2),a0	;常駐部分のマジック
		lea.l	magic(pc),a1		;自分のマジック
		gotoand	<cmpm.l (a0)+,(a1)+>,eq,<cmpm.l (a0)+,(a1)+>,eq,device_found	;一致したら終了
	start
		movea.l	a2,a3			;デバイスドライバ→直前のデバイスドライバ
		movea.l	DH_NEXT(a2),a2		;次のデバイスドライバ
	while	<cmpa.l #-1,a2>,ne
	suba.l	a2,a2
device_found:
;<a2.l:デバイスドライバの先頭,0=デバイスドライバがない
;<a3.l:(デバイスドライバがあるとき)直前のデバイスドライバ,(デバイスドライバがないとき)最後のデバイスドライバ

;----------------------------------------------------------------
;常駐プログラムを探す
	lea.l	program_head(pc),a4	;自分の先頭
	dostart
		movea.l	d0,a4
		lea.l	MM_PROGRAM(a4),a4	;常駐部分の先頭
		lea.l	magic+8-program_head(a4),a0	;常駐部分のマジックの末尾
		if	<cmpa.l MM_TAIL-MM_PROGRAM(a4),a0>,ls	;メモリブロックの長さを確認する
			lea.l	magic-program_head(a4),a0	;常駐部分のマジック
			lea.l	magic(pc),a1		;自分のマジック
			gotoand	<cmpm.l (a0)+,(a1)+>,eq,<cmpm.l (a0)+,(a1)+>,eq,keeppr_found	;一致したら終了
		endif
	start
		move.l	MM_PREV-MM_PROGRAM(a4),d0	;直前のメモリ管理テーブル
	while	ne
	lea.l	program_head(pc),a4	;自分の先頭
	dostart
		movea.l	d0,a4
		lea.l	MM_PROGRAM(a4),a4	;常駐部分の先頭
		lea.l	magic+8-program_head(a4),a0	;常駐部分のマジックの末尾
		if	<cmpa.l MM_TAIL-MM_PROGRAM(a4),a0>,ls	;メモリブロックの長さを確認する
			lea.l	magic-program_head(a4),a0	;常駐部分のマジック
			lea.l	magic(pc),a1		;自分のマジック
			gotoand	<cmpm.l (a0)+,(a1)+>,eq,<cmpm.l (a0)+,(a1)+>,eq,keeppr_found	;一致したら終了
		endif
	start
		move.l MM_NEXT-MM_PROGRAM(a4),d0	;直後のメモリ管理テーブル
	while	ne
	suba.l	a4,a4
keeppr_found:
;<a4.l:常駐プログラムの先頭,0=常駐プログラムがない

;----------------------------------------------------------------
	move.l	a2,d0			;デバイスドライバの先頭
	if 	eq			;デバイスドライバがない

	;----------------------------------------------------------------
	;常駐していない

		if	<tst.b keeppr_flag>,eq	;常駐しない

		;ユーザモードへ復帰する
			usermode

		;タイトルとメッセージを表示する
			if	<tst.b quiet_flag>,eq
				lea.l	title(pc),a0
				bsr	print
			endif
			lea.l	not_installed_message(pc),a0
			bsr	eprint

		;エラー終了する
			move.w	#1,-(sp)
			DOS	_EXIT2

		endif

	;----------------------------------------------------------------
	;常駐する

	;ワークエリアを初期化する
		bsr	initialize_workarea	;ワークエリアを初期化する

	;固定ピッチまたはプロポーショナルピッチを設定する
		if	<tst.b fixed_flag>,ne	;固定ピッチ
			bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		elif	<tst.b proportional_flag>,ne	;プロポーショナルピッチ
			bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		endif

	;ベクタを変更する
		IOCS	_OS_CUROF
		lea.l	vector_table(pc),a0	;ベクタテーブル
		bsr	set_vector		;ベクタを変更する
		IOCS	_OS_CURON

	;デバイスドライバを接続する
		move.l	#program_head,(a3)	;最後のデバイスドライバの次のデバイスドライバを自分にする
		bsr	reset_con_device	;標準入出力に現在のCONデバイスを接続し直す

	;ユーザモードへ復帰する
		usermode

	;タイトルとメッセージを表示する
		if	<tst.b quiet_flag>,eq
			lea.l	title(pc),a0
			bsr	print
			lea.l	install_message(pc),a0
			bsr	print
		endif

	;サンプルを表示する
		if	<tst.b sample_flag>,ne
			lea.l	sample(pc),a0
			bsr	print
		endif

	;常駐終了する
		clr.w	-(sp)
		move.l	#device_tail-program_head,-(sp)
		DOS	_KEEPPR

	else				;デバイスドライバがある

	;----------------------------------------------------------------
	;常駐している

		if	<tst.b keeppr_flag>,ne	;常駐する

		;ユーザモードへ復帰する
			usermode

		;タイトルとメッセージを表示する
			if	<tst.b quiet_flag>,eq
				lea.l	title(pc),a0
				bsr	print
			endif
			lea.l	already_message(pc),a0
			bsr	eprint

		;エラー終了する
			move.w	#1,-(sp)
			DOS	_EXIT2

		endif

	;----------------------------------------------------------------
	;常駐しない

	;固定ピッチまたはプロポーショナルピッチを設定する
		if	<tst.b fixed_flag>,ne	;固定ピッチ
			bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		elif	<tst.b proportional_flag>,ne	;プロポーショナルピッチ
			bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		endif

	;サンプルを表示する
		if	<tst.b sample_flag>,ne
			lea.l	sample(pc),a0
			bsr	print
		endif

		if	<tst.b release_flag>,eq	;解除しない

		;ユーザモードへ復帰する
			usermode

		;正常終了する
			DOS	_EXIT

		endif

	;----------------------------------------------------------------
	;解除する

	;ベクタを確認する
		lea.l	(vector_table-program_head)(a2),a0	;常駐部分のベクタテーブル
		bsr	check_vector		;ベクタを確認する

		if	ne			;ベクタが変更されている

		;ユーザモードへ復帰する
			usermode

		;タイトルとメッセージを表示する
			if	<tst.b quiet_flag>,eq
				lea.l	title(pc),a0
				bsr	print
			endif
			lea.l	vector_message(pc),a0
			bsr	eprint

		;エラー終了する
			move.w	#1,-(sp)
			DOS	_EXIT2

		endif

	;ベクタが変更されていない

	;デバイスドライバを切り離す
		move.l	(a2),(a3)		;前のデバイスドライバに次のデバイスドライバを繋ぐ
		bsr	reset_con_device	;標準入出力に現在のCONデバイスを接続し直す

	;ベクタを復元する
		IOCS	_OS_CUROF
		lea.l	(vector_table-program_head)(a2),a0	;常駐部分のベクタテーブル
		bsr	release_vector		;ベクタを復元する
		IOCS	_OS_CURON

	;常駐プログラムを開放する
		move.l a4,d0			;常駐プログラムの先頭
		if	ne			;常駐プログラムがある

			;常駐プログラムを開放する
			pea.l	MM_SIZE-MM_PROGRAM(a4)	;常駐プログラムのメモリブロックの先頭
			DOS	_MFREE
			addq.l	#4,sp

		endif

	;ユーザモードへ復帰する
		usermode

	;タイトルとメッセージを表示する
		if	<tst.b quiet_flag>,eq
			lea.l	title(pc),a0
			bsr	print
			lea.l	release_message(pc),a0
			bsr	print
		endif

	;正常終了する
		DOS	_EXIT

	endif

;----------------------------------------------------------------
;使用法を表示する
usage_exit:
	if	<tst.b quiet_flag>,eq
		lea.l	title_usage(pc),a0
		bsr	more
	endif

;正常終了する
	DOS	_EXIT

;----------------------------------------------------------------
;ベクタを変更する
;<a0.l:ベクタテーブル
set_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;オフセット
		move.l	(a1),d0
		move.l	(a0)+,(a1)		;新しいベクタ
		move.l	d0,(a0)+		;古いベクタ
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;ベクタを確認する
;<a0.l:常駐部分のベクタテーブル
;>ccr:eq=ベクタは変更されていない,ne=ベクタが変更されている
check_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;オフセット
		move.l	(a1),d0
		break	<cmp.l (a0)+,d0>,ne	;新しいベクタが現在のベクタと一致しなければ失敗
		addq.l	#4,a0			;古いベクタを読み飛ばす
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;ベクタを復元する
;<a0.l:常駐部分のベクタテーブル
release_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;オフセット
		addq.l	#4,a0			;新しいベクタを読み飛ばす
		move.l	(a0)+,(a1)		;古いベクタ
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;標準入出力に現在のCONデバイスを接続し直す
reset_con_device:
	push	d0
	clr.w	-(sp)
	DOS	_CLOSE
	addq.w	#1,(sp)
	DOS	_CLOSE
	addq.w	#1,(sp)
	DOS	_CLOSE
	addq.l	#2,sp
	pop
	rts

;----------------------------------------------------------------
;ワークエリアを初期化する
initialize_workarea:
	push	d0-d1/a0
	moveq.l	#0,d0
	lea.l	$0D30.w,a0
	move.w	#($0DC0-$0D30)/4-1,d1
	for	d1
		move.l	d0,(a0)+
	next
	pop
	rts

;----------------------------------------------------------------
;メッセージ
parameter_message:	.dc.b	'指定できないパラメータです',13,10,0
not_installed_message:	.dc.b	'常駐していません',13,10,0
install_message:	.dc.b	'常駐しました',13,10,0
already_message:	.dc.b	'既に常駐しています',13,10,0
vector_message:		.dc.b	'ベクタが変更されています。解除できません',13,10,0
release_message:	.dc.b	'解除しました',13,10,0

;改行とタイトル
crlf_title:		.dc.b	13,10
;タイトル
title:			.dc.b	TITLE_STRING,' version ',VERSION_STRING,13,10,0

;タイトルと使用法
title_usage:		.dc.b	TITLE_STRING,' version ',VERSION_STRING,13,10
			.dc.b	13,10
			.dc.b	'オプション',13,10
			.dc.b	'  -f        固定ピッチに切り替える',13,10
			.dc.b	'  -k        常駐する',13,10
			.dc.b	'  -p        プロポーショナルピッチに切り替える',13,10
			.dc.b	'  -q        表示を減らす',13,10
			.dc.b	'  -r        解除する',13,10
			.dc.b	'  -s        サンプルを表示する',13,10
			.dc.b	'  -v        表示を増やす',13,10
			.dc.b	13,10
			.dc.b	'制御文字',13,10
			.dc.b	'  ^G        $07 BL ベルを鳴らす',13,10
			.dc.b	'  ^H        $08 BS カーソルを1桁左へ。左端では1行上の右端へ。上端では何もしない',13,10
			.dc.b	'  ^I        $09 HT カーソルを次のタブ桁へ。なければ1行下の左端へ。下端ではスクロールアップして左端へ',13,10
			.dc.b	'  ^J        $0A LF カーソルを1行下へ。下端ではスクロールアップ',13,10
			.dc.b	'  ^K        $0B VT カーソルを1行上へ。上端では何もしない',13,10
			.dc.b	'  ^L        $0C FF カーソルを1桁右へ。右端では1行下の左端へ。下端ではスクロールアップして左端へ',13,10
			.dc.b	'  ^M        $0D CR カーソルを左端へ',13,10
			.dc.b	'  ^Z        $1A SB 左上から右下まで消去。カーソルを左上へ',13,10
			.dc.b	'  ^[        $1B EC エスケープシーケンス開始',13,10
			.dc.b	'  ^^        $1E RS カーソルを左上へ',13,10
			.dc.b	13,10
			.dc.b	'エスケープシーケンス',13,10
			.dc.b	'  ^[*       左上から右下まで消去。カーソルを左上へ',13,10
			.dc.b	'  ^[=rc     カーソルをr-$20行,c-$20桁へ。rとcは文字',13,10
			.dc.b	'  ^[D       カーソルを1行下へ。下端ではスクロールアップ',13,10
			.dc.b	'  ^[E       カーソルを1行下の左端へ。下端ではスクロールアップ',13,10
			.dc.b	'  ^[M       カーソルを1行上へ。上端ではスクロールダウン',13,10
			.dc.b	'  ^[[>5l    カーソルON',13,10
			.dc.b	'  ^[[>5h    カーソルOFF',13,10
			.dc.b	'  ^[[?4l    ジャンプスクロール',13,10
			.dc.b	'  ^[[?4h    8ドットスムーススクロール',13,10
			.dc.b	'  ^[[n@     カーソルから右にn桁挿入',13,10
			.dc.b	'  ^[[nA     カーソルをn行上へ。上端を超えるときは動かない',13,10
			.dc.b	'  ^[[nB     カーソルをn行下へ。下端で止まる',13,10
			.dc.b	'  ^[[nC     カーソルをn桁右へ。右端で止まる',13,10
			.dc.b	'  ^[[nD     カーソルをn桁左へ。左端で止まる',13,10
			.dc.b	'  ^[[r;cH   カーソルをr-1行,c-1桁へ。下端で止まる。右端で止まる',13,10
			.dc.b	'  ^[[r;cf   カーソルをr-1行,c-1桁へ。下端で止まる。右端で止まる',13,10
			.dc.b	'  ^[[0J     カーソルから右下まで消去する',13,10
			.dc.b	'  ^[[1J     左上からカーソルまで消去する',13,10
			.dc.b	'  ^[[2J     左上から右下まで消去する。カーソルを左上へ',13,10
			.dc.b	'  ^[[0K     カーソルから右端まで消去する',13,10
			.dc.b	'  ^[[1K     左端からカーソルまで消去する',13,10
			.dc.b	'  ^[[2K     左端から右端まで消去する',13,10
			.dc.b	'  ^[[nL     カーソルから下にn行挿入。カーソルを左端へ',13,10
			.dc.b	'  ^[[nM     カーソルから下をn行削除。カーソルを左端へ',13,10
			.dc.b	'  ^[[nP     カーソルから右をn桁削除',13,10
			.dc.b	'  ^[[nX     カーソルから右をn桁消去',13,10
			.dc.b	'  ^[[nc     中央寄せ',13,10
			.dc.b	'  ^[[nl     左寄せ',13,10
			.dc.b	'  ^[[0m     リセット',13,10
			.dc.b	'  ^[[1m     太字',13,10
			.dc.b	'  ^[[2m     細字',13,10
			.dc.b	'  ^[[3m     斜体',13,10
			.dc.b	'  ^[[4m     下線',13,10
			.dc.b	'  ^[[7m     反転',13,10
			.dc.b	'  ^[[9m     取り消し線',13,10
			.dc.b	'  ^[[21m    波線',13,10
			.dc.b	'  ^[[22m    太字、細字解除',13,10
			.dc.b	'  ^[[23m    斜体解除',13,10
			.dc.b	'  ^[[24m    下線、波線解除',13,10
			.dc.b	'  ^[[26m    プロポーショナル',13,10
			.dc.b	'  ^[[27m    反転解除',13,10
			.dc.b	'  ^[[29m    取り消し線解除',13,10
			.dc.b	'  ^[[30m    黒',13,10
			.dc.b	'  ^[[31m    水色',13,10
			.dc.b	'  ^[[32m    黄色',13,10
			.dc.b	'  ^[[33m    白',13,10
			.dc.b	'  ^[[34m    太字、黒',13,10
			.dc.b	'  ^[[35m    太字、水色',13,10
			.dc.b	'  ^[[36m    太字、黄色',13,10
			.dc.b	'  ^[[37m    太字、白',13,10
			.dc.b	'  ^[[40m    反転、黒',13,10
			.dc.b	'  ^[[41m    反転、水色',13,10
			.dc.b	'  ^[[42m    反転、黄色',13,10
			.dc.b	'  ^[[43m    反転、白',13,10
			.dc.b	'  ^[[44m    反転、太字、黒',13,10
			.dc.b	'  ^[[45m    反転、太字、水色',13,10
			.dc.b	'  ^[[46m    反転、太字、黄色',13,10
			.dc.b	'  ^[[47m    反転、太字、白',13,10
			.dc.b	'  ^[[50m    プロポーショナル解除',13,10
			.dc.b	'  ^[[51m    四角囲み',13,10
			.dc.b	'  ^[[52m    丸囲み',13,10
			.dc.b	'  ^[[53m    上線',13,10
			.dc.b	'  ^[[54m    四角囲み、丸囲み解除',13,10
			.dc.b	'  ^[[55m    上線解除',13,10
			.dc.b	'  ^[[73m    上付き',13,10
			.dc.b	'  ^[[74m    下付き',13,10
			.dc.b	'  ^[[75m    上付き、下付き解除',13,10
			.dc.b	'  ^[[6n     カーソル位置報告。^[[r;cRを入力',13,10
			.dc.b	'  ^[[nr     右寄せ',13,10
			.dc.b	'  ^[[s      カーソルの座標と文字属性を保存する',13,10
			.dc.b	'  ^[[u      カーソルの座標と文字属性を復元する',13,10
			.dc.b	0

;サンプル
sample:			.dc.b	27,'[s',27,'[m',13,10
			.dc.b	'サンプル',13,10
			.dc.b	'  ',27,'[1m太字',27,'[m'
			.dc.b	'  ',27,'[7m反転',27,'[m'
			.dc.b	'  ',27,'[31m水色',27,'[m'
			.dc.b	'  ',27,'[32m黄色',27,'[m',13,10
			.dc.b	'  ',27,'[2m細字',27,'[m'
			.dc.b	'  ',27,'[3m斜体',27,'[m'
			.dc.b	'  ',27,'[4m下線',27,'[m'
			.dc.b	'  ',27,'[53m上線',27,'[m'
			.dc.b	'  ',27,'[9m取り消し線',27,'[m'
			.dc.b	'  ',27,'[21m波線',27,'[m',13,10
			.dc.b	'  ',27,'[51m四角囲み',27,'[m'
			.dc.b	'  ',27,'[52m丸囲み',27,'[m'
			.dc.b	'  ',27,'[73m上付き',27,'[m'
			.dc.b	'  ',27,'[74m下付き',27,'[m',13,10
			.dc.b	'  ',27,'[7m',27,'[150l左寄せ',27,'[m',13,10
			.dc.b	'  ',27,'[7m',27,'[150c中央寄せ',27,'[m',13,10
			.dc.b	'  ',27,'[7m',27,'[150r右寄せ',27,'[m',13,10
			.dc.b	'  ',27,'[26mProportional-Pitch',27,'[m',13,10
			.dc.b	13,10
			.dc.b	'  ',27,'[26m    Alice was beginning to get very tired of sitting by her sister on the bank, and',13,10
			.dc.b	'  of having nothing to do: once or twice she had peeped into the book her sister was',13,10
			.dc.b	'  reading, but it had no pictures or conversations in it, `and what is the use of a book,',39,13,10
			.dc.b	'  thought Alice `without pictures or conversation?',39,13,10
			.dc.b	'  ',27,'[640r-- from Alice in Wonderland by Lewis Carroll --',27,'[m',13,10
			.dc.b	13,10,27,'[u'
			.dc.b	0

	.data

;----------------------------------------------------------------
;フラグ
option_flag:		.dc.b	0	;-1=オプションが指定された
fixed_flag:		.dc.b	0	;-f。-1=固定ピッチ
keeppr_flag:		.dc.b	0	;-k。-1=常駐する
proportional_flag:	.dc.b	0	;-p。-1=プロポーショナルピッチ
quiet_flag:		.dc.b	0	;-q。-1=表示を減らす
release_flag:		.dc.b	0	;-r。-1=解除する
sample_flag:		.dc.b	0	;-s。-1=サンプル
verbose_flag:		.dc.b	0	;-v。-1=表示を増やす



	.text
	.even

;----------------------------------------------------------------
;文字列をエラー表示する
;<a0.l:文字列
eprint:
	move.l	d0,-(sp)
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#2,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;改行をエラー表示する
eprintcrlf:
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	bsr	eprint
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;文字列と改行をエラー表示する
;<a0.l:文字列
eprintln:
	bsr	eprint
	bsr	eprintcrlf
	rts

;----------------------------------------------------------------
;-more-を挟みながら文字列を表示する
;<a0.l:文字列
more:
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
;空白か
;<d0.b:文字
;>z:eq=空白,ne=空白ではない
isspace:
	ifor	<cmp.b #' ',d0>,eq,<cmp.b #9,d0>,eq,<cmp.b #10,d0>,eq,<cmp.b #11,d0>,eq,<cmp.b #12,d0>,eq,<cmp.b #13,d0>,eq	; \t\n\v\f\r
	endif
	rts

;----------------------------------------------------------------
;空白以外の文字まで読み飛ばす
;<a0.l:文字列
;>d0.l:空白以外の文字または0
;>a0.l:空白以外の文字または0の位置
;>z:eq=0
nonspace:
	moveq.l	#0,d0
	do
		move.b	(a0)+,d0		;次の文字
		redoand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\rならば繰り返す
	while	<cmp.b #' ',d0>,eq	;空白ならば繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	tst.l	d0
	rts

;----------------------------------------------------------------
;文字列を表示する
;<a0.l:文字列
print:
	move.l	d0,-(sp)
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;改行を表示する
printcrlf:
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	bsr	print
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;文字列と改行を表示する
;<a0.l:文字列
println:
	bsr	print
	bsr	printcrlf
	rts

;----------------------------------------------------------------
;10進数の文字列を符号なし整数に変換する
;<a0.l:10進数の文字列。先頭の空白は認めない
;>d0.l:(ccのとき)符号なし整数。(csのとき)0=10進数の文字がない,-1=オーバーフロー
;>a0.l:(ccのとき)10進数の文字列の次の位置。(csのとき)変化しない
;>z:(ccのとき)eq=符号なし整数が0
;>v:(csのとき)vc=10進数の文字がない,vs=オーバーフロー
;>c:cs=10進数の文字がないまたはオーバーフロー
stou:
	push	d1-d2/a1
	moveq.l	#0,d0			;符号なし整数
	moveq.l	#0,d1			;文字
	movea.l	a0,a1			;開始位置
	dostart
		goto	<cmp.l #$1999999A,d0>,hs,80f	;10倍したらオーバーフローする
		move.l	d0,d2			;1倍
		lsl.l	#2,d0			;4倍
		add.l	d2,d0			;5倍
		add.l	d0,d0			;10倍して
		add.l	d1,d0			;1桁加える
		goto	cs,80f			;オーバーフローした
	start
		move.b	(a0)+,d1		;次の文字
		sub.b	#'0',d1			;整数にする
	whileand	<>,hs,<cmp.b #10,d1>,lo	;10進数の文字ならば繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	if	<cmpa.l a1,a0>,eq	;進んでいない。10進数の文字がない
		move.w	#%00001,ccr		;vc,cs
	else
		tst.l	d0			;eq or ne,vc,cc
	endif
	goto	90f

;オーバーフローしたとき
80:	moveq.l	#-1,d0			;オーバーフロー
	movea.l	a1,a0			;変化しない
	move.w	#%00011,ccr		;vs,cs
90:	pop
	rts

;----------------------------------------------------------------
;文字列の長さを数える
;<a0.l:文字列
;>d0.l:長さ
strlen:
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
tolower:
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;大文字
		add.b	#'a'-'A',d0		;小文字にする
	endif
	rts



;----------------------------------------------------------------
;プログラムの末尾
	.bss
	.even
program_end:

	.end	execution_start

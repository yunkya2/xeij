;========================================================================================
;  optime.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	optime.x
;		命令列の実行時間を計測します。
;
;	最終更新
;		2023-09-17
;
;	作り方
;		has060 -i include -o optime.o -w optime.s
;		lk -o optime.x optime.o
;
;	使い方
;		-a アセンブラ
;			アセンブラを指定します。
;			指定がなければhas060を使います。
;		-f ファイル名
;			実行時間を計測したい命令列を書いたファイルを指定します。
;			改行で命令を区切ります。
;		-i "命令列"
;			実行時間を計測したい命令列を"～"で囲んで指定します。
;			セミコロンで命令を区切ります。
;			注釈を意味するセミコロンは書けません。
;		-s
;			命令列をSRAMに書き込んで計測します。
;			DRAMのリフレッシュによる誤差が出にくくなります。
;			X68000では1ワードあたり1サイクルのウェイトが追加されます。
;			SRAMが使用中のとき計測するか問い合わせます。
;		-sn
;			-sと同様ですがSRAMが使用中のときは計測しません。
;		-sy
;			-sと同様ですがSRAMが使用中のときも計測します。
;		-t ディレクトリ名
;			テンポラリディレクトリを指定します。
;			指定がなければ環境変数tempを読み出します。
;			環境変数tempもなければカレントディレクトリを使います。
;		-v
;			冗長に出力します。
;		命令列
;			正しく計測できる実行時間の上限は12.799msです。
;			命令列の長さの上限は32766バイトです。
;			セクションの変更はできません。
;			分岐命令も書けますが出口は命令列の末尾になければなりません。
;			d7/a5-a7を変更するときは保存と復元を行ってください。
;			-268(a5)～-1(a5)の268バイトは読み書き自由の空き領域です。
;			命令列はスーパーバイザモードで呼び出されます。
;			命令列は割り込みが禁止された状態で呼び出されます。
;
;	更新履歴
;		2023-01-19
;			公開。
;		2023-01-21
;			-vのときタイトルとバージョンを表示する。
;			エラーメッセージの表示に標準エラー出力を使わない。
;			テンポラリディレクトリ名の末尾が':'のとき'\'を追加しない。
;			アセンブラのパラメータに-wを指定して警告を抑制する。
;			アセンブラのメッセージを隠さない。
;			-vのときアセンブラの終了コードを表示する。
;		2023-09-17
;			"～"または'～'が閉じていないと白窓が出るバグを修正。
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sram.equ

TITLE_STRING	reg	'optime.x (2023-09-17)'

ERROR_OUTPUT	equ	0		;1=エラーメッセージの表示に標準エラー出力を使う
WARNING_OPTION	equ	1		;1=アセンブラのパラメータに-wを指定して警告を抑制する
HIDE_ASSEMBLER	equ	0		;1=アセンブラのメッセージを隠す

	.text

;----------------------------------------------------------------
;プログラム開始
program_start::

;----------------------------------------------------------------
;スタックエリアを設定する
	lea.l	stack_area_end,sp	;スタックエリアの末尾

	.stack
	.even
		.ds.b	65536		;スタックエリア
stack_area_end::
	.text

;----------------------------------------------------------------
;メモリブロックを短くする
;	子プロセスを起動するため
;	*.r形式は非対応
;<a0.l:メモリ管理ポインタ
;<a1.l:使用部分の末尾
	lea.l	16(a0),a0		;メモリブロックの先頭
	suba.l	a0,a1			;使用部分の長さ
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	DOS	_SETBLOCK
	addq.l	#8,sp

;----------------------------------------------------------------
;オプションを確認する
;<a2.l:コマンドライン。LASCIIZ
	clr.b	assembler_arg		;-a アセンブラ
	clr.b	file_arg		;-f ファイル名
	clr.b	inst_arg		;-i 命令列
	clr.b	sram_flag		;-s SRAMフラグ。1=-s,2=-sn,3=-sy
	clr.b	temp_arg		;-t ディレクトリ名
	clr.b	verbose_flag		;-v 冗長フラグ
	lea.l	1(a2),a1
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;-,/以外
		addq.l	#1,a1
		move.b	(a1)+,d0
		goto	eq,usage_exit		;-,/の後に文字がない
		bsr	tolower
		if	<cmp.b #'a',d0>,eq	;-a
			lea.l	assembler_arg,a0	;-a アセンブラ
			bsr	argcpy
			goto	eq,usage_exit		;-aの後に文字がない
		elif	<cmp.b #'f',d0>,eq	;-f
			lea.l	file_arg,a0		;-f ファイル名
			bsr	argcpy
			goto	eq,usage_exit		;-fの後に文字がない
		elif	<cmp.b #'i',d0>,eq	;-i
			lea.l	inst_arg,a0		;-i 命令列
			bsr	argcpy
			goto	eq,usage_exit		;-iの後に文字がない
		elif	<cmp.b #'s',d0>,eq
			move.b	(a1)+,d0
			bsr	tolower
			if	<cmpi.b #'n',d0>,eq	;-sn
				move.b	#2,sram_flag		;-s SRAMフラグ。1=-s,2=-sn,3=-sy
			elif	<cmpi.b #'y',d0>,eq	;-sy
				move.b	#3,sram_flag		;-s SRAMフラグ。1=-s,2=-sn,3=-sy
			else
				subq.l	#1,a1
				move.b	#1,sram_flag		;-s SRAMフラグ。1=-s,2=-sn,3=-sy
			endif
		elif	<cmp.b #'t',d0>,eq	;-t
			lea.l	temp_arg,a0		;-t ディレクトリ名
			bsr	argcpy
			goto	eq,usage_exit		;-tの後に文字がない
		elif	<cmp.b #'v',d0>,eq	;-v
			st.b	verbose_flag		;-v 冗長フラグ
		else				;その他
			goto	usage_exit
		endif
	start
		exg.l	a0,a1
		bsr	nonspace
		exg.l	a0,a1
	while	ne
	gotoand	<tst.b file_arg>,eq,<tst.b inst_arg>,eq,usage_exit	;-fと-iが両方ない
	gotoand	<tst.b file_arg>,ne,<tst.b inst_arg>,ne,usage_exit	;-fと-iが両方ある
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'> optime.x',a1
		bsr	strcpy
		if	<tst.b assembler_arg>,ne
			leastrdata	' -a ',a1
			bsr	strcpy
			lea.l	assembler_arg,a1	;-a アセンブラ
			bsr	strcpy
		endif
		if	<tst.b file_arg>,ne
			leastrdata	' -f ',a1
			bsr	strcpy
			lea.l	file_arg,a1		;-f ファイル名
			bsr	strcpy
		endif
		if	<tst.b inst_arg>,ne
			leastrdata	' -i ',a1
			bsr	strcpy
			move.b	#'"',(a0)+
			lea.l	inst_arg,a1		;-i 命令列
			bsr	strcpy
			move.b	#'"',(a0)+
		endif
		if	<tst.b sram_flag>,ne
			if	<cmpi.b #2,sram_flag>,lo	;-s SRAMフラグ
				leastrdata	' -s',a1
			elif	eq
				leastrdata	' -sn',a1
			else
				leastrdata	' -sy',a1
			endif
			bsr	strcpy
		endif
		if	<tst.b temp_arg>,ne
			leastrdata	' -t ',a1
			bsr	strcpy
			lea.l	temp_arg,a1		;-t ディレクトリ名
			bsr	strcpy
		endif
	;	if	<tst.b verbose_flag>,ne
			leastrdata	' -v',a1
			bsr	strcpy
	;	endif
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif

	.bss
assembler_arg::
	.ds.b	1024			;-a アセンブラ
file_arg::
	.ds.b	1024			;-f ファイル名
inst_arg::
	.ds.b	1024			;-i 命令列
sram_flag::
	.ds.b	1			;-s SRAMフラグ
temp_arg::
	.ds.b	1024			;-t ディレクトリ名
verbose_flag::
	.ds.b	1			;-v 冗長フラグ
string_buffer::
	.ds.b	4096			;文字列バッファ
	.text

;----------------------------------------------------------------
;命令列をソースコードに変換する
	if	<tst.b inst_arg>,ne
		lea.l	inst_arg,a1		;-i 命令列
		lea.l	source_code,a0		;ソースコード
		dostart
			if	<cmpi.b #'@',(a1)>,ne
				move.b	#9,(a0)+
			endif
			docontinue
				move.b	(a1)+,(a0)+
			whileand	<tst.b (a1)>,ne,<cmpi.b #';',(a1)>,ne
			move.b	#13,(a0)+
			move.b	#10,(a0)+
		start
			docontinue
				addq.l	#1,a1
			whileor	<cmpi.b #' ',(a1)>,eq,<cmpi.b #9,(a1)>,eq,<cmpi.b #';',(a1)>,eq
		while	<tst.b (a1)>,ne
		clr.b	(a0)
		if	<tst.b verbose_flag>,ne
			leastrdata	<'source code:',13,10>,a0
			bsr	print
			lea.l	source_code,a0		;ソースコード
			bsr	print
		endif
	endif

	.bss
source_code::
	.ds.b	1024			;ソースコード
	.text

;----------------------------------------------------------------
;テンポラリディレクトリ名を取得する
;	末尾が':'と'/'と'\'のいずれでもないとき'\'を追加する
;	'.'が2バイト文字の2バイト目でないことの確認は省略する
	if	<tst.b temp_arg>,ne
		lea.l	temp_directory,a0	;テンポラリディレクトリ名
		lea.l	temp_arg,a1		;-t ディレクトリ名
		bsr	strcpy
	else
		clr.b	temp_directory		;テンポラリディレクトリ名
		pea.l	temp_directory		;テンポラリディレクトリ名
		clr.l	-(sp)
		peastrdata	'temp'		;環境変数tempを読み出す
		DOS	_GETENV
		lea.l	12(sp),sp
	endif
	lea.l	temp_directory,a0	;テンポラリディレクトリ名
	if	<tst.b (a0)>,ne
		bsr	strchr0
		ifand	<cmpi.b #':',-1(a0)>,ne,<cmpi.b #'/',-1(a0)>,ne,<cmpi.b #'\',-1(a0)>,ne
			move.b	#'\',(a0)+
			clr.b	(a0)
		endif
	endif
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'temporary directory: ',a1
		bsr	strcpy
		lea.l	temp_directory,a1	;テンポラリディレクトリ名
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif

	.bss
temp_directory::
	.ds.b	1024			;テンポラリディレクトリ名
	.text

;----------------------------------------------------------------
;スーパーバイザモードへ移行する
	supervisormode

;----------------------------------------------------------------
;sspとuspを保存する
	move.l	sp,saved_ssp		;保存されたssp
	move.l	usp,a0
	move.l	a0,saved_usp		;保存されたusp

	.data
	.even
saved_ssp::
	.dc.l	0			;保存されたssp
saved_usp::
	.dc.l	0			;保存されたusp
	.text

;----------------------------------------------------------------
;アボートベクタを保存する
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,saved_ctrlvc		;保存された_CTRLVC
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,saved_errjvc		;保存された_ERRJVC

	.data
	.even
saved_ctrlvc::
	.dc.l	0			;保存された_CTRLVC
saved_errjvc::
	.dc.l	0			;保存された_ERRJVC
	.text

;----------------------------------------------------------------
;アボートベクタを変更する
	pea.l	abort			;中止
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	pea.l	abort			;中止
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp

;----------------------------------------------------------------
;SRAMの使用状態を確認する
	if	<tst.b sram_flag>,ne
		if	<tst.b SRAM_SRAM_USAGE>,ne
			if	<cmp.b #2,sram_flag>,lo
				leastrdata	'SRAM in use. Continue? (y/n) ',a0
				bsr	yesno
			elif	eq
				moveq.l	#'n',d0
			else
				moveq.l	#'y',d0
			endif
			goto	<cmp.b #'y',d0>,ne,abort	;中止
		endif
	endif

;----------------------------------------------------------------
;ソースファイルを作る
	bsr	create_source		;ソースファイルを作る

;----------------------------------------------------------------
;オブジェクトファイル名を作る
;	ソースファイル名の先頭を除く最後の'.'の位置なければ末尾に'.o'を書く
;	'.'が2バイト文字の2バイト目でないことの確認は省略する
	lea.l	object_file,a0		;オブジェクトファイル名
	lea.l	source_file,a1		;ソースファイル名
	bsr	strcpy
	movea.l	a0,a2			;末尾
	lea.l	object_file,a1		;先頭
	dostart
		if	<cmpi.b #'.',(a0)>,eq
			movea.l	a0,a2			;最後の'.'の位置
			break
		endif
	start
		subq.l	#1,a0
	while	<cmpa.l a1,a0>,hi	;先頭を除く
	move.b	#'.',(a2)+
	move.b	#'o',(a2)+
	clr.b	(a2)
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'object file: ',a1
		bsr	strcpy
		lea.l	object_file,a1		;オブジェクトファイル名
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif

	.bss
object_file::
	.ds.b	1024			;オブジェクトファイル名
	.text

;----------------------------------------------------------------
;コマンドラインを作る
	lea.l	command_line,a0		;コマンドライン、コマンド
	lea.l	assembler_arg,a1	;アセンブラ
	if	<tst.b (a1)>,eq
		leastrdata	'has060',a1
	endif
	bsr	strcpy
  .if WARNING_OPTION
	leastrdata	' -w -o ',a1
  .else
	leastrdata	' -o ',a1
  .endif
	bsr	strcpy
	lea.l	object_file,a1		;オブジェクトファイル名
	bsr	strcpy
	move.b	#' ',(a0)+
	lea.l	source_file,a1		;ソースファイル名
	bsr	strcpy
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'command line: ',a1
		bsr	strcpy
		lea.l	command_line,a1		;コマンドライン、コマンド
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif

	.bss
command_line::
	.ds.b	1024			;コマンドライン、コマンド
	.text

;----------------------------------------------------------------
;コマンドラインをコマンドと引数に分ける
	clr.l	-(sp)
	pea.l	command_args		;引数
	pea.l	command_line		;コマンドライン、コマンド
	move.w	#2,-(sp)
	DOS	_EXEC
	lea.l	14(sp),sp
	if	<tst.l d0>,mi
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'cannot find ',a1
		bsr	strcpy
		lea.l	command_line,a1		;コマンドライン、コマンド
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;中止
	endif
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'command: ',a1
		bsr	strcpy
		lea.l	command_line,a1		;コマンドライン、コマンド
		bsr	strcpy
		bsr	crlf
		leastrdata	'arguments: ',a1
		bsr	strcpy
		lea.l	command_args+1,a1	;引数
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif

	.bss
command_args::
	.ds.b	1024			;引数
	.text

  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;NULを開く
	bsr	open_nul		;NULを開く

;----------------------------------------------------------------
;標準ハンドルを保存する
	bsr	save_std		;標準ハンドルを保存する

;----------------------------------------------------------------
;標準ハンドルをNULへリダイレクトする
;	アセンブラの表示を隠す
	clr.w	-(sp)			;標準入力ハンドル
	move.w	nul_in_handle,-(sp)	;NUL入力ハンドル
	DOS	_DUP2
	addq.l	#4,sp
	move.w	#1,-(sp)		;標準出力ハンドル
	move.w	nul_out_handle,-(sp)	;NUL出力ハンドル
	DOS	_DUP2
	addq.l	#4,sp
	move.w	#2,-(sp)		;標準エラー出力ハンドル
	move.w	nul_out_handle,-(sp)	;NUL出力ハンドル
	DOS	_DUP2
	addq.l	#4,sp

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;コマンドを実行する
	clr.l	-(sp)
	pea.l	command_args		;引数
	pea.l	command_line		;コマンドライン、コマンド
	clr.w	-(sp)
	DOS	_EXEC
	lea.l	14(sp),sp
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'exit code: ',a1
		bsr	strcpy
		bsr	utos
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif
	if	<tst.l d0>,mi
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'cannot execute ',a1
		bsr	strcpy
		lea.l	command_line,a1		;コマンドライン、コマンド
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;中止
	endif
	st.b	object_created		;-1=オブジェクトファイル作成済み

	.data
object_created::
	.dc.b	0			;-1=オブジェクトファイル作成済み
	.text

  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;標準ハンドルを復元する
	bsr	restore_std		;標準ハンドルを復元する

;----------------------------------------------------------------
;NULを閉じる
	bsr	close_nul		;NULを閉じる

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;ソースファイルを消す
	bsr	delete_source		;ソースファイルを消す

;----------------------------------------------------------------
;オブジェクトファイルを開く
	bsr	open_object		;オブジェクトファイルを開く

;----------------------------------------------------------------
;SRAMの内容を保存する
	bsr	save_sram		;SRAMの内容を保存する

;----------------------------------------------------------------
;コードの先頭アドレスを決める
	if	<tst.b sram_flag>,ne
		lea.l	SRAM_PROGRAM_START,a0	;SRAM常駐プログラムの先頭
	else
		lea.l	code_buffer,a0		;コードバッファ
	endif
	move.l	a0,d0
	add.l	#256-1,d0		;256の倍数に切り上げる
	and.w	#-256,d0
	movea.l	d0,a0
	move.l	a0,free_start		;空き領域の先頭アドレス
	lea.l	268(a0),a0
	move.l	a0,code_start		;コードの先頭アドレス
	addq.l	#4,a0
	move.l	a0,loop_start		;ループの先頭アドレス
	lea.l	32766(a0),a0
	if	<tst.b sram_flag>,ne
		if	<cmpa.l #SRAM_END-6,a0>,hi
			lea.l	SRAM_END-6,a0		;SRAMの末尾-6
		endif
	endif
	move.l	a0,loop_end_limit	;ループの末尾アドレスの上限
;	addq.l	#6,a0
;	move.l	a0,code_end_limit	;コードの末尾アドレスの上限


	.bss
	.even
free_start::
	.ds.l	1			;空き領域の先頭アドレス
code_start::
	.ds.l	1			;コードの先頭アドレス
loop_start::
	.ds.l	1			;ループの先頭アドレス
loop_end_limit::
	.ds.l	1			;ループの末尾アドレスの上限
;code_end_limit::
;	.ds.l	1			;コードの末尾アドレスの上限
code_buffer::
	.ds.b	256+268+4+32766+6	;コードバッファ
	.text

;----------------------------------------------------------------
;空き領域をゼロクリアする
	if	<tst.b sram_flag>,ne
		unlocksram			;SRAM書き込み許可
	endif
	movea.l	free_start,a0		;空き領域の先頭アドレス
	movea.l	code_start,a1		;コードの先頭アドレス
	moveq.l	#0,d0
	do
		move.l	d0,(a0)+
	while	<cmpa.l a1,a0>,lo
;	if	<tst.b sram_flag>,ne
;		locksram			;SRAM書き込み禁止
;	endif

;----------------------------------------------------------------
;オブジェクトファイルを読み込んで命令列ループを作る
;	if	<tst.b sram_flag>,ne
;		unlocksram			;SRAM書き込み許可
;	endif
	movea.l	code_start,a0		;コードの先頭アドレス
	move.l	#$3E3C0000,(a0)+	;move.w #1-1,d7
	movea.l	a0,a3			;loop_start
	moveq.l	#0,d3			;0=失敗,1=成功
	do
		bsr	object_word
		break	mi
		if	eq			;終了
			move.w	#$51CF,(a0)+		;dbra d7,(loop_start)
			move.w	a3,d0
			sub.w	a0,d0
			move.w	d0,(a0)+
			move.w	#$4E75,(a0)+		;rts
		;	bsr	cache_flush		;キャッシュフラッシュ
			move.l	a0,code_end		;コードの末尾アドレス
			moveq.l	#1,d3			;成功
			break
		elifand	<cmp.w #$1000,d0>,hs,<cmp.w #$10FF,d0>,ls	;.dcまたは命令
			and.w	#$00FF,d0
			addq.w	#1,d0			;長さ
			lea.l	(a0,d0.w),a1		;末尾
			break	<cmpa.l loop_end_limit,a1>,hi	;textセクションが溢れた。失敗
			do
				bsr	object_byte
				break2	mi
				move.b	d0,(a0)+
			while	<cmpa.l a1,a0>,lo
			move.w	a1,d0
			if	<btst.l #0,d0>,ne	;長さが奇数
				bsr	object_byte
				break	mi
			endif
		elif	<cmp.w #$2001,d0>,eq	;textセクション
			bsr	object_long
			break	mi
		elif	<cmp.w #$2002,d0>,eq	;dataセクション
			break	t			;dataセクションがある。失敗
		elif	<cmp.w #$2003,d0>,eq	;bssセクション
			break	t			;bssセクションがある。失敗
		elif	<cmp.w #$2004,d0>,eq	;stackセクション
			break	t			;stackセクションがある。失敗
		elif	<cmp.w #$3000,d0>,eq	;.ds
			bsr	object_long		;長さ
			break	mi
			lea.l	(a0,d0.l),a1		;末尾
			break	<cmpa.l loop_end_limit,a1>,hi	;textセクションが溢れた。失敗
			do
				clr.b	(a0)+
			while	<cmpa.l a1,a0>,lo
		elif	<cmp.w #$4201,d0>,eq	;textセクションの先頭からのオフセット
			bsr	object_long		;オフセット
			break	mi
			lea.l	4(a0),a1		;末尾
			break	<cmpa.l loop_end_limit,a1>,hi	;textセクションが溢れた。失敗
			add.l	a3,d0			;リロケートしたアドレス
			moveq.l	#4-1,d1
			for	d1
				rol.l	#8,d0
				move.b	d0,(a0)+
			next
		elif	<cmp.w #$C001,d0>,eq	;textセクションの情報
			bsr	object_long		;textセクションの長さ
			break	mi
			break	eq			;textセクションがない。失敗
			bsr	object_string
			break	mi
		elif	<cmp.w #$C002,d0>,eq	;.dataの情報
			bsr	object_long		;.dataの長さ
			break	mi
			break	ne			;.dataがある。失敗
			bsr	object_string
			break	mi
		elif	<cmp.w #$C003,d0>,eq	;.bssの情報
			bsr	object_long		;.bssの長さ
			break	mi
			break	ne			;.bssがある。失敗
			bsr	object_string
			break	mi
		elif	<cmp.w #$C004,d0>,eq	;.stackの情報
			bsr	object_long		;.stackの長さ
			break	mi
			break	ne			;.stackがある。失敗
			bsr	object_string
			break	mi
		elif	<cmp.w #$D000,d0>,eq	;ファイル情報
			bsr	object_long
			break	mi
			bsr	object_string
			break	mi
		else				;その他
			break	t			;失敗
		endif
	while	t
	if	<tst.b sram_flag>,ne
		locksram			;SRAM書き込み禁止
	endif
	if	<tst.l d3>,eq		;失敗
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'cannot process ',a1
		bsr	strcpy
	;	lea.l	object_file,a1		;オブジェクトファイル名
		if	<tst.b inst_arg>,ne
			move.b	#'"',(a0)+
			lea.l	inst_arg,a1		;-i 命令列
			bsr	strcpy
			move.b	#'"',(a0)+
		else
			lea.l	file_arg,a1		;-f ファイル名
			bsr	strcpy
		endif
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;中止
	endif

	.bss
	.even
code_end::
	.ds.l	1			;コードの末尾アドレス
	.text

;----------------------------------------------------------------
;オブジェクトファイルを閉じる
	bsr	close_object		;オブジェクトファイルを閉じる

;----------------------------------------------------------------
;オブジェクトファイルを消す
	bsr	delete_object		;オブジェクトファイルを消す

;----------------------------------------------------------------
;命令列ループを計測する
	move.l	#1,repeat_count		;繰り返し回数
	do
		if	<tst.b verbose_flag>,ne
			lea.l	string_buffer,a0	;文字列バッファ
			leastrdata	'repeat count: ',a1
			bsr	strcpy
			move.l	repeat_count,d0		;繰り返し回数
			bsr	utos
			bsr	crlf
			lea.l	string_buffer,a0	;文字列バッファ
			bsr	print
		endif
		if	<tst.b sram_flag>,ne
			unlocksram			;SRAM書き込み許可
		endif
		move.l	repeat_count,d0		;繰り返し回数
		subq.w	#1,d0			;繰り返し回数-1
		movea.l	code_start,a0		;コードの先頭アドレス
		move.w	d0,2(a0)		;DBRAを書き換える
		bsr	cache_flush		;キャッシュフラッシュ
		if	<tst.b sram_flag>,ne
			locksram			;SRAM書き込み禁止
		endif
		if	<tst.b verbose_flag>,ne
			leastrdata	<'instructions loop:',13,10>,a0
			bsr	print
			bsr	dump_code		;コードをダンプする
		endif
		if	<tst.b sram_flag>,ne
			unlocksram			;SRAM書き込み許可
		endif
		movea.l	code_start,a0		;コードの先頭アドレス
		bsr	optime			;計測
		move.l	d0,inst_loop_time	;命令列ループの所要時間
		if	<tst.b sram_flag>,ne
			locksram			;SRAM書き込み禁止
		endif
		if	<tst.b verbose_flag>,ne
			lea.l	string_buffer,a0	;文字列バッファ
			leastrdata	'instructions loop time: ',a1
			bsr	strcpy
			move.l	inst_loop_time,d0	;命令列ループの所要時間
			moveq.l	#1,d1
			bsr	time_to_string
			bsr	crlf
			lea.l	string_buffer,a0	;文字列バッファ
			bsr	print
		endif
		break	<cmpi.l #1200,inst_loop_time>,hs	;1200us以上ならば終了
		break	<cmpi.l #10000,repeat_count>,eq	;10000回ならば終了
		move.l	repeat_count,d0
		mulu.w	#10,d0			;回数を10倍にする
		move.l	d0,repeat_count
	while	t

	.bss
	.even
repeat_count::
	.ds.l	1			;繰り返し回数
inst_loop_time::
	.ds.l	1			;命令列ループの所要時間
	.text

;----------------------------------------------------------------
;空ループを作る
	if	<tst.b sram_flag>,ne
		unlocksram			;SRAM書き込み許可
	endif
	movea.l	code_start,a0		;コードの先頭アドレス
	move.w	#$3E3C,(a0)+		;move.w #回数-1,d7
	move.l	repeat_count,d0
	subq.w	#1,d0
	move.w	d0,(a0)+
	move.l	#$51CFFFFE,(a0)+	;dbra d7,(loop_start)
	move.w	#$4E75,(a0)+		;rts
	bsr	cache_flush		;キャッシュフラッシュ
	move.l	a0,code_end
	if	<tst.b sram_flag>,ne
		locksram			;SRAM書き込み禁止
	endif
	if	<tst.b verbose_flag>,ne
		leastrdata	<'null loop:',13,10>,a0
		bsr	print
		bsr	dump_code		;コードをダンプする
	endif

;----------------------------------------------------------------
;空ループを計測する
	movea.l	code_start,a0		;コードの先頭アドレス
	bsr	optime			;計測
	move.l	d0,null_loop_time	;空ループの所要時間
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'null loop time: ',a1
		bsr	strcpy
		move.l	null_loop_time,d0	;空ループの所要時間
		moveq.l	#1,d1
		bsr	time_to_string
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif

	.bss
	.even
null_loop_time::
	.ds.l	1			;空ループの所要時間
	.text

;----------------------------------------------------------------
;SRAMの内容を復元する
	bsr	restore_sram		;SRAMの内容を復元する

;----------------------------------------------------------------
;コードの所要時間を表示する
	lea.l	string_buffer,a0	;文字列バッファ
	if	<tst.b inst_arg>,ne
		move.b	#'"',(a0)+
		lea.l	inst_arg,a1		;-i 命令列
		bsr	strcpy
		move.b	#'"',(a0)+
	else
		lea.l	file_arg,a1		;-f ファイル名
		bsr	strcpy
	endif
	move.b	#9,(a0)+
	move.l	inst_loop_time,d0	;命令列ループの所要時間
	sub.l	null_loop_time,d0	;命令列ループの所要時間-空ループの所要時間=命令列の所要時間
	if	lt
		moveq.l	#0,d0
	endif
	move.l	repeat_count,d1
	bsr	time_to_string
	bsr	crlf
	lea.l	string_buffer,a0	;文字列バッファ
	bsr	print

;----------------------------------------------------------------
;正常終了
	clr.w	exit_code		;終了コード

	.data
	.even
exit_code::
	.dc.w	1			;終了コード
	.text

;----------------------------------------------------------------
;中止
abort::

;----------------------------------------------------------------
;sspとuspを復元する
	if	<tst.l saved_ssp>,ne
		movea.l	saved_ssp,sp		;保存されたssp
		clr.l	saved_ssp		;保存されたssp
	endif
	if	<tst.l saved_usp>,ne
		move.l	saved_usp,a0		;保存されたusp
		move.l	a0,usp
		clr.l	saved_usp		;保存されたusp
	endif

;----------------------------------------------------------------
;アボートベクタを復元する
	if	<tst.l saved_ctrlvc>,ne
		move.l	saved_ctrlvc,-(sp)	;保存された_CTRLVC
		move.w	#_CTRLVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		clr.l	saved_ctrlvc		;保存された_CTRLVC
	endif
	if	<tst.l saved_errjvc>,ne
		move.l	saved_errjvc,-(sp)	;保存された_ERRJVC
		move.w	#_ERRJVC,-(sp)
		DOS	_INTVCS
		addq.l	#6,sp
		clr.l	saved_errjvc		;保存された_ERRJVC
	endif

;----------------------------------------------------------------
;タイマを復元する
	bsr	restore_timer		;タイマを復元する

  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;標準ハンドルを復元する
	bsr	restore_std		;標準ハンドルを復元する

;----------------------------------------------------------------
;NULを閉じる
	bsr	close_nul		;NULを閉じる

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;ソースファイルを消す
	bsr	delete_source		;ソースファイルを消す

;----------------------------------------------------------------
;オブジェクトファイルを閉じる
	bsr	close_object		;オブジェクトファイルを閉じる

;----------------------------------------------------------------
;オブジェクトファイルを消す
	bsr	delete_object		;オブジェクトファイルを消す

;----------------------------------------------------------------
;SRAMの内容を復元する
	bsr	restore_sram		;SRAMの内容を復元する

;----------------------------------------------------------------
;ユーザモードへ復帰する
	usermode

;----------------------------------------------------------------
;終了する
	move.w	exit_code,-(sp)		;終了コード
	DOS	_EXIT2


;----------------------------------------------------------------
;タイトルと使用法を表示して終了する
usage_exit::
	lea.l	title_usage,a0		;タイトルと使用法
  .if ERROR_OUTPUT
	bsr	eprint
  .else
	bsr	print
  .endif
	move.w	#1,-(sp)
	DOS	_EXIT2

	.data
title_usage::
	.dc.b	TITLE_STRING,13,10
	.dc.b	'Measure the execution time of instructions',13,10
	.dc.b	'  -a has060  Assembler',13,10
	.dc.b	'  -f nop.s   File containing instructions',13,10
	.dc.b	'  -i "nop"   Semicolon-delimited instructions',13,10
	.dc.b	'  -s         Measure in SRAM. Ask when SRAM in use',13,10
	.dc.b	'  -sn        Same as -s but not measure when SRAM in use',13,10
	.dc.b	'  -sy        Same as -s but measure even when SRAM in use',13,10
	.dc.b	'  -t %temp%  Temporary directory',13,10
	.dc.b	'  -v         Output verbose messages',13,10
	.dc.b	0			;タイトルと使用法
	.text


;----------------------------------------------------------------
;1回の時間を文字列に変換する
;<d0.l:時間(us)。0～12799
;<d1.w:回数。1,10,100,1000,10000のいずれか
;<a0.l:バッファ
;>a0.l:文字列の末尾の0の位置
time_to_string::
	push	d0-d3/a1-a2
	movea.l	a0,a1
;<a1.l:先頭
	bsr	utos
;<a0.l:末尾
	move.w	a0,d0
	sub.w	a1,d0
;<d0.w:全体の桁数。0usは1桁
	moveq.l	#0,d2
	moveq.l	#1,d3
	docontinue
		addq.w	#1,d2
		mulu.w	#10,d3
	while	<cmp.w d3,d1>,hi
;<d2.w:小数部の桁数。0以上
	move.w	d0,d1
	sub.w	d2,d1
;<d1.w:整数部の桁数
	moveq.l	#'u',d3
	if	<cmp.w #3,d1>,gt	;usの整数部が4桁以上ある。msにする
		addq.w	#3,d2
		subq.w	#3,d1
		moveq.l	#'m',d3
	endif
;<d3.b:単位。'u'または'm'
	if	<tst.w	d1>,le		;整数部がない。(a1)に'0.'と'0'を-d1個挿入する
		neg.w	d1
		lea.l	2(a1,d1.w),a2		;(a1)の移動先
		lea.l	(a2,d0.w),a0		;新しい末尾
		for	d0
			move.b	(a1,d0.w),(a2,d0.w)	;末尾の0と全体をずらす
		next
		move.b	#'0',(a1)+
		move.b	#'.',(a1)+
		forcontinue	d1
			move.b	#'0',(a1)+
		next
	elif	<tst.w	d2>,gt		;小数部がある。(a1,d1.w)に'.'を挿入する
		adda.w	d1,a1			;'.'を挿入する位置
		lea.l	1(a1),a2		;(a1)の移動先
		addq.l	#1,a0			;新しい末尾
		for	d2
			move.b	(a1,d2.w),(a2,d2.w)	;末尾の0と小数部をずらす
		next
		move.b	#'.',(a1)+
	endif
	move.b	#' ',(a0)+
	move.b	d3,(a0)+
	move.b	#'s',(a0)+
	clr.b	(a0)
	pop
	rts


  .if HIDE_ASSEMBLER

;----------------------------------------------------------------
;標準ハンドルを保存する
save_std::
	clr.w	-(sp)			;標準入力ハンドル
	DOS	_DUP
	addq.l	#2,sp
	move.w	d0,saved_stdin		;保存された標準入力ハンドル
	move.w	#1,-(sp)		;標準出力ハンドル
	DOS	_DUP
	addq.l	#2,sp
	move.w	d0,saved_stdout		;保存された標準出力ハンドル
	move.w	#2,-(sp)		;標準エラー出力ハンドル
	DOS	_DUP
	addq.l	#2,sp
	move.w	d0,saved_stderr		;保存された標準エラー出力ハンドル
	rts

	.data
	.even
saved_stdin::
	.dc.w	-1			;保存された標準入力ハンドル
saved_stdout::
	.dc.w	-1			;保存された標準出力ハンドル
saved_stderr::
	.dc.w	-1			;保存された標準エラー出力ハンドル
	.text

;----------------------------------------------------------------
;標準ハンドルを復元する
restore_std::
	if	<cmpi.w #-1,saved_stdin>,ne
		clr.w	-(sp)			;標準入力ハンドル
		move.w	saved_stdin,-(sp)	;保存された標準入力ハンドル
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,sp
		move.w	#-1,saved_stdin		;保存された標準入力ハンドル
	endif
	if	<cmpi.w #-1,saved_stdout>,ne
		move.w	#1,-(sp)		;標準出力ハンドル
		move.w	saved_stdout,-(sp)	;保存された標準出力ハンドル
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,sp
		move.w	#-1,saved_stdout	;保存された標準出力ハンドル
	endif
	if	<cmpi.w #-1,saved_stderr>,ne
		move.w	#2,-(sp)		;標準エラー出力ハンドル
		move.w	saved_stderr,-(sp)	;保存された標準エラー出力ハンドル
		DOS	_DUP2
		DOS	_CLOSE
		addq.l	#4,sp
		move.w	#-1,saved_stderr	;保存された標準エラー出力ハンドル
	endif
	rts

;----------------------------------------------------------------
;NULを開く
open_nul::
	clr.w	-(sp)			;入力
	peastrdata	'nul'
	DOS	_OPEN
	addq.l	#6,sp
	move.w	d0,nul_in_handle	;NUL入力ハンドル
	move.w	#1,-(sp)		;出力
	peastrdata	'nul'
	DOS	_OPEN
	addq.l	#6,sp
	move.w	d0,nul_out_handle	;NUL出力ハンドル
	rts

	.data
	.even
nul_in_handle::
	.dc.w	-1			;NUL入力ハンドル
nul_out_handle::
	.dc.w	-1			;NUL出力ハンドル
	.text

;----------------------------------------------------------------
;NULを閉じる
close_nul::
	if	<cmpi.w #-1,nul_in_handle>,ne
		move.w	nul_in_handle,-(sp)		;NUL入力ハンドル
		DOS	_CLOSE
		addq.l	#2,sp
		move.w	#-1,nul_in_handle		;NUL入力ハンドル
	endif
	if	<cmpi.w #-1,nul_out_handle>,ne
		move.w	nul_out_handle,-(sp)		;NUL出力ハンドル
		DOS	_CLOSE
		addq.l	#2,sp
		move.w	#-1,nul_out_handle		;NUL出力ハンドル
	endif
	rts

  .endif ;HIDE_ASSEMBLER

;----------------------------------------------------------------
;ソースファイルを作る
create_source::
	if	<tst.b inst_arg>,ne
		lea.l	source_file,a0		;ソースファイル名
		lea.l	temp_directory,a1	;テンポラリディレクトリ名
		bsr	strcpy
		leastrdata	'opti????.s',a1
		bsr	strcpy
		move.w	#$0020,-(sp)
		pea.l	source_file		;ソースファイル名
		DOS	_MAKETMP
		addq.l	#6,sp
		move.l	d0,d1
		if	mi
			lea.l	string_buffer,a0	;文字列バッファ
			leastrdata	'cannot create ',a1
			bsr	strcpy
			lea.l	source_file,a1		;ソースファイル名
			bsr	strcpy
			bsr	crlf
			lea.l	string_buffer,a0	;文字列バッファ
  .if ERROR_OUTPUT
			bsr	eprint
  .else
			bsr	print
  .endif
			goto	abort			;中止
		endif
		st.b	source_created		;ソースファイル作成済みフラグ
		move.w	d1,-(sp)
		pea.l	source_code		;ソースコード
		DOS	_FPUTS
		addq.l	#6,sp
		move.w	d1,-(sp)
		DOS	_CLOSE
		addq.l	#2,sp
	else
		lea.l	source_file,a0		;ソースファイル名
		lea.l	file_arg,a1		;-f ファイル名
		bsr	strcpy
	endif
	if	<tst.b verbose_flag>,ne
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'source file: ',a1
		bsr	strcpy
		lea.l	source_file,a1		;ソースファイル名
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
		bsr	print
	endif
	rts

	.data
source_created::
	.dc.b	0			;ソースファイル作成済みフラグ
	.bss
source_file::
	.ds.b	1024			;ソースファイル名
	.text

;----------------------------------------------------------------
;ソースファイルを消す
delete_source::
	if	<tst.b source_created>,ne
		pea.l	source_file		;ソースファイル名
		DOS	_DELETE
		addq.l	#4,sp
		sf.b	source_created		;ソースファイル作成済みフラグ
	endif
	rts

;----------------------------------------------------------------
;オブジェクトファイルを開く
open_object::
	clr.w	-(sp)
	pea.l	object_file		;オブジェクトファイル名
	DOS	_OPEN
	addq.l	#6,sp
	if	<tst.l d0>,mi
		lea.l	string_buffer,a0	;文字列バッファ
		leastrdata	'cannot open ',a1
		bsr	strcpy
		lea.l	object_file,a1		;オブジェクトファイル名
		bsr	strcpy
		bsr	crlf
		lea.l	string_buffer,a0	;文字列バッファ
  .if ERROR_OUTPUT
		bsr	eprint
  .else
		bsr	print
  .endif
		goto	abort			;中止
	endif
	move.w	d0,object_handle
	rts

	.data
	.even
object_handle::
	.dc.w	-1			;オブジェクトファイルハンドル
	.text

;----------------------------------------------------------------
;オブジェクトファイルを閉じる
close_object::
	if	<cmpi.w #-1,object_handle>,ne
		move.w	object_handle,-(sp)	;オブジェクトファイルハンドル
		DOS	_CLOSE
		addq.l	#2,sp
		move.w	#-1,object_handle	;オブジェクトファイルハンドル
	endif
	rts

;----------------------------------------------------------------
;オブジェクトファイルを消す
delete_object::
	if	<tst.b object_created>,ne
		pea.l	object_file		;オブジェクトファイル名
		DOS	_DELETE
		addq.l	#4,sp
		sf.b	object_created		;-1=オブジェクトファイル作成済み
	endif
	rts

;----------------------------------------------------------------
;SRAMの内容を保存する
save_sram::
	if	<tst.b sram_flag>,ne
		lea.l	sram_data,a0		;保存されたSRAMデータ
		lea.l	$00ED0100,a1
		move.w	#$3F00/4-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
		st.b	sram_saved		;SRAM保存済みフラグ
	endif
	rts

	.data
sram_saved::
	.dc.b	0			;SRAM保存済みフラグ
	.bss
	.even
sram_data::
	.ds.l	$3F00/4			;保存されたSRAMデータ
	.text

;----------------------------------------------------------------
;SRAMの内容を復元する
restore_sram::
	if	<tst.b sram_saved>,ne
		unlocksram			;SRAM書き込み許可
		lea.l	$00ED0100,a0
		lea.l	sram_data,a1		;保存されたSRAMデータ
		move.w	#$3F00/4-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
		locksram			;SRAM書き込み禁止
		sf.b	sram_saved		;SRAM保存済みフラグ
	endif
	rts


;----------------------------------------------------------------
;コードをダンプする
dump_code::
	push	d0/a0-a4
	movea.l	code_start,a3		;コードの先頭アドレス
	move.l	a3,d0
	and.w	#-16,d0			;16の倍数に切り捨てる
	movea.l	d0,a1			;表示開始アドレス
	movea.l	code_end,a4		;コードの末尾アドレス
	move.l	a4,d0
	add.l	#16-1,d0		;16の倍数に切り上げる
	and.w	#-16,d0
	movea.l	d0,a2			;表示終了アドレス
	docontinue
		move.l	a1,d0
		and.w	#16-1,d0
		if	eq
			lea.l	string_buffer,a0	;文字列バッファ
			move.l	a1,d0
			bsr	h8tos
			move.b	#' ',(a0)+
		endif
		move.b	#' ',(a0)+
		ifand	<cmpa.l a3,a1>,hs,<cmpa.l a4,a1>,lo	;コードの範囲内
			move.w	(a1),d0
			bsr	h4tos
		else				;コードの範囲外
			move.b	#'.',(a0)+
			move.b	#'.',(a0)+
			move.b	#'.',(a0)+
			move.b	#'.',(a0)+
		endif
		addq.l	#2,a1
		move.l	a1,d0
		and.w	#16-1,d0
		if	eq
			bsr	crlf
			lea.l	string_buffer,a0	;文字列バッファ
			bsr	print
		endif
	while	<cmpa.l a2,a1>,lo
	pop
	rts


;----------------------------------------------------------------
;計測サブルーチン
;	スーパーバイザモードで呼び出すこと
;<a0.l:計測するサブルーチン。d0-d7/a0-a4を自由に使える
;>d0.l:所要時間(us)。0～12799
optime::
	push	d1-d7/a0-a6
	movea.l	a0,a5
aTCDCR	reg	a6
	lea.l	MFP_TCDCR,aTCDCR
;割り込み禁止
	di
;タイマ保存
	lea.l	timer_ierb(pc),a0
	move.b	MFP_IERB-MFP_TCDCR(aTCDCR),(a0)	;timer_ierb
	move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(a0)	;timer_imrb
	move.b	MFP_TCDCR-MFP_TCDCR(aTCDCR),-(a0)	;timer_tcdcr
	st.b	-(a0)			;timer_saved
;タイマ設定
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み停止
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み禁止
	move.b	#0,(aTCDCR)		;Timer-C/Dカウント停止
	do
	while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ
;リハーサルと本番
	clr.b	-(sp)			;$00=リハーサル,$FF=本番
	do
	;カウント開始
		move.b	#0,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタクリア
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
		move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/Dカウント開始
						;Timer-Cは1/200プリスケール(50us)
						;Timer-Dは1/4プリスケール(1us)
	;計測
		jsr	(a5)
	;カウント停止
		move.b	#0,(aTCDCR)		;Timer-C/Dカウント停止
		do
		while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ
		not.b	(sp)
	while	ne
	tst.b	(sp)+
;タイマ取得
	moveq.l	#0,d0
	moveq.l	#0,d1
	sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-Cカウント数
	sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-Dカウント数(オーバーフローあり)
;タイマ復元
	lea.l	timer_saved(pc),a0
	move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタ復元
	move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
	sf.b	(a0)+				;timer_saved
	move.b	(a0)+,(aTCDCR)			;timer_tcdcr
	move.b	(a0)+,MFP_IMRB-MFP_TCDCR(aTCDCR)	;timer_imrb
	move.b	(a0),MFP_IERB-MFP_TCDCR(aTCDCR)	;timer_ierb
;割り込み許可
	ei
;カウンタ合成
	mulu.w	#50,d0
	if	<cmp.b d1,d0>,hi
		add.w	#256,d0
	endif
	move.b	d1,d0
	move.l	d0,d1
;終了
	move.l	d1,d0
	pop
	rts

;タイマを復元する
restore_timer::
	push	a0/a6
	lea.l	MFP_TCDCR,aTCDCR
	lea.l	timer_saved(pc),a0
	if	<tst.b (a0)>,ne
		di
		move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタ復元
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
		sf.b	(a0)+				;timer_saved
		move.b	(a0)+,(aTCDCR)			;timer_tcdcr
		move.b	(a0)+,MFP_IMRB-MFP_TCDCR(aTCDCR)	;timer_imrb
		move.b	(a0),MFP_IERB-MFP_TCDCR(aTCDCR)	;timer_ierb
		ei
	endif
	pop
	rts

	.data
timer_saved::
	.dc.b	0			;-1=以下保存済み
timer_tcdcr::
	.dc.b	0			;保存されたTCDCR
timer_imrb::
	.dc.b	0			;保存されたIMRB
timer_ierb::
	.dc.b	0			;保存されたIERB
	.text


;----------------------------------------------------------------
;オブジェクトファイルの文字列を読み飛ばす
;>d0.l:読み飛ばしたバイト数。0を含む。偶数
object_string::
	push	d1
	moveq.l	#0,d1
	do
		do
			addq.l	#1,d1
			bsr	object_byte
			break2	mi
		while	ne
		if	<btst.l #0,d1>,ne
			addq.l	#1,d1
			bsr	object_byte
			break	mi
		endif
		move.l	d1,d0
	while	f
	pop
	tst.l	d0
	rts

;----------------------------------------------------------------
;オブジェクトファイルから1ロングワード読み出す
;>d0.l:読み出したデータ
object_long::
	clr.l	-(sp)
	do
		bsr	object_byte
		break	mi
		move.b	d0,(sp)
		bsr	object_byte
		break	mi
		move.b	d0,1(sp)
		bsr	object_byte
		break	mi
		move.b	d0,2(sp)
		bsr	object_byte
		break	mi
		move.b	d0,3(sp)
		move.l	(sp),d0
	while	f
	addq.l	#4,sp
	rts

;----------------------------------------------------------------
;オブジェクトファイルから1ワード読み出す
;>d0.l:読み出したデータ
object_word::
	clr.l	-(sp)
	do
		bsr	object_byte
		break	mi
		move.b	d0,2(sp)
		bsr	object_byte
		break	mi
		move.b	d0,3(sp)
		move.l	(sp),d0
	while	f
	addq.l	#4,sp
	rts

;----------------------------------------------------------------
;オブジェクトファイルから1バイト読み出す
;>d0.l:読み出したデータ
object_byte::
	move.w	object_handle,-(sp)
	DOS	_FGETC
	addq.l	#2,sp
	if	<tst.l d0>,pl
		and.l	#$000000FF,d0
	endif
	rts


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
	bsr	nonspace		;空白を読み飛ばす
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
;キャッシュフラッシュ
cache_flush::
	push	d0-d1
	if	<is68000 d0>,ne
		moveq.l	#3,d1
		IOCS	_SYS_STAT
	endif
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

  .if ERROR_OUTPUT
;----------------------------------------------------------------
;文字列をエラー表示する
;<a0.l:文字列の先頭
;>a0.l:文字列の先頭
eprint::
	push	d0
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#2,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts
  .endif

;----------------------------------------------------------------
;符号なし整数を16進数4桁の文字列に変換する
;<d0.w:符号なし整数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
h4tos::
	push	d1-d2
	moveq.l	#4-1,d1
	for	d1
		rol.w	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	h8tos_hex(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

;----------------------------------------------------------------
;符号なし整数を16進数8桁の文字列に変換する
;<d0.l:符号なし整数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
h8tos::
	push	d1-d2
	moveq.l	#8-1,d1
	for	d1
		rol.l	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	h8tos_hex(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

h8tos_hex:
	.dc.b	'0123456789ABCDEF'
	.even

;----------------------------------------------------------------
;空白以外の文字まで読み飛ばす
;<a0.l:文字列
;>d0.l:空白以外の文字または0
;>a0.l:空白以外の文字または0の位置
;>z:eq=0
nonspace::
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
;<a0.l:文字列の先頭
;>a0.l:文字列の先頭
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
;文字列を末尾まで読み飛ばす
;<a0.l:文字列の先頭
;>a0.l:文字列の末尾の0の位置
strchr0::
	do
		tst.b	(a0)+
	while	ne
	subq.l	#1,a0
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
;小文字にする
;<d0.b:文字
;>d0.b:文字
tolower::
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;大文字
		add.b	#'a'-'A',d0		;小文字にする
	endif
	rts

;----------------------------------------------------------------
;符号なし整数を10進数の文字列に変換する
;<d0.l:符号なし整数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
utos::
	push	d0-d2/a1
	if	<tst.l d0>,eq
		move.b	#'0',(a0)+
	else
		lea.l	utos_table(pc),a1
		do
			move.l	(a1)+,d1
		while	<cmp.l d1,d0>,lo	;引けるところまで進む
		do
			moveq.l	#'0'-1,d2
			do
				addq.b	#1,d2
				sub.l	d1,d0
			while	hs			;引ける回数を数える
			move.b	d2,(a0)+
			add.l	d1,d0			;引きすぎた分を加え戻す
			move.l	(a1)+,d1
		while	ne
	endif
	clr.b	(a0)
	pop
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
;y/n入力待ち
;	メッセージを表示してyまたはnが入力されるまで待って改行する
;	^Cで中断できる
;<a0.l:メッセージ
;>d0.l:'y'=yes,'n'=no
yesno::
	push	a0
	bsr	print
	do
		DOS	_GETCHAR		;標準入力から1バイト入力(標準出力にエコーバックする)
		bsr	tolower
	whileand	<cmp.b #'y',d0>,ne,<cmp.b #'n',d0>,ne
	leastrdata	<13,10>,a0
	bsr	print
	pop
	rts

;----------------------------------------------------------------
;プログラム終了
	.end	program_start

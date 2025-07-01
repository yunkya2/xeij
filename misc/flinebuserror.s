;========================================================================================
;  flinebuserror.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;
;	flinebuserror.x
;		MC68030でDOSコールの_GETENVを古い番号$FF53で呼び出してバスエラーを発生させる実験です。
;		バスエラーが発生したときはbus errorと、さもなくば環境変数pathの内容が表示されます。
;		MC68030では$FF53がcpRESTORE (a3)なので、$FF53を実行すると(a3)がリードされ、a3の内容によってはバスエラーが発生します。
;		この問題が、_GETENVを新しい番号$FF83に移動させなければならなかった理由であると考えられます。
;
;	更新履歴
;		2024-11-29
;			公開。
;
;----------------------------------------------------------------------------------------

	.include	doscall.mac

	.text

;スーパーバイザモードに移行する
	clr.l	-(sp)
	DOS	_SUPER
	move.l	d0,(sp)

;バスエラーが発生するアドレスを用意する
	movea.l	#$00E80400,a3		;a3=バスエラーが発生するアドレス

;スーパーバイザスタックポインタを保存する
	movea.l	sp,a4			;a4=スーパーバイザスタックポインタ

;バスエラー例外ベクタを保存して変更する
	move.l	$0008.w,a5		;a5=元のバスエラー例外ベクタ
	move.l	#buserror,$0008.w

;環境変数pathの値を取り出す
	lea.l	name,a0			;a0=環境変数の名前
	suba.l	a1,a1			;a1=環境の領域。0は実行中のプロセス
	lea.l	value,a2		;a2=環境変数の値
	clr.b	(a2)			;環境変数がなければ空とみなす
	movem.l	a0-a2,-(sp)
	DOS	_V2_GETENV		;X68030のときここでバスエラーが発生する
	lea.l	12(sp),sp

;バスエラー例外ベクタを復元する
	move.l	a5,$0008.w

;環境変数pathの値を表示する
	move.l	a0,-(sp)		;環境変数の名前
	DOS	_PRINT
	pea.l	separator		;区切り
	DOS	_PRINT
	move.l	a2,-(sp)		;環境変数の値
	DOS	_PRINT
	pea.l	crlf			;改行
	DOS	_PRINT
	lea.l	16(sp),sp

	bra	user_exit

;バスエラーのとき
buserror:

;スーパーバイザスタックポインタを復元する
	movea.l	a4,sp			;元のスーパーバイザスタックポインタ

;バスエラー例外ベクタを復元する
	move.l	a5,$0008.w		;元のバスエラー例外ベクタ

;バスエラーのメッセージを表示する
	pea.l	message			;'bus error'
	DOS	_PRINT
	addq.l	#4,sp

user_exit:

;ユーザモードに復帰する
	DOS	_SUPER
	addq.l	#4,sp

;終了する
	DOS	_EXIT

	.data

;環境変数の名前
name:
	.dc.b	'path',0

;'bus error'
message:
	.dc.b	'bus error'
;改行
crlf:
	.dc.b	13,10,0
;区切り
separator:
	.dc.b	'=',0

	.bss

;環境変数の値
value:
	.ds.b	1024

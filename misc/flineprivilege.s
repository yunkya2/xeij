;========================================================================================
;  flineprivilege.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;
;	flineprivilege.x
;		MC68030でユーザモードのとき$FE00～$FFFFのどれで特権違反例外が発生するか調べます。
;		「.」はFライン例外が発生したものを示しており、「!」は特権違反例外が発生したものを示しています。
;		cpSAVEまたはcpRESTOREでアドレッシングモードが正しい場合に限り、Fライン例外ではなく特権違反例外が発生します。
;
;	更新履歴
;		2024-11-29
;			公開。
;
;----------------------------------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac
	.include	control2.mac

	.text

;結果のバッファを準備する
	lea.l	result_buffer,a2	;a2=結果のバッファのポインタ

;自己書き換えするためキャッシュをOFFにする
	moveq.l	#-1,d3			;d3=元のキャッシュモード
	movem.l	sp,-(sp)
	cmpa.l	(sp)+,sp
	if	ne			;68020以上
		moveq.l	#0,d2
		moveq.l	#4,d1
		IOCS	_SYS_STAT
		move.l	d0,d3
	endif

;特権違反例外ベクタを保存して変更する
	moveq.l	#$08,d1			;特権違反例外
	lea.l	privilege_routine,a1	;特権違反例外処理ルーチン
	IOCS	_B_INTVCS
	movea.l	d0,a3			;a3=元の特権違反例外ベクタ

;Fライン例外ベクタを保存して変更する
	moveq.l	#$0B,d1			;Fライン例外
	lea.l	fline_routine,a1	;Fライン例外処理ルーチン
	IOCS	_B_INTVCS
	movea.l	d0,a4			;a4=元のFライン例外ベクタ

;$FE00～$FFFFを実行する
	move.w	#$FE00,d1		;d1=命令コード
	do
		move.w	d1,@f			;自己書き換え
		nop
		.align	4,$4E71			;おまじない
	@@:	nop
		addq.w	#1,d1
		moveq.l	#63,d0			;64桁毎に
		and.w	d1,d0
		if	eq
			move.b	#13,(a2)+		;改行
			move.b	#10,(a2)+
		else
			moveq.l	#15,d0			;16桁毎に
			and.w	d1,d0
			if	eq
				move.b	#' ',(a2)+		;空白
			endif
		endif
	while	<tst.w d1>,ne

;特権違反例外ベクタを復元する
	moveq.l	#$08,d1			;特権違反例外
	movea.l	a3,a1			;元の特権違反例外ベクタ
	IOCS	_B_INTVCS

;Fライン例外ベクタを復元する
	moveq.l	#$0B,d1			;Fライン例外
	movea.l	a4,a1			;元のFライン例外ベクタ
	IOCS	_B_INTVCS

;キャッシュモードを復元する
	move.l	d3,d2			;元のキャッシュモード
	if	pl			;68020以上
		moveq.l	#4,d1
		IOCS	_SYS_STAT
	endif

;結果を表示する
	clr.b	(a2)
	pea.l	result_buffer
	DOS	_PRINT
	addq.l	#4,sp

;終了する
	DOS	_EXIT

;特権違反例外処理ルーチン
privilege_routine:
	move.b	#'!',(a2)+
	addq.l	#2,2(sp)		;次の命令に進む
	rte

;Fライン例外処理ルーチン
fline_routine:
	move.b	#'.',(a2)+
	addq.l	#2,2(sp)		;次の命令に進む
	rte

	.bss

;結果のバッファ
result_buffer:
	.ds.b	4096

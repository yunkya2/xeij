;----------------------------------------------------------------
;
;	_HIMEM
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ
	.include	t09version.equ

;__DEBUG__	equ	1

;TS16_VERSION
;	TS16DRV.Xでのバージョン
;	TS16DRV.Xの最後のバージョンが$12なので、$13にしておく
TS16_VERSION	equ	$13

	.cpu	68060

;----------------------------------------------------------------
;IOCS _HIMEM($F8)	ハイメモリ操作
;	TS-6BE16の添付ディスクに入っているHIMEM.SYS v1.0とほぼ上位互換
;	拡張メモリTS-6BE16管理ドライバ(TS16DRV.X)とほぼ上位互換
;<d1.w:コマンドコード
;	1	HIMEM_MALLOC
;		ブロックの確保
;			下位アドレスから確保する
;			<d2.l:確保するブロックのサイズ
;			>d0.l:0=成功,-1=失敗
;			>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;	2	HIMEM_FREE
;		ブロックの開放
;			<d2.l:開放するブロックのユーザ領域の先頭
;				0=実行中のプロセスが確保したブロックをすべて開放
;			>d0.l:0=成功,-1=失敗
;	3	HIMEM_GETSIZE
;		確保できるサイズの取得
;			>d0.l:確保できるサイズの合計
;			>d1.l:一度に確保できる最大のサイズ
;	4	HIMEM_RESIZE
;		ブロックのサイズ変更
;			ブロックは移動しない
;			新しいサイズが0ならばブロックを開放する
;			<d2.l:サイズを変更するブロックのユーザ領域の先頭
;			<d3.l:新しいサイズ(0=ブロックを開放する)
;			>d0.l:0=成功,-1=失敗
;	以降のコールはHIMEM.SYS v1.0にはない
;	5	HIMEM_VERSION
;		_HIMEMのバージョンの取得
;			>d0.l:'060T'
;			>d1.l:バージョン
;	6	HIMEM_CALLOC
;		配列のためのブロックの確保
;			下位アドレスから確保する
;			確保したブロックは0で初期化される
;			<d2.l:配列要素数
;			<d3.l:配列要素サイズ
;			>d0.l:0=成功,-1=失敗
;			>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;	7	HIMEM_REALLOC
;		ブロックのサイズ変更
;			ブロックが移動することがある
;			移動するとき新しいブロックは下位から確保する
;			移動してもブロックを確保したプロセスは変化しない
;			新しいサイズが0ならばブロックを開放する
;			<d2.l:サイズを変更するブロックのユーザ領域の先頭
;			<d3.l:新しいサイズ(0=ブロックを開放する)
;			>d0.l:0=成功,-1=失敗
;			>a1.l:0=失敗,0以外=移動後のブロックのユーザ領域の先頭
;	8	HIMEM_MALLOC2
;		ブロックの確保
;			<d2.l:確保するサイズ
;			<d3.w:bit15=プロセス指定フラグ
;					0	実行中のプロセス
;					1	d4.lを親プロセスとして使用する
;				下位8bit=モード
;					0	下位から
;					1	必要最小ブロックから
;					2	上位から
;					3	最大ブロックから
;			<d4.l:(d3.wのbit15が1のとき)親プロセスのメモリ管理テーブル
;			>d0.l:0=成功,$81xxxxxx=確保できる最大のサイズ,$82000000=まったく確保できない
;			>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;	9	HIMEM_PSFREE
;		特定のプロセスが確保したブロックの開放
;			子プロセスが確保したブロックも開放する
;			<d2.l:開放するブロックを確保したプロセスのメモリ管理テーブル
;			>d0.l:0=成功,-1=失敗
;	10	HIMEM_GETAREA
;		_HIMEMでアクセスできるメモリ空間の取得
;			>d0.l:メモリ空間の先頭(先頭のブロックのヘッダ),-1=失敗
;			>d1.l:メモリ空間の末尾+1,-1=失敗
;?d0,d1-d7/a0-a6は返却に使われるものを除いて破壊されない
	.dc.b	'060T'
	.dc.b	'TS16DRV',TS16_VERSION
	.dc.b	'HIMEM',0
iocsHimem::
	cmp.w	#(himemJumpTableEnd-himemJumpTable)/4,d1
	bcc	himemUnknownCall
	jmp	([himemJumpTable,pc,d1.w*4])

himemReserved:
himemUnknownCall:
	moveq.l	#-1,d0
	rts

himemJumpTable:
	.dc.l	himemReserved
	.dc.l	himemMalloc
	.dc.l	himemFree
	.dc.l	himemGetSize
	.dc.l	himemResize
	.dc.l	himemVersion
	.dc.l	himemCalloc
	.dc.l	himemRealloc
	.dc.l	himemMalloc2
	.dc.l	himemPsfree
	.dc.l	himemGetArea
himemJumpTableEnd:

;----------------------------------------------------------------
;_HIMEM	1	ブロックの確保
;	下位アドレスから確保する
;<d2.l:確保するブロックのサイズ
;>d0.l:0=成功,-1=失敗
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
himemMalloc::
  debug '|himemMalloc in (size)=',1,d2
	movem.l	d4/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemMallocFailed
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	bsr	malloc20		;ブロックの確保(下位から)
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bpl	himemMallocEnd
	moveq.l	#-1,d0
himemMallocEnd:
  debug '|himemMalloc out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d4/a4-a5
	rts

himemMallocFailed:
	suba.l	a1,a1
	bra	himemMallocEnd

;----------------------------------------------------------------
;_HIMEM	2	ブロックの開放
;<d2.l:開放するブロックのユーザ領域の先頭
;	0=実行中のプロセスが確保したブロックをすべて開放
;>d0.l:0=成功,-1=失敗
himemFree::
  debug '|himemFree in (ptr)=',1,d2
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemFreeEnd
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	tst.l	d2
	beq	himemFreeProc		;実行中のプロセスが確保したブロックをすべて開放
	bsr	free
;<d0.l:0=成功,-1=ヘッダが見つからない
himemFreeEnd:
  debug '|himemFree out (err)=',1,d0
	movem.l	(sp)+,a4-a5
	rts

;実行中のプロセスが確保したブロックをすべて開放
himemFreeProc:
	move.l	d4,-(sp)
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	bsr	psfree
;<d0.l:0(常に成功する)
	move.l	(sp)+,d4
	tst.l	d0
	bra	himemFreeEnd

;----------------------------------------------------------------
;_HIMEM	3	確保できるサイズの取得
;>d0.l:確保できるサイズの合計
;>d1.l:一度に確保できる最大のサイズ
;*d0-d1
himemGetSize::
  debug '|himemGetSize in',0
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemGetSizeFailed
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	bsr	getSize
;<d0.l:確保できるサイズの合計
;<d1.l:一度に確保できる最大のサイズ
himemGetSizeEnd:
  debug '|himemGetSize out (ttl,max)=',2,d0,d1
	movem.l	(sp)+,a4-a5
	rts

himemGetSizeFailed:
	moveq.l	#0,d0
	moveq.l	#0,d1
	bra	himemGetSizeEnd

;----------------------------------------------------------------
;_HIMEM	4	ブロックのサイズ変更
;	ブロックは移動しない
;	新しいサイズが0ならばブロックを開放する
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ(0=ブロックを開放する)
;>d0.l:0=成功,-1=失敗
;*d0
himemResize::
  debug '|himemResize in (ptr,size)=',2,d2,d3
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemResizeEnd
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	bsr	resizeOrFree
;<d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
	bpl	himemResizeEnd
	moveq.l	#-1,d0
himemResizeEnd:
  debug '|himemResize out (err)=',1,d0
	movem.l	(sp)+,a4-a5
	rts

;----------------------------------------------------------------
;_HIMEM	5	_HIMEMのバージョンの取得
;>d0.l:'060T'
;>d1.l:バージョン
;*d0-d1
himemVersion::
	move.l	#'060T',d0
	move.l	#VERSION,d1
	rts

;----------------------------------------------------------------
;_HIMEM	6	配列のためのブロックの確保
;	下位アドレスから確保する
;	確保したブロックは0で初期化される
;<d2.l:配列要素数
;<d3.l:配列要素サイズ
;>d0.l:0=成功,-1=失敗
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
himemCalloc::
  debug '|himemCalloc in (cnt,size)=',2,d2,d3
	movem.l	d1-d2/d4/a2/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemCallocFailed
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	d2,d0
	move.l	d3,d1
	bsr	imul			;32bit×32bit→64bit乗算(符号なし)
	tst.l	d0
	bne	himemCallocFailed	;オーバーフロー
	move.l	d1,d2
	bmi	himemCallocFailed	;オーバーフロー
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	bsr	malloc20		;ブロックの確保(下位から)
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bmi	himemCallocFailed	;確保できない
	movea.l	a1,a2			;確保したブロックのユーザ領域の先頭
	subq.l	#1,d2
	bcs	himemCallocDone		;サイズが0
	moveq.l	#0,d0
	lsr.l	#4,d2			;(サイズ-1)/16=(サイズ+15)/16-1
	swap.w	d2
himemCallocClear1:
	swap.w	d2
himemCallocClear0:
	move.l	d0,(a2)+
	move.l	d0,(a2)+
	move.l	d0,(a2)+
	move.l	d0,(a2)+
	dbra	d2,himemCallocClear0
	swap.w	d2
	dbra	d2,himemCallocClear1
himemCallocDone:
	moveq.l	#0,d0
himemCallocEnd:
  debug '|himemCalloc out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d2/d4/a2/a4-a5
	rts

himemCallocFailed:
	suba.l	a1,a1
	moveq.l	#-1,d0
	bra	himemCallocEnd

;----------------------------------------------------------------
;_HIMEM	7	ブロックのサイズ変更
;	ブロックが移動することがある
;	移動するとき新しいブロックは下位から確保する
;	移動してもブロックを確保したプロセスは変化しない
;	新しいサイズが0ならばブロックを開放する
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ(0=ブロックを開放する)
;>d0.l:0=成功,-1=失敗
;>a1.l:0=失敗,0以外=移動後のブロックのユーザ領域の先頭
himemRealloc::
  debug '|himemRealloc in (ptr,size)=',2,d2,d3
	movem.l	d1-d2/a2/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemReallocFailed
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	bsr	reallocOrFree
;>d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=移動後のブロックのユーザ領域の先頭
	bmi	himemReallocFailed
himemReallocEnd:
  debug '|himemRealloc out (err,ptr,)=',2,d0,a1
	movem.l	(sp)+,d1-d2/a2/a4-a5
	rts

himemReallocFailed:
	suba.l	a1,a1
	moveq.l	#-1,d0
	bra	himemReallocEnd

;----------------------------------------------------------------
;_HIMEM	8	ブロックの確保
;<d2.l:確保するサイズ
;<d3.w:bit15=プロセス指定フラグ
;		0	実行中のプロセス
;		1	d4.lを親プロセスとして使用する
;	下位8bit=モード
;		0	下位から
;		1	必要最小ブロックから
;		2	上位から
;		3	最大ブロックから
;<d4.l:(d3.wのbit15が1のとき)親プロセスのメモリ管理テーブル
;>d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;*d0/a1
himemMalloc2::
  debug '|himemMalloc2 in (size,mode,proc)=',3,d2,d3,d4
	movem.l	d4/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemMalloc2Failed
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.w	d3,d0
	bmi	@f
	bsr	getProc
@@:
;<d4.l:実行中のプロセスのメモリ管理テーブル
	and.w	#$00FF,d0
	cmp.w	#4,d0
	bcc	himemMalloc2Failed
	jsr	([malloc2Table,pc,d0.w*4])	;ブロックの確保
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bpl	himemMalloc2End
	moveq.l	#-1,d0
himemMalloc2End:
  debug '|himemMalloc2 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d4/a4-a5
	rts

himemMalloc2Failed:
	suba.l	a1,a1
	moveq.l	#-1,d0
	bra	himemMalloc2End

;----------------------------------------------------------------
;_HIMEM	9	特定のプロセスが確保したブロックの開放
;	子プロセスが確保したブロックも開放する
;<d2.l:開放するブロックを確保したプロセスのメモリ管理テーブル
;>d0.l:0=成功,-1=失敗
;*d0
himemPsfree::
  debug '|himemPsfree in (proc)=',1,d2
	movem.l	d4/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemPsfreeEnd
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	d2,d4
;<d4.l:開放するブロックを確保したプロセスのメモリ管理テーブル
	bsr	psfree
;<d0.l:0(常に成功する)
himemPsfreeEnd:
  debug '|himemPsfree out (err)=',1,d0
	movem.l	(sp)+,d4/a4-a5
	rts

;----------------------------------------------------------------
;_HIMEM	10	_HIMEMでアクセスできるメモリ空間の取得
;>d0.l:メモリ空間の先頭(先頭のブロックのヘッダ),-1=失敗
;>d1.l:メモリ空間の末尾+1,-1=失敗
;*d0-d1
himemGetArea::
  debug '|himemGetArea in',0
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemGetAreaFailed
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	a4,d0
	move.l	a5,d1
;<d0.l:メモリ空間の先頭(先頭のブロック)
;<d1.l:メモリ空間の末尾+1
himemGetAreaEnd:
  debug '|himemGetArea out (top,btm)=',2,d0,d1
	movem.l	(sp)+,a4-a5
	rts

himemGetAreaFailed:
	moveq.l	#-1,d0
	moveq.l	#-1,d1
	bra	himemGetAreaEnd

;----------------------------------------------------------------
;----------------------------------------------------------------
;拡張メモリ空間をアクセスできるか調べる
;	新しいmpusw.rは_HIMEM使用中に68000モードに切り替えられないようになっている
;>d0.l:0=成功,-1=失敗
;>a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;>a5.l:メモリ空間の末尾+1(16バイトアラインメント)
himemAreaSet::
	tst.l	himemAreaSize
	beq	9f			;拡張メモリ空間使用不可
	movea.l	himemAreaStart,a4
	movea.l	himemAreaEnd,a5
	moveq.l	#0,d0
	rts

9:	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;32bit×32bit→64bit乗算(符号なし)
;<d0.l:被乗数
;<d1.l:乗数
;>d0.l:結果(上位)
;>d1.l:結果(下位)
;*d0-d1
imul::
	movem.l	d2-d4,-(sp)
	move.l	d0,d3
	move.l	d1,d4
	swap.w	d3
	swap.w	d4
	move.w	d3,d2
	mulu.w	d1,d2
	mulu.w	d0,d1
	mulu.w	d4,d0
	mulu.w	d3,d4
	add.l	d2,d0
	clr.w	d3
	addx.w	d3,d3
	swap.w	d1
	add.w	d0,d1
	swap.w	d1
	move.w	d3,d0
	swap.w	d0
	addx.l	d4,d0
	movem.l	(sp)+,d2-d4
	rts

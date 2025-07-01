;----------------------------------------------------------------
;
;	メモリ管理ルーチン
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;ブロックの確保を行うルーチンのテーブル
malloc2Table::
	.dc.l	malloc20		;下位から
	.dc.l	malloc21		;必要最小ブロックから
	.dc.l	malloc22		;上位から
	.dc.l	malloc23		;最大ブロックから

;----------------------------------------------------------------
;ブロックの確保(下位から)
;<d2.l:確保するサイズ
;<d4.l:親プロセスのメモリ管理テーブル
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;*d0/a1
malloc20::
	movem.l	d1-d2/a2,-(sp)
  debug '|malloc20 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;念のため
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;先頭のブロック
malloc20Loop:
	cmp.l	a5,d0
	bcc	malloc20Failed		;見つからなかった
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc20Next		;ロックされている
	bsr	splitBlock		;分割してできるブロックのヘッダとサイズを求める
	bmi	malloc20Next		;分割できない
	cmp.l	d2,d1			;サイズが足りているか
	bhs	malloc20Found		;見つかった
malloc20Next:
	move.l	(Next,a2),d0		;次のブロックへ
	bne	malloc20Loop
malloc20Failed:
	suba.l	a1,a1
	bsr	getSize
;<d0.l:確保できるサイズの合計
;<d1.l:一度に確保できる最大のサイズ
	move.l	d1,d0			;最大のサイズ
	or.l	#$80000000,d0		;最上位ビットだけセットする
	bra	malloc20End

malloc20Found:
	bsr	insertHeader		;ヘッダを挿入する
	lea.l	(User,a1),a1		;ユーザ領域の先頭
	add.l	a1,d2			;ユーザ領域の末尾+1
	move.l	d2,(-User+Tail,a1)	;ユーザ領域の末尾+1
	move.l	d4,(-User+Proc,a1)	;親プロセスのメモリ管理テーブル
	moveq.l	#0,d0
malloc20End:
  debug '|malloc20 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d2/a2
	rts

;----------------------------------------------------------------
;ブロックの確保(必要最小ブロックから)
;<d2.l:確保するサイズ
;<d4.l:親プロセスのメモリ管理テーブル
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;*d0/a1
malloc21::
	movem.l	d1-d3/d5/a2-a4,-(sp)
  debug '|malloc21 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;念のため
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;先頭のブロック
	moveq.l	#$FFFFFFFF,d3		;見つかった最小のブロックのサイズ
	moveq.l	#0,d5			;見つかった最小のブロック
malloc21Loop:
	cmp.l	a5,d0
	bcc	malloc21Last		;見つからなかった
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc21Next		;ロックされている
	bsr	splitBlock		;分割してできるブロックのヘッダとサイズを求める
	bmi	malloc21Next		;分割できない
	cmp.l	d2,d1			;サイズが足りているか
	blo	malloc21Next		;足りない
	cmp.l	d3,d1			;これまでに見つかったブロックのサイズより小さいか
	bhs	malloc21Next		;大きいか等しい
	move.l	d1,d3			;最小のブロックのサイズを更新
	movea.l	a1,a3			;ヘッダを作れる位置を更新
	move.l	a2,d5			;見つかったブロックのヘッダを更新
malloc21Next:
	move.l	(Next,a2),d0		;次のブロックへ
	bne	malloc21Loop
malloc21Last:
	move.l	d5,d0			;見つかった最小のブロック
	beq	malloc21Failed		;見つからなかった
	movea.l	a3,a1			;新しいヘッダ
	movea.l	d5,a2			;見つかったブロックのヘッダ
	bsr	insertHeader		;ヘッダを挿入する
	lea.l	(User,a1),a1		;ユーザ領域の先頭
	add.l	a1,d2			;ユーザ領域の末尾+1
	move.l	d2,(-User+Tail,a1)	;ユーザ領域の末尾+1
	move.l	d4,(-User+Proc,a1)	;親プロセスのメモリ管理テーブル
	moveq.l	#0,d0
malloc21End:
  debug '|malloc21 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d3/d5/a2-a4
	rts

malloc21Failed:
	suba.l	a1,a1
	bsr	getSize
;<d0.l:確保できるサイズの合計
;<d1.l:一度に確保できる最大のサイズ
	move.l	d1,d0			;最大のサイズ
	or.l	#$80000000,d0		;最上位ビットだけセットする
	bra	malloc21End

;----------------------------------------------------------------
;ブロックの確保(上位から)
;<d2.l:確保するサイズ
;<d4.l:親プロセスのメモリ管理テーブル
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;*d0/a1
malloc22::
	movem.l	d1-d2/a2-a4,-(sp)
  debug '|malloc22 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;念のため
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;先頭のブロック
	suba.l	a3,a3
malloc22Loop:
	cmp.l	a5,d0
	bcc	malloc22Last		;見つからなかった
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc22Next		;ロックされている
	bsr	splitBlock		;分割してできるブロックのヘッダとサイズを求める
	bmi	malloc22Next		;分割できない
	cmp.l	d2,d1			;サイズが足りているか
	blo	malloc22Next		;足りない
	movea.l	a2,a3			;最後に見つかったブロックのヘッダを更新
malloc22Next:
	move.l	(Next,a2),d0		;次のブロックへ
	bne	malloc22Loop
malloc22Last:
	move.l	a3,d0			;最後に見つかったブロック
	beq	malloc22Failed		;見つからなかった
	movea.l	a3,a2			;見つかったブロックのアドレス
	move.l	(Next,a2),d1		;末尾+1
	beq	1f
	cmp.l	a5,d1
	bls	2f
1:	move.l	a5,d1
2:	sub.l	d2,d1
	moveq.l	#$FFFFFFF0,d0
	and.l	d0,d1			;ユーザ領域の先頭
	add.l	d0,d1			;新しいヘッダ
	movea.l	a2,a1			;分割するブロックのヘッダ
	lea.l	(User,a2),a3		;分割するブロックのユーザ領域の先頭
	cmp.l	a1,d1
	beq	malloc22FreeBlock	;分割するブロックの長さが0になるとき分割しない
	movea.l	d1,a1
	bsr	insertHeader		;ヘッダを挿入する
malloc22FreeBlock:
	lea.l	(User,a1),a1		;ユーザ領域の先頭
	add.l	a1,d2			;ユーザ領域の末尾+1
	move.l	d2,(-User+Tail,a1)	;ユーザ領域の末尾+1
	move.l	d4,(-User+Proc,a1)	;親プロセスのメモリ管理テーブル
	moveq.l	#0,d0
malloc22End:
  debug '|malloc22 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d2/a2-a4
	rts

malloc22Failed:
	suba.l	a1,a1
	bsr	getSize
;<d0.l:確保できるサイズの合計
;<d1.l:一度に確保できる最大のサイズ
	move.l	d1,d0			;最大のサイズ
	or.l	#$80000000,d0		;最上位ビットだけセットする
	bra	malloc22End

;----------------------------------------------------------------
;ブロックの確保(最大ブロックから)
;<d2.l:確保するサイズ
;<d4.l:親プロセスのメモリ管理テーブル
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
;*d0/a1
malloc23::
	movem.l	d1-d3/d5/a2-a4,-(sp)
  debug '|malloc23 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;念のため
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;先頭のブロック
	moveq.l	#0,d3			;見つかった最大のブロックのサイズ
	moveq.l	#0,d5			;見つかった最大のブロック
malloc23Loop:
	cmp.l	a5,d0
	bcc	malloc23Last		;見つからなかった
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc23Next		;ロックされている
	bsr	splitBlock		;分割してできるブロックのヘッダとサイズを求める
	bmi	malloc23Next		;分割できない
	cmp.l	d2,d1			;サイズが足りているか
	blo	malloc23Next		;足りない
	cmp.l	d3,d1			;これまでに見つかったブロックのサイズより大きい
	bls	malloc23Next		;小さいか等しい
	move.l	d1,d3			;最大のブロックのサイズを更新
	movea.l	a1,a3			;ヘッダを作れる位置を更新
	move.l	a2,d5			;見つかったブロックのヘッダを更新
malloc23Next:
	move.l	(Next,a2),d0		;次のブロックへ
	bne	malloc23Loop
malloc23Last:
	move.l	d5,d0			;見つかった最大のブロック
	beq	malloc23Failed		;見つからなかった
	movea.l	a3,a1			;新しいヘッダ
	movea.l	d5,a2			;見つかったブロックのヘッダ
	bsr	insertHeader		;ヘッダを挿入する
	lea.l	(User,a1),a1		;ユーザ領域の先頭
	add.l	a1,d2			;ユーザ領域の末尾+1
	move.l	d2,(-User+Tail,a1)	;ユーザ領域の末尾+1
	move.l	d4,(-User+Proc,a1)	;親プロセスのメモリ管理テーブル
	moveq.l	#0,d0
malloc23End:
  debug '|malloc23 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d3/d5/a2-a4
	rts

malloc23Failed:
	suba.l	a1,a1
	move.l	d3,d0			;最大のサイズ
	or.l	#$80000000,d0		;最上位ビットだけセットする
	bra	malloc23End

;----------------------------------------------------------------
;ブロックの開放
;<d2.l:開放するブロックのユーザ領域の先頭
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,-1=ヘッダが見つからない
;*d0
free::
	movem.l	d2/a1-a2,-(sp)
  debug '|free in (ptr)=',1,d2
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2			;ヘッダ
	bsr	searchBlock2		;ヘッダを探す
	bmi	freeEnd			;見つからない
;<a2.l:ヘッダ
	bsr	deleteHeader		;ヘッダを削除する
freeDone:
	moveq.l	#0,d0
freeEnd:
  debug '|free out (err)=',1,d0
	movem.l	(sp)+,d2/a1-a2
	rts

;----------------------------------------------------------------
;特定のプロセスが確保したブロックの開放
;	子プロセスが確保したブロックも開放する
;<d4.l:開放するブロックを確保したプロセスのメモリ管理テーブル
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0(常に成功する)
;*d0
psfree::
	movem.l	d1/a2,-(sp)
  debug '|psfree in (proc)=',1,d4
	move.l	a4,d0			;先頭のブロック
psfreeLoop:
	cmp.l	a5,d0
	bcc	psfreeEnd		;終わり
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	psfreeNext		;ロックされている
	move.l	(Next,a2),d1		;直後
	cmp.l	(Proc,a2),d4		;確保したプロセス
	bne	psfreeNext		;該当しない
	bsr	deleteHeader		;ヘッダを削除する
	move.l	d2,-(sp)
	move.l	d1,-(sp)
	move.l	a2,d2			;子プロセス
	bsr	psfree			;子プロセスが確保したブロックを開放
	move.l	(sp)+,d1
	move.l	(sp)+,d2
psfreeNext:
	move.l	d1,d0
	bne	psfreeLoop
psfreeEnd:
	moveq.l	#0,d0
  debug '|psfree out (err)=',1,d0
	movem.l	(sp)+,d1/a2
	rts

;----------------------------------------------------------------
;ブロックのサイズ変更
;	ブロックは移動しない
;	新しいサイズが0ならばブロックを開放する
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ(0=ブロックを開放する)
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
;*d0
resizeOrFree::
	tst.l	d3			;サイズが0ならばブロックを開放する
	beq	free
;----------------------------------------------------------------
;ブロックのサイズ変更
;	ブロックは移動しない
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
;*d0
resize::
	movem.l	d1-d3/a1-a2,-(sp)
  debug '|resize in (ptr,size)=',2,d2,d3
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2			;ヘッダ
	bsr	searchBlock2		;ヘッダを探す
	bmi	resizeEnd		;見つからない
;<a2.l:ヘッダ
	cmp.l	#LOGICAL_SIZE-1,d3	;オーバーフローさせないため
	bls	@f
	move.l	#LOGICAL_SIZE-1,d3
@@:	lea.l	(User,a2,d3.l),a1	;新しいユーザ領域の末尾+1
	move.l	(Next,a2),d0		;ユーザ領域の末尾+1の最大値
	beq	1f
	cmp.l	a5,d0
	bls	2f
1:	move.l	a5,d0
2:	cmpa.l	d0,a1			;入り切るか
	bhi	resizeFailed		;入り切らない
	move.l	a1,(Tail,a2)		;ユーザ領域の末尾+1
	moveq.l	#0,d0
resizeEnd:
  debug '|resize out (err)=',1,d0
	movem.l	(sp)+,d1-d3/a1-a2
	rts

resizeFailed:
	lea.l	(User,a2),a2		;ユーザ領域の先頭
	sub.l	a2,d0			;ヘッダを含まない最大のサイズ
	or.l	#$80000000,d0		;最上位ビットだけセットする
	bra	resizeEnd

;----------------------------------------------------------------
;ブロックのサイズ変更
;	ブロックが移動することがある
;	移動するとき新しいブロックは下位から確保する
;	移動してもブロックを確保したプロセスは変化しない
;	新しいサイズが0ならばブロックを開放する
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ(0=ブロックを開放する)
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=移動後のブロックのユーザ領域の先頭
;*d0/a1
reallocOrFree::
	tst.l	d3			;サイズが0ならばブロックを開放する
	beq	free
;----------------------------------------------------------------
;ブロックのサイズ変更
;	ブロックが移動することがある
;	移動するとき新しいブロックは下位から確保する
;	移動してもブロックを確保したプロセスは変化しない
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
;>a1.l:0=失敗,0以外=移動後のブロックのユーザ領域の先頭
;*d0/a1
realloc::
	movem.l	d1-d4/a2-a3,-(sp)
  debug '|realloc in (ptr,size)=',2,d2,d3
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2			;ヘッダ
	bsr	searchBlock2		;ヘッダを探す
	bmi	reallocEnd		;見つからない
;移動せずにサイズを変えてみる
;<d3.l:新しいサイズ
;<a2.l:サイズを変更するブロックのユーザ領域の先頭
	cmp.l	#LOGICAL_SIZE-1,d3	;オーバーフローさせないため
	bls	@f
	move.l	#LOGICAL_SIZE-1,d3
@@:	lea.l	(User,a2,d3.l),a1	;新しいユーザ領域の末尾+1
	move.l	(Next,a2),d0		;ユーザ領域の末尾+1の最大値
	beq	1f
	cmp.l	a5,d0
	bls	2f
1:	move.l	a5,d0
2:	cmpa.l	d0,a1			;入り切るか
	bhi	reallocPrevious		;入り切らない
	move.l	a1,(Tail,a2)		;ユーザ領域の末尾+1
	bra	reallocDone

;<d3.l:新しいサイズ
;<a2.l:サイズを変更するブロックのユーザ領域の先頭
reallocPrevious:
	movea.l	a2,a3			;サイズを変更するブロックのヘッダ
;<a3.l:サイズを変更するブロックのヘッダ
	cmpa.l	a4,a3
	beq	reallocFirstBlock	;先頭のブロック
;手前に伸ばしてみる
;<a3.l:サイズを変更するブロックのヘッダ
	movea.l	(Prev,a3),a2		;直前のブロックの未使用の領域を求める
;<a2.l:手前のブロック
	bsr	splitBlock
	bmi	reallocOtherPlace	;手前にはまったく伸ばせない
;<a1.l:手前のブロックを分割してできるブロックのヘッダ(フリーブロックのときは元のヘッダ)
	lea.l	(User,a1),a1		;手前に伸ばした場合のユーザ領域の先頭
	move.l	(Next,a3),d0		;サイズを変更するブロックの末尾+1
	beq	1f
	cmp.l	a5,d0
	bls	2f
1:	move.l	a5,d0
2:	sub.l	a1,d0			;手前に伸ばした場合のサイズ
	cmp.l	d3,d0			;入り切るか
	blo	reallocOtherPlace	;入り切らない
	lea.l	(-User,a1),a1		;手前に伸ばした場合のヘッダ
	bsr	insertHeader		;新しいヘッダを挿入する
	move.l	(Proc,a3),(Proc,a1)	;親プロセス
	lea.l	(User,a1),a1		;手前に伸ばした場合のユーザ領域の先頭
;<a1.l:新しいブロックのユーザ領域の先頭
;<a3.l:サイズを変更するブロックのヘッダ
	bra	reallocDelete

;別の場所に移動する
;<d3.l:新しいサイズ
;<a3.l:サイズを変更するブロックのヘッダ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
reallocOtherPlace:
reallocFirstBlock:
	move.l	d3,d2			;新しいサイズ
	move.l	(Proc,a3),d4		;親プロセス
	bsr	malloc20		;別の場所にブロックを確保する(下位から)
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bmi	reallocEnd		;確保できない
;元のブロックのヘッダを削除する
;<a1.l:新しいブロックのユーザ領域の先頭
;<a3.l:サイズを変更するブロックのヘッダ
reallocDelete:
	move.l	a1,d2
;<d2.l:新しいブロックのユーザ領域の先頭
	moveq.l	#$FFFFFFF0,d4
	add.l	(Tail,a3),d4
	sub.l	a3,d4			;移動するデータのサイズ
;<d4.l:移動するデータのサイズ
	movea.l	a3,a2
	bsr	deleteHeader		;元のブロックのヘッダを削除する
;データをコピーする
;<d2.l:新しいブロックのユーザ領域の先頭
;<d4.l:移動するデータのサイズ
;<a3.l:サイズを変更するブロックのヘッダ
	tst.l	d4			;移動するデータのサイズ
	beq	reallocFreeBlock	;移動すべきデータがない
	lea.l	(User,a3),a3		;移動元のデータの先頭
	movea.l	d2,a2			;移動先のデータの先頭
	subq.l	#1,d4
	lsr.l	#4,d4			;(サイズ-1)/16=(サイズ+15)/16-1
	swap.w	d4
reallocCopy1:
	swap.w	d4
reallocCopy0:
	move.l	(a3)+,(a2)+		;手前に移動して重なることがあるので順序に注意
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	dbra	d4,reallocCopy0
	swap.w	d4
	dbra	d4,reallocCopy1
reallocFreeBlock:
	movea.l	d2,a1
	lea.l	(a1,d3.l),a2
	move.l	a2,(-User+Tail,a1)
reallocDone:
	moveq.l	#0,d0
reallocEnd:
  debug '|realloc out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d4/a2-a3
	rts

;----------------------------------------------------------------
;確保できるサイズの取得
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:確保できるサイズの合計
;>d1.l:一度に確保できる最大のサイズ
;*d0-d1
getSize::
	movem.l	d2-d3/a1-a2,-(sp)
  debug '|getsize in (top,btm)=',2,a4,a5
	moveq.l	#0,d2			;確保できるブロックのサイズの合計
	moveq.l	#0,d3			;確保できる最大のブロックのサイズ
	move.l	a4,d0			;先頭のブロック
getSizeLoop:
	cmp.l	a5,d0
	bcc	getSizeEnd		;終わり
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	getSizeNext		;ロックされている
	bsr	splitBlock		;分割してできるブロックのヘッダとサイズを求める
	bmi	getSizeNext		;分割できない
	tst.l	d1
	beq	getSizeNext
	add.l	d1,d2			;確保できるブロックのサイズの合計を更新
	cmp.l	d3,d1			;これまでに見つかった最大のブロックより大きいか
	bls	getSizeNotLargest	;小さいか等しい
	move.l	d1,d3			;最大のブロックのサイズを更新
getSizeNotLargest:
getSizeNext:
	move.l	(Next,a2),d0		;次のブロックへ
	bne	getSizeLoop
getSizeEnd:
	move.l	d2,d0			;合計サイズ
	move.l	d3,d1			;最大のサイズ
  debug '|getsize out (ttl,max)=',2,d0,d1
	movem.l	(sp)+,d2-d3/a1-a2
	rts

;----------------------------------------------------------------
;ヘッダを探す
;	ロックされているブロックは検索しない
;<d2.l:ヘッダ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=先頭のブロック,1=先頭以外のブロック,-1=失敗
;>a2.l:0=失敗,0以外=ヘッダ
;*d0/a2
searchBlock2::
	bsr	searchBlock
	bmi	searchBlock2End		;見つからない
	tst.b	(Tail,a2)
	bpl	searchBlock2Done
	suba.l	a2,a2			;ロックされている
	moveq.l	#-1,d0
searchBlock2Done:
	tst.l	d0
searchBlock2End:
	rts

;----------------------------------------------------------------
;ヘッダを探す
;	ロックされているブロックも検索する
;<d2.l:ヘッダ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=先頭のブロック,1=先頭以外のブロック,-1=失敗
;>a2.l:0=失敗,0以外=ヘッダ
;*d0/a2
searchBlock::
	cmp.l	a4,d2
	bcs	searchBlockFailed	;範囲外
	cmp.l	a5,d2
	bcc	searchBlockFailed	;範囲外
	move.l	a4,d0			;先頭のブロック
searchBlockLoop:
	cmp.l	a5,d0
	bcc	searchBlockFailed	;見つからなかった
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	searchBlockNext		;ロックされている
	cmpa.l	d2,a2
	beq	searchBlockFound	;見つかった
searchBlockNext:
	move.l	(Next,a2),d0		;次のブロックへ
	bne	searchBlockLoop
searchBlockFailed:
	suba.l	a2,a2			;失敗
	moveq.l	#-1,d0
	bra	searchBlockEnd

searchBlockFound:
	moveq.l	#0,d0
	cmpa.l	a4,a2
	beq	searchBlockEnd		;先頭のブロック
	moveq.l	#1,d0
searchBlockEnd:
	rts

;----------------------------------------------------------------
;分割してできるブロックのヘッダとサイズを求める
;<a2.l:分割するブロックのヘッダ(無効なアドレスは指定不可)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;>d0.l:0=フリーブロックなので分割しない,1=フリーブロックではないので分割する,-1=失敗
;>d1.l:0=失敗,0以外=分割してできるブロックのサイズ
;>a1.l:0=失敗,0以外=分割してできるブロックのヘッダ(フリーブロックのときは元のヘッダ)
;*d0-d1/a1
splitBlock::
  debug '|splitBlock in (header,limit)=',2,a2,a5
	lea.l	(User,a2),a1		;ユーザ領域の先頭
	move.l	(Tail,a2),d0
	sub.l	a1,d0			;ユーザ領域のサイズ
	bne	splitBlockUsed
;フリーブロックのとき
	move.l	(Next,a2),d1		;末尾+1
	beq	1f
	cmp.l	a5,d1
	bls	2f
1:	move.l	a5,d1
2:	sub.l	a1,d1			;確保できるサイズ
	ble	splitBlockFailed	;確保できない
	movea.l	a2,a1
	moveq.l	#0,d0
  debug '|splitBlock out (split,size,header)=',3,d0,d1,a1
	rts

;フリーブロックではないとき
splitBlockUsed:
	lea.l	(15,a1,d0.l),a1		;ユーザ領域の末尾+1+15
	move.l	a1,d1
	moveq.l	#$FFFFFFF0,d0
	and.w	d0,d1
	movea.l	d1,a1			;新しいヘッダ
	move.l	(Next,a2),d1		;末尾+1
	beq	1f
	cmp.l	a5,d1
	bls	2f
1:	move.l	a5,d1
2:	sub.l	a1,d1			;ヘッダを含めたサイズ
	ble	splitBlockFailed	;ヘッダも入らない
	add.l	d0,d1			;確保できるサイズ
	beq	splitBlockFailed	;ヘッダしか入らない
	moveq.l	#1,d0
  debug '|splitBlock out (split,size,header)=',3,d0,d1,a1
	rts

splitBlockFailed:
	suba.l	a1,a1
	moveq.l	#0,d1
	moveq.l	#-1,d0
  debug '|splitBlock out (split,size,header)=',3,d0,d1,a1
	rts

;----------------------------------------------------------------
;ヘッダを挿入する
;	ブロックを分割してヘッダを作りリストに挿入する
;	ユーザ領域のサイズは設定しない
;	親プロセスは設定しない
;	新しいヘッダが分割するブロックのヘッダと同じならば何もしない
;<a1.l:新しいヘッダ
;<a2.l:分割するブロックのヘッダ
;?d0
insertHeader::
	cmpa.l	a2,a1
	beq	insertHeaderFreeBlock
	move.l	a2,(Prev,a1)		;直前を設定
	move.l	(Next,a2),d0
	move.l	a1,(Next,a2)		;分割するブロックを縮める
	move.l	d0,(Next,a1)		;直後を設定
	beq	insertHeaderLastBlock
	exg.l	d0,a2
	move.l	a1,(Prev,a2)		;直後のブロックの直前を設定
	exg.l	d0,a2
insertHeaderLastBlock:
insertHeaderFreeBlock:
	rts

;----------------------------------------------------------------
;ヘッダを削除する
;	確保したプロセスを0にする
;	フリーブロックにする
;	先頭のブロックでなければヘッダをリストから取り除く
;<a2.l:削除するヘッダのアドレス(先頭のブロックのヘッダは削除しない)
;<a4.l:メモリ空間の先頭(先頭のブロック)
;?d0/a1
deleteHeader::
	clr.l	(Proc,a2)		;確保したプロセスを0にする
	lea.l	(User,a2),a1
	move.l	a1,(Tail,a2)		;フリーブロックにする
	cmpa.l	a4,a2
	beq	deleteHeaderFirstBlock	;先頭のブロック
	move.l	(Prev,a2),a1		;直前
	move.l	(Next,a2),d0		;直後
	move.l	d0,(Next,a1)		;直前のブロックの直後を設定
	beq	deleteHeaderLastBlock
	exg.l	d0,a2
	move.l	a1,(Prev,a2)		;直後のブロックの直前を設定
	exg.l	d0,a2
deleteHeaderLastBlock:
deleteHeaderFirstBlock:
	rts

;----------------------------------------------------------------
;自分以外の連続メモリ型サブスレッドのすべてのブロックをロックする
;<a0.l:自分のサブスレッドのスレッド管理テーブル,通常は[$1C54.w].l
lockBlocks::
	movem.l	d0-d4/a2-a5,-(sp)
	move.w	$1C58.w,d1		;スレッド数-1=サブスレッド数
	beq	lockBlocksEnd		;サブスレッドが存在しない
	moveq.l	#$80,d2
	movea.l	$1C50.w,a3		;メインスレッドのスレッド管理テーブル
	move.l	(tMemStart,a3),d3	;メインスレッドのメモリ空間の先頭
	move.l	(tMemStart,a0),d4	;自分のメモリ空間の先頭
;<d1.w:スレッド数-1=サブスレッド数(>0)
;<d2.b:$80
;<d3.l:メインスレッドのメモリ空間の先頭
;<d4.l:自分のメモリ空間の先頭
;<a0.l:自分のサブスレッドのスレッド管理テーブル
;<a3.l:メインスレッドのスレッド管理テーブル
	subq.w	#1,d1			;サブスレッド数-1
lockBlocksThreadLoop:
	lea.l	(tSize,a3),a3
;<a3.l:スレッド管理テーブル
	tst.l	(tProcess,a3)
	beq	lockBlocksNextThread	;未使用のスレッド
	cmpa.l	a0,a3
	beq	lockBlocksNextThread	;自分はロックしない
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	cmpa.l	d3,a4
	beq	lockBlocksNextThread	;メインスレッドと同じメモリ空間なのでロックしない
	cmpa.l	d4,a4
	beq	lockBlocksNextThread	;自分と同じメモリ空間なのでロックしない
	moveq.l	#(.not.LOGICAL_MASK)>>24,d0
	and.b	(Proc,a4),d0
	cmp.b	#$C0,d0			;先頭のブロックにサブスレッドのフラグがあれば連続メモリ型
	bne	lockBlocksNextThread	;サブメモリ型サブスレッドのメモリ空間なのでロックしない
	move.l	a4,d0
lockBlocksSubLoop:
	cmp.l	a5,d0
	bcc	lockBlocksNextThread
	movea.l	d0,a2
	or.b	d2,(Tail,a2)		;ロックする
	move.l	(Next,a2),d0
	bne	lockBlocksSubLoop
lockBlocksNextThread:
	dbra	d1,lockBlocksThreadLoop
;
lockBlocksEnd:
	movem.l	(sp)+,d0-d4/a2-a5
	rts

;----------------------------------------------------------------
;ブロックのロックを解除する
;	メインスレッドのメモリ空間にあるブロックについてロックされていたら解除する
unlockBlocks::
	movem.l	d0-d2/a2-a5,-(sp)
	move.w	$1C58.w,d1		;スレッド数-1
	beq	lockBlocksEnd		;サブスレッドが存在しない
	moveq.l	#$7F,d2
	movea.l	$1C50.w,a3		;メインスレッドのスレッド管理テーブル
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:メインスレッドのメモリ空間の先頭
;<a5.l:メインスレッドのメモリ空間の末尾+1
	move.l	a4,d0
unlockBlocksLoop:
	cmp.l	a5,d0
	bcc	unlockBlocksEnd
	movea.l	d0,a2
	and.b	d2,(Tail,a2)		;ロックを解除する
	move.l	(Next,a2),d0
	bne	unlockBlocksLoop
unlockBlocksEnd:
	movem.l	(sp)+,d0-d2/a2-a5
	rts

;----------------------------------------------------------------
;実行中のプロセスのメモリ管理テーブルを得る
;>d4.l:実行中のプロセスのメモリ管理テーブル
;*d4
getProc::
	move.l	([$1C28.w]),d4		;実行中のプロセスのメモリ管理テーブル
	rts

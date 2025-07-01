;----------------------------------------------------------------
;
;	アドレス変換に関連するルーチン群
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;アドレス変換テーブル(デスクリプタの領域)
;
;	アドレス変換テーブルはメインメモリまたはローカルメモリ上に配置
;	アドレス変換テーブルは$00002000(8KB)で割り切れるアドレスに置く
;
;	アドレス変換テーブルはスーパーバイザ領域とする
;	アドレス変換テーブルはライトプロテクトする
;	アドレス変換テーブルへのアクセスはFC_MMU_DATAに対するMOVESで行う
;
;	アドレス変換テーブルは次の3つのデスクリプタテーブルから成る
;		ルートデスクリプタテーブル
;		ポインタデスクリプタテーブル
;		ページデスクリプタテーブル
;
;	ルートデスクリプタテーブルは下位側に固定
;	ポインタデスクリプタテーブルは下位側から上位側へ伸長(末尾を動かす)
;	ページデスクリプタテーブルは上位側から下位側へ伸長(先頭を動かす)
;
;	無効なデスクリプタは必ず32ビットすべてを0にする
;	デスクリプタテーブルの内容がすべて無効になったらテーブルごと開放する
;
;	ページデスクリプタテーブルの後にデスクリプタの参照数カウンタのテーブルが続く
;		ポインタデスクリプタ参照数カウンタテーブル
;		ページデスクリプタ参照数カウンタテーブル
;
;	参照数カウンタのテーブルの内容は参照数-1
;	参照数カウンタが-1のデスクリプタテーブルは未使用であることを意味する
;
;	論理アドレスが30ビットなので、アドレスの上位2ビットの違いは無視される
;	ルートデスクリプタテーブルは16個のデスクリプタのセットを8個並べたものになる
;	論理アドレスの上位2ビットが0でないルートデスクリプタは参照数カウンタに影響しない
;
;			      内容		アドレスを保持している変数
;		┏━━━━━━━━━━━━━━┓descHead/rootDescHead
;		┃ ルートデスクリプタテーブル ┃
;		┗━━━━━━━━━━━━━━┛rootDescTail
;		┏━━━━━━━━━━━━━━┓pointerDescHead
;		┃ポインタデスクリプタテーブル┃
;		┠──────────────┨
;		┃ポインタデスクリプタテーブル┃
;		┠──────────────┨
;		┃	     未使用	      ┃
;		┠──────────────┨
;		┃ポインタデスクリプタテーブル┃
;		┠──────────────┨
;		┃	     未使用	      ┃
;		┠──────────────┨
;		┃ポインタデスクリプタテーブル┃
;		┣━━━━━━━━━━━━━━┫pointerDescTail
;		┃	       ↓	      ┃
;		┃			      ┃
;		┃	     未使用	      ┃
;		┃			      ┃
;		┃	       ↑	      ┃
;		┣━━━━━━━━━━━━━━┫pageDescHead
;		┃ ページデスクリプタテーブル ┃
;		┠──────────────┨
;		┃ ページデスクリプタテーブル ┃
;		┠──────────────┨
;		┃	     未使用	      ┃
;		┠──────────────┨
;		┃	     未使用	      ┃
;		┠──────────────┨
;		┃ ページデスクリプタテーブル ┃
;		┗━━━━━━━━━━━━━━┛pageDescTail
;		┏━━━━━━━━━━━━━━┓pointerCounterHead
;		┃	     ０以上	      ┃
;		┠──────────────┨
;		┃	     ０以上	      ┃
;		┠──────────────┨
;		┃	      －１	      ┃
;		┠──────────────┨
;		┃	     ０以上	      ┃
;		┠──────────────┨
;		┃	      －１	      ┃
;		┠──────────────┨
;		┃	     ０以上	      ┃
;		┠──────────────┨
;		┃	       ↓	      ┃
;		┃			      ┃
;		┃	     未使用	      ┃
;		┃			      ┃
;		┃	       ↑	      ┃
;		┠──────────────┨
;		┃	     ０以上	      ┃
;		┠──────────────┨
;		┃	     ０以上	      ┃
;		┠──────────────┨
;		┃	      －１	      ┃
;		┠──────────────┨
;		┃	      －１	      ┃
;		┠──────────────┨
;		┃	     ０以上	      ┃
;		┗━━━━━━━━━━━━━━┛pageCounterTail/descTail
;
;----------------------------------------------------------------


;----------------------------------------------------------------
;デスクリプタの無効化
;<a1.l:論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:更新前のページデスクリプタ
;	-1	デスクリプタの領域が不足している
invDesc::
	movem.l	d7/a0/a2,-(sp)
	bsr	getDesc
	move.l	d0,d7
	bmi	8f			;デスクリプタが存在しない
	beq	8f			;デスクリプタが無効
	moveq.l	#0,d0
	moves.l	d0,(a0)
;デスクリプタテーブルを検索
	move.l	rootDescHead,d0
	bsr	getRootDesc
	movea.l	a0,a2			;ルートデスクリプタのアドレス
	and.l	#POINTER_DESC_MASK,d0	;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDesc
;ページデスクリプタテーブル全体が無効になったらポインタデスクリプタを無効化する
	move.l	a0,d0			;ポインタデスクリプタのアドレス
	bsr	invUpPageDescTable
	bne	8f
;ポインタデスクリプタテーブル全体が無効になったらルートデスクリプタを無効化する
	move.l	a2,d0			;ルートデスクリプタのアドレス
	bsr	invUpPointerDescTable
8:	move.l	d7,d0
	movem.l	(sp)+,d7/a0/a2
	rts

;----------------------------------------------------------------
;共有デスクリプタの設定(間接ページデスクリプタを含む)
;<d2.l:論理アドレス(ページデスクリプタが存在すること)
;<a1.l:論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:更新前のページデスクリプタ
;	-1	デスクリプタの領域が不足している
;	-2	変換先のページデスクリプタが存在しない
comDesc::
	movem.l	d1-d2/d7/a0-a6,-(sp)
	exg.l	d2,a1
	bsr	getDesc			;変換先のページデスクリプタを求める
	bmi	9f
	movea.l	d2,a1
	move.l	a0,d2			;ページデスクリプタのアドレス
	addq.l	#%10,d2			;PDT=%10(間接)
	bsr	setDesc			;間接ページデスクリプタを設定する
	move.l	d0,d7
	bmi	8f
;デスクリプタテーブルを検索
	move.l	rootDescHead,d0
	bsr	getRootDesc
	movea.l	a0,a2			;ルートデスクリプタのアドレス
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a3			;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDesc
	movea.l	a0,a4			;ポインタデスクリプタのアドレス
	and.l	pageDescMask,d0
	movea.l	d0,a5			;ページデスクリプタテーブルの先頭
;ページデスクリプタテーブルのすべてのページデスクリプタが、
;一様に他のページデスクリプタテーブルへの間接ページデスクリプタかどうか調べる
	movea.l	a5,a0
	moves.l	(a0)+,d0		;先頭のページデスクリプタ
	moveq.l	#%11,d1
	and.l	d0,d1			;PDT
	subq.l	#%10,d1
	bne	8f			;間接でない
	subq.l	#%10,d0
	move.l	d0,d1
	and.l	pageDescMask,d0
	cmp.l	d1,d0
	bne	8f			;ページデスクリプタテーブルの先頭でない
	movea.l	d0,a6			;間接ページデスクリプタが指していたページデスクリプタテーブルの先頭
	addq.l	#%10,d1
	moveq.l	#PAGE_INDEX_SIZE-1-1,d2
@@:	addq.l	#4,d1
	moves.l	(a0)+,d0
	cmp.l	d1,d0			;間接ページデスクリプタなのでそのまま比較できる
	dbne	d2,@b
	bne	8f			;異なるページデスクリプタがある
;ページデスクリプタテーブルを切り離して、
;間接ページデスクリプタが指していたページデスクリプタテーブルに繋ぐ
	move.l	a3,d0
	move.l	a6,d1			;ページデスクリプタテーブルの先頭
;		  U W UDT
	addq.l	#%0_0_11,d1
	bsr	setPointerDesc
;論理アドレスの上位8ビットをクリアした場合のデスクリプタテーブルを検索
	move.l	a1,d0
	and.l	#$00FFFFFF,d0
	cmpa.l	d0,a1
	beq	8f			;$00xxxxxxなので関係ない
	move.l	a1,-(sp)
	movea.l	d0,a1			;論理アドレス変更
	move.l	rootDescHead,d0
	bsr	getRootDesc
	movea.l	(sp)+,a1
	bmi	8f			;ないはずはないが念のため
	movea.l	a0,a4			;ルートデスクリプタのアドレス
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a5			;ポインタデスクリプタテーブルの先頭
	cmpa.l	a3,a5
	beq	8f			;同じポインタデスクリプタテーブルなので関係ない
;ポインタデスクリプタテーブルのすべてのポインタデスクリプタが、
;論理アドレスの上位8ビットをクリアした場合のポインタデスクリプタテーブルと、
;一致しているか調べる
	move.l	a1,-(sp)
	movea.l	a3,a0			;ポインタデスクリプタテーブルの先頭
	movea.l	a5,a1			;論理アドレスの上位8ビットをクリアした場合の
					;ポインタデスクリプタテーブルの先頭
	bsr	cmpPointerDescTable
	movea.l	(sp)+,a1
	bne	8f			;一致しない
;ポインタデスクリプタテーブルを切り離して、
;論理アドレスの上位8ビットをクリアした場合のポインタデスクリプタテーブルに繋ぐ
	move.l	rootDescHead,d0
	moves.l	(a4),d1			;ルートデスクリプタ
	bsr	setRootDesc
8:	move.l	d7,d0
	movem.l	(sp)+,d1-d2/d7/a0-a6
	rts

9:	moveq.l	#-2,d7
	bra	8b

;----------------------------------------------------------------
;ページデスクリプタの設定
;	このプログラム自身や割り込みルーチンで使用中の領域は指定しないこと
;<d2.l:ページデスクリプタ
;<a1.l:論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:更新前のページデスクリプタ
;	-1	デスクリプタの領域が不足している
setDesc::
	movem.l	d1-d2/d7/a0/a2-a5,-(sp)
	moveq.l	#0,d7			;更新前のページデスクリプタ
;PDT=%00ならば全体を0にする
	moveq.l	#%11,d0
	and.l	d2,d0			;PDT
	bne	@f
	moveq.l	#0,d2			;PDT=%00ならば全体を0にする
@@:
;$00000000～$00FFFFFFのページデスクリプタは無効や間接にできない
	cmpa.l	#$01000000,a1
	bhs	@f
	btst.l	#0,d2
	beq	9f			;PDT=%00(無効),%10(間接)
@@:
;デスクリプタテーブルを辿る
	move.l	rootDescHead,d0
	beq	9f			;ルートデスクリプタテーブルがない
;ルートデスクリプタテーブルが存在する
	bsr	getRootDesc
	movea.l	a0,a2			;ルートデスクリプタのアドレス
	beq	1f			;ルートデスクリプタが無効(ポインタデスクリプタテーブルがない)
;ポインタデスクリプタテーブルが存在する
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a3			;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDesc
	movea.l	a0,a4			;ポインタデスクリプタのアドレス
	beq	2f			;ポインタデスクリプタが無効(ページデスクリプタテーブルがない)
;ページデスクリプタテーブルが存在する
	and.l	pageDescMask,d0
	movea.l	d0,a5			;ページデスクリプタテーブルの先頭
	bsr	getPageDesc
	move.l	d0,d7			;更新前のページデスクリプタ
	beq	3f			;ページデスクリプタが無効
;ページデスクリプタが有効
;キャッシュフラッシュ
	and.l	pageMask,d0		;物理ページアドレス
	movea.l	d0,a2			;物理ページアドレス
	cpushp	dc,(a2)			;データキャッシュプッシュ
	cinvp	bc,(a2)			;キャッシュ無効化
;ページデスクリプタの参照数をチェック
3:	move.l	a5,d0			;ページデスクリプタテーブルの先頭
	bsr	getPageDescCount	;参照数カウンタを調べる
	beq	4f			;1箇所だけから参照されている
;ページデスクリプタテーブルが2箇所以上から参照されているので新しく作る
	movea.l	a5,a0			;ページデスクリプタテーブルの先頭
	bsr	dupPageDescTable	;ページデスクリプタテーブルを複製する
	bra	6f

;ポインタデスクリプタが無効(ページデスクリプタテーブルがない)
2:	bsr	callocPageDescTable	;ページデスクリプタテーブルを作る
6:	bmi	9f			;デスクリプタの領域が不足している
	movea.l	d0,a5			;ページデスクリプタテーブルの先頭
;ポインタデスクリプタの参照数をチェック
	move.l	a3,d0			;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDescCount
	beq	5f			;1箇所だけから参照されている
;ポインタデスクリプタテーブルが2箇所以上から参照されているので新しく作る
	movea.l	a3,a0			;ポインタデスクリプタテーブルの先頭
	bsr	dupPointerDescTable	;ポインタデスクリプタテーブルを複製する
	bra	7f

;ルートデスクリプタが無効(ポインタデスクリプタテーブルがない)
1:	bsr	callocPageDescTable	;ページデスクリプタテーブルを作る
	bmi	9f			;デスクリプタの領域が不足している
	movea.l	d0,a5			;ページデスクリプタテーブルの先頭
	bsr	callocPointerDescTable	;ポインタデスクリプタテーブルを作る
7:	bmi	9f			;デスクリプタの領域が不足している
	movea.l	d0,a3			;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDesc
	movea.l	a0,a4			;ポインタデスクリプタのアドレス
;ルートデスクリプタを更新する
	move.l	rootDescHead,d0		;ルートデスクリプタテーブルの先頭
	move.l	a3,d1			;ポインタデスクリプタテーブルの先頭
;		  U W UDT
	addq.l	#%0_0_11,d1		;UDT=%11(有効)
	bsr	setRootDesc		;ルートデスクリプタを更新
;ポインタデスクリプタが1箇所だけから参照されているので直接更新する
5:	move.l	a3,d0			;ポインタデスクリプタテーブルの先頭
	move.l	a5,d1			;ページデスクリプタテーブルの先頭
;		  U W UDT
	addq.l	#%0_0_11,d1		;UDT=%11(有効)
	bsr	setPointerDesc		;ポインタデスクリプタを更新
;ページデスクリプタテーブルが1箇所だけから参照されているので直接更新する
;間接ページデスクリプタによる参照があった場合はそれも更新されることになる
4:	move.l	a5,d0			;ページデスクリプタテーブルの先頭
	move.l	d2,d1			;ページデスクリプタ
	bsr	setPageDesc		;ページデスクリプタを更新
;後始末
8:	bsr	cleanPointerDesc
	bsr	cleanPageDesc
;更新前のページデスクリプタを返す
	move.l	d7,d0
	movem.l	(sp)+,d1-d2/d7/a0/a2-a5
	rts

9:	moveq.l	#-1,d7
	bra	8b

;----------------------------------------------------------------
;論理アドレスからページデスクリプタを求める
;<a1.l:論理アドレス
;<sfc.l:FC_MMU_DATA
;>d0.l:ページデスクリプタ
;	-1	ページデスクリプタがない
;	0	ページデスクリプタが無効
;>a0.l:ページデスクリプタのアドレス(間接ページデスクリプタのとき(a0)≠d0)
;	0	ページデスクリプタがない
;>n-flag:mi=ページデスクリプタがない,pl=ページデスクリプタがある
;>z-flag:(pl)ne=ページデスクリプタが有効,eq=ページデスクリプタが無効
getDesc::
	move.l	rootDescHead,d0
	beq	9f			;ルートデスクリプタテーブルがない
	bsr	getRootDesc		;ルートデスクリプタを得る
	beq	9f			;ルートデスクリプタが無効
;<d0.l:ルートデスクリプタ
;<a0.l:ルートデスクリプタのアドレス
	and.l	#POINTER_DESC_MASK,d0
;<d0.l:ポインタデスクリプタテーブルの先頭
	bsr	getPointerDesc		;ポインタデスクリプタを得る
	beq	9f			;ポインタデスクリプタが無効
;<d0.l:ポインタデスクリプタ
;<a0.l:ポインタデスクリプタのアドレス
	and.l	pageDescMask,d0
;<d0.l:ページデスクリプタテーブルの先頭
	bsr	getPageDesc		;ページデスクリプタを得る
;<d0.l:ページデスクリプタ
;<a0.l:ページデスクリプタのアドレス(間接ページデスクリプタのとき(a0)≠d0)
;<n-flag:pl
;<z-flag:ne=ページデスクリプタが有効,eq=ページデスクリプタが無効
	rts

9:	moveq.l	#-1,d0
	suba.l	a0,a0
;<d0.l:-1
;<a0.l:0
;<n-flag:mi
	rts


;----------------------------------------------------------------
;
;	ルートデスクリプタの操作
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;ルートデスクリプタをコピーする
;<d0.l:コピー元の論理アドレス
;<a1.l:コピー先の論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:変更前のルートデスクリプタ
;	-1	エラー
copyRootDesc::
	movem.l	d1/a0-a1,-(sp)
	move.l	a1,d1			;コピー先の論理アドレス
	movea.l	d0,a1			;コピー元の論理アドレス
	move.l	rootDescHead,d0
	beq	9f
	bsr	getRootDesc		;コピー元のルートデスクリプタを求める
	movea.l	d1,a1			;コピー先の論理アドレス
	move.l	d0,d1			;コピー元のルートデスクリプタ
	move.l	rootDescHead,d0
	bsr	setRootDesc		;ルートデスクリプタを変更する
8:	movem.l	(sp)+,d1/a0-a1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;ルートデスクリプタを更新する
;<d0.l:ルートデスクリプタテーブルの先頭
;<d1.l:ルートデスクリプタ
;<a1.l:論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:更新前のルートデスクリプタ
;	0	ルートデスクリプタが無効
;>n-flag:pl
;>z-flag:ne=ルートデスクリプタが有効,eq=ルートデスクリプタが無効
setRootDesc::
	movem.l	d2/d7/a0/a2,-(sp)
	bsr	getRootDesc		;ルートデスクリプタを求める
	move.l	d0,d7
;新しいポインタデスクリプタテーブルのカウンタを1増やす
;減らす方を先に行うと、減らした段階でデスクリプタテーブルが開放されてしまって
;増やせなくなく可能性があるので、増やす方を先に行う
	move.l	d1,d0
	beq	1f
	and.l	#POINTER_DESC_MASK,d0
	bsr	incPointerDescCount
1:
;元のポインタデスクリプタテーブルのカウンタを1減らす
	move.l	d7,d0
	beq	2f
	and.l	#POINTER_DESC_MASK,d0
	bsr	decPointerDescCount
2:
;ルートデスクリプタを更新する
	movea.l	a0,a2
	moveq.l	#(1<<(32-LOGICAL_WIDTH))-1,d2
@@:	moves.l	d1,(a2)			;ルートデスクリプタを更新する
	lea.l	(4<<(LOGICAL_WIDTH-25),a2),a2
	dbra	d2,@b
	move.l	d7,d0
	movem.l	(sp)+,d2/d7/a0/a2
	rts

;----------------------------------------------------------------
;ルートデスクリプタを取得する
;<d0.l:ルートデスクリプタテーブルの先頭
;<a1.l:論理アドレス
;	無効なビットは無視される
;<sfc.l:FC_MMU_DATA
;>d0.l:ルートデスクリプタ
;	0	ルートデスクリプタが無効
;>a0.l:ルートデスクリプタのアドレス
;>n-flag:pl
;>z-flag:ne=ルートデスクリプタが有効,eq=ルートデスクリプタが無効
getRootDesc::
	movea.l	d0,a0			;ルートデスクリプタテーブルの先頭
	move.l	a1,d0			;論理アドレス
	bfextu	d0{32-LOGICAL_WIDTH:LOGICAL_WIDTH-25},d0	;ルートインデックスフィールド
					;	無効なビットを無視する
	lea.l	(a0,d0.l*4),a0		;ルートデスクリプタのアドレス
	moves.l	(a0),d0			;ルートデスクリプタ
	btst.l	#1,d0
	bne	8f			;UDT=%10,%11(有効)
	moveq.l	#0,d0
8:	tst.l	d0
	rts


;----------------------------------------------------------------
;
;	ポインタデスクリプタの操作
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;ポインタデスクリプタをコピーする
;<d0.l:コピー元の論理アドレス
;<a1.l:コピー先の論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:変更前のポインタデスクリプタ
;	-1	エラー
copyPointerDesc::
	movem.l	d1/a0-a1,-(sp)
	move.l	a1,d1			;コピー先の論理アドレス
	movea.l	d0,a1			;コピー元の論理アドレス
	move.l	rootDescHead,d0
	beq	9f
	bsr	getRootDesc		;コピー元のルートデスクリプタを求める
	beq	9f
	and.l	#POINTER_DESC_MASK,d0
	bsr	getPointerDesc		;コピー元のポインタデスクリプタを求める
	movea.l	d1,a1			;コピー先の論理アドレス
	move.l	d0,d1			;コピー元のポインタデスクリプタ
	move.l	rootDescHead,d0
	bsr	getRootDesc		;コピー先のルートデスクリプタを求める
	beq	9f
	and.l	#POINTER_DESC_MASK,d0
	bsr	setPointerDesc		;ルートデスクリプタを変更する
8:	movem.l	(sp)+,d1/a0-a1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;ポインタデスクリプタを更新する
;<d0.l:ポインタデスクリプタテーブルの先頭
;<d1.l:ポインタデスクリプタ
;<a1.l:論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:ポインタデスクリプタ
;	0	ポインタデスクリプタが無効
;>n-flag:pl
;>z-flag:ne=ポインタデスクリプタが有効,eq=ポインタデスクリプタが無効
setPointerDesc::
	movem.l	d3/d7/a0,-(sp)
	move.l	d0,d3
	bsr	getPointerDescCount
	exg.l	d0,d3
	addq.l	#1,d3			;参照数
	bsr	getPointerDesc
	move.l	d0,d7
;新しいページデスクリプタテーブルのカウンタを増やす
;減らす方を先に行うと、減らした段階でデスクリプタテーブルが開放されてしまって
;増やせなくなく可能性があるので、増やす方を先に行う
	move.l	d1,d0
	beq	1f
	and.l	pageDescMask,d0
	bsr	addPageDescCount
1:
;元のページデスクリプタテーブルのカウンタを減らす
	move.l	d7,d0
	beq	1f
	and.l	pageDescMask,d0
	bsr	subPageDescCount
1:
;ポインタデスクリプタを更新する
	moves.l	d1,(a0)
	move.l	d7,d0
	movem.l	(sp)+,d3/d7/a0
	rts

;----------------------------------------------------------------
;ポインタデスクリプタを取得する
;<d0.l:ポインタデスクリプタテーブルの先頭
;<a1.l:論理アドレス
;<sfc.l:FC_MMU_DATA
;>d0.l:ポインタデスクリプタ
;	0	ポインタデスクリプタが無効
;>a0.l:ポインタデスクリプタのアドレス
;>n-flag:pl
;>z-flag:ne=ポインタデスクリプタが有効,eq=ポインタデスクリプタが無効
getPointerDesc::
	movea.l	d0,a0			;ポインタデスクリプタテーブルの先頭
	move.l	a1,d0			;論理アドレス
	bfextu	d0{7:7},d0		;ポインタインデックスフィールド
	lea.l	(a0,d0.l*4),a0		;ポインタデスクリプタのアドレス
	moves.l	(a0),d0			;ポインタデスクリプタ
	btst.l	#1,d0
	bne	8f			;UDT=%10,%11(有効)
	moveq.l	#0,d0
8:	tst.l	d0
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを1つ確保して0クリアする
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:ポインタデスクリプタテーブルのアドレス(0クリアされている)
;	-1	デスクリプタの領域が不足している
;>n-flag:pl=正常終了,mi=デスクリプタの領域が不足している
callocPointerDescTable::
	bsr	allocPointerDescTable
	bmi	9f
	bsr	clearPointerDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを1つ複製する
;<a0.l:複製するポインタデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:複製されたポインタデスクリプタテーブルのアドレス
;	-1	デスクリプタの領域が不足している
;>n-flag:pl=正常終了,mi=デスクリプタの領域が不足している
dupPointerDescTable::
	bsr	allocPointerDescTable
	bmi	9f
	bsr	copyPointerDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを1つ確保する
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:ポインタデスクリプタテーブルのアドレス
;	-1	デスクリプタの領域が不足している
;>n-flag:pl=正常終了,mi=デスクリプタの領域が不足している
allocPointerDescTable::
	movem.l	a0-a1,-(sp)
	movea.l	pointerCounterHead,a0
	movea.l	pointerDescHead,a1
	bra	2f

1:	moves.l	(a0),d0			;参照数-1
	tst.l	d0
	bmi	3f			;途中に未使用の領域があった
	addq.l	#4,a0
	lea.l	(POINTER_DESC_SIZE,a1),a1
2:	cmpa.l	pointerDescTail,a1
	bne	1b
;途中には未使用の領域がなかった
	lea.l	(POINTER_DESC_SIZE,a1),a1	;ポインタデスクリプタテーブルの領域を伸ばしてみる
	cmpa.l	pageDescHead,a1
	bhi	9f			;デスクリプタテーブルの領域が不足している
	move.l	a1,pointerDescTail	;ポインタデスクリプタテーブルの領域を伸ばす
	lea.l	(-POINTER_DESC_SIZE,a1),a1
;途中に未使用の領域があった
3:	moveq.l	#-1,d0
	moves.l	d0,(a0)			;参照数に0を設定
	move.l	a1,d0
8:	movem.l	(sp)+,a0-a1
	rts

;デスクリプタテーブルの領域が不足している
9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;ポインタデスクリプタテーブルがすべて無効ならばルートデスクリプタを無効にする
;<d0.l:ルートデスクリプタのアドレス
;>z-flag:eq=デスクリプタを無効にした,ne=デスクリプタを無効にしなかった
invUpPointerDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a2			;ルートデスクリプタのアドレス
	moves.l	(a2),d1			;ルートデスクリプタ
	and.l	#POINTER_DESC_MASK,d1	;ポインタデスクリプタテーブルのアドレス
	movea.l	d1,a0
	lea.l	(POINTER_DESC_SIZE,a0.l),a1
1:	moves.l	(a0)+,d0		;ポインタデスクリプタ
	tst.l	d0
	bne	9f
	cmpa.l	a1,a0
	blo	1b
	moveq.l	#0,d0
	moves.l	d0,(a2)			;ルートデスクリプタを無効化する
	move.l	d1,d0
	bsr	freePointerDescTable	;ポインタデスクリプタテーブルを削除する
	moveq.l	#0,d0
9:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルの参照数カウンタを1増やす
;	含まれるページデスクリプタテーブルの参照数カウンタもすべて1ずつ増やす
;<d0.l:ポインタデスクリプタテーブルの先頭
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
incPointerDescCount::
	movem.l	d0/a0-a2,-(sp)
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a1			;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDescCount
;現在の参照数が0でも処理すること
;ポインタデスクリプタテーブルの参照数を1増やす
	addq.l	#1,d0
	moves.l	d0,(a0)			;ポインタデスクリプタテーブルの参照数を1増やす
;含まれるページデスクリプタテーブルの参照数も1ずつ増やす
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a1)+,d0		;ポインタデスクリプタ
	btst.l	#1,d0
	beq	2f			;UDT=%00,%01(無効)
	bsr	incPageDescCount	;ページデスクリプタテーブルの参照数を1増やす
2:	cmpa.l	a2,a1
	blo	1b
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルの参照数カウンタを1減らす
;	含まれるページデスクリプタテーブルの参照数カウンタもすべて1ずつ減らす
;<d0.l:ポインタデスクリプタテーブルの先頭
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
decPointerDescCount::
	movem.l	d0/a0-a2,-(sp)
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a1			;ポインタデスクリプタテーブルの先頭
	bsr	getPointerDescCount
	bmi	8f
	beq	3f			;ポインタデスクリプタテーブルがなくなるとき
					;ページデスクリプタテーブルの参照数を減らしすぎないようにする
;含まれるページデスクリプタテーブルの参照数を1ずつ減らす
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a1)+,d0		;ポインタデスクリプタ
	btst.l	#1,d0
	beq	2f			;UDT=%00,%01(無効)
	bsr	decPageDescCount	;ページデスクリプタテーブルの参照数を1減らす
2:	cmpa.l	a2,a1
	blo	1b
;ポインタデスクリプタテーブルの参照数を1減らす
	moves.l	(a0),d0
3:	subq.l	#1,d0
	moves.l	d0,(a0)			;ポインタデスクリプタテーブルの参照数を1減らす
	bcc	8f
	bsr	freePointerDescTable	;どこからも参照されないので開放する
8:	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを1つ開放する
;<d0.l:ポインタデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
freePointerDescTable::
	movem.l	d0/d3/a0-a2,-(sp)
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a1			;ポインタデスクリプタテーブルのアドレス
	bsr	getPointerDescCount
	bmi	9f
	move.l	d0,d3			;ポインタデスクリプタテーブルの参照数-1
	addq.l	#1,d3			;参照数
;ポインタデスクリプタテーブルの参照数を0にする
	moveq.l	#-1,d0
	moves.l	d0,(a0)			;参照数を0にする
;含まれるポインタデスクリプタが無効でなければページデスクリプタテーブルの参照数を減らす
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a1)+,d0
	tst.l	d0
	bne	2f
	bsr	subPageDescCount
2:	cmpa.l	a2,a1
	blo	1b
9:	bsr	cleanPointerDesc
	movem.l	(sp)+,d0/d3/a0-a2
	rts

;----------------------------------------------------------------
;作りかけのポインタデスクリプタテーブルがあれば開放する
;<sfc.l:FC_MMU_DATA
cleanPointerDesc::
	movem.l	d0/a0-a1,-(sp)
	move.l	pointerDescTail,d0
	cmp.l	pointerDescHead,d0
	beq	9f			;ポインタデスクリプタテーブルがない
	sub.l	#POINTER_DESC_SIZE,d0	;末尾のポインタデスクリプタテーブル
	movea.l	d0,a1			;末尾のポインタデスクリプタテーブル
	bsr	getPointerDescCount
	bpl	9f			;作りかけのポインタデスクリプタテーブルはない
1:	cmpa.l	pointerDescHead,a1
	beq	8f			;全部作りかけだった?
	lea.l	(-POINTER_DESC_SIZE,a1),a1	;1つ手前へ
	moves.l	-(a0),d0		;参照数
	tst.l	d0
	bmi	1b
8:	move.l	a1,pointerDescTail
9:	movem.l	(sp)+,d0/a0-a1
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを1つ0クリアする
;<d0.l:ポインタデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
clearPointerDescTable::
	movem.l	d0/a1-a2,-(sp)
	movea.l	d0,a1
	lea.l	(POINTER_DESC_SIZE,a1),a2
	moveq.l	#0,d0
@@:	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a1-a2
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを1つコピーする
;<d0.l:コピー先のポインタデスクリプタテーブルのアドレス
;<a0.l:コピー元のポインタデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
copyPointerDescTable::
	movem.l	d0/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	(POINTER_DESC_SIZE,a1),a2
@@:	moves.l	(a0)+,d0
	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルを比較する
;<d0.l:ポインタデスクリプタテーブルのアドレス
;<a0.l:ポインタデスクリプタテーブルのアドレス
;<sfc.l:FC_MMU_DATA
;>z-flag:eq=一致,ne=不一致
cmpPointerDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a0)+,d0
	moves.l	(a1)+,d1
;		                U W UDT
	and.w	#%1111111_11111_0_1_11,d0
	and.w	#%1111111_11111_0_1_11,d1
	cmp.l	d1,d0
	bne	2f
	cmpa.l	a2,a1
	blo	1b
	moveq.l	#0,d0
2:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;ポインタデスクリプタテーブルの参照数カウンタを求める
;<d0.l:ポインタデスクリプタテーブルの先頭
;<sfc.l:FC_MMU_DATA
;>d0.l:参照数カウンタ
;	-1	どこからも参照されていない
;	0	1箇所だけから参照されている
;>a0.l:参照数カウンタのアドレス
;>n-flag:mi=どこからも参照されていない(未使用),pl=参照されている(使用中)
;>z-flag:(pl)eq=1箇所だけから参照されている,ne=2箇所以上から参照されている
getPointerDescCount::
	and.l	#POINTER_DESC_MASK,d0
	sub.l	pointerDescHead,d0
	asr.l	#7,d0
	lea.l	([pointerCounterHead],d0.l),a0
	moves.l	(a0),d0
	tst.l	d0
	bpl	@f
	moveq.l	#-1,d0
@@:	rts


;----------------------------------------------------------------
;
;	ページデスクリプタの操作
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;ページデスクリプタを更新する
;<d0.l:ページデスクリプタテーブルの先頭
;<d1.l:ページデスクリプタ
;<a1.l:論理アドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:更新前のページデスクリプタ
;	0	ページデスクリプタが無効
;>z-flag:ne=ページデスクリプタが有効,eq=ページデスクリプタが無効
;>n-flag:pl
setPageDesc::
	move.l	a0,-(sp)
	bsr	getPageDesc
	moves.l	d1,(a0)
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;ページデスクリプタを取得する
;<d0.l:ページデスクリプタテーブルの先頭
;<a1.l:論理アドレス
;<sfc.l:FC_MMU_DATA
;>d0.l:ページデスクリプタ
;	0	ページデスクリプタが無効
;>a0.l:ページデスクリプタのアドレス(間接ページデスクリプタのとき(a0)≠d0)
;>z-flag:ne=ページデスクリプタが有効,eq=ページデスクリプタが無効
;>n-flag:pl
getPageDesc::
	move.l	d1,-(sp)
	movea.l	d0,a0
	move.l	a1,d0			;論理アドレス
	move.l	pageIndexWidth,d1	;ページインデックスフィールドのビット数(5～6)
	bfextu	d0{14:d1},d0		;ページインデックスフィールド
	lea.l	(a0,d0.l*4),a0		;ページデスクリプタのアドレス
	moves.l	(a0),d0			;ページデスクリプタ
	moveq.l	#%11,d1
	and.l	d0,d1			;PDT
	beq	9f			;PDT=%00(無効)
	subq.l	#%10,d1
	bne	8f			;PDT=%01,%11(有効)
	moves.l	(-2,za0,d0.l),d0	;ページデスクリプタ
	btst.l	#0,d0
	bne	8f			;PDT=%01,%11(有効)
9:	moveq.l	#0,d0
8:	move.l	(sp)+,d1
	tst.l	d0
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを1つ確保して0クリアする
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:ページデスクリプタテーブルのアドレス(0クリアされている)
;	-1	デスクリプタの領域が不足している
;>n-flag:pl=正常終了,mi=デスクリプタの領域が不足している
callocPageDescTable::
	bsr	allocPageDescTable
	bmi	9f
	bsr	clearPageDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを1つ複製する
;<a0.l:複製するページデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:複製されたページデスクリプタテーブルのアドレス
;	-1	デスクリプタの領域が不足している
;>n-flag:pl=正常終了,mi=デスクリプタの領域が不足している
dupPageDescTable::
	bsr	allocPageDescTable
	bmi	9f
	bsr	copyPageDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを1つ確保する
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:ページデスクリプタテーブルのアドレス
;	-1	デスクリプタの領域が不足している
;>n-flag:pl=正常終了,mi=デスクリプタの領域が不足している
allocPageDescTable::
	movem.l	a0-a1,-(sp)
	movea.l	pageCounterTail,a0
	movea.l	pageDescTail,a1
	bra	2f

1:	suba.l	pageDescSize,a1
	moves.l	-(a0),d0		;参照数-1
	tst.l	d0
	bmi	3f			;途中に未使用の領域があった
2:	cmpa.l	pageDescHead,a1
	bne	1b
;途中には未使用の領域がなかった
	suba.l	pageDescSize,a1		;ページデスクリプタテーブルの領域を伸ばしてみる
	cmpa.l	pointerDescTail,a1
	blo	9f			;デスクリプタテーブルの領域が不足している
	move.l	a1,pageDescHead		;ページデスクリプタテーブルの領域を伸ばす
	subq.l	#4,a0
;途中に未使用の領域があった
3:	moveq.l	#-1,d0
	moves.l	d0,(a0)			;参照数に0を設定
	move.l	a1,d0
8:	movem.l	(sp)+,a0-a1
	rts

;デスクリプタテーブルの領域が不足している
9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;ページデスクリプタテーブルがすべて無効ならばデスクリプタを無効にする
;<d0.l:ポインタデスクリプタのアドレス
;>z-flag:eq=デスクリプタを無効にした,ne=デスクリプタを無効にしなかった
invUpPageDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a2			;ポインタデスクリプタのアドレス
	moves.l	(a2),d1			;ポインタデスクリプタ
	and.l	pageDescMask,d1		;ページデスクリプタテーブルのアドレス
	movea.l	d1,a0
	lea.l	([pageDescSize],a0.l),a1
1:	moves.l	(a0)+,d0		;ページデスクリプタ
	tst.l	d0
	bne	9f
	cmpa.l	a1,a0
	blo	1b
	moveq.l	#0,d0
	moves.l	d0,(a2)			;ポインタデスクリプタを無効化する
	move.l	d1,d0
	bsr	freePageDescTable	;ページデスクリプタテーブルを削除する
	moveq.l	#0,d0
9:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルの参照数を1増やす
;<d0.l:ページデスクリプタテーブルの先頭
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
incPageDescCount::
	move.l	d3,-(sp)
	moveq.l	#1,d3
	bsr	addPageDescCount
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルの参照数を増やす
;<d0.l:ページデスクリプタテーブルの先頭
;<d3.l:増やす数
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
addPageDescCount::
	movem.l	d0/a0,-(sp)
	bsr	getPageDescCount
;現在の参照数が0でも処理すること
	add.l	d3,d0
	moves.l	d0,(a0)			;ページデスクリプタテーブルの参照数を増やす
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルの参照数を1減らす
;<d0.l:ページデスクリプタテーブルの先頭
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
decPageDescCount::
	move.l	d3,-(sp)
	moveq.l	#1,d3
	bsr	subPageDescCount
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルの参照数を減らす
;<d0.l:ページデスクリプタテーブルの先頭
;<d3.l:減らす数
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
subPageDescCount::
	movem.l	d0/a0,-(sp)
	bsr	getPageDescCount
	bmi	8f
	sub.l	d3,d0
	moves.l	d0,(a0)
	bcc	8f
	bsr	freePageDescTable	;どこからも参照されないので開放する
8:	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを1つ開放する
;<d0.l:ページデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
freePageDescTable::
	movem.l	d0/a0,-(sp)
	and.l	pageDescMask,d0
	bsr	getPageDescCount
	bmi	9f
	moveq.l	#-1,d0
	moves.l	d0,(a0)			;参照数を0にする
9:	bsr	cleanPageDesc
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;作りかけのページデスクリプタテーブルがあれば開放する
;<sfc.l:FC_MMU_DATA
cleanPageDesc::
	movem.l	d0/a0-a1,-(sp)
	move.l	pageDescHead,d0
	cmp.l	pageDescTail,d0
	beq	9f			;ページデスクリプタテーブルがない
	movea.l	d0,a1			;先頭のページデスクリプタテーブル
	bsr	getPageDescCount
	bpl	9f			;作りかけのページデスクリプタテーブルはない
1:	lea.l	([pageDescSize],a1.l),a1	;1つ後ろへ
	addq.l	#4,a0
	cmpa.l	pageDescTail,a1
	beq	8f			;全部作りかけだった?
	moves.l	(a0),d0			;参照数
	tst.l	d0
	bmi	1b
8:	move.l	a1,pageDescHead
9:	movem.l	(sp)+,d0/a0-a1
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを1つ0クリアする
;<d0.l:ページデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
clearPageDescTable::
	movem.l	d0/a1-a2,-(sp)
	movea.l	d0,a1
	lea.l	([pageDescSize],a1.l),a2
	moveq.l	#0,d0
@@:	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a1-a2
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを1つコピーする
;<d0.l:コピー先のページデスクリプタテーブルのアドレス
;<a0.l:コピー元のページデスクリプタテーブルのアドレス
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
copyPageDescTable::
	movem.l	d0/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	([pageDescSize],a1.l),a2
@@:	moves.l	(a0)+,d0
	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルを比較する
;<d0.l:ページデスクリプタテーブルのアドレス
;<a0.l:ページデスクリプタテーブルのアドレス
;<sfc.l:FC_MMU_DATA
;>z-flag:eq=一致,ne=不一致
cmpPageDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	([pageDescSize],a1.l),a2
1:	moves.l	(a0)+,d0
	moves.l	(a1)+,d1
;		      UR G U1U0 S CM M U W PDT
	and.w	#%111_11_1__11__1_11_0_0_1_11,d0
	and.w	#%111_11_1__11__1_11_0_0_1_11,d1
	cmp.l	d1,d0
	bne	2f
	cmpa.l	a2,a1
	blo	1b
	moveq.l	#0,d0
2:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;ページデスクリプタテーブルの参照数カウンタを求める
;<d0.l:ページデスクリプタテーブルの先頭
;<sfc.l:FC_MMU_DATA
;>d0.l:参照数カウンタ
;	-1	どこからも参照されていない
;	0	1箇所だけから参照されている
;>a0.l:参照数カウンタのアドレス
;>n-flag:mi=どこからも参照されていない(未使用),pl=参照されている(使用中)
;>z-flag:(pl)eq=1箇所だけから参照されている,ne=2箇所以上から参照されている
getPageDescCount::
	and.l	pageDescMask,d0
	sub.l	pageDescTail,d0
	move.l	d1,-(sp)
	move.l	pageIndexWidth,d1
	asr.l	d1,d0			;d0は負数なのでlsrは不可
	move.l	(sp)+,d1
	lea.l	([pageCounterTail],d0.l),a0
	moves.l	(a0),d0
	tst.l	d0
	bpl	@f
	moveq.l	#-1,d0
@@:	rts


;----------------------------------------------------------------
;
;	ローカルメモリ
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;論理アドレス範囲がDMA転送可能か調べる
;	範囲内に非常駐ページがあるとアクセスエラーが発生してしまう
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<d1.l:論理アドレス(先頭)
;<d2.l:論理アドレス(末尾+1)
;>n-flag:mi=DMA転送不可能,pl=DMA転送可能
dmaAccessCheck::
	movem.l	d0-d1/d3/a0-a1,-(sp)
  debug '|dmaAccessCheck in (top,btm)=',2,d1,d2
	and.l	pageMask,d1		;先頭があるページの先頭
					;pageMaskはLOGICAL_MASKを伴うこと
	and.l	#LOGICAL_MASK,d2	;末尾+1
					;bit31が1になっているときd1だけマスクすると
					;範囲が2GB以上になってしまう
	tst.b	localSystemArea
	bne	@f
	cmp.l	([$1C20.w],Tail),d2	;(-lsでないとき)Humanの中ならばチェックは省略
	blo	4f
@@:	lea.l	(readTranslation,pc),a0
	tst.l	d0
	beq	@f
	lea.l	(writeTranslation,pc),a0
@@:	movec.l	dfc,d3
	moveq.l	#FC_SUPER_DATA,d0
	movec.l	d0,dfc
1:	movea.l	d1,a1
;<a1.l:論理アドレス
	jsr	(a0)			;論理アドレスを物理アドレスに変換
;<a1.l:物理アドレス
	cmpa.l	d1,a1
	bne	2f			;物理アドレスが論理アドレスと異なる
					;$00000000と$01000000でも異なると判断される
	move.l	a1,d0
	bsr	physicalToLocal
	bpl	2f			;ローカルメモリ
	add.l	pageOffsetSize,d1	;次のページの先頭
	cmp.l	d2,d1			;ページの先頭が末尾+1以上ならば終了
	blo	1b
4:	moveq.l	#0,d0			;DMA転送可能
	bra	3f

2:	moveq.l	#-1,d0			;DMA転送不可能
3:
  debug '|dmaAccessCheck out (0=DMA enable)=',1,d0
	movec.l	d3,dfc
	tst.l	d0
	movem.l	(sp)+,d0-d1/d3/a0-a1
	rts

;物理アドレスのチェック(デバイスからメモリへ転送)
;<a1.l:論理アドレス
;<dfc:チェックするアドレス空間
;>a1.l:物理アドレス
readTranslation:
	tst.b	noTranslation
	bne	90f
	movem.l	d0-d1/a0,-(sp)
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc			;論理アドレスからページデスクリプタを求める
	bmi	9f			;ページデスクリプタがない
	beq	9f			;非常駐
	btst.l	#PD_W_BIT,d0
	bne	9f			;ライトプロテクトされている
	and.l	pageMask,d0		;ページの先頭アドレス
	move.l	a1,d1
	and.l	pageOffsetMask,d1	;オフセット
	or.l	d1,d0			;ページの先頭アドレスにオフセットを合成する
8:	movea.l	d0,a1			;物理アドレス
	POP_SFC_DFC	d1
	movem.l	(sp)+,d0-d1/a0
90:	rts

9:	moveq.l	#-1,d0			;失敗
	bra	8b

;物理アドレスのチェック(メモリからデバイスへ転送)
;<a1.l:論理アドレス
;<dfc:チェックするアドレス空間
;>a1.l:物理アドレス
writeTranslation:
	tst.b	noTranslation
	bne	90f
	movem.l	d0-d1/a0,-(sp)
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc			;論理アドレスからページデスクリプタを求める
	bmi	9f			;ページデスクリプタがない
	beq	9f			;非常駐
	and.l	pageMask,d0		;ページの先頭アドレス
	move.l	a1,d1
	and.l	pageOffsetMask,d1	;オフセット
	or.l	d1,d0			;ページの先頭アドレスにオフセットを合成する
8:	movea.l	d0,a1			;物理アドレス
	POP_SFC_DFC	d1
	movem.l	(sp)+,d0-d1/a0
90:	rts

9:	moveq.l	#-1,d0			;失敗
	bra	8b

;----------------------------------------------------------------
;物理アドレスがローカルメモリを指しているか調べる
;<d0.l:物理アドレス
;>d0.l:結果
;	-1	ローカルメモリではない
;	その他	ローカルメモリの物理アドレス
;>n-flag:mi=ローカルメモリではない,pl=ローカルメモリ
physicalToLocal::
	tst.l	localMemorySize
	beq	9f
	and.l	#LOGICAL_MASK,d0
	sub.l	localMemoryStart,d0
	cmp.l	localMemorySize,d0
	bcc	9f
	add.l	localMemoryStart,d0
	rts

9:	moveq.l	#-1,d0
	rts

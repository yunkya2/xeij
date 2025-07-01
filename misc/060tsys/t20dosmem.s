;----------------------------------------------------------------
;
;	メモリ管理関連のDOSCALL
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;_MALLOC	ブロックの確保(下位から)
;<(a6).l:確保するブロックのサイズ
;>d0.l:確保したブロックのユーザ領域の先頭
;	$81xxxxxx=確保できる最大のサイズ,$82000000=まったく確保できない
;*d0,?d2/d4-d5/a0-a5
dosMalloc::
  debug '|malloc in (size)=',1,(a6)
	bsr	dosAreaLockMalloc
	bmi	dosMallocNever
;<a2.l:(次候補)メモリ空間の先頭(先頭のブロックのヘッダ)
;<a3.l:(次候補)メモリ空間の末尾+1(16バイトアラインメント)
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	(a6),d2			;確保するサイズ
;<d2.l:確保するサイズ
	cmp.l	#$00FFFFF0,d2		;$00FFFFF0よりも大きいときは最大サイズの取得と見なす
	bhi	dosMallocGetSize
;ブロックを確保する
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	bsr	malloc20		;ブロックの確保(下位から)
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bpl	dosMallocDone
	movea.l	a2,a4
	movea.l	a3,a5
	bsr	malloc20
	bmi	dosMallocFailed
dosMallocDone:
	move.l	a1,d0
dosMallocEnd:
	bsr	dosAreaUnlock
  debug '|malloc out (ptr)=',1,d0
	tst.l	d0
	rts

;最大サイズの取得
dosMallocGetSize:
	movea.l	a2,a4			;最大のサイズは優先範囲に制限せずに求める
	movea.l	a3,a5
	bsr	getSize
	move.l	d1,d0			;一度に確保できる最大のサイズ
dosMallocFailed:
	lsl.l	#1,d0
	beq	dosMallocNever		;まったく確保できない
	lsr.l	#1,d0
	cmp.l	#$00FFFFF0,d0
	bls	@f
	move.l	#$00FFFFF0,d0		;$00FFFFFFは不可(もう1度$00FFFFFFで呼ばれてしまうから)
@@:	or.l	#$81000000,d0
	bra	dosMallocEnd

dosMallocNever:
	move.l	#$82000000,d0		;まったく確保できない
	bra	dosMallocEnd

;----------------------------------------------------------------
;_MALLOC3	ブロックの確保(下位から)
;<(a6).l:確保するブロックのサイズ
;>d0.l:確保したブロックのユーザ領域の先頭
;	$8xxxxxxx=確保できる最大のサイズ
;*d0,?d2/d4-d5/a0-a5
dosMalloc3::
  debug '|malloc3 in (size)=',1,(a6)
  debugChar '!'
	bsr	dosAreaLockMalloc
	bmi	dosMalloc3Never
  debugChar '@'
;<a2.l:(次候補)メモリ空間の先頭(先頭のブロックのヘッダ)
;<a3.l:(次候補)メモリ空間の末尾+1(16バイトアラインメント)
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	(a6),d2			;確保するサイズ
;<d2.l:確保するサイズ
;ブロックを確保する
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	bsr	malloc20		;ブロックの確保(下位から)
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bpl	dosMalloc3Done
	movea.l	a2,a4
	movea.l	a3,a5
	bsr	malloc20
	bmi	dosMalloc3End
dosMalloc3Done:
	move.l	a1,d0
dosMalloc3End:
	bsr	dosAreaUnlock
  debug '|malloc3 out (ptr)=',1,d0
	tst.l	d0
	rts

dosMalloc3Never:
	move.l	#$80000000,d0
	bra	dosMalloc3End

;----------------------------------------------------------------
;_MFREE		ブロックの開放
;(a6).l:開放するブロックのユーザ領域の先頭
;	0=実行中のプロセスが確保したブロックをすべて開放する
;>d0.l:エラーコード
;	$FFFFFFF7=無効なブロックを指定した
;*d0,?d2/d4-d5/a0-a5
dosMfree::
  debug '|mfree in (ptr)=',1,(a6)
	moveq.l	#8,d5			;制限なし,優先なし
	bsr	dosAreaLock
	bmi	dosMfreeNotFound
;制限なし,優先なしなのでa2-a3はa4-a5と同じ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	(a6),d2			;開放するブロックのユーザ領域の先頭
	beq	dosMfreeProc		;実行中のプロセスが確保したブロックをすべて開放
;<d2.l:開放するブロックのユーザ領域の先頭
dosMfreeSMfree::
	bsr	free
;<d0.l:0=成功,-1=ヘッダが見つからない
	bmi	dosMfreeNotFound	;開放できない
dosMfreeEnd:
	bsr	dosAreaUnlock
  debug '|mfree out (error-code)=',1,d0
	tst.l	d0
	rts

;実行中のプロセスが確保したブロックをすべて開放
dosMfreeProc:
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	bsr	psfree
;<d0.l:0(常に成功する)
	bra	dosMfreeEnd

dosMfreeNotFound:
	moveq.l	#$FFFFFFF7,d0		;無効なブロックを指定した
	bra	dosMfreeEnd

;----------------------------------------------------------------
;_SETBLOCK	ブロックのサイズ変更
;	ブロックは移動しない
;<(a6).l:サイズを変更するブロックのユーザ領域の先頭
;<(4,a6).l:新しいサイズ
;>d0.l:エラーコード
;	$FFFFFFF7=無効なブロックを指定した
;	$81xxxxxx=確保できる最大のサイズ
;*d0,?d2-d3/d5/a0-a5
dosSetblock::
  debug '|setblock in (ptr,size)=',2,(a6),(4,a6)
	moveq.l	#8,d5			;制限なし,優先なし
	bsr	dosAreaLock
	bmi	dosSetblockNotFound
;制限なし,優先なしなのでa2-a3はa4-a5と同じ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	(a6),d2
	move.l	(4,a6),d3
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ
	cmp.l	#$00FFFFF0,d3		;$00FFFFF0よりも大きいときは最大サイズの取得と見なす
	bhi	dosSetblockGetSize
;サイズを変更する
	bsr	resize
;<d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
	bmi	dosSetblockFailed
dosSetblockEnd:
	bsr	dosAreaUnlock
  debug '|setblock out (error-code)=',1,d0
	tst.l	d0
	rts

;最大サイズの取得
dosSetblockGetSize:
	moveq.l	#-1,d3			;必ずエラーを出す
	bsr	resize
dosSetblockFailed:
;<d0.l:-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
	cmp.l	#$FFFFFFFF,d0
	beq	dosSetblockNotFound
	cmp.l	#$80FFFFF0,d0
	blo	@f
	move.l	#$80FFFFF0,d0		;$80FFFFFFは不可(もう1度$00FFFFFFで呼ばれてしまうから)
@@:	or.l	#$81000000,d0
	bra	dosSetblockEnd

dosSetblockNotFound:
	moveq.l	#$FFFFFFF7,d0		;無効なブロックを指定した
	bra	dosSetblockEnd

;----------------------------------------------------------------
;_SETBLOCK2	ブロックのサイズ変更
;	ブロックは移動しない
;<(a6).l:サイズを変更するブロックのユーザ領域の先頭
;<(4,a6).l:新しいサイズ
;>d0.l:エラーコード
;	$FFFFFFF7=無効なブロックを指定した
;	$8xxxxxxx=確保できる最大のサイズ
;*d0,?d2-d3/d5/a0-a5
dosSetblock2::
  debug '|setblock2 in (ptr,size)=',2,(a6),(4,a6)
	moveq.l	#8,d5			;制限なし,優先なし
	bsr	dosAreaLock
	bmi	dosSetblock2NotFound
;制限なし,優先なしなのでa2-a3はa4-a5と同じ
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	move.l	(a6),d2
	move.l	(4,a6),d3
;<d2.l:サイズを変更するブロックのユーザ領域の先頭
;<d3.l:新しいサイズ
;サイズを変更する
	bsr	resize
;<d0.l:0=成功,-1=ヘッダが見つからない,$8xxxxxxx=確保できる最大のサイズ
	cmp.l	#$FFFFFFFF,d0
	beq	dosSetblock2NotFound
dosSetblock2End:
	bsr	dosAreaUnlock
  debug '|setblock2 out (error-code)=',1,d0
	tst.l	d0
	rts

dosSetblock2NotFound:
	moveq.l	#$FFFFFFF7,d0		;無効なブロックを指定した
	bra	dosSetblock2End

;----------------------------------------------------------------
;_MALLOC2	ブロックの確保(モード指定あり)
;<(a6).w:bit15=プロセス指定フラグ(0=実行中のプロセス,1=(6,a6).lを親プロセスとして使用する)
;	下位8bit=モード(0=下位から,1=必要最小ブロックから,2=上位から,3=最大ブロックから)
;<(2,a6).l:確保するサイズ
;<(6,a6).l:((a6).wのbit15が1のとき)親プロセスのメモリ管理テーブル
;>d0.l:確保したブロックのユーザ領域の先頭
;	$FFFFFFF2=パラメータが無効
;	$81xxxxxx=確保できる最大のサイズ,$82000000=まったく確保できない
;*d0,?d2-d4/a0-a5
dosMalloc2::
  debug '|malloc2 in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	bsr	dosAreaLockMalloc
	bmi	dosMalloc2Never
;<a2.l:(次候補)メモリ空間の先頭(先頭のブロックのヘッダ)
;<a3.l:(次候補)メモリ空間の末尾+1(16バイトアラインメント)
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
dosMalloc2SMalloc::
	move.l	(2,a6),d2		;確保するサイズ
;<d2.l:確保するサイズ
	cmp.l	#$00FFFFF0,d2		;00FFFFF0よりも大きいときは最大サイズの取得と見なす
	bhi	dosMalloc2GetSize
;親プロセスのメモリ管理テーブルを求める
	bsr	getProc
	move.w	(a6),d3			;モード
	bpl	@f
	move.l	(6,a6),d4		;親プロセスのメモリ管理テーブル
	and.w	#$7FFF,d3
@@:	cmp.w	#4,d3
	bcc	dosMalloc2ParamError
;ブロックを確保する
;<d4.l:実行中のプロセスのメモリ管理テーブル
	jsr	([malloc2Table,d3.w*4])	;ブロックの確保
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bpl	dosMalloc2Done
	movea.l	a2,a4
	movea.l	a3,a5
	jsr	([malloc2Table,d3.w*4])	;ブロックの確保
	bmi	dosMalloc2Failed
dosMalloc2Done:
	move.l	a1,d0
dosMalloc2End:
	bsr	dosAreaUnlock
  debug '|malloc2 out (ptr)=',1,d0
	tst.l	d0
	rts

;最大サイズの取得
dosMalloc2GetSize:
	movea.l	a2,a4			;最大のサイズは優先範囲に制限せずに求める
	movea.l	a3,a5
	bsr	getSize
	move.l	d1,d0			;一度に確保できる最大のサイズ
dosMalloc2Failed:
	lsl.l	#1,d0
	beq	dosMalloc2Never		;まったく確保できない
	lsr.l	#1,d0
	cmp.l	#$00FFFFF0,d0
	bls	@f
	move.l	#$00FFFFF0,d0		;$00FFFFFFは不可(もう1度$00FFFFFFで呼ばれてしまうから)
@@:	or.l	#$81000000,d0
	bra	dosMalloc2End

dosMalloc2Never:
	move.l	#$82000000,d0		;まったく確保できない
	bra	dosMalloc2End

dosMalloc2ParamError:
	moveq.l	#$FFFFFFF2,d0		;パラメータが無効
	bra	dosMalloc2End

;----------------------------------------------------------------
;_MALLOC4	ブロックの確保(モード指定あり)
;<(a6).w:bit15=プロセス指定フラグ(0=実行中のプロセス,1=d4.lを親プロセスとして使用する)
;	下位8bit=モード(0=下位から,1=必要最小ブロックから,2=上位から,3=最大ブロックから)
;<(2,a6).l:確保するサイズ
;<(6,a6).l:((a6).wのbit15が1のとき)親プロセスのメモリ管理テーブル
;>d0.l:確保したブロックのユーザ領域の先頭
;	$FFFFFFF2=パラメータが無効
;	$8xxxxxxx=確保できる最大のサイズ
;*d0,?d2-d5/a0-a5
dosMalloc4::
  debug '|malloc4 in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	bsr	dosAreaLockMalloc
	bmi	dosMalloc4Never
;<a2.l:(次候補)メモリ空間の先頭(先頭のブロックのヘッダ)
;<a3.l:(次候補)メモリ空間の末尾+1(16バイトアラインメント)
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
dosMalloc4SMalloc::
	move.l	(2,a6),d2		;確保するサイズ
;<d2.l:確保するサイズ
	move.w	(a6),d3			;モード
	bpl	@f
	move.l	(6,a6),d4		;親プロセスのメモリ管理テーブル
	and.w	#$7FFF,d3
@@:	cmp.w	#4,d3
	bcc	dosMalloc4ParamError
;ブロックを確保する
	bsr	getProc
;<d4.l:実行中のプロセスのメモリ管理テーブル
	jsr	([malloc2Table,d3.w*4])	;ブロックの確保
;<d0.l:0=成功,$8xxxxxxx=確保できる最大のサイズ
;<a1.l:0=失敗,0以外=確保したブロックのユーザ領域の先頭
	bpl	dosMalloc4Done
	movea.l	a2,a4
	movea.l	a3,a5
	jsr	([malloc2Table,d3.w*4])	;ブロックの確保
	bmi	dosMalloc4End
dosMalloc4Done:
	move.l	a1,d0
dosMalloc4End:
	bsr	dosAreaUnlock
  debug '|malloc4 out (ptr)=',1,d0
	tst.l	d0
	rts

dosMalloc4Never:
	move.l	#$80000000,d0		;まったく確保できない
	bra	dosMalloc4End

dosMalloc4ParamError:
	moveq.l	#$FFFFFFF2,d0		;パラメータが無効
	bra	dosMalloc4End

;----------------------------------------------------------------
;アクセスできないメモリ空間を制限する
;	自分以外の連続メモリ型サブスレッドのすべてのブロックをロックする
;	_EXECの場合はプログラムのロード範囲の制限を受ける
;	_EXEC以外ではアロケート範囲の制限を受ける
;	次候補は優先して確保する範囲に制限する前の範囲なので優先する範囲を含む
;<d5.b:モード
;	0	下位のみ
;	1	上位のみ
;	2	親と同じ側のみ
;	3	親と反対側のみ
;	4	制限なし,下位優先
;	5	制限なし,上位優先
;	6	制限なし,親と同じ側優先
;	7	制限なし,親と反対側優先
;	8	制限なし,優先なし
;>d0.l:0=成功,-1=失敗
;>a2.l:(次候補)メモリ空間の先頭(先頭のブロックのヘッダ)
;>a3.l:(次候補)メモリ空間の末尾+1(16バイトアラインメント)
;>a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;>a5.l:メモリ空間の末尾+1(16バイトアラインメント)
;*d0/a2-a5,?a0-a1
dosAreaLockMalloc::
	cmpi.b	#_EXEC-$FF00,$1C0A.w	;レベル0で入ったDOSコール番号
	bne	dosAreaLockNotExec
;_EXECのとき
	moveq.l	#1,d5			;loadhighのときは上位のみ
	tst.b	execLoadHigh
	bne	dosAreaLock
	move.b	defaultLoadArea,d5
	bra	dosAreaLock

;_EXEC以外のとき
dosAreaLockNotExec:
	movea.l	([$1C28.w]),a0		;親プロセスのプロセス管理テーブル
	move.b	(pAllocArea,a0),d5
;<d5.b:モード
;	0	下位のみ
;	1	上位のみ
;	2	親と同じ側のみ
;	3	親と反対側のみ
;	4	制限なし,下位優先
;	5	制限なし,上位優先
;	6	制限なし,親と同じ側優先
;	7	制限なし,親と反対側優先
;	8	制限なし,優先なし
dosAreaLock::
  debugByte '|dosAreaLock in (mode)=',1,d5
	movea.l	$1C54.w,a0		;現在のスレッドのスレッド管理テーブル
	bsr	lockBlocks		;自分以外のサブスレッドのブロックをロックする
	movea.l	$1C04.w,a4		;メモリ空間の先頭
	movea.l	$1C00.w,a5		;メモリ空間の末尾+1
	movea.l	a4,a2			;優先する範囲に制限する前のメモリ空間の先頭
	movea.l	a5,a3			;優先する範囲に制限する前のメモリ空間の末尾+1
	move.b	d5,d0
	beq	dosAreaLockLowerOnly	;0=下位のみ
	subq.b	#2,d0
	bcs	dosAreaLockUpperOnly	;1=上位のみ
	beq	dosAreaLockProcOnly	;2=親と同じ側のみ
	subq.b	#2,d0
	bcs	dosAreaLockNotProcOnly	;3=親と反対側のみ
	beq	dosAreaLockLower	;4=制限なし,下位優先
	subq.b	#2,d0
	bcs	dosAreaLockUpper	;5=制限なし,上位優先
	beq	dosAreaLockProc		;6=制限なし,親と同じ側優先
	subq.b	#2,d0
	bcs	dosAreaLockNotProc	;7=制限なし,親と反対側優先
					;8=制限なし,優先なし
dosAreaLockEnd:
	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

dosAreaLockFailed:
	moveq.l	#-1,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;親と反対側のみ
dosAreaLockNotProcOnly:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockUpperOnly
;下位のみ
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockLowerOnly:
;上位の部分を切り捨てる
	move.l	himemAreaStart,d0	;下位メモリの上限
	beq	@f			;上位がない
	cmpa.l	d0,a5
	bls	@f			;既に下位だけに制限されている
	cmpa.l	d0,a4
	bhs	dosAreaLockFailed	;上位だけに制限されている
	movea.l	d0,a5			;末尾+1を制限する
	movea.l	a5,a3			;次候補も制限する
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;親と同じ側のみ
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockProcOnly:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockLowerOnly
;上位のみ
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockUpperOnly:
;下位の部分を切り捨てる,下位しかないときは条件を無視する
	move.l	himemAreaStart,d0	;上位メモリの下限
	beq	@f			;下位しかないので条件を無視する
	cmpa.l	d0,a4
	bhs	@f			;既に上位だけに制限されている
	cmpa.l	d0,a5
	bls	dosAreaLockFailed	;下位だけに制限されている
	movea.l	d0,a4			;先頭を制限する
	movea.l	a4,a2			;次候補も制限する
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;制限なし,親と反対側優先
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockNotProc:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockUpper
;制限なし,下位優先
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockLower:
;上位と下位の境目を跨いでいるときだけ制限する
	move.l	himemAreaStart,d0	;下位メモリの上限
	beq	@f			;下位しかない
	cmpa.l	d0,a5
	bls	@f			;既に下位だけに制限されている
	cmpa.l	d0,a4
	bhs	@f			;上位だけに制限されている
	movea.l	d0,a5			;末尾+1を制限する
					;次候補は制限しない
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;制限なし,親と同じ側優先
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockProc:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockLower
;制限なし,上位優先
;<a0.l:親プロセスのプロセス管理テーブル
dosAreaLockUpper:
;上位と下位の境目を跨いでいるときだけ制限する
	move.l	himemAreaStart,d0	;上位メモリの下限
	beq	@f			;下位しかないので制限できない
	cmpa.l	d0,a4
	bhs	@f			;既に上位だけに制限されている
	cmpa.l	d0,a5
	bls	@f			;下位しかないので制限できない
	movea.l	d0,a4			;先頭を制限する
					;次候補は制限しない
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;----------------------------------------------------------------
;アクセスできるメモリ空間の制限を解除する
;	ブロックのロックを解除する
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
dosAreaUnlock::
	bsr	unlockBlocks
	rts

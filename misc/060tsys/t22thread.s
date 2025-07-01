;----------------------------------------------------------------
;
;	スレッド関係のDOSコールのパッチ
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t03memory.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;_S_MALLOC	メインスレッドのメモリ空間からのブロックの確保
;<(a6).w:bit15=プロセス指定フラグ(0=実行中のプロセス,1=(6,a6).lを親プロセスとして使用する)
;	下位8bit=モード(0=下位から,1=必要最小ブロックから,2=上位から,3=最大ブロックから)
;<(2,a6).l:確保するサイズ
;<(6,a6).l:((a6).wのbit15が1のとき)親プロセスのメモリ管理テーブル
;>d0.l:確保したブロックのユーザ領域の先頭
;	$81xxxxxx=確保できる最大のサイズ,$82000000=まったく確保できない
;*d0,?d2-d4/a0-a5
dosSMalloc::
  debug '|s_malloc in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	movea.l	$1C50.w,a0		;メインスレッドのスレッド管理テーブル
	cmpa.l	$1C54.w,a0		;実行中のスレッドのスレッド管理テーブル
	beq	dosMalloc2		;メインスレッド実行中ならば_MALLOC2で済ます
;<a0.l:メインスレッドのスレッド管理テーブル
	bsr	lockBlocks		;自分を含めたすべてのサブスレッドのブロックをロックする
	movea.l	$1C50.w,a3		;メインスレッドのスレッド管理テーブル
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	movea.l	a4,a2
	movea.l	a5,a3
	bra	dosMalloc2SMalloc

;----------------------------------------------------------------
;_S_MALLOC2	メインスレッドのメモリ空間からのブロックの確保
;<(a6).w:bit15=プロセス指定フラグ(0=実行中のプロセス,1=(6,a6).lを親プロセスとして使用する)
;	下位8bit=モード(0=下位から,1=必要最小ブロックから,2=上位から,3=最大ブロックから)
;<(2,a6).l:確保するサイズ
;<(6,a6).l:((a6).wのbit15が1のとき)親プロセスのメモリ管理テーブル
;>d0.l:確保したブロックのユーザ領域の先頭
;	$8xxxxxxx=確保できる最大のサイズ
;*d0,?d2-d4/a0-a5
dosSMalloc2::
  debug '|s_malloc2 in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	movea.l	$1C50.w,a0		;メインスレッドのスレッド管理テーブル
	cmpa.l	$1C54.w,a0		;実行中のスレッドのスレッド管理テーブル
	beq	dosMalloc4		;メインスレッド実行中ならば_MALLOC4で済ます
;<a0.l:メインスレッドのスレッド管理テーブル
	bsr	lockBlocks		;自分を含めたすべてのサブスレッドのブロックをロックする
	movea.l	$1C50.w,a3		;メインスレッドのスレッド管理テーブル
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:メモリ空間の先頭(先頭のブロックのヘッダ)
;<a5.l:メモリ空間の末尾+1(16バイトアラインメント)
	movea.l	a4,a2
	movea.l	a5,a3
	bra	dosMalloc4SMalloc

;----------------------------------------------------------------
;_S_MFREE	メインスレッドのメモリ空間からのブロックの開放
;	現在のスレッドのメモリ空間の先頭(先頭のブロックのヘッダ)ならばスレッドを破棄する
;	それ以外はメインスレッドのメモリ管理でロックを行わずに_MFREEを行う
;<(a6).l:開放するブロックのユーザ領域の先頭
;>d0.l:エラーコード
;*d0,?d1-d2/a0/a2-a5
dosSMfree::
  debug '|s_mfree in (ptr)=',1,(a6)
	move.w	currentThreadId,d1	;現在のスレッド番号
	beq	dosMfree		;メインスレッドを実行中ならば_MFREEするだけ
;<d1.w:現在のスレッド番号
	move.l	(a6),d2			;開放するブロックのユーザ領域の先頭
;<d2.l:開放するブロックのユーザ領域の先頭
	movea.l	$1C50.w,a3		;メインスレッドのスレッド管理テーブルの先頭アドレス
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:メインスレッドのメモリ空間の先頭
;<a5.l:メインスレッドのメモリ空間の末尾+1
	movea.l	$1C54.w,a3		;現在のスレッドのスレッド管理テーブル
;<a3.l:現在のスレッドのスレッド管理テーブル
	move.l	(tMemStart,a3),d0	;現在のスレッドの先頭のブロックのヘッダ
	cmpa.l	d0,a4
	beq	dosMfreeSMfree		;メインスレッドと同じメモリ空間ならば_MFREEするだけ
	cmp.l	d0,d2
	bne	dosMfreeSMfree		;現在のスレッドの先頭のブロックでなければ_MFREEするだけ
;ブロックを検索する
	bsr	searchBlock		;メインスレッドのメモリ空間から検索する
	bpl	dosSMfreeContinuous	;連続メモリ型サブスレッド
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2
	bsr	searchBlock		;メインスレッドのメモリ空間から検索する
	bmi	dosSMfreeParamError	;パラメータが無効

;サブメモリ型サブスレッド
;	排他制御情報を破棄する
;	メインスレッドのメモリ空間に変更
;	サブスレッドのメモリ空間の親ブロックのフラグを消す
;	サブスレッドのメモリ空間の親ブロックのヘッダを削除する
;	サブスレッドのメモリ空間をメインスレッドのメモリ空間に結合する
;<d1.w:スレッド番号
;<a2.l:親ブロックのヘッダ
;<a4.l:メインスレッドのメモリ空間の先頭
;<a5.l:メインスレッドのメモリ空間の末尾+1
	tst.b	backgroundFlag
	beq	@f
	move.w	d1,d0
	bsr	killExclusive		;排他制御情報を破棄する
@@:	move.l	a4,$1C04.w		;メインスレッドのメモリ空間に変更
	move.l	a5,$1C00.w
	andi.b	#LOGICAL_MASK>>24,(Proc,a2)	;親ブロックのフラグを消す
	lea.l	(User,a2),a0		;先頭のブロックのヘッダ
	move.l	(Proc,a2),(Proc,a0)	;先頭のブロックの親プロセスを親ブロックの親プロセスにする
	movea.l	(a2),a1			;親ブロックの直前
	move.l	a1,(Prev,a0)		;先頭のブロックの直前を親ブロックの直前にする
	beq	@f
	move.l	a0,(Next,a1)		;親ブロックの直前の直後を先頭のブロックにする
@@:
1:	move.l	(Next,a0),d0
	beq	2f
	movea.l	d0,a0
	move.l	(Next,a0),d0
	bne	1b
2:
;<a0.l:最後のブロックのヘッダ
	movea.l	(Next,a2),a1
	move.l	a1,(Next,a0)		;末尾の直後を親ブロックの直後にする
	beq	@f
	move.l	a0,(Prev,a1)		;サブの直後の直前を末尾にする
@@:
	bra	dosSMfreeSetEnd

;連続メモリ型サブスレッド
;	排他制御情報を破棄する
;	メインスレッドのメモリ空間に変更
;	サブスレッドのメモリ空間の先頭のブロックのフラグを消す
;	サブスレッドのメモリ空間の直後のダミーのブロックのヘッダを削除する
;<d1.w:スレッド番号
;<a2.l:先頭のブロックのヘッダ
;<a3.l:現在のスレッドのスレッド管理テーブル
;<a4.l:メインスレッドのメモリ空間の先頭
;<a5.l:メインスレッドのメモリ空間の末尾+1
dosSMfreeContinuous:
	tst.b	backgroundFlag
	beq	@f
	move.w	d1,d0
	bsr	killExclusive		;排他制御情報を破棄する
@@:	move.l	a4,$1C04.w		;メインスレッドのメモリ空間に変更
	move.l	a5,$1C00.w
	andi.b	#LOGICAL_MASK>>24,(Proc,a2)	;先頭のブロックのフラグを消す
	movea.l	(tMemEnd,a3),a5
	movea.l	a2,a0
	move.l	a2,d0
1:	cmp.l	a5,d0
	bcc	2f
	movea.l	d0,a0
	move.l	(Next,a0),d0
	bne	1b
	bra	3f
2:
;<d0.l:最後のブロックの次のブロックのヘッダ
;<a0.l:最後のブロックのヘッダ
	cmp.l	a5,d0
	bne	3f			;メモリ空間の直後にブロックがない
	movea.l	(Next,a5),a1
	move.l	a1,(Next,a0)		;最後のブロックの直後をダミーのブロックの直後にする
	beq	@f
	move.l	a0,(Prev,a1)		;ダミーのブロックの直後の直前を最後のブロックにする
@@:
3:
;<a2.l:先頭のブロックのヘッダ
dosSMfreeSetEnd:
	addq.l	#4,sp
	movem.l	(sp)+,d1-d7/a0-a4
  debug '|s_mfree done; jump to kill_pr',0
	move.l	killPrEntry,-(sp)	;_KILL_PRへ
	rts

dosSMfreeParamError:
	moveq.l	#$FFFFFFF2,d0		;パラメータが無効
  debug '|s_mfree out; illegal parameter',0
	rts

;----------------------------------------------------------------
;_S_PROCESS	サブスレッドのメモリ空間の設定
;	サブメモリ型サブスレッドのときサブスレッドのメモリ空間の先頭のブロックのヘッダを作る
;	連続メモリ型サブスレッドのときサブスレッドのメモリ空間の直後にダミーのヘッダを作る
;	排他制御情報を作成する
;<(a6).w:スレッド番号
;<(2,a6).l:ブロックの先頭アドレス
;<(6,a6).l:サブのメモリ管理のサイズ
;<(10,a6).l:先頭のブロックのサイズ
;>d0.l:先頭のブロックのユーザ領域の先頭
;	$FFFFxxxx=最大スレッド番号,$FFFFFFF2=ブロックの指定が違う
;*d0,?d1-d4/d7/a0-a2/a4-a5
dosSProcess::
  debug '|s_process in (thread-id,ptr,size,head-size)=',4,(-2,a6),(2,a6),(6,a6),(10,a6)
	moveq.l	#$FFFFFFFF,d0
	move.w	($1C58).w,d0		;processのスレッド数-1
	beq	dosSProcessEnd		;processが設定されていない
;<d0.l:$FFFF0000+processのスレッド数-1
	move.w	(a6)+,d1		;スレッド番号
	beq	dosSProcessEnd		;メインスレッドは指定できない
	cmp.w	d0,d1
	bhi	dosSProcessEnd		;スレッド番号が大きすぎる
;<d1.w:スレッド番号
	movea.l	$1C50.w,a3
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:メインスレッドのメモリ空間の先頭
;<a5.l:メインスレッドのメモリ空間の末尾+1
	moveq.l	#tSize,d2
	mulu.w	d1,d2
	adda.l	d2,a3
;<a3.l:スレッド管理テーブル
	tst.l	(tProcess,a3)
	beq	dosSProcessEnd		;未使用のスレッド
	movem.l	(a6)+,d2-d4
;<d2.l:サブスレッドのメモリ空間の先頭
;<d3.l:サブスレッドのメモリ空間のサイズ
;<d4.l:先頭のブロックのサイズ
	move.l	#LOGICAL_SIZE-1,d0	;オーバーフローしないようにする
	cmp.l	d0,d3
	bls	@f
	move.l	d0,d3
@@:	cmp.l	d0,d4
	bls	@f
	move.l	d0,d4
@@:
	moveq.l	#$0000000F,d0
	add.l	d0,d3
	moveq.l	#$FFFFFFF0,d0
	and.w	d0,d3			;サイズを16の倍数に切り上げる
;ブロックを検索する
	bsr	searchBlock
	bpl	dosSProcessContinuous	;連続メモリ型サブスレッド
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2
	bsr	searchBlock
	bmi	dosSProcessParamError	;パラメータが無効

;サブメモリ型サブスレッド
;	サブスレッドのメモリ空間の先頭のブロックのヘッダを作る
;<d3.l:サブスレッドのメモリ空間のサイズ
;<d4.l:先頭のブロックのサイズ
;<a2.l:親ブロックのヘッダ
;<a3.l:スレッド管理テーブル
	lea.l	(User,a2),a4		;サブスレッドのメモリ空間の先頭
	lea.l	(a4,d3.l),a5		;サブスレッドのメモリ空間の末尾+1
;<a4.l:サブスレッドのメモリ空間の先頭
;<a5.l:サブスレッドのメモリ空間の末尾+1
	cmpa.l	(Tail,a2),a5
	bhi	dosSProcessParamError	;親ブロックが小さすぎる
	lea.l	(User,a4,d4.l),a1	;先頭のブロックの末尾+1
;<a1.l:先頭のブロックの末尾+1
	cmpa.l	a5,a1
	bhi	dosSProcessParamError	;先頭のブロックが大きすぎる
	movea.l	a4,a0			;先頭のブロックのヘッダを設定
	clr.l	(a0)+			;直前
	clr.l	(a0)+			;プロセス
	move.l	a1,(a0)+		;末尾+1
	clr.l	(a0)			;直後
	bra	dosSProcessSetEnd

;連続メモリ型サブスレッド
;	サブスレッドのメモリ空間の直後にダミーのヘッダを作る
;<d3.l:サブスレッドのメモリ空間のサイズ
;<d4.l:先頭のブロックのサイズ
;<a2.l:先頭のブロックのヘッダ
;<a3.l:スレッド管理テーブル
dosSProcessContinuous:
	movea.l	a2,a4			;サブスレッドのメモリ空間の先頭
	lea.l	(a4,d3.l),a5		;サブスレッドのメモリ空間の末尾+1,ダミーのヘッダ
;<a4.l:サブスレッドのメモリ空間の先頭
;<a5.l:サブスレッドのメモリ空間の末尾+1
	lea.l	(User,a5),a0		;ダミーのヘッダの末尾+1
	cmpa.l	(Tail,a2),a0
	bhi	dosSProcessParamError	;先頭のブロックの現在のサイズが小さすぎる
	lea.l	(User,a4,d4.l),a1	;先頭のブロックの末尾+1
;<a1.l:先頭のブロックの末尾+1
	cmpa.l	a5,a1
	bhi	dosSProcessParamError	;先頭のブロックが大きすぎる
	movea.l	a5,a0			;ダミーのブロックのヘッダを設定
	move.l	a4,(a0)+		;直前
	clr.l	(a0)+			;プロセス
	move.l	(Tail,a4),(a0)+		;末尾+1
	move.l	(Next,a4),(a0)		;直後
					;先頭のブロックのヘッダを設定
	move.l	a5,(Tail,a4)		;末尾+1
	move.l	a5,(Next,a5)		;直後

;<d3.l:サブスレッドのメモリ空間のサイズ
;<d4.l:先頭のブロックのサイズ
;<a2.l:先頭のブロックのヘッダ
;<a3.l:スレッド管理テーブル
;<a4.l:サブスレッドのメモリ空間の先頭
;<a5.l:サブスレッドのメモリ空間の末尾+1
dosSProcessSetEnd:
	or.b	#$C0,(Proc,a2)		;親または先頭のブロックにフラグをセット
	move.l	a4,(tMemStart,a3)	;サブスレッドのメモリ空間を設定
	move.l	a5,(tMemEnd,a3)

dosSProcessEnd:
  debug '|s_process out (ptr or max-id)=',1,d0
	rts

dosSProcessParamError:
	moveq.l	#$FFFFFFF2,d0		;パラメータが無効
  debug '|s_process out; illegal parameter',0
	rts

;----------------------------------------------------------------
;_OPEN_PR追加処理
;	スレッドが作成された直後に呼ばれる
;	排他制御情報を作成する
;<d0.w:作成されたスレッド番号
dosOpenPr::
	movem.l	d0-d2/a0-a2,-(sp)
	move.w	d0,d1
	beq	dosOpenPrEnd		;念のため
	tst.l	(xTable,d1.w*4)
	bpl	dosOpenPrEnd		;念のため
	subq.w	#1,d0			;メインスレッドの分を引く
	mulu.w	#xSize2,d0
	lea.l	([exclusiveStart],d0.l),a2	;排他制御情報の先頭
	move.l	a2,(xTable,d1.w*4)
;<a2.l:新しいスレッドの排他制御情報のアドレス

;FPUの状態を作成する
	movea.l	a2,a0
	moveq.l	#120/4-1,d2
@@:	clr.l	(a0)+			;すべてクリア
	dbra	d2,@b
	move.w	#$6000,(xFsave+2,a2)	;NULL
;標準ハンドラを作成する
	moveq.l	#0,d2
1:	move.w	d2,d0
	bsr	callDup			;現在の標準ハンドラを複製する
	bpl	2f
	moveq.l	#-1,d0			;排他制御情報の標準ハンドラが-1のときは,
					;メインスレッドの排他制御情報を使う
2:	move.w	d0,(xStdin,a2,d2.w*2)
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;標準ハンドラ変換テーブルを作成する
	movea.l	stdHdlDup0,a0		;現在の標準ハンドラ変換テーブル
	lea.l	(xDup0Table,a2),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;ドライブ管理テーブルのアドレスを設定し,テーブルの本体を作成する
	lea.l	(xDriveTable,a2),a1	;ドライブ管理テーブルの先頭
	move.l	a1,(xDriveTablePtr,a2)	;ドライブ管理テーブルのアドレス
	movea.l	$1C38.w,a0		;現在のドライブ管理テーブル
	moveq.l	#1,d0
	add.b	$1C74.w,d0		;ドライブ管理テーブルの個数
	mulu.w	#dSize,d0		;ドライブ管理テーブルのサイズ
	lsr.w	#1,d0
	subq.w	#1,d0
@@:	move.w	(a0)+,(a1)+		;現在のドライブ管理テーブルをコピーする
	dbra	d0,@b
;カレントドライブを作成する
	move.b	$1C15.w,(xCurrentDrive,a2)	;現在のカレントドライブ
;breakのモードを作成する
	move.b	#2,(xBreakMode,a2)	;常にkill
dosOpenPrEnd:
	movem.l	(sp)+,d0-d2/a0-a2
	rts

;----------------------------------------------------------------
;_KILL_PR追加処理
;	スレッドが削除された直後に呼ばれる
;	排他制御情報を破棄する
;<d0.w:削除されたスレッド番号-1
dosKillPr::
	addq.w	#1,d0
;<d0.w:スレッド番号
	bsr	killExclusive		;排他制御情報を破棄する
	subq.w	#1,d0
	rts

;----------------------------------------------------------------
;_CHANGE_PR追加処理
;	スレッドが切り替わった直後に呼ばれる
;	排他制御情報を切り替える
;<d0.w:次のスレッド番号
dosChangePr::
	movem.l	d0-d2/a0-a3,-(sp)
;排他制御情報の保存
	move.w	currentThreadId,d1	;現在のスレッド
	cmp.w	d1,d0			;念のため
	beq	dosChangePrEnd
	move.w	d0,currentThreadId	;次のスレッド
	move.l	(xTable,d1.w*4),d0	;現在の排他制御情報の先頭
	bmi	dosChangePrLoad		;念のため
	movea.l	d0,a2
;<a2.l:現在の排他制御情報の先頭

;FPUの状態を保存する
	fsave		(xFsave,a2)
	fmovem.l	fpcr/fpsr/fpiar,(xFpcr,a2)
	fmovem.x	fp0-fp7,(xFp0,a2)
;標準ハンドラを保存する
	moveq.l	#0,d2
1:	move.w	(xStdin,a2,d2.w*2),d0
	bmi	2f
	move.w	d2,d1
	bsr	dup2
2:	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;標準ハンドラ変換テーブルを保存する
	movea.l	stdHdlDup0,a0		;標準ハンドラ変換テーブル
	lea.l	(xDup0Table,a2),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;ドライブ管理テーブルのアドレスを保存する(念のため)
	move.l	$1C38.w,(xDriveTablePtr,a2)
;カレントドライブを保存する
	move.b	$1C15.w,(xCurrentDrive,a2)
;breakのモードを保存する
	move.b	$1C12.w,(xBreakMode,a2)

;排他制御情報の再生
dosChangePrLoad:
	move.w	currentThreadId,d0	;次のスレッド番号
	beq	dosChangePrMain
	move.l	(xTable,d0.w*4),d0	;次のスレッドの排他制御情報
	bmi	dosChangePrMain		;次のスレッドの排他制御情報がなければ,
					;メインスレッドの排他制御情報を使う
	movea.l	d0,a2
	lea.l	mainExclusive,a3	;メインスレッドの排他制御情報
;<a2.l:次のスレッドの排他制御情報のアドレス
;<a3.l:メインスレッドの排他制御情報のアドレス

;FPUの状態を再生する
	fmovem.x	(xFp0,a2),fp0-fp7
	fmovem.l	(xFpcr,a2),fpcr/fpsr/fpiar
	frestore	(xFsave,a2)
;標準ハンドラを再生する
	moveq.l	#0,d2
1:	move.w	d2,d0
	move.w	(xStdin,a2,d2.w*2),d1
	bpl	2f
	move.w	(xStdin,a3,d2.w*2),d1
2:	bsr	dup2
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;標準ハンドラ変換テーブルを再生する
	lea.l	(xDup0Table,a2),a0
	movea.l	stdHdlDup0,a1		;標準ハンドラ変換テーブル
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;ドライブ管理テーブルを再生する
	move.l	(xDriveTablePtr,a2),$1C38.w
;カレントドライブを再生する
	move.b	(xCurrentDrive,a2),$1C15.w
;breakのモードを再生する
	move.b	#2,$1C12.w		;ここはサブスレッドのみなので常にkill
;
dosChangePrEnd:
	movem.l	(sp)+,d0-d2/a0-a3
	rts

;メインスレッドの排他制御情報を再生する
dosChangePrMain:
	bsr	loadMainExclusive
	bra	dosChangePrEnd

;----------------------------------------------------------------
;排他制御情報を破棄する
;	破棄した後、一旦メインスレッドの排他制御情報を再生する
;<d0.w:スレッド番号
killExclusive:
	movem.l	d0-d2/a2,-(sp)
	move.w	d0,d1
	beq	killExclusiveEnd	;メインスレッドの排他制御情報は破棄できない
	move.l	(xTable,d1.w*4),d0
	bmi	killExclusiveEnd	;排他制御情報が存在しない
	move.l	#-1,(xTable,d1.w*4)	;排他制御情報を破棄する
	movea.l	d0,a2			;排他制御情報の先頭
;<a2.l:排他制御情報のアドレス

;標準ハンドラを破棄する
	moveq.l	#0,d2
1:	move.w	(xStdin,a2,d2.w*2),d0
	bmi	2f
	bsr	callClose
2:	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b

;メインスレッドの排他制御情報を再生する
	bsr	loadMainExclusive
;
killExclusiveEnd:
	movem.l	(sp)+,d0-d2/a2
	rts

;----------------------------------------------------------------
;メインスレッドの排他制御情報を再生する
loadMainExclusive:
	movem.l	d0/d2/a0-a2,-(sp)
	clr.w	currentThreadId		;メインスレッドの排他制御情報に移行

	lea.l	mainExclusive,a2
;<a2.l:メインスレッドの排他制御情報のアドレス

;FPUの状態を再生する
	fmovem.x	(xFp0,a2),fp0-fp7
	fmovem.l	(xFpcr,a2),fpcr/fpsr/fpiar
	frestore	(xFsave,a2)
;標準ハンドラを再生する
	moveq.l	#0,d2
1:	move.w	d2,d0
	move.w	(xStdin,a2,d2.w*2),d1	;メインスレッドなので負数は有り得ない
	bsr	dup2
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;標準ハンドラ変換テーブルを再生する
	lea.l	(xDup0Table,a2),a0
	movea.l	stdHdlDup0,a1		;標準ハンドラ変換テーブル
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;ドライブ管理テーブルを再生する
	move.l	(xDriveTablePtr,a2),$1C38.w
;カレントドライブを再生する
	move.b	(xCurrentDrive,a2),$1C15.w
;breakのモードを再生する
	move.b	(xBreakMode,a2),$1C12.w	;メインスレッドなのでbreakのモードを復元する
;
	movem.l	(sp)+,d0/d2/a0-a2
	rts

;----------------------------------------------------------------
;ハンドラクローズ
;	_CLOSEを呼び出す
;	ハンドラはHumanのプロセス管理テーブルでクローズする
;<d0.w:ハンドラ番号
;?d0
callClose:
	movem.l	d1-d7/a0-a6,-(sp)
	move.w	d0,-(sp)
	movea.l	sp,a6
	movea.l	$1C28.w,a0
	move.l	(a0),-(sp)
	move.l	$1C20.w,(a0)		;Humanのメモリ管理テーブル
	jsr	([$1800+(_CLOSE-$FF00)*4.w])
	move.l	(sp)+,([$1C28.w])
	addq.l	#2,sp
	movem.l	(sp)+,d1-d7/a0-a6
	rts

;----------------------------------------------------------------
;ハンドラ複製
;	_DUPを呼び出す
;	新しいハンドラはHumanのプロセス管理テーブルでオープンする
;<d0.w:ハンドラ番号
;?d0
callDup:
	movem.l	d1-d7/a0-a6,-(sp)
	move.w	d0,-(sp)
	movea.l	sp,a6
	movea.l	$1C28.w,a0
	move.l	(a0),-(sp)
	move.l	$1C20.w,(a0)		;Humanのメモリ管理テーブル
	jsr	([$1800+(_DUP-$FF00)*4.w])
	move.l	(sp)+,([$1C28.w])
	addq.l	#2,sp
	movem.l	(sp)+,d1-d7/a0-a6
	tst.l	d0
	rts

;----------------------------------------------------------------
;強制ハンドラコピー
;	_DUP2のエラーチェックをすべて省いたもの
;<d0.w:コピー先のハンドラ番号(オープンされていること)
;<d1.w:コピー元のハンドラ番号(オープンされていること)
;?d0-d1/a0-a1
dup2:
	bsr	getfcb
	subq.b	#1,(a0)
	move.w	d1,d0
	move.l	a1,d1
	bsr	getfcb
	addq.b	#1,(a0)
	movea.l	d1,a0
	move.w	(a1),(a0)
	rts

;----------------------------------------------------------------
;ハンドラ番号からFCBテーブルのアドレスを求める
;	_GETFCBのエラーチェックをすべて省いたもの
;<d0.w:ハンドラ番号
;>a0.l:FCBテーブル
;>a1.l:ハンドラFCB変換テーブル上のアドレス
;*a0-a1,?d0
getfcb:
	movea.l	stdHdlToFcb,a1		;ハンドラ番号=0～5のハンドラFCB変換テーブル
	cmp.w	#6,d0
	bcs	@f
	subq.w	#6,d0
	movea.l	$1C2C.w,a1		;ハンドラFCB変換テーブルの先頭(1個2バイト)
@@:	add.w	d0,d0
	adda.w	d0,a1
	move.w	(a1),d0
	ext.w	d0
	movea.l	stdFcbTable,a0		;FCB番号=0～5のFCBテーブル
	cmp.w	#6,d0
	bcs	@f
	subq.w	#6,d0
	movea.l	$1C30.w,a0		;FCBテーブルの先頭(1個96バイト)
@@:	mulu.w	#96,d0
	adda.w	d0,a0
	rts

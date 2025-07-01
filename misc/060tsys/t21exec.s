;----------------------------------------------------------------
;
;	_EXIT,_KEEPPR,_EXEC,_EXIT2
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;_EXIT		プロセスの終了(終了コード指定なし)
;復帰しない
	.text
	.align	4,$2048
dosExit::
	moveq.l	#0,d0
	bra	dosExitGo

;----------------------------------------------------------------
;_EXIT2		プロセスの終了(終了コード指定あり)
;<(a6).w:終了コード
;復帰しない
	.text
	.align	4,$2048
dosExit2::
	moveq.l	#0,d0
	move.w	(a6),d0
dosExitGo:
	move.l	d0,$1CAE.w
	jsr	$0000A65A.l		;_ALLCLOSE
	movea.l	([$1C28.w]),a0
	jsr	$000092B8.l		;プロセスが使っていたメモリブロックを,
					;すべて開放して親プロセスに戻る
	movea.l	(pSsp,a0),sp		;ssp
	movea.l	(pUsp,a0),a5		;usp
	move.l	a5,usp
	clr.w	-(sp)
	move.l	(pExitvc,a0),-(sp)	;_EXITVC
	move.w	(p_Sr,a0),-(sp)		;sr
	movea.l	([$1C28.w]),a0		;親プロセス
	clr.l	(pChildPtr,a0)		;子プロセスのメモリ管理テーブル
	jsr	$0000A11E.l		;プロセス管理の移行にともなうベクタ類の設定(常駐プロセス以外)
	jsr	$00010134.l		;かな漢字変換行クローズ
	move.l	$1CAE.w,d0		;_EXIT,_KEEPPR,_EXIT2の終了コード(上位ワードは非常駐=0,常駐=1)
	clr.w	$1C08.w			;DOSコールのレベル
	rte

;----------------------------------------------------------------
;_KEEPPR	プロセスの常駐終了(メモリは開放しない)
;<(a6).l:常駐サイズ(プログラムの先頭から常駐部分の末尾まで)
;<4(a6).w:終了コード
;復帰しない
	.text
	.align	4,$2048
dosKeeppr::
	move.l	(a6)+,d1		;常駐部分の長さ
	moveq.l	#1,d0
	swap.w	d0
	move.w	(a6),d0			;終了コード
	move.l	d0,$1CAE.w		;_EXIT,_KEEPPR,_EXIT2の終了コード(上位ワードは非常駐=0,常駐=1)
	movea.l	([$1C28.w]),a0		;実行中のプロセスのメモリ管理テーブル
	move.l	(Proc,a0),([$1C28.w])	;実行中のプロセスのメモリ管理テーブル
;親のアドレスの最上位バイトに常駐フラグ$FFを書き込む
;親がハイメモリにあるとアドレスが破壊される
;親はいつまでも健在とは限らないのでそもそも辿ってよい情報ではないが
;念のため始祖であるHuman68kのメモリ管理テーブルのアドレスを入れておく
	tst.b	(Proc,a0)
	beq	@f
	move.l	$1C20.w,(Proc,a0)	;Humanのメモリ管理テーブル
@@:	st.b	(Proc,a0)		;常駐フラグを設定
	add.l	a0,d1
	add.l	#$00000100,d1		;常駐部分の末尾+1
	cmp.l	(Tail,a0),d1
	bcc	@f
	move.l	d1,(Tail,a0)
@@:	movea.l	(pSsp,a0),sp		;ssp
	movea.l	(pUsp,a0),a5		;usp
	move.l	a5,usp
	clr.w	-(sp)
	move.l	(pExitvc,a0),-(sp)	;_EXITVC
	move.w	(p_Sr,a0),-(sp)		;sr
	movea.l	([$1C28.w]),a0		;親プロセス
	clr.l	(pChildPtr,a0)		;子プロセスのメモリ管理テーブル
	jsr	$0000A150.l		;プロセス管理の移行にともなうベクタ類の設定(常駐プロセス)
	jsr	$00010134.l		;かな漢字変換行クローズ
	move.l	$1CAE.w,d0		;_EXIT,_KEEPPR,_EXIT2の終了コード(上位ワードは非常駐=0,常駐=1)
	clr.w	$1C08.w			;DOSコールのレベル
	rte

;----------------------------------------------------------------
;_EXEC		子プロセスの実行
;<(a6).b:モジュール番号
;<1(a6).b:モード
;	0	プログラムのロードおよび実行
;			<2(a6).l:実行ファイル名
;				最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;			<6(a6).l:コマンドライン
;			<10(a6).l:環境のアドレス(0ならば実行中のプロセスの環境)
;			>d0.l:終了コード(常駐したとき上位ワード=1)
;	1	プログラムのロード
;			<2(a6).l:実行ファイル名
;				最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;			<6(a6).l:コマンドライン
;			<10(a6).l:環境のアドレス(0ならば実行中のプロセスの環境)
;			>d0.l:実行開始アドレス
;			>a0.l:メモリ管理テーブル
;			>a1.l:プログラムの末尾+1
;			>a2.l:コマンドライン
;			>a3.l:環境
;			>a4.l:実行開始アドレス
;	2	実行ファイル名のpath検索
;			<2(a6).l:実行ファイル名とコマンドライン
;				最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;			<6(a6).l:コマンドラインのバッファ
;			<10(a6).l:環境のアドレス(0ならば実行中のプロセスの環境)
;			>d0.l:エラーコード
;	3	実行ファイルのアドレス指定ロード
;			<2(a6).l:実行ファイル名
;				最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;			<6(a6).l:ロードアドレス
;			<10(a6).l:リミットアドレス
;			>d0.l:text+data+bss+comm+stackのサイズ
;	4	ロード済みのプログラムの実行
;			<2(a6).l:実行開始アドレス
;			>d0.l:終了コード(常駐したとき上位ワード=1)
;	5	モジュール番号の検索(最後に見つかったモジュール番号を返す)
;			<2(a6).l:実行ファイル名
;			<6(a6).l:モジュール名
;			>d0.l:モジュール番号*$100
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec::
  debug '|exec in (module*256+mode,file,param,env)=',4,(-2,a6),(2,a6),(6,a6),(10,a6)

	move.b	(1,a6),d0
	beq	dosExec0
	subq.b	#1,d0
	beq	dosExec1
	subq.b	#2-1,d0
	beq	dosExec2
	subq.b	#3-2,d0
	beq	dosExec3
dosExecGo::
	move.l	vectorOldDosExec,-(sp)
	rts

;----------------------------------------------------------------
;元の_EXECを呼ぶ
	.text
	.align	4,$2048
callExec::
	move.l	a6,-(sp)
	lea.l	(8,sp),a6
	bsr	dosExecGo
	movea.l	(sp)+,a6
	movea.l	$1C5C.w,a5
	movem.l	(dosA0,a5),a0-a4
	rts

;----------------------------------------------------------------
;_EXECモード0	プログラムのロードおよび実行
;	必要ならばスワップアウトを行う
;	プログラムをロードしてLZX展開を行う
;	ダイナミックパッチをあてる
;<(a6).b:モジュール番号
;<1(a6).b:0
;<2(a6).l:実行ファイル名
;	最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;<6(a6).l:コマンドライン
;<10(a6).l:環境のアドレス(0ならば実行中のプロセスの環境)
;>d0.l:終了コード(常駐したとき上位ワード=1)
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec0::
  debug '|exec0 in (file,param,env)=',3,(2,a6),(6,a6),(10,a6)
;ロード
	move.l	(10,a6),-(sp)
	move.l	(6,a6),-(sp)
	move.l	(2,a6),-(sp)
	move.w	#1,-(sp)
	move.b	(a6),(sp)
	bsr	callExec
	lea	(14,sp),sp
	tst.l	d0
	bmi	dosExec0End
;LZX展開
	move.l	(Tail,a0),d6		;リミットアドレス
	lea.l	(pProgram,a0),a5	;ロードアドレス
	move.l	(pBssTop,a0),d5
	movea.l	(pStackTop,a0),a1
	bsr	unpackLzx
	move.l	d5,(pBssTop,a0)		;bssの先頭
	move.l	d5,(pHeapTop,a0)	;ヒープの先頭
	move.l	a1,(pStackTop,a0)	;スタックエリアの先頭
	movea.l	$1C5C.w,a5
	movem.l	a0-a4,(dosA0,a5)
;パッチをあてる
	bsr	dynamicPatch
;キャッシュフラッシュ
	bsr	cache_flush
;_EXECモード4で実行する
	move.l	a4,-(sp)
	move.w	#4,-(sp)
	bsr	callExec
	addq.l	#6,sp
dosExec0End:
	rts

;----------------------------------------------------------------
;_EXECモード1	プログラムのロード
;	プログラムをロードしてLZX展開を行う
;	ダイナミックパッチをあてる
;<(a6).b:モジュール番号
;<1(a6).b:1
;<2(a6).l:実行ファイル名
;	最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;<6(a6).l:コマンドライン
;<10(a6).l:環境のアドレス(0ならば実行中のプロセスの環境)
;>d0.l:実行開始アドレス
;>a0.l:メモリ管理テーブル
;>a1.l:プログラムの末尾+1
;>a2.l:コマンドライン
;>a3.l:環境
;>a4.l:実行開始アドレス
;*d0/a0-a4,?d1-d7/a5-a6
	.text
	.align	4,$2048
dosExec1::
  debug '|exec1 in (file,param,env)=',3,(2,a6),(6,a6),(10,a6)
;ロード
	move.l	(10,a6),-(sp)
	move.l	(6,a6),-(sp)
	move.l	(2,a6),-(sp)
	move.w	#1,-(sp)
	move.b	(a6),(sp)
	bsr	callExec
	lea	(14,sp),sp
	tst.l	d0
	bmi	dosExec1End
;LZX展開
	move.l	(Tail,a0),d6		;リミットアドレス
	lea.l	(pProgram,a0),a5	;ロードアドレス
	move.l	(pBssTop,a0),d5
	movea.l	(pStackTop,a0),a1
	bsr	unpackLzx
	move.l	d5,(pBssTop,a0)
	move.l	d5,(pHeapTop,a0)
	move.l	a1,(pStackTop,a0)
	movea.l	$1C5C.w,a5
	movem.l	a0-a4,(dosA0,a5)
;パッチをあてる
	bsr	dynamicPatch
;キャッシュフラッシュ
	bsr	cache_flush
	move.l	a4,d0			;実行開始アドレス
dosExec1End:
  debug '|exec1 out (d0,a0,a1,a2,a3,a4)=',6,d0,a0,a1,a2,a3,a4
	rts

;----------------------------------------------------------------
;_EXECモード2	実行ファイル名のpath検索
;<1(a6).b:2
;<2(a6).l:実行ファイル名とコマンドライン
;	最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;<6(a6).l:コマンドラインのバッファ
;<10(a6).l:環境のアドレス(0ならば実行中のプロセスの環境)
;>d0.l:エラーコード
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec2::
;hupair対応
	bra	dosExecGo

;----------------------------------------------------------------
;_EXECモード3	実行ファイルのアドレス指定ロード
;	プログラムをロードしてLZX展開を行う
;<(a6).b:モジュール番号
;<1(a6).b:3
;<2(a6).l:実行ファイル名
;	最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;<6(a6).l:ロードアドレス
;<10(a6).l:リミットアドレス
;>d0.l:サイズ
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec3::
  debug '|exec3 in (file,ptr,limit)=',3,(2,a6),(6,a6),(10,a6)
;ロード
	move.l	(10,a6),-(sp)
	move.l	(6,a6),-(sp)
	move.l	(2,a6),-(sp)
	move.w	#3,-(sp)
	move.b	(a6),(sp)
	bsr	callExec
	lea	(14,sp),sp
	tst.l	d0
	bmi	dosExec3End
;LZX展開
	move.l	(10,a6),d6		;リミットアドレス
	movea.l	(6,a6),a5		;ロードアドレス
	lea.l	(a5,d0.l),a1		;末尾+1
	bsr	unpackLzx
	move.l	a1,d7			;末尾+1
	sub.l	a5,d7			;プログラムのサイズ
;パッチをあてる
;<a5.l:ロードアドレス
;<d7.l:プログラムのサイズ
	bsr	dynamicDevicePatch
;キャッシュフラッシュ
	bsr	cache_flush
	move.l	d7,d0			;プログラムのサイズ
dosExec3End:
  debug '|exec3 out (size)=',1,d0
	rts

;----------------------------------------------------------------
;LZX展開
;<d6.l:リミットアドレス
;<a0.l:メモリ管理テーブル
;<a1.l:末尾+1
;<a5.l:ロードアドレス
;>d5.l:(展開したとき)bssの先頭
;>a1.l:末尾+1
;>a4.l:(展開したとき)実行開始アドレス
;*d5/a1/a4,?d0-d2
	.text
	.align	4,$2048
unpackLzx::
;#HUPAIR LZX 0.42のチェック
	moveq.l	#0,d1
	moveq.l	#2,d2
	cmpi.l	#'#HUP',(2,a5)
	bne	@f
	cmpi.l	#'AIR'*$100,(6,a5)
	bne	@f
	moveq.l	#6,d1
	moveq.l	#84,d2
	cmpi.l	#'0.42',(14,a5)
	beq	@f
	moveq.l	#90,d2
	cmpi.l	#'1.04',(14,a5)
	bne	unpackLzxEnd
@@:
;LZXヘッダのチェック
	cmpi.l	#'LZX ',(4,a5,d1.w)
	bne	unpackLzxEnd
	cmpi.l	#'0.31',(8,a5,d1.w)
	bcs	unpackLzxEnd
	cmpi.l	#'1.04',(8,a5,d1.w)
	bhi	unpackLzxEnd
	cmpi.l	#'1.00',(8,a5,d1.w)
	bcc	unpackLzxGo		;ITA lzxのときはキャッシュ操作を省略
;キャッシュディセーブル
	PUSH_CACR_DISABLE_BC	d0
	bsr	unpackLzxGo		;展開する
;キャッシュモード復元
	POP_CACR	d0
unpackLzxEnd:
	rts

;展開する
unpackLzxGo:
	move.l	d6,(4,a5,d1.w)		;リミットアドレス
	move.l	a5,(8,a5,d1.w)		;ロードアドレス
	move.l	(14,a5,d1.w),-(sp)	;実行開始位置のオフセット
	move.l	(18,a5,d1.w),d5		;text+data+bssのサイズ
	sub.l	(26,a5,d1.w),d5		;bssのサイズ
	lea.l	(@f,pc),a4		;戻り先
	jmp	(a5,d2.w)		;展開
@@:	add.l	a5,d5			;bssの先頭
	movea.l	a5,a4			;先頭アドレス
	adda.l	(sp)+,a4		;新しい実行開始アドレス
	rts

;----------------------------------------------------------------
;_PSPSETの追加
;<d3.l:text+dataのサイズ
;<d6.l:スタックエリアのサイズ
;<a0.l:メモリ管理テーブル
;<a2.l:コマンドラインのアドレス
;<a3.l:環境の領域のアドレス
;>d0.l:0
;>a3.l:環境の領域のアドレス(0だったとき親プロセスの環境の領域アドレスが入る)
;>a5.l:DOSコールにレベル0で入ったときのssp
;*d0/a3/a5,?d3/a6
	.text
	.align	4,$2048
human302_makePsp::
	add.l	a0,d3
	add.l	#pProgram,d3
	movea.l	([$1C28.w]),a5		;実行中のプロセスのメモリ管理テーブル
	move.l	a0,(pChildPtr,a5)	;子プロセスのメモリ管理テーブル
	move.l	d3,(pBssTop,a0)		;bss+comm+stackの先頭
	move.l	d3,(pHeapTop,a0)	;ヒープの先頭
	add.l	d6,d3
	move.l	d3,(pStackTop,a0)	;スタックエリアの先頭
	cmpa.w	#0,a3
	bne	@f
	movea.l	(pEnvPtr,a5),a3		;現在の環境の領域のアドレス
@@:	move.l	a3,(pEnvPtr,a0)		;環境の領域のアドレス
	move.l	a2,(pCmdLinePtr,a0)	;コマンドラインのアドレス
	lea.l	(pHandler,a0),a6
	clr.l	(a6)+			;ハンドラの使用状況(12バイト)
	clr.l	(a6)+			;
	clr.l	(a6)			;
	movea.l	$1C5C.w,a5		;DOSコールにレベル0で入ったときのssp
	move.l	(dosPC,a5),$1BC0.w	;pcを_EXITVCへ
	lea.l	(dosSSP,a5),a6
	move.l	a6,(pSsp,a0)		;ssp
	move.l	usp,a6
	move.l	a6,(pUsp,a0)		;usp
	move.w	(dosSR,a5),(p_Sr,a0)	;sr
	clr.l	(pOsFlag,a0)		;OSフラグ(-1=Humanが起動,0=その他)
	clr.l	(pChildPtr,a0)		;子プロセスのメモリ管理テーブル
	jsr	$0000A0EC.l		;メモリ管理ブロックの生成にともなうベクタ類の保存
	move.l	a0,([$1C28.w])		;実行中のプロセスのメモリ管理テーブル

	cmpi.b	#_EXEC-$FF00,$1C0A.w
	bne	@f

	move.b	deviceCacheNoPush,(pDeviceNoPush,a0)	;デバイス呼び出しでキャッシュプッシュするか
	move.b	defaultAllocArea,(pAllocArea,a0)	;アロケートできる領域の条件
					;	0	下位のみ
					;	1	上位のみ
					;	2	親と同じ側のみ
					;	3	親と反対側のみ
					;	4	制限なし,下位優先
					;	5	制限なし,上位優先
					;	6	制限なし,親と同じ側優先
					;	7	制限なし,親と反対側優先
					;	8	制限なし,優先なし
	move.b	#1,(pLoadCache,a0)	;本体のブロックのキャッシュモード
	move.b	#1,(pAllocCache,a0)	;アロケートしたブロックのキャッシュモード

@@:	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;_EXECの実行前の処理
;	bss+comm+stackの初期化
;	プロセス管理テーブルの作成
;<d1.w:0=起動する,0以外=レジスタの設定のみ
;<d3.l:text+dataのサイズ
;<d6.l:スタックエリアのサイズ
;<a0.l:メモリ管理テーブル
;<a2.l:コマンドラインのアドレス
;<a3.l:環境の領域のアドレス
;<a4.l:実行開始アドレス
;$0000967E
	.text
	.align	4,$2048
human302_execMakePsp::

;bss+comm+stackを初期化する
	lea.l	(pProgram.w,a0,d3.l),a1	;bss+comm+stackの先頭アドレス
	move.l	d6,d0
	lsr.l	#2,d0
	beq	2f
1:	clr.l	(a1)+
	subq.l	#1,d0
	bne	1b
2:	moveq.l	#3,d0
	and.l	d6,d0
	beq	4f
3:	clr.b	(a1)+
	subq.l	#1,d0
	bne	3b
4:
;<a1.l:bss+comm+stackの末尾

	movem.l	d1/a1-a3,-(sp)

;_EXECの動作レベルを-3に設定
	move.b	#-3,$1CA0.w		;_EXECの動作レベル

;プロセス管理テーブルを作る
	bsr	human302_makePsp
;<a5.l:DOSコールにレベル0で入ったときのssp

;_EXECの動作レベルを0に設定
	clr.b	$1CA0.w			;_EXECの動作レベル

;プロセス管理テーブルにモジュール番号を設定する
	move.b	$1CA1.w,(pModuleNumber,a0)	;_EXECで起動するモジュール番号

;プロセス管理テーブルにパス名とファイル名を設定する
	lea.l	(-90,sp),sp
	movea.l	sp,a2
	move.l	a2,-(sp)
	move.l	$1CB2.w,-(sp)		;_EXECで起動するファイル名
	DOS	_NAMESTS
	addq.l	#8,sp
	lea.l	(pPath,a0),a1
	lea.l	(nDrive,a2),a3		;ドライブ番号
					;_NAMESTSを使っているので,内部ドライブ番号ではない
	moveq.l	#'A',d0
	add.b	(a3)+,d0		;ドライブ名
	move.b	d0,(a1)+
	move.b	#':',(a1)+
;	lea.l	(nPath,a2),a3		;パス
@@:	move.b	(a3)+,(a1)+
	bne	@b
	lea.l	(pName,a0),a1
	lea.l	(nName1,a2),a3		;ファイル名1(残りは$20)
	moveq.l	#8-1,d0
1:	cmpi.b	#' ',(a3)
	beq	3f
	move.b	(a3)+,(a1)+
	dbra	d0,1b
	lea.l	(nName2,a2),a3		;ファイル名2(残りは$00)
	moveq.l	#10-1,d0
2:	tst.b	(a3)
	beq	3f
	move.b	(a3)+,(a1)+
	dbra	d0,2b
3:	lea.l	(nExt,a2),a3		;拡張子(残りは$20)
	cmpi.b	#' ',(a3)		;Humanは拡張子がなくても'.'を付ける
	beq	5f
	move.b	#'.',(a1)+
	moveq.l	#3-1,d0
4:	cmpi.b	#' ',(a3)
	beq	5f
	move.b	(a3)+,(a1)+
	dbra	d0,4b
5:	clr.b	(a1)
	lea.l	(90,sp),sp

;プロセス管理テーブルの拡張情報を設定する
	lea.l	(pName,a0),a1
	move.l	(a1)+,d0
	or.l	#$20202020,d0
	cmp.l	#'comm',d0
	bne	@f
	move.l	(a1)+,d0
	or.l	#$20202000,d0
	cmp.l	#'and.',d0
	bne	@f
	move.w	(a1)+,d0
	or.w	#$2000,d0
	cmp.w	#'x'*256,d0
	bne	@f
	move.b	#8,(pAllocArea,a0)	;command.xは制限なし,優先なし
@@:

	movem.l	(sp)+,d1/a1-a3

;<d1.w:0=起動する,0以外=レジスタの設定のみ
;<a0.l:メモリ管理テーブル
;<a1.l:bss+comm+stackの末尾
;<a2.l:コマンドラインのアドレス
;<a3.l:環境の領域のアドレス
;<a4.l:実行開始アドレス
;<a5.l:DOSコールにレベル0で入ったときのssp

	jmp	$0000971E

;----------------------------------------------------------------
;ダイナミックパッチをあてる(デバイスドライバ)
;<a5.l:ロードアドレス
;<d7.l:プログラムのサイズ
dynamicDevicePatch:
  .ifdef __DEBUG__
	movem.l	d1/a1,-(sp)
	moveq.l	#'[',d1
	jsr	debugPutc
	movea.l	$1CB2.w,a1
	jsr	debugPrint
	moveq.l	#']',d1
	jsr	debugPutc
	movem.l	(sp)+,d1/a1
  .endif
	bsr	rsdrv202
	rts

rsdrv202:
	movem.l	d0/a0-a1,-(sp)
	cmp.l	#$00000EA6,d7
	blo	9f
	lea.l	($00000E4C,a5),a0
	lea.l	(1f,pc),a1
	bsr	strcmp
	bne	9f

	lea.l	(2f,pc),a1
	move.w	(a1)+,d0
	lea.l	($00000D04,a5),a0
@@:	move.w	(a1)+,(a0)+
	dbra	d0,@b

9:	movem.l	(sp)+,d0/a0-a1
	rts

1:	.dc.b	$0D,$0A
	.dc.b	'RS-232C DRIVER for X68000 version 2.02',$0D,$0A
	.dc.b	'AUX0 から AUX5 のファイル名で、通信が可能です',$0D,$0A,$00
	.even

2:	.dc.w	(11f-10f)/2-1
10:	move.w	#2,-(sp)		;(a0)からワードで読めるか調べるルーチン
	pea.l	(3f,pc)			;ダミー
	move.l	a0,-(sp)
	DOS	_BUS_ERR
	lea.l	(10,sp),sp
	tst.l	d0
	beq	@f
	moveq.l	#-1,d0
@@:	rts
3:	.ds.w	1
11:

;----------------------------------------------------------------
;ダイナミックパッチをあてる
;<a0.l:メモリ管理ポインタ
;<a1.l:末尾+1
;<a4.l:実行開始アドレス
dynamicPatch:
  .ifdef __DEBUG__
	movem.l	d1/a1,-(sp)
	moveq.l	#'[',d1
	jsr	debugPutc
	movea.l	$1CB2.w,a1
	jsr	debugPrint
	moveq.l	#']',d1
	jsr	debugPutc
	movem.l	(sp)+,d1/a1
  .endif
;プログラムのサイズのチェックが必須なので注意！！！
;パッチを当てるプログラムを実行してからそれより小さいものを動かすと,
;同じアドレスにロードされてバージョンナンバーなどが残っている可能性があるため
	bsr	patchLibcAladin
	bsr	pcm8a102

	tst.b	useJointMode
	beq	@f
	bsr	patchXclib		;XCのライブラリにパッチをあてる
	bsr	history_x_110
	bsr	sxwin940507
	bsr	commandx
@@:
	rts

;libc-1.1.31 Release Aladinの_open()にデバッグパッチをあてる
patchLibcAladin:
	movem.l	d0-d1/a1-a2,-(sp)
;'Aladin',0,'1.1.31',0を探す
	move.l	(pBssTop,a0),d1		;bssの先頭
	lea.l	(pProgram,a0),a1	;プログラムの先頭
	moveq.l	#0,d0
1:	cmpa.l	d1,a1
	bcc	9f			;libc-1.1.31ではない
	lsl.l	#8,d0
	move.b	(a1)+,d0
	cmpi.l	#'Alad',d0
	bne	1b
	movea.l	a1,a2
	cmpi.l	#('in'<<16)+0*256+'1',(a2)+	;奇数アドレスの可能性がある
	bne	1b
	cmpi.l	#'.1.3',(a2)+		;奇数アドレスの可能性がある
	bne	1b
	cmpi.w	#'1'*256,(a2)+		;奇数アドレスの可能性がある
	bne	1b
;$FF44,$FFAC,$8004の並びを探す
	lea.l	(pProgram,a0),a1	;プログラムの先頭
1:	cmpa.l	d1,a1
	bcc	9f			;見つからなかった
	cmpi.w	#$FF44,(a1)+		;$FF44を探す
	bne	1b
	movea.l	a1,a2
	moveq.l	#64-1,d0		;64ワード以内に$FFACと$8004があるか
@@:	cmpi.w	#$FFAC,(a2)+		;$FFACを探す
	dbeq	d0,@b
	bne	1b
@@:	cmpi.w	#$8004,(a2)+		;$8004を探す
	dbeq	d0,@b
	bne	1b
;見つかった
	move.w	#$8000,-(a2)		;$8004を$8000に変更
;
9:	movem.l	(sp)+,d0-d1/a1-a2
	rts



history_x_110:
	movem.l	a0-a2,-(sp)
	lea.l	($000056E2,a0),a1
	cmpa.l	(pBssTop,a0),a1
	bhs	9f
	lea.l	($0100,a0),a2
	lea.l	($000056AE,a2),a0
	lea.l	(1f,pc),a1
	bsr	strcmp
	bne	9f
	cmpi.l	#$00C00000,($00004BFE,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C02,a2)
@@:
	cmpi.l	#$00C00000,($00004C1E,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C22,a2)
@@:
	cmpi.l	#$00C00000,($00004C34,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C38,a2)
@@:
	cmpi.l	#$00C00000,($00004C4E,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C52,a2)
@@:
9:	movem.l	(sp)+,a0-a2
	rts

1:	.dc.b	'X68k History v1.10 Copyright 1989-93 SHARP/Hudson',$0D,$0A,$00
	.even

sxwin940507:
	movem.l	a0-a2,-(sp)
	lea.l	($00002BB2,a0),a1
	cmpa.l	(pBssTop,a0),a1
	bhs	9f
	lea.l	($0100,a0),a2
	lea.l	($00002B9E,a2),a0
	lea.l	(1f,pc),a1
	bsr	strcmp
	bne	9f
	lea.l	($00002BA8,a2),a0
	lea.l	(2f,pc),a1
	bsr	strcmp
	bne	9f
	cmpi.l	#$00FFFFFF,($0000169E,a2)
	bne	9f
	cmpi.w	#_MALLOC,($000016A2,a2)
	bne	9f
	cmpi.l	#$00FFFFFF,($000016A8,a2)
	bne	9f
	cmpi.w	#_MALLOC,($000016BA,a2)
	bne	9f
	move.l	#LOGICAL_MASK,($0000169E,a2)
	move.w	#_MALLOC3,($000016A2,a2)
	move.l	#LOGICAL_MASK,($000016A8,a2)
	move.w	#_MALLOC3,($000016BA,a2)
@@:
9:	movem.l	(sp)+,a0-a2
	rts

1:	.dc.b	'SX_SHELL',$00
2:	.dc.b	'ver 3.10',$00
	.even


;	PCM8A.X 1.02はI/Oポートのアドレスの上位8ビットを$FFにしていて
;	ハイメモリがあるだけで動かなくなることがあるのでパッチをあてる
;<a0.l:メモリ管理ポインタ
;<a1.l:末尾+1
;<a4.l:実行開始アドレス
pcm8a102:
	movem.l	d0-d1/a0-a1,-(sp)
	lea.l	256(a0),a0		;先頭
	sub.l	a0,a1			;長さ
;長さを確認する
	cmpa.l	#$FF60,a1
	blo	99f
;タイトルを確認する
	cmpi.l	#'PCM8',$10F8(a0)
	bne	99f
	cmpi.l	#'A102',$10FC(a0)
	bne	99f
;57箇所すべて$FFであることを確認する
;XEiJが既にパッチをあてているかも知れない
	moveq.l	#0,d0
	lea.l	100f(pc),a1
	moveq.l	#57-1,d1
10:	move.w	(a1)+,d0		;ゼロ拡張
	cmpi.b	#$FF,(a0,d0.l)
	dbne	d1,10b
	bne	99f
;57箇所すべて$00に書き換える
;	moveq.l	#0,d0
	lea.l	100f(pc),a1
	moveq.l	#57-1,d1
20:	move.w	(a1)+,d0		;ゼロ拡張
	clr.b	(a0,d0.l)
	dbra	d1,20b
99:	movem.l	(sp)+,d0-d1/a0-a1
	rts

100:	.dc.w	$0138,$01F6,$0394,$11EC,$120A,$1400,$1814,$1870,$1882,$188A
	.dc.w	$1892,$18A2,$18A8,$18CA,$18D4,$18E0,$18E8,$1908,$19E4,$1AFA
	.dc.w	$1B58,$1B7C,$1BAC,$1C38,$1CCC,$21F8,$2250,$2258,$2290,$22A6
	.dc.w	$22B0,$22C0,$22C8,$22DE,$22EA,$30C8,$30DE,$30E6,$30EA,$30F6
	.dc.w	$3112,$3188,$334C,$338A,$33A2,$33C4,$33D0,$341A,$3428,$3496
	.dc.w	$34A6,$34D6,$FE0E,$FEC8,$FEEC,$FF46,$FF4E


;<a0.l:メモリ管理ポインタ
;<a1.l:末尾+1
;<a4.l:実行開始アドレス
commandx:
	movem.l	a0,-(sp)
	lea.l	256(a0),a0
	suba.l	a0,a1
	cmpa.l	#$12A0,a1
	blo	99f
	cmpi.l	#'Comm',$000C(a0)
	bne	99f
	cmpi.l	#'and2',$0010(a0)
	bne	99f
	cmpi.l	#'.03H',$0014(a0)
	bne	99f
	cmpi.w	#'u'*$100,$0018(a0)
	bne	99f
;症状　ハイメモリで実行したとき「常駐部が読み込めません」が出る
;原因　EXEC(3)に渡すファイル名の最上位バイトにx形式の$03をorしている
;対策　$03をorするを$00をorするに変更する
	cmpi.l	#$00170003,$220(a0)	;ori.b #$03,(sp)
	bne	@f
	move.l	#$00170000,$220(a0)	;ori.b #$00,(sp)
@@:
;症状　先祖がハイメモリにあると常駐部を見つけられず常駐部が無駄に増える
;原因　最上位バイトが$00でないときそれ以上遡らない
;対策　最上位バイトが$00でないときを最上位ビットが0でないときに変更する
	cmpi.l	#$4A016608,$26C(a0)	;tst.b d1;bne (*)+10
	bne	@f
	move.l	#$4A016B08,$26C(a0)	;tst.b d1;bmi (*)+10
@@:
99:	movem.l	(sp)+,a0
	rts


;----------------------------------------------------------------
1:	cmpm.b	(a1)+,(a0)+
	bne	2f
;文字列比較(大文字と小文字を区別する)
;<a0.l:比較される文字列
;<a1.l:比較する文字列
;>z-flag:eq=一致,ne=不一致
;>c-flag:hs=(a0)>=(a1),lo=(a0)<(a1)
;?a0-a1
	.text
	.align	4,$2048
strcmp::
	tst.b	(a1)
	bne	1b
	tst.b	(a0)
2:	rts

;----------------------------------------------------------------
;文字列連結
;<a0.l:連結される文字列
;<a1.l:連結する文字列
	.text
	.align	4,$2048
strcat::
	bsr	strtail
;----------------------------------------------------------------
;文字列コピー
;<a0.l:コピー先
;<a1.l:コピー元
strcpy::
@@:	move.b	(a1)+,(a0)+
	bne	@b
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;文字列の末尾までスキップ
;<a0.l:文字列
;>a0.l:文字列の末尾の0の位置
	.text
	.align	4,$2048
strtail::
@@:	tst.b	(a0)+
	bne	@b
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;文字列比較(大文字と小文字を区別しない)
;<a0.l:比較される文字列
;<a1.l:比較する文字列
;>z-flag:eq=一致,ne=不一致
;>c-flag:hs=(a0)>=(a1),lo=(a0)<(a1)
;?a0-a1
	.text
	.align	4,$2048
strcmpi::
	move.l	d1,-(sp)
	clr.b	d1
1:	tst.b	(a1)
	beq	5f
	move.b	(a0)+,d0
	tas.b	d1
	bne	3f			;2バイト目
	cmp.b	#'A',d0
	blo	3f			;1バイト目で'A'～'Z'以外
	cmp.b	#'Z',d0
	bhi	2f			;1バイト目で'A'～'Z'以外
	or.b	#$20,d0			;'A'～'Z'を小文字化する
	bra	3f

2:	tst.b	d0
	bpl	3f			;$00～$7F:1バイトコード
	cmp.b	#$A0,d0
	blo	4f			;$80～$BF:2バイトコードの1バイト目
	cmp.b	#$E0,d0
	bhs	4f			;$E0～$FF:2バイトコードの1バイト目
3:	clr.b	d1			;1バイトコード
4:	cmp.b	(a1)+,d0
	beq	1b
	bra	6f

5:	tst.b	(a0)
6:	movem.l	(sp)+,d1		;フラグ保護
	rts

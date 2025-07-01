;----------------------------------------------------------------
;
;	Human302のパッチルーチン(常駐部)
;
;----------------------------------------------------------------

	.include	t00iocs.equ
	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;Trap#10
;ROMやシステムをローカルメモリにコピーして使っているときのソフトリセット対策
	.text
	.align	4,$2048
humanTrap10::
	movem.l	d0-d1/a0,-(sp)
	PUSH_SR_DI
;ベクタテーブル復活
	tst.b	localSystemArea
	beq	2f
	movec.l	dfc,d1
	moveq.l	#FC_MMU_DATA,d0
	movec.l	d0,dfc
	suba.l	a0,a0
1:	move.l	(a0),d0			;現在のデータ
	moves.l	d0,(a0)+		;本来のアドレスに戻す
	cmpa.l	mainLowerStart,a0
	blo	1b
	movec.l	d1,dfc
2:
;キャッシュ機能停止
	moveq.l	#0,d0
	movec.l	d0,cacr
	bsr	cache_flush
;MMU機能停止
	tst.b	noTranslation
	bne	99f
;		  E  P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
;		  15 14 13 12  11   10   98  76  5   43  21
	move.l	#%0__0__0__0___0____0____10__00__0___00__00_0,d0
	movec.l	d0,tc
	pflusha
;トランスペアレント変換機能停止
;	moveq.l	#0,d0
	movec.l	d0,itt0
	movec.l	d0,itt1
	movec.l	d0,dtt0
	movec.l	d0,dtt1
99:
	POP_SR
	movem.l	(sp)+,d0-d1/a0
	jmp	([vectorOldHumanTrap10])

;----------------------------------------------------------------
;スーパーバイザ領域設定
;EXCONFIGの実行開始前とSHELLの起動前に呼ばれるルーチン
;ただし、DEVICEで組み込む限り、EXCONFIGの実行開始前には機能しない
;HUMAN.SYSにバインドした場合はEXCONFIGの実行開始前にも使用されることになる
;これは領域設定後は常駐している必要がないが、最後のデバイスドライバを登録するまで
;残っていないと困るので常駐部に置く
;変更前
;	$00006A96:
;		move.l	$1C24.w,d0		;空きエリアの先頭アドレス
;		add.l	#$00001FFF,d0
;		and.l	#$00FFE000,d0
;		move.l	d0,$0000837A		;Humanの末尾のアドレス+1
;		lsr.l	#8,d0
;		lsr.l	#5,d0
;		subq.w	#1,d0
;		cmp.w	#$0100,d0
;		bcs.s	$00006ABA
;		moveq.l	#$FF,d0
;	$00006ABA:
;		move.b	d0,$00E86001
;		rts
;$00006A96
	.text
	.align	4,$2048
human302_superarea::
	movem.l	d1-d4/a0-a1,-(sp)
	moveq.l	#0,d4
  debug '|IOCS($92-$93)=',2,$0192.w*4.w,$0193*4.w
	move.l	$1C24.w,d2		;空きエリアの先頭アドレス
	add.l	#$00001FFF,d2		;ページサイズに関わらず8KB単位に切り上げる
	and.l	#LOGICAL_MASK.and.$FFFFE000,d2
	move.l	d2,([$1C20.w],Tail)	;Humanの末尾のアドレス+1
	move.l	d2,d0
	lsr.l	#8,d0
	lsr.l	#5,d0
	subq.l	#1,d0
	cmp.w	#$00FF,d0
	bls	@f
	move.w	#$00FF,d0
@@:	move.b	d0,$00E86001		;スーパーバイザエリア設定
	suba.l	a1,a1
;指定された領域をスーパーバイザプロテクトする
;<d2.l:サイズ(ページサイズの倍数)
;<a1.l:先頭アドレス(ページの先頭)
	tst.b	noTranslation
	bne	99f
	PUSH_MMU_SFC_DFC	d0
	add.l	a1,d2
@@:	bsr	getDesc
	bset.l	#PD_S_BIT,d0
	moves.l	d0,(a0)
	pflusha
	adda.l	pageOffsetSize,a1
	cmpa.l	d2,a1
	blo	@b
	POP_SFC_DFC	d0
;
	tst.l	d4
	bne	@f
	moveq.l	#1,d4
	pea.l	(crlfMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
@@:
	pea.l	(superareaMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
99:

;ユーザモードの領域を1ページ分だけ確保する
	move.l	([$1C20.w],Tail),d0	;Humanの末尾のアドレス+1
	move.l	d0,userAreaWork
	add.l	#PAGE_OFFSET_SIZE,d0
	move.l	d0,([$1C20.w],Tail)	;Humanの末尾のアドレス+1

;拡張モード
	tst.l	([$1C20.w],Next)
	bne	1f
	move.l	mainMemorySize,d2	;メインメモリサイズの指定(MBの倍数)
	bmi	1f
	cmp.l	([$1C20.w],Tail),d2
	bhi	@f
	move.l	([$1C20.w],Tail),d2	;デバイスの末尾(ページサイズの倍数)
	move.l	d2,mainMemorySize	;デバイスの末尾よりも短くできない
@@:
;<d2.l:メインメモリのサイズ
	move.l	$1C00.w,d0
	and.l	pageMask,d0		;他のデバイスが切り詰めた可能性があるので
					;ページサイズに切り直す
	cmp.l	d0,d2
	bhi	1f			;不足のとき(未対応)
;拡張実行
	move.l	d0,$1C00.w		;他のデバイスが確保した領域から
					;ページサイズまで切り下げる

	sub.l	d2,d0
	cmp.l	#128*1024,d0		;メインメモリが128KBに満たないときは,
	bcc	@f			;ロードとアロケーションの領域を上位のみにする
	move.b	#1,defaultLoadArea
	move.b	#1,defaultAllocArea
@@:

	movea.l	himemAreaEnd,a1		;ハイメモリ領域の現在の末尾
	tst.l	himemAreaSize
	bne	5f			;ハイメモリ領域がある
	movea.l	localUpperStart,a1	;ローカルメモリの末尾かデスクリプタまたはROMの先頭
	tst.l	localMemorySize
	bne	4f			;ローカルメモリはあるがハイメモリ領域がないので
					;himemAreaStartを設定する
	movea.l	#$10000000,a1		;ローカルメモリがないとき
4:	move.l	a1,himemAreaStart	;ハイメモリ領域がないのでhimemAreaStartを設定する
5:
;<d2.l:移動元の先頭
;<a1.l:移動先の先頭
	move.l	d2,-(sp)		;移動元の先頭
					;元→先  デスクリプタ
					;d2→a1
	PUSH_MMU_SFC_DFC	d0
2:	move.l	a1,d3			;d2→d3/a1
	movea.l	d2,a1			;d2/a1→d3
;	bsr	invDesc			;移動元のデスクリプタを除去する
	move.l	userAreaWork,d2
;		  UR G U1U0 S CM M U W PDT
	or.l	#%00_1__00__0_00_0_0_0_01,d2
	bsr	setDesc			;ユーザモードのワークエリアを割り当てる
	move.l	d0,d2			;a1→d3  d2
	exg.l	d3,a1			;d3→a1  d2
	bsr	setDesc			;移動先に設定する
	pflusha
  debug '|拡張モード setDesc(a1,d2,d0)=',3,a1,d2,d0
	move.l	d3,d2			;d2→a1
	move.l	pageOffsetSize,d0
	add.l	d0,d2
	adda.l	d0,a1
	add.l	d0,himemAreaSize
	cmp.l	$1C00.w,d2		;他のデバイスが確保した領域の手前まで
	blo	2b
	POP_SFC_DFC	d0
	move.l	a1,himemAreaEnd		;ハイメモリの領域を伸ばす
	move.l	(sp)+,$1C00.w		;移動元の先頭から切り捨てる
;ハイメモリ領域の先頭のブロックを設定する
	movea.l	himemAreaStart,a0
	lea.l	(User,a0),a1
	cmpi.l	#'060t',(a1)
	beq	3f			;初期化されている
	move.l	#'060t',(a1)+
	move.l	#'urbo',(a1)+
	move.l	#'HIME',(a1)+
	move.l	#'M'<<24,(a1)+
	clr.l	(Prev,a0)
	move.l	$1C20.w,(Proc,a0)	;Humanのメモリ管理ポインタ
	move.l	a1,(Tail,a0)
	clr.l	(Next,a0)
3:
	tst.l	d4
	bne	@f
	moveq.l	#1,d4
	pea.l	(crlfMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
@@:
	pea.l	(extendedMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
1:

;結合モード
	tst.l	([$1C20.w],Next)
	bne	1f
	tst.b	useJointMode
	beq	1f
	tst.l	himemAreaSize
	beq	1f
	move.l	$1C20.w,jointBlockHeader
	movea.l	$1C00.w,a0
	cmpa.l	([$1C20.w],Tail),a0
	beq	2f			;デバイスドライバの後ろをすべて押し出したので
					;ジョイントブロックを作らない
	suba.l	jointBlockSize,a0
	lea.l	(-User,a0),a0
	move.l	a0,jointBlockHeader
	move.l	a0,([$1C20.w],Next)
	move.l	$1C20.w,(a0)+		;Prev
	move.l	$1C20.w,(a0)+		;Proc
	addq.l	#4,a0
	clr.l	(a0)+			;Next
	move.l	#'join',(a0)+
	move.l	#'tBlo',(a0)+
	move.w	#'ck',(a0)+
2:	movea.l	jointBlockHeader,a0	;ジョイントブロックまたはHumanの先頭
	move.l	himemAreaStart,d0
	move.l	d0,(Tail,a0)
	move.l	d0,$1C00.w
;結合モードにする
	tst.b	jointMode
	beq	1f
	sf.b	jointMode		;一旦クリアする
	bsr	sysStat_C001		;結合モードへ
	tst.l	d0
	bmi	1f
	tst.l	d4
	bne	@f
	moveq.l	#1,d4
	pea.l	(crlfMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
@@:
	pea.l	(jointMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
1:

;
  debug '|$1C00.w=',1,$1C00.w
  debug '|#deviceHeader=',1,#deviceHeader
  debug '|#vectorTable=',1,#vectorTable
  debug '|mainLower(Start,End)=',2,mainLowerStart,mainLowerEnd
  debug '|mainUpper(Start,End)=',2,mainUpperStart,mainUpperEnd
  debug '|localLower(Start,End)=',2,localLowerStart,localLowerEnd
  debug '|localUpper(Start,End)=',2,localUpperStart,localUpperEnd
  debug '|dosBusErr(Vbr,Ssp)=',2,dosBusErrVbr,dosBusErrSsp
  debug '|localRom(Start,End)=',2,localRomStart,localRomEnd
  debug '|localSystem(Start,End)=',2,localSystemStart,localSystemEnd
  debugKeyWait
  debug '|pageIndex(Width,Size,Mask)=',3,pageIndexWidth,pageIndexSize,pageIndexMask
  debug '|pageOffset(Width,Size,Mask)=',3,pageOffsetWidth,pageOffsetSize,pageOffsetMask
  debug '|pageMask=',1,pageMask
  debug '|pageDesc(Size,Mask)=',2,pageDescSize,pageDescMask
  debug '|descArea(Start,End,Size)=',3,descAreaStart,descAreaEnd,descAreaSize
  debug '|desc(Head,Tail)=',2,descHead,descTail
  debug '|rootDesc(Head,Tail)=',2,rootDescHead,rootDescTail
  debug '|pointerDesc(Head,Tail)=',2,pointerDescHead,pointerDescTail
  debug '|pointerCounterHead=',1,pointerCounterHead
  debug '|pageCounterTail=',1,pageCounterTail
  debugKeyWait
  debug '|tempBuffer(Start,End,Size)=',3,tempBufferStart,tempBufferEnd,tempBufferSize
  debug '|localMemory(Start,End,Size)=',3,localMemoryStart,localMemoryEnd,localMemorySize
  debug '|himemArea(Start,End,Size)=',3,himemAreaStart,himemAreaEnd,himemAreaSize
  debug '|mainMemorySize=',1,mainMemorySize
  debug '|jointBlock(Header,Size)=',2,jointBlockHeader,jointBlockSize
  debug '|jointBlockHeader(Prev,Proc,Tail,Next)=',4,([jointBlockHeader],Prev),([jointBlockHeader],Proc),([jointBlockHeader],Tail),([jointBlockHeader],Next)
  debug '|exclusive(Start,End)=',2,exclusiveStart,exclusiveEnd
  debug '|#xTable=',1,#xTable
  debug '|#mainExclusive=',1,#mainExclusive
  debug '|localRamdiskArea(Start,End,Size)=',3,localRamdiskAreaStart,localRamdiskAreaEnd,localRamdiskAreaSize
  debug '|mainRamdiskArea(Start,End,Size)=',3,mainRamdiskAreaStart,mainRamdiskAreaEnd,mainRamdiskAreaSize
  debug '|#bpbTablePointer=',1,#bpbTablePointer
  debug '|#bpbTable=',1,#bpbTable
  debugKeyWait
	movem.l	(sp)+,d1-d4/a0-a1
	rts

superareaMessage:
	.dc.b	'ＯＳをスーパーバイザ保護しました',13,10,0
extendedMessage:
	.dc.b	'拡張モードに切り替えました',13,10,0
jointMessage:
	.dc.b	'ローカルメモリを結合しました'
crlfMessage:
	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;_EXIT,_KEEPPR,_EXIT2	プロセスが使っていたメモリブロックの開放
;実行中のプロセスが使っていたメモリブロックをすべて開放する
;親プロセスに戻る
;子プロセスが確保したブロックもすべて開放する
;変更前
;	プロセスが使っていたメモリブロックをすべて開放し親プロセスに戻る
;	<a0.l:実行中のプロセスのメモリ管理ポインタ
;	$000092B8
;		movem.l	d0-d1/a0-a2,-(sp)
;		movea.l	$0000.w(a0),a1
;		move.l	a1,d0			;先頭のメモリブロックはHumanなので開放しない
;		beq.s	$000092E0
;		move.l	$000C(a0),d0
;		move.l	d0,$000C(a1)
;		beq.s	$000092D4
;		movea.l	d0,a2
;		move.l	a1,$0000.w(a2)
;	$000092D4:
;		move.l	$0004(a0),$00013D0A	;実行中のプロセスのメモリ管理テーブル
;		move.l	a0,d0
;		bsr.s	$000092E6		;プロセスが使っていたメモリブロックの開放
;	$000092E0:
;		movem.l	(sp)+,d0-d1/a0-a2
;		rts
;
;	子プロセスが使っていたメモリブロックの開放
;	<d0.l:開放する親プロセスのメモリ管理ポインタ
;	$000092E6:
;		move.l	$1C04.w,d1		;_MALLOCできるメモリ空間の先頭アドレス
;	$000092EA:
;		movea.l	d1,a0
;		move.l	$000C(a0),d1
;		beq.s	$00009310
;		cmp.l	$0004(a0),d0
;		bne.s	$000092EA
;		tst.l	$0000.w(a0)
;		beq.s	$0000932A
;		movea.l	$0000.w(a0),a1
;		move.l	d1,$000C(a1)
;		movea.l	d1,a2
;		move.l	a1,$0000.w(a2)
;		bsr.s	$0000931E
;		bra.s	$000092E6		;プロセスが使っていたメモリブロックの開放
;
;	$00009310:
;		cmp.l	$0004(a0),d0
;		bne.s	$0000932A
;		movea.l	$0000.w(a0),a1
;		move.l	d1,$000C(a1)
;	$0000931E:
;		movem.l	d0-d1,-(sp)
;		move.l	a0,d0
;		bsr.s	$000092E6		;プロセスが使っていたメモリブロックの開放
;		movem.l	(sp)+,d0-d1
;	$0000932A:
;		rts
;<a0.l:実行中のプロセスのメモリ管理ポインタ
	.text
	.align	4,$2048
human302_exitfreepat::
	movem.l	d0/d2/d4/a4-a5,-(sp)
	tst.l	(Prev,a0)
	beq	9f			;Human自身ならば何もしない
	movea.l	$1C04.w,a4		;メモリ空間の先頭
	movea.l	$1C00.w,a5		;メモリ空間の末尾+1
	move.l	a0,d4
	bsr	psfree			;実行中のプロセスが確保したブロックを開放する
					;子プロセスが確保したブロックも開放する
	move.l	(Proc,a0),([$1C28.w])
	move.l	a0,d2
	add.l	#User,d2
	bsr	free			;自分自身を開放する
9:	movem.l	(sp)+,d0/d2/d4/a4-a5
	rts

;----------------------------------------------------------------
;_EXEC	[3]実行ファイルの形式指定
;変更前
;	$00009510
;	_dos_exec_3_x:
;		bsr.w	$0000997C		;実行ファイル名の拡張子の先頭の文字を小文字化して返す
;		cmp.b	#'x',d0
;		beq.s	_dos_exec_3_x
;		cmp.b	#'r',d0
;		beq.s	_dos_exec_3_r
;		cmp.b	#'z',d0
;		beq.s	_dos_exec_3_z
;		move.l	a1,d0
;		rol.l	#8,d0
;	$0000952A
;$00009510
	.text
	.align	4,$2048
human302_exec3pat::
	bsr	human302_exec013pat
	jmp	$0000952A.l

;----------------------------------------------------------------
;_EXEC	[0][1]実行ファイルの形式指定
;変更前
;	$0000961A
;	_dos_exec_01::
;		move.l	a1,$1CB2.w		;_EXECで起動するファイル名
;		bsr.w	$0000997C		;実行ファイル名の拡張子の先頭の文字を小文字化して返す
;		cmp.b	#'x',d0
;		beq.w	_dos_exec_01_x
;		cmp.b	#'r',d0
;		beq.w	_dos_exec_01_r
;		cmp.b	#'z',d0
;		beq.s	_dos_exec_01_z
;		move.l	a1,d0
;		rol.l	#8,d0
;	$0000963C
;$0000961A
	.text
	.align	4,$2048
human302_exec01pat::
	bsr	human302_exec013pat
	move.l	a1,$1CB2.w		;_EXECで起動するファイル名
	jmp	$0000963C.l

;----------------------------------------------------------------
;_EXEC	[0][1][3]実行ファイルの形式指定
;	ファイル名のアドレスの最上位バイトで実行ファイルの形式を指定できる
;	指定よりも拡張子の方が優先する
;<a1.l:ファイル名のアドレス
;	最上位バイトは実行ファイルのタイプ(0=拡張子,1=r,2=z,3=x)
;>d0.l:実行ファイルの形式(0=不明,1=r,2=z,3=x)
;>a1.l:ファイル名のアドレス
;	最上位バイトが修正されている
	.text
	.align	4,$2048
human302_exec013pat::
;実行ファイルの形式の指定を取得し、ファイル名のアドレスの最上位バイトを修正する
	move.l	a1,-(sp)
	moveq.l	#LOGICAL_MASK>>24,d0
	and.b	(sp),d0			;ファイル名の最上位バイト
	beq	@f
	cmp.b	#3,d0
	bls	1f			;ファイル名の最上位バイトが1～3
;ファイル名の最上位バイトが4以上
	tst.l	himemAreaSize
	beq	4f
	move.l	(sp),d0
	cmp.l	himemAreaEnd,d0
	blo	3f
	cmp.l	#$14000000,d0
	blo	2f
3:	moveq.l	#0,d0
	bra	@f

;ファイル名の最上位バイトがローカルメモリ
2:	rol.l	#8,d0
4:	and.l	#$00000003,d0
;ファイル名の最上位バイトを修正する
1:	movea.l	$1C5C.w,a1
	move.b	(dosPC,a1),(sp)		;pcの最上位バイトを補う
@@:	movea.l	(sp)+,a1		;最上位バイトが修正されている
;<d0.l:実行ファイルの形式の指定(0=拡張子,1=r,2=z,3=x)
;<a1.l:最上位バイトが修正されたファイル名のアドレス
	move.l	d0,-(sp)
	jsr	$0000997C.l		;ファイル名の拡張子の先頭の文字を小文字化して返す
;>d0.b:拡張子の先頭の文字を小文字化したもの(拡張子がなければ0)
	cmp.b	#'x',d0
	beq	3f
	cmp.b	#'r',d0
	beq	1f
	cmp.b	#'z',d0
	beq	2f
;拡張子では見分けがつかないので指定に従う
	move.l	(sp)+,d0
	rts

;R形式
1:	moveq.l	#1,d0
	addq.l	#4,sp
	rts

;Z形式
2:	moveq.l	#2,d0
	addq.l	#4,sp
	rts

;X形式
3:	moveq.l	#3,d0
	addq.l	#4,sp
	rts



.comment !!!

;	ファイル名のアドレスの最上位バイトが
;	・$00のとき
;		形式0がmove(またはand)されている可能性がある
;	・$01～$03のとき
;		形式1～3がmove(または0にaddまたはor)されている可能性が高い
;	・ハイメモリの下限+1以上、ハイメモリの上限+3以下のとき
;		形式1～3がaddされている可能性がある
;	・ハイメモリの下限|1以上、ハイメモリの上限|3以下で下位2ビットが0でないとき
;		形式1～3がorされている可能性がある
;
;	ファイル名のアドレスの最上位バイトの復元を試みる
;	復元できたかどうかは以下の条件で判別する
;	・アドレスをアクセスできるかどうか(範囲内かどうか)
;	・ファイル名として正しいかどうか
;	・ファイルが存在して少なくとも2バイト読み込めるかどうか
;	最初にそのままの状態で試す
;	形式がmoveされている可能性があるときはpcおよびspの最上位バイトの前後を試す
;	形式がaddまたはorされている可能性があるときはその可能性がある範囲を試す
;
;	以下の場合はファイルの先頭2バイトで形式を判別する
;	・形式の指定がなくて拡張子がR,Z,Xのいずれでもない場合
;	・ファイル名のアドレスを復元できたが形式をaddしたのかorしたのかわからない場合
;	ファイルの先頭2バイトが
;	・'HU'のとき
;		X形式の実行ファイル
;	・$601Aのとき
;		Z形式の実行ファイル
;	・その他
;		R形式の実行ファイル
;
;	今後の課題
;		シンボリックリンクへの対応
;		(他のDOSコールも対応させる必要がある)
;		ファイルの先頭2バイトが'#!'のときはスクリプトと見なす
;		(引数を変える必要があるのでこのパッチの範囲では処理できない)

	movem.l	d1-d3/a1,-(sp)
;最初にファイル名のアドレスをLOGICAL_MASKでマスクして余計なフラグ類を消す
;この方法ではハイメモリ領域256MBの末尾で形式1～3がaddされて論理アドレス空間512MBから
;溢れた場合に対処できない
	move.w	#LOGICAL_MASK>>24,d0
	and.b	(4*3,sp),d0		;a1の最上位バイト,スタック注意
;<d0.w:ファイル名のアドレスの最上位バイト(0拡張)

	cmp.b	#3,d0
	bhi	@f
;ファイル名のアドレスの最上位バイトが$00～$03
	move.l	#$0001_0001,d3
	lsl.l	d0,d3
	lsl.b	#2,d0
	lsl.w	d0,d3
;<d3.l:
;	$0001_0001	最上位バイトが$00
;			距離0で形式0がaddされた可能性
;			距離0で形式0がorされた可能性
;			距離不明で形式0がmoveされた可能性
;	$0002_0020	最上位バイトが$01
;			距離1で形式1がaddされた可能性
;			距離1で形式1がorされた可能性
;			距離不明で形式1がmoveされた可能性
;	$0004_0400	最上位バイトが$02
;			距離2で形式2がaddされた可能性
;			距離2で形式2がorされた可能性
;			距離不明で形式2がmoveされた可能性
;	$0008_8000	最上位バイトが$03
;			距離3で形式3がaddされた可能性
;			距離3で形式3がorされた可能性
;			距離不明で形式3がmoveされた可能性
	bra	9f

@@:
;ファイル名のアドレスの最上位バイトが$04以上
	tst.l	himemAreaSize
	beq	90f			;ハイメモリ領域がない
	moveq.l	#0,d3
	move.l	himemAreaStart,d1
	rol.l	#8,d1
;<d1.b:ハイメモリ領域の先頭のアドレスの最上位バイト
	sub.b	d0,d1
;<d1.b:ファイル名のアドレスの最上位バイトからハイメモリ領域の先頭のアドレスの最上位バイトまでの距離
;	1以上は範囲外
;	0は距離0が有効
;	-1は距離0～1が有効
;	-2は距離0～2が有効
;	-3以下は距離0～3が有効
	bgt	90f			;1以上なので範囲外
	move.l	#$0000_FFFF,d3
	addq.b	#3,d1
;	3は距離0が有効
;	2は距離0～1が有効
;	1は距離0～2が有効
;	0以下は距離0～3が有効
	bcc	@f
	lsl.b	#2,d1
	lsr.w	d1,d3
@@:
;<d3.w:ハイメモリ領域の下限による距離の条件
;	$FFFF	距離0～3が有効
;	$0FFF	距離0～2が有効
;	$00FF	距離0～1が有効
;	$000F	距離0が有効

	move.l	himemAreaEnd,d1
	subq.l	#1,d1
	rol.l	#8,d1
;<d1.b:ハイメモリ領域の末尾のアドレスの最上位バイト
	sub.b	d0,d1
;<d1.b:ファイル名のアドレスの最上位バイトからハイメモリ領域の末尾のアドレスの最上位バイトまでの距離
;	0以上は距離0～3が有効
;	-1は距離1～3が有効
;	-2は距離2～3が有効
;	-3は距離3が有効
;	-4以下は範囲外
	bge	@f			;0以上なので範囲内
	addq.b	#3,d1
	bmi	90f			;範囲外
;	2は距離1～3が有効
;	1は距離2～3が有効
;	0は距離3が有効
	lsl.b	#2,d1
	move.l	#$0000_FFFF,d2
	lsl.w	d1,d2
;<d2.w:ハイメモリ領域の上限による距離の条件
;	$FFFF	距離0～3が有効
;	$FFF0	距離1～3が有効
;	$FF00	距離2～3が有効
;	$F000	距離3が有効
	and.w	d2,d3
@@:

;<d3.w:ハイメモリ領域の条件

;ファイル名のアドレスの最上位バイトがハイメモリ領域を指している場合
	and.b	#3,d0			;下位2ビット
	bne	@f
	and.w	#$0001,d3		;下位2ビットが0
					;	距離0で形式0がorされた可能性(0|0=0)
	bra	1f
@@:
	subq.b	#2,d0
	bcc	@f
	and.w	#$0023,d3		;下位2ビットが1
					;	距離0で形式0がorされた可能性(1|0=1)
					;	距離0で形式1がorされた可能性(1|1=1)
					;	距離1で形式1がorされた可能性(0|1=1)
	bra	1f
@@:
	bne	@f
	and.w	#$0405,d3		;下位2ビットが2
					;	距離0で形式0がorされた可能性(2|0=2)
					;	距離0で形式2がorされた可能性(2|2=2)
					;	距離2で形式2がorされた可能性(0|2=2)
	bra	1f
@@:
	and.w	#$86AF,d3		;下位2ビットが3
					;	距離0で形式0がorされた可能性(3|0=3)
					;	距離0で形式1がorされた可能性(3|1=3)
					;	距離0で形式2がorされた可能性(3|2=3)
					;	距離0で形式3がorされた可能性(3|3=3)
					;	距離1で形式1がorされた可能性(2|1=3)
					;	距離1で形式3がorされた可能性(2|3=3)
					;	距離2で形式2がorされた可能性(1|2=3)
					;	距離2で形式3がorされた可能性(1|3=3)
					;	距離3で形式3がorされた可能性(0|3=3)
1:
	tst.l	d3
	beq	90f

9:
;<d3.l:ファイル名のアドレスの最上位バイトの範囲による条件
;	bit0	1=距離0で形式0が指定された可能性がある
;	bit1	1=距離0で形式1が指定された可能性がある
;	bit2	1=距離0で形式2が指定された可能性がある
;	bit3	1=距離0で形式3が指定された可能性がある
;	bit4	1=距離1で形式0が指定された可能性がある
;	bit5	1=距離1で形式1が指定された可能性がある
;	bit6	1=距離1で形式2が指定された可能性がある
;	bit7	1=距離1で形式3が指定された可能性がある
;	bit8	1=距離2で形式0が指定された可能性がある
;	bit9	1=距離2で形式1が指定された可能性がある
;	bit10	1=距離2で形式2が指定された可能性がある
;	bit11	1=距離2で形式3が指定された可能性がある
;	bit12	1=距離3で形式0が指定された可能性がある
;	bit13	1=距離3で形式1が指定された可能性がある
;	bit14	1=距離3で形式2が指定された可能性がある
;	bit15	1=距離3で形式3が指定された可能性がある
;	bit16	1=距離不明(pc,spの前後)で形式0が指定された可能性がある
;	bit17	1=距離不明(pc,spの前後)で形式1が指定された可能性がある
;	bit18	1=距離不明(pc,spの前後)で形式2が指定された可能性がある
;	bit19	1=距離不明(pc,spの前後)で形式3が指定された可能性がある

;距離0～3を順にチェックする
30:
;この距離だった可能性があるか
	moveq.l	#$0F,d1
	and.w	d3,d1
	beq	39f			;この距離ではない

;<d1.l:形式の候補
;<a1.l:ファイル名のアドレス
	bsr	checkExecFil



39:
	suba.l	#$01000000,a1
	lsr.w	#4,d3
	bne	30b



	movem.l	(sp)+,d1-d3/a1,-(sp)
	rts


;判別失敗
90:
	movem.l	(sp)+,d1-d3/a1,-(sp)
	moveq.l	#0,d0
	rts


;ファイル名のアドレスが正しいか調べる
;<d1.l:形式の候補(複数指定可)
;	bit0	拡張子で判別
;	bit1	R形式
;	bit2	Z形式
;	bit3	X形式
;<a1.l:ファイル名のアドレス
;>d0.l:-1=エラー
;>d1.l:形式
;	2	R
;	4	Z
;	8	X
	.text
	.align	4,$2048
checkExecFil::
	movem.l	a2-a3,-(sp)
	lea.l	(-ncSize-fSize,sp),sp

;ファイル名として正しいか
	move.l	a1,-(sp)
	DOS	_NAMECK
	addq.l	#4,sp
	tst.l	d0
	bne	90f			;エラーまたはワイルドカードがある

;拡張子を確認しておく
	move.l	(ncExt,sp),d0		;拡張子(ncExtは偶数)
	and.l	#$FFDFFF00,d0		;1文字目を大文字化,3文字目を無視
	cmp.l	#'.R'<<16,d0
	bne	1f
	moveq.l	#$02,d1
	bra	3f
1:	cmp.l	#'.Z'<<16,d0
	bne	2f
	moveq.l	#$04,d1
	bra	3f
2:	cmp.l	#'.X'<<16,d0
	bne	3f
	moveq.l	#$08,d1
3:

;ドライブの準備ができているか
	moveq.l	#$1F,d0
	and.b	(ncDrive,sp),d0		;ドライブ番号(1=A:)
	move.w	d0,-(sp)
	DOS	_DRVCTRL
	addq.l	#2,sp
	and.b	#$02,d0
	beq	90f			;ドライブの準備ができていない

;フルパスのファイル名を作る
	lea.l	(ncPath,sp),a3
@@:	tst.b	(a3)+
	bne	@b
	subq.l	#1,a3
	lea.l	(ncName,sp),a2
@@:	move.b	(a2)+,(a3)+
	bne	@b
	subq.l	#1,a3
	lea.l	(ncExt,sp),a2
@@:	move.b	(a2)+,(a3)+
	bne	@b

;ファイルを検索する
	move.w	#$0020,-(sp)		;ファイルのみ
	pea.l	(2,sp)
	pea.l	(4+2+ncSize,sp)
	DOS	_FILES
	lea.l	(10,sp),sp
	tst.l	d0
	bne	90f			;ファイルが見つからない

;先頭の2バイトを読み込んでみる




99:
	lea.l	(ncSize+fSize,sp),sp
	movem.l	(sp)+,a2-a3
	rts

90:
	moveq.l	#-1,d0
	bra	99b
!!!



;----------------------------------------------------------------
;_EXEC	スーパーバイザモード選択
;変更前
;	$00009748
;		and.l	#$00FFFFFF,d0
;		cmp.l	$0000837A,d0		;Humanの末尾のアドレス+1
;		bcc.s	$0000975E
;	$00009756
;		ori.w	#$2000,($38,a5)		;スーパーバイザモードで起動する
;		rts
;	$0000975E
;		cmp.l	#$00C00000,d0
;		bcc.s	$00009756
;		andi.w	#$DFFF,($38,a5)		;ユーザモードで起動する
;		rts
;$00009748
	.text
	.align	4,$2048
human302_execsuperpat::
	and.l	#LOGICAL_MASK,d0
	cmp.l	$0000837A.l,d0
	bcc	2f
;スーパーバイザモードで起動する
1:	ori.w	#$2000,(dosSR,a5)
	rts

2:	cmp.l	#$00C00000,d0
	bcs	3f
	cmp.l	#$01000000,d0
	bcs	1b
;ユーザモードで起動する
3:	andi.w	#$DFFF,(dosSR,a5)
	rts

;----------------------------------------------------------------
;_KEEPPR	常駐フラグの設定
;変更前
;	$0000A064
;		ori.l	#$FF000000,$0004(a0)	;常駐フラグを設定
;$0000A064
	.text
	.align	4,$2048
human302_keeppr::
;親のアドレスの最上位バイトに常駐フラグ$FFを書き込む
;親がハイメモリにあるとアドレスが破壊される
;親はいつまでも健在とは限らないのでそもそも辿ってよい情報ではないが
;念のため始祖であるHuman68kのメモリ管理テーブルのアドレスを入れておく
	tst.b	(Proc,a0)
	beq	@f
	move.l	$1C20.w,(Proc,a0)	;Humanのメモリ管理テーブル
@@:	ori.l	#$FF000000,(Proc,a0)	;常駐フラグを設定
	jmp	$0000A06C

;----------------------------------------------------------------
;_S_MFREE	メモリ管理が破壊されるバグ
;変更前
;	$0000DF9A
;		movea.l	d2,a0			;先頭
;		movea.l	(-16,a0),a1		;サブの直前
;		movea.l	(-16+12,a0),a2		;サブの直後
;		move.l	a1,(a0)			;先頭のブロックの直前をサブの直前にする
;		clr.b	(-16+4,a0)		;サブの親のフラグを消す
;		move.l	(-16+4,a0),(4,a0)	;先頭のブロックの親をサブの親にする
;	$0000DFB0
;		move.l	(12,a0),d0		;末尾のブロックまでスキップ
;		beq.s	$0000DFBA
;		movea.l	d0,a0
;		bra.s	$0000DFB0
;	$0000DFBA
;		move.l	a2,(12,a0)		;末尾のブロックの直後をサブの直後にする
;	$0000DFBE
;$0000DF9A
	.text
	.align	4,$2048
human302_smfreepat::
	movea.l	d2,a0			;先頭
	movea.l	(-16,a0),a1		;サブの直前
	movea.l	(-16+12,a0),a2		;サブの直後
	move.l	a1,(a0)			;先頭の直前をサブの直前にする
	beq	1f
	move.l	a0,(12,a1)		;サブの直前の直後を先頭にする
1:	andi.l	#LOGICAL_MASK,(-16+4,a0)	;サブの親のフラグを消す
	move.l	(-16+4,a0),(4,a0)	;先頭の親をサブの親にする
	move.l	d2,d0			;先頭
2:	movea.l	d0,a0
	move.l	(12,a0),d0		;末尾までスキップ
	bne	2b
	move.l	a2,(12,a0)		;末尾の直後をサブの直後にする
	beq	3f
	move.l	a0,(a2)			;サブの直後の直前を末尾にする
3:	jmp	$0000DFBE.l

;----------------------------------------------------------------
;バスエラーチェック(_BUS_ERRの下請けルーチン)
;<d1.w:サイズ
;	1	バイト
;	2	ワード
;	4	ロングワード
;<a0.l:読み出すアドレス
;<a1.l:書き込むアドレス
;>d0.l:バスエラーの発生状況
;	0	読み書き成功
;	1	読み出し成功,書き込み失敗
;	2	読み書き失敗
;	-1	パラメータがおかしい
;$0000E28A
	.text
	.align	4,$2048
human302_buserr::
  debug '|buserr in (size,read,write)=',3,d1,a0,a1
  debug '|buserrtrap=',1,#human302_buserr_trap
	PUSH_SR_DI
	PUSH_CACR_DISABLE_DC	d0
;仮のベクタテーブルを作る
	movec.l	vbr,a5			;a5=元のvbr
	movea.l	dosBusErrVbr,a6
	movec.l	a6,vbr			;ベクタテーブルを本体メモリへ
					;どうせベクタテーブルを作っている最中に
					;割り込まれても処理できないので先に設定する
	move.w	#256-1,d0		;仮のベクタテーブルはすべてトラップ
@@:	move.l	#human302_buserr_trap,(a6)+
	dbra	d0,@b
;仮のスーパーバイザスタックを使う
	movea.l	sp,a6			;a6=元のssp
	movea.l	dosBusErrSsp,sp		;sspを本体メモリへ
;
	moveq.l	#2,d0
	cmp.w	#1,d1
	beq	1f
	cmp.w	#2,d1
	beq	2f
	cmp.w	#4,d1
	beq	4f
9:	moveq.l	#-1,d0
8:	movea.l	a6,sp
	movec.l	a5,vbr
	POP_CACR	d1
	POP_SR
  debug '|buserr out (err)=',1,d0
	rts

human302_buserr_trap:
	movea.l	a6,sp
	bra	8b

1:	nop
	move.b	(a0),d1
	nop
	moveq.l	#1,d0
	nop
	move.b	d1,(a1)
	nop
	moveq.l	#0,d0
	bra	8b

2:	move.l	a0,d1
	lsr.l	#1,d1
	bcs	9b
	move.l	a1,d1
	lsr.l	#1,d1
	bcs	9b
	nop
	move.w	(a0),d1
	nop
	moveq.l	#1,d0
	nop
	move.w	d1,(a1)
	nop
	moveq.l	#0,d0
	bra	8b

4:	move.l	a0,d1
	lsr.l	#1,d1
	bcs	9b
	move.l	a1,d1
	lsr.l	#1,d1
	bcs	9b
	nop
	move.l	(a0),d1
	nop
	moveq.l	#1,d0
	nop
	move.l	d1,(a1)
	nop
	moveq.l	#0,d0
	bra	8b

;----------------------------------------------------------------
;DISK2HDデバイスドライバの処理ルーチンの取得と設定
;	$00010A20
;		move.w	(a6)+,(a4)+
;		dbra	d0,$00010A20
;$00010A20
	.text
	.align	4,$2048
human302_disk2hd_jmp::
@@:	move.w	(a6)+,(a4)
	addq.l	#2,a4
	dbra	d0,@b
	bsr	cache_flush
	rts

	.include	t00iocs.equ
	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ
	.include	t09version.equ

;__DEBUG__	equ	1

;__USE_DISPLACMENT__	equ	1

	.cpu	68060

  .ifdef __USE_DISPLACEMENT__
r	reg	-deviceHeader.w(a4)	;t10head.sにあるラベル以外には使わないこと
  .else
r	reg	-0
  .endif

;----------------------------------------------------------------
;常駐部分の末尾
keepTail::

;----------------------------------------------------------------
;デバイス初期化
deviceInitialize::
	movem.l	d1-d7/a0-a4/a6,-(sp)
  .ifdef __USE_DISPLACEMENT__
	lea.l	deviceHeader,a4
  .endif
  debug 'device initialize start',0

	lea.l	(banner,pc),a1
	bsr	print

;----------------------------------------------------------------
;MPU,Humanのチェック
	bsr	mpuCheck
	bmi	deviceInitializeError
	bsr	humanCheck
	bmi	deviceInitializeError
  debug 'MPU,ROM,Human check ok',0

;----------------------------------------------------------------
;データキャッシュがOFFのときキャッシュをプッシュせずに無効化する
	cmpi.b	#4,$0CBC.w
	blo	99f
	movec.l	cacr,d0
	btst.l	#CACR_EDC_BIT,d0
	bne	@f
	cinva	dc
@@:	cinva	ic
99:

;----------------------------------------------------------------
;store/load bypass機能を無効にする
	cmpi.b	#6,$0CBC.w
	bne	10f
	movec.l	pcr,d0
	bset.l	#5,d0			;disable store/load bypass
	movec.l	d0,pcr
10:

;----------------------------------------------------------------
;ローカルメモリの容量チェック
	bsr	getLocalMemorySize
	move.l	d0,(localMemorySize)r
	move.l	d1,(localMemoryStart)r
	add.l	d0,d1
	move.l	d1,(localMemoryEnd)r
  debug 'local memory size checked',0

;----------------------------------------------------------------
;管理領域の範囲の初期化
	move.l	#keepTail,d0
	add.l	#$00001FFF,d0		;mainLowerStartはページサイズに合わせる
	and.l	#$FFFFE000,d0
	move.l	d0,(mainLowerStart)r
	move.l	d0,(mainLowerEnd)r
	move.l	$1C00.w,d0
	and.l	#$FFFFE000,d0
	move.l	d0,(mainUpperStart)r
	move.l	d0,(mainUpperEnd)r
	tst.l	(localMemorySize)r
	beq	@f
	move.l	(localMemoryStart)r,d0
	move.l	d0,(localLowerStart)r
	move.l	d0,(localLowerEnd)r
	move.l	(localMemoryEnd)r,d0
	move.l	d0,(localUpperStart)r
	move.l	d0,(localUpperEnd)r
@@:
  debug 'management area set',0

;----------------------------------------------------------------
;転送バッファの領域の初期化
	clr.l	(tempBufferSize)r
  debug 'temporary buffer vanished',0

;----------------------------------------------------------------
;メインメモリ上のRAMDISKの領域の初期化
	move.l	(mainUpperStart)r,d0
	move.l	d0,(mainRamdiskAreaStart)r
	move.l	d0,(mainRamdiskAreaEnd)r
	clr.l	(mainRamdiskAreaSize)r
  debug 'main RAMDISK vanished',0

;ローカルメモリ上のRAMDISKの領域の初期化
	move.l	(localLowerStart)r,d0
	move.l	d0,(localRamdiskAreaStart)r
	move.l	d0,(localRamdiskAreaEnd)r
	clr.l	(localRamdiskAreaSize)r
  debug 'local RAMDISK vanished',0

;----------------------------------------------------------------
;メインメモリのサイズの初期化
	move.l	#-1,(mainMemorySize)r
  debug 'main memory size initialized',0

;----------------------------------------------------------------
;パラメータの解釈
;	mainLowerを使うもの
;		tempBuffer
;		dosBusErr
;	mainUpperを使うもの
;		mainRamdiskArea
;		descArea
;	localLowerを使うもの
;		localRamdiskArea
;	localLowerとlocalUpperの間がhimemArea
;	localUpperを使うもの
;		localRom
;		descArea
  debug 'parameter check start',0
;68030のとき-ntを強制的に指定する
	cmpi.b	#3,$0CBC.w
	bhi	@f
	st.b	(noTranslation)r
@@:
	movea.l	(18,a5),a6		;パラメータのアドレス
1:	tst.b	(a6)+
	bne	1b
	tst.b	(a6)
	beq	2f
	movea.l	a6,a0
	bsr	getParam
	bra	1b
2:
  debug 'parameter check end',0

;----------------------------------------------------------------
;デスクリプタの領域のサイズを決定する
;	-tsの指定があればそのまま
;	-tsの指定がおかしければ0になっているのでここで設定される
	tst.b	(noTranslation)r
	bne	99f
	bsr	defaultDescAreaSize
  debug 'desc area size set',0
99:

;----------------------------------------------------------------
;メインメモリ上のRAMDISKの領域をページサイズの倍数まで切り下げる
	move.l	(mainRamdiskAreaStart)r,d0
	and.l	(pageMask)r,d0
	move.l	d0,(mainRamdiskAreaStart)r
	move.l	d0,(mainUpperStart)r
  debug 'main RAMDISK area resized',0

;----------------------------------------------------------------
;転送バッファの確保
	tst.l	(tempBufferSize)r
	bne	@f
	move.l	#DEFAULT_BUFFER_SIZE,d0	;転送バッファはページサイズの倍数にすること
	move.l	d0,(tempBufferSize)r
	move.l	(mainLowerEnd)r,d1
	add.l	#$00001FFF,d1		;転送バッファはページ位置に合わせる
	and.l	#$FFFFE000,d1
	move.l	d1,(tempBufferStart)r
	add.l	d0,d1
	move.l	d1,(tempBufferEnd)r
	move.l	d1,(mainLowerEnd)r
	move.l	(mainUpperStart)r,d0
	sub.l	d1,d0
	cmp.l	#128*1024,d0
	blt	tempBufferOver
@@:

;----------------------------------------------------------------
;ADPCM転送バッファの確保と初期化
	tst.b	(patchIocsAdpcm)r
	beq	@f
	move.l	(adpcmBufferSize)r,d0	;設定済み
	move.l	(mainLowerEnd)r,d1
	add.l	#$00001FFF,d1		;転送バッファはページ位置に合わせる
	and.l	#$FFFFE000,d1
	move.l	d1,(adpcmBufferStart)r
	move.l	d1,(adpcmBufferPtr0)r
	add.l	d0,d1
	move.l	d1,(adpcmBufferPtr1)r
	add.l	d0,d1
	move.l	d1,(adpcmBufferEnd)r
	add.l	#$00001FFF,d1		;転送バッファはページ位置に合わせる
	and.l	#$FFFFE000,d1
	move.l	d1,(mainLowerEnd)r
	bsr	dmac3Initialize
;1ページだけなのでメモリ不足チェックは省略
@@:

;----------------------------------------------------------------
;_BUS_ERR用の仮のベクタテーブルと仮のスーパーバイザスタックの領域を確保する
	move.l	(mainLowerEnd)r,d0
	move.l	d0,(dosBusErrVbr)r
	add.l	#1024+1024,d0		;2KBなのでメモリ不足チェックは省略
	move.l	d0,(dosBusErrSsp)r
	move.l	d0,(mainLowerEnd)r

;----------------------------------------------------------------
;ローカルメモリ上のRAMDISKの領域をページサイズの倍数まで切り上げる
	move.l	(localRamdiskAreaEnd)r,d0
	add.l	(pageOffsetMask)r,d0
*****pageMaskでマスクすると論理アドレス空間の末尾が0になってしまう
*****	and.l	(pageMask)r,d0
	and.w	(pageMask+2)r,d0
	move.l	d0,(localRamdiskAreaEnd)r
	move.l	d0,(localLowerEnd)r
  debug 'local RAMDISK area resized',0

;----------------------------------------------------------------
;ローカルメモリ上にROMをコピーする
	tst.b	(noTranslation)r
	bne	99f
	tst.b	(localRomArea)r
	beq	2f
	movea.l	#$00F00000,a1
	movea.l	(localRomStart)r,a0
1:	move16	(a1)+,(a0)+
	cmpa.l	#$01000000,a1
	blo	1b
	movea.l	(localRomStart)r,a0
	add.l	#$00FF0000-$00F00000,a0
	move.l	#'loca',(a0)+
	move.l	#'lRom',(a0)+

;ROMVER=$15970213のバグを修正
	IOCS	_ROMVER
	cmp.l	#$15970213,d0
	bne	9f
	movea.l	(localRomStart)r,a0
	add.l	#$00FFB32C-$00F00000,a0
	cmpi.l	#$4A75002A,(a0)
	bne	@f
	move.l	#$4A75042A,(a0)
@@:
	move.b	#$08,DCR2
	move.b	#$05,MFC2
	move.b	#$03,CPR2
	move.b	#$05,DFC2
;	move.b	#$05,BFC2
;	move.b	#$68,NIV2
;	move.b	#$69,EIV2
9:

;ROMVER=$15970529のバグを修正
	IOCS	_ROMVER
	cmp.l	#$15970529,d0
	bne	9f
;ソフトキーボードが表示されている状態でキーを押すとハングアップするバグを修正
	movea.l	(localRomStart)r,a0
	add.l	#$00FF5004-$00F00000,a0
	cmpi.w	#$2057,(a0)		;movea.l (sp),a0
	bne	@f
	move.w	#$205F,(a0)		;movea.l (sp)+,a0
@@:
9:

;SCSIのDMA転送をPACKしてみる(700KB→500KBと、かえって遅くなるらしい)
;	IOCS	_ROMVER
;	cmp.l	#$14970107,d0
;	bne	@f
;	movea.l	(localRomStart)r,a0
;	add.l	#$00FFDE60-$00F00000,a0
;	cmpi.w	#$80B1,(a0)
;	bne	@f
;	move.w	#$8081,(a0)
;@@:
	bsr	cache_flush
2:
  debug 'local ROM area set',0
99:

;----------------------------------------------------------------
;デスクリプタの領域の確保
	tst.b	(noTranslation)r
	bne	99f
	tst.b	(localAreaDescriptor)r
	beq	1f
	move.l	(localUpperStart)r,d0
	sub.l	(descAreaSize)r,d0
	and.l	(pageMask)r,d0
	cmp.l	(localLowerEnd)r,d0
	bcc	2f
	sf.b	(localAreaDescriptor)r
;メインに作る
1:	move.l	(mainUpperStart)r,d0
	sub.l	(descAreaSize)r,d0
	and.l	(pageMask)r,d0
	move.l	(mainLowerEnd)r,d1
	add.l	#128*1024,d1
	cmp.l	d1,d0
	blt	descAreaOver
	move.l	d0,(mainUpperStart)r
	bra	3f
;ローカルに作る
2:	move.l	d0,(localUpperStart)r
3:	move.l	d0,(descAreaStart)r
	add.l	(descAreaSize)r,d0
	move.l	d0,(descAreaEnd)r
  debug 'descriptor area allocated',0
99:

;----------------------------------------------------------------
;_HIMEMの領域を設定
	clr.l	(himemAreaStart)r
	clr.l	(himemAreaEnd)r
	clr.l	(himemAreaSize)r
	tst.l	(localMemorySize)r
	beq	2f
	move.l	(localLowerEnd)r,d1
	move.l	(localUpperStart)r,d2
	move.l	d2,d0
	sub.l	d1,d0
	bls	2f			;HIMEMに空きエリアがない
	move.l	d0,(himemAreaSize)r
	move.l	d1,(himemAreaStart)r
	move.l	d2,(himemAreaEnd)r
	movea.l	d1,a0
	lea.l	(User,a0),a1
;;;	cmpi.l	#'060t',(a1)
;;;	beq	2f			;初期化されている
	move.l	#'060t',(a1)+
	move.l	#'urbo',(a1)+
	move.l	#'HIME',(a1)+
	move.l	#'M'<<24,(a1)+
	clr.l	(Prev,a0)
	move.l	$1C20.w,(Proc,a0)	;Humanのメモリ管理ポインタ
	move.l	a1,(Tail,a0)
	clr.l	(Next,a0)
2:
  debug 'HIMEM area initialized',0

;----------------------------------------------------------------
;スレッド間の排他制御情報を初期化する
	tst.b	(backgroundFlag)r
	beq	9f
;メインスレッドの排他制御情報を初期化する
	lea.l	(mainExclusive)r,a2
;標準ハンドラを作成する
	moveq.l	#0,d2
1:	move.w	d2,-(sp)
	DOS	_DUP			;標準ハンドラを複製する
	addq.l	#2,sp			;エラーが発生してはならない
	move.w	d0,(xStdin,a2,d2.w*2)
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;ドライブ管理テーブルのアドレスを設定する
	move.l	$1C38.w,(xDriveTablePtr,a2)	;現在のドライブ管理テーブル
9:

;----------------------------------------------------------------
;乱数系列を初期化する
	DOS	_GETDATE
	move.l	d0,d1
	DOS	_GETTIME
	add.w	d1,d0
	swap.w	d1
	add.w	d1,d0
	move.l	d0,d1
	bsr	srand
	move.l	d1,d0
	bsr	randomize

;----------------------------------------------------------------
;
;	以降は中断不可
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;Humanにパッチをあてる
	tst.b	(unitCounter)r		;RAMDISKがなければ,
	bne	@f			;RAMDISKのチェックは無意味なので省略する
	move.l	#callDeviceNoRamdisk,patchHumanCallDevice+2
@@:
	bsr	patchHuman
	bmi	deviceInitializeError
  debug 'Human68k patched',0

;----------------------------------------------------------------
;メインメモリを切り詰める
	move.l	(mainUpperStart)r,$1C00.w
  debug 'main memory resized',0

;----------------------------------------------------------------
;アドレス変換テーブルを作る
	tst.b	(noTranslation)r
	bne	99f
	bsr	makeTranslationTable
  debug 'address translation table created',0
99:

;----------------------------------------------------------------
;ベクタ設定
	move.b	(localRomArea)r,d0
	or.b	(localSystemArea)r,d0
	beq	@f
	lea.l	(vectorInfoHumanTrap10)r,a0
	bsr	setVector
  debug 'TRAP#10 vector set',0
@@:

	lea.l	(vectorInfoPRIVILEGE)r,a0
	bsr	setVector
	lea.l	(vectorInfoFLINE)r,a0
	bsr	setVector
	lea.l	(vectorInfoBSUN)r,a0
	bsr	setVector
	lea.l	(vectorInfoINEX)r,a0
	bsr	setVector
	lea.l	(vectorInfoDZ)r,a0
	bsr	setVector
	lea.l	(vectorInfoUNFL)r,a0
	bsr	setVector
	lea.l	(vectorInfoOPERR)r,a0
	bsr	setVector
	lea.l	(vectorInfoOVFL)r,a0
	bsr	setVector
	lea.l	(vectorInfoSNAN)r,a0
	bsr	setVector
	lea.l	(vectorInfoUNSUPP)r,a0
	bsr	setVector
	lea.l	(vectorInfoEFFADD)r,a0
	bsr	setVector
	lea.l	(vectorInfoUNINT)r,a0
	bsr	setVector
  debug '060SP vector set',0

	lea.l	(spBanner,pc),a1
	bsr	print

	tst.b	(patchIocsAdpcm)r
	beq	@f
	lea.l	(vectorInfoIocsAdpcmout)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcminp)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmaot)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmain)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmlot)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmlin)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmsns)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmmod)r,a0
	bsr	setVector
  debug 'IOCS ADPCM vector set',0
@@:

	tst.b	(softwareIocsDma)r
	beq	@f
	lea.l	(vectorInfoIocsDmamove)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsDmamovA)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsDmamovL)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsDmamode)r,a0
	bsr	setVector
  debug 'IOCS DMA vector set',0
@@:

	lea.l	(vectorInfoIocsSysStat)r,a0
	bsr	setVector
  debug 'SYS_STAT vector set',0

	cmpi.w	#_SCSIDRV*$0100+$00FF,$0400+_SCSIDRV*4.w
	beq	@f			;_SCSIDRVは登録されていない
	cmpi.w	#$00FF,$0400+_SCSIDRV*4.w
	beq	@f			;_SCSIDRVは登録されていない
	SCSI	_S_REVISION
	move.w	d0,(scsiRevisionCode)r
	lea.l	(vectorInfoIocsScsidrv)r,a0
	bsr	setVector
  debug 'SCSIDRV vector set',0
@@:

	lea.l	(vectorInfoIocsPrnintst)r,a0
	bsr	setVector
	lea.l	(vectorInfoPrnint)r,a0
	bsr	setVector
  debug 'PRNINTST vector set',0

	tst.b	(useIocsHimem)r
	beq	@f
	lea.l	(vectorInfoIocsHimem)r,a0
	bsr	setVector
  debug 'HIMEM vector set',0
@@:

	lea.l	(vectorInfoDosExec)r,a0
	bsr	setVector
  debug 'EXEC vector set',0

;	tst.b	(useJointMode)r
;	beq	@f
	lea.l	(vectorInfoDosMalloc)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Malloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMalloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Malloc3)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMalloc3)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Malloc4)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMalloc4)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMfree)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSetblock)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Setblock2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSetblock2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SMalloc)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSMalloc)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SMalloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSMalloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SMfree)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSMfree)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SProcess)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSProcess)r,a0
	bsr	setVector
  debug 'memory doscall vector set',0
@@:

	tst.b	(backgroundFlag)r
	beq	@f
	lea.l	(vectorInfoDosOpenPr)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosKillPr)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosChangePr)r,a0
	bsr	setVector
  debug 'background doscall vector set',0
@@:

;----------------------------------------------------------------
;アドレス変換開始
	tst.b	(noTranslation)r
	bne	99f
	bsr	enableTranslation
  debug 'address translation enabled',0
99:

;----------------------------------------------------------------
;キャッシュなどの状態を初期化
;EBC=1,ESB=1,ESS=1,EDC=0,EIC=0
;	データキャッシュと命令キャッシュの状態は,
;	060turbo.sysの初期化が終わってHumanに戻った直後に,
;	パッチによってSRAMの設定になる
	move.w	#$C007,d1
	moveq.l	#%11100,d2
	IOCS	_SYS_STAT
  debug 'branch cache, store buffer, superscaler enabled',0

;----------------------------------------------------------------
;ベクタ領域からHuman本体の末尾までと060turbo.sysの常駐部分をローカルメモリに移動する
	tst.b	(localSystemArea)r
	beq	9f
	PUSH_MMU_SFC_DFC	d0
	move.l	(localSystemStart)r,d3	;コピー先
	suba.l	a1,a1			;コピー元
1:	cmpa.l	#$0001447A.and.PAGE_MASK,a1	;Human本体の末尾
	bne	@f
	move.l	#deviceHeader,d0	;060turbo.sysの先頭
	add.l	#PAGE_OFFSET_SIZE-1,d0
	and.l	#PAGE_MASK,d0
	movea.l	d0,a1
@@:
;
	bsr	getDesc
	move.l	d0,d2			;現在のページデスクリプタ
	and.l	(pageOffsetMask)r,d2	;属性だけ取り出す
	or.l	d3,d2			;コピー先のアドレスを使う
	movea.l	d3,a2			;コピー先
	movea.l	a1,a3			;コピー元
	move.l	(pageOffsetSize)r,d0
	lsr.l	#4,d0
;割り込みを止めた状態で大急ぎでコピーしてすぐに切り替える
;コピー元のアドレスでコピー先が見えるようにする
	PUSH_SR_DI
2:	move16	(a3)+,(a2)+
	subq.l	#1,d0
	bne	2b
	movea.l	d3,a2
	cpushp	bc,(a2)
	moves.l	d2,(a0)
	pflusha
	POP_SR
;念のためコピー先のアドレスでコピー元が見えるようにしておく
	exg.l	d3,a1
	bsr	getDesc			;コピー先
	and.l	(pageOffsetMask)r,d2	;属性だけ取り出す
	or.l	d3,d2			;コピー元のアドレスを使う
	moves.l	d2,(a0)
	pflusha
	exg.l	d3,a1
;
	add.l	(pageOffsetSize)r,d3
	adda.l	(pageOffsetSize)r,a1
	cmp.l	(localSystemEnd)r,d3
	blo	1b
	POP_SFC_DFC	d0
  debug 'local system started',0
9:

;----------------------------------------------------------------
;デバイス初期化終了
	tst.b	(unitCounter)r
	bne	1f
;ユニット数が0のときキャラクタデバイスのふりをする
	move.w	#$8000,(deviceHeader+dhType)r
	move.l	#'/*06',(deviceHeader+dhName)r
	move.l	#'0T*/',(deviceHeader+dhName+4)r
	bra	2f
1:	move.b	(unitCounter)r,(13,a5)	;ユニット数
	move.l	#bpbTablePointer,(18,a5)	;BPBテーブルのポインタのテーブル
2:	move.l	(mainLowerEnd)r,(14,a5)	;デバイスドライバの末尾+1
	moveq.l	#0,d0
  debug 'device initialize end',0

deviceInitializeExit:
	movem.l	(sp)+,d1-d7/a0-a4/a6
	rts

banner:
	.dc.b	13,10
*	.dc.b	$1B,'[1m'
	.dc.b	'060turbo.sys version ',VERSION
*	.dc.b	$1B,'[1m'
	.dc.b	' ',DATE
	.dc.b	' by M.Kamada',13,10,0

spBanner:
	.dc.b	'M68060 Software Package Copyright (C) Motorola Inc.',13,10
	.dc.b	0
	.even

deviceInitializeError:
	move.w	#$700D,d0
	bra	deviceInitializeExit

tempBufferOver:
	lea.l	(@f,pc),a1
	bsr	print
	bra	deviceInitializeError
@@:	.dc.b	'転送バッファが確保できません',13,10,0
	.even

descAreaOver:
	lea.l	(@f,pc),a1
	bsr	print
	bra	deviceInitializeError
@@:	.dc.b	'デスクリプタの領域が確保できません',13,10,0
	.even

;----------------------------------------------------------------
;MPUを確かめる
;68060のときHumanが[$0CBC].b=$03にしてしまっている
;>d0.l:0=成功,-1=失敗
;>ccr:pl成功,mi=失敗
mpuCheck:
	movem.l	d1/a0-a2,-(sp)
	PUSH_SR_DI
	movea.l	sp,a1
	move.l	$0010,a2
	move.l	#110f,$0010.w		;Illegal Instruction
;MOVEC from SFCがなければ68000
	moveq.l	#0,d0
	lea.l	(80f,pc),a0
	movec.l	sfc,d0
;スケールファクタがなければ68010
	moveq.l	#1,d0
10:	moveq.l	#1,d1
	and.b	(10b-1,pc,d1.l*2),d1
	beq	80f
;CALLMがあれば68020
	.cpu	68020
	lea.l	(40f,pc),a0
	callm	#0,(20f,pc)
	moveq.l	#2,d0
	bra	80f

;モジュールデスクリプタ
20:	.dc.l	%0<<13|0<<24|0<<16	;option=0,type=0,accesslevel=0
	.dc.l	30f			;モジュールエントリポインタ
	.dc.l	0			;モジュールデータ領域ポインタ
	.dc.l	0
;モジュールエントリ
30:	.dc.w	15<<12			;Rn=sp
	rtm	sp
	.cpu	68060

;MOVEC from CAARがあれば68030
	.cpu	68030
40:	lea.l	(50f,pc),a0
	movec.l	caar,d0
	moveq.l	#3,d0
	bra	80f
	.cpu	68060

;MOVEC from MMUSRがあれば68040
	.cpu	68040
50:	lea.l	(60f,pc),a0
	movec.l	mmusr,d0
	moveq.l	#4,d0
	bra	80f
	.cpu	68060

;MOVEC from PCRがあれば68060
60:	lea.l	(70f,pc),a0
	movec.l	pcr,d0
	moveq.l	#6,d0
	bra	80f

;不明
70:	moveq.l	#0,d0
80:	move.b	d0,$0CBC.w
	move.l	a2,$0010.w
	POP_SR
	moveq.l	#0,d0
	cmpi.b	#3,$0CBC.w
	bhs	90f
	lea.l	(100f,pc),a1
	bsr	print
	moveq.l	#-1,d0
90:	movem.l	(sp)+,d1/a0-a2
	tst.l	d0
	rts

100:	.dc.b	'68030 以上ではありません',13,10,0
	.even

110:	movea.l	a1,sp
	jmp	(a0)

;----------------------------------------------------------------
;Human68kのバージョンを確かめる
humanCheck:
	DOS	_VERNUM
	cmp.w	#$0302,d0
	bne	9f
	moveq.l	#0,d0
	rts

9:	lea.l	(@f,pc),a1
	bsr	print
	moveq.l	#-1,d0
	rts
@@:	.dc.b	'Human のバージョンが違います',13,10,0
	.even

;----------------------------------------------------------------
;Humanにパッチをあてる
patchHuman::
	bsr	patchHuman302
	bmi	9f
	rts

9:	lea.l	(@f,pc),a1
	bsr	print
	moveq.l	#-1,d0
	rts
@@:	.dc.b	'Human が異常です',13,10,0
	.even

;----------------------------------------------------------------
;ベクタを設定する
;<a0.l:ベクタ情報
;	0000	.l	ベクタアドレス
;	0004	.l	元のベクタ
;	0008	.l	新しいベクタ
setVector::
	movem.l	a0-a1,-(sp)
	movea.l	(a0)+,a1		;ベクタアドレス
	move.l	(a1),(a0)+		;元のベクタを保存
	move.l	(a0),(a1)		;新しいベクタを設定
	movem.l	(sp)+,a0-a1
	rts

;----------------------------------------------------------------
;ローカルメモリの容量と先頭アドレスを返す
;	前提
;	・ローカルメモリの容量と先頭アドレスは$01000000(16MB)の倍数である
;	・ローカルメモリのアクセスでアクセスエラーや不具合によるデータの破損は発生しない
;	・このプログラムはスーパーバイザモードで実行される
;	・このプログラムとスーパーバイザスタックエリアは論理アドレス=物理アドレスの領域にある
;	・このプログラムとスーパーバイザスタックエリアのアドレスの上位8ビットは$00である
;	手順
;	・$00000000-$3FFFFFFF(1024MB)を$01000000(16MB)ずつ64個に区切る
;	・上位のブロックから順に同じオフセットに異なるデータを書き込む
;	・上位のブロックから順に書き込んだデータを読み出せれば存在すると判断する
;パラメータなし
;>d0.l:ローカルメモリの容量
;>d1.l:ローカルメモリの先頭アドレス
getLocalMemorySize::
	movem.l	d2-d5/a0,-(sp)
	moveq.l	#0,d0
;キャッシュ禁止
	movec.l	cacr,d4
	movec.l	d0,cacr
	CACHE_FLUSH	d3
;MMU禁止
	cmpi.b	#4,$0CBC.w
	blo	@f
	movec.l	tc,d3
	movec.l	d0,tc
	pflusha
;トランスペアレント変換禁止
	movec.l	dtt1,d2
	movec.l	d0,dtt1
	movec.l	dtt0,d5
	movec.l	d0,dtt0
@@:
;コントロールレジスタ保存
	movem.l	d2-d5,-(sp)
;ワークエリア確保
	lea.l	-4-64(sp),sp
;保存
	moveq.l	#$3F,d1			;ブロックの番号。$3F→$00
10:	move.l	d1,d0
	ror.l	#8,d0
	lea.l	(sp,d0.l),a0		;テストするアドレス
	move.b	(a0),4(sp,d1.l)		;保存
	dbra	d1,10b
;変更
	moveq.l	#$3F,d1			;ブロックの番号。$3F→$00
20:	move.l	d1,d0
	ror.l	#8,d0
	lea.l	(sp,d0.l),a0		;テストするアドレス
	move.b	d1,(a0)			;変更
	dbra	d1,20b
;比較と復元
	moveq.l	#$3F,d1			;ブロックの番号。$3F→$00
30:	move.l	d1,d0
	ror.l	#8,d0
	lea.l	(sp,d0.l),a0		;テストするアドレス
	cmp.b	(a0),d1			;比較
	seq.b	d0			;0=ない,-1=ある
	bne	40f
	move.b	4(sp,d1.l),(a0)		;(あるとき)復元
40:	move.b	d0,4(sp,d1.l)		;結果。0=ない,-1=ある
	dbra	d1,30b
	sf.b	4(sp)			;ブロック0はローカルメモリではない
;末尾
	moveq.l	#$3F,d1			;ブロックの番号。$3F→$00
50:	tst.b	4(sp,d1.l)
	dbne	d1,50b
	beq	70f			;ない
;ある
	move.l	d1,d0			;末尾のブロックの番号
;先頭
60:	tst.b	4(sp,d1.l)
	dbeq	d1,60b			;必ずeqで止まる
	addq.b	#1,d1
	ror.l	#8,d1			;先頭のブロックの先頭アドレス
	addq.b	#1,d0
	ror.l	#8,d0			;末尾のブロックの末尾アドレス+1
	sub.l	d1,d0			;長さ
	bra	80f
;ない
70:	moveq.l	#0,d0
	moveq.l	#0,d1
80:
;<d0.l:ローカルメモリの容量
;<d1.l:ローカルメモリの先頭アドレス
;ワークエリア開放
	lea.l	4+64(sp),sp
;コントロールレジスタ復元
	movem.l	(sp)+,d2-d5
;トランスペアレント変換復元
	cmpi.b	#4,$0CBC.w
	blo	@f
	movec.l	d5,dtt0
	movec.l	d2,dtt1
;MMU復元
	movec.l	d3,tc
@@:
;キャッシュ復元
	movec.l	d4,cacr
	movem.l	(sp)+,d2-d5/a0
	rts


;----------------------------------------------------------------
;ローカルメモリのサイズからデスクリプタの領域のサイズを決定する
defaultDescAreaSize::
	movem.l	d0-d1,-(sp)
	tst.l	(descAreaSize)r
	bne	2f			;既に指定されている
	move.l	#DEFAULT_DESC_SIZE_0,d1
	move.l	(localMemorySize)r,d0
	beq	1f			;本体16MBのみ
	move.l	#DEFAULT_DESC_SIZE_16,d1
	cmp.l	#16<<20,d0
	bls	1f			;本体16MB+ローカル16MB
	move.l	#DEFAULT_DESC_SIZE_32,d1
	cmp.l	#32<<20,d0
	bls	1f			;本体16MB+ローカル32MB
	move.l	#DEFAULT_DESC_SIZE_64,d1
	cmp.l	#64<<20,d0
	bls	1f			;本体16MB+ローカル64MB
	move.l	#DEFAULT_DESC_SIZE_128,d1
	cmp.l	#128<<20,d0
	bls	1f			;本体16MB+ローカル128MB
	move.l	#DEFAULT_DESC_SIZE_256,d1
	cmp.l	#256<<20,d0
	bls	1f			;本体16MB+ローカル256MB
	move.l	#DEFAULT_DESC_SIZE_384,d1
	cmp.l	#384<<20,d0
	bls	1f			;本体16MB+ローカル384MB
	move.l	#DEFAULT_DESC_SIZE_512,d1
	cmp.l	#512<<20,d0
	bls	1f			;本体16MB+ローカル512MB
	move.l	#DEFAULT_DESC_SIZE_768,d1
					;本体16MB+ローカル768MB
1:	move.l	d1,(descAreaSize)r
2:	movem.l	(sp)+,d0-d1
	rts

;----------------------------------------------------------------
;アドレス変換テーブルを作る
makeTranslationTable::
	movea.l	(descAreaStart)r,a0
	movea.l	(descAreaEnd)r,a1
;デスクリプタの領域に関連するワークを設定する
	move.l	a0,(descHead)r
;	move.l	a0,(rootDescHead)r
	lea.l	(ROOT_DESC_SIZE,a0),a2
	move.l	a2,(rootDescTail)r
;	move.l	a2,(pointerDescHead)r
	move.l	a2,(pointerDescTail)r
	move.l	(descAreaSize)r,d0
	move.l	(pageIndexWidth)r,d1
	lsr.l	d1,d0			;参照数カウンタの領域のサイズ
	move.l	a1,d1
	sub.l	d0,d1
	and.l	(pageDescMask)r,d1
	move.l	d1,(pageDescHead)r
	move.l	d1,(pageDescTail)r
;	move.l	d1,(pointerCounterHead)r
	move.l	a1,(pageCounterTail)r
;	move.l	a1,(descTail)r

;デスクリプタの領域を初期化する
	movea.l	(rootDescHead)r,a0
	movea.l	(pageDescTail)r,a1
@@:	clr.l	(a0)+
	cmpa.l	a1,a0
	blo	@b
	movea.l	(pageCounterTail)r,a1
@@:	move.l	#-1,(a0)+
	cmpa.l	a1,a0
	blo	@b

	MMU_SFC_DFC	d0

;メインメモリのアドレス変換
	lea.l	(physicalModeTable,pc),a2
	suba.l	a1,a1
1:	move.l	(a2)+,d2		;モード
	move.l	(a2)+,d0		;次のアドレス
6:	cmpa.l	d0,a1
	blo	7f
	move.l	(a2)+,d2		;モード
	move.l	(a2)+,d0		;次のアドレス
	bpl	6b
7:	subq.l	#8,a2
	add.l	a1,d2
	bsr	setDesc
	bmi	9f			;エラー無視
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	#$01000000,a1
	bne	1b

	moveq.l	#$00000000,d1
2:	move.l	d1,d0
	bsr	copyPointerDesc
	add.l	#$00040000,d1
	adda.l	#$00040000,a1
	cmpa.l	#$02000000,a1
	bne	2b

3:	moveq.l	#$00000000,d0
	bsr	copyRootDesc
	adda.l	#$02000000,a1
	cmpa.l	#LOGICAL_SIZE,a1
	bne	3b

;ローカルメモリのアドレス変換
	move.l	(localMemorySize)r,d1
	beq	5f
	clr.w	d3
	move.b	localMemoryCacheMode,d3
	lsl.w	#PD_CM_BIT,d3
;		  UR G U1U0 S CM M U W PDT
	or.w	#%00_1__00__0_00_0_0_0_11,d3
	movea.l	#$10000000,a1
	add.l	a1,d1
4:	move.l	a1,d2
	or.w	d3,d2
	bsr	setDesc
	bmi	9f			;エラー無視
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	d1,a1
	bne	4b
5:

9:

;転送バッファの領域をライトスルーにする
	tst.l	(tempBufferSize)r
	beq	2f			;念のため
	movea.l	(tempBufferStart)r,a1	;既にページサイズに合わせてある
	movea.l	(tempBufferEnd)r,a2	;既にページサイズに合わせてある
1:	moveq.l	#0,d2			;ライトスルー
	bsr	sysStat_8004
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	a2,a1
	blo	1b
2:

;ADPCMの転送バッファの領域をライトスルーにする
	movea.l	(adpcmBufferStart)r,a1	;既にページサイズに合わせてある
	moveq.l	#0,d2			;ライトスルー
	bsr	sysStat_8004		;1ページだけ

;メインメモリ上のRAMDISKの領域をノンキャッシャブルにする
	movea.l	(mainRamdiskAreaStart)r,a1
	movea.l	(mainRamdiskAreaEnd)r,a2
	cmpa.l	a1,a2
	beq	2f
1:	moveq.l	#3,d2			;キャッシュ禁止ストアバッファ許可
	bsr	sysStat_8004
;指定論理ページをスーパーバイザ保護する
;<a1.l:論理アドレス
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bset.l	#PD_S_BIT,d0
	moves.l	d0,(a0)
	POP_SFC_DFC	d0
;
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	a2,a1
	blo	1b
2:

;ローカルメモリ上のRAMDISKの領域をノンキャッシャブルにする
	movea.l	(localRamdiskAreaStart)r,a1
	movea.l	(localRamdiskAreaEnd)r,a2
	cmpa.l	a1,a2
	beq	2f
1:	moveq.l	#3,d2			;キャッシュ禁止ストアバッファ許可
	bsr	sysStat_8004
;指定論理ページをスーパーバイザ保護する
;<a1.l:論理アドレス
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bset.l	#PD_S_BIT,d0
	moves.l	d0,(a0)
	POP_SFC_DFC	d0
;
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	a2,a1
	blo	1b
2:

;ローカルメモリ上のROM
	tst.b	(localRomArea)r
	beq	2f
	movea.l	#$00F00000,a1
	move.l	(localRomStart)r,d2
1:	bsr	sysStat_F001		;ROMアドレス→ローカルメモリ
	exg.l	d2,a1
	bsr	invDesc			;ローカルメモリ→無効
	exg.l	d2,a1
	add.l	(pageOffsetSize)r,d2
	adda.l	(pageOffsetSize)r,a1
	cmp.l	#$01000000,a1
	blo	1b


2:

;デスクリプタの領域を見えなくする
	movea.l	(descAreaStart)r,a1
1:	bsr	invDesc
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	(descAreaEnd)r,a1
	bne	1b
2:

	CACHE_FLUSH	d0		;念のためプッシュしておく
	rts

physicalModeTable::
;			   UR G U1U0 S CM M U W PDT
;	.dc.l	          %00_1__00__1_00_0_0_0_01	;Vector
;	.dc.l	$00002000
mainPD:
	.dc.l	          %00_1__00__0_00_0_0_0_01	;Main Memory
	.dc.l	$00C00000,%00_1__00__1_11_0_0_0_01	;Graphic
	.dc.l	$00E00000,%00_1__00__1_11_0_0_0_01	;Text
	.dc.l	$00E80000,%00_1__00__1_10_0_0_0_01	;CRTC
	.dc.l	$00E82000,%00_1__00__1_10_0_0_0_01	;Palet/Video Controler
	.dc.l	$00E84000,%00_1__00__1_10_0_0_0_01	;DMAC
	.dc.l	$00E86000,%00_1__00__1_10_0_0_0_01	;Supervisor Area Control
	.dc.l	$00E88000,%00_1__00__1_10_0_0_0_01	;MFP
	.dc.l	$00E8A000,%00_1__00__1_10_0_0_0_01	;RTC
	.dc.l	$00E8C000,%00_1__00__1_10_0_0_0_01	;Printer
	.dc.l	$00E8E000,%00_1__00__1_10_0_0_0_01	;System Port
	.dc.l	$00E90000,%00_1__00__1_10_0_0_0_01	;FM
	.dc.l	$00E92000,%00_1__00__1_10_0_0_0_01	;ADPCM
	.dc.l	$00E94000,%00_1__00__1_10_0_0_0_01	;FDC
	.dc.l	$00E96000,%00_1__00__1_10_0_0_0_01	;Internal SCSI
	.dc.l	$00E98000,%00_1__00__1_10_0_0_0_01	;SCC
	.dc.l	$00E9A000,%00_1__00__1_10_0_0_0_01	;Joy Stick
	.dc.l	$00E9C000,%00_1__00__1_10_0_0_0_01	;I/O Interrupt Control
	.dc.l	$00E9E000,%00_1__00__1_10_0_0_0_01	;Co-processor
	.dc.l	$00EA0000,%00_1__00__1_10_0_0_0_01	;External SCSI
	.dc.l	$00EAE000,%00_1__00__1_10_0_0_0_01	;Supervisor Area Control
							;External RS-232C
	.dc.l	$00EB0000,%00_1__00__1_10_0_0_0_01	;Sprite Register/Controler
	.dc.l	$00EB8000,%00_1__00__1_11_0_0_0_01	;Sprite PCG
	.dc.l	$00EBC000,%00_1__00__1_11_0_0_0_01	;Sprite Text
	.dc.l	$00EC0000,%00_1__00__0_10_0_0_0_01	;User I/O
	.dc.l	$00ED0000,%00_1__00__1_10_0_0_0_01	;SRAM
	.dc.l	$00ED4000,%00_1__00__0_10_0_0_0_01	;User I/O
	.dc.l	$00F00000,%00_1__00__1_00_0_0_1_01	;ROM
	.dc.l	-1

makeTranslationMain:
	.dc.b	'アドレス変換テーブルをメインメモリに配置します',13,10,0
	.even

;----------------------------------------------------------------
;アドレス変換を有効にする
enableTranslation::
	PUSH_SR_DI

	moveq.l	#0,d0
	movec.l	d0,cacr
	CACHE_FLUSH	d0

	move.l	(rootDescHead)r,d0
	movec.l	d0,srp
	movec.l	d0,urp

;		  E  P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
	move.l	#%1__0__0__0___0____0____10__00__0___10__00_0,d0
	cmpi.l	#4096,(pageOffsetSize)r
	beq	@f
	bset.l	#TC_P_BIT,d0
@@:	movec.l	d0,tc

	pflusha

	POP_SR
	rts


;----------------------------------------------------------------
;パラメータの解釈
;<a0.l:ワードの先頭
getParam::
	movea.l	a0,a1
	cmpi.b	#'-',(a0)+
	bne	9f
	move.w	(a0)+,d0		;奇数アドレスの可能性がある
	or.w	#$2020,d0
	cmp.w	#'ad',d0
	beq	param_ad
	cmp.w	#'bg',d0
	beq	param_bg
	cmp.w	#'bs',d0
	beq	param_bs
	cmp.w	#'cm',d0
	beq	param_cm
	cmp.w	#'dv',d0
	beq	param_dv
	cmp.w	#'fe',d0
	beq	param_fe
	cmp.w	#'hi',d0
	beq	param_hi
	cmp.w	#'ld',d0
	beq	param_ld
	cmp.w	#'lr',d0
	beq	param_lr
	cmp.w	#'ls',d0
	beq	param_ls
	cmp.w	#'lt',d0
	beq	param_lt
	cmp.w	#'lz',d0
	beq	param_lz
	cmp.w	#'md',d0
	beq	param_md
	cmp.w	#'mm',d0
	beq	param_mm
	cmp.w	#'np',d0
	beq	param_np
	cmp.w	#'nt',d0
	beq	param_nt
	cmp.w	#'sd',d0
	beq	param_sd
	cmp.w	#'sl',d0
	beq	param_sl
	cmp.w	#'ss',d0
	beq	param_ss
	cmp.w	#'ts',d0
	beq	param_ts
	cmp.w	#'xm',d0
	beq	param_xm
9:	bsr	print
	lea.l	(1f,pc),a1
	bra	print
1:	.dc.b	' … 解釈できませんので無視します',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-sl
;機能:	68060のstore/load bypass機能を有効にする
;説明:	68060のresult forwarding featuresの1つであるstore/load
;	bypass機能を有効にします。
;	store/load bypass機能はリセット直後は有効ですが、
;	060turbo.sys(v0.54以降)がこれを無効にしています。
;	-slを指定すると、store/load bypass機能が有効になります。
;	store/load bypass機能を無効にすることによる速度低下はほ
;	とんどありません。
param_sl:
	cmpi.b	#6,$0CBC.w
	bne	10f
	movec.l	pcr,d0
	bclr.l	#5,d0			;enable store/load bypass
	movec.l	d0,pcr
10:
	rts

;----------------------------------------------------------------
;文法:	-mm<size>
;	<size>	メインメモリのサイズ（単位は MB）
;機能:	メインメモリのサイズの設定
;説明:	メインメモリのサイズを指定します。
;	メモリが足りなければローカルメモリがあればそこから補い、
;	多すぎたらローカルメモリ側に押し出します。
;	メモリサイズの変更はシェル起動前に行われます。
;	-mm0 とするとデバイスドライバより後ろのメモリをすべて
;	ローカルメモリ側に押し出します（JUPITER の拡張モードと同じ）。
param_mm:
	tst.b	(noTranslation)r
	bne	param_mm_notrans	;-ntが指定されている
	bsr	stou
	bmi	param_mm_illegal
	cmp.l	#12,d0
	bhi	param_mm_illegal
	swap.w	d0
	lsl.l	#4,d0
	move.l	d0,(mainMemorySize)r
	rts

param_mm_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt と -mm は同時に指定できません．-mm は無効です',13,10,0
	.even

param_mm_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-mm の指定値が異常です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-ts<size>
;	<size>	アドレス変換のための領域のサイズ（単位は KB）
;機能:	アドレス変換のための領域のサイズの設定
;説明:	アドレス変換のための領域のサイズを指定します。
;	ページサイズが 8KB のとき、ローカルメモリの容量に応じた
;	最低サイズとデフォルトサイズは以下の通りです。
;					最低	デフォルト
;		本体16MBのみ		10KB	32KB
;		本体16MB+ローカル16MB	19KB	48KB
;		本体16MB+ローカル32MB	27KB	64KB
;		本体16MB+ローカル64MB	44KB	96KB
;		本体16MB+ローカル128MB	78KB	160KB
;		本体16MB+ローカル256MB	146KB	320KB
;		本体16MB+ローカル384MB	214KB	480KB
;		本体16MB+ローカル512MB	282KB	640KB
;		本体16MB+ローカル768MB	418KB	960KB
;	4MB 以上は指定できません。
param_ts:
	cmpi.b	#3,$0CBC.w
	beq	param_ts_68030		;68030では指定できない
	tst.b	(noTranslation)r
	bne	param_ts_notrans	;-ntが指定されている
	bsr	stou
	bmi	param_ts_illegal	;数字がない
	cmp.l	#4096,d0
	bhi	param_ts_toobig		;大きすぎる
	move.l	(localMemorySize)r,d1
	bne	@f
;本体16MBのみ
	cmp.w	#MINIMUM_DESC_SIZE_0>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#16<<20,d1
	bhi	@f
;本体16MB+ローカル16MB
	cmp.w	#MINIMUM_DESC_SIZE_16>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#32<<20,d1
	bhi	@f
;本体16MB+ローカル32MB
	cmp.w	#MINIMUM_DESC_SIZE_32>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#64<<20,d1
	bhi	@f
;本体16MB+ローカル64MB
	cmp.w	#MINIMUM_DESC_SIZE_64>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#128<<20,d1
	bhi	@f
;本体16MB+ローカル128MB
	cmp.w	#MINIMUM_DESC_SIZE_128>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#256<<20,d1
	bhi	@f
;本体16MB+ローカル256MB
	cmp.w	#MINIMUM_DESC_SIZE_256>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#384<<20,d1
	bhi	@f
;本体16MB+ローカル384MB
	cmp.w	#MINIMUM_DESC_SIZE_384>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:	cmp.l	#512<<20,d1
	bhi	@f
;本体16MB+ローカル512MB
	cmp.w	#MINIMUM_DESC_SIZE_512>>10,d0
	blo	param_ts_toosmall	;小さすぎる
	bra	9f

@@:
;本体16MB+ローカル768MB
	cmp.w	#MINIMUM_DESC_SIZE_768>>10,d0
	blo	param_ts_toosmall	;小さすぎる

9:	lsl.l	#8,d0
	lsl.l	#2,d0
	move.l	d0,(descAreaSize)r
	rts

param_ts_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts は 68030 では指定できません．-ts は無効です',13,10,0
	.even

param_ts_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt と -ts は同時に指定できません．-ts は無効です',13,10,0
	.even

param_ts_toosmall:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts の指定値が小さすぎます。デフォルトを使用します',13,10,0
	.even

param_ts_toobig:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts の指定値が大きすぎます。デフォルトを使用します',13,10,0
	.even

param_ts_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts の指定値が異常です。デフォルトを使用します',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-lr
;説明:	ローカルメモリがあるとき、ROM をローカルメモリにコピーし
;	て使います。
param_lr:
	tst.b	(localRomArea)r
	bne	99f			;-lrは既に指定された
	tst.b	(forceNoSimm)r
	bne	param_lr_nosimm		;-lzが指定されている
	cmpi.b	#3,$0CBC.w
	beq	param_lr_68030		;68030では指定できない
	tst.b	(noTranslation)r
	bne	param_lr_notrans	;-ntが指定されている
	tst.l	(localMemorySize)r
	beq	param_lr_cannot		;ローカルメモリがない
	move.l	(localUpperStart)r,d0
	sub.l	#1024*1024,d0
	cmp.l	(localLowerEnd)r,d0
	blo	param_lr_over
	move.l	d0,(localUpperStart)r
	move.l	d0,(localRomStart)r
	add.l	#1024*1024,d0
	move.l	d0,(localRomEnd)r
	st.b	(localRomArea)r
99:	rts

param_lr_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz と -lr は同時に指定できません．-lr は無効です',13,10,0
	.even

param_lr_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lr は 68030 では指定できません．-lr は無効です',13,10,0
	.even

param_lr_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt と -lr は同時に指定できません．-lr は無効です',13,10,0
	.even

param_lr_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリが不足しています．-lr は無効です',13,10,0
	.even

param_lr_cannot:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリがありません．-lr は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-lt
;説明:	ローカルメモリがあるとき、アドレス変換テーブルをローカル
;	メモリに置きます。
param_lt:
	tst.b	(forceNoSimm)r
	bne	param_lt_nosimm		;-lzが指定されている
	cmpi.b	#3,$0CBC.w
	beq	param_lt_68030		;68030では指定できない
	tst.b	(noTranslation)r
	bne	param_lt_notrans	;-ntが指定されている
	tst.l	(localMemorySize)r
	beq	9f
	st.b	(localAreaDescriptor)r
	rts

param_lt_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz と -lt は同時に指定できません．-lt は無効です',13,10,0
	.even

param_lt_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lt は 68030 では指定できません．-lt は無効です',13,10,0
	.even

param_lt_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt と -lt は同時に指定できません．-lt は無効です',13,10,0
	.even

9:	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリがありません．-lt は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-ss
;機能:	SCSI のアクセスでソフト転送を使う
;説明:	IOCS $F5 による SCSI のアクセスでローカルメモリとのやりと
;	りを可能にします。
;	指定されたバッファの論理アドレスが物理アドレスと異なって
;	いたり、実体がローカルメモリにあるとき、一時的にソフト転
;	送に切り替えます。
param_ss:
	st.b	(patchIocsScsi)r
	rts

;----------------------------------------------------------------
;文法:	-dv
;機能:	デバイスドライバのアクセスでテンポラリバッファを使う
;説明:	デバイスドライバのアクセスでローカルメモリとのやりとりを
;	可能にします。
;	指定されたバッファの論理アドレスが物理アドレスと異なって
;	いたり、実体がローカルメモリにあるとき、テンポラリバッフ
;	ァを媒介してデータをやりとりします。
param_dv:
	st.b	(patchDevice)r
	rts

;----------------------------------------------------------------
;文法:	-bs<size>
;	<size>	テンポラリバッファのサイズ（単位は KB）
;説明:	-dv 指定時に使用するテンポラリバッファのサイズを指定しま
;	す。デフォルトは 64KB です。
;	テンポラリバッファは常にメインメモリ上に確保されます。
param_bs:
	tst.l	(tempBufferSize)r
	bne	param_bs_already
	bsr	stou
	bmi	param_bs_illegal
	lsl.l	#8,d0
	lsl.l	#2,d0
	add.l	#$00001FFF,d0		;転送バッファはページ位置に合わせる
	and.l	#$FFFFE000,d0
	move.l	d0,(tempBufferSize)r
	move.l	(mainLowerEnd)r,d1
	add.l	#$00001FFF,d1		;転送バッファはページ位置に合わせる
	and.l	#$FFFFE000,d1
	move.l	d1,(tempBufferStart)r
	add.l	d0,d1
	move.l	d1,(tempBufferEnd)r
	move.l	d1,d0
	add.l	#128*1024,d0
	cmp.l	(mainUpperStart)r,d0
	bhi	param_bs_over
	move.l	d1,(mainLowerEnd)r
	rts

param_bs_already:
	lea.l	(@f,pc),a1
	bra	9f
@@:	.dc.b	'-bs は二重指定です',13,10,0
	.even

param_bs_illegal:
	lea.l	(@f,pc),a1
	bra	9f
@@:	.dc.b	'-bs の指定が異常です',13,10,0
	.even

param_bs_over:
	lea.l	(@f,pc),a1
9:	bsr	print
	clr.l	(tempBufferSize)r
	rts
@@:	.dc.b	'-bs の指定が大きすぎます．デフォルトを使用します',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-xm
;機能:	拡張モードの設定
;説明:	拡張モードにしてからシェルを起動します。
;	Human のメモリ管理をローカルメモリまで拡張します。
;	メモリ管理関係の DOS コールを拡張します。
;	XC のライブラリを使用しているプログラムをロードしたとき、
;	自動的にパッチをあてます。
param_xm:
	tst.b	(forceNoSimm)r
	bne	param_xm_nosimm		;-lzが指定されている
	tst.l	(localMemorySize)r
	beq	9f
	st.b	(useJointMode)r
	st.b	(jointMode)r
	rts

param_xm_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz と -xm は同時に指定できません．-xm は無効です',13,10,0
	.even

9:	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリがありません．-xm は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-hi
;	v0.53より完全に廃止
param_hi:
	rts

;----------------------------------------------------------------
;文法:	-md<size>{[K]|M}[a][i]
;	<size>	RAMDISK のサイズ
;	K	サイズの単位は KB
;	M	サイズの単位は MB
;	a	TIMER-LED をアクセスランプにする
;	i	SHIFT キーが押されていないとき初期化する
;機能:	メインメモリ上の RAMDISK の設定
;説明:	RAMDISK ドライバを組み込みます。RAMDISK の領域はメインメ
;	モリの上位側から確保されます。
;	<size> の範囲は 16KB から 32767KB までです。ただし、メイ
;	ンメモリの容量によって制限されます。
;	i を指定しなければ SHIFT キーが押されているとき初期化し
;	ます。ただし、RAMDISK の先頭が壊れているときは無条件に初
;	期化します。
;	-ld と -md は合わせて 16 個まで指定できます。
;	RAMDISK の領域はスーパーバイザプロテクトされます。また、
;	キャッシュモードをノンキャッシャブル・インプリサイズドシ
;	リアライゼーションにすることで、キャッシュを無駄遣いしな
;	いようにします。
;例:	-md512Ka
;		メインメモリ上に 512KB の RAMDISK を確保します。
;		TIMER-LED をアクセスランプにします。
;		SHIFT キーが押されているとき初期化します。
;<a0.l:'md'の次のアドレス
param_md:
	moveq.l	#0,d0
	move.b	(unitCounter)r,d0
	cmp.b	#MAXIMUM_UNIT,d0
	beq	param_md_toomany	;ユニット数が多すぎる
	lea.l	(bpbTablePointer)r,a1
1:	movea.l	(a1)+,a3
	dbra	d0,1b
;<a3.l:BPBテーブル
	moveq.l	#0,d2
	cmpi.b	#'-',(a0)
	bne	@f
	moveq.l	#1,d2
	addq.l	#1,a0
@@:	bsr	stou
	bmi	param_md_illegal
	move.l	d0,d1
	moveq.l	#$20,d0
	or.b	(a0),d0
	cmp.b	#'k',d0
	beq	1f
	cmp.b	#'m',d0
	bne	2f
	lsl.l	#8,d1
	lsl.l	#2,d1
1:	addq.l	#1,a0
2:	tst.l	d2
	beq	@f
	move.l	(mainUpperStart)r,d0
	sub.l	(mainLowerEnd)r,d0
	lsr.l	#8,d0
	lsr.l	#2,d0
	sub.l	d1,d0
	move.l	d0,d1
@@:	cmp.l	#MINIMUM_SIZE,d1
	blo	param_md_illegal
	cmp.l	#MAXIMUM_SIZE,d1
	bhi	param_md_illegal
;<d1.l:全領域のセクタ数
	move.l	d1,(12,a3)		;全領域のセクタ数
	move.l	d1,d2
	lsl.l	#8,d2
	lsl.l	#2,d2			;全領域のバイト数
;<d2.l:全領域のバイト数
;メインメモリのRAMDISKは末尾から確保する
	movea.l	(mainRamdiskAreaStart)r,a1
;<a1.l:末尾アドレス+1
	movea.l	a1,a2
	suba.l	d2,a2
;<a2.l:先頭アドレス
	move.l	a2,d0
	sub.l	#128*1024,d0
	cmp.l	(mainLowerEnd)r,d0
	blt	param_md_over
	move.l	a2,(mainRamdiskAreaStart)r
;<a1.l:末尾アドレス+1
;<a2.l:先頭アドレス
	move.l	a2,(16,a3)		;先頭アドレス
	move.l	a1,(20,a3)		;末尾アドレス+1
	moveq.l	#0,d6
1:	move.b	(a0)+,d0
	beq	2f
	or.b	#$20,d0
	cmp.b	#'i',d0
	bne	@f
	or.b	#%00000001,d6
	bra	1b
@@:	cmp.b	#'a',d0
	bne	@f
	or.b	#%00000100,d6
	bra	1b
@@:	bra	param_md_illegal
2:
;<d1.l:全領域のセクタ数
	move.l	d1,d0
	sub.l	#(ROOT_ENTRY+31)>>5,d0
;<d0.l:データ領域のセクタ数の上限
	moveq.l	#1,d3
	moveq.l	#0,d4
	bra	2f
1:	add.l	d3,d3			;1クラスタあたりのセクタ数
	addq.l	#1,d4			;1クラスタあたりのセクタ数のシフトカウント
	lsr.l	#1,d0
2:	cmp.l	#$0000FFF0,d0
	bhi	1b
	addq.l	#2,d0
;<d0.l:データ領域のクラスタ数の上限+2
;<d3.l:1クラスタあたりのセクタ数
;<d4.l:1クラスタあたりのセクタ数のシフトカウント
	move.b	d3,(2,a3)		;1クラスタあたりのセクタ数
	move.l	d0,d3
	add.l	d3,d3
	cmp.l	#$0FF7,d0
	bcc	@f
	lsr.l	#2,d3
	addx.l	d0,d3
@@:	add.l	#$03FF,d3
	lsr.l	#8,d3
	lsr.l	#2,d3
;<d3.l:FAT領域のセクタ数
	move.b	d3,(11,a3)		;1個のFAT領域に使用するセクタ数
	move.l	d1,d5			;全領域のセクタ数
	sub.l	#(ROOT_ENTRY+31)>>5,d5
	sub.l	d3,d5
;<d5.l:データ領域のセクタ数
	lsr.l	d4,d5
	addq.l	#2,d5
;<d5.l:データ領域のクラスタ数+2
	moveq.l	#1,d4
	cmpi.w	#$F9FF,(a2)
	bne	1f			;壊れている
	cmpi.b	#$FF,(2,a2)
	bne	1f			;壊れている
	IOCS	_B_SFTSNS
	and.b	d0,d4			;SHIFTキーの状態
	btst.l	#0,d6
	beq	@f			;初期化指定がない
	eori.b	#1,d4			;SHIFTキーの条件を反転する
@@:	tst.l	d4
	beq	2f			;初期化しない
1:	movea.l	a2,a0			;先頭アドレス
	move.l	d3,d0			;1個のFAT領域に使用するセクタ数
	lsl.l	#10-2,d0		;1個のFAT領域に使用するバイト数/4
	subq.w	#1,d0
@@:	clr.l	(a0)+			;FATを初期化
	dbra	d0,@b
	move.w	#ROOT_ENTRY*32/4-1,d0
@@:	clr.l	(a0)+			;ルートディレクトリを初期化
	dbra	d0,@b
	moveq.l	#$F9,d0
	ror.l	#8,d0
	cmp.l	#$00000FF7,d5
	bcc	@f
	clr.b	d0
@@:	move.l	d0,(a2)			;FATのヘッダをセット
2:
;<d4.l:初期化フラグ(0=初期化しなかった,1=初期化した)
;アクセスランプ
	btst.l	#2,d6
	sne.b	(24,a3)
;メッセージ表示
	lea.l	(param_md_message,pc),a1
	moveq.l	#'A',d0
	add.b	(22,a5),d0		;ドライブ名
	add.b	(unitCounter)r,d0
	move.b	d0,(param_md_drive-param_md_message,a1)
	move.l	a2,d0
	lea.l	(param_md_start-param_md_message,a1),a0
	bsr	hex8			;整数→16進数8桁
	add.l	d2,d0
	subq.l	#1,d0
	lea.l	(param_md_end-param_md_message,a1),a0
	bsr	hex8			;整数→16進数8桁
	bsr	print
	lea.l	(param_md_not_initialized,pc),a1	;'は初期化しません'
	tst.l	d4
	beq	@f
	lea.l	(param_md_initialized,pc),a1	;'を初期化しました'
@@:	bsr	print
;
	addq.b	#1,(unitCounter)r
	rts

param_md_message:
	.dc.b	'ＲＡＭディスク '
param_md_drive:
	.dc.b	'?: $'
param_md_start:
	.dc.b	'xxxxxxxx～$'
param_md_end:
	.dc.b	'xxxxxxxx ',0
param_md_not_initialized:
	.dc.b	'は初期化しません',13,10,0
param_md_initialized:
	.dc.b	'を初期化しました',13,10,0
	.even

param_md_toomany:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-md のユニット数が多すぎます',13,10,0
	.even

param_md_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-md の指定が異常です',13,10,0
	.even

param_md_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-md の指定が大きすぎます',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-ld<size>{[K]|M}[a][i]
;	<size>	RAMDISK のサイズ
;	K	<size> の単位は KB
;	M	<size> の単位は MB
;	a	TIMER-LED をアクセスランプにする
;	i	SHIFT キーが押されていないとき初期化する
;機能:	ローカルメモリ上の RAMDISK の設定
;説明:	RAMDISK ドライバを組み込みます。RAMDISK の領域はローカル
;	メモリの下位側から確保されます。
;	<size> の範囲は 16KB から 1024MB までです。ただし、ロー
;	カルメモリの容量によって制限されます。
;	<size> に - を付けると残すサイズを指定できます。
;	i を指定しなければ SHIFT キーが押されているとき初期化し
;	ます。ただし、RAMDISK の先頭が壊れているときは無条件に初
;	期化します。
;	-ld と -md は合わせて 16 個まで指定できます。
;	RAMDISK の領域はスーパーバイザプロテクトされます。また、
;	キャッシュモードをノンキャッシャブル・インプリサイズドシ
;	リアライゼーションにすることで、キャッシュを無駄遣いしな
;	いようにします。
;例:	-ld16Mai
;		ローカルメモリ上に 16MB の RAMDISK を確保します。
;		TIMER-LED をアクセスランプにします。
;		SHIFT キーが押されていないとき初期化します。
;<a0.l:'ld'の次のアドレス
param_ld:
	tst.b	(forceNoSimm)r
	bne	param_ld_nosimm		;-lzが指定されている
	tst.l	(localMemorySize)r
	beq	param_ld_cannot		;ローカルメモリがない
	moveq.l	#0,d0
	move.b	(unitCounter)r,d0
	cmp.b	#MAXIMUM_UNIT,d0
	beq	param_ld_toomany	;ユニット数が多すぎる
	lea.l	(bpbTablePointer)r,a1
1:	movea.l	(a1)+,a3
	dbra	d0,1b
;<a3.l:BPBテーブル
	moveq.l	#0,d2
	cmpi.b	#'-',(a0)
	bne	@f
	moveq.l	#1,d2
	addq.l	#1,a0
@@:	bsr	stou
	bmi	param_ld_illegal
	move.l	d0,d1
	moveq.l	#$20,d0
	or.b	(a0),d0
	cmp.b	#'k',d0
	beq	1f
	cmp.b	#'m',d0
	bne	2f
	lsl.l	#8,d1
	lsl.l	#2,d1
1:	addq.l	#1,a0
2:	tst.l	d2
	beq	@f
	move.l	(localUpperStart)r,d0
	sub.l	(localRamdiskAreaEnd)r,d0
	lsr.l	#8,d0
	lsr.l	#2,d0
	sub.l	d1,d0			;確保するセクタ数=空きセクタ数-残すセクタ数
	move.l	d0,d1
@@:	cmp.l	#MINIMUM_SIZE,d1
	blo	param_ld_illegal
	cmp.l	#MAXIMUM_SIZE,d1
	bhi	param_ld_illegal
;<d1.l:全領域のセクタ数
	move.l	d1,(12,a3)		;全領域のセクタ数
	move.l	d1,d2
	lsl.l	#8,d2
	lsl.l	#2,d2			;全領域のバイト数
;ハイメモリのRAMDISKは先頭から確保する
;<d2.l:全領域のバイト数
	movea.l	(localRamdiskAreaEnd)r,a2
;<a2.l:先頭アドレス
	lea.l	(a2,d2.l),a1
;<a1.l:末尾アドレス+1
	cmpa.l	(localUpperStart)r,a1
	bhi	param_ld_over		;残り0を許容している。-xmができなくなる
	move.l	a1,(localRamdiskAreaEnd)r
;<a1.l:末尾アドレス+1
;<a2.l:先頭アドレス
	move.l	a2,(16,a3)		;先頭アドレス
	move.l	a1,(20,a3)		;末尾アドレス+1
	moveq.l	#0,d6
1:	move.b	(a0)+,d0
	beq	2f
	or.b	#$20,d0
	cmp.b	#'i',d0
	bne	@f
	or.b	#%00000001,d6
	bra	1b
@@:	cmp.b	#'a',d0
	bne	@f
	or.b	#%00000100,d6
	bra	1b
@@:	bra	param_ld_illegal
2:
;<d1.l:全領域のセクタ数
	move.l	d1,d0
	sub.l	#(ROOT_ENTRY+31)>>5,d0
;<d0.l:データ領域のセクタ数の上限
	moveq.l	#1,d3
	moveq.l	#0,d4
	bra	2f
1:	add.l	d3,d3			;1クラスタあたりのセクタ数
	addq.l	#1,d4			;1クラスタあたりのセクタ数のシフトカウント
	lsr.l	#1,d0
2:	cmp.l	#$0000FFF0,d0
	bhi	1b
	addq.l	#2,d0
;<d0.l:データ領域のクラスタ数の上限+2
;<d3.l:1クラスタあたりのセクタ数
;<d4.l:1クラスタあたりのセクタ数のシフトカウント
	move.b	d3,(2,a3)		;1クラスタあたりのセクタ数
	move.l	d0,d3
	add.l	d3,d3
	cmp.l	#$0FF7,d0
	bcc	@f
	lsr.l	#2,d3
	addx.l	d0,d3
@@:	add.l	#$03FF,d3
	lsr.l	#8,d3
	lsr.l	#2,d3
;<d3.l:FAT領域のセクタ数
	move.b	d3,(11,a3)		;1個のFAT領域に使用するセクタ数
	move.l	d1,d5			;全領域のセクタ数
	sub.l	#(ROOT_ENTRY+31)>>5,d5
	sub.l	d3,d5
;<d5.l:データ領域のセクタ数
	lsr.l	d4,d5
	addq.l	#2,d5
;<d5.l:データ領域のクラスタ数+2
	moveq.l	#1,d4
	cmpi.w	#$F9FF,(a2)
	bne	1f			;壊れている
	cmpi.b	#$FF,(2,a2)
	bne	1f			;壊れている
	IOCS	_B_SFTSNS
	and.b	d0,d4			;SHIFTキーの状態
	btst.l	#0,d6
	beq	@f			;初期化指定がない
	eori.b	#1,d4			;SHIFTキーの条件を反転する
@@:	tst.l	d4
	beq	2f			;初期化しない
1:	movea.l	a2,a0			;先頭アドレス
	move.l	d3,d0			;1個のFAT領域に使用するセクタ数
	lsl.l	#10-2,d0		;1個のFAT領域に使用するバイト数/4
	subq.w	#1,d0
@@:	clr.l	(a0)+			;FATを初期化
	dbra	d0,@b
	move.w	#ROOT_ENTRY*32/4-1,d0
@@:	clr.l	(a0)+			;ルートディレクトリを初期化
	dbra	d0,@b
	moveq.l	#$F9,d0
	ror.l	#8,d0
	cmp.l	#$00000FF7,d5
	bcc	@f
	clr.b	d0
@@:	move.l	d0,(a2)			;FATのヘッダをセット
2:
;<d4.l:初期化フラグ(0=初期化しなかった,1=初期化した)
;アクセスランプ
	btst.l	#2,d6
	sne.b	(24,a3)
;メッセージ表示
	lea.l	(param_ld_message,pc),a1
	moveq.l	#'A',d0
	add.b	(22,a5),d0		;ドライブ名
	add.b	(unitCounter)r,d0
	move.b	d0,(param_ld_drive-param_ld_message,a1)
	move.l	a2,d0
	lea.l	(param_ld_start-param_ld_message,a1),a0
	bsr	hex8			;整数→16進数8桁
	add.l	d2,d0
	subq.l	#1,d0
	lea.l	(param_ld_end-param_ld_message,a1),a0
	bsr	hex8			;整数→16進数8桁
	bsr	print
	lea.l	(param_ld_not_initialized,pc),a1	;'は初期化しません'
	tst.l	d4
	beq	@f
	lea.l	(param_ld_initialized,pc),a1	;'を初期化しました'
@@:	bsr	print
;
	addq.b	#1,(unitCounter)r
	rts

param_ld_message:
	.dc.b	'ＲＡＭディスク '
param_ld_drive:
	.dc.b	'?: $'
param_ld_start:
	.dc.b	'xxxxxxxx～$'
param_ld_end:
	.dc.b	'xxxxxxxx ',0
param_ld_not_initialized:
	.dc.b	'は初期化しません',13,10,0
param_ld_initialized:
	.dc.b	'を初期化しました',13,10,0
	.even

param_ld_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz と -ld は同時に指定できません．-ld は無効です',13,10,0
	.even

param_ld_cannot:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリがありません．-ld は無効です',13,10,0
	.even

param_ld_toomany:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld のユニット数が多すぎます',13,10,0
	.even

param_ld_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld の指定が異常です',13,10,0
	.even

param_ld_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld の指定が大きすぎます',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-cm<mode>
;	<mode>	キャッシュモード
;		0	キャッシュ許可,ライトスルー
;		1	キャッシュ許可,コピーバック
;		2	キャッシュ禁止,ストアバッファ禁止
;		3	キャッシュ禁止,ストアバッファ許可
;説明:	メモリのキャッシュモードを指定します。デフォルトはライト
;	スルーです。
param_cm:
	moveq.l	#0,d0
	move.b	(a0),d0
	sub.b	#'0',d0
	bmi	param_cm_illegal
	cmp.b	#3,d0
	bhi	param_cm_illegal
	move.b	d0,mainMemoryCacheMode
	move.b	d0,localMemoryCacheMode
	lsl.l	#PD_CM_BIT,d0
	andi.l	#.not.PD_CM_MASK,mainPD
	or.l	d0,mainPD
	rts

param_cm_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-cm の指定が異常です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-bg
;説明:	スレッド間の排他制御を行います。
;	-bgを指定すると、スレッドが切り替わる度に、FPUの内部状態
;	と各レジスタ、標準ハンドラ、標準ハンドラの変換状態、各ド
;	ライブのカレントディレクトリ、カレントドライブが切り替わ
;	ります。
;	CONFIG.SYSのFILESの値は最低でも30以上を指定して下さい。
param_bg:
	tst.b	(backgroundFlag)r
	bne	99f			;-bgは既に指定された
	tst.w	$1C58.w			;processのスレッド数-1
	beq	param_bg_no_process	;サブスレッドは使えない
	cmpi.w	#30+2,$1C6E.w		;filesが30以上か
	blo	param_bg_no_files	;filesの指定値が小さすぎる
	movea.l	(mainLowerEnd)r,a1	;排他制御情報の先頭
	move.l	a1,(exclusiveStart)r
	move.w	#xSize2,d0		;排他制御情報1個のサイズ
	mulu.w	$1C58.w,d0		;サブスレッドの排他制御情報のサイズ
	add.l	#$0000000F,d0		;16の倍数に切り上げる
	and.l	#$FFFFFFF0,d0
	adda.l	d0,a1			;排他制御情報の末尾+1
	move.l	(mainUpperStart)r,d0
	sub.l	#128*1024,d0
	cmpa.l	d0,a1
	bhi	param_bg_over
	move.l	a1,(exclusiveEnd)r
	move.l	a1,(mainLowerEnd)r
	st.b	(backgroundFlag)r
99:	rts

param_bg_no_process:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'process が指定されていません．-bg は無効です',13,10,0
	.even

param_bg_no_files:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'files の指定値が小さすぎます．-bg は無効です',13,10,0
	.even

param_bg_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'メモリが不足しています．-bg は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-sd
;説明:	IOCSによるDMA転送をソフト転送にします。
param_sd:
	st.b	(softwareIocsDma)r
	rts

;----------------------------------------------------------------
;文法:	-fe
;説明:	060turbo.sysの内部のFEファンクションを使用することを明示
;	します。後からFLOATn.Xを組み込むことができなくなります。
param_fe:
	cmpi.b	#6,$0CBC.w
	bne	param_fe_not_68060	;68060以外では指定できない
	move.l	#'FEfn',_060_fpsp_fline-4
	rts

param_fe_not_68060:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-fe は 68060 以外では指定できません．-fe は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-ls
;説明:	ベクタ領域からHuman本体の末尾までと060turbo.sys本体をロー
;	カルメモリにコピーして使います。
param_ls:
	tst.b	(localSystemArea)r
	bne	99f			;-lsは既に指定された
	tst.b	(forceNoSimm)r
	bne	param_ls_nosimm		;-lzが指定されている
	cmpi.b	#3,$0CBC.w
	beq	param_ls_68030		;68030では指定できない
	tst.b	(noTranslation)r
	bne	param_ls_notrans	;-ntが指定されている
	tst.l	(localMemorySize)r
	beq	param_ls_cannot
;システムをコピーする領域を確保
	move.l	#keepTail,d1
	and.l	#PAGE_MASK,d1		;変換する部分の末尾なので切り捨てる
	sub.l	#deviceHeader,d1
	and.l	#PAGE_MASK,d1		;060turbo.sysの常駐部分の長さ
	add.l	#$0001447A.and.PAGE_MASK,d1	;Humanの長さ
	move.l	(localUpperStart)r,d0
	sub.l	d1,d0
	cmp.l	(localLowerEnd)r,d0
	blo	param_ls_over
	move.l	d0,(localUpperStart)r
	move.l	d0,(localSystemStart)r
	add.l	d1,d0
	move.l	d0,(localSystemEnd)r
	st.b	(localSystemArea)r
99:	rts

param_ls_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz と -ls は同時に指定できません．-ls は無効です',13,10,0
	.even

param_ls_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ls は 68030 では指定できません．-ls は無効です',13,10,0
	.even

param_ls_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt と -ls は同時に指定できません．-ls は無効です',13,10,0
	.even

param_ls_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリが不足しています．-ls は無効です',13,10,0
	.even

param_ls_cannot:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'ローカルメモリがありません．-ls は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-np
;説明:	初期化以外のデバイス呼び出しでデータキャッシュのプッシュ
;	および無効化を行いません。
;	SCSI転送は強制的にソフト転送になります。
param_np:
	tst.b	(deviceCacheNoPush)r
	bne	99f				;-npは既に指定された
	st.b	(patchIocsScsi)r		;SCSIを強制的にソフト転送にする
	st.b	(forceSoftScsi)r
	st.b	([$1C20.w],pDeviceNoPush)	;Humanは-npを許可する
	st.b	(deviceCacheNoPush)r
99:	rts

;----------------------------------------------------------------
;文法:	-ad
;説明:	ADPCM関係のIOCSコールにパッチをあててローカルメモリから直
;	接再生できるようにします。
param_ad:
	st.b	(patchIocsAdpcm)r
	rts

;----------------------------------------------------------------
;文法:	-lz
;説明:	SIMMが装着されていても使わないことにします。
param_lz:
	tst.b	(forceNoSimm)r
	bne	99f			;-lzは既に指定された
	tst.l	(localMemorySize)r
	beq	99f			;ローカルメモリがない
	tst.l	(localRamdiskAreaSize)r
	bne	param_lz_error
	tst.b	(localAreaDescriptor)r
	bne	param_lz_error
	tst.b	(localRomArea)r
	bne	param_lz_error
	tst.b	(useJointMode)r
	bne	param_lz_error
	tst.b	(jointMode)r
	bne	param_lz_error
	tst.b	(localSystemArea)r
	bne	param_lz_error
	clr.l	(localMemorySize)r
	move.l	(localMemoryStart)r,(localMemoryEnd)r
	clr.l	(localLowerStart)r
	clr.l	(localLowerEnd)r
	clr.l	(localUpperStart)r
	clr.l	(localUpperEnd)r
	clr.l	(localRamdiskAreaStart)r
	clr.l	(localRamdiskAreaEnd)r
	st.b	(forceNoSimm)r
99:	rts

param_lz_error:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld,-lr,-ls,-lt,-xm と -lz は同時に指定できません．-lz は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文法:	-nt
;説明:	アドレス変換を行いません。
;	実機および実機と同じ手順でキャッシュラインを充填しようと
;	するエミュレータでは指定しないでください。
;	-lr,-ls,-lt,-mm,-ts と -nt は同時に指定できません。
param_nt:
	tst.b	(noTranslation)r
	bne	99f			;-ntは既に指定された(68030を含む)
	tst.b	(localRomArea)r
	bne	param_nt_error		;-lrが指定されている
	tst.b	(localSystemArea)r
	bne	param_nt_error		;-lsが指定されている
	tst.b	(localAreaDescriptor)r
	bne	param_nt_error		;-ltが指定されている
	tst.l	(mainMemorySize)r
	bpl	param_nt_error		;-mmが指定されている
	tst.l	(descAreaSize)r
	bne	param_nt_error		;-tsが指定されている
	st.b	(noTranslation)r
99:	rts

param_nt_error:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lr,-ls,-lt,-mm,-ts と -nt は同時に指定できません．-nt は無効です',13,10,0
	.even

;----------------------------------------------------------------
;文字列を符号なし10進数と見なして数値に変換する
;<a0.l:文字列のアドレス
;>d0.l:数値(0～$7FFFFFFF,-1=エラー)
;>a0.l:数字の次のアドレス
;>n-flag:mi=エラー
stou::
	move.l	d1,-(sp)
	moveq.l	#0,d0
	moveq.l	#0,d1
1:	move.b	(a0)+,d1
	sub.b	#'0',d1
	bcs	3f
	cmp.b	#10,d1
	bcc	3f
	mulu.l	#10,d0
	bvs	2f
	bmi	2f
	add.l	d1,d0
	bcs	2f
	bpl	1b
2:	moveq.l	#-1,d0
3:	subq.l	#1,a0
	move.l	(sp)+,d1
	tst.l	d0
	rts

;----------------------------------------------------------------
;文字列表示
print::
	move.l	d0,-(sp)
	move.l	a1,-(sp)
	DOS	_PRINT
	addq.l	#4,sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;整数→16進数8桁
hex8::
	movem.l	d1-d2,-(sp)
	moveq.l	#8-1,d2
1:	rol.l	#4,d0
	moveq.l	#$0F,d1
	and.b	d0,d1
	move.b	(2f,pc,d1.w),(a0)+
	dbra	d2,1b
	movem.l	(sp)+,d1-d2
	rts
2:	.dc.b	'0123456789ABCDEF'

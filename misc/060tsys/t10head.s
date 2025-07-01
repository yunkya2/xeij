	.include	t00iocs.equ
	.include	t01dos.equ
	.include	t02const.equ

	.cpu	68060

;----------------------------------------------------------------
;デバイスヘッダ
deviceHeader::
	.dc.l	-1
	.dc.w	$0000
	.dc.l	strategyRoutine
	.dc.l	interruptRoutine
	.dc.b	1,'RAMDISK'

requestHeader:
	.ds.l	1

deviceJumpTable::
	.dc.l	deviceInitialize	;初期化
	.dc.l	deviceCheck		;メディアチェック
	.dc.l	noError
	.dc.l	commandError
	.dc.l	deviceInput		;入力
	.dc.l	deviceSense		;状態取得
	.dc.l	noError
	.dc.l	noError
	.dc.l	deviceOutput		;出力
	.dc.l	deviceOutput		;出力
	.dc.l	noError
	.dc.l	noError
	.dc.l	commandError

;ストラテジルーチン
strategyRoutine:
	move.l	a5,requestHeader
	rts

;インタラプトルーチン
interruptRoutine:
	move.l	a5,-(sp)
	move.l	d0,-(sp)
	movea.l	requestHeader,a5
	moveq.l	#0,d0
	move.b	(2,a5),d0		;コマンドコード
	lsl.l	#2,d0
	pea.l	(@f,pc)
	move.l	(deviceJumpTable,pc,d0.l),-(sp)
	rts				;コマンドの処理を呼ぶ
@@:	move.b	d0,(3,a5)		;エラーコード(下位)
	lsr.w	#8,d0
	move.b	d0,(4,a5)		;エラーコード(上位)
	move.l	(sp)+,d0
	movea.l	(sp)+,a5
	rts

noError:
	moveq.l	#0,d0
	rts

commandError:
	move.w	#$5003,d0
	rts

;----------------------------------------------------------------
;ベクタテーブル
	.align	4,$2048
vectorTable::
vectorInfoAccessError::	.dc.l	ACCESS_ERROR
vectorOldAccessError::	.dc.l	0
vectorAccessError::	.dc.l	accessError

vectorInfoPRIVILEGE::	.dc.l	PRIVILEGE
vectorOldPRIVILEGE::	.dc.l	0
vectorPRIVILEGE::	.dc.l	_060_fpsp_fline		;privilegeViolation

vectorInfoFLINE::	.dc.l	FLINE
vectorOldFLINE::	.dc.l	0
vectorFLINE::		.dc.l	_060_fpsp_fline

vectorInfoBSUN::	.dc.l	BSUN
vectorOldBSUN::		.dc.l	0
vectorBSUN::		.dc.l	_060_real_bsun

vectorInfoINEX::	.dc.l	INEX
vectorOldINEX::		.dc.l	0
vectorINEX::		.dc.l	_fpsp_inex
				;_060FPSP_TABLE+$000019D4
				;_060FPSP_TABLE+$28
				;$80000000+_060FPSP_TABLE+$28+2

vectorInfoDZ::		.dc.l	DZ
vectorOldDZ::		.dc.l	0
vectorDZ::		.dc.l	_fpsp_dz
				;_060FPSP_TABLE+$00001B32
				;_060FPSP_TABLE+$20
				;$80000000+_060FPSP_TABLE+$20+2

vectorInfoUNFL::	.dc.l	UNFL
vectorOldUNFL::		.dc.l	0
vectorUNFL::		.dc.l	_fpsp_unfl
				;_060FPSP_TABLE+$0000048A
				;_060FPSP_TABLE+$18
				;$80000000+_060FPSP_TABLE+$18+2

vectorInfoOPERR::	.dc.l	OPERR
vectorOldOPERR::	.dc.l	0
vectorOPERR::		.dc.l	_fpsp_operr
				;_060FPSP_TABLE+$000015FE
				;_060FPSP_TABLE+$08
				;$80000000+_060FPSP_TABLE+$08+2

vectorInfoOVFL::	.dc.l	OVFL
vectorOldOVFL::		.dc.l	0
vectorOVFL::		.dc.l	_fpsp_ovfl
				;_060FPSP_TABLE+$000002C8
				;_060FPSP_TABLE+$10
				;$80000000+_060FPSP_TABLE+$10+2

vectorInfoSNAN::	.dc.l	SNAN
vectorOldSNAN::		.dc.l	0
vectorSNAN::		.dc.l	_fpsp_snan
				;_060FPSP_TABLE+$00001742
				;_060FPSP_TABLE+$00
				;$80000000+_060FPSP_TABLE+$00+2

vectorInfoUNSUPP::	.dc.l	UNSUPP
vectorOldUNSUPP::	.dc.l	0
vectorUNSUPP::		.dc.l	_fpsp_unsupp
				;_060FPSP_TABLE+$00000668
				;_060FPSP_TABLE+$38
				;$80000000+_060FPSP_TABLE+$38+2

vectorInfoEFFADD::	.dc.l	EFFADD
vectorOldEFFADD::	.dc.l	0
vectorEFFADD::		.dc.l	_fpsp_effadd
				;_060FPSP_TABLE+$0000106E
				;_060FPSP_TABLE+$40
				;$80000000+_060FPSP_TABLE+$40+2

vectorInfoUNINT::	.dc.l	UNINT
vectorOldUNINT::	.dc.l	0
vectorUNINT::		.dc.l	_060_isp_unint

vectorInfoIocsAdpcmout::	.dc.l	$0400+_ADPCMOUT*4
vectorOldIocsAdpcmout::	.dc.l	0
vectorIocsAdpcmout::	.dc.l	iocsAdpcmout

vectorInfoIocsAdpcminp::	.dc.l	$0400+_ADPCMINP*4
vectorOldIocsAdpcminp::	.dc.l	0
vectorIocsAdpcminp::	.dc.l	iocsAdpcminp

vectorInfoIocsAdpcmaot::	.dc.l	$0400+_ADPCMAOT*4
vectorOldIocsAdpcmaot::	.dc.l	0
vectorIocsAdpcmaot::	.dc.l	iocsAdpcmaot

vectorInfoIocsAdpcmain::	.dc.l	$0400+_ADPCMAIN*4
vectorOldIocsAdpcmain::	.dc.l	0
vectorIocsAdpcmain::	.dc.l	iocsAdpcmain

vectorInfoIocsAdpcmlot::	.dc.l	$0400+_ADPCMLOT*4
vectorOldIocsAdpcmlot::	.dc.l	0
vectorIocsAdpcmlot::	.dc.l	iocsAdpcmlot

vectorInfoIocsAdpcmlin::	.dc.l	$0400+_ADPCMLIN*4
vectorOldIocsAdpcmlin::	.dc.l	0
vectorIocsAdpcmlin::	.dc.l	iocsAdpcmlin

vectorInfoIocsAdpcmsns::	.dc.l	$0400+_ADPCMSNS*4
vectorOldIocsAdpcmsns::	.dc.l	0
vectorIocsAdpcmsns::	.dc.l	iocsAdpcmsns

vectorInfoIocsAdpcmmod::	.dc.l	$0400+_ADPCMMOD*4
vectorOldIocsAdpcmmod::	.dc.l	0
vectorIocsAdpcmmod::	.dc.l	iocsAdpcmmod

vectorInfoIocsDmamove::	.dc.l	$0400+_DMAMOVE*4
vectorOldIocsDmamove::	.dc.l	0
vectorIocsDmamove::	.dc.l	iocsDmamove

vectorInfoIocsDmamovA::	.dc.l	$0400+_DMAMOV_A*4
vectorOldIocsDmamovA::	.dc.l	0
vectorIocsDmamovA::	.dc.l	iocsDmamovA

vectorInfoIocsDmamovL::	.dc.l	$0400+_DMAMOV_L*4
vectorOldIocsDmamovL::	.dc.l	0
vectorIocsDmamovL::	.dc.l	iocsDmamovL

vectorInfoIocsDmamode::	.dc.l	$0400+_DMAMODE*4
vectorOldIocsDmamode::	.dc.l	0
vectorIocsDmamode::	.dc.l	iocsDmamode

vectorInfoIocsSysStat::	.dc.l	$0400+_SYS_STAT*4
vectorOldIocsSysStat::	.dc.l	0
vectorIocsSysStat::	.dc.l	iocsSysStat

vectorInfoIocsScsidrv::	.dc.l	$0400+_SCSIDRV*4
vectorOldIocsScsidrv::	.dc.l	0
vectorIocsScsidrv::	.dc.l	iocsScsidrv

vectorInfoIocsPrnintst::	.dc.l	$0400+_PRNINTST*4
vectorOldIocsPrnintst::	.dc.l	0
vectorIocsPrnintst::	.dc.l	iocsPrnintst

vectorInfoPrnint::	.dc.l	PRNINT
vectorOldPrnint::	.dc.l	0
vectorPrnint::		.dc.l	((PRNINT>>2)<<24)+defaultPrnint

vectorInfoIocsHimem::	.dc.l	$0400+_HIMEM*4
vectorOldIocsHimem::	.dc.l	0
vectorIocsHimem::	.dc.l	iocsHimem

vectorInfoDosExit::	.dc.l	$1800+(_EXIT-$FF00)*4
vectorOldDosExit::	.dc.l	0
vectorDosExit::		.dc.l	dosExit

vectorInfoDosKeeppr::	.dc.l	$1800+(_KEEPPR-$FF00)*4
vectorOldDosKeeppr::	.dc.l	0
vectorDosKeeppr::	.dc.l	dosKeeppr

vectorInfoDosMalloc::	.dc.l	$1800+(_MALLOC-$FF00)*4
vectorOldDosMalloc::	.dc.l	0
vectorDosMalloc::	.dc.l	dosMalloc

vectorInfoDosMfree::	.dc.l	$1800+(_MFREE-$FF00)*4
vectorOldDosMfree::	.dc.l	0
vectorDosMfree::	.dc.l	dosMfree

vectorInfoDosSetblock::	.dc.l	$1800+(_SETBLOCK-$FF00)*4
vectorOldDosSetblock::	.dc.l	0
vectorDosSetblock::	.dc.l	dosSetblock

vectorInfoDosExec::	.dc.l	$1800+(_EXEC-$FF00)*4
vectorOldDosExec::	.dc.l	0
vectorDosExec::		.dc.l	dosExec

vectorInfoDosExit2::	.dc.l	$1800+(_EXIT2-$FF00)*4
vectorOldDosExit2::	.dc.l	0
vectorDosExit2::	.dc.l	dosExit2

vectorInfoDos0Malloc2::	.dc.l	$1800+(~0~_MALLOC2-$FF00)*4
vectorOldDos0Malloc2::	.dc.l	0
vectorDos0Malloc2::	.dc.l	dosMalloc2

vectorInfoDos0Malloc3::	.dc.l	$1800+(~0~_MALLOC3-$FF00)*4
vectorOldDos0Malloc3::	.dc.l	0
vectorDos0Malloc3::	.dc.l	dosMalloc3

vectorInfoDos0Setblock2::	.dc.l	$1800+(~0~_SETBLOCK2-$FF00)*4
vectorOldDos0Setblock2::	.dc.l	0
vectorDos0SetBlock2::	.dc.l	dosSetblock2

vectorInfoDos0Malloc4::	.dc.l	$1800+(~0~_MALLOC4-$FF00)*4
vectorOldDos0Malloc4::	.dc.l	0
vectorDos0Malloc4::	.dc.l	dosMalloc4

vectorInfoDos0SMalloc2::	.dc.l	$1800+(~0~_S_MALLOC2-$FF00)*4
vectorOldDos0SMalloc2::	.dc.l	0
vectorDos0SMalloc2::	.dc.l	dosSMalloc2

vectorInfoDos0SMalloc::	.dc.l	$1800+(~0~_S_MALLOC-$FF00)*4
vectorOldDos0SMalloc::	.dc.l	0
vectorDos0SMalloc::	.dc.l	dosSMalloc

vectorInfoDos0SMfree::	.dc.l	$1800+(~0~_S_MFREE-$FF00)*4
vectorOldDos0SMfree::	.dc.l	0
vectorDos0SMfree::	.dc.l	dosSMfree

vectorInfoDos0SProcess::	.dc.l	$1800+(~0~_S_PROCESS-$FF00)*4
vectorOldDos0SProcess::	.dc.l	0
vectorDos0SProcess::	.dc.l	dosSProcess

vectorInfoDosMalloc2::	.dc.l	$1800+(_MALLOC2-$FF00)*4
vectorOldDosMalloc2::	.dc.l	0
vectorDosMalloc2::	.dc.l	dosMalloc2

vectorInfoDosMalloc3::	.dc.l	$1800+(_MALLOC3-$FF00)*4
vectorOldDosMalloc3::	.dc.l	0
vectorDosMalloc3::	.dc.l	dosMalloc3

vectorInfoDosSetblock2::	.dc.l	$1800+(_SETBLOCK2-$FF00)*4
vectorOldDosSetblock2::	.dc.l	0
vectorDosSetBlock2::	.dc.l	dosSetblock2

vectorInfoDosMalloc4::	.dc.l	$1800+(_MALLOC4-$FF00)*4
vectorOldDosMalloc4::	.dc.l	0
vectorDosMalloc4::	.dc.l	dosMalloc4

vectorInfoDosSMalloc2::	.dc.l	$1800+(_S_MALLOC2-$FF00)*4
vectorOldDosSMalloc2::	.dc.l	0
vectorDosSMalloc2::	.dc.l	dosSMalloc2

vectorInfoDosSMalloc::	.dc.l	$1800+(_S_MALLOC-$FF00)*4
vectorOldDosSMalloc::	.dc.l	0
vectorDosSMalloc::	.dc.l	dosSMalloc

vectorInfoDosSMfree::	.dc.l	$1800+(_S_MFREE-$FF00)*4
vectorOldDosSMfree::	.dc.l	0
vectorDosSMfree::	.dc.l	dosSMfree

vectorInfoDosSProcess::	.dc.l	$1800+(_S_PROCESS-$FF00)*4
vectorOldDosSProcess::	.dc.l	0
vectorDosSProcess::	.dc.l	dosSProcess

vectorInfoDosOpenPr::	.dc.l	$1800+(_OPEN_PR-$FF00)*4
vectorOldDosOpenPr::	.dc.l	0
vectorDosOpenPr::	.dc.l	dosOpenPr

vectorInfoDosKillPr::	.dc.l	$1800+(_KILL_PR-$FF00)*4
vectorOldDosKillPr::	.dc.l	0
vectorDosKillPr::	.dc.l	dosKillPr

vectorInfoDosChangePr::	.dc.l	$1800+(_CHANGE_PR-$FF00)*4
vectorOldDosChangePr::	.dc.l	0
vectorDosChangePr::	.dc.l	dosChangePr

vectorInfoHumanTrap10::	.dc.l	$1C6A
vectorOldHumanTrap10::	.dc.l	0
vectorHumanTrap10::	.dc.l	humanTrap10

			.dc.l	0


;----------------------------------------------------------------
;
;	管理領域の範囲
;
;----------------------------------------------------------------
	.align	4,$2048
mainLowerStart::
	.dc.l	0
mainLowerEnd::
	.dc.l	0
mainUpperStart::
	.dc.l	0
mainUpperEnd::
	.dc.l	0
localLowerStart::
	.dc.l	0
localLowerEnd::
	.dc.l	0
localUpperStart::
	.dc.l	0
localUpperEnd::
	.dc.l	0

;----------------------------------------------------------------
;
;	バスエラーチェックルーチンのワーク
;
;----------------------------------------------------------------
	.align	4,$2048
dosBusErrVbr::
	.dc.l	0			;バスエラーチェック用の仮のベクタテーブルのアドレス
dosBusErrSsp::
	.dc.l	0			;バスエラーチェック用の仮のスーパーバイザスタック

;----------------------------------------------------------------
;
;	各種フラグ,カウンタ
;
;----------------------------------------------------------------
localRomArea::
	.dc.b	0			;-1=ROMをローカルメモリにコピーして使う
localSystemArea::
	.dc.b	0			;-1=ベクタからHumanまでとドライバ本体を,
					;ローカルメモリにコピーして使う
localAreaDescriptor::
	.dc.b	0			;-1=デスクリプタの領域をローカルメモリに配置する
patchIocsScsi::
	.dc.b	0			;-1=_SCSIDRVにパッチをあてる
forceSoftScsi::
	.dc.b	0			;-1=SCSIを強制的にソフト転送にする
patchDevice::
	.dc.b	0			;-1=デバイスドライバのアクセスにパッチをあてる
deviceCacheNoPush::
	.dc.b	0			;-1=初期化以外のデバイス呼び出しでキャッシュプッシュしない
useIocsHimem::
	.dc.b	-1			;-1=_HIMEMを使う
unitCounter::
	.dc.b	0			;RAMDISKのユニット数
useExtendedMode::
	.dc.b	0			;-1=拡張モードを使う
extendedMode::
	.dc.b	0			;-1=現在拡張モードになっている
useJointMode::
	.dc.b	0			;-1=結合モードを使う
jointMode::
	.dc.b	0			;-1=現在結合モードになっている
mainMemoryCacheMode::
	.dc.b	0			;メインメモリのキャッシュモード
localMemoryCacheMode::
	.dc.b	0			;ローカルメモリのキャッシュモード
softwareIocsDma::
	.dc.b	0			;-1=IOCSによるDMA転送をソフト転送にする
patchIocsAdpcm::
	.dc.b	0			;-1=ADPCM関係のIOCSコールにパッチをあてる
forceNoSimm::
	.dc.b	0			;-1=SIMMが装着されていても使わないことにする
noTranslation::
	.dc.b	0			;-1=アドレス変換を行わない

	.even
scsiRevisionCode::
	.dc.w	0			;SCSI _S_REVISIONの結果
					;$000A以上はSRAMのソフト転送フラグに対応している

;----------------------------------------------------------------
;
;	ローカルメモリ上に置くROM領域
;
;----------------------------------------------------------------
	.align	4,$2048
localRomStart::
	.dc.l	0
localRomEnd::
	.dc.l	0

;----------------------------------------------------------------
;
;	ローカルメモリ上に置くシステム領域
;
;----------------------------------------------------------------
	.align	4,$2048
localSystemStart::
	.dc.l	0
localSystemEnd::
	.dc.l	0

;----------------------------------------------------------------
;
;	デスクリプタの領域
;
;----------------------------------------------------------------
	.align	4,$2048
;ページインデックスフィールドのビット数に応じて変化する値
pageIndexWidth::			;ページインデックスフィールドのビット数(5～6)
	.dc.l	PAGE_INDEX_WIDTH	;	5
pageIndexSize::				;ページテーブル1個に含まれるページデスクリプタの個数
	.dc.l	PAGE_INDEX_SIZE		;	32
pageIndexMask::				;ページインデックスフィールドのマスク
	.dc.l	PAGE_INDEX_MASK		;	31

pageOffsetWidth::			;ページ内オフセットのビット数(12～13)
	.dc.l	PAGE_OFFSET_WIDTH	;	13=8KB/page
pageOffsetSize::			;1ページのサイズ
	.dc.l	PAGE_OFFSET_SIZE	;	$00002000=8KB/page
pageOffsetMask::			;ページ内オフセットのマスク
	.dc.l	PAGE_OFFSET_MASK	;	$00001FFF

pageMask::				;ページの先頭アドレスのマスク
	.dc.l	PAGE_MASK		;	$3FFFE000

pageDescSize::				;ページテーブル1個のサイズ
	.dc.l	PAGE_DESC_SIZE		;	$00000080
pageDescMask::				;ページテーブルの先頭のアドレスのマスク
	.dc.l	PAGE_DESC_MASK		;	$3FFFFF80

;デスクリプタの領域は常にmovesでアクセスされるので普段は見えなくてよい
descAreaStart::
	.dc.l	0			;デスクリプタの領域の先頭(ページの先頭)
descAreaEnd::
	.dc.l	0			;デスクリプタの領域の末尾+1(ページの末尾+1)
descAreaSize::
	.dc.l	0			;デスクリプタの領域のサイズ(ページサイズの倍数とは限らない)

;デスクリプタの領域
descHead::				;ルートデスクリプタの先頭
rootDescHead::				;デスクリプタの領域の先頭
	.dc.l	0
rootDescTail::				;ルートデスクリプタの末尾
pointerDescHead::			;ポインタデスクリプタの先頭
	.dc.l	0
pointerDescTail::			;ポインタデスクリプタの末尾（使用している部分の末尾,可変）
	.dc.l	0
pageDescHead::				;ページデスクリプタの先頭（使用している部分の先頭,可変）
	.dc.l	0
pageDescTail::				;ページデスクリプタの末尾
pointerCounterHead::			;ポインタデスクリプタテーブルの参照数カウンタテーブルの先頭
	.dc.l	0
pageCounterTail::			;ページデスクリプタテーブルの参照数カウンタテーブルの末尾
descTail::				;デスクリプタの領域の末尾
	.dc.l	0

;----------------------------------------------------------------
;
;	デバイスドライバの転送バッファ
;
;----------------------------------------------------------------
	.align	4,$2048
tempBufferStart::
	.dc.l	0			;転送バッファの先頭
tempBufferEnd::
	.dc.l	0			;転送バッファの末尾+1
tempBufferSize::
	.dc.l	0			;転送バッファのバイト数(1024の倍数)


;----------------------------------------------------------------
;
;	ADPCM関係のワーク
;
;----------------------------------------------------------------
	.align	4,$2048
adpcmBufferStart::
	.dc.l	0			;ADPCM転送バッファの先頭
adpcmBufferEnd::
	.dc.l	0			;ADPCM転送バッファの末尾
adpcmBufferSize::
	.dc.l	ADPCM_SPLIT_SIZE	;分割サイズ
adpcmLeftSize::
	.dc.l	0			;まだバッファにコピーしていないサイズ
adpcmDataPtr::
	.dc.l	0			;まだバッファにコピーしていないデータ
adpcmBufferPtr0::
	.dc.l	0			;バッファ0へのポインタ
adpcmBufferPtr1::
	.dc.l	0			;バッファ1へのポインタ

;----------------------------------------------------------------
;
;	ローカルメモリ
;
;----------------------------------------------------------------
	.align	4,$2048
localMemoryStart::
	.dc.l	0			;ローカルメモリの先頭
localMemoryEnd::
	.dc.l	0			;ローカルメモリの末尾+1
localMemorySize::
	.dc.l	0			;ローカルメモリのサイズ(0=存在しない)

himemAreaStart::
	.dc.l	0			;_HIMEMでアクセスする範囲の先頭
himemAreaEnd::
	.dc.l	0			;_HIMEMでアクセスする範囲の末尾+1
himemAreaSize::
	.dc.l	0			;_HIMEMでアクセスする範囲のサイズ

;----------------------------------------------------------------
;
;	拡張モード
;
;----------------------------------------------------------------
	.align	4,$2048
mainMemorySize::
	.dc.l	-1			;メインメモリのサイズ

;----------------------------------------------------------------
;
;	結合モード
;
;----------------------------------------------------------------
	.align	4,$2048
jointBlockHeader::
	.dc.l	0			;結合ブロックのヘッダ(0=拡張モード禁止)
jointBlockSize::
	.dc.l	DEFAULT_JOIN_SIZE	;結合ブロックのサイズ(ヘッダを含まない)

;----------------------------------------------------------------
;
;	スレッドの排他制御関係のワーク
;
;----------------------------------------------------------------
backgroundFlag::
	.ds.b	1		;-1=スレッド間の排他制御を行う

	.align	4,$2048
exclusiveStart::
	.ds.l	1		;メインスレッド以外の排他制御情報の先頭
				;メインスレッド以外の排他制御情報は,
				;1個xSize2バイトで($1C58.w).w個必要
exclusiveEnd::
	.ds.l	1		;メインスレッド以外の排他制御情報の末尾+1

;排他制御情報へのポインタのテーブル
;-1は排他制御情報が存在しない(初期化されていない)ことを示す
	.align	4,$2048
xTable::
	.dc.l	mainExclusive
	.dcb.l	32-1,-1

;メインスレッドの排他制御情報
mainExclusive::
	.ds.b	xSize		;ドライブ管理テーブルは既に存在するので不要

	.even
currentThreadId::
	.dc.w	0		;現在のスレッド番号

;----------------------------------------------------------------
;
;	ファイル情報
;
;----------------------------------------------------------------
	.align	4
fileInfoHeapStart::
	.ds.l	1		;ファイル情報の領域(ヒープ管理)の先頭
fileInfoHeapEnd::
	.ds.l	1		;ファイル情報の領域(ヒープ管理)の末尾
fileInfoHashTablePtr::
	.ds.l	1		;ハッシュテーブルへのポインタ(4*256バイト)
				;内容はファイル情報へのハンドル

;----------------------------------------------------------------
;
;	loadhigh関連のワーク
;
;----------------------------------------------------------------
	.align	4,$2048
userAreaWork::
	.dc.l	0			;ユーザモードのワークエリア
					;(コマンドラインなどを渡すとき使用する)
execLoadHigh::
	.dc.b	0			;_EXECから_MALLOCしたときloadhighするか(-1=yes)

defaultLoadArea::
	.dc.b	0			;ロード領域の条件
					;	0	下位のみ
					;	1	上位のみ
					;	2	親と同じ側のみ
					;	3	親と反対側のみ
					;	4	制限なし,下位優先
					;	5	制限なし,上位優先
					;	6	制限なし,親と同じ側優先
					;	7	制限なし,親と反対側優先
					;	8	制限なし,優先なし
defaultAllocArea::
	.dc.b	0			;アロケート領域の条件
					;	0	下位のみ
					;	1	上位のみ
					;	2	親と同じ側のみ
					;	3	親と反対側のみ
					;	4	制限なし,下位優先
					;	5	制限なし,上位優先
					;	6	制限なし,親と同じ側優先
					;	7	制限なし,親と反対側優先
					;	8	制限なし,優先なし

;----------------------------------------------------------------
;
;	Humanのバージョンに依存する定数のワーク
;
;----------------------------------------------------------------
	.align	4,$2048
killPrEntry::
	.dc.l	$0000E60C		;_KILL_PRの開始位置
stdHdlDup0::
	.dc.l	$00013D1A		;標準ハンドラ変換テーブル
stdHdlToFcb::
	.dc.l	$00013D24		;ハンドラ番号=0～5のハンドラFCB変換テーブル
stdFcbTable::
	.dc.l	$00013D30		;FCB番号=0～5のFCBテーブル

;----------------------------------------------------------------
;
;	RAMDISK関係のワーク
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;ローカルメモリ上でRAMDISKの存在する範囲
;	RAMDISKの領域に該当するページはスーパーバイザ保護される
	.align	4,$2048
localRamdiskAreaStart::
	.dc.l	0			;先頭
localRamdiskAreaEnd::
	.dc.l	0			;末尾+1
localRamdiskAreaSize::
	.dc.l	0			;サイズ(ページサイズの倍数)

;----------------------------------------------------------------
;メインメモリ上でRAMDISKの存在する範囲
;	RAMDISKの領域に該当するページはスーパーバイザ保護される
	.align	4,$2048
mainRamdiskAreaStart::
	.dc.l	0			;先頭
mainRamdiskAreaEnd::
	.dc.l	0			;末尾+1
mainRamdiskAreaSize::
	.dc.l	0			;サイズ(ページサイズの倍数)

;----------------------------------------------------------------
;BPBテーブルのアドレス
	.align	4,$2048
bpbTablePointer::
d = 0
  .rept MAXIMUM_UNIT
	.dc.l	bpbTable+d
d = d+28
  .endm

;----------------------------------------------------------------
;BPBテーブル
	.align	4,$2048
bpbTable::
  .rept MAXIMUM_UNIT
	.dc.w	1024		;+0	1セクタあたりのバイト数
	.dc.b	1		;+2	1クラスタあたりのセクタ数
	.dc.b	1		;+3	FAT領域の個数
				;	bit7=1のとき2バイトFATの上下のバイトを入れ換える
	.dc.w	0		;+4	FATの先頭セクタ番号
	.dc.w	ROOT_ENTRY	;+6	ルートディレクトリに入るエントリ数
	.dc.w	0		;+8	(全領域のセクタ数)
	.dc.b	$F9		;+10	メディアバイト
	.dc.b	1		;+11	1個のFAT領域に使用するセクタ数
	.dc.l	DEFAULT_SIZE	;+12	全領域のセクタ数
	.dc.l	0		;+16	先頭アドレス(0=このユニットは存在しない)
	.dc.l	0		;+20	末尾アドレス+1
	.dc.b	0		;+24	アクセスランプを使うかどうか
	.ds.b	3		;+25
				;+28
  .endm

;----------------------------------------------------------------
;
;	デバッグ用サブルーチン
;
;----------------------------------------------------------------
;数値を16進数8桁で表示
;<d0.l:数値
	.align	4,$2048
debugHex8::
	move.w	ccr,-(sp)
	swap.w	d0
	bsr	debugHex4
	swap.w	d0
	bsr	debugHex4
	move.w	(sp)+,ccr
	rts

;数値を16進数4桁で表示
;<d0.w:数値
	.align	4,$2048
debugHex4::
	move.w	ccr,-(sp)
	rol.w	#8,d0
	bsr	debugHex2
	rol.w	#8,d0
	bsr	debugHex2
	move.w	(sp)+,ccr
	rts

;数値を16進数2桁で表示
;<d0.b:数値
	.align	4,$2048
debugHex2::
	move.w	ccr,-(sp)
	movem.l	d1-d2,-(sp)
	moveq.l	#2-1,d2
@@:	rol.b	#4,d0
	moveq.l	#$0F,d1
	and.l	d0,d1
	move.b	(hexchar,pc,d1.l),d1
	bsr	debugPutc
	dbra	d2,@b
	movem.l	(sp)+,d1-d2
	move.w	(sp)+,ccr
	rts

hexchar:
	.dc.b	'0123456789ABCDEF'

;文字列表示
;<a1.l:文字列のアドレス
	.align	4,$2048
debugPrint::
	move.w	ccr,-(sp)
	movem.l	d0/a1,-(sp)
	moveq.l	#$21,d0
	trap	#15
	movem.l	(sp)+,d0/a1
	move.w	(sp)+,ccr
	rts

;1文字表示
;<d1.w:文字コード
	.align	4,$2048
debugPutc::
	move.w	ccr,-(sp)
	movem.l	d0-d1,-(sp)
	moveq.l	#$20,d0
	trap	#15
	movem.l	(sp)+,d0-d1
	move.w	(sp)+,ccr
	rts

;1キー入力待ち
	.align	4,$2048
debugKeyinp::
	move.w	ccr,-(sp)
	move.l	d0,-(sp)
	bra	2f
1:	moveq.l	#0,d0
	trap	#15
2:	moveq.l	#1,d0
	trap	#15
	tst.b	d0
	bne	1b
3:	moveq.l	#0,d0
	trap	#15
	tst.b	d0
	beq	3b
	move.l	(sp)+,d0
	move.w	(sp)+,ccr
	rts

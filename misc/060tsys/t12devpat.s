;----------------------------------------------------------------
;
;	デバイスドライバのハイメモリ対策
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;デバイスドライバを呼び出す(キャッシュおよびローカルメモリ対策)
;	Human302での手順(68000,68030)
;		$0000DEFA
;			データキャッシュをOFFにする
;			([6,a1])を呼び出す
;			([10,a1])を呼び出す
;			データキャッシュと命令キャッシュをフラッシュする
;			キャッシュモードを復元する
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;?d0
callDevice::
;ドライバ自身のRAMDISKドライバの呼び出しは特別扱いで高速化
	cmpa.l	#deviceHeader,a1
	beq	ramdiskGo
;RAMDISKがないときはここからスタート
callDeviceNoRamdisk::
;キャラクタデバイスのときはキャッシュのみ処置
	tst.w	(4,a1)			;デバイスタイプ
	bmi	characterDevice		;キャラクタデバイス
;ブロックデバイス,特殊デバイス
	movem.l	d1-d7/a0-a3/a5-a6,-(sp)
;特殊デバイスを区別する
	btst.b	#13-8,(4,a1)
	bne	specialDevice		;特殊デバイス
;----------------------------------------------------------------
;ブロックデバイスの呼び出し
;	転送とディスク交換チェックは-npが指定されていなければキャッシュ操作を伴う
;	その他のコマンドは無条件にキャッシュ操作を伴う
blockDevice:
	moveq.l	#0,d0
	move.b	(2,a5),d0		;コマンド
	cmp.b	#$0D,d0
	bcc	unknownCommand
	jsr	([@f,pc,d0.l*4])
	movem.l	(sp)+,d1-d7/a0-a3/a5-a6
	rts

@@:	.dc.l	deviceGoPush		;00	初期化
	.dc.l	deviceGoPush		;01	ディスク交換チェック
	.dc.l	deviceGoPush		;02	ディスク交換処理
	.dc.l	ioctrlRead		;03	IOCTRLによる入力
	.dc.l	blockRead		;04	入力
	.dc.l	deviceGoPush		;05	ドライブコントロール&センス
					;	(キャッシュ制御しないとFORMAT.Xが動かない)
	.dc.l	deviceGoPush		;06	エラー
	.dc.l	deviceGoPush		;07	エラー
	.dc.l	blockWrite		;08	出力(VERIFY OFF時)
	.dc.l	blockWrite		;09	出力(VERIFY ON時)
	.dc.l	deviceGoPush		;0A	エラー
	.dc.l	deviceGoPush		;0B	未使用
	.dc.l	ioctrlWrite		;0C	IOCTRLによる出力

;----------------------------------------------------------------
;特殊デバイスの呼び出し
;	初期化と未定義のコマンドは無条件にキャッシュ操作を伴う
;	その他のコマンドは-npが指定されていなければキャッシュ操作を伴う
specialDevice:
	moveq.l	#$7F,d0
	and.b	(2,a5),d0		;コマンド(verifyフラグを除去)
	sub.b	#$40,d0
	bcs	unknownCommand
	cmp.b	#$59-$40,d0
	bcc	unknownCommand
	jsr	([@f,pc,d0.l*4])
	movem.l	(sp)+,d1-d7/a0-a3/a5-a6
	rts

@@:	.dc.l	deviceGoPush		;40	initialize
	.dc.l	deviceGoPush		;41	chdir
	.dc.l	deviceGoPush		;42	mkdir
	.dc.l	deviceGoPush		;43	rmdir
	.dc.l	deviceGoPush		;44	rename
	.dc.l	deviceGoPush		;45	delete
	.dc.l	deviceGoPush		;46	chmod
	.dc.l	deviceGoPush		;47	files
	.dc.l	deviceGoPush		;48	nfiles
	.dc.l	deviceGoPush		;49	create/newfile
	.dc.l	deviceGoPush		;4A	open
	.dc.l	deviceGoPush		;4B	close
	.dc.l	specialRead		;4C	read
	.dc.l	specialWrite		;4D	write
	.dc.l	deviceGoPush		;4E	seek
	.dc.l	deviceGoPush		;4F	filedate
	.dc.l	deviceGoPush		;50	dskfre
	.dc.l	deviceGoPush		;51	drvctrl
	.dc.l	deviceGoPush		;52	getdpb
	.dc.l	deviceGoPush		;53	diskred
	.dc.l	deviceGoPush		;54	diskwrt
	.dc.l	deviceGoPush		;55	special_ctrl
	.dc.l	deviceGoPush		;56	fflush
	.dc.l	deviceGoPush		;57	mediacheck
	.dc.l	deviceGoPush		;58	lock

;----------------------------------------------------------------
;未対応のコマンド
;	無条件にキャッシュ操作を伴う
unknownCommand:
	movem.l	(sp)+,d1-d7/a0-a3/a5-a6
	bra	deviceGoPush

;----------------------------------------------------------------
;キャラクタデバイスの呼び出し
;	初期化は無条件にキャッシュ操作を伴う
;	その他のコマンドは-npが指定されていなければキャッシュ操作を伴う
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;?d0
characterDevice:
	tst.b	(2,a5)			;コマンド
	beq	deviceGoPush		;初期化
;----------------------------------------------------------------
;デバイスの処理を実行する(-npが指定されていなければキャッシュ操作を伴う)
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;?d0
deviceGo:
	tst.b	deviceCacheNoPush
	beq	deviceGoPush		;-npが指定されていない
	move.l	a0,-(sp)
	movea.l	([$1C28.w]),a0
	tst.b	(pDeviceNoPush,a0)
	movea.l	(sp)+,a0
	beq	deviceGoPush		;-npを適用できないプロセス
;----------------------------------------------------------------
;デバイスの処理を実行する(キャッシュ操作を伴わない)
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;?d0
	jsr	([6,a1])		;ストラテジルーチンを呼ぶ
	jmp	([10,a1])		;インタラプトルーチンを呼ぶ

;----------------------------------------------------------------
specialRead:				;現在未対応
specialWrite:				;現在未対応
;----------------------------------------------------------------
;デバイスの処理を実行する(キャッシュ操作を伴う)
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;?d0
deviceGoPush:
	PUSH_CACR_DISABLE_DC	d0
	jsr	([6,a1])		;ストラテジルーチンを呼ぶ
	jsr	([10,a1])		;インタラプトルーチンを呼ぶ
	cmpi.b	#4,$0CBC.w
	blo	@f
	cinva	ic
@@:
	POP_CACR	d0
	rts

;----------------------------------------------------------------
;RAMDISKの処理を実行する
;	データキャッシュをプッシュしない
;	コマンドコード毎の処理を直接呼び出す
;	requestHeaderを設定しないのでコマンド内でrequestHeaderを使わないこと
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;?d0
ramdiskGo:
	moveq.l	#0,d0
	move.b	(2,a5),d0		;コマンドコード
	jsr	([deviceJumpTable,pc,d0.l*4])	;コマンドの処理を呼ぶ
	move.b	d0,(3,a5)		;エラーコード(下位)
	lsr.w	#8,d0
	move.b	d0,(4,a5)		;エラーコード(上位)
	rts

;----------------------------------------------------------------
;ブロックデバイスへの書き込み
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
blockWrite:
	tst.b	patchDevice
	beq	deviceGo		;ローカルメモリ対策をしないときはキャッシュのみ処置

  debug '|blockWrite(top,siz,ptr,head) ',4,(22,a5),(18,a5),(14,a5),([14,a5])
	lea.l	(blockWriteTransfer,pc),a2	;ブロックデバイスへの出力
	moveq.l	#1,d0
	bra	blockTransfer

;----------------------------------------------------------------
;ブロックデバイスからの読み出し
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
blockRead:
	tst.b	patchDevice
	beq	deviceGo		;ローカルメモリ対策をしないときはキャッシュのみ処置

  debug '|blockRead(top,siz,ptr) ',3,(22,a5),(18,a5),(14,a5)
	lea.l	(blockReadTransfer,pc),a2	;ブロックデバイスからの入力
	moveq.l	#0,d0
;ブロックデバイスの入出力
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<a1.l:デバイスヘッダ
;<a2.l:転送ルーチン
;<a5.l:リクエストヘッダ
blockTransfer:
	move.l	(18,a5),d6		;転送セクタ数
	beq	deviceGo		;転送セクタ数が0のときは何もしない
;内部DPBテーブルを求める
	bsr	searchInnerDpb		;デバイスヘッダとユニット番号から内部DPBテーブルを探す
	bmi	deviceGo		;内部DPBテーブルが見つからない(念のため)
;<a0.l:内部DPBテーブル
  debug 'inner dpb=',1,a0
  debugByte 'drive,unit=',2,(iDrive,a0),(iUnit,a0)
  debug 'device header=',1,(iDeviceHeader,a0)
  debugByte 'media byte=',1,(iMediaByte,a0)
  debugByte 'byte per sect2=',1,(iBytePerSect2,a0)
;メディアバイト一覧
;	$F0	SCSI MO (IBM format)
;	$F4	SCSI DAT
;	$F5	SCSI CD-ROM
;	$F6	SCSI MO
;	$F7	SCSI HD
;	$F8	SASI HD
;	$F9	RAM / SRAM / ROM
;	$FA	2HD 1.44MB
;	$FB	2DD 640KB
;	$FC	2DD 720KB
;	$FD	2HC 1.2MB
;	$FE	2HD 1.2MB
;メディアバイトが$F0～$F7のとき,SCSI IOCSにパッチがあたっていれば
;SCSI IOCS側でソフト転送になるので一時バッファを媒介しなくてよい
	moveq.l	#$10,d3
	add.b	(iMediaByte,a0),d3	;メディアバイト
;	bcc	@f
	subq.b	#8,d3
	bcc	@f
	tst.b	patchIocsScsi
	bne	deviceGo
@@:
	move.b	(iBytePerSect2,a0),d3	;セクタ数をバイト数に変換するときのシフトカウント
	cmp.b	#8,d3
	blo	deviceGo		;1セクタが256バイト未満(念のため)
	move.l	tempBufferSize,d4	;一時バッファのバイト数
	lsr.l	d3,d4			;一時バッファのセクタ数
	move.l	(14,a5),d5		;目的のバッファの先頭アドレス
	and.l	#LOGICAL_MASK,d5	;_DISKRED/_DISKWRTの拡張モードではbit31が
					;セットされたまま入ってくる
	move.l	(22,a5),d7		;先頭のセクタ番号
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<d3.b:セクタ数をバイト数に変換するときのシフトカウント
;<d4.l:一時バッファのセクタ数
;<d5.l:目的のバッファの先頭アドレス
;<d6.l:転送セクタ数
;<d7.l:先頭のセクタ番号
;<a0.l:内部DPBテーブル
;<a1.l:デバイスヘッダ
;<a2.l:転送ルーチン
;<a5.l:リクエストヘッダ
;目的のバッファがDMA転送可能かどうか調べる
;	物理アドレスが論理アドレスと異なる場合はDMA転送不可
;	物理アドレスがローカルメモリを指している場合もDMA転送不可
	move.l	d5,d1			;先頭
	move.l	d6,d2			;セクタ数
	lsl.l	d3,d2			;バイト数
	add.l	d5,d2			;末尾+1
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<d1.l:バッファの先頭
;<d2.l:バッファの末尾+1
	bsr	dmaAccessCheck
	bpl	deviceGo		;DMA転送可能な領域なので何もしない
;----------------------------------------------------------------
;一時バッファを使った転送処理(ブロックデバイスの入出力)
;新しいリクエストヘッダを確保する
	lea.l	(-26,sp),sp
	movea.l	a5,a6			;元のリクエストヘッダ
	movea.l	sp,a5			;新しいリクエストヘッダ
;<a5.l:新しいリクエストヘッダ
;<a6.l:元のリクエストヘッダ
;転送ループ
blockTransferLoop:
;新しいリクエストヘッダを作る
	move.w	(a6),(a5)		;定数,コマンドコード
	movem.l	(2,a6),d0-d2
	movem.l	d0-d2,(2,a5)
;パラメータを設定する
	sub.l	d4,d6			;残りの転送セクタ数
	bcc	@f
	add.l	d6,d4			;今回の転送セクタ数
	moveq.l	#0,d6
@@:	movea.l	tempBufferStart,a0	;一時バッファの先頭アドレス
	move.l	a0,(14,a5)		;転送アドレス
	move.l	d4,(18,a5)		;セクタ数
	move.l	d7,(22,a5)		;セクタ番号
	add.l	d4,d7			;次のセクタ番号
;入出力の実行
;<d3.b:セクタ数をバイト数に変換するときのシフトカウント
;<d4.l:今回の転送セクタ数
;<d5.l:目的のバッファのアドレス
;<d6.l:残りの転送セクタ数
;<d7.l:次のセクタ番号
;<a0.l:一時バッファの先頭アドレス
;<a1.l:デバイスヘッダ
;<a2.l:転送ルーチン
;<a5.l:新しいリクエストヘッダ(構築済み)
;<a6.l:元のリクエストヘッダ
	jsr	(a2)			;入力または出力の実行
	tst.l	d6
	bne	blockTransferLoop
;エラーコードを元のリクエストヘッダにコピーして終わり
blockTransferEnd:
	move.w	(3,a5),(3,a6)		;エラーコード
	movea.l	a6,a5
	lea.l	(26,sp),sp
;一時バッファを使った転送処理終わり
	rts

;エラー発生時は続きを処理せずに終了
blockTransferError:
	addq.l	#4,sp
	bra	blockTransferEnd

;----------------------------------------------------------------
;ブロックデバイスからの入力
;<d3.b:セクタ数をバイト数に変換するときのシフトカウント
;<d4.l:今回の転送セクタ数
;<d5.l:目的のバッファのアドレス
;<a0.l:一時バッファの先頭アドレス
;<a1.l:デバイスヘッダ
;<a5.l:新しいリクエストヘッダ(構築済み)
;>d5.l:目的のバッファの次のアドレス
;*d5,?d0/a0
blockReadTransfer:
  debug '|blockReadTransfer(ptr,tmp,(top,siz,ptr)) ',5,d5,a0,(22,a5),(18,a5),(14,a5)
;デバイスの処理を実行する
	bsr	deviceGo		;デバイスの処理を実行する(キャッシュ操作を伴う)
	tst.b	(3,a5)			;エラーチェック
	bne	blockTransferError	;エラーが発生したので中止する
;一時バッファから目的のバッファにコピーする
	moveq.l	#$0F,d0
	and.l	d5,d0
					;元  先,デバイスヘッダ
					;d5→a0,a1
	exg.l	d5,a1			;a1→a0,d5
	bsr	blockTransferSub
	exg.l	d5,a1			;d5→a0,a1
	rts

;----------------------------------------------------------------
;ブロックデバイスへの出力
;<d3.b:セクタ数をバイト数に変換するときのシフトカウント
;<d4.l:今回の転送セクタ数
;<d5.l:目的のバッファのアドレス
;<a0.l:一時バッファの先頭アドレス
;<a1.l:デバイスヘッダ
;<a5.l:新しいリクエストヘッダ(構築済み)
;>d5.l:目的のバッファの次のアドレス
;*d5,?d0/a0
blockWriteTransfer:
  debug '|blockWriteTransfer(ptr,tmp,(top,siz,ptr,head)) ',6,d5,a0,(22,a5),(18,a5),(14,a5),([14,a5])
;目的のバッファから一時バッファにコピーする
	moveq.l	#$0F,d0
	and.l	d5,d0
					;元  先,デバイスヘッダ
					;d5→a0,a1
	exg.l	d5,a1			;a1→a0,d5
	exg.l	a0,a1			;a0→a1,d5
	bsr	blockTransferSub
	movea.l	d5,a1			;a0→??,a1
	move.l	a0,d5			;d5→??,a1
;デバイスの処理を実行する
	bsr	deviceGo		;デバイスの処理を実行する(キャッシュ操作を伴う)
	tst.b	(3,a5)			;エラーチェック
	bne	blockTransferError	;エラーが発生したので中止する
	rts

;----------------------------------------------------------------
;転送サブルーチン
;<d0.l:0のときmove16を使う
;<d3.b:セクタ数をバイト数に変換するときのシフトカウント
;<d4.l:今回の転送セクタ数
;<a0.l:転送元の先頭アドレス
;<a1.l:転送先の先頭アドレス
;>a0.l:転送元の次のアドレス
;>a1.l:転送先の次のアドレス
;*a0-a1,?d0
blockTransferSub:
  debug '|blockTransferSub(src,dst) ',2,a0,a1
	tst.l	d0
	bne	blockTransferSub1
	cmpi.b	#4,$0CBC.W
	blo	blockTransferSub1
;move16を使って転送する
	move.l	d4,d0			;セクタ数
	lsl.l	d3,d0			;バイト数
;<d0.l:転送バイト数
;<a0.l:転送元のアドレス(16の倍数)
;<a1.l:転送先のアドレス(16の倍数)
	lsr.l	#8,d0			;バイト数/256
@@:
  .rept 16
	move16	(a0)+,(a1)+		;256バイトずつコピーする
  .endm
	subq.l	#1,d0
	bne	@b
	rts

;moveを使って転送する
blockTransferSub1:
	move.l	d4,d0			;セクタ数
	lsl.l	d3,d0			;バイト数
;<d0.l:転送バイト数
;<a0.l:転送元のアドレス
;<a1.l:転送先のアドレス
	lsr.l	#8,d0			;バイト数/256
@@:
  .rept 64
	move.l	(a0)+,(a1)+		;256バイトずつコピーする
  .endm
	subq.l	#1,d0
	bne	@b
	rts

;----------------------------------------------------------------
;ブロックデバイスからのIOCTRLによる書き込み
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
ioctrlWrite:
	tst.b	patchDevice
	beq	deviceGo		;ローカルメモリ対策をしないときはキャッシュのみ処置

	lea.l	(ioctrlWriteTransfer,pc),a2	;ブロックデバイスへのIOCTRLによる出力
	moveq.l	#1,d0
	bra	ioctrlTransfer

;----------------------------------------------------------------
;ブロックデバイスからのIOCTRLによる読み出し
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
ioctrlRead:
	tst.b	patchDevice
	beq	deviceGo		;ローカルメモリ対策をしないときはキャッシュのみ処置

	lea.l	(ioctrlReadTransfer,pc),a2	;ブロックデバイスからのIOCTRLによる入力
	moveq.l	#0,d0
;ブロックデバイスのIOCTRLによる入出力
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<a1.l:デバイスヘッダ
;<a2.l:転送ルーチン
;<a5.l:リクエストヘッダ
ioctrlTransfer:
	move.l	(18,a5),d6		;転送バイト数
	beq	deviceGo		;転送バイト数が0のときは何もしない
	move.l	tempBufferSize,d4	;一時バッファのバイト数
	move.l	(14,a5),d5		;目的のバッファの先頭アドレス
	and.l	#LOGICAL_MASK,d5	;念のため
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<d4.l:一時バッファのバイト数
;<d5.l:目的のバッファの先頭アドレス
;<d6.l:転送バイト数
;<a1.l:デバイスヘッダ
;<a2.l:転送ルーチン
;<a5.l:リクエストヘッダ
;目的のバッファがDMA転送可能かどうか調べる
;	物理アドレスが論理アドレスと異なる場合はDMA転送不可
;	物理アドレスがローカルメモリを指している場合もDMA転送不可
	move.l	d5,d1			;先頭
	move.l	d6,d2			;セクタ数
	add.l	d5,d2			;末尾+1
;<d0.l:転送方向
;	0	デバイスから読み出し(メモリへ書き込み)
;	1	デバイスへ書き込み(メモリから読み出し)
;<d1.l:バッファの先頭
;<d2.l:バッファの末尾+1
	bsr	dmaAccessCheck
	bpl	deviceGo		;DMA転送可能な領域なので何もしない
;----------------------------------------------------------------
;一時バッファを使った転送処理(ブロックデバイスのIOCTRLによる入出力)
;新しいリクエストヘッダを確保する
	lea.l	(-26,sp),sp
	movea.l	a5,a6			;元のリクエストヘッダ
	movea.l	sp,a5			;新しいリクエストヘッダ
;<a5.l:新しいリクエストヘッダ
;<a6.l:元のリクエストヘッダ
;転送ループ
ioctrlTransferLoop:
;新しいリクエストヘッダを作る
	move.w	(a6),(a5)		;定数,コマンドコード
	movem.l	(2,a6),d0-d2
	movem.l	d0-d2,(2,a5)
;パラメータを設定する
	sub.l	d4,d6			;残りの転送バイト数
	bcc	@f
	add.l	d6,d4			;今回の転送バイト数
	moveq.l	#0,d6
@@:	movea.l	tempBufferStart,a0	;一時バッファの先頭アドレス
	move.l	a0,(14,a5)		;転送アドレス
	move.l	d4,(18,a5)		;バイト数
					;(22,a5)は設定しない
;入出力の実行
;<d4.l:今回の転送バイト数
;<d5.l:目的のバッファのアドレス
;<d6.l:残りの転送バイト数
;<a0.l:一時バッファの先頭アドレス
;<a1.l:デバイスヘッダ
;<a2.l:転送ルーチン
;<a5.l:新しいリクエストヘッダ(構築済み)
;<a6.l:元のリクエストヘッダ
	jsr	(a2)			;入力または出力の実行
	tst.l	d6
	bne	ioctrlTransferLoop
;エラーコードを元のリクエストヘッダにコピーして終わり
ioctrlTransferEnd:
	move.w	(3,a5),(3,a6)		;エラーコード
	movea.l	a6,a5
	lea.l	(26,sp),sp
;一時バッファを使った転送処理終わり
	rts

;エラー発生時は続きを処理せずに終了
ioctrlTransferError:
	addq.l	#4,sp
	bra	ioctrlTransferEnd

;----------------------------------------------------------------
;ブロックデバイスからのIOCTRLによる入力
;<d4.l:今回の転送バイト数
;<d5.l:目的のバッファのアドレス
;<a0.l:一時バッファの先頭アドレス
;<a1.l:デバイスヘッダ
;<a5.l:新しいリクエストヘッダ(構築済み)
;>d5.l:目的のバッファの次のアドレス
;*d5,?d0/a0
ioctrlReadTransfer:
;デバイスの処理を実行する
	bsr	deviceGo		;デバイスの処理を実行する(キャッシュ操作を伴う)
	tst.b	(3,a5)			;エラーチェック
	bne	ioctrlTransferError	;エラーが発生したので中止する
;一時バッファから目的のバッファにコピーする
					;元  先,デバイスヘッダ
					;d5→a0,a1
	exg.l	d5,a1			;a1→a0,d5
	bsr	ioctrlTransferSub
	exg.l	d5,a1			;d5→a0,a1
	rts

;----------------------------------------------------------------
;ブロックデバイスへのIOCTRLによる出力
;<d4.l:今回の転送バイト数
;<d5.l:目的のバッファのアドレス
;<a0.l:一時バッファの先頭アドレス
;<a1.l:デバイスヘッダ
;<a5.l:新しいリクエストヘッダ(構築済み)
;>d5.l:目的のバッファの次のアドレス
;*d5,?d0/a0
ioctrlWriteTransfer:
;目的のバッファから一時バッファにコピーする
					;元  先,デバイスヘッダ
					;d5→a0,a1
	exg.l	d5,a1			;a1→a0,d5
	exg.l	a0,a1			;a0→a1,d5
	bsr	ioctrlTransferSub
	movea.l	d5,a1			;a0→??,a1
	move.l	a0,d5			;d5→??,a1
;デバイスの処理を実行する
	bsr	deviceGo		;デバイスの処理を実行する(キャッシュ操作を伴う)	jsr	([6,a1]			;元のストラテジルーチンを呼ぶ
	tst.b	(3,a5)			;エラーチェック
	bne	ioctrlTransferError	;エラーが発生したので中止する
	rts

;----------------------------------------------------------------
;転送サブルーチン
;<d4.l:今回の転送バイト数
;<a0.l:転送元の先頭アドレス
;<a1.l:転送先の先頭アドレス
;>a0.l:転送元の次のアドレス
;>a1.l:転送先の次のアドレス
;*a0-a1,?d0
ioctrlTransferSub:
	move.l	d4,d0			;バイト数
;<d0.l:転送バイト数
;<a0.l:転送元のアドレス
;<a1.l:転送先のアドレス
@@:	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne	@b
	rts

;----------------------------------------------------------------
;デバイスヘッダとユニット番号から内部DPBテーブルを探す
;<a1.l:デバイスヘッダ
;<a5.l:リクエストヘッダ
;>a0.l:内部DPBテーブル
;	-1	見つからなかった
;>n-flag:pl=見つかった,mi=見つからなかった
searchInnerDpb:
	move.l	d0,-(sp)
	move.b	(1,a5),d0		;ユニット番号
	movea.l	$1C3C.w,a0		;[$1C3C.w].l:内部DPBテーブルの先頭アドレス
	cmpa.l	(2,a0),a1		;デバイスヘッダ
	beq	3f
1:	movea.l	(6,a0),a0		;次の内部DPBテーブル
	tst.l	a0
	bmi	9f			;見つからなかった(見つからないはずはないが念のため)
2:	cmpa.l	(2,a0),a1		;デバイスヘッダ
	bne	1b
;デバイスヘッダが一致した
3:	cmp.b	(1,a0),d0		;ユニット番号を比較
	bne	1b			;ユニット番号が異なる
9:	move.l	(sp)+,d0
	tst.l	a0			;デバイスヘッダまたは-1
	rts

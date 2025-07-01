;----------------------------------------------------------------
;
;	SCSI
;
;----------------------------------------------------------------

	.include	t00iocs.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;
;	IOCS _SCSIDRV
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _SCSIDRV
;	バッファがDMA転送できないとき(バッファの物理アドレスが論理アドレスと
;	異なる場合および物理アドレスがローカルメモリを指している場合)はソフト
;	転送に変更する。
;	_S_REVISIONの返却値が$000A以上のとき(SHARP純正拡張SCSIボード,X68030の
;	内蔵SCSI-BIOSおよびMach-2のSCSI-BIOS)はSRAMのソフト転送フラグを使って
;	ソフト転送に変更する。
;	_S_REVISIONの返却値が$000A未満のとき(SUPERからXVICompactまでのX68000の
;	内蔵SCSI-BIOS)は高レベルの転送コマンド(_S_READ,_S_READEXTなど)を自前で
;	展開して低レベルのソフト転送コマンドを用いる。
	.text
	.align	4,$2048
iocsScsidrv::
	tst.b	patchIocsScsi
	beq	scsicall
	cmp.l	#(scsidrvJumpTableEnd-scsidrvJumpTable)/4,d1
	bcc	scsicall
	jmp	([scsidrvJumpTable,pc,d1.l*4])

	.align	4,$2048
scsidrvJumpTable:
	.dc.l	scsicall		;$00 _S_RESET
	.dc.l	scsicall		;$01 _S_SELECT
	.dc.l	scsicall		;$02 _S_SELECTA
	.dc.l	scsicall		;$03 _S_CMDOUT
	.dc.l	scsidrvDatain		;$04 _S_DATAIN
	.dc.l	scsidrvDataout		;$05 _S_DATAOUT
	.dc.l	scsicall		;$06 _S_STSIN
	.dc.l	scsicall		;$07 _S_MSGIN
	.dc.l	scsicall		;$08 _S_MSGOUT
	.dc.l	scsicall		;$09 _S_PHASE
	.dc.l	scsicall		;$0A _S_REVISION
	.dc.l	scsicall		;$0B _S_DATAIN_P
	.dc.l	scsicall		;$0C _S_DATAOUT_P
	.dc.l	scsicall		;$0D _S_MSGOUTEXT
	.dc.l	scsicall		;$0E 
	.dc.l	scsicall		;$0F 
	.dc.l	scsicall		;$10 
	.dc.l	scsicall		;$11 
	.dc.l	scsicall		;$12 
	.dc.l	scsicall		;$13 
	.dc.l	scsicall		;$14 
	.dc.l	scsicall		;$15 
	.dc.l	scsicall		;$16 
	.dc.l	scsicall		;$17 
	.dc.l	scsicall		;$18 
	.dc.l	scsicall		;$19 
	.dc.l	scsicall		;$1A 
	.dc.l	scsicall		;$1B 
	.dc.l	scsicall		;$1C 
	.dc.l	scsicall		;$1D 
	.dc.l	scsicall		;$1E 
	.dc.l	scsicall		;$1F 
	.dc.l	scsidrvInquiry		;$20 _S_INQUIRY
	.dc.l	scsidrvRead		;$21 _S_READ
	.dc.l	scsidrvWrite		;$22 _S_WRITE
	.dc.l	scsicall		;$23 _S_FORMAT
	.dc.l	scsicall		;$24 _S_TESTUNIT
	.dc.l	scsidrvReadcap		;$25 _S_READCAP
	.dc.l	scsidrvReadext		;$26 _S_READEXT
	.dc.l	scsidrvWriteext		;$27 _S_WRITEEXT
	.dc.l	scsidrvVerifyext	;$28 _S_VERIFYEXT
	.dc.l	scsidrvModesense	;$29 _S_MODESENSE
	.dc.l	scsidrvModeselect	;$2A _S_MODESELECT
	.dc.l	scsicall		;$2B _S_REZEROUNIT
	.dc.l	scsidrvRequest		;$2C _S_REQUEST
	.dc.l	scsicall		;$2D _S_SEEK
	.dc.l	scsidrvReaddma		;$2E _S_READDMA
	.dc.l	scsicall		;$2F _S_STARTSTOP
	.dc.l	scsicall		;$30 _S_SEJECT
	.dc.l	scsidrvReassign		;$31 _S_REASSIGN
	.dc.l	scsicall		;$32 _S_PAMEDIUM
	.dc.l	scsicall		;$33 
	.dc.l	scsicall		;$34 
	.dc.l	scsicall		;$35 
	.dc.l	scsicall		;$36 _S_DSKINI
	.dc.l	scsicall		;$37 _S_FORMATB
	.dc.l	scsicall		;$38 _S_BADFMT
	.dc.l	scsicall		;$39 _S_ASSIGN
scsidrvJumpTableEnd:

;----------------------------------------------------------------
;元の_SCSIDRVを呼び出す
;	Mach-2によるプリンタレディー割り込みベクタの変更をブロックする。
;<d1.l:コマンド
	.text
	.align	4,$2048
scsicall::
	move.l	PRNINT.w,-(sp)		;プリンタレディー割り込みベクタを保存
	pea.l	(@f,pc)
	move.l	vectorOldIocsScsidrv,-(sp)
	rts
@@:	move.l	(sp)+,PRNINT.w		;プリンタレディー割り込みベクタを復元
	rts

;----------------------------------------------------------------
;SRAMのソフト転送フラグをセットした状態で元の_SCSIDRVを呼び出す
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないのでそのまま呼び出す。
;<d1.l:コマンド
	.text
	.align	4,$2048
scsicallSoft::
	cmpi.w	#$000A,scsiRevisionCode
	blo	scsicall		;SRAMのソフト転送フラグに対応していない
	btst.b	#4,$00ED0070
	bne	scsicall		;既にソフト転送になっている
					;以降は終わったら無条件にOFFするので先に確認する
	move.b	#$31,$00E8E00D
	bset.b	#4,$00ED0070		;ソフト転送ON
	move.b	#$00,$00E8E00D
	bsr	scsicall		;元の_SCSIDRVを呼び出す
	move.b	#$31,$00E8E00D
	bclr.b	#4,$00ED0070		;ソフト転送OFF
	move.b	#$00,$00E8E00D
	rts

;----------------------------------------------------------------
;バッファがDMA転送可能かどうか調べる(デバイスからメモリへ転送)
;	以下の条件のいずれか1つでも成立したときDMA転送不可
;		強制ソフト転送が指定されている
;		バッファの物理アドレスが論理アドレスと異なる
;		バッファの物理アドレスがローカルメモリを指している
;<d3.l:バイト数
;<a1.l:バッファの先頭アドレス
;>n-flag:mi=DMA転送不可,pl=DMA転送可能
	.text
	.align	4,$2048
scsiDmaCheckIn::
	tst.b	forceSoftScsi
	bmi	@f
	movem.l	d0-d2,-(sp)
	moveq.l	#0,d0			;デバイスからメモリへ転送
	move.l	a1,d1
	move.l	a1,d2
	add.l	d3,d2
	bsr	dmaAccessCheck
	movem.l	(sp)+,d0-d2
@@:	rts

;----------------------------------------------------------------
;バッファがDMA転送可能かどうか調べる(メモリからデバイスへ転送)
;	以下の条件のいずれか1つでも成立したときDMA転送不可
;		強制ソフト転送が指定されている
;		バッファの物理アドレスが論理アドレスと異なる
;		バッファの物理アドレスがローカルメモリを指している
;<d3.l:バイト数
;<a1.l:バッファの先頭アドレス
;>n-flag:mi=DMA転送不可,pl=DMA転送可能
	.text
	.align	4,$2048
scsiDmaCheckOut::
	tst.b	forceSoftScsi
	bmi	@f
	movem.l	d0-d2,-(sp)
	moveq.l	#1,d0			;メモリからデバイスへ転送
	move.l	a1,d1
	move.l	a1,d2
	add.l	d3,d2
	bsr	dmaAccessCheck
	movem.l	(sp)+,d0-d2
@@:	rts

;----------------------------------------------------------------
;_S_DATAIN
;	データインフェーズの実行(DMA転送)
;	DMA転送不可のとき_S_DATAIN_Pに変更する
;<d3.l:バイト数
;<a1.l:バッファの先頭アドレス
	.text
	.align	4,$2048
scsidrvDatain::
	bsr	scsiDmaCheckIn
	bpl	scsicall		;DMA転送可能なのでこのまま実行する
	move.l	d1,-(sp)
	moveq.l	#_S_DATAIN_P,d1		;DMA転送不可なので_S_DATAIN_Pに変更する
	bsr	scsicall
	move.l	(sp)+,d1
	rts

;----------------------------------------------------------------
;_S_DATAOUT
;	データアウトフェーズの実行(DMA転送)
;	DMA転送不可のとき_S_DATAOUT_Pに変更する
;<d3.l:バイト数
;<a1.l:バッファの先頭アドレス
	.text
	.align	4,$2048
scsidrvDataout::
	bsr	scsiDmaCheckOut
	bpl	scsicall		;DMA転送可能なのでこのまま実行する
	move.l	d1,-(sp)
	moveq.l	#_S_DATAOUT_P,d1	;DMA転送不可なので_S_DATAOUT_Pに変更する
	bsr	scsicall
	move.l	(sp)+,d1
	rts

;----------------------------------------------------------------
;_S_INQUIRY
;	内蔵SCSI-BIOSは問題ないがMach-2がDMA転送を使おうとするのでパッチが必要
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないがDMA転送も使っていないのでそのままでよい
;<d3.l:バイト数
;<d4.l:ターゲット
;<a1.l:バッファの先頭アドレス
	.text
	.align	4,$2048
scsidrvInquiry::
	bsr	scsiDmaCheckIn
	bpl	scsicall		;DMA転送可能
	bra	scsicallSoft

;----------------------------------------------------------------
;_S_READ
;	DMA転送不可のときソフト転送に変更する
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないので自前で展開する
;<d2.l:ブロック番号($001FFFFF=2097151以下)
;<d3.l:ブロック数($0001=1～$0100=256)
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;>d0.l:
;	-1		エラー
;	-2		エラー(データインフェーズにおけるDMA転送未完了)
;	下位ワード	ステータスインフェーズの結果
;	上位ワード	メッセージインフェーズの結果
	.text
	.align	4,$2048
scsidrvRead::
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;バイト数
	bsr	scsiDmaCheckIn
	movem.l	(sp)+,d3		;フラグ保存
	bpl	scsicall		;バッファはDMA転送可能
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAMのソフト転送フラグが使える
	movem.l	d1-d4/a1,-(sp)		;スタック注意
	moveq.l	#_S_SELECT,d1		;セレクションフェーズ
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;リトライ
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;ブロック数<<8
	and.l	#$001FFFFF,d2		;ブロック番号
	and.l	#$00070000,d4		;LUN<<16
	lsl.l	#5,d4			;LUN<<21
	or.l	d4,d2			;(LUN<<21)|ブロック番号
	or.l	#$08000000,d2		;($08<<24)|(LUN<<21)|ブロック番号
	move.w	d3,-(sp)		;ブロック数 0(256のときは0 0)
	move.l	d2,-(sp)		;$08 LUN|ブロック番号H M L
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;コマンドアウトフェーズ
	bsr	scsicall
	addq.l	#6,sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;バイト数
	movea.l	(4*4,sp),a1		;バッファの先頭アドレス(スタック注意)
	moveq.l	#_S_DATAIN_P,d1		;データインフェーズ
	bsr	scsicall
	cmp.l	#-1,d0			;データインフェーズが-1を返したときは続行不可
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;ステータスインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;メッセージインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;データインフェーズが転送未完了のときは-2を返す
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_WRITE
;	DMA転送不可のときソフト転送に変更する
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないので自前で展開する
;<d2.l:ブロック番号($001FFFFF=2097151以下)
;<d3.l:ブロック数($0001=1～$0100=256)
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;>d0.l:
;	-1		エラー
;	-2		エラー(データアウトフェーズにおけるDMA転送未完了)
;	下位ワード	ステータスインフェーズの結果
;	上位ワード	メッセージインフェーズの結果
	.text
	.align	4,$2048
scsidrvWrite::
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;バイト数
	bsr	scsiDmaCheckOut
	movem.l	(sp)+,d3		;フラグ保存
	bpl	scsicall		;バッファはDMA転送可能
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAMのソフト転送フラグが使える
	movem.l	d1-d4/a1,-(sp)		;スタック注意
	moveq.l	#_S_SELECT,d1		;セレクションフェーズ
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;リトライ
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;ブロック数<<8
	and.l	#$001FFFFF,d2		;ブロック番号
	and.l	#$00070000,d4		;LUN<<16
	lsl.l	#5,d4			;LUN<<21
	or.l	d4,d2			;(LUN<<21)|ブロック番号
	or.l	#$0A000000,d2		;($0A<<24)|(LUN<<21)|ブロック番号
	move.w	d3,-(sp)		;ブロック数 0(256のときは0 0)
	move.l	d2,-(sp)		;$0A LUN|ブロック番号H M L
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;コマンドアウトフェーズ
	bsr	scsicall
	addq.l	#6,sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;バイト数
	movea.l	(4*4,sp),a1		;バッファの先頭アドレス(スタック注意)
	moveq.l	#_S_DATAOUT_P,d1	;データアウトフェーズ
	bsr	scsicall
	cmp.l	#-1,d0			;データアウトフェーズが-1を返したときは続行不可
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;ステータスインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;メッセージインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;データアウトフェーズが転送未完了のときは-2を返す
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_READCAP
;	内蔵SCSI-BIOSは問題ないがMach-2がDMA転送を使おうとするのでパッチが必要
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないがDMA転送も使っていないのでそのままでよい
;<d4.l:ターゲット
;<a1.l:バッファの先頭アドレス
	.text
	.align	4,$2048
scsidrvReadcap::
	move.l	d3,-(sp)
	moveq.l	#8,d3			;8バイト固定
	bsr	scsiDmaCheckIn
	movem.l	(sp)+,d3		;ccr保存
	bpl	scsicall		;DMA転送可能
	bra	scsicallSoft

;----------------------------------------------------------------
;_S_READEXT,_S_WRITEEXT,_S_VERIFYEXTの分割処理ルーチン
;	16MB以上のデータを分割する。
;	_S_READEXT,_S_WRITEEXT,_S_VERIFYEXTはブロック数を65535まで指定できるが
;	実際には16MB以上を一度に転送することができない。すなわちブロックのサイズが
;	512バイトならば32767ブロックが上限となっている。
;	これはソフトウェアの都合ではなくてSPCの転送バイト数カウンタが24ビットしか
;	ないため。
;<d2.l:ブロック番号
;<d3.l:ブロック数
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;<(4,sp).l:転送処理ルーチンのアドレス
;<(8,sp).l:復帰アドレス
	.text
	.align	4,$2048
scsiCommandSplitter::
	movem.l	d1-d5/a1,-(sp)
	lsl.l	d5,d3			;バイト数>>8
	cmp.l	#$00FFFFFF>>8,d3	;サイズが小さければそのまま転送処理を行う
	bls	9f
	lsr.l	d5,d3			;ブロック数
	movem.l	d2-d3/a1,-(sp)
;<(sp):今回のブロック番号
;<(4,sp):今回の残りブロック数
;<(8,sp):今回のバッファの先頭アドレス
1:	movem.l	(12+12,sp),d4-d5	;スタック注意
	move.l	#$00FFFFFF>>8,d3
	lsr.l	d5,d3			;今回のブロック数
	sub.l	d3,(4,sp)		;次回の残りブロック数
	bpl	2f
	add.l	(4,sp),d3		;最後のブロック数
	clr.l	(4,sp)			;残りなし
2:	move.l	(sp),d2			;今回のブロック番号
	add.l	d3,(sp)			;次回のブロック番号
	movea.l	(8,sp),a1		;今回のバッファの先頭アドレス
	lsl.l	#8,d3
	lsl.l	d5,d3
	add.l	d3,(8,sp)		;次回のバッファの先頭アドレス
	lsr.l	#8,d3
	lsr.l	d5,d3
;<d2.l:今回のブロック番号
;<d3.l:今回のブロック数
;<a1.l:今回のバッファの先頭アドレス
;<(sp).l:次回のブロック番号
;<(4,sp).l:次回の残りブロック数
;<(8,sp).l:次回のバッファの先頭アドレス
  debug 'splitted(d2,d3,d4,d5,a1)=',5,d2,d3,d4,d5,a1
	jsr	([12+24,sp])		;転送実行,スタック注意
	tst.l	d0
	bne	3f			;エラー終了
	tst.l	(4,sp)			;残り転送ブロック数
	bne	1b			;残りあり
3:	lea.l	(12,sp),sp
	movem.l	(sp)+,d1-d5/a1
	addq.l	#4,sp			;転送ルーチンをスキップする
					;レジスタを復元するため最後までループの中で行う
	rts

9:	movem.l	(sp)+,d1-d5/a1
	rts

;----------------------------------------------------------------
;_S_READEXT
;	DMA転送不可のときソフト転送に変更する
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないので自前で展開する
;<d2.l:ブロック番号
;<d3.l:ブロック数($0000=0～$FFFF=65535)
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;>d0.l:
;	-1		エラー
;	-2		エラー(データインフェーズにおけるDMA転送未完了)
;	下位ワード	ステータスインフェーズの結果
;	上位ワード	メッセージインフェーズの結果
	.text
	.align	4,$2048
scsidrvReadext::
	bsr	scsiCommandSplitter	;分割処理
;分割処理ルーチンによって以降の処理は複数回に分けて行われることがある
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;バイト数
	bsr	scsiDmaCheckIn
	movem.l	(sp)+,d3		;ccr保存
	bpl	scsicall		;バッファはDMA転送可能
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAMのソフト転送フラグが使える
	movem.l	d1-d4/a1,-(sp)		;スタック注意
	and.l	#$0000FFFF,d3
	beq	8f
	moveq.l	#_S_SELECT,d1		;セレクションフェーズ
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;リトライ
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;ブロック数<<8
	swap.w	d4
	and.w	#$0007,d4		;LUN
	lsl.w	#5,d4			;LUN<<5
	or.w	#$2800,d4		;($28<<8)|(LUN<<5)
	move.l	d3,-(sp)		;0 ブロック数H L 0
	move.l	d2,-(sp)		;ブロック番号HH HL LH LL
	move.w	d4,-(sp)		;($28<<8)|(LUN<<5)
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;コマンドアウトフェーズ
	bsr	scsicall
	lea.l	(10,sp),sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;バイト数
	movea.l	(4*4,sp),a1		;バッファの先頭アドレス(スタック注意)
	moveq.l	#_S_DATAIN_P,d1		;データインフェーズ
	bsr	scsicall
	cmp.l	#-1,d0			;データインフェーズが-1を返したときは続行不可
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;ステータスインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;メッセージインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;データインフェーズが転送未完了のときは-2を返す
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_WRITEEXT
;	DMA転送不可のときソフト転送に変更する
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないので自前で展開する
;<d2.l:ブロック番号
;<d3.l:ブロック数($0000=0～$FFFF=65535)
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;>d0.l:
;	-1		エラー
;	-2		エラー(データアウトフェーズにおけるDMA転送未完了)
;	下位ワード	ステータスインフェーズの結果
;	上位ワード	メッセージインフェーズの結果
	.text
	.align	4,$2048
scsidrvWriteext::
	bsr	scsiCommandSplitter	;分割処理
;分割処理ルーチンによって以降の処理は複数回に分けて行われることがある
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;バイト数
	bsr	scsiDmaCheckOut
	movem.l	(sp)+,d3		;ccr保存
	bpl	scsicall		;バッファはDMA転送可能
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAMのソフト転送フラグが使える
	movem.l	d1-d4/a1,-(sp)		;スタック注意
	and.l	#$0000FFFF,d3
	beq	8f
	moveq.l	#_S_SELECT,d1		;セレクションフェーズ
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;リトライ
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;ブロック数<<8
	swap.w	d4
	and.w	#$0007,d4		;LUN
	lsl.w	#5,d4			;LUN<<5
	or.w	#$2A00,d4		;($2A<<8)|(LUN<<5)
	move.l	d3,-(sp)		;0 ブロック数H L 0
	move.l	d2,-(sp)		;ブロック番号HH HL LH LL
	move.w	d4,-(sp)		;($2A<<8)|(LUN<<5)
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;コマンドアウトフェーズ
	bsr	scsicall
	lea.l	(10,sp),sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;バイト数
	movea.l	(4*4,sp),a1		;バッファの先頭アドレス(スタック注意)
	moveq.l	#_S_DATAOUT_P,d1	;データアウトフェーズ
	bsr	scsicall
	cmp.l	#-1,d0			;データアウトフェーズが-1を返したときは続行不可
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;ステータスインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;メッセージインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;データアウトフェーズが転送未完了のときは-2を返す
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_VERIFYEXT
;	DMA転送不可のときソフト転送に変更する
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないので自前で展開する
;<d2.l:ブロック番号
;<d3.l:ブロック数($0000=0～$FFFF=65535)
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;>d0.l:
;	-1		エラー
;	-2		エラー(データアウトフェーズにおけるDMA転送未完了)
;	下位ワード	ステータスインフェーズの結果
;	上位ワード	メッセージインフェーズの結果
	.text
	.align	4,$2048
scsidrvVerifyext::
	bsr	scsiCommandSplitter	;分割処理
;分割処理ルーチンによって以降の処理は複数回に分けて行われることがある
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;バイト数
	bsr	scsiDmaCheckOut
	movem.l	(sp)+,d3		;ccr保存
	bpl	scsicall		;バッファはDMA転送可能
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAMのソフト転送フラグが使える
	movem.l	d1-d4/a1,-(sp)		;スタック注意
	and.l	#$0000FFFF,d3
	beq	8f
	moveq.l	#_S_SELECT,d1		;セレクションフェーズ
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;リトライ
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;ブロック数<<8
	swap.w	d4
	and.w	#$0007,d4		;LUN
	lsl.w	#5,d4			;LUN<<5
	or.w	#$2F00,d4		;($2F<<8)|(LUN<<5)
	move.l	d3,-(sp)		;0 ブロック数H L 0
	move.l	d2,-(sp)		;ブロック番号HH HL LH LL
	move.w	d4,-(sp)		;($2F<<8)|(LUN<<5)
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;コマンドアウトフェーズ
	bsr	scsicall
	lea.l	(10,sp),sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;バイト数
	movea.l	(4*4,sp),a1		;バッファの先頭アドレス(スタック注意)
	moveq.l	#_S_DATAOUT_P,d1	;データアウトフェーズ
	bsr	scsicall
	cmp.l	#-1,d0			;データアウトフェーズが-1を返したときは続行不可
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;ステータスインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;メッセージインフェーズ
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;データアウトフェーズが転送未完了のときは-2を返す
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_MODESENSE
;	内蔵SCSI-BIOSは問題ないがMach-2がDMA転送を使おうとするのでパッチが必要
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないがDMA転送も使っていないのでそのままでよい
;<d2.l:bit0-5=ページコード
;	bit6-7=ページコントロール(0=カレント,1=変更可能,2=デフォルト,3=セーブ)
;<d3.l:バイト数($00=0～$FF=255)
;<d4.l:ターゲット
;<a1.l:バッファの先頭アドレス
scsidrvModesense	equ	scsidrvInquiry

;----------------------------------------------------------------
;_S_MODESELECT
;	内蔵SCSI-BIOSは問題ないがMach-2がDMA転送を使おうとするのでパッチが必要
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないがDMA転送も使っていないのでそのままでよい
;<d2.l:bit0=SP(0=保存しない,1=保存する),bit4=PF(0=SCSI-1,1=SCSI-2)
;<d3.l:バイト数($00=0～$FF=255)
;<d4.l:ターゲット
;<a1.l:バッファの先頭アドレス
	.text
	.align	4,$2048
scsidrvModeselect::
	bsr	scsiDmaCheckOut
	bpl	scsicall		;DMA転送可能
	bra	scsicallSoft

;----------------------------------------------------------------
;_S_REQUEST
;	内蔵SCSI-BIOSは問題ないがMach-2がDMA転送を使おうとするのでパッチが必要
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないがDMA転送も使っていないのでそのままでよい
;<d3.l:バイト数($00=0～$FF=255,0のときの挙動がSCSI-1とSCSI-2で異なる)
;<d4.l:ターゲット
;<a1.l:バッファの先頭アドレス
scsidrvRequest	equ	scsidrvInquiry

;----------------------------------------------------------------
;_S_REASSIGN
;	内蔵SCSI-BIOSは問題ないがMach-2がDMA転送を使おうとするのでパッチが必要
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないがDMA転送も使っていないのでそのままでよい
;<d3.l:バイト数($00=0～$FF=255)
;<d4.l:ターゲット
;<a1.l:バッファの先頭アドレス
scsidrvReassign	equ	scsidrvModeselect

;----------------------------------------------------------------
;_S_READDMA
;	DMA転送不可のときソフト転送に変更する
;	SUPERからXVICompactまでのX68000の内蔵SCSI-BIOSはSRAMのソフト転送フラグに
;	対応していないので自前で展開する
;<d2.l:ブロック番号($001FFFFF=2097151以下)
;<d3.l:ブロック数($0001=1～$0100=256)
;<d4.l:ターゲット
;<d5.l:ブロックのサイズ(0=256,1=512,2=1024)
;<a1.l:バッファの先頭アドレス
;>d0.l:
;	-1		エラー
;	-2		エラー(データインフェーズにおけるDMA転送未完了)
;	下位ワード	ステータスインフェーズの結果
;	上位ワード	メッセージインフェーズの結果
scsidrvReaddma	equ	scsidrvRead



;----------------------------------------------------------------
;
;	IOCS _PRNINTST(Mach-2対策)
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _PRNINTST
;	内蔵SCSIインタフェイスのMB89352のリセットコンディション割り込みがなぜか
;	$6Cではなく$63で入ってくることがあり、Mach-2と内蔵SCSIポートを繋いだ状態で
;	SCSIバスリセットをかけると白帯が出てしまう。そこで、Mach-2のSCSI-BIOSは
;	SCSIバスリセットの際にプリンタレディー割り込みベクタを変更して白帯が出ない
;	ように細工されている。変更されたベクタは$63EAxxxxとなって、次のようなコード
;	を指す。
;		move.b	$00E96029,$00E96029	;13F9 00E9 6029 00E9 6029
;		rte				;4E73
;	このコードは内蔵SCSIインタフェイスのMB89352のINTS(Interrupt Sense)レジスタを
;	クリアしているだけで、内蔵SCSI-BIOSのSCSI割り込みルーチンと同じ処理である。
;
;	X68030のROMはプリンタレディー割り込みベクタの使用状態を最上位バイトが0か
;	どうかで判別するので、書き換えられたベクタを未使用と認識する。しかし、
;	060turboのROMでは割り込みルーチンをハイメモリ領域に配置できるようにするために
;	ベクタの使用状態を32ビット全体でチェックするように変更されているため、
;	書き換えられたベクタを使用中と認識してしまう。その結果、060turboとMach-2を
;	併用するとプリンタレディー割り込みベクタを変更できなくなり、TeXシステムの
;	print.xなどが動作しなくなる。
;
;	$63はハイメモリのアドレスの最上位バイトと一致しないので、ベクタの最上位バイト
;	が$63かどうかで使用状態を判別するように変更することでMath-2を併用した場合に
;	_PRNINTSTが機能しなくなる問題を回避する。
;	これだけでは既にプリンタレディー割り込みを使用している状態でSCSIバスリセット
;	を行うとプリンタレディー割り込みベクタが破壊されてしまうが、それは_SCSIDRV側
;	で対処する。
;
;<a1.l:プリンタのレディー割り込み処理ルーチンのアドレス(0=解除)
;>d0.l:結果
;	0	正常終了
;	その他	使用中なので設定できない(現在の処理ルーチンのアドレス)
	.text
	.align	4,$2048
iocsPrnintst::
	move.l	a0,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr		;割り込み禁止
	moveq.l	#PRNINT>>2,d0
	lea.l	PRNINT.w,a0
	cmpa.w	#0,a1			;tst.l a1
	beq	1f			;解除する
	cmp.b	(a0),d0			;最上位バイトだけ比較する
	bne	2f			;使用中なので設定できない
;未使用なので設定する
	move.l	a1,(a0)			;設定する
	bset.b	#0,$00E9C001		;プリンタ割り込み許可
8:	moveq.l	#0,d0
9:	move.w	(sp)+,sr
	movea.l	(sp)+,a0
	rts

;解除する
1:	bclr.b	#0,$00E9C001		;プリンタ割り込み禁止
	move.l	#((PRNINT>>2)<<24)+defaultPrnint,(a0)	;解除する
	bra	8b

;使用中なので設定できない
2:	move.l	(a0),d0			;取得する
	bra	9b

;----------------------------------------------------------------
;デフォルトのプリンタレディー割り込み処理ルーチン
;	$00xxxxxxのアドレスに配置して$63000000を加えたベクタを設定する
	.text
	.align	4,$2048
defaultPrnint::
	rte				;何もしない

;白帯を出すとき
;	moveq.l	#$63,d7			;ベクタ番号
;	movea.l	sp,a6
;	trap	#14
;@@:	IOCS	_ABORTJOB
;	bra	@b

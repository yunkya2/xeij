;----------------------------------------------------------------
;
;	ADPCMとDMA転送のIOCSコール
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;
;	ADPCM関係のIOCSコール
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _ADPCMOUT
;$60 ADPCM再生
;<d1.w:サンプリング周波数と出力モード
;	bit0～bit1	出力モード
;				0	カット
;				1	左
;				2	右
;				3	左右
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
;<d2.l:再生するデータのバイト数
;<a1.l:バッファアドレス
	.align	4,$2048
iocsAdpcmout::
	movem.l	d0-d1/d3/a0-a1/a3,-(sp)
;動作終了を待つ
@@:	tst.b	$0C32.w
	bne	@b
	bsr	adpcmStartWait
	tst.l	d2
	beq	iocsAdpcmoutEnd		;サイズが0
	move.b	#$02,$0C32.w
;1番目のデータを用意する
	move.l	a1,adpcmDataPtr
	move.l	d2,adpcmLeftSize
	move.l	d2,d0
	bsr	dataTransfer0
;OCR
;	DIR	0	MAR→DAR
;	BTD	0	DONEなし
;	SIZE	11	パックなし,8bit
;	CHAIN	00	チェインなし
;	REQG	10	外部要求
;		 DIR BTD SIZE CHAIN REQG
	move.b	#%0___0___11____00___10,OCR3
	st.b	CSR3
	move.l	a3,MAR3
	move.w	d3,MTC3
;	d1.w		サンプリング周波数	原発振周波数	レート
;	$00xx		3.9KHz			4MHz		0
;	$01xx		5.2KHz			4MHz		1
;	$02xx		7.8KHz			8MHz		0
;	$03xx		10.4KHz			8MHz		1
;	$04xx		15.6KHz			8MHz		2
	move.b	$09DA.w,d0
	tas.b	d0			;4MHz
	cmp.w	#$0200,d1
	blo	@f
	sub.w	#$0200,d1
	and.b	#$7F,d0			;8MHz
@@:	move.b	d0,$09DA.w
	bsr	fmBusyWait
	move.b	#$1B,$00E90001		;FM音源アドレスポート
	bsr	fmBusyWait
	move.b	d0,$00E90003		;FM音源データポート
;PAN(0→3,1→1,2→2,3→0)
				;BA98|76543210 BA98|76543210 BA98|76543210 BA98|76543210
				;           __            __            __            __
				;..rr|......00 ..rr|......01 ..rr|......10 ..rr|......11
	ror.b	#2,d1		;..rr|00...... ..rr|01...... ..rr|10...... ..rr|11......
	not.b	d1		;..rr|11...... ..rr|10...... ..rr|01...... ..rr|00......
	rol.b	#1,d1		;..rr|1......1 ..rr|0......1 ..rr|1......0 ..rr|0......0
	lsl.w	#1,d1		;.rr1|......10 .rr0|......10 .rr1|......00 .rr0|......00
	ror.b	#2,d1		;.rr1|10...... .rr0|10...... .rr1|00...... .rr0|00......
	lsl.w	#1,d1		;rr11|0......0 rr01|0......0 rr10|0......0 rr00|0......0
				;  ~~            ~~            ~~            ~~
	move.b	$00E9A005,d1	;rr11|7654.... rr01|7654.... rr10|7654.... rr00|7654....
	lsr.w	#4,d1		;....|rr117654 ....|rr017654 ....|rr107654 ....|rr007654
	rol.b	#4,d1		;....|7654rr11 ....|7654rr01 ....|7654rr10 ....|7654rr00
				;           ~~            ~~            ~~            ~~
;転送開始
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	tst.l	adpcmLeftSize
	bne	1f
;継続しないとき
	move.l	#dmac3LastInterrupt,DMAC3NIV.w	;転送終了割り込み設定
;		 STR CNT HLT SAB INT
	move.b	#%1___0___0___0___1_000,CCR3	;転送開始,継続なし,割り込み発生
;再生開始
	move.b	d1,$00E9A005	;....|7654rr11 ....|7654rr01 ....|7654rr10 ....|7654rr00
	move.b	#$02,$00E92001
  .rept 8
	nop
  .endm
	bra	iocsAdpcmoutStarted

1:
;継続するとき
	move.l	#dmac3NormalInterrupt0,DMAC3NIV.w	;転送終了割り込み設定
;		 STR CNT HLT SAB INT
	move.b	#%1___1___0___0___1_000,CCR3	;転送開始,継続なし,割り込み発生
;再生開始
	move.b	d1,$00E9A005	;....|7654rr11 ....|7654rr01 ....|7654rr10 ....|7654rr00
	move.b	#$02,$00E92001
  .rept 8
	nop
  .endm
;2番目のデータを用意する
	move.l	adpcmLeftSize,d0
;	beq	iocsAdpcmoutEnd
	bsr	dataTransfer1
	move.l	a3,BAR3
	move.w	d3,BTC3
iocsAdpcmoutStarted:
	move.w	(sp)+,sr
iocsAdpcmoutEnd:
	movem.l	(sp)+,d0-d1/d3/a0-a1/a3
	rts

;----------------------------------------------------------------
;IOCS _ADPCMINP
;$61 ADPCM録音
;<d1.w:サンプリング周波数
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
;<d2.l:録音するデータのバイト数
;<a1.l:バッファアドレス
	.align	4,$2048
iocsAdpcminp::
	move.l	vectorOldIocsAdpcminp,-(sp)
	rts

;	move.b	#$04,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMAOT
;$62 アレイチェーンによるADPCM再生
;<d1.w:サンプリング周波数と出力モード
;	bit0～bit1	出力モード
;				0	カット
;				1	左
;				2	右
;				3	左右
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
;<d2.l:アレイチェーンテーブルの個数
;<a1.l:アレイチェーンテーブルの先頭アドレス
;	0000	.l	先頭アドレス
;	0004	.w	長さ
;	0006		次のテーブル
;	 ：		：
	.align	4,$2048
iocsAdpcmaot::
	move.l	vectorOldIocsAdpcmaot,-(sp)
	rts

;	move.b	#$12,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMAIN
;$63 アレイチェーンによるADPCM録音
;<d1.w:サンプリング周波数
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
;<d2.l:アレイチェーンテーブルの個数
;<a1.l:アレイチェーンテーブルの先頭アドレス
;	0000	.l	先頭アドレス
;	0004	.w	長さ
;	0006		次のテーブル
;	 ：		：
	.align	4,$2048
iocsAdpcmain::
	move.l	vectorOldIocsAdpcmain,-(sp)
	rts

;	move.b	#$14,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMLOT
;$64 リンクアレイチェーンによるADPCM再生
;<d1.w:サンプリング周波数と出力モード
;	bit0～bit1	出力モード
;				0	カット
;				1	左
;				2	右
;				3	左右
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
;<a1.l:リンクアレイチェーンテーブルの先頭アドレス
;	0000	.l	先頭アドレス
;	0004	.w	長さ
;	0006	.l	次のテーブルアドレス(0=終わり)
	.align	4,$2048
iocsAdpcmlot::
	move.l	vectorOldIocsAdpcmlot,-(sp)
	rts

;	move.b	#$22,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMLIN
;$65 リンクアレイチェーンによるADPCM録音
;<d1.w:サンプリング周波数
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
;<a1.l:リンクアレイチェーンテーブルの先頭アドレス
;	0000	.l	先頭アドレス
;	0004	.w	長さ
;	0006	.l	次のテーブルアドレス(0=終わり)
	.align	4,$2048
iocsAdpcmlin::
	move.l	vectorOldIocsAdpcmlin,-(sp)
	rts

;	move.b	#$24,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMSNS
;$66 ADPCMの実行モードセンス
;>d0.l:ADPCMの実行モード
;	$00	何もしていない
;	$02	出力中(_ADPCMOUT実行中)
;	$04	入力中(_ADPCMINP実行中)
;	$12	アレイチェーンによる出力中(_ADPCMAOT実行中)
;	$14	アレイチェーンによる入力中(_ADPCMAIN実行中)
;	$22	リンクアレイチェーンによる出力中(_ADPCMLOT実行中)
;	$24	リンクアレイチェーンによる入力中(_ADPCMLIN実行中)
	.align	4,$2048
iocsAdpcmsns::
	moveq.l	#$7F,d0
	and.b	$0C32.w,d0
	rts

;----------------------------------------------------------------
;IOCS _ADPCMMOD
;$67 ADPCMの実行制御
;<d1.b:モード
;	0	終了
;	1	中止
;	2	再開
;>d0.l:エラーコード
;	0	正常終了
;	-1	パラメータがおかしい
	.align	4,$2048
iocsAdpcmmod::
	move.l	vectorOldIocsAdpcmmod,-(sp)
	rts

;----------------------------------------------------------------
;DMAC3の初期化
	.align	4,$2048
dmac3Initialize::
;DCR3
;	XRM	10	ホールドなし,サイクルスチール
;	DTYP	00	68000バスタイプ
;	DPS	0	8とポート
;	PCL	00	ステータス入力
;		 XRM DTYP DPS   PCL
	move.b	#%10__00___0__0_00,DCR3
;SCR
;	MAC	01	インクリメント
;	DAC	00	そのまま
;		      MAC DAC
	move.b	#%0000_01_00,SCR3
;MFC
;	FC	101	スーパーバイザデータ
	move.b	#%00000_101,MFC3
;CPR
;	CP	01	2番目に高い優先度
	move.b	#%000000_01,CPR3
;DFC
;	FC	101	スーパーバイザデータ
	move.b	#%00000_101,DFC3
;BFC
;	FC	101	スーパーバイザデータ
	move.b	#%00000_101,BFC3
	move.b	#DMAC3NIV/4,NIV3
	move.b	#DMAC3EIV/4,EIV3
	move.l	#$00E92003,DAR3
	move.l	#dmac3ErrorInterrupt,DMAC3EIV.w
	rts

;----------------------------------------------------------------
;バッファ0の転送終了割り込み
;バッファ1の転送が開始されているので,次のデータをバッファ0に用意して継続し,
;バッファ1の転送終了を待つ
	.align	4,$2048
dmac3NormalInterrupt0:
	ori.w	#$0700,sr
	movem.l	d0/d3/a0-a1/a3,-(sp)
	move.l	adpcmLeftSize,d0
	beq	dmac3InterruptDone
	bsr	dataTransfer0
	lea.l	(dmac3NormalInterrupt1,pc),a0
	bra	dmac3InterruptContinue

;バッファ1の転送終了割り込み
;バッファ0の転送が開始されているので,次のデータをバッファ1に用意して継続し,
;バッファ0の転送終了を待つ
	.align	4,$2048
dmac3NormalInterrupt1:
	ori.w	#$0700,sr
	movem.l	d0/d3/a0-a1/a3,-(sp)
	move.l	adpcmLeftSize,d0
	beq	dmac3InterruptDone
	bsr	dataTransfer1
	lea.l	(dmac3NormalInterrupt0,pc),a0
dmac3InterruptContinue:
	tst.b	CSR3
	st.b	CSR3
	move.l	a0,DMAC3NIV.w
	move.l	a3,BAR3
	move.w	d3,BTC3
;		 STR CNT HLT SAB INT
	move.b	#%0___1___0___0___1_000,CCR3	;転送継続,割り込み発生
  .rept 8
	nop
  .endm
  debug '(adpcmLeftSize,adpcmDataPtr,a3,d3)=',4,adpcmLeftSize,adpcmDataPtr,a3,d3
	movem.l	(sp)+,d0/d3/a0-a1/a3
	rte

;最後の転送が開始されているので,次回の割り込みで終了する
dmac3InterruptDone:
	move.l	#dmac3LastInterrupt,DMAC3NIV.w
	movem.l	(sp)+,d0/d3/a0-a1/a3
	rte

;----------------------------------------------------------------
;DMAC3エラー割り込み
;ADPCMを停止してから転送を中止する
	.align	4,$2048
dmac3LastInterrupt:
dmac3ErrorInterrupt:
	move.b	CER3,$0C33.w		;DMAC3エラーコード
	move.b	#$01,$00E9A007		;ADPCM動作停止
	move.b	#$03,$00E9A007
	move.b	#$01,$00E92001
	tst.b	CSR3			;DMAC3動作停止
	st.b	CSR3
	clr.b	$0C32.w			;IOCSコールによる転送終了
	rte

;----------------------------------------------------------------
;バッファ0のデータを用意する
;<d0.l:残りサイズ(adpcmLeftSize,0以外)
;>d3.w:DMAC3の転送サイズ
;>a3.l:DMAC3の転送アドレス
;*d3/a3
;?d0/a0-a1
	.align	4,$2048
dataTransfer0:
	movea.l	adpcmBufferPtr0,a0	;16の倍数
	bra	dataTransfer

;バッファ1のデータを用意する
;<d0.l:残りサイズ(adpcmLeftSize,0以外)
;>d3.w:DMAC3の転送サイズ
;>a3.l:DMAC3の転送アドレス
;*d3/a3
;?d0/a0-a1
	.align	4,$2048
dataTransfer1:
	movea.l	adpcmBufferPtr1,a0	;16の倍数
dataTransfer:
  debug 'dataTransfer in(adpcmLeftSize,adpcmDataPtr)=',2,adpcmLeftSize,adpcmDataPtr
	cmp.l	adpcmBufferSize,d0
	bls	@f
	move.l	adpcmBufferSize,d0
@@:	sub.l	d0,adpcmLeftSize
	move.l	a0,a3
	move.w	d0,d3
	movea.l	adpcmDataPtr,a1
	move.l	a1,d0
	ror.l	#4,d0			;d0.lの上位4bitはa1の下位4bit
	move.w	d3,d0			;d0.lの下位ワードはDMAC3の転送サイズ
					;1:で転送サイズが必要なのでわざと合成した

	btst.b	#2,$0C32.w
	beq	@f
	exg.l	a0,a1			;入力の時は逆向きに転送する
@@:

	cmp.l	#$10000000,d0
	bcc	8f			;先頭が16の倍数でない
	cmpi.b	#4,$0CBC.W
	blo	8f

	sub.w	#16,d0
	bcs	1f			;サイズが16未満
@@:	move16	(a1)+,(a0)+
	sub.w	#16,d0
	bcc	@b
1:	add.w	#16,d0
	beq	9f			;サイズが16の倍数だった

8:

	subq.w	#4,d0
	bcs	2f			;サイズが4未満
@@:	move.l	(a1)+,(a0)+
	subq.w	#4,d0
	bcc	@b
2:	addq.w	#4,d0
	beq	9f			;サイズが4の倍数だった

@@:	move.b	(a1)+,(a0)+
	subq.w	#1,d0
	bne	@b

9:	move.l	a1,adpcmDataPtr
  debug 'dataTransfer out(adpcmLeftSize,adpcmDataPtr,a3,d3)=',4,adpcmLeftSize,adpcmDataPtr,a3,d3
	rts

;----------------------------------------------------------------
;FM音源のビジーフラグがクリアされるまで待つ
;サブルーチンにしないと速すぎる可能性がある
	.align	4,$2048
fmBusyWait:
@@:	tst.b	$00E90003
	bmi	@b
	rts

;----------------------------------------------------------------
;ADPCMのサンプリング周波数に応じたウェイト
;<d1.w:サンプリング周波数
;	bit8～bit14	サンプリング周波数
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		ウェイトフラグ
;				0	サンプリング周波数に応じてウェイトを入れる
;				1	ウェイトを入れない
	.align	4,$2048
adpcmStartWait:
	tst.w	d1
	bmi	@f
	move.w	d1,-(sp)
	lsr.w	#8,d1
	and.w	#7,d1
	moveq.l	#0,d0
	move.b	(adpcmStartWaitTable,pc,d1.w),d0
	bsr	wait50Micro
	move.w	(sp)+,d1
@@:	and.w	#$7FFF,d1
	rts

adpcmStartWaitTable:
	.dc.b	$0A			;500μs 0(3.9KHz)
	.dc.b	$08			;400μs 1(5.2KHz)
	.dc.b	$05			;250μs 2(7.8KHz)
	.dc.b	$04			;200μs 3(10.4KHz)
	.dc.b	$03			;150μs 4(15.6KHz)
	.dc.b	$00,$00,$00

;----------------------------------------------------------------
;50μs単位のウェイト
;<d0.l:待ち時間(50μs単位)
	.align	4,$2048
wait50Micro:
	movem.l	d0-d2/a0,-(sp)
	lea.l	$00E88023,a0		;MFP TCDR
	moveq.l	#0,d1
	move.b	(a0),d1
	move.b	(a0),d1
1:	moveq.l	#0,d2
	move.b	(a0),d2
	cmp.b	(a0),d2
	bcs	1b
	sub.w	d2,d1
	bcc	2f
	add.w	#200,d1
2:	exg.l	d1,d2
	sub.l	d2,d0
	bhi	1b
	movem.l	(sp)+,d0-d2/a0
	rts

;----------------------------------------------------------------
;
;	DMA転送関係のIOCSコール
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _DMAMOVE
;$8A DMA転送
;<d1.b:モード
;	bit0～bit1	a2のモード
;				0	カウントしない
;				1	インクリメント
;				2	デクリメント
;				3	禁止
;	bit2～bit3	a1のモード
;				0	カウントしない
;				1	インクリメント
;				2	デクリメント
;				3	禁止
;	bit7		転送方向
;				0	a1からa2へ
;				1	a2からa1へ
;<d2.l:転送データのバイト数
;<a1.l:転送元アドレス
;<a2.l:転送先アドレス
;?d0/d2/a1-a2
	.align	4,$2048
iocsDmamove::
	tst.l	d2
	beq	9f
	moveq.l	#$0F,d0
	and.b	d1,d0
	tst.b	d1
	bmi	@f
	jmp	([iocsDmamoveTable0,pc,d0.l*4])

@@:	exg.l	a1,a2
	jmp	([iocsDmamoveTable1,pc,d0.l*4])

9:	rts

;(a1),(a2)
	.align	4,$2048
iocsDmamoveTable0:
	.dc.l	iocsDmamove00	;(a1),(a2)
	.dc.l	iocsDmamove01	;(a1),(a2)+
	.dc.l	iocsDmamove02	;(a1),(a2)-
	.dc.l	iocsDmamove03
	.dc.l	iocsDmamove10	;(a1)+,(a2)
	.dc.l	iocsDmamove11	;(a1)+,(a2)+
	.dc.l	iocsDmamove12	;(a1)+,(a2)-
	.dc.l	iocsDmamove13
	.dc.l	iocsDmamove20	;(a1)-,(a2)
	.dc.l	iocsDmamove21	;(a1)-,(a2)+
	.dc.l	iocsDmamove22	;(a1)-,(a2)-
	.dc.l	iocsDmamove23
	.dc.l	iocsDmamove30
	.dc.l	iocsDmamove31
	.dc.l	iocsDmamove32
	.dc.l	iocsDmamove33

;(a2),(a1)
	.align	4,$2048
iocsDmamoveTable1:
	.dc.l	iocsDmamove00	;(a2),(a1)
	.dc.l	iocsDmamove10	;(a2)+,(a1)
	.dc.l	iocsDmamove20	;(a2)-,(a1)
	.dc.l	iocsDmamove30
	.dc.l	iocsDmamove01	;(a2),(a1)+
	.dc.l	iocsDmamove11	;(a2)+,(a1)+
	.dc.l	iocsDmamove21	;(a2)-,(a1)+
	.dc.l	iocsDmamove31
	.dc.l	iocsDmamove02	;(a2),(a1)-
	.dc.l	iocsDmamove12	;(a2)+,(a1)-
	.dc.l	iocsDmamove22	;(a2)-,(a1)-
	.dc.l	iocsDmamove32
	.dc.l	iocsDmamove03
	.dc.l	iocsDmamove13
	.dc.l	iocsDmamove23
	.dc.l	iocsDmamove33

	.align	4,$2048
iocsDmamove00:	;(a1),(a2)/(a2),(a1)
iocsDmamove03:
iocsDmamove30:
iocsDmamove33:
@@:	move.b	(a1),(a2)
	subq.l	#1,d2
	bne	@b
	rts

	.align	4,$2048
iocsDmamove01:	;(a1),(a2)+/(a2),(a1)+
iocsDmamove31:
@@:	move.b	(a1),(a2)+
	subq.l	#1,d2
	bne	@b
	rts

	.align	4,$2048
iocsDmamove02:	;(a1),(a2)-/(a2),(a1)-
iocsDmamove32:
	addq.l	#1,a2
@@:	move.b	(a1),-(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a2
	rts

	.align	4,$2048
iocsDmamove10:	;(a1)+,(a2)/(a2)+,(a1)
iocsDmamove13:
@@:	move.b	(a1)+,(a2)
	subq.l	#1,d2
	bne	@b
	rts

	.align	4,$2048
iocsDmamove11:	;(a1)+,(a2)+/(a2)+,(a1)+
;	tst.l	d2
;	beq	9f
	cmp.l	#$00000010,d2
	blo	iocsDmamove11notLine
	move.l	a1,d0
	move.l	a2,d1
	eor.l	d1,d0
	and.l	#$0000000F,d0
	bne	iocsDmamove11notLine
	cmpi.b	#4,$0CBC.W
	blo	iocsDmamove11notLine
;先頭アドレスの下位4bitが共通
	and.l	#$0000000F,d1		;先頭アドレスの下位4bit(a1とa2で共通)
	beq	@f			;ラインの先頭
	move.l	d2,d0
	moveq.l	#16,d2
	sub.l	d1,d2			;次のラインの先頭までのバイト数
					;この値は15以下,転送バイト数は16以上なので,
					;余計に転送してしまう心配はない
	sub.l	d2,d0			;残り
	bsr	iocsDmamove11notLine
	move.l	d0,d2			;d2復元
@@:	sub.l	#16,d2
	blo	2f
1:	move16	(a1)+,(a2)+
	sub.l	#16,d2
	bhi	1b
2:	add.l	#16,d2
	beq	9f
iocsDmamove11notLine:
	subq.l	#4,d2
	blo	2f
1:	move.l	(a1)+,(a2)+
	subq.l	#4,d2
	bhi	1b
2:	addq.l	#4,d2
	beq	9f
@@:	move.b	(a1)+,(a2)+
	subq.l	#1,d2
	bne	@b
9:	rts

	.align	4,$2048
iocsDmamove12:	;(a1)+,(a2)-/(a2)+,(a1)-
	addq.l	#1,a2
@@:	move.b	(a1)+,-(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a2
	rts

	.align	4,$2048
iocsDmamove20:	;(a1)-,(a2)/(a2)-,(a1)
iocsDmamove23:
	addq.l	#1,a1
@@:	move.b	-(a1),(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a1
	rts

	.align	4,$2048
iocsDmamove21:	;(a1)-,(a2)+/(a2)-,(a1)+
	addq.l	#1,a1
@@:	move.b	-(a1),(a2)+
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a1
	rts

	.align	4,$2048
iocsDmamove22:	;(a1)-,(a2)-/(a2)-,(a1)-
	addq.l	#1,a1
	addq.l	#1,a2
@@:	move.b	-(a1),-(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a1
	subq.l	#1,a2
	rts

;----------------------------------------------------------------
;IOCS _DMAMOV_A
;$8B アレイチェーンによるDMA転送
;<d1.b:モード
;	bit0～bit1	a2のモード
;				0	カウントしない
;				1	インクリメント
;				2	デクリメント
;				3	禁止
;	bit2～bit3	a1のモード
;				0	カウントしない
;				1	インクリメント
;				2	デクリメント
;				3	禁止
;	bit7		転送方向
;				0	a1からa2へ
;				1	a2からa1へ
;<d2.l:アレイチェーンテーブルの個数
;<a1.l:転送元アレイチェーンテーブルの先頭アドレス
;	0000	.l	先頭アドレス
;	0004	.w	長さ
;	0006		次のテーブル
;	 ：		：
;<a2.l:転送先アドレス
	.align	4,$2048
iocsDmamovA::
	move.l	d3,-(sp)
	move.l	d2,d3
	beq	9f
	move.l	a4,-(sp)
	move.l	a3,-(sp)
	moveq.l	#$0F,d0
	and.b	d1,d0
	tst.b	d1
	bmi	3f
	movea.l	(iocsDmamoveTable0,pc,d0.l*4),a4
	movea.l	a1,a3
1:	movea.l	(a3)+,a1
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	subq.l	#1,d3
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
9:	move.l	(sp)+,d3
	rts

3:	movea.l	(iocsDmamoveTable1,pc,d0.l*4),a4
	movea.l	a1,a3
	movea.l	a2,a1
1:	movea.l	(a3)+,a2
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	subq.l	#1,d3
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;IOCS _DMAMOV_L
;$8C リンクアレイチェーンによるDMA転送
;<d1.b:モード
;	bit0～bit1	a2のモード
;				0	カウントしない
;				1	インクリメント
;				2	デクリメント
;				3	禁止
;	bit2～bit3	a1のモード
;				0	カウントしない
;				1	インクリメント
;				2	デクリメント
;				3	禁止
;	bit7		転送方向
;				0	a1からa2へ
;				1	a2からa1へ
;<a1.l:転送元リンクアレイチェーンテーブルの先頭アドレス
;	0000	.l	先頭アドレス
;	0004	.w	長さ
;	0006	.l	次のテーブルアドレス(0=終わり)
;<a2.l:転送先アドレス
	.align	4,$2048
iocsDmamovL::
	move.l	a4,-(sp)
	move.l	a3,-(sp)
	moveq.l	#$0F,d0
	and.b	d1,d0
	tst.b	d1
	bmi	3f
	movea.l	(iocsDmamoveTable0,pc,d0.l*4),a4
	move.l	a1,d0
1:	movea.l	d0,a3
	movea.l	(a3)+,a1
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	move.l	(a3)+,d0
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
	rts

3:	movea.l	(iocsDmamoveTable1,pc,d0.l*4),a4
	move.l	a1,d0
	movea.l	a2,a1
1:	movea.l	d0,a3
	movea.l	(a3)+,a2
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	move.l	(a3)+,d0
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
	rts

;----------------------------------------------------------------
;IOCS _DMAMODE
;$8D DMA転送中モードの取得
;パラメータなし
;>d0.l:DMA転送中モード
;	0		転送中ではない
;	_DMAMOVE	_DMAMOVEで転送中
;	_DMAMOV_A	_DMAMOV_Aで転送中
;	_DMAMOV_L	_DMAMOV_Lで転送中
	.align	4,$2048
iocsDmamode::
	moveq.l	#0,d0
	rts

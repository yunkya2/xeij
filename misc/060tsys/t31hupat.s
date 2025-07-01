;----------------------------------------------------------------
;
;	Humanのパッチ
;
;----------------------------------------------------------------

	.include	t02const.equ

	.cpu	68060

;----------------------------------------------------------------
;Human302にパッチをあてられるかどうかチェックする
;>d0.l:0=成功,-1=失敗
;>n-flag:pl=成功,mi=失敗
patchCheckHuman302::
	move.l	a0,-(sp)
	lea.l	(human302Patch,pc),a0
	bsr	patchCheck
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;Human302にパッチをあてる
;>d0.l:0=成功,-1=失敗
;>n-flag:pl=成功,mi=失敗
patchHuman302::
	move.l	a0,-(sp)
	lea.l	(human302Patch,pc),a0
	bsr	patch
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;パッチをあてられるかどうかチェックする
;<a0.l:パッチデータのアドレス
;>d0.l:0=成功,-1=失敗
;>n-flag:pl=成功,mi=失敗
patchCheck::
	movem.l	a1-a2,-(sp)
	movea.l	a0,a1
	move.l	(a1)+,d0
1:	movea.l	d0,a2			;パッチアドレス
	move.w	(a1)+,d1		;ワード数-1
2:	cmpm.w	(a1)+,(a2)+		;比較
	dbne	d1,2b
	bne	9f			;一致しないのでパッチをあてない
	move.w	(a1)+,d1		;ワード数-1
	lea.l	(2,a1,d1.w*2),a1	;新しい状態をスキップする
	move.l	(a1)+,d0
	bne	1b
8:	movem.l	(sp)+,a1-a2
	rts

9:
  .if 1
	lea.l	-64(sp),sp
	movea.l	sp,a0
	lea.l	100f(pc),a1
	bsr	strcpy
	move.l	a2,d0
	subq.l	#2,d0
	bsr	hex8
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	movea.l	sp,a1
	bsr	print
	lea.l	64(sp),sp
  .endif
	moveq.l	#-1,d0
	bra	8b

  .if 1
100:	.dc.b	'patchCheck failed at ',0
	.even
  .endif

;----------------------------------------------------------------
;パッチをあてる
;<a0.l:パッチデータのアドレス
;>d0.l:0=成功,-1=失敗
;>n-flag:pl=成功,mi=失敗
patch::
	movem.l	d1/a1-a2,-(sp)
	PUSH_SR_DI
	bsr	patchCheck
	bmi	8f
	movea.l	a0,a1
	move.l	(a1)+,d0
1:	movea.l	d0,a2			;パッチアドレス
	move.w	(a1)+,d1
	lea.l	(2,a1,d1.w*2),a1	;元の状態をスキップする
	move.w	(a1)+,d1		;ワード数
2:	move.w	(a1)+,(a2)+		;変更
	dbra	d1,2b
	move.l	(a1)+,d0
	bne	1b
	CACHE_FLUSH	d1
8:	POP_SR
	movem.l	(sp)+,d1/a1-a2
	tst.l	d0
	rts

;----------------------------------------------------------------
;
;	Human302のパッチデータ(非常駐部)
;
;----------------------------------------------------------------
;Human302にパッチをあてる前の状態
;	改造チェックと元に戻すときに使うので、
;	パッチデータ以上のサイズのコードを記述する必要がある
;Human302にパッチをあてた後の状態
;	パッチデータは確実かつ必要最小限にとどめる
;	元に戻すときはチェックの前にリロケートしておく必要がある
;
;パッチルーチンにジャンプするのでなければ変更前と変更後のサイズを合わせること
;
;MOVE from SRはF-Lineと特権違反で吸収されるのでパッチする必要がない

human302Patch::
	.dc.l	$000068FE
	.dc.w	(2f-1f)/2-1
1:	bsr.w	(*)-$000068FE+$00006A96	;スーパーバイザ領域設定
	pea.l	$00008566.l		;アボートベクタ設定
2:
	.dc.w	(2f-1f)/2-1
1:	jsr	human302_superarea.l
	pea.l	((*)-$00006904+$00008566,pc)
2:

;_EXEC	[3]実行ファイルの形式指定
	.dc.l	$00009510
	.dc.w	(2f-1f)/2-1
1:	bsr.w	(*)-$9510+$997C
	cmp.b	#'x',d0
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_exec3pat
2:

;_EXEC	[0][1]実行ファイルの形式指定
	.dc.l	$0000961A
	.dc.w	(2f-1f)/2-1
1:	move.l	a1,$1CB2.w
	bsr.w	(*)-$961E+$997C
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_exec01pat
2:

;_PSPSETの追加
	.dc.l	$0000938C
	.dc.w	(2f-1f)/2-1
1:	add.l	a0,d3
	add.l	#$00000100,d3
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_makePsp
2:

;_EXECの実行前の処理
	.dc.l	$0000967E
	.dc.w	(2f-1f)/2-1
1:	bsr.w	(*)-$967E+$98A0		;bss+comm+stackを0で初期化する
	move.b	#-3,$1CA0.w		;_EXECの動作レベル
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_execMakePsp
2:

;_EXEC	スーパーバイザモード選択
	.dc.l	$00009748
	.dc.w	(2f-1f)/2-1
1:	and.l	#$00FFFFFF,D0
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_execsuperpat
2:

  .if 0
;68030のときXEiJのパッチと衝突する
;_EXEC	アロケートモードチェックのバグ
	.dc.l	$000099C4
	.dc.w	(2f-1f)/2-1
1:	btst.l	#1,d1
2:
	.dc.w	(2f-1f)/2-1
1:	btst.l	#0,d1
2:
  .endif

;_KEEPPR	常駐フラグの設定
	.dc.l	$0000A064
	.dc.w	(2f-1f)/2-1
1:	ori.l	#$FF000000,(4,a0)
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_keeppr
2:

;_FATCHK	拡張モードビットの除去
	.dc.l	$0000B162
	.dc.w	(2f-1f)/2-1
1:	and.l	#$00FFFFFF,d6
2:
	.dc.w	(2f-1f)/2-1
1:	and.l	#$7FFFFFFF,d6
2:

;デバイスドライバの呼び出し
	.dc.l	$0000DEFA
	.dc.w	(2f-1f)/2-1
1:	cmpi.b	#1,$0CBC.w
2:
	.dc.w	(2f-1f)/2-1
1:
patchHumanCallDevice::
	jmp	callDevice		;RAMDISKがないときはcallDeviceNoRamdiskに変更
2:

;デバイスドライバから復帰した直後のキャッシュの復元
;(060turbo.sysから戻ったときだけ使用される)
	.dc.l	$0000DF38
	.dc.w	(2f-1f)/2-1
1:	moveq.l	#$04,d1			;キャッシュの設定
2:
	.dc.w	(2f-1f)/2-1
1:	moveq.l	#$02,d1			;キャッシュをSRAM設定値に初期化
2:

;バスエラーチェック
	.dc.l	$0000E28A
	.dc.w	(2f-1f)/2-1
1:	move.w	sr,-(sp)
	ori.w	#$0700,sr
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_buserr
2:

;DISK2HDデバイスドライバの処理ルーチンの取得と設定
	.dc.l	$00010A20
	.dc.w	(2f-1f)/2-1
1:	move.w	(a6)+,(a4)+
	dbra.w	d0,1b
2:
	.dc.w	(2f-1f)/2-1
1:	jsr	human302_disk2hd_jmp
2:

	.dc.l	0

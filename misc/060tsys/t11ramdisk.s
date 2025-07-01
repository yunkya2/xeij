;----------------------------------------------------------------
;
;	RAMDISKドライバ
;
;----------------------------------------------------------------

	.cpu	68060

;----------------------------------------------------------------
;RAMDISKドライバの転送速度に関するメモ
;	68060は奇数番地のロングワード転送が可能だがキャッシュがミスすると非常に遅くなる
;	キャッシュ可でもキャッシュが溢れるときはコピーバックよりもライトスルーの方が速い
;	move16は転送前後のアドレスの下位4ビットが一致している必要がある
;	move16はキャッシュモードによらず転送速度が一定
;		move16の読み出しはコピーバックキャッシュのダーティデータも読み出せる
;		move16の書き込みはデータキャッシュにもライトアロケートされる
;		つまりコピーバック領域のアクセスにmove16を混ぜても問題は生じない
;	大量転送の所要時間
;		wt,cbでキャッシュがヒットするとき
;			move<movem<move16
;		wt,cbでキャッシュがヒットしないとき
;			move16<move<movem
;		is,psのとき
;			move16<movem<move
;		move,movemのとき
;			wt<cb<is<ps
;		move16のとき
;			wt=cb=is=ps
;	RAMDISK領域をキャッシュ可にするのはデータキャッシュを食い潰すだけで無意味
;	RAMDISK領域はキャッシュ不可にしてmove16で転送するのが望ましい
;	move16が使えなければライトスルーにしてmoveで転送するのが望ましい
;
;	requestHeaderは設定されていない場合があるので使わないこと

;----------------------------------------------------------------
;メディアチェック
;<a5.l:リクエストヘッダ
deviceCheck::
	move.b	(1,a5),d0		;ユニット番号
	bsr	mediaCheck
	sne.b	(14,a5)			;0=正常,-1=壊れている
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;状態取得
;<a5.l:リクエストヘッダ
deviceSense::
	move.b	(1,a5),d0
	bsr	mediaCheck
	bne	1f
;		   イジェクト禁止
;		   |
;		   |
;		   |  プロテクト
;		   |  |レディ
;		   |  ||メディア挿入
;		   |  |||誤挿入
;		   |  ||||
	move.b	#%01000010,(13,a5)
	bra	2f
1:	move.b	#%01000100,(13,a5)
2:	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;メディアチェックルーチン
;	RAMDISK.SYSと同じく先頭の3バイトだけチェックしている
;	本当はもっと厳密に調べたほうがよい
;<d0.b:ユニット番号
;>d0.w:ユニット番号
;>z-flag:eq=OK,ne=ERROR
;*d0
mediaCheck::
	move.l	a0,-(sp)
	ext.w	d0
	movea.l	([bpbTablePointer,d0.w*4],16),a0
	cmpi.w	#$F9FF,(a0)+
	bne	@f
	cmpi.b	#$FF,(a0)
@@:	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;壊れていて入出力できないとき
mediaError:
	move.w	#$5007,d0
	rts

;----------------------------------------------------------------
;出力
;	出力のときはメディアチェックをしてエラーを出してはならない
;	(フォーマットできなくなるので)
;<a5.l:リクエストヘッダ
deviceOutput::
	movem.l	d1-d2/a0-a3,-(sp)
	move.l	(14,a5),d0		;バッファの先頭
;<d0.l:バッファの先頭
	cmpi.b	#4,$0CBC.W
	blo	@f
	lea.l	(outputMove16,pc),a0
	moveq.l	#$0F,d2
	and.l	d0,d2
	beq	transfer
@@:	lea.l	(outputMove,pc),a0
	bra	transfer

;----------------------------------------------------------------
;入力
;<a5.l:リクエストヘッダ
deviceInput::
	move.b	(1,a5),d0
	bsr	mediaCheck
	bne	mediaError		;壊れている
	movem.l	d1-d2/a0-a3,-(sp)
	move.l	(14,a5),d0		;バッファの先頭
;<d0.l:バッファの先頭
	cmpi.b	#4,$0CBC.W
	blo	@f
	lea.l	(inputMove16,pc),a0
	moveq.l	#$0F,d2
	and.l	d0,d2
	beq	transfer
@@:	lea.l	(inputMove,pc),a0
;	bra	transfer
;----------------------------------------------------------------
;転送ルーチン
;<d0.l:バッファの先頭
;<a5.l:リクエストヘッダ
transfer:
	movea.l	d0,a2
;<a2.l:バッファの先頭
	moveq.l	#0,d0
	move.b	(1,a5),d0		;ユニット番号
	movea.l	(bpbTablePointer,d0.l*4),a3	;BPBテーブルのアドレス
	bsr	toggleAccessLamp	;アクセスランプ反転
;<a1.l:BPBテーブルのアドレス
	move.l	(18,a5),d0
;<d0.l:転送セクタ数
	move.l	d0,d1
;<d1.l:転送セクタ数
	move.l	(22,a5),d2
;<d2.l:先頭のセクタ番号
	add.l	d2,d1
;<d1.l:末尾のセクタ番号+1
	cmp.l	(12,a3),d1
	bhi	sectorError		;範囲外
	lsl.l	#8,d2
	lsl.l	#2,d2
;<d2.l:先頭のセクタまでのオフセット
	movea.l	(16,a3),a1		;先頭アドレス
	adda.l	d2,a1
;<a1.l:先頭のセクタのアドレス
	jsr	(a0)			;転送
	moveq.l	#0,d0
transferError:
	bsr	toggleAccessLamp	;アクセスランプ反転
	movem.l	(sp)+,d1-d2/a0-a3
	rts

;セクタ番号の指定がおかしい
sectorError:
	move.w	#$5008,d0
	bra	transferError

;----------------------------------------------------------------
;アクセスランプ反転
;<a3.l:BPBテーブルのアドレス
toggleAccessLamp:
	tst.b	(24,a3)
	beq	@f
	bset.b	#0,$00E8A01B		;TIMER-LED反転
	eori.b	#%00000111,$00E8A001	;
@@:	rts

;----------------------------------------------------------------
;出力(バッファアドレスの下位4bitが0)
outputMove16:
	exg.l	a1,a2
;	bra	transferMove16
;----------------------------------------------------------------
;入力(バッファアドレスの下位4bitが0)
inputMove16:
;	bra	transferMove16
;----------------------------------------------------------------
;入出力(バッファアドレスの下位4bitが0)
;<d0.l:転送セクタ数
;<a1.l:転送元アドレス(下位4bitが0)
;<a2.l:転送先アドレス(下位4bitが0)
transferMove16:
@@:	moveq.l	#4-1,d1
1:	.rept	16
	move16	(a1)+,(a2)+
	.endm
	dbra	d1,1b
	subq.l	#1,d0
	bne	@b
	rts

;----------------------------------------------------------------
;出力(バッファアドレスの下位4bitが0でない)
outputMove:
	exg.l	a1,a2
;	bra	transferMove
;----------------------------------------------------------------
;入力(バッファアドレスの下位4bitが0でない)
inputMove:
;	bra	transferMove
;----------------------------------------------------------------
;入出力(バッファアドレスの下位4bitが0でない)
;<d0.l:転送セクタ数
;<a1.l:転送元アドレス
;<a2.l:転送先アドレス
transferMove:
@@:	moveq.l	#16-1,d1
1:	.rept	16
	move.l	(a1)+,(a2)+
	.endm
	dbra	d1,1b
	subq.l	#1,d0
	bne	@b
	rts

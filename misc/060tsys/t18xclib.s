;----------------------------------------------------------------
;
;	XCのライブラリのハイメモリ対策
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ

	.cpu	68060

;「$00FFFFFE」→「$3FFFFFFE」
;「$00FFFFFF」→「$3FFFFFFF」
;「move.b #$FE,～」→「ori.b #$C0,～」
;「cmpi.b #$FE,～;beq ～」→「cmpi.b #$C0,～;bcc ～」
;「cmpi.b #$FE,～;bne ～」→「cmpi.b #$C0,～;bcs ～」

MARKER	equ	.notb.(LOGICAL_MASK>>24)	;$C0

;----------------------------------------------------------------
;ロードしたプログラムがXCのライブラリを使用していたらパッチをあてる
;	キャッシュを考慮していないので、後でプッシュと無効化を行うこと
;<a0.l:メモリ管理ポインタ
;<a1.l:末尾+1
;<a4.l:実行開始アドレス
patchXclib::
	movem.l	d0-d3/a2-a3,-(sp)
;実行開始位置の手前128バイト以内に'XCｺﾝﾊﾟｲﾗ'の文字列があるか
	lea.l	(-128,a4),a3
	moveq.l	#'X',d1
	moveq.l	#128-1,d2
@@:	cmp.b	(a3)+,d1
	dbeq	d2,@b
	bne	patchXclibEnd		;XCのライブラリではなさそう
	cmpi.w	#'Cｺ',(a3)		;奇数アドレスの可能性がある
	bne	@b
	cmpi.l	#'ﾝﾊﾟｲ',(2,a3)		;奇数アドレスの可能性がある
	bne	@b
	cmpi.b	#'ﾗ',(6,a3)
	bne	@b
;実行開始位置の直後から512バイト以内で_SETBLOCKまでの5個の$00FFFFFEを$3FFFFFFEに変更
	movea.l	a4,a3
	move.w	#512/2-1,d2
1:	cmp.w	#_SETBLOCK,(a3)
	beq	3f
	cmpi.l	#$00FFFFFE,(a3)
	bne	2f
	move.b	#LOGICAL_MASK>>24,(a3)	;$00FFFFFE→$3FFFFFFE
2:	addq.l	#2,a3
	dbra	d2,1b
3:
;MALLOCPの位置を確認する
;<a3.l:_SETBLOCKの位置
	lea.l	(22,a3),a3
	cmpi.w	#$23C8,(a3)+		;move.l a0,MALLOCP
	bne	patchXclibEnd		;改造されているのかも
	move.l	(a3),d3			;MALLOCP
;malloc(),free(),realloc()を修正する
;<d3.l:MALLOCP
;<a0.l:メモリ管理テーブル
	lea.l	(pProgram,a0),a3	;プログラムの先頭
	move.l	(pBssTop,a0),d2		;bssの先頭
	sub.l	a3,d2			;プログラムのバイト数
	lsr.l	#1,d2			;ワード数
	subq.l	#1,d2
	swap.w	d2
6:	swap.w	d2
5:	cmp.l	(a3),d3			;MALLOCPを検索する
	bne	2f
	move.l	(-4,a3),d0
;
	cmp.w	#$2279,d0		;movea.l MALLOCP,a1
	bne	3f
;movea.l MALLOCP,a1
	cmpi.l	#$157C_00FE,(-38,a3)	;move.b #$FE,(4,a2)
	bne	4f
	cmpi.w	#$0004,(-34,a3)		;
	bne	4f
;move.b #$FE,(4,a2)
;.ds.w 15
;movea.l MALLOCP,a1
;XC1のrealloc()の1番目のパッチ
	move.l	#$002A_0000+MARKER,(-38,a3)	;move→ori,$FE→MARKER
4:	cmpi.l	#$0C28_00FE,(-10,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(-6,a3)		;
	bne	4f
	cmpi.b	#$66,(-4,a3)		;bne
	bne	4f
;cmpi.b #$FE,(4,a0)
;bne.s
;movea.l MALLOCP,a1
;XC1,XC2のrealloc()の2番目のパッチ
	move.b	#MARKER,(-7,a3)		;$FE→MARKER
	move.b	#$65,(-4,a3)		;bne→bcs
	bra	2f

4:
3:	cmp.w	#$23CA,d0		;move.l a2,MALLOCP
	bne	3f
;move.l a2,MALLOCP
	cmpi.l	#$0C28_00FE,(14,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(18,a3)		;
	bne	4f
	cmpi.b	#$66,(20,a3)		;bne
	bne	4f
;move.l a2,MALLOCP
;.ds.w 5
;cmpi.b #$FE,(4,a0)
;bne
;XC1のmalloc()の2番目のパッチ
	move.b	#MARKER,(17,a3)		;$FE→MARKER
	move.b	#$65,(20,a3)		;bne→bcs
	bra	2f

4:	cmpi.l	#$0C28_00FE,(12,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(16,a3)		;
	bne	4f
	cmpi.b	#$67,(18,a3)		;beq
	bne	4f
;move.l a2,MALLOCP
;.ds.w 4
;cmpi.b #$FE,(4,a0)
;beq
;XC1,XC2のrealloc()の3番目のパッチ
	move.b	#MARKER,(15,a3)		;$FE→MARKER
	move.b	#$64,(18,a3)		;beq→bcc
4:	cmpi.l	#$C2BC_00FF,(50,a3)	;and.l #$00FFFFFF,d1
	bne	2f
	cmpi.w	#$FFFF,(54,a3)		;
	bne	2f
;move.l a2,MALLOCP
;.ds.w 23
;and.l #$00FFFFFF,d1
;XC1,XC2のrealloc()の4番目のパッチ
	move.b	#LOGICAL_MASK>>24,(52,a3)	;$00FFFFFFを$3FFFFFFFに変更
	bra	2f

3:	cmp.l	#$23EA_0000,d0		;move.l (0.w,a2),MALLOCP
	bne	3f
;move.l (0.w,a2),MALLOCP
	cmpi.l	#$0C28_00FE,(14,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(18,a3)		;
	bne	4f
	cmpi.b	#$66,(20,a3)		;bne
	bne	4f
;move.l (0.w,a2),MALLOCP
;.ds.w 5
;cmpi.b #$FE,(4,a0)
;bne
;XC2のmalloc()の2番目のパッチ
	move.b	#MARKER,(17,a3)		;$FE→MARKER
	move.b	#$65,(20,a3)		;bne→bcs
	bra	2f
4:
3:	cmp.w	#$2479,d0		;movea.l MALLOCP,a2
	bne	3f
;movea.l MALLOCP,a2
	cmpi.l	#$0C2A_00FE,(4,a3)	;cmpi.b #$FE,(4,a2)
	bne	4f
	cmpi.w	#$0004,(8,a3)		;
	bne	4f
	cmpi.b	#$67,(10,a3)		;beq
	bne	4f
;movea.l MALLOCP,a2
;cmpi.b #$FE,(4,a2)
;beq
;XC1,XC2のmalloc()の1番目のパッチ
	move.b	#MARKER,(7,a3)		;$FE→MARKER
	move.b	#$64,(10,a3)		;beq→bcc
	bra	2f
4:
3:	cmp.w	#$2879,d0		;movea.l MALLOCP,a4
	bne	3f
;movea.l MALLOCP,a4
	cmpi.l	#$16BC_00FE,(-6,a3)	;move.b #$FE,(a3)
	bne	4f
;move.b #$FE,(a3)
;movea.l MALLOCP,a4
;XC2のrealloc()の1番目のパッチ
	move.l	#$0013_0000+MARKER,(-6,a3)	;move→ori,$FE→MARKER
	bra	2f
4:
3:	cmp.w	#$43F9,d0		;lea.l MALLOCP,a1
	bne	3f
;lea.l MALLOCP,a1
	cmpi.l	#$157C_00FE,(-8,a3)	;move.b #$FE,(4,a2)
	bne	4f
	cmpi.w	#$0004,(-4,a3)		;
	bne	4f
;move.b #$FE,(4,a2)
;lea.l MALLOCP,a1
;XC1,XC2のfree()のパッチ
	move.l	#$002A_0000+MARKER,(-8,a3)	;move→or,$FE→MARKER
	bra	2f
4:
3:
2:	addq.l	#2,a3
	dbra	d2,5b
	swap.w	d2
	dbra	d2,6b
patchXclibEnd:
	movem.l	(sp)+,d0-d3/a2-a3
	rts

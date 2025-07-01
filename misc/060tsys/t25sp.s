;----------------------------------------------------------------
;
;	例外ハンドラ
;
;----------------------------------------------------------------

	.include	t02const.equ

	.cpu	68060

;----------------------------------------------------------------
;
;	アクセスエラー例外
;
;----------------------------------------------------------------
accessError::
	btst.b	#FSLW_BPE_BIT,($000C+3,sp)	;FSLWのBPEビットをテストする
	bne	branchPredictionError	;BPEビットがセットされていたら分岐予測エラー
	jmp	([vectorOldAccessError])

;----------------------------------------------------------------
;
;	分岐予測エラー
;
;----------------------------------------------------------------
branchPredictionError::
;分岐キャッシュをクリアする
	move.l	d0,-(sp)
	movec.l	cacr,d0
	bset.l	#CACR_CABC_BIT,d0	;分岐キャッシュをクリア
	movec.l	d0,cacr			;CABCビットはreadは常に0なので元に戻す必要はない
	move.l	(sp)+,d0
;マニュアルではBPE以外のBusErrorが発生していないことを確認してからrteするように
;書かれているが、何故か必ずWEビットもセットされてしまっているので、とりあえず
;無視して復帰する
	rte


;----------------------------------------------------------------
;----------------------------------------------------------------
UNIMPLEMENTED_INTEGER	equ	5
;MOVEPエミュレーションルーチンの履歴
;1	～v0.47
;		スタックにレジスタテーブルを生成
;		ROM 1.5(97/03/26,97/05/29)もこれと同じ
;2	v0.49～v0.51
;		スーパースケーラを意識して最適化
;		エンバグがあり,パターンによっては正しくエミュレートできない
;		エミュレート中の割り込みによってデータが破壊される
;3	v0.52
;		パターンによって正しくエミュレートできていなかった部分だけ修正
;		割り込みによるデータ破壊は未修正
;4	v0.53
;		割り込みによるデータ破壊を修正,完成
;5(97/08/17,97/09/15)
;		スタックのレジスタテーブルをやめ,レジスタ番号で分岐
;		MOVEPエミュレーションルーチンがかなり大きくなった
;		実効アドレスのアクセスウェイトを多少考慮
;6(予定)
;		実効アドレスのアクセスウェイトを積極的に活用する
;		<ea>→Dnの順で確定し,読み出し時は読み出しながらDnを確定する
;		書き込み時は書き込みながら直後の命令もMOVEPでないか調べ,
;		MOVEPが続いていたら例外処理から復帰せずにエミュレートを続ける
;		実効アドレスのアクセスの最中は,なるべく他のアドレスをアクセスしない
;		(キャッシュがミスするとそこで待たされるため)
;		ストアバッファの効果で,1回目の書き込みはすぐに復帰する可能性がある
;		分岐方法も改良



  .if UNIMPLEMENTED_INTEGER=1



;----------------------------------------------------------------
;
;	未実装整数命令例外
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP以外の未実装整数命令
ispCall:
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movea.l	(sp)+,a0
	lea.l	(4*(8-1),sp),sp
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;MOVEPでユーザモードのとき
_movepUser:
	move.l	usp,a1			;例外発生時のusp
	move.l	a1,(4*15,sp)		;例外発生時のsp
	bra	_movepSuper

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;未実装整数命令例外処理ルーチン
;	MOVEPだけ特別扱いにして高速に処理しています
;	その他の未実装整数命令の処理はISPに任せます
_060_isp_unint::
	pea.l	(8,sp)			;例外発生時のssp
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	(4*16+2,sp),a0		;例外発生時のpc
;<a0.l:例外発生時のpc
	move.w	(a0)+,d1		;命令コード
;<d1.w:例外発生時の(pc).w
;MOVEPか
	move.w	d1,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP命令
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	ファンクションコードのチェック/変更を一切行っていません
;	転送中のアクセスエラーを考慮していません
;	次のような異常なメモリ操作は正しくエミュレートできません
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<d1.w:例外発生時の(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a0.l:例外発生時のpc+2
;<sp.l:スタックに例外発生時のレジスタの内容を保持
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	ssp
;	0040	.w	sr
;	0042	.l	pc		pcは次の命令のアドレスに更新すること
;	0046	.w	ベクタオフセット
;	0048		sspの位置
_movep:
	btst.b	#5,(4*16,sp)		;例外発生時のsrのS
	beq	_movepUser		;スーパーバイザモードを優先
_movepSuper:
;<sp.l:スタックに例外発生時のレジスタの内容を保持
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	uspまたはssp
;	0040	.w	sr
;	0042	.l	pc		pcは次の命令のアドレスに更新すること
;	0046	.w	ベクタオフセット
;	0048		sspの位置
;実効アドレスを求める
	moveq.l	#7,d0			;0000000000000111
	and.w	d1,d0			;0000000000000aaa
	movea.l	(4*8,sp,d0.w*4),a1	;アドレスレジスタの内容
	adda.w	(a0)+,a1		;ディスプレースメントを加える
;<a0.l:例外発生時のpc+4
;<a1.l:実効アドレス
;復帰アドレスを更新する
	move.l	a0,(4*16+2,sp)		;復帰アドレスを更新
;データレジスタのアドレスを求める
	move.w	d1,d0			;0000ddd1ws001aaa
	lsr.w	#8,d0			;000000000000ddd1
	lea.l	(-2,sp,d0.w*2),a0	;00000000000ddd10
					;00000000000ddd00
					;データレジスタのアドレス
;<a0.l:データレジスタのアドレス
;オペレーションモードに従って転送する
	add.b	d1,d1
	bcc	_movepRead		;writeを優先
;レジスタ→メモリ
;	MOVEP.{WL} Dx,(d16,Ay)
_movepWrite:
	bpl	_movepWriteWord		;ロングワードを優先
;レジスタ→メモリ,ロングワード
;	MOVEP.L Dx,(d16,Ay)
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepWriteLong:
	move.b	(a0)+,(a1)
	move.b	(a0)+,(2,a1)
	move.b	(a0)+,(4,a1)
	move.b	(a0),(6,a1)
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movem.l	(sp)+,a0-a1
	lea.l	(4*(8-2),sp),sp
	rte

;レジスタ→メモリ,ワード
;	MOVEP.W Dx,(d16,Ay)
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepWriteWord:
	addq.w	#2,a0
	move.b	(a0)+,(a1)
	move.b	(a0),(2,a1)
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movem.l	(sp)+,a0-a1
	lea.l	(4*(8-2),sp),sp
	rte

;メモリ→レジスタ
;	MOVEP.{WL} (d16,Ay),Dx
_movepRead:
	bpl	_movepReadWord		;ロングワードを優先
;メモリ→レジスタ,ロングワード
;	MOVEP.L	(d16,Ay),Dx
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepReadLong:
	move.b	(a1),(a0)+
	move.b	(2,a1),(a0)+
	move.b	(4,a1),(a0)+
	move.b	(6,a1),(a0)
	movem.l	(sp)+,d0-d7/a0-a1
	lea.l	(4*(8-2),sp),sp
	rte

;メモリ→レジスタ,ワード
;	MOVEP.W (d16,Ay),Dx
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepReadWord:
	addq.w	#2,a0
	move.b	(a1),(a0)+
	move.b	(2,a1),(a0)
	movem.l	(sp)+,d0-d7/a0-a1
	lea.l	(4*(8-2),sp),sp
	rte



  .elseif UNIMPLEMENTED_INTEGER=4



;----------------------------------------------------------------
;
;	未実装整数命令例外
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP以外の未実装整数命令
ispCall:
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movea.l	(sp)+,a0
	lea.l	(4*(8-1),sp),sp
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;MOVEPでユーザモードのとき
_movepUser:
	move.l	usp,a1			;例外発生時のusp
	move.l	a1,(4*15,sp)		;例外発生時のsp
	bra	_movepSuper

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;未実装整数命令例外処理ルーチン
;	MOVEPだけ特別扱いにして高速に処理しています
;	その他の未実装整数命令の処理はISPに任せます
_060_isp_unint::
	pea.l	(8,sp)			;例外発生時のssp
	movem.l	d0-d7/a0-a6,-(sp)	;movem.l <register-list>,-(sp)は,
					;move.l rn,-(sp)で展開しても速くならない
	movea.l	(4*16+2,sp),a0		;例外発生時のpc
;<a0.l:例外発生時のpc
	move.w	(a0)+,d1		;命令コード
;<d1.w:例外発生時の(pc).w
;MOVEPか
	move.w	d1,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP命令
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	ファンクションコードのチェック/変更を一切行っていません
;	転送中のアクセスエラーを考慮していません
;	次のような異常なメモリ操作は正しくエミュレートできません
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<d1.w:例外発生時の(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a0.l:例外発生時のpc+2
;<sp.l:スタックに例外発生時のレジスタの内容を保持
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	ssp
;	0040	.w	sr
;	0042	.l	pc		pcは次の命令のアドレスに更新すること
;	0046	.w	ベクタオフセット
;	0048		sspの位置
_movep:
	btst.b	#5,(4*16,sp)		;例外発生時のsrのS
	beq	_movepUser		;スーパーバイザモードを優先
_movepSuper:
;<sp.l:スタックに例外発生時のレジスタの内容を保持
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	uspまたはssp
;	0040	.w	sr
;	0042	.l	pc		pcは次の命令のアドレスに更新すること
;	0046	.w	ベクタオフセット
;	0048		sspの位置
;実効アドレスを求める
	moveq.l	#7,d0			;0000000000000111
	and.w	d1,d0			;0000000000000aaa
	movea.l	(4*8,sp,d0.w*4),a1	;アドレスレジスタの内容
	adda.w	(a0)+,a1		;ディスプレースメントを加える
;<a0.l:例外発生時のpc+4
;<a1.l:実効アドレス
		move.w	d1,d0		;0000ddd1ws001aaa
;復帰アドレスを更新する
	move.l	a0,(4*16+2,sp)		;復帰アドレスを更新
;データレジスタのアドレスを求める
		lsr.w	#8,d0		;000000000000ddd1
	add.b	d1,d1
		lea.l	(-2,sp,d0.w*2),a0	;00000000000ddd10
					;00000000000ddd00
					;データレジスタのアドレス
;<a0.l:データレジスタのアドレス
;オペレーションモードに従って転送する
	bcc	_movepRead		;writeを優先
;レジスタ→メモリ
;	MOVEP.{WL} Dx,(d16,Ay)
_movepWrite:
	bpl	_movepWriteWord		;ロングワードを優先
;レジスタ→メモリ,ロングワード
;	MOVEP.L Dx,(d16,Ay)
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepWriteLong:
					;movem.l (sp)+,<register-list>は,
					;move.l (sp)+,rnで展開すると速くなる
	move.b	(a0)+,(a1)
	move.b	(a0)+,(2,a1)
	move.b	(a0)+,(4,a1)
	move.b	(a0),(6,a1)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		movea.l	(4*(8-2),sp),a0
	movea.l	(4*(9-2),sp),a1
		lea.l	(4*(16-2),sp),sp
	rte

;レジスタ→メモリ,ワード
;	MOVEP.W Dx,(d16,Ay)
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepWriteWord:
	move.b	(2,a0),(a1)
	move.b	(3,a0),(2,a1)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		movea.l	(4*(8-2),sp),a0
	movea.l	(4*(9-2),sp),a1
		lea.l	(4*(16-2),sp),sp
	rte

;メモリ→レジスタ
;	MOVEP.{WL} (d16,Ay),Dx
_movepRead:
	bpl	_movepReadWord		;ロングワードを優先
;メモリ→レジスタ,ロングワード
;	MOVEP.L	(d16,Ay),Dx
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepReadLong:
	move.b	(a1),(a0)+
	move.b	(2,a1),(a0)+
	move.b	(4,a1),(a0)+
	move.b	(6,a1),(a0)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		move.l	(sp)+,d2
	move.l	(sp)+,d3
		move.l	(sp)+,d4
	move.l	(sp)+,d5
		move.l	(sp)+,d6
	move.l	(sp)+,d7
		movea.l	(sp)+,a0
	movea.l	(sp)+,a1
		lea.l	(4*(16-10),sp),sp
	rte

;メモリ→レジスタ,ワード
;	MOVEP.W (d16,Ay),Dx
;<a0.l:データレジスタのアドレス
;<a1.l:実効アドレス
_movepReadWord:
	move.b	(a1),(2,a0)
	move.b	(2,a1),(3,a0)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		move.l	(sp)+,d2
	move.l	(sp)+,d3
		move.l	(sp)+,d4
	move.l	(sp)+,d5
		move.l	(sp)+,d6
	move.l	(sp)+,d7
		movea.l	(sp)+,a0
	movea.l	(sp)+,a1
		lea.l	(4*(16-10),sp),sp
	rte



  .elseif UNIMPLEMENTED_INTEGER=5



;----------------------------------------------------------------
;
;	未実装整数命令例外
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP以外の未実装整数命令
ispCall:
	movea.l	(sp)+,a1		;順序に注意
	move.w	(sp)+,d0
	movea.l	(sp)+,a0
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;未実装整数命令例外処理ルーチン
;	MOVEPだけ特別扱いにして高速に処理しています
;	その他の未実装整数命令の処理はISPに任せます
	.align	4
_060_isp_unint::
	move.l	a0,-(sp)		;順序に注意
	move.w	d0,-(sp)		;上位ワードは保護しないので注意
	move.l	a1,-(sp)
	movea.l	((4+2+4)+2,sp),a1	;例外発生時のpc
;<a1.l:例外発生時のpc
	movea.w	(a1)+,a0		;命令コード
;<a0.w:例外発生時の(pc).w
;MOVEPか
	move.w	a0,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP命令
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	ファンクションコードのチェック/変更を一切行っていません
;	転送中のアクセスエラーを考慮していません
;	次のような異常なメモリ操作は正しくエミュレートできません
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<a0.w:例外発生時の(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a1.l:例外発生時のpc+2
;<sp.l:スタックに例外発生時のレジスタの内容を保持
;	0000	.l	a1
;	0004	.w	d0
;	0006	.l	a0
;	000A	.w	sr
;	000C	.l	pc		pcは次の命令のアドレスに更新すること
;	0010	.w	例外フォーマット番号,ベクタオフセット
;	0012		例外発生時のsspの位置
_movep:
;実効アドレスを求める
	move.w	a0,d0			;0000ddd1ws001aaa
	and.b	#7,d0			;0000000000000aaa
					; 0  1  2  3  4  5  6  7
	beq	_movep_a0		; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_a123		;   -3 -2 -1
	beq	_movep_a4		;             0
_movep_a567:				;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_a5		;               -1
	beq	_movep_a6		;                   0
_movep_a7:				;                      1
	move.w	a0,d0			;0000ddd1ws001aaa
	lea.l	((4+2+4)+8,sp),a0		;例外発生時のssp
	btst.b	#5,((4+2+4)+0,sp)
	bne	_movep_d
	movea.l	usp,a0			;例外発生時のusp
	bra	_movep_d

_movep_a6:				;                   0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a6,a0			;例外発生時のa6
	bra	_movep_d

_movep_a5:				;               -1
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a5,a0			;例外発生時のa5
	bra	_movep_d

_movep_a4:				;             0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a4,a0			;例外発生時のa4
	bra	_movep_d

_movep_a123:				;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_a1		;   -1
	beq	_movep_a2		;       0
_movep_a3:				;          1
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a3,a0			;例外発生時のa3
	bra	_movep_d

_movep_a2:				;       0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a2,a0			;例外発生時のa2
	bra	_movep_d

_movep_a1:				;   -1
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	(sp),a0			;例外発生時のa1
	bra	_movep_d

_movep_a0:				; 0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	((4+2),sp),a0		;例外発生時のa0
;<a0.l:アドレスレジスタの内容
;<a1.l:例外発生時のpc+2
_movep_d:
	adda.w	(a1)+,a0		;ディスプレースメントを加える
;<d0.w:0000ddd1ws001aaa
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
;復帰アドレスを更新する
	move.l	a1,((4+2+4)+2,sp)	;復帰アドレスを更新
	movea.l	(sp)+,a1
;オペレーションモードに従って転送する
;<d0.w:0000ddd1ws001aaa
;<a0.l:実効アドレス
	add.b	d0,d0			;c-flag=w,n-flag=s
	bcc	_movep_read		;writeを優先
;レジスタ→メモリ
;	MOVEP.{WL} Dx,(d16,Ay)
;<d0.w:0000ddd1s001aaa0
;<a0.l:実効アドレス
_movep_write:
	bpl	_movep_write_word	;longを優先
;レジスタ→メモリ,ロングワード
;	MOVEP.L Dx,(d16,Ay)
;<d0.w:0000ddd1s001aaa0
;<a0.l:実効アドレス
_movep_write_long:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_write_long_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_write_long_d123	;   -3 -2 -1
	beq	_movep_write_long_d4	;             0
_movep_write_long_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_write_long_d5	;               -1
	beq	_movep_write_long_d6	;                   0
;	MOVEP.L D7,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d7:			;                      1
	rol.l	#8,d7
	move.b	d7,(a0)
	rol.l	#8,d7
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d7,(2,a0)
	rol.l	#8,d7
	move.b	d7,(4,a0)
	rol.l	#8,d7
	move.b	d7,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D6,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d6:			;                   0
	rol.l	#8,d6
	move.b	d6,(a0)
	rol.l	#8,d6
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d6,(2,a0)
	rol.l	#8,d6
	move.b	d6,(4,a0)
	rol.l	#8,d6
	move.b	d6,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D5,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d5:			;               -1
	rol.l	#8,d5
	move.b	d5,(a0)
	rol.l	#8,d5
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d5,(2,a0)
	rol.l	#8,d5
	move.b	d5,(4,a0)
	rol.l	#8,d5
	move.b	d5,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D4,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d4:			;             0
	rol.l	#8,d4
	move.b	d4,(a0)
	rol.l	#8,d4
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d4,(2,a0)
	rol.l	#8,d4
	move.b	d4,(4,a0)
	rol.l	#8,d4
	move.b	d4,(6,a0)
	movea.l	(sp)+,a0
	rte

_movep_write_long_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_write_long_d1	;   -1
	beq	_movep_write_long_d2	;       0
;	MOVEP.L D3,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d3:			;          1
	rol.l	#8,d3
	move.b	d3,(a0)
	rol.l	#8,d3
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d3,(2,a0)
	rol.l	#8,d3
	move.b	d3,(4,a0)
	rol.l	#8,d3
	move.b	d3,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D2,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d2:			;       0
	rol.l	#8,d2
	move.b	d2,(a0)
	rol.l	#8,d2
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d2,(2,a0)
	rol.l	#8,d2
	move.b	d2,(4,a0)
	rol.l	#8,d2
	move.b	d2,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D1,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d1:			;   -1
	rol.l	#8,d1
	move.b	d1,(a0)
	rol.l	#8,d1
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d1,(2,a0)
	rol.l	#8,d1
	move.b	d1,(4,a0)
	rol.l	#8,d1
	move.b	d1,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D0,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_long_d0:			; 0
	move.w	(sp)+,d0		;先に復元すること
	rol.l	#8,d0
	move.b	d0,(a0)
	rol.l	#8,d0
	move.b	d0,(2,a0)
	rol.l	#8,d0
	move.b	d0,(4,a0)
	rol.l	#8,d0
	move.b	d0,(6,a0)
	movea.l	(sp)+,a0
	rte

;レジスタ→メモリ,ワード
;	MOVEP.W Dx,(d16,Ay)
;<d0.w:0000ddd1s001aaa0
;<a0.l:実効アドレス
_movep_write_word:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_write_word_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_write_word_d123	;   -3 -2 -1
	beq	_movep_write_word_d4	;             0
_movep_write_word_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_write_word_d5	;               -1
	beq	_movep_write_word_d6	;                   0
;	MOVEP.W D7,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d7:			;                      1
	rol.w	#8,d7
	move.b	d7,(a0)
	rol.w	#8,d7
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d7,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D6,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d6:			;                   0
	rol.w	#8,d6
	move.b	d6,(a0)
	rol.w	#8,d6
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d6,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D5,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d5:			;               -1
	rol.w	#8,d5
	move.b	d5,(a0)
	rol.w	#8,d5
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d5,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D4,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d4:			;             0
	rol.w	#8,d4
	move.b	d4,(a0)
	rol.w	#8,d4
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d4,(2,a0)
	movea.l	(sp)+,a0
	rte

_movep_write_word_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_write_word_d1	;   -1
	beq	_movep_write_word_d2	;       0
;	MOVEP.W D3,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d3:			;          1
	rol.w	#8,d3
	move.b	d3,(a0)
	rol.w	#8,d3
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d3,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D2,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d2:			;       0
	rol.w	#8,d2
	move.b	d2,(a0)
	rol.w	#8,d2
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d2,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D1,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d1:			;   -1
	rol.w	#8,d1
	move.b	d1,(a0)
	rol.w	#8,d1
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	d1,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D0,(d16,Ay)
;<a0.l:実効アドレス
_movep_write_word_d0:			; 0
	move.w	(sp)+,d0		;先に復元すること
	rol.w	#8,d0
	move.b	d0,(a0)
	rol.w	#8,d0
	move.b	d0,(2,a0)
	movea.l	(sp)+,a0
	rte

;メモリ→レジスタ
;	MOVEP.{WL} (d16,Ay),Dx
;<d0.w:0000ddd1s001aaa0
;<a0.l:実効アドレス
_movep_read:
	bpl	_movep_read_word	;longを優先
;メモリ→レジスタ,ロングワード
;	MOVEP.L	(d16,Ay),Dx
;<d0.w:0000ddd1s001aaa0
;<a0.l:実効アドレス
_movep_read_long:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_read_long_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_read_long_d123	;   -3 -2 -1
	beq	_movep_read_long_d4	;             0
_movep_read_long_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_read_long_d5	;               -1
	beq	_movep_read_long_d6	;                   0
;	MOVEP.L	(d16,Ay),D7
;<a0.l:実効アドレス
_movep_read_long_d7:			;                      1
	move.b	(a0),d7
	lsl.l	#8,d7
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d7
	lsl.l	#8,d7
	move.b	(4,a0),d7
	lsl.l	#8,d7
	move.b	(6,a0),d7
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D6
;<a0.l:実効アドレス
_movep_read_long_d6:			;                      1
	move.b	(a0),d6
	lsl.l	#8,d6
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d6
	lsl.l	#8,d6
	move.b	(4,a0),d6
	lsl.l	#8,d6
	move.b	(6,a0),d6
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D5
;<a0.l:実効アドレス
_movep_read_long_d5:			;                      1
	move.b	(a0),d5
	lsl.l	#8,d5
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d5
	lsl.l	#8,d5
	move.b	(4,a0),d5
	lsl.l	#8,d5
	move.b	(6,a0),d5
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D4
;<a0.l:実効アドレス
_movep_read_long_d4:			;             0
	move.b	(a0),d4
	lsl.l	#8,d4
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d4
	lsl.l	#8,d4
	move.b	(4,a0),d4
	lsl.l	#8,d4
	move.b	(6,a0),d4
	movea.l	(sp)+,a0
	rte

_movep_read_long_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_read_long_d1	;   -1
	beq	_movep_read_long_d2	;       0
;	MOVEP.L	(d16,Ay),D3
;<a0.l:実効アドレス
_movep_read_long_d3:			;          1
	move.b	(a0),d3
	lsl.l	#8,d3
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d3
	lsl.l	#8,d3
	move.b	(4,a0),d3
	lsl.l	#8,d3
	move.b	(6,a0),d3
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D2
;<a0.l:実効アドレス
_movep_read_long_d2:			;       0
	move.b	(a0),d2
	lsl.l	#8,d2
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d2
	lsl.l	#8,d2
	move.b	(4,a0),d2
	lsl.l	#8,d2
	move.b	(6,a0),d2
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D1
;<a0.l:実効アドレス
_movep_read_long_d1:			;   -1
	move.b	(a0),d1
	lsl.l	#8,d1
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d1
	lsl.l	#8,d1
	move.b	(4,a0),d1
	lsl.l	#8,d1
	move.b	(6,a0),d1
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D0
;<a0.l:実効アドレス
_movep_read_long_d0:			; 0
	move.b	(a0),d0
	lsl.l	#8,d0
	addq.l	#2,sp			;スタックのd0を捨てる
					;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d0
	lsl.l	#8,d0
	move.b	(4,a0),d0
	lsl.l	#8,d0
	move.b	(6,a0),d0
	movea.l	(sp)+,a0
	rte

;メモリ→レジスタ,ワード
;	MOVEP.W (d16,Ay),Dx
;<d0.w:0000ddd1s001aaa0
;<a0.l:実効アドレス
_movep_read_word:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_read_word_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_read_word_d123	;   -3 -2 -1
	beq	_movep_read_word_d4	;             0
_movep_read_word_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_read_word_d5	;               -1
	beq	_movep_read_word_d6	;                   0
;	MOVEP.W	(d16,Ay),D7
;<a0.l:実効アドレス
_movep_read_word_d7:			;                      1
	move.b	(a0),d7
	lsl.w	#8,d7
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d7
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D6
;<a0.l:実効アドレス
_movep_read_word_d6:			;                      1
	move.b	(a0),d6
	lsl.w	#8,d6
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d6
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D5
;<a0.l:実効アドレス
_movep_read_word_d5:			;                      1
	move.b	(a0),d5
	lsl.w	#8,d5
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d5
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D4
;<a0.l:実効アドレス
_movep_read_word_d4:			;             0
	move.b	(a0),d4
	lsl.w	#8,d4
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d4
	movea.l	(sp)+,a0
	rte

_movep_read_word_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_read_word_d1	;   -1
	beq	_movep_read_word_d2	;       0
;	MOVEP.W	(d16,Ay),D3
;<a0.l:実効アドレス
_movep_read_word_d3:			;          1
	move.b	(a0),d3
	lsl.w	#8,d3
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d3
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D2
;<a0.l:実効アドレス
_movep_read_word_d2:			;       0
	move.b	(a0),d2
	lsl.w	#8,d2
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d2
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D1
;<a0.l:実効アドレス
_movep_read_word_d1:			;   -1
	move.b	(a0),d1
	lsl.w	#8,d1
	move.w	(sp)+,d0		;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d1
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D0
;<a0.l:実効アドレス
_movep_read_word_d0:			; 0
	move.b	(a0),d0
	lsl.w	#8,d0
	addq.l	#2,sp			;スタックのd0を捨てる
					;(a0)が遅い可能性があるのでここに挟む
	move.b	(2,a0),d0
	movea.l	(sp)+,a0
	rte



  .elseif UNIMPLEMENTED_INTEGER=6



;----------------------------------------------------------------
;
;	未実装整数命令例外
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP以外の未実装整数命令
ispCall:
	move.l	(sp)+,d0
	move.l	(sp)+,d1
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;未実装整数命令例外処理ルーチン
;	MOVEPだけ特別扱いにして高速に処理しています
;	その他の未実装整数命令の処理はISPに任せます
	.align	4
_060_isp_unint::
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	movea.l	(4*4+2,sp),a1		;例外発生時のpc
;<a1.l:例外発生時のpc
	move.w	(a1)+,d1		;命令コード
;<d1.w:例外発生時の(pc).w
;MOVEPか
	move.w	d1,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP命令
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	ファンクションコードのチェック/変更を一切行っていません
;	転送中のアクセスエラーを考慮していません
;	次のような異常なメモリ操作は正しくエミュレートできません
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<d1.w:例外発生時の(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a1.l:例外発生時のpc+2
;<sp.l:スタックに例外発生時のレジスタの内容を保持
;	0000	.l	d0
;	0004	.l	d0
;	0008	.l	a0
;	000C	.l	a1
;	0010	.w	sr
;	0012	.l	pc		pcは次の命令のアドレスに更新すること
;	0016	.w	例外フォーマット番号,ベクタオフセット
;	0018		例外発生時のsspの位置
_movep:
	ror.b	#3,d1			;0000ddd1aaaws001,n=aaa[2]
	bpl	_movep_a0123
_movep_a4567:
	lsl.b	#2,d1			;0000ddd1aws00100,c=aaa[1],n=aaa[0]
	bcc	_movep_a45
_movep_a67:
	bpl	_movep_a6
_movep_a7:
	lea.l	(4*4+8,sp),a0		;例外発生時のssp
	btst.b	#5,(4*4+0,sp)
	bne	_movep_an
	movea.l	usp,a0			;例外発生時のusp
	bra	_movep_an

_movep_a6:
	movea.l	a6,a0			;例外発生時のa6
	bra	_movep_an

_movep_a45:
	bpl	_movep_a4
_movep_a5:
	movea.l	a5,a0			;例外発生時のa5
	bra	_movep_an

_movep_a4:
	movea.l	a4,a0			;例外発生時のa4
	bra	_movep_an

_movep_a0123:
	lsl.b	#2,d1			;0000ddd1aws00100,c=aaa[1],n=aaa[0]
	bcc	_movep_a01
_movep_a23:
	bpl	_movep_a2
_movep_a3:
	movea.l	a3,a0			;例外発生時のa3
	bra	_movep_an

_movep_a2:
	movea.l	a2,a0			;例外発生時のa2
	bra	_movep_an

_movep_a01:
	bpl	_movep_a0
_movep_a1:
	movea.l	(4,sp),a0		;例外発生時のa1
	bra	_movep_an

_movep_a0:
	movea.l	(sp),a0			;例外発生時のa0
;<d1.w:0000ddd1aws00100
;<a0.l:An
;<a1.l:例外発生時のpc+2
_movep_an:
	adda.w	(a1)+,a0		;ディスプレースメントを加える
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
	lsl.b	#2,d1			;0000ddd1s0010000,c=w,n=s
	bcc	_movep_read		;writeを優先
;レジスタ→メモリ
;	MOVEP.{WL} Dx,(d16,Ay)
;<d1.w:0000ddd1s0010000
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
_movep_write:
	lsl.w	#5,d1			;dd1s001000000000,c=ddd[2],n=ddd[1]
	bcc	_movep_write_d0123
_movep_write_d4567:
	bpl	_movep_write_d45
_movep_write_d67:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d6
_movep_write_d7:
	move.l	d7,d0
	bra	_movep_write_dn

_movep_write_d6:
	move.l	d6,d0
	bra	_movep_write_dn

_movep_write_d45:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d4
_movep_write_d5:
	move.l	d5,d0
	bra	_movep_write_dn

_movep_write_d4:
	move.l	d4,d0
	bra	_movep_write_dn

_movep_write_d0123:
	bpl	_movep_write_d01
_movep_write_d23:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d2
_movep_write_d3:
	move.l	d3,d0
	bra	_movep_write_dn

_movep_write_d2:
	move.l	d2,d0
	bra	_movep_write_dn

_movep_write_d01:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d0
_movep_write_d1:
	move.l	(4,sp),d0
	bra	_movep_write_dn

_movep_write_d0:
	move.l	(sp),d0
;<d0.l:Dn
;<d1.w:1s00100000000000
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
_movep_write_dn:
	lsl.w	#2,d1			;0010000000000000,c=s
	bpl	_movep_write_word	;longを優先
;レジスタ→メモリ,ロングワード
;	MOVEP.L Dx,(d16,Ay)
;<d0.l:Dn
;<d1.w:0010000000000000
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
_movep_write_long:
	rol.l	#8,d0
	tst.l	(a1)			;MOVEPの直後の2ワードをキャッシュに乗せておく
	move.b	d0,(a0)			;1バイト目を書き込む
	move.w	(a1),d1			;MOVEPの直後のワード
					;キャッシュはヒットするはず
	rol.l	#8,d0			;書き込んだ直後に次の1バイトを用意する
	and.w	#$F138,d1		;直後の命令もMOVEPか?
	cmp.w	#$0108,d1
	bne	_movep_write_long_stop	;MOVEPではない
;MOVEPの直後の命令もMOVEPだった
;書き込みながら直後のMOVEPのAnとDnを確定する
_movep_write_long_cont:
	move.w	(a1)+,d1		;直後のMOVEP
					;キャッシュはヒットするはず
;<d1.w:直後のMOVEP,0000ddd1ws001aaa
;<a1.l:直後の命令のpc+2
	ror.b	#3,d1			;0000ddd1aaaws001,n=aaa[2]
	bpl	_movep_long_cont_a0123
_movep_long_cont_a4567:
	lsl.b	#2,d1			;0000ddd1aws00100,c=aaa[1],n=aaa[0]
	bcc	_movep_long_cont_a45
_movep_long_cont_a67:
	bpl	_movep_long_cont_a6
_movep_long_cont_a7:
	move.b	d0,(2,a0)		;2バイト目を書き込む
	rol.l	#8,d0			;書き込んだ直後に次の1バイトを用意する





;MOVEPの直後の命令はMOVEPではなかった
;残りのデータを書き込んで復帰アドレスを更新して終わり

_movep_write_long_stop:
;復帰アドレスを更新する
	move.l	a1,(4*4+2,sp)		;復帰アドレスを更新




;レジスタ→メモリ,ワード
;	MOVEP.W Dx,(d16,Ay)
;<d0.l:Dn
;<d1.w:0010000000000000
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
_movep_write_word:




;メモリ→レジスタ
;	MOVEP.{WL} (d16,Ay),Dx
;<d1.w:0000ddd1s0010000
;<a0.l:実効アドレス
;<a1.l:例外発生時のpc+4
_movep_read:
;復帰アドレスを更新する
	move.l	a1,(4*4+2,sp)		;復帰アドレスを更新
	move.b	(a0),d0			;サイズ未確定のまま1バイト目をread
					;(d16,Ay)でキャッシュはヒットしないと想定して,
					;ウェイトの間になるべく多くの処理を行う
					;ここではウェイトの間にDnを確定してみる
					;これでもウェイトがかなり余るはず
					;メモリアクセスは極力避けること(キャッシュが
					;ミスするとそこにウェイトが入ってしまう)
	tst.b	d1			;0000ddd1s0010000,n=s
					;_movep_readの直後で分岐すればtstは不要だが,
					;あえてここに入れる
	bpl	_movep_read_word	;longを優先
;メモリ→レジスタ,ロングワード
;	MOVEP.L (d16,Ay),Dx
_movep_read_long:
	lsl.w	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(2,a0),d0		;2バイト目をread
	lsl.w	#4,d1			;ddd1s00100000000,s=1,n=ddd[2]
					;1ビットずつテストするのでcは使わない
	bpl	_movep_read_long_d0123	;アクセスの度に分岐を1～2個ずつ入れる
					;命令キャッシュさえヒットすれば,
					;分岐キャッシュがミスしても問題ない
_movep_read_long_d4567:
	lsl.l	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(4,a0),d0		;3バイト目をread
	lsl.w	#1,d1			;dd1s001000000000,s=1,n=ddd[1]
	bpl	_movep_read_long_d45
_movep_read_long_d67:
	lsl.l	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(6,a0),d0		;4バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d6
_movep_read_long_d7:
	move.l	d0,d7
	bra	_movep_read_long_dn

_movep_read_long_d6:
	move.l	d0,d6
	bra	_movep_read_long_dn

_movep_read_long_d45:
	lsl.l	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(6,a0),d0		;4バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d4
_movep_read_long_d5:
	move.l	d0,d5
	bra	_movep_read_long_dn

_movep_read_long_d4:
	move.l	d0,d4
	bra	_movep_read_long_dn

_movep_read_long_d0123:
	lsl.l	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(4,a0),d0		;3バイト目をread
	lsl.w	#1,d1			;dd1s001000000000,s=1,n=ddd[1]
	bpl	_movep_read_long_d01
_movep_read_long_d23:
	lsl.l	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(6,a0),d0		;4バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d2
_movep_read_long_d3:
	move.l	d0,d3
	bra	_movep_read_long_dn

_movep_read_long_d2:
	move.l	d0,d2
_movep_read_long_dn:
	move.l	(sp)+,d0
_movep_read_long_dn_d1:
	move.l	(sp)+,d1
_movep_read_long_dn_a0:
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	rte

_movep_read_long_d01:
	lsl.l	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(6,a0),d0		;4バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d0
_movep_read_long_d1:
	move.l	d0,d1
	move.l	(sp)+,d0
	addq.l	#4,sp			;スタックのd1を破棄する
	bra	_movep_read_long_dn_a0

_movep_read_long_d0:
	addq.l	#4,sp			;スタックのd0を破棄して,
					;読み出したd0をそのまま返す
	bra	_movep_read_long_dn_d1

;メモリ→レジスタ,ワード
;	MOVEP.W (d16,Ay),Dx
_movep_read_word:
	lsl.w	#5,d1			;dd1s001000000000,s=0,c=ddd[2],n=ddd[1]
	bcc	_movep_read_word_d0123	;アクセスの度に分岐を2～3個ずつ入れる
					;分岐キャッシュが全部ミスしても,
					;命令キャッシュさえヒットしていれば,
					;これでもウェイトに入り切ると思われる
					;(入り切らなくても問題はない)
_movep_read_word_d4567:
	bpl	_movep_read_word_d45
_movep_read_word_d67:
	lsl.w	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(2,a0),d0		;2バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d6
_movep_read_word_d7:
	move.w	d0,d7
	bra	_movep_read_word_dn

_movep_read_word_d6:
	move.w	d0,d6
	bra	_movep_read_word_dn

_movep_read_word_d45:
	lsl.w	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(2,a0),d0		;2バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d4
_movep_read_word_d5:
	move.w	d0,d5
	bra	_movep_read_word_dn

_movep_read_word_d4:
	move.w	d0,d4
	bra	_movep_read_word_dn

_movep_read_word_d0123:
	bpl	_movep_read_word_d01
_movep_read_word_d23:
	lsl.w	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(2,a0),d0		;2バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d2
_movep_read_word_d3:
	move.w	d0,d3
	bra	_movep_read_word_dn

_movep_read_word_d2:
	move.w	d0,d2
_movep_read_word_dn:
	move.l	(sp)+,d0
_movep_read_word_dn_d1:
	move.l	(sp)+,d1
_movep_read_word_dn_a0:
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	rte

_movep_read_word_d01:
	lsl.w	#8,d0			;ウェイト終了までd0が確定しないので,
					;次のアクセスの直前でシフトする
	move.b	(2,a0),d0		;2バイト目をread
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d0
_movep_read_word_d1:
	move.w	d0,d1			;d1の上位ワードは破壊されていないので,
					;そのまま返す
	move.l	(sp)+,d0
	addq.l	#4,sp			;スタックのd1を破棄する
	bra	_movep_read_word_dn_a0

_movep_read_word_d0:
					;d0の上位ワードは破壊されていないので,
					;そのまま返す
	addq.l	#4,sp			;スタックのd0を破棄する
	bra	_movep_read_word_dn_d1



  .endif



;----------------------------------------------------------------
;
;	F-line未実装命令例外/特権違反例外
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;Line 1111 Emulator (Unimplemented F-Line Opcode)
;	FLOATn.Xが特権違反例外をF-lineに落としてしまうので、
;	ここにも特権違反例外が入ってくることがある
	.dc.b	'060turbo'
	.dc.l	0
_060_fpsp_fline::
	cmpi.w	#$2000,(6,sp)		;フォーマットが2以上ならばFPSPに渡す
	bcc	_fpsp_fline
	move.l	a6,-(sp)
	movea.l	(4+2,sp),a6		;例外発生時のPC
;<a6.l:例外発生時のpc
	cmpi.b	#$FE,(a6)
	beq	feCall			;$FExx FEファンクションコール
	bhi	dosCall			;$FFxx DOSコール
	cmpi.b	#$F0,(a6)
	blo	flineToPrivilege	;F-Lineでなければ特権違反例外
;----------------------------------------------------------------
;$FExxでも$FFxxでもないF-Line OpcodeはFPSPに任せる
fpspCall::
	movea.l	(sp)+,a6
	bra	_fpsp_fline		;_060FPSP_TABLE+$00001B8C
					;_060FPSP_TABLE+$30

;----------------------------------------------------------------
;DOSコール
;<a6.l:例外発生時のpc
dosCall::
;;;	movea.l	(sp)+,a6
;;;	jmp	([vectorOldFLINE])
	cmpi.w	#$FFF5,(a6)
	bcc	dosCallThread
	movem.l	d1-d7/a0-a5,-(sp)
	move.w	(a6)+,d0		;(pc).w
	and.l	#$000000FF,d0
;<d0.l:DOSコール番号
	move.l	a6,(dosPC,sp)		;復帰アドレスを更新
	lea.l	(dosSSP,sp),a6		;例外発生時のssp
	btst.b	#5,(dosSR,sp)
	bne	@f
	move.l	usp,a6			;例外発生時のusp
@@:
;<a6.l:パラメータのアドレス
	tst.w	$1C08.w			;DOSコールのレベル(ここから_INDOSFLG)
	bne	@f
	move.l	sp,$1C5C.w		;DOSコールにレベル0で入ったときのssp
	move.b	d0,$1C0A.w		;レベル0で入ったDOSコール番号
@@:
	addq.w	#1,$1C08.w		;DOSコールのレベル(ここから_INDOSFLG)
	clr.l	$1C98.w			;DOSコールに入ってからオープンしたFCBテーブル
	jsr	([$1800,d0.l*4])
;	jsr	([$1800+$0400,d0.w*4])	;DOSコール実行
					;d0.l	$xxxxFFxx
					;拡張	$FFFFFFxx
					;4倍	$FFFFFCxx
					;本来の値より$0400足りないのでbdに加えておく
	clr.l	$1C98.w			;DOSコールに入ってからオープンしたFCBテーブル
	subq.w	#1,$1C08.w		;DOSコールのレベル(ここから_INDOSFLG)
	bne	@f
	clr.b	$1C0A.w			;レベル0で入ったDOSコール番号
@@:	move.l	d0,-(sp)
	jsr	$00008740		;breakチェック
	movem.l	(sp)+,d0-d7/a0-a6
	tst.b	$1C14.w			;DOSコール終了時にスレッドを切り替えるか(0=no,1=yes)
	bne	dosCallThreadChange
	tst.w	(sp)
	bmi	@f
	rte

@@:	ori.w	#$8000,sr
	rte

;スレッド管理関係のDOSコール
dosCallThread::
	move.l	a5,-(sp)
	move.l	d0,-(sp)
	move.w	(a6)+,d0		;(pc).w
	move.l	a6,(4*3+2,sp)		;復帰アドレスを更新
	lea.l	(4*3+8,sp),a6		;パラメータのアドレス
	jmp	$0000E31C

;DOSコール終了時にスレッドを切り替える
dosCallThreadChange::
	jmp	$0000E050

;----------------------------------------------------------------
;FEファンクションコール
;<a6.l:例外発生時のpc
feCall::
	move.l	d7,-(sp)
	move.w	(a6)+,d7		;例外発生時の(pc).w
;<d7.w:例外発生時の(pc).w
;<a6.l:例外発生時のpc+2
	move.l	a6,(4+4+2,sp)		;復帰アドレスを更新する
	jmp	([feJumpTable+$0200*4,pc,d7.w*4])	;各FEファンクションへ分岐
					;+$0200*4はオフセットの調節のため
					;d7.wを符号拡張すると	$FFFFFE00～$FFFFFEFF
					;4倍すると		$FFFFF800～$FFFFFBFC
					;オフセットが$0200*4足りないのでその分加えている

;----------------------------------------------------------------
;
;	特権違反例外
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;特権違反例外
privilegeViolation::
	move.l	a6,-(sp)
	movea.l	(4+2,sp),a6		;例外発生時のPC
flineToPrivilege:
	cmpi.w	#$40C0,(a6)
	blo	unknownPrivilege
	cmpi.w	#$40FF,(a6)
	bhi	unknownPrivilege
;----------------------------------------------------------------
;MOVE from SR
;	このままでは書き換えが反映される前に特権違反が発生してしまい、
;	そのとき既にMOVE from CCRになっているので白窓が出る
;	~008652:
;		move.l	a6,d0			;MOVE from CCRに変更する
;		or.w	#$0200,d0
;		move.w	d0,-(a5)
;		movec.l	cacr,d0			;命令キャッシュフラッシュ
;		or.w	#$0008,d0
;		movec.l	d0,cacr
;		movem.l	(sp)+,d0/a5-a6
;		rte
moveFromSr::
	bset.b	#1,(a6)			;MOVE from SRをMOVE from CCRにする
					;d0は壊れているので使わないこと
	bsr	cache_flush
	movea.l	(sp)+,a6
	rte

;----------------------------------------------------------------
;解釈できない特権違反例外
;スーパーバイザモードでもSTOPでSRのSビットをクリアしようとしたときなどに発生する
unknownPrivilege::
	move.l	(sp)+,a6
;----------------------------------------------------------------
;FPSPにも解釈できないF-Line Opcodeや特権違反例外は白窓へ
;[$002C.w]に飛ばすと無限ループに陥ってしまうので[$0010.w]を使う
_060_real_fline::
	jmp	([$0010.w])

;----------------------------------------------------------------
;
;	ISPとFPSPが使うサブルーチン
;
;----------------------------------------------------------------
;----------------------------------------------------------------
_060_real_lock_page::
_060_real_unlock_page::
	clr.l	d0
	rts

;----------------------------------------------------------------
_060_dmem_write::
_060_imem_read::
_060_dmem_read::
@@:	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne	@b
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_read_byte::
	clr.l	d0
	move.b	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_write_byte::
	move.b	d0,(a0)
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_read_word::
	clr.l	d0
	move.w	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_imem_read_word::
	move.w	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_write_word::
	move.w	d0,(a0)
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_read_long::
_060_imem_read_long::
	move.l	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_write_long::
	move.l	d0,(a0)
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_real_chk::
_060_real_divbyzero::
	tst.w	(sp)
	bmi	@f
	rte

@@:	move.b	#$24,(7,sp)
;----------------------------------------------------------------
_060_real_trace::
	jmp	([$0024.w])		;トレース

;----------------------------------------------------------------
_060_real_access::
	jmp	([$0008.w])		;アクセスエラー

;----------------------------------------------------------------
_060_real_trap::
	jmp	([$001C.w])		;FTRAPcc

;----------------------------------------------------------------
_060_real_inex::
_060_real_dz::
_060_real_unfl::
_060_real_operr::
_060_real_ovfl::
_060_real_snan::
	fsave	-(sp)
	move.w	#$6000,(2,sp)
	frestore	(sp)+
	rte

;----------------------------------------------------------------
_060_real_bsun::
	fsave	-(sp)
	fmove.l	fpsr,-(sp)
	and.b	#$FE,(sp)
	fmove.l	(sp)+,fpsr
	lea.l	(12,sp),sp
	rte

;----------------------------------------------------------------
_060_real_fpu_disabled::
	move.l	d0,-(sp)
	movec.l	pcr,d0			;FPUをイネーブルにする
	bclr.l	#1,d0
	movec.l	d0,pcr
	move.l	(sp)+,d0
	move.l	(12,sp),(2,sp)		;リトライ
	rte

;----------------------------------------------------------------
;
;	ISPとFPSPの出口
;
;----------------------------------------------------------------
;----------------------------------------------------------------
_060_isp_done::
	rte

;----------------------------------------------------------------
_060_fpsp_done::
	rte

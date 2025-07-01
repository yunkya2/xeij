;----------------------------------------------------------------
;
;	FEファンクション
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t06float.equ

	.cpu	68060

;----------------------------------------------------------------
;未完成のルーチン
;	_USING	_FUSING	(#INFと#NANの処理)
;	_POWER	_FPOWER
;	_DTOS	(pi()/180などの指数部の表示)


;----------------------------------------------------------------
;FPUが処理する浮動小数点命令
;	FABS	FADD	FBcc	FCMP	FDABS	FDADD	FDDIV	FDIV
;	FDMOVE	FDMUL	FDNEG	FDSQRT	FDSUB	FINT	FINTRZ	FMOVE
;	FMOVEM*	FMUL	FNEG	FNOP	FRESTORE	FSABS	FSADD
;	FSDIV	FSMOVE	FSMUL	FSNEG	FSAVE	FSQRT	FSSQRT	FSSUB
;	FSUB	FTST

;----------------------------------------------------------------
;FPSPが処理する浮動小数点命令
;	FACOS	FASIN	FATAN	FATANH	FCOS	FCOSH	FDBcc	FETOX
;	FETOXM1	FGETEXP	FGETMAN	FLOG10	FLOG2	FLOGN	FLOGNP1	FMOD
;	FMOVECR	FMOVEM*	FREM	FSCALE	FScc	FSGLDIV	FSGLMUL	FSIN
;	FSINCOS	FSINH	FTAN	FTANH	FTENTOX	FTRAPcc	FTWOTOX

;----------------------------------------------------------------
;FPSP内部のエミュレーションルーチンのオフセット
acos	reg	sacos			;_060FPSP_TABLE+$00003D42
asin	reg	sasin			;_060FPSP_TABLE+$00003C8E
atan	reg	satan			;_060FPSP_TABLE+$00003A4A
atanh	reg	satanh			;_060FPSP_TABLE+$000056B2
cos	reg	scos			;_060FPSP_TABLE+$00002404
cosh	reg	scosh			;_060FPSP_TABLE+$00004778
etox	reg	setox			;_060FPSP_TABLE+$00004272
etoxm1	reg	setoxm1			;_060FPSP_TABLE+$00004442
getexp	reg	sgetexp			;_060FPSP_TABLE+$000046FE
getman	reg	sgetman			;_060FPSP_TABLE+$00004732
log10	reg	slog10			;_060FPSP_TABLE+$0000575A
log2	reg	slog2			;_060FPSP_TABLE+$000057AA
logn	reg	slogn			;_060FPSP_TABLE+$00005318
lognp1	reg	slognp1			;_060FPSP_TABLE+$00005558
mod	reg	smod_snorm		;_060FPSP_TABLE+$00006C36
rem	reg	srem_snorm		;_060FPSP_TABLE+$00006D3E
scale	reg	sscale_snorm		;_060FPSP_TABLE+$00006DE0
sin	reg	ssin			;_060FPSP_TABLE+$000023FA
sincos	reg	ssincos			;_060FPSP_TABLE+$000025F2
sinh	reg	ssinh			;_060FPSP_TABLE+$00004836
tan	reg	stan			;_060FPSP_TABLE+$00002EBC
tanh	reg	stanh			;_060FPSP_TABLE+$0000491A
tentox	reg	stentox			;_060FPSP_TABLE+$00005D8C
twotox	reg	stwotox			;_060FPSP_TABLE+$00005C94

;----------------------------------------------------------------
;
;	fpsp	関数名
;
;	機能
;		・FPSP内部のエミュレーションルーチンを呼び出します。
;
;	引数
;		FP0	関数の引数
;
;	返却値
;		FP0	演算結果
;		D7	FPSR
;
;	破壊レジスタ
;		D0-D1
;
;----------------------------------------------------------------
fpsp	.macro	name
	move.l	a1,-(sp)
		move.l	a0,-(sp)
	link	a6,#-192
	clr.l	-192+32(a6)		;FPCR
		clr.l	-192+36(a6)		;FPSR
	fmove.x	fp0,-(sp)
	movea.l	sp,a0
		moveq.l	#0,d0			;ラウンディングモード
	jsr	name

	move.l	-192+36(a6),d7		;FPSR
;;;	lea.l	12(sp),sp
	unlk	a6
	movea.l	(sp)+,a0
		movea.l	(sp)+,a1
	.endm

;----------------------------------------------------------------
;
;	exit	引数,…
;
;	機能
;		・F系列命令エミュレーションを終了します。
;		・復元するレジスタ、CCRの設定、スタックに出力するデータなどを
;		  指定できます。
;
;	引数(復元するレジスタに関するもの)
;		・d0～d6 のレジスタ名を複数指定できます。
;		・アドレスレジスタは指定できません。
;			dn	dnを復元します。
;				dは小文字で、nは0～6の数字です。
;
;	引数(CCRに関するもの)
;		・CCRに関する引数の指定がなければ、CCRは変化しません。
;		  (FEファンクションコールの前後で変化しません)
;		・_,C,V,Z,N,Xの6つに限り、複数指定できます。
;		・_,C,V,Z,N,Xのいずれかが指定されているときは、指定されなかったフラグは
;		  クリアされます。
;			_	すべてのフラグをクリアします。
;			C	Cフラグをセットします。
;			V	Vフラグをセットします。
;			Z	Zフラグをセットします。
;			N	Nフラグをセットします。
;			X	Xフラグをセットします。
;			ccr	現在のccrの内容をそのまま返します。
;			Dn	現在のDnの内容をccrに設定します。
;				Dは大文字で、nは0～7の数字です。
;
;	引数(スタックに出力するデータに関するもの)
;		・次のいずれか1つを指定できます。
;		・デクリメントモードとは、既に1ロングワード分インクリメントされている
;		  場合です。
;			=n	dnを出力します。
;			=mn	dm/dnを出力します。
;			-n	dnを出力します。(デクリメントモード)
;			-mn	dm/dnを出力します。(デクリメントモード)
;				m,nは0～7の数字です。
;
;	補足
;		・引数の順序は任意です。
;		・引数がおかしいと、アセンブル時にエラーになります。
;
;----------------------------------------------------------------
exit	.macro	_0,_1,_2,_3,_4,_5,_6,_7,_8,_9
	.local	REGCNT,REGLST,F_IMM,F_REG,F_CCR,IMM_CC,REG_CC,CODE
	.local	x
	.local	trace
REGCNT	=	2	;復元するレジスタの個数
REGLST	reg	d7/a6	;復元するレジスタのレジスタリスト
F_IMM	=	0	;CCRをイミディエイトで返すとき1
F_REG	=	0	;CCRをレジスタで返すとき1
F_CCR	=	0	;CCRをそのまま返すとき1
IMM_CC	=	0	;CCRに設定するイミディエイトの値
REG_CC	reg	d7	;CCRに設定するレジスタ(CCRをそのまま返すときはd7)
CODE	=	0	;スタックにデータを出力するオペコード
  .irp %p,_9,_8,_7,_6,_5,_4,_3,_2,_1,_0
    .if ' &%p'>' '
x	=	'&%p'
      .if x>>8='d'
REGCNT	=	REGCNT+1
REGLST	reg	%p/REGLST
      .elseif x='_'
F_IMM	=	1
      .elseif x='C'|x='V'|x='Z'|x='N'|x='X'
F_IMM	=	1
IMM_CC	=	IMM_CC|%p
      .elseif x>>8='D'
F_REG	=	1
REG_CC	reg	%p
      .elseif x='ccr'
F_CCR	=	1
      .elseif x>>8='='
CODE	=	$2C80+x.mod.8		;move.l dn,(a6)
      .elseif x>>8='-'
CODE	=	$2D00+x.mod.8		;move.l dn,-(a6)
      .elseif x>>16='='
CODE	=	$10000*($2CC0+(.high.x).mod.8)+($2C80+(.low.x).mod.8)
					;move.l dm,(a6)+
					;move.l dn,(a6)
      .elseif x>>16='-'
CODE	=	$10000*($2C80+(.low.x).mod.8)+($2D00+(.low.x).mod.8)
					;move.l dn,(a6)
					;move.l dm,-(a6)
      .else
	.fail	1	;exitマクロの引数がおかしい
      .endif
    .endif
  .endm
  .if F_CCR
    .fail CODE.mod.8=7|(CODE>>16).mod.8=7
	move.w	ccr,REG_CC
  .endif
  .if CODE>>16
	.dc.l	CODE
  .elseif CODE
	.dc.w	CODE
  .endif
  .if F_IMM
    .if IMM_CC
	move.b	#IMM_CC,4*REGCNT+1(sp)
    .else
	clr.b	4*REGCNT+1(sp)
    .endif
  .elseif F_REG|F_CCR
	move.b	REG_CC,4*REGCNT+1(sp)
  .endif
	movem.l	(sp)+,REGLST
	tst.w	(sp)
	bmi	trace
	rte

trace:
	ori.w	#$8000,sr
	rte
	.endm

;----------------------------------------------------------------
;
;	param	areg
;
;	機能
;		・スタックのパラメータのアドレスを求めます。
;
;	引数
;		areg	アドレスレジスタ
;
;	補足
;		各FEファンクションコールに分岐した直後で指定して下さい。
;		SPが変化していると正常に機能しません。
;		そのため、実質的にアドレスレジスタはA6のみ指定可能です。
;
;----------------------------------------------------------------
param	.macro	areg
	.local	super
	btst.b	#5,4*2+0(sp)
		lea.l	4*2+8(sp),areg
	bne	super
	move.l	usp,areg
super:
	.endm

;----------------------------------------------------------------

	.text

;----------------------------------------------------------------
;FEファンクションコールジャンプテーブル
feJumpTable::
	.dc.l	fe_lmul		;$FE00
	.dc.l	fe_ldiv		;$FE01
	.dc.l	fe_lmod		;$FE02
	.dc.l	fe_undefined	;$FE03
	.dc.l	fe_umul		;$FE04
	.dc.l	fe_udiv		;$FE05
	.dc.l	fe_umod		;$FE06
	.dc.l	fe_undefined	;$FE07
	.dc.l	fe_imul		;$FE08
	.dc.l	fe_idiv		;$FE09
	.dc.l	fe_undefined	;$FE0A
	.dc.l	fe_undefined	;$FE0B
	.dc.l	fe_randomize	;$FE0C
	.dc.l	fe_srand	;$FE0D
	.dc.l	fe_rand		;$FE0E
	.dc.l	fe_undefined	;$FE0F
	.dc.l	fe_stol		;$FE10
	.dc.l	fe_ltos		;$FE11
	.dc.l	fe_stoh		;$FE12
	.dc.l	fe_htos		;$FE13
	.dc.l	fe_stoo		;$FE14
	.dc.l	fe_otos		;$FE15
	.dc.l	fe_stob		;$FE16
	.dc.l	fe_btos		;$FE17
	.dc.l	fe_iusing	;$FE18
	.dc.l	fe_undefined	;$FE19
	.dc.l	fe_ltod		;$FE1A
	.dc.l	fe_dtol		;$FE1B
	.dc.l	fe_ltof		;$FE1C
	.dc.l	fe_ftol		;$FE1D
	.dc.l	fe_ftod		;$FE1E
	.dc.l	fe_dtof		;$FE1F
	.dc.l	fe_val		;$FE20
	.dc.l	fe_using	;$FE21
	.dc.l	fe_stod		;$FE22
	.dc.l	fe_dtos		;$FE23
	.dc.l	fe_ecvt		;$FE24
	.dc.l	fe_fcvt		;$FE25
	.dc.l	fe_gcvt		;$FE26
	.dc.l	fe_undefined	;$FE27
	.dc.l	fe_dtst		;$FE28
	.dc.l	fe_dcmp		;$FE29
	.dc.l	fe_dneg		;$FE2A
	.dc.l	fe_dadd		;$FE2B
	.dc.l	fe_dsub		;$FE2C
	.dc.l	fe_dmul		;$FE2D
	.dc.l	fe_ddiv		;$FE2E
	.dc.l	fe_dmod		;$FE2F
	.dc.l	fe_dabs		;$FE30
	.dc.l	fe_dceil	;$FE31
	.dc.l	fe_dfix		;$FE32
	.dc.l	fe_dfloor	;$FE33
	.dc.l	fe_dfrac	;$FE34
	.dc.l	fe_dsgn		;$FE35
	.dc.l	fe_sin		;$FE36
	.dc.l	fe_cos		;$FE37
	.dc.l	fe_tan		;$FE38
	.dc.l	fe_atan		;$FE39
	.dc.l	fe_log		;$FE3A
	.dc.l	fe_exp		;$FE3B
	.dc.l	fe_sqr		;$FE3C
	.dc.l	fe_pi		;$FE3D
	.dc.l	fe_npi		;$FE3E
	.dc.l	fe_power	;$FE3F
	.dc.l	fe_rnd		;$FE40
	.dc.l	fe_sinh		;$FE41
	.dc.l	fe_cosh		;$FE42
	.dc.l	fe_tanh		;$FE43
	.dc.l	fe_atanh	;$FE44
	.dc.l	fe_asin		;$FE45
	.dc.l	fe_acos		;$FE46
	.dc.l	fe_log10	;$FE47
	.dc.l	fe_log2		;$FE48
	.dc.l	fe_dfrexp	;$FE49
	.dc.l	fe_dldexp	;$FE4A
	.dc.l	fe_daddone	;$FE4B
	.dc.l	fe_dsubone	;$FE4C
	.dc.l	fe_ddivtwo	;$FE4D
	.dc.l	fe_dieecnv	;$FE4E
	.dc.l	fe_ieedcnv	;$FE4F
	.dc.l	fe_fval		;$FE50
	.dc.l	fe_fusing	;$FE51
	.dc.l	fe_stof		;$FE52
	.dc.l	fe_ftos		;$FE53
	.dc.l	fe_fecvt	;$FE54
	.dc.l	fe_ffcvt	;$FE55
	.dc.l	fe_fgcvt	;$FE56
	.dc.l	fe_undefined	;$FE57
	.dc.l	fe_ftst		;$FE58
	.dc.l	fe_fcmp		;$FE59
	.dc.l	fe_fneg		;$FE5A
	.dc.l	fe_fadd		;$FE5B
	.dc.l	fe_fsub		;$FE5C
	.dc.l	fe_fmul		;$FE5D
	.dc.l	fe_fdiv		;$FE5E
	.dc.l	fe_fmod		;$FE5F
	.dc.l	fe_fabs		;$FE60
	.dc.l	fe_fceil	;$FE61
	.dc.l	fe_ffix		;$FE62
	.dc.l	fe_ffloor	;$FE63
	.dc.l	fe_ffrac	;$FE64
	.dc.l	fe_fsgn		;$FE65
	.dc.l	fe_fsin		;$FE66
	.dc.l	fe_fcos		;$FE67
	.dc.l	fe_ftan		;$FE68
	.dc.l	fe_fatan	;$FE69
	.dc.l	fe_flog		;$FE6A
	.dc.l	fe_fexp		;$FE6B
	.dc.l	fe_fsqr		;$FE6C
	.dc.l	fe_fpi		;$FE6D
	.dc.l	fe_fnpi		;$FE6E
	.dc.l	fe_fpower	;$FE6F
	.dc.l	fe_frnd		;$FE70
	.dc.l	fe_fsinh	;$FE71
	.dc.l	fe_fcosh	;$FE72
	.dc.l	fe_ftanh	;$FE73
	.dc.l	fe_fatanh	;$FE74
	.dc.l	fe_fasin	;$FE75
	.dc.l	fe_facos	;$FE76
	.dc.l	fe_flog10	;$FE77
	.dc.l	fe_flog2	;$FE78
	.dc.l	fe_ffrexp	;$FE79
	.dc.l	fe_fldexp	;$FE7A
	.dc.l	fe_faddone	;$FE7B
	.dc.l	fe_fsubone	;$FE7C
	.dc.l	fe_fdivtwo	;$FE7D
	.dc.l	fe_fieecnv	;$FE7E
	.dc.l	fe_ieefcnv	;$FE7F
	.dcb.l	96,fe_undefined
	.dc.l	fe_clmul	;$FEE0
	.dc.l	fe_cldiv	;$FEE1
	.dc.l	fe_clmod	;$FEE2
	.dc.l	fe_cumul	;$FEE3
	.dc.l	fe_cudiv	;$FEE4
	.dc.l	fe_cumod	;$FEE5
	.dc.l	fe_cltod	;$FEE6
	.dc.l	fe_cdtol	;$FEE7
	.dc.l	fe_cltof	;$FEE8
	.dc.l	fe_cftol	;$FEE9
	.dc.l	fe_cftod	;$FEEA
	.dc.l	fe_cdtof	;$FEEB
	.dc.l	fe_cdcmp	;$FEEC
	.dc.l	fe_cdadd	;$FEED
	.dc.l	fe_cdsub	;$FEEE
	.dc.l	fe_cdmul	;$FEEF
	.dc.l	fe_cddiv	;$FEF0
	.dc.l	fe_cdmod	;$FEF1
	.dc.l	fe_cfcmp	;$FEF2
	.dc.l	fe_cfadd	;$FEF3
	.dc.l	fe_cfsub	;$FEF4
	.dc.l	fe_cfmul	;$FEF5
	.dc.l	fe_cfdiv	;$FEF6
	.dc.l	fe_cfmod	;$FEF7
	.dc.l	fe_cdtst	;$FEF8
	.dc.l	fe_cftst	;$FEF9
	.dc.l	fe_cdinc	;$FEFA
	.dc.l	fe_cfinc	;$FEFB
	.dc.l	fe_cddec	;$FEFC
	.dc.l	fe_cfdec	;$FEFD
	.dc.l	fe_fevarg	;$FEFE
	.dc.l	fe_fevecs	;$FEFF

;----------------------------------------------------------------
;未定義のFEファンクションコール
fe_undefined::
	exit

;----------------------------------------------------------------
;$FE00	__LMUL
;	4バイト符号つき整数どうしの乗算をします。
;<d0.l:被乗数
;<d1.l:乗数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフロー)
fe_lmul::
	muls.l	d1,d0
	svs.b	d7
	neg.b	d7
	exit	D7

;----------------------------------------------------------------
;$FE01	__LDIV
;	4バイト符号つき整数どうしの除算をします。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果
;>c-flag:cs=エラー(除数が0)
fe_ldiv::
	tst.l	d1
	beq	@f
	divs.l	d1,d0
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE02	__LMOD
;	4バイト符号つき整数どうしの除算の剰余を計算します。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果
;>c-flag:cs=エラー(除数が0)
fe_lmod::
	tst.l	d1
	beq	@f
	move.l	d1,-(sp)
	exg.l	d0,d1
	divsl.l	d0,d0:d1
	exit	_,d1

@@:	exit	C

;----------------------------------------------------------------
;$FE04	__UMUL
;	4バイト符号なし整数どうしの乗算をします。
;<d0.l:被乗数
;<d1.l:乗数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフロー)
fe_umul::
	mulu.l	d1,d0
	svs.b	d7
	neg.b	d7
	exit	D7

;----------------------------------------------------------------
;$FE05	__UDIV
;	4バイト符号なし整数どうしの除算をします。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果
;>c-flag:cs=エラー(除数が0)
fe_udiv::
	tst.l	d1
	beq	@f
	divu.l	d1,d0
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE06	__UMOD
;	4バイト符号なし整数どうしの除算の剰余を計算します。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果
;>c-flag:cs=エラー(除数が0)
fe_umod::
	tst.l	d1
	beq	@f
	move.l	d1,-(sp)
	exg.l	d0,d1
	divsl.l	d0,d0:d1
	exit	_,d1

@@:	exit	C

;----------------------------------------------------------------
;$FE08	__IMUL
;	4バイト符号なし整数どうしの乗算をします。
;<d0.l:被乗数
;<d1.l:乗数
;>d0.l:演算結果の上位4バイト
;>d1.l:演算結果の下位4バイト
fe_imul::
	move.l	d1,d7
	mulu.l	d0,d1
	bvs	@f
	moveq.l	#0,d0
	exit

@@:	move.l	d3,-(sp)
		move.l	d2,-(sp)
	move.l	d7,d1
	move.l	d0,d3
	swap.w	d3
	swap.w	d7
	move.w	d3,d2
	mulu.w	d1,d2
	mulu.w	d0,d1
	mulu.w	d7,d0
	mulu.w	d3,d7
	add.l	d2,d0
		clr.w	d3
	addx.w	d3,d3
	swap.w	d1
	add.w	d0,d1
	swap.w	d1
	move.w	d3,d0
	swap.w	d0
	addx.l	d7,d0
	exit	d2,d3

;----------------------------------------------------------------
;$FE09	__IDIV
;	4バイト符号なし整数どうしの除算をします。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果(商)
;>d1.l:演算結果(剰余)
;>c-flag:cs=エラー(除数が0)
fe_idiv::
	tst.l	d1
	beq	@f
	divul.l	d1,d1:d0
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE0C	__RANDOMIZE
;	-32768から32767までの範囲で乱数のもとをセットします。
;<d0.l:4バイト符号つき整数
;	引数の値が正しくない場合、乱数は初期化されません。
fe_randomize::
	bsr	randomize
	moveq.l	#0,d0
	exit

;?d0/d7/a6
randomize::
	lea.l	(rnd_table,pc),a6
	moveq.l	#54,d7
@@:	mulu.w	#15625,d0
	addq.w	#1,d0
	move.w	d0,(a6)+
	move.w	d0,(a6)+
	dbra	d7,@b
	move.w	#54,rnd_count
	bsr	rnd_shuffle
	bsr	rnd_shuffle
;;;	bsr	rnd_shuffle
;?d0/d7/a6
rnd_shuffle::
	lea.l	(rnd_table,pc),a6
	moveq.l	#24-1,d7
@@:	move.l	(4*31,a6),d0
	sub.l	d0,(a6)+
	dbra	d7,@b
	moveq.l	#31-1,d7
@@:	move.l	(-4*24,a6),d0
	sub.l	d0,(a6)+
	dbra	d7,@b
	rts

rnd_count::
	.dc.w	-1
rnd_table::
	.dcb.l	55,0

;----------------------------------------------------------------
;$FE0D	__SRAND
;	0から65535までの範囲で乱数のもとをセットします。
;<d0.l:4バイト符号つき整数
;	引数の値が正しくない場合、乱数は初期化されません。
fe_srand::
	bsr	srand
	moveq.l	#0,d0
	exit

;?d0/d7/a6
srand::
	lea.l	(rand_table,pc),a6
	moveq.l	#54,d7
@@:	mulu.w	#15625,d0
	addq.w	#1,d0
	move.w	d0,(a6)+
	dbra	d7,@b
	move.w	#54,rand_count
;;;	bsr	rand_shuffle
;?d0/d7/a6
rand_shuffle::
	lea.l	(rand_table,pc),a6
	moveq.l	#24-1,d7
@@:	move.w	(2*31,a6),d0
	sub.w	d0,(a6)+
	dbra	d7,@b
	moveq.l	#31-1,d7
@@:	move.w	(-2*24,a6),d0
	sub.w	d0,(a6)+
	dbra	d7,@b
	rts

rand_count::
	.dc.w	-1
rand_table::
	.dcb.w	55,0

;----------------------------------------------------------------
;$FE0E	__RAND
;	4バイト符号つき整数の乱数を返します。
;>d0.l:4バイト符号つき整数(0以上32767以内)
1:	moveq.l	#51,d0
	bsr	srand
fe_rand::
	move.w	(rand_count,pc),d0
	bmi	1b
	cmp.w	#54,d0
	bne	2f
	bsr	rand_shuffle
	moveq.l	#-1,d0
2:	addq.w	#1,d0
	move.w	d0,rand_count
	move.w	(rand_table,pc,d0.w*2),d0
	and.l	#$00007FFF,d0
	exit

;----------------------------------------------------------------
;$FE10	__STOL
;	文字列を4バイト符号つき整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号つき整数
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
fe_stol::
	moveq.l	#' ',d7
		moveq.l	#0,d0
1:	move.b	(a0)+,d0
		cmp.b	d7,d0
	beq	1b
	cmp.b	#9,d0
	beq	1b
	cmp.b	#'+',d0
	beq	2f
	cmp.b	#'-',d0
	bne	3f
	moveq.l	#0,d7
2:	move.b	(a0)+,d0
3:	sub.b	#'0',d0
	bcs	6f
	cmp.b	#10,d0
	bcc	6f
	movea.w	d7,a6			;0=負,その他=正
		move.b	(a0)+,d7
	sub.b	#'0',d7
	bcs	5f
	cmp.b	#10,d7
	bcc	5f
4:	mulu.l	#10,d0
	bvs	8f
	add.l	d7,d0
	bcs	8f
	move.b	(a0)+,d7
		sub.b	#'0',d7
	bcs	5f
	cmp.b	#10,d7
	bcs	4b
5:	subq.w	#1,a0
		move.w	a6,d7
	beq	7f
;正
	tst.l	d0
	bmi	9f
	exit	_

;数値の記述法がおかしい
6:	subq.w	#1,a0
	exit	C,N

;負
7:	neg.l	d0
		tst.l	d0
	bgt	9f
	exit	_

;オーバーフロー
8:	subq.w	#1,a0
9:	exit	C,V

;----------------------------------------------------------------
;$FE11	__LTOS
;	4バイト符号つき整数を文字列に変換します。
;<d0.l:4バイト符号つき整数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
fe_ltos::
	tst.l	d0
	beq	8f
	movem.l	d0-d1,-(sp)		;フラグ保存
	bpl	1f
	move.b	#'-',(a0)+
		neg.l	d0
1:	lea.l	9f(pc),a6
2:	cmp.l	(a6)+,d0
	bcs	2b
	move.l	-4(a6),d1
3:	moveq.l	#'0'-1,d7
4:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	4b
	move.b	d7,(a0)+
		add.l	d1,d0
	move.l	(a6)+,d1
	bne	3b
	clr.b	(a0)
	exit	d0,d1

8:	move.b	#'0',(a0)+
		clr.b	(a0)
	exit

9:	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0

;----------------------------------------------------------------
;$FE12	__STOH
;	16進数を表す文字列を4バイト符号なし整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号なし整数
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
fe_stoh::
	bsr	stoh
	exit	D7

;16進数を表す文字列を4バイト符号なし整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号なし整数
;>d7.b:CCR
;>z-flag:ne=エラー
stoh:
	moveq.l	#-'0',d7
		add.b	(a0)+,d7
	bmi	3f
	moveq.l	#0,d0
	cmp.b	#10,d7
	bcs	1f
	and.b	#$DF,d7
		subq.b	#'A'-('9'+1),d7
	cmp.b	#10,d7
	bcs	3f
	cmp.b	#16,d7
	bcc	3f
1:	or.b	d7,d0
		moveq.l	#-'0',d7
	add.b	(a0)+,d7
	bmi	4f
	cmp.b	#10,d7
	bcs	2f
	and.b	#$DF,d7
		subq.b	#'A'-('9'+1),d7
	cmp.b	#10,d7
	bcs	4f
	cmp.b	#16,d7
	bcc	4f
2:	mulu.l	#16,d0
	bvc	1b
	subq.w	#1,a0
	moveq.l	#0|0|0|V|C,d7
	rts

3:	subq.w	#1,a0
	moveq.l	#0|N|0|0|C,d7
	rts

4:	subq.w	#1,a0
	moveq.l	#0,d7
	rts

;----------------------------------------------------------------
;$FE13	__HTOS
;	4バイト符号なし整数を16進数表現の文字列に変換します。
;<d0.l:4バイト符号なし整数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
fe_htos::
	tst.l	d0
	beq	8f
	move.l	d1,-(sp)		;d0は元に戻るので保護する必要がない
		moveq.l	#8-1,d1
1:	rol.l	#4,d0
		moveq.l	#$0F,d7
	and.b	d0,d7
	dbne	d1,1b
	bra	3f

2:	rol.l	#4,d0
		moveq.l	#$0F,d7
	and.b	d0,d7
3:	move.b	9f(pc,d7.w),(a0)+
	dbra	d1,2b
	clr.b	(a0)
	exit	d1

8:	move.b	#'0',(a0)+
		clr.b	(a0)
	exit

9:	.dc.b	'0123456789ABCDEF'

;----------------------------------------------------------------
;$FE14	__STOO
;	8進数を表す文字列を4バイト符号なし整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号なし整数
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
fe_stoo::
	bsr	stoo
	exit	D7

;8進数を表す文字列を4バイト符号なし整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号なし整数
;>d7.b:CCR
;>z-flag:ne=エラー
stoo:
	moveq.l	#-('7'+1),d7
		add.b	(a0)+,d7
	bpl	2f
	addq.b	#8,d7
	bmi	2f
	moveq.l	#0,d0
1:	or.b	d7,d0
		moveq.l	#-('7'+1),d7
	add.b	(a0)+,d7
	bpl	3f
	addq.b	#8,d7
	bmi	3f
	mulu.l	#8,d0
	bvc	1b
	subq.w	#1,a0
	moveq.l	#0|0|0|V|C,d7
	rts

2:	subq.w	#1,a0
	moveq.l	#0|N|0|0|C,d7
	rts

3:	subq.w	#1,a0
	moveq.l	#0,d7
	rts

;----------------------------------------------------------------
;$FE15	__OTOS
;	4バイト符号なし整数を8進数表現の文字列に変換します。
;<d0.l:4バイト符号なし整数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
fe_otos::
	tst.l	d0
	beq	8f
	move.l	d1,-(sp)		;d0は元に戻るので保護する必要がない
	moveq.l	#11-1,d1
		rol.l	#2,d0
	moveq.l	#$03,d7
		and.b	d0,d7
	bne	3f
	moveq.l	#10-1,d1
1:	rol.l	#3,d0
		moveq.l	#$07,d7
	and.b	d0,d7
	dbne	d1,1b
	bra	3f

2:	rol.l	#3,d0
		moveq.l	#$07,d7
	and.b	d0,d7
3:	add.b	#'0',d7
		move.b	d7,(a0)+
	dbra	d1,2b
	clr.b	(a0)
	exit	d1

8:	move.b	#'0',(a0)+
		clr.b	(a0)
	exit

;----------------------------------------------------------------
;$FE16	__STOB
;	2進数を表す文字列を4バイト符号なし整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号なし整数
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
fe_stob::
	bsr	stob
	exit	D7

;2進数を表す文字列を4バイト符号なし整数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト符号なし整数
;>d7.b:CCR
;>z-flag:ne=エラー
stob:
	moveq.l	#-('1'+1),d7
		add.b	(a0)+,d7
	bpl	2f
	addq.b	#2,d7
	bmi	2f
	moveq.l	#0,d0
1:	or.b	d7,d0
		moveq.l	#-('1'+1),d7
	add.b	(a0)+,d7
	bpl	3f
	addq.b	#2,d7
	bmi	3f
	add.l	d0,d0
	bcc	1b
	subq.w	#1,a0
	moveq.l	#0|0|0|V|C,d7
	rts

2:	subq.w	#1,a0
	moveq.l	#0|N|0|0|C,d7
	rts

3:	subq.w	#1,a0
	moveq.l	#0,d7
	rts

;----------------------------------------------------------------
;$FE17	__BTOS
;	4バイト符号なし整数を2進数表現の文字列に変換します。
;<d0.l:4バイト符号なし整数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
fe_btos::
	tst.l	d0
	beq	8f
	move.l	d1,-(sp)		;d0は元に戻るので保護する必要がない
	moveq.l	#32-1,d1
1:	rol.l	#1,d0
		moveq.l	#$01,d7
	and.b	d0,d7
	dbne	d1,1b
	bra	3f

2:	rol.l	#1,d0
		moveq.l	#$01,d7
	and.b	d0,d7
3:	add.b	#'0',d7
		move.b	d7,(a0)+
	dbra	d1,2b
	clr.b	(a0)
	exit	d1

8:	move.b	#'0',(a0)+
		clr.b	(a0)
	exit

;----------------------------------------------------------------
;$FE18	__IUSING
;	4バイト符号つき整数を文字列に変換します。
;<d0.l:4バイト符号つき整数
;<d1.l:桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;<(a0):変換された文字列
fe_iusing::
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	tst.l	d0
	beq	6f
	lea.l	9f(pc),a6
	bmi	7f
;正
1:	addq.w	#1,d1
	cmp.l	(a6)+,d0
	bcs	1b
	sub.w	#12,d1
	bmi	3f
	moveq.l	#' ',d7
2:	move.b	d7,(a0)+
	dbra	d1,2b
3:	move.l	-4(a6),d1
4:	moveq.l	#'0'-1,d7
5:	addq.b	#1,d7
	sub.l	d1,d0
	bcc	5b
	add.l	d1,d0
	move.b	d7,(a0)+
	move.l	(a6)+,d1
	bne	4b
	clr.b	(a0)
	exit	d0,d1

;0
6:	subq.w	#2,d1
	bmi	3f
	moveq.l	#' ',d7
2:	move.b	d7,(a0)+
	dbra	d1,2b
3:	move.b	#'0',(a0)+
	clr.b	(a0)
	exit	d0,d1

;負
7:	neg.l	d0
1:	addq.w	#1,d1
	cmp.l	(a6)+,d0
	bcs	1b
	sub.w	#13,d1
	bmi	3f
	moveq.l	#' ',d7
2:	move.b	d7,(a0)+
	dbra	d1,2b
3:	move.b	#'-',(a0)+
	move.l	-4(a6),d1
4:	moveq.l	#'0'-1,d7
5:	addq.b	#1,d7
	sub.l	d1,d0
	bcc	5b
	add.l	d1,d0
	move.b	d7,(a0)+
	move.l	(a6)+,d1
	bne	4b
	clr.b	(a0)
	exit	d0,d1

9:	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0

;----------------------------------------------------------------
;$FE1A	__LTOD
;	4バイト符号つき整数を8バイト浮動小数点数に変換します。
;<d0.l:4バイト符号つき整数
;>d0-d1:変換された8バイト浮動小数点数
fe_ltod::
	fmove.l	d0,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE1B	__DTOL
;	8バイト浮動小数点数を4バイト符号つき整数に変換します。
;<d0-d1:8バイト浮動小数点数
;>d0.l:変換された4バイト符号つき整数
;>c-flag:cs=エラー(変換結果が4バイト符号つき整数の値の範囲を超えた)
;	小数部分は切り捨てられます。
;	4バイト符号つき整数の値は次の範囲です。
;		-2147483648～+2147483647
fe_dtol::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fintrz.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.l	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|0|0|0|0|0|0,d7	;iv000000
	bne	@f
	exit

@@:	add.b	d7,d7			;v0000000
	rol.b	#2,d7			;000000v0
	addq.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE1C	__LTOF
;	4バイト符号つき整数を4バイト浮動小数点数に変換します。
;<d0.l:4バイト符号つき整数
;<d0.l:変換された4バイト浮動小数点数
fe_ltof::
	fmove.l	d0,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE1D	__FTOL
;	4バイト浮動小数点数を4バイト符号つき整数に変換します。
;<d0.l:4バイト浮動小数点数
;>d0.l:変換された4バイト符号つき整数
;>c-flag:cs=エラー(変換結果が4バイト符号つき整数の値の範囲を超えた)
;	小数部分は切り捨てられます。
;	4バイト符号つき整数の値は次の範囲です。
;		-2147483648～+2147483647
fe_ftol::
	fmove.l	#$00000000,fpsr
	fintrz.s	d0,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.l	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|0|0|0|0|0|0,d7	;iv000000
	bne	@f
	exit

@@:	add.b	d7,d7			;v0000000
	rol.b	#2,d7			;000000v0
	addq.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE1E	__FTOD
;	4バイト浮動小数点数を8バイト浮動小数点数に変換します。
;<d0.l:4バイト浮動小数点数
;>d0-d1:変換された8バイト浮動小数点数
fe_ftod::
	fmove.s	d0,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE1F	__DTOF
;	8バイト浮動小数点数を4バイト浮動小数点数に変換します。
;<d0-d1:8バイト浮動小数点数
;>d0.l:変換された4バイト浮動小数点数
;>c-flag:cs=エラー(引数が4バイト浮動小数点数で表現できない)
fe_dtof::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|0|0|0|0|0|0,d7	;iv000000
	bne	@f
	exit

@@:	add.b	d7,d7			;v0000000
	rol.b	#2,d7			;000000v0
	addq.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE20	__VAL
;	文字列を8バイト浮動小数点数に変換します。
;<a0.l:文字列を指すポインタ
;>d0-d1:変換された8バイト浮動小数点数
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
;	文字列が10進数以外の場合、その先頭には、2進数では'&B'、8進数では'&O'、
;	16進数では'&H'が必要です。
;	10進数の場合、返り値として次のものが追加されます。
;		d2.w	整数フラグ
;		d3.l	整数値
;	文字列が整数(小数部及び指数部がない)で、かつ4バイト符号つき整数で表現可能な場合、
;	整数フラグは$FFFFで、整数値にその値がはいります。
;	それ以外の場合は整数フラグは0となります。
fe_val::
1:	move.b	(a0)+,d0
	cmp.b	#' ',d0
	beq	1b
	cmp.b	#9,d0
	beq	1b
	cmp.b	#'&',d0
	beq	2f
	subq.w	#1,a0
	bra	fe_stod

2:	moveq.l	#0,d2			;整数フラグ
	moveq.l	#0,d3
	move.b	(a0)+,d0
	cmp.b	#'H',d0
	beq	3f
	cmp.b	#'B',d0
	beq	4f
	cmp.b	#'O',d0
	beq	5f
	subq.w	#1,a0			;純正品は戻していない
	exit	C,N

3:	bsr	stoh
	bne	6f
	bra	fe_ltod

4:	bsr	stob
	bne	6f
	bra	fe_ltod

5:	bsr	stoo
	bne	6f
	bra	fe_ltod

6:	exit	D7

;----------------------------------------------------------------
;$FE21	__USING
;	8バイト浮動小数点数を文字列に変換します。
;<d0-d1:8バイト浮動小数点数
;<d2.l:整数部分の桁数
;<d3.l:小数部分の桁数
;<d4.l:アトリビュート
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
;	アトリビュートはビット0～6をセットすることにより以下のような数値表現ができます。
;	ビット0:左側を'*'でパッティングします。
;	ビット1:'\'を先頭に付加します。
;	ビット2:整数部分を3桁ごとに','で区切ります。
;	ビット3:指数形式で表現します。
;	ビット4:正数の場合'+'を先頭に付加します。
;	ビット5:正数の場合'+'を、負数の場合'-'を最後尾に付加します。
;	ビット6:正数の場合' 'を、負数の場合'-'を最後尾に付加します。
fe_using::
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	bsr	using
	exit

;----------------------------------------------------------------
;using
;浮動小数点数を文字列に変換する
;<fp0:浮動小数点数(#INFや#NANは不可)
;<d2.l:整数部の桁数(負数は不可,アトリビュートで指定しない限り負符号を含む桁数,
;	指数形式を指定しない限り入り切らなければ何桁でもはみ出す)
;<d3.l:小数部の桁数(負数は不可,0でも小数点を書く,-1のとき小数点を書かない)
;<d4.l:アトリビュート
;	bit0	左側が余っていたら'*'で埋める(整数部の桁数に含まれる,指数形式では無効)
;	bit1	先頭に'\'を付ける(整数部の桁数に含まれる,指数形式では無効,符号と数字の間に入る)
;	bit2	整数部を3桁毎に','で区切る(整数部の桁数に含まれる,指数形式では無効)
;	bit3	指数形式(整数部の桁数から符号' 'or'-'を除いた桁数の位置に小数点を置く)
;	bit4	先頭に正のとき'+',負のとき'-'を付ける(整数部の桁数に含まれない)
;	bit5	末尾に正のとき'+',負のとき'-'を付ける(小数部の桁数に含まれない)
;	bit6	末尾に正のとき' ',負のとき'-'を付ける(小数部の桁数に含まれない)
;<a0.l:バッファの先頭
;>(a0):文字列
;>a0.l:文字列の末尾の0の位置
;*a0,?d0-d4/d7/fp0
using:
	movem.l	d5-d6,-(sp)
;整数部の桁数の調整
	tst.l	d2
	bgt	@f
	moveq.l	#1,d2			;整数部は少なくとも1桁必要
@@:
;指数形式かどうかで分岐
	btst.l	#3,d4
	bne	usingExp		;指数形式
;指数形式ではないとき
usingNotExp:
;小数部の桁数の調整
	cmp.l	#-1,d3
	bge	@f
	moveq.l	#-1,d3			;指数形式でないとき小数部の桁数は-1以上
@@:
;10進正規化
	bsr	dexp
;整数部が入り切るように桁数を調整する
	cmp.l	d2,d0
	blt	@f
	move.l	d0,d2
@@:
;左側のスペースを書き込む
	movea.l	a0,a6			;バッファの先頭
;<a6.l:バッファの先頭
	move.l	d2,d5			;整数部の桁数(1以上)
	move.l	d0,d2
	sub.l	d0,d5			;スペースの桁数
	beq	2f
	move.l	d5,d0			;スペースの桁数
1:	move.b	#' ',(a0)+
	subq.l	#1,d0
	bne	1b
2:
;<d5.l:スペースの桁数
;文字列に変換する
	move.l	d2,d6			;整数部の桁数(1以上)
	add.l	d3,d6			;スペースを除く桁数(1以上)
	tst.l	d3
	bpl	@f
	addq.l	#1,d6			;小数点以下の桁数が-1だったときは0とみなす
@@:
;<d6.l:スペースを除く桁数
	move.l	d6,d0			;スペースを除く桁数(1以上)
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
	add.b	#'0',d7			;'0'～'9'にする
	fsub.x	fp1,fp0
	move.b	d7,(a0)+
	subq.l	#1,d0
	bne	1b
2:
;四捨五入
	fcmp.s	#0f0.5,fp0
	fblt	3f			;次の桁が5未満なので切り捨てる
;繰り上げる
	move.l	d6,d0			;スペースを除く桁数(1以上)
1:	addq.b	#1,-(a0)		;繰り上がり
	cmpi.b	#'9',(a0)
	bls	3f			;上の位に納まったので終わり
	move.b	#'0',(a0)		;上の位も溢れた
	subq.l	#1,d0
	bne	1b
2:
;最上位から繰り上がった
	addq.l	#1,d2			;整数部の桁数が1増える
	subq.l	#1,d5			;スペースの桁数を減らす
	bcc	@f			;スペースがあった
	move.b	#'0',(a6,d6.l)		;スペースがなかったので右にずらす
	lea.l	(1,a6),a0
	moveq.l	#0,d5
@@:	move.b	#'1',-(a0)		;先頭の1を書く
	addq.l	#1,d6			;スペースを除く桁数が1増えた
3:
;文字列の末尾の0(番兵)を置く
	lea.l	(a6,d5.l),a0		;数字の先頭
	clr.b	(a0,d6.l)		;末尾の0を書き込む(文字列シフトのときの番兵に必要)
;小数点を入れる(小数点以下の桁数が0でも入れる,-1のときは入れない)
	tst.l	d3			;小数点以下の桁数
	bmi	@f			;-1のときは小数点を入れない
	adda.l	d2,a0			;小数点の位置
	bsr	usingShiftRight		;右にずらす
	move.b	#'.',(a0)		;小数点を書く
	addq.l	#1,d6			;スペースを除く桁数が1増えた
@@:
;整数部を3桁毎に','で区切る
	btst.l	#2,d4
	beq	3f
	move.l	d2,d0			;整数部の桁数
;以降ではd2は不要
	bra	2f

1:	lea.l	(a6,d5.l),a0		;数字の先頭
	subq.l	#1,d5			;スペースの桁数を1減らす
	bcc	4f
;スペースがないので右にずらす
	moveq.l	#0,d5
	adda.l	d0,a0			;','を入れる位置
	bsr	usingShiftRight		;右にずらす
	bra	5f

;スペースがあるので左にずらす
;<d0.l:','の左側の数字の桁数=ずらす範囲の桁数
;<a0.l:数字の先頭=ずらす範囲の先頭
4:	bsr	usingShiftLeft		;左にずらす
;<a0.l:ずらしてできた隙間の位置
5:	move.b	#',',(a0)
;;;	addq.l	#1,d2			;整数部の桁数が1増えた
	addq.l	#1,d6			;スペースを除く桁数が1増えた
2:	subq.l	#3,d0
	bgt	1b
3:
;先頭に'\'を付ける
	btst.l	#1,d4
	beq	2f
	subq.l	#1,d5
	bcc	1f
	moveq.l	#0,d5
	movea.l	a6,a0
	bsr	usingShiftRight
1:	move.b	#'\',(a6,d5.l)
;;;	addq.l	#1,d2			;整数部の桁数が1増えた
	addq.l	#1,d6			;スペースを除く桁数が1増えた
2:
;先頭に正のとき'+',負のとき'-'を付ける
	btst.l	#4,d4
	beq	2f
	lea.l	(a6,d5.l),a0		;スペースの直後
	bsr	usingShiftRight		;無条件に隙間を空ける
	addq.l	#1,d6			;スペースを除く桁数が1増えた
	moveq.l	#'+',d0			;正のとき'+'
	add.l	d1,d0
	add.l	d1,d0			;負のとき'-'
	move.b	d0,(a0)
	bra	3f
2:
;末尾に正のとき'+',負のとき'-'を付ける
	btst.l	#5,d4
	beq	2f
	lea.l	(a6,d5.l),a0		;スペースの直後
	adda.l	d6,a0			;末尾の0の位置
	moveq.l	#'+',d0			;正のとき'+'
	add.l	d1,d0
	add.l	d1,d0			;負のとき'-'
	move.b	d0,(a0)+
	clr.b	(a0)
	addq.l	#1,d6			;スペースを除く桁数が1増えた
	bra	3f
2:
;末尾に正のとき' ',負のとき'-'を付ける
	btst.l	#6,d4
	beq	2f
	lea.l	(a6,d5.l),a0		;スペースの直後
	adda.l	d6,a0			;末尾の0の位置
	tst.l	d1
	sne.b	d0
	and.b	#'-'-' ',d0
	add.b	#' ',d0
	move.b	d0,(a0)+
	clr.b	(a0)
	addq.l	#1,d6			;スペースを除く桁数が1増えた
	bra	3f
2:
;負符号を付ける
	tst.l	d1
	beq	2f			;正数
	subq.l	#1,d5
	bcc	1f
	moveq.l	#0,d5
	movea.l	a6,a0
	bsr	usingShiftRight
1:	move.b	#'-',(a6,d5.l)
;;;	addq.l	#1,d2			;整数部の桁数が1増えた
	addq.l	#1,d6			;スペースを除く桁数が1増えた
2:
;符号終わり
3:
;左側が余っていたら'*'で埋める
	btst.l	#0,d4
	beq	2f
	tst.l	d5
	beq	2f			;スペースがない
	movea.l	a6,a0			;バッファの先頭
;;;	add.l	d5,d2			;小数点の左側の桁数
	add.l	d5,d6			;スペースを除く桁数
1:	move.b	#'*',(a0)+
	subq.l	#1,d5
	bne	1b
2:	lea.l	(a6,d5.l),a0		;'*'で埋めなかったとき必要
	adda.l	d6,a0
	clr.b	(a0)			;文字列の末尾
	movem.l	(sp)+,d5-d6
	rts


;指数形式のとき
usingExp:
;小数部の桁数の調整
	tst.l	d3
	bge	@f
	moveq.l	#0,d3			;指数形式のとき小数部の桁数は0以上
@@:
;符号の確認
;>d5.l:
;	bit0～7		先頭に正のとき付ける文字
;	bit8～15	末尾に正のとき付ける文字
;	bit16～23	先頭に負のとき付ける文字
;	bit24～31	末尾に負のとき付ける文字
	move.l	#('-'<<16)+('+'<<0),d5	;先頭に正のとき'+',負のとき'-'を付ける
;0,'-',0,'+'
	btst.l	#4,d4			;bit4をテスト
	bne	@f
	lsl.l	#8,d5			;末尾に正のとき'+',負のとき'-'を付ける
;'-',0,'+',0
	btst.l	#5,d4			;bit5をテスト
	bne	@f
	move.w	#' '<<8,d5		;末尾に正のとき' ',負のとき'-'を付ける
;'-',0,' ',0
	btst.l	#6,d4			;bit6をテスト
	bne	@f
	lsr.l	#8,d5			;先頭に正のとき' ',負のとき'-'を付ける
;0,'-',0,' '
@@:
;>d5.w:
;	bit0～7		先頭に付ける文字
;	bit8～15	末尾に付ける文字
;桁数の調整
	and.b	#%01110000,d4
	bne	@f			;符号の指定があるときは符号の桁数は含まれていない
	subq.l	#1,d2			;符号の桁数を引く
	bgt	@f
	moveq.l	#1,d2			;整数部は最低1桁必要
@@:
	move.l	d2,d6			;整数部の桁数
;符号の確認
	ftst.x	fp0
	fbge	@f
	fneg.x	fp0,fp0
	swap.w	d5
@@:
;先頭の符号
	tst.b	d5
	beq	@f
	move.b	d5,(a0)+
@@:	lsr.w	#8,d5
;文字列に変換
	add.l	d3,d2			;全体の桁数
	bsr	ecvt			;d0-d2/d7/a6を破壊する,a0は末尾の0の位置
;<d0.l:10進指数部(浮動小数点数が0のときは1)
;<d1.l:ここでは常に0
;<d3.l:小数部の桁数
;<d5.b:末尾に付ける文字
;<d6.l:整数部の桁数
;<a0.l:末尾の0のアドレス
	suba.l	d3,a0			;小数点が入る位置
	movea.l	a0,a6
	suba.l	d6,a6			;数字の先頭
;<a6.l:数字の先頭
	bsr	usingShiftRight		;右にずらす
	move.b	#'.',(a0)+
	adda.l	d3,a0			;数字の末尾
;0サプレス(浮動小数点数が0のときだけ必要)
	cmpi.b	#'0',(a6)
	bne	2f
	move.l	d6,d1
	subq.l	#1,d1
1:	move.b	#' ',(a6)+
	subq.l	#1,d1
	bne	1b
2:
;指数部を書く
	move.b	#'E',(a0)+
	moveq.l	#'+',d1
	sub.l	d6,d0			;指数部
	bpl	@f
	moveq.l	#'-',d1
	neg.l	d0
@@:	move.b	d1,(a0)+
;<d0.l:指数(整数)
	cmp.l	#1000,d0
	blo	2f
	move.l	#1000,d1
	moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
	sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
	move.b	d7,(a0)+
;指数を10進3桁で書く
;<d0.l:指数(整数)
2:	moveq.l	#100,d1
	moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
	sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
	move.b	d7,(a0)+
	moveq.l	#10,d1
	moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
	sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
	move.b	d7,(a0)+
	add.b	#'0',d0
	move.b	d0,(a0)+
;末尾の符号
	tst.b	d5
	beq	@f
	move.b	d5,(a0)+
@@:
	clr.b	(a0)			;文字列の末尾
	movem.l	(sp)+,d5-d6
	rts


;文字列を右に1桁ずらす
;<a0.l:ずらす範囲の先頭(末尾の0までずらす)
;>a0.l:変化しない
usingShiftRight:
	move.l	a0,-(sp)
@@:	tst.b	(a0)+
	bne	@b
@@:	move.b	-(a0),(1,a0)
	cmpa.l	(sp),a0
	bne	@b
	addq.l	#4,sp
	rts

;文字列を左に1桁ずらす
;<d0.l:ずらす範囲の桁数
;<a0.l:ずらす範囲の先頭(d0桁ずらす)
;>a0.l:ずらしてできた隙間の位置
usingShiftLeft:
	move.l	d0,-(sp)
	beq	2f
1:	move.b	(a0)+,(-2,a0)
	subq.l	#1,d0
	bne	1b
2:	subq.l	#1,a0
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;$FE22	__STOD
;	文字列を8バイト浮動小数点数に変換します。
;<a0.l:文字列を指すポインタ
;>d0-d1:変換された8バイト浮動小数点数
;>d2.w:整数フラグ
;>d3.l:整数値
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
;	文字列が整数(小数部及び指数部がない)で、かつ4バイト符号つき整数で表現可能な場合、
;	整数フラグは$FFFFで、整数値にその値がはいります。
;	それ以外の場合は整数フラグは0となります。

__	=	-128	;その他
BL	=	-6	;' '|$09
SH	=	-5	;'#'
DO	=	-4	;'.'
EX	=	-3	;'E'|'e'
PL	=	-2	;'+'
MI	=	-1	;'-'

;仮数部文字分類コードテーブル
table:
;		x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,xA,xB,xC,xD,xE,xF
	.dc.b	__,__,__,__,__,__,__,__,__,BL,__,__,__,__,__,__	;0x
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;1x
	.dc.b	BL,__,__,SH,__,__,__,__,__,__,__,PL,__,MI,DO,__	;2x
	.dc.b	+0,+1,+2,+3,+4,+5,+6,+7,+8,+9,__,__,__,__,__,__	;3x
	.dc.b	__,__,__,__,__,EX,__,__,__,__,__,__,__,__,__,__	;4x
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;5x
	.dc.b	__,__,__,__,__,EX,__,__,__,__,__,__,__,__,__,__	;6x
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;7x
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;8x
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;9x
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;Ax
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;Bx
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;Cx
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;Dx
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;Ex
	.dc.b	__,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__	;Fx

err4:
	subq.w	#1,a0
err3:
	subq.w	#1,a0
err2:
	subq.w	#1,a0
;エラー
err:
	subq.w	#1,a0
	moveq.l	#0|N|0|0|C,d7
	rts

;'#I'
sharpI:
	cmp.b	#'N',(a0)+
	bne	err3
;'#IN'
	cmp.b	#'F',(a0)+
	bne	err4
;'#INF'
	or.l	#$7FF00000,d0		;符号はそのまま
	moveq.l	#$00000000,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d7
	rts

;'#'
sharp:
	moveq.l	#'I',d0
	sub.b	(a0)+,d0
	beq	sharpI			;'#I'
	addq.b	#'N'-'I',d0
	bne	err2
;'#N'
	cmp.b	#'A',(a0)+
	bne	err3
;'#NA'
	cmp.b	#'N',(a0)+
	bne	err4
;'#NAN'
	move.l	#$7FFFFFFF,d0		;符号は無視
	moveq.l	#$FFFFFFFF,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d7
	rts

@@:	exit	D7

;?d7/a6/fp0
fe_stod::
	pea.l	@b(pc)
stod:
	lea.l	table(pc),a6		;仮数部用文字コード分類テーブル
	moveq.l	#0,d0			;bit31:仮数部の符号(0=正,1=負)
					;bit15～0:小数点以下の桁数(ダウンカウント)
	moveq.l	#0,d1			;指数部
	moveq.l	#0,d7			;bit31:指数部の符号(0=正,1=負)
					;bit15～0:ワーク
	fmove.s	#0f0,fp0
blank:
	move.b	(a0)+,d7
	move.b	(a6,d7.w),d7
	bpl	int			;'0'～'9'
	addq.b	#-BL,d7
	beq	blank			;スペースまたはタブ
	subq.b	#-(BL-PL),d7
	bpl	sign			;符号
	addq.b	#PL-DO,d7
	beq	frac			;'.'
	addq.b	#DO-SH,d7
	beq	sharp			;'#'
	bra	err

;符号
sign:
	move.b	d7,d0			;0=正,1=負
	ror.l	#1,d0
;
	move.b	(a0)+,d7		;符号の直後の文字
	move.b	(a6,d7.w),d7
	bpl	int			;'0'～'9'
	addq.b	#-DO,d7
	beq	frac			;'.'
	addq.b	#DO-SH,d7
	beq	sharp			;'#'
	bra	err

;'0'～'9'(整数部)
1:	fmul.s	#0f10,fp0
;<d7.b:仮数部の1桁目の値
int:
	fadd.l	d7,fp0
	move.b	(a0)+,d7		;次の文字
	move.b	(a6,d7.w),d7
	bpl	1b			;'0'～'9'
	addq.b	#-EX,d7
	beq	exp0			;'E'または'e'
	addq.b	#EX-DO,d7
	bne	intChk0			;'0'～'9'|'E'|'e'|'.'以外
;'.'
	move.b	(a0)+,d7		;次の文字
	move.b	(a6,d7.w),d7
	bmi	2f
1:	subq.w	#1,d0			;小数点以下の桁数(ダウンカウント)
	fmul.s	#0f10,fp0
	fadd.l	d7,fp0
frac:
	move.b	(a0)+,d7		;次の文字
	move.b	(a6,d7.w),d7
	bpl	1b			;'0'～'9'
2:
;仮数部終わり
;符号を付ける
	tst.l	d0
	bpl	@f
	fneg.x	fp0,fp0
@@:
;<d7.b:仮数部の次の文字の分類コード
	addq.b	#-EX,d7
	bne	expChk			;小数点を動かして終わり
	bra	exp

exp0:
;符号を付ける
	tst.l	d0
	bpl	@f
	fneg.x	fp0,fp0
@@:
;'E'または'e'
exp:
	move.b	(a0)+,d7		;'E'の直後の文字
	move.b	(a6,d7.w),d7
	bgt	expHead			;'1'～'9'
	beq	expZrSp			;'0'
	addq.b	#-PL,d7
	bmi	err			;指数部の先頭が数字でも符号でもない
;指数部の符号
	ror.l	#1,d7
;
	move.b	(a0)+,d7		;指数部の符号の直後の文字
	move.b	(a6,d7.w),d7
	bgt	expHead			;'1'～'9'
	bmi	err			;指数部の符号の直後が数字でない
;指数部の先頭が0
expZrSp:
	move.b	(a0)+,d7		;'0'の次の文字
	move.b	(a6,d7.w),d7
	beq	expZrSp			;'0'をスキップする
	bmi	expChk			;指数部は0だった
;指数部の先頭の0以外の数字から
expHead:
	move.w	d7,d1
	move.b	(a0)+,d7		;指数部の上から2桁目
	move.b	(a6,d7.w),d7
	bmi	expEnd			;'0'～'9'以外
	mulu.w	#10,d1
	add.w	d7,d1
	move.b	(a0)+,d7		;指数部の上から3桁目
	move.b	(a6,d7.w),d7
	bmi	expEnd			;'0'～'9'以外
	mulu.w	#10,d1
	add.w	d7,d1
	move.b	(a0)+,d7		;指数部の上から4桁目
	move.b	(a6,d7.w),d7
	bpl	expErr			;指数部が4桁以上ならオーバーフローまたはアンダーフロー
;指数部終わり
expEnd:
	tst.l	d7
	bpl	@f			;指数部は正
	neg.w	d1			;指数部は負
@@:	add.w	d1,d0			;小数点以下の桁数分ずらす
	cmp.w	#512,d0
	bge	expOver			;512乗以上を取り除く
	cmp.w	#-512,d0
	ble	expUnder		;-512乗以下を取り除く
;指数部が0でなければ補正する
;<d4.w:指数部-小数点以下の桁数
expChk:
	tst.w	d0
	beq	intChk			;指数部が0なので整数チェックへ
	bmi	expLeft			;小数点を左へずらす
;小数点を右にずらす
	moveq.l	#$0F,d7
	and.w	d0,d7
	mulu.w	#12,d7
	fmul.x	(digit_1,pc,d7.w),fp0
	lsr.w	#4,d0
	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+16,fp0		;+16乗
@@:	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+32,fp0		;+32乗
@@:	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+64,fp0		;+64乗
@@:	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+128,fp0		;+128乗
@@:	beq	intChk			;整数チェックへ
	fmul.d	#0f1E+256,fp0		;+256乗
	bra	intChk			;整数チェックへ

;10の正のベキのテーブル
digit_1:
;  .rept %e,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;	.dc.d	0f1E+%e
;  .endm
	.dc.x	!3FFF00008000000000000000	;10^0
	.dc.x	!40020000A000000000000000	;10^1
	.dc.x	!40050000C800000000000000	;10^2
	.dc.x	!40080000FA00000000000000	;10^3
	.dc.x	!400C00009C40000000000000	;10^4
	.dc.x	!400F0000C350000000000000	;10^5
	.dc.x	!40120000F424000000000000	;10^6
	.dc.x	!401600009896800000000000	;10^7
	.dc.x	!40190000BEBC200000000000	;10^8
	.dc.x	!401C0000EE6B280000000000	;10^9
	.dc.x	!402000009502F90000000000	;10^10
	.dc.x	!40230000BA43B74000000000	;10^11
	.dc.x	!40260000E8D4A51000000000	;10^12
	.dc.x	!402A00009184E72A00000000	;10^13
	.dc.x	!402D0000B5E620F480000000	;10^14
	.dc.x	!40300000E35FA931A0000000	;10^15

;10の負のベキのテーブル
digit_2:
;  .rept %e,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
;	.dc.d	0f1E-%e
;  .endm
	.dc.x	!3FFF00008000000000000000	;10^-0
	.dc.x	!3FFB0000CCCCCCCCCCCCCCCD	;10^-1
	.dc.x	!3FF80000A3D70A3D70A3D70A	;10^-2
	.dc.x	!3FF5000083126E978D4FDF3B	;10^-3
	.dc.x	!3FF10000D1B71758E219652B	;10^-4
	.dc.x	!3FEE0000A7C5AC471B478422	;10^-5
	.dc.x	!3FEB00008637BD05AF6C69B5	;10^-6
	.dc.x	!3FE70000D6BF94D5E57A42BB	;10^-7
	.dc.x	!3FE40000ABCC77118461CEFC	;10^-8
	.dc.x	!3FE1000089705F4136B4A596	;10^-9
	.dc.x	!3FDD0000DBE6FECEBDEDD5BD	;10^-10
	.dc.x	!3FDA0000AFEBFF0BCB24AAFE	;10^-11
	.dc.x	!3FD700008CBCCC096F5088CB	;10^-12
	.dc.x	!3FD30000E12E13424BB40E12	;10^-13
	.dc.x	!3FD00000B424DC35095CD80E	;10^-14
	.dc.x	!3FCD0000901D7CF73AB0ACD8	;10^-15

;小数点を左にずらす
expLeft:
	neg.w	d0
	moveq.l	#$0F,d7
	and.w	d0,d7
	mulu.w	#12,d7
	fmul.x	(digit_2,pc,d7.w),fp0
	lsr.w	#4,d0
	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-16,fp0		;-16乗
@@:	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-32,fp0		;-32乗
@@:	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-64,fp0		;-64乗
@@:	beq	intChk			;整数チェックへ
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-128,fp0		;-128乗
@@:	beq	intChk			;整数チェックへ
	fmul.d	#0f1E-256,fp0		;-256乗
	bra	intChk

intChk0:
;符号を付ける
	tst.l	d0
	bpl	@f
	fneg.x	fp0,fp0
@@:
;整数チェック
intChk:
	subq.l	#1,a0
	moveq.l	#-1,d2
	fmove.l	#$00000000,fpsr
	fmove.l	fp0,d3
	fmove.l	fpsr,d7
	and.w	#FPES_OPERR|FPES_OVFL|FPES_INEX2|FPES_INEX1,d7
	beq	@f
	moveq.l	#0,d2
	moveq.l	#0,d3
@@:
;返却値を作る
	fmove.l	#$00000000,fpsr
	fmove.d	fp0,-(sp)
	move.l	(sp)+,d0
	move.l	(sp)+,d1
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	rts

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	rts

;指数部が範囲外
expErr:
	tst.l	d7			;指数部の符号を見る
	bpl	expOver			;オーバーフロー
;アンダーフロー
expUnder:
	subq.l	#1,a0
	moveq.l	#0,d0			;符号は付けない
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0|0|0|0|C,d7
	rts

;オーバーフロー
expOver:
	subq.l	#1,a0
	ftst.x	fp0			;仮数部が0のときはエラーにしない
	fbeq	@f
	clr.w	d0
	or.l	#$7FF00000,d0		;符号を付ける
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0|0|0|V|C,d7
	rts

@@:	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#-1,d2
	moveq.l	#0,d3
	moveq.l	#0,d7
	rts

;----------------------------------------------------------------
;$FE23	__DTOS
;	8バイト浮動小数点数を文字列に変換します。
;	d0,d1は壊れます。
;<d0-d1:8バイト浮動小数点数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
fe_dtos::
	move.l	d2,-(sp)
	cmp.l	#$7FF00000,d0
	bge	1f
	cmp.l	#$FFF00000,d0
	bhs	1f
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	bsr	dtos
	exit	d2

1:	bne	2f
	tst.l	d1
	bne	2f
	tst.l	d0
	bpl	@f
	move.b	#'-',(a0)+
@@:	move.l	#'#INF',(a0)+
	bra	3f

2:	move.l	#'#NAN',(a0)+
3:	clr.b	(a0)
	exit	d2

;----------------------------------------------------------------
;dtos
;浮動小数点数を全体の桁数を指定した浮動小数点表現または指数表現の文字列に変換する
;<a0.l:バッファの先頭
;<fp0:浮動小数点数(#INFや#NANは不可)
;>(a0):変換された文字列
;>a0.l:文字列の末尾の0のアドレス
;	負の値の場合は文字列の先頭にマイナス記号('-')が付加される
;	d2の桁数で表現できない場合は指数表現の文字列に変換する
;*a0,?d0-d2/fp0
dtos:
	moveq.l	#14,d2
	ftst.x	fp0
	fbeq	9f			;浮動小数点数が0
	fbgt	@f
	move.b	#'-',(a0)+
@@:	clr.b	(a0)+			;バッファの先頭または'-'の直後は0(番兵)
	bsr	ecvt
	movea.l	a0,a6			;最後の桁の次の位置
		suba.l	d2,a0
@@:	cmp.b	#'0',-(a6)		;0のときは番兵で止まる
	beq	@b
;<a6.l:'0'でない最後の桁の位置または番兵の位置
	cmpa.l	a0,a6
	blo	7f			;0だった(符号が必要なのでd1を壊す前に飛ぶこと)
	addq.l	#1,a6
;<a6.l:'0'でない最後の桁の次の位置
	move.l	a6,d1			;0でない最後の桁の次の位置
		sub.l	a0,d1		;下位の0を除いた桁数
;     ←── d1 ──→
;    a0              a6
;    ↓              ↓
;     ←───── d2 ─────→      d0
; －□ＸＸＸＸＸＸＸＸ００００００×１０
;    ↑
;－←・→＋
;    d0
	cmp.l	d2,d0
	bgt	1f			;指数が大きすぎる(指数形式)
	tst.l	d0
	bgt	4f			;途中に小数点が入る(整数部.小数部)
;指数部が0以下(指数表現でなければ0.に続く)
	neg.l	d0			;0.の右側の0の数
		add.l	d0,d1		;0.の右側の桁数
;    ←─── d1 ───→
;       a0              a6
;       ↓              ↓
;    ←───── d2 ─────→
;０．００ＸＸＸＸＸＸＸＸ００００００
;  → d0 ←
	cmp.l	d2,d1
	ble	5f			;先頭に0.00…を追加する(指数は不要)
;指数が小さすぎる(指数形式)
;<d1.l:有効な桁数
	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	sub.l	d0,d1			;0でない部分の桁数
		adda.l	d1,a0		;最後の桁の右側
	subq.l	#1,d1
	bne	@f
	subq.l	#1,a0			;'.E'のとき'E'だけにする
@@:	move.b	#'E',(a0)+
		move.b	#'-',(a0)+
	bra	2f

;指数が大きすぎる(指数形式)
;<d1.l:有効な桁数
1:	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	adda.l	d1,a0			;最後の桁の右側
		subq.l	#1,d1
	bne	@f
	subq.l	#1,a0			;'.E'のとき'E'だけにする
@@:		move.b	#'E',(a0)+
	move.b	#'+',(a0)+
;指数を10進4～3桁で書く
;<d0.l:指数(整数)
2:	subq.l	#1,d0			;0.1以上1未満を1以上10未満にする
	cmp.l	#1000,d0
	blo	2f
	move.l	#1000,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
;指数を10進3桁で書く
;<d0.l:指数(整数)
2:	moveq.l	#100,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
	moveq.l	#10,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
	add.b	#'0',d0
	move.b	d0,(a0)+
	clr.b	(a0)
	rts

;整数部がある
;<d0.l:整数部の桁数(≦d2)
;<d1.l:末尾の0を除いた桁数(≦d2,小数点を含まない)
4:	sub.l	d0,d1			;小数部の桁数
	ble	3f			;整数部のみ
;途中に小数点が入る(整数部.小数部)
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	move.b	#'.',(-1,a0)
		adda.l	d1,a0		;最後の桁の右側
	clr.b	(a0)
	rts

;整数部のみ
;<d0.l:桁数(≦d2)
3:
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	clr.b	-(a0)
	rts

;先頭に0.00…を追加する(指数は不要)
;    ←──── d1 ────→
;           a0              a6
;           ↓              ↓
;            ←───── d2 ─────→
;０．００００ＸＸＸＸＸＸＸＸ００００００×１０
;    ← d0 →
;<d0.l:0.の右側の0の数
;<d1.l:0.の右側の0でない最後の桁までの桁数
5:	sub.l	d0,d1			;0でない部分の桁数
;    ← d0 →←── d1 ──→
;           a0              a6
;           ↓              ↓
;            ←───── d2 ─────→
;０．００００ＸＸＸＸＸＸＸＸ００００００
;          ０．００００ＸＸＸＸＸＸＸＸ０
	lea.l	(1,a6,d0.l),a0
@@:	move.b	-(a6),(1,a6,d0.l)	;右にずらす
		subq.l	#1,d1
	bne	@b
	lea.l	(1,a6,d0.l),a6
		tst.l	d0
	beq	2f
1:	move.b	#'0',-(a6)
		subq.l	#1,d0
	bne	1b
2:	move.b	#'.',-(a6)
		move.b	#'0',-(a6)
	clr.b	(a0)
	rts

;すべての桁が0だった
;<d1.l:符号(0=正,1=負)
;<a0.l:番兵の次の位置
7:	subq.l	#1,a0			;番兵の位置
		suba.l	d1,a0		;負符号の分戻してバッファの先頭へ
;浮動小数点数が0のとき
9:	move.b	#'0',(a0)+
		clr.b	(a0)
	rts

;----------------------------------------------------------------
;$FE24	__ECVT
;	8バイト浮動小数点数を全体の桁数を指定して文字列に変換します。
;<d0-d1:8バイト浮動小数点数
;<d2.b:全体の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>d0.l:小数点の位置
;>d1.l:符号(0=正,1=負)
;>(a0):変換された文字列
fe_ecvt::
	move.l	d2,-(sp)
	and.l	#$000000FF,d2
	cmp.l	#$7FF00000,d0
	bge	9f
	cmp.l	#$FFF00000,d0
	bhs	9f
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	move.l	a0,-(sp)		;a0を破壊しない
	bsr	ecvt
	movea.l	(sp)+,a0
	exit	d2

9:	bne	1f
	tst.l	d1
	bne	1f
	moveq.l	#0,d1
	tst.l	d0
	bpl	@f
	moveq.l	#1,d1
	subq.l	#1,d2			;純正は桁数が足りないと$00をいれようとする
	bcs	2f
	move.b	#'-',(a0)+
@@:	subq.l	#1,d2
	bcs	2f
	move.b	#'#',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'I',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'N',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'F',(a0)+
	bra	2f

1:	moveq.l	#0,d1
	subq.l	#1,d2
	bcs	2f
	move.b	#'#',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'N',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'A',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'N',(a0)+
2:	clr.b	(a0)
	move.l	#4,d0			;常に4
	exit	d2

;----------------------------------------------------------------
;ecvt
;浮動小数点数を全体の桁数を指定した浮動小数点表現の文字列に変換する
;<d2.l:全体の桁数(負数は不可)
;<a0.l:バッファの先頭
;<fp0:浮動小数点数(#INFや#NANは不可)
;>d0.l:10進指数部(浮動小数点数が0のときは1)
;>d1.l:符号(0=正,1=負)
;>(a0):変換された文字列(符号や小数点は含まない)
;>a0.l:文字列の末尾の0のアドレス
;*d0-d1/a0,?d2/d7/a6/fp0
ecvt:
	bsr	dexp			;d7/a6を破壊する
	ftst.x	fp0
	fbeq	9f			;浮動小数点数が0
;指定された桁数の文字列に変換する
	move.l	a0,-(sp)		;バッファの先頭
		move.l	d2,-(sp)	;桁数
	ble	2f
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'～'9'にする
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
2:
;四捨五入
	fcmp.s	#0f0.5,fp0
	fblt	3f			;次の桁が5未満なので切り捨てる
;繰り上げる
	move.l	(sp),d2			;桁数
	ble	2f
1:	addq.b	#1,-(a0)		;繰り上がり
		cmpi.b	#'9',(a0)
	bls	3f			;上の位に納まったので終わり
		move.b	#'0',(a0)	;上の位も溢れた
	subq.l	#1,d2
	bne	1b
2:
;最上位から繰り上がった
	addq.l	#1,d0			;指数部が1増える
		move.l	(sp),d2		;桁数
	ble	2f
	move.b	#'1',(a0)+		;先頭を1にする
	bra	4f
1:	move.b	#'0',(a0)+		;残りを0にする
4:	subq.l	#1,d2
	bne	1b
2:
;終わり
3:	move.l	(sp)+,d2		;桁数
		movea.l	(sp)+,a0	;バッファの先頭
	adda.l	d2,a0			;末尾の桁の次の位置
	clr.b	(a0)
	rts

;0のとき
9:	tst.l	d2
	ble	2f
1:	move.b	#'0',(a0)+		;d2+1個0を並べる
	subq.l	#1,d2
	bne	1b
2:	moveq.l	#1,d0			;10^1にする
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;浮動小数点数を10進正規化する
;	fp0→(-1)^d1*fp0*10^d0(fp0は0または0.1以上1未満)
;<fp0:浮動小数点数(#INFや#NANは不可)
;>d0.l:10進指数部
;>d1.l:符号(0=正,1=負)
;>fp0:仮数部(0または0.1以上1未満)
;*d0-d1/fp0,?d7/a6
dexp:
	fmove.x	fp0,-(sp)
	moveq.l	#0,d1
		move.w	(sp),d0
	lea.l	(12,sp),sp
	bpl	@f
	fneg.x	fp0,fp0
		moveq.l	#1,d1
	and.w	#$7FFF,d0
@@:
;<d0.w:2進指数部+$3FFF(0～$7FFF)
	tst.w	d0
	beq	dexpZero		;絶対値が0
	sub.w	#$3FFF,d0
	bmi	dexpMinus		;絶対値が1未満
;絶対値が1以上
;<d0.w:2進指数部(0～$4000)
dexpPlus:
;2進指数部にlog10(2)を掛けて10進指数部を求める(大きめに出す)
	mulu.w	#19729,d0		;log10(2)*65536を繰り上げたもの
	clr.w	d0
	swap.w	d0
;<d0.w:10進指数部(0～4932,1だけ大きすぎることがある)
	move.l	d0,d7
;;;	beq	3f
	lea.l	(dexpMinusTable,pc),a6
1:	lsr.w	#1,d7
	bcc	2f
	fmul.x	(a6),fp0
2:	lea.l	(12,a6),a6
	bne	1b
3:
;10で割って0.1以上1未満にする
	fmul.x	dexpMinusTable,fp0	;0.1
	addq.l	#1,d0
;10進指数部が1だけ大きすぎたとき小さくなりすぎている
;誤差の修正
	fcmp.x	dexpMinusTable,fp0	;0.1
	fblt	dexpRight		;小さすぎる
	fcmp.s	#0f1,fp0
	fbge	dexpLeftOne		;大きすぎる
	rts

dexpRight:
	fmul.s	#0f10,fp0
		subq.l	#1,d0
	fcmp.x	dexpMinusTable,fp0	;0.1
	fblt	dexpRight
	rts

dexpLeftOne:
	fmul.x	dexpMinusTable,fp0	;0.1
		addq.l	#1,d0
	rts

;絶対値が0
dexpZero:
	fmove.s	#0f0,fp0		;念のため
	moveq.l	#0,d0
	moveq.l	#0,d1
	rts

;絶対値が1未満
;<d0.w:2進指数部(-$3FFF～-1)
dexpMinus:
	neg.w	d0
;<d0.w:2進指数部の符号を変えたもの(1～$3FFF)
;2進指数部の符号を変えたものにlog10(2)を掛けて10進指数部の符号を変えたものを求める(大きめに出す)
	mulu.w	#19729,d0		;log10(2)*65536を繰り上げたもの
	clr.w	d0
	swap.w	d0
;<d0.w:10進指数部の符号を変えたもの(0～4931,1だけ大きすぎることがある)
	move.l	d0,d7
;;;	beq	3f
	lea.l	(dexpPlusTable,pc),a6
1:	lsr.w	#1,d7
	bcc	2f
	fmul.x	(a6),fp0
2:	lea.l	(12,a6),a6
	bne	1b
3:
;10進指数部が1だけ大きすぎたとき大きくなりすぎている
;指数部の符号を反転する
	neg.l	d0
;誤差の修正
	fcmp.x	dexpMinusTable,fp0	;0.1
	fblt	dexpRightOne		;小さすぎる
	fcmp.s	#0f1,fp0
	fbge	dexpLeft		;大きすぎる
	rts

dexpRightOne:
	fmul.s	#0f10,fp0
		subq.l	#1,d0
	rts

dexpLeft:
	fmul.x	dexpMinusTable,fp0	;0.1
		addq.l	#1,d0
	fcmp.s	#0f1,fp0
	fbge	dexpLeft
	rts

;10^(2^n),n=0～12のテーブル
	.align	4
dexpPlusTable:
;  .irp %e,1,2,4,8,16,32,64,128,256,512,1024,2048,4096
;	.dc.x	0f1E+%e
;  .endm
	.dc.x	!40020000A000000000000000	;10^1
	.dc.x	!40050000C800000000000000	;10^2
	.dc.x	!400C00009C40000000000000	;10^4
	.dc.x	!40190000BEBC200000000000	;10^8
	.dc.x	!403400008E1BC9BF04000000	;10^16
	.dc.x	!406900009DC5ADA82B70B59E	;10^32
	.dc.x	!40D30000C2781F49FFCFA6D5	;10^64
	.dc.x	!41A8000093BA47C980E98CE0	;10^128
	.dc.x	!43510000AA7EEBFB9DF9DE8E	;10^256
	.dc.x	!46A30000E319A0AEA60E91C7	;10^512
	.dc.x	!4D480000C976758681750C17	;10^1024
	.dc.x	!5A9200009E8B3B5DC53D5DE5	;10^2048
	.dc.x	!75250000C46052028A20979B	;10^4096

;10^(-2^n),n=0～12のテーブル
	.align	4
dexpMinusTable:
;  .irp %e,1,2,4,8,16,32,64,128,256,512,1024,2048,4096
;	.dc.x	0f1E-%e
;  .endm
	.dc.x	!3FFB0000CCCCCCCCCCCCCCCD	;10^-1
	.dc.x	!3FF80000A3D70A3D70A3D70A	;10^-2
	.dc.x	!3FF10000D1B71758E219652C	;10^-4
	.dc.x	!3FE40000ABCC77118461CEFD	;10^-8
	.dc.x	!3FC90000E69594BEC44DE15B	;10^-16
	.dc.x	!3F940000CFB11EAD453994BA	;10^-32
	.dc.x	!3F2A0000A87FEA27A539E9A5	;10^-64
	.dc.x	!3E550000DDD0467C64BCE4A0	;10^-128
	.dc.x	!3CAC0000C0314325637A193A	;10^-256
	.dc.x	!395A00009049EE32DB23D21C	;10^-512
	.dc.x	!32B50000A2A682A5DA57C0BE	;10^-1024
	.dc.x	!256B0000CEAE534F34362DE4	;10^-2048
	.dc.x	!0AD80000A6DD04C8D2CE9FDE	;10^-4096

;----------------------------------------------------------------
;10進正規化された浮動小数点数の仮数部を指定された桁数の文字列にする
;	指定された桁数の数字の並びになる(符号や小数点は入らない)
;	指定された桁数の次の桁を四捨五入する
;	四捨五入の結果小数点が1桁ずれたとき、10進指数部を1増やす
;<d0.l:10進指数部
;<d2.l:桁数
;<a0.l:文字列を格納するアドレス
;<fp0:浮動小数点数(0または1以上10未満,#INFや#NANは不可)
;>d0.l:10進指数部
;>(a0):指定された桁数の文字列('0'～'9'の列)
;	小数点の位置は先頭の数字の右側
;	指定された桁数より後の領域は破壊しない
;?d7/fp0-fp1
dstr:
	move.l	a0,-(sp)
		move.l	d2,-(sp)
;指定された桁数の文字列に変換する
1:	fmul.s	#0f10,fp0		;100倍にしてテーブルを引いてもよいが、
	fintrz.x	fp0,fp1		;fmulは十分速いのでこのままにしておく
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'～'9'にする
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
;四捨五入
	fcmp.s	#0f0.5,fp0
	fblt	4f			;次の桁が5未満なので切り捨てる
;繰り上げる
	move.l	(sp),d2			;桁数
2:	addq.b	#1,-(a0)		;繰り上がり
		cmpi.b	#'9',(a0)
	bls	4f			;上の位に納まったので終わり
		move.b	#'0',(a0)	;上の位も溢れた
	subq.l	#1,d2
	bne	2b
;最上位から繰り上がった
	move.b	#'1',(a0)+
		move.l	(sp),d2		;桁数
	subq.l	#1,d2			;桁数-1
3:	move.b	#'0',(a0)+
		subq.l	#1,d2
	bne	3b
	addq.l	#1,d0			;最上位から繰り上がったので指数部が1増える
;終わり
4:	move.l	(sp)+,d2
		movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;$FE25	__FCVT
;	8バイト浮動小数点数を小数点以下の桁数を指定して、文字列に変換します。
;<d0-d1:8バイト浮動小数点数
;<d2.b:小数点以下の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>d0.l:小数点の位置
;>d1.l:符号(0=正,1=負)
;>(a0):変換された文字列
fe_fcvt::
	move.l	d2,-(sp)
	and.l	#$000000FF,d2
	cmp.l	#$7FF00000,d0
	bge	9f
	cmp.l	#$FFF00000,d0
	bhs	9f
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	move.l	a0,-(sp)		;a0を破壊しない
	bsr	fcvt
	movea.l	(sp)+,a0
	exit	d2

9:	bne	1f
	tst.l	d1
	bne	1f
	moveq.l	#0,d1
	tst.l	d0
	bpl	@f
	moveq.l	#1,d1
	move.b	#'-',(a0)+
@@:	move.l	#'#INF',(a0)+		;奇数アドレスの可能性がある
					;純正は桁数が足りないと$00に指数を付けて結局はみ出す
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;奇数アドレスの可能性がある
2:	clr.b	(a0)
	move.l	#4,d0			;常に4
	exit	d2

;----------------------------------------------------------------
;fcvt
;浮動小数点数を小数部の桁数を指定した浮動小数点表現の文字列に変換する
;<d2.l:小数部の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;<fp0:浮動小数点数
;>d0.l:10進指数部
;>d1.l:符号(0=正,1=負)
;>(a0):変換された文字列(符号や小数点は含まない)
;	整数部は何桁でも展開する
;	0ではないが絶対値が小さすぎて指定した範囲内に0しかないときヌル文字列になる
;	0のときは0.xxxx*10^1になる
;>a0.l:文字列の末尾の0のアドレス
;*a0,?d0-d2/d7/fp0
fcvt:
	bsr	dexp			;d7/a6を破壊する
	ftst.x	fp0
	fbeq	fcvtZero
	tst.l	d0
	blt	4f			;指数部が負
;指数部が0以上
	add.l	d0,d2			;全体の桁数
;文字列に変換する
	move.l	a0,-(sp)
		move.l	d2,-(sp)	;全体の桁数
	beq	2f
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'～'9'にする
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
2:
;四捨五入
	fcmp.s	#0f0.5,fp0
	fblt	3f			;次の桁が5未満なので切り捨てる
;繰り上げる
	move.l	(sp),d2			;全体の桁数
	beq	2f
1:	addq.b	#1,-(a0)		;繰り上がり
		cmpi.b	#'9',(a0)
	bls	3f			;上の位に納まったので終わり
		move.b	#'0',(a0)	;上の位も溢れた
	subq.l	#1,d2
	bne	1b
2:
;最上位から繰り上がった
	move.b	#'1',(a0)+		;整数部なので無条件に書く
		move.l	(sp),d2		;全体の桁数(先頭の1を含まない)
	beq	2f
1:	move.b	#'0',(a0)+
		subq.l	#1,d2
	bne	1b
2:	addq.l	#1,d0			;最上位から繰り上がったので整数部が1桁増える
		addq.l	#1,(sp)		;整数部が1桁増えるので全体の桁数も1桁増える
;終わり
3:	move.l	(sp)+,d2		;全体の桁数
		movea.l	(sp)+,a0	;バッファの先頭
	adda.l	d2,a0			;末尾の桁の次の位置
9:	clr.b	(a0)
	rts

;指数部が負
4:	add.l	d0,d2			;残る桁数
;	bmi	9b			;繰り上がっても残らない
					;ここでジャンプしてしまうと繰り上がることによる
					;指数の補正が正しく行われなくなる
;文字列に変換する
	move.l	a0,-(sp)
		move.l	d2,-(sp)	;残る桁数
	ble	2f
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'～'9'にする
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
2:
;四捨五入
	fcmp.s	#0f0.5,fp0
	fblt	3f			;次の桁が5未満なので切り捨てる
;繰り上げる
	move.l	(sp),d2			;残る桁数
	ble	2f
1:	addq.b	#1,-(a0)		;繰り上がり
		cmpi.b	#'9',(a0)
	bls	3f			;上の位に納まったので終わり
		move.b	#'0',(a0)	;上の位も溢れた
	subq.l	#1,d2
	bne	1b
2:
;最上位から繰り上がった
	move.l	(sp),d2			;残る桁数(繰り上げて書いた1を含まない)
	blt	2f
	move.b	#'1',(a0)+
		tst.l	d2
	beq	2f
1:	move.b	#'0',(a0)+
		subq.l	#1,d2
	bne	1b
2:	addq.l	#1,d0			;最上位から繰り上がった
		addq.l	#1,(sp)		;残る桁数が1桁増える
;終わり
3:	move.l	(sp)+,d2		;残る桁数
		movea.l	(sp)+,a0	;小数部の最初の0以外の数字の位置
;	tst.l	d2
	ble	@f
	adda.l	d2,a0			;末尾の桁の次の位置
@@:	clr.b	(a0)
	rts

fcvtZero:
@@:	move.b	#'0',(a0)+		;d2+1個0を並べる
	subq.l	#1,d2
	bcc	@b
	moveq.l	#1,d0			;10^1にする
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;$FE26	__GCVT
;	8バイト浮動小数点数を全体の桁数を指定した浮動小数点表現または指数表現の文字列に
;	変換します。
;<d0-d1:8バイト浮動小数点数
;<d2.b:全体の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
;	負の値の場合は文字列の先頭にマイナス記号('-')が付加されます。
;	d2の桁数で表現できない場合に、指数表現の文字列に変換します。
fe_gcvt::
	move.l	d2,-(sp)
	and.l	#$000000FF,d2
	cmp.l	#$7FF00000,d0
	bge	9f
	cmp.l	#$FFF00000,d0
	bhs	9f
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	bsr	gcvt
	exit	d2

9:	bne	1f
	tst.l	d1
	bne	1f
	moveq.l	#0,d1
	tst.l	d0
	bpl	@f
	moveq.l	#1,d1
	move.b	#'-',(a0)+
@@:	move.l	#'#INF',(a0)+		;奇数アドレスの可能性がある
					;純正は桁数が足りないと$00に指数を付けて結局はみ出す
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;奇数アドレスの可能性がある
2:	clr.b	(a0)
	move.l	#4,d0			;常に4
	exit	d2

;----------------------------------------------------------------
;gcvt
;浮動小数点数を全体の桁数を指定した浮動小数点表現または指数表現の文字列に変換する
;<d2.l:全体の桁数(負数は不可,符号や小数点は含まない,ただし0.0xxxとなるときは0.を含む)
;<a0.l:バッファの先頭
;<fp0:浮動小数点数(#INFや#NANは不可)
;>(a0):変換された文字列
;>a0.l:文字列の末尾の0のアドレス
;	負の値の場合は文字列の先頭にマイナス記号('-')が付加される
;	d2の桁数で表現できない場合は指数表現の文字列に変換する
;*a0,?d0-d2/d7/a6/fp0
gcvt:
	ftst.x	fp0
	fbeq	9f			;浮動小数点数が0
	fbgt	@f
	move.b	#'-',(a0)+
@@:	clr.b	(a0)+			;バッファの先頭または'-'の直後は0(番兵)
	bsr	ecvt			;d0-d2/d7/a6を破壊する,a0は末尾の0の位置
	movea.l	a0,a6			;最後の桁の次の位置
		suba.l	d2,a0
@@:	cmp.b	#'0',-(a6)		;0のときは番兵で止まる
	beq	@b
;<a6.l:'0'でない最後の桁の位置または番兵の位置
	cmpa.l	a0,a6
	blo	7f			;0だった(符号が必要なのでd1を壊す前に飛ぶこと)
	addq.l	#1,a6
;<a6.l:'0'でない最後の桁の次の位置
	move.l	a6,d1			;0でない最後の桁の次の位置
		sub.l	a0,d1		;下位の0を除いた桁数
;     ←── d1 ──→
;    a0              a6
;    ↓              ↓
;     ←───── d2 ─────→      d0
; －□ＸＸＸＸＸＸＸＸ００００００×１０
;    ↑
;－←・→＋
;    d0
	cmp.l	d2,d0
	bgt	1f			;指数が大きすぎる(指数形式)
	tst.l	d0
	bgt	4f			;途中に小数点が入る(整数部.小数部)
;指数部が0以下(指数表現でなければ0.に続く)
	beq	@f
	subq.l	#2,d2
@@:	neg.l	d0			;0.の右側の0の数
		add.l	d0,d1		;0.の右側の桁数
;d0=0のとき
;    ←── d1 ──→
;   a0              a6
;   ↓              ↓
;    ←───── d2 ─────→
;０．ＸＸＸＸＸＸＸＸ００００００
;  →←
;   d0
;d0>0のとき
;    ←─── d1 ───→
;       a0              a6
;       ↓              ↓     2
;    ←──── d2 ────→←→
;０．００ＸＸＸＸＸＸＸＸ００００００
;  → d0 ←
	cmp.l	d2,d1
	ble	5f			;先頭に0.00…を追加する(指数は不要)
;指数が小さすぎる(指数形式)
;<d1.l:有効な桁数
	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	sub.l	d0,d1			;0でない部分の桁数
		adda.l	d1,a0		;最後の桁の右側
	move.b	#'E',(a0)+
		move.b	#'-',(a0)+
	bra	2f

;指数が大きすぎる(指数形式)
;<d1.l:有効な桁数
1:	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	adda.l	d1,a0			;最後の桁の右側
		move.b	#'E',(a0)+
	move.b	#'+',(a0)+
;指数を10進4～3桁で書く
;<d0.l:指数(整数)
2:	subq.l	#1,d0			;0.1以上1未満を1以上10未満にする
		cmp.l	#1000,d0
	blo	2f
	move.l	#1000,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
;指数を10進3桁で書く
;<d0.l:指数(整数)
2:	moveq.l	#100,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
	moveq.l	#10,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
	add.b	#'0',d0
		move.b	d0,(a0)+
	clr.b	(a0)
	rts

;整数部がある
;<d0.l:整数部の桁数(≦d2)
;<d1.l:末尾の0を除いた桁数(≦d2,小数点を含まない)
4:	sub.l	d0,d1			;小数部の桁数
	ble	3f			;整数部のみ
;途中に小数点が入る(整数部.小数部)
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	move.b	#'.',(-1,a0)
		adda.l	d1,a0		;最後の桁の右側
	clr.b	(a0)
	rts

;整数部のみ
;<d0.l:桁数(≦d2)
3:	cmp.l	d2,d0
	beq	3f			;小数点は入り切らない
;整数部のみだが小数点を付ける
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	move.b	#'.',(-1,a0)
		clr.b	(a0)
	rts

;整数部のみで小数点は入り切らない
3:
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	clr.b	-(a0)
	rts

;先頭に0.00…を追加する(指数は不要)
;    ←──── d1 ────→
;           a0              a6
;           ↓              ↓
;            ←───── d2 ─────→
;０．００００ＸＸＸＸＸＸＸＸ００００００×１０
;    ← d0 →
;<d0.l:0.の右側の0の数
;<d1.l:0.の右側の0でない最後の桁までの桁数
5:	sub.l	d0,d1			;0でない部分の桁数
;    ← d0 →←── d1 ──→
;           a0              a6
;           ↓              ↓
;            ←───── d2 ─────→
;０．００００ＸＸＸＸＸＸＸＸ００００００
;          ０．００００ＸＸＸＸＸＸＸＸ０
	lea.l	(1,a6,d0.l),a0
@@:	move.b	-(a6),(1,a6,d0.l)	;右にずらす
		subq.l	#1,d1
	bne	@b
	lea.l	(1,a6,d0.l),a6
		tst.l	d0
	beq	2f
1:	move.b	#'0',-(a6)
		subq.l	#1,d0
	bne	1b
2:	move.b	#'.',-(a6)
		move.b	#'0',-(a6)
	clr.b	(a0)
	rts

;すべての桁が0だった
;<d1.l:符号(0=正,1=負)
;<a0.l:番兵の次の位置
7:	subq.l	#1,a0			;番兵の位置
		suba.l	d1,a0		;負符号の分戻してバッファの先頭へ
;浮動小数点数が0のとき
9:	move.b	#'0',(a0)+
		subq.l	#1,d2
	ble	@f
	move.b	#'.',(a0)+
@@:	clr.b	(a0)
	rts

;----------------------------------------------------------------
;$FE28	__DTST
;	8バイト浮動小数点数と0の比較をします。
;<d0-d1:8バイト浮動小数点数
;>z-flag:eq=0
;>n-flag:mi=負
fe_dtst::
	move.l	d0,d7
	or.w	d1,d7
	swap.w	d1
	or.w	d1,d7
	swap.w	d1
	tst.l	d7
	exit	ccr

;----------------------------------------------------------------
;$FE29	__DCMP
;	8バイト浮動小数点数どうしの比較をします。
;<d0-d1:被比較数
;<d2-d3:比較数
;	被比較数から比較数を減算した結果にしたがってセットされます。
;>n-flag:mi=負
;>z-flag:eq=0
;>c-flag:cs=ボローが発生した
;	被比較数が比較数より大きいとき	cc,ne,pl
;	被比較数が比較数と等しいとき	cc,eq,pl
;	被比較数が比較数より小さいとき	cs,ne,mi
fe_dcmp::
	tst.l	d0
	bmi	1f
	tst.l	d2
	bmi	2f
	cmp.l	d2,d0
	bne	@f
	cmp.l	d3,d1
@@:	exit	ccr

1:	tst.l	d2
	bpl	3f
	cmp.l	d0,d2
	bne	@f
	cmp.l	d1,d3
@@:	exit	ccr

2:	exit	_

3:	exit	C,N

;----------------------------------------------------------------
;$FE2A	__DNEG
;	8バイト浮動小数点数の符号を反転します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_dneg::
	tst.l	d0
	beq	@f
	bchg.l	#31,d0
@@:	exit

;----------------------------------------------------------------
;$FE2B	__DADD
;	8バイト浮動小数点数どうしの加算をします。
;<d0-d1:被加算数
;<d2-d3:加算数
;>d0-d1:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_dadd::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fadd.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	d0,d1

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7,d0,d1

;----------------------------------------------------------------
;$FE2C	__DSUB
;	8バイト浮動小数点数どうしの減算をします。
;<d0-d1:被減算数
;<d2-d3:減算数
;>d0-d1:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_dsub::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fsub.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	d0,d1

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7,d0,d1

;----------------------------------------------------------------
;$FE2D	__DMUL
;	8バイト浮動小数点数どうしの乗算をします。
;<d0-d1:被乗数
;<d2-d3:乗数
;>d0-d1:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_dmul::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fmul.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	d0,d1

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7,d0,d1

;----------------------------------------------------------------
;$FE2E	__DDIV
;	8バイト浮動小数点数どうしの除算をします。
;<d0-d1:被除数
;<d2-d3:除数
;>d0-d1:演算結果
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=オーバーフロー,(cs,ne)vc=アンダーフロー
fe_ddiv::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fdiv.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit	d0,d1

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7,d0,d1

;----------------------------------------------------------------
;$FE2F	__DMOD
;	8バイト浮動小数点数どうしの剰余を求めます。
;<d0-d1:被除数
;<d2-d3:除数
;>d0-d1:演算結果
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=有効数字の範囲外,(cs,ne)vc=アンダーフロー
fe_dmod::
	move.l	d2,d7
	add.l	d7,d7
	or.l	d3,d7
	beq	1f
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fmod.d	(sp)+,fp0		;エミュレーション
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit	_,d0,d1

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7,d0,d1

1:	move.l	#$7FFFFFFF,d0
	moveq.l	#$FFFFFFFF,d1
	exit	C,Z

;----------------------------------------------------------------
;$FE30	__DABS
;	8バイト浮動小数点数の絶対値を求めます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_dabs::
	bclr.l	#31,d0
	exit

;----------------------------------------------------------------
;$FE31	__DCEIL
;	8バイト浮動小数点数と等しいか、それ以上の最小の整数を返します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_dceil::
	fmove.l	fpcr,d7
	fmove.l	#FPRM_RP,fpcr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fint.d	(sp)+,fp0
	fmove.d	fp0,-(sp)
	fmove.l	d7,fpcr
	exit	d0,d1

;----------------------------------------------------------------
;$FE32	__DFIX
;	8バイト浮動小数点数の整数部を求めます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_dfix::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fintrz.d	(sp)+,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE33	__DFLOOR
;	8バイト浮動小数点数と等しいかまたはそれより小さい最大の整数を返します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_dfloor::
	fmove.l	fpcr,d7
	fmove.l	#FPRM_RM,fpcr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fint.d	(sp)+,fp0
	fmove.d	fp0,-(sp)
	fmove.l	d7,fpcr
	exit	d0,d1

;----------------------------------------------------------------
;$FE34	__DFRAC
;	8バイト浮動小数点数の小数部を求めます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;	整数部分を0にする(intrzを引く)
fe_dfrac::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fintrz.x	fp0,fp1
	fsub.x	fp1,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE35	__DSGN
;	8バイト浮動小数点数が正か負か0かを調べます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:結果(8バイト浮動小数点数)
;	正なら+1、負なら-1、0なら0を返します。
fe_dsgn::
	add.l	d0,d0
	beq	2f
1:	move.l	#$3FF00000<<1,d0
	roxr.l	#1,d0
	moveq.l	#0,d1
	exit

2:	tst.l	d1
	bne	1b
	moveq.l	#0,d0
		moveq.l	#0,d1
	exit

;----------------------------------------------------------------
;$FE36	__SIN
;	角度(ラジアン単位)を与えて正弦(sin)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;	|X|<=π/4としてから
;	{(-1)^(n-1)/(2n-1)!}X^(2n-1)が0になるまで加える
fe_sin::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	sin
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE37	__COS
;	角度(ラジアン単位)を与えて余弦(cos)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;	|X|<=π/4としてから
;	{(-1)^n/(2n)!}X^2nが0になるまで加える
fe_cos::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	cos
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE38	__TAN
;	角度(ラジアン単位)を与えて正接(tan)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(引数が((2n+1)/2)π(n:整数))
;	sin/cos
fe_tan::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	tan
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE39	__ATAN
;	逆正接(atan)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果(ラジアン単位)
;	X>1のときπ/2-atan(1/X)
;	X>1/2のときatan(X)=atan(1/2)+atan(2X-1/(X+2))
;	X>1/4のときatan(X)=atan(1/4)+atan(4X-1/(X+4))
;	X>1/8のときatan(X)=atan(1/4)-atan(1-4X/(X+4))
;	X=1のときπ/4
;	{(-1)^n}X^(2n+1)/(2n+1)が0になるまで加える
fe_atan::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	atan
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE3A	__LOG
;	自然対数(log)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(引数が0または負)
;>z-flag:(cs)eq=引数が0(log 0)
fe_log::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	logn
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE3B	__EXP
;	指数関数(e^x)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフロー)
;	0<=X<logn(2)のときX^n/n!が0になるまで加える
;	X>=logn(2)のときX=n*logn(2)±Y(nは整数,0<Y<log(2)/2)でexp(Y)を求めnビットずらす
fe_exp::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	etox
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE3C	__SQR
;	平方根を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(引数が負)
fe_sqr::
	tst.l	d0
	bmi	9f
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fsqrt.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	d0,d1

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7,d0,d1

9:	exit	C

;----------------------------------------------------------------
;$FE3D	__PI
;	円周率を8バイト浮動小数点数の範囲内で返します。
;>d0-d1:演算結果
fe_pi::
	move.l	#$400921FB,d0
		move.l	#$54442D18,d1
	exit

;----------------------------------------------------------------
;$FE3E	__NPI
;	円周率と8バイト浮動小数点数の積(xπ)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフロー)
fe_npi::
	fmove.l	#$00000000,fpsr
	fmove.x	pi(pc),fp0		;π
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmul.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.d	fp0,-(sp)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	d0,d1

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7,d0,d1

;----------------------------------------------------------------
;$FE3F	__POWER
;	べき乗(X^y)を計算します。
;<d0-d1:被べき乗数
;<d2-d3:指数
;>d0-d1:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_power::
	bsr	power
	exit	ccr

power:
	movem.l	d0-d1,-(sp)
	fmove.l	#$00000000,fpsr
	flogn.d	(sp),fp0		;エミュレーション
					;fp0=ln(x)
	add.l	d0,d0
	cmpi.l	#$FFFFFFFE,d0
	beq	power_nan_y
	move.l	d2,d0
	add.l	d0,d0
	beq	power_x_0
	cmpi.l	#$FFE00000,d0
	bcc	power_x_infnan
	move.l	(sp),d0
	add.l	d0,d0
	beq	power_0_y
	bcs	power_minusnum_y
	movem.l	d2-d3,(sp)
	fmul.d	(sp),fp0		;fp0=ln(x)*y
	fetox.x	fp0			;エミュレーション
					;fp0=e^(ln(x)*y)=(e^ln(x))^y=x^y
	fmove.d	fp0,(sp)		;x^y
	fmove.l	fpsr,d0
	and.w	#FPAE_IOP|FPAE_OVFL|FPAE_DZ,d0
	beq	~0023FA
	add.b	d0,d0
	add.b	d0,d0
	bcc	~0023F6
	addq.b	#1,d0
~0023F6:
	add.b	d0,d0
	addq.b	#1,d0
~0023FA:
	move.w	d0,ccr
	movem.l	(sp)+,d0-d1
	rts

power_nan_y:
~002402:
	move.l	(sp),d0
	addq.l	#8,sp
	move.w	#$0000,ccr
	rts

power_x_infnan:
~00240C:
	beq	power_x_inf
	move.l	d2,d0
	move.l	d3,d1
	addq.l	#8,sp
	move.w	#$0000,ccr
	rts

power_x_inf:
~00241A:
	move.l	(sp),d0
	add.l	d0,d0
	beq	power_0_inf
	cmp.l	#$FFE00000,d0
	beq	power_inf_inf
	tst.l	d2
	bmi	power_x_minusinf
power_x_plusinf:
~00242E:
	move.l	(sp),d0
	and.l	#$80000000,d0
	or.l	#$7FF00000,d0
	moveq.l	#$00,d1
	addq.l	#8,sp
	move.w	#$0000,ccr
	rts

power_inf_inf:
~002446:
	tst.l	d2
	bpl	power_x_plusinf
	move.l	(sp),d0
	or.l	#$7FFFFFFF,d0
	moveq.l	#$FF,d1
	addq.l	#8,d0
	move.w	#$0000,ccr
	rts

power_x_0:
~00245C:
	move.l	#$3FF00000,d0
	moveq.l	#$00,d1
	addq.l	#8,sp
	move.w	#$0000,ccr
	rts

power_x_minusinf:
~00246C:
	tst.l	d0
	bmi	power_0_inf
power_0_y:
~002472:
	moveq.l	#$00,d0
	moveq.l	#$00,d1
	addq.l	#8,sp
	move.w	#$0000,ccr
	rts

power_minusnum_y:
~00247E:
	move.l	d2,d0
	move.l	d3,d1
;	bsr	fe_dfrac		;d0-d1=frac(y)
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fintrz.x	fp0,fp1
	fsub.x	fp1,fp0
	fmove.d	fp0,-(sp)
	movem.l	(sp)+,d0-d1
;
	add.l	d0,d0
	or.l	d0,d1
	bne	power_minusnum_notint
	fmove.l	#$00000000,fpsr
	fmove.d	(sp),fp1		;fp1=x
	movem.l	d2-d3,(sp)
	fmove.d	(sp),fp0		;fp0=y
	fmove.l	fp0,d0			;d0=int(y)
	tst.l	d0
	beq	power_x_0
	bpl	~0024B8			;y>0
					;y<0
	fmove.x	one(pc),fp0		;fp0=1
	fdiv.x	fp1,fp0			;fp0=1/x
	fmove.x	fp0,fp1			;fp1=1/x
	neg.l	d0			;x^(-y)=(1/x)^y
~0024B8:
	fmove.x	one(pc),fp0		;fp0=1
~0024BC:
	lsr.l	#1,d0
	bcc	~0024C8
	fmul.x	fp1,fp0
	tst.l	d0			;←いらないと思う
	beq	~0024CE
~0024C8:
	fmul.x	fp1,fp1
	bra	~0024BC

~0024CE:
	fmove.d	fp0,(sp)
	fmove.l	fpsr,d0
	and.w	#FPAE_IOP|FPAE_OVFL|FPAE_UNFL|FPAE_DZ,d0
	beq	~0024EC
	add.b	d0,d0
	add.b	d0,d0
	bcc	~0024E4
	addq.b	#1,d0
~0024E4:
	add.b	d0,d0
	bpl	~0024EA
	addq.b	#4,d0
~0024EA:
	addq.b	#1,d0
~0024EC:
	move.w	d0,ccr
	movem.l	(sp)+,d0-d1
	rts

power_0_inf:
power_minusnum_notint:
~0024F4:
	move.l	#$7FFFFFFF,d0
	moveq.l	#$FF,d1
	addq.l	#8,sp
	move.w	#SRU_C,ccr
	rts

;----------------------------------------------------------------
;$FE40	__RND
;	8バイト浮動小数点数の乱数を返します。
;>d0-d1:8バイト浮動小数点数の乱数(0以上1未満)
fe_rnd::
	bsr	rnd
	exit

rnd::
	bsr	rnd_long
	move.l	d0,d1
	bsr	rnd_long
	andi.l	#$001FFFFF,d0
	move.w	#$1FF0,d7
	bra	2f

1:	add.l	d1,d1
	addx.l	d0,d0
	subq.w	#8,d7
2:	bclr.l	#20,d0
	beq	1b
	add.w	d7,d7
	swap.w	d0
	or.w	d7,d0
	swap.w	d0
	rts

1:	moveq.l	#111,d0
	bsr	randomize
rnd_long::
	move.w	(rnd_count,pc),d0
	bmi	1b
	cmp.w	#54,d0
	bne	2f
	bsr	rnd_shuffle
	moveq.l	#-1,d0
2:	addq.w	#1,d0
	move.w	d0,rnd_count
	move.l	(rnd_table,pc,d0.w*4),d0
	rts

;----------------------------------------------------------------
;$FE41	__SINH
;	双曲正弦(sinh)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
;	{exp(X)-1/exp(X)}/2
fe_sinh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	sinh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE42	__COSH
;	双曲余弦(cosh)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
;	{exp(X)+1/exp(X)}/2
fe_cosh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	cosh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE43	__TANH
;	双曲正接(tanh)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
;	-EXP(-X)/(EXP(X)+EXP(-X))*2+1
fe_tanh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	tanh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE44	__ATANH
;	逆双曲正接(atanh)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(引数が-1以下または+1以上)
;	LOG((1+X)/(1-X))/2
fe_atanh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	atanh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE45	__ASIN
;	逆正弦(asin)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(引数が-1以上+1以下の範囲に含まれていない)
;	ATAN(X/SQRT(1-X*X))
fe_asin::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	asin
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE46	__ACOS
;	逆余弦(acos)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(引数が-1以上+1以下の範囲に含まれていない)
;	ATAN(X/SQRT(1-X*X))+π/2
fe_acos::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	acos
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE47	__LOG10
;	常用対数(log10 X)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
;	logn(X)/logn(10)
fe_log10::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	log10
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE48	__LOG2
;	ビット対数(log2)を計算します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
;	logn(X)/logn(2)
fe_log2::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fpsp	log2
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE49	__DFREXP
;	8バイト浮動小数点数の仮数部と指数部を分けます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:仮数部を示す8バイト浮動小数点数
;>d2.l:指数部を示す符号つき整数
;	返り値のd0-d1の形式は引数の指数部を1に、仮数部をそのままにして返します。
fe_dfrexp::
	move.l	d0,d2
	lsl.l	#1,d2			;符号を無視
	or.l	d1,d2
	beq	1f			;0
	swap.w	d0
	move.w	d0,d2			;seeeeeeeeeeemmmm
	lsl.w	#1,d2			;eeeeeeeeeeemmmm0
	lsr.w	#5,d2			;00000eeeeeeeeeee
	sub.w	#$03FF,d2
	ext.l	d2			;指数部(符号つき)
	and.w	#$800F,d0		;指数部を1にする
	or.w	#$3FF0,d0		;
	swap.w	d0
	exit

1:	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	exit

;----------------------------------------------------------------
;$FE4A	__DLDEXP
;	指数部と仮数部を結合して8バイト浮動小数点数を返します。
;<d0-d1:仮数部データ(8バイト浮動小数点数)
;<d2.l:指数部データ(4バイト符号つき整数)
;>d0-d1:合成された8バイト浮動小数点数
;>c-flag:cs=エラー
;	引数のd0-d1の指数部にd2の値+$3FFを加算します。
fe_dldexp::
	move.l	d0,d7			;0のときは指数部を変更しない
	lsl.l	#1,d7
	or.l	d1,d7
	beq	1f			;0のとき
	swap.w	d0
	move.w	d0,d7			;seeeeeeeeeeemmmm
	lsl.w	#1,d7			;eeeeeeeeeeemmmm0
	lsr.w	#5,d7			;00000eeeeeeeeeee
	ext.l	d7
	add.l	d2,d7			;指数部を加算
	beq	2f
	cmp.l	#$000007FF,d7
	bcc	2f
	lsl.w	#4,d7			;指数部を合成
	and.w	#$800F,d0
	or.w	d7,d0
	swap.w	d0
	exit	_

1:	moveq.l	#0,d0			;0のとき
					;d1.lは既に0
	exit	_

2:	swap.w	d0			;d0-d1を元に戻す
	exit	C

;----------------------------------------------------------------
;$FE4B	__DADDONE
;	8バイト浮動小数点数に1を加えます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_daddone::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fadd.s	#0f1,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE4C	__DSUBONE
;	8バイト浮動小数点数から1を引きます。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
fe_dsubone::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fsub.s	#0f1,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE4D	__DDIVTWO
;	8バイト浮動小数点数を2で割ります。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:演算結果
;>c-flag:cs=エラー(アンダーフロー)
fe_ddivtwo::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fdiv.s	#0f2,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE4E	__DIEECNV
;	8バイト浮動小数点数をIEEEフォーマットに変換します。
;<d0-d1:8バイト浮動小数点数
;>d0-d1:IEEEフォーマット8バイト浮動小数点数
;	FLOAT2.X、FLOAT3.Xでは変換しません。
fe_dieecnv::
	exit

;----------------------------------------------------------------
;$FE4F	__IEEDCNV
;	IEEEフォーマットを8バイト浮動小数点数に変換します。
;<d0-d1:IEEEフォーマット8バイト浮動小数点数
;>d0-d1:8バイト浮動小数点数
;	FLOAT2.X、FLOAT3.Xでは変換しません。
fe_ieedcnv::
	exit

;----------------------------------------------------------------
;$FE50	__FVAL
;	文字列を4バイト浮動小数点数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト浮動小数点数
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
;	文字列が10進数以外の場合、その先頭には、2進数では'&B'、8進数では'&O'、
;	16進数では'&H'が必要です。
;	10進数の場合、返り値として次のものが追加されます。
;		d2.w	整数フラグ
;		d3.l	整数値
;	文字列が整数(小数部及び指数部がない)で、かつ4バイト符号つき整数で表現可能な場合、
;	整数フラグは$FFFFで、整数値にその値がはいります。
;	それ以外の場合は整数フラグは0となります。
fe_fval::
1:	move.b	(a0)+,d0
	cmp.b	#' ',d0
	beq	1b
	cmp.b	#9,d0
	beq	1b
	cmp.b	#'&',d0
	beq	2f
	subq.w	#1,a0
	bsr	stod
	exit	D7

2:	moveq.l	#0,d2			;整数フラグ
	moveq.l	#0,d3
	move.b	(a0)+,d0
	cmp.b	#'H',d0
	beq	3f
	cmp.b	#'B',d0
	beq	4f
	cmp.b	#'O',d0
	beq	5f
	subq.w	#1,a0			;純正品は戻していない
	exit	C,N

3:	bsr	stoh
	bne	6f
	bra	fe_ltof

4:	bsr	stob
	bne	6f
	bra	fe_ltof

5:	bsr	stoo
	bne	6f
	bra	fe_ltof

6:	exit	D7

;----------------------------------------------------------------
;$FE51	__FUSING
;	4バイト浮動小数点数を文字列に変換します。
;<d0.l:4バイト浮動小数点数
;<d2.l:整数部分の桁数
;<d3.l:小数部分の桁数
;<d4.l:アトリビュート
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
;	アトリビュートはビット0～6をセットすることにより以下のような数値表現ができます。
;	ビット0:左側を'*'でパッティングします。
;	ビット1:'\'を先頭に付加します。
;	ビット2:整数部分を3桁ごとに','で区切ります。
;	ビット3:指数形式で表現します。
;	ビット4:正数の場合'+'を先頭に付加します。
;	ビット5:正数の場合'+'を、負数の場合'-'を最後尾に付加します。
;	ビット6:正数の場合' 'を、負数の場合'-'を最後尾に付加します。
fe_fusing::
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.s	(sp)+,fp0
	bsr	using
	exit	d1

;----------------------------------------------------------------
;$FE52	__STOF
;	文字列を4バイト浮動小数点数に変換します。
;<a0.l:文字列を指すポインタ
;>d0.l:変換された4バイト浮動小数点数
;>d2.w:整数フラグ
;>d3.l:整数値
;>c-flag:cs=エラー
;>n-flag:(cs)mi=数値の記述法がおかしい
;>v-flag:(cs)vs=オーバーフロー
;	文字列が整数(小数部及び指数部がない)で、かつ4バイト符号つき整数で表現可能な場合、
;	整数フラグは$FFFFで、整数値にその値がはいります。
;	それ以外の場合は整数フラグは0となります。
fe_stof::
	move.l	d1,-(sp)
	bsr	stod
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fmove.l	#$00000000,fpsr
	fmove.s	fp0,d0
	fmove.l	fpsr,d1
	and.b	#i|v|u|0|0|0|0|0,d1	;ivu00000
	beq	@f
	add.b	d1,d1			;vu000000
	rol.b	#2,d1			;000000vu
	or.b	#0|0|0|0|C,d1		;000000vc
	or.b	d1,d7
@@:	exit	D7,d1

;----------------------------------------------------------------
;$FE53	__FTOS
;	4バイト浮動小数点数を文字列に変換します。
;<d0.l:4バイト浮動小数点数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;<(a0):変換された文字列
fe_ftos::
	move.l	d2,-(sp)
	move.l	d1,-(sp)
	cmp.l	#$7F800000,d0
	bge	1f
	cmp.l	#$FF800000,d0
	bhs	1f
	move.l	d0,-(sp)
	fmove.s	(sp)+,fp0
	bsr	dtos
	exit	d1,d2

1:	bne	2f
	tst.l	d1
	bne	2f
	tst.l	d0
	bpl	@f
	move.b	#'-',(a0)+
@@:	move.l	#'#INF',(a0)+
	bra	3f

2:	move.l	#'#NAN',(a0)+
3:	clr.b	(a0)
	exit	d1,d2

;----------------------------------------------------------------
;$FE54	__FECVT
;	4バイト浮動小数点数を全体の桁数を指定して文字列に変換します。
;<d0.l:4バイト浮動小数点数
;<d2.b:全体の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>d0.l:小数点の位置
;>d1.l:符号(0=正,1=負)
;>(a0):変換された文字列
fe_fecvt::
	move.l	d2,-(sp)
	move.l	d1,-(sp)
	and.l	#$000000FF,d2
	cmp.l	#$7F800000,d0
	bge	9f
	cmp.l	#$FF800000,d0
	bhs	9f
	move.l	d0,-(sp)
	fmove.s	(sp)+,fp0
	move.l	a0,-(sp)		;a0を破壊しない
	bsr	ecvt
	movea.l	(sp)+,a0
	exit	d1,d2

9:	bne	1f
	tst.l	d1
	bne	1f
	moveq.l	#0,d1
	tst.l	d0
	bpl	@f
	moveq.l	#1,d1
	subq.l	#1,d2			;純正は桁数が足りないと$00をいれようとする
	bcs	2f
	move.b	#'-',(a0)+
@@:	subq.l	#1,d2
	bcs	2f
	move.b	#'#',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'I',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'N',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'F',(a0)+
	bra	2f

1:	moveq.l	#0,d1
	subq.l	#1,d2
	bcs	2f
	move.b	#'#',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'N',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'A',(a0)+
	subq.l	#1,d2
	bcs	2f
	move.b	#'N',(a0)+
2:	clr.b	(a0)
	move.l	#4,d0			;常に4
	exit	d1,d2

;----------------------------------------------------------------
;$FE55	__FFCVT
;	4バイト浮動小数点数を小数点以下の桁数を指定して、文字列に変換します。
;<d0.l:4バイト浮動小数点数
;<d2.b:小数点以下の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>d0.l:小数点の位置
;>d1.l:符号(0=正,1=負)
;>(a0):変換された文字列
fe_ffcvt::
	move.l	d2,-(sp)
	move.l	d1,-(sp)
	and.l	#$000000FF,d2
	cmp.l	#$7F800000,d0
	bge	9f
	cmp.l	#$FF800000,d0
	bhs	9f
	move.l	d0,-(sp)
	fmove.s	(sp)+,fp0
	move.l	a0,-(sp)		;a0を破壊しない
	bsr	fcvt
	movea.l	(sp)+,a0
	exit	d1,d2

9:	bne	1f
	tst.l	d1
	bne	1f
	moveq.l	#0,d1
	tst.l	d0
	bpl	@f
	moveq.l	#1,d1
	move.b	#'-',(a0)+
@@:	move.l	#'#INF',(a0)+		;奇数アドレスの可能性がある
					;純正は桁数が足りないと$00に指数を付けて結局はみ出す
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;奇数アドレスの可能性がある
2:	clr.b	(a0)
	move.l	#4,d0			;常に4
	exit	d1,d2

;----------------------------------------------------------------
;$FE56	__FGCVT
;	4バイト浮動小数点数を全体の桁数を指定した浮動小数点表現または指数表現の文字列に
;	変換します。
;<d0.l:4バイト浮動小数点数
;<d2.b:全体の桁数
;<a0.l:変換された文字列の格納用バッファを指すポインタ
;>(a0):変換された文字列
;	負の値の場合は文字列の先頭にマイナス記号('-')が付加されます。
;	d2の桁数で表現できない場合に、指数表現の文字列に変換します。
fe_fgcvt::
	move.l	d2,-(sp)
	move.l	d1,-(sp)
	and.l	#$000000FF,d2
	cmp.l	#$7F800000,d0
	bge	9f
	cmp.l	#$FF800000,d0
	bhs	9f
	move.l	d0,-(sp)
	fmove.s	(sp)+,fp0
	bsr	gcvt
	exit	d1,d2

9:	bne	1f
	tst.l	d1
	bne	1f
	moveq.l	#0,d1
	tst.l	d0
	bpl	@f
	moveq.l	#1,d1
	move.b	#'-',(a0)+
@@:	move.l	#'#INF',(a0)+		;奇数アドレスの可能性がある
					;純正は桁数が足りないと$00に指数を付けて結局はみ出す
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;奇数アドレスの可能性がある
2:	clr.b	(a0)
	move.l	#4,d0			;常に4
	exit	d1,d2

;----------------------------------------------------------------
;$FE58	__FTST
;	4バイト浮動小数点数と0の比較をします。
;<d0.l:4バイト浮動小数点数
;>z-flag:eq=0
;>n-flag:mi=負
fe_ftst::
	cmp.l	#$80000000,d0
	beq	@f
	tst.l	d0
@@:	exit	ccr

;----------------------------------------------------------------
;$FE59	__FCMP
;	4バイト浮動小数点数どうしの比較をします。
;<d0.l:被比較数
;<d1.l:比較数
;	被比較数から比較数を減算した結果にしたがってセットされます。
;>n-flag:mi=負
;>z-flag:eq=0
;>c-flag:cs=ボローが発生した
;	被比較数が比較数より大きいとき	cc,ne,pl
;	被比較数が比較数と等しいとき	cc,eq,pl
;	被比較数が比較数より小さいとき	cs,ne,mi
fe_fcmp::
	tst.l	d0
	bmi	1f
	tst.l	d1
	bmi	2f
	cmp.l	d1,d0
	exit	ccr

1:	tst.l	d1
	bpl	3f
	cmp.l	d0,d1
	exit	ccr

2:	exit	_

3:	exit	C,N

;----------------------------------------------------------------
;$FE5A	__FNEG
;	4バイト浮動小数点数の符号を反転します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_fneg::
	tst.l	d0
	beq	@f
	bchg.l	#31,d0
@@:	exit

;----------------------------------------------------------------
;$FE5B	__FADD
;	4バイト浮動小数点数どうしの加算をします。
;<d0.l:被加算数
;<d1.l:加算数
;>d0.l:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_fadd::
	fmove.l	#$00000000,fpsr
	fmove.s	d0,fp0
	fadd.s	d1,fp0
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	_

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE5C	__FSUB
;	4バイト浮動小数点数どうしの減算をします。
;<d0.l:被減算数
;<d1.l:減算数
;>d0.l:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_fsub::
	fmove.l	#$00000000,fpsr
	fmove.s	d0,fp0
	fsub.s	d1,fp0
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	_

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE5D	__FMUL
;	4バイト浮動小数点数どうしの乗算をします。
;<d0.l:被乗数
;<d1.l:乗数
;>d0.l:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_fmul::
	fmove.l	#$00000000,fpsr
	fmove.s	d0,fp0
	fsglmul.s	d1,fp0
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	_

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE5E	__FDIV
;	4バイト浮動小数点数どうしの除算をします。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=オーバーフロー,(cs,ne)vc=アンダーフロー
fe_fdiv::
	fmove.l	#$00000000,fpsr
	fmove.s	d0,fp0
	fsgldiv.s	d1,fp0
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit	_

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7

;----------------------------------------------------------------
;$FE5F	__FMOD
;	4バイト浮動小数点数どうしの剰余を求めます。
;<d0.l:被除数
;<d1.l:除数
;>d0.l:演算結果
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=有効数字の範囲外,(cs,ne)vc=アンダーフロー
fe_fmod::
	tst.l	d1
	beq	1f
	fmove.l	#$00000000,fpsr
	fmove.s	d0,fp0
	fmod.s	d1,fp0			;エミュレーション
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit	_

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7

1:	move.l	#$7FFFFFFF,d0
	exit	C,Z

;----------------------------------------------------------------
;$FE60	__FABS
;	4バイト浮動小数点数の絶対値を求めます。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_fabs::
	bclr.l	#31,d0
	exit

;----------------------------------------------------------------
;$FE61	__FCEIL
;	4バイト浮動小数点数と等しいか、それ以上の最小の整数を返します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_fceil::
	fmove.l	fpcr,d7
	fmove.l	#FPRM_RP,fpcr
	fint.s	d0,fp0
	fmove.s	fp0,d0
	fmove.l	d7,fpcr
	exit

;----------------------------------------------------------------
;$FE62	__FFIX
;	4バイト浮動小数点数の整数部を求めます。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_ffix::
	fintrz.s	d0,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE63	__FFLOOR
;	4バイト浮動小数点数と等しいかまたはそれより小さい最大の整数を返します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_ffloor::
	fmove.l	fpcr,d7
	fmove.l	#FPRM_RM,fpcr
	fint.s	d0,fp0
	fmove.s	fp0,d0
	fmove.l	d7,fpcr
	exit

;----------------------------------------------------------------
;$FE64	__FFRAC
;	4バイト浮動小数点数の小数部を求めます。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_ffrac::
	fmove.s	d0,fp0
	fintrz.x	fp0,fp1
	fsub.x	fp1,fp0
	fmove.s	fp0,d0
	exit

  .comment ********
	move.l	d2,-(sp)
	move.l	d0,d2
	swap.w	d2
	asr.w	#7,d2
	move.w	d2,-(sp)
	and.w	#$00FF,d2
	sub.w	#$007E,d2
	bls	3f
	cmp.w	#$002F,d2
	bhi	4f			;指数部が大きすぎる
	lsl.l	d2,d0
	and.l	#$00FFFFFF,d0
	beq	4f			;小数部が0
	moveq.l	#$17,d7
	btst.l	d7,d0
	bne	2f
1:	addq.w	#1,d2			;小数部を正規化する
	add.l	d0,d0
	btst.l	d7,d0
	beq	1b
2:	sub.w	(sp)+,d2
	neg.w	d2
	lsl.w	#7,d2
	swap.w	d0
	and.w	#$007F,d0
	add.w	d2,d0
	swap.w	d0
	exit	d2

3:	addq.l	#2,sp
	exit	d2

4:	move.w	(sp)+,d0
	swap.w	d0
	and.l	#$80000000,d0
	exit	d2
  ******** ********

;----------------------------------------------------------------
;$FE65	__FSGN
;	4バイト浮動小数点数が正か負か0かを調べます。
;<d0.l:4バイト浮動小数点数
;>d0.l:結果(4バイト浮動小数点数)
;	正なら+1、負なら-1、0なら0を返します。
fe_fsgn::
	add.l	d0,d0
	beq	@f
	move.l	#$3F800000<<1,d0
	roxr.l	#1,d0
@@:	exit

;----------------------------------------------------------------
;$FE66	__FSIN
;	角度(ラジアン単位)を与えて正弦(sin)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_fsin::
	fmove.s	d0,fp0
	fpsp	sin
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE67	__FCOS
;	角度(ラジアン単位)を与えて余弦(cos)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_fcos::
	fmove.s	d0,fp0
	fpsp	cos
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE68	__FTAN
;	角度(ラジアン単位)を与えて正接(tan)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(引数が、((2n+1)/2)π(n:整数))
fe_ftan::
	fmove.s	d0,fp0
	fpsp	tan
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE69	__FATAN
;	逆正接(atan)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果(ラジアン単位)
fe_fatan::
	fmove.s	d0,fp0
	fpsp	atan
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE6A	__FLOG
;	自然対数(log)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(引数が0または負)
;>z-flag:(cs)eq=引数が0(log 0)
fe_flog::
	fmove.s	d0,fp0
	fpsp	logn
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE6B	__FEXP
;	指数関数(e^x)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフロー)
fe_fexp::
	fmove.s	d0,fp0
	fpsp	etox
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE6C	__FSQR
;	平方根を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(引数が負)
fe_fsqr::
	tst.l	d0
	bmi	9f
	fmove.l	#$00000000,fpsr
	fsqrt.s	d0,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

9:	exit	C

;----------------------------------------------------------------
;$FE6D	__FPI
;	円周率を4バイト浮動小数点数の範囲内で返します。
;>d0.l:演算結果
fe_fpi::
	move.l	#$40490FDB,d0
	exit

;----------------------------------------------------------------
;$FE6E	__FNPI
;	円周率と4バイト浮動小数点数の積(xπ)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフロー)
fe_fnpi::
	fmove.l	#$00000000,fpsr
	fmove.x	pi(pc),fp0		;π
	fsglmul.s	d0,fp0
	fmove.s	fp0,d0
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit	_

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FE6F	__FPOWER
;	べき乗(X^y)を計算します。
;<d0.l:被べき乗数
;<d1.l:指数
;>d0.l:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_fpower::
	bsr	~001F80
	exit	ccr

~001F80:
	move.l	d0,-(sp)
	add.l	d0,d0
	cmpi.l	#$FFFFFFFE,d0
	beq	~001FDE
	move.l	d1,d0
	add.l	d0,d0
	beq	~00202C
	cmpi.l	#$FF000000,d0
	bcc	~001FE6
	move.l	(sp),d0
	add.l	d0,d0
	beq	~00203E
	bcs	~002048
	fmove.l	#$00000000,fpsr
	flogn.s	(sp),fp0		;エミュレーション
	fmul.s	d1,fp0
	fetox.x	fp0			;エミュレーション
	fmove.s	fp0,(sp)
	fmove.l	fpsr,d0
	and.w	#FPAE_IOP|FPAE_OVFL|FPAE_DZ,d0
	beq	~001FD6
	add.b	d0,d0
	add.b	d0,d0
	bcc	~001FD2
	addq.b	#1,d0
~001FD2:
	add.b	d0,d0
	addq.b	#1,d0
~001FD6:
	move.w	d0,ccr
	movem.l	(sp)+,d0
	rts

~001FDE:
	move.l	(sp)+,d0
	move.w	#$0000,ccr
	rts

~001FE6:
	beq	~001FF2
	move.l	d1,d0
	addq.l	#4,sp
	move.w	#$0000,ccr
	rts

~001FF2:
	move.l	(sp),d0
	add.l	d0,d0
	beq	~0020B6
	cmp.l	#$FF000000,d0
	beq	~00201A
	tst.l	d1
	bmi	~00203A
~002006:
	move.l	(sp)+,d0
	and.l	#$80000000,d0
	or.l	#$7F800000,d0
	move.w	#$0000,ccr
	rts

~00201A:
	tst.l	d1
	bpl	~002006
	move.l	(sp)+,d0
	or.l	#$7FFFFFFF,d0
	move.w	#$0000,ccr
	rts

~00202C:
	move.l	#$3F800000,d0
	move.w	#$0000,ccr
	addq.l	#4,sp
	rts

~00203A:
	tst.l	(sp)
	bmi	~0020B6
~00203E:
	moveq.l	#$00,d0
	move.w	#$0000,ccr
	addq.l	#4,sp
	rts

~002048:
	fmove.s	(sp),fp1
	move.l	d1,d0
;	bsr	fe_ffrac		;__FFRAC
	fmove.s	d0,fp0
	fintrz.x	fp0,fp1
	fsub.x	fp1,fp0
	fmove.s	fp0,d0
;
	add.l	d0,d0
	bne	~0020B6
	fmove.l	#$00000000,fpsr
	fmove.s	d1,fp0
	fmove.l	fp0,d0
	tst.l	d0
	beq	~00202C
	bpl	~00207A
	fmove.x	one(pc),fp0
	fdiv.x	fp1,fp0
	fmove.x	fp0,fp1
	neg.l	d0
~00207A:
	fmove.x	one(pc),fp0
~00207E:
	lsr.l	#1,d0
	bcc	~00208A
	fmul.x	fp1,fp0
	tst.l	d0
	beq	~002090
~00208A:
	fmul.x	fp1,fp1
	bra	~00207E

~002090:
	fmove.s	fp0,(sp)
	fmove.l	fpsr,d0
	and.w	#FPAE_IOP|FPAE_OVFL|FPAE_UNFL|FPAE_DZ,d0
	beq	~0020AE
	add.b	d0,d0
	add.b	d0,d0
	bcc	~0020A6
	addq.b	#1,d0
~0020A6:
	add.b	d0,d0
	bpl	~0020AC
	addq.b	#4,d0
~0020AC:
	addq.b	#1,d0
~0020AE:
	move.w	d0,ccr
	movem.l	(sp)+,d0
	rts

~0020B6:
	move.l	#$7FFFFFFF,d0
	move.w	#SRU_C,ccr
	addq.l	#4,sp
	rts

;----------------------------------------------------------------
;$FE70	__FRND
;	4バイト浮動小数点数の乱数を返します。
;>d0.l:4バイト浮動小数点数の乱数(0以上1未満)
fe_frnd::
	bsr	rnd
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE71	__FSINH
;	双曲正弦(sinh)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
fe_fsinh::
	fmove.s	d0,fp0
	fpsp	sinh
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE72	__FCOSH
;	双曲余弦(cosh)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
fe_fcosh::
	fmove.s	d0,fp0
	fpsp	cosh
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE73	__FTANH
;	双曲正接(tanh)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
fe_ftanh::
	fmove.s	d0,fp0
	fpsp	tanh
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE74	__FATANH
;	逆双曲正接(atanh)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
fe_fatanh::
	fmove.s	d0,fp0
	fpsp	atanh
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE75	__FASIN
;	逆正弦(asin)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(引数が-1以上+1以下の範囲に含まれていない)
fe_fasin::
	fmove.s	d0,fp0
	fpsp	asin
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE76	__FACOS
;	逆余弦(acos)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(引数が-1以上+1以下の範囲に含まれていない)
fe_facos::
	fmove.s	d0,fp0
	fpsp	acos
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE77	__FLOG10
;	常用対数(log10 X)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
fe_flog10::
	fmove.s	d0,fp0
	fpsp	log10
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE78	__FLOG2
;	ビット対数(log2)を計算します。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(オーバーフローまたはアンダーフロー)
fe_flog2::
	fmove.s	d0,fp0
	fpsp	log2
	fmove.s	fp0,d0
		tst.b	d7
	bmi	@f
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE79	__FFREXP
;	4バイト浮動小数点数の仮数部と指数部を分けます。
;<d0.l:4バイト浮動小数点数
;>d0.l:仮数部を示す4バイト浮動小数点数
;>d1.l:指数部を示す4バイト符号つき整数
;	返り値のd0は、引数の指数部を1に、仮数部をそのままにして返します。
fe_ffrexp::
	move.l	d0,d1			;seeeeeeeemmmmmmmmmmmmmmmmmmmmmmm
	lsl.l	#1,d1			;eeeeeeeemmmmmmmmmmmmmmmmmmmmmmm0
	beq	1f			;0のとき
	swap.w	d1			;eeeeeeeemmmmmmmm
	lsr.w	#8,d1			;00000000eeeeeeee
	sub.w	#$007F,d1
	ext.l	d1			;指数部(符号つき)
	and.l	#$807FFFFF,d0		;符号と仮数部を残して指数部を1にする
	or.l	#$3F800000,d0		;
	exit

1:	moveq.l	#0,d0			;符号を消す
					;d1.lは既に0
	exit

;----------------------------------------------------------------
;$FE7A	__FLDEXP
;	指数部と仮数部を結合して4バイト浮動小数点数を返します。
;<d0.l:仮数部データ(4バイト浮動小数点数)
;<d1.l:指数部データ(4バイト符号つき整数)
;>d0.l:合成された4バイト浮動小数点数
;>c-flag:cs=エラー
;	引数のd0の指数部にd1の値+$7Fを加算します。
fe_fldexp::
	move.l	d0,d7			;seeeeeeeemmmmmmm_mmmmmmmmmmmmmmmm
	lsl.l	#1,d7			;eeeeeeeemmmmmmmm_mmmmmmmmmmmmmmm0
	beq	1f			;0のとき
	swap.w	d7			;eeeeeeeemmmmmmmm
	lsr.w	#8,d7			;00000000eeeeeeee
	ext.l	d7
	add.l	d1,d7			;指数部を加算
	beq	2f
	cmp.l	#$00000FF,d7
	bcc	2f
	lsl.w	#7,d7			;0eeeeeeee0000000
	swap.w	d7			;0eeeeeeee0000000_0000000000000000
	and.l	#$807FFFFF,d0
	or.l	d7,d0
	exit	_

1:	moveq.l	#0,d0			;0のとき
	exit	_

2:	exit	C			;d0は変化しない

;----------------------------------------------------------------
;$FE7B	__FADDONE
;	4バイト浮動小数点数に1を加えます。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_faddone::
	fmove.s	d0,fp0
	fadd.s	#0f1,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE7C	__FSUBONE
;	4バイト浮動小数点数から1を引きます。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
fe_fsubone::
	fmove.s	d0,fp0
	fsub.s	#0f1,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE7D	__FDIVTWO
;	4バイト浮動小数点数を2で割ります。
;<d0.l:4バイト浮動小数点数
;>d0.l:演算結果
;>c-flag:cs=エラー(アンダーフロー)
fe_fdivtwo::
	tst.l	d0
	beq	1f
	bmi	3f
	cmp.l	#$7F800000,d0
	bcc	1f
	sub.l	#$00800000,d0
	bcs	2f
	cmp.l	#$00800000,d0
	bcs	2f
1:	exit	_

2:	moveq.l	#0,d0
	exit	C,Z

3:	cmp.l	#$FF800000,d0
	bcc	4f
	sub.l	#$00800000,d0
	cmp.l	#$80800000,d0
	bcs	2b
4:	exit	_

;----------------------------------------------------------------
;$FE7E	__FIEECNV
;	4バイト浮動小数点数をIEEEフォーマットに変換します。
;<d0.l:4バイト浮動小数点数
;>d0.l:IEEEフォーマット4バイト浮動小数点数
;	FLOAT2.X、FLOAT3.Xでは変換しません。
fe_fieecnv::
	exit

;----------------------------------------------------------------
;$FE7F	__IEEFCNV
;	IEEEフォーマットを4バイト浮動小数点数に変換します。
;<d0.l:IEEEフォーマット4バイト浮動小数点数
;>d0.l:4バイト浮動小数点数
;	FLOAT2.X、FLOAT3.Xでは変換しません。
fe_ieefcnv::
	exit

;----------------------------------------------------------------
;$FEE0	__CLMUL
;	4バイト符号つき整数どうしの乗算をします。
;<(sp).l:被乗数の4バイト符号つき整数
;<(4,sp).l:乗数の4バイト符号つき整数
;>(sp).l:演算結果の4バイト符号つき整数
;>c-flag:cs=エラー(演算結果が4バイト符号つき整数の範囲を超えた)
fe_clmul::
	param	a6
	move.l	(a6)+,d7
	muls.l	(a6),d7
	svs.b	-(sp)
		move.l	d7,-(a6)
	move.b	(sp)+,d7
		neg.b	d7
	exit	D7

;----------------------------------------------------------------
;$FEE1	__CLDIV
;	4バイト符号つき整数どうしの除算をします。
;<(sp).l:被除数の4バイト符号つき整数
;<(4,sp).l:除数の4バイト符号つき整数
;>(sp).l:演算結果の4バイト符号つき整数
;>c-flag:cs=エラー(除数が0)
fe_cldiv::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCRクリア
	divs.l	(a6),d7
	exit	-7

@@:	exit	C

;----------------------------------------------------------------
;$FEE2	__CLMOD
;	4バイト符号つき整数どうしの除算の剰余を計算します。
;<(sp).l:被除数の4バイト符号つき整数
;<(4,sp).l:除数の4バイト符号つき整数
;>(sp).l:演算結果の4バイト符号つき整数
;>c-flag:cs=エラー(除数が0)
fe_clmod::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCRクリア
	move.l	d0,-(sp)
	divsl.l	(a6),d0:d7
	exit	-0,d0

@@:	exit	C

;----------------------------------------------------------------
;$FEE3	__CUMUL
;	4バイト符号なし整数どうしの乗算をします。
;<(sp).l:被乗数の4バイト符号つき整数
;<(4,sp).l:乗数の4バイト符号つき整数
;>(sp).l:演算結果の4バイト符号つき整数
;>c-flag:cs=エラー(演算結果が4バイト符号つき整数の範囲を超えた)
fe_cumul::
	param	a6
	move.l	(a6)+,d7
	mulu.l	(a6),d7
	svs.b	-(sp)
		move.l	d7,-(a6)
	move.b	(sp)+,d7
		neg.b	d7
	exit	D7

;----------------------------------------------------------------
;$FEE4	__CUDIV
;	4バイト符号なし整数どうしの除算をします。
;<(sp).l:被除数の4バイト符号つき整数
;<(4,sp).l:除数の4バイト符号つき整数
;>(sp).l:演算結果の4バイト符号つき整数
;>c-flag:cs=エラー(除数が0)
fe_cudiv::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCRクリア
	divu.l	(a6),d7
	exit	-7

@@:	exit	C

;----------------------------------------------------------------
;$FEE5	__CUMOD
;	4バイト符号なし整数どうしの除算の剰余を計算します。
;<(sp).l:被除数の4バイト符号つき整数
;<(4,sp).l:除数の4バイト符号つき整数
;>(sp).l:演算結果の4バイト符号つき整数
;>c-flag:cs=エラー(除数が0)
fe_cumod::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCRクリア
	move.l	d0,-(sp)
	divul.l	(a6),d0:d7
	exit	-0,d0

@@:	exit	C

;----------------------------------------------------------------
;$FEE6	__CLTOD
;	4バイト符号つき整数を8バイト浮動小数点数に変換します。
;<(sp).l:4バイト符号つき整数
;>(sp).d:変換された8バイト浮動小数点数
fe_cltod::
	param	a6
	fmove.l	(a6),fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEE7	__CDTOL
;	8バイト浮動小数点数を4バイト符号つき整数に変換します。
;<(sp).d:8バイト浮動小数点数
;>(sp).l:変換された4バイト符号つき整数
;>c-flag:cs=エラー(変換結果が4バイト符号つき整数の値の範囲を超えた)
;	小数部分は切り捨てられます。
;	4バイト符号つき整数の値は次の範囲です。
;		-2147483648～+2147483647
fe_cdtol::
	param	a6
	fmove.l	#$00000000,fpsr
	fintrz.d	(a6),fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.l	fp0,(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|0|0|0|0|0|0,d7	;iv000000
	bne	@f
	exit

@@:	add.b	d7,d7			;v0000000
	rol.b	#2,d7			;000000v0
	addq.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEE8	__CLTOF
;	4バイト符号つき整数を4バイト浮動小数点数に変換します。
;<(sp).l:4バイト符号つき整数
;>(sp).s:変換された4バイト浮動小数点数
fe_cltof::
	param	a6
	fmove.l	(a6),fp0
	fmove.s	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEE9	__CFTOL
;	4バイト浮動小数点数を4バイト符号つき整数に変換します。
;<(sp).s:4バイト浮動小数点数
;>(sp).l:変換された4バイト符号つき整数
;>c-flag:cs=エラー(変換結果が4バイト符号つき整数の値の範囲を超えた)
;	小数部分は切り捨てられます。
;	4バイト符号つき整数の値は次の範囲です。
;		-2147483648～+2147483647
fe_cftol::
	param	a6
	fmove.l	#$00000000,fpsr
	fintrz.s	(a6),fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.l	fp0,(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|0|0|0|0|0|0,d7	;iv000000
	bne	@f
	exit

@@:	add.b	d7,d7			;v0000000
	rol.b	#2,d7			;000000v0
	addq.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEEA	__CFTOD
;	4バイト浮動小数点数を8バイト浮動小数点数に変換します。
;<(sp).s:4バイト浮動小数点数
;>(sp).d:変換された8バイト浮動小数点数
fe_cftod::
	param	a6
	fmove.s	(a6),fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEEB	__CDTOF
;	8バイト浮動小数点数を4バイト浮動小数点数に変換します。
;<(sp).d:8バイト浮動小数点数
;>(sp).s:変換された4バイト浮動小数点数
;>c-flag:cs=エラー(引数が4バイト浮動小数点数で表現できない)
fe_cdtof::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6),fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmove.s	fp0,(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|0|0|0|0|0|0,d7	;iv000000
	bne	@f
	exit

@@:	add.b	d7,d7			;v0000000
	rol.b	#2,d7			;000000v0
	addq.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEEC	__CDCMP
;	8バイト浮動小数点数どうしの比較をします。
;<(sp).d:被比較数
;<(8,sp).d:比較数
;	被比較数から比較数を減算した結果にしたがってセットされます。
;>n-flag:mi=負
;>z-flag:eq=0
;>c-flag:cs=ボローが発生した
;	被比較数が比較数より大きいとき	cc,ne,pl
;	被比較数が比較数と等しいとき	cc,eq,pl
;	被比較数が比較数より小さいとき	cs,ne,mi
fe_cdcmp::
	param	a6
	move.l	(a6),d7
	bmi	1f
	tst.l	(8,a6)
	bmi	2f
	cmp.l	(8,a6),d7
	bne	@f
	move.l	(4,a6),d7
	cmp.l	(8+4,a6),d7
@@:	exit	ccr

1:	move.l	(8,a6),d7
	bpl	3f
	cmp.l	(a6),d7
	bne	@f
	move.l	(8+4,a6),d7
	cmp.l	(4,a6),d7
@@:	exit	ccr

2:	exit	_

3:	exit	C,N

;----------------------------------------------------------------
;$FEED	__CDADD
;	8バイト浮動小数点数どうしの加算をします。
;<(sp).d:被加算数の8バイト浮動小数点数
;<(8,sp).d:加算数の8バイト浮動小数点数
;>(sp).d:演算結果の8バイト浮動小数点数
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_cdadd::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fadd.d	(a6),fp0
	fmove.d	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEEE	__CDSUB
;	8バイト浮動小数点数どうしの減算をします。
;<(sp).d:被減算数の8バイト浮動小数点数
;<(8,sp).d:減算数の8バイト浮動小数点数
;>(sp).d:演算結果の8バイト浮動小数点数
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_cdsub::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fsub.d	(a6),fp0
	fmove.d	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEEF	__CDMUL
;	8バイト浮動小数点数どうしの乗算をします。
;<(sp).d:被乗算数の8バイト浮動小数点数
;<(8,sp).d:乗算数の8バイト浮動小数点数
;>(sp).d:演算結果の8バイト浮動小数点数
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_cdmul::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmul.d	(a6),fp0
	fmove.d	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEF0	__CDDIV
;	8バイト浮動小数点数どうしの除算をします。
;<(sp).d:被除算数の8バイト浮動小数点数
;<(8,sp).d:除算数の8バイト浮動小数点数
;>(sp).d:演算結果の8バイト浮動小数点数
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=オーバーフロー,(cs,ne)vc=アンダーフロー
fe_cddiv::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fdiv.d	(a6),fp0
	fmove.d	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7

;----------------------------------------------------------------
;$FEF1	__CDMOD
;	8バイト浮動小数点数どうしの剰余を求めます。
;<(sp).d:被除算数の8バイト浮動小数点数
;<(8,sp).d:除算数の8バイト浮動小数点数
;>(sp).d:演算結果の8バイト浮動小数点数
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=有効数字の範囲外,(cs,ne)vc=アンダーフロー
fe_cdmod::
	param	a6
	move.l	(8,a6),d7
	add.l	d7,d7
	or.l	(8+4,a6),d7
	beq	1f
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmod.d	(a6),fp0		;エミュレーション
	fmove.d	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7

1:	move.l	#$7FFFFFFF,(a6)+
	move.l	#$FFFFFFFF,(a6)
	exit	C,Z

;----------------------------------------------------------------
;$FEF2	__CFCMP
;	4バイト浮動小数点数どうしの比較をします。
;<(sp).s:被比較数
;<(4,sp).s:比較数
;	被比較数から比較数を減算した結果にしたがってセットされます。
;>n-flag:mi=負
;>z-flag:eq=0
;>c-flag:cs=ボローが発生した
;	被比較数が比較数より大きいとき	cc,ne,pl
;	被比較数が比較数と等しいとき	cc,eq,pl
;	被比較数が比較数より小さいとき	cs,ne,mi
fe_cfcmp::
	param	a6
	move.l	(a6)+,d7
	bmi	1f
	tst.l	(a6)
	bmi	2f
	cmp.l	(a6),d7
	exit	ccr

1:	move.l	(a6),d7
	bpl	3f
	cmp.l	-(a6),d7
	exit	ccr

2:	exit	_

3:	exit	C,N

;----------------------------------------------------------------
;$FEF3	__CFADD
;	4バイト浮動小数点数どうしの加算をします。
;<(sp).s:被加算数
;<(4,sp).s:加算数
;>(sp).s:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_cfadd::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fadd.s	(a6),fp0
	fmove.s	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEF4	__CFSUB
;	4バイト浮動小数点数どうしの減算をします。
;<(sp).s:被減算数
;<(4,sp).s:減算数
;>(sp).s:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_cfsub::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fsub.s	(a6),fp0
	fmove.s	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEF5	__CFMUL
;	4バイト浮動小数点数どうしの乗算をします。
;<(sp).s:被乗算数
;<(4,sp).s:乗算数
;>(sp).s:演算結果
;>c-flag:cs=エラー
;>v-flag:(cs)vs=オーバーフロー,(cs)vc=アンダーフロー
fe_cfmul::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fsglmul.s	(a6),fp0
	fmove.s	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|0|0|0|0|0,d7	;ivu00000
	bne	@f
	exit

@@:	add.b	d7,d7			;vu000000
	rol.b	#2,d7			;000000vu
	or.b	#0|0|0|0|C,d7		;000000vc
	exit	D7

;----------------------------------------------------------------
;$FEF6	__CFDIV
;	4バイト浮動小数点数どうしの除算をします。
;<(sp).s:被除算数
;<(4,sp).s:除算数
;>(sp).s:演算結果
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=オーバーフロー,(cs,ne)vc=アンダーフロー
fe_cfdiv::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fsgldiv.s	(a6),fp0
	fmove.s	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7

;----------------------------------------------------------------
;$FEF7	__CFMOD
;	4バイト浮動小数点数どうしの剰余を求めます。
;<(sp).s:被除算数
;<(4,sp).s:除算数
;>(sp).s:演算結果
;>c-flag:cs=エラー
;>z-flag:(cs)eq=0で割った
;>v-flag:(cs,ne)vs=有効数字の範囲外,(cs,ne)vc=アンダーフロー
fe_cfmod::
	param	a6
	tst.l	4(a6)
	beq	1f
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCRクリア
	fmod.s	(a6),fp0		;エミュレーション
	fmove.s	fp0,-(a6)
	fmove.l	fpsr,d7
	and.b	#i|v|u|z|0|0|0|0,d7	;ivuz0000
	bne	@f
	exit

@@:	add.b	d7,d7			;vuz00000
	rol.b	#2,d7			;z00000vu
	bpl	@f
	addq.b	#4,d7			;z0000zvu
@@:	or.b	#0|0|0|0|C,d7		;z0000zvc
	exit	D7

1:	move.l	#$7FFFFFFF,(a6)
	exit	C,Z

;----------------------------------------------------------------
;$FEF8	__CDTST
;	8バイト浮動小数点数と0の比較をします。
;<(sp).d:8バイト浮動小数点数
;>z-flag:eq=0
;>n-flag:mi=負
fe_cdtst::
	param	a6
	move.l	(a6)+,d7
	or.w	(a6)+,d7
	or.w	(a6),d7
	tst.l	d7
	exit	ccr

;----------------------------------------------------------------
;$FEF9	__CFTST
;	4バイト浮動小数点数と0の比較をします。
;<(sp).s:4バイト浮動小数点数
;>z-flag:eq=0
;>n-flag:mi=負
fe_cftst::
	param	a6
	cmpi.l	#$80000000,(a6)
	beq	@f
	tst.l	(a6)
@@:	exit	ccr

;----------------------------------------------------------------
;$FEFA	__CDINC
;	8バイト浮動小数点数に1を加えます。
;<(sp).d:8バイト浮動小数点数
;>(sp).d:演算結果
fe_cdinc::
	param	a6
	fmove.d	(a6),fp0
	fadd.s	#0f1,fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFB	__CFINC
;	4バイト浮動小数点数に1を加えます。
;<(sp).s:4バイト浮動小数点数
;>(sp).s:演算結果
fe_cfinc::
	param	a6
	fmove.s	(a6),fp0
	fadd.s	#0f1,fp0
	fmove.s	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFC	__CDDEC
;	8バイト浮動小数点数から1を引きます。
;<(sp).d:8バイト浮動小数点数
;>(sp).d:演算結果
fe_cddec::
	param	a6
	fmove.d	(a6),fp0
	fsub.s	#0f1,fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFD	__CFDEC
;	4バイト浮動小数点数から1を引きます。
;<(sp).s:4バイト浮動小数点数
;>(sp).s:演算結果
fe_cfdec::
	param	a6
	fmove.s	(a6),fp0
	fsub.s	#0f1,fp0
	fmove.s	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFE	__FEVARG
;	組み込まれている数値演算デバイスドライバの種類を照会します。
;	組み込まれている数値演算デバイスドライバにより次に示す値が返ります。
;FLOAT1.Xの場合
;>d0.l:'HS86'($48533836)
;>d1.l:'SOFT'($534F4654)
;FLOAT2.Xの場合
;>d0.l:'IEEE'($49454545)
;>d1.l:'SOFT'($534F4654)
;FLOAT3.Xの場合
;>d0.l:'IEEE'($49454545)
;>d1.l:'FPCP'($46504350)
;FLOAT4.Xの場合
;>d0.l:'IEEE'($49454545)
;>d1.l:'FP20'($46503230)
fe_fevarg::
	move.l	#'IEEE',d0
	move.l	#'FPSP',d1
	exit

;----------------------------------------------------------------
;$FEFF	__FEVECS
;	浮動小数点演算処理の追加、変更。
;<d0.l:FETBLの番号
;<a0.l:処理アドレス
;>d0.l:前の処理アドレス
;	引数のd0の値は$FE00～$FEFEの範囲です。
;	これ以外の値を渡すとd0に-1を返します。
fe_fevecs::
	moveq.l	#-1,d0
	exit

;----------------------------------------------------------------
;定数
pi:
	.dc.x	!40000000C90FDAA22168C235	;cr($00)=π
one:
	.dc.x	!3FFF00008000000000000000	;cr($32)=10^0

;	.dc.x	!40000000C90FDAA22168C235	;π
;	.dc.x	!3FFD0000A2F9836E4E44152A	;1/π
;	.dc.x	!3FFD00009A209A84FBCFF798	;log10(2)
;	.dc.x	!40000000D49A784BCD1B8AFF	;1/log10(2)
;	.dc.x	!40000000ADF85458A2BB4A9A	;e
;	.dc.x	!3FFD0000BC5AB1B16779BE36	;1/e
;	.dc.x	!3FFF0000B8AA3B295C17F0BC	;log2(e)
;	.dc.x	!3FFE0000B17217F7D1CF79AC	;1/log2(e)
;	.dc.x	!3FFD0000DE5BD8A937287195	;log10(e)
;	.dc.x	!40000000935D8DDDAAA8AC17	;1/log10(e)
;	.dc.x	!000000000000000000000000	;0
;	.dc.x	!3FFE0000B17217F7D1CF79AC	;ln(2)
;	.dc.x	!3FFF0000B8AA3B295C17F0BC	;1/ln(2)
;	.dc.x	!40000000935D8DDDAAA8AC17	;ln(10)
;	.dc.x	!3FFD0000DE5BD8A937287195	;1/ln(10)
;	.dc.x	!3FFF00008000000000000000	;10^0
;	.dc.x	!3FFF00008000000000000000	;10^-0
;	.dc.x	!40020000A000000000000000	;10^1
;	.dc.x	!3FFB0000CCCCCCCCCCCCCCCD	;10^-1
;	.dc.x	!40050000C800000000000000	;10^2
;	.dc.x	!3FF80000A3D70A3D70A3D70A	;10^-2
;	.dc.x	!400C00009C40000000000000	;10^4
;	.dc.x	!3FF10000D1B71758E219652C	;10^-4
;	.dc.x	!40190000BEBC200000000000	;10^8
;	.dc.x	!3FE40000ABCC77118461CEFD	;10^-8
;	.dc.x	!403400008E1BC9BF04000000	;10^16
;	.dc.x	!3FC90000E69594BEC44DE15B	;10^-16
;	.dc.x	!406900009DC5ADA82B70B59E	;10^32
;	.dc.x	!3F940000CFB11EAD453994BA	;10^-32
;	.dc.x	!40D30000C2781F49FFCFA6D5	;10^64
;	.dc.x	!3F2A0000A87FEA27A539E9A5	;10^-64
;	.dc.x	!41A8000093BA47C980E98CE0	;10^128
;	.dc.x	!3E550000DDD0467C64BCE4A0	;10^-128
;	.dc.x	!43510000AA7EEBFB9DF9DE8E	;10^256
;	.dc.x	!3CAC0000C0314325637A193A	;10^-256
;	.dc.x	!46A30000E319A0AEA60E91C7	;10^512
;	.dc.x	!395A00009049EE32DB23D21C	;10^-512
;	.dc.x	!4D480000C976758681750C17	;10^1024
;	.dc.x	!32B50000A2A682A5DA57C0BE	;10^-1024
;	.dc.x	!5A9200009E8B3B5DC53D5DE5	;10^2048
;	.dc.x	!256B0000CEAE534F34362DE4	;10^-2048
;	.dc.x	!75250000C46052028A20979B	;10^4096
;	.dc.x	!0AD80000A6DD04C8D2CE9FDE	;10^-4096
;	.dc.x	!3FFF00008000000000000000	;10^0
;	.dc.x	!40020000A000000000000000	;10^1
;	.dc.x	!40050000C800000000000000	;10^2
;	.dc.x	!40080000FA00000000000000	;10^3
;	.dc.x	!400C00009C40000000000000	;10^4
;	.dc.x	!400F0000C350000000000000	;10^5
;	.dc.x	!40120000F424000000000000	;10^6
;	.dc.x	!401600009896800000000000	;10^7
;	.dc.x	!40190000BEBC200000000000	;10^8
;	.dc.x	!401C0000EE6B280000000000	;10^9
;	.dc.x	!402000009502F90000000000	;10^10
;	.dc.x	!40230000BA43B74000000000	;10^11
;	.dc.x	!40260000E8D4A51000000000	;10^12
;	.dc.x	!402A00009184E72A00000000	;10^13
;	.dc.x	!402D0000B5E620F480000000	;10^14
;	.dc.x	!40300000E35FA931A0000000	;10^15
;	.dc.x	!403400008E1BC9BF04000000	;10^16
;	.dc.x	!40370000B1A2BC2EC5000000	;10^17
;	.dc.x	!403A0000DE0B6B3A76400000	;10^18
;	.dc.x	!403E00008AC7230489E80000	;10^19
;	.dc.x	!40410000AD78EBC5AC620000	;10^20
;	.dc.x	!40440000D8D726B7177A8000	;10^21
;	.dc.x	!40480000878678326EAC9000	;10^22
;	.dc.x	!404B0000A968163F0A57B400	;10^23
;	.dc.x	!404E0000D3C21BCECCEDA100	;10^24
;	.dc.x	!4052000084595161401484A0	;10^25
;	.dc.x	!40550000A56FA5B99019A5C8	;10^26
;	.dc.x	!40580000CECB8F27F4200F3A	;10^27
;	.dc.x	!405C0000813F3978F8940984	;10^28
;	.dc.x	!405F0000A18F07D736B90BE5	;10^29
;	.dc.x	!40620000C9F2C9CD04674EDE	;10^30
;	.dc.x	!40650000FC6F7C4045812296	;10^31
;	.dc.x	!406900009DC5ADA82B70B59E	;10^32
;	.dc.x	!406C0000C5371912364CE306	;10^33
;	.dc.x	!406F0000F684DF56C3E01BC8	;10^34
;	.dc.x	!407300009A130B963A6C115D	;10^35
;	.dc.x	!40760000C097CE7BC90715B4	;10^36
;	.dc.x	!40790000F0BDC21ABB48DB21	;10^37
;	.dc.x	!407D000096769950B50D88F5	;10^38
;	.dc.x	!40800000BC143FA4E250EB32	;10^39
;	.dc.x	!40830000EB194F8E1AE525FE	;10^40
;	.dc.x	!4087000092EFD1B8D0CF37BF	;10^41
;	.dc.x	!408A0000B7ABC627050305AF	;10^42
;	.dc.x	!408D0000E596B7B0C643C71B	;10^43
;	.dc.x	!409100008F7E32CE7BEA5C71	;10^44
;	.dc.x	!40940000B35DBF821AE4F38D	;10^45
;	.dc.x	!40970000E0352F62A19E3070	;10^46
;	.dc.x	!409B00008C213D9DA502DE46	;10^47
;	.dc.x	!409E0000AF298D050E4395D8	;10^48
;	.dc.x	!40A10000DAF3F04651D47B4E	;10^49
;	.dc.x	!40A5000088D8762BF324CD11	;10^50
;	.dc.x	!40A80000AB0E93B6EFEE0055	;10^51
;	.dc.x	!40AB0000D5D238A4ABE9806A	;10^52
;	.dc.x	!40AF000085A36366EB71F042	;10^53
;	.dc.x	!40B20000A70C3C40A64E6C52	;10^54
;	.dc.x	!40B50000D0CF4B50CFE20766	;10^55
;	.dc.x	!40B9000082818F1281ED44A0	;10^56
;	.dc.x	!40BC0000A321F2D7226895C8	;10^57
;	.dc.x	!40BF0000CBEA6F8CEB02BB3A	;10^58
;	.dc.x	!40C20000FEE50B7025C36A08	;10^59
;	.dc.x	!40C600009F4F2726179A2245	;10^60
;	.dc.x	!40C90000C722F0EF9D80AAD6	;10^61
;	.dc.x	!40CC0000F8EBAD2B84E0D58C	;10^62
;	.dc.x	!40D000009B934C3B330C8578	;10^63
;	.dc.x	!3FFF00008000000000000000	;10^-0
;	.dc.x	!3FFB0000CCCCCCCCCCCCCCCD	;10^-1
;	.dc.x	!3FF80000A3D70A3D70A3D70A	;10^-2
;	.dc.x	!3FF5000083126E978D4FDF3B	;10^-3
;	.dc.x	!3FF10000D1B71758E219652B	;10^-4
;	.dc.x	!3FEE0000A7C5AC471B478422	;10^-5
;	.dc.x	!3FEB00008637BD05AF6C69B5	;10^-6
;	.dc.x	!3FE70000D6BF94D5E57A42BB	;10^-7
;	.dc.x	!3FE40000ABCC77118461CEFC	;10^-8
;	.dc.x	!3FE1000089705F4136B4A596	;10^-9
;	.dc.x	!3FDD0000DBE6FECEBDEDD5BD	;10^-10
;	.dc.x	!3FDA0000AFEBFF0BCB24AAFE	;10^-11
;	.dc.x	!3FD700008CBCCC096F5088CB	;10^-12
;	.dc.x	!3FD30000E12E13424BB40E12	;10^-13
;	.dc.x	!3FD00000B424DC35095CD80E	;10^-14
;	.dc.x	!3FCD0000901D7CF73AB0ACD8	;10^-15
;	.dc.x	!3FC90000E69594BEC44DE15A	;10^-16
;	.dc.x	!3FC60000B877AA3236A4B448	;10^-17
;	.dc.x	!3FC300009392EE8E921D5D06	;10^-18
;	.dc.x	!3FBF0000EC1E4A7DB69561A3	;10^-19
;	.dc.x	!3FBC0000BCE5086492111AE9	;10^-20
;	.dc.x	!3FB90000971DA05074DA7BEE	;10^-21
;	.dc.x	!3FB50000F1C90080BAF72CB0	;10^-22
;	.dc.x	!3FB20000C16D9A0095928A26	;10^-23
;	.dc.x	!3FAF00009ABE14CD44753B52	;10^-24
;	.dc.x	!3FAB0000F79687AED3EEC550	;10^-25
;	.dc.x	!3FA80000C612062576589DDA	;10^-26
;	.dc.x	!3FA500009E74D1B791E07E48	;10^-27
;	.dc.x	!3FA10000FD87B5F28300CA0D	;10^-28
;	.dc.x	!3F9E0000CAD2F7F5359A3B3E	;10^-29
;	.dc.x	!3F9B0000A2425FF75E14FC32	;10^-30
;	.dc.x	!3F98000081CEB32C4B43FCF5	;10^-31
;	.dc.x	!3F940000CFB11EAD453994BB	;10^-32
;	.dc.x	!3F910000A6274BBDD0FADD62	;10^-33
;	.dc.x	!3F8E000084EC3C97DA624AB5	;10^-34
;	.dc.x	!3F8A0000D4AD2DBFC3D07788	;10^-35
;	.dc.x	!3F870000AA242499697392D3	;10^-36
;	.dc.x	!3F840000881CEA14545C7576	;10^-37
;	.dc.x	!3F800000D9C7DCED53C72256	;10^-38
;	.dc.x	!3F7D0000AE397D8AA96C1B78	;10^-39
;	.dc.x	!3F7A00008B61313BBABCE2C6	;10^-40
;	.dc.x	!3F760000DF01E85F912E37A3	;10^-41
;	.dc.x	!3F730000B267ED1940F1C61C	;10^-42
;	.dc.x	!3F7000008EB98A7A9A5B04E3	;10^-43
;	.dc.x	!3F6C0000E45C10C42A2B3B05	;10^-44
;	.dc.x	!3F690000B6B00D69BB55C8D1	;10^-45
;	.dc.x	!3F6600009226712162AB070E	;10^-46
;	.dc.x	!3F620000E9D71B689DDE71B0	;10^-47
;	.dc.x	!3F5F0000BB127C53B17EC15A	;10^-48
;	.dc.x	!3F5C000095A8637627989AAE	;10^-49
;	.dc.x	!3F580000EF73D256A5C0F77D	;10^-50
;	.dc.x	!3F550000BF8FDB78849A5F97	;10^-51
;	.dc.x	!3F520000993FE2C6D07B7FAC	;10^-52
;	.dc.x	!3F4E0000F53304714D9265E0	;10^-53
;	.dc.x	!3F4B0000C428D05AA4751E4D	;10^-54
;	.dc.x	!3F4800009CED737BB6C4183E	;10^-55
;	.dc.x	!3F440000FB158592BE068D30	;10^-56
;	.dc.x	!3F410000C8DE047564D20A8D	;10^-57
;	.dc.x	!3F3E0000A0B19D2AB70E6ED7	;10^-58
;	.dc.x	!3F3B0000808E17555F3EBF12	;10^-59
;	.dc.x	!3F370000CDB02555653131B6	;10^-60
;	.dc.x	!3F340000A48CEAAAB75A8E2B	;10^-61
;	.dc.x	!3F31000083A3EEEEF9153E89	;10^-62
;	.dc.x	!3F2D0000D29FE4B18E88640E	;10^-63

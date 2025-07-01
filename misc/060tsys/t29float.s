;----------------------------------------------------------------
;
;	FE�t�@���N�V����
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t06float.equ

	.cpu	68060

;----------------------------------------------------------------
;�������̃��[�`��
;	_USING	_FUSING	(#INF��#NAN�̏���)
;	_POWER	_FPOWER
;	_DTOS	(pi()/180�Ȃǂ̎w�����̕\��)


;----------------------------------------------------------------
;FPU���������镂�������_����
;	FABS	FADD	FBcc	FCMP	FDABS	FDADD	FDDIV	FDIV
;	FDMOVE	FDMUL	FDNEG	FDSQRT	FDSUB	FINT	FINTRZ	FMOVE
;	FMOVEM*	FMUL	FNEG	FNOP	FRESTORE	FSABS	FSADD
;	FSDIV	FSMOVE	FSMUL	FSNEG	FSAVE	FSQRT	FSSQRT	FSSUB
;	FSUB	FTST

;----------------------------------------------------------------
;FPSP���������镂�������_����
;	FACOS	FASIN	FATAN	FATANH	FCOS	FCOSH	FDBcc	FETOX
;	FETOXM1	FGETEXP	FGETMAN	FLOG10	FLOG2	FLOGN	FLOGNP1	FMOD
;	FMOVECR	FMOVEM*	FREM	FSCALE	FScc	FSGLDIV	FSGLMUL	FSIN
;	FSINCOS	FSINH	FTAN	FTANH	FTENTOX	FTRAPcc	FTWOTOX

;----------------------------------------------------------------
;FPSP�����̃G�~�����[�V�������[�`���̃I�t�Z�b�g
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
;	fpsp	�֐���
;
;	�@�\
;		�EFPSP�����̃G�~�����[�V�������[�`�����Ăяo���܂��B
;
;	����
;		FP0	�֐��̈���
;
;	�ԋp�l
;		FP0	���Z����
;		D7	FPSR
;
;	�j�󃌃W�X�^
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
		moveq.l	#0,d0			;���E���f�B���O���[�h
	jsr	name

	move.l	-192+36(a6),d7		;FPSR
;;;	lea.l	12(sp),sp
	unlk	a6
	movea.l	(sp)+,a0
		movea.l	(sp)+,a1
	.endm

;----------------------------------------------------------------
;
;	exit	����,�c
;
;	�@�\
;		�EF�n�񖽗߃G�~�����[�V�������I�����܂��B
;		�E�������郌�W�X�^�ACCR�̐ݒ�A�X�^�b�N�ɏo�͂���f�[�^�Ȃǂ�
;		  �w��ł��܂��B
;
;	����(�������郌�W�X�^�Ɋւ������)
;		�Ed0�`d6 �̃��W�X�^���𕡐��w��ł��܂��B
;		�E�A�h���X���W�X�^�͎w��ł��܂���B
;			dn	dn�𕜌����܂��B
;				d�͏������ŁAn��0�`6�̐����ł��B
;
;	����(CCR�Ɋւ������)
;		�ECCR�Ɋւ�������̎w�肪�Ȃ���΁ACCR�͕ω����܂���B
;		  (FE�t�@���N�V�����R�[���̑O��ŕω����܂���)
;		�E_,C,V,Z,N,X��6�Ɍ���A�����w��ł��܂��B
;		�E_,C,V,Z,N,X�̂����ꂩ���w�肳��Ă���Ƃ��́A�w�肳��Ȃ������t���O��
;		  �N���A����܂��B
;			_	���ׂẴt���O���N���A���܂��B
;			C	C�t���O���Z�b�g���܂��B
;			V	V�t���O���Z�b�g���܂��B
;			Z	Z�t���O���Z�b�g���܂��B
;			N	N�t���O���Z�b�g���܂��B
;			X	X�t���O���Z�b�g���܂��B
;			ccr	���݂�ccr�̓��e�����̂܂ܕԂ��܂��B
;			Dn	���݂�Dn�̓��e��ccr�ɐݒ肵�܂��B
;				D�͑啶���ŁAn��0�`7�̐����ł��B
;
;	����(�X�^�b�N�ɏo�͂���f�[�^�Ɋւ������)
;		�E���̂����ꂩ1���w��ł��܂��B
;		�E�f�N�������g���[�h�Ƃ́A����1�����O���[�h���C���N�������g����Ă���
;		  �ꍇ�ł��B
;			=n	dn���o�͂��܂��B
;			=mn	dm/dn���o�͂��܂��B
;			-n	dn���o�͂��܂��B(�f�N�������g���[�h)
;			-mn	dm/dn���o�͂��܂��B(�f�N�������g���[�h)
;				m,n��0�`7�̐����ł��B
;
;	�⑫
;		�E�����̏����͔C�ӂł��B
;		�E���������������ƁA�A�Z���u�����ɃG���[�ɂȂ�܂��B
;
;----------------------------------------------------------------
exit	.macro	_0,_1,_2,_3,_4,_5,_6,_7,_8,_9
	.local	REGCNT,REGLST,F_IMM,F_REG,F_CCR,IMM_CC,REG_CC,CODE
	.local	x
	.local	trace
REGCNT	=	2	;�������郌�W�X�^�̌�
REGLST	reg	d7/a6	;�������郌�W�X�^�̃��W�X�^���X�g
F_IMM	=	0	;CCR���C�~�f�B�G�C�g�ŕԂ��Ƃ�1
F_REG	=	0	;CCR�����W�X�^�ŕԂ��Ƃ�1
F_CCR	=	0	;CCR�����̂܂ܕԂ��Ƃ�1
IMM_CC	=	0	;CCR�ɐݒ肷��C�~�f�B�G�C�g�̒l
REG_CC	reg	d7	;CCR�ɐݒ肷�郌�W�X�^(CCR�����̂܂ܕԂ��Ƃ���d7)
CODE	=	0	;�X�^�b�N�Ƀf�[�^���o�͂���I�y�R�[�h
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
	.fail	1	;exit�}�N���̈�������������
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
;	�@�\
;		�E�X�^�b�N�̃p�����[�^�̃A�h���X�����߂܂��B
;
;	����
;		areg	�A�h���X���W�X�^
;
;	�⑫
;		�eFE�t�@���N�V�����R�[���ɕ��򂵂�����Ŏw�肵�ĉ������B
;		SP���ω����Ă���Ɛ���ɋ@�\���܂���B
;		���̂��߁A�����I�ɃA�h���X���W�X�^��A6�̂ݎw��\�ł��B
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
;FE�t�@���N�V�����R�[���W�����v�e�[�u��
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
;����`��FE�t�@���N�V�����R�[��
fe_undefined::
	exit

;----------------------------------------------------------------
;$FE00	__LMUL
;	4�o�C�g�����������ǂ����̏�Z�����܂��B
;<d0.l:��搔
;<d1.l:�搔
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[)
fe_lmul::
	muls.l	d1,d0
	svs.b	d7
	neg.b	d7
	exit	D7

;----------------------------------------------------------------
;$FE01	__LDIV
;	4�o�C�g�����������ǂ����̏��Z�����܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����
;>c-flag:cs=�G���[(������0)
fe_ldiv::
	tst.l	d1
	beq	@f
	divs.l	d1,d0
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE02	__LMOD
;	4�o�C�g�����������ǂ����̏��Z�̏�]���v�Z���܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����
;>c-flag:cs=�G���[(������0)
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
;	4�o�C�g�����Ȃ������ǂ����̏�Z�����܂��B
;<d0.l:��搔
;<d1.l:�搔
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[)
fe_umul::
	mulu.l	d1,d0
	svs.b	d7
	neg.b	d7
	exit	D7

;----------------------------------------------------------------
;$FE05	__UDIV
;	4�o�C�g�����Ȃ������ǂ����̏��Z�����܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����
;>c-flag:cs=�G���[(������0)
fe_udiv::
	tst.l	d1
	beq	@f
	divu.l	d1,d0
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE06	__UMOD
;	4�o�C�g�����Ȃ������ǂ����̏��Z�̏�]���v�Z���܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����
;>c-flag:cs=�G���[(������0)
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
;	4�o�C�g�����Ȃ������ǂ����̏�Z�����܂��B
;<d0.l:��搔
;<d1.l:�搔
;>d0.l:���Z���ʂ̏��4�o�C�g
;>d1.l:���Z���ʂ̉���4�o�C�g
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
;	4�o�C�g�����Ȃ������ǂ����̏��Z�����܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����(��)
;>d1.l:���Z����(��])
;>c-flag:cs=�G���[(������0)
fe_idiv::
	tst.l	d1
	beq	@f
	divul.l	d1,d1:d0
	exit	_

@@:	exit	C

;----------------------------------------------------------------
;$FE0C	__RANDOMIZE
;	-32768����32767�܂ł͈̔͂ŗ����̂��Ƃ��Z�b�g���܂��B
;<d0.l:4�o�C�g����������
;	�����̒l���������Ȃ��ꍇ�A�����͏���������܂���B
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
;	0����65535�܂ł͈̔͂ŗ����̂��Ƃ��Z�b�g���܂��B
;<d0.l:4�o�C�g����������
;	�����̒l���������Ȃ��ꍇ�A�����͏���������܂���B
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
;	4�o�C�g�����������̗�����Ԃ��܂��B
;>d0.l:4�o�C�g����������(0�ȏ�32767�ȓ�)
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
;	�������4�o�C�g�����������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g����������
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
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
	movea.w	d7,a6			;0=��,���̑�=��
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
;��
	tst.l	d0
	bmi	9f
	exit	_

;���l�̋L�q�@����������
6:	subq.w	#1,a0
	exit	C,N

;��
7:	neg.l	d0
		tst.l	d0
	bgt	9f
	exit	_

;�I�[�o�[�t���[
8:	subq.w	#1,a0
9:	exit	C,V

;----------------------------------------------------------------
;$FE11	__LTOS
;	4�o�C�g�����������𕶎���ɕϊ����܂��B
;<d0.l:4�o�C�g����������
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
fe_ltos::
	tst.l	d0
	beq	8f
	movem.l	d0-d1,-(sp)		;�t���O�ۑ�
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
;	16�i����\���������4�o�C�g�����Ȃ������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g�����Ȃ�����
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
fe_stoh::
	bsr	stoh
	exit	D7

;16�i����\���������4�o�C�g�����Ȃ������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g�����Ȃ�����
;>d7.b:CCR
;>z-flag:ne=�G���[
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
;	4�o�C�g�����Ȃ�������16�i���\���̕�����ɕϊ����܂��B
;<d0.l:4�o�C�g�����Ȃ�����
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
fe_htos::
	tst.l	d0
	beq	8f
	move.l	d1,-(sp)		;d0�͌��ɖ߂�̂ŕی삷��K�v���Ȃ�
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
;	8�i����\���������4�o�C�g�����Ȃ������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g�����Ȃ�����
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
fe_stoo::
	bsr	stoo
	exit	D7

;8�i����\���������4�o�C�g�����Ȃ������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g�����Ȃ�����
;>d7.b:CCR
;>z-flag:ne=�G���[
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
;	4�o�C�g�����Ȃ�������8�i���\���̕�����ɕϊ����܂��B
;<d0.l:4�o�C�g�����Ȃ�����
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
fe_otos::
	tst.l	d0
	beq	8f
	move.l	d1,-(sp)		;d0�͌��ɖ߂�̂ŕی삷��K�v���Ȃ�
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
;	2�i����\���������4�o�C�g�����Ȃ������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g�����Ȃ�����
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
fe_stob::
	bsr	stob
	exit	D7

;2�i����\���������4�o�C�g�����Ȃ������ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g�����Ȃ�����
;>d7.b:CCR
;>z-flag:ne=�G���[
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
;	4�o�C�g�����Ȃ�������2�i���\���̕�����ɕϊ����܂��B
;<d0.l:4�o�C�g�����Ȃ�����
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
fe_btos::
	tst.l	d0
	beq	8f
	move.l	d1,-(sp)		;d0�͌��ɖ߂�̂ŕی삷��K�v���Ȃ�
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
;	4�o�C�g�����������𕶎���ɕϊ����܂��B
;<d0.l:4�o�C�g����������
;<d1.l:����
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;<(a0):�ϊ����ꂽ������
fe_iusing::
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	tst.l	d0
	beq	6f
	lea.l	9f(pc),a6
	bmi	7f
;��
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

;��
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
;	4�o�C�g������������8�o�C�g���������_���ɕϊ����܂��B
;<d0.l:4�o�C�g����������
;>d0-d1:�ϊ����ꂽ8�o�C�g���������_��
fe_ltod::
	fmove.l	d0,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE1B	__DTOL
;	8�o�C�g���������_����4�o�C�g�����������ɕϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;>d0.l:�ϊ����ꂽ4�o�C�g����������
;>c-flag:cs=�G���[(�ϊ����ʂ�4�o�C�g�����������̒l�͈̔͂𒴂���)
;	���������͐؂�̂Ă��܂��B
;	4�o�C�g�����������̒l�͎��͈̔͂ł��B
;		-2147483648�`+2147483647
fe_dtol::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fintrz.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g������������4�o�C�g���������_���ɕϊ����܂��B
;<d0.l:4�o�C�g����������
;<d0.l:�ϊ����ꂽ4�o�C�g���������_��
fe_ltof::
	fmove.l	d0,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE1D	__FTOL
;	4�o�C�g���������_����4�o�C�g�����������ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:�ϊ����ꂽ4�o�C�g����������
;>c-flag:cs=�G���[(�ϊ����ʂ�4�o�C�g�����������̒l�͈̔͂𒴂���)
;	���������͐؂�̂Ă��܂��B
;	4�o�C�g�����������̒l�͎��͈̔͂ł��B
;		-2147483648�`+2147483647
fe_ftol::
	fmove.l	#$00000000,fpsr
	fintrz.s	d0,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g���������_����8�o�C�g���������_���ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;>d0-d1:�ϊ����ꂽ8�o�C�g���������_��
fe_ftod::
	fmove.s	d0,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE1F	__DTOF
;	8�o�C�g���������_����4�o�C�g���������_���ɕϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;>d0.l:�ϊ����ꂽ4�o�C�g���������_��
;>c-flag:cs=�G���[(������4�o�C�g���������_���ŕ\���ł��Ȃ�)
fe_dtof::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	�������8�o�C�g���������_���ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0-d1:�ϊ����ꂽ8�o�C�g���������_��
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
;	������10�i���ȊO�̏ꍇ�A���̐擪�ɂ́A2�i���ł�'&B'�A8�i���ł�'&O'�A
;	16�i���ł�'&H'���K�v�ł��B
;	10�i���̏ꍇ�A�Ԃ�l�Ƃ��Ď��̂��̂��ǉ�����܂��B
;		d2.w	�����t���O
;		d3.l	�����l
;	�����񂪐���(�������y�юw�������Ȃ�)�ŁA����4�o�C�g�����������ŕ\���\�ȏꍇ�A
;	�����t���O��$FFFF�ŁA�����l�ɂ��̒l���͂���܂��B
;	����ȊO�̏ꍇ�͐����t���O��0�ƂȂ�܂��B
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

2:	moveq.l	#0,d2			;�����t���O
	moveq.l	#0,d3
	move.b	(a0)+,d0
	cmp.b	#'H',d0
	beq	3f
	cmp.b	#'B',d0
	beq	4f
	cmp.b	#'O',d0
	beq	5f
	subq.w	#1,a0			;�����i�͖߂��Ă��Ȃ�
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
;	8�o�C�g���������_���𕶎���ɕϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;<d2.l:���������̌���
;<d3.l:���������̌���
;<d4.l:�A�g���r���[�g
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
;	�A�g���r���[�g�̓r�b�g0�`6���Z�b�g���邱�Ƃɂ��ȉ��̂悤�Ȑ��l�\�����ł��܂��B
;	�r�b�g0:������'*'�Ńp�b�e�B���O���܂��B
;	�r�b�g1:'\'��擪�ɕt�����܂��B
;	�r�b�g2:����������3�����Ƃ�','�ŋ�؂�܂��B
;	�r�b�g3:�w���`���ŕ\�����܂��B
;	�r�b�g4:�����̏ꍇ'+'��擪�ɕt�����܂��B
;	�r�b�g5:�����̏ꍇ'+'���A�����̏ꍇ'-'���Ō���ɕt�����܂��B
;	�r�b�g6:�����̏ꍇ' '���A�����̏ꍇ'-'���Ō���ɕt�����܂��B
fe_using::
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	bsr	using
	exit

;----------------------------------------------------------------
;using
;���������_���𕶎���ɕϊ�����
;<fp0:���������_��(#INF��#NAN�͕s��)
;<d2.l:�������̌���(�����͕s��,�A�g���r���[�g�Ŏw�肵�Ȃ����蕉�������܂ތ���,
;	�w���`�����w�肵�Ȃ��������؂�Ȃ���Ή����ł��͂ݏo��)
;<d3.l:�������̌���(�����͕s��,0�ł������_������,-1�̂Ƃ������_�������Ȃ�)
;<d4.l:�A�g���r���[�g
;	bit0	�������]���Ă�����'*'�Ŗ��߂�(�������̌����Ɋ܂܂��,�w���`���ł͖���)
;	bit1	�擪��'\'��t����(�������̌����Ɋ܂܂��,�w���`���ł͖���,�����Ɛ����̊Ԃɓ���)
;	bit2	��������3������','�ŋ�؂�(�������̌����Ɋ܂܂��,�w���`���ł͖���)
;	bit3	�w���`��(�������̌������畄��' 'or'-'�������������̈ʒu�ɏ����_��u��)
;	bit4	�擪�ɐ��̂Ƃ�'+',���̂Ƃ�'-'��t����(�������̌����Ɋ܂܂�Ȃ�)
;	bit5	�����ɐ��̂Ƃ�'+',���̂Ƃ�'-'��t����(�������̌����Ɋ܂܂�Ȃ�)
;	bit6	�����ɐ��̂Ƃ�' ',���̂Ƃ�'-'��t����(�������̌����Ɋ܂܂�Ȃ�)
;<a0.l:�o�b�t�@�̐擪
;>(a0):������
;>a0.l:������̖�����0�̈ʒu
;*a0,?d0-d4/d7/fp0
using:
	movem.l	d5-d6,-(sp)
;�������̌����̒���
	tst.l	d2
	bgt	@f
	moveq.l	#1,d2			;�������͏��Ȃ��Ƃ�1���K�v
@@:
;�w���`�����ǂ����ŕ���
	btst.l	#3,d4
	bne	usingExp		;�w���`��
;�w���`���ł͂Ȃ��Ƃ�
usingNotExp:
;�������̌����̒���
	cmp.l	#-1,d3
	bge	@f
	moveq.l	#-1,d3			;�w���`���łȂ��Ƃ��������̌�����-1�ȏ�
@@:
;10�i���K��
	bsr	dexp
;������������؂�悤�Ɍ����𒲐�����
	cmp.l	d2,d0
	blt	@f
	move.l	d0,d2
@@:
;�����̃X�y�[�X����������
	movea.l	a0,a6			;�o�b�t�@�̐擪
;<a6.l:�o�b�t�@�̐擪
	move.l	d2,d5			;�������̌���(1�ȏ�)
	move.l	d0,d2
	sub.l	d0,d5			;�X�y�[�X�̌���
	beq	2f
	move.l	d5,d0			;�X�y�[�X�̌���
1:	move.b	#' ',(a0)+
	subq.l	#1,d0
	bne	1b
2:
;<d5.l:�X�y�[�X�̌���
;������ɕϊ�����
	move.l	d2,d6			;�������̌���(1�ȏ�)
	add.l	d3,d6			;�X�y�[�X����������(1�ȏ�)
	tst.l	d3
	bpl	@f
	addq.l	#1,d6			;�����_�ȉ��̌�����-1�������Ƃ���0�Ƃ݂Ȃ�
@@:
;<d6.l:�X�y�[�X����������
	move.l	d6,d0			;�X�y�[�X����������(1�ȏ�)
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
	add.b	#'0',d7			;'0'�`'9'�ɂ���
	fsub.x	fp1,fp0
	move.b	d7,(a0)+
	subq.l	#1,d0
	bne	1b
2:
;�l�̌ܓ�
	fcmp.s	#0f0.5,fp0
	fblt	3f			;���̌���5�����Ȃ̂Ő؂�̂Ă�
;�J��グ��
	move.l	d6,d0			;�X�y�[�X����������(1�ȏ�)
1:	addq.b	#1,-(a0)		;�J��オ��
	cmpi.b	#'9',(a0)
	bls	3f			;��̈ʂɔ[�܂����̂ŏI���
	move.b	#'0',(a0)		;��̈ʂ���ꂽ
	subq.l	#1,d0
	bne	1b
2:
;�ŏ�ʂ���J��オ����
	addq.l	#1,d2			;�������̌�����1������
	subq.l	#1,d5			;�X�y�[�X�̌��������炷
	bcc	@f			;�X�y�[�X��������
	move.b	#'0',(a6,d6.l)		;�X�y�[�X���Ȃ������̂ŉE�ɂ��炷
	lea.l	(1,a6),a0
	moveq.l	#0,d5
@@:	move.b	#'1',-(a0)		;�擪��1������
	addq.l	#1,d6			;�X�y�[�X������������1������
3:
;������̖�����0(�ԕ�)��u��
	lea.l	(a6,d5.l),a0		;�����̐擪
	clr.b	(a0,d6.l)		;������0����������(������V�t�g�̂Ƃ��̔ԕ��ɕK�v)
;�����_������(�����_�ȉ��̌�����0�ł������,-1�̂Ƃ��͓���Ȃ�)
	tst.l	d3			;�����_�ȉ��̌���
	bmi	@f			;-1�̂Ƃ��͏����_�����Ȃ�
	adda.l	d2,a0			;�����_�̈ʒu
	bsr	usingShiftRight		;�E�ɂ��炷
	move.b	#'.',(a0)		;�����_������
	addq.l	#1,d6			;�X�y�[�X������������1������
@@:
;��������3������','�ŋ�؂�
	btst.l	#2,d4
	beq	3f
	move.l	d2,d0			;�������̌���
;�ȍ~�ł�d2�͕s�v
	bra	2f

1:	lea.l	(a6,d5.l),a0		;�����̐擪
	subq.l	#1,d5			;�X�y�[�X�̌�����1���炷
	bcc	4f
;�X�y�[�X���Ȃ��̂ŉE�ɂ��炷
	moveq.l	#0,d5
	adda.l	d0,a0			;','������ʒu
	bsr	usingShiftRight		;�E�ɂ��炷
	bra	5f

;�X�y�[�X������̂ō��ɂ��炷
;<d0.l:','�̍����̐����̌���=���炷�͈͂̌���
;<a0.l:�����̐擪=���炷�͈͂̐擪
4:	bsr	usingShiftLeft		;���ɂ��炷
;<a0.l:���炵�Ăł������Ԃ̈ʒu
5:	move.b	#',',(a0)
;;;	addq.l	#1,d2			;�������̌�����1������
	addq.l	#1,d6			;�X�y�[�X������������1������
2:	subq.l	#3,d0
	bgt	1b
3:
;�擪��'\'��t����
	btst.l	#1,d4
	beq	2f
	subq.l	#1,d5
	bcc	1f
	moveq.l	#0,d5
	movea.l	a6,a0
	bsr	usingShiftRight
1:	move.b	#'\',(a6,d5.l)
;;;	addq.l	#1,d2			;�������̌�����1������
	addq.l	#1,d6			;�X�y�[�X������������1������
2:
;�擪�ɐ��̂Ƃ�'+',���̂Ƃ�'-'��t����
	btst.l	#4,d4
	beq	2f
	lea.l	(a6,d5.l),a0		;�X�y�[�X�̒���
	bsr	usingShiftRight		;�������Ɍ��Ԃ��󂯂�
	addq.l	#1,d6			;�X�y�[�X������������1������
	moveq.l	#'+',d0			;���̂Ƃ�'+'
	add.l	d1,d0
	add.l	d1,d0			;���̂Ƃ�'-'
	move.b	d0,(a0)
	bra	3f
2:
;�����ɐ��̂Ƃ�'+',���̂Ƃ�'-'��t����
	btst.l	#5,d4
	beq	2f
	lea.l	(a6,d5.l),a0		;�X�y�[�X�̒���
	adda.l	d6,a0			;������0�̈ʒu
	moveq.l	#'+',d0			;���̂Ƃ�'+'
	add.l	d1,d0
	add.l	d1,d0			;���̂Ƃ�'-'
	move.b	d0,(a0)+
	clr.b	(a0)
	addq.l	#1,d6			;�X�y�[�X������������1������
	bra	3f
2:
;�����ɐ��̂Ƃ�' ',���̂Ƃ�'-'��t����
	btst.l	#6,d4
	beq	2f
	lea.l	(a6,d5.l),a0		;�X�y�[�X�̒���
	adda.l	d6,a0			;������0�̈ʒu
	tst.l	d1
	sne.b	d0
	and.b	#'-'-' ',d0
	add.b	#' ',d0
	move.b	d0,(a0)+
	clr.b	(a0)
	addq.l	#1,d6			;�X�y�[�X������������1������
	bra	3f
2:
;��������t����
	tst.l	d1
	beq	2f			;����
	subq.l	#1,d5
	bcc	1f
	moveq.l	#0,d5
	movea.l	a6,a0
	bsr	usingShiftRight
1:	move.b	#'-',(a6,d5.l)
;;;	addq.l	#1,d2			;�������̌�����1������
	addq.l	#1,d6			;�X�y�[�X������������1������
2:
;�����I���
3:
;�������]���Ă�����'*'�Ŗ��߂�
	btst.l	#0,d4
	beq	2f
	tst.l	d5
	beq	2f			;�X�y�[�X���Ȃ�
	movea.l	a6,a0			;�o�b�t�@�̐擪
;;;	add.l	d5,d2			;�����_�̍����̌���
	add.l	d5,d6			;�X�y�[�X����������
1:	move.b	#'*',(a0)+
	subq.l	#1,d5
	bne	1b
2:	lea.l	(a6,d5.l),a0		;'*'�Ŗ��߂Ȃ������Ƃ��K�v
	adda.l	d6,a0
	clr.b	(a0)			;������̖���
	movem.l	(sp)+,d5-d6
	rts


;�w���`���̂Ƃ�
usingExp:
;�������̌����̒���
	tst.l	d3
	bge	@f
	moveq.l	#0,d3			;�w���`���̂Ƃ��������̌�����0�ȏ�
@@:
;�����̊m�F
;>d5.l:
;	bit0�`7		�擪�ɐ��̂Ƃ��t���镶��
;	bit8�`15	�����ɐ��̂Ƃ��t���镶��
;	bit16�`23	�擪�ɕ��̂Ƃ��t���镶��
;	bit24�`31	�����ɕ��̂Ƃ��t���镶��
	move.l	#('-'<<16)+('+'<<0),d5	;�擪�ɐ��̂Ƃ�'+',���̂Ƃ�'-'��t����
;0,'-',0,'+'
	btst.l	#4,d4			;bit4���e�X�g
	bne	@f
	lsl.l	#8,d5			;�����ɐ��̂Ƃ�'+',���̂Ƃ�'-'��t����
;'-',0,'+',0
	btst.l	#5,d4			;bit5���e�X�g
	bne	@f
	move.w	#' '<<8,d5		;�����ɐ��̂Ƃ�' ',���̂Ƃ�'-'��t����
;'-',0,' ',0
	btst.l	#6,d4			;bit6���e�X�g
	bne	@f
	lsr.l	#8,d5			;�擪�ɐ��̂Ƃ�' ',���̂Ƃ�'-'��t����
;0,'-',0,' '
@@:
;>d5.w:
;	bit0�`7		�擪�ɕt���镶��
;	bit8�`15	�����ɕt���镶��
;�����̒���
	and.b	#%01110000,d4
	bne	@f			;�����̎w�肪����Ƃ��͕����̌����͊܂܂�Ă��Ȃ�
	subq.l	#1,d2			;�����̌���������
	bgt	@f
	moveq.l	#1,d2			;�������͍Œ�1���K�v
@@:
	move.l	d2,d6			;�������̌���
;�����̊m�F
	ftst.x	fp0
	fbge	@f
	fneg.x	fp0,fp0
	swap.w	d5
@@:
;�擪�̕���
	tst.b	d5
	beq	@f
	move.b	d5,(a0)+
@@:	lsr.w	#8,d5
;������ɕϊ�
	add.l	d3,d2			;�S�̂̌���
	bsr	ecvt			;d0-d2/d7/a6��j�󂷂�,a0�͖�����0�̈ʒu
;<d0.l:10�i�w����(���������_����0�̂Ƃ���1)
;<d1.l:�����ł͏��0
;<d3.l:�������̌���
;<d5.b:�����ɕt���镶��
;<d6.l:�������̌���
;<a0.l:������0�̃A�h���X
	suba.l	d3,a0			;�����_������ʒu
	movea.l	a0,a6
	suba.l	d6,a6			;�����̐擪
;<a6.l:�����̐擪
	bsr	usingShiftRight		;�E�ɂ��炷
	move.b	#'.',(a0)+
	adda.l	d3,a0			;�����̖���
;0�T�v���X(���������_����0�̂Ƃ������K�v)
	cmpi.b	#'0',(a6)
	bne	2f
	move.l	d6,d1
	subq.l	#1,d1
1:	move.b	#' ',(a6)+
	subq.l	#1,d1
	bne	1b
2:
;�w����������
	move.b	#'E',(a0)+
	moveq.l	#'+',d1
	sub.l	d6,d0			;�w����
	bpl	@f
	moveq.l	#'-',d1
	neg.l	d0
@@:	move.b	d1,(a0)+
;<d0.l:�w��(����)
	cmp.l	#1000,d0
	blo	2f
	move.l	#1000,d1
	moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
	sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
	move.b	d7,(a0)+
;�w����10�i3���ŏ���
;<d0.l:�w��(����)
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
;�����̕���
	tst.b	d5
	beq	@f
	move.b	d5,(a0)+
@@:
	clr.b	(a0)			;������̖���
	movem.l	(sp)+,d5-d6
	rts


;��������E��1�����炷
;<a0.l:���炷�͈͂̐擪(������0�܂ł��炷)
;>a0.l:�ω����Ȃ�
usingShiftRight:
	move.l	a0,-(sp)
@@:	tst.b	(a0)+
	bne	@b
@@:	move.b	-(a0),(1,a0)
	cmpa.l	(sp),a0
	bne	@b
	addq.l	#4,sp
	rts

;�����������1�����炷
;<d0.l:���炷�͈͂̌���
;<a0.l:���炷�͈͂̐擪(d0�����炷)
;>a0.l:���炵�Ăł������Ԃ̈ʒu
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
;	�������8�o�C�g���������_���ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0-d1:�ϊ����ꂽ8�o�C�g���������_��
;>d2.w:�����t���O
;>d3.l:�����l
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
;	�����񂪐���(�������y�юw�������Ȃ�)�ŁA����4�o�C�g�����������ŕ\���\�ȏꍇ�A
;	�����t���O��$FFFF�ŁA�����l�ɂ��̒l���͂���܂��B
;	����ȊO�̏ꍇ�͐����t���O��0�ƂȂ�܂��B

__	=	-128	;���̑�
BL	=	-6	;' '|$09
SH	=	-5	;'#'
DO	=	-4	;'.'
EX	=	-3	;'E'|'e'
PL	=	-2	;'+'
MI	=	-1	;'-'

;�������������ރR�[�h�e�[�u��
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
;�G���[
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
	or.l	#$7FF00000,d0		;�����͂��̂܂�
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
	move.l	#$7FFFFFFF,d0		;�����͖���
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
	lea.l	table(pc),a6		;�������p�����R�[�h���ރe�[�u��
	moveq.l	#0,d0			;bit31:�������̕���(0=��,1=��)
					;bit15�`0:�����_�ȉ��̌���(�_�E���J�E���g)
	moveq.l	#0,d1			;�w����
	moveq.l	#0,d7			;bit31:�w�����̕���(0=��,1=��)
					;bit15�`0:���[�N
	fmove.s	#0f0,fp0
blank:
	move.b	(a0)+,d7
	move.b	(a6,d7.w),d7
	bpl	int			;'0'�`'9'
	addq.b	#-BL,d7
	beq	blank			;�X�y�[�X�܂��̓^�u
	subq.b	#-(BL-PL),d7
	bpl	sign			;����
	addq.b	#PL-DO,d7
	beq	frac			;'.'
	addq.b	#DO-SH,d7
	beq	sharp			;'#'
	bra	err

;����
sign:
	move.b	d7,d0			;0=��,1=��
	ror.l	#1,d0
;
	move.b	(a0)+,d7		;�����̒���̕���
	move.b	(a6,d7.w),d7
	bpl	int			;'0'�`'9'
	addq.b	#-DO,d7
	beq	frac			;'.'
	addq.b	#DO-SH,d7
	beq	sharp			;'#'
	bra	err

;'0'�`'9'(������)
1:	fmul.s	#0f10,fp0
;<d7.b:��������1���ڂ̒l
int:
	fadd.l	d7,fp0
	move.b	(a0)+,d7		;���̕���
	move.b	(a6,d7.w),d7
	bpl	1b			;'0'�`'9'
	addq.b	#-EX,d7
	beq	exp0			;'E'�܂���'e'
	addq.b	#EX-DO,d7
	bne	intChk0			;'0'�`'9'|'E'|'e'|'.'�ȊO
;'.'
	move.b	(a0)+,d7		;���̕���
	move.b	(a6,d7.w),d7
	bmi	2f
1:	subq.w	#1,d0			;�����_�ȉ��̌���(�_�E���J�E���g)
	fmul.s	#0f10,fp0
	fadd.l	d7,fp0
frac:
	move.b	(a0)+,d7		;���̕���
	move.b	(a6,d7.w),d7
	bpl	1b			;'0'�`'9'
2:
;�������I���
;������t����
	tst.l	d0
	bpl	@f
	fneg.x	fp0,fp0
@@:
;<d7.b:�������̎��̕����̕��ރR�[�h
	addq.b	#-EX,d7
	bne	expChk			;�����_�𓮂����ďI���
	bra	exp

exp0:
;������t����
	tst.l	d0
	bpl	@f
	fneg.x	fp0,fp0
@@:
;'E'�܂���'e'
exp:
	move.b	(a0)+,d7		;'E'�̒���̕���
	move.b	(a6,d7.w),d7
	bgt	expHead			;'1'�`'9'
	beq	expZrSp			;'0'
	addq.b	#-PL,d7
	bmi	err			;�w�����̐擪�������ł������ł��Ȃ�
;�w�����̕���
	ror.l	#1,d7
;
	move.b	(a0)+,d7		;�w�����̕����̒���̕���
	move.b	(a6,d7.w),d7
	bgt	expHead			;'1'�`'9'
	bmi	err			;�w�����̕����̒��オ�����łȂ�
;�w�����̐擪��0
expZrSp:
	move.b	(a0)+,d7		;'0'�̎��̕���
	move.b	(a6,d7.w),d7
	beq	expZrSp			;'0'���X�L�b�v����
	bmi	expChk			;�w������0������
;�w�����̐擪��0�ȊO�̐�������
expHead:
	move.w	d7,d1
	move.b	(a0)+,d7		;�w�����̏ォ��2����
	move.b	(a6,d7.w),d7
	bmi	expEnd			;'0'�`'9'�ȊO
	mulu.w	#10,d1
	add.w	d7,d1
	move.b	(a0)+,d7		;�w�����̏ォ��3����
	move.b	(a6,d7.w),d7
	bmi	expEnd			;'0'�`'9'�ȊO
	mulu.w	#10,d1
	add.w	d7,d1
	move.b	(a0)+,d7		;�w�����̏ォ��4����
	move.b	(a6,d7.w),d7
	bpl	expErr			;�w������4���ȏ�Ȃ�I�[�o�[�t���[�܂��̓A���_�[�t���[
;�w�����I���
expEnd:
	tst.l	d7
	bpl	@f			;�w�����͐�
	neg.w	d1			;�w�����͕�
@@:	add.w	d1,d0			;�����_�ȉ��̌��������炷
	cmp.w	#512,d0
	bge	expOver			;512��ȏ����菜��
	cmp.w	#-512,d0
	ble	expUnder		;-512��ȉ�����菜��
;�w������0�łȂ���Ε␳����
;<d4.w:�w����-�����_�ȉ��̌���
expChk:
	tst.w	d0
	beq	intChk			;�w������0�Ȃ̂Ő����`�F�b�N��
	bmi	expLeft			;�����_�����ւ��炷
;�����_���E�ɂ��炷
	moveq.l	#$0F,d7
	and.w	d0,d7
	mulu.w	#12,d7
	fmul.x	(digit_1,pc,d7.w),fp0
	lsr.w	#4,d0
	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+16,fp0		;+16��
@@:	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+32,fp0		;+32��
@@:	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+64,fp0		;+64��
@@:	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E+128,fp0		;+128��
@@:	beq	intChk			;�����`�F�b�N��
	fmul.d	#0f1E+256,fp0		;+256��
	bra	intChk			;�����`�F�b�N��

;10�̐��̃x�L�̃e�[�u��
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

;10�̕��̃x�L�̃e�[�u��
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

;�����_�����ɂ��炷
expLeft:
	neg.w	d0
	moveq.l	#$0F,d7
	and.w	d0,d7
	mulu.w	#12,d7
	fmul.x	(digit_2,pc,d7.w),fp0
	lsr.w	#4,d0
	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-16,fp0		;-16��
@@:	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-32,fp0		;-32��
@@:	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-64,fp0		;-64��
@@:	beq	intChk			;�����`�F�b�N��
	lsr.w	#1,d0
	bcc	@f
	fmul.d	#0f1E-128,fp0		;-128��
@@:	beq	intChk			;�����`�F�b�N��
	fmul.d	#0f1E-256,fp0		;-256��
	bra	intChk

intChk0:
;������t����
	tst.l	d0
	bpl	@f
	fneg.x	fp0,fp0
@@:
;�����`�F�b�N
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
;�ԋp�l�����
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

;�w�������͈͊O
expErr:
	tst.l	d7			;�w�����̕���������
	bpl	expOver			;�I�[�o�[�t���[
;�A���_�[�t���[
expUnder:
	subq.l	#1,a0
	moveq.l	#0,d0			;�����͕t���Ȃ�
	moveq.l	#0,d1
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0|0|0|0|C,d7
	rts

;�I�[�o�[�t���[
expOver:
	subq.l	#1,a0
	ftst.x	fp0			;��������0�̂Ƃ��̓G���[�ɂ��Ȃ�
	fbeq	@f
	clr.w	d0
	or.l	#$7FF00000,d0		;������t����
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
;	8�o�C�g���������_���𕶎���ɕϊ����܂��B
;	d0,d1�͉��܂��B
;<d0-d1:8�o�C�g���������_��
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
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
;���������_����S�̂̌������w�肵�����������_�\���܂��͎w���\���̕�����ɕϊ�����
;<a0.l:�o�b�t�@�̐擪
;<fp0:���������_��(#INF��#NAN�͕s��)
;>(a0):�ϊ����ꂽ������
;>a0.l:������̖�����0�̃A�h���X
;	���̒l�̏ꍇ�͕�����̐擪�Ƀ}�C�i�X�L��('-')���t�������
;	d2�̌����ŕ\���ł��Ȃ��ꍇ�͎w���\���̕�����ɕϊ�����
;*a0,?d0-d2/fp0
dtos:
	moveq.l	#14,d2
	ftst.x	fp0
	fbeq	9f			;���������_����0
	fbgt	@f
	move.b	#'-',(a0)+
@@:	clr.b	(a0)+			;�o�b�t�@�̐擪�܂���'-'�̒����0(�ԕ�)
	bsr	ecvt
	movea.l	a0,a6			;�Ō�̌��̎��̈ʒu
		suba.l	d2,a0
@@:	cmp.b	#'0',-(a6)		;0�̂Ƃ��͔ԕ��Ŏ~�܂�
	beq	@b
;<a6.l:'0'�łȂ��Ō�̌��̈ʒu�܂��͔ԕ��̈ʒu
	cmpa.l	a0,a6
	blo	7f			;0������(�������K�v�Ȃ̂�d1���󂷑O�ɔ�Ԃ���)
	addq.l	#1,a6
;<a6.l:'0'�łȂ��Ō�̌��̎��̈ʒu
	move.l	a6,d1			;0�łȂ��Ō�̌��̎��̈ʒu
		sub.l	a0,d1		;���ʂ�0������������
;     ������ d1 ������
;    a0              a6
;    ��              ��
;     ������������ d2 ������������      d0
; �|���w�w�w�w�w�w�w�w�O�O�O�O�O�O�~�P�O
;    ��
;�|���E���{
;    d0
	cmp.l	d2,d0
	bgt	1f			;�w�����傫������(�w���`��)
	tst.l	d0
	bgt	4f			;�r���ɏ����_������(������.������)
;�w������0�ȉ�(�w���\���łȂ����0.�ɑ���)
	neg.l	d0			;0.�̉E����0�̐�
		add.l	d0,d1		;0.�̉E���̌���
;    �������� d1 ��������
;       a0              a6
;       ��              ��
;    ������������ d2 ������������
;�O�D�O�O�w�w�w�w�w�w�w�w�O�O�O�O�O�O
;  �� d0 ��
	cmp.l	d2,d1
	ble	5f			;�擪��0.00�c��ǉ�����(�w���͕s�v)
;�w��������������(�w���`��)
;<d1.l:�L���Ȍ���
	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	sub.l	d0,d1			;0�łȂ������̌���
		adda.l	d1,a0		;�Ō�̌��̉E��
	subq.l	#1,d1
	bne	@f
	subq.l	#1,a0			;'.E'�̂Ƃ�'E'�����ɂ���
@@:	move.b	#'E',(a0)+
		move.b	#'-',(a0)+
	bra	2f

;�w�����傫������(�w���`��)
;<d1.l:�L���Ȍ���
1:	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	adda.l	d1,a0			;�Ō�̌��̉E��
		subq.l	#1,d1
	bne	@f
	subq.l	#1,a0			;'.E'�̂Ƃ�'E'�����ɂ���
@@:		move.b	#'E',(a0)+
	move.b	#'+',(a0)+
;�w����10�i4�`3���ŏ���
;<d0.l:�w��(����)
2:	subq.l	#1,d0			;0.1�ȏ�1������1�ȏ�10�����ɂ���
	cmp.l	#1000,d0
	blo	2f
	move.l	#1000,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
;�w����10�i3���ŏ���
;<d0.l:�w��(����)
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

;������������
;<d0.l:�������̌���(��d2)
;<d1.l:������0������������(��d2,�����_���܂܂Ȃ�)
4:	sub.l	d0,d1			;�������̌���
	ble	3f			;�������̂�
;�r���ɏ����_������(������.������)
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	move.b	#'.',(-1,a0)
		adda.l	d1,a0		;�Ō�̌��̉E��
	clr.b	(a0)
	rts

;�������̂�
;<d0.l:����(��d2)
3:
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	clr.b	-(a0)
	rts

;�擪��0.00�c��ǉ�����(�w���͕s�v)
;    ���������� d1 ����������
;           a0              a6
;           ��              ��
;            ������������ d2 ������������
;�O�D�O�O�O�O�w�w�w�w�w�w�w�w�O�O�O�O�O�O�~�P�O
;    �� d0 ��
;<d0.l:0.�̉E����0�̐�
;<d1.l:0.�̉E����0�łȂ��Ō�̌��܂ł̌���
5:	sub.l	d0,d1			;0�łȂ������̌���
;    �� d0 �������� d1 ������
;           a0              a6
;           ��              ��
;            ������������ d2 ������������
;�O�D�O�O�O�O�w�w�w�w�w�w�w�w�O�O�O�O�O�O
;          �O�D�O�O�O�O�w�w�w�w�w�w�w�w�O
	lea.l	(1,a6,d0.l),a0
@@:	move.b	-(a6),(1,a6,d0.l)	;�E�ɂ��炷
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

;���ׂĂ̌���0������
;<d1.l:����(0=��,1=��)
;<a0.l:�ԕ��̎��̈ʒu
7:	subq.l	#1,a0			;�ԕ��̈ʒu
		suba.l	d1,a0		;�������̕��߂��ăo�b�t�@�̐擪��
;���������_����0�̂Ƃ�
9:	move.b	#'0',(a0)+
		clr.b	(a0)
	rts

;----------------------------------------------------------------
;$FE24	__ECVT
;	8�o�C�g���������_����S�̂̌������w�肵�ĕ�����ɕϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;<d2.b:�S�̂̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>d0.l:�����_�̈ʒu
;>d1.l:����(0=��,1=��)
;>(a0):�ϊ����ꂽ������
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
	move.l	a0,-(sp)		;a0��j�󂵂Ȃ�
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
	subq.l	#1,d2			;�����͌���������Ȃ���$00������悤�Ƃ���
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
	move.l	#4,d0			;���4
	exit	d2

;----------------------------------------------------------------
;ecvt
;���������_����S�̂̌������w�肵�����������_�\���̕�����ɕϊ�����
;<d2.l:�S�̂̌���(�����͕s��)
;<a0.l:�o�b�t�@�̐擪
;<fp0:���������_��(#INF��#NAN�͕s��)
;>d0.l:10�i�w����(���������_����0�̂Ƃ���1)
;>d1.l:����(0=��,1=��)
;>(a0):�ϊ����ꂽ������(�����⏬���_�͊܂܂Ȃ�)
;>a0.l:������̖�����0�̃A�h���X
;*d0-d1/a0,?d2/d7/a6/fp0
ecvt:
	bsr	dexp			;d7/a6��j�󂷂�
	ftst.x	fp0
	fbeq	9f			;���������_����0
;�w�肳�ꂽ�����̕�����ɕϊ�����
	move.l	a0,-(sp)		;�o�b�t�@�̐擪
		move.l	d2,-(sp)	;����
	ble	2f
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'�`'9'�ɂ���
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
2:
;�l�̌ܓ�
	fcmp.s	#0f0.5,fp0
	fblt	3f			;���̌���5�����Ȃ̂Ő؂�̂Ă�
;�J��グ��
	move.l	(sp),d2			;����
	ble	2f
1:	addq.b	#1,-(a0)		;�J��オ��
		cmpi.b	#'9',(a0)
	bls	3f			;��̈ʂɔ[�܂����̂ŏI���
		move.b	#'0',(a0)	;��̈ʂ���ꂽ
	subq.l	#1,d2
	bne	1b
2:
;�ŏ�ʂ���J��オ����
	addq.l	#1,d0			;�w������1������
		move.l	(sp),d2		;����
	ble	2f
	move.b	#'1',(a0)+		;�擪��1�ɂ���
	bra	4f
1:	move.b	#'0',(a0)+		;�c���0�ɂ���
4:	subq.l	#1,d2
	bne	1b
2:
;�I���
3:	move.l	(sp)+,d2		;����
		movea.l	(sp)+,a0	;�o�b�t�@�̐擪
	adda.l	d2,a0			;�����̌��̎��̈ʒu
	clr.b	(a0)
	rts

;0�̂Ƃ�
9:	tst.l	d2
	ble	2f
1:	move.b	#'0',(a0)+		;d2+1��0����ׂ�
	subq.l	#1,d2
	bne	1b
2:	moveq.l	#1,d0			;10^1�ɂ���
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;���������_����10�i���K������
;	fp0��(-1)^d1*fp0*10^d0(fp0��0�܂���0.1�ȏ�1����)
;<fp0:���������_��(#INF��#NAN�͕s��)
;>d0.l:10�i�w����
;>d1.l:����(0=��,1=��)
;>fp0:������(0�܂���0.1�ȏ�1����)
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
;<d0.w:2�i�w����+$3FFF(0�`$7FFF)
	tst.w	d0
	beq	dexpZero		;��Βl��0
	sub.w	#$3FFF,d0
	bmi	dexpMinus		;��Βl��1����
;��Βl��1�ȏ�
;<d0.w:2�i�w����(0�`$4000)
dexpPlus:
;2�i�w������log10(2)���|����10�i�w���������߂�(�傫�߂ɏo��)
	mulu.w	#19729,d0		;log10(2)*65536���J��グ������
	clr.w	d0
	swap.w	d0
;<d0.w:10�i�w����(0�`4932,1�����傫�����邱�Ƃ�����)
	move.l	d0,d7
;;;	beq	3f
	lea.l	(dexpMinusTable,pc),a6
1:	lsr.w	#1,d7
	bcc	2f
	fmul.x	(a6),fp0
2:	lea.l	(12,a6),a6
	bne	1b
3:
;10�Ŋ�����0.1�ȏ�1�����ɂ���
	fmul.x	dexpMinusTable,fp0	;0.1
	addq.l	#1,d0
;10�i�w������1�����傫�������Ƃ��������Ȃ肷���Ă���
;�덷�̏C��
	fcmp.x	dexpMinusTable,fp0	;0.1
	fblt	dexpRight		;����������
	fcmp.s	#0f1,fp0
	fbge	dexpLeftOne		;�傫������
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

;��Βl��0
dexpZero:
	fmove.s	#0f0,fp0		;�O�̂���
	moveq.l	#0,d0
	moveq.l	#0,d1
	rts

;��Βl��1����
;<d0.w:2�i�w����(-$3FFF�`-1)
dexpMinus:
	neg.w	d0
;<d0.w:2�i�w�����̕�����ς�������(1�`$3FFF)
;2�i�w�����̕�����ς������̂�log10(2)���|����10�i�w�����̕�����ς������̂����߂�(�傫�߂ɏo��)
	mulu.w	#19729,d0		;log10(2)*65536���J��グ������
	clr.w	d0
	swap.w	d0
;<d0.w:10�i�w�����̕�����ς�������(0�`4931,1�����傫�����邱�Ƃ�����)
	move.l	d0,d7
;;;	beq	3f
	lea.l	(dexpPlusTable,pc),a6
1:	lsr.w	#1,d7
	bcc	2f
	fmul.x	(a6),fp0
2:	lea.l	(12,a6),a6
	bne	1b
3:
;10�i�w������1�����傫�������Ƃ��傫���Ȃ肷���Ă���
;�w�����̕����𔽓]����
	neg.l	d0
;�덷�̏C��
	fcmp.x	dexpMinusTable,fp0	;0.1
	fblt	dexpRightOne		;����������
	fcmp.s	#0f1,fp0
	fbge	dexpLeft		;�傫������
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

;10^(2^n),n=0�`12�̃e�[�u��
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

;10^(-2^n),n=0�`12�̃e�[�u��
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
;10�i���K�����ꂽ���������_���̉��������w�肳�ꂽ�����̕�����ɂ���
;	�w�肳�ꂽ�����̐����̕��тɂȂ�(�����⏬���_�͓���Ȃ�)
;	�w�肳�ꂽ�����̎��̌����l�̌ܓ�����
;	�l�̌ܓ��̌��ʏ����_��1�����ꂽ�Ƃ��A10�i�w������1���₷
;<d0.l:10�i�w����
;<d2.l:����
;<a0.l:��������i�[����A�h���X
;<fp0:���������_��(0�܂���1�ȏ�10����,#INF��#NAN�͕s��)
;>d0.l:10�i�w����
;>(a0):�w�肳�ꂽ�����̕�����('0'�`'9'�̗�)
;	�����_�̈ʒu�͐擪�̐����̉E��
;	�w�肳�ꂽ��������̗̈�͔j�󂵂Ȃ�
;?d7/fp0-fp1
dstr:
	move.l	a0,-(sp)
		move.l	d2,-(sp)
;�w�肳�ꂽ�����̕�����ɕϊ�����
1:	fmul.s	#0f10,fp0		;100�{�ɂ��ăe�[�u���������Ă��悢���A
	fintrz.x	fp0,fp1		;fmul�͏\�������̂ł��̂܂܂ɂ��Ă���
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'�`'9'�ɂ���
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
;�l�̌ܓ�
	fcmp.s	#0f0.5,fp0
	fblt	4f			;���̌���5�����Ȃ̂Ő؂�̂Ă�
;�J��グ��
	move.l	(sp),d2			;����
2:	addq.b	#1,-(a0)		;�J��オ��
		cmpi.b	#'9',(a0)
	bls	4f			;��̈ʂɔ[�܂����̂ŏI���
		move.b	#'0',(a0)	;��̈ʂ���ꂽ
	subq.l	#1,d2
	bne	2b
;�ŏ�ʂ���J��オ����
	move.b	#'1',(a0)+
		move.l	(sp),d2		;����
	subq.l	#1,d2			;����-1
3:	move.b	#'0',(a0)+
		subq.l	#1,d2
	bne	3b
	addq.l	#1,d0			;�ŏ�ʂ���J��オ�����̂Ŏw������1������
;�I���
4:	move.l	(sp)+,d2
		movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;$FE25	__FCVT
;	8�o�C�g���������_���������_�ȉ��̌������w�肵�āA������ɕϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;<d2.b:�����_�ȉ��̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>d0.l:�����_�̈ʒu
;>d1.l:����(0=��,1=��)
;>(a0):�ϊ����ꂽ������
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
	move.l	a0,-(sp)		;a0��j�󂵂Ȃ�
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
@@:	move.l	#'#INF',(a0)+		;��A�h���X�̉\��������
					;�����͌���������Ȃ���$00�Ɏw����t���Č��ǂ͂ݏo��
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;��A�h���X�̉\��������
2:	clr.b	(a0)
	move.l	#4,d0			;���4
	exit	d2

;----------------------------------------------------------------
;fcvt
;���������_�����������̌������w�肵�����������_�\���̕�����ɕϊ�����
;<d2.l:�������̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;<fp0:���������_��
;>d0.l:10�i�w����
;>d1.l:����(0=��,1=��)
;>(a0):�ϊ����ꂽ������(�����⏬���_�͊܂܂Ȃ�)
;	�������͉����ł��W�J����
;	0�ł͂Ȃ�����Βl�����������Ďw�肵���͈͓���0�����Ȃ��Ƃ��k��������ɂȂ�
;	0�̂Ƃ���0.xxxx*10^1�ɂȂ�
;>a0.l:������̖�����0�̃A�h���X
;*a0,?d0-d2/d7/fp0
fcvt:
	bsr	dexp			;d7/a6��j�󂷂�
	ftst.x	fp0
	fbeq	fcvtZero
	tst.l	d0
	blt	4f			;�w��������
;�w������0�ȏ�
	add.l	d0,d2			;�S�̂̌���
;������ɕϊ�����
	move.l	a0,-(sp)
		move.l	d2,-(sp)	;�S�̂̌���
	beq	2f
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'�`'9'�ɂ���
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
2:
;�l�̌ܓ�
	fcmp.s	#0f0.5,fp0
	fblt	3f			;���̌���5�����Ȃ̂Ő؂�̂Ă�
;�J��グ��
	move.l	(sp),d2			;�S�̂̌���
	beq	2f
1:	addq.b	#1,-(a0)		;�J��オ��
		cmpi.b	#'9',(a0)
	bls	3f			;��̈ʂɔ[�܂����̂ŏI���
		move.b	#'0',(a0)	;��̈ʂ���ꂽ
	subq.l	#1,d2
	bne	1b
2:
;�ŏ�ʂ���J��オ����
	move.b	#'1',(a0)+		;�������Ȃ̂Ŗ������ɏ���
		move.l	(sp),d2		;�S�̂̌���(�擪��1���܂܂Ȃ�)
	beq	2f
1:	move.b	#'0',(a0)+
		subq.l	#1,d2
	bne	1b
2:	addq.l	#1,d0			;�ŏ�ʂ���J��オ�����̂Ő�������1��������
		addq.l	#1,(sp)		;��������1��������̂őS�̂̌�����1��������
;�I���
3:	move.l	(sp)+,d2		;�S�̂̌���
		movea.l	(sp)+,a0	;�o�b�t�@�̐擪
	adda.l	d2,a0			;�����̌��̎��̈ʒu
9:	clr.b	(a0)
	rts

;�w��������
4:	add.l	d0,d2			;�c�錅��
;	bmi	9b			;�J��オ���Ă��c��Ȃ�
					;�����ŃW�����v���Ă��܂��ƌJ��オ�邱�Ƃɂ��
					;�w���̕␳���������s���Ȃ��Ȃ�
;������ɕϊ�����
	move.l	a0,-(sp)
		move.l	d2,-(sp)	;�c�錅��
	ble	2f
1:	fmul.s	#0f10,fp0
	fintrz.x	fp0,fp1
	fmove.l	fp1,d7
		add.b	#'0',d7		;'0'�`'9'�ɂ���
	fsub.x	fp1,fp0
		move.b	d7,(a0)+
	subq.l	#1,d2
	bne	1b
2:
;�l�̌ܓ�
	fcmp.s	#0f0.5,fp0
	fblt	3f			;���̌���5�����Ȃ̂Ő؂�̂Ă�
;�J��グ��
	move.l	(sp),d2			;�c�錅��
	ble	2f
1:	addq.b	#1,-(a0)		;�J��オ��
		cmpi.b	#'9',(a0)
	bls	3f			;��̈ʂɔ[�܂����̂ŏI���
		move.b	#'0',(a0)	;��̈ʂ���ꂽ
	subq.l	#1,d2
	bne	1b
2:
;�ŏ�ʂ���J��オ����
	move.l	(sp),d2			;�c�錅��(�J��グ�ď�����1���܂܂Ȃ�)
	blt	2f
	move.b	#'1',(a0)+
		tst.l	d2
	beq	2f
1:	move.b	#'0',(a0)+
		subq.l	#1,d2
	bne	1b
2:	addq.l	#1,d0			;�ŏ�ʂ���J��オ����
		addq.l	#1,(sp)		;�c�錅����1��������
;�I���
3:	move.l	(sp)+,d2		;�c�錅��
		movea.l	(sp)+,a0	;�������̍ŏ���0�ȊO�̐����̈ʒu
;	tst.l	d2
	ble	@f
	adda.l	d2,a0			;�����̌��̎��̈ʒu
@@:	clr.b	(a0)
	rts

fcvtZero:
@@:	move.b	#'0',(a0)+		;d2+1��0����ׂ�
	subq.l	#1,d2
	bcc	@b
	moveq.l	#1,d0			;10^1�ɂ���
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;$FE26	__GCVT
;	8�o�C�g���������_����S�̂̌������w�肵�����������_�\���܂��͎w���\���̕������
;	�ϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;<d2.b:�S�̂̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
;	���̒l�̏ꍇ�͕�����̐擪�Ƀ}�C�i�X�L��('-')���t������܂��B
;	d2�̌����ŕ\���ł��Ȃ��ꍇ�ɁA�w���\���̕�����ɕϊ����܂��B
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
@@:	move.l	#'#INF',(a0)+		;��A�h���X�̉\��������
					;�����͌���������Ȃ���$00�Ɏw����t���Č��ǂ͂ݏo��
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;��A�h���X�̉\��������
2:	clr.b	(a0)
	move.l	#4,d0			;���4
	exit	d2

;----------------------------------------------------------------
;gcvt
;���������_����S�̂̌������w�肵�����������_�\���܂��͎w���\���̕�����ɕϊ�����
;<d2.l:�S�̂̌���(�����͕s��,�����⏬���_�͊܂܂Ȃ�,������0.0xxx�ƂȂ�Ƃ���0.���܂�)
;<a0.l:�o�b�t�@�̐擪
;<fp0:���������_��(#INF��#NAN�͕s��)
;>(a0):�ϊ����ꂽ������
;>a0.l:������̖�����0�̃A�h���X
;	���̒l�̏ꍇ�͕�����̐擪�Ƀ}�C�i�X�L��('-')���t�������
;	d2�̌����ŕ\���ł��Ȃ��ꍇ�͎w���\���̕�����ɕϊ�����
;*a0,?d0-d2/d7/a6/fp0
gcvt:
	ftst.x	fp0
	fbeq	9f			;���������_����0
	fbgt	@f
	move.b	#'-',(a0)+
@@:	clr.b	(a0)+			;�o�b�t�@�̐擪�܂���'-'�̒����0(�ԕ�)
	bsr	ecvt			;d0-d2/d7/a6��j�󂷂�,a0�͖�����0�̈ʒu
	movea.l	a0,a6			;�Ō�̌��̎��̈ʒu
		suba.l	d2,a0
@@:	cmp.b	#'0',-(a6)		;0�̂Ƃ��͔ԕ��Ŏ~�܂�
	beq	@b
;<a6.l:'0'�łȂ��Ō�̌��̈ʒu�܂��͔ԕ��̈ʒu
	cmpa.l	a0,a6
	blo	7f			;0������(�������K�v�Ȃ̂�d1���󂷑O�ɔ�Ԃ���)
	addq.l	#1,a6
;<a6.l:'0'�łȂ��Ō�̌��̎��̈ʒu
	move.l	a6,d1			;0�łȂ��Ō�̌��̎��̈ʒu
		sub.l	a0,d1		;���ʂ�0������������
;     ������ d1 ������
;    a0              a6
;    ��              ��
;     ������������ d2 ������������      d0
; �|���w�w�w�w�w�w�w�w�O�O�O�O�O�O�~�P�O
;    ��
;�|���E���{
;    d0
	cmp.l	d2,d0
	bgt	1f			;�w�����傫������(�w���`��)
	tst.l	d0
	bgt	4f			;�r���ɏ����_������(������.������)
;�w������0�ȉ�(�w���\���łȂ����0.�ɑ���)
	beq	@f
	subq.l	#2,d2
@@:	neg.l	d0			;0.�̉E����0�̐�
		add.l	d0,d1		;0.�̉E���̌���
;d0=0�̂Ƃ�
;    ������ d1 ������
;   a0              a6
;   ��              ��
;    ������������ d2 ������������
;�O�D�w�w�w�w�w�w�w�w�O�O�O�O�O�O
;  ����
;   d0
;d0>0�̂Ƃ�
;    �������� d1 ��������
;       a0              a6
;       ��              ��     2
;    ���������� d2 ��������������
;�O�D�O�O�w�w�w�w�w�w�w�w�O�O�O�O�O�O
;  �� d0 ��
	cmp.l	d2,d1
	ble	5f			;�擪��0.00�c��ǉ�����(�w���͕s�v)
;�w��������������(�w���`��)
;<d1.l:�L���Ȍ���
	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	sub.l	d0,d1			;0�łȂ������̌���
		adda.l	d1,a0		;�Ō�̌��̉E��
	move.b	#'E',(a0)+
		move.b	#'-',(a0)+
	bra	2f

;�w�����傫������(�w���`��)
;<d1.l:�L���Ȍ���
1:	move.b	(a0),(-1,a0)
		move.b	#'.',(a0)
	adda.l	d1,a0			;�Ō�̌��̉E��
		move.b	#'E',(a0)+
	move.b	#'+',(a0)+
;�w����10�i4�`3���ŏ���
;<d0.l:�w��(����)
2:	subq.l	#1,d0			;0.1�ȏ�1������1�ȏ�10�����ɂ���
		cmp.l	#1000,d0
	blo	2f
	move.l	#1000,d1
		moveq.l	#'0'-1,d7
@@:	addq.b	#1,d7
		sub.l	d1,d0
	bcc	@b
	add.l	d1,d0
		move.b	d7,(a0)+
;�w����10�i3���ŏ���
;<d0.l:�w��(����)
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

;������������
;<d0.l:�������̌���(��d2)
;<d1.l:������0������������(��d2,�����_���܂܂Ȃ�)
4:	sub.l	d0,d1			;�������̌���
	ble	3f			;�������̂�
;�r���ɏ����_������(������.������)
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	move.b	#'.',(-1,a0)
		adda.l	d1,a0		;�Ō�̌��̉E��
	clr.b	(a0)
	rts

;�������̂�
;<d0.l:����(��d2)
3:	cmp.l	d2,d0
	beq	3f			;�����_�͓���؂�Ȃ�
;�������݂̂��������_��t����
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	move.b	#'.',(-1,a0)
		clr.b	(a0)
	rts

;�������݂̂ŏ����_�͓���؂�Ȃ�
3:
@@:	move.b	(a0)+,(-2,a0)
		subq.l	#1,d0
	bne	@b
	clr.b	-(a0)
	rts

;�擪��0.00�c��ǉ�����(�w���͕s�v)
;    ���������� d1 ����������
;           a0              a6
;           ��              ��
;            ������������ d2 ������������
;�O�D�O�O�O�O�w�w�w�w�w�w�w�w�O�O�O�O�O�O�~�P�O
;    �� d0 ��
;<d0.l:0.�̉E����0�̐�
;<d1.l:0.�̉E����0�łȂ��Ō�̌��܂ł̌���
5:	sub.l	d0,d1			;0�łȂ������̌���
;    �� d0 �������� d1 ������
;           a0              a6
;           ��              ��
;            ������������ d2 ������������
;�O�D�O�O�O�O�w�w�w�w�w�w�w�w�O�O�O�O�O�O
;          �O�D�O�O�O�O�w�w�w�w�w�w�w�w�O
	lea.l	(1,a6,d0.l),a0
@@:	move.b	-(a6),(1,a6,d0.l)	;�E�ɂ��炷
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

;���ׂĂ̌���0������
;<d1.l:����(0=��,1=��)
;<a0.l:�ԕ��̎��̈ʒu
7:	subq.l	#1,a0			;�ԕ��̈ʒu
		suba.l	d1,a0		;�������̕��߂��ăo�b�t�@�̐擪��
;���������_����0�̂Ƃ�
9:	move.b	#'0',(a0)+
		subq.l	#1,d2
	ble	@f
	move.b	#'.',(a0)+
@@:	clr.b	(a0)
	rts

;----------------------------------------------------------------
;$FE28	__DTST
;	8�o�C�g���������_����0�̔�r�����܂��B
;<d0-d1:8�o�C�g���������_��
;>z-flag:eq=0
;>n-flag:mi=��
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
;	8�o�C�g���������_���ǂ����̔�r�����܂��B
;<d0-d1:���r��
;<d2-d3:��r��
;	���r�������r�������Z�������ʂɂ��������ăZ�b�g����܂��B
;>n-flag:mi=��
;>z-flag:eq=0
;>c-flag:cs=�{���[����������
;	���r������r�����傫���Ƃ�	cc,ne,pl
;	���r������r���Ɠ������Ƃ�	cc,eq,pl
;	���r������r����菬�����Ƃ�	cs,ne,mi
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
;	8�o�C�g���������_���̕����𔽓]���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
fe_dneg::
	tst.l	d0
	beq	@f
	bchg.l	#31,d0
@@:	exit

;----------------------------------------------------------------
;$FE2B	__DADD
;	8�o�C�g���������_���ǂ����̉��Z�����܂��B
;<d0-d1:����Z��
;<d2-d3:���Z��
;>d0-d1:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_dadd::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fadd.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̌��Z�����܂��B
;<d0-d1:�팸�Z��
;<d2-d3:���Z��
;>d0-d1:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_dsub::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fsub.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̏�Z�����܂��B
;<d0-d1:��搔
;<d2-d3:�搔
;>d0-d1:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_dmul::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fmul.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̏��Z�����܂��B
;<d0-d1:�폜��
;<d2-d3:����
;>d0-d1:���Z����
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�I�[�o�[�t���[,(cs,ne)vc=�A���_�[�t���[
fe_ddiv::
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		move.l	d3,-(sp)
	move.l	d2,-(sp)
	fdiv.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̏�]�����߂܂��B
;<d0-d1:�폜��
;<d2-d3:����
;>d0-d1:���Z����
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�L�������͈̔͊O,(cs,ne)vc=�A���_�[�t���[
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
	fmod.d	(sp)+,fp0		;�G�~�����[�V����
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
;	8�o�C�g���������_���̐�Βl�����߂܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
fe_dabs::
	bclr.l	#31,d0
	exit

;----------------------------------------------------------------
;$FE31	__DCEIL
;	8�o�C�g���������_���Ɠ��������A����ȏ�̍ŏ��̐�����Ԃ��܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
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
;	8�o�C�g���������_���̐����������߂܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
fe_dfix::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fintrz.d	(sp)+,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE33	__DFLOOR
;	8�o�C�g���������_���Ɠ��������܂��͂����菬�����ő�̐�����Ԃ��܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
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
;	8�o�C�g���������_���̏����������߂܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;	����������0�ɂ���(intrz������)
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
;	8�o�C�g���������_������������0���𒲂ׂ܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:����(8�o�C�g���������_��)
;	���Ȃ�+1�A���Ȃ�-1�A0�Ȃ�0��Ԃ��܂��B
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
;	�p�x(���W�A���P��)��^���Đ���(sin)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;	|X|<=��/4�Ƃ��Ă���
;	{(-1)^(n-1)/(2n-1)!}X^(2n-1)��0�ɂȂ�܂ŉ�����
fe_sin::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	sin
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE37	__COS
;	�p�x(���W�A���P��)��^���ė]��(cos)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;	|X|<=��/4�Ƃ��Ă���
;	{(-1)^n/(2n)!}X^2n��0�ɂȂ�܂ŉ�����
fe_cos::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	cos
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE38	__TAN
;	�p�x(���W�A���P��)��^���Đ���(tan)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(������((2n+1)/2)��(n:����))
;	sin/cos
fe_tan::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	tan
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE39	__ATAN
;	�t����(atan)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����(���W�A���P��)
;	X>1�̂Ƃ���/2-atan(1/X)
;	X>1/2�̂Ƃ�atan(X)=atan(1/2)+atan(2X-1/(X+2))
;	X>1/4�̂Ƃ�atan(X)=atan(1/4)+atan(4X-1/(X+4))
;	X>1/8�̂Ƃ�atan(X)=atan(1/4)-atan(1-4X/(X+4))
;	X=1�̂Ƃ���/4
;	{(-1)^n}X^(2n+1)/(2n+1)��0�ɂȂ�܂ŉ�����
fe_atan::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	atan
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE3A	__LOG
;	���R�ΐ�(log)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(������0�܂��͕�)
;>z-flag:(cs)eq=������0(log 0)
fe_log::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	logn
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE3B	__EXP
;	�w���֐�(e^x)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[)
;	0<=X<logn(2)�̂Ƃ�X^n/n!��0�ɂȂ�܂ŉ�����
;	X>=logn(2)�̂Ƃ�X=n*logn(2)�}Y(n�͐���,0<Y<log(2)/2)��exp(Y)������n�r�b�g���炷
fe_exp::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	etox
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE3C	__SQR
;	���������v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(��������)
fe_sqr::
	tst.l	d0
	bmi	9f
	fmove.l	#$00000000,fpsr
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fsqrt.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	�~������8�o�C�g���������_���͈͓̔��ŕԂ��܂��B
;>d0-d1:���Z����
fe_pi::
	move.l	#$400921FB,d0
		move.l	#$54442D18,d1
	exit

;----------------------------------------------------------------
;$FE3E	__NPI
;	�~������8�o�C�g���������_���̐�(x��)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[)
fe_npi::
	fmove.l	#$00000000,fpsr
	fmove.x	pi(pc),fp0		;��
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmul.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	�ׂ���(X^y)���v�Z���܂��B
;<d0-d1:��ׂ��搔
;<d2-d3:�w��
;>d0-d1:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_power::
	bsr	power
	exit	ccr

power:
	movem.l	d0-d1,-(sp)
	fmove.l	#$00000000,fpsr
	flogn.d	(sp),fp0		;�G�~�����[�V����
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
	fetox.x	fp0			;�G�~�����[�V����
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
	tst.l	d0			;������Ȃ��Ǝv��
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
;	8�o�C�g���������_���̗�����Ԃ��܂��B
;>d0-d1:8�o�C�g���������_���̗���(0�ȏ�1����)
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
;	�o�Ȑ���(sinh)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
;	{exp(X)-1/exp(X)}/2
fe_sinh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	sinh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE42	__COSH
;	�o�ȗ]��(cosh)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
;	{exp(X)+1/exp(X)}/2
fe_cosh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	cosh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE43	__TANH
;	�o�Ȑ���(tanh)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
;	-EXP(-X)/(EXP(X)+EXP(-X))*2+1
fe_tanh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	tanh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE44	__ATANH
;	�t�o�Ȑ���(atanh)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(������-1�ȉ��܂���+1�ȏ�)
;	LOG((1+X)/(1-X))/2
fe_atanh::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	atanh
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE45	__ASIN
;	�t����(asin)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(������-1�ȏ�+1�ȉ��͈̔͂Ɋ܂܂�Ă��Ȃ�)
;	ATAN(X/SQRT(1-X*X))
fe_asin::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	asin
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE46	__ACOS
;	�t�]��(acos)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(������-1�ȏ�+1�ȉ��͈̔͂Ɋ܂܂�Ă��Ȃ�)
;	ATAN(X/SQRT(1-X*X))+��/2
fe_acos::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	acos
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE47	__LOG10
;	��p�ΐ�(log10 X)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
;	logn(X)/logn(10)
fe_log10::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	log10
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE48	__LOG2
;	�r�b�g�ΐ�(log2)���v�Z���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
;	logn(X)/logn(2)
fe_log2::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fpsp	log2
	fmove.d	fp0,-(sp)
		tst.b	d7
	bmi	@f
	exit	d0,d1

@@:	exit	C,d0,d1

;----------------------------------------------------------------
;$FE49	__DFREXP
;	8�o�C�g���������_���̉������Ǝw�����𕪂��܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:������������8�o�C�g���������_��
;>d2.l:�w��������������������
;	�Ԃ�l��d0-d1�̌`���͈����̎w������1�ɁA�����������̂܂܂ɂ��ĕԂ��܂��B
fe_dfrexp::
	move.l	d0,d2
	lsl.l	#1,d2			;�����𖳎�
	or.l	d1,d2
	beq	1f			;0
	swap.w	d0
	move.w	d0,d2			;seeeeeeeeeeemmmm
	lsl.w	#1,d2			;eeeeeeeeeeemmmm0
	lsr.w	#5,d2			;00000eeeeeeeeeee
	sub.w	#$03FF,d2
	ext.l	d2			;�w����(������)
	and.w	#$800F,d0		;�w������1�ɂ���
	or.w	#$3FF0,d0		;
	swap.w	d0
	exit

1:	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2
	exit

;----------------------------------------------------------------
;$FE4A	__DLDEXP
;	�w�����Ɖ���������������8�o�C�g���������_����Ԃ��܂��B
;<d0-d1:�������f�[�^(8�o�C�g���������_��)
;<d2.l:�w�����f�[�^(4�o�C�g����������)
;>d0-d1:�������ꂽ8�o�C�g���������_��
;>c-flag:cs=�G���[
;	������d0-d1�̎w������d2�̒l+$3FF�����Z���܂��B
fe_dldexp::
	move.l	d0,d7			;0�̂Ƃ��͎w������ύX���Ȃ�
	lsl.l	#1,d7
	or.l	d1,d7
	beq	1f			;0�̂Ƃ�
	swap.w	d0
	move.w	d0,d7			;seeeeeeeeeeemmmm
	lsl.w	#1,d7			;eeeeeeeeeeemmmm0
	lsr.w	#5,d7			;00000eeeeeeeeeee
	ext.l	d7
	add.l	d2,d7			;�w���������Z
	beq	2f
	cmp.l	#$000007FF,d7
	bcc	2f
	lsl.w	#4,d7			;�w����������
	and.w	#$800F,d0
	or.w	d7,d0
	swap.w	d0
	exit	_

1:	moveq.l	#0,d0			;0�̂Ƃ�
					;d1.l�͊���0
	exit	_

2:	swap.w	d0			;d0-d1�����ɖ߂�
	exit	C

;----------------------------------------------------------------
;$FE4B	__DADDONE
;	8�o�C�g���������_����1�������܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
fe_daddone::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fadd.s	#0f1,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE4C	__DSUBONE
;	8�o�C�g���������_������1�������܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
fe_dsubone::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fsub.s	#0f1,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE4D	__DDIVTWO
;	8�o�C�g���������_����2�Ŋ���܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:���Z����
;>c-flag:cs=�G���[(�A���_�[�t���[)
fe_ddivtwo::
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fdiv.s	#0f2,fp0
	fmove.d	fp0,-(sp)
	exit	d0,d1

;----------------------------------------------------------------
;$FE4E	__DIEECNV
;	8�o�C�g���������_����IEEE�t�H�[�}�b�g�ɕϊ����܂��B
;<d0-d1:8�o�C�g���������_��
;>d0-d1:IEEE�t�H�[�}�b�g8�o�C�g���������_��
;	FLOAT2.X�AFLOAT3.X�ł͕ϊ����܂���B
fe_dieecnv::
	exit

;----------------------------------------------------------------
;$FE4F	__IEEDCNV
;	IEEE�t�H�[�}�b�g��8�o�C�g���������_���ɕϊ����܂��B
;<d0-d1:IEEE�t�H�[�}�b�g8�o�C�g���������_��
;>d0-d1:8�o�C�g���������_��
;	FLOAT2.X�AFLOAT3.X�ł͕ϊ����܂���B
fe_ieedcnv::
	exit

;----------------------------------------------------------------
;$FE50	__FVAL
;	�������4�o�C�g���������_���ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g���������_��
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
;	������10�i���ȊO�̏ꍇ�A���̐擪�ɂ́A2�i���ł�'&B'�A8�i���ł�'&O'�A
;	16�i���ł�'&H'���K�v�ł��B
;	10�i���̏ꍇ�A�Ԃ�l�Ƃ��Ď��̂��̂��ǉ�����܂��B
;		d2.w	�����t���O
;		d3.l	�����l
;	�����񂪐���(�������y�юw�������Ȃ�)�ŁA����4�o�C�g�����������ŕ\���\�ȏꍇ�A
;	�����t���O��$FFFF�ŁA�����l�ɂ��̒l���͂���܂��B
;	����ȊO�̏ꍇ�͐����t���O��0�ƂȂ�܂��B
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

2:	moveq.l	#0,d2			;�����t���O
	moveq.l	#0,d3
	move.b	(a0)+,d0
	cmp.b	#'H',d0
	beq	3f
	cmp.b	#'B',d0
	beq	4f
	cmp.b	#'O',d0
	beq	5f
	subq.w	#1,a0			;�����i�͖߂��Ă��Ȃ�
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
;	4�o�C�g���������_���𕶎���ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;<d2.l:���������̌���
;<d3.l:���������̌���
;<d4.l:�A�g���r���[�g
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
;	�A�g���r���[�g�̓r�b�g0�`6���Z�b�g���邱�Ƃɂ��ȉ��̂悤�Ȑ��l�\�����ł��܂��B
;	�r�b�g0:������'*'�Ńp�b�e�B���O���܂��B
;	�r�b�g1:'\'��擪�ɕt�����܂��B
;	�r�b�g2:����������3�����Ƃ�','�ŋ�؂�܂��B
;	�r�b�g3:�w���`���ŕ\�����܂��B
;	�r�b�g4:�����̏ꍇ'+'��擪�ɕt�����܂��B
;	�r�b�g5:�����̏ꍇ'+'���A�����̏ꍇ'-'���Ō���ɕt�����܂��B
;	�r�b�g6:�����̏ꍇ' '���A�����̏ꍇ'-'���Ō���ɕt�����܂��B
fe_fusing::
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	fmove.s	(sp)+,fp0
	bsr	using
	exit	d1

;----------------------------------------------------------------
;$FE52	__STOF
;	�������4�o�C�g���������_���ɕϊ����܂��B
;<a0.l:��������w���|�C���^
;>d0.l:�ϊ����ꂽ4�o�C�g���������_��
;>d2.w:�����t���O
;>d3.l:�����l
;>c-flag:cs=�G���[
;>n-flag:(cs)mi=���l�̋L�q�@����������
;>v-flag:(cs)vs=�I�[�o�[�t���[
;	�����񂪐���(�������y�юw�������Ȃ�)�ŁA����4�o�C�g�����������ŕ\���\�ȏꍇ�A
;	�����t���O��$FFFF�ŁA�����l�ɂ��̒l���͂���܂��B
;	����ȊO�̏ꍇ�͐����t���O��0�ƂȂ�܂��B
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
;	4�o�C�g���������_���𕶎���ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;<(a0):�ϊ����ꂽ������
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
;	4�o�C�g���������_����S�̂̌������w�肵�ĕ�����ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;<d2.b:�S�̂̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>d0.l:�����_�̈ʒu
;>d1.l:����(0=��,1=��)
;>(a0):�ϊ����ꂽ������
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
	move.l	a0,-(sp)		;a0��j�󂵂Ȃ�
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
	subq.l	#1,d2			;�����͌���������Ȃ���$00������悤�Ƃ���
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
	move.l	#4,d0			;���4
	exit	d1,d2

;----------------------------------------------------------------
;$FE55	__FFCVT
;	4�o�C�g���������_���������_�ȉ��̌������w�肵�āA������ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;<d2.b:�����_�ȉ��̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>d0.l:�����_�̈ʒu
;>d1.l:����(0=��,1=��)
;>(a0):�ϊ����ꂽ������
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
	move.l	a0,-(sp)		;a0��j�󂵂Ȃ�
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
@@:	move.l	#'#INF',(a0)+		;��A�h���X�̉\��������
					;�����͌���������Ȃ���$00�Ɏw����t���Č��ǂ͂ݏo��
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;��A�h���X�̉\��������
2:	clr.b	(a0)
	move.l	#4,d0			;���4
	exit	d1,d2

;----------------------------------------------------------------
;$FE56	__FGCVT
;	4�o�C�g���������_����S�̂̌������w�肵�����������_�\���܂��͎w���\���̕������
;	�ϊ����܂��B
;<d0.l:4�o�C�g���������_��
;<d2.b:�S�̂̌���
;<a0.l:�ϊ����ꂽ������̊i�[�p�o�b�t�@���w���|�C���^
;>(a0):�ϊ����ꂽ������
;	���̒l�̏ꍇ�͕�����̐擪�Ƀ}�C�i�X�L��('-')���t������܂��B
;	d2�̌����ŕ\���ł��Ȃ��ꍇ�ɁA�w���\���̕�����ɕϊ����܂��B
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
@@:	move.l	#'#INF',(a0)+		;��A�h���X�̉\��������
					;�����͌���������Ȃ���$00�Ɏw����t���Č��ǂ͂ݏo��
	bra	2f

1:	moveq.l	#0,d1
	move.l	#'#NAN',(a0)+		;��A�h���X�̉\��������
2:	clr.b	(a0)
	move.l	#4,d0			;���4
	exit	d1,d2

;----------------------------------------------------------------
;$FE58	__FTST
;	4�o�C�g���������_����0�̔�r�����܂��B
;<d0.l:4�o�C�g���������_��
;>z-flag:eq=0
;>n-flag:mi=��
fe_ftst::
	cmp.l	#$80000000,d0
	beq	@f
	tst.l	d0
@@:	exit	ccr

;----------------------------------------------------------------
;$FE59	__FCMP
;	4�o�C�g���������_���ǂ����̔�r�����܂��B
;<d0.l:���r��
;<d1.l:��r��
;	���r�������r�������Z�������ʂɂ��������ăZ�b�g����܂��B
;>n-flag:mi=��
;>z-flag:eq=0
;>c-flag:cs=�{���[����������
;	���r������r�����傫���Ƃ�	cc,ne,pl
;	���r������r���Ɠ������Ƃ�	cc,eq,pl
;	���r������r����菬�����Ƃ�	cs,ne,mi
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
;	4�o�C�g���������_���̕����𔽓]���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_fneg::
	tst.l	d0
	beq	@f
	bchg.l	#31,d0
@@:	exit

;----------------------------------------------------------------
;$FE5B	__FADD
;	4�o�C�g���������_���ǂ����̉��Z�����܂��B
;<d0.l:����Z��
;<d1.l:���Z��
;>d0.l:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
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
;	4�o�C�g���������_���ǂ����̌��Z�����܂��B
;<d0.l:�팸�Z��
;<d1.l:���Z��
;>d0.l:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
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
;	4�o�C�g���������_���ǂ����̏�Z�����܂��B
;<d0.l:��搔
;<d1.l:�搔
;>d0.l:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
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
;	4�o�C�g���������_���ǂ����̏��Z�����܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�I�[�o�[�t���[,(cs,ne)vc=�A���_�[�t���[
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
;	4�o�C�g���������_���ǂ����̏�]�����߂܂��B
;<d0.l:�폜��
;<d1.l:����
;>d0.l:���Z����
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�L�������͈̔͊O,(cs,ne)vc=�A���_�[�t���[
fe_fmod::
	tst.l	d1
	beq	1f
	fmove.l	#$00000000,fpsr
	fmove.s	d0,fp0
	fmod.s	d1,fp0			;�G�~�����[�V����
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
;	4�o�C�g���������_���̐�Βl�����߂܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_fabs::
	bclr.l	#31,d0
	exit

;----------------------------------------------------------------
;$FE61	__FCEIL
;	4�o�C�g���������_���Ɠ��������A����ȏ�̍ŏ��̐�����Ԃ��܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_fceil::
	fmove.l	fpcr,d7
	fmove.l	#FPRM_RP,fpcr
	fint.s	d0,fp0
	fmove.s	fp0,d0
	fmove.l	d7,fpcr
	exit

;----------------------------------------------------------------
;$FE62	__FFIX
;	4�o�C�g���������_���̐����������߂܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_ffix::
	fintrz.s	d0,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE63	__FFLOOR
;	4�o�C�g���������_���Ɠ��������܂��͂����菬�����ő�̐�����Ԃ��܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_ffloor::
	fmove.l	fpcr,d7
	fmove.l	#FPRM_RM,fpcr
	fint.s	d0,fp0
	fmove.s	fp0,d0
	fmove.l	d7,fpcr
	exit

;----------------------------------------------------------------
;$FE64	__FFRAC
;	4�o�C�g���������_���̏����������߂܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
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
	bhi	4f			;�w�������傫������
	lsl.l	d2,d0
	and.l	#$00FFFFFF,d0
	beq	4f			;��������0
	moveq.l	#$17,d7
	btst.l	d7,d0
	bne	2f
1:	addq.w	#1,d2			;�������𐳋K������
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
;	4�o�C�g���������_������������0���𒲂ׂ܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:����(4�o�C�g���������_��)
;	���Ȃ�+1�A���Ȃ�-1�A0�Ȃ�0��Ԃ��܂��B
fe_fsgn::
	add.l	d0,d0
	beq	@f
	move.l	#$3F800000<<1,d0
	roxr.l	#1,d0
@@:	exit

;----------------------------------------------------------------
;$FE66	__FSIN
;	�p�x(���W�A���P��)��^���Đ���(sin)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
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
;	�p�x(���W�A���P��)��^���ė]��(cos)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
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
;	�p�x(���W�A���P��)��^���Đ���(tan)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�������A((2n+1)/2)��(n:����))
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
;	�t����(atan)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����(���W�A���P��)
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
;	���R�ΐ�(log)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(������0�܂��͕�)
;>z-flag:(cs)eq=������0(log 0)
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
;	�w���֐�(e^x)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[)
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
;	���������v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(��������)
fe_fsqr::
	tst.l	d0
	bmi	9f
	fmove.l	#$00000000,fpsr
	fsqrt.s	d0,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	�~������4�o�C�g���������_���͈͓̔��ŕԂ��܂��B
;>d0.l:���Z����
fe_fpi::
	move.l	#$40490FDB,d0
	exit

;----------------------------------------------------------------
;$FE6E	__FNPI
;	�~������4�o�C�g���������_���̐�(x��)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[)
fe_fnpi::
	fmove.l	#$00000000,fpsr
	fmove.x	pi(pc),fp0		;��
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
;	�ׂ���(X^y)���v�Z���܂��B
;<d0.l:��ׂ��搔
;<d1.l:�w��
;>d0.l:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
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
	flogn.s	(sp),fp0		;�G�~�����[�V����
	fmul.s	d1,fp0
	fetox.x	fp0			;�G�~�����[�V����
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
;	4�o�C�g���������_���̗�����Ԃ��܂��B
;>d0.l:4�o�C�g���������_���̗���(0�ȏ�1����)
fe_frnd::
	bsr	rnd
	move.l	d1,-(sp)
		move.l	d0,-(sp)
	fmove.d	(sp)+,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE71	__FSINH
;	�o�Ȑ���(sinh)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
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
;	�o�ȗ]��(cosh)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
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
;	�o�Ȑ���(tanh)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
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
;	�t�o�Ȑ���(atanh)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
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
;	�t����(asin)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(������-1�ȏ�+1�ȉ��͈̔͂Ɋ܂܂�Ă��Ȃ�)
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
;	�t�]��(acos)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(������-1�ȏ�+1�ȉ��͈̔͂Ɋ܂܂�Ă��Ȃ�)
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
;	��p�ΐ�(log10 X)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
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
;	�r�b�g�ΐ�(log2)���v�Z���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�I�[�o�[�t���[�܂��̓A���_�[�t���[)
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
;	4�o�C�g���������_���̉������Ǝw�����𕪂��܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:������������4�o�C�g���������_��
;>d1.l:�w����������4�o�C�g����������
;	�Ԃ�l��d0�́A�����̎w������1�ɁA�����������̂܂܂ɂ��ĕԂ��܂��B
fe_ffrexp::
	move.l	d0,d1			;seeeeeeeemmmmmmmmmmmmmmmmmmmmmmm
	lsl.l	#1,d1			;eeeeeeeemmmmmmmmmmmmmmmmmmmmmmm0
	beq	1f			;0�̂Ƃ�
	swap.w	d1			;eeeeeeeemmmmmmmm
	lsr.w	#8,d1			;00000000eeeeeeee
	sub.w	#$007F,d1
	ext.l	d1			;�w����(������)
	and.l	#$807FFFFF,d0		;�����Ɖ��������c���Ďw������1�ɂ���
	or.l	#$3F800000,d0		;
	exit

1:	moveq.l	#0,d0			;����������
					;d1.l�͊���0
	exit

;----------------------------------------------------------------
;$FE7A	__FLDEXP
;	�w�����Ɖ���������������4�o�C�g���������_����Ԃ��܂��B
;<d0.l:�������f�[�^(4�o�C�g���������_��)
;<d1.l:�w�����f�[�^(4�o�C�g����������)
;>d0.l:�������ꂽ4�o�C�g���������_��
;>c-flag:cs=�G���[
;	������d0�̎w������d1�̒l+$7F�����Z���܂��B
fe_fldexp::
	move.l	d0,d7			;seeeeeeeemmmmmmm_mmmmmmmmmmmmmmmm
	lsl.l	#1,d7			;eeeeeeeemmmmmmmm_mmmmmmmmmmmmmmm0
	beq	1f			;0�̂Ƃ�
	swap.w	d7			;eeeeeeeemmmmmmmm
	lsr.w	#8,d7			;00000000eeeeeeee
	ext.l	d7
	add.l	d1,d7			;�w���������Z
	beq	2f
	cmp.l	#$00000FF,d7
	bcc	2f
	lsl.w	#7,d7			;0eeeeeeee0000000
	swap.w	d7			;0eeeeeeee0000000_0000000000000000
	and.l	#$807FFFFF,d0
	or.l	d7,d0
	exit	_

1:	moveq.l	#0,d0			;0�̂Ƃ�
	exit	_

2:	exit	C			;d0�͕ω����Ȃ�

;----------------------------------------------------------------
;$FE7B	__FADDONE
;	4�o�C�g���������_����1�������܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_faddone::
	fmove.s	d0,fp0
	fadd.s	#0f1,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE7C	__FSUBONE
;	4�o�C�g���������_������1�������܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
fe_fsubone::
	fmove.s	d0,fp0
	fsub.s	#0f1,fp0
	fmove.s	fp0,d0
	exit

;----------------------------------------------------------------
;$FE7D	__FDIVTWO
;	4�o�C�g���������_����2�Ŋ���܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:���Z����
;>c-flag:cs=�G���[(�A���_�[�t���[)
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
;	4�o�C�g���������_����IEEE�t�H�[�}�b�g�ɕϊ����܂��B
;<d0.l:4�o�C�g���������_��
;>d0.l:IEEE�t�H�[�}�b�g4�o�C�g���������_��
;	FLOAT2.X�AFLOAT3.X�ł͕ϊ����܂���B
fe_fieecnv::
	exit

;----------------------------------------------------------------
;$FE7F	__IEEFCNV
;	IEEE�t�H�[�}�b�g��4�o�C�g���������_���ɕϊ����܂��B
;<d0.l:IEEE�t�H�[�}�b�g4�o�C�g���������_��
;>d0.l:4�o�C�g���������_��
;	FLOAT2.X�AFLOAT3.X�ł͕ϊ����܂���B
fe_ieefcnv::
	exit

;----------------------------------------------------------------
;$FEE0	__CLMUL
;	4�o�C�g�����������ǂ����̏�Z�����܂��B
;<(sp).l:��搔��4�o�C�g����������
;<(4,sp).l:�搔��4�o�C�g����������
;>(sp).l:���Z���ʂ�4�o�C�g����������
;>c-flag:cs=�G���[(���Z���ʂ�4�o�C�g�����������͈̔͂𒴂���)
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
;	4�o�C�g�����������ǂ����̏��Z�����܂��B
;<(sp).l:�폜����4�o�C�g����������
;<(4,sp).l:������4�o�C�g����������
;>(sp).l:���Z���ʂ�4�o�C�g����������
;>c-flag:cs=�G���[(������0)
fe_cldiv::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCR�N���A
	divs.l	(a6),d7
	exit	-7

@@:	exit	C

;----------------------------------------------------------------
;$FEE2	__CLMOD
;	4�o�C�g�����������ǂ����̏��Z�̏�]���v�Z���܂��B
;<(sp).l:�폜����4�o�C�g����������
;<(4,sp).l:������4�o�C�g����������
;>(sp).l:���Z���ʂ�4�o�C�g����������
;>c-flag:cs=�G���[(������0)
fe_clmod::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCR�N���A
	move.l	d0,-(sp)
	divsl.l	(a6),d0:d7
	exit	-0,d0

@@:	exit	C

;----------------------------------------------------------------
;$FEE3	__CUMUL
;	4�o�C�g�����Ȃ������ǂ����̏�Z�����܂��B
;<(sp).l:��搔��4�o�C�g����������
;<(4,sp).l:�搔��4�o�C�g����������
;>(sp).l:���Z���ʂ�4�o�C�g����������
;>c-flag:cs=�G���[(���Z���ʂ�4�o�C�g�����������͈̔͂𒴂���)
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
;	4�o�C�g�����Ȃ������ǂ����̏��Z�����܂��B
;<(sp).l:�폜����4�o�C�g����������
;<(4,sp).l:������4�o�C�g����������
;>(sp).l:���Z���ʂ�4�o�C�g����������
;>c-flag:cs=�G���[(������0)
fe_cudiv::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCR�N���A
	divu.l	(a6),d7
	exit	-7

@@:	exit	C

;----------------------------------------------------------------
;$FEE5	__CUMOD
;	4�o�C�g�����Ȃ������ǂ����̏��Z�̏�]���v�Z���܂��B
;<(sp).l:�폜����4�o�C�g����������
;<(4,sp).l:������4�o�C�g����������
;>(sp).l:���Z���ʂ�4�o�C�g����������
;>c-flag:cs=�G���[(������0)
fe_cumod::
	param	a6
	tst.l	(4,a6)
	beq	@f
	move.l	(a6)+,d7
		clr.b	4*2+1(sp)	;CCR�N���A
	move.l	d0,-(sp)
	divul.l	(a6),d0:d7
	exit	-0,d0

@@:	exit	C

;----------------------------------------------------------------
;$FEE6	__CLTOD
;	4�o�C�g������������8�o�C�g���������_���ɕϊ����܂��B
;<(sp).l:4�o�C�g����������
;>(sp).d:�ϊ����ꂽ8�o�C�g���������_��
fe_cltod::
	param	a6
	fmove.l	(a6),fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEE7	__CDTOL
;	8�o�C�g���������_����4�o�C�g�����������ɕϊ����܂��B
;<(sp).d:8�o�C�g���������_��
;>(sp).l:�ϊ����ꂽ4�o�C�g����������
;>c-flag:cs=�G���[(�ϊ����ʂ�4�o�C�g�����������̒l�͈̔͂𒴂���)
;	���������͐؂�̂Ă��܂��B
;	4�o�C�g�����������̒l�͎��͈̔͂ł��B
;		-2147483648�`+2147483647
fe_cdtol::
	param	a6
	fmove.l	#$00000000,fpsr
	fintrz.d	(a6),fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g������������4�o�C�g���������_���ɕϊ����܂��B
;<(sp).l:4�o�C�g����������
;>(sp).s:�ϊ����ꂽ4�o�C�g���������_��
fe_cltof::
	param	a6
	fmove.l	(a6),fp0
	fmove.s	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEE9	__CFTOL
;	4�o�C�g���������_����4�o�C�g�����������ɕϊ����܂��B
;<(sp).s:4�o�C�g���������_��
;>(sp).l:�ϊ����ꂽ4�o�C�g����������
;>c-flag:cs=�G���[(�ϊ����ʂ�4�o�C�g�����������̒l�͈̔͂𒴂���)
;	���������͐؂�̂Ă��܂��B
;	4�o�C�g�����������̒l�͎��͈̔͂ł��B
;		-2147483648�`+2147483647
fe_cftol::
	param	a6
	fmove.l	#$00000000,fpsr
	fintrz.s	(a6),fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g���������_����8�o�C�g���������_���ɕϊ����܂��B
;<(sp).s:4�o�C�g���������_��
;>(sp).d:�ϊ����ꂽ8�o�C�g���������_��
fe_cftod::
	param	a6
	fmove.s	(a6),fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEEB	__CDTOF
;	8�o�C�g���������_����4�o�C�g���������_���ɕϊ����܂��B
;<(sp).d:8�o�C�g���������_��
;>(sp).s:�ϊ����ꂽ4�o�C�g���������_��
;>c-flag:cs=�G���[(������4�o�C�g���������_���ŕ\���ł��Ȃ�)
fe_cdtof::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6),fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̔�r�����܂��B
;<(sp).d:���r��
;<(8,sp).d:��r��
;	���r�������r�������Z�������ʂɂ��������ăZ�b�g����܂��B
;>n-flag:mi=��
;>z-flag:eq=0
;>c-flag:cs=�{���[����������
;	���r������r�����傫���Ƃ�	cc,ne,pl
;	���r������r���Ɠ������Ƃ�	cc,eq,pl
;	���r������r����菬�����Ƃ�	cs,ne,mi
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
;	8�o�C�g���������_���ǂ����̉��Z�����܂��B
;<(sp).d:����Z����8�o�C�g���������_��
;<(8,sp).d:���Z����8�o�C�g���������_��
;>(sp).d:���Z���ʂ�8�o�C�g���������_��
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_cdadd::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̌��Z�����܂��B
;<(sp).d:�팸�Z����8�o�C�g���������_��
;<(8,sp).d:���Z����8�o�C�g���������_��
;>(sp).d:���Z���ʂ�8�o�C�g���������_��
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_cdsub::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̏�Z�����܂��B
;<(sp).d:���Z����8�o�C�g���������_��
;<(8,sp).d:��Z����8�o�C�g���������_��
;>(sp).d:���Z���ʂ�8�o�C�g���������_��
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_cdmul::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̏��Z�����܂��B
;<(sp).d:�폜�Z����8�o�C�g���������_��
;<(8,sp).d:���Z����8�o�C�g���������_��
;>(sp).d:���Z���ʂ�8�o�C�g���������_��
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�I�[�o�[�t���[,(cs,ne)vc=�A���_�[�t���[
fe_cddiv::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	8�o�C�g���������_���ǂ����̏�]�����߂܂��B
;<(sp).d:�폜�Z����8�o�C�g���������_��
;<(8,sp).d:���Z����8�o�C�g���������_��
;>(sp).d:���Z���ʂ�8�o�C�g���������_��
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�L�������͈̔͊O,(cs,ne)vc=�A���_�[�t���[
fe_cdmod::
	param	a6
	move.l	(8,a6),d7
	add.l	d7,d7
	or.l	(8+4,a6),d7
	beq	1f
	fmove.l	#$00000000,fpsr
	fmove.d	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fmod.d	(a6),fp0		;�G�~�����[�V����
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
;	4�o�C�g���������_���ǂ����̔�r�����܂��B
;<(sp).s:���r��
;<(4,sp).s:��r��
;	���r�������r�������Z�������ʂɂ��������ăZ�b�g����܂��B
;>n-flag:mi=��
;>z-flag:eq=0
;>c-flag:cs=�{���[����������
;	���r������r�����傫���Ƃ�	cc,ne,pl
;	���r������r���Ɠ������Ƃ�	cc,eq,pl
;	���r������r����菬�����Ƃ�	cs,ne,mi
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
;	4�o�C�g���������_���ǂ����̉��Z�����܂��B
;<(sp).s:����Z��
;<(4,sp).s:���Z��
;>(sp).s:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_cfadd::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g���������_���ǂ����̌��Z�����܂��B
;<(sp).s:�팸�Z��
;<(4,sp).s:���Z��
;>(sp).s:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_cfsub::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g���������_���ǂ����̏�Z�����܂��B
;<(sp).s:���Z��
;<(4,sp).s:��Z��
;>(sp).s:���Z����
;>c-flag:cs=�G���[
;>v-flag:(cs)vs=�I�[�o�[�t���[,(cs)vc=�A���_�[�t���[
fe_cfmul::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g���������_���ǂ����̏��Z�����܂��B
;<(sp).s:�폜�Z��
;<(4,sp).s:���Z��
;>(sp).s:���Z����
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�I�[�o�[�t���[,(cs,ne)vc=�A���_�[�t���[
fe_cfdiv::
	param	a6
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
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
;	4�o�C�g���������_���ǂ����̏�]�����߂܂��B
;<(sp).s:�폜�Z��
;<(4,sp).s:���Z��
;>(sp).s:���Z����
;>c-flag:cs=�G���[
;>z-flag:(cs)eq=0�Ŋ�����
;>v-flag:(cs,ne)vs=�L�������͈̔͊O,(cs,ne)vc=�A���_�[�t���[
fe_cfmod::
	param	a6
	tst.l	4(a6)
	beq	1f
	fmove.l	#$00000000,fpsr
	fmove.s	(a6)+,fp0
		clr.b	4*2+1(sp)	;CCR�N���A
	fmod.s	(a6),fp0		;�G�~�����[�V����
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
;	8�o�C�g���������_����0�̔�r�����܂��B
;<(sp).d:8�o�C�g���������_��
;>z-flag:eq=0
;>n-flag:mi=��
fe_cdtst::
	param	a6
	move.l	(a6)+,d7
	or.w	(a6)+,d7
	or.w	(a6),d7
	tst.l	d7
	exit	ccr

;----------------------------------------------------------------
;$FEF9	__CFTST
;	4�o�C�g���������_����0�̔�r�����܂��B
;<(sp).s:4�o�C�g���������_��
;>z-flag:eq=0
;>n-flag:mi=��
fe_cftst::
	param	a6
	cmpi.l	#$80000000,(a6)
	beq	@f
	tst.l	(a6)
@@:	exit	ccr

;----------------------------------------------------------------
;$FEFA	__CDINC
;	8�o�C�g���������_����1�������܂��B
;<(sp).d:8�o�C�g���������_��
;>(sp).d:���Z����
fe_cdinc::
	param	a6
	fmove.d	(a6),fp0
	fadd.s	#0f1,fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFB	__CFINC
;	4�o�C�g���������_����1�������܂��B
;<(sp).s:4�o�C�g���������_��
;>(sp).s:���Z����
fe_cfinc::
	param	a6
	fmove.s	(a6),fp0
	fadd.s	#0f1,fp0
	fmove.s	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFC	__CDDEC
;	8�o�C�g���������_������1�������܂��B
;<(sp).d:8�o�C�g���������_��
;>(sp).d:���Z����
fe_cddec::
	param	a6
	fmove.d	(a6),fp0
	fsub.s	#0f1,fp0
	fmove.d	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFD	__CFDEC
;	4�o�C�g���������_������1�������܂��B
;<(sp).s:4�o�C�g���������_��
;>(sp).s:���Z����
fe_cfdec::
	param	a6
	fmove.s	(a6),fp0
	fsub.s	#0f1,fp0
	fmove.s	fp0,(a6)
	exit

;----------------------------------------------------------------
;$FEFE	__FEVARG
;	�g�ݍ��܂�Ă��鐔�l���Z�f�o�C�X�h���C�o�̎�ނ��Ɖ�܂��B
;	�g�ݍ��܂�Ă��鐔�l���Z�f�o�C�X�h���C�o�ɂ�莟�Ɏ����l���Ԃ�܂��B
;FLOAT1.X�̏ꍇ
;>d0.l:'HS86'($48533836)
;>d1.l:'SOFT'($534F4654)
;FLOAT2.X�̏ꍇ
;>d0.l:'IEEE'($49454545)
;>d1.l:'SOFT'($534F4654)
;FLOAT3.X�̏ꍇ
;>d0.l:'IEEE'($49454545)
;>d1.l:'FPCP'($46504350)
;FLOAT4.X�̏ꍇ
;>d0.l:'IEEE'($49454545)
;>d1.l:'FP20'($46503230)
fe_fevarg::
	move.l	#'IEEE',d0
	move.l	#'FPSP',d1
	exit

;----------------------------------------------------------------
;$FEFF	__FEVECS
;	���������_���Z�����̒ǉ��A�ύX�B
;<d0.l:FETBL�̔ԍ�
;<a0.l:�����A�h���X
;>d0.l:�O�̏����A�h���X
;	������d0�̒l��$FE00�`$FEFE�͈̔͂ł��B
;	����ȊO�̒l��n����d0��-1��Ԃ��܂��B
fe_fevecs::
	moveq.l	#-1,d0
	exit

;----------------------------------------------------------------
;�萔
pi:
	.dc.x	!40000000C90FDAA22168C235	;cr($00)=��
one:
	.dc.x	!3FFF00008000000000000000	;cr($32)=10^0

;	.dc.x	!40000000C90FDAA22168C235	;��
;	.dc.x	!3FFD0000A2F9836E4E44152A	;1/��
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

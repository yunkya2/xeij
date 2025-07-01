;----------------------------------------------------------------
;
;	_EXIT,_KEEPPR,_EXEC,_EXIT2
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;_EXIT		�v���Z�X�̏I��(�I���R�[�h�w��Ȃ�)
;���A���Ȃ�
	.text
	.align	4,$2048
dosExit::
	moveq.l	#0,d0
	bra	dosExitGo

;----------------------------------------------------------------
;_EXIT2		�v���Z�X�̏I��(�I���R�[�h�w�肠��)
;<(a6).w:�I���R�[�h
;���A���Ȃ�
	.text
	.align	4,$2048
dosExit2::
	moveq.l	#0,d0
	move.w	(a6),d0
dosExitGo:
	move.l	d0,$1CAE.w
	jsr	$0000A65A.l		;_ALLCLOSE
	movea.l	([$1C28.w]),a0
	jsr	$000092B8.l		;�v���Z�X���g���Ă����������u���b�N��,
					;���ׂĊJ�����Đe�v���Z�X�ɖ߂�
	movea.l	(pSsp,a0),sp		;ssp
	movea.l	(pUsp,a0),a5		;usp
	move.l	a5,usp
	clr.w	-(sp)
	move.l	(pExitvc,a0),-(sp)	;_EXITVC
	move.w	(p_Sr,a0),-(sp)		;sr
	movea.l	([$1C28.w]),a0		;�e�v���Z�X
	clr.l	(pChildPtr,a0)		;�q�v���Z�X�̃������Ǘ��e�[�u��
	jsr	$0000A11E.l		;�v���Z�X�Ǘ��̈ڍs�ɂƂ��Ȃ��x�N�^�ނ̐ݒ�(�풓�v���Z�X�ȊO)
	jsr	$00010134.l		;���Ȋ����ϊ��s�N���[�Y
	move.l	$1CAE.w,d0		;_EXIT,_KEEPPR,_EXIT2�̏I���R�[�h(��ʃ��[�h�͔�풓=0,�풓=1)
	clr.w	$1C08.w			;DOS�R�[���̃��x��
	rte

;----------------------------------------------------------------
;_KEEPPR	�v���Z�X�̏풓�I��(�������͊J�����Ȃ�)
;<(a6).l:�풓�T�C�Y(�v���O�����̐擪����풓�����̖����܂�)
;<4(a6).w:�I���R�[�h
;���A���Ȃ�
	.text
	.align	4,$2048
dosKeeppr::
	move.l	(a6)+,d1		;�풓�����̒���
	moveq.l	#1,d0
	swap.w	d0
	move.w	(a6),d0			;�I���R�[�h
	move.l	d0,$1CAE.w		;_EXIT,_KEEPPR,_EXIT2�̏I���R�[�h(��ʃ��[�h�͔�풓=0,�풓=1)
	movea.l	([$1C28.w]),a0		;���s���̃v���Z�X�̃������Ǘ��e�[�u��
	move.l	(Proc,a0),([$1C28.w])	;���s���̃v���Z�X�̃������Ǘ��e�[�u��
;�e�̃A�h���X�̍ŏ�ʃo�C�g�ɏ풓�t���O$FF����������
;�e���n�C�������ɂ���ƃA�h���X���j�󂳂��
;�e�͂��܂ł����݂Ƃ͌���Ȃ��̂ł��������H���Ă悢���ł͂Ȃ���
;�O�̂��ߎn�c�ł���Human68k�̃������Ǘ��e�[�u���̃A�h���X�����Ă���
	tst.b	(Proc,a0)
	beq	@f
	move.l	$1C20.w,(Proc,a0)	;Human�̃������Ǘ��e�[�u��
@@:	st.b	(Proc,a0)		;�풓�t���O��ݒ�
	add.l	a0,d1
	add.l	#$00000100,d1		;�풓�����̖���+1
	cmp.l	(Tail,a0),d1
	bcc	@f
	move.l	d1,(Tail,a0)
@@:	movea.l	(pSsp,a0),sp		;ssp
	movea.l	(pUsp,a0),a5		;usp
	move.l	a5,usp
	clr.w	-(sp)
	move.l	(pExitvc,a0),-(sp)	;_EXITVC
	move.w	(p_Sr,a0),-(sp)		;sr
	movea.l	([$1C28.w]),a0		;�e�v���Z�X
	clr.l	(pChildPtr,a0)		;�q�v���Z�X�̃������Ǘ��e�[�u��
	jsr	$0000A150.l		;�v���Z�X�Ǘ��̈ڍs�ɂƂ��Ȃ��x�N�^�ނ̐ݒ�(�풓�v���Z�X)
	jsr	$00010134.l		;���Ȋ����ϊ��s�N���[�Y
	move.l	$1CAE.w,d0		;_EXIT,_KEEPPR,_EXIT2�̏I���R�[�h(��ʃ��[�h�͔�풓=0,�풓=1)
	clr.w	$1C08.w			;DOS�R�[���̃��x��
	rte

;----------------------------------------------------------------
;_EXEC		�q�v���Z�X�̎��s
;<(a6).b:���W���[���ԍ�
;<1(a6).b:���[�h
;	0	�v���O�����̃��[�h����ю��s
;			<2(a6).l:���s�t�@�C����
;				�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;			<6(a6).l:�R�}���h���C��
;			<10(a6).l:���̃A�h���X(0�Ȃ�Ύ��s���̃v���Z�X�̊�)
;			>d0.l:�I���R�[�h(�풓�����Ƃ���ʃ��[�h=1)
;	1	�v���O�����̃��[�h
;			<2(a6).l:���s�t�@�C����
;				�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;			<6(a6).l:�R�}���h���C��
;			<10(a6).l:���̃A�h���X(0�Ȃ�Ύ��s���̃v���Z�X�̊�)
;			>d0.l:���s�J�n�A�h���X
;			>a0.l:�������Ǘ��e�[�u��
;			>a1.l:�v���O�����̖���+1
;			>a2.l:�R�}���h���C��
;			>a3.l:��
;			>a4.l:���s�J�n�A�h���X
;	2	���s�t�@�C������path����
;			<2(a6).l:���s�t�@�C�����ƃR�}���h���C��
;				�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;			<6(a6).l:�R�}���h���C���̃o�b�t�@
;			<10(a6).l:���̃A�h���X(0�Ȃ�Ύ��s���̃v���Z�X�̊�)
;			>d0.l:�G���[�R�[�h
;	3	���s�t�@�C���̃A�h���X�w�胍�[�h
;			<2(a6).l:���s�t�@�C����
;				�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;			<6(a6).l:���[�h�A�h���X
;			<10(a6).l:���~�b�g�A�h���X
;			>d0.l:text+data+bss+comm+stack�̃T�C�Y
;	4	���[�h�ς݂̃v���O�����̎��s
;			<2(a6).l:���s�J�n�A�h���X
;			>d0.l:�I���R�[�h(�풓�����Ƃ���ʃ��[�h=1)
;	5	���W���[���ԍ��̌���(�Ō�Ɍ����������W���[���ԍ���Ԃ�)
;			<2(a6).l:���s�t�@�C����
;			<6(a6).l:���W���[����
;			>d0.l:���W���[���ԍ�*$100
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec::
  debug '|exec in (module*256+mode,file,param,env)=',4,(-2,a6),(2,a6),(6,a6),(10,a6)

	move.b	(1,a6),d0
	beq	dosExec0
	subq.b	#1,d0
	beq	dosExec1
	subq.b	#2-1,d0
	beq	dosExec2
	subq.b	#3-2,d0
	beq	dosExec3
dosExecGo::
	move.l	vectorOldDosExec,-(sp)
	rts

;----------------------------------------------------------------
;����_EXEC���Ă�
	.text
	.align	4,$2048
callExec::
	move.l	a6,-(sp)
	lea.l	(8,sp),a6
	bsr	dosExecGo
	movea.l	(sp)+,a6
	movea.l	$1C5C.w,a5
	movem.l	(dosA0,a5),a0-a4
	rts

;----------------------------------------------------------------
;_EXEC���[�h0	�v���O�����̃��[�h����ю��s
;	�K�v�Ȃ�΃X���b�v�A�E�g���s��
;	�v���O���������[�h����LZX�W�J���s��
;	�_�C�i�~�b�N�p�b�`�����Ă�
;<(a6).b:���W���[���ԍ�
;<1(a6).b:0
;<2(a6).l:���s�t�@�C����
;	�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;<6(a6).l:�R�}���h���C��
;<10(a6).l:���̃A�h���X(0�Ȃ�Ύ��s���̃v���Z�X�̊�)
;>d0.l:�I���R�[�h(�풓�����Ƃ���ʃ��[�h=1)
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec0::
  debug '|exec0 in (file,param,env)=',3,(2,a6),(6,a6),(10,a6)
;���[�h
	move.l	(10,a6),-(sp)
	move.l	(6,a6),-(sp)
	move.l	(2,a6),-(sp)
	move.w	#1,-(sp)
	move.b	(a6),(sp)
	bsr	callExec
	lea	(14,sp),sp
	tst.l	d0
	bmi	dosExec0End
;LZX�W�J
	move.l	(Tail,a0),d6		;���~�b�g�A�h���X
	lea.l	(pProgram,a0),a5	;���[�h�A�h���X
	move.l	(pBssTop,a0),d5
	movea.l	(pStackTop,a0),a1
	bsr	unpackLzx
	move.l	d5,(pBssTop,a0)		;bss�̐擪
	move.l	d5,(pHeapTop,a0)	;�q�[�v�̐擪
	move.l	a1,(pStackTop,a0)	;�X�^�b�N�G���A�̐擪
	movea.l	$1C5C.w,a5
	movem.l	a0-a4,(dosA0,a5)
;�p�b�`�����Ă�
	bsr	dynamicPatch
;�L���b�V���t���b�V��
	bsr	cache_flush
;_EXEC���[�h4�Ŏ��s����
	move.l	a4,-(sp)
	move.w	#4,-(sp)
	bsr	callExec
	addq.l	#6,sp
dosExec0End:
	rts

;----------------------------------------------------------------
;_EXEC���[�h1	�v���O�����̃��[�h
;	�v���O���������[�h����LZX�W�J���s��
;	�_�C�i�~�b�N�p�b�`�����Ă�
;<(a6).b:���W���[���ԍ�
;<1(a6).b:1
;<2(a6).l:���s�t�@�C����
;	�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;<6(a6).l:�R�}���h���C��
;<10(a6).l:���̃A�h���X(0�Ȃ�Ύ��s���̃v���Z�X�̊�)
;>d0.l:���s�J�n�A�h���X
;>a0.l:�������Ǘ��e�[�u��
;>a1.l:�v���O�����̖���+1
;>a2.l:�R�}���h���C��
;>a3.l:��
;>a4.l:���s�J�n�A�h���X
;*d0/a0-a4,?d1-d7/a5-a6
	.text
	.align	4,$2048
dosExec1::
  debug '|exec1 in (file,param,env)=',3,(2,a6),(6,a6),(10,a6)
;���[�h
	move.l	(10,a6),-(sp)
	move.l	(6,a6),-(sp)
	move.l	(2,a6),-(sp)
	move.w	#1,-(sp)
	move.b	(a6),(sp)
	bsr	callExec
	lea	(14,sp),sp
	tst.l	d0
	bmi	dosExec1End
;LZX�W�J
	move.l	(Tail,a0),d6		;���~�b�g�A�h���X
	lea.l	(pProgram,a0),a5	;���[�h�A�h���X
	move.l	(pBssTop,a0),d5
	movea.l	(pStackTop,a0),a1
	bsr	unpackLzx
	move.l	d5,(pBssTop,a0)
	move.l	d5,(pHeapTop,a0)
	move.l	a1,(pStackTop,a0)
	movea.l	$1C5C.w,a5
	movem.l	a0-a4,(dosA0,a5)
;�p�b�`�����Ă�
	bsr	dynamicPatch
;�L���b�V���t���b�V��
	bsr	cache_flush
	move.l	a4,d0			;���s�J�n�A�h���X
dosExec1End:
  debug '|exec1 out (d0,a0,a1,a2,a3,a4)=',6,d0,a0,a1,a2,a3,a4
	rts

;----------------------------------------------------------------
;_EXEC���[�h2	���s�t�@�C������path����
;<1(a6).b:2
;<2(a6).l:���s�t�@�C�����ƃR�}���h���C��
;	�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;<6(a6).l:�R�}���h���C���̃o�b�t�@
;<10(a6).l:���̃A�h���X(0�Ȃ�Ύ��s���̃v���Z�X�̊�)
;>d0.l:�G���[�R�[�h
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec2::
;hupair�Ή�
	bra	dosExecGo

;----------------------------------------------------------------
;_EXEC���[�h3	���s�t�@�C���̃A�h���X�w�胍�[�h
;	�v���O���������[�h����LZX�W�J���s��
;<(a6).b:���W���[���ԍ�
;<1(a6).b:3
;<2(a6).l:���s�t�@�C����
;	�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;<6(a6).l:���[�h�A�h���X
;<10(a6).l:���~�b�g�A�h���X
;>d0.l:�T�C�Y
;*d0,?d1-d7/a0-a6
	.text
	.align	4,$2048
dosExec3::
  debug '|exec3 in (file,ptr,limit)=',3,(2,a6),(6,a6),(10,a6)
;���[�h
	move.l	(10,a6),-(sp)
	move.l	(6,a6),-(sp)
	move.l	(2,a6),-(sp)
	move.w	#3,-(sp)
	move.b	(a6),(sp)
	bsr	callExec
	lea	(14,sp),sp
	tst.l	d0
	bmi	dosExec3End
;LZX�W�J
	move.l	(10,a6),d6		;���~�b�g�A�h���X
	movea.l	(6,a6),a5		;���[�h�A�h���X
	lea.l	(a5,d0.l),a1		;����+1
	bsr	unpackLzx
	move.l	a1,d7			;����+1
	sub.l	a5,d7			;�v���O�����̃T�C�Y
;�p�b�`�����Ă�
;<a5.l:���[�h�A�h���X
;<d7.l:�v���O�����̃T�C�Y
	bsr	dynamicDevicePatch
;�L���b�V���t���b�V��
	bsr	cache_flush
	move.l	d7,d0			;�v���O�����̃T�C�Y
dosExec3End:
  debug '|exec3 out (size)=',1,d0
	rts

;----------------------------------------------------------------
;LZX�W�J
;<d6.l:���~�b�g�A�h���X
;<a0.l:�������Ǘ��e�[�u��
;<a1.l:����+1
;<a5.l:���[�h�A�h���X
;>d5.l:(�W�J�����Ƃ�)bss�̐擪
;>a1.l:����+1
;>a4.l:(�W�J�����Ƃ�)���s�J�n�A�h���X
;*d5/a1/a4,?d0-d2
	.text
	.align	4,$2048
unpackLzx::
;#HUPAIR LZX 0.42�̃`�F�b�N
	moveq.l	#0,d1
	moveq.l	#2,d2
	cmpi.l	#'#HUP',(2,a5)
	bne	@f
	cmpi.l	#'AIR'*$100,(6,a5)
	bne	@f
	moveq.l	#6,d1
	moveq.l	#84,d2
	cmpi.l	#'0.42',(14,a5)
	beq	@f
	moveq.l	#90,d2
	cmpi.l	#'1.04',(14,a5)
	bne	unpackLzxEnd
@@:
;LZX�w�b�_�̃`�F�b�N
	cmpi.l	#'LZX ',(4,a5,d1.w)
	bne	unpackLzxEnd
	cmpi.l	#'0.31',(8,a5,d1.w)
	bcs	unpackLzxEnd
	cmpi.l	#'1.04',(8,a5,d1.w)
	bhi	unpackLzxEnd
	cmpi.l	#'1.00',(8,a5,d1.w)
	bcc	unpackLzxGo		;ITA lzx�̂Ƃ��̓L���b�V��������ȗ�
;�L���b�V���f�B�Z�[�u��
	PUSH_CACR_DISABLE_BC	d0
	bsr	unpackLzxGo		;�W�J����
;�L���b�V�����[�h����
	POP_CACR	d0
unpackLzxEnd:
	rts

;�W�J����
unpackLzxGo:
	move.l	d6,(4,a5,d1.w)		;���~�b�g�A�h���X
	move.l	a5,(8,a5,d1.w)		;���[�h�A�h���X
	move.l	(14,a5,d1.w),-(sp)	;���s�J�n�ʒu�̃I�t�Z�b�g
	move.l	(18,a5,d1.w),d5		;text+data+bss�̃T�C�Y
	sub.l	(26,a5,d1.w),d5		;bss�̃T�C�Y
	lea.l	(@f,pc),a4		;�߂��
	jmp	(a5,d2.w)		;�W�J
@@:	add.l	a5,d5			;bss�̐擪
	movea.l	a5,a4			;�擪�A�h���X
	adda.l	(sp)+,a4		;�V�������s�J�n�A�h���X
	rts

;----------------------------------------------------------------
;_PSPSET�̒ǉ�
;<d3.l:text+data�̃T�C�Y
;<d6.l:�X�^�b�N�G���A�̃T�C�Y
;<a0.l:�������Ǘ��e�[�u��
;<a2.l:�R�}���h���C���̃A�h���X
;<a3.l:���̗̈�̃A�h���X
;>d0.l:0
;>a3.l:���̗̈�̃A�h���X(0�������Ƃ��e�v���Z�X�̊��̗̈�A�h���X������)
;>a5.l:DOS�R�[���Ƀ��x��0�œ������Ƃ���ssp
;*d0/a3/a5,?d3/a6
	.text
	.align	4,$2048
human302_makePsp::
	add.l	a0,d3
	add.l	#pProgram,d3
	movea.l	([$1C28.w]),a5		;���s���̃v���Z�X�̃������Ǘ��e�[�u��
	move.l	a0,(pChildPtr,a5)	;�q�v���Z�X�̃������Ǘ��e�[�u��
	move.l	d3,(pBssTop,a0)		;bss+comm+stack�̐擪
	move.l	d3,(pHeapTop,a0)	;�q�[�v�̐擪
	add.l	d6,d3
	move.l	d3,(pStackTop,a0)	;�X�^�b�N�G���A�̐擪
	cmpa.w	#0,a3
	bne	@f
	movea.l	(pEnvPtr,a5),a3		;���݂̊��̗̈�̃A�h���X
@@:	move.l	a3,(pEnvPtr,a0)		;���̗̈�̃A�h���X
	move.l	a2,(pCmdLinePtr,a0)	;�R�}���h���C���̃A�h���X
	lea.l	(pHandler,a0),a6
	clr.l	(a6)+			;�n���h���̎g�p��(12�o�C�g)
	clr.l	(a6)+			;
	clr.l	(a6)			;
	movea.l	$1C5C.w,a5		;DOS�R�[���Ƀ��x��0�œ������Ƃ���ssp
	move.l	(dosPC,a5),$1BC0.w	;pc��_EXITVC��
	lea.l	(dosSSP,a5),a6
	move.l	a6,(pSsp,a0)		;ssp
	move.l	usp,a6
	move.l	a6,(pUsp,a0)		;usp
	move.w	(dosSR,a5),(p_Sr,a0)	;sr
	clr.l	(pOsFlag,a0)		;OS�t���O(-1=Human���N��,0=���̑�)
	clr.l	(pChildPtr,a0)		;�q�v���Z�X�̃������Ǘ��e�[�u��
	jsr	$0000A0EC.l		;�������Ǘ��u���b�N�̐����ɂƂ��Ȃ��x�N�^�ނ̕ۑ�
	move.l	a0,([$1C28.w])		;���s���̃v���Z�X�̃������Ǘ��e�[�u��

	cmpi.b	#_EXEC-$FF00,$1C0A.w
	bne	@f

	move.b	deviceCacheNoPush,(pDeviceNoPush,a0)	;�f�o�C�X�Ăяo���ŃL���b�V���v�b�V�����邩
	move.b	defaultAllocArea,(pAllocArea,a0)	;�A���P�[�g�ł���̈�̏���
					;	0	���ʂ̂�
					;	1	��ʂ̂�
					;	2	�e�Ɠ������̂�
					;	3	�e�Ɣ��Α��̂�
					;	4	�����Ȃ�,���ʗD��
					;	5	�����Ȃ�,��ʗD��
					;	6	�����Ȃ�,�e�Ɠ������D��
					;	7	�����Ȃ�,�e�Ɣ��Α��D��
					;	8	�����Ȃ�,�D��Ȃ�
	move.b	#1,(pLoadCache,a0)	;�{�̂̃u���b�N�̃L���b�V�����[�h
	move.b	#1,(pAllocCache,a0)	;�A���P�[�g�����u���b�N�̃L���b�V�����[�h

@@:	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;_EXEC�̎��s�O�̏���
;	bss+comm+stack�̏�����
;	�v���Z�X�Ǘ��e�[�u���̍쐬
;<d1.w:0=�N������,0�ȊO=���W�X�^�̐ݒ�̂�
;<d3.l:text+data�̃T�C�Y
;<d6.l:�X�^�b�N�G���A�̃T�C�Y
;<a0.l:�������Ǘ��e�[�u��
;<a2.l:�R�}���h���C���̃A�h���X
;<a3.l:���̗̈�̃A�h���X
;<a4.l:���s�J�n�A�h���X
;$0000967E
	.text
	.align	4,$2048
human302_execMakePsp::

;bss+comm+stack������������
	lea.l	(pProgram.w,a0,d3.l),a1	;bss+comm+stack�̐擪�A�h���X
	move.l	d6,d0
	lsr.l	#2,d0
	beq	2f
1:	clr.l	(a1)+
	subq.l	#1,d0
	bne	1b
2:	moveq.l	#3,d0
	and.l	d6,d0
	beq	4f
3:	clr.b	(a1)+
	subq.l	#1,d0
	bne	3b
4:
;<a1.l:bss+comm+stack�̖���

	movem.l	d1/a1-a3,-(sp)

;_EXEC�̓��샌�x����-3�ɐݒ�
	move.b	#-3,$1CA0.w		;_EXEC�̓��샌�x��

;�v���Z�X�Ǘ��e�[�u�������
	bsr	human302_makePsp
;<a5.l:DOS�R�[���Ƀ��x��0�œ������Ƃ���ssp

;_EXEC�̓��샌�x����0�ɐݒ�
	clr.b	$1CA0.w			;_EXEC�̓��샌�x��

;�v���Z�X�Ǘ��e�[�u���Ƀ��W���[���ԍ���ݒ肷��
	move.b	$1CA1.w,(pModuleNumber,a0)	;_EXEC�ŋN�����郂�W���[���ԍ�

;�v���Z�X�Ǘ��e�[�u���Ƀp�X���ƃt�@�C������ݒ肷��
	lea.l	(-90,sp),sp
	movea.l	sp,a2
	move.l	a2,-(sp)
	move.l	$1CB2.w,-(sp)		;_EXEC�ŋN������t�@�C����
	DOS	_NAMESTS
	addq.l	#8,sp
	lea.l	(pPath,a0),a1
	lea.l	(nDrive,a2),a3		;�h���C�u�ԍ�
					;_NAMESTS���g���Ă���̂�,�����h���C�u�ԍ��ł͂Ȃ�
	moveq.l	#'A',d0
	add.b	(a3)+,d0		;�h���C�u��
	move.b	d0,(a1)+
	move.b	#':',(a1)+
;	lea.l	(nPath,a2),a3		;�p�X
@@:	move.b	(a3)+,(a1)+
	bne	@b
	lea.l	(pName,a0),a1
	lea.l	(nName1,a2),a3		;�t�@�C����1(�c���$20)
	moveq.l	#8-1,d0
1:	cmpi.b	#' ',(a3)
	beq	3f
	move.b	(a3)+,(a1)+
	dbra	d0,1b
	lea.l	(nName2,a2),a3		;�t�@�C����2(�c���$00)
	moveq.l	#10-1,d0
2:	tst.b	(a3)
	beq	3f
	move.b	(a3)+,(a1)+
	dbra	d0,2b
3:	lea.l	(nExt,a2),a3		;�g���q(�c���$20)
	cmpi.b	#' ',(a3)		;Human�͊g���q���Ȃ��Ă�'.'��t����
	beq	5f
	move.b	#'.',(a1)+
	moveq.l	#3-1,d0
4:	cmpi.b	#' ',(a3)
	beq	5f
	move.b	(a3)+,(a1)+
	dbra	d0,4b
5:	clr.b	(a1)
	lea.l	(90,sp),sp

;�v���Z�X�Ǘ��e�[�u���̊g������ݒ肷��
	lea.l	(pName,a0),a1
	move.l	(a1)+,d0
	or.l	#$20202020,d0
	cmp.l	#'comm',d0
	bne	@f
	move.l	(a1)+,d0
	or.l	#$20202000,d0
	cmp.l	#'and.',d0
	bne	@f
	move.w	(a1)+,d0
	or.w	#$2000,d0
	cmp.w	#'x'*256,d0
	bne	@f
	move.b	#8,(pAllocArea,a0)	;command.x�͐����Ȃ�,�D��Ȃ�
@@:

	movem.l	(sp)+,d1/a1-a3

;<d1.w:0=�N������,0�ȊO=���W�X�^�̐ݒ�̂�
;<a0.l:�������Ǘ��e�[�u��
;<a1.l:bss+comm+stack�̖���
;<a2.l:�R�}���h���C���̃A�h���X
;<a3.l:���̗̈�̃A�h���X
;<a4.l:���s�J�n�A�h���X
;<a5.l:DOS�R�[���Ƀ��x��0�œ������Ƃ���ssp

	jmp	$0000971E

;----------------------------------------------------------------
;�_�C�i�~�b�N�p�b�`�����Ă�(�f�o�C�X�h���C�o)
;<a5.l:���[�h�A�h���X
;<d7.l:�v���O�����̃T�C�Y
dynamicDevicePatch:
  .ifdef __DEBUG__
	movem.l	d1/a1,-(sp)
	moveq.l	#'[',d1
	jsr	debugPutc
	movea.l	$1CB2.w,a1
	jsr	debugPrint
	moveq.l	#']',d1
	jsr	debugPutc
	movem.l	(sp)+,d1/a1
  .endif
	bsr	rsdrv202
	rts

rsdrv202:
	movem.l	d0/a0-a1,-(sp)
	cmp.l	#$00000EA6,d7
	blo	9f
	lea.l	($00000E4C,a5),a0
	lea.l	(1f,pc),a1
	bsr	strcmp
	bne	9f

	lea.l	(2f,pc),a1
	move.w	(a1)+,d0
	lea.l	($00000D04,a5),a0
@@:	move.w	(a1)+,(a0)+
	dbra	d0,@b

9:	movem.l	(sp)+,d0/a0-a1
	rts

1:	.dc.b	$0D,$0A
	.dc.b	'RS-232C DRIVER for X68000 version 2.02',$0D,$0A
	.dc.b	'AUX0 ���� AUX5 �̃t�@�C�����ŁA�ʐM���\�ł�',$0D,$0A,$00
	.even

2:	.dc.w	(11f-10f)/2-1
10:	move.w	#2,-(sp)		;(a0)���烏�[�h�œǂ߂邩���ׂ郋�[�`��
	pea.l	(3f,pc)			;�_�~�[
	move.l	a0,-(sp)
	DOS	_BUS_ERR
	lea.l	(10,sp),sp
	tst.l	d0
	beq	@f
	moveq.l	#-1,d0
@@:	rts
3:	.ds.w	1
11:

;----------------------------------------------------------------
;�_�C�i�~�b�N�p�b�`�����Ă�
;<a0.l:�������Ǘ��|�C���^
;<a1.l:����+1
;<a4.l:���s�J�n�A�h���X
dynamicPatch:
  .ifdef __DEBUG__
	movem.l	d1/a1,-(sp)
	moveq.l	#'[',d1
	jsr	debugPutc
	movea.l	$1CB2.w,a1
	jsr	debugPrint
	moveq.l	#']',d1
	jsr	debugPutc
	movem.l	(sp)+,d1/a1
  .endif
;�v���O�����̃T�C�Y�̃`�F�b�N���K�{�Ȃ̂Œ��ӁI�I�I
;�p�b�`�𓖂Ă�v���O���������s���Ă��炻���菬�������̂𓮂�����,
;�����A�h���X�Ƀ��[�h����ăo�[�W�����i���o�[�Ȃǂ��c���Ă���\�������邽��
	bsr	patchLibcAladin
	bsr	pcm8a102

	tst.b	useJointMode
	beq	@f
	bsr	patchXclib		;XC�̃��C�u�����Ƀp�b�`�����Ă�
	bsr	history_x_110
	bsr	sxwin940507
	bsr	commandx
@@:
	rts

;libc-1.1.31 Release Aladin��_open()�Ƀf�o�b�O�p�b�`�����Ă�
patchLibcAladin:
	movem.l	d0-d1/a1-a2,-(sp)
;'Aladin',0,'1.1.31',0��T��
	move.l	(pBssTop,a0),d1		;bss�̐擪
	lea.l	(pProgram,a0),a1	;�v���O�����̐擪
	moveq.l	#0,d0
1:	cmpa.l	d1,a1
	bcc	9f			;libc-1.1.31�ł͂Ȃ�
	lsl.l	#8,d0
	move.b	(a1)+,d0
	cmpi.l	#'Alad',d0
	bne	1b
	movea.l	a1,a2
	cmpi.l	#('in'<<16)+0*256+'1',(a2)+	;��A�h���X�̉\��������
	bne	1b
	cmpi.l	#'.1.3',(a2)+		;��A�h���X�̉\��������
	bne	1b
	cmpi.w	#'1'*256,(a2)+		;��A�h���X�̉\��������
	bne	1b
;$FF44,$FFAC,$8004�̕��т�T��
	lea.l	(pProgram,a0),a1	;�v���O�����̐擪
1:	cmpa.l	d1,a1
	bcc	9f			;������Ȃ�����
	cmpi.w	#$FF44,(a1)+		;$FF44��T��
	bne	1b
	movea.l	a1,a2
	moveq.l	#64-1,d0		;64���[�h�ȓ���$FFAC��$8004�����邩
@@:	cmpi.w	#$FFAC,(a2)+		;$FFAC��T��
	dbeq	d0,@b
	bne	1b
@@:	cmpi.w	#$8004,(a2)+		;$8004��T��
	dbeq	d0,@b
	bne	1b
;��������
	move.w	#$8000,-(a2)		;$8004��$8000�ɕύX
;
9:	movem.l	(sp)+,d0-d1/a1-a2
	rts



history_x_110:
	movem.l	a0-a2,-(sp)
	lea.l	($000056E2,a0),a1
	cmpa.l	(pBssTop,a0),a1
	bhs	9f
	lea.l	($0100,a0),a2
	lea.l	($000056AE,a2),a0
	lea.l	(1f,pc),a1
	bsr	strcmp
	bne	9f
	cmpi.l	#$00C00000,($00004BFE,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C02,a2)
@@:
	cmpi.l	#$00C00000,($00004C1E,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C22,a2)
@@:
	cmpi.l	#$00C00000,($00004C34,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C38,a2)
@@:
	cmpi.l	#$00C00000,($00004C4E,a2)
	bne	@f
	move.l	#$4E71_4E71,($00004C52,a2)
@@:
9:	movem.l	(sp)+,a0-a2
	rts

1:	.dc.b	'X68k History v1.10 Copyright 1989-93 SHARP/Hudson',$0D,$0A,$00
	.even

sxwin940507:
	movem.l	a0-a2,-(sp)
	lea.l	($00002BB2,a0),a1
	cmpa.l	(pBssTop,a0),a1
	bhs	9f
	lea.l	($0100,a0),a2
	lea.l	($00002B9E,a2),a0
	lea.l	(1f,pc),a1
	bsr	strcmp
	bne	9f
	lea.l	($00002BA8,a2),a0
	lea.l	(2f,pc),a1
	bsr	strcmp
	bne	9f
	cmpi.l	#$00FFFFFF,($0000169E,a2)
	bne	9f
	cmpi.w	#_MALLOC,($000016A2,a2)
	bne	9f
	cmpi.l	#$00FFFFFF,($000016A8,a2)
	bne	9f
	cmpi.w	#_MALLOC,($000016BA,a2)
	bne	9f
	move.l	#LOGICAL_MASK,($0000169E,a2)
	move.w	#_MALLOC3,($000016A2,a2)
	move.l	#LOGICAL_MASK,($000016A8,a2)
	move.w	#_MALLOC3,($000016BA,a2)
@@:
9:	movem.l	(sp)+,a0-a2
	rts

1:	.dc.b	'SX_SHELL',$00
2:	.dc.b	'ver 3.10',$00
	.even


;	PCM8A.X 1.02��I/O�|�[�g�̃A�h���X�̏��8�r�b�g��$FF�ɂ��Ă���
;	�n�C�����������邾���œ����Ȃ��Ȃ邱�Ƃ�����̂Ńp�b�`�����Ă�
;<a0.l:�������Ǘ��|�C���^
;<a1.l:����+1
;<a4.l:���s�J�n�A�h���X
pcm8a102:
	movem.l	d0-d1/a0-a1,-(sp)
	lea.l	256(a0),a0		;�擪
	sub.l	a0,a1			;����
;�������m�F����
	cmpa.l	#$FF60,a1
	blo	99f
;�^�C�g�����m�F����
	cmpi.l	#'PCM8',$10F8(a0)
	bne	99f
	cmpi.l	#'A102',$10FC(a0)
	bne	99f
;57�ӏ����ׂ�$FF�ł��邱�Ƃ��m�F����
;XEiJ�����Ƀp�b�`�����ĂĂ��邩���m��Ȃ�
	moveq.l	#0,d0
	lea.l	100f(pc),a1
	moveq.l	#57-1,d1
10:	move.w	(a1)+,d0		;�[���g��
	cmpi.b	#$FF,(a0,d0.l)
	dbne	d1,10b
	bne	99f
;57�ӏ����ׂ�$00�ɏ���������
;	moveq.l	#0,d0
	lea.l	100f(pc),a1
	moveq.l	#57-1,d1
20:	move.w	(a1)+,d0		;�[���g��
	clr.b	(a0,d0.l)
	dbra	d1,20b
99:	movem.l	(sp)+,d0-d1/a0-a1
	rts

100:	.dc.w	$0138,$01F6,$0394,$11EC,$120A,$1400,$1814,$1870,$1882,$188A
	.dc.w	$1892,$18A2,$18A8,$18CA,$18D4,$18E0,$18E8,$1908,$19E4,$1AFA
	.dc.w	$1B58,$1B7C,$1BAC,$1C38,$1CCC,$21F8,$2250,$2258,$2290,$22A6
	.dc.w	$22B0,$22C0,$22C8,$22DE,$22EA,$30C8,$30DE,$30E6,$30EA,$30F6
	.dc.w	$3112,$3188,$334C,$338A,$33A2,$33C4,$33D0,$341A,$3428,$3496
	.dc.w	$34A6,$34D6,$FE0E,$FEC8,$FEEC,$FF46,$FF4E


;<a0.l:�������Ǘ��|�C���^
;<a1.l:����+1
;<a4.l:���s�J�n�A�h���X
commandx:
	movem.l	a0,-(sp)
	lea.l	256(a0),a0
	suba.l	a0,a1
	cmpa.l	#$12A0,a1
	blo	99f
	cmpi.l	#'Comm',$000C(a0)
	bne	99f
	cmpi.l	#'and2',$0010(a0)
	bne	99f
	cmpi.l	#'.03H',$0014(a0)
	bne	99f
	cmpi.w	#'u'*$100,$0018(a0)
	bne	99f
;�Ǐ�@�n�C�������Ŏ��s�����Ƃ��u�풓�����ǂݍ��߂܂���v���o��
;�����@EXEC(3)�ɓn���t�@�C�����̍ŏ�ʃo�C�g��x�`����$03��or���Ă���
;�΍�@$03��or�����$00��or����ɕύX����
	cmpi.l	#$00170003,$220(a0)	;ori.b #$03,(sp)
	bne	@f
	move.l	#$00170000,$220(a0)	;ori.b #$00,(sp)
@@:
;�Ǐ�@��c���n�C�������ɂ���Ə풓����������ꂸ�풓�������ʂɑ�����
;�����@�ŏ�ʃo�C�g��$00�łȂ��Ƃ�����ȏ�k��Ȃ�
;�΍�@�ŏ�ʃo�C�g��$00�łȂ��Ƃ����ŏ�ʃr�b�g��0�łȂ��Ƃ��ɕύX����
	cmpi.l	#$4A016608,$26C(a0)	;tst.b d1;bne (*)+10
	bne	@f
	move.l	#$4A016B08,$26C(a0)	;tst.b d1;bmi (*)+10
@@:
99:	movem.l	(sp)+,a0
	rts


;----------------------------------------------------------------
1:	cmpm.b	(a1)+,(a0)+
	bne	2f
;�������r(�啶���Ə���������ʂ���)
;<a0.l:��r����镶����
;<a1.l:��r���镶����
;>z-flag:eq=��v,ne=�s��v
;>c-flag:hs=(a0)>=(a1),lo=(a0)<(a1)
;?a0-a1
	.text
	.align	4,$2048
strcmp::
	tst.b	(a1)
	bne	1b
	tst.b	(a0)
2:	rts

;----------------------------------------------------------------
;������A��
;<a0.l:�A������镶����
;<a1.l:�A�����镶����
	.text
	.align	4,$2048
strcat::
	bsr	strtail
;----------------------------------------------------------------
;������R�s�[
;<a0.l:�R�s�[��
;<a1.l:�R�s�[��
strcpy::
@@:	move.b	(a1)+,(a0)+
	bne	@b
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;������̖����܂ŃX�L�b�v
;<a0.l:������
;>a0.l:������̖�����0�̈ʒu
	.text
	.align	4,$2048
strtail::
@@:	tst.b	(a0)+
	bne	@b
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;�������r(�啶���Ə���������ʂ��Ȃ�)
;<a0.l:��r����镶����
;<a1.l:��r���镶����
;>z-flag:eq=��v,ne=�s��v
;>c-flag:hs=(a0)>=(a1),lo=(a0)<(a1)
;?a0-a1
	.text
	.align	4,$2048
strcmpi::
	move.l	d1,-(sp)
	clr.b	d1
1:	tst.b	(a1)
	beq	5f
	move.b	(a0)+,d0
	tas.b	d1
	bne	3f			;2�o�C�g��
	cmp.b	#'A',d0
	blo	3f			;1�o�C�g�ڂ�'A'�`'Z'�ȊO
	cmp.b	#'Z',d0
	bhi	2f			;1�o�C�g�ڂ�'A'�`'Z'�ȊO
	or.b	#$20,d0			;'A'�`'Z'��������������
	bra	3f

2:	tst.b	d0
	bpl	3f			;$00�`$7F:1�o�C�g�R�[�h
	cmp.b	#$A0,d0
	blo	4f			;$80�`$BF:2�o�C�g�R�[�h��1�o�C�g��
	cmp.b	#$E0,d0
	bhs	4f			;$E0�`$FF:2�o�C�g�R�[�h��1�o�C�g��
3:	clr.b	d1			;1�o�C�g�R�[�h
4:	cmp.b	(a1)+,d0
	beq	1b
	bra	6f

5:	tst.b	(a0)
6:	movem.l	(sp)+,d1		;�t���O�ی�
	rts

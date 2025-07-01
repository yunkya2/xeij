;----------------------------------------------------------------
;
;	Human302�̃p�b�`���[�`��(�풓��)
;
;----------------------------------------------------------------

	.include	t00iocs.equ
	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;Trap#10
;ROM��V�X�e�������[�J���������ɃR�s�[���Ďg���Ă���Ƃ��̃\�t�g���Z�b�g�΍�
	.text
	.align	4,$2048
humanTrap10::
	movem.l	d0-d1/a0,-(sp)
	PUSH_SR_DI
;�x�N�^�e�[�u������
	tst.b	localSystemArea
	beq	2f
	movec.l	dfc,d1
	moveq.l	#FC_MMU_DATA,d0
	movec.l	d0,dfc
	suba.l	a0,a0
1:	move.l	(a0),d0			;���݂̃f�[�^
	moves.l	d0,(a0)+		;�{���̃A�h���X�ɖ߂�
	cmpa.l	mainLowerStart,a0
	blo	1b
	movec.l	d1,dfc
2:
;�L���b�V���@�\��~
	moveq.l	#0,d0
	movec.l	d0,cacr
	bsr	cache_flush
;MMU�@�\��~
	tst.b	noTranslation
	bne	99f
;		  E  P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
;		  15 14 13 12  11   10   98  76  5   43  21
	move.l	#%0__0__0__0___0____0____10__00__0___00__00_0,d0
	movec.l	d0,tc
	pflusha
;�g�����X�y�A�����g�ϊ��@�\��~
;	moveq.l	#0,d0
	movec.l	d0,itt0
	movec.l	d0,itt1
	movec.l	d0,dtt0
	movec.l	d0,dtt1
99:
	POP_SR
	movem.l	(sp)+,d0-d1/a0
	jmp	([vectorOldHumanTrap10])

;----------------------------------------------------------------
;�X�[�p�[�o�C�U�̈�ݒ�
;EXCONFIG�̎��s�J�n�O��SHELL�̋N���O�ɌĂ΂�郋�[�`��
;�������ADEVICE�őg�ݍ��ތ���AEXCONFIG�̎��s�J�n�O�ɂ͋@�\���Ȃ�
;HUMAN.SYS�Ƀo�C���h�����ꍇ��EXCONFIG�̎��s�J�n�O�ɂ��g�p����邱�ƂɂȂ�
;����͗̈�ݒ��͏풓���Ă���K�v���Ȃ����A�Ō�̃f�o�C�X�h���C�o��o�^����܂�
;�c���Ă��Ȃ��ƍ���̂ŏ풓���ɒu��
;�ύX�O
;	$00006A96:
;		move.l	$1C24.w,d0		;�󂫃G���A�̐擪�A�h���X
;		add.l	#$00001FFF,d0
;		and.l	#$00FFE000,d0
;		move.l	d0,$0000837A		;Human�̖����̃A�h���X+1
;		lsr.l	#8,d0
;		lsr.l	#5,d0
;		subq.w	#1,d0
;		cmp.w	#$0100,d0
;		bcs.s	$00006ABA
;		moveq.l	#$FF,d0
;	$00006ABA:
;		move.b	d0,$00E86001
;		rts
;$00006A96
	.text
	.align	4,$2048
human302_superarea::
	movem.l	d1-d4/a0-a1,-(sp)
	moveq.l	#0,d4
  debug '|IOCS($92-$93)=',2,$0192.w*4.w,$0193*4.w
	move.l	$1C24.w,d2		;�󂫃G���A�̐擪�A�h���X
	add.l	#$00001FFF,d2		;�y�[�W�T�C�Y�Ɋւ�炸8KB�P�ʂɐ؂�グ��
	and.l	#LOGICAL_MASK.and.$FFFFE000,d2
	move.l	d2,([$1C20.w],Tail)	;Human�̖����̃A�h���X+1
	move.l	d2,d0
	lsr.l	#8,d0
	lsr.l	#5,d0
	subq.l	#1,d0
	cmp.w	#$00FF,d0
	bls	@f
	move.w	#$00FF,d0
@@:	move.b	d0,$00E86001		;�X�[�p�[�o�C�U�G���A�ݒ�
	suba.l	a1,a1
;�w�肳�ꂽ�̈���X�[�p�[�o�C�U�v���e�N�g����
;<d2.l:�T�C�Y(�y�[�W�T�C�Y�̔{��)
;<a1.l:�擪�A�h���X(�y�[�W�̐擪)
	tst.b	noTranslation
	bne	99f
	PUSH_MMU_SFC_DFC	d0
	add.l	a1,d2
@@:	bsr	getDesc
	bset.l	#PD_S_BIT,d0
	moves.l	d0,(a0)
	pflusha
	adda.l	pageOffsetSize,a1
	cmpa.l	d2,a1
	blo	@b
	POP_SFC_DFC	d0
;
	tst.l	d4
	bne	@f
	moveq.l	#1,d4
	pea.l	(crlfMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
@@:
	pea.l	(superareaMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
99:

;���[�U���[�h�̗̈��1�y�[�W�������m�ۂ���
	move.l	([$1C20.w],Tail),d0	;Human�̖����̃A�h���X+1
	move.l	d0,userAreaWork
	add.l	#PAGE_OFFSET_SIZE,d0
	move.l	d0,([$1C20.w],Tail)	;Human�̖����̃A�h���X+1

;�g�����[�h
	tst.l	([$1C20.w],Next)
	bne	1f
	move.l	mainMemorySize,d2	;���C���������T�C�Y�̎w��(MB�̔{��)
	bmi	1f
	cmp.l	([$1C20.w],Tail),d2
	bhi	@f
	move.l	([$1C20.w],Tail),d2	;�f�o�C�X�̖���(�y�[�W�T�C�Y�̔{��)
	move.l	d2,mainMemorySize	;�f�o�C�X�̖��������Z���ł��Ȃ�
@@:
;<d2.l:���C���������̃T�C�Y
	move.l	$1C00.w,d0
	and.l	pageMask,d0		;���̃f�o�C�X���؂�l�߂��\��������̂�
					;�y�[�W�T�C�Y�ɐ؂蒼��
	cmp.l	d0,d2
	bhi	1f			;�s���̂Ƃ�(���Ή�)
;�g�����s
	move.l	d0,$1C00.w		;���̃f�o�C�X���m�ۂ����̈悩��
					;�y�[�W�T�C�Y�܂Ő؂艺����

	sub.l	d2,d0
	cmp.l	#128*1024,d0		;���C����������128KB�ɖ����Ȃ��Ƃ���,
	bcc	@f			;���[�h�ƃA���P�[�V�����̗̈����ʂ݂̂ɂ���
	move.b	#1,defaultLoadArea
	move.b	#1,defaultAllocArea
@@:

	movea.l	himemAreaEnd,a1		;�n�C�������̈�̌��݂̖���
	tst.l	himemAreaSize
	bne	5f			;�n�C�������̈悪����
	movea.l	localUpperStart,a1	;���[�J���������̖������f�X�N���v�^�܂���ROM�̐擪
	tst.l	localMemorySize
	bne	4f			;���[�J���������͂��邪�n�C�������̈悪�Ȃ��̂�
					;himemAreaStart��ݒ肷��
	movea.l	#$10000000,a1		;���[�J�����������Ȃ��Ƃ�
4:	move.l	a1,himemAreaStart	;�n�C�������̈悪�Ȃ��̂�himemAreaStart��ݒ肷��
5:
;<d2.l:�ړ����̐擪
;<a1.l:�ړ���̐擪
	move.l	d2,-(sp)		;�ړ����̐擪
					;������  �f�X�N���v�^
					;d2��a1
	PUSH_MMU_SFC_DFC	d0
2:	move.l	a1,d3			;d2��d3/a1
	movea.l	d2,a1			;d2/a1��d3
;	bsr	invDesc			;�ړ����̃f�X�N���v�^����������
	move.l	userAreaWork,d2
;		  UR G U1U0 S CM M U W PDT
	or.l	#%00_1__00__0_00_0_0_0_01,d2
	bsr	setDesc			;���[�U���[�h�̃��[�N�G���A�����蓖�Ă�
	move.l	d0,d2			;a1��d3  d2
	exg.l	d3,a1			;d3��a1  d2
	bsr	setDesc			;�ړ���ɐݒ肷��
	pflusha
  debug '|�g�����[�h setDesc(a1,d2,d0)=',3,a1,d2,d0
	move.l	d3,d2			;d2��a1
	move.l	pageOffsetSize,d0
	add.l	d0,d2
	adda.l	d0,a1
	add.l	d0,himemAreaSize
	cmp.l	$1C00.w,d2		;���̃f�o�C�X���m�ۂ����̈�̎�O�܂�
	blo	2b
	POP_SFC_DFC	d0
	move.l	a1,himemAreaEnd		;�n�C�������̗̈��L�΂�
	move.l	(sp)+,$1C00.w		;�ړ����̐擪����؂�̂Ă�
;�n�C�������̈�̐擪�̃u���b�N��ݒ肷��
	movea.l	himemAreaStart,a0
	lea.l	(User,a0),a1
	cmpi.l	#'060t',(a1)
	beq	3f			;����������Ă���
	move.l	#'060t',(a1)+
	move.l	#'urbo',(a1)+
	move.l	#'HIME',(a1)+
	move.l	#'M'<<24,(a1)+
	clr.l	(Prev,a0)
	move.l	$1C20.w,(Proc,a0)	;Human�̃������Ǘ��|�C���^
	move.l	a1,(Tail,a0)
	clr.l	(Next,a0)
3:
	tst.l	d4
	bne	@f
	moveq.l	#1,d4
	pea.l	(crlfMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
@@:
	pea.l	(extendedMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
1:

;�������[�h
	tst.l	([$1C20.w],Next)
	bne	1f
	tst.b	useJointMode
	beq	1f
	tst.l	himemAreaSize
	beq	1f
	move.l	$1C20.w,jointBlockHeader
	movea.l	$1C00.w,a0
	cmpa.l	([$1C20.w],Tail),a0
	beq	2f			;�f�o�C�X�h���C�o�̌������ׂĉ����o�����̂�
					;�W���C���g�u���b�N�����Ȃ�
	suba.l	jointBlockSize,a0
	lea.l	(-User,a0),a0
	move.l	a0,jointBlockHeader
	move.l	a0,([$1C20.w],Next)
	move.l	$1C20.w,(a0)+		;Prev
	move.l	$1C20.w,(a0)+		;Proc
	addq.l	#4,a0
	clr.l	(a0)+			;Next
	move.l	#'join',(a0)+
	move.l	#'tBlo',(a0)+
	move.w	#'ck',(a0)+
2:	movea.l	jointBlockHeader,a0	;�W���C���g�u���b�N�܂���Human�̐擪
	move.l	himemAreaStart,d0
	move.l	d0,(Tail,a0)
	move.l	d0,$1C00.w
;�������[�h�ɂ���
	tst.b	jointMode
	beq	1f
	sf.b	jointMode		;��U�N���A����
	bsr	sysStat_C001		;�������[�h��
	tst.l	d0
	bmi	1f
	tst.l	d4
	bne	@f
	moveq.l	#1,d4
	pea.l	(crlfMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
@@:
	pea.l	(jointMessage,pc)
	DOS	_PRINT
	addq.l	#4,sp
1:

;
  debug '|$1C00.w=',1,$1C00.w
  debug '|#deviceHeader=',1,#deviceHeader
  debug '|#vectorTable=',1,#vectorTable
  debug '|mainLower(Start,End)=',2,mainLowerStart,mainLowerEnd
  debug '|mainUpper(Start,End)=',2,mainUpperStart,mainUpperEnd
  debug '|localLower(Start,End)=',2,localLowerStart,localLowerEnd
  debug '|localUpper(Start,End)=',2,localUpperStart,localUpperEnd
  debug '|dosBusErr(Vbr,Ssp)=',2,dosBusErrVbr,dosBusErrSsp
  debug '|localRom(Start,End)=',2,localRomStart,localRomEnd
  debug '|localSystem(Start,End)=',2,localSystemStart,localSystemEnd
  debugKeyWait
  debug '|pageIndex(Width,Size,Mask)=',3,pageIndexWidth,pageIndexSize,pageIndexMask
  debug '|pageOffset(Width,Size,Mask)=',3,pageOffsetWidth,pageOffsetSize,pageOffsetMask
  debug '|pageMask=',1,pageMask
  debug '|pageDesc(Size,Mask)=',2,pageDescSize,pageDescMask
  debug '|descArea(Start,End,Size)=',3,descAreaStart,descAreaEnd,descAreaSize
  debug '|desc(Head,Tail)=',2,descHead,descTail
  debug '|rootDesc(Head,Tail)=',2,rootDescHead,rootDescTail
  debug '|pointerDesc(Head,Tail)=',2,pointerDescHead,pointerDescTail
  debug '|pointerCounterHead=',1,pointerCounterHead
  debug '|pageCounterTail=',1,pageCounterTail
  debugKeyWait
  debug '|tempBuffer(Start,End,Size)=',3,tempBufferStart,tempBufferEnd,tempBufferSize
  debug '|localMemory(Start,End,Size)=',3,localMemoryStart,localMemoryEnd,localMemorySize
  debug '|himemArea(Start,End,Size)=',3,himemAreaStart,himemAreaEnd,himemAreaSize
  debug '|mainMemorySize=',1,mainMemorySize
  debug '|jointBlock(Header,Size)=',2,jointBlockHeader,jointBlockSize
  debug '|jointBlockHeader(Prev,Proc,Tail,Next)=',4,([jointBlockHeader],Prev),([jointBlockHeader],Proc),([jointBlockHeader],Tail),([jointBlockHeader],Next)
  debug '|exclusive(Start,End)=',2,exclusiveStart,exclusiveEnd
  debug '|#xTable=',1,#xTable
  debug '|#mainExclusive=',1,#mainExclusive
  debug '|localRamdiskArea(Start,End,Size)=',3,localRamdiskAreaStart,localRamdiskAreaEnd,localRamdiskAreaSize
  debug '|mainRamdiskArea(Start,End,Size)=',3,mainRamdiskAreaStart,mainRamdiskAreaEnd,mainRamdiskAreaSize
  debug '|#bpbTablePointer=',1,#bpbTablePointer
  debug '|#bpbTable=',1,#bpbTable
  debugKeyWait
	movem.l	(sp)+,d1-d4/a0-a1
	rts

superareaMessage:
	.dc.b	'�n�r���X�[�p�[�o�C�U�ی삵�܂���',13,10,0
extendedMessage:
	.dc.b	'�g�����[�h�ɐ؂�ւ��܂���',13,10,0
jointMessage:
	.dc.b	'���[�J�����������������܂���'
crlfMessage:
	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;_EXIT,_KEEPPR,_EXIT2	�v���Z�X���g���Ă����������u���b�N�̊J��
;���s���̃v���Z�X���g���Ă����������u���b�N�����ׂĊJ������
;�e�v���Z�X�ɖ߂�
;�q�v���Z�X���m�ۂ����u���b�N�����ׂĊJ������
;�ύX�O
;	�v���Z�X���g���Ă����������u���b�N�����ׂĊJ�����e�v���Z�X�ɖ߂�
;	<a0.l:���s���̃v���Z�X�̃������Ǘ��|�C���^
;	$000092B8
;		movem.l	d0-d1/a0-a2,-(sp)
;		movea.l	$0000.w(a0),a1
;		move.l	a1,d0			;�擪�̃������u���b�N��Human�Ȃ̂ŊJ�����Ȃ�
;		beq.s	$000092E0
;		move.l	$000C(a0),d0
;		move.l	d0,$000C(a1)
;		beq.s	$000092D4
;		movea.l	d0,a2
;		move.l	a1,$0000.w(a2)
;	$000092D4:
;		move.l	$0004(a0),$00013D0A	;���s���̃v���Z�X�̃������Ǘ��e�[�u��
;		move.l	a0,d0
;		bsr.s	$000092E6		;�v���Z�X���g���Ă����������u���b�N�̊J��
;	$000092E0:
;		movem.l	(sp)+,d0-d1/a0-a2
;		rts
;
;	�q�v���Z�X���g���Ă����������u���b�N�̊J��
;	<d0.l:�J������e�v���Z�X�̃������Ǘ��|�C���^
;	$000092E6:
;		move.l	$1C04.w,d1		;_MALLOC�ł��郁������Ԃ̐擪�A�h���X
;	$000092EA:
;		movea.l	d1,a0
;		move.l	$000C(a0),d1
;		beq.s	$00009310
;		cmp.l	$0004(a0),d0
;		bne.s	$000092EA
;		tst.l	$0000.w(a0)
;		beq.s	$0000932A
;		movea.l	$0000.w(a0),a1
;		move.l	d1,$000C(a1)
;		movea.l	d1,a2
;		move.l	a1,$0000.w(a2)
;		bsr.s	$0000931E
;		bra.s	$000092E6		;�v���Z�X���g���Ă����������u���b�N�̊J��
;
;	$00009310:
;		cmp.l	$0004(a0),d0
;		bne.s	$0000932A
;		movea.l	$0000.w(a0),a1
;		move.l	d1,$000C(a1)
;	$0000931E:
;		movem.l	d0-d1,-(sp)
;		move.l	a0,d0
;		bsr.s	$000092E6		;�v���Z�X���g���Ă����������u���b�N�̊J��
;		movem.l	(sp)+,d0-d1
;	$0000932A:
;		rts
;<a0.l:���s���̃v���Z�X�̃������Ǘ��|�C���^
	.text
	.align	4,$2048
human302_exitfreepat::
	movem.l	d0/d2/d4/a4-a5,-(sp)
	tst.l	(Prev,a0)
	beq	9f			;Human���g�Ȃ�Ή������Ȃ�
	movea.l	$1C04.w,a4		;��������Ԃ̐擪
	movea.l	$1C00.w,a5		;��������Ԃ̖���+1
	move.l	a0,d4
	bsr	psfree			;���s���̃v���Z�X���m�ۂ����u���b�N���J������
					;�q�v���Z�X���m�ۂ����u���b�N���J������
	move.l	(Proc,a0),([$1C28.w])
	move.l	a0,d2
	add.l	#User,d2
	bsr	free			;�������g���J������
9:	movem.l	(sp)+,d0/d2/d4/a4-a5
	rts

;----------------------------------------------------------------
;_EXEC	[3]���s�t�@�C���̌`���w��
;�ύX�O
;	$00009510
;	_dos_exec_3_x:
;		bsr.w	$0000997C		;���s�t�@�C�����̊g���q�̐擪�̕����������������ĕԂ�
;		cmp.b	#'x',d0
;		beq.s	_dos_exec_3_x
;		cmp.b	#'r',d0
;		beq.s	_dos_exec_3_r
;		cmp.b	#'z',d0
;		beq.s	_dos_exec_3_z
;		move.l	a1,d0
;		rol.l	#8,d0
;	$0000952A
;$00009510
	.text
	.align	4,$2048
human302_exec3pat::
	bsr	human302_exec013pat
	jmp	$0000952A.l

;----------------------------------------------------------------
;_EXEC	[0][1]���s�t�@�C���̌`���w��
;�ύX�O
;	$0000961A
;	_dos_exec_01::
;		move.l	a1,$1CB2.w		;_EXEC�ŋN������t�@�C����
;		bsr.w	$0000997C		;���s�t�@�C�����̊g���q�̐擪�̕����������������ĕԂ�
;		cmp.b	#'x',d0
;		beq.w	_dos_exec_01_x
;		cmp.b	#'r',d0
;		beq.w	_dos_exec_01_r
;		cmp.b	#'z',d0
;		beq.s	_dos_exec_01_z
;		move.l	a1,d0
;		rol.l	#8,d0
;	$0000963C
;$0000961A
	.text
	.align	4,$2048
human302_exec01pat::
	bsr	human302_exec013pat
	move.l	a1,$1CB2.w		;_EXEC�ŋN������t�@�C����
	jmp	$0000963C.l

;----------------------------------------------------------------
;_EXEC	[0][1][3]���s�t�@�C���̌`���w��
;	�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g�Ŏ��s�t�@�C���̌`�����w��ł���
;	�w������g���q�̕����D�悷��
;<a1.l:�t�@�C�����̃A�h���X
;	�ŏ�ʃo�C�g�͎��s�t�@�C���̃^�C�v(0=�g���q,1=r,2=z,3=x)
;>d0.l:���s�t�@�C���̌`��(0=�s��,1=r,2=z,3=x)
;>a1.l:�t�@�C�����̃A�h���X
;	�ŏ�ʃo�C�g���C������Ă���
	.text
	.align	4,$2048
human302_exec013pat::
;���s�t�@�C���̌`���̎w����擾���A�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g���C������
	move.l	a1,-(sp)
	moveq.l	#LOGICAL_MASK>>24,d0
	and.b	(sp),d0			;�t�@�C�����̍ŏ�ʃo�C�g
	beq	@f
	cmp.b	#3,d0
	bls	1f			;�t�@�C�����̍ŏ�ʃo�C�g��1�`3
;�t�@�C�����̍ŏ�ʃo�C�g��4�ȏ�
	tst.l	himemAreaSize
	beq	4f
	move.l	(sp),d0
	cmp.l	himemAreaEnd,d0
	blo	3f
	cmp.l	#$14000000,d0
	blo	2f
3:	moveq.l	#0,d0
	bra	@f

;�t�@�C�����̍ŏ�ʃo�C�g�����[�J��������
2:	rol.l	#8,d0
4:	and.l	#$00000003,d0
;�t�@�C�����̍ŏ�ʃo�C�g���C������
1:	movea.l	$1C5C.w,a1
	move.b	(dosPC,a1),(sp)		;pc�̍ŏ�ʃo�C�g��₤
@@:	movea.l	(sp)+,a1		;�ŏ�ʃo�C�g���C������Ă���
;<d0.l:���s�t�@�C���̌`���̎w��(0=�g���q,1=r,2=z,3=x)
;<a1.l:�ŏ�ʃo�C�g���C�����ꂽ�t�@�C�����̃A�h���X
	move.l	d0,-(sp)
	jsr	$0000997C.l		;�t�@�C�����̊g���q�̐擪�̕����������������ĕԂ�
;>d0.b:�g���q�̐擪�̕���������������������(�g���q���Ȃ����0)
	cmp.b	#'x',d0
	beq	3f
	cmp.b	#'r',d0
	beq	1f
	cmp.b	#'z',d0
	beq	2f
;�g���q�ł͌����������Ȃ��̂Ŏw��ɏ]��
	move.l	(sp)+,d0
	rts

;R�`��
1:	moveq.l	#1,d0
	addq.l	#4,sp
	rts

;Z�`��
2:	moveq.l	#2,d0
	addq.l	#4,sp
	rts

;X�`��
3:	moveq.l	#3,d0
	addq.l	#4,sp
	rts



.comment !!!

;	�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g��
;	�E$00�̂Ƃ�
;		�`��0��move(�܂���and)����Ă���\��������
;	�E$01�`$03�̂Ƃ�
;		�`��1�`3��move(�܂���0��add�܂���or)����Ă���\��������
;	�E�n�C�������̉���+1�ȏ�A�n�C�������̏��+3�ȉ��̂Ƃ�
;		�`��1�`3��add����Ă���\��������
;	�E�n�C�������̉���|1�ȏ�A�n�C�������̏��|3�ȉ��ŉ���2�r�b�g��0�łȂ��Ƃ�
;		�`��1�`3��or����Ă���\��������
;
;	�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g�̕��������݂�
;	�����ł������ǂ����͈ȉ��̏����Ŕ��ʂ���
;	�E�A�h���X���A�N�Z�X�ł��邩�ǂ���(�͈͓����ǂ���)
;	�E�t�@�C�����Ƃ��Đ��������ǂ���
;	�E�t�@�C�������݂��ď��Ȃ��Ƃ�2�o�C�g�ǂݍ��߂邩�ǂ���
;	�ŏ��ɂ��̂܂܂̏�ԂŎ���
;	�`����move����Ă���\��������Ƃ���pc�����sp�̍ŏ�ʃo�C�g�̑O�������
;	�`����add�܂���or����Ă���\��������Ƃ��͂��̉\��������͈͂�����
;
;	�ȉ��̏ꍇ�̓t�@�C���̐擪2�o�C�g�Ō`���𔻕ʂ���
;	�E�`���̎w�肪�Ȃ��Ċg���q��R,Z,X�̂�����ł��Ȃ��ꍇ
;	�E�t�@�C�����̃A�h���X�𕜌��ł������`����add�����̂�or�����̂��킩��Ȃ��ꍇ
;	�t�@�C���̐擪2�o�C�g��
;	�E'HU'�̂Ƃ�
;		X�`���̎��s�t�@�C��
;	�E$601A�̂Ƃ�
;		Z�`���̎��s�t�@�C��
;	�E���̑�
;		R�`���̎��s�t�@�C��
;
;	����̉ۑ�
;		�V���{���b�N�����N�ւ̑Ή�
;		(����DOS�R�[�����Ή�������K�v������)
;		�t�@�C���̐擪2�o�C�g��'#!'�̂Ƃ��̓X�N���v�g�ƌ��Ȃ�
;		(������ς���K�v������̂ł��̃p�b�`�͈̔͂ł͏����ł��Ȃ�)

	movem.l	d1-d3/a1,-(sp)
;�ŏ��Ƀt�@�C�����̃A�h���X��LOGICAL_MASK�Ń}�X�N���ė]�v�ȃt���O�ނ�����
;���̕��@�ł̓n�C�������̈�256MB�̖����Ō`��1�`3��add����Ę_���A�h���X���512MB����
;��ꂽ�ꍇ�ɑΏ��ł��Ȃ�
	move.w	#LOGICAL_MASK>>24,d0
	and.b	(4*3,sp),d0		;a1�̍ŏ�ʃo�C�g,�X�^�b�N����
;<d0.w:�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g(0�g��)

	cmp.b	#3,d0
	bhi	@f
;�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g��$00�`$03
	move.l	#$0001_0001,d3
	lsl.l	d0,d3
	lsl.b	#2,d0
	lsl.w	d0,d3
;<d3.l:
;	$0001_0001	�ŏ�ʃo�C�g��$00
;			����0�Ō`��0��add���ꂽ�\��
;			����0�Ō`��0��or���ꂽ�\��
;			�����s���Ō`��0��move���ꂽ�\��
;	$0002_0020	�ŏ�ʃo�C�g��$01
;			����1�Ō`��1��add���ꂽ�\��
;			����1�Ō`��1��or���ꂽ�\��
;			�����s���Ō`��1��move���ꂽ�\��
;	$0004_0400	�ŏ�ʃo�C�g��$02
;			����2�Ō`��2��add���ꂽ�\��
;			����2�Ō`��2��or���ꂽ�\��
;			�����s���Ō`��2��move���ꂽ�\��
;	$0008_8000	�ŏ�ʃo�C�g��$03
;			����3�Ō`��3��add���ꂽ�\��
;			����3�Ō`��3��or���ꂽ�\��
;			�����s���Ō`��3��move���ꂽ�\��
	bra	9f

@@:
;�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g��$04�ȏ�
	tst.l	himemAreaSize
	beq	90f			;�n�C�������̈悪�Ȃ�
	moveq.l	#0,d3
	move.l	himemAreaStart,d1
	rol.l	#8,d1
;<d1.b:�n�C�������̈�̐擪�̃A�h���X�̍ŏ�ʃo�C�g
	sub.b	d0,d1
;<d1.b:�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g����n�C�������̈�̐擪�̃A�h���X�̍ŏ�ʃo�C�g�܂ł̋���
;	1�ȏ�͔͈͊O
;	0�͋���0���L��
;	-1�͋���0�`1���L��
;	-2�͋���0�`2���L��
;	-3�ȉ��͋���0�`3���L��
	bgt	90f			;1�ȏ�Ȃ̂Ŕ͈͊O
	move.l	#$0000_FFFF,d3
	addq.b	#3,d1
;	3�͋���0���L��
;	2�͋���0�`1���L��
;	1�͋���0�`2���L��
;	0�ȉ��͋���0�`3���L��
	bcc	@f
	lsl.b	#2,d1
	lsr.w	d1,d3
@@:
;<d3.w:�n�C�������̈�̉����ɂ�鋗���̏���
;	$FFFF	����0�`3���L��
;	$0FFF	����0�`2���L��
;	$00FF	����0�`1���L��
;	$000F	����0���L��

	move.l	himemAreaEnd,d1
	subq.l	#1,d1
	rol.l	#8,d1
;<d1.b:�n�C�������̈�̖����̃A�h���X�̍ŏ�ʃo�C�g
	sub.b	d0,d1
;<d1.b:�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g����n�C�������̈�̖����̃A�h���X�̍ŏ�ʃo�C�g�܂ł̋���
;	0�ȏ�͋���0�`3���L��
;	-1�͋���1�`3���L��
;	-2�͋���2�`3���L��
;	-3�͋���3���L��
;	-4�ȉ��͔͈͊O
	bge	@f			;0�ȏ�Ȃ̂Ŕ͈͓�
	addq.b	#3,d1
	bmi	90f			;�͈͊O
;	2�͋���1�`3���L��
;	1�͋���2�`3���L��
;	0�͋���3���L��
	lsl.b	#2,d1
	move.l	#$0000_FFFF,d2
	lsl.w	d1,d2
;<d2.w:�n�C�������̈�̏���ɂ�鋗���̏���
;	$FFFF	����0�`3���L��
;	$FFF0	����1�`3���L��
;	$FF00	����2�`3���L��
;	$F000	����3���L��
	and.w	d2,d3
@@:

;<d3.w:�n�C�������̈�̏���

;�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g���n�C�������̈���w���Ă���ꍇ
	and.b	#3,d0			;����2�r�b�g
	bne	@f
	and.w	#$0001,d3		;����2�r�b�g��0
					;	����0�Ō`��0��or���ꂽ�\��(0|0=0)
	bra	1f
@@:
	subq.b	#2,d0
	bcc	@f
	and.w	#$0023,d3		;����2�r�b�g��1
					;	����0�Ō`��0��or���ꂽ�\��(1|0=1)
					;	����0�Ō`��1��or���ꂽ�\��(1|1=1)
					;	����1�Ō`��1��or���ꂽ�\��(0|1=1)
	bra	1f
@@:
	bne	@f
	and.w	#$0405,d3		;����2�r�b�g��2
					;	����0�Ō`��0��or���ꂽ�\��(2|0=2)
					;	����0�Ō`��2��or���ꂽ�\��(2|2=2)
					;	����2�Ō`��2��or���ꂽ�\��(0|2=2)
	bra	1f
@@:
	and.w	#$86AF,d3		;����2�r�b�g��3
					;	����0�Ō`��0��or���ꂽ�\��(3|0=3)
					;	����0�Ō`��1��or���ꂽ�\��(3|1=3)
					;	����0�Ō`��2��or���ꂽ�\��(3|2=3)
					;	����0�Ō`��3��or���ꂽ�\��(3|3=3)
					;	����1�Ō`��1��or���ꂽ�\��(2|1=3)
					;	����1�Ō`��3��or���ꂽ�\��(2|3=3)
					;	����2�Ō`��2��or���ꂽ�\��(1|2=3)
					;	����2�Ō`��3��or���ꂽ�\��(1|3=3)
					;	����3�Ō`��3��or���ꂽ�\��(0|3=3)
1:
	tst.l	d3
	beq	90f

9:
;<d3.l:�t�@�C�����̃A�h���X�̍ŏ�ʃo�C�g�͈̔͂ɂ�����
;	bit0	1=����0�Ō`��0���w�肳�ꂽ�\��������
;	bit1	1=����0�Ō`��1���w�肳�ꂽ�\��������
;	bit2	1=����0�Ō`��2���w�肳�ꂽ�\��������
;	bit3	1=����0�Ō`��3���w�肳�ꂽ�\��������
;	bit4	1=����1�Ō`��0���w�肳�ꂽ�\��������
;	bit5	1=����1�Ō`��1���w�肳�ꂽ�\��������
;	bit6	1=����1�Ō`��2���w�肳�ꂽ�\��������
;	bit7	1=����1�Ō`��3���w�肳�ꂽ�\��������
;	bit8	1=����2�Ō`��0���w�肳�ꂽ�\��������
;	bit9	1=����2�Ō`��1���w�肳�ꂽ�\��������
;	bit10	1=����2�Ō`��2���w�肳�ꂽ�\��������
;	bit11	1=����2�Ō`��3���w�肳�ꂽ�\��������
;	bit12	1=����3�Ō`��0���w�肳�ꂽ�\��������
;	bit13	1=����3�Ō`��1���w�肳�ꂽ�\��������
;	bit14	1=����3�Ō`��2���w�肳�ꂽ�\��������
;	bit15	1=����3�Ō`��3���w�肳�ꂽ�\��������
;	bit16	1=�����s��(pc,sp�̑O��)�Ō`��0���w�肳�ꂽ�\��������
;	bit17	1=�����s��(pc,sp�̑O��)�Ō`��1���w�肳�ꂽ�\��������
;	bit18	1=�����s��(pc,sp�̑O��)�Ō`��2���w�肳�ꂽ�\��������
;	bit19	1=�����s��(pc,sp�̑O��)�Ō`��3���w�肳�ꂽ�\��������

;����0�`3�����Ƀ`�F�b�N����
30:
;���̋����������\�������邩
	moveq.l	#$0F,d1
	and.w	d3,d1
	beq	39f			;���̋����ł͂Ȃ�

;<d1.l:�`���̌��
;<a1.l:�t�@�C�����̃A�h���X
	bsr	checkExecFil



39:
	suba.l	#$01000000,a1
	lsr.w	#4,d3
	bne	30b



	movem.l	(sp)+,d1-d3/a1,-(sp)
	rts


;���ʎ��s
90:
	movem.l	(sp)+,d1-d3/a1,-(sp)
	moveq.l	#0,d0
	rts


;�t�@�C�����̃A�h���X�������������ׂ�
;<d1.l:�`���̌��(�����w���)
;	bit0	�g���q�Ŕ���
;	bit1	R�`��
;	bit2	Z�`��
;	bit3	X�`��
;<a1.l:�t�@�C�����̃A�h���X
;>d0.l:-1=�G���[
;>d1.l:�`��
;	2	R
;	4	Z
;	8	X
	.text
	.align	4,$2048
checkExecFil::
	movem.l	a2-a3,-(sp)
	lea.l	(-ncSize-fSize,sp),sp

;�t�@�C�����Ƃ��Đ�������
	move.l	a1,-(sp)
	DOS	_NAMECK
	addq.l	#4,sp
	tst.l	d0
	bne	90f			;�G���[�܂��̓��C���h�J�[�h������

;�g���q���m�F���Ă���
	move.l	(ncExt,sp),d0		;�g���q(ncExt�͋���)
	and.l	#$FFDFFF00,d0		;1�����ڂ�啶����,3�����ڂ𖳎�
	cmp.l	#'.R'<<16,d0
	bne	1f
	moveq.l	#$02,d1
	bra	3f
1:	cmp.l	#'.Z'<<16,d0
	bne	2f
	moveq.l	#$04,d1
	bra	3f
2:	cmp.l	#'.X'<<16,d0
	bne	3f
	moveq.l	#$08,d1
3:

;�h���C�u�̏������ł��Ă��邩
	moveq.l	#$1F,d0
	and.b	(ncDrive,sp),d0		;�h���C�u�ԍ�(1=A:)
	move.w	d0,-(sp)
	DOS	_DRVCTRL
	addq.l	#2,sp
	and.b	#$02,d0
	beq	90f			;�h���C�u�̏������ł��Ă��Ȃ�

;�t���p�X�̃t�@�C���������
	lea.l	(ncPath,sp),a3
@@:	tst.b	(a3)+
	bne	@b
	subq.l	#1,a3
	lea.l	(ncName,sp),a2
@@:	move.b	(a2)+,(a3)+
	bne	@b
	subq.l	#1,a3
	lea.l	(ncExt,sp),a2
@@:	move.b	(a2)+,(a3)+
	bne	@b

;�t�@�C������������
	move.w	#$0020,-(sp)		;�t�@�C���̂�
	pea.l	(2,sp)
	pea.l	(4+2+ncSize,sp)
	DOS	_FILES
	lea.l	(10,sp),sp
	tst.l	d0
	bne	90f			;�t�@�C����������Ȃ�

;�擪��2�o�C�g��ǂݍ���ł݂�




99:
	lea.l	(ncSize+fSize,sp),sp
	movem.l	(sp)+,a2-a3
	rts

90:
	moveq.l	#-1,d0
	bra	99b
!!!



;----------------------------------------------------------------
;_EXEC	�X�[�p�[�o�C�U���[�h�I��
;�ύX�O
;	$00009748
;		and.l	#$00FFFFFF,d0
;		cmp.l	$0000837A,d0		;Human�̖����̃A�h���X+1
;		bcc.s	$0000975E
;	$00009756
;		ori.w	#$2000,($38,a5)		;�X�[�p�[�o�C�U���[�h�ŋN������
;		rts
;	$0000975E
;		cmp.l	#$00C00000,d0
;		bcc.s	$00009756
;		andi.w	#$DFFF,($38,a5)		;���[�U���[�h�ŋN������
;		rts
;$00009748
	.text
	.align	4,$2048
human302_execsuperpat::
	and.l	#LOGICAL_MASK,d0
	cmp.l	$0000837A.l,d0
	bcc	2f
;�X�[�p�[�o�C�U���[�h�ŋN������
1:	ori.w	#$2000,(dosSR,a5)
	rts

2:	cmp.l	#$00C00000,d0
	bcs	3f
	cmp.l	#$01000000,d0
	bcs	1b
;���[�U���[�h�ŋN������
3:	andi.w	#$DFFF,(dosSR,a5)
	rts

;----------------------------------------------------------------
;_KEEPPR	�풓�t���O�̐ݒ�
;�ύX�O
;	$0000A064
;		ori.l	#$FF000000,$0004(a0)	;�풓�t���O��ݒ�
;$0000A064
	.text
	.align	4,$2048
human302_keeppr::
;�e�̃A�h���X�̍ŏ�ʃo�C�g�ɏ풓�t���O$FF����������
;�e���n�C�������ɂ���ƃA�h���X���j�󂳂��
;�e�͂��܂ł����݂Ƃ͌���Ȃ��̂ł��������H���Ă悢���ł͂Ȃ���
;�O�̂��ߎn�c�ł���Human68k�̃������Ǘ��e�[�u���̃A�h���X�����Ă���
	tst.b	(Proc,a0)
	beq	@f
	move.l	$1C20.w,(Proc,a0)	;Human�̃������Ǘ��e�[�u��
@@:	ori.l	#$FF000000,(Proc,a0)	;�풓�t���O��ݒ�
	jmp	$0000A06C

;----------------------------------------------------------------
;_S_MFREE	�������Ǘ����j�󂳂��o�O
;�ύX�O
;	$0000DF9A
;		movea.l	d2,a0			;�擪
;		movea.l	(-16,a0),a1		;�T�u�̒��O
;		movea.l	(-16+12,a0),a2		;�T�u�̒���
;		move.l	a1,(a0)			;�擪�̃u���b�N�̒��O���T�u�̒��O�ɂ���
;		clr.b	(-16+4,a0)		;�T�u�̐e�̃t���O������
;		move.l	(-16+4,a0),(4,a0)	;�擪�̃u���b�N�̐e���T�u�̐e�ɂ���
;	$0000DFB0
;		move.l	(12,a0),d0		;�����̃u���b�N�܂ŃX�L�b�v
;		beq.s	$0000DFBA
;		movea.l	d0,a0
;		bra.s	$0000DFB0
;	$0000DFBA
;		move.l	a2,(12,a0)		;�����̃u���b�N�̒�����T�u�̒���ɂ���
;	$0000DFBE
;$0000DF9A
	.text
	.align	4,$2048
human302_smfreepat::
	movea.l	d2,a0			;�擪
	movea.l	(-16,a0),a1		;�T�u�̒��O
	movea.l	(-16+12,a0),a2		;�T�u�̒���
	move.l	a1,(a0)			;�擪�̒��O���T�u�̒��O�ɂ���
	beq	1f
	move.l	a0,(12,a1)		;�T�u�̒��O�̒����擪�ɂ���
1:	andi.l	#LOGICAL_MASK,(-16+4,a0)	;�T�u�̐e�̃t���O������
	move.l	(-16+4,a0),(4,a0)	;�擪�̐e���T�u�̐e�ɂ���
	move.l	d2,d0			;�擪
2:	movea.l	d0,a0
	move.l	(12,a0),d0		;�����܂ŃX�L�b�v
	bne	2b
	move.l	a2,(12,a0)		;�����̒�����T�u�̒���ɂ���
	beq	3f
	move.l	a0,(a2)			;�T�u�̒���̒��O�𖖔��ɂ���
3:	jmp	$0000DFBE.l

;----------------------------------------------------------------
;�o�X�G���[�`�F�b�N(_BUS_ERR�̉��������[�`��)
;<d1.w:�T�C�Y
;	1	�o�C�g
;	2	���[�h
;	4	�����O���[�h
;<a0.l:�ǂݏo���A�h���X
;<a1.l:�������ރA�h���X
;>d0.l:�o�X�G���[�̔�����
;	0	�ǂݏ�������
;	1	�ǂݏo������,�������ݎ��s
;	2	�ǂݏ������s
;	-1	�p�����[�^����������
;$0000E28A
	.text
	.align	4,$2048
human302_buserr::
  debug '|buserr in (size,read,write)=',3,d1,a0,a1
  debug '|buserrtrap=',1,#human302_buserr_trap
	PUSH_SR_DI
	PUSH_CACR_DISABLE_DC	d0
;���̃x�N�^�e�[�u�������
	movec.l	vbr,a5			;a5=����vbr
	movea.l	dosBusErrVbr,a6
	movec.l	a6,vbr			;�x�N�^�e�[�u����{�̃�������
					;�ǂ����x�N�^�e�[�u��������Ă���Œ���
					;���荞�܂�Ă������ł��Ȃ��̂Ő�ɐݒ肷��
	move.w	#256-1,d0		;���̃x�N�^�e�[�u���͂��ׂăg���b�v
@@:	move.l	#human302_buserr_trap,(a6)+
	dbra	d0,@b
;���̃X�[�p�[�o�C�U�X�^�b�N���g��
	movea.l	sp,a6			;a6=����ssp
	movea.l	dosBusErrSsp,sp		;ssp��{�̃�������
;
	moveq.l	#2,d0
	cmp.w	#1,d1
	beq	1f
	cmp.w	#2,d1
	beq	2f
	cmp.w	#4,d1
	beq	4f
9:	moveq.l	#-1,d0
8:	movea.l	a6,sp
	movec.l	a5,vbr
	POP_CACR	d1
	POP_SR
  debug '|buserr out (err)=',1,d0
	rts

human302_buserr_trap:
	movea.l	a6,sp
	bra	8b

1:	nop
	move.b	(a0),d1
	nop
	moveq.l	#1,d0
	nop
	move.b	d1,(a1)
	nop
	moveq.l	#0,d0
	bra	8b

2:	move.l	a0,d1
	lsr.l	#1,d1
	bcs	9b
	move.l	a1,d1
	lsr.l	#1,d1
	bcs	9b
	nop
	move.w	(a0),d1
	nop
	moveq.l	#1,d0
	nop
	move.w	d1,(a1)
	nop
	moveq.l	#0,d0
	bra	8b

4:	move.l	a0,d1
	lsr.l	#1,d1
	bcs	9b
	move.l	a1,d1
	lsr.l	#1,d1
	bcs	9b
	nop
	move.l	(a0),d1
	nop
	moveq.l	#1,d0
	nop
	move.l	d1,(a1)
	nop
	moveq.l	#0,d0
	bra	8b

;----------------------------------------------------------------
;DISK2HD�f�o�C�X�h���C�o�̏������[�`���̎擾�Ɛݒ�
;	$00010A20
;		move.w	(a6)+,(a4)+
;		dbra	d0,$00010A20
;$00010A20
	.text
	.align	4,$2048
human302_disk2hd_jmp::
@@:	move.w	(a6)+,(a4)
	addq.l	#2,a4
	dbra	d0,@b
	bsr	cache_flush
	rts

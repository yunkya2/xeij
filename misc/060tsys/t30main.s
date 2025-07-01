	.include	t00iocs.equ
	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ
	.include	t09version.equ

;__DEBUG__	equ	1

;__USE_DISPLACMENT__	equ	1

	.cpu	68060

  .ifdef __USE_DISPLACEMENT__
r	reg	-deviceHeader.w(a4)	;t10head.s�ɂ��郉�x���ȊO�ɂ͎g��Ȃ�����
  .else
r	reg	-0
  .endif

;----------------------------------------------------------------
;�풓�����̖���
keepTail::

;----------------------------------------------------------------
;�f�o�C�X������
deviceInitialize::
	movem.l	d1-d7/a0-a4/a6,-(sp)
  .ifdef __USE_DISPLACEMENT__
	lea.l	deviceHeader,a4
  .endif
  debug 'device initialize start',0

	lea.l	(banner,pc),a1
	bsr	print

;----------------------------------------------------------------
;MPU,Human�̃`�F�b�N
	bsr	mpuCheck
	bmi	deviceInitializeError
	bsr	humanCheck
	bmi	deviceInitializeError
  debug 'MPU,ROM,Human check ok',0

;----------------------------------------------------------------
;�f�[�^�L���b�V����OFF�̂Ƃ��L���b�V�����v�b�V�������ɖ���������
	cmpi.b	#4,$0CBC.w
	blo	99f
	movec.l	cacr,d0
	btst.l	#CACR_EDC_BIT,d0
	bne	@f
	cinva	dc
@@:	cinva	ic
99:

;----------------------------------------------------------------
;store/load bypass�@�\�𖳌��ɂ���
	cmpi.b	#6,$0CBC.w
	bne	10f
	movec.l	pcr,d0
	bset.l	#5,d0			;disable store/load bypass
	movec.l	d0,pcr
10:

;----------------------------------------------------------------
;���[�J���������̗e�ʃ`�F�b�N
	bsr	getLocalMemorySize
	move.l	d0,(localMemorySize)r
	move.l	d1,(localMemoryStart)r
	add.l	d0,d1
	move.l	d1,(localMemoryEnd)r
  debug 'local memory size checked',0

;----------------------------------------------------------------
;�Ǘ��̈�͈̔͂̏�����
	move.l	#keepTail,d0
	add.l	#$00001FFF,d0		;mainLowerStart�̓y�[�W�T�C�Y�ɍ��킹��
	and.l	#$FFFFE000,d0
	move.l	d0,(mainLowerStart)r
	move.l	d0,(mainLowerEnd)r
	move.l	$1C00.w,d0
	and.l	#$FFFFE000,d0
	move.l	d0,(mainUpperStart)r
	move.l	d0,(mainUpperEnd)r
	tst.l	(localMemorySize)r
	beq	@f
	move.l	(localMemoryStart)r,d0
	move.l	d0,(localLowerStart)r
	move.l	d0,(localLowerEnd)r
	move.l	(localMemoryEnd)r,d0
	move.l	d0,(localUpperStart)r
	move.l	d0,(localUpperEnd)r
@@:
  debug 'management area set',0

;----------------------------------------------------------------
;�]���o�b�t�@�̗̈�̏�����
	clr.l	(tempBufferSize)r
  debug 'temporary buffer vanished',0

;----------------------------------------------------------------
;���C�����������RAMDISK�̗̈�̏�����
	move.l	(mainUpperStart)r,d0
	move.l	d0,(mainRamdiskAreaStart)r
	move.l	d0,(mainRamdiskAreaEnd)r
	clr.l	(mainRamdiskAreaSize)r
  debug 'main RAMDISK vanished',0

;���[�J�����������RAMDISK�̗̈�̏�����
	move.l	(localLowerStart)r,d0
	move.l	d0,(localRamdiskAreaStart)r
	move.l	d0,(localRamdiskAreaEnd)r
	clr.l	(localRamdiskAreaSize)r
  debug 'local RAMDISK vanished',0

;----------------------------------------------------------------
;���C���������̃T�C�Y�̏�����
	move.l	#-1,(mainMemorySize)r
  debug 'main memory size initialized',0

;----------------------------------------------------------------
;�p�����[�^�̉���
;	mainLower���g������
;		tempBuffer
;		dosBusErr
;	mainUpper���g������
;		mainRamdiskArea
;		descArea
;	localLower���g������
;		localRamdiskArea
;	localLower��localUpper�̊Ԃ�himemArea
;	localUpper���g������
;		localRom
;		descArea
  debug 'parameter check start',0
;68030�̂Ƃ�-nt�������I�Ɏw�肷��
	cmpi.b	#3,$0CBC.w
	bhi	@f
	st.b	(noTranslation)r
@@:
	movea.l	(18,a5),a6		;�p�����[�^�̃A�h���X
1:	tst.b	(a6)+
	bne	1b
	tst.b	(a6)
	beq	2f
	movea.l	a6,a0
	bsr	getParam
	bra	1b
2:
  debug 'parameter check end',0

;----------------------------------------------------------------
;�f�X�N���v�^�̗̈�̃T�C�Y�����肷��
;	-ts�̎w�肪����΂��̂܂�
;	-ts�̎w�肪�����������0�ɂȂ��Ă���̂ł����Őݒ肳���
	tst.b	(noTranslation)r
	bne	99f
	bsr	defaultDescAreaSize
  debug 'desc area size set',0
99:

;----------------------------------------------------------------
;���C�����������RAMDISK�̗̈���y�[�W�T�C�Y�̔{���܂Ő؂艺����
	move.l	(mainRamdiskAreaStart)r,d0
	and.l	(pageMask)r,d0
	move.l	d0,(mainRamdiskAreaStart)r
	move.l	d0,(mainUpperStart)r
  debug 'main RAMDISK area resized',0

;----------------------------------------------------------------
;�]���o�b�t�@�̊m��
	tst.l	(tempBufferSize)r
	bne	@f
	move.l	#DEFAULT_BUFFER_SIZE,d0	;�]���o�b�t�@�̓y�[�W�T�C�Y�̔{���ɂ��邱��
	move.l	d0,(tempBufferSize)r
	move.l	(mainLowerEnd)r,d1
	add.l	#$00001FFF,d1		;�]���o�b�t�@�̓y�[�W�ʒu�ɍ��킹��
	and.l	#$FFFFE000,d1
	move.l	d1,(tempBufferStart)r
	add.l	d0,d1
	move.l	d1,(tempBufferEnd)r
	move.l	d1,(mainLowerEnd)r
	move.l	(mainUpperStart)r,d0
	sub.l	d1,d0
	cmp.l	#128*1024,d0
	blt	tempBufferOver
@@:

;----------------------------------------------------------------
;ADPCM�]���o�b�t�@�̊m�ۂƏ�����
	tst.b	(patchIocsAdpcm)r
	beq	@f
	move.l	(adpcmBufferSize)r,d0	;�ݒ�ς�
	move.l	(mainLowerEnd)r,d1
	add.l	#$00001FFF,d1		;�]���o�b�t�@�̓y�[�W�ʒu�ɍ��킹��
	and.l	#$FFFFE000,d1
	move.l	d1,(adpcmBufferStart)r
	move.l	d1,(adpcmBufferPtr0)r
	add.l	d0,d1
	move.l	d1,(adpcmBufferPtr1)r
	add.l	d0,d1
	move.l	d1,(adpcmBufferEnd)r
	add.l	#$00001FFF,d1		;�]���o�b�t�@�̓y�[�W�ʒu�ɍ��킹��
	and.l	#$FFFFE000,d1
	move.l	d1,(mainLowerEnd)r
	bsr	dmac3Initialize
;1�y�[�W�����Ȃ̂Ń������s���`�F�b�N�͏ȗ�
@@:

;----------------------------------------------------------------
;_BUS_ERR�p�̉��̃x�N�^�e�[�u���Ɖ��̃X�[�p�[�o�C�U�X�^�b�N�̗̈���m�ۂ���
	move.l	(mainLowerEnd)r,d0
	move.l	d0,(dosBusErrVbr)r
	add.l	#1024+1024,d0		;2KB�Ȃ̂Ń������s���`�F�b�N�͏ȗ�
	move.l	d0,(dosBusErrSsp)r
	move.l	d0,(mainLowerEnd)r

;----------------------------------------------------------------
;���[�J�����������RAMDISK�̗̈���y�[�W�T�C�Y�̔{���܂Ő؂�グ��
	move.l	(localRamdiskAreaEnd)r,d0
	add.l	(pageOffsetMask)r,d0
*****pageMask�Ń}�X�N����Ƙ_���A�h���X��Ԃ̖�����0�ɂȂ��Ă��܂�
*****	and.l	(pageMask)r,d0
	and.w	(pageMask+2)r,d0
	move.l	d0,(localRamdiskAreaEnd)r
	move.l	d0,(localLowerEnd)r
  debug 'local RAMDISK area resized',0

;----------------------------------------------------------------
;���[�J�����������ROM���R�s�[����
	tst.b	(noTranslation)r
	bne	99f
	tst.b	(localRomArea)r
	beq	2f
	movea.l	#$00F00000,a1
	movea.l	(localRomStart)r,a0
1:	move16	(a1)+,(a0)+
	cmpa.l	#$01000000,a1
	blo	1b
	movea.l	(localRomStart)r,a0
	add.l	#$00FF0000-$00F00000,a0
	move.l	#'loca',(a0)+
	move.l	#'lRom',(a0)+

;ROMVER=$15970213�̃o�O���C��
	IOCS	_ROMVER
	cmp.l	#$15970213,d0
	bne	9f
	movea.l	(localRomStart)r,a0
	add.l	#$00FFB32C-$00F00000,a0
	cmpi.l	#$4A75002A,(a0)
	bne	@f
	move.l	#$4A75042A,(a0)
@@:
	move.b	#$08,DCR2
	move.b	#$05,MFC2
	move.b	#$03,CPR2
	move.b	#$05,DFC2
;	move.b	#$05,BFC2
;	move.b	#$68,NIV2
;	move.b	#$69,EIV2
9:

;ROMVER=$15970529�̃o�O���C��
	IOCS	_ROMVER
	cmp.l	#$15970529,d0
	bne	9f
;�\�t�g�L�[�{�[�h���\������Ă����ԂŃL�[�������ƃn���O�A�b�v����o�O���C��
	movea.l	(localRomStart)r,a0
	add.l	#$00FF5004-$00F00000,a0
	cmpi.w	#$2057,(a0)		;movea.l (sp),a0
	bne	@f
	move.w	#$205F,(a0)		;movea.l (sp)+,a0
@@:
9:

;SCSI��DMA�]����PACK���Ă݂�(700KB��500KB�ƁA�������Ēx���Ȃ�炵��)
;	IOCS	_ROMVER
;	cmp.l	#$14970107,d0
;	bne	@f
;	movea.l	(localRomStart)r,a0
;	add.l	#$00FFDE60-$00F00000,a0
;	cmpi.w	#$80B1,(a0)
;	bne	@f
;	move.w	#$8081,(a0)
;@@:
	bsr	cache_flush
2:
  debug 'local ROM area set',0
99:

;----------------------------------------------------------------
;�f�X�N���v�^�̗̈�̊m��
	tst.b	(noTranslation)r
	bne	99f
	tst.b	(localAreaDescriptor)r
	beq	1f
	move.l	(localUpperStart)r,d0
	sub.l	(descAreaSize)r,d0
	and.l	(pageMask)r,d0
	cmp.l	(localLowerEnd)r,d0
	bcc	2f
	sf.b	(localAreaDescriptor)r
;���C���ɍ��
1:	move.l	(mainUpperStart)r,d0
	sub.l	(descAreaSize)r,d0
	and.l	(pageMask)r,d0
	move.l	(mainLowerEnd)r,d1
	add.l	#128*1024,d1
	cmp.l	d1,d0
	blt	descAreaOver
	move.l	d0,(mainUpperStart)r
	bra	3f
;���[�J���ɍ��
2:	move.l	d0,(localUpperStart)r
3:	move.l	d0,(descAreaStart)r
	add.l	(descAreaSize)r,d0
	move.l	d0,(descAreaEnd)r
  debug 'descriptor area allocated',0
99:

;----------------------------------------------------------------
;_HIMEM�̗̈��ݒ�
	clr.l	(himemAreaStart)r
	clr.l	(himemAreaEnd)r
	clr.l	(himemAreaSize)r
	tst.l	(localMemorySize)r
	beq	2f
	move.l	(localLowerEnd)r,d1
	move.l	(localUpperStart)r,d2
	move.l	d2,d0
	sub.l	d1,d0
	bls	2f			;HIMEM�ɋ󂫃G���A���Ȃ�
	move.l	d0,(himemAreaSize)r
	move.l	d1,(himemAreaStart)r
	move.l	d2,(himemAreaEnd)r
	movea.l	d1,a0
	lea.l	(User,a0),a1
;;;	cmpi.l	#'060t',(a1)
;;;	beq	2f			;����������Ă���
	move.l	#'060t',(a1)+
	move.l	#'urbo',(a1)+
	move.l	#'HIME',(a1)+
	move.l	#'M'<<24,(a1)+
	clr.l	(Prev,a0)
	move.l	$1C20.w,(Proc,a0)	;Human�̃������Ǘ��|�C���^
	move.l	a1,(Tail,a0)
	clr.l	(Next,a0)
2:
  debug 'HIMEM area initialized',0

;----------------------------------------------------------------
;�X���b�h�Ԃ̔r�������������������
	tst.b	(backgroundFlag)r
	beq	9f
;���C���X���b�h�̔r�������������������
	lea.l	(mainExclusive)r,a2
;�W���n���h�����쐬����
	moveq.l	#0,d2
1:	move.w	d2,-(sp)
	DOS	_DUP			;�W���n���h���𕡐�����
	addq.l	#2,sp			;�G���[���������Ă͂Ȃ�Ȃ�
	move.w	d0,(xStdin,a2,d2.w*2)
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;�h���C�u�Ǘ��e�[�u���̃A�h���X��ݒ肷��
	move.l	$1C38.w,(xDriveTablePtr,a2)	;���݂̃h���C�u�Ǘ��e�[�u��
9:

;----------------------------------------------------------------
;�����n�������������
	DOS	_GETDATE
	move.l	d0,d1
	DOS	_GETTIME
	add.w	d1,d0
	swap.w	d1
	add.w	d1,d0
	move.l	d0,d1
	bsr	srand
	move.l	d1,d0
	bsr	randomize

;----------------------------------------------------------------
;
;	�ȍ~�͒��f�s��
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;Human�Ƀp�b�`�����Ă�
	tst.b	(unitCounter)r		;RAMDISK���Ȃ����,
	bne	@f			;RAMDISK�̃`�F�b�N�͖��Ӗ��Ȃ̂ŏȗ�����
	move.l	#callDeviceNoRamdisk,patchHumanCallDevice+2
@@:
	bsr	patchHuman
	bmi	deviceInitializeError
  debug 'Human68k patched',0

;----------------------------------------------------------------
;���C����������؂�l�߂�
	move.l	(mainUpperStart)r,$1C00.w
  debug 'main memory resized',0

;----------------------------------------------------------------
;�A�h���X�ϊ��e�[�u�������
	tst.b	(noTranslation)r
	bne	99f
	bsr	makeTranslationTable
  debug 'address translation table created',0
99:

;----------------------------------------------------------------
;�x�N�^�ݒ�
	move.b	(localRomArea)r,d0
	or.b	(localSystemArea)r,d0
	beq	@f
	lea.l	(vectorInfoHumanTrap10)r,a0
	bsr	setVector
  debug 'TRAP#10 vector set',0
@@:

	lea.l	(vectorInfoPRIVILEGE)r,a0
	bsr	setVector
	lea.l	(vectorInfoFLINE)r,a0
	bsr	setVector
	lea.l	(vectorInfoBSUN)r,a0
	bsr	setVector
	lea.l	(vectorInfoINEX)r,a0
	bsr	setVector
	lea.l	(vectorInfoDZ)r,a0
	bsr	setVector
	lea.l	(vectorInfoUNFL)r,a0
	bsr	setVector
	lea.l	(vectorInfoOPERR)r,a0
	bsr	setVector
	lea.l	(vectorInfoOVFL)r,a0
	bsr	setVector
	lea.l	(vectorInfoSNAN)r,a0
	bsr	setVector
	lea.l	(vectorInfoUNSUPP)r,a0
	bsr	setVector
	lea.l	(vectorInfoEFFADD)r,a0
	bsr	setVector
	lea.l	(vectorInfoUNINT)r,a0
	bsr	setVector
  debug '060SP vector set',0

	lea.l	(spBanner,pc),a1
	bsr	print

	tst.b	(patchIocsAdpcm)r
	beq	@f
	lea.l	(vectorInfoIocsAdpcmout)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcminp)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmaot)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmain)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmlot)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmlin)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmsns)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsAdpcmmod)r,a0
	bsr	setVector
  debug 'IOCS ADPCM vector set',0
@@:

	tst.b	(softwareIocsDma)r
	beq	@f
	lea.l	(vectorInfoIocsDmamove)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsDmamovA)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsDmamovL)r,a0
	bsr	setVector
	lea.l	(vectorInfoIocsDmamode)r,a0
	bsr	setVector
  debug 'IOCS DMA vector set',0
@@:

	lea.l	(vectorInfoIocsSysStat)r,a0
	bsr	setVector
  debug 'SYS_STAT vector set',0

	cmpi.w	#_SCSIDRV*$0100+$00FF,$0400+_SCSIDRV*4.w
	beq	@f			;_SCSIDRV�͓o�^����Ă��Ȃ�
	cmpi.w	#$00FF,$0400+_SCSIDRV*4.w
	beq	@f			;_SCSIDRV�͓o�^����Ă��Ȃ�
	SCSI	_S_REVISION
	move.w	d0,(scsiRevisionCode)r
	lea.l	(vectorInfoIocsScsidrv)r,a0
	bsr	setVector
  debug 'SCSIDRV vector set',0
@@:

	lea.l	(vectorInfoIocsPrnintst)r,a0
	bsr	setVector
	lea.l	(vectorInfoPrnint)r,a0
	bsr	setVector
  debug 'PRNINTST vector set',0

	tst.b	(useIocsHimem)r
	beq	@f
	lea.l	(vectorInfoIocsHimem)r,a0
	bsr	setVector
  debug 'HIMEM vector set',0
@@:

	lea.l	(vectorInfoDosExec)r,a0
	bsr	setVector
  debug 'EXEC vector set',0

;	tst.b	(useJointMode)r
;	beq	@f
	lea.l	(vectorInfoDosMalloc)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Malloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMalloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Malloc3)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMalloc3)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Malloc4)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMalloc4)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosMfree)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSetblock)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0Setblock2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSetblock2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SMalloc)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSMalloc)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SMalloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSMalloc2)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SMfree)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSMfree)r,a0
	bsr	setVector
	lea.l	(vectorInfoDos0SProcess)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosSProcess)r,a0
	bsr	setVector
  debug 'memory doscall vector set',0
@@:

	tst.b	(backgroundFlag)r
	beq	@f
	lea.l	(vectorInfoDosOpenPr)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosKillPr)r,a0
	bsr	setVector
	lea.l	(vectorInfoDosChangePr)r,a0
	bsr	setVector
  debug 'background doscall vector set',0
@@:

;----------------------------------------------------------------
;�A�h���X�ϊ��J�n
	tst.b	(noTranslation)r
	bne	99f
	bsr	enableTranslation
  debug 'address translation enabled',0
99:

;----------------------------------------------------------------
;�L���b�V���Ȃǂ̏�Ԃ�������
;EBC=1,ESB=1,ESS=1,EDC=0,EIC=0
;	�f�[�^�L���b�V���Ɩ��߃L���b�V���̏�Ԃ�,
;	060turbo.sys�̏��������I�����Human�ɖ߂��������,
;	�p�b�`�ɂ����SRAM�̐ݒ�ɂȂ�
	move.w	#$C007,d1
	moveq.l	#%11100,d2
	IOCS	_SYS_STAT
  debug 'branch cache, store buffer, superscaler enabled',0

;----------------------------------------------------------------
;�x�N�^�̈悩��Human�{�̖̂����܂ł�060turbo.sys�̏풓���������[�J���������Ɉړ�����
	tst.b	(localSystemArea)r
	beq	9f
	PUSH_MMU_SFC_DFC	d0
	move.l	(localSystemStart)r,d3	;�R�s�[��
	suba.l	a1,a1			;�R�s�[��
1:	cmpa.l	#$0001447A.and.PAGE_MASK,a1	;Human�{�̖̂���
	bne	@f
	move.l	#deviceHeader,d0	;060turbo.sys�̐擪
	add.l	#PAGE_OFFSET_SIZE-1,d0
	and.l	#PAGE_MASK,d0
	movea.l	d0,a1
@@:
;
	bsr	getDesc
	move.l	d0,d2			;���݂̃y�[�W�f�X�N���v�^
	and.l	(pageOffsetMask)r,d2	;�����������o��
	or.l	d3,d2			;�R�s�[��̃A�h���X���g��
	movea.l	d3,a2			;�R�s�[��
	movea.l	a1,a3			;�R�s�[��
	move.l	(pageOffsetSize)r,d0
	lsr.l	#4,d0
;���荞�݂��~�߂���Ԃő�}���ŃR�s�[���Ă����ɐ؂�ւ���
;�R�s�[���̃A�h���X�ŃR�s�[�悪������悤�ɂ���
	PUSH_SR_DI
2:	move16	(a3)+,(a2)+
	subq.l	#1,d0
	bne	2b
	movea.l	d3,a2
	cpushp	bc,(a2)
	moves.l	d2,(a0)
	pflusha
	POP_SR
;�O�̂��߃R�s�[��̃A�h���X�ŃR�s�[����������悤�ɂ��Ă���
	exg.l	d3,a1
	bsr	getDesc			;�R�s�[��
	and.l	(pageOffsetMask)r,d2	;�����������o��
	or.l	d3,d2			;�R�s�[���̃A�h���X���g��
	moves.l	d2,(a0)
	pflusha
	exg.l	d3,a1
;
	add.l	(pageOffsetSize)r,d3
	adda.l	(pageOffsetSize)r,a1
	cmp.l	(localSystemEnd)r,d3
	blo	1b
	POP_SFC_DFC	d0
  debug 'local system started',0
9:

;----------------------------------------------------------------
;�f�o�C�X�������I��
	tst.b	(unitCounter)r
	bne	1f
;���j�b�g����0�̂Ƃ��L�����N�^�f�o�C�X�̂ӂ������
	move.w	#$8000,(deviceHeader+dhType)r
	move.l	#'/*06',(deviceHeader+dhName)r
	move.l	#'0T*/',(deviceHeader+dhName+4)r
	bra	2f
1:	move.b	(unitCounter)r,(13,a5)	;���j�b�g��
	move.l	#bpbTablePointer,(18,a5)	;BPB�e�[�u���̃|�C���^�̃e�[�u��
2:	move.l	(mainLowerEnd)r,(14,a5)	;�f�o�C�X�h���C�o�̖���+1
	moveq.l	#0,d0
  debug 'device initialize end',0

deviceInitializeExit:
	movem.l	(sp)+,d1-d7/a0-a4/a6
	rts

banner:
	.dc.b	13,10
*	.dc.b	$1B,'[1m'
	.dc.b	'060turbo.sys version ',VERSION
*	.dc.b	$1B,'[1m'
	.dc.b	' ',DATE
	.dc.b	' by M.Kamada',13,10,0

spBanner:
	.dc.b	'M68060 Software Package Copyright (C) Motorola Inc.',13,10
	.dc.b	0
	.even

deviceInitializeError:
	move.w	#$700D,d0
	bra	deviceInitializeExit

tempBufferOver:
	lea.l	(@f,pc),a1
	bsr	print
	bra	deviceInitializeError
@@:	.dc.b	'�]���o�b�t�@���m�ۂł��܂���',13,10,0
	.even

descAreaOver:
	lea.l	(@f,pc),a1
	bsr	print
	bra	deviceInitializeError
@@:	.dc.b	'�f�X�N���v�^�̗̈悪�m�ۂł��܂���',13,10,0
	.even

;----------------------------------------------------------------
;MPU���m���߂�
;68060�̂Ƃ�Human��[$0CBC].b=$03�ɂ��Ă��܂��Ă���
;>d0.l:0=����,-1=���s
;>ccr:pl����,mi=���s
mpuCheck:
	movem.l	d1/a0-a2,-(sp)
	PUSH_SR_DI
	movea.l	sp,a1
	move.l	$0010,a2
	move.l	#110f,$0010.w		;Illegal Instruction
;MOVEC from SFC���Ȃ����68000
	moveq.l	#0,d0
	lea.l	(80f,pc),a0
	movec.l	sfc,d0
;�X�P�[���t�@�N�^���Ȃ����68010
	moveq.l	#1,d0
10:	moveq.l	#1,d1
	and.b	(10b-1,pc,d1.l*2),d1
	beq	80f
;CALLM�������68020
	.cpu	68020
	lea.l	(40f,pc),a0
	callm	#0,(20f,pc)
	moveq.l	#2,d0
	bra	80f

;���W���[���f�X�N���v�^
20:	.dc.l	%0<<13|0<<24|0<<16	;option=0,type=0,accesslevel=0
	.dc.l	30f			;���W���[���G���g���|�C���^
	.dc.l	0			;���W���[���f�[�^�̈�|�C���^
	.dc.l	0
;���W���[���G���g��
30:	.dc.w	15<<12			;Rn=sp
	rtm	sp
	.cpu	68060

;MOVEC from CAAR�������68030
	.cpu	68030
40:	lea.l	(50f,pc),a0
	movec.l	caar,d0
	moveq.l	#3,d0
	bra	80f
	.cpu	68060

;MOVEC from MMUSR�������68040
	.cpu	68040
50:	lea.l	(60f,pc),a0
	movec.l	mmusr,d0
	moveq.l	#4,d0
	bra	80f
	.cpu	68060

;MOVEC from PCR�������68060
60:	lea.l	(70f,pc),a0
	movec.l	pcr,d0
	moveq.l	#6,d0
	bra	80f

;�s��
70:	moveq.l	#0,d0
80:	move.b	d0,$0CBC.w
	move.l	a2,$0010.w
	POP_SR
	moveq.l	#0,d0
	cmpi.b	#3,$0CBC.w
	bhs	90f
	lea.l	(100f,pc),a1
	bsr	print
	moveq.l	#-1,d0
90:	movem.l	(sp)+,d1/a0-a2
	tst.l	d0
	rts

100:	.dc.b	'68030 �ȏ�ł͂���܂���',13,10,0
	.even

110:	movea.l	a1,sp
	jmp	(a0)

;----------------------------------------------------------------
;Human68k�̃o�[�W�������m���߂�
humanCheck:
	DOS	_VERNUM
	cmp.w	#$0302,d0
	bne	9f
	moveq.l	#0,d0
	rts

9:	lea.l	(@f,pc),a1
	bsr	print
	moveq.l	#-1,d0
	rts
@@:	.dc.b	'Human �̃o�[�W�������Ⴂ�܂�',13,10,0
	.even

;----------------------------------------------------------------
;Human�Ƀp�b�`�����Ă�
patchHuman::
	bsr	patchHuman302
	bmi	9f
	rts

9:	lea.l	(@f,pc),a1
	bsr	print
	moveq.l	#-1,d0
	rts
@@:	.dc.b	'Human ���ُ�ł�',13,10,0
	.even

;----------------------------------------------------------------
;�x�N�^��ݒ肷��
;<a0.l:�x�N�^���
;	0000	.l	�x�N�^�A�h���X
;	0004	.l	���̃x�N�^
;	0008	.l	�V�����x�N�^
setVector::
	movem.l	a0-a1,-(sp)
	movea.l	(a0)+,a1		;�x�N�^�A�h���X
	move.l	(a1),(a0)+		;���̃x�N�^��ۑ�
	move.l	(a0),(a1)		;�V�����x�N�^��ݒ�
	movem.l	(sp)+,a0-a1
	rts

;----------------------------------------------------------------
;���[�J���������̗e�ʂƐ擪�A�h���X��Ԃ�
;	�O��
;	�E���[�J���������̗e�ʂƐ擪�A�h���X��$01000000(16MB)�̔{���ł���
;	�E���[�J���������̃A�N�Z�X�ŃA�N�Z�X�G���[��s��ɂ��f�[�^�̔j���͔������Ȃ�
;	�E���̃v���O�����̓X�[�p�[�o�C�U���[�h�Ŏ��s�����
;	�E���̃v���O�����ƃX�[�p�[�o�C�U�X�^�b�N�G���A�͘_���A�h���X=�����A�h���X�̗̈�ɂ���
;	�E���̃v���O�����ƃX�[�p�[�o�C�U�X�^�b�N�G���A�̃A�h���X�̏��8�r�b�g��$00�ł���
;	�菇
;	�E$00000000-$3FFFFFFF(1024MB)��$01000000(16MB)����64�ɋ�؂�
;	�E��ʂ̃u���b�N���珇�ɓ����I�t�Z�b�g�ɈقȂ�f�[�^����������
;	�E��ʂ̃u���b�N���珇�ɏ������񂾃f�[�^��ǂݏo����Α��݂���Ɣ��f����
;�p�����[�^�Ȃ�
;>d0.l:���[�J���������̗e��
;>d1.l:���[�J���������̐擪�A�h���X
getLocalMemorySize::
	movem.l	d2-d5/a0,-(sp)
	moveq.l	#0,d0
;�L���b�V���֎~
	movec.l	cacr,d4
	movec.l	d0,cacr
	CACHE_FLUSH	d3
;MMU�֎~
	cmpi.b	#4,$0CBC.w
	blo	@f
	movec.l	tc,d3
	movec.l	d0,tc
	pflusha
;�g�����X�y�A�����g�ϊ��֎~
	movec.l	dtt1,d2
	movec.l	d0,dtt1
	movec.l	dtt0,d5
	movec.l	d0,dtt0
@@:
;�R���g���[�����W�X�^�ۑ�
	movem.l	d2-d5,-(sp)
;���[�N�G���A�m��
	lea.l	-4-64(sp),sp
;�ۑ�
	moveq.l	#$3F,d1			;�u���b�N�̔ԍ��B$3F��$00
10:	move.l	d1,d0
	ror.l	#8,d0
	lea.l	(sp,d0.l),a0		;�e�X�g����A�h���X
	move.b	(a0),4(sp,d1.l)		;�ۑ�
	dbra	d1,10b
;�ύX
	moveq.l	#$3F,d1			;�u���b�N�̔ԍ��B$3F��$00
20:	move.l	d1,d0
	ror.l	#8,d0
	lea.l	(sp,d0.l),a0		;�e�X�g����A�h���X
	move.b	d1,(a0)			;�ύX
	dbra	d1,20b
;��r�ƕ���
	moveq.l	#$3F,d1			;�u���b�N�̔ԍ��B$3F��$00
30:	move.l	d1,d0
	ror.l	#8,d0
	lea.l	(sp,d0.l),a0		;�e�X�g����A�h���X
	cmp.b	(a0),d1			;��r
	seq.b	d0			;0=�Ȃ�,-1=����
	bne	40f
	move.b	4(sp,d1.l),(a0)		;(����Ƃ�)����
40:	move.b	d0,4(sp,d1.l)		;���ʁB0=�Ȃ�,-1=����
	dbra	d1,30b
	sf.b	4(sp)			;�u���b�N0�̓��[�J���������ł͂Ȃ�
;����
	moveq.l	#$3F,d1			;�u���b�N�̔ԍ��B$3F��$00
50:	tst.b	4(sp,d1.l)
	dbne	d1,50b
	beq	70f			;�Ȃ�
;����
	move.l	d1,d0			;�����̃u���b�N�̔ԍ�
;�擪
60:	tst.b	4(sp,d1.l)
	dbeq	d1,60b			;�K��eq�Ŏ~�܂�
	addq.b	#1,d1
	ror.l	#8,d1			;�擪�̃u���b�N�̐擪�A�h���X
	addq.b	#1,d0
	ror.l	#8,d0			;�����̃u���b�N�̖����A�h���X+1
	sub.l	d1,d0			;����
	bra	80f
;�Ȃ�
70:	moveq.l	#0,d0
	moveq.l	#0,d1
80:
;<d0.l:���[�J���������̗e��
;<d1.l:���[�J���������̐擪�A�h���X
;���[�N�G���A�J��
	lea.l	4+64(sp),sp
;�R���g���[�����W�X�^����
	movem.l	(sp)+,d2-d5
;�g�����X�y�A�����g�ϊ�����
	cmpi.b	#4,$0CBC.w
	blo	@f
	movec.l	d5,dtt0
	movec.l	d2,dtt1
;MMU����
	movec.l	d3,tc
@@:
;�L���b�V������
	movec.l	d4,cacr
	movem.l	(sp)+,d2-d5/a0
	rts


;----------------------------------------------------------------
;���[�J���������̃T�C�Y����f�X�N���v�^�̗̈�̃T�C�Y�����肷��
defaultDescAreaSize::
	movem.l	d0-d1,-(sp)
	tst.l	(descAreaSize)r
	bne	2f			;���Ɏw�肳��Ă���
	move.l	#DEFAULT_DESC_SIZE_0,d1
	move.l	(localMemorySize)r,d0
	beq	1f			;�{��16MB�̂�
	move.l	#DEFAULT_DESC_SIZE_16,d1
	cmp.l	#16<<20,d0
	bls	1f			;�{��16MB+���[�J��16MB
	move.l	#DEFAULT_DESC_SIZE_32,d1
	cmp.l	#32<<20,d0
	bls	1f			;�{��16MB+���[�J��32MB
	move.l	#DEFAULT_DESC_SIZE_64,d1
	cmp.l	#64<<20,d0
	bls	1f			;�{��16MB+���[�J��64MB
	move.l	#DEFAULT_DESC_SIZE_128,d1
	cmp.l	#128<<20,d0
	bls	1f			;�{��16MB+���[�J��128MB
	move.l	#DEFAULT_DESC_SIZE_256,d1
	cmp.l	#256<<20,d0
	bls	1f			;�{��16MB+���[�J��256MB
	move.l	#DEFAULT_DESC_SIZE_384,d1
	cmp.l	#384<<20,d0
	bls	1f			;�{��16MB+���[�J��384MB
	move.l	#DEFAULT_DESC_SIZE_512,d1
	cmp.l	#512<<20,d0
	bls	1f			;�{��16MB+���[�J��512MB
	move.l	#DEFAULT_DESC_SIZE_768,d1
					;�{��16MB+���[�J��768MB
1:	move.l	d1,(descAreaSize)r
2:	movem.l	(sp)+,d0-d1
	rts

;----------------------------------------------------------------
;�A�h���X�ϊ��e�[�u�������
makeTranslationTable::
	movea.l	(descAreaStart)r,a0
	movea.l	(descAreaEnd)r,a1
;�f�X�N���v�^�̗̈�Ɋ֘A���郏�[�N��ݒ肷��
	move.l	a0,(descHead)r
;	move.l	a0,(rootDescHead)r
	lea.l	(ROOT_DESC_SIZE,a0),a2
	move.l	a2,(rootDescTail)r
;	move.l	a2,(pointerDescHead)r
	move.l	a2,(pointerDescTail)r
	move.l	(descAreaSize)r,d0
	move.l	(pageIndexWidth)r,d1
	lsr.l	d1,d0			;�Q�Ɛ��J�E���^�̗̈�̃T�C�Y
	move.l	a1,d1
	sub.l	d0,d1
	and.l	(pageDescMask)r,d1
	move.l	d1,(pageDescHead)r
	move.l	d1,(pageDescTail)r
;	move.l	d1,(pointerCounterHead)r
	move.l	a1,(pageCounterTail)r
;	move.l	a1,(descTail)r

;�f�X�N���v�^�̗̈������������
	movea.l	(rootDescHead)r,a0
	movea.l	(pageDescTail)r,a1
@@:	clr.l	(a0)+
	cmpa.l	a1,a0
	blo	@b
	movea.l	(pageCounterTail)r,a1
@@:	move.l	#-1,(a0)+
	cmpa.l	a1,a0
	blo	@b

	MMU_SFC_DFC	d0

;���C���������̃A�h���X�ϊ�
	lea.l	(physicalModeTable,pc),a2
	suba.l	a1,a1
1:	move.l	(a2)+,d2		;���[�h
	move.l	(a2)+,d0		;���̃A�h���X
6:	cmpa.l	d0,a1
	blo	7f
	move.l	(a2)+,d2		;���[�h
	move.l	(a2)+,d0		;���̃A�h���X
	bpl	6b
7:	subq.l	#8,a2
	add.l	a1,d2
	bsr	setDesc
	bmi	9f			;�G���[����
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	#$01000000,a1
	bne	1b

	moveq.l	#$00000000,d1
2:	move.l	d1,d0
	bsr	copyPointerDesc
	add.l	#$00040000,d1
	adda.l	#$00040000,a1
	cmpa.l	#$02000000,a1
	bne	2b

3:	moveq.l	#$00000000,d0
	bsr	copyRootDesc
	adda.l	#$02000000,a1
	cmpa.l	#LOGICAL_SIZE,a1
	bne	3b

;���[�J���������̃A�h���X�ϊ�
	move.l	(localMemorySize)r,d1
	beq	5f
	clr.w	d3
	move.b	localMemoryCacheMode,d3
	lsl.w	#PD_CM_BIT,d3
;		  UR G U1U0 S CM M U W PDT
	or.w	#%00_1__00__0_00_0_0_0_11,d3
	movea.l	#$10000000,a1
	add.l	a1,d1
4:	move.l	a1,d2
	or.w	d3,d2
	bsr	setDesc
	bmi	9f			;�G���[����
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	d1,a1
	bne	4b
5:

9:

;�]���o�b�t�@�̗̈�����C�g�X���[�ɂ���
	tst.l	(tempBufferSize)r
	beq	2f			;�O�̂���
	movea.l	(tempBufferStart)r,a1	;���Ƀy�[�W�T�C�Y�ɍ��킹�Ă���
	movea.l	(tempBufferEnd)r,a2	;���Ƀy�[�W�T�C�Y�ɍ��킹�Ă���
1:	moveq.l	#0,d2			;���C�g�X���[
	bsr	sysStat_8004
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	a2,a1
	blo	1b
2:

;ADPCM�̓]���o�b�t�@�̗̈�����C�g�X���[�ɂ���
	movea.l	(adpcmBufferStart)r,a1	;���Ƀy�[�W�T�C�Y�ɍ��킹�Ă���
	moveq.l	#0,d2			;���C�g�X���[
	bsr	sysStat_8004		;1�y�[�W����

;���C�����������RAMDISK�̗̈���m���L���b�V���u���ɂ���
	movea.l	(mainRamdiskAreaStart)r,a1
	movea.l	(mainRamdiskAreaEnd)r,a2
	cmpa.l	a1,a2
	beq	2f
1:	moveq.l	#3,d2			;�L���b�V���֎~�X�g�A�o�b�t�@����
	bsr	sysStat_8004
;�w��_���y�[�W���X�[�p�[�o�C�U�ی삷��
;<a1.l:�_���A�h���X
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bset.l	#PD_S_BIT,d0
	moves.l	d0,(a0)
	POP_SFC_DFC	d0
;
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	a2,a1
	blo	1b
2:

;���[�J�����������RAMDISK�̗̈���m���L���b�V���u���ɂ���
	movea.l	(localRamdiskAreaStart)r,a1
	movea.l	(localRamdiskAreaEnd)r,a2
	cmpa.l	a1,a2
	beq	2f
1:	moveq.l	#3,d2			;�L���b�V���֎~�X�g�A�o�b�t�@����
	bsr	sysStat_8004
;�w��_���y�[�W���X�[�p�[�o�C�U�ی삷��
;<a1.l:�_���A�h���X
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bset.l	#PD_S_BIT,d0
	moves.l	d0,(a0)
	POP_SFC_DFC	d0
;
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	a2,a1
	blo	1b
2:

;���[�J�����������ROM
	tst.b	(localRomArea)r
	beq	2f
	movea.l	#$00F00000,a1
	move.l	(localRomStart)r,d2
1:	bsr	sysStat_F001		;ROM�A�h���X�����[�J��������
	exg.l	d2,a1
	bsr	invDesc			;���[�J��������������
	exg.l	d2,a1
	add.l	(pageOffsetSize)r,d2
	adda.l	(pageOffsetSize)r,a1
	cmp.l	#$01000000,a1
	blo	1b


2:

;�f�X�N���v�^�̗̈�������Ȃ�����
	movea.l	(descAreaStart)r,a1
1:	bsr	invDesc
	adda.l	(pageOffsetSize)r,a1
	cmpa.l	(descAreaEnd)r,a1
	bne	1b
2:

	CACHE_FLUSH	d0		;�O�̂��߃v�b�V�����Ă���
	rts

physicalModeTable::
;			   UR G U1U0 S CM M U W PDT
;	.dc.l	          %00_1__00__1_00_0_0_0_01	;Vector
;	.dc.l	$00002000
mainPD:
	.dc.l	          %00_1__00__0_00_0_0_0_01	;Main Memory
	.dc.l	$00C00000,%00_1__00__1_11_0_0_0_01	;Graphic
	.dc.l	$00E00000,%00_1__00__1_11_0_0_0_01	;Text
	.dc.l	$00E80000,%00_1__00__1_10_0_0_0_01	;CRTC
	.dc.l	$00E82000,%00_1__00__1_10_0_0_0_01	;Palet/Video Controler
	.dc.l	$00E84000,%00_1__00__1_10_0_0_0_01	;DMAC
	.dc.l	$00E86000,%00_1__00__1_10_0_0_0_01	;Supervisor Area Control
	.dc.l	$00E88000,%00_1__00__1_10_0_0_0_01	;MFP
	.dc.l	$00E8A000,%00_1__00__1_10_0_0_0_01	;RTC
	.dc.l	$00E8C000,%00_1__00__1_10_0_0_0_01	;Printer
	.dc.l	$00E8E000,%00_1__00__1_10_0_0_0_01	;System Port
	.dc.l	$00E90000,%00_1__00__1_10_0_0_0_01	;FM
	.dc.l	$00E92000,%00_1__00__1_10_0_0_0_01	;ADPCM
	.dc.l	$00E94000,%00_1__00__1_10_0_0_0_01	;FDC
	.dc.l	$00E96000,%00_1__00__1_10_0_0_0_01	;Internal SCSI
	.dc.l	$00E98000,%00_1__00__1_10_0_0_0_01	;SCC
	.dc.l	$00E9A000,%00_1__00__1_10_0_0_0_01	;Joy Stick
	.dc.l	$00E9C000,%00_1__00__1_10_0_0_0_01	;I/O Interrupt Control
	.dc.l	$00E9E000,%00_1__00__1_10_0_0_0_01	;Co-processor
	.dc.l	$00EA0000,%00_1__00__1_10_0_0_0_01	;External SCSI
	.dc.l	$00EAE000,%00_1__00__1_10_0_0_0_01	;Supervisor Area Control
							;External RS-232C
	.dc.l	$00EB0000,%00_1__00__1_10_0_0_0_01	;Sprite Register/Controler
	.dc.l	$00EB8000,%00_1__00__1_11_0_0_0_01	;Sprite PCG
	.dc.l	$00EBC000,%00_1__00__1_11_0_0_0_01	;Sprite Text
	.dc.l	$00EC0000,%00_1__00__0_10_0_0_0_01	;User I/O
	.dc.l	$00ED0000,%00_1__00__1_10_0_0_0_01	;SRAM
	.dc.l	$00ED4000,%00_1__00__0_10_0_0_0_01	;User I/O
	.dc.l	$00F00000,%00_1__00__1_00_0_0_1_01	;ROM
	.dc.l	-1

makeTranslationMain:
	.dc.b	'�A�h���X�ϊ��e�[�u�������C���������ɔz�u���܂�',13,10,0
	.even

;----------------------------------------------------------------
;�A�h���X�ϊ���L���ɂ���
enableTranslation::
	PUSH_SR_DI

	moveq.l	#0,d0
	movec.l	d0,cacr
	CACHE_FLUSH	d0

	move.l	(rootDescHead)r,d0
	movec.l	d0,srp
	movec.l	d0,urp

;		  E  P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
	move.l	#%1__0__0__0___0____0____10__00__0___10__00_0,d0
	cmpi.l	#4096,(pageOffsetSize)r
	beq	@f
	bset.l	#TC_P_BIT,d0
@@:	movec.l	d0,tc

	pflusha

	POP_SR
	rts


;----------------------------------------------------------------
;�p�����[�^�̉���
;<a0.l:���[�h�̐擪
getParam::
	movea.l	a0,a1
	cmpi.b	#'-',(a0)+
	bne	9f
	move.w	(a0)+,d0		;��A�h���X�̉\��������
	or.w	#$2020,d0
	cmp.w	#'ad',d0
	beq	param_ad
	cmp.w	#'bg',d0
	beq	param_bg
	cmp.w	#'bs',d0
	beq	param_bs
	cmp.w	#'cm',d0
	beq	param_cm
	cmp.w	#'dv',d0
	beq	param_dv
	cmp.w	#'fe',d0
	beq	param_fe
	cmp.w	#'hi',d0
	beq	param_hi
	cmp.w	#'ld',d0
	beq	param_ld
	cmp.w	#'lr',d0
	beq	param_lr
	cmp.w	#'ls',d0
	beq	param_ls
	cmp.w	#'lt',d0
	beq	param_lt
	cmp.w	#'lz',d0
	beq	param_lz
	cmp.w	#'md',d0
	beq	param_md
	cmp.w	#'mm',d0
	beq	param_mm
	cmp.w	#'np',d0
	beq	param_np
	cmp.w	#'nt',d0
	beq	param_nt
	cmp.w	#'sd',d0
	beq	param_sd
	cmp.w	#'sl',d0
	beq	param_sl
	cmp.w	#'ss',d0
	beq	param_ss
	cmp.w	#'ts',d0
	beq	param_ts
	cmp.w	#'xm',d0
	beq	param_xm
9:	bsr	print
	lea.l	(1f,pc),a1
	bra	print
1:	.dc.b	' �c ���߂ł��܂���̂Ŗ������܂�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-sl
;�@�\:	68060��store/load bypass�@�\��L���ɂ���
;����:	68060��result forwarding features��1�ł���store/load
;	bypass�@�\��L���ɂ��܂��B
;	store/load bypass�@�\�̓��Z�b�g����͗L���ł����A
;	060turbo.sys(v0.54�ȍ~)������𖳌��ɂ��Ă��܂��B
;	-sl���w�肷��ƁAstore/load bypass�@�\���L���ɂȂ�܂��B
;	store/load bypass�@�\�𖳌��ɂ��邱�Ƃɂ�鑬�x�ቺ�͂�
;	�Ƃ�ǂ���܂���B
param_sl:
	cmpi.b	#6,$0CBC.w
	bne	10f
	movec.l	pcr,d0
	bclr.l	#5,d0			;enable store/load bypass
	movec.l	d0,pcr
10:
	rts

;----------------------------------------------------------------
;���@:	-mm<size>
;	<size>	���C���������̃T�C�Y�i�P�ʂ� MB�j
;�@�\:	���C���������̃T�C�Y�̐ݒ�
;����:	���C���������̃T�C�Y���w�肵�܂��B
;	������������Ȃ���΃��[�J��������������΂�������₢�A
;	���������烍�[�J�����������ɉ����o���܂��B
;	�������T�C�Y�̕ύX�̓V�F���N���O�ɍs���܂��B
;	-mm0 �Ƃ���ƃf�o�C�X�h���C�o�����̃����������ׂ�
;	���[�J�����������ɉ����o���܂��iJUPITER �̊g�����[�h�Ɠ����j�B
param_mm:
	tst.b	(noTranslation)r
	bne	param_mm_notrans	;-nt���w�肳��Ă���
	bsr	stou
	bmi	param_mm_illegal
	cmp.l	#12,d0
	bhi	param_mm_illegal
	swap.w	d0
	lsl.l	#4,d0
	move.l	d0,(mainMemorySize)r
	rts

param_mm_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt �� -mm �͓����Ɏw��ł��܂���D-mm �͖����ł�',13,10,0
	.even

param_mm_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-mm �̎w��l���ُ�ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-ts<size>
;	<size>	�A�h���X�ϊ��̂��߂̗̈�̃T�C�Y�i�P�ʂ� KB�j
;�@�\:	�A�h���X�ϊ��̂��߂̗̈�̃T�C�Y�̐ݒ�
;����:	�A�h���X�ϊ��̂��߂̗̈�̃T�C�Y���w�肵�܂��B
;	�y�[�W�T�C�Y�� 8KB �̂Ƃ��A���[�J���������̗e�ʂɉ�����
;	�Œ�T�C�Y�ƃf�t�H���g�T�C�Y�͈ȉ��̒ʂ�ł��B
;					�Œ�	�f�t�H���g
;		�{��16MB�̂�		10KB	32KB
;		�{��16MB+���[�J��16MB	19KB	48KB
;		�{��16MB+���[�J��32MB	27KB	64KB
;		�{��16MB+���[�J��64MB	44KB	96KB
;		�{��16MB+���[�J��128MB	78KB	160KB
;		�{��16MB+���[�J��256MB	146KB	320KB
;		�{��16MB+���[�J��384MB	214KB	480KB
;		�{��16MB+���[�J��512MB	282KB	640KB
;		�{��16MB+���[�J��768MB	418KB	960KB
;	4MB �ȏ�͎w��ł��܂���B
param_ts:
	cmpi.b	#3,$0CBC.w
	beq	param_ts_68030		;68030�ł͎w��ł��Ȃ�
	tst.b	(noTranslation)r
	bne	param_ts_notrans	;-nt���w�肳��Ă���
	bsr	stou
	bmi	param_ts_illegal	;�������Ȃ�
	cmp.l	#4096,d0
	bhi	param_ts_toobig		;�傫������
	move.l	(localMemorySize)r,d1
	bne	@f
;�{��16MB�̂�
	cmp.w	#MINIMUM_DESC_SIZE_0>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#16<<20,d1
	bhi	@f
;�{��16MB+���[�J��16MB
	cmp.w	#MINIMUM_DESC_SIZE_16>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#32<<20,d1
	bhi	@f
;�{��16MB+���[�J��32MB
	cmp.w	#MINIMUM_DESC_SIZE_32>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#64<<20,d1
	bhi	@f
;�{��16MB+���[�J��64MB
	cmp.w	#MINIMUM_DESC_SIZE_64>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#128<<20,d1
	bhi	@f
;�{��16MB+���[�J��128MB
	cmp.w	#MINIMUM_DESC_SIZE_128>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#256<<20,d1
	bhi	@f
;�{��16MB+���[�J��256MB
	cmp.w	#MINIMUM_DESC_SIZE_256>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#384<<20,d1
	bhi	@f
;�{��16MB+���[�J��384MB
	cmp.w	#MINIMUM_DESC_SIZE_384>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:	cmp.l	#512<<20,d1
	bhi	@f
;�{��16MB+���[�J��512MB
	cmp.w	#MINIMUM_DESC_SIZE_512>>10,d0
	blo	param_ts_toosmall	;����������
	bra	9f

@@:
;�{��16MB+���[�J��768MB
	cmp.w	#MINIMUM_DESC_SIZE_768>>10,d0
	blo	param_ts_toosmall	;����������

9:	lsl.l	#8,d0
	lsl.l	#2,d0
	move.l	d0,(descAreaSize)r
	rts

param_ts_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts �� 68030 �ł͎w��ł��܂���D-ts �͖����ł�',13,10,0
	.even

param_ts_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt �� -ts �͓����Ɏw��ł��܂���D-ts �͖����ł�',13,10,0
	.even

param_ts_toosmall:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts �̎w��l�����������܂��B�f�t�H���g���g�p���܂�',13,10,0
	.even

param_ts_toobig:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts �̎w��l���傫�����܂��B�f�t�H���g���g�p���܂�',13,10,0
	.even

param_ts_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ts �̎w��l���ُ�ł��B�f�t�H���g���g�p���܂�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-lr
;����:	���[�J��������������Ƃ��AROM �����[�J���������ɃR�s�[��
;	�Ďg���܂��B
param_lr:
	tst.b	(localRomArea)r
	bne	99f			;-lr�͊��Ɏw�肳�ꂽ
	tst.b	(forceNoSimm)r
	bne	param_lr_nosimm		;-lz���w�肳��Ă���
	cmpi.b	#3,$0CBC.w
	beq	param_lr_68030		;68030�ł͎w��ł��Ȃ�
	tst.b	(noTranslation)r
	bne	param_lr_notrans	;-nt���w�肳��Ă���
	tst.l	(localMemorySize)r
	beq	param_lr_cannot		;���[�J�����������Ȃ�
	move.l	(localUpperStart)r,d0
	sub.l	#1024*1024,d0
	cmp.l	(localLowerEnd)r,d0
	blo	param_lr_over
	move.l	d0,(localUpperStart)r
	move.l	d0,(localRomStart)r
	add.l	#1024*1024,d0
	move.l	d0,(localRomEnd)r
	st.b	(localRomArea)r
99:	rts

param_lr_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz �� -lr �͓����Ɏw��ł��܂���D-lr �͖����ł�',13,10,0
	.even

param_lr_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lr �� 68030 �ł͎w��ł��܂���D-lr �͖����ł�',13,10,0
	.even

param_lr_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt �� -lr �͓����Ɏw��ł��܂���D-lr �͖����ł�',13,10,0
	.even

param_lr_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J�����������s�����Ă��܂��D-lr �͖����ł�',13,10,0
	.even

param_lr_cannot:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J��������������܂���D-lr �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-lt
;����:	���[�J��������������Ƃ��A�A�h���X�ϊ��e�[�u�������[�J��
;	�������ɒu���܂��B
param_lt:
	tst.b	(forceNoSimm)r
	bne	param_lt_nosimm		;-lz���w�肳��Ă���
	cmpi.b	#3,$0CBC.w
	beq	param_lt_68030		;68030�ł͎w��ł��Ȃ�
	tst.b	(noTranslation)r
	bne	param_lt_notrans	;-nt���w�肳��Ă���
	tst.l	(localMemorySize)r
	beq	9f
	st.b	(localAreaDescriptor)r
	rts

param_lt_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz �� -lt �͓����Ɏw��ł��܂���D-lt �͖����ł�',13,10,0
	.even

param_lt_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lt �� 68030 �ł͎w��ł��܂���D-lt �͖����ł�',13,10,0
	.even

param_lt_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt �� -lt �͓����Ɏw��ł��܂���D-lt �͖����ł�',13,10,0
	.even

9:	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J��������������܂���D-lt �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-ss
;�@�\:	SCSI �̃A�N�Z�X�Ń\�t�g�]�����g��
;����:	IOCS $F5 �ɂ�� SCSI �̃A�N�Z�X�Ń��[�J���������Ƃ̂���
;	����\�ɂ��܂��B
;	�w�肳�ꂽ�o�b�t�@�̘_���A�h���X�������A�h���X�ƈقȂ���
;	������A���̂����[�J���������ɂ���Ƃ��A�ꎞ�I�Ƀ\�t�g�]
;	���ɐ؂�ւ��܂��B
param_ss:
	st.b	(patchIocsScsi)r
	rts

;----------------------------------------------------------------
;���@:	-dv
;�@�\:	�f�o�C�X�h���C�o�̃A�N�Z�X�Ńe���|�����o�b�t�@���g��
;����:	�f�o�C�X�h���C�o�̃A�N�Z�X�Ń��[�J���������Ƃ̂��Ƃ��
;	�\�ɂ��܂��B
;	�w�肳�ꂽ�o�b�t�@�̘_���A�h���X�������A�h���X�ƈقȂ���
;	������A���̂����[�J���������ɂ���Ƃ��A�e���|�����o�b�t
;	�@��}��ăf�[�^�����Ƃ肵�܂��B
param_dv:
	st.b	(patchDevice)r
	rts

;----------------------------------------------------------------
;���@:	-bs<size>
;	<size>	�e���|�����o�b�t�@�̃T�C�Y�i�P�ʂ� KB�j
;����:	-dv �w�莞�Ɏg�p����e���|�����o�b�t�@�̃T�C�Y���w�肵��
;	���B�f�t�H���g�� 64KB �ł��B
;	�e���|�����o�b�t�@�͏�Ƀ��C����������Ɋm�ۂ���܂��B
param_bs:
	tst.l	(tempBufferSize)r
	bne	param_bs_already
	bsr	stou
	bmi	param_bs_illegal
	lsl.l	#8,d0
	lsl.l	#2,d0
	add.l	#$00001FFF,d0		;�]���o�b�t�@�̓y�[�W�ʒu�ɍ��킹��
	and.l	#$FFFFE000,d0
	move.l	d0,(tempBufferSize)r
	move.l	(mainLowerEnd)r,d1
	add.l	#$00001FFF,d1		;�]���o�b�t�@�̓y�[�W�ʒu�ɍ��킹��
	and.l	#$FFFFE000,d1
	move.l	d1,(tempBufferStart)r
	add.l	d0,d1
	move.l	d1,(tempBufferEnd)r
	move.l	d1,d0
	add.l	#128*1024,d0
	cmp.l	(mainUpperStart)r,d0
	bhi	param_bs_over
	move.l	d1,(mainLowerEnd)r
	rts

param_bs_already:
	lea.l	(@f,pc),a1
	bra	9f
@@:	.dc.b	'-bs �͓�d�w��ł�',13,10,0
	.even

param_bs_illegal:
	lea.l	(@f,pc),a1
	bra	9f
@@:	.dc.b	'-bs �̎w�肪�ُ�ł�',13,10,0
	.even

param_bs_over:
	lea.l	(@f,pc),a1
9:	bsr	print
	clr.l	(tempBufferSize)r
	rts
@@:	.dc.b	'-bs �̎w�肪�傫�����܂��D�f�t�H���g���g�p���܂�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-xm
;�@�\:	�g�����[�h�̐ݒ�
;����:	�g�����[�h�ɂ��Ă���V�F�����N�����܂��B
;	Human �̃������Ǘ������[�J���������܂Ŋg�����܂��B
;	�������Ǘ��֌W�� DOS �R�[�����g�����܂��B
;	XC �̃��C�u�������g�p���Ă���v���O���������[�h�����Ƃ��A
;	�����I�Ƀp�b�`�����Ă܂��B
param_xm:
	tst.b	(forceNoSimm)r
	bne	param_xm_nosimm		;-lz���w�肳��Ă���
	tst.l	(localMemorySize)r
	beq	9f
	st.b	(useJointMode)r
	st.b	(jointMode)r
	rts

param_xm_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz �� -xm �͓����Ɏw��ł��܂���D-xm �͖����ł�',13,10,0
	.even

9:	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J��������������܂���D-xm �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-hi
;	v0.53��芮�S�ɔp�~
param_hi:
	rts

;----------------------------------------------------------------
;���@:	-md<size>{[K]|M}[a][i]
;	<size>	RAMDISK �̃T�C�Y
;	K	�T�C�Y�̒P�ʂ� KB
;	M	�T�C�Y�̒P�ʂ� MB
;	a	TIMER-LED ���A�N�Z�X�����v�ɂ���
;	i	SHIFT �L�[��������Ă��Ȃ��Ƃ�����������
;�@�\:	���C����������� RAMDISK �̐ݒ�
;����:	RAMDISK �h���C�o��g�ݍ��݂܂��BRAMDISK �̗̈�̓��C����
;	�����̏�ʑ�����m�ۂ���܂��B
;	<size> �͈̔͂� 16KB ���� 32767KB �܂łł��B�������A���C
;	���������̗e�ʂɂ���Đ�������܂��B
;	i ���w�肵�Ȃ���� SHIFT �L�[��������Ă���Ƃ���������
;	�܂��B�������ARAMDISK �̐擪�����Ă���Ƃ��͖������ɏ�
;	�������܂��B
;	-ld �� -md �͍��킹�� 16 �܂Ŏw��ł��܂��B
;	RAMDISK �̗̈�̓X�[�p�[�o�C�U�v���e�N�g����܂��B�܂��A
;	�L���b�V�����[�h���m���L���b�V���u���E�C���v���T�C�Y�h�V
;	���A���C�[�[�V�����ɂ��邱�ƂŁA�L���b�V���𖳑ʌ�������
;	���悤�ɂ��܂��B
;��:	-md512Ka
;		���C����������� 512KB �� RAMDISK ���m�ۂ��܂��B
;		TIMER-LED ���A�N�Z�X�����v�ɂ��܂��B
;		SHIFT �L�[��������Ă���Ƃ����������܂��B
;<a0.l:'md'�̎��̃A�h���X
param_md:
	moveq.l	#0,d0
	move.b	(unitCounter)r,d0
	cmp.b	#MAXIMUM_UNIT,d0
	beq	param_md_toomany	;���j�b�g������������
	lea.l	(bpbTablePointer)r,a1
1:	movea.l	(a1)+,a3
	dbra	d0,1b
;<a3.l:BPB�e�[�u��
	moveq.l	#0,d2
	cmpi.b	#'-',(a0)
	bne	@f
	moveq.l	#1,d2
	addq.l	#1,a0
@@:	bsr	stou
	bmi	param_md_illegal
	move.l	d0,d1
	moveq.l	#$20,d0
	or.b	(a0),d0
	cmp.b	#'k',d0
	beq	1f
	cmp.b	#'m',d0
	bne	2f
	lsl.l	#8,d1
	lsl.l	#2,d1
1:	addq.l	#1,a0
2:	tst.l	d2
	beq	@f
	move.l	(mainUpperStart)r,d0
	sub.l	(mainLowerEnd)r,d0
	lsr.l	#8,d0
	lsr.l	#2,d0
	sub.l	d1,d0
	move.l	d0,d1
@@:	cmp.l	#MINIMUM_SIZE,d1
	blo	param_md_illegal
	cmp.l	#MAXIMUM_SIZE,d1
	bhi	param_md_illegal
;<d1.l:�S�̈�̃Z�N�^��
	move.l	d1,(12,a3)		;�S�̈�̃Z�N�^��
	move.l	d1,d2
	lsl.l	#8,d2
	lsl.l	#2,d2			;�S�̈�̃o�C�g��
;<d2.l:�S�̈�̃o�C�g��
;���C����������RAMDISK�͖�������m�ۂ���
	movea.l	(mainRamdiskAreaStart)r,a1
;<a1.l:�����A�h���X+1
	movea.l	a1,a2
	suba.l	d2,a2
;<a2.l:�擪�A�h���X
	move.l	a2,d0
	sub.l	#128*1024,d0
	cmp.l	(mainLowerEnd)r,d0
	blt	param_md_over
	move.l	a2,(mainRamdiskAreaStart)r
;<a1.l:�����A�h���X+1
;<a2.l:�擪�A�h���X
	move.l	a2,(16,a3)		;�擪�A�h���X
	move.l	a1,(20,a3)		;�����A�h���X+1
	moveq.l	#0,d6
1:	move.b	(a0)+,d0
	beq	2f
	or.b	#$20,d0
	cmp.b	#'i',d0
	bne	@f
	or.b	#%00000001,d6
	bra	1b
@@:	cmp.b	#'a',d0
	bne	@f
	or.b	#%00000100,d6
	bra	1b
@@:	bra	param_md_illegal
2:
;<d1.l:�S�̈�̃Z�N�^��
	move.l	d1,d0
	sub.l	#(ROOT_ENTRY+31)>>5,d0
;<d0.l:�f�[�^�̈�̃Z�N�^���̏��
	moveq.l	#1,d3
	moveq.l	#0,d4
	bra	2f
1:	add.l	d3,d3			;1�N���X�^������̃Z�N�^��
	addq.l	#1,d4			;1�N���X�^������̃Z�N�^���̃V�t�g�J�E���g
	lsr.l	#1,d0
2:	cmp.l	#$0000FFF0,d0
	bhi	1b
	addq.l	#2,d0
;<d0.l:�f�[�^�̈�̃N���X�^���̏��+2
;<d3.l:1�N���X�^������̃Z�N�^��
;<d4.l:1�N���X�^������̃Z�N�^���̃V�t�g�J�E���g
	move.b	d3,(2,a3)		;1�N���X�^������̃Z�N�^��
	move.l	d0,d3
	add.l	d3,d3
	cmp.l	#$0FF7,d0
	bcc	@f
	lsr.l	#2,d3
	addx.l	d0,d3
@@:	add.l	#$03FF,d3
	lsr.l	#8,d3
	lsr.l	#2,d3
;<d3.l:FAT�̈�̃Z�N�^��
	move.b	d3,(11,a3)		;1��FAT�̈�Ɏg�p����Z�N�^��
	move.l	d1,d5			;�S�̈�̃Z�N�^��
	sub.l	#(ROOT_ENTRY+31)>>5,d5
	sub.l	d3,d5
;<d5.l:�f�[�^�̈�̃Z�N�^��
	lsr.l	d4,d5
	addq.l	#2,d5
;<d5.l:�f�[�^�̈�̃N���X�^��+2
	moveq.l	#1,d4
	cmpi.w	#$F9FF,(a2)
	bne	1f			;���Ă���
	cmpi.b	#$FF,(2,a2)
	bne	1f			;���Ă���
	IOCS	_B_SFTSNS
	and.b	d0,d4			;SHIFT�L�[�̏��
	btst.l	#0,d6
	beq	@f			;�������w�肪�Ȃ�
	eori.b	#1,d4			;SHIFT�L�[�̏����𔽓]����
@@:	tst.l	d4
	beq	2f			;���������Ȃ�
1:	movea.l	a2,a0			;�擪�A�h���X
	move.l	d3,d0			;1��FAT�̈�Ɏg�p����Z�N�^��
	lsl.l	#10-2,d0		;1��FAT�̈�Ɏg�p����o�C�g��/4
	subq.w	#1,d0
@@:	clr.l	(a0)+			;FAT��������
	dbra	d0,@b
	move.w	#ROOT_ENTRY*32/4-1,d0
@@:	clr.l	(a0)+			;���[�g�f�B���N�g����������
	dbra	d0,@b
	moveq.l	#$F9,d0
	ror.l	#8,d0
	cmp.l	#$00000FF7,d5
	bcc	@f
	clr.b	d0
@@:	move.l	d0,(a2)			;FAT�̃w�b�_���Z�b�g
2:
;<d4.l:�������t���O(0=���������Ȃ�����,1=����������)
;�A�N�Z�X�����v
	btst.l	#2,d6
	sne.b	(24,a3)
;���b�Z�[�W�\��
	lea.l	(param_md_message,pc),a1
	moveq.l	#'A',d0
	add.b	(22,a5),d0		;�h���C�u��
	add.b	(unitCounter)r,d0
	move.b	d0,(param_md_drive-param_md_message,a1)
	move.l	a2,d0
	lea.l	(param_md_start-param_md_message,a1),a0
	bsr	hex8			;������16�i��8��
	add.l	d2,d0
	subq.l	#1,d0
	lea.l	(param_md_end-param_md_message,a1),a0
	bsr	hex8			;������16�i��8��
	bsr	print
	lea.l	(param_md_not_initialized,pc),a1	;'�͏��������܂���'
	tst.l	d4
	beq	@f
	lea.l	(param_md_initialized,pc),a1	;'�����������܂���'
@@:	bsr	print
;
	addq.b	#1,(unitCounter)r
	rts

param_md_message:
	.dc.b	'�q�`�l�f�B�X�N '
param_md_drive:
	.dc.b	'?: $'
param_md_start:
	.dc.b	'xxxxxxxx�`$'
param_md_end:
	.dc.b	'xxxxxxxx ',0
param_md_not_initialized:
	.dc.b	'�͏��������܂���',13,10,0
param_md_initialized:
	.dc.b	'�����������܂���',13,10,0
	.even

param_md_toomany:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-md �̃��j�b�g�����������܂�',13,10,0
	.even

param_md_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-md �̎w�肪�ُ�ł�',13,10,0
	.even

param_md_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-md �̎w�肪�傫�����܂�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-ld<size>{[K]|M}[a][i]
;	<size>	RAMDISK �̃T�C�Y
;	K	<size> �̒P�ʂ� KB
;	M	<size> �̒P�ʂ� MB
;	a	TIMER-LED ���A�N�Z�X�����v�ɂ���
;	i	SHIFT �L�[��������Ă��Ȃ��Ƃ�����������
;�@�\:	���[�J����������� RAMDISK �̐ݒ�
;����:	RAMDISK �h���C�o��g�ݍ��݂܂��BRAMDISK �̗̈�̓��[�J��
;	�������̉��ʑ�����m�ۂ���܂��B
;	<size> �͈̔͂� 16KB ���� 1024MB �܂łł��B�������A���[
;	�J���������̗e�ʂɂ���Đ�������܂��B
;	<size> �� - ��t����Ǝc���T�C�Y���w��ł��܂��B
;	i ���w�肵�Ȃ���� SHIFT �L�[��������Ă���Ƃ���������
;	�܂��B�������ARAMDISK �̐擪�����Ă���Ƃ��͖������ɏ�
;	�������܂��B
;	-ld �� -md �͍��킹�� 16 �܂Ŏw��ł��܂��B
;	RAMDISK �̗̈�̓X�[�p�[�o�C�U�v���e�N�g����܂��B�܂��A
;	�L���b�V�����[�h���m���L���b�V���u���E�C���v���T�C�Y�h�V
;	���A���C�[�[�V�����ɂ��邱�ƂŁA�L���b�V���𖳑ʌ�������
;	���悤�ɂ��܂��B
;��:	-ld16Mai
;		���[�J����������� 16MB �� RAMDISK ���m�ۂ��܂��B
;		TIMER-LED ���A�N�Z�X�����v�ɂ��܂��B
;		SHIFT �L�[��������Ă��Ȃ��Ƃ����������܂��B
;<a0.l:'ld'�̎��̃A�h���X
param_ld:
	tst.b	(forceNoSimm)r
	bne	param_ld_nosimm		;-lz���w�肳��Ă���
	tst.l	(localMemorySize)r
	beq	param_ld_cannot		;���[�J�����������Ȃ�
	moveq.l	#0,d0
	move.b	(unitCounter)r,d0
	cmp.b	#MAXIMUM_UNIT,d0
	beq	param_ld_toomany	;���j�b�g������������
	lea.l	(bpbTablePointer)r,a1
1:	movea.l	(a1)+,a3
	dbra	d0,1b
;<a3.l:BPB�e�[�u��
	moveq.l	#0,d2
	cmpi.b	#'-',(a0)
	bne	@f
	moveq.l	#1,d2
	addq.l	#1,a0
@@:	bsr	stou
	bmi	param_ld_illegal
	move.l	d0,d1
	moveq.l	#$20,d0
	or.b	(a0),d0
	cmp.b	#'k',d0
	beq	1f
	cmp.b	#'m',d0
	bne	2f
	lsl.l	#8,d1
	lsl.l	#2,d1
1:	addq.l	#1,a0
2:	tst.l	d2
	beq	@f
	move.l	(localUpperStart)r,d0
	sub.l	(localRamdiskAreaEnd)r,d0
	lsr.l	#8,d0
	lsr.l	#2,d0
	sub.l	d1,d0			;�m�ۂ���Z�N�^��=�󂫃Z�N�^��-�c���Z�N�^��
	move.l	d0,d1
@@:	cmp.l	#MINIMUM_SIZE,d1
	blo	param_ld_illegal
	cmp.l	#MAXIMUM_SIZE,d1
	bhi	param_ld_illegal
;<d1.l:�S�̈�̃Z�N�^��
	move.l	d1,(12,a3)		;�S�̈�̃Z�N�^��
	move.l	d1,d2
	lsl.l	#8,d2
	lsl.l	#2,d2			;�S�̈�̃o�C�g��
;�n�C��������RAMDISK�͐擪����m�ۂ���
;<d2.l:�S�̈�̃o�C�g��
	movea.l	(localRamdiskAreaEnd)r,a2
;<a2.l:�擪�A�h���X
	lea.l	(a2,d2.l),a1
;<a1.l:�����A�h���X+1
	cmpa.l	(localUpperStart)r,a1
	bhi	param_ld_over		;�c��0�����e���Ă���B-xm���ł��Ȃ��Ȃ�
	move.l	a1,(localRamdiskAreaEnd)r
;<a1.l:�����A�h���X+1
;<a2.l:�擪�A�h���X
	move.l	a2,(16,a3)		;�擪�A�h���X
	move.l	a1,(20,a3)		;�����A�h���X+1
	moveq.l	#0,d6
1:	move.b	(a0)+,d0
	beq	2f
	or.b	#$20,d0
	cmp.b	#'i',d0
	bne	@f
	or.b	#%00000001,d6
	bra	1b
@@:	cmp.b	#'a',d0
	bne	@f
	or.b	#%00000100,d6
	bra	1b
@@:	bra	param_ld_illegal
2:
;<d1.l:�S�̈�̃Z�N�^��
	move.l	d1,d0
	sub.l	#(ROOT_ENTRY+31)>>5,d0
;<d0.l:�f�[�^�̈�̃Z�N�^���̏��
	moveq.l	#1,d3
	moveq.l	#0,d4
	bra	2f
1:	add.l	d3,d3			;1�N���X�^������̃Z�N�^��
	addq.l	#1,d4			;1�N���X�^������̃Z�N�^���̃V�t�g�J�E���g
	lsr.l	#1,d0
2:	cmp.l	#$0000FFF0,d0
	bhi	1b
	addq.l	#2,d0
;<d0.l:�f�[�^�̈�̃N���X�^���̏��+2
;<d3.l:1�N���X�^������̃Z�N�^��
;<d4.l:1�N���X�^������̃Z�N�^���̃V�t�g�J�E���g
	move.b	d3,(2,a3)		;1�N���X�^������̃Z�N�^��
	move.l	d0,d3
	add.l	d3,d3
	cmp.l	#$0FF7,d0
	bcc	@f
	lsr.l	#2,d3
	addx.l	d0,d3
@@:	add.l	#$03FF,d3
	lsr.l	#8,d3
	lsr.l	#2,d3
;<d3.l:FAT�̈�̃Z�N�^��
	move.b	d3,(11,a3)		;1��FAT�̈�Ɏg�p����Z�N�^��
	move.l	d1,d5			;�S�̈�̃Z�N�^��
	sub.l	#(ROOT_ENTRY+31)>>5,d5
	sub.l	d3,d5
;<d5.l:�f�[�^�̈�̃Z�N�^��
	lsr.l	d4,d5
	addq.l	#2,d5
;<d5.l:�f�[�^�̈�̃N���X�^��+2
	moveq.l	#1,d4
	cmpi.w	#$F9FF,(a2)
	bne	1f			;���Ă���
	cmpi.b	#$FF,(2,a2)
	bne	1f			;���Ă���
	IOCS	_B_SFTSNS
	and.b	d0,d4			;SHIFT�L�[�̏��
	btst.l	#0,d6
	beq	@f			;�������w�肪�Ȃ�
	eori.b	#1,d4			;SHIFT�L�[�̏����𔽓]����
@@:	tst.l	d4
	beq	2f			;���������Ȃ�
1:	movea.l	a2,a0			;�擪�A�h���X
	move.l	d3,d0			;1��FAT�̈�Ɏg�p����Z�N�^��
	lsl.l	#10-2,d0		;1��FAT�̈�Ɏg�p����o�C�g��/4
	subq.w	#1,d0
@@:	clr.l	(a0)+			;FAT��������
	dbra	d0,@b
	move.w	#ROOT_ENTRY*32/4-1,d0
@@:	clr.l	(a0)+			;���[�g�f�B���N�g����������
	dbra	d0,@b
	moveq.l	#$F9,d0
	ror.l	#8,d0
	cmp.l	#$00000FF7,d5
	bcc	@f
	clr.b	d0
@@:	move.l	d0,(a2)			;FAT�̃w�b�_���Z�b�g
2:
;<d4.l:�������t���O(0=���������Ȃ�����,1=����������)
;�A�N�Z�X�����v
	btst.l	#2,d6
	sne.b	(24,a3)
;���b�Z�[�W�\��
	lea.l	(param_ld_message,pc),a1
	moveq.l	#'A',d0
	add.b	(22,a5),d0		;�h���C�u��
	add.b	(unitCounter)r,d0
	move.b	d0,(param_ld_drive-param_ld_message,a1)
	move.l	a2,d0
	lea.l	(param_ld_start-param_ld_message,a1),a0
	bsr	hex8			;������16�i��8��
	add.l	d2,d0
	subq.l	#1,d0
	lea.l	(param_ld_end-param_ld_message,a1),a0
	bsr	hex8			;������16�i��8��
	bsr	print
	lea.l	(param_ld_not_initialized,pc),a1	;'�͏��������܂���'
	tst.l	d4
	beq	@f
	lea.l	(param_ld_initialized,pc),a1	;'�����������܂���'
@@:	bsr	print
;
	addq.b	#1,(unitCounter)r
	rts

param_ld_message:
	.dc.b	'�q�`�l�f�B�X�N '
param_ld_drive:
	.dc.b	'?: $'
param_ld_start:
	.dc.b	'xxxxxxxx�`$'
param_ld_end:
	.dc.b	'xxxxxxxx ',0
param_ld_not_initialized:
	.dc.b	'�͏��������܂���',13,10,0
param_ld_initialized:
	.dc.b	'�����������܂���',13,10,0
	.even

param_ld_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz �� -ld �͓����Ɏw��ł��܂���D-ld �͖����ł�',13,10,0
	.even

param_ld_cannot:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J��������������܂���D-ld �͖����ł�',13,10,0
	.even

param_ld_toomany:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld �̃��j�b�g�����������܂�',13,10,0
	.even

param_ld_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld �̎w�肪�ُ�ł�',13,10,0
	.even

param_ld_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld �̎w�肪�傫�����܂�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-cm<mode>
;	<mode>	�L���b�V�����[�h
;		0	�L���b�V������,���C�g�X���[
;		1	�L���b�V������,�R�s�[�o�b�N
;		2	�L���b�V���֎~,�X�g�A�o�b�t�@�֎~
;		3	�L���b�V���֎~,�X�g�A�o�b�t�@����
;����:	�������̃L���b�V�����[�h���w�肵�܂��B�f�t�H���g�̓��C�g
;	�X���[�ł��B
param_cm:
	moveq.l	#0,d0
	move.b	(a0),d0
	sub.b	#'0',d0
	bmi	param_cm_illegal
	cmp.b	#3,d0
	bhi	param_cm_illegal
	move.b	d0,mainMemoryCacheMode
	move.b	d0,localMemoryCacheMode
	lsl.l	#PD_CM_BIT,d0
	andi.l	#.not.PD_CM_MASK,mainPD
	or.l	d0,mainPD
	rts

param_cm_illegal:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-cm �̎w�肪�ُ�ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-bg
;����:	�X���b�h�Ԃ̔r��������s���܂��B
;	-bg���w�肷��ƁA�X���b�h���؂�ւ��x�ɁAFPU�̓������
;	�Ɗe���W�X�^�A�W���n���h���A�W���n���h���̕ϊ���ԁA�e�h
;	���C�u�̃J�����g�f�B���N�g���A�J�����g�h���C�u���؂�ւ�
;	��܂��B
;	CONFIG.SYS��FILES�̒l�͍Œ�ł�30�ȏ���w�肵�ĉ������B
param_bg:
	tst.b	(backgroundFlag)r
	bne	99f			;-bg�͊��Ɏw�肳�ꂽ
	tst.w	$1C58.w			;process�̃X���b�h��-1
	beq	param_bg_no_process	;�T�u�X���b�h�͎g���Ȃ�
	cmpi.w	#30+2,$1C6E.w		;files��30�ȏォ
	blo	param_bg_no_files	;files�̎w��l������������
	movea.l	(mainLowerEnd)r,a1	;�r��������̐擪
	move.l	a1,(exclusiveStart)r
	move.w	#xSize2,d0		;�r��������1�̃T�C�Y
	mulu.w	$1C58.w,d0		;�T�u�X���b�h�̔r��������̃T�C�Y
	add.l	#$0000000F,d0		;16�̔{���ɐ؂�グ��
	and.l	#$FFFFFFF0,d0
	adda.l	d0,a1			;�r��������̖���+1
	move.l	(mainUpperStart)r,d0
	sub.l	#128*1024,d0
	cmpa.l	d0,a1
	bhi	param_bg_over
	move.l	a1,(exclusiveEnd)r
	move.l	a1,(mainLowerEnd)r
	st.b	(backgroundFlag)r
99:	rts

param_bg_no_process:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'process ���w�肳��Ă��܂���D-bg �͖����ł�',13,10,0
	.even

param_bg_no_files:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'files �̎w��l�����������܂��D-bg �͖����ł�',13,10,0
	.even

param_bg_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���������s�����Ă��܂��D-bg �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-sd
;����:	IOCS�ɂ��DMA�]�����\�t�g�]���ɂ��܂��B
param_sd:
	st.b	(softwareIocsDma)r
	rts

;----------------------------------------------------------------
;���@:	-fe
;����:	060turbo.sys�̓�����FE�t�@���N�V�������g�p���邱�Ƃ𖾎�
;	���܂��B�ォ��FLOATn.X��g�ݍ��ނ��Ƃ��ł��Ȃ��Ȃ�܂��B
param_fe:
	cmpi.b	#6,$0CBC.w
	bne	param_fe_not_68060	;68060�ȊO�ł͎w��ł��Ȃ�
	move.l	#'FEfn',_060_fpsp_fline-4
	rts

param_fe_not_68060:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-fe �� 68060 �ȊO�ł͎w��ł��܂���D-fe �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-ls
;����:	�x�N�^�̈悩��Human�{�̖̂����܂ł�060turbo.sys�{�̂����[
;	�J���������ɃR�s�[���Ďg���܂��B
param_ls:
	tst.b	(localSystemArea)r
	bne	99f			;-ls�͊��Ɏw�肳�ꂽ
	tst.b	(forceNoSimm)r
	bne	param_ls_nosimm		;-lz���w�肳��Ă���
	cmpi.b	#3,$0CBC.w
	beq	param_ls_68030		;68030�ł͎w��ł��Ȃ�
	tst.b	(noTranslation)r
	bne	param_ls_notrans	;-nt���w�肳��Ă���
	tst.l	(localMemorySize)r
	beq	param_ls_cannot
;�V�X�e�����R�s�[����̈���m��
	move.l	#keepTail,d1
	and.l	#PAGE_MASK,d1		;�ϊ����镔���̖����Ȃ̂Ő؂�̂Ă�
	sub.l	#deviceHeader,d1
	and.l	#PAGE_MASK,d1		;060turbo.sys�̏풓�����̒���
	add.l	#$0001447A.and.PAGE_MASK,d1	;Human�̒���
	move.l	(localUpperStart)r,d0
	sub.l	d1,d0
	cmp.l	(localLowerEnd)r,d0
	blo	param_ls_over
	move.l	d0,(localUpperStart)r
	move.l	d0,(localSystemStart)r
	add.l	d1,d0
	move.l	d0,(localSystemEnd)r
	st.b	(localSystemArea)r
99:	rts

param_ls_nosimm:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lz �� -ls �͓����Ɏw��ł��܂���D-ls �͖����ł�',13,10,0
	.even

param_ls_68030:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ls �� 68030 �ł͎w��ł��܂���D-ls �͖����ł�',13,10,0
	.even

param_ls_notrans:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-nt �� -ls �͓����Ɏw��ł��܂���D-ls �͖����ł�',13,10,0
	.even

param_ls_over:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J�����������s�����Ă��܂��D-ls �͖����ł�',13,10,0
	.even

param_ls_cannot:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'���[�J��������������܂���D-ls �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-np
;����:	�������ȊO�̃f�o�C�X�Ăяo���Ńf�[�^�L���b�V���̃v�b�V��
;	����і��������s���܂���B
;	SCSI�]���͋����I�Ƀ\�t�g�]���ɂȂ�܂��B
param_np:
	tst.b	(deviceCacheNoPush)r
	bne	99f				;-np�͊��Ɏw�肳�ꂽ
	st.b	(patchIocsScsi)r		;SCSI�������I�Ƀ\�t�g�]���ɂ���
	st.b	(forceSoftScsi)r
	st.b	([$1C20.w],pDeviceNoPush)	;Human��-np��������
	st.b	(deviceCacheNoPush)r
99:	rts

;----------------------------------------------------------------
;���@:	-ad
;����:	ADPCM�֌W��IOCS�R�[���Ƀp�b�`�����Ăă��[�J�����������璼
;	�ڍĐ��ł���悤�ɂ��܂��B
param_ad:
	st.b	(patchIocsAdpcm)r
	rts

;----------------------------------------------------------------
;���@:	-lz
;����:	SIMM����������Ă��Ă��g��Ȃ����Ƃɂ��܂��B
param_lz:
	tst.b	(forceNoSimm)r
	bne	99f			;-lz�͊��Ɏw�肳�ꂽ
	tst.l	(localMemorySize)r
	beq	99f			;���[�J�����������Ȃ�
	tst.l	(localRamdiskAreaSize)r
	bne	param_lz_error
	tst.b	(localAreaDescriptor)r
	bne	param_lz_error
	tst.b	(localRomArea)r
	bne	param_lz_error
	tst.b	(useJointMode)r
	bne	param_lz_error
	tst.b	(jointMode)r
	bne	param_lz_error
	tst.b	(localSystemArea)r
	bne	param_lz_error
	clr.l	(localMemorySize)r
	move.l	(localMemoryStart)r,(localMemoryEnd)r
	clr.l	(localLowerStart)r
	clr.l	(localLowerEnd)r
	clr.l	(localUpperStart)r
	clr.l	(localUpperEnd)r
	clr.l	(localRamdiskAreaStart)r
	clr.l	(localRamdiskAreaEnd)r
	st.b	(forceNoSimm)r
99:	rts

param_lz_error:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-ld,-lr,-ls,-lt,-xm �� -lz �͓����Ɏw��ł��܂���D-lz �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;���@:	-nt
;����:	�A�h���X�ϊ����s���܂���B
;	���@����ю��@�Ɠ����菇�ŃL���b�V�����C�����[�U���悤��
;	����G�~�����[�^�ł͎w�肵�Ȃ��ł��������B
;	-lr,-ls,-lt,-mm,-ts �� -nt �͓����Ɏw��ł��܂���B
param_nt:
	tst.b	(noTranslation)r
	bne	99f			;-nt�͊��Ɏw�肳�ꂽ(68030���܂�)
	tst.b	(localRomArea)r
	bne	param_nt_error		;-lr���w�肳��Ă���
	tst.b	(localSystemArea)r
	bne	param_nt_error		;-ls���w�肳��Ă���
	tst.b	(localAreaDescriptor)r
	bne	param_nt_error		;-lt���w�肳��Ă���
	tst.l	(mainMemorySize)r
	bpl	param_nt_error		;-mm���w�肳��Ă���
	tst.l	(descAreaSize)r
	bne	param_nt_error		;-ts���w�肳��Ă���
	st.b	(noTranslation)r
99:	rts

param_nt_error:
	lea.l	(@f,pc),a1
	bra	print
@@:	.dc.b	'-lr,-ls,-lt,-mm,-ts �� -nt �͓����Ɏw��ł��܂���D-nt �͖����ł�',13,10,0
	.even

;----------------------------------------------------------------
;������𕄍��Ȃ�10�i���ƌ��Ȃ��Đ��l�ɕϊ�����
;<a0.l:������̃A�h���X
;>d0.l:���l(0�`$7FFFFFFF,-1=�G���[)
;>a0.l:�����̎��̃A�h���X
;>n-flag:mi=�G���[
stou::
	move.l	d1,-(sp)
	moveq.l	#0,d0
	moveq.l	#0,d1
1:	move.b	(a0)+,d1
	sub.b	#'0',d1
	bcs	3f
	cmp.b	#10,d1
	bcc	3f
	mulu.l	#10,d0
	bvs	2f
	bmi	2f
	add.l	d1,d0
	bcs	2f
	bpl	1b
2:	moveq.l	#-1,d0
3:	subq.l	#1,a0
	move.l	(sp)+,d1
	tst.l	d0
	rts

;----------------------------------------------------------------
;������\��
print::
	move.l	d0,-(sp)
	move.l	a1,-(sp)
	DOS	_PRINT
	addq.l	#4,sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;������16�i��8��
hex8::
	movem.l	d1-d2,-(sp)
	moveq.l	#8-1,d2
1:	rol.l	#4,d0
	moveq.l	#$0F,d1
	and.b	d0,d1
	move.b	(2f,pc,d1.w),(a0)+
	dbra	d2,1b
	movem.l	(sp)+,d1-d2
	rts
2:	.dc.b	'0123456789ABCDEF'

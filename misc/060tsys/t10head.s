	.include	t00iocs.equ
	.include	t01dos.equ
	.include	t02const.equ

	.cpu	68060

;----------------------------------------------------------------
;�f�o�C�X�w�b�_
deviceHeader::
	.dc.l	-1
	.dc.w	$0000
	.dc.l	strategyRoutine
	.dc.l	interruptRoutine
	.dc.b	1,'RAMDISK'

requestHeader:
	.ds.l	1

deviceJumpTable::
	.dc.l	deviceInitialize	;������
	.dc.l	deviceCheck		;���f�B�A�`�F�b�N
	.dc.l	noError
	.dc.l	commandError
	.dc.l	deviceInput		;����
	.dc.l	deviceSense		;��Ԏ擾
	.dc.l	noError
	.dc.l	noError
	.dc.l	deviceOutput		;�o��
	.dc.l	deviceOutput		;�o��
	.dc.l	noError
	.dc.l	noError
	.dc.l	commandError

;�X�g���e�W���[�`��
strategyRoutine:
	move.l	a5,requestHeader
	rts

;�C���^���v�g���[�`��
interruptRoutine:
	move.l	a5,-(sp)
	move.l	d0,-(sp)
	movea.l	requestHeader,a5
	moveq.l	#0,d0
	move.b	(2,a5),d0		;�R�}���h�R�[�h
	lsl.l	#2,d0
	pea.l	(@f,pc)
	move.l	(deviceJumpTable,pc,d0.l),-(sp)
	rts				;�R�}���h�̏������Ă�
@@:	move.b	d0,(3,a5)		;�G���[�R�[�h(����)
	lsr.w	#8,d0
	move.b	d0,(4,a5)		;�G���[�R�[�h(���)
	move.l	(sp)+,d0
	movea.l	(sp)+,a5
	rts

noError:
	moveq.l	#0,d0
	rts

commandError:
	move.w	#$5003,d0
	rts

;----------------------------------------------------------------
;�x�N�^�e�[�u��
	.align	4,$2048
vectorTable::
vectorInfoAccessError::	.dc.l	ACCESS_ERROR
vectorOldAccessError::	.dc.l	0
vectorAccessError::	.dc.l	accessError

vectorInfoPRIVILEGE::	.dc.l	PRIVILEGE
vectorOldPRIVILEGE::	.dc.l	0
vectorPRIVILEGE::	.dc.l	_060_fpsp_fline		;privilegeViolation

vectorInfoFLINE::	.dc.l	FLINE
vectorOldFLINE::	.dc.l	0
vectorFLINE::		.dc.l	_060_fpsp_fline

vectorInfoBSUN::	.dc.l	BSUN
vectorOldBSUN::		.dc.l	0
vectorBSUN::		.dc.l	_060_real_bsun

vectorInfoINEX::	.dc.l	INEX
vectorOldINEX::		.dc.l	0
vectorINEX::		.dc.l	_fpsp_inex
				;_060FPSP_TABLE+$000019D4
				;_060FPSP_TABLE+$28
				;$80000000+_060FPSP_TABLE+$28+2

vectorInfoDZ::		.dc.l	DZ
vectorOldDZ::		.dc.l	0
vectorDZ::		.dc.l	_fpsp_dz
				;_060FPSP_TABLE+$00001B32
				;_060FPSP_TABLE+$20
				;$80000000+_060FPSP_TABLE+$20+2

vectorInfoUNFL::	.dc.l	UNFL
vectorOldUNFL::		.dc.l	0
vectorUNFL::		.dc.l	_fpsp_unfl
				;_060FPSP_TABLE+$0000048A
				;_060FPSP_TABLE+$18
				;$80000000+_060FPSP_TABLE+$18+2

vectorInfoOPERR::	.dc.l	OPERR
vectorOldOPERR::	.dc.l	0
vectorOPERR::		.dc.l	_fpsp_operr
				;_060FPSP_TABLE+$000015FE
				;_060FPSP_TABLE+$08
				;$80000000+_060FPSP_TABLE+$08+2

vectorInfoOVFL::	.dc.l	OVFL
vectorOldOVFL::		.dc.l	0
vectorOVFL::		.dc.l	_fpsp_ovfl
				;_060FPSP_TABLE+$000002C8
				;_060FPSP_TABLE+$10
				;$80000000+_060FPSP_TABLE+$10+2

vectorInfoSNAN::	.dc.l	SNAN
vectorOldSNAN::		.dc.l	0
vectorSNAN::		.dc.l	_fpsp_snan
				;_060FPSP_TABLE+$00001742
				;_060FPSP_TABLE+$00
				;$80000000+_060FPSP_TABLE+$00+2

vectorInfoUNSUPP::	.dc.l	UNSUPP
vectorOldUNSUPP::	.dc.l	0
vectorUNSUPP::		.dc.l	_fpsp_unsupp
				;_060FPSP_TABLE+$00000668
				;_060FPSP_TABLE+$38
				;$80000000+_060FPSP_TABLE+$38+2

vectorInfoEFFADD::	.dc.l	EFFADD
vectorOldEFFADD::	.dc.l	0
vectorEFFADD::		.dc.l	_fpsp_effadd
				;_060FPSP_TABLE+$0000106E
				;_060FPSP_TABLE+$40
				;$80000000+_060FPSP_TABLE+$40+2

vectorInfoUNINT::	.dc.l	UNINT
vectorOldUNINT::	.dc.l	0
vectorUNINT::		.dc.l	_060_isp_unint

vectorInfoIocsAdpcmout::	.dc.l	$0400+_ADPCMOUT*4
vectorOldIocsAdpcmout::	.dc.l	0
vectorIocsAdpcmout::	.dc.l	iocsAdpcmout

vectorInfoIocsAdpcminp::	.dc.l	$0400+_ADPCMINP*4
vectorOldIocsAdpcminp::	.dc.l	0
vectorIocsAdpcminp::	.dc.l	iocsAdpcminp

vectorInfoIocsAdpcmaot::	.dc.l	$0400+_ADPCMAOT*4
vectorOldIocsAdpcmaot::	.dc.l	0
vectorIocsAdpcmaot::	.dc.l	iocsAdpcmaot

vectorInfoIocsAdpcmain::	.dc.l	$0400+_ADPCMAIN*4
vectorOldIocsAdpcmain::	.dc.l	0
vectorIocsAdpcmain::	.dc.l	iocsAdpcmain

vectorInfoIocsAdpcmlot::	.dc.l	$0400+_ADPCMLOT*4
vectorOldIocsAdpcmlot::	.dc.l	0
vectorIocsAdpcmlot::	.dc.l	iocsAdpcmlot

vectorInfoIocsAdpcmlin::	.dc.l	$0400+_ADPCMLIN*4
vectorOldIocsAdpcmlin::	.dc.l	0
vectorIocsAdpcmlin::	.dc.l	iocsAdpcmlin

vectorInfoIocsAdpcmsns::	.dc.l	$0400+_ADPCMSNS*4
vectorOldIocsAdpcmsns::	.dc.l	0
vectorIocsAdpcmsns::	.dc.l	iocsAdpcmsns

vectorInfoIocsAdpcmmod::	.dc.l	$0400+_ADPCMMOD*4
vectorOldIocsAdpcmmod::	.dc.l	0
vectorIocsAdpcmmod::	.dc.l	iocsAdpcmmod

vectorInfoIocsDmamove::	.dc.l	$0400+_DMAMOVE*4
vectorOldIocsDmamove::	.dc.l	0
vectorIocsDmamove::	.dc.l	iocsDmamove

vectorInfoIocsDmamovA::	.dc.l	$0400+_DMAMOV_A*4
vectorOldIocsDmamovA::	.dc.l	0
vectorIocsDmamovA::	.dc.l	iocsDmamovA

vectorInfoIocsDmamovL::	.dc.l	$0400+_DMAMOV_L*4
vectorOldIocsDmamovL::	.dc.l	0
vectorIocsDmamovL::	.dc.l	iocsDmamovL

vectorInfoIocsDmamode::	.dc.l	$0400+_DMAMODE*4
vectorOldIocsDmamode::	.dc.l	0
vectorIocsDmamode::	.dc.l	iocsDmamode

vectorInfoIocsSysStat::	.dc.l	$0400+_SYS_STAT*4
vectorOldIocsSysStat::	.dc.l	0
vectorIocsSysStat::	.dc.l	iocsSysStat

vectorInfoIocsScsidrv::	.dc.l	$0400+_SCSIDRV*4
vectorOldIocsScsidrv::	.dc.l	0
vectorIocsScsidrv::	.dc.l	iocsScsidrv

vectorInfoIocsPrnintst::	.dc.l	$0400+_PRNINTST*4
vectorOldIocsPrnintst::	.dc.l	0
vectorIocsPrnintst::	.dc.l	iocsPrnintst

vectorInfoPrnint::	.dc.l	PRNINT
vectorOldPrnint::	.dc.l	0
vectorPrnint::		.dc.l	((PRNINT>>2)<<24)+defaultPrnint

vectorInfoIocsHimem::	.dc.l	$0400+_HIMEM*4
vectorOldIocsHimem::	.dc.l	0
vectorIocsHimem::	.dc.l	iocsHimem

vectorInfoDosExit::	.dc.l	$1800+(_EXIT-$FF00)*4
vectorOldDosExit::	.dc.l	0
vectorDosExit::		.dc.l	dosExit

vectorInfoDosKeeppr::	.dc.l	$1800+(_KEEPPR-$FF00)*4
vectorOldDosKeeppr::	.dc.l	0
vectorDosKeeppr::	.dc.l	dosKeeppr

vectorInfoDosMalloc::	.dc.l	$1800+(_MALLOC-$FF00)*4
vectorOldDosMalloc::	.dc.l	0
vectorDosMalloc::	.dc.l	dosMalloc

vectorInfoDosMfree::	.dc.l	$1800+(_MFREE-$FF00)*4
vectorOldDosMfree::	.dc.l	0
vectorDosMfree::	.dc.l	dosMfree

vectorInfoDosSetblock::	.dc.l	$1800+(_SETBLOCK-$FF00)*4
vectorOldDosSetblock::	.dc.l	0
vectorDosSetblock::	.dc.l	dosSetblock

vectorInfoDosExec::	.dc.l	$1800+(_EXEC-$FF00)*4
vectorOldDosExec::	.dc.l	0
vectorDosExec::		.dc.l	dosExec

vectorInfoDosExit2::	.dc.l	$1800+(_EXIT2-$FF00)*4
vectorOldDosExit2::	.dc.l	0
vectorDosExit2::	.dc.l	dosExit2

vectorInfoDos0Malloc2::	.dc.l	$1800+(~0~_MALLOC2-$FF00)*4
vectorOldDos0Malloc2::	.dc.l	0
vectorDos0Malloc2::	.dc.l	dosMalloc2

vectorInfoDos0Malloc3::	.dc.l	$1800+(~0~_MALLOC3-$FF00)*4
vectorOldDos0Malloc3::	.dc.l	0
vectorDos0Malloc3::	.dc.l	dosMalloc3

vectorInfoDos0Setblock2::	.dc.l	$1800+(~0~_SETBLOCK2-$FF00)*4
vectorOldDos0Setblock2::	.dc.l	0
vectorDos0SetBlock2::	.dc.l	dosSetblock2

vectorInfoDos0Malloc4::	.dc.l	$1800+(~0~_MALLOC4-$FF00)*4
vectorOldDos0Malloc4::	.dc.l	0
vectorDos0Malloc4::	.dc.l	dosMalloc4

vectorInfoDos0SMalloc2::	.dc.l	$1800+(~0~_S_MALLOC2-$FF00)*4
vectorOldDos0SMalloc2::	.dc.l	0
vectorDos0SMalloc2::	.dc.l	dosSMalloc2

vectorInfoDos0SMalloc::	.dc.l	$1800+(~0~_S_MALLOC-$FF00)*4
vectorOldDos0SMalloc::	.dc.l	0
vectorDos0SMalloc::	.dc.l	dosSMalloc

vectorInfoDos0SMfree::	.dc.l	$1800+(~0~_S_MFREE-$FF00)*4
vectorOldDos0SMfree::	.dc.l	0
vectorDos0SMfree::	.dc.l	dosSMfree

vectorInfoDos0SProcess::	.dc.l	$1800+(~0~_S_PROCESS-$FF00)*4
vectorOldDos0SProcess::	.dc.l	0
vectorDos0SProcess::	.dc.l	dosSProcess

vectorInfoDosMalloc2::	.dc.l	$1800+(_MALLOC2-$FF00)*4
vectorOldDosMalloc2::	.dc.l	0
vectorDosMalloc2::	.dc.l	dosMalloc2

vectorInfoDosMalloc3::	.dc.l	$1800+(_MALLOC3-$FF00)*4
vectorOldDosMalloc3::	.dc.l	0
vectorDosMalloc3::	.dc.l	dosMalloc3

vectorInfoDosSetblock2::	.dc.l	$1800+(_SETBLOCK2-$FF00)*4
vectorOldDosSetblock2::	.dc.l	0
vectorDosSetBlock2::	.dc.l	dosSetblock2

vectorInfoDosMalloc4::	.dc.l	$1800+(_MALLOC4-$FF00)*4
vectorOldDosMalloc4::	.dc.l	0
vectorDosMalloc4::	.dc.l	dosMalloc4

vectorInfoDosSMalloc2::	.dc.l	$1800+(_S_MALLOC2-$FF00)*4
vectorOldDosSMalloc2::	.dc.l	0
vectorDosSMalloc2::	.dc.l	dosSMalloc2

vectorInfoDosSMalloc::	.dc.l	$1800+(_S_MALLOC-$FF00)*4
vectorOldDosSMalloc::	.dc.l	0
vectorDosSMalloc::	.dc.l	dosSMalloc

vectorInfoDosSMfree::	.dc.l	$1800+(_S_MFREE-$FF00)*4
vectorOldDosSMfree::	.dc.l	0
vectorDosSMfree::	.dc.l	dosSMfree

vectorInfoDosSProcess::	.dc.l	$1800+(_S_PROCESS-$FF00)*4
vectorOldDosSProcess::	.dc.l	0
vectorDosSProcess::	.dc.l	dosSProcess

vectorInfoDosOpenPr::	.dc.l	$1800+(_OPEN_PR-$FF00)*4
vectorOldDosOpenPr::	.dc.l	0
vectorDosOpenPr::	.dc.l	dosOpenPr

vectorInfoDosKillPr::	.dc.l	$1800+(_KILL_PR-$FF00)*4
vectorOldDosKillPr::	.dc.l	0
vectorDosKillPr::	.dc.l	dosKillPr

vectorInfoDosChangePr::	.dc.l	$1800+(_CHANGE_PR-$FF00)*4
vectorOldDosChangePr::	.dc.l	0
vectorDosChangePr::	.dc.l	dosChangePr

vectorInfoHumanTrap10::	.dc.l	$1C6A
vectorOldHumanTrap10::	.dc.l	0
vectorHumanTrap10::	.dc.l	humanTrap10

			.dc.l	0


;----------------------------------------------------------------
;
;	�Ǘ��̈�͈̔�
;
;----------------------------------------------------------------
	.align	4,$2048
mainLowerStart::
	.dc.l	0
mainLowerEnd::
	.dc.l	0
mainUpperStart::
	.dc.l	0
mainUpperEnd::
	.dc.l	0
localLowerStart::
	.dc.l	0
localLowerEnd::
	.dc.l	0
localUpperStart::
	.dc.l	0
localUpperEnd::
	.dc.l	0

;----------------------------------------------------------------
;
;	�o�X�G���[�`�F�b�N���[�`���̃��[�N
;
;----------------------------------------------------------------
	.align	4,$2048
dosBusErrVbr::
	.dc.l	0			;�o�X�G���[�`�F�b�N�p�̉��̃x�N�^�e�[�u���̃A�h���X
dosBusErrSsp::
	.dc.l	0			;�o�X�G���[�`�F�b�N�p�̉��̃X�[�p�[�o�C�U�X�^�b�N

;----------------------------------------------------------------
;
;	�e��t���O,�J�E���^
;
;----------------------------------------------------------------
localRomArea::
	.dc.b	0			;-1=ROM�����[�J���������ɃR�s�[���Ďg��
localSystemArea::
	.dc.b	0			;-1=�x�N�^����Human�܂łƃh���C�o�{�̂�,
					;���[�J���������ɃR�s�[���Ďg��
localAreaDescriptor::
	.dc.b	0			;-1=�f�X�N���v�^�̗̈�����[�J���������ɔz�u����
patchIocsScsi::
	.dc.b	0			;-1=_SCSIDRV�Ƀp�b�`�����Ă�
forceSoftScsi::
	.dc.b	0			;-1=SCSI�������I�Ƀ\�t�g�]���ɂ���
patchDevice::
	.dc.b	0			;-1=�f�o�C�X�h���C�o�̃A�N�Z�X�Ƀp�b�`�����Ă�
deviceCacheNoPush::
	.dc.b	0			;-1=�������ȊO�̃f�o�C�X�Ăяo���ŃL���b�V���v�b�V�����Ȃ�
useIocsHimem::
	.dc.b	-1			;-1=_HIMEM���g��
unitCounter::
	.dc.b	0			;RAMDISK�̃��j�b�g��
useExtendedMode::
	.dc.b	0			;-1=�g�����[�h���g��
extendedMode::
	.dc.b	0			;-1=���݊g�����[�h�ɂȂ��Ă���
useJointMode::
	.dc.b	0			;-1=�������[�h���g��
jointMode::
	.dc.b	0			;-1=���݌������[�h�ɂȂ��Ă���
mainMemoryCacheMode::
	.dc.b	0			;���C���������̃L���b�V�����[�h
localMemoryCacheMode::
	.dc.b	0			;���[�J���������̃L���b�V�����[�h
softwareIocsDma::
	.dc.b	0			;-1=IOCS�ɂ��DMA�]�����\�t�g�]���ɂ���
patchIocsAdpcm::
	.dc.b	0			;-1=ADPCM�֌W��IOCS�R�[���Ƀp�b�`�����Ă�
forceNoSimm::
	.dc.b	0			;-1=SIMM����������Ă��Ă��g��Ȃ����Ƃɂ���
noTranslation::
	.dc.b	0			;-1=�A�h���X�ϊ����s��Ȃ�

	.even
scsiRevisionCode::
	.dc.w	0			;SCSI _S_REVISION�̌���
					;$000A�ȏ��SRAM�̃\�t�g�]���t���O�ɑΉ����Ă���

;----------------------------------------------------------------
;
;	���[�J����������ɒu��ROM�̈�
;
;----------------------------------------------------------------
	.align	4,$2048
localRomStart::
	.dc.l	0
localRomEnd::
	.dc.l	0

;----------------------------------------------------------------
;
;	���[�J����������ɒu���V�X�e���̈�
;
;----------------------------------------------------------------
	.align	4,$2048
localSystemStart::
	.dc.l	0
localSystemEnd::
	.dc.l	0

;----------------------------------------------------------------
;
;	�f�X�N���v�^�̗̈�
;
;----------------------------------------------------------------
	.align	4,$2048
;�y�[�W�C���f�b�N�X�t�B�[���h�̃r�b�g���ɉ����ĕω�����l
pageIndexWidth::			;�y�[�W�C���f�b�N�X�t�B�[���h�̃r�b�g��(5�`6)
	.dc.l	PAGE_INDEX_WIDTH	;	5
pageIndexSize::				;�y�[�W�e�[�u��1�Ɋ܂܂��y�[�W�f�X�N���v�^�̌�
	.dc.l	PAGE_INDEX_SIZE		;	32
pageIndexMask::				;�y�[�W�C���f�b�N�X�t�B�[���h�̃}�X�N
	.dc.l	PAGE_INDEX_MASK		;	31

pageOffsetWidth::			;�y�[�W���I�t�Z�b�g�̃r�b�g��(12�`13)
	.dc.l	PAGE_OFFSET_WIDTH	;	13=8KB/page
pageOffsetSize::			;1�y�[�W�̃T�C�Y
	.dc.l	PAGE_OFFSET_SIZE	;	$00002000=8KB/page
pageOffsetMask::			;�y�[�W���I�t�Z�b�g�̃}�X�N
	.dc.l	PAGE_OFFSET_MASK	;	$00001FFF

pageMask::				;�y�[�W�̐擪�A�h���X�̃}�X�N
	.dc.l	PAGE_MASK		;	$3FFFE000

pageDescSize::				;�y�[�W�e�[�u��1�̃T�C�Y
	.dc.l	PAGE_DESC_SIZE		;	$00000080
pageDescMask::				;�y�[�W�e�[�u���̐擪�̃A�h���X�̃}�X�N
	.dc.l	PAGE_DESC_MASK		;	$3FFFFF80

;�f�X�N���v�^�̗̈�͏��moves�ŃA�N�Z�X�����̂ŕ��i�͌����Ȃ��Ă悢
descAreaStart::
	.dc.l	0			;�f�X�N���v�^�̗̈�̐擪(�y�[�W�̐擪)
descAreaEnd::
	.dc.l	0			;�f�X�N���v�^�̗̈�̖���+1(�y�[�W�̖���+1)
descAreaSize::
	.dc.l	0			;�f�X�N���v�^�̗̈�̃T�C�Y(�y�[�W�T�C�Y�̔{���Ƃ͌���Ȃ�)

;�f�X�N���v�^�̗̈�
descHead::				;���[�g�f�X�N���v�^�̐擪
rootDescHead::				;�f�X�N���v�^�̗̈�̐擪
	.dc.l	0
rootDescTail::				;���[�g�f�X�N���v�^�̖���
pointerDescHead::			;�|�C���^�f�X�N���v�^�̐擪
	.dc.l	0
pointerDescTail::			;�|�C���^�f�X�N���v�^�̖����i�g�p���Ă��镔���̖���,�ρj
	.dc.l	0
pageDescHead::				;�y�[�W�f�X�N���v�^�̐擪�i�g�p���Ă��镔���̐擪,�ρj
	.dc.l	0
pageDescTail::				;�y�[�W�f�X�N���v�^�̖���
pointerCounterHead::			;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^�e�[�u���̐擪
	.dc.l	0
pageCounterTail::			;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^�e�[�u���̖���
descTail::				;�f�X�N���v�^�̗̈�̖���
	.dc.l	0

;----------------------------------------------------------------
;
;	�f�o�C�X�h���C�o�̓]���o�b�t�@
;
;----------------------------------------------------------------
	.align	4,$2048
tempBufferStart::
	.dc.l	0			;�]���o�b�t�@�̐擪
tempBufferEnd::
	.dc.l	0			;�]���o�b�t�@�̖���+1
tempBufferSize::
	.dc.l	0			;�]���o�b�t�@�̃o�C�g��(1024�̔{��)


;----------------------------------------------------------------
;
;	ADPCM�֌W�̃��[�N
;
;----------------------------------------------------------------
	.align	4,$2048
adpcmBufferStart::
	.dc.l	0			;ADPCM�]���o�b�t�@�̐擪
adpcmBufferEnd::
	.dc.l	0			;ADPCM�]���o�b�t�@�̖���
adpcmBufferSize::
	.dc.l	ADPCM_SPLIT_SIZE	;�����T�C�Y
adpcmLeftSize::
	.dc.l	0			;�܂��o�b�t�@�ɃR�s�[���Ă��Ȃ��T�C�Y
adpcmDataPtr::
	.dc.l	0			;�܂��o�b�t�@�ɃR�s�[���Ă��Ȃ��f�[�^
adpcmBufferPtr0::
	.dc.l	0			;�o�b�t�@0�ւ̃|�C���^
adpcmBufferPtr1::
	.dc.l	0			;�o�b�t�@1�ւ̃|�C���^

;----------------------------------------------------------------
;
;	���[�J��������
;
;----------------------------------------------------------------
	.align	4,$2048
localMemoryStart::
	.dc.l	0			;���[�J���������̐擪
localMemoryEnd::
	.dc.l	0			;���[�J���������̖���+1
localMemorySize::
	.dc.l	0			;���[�J���������̃T�C�Y(0=���݂��Ȃ�)

himemAreaStart::
	.dc.l	0			;_HIMEM�ŃA�N�Z�X����͈͂̐擪
himemAreaEnd::
	.dc.l	0			;_HIMEM�ŃA�N�Z�X����͈̖͂���+1
himemAreaSize::
	.dc.l	0			;_HIMEM�ŃA�N�Z�X����͈͂̃T�C�Y

;----------------------------------------------------------------
;
;	�g�����[�h
;
;----------------------------------------------------------------
	.align	4,$2048
mainMemorySize::
	.dc.l	-1			;���C���������̃T�C�Y

;----------------------------------------------------------------
;
;	�������[�h
;
;----------------------------------------------------------------
	.align	4,$2048
jointBlockHeader::
	.dc.l	0			;�����u���b�N�̃w�b�_(0=�g�����[�h�֎~)
jointBlockSize::
	.dc.l	DEFAULT_JOIN_SIZE	;�����u���b�N�̃T�C�Y(�w�b�_���܂܂Ȃ�)

;----------------------------------------------------------------
;
;	�X���b�h�̔r������֌W�̃��[�N
;
;----------------------------------------------------------------
backgroundFlag::
	.ds.b	1		;-1=�X���b�h�Ԃ̔r��������s��

	.align	4,$2048
exclusiveStart::
	.ds.l	1		;���C���X���b�h�ȊO�̔r��������̐擪
				;���C���X���b�h�ȊO�̔r���������,
				;1��xSize2�o�C�g��($1C58.w).w�K�v
exclusiveEnd::
	.ds.l	1		;���C���X���b�h�ȊO�̔r��������̖���+1

;�r��������ւ̃|�C���^�̃e�[�u��
;-1�͔r�������񂪑��݂��Ȃ�(����������Ă��Ȃ�)���Ƃ�����
	.align	4,$2048
xTable::
	.dc.l	mainExclusive
	.dcb.l	32-1,-1

;���C���X���b�h�̔r��������
mainExclusive::
	.ds.b	xSize		;�h���C�u�Ǘ��e�[�u���͊��ɑ��݂���̂ŕs�v

	.even
currentThreadId::
	.dc.w	0		;���݂̃X���b�h�ԍ�

;----------------------------------------------------------------
;
;	�t�@�C�����
;
;----------------------------------------------------------------
	.align	4
fileInfoHeapStart::
	.ds.l	1		;�t�@�C�����̗̈�(�q�[�v�Ǘ�)�̐擪
fileInfoHeapEnd::
	.ds.l	1		;�t�@�C�����̗̈�(�q�[�v�Ǘ�)�̖���
fileInfoHashTablePtr::
	.ds.l	1		;�n�b�V���e�[�u���ւ̃|�C���^(4*256�o�C�g)
				;���e�̓t�@�C�����ւ̃n���h��

;----------------------------------------------------------------
;
;	loadhigh�֘A�̃��[�N
;
;----------------------------------------------------------------
	.align	4,$2048
userAreaWork::
	.dc.l	0			;���[�U���[�h�̃��[�N�G���A
					;(�R�}���h���C���Ȃǂ�n���Ƃ��g�p����)
execLoadHigh::
	.dc.b	0			;_EXEC����_MALLOC�����Ƃ�loadhigh���邩(-1=yes)

defaultLoadArea::
	.dc.b	0			;���[�h�̈�̏���
					;	0	���ʂ̂�
					;	1	��ʂ̂�
					;	2	�e�Ɠ������̂�
					;	3	�e�Ɣ��Α��̂�
					;	4	�����Ȃ�,���ʗD��
					;	5	�����Ȃ�,��ʗD��
					;	6	�����Ȃ�,�e�Ɠ������D��
					;	7	�����Ȃ�,�e�Ɣ��Α��D��
					;	8	�����Ȃ�,�D��Ȃ�
defaultAllocArea::
	.dc.b	0			;�A���P�[�g�̈�̏���
					;	0	���ʂ̂�
					;	1	��ʂ̂�
					;	2	�e�Ɠ������̂�
					;	3	�e�Ɣ��Α��̂�
					;	4	�����Ȃ�,���ʗD��
					;	5	�����Ȃ�,��ʗD��
					;	6	�����Ȃ�,�e�Ɠ������D��
					;	7	�����Ȃ�,�e�Ɣ��Α��D��
					;	8	�����Ȃ�,�D��Ȃ�

;----------------------------------------------------------------
;
;	Human�̃o�[�W�����Ɉˑ�����萔�̃��[�N
;
;----------------------------------------------------------------
	.align	4,$2048
killPrEntry::
	.dc.l	$0000E60C		;_KILL_PR�̊J�n�ʒu
stdHdlDup0::
	.dc.l	$00013D1A		;�W���n���h���ϊ��e�[�u��
stdHdlToFcb::
	.dc.l	$00013D24		;�n���h���ԍ�=0�`5�̃n���h��FCB�ϊ��e�[�u��
stdFcbTable::
	.dc.l	$00013D30		;FCB�ԍ�=0�`5��FCB�e�[�u��

;----------------------------------------------------------------
;
;	RAMDISK�֌W�̃��[�N
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;���[�J�����������RAMDISK�̑��݂���͈�
;	RAMDISK�̗̈�ɊY������y�[�W�̓X�[�p�[�o�C�U�ی삳���
	.align	4,$2048
localRamdiskAreaStart::
	.dc.l	0			;�擪
localRamdiskAreaEnd::
	.dc.l	0			;����+1
localRamdiskAreaSize::
	.dc.l	0			;�T�C�Y(�y�[�W�T�C�Y�̔{��)

;----------------------------------------------------------------
;���C�����������RAMDISK�̑��݂���͈�
;	RAMDISK�̗̈�ɊY������y�[�W�̓X�[�p�[�o�C�U�ی삳���
	.align	4,$2048
mainRamdiskAreaStart::
	.dc.l	0			;�擪
mainRamdiskAreaEnd::
	.dc.l	0			;����+1
mainRamdiskAreaSize::
	.dc.l	0			;�T�C�Y(�y�[�W�T�C�Y�̔{��)

;----------------------------------------------------------------
;BPB�e�[�u���̃A�h���X
	.align	4,$2048
bpbTablePointer::
d = 0
  .rept MAXIMUM_UNIT
	.dc.l	bpbTable+d
d = d+28
  .endm

;----------------------------------------------------------------
;BPB�e�[�u��
	.align	4,$2048
bpbTable::
  .rept MAXIMUM_UNIT
	.dc.w	1024		;+0	1�Z�N�^������̃o�C�g��
	.dc.b	1		;+2	1�N���X�^������̃Z�N�^��
	.dc.b	1		;+3	FAT�̈�̌�
				;	bit7=1�̂Ƃ�2�o�C�gFAT�̏㉺�̃o�C�g����ꊷ����
	.dc.w	0		;+4	FAT�̐擪�Z�N�^�ԍ�
	.dc.w	ROOT_ENTRY	;+6	���[�g�f�B���N�g���ɓ���G���g����
	.dc.w	0		;+8	(�S�̈�̃Z�N�^��)
	.dc.b	$F9		;+10	���f�B�A�o�C�g
	.dc.b	1		;+11	1��FAT�̈�Ɏg�p����Z�N�^��
	.dc.l	DEFAULT_SIZE	;+12	�S�̈�̃Z�N�^��
	.dc.l	0		;+16	�擪�A�h���X(0=���̃��j�b�g�͑��݂��Ȃ�)
	.dc.l	0		;+20	�����A�h���X+1
	.dc.b	0		;+24	�A�N�Z�X�����v���g�����ǂ���
	.ds.b	3		;+25
				;+28
  .endm

;----------------------------------------------------------------
;
;	�f�o�b�O�p�T�u���[�`��
;
;----------------------------------------------------------------
;���l��16�i��8���ŕ\��
;<d0.l:���l
	.align	4,$2048
debugHex8::
	move.w	ccr,-(sp)
	swap.w	d0
	bsr	debugHex4
	swap.w	d0
	bsr	debugHex4
	move.w	(sp)+,ccr
	rts

;���l��16�i��4���ŕ\��
;<d0.w:���l
	.align	4,$2048
debugHex4::
	move.w	ccr,-(sp)
	rol.w	#8,d0
	bsr	debugHex2
	rol.w	#8,d0
	bsr	debugHex2
	move.w	(sp)+,ccr
	rts

;���l��16�i��2���ŕ\��
;<d0.b:���l
	.align	4,$2048
debugHex2::
	move.w	ccr,-(sp)
	movem.l	d1-d2,-(sp)
	moveq.l	#2-1,d2
@@:	rol.b	#4,d0
	moveq.l	#$0F,d1
	and.l	d0,d1
	move.b	(hexchar,pc,d1.l),d1
	bsr	debugPutc
	dbra	d2,@b
	movem.l	(sp)+,d1-d2
	move.w	(sp)+,ccr
	rts

hexchar:
	.dc.b	'0123456789ABCDEF'

;������\��
;<a1.l:������̃A�h���X
	.align	4,$2048
debugPrint::
	move.w	ccr,-(sp)
	movem.l	d0/a1,-(sp)
	moveq.l	#$21,d0
	trap	#15
	movem.l	(sp)+,d0/a1
	move.w	(sp)+,ccr
	rts

;1�����\��
;<d1.w:�����R�[�h
	.align	4,$2048
debugPutc::
	move.w	ccr,-(sp)
	movem.l	d0-d1,-(sp)
	moveq.l	#$20,d0
	trap	#15
	movem.l	(sp)+,d0-d1
	move.w	(sp)+,ccr
	rts

;1�L�[���͑҂�
	.align	4,$2048
debugKeyinp::
	move.w	ccr,-(sp)
	move.l	d0,-(sp)
	bra	2f
1:	moveq.l	#0,d0
	trap	#15
2:	moveq.l	#1,d0
	trap	#15
	tst.b	d0
	bne	1b
3:	moveq.l	#0,d0
	trap	#15
	tst.b	d0
	beq	3b
	move.l	(sp)+,d0
	move.w	(sp)+,ccr
	rts

;----------------------------------------------------------------
;
;	SCSI
;
;----------------------------------------------------------------

	.include	t00iocs.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;
;	IOCS _SCSIDRV
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _SCSIDRV
;	�o�b�t�@��DMA�]���ł��Ȃ��Ƃ�(�o�b�t�@�̕����A�h���X���_���A�h���X��
;	�قȂ�ꍇ����ѕ����A�h���X�����[�J�����������w���Ă���ꍇ)�̓\�t�g
;	�]���ɕύX����B
;	_S_REVISION�̕ԋp�l��$000A�ȏ�̂Ƃ�(SHARP�����g��SCSI�{�[�h,X68030��
;	����SCSI-BIOS�����Mach-2��SCSI-BIOS)��SRAM�̃\�t�g�]���t���O���g����
;	�\�t�g�]���ɕύX����B
;	_S_REVISION�̕ԋp�l��$000A�����̂Ƃ�(SUPER����XVICompact�܂ł�X68000��
;	����SCSI-BIOS)�͍����x���̓]���R�}���h(_S_READ,_S_READEXT�Ȃ�)�����O��
;	�W�J���Ē჌�x���̃\�t�g�]���R�}���h��p����B
	.text
	.align	4,$2048
iocsScsidrv::
	tst.b	patchIocsScsi
	beq	scsicall
	cmp.l	#(scsidrvJumpTableEnd-scsidrvJumpTable)/4,d1
	bcc	scsicall
	jmp	([scsidrvJumpTable,pc,d1.l*4])

	.align	4,$2048
scsidrvJumpTable:
	.dc.l	scsicall		;$00 _S_RESET
	.dc.l	scsicall		;$01 _S_SELECT
	.dc.l	scsicall		;$02 _S_SELECTA
	.dc.l	scsicall		;$03 _S_CMDOUT
	.dc.l	scsidrvDatain		;$04 _S_DATAIN
	.dc.l	scsidrvDataout		;$05 _S_DATAOUT
	.dc.l	scsicall		;$06 _S_STSIN
	.dc.l	scsicall		;$07 _S_MSGIN
	.dc.l	scsicall		;$08 _S_MSGOUT
	.dc.l	scsicall		;$09 _S_PHASE
	.dc.l	scsicall		;$0A _S_REVISION
	.dc.l	scsicall		;$0B _S_DATAIN_P
	.dc.l	scsicall		;$0C _S_DATAOUT_P
	.dc.l	scsicall		;$0D _S_MSGOUTEXT
	.dc.l	scsicall		;$0E 
	.dc.l	scsicall		;$0F 
	.dc.l	scsicall		;$10 
	.dc.l	scsicall		;$11 
	.dc.l	scsicall		;$12 
	.dc.l	scsicall		;$13 
	.dc.l	scsicall		;$14 
	.dc.l	scsicall		;$15 
	.dc.l	scsicall		;$16 
	.dc.l	scsicall		;$17 
	.dc.l	scsicall		;$18 
	.dc.l	scsicall		;$19 
	.dc.l	scsicall		;$1A 
	.dc.l	scsicall		;$1B 
	.dc.l	scsicall		;$1C 
	.dc.l	scsicall		;$1D 
	.dc.l	scsicall		;$1E 
	.dc.l	scsicall		;$1F 
	.dc.l	scsidrvInquiry		;$20 _S_INQUIRY
	.dc.l	scsidrvRead		;$21 _S_READ
	.dc.l	scsidrvWrite		;$22 _S_WRITE
	.dc.l	scsicall		;$23 _S_FORMAT
	.dc.l	scsicall		;$24 _S_TESTUNIT
	.dc.l	scsidrvReadcap		;$25 _S_READCAP
	.dc.l	scsidrvReadext		;$26 _S_READEXT
	.dc.l	scsidrvWriteext		;$27 _S_WRITEEXT
	.dc.l	scsidrvVerifyext	;$28 _S_VERIFYEXT
	.dc.l	scsidrvModesense	;$29 _S_MODESENSE
	.dc.l	scsidrvModeselect	;$2A _S_MODESELECT
	.dc.l	scsicall		;$2B _S_REZEROUNIT
	.dc.l	scsidrvRequest		;$2C _S_REQUEST
	.dc.l	scsicall		;$2D _S_SEEK
	.dc.l	scsidrvReaddma		;$2E _S_READDMA
	.dc.l	scsicall		;$2F _S_STARTSTOP
	.dc.l	scsicall		;$30 _S_SEJECT
	.dc.l	scsidrvReassign		;$31 _S_REASSIGN
	.dc.l	scsicall		;$32 _S_PAMEDIUM
	.dc.l	scsicall		;$33 
	.dc.l	scsicall		;$34 
	.dc.l	scsicall		;$35 
	.dc.l	scsicall		;$36 _S_DSKINI
	.dc.l	scsicall		;$37 _S_FORMATB
	.dc.l	scsicall		;$38 _S_BADFMT
	.dc.l	scsicall		;$39 _S_ASSIGN
scsidrvJumpTableEnd:

;----------------------------------------------------------------
;����_SCSIDRV���Ăяo��
;	Mach-2�ɂ��v�����^���f�B�[���荞�݃x�N�^�̕ύX���u���b�N����B
;<d1.l:�R�}���h
	.text
	.align	4,$2048
scsicall::
	move.l	PRNINT.w,-(sp)		;�v�����^���f�B�[���荞�݃x�N�^��ۑ�
	pea.l	(@f,pc)
	move.l	vectorOldIocsScsidrv,-(sp)
	rts
@@:	move.l	(sp)+,PRNINT.w		;�v�����^���f�B�[���荞�݃x�N�^�𕜌�
	rts

;----------------------------------------------------------------
;SRAM�̃\�t�g�]���t���O���Z�b�g������ԂŌ���_SCSIDRV���Ăяo��
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂ł��̂܂܌Ăяo���B
;<d1.l:�R�}���h
	.text
	.align	4,$2048
scsicallSoft::
	cmpi.w	#$000A,scsiRevisionCode
	blo	scsicall		;SRAM�̃\�t�g�]���t���O�ɑΉ����Ă��Ȃ�
	btst.b	#4,$00ED0070
	bne	scsicall		;���Ƀ\�t�g�]���ɂȂ��Ă���
					;�ȍ~�͏I������疳������OFF����̂Ő�Ɋm�F����
	move.b	#$31,$00E8E00D
	bset.b	#4,$00ED0070		;�\�t�g�]��ON
	move.b	#$00,$00E8E00D
	bsr	scsicall		;����_SCSIDRV���Ăяo��
	move.b	#$31,$00E8E00D
	bclr.b	#4,$00ED0070		;�\�t�g�]��OFF
	move.b	#$00,$00E8E00D
	rts

;----------------------------------------------------------------
;�o�b�t�@��DMA�]���\���ǂ������ׂ�(�f�o�C�X���烁�����֓]��)
;	�ȉ��̏����̂����ꂩ1�ł����������Ƃ�DMA�]���s��
;		�����\�t�g�]�����w�肳��Ă���
;		�o�b�t�@�̕����A�h���X���_���A�h���X�ƈقȂ�
;		�o�b�t�@�̕����A�h���X�����[�J�����������w���Ă���
;<d3.l:�o�C�g��
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>n-flag:mi=DMA�]���s��,pl=DMA�]���\
	.text
	.align	4,$2048
scsiDmaCheckIn::
	tst.b	forceSoftScsi
	bmi	@f
	movem.l	d0-d2,-(sp)
	moveq.l	#0,d0			;�f�o�C�X���烁�����֓]��
	move.l	a1,d1
	move.l	a1,d2
	add.l	d3,d2
	bsr	dmaAccessCheck
	movem.l	(sp)+,d0-d2
@@:	rts

;----------------------------------------------------------------
;�o�b�t�@��DMA�]���\���ǂ������ׂ�(����������f�o�C�X�֓]��)
;	�ȉ��̏����̂����ꂩ1�ł����������Ƃ�DMA�]���s��
;		�����\�t�g�]�����w�肳��Ă���
;		�o�b�t�@�̕����A�h���X���_���A�h���X�ƈقȂ�
;		�o�b�t�@�̕����A�h���X�����[�J�����������w���Ă���
;<d3.l:�o�C�g��
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>n-flag:mi=DMA�]���s��,pl=DMA�]���\
	.text
	.align	4,$2048
scsiDmaCheckOut::
	tst.b	forceSoftScsi
	bmi	@f
	movem.l	d0-d2,-(sp)
	moveq.l	#1,d0			;����������f�o�C�X�֓]��
	move.l	a1,d1
	move.l	a1,d2
	add.l	d3,d2
	bsr	dmaAccessCheck
	movem.l	(sp)+,d0-d2
@@:	rts

;----------------------------------------------------------------
;_S_DATAIN
;	�f�[�^�C���t�F�[�Y�̎��s(DMA�]��)
;	DMA�]���s�̂Ƃ�_S_DATAIN_P�ɕύX����
;<d3.l:�o�C�g��
;<a1.l:�o�b�t�@�̐擪�A�h���X
	.text
	.align	4,$2048
scsidrvDatain::
	bsr	scsiDmaCheckIn
	bpl	scsicall		;DMA�]���\�Ȃ̂ł��̂܂܎��s����
	move.l	d1,-(sp)
	moveq.l	#_S_DATAIN_P,d1		;DMA�]���s�Ȃ̂�_S_DATAIN_P�ɕύX����
	bsr	scsicall
	move.l	(sp)+,d1
	rts

;----------------------------------------------------------------
;_S_DATAOUT
;	�f�[�^�A�E�g�t�F�[�Y�̎��s(DMA�]��)
;	DMA�]���s�̂Ƃ�_S_DATAOUT_P�ɕύX����
;<d3.l:�o�C�g��
;<a1.l:�o�b�t�@�̐擪�A�h���X
	.text
	.align	4,$2048
scsidrvDataout::
	bsr	scsiDmaCheckOut
	bpl	scsicall		;DMA�]���\�Ȃ̂ł��̂܂܎��s����
	move.l	d1,-(sp)
	moveq.l	#_S_DATAOUT_P,d1	;DMA�]���s�Ȃ̂�_S_DATAOUT_P�ɕύX����
	bsr	scsicall
	move.l	(sp)+,d1
	rts

;----------------------------------------------------------------
;_S_INQUIRY
;	����SCSI-BIOS�͖��Ȃ���Mach-2��DMA�]�����g�����Ƃ���̂Ńp�b�`���K�v
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ���DMA�]�����g���Ă��Ȃ��̂ł��̂܂܂ł悢
;<d3.l:�o�C�g��
;<d4.l:�^�[�Q�b�g
;<a1.l:�o�b�t�@�̐擪�A�h���X
	.text
	.align	4,$2048
scsidrvInquiry::
	bsr	scsiDmaCheckIn
	bpl	scsicall		;DMA�]���\
	bra	scsicallSoft

;----------------------------------------------------------------
;_S_READ
;	DMA�]���s�̂Ƃ��\�t�g�]���ɕύX����
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂Ŏ��O�œW�J����
;<d2.l:�u���b�N�ԍ�($001FFFFF=2097151�ȉ�)
;<d3.l:�u���b�N��($0001=1�`$0100=256)
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:
;	-1		�G���[
;	-2		�G���[(�f�[�^�C���t�F�[�Y�ɂ�����DMA�]��������)
;	���ʃ��[�h	�X�e�[�^�X�C���t�F�[�Y�̌���
;	��ʃ��[�h	���b�Z�[�W�C���t�F�[�Y�̌���
	.text
	.align	4,$2048
scsidrvRead::
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;�o�C�g��
	bsr	scsiDmaCheckIn
	movem.l	(sp)+,d3		;�t���O�ۑ�
	bpl	scsicall		;�o�b�t�@��DMA�]���\
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAM�̃\�t�g�]���t���O���g����
	movem.l	d1-d4/a1,-(sp)		;�X�^�b�N����
	moveq.l	#_S_SELECT,d1		;�Z���N�V�����t�F�[�Y
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;���g���C
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;�u���b�N��<<8
	and.l	#$001FFFFF,d2		;�u���b�N�ԍ�
	and.l	#$00070000,d4		;LUN<<16
	lsl.l	#5,d4			;LUN<<21
	or.l	d4,d2			;(LUN<<21)|�u���b�N�ԍ�
	or.l	#$08000000,d2		;($08<<24)|(LUN<<21)|�u���b�N�ԍ�
	move.w	d3,-(sp)		;�u���b�N�� 0(256�̂Ƃ���0 0)
	move.l	d2,-(sp)		;$08 LUN|�u���b�N�ԍ�H M L
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;�R�}���h�A�E�g�t�F�[�Y
	bsr	scsicall
	addq.l	#6,sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;�o�C�g��
	movea.l	(4*4,sp),a1		;�o�b�t�@�̐擪�A�h���X(�X�^�b�N����)
	moveq.l	#_S_DATAIN_P,d1		;�f�[�^�C���t�F�[�Y
	bsr	scsicall
	cmp.l	#-1,d0			;�f�[�^�C���t�F�[�Y��-1��Ԃ����Ƃ��͑��s�s��
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;�X�e�[�^�X�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;���b�Z�[�W�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;�f�[�^�C���t�F�[�Y���]���������̂Ƃ���-2��Ԃ�
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_WRITE
;	DMA�]���s�̂Ƃ��\�t�g�]���ɕύX����
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂Ŏ��O�œW�J����
;<d2.l:�u���b�N�ԍ�($001FFFFF=2097151�ȉ�)
;<d3.l:�u���b�N��($0001=1�`$0100=256)
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:
;	-1		�G���[
;	-2		�G���[(�f�[�^�A�E�g�t�F�[�Y�ɂ�����DMA�]��������)
;	���ʃ��[�h	�X�e�[�^�X�C���t�F�[�Y�̌���
;	��ʃ��[�h	���b�Z�[�W�C���t�F�[�Y�̌���
	.text
	.align	4,$2048
scsidrvWrite::
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;�o�C�g��
	bsr	scsiDmaCheckOut
	movem.l	(sp)+,d3		;�t���O�ۑ�
	bpl	scsicall		;�o�b�t�@��DMA�]���\
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAM�̃\�t�g�]���t���O���g����
	movem.l	d1-d4/a1,-(sp)		;�X�^�b�N����
	moveq.l	#_S_SELECT,d1		;�Z���N�V�����t�F�[�Y
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;���g���C
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;�u���b�N��<<8
	and.l	#$001FFFFF,d2		;�u���b�N�ԍ�
	and.l	#$00070000,d4		;LUN<<16
	lsl.l	#5,d4			;LUN<<21
	or.l	d4,d2			;(LUN<<21)|�u���b�N�ԍ�
	or.l	#$0A000000,d2		;($0A<<24)|(LUN<<21)|�u���b�N�ԍ�
	move.w	d3,-(sp)		;�u���b�N�� 0(256�̂Ƃ���0 0)
	move.l	d2,-(sp)		;$0A LUN|�u���b�N�ԍ�H M L
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;�R�}���h�A�E�g�t�F�[�Y
	bsr	scsicall
	addq.l	#6,sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;�o�C�g��
	movea.l	(4*4,sp),a1		;�o�b�t�@�̐擪�A�h���X(�X�^�b�N����)
	moveq.l	#_S_DATAOUT_P,d1	;�f�[�^�A�E�g�t�F�[�Y
	bsr	scsicall
	cmp.l	#-1,d0			;�f�[�^�A�E�g�t�F�[�Y��-1��Ԃ����Ƃ��͑��s�s��
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;�X�e�[�^�X�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;���b�Z�[�W�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;�f�[�^�A�E�g�t�F�[�Y���]���������̂Ƃ���-2��Ԃ�
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_READCAP
;	����SCSI-BIOS�͖��Ȃ���Mach-2��DMA�]�����g�����Ƃ���̂Ńp�b�`���K�v
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ���DMA�]�����g���Ă��Ȃ��̂ł��̂܂܂ł悢
;<d4.l:�^�[�Q�b�g
;<a1.l:�o�b�t�@�̐擪�A�h���X
	.text
	.align	4,$2048
scsidrvReadcap::
	move.l	d3,-(sp)
	moveq.l	#8,d3			;8�o�C�g�Œ�
	bsr	scsiDmaCheckIn
	movem.l	(sp)+,d3		;ccr�ۑ�
	bpl	scsicall		;DMA�]���\
	bra	scsicallSoft

;----------------------------------------------------------------
;_S_READEXT,_S_WRITEEXT,_S_VERIFYEXT�̕����������[�`��
;	16MB�ȏ�̃f�[�^�𕪊�����B
;	_S_READEXT,_S_WRITEEXT,_S_VERIFYEXT�̓u���b�N����65535�܂Ŏw��ł��邪
;	���ۂɂ�16MB�ȏ����x�ɓ]�����邱�Ƃ��ł��Ȃ��B���Ȃ킿�u���b�N�̃T�C�Y��
;	512�o�C�g�Ȃ��32767�u���b�N������ƂȂ��Ă���B
;	����̓\�t�g�E�F�A�̓s���ł͂Ȃ���SPC�̓]���o�C�g���J�E���^��24�r�b�g����
;	�Ȃ����߁B
;<d2.l:�u���b�N�ԍ�
;<d3.l:�u���b�N��
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;<(4,sp).l:�]���������[�`���̃A�h���X
;<(8,sp).l:���A�A�h���X
	.text
	.align	4,$2048
scsiCommandSplitter::
	movem.l	d1-d5/a1,-(sp)
	lsl.l	d5,d3			;�o�C�g��>>8
	cmp.l	#$00FFFFFF>>8,d3	;�T�C�Y����������΂��̂܂ܓ]���������s��
	bls	9f
	lsr.l	d5,d3			;�u���b�N��
	movem.l	d2-d3/a1,-(sp)
;<(sp):����̃u���b�N�ԍ�
;<(4,sp):����̎c��u���b�N��
;<(8,sp):����̃o�b�t�@�̐擪�A�h���X
1:	movem.l	(12+12,sp),d4-d5	;�X�^�b�N����
	move.l	#$00FFFFFF>>8,d3
	lsr.l	d5,d3			;����̃u���b�N��
	sub.l	d3,(4,sp)		;����̎c��u���b�N��
	bpl	2f
	add.l	(4,sp),d3		;�Ō�̃u���b�N��
	clr.l	(4,sp)			;�c��Ȃ�
2:	move.l	(sp),d2			;����̃u���b�N�ԍ�
	add.l	d3,(sp)			;����̃u���b�N�ԍ�
	movea.l	(8,sp),a1		;����̃o�b�t�@�̐擪�A�h���X
	lsl.l	#8,d3
	lsl.l	d5,d3
	add.l	d3,(8,sp)		;����̃o�b�t�@�̐擪�A�h���X
	lsr.l	#8,d3
	lsr.l	d5,d3
;<d2.l:����̃u���b�N�ԍ�
;<d3.l:����̃u���b�N��
;<a1.l:����̃o�b�t�@�̐擪�A�h���X
;<(sp).l:����̃u���b�N�ԍ�
;<(4,sp).l:����̎c��u���b�N��
;<(8,sp).l:����̃o�b�t�@�̐擪�A�h���X
  debug 'splitted(d2,d3,d4,d5,a1)=',5,d2,d3,d4,d5,a1
	jsr	([12+24,sp])		;�]�����s,�X�^�b�N����
	tst.l	d0
	bne	3f			;�G���[�I��
	tst.l	(4,sp)			;�c��]���u���b�N��
	bne	1b			;�c�肠��
3:	lea.l	(12,sp),sp
	movem.l	(sp)+,d1-d5/a1
	addq.l	#4,sp			;�]�����[�`�����X�L�b�v����
					;���W�X�^�𕜌����邽�ߍŌ�܂Ń��[�v�̒��ōs��
	rts

9:	movem.l	(sp)+,d1-d5/a1
	rts

;----------------------------------------------------------------
;_S_READEXT
;	DMA�]���s�̂Ƃ��\�t�g�]���ɕύX����
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂Ŏ��O�œW�J����
;<d2.l:�u���b�N�ԍ�
;<d3.l:�u���b�N��($0000=0�`$FFFF=65535)
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:
;	-1		�G���[
;	-2		�G���[(�f�[�^�C���t�F�[�Y�ɂ�����DMA�]��������)
;	���ʃ��[�h	�X�e�[�^�X�C���t�F�[�Y�̌���
;	��ʃ��[�h	���b�Z�[�W�C���t�F�[�Y�̌���
	.text
	.align	4,$2048
scsidrvReadext::
	bsr	scsiCommandSplitter	;��������
;�����������[�`���ɂ���Ĉȍ~�̏����͕�����ɕ����čs���邱�Ƃ�����
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;�o�C�g��
	bsr	scsiDmaCheckIn
	movem.l	(sp)+,d3		;ccr�ۑ�
	bpl	scsicall		;�o�b�t�@��DMA�]���\
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAM�̃\�t�g�]���t���O���g����
	movem.l	d1-d4/a1,-(sp)		;�X�^�b�N����
	and.l	#$0000FFFF,d3
	beq	8f
	moveq.l	#_S_SELECT,d1		;�Z���N�V�����t�F�[�Y
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;���g���C
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;�u���b�N��<<8
	swap.w	d4
	and.w	#$0007,d4		;LUN
	lsl.w	#5,d4			;LUN<<5
	or.w	#$2800,d4		;($28<<8)|(LUN<<5)
	move.l	d3,-(sp)		;0 �u���b�N��H L 0
	move.l	d2,-(sp)		;�u���b�N�ԍ�HH HL LH LL
	move.w	d4,-(sp)		;($28<<8)|(LUN<<5)
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;�R�}���h�A�E�g�t�F�[�Y
	bsr	scsicall
	lea.l	(10,sp),sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;�o�C�g��
	movea.l	(4*4,sp),a1		;�o�b�t�@�̐擪�A�h���X(�X�^�b�N����)
	moveq.l	#_S_DATAIN_P,d1		;�f�[�^�C���t�F�[�Y
	bsr	scsicall
	cmp.l	#-1,d0			;�f�[�^�C���t�F�[�Y��-1��Ԃ����Ƃ��͑��s�s��
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;�X�e�[�^�X�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;���b�Z�[�W�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;�f�[�^�C���t�F�[�Y���]���������̂Ƃ���-2��Ԃ�
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_WRITEEXT
;	DMA�]���s�̂Ƃ��\�t�g�]���ɕύX����
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂Ŏ��O�œW�J����
;<d2.l:�u���b�N�ԍ�
;<d3.l:�u���b�N��($0000=0�`$FFFF=65535)
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:
;	-1		�G���[
;	-2		�G���[(�f�[�^�A�E�g�t�F�[�Y�ɂ�����DMA�]��������)
;	���ʃ��[�h	�X�e�[�^�X�C���t�F�[�Y�̌���
;	��ʃ��[�h	���b�Z�[�W�C���t�F�[�Y�̌���
	.text
	.align	4,$2048
scsidrvWriteext::
	bsr	scsiCommandSplitter	;��������
;�����������[�`���ɂ���Ĉȍ~�̏����͕�����ɕ����čs���邱�Ƃ�����
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;�o�C�g��
	bsr	scsiDmaCheckOut
	movem.l	(sp)+,d3		;ccr�ۑ�
	bpl	scsicall		;�o�b�t�@��DMA�]���\
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAM�̃\�t�g�]���t���O���g����
	movem.l	d1-d4/a1,-(sp)		;�X�^�b�N����
	and.l	#$0000FFFF,d3
	beq	8f
	moveq.l	#_S_SELECT,d1		;�Z���N�V�����t�F�[�Y
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;���g���C
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;�u���b�N��<<8
	swap.w	d4
	and.w	#$0007,d4		;LUN
	lsl.w	#5,d4			;LUN<<5
	or.w	#$2A00,d4		;($2A<<8)|(LUN<<5)
	move.l	d3,-(sp)		;0 �u���b�N��H L 0
	move.l	d2,-(sp)		;�u���b�N�ԍ�HH HL LH LL
	move.w	d4,-(sp)		;($2A<<8)|(LUN<<5)
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;�R�}���h�A�E�g�t�F�[�Y
	bsr	scsicall
	lea.l	(10,sp),sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;�o�C�g��
	movea.l	(4*4,sp),a1		;�o�b�t�@�̐擪�A�h���X(�X�^�b�N����)
	moveq.l	#_S_DATAOUT_P,d1	;�f�[�^�A�E�g�t�F�[�Y
	bsr	scsicall
	cmp.l	#-1,d0			;�f�[�^�A�E�g�t�F�[�Y��-1��Ԃ����Ƃ��͑��s�s��
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;�X�e�[�^�X�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;���b�Z�[�W�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;�f�[�^�A�E�g�t�F�[�Y���]���������̂Ƃ���-2��Ԃ�
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_VERIFYEXT
;	DMA�]���s�̂Ƃ��\�t�g�]���ɕύX����
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂Ŏ��O�œW�J����
;<d2.l:�u���b�N�ԍ�
;<d3.l:�u���b�N��($0000=0�`$FFFF=65535)
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:
;	-1		�G���[
;	-2		�G���[(�f�[�^�A�E�g�t�F�[�Y�ɂ�����DMA�]��������)
;	���ʃ��[�h	�X�e�[�^�X�C���t�F�[�Y�̌���
;	��ʃ��[�h	���b�Z�[�W�C���t�F�[�Y�̌���
	.text
	.align	4,$2048
scsidrvVerifyext::
	bsr	scsiCommandSplitter	;��������
;�����������[�`���ɂ���Ĉȍ~�̏����͕�����ɕ����čs���邱�Ƃ�����
	move.l	d3,-(sp)
	lsl.l	#8,d3
	lsl.l	d5,d3			;�o�C�g��
	bsr	scsiDmaCheckOut
	movem.l	(sp)+,d3		;ccr�ۑ�
	bpl	scsicall		;�o�b�t�@��DMA�]���\
	cmpi.w	#$000A,scsiRevisionCode
	bhs	scsicallSoft		;SRAM�̃\�t�g�]���t���O���g����
	movem.l	d1-d4/a1,-(sp)		;�X�^�b�N����
	and.l	#$0000FFFF,d3
	beq	8f
	moveq.l	#_S_SELECT,d1		;�Z���N�V�����t�F�[�Y
	bsr	scsicall
	tst.l	d0
	beq	1f
	moveq.l	#_S_SELECT,d1		;���g���C
	bsr	scsicall
	tst.l	d0
	bne	8f
1:	lsl.l	#8,d3			;�u���b�N��<<8
	swap.w	d4
	and.w	#$0007,d4		;LUN
	lsl.w	#5,d4			;LUN<<5
	or.w	#$2F00,d4		;($2F<<8)|(LUN<<5)
	move.l	d3,-(sp)		;0 �u���b�N��H L 0
	move.l	d2,-(sp)		;�u���b�N�ԍ�HH HL LH LL
	move.w	d4,-(sp)		;($2F<<8)|(LUN<<5)
	movea.l	sp,a1
	moveq.l	#_S_CMDOUT,d1		;�R�}���h�A�E�g�t�F�[�Y
	bsr	scsicall
	lea.l	(10,sp),sp
	tst.l	d0
	bne	8f
	lsl.l	d5,d3			;�o�C�g��
	movea.l	(4*4,sp),a1		;�o�b�t�@�̐擪�A�h���X(�X�^�b�N����)
	moveq.l	#_S_DATAOUT_P,d1	;�f�[�^�A�E�g�t�F�[�Y
	bsr	scsicall
	cmp.l	#-1,d0			;�f�[�^�A�E�g�t�F�[�Y��-1��Ԃ����Ƃ��͑��s�s��
	beq	9f
	move.l	d0,d2
	clr.l	-(sp)
	moveq.l	#_S_STSIN,d1		;�X�e�[�^�X�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	moveq.l	#_S_MSGIN,d1		;���b�Z�[�W�C���t�F�[�Y
	lea.l	(1,sp),a1
	bsr	scsicall
	tst.l	d0
	bne	7f
	move.l	(sp)+,d0
	bne	9f
	cmp.l	#-2,d2			;�f�[�^�A�E�g�t�F�[�Y���]���������̂Ƃ���-2��Ԃ�
	bne	9f
	moveq.l	#-2,d0
9:	movem.l	(sp)+,d1-d4/a1
	rts

7:	addq.l	#4,sp
8:	moveq.l	#-1,d0
	bra	9b

;----------------------------------------------------------------
;_S_MODESENSE
;	����SCSI-BIOS�͖��Ȃ���Mach-2��DMA�]�����g�����Ƃ���̂Ńp�b�`���K�v
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ���DMA�]�����g���Ă��Ȃ��̂ł��̂܂܂ł悢
;<d2.l:bit0-5=�y�[�W�R�[�h
;	bit6-7=�y�[�W�R���g���[��(0=�J�����g,1=�ύX�\,2=�f�t�H���g,3=�Z�[�u)
;<d3.l:�o�C�g��($00=0�`$FF=255)
;<d4.l:�^�[�Q�b�g
;<a1.l:�o�b�t�@�̐擪�A�h���X
scsidrvModesense	equ	scsidrvInquiry

;----------------------------------------------------------------
;_S_MODESELECT
;	����SCSI-BIOS�͖��Ȃ���Mach-2��DMA�]�����g�����Ƃ���̂Ńp�b�`���K�v
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ���DMA�]�����g���Ă��Ȃ��̂ł��̂܂܂ł悢
;<d2.l:bit0=SP(0=�ۑ����Ȃ�,1=�ۑ�����),bit4=PF(0=SCSI-1,1=SCSI-2)
;<d3.l:�o�C�g��($00=0�`$FF=255)
;<d4.l:�^�[�Q�b�g
;<a1.l:�o�b�t�@�̐擪�A�h���X
	.text
	.align	4,$2048
scsidrvModeselect::
	bsr	scsiDmaCheckOut
	bpl	scsicall		;DMA�]���\
	bra	scsicallSoft

;----------------------------------------------------------------
;_S_REQUEST
;	����SCSI-BIOS�͖��Ȃ���Mach-2��DMA�]�����g�����Ƃ���̂Ńp�b�`���K�v
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ���DMA�]�����g���Ă��Ȃ��̂ł��̂܂܂ł悢
;<d3.l:�o�C�g��($00=0�`$FF=255,0�̂Ƃ��̋�����SCSI-1��SCSI-2�ňقȂ�)
;<d4.l:�^�[�Q�b�g
;<a1.l:�o�b�t�@�̐擪�A�h���X
scsidrvRequest	equ	scsidrvInquiry

;----------------------------------------------------------------
;_S_REASSIGN
;	����SCSI-BIOS�͖��Ȃ���Mach-2��DMA�]�����g�����Ƃ���̂Ńp�b�`���K�v
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ���DMA�]�����g���Ă��Ȃ��̂ł��̂܂܂ł悢
;<d3.l:�o�C�g��($00=0�`$FF=255)
;<d4.l:�^�[�Q�b�g
;<a1.l:�o�b�t�@�̐擪�A�h���X
scsidrvReassign	equ	scsidrvModeselect

;----------------------------------------------------------------
;_S_READDMA
;	DMA�]���s�̂Ƃ��\�t�g�]���ɕύX����
;	SUPER����XVICompact�܂ł�X68000�̓���SCSI-BIOS��SRAM�̃\�t�g�]���t���O��
;	�Ή����Ă��Ȃ��̂Ŏ��O�œW�J����
;<d2.l:�u���b�N�ԍ�($001FFFFF=2097151�ȉ�)
;<d3.l:�u���b�N��($0001=1�`$0100=256)
;<d4.l:�^�[�Q�b�g
;<d5.l:�u���b�N�̃T�C�Y(0=256,1=512,2=1024)
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:
;	-1		�G���[
;	-2		�G���[(�f�[�^�C���t�F�[�Y�ɂ�����DMA�]��������)
;	���ʃ��[�h	�X�e�[�^�X�C���t�F�[�Y�̌���
;	��ʃ��[�h	���b�Z�[�W�C���t�F�[�Y�̌���
scsidrvReaddma	equ	scsidrvRead



;----------------------------------------------------------------
;
;	IOCS _PRNINTST(Mach-2�΍�)
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _PRNINTST
;	����SCSI�C���^�t�F�C�X��MB89352�̃��Z�b�g�R���f�B�V�������荞�݂��Ȃ���
;	$6C�ł͂Ȃ�$63�œ����Ă��邱�Ƃ�����AMach-2�Ɠ���SCSI�|�[�g���q������Ԃ�
;	SCSI�o�X���Z�b�g��������Ɣ��т��o�Ă��܂��B�����ŁAMach-2��SCSI-BIOS��
;	SCSI�o�X���Z�b�g�̍ۂɃv�����^���f�B�[���荞�݃x�N�^��ύX���Ĕ��т��o�Ȃ�
;	�悤�ɍ׍H����Ă���B�ύX���ꂽ�x�N�^��$63EAxxxx�ƂȂ��āA���̂悤�ȃR�[�h
;	���w���B
;		move.b	$00E96029,$00E96029	;13F9 00E9 6029 00E9 6029
;		rte				;4E73
;	���̃R�[�h�͓���SCSI�C���^�t�F�C�X��MB89352��INTS(Interrupt Sense)���W�X�^��
;	�N���A���Ă��邾���ŁA����SCSI-BIOS��SCSI���荞�݃��[�`���Ɠ��������ł���B
;
;	X68030��ROM�̓v�����^���f�B�[���荞�݃x�N�^�̎g�p��Ԃ��ŏ�ʃo�C�g��0��
;	�ǂ����Ŕ��ʂ���̂ŁA����������ꂽ�x�N�^�𖢎g�p�ƔF������B�������A
;	060turbo��ROM�ł͊��荞�݃��[�`�����n�C�������̈�ɔz�u�ł���悤�ɂ��邽�߂�
;	�x�N�^�̎g�p��Ԃ�32�r�b�g�S�̂Ń`�F�b�N����悤�ɕύX����Ă��邽�߁A
;	����������ꂽ�x�N�^���g�p���ƔF�����Ă��܂��B���̌��ʁA060turbo��Mach-2��
;	���p����ƃv�����^���f�B�[���荞�݃x�N�^��ύX�ł��Ȃ��Ȃ�ATeX�V�X�e����
;	print.x�Ȃǂ����삵�Ȃ��Ȃ�B
;
;	$63�̓n�C�������̃A�h���X�̍ŏ�ʃo�C�g�ƈ�v���Ȃ��̂ŁA�x�N�^�̍ŏ�ʃo�C�g
;	��$63���ǂ����Ŏg�p��Ԃ𔻕ʂ���悤�ɕύX���邱�Ƃ�Math-2�𕹗p�����ꍇ��
;	_PRNINTST���@�\���Ȃ��Ȃ�����������B
;	���ꂾ���ł͊��Ƀv�����^���f�B�[���荞�݂��g�p���Ă����Ԃ�SCSI�o�X���Z�b�g
;	���s���ƃv�����^���f�B�[���荞�݃x�N�^���j�󂳂�Ă��܂����A�����_SCSIDRV��
;	�őΏ�����B
;
;<a1.l:�v�����^�̃��f�B�[���荞�ݏ������[�`���̃A�h���X(0=����)
;>d0.l:����
;	0	����I��
;	���̑�	�g�p���Ȃ̂Őݒ�ł��Ȃ�(���݂̏������[�`���̃A�h���X)
	.text
	.align	4,$2048
iocsPrnintst::
	move.l	a0,-(sp)
	move.w	sr,-(sp)
	ori.w	#$0700,sr		;���荞�݋֎~
	moveq.l	#PRNINT>>2,d0
	lea.l	PRNINT.w,a0
	cmpa.w	#0,a1			;tst.l a1
	beq	1f			;��������
	cmp.b	(a0),d0			;�ŏ�ʃo�C�g������r����
	bne	2f			;�g�p���Ȃ̂Őݒ�ł��Ȃ�
;���g�p�Ȃ̂Őݒ肷��
	move.l	a1,(a0)			;�ݒ肷��
	bset.b	#0,$00E9C001		;�v�����^���荞�݋���
8:	moveq.l	#0,d0
9:	move.w	(sp)+,sr
	movea.l	(sp)+,a0
	rts

;��������
1:	bclr.b	#0,$00E9C001		;�v�����^���荞�݋֎~
	move.l	#((PRNINT>>2)<<24)+defaultPrnint,(a0)	;��������
	bra	8b

;�g�p���Ȃ̂Őݒ�ł��Ȃ�
2:	move.l	(a0),d0			;�擾����
	bra	9b

;----------------------------------------------------------------
;�f�t�H���g�̃v�����^���f�B�[���荞�ݏ������[�`��
;	$00xxxxxx�̃A�h���X�ɔz�u����$63000000���������x�N�^��ݒ肷��
	.text
	.align	4,$2048
defaultPrnint::
	rte				;�������Ȃ�

;���т��o���Ƃ�
;	moveq.l	#$63,d7			;�x�N�^�ԍ�
;	movea.l	sp,a6
;	trap	#14
;@@:	IOCS	_ABORTJOB
;	bra	@b

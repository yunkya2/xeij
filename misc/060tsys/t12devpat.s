;----------------------------------------------------------------
;
;	�f�o�C�X�h���C�o�̃n�C�������΍�
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;�f�o�C�X�h���C�o���Ăяo��(�L���b�V������у��[�J���������΍�)
;	Human302�ł̎菇(68000,68030)
;		$0000DEFA
;			�f�[�^�L���b�V����OFF�ɂ���
;			([6,a1])���Ăяo��
;			([10,a1])���Ăяo��
;			�f�[�^�L���b�V���Ɩ��߃L���b�V�����t���b�V������
;			�L���b�V�����[�h�𕜌�����
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;?d0
callDevice::
;�h���C�o���g��RAMDISK�h���C�o�̌Ăяo���͓��ʈ����ō�����
	cmpa.l	#deviceHeader,a1
	beq	ramdiskGo
;RAMDISK���Ȃ��Ƃ��͂�������X�^�[�g
callDeviceNoRamdisk::
;�L�����N�^�f�o�C�X�̂Ƃ��̓L���b�V���̂ݏ��u
	tst.w	(4,a1)			;�f�o�C�X�^�C�v
	bmi	characterDevice		;�L�����N�^�f�o�C�X
;�u���b�N�f�o�C�X,����f�o�C�X
	movem.l	d1-d7/a0-a3/a5-a6,-(sp)
;����f�o�C�X����ʂ���
	btst.b	#13-8,(4,a1)
	bne	specialDevice		;����f�o�C�X
;----------------------------------------------------------------
;�u���b�N�f�o�C�X�̌Ăяo��
;	�]���ƃf�B�X�N�����`�F�b�N��-np���w�肳��Ă��Ȃ���΃L���b�V������𔺂�
;	���̑��̃R�}���h�͖������ɃL���b�V������𔺂�
blockDevice:
	moveq.l	#0,d0
	move.b	(2,a5),d0		;�R�}���h
	cmp.b	#$0D,d0
	bcc	unknownCommand
	jsr	([@f,pc,d0.l*4])
	movem.l	(sp)+,d1-d7/a0-a3/a5-a6
	rts

@@:	.dc.l	deviceGoPush		;00	������
	.dc.l	deviceGoPush		;01	�f�B�X�N�����`�F�b�N
	.dc.l	deviceGoPush		;02	�f�B�X�N��������
	.dc.l	ioctrlRead		;03	IOCTRL�ɂ�����
	.dc.l	blockRead		;04	����
	.dc.l	deviceGoPush		;05	�h���C�u�R���g���[��&�Z���X
					;	(�L���b�V�����䂵�Ȃ���FORMAT.X�������Ȃ�)
	.dc.l	deviceGoPush		;06	�G���[
	.dc.l	deviceGoPush		;07	�G���[
	.dc.l	blockWrite		;08	�o��(VERIFY OFF��)
	.dc.l	blockWrite		;09	�o��(VERIFY ON��)
	.dc.l	deviceGoPush		;0A	�G���[
	.dc.l	deviceGoPush		;0B	���g�p
	.dc.l	ioctrlWrite		;0C	IOCTRL�ɂ��o��

;----------------------------------------------------------------
;����f�o�C�X�̌Ăяo��
;	�������Ɩ���`�̃R�}���h�͖������ɃL���b�V������𔺂�
;	���̑��̃R�}���h��-np���w�肳��Ă��Ȃ���΃L���b�V������𔺂�
specialDevice:
	moveq.l	#$7F,d0
	and.b	(2,a5),d0		;�R�}���h(verify�t���O������)
	sub.b	#$40,d0
	bcs	unknownCommand
	cmp.b	#$59-$40,d0
	bcc	unknownCommand
	jsr	([@f,pc,d0.l*4])
	movem.l	(sp)+,d1-d7/a0-a3/a5-a6
	rts

@@:	.dc.l	deviceGoPush		;40	initialize
	.dc.l	deviceGoPush		;41	chdir
	.dc.l	deviceGoPush		;42	mkdir
	.dc.l	deviceGoPush		;43	rmdir
	.dc.l	deviceGoPush		;44	rename
	.dc.l	deviceGoPush		;45	delete
	.dc.l	deviceGoPush		;46	chmod
	.dc.l	deviceGoPush		;47	files
	.dc.l	deviceGoPush		;48	nfiles
	.dc.l	deviceGoPush		;49	create/newfile
	.dc.l	deviceGoPush		;4A	open
	.dc.l	deviceGoPush		;4B	close
	.dc.l	specialRead		;4C	read
	.dc.l	specialWrite		;4D	write
	.dc.l	deviceGoPush		;4E	seek
	.dc.l	deviceGoPush		;4F	filedate
	.dc.l	deviceGoPush		;50	dskfre
	.dc.l	deviceGoPush		;51	drvctrl
	.dc.l	deviceGoPush		;52	getdpb
	.dc.l	deviceGoPush		;53	diskred
	.dc.l	deviceGoPush		;54	diskwrt
	.dc.l	deviceGoPush		;55	special_ctrl
	.dc.l	deviceGoPush		;56	fflush
	.dc.l	deviceGoPush		;57	mediacheck
	.dc.l	deviceGoPush		;58	lock

;----------------------------------------------------------------
;���Ή��̃R�}���h
;	�������ɃL���b�V������𔺂�
unknownCommand:
	movem.l	(sp)+,d1-d7/a0-a3/a5-a6
	bra	deviceGoPush

;----------------------------------------------------------------
;�L�����N�^�f�o�C�X�̌Ăяo��
;	�������͖������ɃL���b�V������𔺂�
;	���̑��̃R�}���h��-np���w�肳��Ă��Ȃ���΃L���b�V������𔺂�
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;?d0
characterDevice:
	tst.b	(2,a5)			;�R�}���h
	beq	deviceGoPush		;������
;----------------------------------------------------------------
;�f�o�C�X�̏��������s����(-np���w�肳��Ă��Ȃ���΃L���b�V������𔺂�)
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;?d0
deviceGo:
	tst.b	deviceCacheNoPush
	beq	deviceGoPush		;-np���w�肳��Ă��Ȃ�
	move.l	a0,-(sp)
	movea.l	([$1C28.w]),a0
	tst.b	(pDeviceNoPush,a0)
	movea.l	(sp)+,a0
	beq	deviceGoPush		;-np��K�p�ł��Ȃ��v���Z�X
;----------------------------------------------------------------
;�f�o�C�X�̏��������s����(�L���b�V������𔺂�Ȃ�)
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;?d0
	jsr	([6,a1])		;�X�g���e�W���[�`�����Ă�
	jmp	([10,a1])		;�C���^���v�g���[�`�����Ă�

;----------------------------------------------------------------
specialRead:				;���ݖ��Ή�
specialWrite:				;���ݖ��Ή�
;----------------------------------------------------------------
;�f�o�C�X�̏��������s����(�L���b�V������𔺂�)
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;?d0
deviceGoPush:
	PUSH_CACR_DISABLE_DC	d0
	jsr	([6,a1])		;�X�g���e�W���[�`�����Ă�
	jsr	([10,a1])		;�C���^���v�g���[�`�����Ă�
	cmpi.b	#4,$0CBC.w
	blo	@f
	cinva	ic
@@:
	POP_CACR	d0
	rts

;----------------------------------------------------------------
;RAMDISK�̏��������s����
;	�f�[�^�L���b�V�����v�b�V�����Ȃ�
;	�R�}���h�R�[�h���̏����𒼐ڌĂяo��
;	requestHeader��ݒ肵�Ȃ��̂ŃR�}���h����requestHeader���g��Ȃ�����
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;?d0
ramdiskGo:
	moveq.l	#0,d0
	move.b	(2,a5),d0		;�R�}���h�R�[�h
	jsr	([deviceJumpTable,pc,d0.l*4])	;�R�}���h�̏������Ă�
	move.b	d0,(3,a5)		;�G���[�R�[�h(����)
	lsr.w	#8,d0
	move.b	d0,(4,a5)		;�G���[�R�[�h(���)
	rts

;----------------------------------------------------------------
;�u���b�N�f�o�C�X�ւ̏�������
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
blockWrite:
	tst.b	patchDevice
	beq	deviceGo		;���[�J���������΍�����Ȃ��Ƃ��̓L���b�V���̂ݏ��u

  debug '|blockWrite(top,siz,ptr,head) ',4,(22,a5),(18,a5),(14,a5),([14,a5])
	lea.l	(blockWriteTransfer,pc),a2	;�u���b�N�f�o�C�X�ւ̏o��
	moveq.l	#1,d0
	bra	blockTransfer

;----------------------------------------------------------------
;�u���b�N�f�o�C�X����̓ǂݏo��
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
blockRead:
	tst.b	patchDevice
	beq	deviceGo		;���[�J���������΍�����Ȃ��Ƃ��̓L���b�V���̂ݏ��u

  debug '|blockRead(top,siz,ptr) ',3,(22,a5),(18,a5),(14,a5)
	lea.l	(blockReadTransfer,pc),a2	;�u���b�N�f�o�C�X����̓���
	moveq.l	#0,d0
;�u���b�N�f�o�C�X�̓��o��
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<a1.l:�f�o�C�X�w�b�_
;<a2.l:�]�����[�`��
;<a5.l:���N�G�X�g�w�b�_
blockTransfer:
	move.l	(18,a5),d6		;�]���Z�N�^��
	beq	deviceGo		;�]���Z�N�^����0�̂Ƃ��͉������Ȃ�
;����DPB�e�[�u�������߂�
	bsr	searchInnerDpb		;�f�o�C�X�w�b�_�ƃ��j�b�g�ԍ��������DPB�e�[�u����T��
	bmi	deviceGo		;����DPB�e�[�u����������Ȃ�(�O�̂���)
;<a0.l:����DPB�e�[�u��
  debug 'inner dpb=',1,a0
  debugByte 'drive,unit=',2,(iDrive,a0),(iUnit,a0)
  debug 'device header=',1,(iDeviceHeader,a0)
  debugByte 'media byte=',1,(iMediaByte,a0)
  debugByte 'byte per sect2=',1,(iBytePerSect2,a0)
;���f�B�A�o�C�g�ꗗ
;	$F0	SCSI MO (IBM format)
;	$F4	SCSI DAT
;	$F5	SCSI CD-ROM
;	$F6	SCSI MO
;	$F7	SCSI HD
;	$F8	SASI HD
;	$F9	RAM / SRAM / ROM
;	$FA	2HD 1.44MB
;	$FB	2DD 640KB
;	$FC	2DD 720KB
;	$FD	2HC 1.2MB
;	$FE	2HD 1.2MB
;���f�B�A�o�C�g��$F0�`$F7�̂Ƃ�,SCSI IOCS�Ƀp�b�`���������Ă����
;SCSI IOCS���Ń\�t�g�]���ɂȂ�̂ňꎞ�o�b�t�@��}��Ȃ��Ă悢
	moveq.l	#$10,d3
	add.b	(iMediaByte,a0),d3	;���f�B�A�o�C�g
;	bcc	@f
	subq.b	#8,d3
	bcc	@f
	tst.b	patchIocsScsi
	bne	deviceGo
@@:
	move.b	(iBytePerSect2,a0),d3	;�Z�N�^�����o�C�g���ɕϊ�����Ƃ��̃V�t�g�J�E���g
	cmp.b	#8,d3
	blo	deviceGo		;1�Z�N�^��256�o�C�g����(�O�̂���)
	move.l	tempBufferSize,d4	;�ꎞ�o�b�t�@�̃o�C�g��
	lsr.l	d3,d4			;�ꎞ�o�b�t�@�̃Z�N�^��
	move.l	(14,a5),d5		;�ړI�̃o�b�t�@�̐擪�A�h���X
	and.l	#LOGICAL_MASK,d5	;_DISKRED/_DISKWRT�̊g�����[�h�ł�bit31��
					;�Z�b�g���ꂽ�܂ܓ����Ă���
	move.l	(22,a5),d7		;�擪�̃Z�N�^�ԍ�
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<d3.b:�Z�N�^�����o�C�g���ɕϊ�����Ƃ��̃V�t�g�J�E���g
;<d4.l:�ꎞ�o�b�t�@�̃Z�N�^��
;<d5.l:�ړI�̃o�b�t�@�̐擪�A�h���X
;<d6.l:�]���Z�N�^��
;<d7.l:�擪�̃Z�N�^�ԍ�
;<a0.l:����DPB�e�[�u��
;<a1.l:�f�o�C�X�w�b�_
;<a2.l:�]�����[�`��
;<a5.l:���N�G�X�g�w�b�_
;�ړI�̃o�b�t�@��DMA�]���\���ǂ������ׂ�
;	�����A�h���X���_���A�h���X�ƈقȂ�ꍇ��DMA�]���s��
;	�����A�h���X�����[�J�����������w���Ă���ꍇ��DMA�]���s��
	move.l	d5,d1			;�擪
	move.l	d6,d2			;�Z�N�^��
	lsl.l	d3,d2			;�o�C�g��
	add.l	d5,d2			;����+1
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<d1.l:�o�b�t�@�̐擪
;<d2.l:�o�b�t�@�̖���+1
	bsr	dmaAccessCheck
	bpl	deviceGo		;DMA�]���\�ȗ̈�Ȃ̂ŉ������Ȃ�
;----------------------------------------------------------------
;�ꎞ�o�b�t�@���g�����]������(�u���b�N�f�o�C�X�̓��o��)
;�V�������N�G�X�g�w�b�_���m�ۂ���
	lea.l	(-26,sp),sp
	movea.l	a5,a6			;���̃��N�G�X�g�w�b�_
	movea.l	sp,a5			;�V�������N�G�X�g�w�b�_
;<a5.l:�V�������N�G�X�g�w�b�_
;<a6.l:���̃��N�G�X�g�w�b�_
;�]�����[�v
blockTransferLoop:
;�V�������N�G�X�g�w�b�_�����
	move.w	(a6),(a5)		;�萔,�R�}���h�R�[�h
	movem.l	(2,a6),d0-d2
	movem.l	d0-d2,(2,a5)
;�p�����[�^��ݒ肷��
	sub.l	d4,d6			;�c��̓]���Z�N�^��
	bcc	@f
	add.l	d6,d4			;����̓]���Z�N�^��
	moveq.l	#0,d6
@@:	movea.l	tempBufferStart,a0	;�ꎞ�o�b�t�@�̐擪�A�h���X
	move.l	a0,(14,a5)		;�]���A�h���X
	move.l	d4,(18,a5)		;�Z�N�^��
	move.l	d7,(22,a5)		;�Z�N�^�ԍ�
	add.l	d4,d7			;���̃Z�N�^�ԍ�
;���o�͂̎��s
;<d3.b:�Z�N�^�����o�C�g���ɕϊ�����Ƃ��̃V�t�g�J�E���g
;<d4.l:����̓]���Z�N�^��
;<d5.l:�ړI�̃o�b�t�@�̃A�h���X
;<d6.l:�c��̓]���Z�N�^��
;<d7.l:���̃Z�N�^�ԍ�
;<a0.l:�ꎞ�o�b�t�@�̐擪�A�h���X
;<a1.l:�f�o�C�X�w�b�_
;<a2.l:�]�����[�`��
;<a5.l:�V�������N�G�X�g�w�b�_(�\�z�ς�)
;<a6.l:���̃��N�G�X�g�w�b�_
	jsr	(a2)			;���͂܂��͏o�͂̎��s
	tst.l	d6
	bne	blockTransferLoop
;�G���[�R�[�h�����̃��N�G�X�g�w�b�_�ɃR�s�[���ďI���
blockTransferEnd:
	move.w	(3,a5),(3,a6)		;�G���[�R�[�h
	movea.l	a6,a5
	lea.l	(26,sp),sp
;�ꎞ�o�b�t�@���g�����]�������I���
	rts

;�G���[�������͑��������������ɏI��
blockTransferError:
	addq.l	#4,sp
	bra	blockTransferEnd

;----------------------------------------------------------------
;�u���b�N�f�o�C�X����̓���
;<d3.b:�Z�N�^�����o�C�g���ɕϊ�����Ƃ��̃V�t�g�J�E���g
;<d4.l:����̓]���Z�N�^��
;<d5.l:�ړI�̃o�b�t�@�̃A�h���X
;<a0.l:�ꎞ�o�b�t�@�̐擪�A�h���X
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:�V�������N�G�X�g�w�b�_(�\�z�ς�)
;>d5.l:�ړI�̃o�b�t�@�̎��̃A�h���X
;*d5,?d0/a0
blockReadTransfer:
  debug '|blockReadTransfer(ptr,tmp,(top,siz,ptr)) ',5,d5,a0,(22,a5),(18,a5),(14,a5)
;�f�o�C�X�̏��������s����
	bsr	deviceGo		;�f�o�C�X�̏��������s����(�L���b�V������𔺂�)
	tst.b	(3,a5)			;�G���[�`�F�b�N
	bne	blockTransferError	;�G���[�����������̂Œ��~����
;�ꎞ�o�b�t�@����ړI�̃o�b�t�@�ɃR�s�[����
	moveq.l	#$0F,d0
	and.l	d5,d0
					;��  ��,�f�o�C�X�w�b�_
					;d5��a0,a1
	exg.l	d5,a1			;a1��a0,d5
	bsr	blockTransferSub
	exg.l	d5,a1			;d5��a0,a1
	rts

;----------------------------------------------------------------
;�u���b�N�f�o�C�X�ւ̏o��
;<d3.b:�Z�N�^�����o�C�g���ɕϊ�����Ƃ��̃V�t�g�J�E���g
;<d4.l:����̓]���Z�N�^��
;<d5.l:�ړI�̃o�b�t�@�̃A�h���X
;<a0.l:�ꎞ�o�b�t�@�̐擪�A�h���X
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:�V�������N�G�X�g�w�b�_(�\�z�ς�)
;>d5.l:�ړI�̃o�b�t�@�̎��̃A�h���X
;*d5,?d0/a0
blockWriteTransfer:
  debug '|blockWriteTransfer(ptr,tmp,(top,siz,ptr,head)) ',6,d5,a0,(22,a5),(18,a5),(14,a5),([14,a5])
;�ړI�̃o�b�t�@����ꎞ�o�b�t�@�ɃR�s�[����
	moveq.l	#$0F,d0
	and.l	d5,d0
					;��  ��,�f�o�C�X�w�b�_
					;d5��a0,a1
	exg.l	d5,a1			;a1��a0,d5
	exg.l	a0,a1			;a0��a1,d5
	bsr	blockTransferSub
	movea.l	d5,a1			;a0��??,a1
	move.l	a0,d5			;d5��??,a1
;�f�o�C�X�̏��������s����
	bsr	deviceGo		;�f�o�C�X�̏��������s����(�L���b�V������𔺂�)
	tst.b	(3,a5)			;�G���[�`�F�b�N
	bne	blockTransferError	;�G���[�����������̂Œ��~����
	rts

;----------------------------------------------------------------
;�]���T�u���[�`��
;<d0.l:0�̂Ƃ�move16���g��
;<d3.b:�Z�N�^�����o�C�g���ɕϊ�����Ƃ��̃V�t�g�J�E���g
;<d4.l:����̓]���Z�N�^��
;<a0.l:�]�����̐擪�A�h���X
;<a1.l:�]����̐擪�A�h���X
;>a0.l:�]�����̎��̃A�h���X
;>a1.l:�]����̎��̃A�h���X
;*a0-a1,?d0
blockTransferSub:
  debug '|blockTransferSub(src,dst) ',2,a0,a1
	tst.l	d0
	bne	blockTransferSub1
	cmpi.b	#4,$0CBC.W
	blo	blockTransferSub1
;move16���g���ē]������
	move.l	d4,d0			;�Z�N�^��
	lsl.l	d3,d0			;�o�C�g��
;<d0.l:�]���o�C�g��
;<a0.l:�]�����̃A�h���X(16�̔{��)
;<a1.l:�]����̃A�h���X(16�̔{��)
	lsr.l	#8,d0			;�o�C�g��/256
@@:
  .rept 16
	move16	(a0)+,(a1)+		;256�o�C�g���R�s�[����
  .endm
	subq.l	#1,d0
	bne	@b
	rts

;move���g���ē]������
blockTransferSub1:
	move.l	d4,d0			;�Z�N�^��
	lsl.l	d3,d0			;�o�C�g��
;<d0.l:�]���o�C�g��
;<a0.l:�]�����̃A�h���X
;<a1.l:�]����̃A�h���X
	lsr.l	#8,d0			;�o�C�g��/256
@@:
  .rept 64
	move.l	(a0)+,(a1)+		;256�o�C�g���R�s�[����
  .endm
	subq.l	#1,d0
	bne	@b
	rts

;----------------------------------------------------------------
;�u���b�N�f�o�C�X�����IOCTRL�ɂ�鏑������
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
ioctrlWrite:
	tst.b	patchDevice
	beq	deviceGo		;���[�J���������΍�����Ȃ��Ƃ��̓L���b�V���̂ݏ��u

	lea.l	(ioctrlWriteTransfer,pc),a2	;�u���b�N�f�o�C�X�ւ�IOCTRL�ɂ��o��
	moveq.l	#1,d0
	bra	ioctrlTransfer

;----------------------------------------------------------------
;�u���b�N�f�o�C�X�����IOCTRL�ɂ��ǂݏo��
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
ioctrlRead:
	tst.b	patchDevice
	beq	deviceGo		;���[�J���������΍�����Ȃ��Ƃ��̓L���b�V���̂ݏ��u

	lea.l	(ioctrlReadTransfer,pc),a2	;�u���b�N�f�o�C�X�����IOCTRL�ɂ�����
	moveq.l	#0,d0
;�u���b�N�f�o�C�X��IOCTRL�ɂ����o��
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<a1.l:�f�o�C�X�w�b�_
;<a2.l:�]�����[�`��
;<a5.l:���N�G�X�g�w�b�_
ioctrlTransfer:
	move.l	(18,a5),d6		;�]���o�C�g��
	beq	deviceGo		;�]���o�C�g����0�̂Ƃ��͉������Ȃ�
	move.l	tempBufferSize,d4	;�ꎞ�o�b�t�@�̃o�C�g��
	move.l	(14,a5),d5		;�ړI�̃o�b�t�@�̐擪�A�h���X
	and.l	#LOGICAL_MASK,d5	;�O�̂���
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<d4.l:�ꎞ�o�b�t�@�̃o�C�g��
;<d5.l:�ړI�̃o�b�t�@�̐擪�A�h���X
;<d6.l:�]���o�C�g��
;<a1.l:�f�o�C�X�w�b�_
;<a2.l:�]�����[�`��
;<a5.l:���N�G�X�g�w�b�_
;�ړI�̃o�b�t�@��DMA�]���\���ǂ������ׂ�
;	�����A�h���X���_���A�h���X�ƈقȂ�ꍇ��DMA�]���s��
;	�����A�h���X�����[�J�����������w���Ă���ꍇ��DMA�]���s��
	move.l	d5,d1			;�擪
	move.l	d6,d2			;�Z�N�^��
	add.l	d5,d2			;����+1
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<d1.l:�o�b�t�@�̐擪
;<d2.l:�o�b�t�@�̖���+1
	bsr	dmaAccessCheck
	bpl	deviceGo		;DMA�]���\�ȗ̈�Ȃ̂ŉ������Ȃ�
;----------------------------------------------------------------
;�ꎞ�o�b�t�@���g�����]������(�u���b�N�f�o�C�X��IOCTRL�ɂ����o��)
;�V�������N�G�X�g�w�b�_���m�ۂ���
	lea.l	(-26,sp),sp
	movea.l	a5,a6			;���̃��N�G�X�g�w�b�_
	movea.l	sp,a5			;�V�������N�G�X�g�w�b�_
;<a5.l:�V�������N�G�X�g�w�b�_
;<a6.l:���̃��N�G�X�g�w�b�_
;�]�����[�v
ioctrlTransferLoop:
;�V�������N�G�X�g�w�b�_�����
	move.w	(a6),(a5)		;�萔,�R�}���h�R�[�h
	movem.l	(2,a6),d0-d2
	movem.l	d0-d2,(2,a5)
;�p�����[�^��ݒ肷��
	sub.l	d4,d6			;�c��̓]���o�C�g��
	bcc	@f
	add.l	d6,d4			;����̓]���o�C�g��
	moveq.l	#0,d6
@@:	movea.l	tempBufferStart,a0	;�ꎞ�o�b�t�@�̐擪�A�h���X
	move.l	a0,(14,a5)		;�]���A�h���X
	move.l	d4,(18,a5)		;�o�C�g��
					;(22,a5)�͐ݒ肵�Ȃ�
;���o�͂̎��s
;<d4.l:����̓]���o�C�g��
;<d5.l:�ړI�̃o�b�t�@�̃A�h���X
;<d6.l:�c��̓]���o�C�g��
;<a0.l:�ꎞ�o�b�t�@�̐擪�A�h���X
;<a1.l:�f�o�C�X�w�b�_
;<a2.l:�]�����[�`��
;<a5.l:�V�������N�G�X�g�w�b�_(�\�z�ς�)
;<a6.l:���̃��N�G�X�g�w�b�_
	jsr	(a2)			;���͂܂��͏o�͂̎��s
	tst.l	d6
	bne	ioctrlTransferLoop
;�G���[�R�[�h�����̃��N�G�X�g�w�b�_�ɃR�s�[���ďI���
ioctrlTransferEnd:
	move.w	(3,a5),(3,a6)		;�G���[�R�[�h
	movea.l	a6,a5
	lea.l	(26,sp),sp
;�ꎞ�o�b�t�@���g�����]�������I���
	rts

;�G���[�������͑��������������ɏI��
ioctrlTransferError:
	addq.l	#4,sp
	bra	ioctrlTransferEnd

;----------------------------------------------------------------
;�u���b�N�f�o�C�X�����IOCTRL�ɂ�����
;<d4.l:����̓]���o�C�g��
;<d5.l:�ړI�̃o�b�t�@�̃A�h���X
;<a0.l:�ꎞ�o�b�t�@�̐擪�A�h���X
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:�V�������N�G�X�g�w�b�_(�\�z�ς�)
;>d5.l:�ړI�̃o�b�t�@�̎��̃A�h���X
;*d5,?d0/a0
ioctrlReadTransfer:
;�f�o�C�X�̏��������s����
	bsr	deviceGo		;�f�o�C�X�̏��������s����(�L���b�V������𔺂�)
	tst.b	(3,a5)			;�G���[�`�F�b�N
	bne	ioctrlTransferError	;�G���[�����������̂Œ��~����
;�ꎞ�o�b�t�@����ړI�̃o�b�t�@�ɃR�s�[����
					;��  ��,�f�o�C�X�w�b�_
					;d5��a0,a1
	exg.l	d5,a1			;a1��a0,d5
	bsr	ioctrlTransferSub
	exg.l	d5,a1			;d5��a0,a1
	rts

;----------------------------------------------------------------
;�u���b�N�f�o�C�X�ւ�IOCTRL�ɂ��o��
;<d4.l:����̓]���o�C�g��
;<d5.l:�ړI�̃o�b�t�@�̃A�h���X
;<a0.l:�ꎞ�o�b�t�@�̐擪�A�h���X
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:�V�������N�G�X�g�w�b�_(�\�z�ς�)
;>d5.l:�ړI�̃o�b�t�@�̎��̃A�h���X
;*d5,?d0/a0
ioctrlWriteTransfer:
;�ړI�̃o�b�t�@����ꎞ�o�b�t�@�ɃR�s�[����
					;��  ��,�f�o�C�X�w�b�_
					;d5��a0,a1
	exg.l	d5,a1			;a1��a0,d5
	exg.l	a0,a1			;a0��a1,d5
	bsr	ioctrlTransferSub
	movea.l	d5,a1			;a0��??,a1
	move.l	a0,d5			;d5��??,a1
;�f�o�C�X�̏��������s����
	bsr	deviceGo		;�f�o�C�X�̏��������s����(�L���b�V������𔺂�)	jsr	([6,a1]			;���̃X�g���e�W���[�`�����Ă�
	tst.b	(3,a5)			;�G���[�`�F�b�N
	bne	ioctrlTransferError	;�G���[�����������̂Œ��~����
	rts

;----------------------------------------------------------------
;�]���T�u���[�`��
;<d4.l:����̓]���o�C�g��
;<a0.l:�]�����̐擪�A�h���X
;<a1.l:�]����̐擪�A�h���X
;>a0.l:�]�����̎��̃A�h���X
;>a1.l:�]����̎��̃A�h���X
;*a0-a1,?d0
ioctrlTransferSub:
	move.l	d4,d0			;�o�C�g��
;<d0.l:�]���o�C�g��
;<a0.l:�]�����̃A�h���X
;<a1.l:�]����̃A�h���X
@@:	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne	@b
	rts

;----------------------------------------------------------------
;�f�o�C�X�w�b�_�ƃ��j�b�g�ԍ��������DPB�e�[�u����T��
;<a1.l:�f�o�C�X�w�b�_
;<a5.l:���N�G�X�g�w�b�_
;>a0.l:����DPB�e�[�u��
;	-1	������Ȃ�����
;>n-flag:pl=��������,mi=������Ȃ�����
searchInnerDpb:
	move.l	d0,-(sp)
	move.b	(1,a5),d0		;���j�b�g�ԍ�
	movea.l	$1C3C.w,a0		;[$1C3C.w].l:����DPB�e�[�u���̐擪�A�h���X
	cmpa.l	(2,a0),a1		;�f�o�C�X�w�b�_
	beq	3f
1:	movea.l	(6,a0),a0		;���̓���DPB�e�[�u��
	tst.l	a0
	bmi	9f			;������Ȃ�����(������Ȃ��͂��͂Ȃ����O�̂���)
2:	cmpa.l	(2,a0),a1		;�f�o�C�X�w�b�_
	bne	1b
;�f�o�C�X�w�b�_����v����
3:	cmp.b	(1,a0),d0		;���j�b�g�ԍ����r
	bne	1b			;���j�b�g�ԍ����قȂ�
9:	move.l	(sp)+,d0
	tst.l	a0			;�f�o�C�X�w�b�_�܂���-1
	rts

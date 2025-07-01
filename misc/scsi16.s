;========================================================================================
;  scsi16.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	scsi16in.r / scsi16ex.r
;		SCSIINROM 16��SCSIEXROM 16
;
;	�ŏI�X�V
;		2024-07-02
;
;	����
;		has060 -i include -o scsi16in.o -w scsi16.s -SSCSIEXROM=0
;		lk -b fc0000 -o scsi16in.x -x scsi16in.o
;		cv /rn scsi16in.x scsi16in.r
;		has060 -i include -o scsi16ex.o -w scsi16.s -SSCSIEXROM=1
;		lk -b ea0000 -o scsi16ex.x -x scsi16ex.o
;		cv /rn scsi16ex.x scsi16ex.r
;
;	�C���ӏ�
;		�ڑ�����Ă��邾���ŋN���ł��Ȃ��Ȃ�@�킪����
;			�N������Request Sense��Inquiry�̃A���P�[�V���������Z������
;			�Z������A���P�[�V�������ɏ]��Ȃ��@�킪�ڑ�����Ă���ƋN�����Ɍł܂�
;			�A���P�[�V���������\���Ȓ����ɂ���
;		�������݂Ɏ��s����\��������
;			DMA�]���̏������݂Ńo�X�G���[���畜�A����Ƃ�DMAC��SPC�̎c��f�[�^�����H���Ⴄ�ꍇ������
;			�H��������܂ܕ��A����Ɠ����f�[�^��2��o�͂���S�̂̐�������Ȃ��Ȃ�
;			�o�X�G���[���畜�A����Ƃ�SPC�̎c��f�[�^����p����DMAC�̃A�h���X�Ǝc��f�[�^�����Čv�Z����
;		�ǂݏo���Ɏ��s����\��������
;			�f�[�^�C���t�F�[�Y����X�e�[�^�X�t�F�[�Y�Ɉڂ�Ƃ�ACK���l�Q�[�g�����̂�҂��Ȃ��@�킪����炵��
;			FIFO����ɂȂ�O�Ƀt�F�[�Y���ς���Service Required���������Ĉُ�I������
;			FIFO����łȂ��Ƃ�Service Required�𖳎�����
;		SASI HD��ڑ�����SASI�t���O���Z�b�g����ƋN���ł��Ȃ��Ȃ�
;			_B_DSKINI��d5/a2��j�󂵂Ă���
;			SCSI�f�o�C�X�h���C�o�g�ݍ��݃��[�`����_B_DSKINI���ׂ���a2���g���Ă��ăX�^�b�N���j�󂳂��
;			_B_DSKINI��d5/a2��ی삷��
;
;	�ǉ��@�\
;		MC68040��MC68060�ɑΉ�����
;			MC68040�܂���MC68060�̂Ƃ�DMA�]���J�n�O�ɃL���b�V�����v�b�V������
;			MC68060�̖������������ߗ�O�̔���������邽��MOVEP���߂��g��Ȃ�
;		�u���b�N����2048�̋@��̃f�B�X�NIPL�ƃf�o�C�X�h���C�o��ǂݏo����
;			�f�B�X�NIPL�̈ʒu��$0400��$0800�̂ǂ���ł��悢
;			S_READ�Ȃǂ�d5�̃u���b�N���w����4�ȏ�̂Ƃ�3�ƌ��Ȃ�
;			NetBSD/x68k�̃C���X�g�[��CD-ROM����N���ł���
;			�f�B�X�NIPL�ƃf�o�C�X�h���C�o���Ή����Ȃ���΃u���b�N����2048�̋@�킩��N���ł��Ȃ����Ƃɕς��͂Ȃ�
;			4096�ȏ�͔�Ή�
;
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	dmac.equ
	.include	dosconst.equ
	.include	hdc.equ
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	scsicall.mac
	.include	spc.equ
	.include	sram.equ
	.include	sysport.equ
	.include	vector.equ

  .ifndef SCSI_BIOS_LEVEL
SCSI_BIOS_LEVEL	equ	16		;���x���B0=SUPER,3=XVI,4=FORMAT.X,10=X68030,16=XEiJ
  .endif
  .ifndef SCSIEXROM
SCSIEXROM	equ	0		;�g�����B0=SCSIINROM,1=SCSIEXROM
  .endif

  .if 16<=SCSI_BIOS_LEVEL
    .if SCSIEXROM
SCSI_BIOS_TITLE	reg	'SCSIEXROM 16 (2024-07-02)'
    .else
SCSI_BIOS_TITLE	reg	'SCSIINROM 16 (2024-07-02)'
    .endif
  .endif

	.cpu	68000
	.text



;--------------------------------------------------------------------------------
;	.include	sc01head.s
;--------------------------------------------------------------------------------

  .if SCSIEXROM
SPC_BASE	equ	SPC_EX_BASE	;�g��SPC�x�[�X�A�h���X
  .else
SPC_BASE	equ	SPC_IN_BASE	;����SPC�x�[�X�A�h���X
  .endif

  .if SCSI_BIOS_LEVEL<=3
abs	reg	.l			;(xxx)abs���΃����O�ɂ���
  .else
abs	reg	.w			;(xxx)abs���΃��[�h�ɂ���
  .endif

dLEN	reg	d3			;�f�[�^�̒���
dID	reg	d4			;(LUN<<16)|SCSI-ID
aBUF	reg	a1			;�o�b�t�@�̃A�h���X
aSPC	reg	a6			;SPC_xxx(aSPC)��SPC�̃��W�X�^���Q�Ƃ���

scsi_bios_start:

  .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
    .if SCSIEXROM
;----------------------------------------------------------------
;SPC
spc_ex_base:
	.dcb.b	32,$FF
    .endif
  .endif

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;ROM�N���n���h��
rom_boot_handle:
	.dc.l	rom_boot_routine				;+0
    .if SCSI_BIOS_LEVEL<>10
	.dc.l	rom_boot_routine				;+4
	.dc.l	rom_boot_routine				;+8
	.dc.l	rom_boot_routine				;+12
	.dc.l	rom_boot_routine				;+16
	.dc.l	rom_boot_routine				;+20
	.dc.l	rom_boot_routine				;+24
	.dc.l	rom_boot_routine				;+28
    .endif

;----------------------------------------------------------------
;ROM�N���n���h��+32 SCSI�������n���h��
scsi_init_handle:
	.dc.l	scsi_init_routine				;+32
  .endif

  .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
;----------------------------------------------------------------
;ROM�N���n���h��+36 SCSIIN/SCSIEX�}�W�b�N
scsi_rom_magic:
    .if SCSIEXROM
	.dc.b	'SCSIEX'					;+36
    .else
	.dc.b	'SCSIIN'					;+36
    .endif
  .endif



;--------------------------------------------------------------------------------
;	.include	sc02boot.s
;--------------------------------------------------------------------------------

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;ROM�N���n���h��+42 SCSI BIOS���x��
scsi_bios_level:
	.dc.w	SCSI_BIOS_LEVEL					;+42

    .if 16<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
scsi_bios_title:
	.dc.b	SCSI_BIOS_TITLE,0
	.even
    .endif
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;SPC�x�[�X�n���h��
;	���x��4��SPC�x�[�X�n���h���̓f�o�C�X�h���C�o�������Ɗg����I������
spc_base_handle:
	.dc.l	SPC_BASE		;SPC�x�[�X�A�h���X
  .endif

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;SCSI���������[�`��
;?d0-d1/a1
scsi_init_routine:
    .if SCSI_BIOS_LEVEL<>10
;_SCSIDRV��o�^����
	moveq.l	#_B_INTVCS,d0
	move.l	#$100+_SCSIDRV,d1
	lea.l	iocs_F5_SCSIDRV(pc),a1	;IOCS�R�[��$F5 _SCSIDRV
	trap	#15
      .if SCSI_BIOS_LEVEL<=10
	if	<cmp.l a1,d0>,ne	;����
      .else
        .if SCSIEXROM
	ifor	<cmp.l a1,d0>,ne,<btst.b #1,BIOS_SCSI_INITIALIZED.w>,eq
        .else
	ifor	<cmp.l a1,d0>,ne,<btst.b #0,BIOS_SCSI_INITIALIZED.w>,eq
        .endif
	;_SCSIDRV�̃x�N�^���������w���Ă��Ȃ������܂���SCSI�������ς݃t���O���Z�b�g����Ă��Ȃ��Ƃ�
      .endif
	;_S_RESET���Ăяo��
		moveq.l	#_SCSIDRV,d0
		moveq.l	#_S_RESET,d1
		trap	#15
      .if 16<=SCSI_BIOS_LEVEL
		goto	<tst.b SRAM_SCSI_SASI_FLAG>,eq,scsi_init_skip	;SASI�@�킪�ڑ�����Ă��Ȃ�
		goto	<tst.l BIOS_SCSI_OLD_VERIFY.w>,ne,scsi_init_skip	;���Ɋg������Ă���
      .endif
	;IOCS�R�[��$40�`$4F��o�^����
		bsr	install_sasi_iocs	;SCSI�o�X�ɐڑ�����Ă���SASI�@���IOCS�R�[��$40�`$4F�ő���ł���悤�ɂ���
	;TRAP#11(BREAK)��o�^����
		moveq.l	#_B_INTVCS,d0
		moveq.l	#OFFSET_TRAP_11/4,d1	;��O�x�N�^$2B TRAP#11(BREAK)
		lea.l	trap_11_break(pc),a1	;TRAP#11(BREAK)
		trap	#15
      .if 16<=SCSI_BIOS_LEVEL
	;TRAP#11(BREAK)��o�^���Ă��猳�̃x�N�^��ۑ�����܂ł̊Ԃ�BREAK�L�[���������\�����[���ł͂Ȃ��̂Ŏ菇�Ƃ��Ă͐������Ȃ�
		move.l	d0,BIOS_SCSI_OLD_TRAP11.l	;��O�x�N�^$2B TRAP#11(BREAK)�̌��̃x�N�^
	scsi_init_skip:
      .endif
	endif
    .else
	bsr	dskini_all		;SASI�n�[�h�f�B�X�N������������
    .endif
	rts

;----------------------------------------------------------------
;ROM�N�����[�`��-20 ROM�N���}�W�b�N
;	ROM 1.3���N������SCSI-ID�����߂�Ƃ��Ɋm�F����
rom_boot_magic:
	.dc.l	'SCSI'

;----------------------------------------------------------------
;ROM�N�����[�`��-16 SCSI�f�o�C�X�h���C�o�g�ݍ��݃n���h��
;	Human68k 3.02���f�o�C�X�h���C�o��g�ݍ��ނƂ��ɎQ�Ƃ���
device_installer_handle:
	.dc.l	device_installer	;SCSI�f�o�C�X�h���C�o�g�ݍ��݃��[�`��

;----------------------------------------------------------------
;ROM�N�����[�`��-12 SCSI�f�o�C�X�h���C�o�g�ݍ��݃��[�`���̃p�����[�^
;	Human68k 3.02��SCSI�f�o�C�X�h���C�o��g�ݍ��ނƂ��ɎQ�Ƃ���
;	FORMAT2.X���n�[�h�f�B�X�N�ɏ�������SCSI�f�o�C�X�h���C�o��
;	�u�w�肳�ꂽSCSI ROM��p����_S_RESET�����s���A�ݒ肳��Ă��Ȃ����_SCSIDRV��ݒ肷��v
;	�Ƃ�������������A�������Q�Ƃ��Ă���
;	�����ɂ�IOCS�R�[��$F5 _SCSIDRV�̃n���h�����Ȃ���΂Ȃ�Ȃ�
device_installer_parameter:
	.dc.l	iocs_F5_SCSIDRV		;IOCS�R�[��$F5 _SCSIDRV

;----------------------------------------------------------------
;ROM�N�����[�`��-8 �f�o�C�X�h���C�o���ʎq
;	Human68k 3.02��SCSI�f�o�C�X�h���C�o��g�ݍ��ނƂ��Ɋm�F����
device_installer_magic:
	.dc.b	'Human68k'

;----------------------------------------------------------------
;ROM�N�����[�`��
rom_boot_routine:
;�N������SCSI-ID�����߂�
    .if SCSI_BIOS_LEVEL<>10
	IOCS	_BOOTINF
      .if 3<=SCSI_BIOS_LEVEL
	andi.l	#$00FFFFFF,d0
      .endif
	move.l	d0,d4
	subi.l	#rom_boot_handle,d4	;ROM�N���n���h������̃I�t�Z�b�g
	lsr.l	#2,d4			;�N������SCSI-ID
    .else
	bsr	get_scsi_id_to_boot	;�N������SCSI-ID�����߂�
	if	<tst.l d0>,mi
		moveq.l	#0,d0
	endif
	move.l	d0,d4			;�N������SCSI-ID
    .endif
;<d4.l:�N������SCSI-ID�B-1=SCSI�N���ł͂Ȃ�
    .if SCSI_BIOS_LEVEL<>10
      .if SCSI_BIOS_LEVEL<=10
;_SCSIDRV��o�^����
	moveq.l	#_B_INTVCS,d0
	move.l	#$100+_SCSIDRV,d1
	lea.l	iocs_F5_SCSIDRV(pc),a1	;IOCS�R�[��$F5 _SCSIDRV
	trap	#15
	if	<cmp.l a1,d0>,ne	;����
	;_S_RESET���Ăяo��
		moveq.l	#_SCSIDRV,d0
		moveq.l	#_S_RESET,d1		;SPC�̏�������SCSI�o�X���Z�b�g
		trap	#15
	;(SCSI����N�������Ƃ�)
	;IOCS�R�[��$40�`$4F��o�^����
		bsr	install_sasi_iocs	;SCSI�o�X�ɐڑ�����Ă���SASI�@���IOCS�R�[��$40�`$4F�ő���ł���悤�ɂ���
	;TRAP#11(BREAK)��o�^����
		moveq.l	#_B_INTVCS,d0
		moveq.l	#OFFSET_TRAP_11/4,d1	;��O�x�N�^$2B TRAP#11(BREAK)
		lea.l	trap_11_break(pc),a1	;TRAP#11(BREAK)
		trap	#15
        .if 3<=SCSI_BIOS_LEVEL
		move.l	d0,BIOS_SCSI_OLD_TRAP11.l	;��O�x�N�^$2B TRAP#11(BREAK)�̌��̃x�N�^
        .endif
	endif
      .else
	bsr	scsi_init_routine	;SCSI���������[�`��
      .endif
    .else
	bsr	dskini_all		;SASI�n�[�h�f�B�X�N������������
    .endif
;�A�N�Z�X�J�n
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,ne,scsi_boot_failed	;�N������SCSI-ID��SASI�t���O���Z�b�g����Ă���̂Ŏ��s
    .if SCSI_BIOS_LEVEL<=3
	moveq.l	#10-1,d6		;10��܂Ń��g���C����
    .else
	moveq.l	#20-1,d6		;20��܂Ń��g���C����
    .endif
scsi_boot_redo:
	bsr	check_confliction_1st	;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����
;<d0.l:-1=�{�̂Ɠ���SCSI-ID�̋@��͂Ȃ�
    .if SCSI_BIOS_LEVEL<=3
	goto	<cmp.l #-1,d0>,ne,scsi_boot_failed	;�{�̂Ɠ���SCSI-ID�̋@�킪�ڑ�����Ă���̂Ŏ��s
    .else
	addq.l	#1,d0
	goto	ne,scsi_boot_failed	;�{�̂Ɠ���SCSI-ID�̋@�킪�ڑ�����Ă���̂Ŏ��s
    .endif
;Test Unit Ready
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_TESTUNIT,d1
	trap	#15
    .if SCSI_BIOS_LEVEL<=3
	goto	<cmp.l #0,d0>,eq,test_unit_passed	;_S_TESTUNIT��Command Complete���Ԃ���
    .else
	goto	<tst.l d0>,eq,test_unit_passed	;_S_TESTUNIT��Command Complete���Ԃ���
    .endif
	goto	<cmp.l #-1,d0>,eq,scsi_boot_retry	;�G���[�̂Ƃ��̓��g���C
	goto	<cmp.l #8,d0>,eq,scsi_boot_retry	;Busy�̂Ƃ��̓��g���C
	goto	<cmp.l #2,d0>,ne,scsi_boot_failed	;Check Condition�łȂ���Ύ��s
;_S_TESTUNIT��Check Condition���Ԃ���
;Request Sense
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_REQUEST,d1
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;Request Sense�̃A���P�[�V������������Ȃ�
;	Request Sense�̃Z���X�f�[�^�̓G���[�N���X�ɂ����4�o�C�g�܂���8�o�C�g�ȏゾ���A���P�[�V��������3�o�C�g�ɂȂ��Ă���
;	�N�����ɃA���P�[�V���������������̃f�[�^��Ԃ����Ƃ���SCSI�@�킪�ڑ�����ēd���������Ă���ƃn���O�A�b�v����
;	�Q�l: �d�]��y��111�� FDS120T.DOC
	moveq.l	#3,d3			;�A���P�[�V������
;+++++ BUG +++++
    .else
	moveq.l	#8,d3			;�A���P�[�V�������B8�ȏ�
    .endif
    .if SCSI_BIOS_LEVEL<=3
	lea.l	$00002000.l,a1
    .else
	lea.l	$2000.w,a1
    .endif
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed
    .if SCSI_BIOS_LEVEL<=3
	lea.l	$00002000.l,a1
    .else
	lea.l	$2000.w,a1
    .endif
	move.b	(a1),d0			;�Z���X�G���[�R�[�h
	andi.b	#$70,d0
	goto	<cmpi.b #$70,d0>,ne,scsi_boot_failed	;�g���Z���X�L�[���Ȃ���Ύ��s
	move.b	2(a1),d0		;�Z���X�L�[
	goto	eq,scsi_boot_redo	;No Sense�̓��g���C
	goto	<cmp.b #1,d0>,eq,scsi_boot_redo	;Recovered Error�̓��g���C
	goto	<cmp.b #6,d0>,eq,scsi_boot_redo	;Unit Attention�̓��g���C
    .if 10<=SCSI_BIOS_LEVEL
	goto	<cmp.b #2,d0>,eq,scsi_boot_redo	;Not Ready�̓��g���C
    .endif
	goto	scsi_boot_failed	;����ȊO�͎��s

;���g���C
scsi_boot_retry:
	dbra.w	d6,scsi_boot_redo_1
;���g���C�񐔂�����𒴂���
	goto	scsi_boot_failed

scsi_boot_redo_1:
	goto	scsi_boot_redo

scsi_boot_failed:
	rts

;_S_TESTUNIT��Command Complete���Ԃ���
test_unit_passed:
    .if SCSI_BIOS_LEVEL<=3
	bsr	check_confliction_1st	;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����
    .else
	bsr	check_confliction_2nd	;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����(�m�F�ς݂Ȃ�Ή������Ȃ�)
    .endif
;<d0.l:-1=�{�̂Ɠ���SCSI-ID�̋@��͂Ȃ�
    .if SCSI_BIOS_LEVEL<=3
	goto	<cmp.l #-1,d0>,ne,scsi_boot_failed	;�{�̂Ɠ���SCSI-ID�̋@�킪�ڑ�����Ă���̂Ŏ��s
    .else
	addq.l	#1,d0
	goto	ne,scsi_boot_failed	;�{�̂Ɠ���SCSI-ID�̋@�킪�ڑ�����Ă���̂Ŏ��s
    .endif
;Inquiry
    .if SCSI_BIOS_LEVEL<=3
	lea.l	$00002000.l,a1
    .else
	lea.l	$2000.w,a1
    .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_INQUIRY,d1
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;Inquiry�̃A���P�[�V������������Ȃ�
;	Inquiry��EVPD��0�̂Ƃ��A���P�[�V��������5�o�C�g�ȏ�łȂ���΂Ȃ�Ȃ��̂�1�o�C�g�ɂȂ��Ă���
;	Inquiry��1��ڂ�5�o�C�g�v������2��ڂɒǉ��f�[�^��+5�o�C�g�v������̂�������
;	�ŏ�����36�o�C�g�v�����Ă��ǂ���2��ɕ������������
	moveq.l	#1,d3
;+++++ BUG +++++
    .else
	moveq.l	#5,d3			;�A���P�[�V�������B5�ȏ�
    .endif
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;INQUIRY�Ŏ��s
    .if SCSI_BIOS_LEVEL<=3
	gotoand	<cmpi.b #$84,0.w(a1)>,ne,<tst.b 0.w(a1)>,ne,scsi_boot_failed	;SHARP MO�ƃ_�C���N�g�A�N�Z�X�f�o�C�X�ȊO�͎��s
    .else
	ifand	<btst.b #SRAM_SCSI_IGNORE_BIT,SRAM_SCSI_MODE>,eq,<tst.b (a1)>,ne,<cmpi.b #$04,(a1)>,ne,<cmpi.b #$05,(a1)>,ne,<cmpi.b #$07,(a1)>,ne,<cmpi.b #$84,(a1)>,ne
		;�^�C�v�����ł͂Ȃ���
		;�f�o�C�X�^�C�v��
		;	$00(�_�C���N�g�A�N�Z�X�f�o�C�X)
		;	$04(���C�g�����X�f�o�C�X(�ǋL�^���f�B�X�N))
		;	$05(CD-ROM�f�o�C�X)
		;	$07(���������f�o�C�X(�����\���f�B�X�N))
		;	$84(SHARP MO)
		;�ł͂Ȃ�
		goto	scsi_boot_failed	;���s

	endif
    .endif
;Rezero Unit
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_REZEROUNIT,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;REZEROUNIT�Ŏ��s
;Read Capacity
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READCAP,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;READCAP�Ŏ��s
    .if SCSI_BIOS_LEVEL<=0
;+++++ BUG +++++
;�u���b�N����2048�ȏ�̂Ƃ��f�ʂ肳���Ă��邪����ɓ��삵�Ȃ�
;+++++ BUG +++++
    .elif SCSI_BIOS_LEVEL<=3
	goto	<cmpi.l #2048,4(a1)>,cc,scsi_boot_failed	;�u���b�N����2048�ȏ�̂Ƃ��͎��s
    .elif SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;�u���b�N����2048�ȏ�̂Ƃ��f�ʂ肳���Ă��邪����ɓ��삵�Ȃ�
;+++++ BUG +++++
    .endif
	move.l	4(a1),d5		;�u���b�N��
	lsr.l	#8,d5
	lsr.l	#1,d5			;256��0,512��1,1024��2,2048��4,4096��8,�c
    .if 16<=SCSI_BIOS_LEVEL
	goto	<cmp.l #4,d5>,hi,scsi_boot_failed	;�u���b�N�����傫������̂Ŏ��s
	if	eq			;2048
		moveq.l	#3,d5			;2048��3
	endif
    .endif
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
    .if SCSI_BIOS_LEVEL<=10
;$0000-$03FF��$2000-$23FF�ɓǂݍ���
	moveq.l	#$0000/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;�u���b�N���ɉ����ău���b�N�ԍ��ƃu���b�N���𒲐�����
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;READ�Ŏ��s
	gotoor	<cmpi.l #'X68S',0.w(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,scsi_boot_failed	;���u����������Ă��Ȃ��̂Ŏ��s
;$0400-$07FF��$2000-$23FF�ɓǂݍ���
	moveq.l	#$0400/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;�u���b�N���ɉ����ău���b�N�ԍ��ƃu���b�N���𒲐�����
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;READ�Ŏ��s
	goto	<cmpi.b #$60,(a1)>,ne,scsi_boot_failed	;IPL�̐擪��bra�łȂ��̂Ŏ��s
	jsr	(a1)			;�f�B�X�NIPL���N������
	goto	scsi_boot_failed	;�f�B�X�NIPL����A���Ă��Ă��܂����̂Ŏ��s

    .else
;$0000-$07FF��$2000-$27FF�ɓǂݍ���
	moveq.l	#$0000/256,d2
	moveq.l	#$0800/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	lea.l	$2000.w,a1
	SCSI	_S_READ
	goto	<tst.l d0>,ne,scsi_boot_failed	;READ�Ŏ��s
	gotoor	<cmpi.l #'X68S',(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,scsi_boot_failed	;���u����������Ă��Ȃ��̂Ŏ��s
	if	<cmpi.b #$60,$0400(a1)>,eq	;$0400-$07FF�Ƀf�B�X�NIPL������
		;$2400-$27FF��$2000-$23FF�ɃR�s�[����
		lea.l	$2000.w,a1
		move.w	#$0400/4-1,d0
		for	d0
			move.l	$0400(a1),(a1)+
		next
		move.w	#$0400/4-1,d0
		for	d0
			clr.l	(a1)+
		next
	else
	;$0400-$07FF�Ƀf�B�X�NIPL���Ȃ�
	;$0800-$0FFF��$2000-$27FF�ɓǂݍ���
		moveq.l	#$0800/256,d2
		moveq.l	#$0800/256,d3
		lsr.l	d5,d2
		lsr.l	d5,d3
		lea.l	$2000.w,a1
		SCSI	_S_READ
		goto	<tst.l d0>,ne,scsi_boot_failed	;READ�Ŏ��s
		goto	<cmpi.b #$60,(a1)>,ne,scsi_boot_failed	;$0800-$0FFF�Ƀf�B�X�NIPL���Ȃ�
	;$0800-$0FFF�Ƀf�B�X�NIPL������
	endif
	bsr	cache_flush
	moveq.l	#0,d0
	lea.l	$2000.w,a1
	jsr	(a1)			;�f�B�X�NIPL���N������
	goto	scsi_boot_failed	;�f�B�X�NIPL����A���Ă��Ă��܂����̂Ŏ��s

    .endif

    .if SCSI_BIOS_LEVEL==10
;----------------------------------------------------------------
;�N������SCSI-ID�����߂�
;>d0.l:SCSI-ID(0�`7,-1=SCSI�N���ł͂Ȃ�)
get_scsi_id_to_boot:
	IOCS	_BOOTINF
	andi.l	#$00FFFFFF,d0
	if	<cmp.l #$00000100,d0>,cc	;ROM�N���܂���SRAM�N��
	;+++++ BUG +++++
	;ROM�N���A�h���X-20��s�p�ӂɃ��[�h���Ă���
	;	������SRAM�N���Ȃ��SRAM�N�����[�`���̐擪4�o�C�g�̒l-20�����[�h���邱�ƂɂȂ�
	;	�N������SCSI ROM�������łȂ��Ă�SCSI-ID�𔻕ʂł���悤�ɂ��悤�Ƃ����悤�Ɍ����邪�ړI���s��
		movea.l	d0,a0			;ROM�N���n���h���܂���SRAM�N���A�h���X
		movea.l	(a0),a0			;ROM�N���A�h���X
	;+++++ BUG +++++
		if	<cmpi.l #'SCSI',rom_boot_magic-rom_boot_routine(a0)>,eq	;ROM�N���}�W�b�N���r�BSCSI�N��
			andi.l	#31,d0			;SCSI ROM�̐擪����̃I�t�Z�b�g
			lsr.l	#2,d0			;�N������SCSI-ID
			rts

		endif
	;SCSI�N���ł͂Ȃ�
	endif
;ROM�N���܂���SRAM�N���ł͂Ȃ�
	moveq.l	#-1,d0
	rts
    .endif

    .if 10<=SCSI_BIOS_LEVEL
;�N���ł��Ȃ�
next_device:
	bset.b	d2,BIOS_SCSI_UNBOOTABLE.w
	addq.w	#1,d2
	goto	install_device
    .endif

;----------------------------------------------------------------
;SCSI�f�o�C�X�h���C�o�g�ݍ��݃��[�`��
;	Human68k��SCSI�f�o�C�X�h���C�o��g�ݍ��ނƂ��ŏ��ɌĂяo��
;<d2.l:(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID�B�����0�B�g�ݍ���SCSI-ID��8�̂Ƃ��I��
;<a1.l:�f�o�C�X�h���C�o�̃R�s�[��̃A�h���X
;>d2.l:�����(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
device_installer:
	push	d0-d1/d3-d7/a0-a6
;�N������SCSI-ID�����߂�
    .if SCSI_BIOS_LEVEL<>10
	IOCS	_BOOTINF
      .if 3<=SCSI_BIOS_LEVEL
	andi.l	#$00FFFFFF,d0
      .endif
	subi.l	#rom_boot_handle,d0	;ROM�N���n���h������̃I�t�Z�b�g
	if	cc
		lsr.l	#2,d0			;�N������SCSI-ID
		move.b	d0,d7			;�N������SCSI-ID
		goto	<cmpi.l #8,d0>,cs,install_device	;SCSI�N��
	endif
	moveq.l	#-1,d7
	goto	<cmpi.l #8,d0>,eq,install_device	;�N������SCSI-ID��8�BSASI�N���H
	goto	<tst.b d2>,ne,install_device	;�g�ݍ���SCSI-ID��0�ł͂Ȃ�
;�g�ݍ���SCSI-ID��0
	movea.l	a1,a2
;<a2.l:�f�o�C�X�h���C�o�̃R�s�[��̃A�h���X
      .if SCSI_BIOS_LEVEL<=10
;_SCSIDRV��o�^����
	moveq.l	#_B_INTVCS,d0
	move.l	#$100+_SCSIDRV,d1
	lea.l	iocs_F5_SCSIDRV(pc),a1	;IOCS�R�[��$F5 _SCSIDRV
	trap	#15
	if	<cmp.l a1,d0>,ne	;����
	;_S_RESET���Ăяo��
		moveq.l	#_SCSIDRV,d0
		moveq.l	#_S_RESET,d1		;SPC�̏�������SCSI�o�X���Z�b�g
		trap	#15
	;(SCSI����N�����Ȃ������Ƃ�)
	;IOCS�R�[��$40�`$4F��o�^���Ȃ�
	;TRAP#11(BREAK)��o�^����
		moveq.l	#_B_INTVCS,d0
		moveq.l	#OFFSET_TRAP_11/4,d1	;��O�x�N�^$2B TRAP#11(BREAK)
		lea.l	trap_11_break(pc),a1	;TRAP#11(BREAK)
		trap	#15
        .if 3<=SCSI_BIOS_LEVEL
		move.l	d0,BIOS_SCSI_OLD_TRAP11.l	;��O�x�N�^$2B TRAP#11(BREAK)�̌��̃x�N�^
        .endif
	endif
      .else
	bsr	scsi_init_routine	;SCSI���������[�`��
      .endif
	movea.l	a2,a1
;<a1.l:�f�o�C�X�h���C�o�̃R�s�[��̃A�h���X
    .else
	bsr	get_scsi_id_to_boot	;�N������SCSI-ID�����߂�
	if	<tst.l d0>,pl
		move.b	d0,d7			;�N������SCSI-ID
		goto	<cmpi.w #8,d0>,cs,install_device
	endif
	moveq.l	#-1,d7			;SCSI�N���ł͂Ȃ�
    .endif
;SCSI�N��
;<d2.l:(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
;<d7.l:�N������SCSI-ID�B-1=SCSI�N���ł͂Ȃ�
;<a1.l:�f�o�C�X�h���C�o�̃R�s�[��̃A�h���X
install_device:
	goto	<cmp.w #8,d2>,eq,install_finish	;�g�ݍ���SCSI-ID��8�B�I��
;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����
    .if SCSI_BIOS_LEVEL<=3
	bsr	check_confliction_1st	;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����
	goto	<cmp.l #-1,d0>,ne,install_finish	;�{�̂Ɠ���SCSI-ID�̋@�킪����
    .else
	bsr	check_confliction_2nd	;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����(�m�F�ς݂Ȃ�Ή������Ȃ�)
	goto	<addq.l #1,d0>,ne,install_finish	;�{�̂Ɠ���SCSI-ID�̋@�킪����
    .endif
;�{�̂Ɠ���SCSI-ID�̋@��͂Ȃ�
wait_device:
	moveq.l	#0,d4
	move.w	d2,d4			;�g�ݍ���SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,ne,next_device	;SASI�͎��s
    .if 10<=SCSI_BIOS_LEVEL
	goto	<btst.b d4,BIOS_SCSI_UNBOOTABLE.w>,ne,next_device	;�N���ł��Ȃ�
    .endif
	move.b	SRAM_SCSI_MODE,d0	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
	andi.b	#7,d0			;�{�̂�SCSI-ID
	goto	<cmp.b d4,d0>,eq,next_device	;�{�͎̂��s
;Test Unit Ready
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_TESTUNIT,d1
	trap	#15
	if	<cmp.l #2,d0>,ne	;Check Condition�ȊO
		goto	<cmp.l #8,d0>,eq,wait_device	;Busy�͑҂�
		goto	<tst.l d0>,ne,next_device	;Check Condition��Busy�ȊO�̃G���[�͎��s
	endif
;Request Sense
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_REQUEST,d1
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;Request Sense�̃A���P�[�V������������Ȃ�
;	����
	moveq.l	#3,d3
;+++++ BUG +++++
    .else
	moveq.l	#8,d3			;�A���P�[�V�������B8�ȏ�
    .endif
	trap	#15
	goto	<tst.l d0>,ne,next_device	;REQUEST�Ŏ��s
;Inquiry
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_INQUIRY,d1
	moveq.l	#36,d3
	trap	#15
    .if SCSI_BIOS_LEVEL<>10
	goto	<tst.l d0>,ne,next_device	;INQUIRY�Ŏ��s
    .else
	tst.l	d0
;!!! �V���[�g�œ͂��̂Ƀ��[�h�ɂȂ��Ă���
	bne.w	next_device		;INQUIRY�Ŏ��s
    .endif
    .if SCSI_BIOS_LEVEL<=3
	gotoand	<cmpi.b #$84,0.w(a1)>,ne,<tst.b 0.w(a1)>,ne,next_device	;SHARP MO�ƃ_�C���N�g�A�N�Z�X�f�o�C�X�ȊO�͎��s
    .else
	ifand	<btst.b #6,SRAM_SCSI_MODE>,eq,<tst.b (a1)>,ne,<cmpi.b #$04,(a1)>,ne,<cmpi.b #$05,(a1)>,ne,<cmpi.b #$07,(a1)>,ne,<cmpi.b #$84,(a1)>,ne
	;�^�C�v�����ł͂Ȃ���
	;�f�o�C�X�^�C�v��
	;	$00(�_�C���N�g�A�N�Z�X�f�o�C�X)
	;	$04(���C�g�����X�f�o�C�X(�ǋL�^���f�B�X�N))
	;	$05(CD-ROM�f�o�C�X)
	;	$07(���������f�o�C�X(�����\���f�B�X�N))
	;	$84(SHARP MO)
	;�ł͂Ȃ�
		goto	next_device		;���s

	endif
    .endif
;Read Capacity
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READCAP,d1
	trap	#15
	goto	<tst.l d0>,ne,next_device	;READCAP�Ŏ��s
	move.l	d2,d6			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	move.l	4(a1),d5		;�u���b�N��
	lsr.l	#8,d5
	lsr.l	#1,d5			;256��0,512��1,1024��2,2048��4,4096��8,�c
    .if 16<=SCSI_BIOS_LEVEL
	goto	<cmp.l #4,d5>,hi,next_device	;�u���b�N�����傫������̂Ŏ��s
	if	eq			;2048
		moveq.l	#3,d5			;2048��3
	endif
    .endif
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
    .if SCSI_BIOS_LEVEL<=10
;$0800-$0BFF��a1-(a1+$03FF)�ɓǂݍ���
	moveq.l	#$0800/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;�u���b�N���ɉ����ău���b�N�ԍ��ƃu���b�N���𒲐�����
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	move.l	d6,d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	goto	<tst.l d0>,ne,next_device	;READ�Ŏ��s
	goto	<cmpi.l #'X68K',(a1)>,ne,next_device	;�p�[�e�B�V�����e�[�u�����Ȃ��B���u����������Ă��Ȃ�
;SCSI�N���̂Ƃ��͋N������SCSI-ID�̎����N���̃p�[�e�B�V�����܂ł̎����N���܂��͎g�p�\�ȃp�[�e�B�V�����̐��𐔂���
;SCSI�N���łȂ��Ƃ��͂��ׂĂ�SCSI-ID�̎����N���܂��͎g�p�\�ȃp�[�e�B�V�����̐��𐔂���
	swap.w	d2			;(�g�ݍ���SCSI-ID<<16)|�p�[�e�B�V�����̐�
	if	<cmp.b d7,d4>,ls	;(���݂�SCSI-ID)-(�N������SCSI-ID)
	;SCSI�N���̂Ƃ��͑g�ݍ���SCSI-ID���N������SCSI-ID�ȉ��BSCSI�N���łȂ��Ƃ��͂��ׂ�
      .if SCSI_BIOS_LEVEL<=3
		if	ne			;�g�ݍ���SCSI-ID���N������SCSI-ID�ƈႤ
			bsr	count_partition_1	;�����N���܂��͎g�p�\�ȃp�[�e�B�V�����̐��𐔂���
			add.w	d3,d2			;�p�[�e�B�V�����̐������Z
		else				;�g�ݍ���SCSI-ID���N������SCSI-ID�Ɠ���
			bsr	count_partition_2	;�����N���܂��͎g�p�\�ȃp�[�e�B�V�����̐��������N���̃p�[�e�B�V������������܂Ő�����
			add.w	d3,d2			;�p�[�e�B�V�����̐������Z
		endif
      .else
		bsr	count_partition		;�����N���܂��͋N���\�ȃp�[�e�B�V�����𐔂���
		add.w	d3,d2			;�p�[�e�B�V�����̐������Z
      .endif
	endif
	swap.w	d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	move.l	d2,d6			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
;$0000-$03FF��(a1)-(a1+$03FF)�ɓǂݍ���
	moveq.l	#$0000/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;�u���b�N���ɉ����ău���b�N�ԍ��ƃu���b�N���𒲐�����
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	move.l	d6,d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	goto	<tst.l d0>,ne,next_device	;READ�Ŏ��s
	gotoor	<cmpi.l #'X68S',0.w(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,next_device	;���u����������Ă��Ȃ�
;$0C00-$3FFF��(a1)-(a1+$33FF)�ɓǂݍ���
	moveq.l	#$0C00/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$3400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$3400/256,d3
	bsr	adjust_block_number	;�u���b�N���ɉ����ău���b�N�ԍ��ƃu���b�N���𒲐�����
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	move.l	d6,d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	goto	<tst.l d0>,ne,next_device	;READ�Ŏ��s
    .else
;<d6.l:(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	movea.l	a1,a2
;<a2.l:�f�o�C�X�h���C�o�̃R�s�[��̃A�h���X
;$0000-$07FF��(a2)-(a2+$07FF)�ɓǂݍ���
	moveq.l	#$0000/256,d2
	moveq.l	#$0800/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	movea.l	a2,a1
	SCSI	_S_READ
	move.l	d6,d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	goto	<tst.l d0>,ne,next_device	;READ�Ŏ��s
	gotoor	<cmpi.l #'X68S',0.w(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,next_device	;���u����������Ă��Ȃ�
;$0800-$0FFF��(a2)-(a2+$07FF)�ɓǂݍ���
	moveq.l	#$0800/256,d2
	moveq.l	#$0800/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	movea.l	a2,a1
	SCSI	_S_READ
	move.l	d6,d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	goto	<tst.l d0>,ne,next_device	;READ�Ŏ��s
	goto	<cmpi.l #'X68K',(a1)>,ne,next_device	;�p�[�e�B�V�����e�[�u�����Ȃ��B���u����������Ă��Ȃ�
;SCSI�N���̂Ƃ��͋N������SCSI-ID�̎����N���̃p�[�e�B�V�����܂ł̎����N���܂��͎g�p�\�ȃp�[�e�B�V�����̐��𐔂���
;SCSI�N���łȂ��Ƃ��͂��ׂĂ�SCSI-ID�̎����N���܂��͎g�p�\�ȃp�[�e�B�V�����̐��𐔂���
	swap.w	d2			;(�g�ݍ���SCSI-ID<<16)|�p�[�e�B�V�����̐�
	if	<cmp.b d7,d4>,ls	;(���݂�SCSI-ID)-(�N������SCSI-ID)
	;SCSI�N���̂Ƃ��͑g�ݍ���SCSI-ID���N������SCSI-ID�ȉ��BSCSI�N���łȂ��Ƃ��͂��ׂ�
		bsr	count_partition		;�����N���܂��͋N���\�ȃp�[�e�B�V�����𐔂���
		add.w	d3,d2			;�p�[�e�B�V�����̐������Z
	endif
	swap.w	d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	move.l	d2,d6			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
;(a2+$0400)-(a2+$07FF)��(a2)-(a2+$03FF)�ɃR�s�[����
	movea.l	a2,a1
	move.w	#$0400/4-1,d0
	for	d0
		move.l	$0400(a1),(a1)+
	next
;$1000-$3FFF��(a2+$0400)-(a2+$33FF)�ɓǂݍ���
	moveq.l	#$1000/256,d2
	moveq.l	#$3000/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	lea.l	$0400(a2),a1
	SCSI	_S_READ
	move.l	d6,d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
	goto	<tst.l d0>,ne,next_device	;READ�Ŏ��s
	movea.l	a2,a1
    .endif
;�f�o�C�X�w�b�_�������P�[�g����
	do
		gotoor	<cmpi.l #($01.shl.24)|'SCH',14(a1)>,ne,<cmpi.l #'DISK',18(a1)>,ne,next_device	;SCSI�f�o�C�X�h���C�o���Ȃ�
		move.l	a1,d0
		add.l	d0,6(a1)		;�X�g���e�W�n���h���������P�[�g����
		add.l	d0,10(a1)		;�C���^���v�g�n���h���������P�[�g����
		move.l	(a1),d0			;�l�N�X�g�f�o�C�X�h���C�o�n���h��
		break	<cmp.l #-1,d0>,eq	;�Ō�̃f�o�C�X�h���C�o
		add.l	a1,d0			;�l�N�X�g�f�o�C�X�h���C�o�n���h���������P�[�g����
		move.l	d0,(a1)
		movea.l	d0,a1
	while	t
	swap.w	d2			;(�g�ݍ���SCSI-ID<<16)|�p�[�e�B�V�����̐�
	move.b	d2,22(a1)		;�Ō�̃f�o�C�X�h���C�o�Ƀp�[�e�B�V�����̐���ݒ肷��
	swap.w	d2			;(�p�[�e�B�V�����̐�<<16)|�g�ݍ���SCSI-ID
    .if SCSI_BIOS_LEVEL<=3
	pop_test
	addq.w	#1,d2			;���̑g�ݍ���SCSI-ID
	rts

;����SCSI-ID��
next_device:
	addq.w	#1,d2			;���̑g�ݍ���SCSI-ID
	goto	install_device

install_finish:
	pop
	moveq.l	#-1,d2
	rts
    .else
	bclr.b	d2,BIOS_SCSI_UNBOOTABLE.w	;����SCSI-ID�͋N���\
	addq.w	#1,d2			;���̑g�ݍ���SCSI-ID
device_installer_end:
	pop
	rts

install_finish:
	moveq.l	#-1,d2
	goto	device_installer_end
    .endif

    .if SCSI_BIOS_LEVEL<=3
;----------------------------------------------------------------
;�����N���܂��͎g�p�\�ȃp�[�e�B�V�����𐔂���
;<a1.l:�p�[�e�B�V�����e�[�u���̐擪
;>d3.w:�p�[�e�B�V�����̐�
count_partition_1:
	push	d2/a1
	moveq.l	#15-1,d2
	moveq.l	#0,d3
	for	d2
		lea.l	16(a1),a1
		continue	<tst.b (a1)>,eq	;�p�[�e�B�V�������Ȃ�
		continue	<cmpi.l #'Huma',(a1)>,ne	;Human68k�̃p�[�e�B�V�����ł͂Ȃ�
		continue	<cmpi.l #'n68k',4(a1)>,ne	;Human68k�̃p�[�e�B�V�����ł͂Ȃ�
		move.b	8(a1),d0		;0=�����N��,1=�g�p�s��,2=�g�p�\
		continue	<btst.l #0,d0>,ne	;�g�p�s��
		addq.w	#1,d3			;�����N���܂��͎g�p�\
	next
	pop
	rts

;----------------------------------------------------------------
;�����N���܂��͎g�p�\�ȃp�[�e�B�V�����𐔂���
;	�����N���̃p�[�e�B�V�����ŏI������
;<a1.l:�p�[�e�B�V�����e�[�u���̐擪
;>d3.w:�p�[�e�B�V�����̐�
count_partition_2:
	push	d2/a1
	moveq.l	#15-1,d2
	moveq.l	#0,d3
	for	d2
		lea.l	16(a1),a1
		continue	<tst.b (a1)>,eq	;�p�[�e�B�V�������Ȃ�
		continue	<cmpi.l #'Huma',(a1)>,ne	;Human68k�̃p�[�e�B�V�����ł͂Ȃ�
		continue	<cmpi.l #'n68k',4(a1)>,ne	;Human68k�̃p�[�e�B�V�����ł͂Ȃ�
		move.b	8(a1),d0		;0=�����N��,1=�g�p�s��,2=�g�p�\
		continue	<btst.l #0,d0>,ne	;�g�p�s��
		addq.w	#1,d3			;�����N���܂��͎g�p�\
		break	<tst.b d0>,eq		;�����N��
	next
	pop
	rts
    .else
;----------------------------------------------------------------
;�����N���܂��͎g�p�\�ȃp�[�e�B�V�����𐔂���
;	�N������SCSI-ID�̂Ƃ��͎����N���̃p�[�e�B�V�����ŏI������
;<ccr:(���݂�SCSI-ID)-(�N������SCSI-ID)
;<a1.l:�p�[�e�B�V�����e�[�u���̐擪
;>d3.w:�p�[�e�B�V�����̐�
count_partition:
	push	d1/d2/a1
	seq.b	d1			;-1=(���݂�SCSI-ID)==(�N������SCSI-ID)
	moveq.l	#15-1,d2
	moveq.l	#0,d3
	for	d2
		lea.l	16(a1),a1
		continue	<tst.b (a1)>,eq	;�p�[�e�B�V�������Ȃ�
		continue	<cmpi.l #'Huma',(a1)>,ne	;Human68k�̃p�[�e�B�V�����ł͂Ȃ�
		continue	<cmpi.l #'n68k',4(a1)>,ne	;Human68k�̃p�[�e�B�V�����ł͂Ȃ�
		move.b	8(a1),d0		;0=�����N��,1=�g�p�s��,2=�g�p�\
		continue	<btst.l #0,d0>,ne	;�g�p�s��
		addq.w	#1,d3			;�����N���܂��͎g�p�\
		continue	<tst.b d1>,eq	;�N������SCSI-ID�ł͂Ȃ�
		break	<tst.b d0>,eq		;�N������SCSI-ID�Ŏ����N���̂Ƃ��I��
	next
	pop
	rts
    .endif

    .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����(�m�F�ς݂Ȃ�Ή������Ȃ�)
;>d0.l:�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����B0=����,-1=�Ȃ�
check_confliction_2nd:
	moveq.l	#-1,d0
	goto	<tst.b BIOS_SCSI_NOT_CONFLICT.w>,ne,check_confliction_end
    .endif
;----------------------------------------------------------------
;�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����m�F����
;>d0.l:�{�̂Ɠ���SCSI-ID�̋@�킪�Ȃ����B0=����,-1=�Ȃ�
check_confliction_1st:
    .if SCSI_BIOS_LEVEL<=3
	movem.l	d4,-(sp)
    .else
	move.l	d4,-(sp)
	st.b	BIOS_SCSI_NOT_CONFLICT.w
    .endif
	move.b	SRAM_SCSI_MODE,d4	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
	andi.b	#7,d4			;�{�̂�SCSI-ID
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_TESTUNIT,d1
	trap	#15
	move.l	(sp)+,d4
check_confliction_end:
	rts

    .if SCSI_BIOS_LEVEL==10
;----------------------------------------------------------------
;�u���b�N���ɉ����ău���b�N�ԍ��ƃu���b�N���𒲐�����
;<d2.l:�u���b�N�ԍ��B256�o�C�g/�u���b�N
;<d3.l:�u���b�N���B256�o�C�g/�u���b�N
;<d5.w:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;>d2.l:�u���b�N�ԍ�
;>d3.l:�u���b�N��
adjust_block_number:
	if	<cmpi.w #3,d5>,cs
		lsr.l	d5,d2
		lsr.l	d5,d3
		rts

	endif
	lsr.l	#2,d2
	lsr.l	#2,d3
	rts
    .endif
  .endif



;--------------------------------------------------------------------------------
;	.include	sc03break.s
;--------------------------------------------------------------------------------

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;TRAP#11(BREAK)
;	FD��HD�֘A��IOCS�R�[��($40�`$4F,$F5)�̏������łȂ���΃V�b�s���O���s��
;<d0.b:bit0:0=BREAK(CTRL+C),1=SHIFT+BREAK(CTRL+S)
trap_11_break:
	push	d0-d7/a0-a6
	if	<btst.l #0,d0>,eq	;BREAK�BSHIFT+BREAK�ł͂Ȃ�
		move.w	(BIOS_IOCS_NUMBER)abs,d0	;���s����IOCS�R�[���̔ԍ��B-1=�Ȃ�
		goto	<cmp.w #$0040,d0>,cs,do_eject_all
		ifand	<cmp.w #$0050,d0>,cc,<cmp.w #_SCSIDRV,d0>,ne
		do_eject_all:
			bsr	eject_all		;�V�b�s���O����
		endif
	endif
	pop
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;SASI�n�[�h�f�B�X�N�����@��SCSI�{�[�h�����t�����BREAK�L�[��SASI�n�[�h�f�B�X�N���V�b�s���O����@�\��������
;X68000 PRO[HD]�̎戵�������Ɂu�R���s���[�^�{�̂̓��쒆��[BREAK]�L�[���������Ƃ��ɂ��A���C�w�b�h�̑ޔ���Ƃ��s�����Ƃ��ł��܂��v�Ƃ����L�q������
;+++++ BUG +++++
	rte
    .else
	move.l	BIOS_SCSI_OLD_TRAP11.w,-(sp)	;TRAP#11(BREAK)�̌��̃x�N�^
	rts
    .endif
  .endif



;--------------------------------------------------------------------------------
;	.include	sc04eject.s
;--------------------------------------------------------------------------------

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;�V�b�s���O����
eject_all:
	move.w	#$8000,d1
	do
		bsr	iocs_4F_B_EJECT		;IOCS�R�[��$4F _B_EJECT
		add.w	#$0100,d1
	while	<cmp.w #$9000,d1>,cs
	rts
  .endif



;--------------------------------------------------------------------------------
;	.include	sc05iocs1.s
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;IOCS�R�[��$F5 _SCSIDRV
;<d1.l:SCSI�R�[���ԍ�
iocs_F5_SCSIDRV:
	push	d1/dLEN/aBUF/a2/aSPC
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.l #$00000010,d1>,cs,scsi_00_0F	;SCSI�R�[��$00�`$0F
	goto	<cmp.l #$00000020,d1>,cs,scsi_10_1F	;SCSI�R�[��$10�`$1F
	goto	<cmp.l #$00000040,d1>,cs,scsi_20_3F	;SCSI�R�[��$20�`$3F
;+++++ BUG +++++
;SCSI�R�[��$40�ȏ���w�肷���SCSI�R�[��$00�`$0F�̃W�����v�e�[�u������O��Ė\������
	goto	<cmp.l #$00000020,d1>,cs,scsi_10_1F
;�{����
;	goto	<cmp.l #$00000050,d1>,cs,scsi_40_4F	;SCSI�R�[��$40�`$4F
;	goto	scsi_10_1F		;SCSI�R�[��$50�`
;+++++ BUG +++++
  .else
	moveq.l	#$10,d0
	goto	<cmp.l d0,d1>,cs,scsi_00_0F	;SCSI�R�[��$00�`$0F
	add.l	d0,d0
	goto	<cmp.l d0,d1>,cs,scsi_10_1F	;SCSI�R�[��$10�`$1F
	add.l	d0,d0
	goto	<cmp.l d0,d1>,cs,scsi_20_3F	;SCSI�R�[��$20�`$3F
	moveq.l	#$50,d0
	goto	<cmp.l d0,d1>,cs,scsi_40_4F	;SCSI�R�[��$40�`$4F
	goto	scsi_10_1F		;SCSI�R�[��$50�`
  .endif

;SCSI�R�[��$00�`$0F
scsi_00_0F:
	lea.l	jump_00_0F(pc),a2	;SCSI�R�[��$00�`$0F�̃W�����v�e�[�u��
	goto	scsi_go

;SCSI�R�[��$20�`$3F
scsi_20_3F:
  .if SCSI_BIOS_LEVEL<=4
	sub.l	#$00000020,d1
  .else
	moveq.l	#$20,d0
	sub.l	d0,d1
  .endif
	lea.l	jump_20_3F(pc),a2	;SCSI�R�[��$20�`$3F�̃W�����v�e�[�u��
	goto	scsi_go

;SCSI�R�[��$40�`$4F
scsi_40_4F:
  .if SCSI_BIOS_LEVEL<=4
	sub.l	#$00000040,d1
  .else
	moveq.l	#$40,d0
	sub.l	d0,d1
  .endif
	lea.l	jump_40_4F(pc),a2	;SCSI�R�[��$40�`$4F�̃W�����v�e�[�u��
scsi_go:
	lsl.l	#2,d1
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_IN_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	move.l	(a2,d1.w),d1
	adda.l	d1,a2
	jsr	(a2)
	pop_test
	rts

;SCSI�R�[��$10�`$1F
;SCSI�R�[��$50�`
scsi_10_1F:
	moveq.l	#-1,d0
	pop
	rts

;����`��SCSI�R�[��
scsi_XX_undefined:
	moveq.l	#-1,d0
	rts

;SCSI�R�[��$00�`$0F�̃W�����v�e�[�u��
jump_00_0F:
	.dc.l	scsi_00_S_RESET-jump_00_0F	;SCSI�R�[��$00 _S_RESET
	.dc.l	scsi_01_S_SELECT-jump_00_0F	;SCSI�R�[��$01 _S_SELECT
	.dc.l	scsi_02_S_SELECTA-jump_00_0F	;SCSI�R�[��$02 _S_SELECTA
	.dc.l	scsi_03_S_CMDOUT-jump_00_0F	;SCSI�R�[��$03 _S_CMDOUT
	.dc.l	scsi_04_S_DATAIN-jump_00_0F	;SCSI�R�[��$04 _S_DATAIN
	.dc.l	scsi_05_S_DATAOUT-jump_00_0F	;SCSI�R�[��$05 _S_DATAOUT
	.dc.l	scsi_06_S_STSIN-jump_00_0F	;SCSI�R�[��$06 _S_STSIN
	.dc.l	scsi_07_S_MSGIN-jump_00_0F	;SCSI�R�[��$07 _S_MSGIN
	.dc.l	scsi_08_S_MSGOUT-jump_00_0F	;SCSI�R�[��$08 _S_MSGOUT
	.dc.l	scsi_09_S_PHASE-jump_00_0F	;SCSI�R�[��$09 _S_PHASE
	.dc.l	scsi_0A_S_LEVEL-jump_00_0F	;SCSI�R�[��$0A _S_LEVEL
	.dc.l	scsi_0B_S_DATAINI-jump_00_0F	;SCSI�R�[��$0B _S_DATAINI
	.dc.l	scsi_0C_S_DATAOUTI-jump_00_0F	;SCSI�R�[��$0C _S_DATAOUTI
  .if SCSI_BIOS_LEVEL<=4
	.dc.l	scsi_XX_undefined-jump_00_0F	;SCSI�R�[��$0D _S_MSGOUTEXT
  .else
	.dc.l	scsi_0D_S_MSGOUTEXT-jump_00_0F	;SCSI�R�[��$0D _S_MSGOUTEXT
  .endif
	.dc.l	scsi_XX_undefined-jump_00_0F	;SCSI�R�[��$0E
	.dc.l	scsi_XX_undefined-jump_00_0F	;SCSI�R�[��$0F

;SCSI�R�[��$20�`$3F�̃W�����v�e�[�u��
jump_20_3F:
	.dc.l	scsi_20_S_INQUIRY-jump_20_3F	;SCSI�R�[��$20 _S_INQUIRY
	.dc.l	scsi_21_S_READ-jump_20_3F	;SCSI�R�[��$21 _S_READ
	.dc.l	scsi_22_S_WRITE-jump_20_3F	;SCSI�R�[��$22 _S_WRITE
	.dc.l	scsi_23_S_FORMAT-jump_20_3F	;SCSI�R�[��$23 _S_FORMAT
	.dc.l	scsi_24_S_TESTUNIT-jump_20_3F	;SCSI�R�[��$24 _S_TESTUNIT
	.dc.l	scsi_25_S_READCAP-jump_20_3F	;SCSI�R�[��$25 _S_READCAP
	.dc.l	scsi_26_S_READEXT-jump_20_3F	;SCSI�R�[��$26 _S_READEXT
	.dc.l	scsi_27_S_WRITEEXT-jump_20_3F	;SCSI�R�[��$27 _S_WRITEEXT
	.dc.l	scsi_28_S_VERIFYEXT-jump_20_3F	;SCSI�R�[��$28 _S_VERIFYEXT
	.dc.l	scsi_29_S_MODESENSE-jump_20_3F	;SCSI�R�[��$29 _S_MODESENSE
	.dc.l	scsi_2A_S_MODESELECT-jump_20_3F	;SCSI�R�[��$2A _S_MODESELECT
	.dc.l	scsi_2B_S_REZEROUNIT-jump_20_3F	;SCSI�R�[��$2B _S_REZEROUNIT
	.dc.l	scsi_2C_S_REQUEST-jump_20_3F	;SCSI�R�[��$2C _S_REQUEST
	.dc.l	scsi_2D_S_SEEK-jump_20_3F	;SCSI�R�[��$2D _S_SEEK
	.dc.l	scsi_2E_S_READI-jump_20_3F	;SCSI�R�[��$2E _S_READI
	.dc.l	scsi_2F_S_STARTSTOP-jump_20_3F	;SCSI�R�[��$2F _S_STARTSTOP
	.dc.l	scsi_30_S_SEJECT-jump_20_3F	;SCSI�R�[��$30 _S_SEJECT
	.dc.l	scsi_31_S_REASSIGN-jump_20_3F	;SCSI�R�[��$31 _S_REASSIGN
	.dc.l	scsi_32_S_PAMEDIUM-jump_20_3F	;SCSI�R�[��$32 _S_PAMEDIUM
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$33
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$34
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$35
	.dc.l	scsi_36_S_DSKINI-jump_20_3F	;SCSI�R�[��$36 _S_DSKINI
	.dc.l	scsi_37_S_FORMATB-jump_20_3F	;SCSI�R�[��$37 _S_FORMATB
	.dc.l	scsi_38_S_BADFMT-jump_20_3F	;SCSI�R�[��$38 _S_BADFMT
	.dc.l	scsi_39_S_ASSIGN-jump_20_3F	;SCSI�R�[��$39 _S_ASSIGN
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$3A
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$3B
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$3C
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$3D
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$3E
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSI�R�[��$3F

;SCSI�R�[��$40�`$4F�̃W�����v�e�[�u��
jump_40_4F:
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$40
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$41
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$42
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$43
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$44
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$45
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$46
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$47
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$48
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$49
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$4A
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$4B
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$4C
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$4D
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$4E
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSI�R�[��$4F



;--------------------------------------------------------------------------------
;	.include	sc06iocs2.s
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;SCSI�R�[��$00 _S_RESET SPC�̏�������SCSI�o�X���Z�b�g
scsi_00_S_RESET:
	push	d1/a1/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;�n�[�h�E�F�A���Z�b�g���J�n����
	move.b	#SPC_SCTL_RD|SPC_SCTL_AE,SPC_SCTL(aSPC)	;�A�[�r�g���[�V�����t�F�[�Y����(SCSI)
  .if 10<=SCSI_BIOS_LEVEL
	sf.b	BIOS_SCSI_NOT_CONFLICT.w	;SCSI-ID�Փˊm�F�B$00=���m�F,$FF=�m�F�ς�
  .endif
;SRAM������������
	move.b	SRAM_SCSI_MAGIC,d0	;SCSI�}�W�b�N�B'V'($56)=�������ς�
	if	<cmpi.b #'V',d0>,ne	;SRAM��������
		move.b	#$31,SYSPORT_SRAM	;SRAM�������ݐ���B$31=����,���̑�=�֎~
  .if (SCSI_BIOS_LEVEL<=0)|(10<=SCSI_BIOS_LEVEL)
    .if SCSIEXROM
		move.b	#$0F,SRAM_SCSI_MODE	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
    .else
		move.b	#$07,SRAM_SCSI_MODE	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
    .endif
  .else
		if	<cmpa.l #SPC_IN_BASE,aSPC>,eq	;����
			move.b	#$07,SRAM_SCSI_MODE	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
		else				;�g��
			move.b	#$0F,SRAM_SCSI_MODE	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
		endif
  .endif
		move.b	#$00,SRAM_SCSI_SASI_FLAG	;SASI�t���O
		move.b	#'V',SRAM_SCSI_MAGIC	;SCSI�}�W�b�N�B'V'($56)=�������ς�
		move.b	#$00,SYSPORT_SRAM	;SRAM�������ݐ���B$31=����,���̑�=�֎~
	endif
;SRAM�������ς�
;�{�̂�SCSI-ID��ݒ肷��
	move.b	SRAM_SCSI_MODE,d0	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
	andi.b	#7,d0			;�{�̂�SCSI-ID
	move.b	d0,SPC_BDID(aSPC)
;SPC�̃��W�X�^���N���A����
	moveq.l	#0,d0
	move.b	d0,SPC_SCMD(aSPC)
	move.b	d0,SPC_PCTL(aSPC)
	move.b	d0,SPC_TCH(aSPC)
	move.b	d0,SPC_TCM(aSPC)
	move.b	d0,SPC_TCL(aSPC)
	move.b	d0,SPC_TEMP(aSPC)
  .if 10<=SCSI_BIOS_LEVEL
	move.b	#$00,SPC_SDGC(aSPC)
	move.w	#512,BIOS_SCSI_BLOCK_SIZE.w	;SCSI�@��̃u���b�N�T�C�Y
  .endif
;SPC���荞�݂�ݒ肷��
  .if SCSI_BIOS_LEVEL<=4
	moveq.l	#_B_INTVCS,d0
    .if SCSI_BIOS_LEVEL<=0
	moveq.l	#OFFSET_SPC_IN/4,d1	;����SPC���荞�݃x�N�^
    .else
	if	<cmpa.l #SPC_IN_BASE,aSPC>,eq	;����
		moveq.l	#OFFSET_SPC_IN/4,d1	;����SPC���荞�݃x�N�^
	else				;�g��
		move.l	#OFFSET_SPC_EX/4,d1	;�g��SPC���荞�݃x�N�^
	endif
    .endif
	lea.l	spc_interrupt_routine(pc),a1	;SPC���荞�݃��[�`��
	trap	#15
  .else
    .if SCSIEXROM
	moveq.l	#OFFSET_SPC_EX/4,d1	;�g��SPC���荞�݃x�N�^
    .else
	moveq.l	#OFFSET_SPC_IN/4,d1	;����SPC���荞�݃x�N�^
    .endif
	lea.l	spc_interrupt_routine(pc),a1	;SPC���荞�݃��[�`��
	IOCS	_B_INTVCS
  .endif
;�n�[�h�E�F�A���Z�b�g���I������
	move.b	#SPC_SCTL_AE,SPC_SCTL(aSPC)	;�A�[�r�g���[�V�����t�F�[�Y����(SCSI)
  .if SCSI_BIOS_LEVEL<=4
	move.b	#$00,SPC_SDGC(aSPC)
  .endif
  .if SCSI_BIOS_LEVEL<=3
	move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
	move.w	#81-1,d0		;97.2us@10MHz
    .else
	move.w	#129-1,d0		;154.8us@10MHz
    .endif
	for	d0
	next
	move.w	(sp)+,d0
  .endif
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#100/50,d0		;100us
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
  .endif
;SCSI�o�X���Z�b�g���J�n����
	move.b	#SPC_SCMD_RO,SPC_SCMD(aSPC)
  .if SCSI_BIOS_LEVEL<=3
	move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
	move.w	#201-1,d0		;241.2us@10MHz
    .else
	move.w	BIOS_MPU_SPEED_ROM.l,d0	;MPU�N���b�N�BX68000��10MHz*250/3=833�AX68030��25MHz*500/3=4167�B1ms�Ԃ�dbra�̋󃋁[�v�������邩
	lsr.w	#2,d0			;250us
    .endif
	for	d0
	next
	move.w	(sp)+,d0
  .endif
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#250/50,d0		;250us
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
  .endif
;SCSI�o�X���Z�b�g���I������
	move.b	#$00,SPC_SCMD(aSPC)
  .if SCSI_BIOS_LEVEL<=3
	move.w	#2000/10,d0		;2s
	for	d0
		move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
		move.w	#1000*10,d0		;10ms
    .else
		move.w	BIOS_MPU_SPEED_ROM.l,d0	;MPU�N���b�N�BX68000��10MHz*250/3=833�AX68030��25MHz*500/3=4167�B1ms�Ԃ�dbra�̋󃋁[�v�������邩
		mulu.w	#10,d0			;10ms
    .endif
		for	d0
		next
		move.w	(sp)+,d0
	next
  .else
	move.l	#2000000/50,d0		;2s
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
  .endif
  .if 16<=SCSI_BIOS_LEVEL
;SCSI�������ς݃t���O���Z�b�g����
    .if SCSIEXROM
	bset.b	#1,BIOS_SCSI_INITIALIZED.w
    .else
	bset.b	#0,BIOS_SCSI_INITIALIZED.w
    .endif
  .endif
	pop
	rts

;----------------------------------------------------------------
;SPC���荞�݃��[�`��
spc_interrupt_routine:
	push	d0/d1/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	move.b	SPC_INTS(aSPC),d0
	move.b	d0,SPC_INTS(aSPC)	;INTS���N���A
	pop
	rte

;----------------------------------------------------------------
;SCSI�R�[��$02 _S_SELECTA
;	�A�[�r�g���[�V�����t�F�[�Y�ƃZ���N�V�����t�F�[�Y(���b�Z�[�W�A�E�g�t�F�[�Y����)
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:�I���R�[�h�B0=����I��,���̑�=(INTS<<16)|PSNS
scsi_02_S_SELECTA:
  .if SCSI_BIOS_LEVEL<=4
ints	reg	SPC_INTS(aSPC)
	push	dID/d7/aSPC
  .else
aINTS	reg	a0
ints	reg	(a0)
	push	dID/d7/aINTS/aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	SPC_INTS(aSPC),aINTS
  .endif
	move.b	#SPC_PCTL_SR_S,SPC_PCTL(aSPC)	;Select�R�}���h�̓Z���N�V����
;���݂̃R�}���h���I������܂ő҂�
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP|SPC_SSTS_SRIN,d0
	while	ne
  .if 10<=SCSI_BIOS_LEVEL
	move.b	ints,ints		;INTS���N���A
  .endif
	move.b	#SPC_SCMD_CC_SA,SPC_SCMD(aSPC)	;Set ATN
  .if SCSI_BIOS_LEVEL<=0
	jmp	select_common		;��������_S_SELECT�A_S_SELECTA����
  .else
	goto	select_common		;��������_S_SELECT�A_S_SELECTA����
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$01 _S_SELECT
;	�A�[�r�g���[�V�����t�F�[�Y�ƃZ���N�V�����t�F�[�Y(���b�Z�[�W�A�E�g�t�F�[�Y�Ȃ�)
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:�I���R�[�h�B0=����I��,���̑�=(INTS<<16)|PSNS
scsi_01_S_SELECT:
	push_again
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	SPC_INTS(aSPC),aINTS
  .endif
	move.b	#SPC_PCTL_SR_S,SPC_PCTL(aSPC)	;Select�R�}���h�̓Z���N�V����
;���݂̃R�}���h���I������܂ő҂�
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP|SPC_SSTS_SRIN,d0
	while	ne
;��������_S_SELECT�A_S_SELECTA����
select_common:
	andi.w	#7,dID			;�^�[�Q�b�g��SCSI-ID
  .if SCSI_BIOS_LEVEL<=4
	move.b	#1,d0
  .else
	moveq.l	#1,d0
  .endif
	lsl.b	dID,d0
	if	<btst.b dID,SRAM_SCSI_SASI_FLAG>,eq	;SCSI�@��
		or.b	SPC_BDID(aSPC),d0	;�^�[�Q�b�g��SCSI-ID�Ɩ{�̂�SCSI-ID�����킹��
  .if SCSI_BIOS_LEVEL<=4
		move.b	#SPC_SCTL_AE,SPC_SCTL(aSPC)	;�A�[�r�g���[�V�����t�F�[�Y����(SCSI)
  .else
		bset.b	#SPC_SCTL_AE_BIT,SPC_SCTL(aSPC)	;�A�[�r�g���[�V�����t�F�[�Y����(SCSI)
  .endif
	else				;SASI�@��
  .if SCSI_BIOS_LEVEL<=4
		move.b	#$00,SPC_SCTL(aSPC)	;�A�[�r�g���[�V�����t�F�[�Y�Ȃ�(SASI)
  .else
		bclr.b	#SPC_SCTL_AE_BIT,SPC_SCTL(aSPC)	;�A�[�r�g���[�V�����t�F�[�Y�Ȃ�(SASI)
  .endif
	endif
;�����҂����ԂƃA�[�r�g���[�V�����J�n�x�����Ԃ�ݒ肷��
;	�����҂�����
;		(9*65536+196*256+15)*200ns*2=256.006us
;	�A�[�r�g���[�V�����J�n�x������
;		(3+6)*200ns�`(3+7)*200ns=1.8us�`2us
  .if (SCSI_BIOS_LEVEL<=4)|(16<=SCSI_BIOS_LEVEL)
	move.b	d0,SPC_TEMP(aSPC)	;�^�[�Q�b�g��SCSI-ID�Ǝ�����SCSI-ID�����킹������
	move.w	#(9<<8)|196,d0
	move.b	d0,SPC_TCM(aSPC)	;196
	lsr.w	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;9
	move.b	#3,SPC_TCL(aSPC)	;3
  .else
	swap.w	d0			;mask<<16
	move.w	#(9<<8)|196,d0		;(mask<<16)|(9<<8)|196
	lsl.l	#8,d0			;(mask<<24)|(9<<16)|(196<<8)
	move.b	#3,d0			;(mask<<24)|(9<<16)|(196<<8)|3
	movep.l	d0,SPC_TEMP(aSPC)	;�^�[�Q�b�g��SCSI-ID�Ǝ�����SCSI-ID�����킹������
					;9
					;196
					;3
  .endif
	move.b	ints,ints		;INTS���N���A
;�Z���N�V�����J�n
	move.b	#SPC_SCMD_CC_SL,SPC_SCMD(aSPC)
  .if SCSI_BIOS_LEVEL<=3
	move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
	move.w	#13-1,d0		;15.6us@10MHz
    .else
	move.w	#25-1,d0		;30us@10MHz
    .endif
	for	d0
	next
	move.w	(sp)+,d0
  .endif
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#50/50,d0		;50us
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
  .endif
  .if SCSI_BIOS_LEVEL<=3
	move.b	SPC_INTS(aSPC),d0
	if	eq
		move.b	SPC_SSTS(aSPC),d0
		goto	<btst.l #SPC_SSTS_INIT_BIT,d0>,eq,select_common	;�C�j�V�G�[�^�ɂȂ��Ă��Ȃ��B�Z���N�V�������s�B�A�[�r�g���[�V���������蒼��
	endif
  .elif SCSI_BIOS_LEVEL==4
;���荞�݂�҂�
	do
		move.b	ints,d0
		break	ne				;���荞�݂���
	;+++++ BUG +++++
	;BUSY=0�ł��~�܂�悤�ɂ����������悤����btst.b��move.b�ɂȂ��Ă���
	;SSTS�̃r�b�g5���e�X�g��������SSTS��5����������ł���
	;���ne�Ȃ̂�BUSY=0�ł͎~�܂�Ȃ�
	;���[�v�̏o��������1����̂Ŗ������[�v�ɂȂ炸�ɍς�ł���
		move.b	#SPC_SSTS_BUSY_BIT,SPC_SSTS(aSPC)
	;+++++ BUG +++++
	while	ne
  .else
;BUSY=0�܂��͊��荞�݂�҂�
	do
		move.b	ints,d0
		break	ne				;���荞�݂���
		redo	<btst.b #SPC_SSTS_BUSY_BIT,SPC_SSTS(aSPC)>,ne
		goto	<tst.b SPC_SSTS(aSPC)>,pl,select_common	;SPC_SSTS_INIT_BIT
								;BUSY=0�����C�j�V�G�[�^�ɂȂ��Ă��Ȃ��B�Z���N�V�������s�B�A�[�r�g���[�V���������蒼��
	while	f
  .endif
;���荞�݂�҂�
	do
  .if SCSI_BIOS_LEVEL==4
		move.b	SPC_SSTS(aSPC),d0
		goto	<btst.l #SPC_SSTS_INIT_BIT,d0>,eq,select_common	;�C�j�V�G�[�^�ɂȂ��Ă��Ȃ��B�Z���N�V�������s�B�A�[�r�g���[�V���������蒼��
  .endif
		move.b	ints,d0
	while	eq
	goto	<cmp.b #SPC_INTS_TO,d0>,eq,selection_timeout	;�Z���N�V�����^�C���A�E�g
  .if SCSI_BIOS_LEVEL<=4
	move.b	d0,ints			;INTS���N���A
  .else
	move.b	ints,ints		;INTS���N���A
  .endif
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,selection_no_error	;�R�}���h�I���B�Z���N�V��������I��
;�Z���N�V�����G���[�I��
selection_error:
	swap.w	d0
	move.b	SPC_PSNS(aSPC),d0
;�Z���N�V�����I��
selection_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;�Z���N�V��������I��
selection_no_error:
	moveq.l	#0,d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	selection_end		;�Z���N�V�����I��
  .endif

  .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;�ǂ�������Q�Ƃ���Ă��Ȃ�
	moveq.l	#-1,d0
    .if SCSI_BIOS_LEVEL<=4
	pop
	rts
    .else
	goto	selection_end		;�Z���N�V�����I��
    .endif
;+++++ BUG +++++
  .endif

;�Z���N�V�����^�C���A�E�g
;	�Z���N�V���������҂��Ď�����
;		((0<<16)|(2<<8)|88)*200ns*2=240us
selection_timeout:
  .if SCSI_BIOS_LEVEL==4
	moveq.l	#50/50,d0
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
  .endif
  .if (SCSI_BIOS_LEVEL<=4)|(16<=SCSI_BIOS_LEVEL)
	move.b	#0,SPC_TEMP(aSPC)	;0
	move.l	#(0<<16)|(2<<8)|88,d0
	move.b	d0,SPC_TCL(aSPC)	;88
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;2
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;0
  .else
	move.l	#(0<<16)|(2<<8)|88,d0
	movep.l	d0,SPC_TEMP(aSPC)	;0
					;0
					;2
					;88
  .endif
	move.b	#SPC_INTS_TO,ints	;�^�C���A�E�g���N���A
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#100/50,d0		;100us
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
  .endif
;���荞�݂�҂�
	do
		move.b	ints,d0
	while	eq
  .if SCSI_BIOS_LEVEL<=4
	move.b	d0,ints			;INTS���N���A
  .else
	move.b	ints,ints		;INTS���N���A
  .endif
	goto	<cmp.b #SPC_INTS_TO,d0>,eq,selection_timeout_2nd	;�Z���N�V�����^�C���A�E�g(2���)
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,selection_no_error	;�R�}���h�I���B�Z���N�V��������I��
;�R�}���h�I���ł͂Ȃ�
	goto	selection_error		;�Z���N�V�����G���[�I��

;�Z���N�V�����^�C���A�E�g(2���)
selection_timeout_2nd:
;BUSY=0��҂�
	do
		btst.b	#SPC_SSTS_BUSY_BIT,SPC_SSTS(aSPC)
	while	ne
	move.b	ints,ints		;INTS���N���A
  .if SCSI_BIOS_LEVEL<=4
	goto	<btst.b #SPC_SSTS_INIT_BIT,SPC_SSTS(aSPC)>,ne,selection_no_error	;�C�j�V�G�[�^�B�Z���N�V��������I��
  .else
	goto	<tst.b SPC_SSTS(aSPC)>,mi,selection_no_error	;SPC_SSTS_INIT_BIT
								;�C�j�V�G�[�^�B�Z���N�V��������I��
  .endif
;�C�j�V�G�[�^�ł͂Ȃ�
	goto	selection_error		;�Z���N�V�����G���[�I��

;----------------------------------------------------------------
;SCSI�R�[��$03 _S_CMDOUT
;	�R�}���h�A�E�g�t�F�[�Y
;<dLEN.l:�R�}���h�̒����B�O���[�v0,1,5�͕s�v�B�O���[�v0��6�o�C�g�A�O���[�v1��10�o�C�g�A�O���[�v5��12�o�C�g
;<a1.l:�R�}���h�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_03_S_CMDOUT:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	move.b	(a1),d0
	andi.b	#7<<5,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.b #0.shl.5,d0>,eq,cmdout_group_0	;�O���[�v0($00-$1F)
  .else
	goto	eq,cmdout_group_0	;�O���[�v0($00-$1F)
  .endif
	goto	<cmp.b #1.shl.5,d0>,eq,cmdout_group_1	;�O���[�v1($20-$3F)
	goto	<cmp.b #5.shl.5,d0>,eq,cmdout_group_5	;�O���[�v5($A0-$BF)
	goto	cmdout_go

;�O���[�v0($00-$1F)
cmdout_group_0:
	moveq.l	#6,dLEN			;�O���[�v0�̃R�}���h��6�o�C�g
	goto	cmdout_go

;�O���[�v1($20-$3F)
cmdout_group_1:
	moveq.l	#10,dLEN		;�O���[�v1�̃R�}���h��10�o�C�g
	goto	cmdout_go

;�O���[�v5($A0-$BF)
cmdout_group_5:
	moveq.l	#12,dLEN		;�O���[�v5�̃R�}���h��12�o�C�g
cmdout_go:
;REQ=1��҂�
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,cmdout_disconnected	;�ؒf
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,cmdout_disconnected	;�ؒf
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0
	goto	<cmpi.b #SPC_CMDOUT_PHASE,d0>,ne,cmdout_error	;�R�}���h�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
	bsr	dataout_cpu		;CPU�]���ŏo�͂���
	swap.w	d0
	goto	ne,cmdout_error		;�]�����s�B�G���[�I��
cmdout_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;�G���[�I��
cmdout_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	cmdout_end
  .endif

;�ؒf
cmdout_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	cmdout_end
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$0C _S_DATAOUTI
;	�f�[�^�A�E�g�t�F�[�Y(�\�t�g�]��)
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_0C_S_DATAOUTI:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1��҂�
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,dataouti_disconnected	;�ؒf
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataouti_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0	;SPC_DATAOUT_PHASE
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAOUT_PHASE,d0>,ne,dataouti_error	;�f�[�^�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	ne,dataouti_error	;�f�[�^�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
	bsr	dataouti_transfer	;SCSI�o��(�\�t�g�]��)
	swap.w	d0
	goto	ne,dataouti_error	;�]�����s�B�G���[�I��
dataouti_end:
  .if SCSI_BIOS_LEVEL<=4
	popm_test
  .elif SCSI_BIOS_LEVEL<=10
	popm
  .else
	pop
  .endif
	rts

;�G���[�I��
dataouti_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	dataouti_end
  .endif

;�ؒf
dataouti_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	dataouti_end
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$0B _S_DATAINI
;	�f�[�^�C���t�F�[�Y(�\�t�g�]��)
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_0B_S_DATAINI:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1��҂�
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,dataini_disconnected	;�ؒf
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataini_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAIN_PHASE,d0>,ne,dataini_error	;�f�[�^�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	<cmpi.b #SPC_DATAIN_PHASE,d0>,ne,dataini_error	;�f�[�^�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
	bsr	dataini_transfer	;SCSI����(�\�t�g�]��)
	swap.w	d0
	goto	ne,dataini_error	;�]�����s�B�G���[�I��
dataini_end:
  .if SCSI_BIOS_LEVEL<=4
	popm_test
  .elif SCSI_BIOS_LEVEL<=10
	popm
  .else
	pop
  .endif
	rts

;�G���[�I��
dataini_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	dataini_end
  .endif

;�ؒf
dataini_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	dataini_end
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$06 _S_STSIN
;	�X�e�[�^�X�C���t�F�[�Y
;	�X�e�[�^�X�o�C�g
;		$00 --00000-	Good
;		$02 --00001-	Check Condition
;		$04 --00010-	Condition Met
;		$08 --00100-	Busy
;		$10 --01000-	Intermediate
;		$14 --01010-	Intermediate-Condition Met
;		$18 --01100-	Reservation Conflict
;		$22 --10001-	Command Terminated
;		$28 --10100-	Queue Full
;		���̑�		���U�[�u
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_06_S_STSIN:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1��҂�
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,stsin_disconnected	;�ؒf
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,stsin_disconnected	;�ؒf
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_STSIN_PHASE,d0>,ne,stsin_error	;�X�e�[�^�X�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	<cmpi.b #SPC_STSIN_PHASE,d0>,ne,stsin_error	;�X�e�[�^�X�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
;�]������
	moveq.l	#1,dLEN			;�f�[�^�̒���
	bsr	datain_cpu		;CPU�]���œ��͂���
	swap.w	d0
	goto	ne,stsin_error		;�]�����s�B�G���[�I��
stsin_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;�G���[�I��
stsin_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	stsin_end
  .endif

;�ؒf
stsin_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	stsin_end
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$07 _S_MSGIN
;	���b�Z�[�W�C���t�F�[�Y
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_07_S_MSGIN:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	moveq.l	#1,dLEN			;�f�[�^�̒���
  .endif
;REQ=1��҂�
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,msgin_disconnected	;�ؒf
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,msgin_disconnected	;�ؒf
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_MSGIN_PHASE,d0>,ne,msgin_error	;���b�Z�[�W�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	<cmpi.b #SPC_MSGIN_PHASE,d0>,ne,msgin_error	;���b�Z�[�W�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
;�]������
  .if SCSI_BIOS_LEVEL<=4
	moveq.l	#1,dLEN			;�f�[�^�̒���
  .endif
	bsr	datain_cpu		;CPU�]���œ��͂���
	swap.w	d0
	goto	ne,msgin_error	;�]�����s�B�G���[�I��
msgin_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;�G���[�I��
msgin_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	msgin_end
  .endif

;�ؒf
msgin_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	msgin_end
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$08 _S_MSGOUT
;	���b�Z�[�W�A�E�g�t�F�[�Y
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_08_S_MSGOUT:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	moveq.l	#1,dLEN			;�f�[�^�̒���
  .endif
;��������_S_MSGOUT�A_S_MSGOUTEXT����
msgout_common:
;REQ=1��҂�
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,msgout_disconnected	;�ؒf
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,msgout_disconnected	;�ؒf
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_MSGOUT_PHASE,d0>,ne,msgout_error	;���b�Z�[�W�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	<cmpi.b #SPC_MSGOUT_PHASE,d0>,ne,msgout_error	;���b�Z�[�W�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
;�]������
  .if SCSI_BIOS_LEVEL<=4
	moveq.l	#1,dLEN			;�f�[�^�̒���
  .endif
	bsr	dataouti_transfer	;SCSI�o��(�\�t�g�]��)
	swap.w	d0
	goto	ne,msgout_error
msgout_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;�G���[�I��
msgout_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	msgout_end
  .endif

;�ؒf
msgout_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	msgout_end
  .endif

  .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;SCSI�R�[��$0D _S_MSGOUTEXT
;	�g�����b�Z�[�W�A�E�g�t�F�[�Y
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,-1=�ؒf,���̑�=(INTS<<16)|PSNS
scsi_0D_S_MSGOUTEXT:
	push	dLEN/aSPC
	movea.l	spc_base_handle(pc),aSPC	;SPC�x�[�X�n���h��
	move.b	2(aBUF),d0
	goto	eq,msgoutext_0
	subq.b	#2,d0
	goto	cs,msgoutext_1
	goto	eq,msgoutext_2
	subq.b	#1,d0
	goto	eq,msgoutext_2
	goto	msgout_common		;��������_S_MSGOUT�A_S_MSGOUTEXT����

msgoutext_0:
	moveq.l	#5,dLEN
	goto	msgoutext_go

msgoutext_1:
	moveq.l	#3,dLEN
	goto	msgoutext_go

msgoutext_2:
	moveq.l	#2,dLEN
msgoutext_go:
	move.b	#1,(aBUF)
	move.b	dLEN,1(aBUF)
	addq.l	#2,dLEN
	goto	msgout_common		;��������_S_MSGOUT�A_S_MSGOUTEXT����
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$09 _S_PHASE
;	�t�F�[�Y�Z���X
;>d0.l:���݂̃t�F�[�Y
scsi_09_S_PHASE:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,a6
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	moveq.l	#0,d0
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=10
	popm
  .else
	pop
  .endif
	rts

;----------------------------------------------------------------
;SCSI�R�[��$0A _S_LEVEL
;	�o�[�W����
;	�o�[�W������3�ȉ��̂Ƃ�FORMAT.X��SCSI�n�[�h�f�B�X�N�ɏ�������SCSI�f�o�C�X�h���C�o���o�[�W����4�ɍ����ւ���
;>d0.l:�o�[�W����
scsi_0A_S_LEVEL:
	moveq.l	#SCSI_BIOS_LEVEL,d0
	rts


  .if SCSI_BIOS_LEVEL<=4


;----------------------------------------------------------------
;SCSI�o��(�\�t�g�]��)
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataouti_transfer:
	push	dLEN/aBUF
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1��҂�
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;�]���J�n
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;�C�j�V�G�[�^�œ]������҂�
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;�^�[�Q�b�g�œ]�����H
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne
;1�o�C�g���]������
	do
		break	<tst.b SPC_INTS(aSPC)>,ne	;���荞�݂���
		redo	<btst.b #SPC_SSTS_DF_BIT,SPC_SSTS(aSPC)>,ne	;FIFO���t���łȂ��Ȃ�܂ő҂�
		move.b	(aBUF)+,SPC_DREG(aSPC)
		subq.l	#1,dLEN
	while	ne
;���荞�݂�҂�
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	d0,SPC_INTS(aSPC)	;INTS���N���A
	if	<cmp.b #SPC_INTS_CC,d0>,ne
		pop_test
		rts

	endif
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;SCSI����(�\�t�g�]��)
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataini_transfer:
	push	dLEN/aBUF
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
;�]���J�n
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;�C�j�V�G�[�^�œ]������҂�
dataini_wait:
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;�^�[�Q�b�g�œ]�����H
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne
;1�o�C�g���]������
dataini_loop:
;+++++ BUG +++++
;Service Required�ɑΉ����Ă��Ȃ�
;	�Ō�̃f�[�^�𑗐M������AACK��False�ɂȂ�̂�҂����ɃX�e�[�^�X�C���t�F�[�Y�Ɉڍs���Ă��܂��n�[�h�f�B�X�N������炵��
;	�Ō�̃f�[�^��FIFO������o���I���܂Ŗ{�̂̓f�[�^�C���t�F�[�Y�Ȃ̂ŁA
;	�t�F�[�Y�̕s��v�Ŋ��荞�ݗv����Service Required���Z�b�g�����\��������
;	Service Required���Z�b�g�����Ɠ]�������f���Ă��܂��AFIFO�Ɏc���Ă����Ō�̃f�[�^���󂯎�葹�˂�\��������
;+++++ BUG +++++
	do
	;FIFO����łȂ��Ȃ�܂ő҂�
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataini_interrupted	;���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;FIFO����1�o�C�g�ǂݍ���
		move.b	SPC_DREG(aSPC),(aBUF)+
		subq.l	#1,dLEN
	while	ne
dataini_interrupted:
;���荞�݂�҂�
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	d0,SPC_INTS(aSPC)	;INTS���N���A
	if	<cmp.b #SPC_INTS_CC,d0>,ne
		pop_test
		rts

	endif
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;CPU�]���ŏo�͂���
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0
dataout_cpu:
	push	dLEN/aBUF
dataout_cpu_loop:
	do
	;�t�F�[�Y���Z�b�g����
		move.b	SPC_PSNS(aSPC),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1��҂�
	dataout_cpu_wait_1:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
	;1�o�C�g�o�͂���
		move.b	(aBUF)+,SPC_TEMP(aSPC)
		move.b	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Set ACK
	;REQ=0��҂�
	dataout_cpu_wait_2:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,ne
		move.b	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
dataout_cpu_end:
	pop
	rts

;----------------------------------------------------------------
;CPU�]���œ��͂���
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0
datain_cpu:
	push	dLEN/aBUF
datain_cpu_loop:
	do
	;�t�F�[�Y���Z�b�g����
		move.b	SPC_PSNS(aSPC),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1��҂�
	datain_cpu_wait_1:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
		move.b	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Set ACK
	;REQ=0��҂�
	datain_cpu_wait_2:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,ne
	;1�o�C�g���͂���
		move.b	SPC_TEMP(aSPC),(aBUF)+
		move.b	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
	pop
	rts


  .else


;----------------------------------------------------------------
;SCSI�o��(�\�t�g�]��)
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataouti_transfer:
aINTS	reg	a2
aSSTS	reg	a3
aDREG	reg	a4
	push	d1/d2/dLEN/dID/aBUF/aINTS/aSSTS/aDREG
	lea.l	SPC_INTS(aSPC),aINTS
	lea.l	SPC_SSTS(aSPC),aSSTS
	lea.l	SPC_DREG(aSPC),aDREG
;������0�̂Ƃ�256�ƌ��Ȃ�
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;�������Z�b�g����
    .if SCSI_BIOS_LEVEL<=10
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
    .else
	move.b	#0,SPC_TEMP(aSPC)
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
    .endif
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1��҂�
	do
	while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
;�]���J�n
	move.b	(aINTS),(aINTS)		;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;�C�j�V�G�[�^�œ]������҂�
	do
		move.b	(aSSTS),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
    .if SCSI_BIOS_LEVEL<=10
	;+++++ BUG +++++
	;�^�[�Q�b�g�̂Ƃ����[�v�J�E���^��d2��ݒ肹���Ƀ��[�v�ɔ�э���ł���
		goto	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq,dataouti_target	;�^�[�Q�b�g�œ]�����H
	;+++++ BUG +++++
    .else
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;�^�[�Q�b�g�œ]�����H
    .endif
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne	;�C�j�V�G�[�^�œ]������҂�

    .if SCSI_BIOS_LEVEL<=10

;�C�j�V�G�[�^�œ]����
	move.l	dLEN,d0
	lsr.l	#3,d0			;����/8
	goto	eq,dataouti_less_than_8	;8�o�C�g����
;8�o�C�g�ȏ�
;<d0.l:����/8
	move.l	d0,d2
dataouti_target:
;8�o�C�g���]������
	do
	;FIFO����ɂȂ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,dataouti_finish	;���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,eq	;FIFO����ɂȂ�܂ő҂�
	;FIFO��8�o�C�g��������
	;+++++ BUG +++++
	;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
	;+++++ BUG +++++
		move.l	(aBUF)+,d0
		move.b	d0,d1
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		move.b	d1,(aDREG)
	;+++++ BUG +++++
	;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
	;+++++ BUG +++++
		move.l	(aBUF)+,d0
		move.b	d0,d1
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		move.b	d1,(aDREG)
		subq.l	#1,d2
	while	ne
;8�o�C�g����
dataouti_less_than_8:
	and.w	#7,dLEN
	beq	dataouti_finish
;1�o�C�g���]������
	subq.w	#1,dLEN
	for	dLEN
		break	<tst.b (aINTS)>,ne	;���荞�݂���
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,ne	;FIFO���t���łȂ��Ȃ�܂ő҂�
		move.b	(aBUF)+,(aDREG)
	next
;��n��
dataouti_finish:
	do
		move.b	(aINTS),d0
	while	eq			;���荞�݂�҂�
	move.b	d0,(aINTS)		;INTS���N���A
	if	<cmp.b #SPC_INTS_CC,d0>,eq
		moveq.l	#0,d0
	endif
;+++++ BUG +++++
;INTS��Ԃ��Ƃ�d0.l�̏�ʃo�C�g�ɃS�~������
;+++++ BUG +++++
	pop
	rts

    .else

	move.w	aBUF,d0
	gotoand	<lsr.w #1,d0>,cs,<is68000 d0>,eq,dataouti_1byte	;aBUF�������68000�ł���B1�o�C�g���]������
;aBUF�������܂���68000�łȂ�
;8�o�C�g���]������
	while	<subq.l #8,dLEN>,hs
		goto	<tst.b (aINTS)>,ne,dataouti_finish	;���荞�݂���
		redo	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,eq	;FIFO����ɂȂ�܂ő҂�
	;8�o�C�g�]������B�r����FIFO���t���ɂȂ��Ă��Ȃ����m�F���Ȃ�
	  .rept 2
		move.l	(aBUF)+,d0
	    .rept 4
		rol.l	#8,d0
		move.b	d0,(aDREG)
	    .endm
	  .endm
	endwhile
	addq.l	#8,dLEN
;1�o�C�g���]������
dataouti_1byte:
	while	<subq.l #1,dLEN>,hs
		goto	<tst.b (aINTS)>,ne,dataouti_finish	;���荞�݂���
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,ne	;FIFO���t���łȂ��Ȃ�܂ő҂�
	;1�o�C�g�]������
		move.b	(aBUF)+,(aDREG)
	endwhile
;��n��
dataouti_finish:
	moveq.l	#0,d0
	do
		move.b	(aINTS),d0
	while	eq			;���荞�݂�҂�
	move.b	d0,(aINTS)		;INTS���N���A
	if	<cmp.b #SPC_INTS_CC,d0>,eq	;Command Complete
		moveq.l	#0,d0
	endif
	pop
	rts

    .endif

;----------------------------------------------------------------
;SCSI����(�\�t�g�]��)
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataini_transfer:
aINTS	reg	a2
aSSTS	reg	a3
aDREG	reg	a4
	push	d1/d2/dLEN/aBUF/aINTS/aSSTS/aDREG
	lea.l	SPC_INTS(aSPC),aINTS
	lea.l	SPC_SSTS(aSPC),aSSTS
	lea.l	SPC_DREG(aSPC),aDREG
;������0�̂Ƃ�256�ƌ��Ȃ�
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;�������Z�b�g����
    .if SCSI_BIOS_LEVEL<=10
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
    .else
	move.b	#0,SPC_TEMP(aSPC)
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
    .endif
;�]���J�n
	move.b	(aINTS),(aINTS)		;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;�C�j�V�G�[�^�œ]������҂�
	do
		move.b	(aSSTS),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
    .if SCSI_BIOS_LEVEL<=10
	;+++++ BUG +++++
	;�^�[�Q�b�g�̂Ƃ����[�v�J�E���^��d2��ݒ肹���Ƀ��[�v�ɔ�э���ł���
		goto	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq,dataini_target	;�^�[�Q�b�g�œ]�����H
	;+++++ BUG +++++
    .else
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;�^�[�Q�b�g�œ]�����H
    .endif
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne	;�C�j�V�G�[�^�œ]������҂�

    .if SCSI_BIOS_LEVEL<=10

;�C�j�V�G�[�^�œ]����
	goto	<tst.b SRAM_SCSI_MODE>,mi,dataini_block_transfer	;SCSI�ݒ�B�u���b�N|�^�C�v����|�o�[�X�g|�\�t�g|�g��|�{��###
									;�u���b�N�]��
;�o�C�g�]��
dataini_byte_transfer:
	move.l	dLEN,d0
	lsr.l	#3,d0			;����/8
	goto	eq,dataini_less_than_8	;8�o�C�g����
;8�o�C�g�ȏ�
;<d0.l:����/8
	move.l	d0,d2
dataini_target:
;8�o�C�g���]������
	do
	;FIFO���t���ɂȂ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,dataini_finish	;���荞�݂���
		while	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq
	;FIFO����8�o�C�g�ǂݍ���
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
	;+++++ BUG +++++
	;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
	;+++++ BUG +++++
		move.l	d0,(aBUF)+
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
	;+++++ BUG +++++
	;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
	;+++++ BUG +++++
		move.l	d0,(aBUF)+
		subq.l	#1,d2
	while	ne
;8�o�C�g����
dataini_less_than_8:
	and.w	#7,dLEN
	goto	eq,dataini_finish
;1�o�C�g���]������
;+++++ BUG +++++
;Service Required�ɑΉ����Ă��Ȃ�
;	�Ō�̃f�[�^�𑗐M������AACK��False�ɂȂ�̂�҂����ɃX�e�[�^�X�C���t�F�[�Y�Ɉڍs���Ă��܂��n�[�h�f�B�X�N������炵��
;	�Ō�̃f�[�^��FIFO������o���I���܂Ŗ{�̂̓f�[�^�C���t�F�[�Y�Ȃ̂ŁA
;	�t�F�[�Y�̕s��v�Ŋ��荞�ݗv����Service Required���Z�b�g�����\��������
;	Service Required���Z�b�g�����Ɠ]�������f���Ă��܂��AFIFO�Ɏc���Ă����Ō�̃f�[�^���󂯎�葹�˂�\��������
;+++++ BUG +++++
	subq.w	#1,dLEN
	for	dLEN
		goto	<tst.b (aINTS)>,ne,dataini_finish	;���荞�݂���
		redo	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,ne	;FIFO����
		move.b	(aDREG),(aBUF)+		;FIFO����1�o�C�g�ǂݍ���
	next
;��n��
dataini_finish:
	do
		move.b	(aINTS),d0
	while	eq			;���荞�݂�҂�
	move.b	d0,(aINTS)		;INTS���N���A
	if	<cmp.b #SPC_INTS_CC,d0>,eq
		moveq.l	#0,d0
	endif
;+++++ BUG +++++
;INTS��Ԃ��Ƃ�d0.l�̏�ʃo�C�g�ɃS�~������
;+++++ BUG +++++
	pop
	rts

;�u���b�N�]��
dataini_block_transfer:
	moveq.l	#0,d2
	move.w	BIOS_SCSI_BLOCK_SIZE.w,d2	;SCSI�@��̃u���b�N�T�C�Y
	goto	<cmp.l d2,dLEN>,cs,dataini_byte_transfer	;�u���b�N�T�C�Y�����B�o�C�g�]��
	divu.w	d2,dLEN			;�[��*$10000+�u���b�N��
	lsr.l	#4,d2			;�u���b�N�T�C�Y/16
;1�u���b�N���]������
	subq.l	#1,d2			;�u���b�N�T�C�Y/16-1
	do
	;FIFO���t���ɂȂ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,dataini_finish	;���荞�݂���
		while	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq
	;FIFO����1�u���b�N�ǂݍ��ށB�r����FIFO����ɂȂ��Ă��Ȃ����m�F���Ȃ�
		move.w	d2,d1
		for	d1
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000�Ńo�b�t�@�̃A�h���X����̂Ƃ��A�h���X�G���[����������
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
		next
		subq.w	#1,dLEN
	while	ne
	swap.w	dLEN			;0*$10000+�[��
	goto	dataini_byte_transfer	;�o�C�g�]��

    .else

	move.w	aBUF,d0
	gotoand	<lsr.w #1,d0>,cs,<is68000 d0>,eq,dataini_1byte	;aBUF�������68000�ł���B1�o�C�g���]������
;aBUF�������܂���68000�łȂ�
	goto	<tst.b SRAM_SCSI_MODE>,pl,dataini_8bytes	;SRAM_SCSI_BLOCK_BIT�B�u���b�N�]�����Ȃ��B8�o�C�g���]������
;�u���b�N�]������
	moveq.l	#0,d2
	move.w	BIOS_SCSI_BLOCK_SIZE.w,d2	;SCSI�@��̃u���b�N�T�C�Y�B0�łȂ�16�Ŋ���؂�邱��
	while	<sub.l d2,dLEN>,hs
		move.b	(aINTS),d0
		if	ne			;���荞�݂���
			add.l	d2,dLEN
			goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataini_1byte	;Service Required�̂Ƃ�FIFO����ɂȂ�܂�1�o�C�g���]������
			goto	dataini_finish		;����ȊO�͒��~
		endif
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq	;FIFO���t���ɂȂ�܂ő҂�
	;1�u���b�N�]������B�r����FIFO����ɂȂ��Ă��Ȃ����m�F���Ȃ�
		move.w	d2,d1
		lsr.w	#4,d1
		subq.w	#1,d1			;�u���b�N�T�C�Y/16-1
		for	d1
		;16�o�C�g�]������
		  .rept 4
			move.b	(aDREG),d0
			lsl.w	#8,d0
			move.b	(aDREG),d0
			swap.w	d0
			move.b	(aDREG),d0
			lsl.w	#8,d0
			move.b	(aDREG),d0
			move.l	d0,(aBUF)+
		  .endm
		next
	endwhile
	add.l	d2,dLEN
;8�o�C�g���]������
dataini_8bytes:
	while	<subq.l #8,dLEN>,hs
		move.b	(aINTS),d0
		if	ne			;���荞�݂���
			addq.l	#8,dLEN
			goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataini_1byte	;Service Required�̂Ƃ�FIFO����ɂȂ�܂�1�o�C�g���]������
			goto	dataini_finish		;����ȊO�͒��~
		endif
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq	;FIFO���t���ɂȂ�܂ő҂�
	;8�o�C�g�]������B�r����FIFO����ɂȂ��Ă��Ȃ����m�F���Ȃ�
	  .rept 2
		move.b	(aDREG),d0
		lsl.w	#8,d0
		move.b	(aDREG),d0
		swap.w	d0
		move.b	(aDREG),d0
		lsl.w	#8,d0
		move.b	(aDREG),d0
		move.l	d0,(aBUF)+
	  .endm
	endwhile
	addq.l	#8,dLEN
;1�o�C�g���]������
dataini_1byte:
	while	<subq.l #1,dLEN>,hs
		move.b	(aINTS),d0
		if	ne			;���荞�݂���
			ifor	<btst.l #SPC_INTS_SR_BIT,d0>,eq,<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,ne	;Service Required�łȂ��܂���FIFO����̂Ƃ�
				addq.l	#1,dLEN
				goto	dataini_finish
			endif
			;Service Required����FIFO����łȂ��Ƃ����荞�݂𖳎�����
		endif
		redo	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,ne	;FIFO����łȂ��Ȃ�܂ő҂�
	;1�o�C�g�]������
		move.b	(aDREG),(aBUF)+
	endwhile
	addq.l	#1,dLEN
;��n��
dataini_finish:
	moveq.l	#0,d0
	do
		move.b	(aINTS),d0
	while	eq			;���荞�݂�҂�
	move.b	d0,(aINTS)		;INTS���N���A
	moveq.l	#.notb.(SPC_INTS_CC|SPC_INTS_SR),d1
	and.b	d0,d1
	ifand	<>,eq,<tst.l dLEN>,eq	;Command Complete�܂���Service Required�ōŌ�܂œ]������
		moveq.l	#0,d0
	endif
	pop
	rts

    .endif

;----------------------------------------------------------------
;CPU�]���ŏo�͂���
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0
dataout_cpu:
aPSNS	reg	a2
aSCMD	reg	a3
	push	d1/d2/dLEN/aBUF/aPSNS/aSCMD
	lea.l	SPC_PSNS(aSPC),aPSNS
	lea.l	SPC_SCMD(aSPC),aSCMD
	moveq.l	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,d1	;Set ACK
	moveq.l	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,d2	;Reset ACK
	do
	;�t�F�[�Y���Z�b�g����
		move.b	(aPSNS),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1��҂�
		do
		while	<tst.b (aPSNS)>,pl	;SPC_PSNS_REQ_BIT
	;1�o�C�g�o�͂���
		move.b	(aBUF)+,SPC_TEMP(aSPC)
		move.b	d1,(aSCMD)		;Set ACK
	;REQ=0��҂�
		do
		while	<tst.b (aPSNS)>,mi	;SPC_PSNS_REQ_BIT
		move.b	d2,(aSCMD)		;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;CPU�]���œ��͂���
;<dLEN.l:�f�[�^�̒���
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0
datain_cpu:
aPSNS	reg	a2
aSCMD	reg	a3
	push	d1/d2/dLEN/aBUF/aPSNS/aSCMD
	lea.l	SPC_PSNS(aSPC),aPSNS
	lea.l	SPC_SCMD(aSPC),aSCMD
	moveq.l	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,d1	;Set ACK
	moveq.l	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,d2	;Reset ACK
	do
	;�t�F�[�Y���Z�b�g����
		move.b	(aPSNS),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1��҂�
		do
		while	<tst.b (aPSNS)>,pl	;SPC_PSNS_REQ_BIT
		move.b	d1,(aSCMD)		;Set ACK
	;REQ=0��҂�
		do
		while	<tst.b (aPSNS)>,mi	;SPC_PSNS_REQ_BIT
	;1�o�C�g���͂���
		move.b	SPC_TEMP(aSPC),(aBUF)+
		move.b	d2,(aSCMD)		;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
	pop
	rts


  .endif


  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Test Unit Ready�R�}���h
test_unit_ready_command:
	.dc.b	$00			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$24 _S_TESTUNIT
;	����e�X�g
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_24_S_TESTUNIT:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
  .if SCSI_BIOS_LEVEL<=0
	lea.l	test_unit_ready_command,a2	;Test Unit Ready�R�}���h
  .else
	lea.l	test_unit_ready_command(pc),a2	;Test Unit Ready�R�}���h
  .endif
	bsr	no_dataio_command	;�f�[�^�C���t�F�[�Y�^�f�[�^�A�E�g�t�F�[�Y�̂Ȃ�6�o�C�g�̃R�}���h
	pop
	unlk	a5
	rts

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Rezero Unit�R�}���h
rezero_unit_command:
	.dc.b	$01			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$2B _S_REZEROUNIT
;	��Ԑݒ�
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_2B_S_REZEROUNIT:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
  .if SCSI_BIOS_LEVEL<=0
	lea.l	rezero_unit_command,a2	;Rezero Unit�R�}���h
  .else
	lea.l	rezero_unit_command(pc),a2	;Rezero Unit�R�}���h
  .endif
	bsr	no_dataio_command	;�f�[�^�C���t�F�[�Y�^�f�[�^�A�E�g�t�F�[�Y�̂Ȃ�6�o�C�g�̃R�}���h
	pop
	unlk	a5
	rts

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read(6)�R�}���h
read_6_command_2nd:
	.dc.b	$08			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�_���u���b�N�A�h���X(���)#####
	.dc.b	$00			;2 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;3 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;4 �]���f�[�^��
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$2E _S_READI
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�u���b�N��
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;<a1.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_2E_S_READI:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
	movea.l	a1,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	read_6_command_2nd,a2	;Read(6)�R�}���h
    .else
	lea.l	read_6_command_2nd(pc),a2	;Read(6)�R�}���h
    .endif
	lea.l	-16(a5),a1
  .else
	lea.l	-16(a5),a1
	lea.l	read_6_command_2nd(pc),a2	;Read(6)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(a1)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),a1
	move.b	d6,3(a1)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,2(a1)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(a1)		;�u���b�N�ԍ�(���)
  .else
	lea.l	-16(a5),a1
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(a1)			;�u���b�N�ԍ�
  .endif
	move.b	dLEN,4(a1)		;�u���b�N��
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	goto	<tst.l d0>,ne,readcap_error
;�f�[�^�C���t�F�[�Y
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;�u���b�N���w����4�ȏ�̂Ƃ�3�ƌ��Ȃ�
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,a1
  .if SCSI_BIOS_LEVEL<=0
	bsr	scsi_0B_S_DATAINI	;SCSI�R�[��$0B _S_DATAINI
  .else
	bsr	scsi_04_S_DATAIN	;SCSI�R�[��$04 _S_DATAIN
  .endif
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	goto	<cmpi.l #-1,d0>,eq,readcap_error
  .if 3<=SCSI_BIOS_LEVEL
	if	<cmpi.l #-2,d0>,ne
		bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	readi_end:
    .if SCSI_BIOS_LEVEL<=4
		pop_test
    .else
		pop
    .endif
		unlk	a5
		rts
	endif
  .endif
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
    .if 3<=SCSI_BIOS_LEVEL
	if	<tst.l d0>,eq
		moveq.l	#-2,d0
	endif
    .endif
	pop
	unlk	a5
	rts
  .else
	goto	<tst.l d0>,ne,readi_end
	moveq.l	#-2,d0
	goto	readi_end
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read Capacity�R�}���h
read_capacity_command:
	.dc.b	$25			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved####|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 Reserved
	.dc.b	$00			;8 Reserved#######|PMI
	.dc.b	$00			;9 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$25 _S_READCAP
;	�e�ʊm�F
;<dID.l:(LUN<<16)|SCSI-ID
;<a1.l:�o�b�t�@�̃A�h���X
;	0	�_���u���b�N�A�h���X(���)
;	1	  :
;	2	  :
;	3	�_���u���b�N�A�h���X(����)
;	4	�u���b�N��(���)
;	5	  :
;	6	  :
;	7	�u���b�N��(����)
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_25_S_READCAP:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
	movea.l	a1,a3
;�R�}���h�����
	lea.l	-16(a5),a1
  .if SCSI_BIOS_LEVEL<=0
	lea.l	read_capacity_command,a2	;Read Capacity�R�}���h
  .else
	lea.l	read_capacity_command(pc),a2	;Read Capacity�R�}���h
  .endif
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(a1)+
	next
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	lea.l	-16(a5),a1
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	goto	<tst.l d0>,ne,readcap_error
;�f�[�^�C���t�F�[�Y
	movea.l	a3,a1
	moveq.l	#8,dLEN			;�f�[�^�̒���
	bsr	scsi_0B_S_DATAINI	;SCSI�R�[��$0B _S_DATAINI
	goto	<cmpi.l #-1,d0>,eq,readcap_error
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
readcap_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	unlk	a5
	rts

readcap_error:
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	unlk	a5
	rts
  .else
	goto	readcap_end
  .endif

;----------------------------------------------------------------
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;<dID.l:(LUN<<16)|SCSI-ID
;<a1.l:�R�}���h
;>d0.l:0=����,-1=���s
select_and_cmdout:
	push	d1/dID
;�Z���N�V�����t�F�[�Y
	move.w	#2-1,d1
	for	d1
		bsr	scsi_01_S_SELECT	;SCSI�R�[��$01 _S_SELECT
  .if SCSI_BIOS_LEVEL<=4
		goto	<tst.l d0>,eq,select_and_cmdout_cmdout
	next
	goto	select_and_cmdout_error
  .else
	next	<tst.l d0>,ne
	goto	ne,select_and_cmdout_error
  .endif
;�R�}���h�A�E�g�t�F�[�Y
select_and_cmdout_cmdout:
	swap.w	dID
	lsl.b	#5,dID			;LUN<<5
	or.b	dID,1(a1)		;LUN
	bsr	scsi_03_S_CMDOUT	;SCSI�R�[��$03 _S_CMDOUT
	goto	<tst.l d0>,ne,select_and_cmdout_error
	moveq.l	#0,d0			;����
select_and_cmdout_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

select_and_cmdout_error:
	moveq.l	#-1,d0			;���s
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	select_and_cmdout_end
  .endif

;----------------------------------------------------------------
;�f�[�^�C���t�F�[�Y�^�f�[�^�A�E�g�t�F�[�Y�̂Ȃ�6�o�C�g�̃R�}���h
;<a2.l:�R�}���h�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
no_dataio_command:
	lea.l	-16(a5),a1
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(a1)+
	next
	lea.l	-16(a5),a1
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	goto	<tst.l d0>,ne,stsin_and_msgin_error
;----------------------------------------------------------------
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
;>d0.l:(MSGIN<<16)|STSIN
stsin_and_msgin:
	lea.l	-1(a5),a1
	bsr	scsi_06_S_STSIN		;SCSI�R�[��$06 _S_STSIN
	goto	<tst.l d0>,ne,stsin_and_msgin_error
	lea.l	-2(a5),a1
	bsr	scsi_07_S_MSGIN		;SCSI�R�[��$07 _S_MSGIN
	goto	<tst.l d0>,ne,stsin_and_msgin_error
	move.b	-2(a5),d0		;MSGIN
	swap.w	d0
	move.b	-1(a5),d0		;(MSGIN<<16)|STSIN
	rts

stsin_and_msgin_error:
	moveq.l	#-1,d0
	rts

  .if 4<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;50us�P�ʂ̃E�F�C�g
;<d0.l:����(50us�P��)
wait_50us:
aTCDR	reg	a0
	push	d0/d1/d2/aTCDR
	lea.l	MFP_TCDR,aTCDR
	moveq.l	#0,d1
	move.b	(aTCDR),d1
	move.b	(aTCDR),d1
	do
		moveq.l	#0,d2
		move.b	(aTCDR),d2
		redo	<cmp.b (aTCDR),d2>,cs
		sub.w	d2,d1
		if	cs
			add.w	#200,d1
		endif
		exg.l	d1,d2
		sub.l	d2,d0
	while	hi
	pop
	rts
  .endif



;--------------------------------------------------------------------------------
;	.include	sc07iocs3.s
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;SCSI�R�[��$05 _S_DATAOUT �f�[�^�A�E�g�t�F�[�Y
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_05_S_DATAOUT:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,a6
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1��҂�
dataout_wait:
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,dataout_disconnected	;�ؒf
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataout_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0	;SPC_DATAOUT_PHASE
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAOUT_PHASE,d0>,ne,dataout_error	;�f�[�^�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	ne,dataout_error	;�f�[�^�A�E�g�t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
;�]���J�n
	bsr	dataout_transfer	;SCSI�o��(DMA�]��)
	swap.w	d0
	if	eq
	dataout_end:
  .if SCSI_BIOS_LEVEL<=4
		popm_test
  .elif SCSI_BIOS_LEVEL<=10
		popm
  .else
		pop
  .endif
		rts
	endif
  .if 3<=SCSI_BIOS_LEVEL
	if	<tst.w d0>,ne
		swap.w	d0
    .if SCSI_BIOS_LEVEL<=4
		popm_test
		rts
    .else
		goto	dataout_end
    .endif
	endif
  .endif
;�G���[�I��
dataout_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	dataout_end
  .endif

;�ؒf
dataout_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	dataout_end
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$04 _S_DATAIN
;	�f�[�^�C���t�F�[�Y
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_04_S_DATAIN:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,a6
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1��҂�
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,datain_disconnected	;�ؒf
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,datain_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;�t�F�[�Y���m�F����
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
;+++++ BUG +++++
;�]���Ȗ���
	andi.b	#SPC_PHASE_MASK,d0
;+++++ BUG +++++
  .endif
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAIN_PHASE,d0>,ne,datain_error	;�f�[�^�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .else
	goto	<cmpi.b #SPC_DATAIN_PHASE,d0>,ne,datain_error	;�f�[�^�C���t�F�[�Y�ł͂Ȃ��B�G���[�I��
  .endif
;�]���J�n
	bsr	datain_transfer		;SCSI����(DMA�]��)
	swap.w	d0
	if	eq
	datain_end:
  .if SCSI_BIOS_LEVEL<=4
		popm_test
  .elif SCSI_BIOS_LEVEL<=10
		popm
  .else
		pop
  .endif
		rts

	endif
  .if 3<=SCSI_BIOS_LEVEL
	goto	<tst.w d0>,eq,datain_error
	swap.w	d0
    .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
    .else
	goto	datain_end
    .endif
  .endif
;�G���[�I��
datain_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	datain_end
  .endif

;�ؒf
datain_disconnected:
	bsr	scsi_00_S_RESET		;SCSI�R�[��$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	datain_end
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Inquiry�R�}���h
inquiry_command:
	.dc.b	$12			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved####|EVPD
	.dc.b	$00			;2 �y�[�W�R�[�h
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �A���P�[�V������
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$20 _S_INQUIRY
;	INQUIRY�f�[�^�̗v��
;	�ŏ��ɃA���P�[�V��������5���w�肵�Ēǉ��f�[�^���𓾂�
;	�����ăA���P�[�V��������5+�ǉ��f�[�^�����w�肵�Ēǉ��f�[�^�𓾂�
;<dLEN.l:�A���P�[�V������
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;	0	�N�H���t�@�C�A###|�f�o�C�X�^�C�v�R�[�h#####
;		�N�H���t�@�C�A
;			0	���W�J�����j�b�g���ڑ�����Ă���
;			1	���W�J�����j�b�g���ڑ�����Ă��Ȃ�
;			3	���W�J�����j�b�g�����݂��Ȃ�
;		�f�o�C�X�^�C�v�R�[�h
;			$00	�_�C���N�g�A�N�Z�X�f�o�C�X�B���C�f�B�X�N�Ȃ�
;			$01	�V�[�P���V�����A�N�Z�X�f�o�C�X�B���C�e�[�v�Ȃ�
;			$02	�v�����^�f�o�C�X
;			$03	�v���Z�b�T�f�o�C�X
;			$04	���C�g�����X�f�o�C�X�B�ǋL�^���f�B�X�N�Ȃ�
;			$05	CD-ROM�f�o�C�X
;			$06	�X�L���i�f�o�C�X
;			$07	���������f�o�C�X�B�C���[�U�u�����f�B�X�N�Ȃ�
;			$08	���f�B�A�`�F���W���f�o�C�X�B���C�e�[�v���C�u�����A���f�B�X�N���C�u�����Ȃ�
;			$09	�R�~���j�P�[�V�����f�o�C�X
;			$84	SHARP MO
;	1	RMB|�f�o�C�X�^�C�v�C���q#######
;		RMB
;			0	�Œ�
;			1	��
;	2	ISO�o�[�W����##|ECMA�o�[�W����###|ANSI�o�[�W����###
;		bit7-6	ISO�o�[�W����(�ʏ��0)
;		bit5-3	ECMA�o�[�W����(�ʏ��0)
;		bit2-0	ANSI�o�[�W����
;			0	���K��
;			1	SCSI-1�BANSI X3.131-1986����
;			2	SCSI-2�BANSI X3T9.2/86-109����
;	3	AENC|TrmlOP|Reserved##|���X�|���X�f�[�^�`��####
;	4	�ǉ��f�[�^��(�Ȃ����0)
;	5�`	�ǉ��f�[�^
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_20_S_INQUIRY:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	inquiry_command,a2	;Inquiry�R�}���h
    .else
	lea.l	inquiry_command(pc),a2	;Inquiry�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	inquiry_command(pc),a2	;Inquiry�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;�A���P�[�V������
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�C���t�F�[�Y
	movea.l	a3,aBUF
	bsr	scsi_0B_S_DATAINI	;SCSI�R�[��$0B _S_DATAINI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Request Sense�R�}���h
request_sense_command:
	.dc.b	$03			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �A���P�[�V������
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$2C _S_REQUEST
;	�Z���X�f�[�^�̗v��
;<dLEN.l:�A���P�[�V������
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_2C_S_REQUEST:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	request_sense_command,a2	;Request Sense�R�}���h
    .else
	lea.l	request_sense_command(pc),a2	;Request Sense�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	request_sense_command(pc),a2	;Request Sense�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;�A���P�[�V������
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�C���t�F�[�Y
	movea.l	a3,aBUF
	bsr	scsi_0B_S_DATAINI	;SCSI�R�[��$0B _S_DATAINI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Mode Sense(6)�R�}���h
mode_sense_6_command:
	.dc.b	$1A			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|R|DBD|Reserved###
	.dc.b	$00			;2 PC##|�y�[�W�R�[�h######
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �A���P�[�V������
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$29 _S_MODESENSE
;	���[�h�Z���X
;<d2.l:(PC<<6)|�y�[�W�R�[�h
;	PC	0	����
;		1	�ύX�\�r�b�g�}�X�N
;		2	�f�t�H���g
;		3	�ۑ�
;	�y�[�W�R�[�h63�͂��ׂẴp�����[�^�y�[�W���擾
;<dLEN.l:�A���P�[�V�������B4�ȏ�
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;	���[�h�p�����[�^�w�b�_
;	0	���[�h�p�����[�^��
;		�ԋp�ł���p�����[�^���X�g�̃o�C�g���B���[�h�p�����[�^�w�b�_���܂܂Ȃ��B8�̔{��
;	1	���f�B�A�^�C�v
;	2	�f�o�C�X�ŗL�p�����[�^
;		�_�C���N�g�A�N�Z�X�f�o�C�X�̃f�o�C�X�ŗL�p�����[�^
;		WP#|Reserved##|DPOFUA|Reserved####
;		�r�b�g7��1�̂Ƃ��������݋֎~
;	3	�u���b�N�f�B�X�N���v�^��
;		�ԋp���ꂽ�p�����[�^���X�g�̃o�C�g���B���[�h�p�����[�^�w�b�_���܂܂Ȃ��B8�̔{��
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_29_S_MODESENSE:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	mode_sense_6_command,a2	;Mode Sense(6)�R�}���h
    .else
	lea.l	mode_sense_6_command(pc),a2	;Mode Sense(6)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	mode_sense_6_command(pc),a2	;Mode Sense(6)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;�A���P�[�V������
  .if 3<=SCSI_BIOS_LEVEL
	move.b	d2,2(aBUF)		;(PC<<6)|�y�[�W�R�[�h�BPC:0=����,1=�ύX�\�r�b�g�}�X�N,2=�f�t�H���g,3=�ۑ�
  .endif
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�C���t�F�[�Y
	movea.l	a3,aBUF
	bsr	scsi_0B_S_DATAINI	;SCSI�R�[��$0B _S_DATAINI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Mode Select(6)�R�}���h
mode_select_6_command:
	.dc.b	$15			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|PF|Reserved###|SP
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �p�����[�^���X�g��
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$2A _S_MODESELECT
;	���[�h�Z���N�g
;<d2.l:PF<<4|SP
;	PF	0	SCSI-1
;		1	SCSI-2
;	SP	0	�ۑ����Ȃ�
;		1	�ۑ�����
;<dLEN.l:�p�����[�^���X�g��
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_2A_S_MODESELECT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	mode_select_6_command,a2	;Mode Select(6)�R�}���h
    .else
	lea.l	mode_select_6_command(pc),a2	;Mode Select(6)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	mode_select_6_command(pc),a2	;Mode Select(6)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;�p�����[�^���X�g��
  .if 3<=SCSI_BIOS_LEVEL
	move.b	d2,1(aBUF)		;PF<<4|SP�BPF:0=SCSI-1,1=SCSI-2�BSP:0=�ۑ����Ȃ�,1=�ۑ�����
  .endif
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�A�E�g�t�F�[�Y
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSI�R�[��$0C _S_DATAOUTI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Reassign Blocks�R�}���h
reassign_blocks_command:
	.dc.b	$07			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$31 _S_REASSIGN
;	�Ĕz�u
;
;�f�B�t�F�N�g���X�g
;	�w�b�_
;	  0 Reserved
;	  1 Reserved
;	  2 �f�B�t�F�N�g���X�g��4*n(���)
;	  3 �f�B�t�F�N�g���X�g��4*n(����)
;	�f�B�t�F�N�g�f�B�X�N���v�^
;	  4+4*0+0 �s�ǃu���b�N�̘_���u���b�N�A�h���X(���)
;	  4+4*0+1   :
;	  4+4*0+2   :
;	  4+4*0+3 �s�ǃu���b�N�̘_���u���b�N�A�h���X(����)
;	    :
;	  4+4*(n-1)+0 �s�ǃu���b�N�̘_���u���b�N�A�h���X(���)
;	  4+4*(n-1)+1   :
;	  4+4*(n-1)+2   :
;	  4+4*(n-1)+3 �s�ǃu���b�N�̘_���u���b�N�A�h���X(����)
;
;<dLEN.l:�f�[�^�̒���
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_31_S_REASSIGN:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	reassign_blocks_command,a2	;Reassign Blocks�R�}���h
    .else
	lea.l	reassign_blocks_command(pc),a2	;Reassign Blocks�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	reassign_blocks_command(pc),a2	;Reassign Blocks�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	lea.l	-16(a5),aBUF
  .if SCSI_BIOS_LEVEL<=3
;+++++ BUG +++++
;Reserved�̃t�B�[���h�ɏ�������ł���
	move.b	#8,4(aBUF)
;+++++ BUG +++++
  .endif
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�A�E�g�t�F�[�Y
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSI�R�[��$0C _S_DATAOUTI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read(6)�R�}���h
read_6_command:
	.dc.b	$08			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�_���u���b�N�A�h���X(���)#####
	.dc.b	$00			;2 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;3 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;4 �]���f�[�^��
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$21 _S_READ
;	�ǂݍ���
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�u���b�N��
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_21_S_READ:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	read_6_command,a2	;Read(6)�R�}���h
    .else
	lea.l	read_6_command(pc),a2	;Read(6)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	read_6_command(pc),a2	;Read(6)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),aBUF
	move.b	d6,3(aBUF)		;�u���b�N�ԍ�(���)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;�u���b�N�ԍ�(����)
  .else
	lea.l	-16(a5),aBUF
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;�u���b�N�ԍ�
  .endif
	move.b	dLEN,4(aBUF)		;�u���b�N��
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�C���t�F�[�Y
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;�u���b�N���w����4�ȏ�̂Ƃ�3�ƌ��Ȃ�
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_04_S_DATAIN	;SCSI�R�[��$04 _S_DATAIN
  .else
	lea.l	scsi_04_S_DATAIN(pc),a0	;SCSI�R�[��$04 _S_DATAIN
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;�\�t�g
		lea.l	scsi_0B_S_DATAINI(pc),a0	;SCSI�R�[��$0B _S_DATAINI
	endif
	jsr	(a0)
  .endif
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_2	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Write(6)�R�}���h
write_6_command:
	.dc.b	$0A			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�_���u���b�N�A�h���X(���)#####
	.dc.b	$00			;2 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;3 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;4 �]���f�[�^��
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$22 _S_WRITE
;	�����o��
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�u���b�N��
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_22_S_WRITE:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	write_6_command,a2	;Write(6)�R�}���h
    .else
	lea.l	write_6_command(pc),a2	;Write(6)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	write_6_command(pc),a2	;Write(6)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),aBUF
	move.b	d6,3(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;�u���b�N�ԍ�(���)
  .else
	lea.l	-16(a5),aBUF
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;�u���b�N�ԍ�
  .endif
	move.b	dLEN,4(aBUF)		;�u���b�N��
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�A�E�g�t�F�[�Y
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;�u���b�N���w����4�ȏ�̂Ƃ�3�ƌ��Ȃ�
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_05_S_DATAOUT	;SCSI�R�[��$05 _S_DATAOUT
  .else
	lea.l	scsi_05_S_DATAOUT(pc),a0	;SCSI�R�[��$05 _S_DATAOUT
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;�\�t�g
		lea.l	scsi_0C_S_DATAOUTI(pc),a0	;SCSI�R�[��$0C _S_DATAOUTI
	endif
	jsr	(a0)
  .endif
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_2	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read(10)�R�}���h
read_10_command:
	.dc.b	$28			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 �]���f�[�^��(���)
	.dc.b	$00			;8 �]���f�[�^��(����)
	.dc.b	$00			;9 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$26 _S_READEXT
;	�g���ǂݍ���
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�u���b�N��
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_26_S_READEXT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	goto	<tst.w dLEN>,eq,writeext_error_1
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
	lea.l	-16(a5),aBUF
  .if SCSI_BIOS_LEVEL<=0
	lea.l	read_10_command,a2	;Read(10)�R�}���h
  .else
	lea.l	read_10_command(pc),a2	;Read(10)�R�}���h
  .endif
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	dLEN,d6
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	move.l	dLEN,d6
  .endif
	move.l	d2,2(aBUF)		;�u���b�N�ԍ�
	move.b	dLEN,8(aBUF)		;�u���b�N��(����)
	lsr.l	#8,dLEN
	move.b	dLEN,7(aBUF)		;�u���b�N��(���)
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�C���t�F�[�Y
	move.l	d6,dLEN
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;�u���b�N���w����4�ȏ�̂Ƃ�3�ƌ��Ȃ�
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_04_S_DATAIN	;SCSI�R�[��$04 _S_DATAIN
  .else
	lea.l	scsi_04_S_DATAIN(pc),a0	;SCSI�R�[��$04 _S_DATAIN
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;�\�t�g
		lea.l	scsi_0B_S_DATAINI(pc),a0	;SCSI�R�[��$0B _S_DATAINI
	endif
	jsr	(a0)
  .endif
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_2	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Write(10)�R�}���h
write_10_command:
	.dc.b	$2A			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 �]���f�[�^��(���)
	.dc.b	$00			;8 �]���f�[�^��(����)
	.dc.b	$00			;9 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$27 _S_WRITEEXT
;	�g�������o��
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�u���b�N��
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_27_S_WRITEEXT:
	link.w	a5,#-16
	push	d1/dLEN/d6/aBUF/a2/a3
  .if 10<=SCSI_BIOS_LEVEL
	goto	<tst.w dLEN>,eq,writeext_error_1
  .endif
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	write_10_command,a2	;Write(10)�R�}���h
    .else
	lea.l	write_10_command(pc),a2	;Write(10)�R�}���h
    .endif
;��������_S_WRITEEXT�A_S_VERIFYEXT����
writeext_verifyext_common:
	movea.l	aBUF,a3
  .else
	movea.l	aBUF,a3
  .endif
;�R�}���h�����
	lea.l	-16(a5),aBUF
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	write_10_command(pc),a2	;Write(10)�R�}���h
  .endif
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	-16(a5),aBUF
;��������_S_WRITEEXT�A_S_VERIFYEXT����
writeext_verifyext_common:
  .endif
	move.l	dLEN,d6
  .if SCSI_BIOS_LEVEL<=4
	lea.l	-16(a5),aBUF
  .endif
	move.l	d2,2(aBUF)		;�u���b�N�ԍ�
	move.b	dLEN,8(aBUF)		;�u���b�N��(����)
	lsr.l	#8,dLEN
	move.b	dLEN,7(aBUF)		;�u���b�N��(���)
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�A�E�g�t�F�[�Y
	move.l	d6,dLEN
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;�u���b�N���w����4�ȏ�̂Ƃ�3�ƌ��Ȃ�
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_05_S_DATAOUT	;SCSI�R�[��$05 _S_DATAOUT
  .else
	lea.l	scsi_05_S_DATAOUT(pc),a0	;SCSI�R�[��$05 _S_DATAOUT
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;�\�t�g
		lea.l	scsi_0C_S_DATAOUTI(pc),a0	;SCSI�R�[��$0C _S_DATAOUTI
	endif
	jsr	(a0)
  .endif
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop_test
	unlk	a5
	rts
  .else
writeext_stsin_2:
	goto	<cmpi.l #-1,d0>,eq,writeext_error_1
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
	goto	writeext_stsin_0

;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
writeext_stsin_x:
	goto	<tst.l d0>,ne,writeext_error_1
writeext_stsin_0:
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
writeext_end:
	pop_test
	unlk	a5
	rts

;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
writeext_stsin_1:
	goto	<cmpi.l #-1,d0>,ne,writeext_stsin_0
writeext_error_1:
	moveq.l	#-1,d0
	goto	writeext_end
  .endif

  .if 3<=SCSI_BIOS_LEVEL
writeext_error_2:
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	if	<tst.l d0>,eq
		moveq.l	#-2,d0
	endif
	pop
	unlk	a5
	rts
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Verify(10)�R�}���h
verify_10_command:
	.dc.b	$2F			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|DPO|Reserved##|BytChk|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 �]���f�[�^��(���)
	.dc.b	$00			;8 �]���f�[�^��(����)
	.dc.b	$00			;9 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$28 _S_VERIFYEXT
;	�g���x���t�@�C
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�u���b�N��
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:�u���b�N���w���B0=256,1=512,2=1024,3=2048
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_28_S_VERIFYEXT:
	link.w	a5,#-16
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .if 10<=SCSI_BIOS_LEVEL
	goto	<tst.w dLEN>,eq,writeext_error_1
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	verify_10_command,a2	;Verify(10)�R�}���h
  .elif SCSI_BIOS_LEVEL<=4
	lea.l	verify_10_command(pc),a2	;Verify(10)�R�}���h
  .else
	movea.l	aBUF,a3
;�R�}���h�����
	lea.l	-16(a5),aBUF
	lea.l	verify_10_command(pc),a2	;Verify(10)�R�}���h
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
  .endif
;��������_S_WRITEEXT�A_S_VERIFYEXT����
	goto	writeext_verifyext_common

;----------------------------------------------------------------
;Format Unit�R�}���h
format_unit_command:
	.dc.b	$04			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|FmtData|CmpLst|�f�B�t�F�N�g���X�g�`��###
	.dc.b	$00			;2 �x���_�ŗL
	.dc.b	$00			;3 �C���^���[�u(���)
	.dc.b	$00			;4 �C���^���[�u(����)
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;SCSI�R�[��$23 _S_FORMAT
;	�t�H�[�}�b�g
;<dLEN.l:�C���^���[�u
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_23_S_FORMAT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	format_unit_command,a2	;Format Unit�R�}���h
    .else
	lea.l	format_unit_command(pc),a2	;Format Unit�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	format_unit_command(pc),a2	;Format Unit�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;�C���^���[�u(����)
	lsr.l	#8,dLEN
	move.b	dLEN,3(aBUF)		;�C���^���[�u(���)
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Prevent-Allow Medium Removal�R�}���h
prevent_allow_command:
	.dc.b	$1E			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved#######|Prevent
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$32 _S_PAMEDIUM
;	�C�W�F�N�g���^�C�W�F�N�g�֎~
;<dLEN.l:0=�C�W�F�N�g����,1=�C�W�F�N�g�֎~
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_32_S_PAMEDIUM:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	prevent_allow_command,a2	;Prevent-Allow Medium Removal�R�}���h
    .else
	lea.l	prevent_allow_command(pc),a2	;Prevent-Allow Medium Removal�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	prevent_allow_command(pc),a2	;Prevent-Allow Medium Removal�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	andi.b	#1,dLEN
	move.b	dLEN,4(aBUF)		;0=�C�W�F�N�g����,1=�C�W�F�N�g�֎~
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Start-Stop Unit(Eject SONY MO)�R�}���h
start_stop_unit_command:
	.dc.b	$1B			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved####|Immed
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved######|LoEj|Start
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$2F _S_STARTSTOP
;	���싖�^����֎~
;<dLEN.l:0=����֎~,1=���싖��,2=�A�����[�h,3=���[�h
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_2F_S_STARTSTOP:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	start_stop_unit_command,a2	;Start-Stop Unit(Eject SONY MO)�R�}���h
    .else
	lea.l	start_stop_unit_command(pc),a2	;Start-Stop Unit(Eject SONY MO)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	start_stop_unit_command(pc),a2	;Start-Stop Unit�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	andi.b	#3,dLEN
	move.b	dLEN,4(aBUF)		;0=����֎~,1=���싖��,2=�A�����[�h,3=���[�h
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Load/Unload SHARP MO�R�}���h
load_unload_command:
	.dc.b	$C1			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|#####
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4 #######|LoEj
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$30 _S_SEJECT
;	�C�W�F�N�g(SHARP MO)
;	SUSIE.X�ł�_S_EJECT6MO1�ƌĂ΂�Ă���
;<dLEN.l:0=�A�����[�h,1=���[�h
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_30_S_SEJECT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	load_unload_command,a2	;Load/Unload SHARP MO�R�}���h
    .else
	lea.l	load_unload_command(pc),a2	;Load/Unload SHARP MO�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	load_unload_command(pc),a2	;Load/Unload SHARP MO�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	andi.b	#1,dLEN
	move.b	dLEN,4(aBUF)		;0=�A�����[�h,1=���[�h
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	moveq.l	#6,dLEN			;����
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Seek(6)�R�}���h
seek_6_command:
	.dc.b	$0B			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�u���b�N�ԍ�(���)#####
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$2D _S_SEEK
;	�V�[�N
;<d2.l:�u���b�N�ԍ�
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_2D_S_SEEK:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	seek_6_command,a2	;Seek(6)�R�}���h
    .else
	lea.l	seek_6_command(pc),a2	;Seek(6)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	seek_6_command(pc),a2	;Seek(6)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),aBUF
	move.b	d6,3(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;�u���b�N�ԍ�(���)
  .else
	lea.l	-16(a5),aBUF
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;�u���b�N�ԍ�
  .endif
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=3
;+++++ BUG +++++
;Reserved�̃t�B�[���h�ɏ�������ł���
	move.b	dLEN,4(aBUF)
;+++++ BUG +++++
  .endif
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Assign Drive(SASI)�R�}���h
assign_drive_sasi_command:
	.dc.b	$C2			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4
	.dc.b	$00			;5 �f�[�^�̒���
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$36 _S_DSKINI
;	Assign Drive(SASI)
;<dLEN.l:�f�[�^�̒���
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_36_S_DSKINI:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	assign_drive_sasi_command,a2	;Assign Drive(SASI)�R�}���h
    .else
	lea.l	assign_drive_sasi_command(pc),a2	;Assign Drive(SASI)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	assign_drive_sasi_command(pc),a2	;Assign Drive(SASI)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	dLEN,d1
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	move.l	dLEN,d1
  .endif
	move.b	d1,5(aBUF)		;�f�[�^�̒���
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	moveq.l	#6,dLEN
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�A�E�g�t�F�[�Y
	move.l	d1,dLEN
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSI�R�[��$0C _S_DATAOUTI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Format Block(SASI)�R�}���h
format_block_sasi_command:
	.dc.b	$06			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 �u���b�N�ԍ�(���)
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 �C���^���[�u
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$37 _S_FORMATB
;	Format Block(SASI)
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�C���^���[�u
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_37_S_FORMATB:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	format_block_sasi_command,a2	;Format Block(SASI)�R�}���h
    .else
	lea.l	format_block_sasi_command(pc),a2	;Format Block(SASI)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	format_block_sasi_command(pc),a2	;Format Block�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.l	d2,d6
  .if SCSI_BIOS_LEVEL<=4
	move.b	d6,3(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;�u���b�N�ԍ�(���)
  .else
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;�u���b�N�ԍ�
  .endif
	move.b	dLEN,4(aBUF)		;�C���^���[�u
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Bad Track Format(SASI)�R�}���h
bad_track_format_sasi_command:
	.dc.b	$07			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 �u���b�N�ԍ�(���)
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 �C���^���[�u
	.dc.b	$00			;5 �R���g���[���o�C�g
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$38 _S_BADFMT
;	Bad Track Format(SASI)
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�C���^���[�u
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_38_S_BADFMT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	bad_track_format_sasi_command,a2	;Bad Track Format(SASI)�R�}���h
    .else
	lea.l	bad_track_format_sasi_command(pc),a2	;Bad Track Format(SASI)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	bad_track_format_sasi_command(pc),a2	;Bad Track Format(SASI)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.l	d2,d6
  .if SCSI_BIOS_LEVEL<=4
	move.b	d6,3(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;�u���b�N�ԍ�(���)
  .else
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;�u���b�N�ԍ�
  .endif
	move.b	dLEN,4(aBUF)		;�C���^���[�u
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Assign Track(SASI)�R�}���h
assign_track_sasi_command:
	.dc.b	$0E			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 �u���b�N�ԍ�(���)
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 �C���^���[�u
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;SCSI�R�[��$39 _S_ASSIGN
;	Assign Track(SASI)
;<d2.l:�u���b�N�ԍ�
;<dLEN.l:�C���^���[�u
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:�o�b�t�@�̃A�h���X
;>d0.l:0=����,-1=���s,���̑�=(MSGIN<<16)|STSIN
scsi_39_S_ASSIGN:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;�R�}���h�����
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	assign_track_sasi_command,a2	;Assign Track(SASI)�R�}���h
    .else
	lea.l	assign_track_sasi_command(pc),a2	;Assign Track(SASI)�R�}���h
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	assign_track_sasi_command(pc),a2	;Assign Track(SASI)�R�}���h
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.l	d2,d6
  .if SCSI_BIOS_LEVEL<=4
	move.b	d6,3(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;�u���b�N�ԍ�(����)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;�u���b�N�ԍ�(���)
  .else
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;�u���b�N�ԍ�
  .endif
	move.b	dLEN,4(aBUF)		;�C���^���[�u
;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
	bsr	select_and_cmdout	;�Z���N�V�����t�F�[�Y�ƃR�}���h�A�E�g�t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;�f�[�^�A�E�g�t�F�[�Y
	moveq.l	#4,dLEN			;����
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSI�R�[��$0C _S_DATAOUTI
;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
	pop_test
	unlk	a5
	rts

assign_error:
	moveq.l	#-1,d0
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;�X�e�[�^�X�C���t�F�[�Y�ƃ��b�Z�[�W�C���t�F�[�Y
  .endif


  .if SCSI_BIOS_LEVEL<=3


;----------------------------------------------------------------
;SCSI�o��(DMA�]��)
;	MC68040�܂���MC68060�̂Ƃ��̓f�[�^�L���b�V�����v�b�V�����Ă���Ăяo���K�v������
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataout_transfer:
	push	dLEN/aBUF
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1��҂�
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;�]���J�n
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)	;�]���J�n
	bsr	dataout_dma		;SCSI�o��(DMA�]��)���s
	goto	<tst.l d0>,ne,dataout_transfer_end	;�]�����s�B�I��
;���荞�݂�҂�
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,dataout_transfer_no_error
dataout_transfer_end:
	pop_test
	rts

dataout_transfer_no_error:
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,���̑�=INTS
datain_transfer:
	push	dLEN/aBUF
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
;�]���J�n
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	datain_dma		;SCSI����(DMA�]��)���s
	goto	<tst.l d0>,ne,datain_transfer_end
;���荞�݂�҂�
datain_transfer_wait:
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,datain_transfer_no_error
datain_transfer_end:
	pop_test
	rts

datain_transfer_no_error:
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;SCSI�o��(DMA�]��)���s
;<dLEN.l:����
;<aBUF.l:�A�h���X
dataout_dma:
aDMAC	reg	a0
	push	aDMAC/a3
;DMA��ݒ肷��
	lea.l	DMAC_1_BASE,aDMAC
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
	move.b	#DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.w	#0,DMAC_BTC(aDMAC)
	move.b	#DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;256�o�C�g���]������
	do
	;<dLEN.l:����̎c��̃f�[�^�̒���
	;<aBUF.l:����̃o�b�t�@�̃A�h���X
		goto	<cmp.l #256,dLEN>,ls,dataout_dma_last	;�c��1�`256�o�C�g
		move.l	aBUF,DMAC_MAR(aDMAC)	;�o�b�t�@�̃A�h���X
		move.w	#256,DMAC_MTC(aDMAC)	;�f�[�^�̒���
	dataout_dma_continue:
	;FIFO����ɂȂ�܂ő҂�
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;REQ=1��҂�
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
	;DMA�]���J�n
		move.b	#-1,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
		nop
		nop
		nop
    .if 3<=SCSI_BIOS_LEVEL
		nop
    .endif
	;DMA�]���I����҂�
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
	;+++++ BUG +++++
	;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
	;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
		goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,dataout_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(aDMAC)>,ne,dataout_dma_error	;DMA�G���[����
		adda.l	#256,aBUF		;����̃o�b�t�@�̃A�h���X
		sub.l	#256,dLEN		;����̎c��̃f�[�^�̒���
	while	ne
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;�c��1�`256�o�C�g
dataout_dma_last:
	move.l	aBUF,DMAC_MAR(aDMAC)
	move.w	dLEN,DMAC_MTC(aDMAC)
dataout_dma_last_start:
;FIFO����ɂȂ�܂ő҂�
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
	while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
;REQ=1��҂�
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;DMA�]���J�n
	move.b	#-1,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
	move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
	nop
	nop
	nop
    .if 3<=SCSI_BIOS_LEVEL
	nop
    .endif
;DMA�]���I����҂�
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
	while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
;+++++ BUG +++++
;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
    .if SCSI_BIOS_LEVEL<=0
	goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,dataout_dma_continue
    .else
	goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,dataout_dma_last_start
    .endif
;+++++ BUG +++++
	goto	<tst.b DMAC_CER(aDMAC)>,ne,dataout_dma_error	;DMA�G���[����
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;DMA�G���[����
dataout_dma_error:
	moveq.l	#-1,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)���s
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
datain_dma:
aDMAC	reg	a0
	push	aDMAC/a3
;DMA��ݒ肷��
	lea.l	DMAC_1_BASE,aDMAC
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
	move.b	#DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.w	#0,DMAC_BTC(aDMAC)
	move.b	#DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;256�o�C�g���]������
	do
	;<dLEN.l:����̎c��̃f�[�^�̒���
	;<aBUF.l:����̃o�b�t�@�̃A�h���X
		goto	<cmp.l #256,dLEN>,ls,datain_dma_last	;�c��1�`256�o�C�g
		move.l	aBUF,DMAC_MAR(aDMAC)	;�o�b�t�@�̃A�h���X
		move.w	#256,DMAC_MTC(aDMAC)	;�f�[�^�̒���
	datain_dma_continue:
	;FIFO����łȂ��Ȃ�܂ő҂�
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;DMA�]���J�n
		move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
		nop
		nop
		nop
    .if 3<=SCSI_BIOS_LEVEL
		nop
    .endif
	;DMA�]���I����҂�
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
	;+++++ BUG +++++
	;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
	;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
		goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,datain_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(aDMAC)>,ne,datain_dma_error	;DMA�G���[����
		adda.l	#256,aBUF		;����̃o�b�t�@�̃A�h���X
		sub.l	#256,dLEN		;����̎c��̃f�[�^�̒���
	while	ne
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;�c��1�`256�o�C�g
datain_dma_last:
	move.l	aBUF,DMAC_MAR(aDMAC)
	move.w	dLEN,DMAC_MTC(aDMAC)
datain_dma_last_start:
;FIFO����łȂ��Ȃ�܂ő҂�
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
	while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
;DMA�]���J�n
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
	move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
	nop
	nop
	nop
    .if 3<=SCSI_BIOS_LEVEL
	nop
    .endif
;DMA�]���I����҂�
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC���荞�݂���
	while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
;+++++ BUG +++++
;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
	goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,datain_dma_last_start
;+++++ BUG +++++
	goto	<tst.b DMAC_CER(aDMAC)>,ne,datain_dma_error	;DMA�G���[����
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;DMA�G���[����
datain_dma_error:
	moveq.l	#-1,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;SPC���荞�݂���
dataio_interrupted:
    .if SCSI_BIOS_LEVEL<=0
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA���쒆�~
	moveq.l	#0,d0
	pop
	rts
    .else
	move.b	SPC_INTS(aSPC),d0
	goto	<cmpi.b #SPC_INTS_CC,d0>,ne,dataio_abort	;SPC���]���I�����Ă��Ȃ�
;SPC���]���I������
	goto	<tst.w DMAC_MTC(aDMAC)>,ne,dataio_abort_2	;DMA���]���I�����Ă��Ȃ�
	moveq.l	#0,d0
	goto	dataio_abort

;DMA���]���I�����Ă��Ȃ�
dataio_abort_2:
	moveq.l	#-2,d0
;SPC���]���I�����Ă��Ȃ�
dataio_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA���쒆�~
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts
    .endif


  .elif SCSI_BIOS_LEVEL<=4


;----------------------------------------------------------------
;SCSI�o��(DMA�]��)
;	MC68040�܂���MC68060�̂Ƃ��̓f�[�^�L���b�V�����v�b�V�����Ă���Ăяo���K�v������
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataout_transfer:
	move.l	a3,-(sp)
	lea.l	dataout_dma(pc),a3	;SCSI�o��(DMA�]��)���s
	bsr	dataio_transfer		;SCSI���o��(DMA�]��)
	movea.l	(sp)+,a3
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,���̑�=INTS
datain_transfer:
	move.l	a3,-(sp)
	lea.l	datain_dma(pc),a3	;SCSI����(DMA�]��)���s
	bsr	dataio_transfer		;SCSI���o��(DMA�]��)
;�L���b�V���N���A
;!!! �@�킪X68030�̂Ƃ��]�����CACR�𒼐ڑ��삵�ăf�[�^�L���b�V�������N���A���Ă���
	push	d0/d1
	move.b	SYSPORT_MODEL,d0
	lsr.b	#4,d0
	if	<cmpi.b #14,d0>,cs	;X68030
		.cpu	68030
		movec.l	cacr,d0
		move.l	d0,d1
		bset.l	#11,d0			;�f�[�^�L���b�V�����N���A
		movec.l	d0,cacr
		movec.l	d1,cacr
		.cpu	68000
	endif
	pop
	movea.l	(sp)+,a3
	rts

;----------------------------------------------------------------
;SCSI���o��(DMA�]��)
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
;<a3.l:dataout_dma�܂���datain_dma
;<a6.l:SPC�x�[�X�A�h���X
dataio_transfer:
aDMAC	reg	a2
	push	aBUF/aDMAC
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PSNS_MSG|SPC_PSNS_CD|SPC_PSNS_IO,d0
	move.b	d0,SPC_PCTL(aSPC)
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)	;�f�[�^�̒���(����)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;�f�[�^�̒���(����)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;�f�[�^�̒���(���)
;REQ=1��҂�
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;DMA��ݒ肷��
	lea.l	DMAC_1_BASE,aDMAC
;<a2.l:DMA�`�����l���x�[�X�A�h���X
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSR���N���A
	move.w	#0,DMAC_BTC(aDMAC)
	move.b	#DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a0
	move.l	a0,DMAC_DAR(aDMAC)
;REQ=1��҂�
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;�]���J�n
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)	;�]���J�n
	jsr	(a3)			;dataout_dma�܂���datain_dma
	goto	<tst.l d0>,ne,dataio_transfer_end	;�]�����s�B�I��
;�]���I����҂�
	do
		goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataio_transfer_phase	;�t�F�[�Y�s��v
	while	<btst.b #SPC_INTS_CC_BIT,SPC_INTS(aSPC)>,eq
;�]���I��
	bset.b	#SPC_INTS_CC_BIT,SPC_INTS(aSPC)	;Command Complete���N���A
	moveq.l	#0,d0
	goto	dataio_transfer_end

;�t�F�[�Y�s��v
dataio_transfer_phase:
	bset.b	#SPC_INTS_SR_BIT,SPC_INTS(aSPC)	;Service Required���N���A
	moveq.l	#-3,d0
	goto	dataio_transfer_end

;+++++ BUG +++++
;�ǂ�������Q�Ƃ���Ă��Ȃ�
	moveq.l	#-1,d0
;+++++ BUG +++++
;�I��
dataio_transfer_end:
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts

;----------------------------------------------------------------
;SCSI�o��(DMA�]��)���s
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a2.l:DMA�`�����l���x�[�X�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
dataout_dma:
	push	d1/d2/dLEN/d4/d5/aBUF
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
	move.b	#DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.l	dLEN,d4
;256�o�C�g���]������
	do
		if	<cmp.l #256,dLEN>,hi
			move.l	#256,d5
		else
			move.l	dLEN,d5
		endif
	;<dLEN.l:�c��̃f�[�^�̒���
	;<d4.l:�c��̃f�[�^�̒���
	;<d5.l:����]�����钷��
	;<aBUF.l:�o�b�t�@�̃A�h���X
		move.l	aBUF,DMAC_MAR(a2)	;�o�b�t�@�̃A�h���X
		move.w	d5,DMAC_MTC(a2)		;����]�����钷��
	dataout_dma_continue:
	;FIFO����ɂȂ�܂ő҂�
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataout_dma_phase	;�t�F�[�Y�s��v
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;REQ=1��҂�
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataout_dma_phase	;�t�F�[�Y�s��v
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
	;�o�X�G���[�΍�
	;	X68000�ł�DMAC��SPC��DREQ���O���]���v���M���Ƃ��Ďg���Ȃ����߁A
	;	DREQ���o�Ă��Ȃ��Ƃ���DTACK���o���Ȃ����Ƃ�DREG�ւ̃��C�g��҂����Ă���
	;	SCSI�@��̃f�[�^�̎󂯎�肪�x���ƃo�b�t�@����t�ɂȂ�DREQ���o�Ȃ��Ȃ�
	;	DREG�ւ̃��C�g��DTACK���o�Ȃ��ƃo�X�G���[���������ē]�������f�����
	;	���̂Ƃ�DMAC�̓o�X�G���[�ɂȂ����f�[�^�͓]������Ȃ������Ɣ��f���邪�A
	;	SPC�̓o�X�G���[�����m���Ă��Ȃ��̂ŁABERR���A�T�[�g����Ă���AS���l�Q�[�g�����܂ł̊Ԃ�
	;	�o�X�G���[�ɂȂ����͂��̃f�[�^���󂯎���Ă��܂��ꍇ������
	;	��������o���ăf�[�^���d�����Ȃ��悤�ɂ���
		moveq.l	#0,d0
		move.b	SPC_TCH(aSPC),d0
		lsl.l	#8,d0
		move.b	SPC_TCM(aSPC),d0
		lsl.l	#8,d0
		move.b	SPC_TCL(aSPC),d0	;SPC���]������c��̒���
		move.l	d4,d1			;�u���b�N�J�n���̎c��̒���
		sub.l	d0,d1			;SPC������̃u���b�N�œ]����������
		moveq.l	#0,d0
		move.w	DMAC_MTC(a2),d0		;DMAC�̍���̃u���b�N�̎c��̒���
		move.l	d5,d2			;����]�����钷��
		sub.l	d0,d2			;DMAC������̃u���b�N�œ]����������
		sub.l	d2,d1			;SPC��DMAC���������]����������
		if	ne
			add.l	d1,DMAC_MAR(a2)		;DMAC���]������A�h���X��i�߂�
			sub.w	d1,DMAC_MTC(a2)		;DMAC���]�����钷�������炷
		endif
	;�]���J�n
		move.b	#-1,DMAC_CSR(a2)		;DMAC_CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(a2)	;�]���J�n
		nop
		nop
		nop
		nop
		nop
	;�]���I����҂�
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataout_dma_phase	;�t�F�[�Y�s��v
			break	<btst.b #SPC_INTS_CC_BIT,SPC_INTS(aSPC)>,ne	;�]���I��
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(a2)>,eq
	;SPC�܂���DMA���]���I������
	;+++++ BUG +++++
	;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
	;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
		goto	<btst.b #1,DMAC_CER(a2)>,ne,dataout_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(a2)>,ne,dataout_dma_error	;DMA�G���[����
		goto	<tst.w DMAC_MTC(a2)>,ne,dataout_dma_error	;DMA���]���I�����Ă��Ȃ�
		adda.l	d5,aBUF			;�A�h���X�𑝂₷
		sub.l	d5,d4			;���������炷
		sub.l	d5,dLEN			;���������炷
	while	ne
	moveq.l	#0,d0
	goto	dataout_dma_end		;�I��

;�t�F�[�Y�s��v
dataout_dma_phase:
	moveq.l	#-3,d0
	goto	dataout_dma_abort	;�]�����~

;DMA�G���[����
;DMA���]���I�����Ă��Ȃ�
dataout_dma_error:
	moveq.l	#-2,d0
	goto	dataout_dma_abort	;�]�����~

;+++++ BUG +++++
;�ǂ�������Q�Ƃ���Ă��Ȃ�
	moveq.l	#-1,d0
;+++++ BUG +++++
;�]�����~
dataout_dma_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(a2)	;DMA�]�����~
;�I��
dataout_dma_end:
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)���s
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a2.l:DMA�`�����l���x�[�X�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
datain_dma:
	push	d1/d2/dLEN/d4/d5/aBUF
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
	move.b	#DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
;256�o�C�g���]������
	do
		if	<cmp.l #256,dLEN>,hi
			move.l	#256,d5
		else
			move.l	dLEN,d5
		endif
	;<dLEN.l:�c��̃f�[�^�̒���
	;<d5.l:����]�����钷��
		move.l	aBUF,DMAC_MAR(aDMAC)	;�o�b�t�@�̃A�h���X
		move.w	d5,DMAC_MTC(aDMAC)	;����]�����钷��
	datain_dma_continue:
	;FIFO����łȂ��Ȃ�܂ő҂�
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,datain_dma_phase	;�t�F�[�Y�s��v
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;�]���J�n
		move.b	#-1,DMAC_CSR(aDMAC)	;DMAC_CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;�]���J�n
		nop
		nop
		nop
		nop
		nop
	;�]���I����҂�
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,datain_dma_phase	;�t�F�[�Y�s��v
			break	<btst.b #SPC_INTS_CC_BIT,SPC_INTS(aSPC)>,ne	;�]���I��
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
	;SPC�܂���DMA���]���I������
	;+++++ BUG +++++
	;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
	;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
		goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,datain_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(aDMAC)>,ne,datain_dma_error	;DMA�G���[����
		goto	<tst.w DMAC_MTC(aDMAC)>,ne,datain_dma_error	;DMA���]���I�����Ă��Ȃ�
		adda.l	d5,aBUF			;�A�h���X�𑝂₷
		sub.l	d5,d4			;���������炷
		sub.l	d5,dLEN			;���������炷
	while	ne
	moveq.l	#0,d0
	goto	datain_dma_end		;�I��

;�t�F�[�Y�s��v
datain_dma_phase:
	moveq.l	#-3,d0
	goto	datain_dma_abort	;�]�����~

;DMA�G���[����
;DMA���]���I�����Ă��Ȃ�
datain_dma_error:
	moveq.l	#-2,d0
	goto	datain_dma_abort	;�]�����~

;+++++ BUG +++++
;�ǂ�������Q�Ƃ���Ă��Ȃ�
	moveq.l	#-1,d0
;+++++ BUG +++++
;�]�����~
datain_dma_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA�]�����~
;�I��
datain_dma_end:
	pop
	rts


  .elif SCSI_BIOS_LEVEL<=10


;----------------------------------------------------------------
;SCSI�o��(DMA�]��)
;	MC68040�܂���MC68060�̂Ƃ��̓f�[�^�L���b�V�����v�b�V�����Ă���Ăяo���K�v������
;<dLEN.l:����
;<aBUF.l:�A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,���̑�=INTS
dataout_transfer:
	push	dLEN/aBUF
;������0�̂Ƃ�256�ƌ��Ȃ�
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;�������Z�b�g����
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1��҂�
	do
	while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
;�]���J�n
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	dataout_dma		;SCSI�o��(DMA�]��)���s
	if	<tst.l d0>,eq
	;���荞�݂�҂�
		do
			move.b	SPC_INTS(aSPC),d0
		while	eq
		move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
		if	<cmp.b #SPC_INTS_CC,d0>,eq
			moveq.l	#0,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
datain_transfer:
	push	dLEN/aBUF
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;������0�̂Ƃ�256�ƌ��Ȃ�
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;�������Z�b�g����
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
;�]���J�n
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	datain_dma		;SCSI����(DMA�]��)���s
	if	<tst.l d0>,eq
	;���荞�݂�҂�
		do
			move.b	SPC_INTS(aSPC),d0
		while	eq
		move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
		if	<cmp.b #SPC_INTS_CC,d0>,eq
			moveq.l	#0,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)���s
datain_dma:
	push	d1/d2/a0/a3
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
~ocr = DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
	goto	dataio_dma_common	;��������SCSI���o��(DMA�]��)���s����

;----------------------------------------------------------------
;SCSI�o��(DMA�]��)���s
dataout_dma:
	push_again
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
~ocr = DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
;----------------------------------------------------------------
;��������SCSI���o��(DMA�]��)���s����
dataio_dma_common:
	bsr	cache_flush		;DMA�]���J�n���O�̃L���b�V���t���b�V��
aDMAC	reg	a0
;DMA��ݒ肷��
	lea.l	DMAC_1_BASE,aDMAC
	st.b	DMAC_CSR(aDMAC)		;DMAC_CSR���N���A
	clr.w	DMAC_BTC(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;��x�ɓ]�����钷�������߂�
	moveq.l	#0,d2
	move.w	#256,d2
	if	<tst.b SRAM_SCSI_MODE>,mi	;SRAM_SCSI_BLOCK_BIT �u���b�N
		moveq.l	#0,d2
		move.w	BIOS_SCSI_BLOCK_SIZE.l,d2	;SCSI�@��̃u���b�N�T�C�Y
	endif
;�o�[�X�g�ɂ��邩
	if	<btst.b #SRAM_SCSI_BURST_BIT,SRAM_SCSI_MODE>,ne	;�o�[�X�g
	;�O���]���v���ɂ���
	;DMA��REQ1��SPC��DREQ�Ɍq�����Ă���̂�X68030����
~dcr = DMAC_NO_HOLD_CYCLE^DMAC_BURST_TRANSFER
~ocr = DMAC_AUTO_REQUEST_MAX^DMAC_EXTERNAL_REQUEST
		eori.w	#(~dcr<<8)|~ocr,d1
	endif
;DMAC_DCR��DMAC_OCR��ݒ肷��
	move.w	d1,DMAC_DCR(aDMAC)	;DMAC_DCR��DMAC_OCR
;���͂Əo�͂ŕ��򂷂�
aINTS	reg	a3
	lea.l	SPC_INTS(aSPC),aINTS
	goto	<tst.b d1>,mi,dataio_dma_input	;pl=DMAC_MEMORY_TO_DEVICE,mi=DMAC_DEVICE_TO_MEMORY
						;����
;�o��
dataio_dma_output:
	do
	;<dLEN.l:����̎c��̃f�[�^�̒���
	;<aBUF.l:����̃o�b�t�@�̃A�h���X
		goto	<cmp.l d2,dLEN>,ls,dataio_dma_output_last	;�c��1�`�u���b�N�T�C�Y
	dataio_dma_output_start:
	;<d2.l:����]�����钷��
	;����̃o�b�t�@�̃A�h���X�ƍ���]�����钷����DMA�ɐݒ肷��
		move.l	aBUF,DMAC_MAR(aDMAC)	;�o�b�t�@�̃A�h���X
		move.w	d2,DMAC_MTC(aDMAC)	;����]�����钷��
	dataio_dma_output_continue:
	;FIFO����ɂȂ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;REQ=1��҂�
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
	;DMA�]���J�n
		st.b	DMAC_CSR(aDMAC)		;CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
		tst.b	(aINTS)			;��ǂ݁H
	;DMA�]���I����҂�
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;�G���[���Ȃ����m�F����
		move.b	DMAC_CER(aDMAC),d0
		goto	ne,dataio_dma_output_error	;DMA�G���[����
	;�c��̃f�[�^�̒�����0�ɂȂ�܂ŌJ��Ԃ�
		adda.l	d2,aBUF			;����̃o�b�t�@�̃A�h���X
		sub.l	d2,dLEN			;����̎c��̃f�[�^�̒���
	while	ne
	moveq.l	#0,d0
dataio_dma_output_end:
;+++++ BUG +++++
;DMAC_DAR��SASI�ɖ߂��Ă��Ȃ�
;+++++ BUG +++++
	pop_test
	rts

;�c��1�`�u���b�N�T�C�Y
dataio_dma_output_last:
	move.l	dLEN,d2			;����]�����钷���͎c��̃f�[�^�̒���
	goto	dataio_dma_output_start

;DMA�G���[����
dataio_dma_output_error:
;+++++ BUG +++++
;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
	goto	<btst.l #1,d0>,ne,dataio_dma_output_continue
;+++++ BUG +++++
;�o�X�G���[�ȊO��DMA�G���[
	moveq.l	#-1,d0
	goto	dataio_dma_output_end

;SPC���荞�݂���
dataio_interrupted:
	move.b	SPC_INTS(aSPC),d0
	goto	<cmpi.b #SPC_INTS_CC,d0>,ne,dataio_dma_output_abort	;SPC���]���I�����Ă��Ȃ��B�]�����~
;SPC���]���I������
	moveq.l	#0,d0
	goto	<tst.w DMAC_MTC(aDMAC)>,eq,dataio_dma_output_abort	;DMA���]���I�������B�]�����~
;SPC�͓]���I��������DMA���]���I�����Ă��Ȃ�
	moveq.l	#-2,d0
;�]�����~
dataio_dma_output_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA�]�����~
	goto	dataio_dma_output_end

;�c��1�`�u���b�N�T�C�Y
dataio_dma_input_last:
	move.l	dLEN,d2			;����]�����钷���͎c��̃f�[�^�̒���
	goto	dataio_dma_input_start

;����
dataio_dma_input:
	do
	;<dLEN.l:����̎c��̃f�[�^�̒���
	;<aBUF.l:����̃o�b�t�@�̃A�h���X
		goto	<cmp.l d2,dLEN>,ls,dataio_dma_input_last	;�c��1�`�u���b�N�T�C�Y
	dataio_dma_input_start:
	;<d2.l:����]�����钷��
	;����̃o�b�t�@�̃A�h���X�ƍ���]�����钷����DMA�ɐݒ肷��
		move.l	aBUF,DMAC_MAR(aDMAC)	;�o�b�t�@�̃A�h���X
		move.w	d2,DMAC_MTC(aDMAC)	;����]�����钷��
	dataio_dma_input_continue:
	;FIFO����łȂ��Ȃ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;DMA�]���J�n
		st.b	DMAC_CSR(aDMAC)		;CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
		tst.b	(aINTS)			;��ǂ݁H
	;DMA�]���I����҂�
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC���荞�݂���
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;�G���[���Ȃ����m�F����
		move.b	DMAC_CER(aDMAC),d0
		goto	ne,dataio_dma_input_error	;DMA�G���[����
	;�c��̃f�[�^�̒�����0�ɂȂ�܂ŌJ��Ԃ�
		adda.l	d2,aBUF			;����̃o�b�t�@�̃A�h���X
		sub.l	d2,dLEN			;����̎c��̃f�[�^�̒���
	while	ne
	moveq.l	#0,d0
dataio_dma_input_end:
;+++++ BUG +++++
;DMAC_DAR��SASI�ɖ߂��Ă��Ȃ�
;+++++ BUG +++++
	pop
	rts

;DMA�G���[����
dataio_dma_input_error:
;+++++ BUG +++++
;DMAC_CER��5�r�b�g�̃G���[�R�[�h�̃r�b�g1�����e�X�g���ăo�X�G���[(�f�o�C�X�A�h���X)�ƌ��Ȃ��Ă���
;�o�X�G���[(�f�o�C�X�A�h���X)�̃G���[�R�[�h$0A�̃r�b�g1�����܂���1�������̂œ����Ă���H
	goto	<btst.l #1,d0>,ne,dataio_dma_input_continue
;+++++ BUG +++++
;�o�X�G���[�ȊO��DMA�G���[
	moveq.l	#-1,d0
	goto	dataio_dma_input_end


  .else


;----------------------------------------------------------------
;SCSI�o��(DMA�]��)
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,-1=DMA�G���[,���̑�=INTS
dataout_transfer:
	push	d1/d2/dLEN/a0/aBUF/a3
aDMAC	reg	a0
aINTS	reg	a3
	lea.l	DMAC_1_BASE,aDMAC
	lea.l	SPC_INTS(aSPC),aINTS
;�L���b�V���t���b�V��
	bsr	cache_flush
;������0�̂Ƃ�256�ƌ��Ȃ�
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)	;�f�[�^�̒���(����)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;�f�[�^�̒���(����)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;�f�[�^�̒���(���)
;REQ=1��҂�
	do
	while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
;SPC�]���J�n
	move.b	(aINTS),(aINTS)		;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;DCR��OCR�����߂�
;	X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;	DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
~ocr = DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
    .if SCSIEXROM==0
	ifand	<isX68030>,eq,<btst.b #SRAM_SCSI_BURST_BIT,SRAM_SCSI_MODE>,ne	;����SCSI����X68030���o�[�X�g
~dcr = DMAC_NO_HOLD_CYCLE^DMAC_BURST_TRANSFER
~ocr = DMAC_AUTO_REQUEST_MAX^DMAC_EXTERNAL_REQUEST
		eori.w	#(~dcr<<8)|~ocr,d1
	endif
    .endif
;DMAC��ݒ肷��
	st.b	DMAC_CSR(aDMAC)		;CSR���N���A
	clr.w	DMAC_BTC(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	move.w	d1,DMAC_DCR(aDMAC)	;DMAC_DCR,DMAC_OCR
	moveq.l	#SPC_DREG,d0
	add.l	aSPC,d0
	move.l	d0,DMAC_DAR(aDMAC)	;DAR��DREG��ݒ�
;�u���b�N�̒��������߂�
	move.l	#256,d2
	if	<tst.b SRAM_SCSI_MODE>,mi	;SRAM_SCSI_BLOCK_BIT
		move.w	BIOS_SCSI_BLOCK_SIZE.l,d2	;SCSI�@��̃u���b�N�T�C�Y
	endif
;<d2.l:�u���b�N�̒���
	do
	;<dLEN.l:�u���b�N�J�n���̑S�̂̎c��̒���
	;<aBUF.l:�u���b�N�J�n���̃f�[�^�̃A�h���X
	;�Ō�̃u���b�N�̒����𒲐�����
		if	<cmp.l dLEN,d2>,hi
			move.l	dLEN,d2
		endif
	;<d2.l:�u���b�N�̒���
	dataout_transfer_continue:
	;FIFO����ɂȂ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,dataout_transfer_finish	;SPC����I��
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;�f�[�^�̃A�h���X�ƃu���b�N�̎c��̒������v�Z����
		moveq.l	#0,d0
		move.b	SPC_TCH(aSPC),d0	;�f�[�^�̒���(���)
		swap.w	d0
		move.b	SPC_TCM(aSPC),d0	;�f�[�^�̒���(����)
		lsl.w	#8,d0
		move.b	SPC_TCL(aSPC),d0	;�f�[�^�̒���(����)
	;<d0.l:�S�̂̎c��̒���
		sub.l	dLEN,d0			;-(�u���b�N�̓]����������)=(�S�̂̎c��̒���)-(�u���b�N�J�n���̑S�̂̎c��̒���)
	;<d0.l:-(�u���b�N�̓]����������)
		move.l	aBUF,d1
		sub.l	d0,d1			;(�f�[�^�̃A�h���X)=(�u���b�N�J�n���̃f�[�^�̃A�h���X)+(�u���b�N�̓]����������)
	;<d1.l:�f�[�^�̃A�h���X
		add.l	d2,d0			;(�u���b�N�̎c��̒���)=(�u���b�N�̒���)-(�u���b�N�̓]����������)
	;<d0.l:�u���b�N�̎c��̒���
		st.b	DMAC_CSR(aDMAC)		;CSR���N���A
		move.l	d1,DMAC_MAR(aDMAC)	;�f�[�^�̃A�h���X
		move.w	d0,DMAC_MTC(aDMAC)	;�u���b�N�̎c��̒���
	;REQ=1��҂�
		do
			goto	<tst.b (aINTS)>,ne,dataout_transfer_finish	;SPC����I��
		while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
	;DMA�]���J�n
		st.b	DMAC_CSR(aDMAC)		;CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
		tst.b	(aINTS)			;��ǂ�
	;DMA����I����҂�
		do
			goto	<tst.b (aINTS)>,ne,dataout_transfer_finish	;SPC����I��
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;DMA����I��
		move.b	DMAC_CER(aDMAC),d0
		if	ne			;DMA�G���[����
			goto	<cmp.b #DMAC_BUS_ERROR_DEVICE,d0>,eq,dataout_transfer_continue	;�f�o�C�X�A�h���X�̃o�X�G���[�͌p��
		;�f�o�C�X�A�h���X�̃o�X�G���[�ȊO��DMA�G���[
		;!!! SPC�̌�n�������Ă��Ȃ��B�n���O�A�b�v������
			moveq.l	#-1,d0
			goto	dataout_transfer_end

		endif
	;DMA�G���[�Ȃ�
	;�f�[�^�̃A�h���X�ƑS�̂̎c��̒������X�V����
		adda.l	d2,aBUF			;(�f�[�^�̃A�h���X)+=(�u���b�N�̒���)
		sub.l	d2,dLEN			;(�S�̂̎c��̒���)-=(�u���b�N�̒���)
	while	ne			;�S�̂̎c��̒�����0�ɂȂ�܂ŌJ��Ԃ�
;SPC����I��
dataout_transfer_finish:
;SPC�̌�n��
	moveq.l	#0,d0
	do
		move.b	(aINTS),d0
	while	eq
	move.b	d0,(aINTS)		;INTS���N���A
	if	<cmp.b #SPC_INTS_CC,d0>,eq	;SPC�]���I��
		moveq.l	#0,d0
	endif
;DMAC�̌�n��
	if	<tst.w DMAC_MTC(aDMAC)>,ne	;MTC��0�łȂ�
		moveq.l	#-2,d0
	endif
	if	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC�BDMA���]���I�����Ă��Ȃ�
		move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA�]�����~
	endif
;�I��
dataout_transfer_end:
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)
;<dLEN.l:�f�[�^�̒���
;<aBUF.l:�o�b�t�@�̃A�h���X
;<a6.l:SPC�x�[�X�A�h���X
;>d0.l:0=����I��,���̑�=INTS
datain_transfer:
	push	dLEN/aBUF
;������0�̂Ƃ�256�ƌ��Ȃ�
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;�t�F�[�Y���Z�b�g����
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;�������Z�b�g����
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)	;�f�[�^�̒���(����)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;�f�[�^�̒���(����)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;�f�[�^�̒���(���)
;�]���J�n
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	datain_dma		;SCSI����(DMA�]��)���s
	if	<tst.l d0>,eq
	;���荞�݂�҂�
		do
			move.b	SPC_INTS(aSPC),d0
		while	eq
		move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTS���N���A
		if	<cmp.b #SPC_INTS_CC,d0>,eq
			moveq.l	#0,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;SCSI����(DMA�]��)���s
datain_dma:
	push	d1/d2/a0/a3
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
;X68000��SPC��DREQ��DMAC��REQ1�Ɍq�����Ă��Ȃ�
;DREQ���g����DTACK�������̂ŃI�[�g���N�G�X�g�ő呬�x��p����
~ocr = DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
	bsr	cache_flush		;DMA�]���J�n���O�̃L���b�V���t���b�V��
aDMAC	reg	a0
;DMA��ݒ肷��
	lea.l	DMAC_1_BASE,aDMAC
	st.b	DMAC_CSR(aDMAC)		;DMAC_CSR���N���A
	clr.w	DMAC_BTC(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;��x�ɓ]�����钷�������߂�
	moveq.l	#0,d2
	move.w	#256,d2
	if	<tst.b SRAM_SCSI_MODE>,mi	;SRAM_SCSI_BLOCK_BIT �u���b�N
		moveq.l	#0,d2
		move.w	BIOS_SCSI_BLOCK_SIZE.l,d2	;SCSI�@��̃u���b�N�T�C�Y
	endif
;�o�[�X�g�ɂ��邩
    .if SCSIEXROM==0
	ifand	<isX68030>,eq,<btst.b #SRAM_SCSI_BURST_BIT,SRAM_SCSI_MODE>,ne	;����SCSI����X68030���o�[�X�g
~dcr = DMAC_NO_HOLD_CYCLE^DMAC_BURST_TRANSFER
~ocr = DMAC_AUTO_REQUEST_MAX^DMAC_EXTERNAL_REQUEST
		eori.w	#(~dcr<<8)|~ocr,d1
	endif
    .endif
;DMAC_DCR��DMAC_OCR��ݒ肷��
	move.w	d1,DMAC_DCR(aDMAC)	;DMAC_DCR��DMAC_OCR
aINTS	reg	a3
	lea.l	SPC_INTS(aSPC),aINTS
	do
	;<dLEN.l:����̎c��̃f�[�^�̒���
	;<aBUF.l:����̃o�b�t�@�̃A�h���X
		if	<cmp.l d2,dLEN>,ls	;�c��1�`�u���b�N�T�C�Y
			move.l	dLEN,d2			;����]�����钷���͎c��̃f�[�^�̒���
		endif
	;<d2.l:����]�����钷��
	;����̃o�b�t�@�̃A�h���X�ƍ���]�����钷����DMA�ɐݒ肷��
		move.l	aBUF,DMAC_MAR(aDMAC)	;�o�b�t�@�̃A�h���X
		move.w	d2,DMAC_MTC(aDMAC)	;����]�����钷��
	datain_dma_continue:
	;FIFO����łȂ��Ȃ�܂ő҂�
		do
			goto	<tst.b (aINTS)>,ne,datain_dma_interrupted	;SPC���荞�݂���
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;DMA�]���J�n
		st.b	DMAC_CSR(aDMAC)		;CSR���N���A
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
		tst.b	(aINTS)			;��ǂ�
	;DMA�]���I����҂�
		do
			goto	<tst.b (aINTS)>,ne,datain_dma_interrupted	;SPC���荞�݂���
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;�G���[���Ȃ����m�F����
		move.b	DMAC_CER(aDMAC),d0
		goto	ne,datain_dma_error	;DMA�G���[����
	;�c��̃f�[�^�̒�����0�ɂȂ�܂ŌJ��Ԃ�
		adda.l	d2,aBUF			;����̃o�b�t�@�̃A�h���X
		sub.l	d2,dLEN			;����̎c��̃f�[�^�̒���
	while	ne
	moveq.l	#0,d0
datain_dma_end:
;DMAC_DAR��SASI�ɖ߂�
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts

;DMA�G���[����
;<d0.b:DMAC_CER
datain_dma_error:
	goto	<cmp.b #DMAC_BUS_ERROR_DEVICE,d0>,eq,datain_dma_continue	;�o�X�G���[
;�o�X�G���[�ȊO��DMA�G���[
	moveq.l	#-1,d0
	goto	datain_dma_end

;SPC���荞�݂���
datain_dma_interrupted:
	move.b	SPC_INTS(aSPC),d0
	goto	<cmpi.b #SPC_INTS_CC,d0>,ne,datain_dma_abort	;SPC���]���I�����Ă��Ȃ��B�]�����~
;SPC���]���I������
	moveq.l	#0,d0
	goto	<tst.w DMAC_MTC(aDMAC)>,eq,datain_dma_abort	;DMA���]���I�������B�]�����~
;SPC�͓]���I��������DMA���]���I�����Ă��Ȃ�
	moveq.l	#-2,d0
;�]�����~
datain_dma_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA�]�����~
	goto	datain_dma_end


  .endif


;----------------------------------------------------------------
;	https://twitter.com/kamadox/status/1204687543200972805
;	SUPER����Compact�܂ł̓���SCSI��DMA�]�����g���Ă��邪�ASPC��DREQ��DMA�R���g���[���Ɍq�����Ă��炸�A
;	�����DTACK��BERR�œ]���̃^�C�~���O�𐧌䂵�Ă���B
;                                                                                                
;                                      [X68000 XVI Compact]                                      
;                                                                                                
;             MC68HC000             DOSA               HD63450                                   
;          +-------------+     +-------------+     +-------------+                               
;          |         BERR|-----|BERR   BEC0/1|-----|BEC0/1   REQ1|--+                            
;          |        DTACK|--+  +-------------+  +--|DTACK        |  |                            
;          +-------------+  |        ASA        |  +-------------+  |                            
;                           |  +-------------+  |       PEDEC       |                            
;                           +--|MPUDTACK     |  |  +-------------+  |      MB89352               
;                              |  +--DMADTACK|--+  |        HDREQ|--+  +-------------+           
;                              |  +-SYNCDTACK|-----|IOCDTK--SIREQ|-----|DREQ         |           
;                              +-------------+     +-------------+     +-------------+           
;                                                                                                
;                                             [X68030]                                           
;                                                                                                
;             MC68EC030             SAKI               HD63450                                   
;          +-------------+     +-------------+     +-------------+                               
;          |         BERR|-----|BERR   BEC0/1|-----|BEC0/1   REQ1|--+                            
;          |     DSACK0/1|--+  +-------------+  +--|DTACK        |  |                            
;          +-------------+  |       YUKI        |  +-------------+  |                            
;                           |  +-------------+  |       PEDEC       |                            
;                           +--|DSACK0/1     |  |  +-------------+  |      MB89352               
;                              |  +--DMADTACK|--+  |        HDREQ|- |  +-------------+           
;                              |  +-SYNCDTACK|-----|IOCDTK--SIREQ|--+--|DREQ         |           
;                              +-------------+     +-------------+     +-------------+           
;                                                                                                
;	DMA�R���g���[����SPC��DREG���A�N�Z�X����Ƃ�DREQ���O���]���v���Ƃ��Ďg���Ȃ��̂ŁA
;	�I�[�g���N�G�X�g�ő呬�x�ŃA�N�Z�X���āA�o�X��͂񂾂܂�DREQ�ƘA�����Ă���DTACK��҂B
;	��莞�ԓ��ɓ]���ł����A�o�X�G���[�ŋ����I���������Ă��A�]�����p������悤�Ƀv���O��������Ă���B
;	MO�Ȃǂ̒x���f�o�C�X�ւ̏������݂ŁA�o�X�G���[���鍐�����^�C�~���O�������ƁA
;	DMA�R���g���[������U�������߂悤�Ƃ����f�[�^��SPC�����M���Ă��܂����Ƃ�����B
;	���̂܂܌p������Ɠ����f�[�^���d�����đ��M�����B������SCSI BIOS�͂��ꂪ�����ŏ������݂Ɏ��s���邱�Ƃ��������B
;	�f�[�^�̏d���̓o�X�G���[�����������Ƃ�DMA�R���g���[����SPC�̃J�E���^���r���ē]�����ĊJ����ʒu��␳���邱�Ƃŉ���ł���B
;	�f���������FiloP.x��p���邩�AHuman68k version 3.0��FORMAT.X�Ńt�H�[�}�b�g�����n�[�h�f�B�X�N����N������Ƒ΍􂪎{�����B
;----------------------------------------------------------------



;--------------------------------------------------------------------------------
;	.include	sc08cache.s
;--------------------------------------------------------------------------------

  .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;DMA�]���J�n���O�̃L���b�V���t���b�V��
cache_flush:
    .if SCSI_BIOS_LEVEL<=10
	move.l	d0,-(sp)
	if	<cmpi.b #1,BIOS_MPU_TYPE.w>,hi
		.cpu	68030
		movec.l	cacr,d0
		or.w	#$0808,d0
		movec.l	d0,cacr
		and.w	#$F7F7,d0
		movec.l	d0,cacr
		.cpu	68000
	endif
	move.l	(sp)+,d0
    .else
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
			move.l	d0,-(sp)
			.cpu	68030
		;68030��cacr
		;| 15| 14| 13| 12| 11| 10|  9|  8|  7|  6|  5|  4|  3|  2|  1|  0|
		;|  0|  0| WA|DBE| CD|CED| FD| ED|  0|  0|  0|IBE| CI|CEI| FI| EI|
		;CD��CI��1���������ނƃL���b�V���N���A�ŏ��0�œǂݏo�����B0����������ł��Ӗ����Ȃ�
			movec.l	cacr,d0
			or.w	#$0808,d0
			movec.l	d0,cacr
			.cpu	68000
			move.l	(sp)+,d0
		else				;040/060
			.cpu	68040
			cpusha	bc
			.cpu	68000
		endif
	endif
    .endif
	rts
  .endif



;--------------------------------------------------------------------------------
;	.include	sc09sasi.s
;--------------------------------------------------------------------------------

  .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;SASI�n�[�h�f�B�X�N������������
dskini_all:
	push	d0-d4/a1/a6
	move.w	#$8000,d1
	moveq.l	#16-1,d2
	for	d2
		lea.l	0.w,a1
    .if SCSI_BIOS_LEVEL<=10
		bsr	scsi_43_B_DSKINI	;IOCS�R�[��$43 _B_DSKINI(SCSI)
    .else
		bsr	iocs_43_B_DSKINI	;IOCS�R�[��$43 _B_DSKINI
    .endif
		add.w	#1<<8,d1
	next
	pop
	rts
  .endif

  .if SCSI_BIOS_LEVEL<>10
;----------------------------------------------------------------
;SCSI�o�X�ɐڑ�����Ă���SASI�@���IOCS�R�[��$40�`$4F�ő���ł���悤�ɂ���
install_sasi_iocs:
	push	d0/d1/d2/d3/d4/a1/aSPC
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_SEEK,d1
	lea.l	iocs_40_B_SEEK(pc),a1	;IOCS�R�[��$40 _B_SEEK
	trap	#15
    .if SCSI_BIOS_LEVEL<=10
	move.l	d0,(BIOS_SCSI_OLD_SEEK)abs	;IOCS�R�[��$40 _B_SEEK�̌��̃x�N�^
    .else
	move.l	d0,(BIOS_SCSI_OLD_SEEK_16)abs	;IOCS�R�[��$40 _B_SEEK�̌��̃x�N�^
    .endif
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_VERIFY,d1
	lea.l	iocs_41_B_VERIFY(pc),a1	;IOCS�R�[��$41 _B_VERIFY
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_VERIFY)abs	;IOCS�R�[��$41 _B_VERIFY�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_DSKINI,d1
	lea.l	iocs_43_B_DSKINI(pc),a1	;IOCS�R�[��$43 _B_DSKINI
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_DSKINI)abs	;IOCS�R�[��$43 _B_DSKINI�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_DRVSNS,d1
	lea.l	iocs_44_B_DRVSNS(pc),a1	;IOCS�R�[��$44 _B_DRVSNS
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_DRVSNS)abs	;IOCS�R�[��$44 _B_DRVSNS�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_WRITE,d1
	lea.l	iocs_45_B_WRITE(pc),a1	;IOCS�R�[��$45 _B_WRITE
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_WRITE)abs	;IOCS�R�[��$45 _B_WRITE�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_READ,d1
	lea.l	iocs_46_B_READ(pc),a1	;IOCS�R�[��$46 _B_READ
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_READ)abs	;IOCS�R�[��$46 _B_READ�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_RECALI,d1
	lea.l	iocs_47_B_RECALI(pc),a1	;IOCS�R�[��$47 _B_RECALI
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_RECALI)abs	;IOCS�R�[��$47 _B_RECALI�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_ASSIGN,d1
	lea.l	iocs_48_B_ASSIGN(pc),a1	;IOCS�R�[��$48 _B_ASSIGN
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_ASSIGN)abs	;IOCS�R�[��$48 _B_ASSIGN�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_BADFMT,d1
	lea.l	iocs_4B_B_BADFMT(pc),a1	;IOCS�R�[��$4B _B_BADFMT
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_BADFMT)abs	;IOCS�R�[��$4B _B_BADFMT�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_FORMAT,d1
	lea.l	iocs_4D_B_FORMAT(pc),a1	;IOCS�R�[��$4D _B_FORMAT
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_FORMAT)abs	;IOCS�R�[��$4D _B_FORMAT�̌��̃x�N�^
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_EJECT,d1
	lea.l	iocs_4F_B_EJECT(pc),a1	;IOCS�R�[��$4F _B_EJECT
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_EJECT)abs	;IOCS�R�[��$4F _B_EJECT�̌��̃x�N�^
;SASI�n�[�h�f�B�X�N������������
	move.w	#$8000,d1
	moveq.l	#16-1,d2
	for	d2
		movea.l	#0,a1
		bsr	iocs_43_B_DSKINI	;IOCS�R�[��$43 _B_DSKINI
		add.w	#1<<8,d1
	next
	pop
	rts
  .endif

  .if SCSI_BIOS_LEVEL<>10

;----------------------------------------------------------------
;IOCS�R�[��$40 _B_SEEK �V�[�N
iocs_40_B_SEEK:
	move.l	(BIOS_SCSI_OLD_SEEK)abs,-(sp)	;IOCS�R�[��$40 _B_SEEK�̌��̃x�N�^
	push	d1/d4/a5
	lea.l	scsi_2D_S_SEEK(pc),a5	;SCSI�R�[��$2D _S_SEEK
	goto	iocs_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F�̏���

;----------------------------------------------------------------
;IOCS�R�[��$47 _B_RECALI �g���b�N0�ւ̃V�[�N
iocs_47_B_RECALI:
	move.l	(BIOS_SCSI_OLD_RECALI)abs,-(sp)	;IOCS�R�[��$47 _B_RECALI�̌��̃x�N�^
	push_again
	lea.l	scsi_2B_S_REZEROUNIT(pc),a5	;SCSI�R�[��$2B _S_REZEROUNIT
	goto	iocs_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F�̏���

;----------------------------------------------------------------
;IOCS�R�[��$48 _B_ASSIGN
iocs_48_B_ASSIGN:
	move.l	(BIOS_SCSI_OLD_ASSIGN)abs,-(sp)	;IOCS�R�[��$48 _B_ASSIGN�̌��̃x�N�^
	push_again
	lea.l	scsi_39_S_ASSIGN(pc),a5	;SCSI�R�[��$39 _S_ASSIGN
	goto	iocs_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F�̏���

;----------------------------------------------------------------
;IOCS�R�[��$4B _B_BADFMT �o�b�h�g���b�N���g�p�s�\�ɂ���
iocs_4B_B_BADFMT:
	move.l	(BIOS_SCSI_OLD_BADFMT)abs,-(sp)	;IOCS�R�[��$4B _B_BADFMT�̌��̃x�N�^
	push_again
	lea.l	scsi_38_S_BADFMT(pc),a5	;SCSI�R�[��$38 _S_BADFMT
	goto	iocs_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F�̏���

;----------------------------------------------------------------
;IOCS�R�[��$4D _B_FORMAT �����t�H�[�}�b�g
iocs_4D_B_FORMAT:
	move.l	(BIOS_SCSI_OLD_FORMAT)abs,-(sp)	;IOCS�R�[��$4D _B_FORMAT�̌��̃x�N�^
	push_again
	lea.l	scsi_37_S_FORMATB(pc),a5	;SCSI�R�[��$37 _S_FORMATB
	goto	iocs_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F�̏���

;----------------------------------------------------------------
;IOCS�R�[��$44 _B_DRVSNS
iocs_44_B_DRVSNS:
	move.l	(BIOS_SCSI_OLD_DRVSNS)abs,-(sp)	;IOCS�R�[��$44 _B_DRVSNS�̌��̃x�N�^
	push_again
	lea.l	scsi_24_S_TESTUNIT(pc),a5	;SCSI�R�[��$24 _S_TESTUNIT
;!!! ����ւ�bra�B�T�C�Y�������Ȃ��ƍ폜�����
	bra.w	iocs_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F�̏���

;----------------------------------------------------------------
;��������_B_SEEK�A_B_RECALI�A_B_ASSIGN�A_B_BADFMT�A_B_FORMAT�A_B_DRVSNS����
iocs_40_44_47_48_4b_4d_common:

  .else

;----------------------------------------------------------------
;IOCS�R�[��$40 _B_SEEK �V�[�N
scsi_40_B_SEEK:
	lea.l	scsi_2D_S_SEEK(pc),a0	;SCSI�R�[��$2D _S_SEEK
	goto	scsi_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F(SCSI)�̏���

;----------------------------------------------------------------
;IOCS�R�[��$47 _B_RECALI �g���b�N0�ւ̃V�[�N
scsi_47_B_RECALI:
	lea.l	scsi_2B_S_REZEROUNIT(pc),a0	;SCSI�R�[��$2B _S_REZEROUNIT
	goto	scsi_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F(SCSI)�̏���

;----------------------------------------------------------------
;IOCS�R�[��$48 _B_ASSIGN
scsi_48_B_ASSIGN:
	lea.l	scsi_39_S_ASSIGN(pc),a0	;SCSI�R�[��$39 _S_ASSIGN
	goto	scsi_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F(SCSI)�̏���

;----------------------------------------------------------------
;IOCS�R�[��$4B _B_BADFMT �o�b�h�g���b�N���g�p�s�\�ɂ���
scsi_4B_B_BADFMT:
	lea.l	scsi_38_S_BADFMT(pc),a0	;SCSI�R�[��$38 _S_BADFMT
	goto	scsi_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F(SCSI)�̏���

;----------------------------------------------------------------
;IOCS�R�[��$4D _B_FORMAT �����t�H�[�}�b�g
scsi_4D_B_FORMAT:
	lea.l	scsi_37_S_FORMATB(pc),a0	;SCSI�R�[��$37 _S_FORMATB
	goto	scsi_40_44_47_48_4b_4d_common	;IOCS�R�[��$40�`$4F(SCSI)�̏���

;----------------------------------------------------------------
;IOCS�R�[��$44 _B_DRVSNS
scsi_44_B_DRVSNS:
	lea.l	scsi_24_S_TESTUNIT(pc),a0	;SCSI�R�[��$24 _S_TESTUNIT
;----------------------------------------------------------------
;��������_B_SEEK�A_B_RECALI�A_B_ASSIGN�A_B_BADFMT�A_B_FORMAT�A_B_DRVSNS����
scsi_40_44_47_48_4b_4d_common:
	push	d1/d4/a5
	movea.l	a0,a5

  .endif

	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_40_44_47_48_4b_4d_not_hd	;HD�ł͂Ȃ�
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_40_44_47_48_4b_4d_not_sasi	;SASI�t���O���Z�b�g����Ă��Ȃ�
	jsr	(a5)			;SCSI�R�[�����Ă�
;<d0.l:0=����,-1=���s,���̑�=MSGIN<<16|STSIN

  .if SCSI_BIOS_LEVEL<>10

    .if SCSI_BIOS_LEVEL<=10
      .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASI�̃X�e�[�^�X�o�C�g�̈ꕔ�𖳎�����
      .endif
	goto	<tst.l d0>,ne,scsi_40_44_47_48_4b_4d_error
    .else
	goto	<btst.l #1,d0>,ne,scsi_40_44_47_48_4b_4d_error	;Check Condition
    .endif
	moveq.l	#0,d0
	pop_test
	addq.l	#4,sp			;���̏������Ă΂Ȃ�
	rts

scsi_40_44_47_48_4b_4d_error:
	ori.l	#$FFFFFF00,d0
	pop_test
	addq.l	#4,sp			;���̏������Ă΂Ȃ�
	rts

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_40_44_47_48_4b_4d_not_sasi:
;HD�ł͂Ȃ�
iocs_40_44_47_48_4b_4d_not_hd:
	pop
	rts				;���̏������Ă�

  .else

	goto	<btst.l #1,d0>,ne,scsi_40_44_47_48_4b_4d_error	;Check Condition
	moveq.l	#0,d0
scsi_40_44_47_48_4b_4d_end:
	pop
	rts

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_40_44_47_48_4b_4d_not_sasi:
	moveq.l	#-1,d0
scsi_40_44_47_48_4b_4d_error:
	ori.l	#$FFFFFF00,d0
	goto	scsi_40_44_47_48_4b_4d_end

  .endif

;----------------------------------------------------------------
;IOCS�R�[��$4F _B_EJECT �C�W�F�N�g�^�V�b�s���O
;<d1.w:
;	FD	$9000|FD-ID(0�`3)<<8|MFM(0�`1)<<6|RETRY(0�`1)<<5|SEEK(0�`1)<<4
;	HD	$8000|HD-ID(0�`15)<<8
;		HD-ID(0�`15)=SCSI-ID(0�`7)<<1|LUN(0�`1)
;>d0.l:
;	FD	�s��
;	HD	0�ȏ�=����,-1�ȉ�=���s
  .if SCSI_BIOS_LEVEL<>10
iocs_4F_B_EJECT:
	move.l	(BIOS_SCSI_OLD_EJECT)abs,-(sp)
  .else
scsi_4F_B_EJECT:
  .endif
	push	d1/d2/d3/d4/d5/d6/d7/a1/a4
	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_4f_not_hd	;HD�ł͂Ȃ�
  .endif
	move.l	d4,d1
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_4f_not_sasi	;SASI�t���O���Z�b�g����Ă��Ȃ�

  .if SCSI_BIOS_LEVEL<=4

	lea.l	BIOS_SASI_CAPACITY.l,a4	;SASI�n�[�h�f�B�X�N�̗e�ʂ̔z��B0=���m�F,10=10MB,20=20MB,40=40MB,128=��ڑ�
	move.l	d1,d0
	ror.w	#8,d0
	and.l	#15,d0			;HD-ID
	adda.l	d0,a4
	move.b	(a4),d0
	if	<btst.l #7,d0>,eq	;�ڑ�
		and.b	#$7F,d0
		if	ne			;�m�F�ς�
			move.l	#33*4*664,d2		;20MB�V�b�s���O�]�[��
		;!!! �s�v
    .if SCSI_BIOS_LEVEL<=0
			lea.l	sasi_20mb_shipping_parameter,a1	;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .else
			lea.l	sasi_20mb_shipping_parameter(pc),a1	;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .endif
			if	<cmp.b #20,d0>,ne	;20MB
				move.l	#33*8*664,d2		;40MB�V�b�s���O�]�[��
			;!!! �s�v
    .if SCSI_BIOS_LEVEL<=0
				lea.l	sasi_40mb_shipping_parameter,a1	;40MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .else
				lea.l	sasi_40mb_shipping_parameter(pc),a1	;40MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .endif
				if	<cmp.b #40,d0>,ne	;40MB
					move.l	#33*4*340,d2		;10MB�V�b�s���O�]�[��
				;!!! �s�v
    .if SCSI_BIOS_LEVEL<=0
					lea.l	sasi_10mb_shipping_parameter,a1	;10MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .else
					lea.l	sasi_10mb_shipping_parameter(pc),a1	;10MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .endif
				endif
			endif
		;!!! ROM 1.0�`1.2��SASI BIOS��_B_EJECT�̓V�b�s���O�]�[����SET DRIVE PARAMETER���Ă���SEEK���Ă���
			bsr	scsi_2D_S_SEEK		;SCSI�R�[��$2D _S_SEEK
		endif
	endif
;��ڑ��܂��͖��m�F
;+++++ BUG +++++
;����SASI�n�[�h�f�B�X�N���V�b�s���O�ł��Ȃ��Ȃ�
;	SASI�t���O���Z�b�g����Ă��Ȃ��Ƃ�����SASI�n�[�h�f�B�X�N���V�b�s���O���Ȃ���΂Ȃ�Ȃ��̂Ɍ��̏������Ă�ł��Ȃ�
;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_4f_not_sasi:
;+++++ BUG +++++
	pop_test
	addq.l	#4,sp			;���̏������Ă΂Ȃ�
	rts

;HD�ł͂Ȃ�
iocs_4f_not_hd:
	pop
	rts				;���̏������Ă�

;+++++ BUG +++++
;�ǂ�������Q�Ƃ���Ă��Ȃ�
	andi.w	#$F000,d1
	if	<cmp.w #$8000,d1>,eq
		movem.l	(sp)+,d1
		addq.l	#4,sp
		moveq.l	#0,d0
		rts

	endif
	movem.l	(sp)+,d1
	rts
;+++++ BUG +++++

  .else

	lea.l	BIOS_SASI_CAPACITY.w,a4	;SASI�n�[�h�f�B�X�N�̗e�ʂ̔z��B0=���m�F,10=10MB,20=20MB,40=40MB,128=��ڑ�
	move.w	d1,d0
	ror.w	#8,d0
	and.w	#15,d0			;HD-ID
	move.b	(a4,d0.w),d0
;!!! �s�v
	ifand	<tst.b d0>,pl,<>,ne
	;�ڑ��A�m�F�ς�
		move.l	#33*4*664,d2		;20MB�V�b�s���O�]�[��
		if	<cmp.b #20,d0>,ne
			move.l	#33*8*664,d2		;40MB�V�b�s���O�]�[��
			if	<cmp.b #40,d0>,ne
				move.l	#33*4*340,d2		;10MB�V�b�s���O�]�[��
				if	<cmp.b #10,d0>,ne
					goto	scsi_4f_end		;10MB/20MB/40MB�̂�����ł��Ȃ�
				endif
			endif
		endif
	;!!! ROM 1.0�`1.2��SASI BIOS��_B_EJECT�̓V�b�s���O�]�[����SET DRIVE PARAMETER���Ă���SEEK���Ă���
		bsr	scsi_2D_S_SEEK		;SCSI�R�[��$2D _S_SEEK
		moveq.l	#0,d0
	endif
;��ڑ��܂��͖��m�F
scsi_4f_end:

    .if SCSI_BIOS_LEVEL<=10

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_4f_not_sasi:
	pop
	rts

    .else

	pop_test
	addq.l	#4,sp			;���̏������Ă΂Ȃ�
	rts

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_4f_not_sasi:
;HD�ł͂Ȃ�
iocs_4f_not_hd:
	pop
	rts				;���̏������Ă�

    .endif

  .endif

;----------------------------------------------------------------
;IOCS�R�[��$46 _B_READ �ǂݏo��
;<d1.w:�h���C�u
;	HD	$8000|HD-ID(0�`15)<<8
;		HD-ID(0�`15)=SCSI-ID(0�`7)<<1|LUN(0�`1)
;	FD	$9000|FD-ID(0�`3)<<8|MFM(0�`1)<<6|RETRY(0�`1)<<5|SEEK(0�`1)<<4
;<d2.l:�ʒu
;	HD	���R�[�h�ԍ�
;	FD	���R�[�h��(0�`7)<<24|�V�����_�ԍ�(0�`)<<16|�w�b�h�ԍ�(0�`1)<<8|�Z�N�^�ԍ�(1�`)
;<d3.l:�o�C�g��
;<a1.l:�A�h���X
;>d0.l:����
;	HD	0�ȏ�=����,-1�ȉ�=���s�B$FFFFFF00|�G���[�R�[�h=���s
;	FD	ST0<<24|ST1<<16|ST2<<8|�V�����_�ԍ�
;----------------------------------------------------------------
;IOCS�R�[��$45 _B_WRITE ��������
;<d1.w:�h���C�u
;	HD	$8000|HD-ID(0�`15)<<8
;		HD-ID(0�`15)=SCSI-ID(0�`7)<<1|LUN(0�`1)
;	FD	$9000|FD-ID(0�`3)<<8|MFM(0�`1)<<6|RETRY(0�`1)<<5|SEEK(0�`1)<<4
;<d2.l:�ʒu
;	HD	���R�[�h�ԍ�
;	FD	���R�[�h��(0�`7)<<24|�V�����_�ԍ�(0�`)<<16|�w�b�h�ԍ�(0�`1)<<8|�Z�N�^�ԍ�(1�`)
;<d3.l:�o�C�g��
;<a1.l:�A�h���X
;>d0.l:����
;	HD	0�ȏ�=����,$FFFFFF00|STSIN=���s
;	FD	ST0<<24|ST1<<16|ST2<<8|�V�����_�ԍ�

  .if SCSI_BIOS_LEVEL<>10

iocs_46_B_READ:
	move.l	(BIOS_SCSI_OLD_READ)abs,-(sp)	;IOCS�R�[��$46 _B_READ�̌��̃x�N�^
	push	d1/d2/d3/d4/d5/d6/a1/a2/a5
	lea.l	scsi_21_S_READ(pc),a5	;SCSI�R�[��$21 _S_READ
	goto	iocs_45_46_common	;��������_B_READ�A_B_WRITE����

iocs_45_B_WRITE:
	move.l	(BIOS_SCSI_OLD_WRITE)abs,-(sp)	;IOCS�R�[��$45 _B_WRITE�̌��̃x�N�^
	push_again
	lea.l	scsi_22_S_WRITE(pc),a5	;SCSI�R�[��$22 _S_WRITE
;!!! ����ւ�bra�B�T�C�Y�������Ȃ��ƍ폜�����
	bra.w	iocs_45_46_common		;��������_B_READ�A_B_WRITE����

;��������_B_READ�A_B_WRITE����
;<a5.l:_S_READ�܂���_S_WRITE
iocs_45_46_common:

  .else

scsi_46_B_READ:
	lea.l	scsi_21_S_READ(pc),a0	;SCSI�R�[��$21 _S_READ
	goto	scsi_45_46_common	;��������_B_READ(SCSI)�A_B_WRITE(SCSI)����

scsi_45_B_WRITE:
	lea.l	scsi_22_S_WRITE(pc),a0	;SCSI�R�[��$22 _S_WRITE
;��������_B_READ�A_B_WRITE����
;<a0.l:_S_READ�܂���_S_WRITE
scsi_45_46_common:
	push	d1/d2/d3/d4/d5/d6/a1/a2/a5
	movea.l	a0,a5			;_S_READ�܂���_S_WRITE

  .endif

	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_45_46_not_hd	;HD�ł͂Ȃ�
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_45_46_not_sasi	;SASI�t���O���Z�b�g����Ă��Ȃ�
	move.l	d3,d6			;�c��̃o�C�g��
	do
		move.l	d6,d3			;�c��̃o�C�g��
		add.l	#255,d3
		lsr.l	#8,d3			;����̃��R�[�h���B256�o�C�g/���R�[�h
		if	<cmp.l #256,d3>,hi
			move.l	#256,d3			;��x�ɓ]�����郌�R�[�h���̏��
		endif
		moveq.l	#0,d5			;���R�[�h���B0=256�o�C�g/���R�[�h
		jsr	(a5)			;_S_READ�܂���_S_WRITE
  .if SCSI_BIOS_LEVEL<=3
	;+++++ BUG +++++
	;_S_READ�܂���_S_WRITE���G���[��z�ŕԂ��Ȃ��ƌ��o�ł��Ȃ�
	;+++++ BUG +++++
		goto	ne,scsi_45_46_error
  .elif SCSI_BIOS_LEVEL<=4
		andi.l	#$FFFFFF1E,d0		;SASI�̃X�e�[�^�X�o�C�g�̈ꕔ�𖳎�����
		goto	<tst.l d0>,ne,scsi_45_46_error
  .else
		goto	<btst.l #1,d0>,ne,scsi_45_46_error	;Check Condition
  .endif
		add.l	d3,d2			;����̃��R�[�h�ԍ�
		move.l	d3,d1
		lsl.l	#8,d1			;����̃o�C�g��
		adda.l	d1,a1			;����̃A�h���X
		sub.l	d1,d6			;����̎c��̃o�C�g��
	while	hi

  .if SCSI_BIOS_LEVEL<>10

	pop_test
	addq.l	#4,sp			;���̏������Ă΂Ȃ�
	moveq.l	#0,d0
	rts

scsi_45_46_error:
	pop_test
	addq.l	#4,sp			;���̏������Ă΂Ȃ�
	ori.l	#$FFFFFF00,d0
	rts

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_45_46_not_sasi:
;HD�ł͂Ȃ�
iocs_45_46_not_hd:
	pop
	rts				;���̏������Ă�

  .else

	moveq.l	#0,d0
scsi_45_46_end:
	pop
	rts

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_45_46_not_sasi:
	moveq.l	#-1,d0
scsi_45_46_error:
	ori.l	#$FFFFFF00,d0
	goto	scsi_45_46_end

  .endif

;----------------------------------------------------------------
;IOCS�R�[��$41 _B_VERIFY �x���t�@�C
;<d1.w:�h���C�u
;	HD	$8000|HD-ID(0�`15)<<8
;		HD-ID(0�`15)=SCSI-ID(0�`7)<<1|LUN(0�`1)
;	FD	$9000|FD-ID(0�`3)<<8|MFM(0�`1)<<6|RETRY(0�`1)<<5|SEEK(0�`1)<<4
;<d2.l:�ʒu
;	HD	���R�[�h�ԍ�
;	FD	���R�[�h��(0�`7)<<24|�V�����_�ԍ�(0�`)<<16|�w�b�h�ԍ�(0�`1)<<8|�Z�N�^�ԍ�(1�`)
;<d3.l:�o�C�g��
;<a1.l:�A�h���X
;>d0.l:����
;	HD	0=��v,-2=�s��v
;	FD	ST0<<24|PCN<<16
  .if SCSI_BIOS_LEVEL<>10
iocs_41_B_VERIFY:
  .else
scsi_41_B_VERIFY:
  .endif
	link.w	a4,#-256
	push	d1/d2/d3/d4/d5/d6/a1/a2
	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_b_verify_not_hd	;HD�ł͂Ȃ�
	move.l	d4,d1
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_b_verify_not_sasi	;SASI�t���O���Z�b�g����Ă��Ȃ�
	movea.l	a1,a2			;�A�h���X
	move.l	d3,d6			;�c��̃o�C�g��
	do
		move.l	d6,d3			;�c��̃o�C�g��
		if	<cmp.l #256,d3>,cc
			move.l	#256,d3			;��x�ɓǂݍ��ރo�C�g���̏���B256�o�C�g/���R�[�h
		endif
	;!!! �X�[�p�[�o�C�U�X�^�b�N�ɓǂݍ���ł���B���[�J��������������Ƃ�DMA���͂��Ƃ͌���Ȃ�
		lea.l	-256(a4),a1
  .if SCSI_BIOS_LEVEL<>10
		bsr	iocs_46_B_READ		;IOCS�R�[��$46 _B_READ �ǂݏo��
  .else
		bsr	scsi_46_B_READ		;IOCS�R�[��$46 _B_READ(SCSI) �ǂݏo��
  .endif
		move.l	d3,d5
		subq.l	#1,d5
		for	d5
			cmpm.b	(a1)+,(a2)+
			goto	ne,scsi_b_verify_error	;�s��v
		next
		addq.l	#1,d2			;����̃��R�[�h�ԍ�
		sub.l	d3,d6			;����̎c��̃o�C�g��
	while	hi

  .if SCSI_BIOS_LEVEL<>10

	pop_test
	unlk	a4
	moveq.l	#0,d0			;��v
	rts				;���̏������Ă΂Ȃ�

scsi_b_verify_error:
	moveq.l	#-2,d0			;�s��v
	pop_test
	unlk	a4
	ori.l	#$FFFFFF00,d0		;-2�̂܂�
	rts				;���̏������Ă΂Ȃ�

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_b_verify_not_sasi:
;HD�ł͂Ȃ�
iocs_b_verify_not_hd:
	pop
	unlk	a4
	move.l	(BIOS_SCSI_OLD_VERIFY)abs,-(sp)	;IOCS�R�[��$41 _B_VERIFY�̌��̃x�N�^
	rts				;���̏������Ă�

  .else

	moveq.l	#0,d0			;��v
scsi_b_verify_end:
	pop
	unlk	a4
	rts

scsi_b_verify_error:
	moveq.l	#-2,d0			;�s��v
	ori.l	#$FFFFFF00,d0		;-2�̂܂�
	goto	scsi_b_verify_end

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_b_verify_not_sasi:
	moveq.l	#-1,d0
	goto	scsi_b_verify_end

  .endif

;----------------------------------------------------------------
;IOCS�R�[��$43 _B_DSKINI ������
;<d1.w:�h���C�u
;	HD	$8000|HD-ID(0�`15)<<8
;		HD-ID(0�`15)=SCSI-ID(0�`7)<<1|LUN(0�`1)
;	FD	$9000|FD-ID(0�`3)<<8
;<d2.w:
;	HD	�Ȃ�
;	FD	���[�^�[��~����(10ms�P��)�B0=�f�t�H���g(2�b)
;<a1.l:
;	HD	�h���C�u�p�����[�^�̃A�h���X�B0=�f�t�H���g
;	FD	Specify�R�}���h�̃A�h���X�B0=�f�t�H���g
;>d0.l:����
;	HD	0=����,$FFFFFF00|STSIN=���s
;	FD	ST3<<24|�s��
  .if SCSI_BIOS_LEVEL<>10
iocs_43_B_DSKINI:
  .else
scsi_43_B_DSKINI:
  .endif
	link.w	a4,#-256
  .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;d5/a2��j�󂵂Ă���
	push	d1/d2/d3/d4/a1/a5
;+++++ BUG +++++
  .else
	push	d1/d2/d3/d4/d5/a1/a2/a5
  .endif
	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_b_dskini_not_hd	;HD�ł͂Ȃ�
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_b_dskini_not_sasi	;SASI�t���O���Z�b�g����Ă��Ȃ�
	move.l	a1,d0			;�������p�����[�^
	goto	eq,scsi_b_dskini_default	;�f�t�H���g�̃h���C�u�p�����[�^���g��
scsi_b_dskini_go:
	moveq.l	#10,d3			;�h���C�u�p�����[�^�̒����B10�o�C�g
	bsr	scsi_36_S_DSKINI	;SCSI�R�[��$36 _S_DSKINI

  .if SCSI_BIOS_LEVEL<>10

    .if SCSI_BIOS_LEVEL<=10
      .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASI�̃X�e�[�^�X�o�C�g�̈ꕔ�𖳎�����
      .endif
	goto	<tst.l d0>,ne,scsi_b_dskini_error	;���s
    .else
	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
    .endif
    .if SCSI_BIOS_LEVEL<=3
	;!!! ����bsr��$617E�œ͂���$61000080�ɂȂ��Ă���
	bsr.w	sasi_param_to_capacity	;�h���C�u�p�����[�^����SASI�n�[�h�f�B�X�N�̗e�ʂ����߂�
    .else
	bsr	sasi_param_to_capacity	;�h���C�u�p�����[�^����SASI�n�[�h�f�B�X�N�̗e�ʂ����߂�
    .endif
	moveq.l	#0,d0
	pop_test
	unlk	a4
	rts				;���̏������Ă΂Ȃ�

;���s
scsi_b_dskini_error:
	ori.l	#$FFFFFF00,d0
	pop_test
	unlk	a4
	rts				;���̏������Ă΂Ȃ�

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_b_dskini_not_sasi:
;HD�ł͂Ȃ�
iocs_b_dskini_not_hd:
	pop
	unlk	a4
	move.l	(BIOS_SCSI_OLD_DSKINI)abs,-(sp)	;IOCS�R�[��$43 _B_DSKINI�̌��̃x�N�^
	rts				;���̏������Ă�

  .else

	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
;�h���C�u�p�����[�^����SASI�n�[�h�f�B�X�N�̗e�ʂ����߂�
	lea.l	BIOS_SASI_CAPACITY.w,a5	;SASI�n�[�h�f�B�X�N�̗e�ʂ̔z��B0=���m�F,10=10MB,20=20MB,40=40MB,128=��ڑ�
	move.w	d1,d0
	ror.w	#8,d0
	and.w	#15,d0			;HD-ID
	adda.w	d0,a5
	moveq.l	#40,d0			;40MB
	if	<cmpi.b #$07,3(a1)>,ne
		moveq.l	#20,d0			;20MB
		if	<cmpi.b #$02,4(a1)>,ne
			moveq.l	#10,d0			;10MB
		endif
	endif
	move.b	d0,(a5)
	moveq.l	#0,d0
scsi_b_dskini_end:
	pop
	unlk	a4
	rts

;SASI�t���O���Z�b�g����Ă��Ȃ�
scsi_b_dskini_not_sasi:
	moveq.l	#-1,d0
;Check Condition
scsi_b_dskini_error:
	ori.l	#$FFFFFF00,d0
	goto	scsi_b_dskini_end

  .endif

;�f�t�H���g�̃h���C�u�p�����[�^���g��
scsi_b_dskini_default:
	moveq.l	#10,d3			;�h���C�u�p�����[�^�̒����B10�o�C�g
  .if SCSI_BIOS_LEVEL<=4
;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)��ݒ肷��
    .if SCSI_BIOS_LEVEL<=0
	lea.l	sasi_20mb_shipping_parameter,a1	;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .else
	lea.l	sasi_20mb_shipping_parameter(pc),a1	;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
    .endif
  .else
;40MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)��ݒ肷��
	lea.l	sasi_40mb_shipping_parameter(pc),a1	;40MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
  .endif
	bsr	scsi_36_S_DSKINI	;SCSI�R�[��$36 _S_DSKINI
  .if SCSI_BIOS_LEVEL<=4
    .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASI�̃X�e�[�^�X�o�C�g�̈ꕔ�𖳎�����
    .endif
	goto	<tst.l d0>,ne,scsi_b_dskini_error
  .else  ;10<=SCSI_BIOS_LEVEL
	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
  .endif
;���R�[�h4����256�o�C�g�ǂݍ���
	lea.l	-256(a4),a1
	moveq.l	#$0400/256,d2
	moveq.l	#$0100/256,d3
	moveq.l	#0,d5			;256�o�C�g/���R�[�h
	bsr	scsi_21_S_READ		;SCSI�R�[��$21 _S_READ
  .if SCSI_BIOS_LEVEL<=4
    .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASI�̃X�e�[�^�X�o�C�g�̈ꕔ�𖳎�����
    .endif
	goto	<tst.l d0>,ne,scsi_b_dskini_error	;�ǂݍ��߂Ȃ�
  .else  ;10<=SCSI_BIOS_LEVEL
	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
  .endif
	lea.l	-256(a4),a2
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	sasi_10mb_drive_parameter,a1	;10MB�h���C�u�p�����[�^
    .else
	lea.l	sasi_10mb_drive_parameter(pc),a1	;10MB�h���C�u�p�����[�^
    .endif
	goto	<cmpi.l #'X68K',0.w(a2)>,ne,scsi_b_dskini_error	;���u����������Ă��Ȃ�
;���u����������Ă���
    .if SCSI_BIOS_LEVEL<=0
	lea.l	sasi_10mb_drive_parameter,a1	;10MB�h���C�u�p�����[�^
    .else
	lea.l	sasi_10mb_drive_parameter(pc),a1	;10MB�h���C�u�p�����[�^
    .endif
	move.l	4(a2),d0		;���R�[�h��
  .else  ;10<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #'X68K',(a2)+>,ne,scsi_b_dskini_error	;���u����������Ă��Ȃ�
;���u����������Ă���
	lea.l	sasi_10mb_drive_parameter(pc),a1	;10MB�h���C�u�p�����[�^
	move.l	(a2),d0			;���R�[�h��
  .endif
	goto	<cmp.l #33*4*310+1,d0>,cs,scsi_b_dskini_go	;10MB��309�V�����_����310�V�����_�܂�10MB�ƌ��Ȃ�
	lea.l	sasi_20mb_drive_parameter-sasi_10mb_drive_parameter(a1),a1	;20MB�h���C�u�p�����[�^
	goto	<cmp.l #33*4*615+1,d0>,cs,scsi_b_dskini_go	;20MB��614�V�����_����615�V�����_�܂�20MB�ƌ��Ȃ�
	lea.l	sasi_40mb_drive_parameter-sasi_20mb_drive_parameter(a1),a1	;40MB�h���C�u�p�����[�^
	goto	scsi_b_dskini_go

  .if SCSI_BIOS_LEVEL<>10
;----------------------------------------------------------------
;�h���C�u�p�����[�^����SASI�n�[�h�f�B�X�N�̗e�ʂ����߂�
;<d1.w:HD-ID<<8
;<a1.l:�h���C�u�p�����[�^
sasi_param_to_capacity:
	lea.l	BIOS_SASI_CAPACITY.l,a5	;SASI�n�[�h�f�B�X�N�̗e�ʂ̔z��B0=���m�F,10=10MB,20=20MB,40=40MB,128=��ڑ�
	move.l	d1,d0
	ror.w	#8,d0
	and.l	#15,d0			;HD-ID
	adda.l	d0,a5
	move.b	#40,d0			;40MB
	if	<cmpi.b #$07,3(a1)>,ne
		move.b	#20,d0			;20MB
		if	<cmpi.b #$02,4(a1)>,ne
			move.b	#10,d0			;10MB
		endif
	endif
	move.b	d0,(a5)
	clr.l	d0
	rts
  .endif

  .if SCSI_BIOS_LEVEL<=0
;----------------------------------------------------------------
;Test Unit Ready�R�}���h
test_unit_ready_command:
	.dc.b	$00			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Rezero Unit�R�}���h
rezero_unit_command:
	.dc.b	$01			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Read(6)�R�}���h
read_6_command_2nd:
	.dc.b	$08			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�_���u���b�N�A�h���X(���)#####
	.dc.b	$00			;2 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;3 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;4 �]���f�[�^��
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Read Capacity�R�}���h
read_capacity_command:
	.dc.b	$25			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved####|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 Reserved
	.dc.b	$00			;8 Reserved#######|PMI
	.dc.b	$00			;9 �R���g���[���o�C�g

;----------------------------------------------------------------
;Inquiry�R�}���h
inquiry_command:
	.dc.b	$12			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved####|EVPD
	.dc.b	$00			;2 �y�[�W�R�[�h
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �A���P�[�V������
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Request Sense�R�}���h
request_sense_command:
	.dc.b	$03			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �A���P�[�V������
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Mode Sense(6)�R�}���h
mode_sense_6_command:
	.dc.b	$1A			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|R|DBD|Reserved###
	.dc.b	$00			;2 PC##|�y�[�W�R�[�h######
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �A���P�[�V������
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Mode Select(6)�R�}���h
mode_select_6_command:
	.dc.b	$15			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|PF|Reserved###|SP
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 �p�����[�^���X�g��
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Reassign Blocks�R�}���h
reassign_blocks_command:
	.dc.b	$07			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Read(6)�R�}���h
read_6_command:
	.dc.b	$08			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�_���u���b�N�A�h���X(���)#####
	.dc.b	$00			;2 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;3 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;4 �]���f�[�^��
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Write(6)�R�}���h
write_6_command:
	.dc.b	$0A			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�_���u���b�N�A�h���X(���)#####
	.dc.b	$00			;2 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;3 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;4 �]���f�[�^��
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Read(10)�R�}���h
read_10_command:
	.dc.b	$28			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 �]���f�[�^��(���)
	.dc.b	$00			;8 �]���f�[�^��(����)
	.dc.b	$00			;9 �R���g���[���o�C�g

;----------------------------------------------------------------
;Write(10)�R�}���h
write_10_command:
	.dc.b	$2A			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 �]���f�[�^��(���)
	.dc.b	$00			;8 �]���f�[�^��(����)
	.dc.b	$00			;9 �R���g���[���o�C�g

;----------------------------------------------------------------
;Verify(10)�R�}���h
verify_10_command:
	.dc.b	$2F			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|DPO|Reserved##|BytChk|RelAdr
	.dc.b	$00			;2 �_���u���b�N�A�h���X(���)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 �_���u���b�N�A�h���X(����)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 �]���f�[�^��(���)
	.dc.b	$00			;8 �]���f�[�^��(����)
	.dc.b	$00			;9 �R���g���[���o�C�g

;----------------------------------------------------------------
;Prevent-Allow Medium Removal�R�}���h
prevent_allow_command:
	.dc.b	$1E			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved#######|Prevent
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Start-Stop Unit(Eject SONY MO)�R�}���h
start_stop_unit_command:
	.dc.b	$1B			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|Reserved####|Immed
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved######|LoEj|Start
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Load/Unload SHARP MO�R�}���h
load_unload_command:
	.dc.b	$C1			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|#####
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4 #######|LoEj
	.dc.b	$00			;5

;----------------------------------------------------------------
;Seek(6)�R�}���h
seek_6_command:
	.dc.b	$0B			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 LUN###|�u���b�N�ԍ�(���)#####
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Assign Drive(SASI)�R�}���h
assign_drive_sasi_command:
	.dc.b	$C2			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4
	.dc.b	$00			;5 �f�[�^�̒���

;----------------------------------------------------------------
;Format Block(SASI)�R�}���h
format_block_sasi_command:
	.dc.b	$06			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 �u���b�N�ԍ�(���)
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 �C���^���[�u
	.dc.b	$00			;5

;----------------------------------------------------------------
;Bad Track Format(SASI)�R�}���h
bad_track_format_sasi_command:
	.dc.b	$07			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 �u���b�N�ԍ�(���)
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 �C���^���[�u
	.dc.b	$00			;5 �R���g���[���o�C�g

;----------------------------------------------------------------
;Assign Track(SASI)�R�}���h
assign_track_sasi_command:
	.dc.b	$0E			;0 �I�y���[�V�����R�[�h
	.dc.b	$00			;1 �u���b�N�ԍ�(���)
	.dc.b	$00			;2 �u���b�N�ԍ�(����)
	.dc.b	$00			;3 �u���b�N�ԍ�(����)
	.dc.b	$00			;4 �C���^���[�u
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;10MB�h���C�u�p�����[�^
sasi_10mb_drive_parameter:
	.dc.b	$01,$01,$00,$03,$01,$35,$80,$00,$00,$00
;				~~~~~~~309
;			    ~~~4-1
  .if SCSI_BIOS_LEVEL<>10
;10MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
sasi_10mb_shipping_parameter:
	.dc.b	$01,$01,$00,$03,$01,$54,$80,$00,$00,$00
;				~~~~~~~340
;			    ~~~4-1
  .endif
;20MB�h���C�u�p�����[�^
sasi_20mb_drive_parameter:
	.dc.b	$01,$01,$00,$03,$02,$66,$80,$00,$00,$00
;				~~~~~~~614
;			    ~~~4-1
  .if SCSI_BIOS_LEVEL<>10
;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
sasi_20mb_shipping_parameter:
	.dc.b	$01,$01,$00,$03,$02,$98,$80,$00,$00,$00
;				~~~~~~~664
;			    ~~~4-1
  .endif
;40MB�h���C�u�p�����[�^
sasi_40mb_drive_parameter:
	.dc.b	$01,$01,$00,$07,$02,$66,$80,$00,$00,$00
;				~~~~~~~614
;			    ~~~8-1
;40MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
sasi_40mb_shipping_parameter:
	.dc.b	$01,$01,$00,$07,$02,$98,$80,$00,$00,$00
;				~~~~~~~664
;			    ~~~8-1

;----------------------------------------------------------------
;SASI�n�[�h�f�B�X�N
;
;	�����\��
;		10MB	20MB	40MB
;		256	256	256	�o�C�g/���R�[�h
;		33	33	33	���R�[�h/�g���b�N
;		4	4	8	�g���b�N/�V�����_
;		309	614	614	�V�����_/�{�����[��
;		340	664	664	�V�b�s���O�]�[��
;
;	SASI�f�B�X�NIPL
;		IPLROM��$2000.w�ɓǂݍ���Ŏ��s����
;		�N���p�[�e�B�V�����������܂��͎蓮�őI�����A�I�����ꂽ�p�[�e�B�V������SASI�p�[�e�B�V����IPL��$2400.w�ɓǂݍ���Ŏ��s����
;		�A�h���X
;		$00000000	SASI�f�B�X�NIPL
;
;	�p�[�e�B�V�����e�[�u��
;		�A�h���X	10MB		20MB		40MB
;		$00000400	$5836384B	$5836384B	$5836384B	X68K�}�W�b�N
;		$00000404	$00009F54	$00013C98	$00027930	���R�[�h��(�f�B�X�N�C���[�W�̃T�C�Y)
;				33*4*309=40788	33*4*614=81048	33*8*614=162096
;		$00000408	$00009F54	$00013C98	$00027930	��փ��R�[�h
;		$0000040C	$0000AF50	$00015660	$0002ACC0	�V�b�s���O�]�[��
;				33*4*340=44880	33*4*664=87648	33*8*664=175296
;		$00000410	��1�p�[�e�B�V�����̏��
;		$00000410	$48756D61	$48756D61	$48756D61	Huma�}�W�b�N
;		$00000414	$6E36386B	$6E36386B	$6E36386B	n68k�}�W�b�N
;		$00000418	$00000021	$00000021	$00000021	�J�n���R�[�h
;		$0000041C	$00009F2E	$00013C68	$000278F8	���R�[�h��
;		$00000420	��2�p�[�e�B�V�����̏��
;			:
;		$000004F0	��15�p�[�e�B�V�����̏��
;		$00000500	��
;			:
;
;	��1�p�[�e�B�V����(10MB�̑��u�ɍő�T�C�Y�̃p�[�e�B�V�������m�ۂ����ꍇ)
;		�A�h���X	�Z�N�^
;		$00002100	$00000000	SASI�p�[�e�B�V����IPL
;							SASI�f�B�X�NIPL��$2400.w�ɓǂݍ���Ŏ��s����
;							���[�g�f�B���N�g���ɂ���HUMAN.SYS��$6800.w�ɓǂݍ���Ŏ��s����
;		$00002500	$00000001	��1FAT
;		$00007500	$00000015	��2FAT
;		$0000C500	$00000029	���[�g�f�B���N�g��
;		$00010500	$00000039	�f�[�^�̈�
;
;	�h���C�u���(�ő�T�C�Y�̃p�[�e�B�V�������m�ۂ����ꍇ)
;		10MB	20MB	40MB
;		1024	1024	1024	�o�C�g/�Z�N�^
;		1	1	1	�Z�N�^/�N���X�^
;		10132	20155	40335	�f�[�^�̈�̃N���X�^��+2
;		1	1	1	�\��̈�̃Z�N�^��
;		20	40	80	1��FAT�̈�Ɏg�p����Z�N�^��
;		41	81	161	���[�g�f�B���N�g���̐擪�Z�N�^�ԍ�
;		512	512	512	���[�g�f�B���N�g���ɓ���G���g����
;		57	97	177	�f�[�^�̈�̐擪�Z�N�^�ԍ�
;

scsi_bios_end:

  .if SCSI_BIOS_LEVEL==0
;�����P�[�g�e�[�u��
	.dc.w	$0000,$0004,$0004,$0004,$0004,$0004,$0004,$0004
	.dc.w	$0004,$0038,$0004,$0014,$0144,$04C2,$0490,$001A
	.dc.w	$001C,$005E,$0156,$004A,$004A,$004A,$004A,$004C
	.dc.w	$0060,$0064,$0056,$005C,$0016,$003E,$003C,$003C
	.dc.w	$003E,$004C,$004E,$004A,$004A,$04FC,$0012,$0012
	.dc.w	$01AC,$0024,$0010
;�V���{���e�[�u��
	.dc.w	$0201
	.dc.l	install_sasi_iocs
	.dc.b	'sainit',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_4F_B_EJECT
	.dc.b	'b_eject',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_F5_SCSIDRV
	.dc.b	'SCSI',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_00_S_RESET
	.dc.b	'S_RESET',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_01_S_SELECT
	.dc.b	'S_SELECT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_02_S_SELECTA
	.dc.b	'S_SELECTA',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_03_S_CMDOUT
	.dc.b	'S_CMDOUT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_04_S_DATAIN
	.dc.b	'S_DATAIN',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_05_S_DATAOUT
	.dc.b	'S_DATAOUT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_06_S_STSIN
	.dc.b	'S_STSIN',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_07_S_MSGIN
	.dc.b	'S_MSGIN',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_08_S_MSGOUT
	.dc.b	'S_MSGOUT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_09_S_PHASE
	.dc.b	'S_PHASE',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_0A_S_LEVEL
	.dc.b	'S_LEVEL',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_0B_S_DATAINI
	.dc.b	'S_DATAINI',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_0C_S_DATAOUTI
	.dc.b	'S_DATAOUTI',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_24_S_TESTUNIT
	.dc.b	'testunit',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2B_S_REZEROUNIT
	.dc.b	'rezerounit',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2E_S_READI
	.dc.b	'readi',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_25_S_READCAP
	.dc.b	'readcap',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_20_S_INQUIRY
	.dc.b	'inquiry',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2C_S_REQUEST
	.dc.b	'request',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_21_S_READ
	.dc.b	'read',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_22_S_WRITE
	.dc.b	'write',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_23_S_FORMAT
	.dc.b	'format',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2F_S_STARTSTOP
	.dc.b	'startstop',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_30_S_SEJECT
	.dc.b	'seject',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2D_S_SEEK
	.dc.b	'seek',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_36_S_DSKINI
	.dc.b	'dskini',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_37_S_FORMATB
	.dc.b	'formatb',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_38_S_BADFMT
	.dc.b	'badfmt',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_39_S_ASSIGN
	.dc.b	'assign',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_29_S_MODESENSE
	.dc.b	'modesense',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2A_S_MODESELECT
	.dc.b	'modeselect',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_31_S_REASSIGN
	.dc.b	'reassign',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_26_S_READEXT
	.dc.b	'readext',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_27_S_WRITEEXT
	.dc.b	'writeext',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_28_S_VERIFYEXT
	.dc.b	'verifyext',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_32_S_PAMEDIUM
	.dc.b	'pamedium',$00
	.even
	.dc.w	$0201
	.dc.l	jump_00_0F
	.dc.b	'cmdtbl1',$00
	.even
	.dc.w	$0201
	.dc.l	jump_20_3F
	.dc.b	'cmdtbl2',$00
	.even
	.dc.w	$0201
	.dc.l	jump_40_4F
	.dc.b	'cmdtbl3',$00
	.even
	.dc.w	$0201
	.dc.l	select_and_cmdout
	.dc.b	'command',$00
	.even
	.dc.w	$0201
	.dc.l	stsin_and_msgin
	.dc.b	'ms_get',$00
	.even
	.dc.w	$0201
	.dc.l	spc_interrupt_routine
	.dc.b	'scsi_int',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu
	.dc.b	'man_out',$00
	.even
	.dc.w	$0201
	.dc.l	dataouti_transfer
	.dc.b	'prg_out',$00
	.even
	.dc.w	$0201
	.dc.l	dataini_transfer
	.dc.b	'prg_in',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu
	.dc.b	'man_in',$00
	.even
	.dc.w	$0201
	.dc.l	dataini_wait
	.dc.b	'wt_pin',$00
	.even
	.dc.w	$0201
	.dc.l	dataini_loop
	.dc.b	'st_pin',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_loop
	.dc.b	'st_mout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_wait_1
	.dc.b	'aa_mout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_wait_2
	.dc.b	'na_mout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_end
	.dc.b	'ed_mout',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu_loop
	.dc.b	'st_min',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu_wait_1
	.dc.b	'aa_min',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu_wait_2
	.dc.b	'na_min',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_wait
	.dc.b	'dout_loop',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_transfer
	.dc.b	'dma_out',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer
	.dc.b	'dma_in',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_transfer_end
	.dc.b	'er_dout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_transfer_no_error
	.dc.b	'ed_dout',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer_end
	.dc.b	'er_din',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer_wait
	.dc.b	'ew_din',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer_no_error
	.dc.b	'ed_din',$00
	.even
	.dc.w	$0203
	.dc.l	scsi_bios_end
	.dc.b	'allend',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_40_B_SEEK
	.dc.b	'b_seek',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_41_B_VERIFY
	.dc.b	'b_verify',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_43_B_DSKINI
	.dc.b	'b_dskini',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_44_B_DRVSNS
	.dc.b	'b_drvsns',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_45_B_WRITE
	.dc.b	'b_write',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_46_B_READ
	.dc.b	'b_read',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_47_B_RECALI
	.dc.b	'b_recali',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_48_B_ASSIGN
	.dc.b	'b_assign',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_4B_B_BADFMT
	.dc.b	'b_badfmt',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_4D_B_FORMAT
	.dc.b	'b_format',$00
	.even
;��
    .if SCSIEXROM
	.dcb.b	$2000-$1F18,$FF
    .else
	.dcb.b	$2000-$1EF8,$FF
    .endif
  .elif SCSI_BIOS_LEVEL==3
;��
    .if SCSIEXROM
	.dcb.b	$2000-$1B1E,$FF
    .else
	.dcb.b	$2000-$1AFE,$FF
    .endif
  .endif



	.end

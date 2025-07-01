;========================================================================================
;  flinebuserror.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;
;	flinebuserror.x
;		MC68030��DOS�R�[����_GETENV���Â��ԍ�$FF53�ŌĂяo���ăo�X�G���[�𔭐�����������ł��B
;		�o�X�G���[�����������Ƃ���bus error�ƁA�����Ȃ��Ί��ϐ�path�̓��e���\������܂��B
;		MC68030�ł�$FF53��cpRESTORE (a3)�Ȃ̂ŁA$FF53�����s�����(a3)�����[�h����Aa3�̓��e�ɂ���Ă̓o�X�G���[���������܂��B
;		���̖�肪�A_GETENV��V�����ԍ�$FF83�Ɉړ������Ȃ���΂Ȃ�Ȃ��������R�ł���ƍl�����܂��B
;
;	�X�V����
;		2024-11-29
;			���J�B
;
;----------------------------------------------------------------------------------------

	.include	doscall.mac

	.text

;�X�[�p�[�o�C�U���[�h�Ɉڍs����
	clr.l	-(sp)
	DOS	_SUPER
	move.l	d0,(sp)

;�o�X�G���[����������A�h���X��p�ӂ���
	movea.l	#$00E80400,a3		;a3=�o�X�G���[����������A�h���X

;�X�[�p�[�o�C�U�X�^�b�N�|�C���^��ۑ�����
	movea.l	sp,a4			;a4=�X�[�p�[�o�C�U�X�^�b�N�|�C���^

;�o�X�G���[��O�x�N�^��ۑ����ĕύX����
	move.l	$0008.w,a5		;a5=���̃o�X�G���[��O�x�N�^
	move.l	#buserror,$0008.w

;���ϐ�path�̒l�����o��
	lea.l	name,a0			;a0=���ϐ��̖��O
	suba.l	a1,a1			;a1=���̗̈�B0�͎��s���̃v���Z�X
	lea.l	value,a2		;a2=���ϐ��̒l
	clr.b	(a2)			;���ϐ����Ȃ���΋�Ƃ݂Ȃ�
	movem.l	a0-a2,-(sp)
	DOS	_V2_GETENV		;X68030�̂Ƃ������Ńo�X�G���[����������
	lea.l	12(sp),sp

;�o�X�G���[��O�x�N�^�𕜌�����
	move.l	a5,$0008.w

;���ϐ�path�̒l��\������
	move.l	a0,-(sp)		;���ϐ��̖��O
	DOS	_PRINT
	pea.l	separator		;��؂�
	DOS	_PRINT
	move.l	a2,-(sp)		;���ϐ��̒l
	DOS	_PRINT
	pea.l	crlf			;���s
	DOS	_PRINT
	lea.l	16(sp),sp

	bra	user_exit

;�o�X�G���[�̂Ƃ�
buserror:

;�X�[�p�[�o�C�U�X�^�b�N�|�C���^�𕜌�����
	movea.l	a4,sp			;���̃X�[�p�[�o�C�U�X�^�b�N�|�C���^

;�o�X�G���[��O�x�N�^�𕜌�����
	move.l	a5,$0008.w		;���̃o�X�G���[��O�x�N�^

;�o�X�G���[�̃��b�Z�[�W��\������
	pea.l	message			;'bus error'
	DOS	_PRINT
	addq.l	#4,sp

user_exit:

;���[�U���[�h�ɕ��A����
	DOS	_SUPER
	addq.l	#4,sp

;�I������
	DOS	_EXIT

	.data

;���ϐ��̖��O
name:
	.dc.b	'path',0

;'bus error'
message:
	.dc.b	'bus error'
;���s
crlf:
	.dc.b	13,10,0
;��؂�
separator:
	.dc.b	'=',0

	.bss

;���ϐ��̒l
value:
	.ds.b	1024

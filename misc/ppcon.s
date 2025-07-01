;========================================================================================
;  ppcon.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	dosconst.equ
	.include	doswork.equ
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sram.equ

DEVICE_NAME	reg	'CON     '
TITLE_STRING	reg	'Proportional-Pitch CONsole'
VERSION_STRING	reg	'0.11'
MAGIC_STRING	reg	'PPCON011'

;----------------------------------------------------------------
;�v���O�����̐擪
	.text
program_head:

;�f�o�C�X�w�b�_
	.dc.l	-1			;���̃f�o�C�X�w�b�_�B-1=�f�o�C�X�w�b�_�̃��X�g�̖���
	.dc.w	$8003			;�f�o�C�X�^�C�v�B�L�����N�^�f�o�C�X�A�W���o�́A�W������
	.dc.l	strategy_routine	;�X�g���e�W���[�`��
	.dc.l	interrupt_routine	;�C���^���v�g���[�`��
	.dc.b	DEVICE_NAME		;�f�o�C�X��

;----------------------------------------------------------------
;�}�W�b�N
magic:
	.dc.b	MAGIC_STRING

;�x�N�^�e�[�u��
vector_table:
;�J�[�\���_�ŏ������[�`��
	.dc.w	BIOS_TC_CURSOR_HANDLE	;�I�t�Z�b�g
	.dc.l	timer_c_cursor		;�V�����x�N�^
	.dc.l	0			;�Â��x�N�^
;_B_CURON
	.dc.w	4*($100+_B_CURON)
	.dc.l	iocs_1E_B_CURON
	.dc.l	0
;_B_CUROFF
	.dc.w	4*($100+_B_CUROFF)
	.dc.l	iocs_1F_B_CUROFF
	.dc.l	0
;_B_PUTC
	.dc.w	4*($100+_B_PUTC)
	.dc.l	iocs_20_B_PUTC
	.dc.l	0
;_B_PRINT
	.dc.w	4*($100+_B_PRINT)
	.dc.l	iocs_21_B_PRINT
	.dc.l	0
;_B_COLOR
	.dc.w	4*($100+_B_COLOR)
	.dc.l	iocs_22_B_COLOR
	.dc.l	0
;_B_LOCATE
	.dc.w	4*($100+_B_LOCATE)
	.dc.l	iocs_23_B_LOCATE
	.dc.l	0
;_B_DOWN_S
	.dc.w	4*($100+_B_DOWN_S)
	.dc.l	iocs_24_B_DOWN_S
	.dc.l	0
;_B_UP_S
	.dc.w	4*($100+_B_UP_S)
	.dc.l	iocs_25_B_UP_S
	.dc.l	0
;_B_UP
	.dc.w	4*($100+_B_UP)
	.dc.l	iocs_26_B_UP
	.dc.l	0
;_B_DOWN
	.dc.w	4*($100+_B_DOWN)
	.dc.l	iocs_27_B_DOWN
	.dc.l	0
;_B_RIGHT
	.dc.w	4*($100+_B_RIGHT)
	.dc.l	iocs_28_B_RIGHT
	.dc.l	0
;_B_LEFT
	.dc.w	4*($100+_B_LEFT)
	.dc.l	iocs_29_B_LEFT
	.dc.l	0
;_B_CLR_ST
	.dc.w	4*($100+_B_CLR_ST)
	.dc.l	iocs_2A_B_CLR_ST
	.dc.l	0
;_B_ERA_ST
	.dc.w	4*($100+_B_ERA_ST)
	.dc.l	iocs_2B_B_ERA_ST
	.dc.l	0
;_B_INS
	.dc.w	4*($100+_B_INS)
	.dc.l	iocs_2C_B_INS
	.dc.l	0
;_B_DEL
	.dc.w	4*($100+_B_DEL)
	.dc.l	iocs_2D_B_DEL
	.dc.l	0
;_B_CONSOL
	.dc.w	4*($100+_B_CONSOL)
	.dc.l	iocs_2E_B_CONSOL
	.dc.l	0
;_OS_CURON
	.dc.w	4*($100+_OS_CURON)
	.dc.l	iocs_AE_OS_CURON
	.dc.l	0
;_OS_CUROF
	.dc.w	4*($100+_OS_CUROF)
	.dc.l	iocs_AF_OS_CUROF
	.dc.l	0
;_PUTCHAR
	.dc.w	$1800+4*(_PUTCHAR-$FF00)
	.dc.l	dos_FF02_PUTCHAR
old_putchar:
	.dc.l	0
;_INPOUT
	.dc.w	$1800+4*(_INPOUT-$FF00)
	.dc.l	dos_FF06_INPOUT
old_inpout:
	.dc.l	0
;_PRINT
	.dc.w	$1800+4*(_PRINT-$FF00)
	.dc.l	dos_FF09_PRINT
old_print:
	.dc.l	0
;_FPUTC
	.dc.w	$1800+4*(_FPUTC-$FF00)
	.dc.l	dos_FF1D_FPUTC
old_fputc:
	.dc.l	0
;_FPUTS
	.dc.w	$1800+4*(_FPUTS-$FF00)
	.dc.l	dos_FF1E_FPUTS
old_fputs:
	.dc.l	0
;_CONCTRL
	.dc.w	$1800+4*(_CONCTRL-$FF00)
	.dc.l	dos_FF23_CONCTRL
old_conctrl:
	.dc.l	0
;_WRITE
	.dc.w	$1800+4*(_WRITE-$FF00)
	.dc.l	dos_FF40_WRITE
old_write:
	.dc.l	0
	.dc.w	0

;----------------------------------------------------------------
;���N�G�X�g�w�b�_�̃A�h���X
request_header:
	.dc.l	0

;�X�g���e�W���[�`��
strategy_routine:
	move.l	a5,request_header
	rts

;�C���^���v�g���[�`��
interrupt_routine:
	push	d0-d7/a0-a6
	movea.l	request_header(pc),a5
	moveq.l	#0,d0
	move.b	2(a5),d0		;�R�}���h�ԍ�
	if	<cmp.w #(jump_table_end-jump_table)/2,d0>,hs	;�͈͊O
		moveq.l	#(jump_table_end-jump_table)/2,d0
	endif
	add.w	d0,d0
	move.w	jump_table(pc,d0.w),d0
	jsr	jump_table(pc,d0.w)
	move.b	d0,3(a5)		;�G���[�R�[�h����
	lsr.w	#8,d0
	move.b	d0,4(a5)		;�G���[�R�[�h���
	pop
	rts

;�f�o�C�X�R�}���h�̃W�����v�e�[�u��
jump_table:
	.dc.w	initialize-jump_table		;�f�o�C�X�R�}���h0 ������
	.dc.w	command_error-jump_table	;�f�o�C�X�R�}���h1 �f�B�X�N�����`�F�b�N
	.dc.w	command_error-jump_table	;�f�o�C�X�R�}���h2 BPB�e�[�u���̍č\�z
	.dc.w	ioctrl_input-jump_table		;�f�o�C�X�R�}���h3 _IOCTRL�ɂ�����
	.dc.w	input-jump_table		;�f�o�C�X�R�}���h4 ����
	.dc.w	control_sense-jump_table	;�f�o�C�X�R�}���h5 �R���g���[��/�Z���X
	.dc.w	input_status-jump_table		;�f�o�C�X�R�}���h6 ���̓X�e�[�^�X
	.dc.w	input_flush-jump_table		;�f�o�C�X�R�}���h7 ���̓o�b�t�@�t���b�V��
	.dc.w	output-jump_table		;�f�o�C�X�R�}���h8 �o��(�x���t�@�C�Ȃ�)
	.dc.w	output-jump_table		;�f�o�C�X�R�}���h9 �o��(�x���t�@�C����)
	.dc.w	output_status-jump_table	;�f�o�C�X�R�}���h10 �o�̓X�e�[�^�X
	.dc.w	no_error-jump_table		;�f�o�C�X�R�}���h11 ����I��
	.dc.w	ioctrl_output-jump_table	;�f�o�C�X�R�}���h12 _IOCTRL�ɂ��o��
jump_table_end:
	.dc.w	command_error-jump_table	;�͈͊O �R�}���h�G���[

;�f�o�C�X�R�}���h1 �f�B�X�N�����`�F�b�N
;�f�o�C�X�R�}���h2 BPB�e�[�u���̍č\�z
;�R�}���h�G���[
command_error:
	move.w	#IGNORE|ABORT|UNKNOWN_COMMAND,d0	;����(I) ���~(A) �f�o�C�X�h���C�o�ɖ����ȃR�}���h���w�肵�܂���
	rts

;�f�o�C�X�R�}���h3 _IOCTRL�ɂ�����
ioctrl_input:
;	movea.l	14(a5),a1		;�A�h���X
	goto	command_error

;�f�o�C�X�R�}���h4 ����
input:
	movea.l	14(a5),a1		;�A�h���X
	move.l	18(a5),d3		;����
	dostart
		clr.w	-(sp)			;1��������
  .if 0
		DOS	_KEYCTRL
  .else
		movea.l	sp,a6
		movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
		jsr	(a0)
  .endif
		addq.l	#2,sp
		move.b	d0,(a1)+		;�����R�[�h
  .if 0
		break	<cmp.b #13,d0>,eq
  .endif
	start
		subq.l	#1,d3
	while	cc
;	move.l	18(a5),18(a5)		;���͂�������
	moveq.l	#0,d0			;��ɐ�������(�I���܂ŕ��A���Ȃ�)
	rts

;�f�o�C�X�R�}���h5 �R���g���[��/�Z���X
control_sense:
	move.w	#1,-(sp)		;1�����Z���X
  .if 0
	DOS	_KEYCTRL
  .else
	movea.l	sp,a6
	movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
	jsr	(a0)
  .endif
	addq.l	#2,sp
	move.b	d0,13(a5)		;�����R�[�h
	moveq.l	#0,d0			;��ɐ�������
	rts

;�f�o�C�X�R�}���h6 ���̓X�e�[�^�X
input_status:
	move.w	#1,-(sp)		;1�����Z���X
  .if 0
	DOS	_KEYCTRL
  .else
	movea.l	sp,a6
	movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
	jsr	(a0)
  .endif
	addq.l	#2,sp
	if	<tst.b d0>,ne
		moveq.l	#0,d0			;0=���̓o�b�t�@����ł͂Ȃ��̂œ��͂ł���
	else
		moveq.l	#1,d0			;1=���̓o�b�t�@����Ȃ̂œ��͂ł��Ȃ�
	endif
	rts

;�f�o�C�X�R�}���h7 ���̓o�b�t�@�t���b�V��
input_flush:
	dostart
		clr.w	-(sp)			;1��������
  .if 0
		DOS	_KEYCTRL
  .else
		movea.l	sp,a6
		movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
		jsr	(a0)
  .endif
		addq.l	#2,sp
	start
		move.w	#1,-(sp)		;1�����Z���X
  .if 0
		DOS	_KEYCTRL
  .else
		movea.l	sp,a6
		movea.l	$1800+4*(_KEYCTRL-$FF00).w,a0
		jsr	(a0)
  .endif
		addq.l	#2,sp
	while	<tst.b d0>,ne
	moveq.l	#0,d0			;��ɐ�������
	rts

;�f�o�C�X�R�}���h8 �o��(�x���t�@�C�Ȃ�)
;�f�o�C�X�R�}���h9 �o��(�x���t�@�C����)
output:
	movea.l	14(a5),a1		;�A�h���X
	move.l	18(a5),d3		;����
	dostart
		moveq.l	#0,d1
		move.b	(a1)+,d1		;�����R�[�h
  .if 0
		move.w	d1,-(sp)
		clr.w	-(sp)			;1�����\��
		DOS	_CONCTRL
		addq.l	#4,sp
  .else
		bsr	putc			;1�����\��
  .endif
	start
		subq.l	#1,d3
	while	cc
;	move.l	18(a5),18(a5)		;�o�͂�������
	moveq.l	#0,d0			;��ɐ�������(�I���܂ŕ��A���Ȃ�)
	rts

;�f�o�C�X�R�}���h10 �o�̓X�e�[�^�X
output_status:
	moveq.l	#0,d0			;0=�o�̓o�b�t�@�����t�ł͂Ȃ��̂ŏo�͂ł���
;	moveq.l	#1,d0			;1=�o�̓o�b�t�@�����t�Ȃ̂ŏo�͂ł��Ȃ�
	rts

;�f�o�C�X�R�}���h11 ����I��
no_error:
	moveq.l	#0,d0			;��ɐ�������
	rts

;�f�o�C�X�R�}���h12 _IOCTRL�ɂ��o��
ioctrl_output:
;	movea.l	14(a5),a1		;�A�h���X
	goto	command_error



;hiocs.x������������DOS�R�[����$FF02,$FF06,$FF09,$FF1D,$FF1E,$FF23,$FF40�B���ׂď㏑������

;----------------------------------------------------------------
;DOS�R�[��$FF02 _PUTCHAR �W���o�͂�1�o�C�g�o��
;<(a6).w:1�o�C�g�f�[�^
dos_FF02_PUTCHAR:
;�W���o�͂�CON��
	bsr	is_stdout_con		;�W���o�͂�CON��
	if	pl			;�G���[�Ȃ�
		if	ne			;CON�ł͂Ȃ�
		;���̏�����
			movea.l	old_putchar(pc),a0
			jmp	(a0)
		endif
	;�o�͂���
		moveq.l	#0,d1
		move.b	1(a6),d1
		bsr	putchar_to_con		;CON��1�o�C�g�o�͂���B�v�����^�o��,^S,^P,^N,^C����������
		moveq.l	#0,d0
	endif
	rts

;----------------------------------------------------------------
;CON��1�o�C�g�o�͂���B�v�����^�o��,^S,^P,^N,^C����������
;<d1.l:1�o�C�g�f�[�^
putchar_to_con:
	push	d0-d7/a0-a6
;CON�֏o�͂���
	bsr	putc			;1�����\��
;�W���v�����^�֏o�͂���
	if	<tst.b DOS_CTRL_P_MODE.w>,ne
		move.w	#STDPRN,-(sp)		;�W���v�����^�o��
		move.w	d1,-(sp)
		movea.l	sp,a6
		movea.l	old_fputc(pc),a0
		jsr	(a0)
		addq.l	#2+2,sp
	endif
;^S����������
	move.w	#$00FE,-(sp)		;$00FE�B�W�����͂̐�ǂ݁B0�ł��߂�BBREAK�`�F�b�N����
	movea.l	sp,a6
	movea.l	old_inpout(pc),a0
	jsr	(a0)
	addq.l	#2,sp
	if	<cmp.w DOS_CTRL_S_CODE.w,d1>,eq	;^S�������ꂽ
		move.w	#$00FF,-(sp)		;$00FF�B�W�����͂�����́B0�ł��߂�BBREAK�`�F�b�N����
		movea.l	sp,a6
		movea.l	old_inpout(pc),a0
		jsr	(a0)
		addq.l	#2,sp
  .if 0
		DOS	_INKEY
  .else
		movea.l	$1800+4*(_INKEY-$FF00).w,a0
		jsr	(a0)
  .endif
	endif
;^P,^N,^C����������
  .if 0
	DOS	_KEYSNS
  .else
	movea.l	$1800+4*(_KEYSNS-$FF00).w,a0
	jsr	(a0)
  .endif
	pop
	rts

;----------------------------------------------------------------
;DOS�R�[��$FF06 _INPOUT �W���n���h���ւ̓��o��
;<(a6).w:1�o�C�g�f�[�^
;	$FE	�W�����͂̐�ǂ݁B0�ł��߂�BBREAK�`�F�b�N����
;	$FF	�W�����͂�����́B0�ł��߂�BBREAK�`�F�b�N����
;	���̑�	�W���o�͂�1�o�C�g�o��
;>d0.l:���͂���1�o�C�g�f�[�^
dos_FF06_INPOUT:
;��ǂ݂܂��͓��͂�
	if	<cmp.b #$FE,1(a6)>,hs	;��ǂ݂܂��͓���
	;���̏�����
		movea.l	old_inpout(pc),a0
		jmp	(a0)
	endif
;�W���o�͂�CON��
	bsr	is_stdout_con		;�W���o�͂�CON��
	if	pl			;�G���[�Ȃ�
		if	ne			;CON�ł͂Ȃ�
		;���̏�����
			movea.l	old_inpout(pc),a0
			jmp	(a0)
		endif
	;CON�֏o�͂���
		moveq.l	#0,d1
		move.b	1(a6),d1
		bsr	putc			;1�����\��
	;�W���v�����^�֏o�͂���
		if	<tst.b DOS_CTRL_P_MODE.w>,ne
			move.w	#STDPRN,-(sp)		;�W���v�����^�o��
			move.w	d1,-(sp)
			movea.l	sp,a6
			movea.l	old_fputc(pc),a0
			jsr	(a0)
			addq.l	#2+2,sp
		endif
		moveq.l	#0,d0
	;^S,^P,^N,^C�͏������Ȃ�
	endif
	rts

;----------------------------------------------------------------
;DOS�R�[��$FF09 _PRINT �W���o�͂ɕ�������o��
;<(a6).l:������
dos_FF09_PRINT:
;�W���o�͂�CON��
	bsr	is_stdout_con		;�W���o�͂�CON��
	if	pl			;�G���[�Ȃ�
		if	ne			;CON�ł͂Ȃ�
		;���̏�����
			movea.l	old_print(pc),a0
			jmp	(a0)
		endif
	;CON�֏o�͂���
		movea.l	(a6),a1			;������
		dostart
			bsr	putchar_to_con		;CON��1�o�C�g�o�͂���B�v�����^�o��,^S,^P,^N,^C����������
		start
			moveq.l	#0,d1
			move.b	(a1)+,d1
		while	ne
		moveq.l	#0,d0
	endif
	rts

;----------------------------------------------------------------
;DOS�R�[��$FF1D _FPUTC �n���h����1�o�C�g�o��
;<(a6).w:����
;<2(a6).w:�n���h���ԍ�
;>d0.l:�o�͂��������܂��̓G���[�R�[�h
dos_FF1D_FPUTC:
;�n���h����CON��
	move.w	2(a6),d0		;�n���h���ԍ�
	bsr	is_handle_con		;�n���h����CON��
	if	pl			;�G���[�Ȃ�
		if	ne			;CON�ł͂Ȃ�
		;���̏�����
			movea.l	old_fputc(pc),a0
			jmp	(a0)
		endif
	;�������߂邩
		moveq.l	#$0F,d0
		and.b	14(a0),d0		;�t�@�C���I�[�v�����[�h
		if	ne			;�������߂�
		;CON�֏o�͂���B�v�����^�o��,^S,^P,^N,^C�͏������Ȃ�
			moveq.l	#0,d1
			move.b	1(a6),d1		;����
			bsr	putc			;1�����\��
			moveq.l	#1,d0			;�o�͂�������
		else				;�������߂Ȃ�
			moveq.l	#INVALID_ACCESS_MODE,d0	;�I�[�v���̃A�N�Z�X���[�h���ُ�
		endif
	endif
	rts

;----------------------------------------------------------------
;DOS�R�[��$FF1E _FPUTS �n���h���֕�������o��
;<(a6).l:������
;<4(a6).w:�n���h���ԍ�
;>d0.l:�o�͂��������܂��̓G���[�R�[�h
dos_FF1E_FPUTS:
;������̒�����0��
	movea.l	(a6),a0			;������
	tst.b	(a0)
	if	eq			;������̒�����0
	;�n���h���ԍ��Ɋ֌W�Ȃ�����I������
		moveq.l	#0,d0			;�o�͂�������
	else				;������̒�����0�ł͂Ȃ�
	;�n���h����CON��
		move.w	4(a6),d0		;�n���h���ԍ�
		bsr	is_handle_con		;�n���h����CON��
		if	pl			;�G���[�Ȃ�
			if	ne			;CON�ł͂Ȃ�
			;���̏�����
				movea.l	old_fputs(pc),a0
				jmp	(a0)
			endif
		;�������߂邩
			moveq.l	#$0F,d0
			and.b	14(a0),d0		;�t�@�C���I�[�v�����[�h
			if	ne			;�������߂�
			;CON�֏o�͂���B�v�����^�o��,^S,^P,^N,^C�͏������Ȃ�
				movea.l	(a6),a1			;������
				move.l	a1,d0
				dostart
					bsr	putc			;1�����\��
				start
					moveq.l	#0,d1
					move.b	(a1)+,d1
				while	ne
				subq.l	#1,a1
				exg.l	d0,a1
				sub.l	a1,d0			;�o�͂�������
			else				;�������߂Ȃ�
				moveq.l	#INVALID_ACCESS_MODE,d0	;�I�[�v���̃A�N�Z�X���[�h���ُ�
			endif
		endif
	endif
	rts

;----------------------------------------------------------------
;DOS�R�[��$FF23 _CONCTRL �R���\�[���o�͂̐���
;<(a6).w:���[�h
;	0	1�����\��
;			<2(a6).w:1�o�C�g�f�[�^
;	1	������\��
;			<2(a6).l:������
;	2	���������̐ݒ�
;			<2(a6).w:����
;	3	�J�[�\���̈ړ�
;			<2(a6).w:X���W
;			<4(a6).w:Y���W
;	4	�J�[�\����1�s���ֈړ�(���[�ł̓X�N���[���A�b�v)
;	5	�J�[�\����1�s��ֈړ�(��[�ł̓X�N���[���_�E��)
;	6	�J�[�\����N�s��ֈړ�
;			<2(a6).w:N
;	7	�J�[�\����N�s���ֈړ�
;			<2(a6).w:N
;	8	�J�[�\����N���E�ֈړ�
;			<2(a6).w:N
;	9	�J�[�\����N�����ֈړ�
;			<2(a6).w:N
;	10	��ʏ���
;			<2(a6).w:���[�h
;				0
;				1
;				2
;	11	�s����
;			<2(a6).w:���[�h
;				0
;				1
;				2
;	12	N�s�}��
;			<2(a6).w:N
;	13	N�s�폜
;			<2(a6).w:N
;	14	�t�@���N�V�����\���s�̃��[�h�̎擾�Ɛݒ�
;			<2(a6).w:���[�h
;				-1	�擾
;				0	�m�[�}��
;				1	�V�t�g
;				2	�\�����Ȃ�
;				3	���ʂ̍s
;	15	�X�N���[���͈͂̐ݒ�
;			<2(a6).w:�X�N���[���͈͂̊J�n�s��Y���W
;			<4(a6).w:�X�N���[���͈͂̍s��
;	16	��ʃ��[�h�̐ݒ�
;			<2(a6).w:��ʃ��[�h
;				0	768x512,�O���t�B�b�N�Ȃ�
;				1	768x512,�O���t�B�b�N16�F
;				2	512x512,�O���t�B�b�N�Ȃ�
;				3	512x512,�O���t�B�b�N16�F
;				4	512x512,�O���t�B�b�N256�F
;				5	512x512,�O���t�B�b�N65536�F
;	17	�J�[�\���\��
;	18	�J�[�\������
dos_FF23_CONCTRL:
	move.w	(a6),d0			;���[�h
	if	<cmp.w #13,d0>,hi	;IOCS�R�[���ȊO
	;���̏�����
		movea.l	old_conctrl(pc),a0
		jmp	(a0)
	endif
	movea.l	2(a6),a1
	move.l	a1,d1
	swap.w	d1
	move.l	a1,d2
	add.w	d0,d0
	move.w	100f(pc,d0.w),d0
	jmp	100f(pc,d0.w)
100:
	.dc.w	iocs_20_B_PUTC-100b
	.dc.w	iocs_21_B_PRINT-100b
	.dc.w	iocs_22_B_COLOR-100b
	.dc.w	iocs_23_B_LOCATE-100b
	.dc.w	iocs_24_B_DOWN_S-100b
	.dc.w	iocs_25_B_UP_S-100b
	.dc.w	iocs_26_B_UP-100b
	.dc.w	iocs_27_B_DOWN-100b
	.dc.w	iocs_28_B_RIGHT-100b
	.dc.w	iocs_29_B_LEFT-100b
	.dc.w	iocs_2A_B_CLR_ST-100b
	.dc.w	iocs_2B_B_ERA_ST-100b
	.dc.w	iocs_2C_B_INS-100b
	.dc.w	iocs_2D_B_DEL-100b

;----------------------------------------------------------------
;DOS�R�[��$FF40 _WRITE �n���h���֎w�肳�ꂽ�T�C�Y�̃f�[�^����������
;<(a6).w:�n���h���ԍ�
;<2(a6).l:������
;<6(a6).l:������̒���
;>d0.l:�o�͂�������
dos_FF40_WRITE:
;�n���h����CON��
	move.w	(a6),d0			;�n���h���ԍ�
	bsr	is_handle_con		;�n���h����CON��
	if	pl			;�G���[�Ȃ�
		if	ne			;CON�ł͂Ȃ�
		;���̏�����
			movea.l	old_write(pc),a0
			jmp	(a0)
		endif
	;�������߂邩
		moveq.l	#$0F,d0
		and.b	14(a0),d0		;�t�@�C���I�[�v�����[�h
		if	ne			;�������߂�
		;CON�֏o�͂���B�v�����^�o��,^S,^P,^N,^C����������
			movea.l	2(a6),a1		;������
			move.l	6(a6),d0		;������̒���
			move.l	d0,d2
			dostart
				moveq.l	#0,d1
				move.b	(a1)+,d1
				bsr	putchar_to_con		;CON��1�o�C�g�o�͂���B�v�����^�o��,^S,^P,^N,^C����������
			start
				subq.l	#1,d2
			while	cc
		else				;�������߂Ȃ�
			moveq.l	#INVALID_ACCESS_MODE,d0	;�I�[�v���̃A�N�Z�X���[�h���ُ�
		endif
	endif
	rts

;----------------------------------------------------------------
;�W���o�͂�CON��
;>d0.l:FCB�e�[�u���܂��̓G���[�R�[�h
;>a0.l:FCB�e�[�u��
;>n:pl=�G���[�Ȃ�,mi=�G���[����
;>z:ne=CON�ł͂Ȃ�,eq=CON
;?d1-d7/a1-a5
is_stdout_con:
	moveq.l	#1,d0
;----------------------------------------------------------------
;�n���h����CON��
;<d0.w:�n���h���ԍ�
;>d0.l:FCB�e�[�u���܂��̓G���[�R�[�h
;>a0.l:FCB�e�[�u��
;>n:pl=�G���[�Ȃ�,mi=�G���[����
;>z:ne=CON�ł͂Ȃ�,eq=CON
;?d1-d7/a1-a5
is_handle_con:
  .if 0
	move.w	d0,-(sp)
	DOS	_GETFCB
	addq.l	#2,sp
  .else
	push	a6
	move.w	d0,-(sp)
	movea.l	sp,a6
	movea.l	$1800+4*(_GETFCB-$FF00).w,a0
	jsr	(a0)
	addq.l	#2,sp
	pop
  .endif
	if	<tst.l d0>,pl		;�G���[�Ȃ�
		movea.l	d0,a0			;FCB�e�[�u��
		if	<tst.b 1(a0)>,mi	;�L�����N�^�f�o�C�X
			cmpi.l	#'CON ',36(a0)		;�f�o�C�X���܂��̓t�@�C����1
		endif
	endif
	rts



;�R���\�[���g��
BIOS_ATTRIBUTE_2	equ	$0D30		;.b ��������2�B-|��t��|���t��|���|�ۈ͂�|�l�p�͂�|�v���|�[�V���i��|�g��
BIOS_SUPERSCRIPT_BIT	equ	 6		;��t��
BIOS_SUPERSCRIPT	equ	%01000000
BIOS_SUBSCRIPT_BIT	equ	  5		;���t��
BIOS_SUBSCRIPT		equ	%00100000
BIOS_OVERLINE_BIT	equ	    4		;���
BIOS_OVERLINE		equ	%00010000
BIOS_ENCIRCLE_BIT	equ	     3		;�ۈ͂�
BIOS_ENCIRCLE		equ	%00001000
BIOS_FRAME_BIT		equ	      2		;�l�p�͂�
BIOS_FRAME		equ	%00000100
BIOS_PROPORTIONAL_BIT	equ	       1	;�v���|�[�V���i��
BIOS_PROPORTIONAL	equ	%00000010
BIOS_WAVELINE_BIT	equ	        0	;�g��
BIOS_WAVELINE		equ	%00000001
BIOS_CURSOR_FRACTION	equ	$0D31		;.b �J�[�\���̌����W�̒[���B0�`7
BIOS_SAVED_ATTRIBUTE_2	equ	$0D32		;.b ESC [s�ŕۑ����ꂽ��������2
BIOS_SAVED_FRACTION	equ	$0D33		;.b ESC [s�ŕۑ����ꂽ�J�[�\���̌����W�̒[��
BIOS_BUFFER_REQUEST	equ	$0D34		;.w �o�b�t�@�̕������\������̈�̃h�b�g���B0=�o�b�t�@�o�͒��ł͂Ȃ�
BIOS_BUFFER_WIDTH	equ	$0D36		;.w �o�b�t�@�̕�����̃h�b�g��
BIOS_BUFFER_POINTER	equ	$0D38		;.l �o�b�t�@�̏������݈ʒu
BIOS_BUFFER_ARRAY	equ	$0D3C		;.w[64] �o�b�t�@�B�E�񂹁A�����񂹂Ŏg��
BIOS_CONSOLE_STATUS	equ	$0DBC		;.b �R���\�[���̏�ԁB----|����|������|�E��|�A��
BIOS_ALIGN_LEFT_BIT	equ	     3		;����
BIOS_ALIGN_LEFT		equ	%00001000
BIOS_ALIGN_CENTER_BIT	equ	      2		;������
BIOS_ALIGN_CENTER	equ	%00000100
BIOS_ALIGN_RIGHT_BIT	equ	       1	;�E��
BIOS_ALIGN_RIGHT	equ	%00000010
BIOS_CONNECTION_BIT	equ	        0	;�A���B�Ō�ɕ`�悵�������͎Α̂ł��̌�J�[�\���𓮂����Ă��Ȃ��B�����Α̂Ȃ�΋l�߂ĕ`�悷��
BIOS_CONNECTION		equ	%00000001
;				$0DBD		;.b[3]

;----------------------------------------------------------------
;�J�[�\���_�ŏ������[�`��
;	Timer-C���荞�݃��[�`������500ms�Ԋu�ŌĂ΂��
timer_c_cursor:
	if	<tst.b BIOS_CURSOR_ON.w>,ne	;�J�[�\����\������Ƃ�
		ifor	<tst.w BIOS_CURSOR_NOT_BLINK.w>,eq,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;�_�ł����邩�A�`����Ă��Ȃ��Ƃ�
			if	<btst.b #1,CRTC_ACCESS>,eq	;CRTC�̃}�X�N���g�p���łȂ��Ƃ�
				bsr	toggle_cursor		;�J�[�\���𔽓]������
				not.b	BIOS_CURSOR_DRAWN.w	;�J�[�\�����`����Ă��邩�B0=�`����Ă��Ȃ�,-1=�`����Ă���
			endif
		endif
	endif
	rts

;----------------------------------------------------------------
;�J�[�\���𔽓]������
toggle_cursor:
	push	d0-d2/a0-a2
	move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
	swap.w	d0
	clr.w	d0			;65536*�s���W
	lsr.l	#5,d0			;128*16*�s���W
	move.w	BIOS_CURSOR_COLUMN.w,d1	;�J�[�\���̌����W
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d1	;�E�[�Ŏ~�܂�
	endif
	add.w	d1,d0
	add.l	BIOS_CONSOLE_OFFSET.w,d0
	add.l	#$00E00000,d0		;�J�[�\���̃A�h���X
	movea.l	d0,a2
	move.w	CRTC_ACCESS,-(sp)
	bclr.b	#0,CRTC_ACCESS		;�����A�N�Z�XOFF
***	move.w	BIOS_CURSOR_PATTERN.w,d1
***	if	eq
***		moveq.l	#-1,d1
***	endif
	moveq.l	#$80,d1
	move.b	BIOS_CURSOR_FRACTION.w,d0
	lsr.b	d0,d1
	bsr	toggle_cursor_1		;�v���[��0�𔽓]
***	lsr.w	#8,d1
	adda.l	#$00020000,a2
	bsr	toggle_cursor_1		;�v���[��1�𔽓]
	move.w	(sp)+,CRTC_ACCESS
	pop
	rts

toggle_cursor_1:
	move.w	BIOS_CURSOR_START.w,d2	;�J�[�\���`��J�n���C��*4
	jmp	@f(pc,d2.w)
@@:	eor.b	d1,(a2)
	movea.l	a0,a0			;nop
  .irp row,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	eor.b	d1,128*row(a2)
  .endm
	rts

;----------------------------------------------------------------
;IOCS�R�[��$1E _B_CURON �J�[�\����\������
iocs_1E_B_CURON:
	ifand	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq,<tst.b BIOS_CURSOR_ON.w>,eq	;������Ă��ĕ\�����Ă��Ȃ��Ƃ�
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;�^�C�}�J�E���^�B1��ڂ�10ms*5=50ms��ɔ���������
		st.b	BIOS_CURSOR_ON.w	;�\�����Ă���
		clr.b	BIOS_CURSOR_DRAWN.w	;�`����Ă��Ȃ�
	endif
	rts

;----------------------------------------------------------------
;IOCS�R�[��$1F _B_CUROFF �J�[�\����\�����Ȃ�
iocs_1F_B_CUROFF:
	if	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq	;������Ă���Ƃ�
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;�^�C�}�J�E���^�B1��ڂ�10ms*5=50ms��ɔ���������
		clr.b	BIOS_CURSOR_ON.w	;�\�����Ă��Ȃ�
		if	<tst.b BIOS_CURSOR_DRAWN.w>,ne	;�`����Ă���Ƃ�
			bsr	toggle_cursor		;�J�[�\���𔽓]������
			clr.b	BIOS_CURSOR_DRAWN.w	;�`����Ă��Ȃ�
		endif
	endif
	rts

;----------------------------------------------------------------
;IOCS�R�[��$20 _B_PUTC ������\������
;<d1.w:�����R�[�h
;>d0.l:�\����̃J�[�\���̌����W<<16|�J�[�\���̍s���W
iocs_20_B_PUTC:
	bsr	putc			;1�����\��
	move.l	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W<<16|�J�[�\���̍s���W
	rts

;----------------------------------------------------------------
;IOCS�R�[��$21 _B_PRINT �������\������
;<a1.l:������̃A�h���X
;>d0.l:�\����̃J�[�\���̌����W<<16|�J�[�\���̍s���W
;>a1.l:������̖�����0�̎��̃A�h���X�B�}�j���A���ɏ����Ă���B�ύX�s��
iocs_21_B_PRINT:
	push	d1
	dostart
		bsr	putc			;1�����\��
	start
		moveq.l	#0,d1
		move.b	(a1)+,d1
	while	ne
	pop
	move.l	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W<<16|�J�[�\���̍s���W
	rts

;----------------------------------------------------------------
;IOCS�R�[��$22 _B_COLOR ����������ݒ肷��
;<d1.w:���������B-1=�擾�̂�
;	0	��
;	1	���F
;	2	���F
;	3	��
;	4+	����
;	8+	���]
;>d0.l:�ݒ�O�̕��������B-1=�ݒ�l���͈͊O
iocs_22_B_COLOR:
	push	d1
	moveq.l	#0,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;��������2�B-|��t��|���t��|���|�ۈ͂�|�l�p�͂�|�v���|�[�V���i��|�g��
	lsl.w	#8,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;��������1�B��������|����|�Α�|�׎�|���]|����|�v���[��##
	if	<cmp.w #-1,d1>,ne	;�ݒ肷��Ƃ�
		if	<cmp.w #$7FFF,d1>,ls	;�ݒ�l���͈͓��̂Ƃ�
			move.b	d1,BIOS_ATTRIBUTE_1.w
			lsr.w	#8,d1
			move.b	d1,BIOS_ATTRIBUTE_2.w
		else				;�ݒ�l���͈͊O�̂Ƃ�
			moveq.l	#-1,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$23 _B_LOCATE �J�[�\���̍��W��ݒ肷��
;<d1.w:�J�[�\���̌����W�̒[��<<8|�J�[�\���̌����W�B-1=�擾�̂�
;<d2.w:�J�[�\���̍s���W
;>d0.l:�ݒ�O�̃J�[�\���̍��W�B�J�[�\���̌����W�̒[��<<24|�J�[�\���̌����W<<16|�J�[�\���̍s���W�B-1=�ݒ�l���͈͊O
;>d1.l:(IOCS.X,1.3�ȏ�)�擾�݂̂̂Ƃ�d0.l�Ɠ���
iocs_23_B_LOCATE:
	moveq.l	#0,d0
	move.b	BIOS_CURSOR_FRACTION.w,d0
	ror.l	#8,d0
	or.l	BIOS_CURSOR_COLUMN.w,d0	;BIOS_CURSOR_ROW�B�J�[�\���̌����W�̒[��<<24|�J�[�\���̌����W<<16|�J�[�\���̍s���W
	if	<cmp.w #-1,d1>,eq	;�擾�̂�
		move.l	d0,d1
		rts
	endif
	push	d1/d3
	move.w	d1,d3
	and.w	#$00FF,d1		;�J�[�\���̌����W
	lsr.w	#8,d3			;�J�[�\���̌����W�̒[��
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls,<cmp.w #7,d3>,ls	;�ݒ�l���͈͓��̂Ƃ�
;		push	d0
		bsr	iocs_1F_B_CUROFF
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		move.b	d3,BIOS_CURSOR_FRACTION.w
		bsr	iocs_1E_B_CURON
;		pop	d0
	else				;�ݒ�l���͈͊O�̂Ƃ�
		moveq.l	#-1,d0
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$24 _B_DOWN_S �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
;>d0.l:0
iocs_24_B_DOWN_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$25 _B_UP_S �J�[�\����1�s��ցB��[�ł̓X�N���[���_�E��
;>d0.l:0
iocs_25_B_UP_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi	;��[�ł͂Ȃ��Ƃ�
		subq.w	#1,d0			;1�s���
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;��[�̂Ƃ�
		moveq.l	#0,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;�R�s�[���̉��[�̍s���W
		moveq.l	#1,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		moveq.l	#0,d0			;��[�̍s���W
		moveq.l	#0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$26 _B_UP �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�
;<d1.b:�ړ�����s���B0=1�s
;>d0.l:0=����,-1=���s�B��[�𒴂���B���̂Ƃ��J�[�\���͓����Ȃ�
iocs_26_B_UP:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
	sub.w	d1,d0			;n�s���
	if	mi			;��[�𒴂���
		moveq.l	#-1,d1
	else				;��[�𒴂��Ȃ�
		move.w	d0,BIOS_CURSOR_ROW.w
		moveq.l	#0,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$27 _B_DOWN �J�[�\����n�s���ցB���[�Ŏ~�܂�
;<d1.b:�ړ�����s���B0=1�s
;>d0.l:0
iocs_27_B_DOWN:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
	add.w	d1,d0			;n�s����
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;���[�𒴂���
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$28 _B_RIGHT �J�[�\����n���E�ցB�E�[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
;>d0.l:0
iocs_28_B_RIGHT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W
	add.w	d1,d0			;n�s�E��
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;�E�[�𒴂���
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;�E�[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$29 _B_LEFT �J�[�\����n�����ցB���[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
;>d0.l:0
iocs_29_B_LEFT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W
	sub.w	d1,d0			;n�s����
	if	mi			;���[�𒴂���
		clr.w	d0			;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2A _B_CLR_ST �͈͂�I�����ĉ�ʂ�����
;<d1.b:�͈́B0=�J�[�\������E���܂�,1=���ォ��J�[�\���܂�,2=���ォ��E���܂ŁB�J�[�\���������
;>d0.l:0=����,-1=���s�B��������������
iocs_2A_B_CLR_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=�J�[�\������E���܂�
		bsr	putc_csi_0J		;ESC [0J �J�[�\������E���܂ŏ�������
		moveq.l	#0,d1
	elif	eq			;1=���ォ��J�[�\���܂�
		bsr	putc_csi_1J		;ESC [1J ���ォ��J�[�\���܂ŏ�������
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=���ォ��E���܂�
		bsr	putc_csi_2J		;ESC [2J ���ォ��E���܂ŏ�������B�J�[�\���������
		moveq.l	#0,d1
	else
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2B _B_ERA_ST �͈͂�I�����čs������
;<d1.b:�͈́B0=�J�[�\������E�[�܂�,1=���[����J�[�\���܂�,2=���[����E�[�܂�
;>d0.l:0=����,-1=���s�B��������������
iocs_2B_B_ERA_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=�J�[�\������E�[�܂�
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
		moveq.l	#0,d1
	elif	eq			;1=���[����J�[�\���܂�
		bsr	putc_csi_1K		;ESC [1K ���[����J�[�\���܂ŏ�������
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=���[����E�[�܂�
		bsr	putc_csi_2K		;ESC [2K ���[����E�[�܂ŏ�������
		moveq.l	#0,d1
	else				;��������������
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2C _B_INS �J�[�\�����牺��n�s�}���B�J�[�\�������[��
;<d1.w:�}������s���B0=1�s
;>d0.l:0
iocs_2C_B_INS:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_L		;ESC [nL �J�[�\�����牺��n�s�}���B�J�[�\�������[��
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2D _B_DEL �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
;<d1.w:�폜����s���B0=1�s
;>d0.l:0
iocs_2D_B_DEL:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_M		;ESC [nM �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2E _B_CONSOL �R���\�[���͈̔͂�ݒ�B�J�[�\���������
;<d1.l:����X�h�b�g���W<<16|����Y�h�b�g���W�B-1=�擾�̂݁B����X�h�b�g���W��8�̔{���A����Y�h�b�g���W��4�̔{��
;<d2.l:�E�[�̌����W<<16|���[�̍s���W�B-1=�擾�̂�
;>d0.l:0
;>d1.l:�ݒ�O�̍���X�h�b�g���W<<16|����Y�h�b�g���W
;>d2.l:�ݒ�O�̉E�[�̌����W<<16|���[�̍s���W
iocs_2E_B_CONSOL:
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CONSOLE_OFFSET.w,d0
	if	<cmp.l #-1,d1>,ne
		and.l	#($03F8<<16)|$03FC,d1
		move.l	d1,d0
		swap.w	d0		;����X�h�b�g���W
		lsr.w	#3,d0		;����X�h�b�g���W/8
		ext.l	d1
		lsl.l	#7,d1		;����Y�h�b�g���W*128
		add.w	d0,d1
		move.l	BIOS_CONSOLE_OFFSET.w,d0
		move.l	d1,BIOS_CONSOLE_OFFSET.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w�B�J�[�\���������
	endif
	moveq.l	#127,d1
	and.w	d0,d1			;����X�h�b�g���W/8
	lsl.w	#3,d1			;����X�h�b�g���W
	swap.w	d1
	lsr.l	#7,d0			;����Y�h�b�g���W
	move.w	d0,d1			;�ݒ�O�̍���X�h�b�g���W<<16|����Y�h�b�g���W
	move.l	BIOS_CONSOLE_RIGHT.w,d0	;BIOS_CONSOLE_BOTTOM.w
	if	<cmp.l #-1,d2>,ne
		and.l	#127<<16|63,d2
		move.l	d2,BIOS_CONSOLE_RIGHT.w	;BIOS_CONSOLE_BOTTOM.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w�B�J�[�\���������
	endif
	move.l	d0,d2			;�ݒ�O�̉E�[�̌����W<<16|���[�̍s���W
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$AE _OS_CURON �J�[�\���̕\����������
iocs_AE_OS_CURON:
	move.w	BIOS_TC_CURSOR_PERIOD.w,BIOS_TC_CURSOR_COUNTER.w	;�^�C�}�J�E���^�������l�ɂ���
	di				;�����݋֎~
	ifor	<tst.b BIOS_CURSOR_PROHIBITED.w>,ne,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;�֎~����Ă��邩�`����Ă��Ȃ��Ƃ�
		bsr	toggle_cursor		;�J�[�\���𔽓]������
		st.b	BIOS_CURSOR_DRAWN.w	;�`����Ă���
	endif
	st.b	BIOS_CURSOR_ON.w		;�\�����Ă���
	sf.b	BIOS_CURSOR_PROHIBITED.w	;������Ă���
	ei				;���荞�݋���
	rts

;----------------------------------------------------------------
;IOCS�R�[��$AF _OS_CUROF �J�[�\���̕\�����֎~����
iocs_AF_OS_CUROF:
	bsr	iocs_1F_B_CUROFF
	st.b	BIOS_CURSOR_PROHIBITED.w	;�֎~����Ă���
	rts

;----------------------------------------------------------------
;1�����\��
;<d1.w:�����R�[�h
putc:
	push	d0-d1
	if	<move.b BIOS_PUTC_POOL.w,d0>,eq	;1�o�C�g�ڂ̂Ƃ�
		if	<cmp.w #$001F,d1>,ls	;$0000�`$001F�̂Ƃ�
			bsr	putc_control		;���䕶������������
		elif	<cmp.w #$007F,d1>,ls	;$0020�`$007F�̂Ƃ�
			if	<cmp.w #$005C,d1>,eq	;$005C�̂Ƃ�
				if	<btst.b #0,SRAM_XCHG>,ne	;�����ϊ��t���O�B-----|$7C�b/$82�U|$7E�P/$81�`|$5C��/$80�_
					move.w	#$0080,d1		;$5C��$80
				endif
			elif	<cmp.w #$007E,d1>,eq	;$007E�̂Ƃ�
				if	<btst.b #1,SRAM_XCHG>,ne	;�����ϊ��t���O�B-----|$7C�b/$82�U|$7E�P/$81�`|$5C��/$80�_
					move.w	#$0081,d1		;$7E��$81
				endif
			elif	<cmp.w #$007C,d1>,eq	;$007C�̂Ƃ�
				if	<btst.b #2,SRAM_XCHG>,ne	;�����ϊ��t���O�B-----|$7C�b/$82�U|$7E�P/$81�`|$5C��/$80�_
					move.w	#$0082,d1		;$7C��$82
				endif
			endif
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		elif	<cmp.w #$009F,d1>,ls	;$0080�`$009F�̂Ƃ�
			move.b	d1,BIOS_PUTC_POOL.w	;1�o�C�g�ڂ̃v�[��
		elif	<cmp.w #$00DF,d1>,ls	;$00A0�`$00DF�̂Ƃ�
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		elif	<cmp.w #$00FF,d1>,ls	;$00E0�`$00FF�̂Ƃ�
			move.b	d1,BIOS_PUTC_POOL.w	;1�o�C�g�ڂ̃v�[��
		else				;$0100�`$FFFF�̂Ƃ�
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		endif
	else				;2�o�C�g�ڂ̂Ƃ�
		if	<cmp.b #$1B,d0>,eq	;1�o�C�g�ڂ�$1B�̂Ƃ��B�G�X�P�[�v�V�[�P���X�̏o�͒�
			bsr	putc_escape		;�G�X�P�[�v�V�[�P���X����������
		else				;1�o�C�g�ڂ�$1B�ł͂Ȃ��Ƃ�
			clr.b	BIOS_PUTC_POOL.w	;1�o�C�g�ڂ������
			lsl.w	#8,d0			;1�o�C�g��<<8
			move.b	d1,d0			;1�o�C�g��<<8|2�o�C�g��
			move.w	d0,d1			;1�o�C�g��<<8|2�o�C�g�ځB1�o�C�g�ڂ�����Ƃ�d1.w�̏�ʃo�C�g�͖��������
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;�o�b�t�@�o�͂��I������
putc_finish_buffer:
	push	d0-d6/a0-a1
	move.w	BIOS_BUFFER_REQUEST.w,d0
	goto	eq,putc_finish_buffer_end	;�o�b�t�@�o�͒��ł͂Ȃ�
;<d0.w:�o�b�t�@�̕������\������̈�̃h�b�g��
	move.w	BIOS_BUFFER_WIDTH.w,d1
;<d1.w:�o�b�t�@�̕�����̃h�b�g��
	movea.l	BIOS_BUFFER_POINTER.w,a0
;<a0.l:�o�b�t�@�̏������݈ʒu=������̒���
	lea.l	BIOS_BUFFER_ARRAY.w,a1
;<a1.l:�o�b�t�@=������̐擪
	clr.w	BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͏I���B�ċA�Ăяo���ŕ\������̂ł��̑O�ɏI�����邱��
	clr.w	BIOS_BUFFER_WIDTH.w
	move.l	a1,BIOS_BUFFER_POINTER.w
	sub.w	d1,d0			;�]��h�b�g��
;<d0.w:�]��h�b�g��
	if	ls			;�]��Ȃ��Ƃ�
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;���񂹂ŗ]��Ƃ�
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;�E���̗]�����͈͂���������
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	elif	<bclr.b #BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;�E�񂹂ŗ]��Ƃ�
	;�����̗]�����͈͂���������
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w>,ne	;�����񂹂ŗ]��Ƃ�
	;�����̗]�����͈͂���������
		move.w	d0,d6
		lsr.w	#1,d0			;�����̗]�����͈͂̃h�b�g��
		sub.w	d0,d6			;�E���̗]�����͈͂̃h�b�g��
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;�E���̗]�����͈͂���������
		move.w	d6,d0
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	endif
putc_finish_buffer_end:
	pop
	rts

;----------------------------------------------------------------
;���䕶������������
;<d1.w:�����R�[�h
putc_control:
	push	d0-d1
;�o�b�t�@�o�͂��I������
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;�o�b�t�@�o�͒�
		bsr	putc_finish_buffer	;�o�b�t�@�o�͂��I������
	endif
;�J�[�\�����E�[����͂ݏo���Ă���Ƃ�BS�łȂ���Ή��s����
	move.w	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi,<cmp.w #$0008,d1>,ne	;�J�[�\�����E�[����͂ݏo���Ă��邩��BS�ł͂Ȃ��Ƃ�
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;���䕶������������
	add.w	d1,d1
	move.w	putc_control_jump_table(pc,d1.w),d1
	jsr	putc_control_jump_table(pc,d1.w)
	pop
	rts

putc_control_jump_table:
	.dc.w	putc_00_NL-putc_control_jump_table	;���䕶��$00 NL 
	.dc.w	putc_01_SH-putc_control_jump_table	;���䕶��$01 SH 
	.dc.w	putc_02_SX-putc_control_jump_table	;���䕶��$02 SX 
	.dc.w	putc_03_EX-putc_control_jump_table	;���䕶��$03 EX 
	.dc.w	putc_04_ET-putc_control_jump_table	;���䕶��$04 ET 
	.dc.w	putc_05_EQ-putc_control_jump_table	;���䕶��$05 EQ 
	.dc.w	putc_06_AK-putc_control_jump_table	;���䕶��$06 AK 
	.dc.w	putc_07_BL-putc_control_jump_table	;���䕶��$07 BL �x����炷
	.dc.w	putc_08_BS-putc_control_jump_table	;���䕶��$08 BS �J�[�\����1�����ցB���[�ł�1�s��̉E�[�ցB��[�ł͉������Ȃ�
	.dc.w	putc_09_HT-putc_control_jump_table	;���䕶��$09 HT �J�[�\�������̃^�u���ցB�Ȃ����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
	.dc.w	putc_0A_LF-putc_control_jump_table	;���䕶��$0A LF �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
	.dc.w	putc_0B_VT-putc_control_jump_table	;���䕶��$0B VT �J�[�\����1�s��ցB��[�ł͉������Ȃ�
	.dc.w	putc_0C_FF-putc_control_jump_table	;���䕶��$0C FF �J�[�\����1���E�ցB�E�[�ł�1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
	.dc.w	putc_0D_CR-putc_control_jump_table	;���䕶��$0D CR �J�[�\�������[��
	.dc.w	putc_0E_SO-putc_control_jump_table	;���䕶��$0E SO 
	.dc.w	putc_0F_SI-putc_control_jump_table	;���䕶��$0F SI 
	.dc.w	putc_10_DE-putc_control_jump_table	;���䕶��$10 DE 
	.dc.w	putc_11_D1-putc_control_jump_table	;���䕶��$11 D1 
	.dc.w	putc_12_D2-putc_control_jump_table	;���䕶��$12 D2 
	.dc.w	putc_13_D3-putc_control_jump_table	;���䕶��$13 D3 
	.dc.w	putc_14_D4-putc_control_jump_table	;���䕶��$14 D4 
	.dc.w	putc_15_NK-putc_control_jump_table	;���䕶��$15 NK 
	.dc.w	putc_16_SN-putc_control_jump_table	;���䕶��$16 SN 
	.dc.w	putc_17_EB-putc_control_jump_table	;���䕶��$17 EB 
	.dc.w	putc_18_CN-putc_control_jump_table	;���䕶��$18 CN 
	.dc.w	putc_19_EM-putc_control_jump_table	;���䕶��$19 EM 
	.dc.w	putc_1A_SB-putc_control_jump_table	;���䕶��$1A SB ���ォ��E���܂ŏ����B�J�[�\���������
	.dc.w	putc_1B_EC-putc_control_jump_table	;���䕶��$1B EC �G�X�P�[�v�V�[�P���X�J�n
	.dc.w	putc_1C_FS-putc_control_jump_table	;���䕶��$1C FS 
	.dc.w	putc_1D_GS-putc_control_jump_table	;���䕶��$1D GS 
	.dc.w	putc_1E_RS-putc_control_jump_table	;���䕶��$1E RS �J�[�\���������
	.dc.w	putc_1F_US-putc_control_jump_table	;���䕶��$1F US 

;----------------------------------------------------------------
;���䕶��$00 NL 
putc_00_NL:
	rts

;----------------------------------------------------------------
;���䕶��$01 SH 
putc_01_SH:
	rts

;----------------------------------------------------------------
;���䕶��$02 SX 
putc_02_SX:
	rts

;----------------------------------------------------------------
;���䕶��$03 EX 
putc_03_EX:
	rts

;----------------------------------------------------------------
;���䕶��$04 ET 
putc_04_ET:
	rts

;----------------------------------------------------------------
;���䕶��$05 EQ 
putc_05_EQ:
	rts

;----------------------------------------------------------------
;���䕶��$06 AK 
putc_06_AK:
	rts

;----------------------------------------------------------------
;���䕶��$07 BL �x����炷
putc_07_BL:
	push	d0-d2/a0-a1
	move.l	BIOS_BEEP_DATA.w,d0	;BEEP����ADPCM�f�[�^�̃A�h���X�B-1=BIOS_BEEP_EXTENSION���g��
	moveq.l	#-1,d1
	if	<cmp.l d1,d0>,eq
		movea.l	BIOS_BEEP_EXTENSION.w,a0	;BEEP�����܂邲�ƍ����������[�`���̃A�h���X�BBIOS_BEEP_DATA=-1�̂Ƃ��L��
		jsr	(a0)
	else
		move.w	#4<<8|3,d1
		moveq.l	#0,d2
		move.w	BIOS_BEEP_LENGTH.w,d2	;BEEP����ADPCM�f�[�^�̃o�C�g���B0=����
		movea.l	d0,a1
		IOCS	_ADPCMOUT
	endif
	pop
	rts

;----------------------------------------------------------------
;���䕶��$08 BS �J�[�\����1�����ցB���[�ł�1�s��̉E�[�ցB��[�ł͉������Ȃ�
putc_08_BS:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	ne
		subq.w	#1,d0			;1������
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else
		move.w	BIOS_CURSOR_ROW.w,d0
		if	ne
			subq.w	#1,d0			;1�s���
			move.w	d0,BIOS_CURSOR_ROW.w
			move.w	BIOS_CONSOLE_RIGHT.w,BIOS_CURSOR_COLUMN.w	;�E�[��
			clr.b	BIOS_CURSOR_FRACTION.w
		endif
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$09 HT �J�[�\�������̃^�u���ցB�Ȃ����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
putc_09_HT:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	addq.w	#8,d0
	and.w	#-8,d0			;���̃^�u����
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,ls	;�͈͓�
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;�͈͊O
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0A LF �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
putc_0A_LF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0B VT �J�[�\����1�s��ցB��[�ł͉������Ȃ�
putc_0B_VT:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	hi
		subq.w	#1,d0			;1�s���
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0C FF �J�[�\����1���E�ցB�E�[�ł�1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
putc_0C_FF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,lo	;�E�[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1���E��
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;�E�[�̂Ƃ�
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0D CR �J�[�\�������[��
putc_0D_CR:
	push	d0
	bsr	iocs_1F_B_CUROFF
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0E SO 
putc_0E_SO:
	rts

;----------------------------------------------------------------
;���䕶��$0F SI 
putc_0F_SI:
	rts

;----------------------------------------------------------------
;���䕶��$10 DE 
putc_10_DE:
	rts

;----------------------------------------------------------------
;���䕶��$11 D1 
putc_11_D1:
	rts

;----------------------------------------------------------------
;���䕶��$12 D2 
putc_12_D2:
	rts

;----------------------------------------------------------------
;���䕶��$13 D3 
putc_13_D3:
	rts

;----------------------------------------------------------------
;���䕶��$14 D4 
putc_14_D4:
	rts

;----------------------------------------------------------------
;���䕶��$15 NK 
putc_15_NK:
	rts

;----------------------------------------------------------------
;���䕶��$16 SN 
putc_16_SN:
	rts

;----------------------------------------------------------------
;���䕶��$17 EB 
putc_17_EB:
	rts

;----------------------------------------------------------------
;���䕶��$18 CN 
putc_18_CN:
	rts

;----------------------------------------------------------------
;���䕶��$19 EM 
putc_19_EM:
	rts

;----------------------------------------------------------------
;���䕶��$1A SB ���ォ��E���܂ŏ����B�J�[�\���������
putc_1A_SB:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;��[�̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	clr.l	BIOS_CURSOR_COLUMN.w	;�����
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$1B EC �G�X�P�[�v�V�[�P���X�J�n
putc_1B_EC:
	move.b	#$1B,BIOS_PUTC_POOL.w	;1�o�C�g�ڂ̃v�[��
	move.l	#BIOS_ESCAPE_BUFFER,BIOS_ESCAPE_POINTER.w	;�G�X�P�[�v�V�[�P���X�o�b�t�@�̏������݈ʒu
	rts

;----------------------------------------------------------------
;���䕶��$1C FS 
putc_1C_FS:
	rts

;----------------------------------------------------------------
;���䕶��$1D GS 
putc_1D_GS:
	rts

;----------------------------------------------------------------
;���䕶��$1E RS �J�[�\���������
putc_1E_RS:
	bsr	iocs_1F_B_CUROFF
	clr.l	BIOS_CURSOR_COLUMN.w
	bsr	iocs_1E_B_CURON
	rts

;----------------------------------------------------------------
;���䕶��$1F US 
putc_1F_US:
	rts

;----------------------------------------------------------------
;�G�X�P�[�v�V�[�P���X����������
;<d1.w:�����R�[�h
putc_escape:
	push	d0/a0
	movea.l	BIOS_ESCAPE_POINTER.w,a0
	move.b	d1,(a0)+
	if	<cmpa.l #BIOS_ESCAPE_BUFFER+10,a0>,lo
		move.l	a0,BIOS_ESCAPE_POINTER.w
	endif
	move.b	BIOS_ESCAPE_BUFFER.w,d0	;�G�X�P�[�v�V�[�P���X�̍ŏ��̕���
	if	<cmp.b #'[',d0>,eq	;ESC [
		moveq.l	#$20,d0
		or.b	d1,d0
		ifand	<cmp.b #'`',d0>,hs,<cmp.b #'z',d0>,ls	;'@'�`'Z','`'�`'z'
			bsr	putc_csi
		endif
	elif	<cmp.b #'*',d0>,eq	;ESC *
		bsr	putc_esc_ast
	elif	<cmp.b #'=',d0>,eq	;ESC =
		if	<cmpa.l #BIOS_ESCAPE_BUFFER+3,a0>,eq
			bsr	putc_esc_equ
		endif
	elif	<cmp.b #'D',d0>,eq	;ESC D
		bsr	putc_esc_D
	elif	<cmp.b #'E',d0>,eq	;ESC E
		bsr	putc_esc_E
	elif	<cmp.b #'M',d0>,eq	;ESC M
		bsr	putc_esc_M
	else				;���̑�
		clr.b	BIOS_PUTC_POOL.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC *
;	���ォ��E���܂ŏ����B�J�[�\���������
putc_esc_ast:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;��[�̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	clr.l	BIOS_CURSOR_COLUMN.w	;�J�[�\���������
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC = r c
;	�J�[�\����r-' '�s,c-' '���ցBr��c�͕���
putc_esc_equ:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	moveq.l	#0,d1
	moveq.l	#0,d2
	move.b	BIOS_ESCAPE_BUFFER+2.w,d1	;���B' '=0
	move.b	BIOS_ESCAPE_BUFFER+1.w,d2	;�s�B' '=0
	moveq.l	#' ',d0
	sub.w	d0,d1			;�����W
	sub.w	d0,d2			;�s���W
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls	;�R���\�[���͈͓̔��̂Ƃ�
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC D
;	�J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
;	_B_DOWN_S�Ɠ���
putc_esc_D:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC E
;	�J�[�\����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v
putc_esc_E:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC M
;	�J�[�\����1�s��ցB��[�ł̓X�N���[���_�E��
;	_B_UP_S�Ɠ���
putc_esc_M:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi		;��[�ł͂Ȃ��Ƃ�
		subq.w	#1,d0			;1�s���
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;��[�̂Ƃ�
		moveq.l	#0,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;�R�s�[���̉��[�̍s���W
		moveq.l	#1,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		moveq.l	#0,d0			;��[�̍s���W
		moveq.l	#0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC [
;	https://en.wikipedia.org/wiki/ANSI_escape_code
;	http://nanno.dip.jp/softlib/man/rlogin/ctrlcode.html
putc_csi:
	push	d0-d3/a0
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CSI_EXTENSION.w,d0	;�G�X�P�[�v�V�[�P���X�ۂ��ƍ����ւ����[�`��
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	else
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		move.w	(a0)+,d0
		if	<cmp.w #'[>',d0>,eq	;ESC [>
			move.w	(a0)+,d0
			if	<cmp.w #'5l',d0>,eq	;ESC [>5l �J�[�\��ON
				sf.b	BIOS_CURSOR_PROHIBITED.w
			elif	<cmp.w #'5h',d0>,eq	;ESC [>5h �J�[�\��OFF
				st.b	BIOS_CURSOR_PROHIBITED.w
			else
				bsr	putc_csi_extension
			endif
		elif	<cmp.w #'[?',d0>,eq	;ESC [?
			move.w	(a0)+,d0
			if	<cmp.w #'4l',d0>,eq	;ESC [?4l �W�����v�X�N���[��
				clr.w	BIOS_SMOOTH_SCROLL.w
			elif	<cmp.w #'4h',d0>,eq	;ESC [?4h 8�h�b�g�X���[�X�X�N���[��
				move.w	#2,BIOS_SMOOTH_SCROLL.w
			else
				bsr	putc_csi_extension
			endif
		else
			lea.l	BIOS_ESCAPE_BUFFER+1.w,a0	;[�̎�
			moveq.l	#0,d0
			moveq.l	#-1,d1			;1�Ԗڂ̐��l
			moveq.l	#-1,d2			;2�Ԗڂ̐��l
			moveq.l	#-1,d3			;3�Ԗڂ̐��l
			do
				move.b	(a0)+,d0
			while	<cmp.b #' ',d0>,eq
			ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				moveq.l	#0,d1
				do
					sub.b	#'0',d0
					mulu.w	#10,d1
					add.w	d0,d1
					move.b	(a0)+,d0
				whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				if	<cmp.b #';',d0>,eq
					do
						move.b	(a0)+,d0
					while	<cmp.b #' ',d0>,eq
					ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						moveq.l	#0,d2
						do
							sub.b	#'0',d0
							mulu.w	#10,d2
							add.w	d0,d2
							move.b	(a0)+,d0
						whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						if	<cmp.b #';',d0>,eq
							do
								move.b	(a0)+,d0
							while	<cmp.b #' ',d0>,eq
							ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
								moveq.l	#0,d3
								do
									sub.b	#'0',d0
									mulu.w	#10,d3
									add.w	d0,d3
									move.b	(a0)+,d0
								whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
							endif
						endif
					endif
				endif
			endif
			if	<cmp.b #'@',d0>,eq
				bsr	putc_csi_at		;ESC [n@ �J�[�\������E��n���}��
			elif	<cmp.b #'A',d0>,eq
				bsr	putc_csi_A		;ESC [nA �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�
			elif	<cmp.b #'B',d0>,eq
				bsr	putc_csi_B		;ESC [nB �J�[�\����n�s���ցB���[�Ŏ~�܂�
			elif	<cmp.b #'C',d0>,eq
				bsr	putc_csi_C		;ESC [nC �J�[�\����n���E�ցB�E�[�Ŏ~�܂�
			elif	<cmp.b #'D',d0>,eq
				bsr	putc_csi_D		;ESC [nD �J�[�\����n�����ցB���[�Ŏ~�܂�
			elif	<cmp.b #'H',d0>,eq
				bsr	putc_csi_H		;ESC [r;cH �J�[�\����r-1�s,c-1����
			elif	<cmp.b #'J',d0>,eq
				bsr	putc_csi_J		;ESC [nJ ��ʂ���������
			elif	<cmp.b #'K',d0>,eq
				bsr	putc_csi_K		;ESC [nK �s����������
			elif	<cmp.b #'L',d0>,eq
				bsr	putc_csi_L		;ESC [nL �J�[�\�����牺��n�s�}���B�J�[�\�������[��
			elif	<cmp.b #'M',d0>,eq
				bsr	putc_csi_M		;ESC [nM �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
			elif	<cmp.b #'P',d0>,eq
				bsr	putc_csi_P		;ESC [nP �J�[�\������E��n���폜
			elif	<cmp.b #'R',d0>,eq
				bsr	putc_csi_R		;ESC [r;cR CSR(Cursor Position Report)
			elif	<cmp.b #'X',d0>,eq
				bsr	putc_csi_X		;ESC [nX �J�[�\������E��n������
			elif	<cmp.b #'c',d0>,eq
				bsr	putc_csi_c		;ESC [nc ������
			elif	<cmp.b #'f',d0>,eq
				bsr	putc_csi_f		;ESC [r;cf �J�[�\����r-1�s,c-1����
			elif	<cmp.b #'l',d0>,eq
				bsr	putc_csi_l		;ESC [nl ����
			elif	<cmp.b #'m',d0>,eq
				bsr	putc_csi_m		;ESC [nm ����������ݒ肷��
			elif	<cmp.b #'n',d0>,eq
				bsr	putc_csi_n		;ESC [nn DSR(Device Status Report)
			elif	<cmp.b #'r',d0>,eq
				bsr	putc_csi_r		;ESC [nr �E��
			elif	<cmp.b #'s',d0>,eq
				bsr	putc_csi_s		;ESC [ns �J�[�\���̍��W�ƕ���������ۑ�����
			elif	<cmp.b #'u',d0>,eq
				bsr	putc_csi_u		;ESC [nu �J�[�\���̍��W�ƕ��������𕜌�����
			else
				bsr	putc_csi_extension
			endif
		endif
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;�g���G�X�P�[�v�V�[�P���X�������[�`�����Ăяo��
putc_csi_extension:
	push	d0/a0
	move.l	BIOS_ESCAPE_EXTENSION.w,d0
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [n@ �J�[�\������E��n���}��
;<d1.w:�}�����錅���B0=1��
putc_csi_at:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
;
;	�`�a�b�c�d�e�f�g�h
;	�`�a�b�@�@�@�@�c�d
;
	move.w	BIOS_CURSOR_COLUMN.w,d4
	add.w	d1,d4			;�J�[�\���̌����W+�}�����錅��=�ړ���̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3
	sub.w	d4,d3			;�R���\�[���̉E�[-�ړ���̌����W=�ړ����镔���̌���-1
	if	lo			;���ׂĉ����o�����
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
	else				;�ړ����镔��������
		move.w	BIOS_CURSOR_ROW.w,d0	;�s���W
		swap.w	d0
		clr.w	d0			;65536*�s���W
		lsr.l	#5,d0			;128*16*�s���W
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;�s�̍��[�̃A�h���X
		movea.l	a2,a3
		adda.w	BIOS_CURSOR_COLUMN.w,a2	;�J�[�\���̃A�h���X
		adda.w	d3,a2			;�ړ����̉E�[�̃A�h���X
		adda.w	BIOS_CONSOLE_RIGHT.w,a3	;�s�̉E�[�̃A�h���X=�ړ���̉E�[�̃A�h���X
		do				;�v���[���̃��[�v
			moveq.l	#16-1,d2
			for	d2			;���X�^�̃��[�v
				lea.l	1(a2),a0		;�ړ����̉E�[�̃A�h���X+1
				lea.l	1(a3),a1		;�ړ���̉E�[�̃A�h���X+1
				move.w	d3,d1			;�ړ����镔���̌���-1
				for	d1			;���̃��[�v
					move.b	-(a0),-(a1)
				next
				lea.l	128(a2),a2		;���̃��X�^
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;���̃v���[��
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
		move.w	d4,d3
		subq.w	#1,d3			;�E�[�̌����W
		moveq.l	#0,d4			;���[�̌����W�̒[��
		moveq.l	#7,d5			;�E�[�̌����W�̒[��
		bsr	putc_clear		;�s����������
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nA �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�
;<d1.w:�ړ�����s���B0=1�s
putc_csi_A:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	sub.w	d1,d0			;n�s���
	if	hs			;��[�𒴂��Ȃ��Ƃ�
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nB �J�[�\����n�s���ցB���[�Ŏ~�܂�
;<d1.w:�ړ�����s���B0=1��
putc_csi_B:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	add.w	d1,d0			;n�s����
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;���[�𒴂���Ƃ�
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nC �J�[�\����n���E�ցB�E�[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
putc_csi_C:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	add.w	d1,d0			;n���E��
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;�E�[�𒴂���Ƃ�
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;�E�[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nD �J�[�\����n�����ցB���[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
putc_csi_D:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	sub.w	d1,d0			;n������
	if	lo			;���[�𒴂���Ƃ�
		moveq.l	#0,d0			;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cf �J�[�\����r-1�s,c-1����
;<d1.w:�ړ���̍s���W+1�B0=��[�B���[�Ŏ~�܂�
;<d2.w:�ړ���̌����W+1�B0=���[�B�E�[�Ŏ~�܂�
putc_csi_f:
;----------------------------------------------------------------
;ESC [r;cH �J�[�\����r-1�s,c-1����
;<d1.w:�ړ���̍s���W+1�B0=��[�B���[�Ŏ~�܂�
;<d2.w:�ړ���̌����W+1�B0=���[�B�E�[�Ŏ~�܂�
putc_csi_H:
	push	d1-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=��[
	endif
	subq.w	#1,d1
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d1>,hi
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�Ŏ~�܂�
	endif
	ifor	<cmp.w #-1,d2>,eq,<tst.w d2>,eq
		moveq.l	#1,d2			;0=���[
	endif
	subq.w	#1,d2
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d2>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d2	;�E�[�Ŏ~�܂�
	endif
	move.w	d2,BIOS_CURSOR_COLUMN.w
	move.w	d1,BIOS_CURSOR_ROW.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nJ ��ʂ���������
;<d1.w:0=�J�[�\������E���܂�,1=���ォ��J�[�\���܂�,2=���ォ��E���܂ŁB�J�[�\���������
putc_csi_J:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0J		;ESC [0J �J�[�\������E���܂ŏ�������
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1J		;ESC [1J ���ォ��J�[�\���܂ŏ�������
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2J		;ESC [2J ���ォ��E���܂ŏ�������B�J�[�\���������
	endif
	rts

;----------------------------------------------------------------
;ESC [0J �J�[�\������E���܂ŏ�������
putc_csi_0J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0
	move.w	BIOS_CONSOLE_BOTTOM.w,d1
	if	<cmp.w d1,d0>,lo		;���[�ł͂Ȃ��Ƃ�
	;	move.w	BIOS_CURSOR_ROW.w,d0
		addq.w	#1,d0			;��[�̍s���W
	;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
	moveq.l	#0,d4
	move.b	BIOS_CURSOR_FRACTION.w,d4	;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [1J ���ォ��J�[�\���܂ŏ�������
putc_csi_1J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d1
	if	<tst.w d1>,hi			;��[�ł͂Ȃ��Ƃ�
		clr.w	d0			;��[�̍s���W
	;	move.w	BIOS_CURSOR_ROW.w,d1
		subq.w	#1,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	moveq.l	#0,d2			;���[�̌����W
	move.w	BIOS_CURSOR_COLUMN.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5
	add.b	BIOS_CURSOR_FRACTION.w,d5	;�E�[�̌����W�̒[��
	if	<cmp.w #7,d5>,hi	;���̌��̂Ƃ�
		if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,lo	;�E�[�ł͂Ȃ��Ƃ�
			addq.w	#1,d3
			subq.w	#8,d5
		else				;�E�[�̂Ƃ�
			moveq.l	#7,d5
		endif
	endif
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [2J ���ォ��E���܂ŏ�������B�J�[�\���������
putc_csi_2J:
	push	d0-d1
	moveq.l	#0,d0			;��[�̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	clr.l	BIOS_CURSOR_COLUMN.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nK �s����������
;<d1.w:0=�J�[�\������E�[�܂�,1=���[����J�[�\���܂�,2=���[����E�[�܂�
putc_csi_K:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1K		;ESC [1K ���[����J�[�\���܂ŏ�������
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2K		;ESC [2K ���[����E�[�܂ŏ�������
	endif
	rts

;----------------------------------------------------------------
;ESC [0K �J�[�\������E�[�܂ŏ�������
putc_csi_0K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [1K ���[����J�[�\���܂ŏ�������
putc_csi_1K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	moveq.l	#0,d2			;���[�̌����W
	move.w	BIOS_CURSOR_COLUMN.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [2K ���[����E�[�܂ŏ�������
putc_csi_2K:
	push	d0-d1
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	pop
	rts

;----------------------------------------------------------------
;ESC [nL �J�[�\�����牺��n�s�}���B�J�[�\�������[��
;<d1.w:�}������s���B0=1�s
putc_csi_L:
	push	d0-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:�J�[�\���̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d2	;�R���\�[���̍s��-1
	addq.w	#1,d2			;�R���\�[���̍s��
	sub.w	d0,d2			;�J�[�\�����牺�̍s��
	sub.w	d1,d2			;��ʓ��Ɏc��s��
;<d2.w:��ʓ��Ɏc��s��
	if	ls			;��ʓ��Ɏc��s���Ȃ��B���ׂĉ�ʊO�ɉ����o�����
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������
	;  ����������  ����������
	;  ����������  ����������
	;  ����������  ����������
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	else				;��ʓ��Ɏc��s������
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������\d1
	;  ����������  ����������/
	;  ����������  ����������)d2
	;  ����������  ����������
		add.w	d0,d2
		subq.w	#1,d2			;�R�s�[���̉��[�̍s���W
		add.w	d0,d1			;�R�s�[��̏�[�̍s���W
		exg.l	d1,d2
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;�R�s�[���̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		exg.l	d1,d2
		subq.w	#1,d1			;���[�̍s���W
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nM �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
;<d1.w:�폜����s���B0=1�s
putc_csi_M:
	push	d0-d3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:�J�[�\���̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d3	;�R���\�[���̍s��-1
	addq.w	#1,d3			;�R���\�[���̍s��
	sub.w	d0,d3			;�J�[�\�����牺�̍s��
	sub.w	d1,d3			;��ʓ��Ɏc��s��
;<d3.w:��ʓ��Ɏc��s��
	if	ls			;��ʓ��Ɏc��s���Ȃ��B���ׂč폜�����
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������
	;  ����������  ����������
	;  ����������  ����������
	;  ����������  ����������
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	else				;��ʓ��Ɏc��s������
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������)d3
	;  ����������  ����������\d1
	;  ����������  ����������/
	;  ����������  ����������
	;;;	move.w	BIOS_CURSOR_ROW.w,d0
		move.w	d0,d2			;�R�s�[��̏�[�̍s���W
		add.w	d1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	d2,d0
		add.w	d3,d0			;��[�̍s���W
	;;;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nP �J�[�\������E��n���폜
;<d1.w:�폜���錅���B0=1��
putc_csi_P:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
;
;	�`�a�b�c�d�e�f�g�h
;	�`�a�b�g�h�@�@�@�@
;
	move.w	BIOS_CURSOR_COLUMN.w,d4	;�J�[�\���̌����W
	add.w	d1,d4			;�J�[�\���̌����W+�폜���錅��=�ړ����̍��[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�R���\�[���̉E�[�̌����W=�ړ����̉E�[�̌����W
	sub.w	d4,d3			;�ړ����̉E�[�̌����W-�ړ����̍��[�̌����W=�ړ����镔���̌���-1
	if	lo			;���ׂč폜�����
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
	else				;�ړ����镔��������
		move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
		swap.w	d0
		clr.w	d0			;65536*�J�[�\���̍s���W
		lsr.l	#5,d0			;128*16*�J�[�\���̍s���W
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;�J�[�\���̍s�̍��[�̃A�h���X
		movea.l	a2,a3
		adda.w	d4,a2			;�J�[�\���̍s�̍��[�̃A�h���X+�ړ����̍��[�̌����W=�ړ����̍��[�̃A�h���X
		adda.w	BIOS_CURSOR_COLUMN.w,a3	;�J�[�\���̍s�̍��[�̃A�h���X+�J�[�\���̌����W=�J�[�\���̃A�h���X=�ړ���̍��[�̃A�h���X
		do				;�v���[���̃��[�v
			moveq.l	#16-1,d2
			for	d2			;���X�^�̃��[�v
				movea.l	a2,a0			;�ړ����̍��[�̃A�h���X
				movea.l	a3,a1			;�ړ���̍��[�̃A�h���X
				move.w	d3,d1			;�ړ����镔���̌���-1
				for	d1			;���̃��[�v
					move.b	(a0)+,(a1)+
				next
				lea.l	128(a2),a2		;���̃��X�^
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;���̃v���[��
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W=��������͈͂̏�[�̍s���W
		move.w	d0,d1			;�J�[�\���̍s���W=��������͈͂̉��[�̍s���W
		move.w	BIOS_CURSOR_COLUMN.w,d2	;�J�[�\���̌����W
		add.w	d3,d2			;�J�[�\���̌����W+�ړ�����͈͂̌���-1
		addq.w	#1,d2			;�J�[�\���̌����W+�ړ�����͈͂̌���=��������͈͂̍��[�̌����W
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;�R���\�[���̉E�[�̌����W=��������͈͂̉E�[�̌����W
		moveq.l	#0,d4			;��������͈͂̍��[�̌����W�̒[��
		moveq.l	#7,d5			;��������͈͂̉E�[�̌����W�̒[��
		bsr	putc_clear		;�s����������
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cR CPR(Cursor Position Report)
;	DSR(Device Status Report)�̕ԓ��B�����ł͉������Ȃ�
putc_csi_R:
	rts

;----------------------------------------------------------------
;ESC [nX �J�[�\������E��n������
;<d1.w:�������錅���B0=1��
putc_csi_X:
	push	d0-d5
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
	move.w	d2,d3
	add.w	d1,d3
	subq.w	#1,d3			;�E�[�̌����W
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,hi	;�E�[�𒴂���Ƃ�
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�Ŏ~�܂�
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	moveq.l	#7,d4
	and.b	BIOS_CURSOR_FRACTION.w,d4	;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [nc ������
;<d1.w:�h�b�g��
putc_csi_c:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	if	<cmp.w d0,d1>,ls	;�傫�����Ȃ�
		bset.b	#BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w	;������
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͊J�n
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nl ����
;<d1.w:�h�b�g��
putc_csi_l:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	if	<cmp.w d0,d1>,ls	;�傫�����Ȃ�
		bset.b	#BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w	;����
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͊J�n
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nm ����������ݒ肷��
;	0	���Z�b�g
;	1	����
;	2	�׎�
;	3	�Α�
;	4	����
;	5	(�x���_��)
;	6	(�����_��)
;	7	���]
;	8	(�閧)
;	9	��������
;	11�`19	(��փt�H���g1�`9)
;	20	(�u���b�N���^�[)
;	21	�g��
;	22	�����A�׎�����
;	23	�Α̉����A(�u���b�N���^�[����)
;	24	�����A�g������
;	25	(�x���_�ŉ����A�����_�ŉ���)
;	26	�v���|�[�V���i��
;	27	���]����
;	28	(�閧����)
;	29	������������
;	30	��
;	31	���F
;	32	���F
;	33	��
;	34	�����A��
;	35	�����A���F
;	36	�����A���F
;	37	�����A��
;	40	���]�A��
;	41	���]�A���F
;	42	���]�A���F
;	43	���]�A��
;	44	���]�A�����A��
;	45	���]�A�����A���F
;	46	���]�A�����A���F
;	47	���]�A�����A��
;	50	�v���|�[�V���i������
;	51	�l�p�͂�
;	52	�ۈ͂�
;	53	���
;	54	�l�p�͂݁A�ۈ͂݉���
;	55	�������
;	73	��t��
;	74	���t��
;	75	��t���A���t������
;<d1.w:�����B-1=�w��Ȃ�
;<d2.w:�����B-1=�w��Ȃ�
;<d3.w:�����B-1=�w��Ȃ�
putc_csi_m:
	push	d1
	bsr	putc_csi_m_1
	if	<cmp.w #-1,d2>,ne
		move.w	d2,d1
		bsr	putc_csi_m_1
	endif
	if	<cmp.w #-1,d3>,ne
		move.w	d3,d1
		bsr	putc_csi_m_1
	endif
	pop
	rts

;?d1
putc_csi_m_1:
;�����Ɣ��]�̂݃g�O������B���̑���ON�܂���OFF�̂ǂ��炩
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		move.b	#3,BIOS_ATTRIBUTE_1.w	;��������1�B��������|����|�Α�|�׎�|���]|����|�v���[��##
		clr.b	BIOS_ATTRIBUTE_2.w	;��������2�B-|��t��|���t��|���|�ۈ͂�|�l�p�͂�|�v���|�[�V���i��|�g��
	elif	<cmp.w #1,d1>,eq
		bchg.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;����
		if	eq			;OFF��ON�̂Ƃ�
			bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;�׎�����
		endif
	elif	<cmp.w #2,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bset.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;�׎�
	elif	<cmp.w #3,d1>,eq
		bset.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;�Α�
	elif	<cmp.w #4,d1>,eq
		bset.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;����
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;�g������
	elif	<cmp.w #7,d1>,eq
		bchg.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;���]
	elif	<cmp.w #9,d1>,eq
		bset.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;��������
	elif	<cmp.w #21,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bset.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;�g��
	elif	<cmp.w #22,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;�׎�����
	elif	<cmp.w #23,d1>,eq
		bclr.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;�Α̉���
	elif	<cmp.w #24,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;�g������
	elif	<cmp.w #26,d1>,eq
		bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;�v���|�[�V���i��
	elif	<cmp.w #27,d1>,eq
		bclr.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;���]����
	elif	<cmp.w #29,d1>,eq
		bclr.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;������������
	elifand	<cmp.w #30,d1>,hs,<cmp.w #37,d1>,ls
		sub.w	#30,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elifand	<cmp.w #40,d1>,hs,<cmp.w #47,d1>,ls
		sub.w	#40,d1
		addq.b	#8,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elif	<cmp.w #50,d1>,eq
		bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;�v���|�[�V���i������
	elif	<cmp.w #51,d1>,eq
		bset.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;�l�p�͂�
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;�ۈ͂݉���
	elif	<cmp.w #52,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;�l�p�͂݉���
		bset.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;�ۈ͂�
	elif	<cmp.w #53,d1>,eq
		bset.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;���
	elif	<cmp.w #54,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;�l�p�͂݉���
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;�ۈ͂݉���
	elif	<cmp.w #55,d1>,eq
		bclr.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;�������
	elif	<cmp.w #73,d1>,eq
		bset.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;��t��
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;���t������
	elif	<cmp.w #74,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;��t������
		bset.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;���t��
	elif	<cmp.w #75,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;��t������
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;���t������
	endif
	rts

;----------------------------------------------------------------
;ESC [nn DSR(Device Status Report)
;<d1.w:6
putc_csi_n:
	push	d0-d2/a0
	if	<cmp.w #6,d1>,eq	;CPR(Cursor Position Report)
		move.w	#$0100+27,d2
		bsr	20f
		move.w	#$1C00+'[',d2
		bsr	20f
		move.w	BIOS_CURSOR_ROW.w,d0
		bsr	10f
		move.w	#$2700+';',d2
		bsr	20f
		move.w	BIOS_CURSOR_COLUMN.w,d0
		bsr	10f
		move.w	#$1400+'R',d2
		bsr	20f
	endif
	pop
	rts

;���l+1�𕶎���ɕϊ����ăL�[���̓o�b�t�@�ɏ�������
;<d0.b:���l�B255�͕s�B�����ł�1���ȗ����Ȃ�
;?d0-d2/a0
10:	addq.b	#1,d0
	move.l	#(1<<24)+(10<<16)+(100<<8),d1
	do
		lsr.l	#8,d1
	while	<cmp.b d1,d0>,lo
	do
		moveq.l	#-2,d2
		do
			addq.w	#2,d2
			sub.b	d1,d0
		while	hs
		move.w	15f(pc,d2.w),d2
		bsr	20f
		add.b	d1,d0
		lsr.l	#8,d1
	while	<tst.b d1>,ne
	rts

15:	.dc.w	$0B00+'0'
	.dc.w	$0200+'1'
	.dc.w	$0300+'2'
	.dc.w	$0400+'3'
	.dc.w	$0500+'4'
	.dc.w	$0600+'5'
	.dc.w	$0700+'6'
	.dc.w	$0800+'7'
	.dc.w	$0900+'8'
	.dc.w	$0A00+'9'

;�L�[���̓o�b�t�@�ɏ�������
;<d2.w:(�X�L�����R�[�h<<8)+�����R�[�h
;?a0
20:	di
	if	<cmpi.w #64,BIOS_KEY_REMAINING.w>,lo	;�L�[���̓o�b�t�@�Ɏc���Ă���f�[�^�̐���64�����̂Ƃ�
		movea.l	BIOS_KEY_WRITTEN.w,a0	;�Ō�ɏ������񂾈ʒu
		addq.l	#2,a0			;���񏑂����ވʒu
		if	<cmpa.w #BIOS_KEY_BUFFER+2*64.w,a0>,hs	;�����𒴂�����
			lea.l	BIOS_KEY_BUFFER.w,a0	;�擪�ɖ߂�
		endif
		move.w	d2,(a0)			;��������
		move.l	a0,BIOS_KEY_WRITTEN.w	;�Ō�ɏ������񂾈ʒu
		addq.w	#1,BIOS_KEY_REMAINING.w	;�L�[���̓o�b�t�@�Ɏc���Ă���f�[�^�̐�
	endif
	ei
	rts

;----------------------------------------------------------------
;ESC [nr �E��
;<d1.w:�h�b�g��
putc_csi_r:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	if	<cmp.w d0,d1>,ls	;�傫�����Ȃ�
		bset.b	#BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w	;�E��
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͊J�n
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [ns �J�[�\���̍��W�ƕ���������ۑ�����
;<d1.w:-1
putc_csi_s:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_CURSOR_ROW.w,BIOS_SAVED_ROW.w
		move.w	BIOS_CURSOR_COLUMN.w,BIOS_SAVED_COLUMN.w
		move.b	BIOS_CURSOR_FRACTION.w,BIOS_SAVED_FRACTION.w
		move.b	BIOS_ATTRIBUTE_1.w,BIOS_SAVED_ATTRIBUTE_1.w
		move.b	BIOS_ATTRIBUTE_2.w,BIOS_SAVED_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;ESC [nu �J�[�\���̍��W�ƕ��������𕜌�����
;<d1.w:-1
putc_csi_u:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_SAVED_ROW.w,BIOS_CURSOR_ROW.w
		move.w	BIOS_SAVED_COLUMN.w,BIOS_CURSOR_COLUMN.w
		move.b	BIOS_SAVED_FRACTION.w,BIOS_CURSOR_FRACTION.w
		move.b	BIOS_SAVED_ATTRIBUTE_1.w,BIOS_ATTRIBUTE_1.w
		move.b	BIOS_SAVED_ATTRIBUTE_2.w,BIOS_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
;<d1.w:�����R�[�h
putc_output:
	push	d0-d7/a0-a2
	lea.l	-4*16-4*16(sp),sp	;�t�H���g�f�[�^�ƃ}�X�N�f�[�^
;<(sp).l[16]:�t�H���g�f�[�^
;<4*16(sp).l[16]:�}�X�N�f�[�^
	move.w	d1,d7
;<d7.w:�����R�[�h
;----------------
;�t�H���g�A�h���X�ƃh�b�g�������߂�
	ifand	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne,<cmp.w #$0020,d1>,hs,<cmp.w #$0082,d1>,ls	;�v���|�[�V���i���ɂ���
		lea.l	proportional_font(pc),a0	;�v���|�[�V���i���t�H���g($20�`$82)
		sub.w	#$0020,d1
		mulu.w	#2+2*16,d1
		adda.l	d1,a0			;�t�H���g�A�h���X
		move.w	(a0)+,d6		;�h�b�g���B1�`16
		moveq.l	#1,d2			;16�h�b�g�f�[�^
	else				;�v���|�[�V���i���ɂ��Ȃ�
		moveq.l	#8,d2
		IOCS	_FNTADR
	;<d0.l:�t�H���g�A�h���X
	;<d1.w:�������̃h�b�g��<<16|�������̃o�C�g��-1
	;<d2.w:�c�����̃h�b�g��-1
		movea.l	d0,a0			;�t�H���g�A�h���X
		move.w	d1,d2			;0=8�h�b�g�f�[�^,1=16�h�b�g�f�[�^
		swap.w	d1
		move.w	d1,d6			;�h�b�g���B1�`16
	endif
;<d2.w:0=8�h�b�g�f�[�^,1=16�h�b�g�f�[�^
;<d6.w:�h�b�g���B1�`16
;<(a0).b[16]:8�h�b�g�f�[�^
;�܂���
;<(a0).w[16]:16�h�b�g�f�[�^
;----------------
;�o�b�t�@�ɏo�͂��邩
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;�o�b�t�@�o�͒�
		movea.l	BIOS_BUFFER_POINTER.w,a0	;�o�b�t�@�̏������݈ʒu
		goto	<cmpa.l #BIOS_BUFFER_ARRAY+2*64,a0>,hs,putc_output_end	;�o�b�t�@����t�̂Ƃ��͖�������
		move.w	d7,(a0)+		;�����R�[�h
		move.l	a0,BIOS_BUFFER_POINTER.w	;�������݈ʒu��i�߂�
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�v���|�[�V���i���̂Ƃ�
			if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�����̂Ƃ�
				addq.w	#1,d6			;����1�h�b�g������
			endif
			if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�Α̂̂Ƃ�
				addq.w	#3,d6			;����3�h�b�g������
				bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
				if	ne	;�A���̂Ƃ�
					subq.w	#3,BIOS_BUFFER_WIDTH.w	;3�h�b�g�l�߂�
					if	cs
						clr.w	BIOS_BUFFER_WIDTH.w	;�O�̈�
					endif
				endif
			else				;�Α̂ł͂Ȃ��Ƃ�
				bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			endif
		endif
		add.w	d6,BIOS_BUFFER_WIDTH.w	;����������
		goto	putc_output_end
	endif
;----------------
;�J�[�\��OFF
;	�Α̂̂Ƃ��ʒu�������̂ł��̑O�ɃJ�[�\��������
	bsr	iocs_1F_B_CUROFF
;----------------
;�t�H���g�f�[�^�����
	movea.l	sp,a1			;�t�H���g�f�[�^
	moveq.l	#0,d0
	if	<tst.w d2>,eq		;8�h�b�g�f�[�^�̂Ƃ�
		moveq.l	#16-1,d3
		for	d3
			move.b	(a0)+,(a1)+
			move.b	d0,(a1)+		;clr
			move.w	d0,(a1)+		;clr
		next
	else				;16�h�b�g�f�[�^�̂Ƃ�
		moveq.l	#16-1,d3
		for	d3
			move.w	(a0)+,(a1)+
			move.w	d0,(a1)+		;clr
		next
	endif
;<(sp).l[16]:�t�H���g�f�[�^
;----------------
;����
;	�S�̂��E��1�h�b�g���炵��OR����
;	�v���|�[�V���i���̂Ƃ��͕���1�h�b�g������
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
;>d6.w:�h�b�g���B1�`17
	if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�����̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�v���|�[�V���i���̂Ƃ�
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;�E��1�h�b�g���炵��
				or.l	d1,d0			;OR����
				move.l	d0,(a1)+
			next
			addq.w	#1,d6			;����1�h�b�g������
		else				;�v���|�[�V���i���ł͂Ȃ��Ƃ�
			moveq.l	#1,d2
			ror.l	d6,d2
			neg.l	d2
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;�E��1�h�b�g���炵��
				or.l	d1,d0			;OR����
				and.l	d2,d0			;���𑝂₳�Ȃ�
				move.l	d0,(a1)+
			next
		endif
	endif
;----------------
;�׎�
;	�㉺���E�̂����ꂩ��1�ŁA���b�V����1�̂Ƃ��A1��0�ɂ���
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�׎��̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		move.l	#$AAAAAAAA,d2
		moveq.l	#1,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
		rol.l	d0,d2
		moveq.l	#16-1,d3
		for	d3
			move.l	(a1),d0
			move.l	d0,d1
			lsr.l	#1,d1			;��
			lsl.l	#1,d0			;�E
			or.l	d1,d0
			if	<cmpa.l sp,a1>,ne
				or.l	-4(a1),d0	;��
			endif
			if	<tst.w d3>,ne
				or.l	4(a1),d0	;��
			endif
			and.l	d2,d0			;���b�V��
			not.l	d0
			and.l	d0,(a1)+
			rol.l	#1,d2
		next
	endif
;----------------
;����
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�����̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*15(a1)
	endif
;----------------
;��������
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w>,ne	;���������̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*8(a1)
	endif
;----------------
;�g��
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�g���̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d2
		ror.l	d6,d2
		neg.l	d2
		moveq.l	#3,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
  .if 0
		move.l	#$CCCCCCCC,d1
		rol.l	d0,d1
		move.l	d1,d0			;11001100
		not.l	d1			;00110011
		and.l	d2,d0
		and.l	d2,d1
		or.l	d0,4*14(a1)
		or.l	d1,4*15(a1)
  .else
		move.l	#$88888888,d1
		move.l	#$55555555,d3
		rol.l	d0,d1			;10001000
		rol.l	d0,d3			;01010101
		move.l	d1,d0
		rol.l	#2,d0			;00100010
		and.l	d2,d0
		and.l	d2,d1
		and.l	d2,d3
		or.l	d0,4*13(a1)
		or.l	d3,4*14(a1)
		or.l	d1,4*15(a1)
  .endif
	endif
;----------------
;�l�p�͂�
	if	<btst.b #BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�l�p�݂͂̂Ƃ�
	;16x16�̒����Ɋ񂹂�
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16��12x12�ɏk������
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16�̒����Ɋ񂹂�
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;�l�p��t����
		movea.l	sp,a0
		or.l	#$FFFF0000,(a0)+
		moveq.l	#14-1,d3
		for	d3
			or.l	#$80010000,(a0)+
		next
		or.l	#$FFFF0000,(a0)+
	endif
;----------------
;�ۈ͂�
	if	<btst.b #BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�ۈ݂͂̂Ƃ�
	;16x16�̒����Ɋ񂹂�
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16��12x12�ɏk������
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16�̒����Ɋ񂹂�
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;�ۂ�t����
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tandi.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print($t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tori.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print(7**2<=$t&&$t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		ori.l	#%0000011111100000_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0000011111100000_0000000000000000,(a0)+
	endif
;----------------
;���
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;����̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*0(a1)
	endif
;----------------
;���t��
;	4x4�̏�2�h�b�g�ƍ�2�h�b�g�����ꂼ��OR��1�h�b�g�ɂ��邱�ƂŁA4x4��3x3�ɏk������
;	SX-Window�Ɠ������@
;	�c16�h�b�g��12�h�b�g�ɏk�����A������1�h�b�g�̍����ɔz�u����
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
;>d6.w:�h�b�g���B1�`12
	if	<btst.b #BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;���t���̂Ƃ�
		lea.l	subscript_pattern(pc),a2
		lea.l	4*16(sp),a0
		lea.l	4*15(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			subq.l	#8,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
		clr.l	4*2(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;��t��
;	4x4�̏�2�h�b�g�ƍ�2�h�b�g�����ꂼ��OR��1�h�b�g�ɂ��邱�ƂŁA4x4��3x3�ɏk������
;	SX-Window�Ɠ������@
;	�c16�h�b�g��12�h�b�g�ɏk�����A�ォ��0�h�b�g�̍����ɔz�u����
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
;>d6.w:�h�b�g���B1�`12
	if	<btst.b #BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;��t���̂Ƃ�
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;���]
;	�S�̂𔽓]������
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;���]�̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		moveq.l	#16-1,d3
		for	d3
			eor.l	d0,(a1)+
		next
	endif
;----------------
;�}�X�N�f�[�^�����
;<d6.w:�h�b�g���B1�`17
;>4*16(sp).l[16]:�}�X�N�f�[�^
	lea.l	4*16(sp),a1		;�}�X�N�f�[�^
	moveq.l	#1,d0
	ror.l	d6,d0
	neg.l	d0
	moveq.l	#16-1,d3
	for	d3
		move.l	d0,(a1)+
	next
;----------------
;�Α�
;	�S�̂��E��0�`3�h�b�g���炷
;	�v���|�[�V���i���̂Ƃ�����3�h�b�g������
;	�Α̂𑱂��ĕ`�悷��Ƃ��J�[�\���������Ȃ�������3�h�b�g�l�߂�
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
;<4*16(sp).l[16]:�}�X�N�f�[�^
;>d6.w:�h�b�g���B1�`20
	if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�Α̂̂Ƃ�
		movea.l	sp,a0			;�t�H���g�f�[�^
		lea.l	4*16(sp),a1		;�}�X�N�f�[�^
*		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�v���|�[�V���i���̂Ƃ�
			moveq.l	#3,d3
			do
				moveq.l	#4-1,d2
				for	d2
					move.l	(a0),d0
					lsr.l	d3,d0
					move.l	d0,(a0)+
					move.l	(a1),d0
					lsr.l	d3,d0
					move.l	d0,(a1)+
				next
				subq.w	#1,d3
			while	ne
			addq.w	#3,d6			;����3�h�b�g������
			bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			if	ne			;�A���̂Ƃ�
				subq.b	#3,BIOS_CURSOR_FRACTION.w	;3�h�b�g�l�߂�
				if	cs
					addq.b	#8,BIOS_CURSOR_FRACTION.w
					subq.w	#1,BIOS_CURSOR_COLUMN.w
					if	cs
						clr.w	BIOS_CURSOR_COLUMN.w	;�O�̈�
						clr.b	BIOS_CURSOR_FRACTION.w
					endif
				endif
			endif
*		else				;�v���|�[�V���i���ł͂Ȃ��Ƃ�
*			moveq.l	#1,d4
*			ror.l	d6,d4
*			neg.l	d4
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a1)+
*			next
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a1)+
*			next
*			lea.l	4*4(a0),a0
*			lea.l	4*4(a1),a1
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsl.l	#1,d0
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsl.l	#1,d0
*				move.l	d0,(a1)+
*			next
*		endif
	else				;�Α̂ł͂Ȃ��Ƃ�
		bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
	endif
;----------------
;���݂̍s�ɓ���؂�Ȃ���Ή��s����
;<d6.w:�h�b�g��
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	move.w	BIOS_CURSOR_COLUMN.w,d1
	lsl.w	#3,d1
	add.b	BIOS_CURSOR_FRACTION.w,d1	;�J�[�\����X�h�b�g���W
	sub.w	d1,d0			;�R���\�[���̃h�b�g��-�J�[�\����X�h�b�g���W=�c��h�b�g��
	if	le			;�c��h�b�g��<=0�B���ɂ͂ݏo���Ă���
	;���s����
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	elif	<cmp.w d6,d0>,lt	;�c��h�b�g��<�h�b�g���B����؂�Ȃ�
	;�c����󔒂Ŗ��߂�
		move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
		moveq.l	#7,d4
		and.b	BIOS_CURSOR_FRACTION.w,d4	;���[�̌����W�̒[��
		moveq.l	#7,d5			;�E�[�̌����W�̒[��
		bsr	putc_clear		;��������
		;���s����
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;----------------
;������`��
;<d6.w:�h�b�g��
;<(sp).l[16]:�t�H���g�f�[�^
;<4*16(sp).l[16]:�}�X�N�f�[�^
	move.w	BIOS_CURSOR_ROW.w,d0	;�s���W
	move.w	BIOS_CURSOR_COLUMN.w,d1	;�����W
	moveq.l	#7,d2
	and.b	BIOS_CURSOR_FRACTION.w,d2	;�����W�̒[��
	move.w	d6,d3			;�h�b�g��
	moveq.l	#3,d4
	and.b	BIOS_ATTRIBUTE_1.w,d4	;�v���[��
	movea.l	sp,a0			;�t�H���g�f�[�^
	lea.l	4*16(sp),a1		;�}�X�N�f�[�^
	bsr	putc_draw		;������`��
;----------------
;�J�[�\����i�߂�
;<d6.w:�h�b�g��
	add.b	BIOS_CURSOR_FRACTION.w,d6	;�J�[�\���̌����W�̒[��+�h�b�g��
	moveq.l	#7,d0
	and.w	d6,d0
	move.b	d0,BIOS_CURSOR_FRACTION.w	;�J�[�\���̌����W�̒[��
	lsr.w	#3,d6
	add.w	d6,BIOS_CURSOR_COLUMN.w	;�J�[�\���̌����W�B���傤�ǉE�[�ɂȂ�ꍇ�����邪�����ł͉��s���Ȃ�
;----------------
;�J�[�\��ON
	bsr	iocs_1E_B_CURON
;----------------
putc_output_end:
	lea.l	4*16+4*16(sp),sp	;�t�H���g�f�[�^�ƃ}�X�N�f�[�^
	pop
	rts

;----------------------------------------------------------------
;���t���Ŏg���p�^�[��
;	����������������
subscript_pattern:
  .irp ff,%00000000,%10000000,%10000000,%10000000
    .irp ee,%00000000,%01000000
      .irp dd,%00000000,%00100000
        .irp cc,%00000000,%00010000,%00010000,%00010000
          .irp bb,%00000000,%00001000
            .irp aa,%00000000,%00000100
	.dc.b	ff+ee+dd+cc+bb+aa
            .endm
          .endm
        .endm
      .endm
    .endm
  .endm

;----------------------------------------------------------------
;������`��
;<d0.l:�s���W
;<d1.l:�����W
;<d2.l:�����W�̒[��
;<d3.l:�h�b�g��
;<d4.l:�v���[���B��������1�̉���2�r�b�g
;<(a0).l[16]:�t�H���g�f�[�^�B���񂹁B���o�[�X���܂߂ĉ��H�ς�
;<(a1).l[16]:�}�X�N�f�[�^�B���񂹁B�������ރr�b�g��1
putc_draw:
	push	d0-d5/a0-a4
;----------------
;�A�h���X�����߂�
	swap.w	d0
	clr.w	d0			;65536*�s���W
	lsr.l	#5,d0			;128*16*�s���W
	add.w	d1,d0			;128*16*�s���W+�����W
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;�`���n�߂�A�h���X�̃I�t�Z�b�g
	add.l	#$00E00000,d0		;�`���n�߂�A�h���X
	bclr.l	#0,d0			;�����ɂ���
	if	ne
		addq.w	#8,d2
	endif
;<d2.w:�����W�̒[���B0�`15
	movea.l	d0,a4
;<a4.l:�`���n�߂�A�h���X�B����
;?d0-d1
;----------------
	add.w	d2,d3			;�����W�̒[��+�h�b�g��
;<d3.w:�����W�̒[��+�h�b�g��
;----------------
;1���[�h�Ɏ��܂邩�A2���[�h�Ɍׂ邩�A3���[�h�Ɍׂ邩
	if	<cmp.w #16,d3>,ls
	;----------------
	;1���[�h�Ɏ��܂�Ƃ�
		do				;�v���[���̃��[�v
			lsr.b	#1,d4
			if	cs			;�v���[���ɕ`�悷��Ƃ�
				movea.l	a0,a2			;�t�H���g�f�[�^
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.w	(a2)+,d0		;�t�H���g
					move.w	(a3)+,d1		;�}�X�N
					lsr.w	d2,d0
					lsr.w	d2,d1
					not.w	d1
					and.w	(a4),d1			;���蔲����
					or.w	d1,d0			;���킹��
					move.w	d0,(a4)+		;��������
					addq.l	#4-2,a2
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;���̃��X�^
				next
			else				;�v���[������������Ƃ�
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.w	(a3)+,d1		;�}�X�N
					lsr.w	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;���蔲��
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;���̃��X�^
				next
			endif
			adda.l	#-128*16+128*1024,a4	;���̃v���[��
		while	<cmpa.l #$00E40000,a4>,lo
	elif	<cmp.w #32,d3>,ls
	;----------------
	;2���[�h�Ɍׂ�Ƃ�
		do				;�v���[���̃��[�v
			lsr.b	#1,d4
			if	cs			;�v���[���ɕ`�悷��Ƃ�
				movea.l	a0,a2			;�t�H���g�f�[�^
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a2)+,d0		;�t�H���g
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;���蔲����
					or.l	d1,d0			;���킹��
					move.l	d0,(a4)+		;��������
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;���̃��X�^
				next
			else				;�v���[������������Ƃ�
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;���蔲��
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;���̃��X�^
				next
			endif
			adda.l	#-128*16+128*1024,a4	;���̃v���[��
		while	<cmpa.l #$00E40000,a4>,lo
	else
	;----------------
	;3���[�h�Ɍׂ�Ƃ�
		do				;�v���[���̃��[�v
			lsr.b	#1,d4
			if	cs			;�v���[���ɕ`�悷��Ƃ�
				movea.l	a0,a2			;�t�H���g�f�[�^
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a2)+,d0		;�t�H���g
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;���蔲����
					or.l	d1,d0			;���킹��
					move.l	d0,(a4)+		;��������
					move.w	-2(a2),d0		;�t�H���g
					move.w	-2(a3),d1		;�}�X�N
					swap.w	d0
					swap.w	d1
					clr.w	d0
					clr.w	d1
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.w	d1
					and.w	(a4),d1			;���蔲����
					or.w	d1,d0			;���킹��
					move.w	d0,(a4)+		;��������
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;���̃��X�^
				next
			else				;�v���[������������Ƃ�
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;���蔲��
					move.w	-2(a3),d1		;�}�X�N
					swap.w	d1
					clr.w	d1
					lsr.l	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;���蔲��
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;���̃��X�^
				next
			endif
			adda.l	#-128*16+128*1024,a4	;���̃v���[��
		while	<cmpa.l #$00E40000,a4>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;�s���R�s�[����
;	  ��������������  ��������������
;	  ��          ������������������
;	  ������������������    ��    ��d2
;	d0��    ��    ��  ��    ��    ��
;	  ��    ��    ��  ��    ��    ��
;	d1��    ��    ������������������
;	  ������������������          ��
;	  ��������������  ��������������
;	  ��������������  ��������������
;	  ������������������          ��
;	d0��    ��    ������������������
;	  ��    ��    ��  ��    ��    ��d2
;	d1��    ��    ��  ��    ��    ��
;	  ������������������    ��    ��
;	  ��          ������������������
;	  ��������������  ��������������
;<d0.w:�R�s�[���̏�[�̍s���W
;<d1.w:�R�s�[���̉��[�̍s���W
;<d2.w:�R�s�[��̏�[�̍s���W
putc_copy_rows:
	push	d0-d3/a0
	move.l	BIOS_CONSOLE_OFFSET.w,d3	;�R���\�[���̍���̃A�h���X�̃I�t�Z�b�g
	lsr.l	#7,d3			;�R���\�[���̏�[��Y�h�b�g���W
	lsr.w	#2,d3			;�R���\�[���̏�[�̃��X�^�u���b�N�ԍ�
	sub.w	d0,d1			;�R�s�[���̉��[�̍s���W-�R�s�[���̏�[�̍s���W=�R�s�[����s��-1
	lsl.w	#2,d1			;�R�s�[���郉�X�^�u���b�N��-4
	addq.w	#3,d1			;�R�s�[���郉�X�^�u���b�N��-1
;<d1.w:�R�s�[���郉�X�^�u���b�N��-1
	lsl.w	#2,d0
	add.w	d3,d0			;�R�s�[���̏�[�̃��X�^�u���b�N�ԍ�
;<d0.w:�R�s�[���̏�[�̃��X�^�u���b�N�ԍ�
	lsl.w	#2,d2
	add.w	d3,d2			;�R�s�[��̏�[�̃��X�^�u���b�N�ԍ�
;<d2.w:�R�s�[��̏�[�̃��X�^�u���b�N�ԍ�
	if	<cmp.w d0,d2>,ls	;��ɂ��炷�Ƃ�
		move.w	#$0101,d3		;���X�^�u���b�N�ԍ��̑���
	else				;���ɂ��炷�Ƃ�
		add.w	d1,d0			;�R�s�[���̉��[�̃��X�^�u���b�N�ԍ�
		add.w	d1,d2			;�R�s�[��̉��[�̃��X�^�u���b�N�ԍ�
		move.w	#$FEFF,d3		;���X�^�u���b�N�ԍ��̑���
	endif
;<d0.w:�R�s�[���̃��X�^�u���b�N�ԍ�
;<d2.w:�R�s�[��̃��X�^�u���b�N�ԍ�
;<d3.w:���X�^�u���b�N�ԍ��̑���
	lsl.w	#8,d0			;�R�s�[���̃��X�^�u���b�N�ԍ�<<8
	move.b	d2,d0			;�R�s�[���̃��X�^�u���b�N�ԍ�<<8|�R�s�[��̃��X�^�u���b�N�ԍ�
;<d0.w:�R�s�[���̃��X�^�u���b�N�ԍ�<<8|�R�s�[��̃��X�^�u���b�N�ԍ�
aGPDR	reg	a0
	lea.l	MFP_GPDR,aGPDR		;GPIP�f�[�^���W�X�^�BHSYNC|RINT|-|VDISP|OPMIRQ|POWER|EXPWON|ALARM
	move.w	sr,d2
	for	d1			;���X�^�u���b�N�̃��[�v
		do
		while	<tst.b (aGPDR)>,mi	;�����\�����Ԃ�҂�
		ori.w	#$0700,sr		;���荞�݂��֎~����
		do
		while	<tst.b (aGPDR)>,pl	;�����A�����Ԃ�҂�
		move.w	d0,CRTC_BLOCK-MFP_GPDR(aGPDR)	;���X�^�u���b�N�ԍ���ݒ肷��
		move.w	#$0008,CRTC_ACTION-MFP_GPDR(aGPDR)	;���X�^�R�s�[��ON�ɂ���B2��ڈȍ~�͕s�v
		move.w	d2,sr			;���荞�݂�������
		add.w	d3,d0			;���̃��X�^�u���b�N��
	next
	do
	while	<tst.b (aGPDR)>,mi	;�����\�����Ԃ�҂�
	ori.w	#$0700,sr		;���荞�݂��֎~����
	do
	while	<tst.b (aGPDR)>,pl	;�����A�����Ԃ�҂�
	move.w	d2,sr			;���荞�݂�������
	clr.w	CRTC_ACTION-MFP_GPDR(aGPDR)	;���X�^�R�s�[��OFF�ɂ���B�K�v
	pop
	rts

;----------------------------------------------------------------
;�s����������
;<d0.w:��[�̍s���W
;<d1.w:���[�̍s���W
putc_clear_rows:
	push	d2-d5
	moveq.l	#0,d2			;���[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;��������
;	�����͋󔒂̕`��Ɠ����B�w�i�F�œh��ׂ�
;		��������		�����F	�w�i�F
;		0			��	��
;		1			���F	��
;		2			���F	��
;		3			��	��
;		4		����	��	��
;		5		����	���F	��
;		6		����	���F	��
;		7		����	��	��
;		8	���]		��	��
;		9	���]		��	���F
;		10	���]		��	���F
;		11	���]		��	��
;		12	���]	����	��	��
;		13	���]	����	��	���F
;		14	���]	����	��	���F
;		15	���]	����	��	��
;<d0.w:��[�̍s���W
;<d1.w:���[�̍s���W
;<d2.w:���[�̌����W
;<d3.w:�E�[�̌����W
;<d4.w:���[�̌����W�̒[���B0�`7�B������܂�
;<d5.w:�E�[�̌����W�̒[���B0�`7�B������܂�
putc_clear:
	push	d0-d7/a0-a3
;----------------
;���X�^�������߂�
	sub.w	d0,d1			;���[�̍s���W-��[�̍s���W=�s��-1
	addq.w	#1,d1			;�s��
	lsl.w	#4,d1			;16*�s��=���X�^��
	subq.w	#1,d1			;���X�^��-1
	movea.w	d1,a3
;<a3.w:���X�^��-1
;?d1
;----------------
;�A�h���X�����߂�
	swap.w	d0
	clr.w	d0			;65536*�s���W
	lsr.l	#5,d0			;128*16*�s���W
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;��[�̍s�̍���̃A�h���X�̃I�t�Z�b�g
	add.l	#$00E00000,d0		;��[�̍s�̍���̃A�h���X
	ext.l	d2
	ext.l	d3
	add.l	d0,d2			;����̃A�h���X
	add.l	d0,d3			;�E��̃A�h���X
;<d2.l:����̃A�h���X
;<d3.l:�E��̃A�h���X
;?d0
;----------------
;�A�h���X�������ɂ���
;	�����W�ł͂Ȃ��A�h���X�������ɂ���
;	_B_CONSOL�̓R���\�[���̍��[�̃A�h���X�������ɐ������Ă��Ȃ�
	bclr.l	#0,d2
	if	ne
		addq.w	#8,d4
	endif
;<d2.l:����̃A�h���X�B����
;<d4.w:���[�̌����W�̒[���B0�`15
	bclr.l	#0,d3
	if	ne
		addq.w	#8,d5
	endif
;<d3.l:�E��̃A�h���X�B����
;<d5.w:�E�[�̌����W�̒[���B0�`15
	movea.l	d2,a2
;<a2.l:����̃A�h���X�B����
;----------------
;���[�h�������߂�
	sub.w	d2,d3			;�E�[�̃A�h���X-���[�̃A�h���X=2*(���[�h��-1)
	lsr.w	#1,d3			;���[�h��-1
;<d3.w:���[�h��-1
;?d2
;----------------
;�}�X�N�����
	moveq.l	#-1,d6
	move.w	#$8000,d7
	lsr.w	d4,d6			;���[�̏������ޕ�����1�̃}�X�N�B$FFFF,$7FFF,�c,$0003,$0001
	asr.w	d5,d7			;�E�[�̏������ޕ�����1�̃}�X�N�B$8000,$C000,�c,$FFFE,$FFFF
;<d6.w:���[�̏������ޕ�����1�̃}�X�N�B$FFFF,$7FFF,�c,$0003,$0001
;<d7.w:�E�[�̏������ޕ�����1�̃}�X�N�B$8000,$C000,�c,$FFFE,$FFFF
;?d4-d5
;----------------
;�f�[�^�����
	moveq.l	#%1111,d0
	and.b	BIOS_ATTRIBUTE_1.w,d0	;�v���[��##
;		  111111
;		  5432109876543210
	move.w	#%1100110000000000,d2	;�w�i�F�����F�܂��͔��B�v���[��1��h��ׂ�
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
	swap.w	d2
;		  111111
;		  5432109876543210
	move.w	#%1010101000000000,d2	;�w�i�F�����F�܂��͔��B�v���[��0��h��ׂ�
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
;<d2.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
;----------------
;1���[�h��1���[�h�ł͂Ȃ���
	if	<tst.w d3>,eq
	;----------------
	;1���[�h�̂Ƃ�
		and.w	d7,d6
	;<d6.w:�������ޕ�����1�̃}�X�N
		and.w	d6,d2
		swap.w	d2
		and.w	d6,d2
		swap.w	d2
	;<d2.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
		not.w	d6
	;<d6.w:�������܂Ȃ�������1�̃}�X�N
		do				;�v���[���̃��[�v
			movea.l	a2,a0			;����̃A�h���X�����[�̃A�h���X
			move.w	a3,d1			;���X�^��-1
			for	d1			;���X�^�̃��[�v
				move.w	(a0),d0
				and.w	d6,d0			;�}�X�N
				or.w	d2,d0			;�f�[�^
				move.w	d0,(a0)
				lea.l	128(a0),a0		;���̍��[�̃A�h���X
			next
			swap.w	d2			;���̃v���[���̃f�[�^
			adda.l	#128*1024,a2		;���̃v���[���̍���̃A�h���X
		while	<cmpa.l #$00E40000,a2>,lo
	else
	;----------------
	;1���[�h�ł͂Ȃ��Ƃ�
		subq.w	#1,d3
	;<d3.w:���[�ƉE�[�̊Ԃ̃��[�h���B0�`
		move.l	d2,d4
		move.l	d2,d5
	;<d4.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
	;<d5.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
	;<d4.l:�v���[��1�̍��[�̃f�[�^<<16|�v���[��0�̍��[�̃f�[�^
	;<d5.l:�v���[��1�̉E�[�̃f�[�^<<16|�v���[��0�̉E�[�̃f�[�^
		not.w	d6
		not.w	d7
	;<d6.w:���[�̏������܂Ȃ�������1�̃}�X�N�B$0000,$8000,�c,$FFFC,$FFFE
	;<d7.w:�E�[�̏������܂Ȃ�������1�̃}�X�N�B$7FFF,$3FFF,�c,$0001,$0000
		do				;�v���[���̃��[�v
			movea.l	a2,a1			;����̃A�h���X�����[�̃A�h���X
			move.w	a3,d1			;���X�^��-1
			for	d1			;���X�^�̃��[�v
				movea.l	a1,a0			;���[�̃A�h���X�����̃A�h���X
			;���[
				move.w	(a0),d0
				and.w	d6,d0			;���[�̃}�X�N
				or.w	d4,d0			;���[�̃f�[�^
				move.w	d0,(a0)+
			;���[�ƉE�[�̊�
				move.w	d3,d0			;���[�ƉE�[�̊Ԃ̃��[�h���B0�`
				forcontinue	d0
					move.w	d2,(a0)+		;�f�[�^
				next
			;�E�[
				move.w	(a0),d0
				and.w	d7,d0			;�E�[�̃}�X�N
				or.w	d5,d0			;�E�[�̃f�[�^
				move.w	d0,(a0)+
				lea.l	128(a1),a1		;���̍��[�̃A�h���X
			next
			swap.w	d2			;���̃v���[���̃f�[�^
			swap.w	d4			;���̃v���[���̍��[�̃f�[�^
			swap.w	d5			;���̃v���[���̉E�[�̃f�[�^
			adda.l	#128*1024,a2		;���̃v���[���̍���̃A�h���X
		while	<cmpa.l #$00E40000,a2>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;�v���|�[�V���i���t�H���g($20�`$82)
proportional_font:
	.dc.w	6	;$20   
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$21 �I
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$22 �h
	.dc.w	%0000000000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0010001000000000
	.dc.w	%0010001000000000
	.dc.w	%0100010000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$23 ��
	.dc.w	%0000000000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0111111100000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%1111111000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$24 ��
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%1001001000000000
	.dc.w	%1101000000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%0001011000000000
	.dc.w	%1001001000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$25 ��
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001000010000000
	.dc.w	%1001000100000000
	.dc.w	%1001001000000000
	.dc.w	%0110010000000000
	.dc.w	%0000100000000000
	.dc.w	%0001001100000000
	.dc.w	%0010010010000000
	.dc.w	%0100010010000000
	.dc.w	%1000010010000000
	.dc.w	%0000001100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$26 ��
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%0101000000000000
	.dc.w	%0011000000000000
	.dc.w	%0100100100000000
	.dc.w	%1000010100000000
	.dc.w	%1000001000000000
	.dc.w	%1000010100000000
	.dc.w	%0111100010000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$27 �f
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$28 �i
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$29 �j
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2A ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%1001001000000000
	.dc.w	%0101010000000000
	.dc.w	%0011100000000000
	.dc.w	%0101010000000000
	.dc.w	%1001001000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2B �{
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%1111111000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$2C �C
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2D �|
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2E �D
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2F �^
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$30 �O
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$31 �P
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001100000000000
	.dc.w	%0011100000000000
	.dc.w	%0111100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$32 �Q
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100000000000000
	.dc.w	%1111111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$33 �R
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0001110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$34 �S
	.dc.w	%0000000000000000
	.dc.w	%0000001000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111000000000
	.dc.w	%0001111000000000
	.dc.w	%0011011000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1111111100000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$35 �T
	.dc.w	%0000000000000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$36 �U
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%1110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$37 �V
	.dc.w	%0000000000000000
	.dc.w	%1111111100000000
	.dc.w	%1100001100000000
	.dc.w	%1100011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$38 �W
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$39 �X
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011111000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3A �F
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3B �G
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3C ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3D ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3E ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3F �H
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$40 ��
	.dc.w	%0000000000000000
	.dc.w	%0001111100000000
	.dc.w	%0010000010000000
	.dc.w	%0100000001000000
	.dc.w	%1000111001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001110110000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0011111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$41 �`
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0010001100000000
	.dc.w	%0010001100000000
	.dc.w	%0011111100000000
	.dc.w	%0100000110000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$42 �a
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$43 �b
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$44 �c
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$45 �d
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$46 �e
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$47 �f
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100001111000000
	.dc.w	%1100000010000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$48 �g
	.dc.w	%0000000000000000
	.dc.w	%1111001111000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%1111001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$49 �h
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$4A �i
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%1100110000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4B �j
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111110000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4C �k
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	13	;$4D �l
	.dc.w	%0000000000000000
	.dc.w	%1110000001110000
	.dc.w	%0110000001100000
	.dc.w	%0111000001100000
	.dc.w	%0111000011100000
	.dc.w	%0111100011100000
	.dc.w	%0101100101100000
	.dc.w	%0101110101100000
	.dc.w	%0100111001100000
	.dc.w	%0100111001100000
	.dc.w	%0100010001100000
	.dc.w	%1110010011110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	12	;$4E �m
	.dc.w	%0000000000000000
	.dc.w	%1100000011100000
	.dc.w	%0110000001000000
	.dc.w	%0111000001000000
	.dc.w	%0111100001000000
	.dc.w	%0101110001000000
	.dc.w	%0100111001000000
	.dc.w	%0100011101000000
	.dc.w	%0100001111000000
	.dc.w	%0100000111000000
	.dc.w	%0100000011000000
	.dc.w	%1110000001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$4F �n
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%0110000110000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$50 �o
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$51 �p
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1101110011000000
	.dc.w	%1111011110000000
	.dc.w	%0110001100000000
	.dc.w	%0001111100000000
	.dc.w	%0000000110000000
	.dc.w	%0000000011000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$52 �q
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110111000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001110000000
	.dc.w	%1111000111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$53 �r
	.dc.w	%0000000000000000
	.dc.w	%0001110100000000
	.dc.w	%0110001100000000
	.dc.w	%1100000100000000
	.dc.w	%1110000000000000
	.dc.w	%0111000000000000
	.dc.w	%0011110000000000
	.dc.w	%0000111000000000
	.dc.w	%0000011100000000
	.dc.w	%1000001100000000
	.dc.w	%1100011000000000
	.dc.w	%1011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$54 �s
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100110011000000
	.dc.w	%1000110001000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0011111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$55 �t
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0000111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$56 �u
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	16	;$57 �v
	.dc.w	%0000000000000000
	.dc.w	%1111000110001110
	.dc.w	%0110000110000100
	.dc.w	%0011000111000100
	.dc.w	%0011000111000100
	.dc.w	%0011001011001000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$58 �w
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000111000000000
	.dc.w	%0001001100000000
	.dc.w	%0010001100000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$59 �x
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$5A �y
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100000011000000
	.dc.w	%1000000110000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000001000000
	.dc.w	%1100000011000000
	.dc.w	%1111111111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5B �m
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5C ��
	.dc.w	%0000000000000000
	.dc.w	%1000001000000000
	.dc.w	%1000001000000000
	.dc.w	%0100010000000000
	.dc.w	%0100010000000000
	.dc.w	%0010100000000000
	.dc.w	%0010100000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5D �n
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5E �O
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010100000000000
	.dc.w	%0100010000000000
	.dc.w	%1000001000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5F �Q
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$60 �M
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$61 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110000000000
	.dc.w	%1100111000000000
	.dc.w	%0000011000000000
	.dc.w	%0011111000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100111000000000
	.dc.w	%0111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$62 ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111001100000000
	.dc.w	%1101111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$63 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$64 ��
	.dc.w	%0000000000000000
	.dc.w	%0000011100000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%0011101100000000
	.dc.w	%0110011100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011101110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$65 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$66 ��
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$67 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110100000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%0111110000000000
	.dc.w	%1100000000000000
	.dc.w	%0111111000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$68 ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$69 ��
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$6A ��
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%1101100000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6B ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111000000000000
	.dc.w	%0111100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110011000000000
	.dc.w	%1111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$6C ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	15	;$6D ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1101111011110000
	.dc.w	%0111011110111000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%1111011110111100
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$6E ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6F ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$70 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0111011100000000
	.dc.w	%0110111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$71 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111011100000000
	.dc.w	%1110111000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111100000000
	.dc.w	%0000000000000000
	.dc.w	9	;$72 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$73 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111101000000000
	.dc.w	%1100011000000000
	.dc.w	%1100001000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%1000011000000000
	.dc.w	%1100011000000000
	.dc.w	%1011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$74 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110110000000000
	.dc.w	%0011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$75 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011110110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$76 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0011010000000000
	.dc.w	%0011100000000000
	.dc.w	%0011100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	14	;$77 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001000111000
	.dc.w	%0110001100010000
	.dc.w	%0110001100010000
	.dc.w	%0011010110100000
	.dc.w	%0011010110100000
	.dc.w	%0001110011100000
	.dc.w	%0001100011000000
	.dc.w	%0000100001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$78 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0011010000000000
	.dc.w	%0001100000000000
	.dc.w	%0001110000000000
	.dc.w	%0010011000000000
	.dc.w	%0100001100000000
	.dc.w	%1110011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$79 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110000100000000
	.dc.w	%0011001000000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0001110000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7A ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%1000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7B �o
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7C �b
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7D �p
	.dc.w	%0000000000000000
	.dc.w	%1100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%1100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7E �P
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7F DL
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$80 �_
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$81 �`
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001001000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$82 �U
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000



;----------------------------------------------------------------
;�f�o�C�X�h���C�o�̖���
device_tail:

;----------------------------------------------------------------
;�f�o�C�X�R�}���h0 ������
initialize:

;�p�����[�^���m�F����
	movea.l	18(a5),a0		;�p�����[�^�B��؂��0�A������0,0�B�擪�̓f�o�C�X�t�@�C����
	do
	while	<tst.b (a0)+>,ne	;�f�o�C�X�t�@�C������ǂݔ�΂�
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,parameter_error	;-,/�ȊO
		move.b	(a0)+,d0
		goto	eq,parameter_error	;-,/�̌�ɕ������Ȃ�
		st.b	option_flag		;�I�v�V��������
		bsr	tolower
		if	<cmp.b #'f',d0>,eq	;-f
			st.b	fixed_flag
			sf.b	proportional_flag
		elif	<cmp.b #'p',d0>,eq	;-p
			sf.b	fixed_flag
			st.b	proportional_flag
		elif	<cmp.b #'q',d0>,eq	;-q
			st.b	quiet_flag
			sf.b	verbose_flag
		elif	<cmp.b #'s',d0>,eq	;-s
			st.b	sample_flag
		elif	<cmp.b #'v',d0>,eq	;-v
			sf.b	quiet_flag
			st.b	verbose_flag
		else
			goto	parameter_error
		endif
		tst.b	(a0)+			;��؂�
		goto	ne,parameter_error	;�]���ȕ���������
	start
		move.b	(a0)+,d0
	while	ne

;���[�N�G���A������������
	bsr	initialize_workarea	;���[�N�G���A������������

;�x�N�^��ύX����
	IOCS	_OS_CUROF
	lea.l	vector_table(pc),a0	;�x�N�^�e�[�u��
	bsr	set_vector		;�x�N�^��ύX����
	IOCS	_OS_CURON

;�Œ�s�b�`�܂��̓v���|�[�V���i���s�b�`��ݒ肷��
	if	<tst.b fixed_flag>,ne	;�Œ�s�b�`
		bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
	elif	<tst.b proportional_flag>,ne	;�v���|�[�V���i���s�b�`
		bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
	endif

;���s�ƃ^�C�g����\������
	if	<tst.b quiet_flag>,eq
		lea.l	crlf_title(pc),a0
		bsr	print
	endif

;�T���v����\������
	if	<tst.b sample_flag>,ne
		lea.l	sample(pc),a0
		bsr	print
	endif

;�f�o�C�X�h���C�o�̖�����ݒ肷��
	move.l	#device_tail,14(a5)	;�f�o�C�X�h���C�o�̖���

;�f�o�C�X�h���C�o��g�ݍ���
	moveq.l	#0,d0
	rts

;�p�����[�^�G���[
parameter_error:

;���s�ƃ^�C�g���ƃG���[���b�Z�[�W��\������
	lea.l	crlf_title(pc),a0
	bsr	print
	lea.l	parameter_message(pc),a0
	bsr	print

;�f�o�C�X�h���C�o��g�ݍ��܂Ȃ�
	move.w	#ABORT|MISCELLANEOUS_ERROR,d0	;���~(A) �G���[���������܂���
	rts

;----------------------------------------------------------------
;���s�J�n
execution_start:

;�I�v�V�������m�F����
	lea.l	1(a2),a0		;�R�}���h���C��
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;-,/�ȊO
		addq.l	#1,a0
		move.b	(a0)+,d0
		goto	eq,usage_exit		;-,/�̌�ɕ������Ȃ�
		st.b	option_flag		;�I�v�V��������
		bsr	tolower
		if	<cmp.b #'f',d0>,eq	;-f
			st.b	fixed_flag
			sf.b	proportional_flag
		elif	<cmp.b #'k',d0>,eq	;-k
			st.b	keeppr_flag
			sf.b	release_flag
		elif	<cmp.b #'p',d0>,eq	;-p
			sf.b	fixed_flag
			st.b	proportional_flag
		elif	<cmp.b #'q',d0>,eq	;-q
			st.b	quiet_flag
			sf.b	verbose_flag
		elif	<cmp.b #'r',d0>,eq	;-r
			sf.b	keeppr_flag
			st.b	release_flag
		elif	<cmp.b #'s',d0>,eq	;-s
			st.b	sample_flag
		elif	<cmp.b #'v',d0>,eq	;-v
			sf.b	quiet_flag
			st.b	verbose_flag
		else
			goto	usage_exit
		endif
		move.b	(a0),d0
		break	eq
		bsr	isspace
		goto	ne,usage_exit		;�]���ȕ���������
	start
		bsr	nonspace
	while	ne
	goto	<tst.b option_flag>,eq,usage_exit	;�I�v�V�����Ȃ�

;�X�[�p�[�o�C�U���[�h�ֈڍs����
	supervisormode

;----------------------------------------------------------------
;�f�o�C�X�h���C�o��T��
	movea.l	DOS_HUMAN_MEMORY.w,a2	;Human68k�̐擪
	do
		addq.l	#2,a2
	whileor	<cmpi.l #'NUL ',DH_NAME(a2)>,ne,<cmpi.l #'    ',DH_NAME+4(a2)>,ne,<cmpi.w #$8024,DH_TYPE(a2)>,ne	;NUL�f�o�C�X�h���C�o��T���B�K������
;<a2.l:NUL�f�o�C�X�h���C�o�̐擪
	dostart
		lea.l	magic-program_head(a2),a0	;�풓�����̃}�W�b�N
		lea.l	magic(pc),a1		;�����̃}�W�b�N
		gotoand	<cmpm.l (a0)+,(a1)+>,eq,<cmpm.l (a0)+,(a1)+>,eq,device_found	;��v������I��
	start
		movea.l	a2,a3			;�f�o�C�X�h���C�o�����O�̃f�o�C�X�h���C�o
		movea.l	DH_NEXT(a2),a2		;���̃f�o�C�X�h���C�o
	while	<cmpa.l #-1,a2>,ne
	suba.l	a2,a2
device_found:
;<a2.l:�f�o�C�X�h���C�o�̐擪,0=�f�o�C�X�h���C�o���Ȃ�
;<a3.l:(�f�o�C�X�h���C�o������Ƃ�)���O�̃f�o�C�X�h���C�o,(�f�o�C�X�h���C�o���Ȃ��Ƃ�)�Ō�̃f�o�C�X�h���C�o

;----------------------------------------------------------------
;�풓�v���O������T��
	lea.l	program_head(pc),a4	;�����̐擪
	dostart
		movea.l	d0,a4
		lea.l	MM_PROGRAM(a4),a4	;�풓�����̐擪
		lea.l	magic+8-program_head(a4),a0	;�풓�����̃}�W�b�N�̖���
		if	<cmpa.l MM_TAIL-MM_PROGRAM(a4),a0>,ls	;�������u���b�N�̒������m�F����
			lea.l	magic-program_head(a4),a0	;�풓�����̃}�W�b�N
			lea.l	magic(pc),a1		;�����̃}�W�b�N
			gotoand	<cmpm.l (a0)+,(a1)+>,eq,<cmpm.l (a0)+,(a1)+>,eq,keeppr_found	;��v������I��
		endif
	start
		move.l	MM_PREV-MM_PROGRAM(a4),d0	;���O�̃������Ǘ��e�[�u��
	while	ne
	lea.l	program_head(pc),a4	;�����̐擪
	dostart
		movea.l	d0,a4
		lea.l	MM_PROGRAM(a4),a4	;�풓�����̐擪
		lea.l	magic+8-program_head(a4),a0	;�풓�����̃}�W�b�N�̖���
		if	<cmpa.l MM_TAIL-MM_PROGRAM(a4),a0>,ls	;�������u���b�N�̒������m�F����
			lea.l	magic-program_head(a4),a0	;�풓�����̃}�W�b�N
			lea.l	magic(pc),a1		;�����̃}�W�b�N
			gotoand	<cmpm.l (a0)+,(a1)+>,eq,<cmpm.l (a0)+,(a1)+>,eq,keeppr_found	;��v������I��
		endif
	start
		move.l MM_NEXT-MM_PROGRAM(a4),d0	;����̃������Ǘ��e�[�u��
	while	ne
	suba.l	a4,a4
keeppr_found:
;<a4.l:�풓�v���O�����̐擪,0=�풓�v���O�������Ȃ�

;----------------------------------------------------------------
	move.l	a2,d0			;�f�o�C�X�h���C�o�̐擪
	if 	eq			;�f�o�C�X�h���C�o���Ȃ�

	;----------------------------------------------------------------
	;�풓���Ă��Ȃ�

		if	<tst.b keeppr_flag>,eq	;�풓���Ȃ�

		;���[�U���[�h�֕��A����
			usermode

		;�^�C�g���ƃ��b�Z�[�W��\������
			if	<tst.b quiet_flag>,eq
				lea.l	title(pc),a0
				bsr	print
			endif
			lea.l	not_installed_message(pc),a0
			bsr	eprint

		;�G���[�I������
			move.w	#1,-(sp)
			DOS	_EXIT2

		endif

	;----------------------------------------------------------------
	;�풓����

	;���[�N�G���A������������
		bsr	initialize_workarea	;���[�N�G���A������������

	;�Œ�s�b�`�܂��̓v���|�[�V���i���s�b�`��ݒ肷��
		if	<tst.b fixed_flag>,ne	;�Œ�s�b�`
			bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		elif	<tst.b proportional_flag>,ne	;�v���|�[�V���i���s�b�`
			bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		endif

	;�x�N�^��ύX����
		IOCS	_OS_CUROF
		lea.l	vector_table(pc),a0	;�x�N�^�e�[�u��
		bsr	set_vector		;�x�N�^��ύX����
		IOCS	_OS_CURON

	;�f�o�C�X�h���C�o��ڑ�����
		move.l	#program_head,(a3)	;�Ō�̃f�o�C�X�h���C�o�̎��̃f�o�C�X�h���C�o�������ɂ���
		bsr	reset_con_device	;�W�����o�͂Ɍ��݂�CON�f�o�C�X��ڑ�������

	;���[�U���[�h�֕��A����
		usermode

	;�^�C�g���ƃ��b�Z�[�W��\������
		if	<tst.b quiet_flag>,eq
			lea.l	title(pc),a0
			bsr	print
			lea.l	install_message(pc),a0
			bsr	print
		endif

	;�T���v����\������
		if	<tst.b sample_flag>,ne
			lea.l	sample(pc),a0
			bsr	print
		endif

	;�풓�I������
		clr.w	-(sp)
		move.l	#device_tail-program_head,-(sp)
		DOS	_KEEPPR

	else				;�f�o�C�X�h���C�o������

	;----------------------------------------------------------------
	;�풓���Ă���

		if	<tst.b keeppr_flag>,ne	;�풓����

		;���[�U���[�h�֕��A����
			usermode

		;�^�C�g���ƃ��b�Z�[�W��\������
			if	<tst.b quiet_flag>,eq
				lea.l	title(pc),a0
				bsr	print
			endif
			lea.l	already_message(pc),a0
			bsr	eprint

		;�G���[�I������
			move.w	#1,-(sp)
			DOS	_EXIT2

		endif

	;----------------------------------------------------------------
	;�풓���Ȃ�

	;�Œ�s�b�`�܂��̓v���|�[�V���i���s�b�`��ݒ肷��
		if	<tst.b fixed_flag>,ne	;�Œ�s�b�`
			bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		elif	<tst.b proportional_flag>,ne	;�v���|�[�V���i���s�b�`
			bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w
		endif

	;�T���v����\������
		if	<tst.b sample_flag>,ne
			lea.l	sample(pc),a0
			bsr	print
		endif

		if	<tst.b release_flag>,eq	;�������Ȃ�

		;���[�U���[�h�֕��A����
			usermode

		;����I������
			DOS	_EXIT

		endif

	;----------------------------------------------------------------
	;��������

	;�x�N�^���m�F����
		lea.l	(vector_table-program_head)(a2),a0	;�풓�����̃x�N�^�e�[�u��
		bsr	check_vector		;�x�N�^���m�F����

		if	ne			;�x�N�^���ύX����Ă���

		;���[�U���[�h�֕��A����
			usermode

		;�^�C�g���ƃ��b�Z�[�W��\������
			if	<tst.b quiet_flag>,eq
				lea.l	title(pc),a0
				bsr	print
			endif
			lea.l	vector_message(pc),a0
			bsr	eprint

		;�G���[�I������
			move.w	#1,-(sp)
			DOS	_EXIT2

		endif

	;�x�N�^���ύX����Ă��Ȃ�

	;�f�o�C�X�h���C�o��؂藣��
		move.l	(a2),(a3)		;�O�̃f�o�C�X�h���C�o�Ɏ��̃f�o�C�X�h���C�o���q��
		bsr	reset_con_device	;�W�����o�͂Ɍ��݂�CON�f�o�C�X��ڑ�������

	;�x�N�^�𕜌�����
		IOCS	_OS_CUROF
		lea.l	(vector_table-program_head)(a2),a0	;�풓�����̃x�N�^�e�[�u��
		bsr	release_vector		;�x�N�^�𕜌�����
		IOCS	_OS_CURON

	;�풓�v���O�������J������
		move.l a4,d0			;�풓�v���O�����̐擪
		if	ne			;�풓�v���O����������

			;�풓�v���O�������J������
			pea.l	MM_SIZE-MM_PROGRAM(a4)	;�풓�v���O�����̃������u���b�N�̐擪
			DOS	_MFREE
			addq.l	#4,sp

		endif

	;���[�U���[�h�֕��A����
		usermode

	;�^�C�g���ƃ��b�Z�[�W��\������
		if	<tst.b quiet_flag>,eq
			lea.l	title(pc),a0
			bsr	print
			lea.l	release_message(pc),a0
			bsr	print
		endif

	;����I������
		DOS	_EXIT

	endif

;----------------------------------------------------------------
;�g�p�@��\������
usage_exit:
	if	<tst.b quiet_flag>,eq
		lea.l	title_usage(pc),a0
		bsr	more
	endif

;����I������
	DOS	_EXIT

;----------------------------------------------------------------
;�x�N�^��ύX����
;<a0.l:�x�N�^�e�[�u��
set_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;�I�t�Z�b�g
		move.l	(a1),d0
		move.l	(a0)+,(a1)		;�V�����x�N�^
		move.l	d0,(a0)+		;�Â��x�N�^
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;�x�N�^���m�F����
;<a0.l:�풓�����̃x�N�^�e�[�u��
;>ccr:eq=�x�N�^�͕ύX����Ă��Ȃ�,ne=�x�N�^���ύX����Ă���
check_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;�I�t�Z�b�g
		move.l	(a1),d0
		break	<cmp.l (a0)+,d0>,ne	;�V�����x�N�^�����݂̃x�N�^�ƈ�v���Ȃ���Ύ��s
		addq.l	#4,a0			;�Â��x�N�^��ǂݔ�΂�
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;�x�N�^�𕜌�����
;<a0.l:�풓�����̃x�N�^�e�[�u��
release_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;�I�t�Z�b�g
		addq.l	#4,a0			;�V�����x�N�^��ǂݔ�΂�
		move.l	(a0)+,(a1)		;�Â��x�N�^
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;�W�����o�͂Ɍ��݂�CON�f�o�C�X��ڑ�������
reset_con_device:
	push	d0
	clr.w	-(sp)
	DOS	_CLOSE
	addq.w	#1,(sp)
	DOS	_CLOSE
	addq.w	#1,(sp)
	DOS	_CLOSE
	addq.l	#2,sp
	pop
	rts

;----------------------------------------------------------------
;���[�N�G���A������������
initialize_workarea:
	push	d0-d1/a0
	moveq.l	#0,d0
	lea.l	$0D30.w,a0
	move.w	#($0DC0-$0D30)/4-1,d1
	for	d1
		move.l	d0,(a0)+
	next
	pop
	rts

;----------------------------------------------------------------
;���b�Z�[�W
parameter_message:	.dc.b	'�w��ł��Ȃ��p�����[�^�ł�',13,10,0
not_installed_message:	.dc.b	'�풓���Ă��܂���',13,10,0
install_message:	.dc.b	'�풓���܂���',13,10,0
already_message:	.dc.b	'���ɏ풓���Ă��܂�',13,10,0
vector_message:		.dc.b	'�x�N�^���ύX����Ă��܂��B�����ł��܂���',13,10,0
release_message:	.dc.b	'�������܂���',13,10,0

;���s�ƃ^�C�g��
crlf_title:		.dc.b	13,10
;�^�C�g��
title:			.dc.b	TITLE_STRING,' version ',VERSION_STRING,13,10,0

;�^�C�g���Ǝg�p�@
title_usage:		.dc.b	TITLE_STRING,' version ',VERSION_STRING,13,10
			.dc.b	13,10
			.dc.b	'�I�v�V����',13,10
			.dc.b	'  -f        �Œ�s�b�`�ɐ؂�ւ���',13,10
			.dc.b	'  -k        �풓����',13,10
			.dc.b	'  -p        �v���|�[�V���i���s�b�`�ɐ؂�ւ���',13,10
			.dc.b	'  -q        �\�������炷',13,10
			.dc.b	'  -r        ��������',13,10
			.dc.b	'  -s        �T���v����\������',13,10
			.dc.b	'  -v        �\���𑝂₷',13,10
			.dc.b	13,10
			.dc.b	'���䕶��',13,10
			.dc.b	'  ^G        $07 BL �x����炷',13,10
			.dc.b	'  ^H        $08 BS �J�[�\����1�����ցB���[�ł�1�s��̉E�[�ցB��[�ł͉������Ȃ�',13,10
			.dc.b	'  ^I        $09 HT �J�[�\�������̃^�u���ցB�Ȃ����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��',13,10
			.dc.b	'  ^J        $0A LF �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v',13,10
			.dc.b	'  ^K        $0B VT �J�[�\����1�s��ցB��[�ł͉������Ȃ�',13,10
			.dc.b	'  ^L        $0C FF �J�[�\����1���E�ցB�E�[�ł�1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��',13,10
			.dc.b	'  ^M        $0D CR �J�[�\�������[��',13,10
			.dc.b	'  ^Z        $1A SB ���ォ��E���܂ŏ����B�J�[�\���������',13,10
			.dc.b	'  ^[        $1B EC �G�X�P�[�v�V�[�P���X�J�n',13,10
			.dc.b	'  ^^        $1E RS �J�[�\���������',13,10
			.dc.b	13,10
			.dc.b	'�G�X�P�[�v�V�[�P���X',13,10
			.dc.b	'  ^[*       ���ォ��E���܂ŏ����B�J�[�\���������',13,10
			.dc.b	'  ^[=rc     �J�[�\����r-$20�s,c-$20���ցBr��c�͕���',13,10
			.dc.b	'  ^[D       �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v',13,10
			.dc.b	'  ^[E       �J�[�\����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v',13,10
			.dc.b	'  ^[M       �J�[�\����1�s��ցB��[�ł̓X�N���[���_�E��',13,10
			.dc.b	'  ^[[>5l    �J�[�\��ON',13,10
			.dc.b	'  ^[[>5h    �J�[�\��OFF',13,10
			.dc.b	'  ^[[?4l    �W�����v�X�N���[��',13,10
			.dc.b	'  ^[[?4h    8�h�b�g�X���[�X�X�N���[��',13,10
			.dc.b	'  ^[[n@     �J�[�\������E��n���}��',13,10
			.dc.b	'  ^[[nA     �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�',13,10
			.dc.b	'  ^[[nB     �J�[�\����n�s���ցB���[�Ŏ~�܂�',13,10
			.dc.b	'  ^[[nC     �J�[�\����n���E�ցB�E�[�Ŏ~�܂�',13,10
			.dc.b	'  ^[[nD     �J�[�\����n�����ցB���[�Ŏ~�܂�',13,10
			.dc.b	'  ^[[r;cH   �J�[�\����r-1�s,c-1���ցB���[�Ŏ~�܂�B�E�[�Ŏ~�܂�',13,10
			.dc.b	'  ^[[r;cf   �J�[�\����r-1�s,c-1���ցB���[�Ŏ~�܂�B�E�[�Ŏ~�܂�',13,10
			.dc.b	'  ^[[0J     �J�[�\������E���܂ŏ�������',13,10
			.dc.b	'  ^[[1J     ���ォ��J�[�\���܂ŏ�������',13,10
			.dc.b	'  ^[[2J     ���ォ��E���܂ŏ�������B�J�[�\���������',13,10
			.dc.b	'  ^[[0K     �J�[�\������E�[�܂ŏ�������',13,10
			.dc.b	'  ^[[1K     ���[����J�[�\���܂ŏ�������',13,10
			.dc.b	'  ^[[2K     ���[����E�[�܂ŏ�������',13,10
			.dc.b	'  ^[[nL     �J�[�\�����牺��n�s�}���B�J�[�\�������[��',13,10
			.dc.b	'  ^[[nM     �J�[�\�����牺��n�s�폜�B�J�[�\�������[��',13,10
			.dc.b	'  ^[[nP     �J�[�\������E��n���폜',13,10
			.dc.b	'  ^[[nX     �J�[�\������E��n������',13,10
			.dc.b	'  ^[[nc     ������',13,10
			.dc.b	'  ^[[nl     ����',13,10
			.dc.b	'  ^[[0m     ���Z�b�g',13,10
			.dc.b	'  ^[[1m     ����',13,10
			.dc.b	'  ^[[2m     �׎�',13,10
			.dc.b	'  ^[[3m     �Α�',13,10
			.dc.b	'  ^[[4m     ����',13,10
			.dc.b	'  ^[[7m     ���]',13,10
			.dc.b	'  ^[[9m     ��������',13,10
			.dc.b	'  ^[[21m    �g��',13,10
			.dc.b	'  ^[[22m    �����A�׎�����',13,10
			.dc.b	'  ^[[23m    �Α̉���',13,10
			.dc.b	'  ^[[24m    �����A�g������',13,10
			.dc.b	'  ^[[26m    �v���|�[�V���i��',13,10
			.dc.b	'  ^[[27m    ���]����',13,10
			.dc.b	'  ^[[29m    ������������',13,10
			.dc.b	'  ^[[30m    ��',13,10
			.dc.b	'  ^[[31m    ���F',13,10
			.dc.b	'  ^[[32m    ���F',13,10
			.dc.b	'  ^[[33m    ��',13,10
			.dc.b	'  ^[[34m    �����A��',13,10
			.dc.b	'  ^[[35m    �����A���F',13,10
			.dc.b	'  ^[[36m    �����A���F',13,10
			.dc.b	'  ^[[37m    �����A��',13,10
			.dc.b	'  ^[[40m    ���]�A��',13,10
			.dc.b	'  ^[[41m    ���]�A���F',13,10
			.dc.b	'  ^[[42m    ���]�A���F',13,10
			.dc.b	'  ^[[43m    ���]�A��',13,10
			.dc.b	'  ^[[44m    ���]�A�����A��',13,10
			.dc.b	'  ^[[45m    ���]�A�����A���F',13,10
			.dc.b	'  ^[[46m    ���]�A�����A���F',13,10
			.dc.b	'  ^[[47m    ���]�A�����A��',13,10
			.dc.b	'  ^[[50m    �v���|�[�V���i������',13,10
			.dc.b	'  ^[[51m    �l�p�͂�',13,10
			.dc.b	'  ^[[52m    �ۈ͂�',13,10
			.dc.b	'  ^[[53m    ���',13,10
			.dc.b	'  ^[[54m    �l�p�͂݁A�ۈ͂݉���',13,10
			.dc.b	'  ^[[55m    �������',13,10
			.dc.b	'  ^[[73m    ��t��',13,10
			.dc.b	'  ^[[74m    ���t��',13,10
			.dc.b	'  ^[[75m    ��t���A���t������',13,10
			.dc.b	'  ^[[6n     �J�[�\���ʒu�񍐁B^[[r;cR�����',13,10
			.dc.b	'  ^[[nr     �E��',13,10
			.dc.b	'  ^[[s      �J�[�\���̍��W�ƕ���������ۑ�����',13,10
			.dc.b	'  ^[[u      �J�[�\���̍��W�ƕ��������𕜌�����',13,10
			.dc.b	0

;�T���v��
sample:			.dc.b	27,'[s',27,'[m',13,10
			.dc.b	'�T���v��',13,10
			.dc.b	'  ',27,'[1m����',27,'[m'
			.dc.b	'  ',27,'[7m���]',27,'[m'
			.dc.b	'  ',27,'[31m���F',27,'[m'
			.dc.b	'  ',27,'[32m���F',27,'[m',13,10
			.dc.b	'  ',27,'[2m�׎�',27,'[m'
			.dc.b	'  ',27,'[3m�Α�',27,'[m'
			.dc.b	'  ',27,'[4m����',27,'[m'
			.dc.b	'  ',27,'[53m���',27,'[m'
			.dc.b	'  ',27,'[9m��������',27,'[m'
			.dc.b	'  ',27,'[21m�g��',27,'[m',13,10
			.dc.b	'  ',27,'[51m�l�p�͂�',27,'[m'
			.dc.b	'  ',27,'[52m�ۈ͂�',27,'[m'
			.dc.b	'  ',27,'[73m��t��',27,'[m'
			.dc.b	'  ',27,'[74m���t��',27,'[m',13,10
			.dc.b	'  ',27,'[7m',27,'[150l����',27,'[m',13,10
			.dc.b	'  ',27,'[7m',27,'[150c������',27,'[m',13,10
			.dc.b	'  ',27,'[7m',27,'[150r�E��',27,'[m',13,10
			.dc.b	'  ',27,'[26mProportional-Pitch',27,'[m',13,10
			.dc.b	13,10
			.dc.b	'  ',27,'[26m    Alice was beginning to get very tired of sitting by her sister on the bank, and',13,10
			.dc.b	'  of having nothing to do: once or twice she had peeped into the book her sister was',13,10
			.dc.b	'  reading, but it had no pictures or conversations in it, `and what is the use of a book,',39,13,10
			.dc.b	'  thought Alice `without pictures or conversation?',39,13,10
			.dc.b	'  ',27,'[640r-- from Alice in Wonderland by Lewis Carroll --',27,'[m',13,10
			.dc.b	13,10,27,'[u'
			.dc.b	0

	.data

;----------------------------------------------------------------
;�t���O
option_flag:		.dc.b	0	;-1=�I�v�V�������w�肳�ꂽ
fixed_flag:		.dc.b	0	;-f�B-1=�Œ�s�b�`
keeppr_flag:		.dc.b	0	;-k�B-1=�풓����
proportional_flag:	.dc.b	0	;-p�B-1=�v���|�[�V���i���s�b�`
quiet_flag:		.dc.b	0	;-q�B-1=�\�������炷
release_flag:		.dc.b	0	;-r�B-1=��������
sample_flag:		.dc.b	0	;-s�B-1=�T���v��
verbose_flag:		.dc.b	0	;-v�B-1=�\���𑝂₷



	.text
	.even

;----------------------------------------------------------------
;��������G���[�\������
;<a0.l:������
eprint:
	move.l	d0,-(sp)
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#2,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;���s���G���[�\������
eprintcrlf:
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	bsr	eprint
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;������Ɖ��s���G���[�\������
;<a0.l:������
eprintln:
	bsr	eprint
	bsr	eprintcrlf
	rts

;----------------------------------------------------------------
;-more-�����݂Ȃ��當�����\������
;<a0.l:������
more:
	push	d0-d5/a0-a2
;�W�����͂��m�F����
	clr.l	-(sp)			;(0<<16)|0
	DOS	_IOCTRL
	addq.l	#4,sp
;<d0.b:�W�����͂�FCB�t���O
	and.b	#$81,d0			;�L�����N�^�f�o�C�X�A�W������
	goto	<cmp.b #$81,d0>,ne,90f	;�W�����͂����_�C���N�g����Ă���Bmore���Ȃ�
;�W���o�͂��m�F����
	pea.l	1.w			;(0<<16)|1
	DOS	_IOCTRL
	addq.l	#4,sp
;<d0.b:�W���o�͂�FCB�t���O
	and.b	#$82,d0			;�L�����N�^�f�o�C�X�A�W���o��
	goto	<cmp.b #$82,d0>,ne,90f	;�W���o�͂����_�C���N�g����Ă���Bmore���Ȃ�
;CONDRV.SYS���m�F����
	move.w	#$0100+_KEY_INIT,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	movea.l	d0,a1
	subq.l	#4,a1
	IOCS	_B_LPEEK
	goto	<cmp.l #'hmk*',d0>,eq,90f	;CONDRV.SYS���g�ݍ��܂�Ă���Bmore���Ȃ�
;��ʂ̑傫�����m�F����
	moveq.l	#-1,d1
	moveq.l	#-1,d2
	IOCS	_B_CONSOL
;<d2.l:�E�[�̌����W<<16|���[�̍s���W
	move.w	d2,d3
	swap.w	d2
	addq.w	#1,d2
;<d2.w:��ʂ̌���
;<d3.w:���[�̍s���W�B-more-�̍s����������ʂ̍s��
	gotoor	<cmp.w #8,d2>,lo,<tst.w d3>,eq,90f	;��ʂ���������Bmore���Ȃ��B�^�u���܂߂�1�����ȏ㏑���Ȃ���΂Ȃ�Ȃ��̂�8��x1�s������
;�y�[�W���[�v
	do
		move.l	#0,d4			;�����W
		move.l	#0,d5			;�s���W
		movea.l	a0,a2			;�y�[�W�擪
	;�������[�v
		do
			movea.l	a0,a1			;�����擪
			move.b	(a0)+,d0		;1�o�C�g��
			if	eq			;00 �I��
				subq.l	#1,a0
				break
			elif	<cmp.b #$09,d0>,eq	;09 �^�u
				moveq.l	#7,d1
				and.w	d4,d1
				subq.w	#8,d1
				neg.w	d1		;�^�u�̌���
			elif	<cmp.b #$0A,d0>,eq	;0A ���s
				moveq.l	#0,d4		;���[��
				addq.w	#1,d5		;���̍s��
				break	<cmp.w d3,d5>,eq	;���[�B�y�[�W�I���
				continue
			elif	<cmp.b #$0C,d0>,eq	;0C ���y�[�W
				break
			elif	<cmp.b #$1F,d0>,ls	;01-08,0B,0D-1F ��������
				continue
			else				;20-FF
				do
					moveq.l	#1,d1			;���p�̌���
					break	<tst.b d0>,pl		;20-7F �A�X�L�[
					breakand	<cmp.b #$A0,d0>,hs,<cmp.b #$DF,d0>,ls	;A0-DF ���p�J�^�J�i
					addq.l	#1,a0			;2�o�C�g��
					break	<cmp.b #$80,d0>,eq	;8000-80FF ���p�Ђ炪��
					break	<cmp.b #$F0,d0>,hs	;F000-FFFF 1/4�p�A���p�O��
					moveq.l	#2,d1			;�S�p�̌���
				while	f
			endif
			add.w	d1,d4			;�\��������̌����W
			if	<cmp.w d2,d4>,hi	;�͂ݏo��
				sub.w	d1,d4			;�i�݉߂������߂�
				movea.l	a1,a0
				addq.w	#1,d5			;���̍s��
				break	<cmp.w d3,d5>,eq	;���[�B�y�[�W�I���
				moveq.l	#0,d4			;���[��
			endif
		while	t
	;1�y�[�W�\������
		move.l	a0,d0			;����
		sub.l	a2,d0			;����-�擪=����
		move.l	d0,-(sp)		;����
		move.l	a2,-(sp)		;�擪
		move.w	#1,-(sp)		;�W���o��
		DOS	_WRITE
		lea.l	10(sp),sp
	;�������Ȃ���ΏI������
		break	<tst.b (a0)>,eq
	;�K�v�Ȃ�Ή��s����
		ifand	<tst.w d4>,ne,<cmp.w d2,d4>,ne	;���[�ł��E�[�ł��Ȃ�
			bsr	printcrlf
		endif
	;-more-��\������
		pea.l	6.w
		pea.l	100f(pc)		;'-more-'
		move.w	#1,-(sp)
		DOS	_WRITE
		lea.l	10(sp),sp
	;�L�[���͂�҂�
		DOS	_GETC
		move.l	d0,d1
	;���s����
		bsr	printcrlf
	whileand	<cmp.b #$1B,d1>,ne,<cmp.b #'Q',d1>,ne,<cmp.b #'q',d1>,ne	;ESC�܂���Q�������ꂽ�Ƃ��͏I������
99:	pop
	rts

;more���Ȃ�
90:	bsr	print
	goto	99b

100:	.dc.b	'-more-'
	.even

;----------------------------------------------------------------
;�󔒂�
;<d0.b:����
;>z:eq=��,ne=�󔒂ł͂Ȃ�
isspace:
	ifor	<cmp.b #' ',d0>,eq,<cmp.b #9,d0>,eq,<cmp.b #10,d0>,eq,<cmp.b #11,d0>,eq,<cmp.b #12,d0>,eq,<cmp.b #13,d0>,eq	; \t\n\v\f\r
	endif
	rts

;----------------------------------------------------------------
;�󔒈ȊO�̕����܂œǂݔ�΂�
;<a0.l:������
;>d0.l:�󔒈ȊO�̕����܂���0
;>a0.l:�󔒈ȊO�̕����܂���0�̈ʒu
;>z:eq=0
nonspace:
	moveq.l	#0,d0
	do
		move.b	(a0)+,d0		;���̕���
		redoand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r�Ȃ�ΌJ��Ԃ�
	while	<cmp.b #' ',d0>,eq	;�󔒂Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	tst.l	d0
	rts

;----------------------------------------------------------------
;�������\������
;<a0.l:������
print:
	move.l	d0,-(sp)
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	move.l	(sp)+,d0
	rts

;----------------------------------------------------------------
;���s��\������
printcrlf:
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	bsr	print
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;������Ɖ��s��\������
;<a0.l:������
println:
	bsr	print
	bsr	printcrlf
	rts

;----------------------------------------------------------------
;10�i���̕�����𕄍��Ȃ������ɕϊ�����
;<a0.l:10�i���̕�����B�擪�̋󔒂͔F�߂Ȃ�
;>d0.l:(cc�̂Ƃ�)�����Ȃ������B(cs�̂Ƃ�)0=10�i���̕������Ȃ�,-1=�I�[�o�[�t���[
;>a0.l:(cc�̂Ƃ�)10�i���̕�����̎��̈ʒu�B(cs�̂Ƃ�)�ω����Ȃ�
;>z:(cc�̂Ƃ�)eq=�����Ȃ�������0
;>v:(cs�̂Ƃ�)vc=10�i���̕������Ȃ�,vs=�I�[�o�[�t���[
;>c:cs=10�i���̕������Ȃ��܂��̓I�[�o�[�t���[
stou:
	push	d1-d2/a1
	moveq.l	#0,d0			;�����Ȃ�����
	moveq.l	#0,d1			;����
	movea.l	a0,a1			;�J�n�ʒu
	dostart
		goto	<cmp.l #$1999999A,d0>,hs,80f	;10�{������I�[�o�[�t���[����
		move.l	d0,d2			;1�{
		lsl.l	#2,d0			;4�{
		add.l	d2,d0			;5�{
		add.l	d0,d0			;10�{����
		add.l	d1,d0			;1��������
		goto	cs,80f			;�I�[�o�[�t���[����
	start
		move.b	(a0)+,d1		;���̕���
		sub.b	#'0',d1			;�����ɂ���
	whileand	<>,hs,<cmp.b #10,d1>,lo	;10�i���̕����Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	if	<cmpa.l a1,a0>,eq	;�i��ł��Ȃ��B10�i���̕������Ȃ�
		move.w	#%00001,ccr		;vc,cs
	else
		tst.l	d0			;eq or ne,vc,cc
	endif
	goto	90f

;�I�[�o�[�t���[�����Ƃ�
80:	moveq.l	#-1,d0			;�I�[�o�[�t���[
	movea.l	a1,a0			;�ω����Ȃ�
	move.w	#%00011,ccr		;vs,cs
90:	pop
	rts

;----------------------------------------------------------------
;������̒����𐔂���
;<a0.l:������
;>d0.l:����
strlen:
	move.l	a0,d0			;d0=�擪
	do
		tst.b (a0)+
	while	ne			;0�łȂ���ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�Ba0=����
	exg.l	d0,a0			;d0=����,a0=�擪
	sub.l	a0,d0			;d0=����-�擪=����
	rts

;----------------------------------------------------------------
;�������ɂ���
;<d0.b:����
;>d0.b:����
tolower:
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;�啶��
		add.b	#'a'-'A',d0		;�������ɂ���
	endif
	rts



;----------------------------------------------------------------
;�v���O�����̖���
	.bss
	.even
program_end:

	.end	execution_start

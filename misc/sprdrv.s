;========================================================================================
;  sprdrv.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;�^�C�g��
;	�g���X�v���C�g�E�o�b�N�O���E���h�h���C�o
;���O
;	sprdrv.x
;�o�[�W����
;	(2025-04-10)
;�@�\
;	�X�v���C�g�E�o�b�N�O���E���h�֘A��IOCS�R�[����XEiJ�̊g���@�\���g�p�ł���悤�ɂ��܂��B
;	_SP_INIT�Ŋg���@�\��L���ɂ����v���Z�X���I������Ƃ��g���@�\�𖳌��ɂ��܂��B
;XEiJ�̐ݒ�
;	4096�̃p�^�[����ON�ɂ��ă��Z�b�g���Ă��������B
;	�X�v���C�g�̖�����128/256/504/1016�̂����ꂩ�A768x512�ŃX�v���C�g��\���A512x512��BG1��\���ɑΉ����܂��B
;	���X�^������̃X�v���C�g�̖�����1016�ɂ��Ă����Ƃ悢�ł��傤�B
;�g�p�@
;	device=sprdrv.x <�I�v�V����>
;	  �܂���
;	A>sprdrv.x <�I�v�V����>
;�I�v�V����
;	-c	�풓�m�F
;		�풓�m�F���s���A���ʂ����b�Z�[�W�ƏI���R�[�h�ŕԂ��܂��B
;	-d	��n���Ȃ�
;		���݂̃v���Z�X�̏I���V�[�P���X�Ɍ�n���̏�����ǉ����܂���B
;		�������̃v���Z�X��������Ă���ꍇ�Ɏw�肵�܂��B
;		�I���V�[�P���X�̕ύX�����̃v���O������OS�̃p�b�`�ƏՓ˂���ꍇ�ɂ��w�肵�܂��B
;	-e	��n������(�f�t�H���g)
;		�g���@�\���g�p����Ƃ��A���݂̃v���Z�X�̏I���V�[�P���X�Ɍ�n���̏�����ǉ����܂��B
;	-q	�Ïl
;		�I�v�V�������Ⴄ�Ƃ��ȊO�A���b�Z�[�W��\�����܂���B
;	-r	�풓����
;		�풓�������f�o�C�X�h���C�o�̂Ƃ��A�x�N�^�𕜌����ăf�o�C�X�h���C�o��؂藣���܂��B
;		�풓�������������u���b�N�̂Ƃ��A�x�N�^�𕜌����ă������u���b�N���J�����܂��B
;		�풓��Ƀx�N�^���ύX����ď풓�������w���Ă��Ȃ��Ƃ��͉����ł��܂���B
;	-v	�o�[�W�����m�F
;		�^�C�g���ƃo�[�W������\�����Đ���I�����܂��B
;�I���R�[�h
;	0	�������܂���
;	1	�I�v�V�������Ⴂ�܂�
;	2	�풓���Ă��܂�
;	3	�풓���Ă��܂���
;	4	�x�N�^���ύX����Ă��܂��B�����ł��܂���
;	65536	�풓���܂���
;�X�V����
;	2025-04-07
;		���ŁB
;	2025-04-10
;		_SP_REGST/_SP_REGGT�̃X�v���C�g�̔ԍ���A�ԂɕύX���܂����B
;		_BGTEXTST���C�����܂����B
;----------------------------------------------------------------
;�o���N����
;	  15   14   13   12   11   10    9    8    7    6    5    4    3    2    1    0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|                                                                | ���[�h  |�ړ�|
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	�ړ�
;		�ړ�	�e�L�X�g�G���A�̈ړ�
;		0	���Ȃ�
;		1	����
;	���[�h
;		���[�h	�p�^�[����	�X�v���C�g���]	�e�L�X�g���]
;		0	256		��		��
;		1	1024		��		��
;		2	4096		�s��		�s��
;		3	4096		��		�s��
;		���]�s��₤���߁A_SP_DEFCG�Ƀp�^�[���𔽓]����@�\���ǉ�����Ă��܂��B
;�L�����N�^
;	  15   14   13   12   11   10    9    8    7    6    5    4    3    2    1    0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|�㉺|���E|         | �p���b�g�u���b�N  |             �p�^�[���ԍ�              |  ���[�h0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|�㉺|���E|�ԍ���� | �p���b�g�u���b�N  |           �p�^�[���ԍ�����            |  ���[�h1
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	| �p�^�[���ԍ����  | �p���b�g�u���b�N  |           �p�^�[���ԍ�����            |  ���[�h2,3
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;�v���C�I���e�B
;	  15   14   13   12   11   10    9    8    7    6    5    4    3    2    1    0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|                                                                |����|�D�揇�� |  ���[�h0,1,2
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|�㉺|���E|                                                      |����|�D�揇�� |  ���[�h3
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	�D�揇��
;	0	�\�����Ȃ�
;	1	�o�b�N�O���E���h0���o�b�N�O���E���h1���X�v���C�g
;	2	�o�b�N�O���E���h0���X�v���C�g���o�b�N�O���E���h1
;	3	�X�v���C�g���o�b�N�O���E���h0���o�b�N�O���E���h1
;----------------------------------------------------------------
;IOCS $C0 _SP_INIT
;	�@�\	�X�v���C�g�E�o�b�N�O���E���h�����������܂��B
;		_SP_INIT�Ŋg���@�\��L���ɂ����v���Z�X���I������Ƃ��g���@�\�𖳌��ɂ��܂��B
;	����	���W�X�^	�l
;		d1.l		'SPRD'$53505244	�g���@�\���g�p����
;		d2.l		0�`7		�o���N����
;	�o��	���W�X�^	�l
;		d0.l		-3		�g���@�\���g�p�ł��Ȃ�
;				-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C1 _SP_ON
;	�@�\	�X�v���C�g��ʂ�\�����܂��B
;	����	�Ȃ�
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C2 _SP_OFF
;	�@�\	�X�v���C�g��ʂ�\�����܂���B
;	����	�Ȃ�
;	�o��	���W�X�^	�l
;		d0.l		0		����I��
;----------------------------------------------------------------
;IOCS $C3 _SP_CGCLR
;	�@�\	�p�^�[�����[���N���A���܂��B
;	����	���W�X�^	�l
;		d1.w		0�`4095		�p�^�[���ԍ�
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C4 _SP_DEFCG
;	�@�\	�p�^�[����ݒ肵�܂��B
;		�p�^�[���𔽓]����@�\���ǉ�����Ă��܂��B
;	����	���W�X�^	�l
;		d1.w		0�`4095		�p�^�[���ԍ�
;		d2.w[15]	0�`1		�㉺���]
;		d2.w[14]	0�`1		���E���]
;		d2.b		0�`1		�T�C�Y�B0=8x8,1=16x16
;		a1.l		����		�o�b�t�@�̃A�h���X
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C5 _SP_GTPCG
;	�@�\	�p�^�[�����擾���܂��B
;	����	���W�X�^	�l
;		d1.w		0�`4095		�p�^�[���ԍ�
;		d2.b		0�`1		�T�C�Y�B0=8x8,1=16x16
;		a1.l		����		�o�b�t�@�̃A�h���X
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C6 _SP_REGST
;	�@�\	�X�v���C�g�X�N���[�����W�X�^��ݒ肵�܂��B
;		�����r�b�g���N���A���܂��B
;	����	���W�X�^	�l
;		d1.l[31]	1		VDISP�̗����������҂��Ȃ�
;		d1.w		0�`1015		�X�v���C�g�ԍ�(�A��)
;		d2.l[31]	1		X���W��ݒ肵�Ȃ�
;		d2.w		0�`1023		X���W
;		d3.l[31]	1		Y���W��ݒ肵�Ȃ�
;		d3.w		0�`1023		Y���W
;		d4.l[31]	1		�L�����N�^��ݒ肵�Ȃ�
;		d4.w		0�`65535	�L�����N�^
;		d5.l[31]	1		�v���C�I���e�B��ݒ肵�Ȃ�
;		d5.w		0�`65535	�v���C�I���e�B
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C7 _SP_REGGT
;	�@�\	�X�v���C�g�X�N���[�����W�X�^���擾���܂��B
;	����	���W�X�^	�l
;		d1.w		0�`1015		�X�v���C�g�ԍ�(�A��)
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;		d2.l		0�`1023		X���W
;		d3.l		0�`1023		Y���W
;		d4.l		0�`65535	�L�����N�^
;		d5.l		0�`65535	�v���C�I���e�B
;----------------------------------------------------------------
;IOCS $C8 _BGSCRLST
;	�@�\	�o�b�N�O���E���h�X�N���[�����W�X�^��ݒ肵�܂��B
;	����	���W�X�^	�l
;		d1.l[31]	1		VDISP�̗����������҂��Ȃ�
;		d1.b		0�`1		�o�b�N�O���E���h�ԍ�
;		d2.l[31]	1		X���W��ݒ肵�Ȃ�
;		d2.w		0�`1023		X���W
;		d3.l[31]	1		Y���W��ݒ肵�Ȃ�
;		d3.w		0�`1023		Y���W
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $C9 _BGSCRLGT
;	�@�\	�o�b�N�O���E���h�X�N���[�����W�X�^���擾���܂��B
;	����	���W�X�^	�l
;		d1.b		0�`1		�o�b�N�O���E���h�ԍ�
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;		d2.l		0�`1023		X���W
;		d3.l		0�`1023		Y���W
;----------------------------------------------------------------
;IOCS $CA _BGCTRLST
;	�@�\	�o�b�N�O���E���h���䃌�W�X�^��ݒ肵�܂��B
;	����	���W�X�^	�l
;		d1.b		0�`1		�o�b�N�O���E���h�ԍ�
;		d2.l[31]	1		�e�L�X�g�G���A�ԍ���ݒ肵�Ȃ�
;		d2.b		0�`1		�e�L�X�g�G���A�ԍ�
;		d3.l[31]	1		�\���̗L����ݒ肵�Ȃ�
;		d3.b		0�`1		�\���̗L��
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $CB _BGCTRLGT
;	�@�\	�o�b�N�O���E���h���䃌�W�X�^���擾���܂�
;	����	���W�X�^	�l
;		d1.b		0�`1		�o�b�N�O���E���h�ԍ�
;	�o��	���W�X�^	�l
;		d0.l		-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0�`7		�e�L�X�g�G���A�ԍ�<<1|�\���̗L��
;----------------------------------------------------------------
;IOCS $CC _BGTEXTCL
;	�@�\	�o�b�N�O���E���h�e�L�X�g���L�����N�^�Ŗ��ߐs�����܂��B
;		�^���O���t�B�b�N��ʂ����@�\���ǉ�����Ă��܂��B
;	����	���W�X�^	�l
;		d1.w[15�`8]	$00		�L�����N�^�Ŗ��ߐs����
;				$10		�^���O���t�B�b�N��ʂ����
;		d1.b		0�`1		�e�L�X�g�G���A�ԍ�
;		d2.w		0�`65535	�L�����N�^�^�p���b�g�u���b�N
;	�o��	���W�X�^	�l
;		d0.l		-3		�g���@�\���g�p�ł��Ȃ�
;				-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $CD _BGTEXTST
;	�@�\	�o�b�N�O���E���h�e�L�X�g�ɃL�����N�^���������݂܂��B
;		�^���O���t�B�b�N��ʂɏ������ދ@�\���ǉ�����Ă��܂��B
;	����	���W�X�^	�l
;		d1.w[15�`8]	$00		�L�����N�^����������
;				$10		�^���O���t�B�b�N��ʂ�1�h�b�g��������
;		d1.b		0�`1		�e�L�X�g�G���A�ԍ�
;		d2.w		0�`1023		X���W
;		d3.w		0�`1023		Y���W
;		d4.w		0�`65535	�L�����N�^�^�p���b�g�R�[�h
;	�o��	���W�X�^	�l
;		d0		-3		�g���@�\���g�p�ł��Ȃ�
;				-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0		����I��
;----------------------------------------------------------------
;IOCS $CE _BGTEXTGT
;	�@�\	�o�b�N�O���E���h�e�L�X�g����L�����N�^��ǂݏo���܂��B
;		�^���O���t�B�b�N��ʂ���ǂݏo���@�\���ǉ�����Ă��܂��B
;	����	���W�X�^	�l
;		d1.w[15�`8]	$00		�L�����N�^��ǂݏo��
;				$10		�^���O���t�B�b�N��ʂ���1�h�b�g�ǂݏo��
;		d1.b		0�`1		�e�L�X�g�G���A�ԍ�
;		d2.w		0�`1023		X���W
;		d3.w		0�`1023		Y���W
;	�o��	���W�X�^	�l
;		d0.l		-3		�g���@�\���g�p�ł��Ȃ�
;				-1		�X�v���C�g��ʂ��g�p�ł��Ȃ�
;				0�`65535	�L�����N�^�^�p���b�g�R�[�h
;----------------------------------------------------------------
;IOCS $CF _SPALET
;	�@�\	�X�v���C�g�p���b�g��ݒ�܂��͎擾���܂��B
;		�p���b�g�u���b�N0�͎w��ł��܂���B
;	����	���W�X�^	�l
;		d1.l[31]	1		VDISP�̗����������҂��Ȃ�
;		d1.b		0�`255		�p���b�g�u���b�N<<4|�p���b�g�R�[�h
;		d2.b		0�`15		�p���b�g�u���b�N(�D��)
;		d3.l[31]	0		�ݒ�
;				1		�擾
;		d3.w		0�`65535	�J���[�R�[�h
;	�o��	���W�X�^	�l
;		d0.l		-2		�p���b�g�u���b�N0���w�肳�ꂽ
;				0�`65535	�ݒ�O�̃J���[�R�[�h
;----------------------------------------------------------------

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
	.include	sprc.equ
	.include	vector.equ
	.include	vicon.equ

DEVICE_NAME	reg	'/*SPRD*/'
JAPANESE_TITLE	reg	'�g���X�v���C�g�E�o�b�N�O���E���h�h���C�o'
ENGLISH_TITLE	reg	'Extended sprite and background driver'
VERSION_STRING	reg	'(2025-04-10)'
PROGRAM_NAME	reg	'sprdrv.x'
PROGRAMEN_NAME	reg	'sprdrven.x'

  .ifndef ENGLISH
ENGLISH		equ	0
  .endif

;----------------------------------------------------------------
;�v���O�����̐擪
	.text
program_head:

;�f�o�C�X�w�b�_
	.dc.l	-1			;���̃f�o�C�X�w�b�_�B-1=�f�o�C�X�w�b�_�̃��X�g�̖���
	.dc.w	$8000			;�f�o�C�X�^�C�v�B�L�����N�^�f�o�C�X
	.dc.l	strategy_routine	;�X�g���e�W���[�`��
	.dc.l	interrupt_routine	;�C���^���v�g���[�`��
	.dc.b	DEVICE_NAME		;�f�o�C�X��

;�x�N�^�e�[�u��
vector_table:
	.dc.w	4*($100+_SP_INIT)	;�I�t�Z�b�g
	.dc.l	iocs_C0_SP_INIT		;�V�����x�N�^
	.dc.l	0			;�Â��x�N�^
	.dc.w	4*($100+_SP_ON)
	.dc.l	iocs_C1_SP_ON
	.dc.l	0
	.dc.w	4*($100+_SP_OFF)
	.dc.l	iocs_C2_SP_OFF
	.dc.l	0
	.dc.w	4*($100+_SP_CGCLR)
	.dc.l	iocs_C3_SP_CGCLR
	.dc.l	0
	.dc.w	4*($100+_SP_DEFCG)
	.dc.l	iocs_C4_SP_DEFCG
	.dc.l	0
	.dc.w	4*($100+_SP_GTPCG)
	.dc.l	iocs_C5_SP_GTPCG
	.dc.l	0
	.dc.w	4*($100+_SP_REGST)
	.dc.l	iocs_C6_SP_REGST
	.dc.l	0
	.dc.w	4*($100+_SP_REGGT)
	.dc.l	iocs_C7_SP_REGGT
	.dc.l	0
	.dc.w	4*($100+_BGSCRLST)
	.dc.l	iocs_C8_BGSCRLST
	.dc.l	0
	.dc.w	4*($100+_BGSCRLGT)
	.dc.l	iocs_C9_BGSCRLGT
	.dc.l	0
	.dc.w	4*($100+_BGCTRLST)
	.dc.l	iocs_CA_BGCTRLST
	.dc.l	0
	.dc.w	4*($100+_BGCTRLGT)
	.dc.l	iocs_CB_BGCTRLGT
	.dc.l	0
	.dc.w	4*($100+_BGTEXTCL)
	.dc.l	iocs_CC_BGTEXTCL
	.dc.l	0
	.dc.w	4*($100+_BGTEXTST)
	.dc.l	iocs_CD_BGTEXTST
	.dc.l	0
	.dc.w	4*($100+_BGTEXTGT)
	.dc.l	iocs_CE_BGTEXTGT
	.dc.l	0
	.dc.w	4*($100+_SPALET)
	.dc.l	iocs_CF_SPALET
	.dc.l	0
	.dc.w	0

;�t���O
cleanup_flag:
	.dc.b	-1			;-1=��n������,0=��n���Ȃ�
	.even

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
	docontinue
		clr.b	(a1)+
	while	<subq.l #1,d3>,cc
	moveq.l	#0,d0			;��ɐ�������(�I���܂ŕ��A���Ȃ�)
	rts

;�f�o�C�X�R�}���h5 �R���g���[��/�Z���X
control_sense:
	clr.b	13(a5)			;�f�[�^
	moveq.l	#0,d0			;��ɐ�������
	rts

;�f�o�C�X�R�}���h6 ���̓X�e�[�^�X
input_status:
	moveq.l	#1,d0			;0=���̓o�b�t�@����ł͂Ȃ��̂œ��͂ł���,1=���̓o�b�t�@����Ȃ̂œ��͂ł��Ȃ�
	rts

;�f�o�C�X�R�}���h7 ���̓o�b�t�@�t���b�V��
input_flush:
	moveq.l	#0,d0			;��ɐ�������
	rts

;�f�o�C�X�R�}���h8 �o��(�x���t�@�C�Ȃ�)
;�f�o�C�X�R�}���h9 �o��(�x���t�@�C����)
output:
;	movea.l	14(a5),a1		;�A�h���X
;	move.l	18(a5),d3		;����
	moveq.l	#0,d0			;��ɐ�������(�I���܂ŕ��A���Ȃ�)
	rts

;�f�o�C�X�R�}���h10 �o�̓X�e�[�^�X
output_status:
	moveq.l	#1,d0			;0=�o�̓o�b�t�@�����t�ł͂Ȃ��̂ŏo�͂ł���,1=�o�̓o�b�t�@�����t�Ȃ̂ŏo�͂ł��Ȃ�
	rts

;�f�o�C�X�R�}���h11 ����I��
no_error:
	moveq.l	#0,d0			;��ɐ�������
	rts

;�f�o�C�X�R�}���h12 _IOCTRL�ɂ��o��
ioctrl_output:
;	movea.l	14(a5),a1		;�A�h���X
	goto	command_error



;----------------------------------------------------------------
;���[�N�G���A
original_exitvc:
	.dc.l	0			;�ύX�O��_EXITVC�B0=�ύX���Ă��Ȃ�
original_sr:
	.dc.w	0			;�ύX�O��sr
text_area:
	.dc.l	SPRC_TEXT_0		;���݂̃e�L�X�g�G���A0
sprite_max:
	.dc.w	127			;�X�v���C�g�ԍ��̍ő�l�B127,255,511,1023
bank_available:
	.dc.b	0			;-1=�o���N����,0=�o���N�Ȃ�
extended_1xx1x:
	.dc.b	1			;%1xx1x�̂Ƃ��X�v���C�g��ʂ��g�p�ł��邩�B-1=�g����,0=�g���Ȃ�,1=���m�F
	.even

;----------------------------------------------------------------
;_EXITVC���[�`��
;	_EXITVC��p���Đe�v���Z�X��_EXEC�̒���ɏ�����ǉ�����
;	���̂܂܂��Ɛe�v���Z�X�����[�U���[�h�̂Ƃ��X�[�p�[�o�C�U�̈�ɂ���(�f�o�C�X�h���C�o�̒��ɂ���)�R�[�h�����s�ł��Ȃ�
;	�e�v���Z�X��sr��ύX���ăX�[�p�[�p�C�U���[�h�Œǉ��̏��������s���Ă���ύX�O��sr�𕜌�����
exitvc_routine:
;��n������
	push	d0-d1/a0
	move.b	cleanup_flag(pc),d0
	if	ne			;��n������
		moveq.l	#0,d1
		bsr	iocs_C0_SP_INIT
	endif
	pop
;�ύX�O��sr�𕜌����āA�ύX�O��_EXITVC(����_EXITVC�ɒǉ����ꂽ�������Ȃ���ΐe�v���Z�X��_EXEC�̒���)�փW�����v����
	if	<tst.b BIOS_MPU_TYPE.w>,ne
		clr.w	-(sp)
	endif
	move.l	original_exitvc(pc),-(sp)	;�ύX�O��_EXITVC
	clr.l	original_exitvc
	move.w	original_sr(pc),-(sp)	;�ύX�O��sr
	clr.w	original_sr
	rte

;----------------------------------------------------------------
;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
;	IOCS�R�[���̐擪�ŌĂяo��
;	�X�v���C�g��ʂ��g�p�ł���Ƃ��������Ȃ�
;	�X�v���C�g��ʂ��g�p�ł��Ȃ��Ƃ�d0.l=-1��IOCS�R�[�����I������
;?d0/a0
check_sprite:
	moveq.l	#.not.%10010,d0
	or.b	CRTC_RESOLUTION_BYTE,d0	;R20L�B%1xx1x�̂Ƃ�����%11111111
	not.b	d0			;%1xx1x�̂Ƃ�����%00000000
	do
		break	ne			;%1xx1x�ł͂Ȃ��B�g�p�ł���
		move.b	extended_1xx1x(pc),d0	;%1xx1x�̂Ƃ��X�v���C�g��ʂ��g�p�ł��邩
		break	mi			;-1=�g�p�ł���
		if	ne			;1=���m�F
		;%1xx1x�̂Ƃ��X�v���C�g��ʂ��g�p�ł��邩�m�F����
			moveq.l	#-1,d0
			move.l	OFFSET_BUS_ERROR.w,-(sp)
			movea.l	sp,a0
			move.l	#@f,OFFSET_BUS_ERROR.w
			nop
			move.w	SPRC_SCROLL,d0		;�X�v���C�g�X�N���[�����W�X�^�����[�h���Ă݂�
			nop
		@@:	movea.l	a0,sp
			move.l	(sp)+,OFFSET_BUS_ERROR.w
			tst.w	d0			;�o�X�G���[������������X���W�����̂Ƃ�mi�A�����Ȃ���pl
			spl.b	extended_1xx1x		;-1=�g�p�ł���,0=�g�p�ł��Ȃ�
			break	pl			;�g�p�ł���
		endif
		moveq.l	#-1,d0			;�X�v���C�g��ʂ��g�p�ł��Ȃ�
		addq.l	#4,sp			;IOCS�R�[�����I������
	while	f
	rts

;----------------------------------------------------------------
;VDISP�̗����������҂�
vdisp_falling_edge:
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne
	rts

;----------------------------------------------------------------
;IOCS $C0 _SP_INIT
;	�X�v���C�g�E�o�b�N�O���E���h�����������܂��B
;	_SP_INIT�Ŋg���@�\��L���ɂ����v���Z�X���I������Ƃ��g���@�\�𖳌��ɂ��܂��B
;<d1.l:'SPRD'$53505244=�g���@�\���g�p����
;<d2.l:�o���N����
;>d0.l:-3=�g���@�\���g�p�ł��Ȃ�,-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C0_SP_INIT:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	push	d1-d7/a1-a4/a6
	lea.l	$00EB8000,a6
EB	reg	-$00EB8000(a6)
;�g���@�\���g�p����^�g�p���Ȃ�
	moveq.l	#-1,d6
	if	<cmp.l #'SPRD',d1>,eq	;�g���@�\���g�p����
		moveq.l	#7,d6
		and.w	d2,d6			;�o���N����
	endif
;<d6.l:-1=�g���@�\���g�p���Ȃ�,0�`7=�o���N����
;�X�v���C�g�̔ԍ��̍ő�l�����߂�
	lea.l	(SPRC_SCROLL)EB,a0	;�X�v���C�g�X�N���[�����W�X�^��X���W
	move.w	#1024-1,d7
	do
		move.w	d7,d0			;�ԍ�
		lsl.w	#3,d0			;8*�ԍ�
		break	<tst.w (a0,d0.w)>,pl	;����ΏI��
		lsr.w	#1,d7			;�Ȃ���Δ����ɂ���
	while	<tst.b d7>,mi		;128-1�ŏI��
;<d7.w:�X�v���C�g�̔ԍ��̍ő�l
;d1-d4/a1-a4���[���ɂ���
	moveq.l	#0,d1
  .irp rn,d2,d3,d4,a1,a2,a3,a4
	move.l	d1,rn
  .endm
;�X�v���C�g�R���g���[�����W�X�^���[���N���A����
	move.w	d1,(SPRC_CONTROL)EB
;�o�b�N�O���E���h�X�N���[�����W�X�^���[���N���A����
	movem.l	d1-d2,(SPRC_BG_0_X)EB
;�X�v���C�g�X�N���[�����W�X�^���[���N���A����
	lea.l	(SPRC_SCROLL)EB,a0
	move.w	d7,d0			;�X�v���C�g�̔ԍ��̍ő�l�B127,255,511,1023
	lsr.w	#5-3,d0			;8*���Ԃ��܂ޖ���/32-1�B31,63,127,255
	moveq.l	#8*256/32-1,d5
	if	<cmp.w d5,d0>,hi	;256����葽���Ƃ�
		for	d5
			movem.l	d1-d4/a1-a4,(a0)	;256���N���A����
			lea.l	32(a0),a0
		next
		lea.l	8*8(a0),a0		;8����΂�
		sub.w	#8*(256+8)/32,d0
	endif
	for	d0
		movem.l	d1-d4/a1-a4,(a0)
		lea.l	32(a0),a0
	next
;�p�^�[���ƃe�L�X�g�G���A���[���N���A����
	move.w	(SPRC_BANK_NUMBER)EB,d0
	if	mi			;�o���N�Ȃ�
	;�p�^�[���ƃe�L�X�g�G���A���[���N���A����
		lea.l	(SPRC_PATTERN)EB,a0
		move.w	#128*256/32-1,d0
		for	d0
			movem.l	d1-d4/a1-a4,(a0)
			lea.l	32(a0),a0
		next
	else				;�o���N����
		lsr.w	#1,d0
		if	cs			;�e�L�X�g�G���A�ړ�����
		;�e�L�X�g�G���A���[���N���A����
			lea.l	(SPRC_BANK_TEXT_0)EB,a0
			move.w	#2*64*64*2/32-1,d0
			for	d0
				movem.l	d1-d4/a1-a4,(a0)
				lea.l	32(a0),a0
			next
		endif
	;�p�^�[�����[���N���A����
		moveq.l	#15,d5			;�o���N�ԍ��B15�`0�B�o���N0���I�����ꂽ��ԂŏI������
		for	d5
			move.b	d5,(SPRC_BANK_NUMBER)EB	;�o���N�ԍ�
			lea.l	(SPRC_PATTERN)EB,a0
			move.w	#128*256/32-1,d0
			for	d0
				movem.l	d1-d4/a1-a4,(a0)
				lea.l	32(a0),a0
			next
		next
	endif
;�X�v���C�g�p���b�g������������
	lea.l	VICON_TSPALET+2*16,a0	;�p���b�g�u���b�N1�`15
	movem.l	100f(pc),d1-d4/a1-a4	;�J���[�R�[�h�̏����l
	bsr	vdisp_falling_edge	;VDISP�̗����������҂�
	moveq.l	#15-1,d0
	for	d0
		movem.l	d1-d4/a1-a4,(a0)
		lea.l	32(a0),a0
	next
;�g���@�\���g�p����^�g�p���Ȃ�
	if	<tst.l d6>,mi		;�g���@�\���g�p���Ȃ�
		if	<tst.w (SPRC_BANK_NUMBER)EB>,pl	;�o���N�ԍ����W�X�^������
			clr.l	(SPRC_BANK_CONTROL)EB	;�o���N���䃌�W�X�^�ƃo���N�ԍ����W�X�^���[���N���A����
		endif
		move.l	#SPRC_TEXT_0,text_area	;�ړ��O�̃e�L�X�g�G���A
		move.w	#127,sprite_max		;�X�v���C�g�̔ԍ��̍ő�l
		sf.b	bank_available		;�o���N�Ȃ�
	elif	<tst.w (SPRC_BANK_NUMBER)EB>,mi	;�o���N�ԍ����W�X�^���Ȃ�
		moveq.l	#-3,d0			;�g���@�\���g�p�ł��Ȃ�
	else				;�g���@�\���g�p����
	;��n���̏���
		move.b	cleanup_flag(pc),d0
		if	ne			;��n������
			movea.l	DOS_PROCESS_HANDLE.w,a0	;�v���Z�X�n���h��
			movea.l	(a0),a0			;���s���̃v���Z�X�̃������Ǘ��|�C���^
			lea.l	original_exitvc(pc),a1	;�ύX�O��_EXITVC�̃n���h��
			lea.l	original_sr(pc),a2	;�ύX�O��sr�̃n���h��
			lea.l	exitvc_routine(pc),a3	;�ύX���_EXITVC
			lea.l	OFFSET_DOS+4*(_EXITVC&$FF).w,a4	;_EXITVC�̃n���h��
			if	<tst.l (a1)>,eq		;������o�^���Ă��Ȃ�
				move.l	(a4),(a1)		;_EXITVC��ۑ�����
				move.l	a3,(a4)			;_EXITVC��ύX����
				move.l	a3,MM_EXITVC(a0)	;���s���̃v���Z�X��_EXITVC��ύX����
				move.w	MM_SR(a0),(a2)		;���s���̃v���Z�X�̐e�v���Z�X��sr��ۑ�����
				ori.w	#$2000,MM_SR(a0)	;���s���̃v���Z�X�̐e�v���Z�X��sr��ύX����
			endif
		endif
	;�g���@�\��L���ɂ���
		move.w	d6,(SPRC_BANK_CONTROL)EB	;�o���N����
		lea.l	(SPRC_TEXT_0)EB,a0	;�ړ��O�̃e�L�X�g�G���A
		if	<btst.l #0,d6>,ne
			lea.l	(SPRC_BANK_TEXT_0)EB,a0	;�ړ���̃e�L�X�g�G���A
		endif
		move.l	a0,text_area
		move.w	d7,sprite_max		;�X�v���C�g�̔ԍ��̍ő�l
		st.b	bank_available		;�o���N����
		moveq.l	#0,d0			;����I��
	endif
	pop
	rts

;�J���[�R�[�h�̏����l
100:	dcrgb	0,0,0			;0=��
	dcrgb	10,10,10		;1=�Â��D�F
	dcrgb	0,0,16			;2=�Â���
	dcrgb	0,0,31			;3=��
	dcrgb	16,0,0			;4=�Â���
	dcrgb	31,0,0			;5=��
	dcrgb	16,0,16			;6=�Â���
	dcrgb	31,0,31			;7=��
	dcrgb	0,16,0			;8=�Â���
	dcrgb	0,31,0			;9=��
	dcrgb	0,16,16			;10=�Â����F
	dcrgb	0,31,31			;11=���F
	dcrgb	16,16,0			;12=�Â����F
	dcrgb	31,31,0			;13=���F
	dcrgb	21,21,21		;14=���邢�D�F
	dcrgb	31,31,31		;15=��

;----------------------------------------------------------------
;IOCS $C1 _SP_ON
;	�X�v���C�g��ʂ�\�����܂��B
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C1_SP_ON:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	ori.w	#VICON_SPON_MASK,VICON_VISIBLE
	ori.w	#SPRC_SPRITE_ON,SPRC_CONTROL
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $C2 _SP_OFF
;	�X�v���C�g��ʂ�\�����܂���B
;>d0.l:0=����I��
iocs_C2_SP_OFF:
	andi.w	#.notw.VICON_SPON_MASK,VICON_VISIBLE
	andi.w	#.notw.SPRC_SPRITE_ON,SPRC_CONTROL
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $C3 _SP_CGCLR
;	�p�^�[�����[���N���A���܂��B
;<d1.w:�p�^�[���ԍ�
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C3_SP_CGCLR:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	push	d1
	lea.l	SPRC_PATTERN,a0
	move.b	bank_available(pc),d0
	if	ne			;�o���N����
		move.w	d1,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;�o���N�ԍ�
	endif
	and.w	#$00FF,d1		;�o���N���p�^�[���ԍ�
	lsl.w	#7,d1
	adda.w	d1,a0
	moveq.l	#0,d0
	moveq.l	#128/4-1,d1
	for	d1
		move.l	d0,(a0)+
	next
;	moveq.l	#0,d0			;����I��
	pop
	rts

;----------------------------------------------------------------
;IOCS $C4 _SP_DEFCG
;	�p�^�[����ݒ肵�܂��B
;	�p�^�[���𔽓]����@�\���ǉ�����Ă��܂��B
;<d1.w:�p�^�[���ԍ�
;<d2.w[15]:�㉺���]
;<d2.w[14]:���E���]
;<d2.b:�T�C�Y�B0=8x8,1=16x16
;<a1.l:�o�b�t�@�̃A�h���X�B����
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C4_SP_DEFCG:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	push	d1-d2/a1
	lea.l	SPRC_PATTERN,a0
	do
		if	<tst.b d2>,eq		;8x8
			move.b	bank_available(pc),d0
			if	ne			;�o���N����
				move.w	d1,d0
				lsr.w	#2,d0
				move.w	d0,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;�o���N�ԍ�
			endif
			and.w	#$03FF,d1		;�o���N��8x8�p�^�[���ԍ�
			lsl.w	#5,d1
			adda.w	d1,a0
			add.w	d2,d2
			if	cc			;�㉺���]���Ȃ�
				if	pl			;���E���]���Ȃ�
					moveq.l	#8-1,d2
					for	d2
						move.l	(a1)+,(a0)+		;�と��
					next
					break
				else				;���E���]����
					moveq.l	#8-1,d2
					for	d2
						move.l	(a1)+,d0		;�と��
						bsr	hexrev
						move.l	d0,(a0)+		;�と��
					next
					break
				endif
			else				;�㉺���]����
				lea.l	32(a1),a1		;�と��
				if	pl			;���E���]���Ȃ�
					moveq.l	#8-1,d2
					for	d2
						move.l	-(a1),(a0)+		;������^�と��
					next
					break
				else				;���E���]����
					moveq.l	#8-1,d2
					for	d2
						move.l	-(a1),d0		;������
						bsr	hexrev
						move.l	d0,(a0)+		;�と��
					next
					break
				endif
			endif
		else				;16x16
			move.b	bank_available(pc),d0
			if	ne			;�o���N����
				move.w	d1,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;�o���N�ԍ�
			endif
			and.w	#$00FF,d1		;�o���N��16x16�p�^�[���ԍ�
			lsl.w	#7,d1
			adda.w	d1,a0
			add.w	d2,d2
			if	cc			;�㉺���]���Ȃ�
				if	pl			;���E���]���Ȃ�
					moveq.l	#32-1,d2
					for	d2
						move.l	(a1)+,(a0)+		;���と����=�E�と�E��
					next
					break
				else				;���E���]����
					lea.l	64(a1),a1		;���と�E��
					moveq.l	#16-1,d2
					for	d2
						move.l	(a1)+,d0		;�E�と�E��
						bsr	hexrev
						move.l	d0,(a0)+		;���と����=�E��
					next
					lea.l	-128(a1),a1		;�E��������
					moveq.l	#16-1,d2
					for	d2
						move.l	(a1)+,d0		;���と����
						bsr	hexrev
						move.l	d0,(a0)+		;����=�E�と�E��
					next
					break
				endif
			else				;�㉺���]����
				if	pl			;���E���]���Ȃ�
					lea.l	64(a1),a1		;���と����
					moveq.l	#16-1,d2
					for	d2
						move.l	-(a1),(a0)+		;����������^���と����=�E��
					next
					lea.l	128(a1),a1		;���と�E��
					moveq.l	#16-1,d2
					for	d2
						move.l	-(a1),(a0)+		;�E�����E��^����=�E�と�E��
					next
					break
				else				;���E���]����
					lea.l	128(a1),a1		;���と�E��
					moveq.l	#32-1,d2
					for	d2
						move.l	-(a1),d0		;�E�����E��=����������
						bsr	hexrev
						move.l	d0,(a0)+		;���と����=�E�と�E��
					next
				;	break
				endif
			endif
		endif
	while	f
	moveq.l	#0,d0			;����I��
	pop
	rts

;���E���]
;<d0.l:�p�^�[��
;>d0.l:���E���]�����p�^�[��
;?d1
hexrev:
					;d0=ABCDEFGH
	move.l	d0,d1			;d1=ABCDEFGH
	and.l	#$00FF00FF,d1		;d1=00CD00GH
	eor.l	d1,d0			;d0=AB00EF00
	swap.w	d1			;d1=00GH00CD
	or.l	d1,d0			;d0=ABGHEFCD
	move.l	d0,d1			;d1=ABGHEFCD
	and.l	#$0F0F0F0F,d1		;d1=0B0H0F0D
	eor.l	d1,d0			;d0=A0G0E0C0
	rol.l	#8,d1			;d1=0H0F0D0B
	or.l	d1,d0			;d0=AHGFEDCB
	rol.l	#4,d0			;d0=HGFEDCBA
	rts

;----------------------------------------------------------------
;IOCS $C5 _SP_GTPCG
;	�p�^�[�����擾���܂��B
;<d1.w:�p�^�[���ԍ�
;<d2.b:�T�C�Y�B0=8x8,1=16x16
;<a1.l:�o�b�t�@�̃A�h���X�B����
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C5_SP_GTPCG:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	push	d1-d2/a1
	lea.l	SPRC_PATTERN,a0
	if	<tst.b d2>,eq		;8x8
		move.b	bank_available(pc),d0
		if	ne			;�o���N����
			move.w	d1,d0
			lsr.w	#2,d0
			move.w	d0,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;�o���N�ԍ�
		endif
		and.w	#$03FF,d1		;�o���N��8x8�p�^�[���ԍ�
		lsl.w	#5,d1
		moveq.l	#8-1,d2
	else				;16x16
		move.b	bank_available(pc),d0
		if	ne			;�o���N����
			move.w	d1,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;�o���N�ԍ�
		endif
		and.w	#$00FF,d1		;�o���N��16x16�p�^�[���ԍ�
		lsl.w	#7,d1
		moveq.l	#32-1,d2
	endif
	adda.w	d1,a0
	for	d2
		move.l	(a0)+,(a1)+
	next
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS $C6 _SP_REGST
;	�X�v���C�g�X�N���[�����W�X�^��ݒ肵�܂��B
;	�����r�b�g���N���A���܂��B
;<d1.l[31]:1=VDISP�̗����������҂��Ȃ�
;<d1.w:�X�v���C�g�ԍ�(�A��)
;<d2.l[31]:1=X���W��ݒ肵�Ȃ�
;<d2.w:X���W
;<d3.l[31]:1=Y���W��ݒ肵�Ȃ�
;<d3.w:Y���W
;<d4.l[31]:1=�L�����N�^��ݒ肵�Ȃ�
;<d4.w:�L�����N�^
;<d5.l[31]:1=�v���C�I���e�B��ݒ肵�Ȃ�
;<d5.w:�v���C�I���e�B
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C6_SP_REGST:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	move.w	d1,d0
	and.w	sprite_max(pc),d0	;0�`1015/1016�`1023
	do
		if	<cmp.w #256,d0>,hs	;256�`1015/1016�`1023
			addq.w	#8,d0			;264�`1023/1024�`1031
			break	<cmp.w sprite_max(pc),d0>,hi	;1024�`1031
		endif
		lea.l	SPRC_SCROLL,a0
		lsl.w	#3,d0
		adda.w	d0,a0
		if	<tst.l d1>,pl
			bsr	vdisp_falling_edge	;VDISP�̗����������҂�
		endif
		if	<tst.l d2>,pl
			move.w	d2,(a0)			;X���W
		endif
		if	<tst.l d3>,pl
			move.w	d3,2(a0)		;Y���W
		endif
		if	<tst.l d4>,pl
			move.w	d4,4(a0)		;�L�����N�^
		endif
		if	<tst.l d5>,pl
			moveq.l	#.not.4,d0		;�����r�b�g���N���A����
			and.w	d5,d0
			move.w	d0,6(a0)		;�v���C�I���e�B
		endif
	while	f
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $C7 _SP_REGGT
;	�X�v���C�g�X�N���[�����W�X�^���擾���܂��B
;<d1.w:�X�v���C�g�ԍ�(�A��)
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;>d2.l:X���W
;>d3.l:Y���W
;>d4.l:�L�����N�^
;>d5.l:�v���C�I���e�B
;?a0
iocs_C7_SP_REGGT:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#0,d5
	move.w	d1,d0
	and.w	sprite_max(pc),d0	;0�`1015/1016�`1023
	do
		if	<cmp.w #256,d0>,hs	;256�`1015/1016�`1023
			addq.w	#8,d0			;264�`1023/1024�`1031
			break	<cmp.w sprite_max(pc),d0>,hi	;1024�`1031
		endif
		lea.l	SPRC_SCROLL,a0
		lsl.w	#3,d0
		adda.w	d0,a0
		move.w	(a0)+,d2		;X���W
		move.w	(a0)+,d3		;Y���W
		move.w	(a0)+,d4		;�L�����N�^
		move.w	(a0)+,d5		;�v���C�I���e�B
	while	f
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $C8 _BGSCRLST
;	�o�b�N�O���E���h�X�N���[�����W�X�^��ݒ肵�܂��B
;<d1.l[31]:1=VDISP�̗����������҂��Ȃ�
;<d1.b:�o�b�N�O���E���h�ԍ�
;<d2.l[31]:1=X���W��ݒ肵�Ȃ�
;<d2.w:X���W
;<d3.l[31]:1=Y���W��ݒ肵�Ȃ�
;<d3.w:Y���W
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_C8_BGSCRLST:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	lea.l	SPRC_BG_0_X,a0
	if	<tst.b d1>,ne
		addq.l	#SPRC_BG_1_X-SPRC_BG_0_X,a0
	endif
	if	<tst.l d1>,pl
		bsr	vdisp_falling_edge	;VDISP�̗����������҂�
	endif
	if	<tst.l d2>,pl
		move.w	d2,(a0)			;X���W
	endif
	if	<tst.l d3>,pl
		move.w	d3,2(a0)		;Y���W
	endif
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $C9 _BGSCRLGT
;	�o�b�N�O���E���h�X�N���[�����W�X�^���擾���܂��B
;<d1.b:�o�b�N�O���E���h�ԍ�
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;>d2.l:X���W
;>d3.l:Y���W
;?a0
iocs_C9_BGSCRLGT:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	lea.l	SPRC_BG_0_X,a0
	if	<tst.b d1>,ne
		addq.l	#SPRC_BG_1_X-SPRC_BG_0_X,a0
	endif
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.w	(a0)+,d2		;X���W
	move.w	(a0)+,d3		;Y���W
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $CA _BGCTRLST
;	�o�b�N�O���E���h���䃌�W�X�^��ݒ肵�܂��B
;<d1.b:�o�b�N�O���E���h�ԍ�
;<d2.l[31]:1=�e�L�X�g�G���A�ԍ���ݒ肵�Ȃ�
;<d2.b:�e�L�X�g�G���A�ԍ�
;<d3.l[31]:1=�\���̗L����ݒ肵�Ȃ�
;<d3.b:�\���̗L��
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_CA_BGCTRLST:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	move.w	SPRC_CONTROL,d0
	if	<tst.b d1>,eq		;�o�b�N�O���E���h0
		if	<tst.l d2>,pl		;�e�L�X�g�G���A�ԍ���ݒ肷��
			and.w	#.notw.%000_110,d0
			if	<tst.b d2>,ne		;�e�L�X�g�G���A1
				addq.w	#%000_010,d0
			endif
		endif
		if	<tst.l d3>,pl		;�\���̗L����ݒ肷��
			and.w	#.notw.%000_001,d0
			if	<tst.b d3>,ne		;�\������
				addq.w	#%000_001,d0
			endif
		endif
	else				;�o�b�N�O���E���h1
		if	<tst.l d2>,pl		;�e�L�X�g�G���A�ԍ���ݒ肷��
			and.w	#.notw.%110_000,d0
			if	<tst.b d2>,ne		;�e�L�X�g�G���A1
				add.w	#%010_000,d0
			endif
		endif
		if	<tst.l d3>,pl		;�\���̗L����ݒ肷��
			and.w	#.notw.%001_000,d0
			if	<tst.b d3>,ne		;�\������
				addq.w	#%001_000,d0
			endif
		endif
	endif
	move.w	d0,SPRC_CONTROL
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $CB _BGCTRLGT
;	�o�b�N�O���E���h���䃌�W�X�^���擾���܂�
;<d1.b:�o�b�N�O���E���h�ԍ�
;>d0.l:-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0�`7=�e�L�X�g�G���A�ԍ�<<1|�\���̗L��
;?a0
iocs_CB_BGCTRLGT:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	moveq.l	#0,d0
	move.w	SPRC_CONTROL,d0
	if	<tst.b d1>,ne
		lsr.w	#3,d0
	endif
	and.w	#%111,d0
	rts

;----------------------------------------------------------------
;IOCS $CC _BGTEXTCL
;	�o�b�N�O���E���h�e�L�X�g���L�����N�^�Ŗ��ߐs�����܂��B
;	�^���O���t�B�b�N��ʂ����@�\���ǉ�����Ă��܂��B
;<d1.w[15�`8]:$00=�L�����N�^�Ŗ��ߐs����,$10=�^���O���t�B�b�N��ʂ����
;<d1.b:�e�L�X�g�G���A�ԍ�
;<d2.w:�L�����N�^�^�p���b�g�u���b�N
;>d0.l:-3=�g���@�\���g�p�ł��Ȃ�,-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_CC_BGTEXTCL:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	if	<cmp.w #$0FFF,d1>,ls	;�L�����N�^����������
		push	d1-d4/a1-a4
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		move.w	d2,d0
		swap.w	d2
		move.w	d0,d2
	  .irp rn,d1,d3,d4,a1,a2,a3,a4
		move.l	d2,rn
	  .endm
		move.w	#2*64*64/32-1,d0
		for	d0
			movem.l	d1-d4/a1-a4,(a0)
			lea.l	32(a0),a0
		next
		pop
	else				;�^���O���t�B�b�N��ʂ����
		move.b	bank_available(pc),d0
		if	eq			;�o���N�Ȃ�
			moveq.l	#-3,d0			;�g���@�\���g�p�ł��Ȃ�
			rts
		endif
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		moveq.l	#$0F,d0
		and.w	d2,d0			;�p���b�g�u���b�N
		lsl.w	#8,d0			;�p�^�[���ԍ����4bit<<12|�p���b�g�u���b�N<<8|�p�^�[���ԍ�����8bit
		do
			do
			  .rept 8
				move.w	d0,(a0)+
				addq.b	#1,d0
			  .endm
			while	cc
			add.w	#1<<12,d0
		while	cc
	endif
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $CD _BGTEXTST
;	�o�b�N�O���E���h�e�L�X�g�ɃL�����N�^���������݂܂��B
;	�^���O���t�B�b�N��ʂɏ������ދ@�\���ǉ�����Ă��܂��B
;<d1.w[15�`8]:$00=�L�����N�^����������,$10=�^���O���t�B�b�N��ʂ�1�h�b�g��������
;<d1.b:�e�L�X�g�G���A�ԍ�
;<d2.w:X���W
;<d3.w:Y���W
;<d4.w:�L�����N�^�^�p���b�g�R�[�h
;>d0.l:-3=�g���@�\���g�p�ł��Ȃ�,-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0=����I��
;?a0
iocs_CD_BGTEXTST:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	if	<cmp.w #$0FFF,d1>,ls	;�L�����N�^����������
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		moveq.l	#63,d0			;00111111
		and.b	d3,d0			;00YYYYYY
		move.b	d0,-(sp)		;00YYYYYY
		move.w	(sp)+,d0		;00YYYYYY........
		move.b	d2,d0			;00YYYYYY..XXXXXX
		add.b	d0,d0			;00YYYYYY.XXXXXX0
		add.b	d0,d0			;00YYYYYYXXXXXX00
		lsr.w	#1,d0			;000YYYYYYXXXXXX0
		move.w	d4,(a0,d0.w)
	else				;�^���O���t�B�b�N��ʂ�1�h�b�g��������
		move.b	bank_available(pc),d0
		if	eq			;�o���N�Ȃ�
			moveq.l	#-3,d0			;�g���@�\���g�p�ł��Ȃ�
			rts
		endif
		push	d1-d3
		lea.l	SPRC_PATTERN,a0
		moveq.l	#%00011,d1
		and.w	SPRC_RESOLUTION-SPRC_PATTERN(a0),d1	;�����T�C�Y
		if	eq			;8x8
			ifand	<cmp.w #511,d2>,ls,<cmp.w #511,d3>,ls	;�͈͓�
			;512x512�h�b�g�̉�ʂ�64x64��8x8�h�b�g(32�o�C�g)�̃p�^�[���ɕ�������Ă���
			;��ʍ��W(%LLLLLLTXX,%BBHHHHYYY)
			;8x8�p�^�[�����W(%LLLLLL,%BBHHHH) 8x8�p�^�[�������W(%TXX,%YYY)
			;8x8�p�^�[���ԍ�%BBHHHHLLLLLL �o���N�ԍ�%BB �o���N��8x8�p�^�[���ԍ�%HHHHLLLLLL
			;���[�h�A�h���X$00EB8000+%HHHHLLLLLLYYYT0 ���[�h���r�b�g�ԍ�%XX00^%1100
				moveq.l	#%111,d0		;d2.w=%LLLLLLTXX
				moveq.l	#%111,d1		;d3.w=%BBHHHHYYY
				and.w	d2,d0			;d0.l=%TXX
				and.w	d3,d1			;d1.l=%YYY
				lsr.w	#3,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBHHHH000
				add.w	d3,d3			;d3.w=%BBHHHH0000
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BB �o���N�ԍ�
				and.w	#$00FF,d3		;d3.w=%HHHH0000
				add.w	d3,d3			;d3.w=%HHHH00000
				add.w	d3,d3			;d3.w=%HHHH000000
				or.w	d3,d2			;d2.w=%HHHHLLLLLL �o���N��8x8�p�^�[���ԍ�
				lsl.w	#3,d2			;d2.w=%HHHHLLLLLL000,x=0
				or.w	d2,d1			;d1.w=%HHHHLLLLLLYYY
				roxr.b	#3,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT
				add.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHHHLLLLLLYYYT0 ���[�h�A�h���X
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ���[�h���r�b�g�ԍ�
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP �p���b�g�R�[�h
				move.w	(a0),d3			;���[�h��ǂݏo��
				ror.w	d0,d3			;�ړI�̈ʒu������4bit�ֈړ�����
				and.w	#$FFF0,d3		;����4bit������
				or.w	d1,d3			;����4bit�Ƀp���b�g�R�[�h������
				rol.w	d0,d3			;���̈ʒu�ɖ߂�
				move.w	d3,(a0)			;���[�h�������߂�
			endif
		else				;16x16
			ifand	<cmp.w #1023,d2>,ls,<cmp.w #1023,d3>,ls	;�͈͓�
			;1024x1024�h�b�g�̉�ʂ�64x64��16x16�h�b�g(128�o�C�g)�̃p�^�[���ɕ�������Ă���
			;��ʍ��W(%LLLLLLSTXX,%BBBBHHYYYY)
			;�p�^�[�����W(%LLLLLL,%BBBBHH) �p�^�[�������W(%STXX,%YYYY)
			;�p�^�[���ԍ�%BBBBHHLLLLLL �o���N�ԍ�%BBBB �o���N���p�^�[���ԍ�%HHLLLLLL
			;���[�h�A�h���X$00EB8000+%HHLLLLLLSYYYYT0 ���[�h���r�b�g�ԍ�%XX00^%1100
				moveq.l	#%1111,d0		;d2.w=%LLLLLLSTXX
				moveq.l	#%1111,d1		;d3.w=%BBBBHHYYYY
				and.w	d2,d0			;d0.l=%STXX
				and.w	d3,d1			;d1.l=%YYYY
				lsr.w	#4,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBBBHH0000
				add.w	d3,d3			;d3.w=%BBBBHH00000
				add.w	d3,d3			;d3.w=%BBBBHH000000,x=0
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BBBB �o���N�ԍ�
				and.w	#$00FF,d3		;d3.w=%HH000000
				or.w	d3,d2			;d2.w=%HHLLLLLL �o���N���p�^�[���ԍ�
				roxr.b	#4,d0			;d0.b=%TXX00000,x=S
				addx.w	d2,d2			;d2.w=%HHLLLLLLS
				lsl.w	#4,d2			;d2.w=%HHLLLLLLS0000
				or.w	d2,d1			;d1.w=%HHLLLLLLSYYYY
				add.b	d0,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT
				add.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHLLLLLLSYYYYT0 ���[�h�A�h���X
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ���[�h���r�b�g�ԍ�
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP �p���b�g�R�[�h
				move.w	(a0),d3			;���[�h��ǂݏo��
				ror.w	d0,d3			;�ړI�̈ʒu������4bit�ֈړ�����
				and.w	#$FFF0,d3		;����4bit������
				or.w	d1,d3			;����4bit�Ƀp���b�g�R�[�h������
				rol.w	d0,d3			;���̈ʒu�ɖ߂�
				move.w	d3,(a0)			;���[�h�������߂�
			endif
		endif
		pop
	endif
	moveq.l	#0,d0			;����I��
	rts

;----------------------------------------------------------------
;IOCS $CE _BGTEXTGT
;	�o�b�N�O���E���h�e�L�X�g����L�����N�^��ǂݏo���܂��B
;	�^���O���t�B�b�N��ʂ���ǂݏo���@�\���ǉ�����Ă��܂��B
;<d1.w[15�`8]:$00=�L�����N�^��ǂݏo��,$10=�^���O���t�B�b�N��ʂ���1�h�b�g�ǂݏo��
;<d1.b:�e�L�X�g�G���A�ԍ�
;<d2.w:X���W
;<d3.w:Y���W
;>d0.l:-3=�g���@�\���g�p�ł��Ȃ�,-1=�X�v���C�g��ʂ��g�p�ł��Ȃ�,0�`65535=�L�����N�^�^�p���b�g�R�[�h
;?a0
iocs_CE_BGTEXTGT:
	bsr	check_sprite		;�X�v���C�g��ʂ��g�p�ł��邩�m�F����
	if	<cmp.w #$0FFF,d1>,ls	;�L�����N�^��ǂݏo��
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		moveq.l	#63,d0			;00111111 �����ŏ�ʃ��[�h���N���A����
		and.b	d3,d0			;00YYYYYY
		move.b	d0,-(sp)		;00YYYYYY
		move.w	(sp)+,d0		;00YYYYYY........
		move.b	d2,d0			;00YYYYYY..XXXXXX
		add.b	d0,d0			;00YYYYYY.XXXXXX0
		add.b	d0,d0			;00YYYYYYXXXXXX00
		lsr.w	#1,d0			;000YYYYYYXXXXXX0
		move.w	(a0,d0.w),d0
	else				;�^���O���t�B�b�N��ʂ���1�h�b�g�ǂݏo��
		move.b	bank_available(pc),d0
		if	eq			;�o���N�Ȃ�
			moveq.l	#-3,d0			;�g���@�\���g�p�ł��Ȃ�
			rts
		endif
		push	d1-d3
		lea.l	SPRC_PATTERN,a0
		moveq.l	#0,d0			;�͈͊O
		moveq.l	#%00011,d1
		and.w	SPRC_RESOLUTION-SPRC_PATTERN(a0),d1	;�����T�C�Y
		if	eq			;8x8
			ifand	<cmp.w #511,d2>,ls,<cmp.w #511,d3>,ls	;�͈͓�
			;512x512�h�b�g�̉�ʂ�64x64��8x8�h�b�g(32�o�C�g)�̃p�^�[���ɕ�������Ă���
			;��ʍ��W(%LLLLLLTXX,%BBHHHHYYY)
			;8x8�p�^�[�����W(%LLLLLL,%BBHHHH) 8x8�p�^�[�������W(%TXX,%YYY)
			;8x8�p�^�[���ԍ�%BBHHHHLLLLLL �o���N�ԍ�%BB �o���N��8x8�p�^�[���ԍ�%HHHHLLLLLL
			;���[�h�A�h���X$00EB8000+%HHHHLLLLLLYYYT0 ���[�h���r�b�g�ԍ�%XX00^%1100
				moveq.l	#%111,d0		;d2.w=%LLLLLLTXX
				moveq.l	#%111,d1		;d3.w=%BBHHHHYYY
				and.w	d2,d0			;d0.l=%TXX
				and.w	d3,d1			;d1.l=%YYY
				lsr.w	#3,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBHHHH000
				add.w	d3,d3			;d3.w=%BBHHHH0000
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BB �o���N�ԍ�
				and.w	#$00FF,d3		;d3.w=%HHHH0000
				add.w	d3,d3			;d3.w=%HHHH00000
				add.w	d3,d3			;d3.w=%HHHH000000
				or.w	d3,d2			;d2.w=%HHHHLLLLLL �o���N��8x8�p�^�[���ԍ�
				lsl.w	#3,d2			;d2.w=%HHHHLLLLLL000,x=0
				or.w	d2,d1			;d1.w=%HHHHLLLLLLYYY
				roxr.b	#3,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT
				add.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHHHLLLLLLYYYT0 ���[�h�A�h���X
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ���[�h���r�b�g�ԍ�
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP �p���b�g�R�[�h
				move.w	(a0),d3			;���[�h��ǂݏo��
				ror.w	d0,d3			;�ړI�̈ʒu������4bit�ֈړ�����
				moveq.l	#$0F,d0
				and.w	d3,d0			;����4bit��ǂݏo��
			endif
		else				;16x16
			ifand	<cmp.w #1023,d2>,ls,<cmp.w #1023,d3>,ls	;�͈͓�
			;1024x1024�h�b�g�̉�ʂ�64x64��16x16�h�b�g(128�o�C�g)�̃p�^�[���ɕ�������Ă���
			;��ʍ��W(%LLLLLLSTXX,%BBBBHHYYYY)
			;�p�^�[�����W(%LLLLLL,%BBBBHH) �p�^�[�������W(%STXX,%YYYY)
			;�p�^�[���ԍ�%BBBBHHLLLLLL �o���N�ԍ�%BBBB �o���N���p�^�[���ԍ�%HHLLLLLL
			;���[�h�A�h���X$00EB8000+%HHLLLLLLSYYYYT0 ���[�h���r�b�g�ԍ�%XX00^%1100
				moveq.l	#%1111,d0		;d2.w=%LLLLLLSTXX
				moveq.l	#%1111,d1		;d3.w=%BBBBHHYYYY
				and.w	d2,d0			;d0.l=%STXX
				and.w	d3,d1			;d1.l=%YYYY
				lsr.w	#4,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBBBHH0000
				add.w	d3,d3			;d3.w=%BBBBHH00000
				add.w	d3,d3			;d3.w=%BBBBHH000000,x=0
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BBBB �o���N�ԍ�
				and.w	#$00FF,d3		;d3.w=%HH000000
				or.w	d3,d2			;d2.w=%HHLLLLLL �o���N���p�^�[���ԍ�
				roxr.b	#4,d0			;d0.b=%TXX00000,x=S
				addx.w	d2,d2			;d2.w=%HHLLLLLLS
				lsl.w	#4,d2			;d2.w=%HHLLLLLLS0000
				or.w	d2,d1			;d1.w=%HHLLLLLLSYYYY
				add.b	d0,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT
				add.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHLLLLLLSYYYYT0 ���[�h�A�h���X
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ���[�h���r�b�g�ԍ�
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP �p���b�g�R�[�h
				move.w	(a0),d3			;���[�h��ǂݏo��
				ror.w	d0,d3			;�ړI�̈ʒu������4bit�ֈړ�����
				moveq.l	#$0F,d0
				and.w	d3,d0			;����4bit��ǂݏo��
			endif
		endif
		pop
	endif
	rts

;----------------------------------------------------------------
;IOCS $CF _SPALET
;	�X�v���C�g�p���b�g��ݒ�܂��͎擾���܂��B
;	�p���b�g�u���b�N0�͎w��ł��܂���B
;<d1.l[31]:1=VDISP�̗����������҂��Ȃ�
;<d1.b:�p���b�g�u���b�N<<4|�p���b�g�R�[�h
;<d2.b:�p���b�g�u���b�N(�D��)
;<d3.l[31]:0=�ݒ�,1=�擾
;<d3.w:�J���[�R�[�h
;>d0.l:-2=�p���b�g�u���b�N0���w�肳�ꂽ,0�`65535=�ݒ�O�̃J���[�R�[�h
;?a0
iocs_CF_SPALET:
	move.b	d2,-(sp)
	moveq.l	#$0F,d0			;�����ŏ�ʃ��[�h���N���A����
	and.b	d1,d0			;0<<4|�p���b�g�R�[�h
	lsl.b	#4,d2			;d2�̃p���b�g�u���b�N<<4|0
	if	ne			;d2�Ƀp���b�g�u���b�N������
		or.b	d2,d0			;d2�̃p���b�g�u���b�N<<4|�p���b�g�R�[�h
	else
		goto	<cmp.b d1,d0>,eq,20f	;d2��d1�̂ǂ���ɂ��p���b�g�u���b�N���Ȃ�
		move.b	d1,d0		;d1�̃p���b�g�u���b�N<<4|�p���b�g�R�[�h
	endif
	lea.l	VICON_TSPALET,a0
	add.w	d0,d0
	adda.w	d0,a0
	if	<tst.l d1>,pl
		bsr	vdisp_falling_edge	;VDISP�̗����������҂�
	endif
	move.w	(a0),d0			;�擾
	if	<tst.l d3>,pl
		move.w	d3,(a0)			;�ݒ�
	endif
10:	move.b	(sp)+,d2
	rts

20:	moveq.l	#-2,d0			;�p���b�g�u���b�N0���w�肳�ꂽ
	goto	10b

;----------------------------------------------------------------
;�f�o�C�X�h���C�o�̖���
device_tail:



dFLAG	reg	d4			;-1=�풓���Ă��Ȃ�,0=�풓�����̓f�o�C�X�h���C�o,1=�풓�����̓������u���b�N
aRESI	reg	a2			;�풓�����̃v���O�����̐擪�B0=�풓���Ă��Ȃ�
aPREV	reg	a3			;�f�o�C�X�h���C�o�Ƃ��ď풓���Ă���Ƃ����O�̃f�o�C�X�h���C�o�B�����Ȃ��΍Ō�̃f�o�C�X�h���C�o
aSELF	reg	a4			;�����̃v���O�����̐擪
r	reg	-program_head(aSELF)

;----------------------------------------------------------------
;�f�o�C�X�R�}���h0 ������
initialize:
	lea.l	program_head(pc),aSELF	;�����̃v���O�����̐擪

;�I�v�V�������m�F����
	movea.l	18(a5),a0		;�����̕��сB��؂��0�A������0,0�B�擪�̓f�o�C�X�t�@�C����
	do
	while	<tst.b (a0)+>,ne	;�f�o�C�X�t�@�C������ǂݔ�΂�
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,option_error	;1�����ڂ�-,/�łȂ�
		move.b	(a0)+,d0		;2������
		goto	eq,option_error		;-,/�̌�ɕ������Ȃ�
		jbsr	tolower
		if	<cmp.b #'d',d0>,eq	;-d ��n���Ȃ�
			goto	<tst.b (enable_flag)r>,ne,option_error	;-d -e�͓����Ɏw��ł��Ȃ�
			st.b	(disable_flag)r
		elif	<cmp.b #'e',d0>,eq	;-e ��n������
			goto	<tst.b (disable_flag)r>,ne,option_error	;-d -e�͓����Ɏw��ł��Ȃ�
			st.b	(enable_flag)r
		elif	<cmp.b #'q',d0>,eq	;-q �Ïl
			st.b	(quiet_flag)r
		else
			goto	option_error
		endif
		tst.b	(a0)+			;�����̋�؂�
		goto	ne,option_error		;�]���ȕ���������
	start
		move.b	(a0)+,d0		;���̈�����1������
	while	ne

;��n���̐ݒ�
	if	<tst.b (disable_flag)r>,ne	;��n���Ȃ�
		sf.b	(cleanup_flag)r
	elif	<tst.b (enable_flag)r>,ne	;��n������
		st.b	(cleanup_flag)r
	endif

;�x�N�^��ύX����
	lea.l	vector_table(pc),a0	;�x�N�^�e�[�u��
	bsr	set_vector		;�x�N�^��ύX����

;���s�ƃ^�C�g����\������
	if	<tst.b (quiet_flag)r>,eq
		jbsr	printcrlf
		lea.l	title_message(pc),a0
		jbsr	print
	endif

;�f�o�C�X�h���C�o�̖�����ݒ肵�Đ���I������
	move.l	#device_tail,14(a5)	;�f�o�C�X�h���C�o�̖���
	moveq.l	#0,d0			;����I������
	rts

;�I�v�V�����G���[
option_error:

;���s�ƃG���[���b�Z�[�W��\������B-q�͖���
	jbsr	printcrlf
	lea.l	program_colon(pc),a0
	jbsr	print
	lea.l	wrong_message(pc),a0
	jbsr	print

;�f�o�C�X�h���C�o��g�ݍ��܂Ȃ�
	move.w	#ABORT|MISCELLANEOUS_ERROR,d0	;���~(A) �G���[���������܂���
	rts

;----------------------------------------------------------------
;���s�J�n
execution_start:
	lea.l	program_head(pc),aSELF	;�����̃v���O�����̐擪

;�I�v�V�������m�F����
	lea.l	1(a2),a0		;�R�}���h���C��
	dostart
		addq.l	#1,a0
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;1�����ڂ�-,/�łȂ�
		move.b	(a0)+,d0		;2������
		goto	eq,usage_exit		;-,/�̌�ɕ������Ȃ�
		jbsr	tolower
		if	<cmp.b #'c',d0>,eq	;-c �풓�m�F
			gotoor	<tst.b (release_flag)r>,ne,<tst.b (version_flag)r>,ne,usage_exit	;-c -r -v�͓����Ɏw��ł��Ȃ�
			st.b	(check_flag)r
		elif	<cmp.b #'d',d0>,eq	;-d ��n���Ȃ�
			gotoor	<tst.b (enable_flag)r>,ne,<tst.b (release_flag)r>,ne,usage_exit	;-d -e -r�͓����Ɏw��ł��Ȃ�
			st.b	(disable_flag)r
		elif	<cmp.b #'e',d0>,eq	;-e ��n������
			gotoor	<tst.b (disable_flag)r>,ne,<tst.b (release_flag)r>,ne,usage_exit	;-d -e -r�͓����Ɏw��ł��Ȃ�
			st.b	(enable_flag)r
		elif	<cmp.b #'q',d0>,eq	;-q �Ïl
			st.b	(quiet_flag)r
		elif	<cmp.b #'r',d0>,eq	;-r �풓����
			gotoor	<tst.b (check_flag)r>,ne,<tst.b (version_flag)r>,ne,usage_exit	;-c -r -v�͓����Ɏw��ł��Ȃ�
			gotoor	<tst.b (disable_flag)r>,ne,<tst.b (enable_flag)r>,ne,usage_exit	;-d -e -r�͓����Ɏw��ł��Ȃ�
			st.b	(release_flag)r
		elif	<cmp.b #'v',d0>,eq	;-v �o�[�W�����m�F
			gotoor	<tst.b (check_flag)r>,ne,<tst.b (release_flag)r>,ne,usage_exit	;-c -r -v�͓����Ɏw��ł��Ȃ�
			st.b	(version_flag)r
		else
			goto	usage_exit
		endif
		move.b	(a0),d0			;���̕���
		break	eq
		jbsr	isspace
		goto	ne,usage_exit		;�]���ȕ���������
	start
		jbsr	nextword		;�󔒂�ǂݔ�΂�
	while	ne

;�X�[�p�[�o�C�U���[�h�ֈڍs����
	supervisormode
;�풓������T��
	do
	;�f�o�C�X�h���C�o��T��
		moveq.l	#0,dFLAG		;�풓�����̓f�o�C�X�h���C�o
		movea.l	DOS_HUMAN_MEMORY.w,a0	;Human68k�̐擪�B�������O�̓X�[�p�[�o�C�U�X�^�b�N�G���A
		move.w	#'NU',d0		;NUL�f�o�C�X�h���C�o=�f�o�C�X�h���C�o�̃��X�g�̐擪��T���B�K������
		lea.l	DH_NAME(a0),a0
		do
			do
			while	<cmp.w (a0)+,d0>,ne
		whileor	<cmpi.l #'L   ',2-2(a0)>,ne,<cmpi.w #'  ',6-2(a0)>,ne,<cmpi.w #$8024,DH_TYPE-(DH_NAME+2)(a0)>,ne
		lea.l	-(DH_NAME+2)(a0),aRESI	;NUL�f�o�C�X�h���C�o
		movem.l	DH_NAME(aSELF),d0-d1	;�����̃f�o�C�X��
		do
			break2and	<cmp.l DH_NAME(aRESI),d0>,eq,<cmp.l DH_NAME+4(aRESI),d1>,eq	;�f�o�C�X��������
			movea.l	aRESI,aPREV		;�f�o�C�X�h���C�o�����O�̃f�o�C�X�h���C�o
			movea.l	DH_NEXT(aRESI),aRESI	;���̃f�o�C�X�h���C�o
		while	<cmpa.w #-1,aRESI>,ne
	;�������u���b�N��T��
		moveq.l	#1,dFLAG		;�풓�����̓������u���b�N
		movea.l	DOS_HUMAN_MEMORY.w,aRESI	;�������u���b�N�̃��X�g�̐擪
		dostart
			if	<cmpi.b #-1,MM_PARENT(aRESI)>,eq	;�풓���Ă���B�����͂����Ŏ�菜��
				lea.l	MM_PROGRAM+DH_NAME+8(aRESI),a0	;�풓�����̃f�o�C�X���̒���
				ifand	<cmpa.l MM_TAIL(aRESI),a0>,ls,<cmp.l -(a0),d1>,eq,<cmp.l -(a0),d0>,eq	;����������Ă��ăf�o�C�X��������
					lea.l	MM_PROGRAM(aRESI),aRESI	;�풓�����̃v���O�����̐擪
					break2
				endif
			endif
		start
			movea.l MM_NEXT(aRESI),aRESI	;���̃������Ǘ��e�[�u��
		while	<cmpa.w #0,aRESI>,ne
		moveq.l	#-1,dFLAG		;�풓���Ă��Ȃ�
	while	f
;<dFLAG.l:-1=�풓���Ă��Ȃ�,0=�풓�����̓f�o�C�X�h���C�o,1=�풓�����̓������u���b�N
;<aRESI.l:�풓�����̃v���O�����̐擪�B0=�풓���Ă��Ȃ�
;<aPREV.l:�f�o�C�X�h���C�o�Ƃ��ď풓���Ă���Ƃ����O�̃f�o�C�X�h���C�o�B�����Ȃ��΍Ō�̃f�o�C�X�h���C�o

;�o�[�W�����m�F
	if	<tst.b (version_flag)r>,ne	;�o�[�W�����m�F
		moveq.l	#1,d1			;�^�C�g��
		moveq.l	#0,d2			;����I��
		goto	message_exit
	endif

;�풓�m�F
	if	<tst.b (check_flag)r>,ne	;�풓�m�F
		moveq.l	#2+4,d1			;�v���O�������ƃ��b�Z�[�W
		moveq.l	#2,d2			;�G���[�I���B�풓���Ă��܂�
		lea.l	already_message(pc),a1	;�풓���Ă��܂�
		if	<tst.l dFLAG>,mi	;�풓���Ă��Ȃ�
			moveq.l	#3,d2			;�G���[�I���B�풓���Ă��܂���
			lea.l	not_yet_message(pc),a1	;�풓���Ă��܂���
		endif
		goto	message_exit
	endif

;��n���̐ݒ�
	if	<tst.b (disable_flag)r>,ne	;��n���Ȃ�
		sf.b	(cleanup_flag)r
	elif	<tst.b (enable_flag)r>,ne	;��n������
		st.b	(cleanup_flag)r
	endif

;����
	if	<tst.b (release_flag)r>,ne	;����

	;�풓���Ă��Ȃ��̂ɉ������悤�Ƃ�����G���[
		if	<tst.l dFLAG>,mi	;�풓���Ă��Ȃ�
			moveq.l	#2+4,d1			;�v���O�������ƃ��b�Z�[�W
			moveq.l	#3,d2			;�G���[�I���B�풓���Ă��܂���
			lea.l	not_yet_message(pc),a1	;�풓���Ă��܂���
			goto	message_exit
		endif

	;�x�N�^���ύX����Ă�����G���[
		lea.l	(vector_table-program_head)(aRESI),a0	;�풓�����̃x�N�^�e�[�u��
		bsr	check_vector		;�x�N�^���m�F����
		if	ne			;�x�N�^���ύX����Ă���
			moveq.l	#2+4,d1			;�v���O�������ƃ��b�Z�[�W
			moveq.l	#4,d2			;�G���[�I���B�x�N�^���ύX����Ă��܂��B�����ł��܂���
			lea.l	vector_message(pc),a1	;�x�N�^���ύX����Ă��܂��B�����ł��܂���
			goto	message_exit
		endif

	;����������
		moveq.l	#0,d1
		bsr	iocs_C0_SP_INIT

	;�x�N�^�𕜌�����
		lea.l	(vector_table-program_head)(aRESI),a0	;�풓�����̃x�N�^�e�[�u��
		bsr	release_vector		;�x�N�^�𕜌�����

	;�f�o�C�X�h���C�o��؂藣���^�������u���b�N���J������
		if	<tst.l dFLAG>,eq	;�풓�����̓f�o�C�X�h���C�o
			move.l	DH_NEXT(aRESI),DH_NEXT(aPREV)	;���O�̃f�o�C�X�h���C�o�̎��̃f�o�C�X�h���C�o�͎��̃f�o�C�X�h���C�o(-1���܂�)
		else				;�풓�����̓������u���b�N
			pea.l	MM_SIZE-MM_PROGRAM(aRESI)	;�풓�����̃������u���b�N�̐擪
			DOS	_MFREE
			addq.l	#4,sp
		endif

	;����I������
		moveq.l	#2+4,d1			;�v���O�������ƃ��b�Z�[�W
		moveq.l	#0,d2			;����I��
		lea.l	released_message(pc),a1	;�������܂���
		goto	message_exit

	endif

;�풓���Ă���̂ɏ풓���悤�Ƃ�����G���[
	if	<tst.l dFLAG>,pl	;�풓���Ă���
	;�ݒ�ύX
		ifor	<tst.b (disable_flag)r>,ne,<tst.b (enable_flag)r>,ne
			move.b	(cleanup_flag)r,cleanup_flag-program_head(aRESI)
			lea.l	disabled_message(pc),a0	;��n���Ȃ�
			if	ne			;��n������
				lea.l	enabled_message(pc),a0	;��n������
			endif
			moveq.l	#2+4,d1			;�v���O�������ƃ��b�Z�[�W
			moveq.l	#0,d2			;����I��
			goto	message_exit
		endif
		moveq.l	#2+4,d1			;�v���O�������ƃ��b�Z�[�W
		moveq.l	#2,d2			;�G���[�I���B�풓���Ă��܂�
		lea.l	already_message(pc),a1	;�풓���Ă��܂�
		goto	message_exit
	endif

;�x�N�^��ύX����
	lea.l	vector_table(pc),a0	;�x�N�^�e�[�u��
	bsr	set_vector		;�x�N�^��ύX����

;�f�o�C�X�h���C�o��ڑ�����
;	move.l	aSELF,(aPREV)		;�Ō�̃f�o�C�X�h���C�o�̎��̃f�o�C�X�h���C�o�������ɂ���

;����������
	moveq.l	#0,d1
	bsr	iocs_C0_SP_INIT

;�풓�I������
	moveq.l	#1+2+4,d1		;�^�C�g���ƃv���O�������ƃ��b�Z�[�W
	moveq.l	#-1,d2			;�풓�I��
	lea.l	resident_message(pc),a1	;�풓���܂���
	goto	message_exit

;���[�U���[�h�֕��A���ďI������
;<d1.l:1=�^�C�g����\������,2=�v���O��������\������,4=���b�Z�[�W��\������
;<d2.w:�I���R�[�h�B-1=�풓�I��,0=����I��,1�`=�G���[�I��
;<a1.l:���b�Z�[�W
message_exit:
;���[�U���[�h�֕��A����
	usermode
	if	<tst.b (quiet_flag)r>,eq
		if	<btst.l #0,d1>,ne	;�^�C�g����\������
			lea.l	title_message(pc),a0
			jbsr	print
		endif
		if	<btst.l #1,d1>,ne	;�v���O��������\������
			lea.l	program_colon(pc),a0
			jbsr	print
		endif
		if	<btst.l #2,d1>,ne	;���b�Z�[�W��\������
			movea.l	a1,a0
			jbsr	print
		endif
	endif
;�I������
	if	<tst.w d2>,mi		;�풓�I��
		clr.w	-(sp)
		move.l	#device_tail-program_head,-(sp)
		DOS	_KEEPPR
	endif
	move.w	d2,-(sp)
	DOS	_EXIT2

;�^�C�g���Ǝg�p�@��\�����ďI������
usage_exit:
;�^�C�g���Ǝg�p�@��\������B-q�͖���
	lea.l	title_message(pc),a0
	jbsr	print
	lea.l	usage_message(pc),a0
	jbsr	print
;�I������
	move.w	#1,-(sp)
	DOS	_EXIT2

;----------------------------------------------------------------
;�x�N�^��ύX����
;	�X�[�p�[�o�C�U���[�h�ŌĂяo������
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
;	�X�[�p�[�o�C�U���[�h�ŌĂяo������
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
;	�X�[�p�[�o�C�U���[�h�ŌĂяo������
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
;������
  .if ENGLISH
title_message:
	.dc.b	ENGLISH_TITLE,' ',VERSION_STRING,13,10,0
program_colon:
	.dc.b	PROGRAMEN_NAME,': ',0
usage_message:
	.dc.b	'  device = ',PROGRAM_NAME,' <option>',13,10
	.dc.b	'    or',13,10
	.dc.b	'  A>',PROGRAM_NAME,' <option>',13,10
	.dc.b	'    -c    Resident check',10
	.dc.b	'    -d    Disable cleanup',10
	.dc.b	'    -e    Enable cleanup',10
	.dc.b	'    -q    Quiet',13,10
	.dc.b	'    -r    Release',13,10
	.dc.b	'    -v    Version check',13,10,0
wrong_message:
	.dc.b	'Wrong option',13,10,0
already_message:
	.dc.b	'Already resident',13,10,0
resident_message:
	.dc.b	'Resident',13,10,0
not_yet_message:
	.dc.b	'Not yet resident',13,10,0
vector_message:
	.dc.b	'Vector has been changed, unable to release',13,10,0
released_message:
	.dc.b	'Released',13,10,0
disabled_message:
	.dc.b	'Cleanup is disabled',13,10,0
enabled_message:
	.dc.b	'Cleanup is enabled',13,10,0
  .else
title_message:
	.dc.b	JAPANESE_TITLE,' ',VERSION_STRING,13,10,0
program_colon:
	.dc.b	PROGRAM_NAME,': ',0
usage_message:
	.dc.b	'  device = ',PROGRAM_NAME,' <�I�v�V����>',13,10
	.dc.b	'    �܂���',13,10
	.dc.b	'  A>',PROGRAM_NAME,' <�I�v�V����>',13,10
	.dc.b	'    -c    �풓�m�F',13,10
	.dc.b	'    -d    ��n���Ȃ�',10
	.dc.b	'    -e    ��n������',10
	.dc.b	'    -q    �Ïl',13,10
	.dc.b	'    -r    �풓����',13,10
	.dc.b	'    -v    �o�[�W�����m�F',13,10,0
wrong_message:
	.dc.b	'�I�v�V�������Ⴂ�܂�',13,10,0
already_message:
	.dc.b	'�풓���Ă��܂�',13,10,0
resident_message:
	.dc.b	'�풓���܂���',13,10,0
not_yet_message:
	.dc.b	'�풓���Ă��܂���',13,10,0
vector_message:
	.dc.b	'�x�N�^���ύX����Ă��܂��B�����ł��܂���',13,10,0
released_message:
	.dc.b	'�������܂���',13,10,0
disabled_message:
	.dc.b	'��n���Ȃ�',13,10,0
enabled_message:
	.dc.b	'��n������',13,10,0
  .endif
	.even

	.data

;----------------------------------------------------------------
;�t���O
check_flag:
	.dc.b	0			;-c �풓�m�F
disable_flag:
	.dc.b	0			;-d ��n���Ȃ�
enable_flag:
	.dc.b	0			;-e ��n������
quiet_flag:
	.dc.b	0			;-q �Ïl
release_flag:
	.dc.b	0			;-r �풓����
version_flag:
	.dc.b	0			;-v �o�[�W�����m�F
	.even



	.text
	.even

;----------------------------------------------------------------
;�󔒕����� \s
;<d0.b:����
;>z:eq=�󔒕���,ne=�󔒕����ł͂Ȃ�(0���܂�)
isspace::
	if	<cmp.b #' ',d0>,ne
		ifand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r
			cmp.b	d0,d0
		endif
	endif
	rts

;----------------------------------------------------------------
;�󔒂�ǂݔ�΂�
;<a0.l:������
;>d0.l:�ŏ��̋󔒈ȊO�̕����܂���0
;>a0.l:�ŏ��̋󔒈ȊO�̕����܂���0�̈ʒu
;>z:ne=�󔒈ȊO�̕���������,eq=�󔒈ȊO�̕������Ȃ�
nextword::
	moveq.l	#0,d0
	do
		move.b	(a0)+,d0		;���̕���
		break	eq			;0�Ȃ�ΏI��
		jbsr	isspace			;�󔒂�
	while	eq			;�󔒂Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	tst.l	d0
	rts

;----------------------------------------------------------------
;�������\������
;<a0.l:������
print::
	push	d0
	jbsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts

;----------------------------------------------------------------
;���s��\������
printcrlf::
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	jbsr	print
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;�������r
;<a0.l:������0
;<a1.l:������1
;>ccr:eq=������0==������1,lo=������0<������1,hi=������1<������0
strcmp::
	push	d0/a0-a1
	do
		move.b	(a0)+,d0
		if	eq
			cmp.b	(a1)+,d0
			break
		endif
		cmp.b	(a1)+,d0
	while	eq
	pop
	rts

;----------------------------------------------------------------
;������̒����𐔂���
;<a0.l:������
;>d0.l:����
strlen::
	move.l	a0,d0			;d0=�擪
	do
	while	<tst.b (a0)+>,ne		;0�̎��̈ʒu�܂Ői��
	subq.l	#1,a0			;�i�݉߂������߂�Ba0=0�̈ʒu
	exg.l	d0,a0			;d0=����,a0=�擪
	sub.l	a0,d0			;d0=����-�擪=����
	rts

;----------------------------------------------------------------
;�������ɂ���
;<d0.b:����
;>d0.b:����
tolower::
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

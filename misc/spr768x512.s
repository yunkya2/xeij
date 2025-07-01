;========================================================================================
;  spr768x512.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;  spr768x512.x
;	XEiJ��256���̃X�v���C�g��4096�̃p�^�[����768x512�ŃX�v���C�g��\�����e�X�g���܂��B
;	�������j���[��256���̃X�v���C�g�`�F�b�N�{�b�N�X��4096�̃p�^�[���`�F�b�N�{�b�N�X��
;	768x512�ŃX�v���C�g��\���`�F�b�N�{�b�N�X��ON�ɂ��ă��Z�b�g���Ă�����s���܂��B
;	�����L�[�������ƏI�����܂��B
;	X68000���@�ł͓����܂���B
;----------------------------------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ
	.include	vicon.equ

;�J�n

;��ʃ��[�h��ύX
	move.w	#-1,screen_mode
	moveq.l	#-1,d1
	IOCS	_CRTMOD
	if	<cmp.w #16,d0>,ne	;CRTMOD 16�łȂ��Ƃ�
		move.w	#3,-(sp)		;�t�@���N�V�����L�[�\���Ȃ�
		move.w	#14,-(sp)
		DOS	_CONCTRL
		move.w	d0,function_mode
		clr.w	-(sp)			;768x512�O���t�B�b�N�Ȃ�
		move.w	#16,-(sp)
		DOS	_CONCTRL
		move.w	d0,screen_mode
		addq.l	#8,sp
	endif

;�X�[�p�[�o�C�U���[�h
	supervisormode

;�X�v���C�g�R���g���[��������
	move.w	#28+4,SPRC_H_BACK_END	;�����o�b�N�|�[�`�I���J�����BR02+4
	move.w	#255,SPRC_H_FRONT_END	;�����t�����g�|�[�`�I���J�����B255�B�E�F�C�g�͏ȗ�
	move.w	#40,SPRC_V_BACK_END	;�����o�b�N�|�[�`�I�����X�^�BR06
	move.w	#%10101,SPRC_RESOLUTION	;�𑜓x�B--------|---|���𑜓x|�����T�C�Y##|�����T�C�Y##
	moveq.l	#0,d0
	move.l	d0,SPRC_BG_0_X		;BG0�X�N���[��X���W,BG0�X�N���[��Y���W
	move.l	d0,SPRC_BG_1_X		;BG1�X�N���[��X���W,BG1�X�N���[��Y���W
	move.w	d0,SPRC_CONTROL		;�R���g���[���B------|�X�v���C�g���ON|---|BG1�e�L�X�g##|BG1�\��ON|BG0�e�L�X�g##|BG0�\��ON

;�p�^�[��4096����`ON
	move.w	#$0005,$00EB0812
	move.w	#$0000,$00EB0814

;�X�v���C�g���N���A
	lea.l	$00EB0000,a0
	moveq.l	#0,d0
	move.w	#256-1,d1
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;�p�^�[�����N���A
	moveq.l	#0,d0
	moveq.l	#0,d2			;�o���N
	do
		move.w	d2,$00EB0814		;�o���N�ԍ�
		lea.l	$00EB8000,a0
		move.w	#32768/8-1,d1
		for	d1
			move.l	d0,(a0)+
			move.l	d0,(a0)+
		next
		add.w	#$0100,d2
	while	<cmp.w #$0F00,d2>,ls

;�X�v���C�g�\��ON
	move.w	#SPRC_SPRITE_ON,SPRC_CONTROL
	ori.w	#VICON_SPON_MASK,VICON_VISIBLE
	move.w	#%00_00_01_10_11_10_01_00,VICON_PRIORITY

;�p���b�g��ݒ肷��
;	�p���b�g�R�[�h$0x�͎g�p���Ȃ��B$x0�͍��B�c���225�F��p����
;	n=0�`224
;	t=n/225
;	H=floor(192*t)
;	S=31
;	V=31	floor(15+8*cos(2*pi*t)+0.5)
	lea.l	VICON_TSPALET+2*$10,a0	;�p���b�g���W�X�^�B$10����
	suba.l	a1,a1			;a1=n
	do
		clr.w	(a0)+			;�p���b�g�R�[�h$x0�͍�
		moveq.l	#15-1,d7		;�p���b�g�R�[�h$x1�`$xF
		for	d7
			move.l	#225,d0
			FPACK	__LTOD			;d0d1=225
			move.l	d0,d2
			move.l	d1,d3			;d2d3=225
			move.l	a1,d0
			FPACK	__LTOD			;d0d1=n
			FPACK	__DDIV			;d0d1=n/225=t
			move.l	d0,d4
			move.l	d1,d5			;d4d5=t
			move.l	d0,d2
			move.l	d1,d3			;d2d3=t
			move.l	#192,d0
			FPACK	__LTOD			;d0d1=192
			FPACK	__DMUL			;d0d1=192*t
			FPACK	__DFLOOR		;H=floor(192*t)
			FPACK	__DTOL
			move.l	d0,d6
			swap.w	d6
			move.w	#31.shl.8,d6		;S=31
  .if 0
			move.b	#31,d6			;V=31
  .else
			move.l	d4,d0
			move.l	d5,d1			;d0d1=t
			FPACK	__NPI			;d0d1=pi*t
			move.l	d0,d2
			move.l	d1,d3			;d2d3=pi*t
			move.l	#2*15,d0
			FPACK	__LTOD			;d0d1=2*15
			FPACK	__DMUL			;d0d1=2*pi*10*t
			FPACK	__COS			;d0d1=cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2d3=cos(2*pi*t)
			moveq.l	#8,d0
			FPACK	__LTOD			;d0d1=8
			FPACK	__DMUL			;d0d1=8*cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2d3=8*cos(2*pi*t)
			moveq.l	#15,d0
			FPACK	__LTOD			;d0d1=15
			FPACK	__DADD			;d0d1=15+8*cos(2*pi*t)
			move.l	#$3FE00000,d2
			moveq.l	#$00000000,d3		;d2d3=0.5
			FPACK	__DADD			;d0d1=15+8*cos(2*pi*t)+0.5
			FPACK	__DFLOOR		;V=floor(15+8*cos(2*pi*t)+0.5)
			FPACK	__DTOL
			move.b	d0,d6
  .endif
			move.l	d6,d1			;d1=H<<16|S<<8|V
			IOCS	_HSVTORGB
			move.w	d0,(a0)+
			addq.l	#1,a1			;n++
		next
	while	<cmpa.l #VICON_TSPALET+2*256,a0>,lo

;�X�v���C�g�p�^�[�����`����
;	�p�^�[���ԍ�0�`4095�Ɋ������`����
;	�p�^�[���ԍ��̉���8�r�b�g��256����225�Ɍ��炵�ăp���b�g�R�[�h�����
	lea.l	conv225(pc),a3
	move.l	#'��',d1
	moveq.l	#8,d2
	IOCS	_FNTADR
	movea.l	d0,a6			;a6=�t�H���g�A�h���X
	moveq.l	#0,d7			;d7=�p�^�[���ԍ�
	do
	;�󔒂�ǂݔ�΂�
		dostart
			lea.l	32(a6),a6
		start
			movea.l	a6,a0
			moveq.l	#0,d0
			moveq.l	#8-1,d6
			for	d6
				or.l	(a0)+,d0
			next
		while	eq
		if	<tst.b d7>,eq		;�p�^�[���ԍ���256�̔{���̂Ƃ�
		;�X�v���C�g��\������
		;	�X�v���C�g�p�^�[�����`����O�ɕ\�����Ē�`���Ă���l�q��������
		;	�X�v���C�g�ԍ��ƃp�^�[���ԍ��͓���
		;	�X�v���C�g�ԍ��̏��4�r�b�g���p���b�g�u���b�N�Ƃ���
			moveq.l	#0,d6			;�X�v���C�g�ԍ�/�p�^�[���ԍ�
			lea.l	$00EB0000,a0		;�X�v���C�g�X�N���[�����W�X�^
			movea.l	#16,a4			;Y���W
			do
				movea.l	#16,a5			;X���W
				do
					move.w	a5,(a0)+		;X���W
					move.w	a4,(a0)+		;Y���W
					moveq.l	#0,d3
					move.b	d6,d3			;�X�v���C�g�ԍ�
					move.b	(a3,d3.l),d3		;�p���b�g�R�[�h
					move.w	d7,d0			;�o���N�ԍ�<<8|?
					move.b	d3,d0			;�o���N�ԍ�<<8|�p���b�g�R�[�h
					lsl.w	#4,d0			;�o���N�ԍ�<<12|�p���b�g�R�[�h<<4
					move.b	d6,d0			;�o���N�ԍ�<<12|�p���b�g�u���b�N<<8|�p�^�[���ԍ�
					move.w	d0,(a0)+
					move.w	#3,(a0)+		;�v���C�I���e�B
					addq.l	#1,d6			;�X�v���C�g�ԍ�
					adda.l	#16,a5			;X���W
				while	<cmpa.l #16+16*16,a5>,lo
				adda.l	#16,a4			;Y���W
			while	<cmpa.l #16+16*16,a4>,lo
		endif
		lea.l	sprbuf,a0
		moveq.l	#0,d3
		move.b	d7,d3
		move.b	(a3,d3.l),d3		;�p���b�g�R�[�h
		and.b	#15,d3			;�p���b�g�R�[�h�̉���4bit
		moveq	#16-1,d4
		for	d4
			move.b	(a6)+,d0	;������
		;	not.b	d0		;���]
			addq.l	#1,a6
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d3,d1
				endif
			next
			move.l	d1,(a0)+
		next
		lea.l	-2*16(a6),a6
		moveq	#16-1,d4
		for	d4
			addq.l	#1,a6
			move.b	(a6)+,d0	;�E����
		;	not.b	d0		;���]
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d3,d1
				endif
			next
			move.l	d1,(a0)+
		next
		move.w	d7,$00EB0814	;�o���N�ԍ�
		moveq.l	#0,d1
		move.b	d7,d1		;�p�^�[���ԍ�
	;	moveq.l	#1,d2		;�p�^�[���T�C�Y
		lea.l	sprbuf,a1	;�p�^�[���f�[�^
	;	IOCS	_SP_DEFCG
		lea.l	$00EB8000,a0
		lsl.w	#7,d1
		adda.l	d1,a0
		moveq.l	#64/2-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
	;
		addq.l	#1,d7
	while	<cmp.l #4096,d7>,lo

;�O�������
;	{x=3sin(t)-sin(3t/2)
;	{y=3cos(t)+cos(3t/2)�@�@(0��t<4��)
;	-4<=x,y<=4
;	https://twitter.com/sukannpi2/status/860126933606047745
;	����55.458Hz�Ȃ̂�1��30�b�Ƃ���Ɛ�������1664���1��
;	dt=4��/1664
;	�X�v���C�g�̊Ԋu��4��/256�ɂ����1���q���邪�e�[�u�������ɂ���
;	6�����x��ɂ��邩

FLIP		equ	15	;�o���N��؂�ւ���Ԋu
GAP		equ	FLIP*2	;�����̊Ԋu
ORBIT_LENGTH	equ	GAP*256	;�O���̈ʒu�̐�
COEFF_N		equ	3	;3*sin(t)��3
COEFF_T		equ	13	;3*t/2��3 �傫������Ɗp�������Đ��
COEFF_S		equ	2	;3*t/2��2
COEFF_P		equ	4	;4*pi��4
RADIUS_X	equ	90	;���a
RADIUS_Y	equ	60	;
CENTER_X	equ	384	;���S
CENTER_Y	equ	256	;
WIDTH		equ	768	;��ʂ̃T�C�Y
HEIGHT		equ	512	;

	lea.l orbit,a0

	move.l	#ORBIT_LENGTH,d0
	FPACK	__LTOD
	move.l	d0,d2		;d2-d3=ORBIT_LENGTH
	move.l	d1,d3
	moveq.l	#COEFF_P,d0
	FPACK	__LTOD
	FPACK	__NPI		;d0-d1=4*pi
	FPACK	__DDIV		;d0-d1=4*pi/ORBIT_LENGTH=dt
	movea.l	d0,a4		;a4-a5=dt
	movea.l	d1,a5

	move.l	a4,d2		;d2-d3=dt
	move.l	a5,d3
	move.l	#COEFF_T,d0
	FPACK	__LTOD		;d0-d1=3
	FPACK	__DMUL		;d0-d1=3*dt
	move.l	d0,d2		;d2-d3=3*dt
	move.l	d1,d3
	move.l	#COEFF_S,d0
	FPACK	__LTOD		;d0-d1=2
	exg.l	d0,d2		;d0-d1=3*dt
	exg.l	d1,d3		;d2-d3=2
	FPACK	__DDIV		;d0-d1=3*dt/2
	movea.l	d0,a2		;a2-a3=3*dt/2
	movea.l	d1,a3

	moveq.l	#0,d6		;d6-d7=0=t
	moveq.l	#0,d7
	moveq.l	#0,d4		;d4-d5=0=3*t/2
	moveq.l	#0,d5

	movea.l	#0,a1		;n=0..1663
	do

		moveq.l	#COEFF_N,d0
		FPACK	__LTOD		;d0-d1=3
		move.l	d0,d2		;d2-d3=3
		move.l	d1,d3
		move.l	d6,d0		;d0-d1=t
		move.l	d7,d1
		FPACK	__SIN		;d0-d1=sin(t)
		FPACK	__DMUL		;d0-d1=3*sin(t)
		move.l	d0,d2		;d2-d3=3*sin(t)
		move.l	d1,d3
		move.l	d4,d0		;d0-d1=3*t/2
		move.l	d5,d1
		FPACK	__SIN		;d0-d1=sin(3*t/2)
		exg.l	d0,d2		;d0-d1=3*sin(t)
		exg.l	d1,d3		;d2-d3=sin(3*t/2)
		FPACK	__DSUB		;d0-d1=3*sin(t)-sin(3*t/2)=x
		move.l	d0,d2		;d2-d3=x
		move.l	d1,d3
		move.l	#RADIUS_X,d0
		FPACK	__LTOD		;d0-d1=60
		FPACK	__DMUL		;d0-d1=60*x
		move.l	d0,d2		;d2-d3=60*x
		move.l	d1,d3
		move.l	#16+CENTER_X-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DADD		;d0-d1=16+256-8+60*x
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8+60*x+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8+60*x+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+WIDTH,d0>,ge
			moveq.l	#0,d0
		endif
		move.w	d0,(a0)+

		moveq.l	#COEFF_N,d0
		FPACK	__LTOD		;d0-d1=3
		move.l	d0,d2		;d2-d3=3
		move.l	d1,d3
		move.l	d6,d0		;d0-d1=t
		move.l	d7,d1
		FPACK	__COS		;d0-d1=cos(t)
		FPACK	__DMUL		;d0-d1=3*cos(t)
		move.l	d0,d2		;d2-d3=3*cos(t)
		move.l	d1,d3
		move.l	d4,d0		;d0-d1=3*t/2
		move.l	d5,d1
		FPACK	__COS		;d0-d1=cos(3*t/2)
		exg.l	d0,d2		;d0-d1=3*cos(t)
		exg.l	d1,d3		;d2-d3=cos(3*t/2)
		FPACK	__DADD		;d0-d1=3*cos(t)+cos(3*t/2)=y

		move.l	d0,d2		;d2-d3=y
		move.l	d1,d3
		move.l	#RADIUS_Y,d0
		FPACK	__LTOD		;d0-d1=60
		FPACK	__DMUL		;d0-d1=60*y
		move.l	d0,d2		;d2-d3=60*y
		move.l	d1,d3
		move.l	#16+CENTER_Y-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DSUB		;d0-d1=16+256-8-60*y
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8-60*y+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8-60*y+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+HEIGHT,d0>,ge
			moveq.l	#0,d0
		endif
		move.w	d0,(a0)+

		move.l	d6,d0		;d0-d1=t
		move.l	d7,d1
		move.l	a4,d2		;d2-d3=dt
		move.l	a5,d3
		FPACK	__DADD		;d0-d1=t+dt
		move.l	d0,d6		;d6-d7=t+dt
		move.l	d1,d7

		move.l	d4,d0		;d0-d1=3*t/2
		move.l	d5,d1
		move.l	a2,d2		;d2-d3=3*dt/2
		move.l	a3,d3
		FPACK	__DADD		;d0-d1=3*(t+dt)/2
		move.l	d0,d4		;d4-d5=3*(t+dt)/2
		move.l	d1,d5

		addq.l	#1,a1
	while	<cmpa.l #ORBIT_LENGTH,a1>,lo

;������
	lea.l	orbit,a4		;a4=�O���f�[�^�̔z��̐擪
	lea.l	4*ORBIT_LENGTH(a4),a5	;a5=�O���f�[�^�̔z��̖���
	lea.l	$00EB0000,a6		;�X�v���C�g0�̃X�v���C�g�X�N���[�����W�X�^
	movea.l	a4,a3			;�X�v���C�g0�̋O���f�[�^�̈ʒu
	moveq.l	#0,d7			;�o���N�ԍ��𑝂₷�X�v���C�g�̉���4bit
	do
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;�����\�����Ԃ�҂�
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;�����A�����Ԃ�҂�

	;�o���N�ԍ��𑝂₷
		moveq.l	#5-1,d1
		for	d1
			addi.w	#$1000,4(a6,d7.w)
			add.w	#8*33,d7
			and.w	#8*(256-1),d7
		next

		movea.l	a3,a1		;�O���f�[�^
		movea.l	a6,a2		;�X�v���C�g�X�N���[�����W�X�^
		move.w	#256-1,d0
		for	d0
			move.l	(a1),(a2)	;�O���f�[�^���X�v���C�g�X�N���[�����W�X�^��
			lea.l	-4*GAP(a1),a1	;�O���f�[�^�̈ʒu��6�߂�
			if	<cmpa.l a4,a1>,lo
				lea.l	4*ORBIT_LENGTH(a1),a1
			endif
			addq.l	#8,a2		;���̃X�v���C�g�̃X�v���C�g�X�N���[�����W�X�^
		next

		addq.l	#4,a3		;�X�v���C�g0�̋O���f�[�^�̈ʒu��1�i�߂�
		if	<cmpa.l a5,a3>,hs
			lea.l	-4*ORBIT_LENGTH(a3),a3
		endif

		bsr	inkey0
	while	eq

;�X�v���C�g�\��OFF
	move.w	#$0000,SPRC_CONTROL	;�R���g���[���B------|�X�v���C�g���ON|---|BG1�e�L�X�g##|BG1�\��ON|BG0�e�L�X�g##|BG0�\��ON
	andi.w	#.notw.VICON_SPON_MASK,VICON_VISIBLE

;�p�^�[��4096����`OFF
	move.w	#$0000,$00EB0812
	move.w	#$0000,$00EB0814

;���[�U���[�h
	usermode

;��ʃ��[�h�𕜌�
	if	<tst.w screen_mode>,pl
		move.w	screen_mode,-(sp)
		move.w	#16,-(sp)
		DOS	_CONCTRL
		move.w	function_mode,-(sp)
		move.w	#14,-(sp)
		DOS	_CONCTRL
		addq.l	#8,sp
	endif

;�I��
	DOS	_EXIT

;�L�[����(�҂��Ȃ�)
;>d0.l:�����R�[�h�B0=�Ȃ�
inkey0:
	do
		IOCS	_B_KEYSNS
		break	<tst.l d0>,eq
		IOCS	_B_KEYINP
		and.l	#$FF,d0
	while	eq
	rts

;�L�[����(�҂�)
;>d0.l:�����R�[�h
inkey1:
	do
		do
			IOCS	_B_KEYSNS
		while	<tst.l d0>,eq
		IOCS	_B_KEYINP
		and.l	#$FF,d0
	while	eq
	rts

conv225:
n = 0
	.rept	256
l = (n*225+128)>>8
h = l/15
l = l-(15*h)
		.dc.b	((1+h)<<4)|(1+l)
n = n+1
	.endm

	.bss
	.even
sprbuf:
	.ds.l	2*16
orbit:
	.ds.w	2*ORBIT_LENGTH

	.even
function_mode:
	.ds.w	1
screen_mode:
	.ds.w	1

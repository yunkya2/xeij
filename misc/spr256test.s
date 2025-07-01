;========================================================================================
;  spr256test.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	spr256test.x
;		XEiJ�̃X�v���C�g256���\���@�\�̓�����m�F���܂��B
;		���̃G�~�����[�^�ł��X�v���C�g256���\���@�\������Γ��������m��܂���B
;		X68000���@�ł͓����܂���B
;
;	�ŏI�X�V
;		2023-02-09
;
;	����
;		has060 -i include -o spr256test.o -w spr256test.s
;		lk -o spr256test.x spr256test.o
;
;	�g����
;		XEiJ�̉������j���[�ŃX�v���C�g256���\����ON�ɂ��܂��B
;		XEiJ�̉������j���[�Ń��X�^������̃X�v���C�g�̖�����256�ɕύX���܂��B
;		�K�v�Ȃ�΃��Z�b�g���܂��B
;		spr256test.x�����s���܂��B
;		�����L�[�������ƏI�����܂��B
;
;	�X�V����
;		2023-02-09
;			���ŁB
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	vicon.equ

;�J�n

;512x512
	moveq.l	#0,d1
	IOCS	_CRTMOD

;�J�[�\��OFF
	IOCS	_B_CUROFF

;�X�[�p�[�o�C�U���[�h
	supervisormode

;�X�v���C�g������
	IOCS	_SP_INIT

;�X�v���C�g128�`255���N���A
	lea.l	$00EB0000+8*128,a0
	moveq.l	#0,d0
	moveq.l	#128-1,d1
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;�X�v���C�gON
	IOCS	_SP_ON

;�p���b�g��ݒ肷��
;	�p���b�g�R�[�h$x0�͍��B�p���b�g�R�[�h$x1�`$xF��240�F��p����
;	n=0�`239
;	t=n/240
;	H=floor(192*t)
;	S=31
;	V=31	floor(15+8*cos(2*pi*t)+0.5)
	lea.l	VICON_TSPALET,a0	;�p���b�g���W�X�^
	suba.l	a1,a1			;a1=n
	do
		clr.w	(a0)+			;�p���b�g�R�[�h$x0�͍�
		moveq.l	#15-1,d7		;�p���b�g�R�[�h$x1�`$xF
		for	d7
			move.l	#240,d0
			FPACK	__LTOD			;d0-d1=240
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=240
			move.l	a1,d0
			FPACK	__LTOD			;d0-d1=n
			FPACK	__DDIV			;d0-d1=n/240=t
			move.l	d0,d4
			move.l	d1,d5			;d4-d5=t
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=t
			move.l	#192,d0
			FPACK	__LTOD			;d0-d1=192
			FPACK	__DMUL			;d0-d1=192*t
			FPACK	__DFLOOR		;H=floor(192*t)
			FPACK	__DTOL
			move.l	d0,d6
			swap.w	d6
			move.w	#31.shl.8,d6		;S=31
			move.l	d4,d0
			move.l	d5,d1			;d0-d1=t
			FPACK	__NPI			;d0-d1=pi*t
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=pi*t
			move.l	#2*15,d0
			FPACK	__LTOD			;d0-d1=2*15
			FPACK	__DMUL			;d0-d1=2*pi*10*t
			FPACK	__COS			;d0-d1=cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=cos(2*pi*t)
			moveq.l	#8,d0
			FPACK	__LTOD			;d0-d1=8
			FPACK	__DMUL			;d0-d1=8*cos(2*pi*t)
			move.l	d0,d2
			move.l	d1,d3			;d2-d3=8*cos(2*pi*t)
			moveq.l	#15,d0
			FPACK	__LTOD			;d0-d1=15
			FPACK	__DADD			;d0-d1=15+8*cos(2*pi*t)
			move.l	#$3FE00000,d2
			moveq.l	#$00000000,d3		;d2-d3=0.5
			FPACK	__DADD			;d0-d1=15+8*cos(2*pi*t)+0.5
			FPACK	__DFLOOR		;V=floor(15+8*cos(2*pi*t)+0.5)
			FPACK	__DTOL
			move.b	d0,d6
			move.l	d6,d1			;d1=H<<16|S<<8|V
			IOCS	_HSVTORGB
			move.w	d0,(a0)+
			addq.l	#1,a1			;n++
		next
	while	<cmpa.l #VICON_TSPALET+2*256,a0>,lo

;�X�v���C�g��\������
;	�X�v���C�g�p�^�[�����`����O�ɕ\�����Ē�`���Ă���l�q��������
;	�X�v���C�g�ԍ��ƃp�^�[���ԍ��͓���
;	�X�v���C�g�ԍ��̏��4�r�b�g���p���b�g�u���b�N�Ƃ���
	moveq.l	#0,d7			;�X�v���C�g�ԍ�/�p�^�[���ԍ�
	lea.l	$00EB0000,a0		;�X�v���C�g�X�N���[�����W�X�^
	movea.l	#16,a6			;Y���W
	do
		movea.l	#16,a5			;X���W
		do
			move.w	a5,(a0)+		;X���W
			move.w	a6,(a0)+		;Y���W
			move.w	d7,d0
			and.w	#$00F0,d0		;�p���b�g�u���b�N
			lsl.w	#4,d0
			move.b	d7,d0			;�p�^�[���ԍ�
			move.w	d0,(a0)+		;�p���b�g�u���b�N<<8|�p�^�[���ԍ�
			move.w	#3,(a0)+		;�v���C�I���e�B
			addq.l	#1,d7			;�X�v���C�g�ԍ�
			adda.l	#16,a5			;X���W
		while	<cmpa.l #16+16*16,a5>,lo
		adda.l	#16,a6			;Y���W
	while	<cmpa.l #16+16*16,a6>,lo

;�X�v���C�g�p�^�[�����`����
;	�p�^�[���ԍ�0�`255�Ɋ������`����
;	�p�^�[���ԍ��̉���4�r�b�g���p���b�g�R�[�h�Ƃ���B������0��1�ɓǂݑւ���
	move.l	#'��',d1
	moveq.l	#8,d2
	IOCS	_FNTADR
	movea.l	d0,a6			;a6=�t�H���g�A�h���X
	moveq.l	#0,d7			;d7=�p�^�[���ԍ�
	do
		lea.l	sprbuf,a0
		moveq.l	#15,d3
		and.b	d7,d3		;�p�^�[���ԍ��̉���4�r�b�g
		if	eq
			moveq.l	#1,d3		;0��1�ɓǂݑւ���
		endif
		moveq	#16-1,d4
		for	d4
			move.b	(a6)+,d0	;������
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
		move.l	d7,d1		;�p�^�[���ԍ�
		moveq.l	#1,d2		;�p�^�[���T�C�Y
		lea.l	sprbuf,a1	;�p�^�[���f�[�^
		IOCS	_SP_DEFCG
		addq.l	#1,d7
	while	<cmp.l #256,d7>,lo

;�O�������
;	{x=3sin(t)-sin(3t/2)
;	{y=3cos(t)+cos(3t/2)�@�@(0��t<4��)
;	-4<=x,y<=4
;	https://twitter.com/sukannpi2/status/860126933606047745
;	����55.458Hz�Ȃ̂�1��30�b�Ƃ���Ɛ�������1664���1��
;	dt=4��/1664
;	�X�v���C�g�̊Ԋu��4��/256�ɂ����1���q���邪�e�[�u�������ɂ���
;	6�����x��ɂ��邩

GAP		equ	30	;�����̊Ԋu
ORBIT_LENGTH	equ	GAP*256	;�O���̈ʒu�̐�
COEFF_N		equ	3	;3*sin(t)��3
COEFF_T		equ	13	;3*t/2��3 �傫������Ɗp�������Đ��
COEFF_S		equ	2	;3*t/2��2
COEFF_P		equ	4	;4*pi��4
RADIUS_X	equ	50	;X�����̔��a
RADIUS_Y	equ	60	;Y�����̔��a

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
		move.l	#16+256-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DADD		;d0-d1=16+256-8+60*x
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8+60*x+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8+60*x+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+512,d0>,ge
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
		move.l	#16+256-8,d0
		FPACK	__LTOD		;d0-d1=16+256-8
		FPACK	__DSUB		;d0-d1=16+256-8-60*y
		move.l	#$3FE00000,d2	;d2-d3=0.5
		moveq.l	#$00000000,d3
		FPACK	__DADD		;d0-d1=16+256-8-60*y+0.5
		FPACK	__DFLOOR	;d0-d1=floor(16+256-8-60*y+0.5)
		FPACK	__DTOL
		ifor	<tst.l d0>,lt,<cmp.l #16+512,d0>,ge
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
	do
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;�����󔒊��Ԃ�҂�
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;�����A�����Ԃ�҂�

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

;���[�U���[�h
	usermode

;768x512
;	moveq.l	#16,d1
	moveq.l	#0,d1
	IOCS	_CRTMOD

;�J�[�\��ON
	IOCS	_B_CURON

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

	.bss
	.even
sprbuf:
	.ds.l	2*16
orbit:
	.ds.w	2*ORBIT_LENGTH


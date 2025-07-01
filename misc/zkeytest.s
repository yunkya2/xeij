;========================================================================================
;  zkeytest.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	zkeytest.x
;		Z�L�[�{�[�hLED����̃e�X�g
;
;	�ŏI�X�V
;		2023-04-15
;
;	����
;		has060 -i include -o zkeytest.o -w zkeytest.s
;		lk -o zkeytest.x zkeytest.o
;
;	�g����
;		zkeytest.x
;
;	�X�V����
;		2023-04-15
;			���ŁB
;
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac

	.text

;�萔
N	equ	55			;�P�x�̐�
dCOUNT	reg	d7			;���[�v�J�E���^�B0�`2*N-1
aGPDR	reg	a4			;MFP GPDR
aFILTER	reg	a5			;�J�E���^���P�x�ϊ��e�[�u��
aPORT	reg	a6			;Z�L�[�{�[�h����I/O�|�[�g
	lea.l	MFP_GPDR,aGPDR
	lea.l	brightness_filter,aFILTER
	lea.l	$00E9F040,aPORT

;�X�[�p�[�o�C�U���[�h
	supervisormode

;�ݒ��ۑ�����
	lea.l	port_temporary,a0
	movea.l	aPORT,a1
	moveq.l	#9-1,d1
	for	d1
		move.b	(a1)+,(a0)+
	next

;�v���O���}�u�����[�h�ɐ؂�ւ���
	bset.b	#0,8(aPORT)

;���[�v�J�n
	clr.w	dCOUNT
	do

	;���[�v�J�E���^����P�x�����
		if	<cmp.w #N,dCOUNT>,lo	;0�`N-1
			move.w	dCOUNT,d1	;0�`N-1
		else				;N�`2*N-1
			move.w	#2*N-1,d1
			sub.w	dCOUNT,d1	;N-1�`0
		endif
		move.b	(aFILTER,d1.w),d0	;d0.b=�P�x

	;�P�x��ݒ肷��
		movea.l	aPORT,a0
		moveq.l	#7-1,d1
		for	d1
			move.b	d0,(a0)+
		next

	;���M����
		bset.b	#1,8(aPORT)

	;�C���N�������g
		addq.w	#1,dCOUNT
		if	<cmp.w #N*2,dCOUNT>,eq
			moveq.l	#0,dCOUNT
		endif

	;�����A�����Ԃ�҂�
		do
		while	<btst.b #MFP_G_VDISP_BIT,(aGPDR)>,eq
		do
		while	<btst.b #MFP_G_VDISP_BIT,(aGPDR)>,ne

	;�L�[���͂�҂�
		bsr	inkey0
	while	eq

;�ݒ�𕜌�����
	movea.l	aPORT,a0
	lea.l	port_temporary,a1
	moveq.l	#9-1,d1
	for	d1
		move.b	(a1)+,(a0)+
	next

;���[�U���[�h
	usermode

;�I��
	DOS	_EXIT

brightness_filter:
k = 0
  .rept N
	.dc.b	k*k*255/((N-1)*(N-1))
k = k+1
  .endm
	.even

	.bss
	.even
port_temporary:
	.ds.b	9
	.text

;----------------------------------------------------------------
;�����R�[�h��0�łȂ��L�[����͂���B������Ă��Ȃ��Ă��҂��Ȃ�
;>d0.l:�����R�[�h�B0=������Ă��Ȃ�
inkey0::
	dostart
		IOCS	_B_KEYINP		;�L�[�o�b�t�@�����菜��
		break	<tst.b d0>,ne		;�����R�[�h��0�łȂ��L�[�������ꂽ�Ƃ��I��
	start
		IOCS	_B_KEYSNS		;�L�[�o�b�t�@���ǂ݂���
	while	<tst.l d0>,ne		;����������Ă���Ƃ��J��Ԃ�
	and.l	#$000000FF,d0		;�����R�[�h
	rts


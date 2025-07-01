;========================================================================================
;  vperiod.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;	vperiod.x
;	��������(���������M���̎���)���v�����܂�
;----------------------------------------------------------------------------------------

TITLE		reg	'vperiod.x (2024-02-17)'

	.include	control2.mac
	.include	doscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac

;�O���[�o�����W�X�^
dZERO	reg	d7
	moveq.l	#0,dZERO
aTCDCR	reg	a6
	lea.l	MFP_TCDCR,aTCDCR

;�X�[�p�[�o�C�U���[�h
	supervisormode

;���荞�݋֎~
	di

;�^�C�}�ۑ�
	move.b	MFP_IERB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	MFP_TCDCR-MFP_TCDCR(aTCDCR),-(sp)

;�^�C�}�ݒ�
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�݋֎~
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�ݒ�~�BIPRB�N���A

;�J�E���g��~
	move.b	dZERO,(aTCDCR)		;Timer-C/D�J�E���g��~
	do
	while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�

;V-DISP��1��0��҂�
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;?��1��҂�
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;1��0��҂�

;�J�E���g�J�n
	moveq.l	#0,d2			;neg(TCDR)��bit7��1��0�̉�
	moveq.l	#0,d3			;�O���neg(TCDR)
	move.b	dZERO,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^�N���A
	move.b	dZERO,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
	move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/D�J�E���g�J�n
					;Timer-C��1/200�v���X�P�[��(50us)
					;Timer-D��1/4�v���X�P�[��(1us)

;V-DISP��1��0��҂�
	do
		moveq.l	#0,d0
		sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;neg(TCDR)
		eor.b	d0,d3
		ifand	<>,mi,<tst.b d0>,pl	;neg(TCDR)��bit7��1��0
			addq.w	#1,d2			;������
		endif
		move.b	d0,d3
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;V-DISP��?��1��҂�
	do
		moveq.l	#0,d0
		sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;neg(TCDR)
		eor.b	d0,d3
		ifand	<>,mi,<tst.b d0>,pl	;neg(TCDR)��bit7��1��0
			addq.w	#1,d2			;������
		endif
		move.b	d0,d3
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;V-DISP��1��0��҂�

;�J�E���g��~
	move.b	dZERO,(aTCDCR)		;Timer-C/D�J�E���g��~
	do
	while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�

;�^�C�}�擾
	moveq.l	#0,d0
	moveq.l	#0,d1
	sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-C�J�E���g��
	sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-D�J�E���g��(�I�[�o�[�t���[����)
	eor.b	d0,d3
	ifand	<>,mi,<tst.b d0>,pl	;neg(TCDR)��bit7��1��0
		addq.w	#1,d2			;������
	endif

;�^�C�}����
	move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^����
	move.b	dZERO,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
	move.b	(sp)+,(aTCDCR)
	move.b	(sp)+,MFP_IMRB-MFP_TCDCR(aTCDCR)
	move.b	(sp)+,MFP_IERB-MFP_TCDCR(aTCDCR)

;���荞�݋���
	ei

;�J�E���^����
	mulu.w	#50,d0
	if	<cmp.b d1,d0>,hi
		add.w	#256,d0
	endif
	move.b	d1,d0
	mulu.w	#50*256,d2
	add.l	d2,d0			;��������(us)
	move.l	d0,d1

;���[�U���[�h
	usermode

;���ʂ�\������
	lea.l	buffer(pc),a0
	leastrdata	<TITLE,13,10,'obs_VP='>,a1
	bsr	strcpy
	move.l	d1,d0
	bsr	utos
	bsr	crlf
	lea.l	buffer(pc),a0
	bsr	print

;�I��
	DOS	_EXIT

	.bss
buffer:
	.ds.b	256
	.text



;----------------------------------------------------------------
;���s���R�s�[����
;<a0.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
crlf::
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;�������\������
;<a0.l:������
print::
	push	d0
	bsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts

;----------------------------------------------------------------
;��������R�s�[����
;<a0.l:�R�s�[��
;<a1.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
;>a1.l:�R�s�[����0�̎��̈ʒu
strcpy::
	do
		move.b	(a1)+,(a0)+
	while	ne			;0�łȂ���ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	rts

;----------------------------------------------------------------
;������̒����𐔂���
;<a0.l:������
;>d0.l:����
strlen::
	move.l	a0,d0			;d0=�擪
	do
		tst.b (a0)+
	while	ne			;0�łȂ���ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�Ba0=����
	exg.l	d0,a0			;d0=����,a0=�擪
	sub.l	a0,d0			;d0=����-�擪=����
	rts

;----------------------------------------------------------------
;32�r�b�g�����Ȃ�������10�i���̕�����ɕϊ�����
;<d0.l:�����Ȃ�����
;<a0.l:�o�b�t�@�B10�i���̕�����̐擪
;>a0.l:10�i���̕�����̖�����0�̈ʒu
utos::
	if	<tst.l d0>,eq		;0
		move.b	#'0',(a0)+
	else				;0�ȊO
		push	d0-d2/a1
		lea.l	utos_table(pc),a1
		do
			move.l	(a1)+,d1
		while	<cmp.l d1,d0>,lo	;������Ƃ���܂Ői�ށB�[���T�v���X
		do
			moveq.l	#'0'-1,d2
			do
				addq.b	#1,d2
				sub.l	d1,d0
			while	hs			;������񐔂𐔂���
			move.b	d2,(a0)+
			add.l	d1,d0			;�����߂������������߂�
			move.l	(a1)+,d1
		while	ne
		pop
	endif
	clr.b	(a0)
	rts

utos_table::
	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0




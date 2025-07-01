;========================================================================================
;  hypotrochoid.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;  hypotrochoid.x
;	XEiJ�̋^���O���t�B�b�N���(4096�̃p�^�[����~���l�߂��o�b�N�O���E���h)�Ƀn�C�|�g���R�C�h��`���܂��B
;	��(S)�Ǝ�(S)�̓X�v���C�g���(BG0��BG1)�A��(T)�̓e�L�X�g��ʁA��(G)�̓O���t�B�b�N��ʂł��B
;	�������j���[��4096�̃p�^�[���`�F�b�N�{�b�N�X��768x512�ŃX�v���C�g��\���`�F�b�N�{�b�N�X��
;	512x512��BG1��\���`�F�b�N�{�b�N�X��ON�ɂ��ă��Z�b�g���Ă�����s���܂��B
;	BREAK/CTRL+C/ESC�L�[�ŏI���A���쒆�͂��̑��̃L�[�Œ�~�B��~����ENTER�L�[�ōĊJ�A���̑��̃L�[�ŃR�}���肵�܂��B
;	X68000���@�ł͓����܂���B
;----------------------------------------------------------------

;----------------------------------------------------------------
;�n�C�|�g���R�C�h
;	��~�̓����ɉ����ē��~���]����Ƃ��A���~�ɌŒ肳�ꂽ�_�̋O�Ղ��n�C�|�g���R�C�h�ƌĂт܂��B
;	��~�̒��S��(0,0)�A���a��R�A���~�̔��a��r�A���~�̒��S����_�܂ł̋�����d�Ƃ��܂��B
;	��~�Ɠ��~�̎��̒����̔䂩��A���~������1������Ԃɓ��~�͐ڐ��ɑ΂��ĉE��R/r��]���܂��B
;	�����ɐڐ�������1��]����̂ŁA���킹�ē��~�͉E��(R-r)/r��]���܂��B
;	���~�̒��S�̕�����t�Ƃ���ƁA�_�̈ʒu��((R-r)*cos(t)+d*cos((R-r)/r*t),(R-r)*sin(t)-d*sin((R-r)/r*t))�ƂȂ�܂��B
;	���~������n������Ԃɓ��~�͉E��(R-r)/r*n��]���܂��B
;	R,r�������̂Ƃ��A�_���ŏ��̈ʒu�ɖ߂�܂ł̎���n0��(R-r)/r*n�������ɂȂ�ŏ���n�A���Ȃ킿n0=r/gcd(R-r,r)�ł��B
;	https://en.wikipedia.org/wiki/Hypotrochoid
;----------------------------------------------------------------

	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ
	.include	vicon.equ

;����
	lea.l	1(a2),a0
	do
	;R ��~�̔��a
		bsr	nextword
		break	eq			;�w��Ȃ��B����l���g��
		FPACK	__STOL
		goto	cs,error		;�������Ȃ��B�G���[�I��
		goto	<tst.l d0>,le,error	;1��菬�����B�G���[�I��
		goto	<cmp.l #1000000,d0>,gt,error	;1000000���傫���B�G���[�I��
		move.l	d0,int_R
	;r ���~�̔��a
		bsr	nextword
		break	eq			;�w��Ȃ��B����l���g��
		FPACK	__STOL
		goto	cs,error		;�������Ȃ��B�G���[�I��
		goto	<tst.l d0>,le,error	;1��菬�����B�G���[�I��
		goto	<cmp.l #1000000,d0>,gt,error	;1000000���傫���B�G���[�I��
		goto	<cmp.l int_R,d0>,ge,error	;r��R�Ɠ����������傫���B�G���[�I��
		move.l	d0,int_r
	;d ���~�̒��S����_�܂ł̋���
		bsr	nextword
		break	eq			;�w��Ȃ��B����l���g��
		FPACK	__STOD
		goto	cs,error		;���l���Ȃ��B�G���[�I��
		FPACK	__DTST
		goto	lt,error		;0��菬�����B�G���[�I��
		move.l	d0,d2
		move.l	d1,d3
		move.l	#1000000,d0
		FPACK	__LTOD
		FPACK	__DCMP
		goto	lt,error		;1000000���傫���B�G���[�I��
		movem.l	d2-d3,dbl_d
	;f 1��(��1����)�̓_�̐�
		bsr	nextword
		break	eq			;�w��Ȃ��B����l���g��
		FPACK	__STOL
		goto	cs,error		;���l���Ȃ��B�G���[�I��
		goto	<tst.l d0>,le,error	;1��菬�����B�G���[�I��
		goto	<cmp.l #1000000,d0>,gt,error	;1000000���傫���B�G���[�I��
		move.l	d0,int_f
	while	f

;�����Ō��܂�l
;R ��~�̔��a
	move.l	int_R,d0
	FPACK	__LTOD
	movem.l	d0-d1,dbl_R
;r ���~�̔��a
	move.l	int_r,d0
	FPACK	__LTOD
	movem.l	d0-d1,dbl_r
;Rr=R-r ��~�̒��S���瓮�~�̒��S�܂ł̋���
	move.l	int_R,d0
	sub.l	int_r,d0
	move.l	d0,int_Rr
	FPACK	__LTOD
	movem.l	d0-d1,dbl_Rr
;Rrr=(R-r)/r �_�̑��x
;	movem.l	dbl_Rr,d0-d1
	movem.l	dbl_r,d2-d3
	FPACK	__DDIV
	movem.l	d0-d1,dbl_Rrr
;n0=r/gcd(R-r,r) ����
	move.l	int_Rr,d0		;d0=�O��̗]��=R-r�B0�ł͂Ȃ�
	move.l	int_r,d1		;d1=�O��̏���=r�B0�ł͂Ȃ�
	do
					;d0=�O��̗]��,d1=�O��̏���
					;�O��̏������폜��,�O��̗]�聨����
		exg.l	d0,d1		;d0=�폜��,d1=����
		FPACK	__LMOD		;d0=�]��,d1=����
	while	<tst.l d0>,ne		;�]�肪0�ɂȂ�܂ŌJ��Ԃ�
					;�]�肪0�ɂȂ����Ƃ��̏���=gcd(R-r,r)
	move.l	int_r,d0		;d0=r
	FPACK	__LDIV			;d0=n0=r/gcd(R-r,r)
	move.l	d0,int_n0
;fn0=f*n0 n0��(=1����)�̓_�̐�
	move.l	int_f,d0
	move.l	int_n0,d1
	FPACK	__LMUL
	move.l	d0,int_fn0
;s=RR/(R-r+d) �{��
	movem.l	dbl_Rr,d0-d1
	movem.l	dbl_d,d2-d3
	FPACK	__DADD
	move.l	d0,d2
	move.l	d1,d3
	movem.l	dbl_RR,d0-d1
	FPACK	__DDIV
	movem.l	d0-d1,dbl_s
;f 1��(��1����)�̓_�̐�
	move.l	int_f,d0
	FPACK	__LTOD
	movem.l	d0-d1,dbl_f
;dt=2*pi/f �p�x�̑���
	moveq.l	#2,d0
	FPACK	__LTOD
	FPACK	__NPI
	movem.l	dbl_f,d2-d3
	FPACK	__DDIV
	movem.l	d0-d1,dbl_dt

;�X�N���[���̋O�������
;	���S(128,256)���a(128,256)�̉~
orbit_length	equ	(orbit_end-orbit)/4
	move.l	#orbit_length,d0
	FPACK	__LTOD
	move.l	d0,d2			;d2d3=n
	move.l	d1,d3
	moveq.l	#2,d0
	FPACK	__LTOD
	FPACK	__NPI			;d0d1=2*pi
	FPACK	__DDIV			;d0d1=2*pi/n=dt
	movea.l	d0,a4			;a4a5=dt
	movea.l	d1,a5
	move.l	#128,d0
	FPACK	__LTOD
	movea.l	d0,a0			;a0a1=128
	movea.l	d1,a1
	move.l	#256,d0
	FPACK	__LTOD
	movea.l	d0,a2			;a2a3=256
	movea.l	d1,a3
	moveq.l	#0,d4			;d4d5=t
	moveq.l	#0,d5
	lea.l	orbit,a6
	move.w	#orbit_length-1,d7
	for	d7
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__COS			;d0d1=cos(t)
		move.l	a0,d2			;d2d3=128
		move.l	a1,d3
		FPACK	__DMUL			;d0d1=128*cos(t)
		exg.l	d0,d2			;d0d1=128
		exg.l	d1,d3			;d2d3=128*cos(t)
		FPACK	__DSUB			;d0d1=128-128*cos(t)
		FPACK	__DTOL			;d0=128-128*cos(t)
		move.w	d0,(a6)+		;x
	;
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__SIN			;d0d1=sin(t)
		move.l	a2,d2			;d2d3=256
		move.l	a3,d3
		FPACK	__DMUL			;d0d1=256*sin(t)
		FPACK	__DADD			;d0d1=256+256*sin(t)
		FPACK	__DTOL			;d0=256+256*sin(t)
		move.w	d0,(a6)+		;y
	;
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		move.l	a4,d2			;d2d3=dt
		move.l	a5,d3
		FPACK	__DADD			;d0d1=t+dt
		move.l	d0,d4			;d4d5=t+dt
		move.l	d1,d5
	next

;��ʃ��[�h��ύX
	move.w	#3,-(sp)		;�t�@���N�V�����L�[�\���Ȃ�
	move.w	#14,-(sp)
	DOS	_CONCTRL
	move.w	d0,function_mode
	move.w	#1,-(sp)		;768x512�O���t�B�b�N����
	move.w	#16,-(sp)
	DOS	_CONCTRL
	move.w	d0,screen_mode
	addq.l	#8,sp

;�J�[�\��OFF
	IOCS	_B_CUROFF

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

;�e�L�X�g�G���A�Ƀp�^�[����~���l�߂�
	lea.l	$00EB4000,a0		;�J�n�ʒu(0,0)
	moveq.l	#0,d4			;�p�^�[���ԍ����4bit<<12
	move.w	#1<<8,d5		;�p���b�g�u���b�N<<8�B�p���b�g�u���b�N1����
	moveq.l	#0,d6			;�p�^�[���ԍ�����8bit
	do
		moveq.l	#16-1,d3		;Y�������[�v���16��
		for	d3
			moveq.l	#4-1,d2			;Y�������[�v����4��
			for	d2
				moveq.l	#64-1,d1		;X�������[�v64��
				for	d1
					move.w	d4,d0			;�p�^�[���ԍ����4bit<<12
					add.w	d5,d0			;�p���b�g�u���b�N<<8
					add.w	d6,d0			;�p�^�[���ԍ�����8bit
					move.w	d0,(a0)+
					addq.b	#1,d6			;�p�^�[���ԍ�����8bit
				next
			next
			add.w	#1<<12,d4		;�p�^�[���ԍ����4bit<<12
		next
		add.w	#1<<8,d5		;�p���b�g�u���b�N<<8
	while	<cmp.w #2<<8,d5>,ls	;�p���b�g�u���b�N2�܂�

;�X�v���C�g�\��ON
;	BG0�Ƀe�L�X�g�G���A0�ABG1�Ƀe�L�X�g�G���A1�����蓖�Ăĕ\��
	move.w	#SPRC_SPRITE_ON|SPRC_BG_1_TEXT_1|SPRC_BG_1_ON|SPRC_BG_0_TEXT_0|SPRC_BG_0_ON,SPRC_CONTROL
	ori.w	#VICON_SPON_MASK,VICON_VISIBLE
	move.w	#%00_00_01_10_11_10_01_00,VICON_PRIORITY

;�p���b�g��ݒ肷��
	movehsv	104,31,31,VICON_TSPALET+2*$11	;�BBG0�B�X�v���C�g�p���b�g$11
	movehsv	152,31,31,VICON_TSPALET+2*$21	;���BBG1�B�X�v���C�g�p���b�g$21
	movehsv	8,31,31,VICON_TSPALET+2*1	;�ԁB�e�L�X�g��ʁB�e�L�X�g�p���b�g1
	movehsv	56,31,31,VICON_GPALET+2*1	;�΁B�O���t�B�b�N��ʁB�O���t�B�b�N�p���b�g1

;�J�n�ʒu�܂ŃX�N���[������
	lea.l	orbit,a0
	move.w	(a0),SPRC_BG_0_X	;BG0�𓮂���
	move.w	2(a0),SPRC_BG_0_Y
	move.w	4*(orbit_length*1/4)(a0),SPRC_BG_1_X	;BG1�𓮂���
	move.w	4*(orbit_length*1/4)+2(a0),SPRC_BG_1_Y
	move.w	4*(orbit_length*2/4)(a0),CRTC_TEXT_X	;�e�L�X�g��ʂ𓮂���
	move.w	4*(orbit_length*2/4)+2(a0),CRTC_TEXT_Y
	move.w	4*(orbit_length*3/4)(a0),CRTC_GRAPHIC_X_0	;�O���t�B�b�N��ʂ𓮂���
	move.w	4*(orbit_length*3/4)+2(a0),CRTC_GRAPHIC_Y_0

;������`��
	lea.l	moji(pc),a0		;a0=����
	moveq.l	#2,d7			;2=S,1=T,0=G
	for	d7
	;�����R�[�h�����o���BSJIS�Ɍ���
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.b	(a0)+,d0		;sh
		move.b	(a0)+,d1		;sl
	;94��94�_�̒ʂ��ԍ������߂�
	;	((sh - (sh < 0xe0 ? 0x81 : 0xe0 - (0xa0 - 0x81))) * 188 +
	;	 (sl - (sl < 0x80 ? 0x40 : 0x80 - (0x7f - 0x40))))
		moveq.l	#$81,d2
		if	<cmp.b #$E0,d0>,hs
			moveq.l	#$E0-($A0-$81),d2
		endif
		sub.b	d2,d0
		moveq.l	#$40,d2
		if	<cmp.b #$80,d1>,hs
			moveq.l	#$80-($7F-$40),d2
		endif
		sub.b	d2,d1
		mulu.w	#188,d0
		add.w	d1,d0
	;9�悩��15��܂łȂ��̂ŋl�߂�
		if	<cmp.w #94*(16-1),d0>,hs	;16��`
			sub.w	#94*(16-9),d0		;16�恨9��
		endif
	;�t�H���g�A�h���X�����߂�
		mulu.w	#3*24,d0
		add.l	#$00F40000,d0		;24x24
		movea.l	d0,a1
	;�_����ׂ�
		moveq.l	#1,d3			;�F
		move.w	#512-12,d2		;Y���W
		moveq.l	#24-1,d6		;24���C��
		for	d6
			move.w	#512-12,d1		;X���W
			moveq.l	#3-1,d5			;3�o�C�g
			for	d5
				move.b	(a1)+,d0
				moveq.l	#8-1,d4			;8�h�b�g
				for	d4
					add.b	d0,d0
					if	cs
						if	<cmp.w #1,d7>,hi	;2=S
							bsr	sp_pset
						elif	eq			;1=T
							bsr	tx_pset
						else				;0=G
							bsr	gr_pset
						endif
					endif
					addq.w	#1,d1			;X���W��i�߂�
				next
			next
			sub.w	#24,d1			;X���W��߂���
			addq.w	#1,d2			;Y���W��i�߂�
		next
	next

;�n�C�|�g���R�C�h��`��
;	t=0
;	for i=1 to fn0
;		pset(floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t))),
;		     floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t))))
;		t=t+dt
;	next
	moveq.l	#0,d4			;d4d5=t
	moveq.l	#0,d5
	move.l	int_fn0,d7
	forlong	d7
		movem.l	dbl_Rrr,d0-d1		;d0d1=Rrr
		move.l	d4,d2			;d2d3=t
		move.l	d5,d3
		FPACK	__DMUL			;d0d1=Rrr*t
		movea.l	d0,a4			;a4a5=Rrr*t
		movea.l	d1,a5
		FPACK	__COS			;d0d1=cos(Rrr*t)
		movem.l	dbl_d,d2-d3		;d2d3=d
		FPACK	__DMUL			;d0d1=d*cos(Rrr*t)
		movea.l	d0,a2			;a2a3=d*cos(Rrr*t)
		movea.l	d1,a3
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__COS			;d0d1=cos(t)
		movem.l	dbl_Rr,d2-d3		;d2d3=Rr
		FPACK	__DMUL			;d0d1=Rr*cos(t)
		move.l	a2,d2			;d2d3=d*cos(Rrr*t)
		move.l	a3,d3
		FPACK	__DADD			;d0d1=Rr*cos(t)+d*cos(Rrr*t)
		movem.l	dbl_s,d2-d3		;d2d3=s
		FPACK	__DMUL			;d0d1=s*(Rr*cos(t)+d*cos(Rrr*t))
		movem.l	dbl_ox,d2-d3	;d2d3=ox
		FPACK	__DADD			;d0d1=ox+s*(Rr*cos(t)+d*cos(Rrr*t))
		FPACK	__DFLOOR		;d0d1=floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t)))
		FPACK	__DTOL			;d0=floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t)))
		movea.l	d0,a0			;a0=floor(ox+s*(Rr*cos(t)+d*cos(Rrr*t))) X���W
	;
		move.l	a4,d0
		move.l	a5,d1			;d0d1=Rrr*t
		FPACK	__SIN			;d0d1=sin(Rrr*t)
		movem.l	dbl_d,d2-d3		;d2d3=d
		FPACK	__DMUL			;d0d1=d*sin(Rrr*t)
		movea.l	d0,a2			;a2a3=d*sin(Rrr*t)
		movea.l	d1,a3
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		FPACK	__SIN			;d0d1=sin(t)
		movem.l	dbl_Rr,d2-d3		;d2d3=Rr
		FPACK	__DMUL			;d0d1=Rr*sin(t)
		move.l	a2,d2			;d2d3=d*sin(Rrr*t)
		move.l	a3,d3
		FPACK	__DSUB			;d0d1=Rr*sin(t)-d*sin(Rrr*t)
		movem.l	dbl_s,d2-d3		;d2d3=s
		FPACK	__DMUL			;d0d1=s*(Rr*sin(t)-d*sin(Rrr*t))
		move.l	d0,d2			;d2d3=s*(Rr*sin(t)-d*sin(Rrr*t))
		move.l	d1,d3
		movem.l	dbl_oy,d0-d1	;d0d1=oy
		FPACK	__DSUB			;d0d1=oy-s*(Rr*sin(t)-d*sin(Rrr*t))
		FPACK	__DFLOOR		;d0d1=floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t)))
		FPACK	__DTOL			;d0=floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t)))
		movea.l	d0,a1			;a1=floor(oy-s*(Rr*sin(t)-d*sin(Rrr*t))) Y���W
	;
		move.l	a0,d1
		move.l	a1,d2
		moveq.l	#1,d3
		bsr	sp_pset
		bsr	tx_pset
		bsr	gr_pset
	;
		move.l	d4,d0			;d0d1=t
		move.l	d5,d1
		movem.l	dbl_dt,d2-d3		;d2d3=dt
		FPACK	__DADD			;d0d1=t+dt
		move.l	d0,d4			;d4d5=t+dt
		move.l	d1,d5
	next

;������
	lea.l	orbit,a0
	movea.l	a0,a1
	lea.l	4*(orbit_length*1/4)(a0),a2
	lea.l	4*(orbit_length*2/4)(a0),a3
	lea.l	4*(orbit_length*3/4)(a0),a4
	lea.l	orbit_end-orbit(a0),a5
	moveq.l	#0,d1			;-1=��~��,0=���쒆,1=�R�}����
	dostart
		ifand	<tst.l d1>,mi,<cmp.b #13,d0>,eq	;��~����ENTER�L�[�������ꂽ�Ƃ�
			moveq.l	#0,d1			;���쒆�ɂ���
		elif	<tst.b d0>,ne		;��~����ENTER�ȊO�̃L�[�������ꂽ���A���쒆�ɉ����L�[�������ꂽ�Ƃ�
			moveq.l	#1,d1			;�R�}����ɂ���
		endif
	start
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq	;�����\�����Ԃ�҂�
		do
		while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne	;�����A�����Ԃ�҂�
		if	<tst.l d1>,pl		;���쒆�܂��̓R�}����̂Ƃ�
			if	ne			;�R�}����̂Ƃ�
				moveq.l	#-1,d1			;��~���ɂ���
			endif
			move.w	(a1)+,SPRC_BG_0_X	;BG0�𓮂���
			move.w	(a1)+,SPRC_BG_0_Y
			if	<cmpa.l a5,a1>,eq
				movea.l	a0,a1
			endif
			move.w	(a2)+,SPRC_BG_1_X	;BG1�𓮂���
			move.w	(a2)+,SPRC_BG_1_Y
			if	<cmpa.l a5,a2>,eq
				movea.l	a0,a2
			endif
			move.w	(a3)+,CRTC_TEXT_X	;�e�L�X�g��ʂ𓮂���
			move.w	(a3)+,CRTC_TEXT_Y
			if	<cmpa.l a5,a3>,eq
				movea.l	a0,a3
			endif
			move.w	(a4)+,CRTC_GRAPHIC_X_0	;�O���t�B�b�N��ʂ𓮂���
			move.w	(a4)+,CRTC_GRAPHIC_Y_0
			if	<cmpa.l a5,a4>,eq
				movea.l	a0,a4
			endif
		endif
		bsr	inkey0
	whileand	<cmp.b #27,d0>,ne,<cmp.b #3,d0>,ne	;ESC�܂���CTRL+C���������܂ŌJ��Ԃ�

;�X�v���C�g�\��OFF
	move.w	#$0000,SPRC_CONTROL
	andi.w	#.notw.VICON_SPON_MASK,VICON_VISIBLE

;�p�^�[��4096����`OFF
	move.w	#$0000,$00EB0812
	move.w	#$0000,$00EB0814

;���[�U���[�h
	usermode

;�J�[�\��ON
	IOCS	_B_CURON

;��ʃ��[�h�𕜌�
	move.w	screen_mode,-(sp)
	move.w	#16,-(sp)
	DOS	_CONCTRL
	move.w	function_mode,-(sp)
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.l	#8,sp

;�I��
exit:
	DOS	_EXIT

moji:		.dc.w	'�r','�s','�f'

;�G���[�I��
error:
	pea.l	usage(pc)
	DOS	_PRINT
	addq.l	#4,sp
	move.w	#1,-(sp)
	DOS	_EXIT2

usage:		.dc.b	'>hypotrochoid.x R r d f',13,10
		.dc.b	'                               ����l  �ŏ��l   �ő�l',13,10
		.dc.b	'  R  ��~�̔��a(����)              97     r+1  1000000',13,10
		.dc.b	'  r  ���~�̔��a(����)              47       1      R-1',13,10
		.dc.b	'  d  ���~�̒��S����_�܂ł̋���    37       1  1000000',13,10
		.dc.b	'  f  1��(��1����)�̓_�̐�(����)   720       1  1000000',13,10
		.dc.b	0
	.even

;sp_pset
;	�o�b�N�O���E���h��ʂɓ_��`��
;	1024x1024�h�b�g�̉�ʂ�64x64��16x16�h�b�g(128�o�C�g)�̃p�^�[���ɕ�������Ă���
;	��ʍ��W(%LLLLLLSTXX,%BBBBHHYYYY)
;	�p�^�[�����W(%LLLLLL,%BBBBHH) �p�^�[�������W(%STXX,%YYYY)
;	�p�^�[���ԍ�%BBBBHHLLLLLL �o���N�ԍ�%BBBB �o���N���p�^�[���ԍ�%HHLLLLLL
;	���[�h�A�h���X$00EB8000+%HHLLLLLLSYYYYT0 ���[�h���r�b�g�ԍ�%XX00^%1100
;<d1.w:X���W�B0�`1023�B�͈͊O�̂Ƃ��������Ȃ�
;<d2.w:Y���W�B0�`1023�B�͈͊O�̂Ƃ��������Ȃ�
;<d3.w:�p���b�g�R�[�h�B0�`15�B����4bit���g��
sp_pset:
	ifand	<cmp.w #1023,d1>,ls,<cmp.w #1023,d2>,ls
		push	d1-d5/a0
		moveq.l	#%1111,d4		;d1.w=%LLLLLLSTXX
		moveq.l	#%1111,d5		;d2.w=%BBBBHHYYYY
		and.w	d4,d3			;d3.w=%PPPP
		and.w	d1,d4			;d4.l=%STXX
		and.w	d2,d5			;d5.l=%YYYY
		lsr.w	#4,d1			;d1.w=%LLLLLL
		lsr.w	#4,d2			;d2.w=%BBBBHH
		lsl.w	#6,d2			;d2.w=%BBBBHH000000
		or.w	d2,d1			;d1.w=%BBBBHHLLLLLL �p�^�[���ԍ�
		move.w	d1,$00EB0814		;%BBBB �o���N�ԍ�
		moveq.l	#0,d2
		move.b	d1,d2			;d2.l=%HHLLLLLL
		lsl.b	#5,d4			;d4.b=%TXX00000,x=S
		addx.w	d2,d2			;d2.l=%HHLLLLLLS
		lsl.w	#4,d2			;d2.l=%HHLLLLLLS0000
		or.w	d5,d2			;d2.l=%HHLLLLLLSYYYY
		add.b	d4,d4			;d4.b=%XX000000,x=T
		addx.w	d2,d2			;d2.l=%HHLLLLLLSYYYYT
		add.w	d2,d2			;d2.l=%HHLLLLLLSYYYYT0
		lea.l	$00EB8000,a0
		adda.l	d2,a0			;a0=$00EB8000+%HHLLLLLLSYYYYT0 ���[�h�A�h���X
		lsr.b	#4,d4			;d4.b=%XX00
		eor.b	#%1100,d4		;d4.b=%XX00^%1100 ���[�h���r�b�g�ԍ�
		move.w	(a0),d2			;���[�h��ǂݏo��
		ror.w	d4,d2			;�ړI�̈ʒu������4bit�ֈړ�����
		and.w	#%1111111111110000,d2	;����4bit������
		or.w	d3,d2			;����4bit�Ƀp���b�g�R�[�h������
		rol.w	d4,d2			;���̈ʒu�ɖ߂�
		move.w	d2,(a0)			;���[�h�������߂�
		pop
	endif
	rts

tx_pset:
	ifand	<cmp.w #1023,d1>,ls,<cmp.w #1023,d2>,ls
		push	d0-d3/a0
		move.w	CRTC_ACCESS,-(sp)
		move.w	#$0200,CRTC_ACCESS	;�}�X�NON,����OFF
		move.w	CRTC_MASK,-(sp)
		lea.l	$00E60000,a0		;�v���[��3����
		ext.l	d2
		lsl.l	#7,d2			;y*128
		adda.l	d2,a0
		moveq.l	#15,d0
		and.w	d1,d0			;x�̉���4bit
		move.w	#$8000,d2
		lsr.w	d0,d2			;�������ރr�b�g����1
		not.w	d2			;�������ރr�b�g����0
		move.w	d2,CRTC_MASK
		lsr.w	#4,d1
		add.w	d1,d1			;x/16*2
		adda.w	d1,a0
		ror.w	#4,d3			;bit3���ŏ�ʂ�
		moveq.l	#4-1,d2
		for	d2
			add.w	d3,d3			;�����o��
			subx.w	d0,d0			;�S�r�b�g�ɓW�J
			move.w	d0,(a0)			;��������
			suba.l	#$00020000,a0
		next
		move.w	(sp)+,CRTC_MASK
		move.w	(sp)+,CRTC_ACCESS
		pop
	endif
	rts

gr_pset:
	ifand	<cmp.w #1023,d1>,ls,<cmp.w #1023,d2>,ls
		push	d1-d2/a0
		lea.l	$00C00000,a0
		swap.w	d2
		clr.w	d2
		lsr.l	#5,d2			;y*2048
		adda.l	d2,a0
		add.w	d1,d1			;x*2
		move.w	d3,(a0,d1.w)
		pop
	endif
	rts

	.data
	.even
;�萔
dbl_ox:		.dc.d	512.0		;ox ���S��X���W
dbl_oy:		.dc.d	512.0		;oy ���S��Y���W
dbl_RR:		.dc.d	510.0		;RR �\�����a
;����
int_R:		.dc.l	97		;R ��~�̔��a
int_r:		.dc.l	47		;r ���~�̔��a
dbl_d:		.dc.d	37.0		;d ���~�̒��S����_�܂ł̋���
int_f:		.dc.l	720		;f 1��(��1����)�̓_�̐�

	.bss
	.even
;�����Ō��܂�l
dbl_R:		.ds.d	1		;R ��~�̔��a
dbl_r:		.ds.d	1		;r ���~�̔��a
int_Rr:		.ds.l	1		;Rr=R-r ��~�̒��S���瓮�~�̒��S�܂ł̋���
dbl_Rr:		.ds.d	1		;Rr=R-r ��~�̒��S���瓮�~�̒��S�܂ł̋���
dbl_Rrr:	.ds.d	1		;Rrr=(R-r)/r �_�̑��x
int_n0:		.ds.l	1		;n0=r/gcd(R-r,r) ����
int_fn0:	.ds.l	1		;fn0=f*n0 n0��(=1����)�̓_�̐�
dbl_s:		.ds.d	1		;s=RR/(R-r+d) �{��
dbl_f:		.ds.d	1		;f 1��(��1����)�̓_�̐�
dbl_dt:		.ds.d	1		;dt=2*pi/f �p�x�̑���

;�ۑ�������ʃ��[�h
function_mode:	.ds.w	1
screen_mode:	.ds.w	1

;�X�N���[���̋O��
orbit:		.ds.w	2*720
orbit_end:

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
		redo	<cmp.b #' ',d0>,eq	;' '�Ȃ�ΌJ��Ԃ�
	whileand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r�Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	tst.l	d0
	rts

	.end

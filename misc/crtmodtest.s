;========================================================================================
;  crtmodtest.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	crtmodtest.x
;		IOCS _CRTMOD�̎����ƃ��j�^�̐��\���m�F���邽�߂̉�ʂ�\�����܂��B
;		IPLROM 1.6/crtmod16.x�Ŋg�����ꂽ��ʃ��[�h�ɑΉ����Ă��܂��B
;
;	�ŏI�X�V
;		2025-04-13
;
;	����
;		has060 -i include -o crtmodtest.o -w crtmodtest.s
;		lk -o crtmodtest.x crtmodtest.o
;
;	�g����
;		-l CRTorLCD���[�h
;			CRTorLCD���[�h���w�肵�܂��B
;			0���w�肷���CRT�����̓������g���ɁA1���w�肷���LCD�����̓������g���ɂȂ�܂��B
;			-l���w�肵��-s���w�肵�Ȃ������Ƃ���CRTorLCD���[�h�����ɖ߂��ďI�����܂��B
;			-l���w�肵��-s���w�肵���Ƃ���CRTorLCD���[�h��ύX�����܂܏I�����܂��B
;			-l���w�肵�Ȃ������Ƃ��͌��݂�CRTorLCD���[�h��p���܂��B
;			-l���w�肵�Ȃ������Ƃ���-s�͎w��ł��܂���B
;		-m ��ʃ��[�h
;			��ʃ��[�h��0�`47�͈̔͂Ŏw�肵�܂��B
;			��ʃ��[�h�̈ꗗ�͎g�p�@�ɏ����Ă���܂��B
;		-s
;			-l�Ŏw�肳�ꂽCRTorLCD���[�h��SRAM�ɕۑ����܂��B
;		��ʂ�\�����ăL�[���͑҂��ɂȂ�܂��B
;		�����L�[�������Ɖ�ʃ��[�h�����ɖ߂��ďI�����܂��B
;		ESC�L�[�������ꂽ�Ƃ��͉�ʃ��[�h��ύX�����܂܏I�����܂��B
;
;	�X�V����
;		2022-02-21
;			���J�B
;		2023-01-10
;			�����w���v���b�Z�[�W���y�[�W���ɋ�؂��ĕ\������悤�ɂ��܂����B
;		2023-11-14
;			-l���w�肵���Ƃ�CRTorLCD���[�h��ύX�����܂܏I�����Ă��܂������A���ɖ߂��ďI������悤�ɂ��܂����B
;			-s��ǉ����܂����B-s���w�肷���-l�Ŏw�肳�ꂽCRTorLCD���[�h�ɕύX�����܂܏I�����܂��B
;		2024-08-25
;			��ʃ��[�h40�`47�ɑΉ����܂����B
;		2024-08-26
;			IPLROM 1.0�`1.3��IOCS _SP_INIT�̃o�O�𓥂܂Ȃ��悤�ɂ��܂����B
;			ESC�L�[�ŏI�������Ƃ��A�X�v���C�g�ƃO���t�B�b�N���\���ɁA�e�L�X�g�������A�e�L�X�g�p���b�g�𕜌����܂��B
;			�R�[�h�𐮗����܂����B
;		2025-04-01
;			IPLROM 1.6/CRTMOD16.X�ȊO�̊��œ������Ɖ�ʂ����������C�����܂����B
;		2025-04-13
;			stou���C�����܂����B
;
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ

TITLE_STRING	reg	'crtmodtest.x for IPLROM 1.6/crtmod16.x (2025-04-13)'

MAX_SCREEN_MODE	equ	47		;��ʃ��[�h�̍ő�l

TEXT_LINE	equ	3
GRAPHIC_LINE	equ	4		;4,5,6,7
SPRITE_LINE	equ	8
BG_LINE		equ	9		;9,10

	.text

base:
	lea.l	base(pc),a6
r	reg	-base(a6)

;�I�v�V�������m�F����
	moveq.l	#-1,d6			;CRTorLCD���[�h�͎w�肳��Ă��Ȃ�
	moveq.l	#-1,d7			;��ʃ��[�h�͎w�肳��Ă��Ȃ�
	sf.b	(save_to_sram)r		;CRTorLCD���[�h��SRAM�ɕۑ����Ȃ�
	lea.l	1(a2),a0
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;-,/�ȊO
		addq.l	#1,a0
		move.b	(a0)+,d0
		goto	eq,usage_exit		;-,/�̌�ɕ������Ȃ�
		bsr	tolower
		if	<cmp.b #'l',d0>,eq	;-l
			goto	<tst.l d6>,pl,usage_exit	;CRTorLCD���[�h�͊��Ɏw�肳��Ă���
			bsr	nextword
			bsr	stou
			gotoor	<>,cs,<cmp.l #1,d0>,hi,usage_exit	;10�i�����Ȃ����͈͊O
			move.l	d0,d6			;CRTorLCD���[�h���w�肳�ꂽ
		elif	<cmp.b #'m',d0>,eq	;-m
			goto	<tst.l d7>,pl,usage_exit	;��ʃ��[�h�͊��Ɏw�肳��Ă���
			bsr	nextword
			bsr	stou
			gotoor	<>,cs,<cmp.l #MAX_SCREEN_MODE,d0>,hi,usage_exit	;10�i�����Ȃ����͈͊O
			move.l	d0,d7			;��ʃ��[�h���w�肳�ꂽ
		elif	<cmp.b #'s',d0>,eq	;-s
			st.b	(save_to_sram)r		;CRTorLCD���[�h��SRAM�ɕۑ�����
		else				;-l,-m,-s�ȊO
			goto	usage_exit
		endif
	start
		bsr	nextword
	while	ne
	goto	<tst.l d7>,mi,usage_exit	;��ʃ��[�h���w�肳��Ă��Ȃ�
	gotoand	<tst.l d6>,mi,<tst.b (save_to_sram)r>,ne,usage_exit	;CRTorLCD���[�h���w�肳��Ă��Ȃ��̂�SRAM�ɕۑ��ł��Ȃ�
;<d6.l:CRTorLCD���[�h�B0=CRT����,1=LCD����,-1=�w�肳��Ă��Ȃ�
;<d7.l:��ʃ��[�h

;�X�[�p�[�o�C�U���[�h�ֈڍs����
	supervisormode

;CRTorLCD���[�h��ۑ�����
	move.w	#$16FF,d1
	IOCS	_CRTMOD
	rol.l	#8,d0
	cmp.b	#$96,d0
	seq.b	(saved_crtlcd)r

;CRTorLCD���[�h��ύX����
	if	<tst.l d6>,pl		;CRTorLCD���[�h���w�肳��Ă���
		if	eq			;CRT����
			move.w	#$43FF,d1
		else				;LCD����
			move.w	#$4CFF,d1
		endif
		IOCS	_CRTMOD			;CRTorLCD���[�h��ύX����
	endif

;��ʃ��[�h��ݒ肷��
	move.l	d7,d1			;��ʃ��[�h
	IOCS	_CRTMOD
	IOCS	_G_CLR_ON

;�����W�߂�
;��ʃ��[�h
	moveq.l	#0,d0
	move.b	BIOS_CRTMOD.w,(screen_mode)r
;CRTorLCD���[�h
	move.w	#$16FF,d1
	IOCS	_CRTMOD
	rol.l	#8,d0
	cmp.b	#$96,d0
	seq.b	(crtlcd_mode)r
;�O���t�B�b�N�y�[�W��
	move.b	BIOS_GRAPHIC_PAGES.w,d0
	move.b	d0,(pages)r
;BG�T�C�Y
	move.w	SPRC_RESOLUTION,d0
	btst.l	#0,d0
	sne.b	(bg_size)r
;�X�v���C�g��ʂ̗L��
	moveq.l	#%10010,d0
	and.w	CRTC_MODE_RESOLUTION,d0
	cmp.w	#%10010,d0
	sne.b	(sprite_exists)r
;��ʂ̕�
	move.w	BIOS_GRAPHIC_RIGHT.w,d0
	addq.w	#1,d0
	move.w	BIOS_CONSOLE_RIGHT.w,d1
	addq.w	#1,d1
	lsl.w	#3,d1
	if	<cmp.w d1,d0>,lo
		move.w	d1,d0
	endif
	move.w	d0,(screen_width)r
;��ʂ̍���
	moveq.l	#0,d0
	move.w	BIOS_GRAPHIC_BOTTOM.w,d0
	addq.l	#1,d0
	moveq.l	#0,d1
	move.w	BIOS_CONSOLE_BOTTOM.w,d1
	addq.w	#1,d1
	lsl.w	#4,d1
	if	<cmp.l d1,d0>,lo
		move.l	d1,d0
	endif
	move.w	d0,(screen_height)r
;�X�v���C�g��ʂ̍���
	move.w	(screen_height)r,(sprite_height)r
	ifand	<cmpi.b #44,(screen_mode)r>,hs,<cmpi.b #MAX_SCREEN_MODE,(screen_mode)r>,ls
		lsl.w	(sprite_height)r	;��ʃ��[�h44�`47�̓X�v���C�g��ʂ̍�����2�{�ɂ���
	endif
;����ʃT�C�Y
	move.l	BIOS_GRAPHIC_Y_OFFSET.w,d0
	lsr.l	#1,d0
	move.w	d0,(real_size)r
;�O���t�B�b�N�F��
	moveq.l	#0,d0
	move.w	BIOS_GRAPHIC_PALETS.w,d0
	addq.l	#1,d0
	move.l	d0,(palets)r

;���[�U���[�h�֕��A����
	usermode

;�e�L�X�g��ʂ�`��
;�p���b�g��ݒ肷��
	moveq.l	#3,d1			;�p���b�g�R�[�h
	move.w	(text_color)r,d2	;�J���[�R�[�h
	IOCS	_TPALET
;��ʃ��[�h��\������
	lea.l	(string_buffer)r,a0
	movestr	'CRTMOD(',a1
	bsr	strcpy
	moveq.l	#0,d0
	move.b	(screen_mode)r,d0
	bsr	utos
	if	<tst.b (crtlcd_mode)r>,eq
		movestr	') CRT',a1
	else
		movestr	') LCD',a1
	endif
	bsr	strcpy
	moveq.l	#3,d1			;�p���b�g�R�[�h
	moveq.l	#2,d2			;X���W
	moveq.l	#TEXT_LINE-2,d3		;Y���W
	lea.l	(string_buffer)r,a1	;������
	move.l	a0,d4
	sub.l	a1,d4
	subq.w	#1,d4			;����-1
	IOCS	_B_PUTMES
;��ʃT�C�Y��\������
	lea.l	(string_buffer)r,a0
	moveq.l	#0,d0
	move.w	(screen_width)r,d0
	bsr	utos
	move.b	#'x',(a0)+
	moveq.l	#0,d0
	move.w	(screen_height)r,d0
	bsr	utos
	move.b	#'/',(a0)+
	moveq.l	#0,d0
	move.w	(real_size)r,d0
	bsr	utos
	move.b	#'x',(a0)+
	moveq.l	#0,d0
	move.w	(real_size)r,d0
	bsr	utos
	move.b	#' ',(a0)+
	move.l	(palets)r,d0
	bsr	utos
	move.b	#' ',(a0)+
	moveq.l	#0,d0
	move.b	(pages)r,d0
	bsr	utos
	moveq.l	#3,d1			;�p���b�g�R�[�h
	moveq.l	#2,d2			;X���W
	moveq.l	#TEXT_LINE-1,d3		;Y���W
	lea.l	(string_buffer)r,a1	;������
	move.l	a0,d4
	sub.l	a1,d4
	subq.w	#1,d4			;����-1
	IOCS	_B_PUTMES
;TEXT�Ə���
	moveq.l	#3,d1			;�p���b�g�R�[�h
	moveq.l	#2,d2			;X���W
	moveq.l	#TEXT_LINE,d3		;Y���W
	moveq.l	#8-1,d4			;����-1
	movestr	'�s�d�w�s',a1		;������
	IOCS	_B_PUTMES

;�O���t�B�b�N��ʂ�`��
;�p���b�g��ݒ肷��
	if	<cmp.l #65536,(palets)r>,lo
		moveq.l	#0,d1			;�p���b�g�R�[�h0
		moveq.l	#0,d2			;�J���[�R�[�h
		IOCS	_GPALET
		lea.l	(graphic_color)r,a0
		moveq.l	#1,d3
		do
			move.w	d3,d1			;�p���b�g�R�[�h1�`4
			move.w	(a0)+,d2		;�J���[�R�[�h
			IOCS	_GPALET
			addq.w	#1,d3
		while	<cmp.w #4,d3>,ls
	endif
;�g��`��
	move.w	#$F0F0,-(sp)		;���C���X�^�C��
	moveq.l	#1,d0
	if	<cmp.l #65536,(palets)r>,eq
		move.w	(graphic_color)r,d0
	endif
	move.w	d0,-(sp)		;�p���b�g�R�[�h
	move.w	(screen_height)r,d0
	subq.w	#1,d0
	move.w	d0,-(sp)		;�I�_Y���W
	move.w	(screen_width)r,d0
	subq.w	#1,d0
	move.w	d0,-(sp)		;�I�_X���W
	clr.w	-(sp)			;�n�_Y���W
	clr.w	-(sp)			;�n�_X���W
	moveq.l	#2-1,d1			;�O��,����
	for	d1
		movea.l	sp,a1
		IOCS	_BOX
		addq.w	#4,(sp)			;�n�_X���W
		addq.w	#4,2(sp)		;�n�_Y���W
		subq.w	#4,4(sp)		;�I�_X���W
		subq.w	#4,6(sp)		;�I�_Y���W
	next
	lea.l	12(sp),sp
;GRAPHIC PAGE 0/1/2/3�Ə���
	moveq.l	#0,d5			;�y�[�W�ԍ� 0,1,2,3
	do
	;����������
		lea.l	(string_buffer)r,a0
		movestr	'�f�q�`�o�g�h�b�@�o�`�f�d�@',a1
		bsr	strcpy
		move.w	#'�O',d0
		add.w	d5,d0
		rol.w	#8,d0
		move.b	d0,(a0)+
		rol.w	#8,d0
		move.b	d0,(a0)+
		clr.b	d0
	;�y�[�W��I������
		move.l	d5,d1
		IOCS	_APAGE
	;�`��
		move.w	#1<<8|0,-(sp)		;�T�C�Y:�p�x
		moveq.l	#1,d0
		add.w	d5,d0
		if	<cmp.l #65536,(palets)r>,eq
			move.w	d5,d0
			lea.l	(graphic_color)r,a0
			add.w	d0,d0
			move.w	(a0,d0.w),d0
		endif
		move.w	d0,-(sp)		;�p���b�g�R�[�h
		move.w	#1<<8|1,-(sp)		;X�����̔{��:Y�����̔{��
		pea.l	(string_buffer)r	;������
		moveq.l	#GRAPHIC_LINE,d0
		add.w	d5,d0
		lsl.w	#4,d0
		move.w	d0,-(sp)		;Y���W
		move.w	#8*2,-(sp)		;X���W
		movea.l	sp,a1
		IOCS	_SYMBOL
		lea.l	14(sp),sp
		addq.w	#1,d5
	while	<cmp.b (pages)r,d5>,lo

;�X�v���C�g��ʂ�`��
	if	<tst.b (sprite_exists)r>,ne	;�X�v���C�g��ʂ���
	;����������
		IOCS	_SP_INIT
		IOCS	_SP_ON
	;�p���b�g��ݒ肷��
		lea.l	(sprite_color)r,a0
		moveq.l	#1,d4			;�p���b�g�u���b�N 1,2,3
		do
			moveq.l	#0,d1			;�p���b�g�R�[�h
			move.l	d4,d2			;�p���b�g�u���b�N
			moveq.l	#0,d3			;�J���[�R�[�h
			IOCS	_SPALET
			moveq.l	#1,d1			;�p���b�g�R�[�h
			move.l	d4,d2			;�p���b�g�u���b�N
			move.w	(a0)+,d3		;�J���[�R�[�h
			IOCS	_SPALET
			addq.w	#1,d4
		while	<cmp.w #3,d4>,ls
	;�}�`�p�^�[�����`����
		moveq.l	#2,d1			;�p�^�[���ԍ� 2
		moveq.l	#1,d2			;�T�C�Y 16x16
		lea.l	(sprite_pattern)r,a1	;�X�v���C�g�p�^�[��
		IOCS	_SP_DEFCG		;�p�^�[�����`����
	;�����p�^�[�����`����
	;		  3 4 5 6 7 8 910111213141516171819202122
		movestr	'�r�o�q�h�s�d�a�`�b�j�|�f�q�n�t�m�c�@�O�P',a4
		moveq.l	#3,d6			;�p�^�[���ԍ�
		dostart
			lsl.w	#8,d1
			move.b	(a4)+,d1		;�����R�[�h����
			moveq.l	#8,d2			;�T�C�Y 16x16
			lea.l	(font_buffer)r,a1	;�t�H���g�o�b�t�@
			IOCS	_FNTGET			;�t�H���g�f�[�^�����o��
			lea.l	(pattern_buffer)r,a0	;�p�^�[���o�b�t�@
			moveq.l	#0,d7			;0�Œ�
			moveq.l	#-2,d5			;-2=������,-1=�E����
			do
				lea.l	(font_buffer+4)r,a1	;�t�H���g�f�[�^�̖{��
				moveq.l	#16-1,d3		;�c16�h�b�g
				for	d3
				;	moveq.l	#0,d0
					move.b	2(a1,d5.w),d1		;�������܂��͉E����
					moveq.l	#8-1,d2			;��8�h�b�g
					for	d2
						lsl.l	#4,d0			;0��0000�ɁA1��0001�ɂ���
						add.b	d1,d1			;d1.b�̏�ʂ��牟���o����
						addx.b	d7,d0			;d0.l�̉��ʂ։�������
					next
					move.l	d0,(a0)+		;�p�^�[���f�[�^
					addq.l	#2,a1
				next
				addq.w	#1,d5
			while	ne
			move.w	d6,d1			;�p�^�[���ԍ�
			moveq.l	#1,d2			;�T�C�Y 16x16
			lea.l	(pattern_buffer)r,a1	;�p�^�[���f�[�^
			IOCS	_SP_DEFCG		;�p�^�[�����`����
			addq.w	#1,d6			;���̃p�^�[���ԍ�
		start
			moveq.l	#0,d1
			move.b	(a4)+,d1		;�����R�[�h���
		while	ne
	;�l���̃X�v���C�g��\������
		moveq.l	#0,d6			;�ʒu=�X�v���C�g�ԍ� 0=����,1=�E��,2=����,3=�E��
		do
			move.l	d6,d1			;�X�v���C�g�ԍ� 0,1,2,3
			moveq.l	#16,d2			;X���W���[
			if	<btst.l #0,d6>,ne
				move.w	(screen_width)r,d2	;X���W�E�[
			endif
			moveq.l	#16,d3			;Y���W��[
			if	<btst.l #1,d6>,ne
				move.w	(sprite_height)r,d3	;Y���W���[
			endif
			move.w	#1<<8|2,d4		;�p���b�g�u���b�N:�p�^�[���ԍ� 1:2
			moveq.l	#3,d5			;�v���C�I���e�B 3
			IOCS	_SP_REGST
			addq.w	#1,d6			;���̈ʒu=�X�v���C�g�ԍ�
		while	<cmp.w #3,d6>,ls
	;SPRITE�Ə���
		moveq.l	#16+16*1,d2
		movea.l	d2,a2			;X���W
		moveq.l	#SPRITE_LINE,d3
		move.w	(screen_height)r,d0
		if	<cmp.w (sprite_height)r,d0>,ne
			add.w	d3,d3
		endif
		lsl.w	#4,d3
		add.w	#16,d3
		movea.l	d3,a3			;Y���W
	;		 S P R I T E
		movestr	<3,4,5,6,7,8>,a4	;�p�^�[���ԍ�
		moveq.l	#4,d7			;�X�v���C�g�ԍ�
		dostart
			move.l	d7,d1			;�X�v���C�g�ԍ�
			move.w	a2,d2			;X���W
			move.w	a3,d3			;Y���W
			move.w	#1<<8,d4
			move.b	d0,d4			;�p���b�g�u���b�N:�p�^�[���ԍ�
			moveq.l	#3,d5			;�v���C�I���e�B 3
			IOCS	_SP_REGST
			addq.w	#1,d7			;���̃X�v���C�g�ԍ�
			adda.w	#16,a2			;����X���W
		start
			moveq.l	#0,d0
			move.b	(a4)+,d0		;�p�^�[���ԍ�
		while	ne
	;BG��`��
		if	<tst.b (bg_size)r>,eq	;8x8/512x512x2
			moveq.l	#0,d5			;BG�e�L�X�g�G���A 0,1
			do
			;�g�̃p�^�[�����`����
				move.l	d5,d1
				addq.w	#2,d1			;�p�^�[���ԍ� 2,3
				moveq.l	#0,d2			;�T�C�Y 8x8
				lea.l	(bg_pattern_8x8)r,a1
				move.l	d5,d0
				lsl.w	#5,d0
				adda.l	d0,a1			;�p�^�[���f�[�^
				IOCS	_SP_DEFCG
			;�g�̃p�^�[���œh��ׂ�
				move.l	d5,d1			;BG�e�L�X�g�G���A 0,1
				move.l	d5,d2
				addq.w	#2,d2			;�p�^�[���ԍ�=�p���b�g�u���b�N 2,3
				move.b	d2,d0
				lsl.w	#8,d2
				move.b	d0,d2			;�p���b�g�u���b�N:�p�^�[���ԍ� 2:2,3:3
				IOCS	_BGTEXTCL
			;�g���c���ē��������蔲��
				move.l	d5,d1			;BG�e�L�X�g�G���A 0,1
				moveq.l	#0<<8|0,d4		;�p���b�g�u���b�N:�p�^�[���ԍ� 0:0
				moveq.l	#1,d3			;BG�e�L�X�gY���W�B�g��1��
				move.w	(sprite_height)r,d7
				lsr.w	#3,d7			;8x8���c�ɕ��Ԑ�
				subq.w	#2+1,d7			;�g��2��
				for	d7			;�c
					moveq.l	#1,d2			;BG�e�L�X�gX���W�B�g��1��
					move.w	(screen_width)r,d6
					lsr.w	#3,d6			;8x8�����ɕ��Ԑ�
					subq.w	#2+1,d6			;�g��2��
					for	d6			;��
						IOCS	_BGTEXTST
						addq.w	#1,d2			;����BG�e�L�X�gX���W
					next
					addq.w	#1,d3			;����BG�e�L�X�gY���W
				next
			;BACK-GROUND 0/1�Ə���
				moveq.l	#2*1,d2
				movea.l	d2,a2			;X���W
				moveq.l	#BG_LINE,d3
				add.w	d5,d3
				move.w	(screen_height)r,d0
				if	<cmp.w (sprite_height)r,d0>,ne
					add.w	d3,d3
				endif
				add.w	d3,d3
				movea.l	d3,a3			;Y���W
			;		 B  A  C  K  -  G  R  O  U  N  D     0
				movestr	<9,10,11,12,13,14,15,16,17,18,19,20,21>,a4	;�p�^�[���ԍ�
				dostart
					move.l	d5,d4
					addq.b	#2,d4			;�p���b�g�u���b�N 2,3
					lsl.w	#8,d4
					if	<cmp.b #21,d0>,eq	;0/1
						add.b	d5,d0			;21(0)��22(1)
					endif
					move.b	d0,d4			;�p���b�g�u���b�N:16x16�p�^�[���ԍ�
					lsl.b	#2,d4			;�p���b�g�u���b�N:8x8�p�^�[���ԍ�
					moveq.l	#4-1,d6			;����,����,�E��,�E��
					for	d6
						move.l	d5,d1			;BG�e�L�X�g�G���A 0,1
						moveq.l	#2,d2
						and.b	d4,d2
						lsr.w	#1,d2
						add.w	a2,d2			;BG�e�L�X�gX���W
						moveq.l	#1,d3
						and.b	d4,d3
						add.w	a3,d3			;BG�e�L�X�gY���W
						IOCS	_BGTEXTST
						addq.b	#1,d4			;����8x8�p�^�[���ԍ�
					next
					addq.w	#2,a2			;BG�e�L�X�gX���W
				start
					moveq.l	#0,d0
					move.b	(a4)+,d0		;�p�^�[���ԍ�
				while	ne
			;�\��ON
				move.l	d5,d1			;BG�y�[�W 0,1
				move.l	d5,d2			;BG�e�L�X�g�G���A 0,1
				moveq.l	#1,d3			;�\��ON
				IOCS	_BGCTRLST
			;
				addq.w	#1,d5			;����BG�e�L�X�g�G���A
			while	<cmp.w #1,d5>,ls
		else				;16x16/1024x1024x1
		;�g�̃p�^�[�����`����
			moveq.l	#1,d1			;�p�^�[���ԍ� 1
			moveq.l	#1,d2			;�T�C�Y 16x16
			lea.l	(bg_pattern_16x16)r,a1	;�p�^�[���f�[�^
			IOCS	_SP_DEFCG
		;�g�̃p�^�[���œh��ׂ�
			moveq.l	#0,d1			;BG�e�L�X�g�G���A 0
			move.w	#2<<8|1,d2		;�p���b�g�u���b�N:�p�^�[���ԍ� 2:1
			IOCS	_BGTEXTCL
		;�g���c���ē��������蔲��
			moveq.l	#0,d1			;BG�e�L�X�g�G���A 0
			move.w	#0<<8|0,d4		;�p���b�g�u���b�N:�p�^�[���ԍ� 0:0
			moveq.l	#1,d3			;BG�e�L�X�gY���W�B�g��1��
			move.w	(sprite_height)r,d7
			lsr.w	#4,d7			;16x16���c�ɕ��Ԑ�
			subq.w	#2+1,d7			;�g��2��
			for	d7			;�c
				moveq.l	#1,d2			;BG�e�L�X�gX���W�B�g��1��
				move.w	(screen_width)r,d6
				lsr.w	#4,d6			;16x16�����ɕ��Ԑ�
				subq.w	#2+1,d6			;�g��2��
				for	d6			;��
					IOCS	_BGTEXTST
					addq.w	#1,d2			;����BG�e�L�X�gX���W
				next
				addq.w	#1,d3			;����BG�e�L�X�gY���W
			next
		;BACK-GROUND 0�Ə���
			moveq.l	#1*1,d2
			move.l	d2,a2			;X���W
			moveq.l	#BG_LINE,d3
			move.w	(screen_height)r,d0
			if	<cmp.w (sprite_height)r,d0>,ne
				add.w	d3,d3
			endif
			movea.l	d3,a3			;Y���W
		;		 B  A  C  K  -  G  R  O  U  N  D     0
			movestr	<9,10,11,12,13,14,15,16,17,18,19,20,21>,a4	;�p�^�[���ԍ�
			dostart
				move.w	#2<<8,d4
				move.b	d0,d4			;�p���b�g�u���b�N:�p�^�[���ԍ�
				moveq.l	#0,d1			;BG�e�L�X�g�G���A 0
				move.w	a2,d2			;BG�e�L�X�gX���W
				move.w	a3,d3			;BG�e�L�X�gY���W
				IOCS	_BGTEXTST
				addq.w	#1,a2			;BG�e�L�X�gX���W
			start
				moveq.l	#0,d0
				move.b	(a4)+,d0		;�p�^�[���ԍ�
			while	ne
		;�\��ON
			moveq.l	#0,d1			;BG�y�[�W 0
			moveq.l	#0,d2			;BG�e�L�X�g�G���A 0
			moveq.l	#1,d3			;�\��ON
			IOCS	_BGCTRLST
		endif
	endif

;�L�[���͂�҂��Ă����ʃ��[�h�𕜌�����
	IOCS	_B_CUROFF
	DOS	_GETC
	if	<cmp.b #27,d0>,eq	;ESC�L�[�������ꂽ�Ƃ�
	;�X�v���C�g��ʂƃO���t�B�b�N��ʂ�OFF�ɂ���
		moveq.l	#$0020,d1
		IOCS	_CRTMOD2
	;�e�L�X�g��ʂ���������
		moveq.l	#2,d1
		IOCS	_B_CLR_ST
	;�e�L�X�g�p���b�g�𕜌�����
		moveq.l	#3,d1
		moveq.l	#-2,d2
		IOCS	_TPALET
	else				;ESC�L�[�ȊO�������ꂽ�Ƃ�
	;CRTorLCD���[�h�𕜌�����
		if	<tst.b (save_to_sram)r>,eq	;CRTorLCD���[�h��SRAM�ɕۑ����Ȃ�
			if	<tst.b (saved_crtlcd)r>,eq	;CRT����������
				move.w	#$43FF,d1
			else				;LCD����������
				move.w	#$4CFF,d1
			endif
			IOCS	_CRTMOD			;CRTorLCD���[�h�𕜌�����
		endif
	;OS�̉�ʃ��[�h�𕜌�����
		move.l	#(16<<16)|$FFFF,-(sp)
		DOS	_CONCTRL
		move.w	d0,2(sp)
		DOS	_CONCTRL
		addq.l	#4,sp
	endif
	IOCS	_B_CURON

;�I������
exit:
	DOS	_EXIT

;�^�C�g���Ǝg�p�@��\�����ďI������
usage_exit:
	lea.l	title_usage(pc),a0
	bsr	more
	goto	exit

;�^�C�g���Ǝg�p�@
title_usage:
	.dc.b	TITLE_STRING,13,10
	.dc.b	'�I�v�V����',13,10
	.dc.b	'  -l 0-1   CRTorLCD���[�h�B0=CRT����,1=LCD����',13,10
	.dc.b	'  -m 0-47  ��ʃ��[�h',13,10
	.dc.b	'  -s       -l�Ŏw�肵��CRTorLCD���[�h��SRAM�ɕۑ�����',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��CRTMOD������ʃT�C�Y �F �y�[�W��        ��������  ��������  ��ʃT�C�Y      ���l      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��   0  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��   4  ��  512x512      16  4  ��  CRT  31.500kHz  55.458Hz   512x512                  ��',13,10
	.dc.b	'  ��   8  ��  512x512     256  2  ��  LCD  35.341kHz  56.546Hz   512x512                  ��',13,10
	.dc.b	'  ��  12  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��   1  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��   5  ��  512x512      16  4  ��  CRT  15.980kHz  61.463Hz   512x480   �C���^�[���[�X ��',13,10
	.dc.b	'  ��   9  ��  512x512     256  2  ��  LCD  35.341kHz  56.546Hz   512x480                  ��',13,10
	.dc.b	'  ��  13  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��   2  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��   6  ��  512x512      16  4  ��  CRT  31.500kHz  55.458Hz   256x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  10  ��  512x512     256  2  ��  LCD  34.500kHz  55.200Hz   256x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  14  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��   3  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��   7  ��  512x512      16  4  ��  CRT  15.980kHz  61.463Hz   256x240                  ��',13,10
	.dc.b	'  ��  11  ��  512x512     256  2  ��  LCD  34.500kHz  55.200Hz   256x240   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  15  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  16  �� 1024x1024     16  1  ��  CRT  31.500kHz  55.458Hz   768x512                  ��',13,10
	.dc.b	'  ��  20  ��  512x512     256  2  ��  LCD  35.056kHz  56.090Hz   768x512                  ��',13,10
	.dc.b	'  ��  24  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  17  �� 1024x1024     16  1  ��  CRT  24.699kHz  53.116Hz  1024x424                  ��',13,10
	.dc.b	'  ��  21  ��  512x512     256  2  ��  LCD  35.056kHz  56.090Hz   768x600                  ��',13,10
	.dc.b	'  ��  25  ��  512x512   65536  1  ��                               �ό`                   ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  18  �� 1024x1024     16  1  ��  CRT  24.699kHz  53.116Hz  1024x848   �C���^�[���[�X ��',13,10
	.dc.b	'  ��  22  ��  512x512     256  2  ��  LCD  35.056kHz  56.090Hz   768x1024  �C���^�[���[�X ��',13,10
	.dc.b	'  ��  26  ��  512x512   65536  1  ��                               �ό`                   ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  19  �� 1024x1024     16  1  ��  CRT  31.500kHz  55.458Hz   640x480   VGA�ł͂Ȃ�    ��',13,10
	.dc.b	'  ��  23  ��  512x512     256  2  ��  LCD  31.469kHz  59.940Hz   640x480   VGA            ��',13,10
	.dc.b	'  ��  27  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  28  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��  29  ��  512x512      16  4  ��  CRT  31.963kHz  56.273Hz   384x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  30  ��  512x512     256  2  ��  LCD  31.963kHz  51.141Hz   384x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  31  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  32  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��  33  ��  512x512      16  4  ��  CRT  31.500kHz  55.458Hz   512x512                  ��',13,10
	.dc.b	'  ��  34  ��  512x512     256  2  ��  LCD  35.056kHz  56.090Hz   512x512                  ��',13,10
	.dc.b	'  ��  35  ��  512x512   65536  1  ��                              �����`                  ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  36  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��  37  ��  512x512      16  4  ��  CRT  31.963kHz  56.273Hz   256x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  38  ��  512x512     256  2  ��  LCD  31.963kHz  51.141Hz   256x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  39  ��  512x512   65536  1  ��                              �����`                  ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  40  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��  41  ��  512x512      16  4  ��  CRT  31.500kHz  55.458Hz   512x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  42  ��  512x512     256  2  ��  LCD  35.341kHz  56.546Hz   512x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  43  ��  512x512   65536  1  ��                                                      ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	'  ��  44  �� 1024x1024     16  1  ��                                                      ��',13,10
	.dc.b	'  ��  45  ��  512x512      16  4  ��  CRT  31.500kHz  55.458Hz   512x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  46  ��  512x512     256  2  ��  LCD  35.341kHz  56.546Hz   512x256   ���X�^2�x�ǂ�  ��',13,10
	.dc.b	'  ��  47  ��  512x512   65536  1  ��                       �X�v���C�g��512x512            ��',13,10
	.dc.b	'  ������������������������������������������������������������������������������������������',13,10
	.dc.b	0
	.even

;�F
text_color:	dchsv	0,24,31
graphic_color:	dchsv	24,24,31
		dchsv	48,24,31
		dchsv	72,24,31
		dchsv	96,24,31
sprite_color:	dchsv	120,24,31
		dchsv	144,24,31
		dchsv	168,24,31

;BG�p�^�[��
bg_pattern_8x8:
	.dc.l	$00110011		;BG0
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000

	.dc.l	$00000000		;BG1
	.dc.l	$00000000
	.dc.l	$11001100
	.dc.l	$11001100
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$11001100
	.dc.l	$11001100

bg_pattern_16x16:
	.dc.l	$00110011		;������
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000

	.dc.l	$00110011		;�E����
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$00000000
	.dc.l	$00000000

;�X�v���C�g�p�^�[��
sprite_pattern:
	.dc.l	$00001111		;������
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000

	.dc.l	$00001111		;�E����
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$00001111
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000
	.dc.l	$11110000

	.bss

save_to_sram:	.ds.b	1		;CRTorLCD���[�h��SRAM�ɕۑ����邩�B0=���Ȃ�,-1=����
saved_crtlcd:	.ds.b	1		;���̉�ʃ��[�h
screen_mode:	.ds.b	1		;��ʃ��[�h
crtlcd_mode:	.ds.b	1		;CRTorLCD���[�h�B0=CRT����,-1=LCD����
pages:		.ds.b	1		;�O���t�B�b�N�y�[�W��
bg_size:	.ds.b	1		;BG�T�C�Y�B0=8x8/512x512x2,-1=16x16/1024x1024x1
sprite_exists:	.ds.b	1		;�X�v���C�g��ʂ̗L���B0=�Ȃ�,-1=����
	.even
screen_width:	.ds.w	1		;��ʂ̕�
screen_height:	.ds.w	1		;��ʂ̍���
sprite_height:	.ds.w	1		;�X�v���C�g��ʂ̍���
real_size:	.ds.w	1		;����ʃT�C�Y
palets:		.ds.l	1		;�O���t�B�b�N�F��
font_buffer:	.ds.w	2+2+3*24	;�t�H���g�o�b�t�@
pattern_buffer:	.ds.l	8*4		;�X�v���C�g�p�^�[���o�b�t�@
string_buffer:	.ds.b	256		;������o�b�t�@

	.text



;----------------------------------------------------------------
;-more-�����݂Ȃ��當�����\������
;<a0.l:������
more::
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
;���s��\������
printcrlf::
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	bsr	print
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;10�i���̕�����𕄍��Ȃ������ɕϊ�����
;<a0.l:10�i���̕�����B�擪�̋󔒂͔F�߂Ȃ�
;>d0.l:(cc�̂Ƃ�)�����Ȃ������B(cs�̂Ƃ�)0=10�i���̕������Ȃ�,-1=�I�[�o�[�t���[
;>a0.l:(cc�̂Ƃ�)10�i���̕�����̎��̈ʒu�B(cs�̂Ƃ�)�ω����Ȃ�
;>z:(cc�̂Ƃ�)eq=�����Ȃ�������0
;>v:(cs�̂Ƃ�)vc=10�i���̕������Ȃ�,vs=�I�[�o�[�t���[
;>c:cs=10�i���̕������Ȃ��܂��̓I�[�o�[�t���[
stou::
	push	d1-d2/a1
	moveq.l	#0,d0			;�����Ȃ�����
	moveq.l	#0,d1			;����
	movea.l	a0,a1			;�J�n�ʒu
	dostart
		goto	<cmp.l #$1999999A,d0>,hs,20f	;10�{������I�[�o�[�t���[����
		move.l	d0,d2			;1�{
		lsl.l	#2,d0			;4�{
		add.l	d2,d0			;5�{
		add.l	d0,d0			;10�{����
		add.l	d1,d0			;1��������
		goto	cs,20f			;�I�[�o�[�t���[����
	start
		move.b	(a0)+,d1		;���̕���
		sub.b	#'0',d1			;�����ɂ���
	whileand	<>,hs,<cmp.b #10,d1>,lo	;10�i���̕����Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	goto	<cmpa.l a1,a0>,eq,30f	;�i��ł��Ȃ��B10�i���̕������Ȃ�
	tst.l	d0			;ne/eq,vc,cc
10:	pop
	rts

;�I�[�o�[�t���[
20:
  .if 0
	do
		move.b	(a0)+,d1		;���̕���
		sub.b	#'0',d1			;�����ɂ���
	whileand	<>,hs,<cmp.b #10,d1>,lo	;10�i���̕�����ǂݔ�΂�
	subq.l	#1,a0			;�i�݉߂������߂�
  .else
	movea.l	a1,a0			;�J�n�ʒu�ɖ߂�
  .endif
	moveq.l	#-1,d0			;�I�[�o�[�t���[
	move.w	#%00011,ccr		;ne,vs,cs
	goto	10b

;10�i���̕������Ȃ�
30:
;	moveq.l	#0,d0			;10�i���̕������Ȃ�
	move.w	#%00101,ccr		;eq,vc,cs
	goto	10b

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
;�������ɂ���
;<d0.b:����
;>d0.b:����
tolower::
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;�啶��
		add.b	#'a'-'A',d0		;�������ɂ���
	endif
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



	.end

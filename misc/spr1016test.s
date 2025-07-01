;========================================================================================
;  spr1016test.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;spr1016test.x
;	XEiJ�̊g���@�\���e�X�g���܂��B�ȉ��̐ݒ�Ŏ��s���Ă��������B
;	�E�X�v���C�g�̖���1016
;	�E4096�̃p�^�[��
;	�E768x512�ŃX�v���C�g��\��
;	�E���X�^������̃X�v���C�g�̖���1016
;	�Esprdrv.x��g�ݍ���
;	�����L�[�������ƏI�����܂��B
;	X68000���@�ł͓����܂���B
;�X�V����
;	2025-04-07
;		���ŁB
;	2025-04-10
;		IOCS _SP_REGST�̃X�v���C�g�ԍ��̕ύX�ɒǏ]���܂����B
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	forvar.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	sprc.equ

;��ʃ��[�h��ύX����
	move.l	#14<<16|3,-(sp)		;�t�@���N�V�����L�[�\���Ȃ�
	DOS	_CONCTRL
	addq.l	#4,sp
	move.w	d0,-(sp)
	move.l	#16<<16|0,-(sp)		;768x512�O���t�B�b�N�Ȃ�
	DOS	_CONCTRL
	addq.l	#4,sp
	move.w	d0,-(sp)

;�X�v���C�g��ʂ�����������
	move.l	#'SPRD',d1		;�g���@�\���g�p����
	move.l	#2<<1|1,d2		;�p�^�[��4096�A�e�L�X�g�G���A�ړ�����
	IOCS	_SP_INIT

;�O�������
;	x=16+floor(OX+AX*sin(AF*t)-BX*sin(BF*t))
;	y=16+floor(OY+AY*cos(AF*t)+BY*cos(BF*t))
N	equ	1016			;�v�f��
M	equ	23			;������
PI	fset	3.14159265358979323846	;�~����
TI	fequ	2.0*PI/(M*N)		;t/�ʒu�ԍ�
OX	fequ	376.0			;���SX
OY	fequ	248.0			;���SY
RX	fequ	360.0			;�S�̂̔��aX
RY	fequ	240.0			;�S�̂̔��aY
AF	fequ	6.0			;��~�̎��g��
BF	fequ	23.0			;���~�̎��g��
PA	fequ	5.0			;��~�̊���
PB	fequ	2.0			;���~�̊���
AX	fequ	RX*PA/(PA+PB)		;��~�̔��aX
AY	fequ	RY*PA/(PA+PB)		;��~�̔��aY
BX	fequ	RX*PB/(PA+PB)		;���~�̔��aX
BY	fequ	RY*PB/(PA+PB)		;���~�̔��aY
	.data
	.even
ti:	.dc.d	TI
af:	.dc.d	AF
bf:	.dc.d	BF
ax:	.dc.d	AX
bx:	.dc.d	BX
ox:	.dc.d	OX
ay:	.dc.d	AY
by:	.dc.d	BY
oy:	.dc.d	OY
	.bss
	.even
;�O��(�ʒu�ԍ�*4�����W)
orbit:
	.dc.w	2*M*N
	.text
	lea.l	orbit(pc),a0		;�O��
	moveq.l	#0,d7			;d7=i �ʒu�ԍ�
	do
		move.l	d7,d0			;d0=i
		FPACK	__LTOD			;d0d1=i
		movem.l	ti(pc),d2-d3		;d2d3=ti
		FPACK	__DMUL			;d0d1=ti*i=t
		move.l	d0,d4
		move.l	d1,d5			;d4d5=t
		movem.l	af(pc),d2-d3		;d2d3=af
		FPACK	__DMUL			;d0d1=af*t
		movea.l	d0,a2
		movea.l	d1,a3			;a2a3=af*t
		move.l	d4,d0
		move.l	d5,d1			;d0d1=t
		movem.l	bf(pc),d2-d3		;d2d3=bf
		FPACK	__DMUL			;d0d1=bf*t
		movea.l	d0,a4
		movea.l	d1,a5			;a4a5=bf*t
		FPACK	__SIN			;d0d1=sin(bf*t)
		movem.l	bx(pc),d2-d3		;d2d3=bx
		FPACK	__DMUL			;d0d1=bx*sin(bf*t)
		move.l	d0,d4
		move.l	d1,d5			;d4d5=bx*sin(bf*t)
		move.l	a2,d0
		move.l	a3,d1			;d0d1=af*t
		FPACK	__SIN			;d0d1=sin(af*t)
		movem.l	ax(pc),d2-d3		;d2d3=ax
		FPACK	__DMUL			;d0d1=ax*sin(af*t)
		move.l	d4,d2
		move.l	d5,d3			;d2d3=bx*sin(bf*t)
		FPACK	__DSUB			;d0d1=ax*sin(af*t)-bx*sin(bf*t)
		movem.l	ox(pc),d2-d3		;d2d3=ox
		FPACK	__DADD			;d0d1=ox+ax*sin(af*t)-bx*sin(bf*t)
		FPACK	__DFLOOR		;d0d1=floor(ox+ax*sin(af*t)-bx*sin(bf*t))
		FPACK	__DTOL			;d0=floor(ox+ax*sin(af*t)-bx*sin(bf*t))
		add.l	#16,d0			;d0=16+floor(ox+ax*sin(af*t)-bx*sin(bf*t))=x
		move.l	d0,d6			;d6=x
		move.l	a4,d0
		move.l	a5,d1			;d0d1=bf*t
		FPACK	__COS			;d0d1=cos(bf*t)
		movem.l	by(pc),d2-d3		;d2d3=by
		FPACK	__DMUL			;d0d1=by*cos(bf*t)
		move.l	d0,d4
		move.l	d1,d5			;d4d5=by*cos(bf*t)
		move.l	a2,d0
		move.l	a3,d1			;d0d1=af*t
		FPACK	__COS			;d0d1=cos(af*t)
		movem.l	ay(pc),d2-d3		;d2d3=ay
		FPACK	__DMUL			;d0d1=ay*cos(af*t)
		move.l	d4,d2
		move.l	d5,d3			;d2d3=by*cos(bf*t)
		FPACK	__DADD			;d0d1=ay*cos(af*t)+by*cos(bf*t)
		movem.l	oy(pc),d2-d3		;d2d3=oy
		FPACK	__DADD			;d0d1=oy+ay*cos(af*t)+by*cos(bf*t)
		FPACK	__DFLOOR		;d0d1=floor(oy+ay*cos(af*t)+by*cos(bf*t))
		FPACK	__DTOL			;d0=floor(oy+ay*cos(af*t)+by*cos(bf*t))
		add.l	#16,d0			;d0=16+floor(oy+ay*cos(af*t)+by*cos(bf*t))=y
		move.w	d6,(a0)+		;x
		move.w	d0,(a0)+		;y
		addq.l	#1,d7			;i++
	while	<cmp.l	#M*N,d7>,lo

;�p���b�g��ݒ肷��
;	�p���b�g�u���b�N1�`15�A�p���b�g�R�[�h1�`15��225�F���g��
;	j=0�`224	�F�ԍ�
;	h=floor(HJ*j)
;	s=31
;	v=floor(VO+VR*cos(VF*TJ*j))
	.data
	.even
hj:	.dc.d	192.0/225.0
vftj:	.dc.d	AF*2.0*PI/225.0
vr:	.dc.d	10.0
vo:	.dc.d	20.0
;�F�ԍ����p���b�g�u���b�N
color_to_block:
	forvar	i,0,224,<.dc.b (i/15)+1>
;�F�ԍ����p���b�g�R�[�h
color_to_code:
	forvar	i,0,224,<.dc.b (i.mod.15)+1>
	.text
	lea.l	color_to_block(pc),a4	;�F�ԍ����p���b�g�u���b�N
	lea.l	color_to_code(pc),a5	;�F�ԍ����p���b�g�R�[�h
	moveq.l	#0,d7			;d7=j �F�ԍ�
	do
		move.l	d7,d0			;d0=j
		FPACK	__LTOD			;d0d1=j
		move.l	d0,d4
		move.l	d1,d5			;d4d5=j
		movem.l	hj(pc),d2-d3		;d2d3=hj
		FPACK	__DMUL			;d0d1=hj*j
		FPACK	__DFLOOR		;d0d1=floor(hj*j)=h
		FPACK	__DTOL			;d0=h
		move.l	d0,d6			;d6=h
		move.l	d4,d0
		move.l	d5,d1			;d0d1=p
		movem.l	vftj(pc),d2-d3		;d2d3=vf*tj
		FPACK	__DMUL			;d0d1=vf*tj*j=vf*t
		FPACK	__COS			;d0d1=cos(vf*t)
		movem.l	vr(pc),d2-d3		;d2d3=vr
		FPACK	__DMUL			;d0d1=vr*cos(vf*t)
		movem.l	vo(pc),d2-d3		;d2d3=vo
		FPACK	__DADD			;d0d1=vo+vr*cos(vf*t)
		FPACK	__DFLOOR		;d0d1=floor(vo+vr*cos(vf*t))=V
		FPACK	__DTOL			;d0=v
		move.l	d6,d1			;d1=h
		swap.w	d1			;d1=h<<16
		move.w	#31<<8,d1		;d1=h<<16|s<<8
		move.b	d0,d1			;d1=h<<16|s<<8|v
		IOCS	_HSVTORGB		;d0=�J���[�R�[�h
		move.w	d0,d3			;d3=�J���[�R�[�h
		moveq.l	#0,d2
		move.b	(a4,d7.w),d2		;d2=b �p���b�g�u���b�N
		moveq.l	#0,d1
		move.b	(a5,d7.w),d1		;d1=c �p���b�g�R�[�h
		if	<tst.w d7>,ne
			bset.l	#31,d1
		endif
		IOCS	_SPALET
		addq.w	#1,d7			;p++
	while	<cmp.w	#225,d7>,lo

;�p�^�[�����`����
	.data
	.even
;�v�f�ԍ�*2������
elem_to_moji:
	.dc.b	'�����������������������������������������������������������������������ÈĈňƈǈȈɈʈˈ͈̈Έψ�'
	.dc.b	'�ш҈ӈԈՈֈ׈؈وڈۈ܈݈ވ߈���������������������������������������@�A�B�C�D�E'
	.dc.b	'�F�G�H�I�J�K�L�M�N�O�P�Q�R�S�T�U�V�W�X�Y�Z�[�\�]�^�_�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w'
	.dc.b	'�x�y�z�{�|�}�~��������������������������������������������������������������������������������������'
	.dc.b	'�����������������������������������������������ÉĉŉƉǉȉɉʉˉ͉̉ΉωЉщ҉ӉԉՉ։׉؉ىډۉ�'
	.dc.b	'�݉މ߉���������������������������������������@�A�B�C�D�E�F�G�H�I�J�K�L�M�N�O�P�Q'
	.dc.b	'�R�S�T�U�V�W�X�Y�Z�[�\�]�^�_�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y�z�{�|�}�~����������'
	.dc.b	'����������������������������������������������������������������������������������������������������'
	.dc.b	'�����������������������ÊĊŊƊǊȊɊʊˊ̊͊ΊϊЊъҊӊԊՊ֊׊؊يڊۊ܊݊ފߊ����������'
	.dc.b	'������������������������������@�A�B�C�D�E�F�G�H�I�J�K�L�M�N�O�P�Q�R�S�T�U�V�W�X�Y�Z�[�\�]'
	.dc.b	'�^�_�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y�z�{�|�}�~����������������������������������'
	.dc.b	'����������������������������������������������������������������������������������������������������'
	.dc.b	'�ËċŋƋǋȋɋʋˋ̋͋΋ϋЋыҋӋԋՋ֋׋؋ًڋۋ܋݋ދߋ�����������������������'
	.dc.b	'�����������������@�A�B�C�D�E�F�G�H�I�J�K�L�M�N�O�P�Q�R�S�T�U�V�W�X�Y�Z�[�\�]�^�_�`�a�b�c�d�e�f�g�h�i'
	.dc.b	'�j�k�l�m�n�o�p�q�r�s�t�u�v�w�x�y�z�{�|�}�~����������������������������������������������������������'
	.dc.b	'���������������������������������������������������������������������������ÌČŌƌǌȌɌʌˌ̌͌�'
	.dc.b	'�όЌьҌӌԌՌ֌׌،ٌڌی܌݌ތߌ���������������������������������������@�A�B�C'
	.dc.b	'�D�E�F�G�H�I�J�K�L�M�N�O�P�Q�R�S�T�U�V�W�X�Y�Z�[�\�]�^�_�`�a�b�c�d�e�f�g�h�i�j�k�l�m�n�o�p�q�r�s�t�u'
	.dc.b	'�v�w�x�y�z�{�|�}�~����������������������������������������������������������������������������������'
	.dc.b	'���������������������������������������������������ÍčōƍǍȍɍʍˍ͍̍΍ύЍэҍӍԍՍ֍׍؍ٍ�'
	.dc.b	'�ۍ܍ݍލߍ������������'
;�v�f�ԍ����p���b�g�R�[�h
elem_to_code:
	forvar	i,0,N-1,<.dc.b ((i*225/N).mod.15)+1>
	.text
	lea.l	-(4+2*16+4*32)(sp),sp	;�t�H���g�T�C�Y�A�t�H���g�f�[�^�A�p�^�[���f�[�^
	lea.l	elem_to_moji(pc),a3	;�v�f�ԍ�*2������
	lea.l	elem_to_code(pc),a5	;�v�f�ԍ����p���b�g�R�[�h
	moveq.l	#0,d4			;�v�f�ԍ�
	do
	;�t�H���g�f�[�^�𓾂�
		move.w	(a3)+,d1		;����
		moveq.l	#0,d2			;16x16
		movea.l	sp,a1			;�t�H���g�T�C�Y�A�t�H���g�f�[�^
		IOCS	_FNTGET
	;�p���b�g�R�[�h��p�ӂ���
		move.b	(a5)+,d5		;�p���b�g�R�[�h
	;�t�H���g�f�[�^����p�^�[���f�[�^�����
		lea.l	4(sp),a0		;�t�H���g�f�[�^
		lea.l	4+2*16(sp),a1		;�p�^�[���f�[�^
	;������
		moveq	#16-1,d3
		for	d3
			move.b	(a0)+,d0		;�と��
			addq.l	#1,a0
		;	moveq.l	#0,d1
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d5,d1
				endif
			next
			move.l	d1,(a1)+		;���と����=�E��
		next
		lea.l	-2*16(a0),a0		;������
	;�E����
		moveq	#16-1,d3
		for	d3
			addq.l	#1,a0			;�と��
			move.b	(a0)+,d0
		;	moveq.l	#0,d1
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d5,d1
				endif
			next
			move.l	d1,(a1)+		;����=�E�と�E��
		next
	;�p�^�[�����`����
		move.l	d4,d1			;�p�^�[���ԍ�=�v�f�ԍ�
		moveq.l	#1,d2			;16x16
		lea.l	4+2*16(sp),a1		;�p�^�[���f�[�^
		IOCS	_SP_DEFCG
		addq.w	#1,d4			;�v�f�ԍ�++
	while	<cmp.w #N,d4>,lo
	lea.l	4+2*16+4*32(sp),sp

;�J�[�\���\��OFF
	IOCS	_B_CUROFF

;�X�v���C�g�\��ON
	IOCS	_SP_ON

;������
	.data
	.even
;�v�f�ԍ�*2���L�����N�^
elem_to_char:
	forvar	i,0,N-1,<.dc.w ((i&$F00)<<4)|(((i*225/N)/15+1)<<8)|(i&$FF)>
	.text
	lea.l	orbit(pc),a2		;�O���̐擪���v�f0�̍��W�̃A�h���X
	movea.l	a2,a3			;�O���̐擪
	move.l	#4*M*N,d6		;�O���̒���
	adda.l	d6,a3			;�O���̖���
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	movea.l	#$80000000,a5
	do
		lea.l	elem_to_char(pc),a4	;�v�f�ԍ�*2���L�����N�^
		movea.l	a2,a1			;�v�f�̍��W�̃A�h���X
		moveq.l	#0,d1			;�v�f0��VDISP�̗����������҂�
		moveq.l	#0,d7			;�v�f�ԍ�
		do
			move.w	d7,d1			;�X�v���C�g�ԍ�(�A��)
			move.w	(a1)+,d2		;X���W
			move.w	(a1)+,d3		;Y���W
			move.w	(a4)+,d4		;�L�����N�^
			moveq.l	#3,d5			;�v���C�I���e�B
			IOCS	_SP_REGST
			move.l	a5,d1			;�v�f0�ȊO��VDISP�̗����������҂��Ȃ�
			lea.l	4*(M-1)(a1),a1		;�v�f�̍��W�̃A�h���X+=������*4
			if	<cmpa.l a3,a1>,hs	;�����ɒB����
				suba.l	d6,a1			;�����߂�
			endif
			addq.w	#1,d7			;�v�f�ԍ�++
		while	<cmp.w #N,d7>,lo
		addq.l	#4,a2			;�v�f0�̍��W�̃A�h���X+=4
		if	<cmpa.l a3,a2>,hs	;�����ɒB����
			suba.l	d6,a2			;�����߂�
		endif
		bsr	inkey0
	while	eq			;�����L�[���������܂ŌJ��Ԃ�

;�X�v���C�g�\��OFF
	IOCS	_SP_OFF

;�J�[�\���\��ON
	IOCS	_B_CURON

;��ʃ��[�h�𕜌�����
	move.w	#16,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

;�I��
	DOS	_EXIT

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

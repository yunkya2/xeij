;========================================================================================
;  adotr.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac
	.include	control2.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	push2.mac


  .if STEP=1

dBLK	reg	d4	;�u���b�N�̖���(4�̔{��)
aOUT1	reg	a1	;�o�̓|�C���^1(����)
aOUT2	reg	a2	;�o�̓|�C���^2(����)
aIN	reg	a3	;���̓|�C���^(4�̔{��)
aEND	reg	a4	;�S�̖̂���(4�̔{��)

;<a1.l:�S�̖̂���+���B����0�͕s��
step1:
	clr.l	d2
	lea.l	step1_data(pc,d2.w),aIN	;���̓|�C���^(4�̔{��)
	add.l	a1,d2
	and.w	#-4,d2			;�[����؂�̂Ă�
	movea.l	d2,aEND			;�S�̖̂���(4�̔{��)
	movea.l	aIN,aOUT1		;�o�̓|�C���^1(����)
	do
	;�u���b�N�̖��������߂�
		moveq.l	#4*16,dBLK
		add.l	aIN,dBLK		;�擪+4*16=�Œ��̖���
		clr.l	d0
		add.l	aEND,d0			;�S�̖̂���
		sub.l	dBLK,d0			;-�Œ��̖���
		subx.l	d1,d1			;�S�̖̂���<�Œ��̖���?-1:0
		and.l	d1,d0			;�S�̖̂���<�Œ��̖���?�S�̖̂���-�Œ��̖���:0
		add.l	d0,dBLK			;(�S�̖̂���<�Œ��̖���?�S�̖̂���:�Œ��̖���)=�u���b�N�̖���
	;����31�r�b�g��ϊ�����
	;	4����224�i����31�r�b�g�����B224**4=$96100000
		movea.l	aOUT1,aOUT2		;�o�̓|�C���^2(����)
		do
			move.l	#-$20202020,d1
			add.l	(aIN)+,d1		;4����224�i��
			clr.l	d0			;31�r�b�g����
			moveq.l	#40,d3
			do
				movea.l	d0,a0			;1�{
				lsl.l	#3,d0			;8�{
				sub.l	a0,d0			;7�{
				lsl.l	#5,d0			;224�{
				rol.l	#8,d1			;4����224�i���̏�ʂ���
				add.l	d1,d0			;1�������o���ĉ�����
				sf.b	d1			;�S�̂������Ă���
				sub.l	d1,d0			;�]���Ȍ��������߂�
				lsr.w	#1,d3			;20,10,5,2�]��1
			while	cc
			move.l	d0,(aOUT1)+		;31�r�b�g����
		while	<cmpa.l dBLK,aIN>,lo
	;���1�r�b�g��������
	;	0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	0xxxxxxxxxxxxxxxPQR0000000000000
	;		��
	;	Pxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	Qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	Rxxxxxxxxxxxxxxx
		move.w	-(aOUT1),d1		;�Ō��2�o�C�g����
		do
			clr.l	d0
			add.w	d1,d1			;1�r�b�g�����o����
			roxr.l	#1,d0
			add.l	d0,(aOUT2)+		;���1�r�b�g�ɉ�����
		while	<cmpa.l aOUT1,aOUT2>,lo
	while	<cmpa.l aEND,aIN>,lo
;�L���b�V���t���b�V������
	lea.l	1f+(2f-1f)*2-32(pc),a0
	moveq.l	#-(2f-1f),d2
	.cpu	68020
	jmp	32(a0,d2.w*2)
	.cpu	68000
1:	clr.w	d1
	addq.w	#3,d1
	IOCS	_SYS_STAT
2:
;���s����
;<a1.l:����(4�̔{��+2)
	.align	4,$2048			;movea.l a0,a0

;�f�[�^
;	data:	�G���R�[�h���ꂽ�f�[�^.l[]
;		��($1A)
;	a1:
step1_data:

  .endif	;STEP=1


  .if STEP=2

dOUTEND	reg	d3	;.l �o�̓o�b�t�@�̖���
dDICBIT	reg	d4	;.b �����̃y�[�W���̃r�b�g���B1�`15
dDICEND	reg	d5	;.l �����̖���(����)
dTEMP	reg	d6	;.b �r�b�g�ǂݏo���̈ꎞ�ۊǏꏊ�B���dLEFT�r�b�g���c���Ă���
dLEFT	reg	d7	;.b dTEMP�̎c��r�b�g��
aOUTBUF	reg	a1	;.l �o�̓o�b�t�@�̐擪(����)
aINPPTR	reg	a2	;.l ���̓|�C���^
aINPEND	reg	a3	;.l ���̓o�b�t�@�̖���(����)
aOUTPTR	reg	a4	;.l �o�̓|�C���^
aDICBUF	reg	a5	;.l �����̐擪(����)�B�A�h���X.l,����.l
aDICPTR	reg	a6	;.l �����|�C���^

;<a1.l:���̓o�b�t�@�̖����B�擪�̏o�̓o�b�t�@�̒������܂߂Ē���4�ȉ��͕s��
step2:
;�o�̓o�b�t�@�̐擪
	moveq.l	#1,d0			;���̓o�b�t�@�̖����������ɐ؂�グ��
	add.l	a1,d0
	and.w	#-2,d0
	movea.l	d0,aOUTBUF		;�o�̓o�b�t�@�̐擪(����)
;�r�b�g�ǂݏo���̏���
	moveq.l	#0,dTEMP		;�r�b�g�ǂݏo���̈ꎞ�ۊǏꏊ
	moveq.l	#0,dLEFT		;dTEMP�̎c��r�b�g��
	lea.l	step2_data(pc),aINPPTR	;���̓o�b�t�@�̐擪�����̓|�C���^
;�o�̓o�b�t�@�̖���
	moveq.l	#24,d1
	bsr	get_bits
	move.l	d0,dOUTEND		;�o�̓o�b�t�@�̒���
	add.l	aOUTBUF,dOUTEND		;+�o�̓o�b�t�@�̐擪=�o�̓o�b�t�@�̖���
;�����̐擪
	moveq.l	#1,d0			;�o�̓o�b�t�@�̖����������ɐ؂�グ��
	add.l	dOUTEND,d0
	and.w	#-2,d0
	movea.l	d0,aDICBUF		;�����̐擪(����)
;�����̃y�[�W���̃r�b�g��
	moveq.l	#4,d1
	bsr	get_bits
	goto	eq,data_error		;0�͕s��
	move.b	d0,dDICBIT		;�����̃y�[�W���̃r�b�g��
;�����̖���(����)
	moveq.l	#8,dDICEND
	lsl.l	dDICBIT,dDICEND		;8*�����̃y�[�W��=�����̒���
	add.l	aDICBUF,dDICEND		;+�����̐擪=�����̖���(����)
;���������m�ۂ���
	DOS	_GETPDB
	move.l	dDICEND,d1
	sub.l	d0,d1
	move.l	d1,-(sp)		;�������u���b�N�̒���
	move.l	d0,-(sp)		;�������u���b�N�̐擪
	DOS	_SETBLOCK
	addq.l	#8,sp
	goto	<tst.l d0>,mi,out_of_memory
;����������������
;	����`�G���g�����Q�Ƃ����Ƃ��G���[�ɂ��邽��
	moveq.l	#0,d0
	movea.l	aDICBUF,a0
	do
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	while	<cmpa.l dDICEND,a0>,lo
;�ϐ�������������
	movea.l	aOUTBUF,aOUTPTR		;�o�̓o�b�t�@�̐擪���o�̓|�C���^
	movea.l	aDICBUF,aDICPTR		;�����̐擪�������|�C���^(����)
;�𓀃��[�v
	do
	;���̓o�b�t�@�̖����𓥂݉z���Ă��Ȃ���
		goto	<cmpa.l aOUTBUF,aINPPTR>,hs,data_error
	;�����ɂ��邩
		moveq.l	#1,d1
		bsr	get_bits
		if	eq			;0=�����ɂȂ�
		;�����ɓo�^����
			move.l	aOUTPTR,(aDICPTR)+	;�V�����P��̐擪
			moveq.l	#1,d0
			move.l	d0,(aDICPTR)+		;�V�����P��̒���
		else				;1=�����ɂ���
		;�����̃y�[�W�ԍ���ǂݏo��
			move.b	dDICBIT,d1
			bsr	get_bits
		;����������o��
			lsl.l	#3,d0			;8*�����̃y�[�W�ԍ�
			move.l	(aDICBUF,d0.l),a0	;a0.l:�����ɂ���P��̐擪
			move.l	4(aDICBUF,d0.l),d0	;d0.l:�����ɂ���P��̒���
		;�G���g������`����Ă��邩
			goto	eq,data_error
		;�o�̓o�b�t�@�̖����𓥂݉z���Ȃ���
		;	�����Ŏ~�߂Ȃ��ƃ������u���b�N�̖����𓥂݉z����\��������
			addq.l	#1,d0			;�����ɂ���P��̒���+1
			move.l	d0,d1
			add.l	aOUTPTR,d1
			goto	<cmp.l dOUTEND,d1>,hi,data_error
		;�����ɓo�^����
			move.l	aOUTPTR,(aDICPTR)+	;�V�����P��̐擪
			move.l	d0,(aDICPTR)+		;�����ɂ���P��̒���+1���V�����P��̒���
		;�����ɂ���P����o�͂���
			subq.l	#2,d0			;�����ɂ���P��̒���-1
			forlong	d0
				move.b	(a0)+,(aOUTPTR)+
			next
		endif
	;�������o�͂���
		move.b	(aINPPTR)+,(aOUTPTR)+
	;�����|�C���^�������߂�
		if	<cmpa.l dDICEND,aDICPTR>,eq
			movea.l aDICBUF,aDICPTR
		endif
	while	<cmpa.l dOUTEND,aOUTPTR>,lo
;�L���b�V���t���b�V������
	moveq.l	#-(2f-1f),d0
	.cpu	68020
	jmp	1f+(2f-1f)*2(pc,d0.w*2)
	.cpu	68000
1:	moveq.l	#3,d1
	IOCS	_SYS_STAT
2:
;���s����
	movea.l	aOUTBUF,a0		;�o�̓o�b�t�@�̐擪
	jmp	(a0)

print_exit:
	DOS	_PRINT
	DOS	_EXIT

out_of_memory:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'out of memory',13,10,0
	.even

data_error:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'data error',13,10,0
	.even

;<d1.b:�ǂݏo���r�b�g��
;>d0.l:�ǂݏo�����f�[�^
;>z:eq=0,ne=0�ȊO
;?d1-d2
get_bits:
	moveq.l	#0,d0			;�ǂݏo�����f�[�^�B���24�r�b�g���g��
	do
		if	<tst.b dLEFT>,eq	;dTEMP����
			move.b	(aINPPTR)+,dTEMP	;�V����dTEMP
			addq.b	#8,dLEFT		;dTEMP�̎c��r�b�g��
		endif
		move.b	d1,d2
		if	<cmp.b dLEFT,d2>,hi
			move.b	dLEFT,d2	;d2.b:min(�ǂݏo���r�b�g��,dTEMP�̎c��r�b�g��)
		endif
		move.b	dTEMP,d0		;�ǂݏo�����f�[�^��
		lsl.l	d2,d0			;���ʂɉ�������
		lsl.b	d2,dTEMP		;dTEMP�̏�ʂ��牟���o��
		sub.b	d2,dLEFT		;dTEMP�̎c��r�b�g��
		sub.b	d2,d1			;�ǂݏo���r�b�g���̎c��
	while	ne
	lsr.l	#8,d0			;�ǂݏo�����f�[�^
	rts

;�f�[�^
;	���̓o�b�t�@�A�o�̓o�b�t�@�A����
step2_data:

  .endif	;STEP=2


  .if STEP=3

dLENGTH	reg	d3	;.l �{�̂̒���
aNAME	reg	a2	;.l �t�@�C����
aBODY	reg	a3	;.l �{��
aTABLE	reg	a4	;.l CRC32�e�[�u��
aEND	reg	a5	;.l CRC32�e�[�u���̖���

	.offset	0
NAME:	.ds.b	24
DATE:	.ds.l	1
CRC32:	.ds.l	1
LENGTH:	.ds.l	1
BODY:
	.text

;�o�b�t�@���\������
	lea.l	step3_data(pc),aNAME	;�t�@�C����
	move.l	LENGTH-NAME(aNAME),dLENGTH	;�{�̂̒���
	lea.l	BODY-NAME(aNAME),aBODY	;�{��
	move.l	aBODY,d0		;�{��
	add.l	dLENGTH,d0		;+�{�̂̒���=�{�̖̂���
	addq.l	#1,d0
	and.w	#-2,d0			;�����ɌJ��グ��
	movea.l	d0,aTABLE		;CRC32�e�[�u��
	lea.l	4*256(aTABLE),aEND	;CRC32�e�[�u���̖���
;���������m�ۂ���
	DOS	_GETPDB
	move.l	aEND,d1
	sub.l	d0,d1
	move.l	d1,-(sp)		;�������u���b�N�̒���
	move.l	d0,-(sp)		;�������u���b�N�̐擪
	DOS	_SETBLOCK
	addq.l	#8,sp
	goto	<tst.l d0>,mi,out_of_memory
;CRC32�e�[�u�������
	movea.l	aTABLE,a0
	moveq.l	#0,d1
	do
		move.l	d1,d0
		moveq.l	#8-1,d2
		for	d2
			lsr.l	#1,d0
			if	cs
				eori.l	#$EDB88320,d0
			endif
		next
		move.l	d0,(a0)+
		addq.b	#1,d1
	while	cc
;CRC32���v�Z����
	movea.l	aTABLE,a1
	moveq.l	#0,d0			;CRC32
	move.l	dLENGTH,d1		;�{�̂̒���
	movea.l	aBODY,a0		;�{��
	not.l	d0
	forcontinuelong	d1
		moveq.l	#0,d2
		move.b	(a0)+,d2
		eor.b	d0,d2
		lsr.l	#8,d0
		lsl.w	#2,d2
		move.l	(a1,d2.l),d2
		eor.l	d2,d0
	next
	not.l	d0
;CRC32���r����
	goto	<cmp.l CRC32-NAME(aNAME),d0>,ne,crc_error
;�t�@�C�������
	move.w	#$0020,-(sp)
	move.l	aNAME,-(sp)
	DOS	_CREATE
	addq.l	#6,sp
	goto	<tst.l d0>,mi,cannot_write
	move.l	dLENGTH,-(sp)
	move.l	aBODY,-(sp)
	move.w	d0,-(sp)
	DOS	_WRITE
	move.l	d0,d1
	move.l	DATE-NAME(aNAME),2(sp)
	DOS	_FILEDATE
	DOS	_CLOSE
	lea.l	10(sp),sp
	if	<cmp.l dLENGTH,d1>,ne
		move.l	aNAME,-(sp)
		DOS	_DELETE
		addq.l	#4,sp
		goto	cannot_write
	endif
;����I��
	move.l	aNAME,-(sp)
	DOS	_PRINT
	pea.l	@f(pc)
print_exit:
	DOS	_PRINT
	DOS	_EXIT
@@:	.dc.b	' created',13,10,0
	.even

out_of_memory:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'out of memory',13,10,0
	.even

crc_error:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'crc error',13,10,0
	.even

cannot_write:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'cannot write',13,10,0
	.even

;�f�[�^
;	data:	�t�@�C����.b[24]
;		����.l
;		�������{�̂�CRC32.l
;		�{�̂̒���.l
;		�{��.b[�{�̂̒���]
;		.even
;	a1:	CRC32�e�[�u��
step3_data:

  .endif	;STEP=3



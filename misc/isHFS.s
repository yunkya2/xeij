;========================================================================================
;  isHFS.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	isHFS.x
;		�J�����g�h���C�u�܂��͎w�肳�ꂽ�h���C�u��HFS�����ׂ܂��B
;
;	�ŏI�X�V
;		2024-08-08
;
;	����
;		has060 -i include -o isHFS.o -w isHFS.s
;		lk -o isHFS.x isHFS.o
;
;	�g����
;		>isHFS [�h���C�u��]
;		A: �c Z:
;		a: �c z:
;			�h���C�u��
;		@:
;			�J�����g�h���C�u
;		�ȗ����̓J�����g�h���C�u
;
;	�I���R�[�h
;		0	HFS�ł͂Ȃ�
;		1	HFS
;
;----------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac

;�h���C�u��HFS�����ׂ�
;<(sp).l:�h���C�u�ԍ��B0=�J�����g,1=A:,�c,26=Z:
;>d0.l:0=HFS�ł͂Ȃ�,1=HFS
_isHFS::
	move.l	a1,-(sp)
	lea.l	-94(sp),sp		;DPB�e�[�u���̗̈���m�ۂ���
;DPB�e�[�u�������o��
	move.l	sp,-(sp)		;DPB�e�[�u���̃A�h���X
	move.w	4+94+4+4+2(sp),-(sp)	;�h���C�u�ԍ��B0=�J�����g,1=A:,�c,26=Z:
	DOS	_GETDPB
	addq.l	#6,sp
	tst.l	d0
	bmi	10f			;���o���Ȃ�����
;�f�o�C�X�h���C�o�֐i��
	lea.l	18(sp),a1		;�f�o�C�X�h���C�o�̃A�h���X�̃A�h���X
	IOCS	_B_LPEEK
	movea.l	d0,a1			;�f�o�C�X�h���C�o�̃A�h���X
;�f�o�C�X�����m�F����
	lea.l	14(a1),a1		;�f�o�C�X���̃A�h���X
	IOCS	_B_LPEEK
	cmp.l	#$01_000000+'XEI',d0
	bne	10f			;�Ⴄ
	IOCS	_B_LPEEK
	cmp.l	#'JHFS',d0
	bne	10f			;�Ⴄ
;���ʂ�Ԃ�
	moveq.l	#1,d0			;HFS
	bra	20f

10:	moveq.l	#0,d0			;HFS�ł͂Ȃ�
20:	lea.l	94(sp),sp
	movea.l	(sp)+,a1
	rts

;�J�n�ʒu
start:
;�󔒂�ǂݔ�΂�
	addq.l	#1,a2			;a2=�R�}���h���C��
	moveq.l	#0,d0
10:	move.b	(a2)+,d0
	beq	20f			;�������Ȃ��B�J�����g�h���C�u�𒲂ׂ�
	cmpi.b	#' ',d0
	beq	10b			;�󔒂�ǂݔ�΂�
	cmpi.b	#9,d0
	beq	10b			;�󔒂�ǂݔ�΂�
;�h���C�u����ǂݎ��
	cmp.b	#'@',d0
	beq	20f			;@:�B�J�����g�h���C�u�𒲂ׂ�
	and.b	#$DF,d0			;�啶��������
	sub.b	#'A',d0			;'A',�c,'Z'��0=A:,�c,25=Z:�ɂ���
	blo	50f			;���@�G���[�B�g�p�@��\�����ďI������
	cmp.b	#'Z'-'A',d0
	bhi	50f			;���@�G���[�B�g�p�@��\�����ďI������
	move.l	d0,d1			;d1=�h���C�u�ԍ��B0=A:,�c,25=Z:
	bra	30f			;�h���C�u��HFS�����ׂ�

;�J�����g�h���C�u�𒲂ׂ�
20:	DOS	_CURDRV			;�J�����g�h���C�u�����o��
	move.l	d0,d1			;d1=�h���C�u�ԍ��B0=A:,�c,25=Z:
;�h���C�u��HFS�����ׂ�
30:	addq.b	#1,d1			;d1=�h���C�u�ԍ��B1=A:,�c,26=Z:
	move.l	d1,-(sp)
	bsr	_isHFS			;�h���C�u��HFS�����ׂ�
	addq.l	#4,sp
;���ʂ�\�����ďI���R�[�h�ŕԂ�
	move.w	d0,-(sp)		;0=HFS�ł͂Ȃ�,1=HFS
	lea.l	no(pc),a0		;:��HFS�ł͂���܂���
	beq	40f
	lea.l	yes(pc),a0		;:��HFS�ł�
40:	pea.l	drive(pc)		;�h���C�u
	DOS	_PRINT
	moveq.l	#'A'-1,d0
	add.b	d1,d0			;�h���C�u���B'A',�c,'Z'
	move.w	d0,(sp)
	DOS	_PUTCHAR
	move.l	a0,(sp)			;:��HFS�ł͂���܂���/:��HFS�ł�
	DOS	_PRINT
	addq.l	#4,sp
	DOS	_EXIT2

;�g�p�@��\�����ďI������
50:	pea.l	usage(pc)		;�g�p�@
	DOS	_PRINT
	move.w	#-1,(sp)
	DOS	_EXIT2

usage:	.dc.b	'isHFS.x',13,10
	.dc.b	'  �h���C�u��HFS�����ׂ܂�',13,10
	.dc.b	'  �g�p�@: isHFS [�h���C�u��]',13,10
	.dc.b	'  �I���R�[�h: 0=HFS�ł͂Ȃ� 1=HFS',13,10,0
drive:	.dc.b	'�h���C�u',0
no:	.dc.b	':��HFS�ł͂���܂���',13,10,0
yes:	.dc.b	':��HFS�ł�',13,10,0

	.end	start

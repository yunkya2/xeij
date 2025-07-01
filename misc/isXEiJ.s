;========================================================================================
;  isXEiJ.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	isXEiJ.x
;		XEiJ��œ��삵�Ă��邩���ׂ܂��B
;
;	�ŏI�X�V
;		2024-08-08
;
;	����
;		has060 -i include -o isXEiJ.o -w isXEiJ.s
;		lk -o isXEiJ.x isXEiJ.o
;
;	�g����
;		>isXEiJ
;
;	�I���R�[�h
;		0	XEiJ�ł͂Ȃ�
;		1	XEiJ
;
;----------------------------------------------------------------

	.include	doscall.mac

;XEiJ�����ׂ�
;>d0.l:0=XEiJ�ł͂Ȃ�,1=XEiJ
_isXEiJ::
	clr.l	-(sp)			;�������ޏꏊ
	move.w	#4,-(sp)		;�T�C�Y�B�����O���[�h
	pea.l	2(sp)			;�������ރA�h���X�B�������ޏꏊ
	move.l	#$00E9F03C,-(sp)	;�ǂݏo���A�h���X�BHFS��ROM�̖���
	DOS	_BUS_ERR		;ROM�̓��e���R�s�[����
	lea.l	10(sp),sp
	cmpi.l	#'JHFS',(sp)+		;�m�F����
	seq.b	-(sp)			;$00=�ǂݏo���Ȃ�����/�s��v,$FF=��v
	moveq.l	#1,d0
	and.b	(sp)+,d0		;0=XEiJ�ł͂Ȃ�,1=XEiJ
	rts

;�J�n�ʒu
start:
;�󔒂�ǂݔ�΂�
	addq.l	#1,a2			;a2=�R�}���h���C��
	moveq.l	#0,d0
10:	move.b	(a2)+,d0
	beq	20f			;�������Ȃ��BXEiJ�����ׂ�
	cmpi.b	#' ',d0
	beq	10b
	cmpi.b	#9,d0
	beq	10b
	bra	40f			;���@�G���[�B�g�p�@��\�����ďI��

;XEiJ�����ׂ�
20:	bsr	_isXEiJ
;���ʂ�\�����ďI���R�[�h�ŕԂ�
	move.w	d0,-(sp)		;0=XEiJ�ł͂Ȃ�,1=XEiJ
	lea.l	no(pc),a0		;XEiJ�ł͂���܂���
	beq	30f
	lea.l	yes(pc),a0		;XEiJ�ł�
30:	move.l	a0,-(sp)		;XEiJ�ł͂���܂���/XEiJ�ł�
	DOS	_PRINT
	addq.l	#4,sp
	DOS	_EXIT2

;�g�p�@��\�����ďI������
40:	pea.l	usage(pc)		;�g�p�@
	DOS	_PRINT
	move.w	#-1,(sp)
	DOS	_EXIT2

usage:	.dc.b	'isXEiJ.x',13,10
	.dc.b	'  XEiJ�����ׂ܂�',13,10
	.dc.b	'  �g�p�@: isXEiJ',13,10
	.dc.b	'  �I���R�[�h: 0=XEiJ�ł͂Ȃ� 1=XEiJ',13,10,0
no:	.dc.b	'XEiJ�ł͂���܂���',13,10,0
yes:	.dc.b	'XEiJ�ł�',13,10,0

	.end	start

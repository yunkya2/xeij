;========================================================================================
;  flineprivilege.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;
;	flineprivilege.x
;		MC68030�Ń��[�U���[�h�̂Ƃ�$FE00�`$FFFF�̂ǂ�œ����ᔽ��O���������邩���ׂ܂��B
;		�u.�v��F���C����O�������������̂������Ă���A�u!�v�͓����ᔽ��O�������������̂������Ă��܂��B
;		cpSAVE�܂���cpRESTORE�ŃA�h���b�V���O���[�h���������ꍇ�Ɍ���AF���C����O�ł͂Ȃ������ᔽ��O���������܂��B
;
;	�X�V����
;		2024-11-29
;			���J�B
;
;----------------------------------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac
	.include	control2.mac

	.text

;���ʂ̃o�b�t�@����������
	lea.l	result_buffer,a2	;a2=���ʂ̃o�b�t�@�̃|�C���^

;���ȏ����������邽�߃L���b�V����OFF�ɂ���
	moveq.l	#-1,d3			;d3=���̃L���b�V�����[�h
	movem.l	sp,-(sp)
	cmpa.l	(sp)+,sp
	if	ne			;68020�ȏ�
		moveq.l	#0,d2
		moveq.l	#4,d1
		IOCS	_SYS_STAT
		move.l	d0,d3
	endif

;�����ᔽ��O�x�N�^��ۑ����ĕύX����
	moveq.l	#$08,d1			;�����ᔽ��O
	lea.l	privilege_routine,a1	;�����ᔽ��O�������[�`��
	IOCS	_B_INTVCS
	movea.l	d0,a3			;a3=���̓����ᔽ��O�x�N�^

;F���C����O�x�N�^��ۑ����ĕύX����
	moveq.l	#$0B,d1			;F���C����O
	lea.l	fline_routine,a1	;F���C����O�������[�`��
	IOCS	_B_INTVCS
	movea.l	d0,a4			;a4=����F���C����O�x�N�^

;$FE00�`$FFFF�����s����
	move.w	#$FE00,d1		;d1=���߃R�[�h
	do
		move.w	d1,@f			;���ȏ�������
		nop
		.align	4,$4E71			;���܂��Ȃ�
	@@:	nop
		addq.w	#1,d1
		moveq.l	#63,d0			;64������
		and.w	d1,d0
		if	eq
			move.b	#13,(a2)+		;���s
			move.b	#10,(a2)+
		else
			moveq.l	#15,d0			;16������
			and.w	d1,d0
			if	eq
				move.b	#' ',(a2)+		;��
			endif
		endif
	while	<tst.w d1>,ne

;�����ᔽ��O�x�N�^�𕜌�����
	moveq.l	#$08,d1			;�����ᔽ��O
	movea.l	a3,a1			;���̓����ᔽ��O�x�N�^
	IOCS	_B_INTVCS

;F���C����O�x�N�^�𕜌�����
	moveq.l	#$0B,d1			;F���C����O
	movea.l	a4,a1			;����F���C����O�x�N�^
	IOCS	_B_INTVCS

;�L���b�V�����[�h�𕜌�����
	move.l	d3,d2			;���̃L���b�V�����[�h
	if	pl			;68020�ȏ�
		moveq.l	#4,d1
		IOCS	_SYS_STAT
	endif

;���ʂ�\������
	clr.b	(a2)
	pea.l	result_buffer
	DOS	_PRINT
	addq.l	#4,sp

;�I������
	DOS	_EXIT

;�����ᔽ��O�������[�`��
privilege_routine:
	move.b	#'!',(a2)+
	addq.l	#2,2(sp)		;���̖��߂ɐi��
	rte

;F���C����O�������[�`��
fline_routine:
	move.b	#'.',(a2)+
	addq.l	#2,2(sp)		;���̖��߂ɐi��
	rte

	.bss

;���ʂ̃o�b�t�@
result_buffer:
	.ds.b	4096

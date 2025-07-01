;========================================================================================
;  51200bps.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;--------------------------------------------------------------------------------
;���O
;	51200bps.x
;����
;	RSDRV.SYS 2.02���g�ݍ��܂�Ă����ԂŎ��s���Ă��������B
;	X680x0�̓���RS-232C�|�[�g���ȉ��̐ݒ�ɂȂ�܂��B
;		�{�[���[�g	51200bps (���_�l��52083.3bps)
;		�f�[�^��	8�r�b�g
;		�p���e�B	�Ȃ�
;		�X�g�b�v	1�r�b�g
;		�t���[����	RTS
;	�����USB-RS232C�ϊ��킪50000bps�ɑΉ����Ă���Ƃ��A�덷4%�Őڑ��ł��邱�Ƃ�����܂��B
;--------------------------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	ppi.equ
	.include	scc.equ

;38400bps
;		  S1 PN B8    RTS   38400
	move.w	#%01_00_11_0_0_1_000_1001,d1
	IOCS	_SET232C

;�X�[�p�[�o�C�U���[�h
	supervisormode

;���荞�݋֎~
	di

aCMD	reg	a5
aPPI	reg	a6

	lea.l	SCC_A_COMMAND,aCMD
	lea.l	PPI_PORT_A,aPPI

;�{�[���[�g�W�F�l���[�^��~
	move.b	#14,(aCMD)		;WR14
	tst.b	(aPPI)
	tst.b	(aPPI)
;		             BRGE
	move.b	#%000_0_0_0_1_0,(aCMD)

;���萔
;	TC=5000000/(2*50000*16)-2)=1.125
;	BR=5000000/(2*(1+2)*16)=52083=51200*1.017
	move.b	#12,(aCMD)		;WR12
	tst.b	(aPPI)
	tst.b	(aPPI)
	move.b	#1,(aCMD)
	move.b	#13,(aCMD)		;WR13
	tst.b	(aPPI)
	tst.b	(aPPI)
	move.b	#0,(aCMD)

;�{�[���[�g�W�F�l���[�^�ĊJ
	move.b	#14,(aCMD)		;WR14
	tst.b	(aPPI)
	tst.b	(aPPI)
;		             BRGE
	move.b	#%000_0_0_0_1_1,(aCMD)

;���荞�݋���
	ei

;���[�U���[�h
	usermode

;�I��
	DOS	_EXIT

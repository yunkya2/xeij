;========================================================================================
;  38400bps.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;--------------------------------------------------------------------------------
;���O
;	38400bps.x
;����
;	RSDRV.SYS 2.02���g�ݍ��܂�Ă����ԂŎ��s���Ă��������B
;	X680x0�̓���RS-232C�|�[�g���ȉ��̐ݒ�ɂȂ�܂��B
;		�{�[���[�g	38400bps (���_�l��39062.5bps)
;		�f�[�^��	8�r�b�g
;		�p���e�B	�Ȃ�
;		�X�g�b�v	1�r�b�g
;		�t���[����	RTS
;--------------------------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac

;38400bps
;		  S1 PN B8    RTS   38400
	move.w	#%01_00_11_0_0_1_000_1001,d1
	IOCS	_SET232C

;�I��
	DOS	_EXIT

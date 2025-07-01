;========================================================================================
;  prwbit2.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;--------------------------------------------------------------------------------
;�X�v���C�g�X�N���[�����W�X�^��4���[�h��(�v���C�I���e�B)�̃r�b�g2�̓�����m�F���܂�
;--------------------------------------------------------------------------------
PALET_BLOCK	equ	8
	.include	doscall.mac
	.include	iocscall.mac
	clr.l	-(sp)
	DOS	_SUPER
	move.l	d0,(sp)
	moveq.l	#2,d1			;256x256
	IOCS	_CRTMOD
	IOCS	_SP_INIT
	IOCS	_SP_ON
	move.l	#0,d1			;�o�b�N�O���E���h0
	move.l	#0,d2			;�e�L�X�g�G���A0
	move.l	#1,d3			;�\������
	IOCS	_BGCTRLST
	move.l	#1,d1			;�o�b�N�O���E���h1
	move.l	#1,d2			;�e�L�X�g�G���A1
	move.l	#1,d3			;�\������
	IOCS	_BGCTRLST
;��1
	move.l	#1,d1			;�p���b�g�R�[�h1
	move.l	#PALET_BLOCK,d2		;�p���b�g�u���b�N
	move.l	#$003E,d3		;�J���[�R�[�h��
	IOCS	_SPALET
;��2
	move.l	#2,d1			;�p���b�g�R�[�h2
	move.l	#PALET_BLOCK,d2		;�p���b�g�u���b�N
	move.l	#$07C0,d3		;�J���[�R�[�h��
	IOCS	_SPALET
;��3
	move.l	#3,d1			;�p���b�g�R�[�h3
	move.l	#PALET_BLOCK,d2		;�p���b�g�u���b�N
	move.l	#$F800,d3		;�J���[�R�[�h��
	IOCS	_SPALET
;���邢�D�F15
	move.l	#15,d1			;�p���b�g�R�[�h15
	move.l	#PALET_BLOCK,d2		;�p���b�g�u���b�N
	move.l	#%10101_10101_10101_0,d3	;�J���[�R�[�h���邢�D�F
	IOCS	_SPALET
;�p�^�[��1
	move.l	#1,d1			;�p�^�[��1
	move.l	#1,d2			;16x16
	lea.l	pattern_1,a1		;�p�^�[���f�[�^1
	IOCS	_SP_DEFCG
;�p�^�[��2
	move.l	#2,d1			;�p�^�[��2
	move.l	#1,d2			;16x16
	lea.l	pattern_2,a1		;�p�^�[���f�[�^2
	IOCS	_SP_DEFCG
;�p�^�[��3
	move.l	#3,d1			;�p�^�[��3
	move.l	#1,d2			;16x16
	lea.l	pattern_3,a1		;�p�^�[���f�[�^3
	IOCS	_SP_DEFCG
;�o�b�N�O���E���h0
	move.l	#0,d1			;�e�L�X�g�G���A0
	move.l	#0,d2			;X���W
	move.l	#2,d3			;Y���W
	move.l	#PALET_BLOCK<<8|4*1,d4	;�p���b�g�u���b�N,�p�^�[��1
@@:
	IOCS	_BGTEXTST
	addq.l	#1,d2
	cmp.l	#16,d2
	blo	@b
;�o�b�N�O���E���h1
	move.l	#1,d1			;�e�L�X�g�G���A1
	move.l	#0,d2			;X���W
	move.l	#3,d3			;Y���W
	move.l	#PALET_BLOCK<<8|4*2,d4	;�p���b�g�u���b�N,�p�^�[��2
@@:
	IOCS	_BGTEXTST
	add.l	#1,d2
	cmp.l	#16,d2
	blo	@b
;�X�v���C�g
	move.l	#1,d1			;�X�v���C�g1
	move.l	#16,d2			;X���W
	move.l	#32+4,d3		;Y���W
	move.l	#PALET_BLOCK<<8|3,d4	;�p���b�g�u���b�N�A�p�^�[��3
	move.l	#0,d5			;�v���C�I���e�B
@@:
  .if 0
	IOCS	_SP_REGST
  .else
	movem.l	d1/a0,-(sp)
	lea.l	$00EB0000,a0
	lsl.w	#3,d1
	movem.w	d2-d5,(a0,d1.w)
	movem.l	(sp)+,d1/a0
  .endif
	add.l	#1,d1
	add.l	#16,d2
	add.l	#1,d5
	cmp.l	#8,d5
	blo	@b
	DOS	_SUPER
	addq.l	#4,sp
	DOS	_EXIT
pattern_1:
  .rept 8
	.dc.l	$00110011
	.dc.l	$00110011
	.dc.l	$11001100
	.dc.l	$11001100
  .endm
pattern_2:
  .rept 8
	.dc.l	$00220022
	.dc.l	$00220022
	.dc.l	$22002200
	.dc.l	$22002200
  .endm
pattern_3:
  .rept 4
	.dc.l	$00003333
	.dc.l	$00003333
	.dc.l	$00003333
	.dc.l	$00003333
	.dc.l	$33330000
	.dc.l	$33330000
	.dc.l	$33330000
	.dc.l	$33330000
  .endm

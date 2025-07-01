;========================================================================================
;  hu260pat.s
;  Copyright (C) 2003-2022 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	hu260pat.x
;		Human 3.02����ROM Human 2.60����邽�߂̃p�b�`�f�[�^
;
;	����
;		has060 -i include -o hu260pat.o -w hu260pat.s
;		lk -b 1447a -o hu260pat.x hu260pat.o
;
;	Human 3.02
;		text�̒���
;			$A890
;		data�̒���
;			$33EA
;		text+data�̒���
;			$A890+$33EA=$DC7A
;		text+data�̐擪
;			$6800
;		text+data�̖���+1
;			$6800+$A890+$33EA=$1447A
;
;	Human 3.02��Z�`���ɕϊ�����$FC2000�ɔz�u����
;		text�̒���
;			$FC2002 $A890
;		data�̒���
;			$FC2006 $33EA
;		text+data�̐擪
;			$FC201C
;		text+data�̖���+1
;			$FC201C+$A890+$33EA=$FCFC96
;
;	�p�b�`�����Ă�
;		text�̒���
;			$FC2002 $A890
;		data�̒���
;			$FC2006 $33EA+?
;		�p�b�`�̐擪
;			$FC201C+$A890+$33EA=$FCFC96
;		�p�b�`�̖���+1
;			$FC201C+$A890+$33EA+?=$FCFC96+?
;
;----------------------------------------------------------------

	.include	control.mac
	.include	doscall.mac
	.include	dosconst.equ
	.include	doswork.equ
	.include	patch.mac
	.include	push.mac

VERSION_NUMBER	equ	$023C
VERSION_STRING	reg	'2.60'

Z_START		equ	$FC2000
TEXT_START	equ	Z_START+$1C
TEXT_END	equ	$FCFFFF

	PATCH_START	TEXT_START+$A890+$33EA,TEXT_END

;----------------------------------------------------------------
;Z�`���w�b�_
;----------------------------------------------------------------
	PATCH_DATA	z_header,Z_START+$06,Z_START+$09,$000033EA

	PATCH_SIZE	patch_size
	.dc.l	$33EA+patch_size

;----------------------------------------------------------------
;scsidev�̏����l
;----------------------------------------------------------------
	PATCH_DATA	scsidev,$6818-$6800+TEXT_START,$681B-$6800+TEXT_START,$011B2A1B

	.dc.l	$001B2A1B

;----------------------------------------------------------------
;�^�C�g���̒��̃o�[�W����
;----------------------------------------------------------------
	PATCH_DATA	title,$683E-$6800+TEXT_START,$6841-$6800+TEXT_START,$332E3032

	.dc.b	VERSION_STRING

;----------------------------------------------------------------
;�f�o�C�X�h���C�o�̍����ւ�
;	float*.x��ROM FLOAT��ǂݍ���
;	iocs.x�͓ǂݍ��܂Ȃ�
;	����ȊO�͎w�肳�ꂽ�t�@�C����ǂݍ���
;----------------------------------------------------------------
	PATCH_DATA	load_driver,$7170-$6800+TEXT_START,$7175-$6800+TEXT_START,$803C0003

	jmp	load_driver

	PATCH_TEXT

;�f�o�C�X�h���C�o�����[�h����
;<d0.w:���W���[���ԍ�<<8
;<a0.l:�t�@�C����
;<a1.l:�󂫃G���A�̐擪�A�h���X
;>d0.l:text+data+bss+comm+stack�̃T�C�Y�B0=����,����=�G���[
;>ccr:eq=����,mi=�G���[
load_driver:
	push	d1-d4/a0-a2
	move.w	d0,d2			;���W���[���ԍ�<<8
	lea.l	-NS_SIZE(sp),sp
	move.l	sp,-(sp)		;_NAMESTS�`���̃t�@�C����
	move.l	a0,-(sp)		;�t�@�C����
	DOS	_NAMESTS
	addq.l	#8,sp
	if	pl,<tst.l d0>
		move.l	NS_EXT-1(sp),d0	;�g���q�B?012
		lsl.l	#8,d0		;012-
		or.l	#$20202020,d0
		if	eq,<cmp.l #'x   ',d0>	;�g���q��'x  '
			move.l	NS_NAME_1+1(sp),d0	;�t�@�C����1�B1234
			move.l	NS_NAME_1+5(sp),d1	;�t�@�C����1�B567?
			move.b	NS_NAME_1+0(sp),d0	;1230
			move.b	NS_NAME_1+4(sp),d1	;5674
			ror.l	#8,d0			;0123
			ror.l	#8,d1			;4567
			or.l	#$20202020,d0
			or.l	#$20202020,d1
			ifand	eq,<cmp.l #'iocs',d0>,eq,<cmp.l #'    ',d1>	;�t�@�C����1��'iocs    '
				;�ǂݍ��܂Ȃ�
				moveq.l	#0,d0
				bra	load_driver_end
				noreturn
			else
				and.l	#$FF202020,d1
				ifand	eq,<cmp.l #'floa',d0>,eq,<cmp.l #'t   ',d1>	;�t�@�C����1��'float???'
				;ROM FLOAT��ǂݍ���
					movea.l	$00FF0010,a0		;ROM FLOAT��X�`�����s�t�@�C���̐擪
					move.l	12(a0),d0
					add.l	16(a0),d0		;text+data�̃T�C�Y
					move.l	20(a0),d1		;bss+comm+stack�̃T�C�Y
					move.l	d0,d2
					add.l	d1,d2			;text+data+bss+comm+stack�̃T�C�Y
					move.l	a1,d3			;���[�h�A�h���X
					sub.l	4(a0),d3		;���[�h�A�h���X-�x�[�X�A�h���X
					move.l	24(a0),d4		;�����P�[�g�e�[�u���̃T�C�Y
					movea.l	a1,a2			;�����P�[�g����f�[�^�̃A�h���X
				;text+data���R�s�[����
					lea.l	64(a0),a0		;text�̐擪
					docontinue
						move.l	(a0)+,(a1)+
					while	cc,<subq.l #4,d0>
					addq.w	#4,d0
					forcontinue	d0
						move.b	(a0)+,(a1)+
					next
				;bss+comm+stack���N���A����
					moveq.l	#0,d0
					docontinue
						move.l	d0,(a1)+
					while	cc,<subq.l #4,d1>
					addq.w	#4,d1
					forcontinue	d1
						move.b	d0,(a1)+
					next
				;�����P�[�g����
					if	ne,<tst.l d3>
						add.l	a0,d4			;�����P�[�g�e�[�u���̖����̃A�h���X
						docontinue
							move.w	(a0)+,d0		;���̃����P�[�g�ʒu�܂ł̃��[�h�I�t�Z�b�g�܂���1�Ǝ��̃����P�[�g�ʒu�܂ł̃����O�I�t�Z�b�g
							break	mi
							if	eq,<cmp.w #1,d0>
								move.l	(a0)+,d0
								break	mi
							endif
							bclr.l	#0,d0
							adda.l	d0,a2			;�����P�[�g����f�[�^�̃A�h���X
							if	eq
								add.l	d3,(a2)			;�I�t�Z�b�g�������̂Ƃ��̓����O�̃f�[�^
							else
								add.w	d3,(a2)			;�I�t�Z�b�g����̂Ƃ��̓��[�h�̃f�[�^
							endif
						while	lo,<cmpa.l d4,a0>
					endif
					move.l	d2,d0			;text+data+bss+comm+stack�̃T�C�Y
					bra	load_driver_end
					noreturn
				endif
			endif
		endif
	endif
;�w�肳�ꂽ�t�@�C����ǂݍ���
	move.w	d2,d0			;���W���[���ԍ�<<8
	move.b	#3,d0			;���W���[���ԍ�<<8|3�B���s�t�@�C���̃A�h���X�w�胍�[�h
	adda.l	#3<<24,a0		;X�`��
	move.l	$1C00.w,-(sp)		;���~�b�g�A�h���X�B_MALLOC�ł��郁������Ԃ̖����A�h���X+1
	move.l	a1,-(sp)		;���[�h�A�h���X
	move.l	a0,-(sp)		;���s�t�@�C����
	move.w	d0,-(sp)		;���W���[���ԍ�<<8|3
	DOS	_EXEC
	lea.l	14(sp),sp
load_driver_end:
	lea.l	NS_SIZE(sp),sp
	pop
	tst.l	d0
	rts

;----------------------------------------------------------------
;�󂫃G���A�̐擪�A�h���X
;	Human 3.02�͋N����ɕs�v�ɂȂ�DOS�R�[���x�N�^�e�[�u���̎�̐擪���󂫃G���A�̐擪�ɂ��Ă���
;	�����ł�DOS�R�[���x�N�^�e�[�u���̎�̌��ɒǉ��f�[�^��u���Ă��邽��DOS�R�[���x�N�^�e�[�u���͎c�����邱�ƂɂȂ�
;----------------------------------------------------------------
	PATCH_DATA	freearea,$797E-$6800+TEXT_START,$7985-$6800+TEXT_START,$21FC0001

	PATCH_SIZE	patch_size
	move.l	#$6800+$A890+$33EA+patch_size,DOS_FREE_AREA.w

;----------------------------------------------------------------
;Human�̃������Ǘ��e�[�u��
;----------------------------------------------------------------
	PATCH_DATA	mmtable,$837A-$6800+TEXT_START,$837D-$6800+TEXT_START,$0001407A

	PATCH_SIZE	patch_size
	.dc.l	$6800+$A890+$33EA+patch_size

;----------------------------------------------------------------
;_VERNUM�̒l
;----------------------------------------------------------------
	PATCH_DATA	vernum,$A4B2-$6800+TEXT_START,$A4B5-$6800+TEXT_START,$303C0302

	move.w	#VERSION_NUMBER,d0

;----------------------------------------------------------------

	PATCH_END

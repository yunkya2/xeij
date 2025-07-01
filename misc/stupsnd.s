;========================================================================================
;  stupsnd.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------------------------------
;	stupsnd.x
;		X68030�ȏ��IPLROM 1.6�̋N������on/off����
;	�I�v�V����
;		off
;			�N������炳�Ȃ�
;		on
;			�N�������L�[�R�[�h76(o5c)�Ŗ炷
;		2..127
;		$02..$7F
;		o5c�Ȃ�
;			�N�������w�肳�ꂽ�L�[�R�[�h�Ŗ炷
;		play
;			�������N�������Đ�����
;			FM�����h���C�o���O���Ă�������
;	���F�p�����[�^
;		kc,kf,tm,va[0],...,va[54]
;			���F�p�����[�^���w�肷��
;			kc	�L�[�R�[�h
;			kf	�L�[�t���N�V����
;			tm	�L�[�I������L�[�I�t�܂ł̎���(�P�ʂ�1������1�b)
;			va	OPMDRV.X�Ƌ��ʂ̉��F�p�����[�^
;		save
;			���W�X�^�f�[�^��stupsnd.dat�ɕۑ�����
;			�N�����ɔ��f������ɂ́A�f�[�^��IPLROM 1.6�֖��ߍ��ޕK�v������
;----------------------------------------------------------------------------------------

TITLE	reg	'stupsnd.x (2025-04-13)'

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sram.equ
	.include	sysport.equ

;�O���[�o�����W�X�^�����߂�
dPREV	reg	d6			;�ύX�O�̐ݒ�B0=off,1..255=on,2..127=kc
dMODE	reg	d7			;�ύX��̐ݒ�B-1=�Ȃ�,0=off,1..255=on,2..127=kc
aBASE	reg	a6			;���΃A�N�Z�X�x�[�X�A�h���X
base:
	lea.l	base(pc),aBASE
r	reg	-base(aBASE)

;������ǂݎ��
	addq.l	#1,a2			;�R�}���h���C��
	moveq.l	#-1,dMODE		;�ύX��̐ݒ�Ȃ�
	clr.b	(param_array)r		;���F�p�����[�^�Ȃ�
	sf.b	(play_flag)r		;�������N�������Đ����Ȃ�
	sf.b	(save_flag)r		;���W�X�^�f�[�^��ۑ����Ȃ�
	dostart
		lea.l	buffer(pc),a0
		movestr	<'play'>,a1
		bsr	stricmp
		if	eq
			st.b	(play_flag)r		;�������N�������Đ�����
			restart
		endif
		movestr	<'save'>,a1
		bsr	stricmp
		if	eq
			st.b	(save_flag)r		;���W�X�^�f�[�^��ۑ�����
			restart
		endif
		moveq.l	#$20,d0
		or.b	(a0),d0
		if	<cmp.b #'o',d0>,eq	;off,on,o5c�Ȃ�
			addq.l	#1,a0
			moveq.l	#$20,d0
			or.b	(a0),d0
			if	<cmp.b #'f',d0>,eq
				addq.l	#1,a0
				moveq.l	#$20,d0
				or.b	(a0),d0
				if	<cmp.b #'f',d0>,eq
					addq.l	#1,a0
					moveq.l	#0,d0			;off
				else
					goto	help
				endif
			elif	<cmp.b #'n',d0>,eq
				addq.l	#1,a0
				moveq.l	#1,d0			;on
			else
				moveq.l	#-'0',d0
				add.b	(a0)+,d0
				goto	<cmp.b #'8'-'0',d0>,hi,help
				moveq.l	#0,d1
				move.b	d0,d1
				mulu.w	#12,d1			;�ԍ�
				moveq.l	#$20,d0
				or.b	(a0)+,d0
				sub.b	#'a',d0
				goto	<cmp.b #'g'-'a',d0>,hi,help
				lea.l	note_to_number(pc),a1
				add.b	(a1,d0.w),d1
				ifor	<cmpi.b #'#',(a0)>,eq,<cmpi.b #'+',(a0)>,eq	;�V���[�v
					addq.l	#1,a0
					addq.b	#1,d1
				elif	<cmpi.b #'-',(a0)>,eq	;�t���b�g
					addq.l	#1,a0
					subq.b	#1,d1
				endif
				goto	<tst.b d1>,mi,help
				move.l	d1,d0			;x1
				divu.w	#3,d1			;x1/3
				add.b	d1,d0			;x4/3�B�L�[�R�[�h
				gotoor	<cmp.b #2,d0>,lo,<tst.b d0>,mi,help
			endif
		elif	<cmp.b #'$',(a0)>,eq	;$02..$7F
			addq.l	#1,a0
			bsr	stoh
			goto	cs,help
			moveq.l	#2,d1
			goto	<cmp.l d1,d0>,lo,help
			moveq.l	#127,d1
			goto	<cmp.l d1,d0>,hi,help
		elifand	<cmp.b #'0',(a0)>,hs,<cmp.b #'9',(a0)>,ls	;2..127
			bsr	stou
			goto	cs,help
			moveq.l	#2,d1
			goto	<cmp.l d1,d0>,lo,help
			moveq.l	#127,d1
			goto	<cmp.l d1,d0>,hi,help
		else
			goto	help
		endif
		if	<cmpi.b #',',(a0)>,ne	;','���Ȃ��B�ύX��̐ݒ�
			move.l	d0,dMODE
		else				;','������B���F�p�����[�^
			gotoor	<cmp.b #2,d0>,lo,<tst.b d0>,mi,help	;kc�ȊO�͕s��
			lea.l	param_array(pc),a1
			move.b	d0,(a1)+		;0:kc
			moveq.l	#57-1,d2
			for	d2
				goto	<cmpi.b #',',(a0)>,ne,help
				addq.l	#1,a0
				if	<cmp.b #'$',(a0)>,eq
					addq.l	#1,a0
					bsr	stoh
				elifand	<cmp.b #'0',(a0)>,hs,<cmp.b #'9',(a0)>,ls
					bsr	stou
				else
					goto	help
				endif
				goto	cs,help
				if	<cmp.w #56-1,d2>,hi	;1:kf
					moveq.l	#63,d1
					goto	<cmp.l d1,d0>,hi,help
					move.b	d0,(a1)+
				elif	eq			;2..3:tm
					goto	<cmp.l #65535,d0>,hi,help
					move.w	d0,(a1)+		;tm��2�o�C�g�B�����A�h���X�ɔz�u���邱��
				else				;4..58:va[0],...,va[54]
					goto	<cmp.l #255,d0>,hi,help
					move.b	d0,(a1)+
				endif
			next
		endif
		goto	<tst.b (a0)>,ne,help
	start
		lea.l	buffer(pc),a0
		movea.l	a2,a1
		bsr	argcpy
		movea.l	a1,a2
	while	ne			;����������

;���F�p�����[�^�����W�X�^�f�[�^�ɕϊ�����
	lea.l	param_array(pc),a0
	move.b	(a0)+,d0		;kc
	if	ne
		if	<tst.l dMODE>,mi	;���F�p�����[�^������ύX��̐ݒ肪�Ȃ��Ƃ�
			moveq.l	#0,dMODE
			move.b	d0,dMODE		;���F�p�����[�^��kc��ύX��̐ݒ�ɂ���
		endif
		move.b	(a0)+,d1		;kf
		move.w	(a0)+,d2		;tm��2�o�C�g�B�����A�h���X�ɔz�u���邱��
		bsr	stupsnd_conv
	endif

;�X�[�p�[�o�C�U���[�h�ֈڍs����
	supervisormode

;�ύX�O�̐ݒ��ۑ�����
	moveq.l	#0,dPREV
	move.b	SRAM_STARTUP_SOUND,dPREV	;�ύX�O�̐ݒ�
;<dPREV.l:�ύX�O�̐ݒ�B0=off,1..255=on,2..127=kc

;�ݒ��ύX����
	ifand	<tst.l dMODE>,pl,<cmp.b dPREV,dMODE>,ne	;�ύX��̐ݒ肪����A�ύX�O�ƕύX��̐ݒ肪�قȂ�
		unlocksram			;SRAM�������݋���
		move.b	dMODE,SRAM_STARTUP_SOUND	;�ύX��̐ݒ�
		locksram			;SRAM�������݋֎~
	endif

;�������N�������Đ�����
	if	<tst.b (play_flag)r>,ne
		bsr	play_stupsnd
	endif

;�ݒ��\������
	lea.l	buffer(pc),a0
	movestr	<'startup sound switch is '>,a1
	bsr	strcpy
	move.l	dMODE,d0
	if	mi
		move.l	dPREV,d0
	endif
	if	eq			;0=off
		move.b	#'o',(a0)+
		move.b	#'f',(a0)+
		move.b	#'f',(a0)+
	else				;1..255=on
		move.b	#'o',(a0)+
		move.b	#'n',(a0)+
		if	<cmp.b #2,d0>,ge	;2..127=kc�B�L�[�R�[�h���w�肳��Ă���
			movestr	<' with key code '>,a1
			bsr	strcpy
			bsr	utos
			move.b	#' ',(a0)+
			move.b	#'(',(a0)+
			move.b	d0,d1			;x1
			lsr.b	#2,d1			;x1/4
			sub.b	d1,d0			;x3/4�B�ԍ�
			divu.w	#12,d0			;�m�[�g|�I�N�^�[�u
			move.l	d0,d1
			swap.w	d1			;�m�[�g
			if	<cmp.w #9,d1>,hs	;c c# d��
				addq.w	#1,d0			;1��̃I�N�^�[�u
			endif
			move.b	#'o',(a0)+
			add.b	#'0',d0
			move.b	d0,(a0)+
			add.w	d1,d1
			lea.l	number_to_note(pc),a1
			adda.w	d1,a1
			move.b	(a1)+,(a0)+
			move.b	(a1),d0
			if	ne
				move.b	d0,(a0)+
			endif
			move.b	#')',(a0)+
		endif
	endif
	bsr	crlf
	lea.l	buffer(pc),a0
	bsr	print

;IPLROM�̃o�[�W�������m�F����
	IOCS	_ROMVER
	move.l	#$13000000,d1		;IPLROM 1.3�ȏ�
	if	<cmp.b #2,dMODE>,ge	;2..127=kc�B�L�[�R�[�h���w�肳��Ă���
		move.l	#$16240226,d1		;IPLROM 1.6 (24-02-26)�ȏ�
	endif
	if	<cmp.l d1,d0>,lo		;IPLROM�̃o�[�W�����������Ă��Ȃ�
		ifand	<tst.b dMODE>,pl,<cmp.b dPREV,dMODE>,ne	;�ύX��̐ݒ肪����A�ύX�O�ƕύX��̐ݒ肪�قȂ�
			unlocksram			;SRAM�������݋���
			move.b	dPREV,SRAM_STARTUP_SOUND	;�ύX�O�̐ݒ�𕜌�����
			locksram			;SRAM�������݋֎~
		endif
		movestr	<'unsupported IPLROM version',13,10>,a0
		bsr	print
	endif

;���[�U���[�h�֕��A����
	usermode

;���W�X�^�f�[�^��ۑ�����
	if	<tst.b (save_flag)r>,ne
		move.w	#$0020,-(sp)
		pea.l	data_name(pc)
		DOS	_CREATE
		addq.l	#6,sp
		move.l	d0,d1
		if	mi
			movestr	<'create error',13,10>,a0
			bsr	print
		else
			moveq.l	#42,d2			;42�o�C�g
			move.l	d2,-(sp)
			pea.l	stupsnd_data(pc)	;���W�X�^�f�[�^
			move.w	d1,-(sp)
			DOS	_WRITE
			move.l	d0,d3
			DOS	_CLOSE
			lea.l	10(sp),sp
			if	<cmp.l d2,d3>,ne	;�f�B�X�N�t���H
				pea.l	data_name(pc)
				DOS	_DELETE
				addq.l	#4,sp
				movestr	<'write error',13,10>,a0
				bsr	print
			endif
		endif
	endif

;�I������
	DOS	_EXIT

;�I�v�V������\�����ăG���[�I������
help:
	lea.l	options(pc),a0
	bsr	print
	move.w	#1,-(sp)
	DOS	_EXIT2

;�I�v�V����
options:
	.dc.b	TITLE,13,10
	.dc.b	'  turn on/off startup sound switch of X68030 or higher and IPLROM 1.6',13,10
	.dc.b	'options',13,10
	.dc.b	'  off',13,10
	.dc.b	'    turn off startup sound switch',13,10
	.dc.b	'  on',13,10
	.dc.b	'    turn on startup sound switch with key code 76 (o5c)',13,10
	.dc.b	'  2..127',13,10
	.dc.b	'  $02..$7F',13,10
	.dc.b	'  o5c etc.',13,10
	.dc.b	'    turn on startup sound switch with specified key code',13,10
	.dc.b	'  play',13,10
	.dc.b	'    play startup sound right now',13,10
	.dc.b	'    FM sound driver must be removed',13,10
	.dc.b	'tone parameters',13,10
	.dc.b	'  kc,kf,tm,va[0],...,va[54]',13,10
	.dc.b	'    specify tone parameters',13,10
	.dc.b	'    kc -- key code',13,10
	.dc.b	'    kf -- key fraction',13,10
	.dc.b	'    tm -- time from key-on to key-off (unit is 1/10,000 of a second)',13,10
	.dc.b	'    va -- tone parameters common to OPMDRV.X',13,10
	.dc.b	'  save',13,10
	.dc.b	'    save register data to stupsnd.dat',13,10
	.dc.b	'    to reflect in the startup sound, inserting data into IPLROM 1.6 is required',13,10
	.dc.b	0

;�m�[�g�̕ϊ��\
note_to_number:
	.dc.b	6			;a
	.dc.b	8			;b
	.dc.b	-3			;c
	.dc.b	-1			;d
	.dc.b	1			;e
	.dc.b	2			;f
	.dc.b	4			;g
number_to_note:
	.dc.b	'd#'			;0
	.dc.b	'e',0			;1
	.dc.b	'f',0			;2
	.dc.b	'f#'			;3
	.dc.b	'g',0			;4
	.dc.b	'g#'			;5
	.dc.b	'a',0			;6
	.dc.b	'a#'			;7
	.dc.b	'b',0			;8
	.dc.b	'c',0			;9
	.dc.b	'c#'			;10
	.dc.b	'd',0			;11

data_name:
	.dc.b	'stupsnd.dat',0

	.bss
	.even
param_array:
	.ds.b	59			;���F�p�����[�^�Bkc,kf,tmH,tmL,va[0],...,va[54]�B�����A�h���X�ɔz�u���邱��
play_flag:
	.ds.b	1			;-1=�������N�������Đ�����
save_flag:
	.ds.b	1			;-1=���F�p�����[�^��ۑ�����
buffer:
	.ds.b	1024			;������o�b�t�@

	.text
	.even



;----------------------------------------------------------------
;�N����

CH	equ	0

KC	equ	76
KF	equ	5
TM	equ	2500/100

FLCON	equ	(1<<3)|3		;|FL###|CON###|
SLOT	equ	%1101			;|C2|M2|C1|M1|
WAVE	equ	0
SYNC	equ	1
SPEED	equ	0
PMD	equ	0
AMD	equ	0
PMS	equ	0
AMS	equ	0
PAN	equ	%11			;|R|L|

M1AR	equ	6
M1D1R	equ	11
M1D2R	equ	4
M1RR	equ	4
M1D1L	equ	0
M1TL	equ	29
M1KS	equ	0
M1MUL	equ	0
M1DT1	equ	0
M1DT2	equ	3
M1AMSEN	equ	1

C1AR	equ	31
C1D1R	equ	6
C1D2R	equ	0
C1RR	equ	2
C1D1L	equ	2
C1TL	equ	40
C1KS	equ	2
C1MUL	equ	1
C1DT1	equ	0
C1DT2	equ	3
C1AMSEN	equ	1

M2AR	equ	3
M2D1R	equ	2
M2D2R	equ	7
M2RR	equ	2
M2D1L	equ	3
M2TL	equ	28
M2KS	equ	1
M2MUL	equ	3
M2DT1	equ	0
M2DT2	equ	1
M2AMSEN	equ	1

C2AR	equ	31
C2D1R	equ	21
C2D2R	equ	6
C2RR	equ	4
C2D1L	equ	2
C2TL	equ	2
C2KS	equ	1
C2MUL	equ	1
C2DT1	equ	0
C2DT2	equ	0
C2AMSEN	equ	1

play_stupsnd:
	push	d0-d4/a0
	move.b	SRAM_STARTUP_SOUND,d3	;0=off,1..255=on,2..127=kc
	if	ne			;on
		moveq.l	#$08,d1			;KeyOff
		moveq.l	#(0<<3)|CH,d2		;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
		lea.l	stupsnd_data(pc),a0	;���W�X�^�f�[�^�̔z��
		moveq.l	#$20+CH,d1		;���W�X�^�A�h���X
		moveq.l	#28-1,d4		;0..27
		for	d4
			move.b	(a0)+,d2		;���W�X�^�f�[�^
			ifand	<cmp.b #$28+CH,d1>,eq,<cmp.b #2,d3>,ge	;2..127=kc�B�L�[�R�[�h���w�肳��Ă���
				move.b	d3,d2
			endif
			bsr	stupsnd_opmset
			addq.b	#8,d1			;���̃��W�X�^�A�h���X
		next
		moveq.l	#6-1,d4			;28..39
		for	d4
			move.b	(a0)+,d1		;���W�X�^�A�h���X
			move.b	(a0)+,d2		;���W�X�^�f�[�^
			bsr	stupsnd_opmset
		next
		moveq.l	#$08,d1			;KeyOn
		moveq.l	#(SLOT<<3)|CH,d2	;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
		moveq.l	#0,d0
		move.w	(a0)+,d0		;40..41�Btm@100us
		add.l	d0,d0			;tm@50us
		jsr	wait_50us		;50us�P�ʂ̃E�F�C�g
	;	moveq.l	#$08,d1			;KeyOff
		moveq.l	#(0<<3)|CH,d2		;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
	endif
	pop
	rts

stupsnd_opmset:
	IOCS	_OPMSET
	rts

;���W�X�^�f�[�^(42�o�C�g)�B�����A�h���X�ɔz�u���邱��
	.even
stupsnd_data:
  .ifdef STUPSNDDAT
	.insert	stupsnd.dat
  .else
	.dc.b	(PAN<<6)|FLCON		;0 $20+CH |PAN##|FL###|CON###|
	.dc.b	KC			;1 $28+CH |-|KC#######|
	.dc.b	KF<<2			;2 $30+CH |KF######|--|
	.dc.b	(PMS<<4)|AMS		;3 $38+CH |-|PMS###|--|AMS##|
	.dc.b	(M1DT1<<4)|M1MUL	;4 $40+CH M1 |-|DT1###|MUL####|
	.dc.b	(M2DT1<<4)|M2MUL	;5 $48+CH M2
	.dc.b	(C1DT1<<4)|C1MUL	;6 $50+CH C1
	.dc.b	(C2DT1<<4)|C2MUL	;7 $58+CH C2
	.dc.b	M1TL			;8 $60+CH M1 |-|TL#######|
	.dc.b	M2TL			;9 $68+CH M2
	.dc.b	C1TL			;10 $70+CH C1
	.dc.b	C2TL			;11 $78+CH C2
	.dc.b	(M1KS<<6)|M1AR		;12 $80+CH M1 |KS##|-|AR#####|
	.dc.b	(M2KS<<6)|M2AR		;13 $88+CH M2
	.dc.b	(C1KS<<6)|C1AR		;14 $90+CH C1
	.dc.b	(C2KS<<6)|C2AR		;15 $98+CH C2
	.dc.b	(M1AMSEN<<7)|M1D1R	;16 $A0+CH M1 |AMSEN|--|D1R#####|
	.dc.b	(M2AMSEN<<7)|M2D1R	;17 $A8+CH M2
	.dc.b	(C1AMSEN<<7)|C1D1R	;18 $B0+CH C1
	.dc.b	(C2AMSEN<<7)|C2D1R	;19 $B8+CH C2
	.dc.b	(M1DT2<<6)|M1D2R	;20 $C0+CH M1 |DT2##|-|D2R#####|
	.dc.b	(M2DT2<<6)|M2D2R	;21 $C8+CH M2
	.dc.b	(C1DT2<<6)|C1D2R	;22 $D0+CH C1
	.dc.b	(C2DT2<<6)|C2D2R	;23 $D8+CH C2
	.dc.b	(M1D1L<<4)|M1RR		;24 $E0+CH M1 |D1L####|RR####|
	.dc.b	(M2D1L<<4)|M2RR		;25 $E8+CH M2
	.dc.b	(C1D1L<<4)|C1RR		;26 $F0+CH C1
	.dc.b	(C2D1L<<4)|C2RR		;27 $F8+CH C2
	.dc.b	$18,SPEED		;28,29 $18 |LFRQ########|
	.dc.b	$19,(0<<7)|AMD		;30,31 $19 |0|AMD#######|
	.dc.b	$19,(1<<7)|PMD		;32,33 $19 |1|PMD#######|
	.dc.b	$1B,WAVE		;34,35 $1B |CT1|CT2|----|WAVE##|
	.dc.b	$01,SYNC<<1		;36,37 $01 |------|LFORESET|-|
	.dc.b	$01,0<<1		;38,39 $01 |------|LFORESET|-|
	.dc.w	TM			;40,41 tm@100us
					;42
	.even
  .endif



;----------------------------------------------------------------
;���F�p�����[�^�����W�X�^�f�[�^�ɕϊ�����
;<d0.b:kc
;<d1.b:kf
;<d2.w:tm
;<a0.l:���F�p�����[�^(55�o�C�g)�Bva[0],...,va[54]
;		+0	+1	+2	+3	+4	+5	+6	+7	+8	+9	+10
;	0	FLCON	SLOT	WAVE	SYNC	SPEED	PMD	AMD	PMS	AMS	PAN	0
;	11	M1AR	M1D1R	M1D2R	M1RR	M1D1L	M1TL	M1KS	M1MUL	M1DT1	M1DT2	M1AMSEN
;	22	C1AR	C1D1R	C1D2R	C1RR	C1D1L	C1TL	C1KS	C1MUL	C1DT1	C1DT2	C1AMSEN
;	33	M2AR	M2D1R	M2D2R	M2RR	M2D1L	M2TL	M2KS	M2MUL	M2DT1	M2DT2	M2AMSEN
;	44	C2AR	C2D1R	C2D2R	C2RR	C2D1L	C2TL	C2KS	C2MUL	C2DT1	C2DT2	C2AMSEN
;	55	kc	kf
stupsnd_conv:
	push	d0-d4/a0-a2,58
	movea.l	sp,a1
	moveq.l	#55-1,d3
	for	d3
		move.b	(a0)+,(a1)+
	next
	move.b	d0,(a1)+		;kc
	move.b	d1,(a1)+		;kf
	movea.l	sp,a0			;���F�p�����[�^+kc+kf(57�o�C�g)�Bva[0],...,va[54],kc,kf
	tas.b	5(a0)			;|1|PMD#######|
	lea.l	stupsnd_data(pc),a1	;���W�X�^�f�[�^(42�o�C�g)
	lea.l	100f(pc),a2		;���F�p�����[�^�����W�X�^�f�[�^�ϊ��\
	moveq.l	#0,d1
	moveq.l	#28+6-1,d3
	for	d3
		if	<cmp.b #6-1,d3>,ls	;�Ō��6��
			move.b	(a2)+,(a1)+		;���W�X�^�A�h���X
		endif
		moveq.l	#0,d0			;���W�X�^�f�[�^
		dostart
			move.b	(a0,d1.w),d1		;���F�p�����[�^+kc+kf�Ɋ܂܂�郌�W�X�^�f�[�^�̕��i
			and.b	(a2)+,d1		;�}�X�N
			move.b	(a2)+,d4		;�V�t�g�J�E���g
			lsl.b	d4,d1
			or.b	d1,d0			;���i����ׂ�
		start
			move.b	(a2)+,d1		;���F�p�����[�^+kc+kf�̃C���f�b�N�X
		while	pl
		move.b	d0,(a1)+		;���W�X�^�f�[�^
	next
	move.w	d2,(a1)+		;40,41 tm
	pop
	rts

;���F�p�����[�^�����W�X�^�f�[�^�ϊ��\
100:
;���F�p�����[�^+kc+kf�̃C���f�b�N�X,�}�X�N,�V�t�g�J�E���g,�c,-1
	.dc.b	9,3,6,0,63,0,-1		;0 $20+CH |PAN##|FL###|CON###|
	.dc.b	55+0,127,0,-1		;1 $28+CH |-|KC#######|
	.dc.b	55+1,63,2,-1		;2 $30+CH |KF######|--|
	.dc.b	7,7,4,6,3,0,-1		;3 $38+CH |-|PMS###|--|AMS##|
	.dc.b	11+8,7,4,11+7,15,0,-1	;4 $40+CH M1 |-|DT1###|MUL####|
	.dc.b	33+8,7,4,33+7,15,0,-1	;5 $48+CH M2
	.dc.b	22+8,7,4,22+7,15,0,-1	;6 $50+CH C1
	.dc.b	44+8,7,4,44+7,15,0,-1	;7 $58+CH C2
	.dc.b	11+5,127,0,-1		;8 $60+CH M1 |-|TL#######|
	.dc.b	33+5,127,0,-1		;9 $68+CH M2
	.dc.b	22+5,127,0,-1		;10 $70+CH C1
	.dc.b	44+5,127,0,-1		;11 $78+CH C2
	.dc.b	11+6,3,6,11+0,31,0,-1	;12 $80+CH M1 |KS##|-|AR#####|
	.dc.b	33+6,3,6,33+0,31,0,-1	;13 $88+CH M2
	.dc.b	22+6,3,6,22+0,31,0,-1	;14 $90+CH C1
	.dc.b	44+6,3,6,44+0,31,0,-1	;15 $98+CH C2
	.dc.b	11+10,1,7,11+1,31,0,-1	;16 $A0+CH M1 |AMSEN|--|D1R#####|
	.dc.b	33+10,1,7,33+1,31,0,-1	;17 $A8+CH M2
	.dc.b	22+10,1,7,22+1,31,0,-1	;18 $B0+CH C1
	.dc.b	44+10,1,7,44+1,31,0,-1	;19 $B8+CH C2
	.dc.b	11+9,3,6,11+2,31,0,-1	;20 $C0+CH M1 |DT2##|-|D2R#####|
	.dc.b	33+9,3,6,33+2,31,0,-1	;21 $C8+CH M2
	.dc.b	22+9,3,6,22+2,31,0,-1	;22 $D0+CH C1
	.dc.b	44+9,3,6,44+2,31,0,-1	;23 $D8+CH C2
	.dc.b	11+4,15,4,11+3,15,0,-1	;24 $E0+CH M1 |D1L####|RR####|
	.dc.b	33+4,15,4,33+3,15,0,-1	;25 $E8+CH M2
	.dc.b	22+4,15,4,22+3,15,0,-1	;26 $F0+CH C1
	.dc.b	44+4,15,4,44+3,15,0,-1	;27 $F8+CH C2
;���W�X�^�A�h���X,���F�p�����[�^+kc+kf�̃C���f�b�N�X,�}�X�N,�V�t�g�J�E���g,�c,-1
	.dc.b	$18,4,255,0,-1		;28,29 $18 |LFRQ########|
	.dc.b	$19,6,127,0,-1		;30,31 $19 |0|AMD#######|
	.dc.b	$19,5,127,0,-1		;32,33 $19 |1|PMD#######|
	.dc.b	$1B,2,3,0,-1		;34,35 $1B |CT1|CT2|----|WAVE##|
	.dc.b	$01,3,1,1,-1		;36,37 $01 |------|LFORESET|-|
	.dc.b	$01,3,0,1,-1		;38,39 $01 |------|LFORESET|-|
	.even



;----------------------------------------------------------------
;�������R�s�[����
;	�󔒂�ǂݔ�΂��Ă��玟�̋󔒂̎�O�܂ŃR�s�[����
;	"�`"�܂���'�`'�ň͂ނƈ����ɋ󔒂��܂߂邱�Ƃ��ł���
;	""�܂���''�Ə����ƒ�����0�̈�����^���邱�Ƃ��ł���
;<a0.l:�R�s�[��̃o�b�t�@�̐擪
;<a1.l:�R�s�[���̕�����̐擪
;>d0.l:0=�������Ȃ�,1=����������
;>a0.l:�R�s�[��̕�����̖�����0�̈ʒu
;>a1.l:�R�s�[���̈����̒���B�Ȃ���΃R�s�[���̕�����̖�����0�̈ʒu
;>eq=�������Ȃ�,ne=����������
argcpy::
	exg.l	a0,a1
	bsr	nextword		;�󔒂�ǂݔ�΂�
	exg.l	a0,a1
	if	eq			;�������Ȃ�
		clr.b	(a0)
		moveq.l	#0,d0
		rts
	endif
	dostart
		if	<cmp.b #'"',d0>,eq	;"�`"
			dostart
				move.b	d0,(a0)+		;��������
			start
				move.b	(a1)+,d0		;���̕���
				break2	eq			;�������I�����
			while	<cmp.b #'"',d0>,ne
		elif	<cmp.b #39,d0>,eq	;'�`'
			dostart
				move.b	d0,(a0)+		;��������
			start
				move.b	(a1)+,d0		;���̕���
				break2	eq			;�������I�����
			while	<cmp.b #$39,d0>,ne
		else
			move.b	d0,(a0)+		;��������
		endif
	start
		move.b	(a1)+,d0		;���̕���
		break	eq			;�������I�����
		breakand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r�Ȃ�ΏI��
	while	<cmp.b #' ',d0>,ne	;�󔒂łȂ���ΌJ��Ԃ�
	subq.l	#1,a1			;�i�݉߂������߂�
	clr.b	(a0)
	moveq.l	#1,d0
	rts

;----------------------------------------------------------------
;���s���R�s�[����
;<a0.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
crlf::
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;16�i���̕����𐮐��ɕϊ�����
;<d0.b:����
;>d0.l:0�`16�B-1=16�i���̕����ł͂Ȃ�
;>n:mi=16�i���̕����ł͂Ȃ�
fromxdigit::
	sub.b	#'0',d0
	blo	1f			;x<0
	sub.b	#('9'+1)-'0',d0
	blo	3f			;0<=x<=9
	subq.b	#'A'-('9'+1),d0
	blo	1f			;9<x<A
	subq.b	#('F'+1)-'A',d0
	blo	2f			;A<=x<=F
	sub.b	#'a'-('F'+1),d0
	blo	1f			;F<x<A
	subq.b	#('f'+1)-'a',d0
	blo	2f			;a<=x<=f
1:	moveq.l	#-1,d0			;x<0||9<x<A||F<x<a||f<x
	rts
2:	addq.b	#6,d0			;A<=x<=F||a<=x<=f
3:	add.b	#10,d0			;0<=x<=9
	ext.w	d0
	ext.l	d0
	rts

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
;16�i���̕�����𕄍��Ȃ������ɕϊ�����
;<a0.l:16�i���̕�����B�擪�̋󔒂͔F�߂Ȃ�
;>d0.l:�����Ȃ������B(cs�̂Ƃ�)����32�r�b�g
;>a0.l:16�i���ł͂Ȃ������܂���0�̈ʒu
;>c:cc=����,cs=16�i���̕������Ȃ��܂��̓I�[�o�[�t���[
;>v:(cs�̂Ƃ�)vc=16�i���̕������Ȃ�,vs=�I�[�o�[�t���[
stoh::
	push	d1-d2/a1
	moveq.l	#0,d1			;�����Ȃ�����
	moveq.l	#0,d2			;�I�[�o�[�t���[����p
	movea.l	a0,a1			;�J�n�ʒu
	dostart
		or.l	d1,d2			;16�{���钼�O�̒l��OR
		lsl.l	#4,d1			;16�{����
		or.b	d0,d1			;1��������
	start
		move.b	(a0)+,d0		;���̕���
		bsr	fromxdigit
	while	pl			;16�i���̕����Ȃ�ΌJ��Ԃ�
	subq.l	#1,a0			;�i�݉߂������߂�
	add.l	#$F0000000,d2
	subx.w	d2,d2			;16�{���钼�O�̒l��OR�̏��4�r�b�g��0�łȂ����Ȃ킿�I�[�o�[�t���[�̂Ƃ�-1�A�����Ȃ���0
	and.w	#%00011,d2		;�I�[�o�[�t���[�̂Ƃ�vs,cs�A�����Ȃ���vc,cc
	if	<cmpa.l a1,a0>,eq	;�i��ł��Ȃ�
		or.w	#%00001,d2		;16�i���̕������Ȃ��Ƃ�cs
	endif
	move.l	d1,d0			;�����Ȃ�����
	move.w	d2,ccr
	popm
	rts

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
;�����������Ȃ��當�����r
;	'['<'A'�ƂȂ邱�Ƃɒ��ӁBSJIS�͐�������r�ł��Ȃ����Ƃɒ���
;<a0.l:������0�B�������
;<a1.l:������1�B����
;>ccr:eq=������0==������1,lo=������0<������1,hi=������1<������0
stricmp::
	push	d0-d1/a0-a1
	do
		move.b	(a0)+,d0
		if	eq
			cmp.b	(a1)+,d0
			break
		endif
		move.b	(a1)+,d1
		ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls
			or.b	#$20,d0
		endif
		ifand	<cmp.b #'A',d1>,hs,<cmp.b #'Z',d1>,ls
			or.b	#$20,d1
		endif
		cmp.b	d1,d0
	while	eq
	pop
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

;----------------------------------------------------------------
;50us�P�ʂ̃E�F�C�g
;<d0.l:�҂�����(50us�P��)
wait_50us::
aTCDR	reg	a0
	push	d0-d2/aTCDR
	lea.l	MFP_TCDR,aTCDR		;Timer-C�f�[�^���W�X�^�B200,199,�c,2,1,0��200,199,�c(50us�P��)
	moveq.l	#0,d1
	move.b	(aTCDR),d1
	move.b	(aTCDR),d1		;d1=�O��̒l
	do
		moveq.l	#0,d2
		move.b	(aTCDR),d2		;d2=����̒l
		redo	<cmp.b (aTCDR),d2>,lo	;0��200�̂Ƃ��ǂݒ���
		sub.w	d2,d1			;d1=�O��̒l-����̒l=�o�ߎ���
		if	lo			;0��200���ׂ����Ƃ�
			add.w	#200,d1			;����̒l��200���������o�ߎ��Ԃ�200����̂ŉ����߂�
		endif
		exg.l	d1,d2			;d1=����̒l=����̑O��̒l,d2=�o�ߎ���
		sub.l	d2,d0			;d0=�҂�����-�o�ߎ���=����̑҂�����
	while	hi			;�҂����Ԃ��Ȃ��Ȃ�܂ŌJ��Ԃ�
	pop
	rts



	.end

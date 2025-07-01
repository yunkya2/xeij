;========================================================================================
;  rom16pat.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	rom16pat.x
;		IPLROM 1.3����IPLROM 1.6����邽�߂̃p�b�`�f�[�^
;
;	�ŏI�X�V
;		2025-03-23
;
;	����
;		has060 -i include -o rom16pat.o -w rom16pat.s
;		lk -b fea000 -o rom16pat.x rom16pat.o
;
;	SASI IOCS
;		IPLROM 1.2��SASI IOCS�͈̔͂�$00FF95B6�`$00FF9E7D(2248�o�C�g)
;		IPLROM 1.3��SCSI IOCS�͈̔͂�$00FFCCB8�`$00FFDCE3(4140�o�C�g)
;		IPLROM 1.3��SCSI IOCS�̏ꏊ��IPLROM 1.2��SASI IOCS���R�s�[���Ă��炱�̃p�b�`��K�p����
;
;	6x12�t�H���g
;		IPLROM 1.2��6x12 ANK�t�H���g�͈̔͂�$00FFD45E�`$00FFE045(3048�o�C�g)
;		IPLROM 1.6��6x12 ANK�t�H���g�͈̔͂�$00FEF400�`$00FEFFFF(3072�o�C�g)
;		�R�s�[���āA������24�o�C�g��$00�ŏ[�U����
;
;	SHARP���S
;		X68000���S��傫���ł���悤��SHARP���S��
;		$00FF138C�`$00FF144F(196�o�C�g)����
;		$00FFD680�`$00FFD743(196�o�C�g)�ֈړ�������
;		$00FFD580�`$00FFD67F(256�o�C�g)��SASI IOCS�̃p�b�`�p�ɋ󂯂Ă���
;
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	dmac.equ
	.include	dosconst.equ
	.include	hdc.equ
	.include	iocscall.mac
	.include	key.equ
	.include	mfp.equ
	.include	misc.mac
	.include	ppi.equ
	.include	push2.mac
	.include	rtc.equ
	.include	scsicall.mac
	.include	spc.equ
	.include	sprc.equ
	.include	sram.equ
	.include	sysport.equ
	.include	vector.equ
	.include	vicon.equ

	.include	patch.mac



VERSION_NUMBER	equ	$16_250323	;�o�[�W�����Ɠ��t
VERSION_STRING	reg	'1.6 (2025-03-23)'
CRTMOD_VERSION	equ	$16_250323	;_CRTMOD�̃o�[�W����

TEXT_START	equ	$00FEA000	;�e�L�X�g�Z�N�V�����̐擪
TEXT_END	equ	$00FEF3FF	;�e�L�X�g�Z�N�V�����̖���

REMOVE_CRTMOD_G_CLR_ON	equ	0	;1=_CRTMOD��_G_CLR_ON���O��
USE_PROPORTIONAL_IOCS	equ	0	;1=IOCS�Ńv���|�[�V���i���t�H���g���g��



;----------------------------------------------------------------
;
;	�p�b�`�f�[�^�̐擪
;
;----------------------------------------------------------------

	PATCH_START	TEXT_START,TEXT_END

	.cpu	68000



;----------------------------------------------------------------
;	_ROMVER
;		00FF0030 203C13921127           move.l	#$13921127,d0
;		00FF0036
;----------------------------------------------------------------
	PATCH_DATA	iocs_romver,$00FF0030,$00FF0035,$203C1392
	move.l	#VERSION_NUMBER,d0
	PATCH_TEXT
	.dc.b	'XEiJ IPLROM ',VERSION_STRING,13,10
	.dc.b	'CAUTION: Distribution is prohibited.',13,10
	.dc.b	26,0

;----------------------------------------------------------------
;���b�Z�[�W�̃X�^�C��
;	bit0	0=�m�[�}���s�b�`,1=�v���|�[�V���i���s�b�`
;	bit1	0=����,1=������
;	bit2	0=���ԂȂ�,1=���Ԃ���
message_style::
	.dc.b	7
	.even



;----------------------------------------------------------------
;	���䃌�W�X�^�̏�������MPU/MMU/FPU�̃`�F�b�N
;		�T�u���[�`�����A�h���X�ϊ��𖳌��ɂ���ƃX�^�b�N�G���A���ړ����Ė߂��Ă���Ȃ��Ȃ�̂�jsr�ł͂Ȃ�jmp���g��
;		00FF005A 61000CE2               bsr.w	$00FF0D3E		;MPU,MMU,FPU/FPCP�`�F�b�N
;		00FF005E 2E00                   move.l	d0,d7
;		00FF0060 4A07                   tst.b	d7
;		00FF0062 6710                   beq.s	$00FF0074		;68000
;		00FF0064 7000                   moveq.l	#$00,d0
;		00FF0066 4E7B0801               movec.l	d0,vbr
;		00FF006A 0C070001               cmpi.b	#$01,d7
;		00FF006E 6704                   beq.s	$00FF0074		;68010
;		00FF0070 4E7B0002               movec.l	d0,cacr			;�L���b�V��OFF
;		00FF0074
;----------------------------------------------------------------
	PATCH_DATA	mpu_check,$00FF005A,$00FF0073,$61000CE2
	jmp	mpu_check
	PATCH_TEXT
;----------------------------------------------------------------
;MPU�`�F�b�N
;	�N������Ɋ��荞�݋֎~�A�X�^�b�N���g�p�̏�ԂŃW�����v���Ă���
;	IPLROM 1.3��TRAP#10�̓z�b�g�X�^�[�g����Ƃ�MMU�̃A�h���X�ϊ��̏�Ԃ��m�F������$00FF0038�ɃW�����v���Ă���
;	060turbo.sys��TRAP#10���t�b�N���Ă���̂Ńz�b�g�X�^�[�g�����ꍇ���A�h���X�ϊ��͊��ɖ���������Ă���͂������A
;	�O�̂��߃A�h���X�ϊ����L���ɂȂ��Ă����ꍇ���l������
;	ROM�̃R�[�h�͕ω����Ȃ��̂Ŗ��Ȃ����A
;	�x�N�^�e�[�u���ƃX�^�b�N�G���A�ƃ��[�N�G���A�̓��e�̓A�h���X�ϊ��𖳌��ɂ����u�ԂɎ�����
;	�z�b�g�X�^�[�g������X�^�b�N�G���A�⃏�[�N�G���A���g���O�ɃA�h���X�ϊ��𖳌��ɂ��Ȃ���΂Ȃ�Ȃ�
;<d5.l:0=�R�[���h�X�^�[�g(d0d1!='HotStart'),-1=�z�b�g�X�^�[�g(d0d1=='HotStart')
;<d6.l:�G�~�����[�^���荞�݃x�N�^([OFFSET_EMULATOR_INTERRUPT.w].l)&$00FFFFFF�B�R�[���h�X�^�[�g�̂Ƃ�����`��O�������[�`�����w���Ă��Ȃ���Γd��ON�A�w���Ă���΃��Z�b�g
;>d7.l:MPU�̎�ނ�FPU/FPCP�̗L����MMU�̗L��
;	bit31	MMU�̗L���B0=�Ȃ�,1=����
;	bit15	FPU/FPCP�̗L���B0=�Ȃ�,1=����
;	bit7-0	MPU�̎�ށB0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
;?d0/a1
mpu_check:
	movea.l	sp,a1

;----------------------------------------------------------------
;MOVEC to VBR(-12346)���Ȃ����MC68000
;	MC68000���ǂ����̃e�X�g��VBR�̃N���A�𓯎��ɍs��
;	�s�����ߗ�O�x�N�^��$0010.w�ɂ���̂�MC68000�̏ꍇ��MC68010�ȏ��VBR��0�̏ꍇ
;	MC68010�ȏ��VBR��0�łȂ��Ƃ�$0010.w�����������Ă��s�����ߗ�O�𑨂����Ȃ��̂ŁA
;	MC68010�ȏ�̂Ƃ��͍ŏ���VBR���N���A����K�v������
;	VBR���N���A���閽�߂�MC68000�ŕs�����߂Ȃ̂�MC68000���ǂ����̃e�X�g�����˂�
	lea.l	dummy_trap(pc),a0
	move.l	a0,OFFSET_ILLEGAL_INSTRUCTION.w	;��O�x�N�^$04 �s������
	lea.l	mpu_check_done(pc),a0
	moveq.l	#0,d7			;MC68000
	moveq.l	#0,d0
	.cpu	68010
	movec.l	d0,vbr
	.cpu	68000
	lea.l	dummy_trap(pc),a0
	move.l	a0,OFFSET_ILLEGAL_INSTRUCTION.w	;��O�x�N�^$04 �s������
	move.l	a0,OFFSET_LINE_1111_EMULATOR.w	;��O�x�N�^$0B ���C��1111�G�~�����[�^

;----------------------------------------------------------------
;MOVEC to VBR(-12346)�������ăX�P�[���t�@�N�^(--2346)���Ȃ����MC68010
	moveq.l	#1,d7			;MC68010
@@:	moveq.l	#1,d0			;$70,$01
	.cpu	68020
	and.b	(@b-1,pc,d0.w*2),d0	;�X�P�[���t�@�N�^�Ȃ�(([@b-1+1].b==$70)&1)==0,�X�P�[���t�@�N�^����(([@b-1+1*2].b=$01)&1)==1
	.cpu	68000
	beq	mpu_check_done

;----------------------------------------------------------------
;CALLM(--2---)�������MC68020
	.cpu	68020
	lea.l	9f(pc),a0
	callm	#0,1f(pc)
	moveq.l	#2,d7			;MC68020
;		  3  2 1 0
;		  C CE F E
	move.l	#%1__0_0_0,d0
	movec.l	d0,cacr			;���߃L���b�V���N���A�A���߃L���b�V��OFF
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPU����
@@:
;MC68851�̃`�F�b�N�͏ȗ�
	bra	mpu_check_done

;���W���[���f�X�N���v�^
1:	.dc.l	%0<<13|0<<24|0<<16	;option=0,type=0,accesslevel=0
	.dc.l	2f			;���W���[���G���g���|�C���^
	.dc.l	0			;���W���[���f�[�^�̈�|�C���^
	.dc.l	0
;���W���[���G���g��
2:	.dc.w	15<<12			;Rn=sp
	rtm	sp

9:	movea.l	a1,sp
	.cpu	68000

;----------------------------------------------------------------
;CALLM(--2---)���Ȃ���MOVEC from CAAR(--23--)�������MC68030
	.cpu	68030
	lea.l	9f(pc),a0
	movec.l	caar,d0
	moveq.l	#3,d7			;MC68030
;		   D   C  B   A  9  8 765   4  3   2  1  0
;		  WA DBE CD CED FD ED     IBE CI CEI FI EI
	move.l	#%_0___0__1___0__0__0_000___0__1___0__0__0,d0
	movec.l	d0,cacr			;�f�[�^�L���b�V���N���A�A�f�[�^�L���b�V��OFF�A���߃L���b�V���N���A�A���߃L���b�V��OFF
;		  F ECDBA   9   8 7654 3210 FEDC BA98 7654 3210
;		  E       SRE FCL   PS   IS  TIA  TIB  TIC  TID
	move.l	#%0_00000___0___0_1101_1000_0011_0100_0100_0000,-(sp)
	pmove.l	(sp),tc			;�A�h���X�ϊ�OFF
;		  FEDCBA98 76543210 F EDCB  A   9   8 7    654 3    210
;		      BASE     MASK E      CI R/W RWM   FCBASE   FCMASK
	move.l	#%00000000_00000000_0_0000__0___0___0_0____000_0____000,(sp)
	pmove.l	(sp),tt0		;���ߕϊ�OFF
	pmove.l	(sp),tt1
	addq.l	#4,sp
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPU����
@@:	bsr	mmu_check_3		;MMU�`�F�b�N(MC68030)
	bra	mpu_check_done

9:
	.cpu	68000

;----------------------------------------------------------------
;MOVEC from MMUSR(----4-)�������MC68040
	.cpu	68040
	lea.l	9f(pc),a0
	movec.l	mmusr,d0
	moveq.l	#4,d7			;MC68040
;		   F EDCBA9876543210  F EDCBA9876543210
;		  DE 000000000000000 IE 000000000000000
	move.l	#%_0_000000000000000__0_000000000000000,d0
	movec.l	d0,cacr			;�f�[�^�L���b�V��OFF�A���߃L���b�V��OFF
	cinva	bc			;�f�[�^�L���b�V���N���A�A���߃L���b�V���N���A
;		  F E DCBA9876543210
;		  E P 00000000000000
	move.l	#%0_0_00000000000000,d0
	movec.l	d0,tc			;�A�h���X�ϊ�����
	pflusha				;�A�h���X�ϊ��L���b�V���N���A
;		  FEDCBA98 76543210 F     ED CBA  9  8 7 65 43 2 10
;		      BASE     MASK E SFIELD     U1 U0   CM    W
	move.l	#%00000000_00000000_0_____00_000__0__0_0_00_00_0_00,d0
	movec.l	d0,itt0			;���ߕϊ�OFF
	movec.l	d0,itt1
	movec.l	d0,dtt0
	movec.l	d0,dtt1
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPU����
@@:	bsr	mmu_check_46		;MMU�`�F�b�N(MC68040/MC68060)
	bra	mpu_check_done

9:
	.cpu	68000

;----------------------------------------------------------------
;MOVEC from PCR(-----6)�������MC68060
	.cpu	68060
	lea.l	9f(pc),a0
	movec.l	pcr,d1
	moveq.l	#6,d7			;MC68060
;		    F   E   D   C   B A98   7    6    5 43210   F   E   D CBA9876543210
;		  EDC NAD ESB DPI FOC     EBC CABC CUBC       EIC NAI FIC
	move.l	#%__0___0___0___0___0_000___1____0____0_00000___0___0___0_0000000000000,d0
	movec.l	d0,cacr			;�f�[�^�L���b�V��OFF�A�X�g�A�o�b�t�@OFF�A����L���b�V��ON�A���߃L���b�V��OFF
;	���Z�b�g�ŃL���b�V���̓N���A����Ȃ�
;	���Z�b�g���ꂽ��L���b�V����L���ɂ���O�ɃL���b�V�����N���A���Ȃ���΂Ȃ�Ȃ�(MC68060UM 5.3)
	cinva	bc			;�f�[�^�L���b�V���N���A�A���߃L���b�V���N���A
;		  F E   D   C    B    A  98  76   5  43  21 0
;		  E P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
	move.l	#%0_0___0___0____0____0__10__00___0__10__00_0,d0
	movec.l	d0,tc			;�A�h���X�ϊ�OFF�A�f�[�^�L���b�V��OFF�v���T�C�X���[�h�A���߃L���b�V��OFF�v���T�C�X���[�h
;	���Z�b�g�ŃA�h���X�ϊ��L���b�V���̓N���A����Ȃ�
;	���Z�b�g���ꂽ��A�h���X�ϊ���L���ɂ���O�ɃA�h���X�ϊ��L���b�V�����N���A���Ȃ���΂Ȃ�Ȃ�(MC68060UM 4.6.1)
	pflusha				;�A�h���X�ϊ��L���b�V���N���A
;		  FEDCBA98 76543210 F     ED CBA  9  8 7 65 43 2 10
;		      BASE     MASK E SFIELD     U1 U0   CM    W
	move.l	#%00000000_00000000_0_____00_000__0__0_0_00_00_0_00,d0
	movec.l	d0,itt0			;���ߕϊ�OFF
	movec.l	d0,itt1
	movec.l	d0,dtt0
	movec.l	d0,dtt1
;		  FEDCBA9876543210 FEDCBA98      7 65432   1   0
;		  0000010000110000 REVISION EDEBUG       DFP ESS
	move.l	#%0000000000000000_00000000______0_00000___0___1,d0
	movec.l	d0,pcr			;FPU ON,�X�[�p�[�X�J��ON
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPU����
@@:	bsr	mmu_check_46		;MMU�`�F�b�N(MC68040/MC68060)
	bra	mpu_check_done

9:
	.cpu	68000

;----------------------------------------------------------------
;�s��
	moveq.l	#0,d7

;----------------------------------------------------------------
;�I��
mpu_check_done:
	jmp	$00FF0074

;----------------------------------------------------------------
;�_�~�[�̗�O����
;	a1��sp�ɃR�s�[����a0�ɃW�����v����
dummy_trap:
	movea.l	a1,sp
	jmp	(a0)

;----------------------------------------------------------------
;MMU�`�F�b�N(MC68030)
mmu_check_3:
	.cpu	68030
	lea.l	-128(sp),sp
	movea.l	sp,a0
;		L/U           LIMIT                DT
	move.l	#%0_111111111111111_00000000000000_10,(a0)+
	move.l	sp,d0
	lsr.l	#4,d0
	addq.l	#2,d0
	lsl.l	#4,d0
	move.l	d0,(a0)
;			     CI   M U WP DT
	lea.l	$00000000|%0__0_0_0_0__0_01.w,a0
	movea.l	d0,a1
	moveq.l	#8-1,d0
	for	d0
		move.l	a0,(a1)+
		adda.l	#$00200000,a0
	next
;�A�h���X�ϊ���L���ɂ���
;			      CI   M U WP DT
	move.l	#$00F00000|%0__0_0_0_0__0_01,-4*8+4(a1)	;$00200000��$00F00000�ɕϊ�����
	pmove.q	(sp),crp
;		  E       SRE FCL   PS   IS  TIA  TIB  TIC  TID
	move.l	#%1_00000___0___0_1101_1000_0011_0100_0100_0000,-(sp)
	pflusha
	pmove.l	(sp),tc
;8KB��r����
	lea.l	$00F00000,a1
	lea.l	$00200000,a0
	move.w	#2048-1,d0
@@:	cmpm.l	(a1)+,(a0)+
	dbne	d0,@b
	bne	@f
	bset.l	#31,d7			;MMU����
@@:
;�A�h���X�ϊ�����������
	bclr.b	#7,(sp)			;E=0
	pmove.l	(sp),tc			;�A�h���X�ϊ�����
	pflusha
	lea.l	4+128(sp),sp
	.cpu	68000
	rts

;----------------------------------------------------------------
;MMU�`�F�b�N(MC68040/MC68060)
mmu_check_46:
	.cpu	68040
	lea.l	$2000.w,a1
;���[�g�e�[�u�������
;			   U W UDT
	lea.l	512|%00000_0_0__10(a1),a0
	moveq.l	#128-1,d0
	for	d0
		move.l	a0,(a1)+
	next
;�|�C���^�e�[�u�������
;			   U W UDT
	lea.l	512|%00000_0_0__10(a1),a0
	moveq.l	#128-1,d0
	for	d0
		move.l	a0,(a1)+
	next
;�y�[�W�e�[�u�������
	moveq.l	#32-1,d0
	for	d0
	;			    UR G U1 U0 S CM M U W PDT
		move.l	#$00FF0000|%00_1__0__0_0_10_0_0_0__01,(a1)+
	next
;$80000000�`$FFFFFFFF�𓧉ߕϊ��ɂ���
;		      BASE     MASK E SFIELD     U1 U0   CM    W
	movea.l	#%00000000_01111111_1_____10_000__0__0_0_10_00_0_00,a1
	movec.l	a1,itt0
	movec.l	a1,dtt0
	movec.l	a1,itt1
	movec.l	a1,dtt1
;�A�h���X�ϊ���L���ɂ���
	lea.l	$2000.w,a1
	movec.l	a1,srp			;MMU���Ȃ��Ă��G���[�ɂȂ�Ȃ�(MC68060UM B.2)
	movec.l	a1,urp
;		  E P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
	movea.l	#%1_1___0___0____0____0__00__00___0__00__00_0,a1
	pflusha
	cinva	bc
	movec.l	a1,tc
;8KB��r����
	lea.l	$80FF0000,a0
	lea.l	$80F00000,a1
	move.w	#2048-1,d0
@@:	cmpm.l	(a0)+,(a1)+
	dbne	d0,@b
	bne	@f
	bset.l	#31,d7			;MMU����
@@:
;�A�h���X�ϊ��ƃg�����X�y�A�����g�ϊ�����������
	if	<cmp.b #6,d7>,lo	;68040
;			  E P
		movea.l	#%0_0___0___0____0____0__00__00___0__00__00_0,a1
	else				;68060
;			  E P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
		movea.l	#%0_0___0___0____0____0__10__00___0__00__00_0,a1
	endif
	movec.l	a1,tc
	pflusha
	cinva	bc
	suba.l	a1,a1
	movec.l	a1,itt0
	movec.l	a1,dtt0
	movec.l	a1,itt1
	movec.l	a1,dtt1
	.cpu	68000
	rts



;----------------------------------------------------------------
;	����`��O�x�N�^�Ɩ���`IOCS�R�[���x�N�^�̃n�C�������΍�
;		68060�̂Ƃ�
;			����`��O�x�N�^�Ɩ���`IOCS�R�[���x�N�^��bit28��1�̂Ƃ��x�N�^�ԍ�������
;				$01xxxxxx�Ƀn�C������������Ƃ�����`�x�N�^�𓥂�ł��\�����Ȃ��悤�ɂ���
;				060turbo��ROM�ɍ��킹�ăn�C�������̗L���Ɋ֌W�Ȃ�68060�̂Ƃ������s��
;				TRAP#n($002x)�AMFP($004x)�AIOI/DMA/SPC($006x)�Ȃǂ̓x�N�^�ԍ��������Ȃ�
;				SCC($005x)�A_OPMDRV($01F0)�Ȃǂ̓x�N�^�ԍ�������
;			�������������ߗ�O�x�N�^��ݒ肷��
;		�X�v���A�X���荞�݃x�N�^��ݒ肷��
;	�ύX�O
;		00FF008E 41FAFF70_00000000	lea.l	$00FF0000(pc),a0
;		00FF0092 2408             	move.l	a0,d2
;		00FF0094
;----------------------------------------------------------------
	PATCH_DATA	p008E,$00FF008E,$00FF0093,$41FAFF70
	jsr	p008E
	PATCH_TEXT
;<d7.l:MPU�̎�ނ�FPU/FPCP�̗L����MMU�̗L��
;	bit31	MMU�̗L���B0=�Ȃ�,1=����
;	bit15	FPU/FPCP�̗L���B0=�Ȃ�,1=����
;	bit7-0	MPU�̎�ށB0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
;>d6.l:$00FF0000
;?a0-a1
p008E:
	if	<cmpi.b #6,d7>,eq	;68060�̂Ƃ�
	;����`��O�x�N�^�Ɩ���`IOCS�R�[���x�N�^��bit28��1�̂Ƃ��x�N�^�ԍ�������
	;NMI�x�N�^��������`�ł͂Ȃ������Ȃ�
		suba.l	a0,a0			;��O�x�N�^�e�[�u���̐擪����
		do
			if	<btst.b #4,(a0)>,ne	;bit28��1�̂Ƃ�
				clr.b	(a0)			;�x�N�^�ԍ�������
			endif
			addq.l	#4,a0
		while	<cmpa.w	#$0800,a0>,lo	;IOCS�R�[���x�N�^�e�[�u���̖����܂�
	;�������������ߗ�O�����x�N�^��ݒ肷��
		lea.l	uii(pc),a1		;�������������ߗ�O�������[�`��
		move.l	a1,OFFSET_INTEGER_INSTRUCTION.w	;��O�x�N�^$3D ��������������
	endif
;�X�v���A�X���荞�݃x�N�^��ݒ肷��
	lea.l	uii_rte(pc),a1		;�������������ߗ�O�������[�`����rte
	move.l	a1,OFFSET_SPURIOUS_INTERRUPT.w	;��O�x�N�^$18 �X�v���A�X���荞��
;IOCS�R�[���x�N�^�̐ݒ�ɖ߂�
	move.l	#$00FF0000,d2
	rts

;----------------------------------------------------------------
;�������������ߗ�O�������[�`��
	.cpu	68060
uii:
	pea.l	(8,sp)			;��O��������ssp
	movem.l	d0-d7/a0-a6,-(sp)
	moveq.l	#5,d2			;�X�[�p�[�o�C�U�f�[�^�A�N�Z�X�̃t�@���N�V�����R�[�h
	btst.b	#5,(4*16,sp)		;��O��������sr��S
	bne	1f			;�X�[�p�[�o�C�U���[�h
;���[�U���[�h
	moveq.l	#1,d2			;���[�U�f�[�^�A�N�Z�X�̃t�@���N�V�����R�[�h
	move.l	usp,a0			;��O��������usp
	move.l	a0,(4*15,sp)		;��O��������sp
;���߃R�[�h��ǂݎ��
1:	movea.l	(4*16+2,sp),a0		;a0=��O��������pc
	move.w	(a0)+,d1		;d1=���߃R�[�h,a1=pc+2
;MOVEP���ǂ������ׂ�
	move.w	d1,d0
;		  0000qqq1ws001rrr
	and.w	#%1111000100111000,d0
	cmp.w	#%0000000100001000,d0
	beq	2f			;MOVEP
;MOVEP�ȊO
	movem.l	(sp),d0-d2		;d0/d1/d2�𕜌�
	movea.l	(4*8,sp),a0		;a0�𕜌�
	lea.l	(4*16,sp),sp		;�j�󂳂�Ă��Ȃ����W�X�^�̕������ȗ�����
	jmp	$00FF0770		;����`��O����

;MOVEP
;�����A�h���X�����߂�
2:	moveq.l	#7,d0			;d0=0000000000000111
	and.w	d1,d0			;d0=0000000000000rrr
	movea.l	(4*8,sp,d0.w*4),a1	;a1=Ar
	adda.w	(a0)+,a1		;a0=pc+4,a1=d16+Ar=�����A�h���X
;���A�A�h���X���X�V����
	move.l	a0,(4*16+2,sp)		;pc=pc+4
;Dq�̃A�h���X�����߂�
	move.w	d1,d0			;d0=0000qqq1ws001rrr
	lsr.w	#8,d0			;d0=000000000000qqq1
	lea.l	(-2,sp,d0.w*2),a0	;d0*2=00000000000qqq10,a0=Dq�̃A�h���X
;���[�h/���C�g,���[�h/�����O�ŕ��򂷂�
	add.b	d1,d1			;c=w,d1=s001rrr0
	bcs	5f			;���C�g
;���[�h
	movec.l	sfc,d1			;�t�@���N�V�����R�[�h��ۑ�
	movec.l	d2,sfc			;�t�@���N�V�����R�[�h��ύX
	bmi	3f			;���[�h�����O
;���[�h���[�h
;MOVEP.W (d16,Ar),Dq
	moves.b	(a1),d0			;�����������ʃo�C�g�����[�h
	lsl.w	#8,d0
	moves.b	(2,a1),d0		;���������牺�ʃo�C�g�����[�h
	move.w	d0,(2,a0)		;�f�[�^���W�X�^�̉��ʃ��[�h�փ��C�g
	bra	4f

;���[�h�����O
;MOVEP.L (d16,Ar),Dq
3:	moves.b	(a1),d0			;�����������ʃ��[�h�̏�ʃo�C�g�����[�h
	lsl.l	#8,d0
	moves.b	(2,a1),d0		;�����������ʃ��[�h�̉��ʃo�C�g�����[�h
	lsl.l	#8,d0
	moves.b	(4,a1),d0		;���������牺�ʃ��[�h�̏�ʃo�C�g�����[�h
	lsl.l	#8,d0
	moves.b	(6,a1),d0		;���������牺�ʃ��[�h�̉��ʃo�C�g�����[�h
	move.l	d0,(a0)			;�f�[�^���W�X�^�փ��C�g
4:	movec.l	d1,sfc			;�t�@���N�V�����R�[�h�𕜌�
	movem.l	(sp),d0-d7		;�f�[�^���W�X�^�̂ǂꂩ1���X�V����Ă���
	bra	8f

;���C�g
5:	movec.l	dfc,d1			;�t�@���N�V�����R�[�h��ۑ�
	movec.l	d2,dfc			;�t�@���N�V�����R�[�h��ύX
	bmi	6f			;���C�g�����O
;���C�h���[�h
;MOVEP.W Dq,(d16,Ar)
	move.w	(2,a0),d0		;�f�[�^���W�X�^�̉��ʃ��[�h���烊�[�h
	rol.w	#8,d0
	moves.b	d0,(a1)			;�������֏�ʃo�C�g�����C�g
	rol.w	#8,d0
	moves.b	d0,(2,a1)		;�������։��ʃo�C�g�����C�g
	bra	7f

;���C�g�����O
;MOVEP.L Dq,(d16,Ar)
6:	move.l	(a0),d0			;�f�[�^���W�X�^���烊�[�h
	rol.l	#8,d0
	moves.b	d0,(a1)			;�������֏�ʃ��[�h�̏�ʃo�C�g�����C�g
	rol.l	#8,d0
	moves.b	d0,(2,a1)		;�������֏�ʃ��[�h�̉��ʃo�C�g�����C�g
	rol.l	#8,d0
	moves.b	d0,(4,a1)		;�������։��ʃ��[�h�̏�ʃo�C�g�����C�g
	rol.l	#8,d0
	moves.b	d0,(6,a1)		;�������։��ʃ��[�h�̉��ʃo�C�g�����C�g
7:	movec.l	d1,dfc			;�t�@���N�V�����R�[�h�𕜌�
	movem.l	(sp),d0-d2		;d0/d1/d2�𕜌�
8:	movem.l	(4*8,sp),a0-a1		;a0/a1�𕜌�
	lea.l	(4*16,sp),sp		;�j�󂳂�Ă��Ȃ����W�X�^�̕������ȗ�����
	tst.b	(sp)			;��O��������sr��T
	bpl	9f			;�g���[�X�Ȃ�
;�g���[�X����
	ori.w	#$8000,sr		;RTE�̑O��sr��T���Z�b�g����MOVEP���g���[�X�����悤�ɐU�镑��
9:
;�������������ߗ�O�������[�`����rte
uii_rte:
	rte

	.cpu	68000



;----------------------------------------------------------------
;	IOCS $F5�x�N�^�̐ݒ�
;		000000C4 2039(01)0000934E 	move.l	device_installer_parameter,d0	;ROM�N�����[�`��-12 SCSI�f�o�C�X�h���C�o�g�ݍ��݃��[�`���̃p�����[�^
;		000000CA 21C007D4         	move.l	d0,4*($100+_SCSIDRV).w	;IOCS�R�[��$F5 _SCSIDRV
;		�폜�BSCSI�����@�̂Ƃ���scsi_init_routine�Őݒ肷��̂ł����͍폜
;----------------------------------------------------------------
	PATCH_DATA	p00C4,$00FF00C4,$00FF00C4+9,$203900FF
	bra.s	(*)-$00C4+$00CE



;----------------------------------------------------------------
;	SRAM�̏�����
;		SRAM������������Ƃ����C���������̃T�C�Y�𓋍ڂ��Ă���T�C�Y�ɍ��킹��
;		SASI�����@�̂Ƃ��AROM�N���n���h����$00E80400�ɁA�n�[�h�f�B�X�N�̑䐔��1�ɂ���
;		SCSI�����@�̂Ƃ��AROM�N���n���h����$00FC0000�ɁA�n�[�h�f�B�X�N�̑䐔��0�ɂ���
;			ROM�N���n���h����W����$00BFFFFC�ɂ���ƃ��C����������12MB�ɑ��݂����Ƃ�����ɓ��삵�Ȃ��Ȃ�
;			$00E80400�͂��ׂĂ̋@��Ńo�X�G���[�ɂȂ�͂�
;		�������T�C�Y�̔��ʂ�SASI�����@��SCSI�����@�̔��ʂ������ōs��
;	�ύX�O
;		000000CE 41F900ED0000     	lea.l	SRAM_MAGIC,a0
;			:
;		0000010C*423900E8E00D     	locksram			;SRAM�������݋֎~
;----------------------------------------------------------------
	PATCH_DATA	p00ce,$00FF00CE,$00FF0111,$41F900ED
	jsr	p00ce
	bra.s	(*)-$00D4+$0112
	PATCH_TEXT
p00ce:
	bsr	check_memory_size
	bsr	check_hard_disk_interface
	bsr	check_sram
	rts

;���C���������̃T�C�Y���m�F����
check_memory_size:
	push	d2-d3/a2/a5
	suba.l	a2,a2
	move.l	#$55AAAA55,d3		;�e�X�g�f�[�^
	di				;sr�ۑ��A���荞�݋֎~
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;�o�X�G���[�x�N�^�ۑ�
	movea.l	sp,a5			;sp�ۑ�
	move.l	#@f,OFFSET_BUS_ERROR.w	;�o�X�G���[�Ń��[�v���I������
	do
		move.l	(a2),d2			;�ۑ�
		nop
		move.l	d3,(a2)			;�e�X�g�f�[�^��������
		nop
		cmp.l	(a2),d3			;�e�X�g�f�[�^�ǂݏo���A��r
		nop
		break	ne
		nop
		move.l	d2,(a2)			;����
		nop
		adda.l	#$00100000,a2		;����1MB
	while	<cmpa.l #$00C00000,a2>,lo	;�ő�12MB
@@:	movea.l	a5,sp			;sp����
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;�o�X�G���[�x�N�^����
	ei				;sr����
	move.l	a2,BIOS_MEMORY_SIZE.w	;�N�����Ɋm�F�������C���������̃T�C�Y
	pop
	rts

;SASI�����@��SCSI�����@�𔻕ʂ���
check_hard_disk_interface:
	isSASI
	sne.b	BIOS_BUILTIN_SCSI.w	;0=SASI�����@,-1=SCSI�����@
	rts

check_sram:
	push	d0/a0-a3
	lea.l	SRAM_MAGIC,a2		;SRAM�}�W�b�N
	lea.l	$00FF09E8,a3		;SRAM�����f�[�^
	movea.l	a2,a0
	movea.l	a3,a1
	ifor	<cmpm.l (a0)+,(a1)+>,ne,<cmpm.l (a0)+,(a1)+>,ne	;SRAM�͉��Ă���
	;SRAM�������݋���
		unlocksram
	;SRAM�̐擪256�o�C�g���N���A
		movea.l	a2,a0
		moveq.l	#256/4-1,d0
		for	d0
			clr.l	(a0)+
		next
	;SRAM�����f�[�^����������
		movea.l	a2,a0
		movea.l	a3,a1
		moveq.l	#$00FF0A43-$00FF09E8-1,d0	;SRAM�����f�[�^�̒���-1
		for	d0
			move.b	(a1)+,(a0)+
		next
	;�������T�C�Y���C������
		move.l	BIOS_MEMORY_SIZE.w,SRAM_MEMORY_SIZE-SRAM_MAGIC(a2)
	;ROM�N���n���h���ƃn�[�h�f�B�X�N�̑䐔���C������
		if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI�����@
			move.l	#$00E80400,SRAM_ROM_BOOT_HANDLE-SRAM_MAGIC(a2)
			move.b	#1,SRAM_HDMAX-SRAM_MAGIC(a2)
		else				;SCSI�����@
			move.l	#$00FC0000,SRAM_ROM_BOOT_HANDLE-SRAM_MAGIC(a2)
			clr.b	SRAM_HDMAX-SRAM_MAGIC(a2)
		endif
	;SRAM�풓�v���O�����𖳌��ɂ���
		clr.w	SRAM_PROGRAM_START-SRAM_MAGIC(a2)
	;SRAM�������݋֎~
		locksram
	endif
	pop
	rts



;----------------------------------------------------------------
;	�������m�F����
;		SCSIINROM�̐������m�F����
;		���ʂ��ꂽ�������T�C�Y��SRAM�̐ݒ�l�������Ă��Ȃ��Ƃ�SRAM�̐ݒ�l���C�����邩�₢���킹��
;		CLR�L�[��������Ă�����SRAM�������̈ʒu�ɉ�������
;	�ύX�O
;		00FF01D4 083800070807     	btst.b	#7,BIOS_BITSNS+7.w	;CLR|��|��|��|��|UNDO|ROLL DOWN|ROLL UP
;----------------------------------------------------------------
	PATCH_DATA	p01d4,$00FF01D4,$00FF01D4+5,$08380007
	jsr	p01d4
	PATCH_TEXT
p01d4:
	if	<btst.b #KEY_TENCLR&7,BIOS_BITSNS+(KEY_TENCLR>>3).w>,eq	;CLR�L�[��������Ă��Ȃ��B������Ă���Ƃ�ne�ŕ��A���邽��tst.b�ł͂Ȃ�btst.b���g��
		bsr	check_memory_size
		bsr	check_hard_disk_interface
		bsr	test_scsiinrom
		bsr	confirm_memory_size
		moveq.l	#0,d0			;eq�ŕ��A����
	endif
	rts

;SCSIINROM�̐������m�F����
;	SASI�����@�̂Ƃ�SCSIINROM������΃G���[��񍐂��Ē�~����
;	SCSI�����@�̂Ƃ�SCSIINROM 16���Ȃ���΃G���[��񍐂��Ē�~����
test_scsiinrom:
	push	d0-d1/a0
	lea.l	$00FC0024,a0		;'SCSIIN'
	clr.w	d1			;0=SCSIINROM���Ȃ�
	bsr	read_long
	if	<cmp.l #'SCSI',d0>,eq
		bsr	read_word
		if	<cmp.w #'IN',d0>,eq
			addq.w	#1,d1		;1=SCSIINROM������
			bsr	read_word
			if	<cmp.w #16,d0>,eq
				addq.w	#1,d1		;2=SCSIINROM 16������
			endif
		endif
	endif
;<d1.w:0=SCSIINROM���Ȃ�,1=SCSIINROM������,2=SCSIINROM 16������
	if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI�����@�̂Ƃ�
		if	<tst.w d1>,ne		;SCSIINROM������
			lea.l	100f(pc),a1		;13,10,'  SCSIINROM is not required'
			goto	20f
		endif
	else				;SCSI�����@�̂Ƃ�
		if	<cmp.w #2,d1>,ne	;SCSIINROM 16���Ȃ�
			lea.l	101f(pc),a1		;13,10,'  SCSIINROM 16 is required'
			goto	20f
		endif
	endif
	pop
	rts

20:	bsr	iocs_21_B_PRINT
	do
	while	t

100:	.dc.b	13,10,'  SCSIINROM is not required',0
101:	.dc.b	13,10,'  SCSIINROM 16 is required',0
	.even

;���ʂ��ꂽ�������T�C�Y��SRAM�̐ݒ�l�������Ă��Ȃ��Ƃ�SRAM�̐ݒ�l���C�����邩�₢���킹��
confirm_memory_size:
	push	d0-d1/a0-a1
	move.l	SRAM_MEMORY_SIZE,d0	;SRAM�̐ݒ�l�̃������T�C�Y
	if	<cmp.l BIOS_MEMORY_SIZE.w,d0>,ne	;�N�����Ɋm�F�������C���������̃T�C�Y�B�����Ă��Ȃ�
		lea.l	-128(sp),sp
		movea.l	sp,a0
		lea.l	100f(pc),a1		;13,10,'  Modify memory size setting from '
		bsr	strcpy
	;	move.l	SRAM_MEMORY_SIZE,d0	;SRAM�̐ݒ�l�̃������T�C�Y
		moveq.l	#20,d1
		lsr.l	d1,d0
		bsr	utos
		lea.l	101f(pc),a1		;'MB to '
		bsr	strcpy
		move.l	BIOS_MEMORY_SIZE.w,d0	;�N�����Ɋm�F�������C���������̃T�C�Y
	;	moveq.l	#20,d1
		lsr.l	d1,d0
		bsr	utos
		lea.l	102f(pc),a1		;'MB? (Y/N)'
		bsr	strcpy
		movea.l	sp,a1
		bsr	iocs_21_B_PRINT
		bsr	kflush
		do
			bsr	inkey
			bsr	toupper
		whileand	<cmp.b #'Y',d0>,ne,<cmp.b #'N',d0>,ne
		if	<cmp.b #'Y',d0>,eq
			unlocksram
				move.l	BIOS_MEMORY_SIZE.w,SRAM_MEMORY_SIZE
			locksram
		endif
		lea.l	103f(pc),a1		;26
		bsr	iocs_21_B_PRINT
		lea.l	128(sp),sp
	endif
	pop
	rts

100:	.dc.b	13,10
	.dc.b	'  Modify memory size setting from ',0
101:	.dc.b	'MB to ',0
102:	.dc.b	'MB? (y/n)',0
103:	.dc.b	26,0
	.even



;----------------------------------------------------------------
;���s���R�s�[����
;<a0.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
crlf:
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;�����Ȃ�������16�i��4���̕�����ɕϊ�����
;<d0.w:�����Ȃ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
h4tos:
	push	d1-d2
	moveq.l	#4-1,d1
	for	d1
		rol.w	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	100f(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

100:	.dc.b	'0123456789ABCDEF'
	.even

;----------------------------------------------------------------
;�����Ȃ�������16�i��8���̕�����ɕϊ�����
;<d0.l:�����Ȃ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
h8tos:
	push	d1-d2
	moveq.l	#8-1,d1
	for	d1
		rol.l	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	100f(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

100:	.dc.b	'0123456789ABCDEF'
	.even

;----------------------------------------------------------------
;�����R�[�h��0�łȂ��L�[���������܂ő҂�
;>d0.b:�����R�[�h
inkey:
	do
		IOCS	_B_KEYINP
	while	<tst.b d0>,eq
	rts

;----------------------------------------------------------------
;�L�[���̓o�b�t�@����ɂ���
kflush:
	push	d0
	IOCS	_B_KEYSNS
	while	<tst.l d0>,ne
		IOCS	_B_KEYINP
		IOCS	_B_KEYSNS
	endwhile
	pop
	rts

;----------------------------------------------------------------
;��������R�s�[����
;<a0.l:�R�s�[��
;<a1.l:�R�s�[��
;>a0.l:�R�s�[���0�̈ʒu
;>a1.l:�R�s�[����0�̎��̈ʒu
strcpy:
	do
		move.b	(a1)+,(a0)+
	while	ne
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;�啶���ɂ���
;<d0.b:�����R�[�h
;>d0.b:�����R�[�h
toupper:
	ifand	<cmp.b #'a',d0>,hs,<cmp.b #'z',d0>,ls
		add.b	#'A'-'a',d0
	endif
	rts

;----------------------------------------------------------------
;�����Ȃ�������10�i���̕�����ɕϊ�����
;<d0.l:�����Ȃ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
utos:
	push	d0-d2/a1
	if	<tst.l d0>,eq
		move.b	#'0',(a0)+
	else
		lea.l	utos_table(pc),a1
		do
			move.l	(a1)+,d1
		while	<cmp.l d1,d0>,lo	;������Ƃ���܂Ői��
		do
			moveq.l	#'0'-1,d2
			do
				addq.b	#1,d2
				sub.l	d1,d0
			while	hs			;������񐔂𐔂���
			move.b	d2,(a0)+
			add.l	d1,d0			;�������������������߂�
			move.l	(a1)+,d1
		while	ne
	endif
	clr.b	(a0)
	pop
	rts

utos_table:
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
;�����Ȃ�������10�i���̕�����ɕϊ�����(�[���[�U)
;<d0.l:�����Ȃ�����
;<d1.l:�ŏ�����
;<a0.l:�o�b�t�@
;>a0.l:�o�b�t�@��0�̈ʒu
utosz:
	push	d0-d2/a1
	moveq.l	#10,d2
	sub.l	d1,d2
	if	lo
		do
			move.b	#'0',(a0)+
			addq.l	#1,d2
		while	ne			;����Ȃ�0����ׂ�
	endif
	lea.l	utos_table(pc),a1
	for	d2
		move.l	(a1)+,d1
	next	<cmp.l d1,d0>,lo	;�ŏ������܂��͈�����Ƃ���܂Ői��
	do
		moveq.l	#'0'-1,d2
		do
			addq.b	#1,d2
			sub.l	d1,d0
		while	hs			;������񐔂𐔂���
		move.b	d2,(a0)+
		add.l	d1,d0			;�������������������߂�
		move.l	(a1)+,d1
	while	ne
	clr.b	(a0)
	pop
	rts



  .if 0
;----------------------------------------------------------------
;�o�X�G���[�𖳎�����1�o�C�g�ǂݏo��
;<a0.l:�A�h���X
;>d0.b:�f�[�^�B�o�X�G���[�̂Ƃ�0
;>a0.l:�A�h���X+1
;>c:cc=�o�X�G���[�Ȃ�,cs=�o�X�G���[����
read_byte:
	push	d1/a1
	di				;sr�ۑ��A���荞�݋֎~
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;�o�X�G���[�x�N�^�ۑ�
	lea.l	@f(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp�ۑ�
	moveq.l	#0,d0
;		  XNZVC
	moveq.l	#%00001,d1		;c=1
	nop
	move.b	(a0)+,d0		;1�o�C�g�ǂݏo��
	nop
	moveq.l	#%00000,d1		;c=0
@@:	movea.l	a1,sp			;sp����
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;�o�X�G���[�x�N�^����
	ei				;sr����
	move.w	d1,ccr
	pop
	rts
  .endif

;----------------------------------------------------------------
;�o�X�G���[�𖳎�����1���[�h�ǂݏo��
;<a0.l:�A�h���X�B��͕s��
;>d0.w:�f�[�^�B�o�X�G���[�̂Ƃ�0
;>a0.l:�A�h���X+2
;>c:cc=�o�X�G���[�Ȃ�,cs=�o�X�G���[����
read_word:
	push	d1/a1
	di				;sr�ۑ��A���荞�݋֎~
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;�o�X�G���[�x�N�^�ۑ�
	lea.l	@f(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp�ۑ�
	moveq.l	#0,d0
;		  XNZVC
	moveq.l	#%00001,d1		;c=1
	nop
	move.w	(a0)+,d0		;1���[�h�ǂݏo��
	nop
	moveq.l	#%00000,d1		;c=0
@@:	movea.l	a1,sp			;sp����
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;�o�X�G���[�x�N�^����
	ei				;sr����
	move.w	d1,ccr
	pop
	rts

;----------------------------------------------------------------
;�o�X�G���[�𖳎�����1�����O�ǂݏo��
;<a0.l:�A�h���X�B��͕s��
;>d0.l:�f�[�^�B�o�X�G���[�̂Ƃ�0
;>a0.l:�A�h���X+2
;>c:cc=�o�X�G���[�Ȃ�,cs=�o�X�G���[����
read_long:
	push	d1/a1
	di				;sr�ۑ��A���荞�݋֎~
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;�o�X�G���[�x�N�^�ۑ�
	lea.l	@f(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp�ۑ�
	moveq.l	#0,d0
;		  XNZVC
	moveq.l	#%00001,d1		;c=1
	nop
	move.l	(a0)+,d0		;1�����O�ǂݏo��
	nop
	moveq.l	#%00000,d1		;c=0
@@:	movea.l	a1,sp			;sp����
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;�o�X�G���[�x�N�^����
	ei				;sr����
	move.w	d1,ccr
	pop
	rts



;----------------------------------------------------------------
;	�N���ł��Ȃ�SCSI-ID�̃t���O�̕ۑ�
;		���̂܂�
;			_B_SCSI�̌��̃x�N�^���ړ������邱�Ƃɂ����̂ŋN���ł��Ȃ�SCSI-ID�̃t���O�͈ړ����Ă��Ȃ�
;			SASI�����@�̂Ƃ����Փ˂��邱�Ƃ͂Ȃ��͂�
;		00000112 1A380CC3         	move.b	BIOS_SCSI_UNBOOTABLE.w,d5
;		00000138 11C50CC3         	move.b	d5,BIOS_SCSI_UNBOOTABLE.w
;----------------------------------------------------------------



;----------------------------------------------------------------
;	�N���b�N�v��
;		00FF013C 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;			:
;		00FF019C
;----------------------------------------------------------------
	PATCH_DATA	clock_check,$00FF013C,$00FF019B,$0C380001
	jsr	clock_check
	bra	($00FF019C)PATCH_ZL
	PATCH_TEXT
;----------------------------------------------------------------
;�N���b�N�v��
clock_check:

;�V�X�e���N���b�N�̊m�F
	moveq.l	#0,d0
	move.b	SYSPORT_MODEL,d0	;�@�픻�ʁB$DC=X68030,$FE=XVI��16MHz,$FF=XVI�ȑO��10MHz
					;$00FF=10MHz,$00FE=16MHz,$00DC=25MHz
	not.b	d0			;$0000=10MHz,$0001=16MHz,$0023=25MHz
	lsl.w	#4,d0			;$0000=10MHz,$0010=16MHz,$0230=25MHz
	lsr.b	#4,d0			;$0000=10MHz,$0001=16MHz,$0203=25MHz
	move.w	d0,BIOS_CLOCK_SWITCH.w	;�N���b�N�X�C�b�`�B$0000=10MHz,$0001=16MHz,$0203=25MHz

;�N���b�N�v���̂��߂̃L���b�V��ON
;	68030�̂Ƃ��͖��߃L���b�V���ƃf�[�^�L���b�V����ON�ɂ���
;	68040/68060�̃f�[�^�L���b�V����68060�̃X�g�A�o�b�t�@��MMU��L���ɂ���܂�ON�ɂł��Ȃ��̂Ŗ��߃L���b�V������ON�ɂ���
;	SRAM�̃L���b�V���̐ݒ�͂������Ŕ��f�����
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;68000/68010�̓L���b�V���Ȃ�
		move.l	#$00002101,d0		;68020/68030�͖��߃L���b�V��ON(bit0)�A68030�̓f�[�^�L���b�V��ON(bit8)
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,hs
			if	hi
				.cpu	68060
				movec.l	pcr,d0
				bset.l	#0,d0			;68060�̓X�[�p�[�X�J��ON(bit0)
				movec.l	d0,pcr
				.cpu	68000
				move.l	#$00800000,d0		;68060�̓X�g�A�o�b�t�@OFF(bit29),����L���b�V��ON(bit23)
			endif
			move.w	#$8000,d0		;68040/68060�̓f�[�^�L���b�V��OFF(bit31),���߃L���b�V��ON(bit15)
		endif
		.cpu	68030
		movec.l	d0,cacr
		.cpu	68000
		clr.b	SYSPORT_WAIT
	endif

;�N���b�N�v��
;ROM�v��
	lea.l	clock_loop(pc),a0	;�v�����[�v
	bsr	clock_sub		;�v���T�u
	move.l	d0,BIOS_MPU_SPEED_ROM_LONG.w
	if	<cmp.l #$0000FFFF,d0>,hi
		moveq.l	#-1,d0
	endif
	move.w	d0,BIOS_MPU_SPEED_ROM.w
;RAM�v��
	lea.l	-30(sp),sp
	move.l	sp,d0
	add.w	#14,d0
	and.w	#-16,d0
	movea.l	d0,a0			;16�o�C�g���E����n�܂�16�o�C�g�̃��[�N�G���A
	movem.l	clock_loop(pc),d0-d2/a1	;�v�����[�v�����[�N�G���A�ɃR�s�[����
	movem.l	d0-d2/a1,(a0)
;	�X�^�b�N�G���A�����߃L���b�V���ɏ���Ă��邱�Ƃ͂Ȃ��̂ŃL���b�V���t���b�V���͏ȗ�����
	bsr	clock_sub		;�v���T�u
	lea.l	30(sp),sp
	move.l	d0,BIOS_MPU_SPEED_RAM_LONG.w
	if	<cmp.l #$0000FFFF,d0>,hi
		moveq.l	#-1,d0
	endif
	move.w	d0,BIOS_MPU_SPEED_RAM.w
	rts

;�v���T�u
;>d0.l:�v���l�B0=���s
;?d1-d2/a1
clock_sub:
aTCDCR	reg	a1
	lea.l	MFP_TCDCR,aTCDCR
;�񐔏�����
	moveq.l	#22-8+1,d2
	do
		subq.w	#1,d2
		move.l	#1<<22,d0
		lsr.l	d2,d0
		subq.l	#1,d0
	;���荞�݋֎~
		di
	;�^�C�}�ۑ�
		move.b	MFP_IERB-MFP_TCDCR(aTCDCR),-(sp)
		move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(sp)
		move.b	MFP_TCDCR-MFP_TCDCR(aTCDCR),-(sp)
	;�^�C�}�ݒ�
		andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�݋֎~
		andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�ݒ�~�BIPRB�N���A
	;�J�E���g��~
		move.b	#0,(aTCDCR)		;Timer-C/D�J�E���g��~
		do
		while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�
	;�J�E���g�J�n
		move.b	#0,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^�N���A
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
		move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/D�J�E���g�J�n
						;Timer-C��1/200�v���X�P�[��(50us)
						;Timer-D��1/4�v���X�P�[��(1us)
	;�v��
		jsr	(a0)
	;�J�E���g��~
		move.b	#0,(aTCDCR)		;Timer-C/D�J�E���g��~
		do
		while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�
	;�^�C�}�擾
		moveq.l	#0,d0
		moveq.l	#0,d1
		sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-C�J�E���g��
		sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-D�J�E���g��(�I�[�o�[�t���[����)
	;�^�C�}����
		move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^����
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
		move.b	(sp)+,(aTCDCR)
		move.b	(sp)+,MFP_IMRB-MFP_TCDCR(aTCDCR)
		move.b	(sp)+,MFP_IERB-MFP_TCDCR(aTCDCR)
	;���荞�݋���
		ei
	;�J�E���^����
		mulu.w	#50,d0
		if	<cmp.b d1,d0>,hi
			add.w	#256,d0
		endif
		move.b	d1,d0			;0|us
	whileand	<tst.w d2>,ne,<cmp.w #5000,d0>,lo	;5000us�ɖ����Ȃ���Ή񐔂�2�{�ɂ��Čv��������
	if	<tst.w d0>,ne
	;�␳
		lea.l	clock_scale(pc),a1
		moveq.l	#0,d1
		move.b	BIOS_MPU_TYPE.w,d1
		if	<cmp.w #6,d1>,ls
			lsl.w	#2,d1
			adda.w	d1,a1
		endif
		move.l	(a1),d1
		lsr.l	d2,d1			;d1=H|L
		divu.w	d0,d1			;d1=vc?(H|L)%us|(H|L)/us:H|L
		if	vc
			move.w	d1,d0			;d0=0|(H|L)/us
		else
			move.l	d1,d2			;d2=H|L
			clr.w	d2			;d2=H|0
			swap.w	d2			;d2=0|H
			divu.w	d0,d2			;d2=(0|H)%us|(0|H)/us
			swap.w	d0			;d0=us|0
			move.w	d2,d0			;d0=us|(0|H)/us
			swap.w	d0			;d0=(0|H)/us|us
			move.w	d1,d2			;d2=(0|H)%us|L
			divu.w	d0,d2			;d2=((0|H)%us|L)%us|((0|H)%us|L)/us
			move.w	d2,d0			;d0=(0|H)/us|((0|H)%us|L)/us
		endif
	endif
	rts

;�v�����[�v
	.align	16,$2048		;������dbra��.align 4�ɂ���BRAM�v����.align 16�Ȃ̂�ROM�v����.align 16�ɂ���
clock_loop:
	forlong	d0
	next
	rts

	.align	4
clock_scale:
	.dc.l	4194304000	;68000
	.dc.l	4194304000	;68010
	.dc.l	4194304000	;68020
	.dc.l	4194304000	;68030
	.dc.l	2796202667	;68040
	.dc.l	0
	.dc.l	699050667	;68060

;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  |           |c/n|   f   |u/n=c/n/f|  n | u=u/n*n|  J  |      K=c/n/J*2^22      |             CB8=K/(2^22/n)/u            |        f=CB8*J        |
;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  |68000/68010| 12| 10.000|  1.200  |2^13|9830.400|0.012|4194304000=12/0.012*2^22|  833.333=4194304000/(2^22/2^13)/9830.400| 10.000=  833.333*0.012|
;  |           |   | 16.667|  0.720  |2^13|5898.240|     |                        | 1388.889=4194304000/(2^22/2^13)/5898.240| 16.667= 1388.889*0.012|
;  |           |   | 25.000|  0.480  |2^14|7864.320|     |                        | 2083.333=4194304000/(2^22/2^14)/7864.320| 25.000= 2083.333*0.012|
;  |           |   | 33.333|  0.360  |2^14|5898.240|     |                        | 2777.778=4194304000/(2^22/2^14)/5898.240| 33.333= 2777.778*0.012|
;  |           |   | 50.000|  0.240  |2^15|7864.320|     |                        | 4166.667=4194304000/(2^22/2^15)/7864.320| 50.000= 4166.667*0.012|
;  |           |   | 66.666|  0.180  |2^15|5898.240|     |                        | 5555.556=4194304000/(2^22/2^15)/5898.240| 66.667= 5555.556*0.012|
;  |           |   |100.000|  0.120  |2^16|7864.320|     |                        | 8333.333=4194304000/(2^22/2^16)/7864.320|100.000= 8333.333*0.012|
;  |           |   |750.000|  0.016  |2^19|8388.608|     |                        |62500.000=4194304000/(2^22/2^19)/8388.608|750.000=62500.000*0.012|
;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  |68020/68030|  6| 25.000|  0.240  |2^15|7864.320|0.006|4194304000= 6/0.006*2^22| 4166.667=4194304000/(2^22/2^15)/7864.320| 25.000= 4166.667*0.006|
;  |           |   | 33.333|  0.180  |2^15|5898.240|     |                        | 5555.556=4194304000/(2^22/2^15)/5898.240| 33.333= 5555.556*0.006|
;  |           |   | 50.000|  0.120  |2^16|7864.320|     |                        | 8333.333=4194304000/(2^22/2^16)/7864.320| 50.000= 8333.333*0.006|
;  |           |   |375.000|  0.016  |2^19|8388.608|     |                        |62500.000=4194304000/(2^22/2^19)/8388.608|375.000=62500.000*0.006|
;  +-----------+---+-------+---------+----+--------+     +------------------------+-----------------------------------------+-----------------------+
;  |   68040   |  4| 25.000|  0.160  |2^15|5242.880|     |2796202667= 4/0.006*2^22| 4166.667=2796202667/(2^22/2^15)/5242.880| 25.000= 4166.667*0.006|
;  +-----------+---+-------+---------+----+--------+     +------------------------+-----------------------------------------+-----------------------+
;  |   68060   |  1| 33.333|  0.030  |2^18|7864.320|     | 699050667= 1/0.006*2^22| 5555.556= 699050667/(2^22/2^18)/7864.320| 33.333= 5555.556*0.006|
;  |           |   | 50.000|  0.020  |2^18|5242.880|     |                        | 8333.333= 699050667/(2^22/2^18)/5242.880| 50.000= 8333.333*0.006|
;  |           |   | 66.667|  0.015  |2^19|7864.320|     |                        |11111.111= 699050667/(2^22/2^19)/7864.320| 66.667=11111.111*0.006|
;  |           |   | 75.000|  0.013  |2^19|6990.507|     |                        |12500.000= 699050667/(2^22/2^19)/6990.507| 75.000=12500.000*0.006|
;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  �}��
;    c/n  dbra���[�v1��̃T�C�N����
;    f    ������g��(MHz)
;    u/n  dbra���[�v1��̏��v����(�}�C�N���b)
;    n    dbra���[�v�񐔁B2�̗ݏ��u��5000�ȏ�10000�����ɂȂ�悤�ɒ�������
;    u    dbra���[�vn��̏��v����(�}�C�N���b)
;    J    68000/68010�̂Ƃ�0.012�A68020/68030/68030/68060��0.006
;         dbra�ŕ��򂷂�Ƃ��̃T�C�N������68000��12�T�C�N���A68030��6�T�C�N���ł��邱�ƂɗR������
;    K    c/n/J*2^22�B�e�[�u��������o���B2^22��K��2^32�����ōő�ɂ��Č덷�����炷���߂̌W��
;    CB8  [$0CB8].w�̒l�BROM�Ōv������������g���BX68000��f*250/3�AX68030��f*500/3�B12�{�܂���6�{���邱�Ƃ�f*1000�Ƃ��ėp����
;  �⑫
;    68000/68010��dbra��10�T�C�N������ROM�̂Ƃ��̓E�G�C�g��������̂�12�T�C�N���ɂȂ�
;    RAM�̂Ƃ���DRAM�̃��t���b�V���̉e����(1+0.22/f)�{���炢�ɂȂ�



;----------------------------------------------------------------
;	�s�
;		MC68000�̂Ƃ��G���A�Z�b�g�̃|�[�g�����[�h���悤�Ƃ��ċN���ł��Ȃ�
;	���
;		IPLROM 1.2�܂�MOVE.B $00,$00E86001�������Ƃ��낪IPLROM 1.3��CLR.B $00E86001�ɕύX���ꂽ
;		MC68000��CLR.B�̓��C�g�̑O�Ƀ��[�h����
;		�G���A�Z�b�g�̃|�[�g$00E86001�͐^�Ƀ��C�g�I�����[�Ń��[�h����ƃo�X�G���[�ɂȂ�
;		����������MC68000�ł�CLR.B $00E86001���o�X�G���[�ɂȂ�
;		X68000��X68030��ROM���悹��ƋN���ł��Ȃ�������1��
;		�G�~�����[�^��CLR.B�̃��[�h���ȗ�����Ă���ꍇ�͋N���ł���
;	�΍�
;		SF.B�����[�h����̂�CLR.B��SF.B�ɕύX���Ă��ʖ�
;		���O�̃A���[���N���̏���$00FF05BE���畜�A�����Ƃ�A0�͏��RTC�̃A�h���X$00E8A000���w���Ă���̂ł�����g��
;	�Q�l
;		�ӂ��Ă�����̈�A�̍l�@
;		https://twitter.com/futtyt/status/1332591514963197953
;	�ύX�O
;		00FF01B2  423900E86001          clr.b   $00E86001
;		00FF01B8
;----------------------------------------------------------------
	PATCH_DATA	area_set,$00FF01B2,$00FF01B7,$423900E8
;<a0.l:$00E8A000
	move.b	#$00,$00E86001-$00E8A000(a0)



;----------------------------------------------------------------
;	LCD�Ή��L�[
;	�ύX�O
;		00FF0252  7213                  moveq.l	#$13,d1
;		00FF0254  43F80800              lea.l	BIOS_BITSNS.w,a1
;		00FF0258  082900050005          btst.b	#5,5(a1)		;V�L�[�BN|B|V|C|X|Z|]}|:*
;		00FF025E  660A                  bne.s	$00FF026A
;		00FF0260  7210                  moveq.l	#$10,d1
;		00FF0262  082900070005          btst.b	#7,5(a1)		;N�L�[�BN|B|V|C|X|Z|]}|:*
;		00FF0268  6718                  beq.s	$00FF0282
;		00FF026A  13FC003100E8E00D      move.b	#$31,$00E8E00D		;SRAM�������݋���
;		00FF0272  13C100ED001D          move.b	d1,$00ED001D		;�N�����̉�ʃ��[�h
;		00FF0278  423900E8E00D          clr.b	$00E8E00D		;SRAM�������݋֎~
;		00FF027E  70104E4F              IOCS	_CRTMOD
;		00FF0282
;----------------------------------------------------------------
	PATCH_DATA	lcd_key,$00FF0252,$00FF0281,$721343F8
	jsr	lcd_key
	bra	($00FF0282)PATCH_ZL
	PATCH_TEXT
lcd_key:
	moveq.l	#0,d1
	if	<btst.b #KEY_L&7,BIOS_BITSNS+(KEY_L>>3).w>,ne	;L�L�[��������Ă���
		move.w	#$4C00+16,d1		;��ʃ��[�h16(768x512)LCD����
;	elif	<btst.b #KEY_N&7,BIOS_BITSNS+(KEY_N>>3).w>,mi	;N�L�[��������Ă���
	elif	<tst.b BIOS_BITSNS+(KEY_N>>3).w>,mi	;N�L�[��������Ă���
		move.w	#$4300+16,d1		;��ʃ��[�h16(768x512)CRT����
	elif	<btst.b #KEY_T&7,BIOS_BITSNS+(KEY_T>>3).w>,ne	;T�L�[��������Ă���
		move.w	#$4300+3,d1		;��ʃ��[�h3(256x240�m���C���^�[���[�X)CRT����
	elif	<btst.b #KEY_V&7,BIOS_BITSNS+(KEY_V>>3).w>,ne	;V�L�[��������Ă���
		move.w	#$4C00+19,d1		;��ʃ��[�h19(640x480)LCD����
	endif
	bclr.b	#0,BIOS_STARTUP_FLAGS.w	;HITANYKEY=0
	if	<tst.w d1>,ne
		bset.b	#0,BIOS_STARTUP_FLAGS.w	;HITANYKEY=1
		unlocksram
		move.b	d1,SRAM_CRTMOD		;�N�����̉�ʃ��[�h
		locksram
		IOCS	_CRTMOD
	endif
	rts



;----------------------------------------------------------------
;	ROM�f�o�b�K
;		OPT.2�L�[��������Ă���Ƃ��ASRAM�ɂ���ROM�f�o�b�K�N���t���O��OFF�܂���CON�̂Ƃ�AUX�ɁAAUX�̂Ƃ�OFF�ɕύX���܂�
;		D�L�[��������Ă���Ƃ��ASRAM�ɂ���ROM�f�o�b�K�N���t���O��OFF�܂���AUX�̂Ƃ�CON�ɁACON�̂Ƃ�OFF�ɕύX���܂�
;		OPT.2�L�[�̌��ʂ��ꎞ�I�Ȃ��̂���i���I�Ȃ��̂ɕύX����Ă��邱�Ƃɒ��ӂ��Ă�������
;	�ύX�O
;		00FF0286 423809DE		clr.b	$09DE.w
;		00FF028A 1038080E		move.b	$080E.w,d0
;		00FF028E 123900ED0058		move.b	$00ED0058,d1
;		00FF0294 B300			eor.b	d1,d0
;		00FF0296 08000003		btst.l	#3,d0
;		00FF029A 670C			beq	$00FF02A8
;		00FF029C 11FC000109DE		move.b	#1,$09DE.w
;		00FF02A2 207AFD64		movea.l	$00FF0008(pc),a0
;		00FF02A6 4E90			jsr	(a0)
;		00FF02A8
;----------------------------------------------------------------
	PATCH_DATA	p0286,$00FF0286,$00FF02A7,$423809DE
	jsr	p0286
	bra	($00FF02A8)PATCH_ZL
	PATCH_TEXT
p0286:
	lea.l	SRAM_ROMDB,a0
	move.b	(a0),d0			;0=OFF,-1=AUX,1=CON
	do
		moveq.l	#1,d1			;1=CON
		if	<btst.b #KEY_D&7,BIOS_BITSNS+(KEY_D>>3).w>,eq	;D�L�[��������Ă��Ȃ�
			neg.b	d1			;-1=AUX
			break	<btst.b #KEY_OPT2&7,BIOS_BITSNS+(KEY_OPT2>>3).w>,eq	;OPT.2�L�[��������Ă��Ȃ�
		endif
	;D�L�[�܂���OPT.2�L�[��������Ă���
		if	<cmp.b d0,d1>,eq	;�t���O�Ɠ����L�[��������Ă���
			clr.b	d1			;0=OFF
		endif
		if	<cmp.b d0,d1>,ne	;�t���O���ω�����
			move.b	d1,d0
			lea.l	SYSPORT_SRAM,a1
			move.b	#$31,(a1)
			move.b	d0,(a0)
			clr.b	(a1)
		endif
	while	f
	neg.b	d0			;0=OFF,1=AUX,-1=CON
	move.b	d0,BIOS_ROMDB.w
	if	ne			;1=AUX,-1=CON
		movea.l	$00FF0008,a0		;ROM�f�o�b�K�̊J�n�A�h���X
		jsr	(a0)			;ROM�f�o�b�K���N������
	endif
	rts



;----------------------------------------------------------------
;	68040/68060�̂Ƃ��f�o�C�X�h���C�o��MMU��L���ɂ���܂Ńf�[�^�L���b�V����OFF�ɂ���
;	�ύX�O
;		00FF02A8 7202                   moveq.l	#$02,d1
;		00FF02AA 70AC                   moveq.l	#_SYS_STAT,d0
;		00FF02AC 4E4F                   trap	#15
;		00FF02AE
;----------------------------------------------------------------
	PATCH_DATA	cache_start,$00FF02A8,$00FF02AD,$720270AC
	jsr	cache_start
	PATCH_TEXT
cache_start:
	push	d2
	moveq.l	#0,d2
	move.b	SRAM_CACHE,d2		;�L���b�V���ݒ�B------|�f�[�^|����
	if	<cmpi.b #4,BIOS_MPU_TYPE.w>,hs	;68040/68060
		and.b	#.notb.%10,d2		;�f�[�^�L���b�V��OFF
	endif
	bsr	cache_set		;�L���b�V���ݒ�
	pop
	rts



;----------------------------------------------------------------
;	Hit any key
;	�ύX�O
;		00FF02B2 43FA08D4               lea.l	$00FF0B88(pc),a1	;$1A
;		00FF02B6 61000470               bsr.w	$00FF0728		;������\��
;		00FF02BA
;----------------------------------------------------------------
	PATCH_DATA	hitanykey,$00FF02B2,$00FF02B9,$43FA08D4
	jsr	hitanykey
	PATCH_TEXT
hitanykey:
	if	<btst.b #0,BIOS_STARTUP_FLAGS.w>,ne	;HITANYKEY
		lea.l	-64(sp),sp
		movea.l	sp,a0
		bsr	crlf
		bsr	start_proportional
		lea.l	100f(pc),a1		;'  Hit any key'
		bsr	strcpy
		bsr	end_proportional
		bsr	crlf
		movea.l	sp,a1
		bsr	iocs_21_B_PRINT
		lea.l	64(sp),sp
		do
			redo	<btst.b #KEY_L&7,BIOS_BITSNS+(KEY_L>>3).w>,ne	;L�L�[��������Ă���
		;	redo	<btst.b #KEY_N&7,BIOS_BITSNS+(KEY_N>>3).w>,ne	;N�L�[��������Ă���
			redo	<tst.b BIOS_BITSNS+(KEY_N>>3).w>,mi	;N�L�[��������Ă���
			redo	<btst.b #KEY_T&7,BIOS_BITSNS+(KEY_T>>3).w>,ne	;T�L�[��������Ă���
			redo	<btst.b #KEY_V&7,BIOS_BITSNS+(KEY_V>>3).w>,ne	;V�L�[��������Ă���
		while	f			;L/N/T/V�L�[���������܂ő҂�
		bsr	kflush			;�L�[�o�b�t�@����ɂ���
		bsr	inkey			;�L�[���������܂ő҂�
	endif
	rts

100:	.dc.b	'  Hit any key',0
	.even

;----------------------------------------------------------------
;�v���|�[�V���i���s�b�`�J�n
start_proportional:
	lea.l	100f(pc),a1
	bra	10f

;�v���|�[�V���i���s�b�`�I��
end_proportional:
	lea.l	101f(pc),a1
10:
	goto	<btst.b #0,message_style(pc)>,ne,strcpy	;�v���|�[�V���i���s�b�`
	clr.b	(a0)
	rts

100:	.dc.b	27,'[26m',0
101:	.dc.b	27,'[50m',0
	.even



;----------------------------------------------------------------
;	XF3,XF4,XF5�������Ȃ���N�������Ƃ��̃L���b�V��OFF
;	�ύX�O
;		00FF0336 7000                   moveq.l	#$00,d0
;		00FF0338 4E7B0002               movec.l	d0,cacr			;�L���b�V��OFF
;		00FF033C
;----------------------------------------------------------------
	PATCH_DATA	xf345_cache_off,$00FF0336,$00FF033B,$70004E7B
	jsr	cache_off		;�L���b�V��OFF



;----------------------------------------------------------------
;	XF1,XF2�������Ȃ���N�������Ƃ��̃L���b�V��OFF
;	�ύX�O
;		00FF0380 7000                   moveq.l	#$00,d0
;		00FF0382 4E7B0002               movec.l	d0,cacr			;�L���b�V��OFF
;		00FF0386
;----------------------------------------------------------------
	PATCH_DATA	xf12_cache_off,$00FF0380,$00FF0385,$70004E7B
	jsr	cache_off		;�L���b�V��OFF



;----------------------------------------------------------------
;	����`��O����
;		68000�̂Ƃ��o�X�G���[�ƃA�h���X�G���[�̗�O�X�^�b�N�t���[�����@��N�����Ȃ�
;			TRAP#14(�G���[�\��)��SSW��ACCESS ADDRESS��INSTRUCTION REGISTER�ɃA�N�Z�X�ł���
;		68000�ȊO�̂Ƃ�PC�̍ŏ�ʃo�C�g��$02�`$0F�Ȃ�΂�����x�N�^�ԍ��Ƃ��Ďg��
;			X68030�Ŗ���`��F���C�����߂����s�����Ƃ��u�G���[($000B)���������܂����v�ł͂Ȃ�
;			�u�������Ȗ��߂����s���܂����v�ƕ\�������
;	�ύX�O
;		00FF0762 7E00             	moveq.l	#$00,d7
;		00FF0764 3E2F0006         	move.w	$0006(sp),d7
;		00FF0768 CE7C0FFF         	and.w	#$0FFF,d7		;�x�N�^�I�t�Z�b�g
;		00FF076C E44F             	lsr.w	#2,d7			;�x�N�^�ԍ�
;		00FF076E 6042_000007B2    	bra	$00FF07B2		;�����\��
;		00FF0770 61000002_00000774	bsr	$00FF0774
;		00FF0774 2E1F             	move.l	(sp)+,d7		;$00FF0774���̂���
;		00FF0776 4A380CBC         	tst.b	BIOS_MPU_TYPE.w
;		00FF077A 66E6_00000762    	bne	$00FF0762
;		00FF077C 4247             	clr.w	d7
;		00FF077E 4847             	swap.w	d7
;		00FF0780 E04F             	lsr.w	#8,d7
;		00FF0782 BE7C0003         	cmp.w	#$0003,d7
;		00FF0786 622A_000007B2    	bhi	$00FF07B2
;		00FF0788 5C8F             	addq.l	#6,sp
;		00FF078A 4847             	swap.w	d7
;		00FF078C 3E1F             	move.w	(sp)+,d7		;���߃R�[�h
;		00FF078E 2C6F0002         	movea.l	$0002(sp),a6		;PC
;		00FF0792 BE56             	cmp.w	(a6),d7
;		00FF0794 6714_000007AA    	beq	$00FF07AA
;		00FF0796 BE66             	cmp.w	-(a6),d7
;		00FF0798 6710_000007AA    	beq	$00FF07AA
;		00FF079A BE66             	cmp.w	-(a6),d7
;		00FF079C 670C_000007AA    	beq	$00FF07AA
;		00FF079E BE66             	cmp.w	-(a6),d7
;		00FF07A0 6708_000007AA    	beq	$00FF07AA
;		00FF07A2 BE66             	cmp.w	-(a6),d7
;		00FF07A4 6704_000007AA    	beq	$00FF07AA
;		00FF07A6 BE66             	cmp.w	-(a6),d7
;		00FF07A8 6604_000007AE    	bne	$00FF07AE
;		00FF07AA 2F4E0002         	move.l	a6,$0002(sp)		;PC���G���[�������������߂܂Ŗ߂�
;		00FF07AE 4247             	clr.w	d7
;		00FF07B0 4847             	swap.w	d7
;		00FF07B2 2C4F             	movea.l	sp,a6
;		00FF07B4 4E4E             	trap	#14
;		00FF07B6 303C00FF         	move.w	#_ABORTJOB,d0
;		00FF07BA 4E4F             	trap	#15
;		00FF07BC 60F8_000007B6    	bra	$00FF07B6		;�������[�v
;		00FF07BE
;----------------------------------------------------------------
	PATCH_DATA	p0770,$00FF0770,$00FF0775,$61000002
	jsr	p0770			;������PC���v�b�V������Bjmp��PC�̍ŏ�ʃo�C�g�������Ă��܂��̂ŕs��
	PATCH_TEXT
p0770:
	moveq.l	#0,d7
	move.b	(sp),d7			;PC�̍ŏ�ʃo�C�g
	addq.l	#4,sp
	movea.l	sp,a6			;SR�̈ʒu�B68000�̃o�X�G���[�ƃA�h���X�G���[������
	if	<tst.b BIOS_MPU_TYPE.w>,eq	;68000
		ifor	<cmp.b #$02,d7>,eq,<cmp.b #$03,d7>,eq	;�o�X�G���[�ƃA�h���X�G���[
		;	MC68000UM 6-17
		;	0.w
		;	  15-5 4   3   2-0
		;	  X    R/W I/N FC
		;	  R/W  0=Write,1=Read
		;	  I/N  0=Instruction,1=Not
		;	2.l  ACCESS ADDRESS
		;	6.w  INSTRUCTION REGISTER
		;	8.w  STATUS REGISTER
		;	10.l  PROGRAM COUNTER
			swap.w	d7
			move.w	6(sp),d7		;���߃R�[�h
			movea.l	10(sp),a6		;PC
			do
				if	<cmp.w (a6),d7>,ne
					if	<cmp.w -(a6),d7>,ne
						if	<cmp.w -(a6),d7>,ne
							if	<cmp.w -(a6),d7>,ne
								if	<cmp.w -(a6),d7>,ne
									break	<cmp.w -(a6),d7>,ne
								endif
							endif
						endif
					endif
					move.l	a6,10(sp)		;PC���G���[�������������߂܂Ŗ߂�
				endif
			while	f
			clr.w	d7
			swap.w	d7
			lea.l	8(sp),a6		;SR�̈ʒu�BSP���@��N�����Ȃ�
		endif
	else				;68000�ȊO
		ifor	<cmp.b #$02,d7>,lo,<cmp.b #$0F,d7>,hi	;$02�`$0F�ȊO
			move.w	6(sp),d7		;�t�H�[�}�b�g�ƃx�N�^�I�t�Z�b�g
			and.w	#$0FFF,d7		;�x�N�^�I�t�Z�b�g
			lsr.w	#2,d7			;�x�N�^�ԍ�
		endif
	endif
	trap	#14			;TRAP#14(�G���[�\��)
10:	IOCS	_ABORTJOB
	goto	10b			;�������[�v



;----------------------------------------------------------------
;	IOCS _ABORTJOB
;		TRAP#14(�G���[�\��)�̕ύX�ɍ��킹�ĕ\����ύX����
;	�ύX�O
;		00FF07BE 6128			bsr	$00FF07E8		;��ʃ��[�h�ɂ���ăe�L�X�g��ʂ̕\���ʒu�𒲐߂���
;		00FF07C0 43F900FF0B53		lea.l	$00FF0B53,a1		;�G���[���������܂����B���Z�b�g���Ă��������B
;		00FF07C6 6100FF60		bsr	$00FF0728		;������\��
;		00FF07CA 60FE			bra	$00FF07CA		;�������[�v
;----------------------------------------------------------------
	PATCH_DATA	p07BE,$00FF07BE,$00FF07CB,$612843F9
	jsr	p07BE
	PATCH_TEXT
p07BE:
	lea.l	-64(sp),sp
	movea.l	sp,a0
	bsr	start_proportional
	lea.l	100f(pc),a1		;'  Press the RESET switch'
	bsr	strcpy
	bsr	end_proportional
	movea.l	sp,a1
	bsr	iocs_21_B_PRINT
	lea.l	64(sp),sp
10:
	goto	10b			;�������[�v

100:	.dc.b	'  Press the RESET switch',0
	.even



;----------------------------------------------------------------
;	�N�����
;	�ύX�O
;		00FF0E76 48E7F0E0       	movem.l	d0-d3/a0-a2,-(sp)
;		00FF0E7A 6100025C       	bsr	$00FF10D8		;�N����
;		00FF0E7E 6120           	bsr	$00FF0EA0		;���S
;		00FF0E80 7200           	moveq.l	#$00,d1
;		00FF0E82 70AC4E4F       	IOCS	_SYS_STAT
;		00FF0E86 2600           	move.l	d0,d3
;		00FF0E88 61000182       	bsr	$00FF100C		;ROM�̃o�[�W����
;		00FF0E8C 615C           	bsr	$00FF0EEA		;MPU�̎�ނƓ�����g��
;		00FF0E8E 610000EE       	bsr	$00FF0F7E		;FPU/FPCP�̗L��
;		00FF0E92 610000F8       	bsr	$00FF0F8C		;MMU�̗L��
;		00FF0E96 61000104       	bsr	$00FF0F9C		;���C���������̃T�C�Y
;		00FF0E9A 4CDF070F       	movem.l	(sp)+,d0-d3/a0-a2
;		00FF0E9E 4E75           	rts
;		00FF0EA0
;----------------------------------------------------------------
	PATCH_DATA	ipl_message,$00FF0E76,$00FF0E9F,$48E7F0E0
	jmp	ipl_message
	PATCH_TEXT
;----------------------------------------------------------------
;�N����ʂ�\������
ipl_message:
	push	d0-d7/a0-a6,128
;�L�[�m�F
;	SRAM_XEIJ��_CRTMOD�ŏ������ς�
	lea.l	SRAM_XEIJ,a0
	lea.l	SYSPORT_SRAM,a1
	moveq.l	#$31,d2
	if	<btst.b #0,BIOS_STARTUP_FLAGS.w>,ne	;HITANYKEY
		move.b	d2,(a1)			;unlocksram
		bclr.b	#SRAM_XEIJ_QUIET_BIT,(a0)	;�N����ʂ�\������
		clr.b	(a1)			;locksram
	elif	<btst.b #KEY_Q&7,BIOS_BITSNS+(KEY_Q>>3).w>,ne	;Q�L�[��������Ă���
		move.b	d2,(a1)			;unlocksram
		bset.b	#SRAM_XEIJ_QUIET_BIT,(a0)	;�N����ʂ�\�����Ȃ�
		clr.b	(a1)			;locksram
	endif
	if	<btst.b #SRAM_XEIJ_QUIET_BIT,(a0)>,eq	;�N����ʂ�\������
		jsr	$00FF10D8		;�N����
		jsr	$00FF0EA0		;���S
		moveq.l	#0,d1
		IOCS	_SYS_STAT
		move.l	d0,d7			;MPU�X�e�[�^�X
	;<d7.l:MPU�X�e�[�^�X
		movea.l	sp,a6			;������o�b�t�@
	;<a6.l:������o�b�t�@
		movea.l	a6,a0
		if	<btst.b #2,message_style(pc)>,ne	;���Ԃ���
			bsr	crlf
		endif
		bsr	start_proportional
		movea.l	a6,a1
		bsr	iocs_21_B_PRINT
	;���b�Z�[�W
		bsr	ipl_message_romver	;ROM�̃o�[�W������\������
		bsr	ipl_message_model	;�@���\������
		bsr	ipl_message_series	;�V���[�Y��\������
		bsr	ipl_message_mpu		;MPU�̎�ނƓ�����g����\������
		bsr	ipl_message_mmu		;MMU�̗L����\������
		bsr	ipl_message_fpu		;FPU/FPCP�̗L���Ǝ�ނ�\������
		bsr	ipl_message_memory	;���C���������͈̔͂Ɨe�ʂ�\������
		bsr	ipl_message_exmemory	;�g���������͈̔͂Ɨe�ʂ�\������
		bsr	ipl_message_coprocessor	;�R�v���Z�b�T�̗L���Ǝ�ނ�\������
		bsr	ipl_message_dmac_clock	;DMAC�̓�����g����\������
		bsr	ipl_message_rtc_dttm	;RTC�̓�����\������
		bsr	ipl_message_hd_type	;�����n�[�h�f�B�X�N�C���^�[�t�F�C�X�̎�ނ�\������
		bsr	ipl_message_boot_device	;�N���f�o�C�X��\������
	;�e�L�X�g�J�[�\����������7�s�ڂɈړ�������
		movea.l	a6,a0
		move.b	#27,(a0)+
		move.b	#'=',(a0)+
		moveq.l	#' '-6,d0
		add.w	BIOS_CONSOLE_BOTTOM.w,d0
		move.b	d0,(a0)+		;�s
		move.b	#' '+0,(a0)+		;��
		bsr	end_proportional
		movea.l	a6,a1
		bsr	iocs_21_B_PRINT
	endif
	pop
	rts

;----------------------------------------------------------------
;���̗��\������
;<a1.l:������B�R�������܂܂Ȃ�
;<a6.l:������o�b�t�@
;?d0/a0-a1
print_left_column:
	movea.l	a6,a0			;������o�b�t�@
	if	<btst.b #1,message_style(pc)>,ne	;������
		move.b	#27,(a0)+
		move.b	#'[',(a0)+
		moveq.l	#1,d0
		add.w	BIOS_CONSOLE_RIGHT.w,d0
		lsl.w	#2,d0			;�R���\�[���̕�(px)/2
		bsr	utos
		move.b	#'r',(a0)+		;���̗�𒆉��܂ł̉E�񂹂ŕ\������
		bsr	strcpy
		lea.l	100f(pc),a1		;' : ',1
		bsr	strcpy
	else				;����
		move.l	a1,d0
		if	<btst.b #0,message_style(pc)>,ne	;�v���|�[�V���i���s�b�`
			lea.l	101f(pc),a1		;27,'[320l'�B����40����
		else				;�m�[�}���s�b�`
			lea.l	102f(pc),a1		;27,'[304l'�B����38����
		endif
		bsr	strcpy
		movea.l	d0,a1
		bsr	strcpy
		lea.l	103f(pc),a1		;1,' : '
		bsr	strcpy
	endif
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	' : ',1,0
101:	.dc.b	27,'[320l',0
102:	.dc.b	27,'[304l',0
103:	.dc.b	1,' : ',0
	.even

;----------------------------------------------------------------
;ROM�̃o�[�W������\������
;<a6.l:������o�b�t�@
;?d0-d1/a0-a1
ipl_message_romver:
	lea.l	100f(pc),a1		;'ROM version'
	bsr	print_left_column
	IOCS	_ROMVER
;BCD�ϊ�
	move.l	d0,d1			;abcdefgh
	clr.w	d0			;abcd0000
	sub.l	d0,d1			;0000efgh
	swap.w	d0			;0000abcd
	lsl.l	#4,d0			;000abcd0
	lsl.l	#4,d1			;000efgh0
	lsr.w	#4,d0			;000a0bcd
	lsr.w	#4,d1			;000e0fgh
	lsl.l	#8,d0			;0a0bcd00
	lsl.l	#8,d1			;0e0fgh00
	lsr.w	#4,d0			;0a0b0cd0
	lsr.w	#4,d1			;0e0f0gh0
	lsr.b	#4,d0			;0a0b0c0d
	lsr.b	#4,d1			;0e0f0g0h
	or.l	#$30303030,d0		;3a3b3c3d
	or.l	#$30303030,d1		;3e3f3g3h
;�o�[�W����
	movea.l	a6,a0			;������o�b�t�@
	rol.l	#8,d0
	move.b	d0,(a0)+
	move.b	#'.',(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
;���t
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	rol.l	#8,d0
	if	<cmp.b #'8',d0>,hs
		move.b	#'1',(a0)+
		move.b	#'9',(a0)+
	else
		move.b	#'2',(a0)+
		move.b	#'0',(a0)+
	endif
	move.b	d0,(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
	move.b	#'-',(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	move.b	#'-',(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	move.b	#')',(a0)+
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'ROM Version',0
	.even

;----------------------------------------------------------------
;�@���\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?a0-a1
ipl_message_model:
	if	<cmpi.l #'NAME',$00FFFFE0>,ne	;�@�햼���Ȃ�
		rts
	endif
	lea.l	100f(pc),a1		;'Model'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	$00FFFFE4,a1
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Model',0
	.even

;----------------------------------------------------------------
;�V���[�Y��\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?a0-a1
ipl_message_series:
	lea.l	100f(pc),a1		;'Series'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	101f(pc),a1		;'X68000'
	if	<isX68030>,eq
		lea.l	102f(pc),a1		;'X68030'
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Series',0
101:	.dc.b	'X68000',0
102:	.dc.b	'X68030',0
	.even

;----------------------------------------------------------------
;MPU�̎�ނƓ�����g����\������
;	XC��MC
;		000/010/020/030/040��MC
;		060�̓��r�W����5�܂�XC�A���r�W����6����MC
;			http://www.ppa.pl/forum/amiga/29981/68060-pcr
;			?	���r�W����0
;			F43G	���r�W����1
;			G65V	���r�W����5
;			G59Y	?
;			E41J	���r�W����6
;	�����EC��LC
;		000/010/020�͖���
;		030��MMU���Ȃ��Ƃ�EC�AMMU������Ƃ�����
;		040/060��MMU���Ȃ��Ƃ�EC�AMMU��������FPU���Ȃ��Ƃ�LC�AMMU��FPU������Ƃ�����
;	���r�W�����i���o�[
;		060�̂Ƃ�������-ddd�Ń��r�W�����i���o�[��\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0-d2/a0-a1
ipl_message_mpu:
	lea.l	100f(pc),a1		;'Microprocessor'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
;�^��
	moveq.l	#-1,d2			;���r�W�����i���o�[�B-1=���r�W�����i���o�[�Ȃ�
	moveq.l	#'M',d1
	if	<cmp.b #6,d7>,eq	;060
		.cpu	68060
		movec.l	pcr,d0
		.cpu	68000
		lsr.l	#8,d0
		moveq.l	#0,d2
		move.b	d0,d2			;���r�W�����i���o�[
		if	<cmp.b #6,d2>,lo
			moveq.l	#'X',d1		;060�̓��r�W����5�܂�XC
		endif
	endif
	move.b	d1,(a0)+		;'M'�܂���'X'
	lea.l	101f(pc),a1		;'C68'
	bsr	strcpy
	do
		break	<cmp.b #3,d7>,lo	;000/010/020�͖���
		moveq.l	#'E',d1			;030/040/060��MMU���Ȃ��Ƃ�EC
		if	<btst.l #14,d7>,ne	;030/040/060��MMU������Ƃ�
			break	<cmp.b #3,d7>,eq	;030��MMU������Ƃ�����
			break	<tst.w d7>,mi		;040/060��MMU��FPU������Ƃ�����
			moveq.l	#'L',d1			;040/060��MMU��������FPU���Ȃ��Ƃ�LC
		endif
		move.b	d1,(a0)+		;'E'�܂���'L'
		move.b	#'C',(a0)+		;'C'
	while	f
	move.b	#'0',(a0)+		;'0'
	moveq.l	#'0',d1
	add.b	d7,d1
	move.b	d1,(a0)+		;'0'�`'6'
	move.b	#'0',(a0)+		;'0'
	move.l	d2,d0			;���r�W�����i���o�[
	if	pl
		move.b	#'-',(a0)+
		moveq.l	#3,d1
		bsr	utosz
	endif
;������g��
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	move.l	d7,d0
	clr.w	d0
	swap.w	d0			;������g��(MHz)*10
	bsr	utos
	move.b	-1(a0),(a0)+		;�����_�ȉ�1���ڂ����ɂ��炷
	move.b	#'.',-2(a0)		;�����_����������
	lea.l	102f(pc),a1		;'MHz)'
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Microprocessor',0
101:	.dc.b	'C68',0
102:	.dc.b	'MHz)',0
	.even

;----------------------------------------------------------------
;FPU/FPCP�̗L���Ǝ�ނ�\������
;	030��fmovecr.x #1,fp0��0�̂Ƃ�MC68881�A�����Ȃ���MC68882
;	040/060��on-chip
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0/a0-a1
ipl_message_fpu:
	if	<tst.w d7>,pl		;FPU/FPCP�Ȃ�
		rts
	endif
	lea.l	100f(pc),a1		;'Floating-Point Unit (FPU)'
	if	<cmp.b #4,d7>,lo	;020/030
		lea.l	101f(pc),a1		;'Floating-Point Coprocessor (FPCP)'
	endif
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	102f(pc),a1		;'on-chip'
	if	<cmp.b #4,d7>,lo	;020/030
		lea.l	103f(pc),a1		;'MC68881'
		.cpu	68030
		fmovecr.x	#1,fp0		;0=MC68881,0�ȊO=MC68882
		fmove.x	fp0,-(sp)
		.cpu	68000
		move.l	(sp)+,d0
		or.l	(sp)+,d0
		or.l	(sp)+,d0
		if	ne
			lea.l	104f(pc),a1		;'MC68882'
		endif
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Floating-Point Unit (FPU)',0
101:	.dc.b	'Floating-Point Coprocessor (FPCP)',0
102:	.dc.b	'on-chip',0
103:	.dc.b	'MC68881',0
104:	.dc.b	'MC68882',0
	.even

;----------------------------------------------------------------
;MMU�̗L����\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0/a0-a1
ipl_message_mmu:
	if	<btst.l #14,d7>,eq	;MMU�Ȃ�
		rts
	endif
	lea.l	100f(pc),a1		;'Memory Management Unit (MMU)'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	101f(pc),a1		;'on-chip'
	if	<cmp.b #3,d7>,lo	;020
		lea.l	102f(pc),a1		;'MC68851'
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Memory Management Unit (MMU)',0
101:	.dc.b	'on-chip',0
102:	.dc.b	'MC68851',0
	.even

;----------------------------------------------------------------
;���C���������͈̔͂Ɨe�ʂ�\������
;	$00100000-$00BFFFFF�ɂ���1MB�P�ʂŃ��C���������̗L�����m�F���A���C�������������݂���͈͂�\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0-d1/a0-a1
ipl_message_memory:
	lea.l	100f(pc),a1		;'Main Memory'
	bsr	print_left_column
	moveq.l	#0,d0			;�J�n�A�h���X
	move.l	BIOS_MEMORY_SIZE.w,d1	;�I���A�h���X(������܂܂Ȃ�)
;----------------------------------------------------------------
;�������͈̔͂Ɨe�ʂ�\������
;<d0.l:�J�n�A�h���X
;<d1.l:�I���A�h���X(������܂܂Ȃ�)
;<a6.l:������o�b�t�@
;?d0/a0-a1
ipl_message_memory_sub:
	movea.l	a6,a0			;������o�b�t�@
	move.b	#'$',(a0)+
	bsr	h8tos			;�J�n�A�h���X
	move.b	#'-',(a0)+
	move.b	#'$',(a0)+
	move.l	d0,-(sp)		;�J�n�A�h���X
	move.l	d1,d0			;�I���A�h���X(������܂܂Ȃ�)
	subq.l	#1,d0			;�I���A�h���X(������܂�)
	bsr	h8tos
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	move.l	d1,d0			;�I���A�h���X(������܂܂Ȃ�)
	sub.l	(sp)+,d0		;�I���A�h���X(������܂܂Ȃ�)-�J�n�A�h���X=�e��
	clr.w	d0
	swap.w	d0
	lsr.w	#4,d0			;�e��(16MB�P��)
	bsr	utos
	lea.l	101f(pc),a1		;'MB)'
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Main Memory',0
101:	.dc.b	'MB)',0
	.even

;----------------------------------------------------------------
;�g���������͈̔͂Ɨe�ʂ�\������
;	$01000000-$FFFFFFFF�ɂ���16MB�P�ʂœƗ������g���������̗L�����m�F���A�g�������������݂���͈͂�\������
;	�菇
;		�e�y�[�W�̓����I�t�Z�b�g�ɏ�ʂ̃y�[�W���珇�ɈقȂ�f�[�^����������
;		���ʂ̃y�[�W�ɏ������񂾂��Ƃŏ�ʂ̃y�[�W�̃f�[�^���ω������ꍇ�͏�ʂ̃y�[�W�͑��݂��Ȃ��Ɣ��f����
;		$2000-$21FF�����[�N�Ƃ��Ďg�p����
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0-d1/a0-a3/a5
ipl_message_exmemory:
;	if	<cmp.b #2,d7>,lo	;000/010
;		rts
;	endif
;�m�F�J�n
	di				;sr�ۑ��A���荞�݋֎~
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;�o�X�G���[�x�N�^�ۑ�
	movea.l	sp,a5			;sp�ۑ�
;�ǂݏo���A�ۑ�
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2			;�y�[�W�̐擪�Ba2=page<<24
	lea.l	$2200.w,a1		;�ۑ��̈�Ba1=$2100+page
	lea.l	$2100.w,a0		;���ʗ̈�Ba0=$2000+page
	move.w	#$00FF,d1		;�y�[�W�ԍ��Bd1=page
	for	d1
		suba.l	#$01000000,a2
		subq.l	#1,a1
		st.b	-(a0)			;$FF=�ǂݏo�����s
		nop
		move.b	(a2),(a1)		;�ǂݏo���A�ۑ��B-(a1)�̓o�X�G���[�̂Ƃ������̂ŕs��
		nop
		sf.b	(a0)			;$00=�ǂݏo������
	@@:	movea.l	a5,sp			;sp����
	next
;��������
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2
	lea.l	$2100.w,a0
	move.w	#$00FF,d1
	for	d1
		suba.l	#$01000000,a2
		if	<tst.b -(a0)>,eq	;$00=�ǂݏo�������̂Ƃ�
			st.b	(a0)			;$FF=�������ݎ��s
			nop
			move.b	d1,(a2)			;��������
			nop
			sf.b	(a0)			;$00=�ǂݏo���������������ݐ���,$FF=�ǂݏo�����s�܂��͏������ݎ��s
		@@:	movea.l	a5,sp			;sp����
		endif
	next
;��r
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2
	lea.l	$2100.w,a0
	move.w	#$00FF,d1
	for	d1
		suba.l	#$01000000,a2
		if	<tst.b -(a0)>,eq	;$00=�ǂݏo���������������ݐ����̂Ƃ�
			nop
			cmp.b	(a2),d1			;��r
			nop
			sne.b	(a0)			;$00=��v,$FF=�ǂݏo�����s�܂��͏������ݎ��s�܂��͕s��v
		@@:	movea.l	a5,sp			;sp����
		endif
	next
;����
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2
	lea.l	$2200.w,a1
	move.w	#$00FF,d1
	for	d1
		suba.l	#$01000000,a2
		nop
		move.b	-(a1),(a2)		;����
		nop
	@@:	movea.l	a5,sp			;sp����
	next
;�m�F�I��
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;�o�X�G���[�x�N�^����
	ei				;sr����
;�\��
	suba.l	a2,a2			;�J�n�ʒu�Ba2=$2000+page�B0=page-1�Ɋg���������͂Ȃ�
	lea.l	$2000+1.w,a3		;�I���ʒu�Ba3=$2000+page
	do
		if	<tst.b (a3)>,eq		;����
			continue	<move.l a2,d0>,ne	;���遨����
		;�Ȃ�������
			movea.l	a3,a2			;�J�n�ʒu
		else				;�Ȃ�
			continue	<move.l a2,d0>,eq	;�Ȃ����Ȃ�
		;���遨�Ȃ�
			bsr	ipl_message_exmemory_sub	;�g���������͈̔͂Ɨe�ʂ�1�\������
			suba.l	a2,a2			;�J�n�ʒu
		endif
	while	<addq.l #1,a3>,<cmpa.w #$20FF,a3>,ls
	if	<move.l a2,d0>,ne	;���遨�Ȃ�
		bsr	ipl_message_exmemory_sub	;�g���������͈̔͂Ɨe�ʂ�1�\������
	endif
;��n��
	lea.l	$2000.w,a0
	moveq.l	#($2200-$2000)/4-1,d0
	for	d0
		clr.l	(a0)+
	next
	rts

;----------------------------------------------------------------
;�g���������͈̔͂Ɨe�ʂ�1�\������
;<a2.l:$2000+page�B�J�n�ʒu
;<a3.l:$2000+page�B�I���ʒu(������܂܂Ȃ�)
;<a6.l:������o�b�t�@
;?d0-d1/a0-a1
ipl_message_exmemory_sub:
	lea.l	100f(pc),a1		;'Extension Memory'
	bsr	print_left_column
	move.l	a2,d0
	swap.w	d0
	lsl.l	#8,d0			;�J�n�A�h���X
	move.l	a3,d1
	swap.w	d1
	lsl.l	#8,d1			;�I���A�h���X(������܂܂Ȃ�)
	goto	ipl_message_memory_sub

100:	.dc.b	'Extension Memory',0
	.even

;----------------------------------------------------------------
;�R�v���Z�b�T�̗L���Ǝ�ނ�\������
;	�}�U�[�{�[�h�R�v���Z�b�T
;		040/060��FC=7��$00022000��CIR������
;	���l���Z�v���Z�b�T�{�[�h1
;		$00E9E000��CIR������
;	���l���Z�v���Z�b�T�{�[�h2
;		$00E9E080��CIR������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
ipl_message_coprocessor:
;�}�U�[�{�[�h�R�v���Z�b�T
	if	<cmp.b #4,d7>,hs	;040/060
		bsr	copro_check_1
		if	<tst.l d0>,pl		;�}�U�[�{�[�h�R�v���Z�b�T������
			lea.l	105f(pc),a1		;'Motherboard Coprocessor'
			bsr	print_left_column
			movea.l	a6,a0			;������o�b�t�@
			lea.l	103f(pc),a1		;'MC68881'
			if	<tst.l d0>,ne
				lea.l	104f(pc),a1		;'MC68882'
			endif
			bsr	strcpy
			bsr	crlf
			movea.l	a6,a1			;������o�b�t�@
			bsr	iocs_21_B_PRINT
		endif
	endif
;���l���Z�v���Z�b�T�{�[�h1
	moveq.l	#0,d0
	bsr	copro_check_2
	if	<tst.l d0>,pl		;���l���Z�v���Z�b�T�{�[�h1������
		lea.l	106f(pc),a1		;'Extension Coprocessor #1'
		bsr	print_left_column
		movea.l	a6,a0			;������o�b�t�@
		lea.l	103f(pc),a1		;'MC68881'
		if	<tst.l d0>,ne
			lea.l	104f(pc),a1		;'MC68882'
		endif
		bsr	strcpy
		bsr	crlf
		movea.l	a6,a1			;������o�b�t�@
		bsr	iocs_21_B_PRINT
	endif
;���l���Z�v���Z�b�T�{�[�h2
	moveq.l	#1,d0
	bsr	copro_check_2
	if	<tst.l d0>,pl		;���l���Z�v���Z�b�T�{�[�h2������
		lea.l	107f(pc),a1		;'Extension Coprocessor #2'
		bsr	print_left_column
		movea.l	a6,a0			;������o�b�t�@
		lea.l	103f(pc),a1		;'MC68881',13,10
		if	<tst.l d0>,ne
			lea.l	104f(pc),a1		;'MC68882',13,10
		endif
		bsr	strcpy
		bsr	crlf
		movea.l	a6,a1			;������o�b�t�@
		bsr	iocs_21_B_PRINT
	endif
	rts

105:	.dc.b	'Motherboard Coprocessor',0
106:	.dc.b	'Extension Coprocessor #1',0
107:	.dc.b	'Extension Coprocessor #2',0
103:	.dc.b	'MC68881',0
104:	.dc.b	'MC68882',0
	.even

;----------------------------------------------------------------
;�}�U�[�{�[�h�R�v���Z�b�T�̗L���Ǝ�ނ𒲂ׂ�
;	1ms�ȓ��ɔ��ʂł��Ȃ���Β��߂�BTimer-C�����삵�Ă��邱��
;>d0.l:-1=�Ȃ�,0=MC68881,1=MC68882
	.cpu	68060
copro_check_1:
	moveq.l	#-1,d0			;-1=�Ȃ�
	if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;000/010/020/030
		rts
	endif
	push	d1-d5/a0-a3
	lea.l	$00022000,a0		;�}�U�[�{�[�h�R�v���Z�b�T��CIR
;<a0.l:FPCP_CIR
	lea.l	MFP_TCDR,a3
;<a3.l:MFP_TCDR
	move.w	sr,d2			;sr�ۑ�
;<d2.w:sr�̌��̒l
	ori.w	#$0700,sr		;���荞�݋֎~
	move.b	(a3),d3
	sub.b	#20,d3			;50us*20=1ms
	if	ls
		add.b	#200,d3
	endif
;<d3.b:1ms���MFP_TCDR�̒l
	movec.l	dfc,d4			;dfc�ۑ�
;<d4.l:dfc�̌��̒l
	movec.l	sfc,d5			;sfc�ۑ�
;<d5.l:sfc�̌��̒l
	moveq.l	#7,d1			;CPU���
	movec.l	d1,dfc
	movec.l	d1,sfc
	movea.l	OFFSET_BUS_ERROR.w,a2	;�o�X�G���[�ۑ�
;<a2.l:�o�X�G���[�̌��̃x�N�^
	lea.l	copro_check_1_abort(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp�ۑ�
;<a1.l:sp�̌��̒l
	clr.w	d1			;null
	moves.w	d1,$06(a0)		;restore
	moves.w	$06(a0),d1		;restore
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_1_abort	;�^�C���A�E�g
		moves.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$5C01,d1		;fmovecr.x #$01,fp0
	moves.w	d1,$0A(a0)		;command
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_1_abort	;�^�C���A�E�g
		moves.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$6800,d1		;fmove.x fp0,<mem>
	moves.w	d1,$0A(a0)		;command
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_1_abort	;�^�C���A�E�g
		moves.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
;	while	<cmp.w #$320C,d1>,ne	;extended to mem
	while	<cmp.w #$8900,d1>,eq	;busy
	moves.l	$10(a0),d0		;operand
	moves.l	$10(a0),d1		;operand
	or.l	d1,d0
	moves.l	$10(a0),d1		;operand
	or.l	d1,d0			;0=MC68881
	if	ne
		moveq.l	#1,d0			;1=MC68882
	endif
copro_check_1_abort:
	movea.l	a1,sp			;sp����
	move.l	a2,OFFSET_BUS_ERROR.w	;�o�X�G���[����
	movec.l	d5,sfc			;sfc����
	movec.l	d4,dfc			;dfc����
	move.w	d2,sr			;sr����
	pop
	rts
	.cpu	68000

;----------------------------------------------------------------
;���l���Z�v���Z�b�T�{�[�h�̗L���Ǝ�ނ𒲂ׂ�
;	1ms�ȓ��ɔ��ʂł��Ȃ���Β��߂�BTimer-C�����삵�Ă��邱��
;<d0.l:0=���l���Z�v���Z�b�T�{�[�h1,1=���l���Z�v���Z�b�T�{�[�h2
;>d0.l:-1=�Ȃ�,0=MC68881,1=MC68882
copro_check_2:
	push	d1-d3/a0-a3
	lea.l	$00E9E000,a0		;���l���Z�v���Z�b�T�{�[�h1��CIR
	if	<tst.l d0>,ne
		lea.l	$00E9E080-$00E9E000(a0),a0	;���l���Z�v���Z�b�T�{�[�h2��CIR
	endif
;<a0.l:FPCP_CIR
	lea.l	MFP_TCDR,a3
;<a3.l:MFP_TCDR
	moveq.l	#-1,d0			;-1=�Ȃ�
;<d0.l:-1=�Ȃ�,0=MC68881,1=MC68882
	move.w	sr,d2			;sr�ۑ�
;<d2.w:sr�̌��̒l
	ori.w	#$0700,sr		;���荞�݋֎~
	move.b	(a3),d3
	sub.b	#20,d3			;50us*20=1ms
	if	ls
		add.b	#200,d3
	endif
;<d3.b:1ms���MFP_TCDR�̒l
	movea.l	OFFSET_BUS_ERROR.w,a2	;�o�X�G���[�ۑ�
;<a2.l:�o�X�G���[�̌��̃x�N�^
	lea.l	copro_check_2_abort(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp�ۑ�
;<a1.l:sp�̌��̒l
	move.w	#$0000,$06(a0)		;restore,null
	tst.w	$06(a0)			;restore
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_2_abort	;�^�C���A�E�g
		move.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$5C01,$0A(a0)		;command,fmovecr.x #$01,fp0
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_2_abort	;�^�C���A�E�g
		move.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$6800,$0A(a0)		;command,fmove.x fp0,<mem>
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_2_abort	;�^�C���A�E�g
		move.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
;	while	<cmp.w #$320C,d1>,ne	;extended to mem
	while	<cmp.w #$8900,d1>,eq	;busy
	move.l	$10(a0),d0		;operand
	move.l	$10(a0),d1		;operand
	or.l	d1,d0
	move.l	$10(a0),d1		;operand
	or.l	d1,d0			;0=MC68881
	if	ne
		moveq.l	#1,d0			;1=MC68882
	endif
copro_check_2_abort:
	movea.l	a1,sp			;sp����
	move.l	a2,OFFSET_BUS_ERROR.w	;�o�X�G���[����
	move.w	d2,sr			;sr�����B���荞�݋���
	pop
	rts

;----------------------------------------------------------------
;DMAC�̓�����g����\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0-d2/a0-a1
ipl_message_dmac_clock:
	lea.l	100f(pc),a1		;'Direct Memory Access Controller (DMAC)'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	101f(pc),a1		;'HD63450 (Main Memory:'
	bsr	strcpy
	lea.l	$6800.w,a2
	bsr	measure_dmac_clock
	bsr	utos
	lea.l	102f(pc),a1		;'%, SRAM:'
	bsr	strcpy
	lea.l	$00ED0000,a2
	bsr	measure_dmac_clock
	bsr	utos
	lea.l	103f(pc),a1		;'%)',13,10
	bsr	strcpy
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Direct Memory Access Controller (DMAC)',0
101:	.dc.b	'HD63450 (Main Memory:',0
102:	.dc.b	'%, SRAM:',0
103:	.dc.b	'%)',13,10,0
	.even

;----------------------------------------------------------------
;DMAC�̓�����g�����v������
;	DMAC��(a2)����(a2)��5000���[�h�]������̂ɂ����鎞�Ԃ�us�P�ʂŌv��
;	10MHz��10�T�C�N��/���[�h��100%�Ƃ���%�l��Ԃ�
;<a2.l:�A�h���X
;>d0.l:DMAC�̓��쑬�x�B10MHz��10�T�C�N��/���[�h��100%�Ƃ���%�l
measure_dmac_clock:
	push	d1-d2/a0-a1
aDMAC	reg	a0
	lea.l	DMAC_2_BASE,aDMAC
aTCDCR	reg	a1
	lea.l	MFP_TCDCR,aTCDCR
;�L���b�V���֎~
	bsr	cache_off
	move.l	d0,d2
;���荞�݋֎~
	di
;SRAM�������݋���
	unlocksram
;DMAC�ۑ�
	move.b	DMAC_DCR(aDMAC),-(sp)
	move.b	DMAC_OCR(aDMAC),-(sp)
	move.b	DMAC_SCR(aDMAC),-(sp)
	move.b	DMAC_MFC(aDMAC),-(sp)
	move.b	DMAC_CPR(aDMAC),-(sp)
	move.b	DMAC_DFC(aDMAC),-(sp)
;DMAC�ݒ�
	st.b	DMAC_CSR(aDMAC)		;CSR�N���A
	move.b	#DMAC_BURST_TRANSFER|DMAC_HD68000_COMPATIBLE|DMAC_16_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_MEMORY_TO_DEVICE|DMAC_16_BIT_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_INCREMENT_DEVICE,DMAC_SCR(aDMAC)
	move.b	#DMAC_HIGHEST_PRIORITY,DMAC_CPR(aDMAC)
	move.b	#DMAC_SUPERVISOR_DATA,DMAC_MFC(aDMAC)
	move.b	#DMAC_SUPERVISOR_DATA,DMAC_DFC(aDMAC)
	move.l	a2,DMAC_MAR(aDMAC)	;�]����
	move.l	a2,DMAC_DAR(aDMAC)	;�]����
	move.w	#5000,DMAC_MTC(aDMAC)	;�]���I�y�����h��
;�^�C�}�ۑ�
	move.b	MFP_IERB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	(aTCDCR),-(sp)
;�^�C�}�ݒ�
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�ݒ�~
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D���荞�݋֎~
	move.b	#0,(aTCDCR)		;Timer-C/D�J�E���g��~
	do
	while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�
	move.b	#0,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^�N���A
	move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
;�J�E���g�J�n
	move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/D�J�E���g�J�n
						;Timer-C��1/200�v���X�P�[��(50us)
						;Timer-D��1/4�v���X�P�[��(1us)
;DMA�]�����s
;	DMA�]������MPU�̃o�X�A�N�Z�X����������邱�Ƃɒ���
	move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA�]���J�n
  .rept 8
	nop				;12.5MHz��7�T�C�N��(560ns)�҂�
  .endm
	do
	while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMA�]���I����҂�
;�J�E���g��~
	move.b	#0,(aTCDCR)		;Timer-C/D�J�E���g��~
	do
	while	<tst.b (aTCDCR)>,ne	;���S�ɒ�~����܂ő҂�
;�^�C�}�擾
	moveq.l	#0,d0
	sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-C�J�E���g��
	moveq.l	#0,d1
	sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-D�J�E���g��(�I�[�o�[�t���[����)
;�^�C�}����
	move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-C�J�E���^����
	move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-D�J�E���^�N���A
	move.b	(sp)+,(aTCDCR)
	move.b	(sp)+,MFP_IMRB-MFP_TCDCR(aTCDCR)
	move.b	(sp)+,MFP_IERB-MFP_TCDCR(aTCDCR)
;DMAC����
	st.b	DMAC_CSR(aDMAC)		;CSR�N���A
	move.b	(sp)+,DMAC_DFC(aDMAC)
	move.b	(sp)+,DMAC_CPR(aDMAC)
	move.b	(sp)+,DMAC_MFC(aDMAC)
	move.b	(sp)+,DMAC_SCR(aDMAC)
	move.b	(sp)+,DMAC_OCR(aDMAC)
	move.b	(sp)+,DMAC_DCR(aDMAC)
;SRAM�������݋֎~
	locksram
;���荞�݋���
	ei
;�J�E���^����
	mulu.w	#50,d0
	if	<cmp.b d1,d0>,hi
		add.w	#256,d0
	endif
	move.b	d1,d0
	subq.w	#1,d0
;<d0.l:SRAM����SRAM��5000���[�hDMA�]������̂ɂ�����������(us)�B0�`12799
;10�T�C�N��/���[�h��10MHz��100%�Ƃ���%�l�����߂�
;	10(�T�C�N��/���[�h)/(d0/5000)(us/���[�h)/10(MHz)*100 = 10*5000/d0*10
	move.l	#10*5000*10,d1		;d1=�폜��
	divu.w	d0,d1			;d1=�]��<<16|��
	swap.w	d1			;d1=��<<16|�]��
	lsr.w	#1,d0			;d0=����/2
	sub.w	d1,d0			;d0=����/2-�]��Bx=����/2<�]��?1:0
	swap.w	d1			;d1=�]��<<16|��
	moveq.l	#0,d0
	addx.w	d1,d0
;<d0.l:10MHz��10�T�C�N��/���[�h��100%�Ƃ���%�l
;�L���b�V������
	move.l	d0,d1
	bsr	cache_set
	move.l	d1,d0
	pop
	rts


;----------------------------------------------------------------
;RTC�̓�����\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0-d2/a0-a1
ipl_message_rtc_dttm:
	lea.l	100f(pc),a1		;'Real Time Clock (RTC)'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	101f(pc),a1		;'RP5C15 ('
	bsr	strcpy
;RTC���������ǂݏo��
	bsr	readrtc
	if	pl
		bsr	checkdttm
	endif
;<d0.l:0=����,-1=�ُ�
;<d1.l:�j��<<28|����N<<16|��<<8|���ʓ�
;<d2.l:��<<16|��<<8|�b
;�ُ�̂Ƃ����������J�n
	if	<tst.l d0>,mi
		lea.l	102f(pc),a1		;27,'[9m'
		bsr	strcpy
	endif
;�����𕶎���ɕϊ�����
	bsr	dttmtos
;�ُ�̂Ƃ����������I��
	if	<tst.l d0>,mi
		lea.l	103f(pc),a1		;27,'[29m'
		bsr	strcpy
	endif
	lea.l	104f(pc),a1		;')',13,10
	bsr	strcpy
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Real Time Clock (RTC)',0
101:	.dc.b	'RP5C15 (',0
102:	.dc.b	27,'[9m',0
103:	.dc.b	27,'[29m',0
104:	.dc.b	')',13,10,0
	.even

;--------------------------------------------------------------------------------
;�����𕶎���ɕϊ�����
;<d1.l:�j��<<28|����N<<16|��<<8|���ʓ�
;<d2.l:��<<16|��<<8|�b
;<a0.l:�o�b�t�@
;>a0.l:0�̈ʒu
dttmtos:
	push	d0-d2
	swap.w	d1			;d1.l:��<<24|���ʓ�<<16|�j��<<12|����N
	move.l	#$00000FFF,d0
	and.w	d1,d0			;d0.l:����N
	bsr	utos
	move.b	#'-',(a0)+
	rol.l	#8,d1			;d1.l:���ʓ�<<24|�j��<<20|����N<<8|��
	moveq.l	#0,d0
	move.b	d1,d0			;d0.l:��
	bsr	50f
	move.b	#'-',(a0)+
	rol.l	#8,d1			;d1.l:�j��<<28|����N<<16|��<<8|���ʓ�
	moveq.l	#0,d0
	move.b	d1,d0			;d0.l:���ʓ�
	bsr	50f
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	rol.l	#4,d1			;d1.l:����N<<20|��<<12|���ʓ�<<4|�j��
	moveq.l	#$0F,d0
	and.b	d1,d0			;d0.l:�j��
	if	<cmp.b #7,d0>,hi
		moveq.l	#7,d0
	endif
	lsl.b	#2,d0			;4*�j��
	lea.l	100f(pc,d0.w),a1
	bsr	strcpy
	move.b	#')',(a0)+
	move.b	#' ',(a0)+
	swap.w	d2			;d2.l:��<<24|�b<<16|��
	moveq.l	#0,d0
	move.b	d2,d0			;d0.l:��
	bsr	50f
	move.b	#':',(a0)+
	rol.l	#8,d2			;d2.l:�b<<24|��<<8|��
	moveq.l	#0,d0
	move.b	d2,d0			;d0.l:��
	bsr	50f
	move.b	#':',(a0)+
	rol.l	#8,d2			;d2.l:|��<<16|��<<8|�b
	moveq.l	#0,d0
	move.b	d2,d0			;d0.l:�b
	bsr	50f
	pop
	rts

50:	if	<cmp.b #10,d0>,lo
		move.b	#'0',(a0)+
	endif
	goto	utos

100:	.dc.b	'Sun',0
	.dc.b	'Mon',0
	.dc.b	'Tue',0
	.dc.b	'Wed',0
	.dc.b	'Thu',0
	.dc.b	'Fri',0
	.dc.b	'Sat',0
	.dc.b	'???',0
	.even

;--------------------------------------------------------------------------------
;RTC���������ǂݏo��
;	�X�[�p�[�o�C�U���[�h�ŌĂяo������
;>d0.l:0=����,-1=�ُ�
;>d1.l:�j��<<28|����N<<16|��<<8|���ʓ�
;>d2.l:��<<16|��<<8|�b
;	�j��	����̂Ƃ�0�`6�B0=���j��,�c,6=�y�j��
;	����N	����̂Ƃ�1980�`2079
;	��	����̂Ƃ�1�`12
;	���ʓ�	����̂Ƃ�1�`���̓���
;	��	����̂Ƃ�0�`23
;	��	����̂Ƃ�0�`59
;	�b	����̂Ƃ�0�`59
;	�ُ�̂Ƃ��͈͊O�̒l���Ԃ邱�Ƃ�����
;>ccr:pl=����,mi=�ُ�
;	�ُ�̓��e
;	�EBCD���ُ�
readrtc:
	push	d3-d4/d7/a0-a2
	moveq.l	#0,d7			;����
aRTC	reg	a1
rtc	reg	-RTC_MODE(aRTC)
	lea.l	RTC_MODE,aRTC
aPPIA	reg	a2
	lea.l	PPI_PORT_A,aPPIA
;------------------------------------------------
;RTC�̃��W�X�^��ǂݏo��
;	�����̃��W�X�^��ǂݏo���Ă���ԂɎ��v���i�݃��W�X�^�̓��e���ω�����ꍇ������
;	��ʂ���ǂ�ōŉ��ʂ�0�̂Ƃ�(�J��オ��ɂ����鎞�ԑ҂��Ă���)�ǂݒ���
	moveq.l	#2-1,d4
	for	d4
		moveq.l	#RTC_MODE_BANK_MASK,d0
		or.b	(RTC_MODE)rtc,d0
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		move.b	d0,(RTC_MODE)rtc	;�o���N1
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		moveq.l	#$01,d2
		and.b	(RTC_1_TWENTY_FOUR)rtc,d2	;0=12���Ԍv,1=24���Ԍv
		subq.b	#1,d0
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		move.b	d0,(RTC_MODE)rtc	;�o���N0
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		moveq.l	#$07,d1
		and.b	(RTC_0_DAY_OF_WEEK)rtc,d1	;�j���J�E���^
		lea.l	(RTC_0_TEN_YEARS+1)rtc,a0	;10�N�J�E���^�̒���
		moveq.l	#6-1,d3
		for	d3
			moveq.l	#$0F,d0
			and.w	-(a0),d0		;10�N�J�E���^��1���J�E���^
			lsl.l	#4,d1
			or.b	d0,d1
		next
		subq.l	#2,a0			;�j���J�E���^���ׂ��B10���J�E���^�̒���
		moveq.l	#6-1,d3
		for	d3
			moveq.l	#$0F,d0
			and.w	-(a0),d0		;10���J�E���^��1�b�J�E���^
			lsl.l	#4,d2
			or.b	d0,d2
		next
		moveq.l	#$0F,d0
		and.b	d2,d0			;�ŉ���
	next	eq			;0�łȂ���ΏI��
;<d1.l:�j��<<24|(����N-1980)(BCD)<<16|��(BCD)<<8|���ʓ�(BCD)
;<d2.l:��(BCD)<<16|��(BCD)<<8|�b(BCD)
;------------------------------------------------
;���t���f�R�[�h����
	move.l	d1,d0
	bsr	decode3bcd		;2��*3�g��BCD���f�R�[�h����
;<d0.l:�j��<<24|(����N-1980)<<16|��<<8|���ʓ�
	if	mi			;�ُ�
		moveq.l	#-1,d7			;�ُ�
	endif
;�j�������炵�Đ���N��1980��������
	swap.w	d0			;mmdd0wyy
	ror.w	#8,d0			;mmddyy0w
	lsl.b	#4,d0			;mmddyyw0
	rol.w	#8,d0			;mmddw0yy
	add.w	#1980,d0		;mmddwyyy
	swap.w	d0			;wyyymmdd
	move.l	d0,d1
;<d1.l:�j��<<28|����N<<16|��<<8|���ʓ�
;------------------------------------------------
;�������f�R�[�h����
	move.l	d2,d0
	bsr	decode3bcd		;2��*3�g��BCD���f�R�[�h����
;<d0.l:��<<16|��<<8|�b
	if	mi			;�ُ�
		moveq.l	#-1,d7			;�ُ�
	endif
	move.l	d0,d2
;<d2.l:��<<16|��<<8|�b
;------------------------------------------------
;�I��
	move.l	d7,d0
	pop
	rts

;--------------------------------------------------------------------------------
;RTC����ǂݏo���������Ɉُ킪�Ȃ����m�F����
;<d1.l:�j��<<28|����N<<16|��<<8|���ʓ�
;<d2.l:��<<16|��<<8|�b
;>d0.l:0=����,-1=�ُ�
;>ccr:pl=����,mi=�ُ�
;	�ُ�̓��e
;	�E2023��2��29����31���Ȃǂ̑��݂��Ȃ�����
;	�E_ROMVER�̓��t���O�̖��炩�ɉߋ��̓��t
;	�E�j�����Ⴄ
checkdttm:
	push	d3-d5/a0
;------------------------------------------------
;���t�𕪉�����
	move.l	d1,d5			;d5.l:�j��<<28|����N<<16|��<<8|���ʓ�
	moveq.l	#0,d3
	move.b	d5,d3			;d3.l:���ʓ��B����̂Ƃ�1�`���̓���
	lsr.w	#8,d5			;d5.l:�j��<<28|����N<<16|��
	moveq.l	#0,d4
	move.b	d5,d4			;d4.l:���B����̂Ƃ�1�`12
	swap.w	d5			;d5.l:��<<16|�j��<<12|����N
	and.l	#$00000FFF,d5		;d5.l:����N�B����̂Ƃ�1980�`2079
;<d3.l:���ʓ��B����̂Ƃ�1�`���̓���
;<d4.l:���B����̂Ƃ�1�`12
;<d5.l:����N�B����̂Ƃ�1980�`2079
;------------------------------------------------
;����N�͈̔͂��m�F����
	gotoor	<cmp.w #1980,d5>,lo,<cmp.w #2079,d5>,hi,90f	;����N��1980��菬�����܂���2079���傫��
;------------------------------------------------
;���͈̔͂��m�F����
	gotoor	<tst.w d4>,eq,<cmp.w #12,d4>,hi,90f	;����0�܂���12���傫��
;------------------------------------------------
;���ʓ��͈̔͂��m�F����
	moveq.l	#0,d0
	if	<cmp.b #2,d4>,eq	;2��
		moveq.l	#3,d0
		and.b	d5,d0			;����N&3
		seq.b	d0			;0=�[�N�ł͂Ȃ��N��2��,-1=�[�N��2��
		neg.b	d0			;0=�[�N�ł͂Ȃ��N��2��,1=�[�N��2��
	endif
	lea.l	daysofmonth(pc),a0
	add.b	-1(a0,d4.w),d0		;d0.l:���̓���
	gotoor	<tst.w d3>,eq,<cmp.w d0,d3>,hi,90f	;���ʓ���0�܂��͌��̓������傫��
;------------------------------------------------
;_ROMVER�̓��t�Ɣ�r����
	IOCS	_ROMVER
	bsr	decode3bcd		;2��*3�g��BCD���f�R�[�h����
;<d0.l:_ROMVER�̃o�[�W����<<24|_ROMVER�̐���N�̉�2��<<16|_ROMVER�̌�<<8|_ROMVER�̌��ʓ�
;_ROMVER�̐���N�Ɣ�r����
	swap.w	d0			;d0.w:_ROMVER�̃o�[�W����<<24|_ROMVER�̐���N�̉�2��
	and.w	#$00FF,d0		;d0.w:_ROMVER�̐���N�̉�2��
	add.w	#1900,d0
	if	<cmp.w #1950,d0>,lo
		add.w	#2000-1900,d0	;d0.w:_ROMVER�̐���N
	endif
	goto	<cmp.w d0,d5>,lo,90f	;_ROMVER�̐���N���O
	if	eq			;_ROMVER�̐���N�Ɠ���
	;_ROMVER�̌��Ɣ�r����
		swap.w	d0			;d0.w:_ROMVER�̌�<<8|_ROMVER�̌��ʓ�
		ror.w	#8,d0			;d0.w:_ROMVER�̌��ʓ�<<8|_ROMVER�̌�
		goto	<cmp.b d0,d4>,lo,90f	;_ROMVER�̌����O
		if	eq			;_ROMVER�̌��Ɠ���
		;_ROMVER�̌��ʓ��Ɣ�r����
			rol.w	#8,d0			;d0.w:_ROMVER�̌�<<8|_ROMVER�̌��ʓ�
			goto	<cmp.b d0,d3>,lo,90f	;_ROMVER�̌��ʓ����O
		endif
	endif
;------------------------------------------------
;�j�����m�F����
	if	<cmp.w #2,d4>,ls	;1����2����
		subq.w	#1,d5			;�O�N��
		add.w	#12,d4			;13����14���ɂ���
	endif
	move.l	d5,d0			;d0.l:����N
	mulu.w	#365,d0			;d0.l:365*����N
	lsr.w	#2,d5			;d5.l:floor(����N/4)
	add.l	d5,d0			;d0.l:365*����N+floor(����N/4)
	addq.w	#1,d4			;d4.l:��+1
	mulu.w	#306,d4			;d4.l:306*(��+1)
  .if 1
	divu.w	#10,d4			;d4.w:floor(306*(��+1))/10�B�폜����306*4=1224�`306*15=4590
	ext.l	d4			;d4.l:floor(306*(��+1))/10
  .else
	mulu.w	#3277,d4
	add.l	d4,d4
	clr.w	d4
	swap.w	d4			;d4.l:floor(306*(��+1))/10
  .endif
	add.l	d4,d0			;d0.l:365*����N+floor(����N/4)+floor(306*(��+1))/10
	add.l	d3,d0			;d0.l:365*����N+floor(����N/4)+floor(306*(��+1))/10+���ʓ�
	sub.l	#723256,d0		;d0.l:365*����N+floor(����N/4)+floor(306*(��+1))/10+���ʓ�-723256�B1980�N1��1����2�A2079�N12��31����36526
	divu.w	#7,d0
	swap.w	d0			;d0.w:���t�̗j���B0�`6
	move.l	d1,d3			;d3.l:�j��<<28|����N<<16|��<<8|���ʓ�
	rol.l	#4,d3			;d3.l:����N<<20|��<<12|���ʓ�<<4|�j��
	and.w	#$000F,d3		;d3.w:RTC���Ԃ����j��
	goto	<cmp.w d0,d3>,ne,90f	;�j�����Ⴄ
;------------------------------------------------
;�����͈̔͂��m�F����
	move.l	d2,d0
	goto	<cmp.b #59,d0>,hi,90f	;�b���͈͊O
	lsr.w	#8,d0
	goto	<cmp.b #59,d0>,hi,90f	;�����͈͊O
	swap.w	d0
	goto	<cmp.b #23,d0>,hi,90f	;�����͈͊O
;------------------------------------------------
;����I��
	moveq.l	#0,d0
80:	pop
	rts

;------------------------------------------------
;�ُ�I��
90:	moveq.l	#-1,d0
	goto	80b

;------------------------------------------------
;�[�N�łȂ��N�̌��̓���
daysofmonth:
	.dc.b	31,28,31,30,31,30,31,31,30,31,30,31
	.even

;--------------------------------------------------------------------------------
;2��*3�g��BCD���f�R�[�h����
;<d0.l:$WWXXYYZZ
;>d0.l:$WW<<24|x<<16|y<<8|z
;	���8�r�b�g�͕ω����Ȃ�
;	x,y,z�̍ő�l�͐���̂Ƃ�9*10+9=99�A�ُ�̂Ƃ�15*10+15=165
;>ccr:pl=����,mi=�ُ�
decode3bcd:
	push	d1-d4/d7
	moveq.l	#0,d7			;d7.l:0=����,-1=�ُ�
	moveq.l	#10,d4			;d4.l:10
	moveq.l	#3-1,d3			;d3.w:2,1,0
	for	d3
		moveq.l	#$0F,d1
		and.b	d0,d1			;d1.b:����4bit
		lsr.b	#4,d0			;d0.b:���4bit
		ifor	<cmp.b d4,d1>,hs,<cmp.b d4,d0>,hs	;����4bit��10�ȏ�܂��͏��4bit��10�ȏ�
			moveq.l	#-1,d7			;�ُ�
		endif
		move.b	d0,d2			;d2.b:���4bit
		lsl.b	#2,d0			;d0.b:���4bit*4
		add.b	d2,d0			;d0.b:���4bit*5
		add.b	d0,d0			;d0.b:���4bit*10
		add.b	d1,d0			;d0.b:���4bit*10+����4bit
		ror.l	#8,d0			;$ZZ,$YY,$XX�̏�
	next
	ror.l	#8,d0			;$WW�͂��̂܂�
	tst.l	d7
	pop
	rts


;----------------------------------------------------------------
;�����n�[�h�f�B�X�N�C���^�[�t�F�C�X�̎�ނ�\������
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0/a0-a1
ipl_message_hd_type:
	lea.l	100f(pc),a1		;'Built-in Hard Disk Interface'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	lea.l	101f(pc),a1		;'SASI'
	if	<isSASI>,ne
		lea.l	102f(pc),a1		;'SCSI'
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Built-in Hard Disk Interface',0
101:	.dc.b	'SASI',0
102:	.dc.b	'SCSI',0
	.even

;----------------------------------------------------------------
;�N���f�o�C�X��\������
;	SRAM_ROM_BOOT_HANDLE	ROM�N���n���h��
;	SRAM_SRAM_BOOT_ADDRESS	SRAM�N���A�h���X
;	SRAM_BOOT_DEVICE	�N���f�o�C�X�B$0000=STD,$8xxx=HD,$9xxx=FD,$Axxx=ROM,$Bxxx=SRAM
;		$0000	STD
;		$8xxx	HD n
;		$9xxx	FD n
;		$A000	ROM $xxxxxxxx
;			$00E9F020	XEiJ HFS
;			$00EA0020-	Expansion SCSI n
;			$00EA9000-	PhantomX VDISK n
;			$00FC0000-	Built-in SCSI n
;		$B000	SRAM $xxxxxxxx
;<d7.l:MPU�X�e�[�^�X
;<a6.l:������o�b�t�@
;?d0-d1/a0-a1
ipl_message_boot_device:
	lea.l	100f(pc),a1		;'Boot Device'
	bsr	print_left_column
	movea.l	a6,a0			;������o�b�t�@
	move.w	SRAM_BOOT_DEVICE,d0	;�N���f�o�C�X
	if	eq			;$0000
		lea.l	101f(pc),a1		;'STD'
		bsr	strcpy
	elifor	<cmp.w #$8000,d0>,lo,<cmp.w #$C000,d0>,hs
		lea.l	102f(pc),a1		;'Unknown $'
		bsr	h4tos
	elif	<cmp.w #$9000,d0>,lo	;$8xxx
		lea.l	103f(pc),a1		;'SASI HD '
		bsr	strcpy
		lsr.w	#8,d0
		moveq.l	#$0F,d1
		and.l	d1,d0
		bsr	utos
	elif	<cmp.w #$A000,d0>,lo	;$9xxx
		lea.l	104f(pc),a1		;'FD '
		bsr	strcpy
		lsr.w	#8,d0
		moveq.l	#$07,d1
		and.l	d1,d0
		bsr	utos
	elif	<cmp.w #$B000,d0>,lo	;$Axxx
		move.l	SRAM_ROM_BOOT_HANDLE,d0	;ROM�N���n���h��
		moveq.l	#3,d1
		and.w	d0,d1
		if	<cmp.l #$00E9F020,d0>,eq
			lea.l	105f(pc),a1		;'XEiJ HFS'
			bsr	strcpy
		elifand	<cmp.l #$00EA0020,d0>,hs,<cmp.l #$00EA0020+4*8,d0>,lo,<tst.l d1>,eq
			lea.l	106f(pc),a1		;'Expansion SCSI '
			bsr	strcpy
			lsr.w	#2,d0
			moveq.l	#7,d1
			and.l	d1,d0
			bsr	utos
		elifand	<cmp.l #$00EA9000,d0>,hs,<cmp.l #$00EA9000+4*8,d0>,lo,<tst.l d1>,eq
			lea.l	107f(pc),a1		;'PhantomX VDISK '
			bsr	strcpy
			lsr.w	#2,d0
			moveq.l	#7,d1
			and.l	d1,d0
			bsr	utos
		elifand	<cmp.l #$00FC0000,d0>,hs,<cmp.l #$00FC0000+4*8,d0>,lo,<tst.l d1>,eq
			lea.l	108f(pc),a1		;'Built-in SCSI '
			bsr	strcpy
			lsr.w	#2,d0
			moveq.l	#7,d1
			and.l	d1,d0
			bsr	utos
		else
			lea.l	109f(pc),a1		;'ROM $'
			bsr	strcpy
			bsr	h8tos
		endif
	else				;$Bxxx
		lea.l	110f(pc),a1		;'SRAM $'
		bsr	strcpy
		move.l	SRAM_SRAM_BOOT_ADDRESS,d0	;SRAM�N���A�h���X
		bsr	h8tos
	endif
	bsr	crlf
	movea.l	a6,a1			;������o�b�t�@
	goto	iocs_21_B_PRINT

100:	.dc.b	'Boot Device',0
101:	.dc.b	'STD',0
102:	.dc.b	'Unknown $',0
103:	.dc.b	'SASI HD ',0
104:	.dc.b	'FD ',0
105:	.dc.b	'XEiJ HFS',0
106:	.dc.b	'Expansion SCSI ',0
107:	.dc.b	'PhantomX VDISK ',0
108:	.dc.b	'Built-in SCSI ',0
109:	.dc.b	'ROM $',0
110:	.dc.b	'SRAM $',0
	.even



;----------------------------------------------------------------
;	SHARP���S
;	�ύX�O
;		00FF0EC0 43FA04CA		lea.l	$00FF138C(pc),a1	;SHARP���S
;		00FF0EC4 343C0000		move.w	#$0000,d2
;		00FF0EC8
;----------------------------------------------------------------
	PATCH_DATA	sharp_logo,$00FF0EC0,$00FF0EC7,$43FA04CA
	lea.l	$00FFD680,a1
	clr.w	d2



;----------------------------------------------------------------
;	�s�
;		�N���b�N�\�����[�`����A6���W�X�^�̍ŏ�ʃo�C�g���j�󂳂��
;		https://stdkmd.net/bugsx68k/#rom_clocka6
;	�ύX�O
;		00000F0C 4E56FFFC         	link.w	a6,#-4
;		00000F10 1D7C00000000     	move.b	#$00,$0000.w(a6)
;----------------------------------------------------------------



;----------------------------------------------------------------
;	�s�
;		���C����������9MB�̂Ƃ��N������19MB�ƕ\�������
;	�ύX�O
;		00000FD4 6A0A_00000FE0    	bpl	~FF0FE0			;9MB�ȏ�
;----------------------------------------------------------------



;----------------------------------------------------------------
;	�N����
;		�N������炷��FM�����h���C�o���듮�삷�邱�Ƃ�����s����C������
;		https://stdkmd.net/bugsx68k/#rom_chime
;		�N�����̃L�[�R�[�h��ύX�ł���悤�ɂ���
;----------------------------------------------------------------
	PATCH_DATA	play_stupsnd,$00FF10D8,$00FF118F,$4A3900ED

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
;	�s�
;		�N�����b�Z�[�W��Memory Managiment Unit�̃X�y�����Ԉ���Ă���
;		https://stdkmd.net/bugsx68k/#rom_mmu
;	�΍�
;		Memory Management Unit
;	�ύX�O
;		00001254 4D656D6F7279204D 	.dc.b	'Memory Managiment Unit(MMU) : On-Chip MMU',$0D,$0A,$00
;		         616E6167696D656E 
;		         7420556E6974284D 
;		         4D5529203A204F6E 
;		         2D43686970204D4D 
;		         550D0A00         
;----------------------------------------------------------------



;----------------------------------------------------------------
;	TRAP#14(�G���[�\��)
;		�u�G���[���������܂����B���Z�b�g���Ă��������B�v�����ł͕�����Ȃ��G���[�̓��e��\������
;	�ύX�O
;		00FF1458 41FAF364		lea.l	$00FF07BE(pc),a0	;TRAP#14(�G���[�\��)
;		00FF145C 21C800B8		move.l	a0,OFFSET_TRAP_14.w
;----------------------------------------------------------------
	PATCH_DATA	trap14,$00FF1458,$00FF145F,$41FAF364
	move.l	#trap14,OFFSET_TRAP_14.w
	PATCH_TEXT
;<d7.w:�G���[�ԍ�
;	$00xx	����`��O
;	$01xx	����`IOCS�R�[��
;	$301F	NMI
;	$7009	�v�����^�I�t���C��
;<a6.l:SR�̈ʒu�B$7009�̂Ƃ��Z�b�g����Ȃ�
trap14:
;������o�b�t�@���m�ۂ���
	lea.l	-128(sp),sp		;������o�b�t�@
;�G���[���b�Z�[�W�����
;	Bus error on writing to $XXXXXXXX at $XXXXXXXX
;	Bus error on reading from $XXXXXXXX at $XXXXXXXX
;	Address error on writing to $XXXXXXXX at $XXXXXXXX
;	Address error on reading from $XXXXXXXX at $XXXXXXXX
;	Error $XXXX at $XXXXXXXX
	movea.l	sp,a0			;������o�b�t�@
	bsr	start_proportional
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	moveq.l	#-2,d0
	and.w	d7,d0
	subq.w	#2,d0
	if	eq			;�o�X�G���[�ƃA�h���X�G���[
		move.b	BIOS_MPU_TYPE.w,d0
		if	eq			;68000
		;	MC68000UM 6-17
		;	0.w
		;	  15-5 4   3   2-0
		;	  X    R/W I/N FC
		;	  R/W  0=Write,1=Read
		;	  I/N  0=Instruction,1=Not
		;	2.l  ACCESS ADDRESS
		;	6.w  INSTRUCTION REGISTER
		;	8.w  STATUS REGISTER
		;	10.l  PROGRAM COUNTER
			moveq.l	#$10,d0
			and.b	1-8(a6),d0		;0=Write,���̑�=Read
			movea.l	2-8(a6),a2		;Address
		elif	<subq.b #1,d0>,eq	;68010
		;	MC68000UM 6-18
		;	0.w  STATUS REGISTER
		;	2.l  PROGRAM COUNTER
		;	6.w  FORMAT $A VECTOR OFFSET
		;	8.w  SPECIAL STATUS WORD
		;	  15 14 13 12 11 10 9  8  7-3 2-0
		;	  RR X  IF DF RM HB BY RW X   FC
		;	  RW  0=Write,1=Read
		;	10.l  FAULT ADDRESS
		;	14.w  UNUSED, RESERVED
		;	16.w  DATA OUTPUT BUFFER
		;	18.w  UNUSED, RESERVED
		;	20.w  DATA INPUT BUFFER
		;	22.w  UNUSED, RESERVED
		;	24.w  INSTRUCTION INPUT BUFFER
		;	26.w  VERSION NUMBER INTERNAL INFORMATION, 16 WORDS
		;	58�o�C�g�B���ۂɏ������܂��̂�52�o�C�g
			moveq.l	#$01,d0
			and.b	8(a6),d0		;0=Write,���̑�=Read
			movea.l	10(a6),a2		;Address
		elif	<subq.b #4-1,d0>,lo	;68020/68030
		;68020/68030
		;	MC68020UM 6-23/MC68030UM 8-28
		;	10.w  SPECIAL STATUS WORD
		;	  15 14 13 12 11-9 8  7  6  5-4  3 2-0
		;	  FC FB RC RB X    DF RM RW SIZE X FC
		;	  RW  0=Write,1=Read
		;	16.l  DATA CYCLE FAULT ADDRESS
			moveq.l	#$40,d0
			and.b	11(a6),d0		;0=Write,���̑�=Read
			movea.l	16(a6),a2		;Address
		elif	eq			;68040
		;	MC68040UM 8-24
		;	12.w  SPECIAL STATUS WORD
		;	  15 14 13 12 11 10  9  8  7 6-5  4-3 2-0
		;	  CP CU CT CM MA ATC LK RW X SIZE TT  TM
		;	  RW  0=Write,1=Read
		;	20.l  FAULT ADDRESS
			moveq.l	#$01,d0
			and.b	12(a6),d0		;0=Write,���̑�=Read
			movea.l	20(a6),a2		;Address
		elif	<cmp.w #2,d7>,eq	;68060�̃o�X�G���[
		;	MC68060UM 8-21
		;	8.l  FAULT ADDRESS
		;	12.l  FAULT STATUS LONG WORD
		;	  31-28 27 26 25 24-23 22-21 20-19 18-16 15 14  13  12  11  10 9  8  7  6   5  4  3   2   1 0
		;	  X     MA X  LK RW    SIZE  TT    TM    IO PBE SBE PTA PTB IL PF SP WP TWE RE WE TTR BPE X SEE
		;	  RW  00=Undefined,Reserved,01=Write,10=Read,11=Read-Modify-Write
		;	  SIZE  00=Byte,01=Word,10=Long,11=Double Precision or MOVE16
			moveq.l	#$01,d0
			and.b	12(a6),d0		;0=Write,���̑�=Read
			if	ne			;Read or Read-Modify-Write
				ifand	<tst.b 13(a6)>,mi,<btst.b #4,15(a6)>,ne	;Read-Modify-Write and Bus Error on Write
					moveq.l	#0,d0		;0=Write,���̑�=Read
				endif
			endif
			movea.l	8(a6),a2		;Address
		else				;68060�̃A�h���X�G���[
		;	MC68060UM 8-7
		;	8.l  FAULT ADDRESS
			moveq.l	#1,d0			;Read
			movea.l	8(a6),a2		;Address
			addq.l	#1,a2			;bit0��0�ɂȂ��Ă���̂�1�ɖ߂�
		endif
		lea.l	101f(pc),a1		;'Bus'
		subq.w	#2,d7
		if	ne
			lea.l	102f-101f(a1),a1	;'Address'
		endif
		bsr	strcpy
		lea.l	103f(pc),a1		;' error on '
		bsr	strcpy
		lea.l	104f(pc),a1		;'writing to $'
		if	<tst.b d0>,ne
			lea.l	105f-104f(a1),a1	;'reading from $'
		endif
		bsr	strcpy
		move.l	a2,d0
		bsr	h8tos			;XXXXXXXX
	elif	<cmp.w #12,d7>,lo		;4�`11
		PATCH_lea	sysstat,trap14_message,a1
		move.w	d7,d0
		add.w	d0,d0
		adda.w	-2*4(a1,d0.w),a1
		bsr	strcpy
	elif	<cmp.w #$301F,d7>,eq		;NMI
		lea.l	106f(pc),a1		;'NMI'
		bsr	strcpy
	else				;���̑�����`��O�Ɩ���`IOCS�R�[��
		lea.l	107f(pc),a1		;'Error $'
		bsr	strcpy
		move.w	d7,d0
		bsr	h4tos			;XXXX
	endif
	if	<cmp.w #$7009,d7>,ne
		lea.l	108f(pc),a1		;' at $'
		bsr	strcpy
		move.l	2(a6),d0		;PC
		bsr	h8tos
	endif
	bsr	end_proportional
	bsr	crlf
;�G���[���b�Z�[�W��\������
	movea.l	sp,a1
	bsr	iocs_21_B_PRINT
;������o�b�t�@���J������
	lea.l	128(sp),sp
;��ɒ��~
;	�L�[���͂�҂��������Ƀ��Z�b�g�҂��ɂ���
10:	IOCS	_ABORTJOB
	goto	10b			;�������[�v

101:	.dc.b	'Bus',0
102:	.dc.b	'Address',0
103:	.dc.b	' error on ',0
104:	.dc.b	'writing to $',0
105:	.dc.b	'reading from $',0
106:	.dc.b	'NMI',0
107:	.dc.b	'Error $',0
108:	.dc.b	' at $',0
	.even



;----------------------------------------------------------------
;	IOI HDCINT�x�N�^�̐ݒ�
;		���̂܂܁BIPLROM 1.2��IPLROM 1.3�œ����BSPCINT�Ƃ͊֌W�Ȃ�
;	�ύX�O
;		000017FC 047E             	.dc.w	~FF1C76-~FF17F8		;[$0188.w].l:[$0062]:HDCINT �n�[�h�f�B�X�N�̃X�e�[�^�X���荞��
;		00001C76 4E73             	rte
;----------------------------------------------------------------



;----------------------------------------------------------------
;	DMAC 1�̏�����
;		���̂܂܁BIPLROM 1.2��IPLROM 1.3�œ���
;	�ύX�O
;		0000180A 4480             	.dc.b	$00E84044-$00E84000,$80	;[$00E84044].b:DMA 1 DCR(XRM##|DTYP##|DPS|-|PCL##)
;		0000180C 4604             	.dc.b	$00E84046-$00E84000,$04	;[$00E84046].b:DMA 1 SCR(----|MAC##|DAC##)
;		0000180E 6905             	.dc.b	$00E84069-$00E84000,$05	;[$00E84069].b:DMA 1 MFC
;		00001810 6D02             	.dc.b	$00E8406D-$00E84000,$02	;[$00E8406D].b:DMA 1 CPR
;		00001812 7105             	.dc.b	$00E84071-$00E84000,$05	;[$00E84071].b:DMA 1 DFC
;----------------------------------------------------------------



;----------------------------------------------------------------
;	DMAC 1 DAR�̏�����
;		SASI�����@�̂Ƃ�HDC_DATA��ݒ肷��
;		SCSI�����@�̂Ƃ��폜�BIPLROM 1.3�͖��Ӗ��Ȓl��ݒ肵�Ă���
;	�ύX�O
;		00001788 237A7BB2_0000933C	move.l	spc_base_handle(pc),DMAC_DAR+DMAC_1_BASE-DMAC_0_BASE(a1)
;		         0054             
;----------------------------------------------------------------
	PATCH_DATA	p1788,$00FF1788,$00FF1788+5,$237A7BB2
	jsr	p1788
	PATCH_TEXT
p1788:
	if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI�����@
		move.l	#HDC_DATA,DMAC_DAR+DMAC_1_BASE-DMAC_0_BASE(a1)
	else				;SCSI�����@
		clr.l	DMAC_DAR+DMAC_1_BASE-DMAC_0_BASE(a1)
	endif
	rts



;----------------------------------------------------------------
;	SASI�|�[�g�܂���SCSI�|�[�g�̏�����
;		SASI�����@�̂Ƃ�SASI�|�[�g������������
;		SCSI�����@�Ŋg��SCSI���Ȃ��Ƃ�SCSIINROM��scsi_init_routine���Ăяo��
;	�ύX�O
;		000017D6 70F5             	moveq.l	#_SCSIDRV,d0
;		000017D8 7200             	moveq.l	#_S_RESET,d1
;		000017DA 4E4F             	trap	#15
;----------------------------------------------------------------
	PATCH_DATA	p17D6,$00FF17D6,$00FF17D6+5,$70F57200
	jsr	p17d6
	PATCH_TEXT
p17d6:
	push	d0-d1/a0-a1
	if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI�����@
	;SASI�|�[�g������������
		do
			break	<tst.l BIOS_ALARM_MINUTE.l>,ne
		while	<cmpi.w #6000-100*1,BIOS_TC_MINUTE_COUNTER.l>,cc	;�N����1�b�܂ő҂�
		move.w	#$8000,d1
		do
			suba.l	a1,a1
			IOCS	_B_DSKINI
			if	<cmpi.w #100*30,BIOS_TC_MINUTE_COUNTER.l>,cc	;�N����30�b�܂ł�
				redo	<cmp.b #$04,d0>,eq	;$04�Ń��g���C
			endif
			break	<tst.b d0>,ne
			add.w	#$0100,d1
		while	<cmp.w #$9000,d1>,ne
	else				;SCSI�����@
		lea.l	$00EA0044,a0		;'SCSIEX'
		bsr	read_long
		if	<cmp.l #'SCSI',d0>,eq
			bsr	read_word
			goto	<cmp.w #'EX',d0>,eq,@f	;�g��SCSI������
		endif
	;�g��SCSI���Ȃ�
	;SCSIINROM��scsi_init_routine���Ăяo��
		movea.l	$00FC0020,a1		;scsi_init_handle
		jsr	(a1)
	@@:
	endif
	pop
	rts



;----------------------------------------------------------------
;	�s�
;		�d����g���Ǝ��s���̃v���O�������듮�삷�邱�Ƃ�����
;		https://stdkmd.net/bugsx68k/#rom_dentakud3
;	�ύX�O
;		00FF3BFC 48E76000               movem.l	d1-d2,-(sp)
;		00FF3C00
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_1st,$00FF3BFC,$00FF3BFF,$48E76000
	movem.l	d1-d3,-(sp)
;----------------------------------------------------------------
;	�ύX�O
;		00FF3C16 4CDF0006               movem.l	(sp)+,d1-d2
;		00FF3C1A
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_2nd,$00FF3C16,$00FF3C19,$4CDF0006
	movem.l	(sp)+,d1-d3
;----------------------------------------------------------------
;	�ύX�O
;		00FF3C1C 4CDF0006               movem.l	(sp)+,d1-d2
;		00FF3C20
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_3rd,$00FF3C1C,$00FF3C1F,$4CDF0006
	movem.l	(sp)+,d1-d3
;----------------------------------------------------------------
;	�ύX�O
;		00FF3C5A 48E76000               movem.l	d1-d2,-(sp)
;		00FF3C5E
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_4th,$00FF3C5A,$00FF3C5D,$48E76000
	movem.l	d1-d3,-(sp)
;----------------------------------------------------------------
;	�ύX�O
;		00FF3C76 4CDF0006               movem.l	(sp)+,d1-d2
;		00FF3C7A
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_5th,$00FF3C76,$00FF3C79,$4CDF0006
	movem.l	(sp)+,d1-d3



;----------------------------------------------------------------
;	�s�
;		�J�[�\������ʂ̍ŉ��s�ɂ���Ɠd�삪��ʊO�ɕ\�������
;		https://stdkmd.net/bugsx68k/#rom_dentaku64
;	�΍�
;		�d��̕\���ʒu�����߂鏈����Y���W�𒲐�����R�[�h��ǉ�����
;		���O�ɂ���d��OFF���[�`�����l�߂Ăł������Ԃ�Y���W�𒲐�����R�[�h����������ł�����Ăяo��
;	�ύX�O
;		00FF4444 3F00                   move.w	d0,-(sp)
;		00FF4446 3F3C0010               move.w	#$0010,-(sp)
;		00FF444A 3F3C00B8               move.w	#$00B8,-(sp)
;		00FF444E 3F380BFE               move.w	BIOS_DEN_Y.w,-(sp)	;�d��\��Y���W
;		00FF4452 3F380BFC               move.w	BIOS_DEN_X.w,-(sp)	;�d��\��X���W
;		00FF4456 3F3C0002               move.w	#$0002,-(sp)
;		00FF445A 61002368               bsr.w	$00FF67C4		;_TXFILL���s
;		00FF445E 4FEF000C               lea.l	$000C(sp),sp
;		00FF4462 4267                   clr.w	-(sp)
;		00FF4464 3F3C0010               move.w	#$0010,-(sp)
;		00FF4468 3F3C00B8               move.w	#$00B8,-(sp)
;		00FF446C 3F380BFE               move.w	BIOS_DEN_Y.w,-(sp)	;�d��\��Y���W
;		00FF4470 3F380BFC               move.w	BIOS_DEN_X.w,-(sp)	;�d��\��X���W
;		00FF4474 3F3C0003               move.w	#$0003,-(sp)
;		00FF4478 6100234A               bsr.w	$00FF67C4		;_TXFILL���s
;		00FF447C 4FEF000C               lea.l	$000C(sp),sp
;		00FF4480 301F                   move.w	(sp)+,d0
;		00FF4482 6704                   beq.s	$00FF4488
;		00FF4484 610065D6               bsr.w	$00FFAA5C		;IOCS _MS_CURON
;		00FF4488 4CDF7FFE               movem.l	(sp)+,d1-d7/a0-a6
;		00FF448C 4E75                   rts
;		00FF448E
;----------------------------------------------------------------
	PATCH_DATA	dentaku64_1st,$00FF4444,$00FF448D,$3F003F3C
;�d��OFF
	move.w	d0,-(sp)
	move.l	#184<<16|16,-(sp)
	move.l	BIOS_DEN_X.w,-(sp)	;�d��\��X���W�BBIOS_DEN_Y �d��\��Y���W
	move.w	#2,-(sp)
	bsr	($00FF67C4)PATCH_ZL	;_TXFILL���s
	clr.w	10(sp)
	addq.w	#1,(sp)			;3
	bsr	($00FF67C4)PATCH_ZL	;_TXFILL���s
	lea.l	12(sp),sp
	move.w	(sp)+,d0
	if	ne
		bsr	($00FFAA5C)PATCH_ZL	;IOCS _MS_CURON
	endif
	movem.l	(sp)+,d1-d7/a0-a6
	rts

dentaku64:
	addq.w	#1,d1			;�J�[�\���̎��̍s
	ifand	<cmp.w #32,d1>,hs,<cmp.w BIOS_CONSOLE_BOTTOM.w,d1>,hi	;32�ȏォ�R���\�[���͈̔͊O
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R���\�[���̍ŉ��s
		if	ne			;�R���\�[����2�s�ȏ゠��
			subq.w	#1,d1			;�R���\�[���̉�����2�Ԗڂ̍s
		endif
	endif
	rts
;----------------------------------------------------------------
;	�ύX�O
;		00FF44A6 5241                   addq.w	#1,d1			;�J�[�\���̎��̍s
;		00FF44A8 E941                   asl.w	#4,d1
;----------------------------------------------------------------
	PATCH_DATA	dentaku64_2nd,$00FF44A6,$00FF44A7,$5241E941
	PATCH_bsr	dentaku64_1st,dentaku64



;----------------------------------------------------------------
;	�s�
;		�\�t�g�L�[�{�[�h�́��L�[�̑ܕ��������Ă��Ȃ�
;		https://stdkmd.net/bugsx68k/#rom_softkeyboard
;	�ύX�O
;		00005AA8 2B80             	.dc.b	__M_M_MM,M_______
;----------------------------------------------------------------
	PATCH_DATA	softkeyboard,$00FF5AA8,$00FF5AA9,$2B800A00
	.dc.b	__MMM_MM,M_______



;----------------------------------------------------------------
;	�s�
;		_DEFCHR�Ńt�H���g�T�C�Y��0���w�肳�ꂽ�Ƃ�8�ɓǂݑւ��鏈���������R�[�h��0�̂Ƃ������@�\���Ă��Ȃ�
;		_DEFCHR�Ńt�H���g�T�C�Y��6���w��ł��Ȃ�
;		_DEFCHR��_FNTADR���t�H���g�p�^�[����BIOS_FNTADR_BUFFER.w�ɍ쐬���ĕԂ����Ƃ������ɏ㏑�����Ă��ۑ�����Ȃ��̂ɃG���[�ɂȂ�Ȃ�
;		_DEFCHR�Ńt�H���g�A�h���X��X68030�̃n�C��������060turbo�̃��[�J�����������w���Ă����ROM�ƌ�F���ăG���[�ɂȂ�
;	�ύX�O
;		00FF6ADA 70FF                   moveq.l	#$FF,d0
;		00FF6ADC 48E76040               movem.l	d1-d2/a1,-(sp)
;		00FF6AE0 2401                   move.l	d1,d2
;		00FF6AE2 4842                   swap.w	d2
;		00FF6AE4 6604                   bne.s	$00FF6AEA
;		00FF6AE6 343C0008               move.w	#$0008,d2
;		00FF6AEA B47C0006               cmp.w	#$0006,d2
;		00FF6AEE 6722                   beq.s	$00FF6B12
;		00FF6AF0 20780458               movea.l	$0458.w,a0		;[$0458.w].l:[$0116]_FNTADR
;		00FF6AF4 4E90                   jsr	(a0)
;		00FF6AF6 2040                   movea.l	d0,a0
;		00FF6AF8 70FF                   moveq.l	#$FF,d0
;		00FF6AFA B1FC00F00000           cmpa.l	#$00F00000,a0		;ROM�Ȃ�L�����Z��
;		00FF6B00 6410                   bcc.s	$00FF6B12
;		00FF6B02 5242                   addq.w	#1,d2
;		00FF6B04 5241                   addq.w	#1,d1
;		00FF6B06 C4C1                   mulu.w	d1,d2
;		00FF6B08 5342                   subq.w	#1,d2
;		00FF6B0A 10D9                   move.b	(a1)+,(a0)+
;		00FF6B0C 51CAFFFC               dbra.w	d2,$00FF6B0A
;		00FF6B10 4280                   clr.l	d0
;		00FF6B12 4CDF0206               movem.l	(sp)+,d1-d2/a1
;		00FF6B16 4E75                   rts
;		00FF6B18
;----------------------------------------------------------------
	PATCH_DATA	defchr,$00FF6ADA,$00FF6B17,$70FF48E7
;----------------------------------------------------------------
;IOCS�R�[��$0F _DEFCHR �t�H���g�p�^�[���ݒ�
;<d1.l:�t�H���g�T�C�Y<<16|�����R�[�h
;	�t�H���g�T�C�Y
;		0,8	8x16,16x16
;		12,24	12x24,24x24
;<a1.l:�t�H���g�p�^�[���̐擪�A�h���X
;>d0.l:0=����I��,-1=�G���[
iocs_0F_DEFCHR:
	push	d1/d2/a0/a1
	move.l	d1,d2
	swap.w	d2
	movea.l	4*($100+_FNTADR).w,a0	;IOCS�R�[��$16 _FNTADR �t�H���g�A�h���X�̎擾
	jsr	(a0)
;<d0.l:�t�H���g�A�h���X
;<d1.w:�������̃o�C�g��-1
;<d2.w:�c�����̃h�b�g��-1
	movea.l	d0,a0			;�t�H���g�A�h���X
	moveq.l	#-1,d0
;�t�H���g�A�h���X��ROM���w���Ă���Ƃ��͏㏑���ł��Ȃ��̂Ŏ��s
	ifor	<cmpa.l #$00F00000,a0>,lo,<cmpa.l #$01000000,a0>,hs
	;�t�H���g�A�h���X��BIOS_FNTADR_BUFFER.w���w���Ă���Ƃ��͏㏑�����Ă��ۑ�����Ȃ��̂Ŏ��s
		if	<cmpa.w #BIOS_FNTADR_BUFFER.w,a0>,ne
		;�t�H���g�p�^�[�����R�s�[����
			addq.w	#1,d1
			addq.w	#1,d2
			mulu.w	d2,d1
			subq.w	#1,d1
			for	d1
				move.b	(a1)+,(a0)+
			next
			moveq.l	#0,d0
		endif
	endif
	pop
	rts



  .if REMOVE_CRTMOD_G_CLR_ON=0

;----------------------------------------------------------------
;	_CRTMOD
;	�ύX�O
;		00006B18 48E77060         	movem.l	d1-d3/a1-a2,-(sp)
;			:
;		00006B8C                  iocs_10_CRTMOD:
;		00006B8C 41F900E80028     	lea.l	CRTC_MODE_RESOLUTION,a0	;���������[�h�Ɖ𑜓x
;			:
;		00007042 0400028001E00001 	.dc.w	1024,640,480,1
;----------------------------------------------------------------
	PATCH_DATA	crtmod,$00FF6B8C,$00FF6B91,$41F900E8
	jmp	iocs_10_CRTMOD
	PATCH_TEXT
;----------------------------------------------------------------
;IOCS�R�[��$10 _CRTMOD ��ʃ��[�h�̎擾�Ɛݒ�
;<d1.w:�ݒ��̉�ʃ��[�h
;	$01xx	���������Ȃ�
;	$16FF	�o�[�W�����m�F�B$16_xxxxxx(CRT����)�܂���$96_xxxxxx(LCD����)��Ԃ�
;	$43xx	CRT�����BSRAM�ɕۑ�����B$43FF��SRAM�̕ύX�̂�
;	$4Cxx	LCD�����BSRAM�ɕۑ�����B$4CFF��SRAM�̕ύX�̂�
;	$56FF	�o�[�W�����m�F�B$16_xxxxxx��Ԃ�
;	$FFFF	�擾�̂�
;>d0.l:�ݒ�O�̉�ʃ��[�h�B�o�[�W�����m�F��$16_xxxxxx�܂���$96_xxxxxx��Ԃ�
;----------------------------------------------------------------
;	��ʃ��[�h
;
;	��ʃ��[�h	�𑜓x	��ʃT�C�Y	����ʃT�C�Y	�F��	�y�[�W��
;	0		��	512x512		1024x1024	16	1
;	1		��	512x512		1024x1024	16	1
;	2		��	256x256		1024x1024	16	1
;	3		��	256x256		1024x1024	16	1
;	4		��	512x512		512x512		16	4
;	5		��	512x512		512x512		16	4
;	6		��	256x256		512x512		16	4
;	7		��	256x256		512x512		16	4
;	8		��	512x512		512x512		256	2
;	9		��	512x512		512x512		256	2
;	10		��	256x256		512x512		256	2
;	11		��	256x256		512x512		256	2
;	12		��	512x512		512x512		65536	1
;	13		��	512x512		512x512		65536	1
;	14		��	256x256		512x512		65536	1
;	15		��	256x256		512x512		65536	1
;	16		��	768x512		1024x1024	16	1
;	17		��	1024x424	1024x1024	16	1
;	18		��	1024x848	1024x1024	16	1
;	19		VGA	640x480		1024x1024	16	1
;	20		��	768x512		512x512		256	2
;	21		��	1024x424	512x512		256	2
;	22		��	1024x848	512x512		256	2
;	23		VGA	640x480		512x512		256	2
;	24		��	768x512		512x512		65536	1
;	25		��	1024x424	512x512		65536	1
;	26		��	1024x848	512x512		65536	1
;	27		VGA	640x480		512x512		65536	1
;	$100+(0�`27)	���������Ȃ�
;	-1	�擾�̂�
;
;	�ȉ��͊g��
;	28		��	384x256		1024x1024	16	1
;	29		��	384x256		512x512		16	4
;	30		��	384x256		512x512		256	2
;	31		��	384x256		512x512		65536	1
;	32		��	512x512(�����`)	1024x1024	16	1
;	33		��	512x512(�����`)	512x512		16	4
;	34		��	512x512(�����`)	512x512		256	2
;	35		��	512x512(�����`)	512x512		65536	1
;	36		��	256x256(�����`)	1024x1024	16	1
;	37		��	256x256(�����`)	512x512		16	4
;	38		��	256x256(�����`)	512x512		256	2
;	39		��	256x256(�����`)	512x512		65536	1
;	40		��	512x256		1024x1024	16	1
;	41		��	512x256		512x512		16	4
;	42		��	512x256		512x512		256	2
;	43		��	512x256		512x512		65536	1
;	44		��	512x256(��)	1024x1024	16	1
;	45		��	512x256(��)	512x512		16	4
;	46		��	512x256(��)	512x512		256	2
;	47		��	512x256(��)	512x512		65536	1
;	���X�v���C�g��512x512
;
;----------------------------------------------------------------
;	���낢��
;
;	CRT������LCD����
;		�e��ʃ��[�h�̓������g�������ꂼ��CRT������LCD�����ɕ�����
;		SRAM_XEIJ��SRAM_XEIJ_LCD_BIT��0�̂Ƃ�CRT�����A1�̂Ƃ�LCD�����̓������g���ŏo�͂���
;
;	��ʃ��[�h17
;		����24.699kHz�A����53.116Hz�A1024x424�A�����1024x1024�A16�F
;		X68000���ォ�炠�邪�����J
;		LCD�����̂Ƃ��͉�ʃ��[�h16�̏㉺�����
;
;	��ʃ��[�h18
;		����24.699kHz�A����53.116Hz�A1024x848(�C���^�[���[�X)�A�����1024x1024�A16�F
;		X68000���ォ�炠�邪�����J
;		LCD�����̂Ƃ��͉�ʃ��[�h16�̏㉺������ăC���^�[���[�X�ɂ���
;
;	��ʃ��[�h19(VGA���[�h)
;		����31.469kHz�A����59.940Hz�A640x480�A�����1024x1024�A16�F
;		X68000 Compact�Œǉ����ꂽ
;		CRT�����̂Ƃ��͉�ʃ��[�h16�̎��͂����
;		LCD�����̂Ƃ��͂��̂܂�
;
;	��ʃ��[�h20�`23
;		��ʃ��[�h16�`19�������512x512�A256�F�ɕύX��������
;		X68030�Œǉ����ꂽ�B�����J
;
;	��ʃ��[�h24�`27
;		��ʃ��[�h16�`19�������512x512�A65536�F�ɕύX��������
;		X68030�Œǉ����ꂽ�B�����J
;
;	�O���t�B�b�N�p���b�g�̃o�O(IPLROM 1.0�`1.3)
;		_CRTMOD���w�肳�ꂽ��ʃ��[�h�ƈقȂ�F���ŃO���t�B�b�N�p���b�g������������
;			https://stdkmd.net/bugsx68k/#rom_crtmod_gpalet
;		256x256��16�F�A512x512��256�F�A����ȊO��65536�F�ɂȂ�
;
;	��ʃ��[�h20�`27�̃o�O(IPLROM 1.3)
;		��ʃ��[�h��20�`27���w�肳�ꂽ�Ƃ���ʃ��[�h��16�`19�ɂ��Ă���256�F�܂���65536�F�ɕύX���Ă��邪�A
;		���̂Ƃ�BIOS���[�N�G���A�̉�ʃ��[�h��16�`19�̂܂ܕ��u���Ă���
;		������_G_CLR_ON���Ăяo���Ɖ�ʃ��[�h��16�`19�Ȃ̂�16�F�ɖ߂��Ă��܂�
;
;	�N���b�s���O�G���A�̃o�O(IPLROM 1.3)
;		_CRTMOD�ŉ�ʃ��[�h��22�܂���26�ɂ���ƃN���b�s���O�G���A��512x848�ɂȂ�
;
;	VGA�I�V���[�^�̖��
;		����`XVI�ɂ�VGA�I�V���[�^���Ȃ��̂�VGA���[�h���������������g���ŏo�͂���Ȃ�
;		VGA�I�V���[�^������ꍇ
;			(50.350MHz/2)/(8*100)=31.469kHz
;			(50.350MHz/2)/(8*100*525)=59.940Hz
;		VGA�I�V���[�^���Ȃ��ꍇ
;			(69.552MHz/3)/(8*100)=28.980kHz
;			(69.552MHz/3)/(8*100*525)=55.200Hz
;		�傫���O���킯�ł͂Ȃ��̂Ń}���`�X�L�������j�^�͒Ǐ]�ł��邪�C��������
;
;	VGA�I�V���[�^�̗L���̔���
;		VGA���[�h�̐���������VGA�I�V���[�^������Ƃ�16.683ms�A�Ȃ��Ƃ�18.116ms
;		�����������荞�݂̊Ԃ�Timer-C��1��10ms��7.5ms�i�񂾂��ǂ�����VGA�I�V���[�^�̗L���𔻕ʂł���͂�
;		��Ŏ����H
;
;----------------------------------------------------------------
;	�����M����CRTC�ݒ�l�̊֌W
;
;	HT	���������J������
;	HS	���������p���X�J������
;	HB	�����o�b�N�|�[�`�J������
;	HD	�����f�����ԃJ������
;	HF	�����t�����g�|�[�`�J������
;	VT	�����������X�^��
;	VS	���������p���X���X�^��
;	VB	�����o�b�N�|�[�`���X�^��
;	VD	�����f�����ԃ��X�^��
;	VF	�����t�����g�|�[�`���X�^��
;
;	R00	HT-1=HS+HB+HD+HF-1	�����t�����g�|�[�`�I���J����
;	R01	HS-1			���������p���X�I���J����
;	R02	HS+HB-5			�����o�b�N�|�[�`�I���J����-4
;	R03	HS+HB+HD-5		�����f�����ԏI���J����-4
;	R04	VT-1=VS+VB+VD+VF-1	�����t�����g�|�[�`�I�����X�^
;	R05	VS-1			���������p���X�I�����X�^
;	R06	VS+VB-1			�����o�b�N�|�[�`�I�����X�^
;	R07	VS+VB+VD-1		�����f�����ԏI�����X�^
;
;----------------------------------------------------------------
;	�I�V���[�^�ƕ������R20L��HRL�̊֌W
;
;	OSC/DIV	R20L	HRL
;	38/8	%0**00	*
;	38/4	%0**01	*
;	38/8	%0**1*	*
;	69/6	%1**00	0
;	69/8	%1**00	1
;	69/3	%1**01	0
;	69/4	%1**01	1
;	69/2	%1**10	*	�X�v���C�g�s��
;	50/2	%1**11	*	�X�v���C�g�s�BCompact����
;
;----------------------------------------------------------------
;	CRTC�ݒ�l(CRT����)
;
;	CRT 0/4/8/12: 512x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   91   9  17  81      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   92  10  12  64   6  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*92)=31.500kHz (69.552MHz/3)/(8*92*568)=55.458Hz
;	  64/92=0.696 512/568=0.901 (0.696/0.901)/(512/512)=0.772
;	  31k
;
;	CRT 1/5/9/13: 512x512 15.980kHz 61.463Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %00101   0   75   3   5  69      259   2  16 256     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 38.864   4   76   4   6  64   2  260   3  14 240   3 |
;	  +------------------------------------------------------+
;	  (38.864MHz/4)/(8*76)=15.980kHz (38.864MHz/4)/(8*76*260)=61.463Hz
;	  64/76=0.842 240/260=0.923 (0.842/0.923)/(512/512)=0.912
;	  15k �C���^�[���[�X
;
;	CRT 2/6/10/14: 256x256 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   45   4   6  38      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   46   5   6  32   3  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*46)=31.500kHz (69.552MHz/6)/(8*46*568)=55.458Hz
;	  32/46=0.696 512/568=0.901 (0.696/0.901)/(256/256)=0.772
;	  31k ���X�^2�x�ǂ�
;
;	CRT 3/7/11/15: 256x256 15.980kHz 61.463Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %00000   0   37   1   0  32      259   2  16 256     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 38.864   8   38   2   3  32   1  260   3  14 240   3 |
;	  +------------------------------------------------------+
;	  (38.864MHz/8)/(8*38)=15.980kHz (38.864MHz/8)/(8*38*260)=61.463Hz
;	  32/38=0.842 240/260=0.923 (0.842/0.923)/(256/256)=0.912
;	  15k
;
;	CRT 16/20/24: 768x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  28 124      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  18  96   9  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  96/138=0.696 512/568=0.901 (0.696/0.901)/(768/512)=0.514
;	  31k
;
;	CRT 17/21/25: 1024x424 24.699kHz 53.116Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  175  15  31 159      464   7  32 456     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  176  16  20 128  12  465   8  25 424   8 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*176)=24.699kHz (69.552MHz/2)/(8*176*465)=53.116Hz
;	  128/176=0.727 424/465=0.912 (0.727/0.912)/(1024/424)=0.330
;	  24k
;
;	CRT 18/22/26: 1024x848 24.699kHz 53.116Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %11010   0  175  15  31 159      464   7  32 456     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  176  16  20 128  12  465   8  25 424   8 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*176)=24.699kHz (69.552MHz/2)/(8*176*465)=53.116Hz
;	  128/176=0.727 424/465=0.912 (0.727/0.912)/(1024/848)=0.661
;	  24k �C���^�[���[�X
;
;	CRT 19/23/27: 640x480 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  36 116      567   5  56 536     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  26  80  17  568   6  51 480  31 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  80/138=0.580 480/568=0.845 (0.580/0.845)/(640/480)=0.514
;	  31k
;
;	CRT 28/29/30/31: 384x256 31.963kHz 56.273Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  11  59      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7   9  48   4  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*568)=56.273Hz
;	  48/68=0.706 512/568=0.901 (0.706/0.901)/(384/256)=0.522
;	  31k ���X�^2�x�ǂ�
;
;	CRT 32/33/34/35: 512x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  44 108      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  34  64  25  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  64/138=0.464 512/568=0.901 (0.464/0.901)/(512/512)=0.514
;	  31k
;
;	CRT 36/37/38/39: 256x256 31.963kHz 56.273Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  19  51      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7  17  32  12  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*568)=56.273Hz
;	  32/68=0.471 512/568=0.901 (0.471/0.901)/(256/256)=0.522
;	  31k ���X�^2�x�ǂ�
;
;	CRT 40/41/42/43/44/45/46/47: 512x256 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   0   91   9  17  81      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   92  10  12  64   6  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*92)=31.500kHz (69.552MHz/3)/(8*92*568)=55.458Hz
;	  64/92=0.696 512/568=0.901 (0.696/0.901)/(512/256)=0.386
;	  31k
;
;----------------------------------------------------------------
;	CRTC�ݒ�l(LCD����)
;
;	LCD 0/4/8/12: 512x512 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   81   5  11  75      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 512/625=0.819 (0.780/0.819)/(512/512)=0.953
;	  SVGA
;
;	LCD 1/5/9/13: 512x512 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   81   5  11  75      624   1  83 563     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  82 480  61 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 480/625=0.768 (0.780/0.768)/(512/512)=1.016
;	  SVGA
;
;	LCD 2/6/10/14: 256x256 34.500kHz 55.200Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   41   2   3  35      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   42   3   5  32   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*42)=34.500kHz (69.552MHz/6)/(8*42*625)=55.200Hz
;	  32/42=0.762 512/625=0.819 (0.762/0.819)/(256/256)=0.930
;	  SVGA ���X�^2�x�ǂ�
;
;	LCD 3/7/11/15: 256x256 34.500kHz 55.200Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   41   2   3  35      624   1  83 563     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   42   3   5  32   2  625   2  82 480  61 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*42)=34.500kHz (69.552MHz/6)/(8*42*625)=55.200Hz
;	  32/42=0.762 480/625=0.768 (0.762/0.768)/(256/256)=0.992
;	  SVGA ���X�^2�x�ǂ�
;
;	LCD 16/20/24: 768x512 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  19 115      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 512/625=0.819 (0.774/0.819)/(768/512)=0.630
;	  SVGA
;
;	LCD 17/21/25: 768x600 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  19 115      624   1  23 623     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  22 600   1 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 600/625=0.960 (0.774/0.960)/(768/600)=0.630
;	  SVGA
;
;	LCD 18/22/26: 768x1024 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %11010   0  123   8  19 115      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 512/625=0.819 (0.774/0.819)/(768/1024)=1.260
;	  SVGA �C���^�[���[�X
;
;	LCD 19/23/27: 640x480 31.469kHz 59.940Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10111   0   99  11  13  93      524   1  34 514     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 50.350   2  100  12   6  80   2  525   2  33 480  10 |
;	  +------------------------------------------------------+
;	  (50.350MHz/2)/(8*100)=31.469kHz (50.350MHz/2)/(8*100*525)=59.940Hz
;	  80/100=0.800 480/525=0.914 (0.800/0.914)/(640/480)=0.656
;	  VGA
;
;	LCD 28/29/30/31: 384x256 31.963kHz 51.141Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  11  59      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7   9  48   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*625)=51.141Hz
;	  48/68=0.706 512/625=0.819 (0.706/0.819)/(384/256)=0.574
;	  ���X�^2�x�ǂ�
;
;	LCD 32/33/34/35: 512x512 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  35  99      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  31  64  20  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  64/124=0.516 512/625=0.819 (0.516/0.819)/(512/512)=0.630
;	  SVGA
;
;	LCD 36/37/38/39: 256x256 31.963kHz 51.141Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  19  51      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7  17  32  12  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*625)=51.141Hz
;	  32/68=0.471 512/625=0.819 (0.471/0.819)/(256/256)=0.574
;	  ���X�^2�x�ǂ�
;
;	LCD 40/41/42/43/44/45/46/47: 512x256 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   0   81   5  11  75      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 512/625=0.819 (0.780/0.819)/(512/256)=0.476
;	  SVGA
;
;	�y�Q�l�zVGA: 640x480 31.469kHz 59.940Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 25.175      100  12   6  80   2  525   2  33 480  10 |
;	  +------------------------------------------------------+
;	  25.175MHz/(8*100)=31.469kHz (25.175MHz/1)/(8*100*525)=59.940Hz
;	  80/100=0.800 480/525=0.914 (0.800/0.914)/(640/480)=0.656
;
;	�y�Q�l�zSVGA: 800x600 35.156kHz 56.250Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 36.000      128   9  16 100   3  625   2  22 600   1 |
;	  +------------------------------------------------------+
;	  36.000MHz/(8*128)=35.156kHz (36.000MHz/1)/(8*128*625)=56.250Hz
;	  100/128=0.781 600/625=0.960 (0.781/0.960)/(800/600)=0.610
;
;	�y�Q�l�zSVGA: 800x600 37.879kHz 60.317Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 40.000      132  16  11 100   5  628   4  23 600   1 |
;	  +------------------------------------------------------+
;	  40.000MHz/(8*132)=37.879kHz (40.000MHz/1)/(8*132*628)=60.317Hz
;	  100/132=0.758 600/628=0.955 (0.758/0.955)/(800/600)=0.595
;
;	�y�Q�l�zSVGA: 800x600 46.875kHz 75.000Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 49.500      132  10  20 100   2  625   3  21 600   1 |
;	  +------------------------------------------------------+
;	  49.500MHz/(8*132)=46.875kHz (49.500MHz/1)/(8*132*625)=75.000Hz
;	  100/132=0.758 600/625=0.960 (0.758/0.960)/(800/600)=0.592
;
;----------------------------------------------------------------

;�p�����[�^1
	.offset	0
crtmod_param_1_width:	.ds.w	1
crtmod_param_1_height:	.ds.w	1
crtmod_param_1_r20h:	.ds.b	1
			.ds.b	1
crtmod_param_1_2nd:	.ds.w	1
crtmod_param_1_size:
	.text

;�p�����[�^2
	.offset	0
crtmod_param_2_r20l:	.ds.b	1
crtmod_param_2_hrl:	.ds.b	1
crtmod_param_2_r00:	.ds.w	1
crtmod_param_2_r01:	.ds.w	1
crtmod_param_2_r02:	.ds.w	1
crtmod_param_2_r03:	.ds.w	1
crtmod_param_2_r04:	.ds.w	1
crtmod_param_2_r05:	.ds.w	1
crtmod_param_2_r06:	.ds.w	1
crtmod_param_2_r07:	.ds.w	1
crtmod_param_2_r08:	.ds.w	1
crtmod_param_2_size:
	.text

crtmod_param_1	.macro	width,height,r20h,offset2nd
	.dc.w	width
	.dc.w	height
	.dc.b	r20h			;R20H
	.dc.b	0
	.dc.w	crtmod_param_2_size*offset2nd
	.endm

crtmod_param_2	.macro	r20l,hrl,ht,hs,hb,hd,hf,vt,vs,vb,vd,vf,r08
	.fail	(ht.and.1)!=0
	.fail	ht!=hs+hb+hd+hf
	.fail	vt!=vs+vb+vd+vf
	.dc.b	r20l			;R20L
	.dc.b	hrl			;HRL
	.dc.w	hs+hb+hd+hf-1		;R00
	.dc.w	hs-1			;R01
	.dc.w	hs+hb-5			;R02
	.dc.w	hs+hb+hd-5		;R03
	.dc.w	vs+vb+vd+vf-1		;R04
	.dc.w	vs-1			;R05
	.dc.w	vs+vb-1			;R06
	.dc.w	vs+vb+vd-1		;R07
	.dc.w	r08			;R08
	.endm

crtmod_modes	equ	(crtmod_table_1_crt_end-crtmod_table_1_crt)/crtmod_param_1_size	;��ʃ��[�h�̐�

	.text
	.even
iocs_10_CRTMOD:
dMM	reg	d3			;���������[�h
dPM	reg	d4			;�ݒ�O�̉�ʃ��[�h
aE8	reg	a2			;(�`)E8�̃x�[�X�A�h���X
aEB	reg	a3			;(�`)EB�̃x�[�X�A�h���X
aED	reg	a4			;(�`)ED�̃x�[�X�A�h���X
aP1	reg	a5			;�p�����[�^1�̃A�h���X
aP2	reg	a6			;�p�����[�^2�̃A�h���X
	push	d1-d2/dMM/dPM/a0-a1/aE8/aEB/aED/aP1/aP2

;(�`)E8�ŃA�N�Z�X����
;	$00E80000	CRTC
;	$00E82000	VICON
;	$00E84000	DMAC
;	$00E86000	SUPERAREA
;	$00E88000	MFP
;	$00E8A000	RTC
;	$00E8C000	PRNPORT
;	$00E8E000	SYSPORT
	lea.l	$00E88000,aE8
E8	reg	-$00E88000(aE8)

;(�`)EB�ŃA�N�Z�X����
;	$00EB0000	SPRC
	lea.l	$00EB8000,aEB
EB	reg	-$00EB8000(aEB)

;(�`)ED�ŃA�N�Z�X����
;	$00ED0000	SRAM
	lea.l	$00ED8000,aED
ED	reg	-$00ED8000(aED)

;SRAM������������
	moveq.l	#$60,d0
	moveq.l	#$F0,d2
	and.b	(SRAM_XEIJ)ED,d2
	if	<cmp.b d0,d2>,ne	;����������Ă��Ȃ�
		move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
		move.b	d0,(SRAM_XEIJ)ED	;����������
		clr.b	(SYSPORT_SRAM)E8	;locksram
	endif

;�o�[�W�����m�F
	move.l	#CRTMOD_VERSION,d0
	goto	<cmp.w #$56FF,d1>,eq,@f
	if	<cmp.w #$16FF,d1>,eq
		if	<btst.b #SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED>,ne
			bset.l	#31,d0
		endif
@@:		goto	crtmod_pop

	endif

;�ݒ�O�̉�ʃ��[�h���m�F����
	moveq.l	#0,dPM
	move.b	BIOS_CRTMOD.w,dPM	;�ݒ�O�̉�ʃ��[�h
	swap.w	dPM
;<dPM.l:�ݒ�O�̉�ʃ��[�h<<16

;���������邩
	move.w	d1,dPM
	clr.b	dPM
	sub.w	dPM,d1
;<d1.w:��ʃ��[�h
;<dPM.w:$0000=����������,$0100=���������Ȃ�,$4300=CRT����,$4C00=LCD����

;CRT������LCD�����̃X�C�b�`�̐؂�ւ�
	if	<cmp.w #$4300,dPM>,eq	;CRT����
		move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
		bclr.b	#SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED
		clr.b	(SYSPORT_SRAM)E8	;locksram
		clr.w	dPM			;����������
	elif	<cmp.w #$4C00,dPM>,eq	;LCD����
		move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
		bset.b	#SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED
		clr.b	(SYSPORT_SRAM)E8	;locksram
		clr.w	dPM			;����������
	endif
;<dPM.w:$0000=����������,$0100=���������Ȃ�

;�擾�݂̂�
;	IPLROM 1.0�`1.3��$FFFF�������Đݒ��̉�ʃ��[�h���͈͊O�̂Ƃ��������Ȃ�
;	�����ł�$FFFF���܂߂Đݒ��̉�ʃ��[�h���͈͊O�̂Ƃ��擾�݂̂Ƃ���
;	������$43FF��$4CFF��CRT������LCD�����̃X�C�b�`�̐؂�ւ������s��
	goto	<cmp.w #crtmod_modes,d1>,hs,crtmod_end	;�ݒ��̉�ʃ��[�h���͈͊O

;�ݒ肷��

;�p�����[�^1�̃A�h���X�����߂�
	lea.l	crtmod_table_1_crt(pc),aP1
	if	<btst.b #SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED>,ne	;LCD����
		lea.l	crtmod_table_1_lcd(pc),aP1
	endif
	move.w	d1,d0
  .if crtmod_param_1_size=8
	lsl.w	#3,d0
  .else
	mulu.w	#crtmod_param_1_size,d0
  .endif
	adda.w	d0,aP1
;<aP1.l:�p�����[�^1�̃A�h���X

;�p�����[�^2�̃A�h���X�����߂�
	lea.l	crtmod_table_2(pc),aP2
	adda.w	crtmod_param_1_2nd(aP1),aP2
;<aP2.l:�p�����[�^2�̃A�h���X

;���������[�h���m�F����
	moveq.l	#7,dMM
	and.b	crtmod_param_1_r20h(aP1),dMM	;���������[�h�B0�`7
;<dMM.w:���������[�h�B0�`7

;���������邩
	if	<tst.w dPM>,eq

	;����������

	;�ݒ��̉�ʃ��[�h��ۑ�����
		move.b	d1,BIOS_CRTMOD.w	;�ݒ��̉�ʃ��[�h

	;�O���t�B�b�N���OFF�A�e�L�X�g���OFF�A�X�v���C�g���OFF
		clr.w	(VICON_VISIBLE)E8

	;�e�L�X�g�J�[�\��OFF
		IOCS	_B_CUROFF

	;�e�L�X�g�v���[��0�`1���N���A����
	;	���X�^�R�s�[���g���Ƒ������R�[�h�������Ȃ�
	;	�����CRTC�������Ă��Ȃ��̂Ń��X�^�R�s�[���I���Ȃ�
		move.w	#$0133,(CRTC_ACCESS)E8	;�����A�N�Z�X�J�n
		moveq.l	#0,d0
		lea.l	$00E00000,a0		;�e�L�X�gVRAM
		move.w	#($00E20000-$00E00000)/(4*2)-1,d1	;16384��
		for	d1
			move.l	d0,(a0)+
			move.l	d0,(a0)+
		next
		move.w	#$0033,(CRTC_ACCESS)E8	;�����A�N�Z�X�I��

	;�O���t�B�b�N��ʎg�p�s��
		clr.w	BIOS_GRAPHIC_PALETS.w	;�O���t�B�b�N��ʂ̐F��-1�B0=�O���t�B�b�N��ʎg�p�s��

	;����������/���Ȃ�����
		bsr	crtmod_common

	;CRTC�R�}���h��~
		clr.w	(CRTC_ACTION)E8

	;�O���t�B�b�N�p���b�g������������
  .ifdef CRTMOD_REPRODUCE_BUG		;�o�O���Č�������
		moveq.l	#3,d0
		and.b	crtmod_param_2_r20l(aP2),d0	;�����𑜓x�B256x256=256�F,512x512=512�F,768x512=65536�F
  .else
		move.w	dMM,d0			;���������[�h�B0�`7
  .endif
		bsr	initialize_gpalet	;�O���t�B�b�N�p���b�g������������

	;�O���t�B�b�N�X�g���[�WON
	;	IPLROM 1.0�`1.3��_CRTMOD�̓O���t�B�b�N�X�g���[�WON�̏�Ԃŕ��A����
		bset.b	#CRTC_GRAPHIC_STORAGE_BIT,(CRTC_MODE_BYTE)E8	;�O���t�B�b�N�X�g���[�WON

	;�e�L�X�g�J�[�\��ON
		IOCS	_B_CURON

	;�e�L�X�g�p���b�g������������
		lea.l	(SRAM_TEXT_PALET_0)ED,a0
		lea.l	(VICON_TSPALET)E8,a1
		move.l	(a0)+,(a1)+		;0,1
		move.l	(a0)+,(a1)+		;2,3
		move.l	(a0),d0			;d0=4|8
		move.l	d0,d1			;d1=4|8
		swap.w	d0			;d0=8|4
		move.w	d0,(a1)+		;4
		move.w	d0,(a1)+		;5
		move.w	d0,(a1)+		;6
		move.w	d0,(a1)+		;7
		move.w	d1,d0			;d0=8|8
		move.l	d0,(a1)+		;8,9
		move.l	d0,(a1)+		;10,11
		move.l	d0,(a1)+		;12,13
		move.l	d0,(a1)+		;14,15

	;�R���g���X�g������������
		move.b	(SRAM_CONTRAST)ED,(SYSPORT_CONTRAST)E8

	;�X�v���C�g�R���g���[����ݒ肷��
~i = SPRC_SPRITE_OFF|SPRC_BG_1_TEXT_1|SPRC_BG_1_OFF|SPRC_BG_0_TEXT_0|SPRC_BG_0_OFF
		move.w	#~i,(SPRC_CONTROL)EB

	;�e�L�X�g���ON
		move.w	#VICON_TXON_MASK,(VICON_VISIBLE)E8

	;�D�揇�ʂ�ݒ肷��
~i = 0<<VICON_SPPR_BIT|1<<VICON_TXPR_BIT|2<<VICON_GRPR_BIT			;SP>TX>GR
~j = 3<<VICON_G4TH_BIT|2<<VICON_G3RD_BIT|1<<VICON_G2ND_BIT|0<<VICON_G1ST_BIT	;G1>G2>G3>G4
		move.w	#~i|~j,(VICON_PRIORITY)E8

	else

	;���������Ȃ�

	;�ݒ��̉�ʃ��[�h��ۑ�����
		move.b	d1,BIOS_CRTMOD.w	;�ݒ��̉�ʃ��[�h

	;�O���t�B�b�N��ʎg�p�s��
		clr.w	BIOS_GRAPHIC_PALETS.w	;�O���t�B�b�N��ʂ̐F��-1�B0=�O���t�B�b�N��ʎg�p�s��

	;����������/���Ȃ�����
		bsr	crtmod_common

	;�O���t�B�b�N��ʂ��\������Ă��邩
		moveq.l	#VICON_GXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,d0
		and.w	(VICON_VISIBLE)E8,d0
		if	ne			;�O���t�B�b�N��ʂ��\������Ă���Ƃ�

		;���������[�h��ݒ肷��
		;	�X�g���[�W�͕ω����Ȃ�
			moveq.l	#.not.7,d0
			and.b	(CRTC_MODE_BYTE)E8,d0
			or.b	dMM,d0
			move.b	d0,(CRTC_MODE_BYTE)E8
			move.w	dMM,(VICON_MEMORY_MODE)E8

		;BIOS���[�N�G���A������������
			move.l	#$00C00000,BIOS_GRAPHIC_PAGE.w
			if	<cmp.w #4,dMM>,lo	;���������[�h0�`3�B512x512�h�b�g
				move.l	#2*512,BIOS_GRAPHIC_Y_OFFSET.w
				if	<cmp.w #1,dMM>,lo	;���������[�h0�B512x512�h�b�g�A16�F�A4�y�[�W
					move.w	#16-1,BIOS_GRAPHIC_PALETS.w
				elif	eq			;���������[�h1�B512x512�h�b�g�A256�F�A2�y�[�W
					move.w	#256-1,BIOS_GRAPHIC_PALETS.w
				else				;���������[�h2�`3�B512x512�h�b�g�A65536�F�A1�y�[�W
					move.w	#65536-1,BIOS_GRAPHIC_PALETS.w
				endif
			else					;���������[�h4�`7�B1024x1024�h�b�g�A16�F�A1�y�[�W
				move.l	#2*1024,BIOS_GRAPHIC_Y_OFFSET.w
				move.w	#16-1,BIOS_GRAPHIC_PALETS.w
			endif

		endif

	endif

;�I��
;<dPM.l:�ݒ�O�̉�ʃ��[�h<<16
crtmod_end:
	clr.w	dPM
	swap.w	dPM			;�ݒ�O�̉�ʃ��[�h
	move.l	dPM,d0
crtmod_pop:
	pop
	rts

;����������/���Ȃ�����
crtmod_common:

;CRTC�ƃV�X�e���|�[�g��R20,HRL,R00�`R07��ݒ肷��
;	���ׂẲ�ʃ��[�h�����������[�h3�ɂȂ�
;	�X�g���[�W��OFF�ɂȂ�
	move.w	#3<<8,d2		;R20H(�V)
	move.b	crtmod_param_2_r20l(aP2),d2	;R20L(�V)
;<d2.w:R20(�V)
	lea.l	dot_clock_rank(pc),a0
	moveq.l	#%00011111,d0
	and.b	(CRTC_RESOLUTION_BYTE)E8,d0	;R20L(��)
	moveq.l	#SYSPORT_HRL,d1
	and.b	(SYSPORT_MISC)E8,d1
	neg.b	d1
	addx.b	d0,d0				;R20L<<1|HRL(��)
	move.b	(a0,d0.w),d0			;�Â��h�b�g�N���b�N�̃����N
	moveq.l	#%00011111,d1
	and.b	d2,d1				;R20L(�V)
	add.b	d1,d1
	add.b	crtmod_param_2_hrl(aP2),d1	;R20L<<1|HRL(�V)
	move.b	(a0,d1.w),d1			;�V�����h�b�g�N���b�N�̃����N
	if	<cmp.b d0,d1>,lo	;�h�b�g�N���b�N��������
		move.w	d2,(CRTC_MODE_RESOLUTION)E8	;R20
		tst.b	crtmod_param_2_hrl(aP2)
		bsne.b	#SYSPORT_HRL_BIT,(SYSPORT_MISC)E8	;HRL
		lea.l	(CRTC_H_SYNC_END)E8,a0	;R01
		lea.l	crtmod_param_2_r01(aP2),a1
		move.w	(a1)+,(a0)+		;R01
		move.l	(a1)+,(a0)+		;R02,R03
		move.l	(a1)+,(a0)+		;R04,R05
		move.l	(a1)+,(a0)+		;R06,R07
		move.w	crtmod_param_2_r00(aP2),(CRTC_H_FRONT_END)E8	;R00
	else				;�h�b�g�N���b�N���������オ��
		lea.l	(CRTC_H_FRONT_END)E8,a0	;R00
		lea.l	crtmod_param_2_r00(aP2),a1
		move.l	(a1)+,(a0)+		;R00,R01
		move.l	(a1)+,(a0)+		;R02,R03
		move.l	(a1)+,(a0)+		;R04,R05
		move.l	(a1)+,(a0)+		;R06,R07
		move.w	d2,(CRTC_MODE_RESOLUTION)E8	;R20
		tst.b	crtmod_param_2_hrl(aP2)
		bsne.b	#SYSPORT_HRL_BIT,(SYSPORT_MISC)E8	;HRL
	endif

;CRTC��R08��ݒ肷��
;	�O�����������A�W���X�g
;	�X�[�p�[�C���|�[�Y����Ƃ��r�f�I�̉f����X68000�̉f�����d�˂邽�߂ɁA
;	�r�f�I��X68000�̐��������p���X�̐擪�̎��ԍ���38.863632MHz�̃T�C�N�����Ŏw�肷��
;	��𑜓x512x512�̂Ƃ�
;		���������p���X����4�L�����N�^�BR01=4-1=3
;		�����o�b�N�|�[�`��6�L�����N�^�BR02=4+6-5=5
;		�O�����������A�W���X�g��44
;		perl -e "print((4.7+4.7)*38.863632-(4*8*(4+6))-1)"
;		44.3181408
;	��𑜓x256x256�̂Ƃ��B1�h�b�g�ǉ�����
;		���������p���X����2�L�����N�^�BR01=2-1=1
;		�����o�b�N�|�[�`��3�L�����N�^�BR02=2+3-5=0
;		�O�����������A�W���X�g��36
;		perl -e "print((4.7+4.7)*38.863632-(8*(8*(2+3)+1))-1)"
;		36.3181408
	move.w	crtmod_param_2_r08(aP2),(CRTC_ADJUST)E8	;R08

;CRTC��R09�`R19,R21�`R24������������
	moveq.l	#0,d0
	lea.l	(CRTC_RASTER)E8,a0	;R09
	move.w	d0,(a0)+		;R09
	move.l	d0,(a0)+		;R10,R11
	move.l	d0,(a0)+		;R12,R13
	move.l	d0,(a0)+		;R14,R15
	move.l	d0,(a0)+		;R16,R17
	move.l	d0,(a0)+		;R18,R19
	addq.l	#2,a0
	move.w	#$0033,(a0)+		;R21
	move.l	d0,(a0)+		;R22,R23
	move.w	d0,(a0)+		;R24

;�r�f�I�R���g���[���̃��������[�h��ݒ肷��
;	���ׂẲ�ʃ��[�h�����������[�h3�ɂȂ�
	move.w	#3,(VICON_MEMORY_MODE)E8

;�X�v���C�g�R���g���[��������������
;�𑜓x
	moveq.l	#%1_11_11,d1
	and.b	crtmod_param_2_r20l(aP2),d1	;R20L
;<d1.w:�𑜓x
;�����o�b�N�|�[�`�I���J����
	moveq.l	#4,d0
	add.w	crtmod_param_2_r02(aP2),d0
	move.w	d0,(SPRC_H_BACK_END)EB	;�X�v���C�g�����o�b�N�|�[�`�I���J�����BR02+4
;�����t�����g�|�[�`�I���J����
;	�����o�b�N�|�[�`�I���J������ݒ��130us�҂��Ă��琅���t�����g�|�[�`�I���J������ݒ肷��
;	�����t�����g�|�[�`�I���J�����͐���256�h�b�g�̂Ƃ���R00�Ɠ����l�A����ȊO��255
;		Inside X68000�ɒ�𑜓x256x256�̂Ƃ�����R00�Ɠ����l���A����ȊO��255��ݒ肷��Ə�����Ă��邪�A
;		���𑜓x256x256�̂Ƃ���255�ɂ���ƃX�v���C�g�������ꍇ������
;		����512�h�b�g�̂Ƃ���255�ɂ��Ȃ��Ɛ���256�h�b�g���琅��512�h�b�g�ɐ؂�ւ����Ƃ��X�v���C�g�̐��������̈ʒu������邱�Ƃ�����
;	IPLROM 1.3��dbra��X68030 25MHz�̂Ƃ�500us�҂��Ă���B060turbo�̂Ƃ��E�G�C�g���s������
	moveq.l	#500/50,d0		;500us
	bsr	wait_50us		;50us�P�ʂ̃E�F�C�g
	moveq.l	#%0_00_11,d0
	and.b	d1,d0
	if	eq			;����256�h�b�g
		move.w	crtmod_param_2_r00(aP2),(SPRC_H_FRONT_END)EB	;�X�v���C�g�����t�����g�|�[�`�I���J�����BR00
	else				;����256�h�b�g�ȊO
		move.w	#255,(SPRC_H_FRONT_END)EB	;�X�v���C�g�����t�����g�|�[�`�I���J�����B255
	endif
;�����o�b�N�|�[�`�I�����X�^
	move.w	crtmod_param_2_r06(aP2),(SPRC_V_BACK_END)EB	;�X�v���C�g�����o�b�N�|�[�`�I�����X�^�BR06
;�𑜓x
	moveq.l	#-36,d0
	add.b	BIOS_CRTMOD.w,d0
	ifand	<>,pl,<subq.b #4,d0>,lo	;36/37/38/39 256x256(�����`)
		moveq.l	#%10000,d1		;�X�v���C�g��256x256
	elifand	<subq.b #4,d0>,hs,<subq.b #4,d0>,lo	;44/45/46/47 512x256(��)
		moveq.l	#%10101,d1		;�X�v���C�g��512x512
	endif
	move.w	d1,(SPRC_RESOLUTION)EB	;�X�v���C�g�𑜓x�B--------|---|���𑜓x|�����T�C�Y##|�����T�C�Y##

;�O���t�B�b�N��ʂ̃N���b�s���O�G���A
;	��ʃ��[�h20�`27�͕\����ʂ�����ʂ��傫�����Ƃɒ��ӂ���
	move.w	crtmod_param_1_width(aP1),d0	;��
	move.w	crtmod_param_1_height(aP1),d1	;����
	if	<cmp.w #4,dMM>,lo	;���������[�h0�`3�B512x512�܂�
		move.w	#512,d2
		if	<cmp.w d2,d0>,hi
			move.w	d2,d0
		endif
		if	<cmp.w d2,d1>,hi
			move.w	d2,d1
		endif
	endif
	subq.w	#1,d0			;X�ő�
	subq.w	#1,d1			;Y�ő�
	clr.l	BIOS_GRAPHIC_LEFT.w	;BIOS_GRAPHIC_TOP
	move.w	d0,BIOS_GRAPHIC_RIGHT.w
	move.w	d1,BIOS_GRAPHIC_BOTTOM.w

;�O���t�B�b�NVRAM��Y�����̃I�t�Z�b�g
					;dMM=   0    1    2    3    4    5    6    7
	moveq.l	#4,d0			; d0=   4    4    4    4    4    4    4    4
	and.w	dMM,d0			; d0=   0    0    0    0    4    4    4    4
	addq.w	#4,d0			; d0=   4    4    4    4    8    8    8    8
	lsl.w	#8,d0			; d0=1024 1024 1024 1024 2048 2048 2048 2048
	move.l	d0,BIOS_GRAPHIC_Y_OFFSET.w

;�O���t�B�b�N��ʂ̃y�[�W��
					;dMM=0 1 2  3  4  5  6  7
	moveq.l	#4,d0			; d0=4 4 4  4  4  4  4  4
	lsr.b	dMM,d0			; d0=4 2 1  0  0  0  0  0
	seq.b	d1			; d1=0 0 0 -1 -1 -1 -1 -1
	sub.b	d1,d0			; d0=4 2 1  1  1  1  1  1
	move.b	d0,BIOS_GRAPHIC_PAGES.w

;�e�L�X�g��ʂ̈ʒu
	move.l	#$00E00000,BIOS_TEXT_PLANE.w
	clr.l	BIOS_CONSOLE_OFFSET.w

;�e�L�X�g��ʂ̑傫��
	move.w	crtmod_param_1_width(aP1),d0	;��
	move.w	crtmod_param_1_height(aP1),d1	;����
	lsr.w	#3,d0			;��/8
	lsr.w	#4,d1			;����/16�B424��16�Ŋ���؂�Ȃ����Ƃɒ���
	subq.w	#1,d0			;��/8-1
	subq.w	#1,d1			;����/16-1
	move.w	d0,BIOS_CONSOLE_RIGHT.w
	move.w	d1,BIOS_CONSOLE_BOTTOM.w

;�e�L�X�g�J�[�\���̈ʒu
	clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW

;�}�E�X�J�[�\���̈ړ��͈�
	clr.l	d1
	move.l	BIOS_GRAPHIC_RIGHT,d2	;BIOS_GRAPHIC_BOTTOM
	IOCS	_MS_LIMIT		;IOCS�R�[��$77 _MS_LIMIT �}�E�X�J�[�\���̈ړ��͈͂�ݒ肷��

	rts

;�p�����[�^1(CRT����)
crtmod_table_1_crt:
;			 WIDTH HEIGHT R20H  2ND    1ST
	crtmod_param_1	   512,   512,   4,   0  ; CRT 0
	crtmod_param_1	   512,   512,   4,   1  ; CRT 1
	crtmod_param_1	   256,   256,   4,   2  ; CRT 2
	crtmod_param_1	   256,   256,   4,   3  ; CRT 3
	crtmod_param_1	   512,   512,   0,   0  ; CRT 4
	crtmod_param_1	   512,   512,   0,   1  ; CRT 5
	crtmod_param_1	   256,   256,   0,   2  ; CRT 6
	crtmod_param_1	   256,   256,   0,   3  ; CRT 7
	crtmod_param_1	   512,   512,   1,   0  ; CRT 8
	crtmod_param_1	   512,   512,   1,   1  ; CRT 9
	crtmod_param_1	   256,   256,   1,   2  ; CRT 10
	crtmod_param_1	   256,   256,   1,   3  ; CRT 11
	crtmod_param_1	   512,   512,   3,   0  ; CRT 12
	crtmod_param_1	   512,   512,   3,   1  ; CRT 13
	crtmod_param_1	   256,   256,   3,   2  ; CRT 14
	crtmod_param_1	   256,   256,   3,   3  ; CRT 15
	crtmod_param_1	   768,   512,   4,   4  ; CRT 16
	crtmod_param_1	  1024,   424,   4,   5  ; CRT 17
	crtmod_param_1	  1024,   848,   4,   6  ; CRT 18
	crtmod_param_1	   640,   480,   4,   7  ; CRT 19
	crtmod_param_1	   768,   512,   1,   4  ; CRT 20
	crtmod_param_1	  1024,   424,   1,   5  ; CRT 21
	crtmod_param_1	  1024,   848,   1,   6  ; CRT 22
	crtmod_param_1	   640,   480,   1,   7  ; CRT 23
	crtmod_param_1	   768,   512,   3,   4  ; CRT 24
	crtmod_param_1	  1024,   424,   3,   5  ; CRT 25
	crtmod_param_1	  1024,   848,   3,   6  ; CRT 26
	crtmod_param_1	   640,   480,   3,   7  ; CRT 27
	crtmod_param_1	   384,   256,   4,   8  ; CRT 28
	crtmod_param_1	   384,   256,   0,   8  ; CRT 29
	crtmod_param_1	   384,   256,   1,   8  ; CRT 30
	crtmod_param_1	   384,   256,   3,   8  ; CRT 31
	crtmod_param_1	   512,   512,   4,   9  ; CRT 32
	crtmod_param_1	   512,   512,   0,   9  ; CRT 33
	crtmod_param_1	   512,   512,   1,   9  ; CRT 34
	crtmod_param_1	   512,   512,   3,   9  ; CRT 35
	crtmod_param_1	   256,   256,   4,  10  ; CRT 36
	crtmod_param_1	   256,   256,   0,  10  ; CRT 37
	crtmod_param_1	   256,   256,   1,  10  ; CRT 38
	crtmod_param_1	   256,   256,   3,  10  ; CRT 39
	crtmod_param_1	   512,   256,   4,  22  ; CRT 40
	crtmod_param_1	   512,   256,   0,  22  ; CRT 41
	crtmod_param_1	   512,   256,   1,  22  ; CRT 42
	crtmod_param_1	   512,   256,   3,  22  ; CRT 43
	crtmod_param_1	   512,   256,   4,  22  ; CRT 44
	crtmod_param_1	   512,   256,   0,  22  ; CRT 45
	crtmod_param_1	   512,   256,   1,  22  ; CRT 46
	crtmod_param_1	   512,   256,   3,  22  ; CRT 47
crtmod_table_1_crt_end:

;�p�����[�^1(LCD����)
crtmod_table_1_lcd:
;			 WIDTH HEIGHT R20H  2ND    1ST
	crtmod_param_1	   512,   512,   4,  11  ; LCD 0
	crtmod_param_1	   512,   512,   4,  12  ; LCD 1
	crtmod_param_1	   256,   256,   4,  13  ; LCD 2
	crtmod_param_1	   256,   256,   4,  14  ; LCD 3
	crtmod_param_1	   512,   512,   0,  11  ; LCD 4
	crtmod_param_1	   512,   512,   0,  12  ; LCD 5
	crtmod_param_1	   256,   256,   0,  13  ; LCD 6
	crtmod_param_1	   256,   256,   0,  14  ; LCD 7
	crtmod_param_1	   512,   512,   1,  11  ; LCD 8
	crtmod_param_1	   512,   512,   1,  12  ; LCD 9
	crtmod_param_1	   256,   256,   1,  13  ; LCD 10
	crtmod_param_1	   256,   256,   1,  14  ; LCD 11
	crtmod_param_1	   512,   512,   3,  11  ; LCD 12
	crtmod_param_1	   512,   512,   3,  12  ; LCD 13
	crtmod_param_1	   256,   256,   3,  13  ; LCD 14
	crtmod_param_1	   256,   256,   3,  14  ; LCD 15
	crtmod_param_1	   768,   512,   4,  15  ; LCD 16
	crtmod_param_1	   768,   600,   4,  16  ; LCD 17
	crtmod_param_1	   768,  1024,   4,  17  ; LCD 18
	crtmod_param_1	   640,   480,   4,  18  ; LCD 19
	crtmod_param_1	   768,   512,   1,  15  ; LCD 20
	crtmod_param_1	   768,   600,   1,  16  ; LCD 21
	crtmod_param_1	   768,  1024,   1,  17  ; LCD 22
	crtmod_param_1	   640,   480,   1,  18  ; LCD 23
	crtmod_param_1	   768,   512,   3,  15  ; LCD 24
	crtmod_param_1	   768,   600,   3,  16  ; LCD 25
	crtmod_param_1	   768,  1024,   3,  17  ; LCD 26
	crtmod_param_1	   640,   480,   3,  18  ; LCD 27
	crtmod_param_1	   384,   256,   4,  19  ; LCD 28
	crtmod_param_1	   384,   256,   0,  19  ; LCD 29
	crtmod_param_1	   384,   256,   1,  19  ; LCD 30
	crtmod_param_1	   384,   256,   3,  19  ; LCD 31
	crtmod_param_1	   512,   512,   4,  20  ; LCD 32
	crtmod_param_1	   512,   512,   0,  20  ; LCD 33
	crtmod_param_1	   512,   512,   1,  20  ; LCD 34
	crtmod_param_1	   512,   512,   3,  20  ; LCD 35
	crtmod_param_1	   256,   256,   4,  21  ; LCD 36
	crtmod_param_1	   256,   256,   0,  21  ; LCD 37
	crtmod_param_1	   256,   256,   1,  21  ; LCD 38
	crtmod_param_1	   256,   256,   3,  21  ; LCD 39
	crtmod_param_1	   512,   256,   4,  23  ; LCD 40
	crtmod_param_1	   512,   256,   0,  23  ; LCD 41
	crtmod_param_1	   512,   256,   1,  23  ; LCD 42
	crtmod_param_1	   512,   256,   3,  23  ; LCD 43
	crtmod_param_1	   512,   256,   4,  23  ; LCD 44
	crtmod_param_1	   512,   256,   0,  23  ; LCD 45
	crtmod_param_1	   512,   256,   1,  23  ; LCD 46
	crtmod_param_1	   512,   256,   3,  23  ; LCD 47

;�p�����[�^2
crtmod_table_2:
;			   R20L  HRL    HT   HS   HB   HD   HF    VT   VS   VB   VD   VF   R08    2ND  1ST
	crtmod_param_2	 %10101,   0,   92,  10,  12,  64,   6,  568,   6,  35, 512,  15,   27  ;   0  CRT 0/4/8/12
	crtmod_param_2	 %00101,   0,   76,   4,   6,  64,   2,  260,   3,  14, 240,   3,   44  ;   1  CRT 1/5/9/13
	crtmod_param_2	 %10000,   0,   46,   5,   6,  32,   3,  568,   6,  35, 512,  15,   27  ;   2  CRT 2/6/10/14
	crtmod_param_2	 %00000,   0,   38,   2,   3,  32,   1,  260,   3,  14, 240,   3,   36  ;   3  CRT 3/7/11/15
	crtmod_param_2	 %10110,   0,  138,  15,  18,  96,   9,  568,   6,  35, 512,  15,   27  ;   4  CRT 16/20/24
	crtmod_param_2	 %10110,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   5  CRT 17/21/25
	crtmod_param_2	 %11010,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   6  CRT 18/22/26
	crtmod_param_2	 %10110,   0,  138,  15,  26,  80,  17,  568,   6,  51, 480,  31,   27  ;   7  CRT 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
	crtmod_param_2	 %10110,   0,  138,  15,  34,  64,  25,  568,   6,  35, 512,  15,   27  ;   9  CRT 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  568,   6,  35, 512,  15,   27  ;  10  CRT 36/37/38/39
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  66, 512,  45,   27  ;  11  LCD 0/4/8/12
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  82, 480,  61,   27  ;  12  LCD 1/5/9/13
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  66, 512,  45,   27  ;  13  LCD 2/6/10/14
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  82, 480,  61,   27  ;  14  LCD 3/7/11/15
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  15  LCD 16/20/24
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  22, 600,   1,   27  ;  16  LCD 17/21/25
	crtmod_param_2	 %11010,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  17  LCD 18/22/26
	crtmod_param_2	 %10111,   0,  100,  12,   6,  80,   2,  525,   2,  33, 480,  10,   27  ;  18  LCD 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  625,   2,  66, 512,  45,   27  ;  19  LCD 28/29/30/31
	crtmod_param_2	 %10110,   0,  124,   9,  31,  64,  20,  625,   2,  66, 512,  45,   27  ;  20  LCD 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  625,   2,  66, 512,  45,   27  ;  21  LCD 36/37/38/39
	crtmod_param_2	 %10001,   0,   92,  10,  12,  64,   6,  568,   6,  35, 512,  15,   27  ;  22  CRT 40/41/42/43/44/45/46/47
	crtmod_param_2	 %10001,   0,   82,   6,  10,  64,   2,  625,   2,  66, 512,  45,   27  ;  23  LCD 40/41/42/43/44/45/46/47

;R20L<<1|HRL���h�b�g�N���b�N�̃����N
;	rank	R20L	HRL	osc	div	dotclk	mode
;	7	1**10	*	69.552	2	34.776	768x512(��)
;	6	1**11	*	50.350	2	25.175	640x480
;	5	1**01	0	69.552	3	23.184	512x512(��)
;	4	1**01	1	69.552	4	17.388	384x256
;	3	1**00	0	69.552	6	11.592	256x256(��)
;	2	0**01	*	38.864	4	9.716	512x512(��)
;	1	1**00	1	69.552	8	8.694
;	0	0**00	*	38.864	8	4.858	256x256(��)
;	0	0**1*	*	38.864	8	4.858
dot_clock_rank:
  .rept 4
	.dc.b	0	;0**00 0
	.dc.b	0	;0**00 1
	.dc.b	2	;0**01 0
	.dc.b	2	;0**01 1
	.dc.b	0	;0**10 0
	.dc.b	0	;0**10 1
	.dc.b	0	;0**11 0
	.dc.b	0	;0**11 1
  .endm
  .rept 4
	.dc.b	3	;1**00 0
	.dc.b	1	;1**00 1
	.dc.b	5	;1**01 0
	.dc.b	4	;1**01 1
	.dc.b	7	;1**10 0
	.dc.b	7	;1**10 1
	.dc.b	6	;1**11 0
	.dc.b	6	;1**11 1
  .endm

  .endif  ;REMOVE_CRTMOD_G_CLR_ON



;----------------------------------------------------------------
;	6x12 ANK�t�H���g
;		X68000��CGROM��IPLROM 1.3��g�ݍ��킹���6x12 ANK�t�H���g��\���ł��Ȃ�
;		IPLROM 1.6��6x12 ANK�t�H���g��$00FEF400�`$00FEFFFF(3072�o�C�g)�ɒu��
;	�ύX�O
;		000073F6 203C00FBF400     	move.l	#$00FBF400,d0
;----------------------------------------------------------------
	PATCH_DATA	p73F6,$00FF73F6,$00FF73F6+5,$203C00FB
		move.l	#$00FEF400,d0



;----------------------------------------------------------------
;	IOCS _SET232C
;	�{�[���[�g8=19200bps���g����悤�ɂ���
;		IPLROM 1.3��IOCS _SET232C�̓{�[���[�g8=19200bps��I���ł��邪�ASCC WR13:WR12�̒l���Ԉ���Ă���A
;		�X�^�[�g�r�b�g�œ������Ă��X�g�b�v�r�b�g�܂łɂ��悻1�r�b�g����Ă��܂��̂Ŏg���Ȃ�����
;		(5000000/2/16)/19200-2=6.138
;		(5000000/2/16)/(7+2)=17361.111=19200*0.904  ��
;		(5000000/2/16)/(6+2)=19531.250=19200*1.017  ��
;	�{�[���[�g9=38400bps��10=76800bps��I���ł���悤�ɂ���
;		�g����Ƃ͌���Ȃ�
;		RTS/CTS�ɑΉ����Ă��Ȃ��̂Ŏ��p���͕s��
;		SCC�̓�����g����7.5MHz�̂Ƃ�9=57600bps��10=115200bps�ɂȂ�
;	RTS/CTS�̑I�����m���ɖ�������
;		RTS/CTS�ɂ͑Ή����Ă��Ȃ����I������Ă��邾���Ń{�[���[�g4=1200bps�ɂȂ��Ă��܂���肪������
;
;					�ύX�O				�ύX��
;		00FF7A1A 4240		clr.w	d0			=
;		00FF7A1C 1001		move.b	d1,d0			=
;	A	00FF7A1E B03C		cmp.b	#$09,d0			movea.l	d1,a0
;		00FF7A20 0009						and.b	#$7F,d1
;		00FF7A22 6504		bcs	$00FF7A28
;		00FF7A24 303C		move.w	#$0004,d0		cmp.b	#11,d1
;		00FF7A26 0004
;		00FF7A28 D040		add.w	d0,d0			blo	$00FF7A2C
;		00FF7A2A 41FA		lea.l	$00FF7AE2(pc),a0	moveq.l	#4,d1
;		00FF7A2C 00B6						bsr.w	$00FF7AE2
;		00FF7A2E 3030		move.w	$00(a0,d0.w),d0
;		00FF7A30 0000						move.l	a0,d1
;		00FF7A32
;	B	00FF7AE2 0821		.dc.w	$0821			move.w	#2083,d0
;		00FF7AE4 0410		.dc.w	$0410
;		00FF7AE6 0207		.dc.w	$0207			lsr.w	d1,d0
;		00FF7AE8 0102		.dc.w	$0102			moveq.l	#-2,d1
;		00FF7AEA 0080		.dc.w	$0080			addx.w	d1,d0
;		00FF7AEC 003F		.dc.w	$003F			rts
;		00FF7AEE 001F		.dc.w	$001F			=
;		00FF7AF0 000E		.dc.w	$000E			=
;		00FF7AF2 0007		.dc.w	$0007	;6��������	=
;		00FF7AF4
;----------------------------------------------------------------
	PATCH_DATA	p7a1e,$00FF7A1E,$00FF7A31,$B03C0009
;A
;<d1.b:�{�[���[�g�̔ԍ�
;	0=75bps,1=150bps,2=300bps,3=600bps,4=1200bps,5=2400bps,6=4800bps,7=9600bps,8=19200bps,9=38400bps,10=76800bps
	movea.l	d1,a0			;d1��ۑ�����
	and.b	#$7F,d1			;RTS/CTS�̑I�����m���ɖ�������
	if	<cmp.b #11,d1>,hs	;�{�[���[�g�̔ԍ���0�`10�͈̔͊O�̂Ƃ�
		moveq.l	#4,d1			;�{�[���[�g4=1200bps�ɂ���
	endif
	bsr.w	($00FF7AE2)PATCH_ZL	;B���Ăяo��
	move.l	a0,d1			;d1�𕜌�����
;<d0.w:SCC WR13:WR12�̒l

	PATCH_DATA	p7ae2,$00FF7AE2,$00FF7AED,$08210410
;B
	move.w	#2083,d0		;(5000000Hz/2/16)/75bps=2083.333��
	lsr.w	d1,d0			;�{�[���[�g�̔ԍ��̕������E�ɃV�t�g����
	moveq.l	#-2,d1			;2��������
	addx.w	d1,d0			;�l�̌ܓ�����
	rts				;0��2081,1��1040,2��519,3��258,4��128,5��63,6��31,7��14,8��6,9��2,10��0



;----------------------------------------------------------------
;	DMA�]���J�n���O�̃L���b�V���t���b�V��
;	�ύX�O
;		00FF8284 2F00                   move.l	d0,-(sp)
;		00FF8286 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;		00FF828C 6314                   bls.s	$00FF82A2
;		00FF828E 4E7A0002               movec.l	cacr,d0
;		00FF8292 807C0808               or.w	#$0808,d0
;		00FF8296 4E7B0002               movec.l	d0,cacr
;		00FF829A C07CF7F7               and.w	#$F7F7,d0
;		00FF829E 4E7B0002               movec.l	d0,cacr
;		00FF82A2 201F                   move.l	(sp)+,d0
;		00FF82A4 4E75                   rts
;		00FF82A6
;----------------------------------------------------------------
	PATCH_DATA	dma_cache_flush,$00FF8284,$00FF82A5,$2F000C38
	jmp	cache_flush



;----------------------------------------------------------------
;	���荞�݊֌W��IOCS�R�[���̃n�C�������΍�
;		���荞�݊֌W��IOCS�R�[���͊��荞�݂����g�p���ǂ������x�N�^��$01000000�ȏォ�ǂ����Ŕ��f���Ă���
;		�x�N�^���n�C���������w���Ă���Ɩ��g�p�ƌ�F����
;		�x�N�^�̏��8bit���x�N�^�ԍ��ƈ�v���Ă��邩�ǂ����ɕύX����
;		�ȉ���IOCS�R�[�����Y������
;			$43	iocs_6A_OPMINTST
;			$44	iocs_6B_TIMERDST
;			$4D	iocs_6C_VDISPST
;			$4E	iocs_6D_CRTCRAS
;			$4F	iocs_6E_HSYNCST
;			$63	iocs_6F_PRNINTST
;	�ύX�O
;		00FF85D4 007C0700         	ori.w	#$0700,sr		;���荞�݋֎~
;		00FF85D8 E548             	lsl.w	#2,d0			;�x�N�^�I�t�Z�b�g
;		00FF85DA 3040             	movea.w	d0,a0			;a0.l:�x�N�^�I�t�Z�b�g
;		00FF85DC 2009             	move.l	a1,d0			;�ύX��̃x�N�^
;		00FF85DE 670C_000085EC    	beq.s	$00FF85EC		;����
;		00FF85E0 2010             	move.l	(a0),d0			;d0.l:�ύX�O�̃x�N�^
;	>>>>>	00FF85E2 0C8001000000     	cmpi.l	#$01000000,d0		;�ύX�O�̃x�N�^�Ƀx�N�^�ԍ����t���Ă��邩
;		00FF85E8 6504_000085EE    	bcs.s	$00FF85EE		;�ύX�O�̃x�N�^�Ƀx�N�^�ԍ����t���Ă��Ȃ��̂Ŏg�p��
;		00FF85EA                  ;�ύX�O�̃x�N�^�Ƀx�N�^�ԍ����t���Ă���̂Ŗ��g�p
;		00FF85EA 2089             	move.l	a1,(a0)			;�x�N�^��ύX����
;		00FF85EC 4E75             	rts				;�X��IOCS�R�[���֖߂�
;		00FF85EE                  ;�ύX�O�̃x�N�^�Ƀx�N�^�ԍ����t���Ă��Ȃ��̂Ŏg�p��
;		00FF85EE 4A9F             	tst.l	(sp)+			;�X��IOCS�R�[���֖߂�Ȃ�
;		00FF85F0                  ;�g�p���̂Ƃ�TRAP#15��rte�܂Ŋ��荞�݋֎~�̂܂܂ɂȂ�
;		00FF85F0 4E75             	rts				;IOCS�R�[�����畜�A����
;		00FF85F2
;		
;----------------------------------------------------------------
	PATCH_DATA	p85E2,$00FF85E2,$00FF85E7,$0C800100
	jsr	p85E2
	PATCH_TEXT
;<d0.l:�ύX�O�̃x�N�^
;<a0.l:�x�N�^�I�t�Z�b�g
;>c:cc=���g�p,cs=�g�p��
p85E2:
	push	d0-d1
	move.w	a0,d1			;d1.w:�x�N�^�I�t�Z�b�g
	lsr.w	#2,d1			;d1.b:�x�N�^�ԍ�
	rol.l	#8,d0			;d0.b:�ύX�O�̃x�N�^�̏��8bit
	cmp.b	d1,d0			;eq=���g�p,ne=�g�p��
	sne.b	d0			;d1.b:$00=���g�p,$FF=�g�p��
	add.b	d0,d0			;cc=���g�p,cs=�g�p��
	pop
	rts



;----------------------------------------------------------------
;	�s�
;		_MS_LIMIT��Y�����͈̔͂�1007�܂ł����ݒ�ł��Ȃ�
;		https://stdkmd.net/bugsx68k/#rom_mslimit
;	�ύX�O
;		00FFABA4 B27C03F0               cmp.w	#$03F0,d1
;		00FFABA8
;----------------------------------------------------------------
	PATCH_DATA	mslimit_1st,$00FFABA4,$00FFABA7,$B27C03F0
	cmp.w	#$0400,d1
;----------------------------------------------------------------
;	�ύX�O
;		00FFABB4 B47C03F0               cmp.w	#$03F0,d2
;		00FFABB8
;----------------------------------------------------------------
	PATCH_DATA	mslimit_2nd,$00FFABB4,$00FFABB7,$B47C03F0
	cmp.w	#$0400,d2



;----------------------------------------------------------------
;	_MS_ONTM�̃L���b�V������
;	�ύX�O
;		00FFAC72 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;		00FFAC78 630C                   bls.s	$00FFAC86
;		00FFAC7A 4E7A0002               movec.l	cacr,d0
;		00FFAC7E 2F00                   move.l	d0,-(sp)
;		00FFAC80 7001                   moveq.l	#$01,d0			;EI=1,ED=0
;		00FFAC82 4E7B0002               movec.l	d0,cacr
;		00FFAC86
;----------------------------------------------------------------
	PATCH_DATA	ms_ontm_cache_1st,$00FFAC72,$00FFAC85,$0C380001
	jsr	cache_on_i	;�f�[�^�L���b�V��OFF,���߃L���b�V��ON
	move.l	d0,-(sp)
	bra	($00FFAC86)PATCH_ZL
;----------------------------------------------------------------
;	�ύX�O
;		00FFACE8 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;		00FFACEE 6306                   bls.s	$00FFACF6
;		00FFACF0 201F                   move.l	(sp)+,d0
;		00FFACF2 4E7B0002               movec.l	d0,cacr
;		00FFACF6
;----------------------------------------------------------------
	PATCH_DATA	ms_ontm_cache_2nd,$00FFACE8,$00FFACF5,$0C380001
	move.l	(sp)+,d2
	jsr	cache_set	;�L���b�V���ݒ�
	bra	($00FFACF6)PATCH_ZL



  .if REMOVE_CRTMOD_G_CLR_ON=0

;----------------------------------------------------------------
;	_G_CLR_ON
;	�ύX�O
;		0000B326*48E76040         	movem.l	~pushrl,-(sp)
;			:
;		0000B660*FFFE             	.dc.w	(31<<11)|(31<<6)|(31<<1)
;----------------------------------------------------------------
	PATCH_DATA	g_clr_on,$00FFB326,$00FFB331,$48E76040
	jmp	iocs_90_G_CLR_ON
	PATCH_TEXT
;----------------------------------------------------------------
;IOCS�R�[��$90 _G_CLR_ON �O���t�B�b�N��ʂ̏����ƃp���b�g�������ƕ\��ON
;�p�����[�^�Ȃ�
	.text
	.even
iocs_90_G_CLR_ON:
dMM	reg	d3			;���������[�h
aE8	reg	a2			;(�`)E8�̃x�[�X�A�h���X
aED	reg	a4			;(�`)ED�̃x�[�X�A�h���X
aP1	reg	a5			;�p�����[�^1�̃A�h���X
	push	d0-d1/dMM/a0/aE8/aED/aP1

;(�`)E8�ŃA�N�Z�X����
;	$00E80000	CRTC
;	$00E82000	VICON
;	$00E84000	DMAC
;	$00E86000	SUPERAREA
;	$00E88000	MFP
;	$00E8A000	RTC
;	$00E8C000	PRNPORT
;	$00E8E000	SYSPORT
	lea.l	$00E88000,aE8
E8	reg	-$00E88000(aE8)

;(�`)ED�ŃA�N�Z�X����
;	$00ED0000	SRAM
	lea.l	$00ED8000,aED
ED	reg	-$00ED8000(aED)

;���݂̉�ʃ��[�h���m�F����
	moveq.l	#0,d1
	move.b	BIOS_CRTMOD.w,d1	;���݂̉�ʃ��[�h
	if	<cmp.w #crtmod_modes,d1>,hs	;���݂̉�ʃ��[�h���͈͊O�̂Ƃ�
		move.b	(SRAM_CRTMOD)ED,d1		;�N�����̉�ʃ��[�h���g��
		if	<cmp.w #crtmod_modes,d1>,hs	;�N�����̉�ʃ��[�h���͈͊O�̂Ƃ�
			moveq.l	#16,d1			;16���g��
  .if 0
			move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
			move.b	d1,(SRAM_CRTMOD)ED
			clr.b	(SYSPORT_SRAM)E8	;locksram
  .endif
		endif
	endif

;<d1.l:��ʃ��[�h

;�p�����[�^1�̃A�h���X�����߂�
	lea.l	crtmod_table_1_crt(pc),aP1
	if	<btst.b #SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED>,ne	;LCD����
		lea.l	crtmod_table_1_lcd(pc),aP1
	endif
	move.w	d1,d0
  .if crtmod_param_1_size=8
	lsl.w	#3,d0
  .else
	mulu.w	#crtmod_param_1_size,d0
  .endif
	adda.w	d0,aP1
;<aP1.l:�p�����[�^1�̃A�h���X

;���������[�h���m�F����
	moveq.l	#7,dMM
	and.b	crtmod_param_1_r20h(aP1),dMM	;���������[�h�B0�`7
;<dMM.w:���������[�h�B0�`7

;�e�L�X�g��ʂ̂�ON
	move.w	#VICON_TXON_MASK,(VICON_VISIBLE)E8

;�O���t�B�b�N�X�g���[�WON
	bset.b	#CRTC_GRAPHIC_STORAGE_BIT,(CRTC_MODE_BYTE)E8	;�O���t�B�b�N�X�g���[�WON

;�O���t�B�b�NVRAM���N���A����
	lea.l	$00C00000,a0
	moveq.l	#0,d0
	moveq.l	#-1,d1			;1024*512/8=65536��
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;�O���t�B�b�N�X�g���[�WOFF
;���������[�h��ݒ肷��
	move.b	dMM,(CRTC_MODE_BYTE)E8
	move.w	dMM,(VICON_MEMORY_MODE)E8

;BIOS���[�N�G���A������������
	move.l	#$00C00000,BIOS_GRAPHIC_PAGE.w
	if	<cmp.w #4,dMM>,lo	;���������[�h0�`3�B512x512�h�b�g
		move.l	#2*512,BIOS_GRAPHIC_Y_OFFSET.w
		if	<cmp.w #1,dMM>,lo	;���������[�h0�B512x512�h�b�g�A16�F�A4�y�[�W
			move.w	#16-1,BIOS_GRAPHIC_PALETS.w
		elif	eq			;���������[�h1�B512x512�h�b�g�A256�F�A2�y�[�W
			move.w	#256-1,BIOS_GRAPHIC_PALETS.w
		else				;���������[�h2�`3�B512x512�h�b�g�A65536�F�A1�y�[�W
			move.w	#65536-1,BIOS_GRAPHIC_PALETS.w
		endif
	else					;���������[�h4�`7�B1024x1024�h�b�g�A16�F�A1�y�[�W
		move.l	#2*1024,BIOS_GRAPHIC_Y_OFFSET.w
		move.w	#16-1,BIOS_GRAPHIC_PALETS.w
	endif

;�O���t�B�b�N�p���b�g������������
	move.w	dMM,d0
	bsr	initialize_gpalet

;�e�L�X�g���ON�A�O���t�B�b�N���ON
;	if	<cmp.w #4,dMM>,lo	;���������[�h0�`3�B512x512�h�b�g
;		move.w	#VICON_TXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,(VICON_VISIBLE)E8
;	else				;���������[�h4�`7�B1024x1024�h�b�g
;		move.w	#VICON_TXON_MASK|VICON_GXON_MASK,(VICON_VISIBLE)E8
;	endif
;	IPLROM 1.0�`1.3��1024x1024�h�b�g��512x512�h�b�g�𗼕�ON�ɂ��Ă���
	move.w	#VICON_TXON_MASK|VICON_GXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,(VICON_VISIBLE)E8

	pop
	rts

;----------------------------------------------------------------
;�O���t�B�b�N�p���b�g������������
;<d0.w:���������[�h�B0�`7
	.text
	.even
initialize_gpalet:
	push	d0-d4/a0-a1
	lea.l	VICON_GPALET,a0
	ifor	<tst.w d0>,eq,<cmp.w #4,d0>,hs	;���������[�h0�B512x512�h�b�g�A16�F�A4�y�[�W
						;���������[�h4�`7�B1024x1024�h�b�g�A16�F�A1�y�[�W
		lea.l	gpalet_16_array(pc),a1
		moveq.l	#16/2-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
	elif	<cmp.w #1,d0>,eq	;���������[�h1�B512x512�h�b�g�A256�F�A2�y�[�W
		move.l	#%0000000000010010_0000000000010010,d1
		moveq.l	#%0000000000000000_0000000000000000,d4
		do
			moveq.l	#%0000000000000000_0000000000001000,d3
			moveq.l	#8-1,d2
			for	d2
				move.l	d4,d0
				and.l	#%1111101111111111_1111101111111111,d0
				or.l	d3,d0
				and.l	#%1111111111011111_1111111111011111,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	#%0000000100100000_0000000100100000,d3
			next
			add.l	#%0101010000000000_0101010000000000,d4
		while	cc
	else				;���������[�h2�`3�B512x512�h�b�g�A65536�F�A1�y�[�W
		move.l	#$00_01_00_01,d0
		move.l	#$02_02_02_02,d1
		moveq.l	#256/2-1,d2
		for	d2
			move.l	d0,(a0)+
			add.l	d1,d0
		next
	endif
	pop
	rts

;�O���t�B�b�N16�F�p���b�g
gpalet_16_array:
	dcrgb	0,0,0
	dcrgb	10,10,10
	dcrgb	0,0,16
	dcrgb	0,0,31
	dcrgb	16,0,0
	dcrgb	31,0,0
	dcrgb	16,0,16
	dcrgb	31,0,31
	dcrgb	0,16,0
	dcrgb	0,31,0
	dcrgb	0,16,16
	dcrgb	0,31,31
	dcrgb	16,16,0
	dcrgb	31,31,0
	dcrgb	21,21,21
	dcrgb	31,31,31

;----------------------------------------------------------------
;50us�P�ʂ̃E�F�C�g
;<d0.l:����(50us�P��)
	.text
	.even
wait_50us:
  .if 0
;Timer-C���g��
;	Timer-C��1/200�v���X�P�[��(50us)�œ��삵�Ă��Ȃ���΂Ȃ�Ȃ�
aTCDR	reg	a0
	push	d0-d2/aTCDR
	lea.l	MFP_TCDR,aTCDR
	moveq.l	#0,d1
	move.b	(aTCDR),d1
	move.b	(aTCDR),d1
	do
		moveq.l	#0,d2
		move.b	(aTCDR),d2
		redo	<cmp.b (aTCDR),d2>,cs
		sub.w	d2,d1
		if	cs
			add.w	#200,d1
		endif
		exg.l	d1,d2
		sub.l	d2,d0
	while	hi
	pop
	rts
  .else
;dbra�󃋁[�v���g��
;	BIOS_MPU_SPEED_ROM.w��BIOS_MPU_TYPE.w���ݒ肳��Ă��Ȃ���΂Ȃ�Ȃ�
	push	d0-d3
	subq.l	#1,d0
	if	cc
		move.l	BIOS_MPU_SPEED_ROM_LONG.w,d1
		if	eq
			move.w	BIOS_MPU_SPEED_ROM.w,d1
		endif
	;	�����20bit�Ƃ���50us�������dbra�̉񐔂����߂�
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;000/010/020/030
			move.w	#205,d2			;2**12*50/1000=204.8
		elif	eq			;040
			move.w	#307,d2			;2**12*50/1000*6/4=307.2
		else				;060
			move.w	#1229,d2		;2**12*50/1000*6/1=1228.8
		endif
		move.l	d1,d3			;d3=H|L
		swap.w	d3			;d3=L|H
		mulu.w	d2,d3			;d3=c*H
		mulu.w	d2,d1			;d1=c*L
		swap.w	d3
		clr.w	d3			;d3=c*H|0
		add.l	d3,d1			;d1=c*(H|L)
		and.w	#$F000,d1		;43210___
		rol.l	#4,d1			;3210___4
		swap.w	d1			;___43210  50us�������dbra�̉�
		subq.l	#1,d1
		move.l	d1,d2
		forlong	d0
			move.l	d2,d1
			.align	16,$2048
			forlong	d1
			next
		next
	endif
	pop
	rts
  .endif

  .endif  ;REMOVE_CRTMOD_G_CLR_ON



;----------------------------------------------------------------
;	�s�
;		_GPALET��65536�F���[�h�̃p���b�g�𐳂����擾�ł��Ȃ�
;		https://stdkmd.net/bugsx68k/#rom_gpalet
;	�ύX�O
;		00FFB740 16300000               move.b	$00(a0,d0.w),d3
;		00FFB744
;----------------------------------------------------------------
	PATCH_DATA	gpalet,$00FFB740,$00FFB743,$16300000
	move.b	2(a0,d0.w),d3



;----------------------------------------------------------------
;	�s�
;		_SYS_STAT�̃R�[�h���Ԉ���Ă���
;		https://stdkmd.net/bugsx68k/#rom_sysstat
;	�ύX�O
;		00FFC75A 48E76000               movem.l	d1-d2,-(sp)
;			:
;		00FFC818
;----------------------------------------------------------------
	PATCH_DATA	sysstat,$00FFC75A,$00FFC817,$48E76000
	jmp	iocs_AC_SYS_STAT

;�]�����̈��trap#14�Ŏg��
trap14_message:
200:
	.dc.w	204f-200b
	.dc.w	205f-200b
	.dc.w	206f-200b
	.dc.w	207f-200b
	.dc.w	208f-200b
	.dc.w	209f-200b
	.dc.w	210f-200b
	.dc.w	211f-200b
204:	.dc.b	'Illegal instruction',0
205:	.dc.b	'Zero divide',0
206:	.dc.b	'CHK instruction',0
207:	.dc.b	'TRAPV instruction',0
208:	.dc.b	'Privilege violation',0
209:	.dc.b	'Trace',0
210:	.dc.b	'Line 1010 emulator',0
211:	.dc.b	'Line 1111 emulator',0
	.even

	PATCH_TEXT
;----------------------------------------------------------------
;IOCS�R�[��$AC _SYS_STAT �V�X�e�����̎擾�Ɛݒ�
;<d1.w:���[�h
;	0	MPU�X�e�[�^�X�擾
;		>d0.l:MPU�X�e�[�^�X
;			bit31-16	MPU�̓�����g���BMHz�l*10
;			bit15		FPU/FPCP�̗L���B0=�Ȃ�,1=����
;			bit14		MMU�̗L���B0=�Ȃ�,1=����
;			bit7-0		MPU�̎�ށB0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
;	1	�L���b�V���擾
;		>d0.l:���݂̃L���b�V���̏��
;			bit1	�f�[�^�L���b�V����0=OFF,1=ON
;			bit0	���߃L���b�V����0=OFF,1=ON
;	2	�L���b�V���ݒ�(SRAM�ݒ�l)
;		>d0.l:�ݒ��̃L���b�V���̏��
;			bit1	�f�[�^�L���b�V����0=OFF,1=ON�ɂ���
;			bit0	���߃L���b�V����0=OFF,1=ON�ɂ���
;	3	�L���b�V���t���b�V��
;	4	�L���b�V���ݒ�
;		<d2.l:�ݒ��̃L���b�V���̏��
;			bit1	�f�[�^�L���b�V����0=OFF,1=ON�ɂ���
;			bit0	���߃L���b�V����0=OFF,1=ON�ɂ���
;		>d0.l:�ݒ�O�̃L���b�V���̏��
;			bit1	�f�[�^�L���b�V����0=OFF,1=ON������
;			bit0	���߃L���b�V����0=OFF,1=ON������
iocs_AC_SYS_STAT:
	moveq.l	#-1,d0
	ifor	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs,<tst.w d1>,eq	;000/010�̓��[�h0�ȊO�̓G���[
		if	<cmp.w #5,d1>,lo		;���[�h5�ȏ�̓G���[
			push	d1
			add.w	d1,d1
			move.w	100f(pc,d1.w),d1
			jsr	100f(pc,d1.w)
			pop
		endif
	endif
	rts

100:
	.dc.w	mpu_status-100b		;0 MPU�X�e�[�^�X�擾
	.dc.w	cache_get-100b		;1 �L���b�V���擾
	.dc.w	cache_default-100b	;2 �L���b�V���ݒ�(SRAM�ݒ�l)
	.dc.w	cache_flush-100b	;3 �L���b�V���t���b�V��
	.dc.w	cache_set-100b		;4 �L���b�V���ݒ�

;----------------------------------------------------------------
;MPU�X�e�[�^�X�擾
;>d0.l:MPU�X�e�[�^�X
;	bit31-16	MPU�̓�����g���BMHz�l*10
;	bit15		FPU/FPCP�̗L���B0=�Ȃ�,1=����
;	bit14		MMU�̗L���B0=�Ȃ�,1=����
;	bit7-0		MPU�̎�ށB0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
mpu_status:
	move.l	BIOS_MPU_SPEED_ROM_LONG.w,d0
;	if	eq			;IPLROM 1.6�ȊO�Ŏg���Ƃ��K�v
;		move.w	BIOS_MPU_SPEED_ROM.w,d0
;	endif
	move.l	d0,-(sp)		;x1
	add.l	d0,d0			;x2
	add.l	(sp)+,d0		;x3
	add.l	d0,d0			;x6
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,lo	;68000/68010
		add.l	d0,d0			;x12
	endif
	add.l	#50,d0
	divu.w	#100,d0			;MHz�l*10
;	if	vs			;6553.6MHz�ȏ�
;		moveq.l	#-1,d0
;	endif
	swap.w	d0			;ssssssss ssssssss ........ ........
	clr.w	d0			;ssssssss ssssssss 00000000 00000000
	tst.b	BIOS_MMU_TYPE.w
	sne.b	d0			;ssssssss ssssssss 00000000 mmmmmmmm
	ror.w	#1,d0			;ssssssss ssssssss m0000000 0mmmmmmm
	tst.b	BIOS_FPU_TYPE.w
	sne.b	d0			;ssssssss ssssssss m0000000 ffffffff
	ror.w	#1,d0			;ssssssss ssssssss fm000000 0fffffff
	move.b	BIOS_MPU_TYPE.w,d0	;ssssssss ssssssss fm000000 pppppppp
	rts

;----------------------------------------------------------------
;�L���b�V���擾
;>d0.l:���݂̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON
;	bit0	���߃L���b�V����0=OFF,1=ON
;	000/010�̂Ƃ���0��Ԃ�
cache_get:
	moveq.l	#0,d0
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		.cpu	68030
		movec.l	cacr,d0
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
							;........ ........ .......d .......i
			ror.l	#1,d0			;i....... ........ ........ d.......
			rol.b	#1,d0			;i....... ........ ........ .......d
		else				;040/060
							;d....... ........ i....... ........
			swap.w	d0			;i....... ........ d....... ........
			rol.w	#1,d0			;i....... ........ ........ .......d
		endif
		rol.l	#1,d0			;........ ........ ........ ......di
		and.l	#3,d0			;00000000 00000000 00000000 000000di
		.cpu	68000
	endif
	rts

;----------------------------------------------------------------
;�L���b�V���ݒ�(SRAM�ݒ�l)
;>d0.l:�ݒ��̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON�ɂ���
;	bit0	���߃L���b�V����0=OFF,1=ON�ɂ���
;	000/010�̂Ƃ���0��Ԃ�
cache_default:
	push	d2
	moveq.l	#0,d2
	move.b	SRAM_CACHE,d2		;�L���b�V���ݒ�B------|�f�[�^|����
	bsr	cache_set		;�L���b�V���ݒ�
	pop
	rts

;----------------------------------------------------------------
;�L���b�V���t���b�V��
cache_flush:
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		.cpu	68030
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
			push	d0
			movec.l	cacr,d0
			or.w	#$0808,d0
			movec.l	d0,cacr
		;	and.w	#$F7F7,d0
		;	movec.l	d0,cacr
			pop
		else				;040/060
			.cpu	68040
			cpusha	bc
		endif
		.cpu	68000
	endif
	rts

;----------------------------------------------------------------
;�L���b�V���ݒ�
;<d2.l:�ݒ��̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON�ɂ���
;	bit0	���߃L���b�V����0=OFF,1=ON�ɂ���
;	000/010�̂Ƃ��͉������Ȃ�
;>d0.l:�ݒ�O�̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON������
;	bit0	���߃L���b�V����0=OFF,1=ON������
;	000/010�̂Ƃ���0��Ԃ�
cache_set:
	moveq.l	#0,d0
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		.cpu	68030
		push	d1-d3
		moveq.l	#3,d3			;d3 00000000 00000000 00000000 00000011
		and.l	d3,d2			;d2 00000000 00000000 00000000 000000di
		ror.l	#1,d2			;   i0000000 00000000 00000000 0000000d
		movec.l	cacr,d0
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
							;d0 ........ ........ .......d .......i
			neg.w	d2			;d2 i0000000 00000000 dddddddd dddddddd
			and.w	#$2101.shr.1,d2		;   i0000000 00000000 000d0000 d0000000
			rol.l	#1,d2			;   00000000 00000000 00d0000d 0000000i
			move.l	d0,d1			;d1 ........ ........ .......d .......i
			and.w	#.notw.$2101,d1		;   ........ ........ ..0....0 .......0
			or.w	d2,d1			;   ........ ........ ..d....d .......i
			movec.l	d1,cacr
			ror.l	#1,d0			;d0 i....... ........ ........ d.......
			rol.b	#1,d0			;   i....... ........ ........ .......d
		else				;040/060
							;d0 d....... ........ i....... ........
			.cpu	68040
			ror.w	#1,d2			;d2 i0000000 00000000 d0000000 00000000
			swap.w	d2			;   d0000000 00000000 i0000000 00000000
			move.l	d0,d1			;d1 d....... ........ i....... ........
			and.l	#.not.$80008000,d1	;   0....... ........ 0....... ........
			or.l	d2,d1			;   d....... ........ i....... ........
			movec.l	d1,cacr
			not.l	d2
			and.l	d0,d2			;�ݒ�O&~�ݒ��
			if	mi			;�f�[�^�L���b�V����ON��OFF
				cpusha	dc			;�f�[�^�L���b�V�����v�b�V�����Ė�����
			endif
			if	<tst.w d2>,mi		;���߃L���b�V����ON��OFF
				cinva	ic			;���߃L���b�V���ƕ���L���b�V���𖳌���
			endif
			swap.w	d0			;d0 i....... ........ d....... ........
			rol.w	#1,d0			;   i....... ........ ........ .......d
		endif
		rol.l	#1,d0			;   ........ ........ ........ ......di
		and.l	d3,d0			;   00000000 00000000 00000000 000000di
		pop
		.cpu	68000
	endif
	rts

;----------------------------------------------------------------
;�L���b�V��OFF
;>d0.l:�ݒ�O�̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON������
;	bit0	���߃L���b�V����0=OFF,1=ON������
;	000/010�̂Ƃ���0��Ԃ�
cache_off:
	push	d2
	moveq.l	#0,d2
	bsr	cache_set		;�L���b�V���ݒ�
	pop
	rts

;----------------------------------------------------------------
;�f�[�^�L���b�V��OFF,���߃L���b�V��ON
;>d0.l:�ݒ�O�̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON������
;	bit0	���߃L���b�V����0=OFF,1=ON������
;	000/010�̂Ƃ���0��Ԃ�
cache_on_i:
	push	d2
	moveq.l	#1,d2			;�f�[�^�L���b�V��OFF,���߃L���b�V��ON
	bsr	cache_set		;�L���b�V���ݒ�
	pop
	rts



;----------------------------------------------------------------
;
;	_SP_INIT �Ńo�X�G���[���������� (IPLROM 1.0/1.1/1.2/1.3)
;	https://stdkmd.net/bugsx68k/#rom_spinit
;
;	�Ǐ�
;	�X�v���C�g��\���ł��Ȃ��Ƃ� _SP_INIT �� -1 ��Ԃ����o�X�G���[�Ŏ~�܂邱�Ƃ�����B
;
;	��������
;	��ʃ��[�h 18 (1024x848) �܂��͉�ʃ��[�h 19 (640x480; VGA ���[�h) �� _SP_INIT ���Ăяo�����Ƃ��B
;
;	����
;	�n�[�h�E�F�A�̐���ŁACRTC �� R20 ($00E80028) �̉��� 5 �r�b�g�� %1??1? �̂Ƃ��A�X�v���C�g��\���ł��Ȃ��B
;	�X�v���C�g��\���ł��Ȃ��Ƃ��A�X�v���C�g�X�N���[�����W�X�^ ($00EB0000�`$00EB07FF) �܂���
;	�X�v���C�g PCG�E�e�L�X�g�G���A ($00EB8000�`$00EBFFFF) �ɃA�N�Z�X����ƁA�o�X�G���[����������B
;	�X�v���C�g�֘A�� IOCS �R�[���́A��ʃ��[�h 16 (768x512) �Ɖ�ʃ��[�h 17 (1024x424) �� %10110 �̂Ƃ������A�X�v���C�g��\���ł��Ȃ��Ɣ��f����B
;	��ʃ��[�h 18 �� %11010 �Ɖ�ʃ��[�h 19 �� %10111 ���܂� %1001? �� %10111 �� %11?1? �̓X�v���C�g��\���ł���ƌ���Ĕ��f����A
;	_SP_INIT ���A�N�Z�X�ł��Ȃ��X�v���C�g�X�N���[�����W�X�^�����������悤�Ƃ��ăo�X�G���[����������B
;
;	�⑫
;	��ʃ��[�h 17 (1024x424) �Ɖ�ʃ��[�h 18 (1024x848) �� IPLROM 1.0 ���炠�邪�����J�B
;	��ʃ��[�h 19 (640x480; VGA ���[�h) �� X68000 Compact �� IPLROM 1.2 �Œǉ����ꂽ�B
;
;	����
;	���̃o�X�G���[�̓G�~�����[�^�ł͍Č�����Ȃ����Ƃ�����B
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;	�ύX�O
;		00FFCC9E 303900E80028           move.w	$00E80028,d0		;[$00E80028].w:CRTC R20 ���������[�h/�𑜓x(���𑜓x|�����𑜓x|�����𑜓x)
;		00FFCCA4 024000FF               andi.w	#$00FF,d0
;		00FFCCA8 0C400016               cmpi.w	#$0016,d0
;		00FFCCAC 6606                   bne.s	$00FFCCB4
;		00FFCCAE 70FF                   moveq.l	#$FF,d0
;		00FFCCB0 588F                   addq.l	#4,sp
;		00FFCCB2 4E75                   rts
;
;		00FFCCB4 7000                   moveq.l	#$00,d0
;		00FFCCB6 4E75                   rts
;
;		00FFCCB8
;----------------------------------------------------------------

	PATCH_DATA	spinit,$00FFCC9E,$00FFCCB7,$303900E8
;�X�v���C�g��\���ł��邩
;	�X�v���C�g�֘A��IOCS�R�[���̐擪�ŌĂяo�����
;	�\���ł��Ȃ��Ƃ���-1��Ԃ���IOCS�R�[�����畜�A����
;>d0.l:0=�X�v���C�g��\���ł���,-1=�X�v���C�g��\���ł��Ȃ�
	moveq.l	#%10010,d0
	and.w	$00E80028,d0		;CRTC R20
	if	<cmp.w #%10010,d0>,eq	;%1??1?�B�X�v���C�g��\���ł��Ȃ�
		moveq.l	#-1,d0			;�X�v���C�g��\���ł��Ȃ�
		addq.l	#4,sp			;IOCS�R�[�����畜�A����
	else				;���̑��B�X�v���C�g��\���ł���
		moveq.l	#0,d0			;�X�v���C�g��\���ł���
	endif
	rts



;----------------------------------------------------------------
;
;	�O���t�B�b�N�֌W��IOCS�R�[�������o�[�X���[�h�ɂȂ����܂܂ɂȂ�
;	https://stdkmd.net/bugsx68k/#rom_drawmode
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;	�ύX�O
;		00FFDCEA B07CFFFF               cmp.w	#$FFFF,d0
;		00FFDCEE
;----------------------------------------------------------------

	PATCH_DATA	drawmode,$00FFDCEA,$00FFDCED,$B07CFFFF
	cmp.w	#-1,d1



;----------------------------------------------------------------
;
;	�v���|�[�V���i���s�b�`�R���\�[��
;	���ǂƂ�����薂����
;	����͒x���A�ҏW�͍���ɂȂ�
;
;----------------------------------------------------------------

  .if USE_PROPORTIONAL_IOCS

	PATCH_DATA	timer_c_cursor,$00FF1D8C,$00FF1D91,$4A380992
	jmp	timer_c_cursor

	PATCH_DATA	iocs_1E_B_CURON,$00FF79CE,$00FF79D3,$4A380993
	jmp	iocs_1E_B_CURON

	PATCH_DATA	iocs_1F_B_CUROFF,$00FF79EA,$00FF79EF,$4A380993
	jmp	iocs_1F_B_CUROFF

	PATCH_DATA	iocs_20_B_PUTC,$00FF96AE,$00FF96B3,$2F016100
	jmp	iocs_20_B_PUTC

	PATCH_DATA	iocs_21_B_PRINT,$00FF96BC,$00FF96C3,$48E74020
	jmp	iocs_21_B_PRINT

	PATCH_DATA	iocs_22_B_COLOR,$00FF96D8,$00FF96DD,$700041F8
	jmp	iocs_22_B_COLOR

	PATCH_DATA	iocs_23_B_LOCATE,$00FF96F4,$00FF96FB,$20380974
	jmp	iocs_23_B_LOCATE

	PATCH_DATA	iocs_24_B_DOWN_S,$00FF9724,$00FF972B,$6100E2C4
	jmp	iocs_24_B_DOWN_S

	PATCH_DATA	iocs_25_B_UP_S,$00FF9730,$00FF9737,$6100E2B8
	jmp	iocs_25_B_UP_S

	PATCH_DATA	iocs_26_B_UP,$00FF973C,$00FF9741,$2F016100
	jmp	iocs_26_B_UP

	PATCH_DATA	iocs_27_B_DOWN,$00FF9748,$00FF974D,$2F016100
	jmp	iocs_27_B_DOWN

	PATCH_DATA	iocs_28_B_RIGHT,$00FF9754,$00FF9759,$2F016100
	jmp	iocs_28_B_RIGHT

	PATCH_DATA	iocs_29_B_LEFT,$00FF9760,$00FF9765,$2F016100
	jmp	iocs_29_B_LEFT

	PATCH_DATA	iocs_2A_B_CLR_ST,$00FF9772,$00FF9779,$48E77848
	jmp	iocs_2A_B_CLR_ST

	PATCH_DATA	iocs_2B_B_ERA_ST,$00FF9780,$00FF9787,$48E77848
	jmp	iocs_2B_B_ERA_ST

	PATCH_DATA	iocs_2C_B_INS,$00FF9796,$00FF979D,$48E77F78
	jmp	iocs_2C_B_INS

	PATCH_DATA	iocs_2D_B_DEL,$00FF97A4,$00FF97AB,$48E77F78
	jmp	iocs_2D_B_DEL

	PATCH_DATA	iocs_2E_B_CONSOL,$00FF97BA,$00FF97C1,$6100E22E
	jmp	iocs_2E_B_CONSOL

	PATCH_DATA	iocs_AE_OS_CURON,$00FFC87E,$00FFC883,$31F809BA
	jmp	iocs_AE_OS_CURON

	PATCH_DATA	iocs_AF_OS_CUROF,$00FFC8AC,$00FFC8B1,$4EB900FF
	jmp	iocs_AF_OS_CUROF

  .endif

	PATCH_TEXT



;�R���\�[���g��
BIOS_ATTRIBUTE_2	equ	$0D30		;.b ��������2�B-|��t��|���t��|���|�ۈ͂�|�l�p�͂�|�v���|�[�V���i��|�g��
BIOS_SUPERSCRIPT_BIT	equ	 6		;��t��
BIOS_SUPERSCRIPT	equ	%01000000
BIOS_SUBSCRIPT_BIT	equ	  5		;���t��
BIOS_SUBSCRIPT		equ	%00100000
BIOS_OVERLINE_BIT	equ	    4		;���
BIOS_OVERLINE		equ	%00010000
BIOS_ENCIRCLE_BIT	equ	     3		;�ۈ͂�
BIOS_ENCIRCLE		equ	%00001000
BIOS_FRAME_BIT		equ	      2		;�l�p�͂�
BIOS_FRAME		equ	%00000100
BIOS_PROPORTIONAL_BIT	equ	       1	;�v���|�[�V���i��
BIOS_PROPORTIONAL	equ	%00000010
BIOS_WAVELINE_BIT	equ	        0	;�g��
BIOS_WAVELINE		equ	%00000001
BIOS_CURSOR_FRACTION	equ	$0D31		;.b �J�[�\���̌����W�̒[���B0�`7
BIOS_SAVED_ATTRIBUTE_2	equ	$0D32		;.b ESC [s�ŕۑ����ꂽ��������2
BIOS_SAVED_FRACTION	equ	$0D33		;.b ESC [s�ŕۑ����ꂽ�J�[�\���̌����W�̒[��
BIOS_BUFFER_REQUEST	equ	$0D34		;.w �o�b�t�@�̕������\������̈�̃h�b�g���B0=�o�b�t�@�o�͒��ł͂Ȃ�
BIOS_BUFFER_WIDTH	equ	$0D36		;.w �o�b�t�@�̕�����̃h�b�g��
BIOS_BUFFER_POINTER	equ	$0D38		;.l �o�b�t�@�̏������݈ʒu
BIOS_BUFFER_ARRAY	equ	$0D3C		;.w[64] �o�b�t�@�B�E�񂹁A�����񂹂Ŏg��
BIOS_CONSOLE_STATUS	equ	$0DBC		;.b �R���\�[���̏�ԁB----|����|������|�E��|�A��
BIOS_ALIGN_LEFT_BIT	equ	     3		;����
BIOS_ALIGN_LEFT		equ	%00001000
BIOS_ALIGN_CENTER_BIT	equ	      2		;������
BIOS_ALIGN_CENTER	equ	%00000100
BIOS_ALIGN_RIGHT_BIT	equ	       1	;�E��
BIOS_ALIGN_RIGHT	equ	%00000010
BIOS_CONNECTION_BIT	equ	        0	;�A���B�Ō�ɕ`�悵�������͎Α̂ł��̌�J�[�\���𓮂����Ă��Ȃ��B�����Α̂Ȃ�΋l�߂ĕ`�悷��
BIOS_CONNECTION		equ	%00000001
;				$0DBD		;.b[3]

;----------------------------------------------------------------
;�J�[�\���_�ŏ������[�`��
;	Timer-C���荞�݃��[�`������500ms�Ԋu�ŌĂ΂��
timer_c_cursor:
	if	<tst.b BIOS_CURSOR_ON.w>,ne	;�J�[�\����\������Ƃ�
		ifor	<tst.w BIOS_CURSOR_NOT_BLINK.w>,eq,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;�_�ł����邩�A�`����Ă��Ȃ��Ƃ�
			if	<btst.b #1,CRTC_ACCESS>,eq	;CRTC�̃}�X�N���g�p���łȂ��Ƃ�
				bsr	toggle_cursor		;�J�[�\���𔽓]������
				not.b	BIOS_CURSOR_DRAWN.w	;�J�[�\�����`����Ă��邩�B0=�`����Ă��Ȃ�,-1=�`����Ă���
			endif
		endif
	endif
	rts

;----------------------------------------------------------------
;�J�[�\���𔽓]������
toggle_cursor:
	push	d0-d2/a0-a2
	move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
	swap.w	d0
	clr.w	d0			;65536*�s���W
	lsr.l	#5,d0			;128*16*�s���W
	move.w	BIOS_CURSOR_COLUMN.w,d1	;�J�[�\���̌����W
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d1	;�E�[�Ŏ~�܂�
	endif
	add.w	d1,d0
	add.l	BIOS_CONSOLE_OFFSET.w,d0
	add.l	#$00E00000,d0		;�J�[�\���̃A�h���X
	movea.l	d0,a2
	move.w	CRTC_ACCESS,-(sp)
	bclr.b	#0,CRTC_ACCESS		;�����A�N�Z�XOFF
***	move.w	BIOS_CURSOR_PATTERN.w,d1
***	if	eq
***		moveq.l	#-1,d1
***	endif
	moveq.l	#$80,d1
	move.b	BIOS_CURSOR_FRACTION.w,d0
	lsr.b	d0,d1
	bsr	toggle_cursor_1		;�v���[��0�𔽓]
***	lsr.w	#8,d1
	adda.l	#$00020000,a2
	bsr	toggle_cursor_1		;�v���[��1�𔽓]
	move.w	(sp)+,CRTC_ACCESS
	pop
	rts

toggle_cursor_1:
	move.w	BIOS_CURSOR_START.w,d2	;�J�[�\���`��J�n���C��*4
	jmp	@f(pc,d2.w)
@@:	eor.b	d1,(a2)
	movea.l	a0,a0			;nop
  .irp row,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	eor.b	d1,128*row(a2)
  .endm
	rts

;----------------------------------------------------------------
;IOCS�R�[��$1E _B_CURON �J�[�\����\������
iocs_1E_B_CURON:
	ifand	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq,<tst.b BIOS_CURSOR_ON.w>,eq	;������Ă��ĕ\�����Ă��Ȃ��Ƃ�
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;�^�C�}�J�E���^�B1��ڂ�10ms*5=50ms��ɔ���������
		st.b	BIOS_CURSOR_ON.w	;�\�����Ă���
		clr.b	BIOS_CURSOR_DRAWN.w	;�`����Ă��Ȃ�
	endif
	rts

;----------------------------------------------------------------
;IOCS�R�[��$1F _B_CUROFF �J�[�\����\�����Ȃ�
iocs_1F_B_CUROFF:
	if	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq	;������Ă���Ƃ�
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;�^�C�}�J�E���^�B1��ڂ�10ms*5=50ms��ɔ���������
		clr.b	BIOS_CURSOR_ON.w	;�\�����Ă��Ȃ�
		if	<tst.b BIOS_CURSOR_DRAWN.w>,ne	;�`����Ă���Ƃ�
			bsr	toggle_cursor		;�J�[�\���𔽓]������
			clr.b	BIOS_CURSOR_DRAWN.w	;�`����Ă��Ȃ�
		endif
	endif
	rts

;----------------------------------------------------------------
;IOCS�R�[��$20 _B_PUTC ������\������
;<d1.w:�����R�[�h
;>d0.l:�\����̃J�[�\���̌����W<<16|�J�[�\���̍s���W
iocs_20_B_PUTC:
	bsr	putc			;1�����\��
	move.l	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W<<16|�J�[�\���̍s���W
	rts

;----------------------------------------------------------------
;IOCS�R�[��$21 _B_PRINT �������\������
;<a1.l:������̃A�h���X
;>d0.l:�\����̃J�[�\���̌����W<<16|�J�[�\���̍s���W
;>a1.l:������̖�����0�̎��̃A�h���X�B�}�j���A���ɏ����Ă���B�ύX�s��
iocs_21_B_PRINT:
	push	d1
	dostart
		bsr	putc			;1�����\��
	start
		moveq.l	#0,d1
		move.b	(a1)+,d1
	while	ne
	pop
	move.l	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W<<16|�J�[�\���̍s���W
	rts

;----------------------------------------------------------------
;IOCS�R�[��$22 _B_COLOR ����������ݒ肷��
;<d1.w:���������B-1=�擾�̂�
;	0	��
;	1	���F
;	2	���F
;	3	��
;	4+	����
;	8+	���]
;>d0.l:�ݒ�O�̕��������B-1=�ݒ�l���͈͊O
iocs_22_B_COLOR:
	push	d1
	moveq.l	#0,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;��������2�B-|��t��|���t��|���|�ۈ͂�|�l�p�͂�|�v���|�[�V���i��|�g��
	lsl.w	#8,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;��������1�B��������|����|�Α�|�׎�|���]|����|�v���[��##
	if	<cmp.w #-1,d1>,ne	;�ݒ肷��Ƃ�
		if	<cmp.w #$7FFF,d1>,ls	;�ݒ�l���͈͓��̂Ƃ�
			move.b	d1,BIOS_ATTRIBUTE_1.w
			lsr.w	#8,d1
			move.b	d1,BIOS_ATTRIBUTE_2.w
		else				;�ݒ�l���͈͊O�̂Ƃ�
			moveq.l	#-1,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$23 _B_LOCATE �J�[�\���̍��W��ݒ肷��
;<d1.w:�J�[�\���̌����W�̒[��<<8|�J�[�\���̌����W�B-1=�擾�̂�
;<d2.w:�J�[�\���̍s���W
;>d0.l:�ݒ�O�̃J�[�\���̍��W�B�J�[�\���̌����W�̒[��<<24|�J�[�\���̌����W<<16|�J�[�\���̍s���W�B-1=�ݒ�l���͈͊O
;>d1.l:(IOCS.X,1.3�ȏ�)�擾�݂̂̂Ƃ�d0.l�Ɠ���
iocs_23_B_LOCATE:
	moveq.l	#0,d0
	move.b	BIOS_CURSOR_FRACTION.w,d0
	ror.l	#8,d0
	or.l	BIOS_CURSOR_COLUMN.w,d0	;BIOS_CURSOR_ROW�B�J�[�\���̌����W�̒[��<<24|�J�[�\���̌����W<<16|�J�[�\���̍s���W
	if	<cmp.w #-1,d1>,eq	;�擾�̂�
		move.l	d0,d1
		rts
	endif
	push	d1/d3
	move.w	d1,d3
	and.w	#$00FF,d1		;�J�[�\���̌����W
	lsr.w	#8,d3			;�J�[�\���̌����W�̒[��
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls,<cmp.w #7,d3>,ls	;�ݒ�l���͈͓��̂Ƃ�
;		push	d0
		bsr	iocs_1F_B_CUROFF
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		move.b	d3,BIOS_CURSOR_FRACTION.w
		bsr	iocs_1E_B_CURON
;		pop	d0
	else				;�ݒ�l���͈͊O�̂Ƃ�
		moveq.l	#-1,d0
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$24 _B_DOWN_S �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
;>d0.l:0
iocs_24_B_DOWN_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$25 _B_UP_S �J�[�\����1�s��ցB��[�ł̓X�N���[���_�E��
;>d0.l:0
iocs_25_B_UP_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi	;��[�ł͂Ȃ��Ƃ�
		subq.w	#1,d0			;1�s���
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;��[�̂Ƃ�
		moveq.l	#0,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;�R�s�[���̉��[�̍s���W
		moveq.l	#1,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		moveq.l	#0,d0			;��[�̍s���W
		moveq.l	#0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$26 _B_UP �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�
;<d1.b:�ړ�����s���B0=1�s
;>d0.l:0=����,-1=���s�B��[�𒴂���B���̂Ƃ��J�[�\���͓����Ȃ�
iocs_26_B_UP:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
	sub.w	d1,d0			;n�s���
	if	mi			;��[�𒴂���
		moveq.l	#-1,d1
	else				;��[�𒴂��Ȃ�
		move.w	d0,BIOS_CURSOR_ROW.w
		moveq.l	#0,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$27 _B_DOWN �J�[�\����n�s���ցB���[�Ŏ~�܂�
;<d1.b:�ړ�����s���B0=1�s
;>d0.l:0
iocs_27_B_DOWN:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
	add.w	d1,d0			;n�s����
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;���[�𒴂���
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$28 _B_RIGHT �J�[�\����n���E�ցB�E�[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
;>d0.l:0
iocs_28_B_RIGHT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W
	add.w	d1,d0			;n�s�E��
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;�E�[�𒴂���
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;�E�[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$29 _B_LEFT �J�[�\����n�����ցB���[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
;>d0.l:0
iocs_29_B_LEFT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W
	sub.w	d1,d0			;n�s����
	if	mi			;���[�𒴂���
		clr.w	d0			;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2A _B_CLR_ST �͈͂�I�����ĉ�ʂ�����
;<d1.b:�͈́B0=�J�[�\������E���܂�,1=���ォ��J�[�\���܂�,2=���ォ��E���܂ŁB�J�[�\���������
;>d0.l:0=����,-1=���s�B��������������
iocs_2A_B_CLR_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=�J�[�\������E���܂�
		bsr	putc_csi_0J		;ESC [0J �J�[�\������E���܂ŏ�������
		moveq.l	#0,d1
	elif	eq			;1=���ォ��J�[�\���܂�
		bsr	putc_csi_1J		;ESC [1J ���ォ��J�[�\���܂ŏ�������
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=���ォ��E���܂�
		bsr	putc_csi_2J		;ESC [2J ���ォ��E���܂ŏ�������B�J�[�\���������
		moveq.l	#0,d1
	else
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2B _B_ERA_ST �͈͂�I�����čs������
;<d1.b:�͈́B0=�J�[�\������E�[�܂�,1=���[����J�[�\���܂�,2=���[����E�[�܂�
;>d0.l:0=����,-1=���s�B��������������
iocs_2B_B_ERA_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=�J�[�\������E�[�܂�
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
		moveq.l	#0,d1
	elif	eq			;1=���[����J�[�\���܂�
		bsr	putc_csi_1K		;ESC [1K ���[����J�[�\���܂ŏ�������
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=���[����E�[�܂�
		bsr	putc_csi_2K		;ESC [2K ���[����E�[�܂ŏ�������
		moveq.l	#0,d1
	else				;��������������
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2C _B_INS �J�[�\�����牺��n�s�}���B�J�[�\�������[��
;<d1.w:�}������s���B0=1�s
;>d0.l:0
iocs_2C_B_INS:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_L		;ESC [nL �J�[�\�����牺��n�s�}���B�J�[�\�������[��
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2D _B_DEL �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
;<d1.w:�폜����s���B0=1�s
;>d0.l:0
iocs_2D_B_DEL:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_M		;ESC [nM �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS�R�[��$2E _B_CONSOL �R���\�[���͈̔͂�ݒ�B�J�[�\���������
;<d1.l:����X�h�b�g���W<<16|����Y�h�b�g���W�B-1=�擾�̂݁B����X�h�b�g���W��8�̔{���A����Y�h�b�g���W��4�̔{��
;<d2.l:�E�[�̌����W<<16|���[�̍s���W�B-1=�擾�̂�
;>d0.l:0
;>d1.l:�ݒ�O�̍���X�h�b�g���W<<16|����Y�h�b�g���W
;>d2.l:�ݒ�O�̉E�[�̌����W<<16|���[�̍s���W
iocs_2E_B_CONSOL:
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CONSOLE_OFFSET.w,d0
	if	<cmp.l #-1,d1>,ne
		and.l	#($03F8<<16)|$03FC,d1
		move.l	d1,d0
		swap.w	d0		;����X�h�b�g���W
		lsr.w	#3,d0		;����X�h�b�g���W/8
		ext.l	d1
		lsl.l	#7,d1		;����Y�h�b�g���W*128
		add.w	d0,d1
		move.l	BIOS_CONSOLE_OFFSET.w,d0
		move.l	d1,BIOS_CONSOLE_OFFSET.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w�B�J�[�\���������
	endif
	moveq.l	#127,d1
	and.w	d0,d1			;����X�h�b�g���W/8
	lsl.w	#3,d1			;����X�h�b�g���W
	swap.w	d1
	lsr.l	#7,d0			;����Y�h�b�g���W
	move.w	d0,d1			;�ݒ�O�̍���X�h�b�g���W<<16|����Y�h�b�g���W
	move.l	BIOS_CONSOLE_RIGHT.w,d0	;BIOS_CONSOLE_BOTTOM.w
	if	<cmp.l #-1,d2>,ne
		and.l	#127<<16|63,d2
		move.l	d2,BIOS_CONSOLE_RIGHT.w	;BIOS_CONSOLE_BOTTOM.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w�B�J�[�\���������
	endif
	move.l	d0,d2			;�ݒ�O�̉E�[�̌����W<<16|���[�̍s���W
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCS�R�[��$AE _OS_CURON �J�[�\���̕\����������
iocs_AE_OS_CURON:
	move.w	BIOS_TC_CURSOR_PERIOD.w,BIOS_TC_CURSOR_COUNTER.w	;�^�C�}�J�E���^�������l�ɂ���
	di				;�����݋֎~
	ifor	<tst.b BIOS_CURSOR_PROHIBITED.w>,ne,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;�֎~����Ă��邩�`����Ă��Ȃ��Ƃ�
		bsr	toggle_cursor		;�J�[�\���𔽓]������
		st.b	BIOS_CURSOR_DRAWN.w	;�`����Ă���
	endif
	st.b	BIOS_CURSOR_ON.w		;�\�����Ă���
	sf.b	BIOS_CURSOR_PROHIBITED.w	;������Ă���
	ei				;���荞�݋���
	rts

;----------------------------------------------------------------
;IOCS�R�[��$AF _OS_CUROF �J�[�\���̕\�����֎~����
iocs_AF_OS_CUROF:
	bsr	iocs_1F_B_CUROFF
	st.b	BIOS_CURSOR_PROHIBITED.w	;�֎~����Ă���
	rts

;----------------------------------------------------------------
;1�����\��
;<d1.w:�����R�[�h
putc:
	push	d0-d1
	if	<move.b BIOS_PUTC_POOL.w,d0>,eq	;1�o�C�g�ڂ̂Ƃ�
		if	<cmp.w #$001F,d1>,ls	;$0000�`$001F�̂Ƃ�
			bsr	putc_control		;���䕶������������
		elif	<cmp.w #$007F,d1>,ls	;$0020�`$007F�̂Ƃ�
			if	<cmp.w #$005C,d1>,eq	;$005C�̂Ƃ�
				if	<btst.b #0,SRAM_XCHG>,ne	;�����ϊ��t���O�B-----|$7C�b/$82�U|$7E�P/$81�`|$5C��/$80�_
					move.w	#$0080,d1		;$5C��$80
				endif
			elif	<cmp.w #$007E,d1>,eq	;$007E�̂Ƃ�
				if	<btst.b #1,SRAM_XCHG>,ne	;�����ϊ��t���O�B-----|$7C�b/$82�U|$7E�P/$81�`|$5C��/$80�_
					move.w	#$0081,d1		;$7E��$81
				endif
			elif	<cmp.w #$007C,d1>,eq	;$007C�̂Ƃ�
				if	<btst.b #2,SRAM_XCHG>,ne	;�����ϊ��t���O�B-----|$7C�b/$82�U|$7E�P/$81�`|$5C��/$80�_
					move.w	#$0082,d1		;$7C��$82
				endif
			endif
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		elif	<cmp.w #$009F,d1>,ls	;$0080�`$009F�̂Ƃ�
			move.b	d1,BIOS_PUTC_POOL.w	;1�o�C�g�ڂ̃v�[��
		elif	<cmp.w #$00DF,d1>,ls	;$00A0�`$00DF�̂Ƃ�
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		elif	<cmp.w #$00FF,d1>,ls	;$00E0�`$00FF�̂Ƃ�
			move.b	d1,BIOS_PUTC_POOL.w	;1�o�C�g�ڂ̃v�[��
		else				;$0100�`$FFFF�̂Ƃ�
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		endif
	else				;2�o�C�g�ڂ̂Ƃ�
		if	<cmp.b #$1B,d0>,eq	;1�o�C�g�ڂ�$1B�̂Ƃ��B�G�X�P�[�v�V�[�P���X�̏o�͒�
			bsr	putc_escape		;�G�X�P�[�v�V�[�P���X����������
		else				;1�o�C�g�ڂ�$1B�ł͂Ȃ��Ƃ�
			clr.b	BIOS_PUTC_POOL.w	;1�o�C�g�ڂ������
			lsl.w	#8,d0			;1�o�C�g��<<8
			move.b	d1,d0			;1�o�C�g��<<8|2�o�C�g��
			move.w	d0,d1			;1�o�C�g��<<8|2�o�C�g�ځB1�o�C�g�ڂ�����Ƃ�d1.w�̏�ʃo�C�g�͖��������
			bsr	putc_output		;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;�o�b�t�@�o�͂��I������
putc_finish_buffer:
	push	d0-d6/a0-a1
	move.w	BIOS_BUFFER_REQUEST.w,d0
	goto	eq,putc_finish_buffer_end	;�o�b�t�@�o�͒��ł͂Ȃ�
;<d0.w:�o�b�t�@�̕������\������̈�̃h�b�g��
	move.w	BIOS_BUFFER_WIDTH.w,d1
;<d1.w:�o�b�t�@�̕�����̃h�b�g��
	movea.l	BIOS_BUFFER_POINTER.w,a0
;<a0.l:�o�b�t�@�̏������݈ʒu=������̒���
	lea.l	BIOS_BUFFER_ARRAY.w,a1
;<a1.l:�o�b�t�@=������̐擪
	clr.w	BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͏I���B�ċA�Ăяo���ŕ\������̂ł��̑O�ɏI�����邱��
	clr.w	BIOS_BUFFER_WIDTH.w
	move.l	a1,BIOS_BUFFER_POINTER.w
	sub.w	d1,d0			;�]��h�b�g��
;<d0.w:�]��h�b�g��
	if	ls			;�]��Ȃ��Ƃ�
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;���񂹂ŗ]��Ƃ�
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;�E���̗]�����͈͂���������
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	elif	<bclr.b #BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;�E�񂹂ŗ]��Ƃ�
	;�����̗]�����͈͂���������
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w>,ne	;�����񂹂ŗ]��Ƃ�
	;�����̗]�����͈͂���������
		move.w	d0,d6
		lsr.w	#1,d0			;�����̗]�����͈͂̃h�b�g��
		sub.w	d0,d6			;�E���̗]�����͈͂̃h�b�g��
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;�������\������
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;�E���̗]�����͈͂���������
		move.w	d6,d0
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=���[�̌����W�̒[��
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=�E�[�̌����W�̒[��
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=���[�̌����W
		add.w	d2,d0
		move.w	d0,d3				;d3=�E�[�̌����W
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=��[�̍s���W
		move.w	d0,d1				;d1=���[�̍s���W
		bsr	putc_clear
	;�J�[�\���𓮂���
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	endif
putc_finish_buffer_end:
	pop
	rts

;----------------------------------------------------------------
;���䕶������������
;<d1.w:�����R�[�h
putc_control:
	push	d0-d1
;�o�b�t�@�o�͂��I������
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;�o�b�t�@�o�͒�
		bsr	putc_finish_buffer	;�o�b�t�@�o�͂��I������
	endif
;�J�[�\�����E�[����͂ݏo���Ă���Ƃ�BS�łȂ���Ή��s����
	move.w	BIOS_CURSOR_COLUMN.w,d0	;�J�[�\���̌����W
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi,<cmp.w #$0008,d1>,ne	;�J�[�\�����E�[����͂ݏo���Ă��邩��BS�ł͂Ȃ��Ƃ�
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;���䕶������������
	add.w	d1,d1
	move.w	putc_control_jump_table(pc,d1.w),d1
	jsr	putc_control_jump_table(pc,d1.w)
	pop
	rts

putc_control_jump_table:
	.dc.w	putc_00_NL-putc_control_jump_table	;���䕶��$00 NL 
	.dc.w	putc_01_SH-putc_control_jump_table	;���䕶��$01 SH 
	.dc.w	putc_02_SX-putc_control_jump_table	;���䕶��$02 SX 
	.dc.w	putc_03_EX-putc_control_jump_table	;���䕶��$03 EX 
	.dc.w	putc_04_ET-putc_control_jump_table	;���䕶��$04 ET 
	.dc.w	putc_05_EQ-putc_control_jump_table	;���䕶��$05 EQ 
	.dc.w	putc_06_AK-putc_control_jump_table	;���䕶��$06 AK 
	.dc.w	putc_07_BL-putc_control_jump_table	;���䕶��$07 BL �x����炷
	.dc.w	putc_08_BS-putc_control_jump_table	;���䕶��$08 BS �J�[�\����1�����ցB���[�ł�1�s��̉E�[�ցB��[�ł͉������Ȃ�
	.dc.w	putc_09_HT-putc_control_jump_table	;���䕶��$09 HT �J�[�\�������̃^�u���ցB�Ȃ����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
	.dc.w	putc_0A_LF-putc_control_jump_table	;���䕶��$0A LF �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
	.dc.w	putc_0B_VT-putc_control_jump_table	;���䕶��$0B VT �J�[�\����1�s��ցB��[�ł͉������Ȃ�
	.dc.w	putc_0C_FF-putc_control_jump_table	;���䕶��$0C FF �J�[�\����1���E�ցB�E�[�ł�1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
	.dc.w	putc_0D_CR-putc_control_jump_table	;���䕶��$0D CR �J�[�\�������[��
	.dc.w	putc_0E_SO-putc_control_jump_table	;���䕶��$0E SO 
	.dc.w	putc_0F_SI-putc_control_jump_table	;���䕶��$0F SI 
	.dc.w	putc_10_DE-putc_control_jump_table	;���䕶��$10 DE 
	.dc.w	putc_11_D1-putc_control_jump_table	;���䕶��$11 D1 
	.dc.w	putc_12_D2-putc_control_jump_table	;���䕶��$12 D2 
	.dc.w	putc_13_D3-putc_control_jump_table	;���䕶��$13 D3 
	.dc.w	putc_14_D4-putc_control_jump_table	;���䕶��$14 D4 
	.dc.w	putc_15_NK-putc_control_jump_table	;���䕶��$15 NK 
	.dc.w	putc_16_SN-putc_control_jump_table	;���䕶��$16 SN 
	.dc.w	putc_17_EB-putc_control_jump_table	;���䕶��$17 EB 
	.dc.w	putc_18_CN-putc_control_jump_table	;���䕶��$18 CN 
	.dc.w	putc_19_EM-putc_control_jump_table	;���䕶��$19 EM 
	.dc.w	putc_1A_SB-putc_control_jump_table	;���䕶��$1A SB ���ォ��E���܂ŏ����B�J�[�\���������
	.dc.w	putc_1B_EC-putc_control_jump_table	;���䕶��$1B EC �G�X�P�[�v�V�[�P���X�J�n
	.dc.w	putc_1C_FS-putc_control_jump_table	;���䕶��$1C FS 
	.dc.w	putc_1D_GS-putc_control_jump_table	;���䕶��$1D GS 
	.dc.w	putc_1E_RS-putc_control_jump_table	;���䕶��$1E RS �J�[�\���������
	.dc.w	putc_1F_US-putc_control_jump_table	;���䕶��$1F US 

;----------------------------------------------------------------
;���䕶��$00 NL 
putc_00_NL:
	rts

;----------------------------------------------------------------
;���䕶��$01 SH 
putc_01_SH:
	rts

;----------------------------------------------------------------
;���䕶��$02 SX 
putc_02_SX:
	rts

;----------------------------------------------------------------
;���䕶��$03 EX 
putc_03_EX:
	rts

;----------------------------------------------------------------
;���䕶��$04 ET 
putc_04_ET:
	rts

;----------------------------------------------------------------
;���䕶��$05 EQ 
putc_05_EQ:
	rts

;----------------------------------------------------------------
;���䕶��$06 AK 
putc_06_AK:
	rts

;----------------------------------------------------------------
;���䕶��$07 BL �x����炷
putc_07_BL:
	push	d0-d2/a0-a1
	move.l	BIOS_BEEP_DATA.w,d0	;BEEP����ADPCM�f�[�^�̃A�h���X�B-1=BIOS_BEEP_EXTENSION���g��
	moveq.l	#-1,d1
	if	<cmp.l d1,d0>,eq
		movea.l	BIOS_BEEP_EXTENSION.w,a0	;BEEP�����܂邲�ƍ����������[�`���̃A�h���X�BBIOS_BEEP_DATA=-1�̂Ƃ��L��
		jsr	(a0)
	else
		move.w	#4<<8|3,d1
		moveq.l	#0,d2
		move.w	BIOS_BEEP_LENGTH.w,d2	;BEEP����ADPCM�f�[�^�̃o�C�g���B0=����
		movea.l	d0,a1
		IOCS	_ADPCMOUT
	endif
	pop
	rts

;----------------------------------------------------------------
;���䕶��$08 BS �J�[�\����1�����ցB���[�ł�1�s��̉E�[�ցB��[�ł͉������Ȃ�
putc_08_BS:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	ne
		subq.w	#1,d0			;1������
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else
		move.w	BIOS_CURSOR_ROW.w,d0
		if	ne
			subq.w	#1,d0			;1�s���
			move.w	d0,BIOS_CURSOR_ROW.w
			move.w	BIOS_CONSOLE_RIGHT.w,BIOS_CURSOR_COLUMN.w	;�E�[��
			clr.b	BIOS_CURSOR_FRACTION.w
		endif
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$09 HT �J�[�\�������̃^�u���ցB�Ȃ����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
putc_09_HT:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	addq.w	#8,d0
	and.w	#-8,d0			;���̃^�u����
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,ls	;�͈͓�
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;�͈͊O
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0A LF �J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
putc_0A_LF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0B VT �J�[�\����1�s��ցB��[�ł͉������Ȃ�
putc_0B_VT:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	hi
		subq.w	#1,d0			;1�s���
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0C FF �J�[�\����1���E�ցB�E�[�ł�1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v���č��[��
putc_0C_FF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,lo	;�E�[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1���E��
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;�E�[�̂Ƃ�
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0D CR �J�[�\�������[��
putc_0D_CR:
	push	d0
	bsr	iocs_1F_B_CUROFF
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$0E SO 
putc_0E_SO:
	rts

;----------------------------------------------------------------
;���䕶��$0F SI 
putc_0F_SI:
	rts

;----------------------------------------------------------------
;���䕶��$10 DE 
putc_10_DE:
	rts

;----------------------------------------------------------------
;���䕶��$11 D1 
putc_11_D1:
	rts

;----------------------------------------------------------------
;���䕶��$12 D2 
putc_12_D2:
	rts

;----------------------------------------------------------------
;���䕶��$13 D3 
putc_13_D3:
	rts

;----------------------------------------------------------------
;���䕶��$14 D4 
putc_14_D4:
	rts

;----------------------------------------------------------------
;���䕶��$15 NK 
putc_15_NK:
	rts

;----------------------------------------------------------------
;���䕶��$16 SN 
putc_16_SN:
	rts

;----------------------------------------------------------------
;���䕶��$17 EB 
putc_17_EB:
	rts

;----------------------------------------------------------------
;���䕶��$18 CN 
putc_18_CN:
	rts

;----------------------------------------------------------------
;���䕶��$19 EM 
putc_19_EM:
	rts

;----------------------------------------------------------------
;���䕶��$1A SB ���ォ��E���܂ŏ����B�J�[�\���������
putc_1A_SB:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;��[�̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	clr.l	BIOS_CURSOR_COLUMN.w	;�����
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;���䕶��$1B EC �G�X�P�[�v�V�[�P���X�J�n
putc_1B_EC:
	move.b	#$1B,BIOS_PUTC_POOL.w	;1�o�C�g�ڂ̃v�[��
	move.l	#BIOS_ESCAPE_BUFFER,BIOS_ESCAPE_POINTER.w	;�G�X�P�[�v�V�[�P���X�o�b�t�@�̏������݈ʒu
	rts

;----------------------------------------------------------------
;���䕶��$1C FS 
putc_1C_FS:
	rts

;----------------------------------------------------------------
;���䕶��$1D GS 
putc_1D_GS:
	rts

;----------------------------------------------------------------
;���䕶��$1E RS �J�[�\���������
putc_1E_RS:
	bsr	iocs_1F_B_CUROFF
	clr.l	BIOS_CURSOR_COLUMN.w
	bsr	iocs_1E_B_CURON
	rts

;----------------------------------------------------------------
;���䕶��$1F US 
putc_1F_US:
	rts

;----------------------------------------------------------------
;�G�X�P�[�v�V�[�P���X����������
;<d1.w:�����R�[�h
putc_escape:
	push	d0/a0
	movea.l	BIOS_ESCAPE_POINTER.w,a0
	move.b	d1,(a0)+
	if	<cmpa.l #BIOS_ESCAPE_BUFFER+10,a0>,lo
		move.l	a0,BIOS_ESCAPE_POINTER.w
	endif
	move.b	BIOS_ESCAPE_BUFFER.w,d0	;�G�X�P�[�v�V�[�P���X�̍ŏ��̕���
	if	<cmp.b #'[',d0>,eq	;ESC [
		moveq.l	#$20,d0
		or.b	d1,d0
		ifand	<cmp.b #'`',d0>,hs,<cmp.b #'z',d0>,ls	;'@'�`'Z','`'�`'z'
			bsr	putc_csi
		endif
	elif	<cmp.b #'*',d0>,eq	;ESC *
		bsr	putc_esc_ast
	elif	<cmp.b #'=',d0>,eq	;ESC =
		if	<cmpa.l #BIOS_ESCAPE_BUFFER+3,a0>,eq
			bsr	putc_esc_equ
		endif
	elif	<cmp.b #'D',d0>,eq	;ESC D
		bsr	putc_esc_D
	elif	<cmp.b #'E',d0>,eq	;ESC E
		bsr	putc_esc_E
	elif	<cmp.b #'M',d0>,eq	;ESC M
		bsr	putc_esc_M
	else				;���̑�
		clr.b	BIOS_PUTC_POOL.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC *
;	���ォ��E���܂ŏ����B�J�[�\���������
putc_esc_ast:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;��[�̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	clr.l	BIOS_CURSOR_COLUMN.w	;�J�[�\���������
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC = r c
;	�J�[�\����r-' '�s,c-' '���ցBr��c�͕���
putc_esc_equ:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	moveq.l	#0,d1
	moveq.l	#0,d2
	move.b	BIOS_ESCAPE_BUFFER+2.w,d1	;���B' '=0
	move.b	BIOS_ESCAPE_BUFFER+1.w,d2	;�s�B' '=0
	moveq.l	#' ',d0
	sub.w	d0,d1			;�����W
	sub.w	d0,d2			;�s���W
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls	;�R���\�[���͈͓̔��̂Ƃ�
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC D
;	�J�[�\����1�s���ցB���[�ł̓X�N���[���A�b�v
;	_B_DOWN_S�Ɠ���
putc_esc_D:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC E
;	�J�[�\����1�s���̍��[�ցB���[�ł̓X�N���[���A�b�v
putc_esc_E:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
		addq.w	#1,d0			;1�s����
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;���[�̂Ƃ�
		moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC M
;	�J�[�\����1�s��ցB��[�ł̓X�N���[���_�E��
;	_B_UP_S�Ɠ���
putc_esc_M:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi		;��[�ł͂Ȃ��Ƃ�
		subq.w	#1,d0			;1�s���
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;��[�̂Ƃ�
		moveq.l	#0,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;�R�s�[���̉��[�̍s���W
		moveq.l	#1,d2			;�R�s�[��̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		moveq.l	#0,d0			;��[�̍s���W
		moveq.l	#0,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC [
;	https://en.wikipedia.org/wiki/ANSI_escape_code
;	http://nanno.dip.jp/softlib/man/rlogin/ctrlcode.html
putc_csi:
	push	d0-d3/a0
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CSI_EXTENSION.w,d0	;�G�X�P�[�v�V�[�P���X�ۂ��ƍ����ւ����[�`��
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	else
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		move.w	(a0)+,d0
		if	<cmp.w #'[>',d0>,eq	;ESC [>
			move.w	(a0)+,d0
			if	<cmp.w #'5l',d0>,eq	;ESC [>5l �J�[�\��ON
				sf.b	BIOS_CURSOR_PROHIBITED.w
			elif	<cmp.w #'5h',d0>,eq	;ESC [>5h �J�[�\��OFF
				st.b	BIOS_CURSOR_PROHIBITED.w
			else
				bsr	putc_csi_extension
			endif
		elif	<cmp.w #'[?',d0>,eq	;ESC [?
			move.w	(a0)+,d0
			if	<cmp.w #'4l',d0>,eq	;ESC [?4l �W�����v�X�N���[��
				clr.w	BIOS_SMOOTH_SCROLL.w
			elif	<cmp.w #'4h',d0>,eq	;ESC [?4h 8�h�b�g�X���[�X�X�N���[��
				move.w	#2,BIOS_SMOOTH_SCROLL.w
			else
				bsr	putc_csi_extension
			endif
		else
			lea.l	BIOS_ESCAPE_BUFFER+1.w,a0	;[�̎�
			moveq.l	#0,d0
			moveq.l	#-1,d1			;1�Ԗڂ̐��l
			moveq.l	#-1,d2			;2�Ԗڂ̐��l
			moveq.l	#-1,d3			;3�Ԗڂ̐��l
			do
				move.b	(a0)+,d0
			while	<cmp.b #' ',d0>,eq
			ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				moveq.l	#0,d1
				do
					sub.b	#'0',d0
					mulu.w	#10,d1
					add.w	d0,d1
					move.b	(a0)+,d0
				whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				if	<cmp.b #';',d0>,eq
					do
						move.b	(a0)+,d0
					while	<cmp.b #' ',d0>,eq
					ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						moveq.l	#0,d2
						do
							sub.b	#'0',d0
							mulu.w	#10,d2
							add.w	d0,d2
							move.b	(a0)+,d0
						whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						if	<cmp.b #';',d0>,eq
							do
								move.b	(a0)+,d0
							while	<cmp.b #' ',d0>,eq
							ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
								moveq.l	#0,d3
								do
									sub.b	#'0',d0
									mulu.w	#10,d3
									add.w	d0,d3
									move.b	(a0)+,d0
								whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
							endif
						endif
					endif
				endif
			endif
			if	<cmp.b #'@',d0>,eq
				bsr	putc_csi_at		;ESC [n@ �J�[�\������E��n���}��
			elif	<cmp.b #'A',d0>,eq
				bsr	putc_csi_A		;ESC [nA �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�
			elif	<cmp.b #'B',d0>,eq
				bsr	putc_csi_B		;ESC [nB �J�[�\����n�s���ցB���[�Ŏ~�܂�
			elif	<cmp.b #'C',d0>,eq
				bsr	putc_csi_C		;ESC [nC �J�[�\����n���E�ցB�E�[�Ŏ~�܂�
			elif	<cmp.b #'D',d0>,eq
				bsr	putc_csi_D		;ESC [nD �J�[�\����n�����ցB���[�Ŏ~�܂�
			elif	<cmp.b #'H',d0>,eq
				bsr	putc_csi_H		;ESC [r;cH �J�[�\����r-1�s,c-1����
			elif	<cmp.b #'J',d0>,eq
				bsr	putc_csi_J		;ESC [nJ ��ʂ���������
			elif	<cmp.b #'K',d0>,eq
				bsr	putc_csi_K		;ESC [nK �s����������
			elif	<cmp.b #'L',d0>,eq
				bsr	putc_csi_L		;ESC [nL �J�[�\�����牺��n�s�}���B�J�[�\�������[��
			elif	<cmp.b #'M',d0>,eq
				bsr	putc_csi_M		;ESC [nM �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
			elif	<cmp.b #'P',d0>,eq
				bsr	putc_csi_P		;ESC [nP �J�[�\������E��n���폜
			elif	<cmp.b #'R',d0>,eq
				bsr	putc_csi_R		;ESC [r;cR CSR(Cursor Position Report)
			elif	<cmp.b #'X',d0>,eq
				bsr	putc_csi_X		;ESC [nX �J�[�\������E��n������
			elif	<cmp.b #'c',d0>,eq
				bsr	putc_csi_c		;ESC [nc ������
			elif	<cmp.b #'f',d0>,eq
				bsr	putc_csi_f		;ESC [r;cf �J�[�\����r-1�s,c-1����
			elif	<cmp.b #'l',d0>,eq
				bsr	putc_csi_l		;ESC [nl ����
			elif	<cmp.b #'m',d0>,eq
				bsr	putc_csi_m		;ESC [nm ����������ݒ肷��
			elif	<cmp.b #'n',d0>,eq
				bsr	putc_csi_n		;ESC [nn DSR(Device Status Report)
			elif	<cmp.b #'r',d0>,eq
				bsr	putc_csi_r		;ESC [nr �E��
			elif	<cmp.b #'s',d0>,eq
				bsr	putc_csi_s		;ESC [ns �J�[�\���̍��W�ƕ���������ۑ�����
			elif	<cmp.b #'u',d0>,eq
				bsr	putc_csi_u		;ESC [nu �J�[�\���̍��W�ƕ��������𕜌�����
			else
				bsr	putc_csi_extension
			endif
		endif
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;�g���G�X�P�[�v�V�[�P���X�������[�`�����Ăяo��
putc_csi_extension:
	push	d0/a0
	move.l	BIOS_ESCAPE_EXTENSION.w,d0
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [n@ �J�[�\������E��n���}��
;<d1.w:�}�����錅���B0=1��
putc_csi_at:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
;
;	�`�a�b�c�d�e�f�g�h
;	�`�a�b�@�@�@�@�c�d
;
	move.w	BIOS_CURSOR_COLUMN.w,d4
	add.w	d1,d4			;�J�[�\���̌����W+�}�����錅��=�ړ���̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3
	sub.w	d4,d3			;�R���\�[���̉E�[-�ړ���̌����W=�ړ����镔���̌���-1
	if	lo			;���ׂĉ����o�����
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
	else				;�ړ����镔��������
		move.w	BIOS_CURSOR_ROW.w,d0	;�s���W
		swap.w	d0
		clr.w	d0			;65536*�s���W
		lsr.l	#5,d0			;128*16*�s���W
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;�s�̍��[�̃A�h���X
		movea.l	a2,a3
		adda.w	BIOS_CURSOR_COLUMN.w,a2	;�J�[�\���̃A�h���X
		adda.w	d3,a2			;�ړ����̉E�[�̃A�h���X
		adda.w	BIOS_CONSOLE_RIGHT.w,a3	;�s�̉E�[�̃A�h���X=�ړ���̉E�[�̃A�h���X
		do				;�v���[���̃��[�v
			moveq.l	#16-1,d2
			for	d2			;���X�^�̃��[�v
				lea.l	1(a2),a0		;�ړ����̉E�[�̃A�h���X+1
				lea.l	1(a3),a1		;�ړ���̉E�[�̃A�h���X+1
				move.w	d3,d1			;�ړ����镔���̌���-1
				for	d1			;���̃��[�v
					move.b	-(a0),-(a1)
				next
				lea.l	128(a2),a2		;���̃��X�^
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;���̃v���[��
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
		move.w	d4,d3
		subq.w	#1,d3			;�E�[�̌����W
		moveq.l	#0,d4			;���[�̌����W�̒[��
		moveq.l	#7,d5			;�E�[�̌����W�̒[��
		bsr	putc_clear		;�s����������
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nA �J�[�\����n�s��ցB��[�𒴂���Ƃ��͓����Ȃ�
;<d1.w:�ړ�����s���B0=1�s
putc_csi_A:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	sub.w	d1,d0			;n�s���
	if	hs			;��[�𒴂��Ȃ��Ƃ�
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nB �J�[�\����n�s���ցB���[�Ŏ~�܂�
;<d1.w:�ړ�����s���B0=1��
putc_csi_B:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	add.w	d1,d0			;n�s����
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;���[�𒴂���Ƃ�
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nC �J�[�\����n���E�ցB�E�[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
putc_csi_C:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	add.w	d1,d0			;n���E��
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;�E�[�𒴂���Ƃ�
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;�E�[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nD �J�[�\����n�����ցB���[�Ŏ~�܂�
;<d1.w:�ړ����錅���B0=1��
putc_csi_D:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	sub.w	d1,d0			;n������
	if	lo			;���[�𒴂���Ƃ�
		moveq.l	#0,d0			;���[�Ŏ~�܂�
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cf �J�[�\����r-1�s,c-1����
;<d1.w:�ړ���̍s���W+1�B0=��[�B���[�Ŏ~�܂�
;<d2.w:�ړ���̌����W+1�B0=���[�B�E�[�Ŏ~�܂�
putc_csi_f:
;----------------------------------------------------------------
;ESC [r;cH �J�[�\����r-1�s,c-1����
;<d1.w:�ړ���̍s���W+1�B0=��[�B���[�Ŏ~�܂�
;<d2.w:�ړ���̌����W+1�B0=���[�B�E�[�Ŏ~�܂�
putc_csi_H:
	push	d1-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=��[
	endif
	subq.w	#1,d1
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d1>,hi
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�Ŏ~�܂�
	endif
	ifor	<cmp.w #-1,d2>,eq,<tst.w d2>,eq
		moveq.l	#1,d2			;0=���[
	endif
	subq.w	#1,d2
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d2>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d2	;�E�[�Ŏ~�܂�
	endif
	move.w	d2,BIOS_CURSOR_COLUMN.w
	move.w	d1,BIOS_CURSOR_ROW.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nJ ��ʂ���������
;<d1.w:0=�J�[�\������E���܂�,1=���ォ��J�[�\���܂�,2=���ォ��E���܂ŁB�J�[�\���������
putc_csi_J:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0J		;ESC [0J �J�[�\������E���܂ŏ�������
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1J		;ESC [1J ���ォ��J�[�\���܂ŏ�������
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2J		;ESC [2J ���ォ��E���܂ŏ�������B�J�[�\���������
	endif
	rts

;----------------------------------------------------------------
;ESC [0J �J�[�\������E���܂ŏ�������
putc_csi_0J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0
	move.w	BIOS_CONSOLE_BOTTOM.w,d1
	if	<cmp.w d1,d0>,lo		;���[�ł͂Ȃ��Ƃ�
	;	move.w	BIOS_CURSOR_ROW.w,d0
		addq.w	#1,d0			;��[�̍s���W
	;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
	moveq.l	#0,d4
	move.b	BIOS_CURSOR_FRACTION.w,d4	;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [1J ���ォ��J�[�\���܂ŏ�������
putc_csi_1J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d1
	if	<tst.w d1>,hi			;��[�ł͂Ȃ��Ƃ�
		clr.w	d0			;��[�̍s���W
	;	move.w	BIOS_CURSOR_ROW.w,d1
		subq.w	#1,d1			;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	moveq.l	#0,d2			;���[�̌����W
	move.w	BIOS_CURSOR_COLUMN.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5
	add.b	BIOS_CURSOR_FRACTION.w,d5	;�E�[�̌����W�̒[��
	if	<cmp.w #7,d5>,hi	;���̌��̂Ƃ�
		if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,lo	;�E�[�ł͂Ȃ��Ƃ�
			addq.w	#1,d3
			subq.w	#8,d5
		else				;�E�[�̂Ƃ�
			moveq.l	#7,d5
		endif
	endif
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [2J ���ォ��E���܂ŏ�������B�J�[�\���������
putc_csi_2J:
	push	d0-d1
	moveq.l	#0,d0			;��[�̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	clr.l	BIOS_CURSOR_COLUMN.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nK �s����������
;<d1.w:0=�J�[�\������E�[�܂�,1=���[����J�[�\���܂�,2=���[����E�[�܂�
putc_csi_K:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1K		;ESC [1K ���[����J�[�\���܂ŏ�������
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2K		;ESC [2K ���[����E�[�܂ŏ�������
	endif
	rts

;----------------------------------------------------------------
;ESC [0K �J�[�\������E�[�܂ŏ�������
putc_csi_0K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [1K ���[����J�[�\���܂ŏ�������
putc_csi_1K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	moveq.l	#0,d2			;���[�̌����W
	move.w	BIOS_CURSOR_COLUMN.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [2K ���[����E�[�܂ŏ�������
putc_csi_2K:
	push	d0-d1
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	bsr	putc_clear_rows		;�s����������
	pop
	rts

;----------------------------------------------------------------
;ESC [nL �J�[�\�����牺��n�s�}���B�J�[�\�������[��
;<d1.w:�}������s���B0=1�s
putc_csi_L:
	push	d0-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:�J�[�\���̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d2	;�R���\�[���̍s��-1
	addq.w	#1,d2			;�R���\�[���̍s��
	sub.w	d0,d2			;�J�[�\�����牺�̍s��
	sub.w	d1,d2			;��ʓ��Ɏc��s��
;<d2.w:��ʓ��Ɏc��s��
	if	ls			;��ʓ��Ɏc��s���Ȃ��B���ׂĉ�ʊO�ɉ����o�����
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������
	;  ����������  ����������
	;  ����������  ����������
	;  ����������  ����������
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	else				;��ʓ��Ɏc��s������
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������\d1
	;  ����������  ����������/
	;  ����������  ����������)d2
	;  ����������  ����������
		add.w	d0,d2
		subq.w	#1,d2			;�R�s�[���̉��[�̍s���W
		add.w	d0,d1			;�R�s�[��̏�[�̍s���W
		exg.l	d1,d2
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;�R�s�[���̏�[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		exg.l	d1,d2
		subq.w	#1,d1			;���[�̍s���W
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nM �J�[�\�����牺��n�s�폜�B�J�[�\�������[��
;<d1.w:�폜����s���B0=1�s
putc_csi_M:
	push	d0-d3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1�s
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:�J�[�\���̍s���W
	move.w	BIOS_CONSOLE_BOTTOM.w,d3	;�R���\�[���̍s��-1
	addq.w	#1,d3			;�R���\�[���̍s��
	sub.w	d0,d3			;�J�[�\�����牺�̍s��
	sub.w	d1,d3			;��ʓ��Ɏc��s��
;<d3.w:��ʓ��Ɏc��s��
	if	ls			;��ʓ��Ɏc��s���Ȃ��B���ׂč폜�����
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������
	;  ����������  ����������
	;  ����������  ����������
	;  ����������  ����������
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;���[�̍s���W
		bsr	putc_clear_rows		;�s����������
	else				;��ʓ��Ɏc��s������
	;  ����������  ����������
	;  ��      ��  ��      ��
	;  ��      ��  ��      ��
	;d0����������������������)d3
	;  ����������  ����������\d1
	;  ����������  ����������/
	;  ����������  ����������
	;;;	move.w	BIOS_CURSOR_ROW.w,d0
		move.w	d0,d2			;�R�s�[��̏�[�̍s���W
		add.w	d1,d0			;�R�s�[���̏�[�̍s���W
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		bsr	putc_copy_rows		;�s���R�s�[����
		move.w	d2,d0
		add.w	d3,d0			;��[�̍s���W
	;;;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
		bsr	putc_clear_rows		;�s����������
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;���[��
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nP �J�[�\������E��n���폜
;<d1.w:�폜���錅���B0=1��
putc_csi_P:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
;
;	�`�a�b�c�d�e�f�g�h
;	�`�a�b�g�h�@�@�@�@
;
	move.w	BIOS_CURSOR_COLUMN.w,d4	;�J�[�\���̌����W
	add.w	d1,d4			;�J�[�\���̌����W+�폜���錅��=�ړ����̍��[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�R���\�[���̉E�[�̌����W=�ړ����̉E�[�̌����W
	sub.w	d4,d3			;�ړ����̉E�[�̌����W-�ړ����̍��[�̌����W=�ړ����镔���̌���-1
	if	lo			;���ׂč폜�����
		bsr	putc_csi_0K		;ESC [0K �J�[�\������E�[�܂ŏ�������
	else				;�ړ����镔��������
		move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W
		swap.w	d0
		clr.w	d0			;65536*�J�[�\���̍s���W
		lsr.l	#5,d0			;128*16*�J�[�\���̍s���W
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;�J�[�\���̍s�̍��[�̃A�h���X
		movea.l	a2,a3
		adda.w	d4,a2			;�J�[�\���̍s�̍��[�̃A�h���X+�ړ����̍��[�̌����W=�ړ����̍��[�̃A�h���X
		adda.w	BIOS_CURSOR_COLUMN.w,a3	;�J�[�\���̍s�̍��[�̃A�h���X+�J�[�\���̌����W=�J�[�\���̃A�h���X=�ړ���̍��[�̃A�h���X
		do				;�v���[���̃��[�v
			moveq.l	#16-1,d2
			for	d2			;���X�^�̃��[�v
				movea.l	a2,a0			;�ړ����̍��[�̃A�h���X
				movea.l	a3,a1			;�ړ���̍��[�̃A�h���X
				move.w	d3,d1			;�ړ����镔���̌���-1
				for	d1			;���̃��[�v
					move.b	(a0)+,(a1)+
				next
				lea.l	128(a2),a2		;���̃��X�^
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;���̃v���[��
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;�J�[�\���̍s���W=��������͈͂̏�[�̍s���W
		move.w	d0,d1			;�J�[�\���̍s���W=��������͈͂̉��[�̍s���W
		move.w	BIOS_CURSOR_COLUMN.w,d2	;�J�[�\���̌����W
		add.w	d3,d2			;�J�[�\���̌����W+�ړ�����͈͂̌���-1
		addq.w	#1,d2			;�J�[�\���̌����W+�ړ�����͈͂̌���=��������͈͂̍��[�̌����W
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;�R���\�[���̉E�[�̌����W=��������͈͂̉E�[�̌����W
		moveq.l	#0,d4			;��������͈͂̍��[�̌����W�̒[��
		moveq.l	#7,d5			;��������͈͂̉E�[�̌����W�̒[��
		bsr	putc_clear		;�s����������
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cR CPR(Cursor Position Report)
;	DSR(Device Status Report)�̕ԓ��B�����ł͉������Ȃ�
putc_csi_R:
	rts

;----------------------------------------------------------------
;ESC [nX �J�[�\������E��n������
;<d1.w:�������錅���B0=1��
putc_csi_X:
	push	d0-d5
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1��
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
	move.w	d2,d3
	add.w	d1,d3
	subq.w	#1,d3			;�E�[�̌����W
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,hi	;�E�[�𒴂���Ƃ�
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�Ŏ~�܂�
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
	move.w	d0,d1			;���[�̍s���W
	moveq.l	#7,d4
	and.b	BIOS_CURSOR_FRACTION.w,d4	;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;ESC [nc ������
;<d1.w:�h�b�g��
putc_csi_c:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	if	<cmp.w d0,d1>,ls	;�傫�����Ȃ�
		bset.b	#BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w	;������
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͊J�n
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nl ����
;<d1.w:�h�b�g��
putc_csi_l:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	if	<cmp.w d0,d1>,ls	;�傫�����Ȃ�
		bset.b	#BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w	;����
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͊J�n
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nm ����������ݒ肷��
;	0	���Z�b�g
;	1	����
;	2	�׎�
;	3	�Α�
;	4	����
;	5	(�x���_��)
;	6	(�����_��)
;	7	���]
;	8	(�閧)
;	9	��������
;	11�`19	(��փt�H���g1�`9)
;	20	(�u���b�N���^�[)
;	21	�g��
;	22	�����A�׎�����
;	23	�Α̉����A(�u���b�N���^�[����)
;	24	�����A�g������
;	25	(�x���_�ŉ����A�����_�ŉ���)
;	26	�v���|�[�V���i��
;	27	���]����
;	28	(�閧����)
;	29	������������
;	30	��
;	31	���F
;	32	���F
;	33	��
;	34	�����A��
;	35	�����A���F
;	36	�����A���F
;	37	�����A��
;	40	���]�A��
;	41	���]�A���F
;	42	���]�A���F
;	43	���]�A��
;	44	���]�A�����A��
;	45	���]�A�����A���F
;	46	���]�A�����A���F
;	47	���]�A�����A��
;	50	�v���|�[�V���i������
;	51	�l�p�͂�
;	52	�ۈ͂�
;	53	���
;	54	�l�p�͂݁A�ۈ͂݉���
;	55	�������
;	73	��t��
;	74	���t��
;	75	��t���A���t������
;<d1.w:�����B-1=�w��Ȃ�
;<d2.w:�����B-1=�w��Ȃ�
;<d3.w:�����B-1=�w��Ȃ�
putc_csi_m:
	push	d1
	bsr	putc_csi_m_1
	if	<cmp.w #-1,d2>,ne
		move.w	d2,d1
		bsr	putc_csi_m_1
	endif
	if	<cmp.w #-1,d3>,ne
		move.w	d3,d1
		bsr	putc_csi_m_1
	endif
	pop
	rts

;?d1
putc_csi_m_1:
;�����Ɣ��]�̂݃g�O������B���̑���ON�܂���OFF�̂ǂ��炩
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		move.b	#3,BIOS_ATTRIBUTE_1.w	;��������1�B��������|����|�Α�|�׎�|���]|����|�v���[��##
		clr.b	BIOS_ATTRIBUTE_2.w	;��������2�B-|��t��|���t��|���|�ۈ͂�|�l�p�͂�|�v���|�[�V���i��|�g��
	elif	<cmp.w #1,d1>,eq
		bchg.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;����
		if	eq			;OFF��ON�̂Ƃ�
			bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;�׎�����
		endif
	elif	<cmp.w #2,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bset.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;�׎�
	elif	<cmp.w #3,d1>,eq
		bset.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;�Α�
	elif	<cmp.w #4,d1>,eq
		bset.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;����
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;�g������
	elif	<cmp.w #7,d1>,eq
		bchg.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;���]
	elif	<cmp.w #9,d1>,eq
		bset.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;��������
	elif	<cmp.w #21,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bset.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;�g��
	elif	<cmp.w #22,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;�׎�����
	elif	<cmp.w #23,d1>,eq
		bclr.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;�Α̉���
	elif	<cmp.w #24,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;��������
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;�g������
	elif	<cmp.w #26,d1>,eq
		bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;�v���|�[�V���i��
	elif	<cmp.w #27,d1>,eq
		bclr.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;���]����
	elif	<cmp.w #29,d1>,eq
		bclr.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;������������
	elifand	<cmp.w #30,d1>,hs,<cmp.w #37,d1>,ls
		sub.w	#30,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elifand	<cmp.w #40,d1>,hs,<cmp.w #47,d1>,ls
		sub.w	#40,d1
		addq.b	#8,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elif	<cmp.w #50,d1>,eq
		bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;�v���|�[�V���i������
	elif	<cmp.w #51,d1>,eq
		bset.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;�l�p�͂�
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;�ۈ͂݉���
	elif	<cmp.w #52,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;�l�p�͂݉���
		bset.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;�ۈ͂�
	elif	<cmp.w #53,d1>,eq
		bset.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;���
	elif	<cmp.w #54,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;�l�p�͂݉���
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;�ۈ͂݉���
	elif	<cmp.w #55,d1>,eq
		bclr.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;�������
	elif	<cmp.w #73,d1>,eq
		bset.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;��t��
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;���t������
	elif	<cmp.w #74,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;��t������
		bset.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;���t��
	elif	<cmp.w #75,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;��t������
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;���t������
	endif
	rts

;----------------------------------------------------------------
;ESC [nn DSR(Device Status Report)
;<d1.w:6
putc_csi_n:
	push	d0-d2/a0
	if	<cmp.w #6,d1>,eq	;CPR(Cursor Position Report)
		move.w	#$0100+27,d2
		bsr	20f
		move.w	#$1C00+'[',d2
		bsr	20f
		move.w	BIOS_CURSOR_ROW.w,d0
		bsr	10f
		move.w	#$2700+';',d2
		bsr	20f
		move.w	BIOS_CURSOR_COLUMN.w,d0
		bsr	10f
		move.w	#$1400+'R',d2
		bsr	20f
	endif
	pop
	rts

;���l+1�𕶎���ɕϊ����ăL�[���̓o�b�t�@�ɏ�������
;<d0.b:���l�B255�͕s�B�����ł�1���ȗ����Ȃ�
;?d0-d2/a0
10:	addq.b	#1,d0
	move.l	#(1<<24)+(10<<16)+(100<<8),d1
	do
		lsr.l	#8,d1
	while	<cmp.b d1,d0>,lo
	do
		moveq.l	#-2,d2
		do
			addq.w	#2,d2
			sub.b	d1,d0
		while	hs
		move.w	15f(pc,d2.w),d2
		bsr	20f
		add.b	d1,d0
		lsr.l	#8,d1
	while	<tst.b d1>,ne
	rts

15:	.dc.w	$0B00+'0'
	.dc.w	$0200+'1'
	.dc.w	$0300+'2'
	.dc.w	$0400+'3'
	.dc.w	$0500+'4'
	.dc.w	$0600+'5'
	.dc.w	$0700+'6'
	.dc.w	$0800+'7'
	.dc.w	$0900+'8'
	.dc.w	$0A00+'9'

;�L�[���̓o�b�t�@�ɏ�������
;<d2.w:(�X�L�����R�[�h<<8)+�����R�[�h
;?a0
20:	di
	if	<cmpi.w #64,BIOS_KEY_REMAINING.w>,lo	;�L�[���̓o�b�t�@�Ɏc���Ă���f�[�^�̐���64�����̂Ƃ�
		movea.l	BIOS_KEY_WRITTEN.w,a0	;�Ō�ɏ������񂾈ʒu
		addq.l	#2,a0			;���񏑂����ވʒu
		if	<cmpa.w #BIOS_KEY_BUFFER+2*64.w,a0>,hs	;�����𒴂�����
			lea.l	BIOS_KEY_BUFFER.w,a0	;�擪�ɖ߂�
		endif
		move.w	d2,(a0)			;��������
		move.l	a0,BIOS_KEY_WRITTEN.w	;�Ō�ɏ������񂾈ʒu
		addq.w	#1,BIOS_KEY_REMAINING.w	;�L�[���̓o�b�t�@�Ɏc���Ă���f�[�^�̐�
	endif
	ei
	rts

;----------------------------------------------------------------
;ESC [nr �E��
;<d1.w:�h�b�g��
putc_csi_r:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	if	<cmp.w d0,d1>,ls	;�傫�����Ȃ�
		bset.b	#BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w	;�E��
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;�o�b�t�@�o�͊J�n
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [ns �J�[�\���̍��W�ƕ���������ۑ�����
;<d1.w:-1
putc_csi_s:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_CURSOR_ROW.w,BIOS_SAVED_ROW.w
		move.w	BIOS_CURSOR_COLUMN.w,BIOS_SAVED_COLUMN.w
		move.b	BIOS_CURSOR_FRACTION.w,BIOS_SAVED_FRACTION.w
		move.b	BIOS_ATTRIBUTE_1.w,BIOS_SAVED_ATTRIBUTE_1.w
		move.b	BIOS_ATTRIBUTE_2.w,BIOS_SAVED_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;ESC [nu �J�[�\���̍��W�ƕ��������𕜌�����
;<d1.w:-1
putc_csi_u:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_SAVED_ROW.w,BIOS_CURSOR_ROW.w
		move.w	BIOS_SAVED_COLUMN.w,BIOS_CURSOR_COLUMN.w
		move.b	BIOS_SAVED_FRACTION.w,BIOS_CURSOR_FRACTION.w
		move.b	BIOS_SAVED_ATTRIBUTE_1.w,BIOS_ATTRIBUTE_1.w
		move.b	BIOS_SAVED_ATTRIBUTE_2.w,BIOS_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;��ʂɕ`���܂��̓o�b�t�@�ɏo�͂���
;<d1.w:�����R�[�h
putc_output:
	push	d0-d7/a0-a2
	lea.l	-4*16-4*16(sp),sp	;�t�H���g�f�[�^�ƃ}�X�N�f�[�^
;<(sp).l[16]:�t�H���g�f�[�^
;<4*16(sp).l[16]:�}�X�N�f�[�^
	move.w	d1,d7
;<d7.w:�����R�[�h
;----------------
;�t�H���g�A�h���X�ƃh�b�g�������߂�
	ifand	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne,<cmp.w #$0020,d1>,hs,<cmp.w #$0082,d1>,ls	;�v���|�[�V���i���ɂ���
		lea.l	proportional_font(pc),a0	;�v���|�[�V���i���t�H���g($20�`$82)
		sub.w	#$0020,d1
		mulu.w	#2+2*16,d1
		adda.l	d1,a0			;�t�H���g�A�h���X
		move.w	(a0)+,d6		;�h�b�g���B1�`16
		moveq.l	#1,d2			;16�h�b�g�f�[�^
	else				;�v���|�[�V���i���ɂ��Ȃ�
		moveq.l	#8,d2
		IOCS	_FNTADR
	;<d0.l:�t�H���g�A�h���X
	;<d1.w:�������̃h�b�g��<<16|�������̃o�C�g��-1
	;<d2.w:�c�����̃h�b�g��-1
		movea.l	d0,a0			;�t�H���g�A�h���X
		move.w	d1,d2			;0=8�h�b�g�f�[�^,1=16�h�b�g�f�[�^
		swap.w	d1
		move.w	d1,d6			;�h�b�g���B1�`16
	endif
;<d2.w:0=8�h�b�g�f�[�^,1=16�h�b�g�f�[�^
;<d6.w:�h�b�g���B1�`16
;<(a0).b[16]:8�h�b�g�f�[�^
;�܂���
;<(a0).w[16]:16�h�b�g�f�[�^
;----------------
;�o�b�t�@�ɏo�͂��邩
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;�o�b�t�@�o�͒�
		movea.l	BIOS_BUFFER_POINTER.w,a0	;�o�b�t�@�̏������݈ʒu
		goto	<cmpa.l #BIOS_BUFFER_ARRAY+2*64,a0>,hs,putc_output_end	;�o�b�t�@����t�̂Ƃ��͖�������
		move.w	d7,(a0)+		;�����R�[�h
		move.l	a0,BIOS_BUFFER_POINTER.w	;�������݈ʒu��i�߂�
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�v���|�[�V���i���̂Ƃ�
			if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�����̂Ƃ�
				addq.w	#1,d6			;����1�h�b�g������
			endif
			if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�Α̂̂Ƃ�
				addq.w	#3,d6			;����3�h�b�g������
				bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
				if	ne	;�A���̂Ƃ�
					subq.w	#3,BIOS_BUFFER_WIDTH.w	;3�h�b�g�l�߂�
					if	cs
						clr.w	BIOS_BUFFER_WIDTH.w	;�O�̈�
					endif
				endif
			else				;�Α̂ł͂Ȃ��Ƃ�
				bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			endif
		endif
		add.w	d6,BIOS_BUFFER_WIDTH.w	;����������
		goto	putc_output_end
	endif
;----------------
;�J�[�\��OFF
;	�Α̂̂Ƃ��ʒu�������̂ł��̑O�ɃJ�[�\��������
	bsr	iocs_1F_B_CUROFF
;----------------
;�t�H���g�f�[�^�����
	movea.l	sp,a1			;�t�H���g�f�[�^
	moveq.l	#0,d0
	if	<tst.w d2>,eq		;8�h�b�g�f�[�^�̂Ƃ�
		moveq.l	#16-1,d3
		for	d3
			move.b	(a0)+,(a1)+
			move.b	d0,(a1)+		;clr
			move.w	d0,(a1)+		;clr
		next
	else				;16�h�b�g�f�[�^�̂Ƃ�
		moveq.l	#16-1,d3
		for	d3
			move.w	(a0)+,(a1)+
			move.w	d0,(a1)+		;clr
		next
	endif
;<(sp).l[16]:�t�H���g�f�[�^
;----------------
;����
;	�S�̂��E��1�h�b�g���炵��OR����
;	�v���|�[�V���i���̂Ƃ��͕���1�h�b�g������
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
;>d6.w:�h�b�g���B1�`17
	if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�����̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�v���|�[�V���i���̂Ƃ�
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;�E��1�h�b�g���炵��
				or.l	d1,d0			;OR����
				move.l	d0,(a1)+
			next
			addq.w	#1,d6			;����1�h�b�g������
		else				;�v���|�[�V���i���ł͂Ȃ��Ƃ�
			moveq.l	#1,d2
			ror.l	d6,d2
			neg.l	d2
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;�E��1�h�b�g���炵��
				or.l	d1,d0			;OR����
				and.l	d2,d0			;���𑝂₳�Ȃ�
				move.l	d0,(a1)+
			next
		endif
	endif
;----------------
;�׎�
;	�㉺���E�̂����ꂩ��1�ŁA���b�V����1�̂Ƃ��A1��0�ɂ���
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�׎��̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		move.l	#$AAAAAAAA,d2
		moveq.l	#1,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
		rol.l	d0,d2
		moveq.l	#16-1,d3
		for	d3
			move.l	(a1),d0
			move.l	d0,d1
			lsr.l	#1,d1			;��
			lsl.l	#1,d0			;�E
			or.l	d1,d0
			if	<cmpa.l sp,a1>,ne
				or.l	-4(a1),d0	;��
			endif
			if	<tst.w d3>,ne
				or.l	4(a1),d0	;��
			endif
			and.l	d2,d0			;���b�V��
			not.l	d0
			and.l	d0,(a1)+
			rol.l	#1,d2
		next
	endif
;----------------
;����
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�����̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*15(a1)
	endif
;----------------
;��������
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w>,ne	;���������̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*8(a1)
	endif
;----------------
;�g��
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�g���̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d2
		ror.l	d6,d2
		neg.l	d2
		moveq.l	#3,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
  .if 0
		move.l	#$CCCCCCCC,d1
		rol.l	d0,d1
		move.l	d1,d0			;11001100
		not.l	d1			;00110011
		and.l	d2,d0
		and.l	d2,d1
		or.l	d0,4*14(a1)
		or.l	d1,4*15(a1)
  .else
		move.l	#$88888888,d1
		move.l	#$55555555,d3
		rol.l	d0,d1			;10001000
		rol.l	d0,d3			;01010101
		move.l	d1,d0
		rol.l	#2,d0			;00100010
		and.l	d2,d0
		and.l	d2,d1
		and.l	d2,d3
		or.l	d0,4*13(a1)
		or.l	d3,4*14(a1)
		or.l	d1,4*15(a1)
  .endif
	endif
;----------------
;�l�p�͂�
	if	<btst.b #BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�l�p�݂͂̂Ƃ�
	;16x16�̒����Ɋ񂹂�
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16��12x12�ɏk������
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16�̒����Ɋ񂹂�
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;�l�p��t����
		movea.l	sp,a0
		or.l	#$FFFF0000,(a0)+
		moveq.l	#14-1,d3
		for	d3
			or.l	#$80010000,(a0)+
		next
		or.l	#$FFFF0000,(a0)+
	endif
;----------------
;�ۈ͂�
	if	<btst.b #BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�ۈ݂͂̂Ƃ�
	;16x16�̒����Ɋ񂹂�
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16��12x12�ɏk������
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16�̒����Ɋ񂹂�
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;�ۂ�t����
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tandi.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print($t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tori.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print(7**2<=$t&&$t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		ori.l	#%0000011111100000_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0000011111100000_0000000000000000,(a0)+
	endif
;----------------
;���
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;����̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*0(a1)
	endif
;----------------
;���t��
;	4x4�̏�2�h�b�g�ƍ�2�h�b�g�����ꂼ��OR��1�h�b�g�ɂ��邱�ƂŁA4x4��3x3�ɏk������
;	SX-Window�Ɠ������@
;	�c16�h�b�g��12�h�b�g�ɏk�����A������1�h�b�g�̍����ɔz�u����
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
;>d6.w:�h�b�g���B1�`12
	if	<btst.b #BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;���t���̂Ƃ�
		lea.l	subscript_pattern(pc),a2
		lea.l	4*16(sp),a0
		lea.l	4*15(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			subq.l	#8,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
		clr.l	4*2(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;��t��
;	4x4�̏�2�h�b�g�ƍ�2�h�b�g�����ꂼ��OR��1�h�b�g�ɂ��邱�ƂŁA4x4��3x3�ɏk������
;	SX-Window�Ɠ������@
;	�c16�h�b�g��12�h�b�g�ɏk�����A�ォ��0�h�b�g�̍����ɔz�u����
;<d6.w:�h�b�g���B1�`16
;<(sp).l[16]:�t�H���g�f�[�^
;>d6.w:�h�b�g���B1�`12
	if	<btst.b #BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;��t���̂Ƃ�
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;���]
;	�S�̂𔽓]������
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
	if	<btst.b #BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;���]�̂Ƃ�
		movea.l	sp,a1			;�t�H���g�f�[�^
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		moveq.l	#16-1,d3
		for	d3
			eor.l	d0,(a1)+
		next
	endif
;----------------
;�}�X�N�f�[�^�����
;<d6.w:�h�b�g���B1�`17
;>4*16(sp).l[16]:�}�X�N�f�[�^
	lea.l	4*16(sp),a1		;�}�X�N�f�[�^
	moveq.l	#1,d0
	ror.l	d6,d0
	neg.l	d0
	moveq.l	#16-1,d3
	for	d3
		move.l	d0,(a1)+
	next
;----------------
;�Α�
;	�S�̂��E��0�`3�h�b�g���炷
;	�v���|�[�V���i���̂Ƃ�����3�h�b�g������
;	�Α̂𑱂��ĕ`�悷��Ƃ��J�[�\���������Ȃ�������3�h�b�g�l�߂�
;<d6.w:�h�b�g���B1�`17
;<(sp).l[16]:�t�H���g�f�[�^
;<4*16(sp).l[16]:�}�X�N�f�[�^
;>d6.w:�h�b�g���B1�`20
	if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;�Α̂̂Ƃ�
		movea.l	sp,a0			;�t�H���g�f�[�^
		lea.l	4*16(sp),a1		;�}�X�N�f�[�^
*		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;�v���|�[�V���i���̂Ƃ�
			moveq.l	#3,d3
			do
				moveq.l	#4-1,d2
				for	d2
					move.l	(a0),d0
					lsr.l	d3,d0
					move.l	d0,(a0)+
					move.l	(a1),d0
					lsr.l	d3,d0
					move.l	d0,(a1)+
				next
				subq.w	#1,d3
			while	ne
			addq.w	#3,d6			;����3�h�b�g������
			bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			if	ne			;�A���̂Ƃ�
				subq.b	#3,BIOS_CURSOR_FRACTION.w	;3�h�b�g�l�߂�
				if	cs
					addq.b	#8,BIOS_CURSOR_FRACTION.w
					subq.w	#1,BIOS_CURSOR_COLUMN.w
					if	cs
						clr.w	BIOS_CURSOR_COLUMN.w	;�O�̈�
						clr.b	BIOS_CURSOR_FRACTION.w
					endif
				endif
			endif
*		else				;�v���|�[�V���i���ł͂Ȃ��Ƃ�
*			moveq.l	#1,d4
*			ror.l	d6,d4
*			neg.l	d4
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a1)+
*			next
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;���𑝂₳�Ȃ�
*				move.l	d0,(a1)+
*			next
*			lea.l	4*4(a0),a0
*			lea.l	4*4(a1),a1
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsl.l	#1,d0
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsl.l	#1,d0
*				move.l	d0,(a1)+
*			next
*		endif
	else				;�Α̂ł͂Ȃ��Ƃ�
		bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
	endif
;----------------
;���݂̍s�ɓ���؂�Ȃ���Ή��s����
;<d6.w:�h�b�g��
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;�R���\�[���̃h�b�g��
	move.w	BIOS_CURSOR_COLUMN.w,d1
	lsl.w	#3,d1
	add.b	BIOS_CURSOR_FRACTION.w,d1	;�J�[�\����X�h�b�g���W
	sub.w	d1,d0			;�R���\�[���̃h�b�g��-�J�[�\����X�h�b�g���W=�c��h�b�g��
	if	le			;�c��h�b�g��<=0�B���ɂ͂ݏo���Ă���
	;���s����
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	elif	<cmp.w d6,d0>,lt	;�c��h�b�g��<�h�b�g���B����؂�Ȃ�
	;�c����󔒂Ŗ��߂�
		move.w	BIOS_CURSOR_ROW.w,d0	;��[�̍s���W
		move.w	d0,d1			;���[�̍s���W
		move.w	BIOS_CURSOR_COLUMN.w,d2	;���[�̌����W
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
		moveq.l	#7,d4
		and.b	BIOS_CURSOR_FRACTION.w,d4	;���[�̌����W�̒[��
		moveq.l	#7,d5			;�E�[�̌����W�̒[��
		bsr	putc_clear		;��������
		;���s����
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;���[�ł͂Ȃ��Ƃ�
			addq.w	#1,d0			;1�s����
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;���[�̂Ƃ�
			moveq.l	#1,d0			;�R�s�[���̏�[�̍s���W
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;�R�s�[���̉��[�̍s���W
			moveq.l	#0,d2			;�R�s�[��̏�[�̍s���W
			bsr	putc_copy_rows		;�s���R�s�[����
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;��[�̍s���W
			move.w	d0,d1			;���[�̍s���W
			bsr	putc_clear_rows		;�s����������
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;���[��
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;----------------
;������`��
;<d6.w:�h�b�g��
;<(sp).l[16]:�t�H���g�f�[�^
;<4*16(sp).l[16]:�}�X�N�f�[�^
	move.w	BIOS_CURSOR_ROW.w,d0	;�s���W
	move.w	BIOS_CURSOR_COLUMN.w,d1	;�����W
	moveq.l	#7,d2
	and.b	BIOS_CURSOR_FRACTION.w,d2	;�����W�̒[��
	move.w	d6,d3			;�h�b�g��
	moveq.l	#3,d4
	and.b	BIOS_ATTRIBUTE_1.w,d4	;�v���[��
	movea.l	sp,a0			;�t�H���g�f�[�^
	lea.l	4*16(sp),a1		;�}�X�N�f�[�^
	bsr	putc_draw		;������`��
;----------------
;�J�[�\����i�߂�
;<d6.w:�h�b�g��
	add.b	BIOS_CURSOR_FRACTION.w,d6	;�J�[�\���̌����W�̒[��+�h�b�g��
	moveq.l	#7,d0
	and.w	d6,d0
	move.b	d0,BIOS_CURSOR_FRACTION.w	;�J�[�\���̌����W�̒[��
	lsr.w	#3,d6
	add.w	d6,BIOS_CURSOR_COLUMN.w	;�J�[�\���̌����W�B���傤�ǉE�[�ɂȂ�ꍇ�����邪�����ł͉��s���Ȃ�
;----------------
;�J�[�\��ON
	bsr	iocs_1E_B_CURON
;----------------
putc_output_end:
	lea.l	4*16+4*16(sp),sp	;�t�H���g�f�[�^�ƃ}�X�N�f�[�^
	pop
	rts

;----------------------------------------------------------------
;���t���Ŏg���p�^�[��
;	����������������
subscript_pattern:
  .irp ff,%00000000,%10000000,%10000000,%10000000
    .irp ee,%00000000,%01000000
      .irp dd,%00000000,%00100000
        .irp cc,%00000000,%00010000,%00010000,%00010000
          .irp bb,%00000000,%00001000
            .irp aa,%00000000,%00000100
	.dc.b	ff+ee+dd+cc+bb+aa
            .endm
          .endm
        .endm
      .endm
    .endm
  .endm

;----------------------------------------------------------------
;������`��
;<d0.l:�s���W
;<d1.l:�����W
;<d2.l:�����W�̒[��
;<d3.l:�h�b�g��
;<d4.l:�v���[���B��������1�̉���2�r�b�g
;<(a0).l[16]:�t�H���g�f�[�^�B���񂹁B���o�[�X���܂߂ĉ��H�ς�
;<(a1).l[16]:�}�X�N�f�[�^�B���񂹁B�������ރr�b�g��1
putc_draw:
	push	d0-d5/a0-a4
;----------------
;�A�h���X�����߂�
	swap.w	d0
	clr.w	d0			;65536*�s���W
	lsr.l	#5,d0			;128*16*�s���W
	add.w	d1,d0			;128*16*�s���W+�����W
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;�`���n�߂�A�h���X�̃I�t�Z�b�g
	add.l	#$00E00000,d0		;�`���n�߂�A�h���X
	bclr.l	#0,d0			;�����ɂ���
	if	ne
		addq.w	#8,d2
	endif
;<d2.w:�����W�̒[���B0�`15
	movea.l	d0,a4
;<a4.l:�`���n�߂�A�h���X�B����
;?d0-d1
;----------------
	add.w	d2,d3			;�����W�̒[��+�h�b�g��
;<d3.w:�����W�̒[��+�h�b�g��
;----------------
;1���[�h�Ɏ��܂邩�A2���[�h�Ɍׂ邩�A3���[�h�Ɍׂ邩
	if	<cmp.w #16,d3>,ls
	;----------------
	;1���[�h�Ɏ��܂�Ƃ�
		do				;�v���[���̃��[�v
			lsr.b	#1,d4
			if	cs			;�v���[���ɕ`�悷��Ƃ�
				movea.l	a0,a2			;�t�H���g�f�[�^
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.w	(a2)+,d0		;�t�H���g
					move.w	(a3)+,d1		;�}�X�N
					lsr.w	d2,d0
					lsr.w	d2,d1
					not.w	d1
					and.w	(a4),d1			;���蔲����
					or.w	d1,d0			;���킹��
					move.w	d0,(a4)+		;��������
					addq.l	#4-2,a2
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;���̃��X�^
				next
			else				;�v���[������������Ƃ�
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.w	(a3)+,d1		;�}�X�N
					lsr.w	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;���蔲��
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;���̃��X�^
				next
			endif
			adda.l	#-128*16+128*1024,a4	;���̃v���[��
		while	<cmpa.l #$00E40000,a4>,lo
	elif	<cmp.w #32,d3>,ls
	;----------------
	;2���[�h�Ɍׂ�Ƃ�
		do				;�v���[���̃��[�v
			lsr.b	#1,d4
			if	cs			;�v���[���ɕ`�悷��Ƃ�
				movea.l	a0,a2			;�t�H���g�f�[�^
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a2)+,d0		;�t�H���g
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;���蔲����
					or.l	d1,d0			;���킹��
					move.l	d0,(a4)+		;��������
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;���̃��X�^
				next
			else				;�v���[������������Ƃ�
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;���蔲��
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;���̃��X�^
				next
			endif
			adda.l	#-128*16+128*1024,a4	;���̃v���[��
		while	<cmpa.l #$00E40000,a4>,lo
	else
	;----------------
	;3���[�h�Ɍׂ�Ƃ�
		do				;�v���[���̃��[�v
			lsr.b	#1,d4
			if	cs			;�v���[���ɕ`�悷��Ƃ�
				movea.l	a0,a2			;�t�H���g�f�[�^
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a2)+,d0		;�t�H���g
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;���蔲����
					or.l	d1,d0			;���킹��
					move.l	d0,(a4)+		;��������
					move.w	-2(a2),d0		;�t�H���g
					move.w	-2(a3),d1		;�}�X�N
					swap.w	d0
					swap.w	d1
					clr.w	d0
					clr.w	d1
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.w	d1
					and.w	(a4),d1			;���蔲����
					or.w	d1,d0			;���킹��
					move.w	d0,(a4)+		;��������
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;���̃��X�^
				next
			else				;�v���[������������Ƃ�
				movea.l	a1,a3			;�}�X�N�f�[�^
				moveq.l	#16-1,d5
				for	d5			;���X�^�̃��[�v
					move.l	(a3)+,d1		;�}�X�N
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;���蔲��
					move.w	-2(a3),d1		;�}�X�N
					swap.w	d1
					clr.w	d1
					lsr.l	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;���蔲��
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;���̃��X�^
				next
			endif
			adda.l	#-128*16+128*1024,a4	;���̃v���[��
		while	<cmpa.l #$00E40000,a4>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;�s���R�s�[����
;	  ��������������  ��������������
;	  ��          ������������������
;	  ������������������    ��    ��d2
;	d0��    ��    ��  ��    ��    ��
;	  ��    ��    ��  ��    ��    ��
;	d1��    ��    ������������������
;	  ������������������          ��
;	  ��������������  ��������������
;	  ��������������  ��������������
;	  ������������������          ��
;	d0��    ��    ������������������
;	  ��    ��    ��  ��    ��    ��d2
;	d1��    ��    ��  ��    ��    ��
;	  ������������������    ��    ��
;	  ��          ������������������
;	  ��������������  ��������������
;<d0.w:�R�s�[���̏�[�̍s���W
;<d1.w:�R�s�[���̉��[�̍s���W
;<d2.w:�R�s�[��̏�[�̍s���W
putc_copy_rows:
	push	d0-d3/a0
	move.l	BIOS_CONSOLE_OFFSET.w,d3	;�R���\�[���̍���̃A�h���X�̃I�t�Z�b�g
	lsr.l	#7,d3			;�R���\�[���̏�[��Y�h�b�g���W
	lsr.w	#2,d3			;�R���\�[���̏�[�̃��X�^�u���b�N�ԍ�
	sub.w	d0,d1			;�R�s�[���̉��[�̍s���W-�R�s�[���̏�[�̍s���W=�R�s�[����s��-1
	lsl.w	#2,d1			;�R�s�[���郉�X�^�u���b�N��-4
	addq.w	#3,d1			;�R�s�[���郉�X�^�u���b�N��-1
;<d1.w:�R�s�[���郉�X�^�u���b�N��-1
	lsl.w	#2,d0
	add.w	d3,d0			;�R�s�[���̏�[�̃��X�^�u���b�N�ԍ�
;<d0.w:�R�s�[���̏�[�̃��X�^�u���b�N�ԍ�
	lsl.w	#2,d2
	add.w	d3,d2			;�R�s�[��̏�[�̃��X�^�u���b�N�ԍ�
;<d2.w:�R�s�[��̏�[�̃��X�^�u���b�N�ԍ�
	if	<cmp.w d0,d2>,ls	;��ɂ��炷�Ƃ�
		move.w	#$0101,d3		;���X�^�u���b�N�ԍ��̑���
	else				;���ɂ��炷�Ƃ�
		add.w	d1,d0			;�R�s�[���̉��[�̃��X�^�u���b�N�ԍ�
		add.w	d1,d2			;�R�s�[��̉��[�̃��X�^�u���b�N�ԍ�
		move.w	#$FEFF,d3		;���X�^�u���b�N�ԍ��̑���
	endif
;<d0.w:�R�s�[���̃��X�^�u���b�N�ԍ�
;<d2.w:�R�s�[��̃��X�^�u���b�N�ԍ�
;<d3.w:���X�^�u���b�N�ԍ��̑���
	lsl.w	#8,d0			;�R�s�[���̃��X�^�u���b�N�ԍ�<<8
	move.b	d2,d0			;�R�s�[���̃��X�^�u���b�N�ԍ�<<8|�R�s�[��̃��X�^�u���b�N�ԍ�
;<d0.w:�R�s�[���̃��X�^�u���b�N�ԍ�<<8|�R�s�[��̃��X�^�u���b�N�ԍ�
aGPDR	reg	a0
	lea.l	MFP_GPDR,aGPDR		;GPIP�f�[�^���W�X�^�BHSYNC|RINT|-|VDISP|OPMIRQ|POWER|EXPWON|ALARM
	move.w	sr,d2
	for	d1			;���X�^�u���b�N�̃��[�v
		do
		while	<tst.b (aGPDR)>,mi	;�����\�����Ԃ�҂�
		ori.w	#$0700,sr		;���荞�݂��֎~����
		do
		while	<tst.b (aGPDR)>,pl	;�����A�����Ԃ�҂�
		move.w	d0,CRTC_BLOCK-MFP_GPDR(aGPDR)	;���X�^�u���b�N�ԍ���ݒ肷��
		move.w	#$0008,CRTC_ACTION-MFP_GPDR(aGPDR)	;���X�^�R�s�[��ON�ɂ���B2��ڈȍ~�͕s�v
		move.w	d2,sr			;���荞�݂�������
		add.w	d3,d0			;���̃��X�^�u���b�N��
	next
	do
	while	<tst.b (aGPDR)>,mi	;�����\�����Ԃ�҂�
	ori.w	#$0700,sr		;���荞�݂��֎~����
	do
	while	<tst.b (aGPDR)>,pl	;�����A�����Ԃ�҂�
	move.w	d2,sr			;���荞�݂�������
	clr.w	CRTC_ACTION-MFP_GPDR(aGPDR)	;���X�^�R�s�[��OFF�ɂ���B�K�v
	pop
	rts

;----------------------------------------------------------------
;�s����������
;<d0.w:��[�̍s���W
;<d1.w:���[�̍s���W
putc_clear_rows:
	push	d2-d5
	moveq.l	#0,d2			;���[�̌����W
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;�E�[�̌����W
	moveq.l	#0,d4			;���[�̌����W�̒[��
	moveq.l	#7,d5			;�E�[�̌����W�̒[��
	bsr	putc_clear		;��������
	pop
	rts

;----------------------------------------------------------------
;��������
;	�����͋󔒂̕`��Ɠ����B�w�i�F�œh��ׂ�
;		��������		�����F	�w�i�F
;		0			��	��
;		1			���F	��
;		2			���F	��
;		3			��	��
;		4		����	��	��
;		5		����	���F	��
;		6		����	���F	��
;		7		����	��	��
;		8	���]		��	��
;		9	���]		��	���F
;		10	���]		��	���F
;		11	���]		��	��
;		12	���]	����	��	��
;		13	���]	����	��	���F
;		14	���]	����	��	���F
;		15	���]	����	��	��
;<d0.w:��[�̍s���W
;<d1.w:���[�̍s���W
;<d2.w:���[�̌����W
;<d3.w:�E�[�̌����W
;<d4.w:���[�̌����W�̒[���B0�`7�B������܂�
;<d5.w:�E�[�̌����W�̒[���B0�`7�B������܂�
putc_clear:
	push	d0-d7/a0-a3
;----------------
;���X�^�������߂�
	sub.w	d0,d1			;���[�̍s���W-��[�̍s���W=�s��-1
	addq.w	#1,d1			;�s��
	lsl.w	#4,d1			;16*�s��=���X�^��
	subq.w	#1,d1			;���X�^��-1
	movea.w	d1,a3
;<a3.w:���X�^��-1
;?d1
;----------------
;�A�h���X�����߂�
	swap.w	d0
	clr.w	d0			;65536*�s���W
	lsr.l	#5,d0			;128*16*�s���W
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;��[�̍s�̍���̃A�h���X�̃I�t�Z�b�g
	add.l	#$00E00000,d0		;��[�̍s�̍���̃A�h���X
	ext.l	d2
	ext.l	d3
	add.l	d0,d2			;����̃A�h���X
	add.l	d0,d3			;�E��̃A�h���X
;<d2.l:����̃A�h���X
;<d3.l:�E��̃A�h���X
;?d0
;----------------
;�A�h���X�������ɂ���
;	�����W�ł͂Ȃ��A�h���X�������ɂ���
;	_B_CONSOL�̓R���\�[���̍��[�̃A�h���X�������ɐ������Ă��Ȃ�
	bclr.l	#0,d2
	if	ne
		addq.w	#8,d4
	endif
;<d2.l:����̃A�h���X�B����
;<d4.w:���[�̌����W�̒[���B0�`15
	bclr.l	#0,d3
	if	ne
		addq.w	#8,d5
	endif
;<d3.l:�E��̃A�h���X�B����
;<d5.w:�E�[�̌����W�̒[���B0�`15
	movea.l	d2,a2
;<a2.l:����̃A�h���X�B����
;----------------
;���[�h�������߂�
	sub.w	d2,d3			;�E�[�̃A�h���X-���[�̃A�h���X=2*(���[�h��-1)
	lsr.w	#1,d3			;���[�h��-1
;<d3.w:���[�h��-1
;?d2
;----------------
;�}�X�N�����
	moveq.l	#-1,d6
	move.w	#$8000,d7
	lsr.w	d4,d6			;���[�̏������ޕ�����1�̃}�X�N�B$FFFF,$7FFF,�c,$0003,$0001
	asr.w	d5,d7			;�E�[�̏������ޕ�����1�̃}�X�N�B$8000,$C000,�c,$FFFE,$FFFF
;<d6.w:���[�̏������ޕ�����1�̃}�X�N�B$FFFF,$7FFF,�c,$0003,$0001
;<d7.w:�E�[�̏������ޕ�����1�̃}�X�N�B$8000,$C000,�c,$FFFE,$FFFF
;?d4-d5
;----------------
;�f�[�^�����
	moveq.l	#%1111,d0
	and.b	BIOS_ATTRIBUTE_1.w,d0	;�v���[��##
;		  111111
;		  5432109876543210
	move.w	#%1100110000000000,d2	;�w�i�F�����F�܂��͔��B�v���[��1��h��ׂ�
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
	swap.w	d2
;		  111111
;		  5432109876543210
	move.w	#%1010101000000000,d2	;�w�i�F�����F�܂��͔��B�v���[��0��h��ׂ�
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
;<d2.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
;----------------
;1���[�h��1���[�h�ł͂Ȃ���
	if	<tst.w d3>,eq
	;----------------
	;1���[�h�̂Ƃ�
		and.w	d7,d6
	;<d6.w:�������ޕ�����1�̃}�X�N
		and.w	d6,d2
		swap.w	d2
		and.w	d6,d2
		swap.w	d2
	;<d2.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
		not.w	d6
	;<d6.w:�������܂Ȃ�������1�̃}�X�N
		do				;�v���[���̃��[�v
			movea.l	a2,a0			;����̃A�h���X�����[�̃A�h���X
			move.w	a3,d1			;���X�^��-1
			for	d1			;���X�^�̃��[�v
				move.w	(a0),d0
				and.w	d6,d0			;�}�X�N
				or.w	d2,d0			;�f�[�^
				move.w	d0,(a0)
				lea.l	128(a0),a0		;���̍��[�̃A�h���X
			next
			swap.w	d2			;���̃v���[���̃f�[�^
			adda.l	#128*1024,a2		;���̃v���[���̍���̃A�h���X
		while	<cmpa.l #$00E40000,a2>,lo
	else
	;----------------
	;1���[�h�ł͂Ȃ��Ƃ�
		subq.w	#1,d3
	;<d3.w:���[�ƉE�[�̊Ԃ̃��[�h���B0�`
		move.l	d2,d4
		move.l	d2,d5
	;<d4.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
	;<d5.l:�v���[��1�̃f�[�^<<16|�v���[��0�̃f�[�^
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
	;<d4.l:�v���[��1�̍��[�̃f�[�^<<16|�v���[��0�̍��[�̃f�[�^
	;<d5.l:�v���[��1�̉E�[�̃f�[�^<<16|�v���[��0�̉E�[�̃f�[�^
		not.w	d6
		not.w	d7
	;<d6.w:���[�̏������܂Ȃ�������1�̃}�X�N�B$0000,$8000,�c,$FFFC,$FFFE
	;<d7.w:�E�[�̏������܂Ȃ�������1�̃}�X�N�B$7FFF,$3FFF,�c,$0001,$0000
		do				;�v���[���̃��[�v
			movea.l	a2,a1			;����̃A�h���X�����[�̃A�h���X
			move.w	a3,d1			;���X�^��-1
			for	d1			;���X�^�̃��[�v
				movea.l	a1,a0			;���[�̃A�h���X�����̃A�h���X
			;���[
				move.w	(a0),d0
				and.w	d6,d0			;���[�̃}�X�N
				or.w	d4,d0			;���[�̃f�[�^
				move.w	d0,(a0)+
			;���[�ƉE�[�̊�
				move.w	d3,d0			;���[�ƉE�[�̊Ԃ̃��[�h���B0�`
				forcontinue	d0
					move.w	d2,(a0)+		;�f�[�^
				next
			;�E�[
				move.w	(a0),d0
				and.w	d7,d0			;�E�[�̃}�X�N
				or.w	d5,d0			;�E�[�̃f�[�^
				move.w	d0,(a0)+
				lea.l	128(a1),a1		;���̍��[�̃A�h���X
			next
			swap.w	d2			;���̃v���[���̃f�[�^
			swap.w	d4			;���̃v���[���̍��[�̃f�[�^
			swap.w	d5			;���̃v���[���̉E�[�̃f�[�^
			adda.l	#128*1024,a2		;���̃v���[���̍���̃A�h���X
		while	<cmpa.l #$00E40000,a2>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;�v���|�[�V���i���t�H���g($20�`$82)
proportional_font:
	.dc.w	6	;$20   
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$21 �I
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$22 �h
	.dc.w	%0000000000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0010001000000000
	.dc.w	%0010001000000000
	.dc.w	%0100010000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$23 ��
	.dc.w	%0000000000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0111111100000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%1111111000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$24 ��
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%1001001000000000
	.dc.w	%1101000000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%0001011000000000
	.dc.w	%1001001000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$25 ��
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001000010000000
	.dc.w	%1001000100000000
	.dc.w	%1001001000000000
	.dc.w	%0110010000000000
	.dc.w	%0000100000000000
	.dc.w	%0001001100000000
	.dc.w	%0010010010000000
	.dc.w	%0100010010000000
	.dc.w	%1000010010000000
	.dc.w	%0000001100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$26 ��
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%0101000000000000
	.dc.w	%0011000000000000
	.dc.w	%0100100100000000
	.dc.w	%1000010100000000
	.dc.w	%1000001000000000
	.dc.w	%1000010100000000
	.dc.w	%0111100010000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$27 �f
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$28 �i
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$29 �j
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2A ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%1001001000000000
	.dc.w	%0101010000000000
	.dc.w	%0011100000000000
	.dc.w	%0101010000000000
	.dc.w	%1001001000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2B �{
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%1111111000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$2C �C
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2D �|
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2E �D
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2F �^
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$30 �O
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$31 �P
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001100000000000
	.dc.w	%0011100000000000
	.dc.w	%0111100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$32 �Q
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100000000000000
	.dc.w	%1111111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$33 �R
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0001110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$34 �S
	.dc.w	%0000000000000000
	.dc.w	%0000001000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111000000000
	.dc.w	%0001111000000000
	.dc.w	%0011011000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1111111100000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$35 �T
	.dc.w	%0000000000000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$36 �U
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%1110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$37 �V
	.dc.w	%0000000000000000
	.dc.w	%1111111100000000
	.dc.w	%1100001100000000
	.dc.w	%1100011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$38 �W
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$39 �X
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011111000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3A �F
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3B �G
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3C ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3D ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3E ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3F �H
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$40 ��
	.dc.w	%0000000000000000
	.dc.w	%0001111100000000
	.dc.w	%0010000010000000
	.dc.w	%0100000001000000
	.dc.w	%1000111001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001110110000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0011111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$41 �`
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0010001100000000
	.dc.w	%0010001100000000
	.dc.w	%0011111100000000
	.dc.w	%0100000110000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$42 �a
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$43 �b
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$44 �c
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$45 �d
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$46 �e
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$47 �f
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100001111000000
	.dc.w	%1100000010000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$48 �g
	.dc.w	%0000000000000000
	.dc.w	%1111001111000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%1111001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$49 �h
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$4A �i
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%1100110000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4B �j
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111110000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4C �k
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	13	;$4D �l
	.dc.w	%0000000000000000
	.dc.w	%1110000001110000
	.dc.w	%0110000001100000
	.dc.w	%0111000001100000
	.dc.w	%0111000011100000
	.dc.w	%0111100011100000
	.dc.w	%0101100101100000
	.dc.w	%0101110101100000
	.dc.w	%0100111001100000
	.dc.w	%0100111001100000
	.dc.w	%0100010001100000
	.dc.w	%1110010011110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	12	;$4E �m
	.dc.w	%0000000000000000
	.dc.w	%1100000011100000
	.dc.w	%0110000001000000
	.dc.w	%0111000001000000
	.dc.w	%0111100001000000
	.dc.w	%0101110001000000
	.dc.w	%0100111001000000
	.dc.w	%0100011101000000
	.dc.w	%0100001111000000
	.dc.w	%0100000111000000
	.dc.w	%0100000011000000
	.dc.w	%1110000001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$4F �n
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%0110000110000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$50 �o
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$51 �p
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1101110011000000
	.dc.w	%1111011110000000
	.dc.w	%0110001100000000
	.dc.w	%0001111100000000
	.dc.w	%0000000110000000
	.dc.w	%0000000011000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$52 �q
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110111000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001110000000
	.dc.w	%1111000111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$53 �r
	.dc.w	%0000000000000000
	.dc.w	%0001110100000000
	.dc.w	%0110001100000000
	.dc.w	%1100000100000000
	.dc.w	%1110000000000000
	.dc.w	%0111000000000000
	.dc.w	%0011110000000000
	.dc.w	%0000111000000000
	.dc.w	%0000011100000000
	.dc.w	%1000001100000000
	.dc.w	%1100011000000000
	.dc.w	%1011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$54 �s
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100110011000000
	.dc.w	%1000110001000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0011111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$55 �t
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0000111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$56 �u
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	16	;$57 �v
	.dc.w	%0000000000000000
	.dc.w	%1111000110001110
	.dc.w	%0110000110000100
	.dc.w	%0011000111000100
	.dc.w	%0011000111000100
	.dc.w	%0011001011001000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$58 �w
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000111000000000
	.dc.w	%0001001100000000
	.dc.w	%0010001100000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$59 �x
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$5A �y
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100000011000000
	.dc.w	%1000000110000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000001000000
	.dc.w	%1100000011000000
	.dc.w	%1111111111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5B �m
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5C ��
	.dc.w	%0000000000000000
	.dc.w	%1000001000000000
	.dc.w	%1000001000000000
	.dc.w	%0100010000000000
	.dc.w	%0100010000000000
	.dc.w	%0010100000000000
	.dc.w	%0010100000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5D �n
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5E �O
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010100000000000
	.dc.w	%0100010000000000
	.dc.w	%1000001000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5F �Q
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$60 �M
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$61 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110000000000
	.dc.w	%1100111000000000
	.dc.w	%0000011000000000
	.dc.w	%0011111000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100111000000000
	.dc.w	%0111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$62 ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111001100000000
	.dc.w	%1101111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$63 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$64 ��
	.dc.w	%0000000000000000
	.dc.w	%0000011100000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%0011101100000000
	.dc.w	%0110011100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011101110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$65 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$66 ��
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$67 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110100000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%0111110000000000
	.dc.w	%1100000000000000
	.dc.w	%0111111000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$68 ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$69 ��
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$6A ��
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%1101100000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6B ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111000000000000
	.dc.w	%0111100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110011000000000
	.dc.w	%1111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$6C ��
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	15	;$6D ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1101111011110000
	.dc.w	%0111011110111000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%1111011110111100
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$6E ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6F ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$70 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0111011100000000
	.dc.w	%0110111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$71 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111011100000000
	.dc.w	%1110111000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111100000000
	.dc.w	%0000000000000000
	.dc.w	9	;$72 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$73 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111101000000000
	.dc.w	%1100011000000000
	.dc.w	%1100001000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%1000011000000000
	.dc.w	%1100011000000000
	.dc.w	%1011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$74 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110110000000000
	.dc.w	%0011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$75 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011110110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$76 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0011010000000000
	.dc.w	%0011100000000000
	.dc.w	%0011100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	14	;$77 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001000111000
	.dc.w	%0110001100010000
	.dc.w	%0110001100010000
	.dc.w	%0011010110100000
	.dc.w	%0011010110100000
	.dc.w	%0001110011100000
	.dc.w	%0001100011000000
	.dc.w	%0000100001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$78 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0011010000000000
	.dc.w	%0001100000000000
	.dc.w	%0001110000000000
	.dc.w	%0010011000000000
	.dc.w	%0100001100000000
	.dc.w	%1110011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$79 ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110000100000000
	.dc.w	%0011001000000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0001110000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7A ��
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%1000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7B �o
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7C �b
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7D �p
	.dc.w	%0000000000000000
	.dc.w	%1100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%1100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7E �P
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7F DL
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$80 �_
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$81 �`
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001001000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$82 �U
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000



;----------------------------------------------------------------
;
;	SASI IOCS
;
;----------------------------------------------------------------

SASI_OFFSET	equ	-$95B6+$CCB8

;----------------------------------------------------------------
;	��΃A�h���X
;		�����P�[�g����
;	�ύX�O
;		000095BE 49F9(01)00009E30 	lea.l	sasi_seek_command,a4		;SEEK�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p95be,$00FF95BE+SASI_OFFSET,$00FF95BE+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E30+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		00009650 49F9(01)00009E3C 		lea.l	sasi_set_drive_parameter_command,a4	;SET DRIVE PARAMETER�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p9650,$00FF9650+SASI_OFFSET,$00FF9650+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		0000965E 49F9(01)00009E60 			lea.l	sasi_20mb_shipping_parameter,a4	;20MB�h���C�u�p�����[�^(�V�b�s���O�]�[��)
;----------------------------------------------------------------
	PATCH_DATA	p965E,$00FF965E+SASI_OFFSET,$00FF965E+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E60+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		00009684 43F9(01)00009E42 					lea.l	sasi_10mb_drive_parameter,a1	;10MB�h���C�u�p�����[�^
;----------------------------------------------------------------
	PATCH_DATA	p9684,$00FF9684+SASI_OFFSET,$00FF9684+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009694 43F9(01)00009E42 						lea.l	sasi_10mb_drive_parameter,a1	;10MB�h���C�u�p�����[�^
;----------------------------------------------------------------
	PATCH_DATA	p9694,$00FF9694+SASI_OFFSET,$00FF9694+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		000096C8 49F9(01)00009E3C 						lea.l	sasi_set_drive_parameter_command,a4		;SET DRIVE PARAMETER�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p96C8,$00FF96C8+SASI_OFFSET,$00FF96C8+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		00009728 49F9(01)00009E0C 	lea.l	sasi_test_drive_ready_command,a4	;TEST DRIVE READY�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p9728,$00FF9728+SASI_OFFSET,$00FF9728+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E0C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		000097B0 49F9(01)00009E2A 	lea.l	sasi_write_command,a4	;WRITE�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p97B0,$00FF97B0+SASI_OFFSET,$00FF97B0+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E2A+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		00009854 49F9(01)00009E24 	lea.l	sasi_read_command,a4		;READ�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p9854,$00FF9854+SASI_OFFSET,$00FF9854+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E24+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		000098A6 49F9(01)00009E36 	lea.l	sasi_format_alternate_track_command,a4		;FORAMT ALTERNATE TRACK�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p98A6,$00FF98A6+SASI_OFFSET,$00FF98A6+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E36+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		000098D6 49F9(01)00009E1E 	lea.l	sasi_format_bad_track_command,a4	;FORMAT BAD TRACK�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p98D6,$00FF98D6+SASI_OFFSET,$00FF98D6+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E1E+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		000098FE 49F9(01)00009E18 	lea.l	sasi_format_track_command,a4		;FORMAT TRACK�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p98FE,$00FF98FE+SASI_OFFSET,$00FF98FE+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E18+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		0000993A 43F9(01)00009E56 	lea.l	sasi_20mb_drive_parameter,a1	;20MB�h���C�u�p�����[�^
;----------------------------------------------------------------
	PATCH_DATA	p993A,$00FF993A+SASI_OFFSET,$00FF993A+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E56+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009946 43F9(01)00009E6A 		lea.l	sasi_40mb_drive_parameter,a1	;40MB�h���C�u�p�����[�^
;----------------------------------------------------------------
	PATCH_DATA	p9946,$00FF9946+SASI_OFFSET,$00FF9946+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E6A+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009952 43F9(01)00009E42 			lea.l	sasi_10mb_drive_parameter,a1	;10MB�h���C�u�p�����[�^
;----------------------------------------------------------------
	PATCH_DATA	p9952,$00FF9952+SASI_OFFSET,$00FF9952+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009972 43F9(01)00009E42 				lea.l	sasi_10mb_drive_parameter,a1	;10MB�h���C�u�p�����[�^
;----------------------------------------------------------------
	PATCH_DATA	p9972,$00FF9972+SASI_OFFSET,$00FF9972+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		000099B2 49F9(01)00009E3C 		lea.l	sasi_set_drive_parameter_command,a4	;SET DRIVE PARAMETER�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p99B2,$00FF99B2+SASI_OFFSET,$00FF99B2+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		000099FE 43F9(01)00009E60 			lea.l	sasi_20mb_shipping_parameter,a1
;----------------------------------------------------------------
	PATCH_DATA	p99FE,$00FF99FE+SASI_OFFSET,$00FF99FE+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E60+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009A10 43F9(01)00009E74 				lea.l	sasi_40mb_shipping_parameter,a1
;----------------------------------------------------------------
	PATCH_DATA	p9A10,$00FF9A10+SASI_OFFSET,$00FF9A10+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E74+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009A22 43F9(01)00009E4C 					lea.l	sasi_10mb_shipping_parameter,a1
;----------------------------------------------------------------
	PATCH_DATA	p9A22,$00FF9A22+SASI_OFFSET,$00FF9A22+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E4C+SASI_OFFSET,a1
;----------------------------------------------------------------
;	�ύX�O
;		00009A2E 49F9(01)00009E3C 				lea.l	sasi_set_drive_parameter_command,a4	;SET DRIVE PARAMETER�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p9A2E,$00FF9A2E+SASI_OFFSET,$00FF9A2E+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		00009A48 49F9(01)00009E30 							lea.l	sasi_seek_command,a4	;SEEK�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p9A48,$00FF9A48+SASI_OFFSET,$00FF9A48+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E30+SASI_OFFSET,a4
;----------------------------------------------------------------
;	�ύX�O
;		00009D76 49F9(01)00009E12 		lea.l	sasi_recalibrate_command,a4	;RECALIBRATE�R�}���h
;----------------------------------------------------------------
	PATCH_DATA	p9D76,$00FF9D76+SASI_OFFSET,$00FF9D76+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E12+SASI_OFFSET,a4

;----------------------------------------------------------------
;	SASI�x���t�@�C(1024�o�C�g�ȉ�)
;	���
;		https://twitter.com/kamadox/status/1361214698226479109
;		IOCS _B_VERIFY��SASI�n�[�h�f�B�X�N�̂Ƃ��Ώۂ��X�[�p�[�o�C�U�X�^�b�N�ɓǂݍ���Ń�������Ńf�[�^���r���Ă���
;		�܂�OS�̌������󂯂Ă��Ȃ��o�b�t�@��DMA�]�����Ă���
;		���̍\���͂܂����B���[�J��������������Ƃ��X�[�p�[�o�C�U�X�^�b�N��DMA���͂��Ƃ͌���Ȃ�
;	�΍�
;		��r����f�[�^�͒��O�Ƀf�B�X�N�ɏ������񂾃f�[�^�ł��肻�̃o�b�t�@��DMA�]���\�ȗ̈�ɂ��邱�Ƃ����҂ł���
;		(1)�o�b�t�@�̐擪�A�h���X��$00F00000�`$00FFFFFF�͈̔͂ɂ���Ƃ���r���s�킸��ɐ�����Ԃ�
;		(2)��r����f�[�^���o�b�t�@����X�^�b�N�փR�s�[����
;		(3)��r�����f�[�^���f�B�X�N����o�b�t�@�֓ǂݍ���
;		(4)�ǂݍ��ݐ����̂Ƃ��o�b�t�@�ƃX�^�b�N���r����
;		(5)�ǂݍ��ݎ��s�܂��͕s��v�̂Ƃ���r����f�[�^���X�^�b�N����o�b�t�@�փR�s�[����
;----------------------------------------------------------------
	PATCH_DATA	p9618,$00FF9618+SASI_OFFSET,$00FF963F+SASI_OFFSET,$4FEFFC00
	jmp	sasi_verify_1024
	PATCH_TEXT
;<d1.w:$8000|HD-ID(0�`15)<<8
;<d2.l:���R�[�h�ԍ�
;<d3.w:�o�C�g���B1024�ȉ�
;<a1.l:�o�b�t�@�̐擪�A�h���X
;>d0.l:0=����,-2=���s
sasi_verify_1024:
	push	d4/a0-a1/a6,1024
;(1)�o�b�t�@�̐擪�A�h���X��$00F00000�`$00FFFFFF�͈̔͂ɂ���Ƃ���r���s�킸��ɐ�����Ԃ�
	moveq.l	#0,d0			;����
	gotoand	<cmpa.l #$00F00000,a1>,hs,<cmpa.l #$00FFFFFF,a1>,ls,90f
;(2)��r����f�[�^���o�b�t�@����X�^�b�N�փR�s�[����
	movea.l	a1,a6			;�o�b�t�@
;	movea.l	a6,a1			;�o�b�t�@
	movea.l	sp,a0			;�X�^�b�N
	move.w	d3,d4
	subq.w	#1,d4
	for	d4
		move.b	(a1)+,(a0)+
	next
;(3)��r�����f�[�^���f�B�X�N����o�b�t�@�֓ǂݍ���
	movea.l	a6,a1			;�o�b�t�@
	jsr	$00FF9826+SASI_OFFSET	;sasi_read_modify�Bd1-d3/a1/a6�͔j�󂳂�Ȃ�
	goto	<tst.b d0>,ne,10f	;�ǂݍ��ݎ��s
;�ǂݍ��ݐ���
;(4)�ǂݍ��ݐ����̂Ƃ��o�b�t�@�ƃX�^�b�N���r����
	moveq.l	#0,d0			;����
;	movea.l	a6,a1			;�o�b�t�@
	movea.l	sp,a0			;�X�^�b�N
	move.w	d3,d4
	subq.w	#1,d4
	for	d4
		cmpm.b	(a1)+,(a0)+
	next	eq
	goto	eq,90f			;��v
;�s��v
	moveq.l	#-2,d0			;���s
;(5)�ǂݍ��ݎ��s�܂��͕s��v�̂Ƃ���r����f�[�^���X�^�b�N����o�b�t�@�փR�s�[����
10:	movea.l	sp,a1			;�X�^�b�N
	movea.l	a6,a0			;�o�b�t�@
	move.w	d3,d4
	subq.w	#1,d4
	for	d4
		move.b	(a1)+,(a0)+
	next
90:	pop
	rts

;----------------------------------------------------------------
;	sasi_write_retry�̃��[�v
;		����̓��g���C�񐔂Ȃ̂ł��̂܂�
;	�ύX�O
;		00009798 3F3C0064         	move.w	#100,-(sp)
;----------------------------------------------------------------

;----------------------------------------------------------------
;	sasi_read_retry�̃��[�v
;		����̓��g���C�񐔂Ȃ̂ł��̂܂�
;	�ύX�O
;		0000983C 3F3C0064         	move.w	#100,-(sp)
;----------------------------------------------------------------

;----------------------------------------------------------------
;	sasi_preprocess�̃��[�v
;		�o�X�t���[�t�F�[�Y��҂B�v����
;	�ύX�O
;		00009AA4 203C000000C8     	move.l	#201-1,d0
;----------------------------------------------------------------
	PATCH_DATA	p9AA4,$00FF9AA4+SASI_OFFSET,$00FF9AA4+5+SASI_OFFSET,$203C0000
	move.w	BIOS_MPU_SPEED_ROM.w,d0
	lsr.w	#2,d0			;(10*1000/12)/4=208

;----------------------------------------------------------------
;	sasi_do_select�̃��[�v
;		�o�X�t���[�t�F�[�Y��҂B�v����
;	�ύX�O
;		00009B24 203C000007D0     		move.l	#2001-1,d0
;----------------------------------------------------------------
	PATCH_DATA	p9B24,$00FF9B24+SASI_OFFSET,$00FF9B24+5+SASI_OFFSET,$203C0000
	jsr	p9b24
	PATCH_TEXT
p9b24:
	move.w	BIOS_MPU_SPEED_ROM.w,d0
	mulu.w	#3,d0			;(10*1000/12)*3=2500
	rts
;----------------------------------------------------------------
;	�ύX�O
;		00009B34*51C8FFF4_00009B2A	dbra	~~forDn,~~redo68
;----------------------------------------------------------------
	PATCH_DATA	p9B34,$00FF9B34+SASI_OFFSET,$00FF9B34+3+SASI_OFFSET,$51C8FFF4
	subq.l	#1,d0
	bcc.s	(*)-$9B36+$9B2A

;----------------------------------------------------------------
;	sasi_do_select_10�̃��[�v
;		BSY���Z�b�g�����̂�҂B�v����
;	�ύX�O
;		00009B64 203C00001388     	move.l	#5000,d0
;----------------------------------------------------------------
	PATCH_DATA	p9B64,$00FF9B64+SASI_OFFSET,$00FF9B64+5+SASI_OFFSET,$203C0000
	jsr	p9b64
	PATCH_TEXT
p9b64:
	move.w	BIOS_MPU_SPEED_ROM.w,d0
	mulu.w	#6,d0			;(10*1000/12)*6=5000
	rts

;----------------------------------------------------------------
;	sasi_stsin_msgin��sasi_wait_status�̈���
;		�X�e�[�^�X�t�F�[�Y�ƃ��b�Z�[�W�t�F�[�Y��҂B�v����
;	�ύX�O
;		00009B94 2A3C004C4B40     	move.l	#5000000,d5
;----------------------------------------------------------------
	PATCH_DATA	p9B94,$00FF9B94+SASI_OFFSET,$00FF9B94+5+SASI_OFFSET,$2A3C004C
	jsr	p9b94
	PATCH_TEXT
p9b94:
	move.w	BIOS_MPU_SPEED_ROM.w,d5
	mulu.w	#6000,d5		;(10*1000/12)*6000=5000000
	rts
;----------------------------------------------------------------
;	�ύX�O
;		00009BA8 2A3C0001E848     		move.l	#125000,d5
;----------------------------------------------------------------
	PATCH_DATA	p9BA8,$00FF9BA8+SASI_OFFSET,$00FF9BA8+5+SASI_OFFSET,$2A3C0001
	jsr	p9ba8
	PATCH_TEXT
p9ba8:
	move.w	BIOS_MPU_SPEED_ROM.w,d5
	mulu.w	#150,d5			;(10*1000/12)*150=125000
	rts

;----------------------------------------------------------------
;	sasi_receive_sense�̃��[�v
;		�f�[�^�C���t�F�[�Y��҂B�v����
;	�ύX�O
;		00009C3E 283C0003D090     		move.l	#250000,d4
;----------------------------------------------------------------
	PATCH_DATA	p9C3E,$00FF9C3E+SASI_OFFSET,$00FF9C3E+5+SASI_OFFSET,$283C0003
	jsr	p9c3e
	PATCH_TEXT
p9c3e:
	move.w	BIOS_MPU_SPEED_ROM.w,d4
	mulu.w	#300,d4			;(10*1000/12)*300=250000
	rts

;----------------------------------------------------------------
;	sasi_send_command�̃��[�v
;		�R�}���h�t�F�[�Y��҂B�v����
;	�ύX�O
;		00009CC6 243C0003D090     		move.l	#250000,d2
;----------------------------------------------------------------
	PATCH_DATA	p9CC6,$00FF9CC6+SASI_OFFSET,$00FF9CC6+5+SASI_OFFSET,$243C0003
	jsr	p9cc6
	PATCH_TEXT
p9cc6:
	move.w	BIOS_MPU_SPEED_ROM.w,d2
	mulu.w	#300,d2			;(10*1000/12)*300=250000
	rts

;----------------------------------------------------------------
;	sasi_command_start�̃��[�v
;		�R�}���h�t�F�[�Y��҂B�ŏ���5�o�C�g�ƍŌ��1�o�C�g�B�v����
;	�ύX�O
;		00009D14 243C0003D090     		move.l	#250000,d2
;----------------------------------------------------------------
	PATCH_DATA	p9D14,$00FF9D14+SASI_OFFSET,$00FF9D14+5+SASI_OFFSET,$243C0003
	jsr	p9d14
	PATCH_TEXT
p9d14:
	move.w	BIOS_MPU_SPEED_ROM.w,d2
	mulu.w	#300,d2			;(10*1000/12)*300=250000
	rts
;----------------------------------------------------------------
;	�ύX�O
;		00009D40 243C0003D090     	move.l	#250000,d2
;----------------------------------------------------------------
	PATCH_DATA	p9D40,$00FF9D40+SASI_OFFSET,$00FF9D40+5+SASI_OFFSET,$243C0003
	jsr	p9d40
	PATCH_TEXT
p9d40:
	move.w	BIOS_MPU_SPEED_ROM.w,d2
	mulu.w	#300,d2			;(10*1000/12)*300=250000
;DMA�]���O�̃L���b�V���t���b�V��
;	�R�}���h�̍Ō��1�o�C�g�𑗐M���钼�O�ɃL���b�V�����t���b�V�����Ă���
;	$00FF9E02�̓]���J�n�̒��O�Ŏ��Ԃ��������DMAC���ŏ��̊O���]���v�����������\��������
	bra	cache_flush

;----------------------------------------------------------------
;	sasi_mpuout_10byte�̃��[�v
;		�f�[�^�A�E�g�t�F�[�Y��҂B�v����
;	�ύX�O
;		00009DA0 283C0003D090     		move.l	#250000,d4
;----------------------------------------------------------------
	PATCH_DATA	p9DA0,$00FF9DA0+SASI_OFFSET,$00FF9DA0+5+SASI_OFFSET,$283C0003
	jsr	p9da0
	PATCH_TEXT
p9da0:
	move.w	BIOS_MPU_SPEED_ROM.w,d4
	mulu.w	#300,d4			;(10*1000/12)*300=250000
	rts

;----------------------------------------------------------------
;	sasi_do_recalibrate��sasi_wait_status�̈���
;		�X�e�[�^�X�t�F�[�Y��҂B�v����
;	�ύX�O
;		00009D82 2A3C004C4B40     			move.l	#5000000,d5
;----------------------------------------------------------------
	PATCH_DATA	p9D82,$00FF9D82+SASI_OFFSET,$00FF9D82+5+SASI_OFFSET,$2A3C004C
	jsr	p9d82
	PATCH_TEXT
p9d82:
	move.w	BIOS_MPU_SPEED_ROM.w,d5
	mulu.w	#6000,d5		;(10*1000/12)*6000=5000000
	rts



;----------------------------------------------------------------
;	IOCS$4x��HD�̏���
;		SCSI�����@�̂Ƃ����������G���[��Ԃ�
;			SCSI�����@�̂Ƃ�IOCS$4x��HD�̏����͂����ɗ���O�ɏI����Ă���
;		SASI�����@�̂Ƃ�SASI IOCS�ɃW�����v����
;	�ύX�O
;		00008704 670009B2_000090B8        beq     scsi_40_B_SEEK          ;IOCS�R�[��$40 _B_SEEK(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8704,$00FF8704,$00FF8704+3,$670009B2
;	beq.w	(*)-$8704+$95B6+SASI_OFFSET	;sasi_40_B_SEEK
	PATCH_beq.w	pD580,pD580_40
;----------------------------------------------------------------
;	�ύX�O
;		0000874A 67000A9C_000091E8        beq     scsi_41_B_VERIFY        ;IOCS�R�[��$41 _B_VERIFY(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p874A,$00FF874A,$00FF874A+3,$67000A9C
;	beq.w	(*)-$874A+$95DA+SASI_OFFSET	;sasi_41_B_VERIFY
	PATCH_beq.w	pD580,pD580_41
;----------------------------------------------------------------
;	�ύX�O
;		0000884C 67000A02_00009250        beq     scsi_43_B_DSKINI        ;IOCS�R�[��$43 _B_DSKINI(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p884C,$00FF884C,$00FF884C+3,$67000A02
;	beq.w	(*)-$884C+$9640+SASI_OFFSET	;sasi_43_B_DSKINI
	PATCH_beq.w	pD580,pD580_43
;----------------------------------------------------------------
;	�ύX�O
;		00008890 67000844_000090D6        beq     scsi_44_B_DRVSNS        ;IOCS�R�[��$44 _B_DRVSNS(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8890,$00FF8890,$00FF8890+3,$67000844
;	beq.w	(*)-$8890+$9720+SASI_OFFSET	;sasi_44_B_DRVSNS
	PATCH_beq.w	pD580,pD580_44
;----------------------------------------------------------------
;	�ύX�O
;		000088D0 670008B0_00009182        beq     scsi_45_B_WRITE         ;IOCS�R�[��$45 _B_WRITE(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p88D0,$00FF88D0,$00FF88D0+3,$670008B0
;	beq.w	(*)-$88D0+$9744+SASI_OFFSET	;sasi_45_B_WRITE
	PATCH_beq.w	pD580,pD580_45
;----------------------------------------------------------------
;	�ύX�O
;		00008950 6700082A_0000917C        beq     scsi_46_B_READ          ;IOCS�R�[��$46 _B_READ(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8950,$00FF8950,$00FF8950+3,$6700082A
;	beq.w	(*)-$8950+$97E8+SASI_OFFSET	;sasi_46_B_READ
	PATCH_beq.w	pD580,pD580_46
;----------------------------------------------------------------
;	�ύX�O
;		000089C6 670006F6_000090BE        beq     scsi_47_B_RECALI        ;IOCS�R�[��$47 _B_RECALI(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p89C6,$00FF89C6,$00FF89C6+3,$670006F6
;	beq.w	(*)-$89C6+$988C+SASI_OFFSET	;sasi_47_B_RECALI
	PATCH_beq.w	pD580,pD580_47
;----------------------------------------------------------------
;	�ύX�O
;		00008A96 6700062C_000090C4        beq     scsi_48_B_ASSIGN        ;IOCS�R�[��$48 _B_ASSIGN(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8A96,$00FF8A96,$00FF8A96+3,$6700062C
;	beq.w	(*)-$8A96+$989E+SASI_OFFSET	;sasi_48_B_ASSIGN
	PATCH_beq.w	pD580,pD580_48
;----------------------------------------------------------------
;	�ύX�O
;		00008B2E 6700059A_000090CA        beq     scsi_4B_B_BADFMT        ;IOCS�R�[��$4B _B_BADFMT(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8B2E,$00FF8B2E,$00FF8B2E+3,$6700059A
;	beq.w	(*)-$8B2E+$98CE+SASI_OFFSET	;sasi_4B_B_BADFMT
	PATCH_beq.w	pD580,pD580_4B
;----------------------------------------------------------------
;	�ύX�O
;		00008B80 6700054E_000090D0        beq     scsi_4D_B_FORMAT        ;IOCS�R�[��$4D _B_FORMAT(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8B80,$00FF8B80,$00FF8B80+3,$6700054E
;	beq.w	(*)-$8B80+$98F6+SASI_OFFSET	;sasi_4D_B_FORMAT
	PATCH_beq.w	pD580,pD580_4D
;----------------------------------------------------------------
;	�ύX�O
;		00008D4C 670003C6_00009114        beq     scsi_4F_B_EJECT         ;IOCS�R�[��$4F _B_EJECT(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8D4C,$00FF8D4C,$00FF8D4C+3,$670003C6
;	beq.w	(*)-$8D4C+$99D0+SASI_OFFSET	;sasi_4F_B_EJECT
	PATCH_beq.w	pD580,pD580_4F
;----------------------------------------------------------------
;	�ύX�O
;		0000D580 102E0009         		move.b	SPC_INTS(aSPC),d0
;----------------------------------------------------------------
;	PATCH_DATA	pD580,$00FFD580,$00FFDCE3,$102E0009
	PATCH_DATA	pD580,$00FFD580,$00FFD67F,$102E0009
pD580_40:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF95B6+SASI_OFFSET)PATCH_ZL	;sasi_40_B_SEEK
pD580_41:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF95DA+SASI_OFFSET)PATCH_ZL	;sasi_41_B_VERIFY
pD580_43:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF9640+SASI_OFFSET)PATCH_ZL	;sasi_43_B_DSKINI
pD580_44:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF9720+SASI_OFFSET)PATCH_ZL	;sasi_44_B_DRVSNS
pD580_45:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF9744+SASI_OFFSET)PATCH_ZL	;sasi_45_B_WRITE
pD580_46:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF97E8+SASI_OFFSET)PATCH_ZL	;sasi_46_B_READ
pD580_47:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF988C+SASI_OFFSET)PATCH_ZL	;sasi_47_B_RECALI
pD580_48:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF989E+SASI_OFFSET)PATCH_ZL	;sasi_48_B_ASSIGN
pD580_4B:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF98CE+SASI_OFFSET)PATCH_ZL	;sasi_4B_B_BADFMT
pD580_4D:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF98F6+SASI_OFFSET)PATCH_ZL	;sasi_4D_B_FORMAT
pD580_4F:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF99D0+SASI_OFFSET)PATCH_ZL	;sasi_4F_B_EJECT
pD580_error:
	moveq.l	#-1,d0
	rts



;----------------------------------------------------------------
;
;	�p�b�`�f�[�^�̖���
;
;----------------------------------------------------------------

	PATCH_END



	.end

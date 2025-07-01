;----------------------------------------------------------------
;
;	IOCS _SYS_STAT
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ
	.include	t09version.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;IOCS _SYS_STAT($AC)
;�V�X�e�����̎擾�Ɛݒ�
;<d1.w:���[�h
;	$0000	MPU�X�e�[�^�X�̎擾
;		>d0.l:MPU�X�e�[�^�X
;			bit0�`7		MPU�̎��(6=68060)
;			bit14		MMU�̗L��(0=�Ȃ�,1=����)
;			bit15		FPU�̗L��(0=�Ȃ�,1=����)
;			bit16�`31	�N���b�N�X�s�[�h*10
;	$0001	�L���b�V����Ԃ̎擾
;		>d0.l:���݂̃L���b�V�����
;			bit0	���߃L���b�V���̏��(0=OFF,1=ON)
;			bit1	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;	$0002	�L���b�V���̏�Ԃ�SRAM�ݒ�l�ɂ���
;		>d0.l:�ݒ��̃L���b�V�����
;			bit0	���߃L���b�V���̏��(0=OFF,1=ON)
;			bit1	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;	$0003	�L���b�V���̃v�b�V������і�����
;	$0004	�L���b�V���ݒ�
;		<d2.b:�L���b�V���̐ݒ�
;			bit0	���߃L���b�V���̏��(0=OFF,1=ON)
;			bit1	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;		>d0.l:�ݒ�O�̃L���b�V�����
;			bit0	���߃L���b�V���̏��(0=OFF,1=ON)
;			bit1	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;	$4000	���[�J���������̏��̎擾
;		>d0.l:���[�J���������̃o�C�g��
;			0	���[�J�����������Ȃ�
;			-1	�G���[
;		>a1.l:���[�J���������̐擪�̕����A�h���X
;	$4001	�����A�h���X�����[�J�����������w���Ă��邩���ׂ�
;		<a1.l:�����A�h���X
;		>d0.l:����
;			0	���[�J�����������w���Ă���
;			-1	���[�J���������ł͂Ȃ�
;	$4002	�_���A�h���X�����[�J�����������w���Ă��邩���ׂ�
;		<a1.l:�_���A�h���X
;		>d0.l:����
;			-1	�����Ș_���A�h���X�܂��̓��[�J���������ł͂Ȃ�
;			0	���[�J�����������w���Ă���
;	$4003	�_���A�h���X��DMA�]���\���ǂ������ׂ�
;		<a1.l:�_���A�h���X
;		>d0.l:����
;			-1	DMA�]���s�\
;			0	DMA�]���\
;	$4004	�_���A�h���X�͈̔͂�DMA�]���\���ǂ������ׂ�
;		<d2.l:�T�C�Y
;		<a1.l:�_���A�h���X
;		>d0.l:����
;			-1	DMA�]���s�\
;			0	DMA�]���\
;	$5000	���s�v���O���������[�J���������Ƀ��[�h���Ď��s����
;		<a1.l:���s�t�@�C����
;		<a2.l:�R�}���h���C��
;		<a3.l:���̃A�h���X
;		>d0.l:_EXEC�̕ԋp�l
;	$5001	���ݎ��s���̃v���Z�X���I�����Ă���,
;		�w�肳�ꂽ���s�v���O���������[�J���������Ƀ��[�h���Ď��s��,
;		�e�v���Z�X�ɕ��A����
;		<d2.w:���[�h
;			bit0	1=���[�J�����������s�����Ă����烁�C���������Ŏ��s����
;		<a1.l:���s�t�@�C����
;		<a2.l:�R�}���h���C��
;		<a3.l:���̃A�h���X(0=�e�v���Z�X�̊�,���s���̃v���Z�X�̗̈�͕s��)
;		���A���Ȃ�(_EXEC�̕ԋp�l��e�v���Z�X�ɕԂ�)
;	$8000	�o�[�W�����擾
;		>d0.l:�o�[�W�����ԍ�
;		>a1.l:'060T'
;	$8001	�w��_���A�h���X�̃L���b�V�����[�h�̎擾
;		<a1.l:�_���A�h���X
;		>d0.l:�L���b�V�����[�h
;			0	�L���b�V������,���C�g�X���[
;			1	�L���b�V������,�R�s�[�o�b�N
;			2	�L���b�V���֎~,�X�g�A�o�b�t�@�֎~
;			3	�L���b�V���֎~,�X�g�A�o�b�t�@����
;			-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
;	$8004	�w��_���A�h���X�̃L���b�V�����[�h�̐ݒ�(�y�[�W�P��)
;		<d2.l:�L���b�V�����[�h
;			0	�L���b�V������,���C�g�X���[
;			1	�L���b�V������,�R�s�[�o�b�N
;			2	�L���b�V���֎~,�X�g�A�o�b�t�@�֎~
;			3	�L���b�V���֎~,�X�g�A�o�b�t�@����
;		<a1.l:�_���A�h���X
;		>d0.l:�ύX�O�̃L���b�V�����[�h
;			-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
;	$C000	�݊����[�h
;		>d0.l:
;			0	����I��
;			-1	���Ɍ݊����[�h�ɂȂ��Ă���
;	$C001	�g�����[�h
;		>d0.l:
;			0	����I��
;			-1	���Ɋg�����[�h�ɂȂ��Ă���
;	$C002	���݂̃��[�h���擾����
;		>d0.l:���[�h
;			0	�݊����[�h
;			1	�g�����[�h
;	$C003	���[�h�؂�ւ����V�O�i���̐ݒ�
;		<a1.l:�V�O�i���n���h��
;		>d0.l:
;			0	����I��
;			-1	�V�O�i�����I�[�o�[
;	$C004	���[�h�؂�ւ����V�O�i���̉���
;		<a1.l:�V�O�i���n���h��
;		>d0.l:
;			0	����I��
;			-1	�s���ȃV�O�i���n���h��
;	$C005	���������e�[�u���̎擾
;		<a1.l:�e�[�u���i�[�A�h���X
;	$C006	�L���b�V���ƃX�[�p�[�X�P�[���̏�Ԃ̎擾
;		>d0.l:�L���b�V���ƃX�[�p�[�X�P�[���̏��
;			bit0	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;			bit1	���߃L���b�V���̏��(0=OFF,1=ON)
;			bit2	�X�g�A�o�b�t�@�̏��(0=OFF,1=ON)
;			bit3	�u�����`�L���b�V���̏��(0=OFF,1=ON)
;			bit4	�X�[�p�[�X�P�[���̏��(0=OFF,1=ON)
;	$C007	�L���b�V���ƃX�[�p�[�X�P�[���̏�Ԃ̐ݒ�
;		<d2.l:�L���b�V���ƃX�[�p�[�X�P�[���̏��
;			bit0	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;			bit1	���߃L���b�V���̏��(0=OFF,1=ON)
;			bit2	�X�g�A�o�b�t�@�̏��(0=OFF,1=ON)
;			bit3	�u�����`�L���b�V���̏��(0=OFF,1=ON)
;			bit4	�X�[�p�[�X�P�[���̏��(0=OFF,1=ON)
;		>d0.l:�ύX�O�̃L���b�V���ƃX�[�p�[�X�P�[���̏��
;	$F000	�_���A�h���X���畨���A�h���X�����߂�
;		<a1.l:�_���A�h���X
;		>d0.l:�����A�h���X
;			$00000000�`$3FFFFFFF	�����A�h���X
;			-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
;	$F001	�A�h���X�ϊ��̐ݒ�(�y�[�W�P��)
;		<d2.l:�����y�[�W�A�h���X
;		<a1.l:�_���y�[�W�A�h���X
;		>d0.l:�y�[�W����
;			-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓,�f�X�N���v�^�̗̈悪�s�����Ă���)
;	$F002	�_���y�[�W�̑����̎擾�Ɛݒ�
;		<d2.l:�y�[�W����
;			-1	�擾�̂�
;		<a1.l:�_���y�[�W�A�h���X
;		>d0.l:�ύX�O�̃y�[�W����
;			-1	�G���[
	.dc.l	VERSION
	.dc.l	'060T'
iocsSysStat::
	movem.l	d1-d2/a0,-(sp)
	cmpi.b	#4,$0CBC.w
	bhs	10f			;040/060�͂��ׂėL��
	cmp.w	#4,d1
	bhi	40f			;000/010/020/030�̓��[�h0-4�ȊO�̓G���[
	cmpi.b	#2,$0CBC.w
	bhs	10f			;020/030�̓��[�h0-4�͗L��
	tst.w	d1
	bne	40f			;000/010�̓��[�h0�ȊO�̓G���[
10:	lea.l	100f(pc),a0
20:	move.w	(a0)+,d0		;�I�t�Z�b�g
	beq	40f			;������Ȃ�����
	cmp.w	(a0)+,d1		;�ԍ�
	bne	20b
	jsr	(a0,d0.w)
30:	movem.l	(sp)+,d1-d2/a0
	rts

40:	moveq.l	#-1,d0
	bra	30b

100:	.dc.w	mpu_status-(*+4),$0000
	.dc.w	cache_get-(*+4),$0001
	.dc.w	cache_default-(*+4),$0002
	.dc.w	cache_flush-(*+4),$0003
	.dc.w	cache_set-(*+4),$0004
	.dc.w	sysStat_4000-(*+4),$4000
	.dc.w	sysStat_4001-(*+4),$4001
	.dc.w	sysStat_4002-(*+4),$4002
	.dc.w	sysStat_4003-(*+4),$4003
	.dc.w	sysStat_4004-(*+4),$4004
	.dc.w	sysStat_5000-(*+4),$5000
	.dc.w	sysStat_5001-(*+4),$5001
	.dc.w	sysStat_5002-(*+4),$5002
	.dc.w	sysStat_5003-(*+4),$5003
	.dc.w	sysStat_8000-(*+4),$8000
	.dc.w	sysStat_8001-(*+4),$8001
	.dc.w	sysStat_8004-(*+4),$8004
	.dc.w	sysStat_C000-(*+4),$C000
	.dc.w	sysStat_C001-(*+4),$C001
	.dc.w	sysStat_C002-(*+4),$C002
	.dc.w	sysStat_C003-(*+4),$C003
	.dc.w	sysStat_C004-(*+4),$C004
	.dc.w	sysStat_C005-(*+4),$C005
	.dc.w	sysStat_C006-(*+4),$C006
	.dc.w	sysStat_C007-(*+4),$C007
	.dc.w	sysStat_F000-(*+4),$F000
	.dc.w	sysStat_F001-(*+4),$F001
	.dc.w	sysStat_F002-(*+4),$F002
	.dc.w	0

;----------------------------------------------------------------
;$0000	MPU�X�e�[�^�X�擾
;>d0.l:MPU�X�e�[�^�X
;	bit31-16	MPU�̓�����g���BMHz�l*10
;	bit15		FPU/FPCP�̗L���B0=�Ȃ�,1=����
;	bit14		MMU�̗L���B0=�Ȃ�,1=����
;	bit7-0		MPU�̎�ށB0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
mpu_status::
	moveq.l	#12,d0			;000/010
	cmpi.b #2,$0CBC.w
	blo	10f
	moveq.l	#6,d0			;020/030/040/060
10:	mulu.w	$0CB8.w,d0		;000/010��MHz�l*1000/12�A020/030/040/060��MHz�l*1000/6�BMHz�l*1000
	add.l	#50,d0
	divu.w	#100,d0			;MHz�l*10
	swap.w	d0			;ssssssss ssssssss ........ ........
	clr.w	d0			;ssssssss ssssssss 00000000 00000000
	tst.b	$0CBE.w
	sne.b	d0			;ssssssss ssssssss 00000000 mmmmmmmm
	ror.w	#1,d0			;ssssssss ssssssss m0000000 0mmmmmmm
	tst.b	$0CBD.w
	sne.b	d0			;ssssssss ssssssss m0000000 ffffffff
	ror.w	#1,d0			;ssssssss ssssssss fm000000 0fffffff
	move.b	$0CBC.w,d0		;ssssssss ssssssss fm000000 pppppppp
	rts

;----------------------------------------------------------------
;$0001	�L���b�V���擾
;>d0.l:���݂̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON
;	bit0	���߃L���b�V����0=OFF,1=ON
;	000/010�̂Ƃ���0��Ԃ�
cache_get::
	moveq.l	#0,d0
	cmpi.b	#2,$0CBC.w
	blo	30f			;000/010
;020/030/040/060
	movec.l	cacr,d0
	cmpi.b	#4,$0CBC.w
	bhs	10f			;040/060
;020/030
					;........ ........ .......d .......i
	ror.l	#1,d0			;i....... ........ ........ d.......
	rol.b	#1,d0			;i....... ........ ........ .......d
	bra	20f
;040/060
10:					;d....... ........ i....... ........
	swap.w	d0			;i....... ........ d....... ........
	rol.w	#1,d0			;i....... ........ ........ .......d
20:	rol.l	#1,d0			;........ ........ ........ ......di
	and.l	#3,d0			;00000000 00000000 00000000 000000di
30:	rts

;----------------------------------------------------------------
;$0002	�L���b�V���ݒ�(SRAM�ݒ�l)
;>d0.l:�ݒ��̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON�ɂ���
;	bit0	���߃L���b�V����0=OFF,1=ON�ɂ���
;	000/010�̂Ƃ���0��Ԃ�
cache_default::
	move.l	d2,-(sp)
	moveq.l	#0,d2
	move.b	$00ED0090,d2		;�L���b�V���ݒ�B------|�f�[�^|����
	bsr	cache_set		;�L���b�V���ݒ�
	move.l	(sp)+,d2
	rts

;----------------------------------------------------------------
;$0003	�L���b�V���t���b�V��
cache_flush::
	cmpi.b	#2,$0CBC.w
	blo	20f			;000/010
;020/030/040/060
	cmpi.b	#4,$0CBC.w
	bhs	10f			;040/060
;020/030
	move.l	d0,-(sp)
	movec.l	cacr,d0
	or.w	#$0808,d0
	movec.l	d0,cacr
	move.l	(sp)+,d0
	bra	20f
;040/060
10:	cpusha	bc
20:	rts

;----------------------------------------------------------------
;$0004	�L���b�V���ݒ�
;<d2.l:�ݒ��̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON�ɂ���
;	bit0	���߃L���b�V����0=OFF,1=ON�ɂ���
;	000/010�̂Ƃ��͉������Ȃ�
;>d0.l:�ݒ�O�̃L���b�V���̏��
;	bit1	�f�[�^�L���b�V����0=OFF,1=ON������
;	bit0	���߃L���b�V����0=OFF,1=ON������
;	000/010�̂Ƃ���0��Ԃ�
cache_set::
	moveq.l	#0,d0
	cmpi.b	#2,$0CBC.w
	blo	50f			;000/010
;020/030/040/060
	movem.l	d1-d3,-(sp)
	moveq.l	#3,d3			;d3 00000000 00000000 00000000 00000011
	and.l	d3,d2			;d2 00000000 00000000 00000000 000000di
	ror.l	#1,d2			;   i0000000 00000000 00000000 0000000d
	movec.l	cacr,d0
	cmpi.b	#4,$0CBC.w
	bhs	10f			;040/060
;020/030
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
	bra	40f
;040/060
10:					;d0 d....... ........ i....... ........
	ror.w	#1,d2			;d2 i0000000 00000000 d0000000 00000000
	swap.w	d2			;   d0000000 00000000 i0000000 00000000
	move.l	d0,d1			;d1 d....... ........ i....... ........
	and.l	#.not.$80008000,d1	;   0....... ........ 0....... ........
	or.l	d2,d1			;   d....... ........ i....... ........
	movec.l	d1,cacr
	not.l	d2
	and.l	d0,d2			;�ݒ�O&~�ݒ��
	bpl	20f
;�f�[�^�L���b�V����ON��OFF
	cpusha	dc			;�f�[�^�L���b�V�����v�b�V�����Ė�����
20:	tst.w	d2
	bpl	30f
;���߃L���b�V����ON��OFF
	cinva	ic			;���߃L���b�V���ƕ���L���b�V���𖳌���
30:	swap.w	d0			;d0 i....... ........ d....... ........
	rol.w	#1,d0			;   i....... ........ ........ .......d
40:	rol.l	#1,d0			;   ........ ........ ........ ......di
	and.l	d3,d0			;   00000000 00000000 00000000 000000di
	movem.l	(sp)+,d1-d3
50:	rts

;----------------------------------------------------------------
;$8000	�o�[�W�����擾
;>d0.l:�o�[�W�����ԍ�
;>a1.l:'060T'
sysStat_8000::
	move.l	#VERSION,d0
	movea.l	#'060T',a1
	rts

;----------------------------------------------------------------
;$8001	�w��_���A�h���X�̃L���b�V�����[�h�̎擾
;<a1.l:�_���A�h���X
;>d0.l:�L���b�V�����[�h
;	0	�L���b�V������,���C�g�X���[
;	1	�L���b�V������,�R�s�[�o�b�N
;	2	�L���b�V���֎~,�X�g�A�o�b�t�@�֎~
;	3	�L���b�V���֎~,�X�g�A�o�b�t�@����
;	-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
sysStat_8001::
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bmi	8f			;�y�[�W�f�X�N���v�^���Ȃ�
	beq	9f			;��풓
	and.l	#PD_CM_MASK,d0		;�L���b�V�����[�h
	lsr.l	#PD_CM_BIT,d0
8:	POP_SFC_DFC	d1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;$8004	�w��_���A�h���X�̃L���b�V�����[�h�̐ݒ�(�y�[�W�P��)
;<d2.l:�L���b�V�����[�h
;	0	�L���b�V������,���C�g�X���[
;	1	�L���b�V������,�R�s�[�o�b�N
;	2	�L���b�V���֎~,�X�g�A�o�b�t�@�֎~
;	3	�L���b�V���֎~,�X�g�A�o�b�t�@����
;<a1.l:�_���A�h���X
;>d0.l:�ύX�O�̃L���b�V�����[�h
;	-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
sysStat_8004::
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc			;�y�[�W�f�X�N���v�^�𓾂�
	bmi	8f			;�y�[�W�f�X�N���v�^���Ȃ�
	beq	9f			;��풓
	move.l	d0,d1
	lsl.l	#PD_CM_BIT,d2
	and.l	#PD_CM_MASK,d2		;�V�����L���b�V�����[�h
	and.l	#.not.PD_CM_MASK,d1
	or.l	d1,d2
	moves.l	d2,(a0)			;�y�[�W�f�X�N���v�^��ύX����
					;setDesc��2�ӏ��ȏォ��Q�Ƃ���Ă����
					;�������Ă��܂�
	pflusha				;pflush (a1)�ł�
					;TM_USER_DATA,TM_USER_CODE,TM_SUPER_DATA,TM_SUPER_CODE
					;��4�Ƃ��t���b�V�����Ȃ���΂Ȃ�Ȃ�
	and.l	#PD_CM_MASK,d0
	lsr.l	#PD_CM_BIT,d0		;�ύX�O�̃L���b�V�����[�h
	cmp.b	#2,d0
	bcc	8f
;	and.l	#PAGE_MASK,d2
	movea.l	d2,a0
	cpushp	dc,(a0)
	cinvp	bc,(a0)
8:	POP_SFC_DFC	d1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;$C000	�݊����[�h
;>d0.l:
;	0	����I��
;	-1	���Ɍ݊����[�h�ɂȂ��Ă���
sysStat_C000::
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;$C001	�g�����[�h
;>d0.l:
;	0	����I��
;	-1	���Ɋg�����[�h�ɂȂ��Ă���
sysStat_C001::
	tst.b	useJointMode
	beq	9f
	tst.b	jointMode
	bne	9f
	move.l	jointBlockHeader,d0	;Human�{�̂̂��Ƃ�����
	beq	9f
	movea.l	d0,a0
	move.l	himemAreaStart,d0
	move.l	d0,(Next,a0)
	exg.l	d0,a0
	move.l	d0,(Prev,a0)
;;;	clr.l	(Next,a0)		;�����ł̓n�C�������������������Ȃ�
	move.l	himemAreaEnd,$1C00.w
	st.b	jointMode
	moveq.l	#0,d0
	rts

9:	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;$C002	���݂̃��[�h���擾����
;>d0.l:���[�h
;	0	�݊����[�h
;	1	�g�����[�h
sysStat_C002::
	tst.b	jointMode
	bne	@f
	moveq.l	#0,d0
	rts

@@:	moveq.l	#1,d1
	rts

;----------------------------------------------------------------
;$C003	���[�h�؂�ւ����V�O�i���̐ݒ�
;<a1.l:�V�O�i���n���h��
;>d0.l:
;	0	����I��
;	-1	�V�O�i�����I�[�o�[
sysStat_C003::
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;$C004	���[�h�؂�ւ����V�O�i���̉���
;<a1.l:�V�O�i���n���h��
;>d0.l:
;	0	����I��
;	-1	�s���ȃV�O�i���n���h��
sysStat_C004::
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;$C005	���������e�[�u���̎擾
;<a1.l:�e�[�u���i�[�A�h���X
sysStat_C005::
	suba.l	a1,a1
	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;$C006	�L���b�V���ƃX�[�p�[�X�P�[���̏�Ԃ̎擾
;>d0.l:�L���b�V���ƃX�[�p�[�X�P�[���̏��
;	bit0	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;	bit1	���߃L���b�V���̏��(0=OFF,1=ON)
;	bit2	�X�g�A�o�b�t�@�̏��(0=OFF,1=ON)
;	bit3	�u�����`�L���b�V���̏��(0=OFF,1=ON)
;	bit4	�X�[�p�[�X�P�[���̏��(0=OFF,1=ON)
sysStat_C006::
	moveq.l	#-1,d0
	cmpi.b	#6,$0CBC.w
	bne	90f
	movec.l	pcr,d1
	moveq.l	#1,d0
	and.l	d1,d0
	lsl.l	#8,d0
	movec.l	cacr,d1
	btst.l	#CACR_EBC_BIT,d1
	sne.b	d0
	lsl.l	#1,d0
	btst.l	#CACR_ESB_BIT,d1
	sne.b	d0
	lsl.l	#1,d0
	tst.w	d1	;	btst.l	#CACR_EIC_BIT,d1
	smi.b	d0	;	sne.b	d0
	lsl.l	#1,d0
	tst.l	d1	;	btst.l	#CACR_EDC_BIT,d1
	smi.b	d0	;	sne.b	d0
	lsr.l	#7,d0
90:	rts

;----------------------------------------------------------------
;$C007	�L���b�V���ƃX�[�p�[�X�P�[���̏�Ԃ̐ݒ�
;	�ݒ��A�������ɃL���b�V���̃v�b�V���Ɩ��������s���܂�
;<d2.l:�L���b�V���ƃX�[�p�[�X�P�[���̏��
;	bit0	�f�[�^�L���b�V���̏��(0=OFF,1=ON)
;	bit1	���߃L���b�V���̏��(0=OFF,1=ON)
;	bit2	�X�g�A�o�b�t�@�̏��(0=OFF,1=ON)
;	bit3	�u�����`�L���b�V���̏��(0=OFF,1=ON)
;	bit4	�X�[�p�[�X�P�[���̏��(0=OFF,1=ON)
;>d0.l:�ύX�O�̃L���b�V���ƃX�[�p�[�X�P�[���̏��
sysStat_C007::
	moveq.l	#-1,d0
	cmpi.b	#6,$0CBC.w
	bne	90f
	bsr	sysStat_C006
	movec.l	cacr,d1
	and.l	#.not.(CACR_EDC|CACR_ESB|CACR_EBC|CACR_EIC),d1
	lsr.l	#1,d2
	bcc	@f
	bset.l	#CACR_EDC_BIT,d1
@@:	lsr.l	#1,d2
	bcc	@f
	bset.l	#CACR_EIC_BIT,d1
@@:	lsr.l	#1,d2
	bcc	@f
	bset.l	#CACR_ESB_BIT,d1
@@:	lsr.l	#1,d2
	bcc	@f
	bset.l	#CACR_EBC_BIT,d1
@@:	movec.l	d1,cacr
	CACHE_FLUSH	d1
	movec.l	pcr,d1
	lsr.l	#1,d1
	lsr.l	#1,d2
	roxl.l	#1,d1
	movec.l	d1,pcr
90:	rts

;----------------------------------------------------------------
;$F000	�_���A�h���X���畨���A�h���X�����߂�
;<a1.l:�_���A�h���X
;>d0.l:�����A�h���X
;	$00000000�`$3FFFFFFF	�����A�h���X
;	-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
sysStat_F000::
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bmi	9f			;�y�[�W�f�X�N���v�^���Ȃ�
	beq	9f			;��풓
	and.l	pageMask,d0		;�y�[�W�̐擪�A�h���X
	move.l	a1,d1
	and.l	pageOffsetMask,d1	;�I�t�Z�b�g
	or.l	d1,d0			;�y�[�W�̐擪�A�h���X�ɃI�t�Z�b�g����������
8:	POP_SFC_DFC	d1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;$F001	�A�h���X�ϊ��̐ݒ�(�y�[�W�P��)
;	�ύX�O�̘_���y�[�W���L���������ꍇ�́A���̘_���y�[�W���w���Ă��������y�[�W��
;		�܂܂��L���b�V�����v�b�V������і��������܂�
;	�A�h���X�ϊ���ݒ肵�Ă��̕ϊ���L���ɂ��܂�
;<d2.l:�����y�[�W�A�h���X
;<a1.l:�_���y�[�W�A�h���X
;>d0.l:�y�[�W����
;	-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓,�f�X�N���v�^�̗̈悪�s�����Ă���)
sysStat_F001::
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bmi	9f
	beq	9f
	and.l	pageOffsetMask,d0
	and.l	pageMask,d2
	or.l	d0,d2
	moves.l	d2,(a0)
	pflusha
8:	POP_SFC_DFC	d1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;$F002	�_���y�[�W�̑����̎擾�Ɛݒ�
;	�Ԑڃy�[�W�f�X�N���v�^�͍폜����܂�
;<d2.l:�y�[�W����
;	0	��풓
;	-1	�擾�̂�
;<a1.l:�_���y�[�W�A�h���X
;>d0.l:�ύX�O�̃y�[�W����
;	-1	�G���[(�y�[�W�f�X�N���v�^���Ȃ�,��풓)
sysStat_F002::
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc
	bmi	9f
	tst.l	d2
	bmi	3f			;�擾�̂�
	beq	1f			;��풓
	move.l	d0,d1
	and.l	pageOffsetMask,d2
	and.l	pageMask,d1
	or.l	d1,d2
	moves.l	d2,(a0)
	bra	2f

1:	bsr	invDesc
	bmi	8f
2:	pflusha
3:	and.l	pageOffsetMask,d0
8:	POP_SFC_DFC	d1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;$4000	���[�J���������̏��̎擾
;>d0.l:���[�J���������̃o�C�g��
;	0	���[�J�����������Ȃ�
;	-1	�G���[
;>a1.l:���[�J���������̐擪�̕����A�h���X
sysStat_4000::
	move.l	localMemorySize,d0
	movea.l	localMemoryStart,a1
	rts

;----------------------------------------------------------------
;$4001	�����A�h���X�����[�J�����������w���Ă��邩���ׂ�
;<a1.l:�����A�h���X
;>d0.l:����
;	0	���[�J�����������w���Ă���
;	-1	���[�J���������ł͂Ȃ�
sysStat_4001::
	move.l	a1,d0
	bsr	physicalToLocal
	bmi	8f
	moveq.l	#0,d0
8:	rts

;----------------------------------------------------------------
;$4002	�_���A�h���X�����[�J�����������w���Ă��邩���ׂ�
;<a1.l:�_���A�h���X
;>d0.l:����
;	-1	�����Ș_���A�h���X�܂��̓��[�J���������ł͂Ȃ�
;	0	���[�J�����������w���Ă���
sysStat_4002::
	bsr	sysStat_F000
	bmi	8f
	bsr	physicalToLocal
	bmi	8f
	moveq.l	#0,d0
8:	rts

;----------------------------------------------------------------
;$4003	�_���A�h���X��DMA�]���\���ǂ������ׂ�
;<a1.l:�_���A�h���X
;>d0.l:����
;	-1	DMA�]���s�\
;	0	DMA�]���\
sysStat_4003::
	moveq.l	#0,d0			;�������֏�������
	move.l	a1,d1			;�擪
	move.l	d1,d2			;����+1
	bsr	dmaAccessCheck
	smi.b	d0			;-1=DMA�]���s�\,0=DMA�]���\
	extb.l	d0
	rts

;----------------------------------------------------------------
;$4004	�_���A�h���X�͈̔͂�DMA�]���\���ǂ������ׂ�
;<d2.l:�T�C�Y
;<a1.l:�_���A�h���X
;>d0.l:����
;	-1	DMA�]���s�\
;	0	DMA�]���\
sysStat_4004::
	moveq.l	#0,d0			;�������֏�������
	move.l	a1,d1			;�擪
	add.l	d1,d2			;����+1
	bsr	dmaAccessCheck
	smi.b	d0			;-1=DMA�]���s�\,0=DMA�]���\
	extb.l	d0
	rts

;----------------------------------------------------------------
;$5000	���s�v���O���������[�J���������Ƀ��[�h���Ď��s����
;<d2.l:���W���[���ԍ�*256
;<a1.l:���s�t�@�C����
;<a2.l:�R�}���h���C��
;<a3.l:���̃A�h���X
;>d0.l:_EXEC�̕ԋp�l
sysStat_5000::
	movem.l	d1-d7/a1-a6,-(sp)
	movem.l	a1-a3,-(sp)
	clr.b	d2
	move.w	d2,-(sp)
	st.b	execLoadHigh
	DOS	_EXEC
	clr.b	execLoadHigh
	lea.l	(14,sp),sp
	movem.l	(sp)+,d1-d7/a1-a6
	rts

;----------------------------------------------------------------
;$5001	���ݎ��s���̃v���Z�X���I�����Ă���,
;	�w�肳�ꂽ���s�v���O���������[�J���������Ƀ��[�h���Ď��s��,
;	�e�v���Z�X�ɕ��A����
;<d2.l:���[�h+���W���[���ԍ�*256
;	bit0	1=���[�J�����������s�����Ă����烁�C���������Ŏ��s����
;<a1.l:���s�t�@�C����
;<a2.l:�R�}���h���C��
;<a3.l:���̃A�h���X(0=�e�v���Z�X�̊�,���s���̃v���Z�X�̗̈�͕s��)
;���A���Ȃ�(_EXEC�̕ԋp�l��e�v���Z�X�ɕԂ�)
sysStat_5001::
;���s�t�@�C�����ƃR�}���h���C�����R�s�[����
;(�w�肳�ꂽ������͎��s�O�ɉ���\�������邽��)
  debug '|5001(d2,a1,a2,a3)',4,d2,a1,a2,a3
	lea.l	(5f,pc),a0
	move.w	#255-1,d0
@@:	move.b	(a1)+,(a0)+
	dbeq	d0,@b
	clr.b	(a0)
	movea.l	userAreaWork,a0		;�R�}���h���C���̓��[�U���[�h�̗̈�ɃR�s�[����K�v������
	cmpi.l	#'#HUP',(-8,a2)
	bne	1f
	cmpi.l	#'AIR'<<8,(-4,a2)
	bne	1f
	move.l	#'#HUP',(a0)+
	move.l	#'AIR'<<8,(a0)+
	move.w	#4096-256-8-1,d0
@@:	move.b	(a2)+,(a0)+
	dbeq	d0,@b
	move.w	#256-1,d0
	bra	2f

1:	clr.l	(a0)+
	clr.l	(a0)+
	move.w	#4096-8-1,d0
2:	move.b	(a2)+,(a0)+
	dbeq	d0,2b
	clr.b	(a0)
;���̃A�h���X��ۑ�����
	move.l	a3,7f
;���݂̃A�{�[�g����sr��_EXITVC��ۑ�����
	movea.l	([$1C28.w]),a0		;���ݎ��s���̃v���Z�X�̃������Ǘ��e�[�u���̐擪
  debug '|5001(psp)',1,a0
	move.w	(p_Sr,a0),3f		;sr
	move.l	(pExitvc,a0),4f		;_EXITVC
  debugWord '|5001(sr)',1,3f
  debug '|5001(exitvc)',1,4f
;���[�h��ۑ�����
	move.w	d2,8f
;�A�{�[�g����sr��_EXITVC��ύX���Ă���v���Z�X���I������
	move.w	#$2000,(p_Sr,a0)	;sr��ύX����
					;060turbo.sys���X�[�p�[�o�C�U�̈�ɂ���̂�,
					;�X�[�p�[�o�C�U���[�h�Ŗ߂�K�v������
	move.l	#1f,(pExitvc,a0)	;_EXITVC��ύX����
	DOS	_EXIT			;�e�v���Z�X�ɖ߂�

;�e�v���Z�X��_EXEC�̒���ɔ�ԑ���ɂ���������s
1:
  debug '|5001(d0)',1,d0
	tst.w	d0
	bne	9f			;�A�{�[�g�����Ƃ��̓X�L�b�v(�O�̂���)
					;(_EXIT��0�ȊO(����$4000)���Ԃ����Ƃ�)
;���[�J���������Ƀ��[�h
  debug '|5001(try8001)',0
	move.l	7f,-(sp)
	pea.l	([userAreaWork],8)
	pea.l	(5f,pc)
	move.w	#1,-(sp)
	move.b	8f,(sp)			;���W���[���ԍ�
	st.b	execLoadHigh
	DOS	_EXEC			;���[�J���������Ƀ��[�h
	clr.b	execLoadHigh
	lea.l	(14,sp),sp
  debug '|5001(8001)',1,d0
	tst.l	d0
	bpl	2f
	cmp.l	#$FFFF0000,d0
	bcc	9f			;�������s���ȊO�̃G���[
;���C���������Ƀ��[�h
	btst.b	#0,8f+1
	beq	9f			;���C���������͎g��Ȃ�
  debug '|5001(try0001)',0
	move.l	7f,-(sp)
	pea.l	([userAreaWork],8)
	pea.l	(5f,pc)
	move.w	#1,-(sp)
	move.b	8f,(sp)			;���W���[���ԍ�
	DOS	_EXEC			;���C���������Ƀ��[�h
	lea.l	(14,sp),sp
	tst.l	d0
	bmi	9f
;���s
2:
  debug '|5001(loadok)',1,d0
  debug '|5001(try0004)',0
	clr.w	-(sp)			;_EXEC�̒��ōċA����\��������̂Ő�ɃX�^�b�N�ɐς�ł���
	move.l	4f,-(sp)		;_EXITVC
	move.w	3f,-(sp)		;sr
	move.l	d0,-(sp)
	move.w	#4,-(sp)
	DOS	_EXEC			;���s
	addq.l	#6,sp
  debug '|5001(done)',1,d0
	rte

;�������Ȃ��ŏI��
9:	clr.w	-(sp)
	move.l	4f,-(sp)		;_EXITVC
	move.w	3f,-(sp)		;sr
  debug '|5001(error)',1,d0
	rte

3:	.ds.w	1	;sr
4:	.ds.l	1	;_EXITVC
5:	.ds.b	256	;���s�t�@�C����
7:	.ds.l	1	;���̃A�h���X
8:	.ds.w	1	;���[�h+���W���[���ԍ�*256
	.even

;----------------------------------------------------------------
;$5002	defaultLoadArea�̎w��
;<d2.l:���[�h���郁������Ԃ̎w��
;	0	���ʂ̂�
;	1	��ʂ̂�
;	2	�e�Ɠ������̂�
;	3	�e�Ɣ��Α��̂�
;	4	�����Ȃ�,���ʗD��
;	5	�����Ȃ�,��ʗD��
;	6	�����Ȃ�,�e�Ɠ������D��
;	7	�����Ȃ�,�e�Ɣ��Α��D��
;	8	�����Ȃ�,�D��Ȃ�
;>d0.l:�ύX�O�̎w��
sysStat_5002::
	moveq.l	#0,d0
	move.b	defaultLoadArea,d0
	cmp.l	#-1,d2
	beq	1f
	cmp.l	#9,d2
	bcc	9f
	move.b	d2,defaultLoadArea
1:	rts

9:	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;$5003	defaultAllocArea�̎w��
;<d2.l:�A���P�[�g���郁������Ԃ̎w��
;	0	���ʂ̂�
;	1	��ʂ̂�
;	2	�e�Ɠ������̂�
;	3	�e�Ɣ��Α��̂�
;	4	�����Ȃ�,���ʗD��
;	5	�����Ȃ�,��ʗD��
;	6	�����Ȃ�,�e�Ɠ������D��
;	7	�����Ȃ�,�e�Ɣ��Α��D��
;	8	�����Ȃ�,�D��Ȃ�
;>d0.l:�ύX�O�̎w��
sysStat_5003::
	moveq.l	#0,d0
	move.b	defaultAllocArea,d0
	cmp.l	#-1,d2
	beq	1f
	cmp.l	#9,d2
	bcc	9f
	move.b	d2,defaultAllocArea
1:	rts

9:	moveq.l	#-1,d0
	rts

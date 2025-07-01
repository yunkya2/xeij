;----------------------------------------------------------------
;
;	Human�̃p�b�`
;
;----------------------------------------------------------------

	.include	t02const.equ

	.cpu	68060

;----------------------------------------------------------------
;Human302�Ƀp�b�`�����Ă��邩�ǂ����`�F�b�N����
;>d0.l:0=����,-1=���s
;>n-flag:pl=����,mi=���s
patchCheckHuman302::
	move.l	a0,-(sp)
	lea.l	(human302Patch,pc),a0
	bsr	patchCheck
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;Human302�Ƀp�b�`�����Ă�
;>d0.l:0=����,-1=���s
;>n-flag:pl=����,mi=���s
patchHuman302::
	move.l	a0,-(sp)
	lea.l	(human302Patch,pc),a0
	bsr	patch
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;�p�b�`�����Ă��邩�ǂ����`�F�b�N����
;<a0.l:�p�b�`�f�[�^�̃A�h���X
;>d0.l:0=����,-1=���s
;>n-flag:pl=����,mi=���s
patchCheck::
	movem.l	a1-a2,-(sp)
	movea.l	a0,a1
	move.l	(a1)+,d0
1:	movea.l	d0,a2			;�p�b�`�A�h���X
	move.w	(a1)+,d1		;���[�h��-1
2:	cmpm.w	(a1)+,(a2)+		;��r
	dbne	d1,2b
	bne	9f			;��v���Ȃ��̂Ńp�b�`�����ĂȂ�
	move.w	(a1)+,d1		;���[�h��-1
	lea.l	(2,a1,d1.w*2),a1	;�V������Ԃ��X�L�b�v����
	move.l	(a1)+,d0
	bne	1b
8:	movem.l	(sp)+,a1-a2
	rts

9:
  .if 1
	lea.l	-64(sp),sp
	movea.l	sp,a0
	lea.l	100f(pc),a1
	bsr	strcpy
	move.l	a2,d0
	subq.l	#2,d0
	bsr	hex8
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	movea.l	sp,a1
	bsr	print
	lea.l	64(sp),sp
  .endif
	moveq.l	#-1,d0
	bra	8b

  .if 1
100:	.dc.b	'patchCheck failed at ',0
	.even
  .endif

;----------------------------------------------------------------
;�p�b�`�����Ă�
;<a0.l:�p�b�`�f�[�^�̃A�h���X
;>d0.l:0=����,-1=���s
;>n-flag:pl=����,mi=���s
patch::
	movem.l	d1/a1-a2,-(sp)
	PUSH_SR_DI
	bsr	patchCheck
	bmi	8f
	movea.l	a0,a1
	move.l	(a1)+,d0
1:	movea.l	d0,a2			;�p�b�`�A�h���X
	move.w	(a1)+,d1
	lea.l	(2,a1,d1.w*2),a1	;���̏�Ԃ��X�L�b�v����
	move.w	(a1)+,d1		;���[�h��
2:	move.w	(a1)+,(a2)+		;�ύX
	dbra	d1,2b
	move.l	(a1)+,d0
	bne	1b
	CACHE_FLUSH	d1
8:	POP_SR
	movem.l	(sp)+,d1/a1-a2
	tst.l	d0
	rts

;----------------------------------------------------------------
;
;	Human302�̃p�b�`�f�[�^(��풓��)
;
;----------------------------------------------------------------
;Human302�Ƀp�b�`�����Ă�O�̏��
;	�����`�F�b�N�ƌ��ɖ߂��Ƃ��Ɏg���̂ŁA
;	�p�b�`�f�[�^�ȏ�̃T�C�Y�̃R�[�h���L�q����K�v������
;Human302�Ƀp�b�`�����Ă���̏��
;	�p�b�`�f�[�^�͊m�����K�v�ŏ����ɂƂǂ߂�
;	���ɖ߂��Ƃ��̓`�F�b�N�̑O�Ƀ����P�[�g���Ă����K�v������
;
;�p�b�`���[�`���ɃW�����v����̂łȂ���ΕύX�O�ƕύX��̃T�C�Y�����킹�邱��
;
;MOVE from SR��F-Line�Ɠ����ᔽ�ŋz�������̂Ńp�b�`����K�v���Ȃ�

human302Patch::
	.dc.l	$000068FE
	.dc.w	(2f-1f)/2-1
1:	bsr.w	(*)-$000068FE+$00006A96	;�X�[�p�[�o�C�U�̈�ݒ�
	pea.l	$00008566.l		;�A�{�[�g�x�N�^�ݒ�
2:
	.dc.w	(2f-1f)/2-1
1:	jsr	human302_superarea.l
	pea.l	((*)-$00006904+$00008566,pc)
2:

;_EXEC	[3]���s�t�@�C���̌`���w��
	.dc.l	$00009510
	.dc.w	(2f-1f)/2-1
1:	bsr.w	(*)-$9510+$997C
	cmp.b	#'x',d0
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_exec3pat
2:

;_EXEC	[0][1]���s�t�@�C���̌`���w��
	.dc.l	$0000961A
	.dc.w	(2f-1f)/2-1
1:	move.l	a1,$1CB2.w
	bsr.w	(*)-$961E+$997C
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_exec01pat
2:

;_PSPSET�̒ǉ�
	.dc.l	$0000938C
	.dc.w	(2f-1f)/2-1
1:	add.l	a0,d3
	add.l	#$00000100,d3
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_makePsp
2:

;_EXEC�̎��s�O�̏���
	.dc.l	$0000967E
	.dc.w	(2f-1f)/2-1
1:	bsr.w	(*)-$967E+$98A0		;bss+comm+stack��0�ŏ���������
	move.b	#-3,$1CA0.w		;_EXEC�̓��샌�x��
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_execMakePsp
2:

;_EXEC	�X�[�p�[�o�C�U���[�h�I��
	.dc.l	$00009748
	.dc.w	(2f-1f)/2-1
1:	and.l	#$00FFFFFF,D0
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_execsuperpat
2:

  .if 0
;68030�̂Ƃ�XEiJ�̃p�b�`�ƏՓ˂���
;_EXEC	�A���P�[�g���[�h�`�F�b�N�̃o�O
	.dc.l	$000099C4
	.dc.w	(2f-1f)/2-1
1:	btst.l	#1,d1
2:
	.dc.w	(2f-1f)/2-1
1:	btst.l	#0,d1
2:
  .endif

;_KEEPPR	�풓�t���O�̐ݒ�
	.dc.l	$0000A064
	.dc.w	(2f-1f)/2-1
1:	ori.l	#$FF000000,(4,a0)
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_keeppr
2:

;_FATCHK	�g�����[�h�r�b�g�̏���
	.dc.l	$0000B162
	.dc.w	(2f-1f)/2-1
1:	and.l	#$00FFFFFF,d6
2:
	.dc.w	(2f-1f)/2-1
1:	and.l	#$7FFFFFFF,d6
2:

;�f�o�C�X�h���C�o�̌Ăяo��
	.dc.l	$0000DEFA
	.dc.w	(2f-1f)/2-1
1:	cmpi.b	#1,$0CBC.w
2:
	.dc.w	(2f-1f)/2-1
1:
patchHumanCallDevice::
	jmp	callDevice		;RAMDISK���Ȃ��Ƃ���callDeviceNoRamdisk�ɕύX
2:

;�f�o�C�X�h���C�o���畜�A��������̃L���b�V���̕���
;(060turbo.sys����߂����Ƃ������g�p�����)
	.dc.l	$0000DF38
	.dc.w	(2f-1f)/2-1
1:	moveq.l	#$04,d1			;�L���b�V���̐ݒ�
2:
	.dc.w	(2f-1f)/2-1
1:	moveq.l	#$02,d1			;�L���b�V����SRAM�ݒ�l�ɏ�����
2:

;�o�X�G���[�`�F�b�N
	.dc.l	$0000E28A
	.dc.w	(2f-1f)/2-1
1:	move.w	sr,-(sp)
	ori.w	#$0700,sr
2:
	.dc.w	(2f-1f)/2-1
1:	jmp	human302_buserr
2:

;DISK2HD�f�o�C�X�h���C�o�̏������[�`���̎擾�Ɛݒ�
	.dc.l	$00010A20
	.dc.w	(2f-1f)/2-1
1:	move.w	(a6)+,(a4)+
	dbra.w	d0,1b
2:
	.dc.w	(2f-1f)/2-1
1:	jsr	human302_disk2hd_jmp
2:

	.dc.l	0

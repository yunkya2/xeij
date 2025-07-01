;----------------------------------------------------------------
;
;	RAMDISK�h���C�o
;
;----------------------------------------------------------------

	.cpu	68060

;----------------------------------------------------------------
;RAMDISK�h���C�o�̓]�����x�Ɋւ��郁��
;	68060�͊�Ԓn�̃����O���[�h�]�����\�����L���b�V�����~�X����Ɣ��ɒx���Ȃ�
;	�L���b�V���ł��L���b�V��������Ƃ��̓R�s�[�o�b�N�������C�g�X���[�̕�������
;	move16�͓]���O��̃A�h���X�̉���4�r�b�g����v���Ă���K�v������
;	move16�̓L���b�V�����[�h�ɂ�炸�]�����x�����
;		move16�̓ǂݏo���̓R�s�[�o�b�N�L���b�V���̃_�[�e�B�f�[�^���ǂݏo����
;		move16�̏������݂̓f�[�^�L���b�V���ɂ����C�g�A���P�[�g�����
;		�܂�R�s�[�o�b�N�̈�̃A�N�Z�X��move16�������Ă����͐����Ȃ�
;	��ʓ]���̏��v����
;		wt,cb�ŃL���b�V�����q�b�g����Ƃ�
;			move<movem<move16
;		wt,cb�ŃL���b�V�����q�b�g���Ȃ��Ƃ�
;			move16<move<movem
;		is,ps�̂Ƃ�
;			move16<movem<move
;		move,movem�̂Ƃ�
;			wt<cb<is<ps
;		move16�̂Ƃ�
;			wt=cb=is=ps
;	RAMDISK�̈���L���b�V���ɂ���̂̓f�[�^�L���b�V����H���ׂ������Ŗ��Ӗ�
;	RAMDISK�̈�̓L���b�V���s�ɂ���move16�œ]������̂��]�܂���
;	move16���g���Ȃ���΃��C�g�X���[�ɂ���move�œ]������̂��]�܂���
;
;	requestHeader�͐ݒ肳��Ă��Ȃ��ꍇ������̂Ŏg��Ȃ�����

;----------------------------------------------------------------
;���f�B�A�`�F�b�N
;<a5.l:���N�G�X�g�w�b�_
deviceCheck::
	move.b	(1,a5),d0		;���j�b�g�ԍ�
	bsr	mediaCheck
	sne.b	(14,a5)			;0=����,-1=���Ă���
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;��Ԏ擾
;<a5.l:���N�G�X�g�w�b�_
deviceSense::
	move.b	(1,a5),d0
	bsr	mediaCheck
	bne	1f
;		   �C�W�F�N�g�֎~
;		   |
;		   |
;		   |  �v���e�N�g
;		   |  |���f�B
;		   |  ||���f�B�A�}��
;		   |  |||��}��
;		   |  ||||
	move.b	#%01000010,(13,a5)
	bra	2f
1:	move.b	#%01000100,(13,a5)
2:	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;���f�B�A�`�F�b�N���[�`��
;	RAMDISK.SYS�Ɠ������擪��3�o�C�g�����`�F�b�N���Ă���
;	�{���͂����ƌ����ɒ��ׂ��ق����悢
;<d0.b:���j�b�g�ԍ�
;>d0.w:���j�b�g�ԍ�
;>z-flag:eq=OK,ne=ERROR
;*d0
mediaCheck::
	move.l	a0,-(sp)
	ext.w	d0
	movea.l	([bpbTablePointer,d0.w*4],16),a0
	cmpi.w	#$F9FF,(a0)+
	bne	@f
	cmpi.b	#$FF,(a0)
@@:	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;���Ă��ē��o�͂ł��Ȃ��Ƃ�
mediaError:
	move.w	#$5007,d0
	rts

;----------------------------------------------------------------
;�o��
;	�o�͂̂Ƃ��̓��f�B�A�`�F�b�N�����ăG���[���o���Ă͂Ȃ�Ȃ�
;	(�t�H�[�}�b�g�ł��Ȃ��Ȃ�̂�)
;<a5.l:���N�G�X�g�w�b�_
deviceOutput::
	movem.l	d1-d2/a0-a3,-(sp)
	move.l	(14,a5),d0		;�o�b�t�@�̐擪
;<d0.l:�o�b�t�@�̐擪
	cmpi.b	#4,$0CBC.W
	blo	@f
	lea.l	(outputMove16,pc),a0
	moveq.l	#$0F,d2
	and.l	d0,d2
	beq	transfer
@@:	lea.l	(outputMove,pc),a0
	bra	transfer

;----------------------------------------------------------------
;����
;<a5.l:���N�G�X�g�w�b�_
deviceInput::
	move.b	(1,a5),d0
	bsr	mediaCheck
	bne	mediaError		;���Ă���
	movem.l	d1-d2/a0-a3,-(sp)
	move.l	(14,a5),d0		;�o�b�t�@�̐擪
;<d0.l:�o�b�t�@�̐擪
	cmpi.b	#4,$0CBC.W
	blo	@f
	lea.l	(inputMove16,pc),a0
	moveq.l	#$0F,d2
	and.l	d0,d2
	beq	transfer
@@:	lea.l	(inputMove,pc),a0
;	bra	transfer
;----------------------------------------------------------------
;�]�����[�`��
;<d0.l:�o�b�t�@�̐擪
;<a5.l:���N�G�X�g�w�b�_
transfer:
	movea.l	d0,a2
;<a2.l:�o�b�t�@�̐擪
	moveq.l	#0,d0
	move.b	(1,a5),d0		;���j�b�g�ԍ�
	movea.l	(bpbTablePointer,d0.l*4),a3	;BPB�e�[�u���̃A�h���X
	bsr	toggleAccessLamp	;�A�N�Z�X�����v���]
;<a1.l:BPB�e�[�u���̃A�h���X
	move.l	(18,a5),d0
;<d0.l:�]���Z�N�^��
	move.l	d0,d1
;<d1.l:�]���Z�N�^��
	move.l	(22,a5),d2
;<d2.l:�擪�̃Z�N�^�ԍ�
	add.l	d2,d1
;<d1.l:�����̃Z�N�^�ԍ�+1
	cmp.l	(12,a3),d1
	bhi	sectorError		;�͈͊O
	lsl.l	#8,d2
	lsl.l	#2,d2
;<d2.l:�擪�̃Z�N�^�܂ł̃I�t�Z�b�g
	movea.l	(16,a3),a1		;�擪�A�h���X
	adda.l	d2,a1
;<a1.l:�擪�̃Z�N�^�̃A�h���X
	jsr	(a0)			;�]��
	moveq.l	#0,d0
transferError:
	bsr	toggleAccessLamp	;�A�N�Z�X�����v���]
	movem.l	(sp)+,d1-d2/a0-a3
	rts

;�Z�N�^�ԍ��̎w�肪��������
sectorError:
	move.w	#$5008,d0
	bra	transferError

;----------------------------------------------------------------
;�A�N�Z�X�����v���]
;<a3.l:BPB�e�[�u���̃A�h���X
toggleAccessLamp:
	tst.b	(24,a3)
	beq	@f
	bset.b	#0,$00E8A01B		;TIMER-LED���]
	eori.b	#%00000111,$00E8A001	;
@@:	rts

;----------------------------------------------------------------
;�o��(�o�b�t�@�A�h���X�̉���4bit��0)
outputMove16:
	exg.l	a1,a2
;	bra	transferMove16
;----------------------------------------------------------------
;����(�o�b�t�@�A�h���X�̉���4bit��0)
inputMove16:
;	bra	transferMove16
;----------------------------------------------------------------
;���o��(�o�b�t�@�A�h���X�̉���4bit��0)
;<d0.l:�]���Z�N�^��
;<a1.l:�]�����A�h���X(����4bit��0)
;<a2.l:�]����A�h���X(����4bit��0)
transferMove16:
@@:	moveq.l	#4-1,d1
1:	.rept	16
	move16	(a1)+,(a2)+
	.endm
	dbra	d1,1b
	subq.l	#1,d0
	bne	@b
	rts

;----------------------------------------------------------------
;�o��(�o�b�t�@�A�h���X�̉���4bit��0�łȂ�)
outputMove:
	exg.l	a1,a2
;	bra	transferMove
;----------------------------------------------------------------
;����(�o�b�t�@�A�h���X�̉���4bit��0�łȂ�)
inputMove:
;	bra	transferMove
;----------------------------------------------------------------
;���o��(�o�b�t�@�A�h���X�̉���4bit��0�łȂ�)
;<d0.l:�]���Z�N�^��
;<a1.l:�]�����A�h���X
;<a2.l:�]����A�h���X
transferMove:
@@:	moveq.l	#16-1,d1
1:	.rept	16
	move.l	(a1)+,(a2)+
	.endm
	dbra	d1,1b
	subq.l	#1,d0
	bne	@b
	rts

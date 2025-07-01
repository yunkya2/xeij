;----------------------------------------------------------------
;
;	��O�n���h��
;
;----------------------------------------------------------------

	.include	t02const.equ

	.cpu	68060

;----------------------------------------------------------------
;
;	�A�N�Z�X�G���[��O
;
;----------------------------------------------------------------
accessError::
	btst.b	#FSLW_BPE_BIT,($000C+3,sp)	;FSLW��BPE�r�b�g���e�X�g����
	bne	branchPredictionError	;BPE�r�b�g���Z�b�g����Ă����番��\���G���[
	jmp	([vectorOldAccessError])

;----------------------------------------------------------------
;
;	����\���G���[
;
;----------------------------------------------------------------
branchPredictionError::
;����L���b�V�����N���A����
	move.l	d0,-(sp)
	movec.l	cacr,d0
	bset.l	#CACR_CABC_BIT,d0	;����L���b�V�����N���A
	movec.l	d0,cacr			;CABC�r�b�g��read�͏��0�Ȃ̂Ō��ɖ߂��K�v�͂Ȃ�
	move.l	(sp)+,d0
;�}�j���A���ł�BPE�ȊO��BusError���������Ă��Ȃ����Ƃ��m�F���Ă���rte����悤��
;������Ă��邪�A���̂��K��WE�r�b�g���Z�b�g����Ă��܂��Ă���̂ŁA�Ƃ肠����
;�������ĕ��A����
	rte


;----------------------------------------------------------------
;----------------------------------------------------------------
UNIMPLEMENTED_INTEGER	equ	5
;MOVEP�G�~�����[�V�������[�`���̗���
;1	�`v0.47
;		�X�^�b�N�Ƀ��W�X�^�e�[�u���𐶐�
;		ROM 1.5(97/03/26,97/05/29)������Ɠ���
;2	v0.49�`v0.51
;		�X�[�p�[�X�P�[�����ӎ����čœK��
;		�G���o�O������,�p�^�[���ɂ���Ă͐������G�~�����[�g�ł��Ȃ�
;		�G�~�����[�g���̊��荞�݂ɂ���ăf�[�^���j�󂳂��
;3	v0.52
;		�p�^�[���ɂ���Đ������G�~�����[�g�ł��Ă��Ȃ��������������C��
;		���荞�݂ɂ��f�[�^�j��͖��C��
;4	v0.53
;		���荞�݂ɂ��f�[�^�j����C��,����
;5(97/08/17,97/09/15)
;		�X�^�b�N�̃��W�X�^�e�[�u�������,���W�X�^�ԍ��ŕ���
;		MOVEP�G�~�����[�V�������[�`�������Ȃ�傫���Ȃ���
;		�����A�h���X�̃A�N�Z�X�E�F�C�g�𑽏��l��
;6(�\��)
;		�����A�h���X�̃A�N�Z�X�E�F�C�g��ϋɓI�Ɋ��p����
;		<ea>��Dn�̏��Ŋm�肵,�ǂݏo�����͓ǂݏo���Ȃ���Dn���m�肷��
;		�������ݎ��͏������݂Ȃ��璼��̖��߂�MOVEP�łȂ�������,
;		MOVEP�������Ă������O�������畜�A�����ɃG�~�����[�g�𑱂���
;		�����A�h���X�̃A�N�Z�X�̍Œ���,�Ȃ�ׂ����̃A�h���X���A�N�Z�X���Ȃ�
;		(�L���b�V�����~�X����Ƃ����ő҂�����邽��)
;		�X�g�A�o�b�t�@�̌��ʂ�,1��ڂ̏������݂͂����ɕ��A����\��������
;		������@������



  .if UNIMPLEMENTED_INTEGER=1



;----------------------------------------------------------------
;
;	�������������ߗ�O
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP�ȊO�̖�������������
ispCall:
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movea.l	(sp)+,a0
	lea.l	(4*(8-1),sp),sp
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;MOVEP�Ń��[�U���[�h�̂Ƃ�
_movepUser:
	move.l	usp,a1			;��O��������usp
	move.l	a1,(4*15,sp)		;��O��������sp
	bra	_movepSuper

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;�������������ߗ�O�������[�`��
;	MOVEP�������ʈ����ɂ��č����ɏ������Ă��܂�
;	���̑��̖������������߂̏�����ISP�ɔC���܂�
_060_isp_unint::
	pea.l	(8,sp)			;��O��������ssp
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	(4*16+2,sp),a0		;��O��������pc
;<a0.l:��O��������pc
	move.w	(a0)+,d1		;���߃R�[�h
;<d1.w:��O��������(pc).w
;MOVEP��
	move.w	d1,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP����
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	�t�@���N�V�����R�[�h�̃`�F�b�N/�ύX����؍s���Ă��܂���
;	�]�����̃A�N�Z�X�G���[���l�����Ă��܂���
;	���̂悤�Ȉُ�ȃ���������͐������G�~�����[�g�ł��܂���
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<d1.w:��O��������(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a0.l:��O��������pc+2
;<sp.l:�X�^�b�N�ɗ�O�������̃��W�X�^�̓��e��ێ�
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	ssp
;	0040	.w	sr
;	0042	.l	pc		pc�͎��̖��߂̃A�h���X�ɍX�V���邱��
;	0046	.w	�x�N�^�I�t�Z�b�g
;	0048		ssp�̈ʒu
_movep:
	btst.b	#5,(4*16,sp)		;��O��������sr��S
	beq	_movepUser		;�X�[�p�[�o�C�U���[�h��D��
_movepSuper:
;<sp.l:�X�^�b�N�ɗ�O�������̃��W�X�^�̓��e��ێ�
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	usp�܂���ssp
;	0040	.w	sr
;	0042	.l	pc		pc�͎��̖��߂̃A�h���X�ɍX�V���邱��
;	0046	.w	�x�N�^�I�t�Z�b�g
;	0048		ssp�̈ʒu
;�����A�h���X�����߂�
	moveq.l	#7,d0			;0000000000000111
	and.w	d1,d0			;0000000000000aaa
	movea.l	(4*8,sp,d0.w*4),a1	;�A�h���X���W�X�^�̓��e
	adda.w	(a0)+,a1		;�f�B�X�v���[�X�����g��������
;<a0.l:��O��������pc+4
;<a1.l:�����A�h���X
;���A�A�h���X���X�V����
	move.l	a0,(4*16+2,sp)		;���A�A�h���X���X�V
;�f�[�^���W�X�^�̃A�h���X�����߂�
	move.w	d1,d0			;0000ddd1ws001aaa
	lsr.w	#8,d0			;000000000000ddd1
	lea.l	(-2,sp,d0.w*2),a0	;00000000000ddd10
					;00000000000ddd00
					;�f�[�^���W�X�^�̃A�h���X
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;�I�y���[�V�������[�h�ɏ]���ē]������
	add.b	d1,d1
	bcc	_movepRead		;write��D��
;���W�X�^��������
;	MOVEP.{WL} Dx,(d16,Ay)
_movepWrite:
	bpl	_movepWriteWord		;�����O���[�h��D��
;���W�X�^��������,�����O���[�h
;	MOVEP.L Dx,(d16,Ay)
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepWriteLong:
	move.b	(a0)+,(a1)
	move.b	(a0)+,(2,a1)
	move.b	(a0)+,(4,a1)
	move.b	(a0),(6,a1)
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movem.l	(sp)+,a0-a1
	lea.l	(4*(8-2),sp),sp
	rte

;���W�X�^��������,���[�h
;	MOVEP.W Dx,(d16,Ay)
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepWriteWord:
	addq.w	#2,a0
	move.b	(a0)+,(a1)
	move.b	(a0),(2,a1)
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movem.l	(sp)+,a0-a1
	lea.l	(4*(8-2),sp),sp
	rte

;�����������W�X�^
;	MOVEP.{WL} (d16,Ay),Dx
_movepRead:
	bpl	_movepReadWord		;�����O���[�h��D��
;�����������W�X�^,�����O���[�h
;	MOVEP.L	(d16,Ay),Dx
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepReadLong:
	move.b	(a1),(a0)+
	move.b	(2,a1),(a0)+
	move.b	(4,a1),(a0)+
	move.b	(6,a1),(a0)
	movem.l	(sp)+,d0-d7/a0-a1
	lea.l	(4*(8-2),sp),sp
	rte

;�����������W�X�^,���[�h
;	MOVEP.W (d16,Ay),Dx
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepReadWord:
	addq.w	#2,a0
	move.b	(a1),(a0)+
	move.b	(2,a1),(a0)
	movem.l	(sp)+,d0-d7/a0-a1
	lea.l	(4*(8-2),sp),sp
	rte



  .elseif UNIMPLEMENTED_INTEGER=4



;----------------------------------------------------------------
;
;	�������������ߗ�O
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP�ȊO�̖�������������
ispCall:
	movem.l	(sp)+,d0-d1
	lea.l	(4*(8-2),sp),sp
	movea.l	(sp)+,a0
	lea.l	(4*(8-1),sp),sp
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;MOVEP�Ń��[�U���[�h�̂Ƃ�
_movepUser:
	move.l	usp,a1			;��O��������usp
	move.l	a1,(4*15,sp)		;��O��������sp
	bra	_movepSuper

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;�������������ߗ�O�������[�`��
;	MOVEP�������ʈ����ɂ��č����ɏ������Ă��܂�
;	���̑��̖������������߂̏�����ISP�ɔC���܂�
_060_isp_unint::
	pea.l	(8,sp)			;��O��������ssp
	movem.l	d0-d7/a0-a6,-(sp)	;movem.l <register-list>,-(sp)��,
					;move.l rn,-(sp)�œW�J���Ă������Ȃ�Ȃ�
	movea.l	(4*16+2,sp),a0		;��O��������pc
;<a0.l:��O��������pc
	move.w	(a0)+,d1		;���߃R�[�h
;<d1.w:��O��������(pc).w
;MOVEP��
	move.w	d1,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP����
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	�t�@���N�V�����R�[�h�̃`�F�b�N/�ύX����؍s���Ă��܂���
;	�]�����̃A�N�Z�X�G���[���l�����Ă��܂���
;	���̂悤�Ȉُ�ȃ���������͐������G�~�����[�g�ł��܂���
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<d1.w:��O��������(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a0.l:��O��������pc+2
;<sp.l:�X�^�b�N�ɗ�O�������̃��W�X�^�̓��e��ێ�
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	ssp
;	0040	.w	sr
;	0042	.l	pc		pc�͎��̖��߂̃A�h���X�ɍX�V���邱��
;	0046	.w	�x�N�^�I�t�Z�b�g
;	0048		ssp�̈ʒu
_movep:
	btst.b	#5,(4*16,sp)		;��O��������sr��S
	beq	_movepUser		;�X�[�p�[�o�C�U���[�h��D��
_movepSuper:
;<sp.l:�X�^�b�N�ɗ�O�������̃��W�X�^�̓��e��ێ�
;	0000	.l	d0
;	0004	.l	d1
;	0008	.l	d2
;	000C	.l	d3
;	0010	.l	d4
;	0014	.l	d5
;	0018	.l	d6
;	001C	.l	d7
;	0020	.l	a0
;	0024	.l	a1
;	0028	.l	a2
;	002C	.l	a3
;	0030	.l	a4
;	0034	.l	a5
;	0038	.l	a6
;	003C	.l	usp�܂���ssp
;	0040	.w	sr
;	0042	.l	pc		pc�͎��̖��߂̃A�h���X�ɍX�V���邱��
;	0046	.w	�x�N�^�I�t�Z�b�g
;	0048		ssp�̈ʒu
;�����A�h���X�����߂�
	moveq.l	#7,d0			;0000000000000111
	and.w	d1,d0			;0000000000000aaa
	movea.l	(4*8,sp,d0.w*4),a1	;�A�h���X���W�X�^�̓��e
	adda.w	(a0)+,a1		;�f�B�X�v���[�X�����g��������
;<a0.l:��O��������pc+4
;<a1.l:�����A�h���X
		move.w	d1,d0		;0000ddd1ws001aaa
;���A�A�h���X���X�V����
	move.l	a0,(4*16+2,sp)		;���A�A�h���X���X�V
;�f�[�^���W�X�^�̃A�h���X�����߂�
		lsr.w	#8,d0		;000000000000ddd1
	add.b	d1,d1
		lea.l	(-2,sp,d0.w*2),a0	;00000000000ddd10
					;00000000000ddd00
					;�f�[�^���W�X�^�̃A�h���X
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;�I�y���[�V�������[�h�ɏ]���ē]������
	bcc	_movepRead		;write��D��
;���W�X�^��������
;	MOVEP.{WL} Dx,(d16,Ay)
_movepWrite:
	bpl	_movepWriteWord		;�����O���[�h��D��
;���W�X�^��������,�����O���[�h
;	MOVEP.L Dx,(d16,Ay)
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepWriteLong:
					;movem.l (sp)+,<register-list>��,
					;move.l (sp)+,rn�œW�J����Ƒ����Ȃ�
	move.b	(a0)+,(a1)
	move.b	(a0)+,(2,a1)
	move.b	(a0)+,(4,a1)
	move.b	(a0),(6,a1)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		movea.l	(4*(8-2),sp),a0
	movea.l	(4*(9-2),sp),a1
		lea.l	(4*(16-2),sp),sp
	rte

;���W�X�^��������,���[�h
;	MOVEP.W Dx,(d16,Ay)
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepWriteWord:
	move.b	(2,a0),(a1)
	move.b	(3,a0),(2,a1)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		movea.l	(4*(8-2),sp),a0
	movea.l	(4*(9-2),sp),a1
		lea.l	(4*(16-2),sp),sp
	rte

;�����������W�X�^
;	MOVEP.{WL} (d16,Ay),Dx
_movepRead:
	bpl	_movepReadWord		;�����O���[�h��D��
;�����������W�X�^,�����O���[�h
;	MOVEP.L	(d16,Ay),Dx
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepReadLong:
	move.b	(a1),(a0)+
	move.b	(2,a1),(a0)+
	move.b	(4,a1),(a0)+
	move.b	(6,a1),(a0)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		move.l	(sp)+,d2
	move.l	(sp)+,d3
		move.l	(sp)+,d4
	move.l	(sp)+,d5
		move.l	(sp)+,d6
	move.l	(sp)+,d7
		movea.l	(sp)+,a0
	movea.l	(sp)+,a1
		lea.l	(4*(16-10),sp),sp
	rte

;�����������W�X�^,���[�h
;	MOVEP.W (d16,Ay),Dx
;<a0.l:�f�[�^���W�X�^�̃A�h���X
;<a1.l:�����A�h���X
_movepReadWord:
	move.b	(a1),(2,a0)
	move.b	(2,a1),(3,a0)
		move.l	(sp)+,d0
	move.l	(sp)+,d1
		move.l	(sp)+,d2
	move.l	(sp)+,d3
		move.l	(sp)+,d4
	move.l	(sp)+,d5
		move.l	(sp)+,d6
	move.l	(sp)+,d7
		movea.l	(sp)+,a0
	movea.l	(sp)+,a1
		lea.l	(4*(16-10),sp),sp
	rte



  .elseif UNIMPLEMENTED_INTEGER=5



;----------------------------------------------------------------
;
;	�������������ߗ�O
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP�ȊO�̖�������������
ispCall:
	movea.l	(sp)+,a1		;�����ɒ���
	move.w	(sp)+,d0
	movea.l	(sp)+,a0
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;�������������ߗ�O�������[�`��
;	MOVEP�������ʈ����ɂ��č����ɏ������Ă��܂�
;	���̑��̖������������߂̏�����ISP�ɔC���܂�
	.align	4
_060_isp_unint::
	move.l	a0,-(sp)		;�����ɒ���
	move.w	d0,-(sp)		;��ʃ��[�h�͕ی삵�Ȃ��̂Œ���
	move.l	a1,-(sp)
	movea.l	((4+2+4)+2,sp),a1	;��O��������pc
;<a1.l:��O��������pc
	movea.w	(a1)+,a0		;���߃R�[�h
;<a0.w:��O��������(pc).w
;MOVEP��
	move.w	a0,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP����
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	�t�@���N�V�����R�[�h�̃`�F�b�N/�ύX����؍s���Ă��܂���
;	�]�����̃A�N�Z�X�G���[���l�����Ă��܂���
;	���̂悤�Ȉُ�ȃ���������͐������G�~�����[�g�ł��܂���
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<a0.w:��O��������(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a1.l:��O��������pc+2
;<sp.l:�X�^�b�N�ɗ�O�������̃��W�X�^�̓��e��ێ�
;	0000	.l	a1
;	0004	.w	d0
;	0006	.l	a0
;	000A	.w	sr
;	000C	.l	pc		pc�͎��̖��߂̃A�h���X�ɍX�V���邱��
;	0010	.w	��O�t�H�[�}�b�g�ԍ�,�x�N�^�I�t�Z�b�g
;	0012		��O��������ssp�̈ʒu
_movep:
;�����A�h���X�����߂�
	move.w	a0,d0			;0000ddd1ws001aaa
	and.b	#7,d0			;0000000000000aaa
					; 0  1  2  3  4  5  6  7
	beq	_movep_a0		; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_a123		;   -3 -2 -1
	beq	_movep_a4		;             0
_movep_a567:				;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_a5		;               -1
	beq	_movep_a6		;                   0
_movep_a7:				;                      1
	move.w	a0,d0			;0000ddd1ws001aaa
	lea.l	((4+2+4)+8,sp),a0		;��O��������ssp
	btst.b	#5,((4+2+4)+0,sp)
	bne	_movep_d
	movea.l	usp,a0			;��O��������usp
	bra	_movep_d

_movep_a6:				;                   0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a6,a0			;��O��������a6
	bra	_movep_d

_movep_a5:				;               -1
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a5,a0			;��O��������a5
	bra	_movep_d

_movep_a4:				;             0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a4,a0			;��O��������a4
	bra	_movep_d

_movep_a123:				;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_a1		;   -1
	beq	_movep_a2		;       0
_movep_a3:				;          1
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a3,a0			;��O��������a3
	bra	_movep_d

_movep_a2:				;       0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	a2,a0			;��O��������a2
	bra	_movep_d

_movep_a1:				;   -1
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	(sp),a0			;��O��������a1
	bra	_movep_d

_movep_a0:				; 0
	move.w	a0,d0			;0000ddd1ws001aaa
	movea.l	((4+2),sp),a0		;��O��������a0
;<a0.l:�A�h���X���W�X�^�̓��e
;<a1.l:��O��������pc+2
_movep_d:
	adda.w	(a1)+,a0		;�f�B�X�v���[�X�����g��������
;<d0.w:0000ddd1ws001aaa
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
;���A�A�h���X���X�V����
	move.l	a1,((4+2+4)+2,sp)	;���A�A�h���X���X�V
	movea.l	(sp)+,a1
;�I�y���[�V�������[�h�ɏ]���ē]������
;<d0.w:0000ddd1ws001aaa
;<a0.l:�����A�h���X
	add.b	d0,d0			;c-flag=w,n-flag=s
	bcc	_movep_read		;write��D��
;���W�X�^��������
;	MOVEP.{WL} Dx,(d16,Ay)
;<d0.w:0000ddd1s001aaa0
;<a0.l:�����A�h���X
_movep_write:
	bpl	_movep_write_word	;long��D��
;���W�X�^��������,�����O���[�h
;	MOVEP.L Dx,(d16,Ay)
;<d0.w:0000ddd1s001aaa0
;<a0.l:�����A�h���X
_movep_write_long:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_write_long_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_write_long_d123	;   -3 -2 -1
	beq	_movep_write_long_d4	;             0
_movep_write_long_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_write_long_d5	;               -1
	beq	_movep_write_long_d6	;                   0
;	MOVEP.L D7,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d7:			;                      1
	rol.l	#8,d7
	move.b	d7,(a0)
	rol.l	#8,d7
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d7,(2,a0)
	rol.l	#8,d7
	move.b	d7,(4,a0)
	rol.l	#8,d7
	move.b	d7,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D6,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d6:			;                   0
	rol.l	#8,d6
	move.b	d6,(a0)
	rol.l	#8,d6
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d6,(2,a0)
	rol.l	#8,d6
	move.b	d6,(4,a0)
	rol.l	#8,d6
	move.b	d6,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D5,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d5:			;               -1
	rol.l	#8,d5
	move.b	d5,(a0)
	rol.l	#8,d5
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d5,(2,a0)
	rol.l	#8,d5
	move.b	d5,(4,a0)
	rol.l	#8,d5
	move.b	d5,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D4,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d4:			;             0
	rol.l	#8,d4
	move.b	d4,(a0)
	rol.l	#8,d4
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d4,(2,a0)
	rol.l	#8,d4
	move.b	d4,(4,a0)
	rol.l	#8,d4
	move.b	d4,(6,a0)
	movea.l	(sp)+,a0
	rte

_movep_write_long_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_write_long_d1	;   -1
	beq	_movep_write_long_d2	;       0
;	MOVEP.L D3,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d3:			;          1
	rol.l	#8,d3
	move.b	d3,(a0)
	rol.l	#8,d3
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d3,(2,a0)
	rol.l	#8,d3
	move.b	d3,(4,a0)
	rol.l	#8,d3
	move.b	d3,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D2,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d2:			;       0
	rol.l	#8,d2
	move.b	d2,(a0)
	rol.l	#8,d2
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d2,(2,a0)
	rol.l	#8,d2
	move.b	d2,(4,a0)
	rol.l	#8,d2
	move.b	d2,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D1,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d1:			;   -1
	rol.l	#8,d1
	move.b	d1,(a0)
	rol.l	#8,d1
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d1,(2,a0)
	rol.l	#8,d1
	move.b	d1,(4,a0)
	rol.l	#8,d1
	move.b	d1,(6,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.L D0,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_long_d0:			; 0
	move.w	(sp)+,d0		;��ɕ������邱��
	rol.l	#8,d0
	move.b	d0,(a0)
	rol.l	#8,d0
	move.b	d0,(2,a0)
	rol.l	#8,d0
	move.b	d0,(4,a0)
	rol.l	#8,d0
	move.b	d0,(6,a0)
	movea.l	(sp)+,a0
	rte

;���W�X�^��������,���[�h
;	MOVEP.W Dx,(d16,Ay)
;<d0.w:0000ddd1s001aaa0
;<a0.l:�����A�h���X
_movep_write_word:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_write_word_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_write_word_d123	;   -3 -2 -1
	beq	_movep_write_word_d4	;             0
_movep_write_word_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_write_word_d5	;               -1
	beq	_movep_write_word_d6	;                   0
;	MOVEP.W D7,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d7:			;                      1
	rol.w	#8,d7
	move.b	d7,(a0)
	rol.w	#8,d7
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d7,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D6,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d6:			;                   0
	rol.w	#8,d6
	move.b	d6,(a0)
	rol.w	#8,d6
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d6,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D5,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d5:			;               -1
	rol.w	#8,d5
	move.b	d5,(a0)
	rol.w	#8,d5
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d5,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D4,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d4:			;             0
	rol.w	#8,d4
	move.b	d4,(a0)
	rol.w	#8,d4
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d4,(2,a0)
	movea.l	(sp)+,a0
	rte

_movep_write_word_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_write_word_d1	;   -1
	beq	_movep_write_word_d2	;       0
;	MOVEP.W D3,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d3:			;          1
	rol.w	#8,d3
	move.b	d3,(a0)
	rol.w	#8,d3
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d3,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D2,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d2:			;       0
	rol.w	#8,d2
	move.b	d2,(a0)
	rol.w	#8,d2
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d2,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D1,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d1:			;   -1
	rol.w	#8,d1
	move.b	d1,(a0)
	rol.w	#8,d1
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	d1,(2,a0)
	movea.l	(sp)+,a0
	rte

;	MOVEP.W D0,(d16,Ay)
;<a0.l:�����A�h���X
_movep_write_word_d0:			; 0
	move.w	(sp)+,d0		;��ɕ������邱��
	rol.w	#8,d0
	move.b	d0,(a0)
	rol.w	#8,d0
	move.b	d0,(2,a0)
	movea.l	(sp)+,a0
	rte

;�����������W�X�^
;	MOVEP.{WL} (d16,Ay),Dx
;<d0.w:0000ddd1s001aaa0
;<a0.l:�����A�h���X
_movep_read:
	bpl	_movep_read_word	;long��D��
;�����������W�X�^,�����O���[�h
;	MOVEP.L	(d16,Ay),Dx
;<d0.w:0000ddd1s001aaa0
;<a0.l:�����A�h���X
_movep_read_long:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_read_long_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_read_long_d123	;   -3 -2 -1
	beq	_movep_read_long_d4	;             0
_movep_read_long_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_read_long_d5	;               -1
	beq	_movep_read_long_d6	;                   0
;	MOVEP.L	(d16,Ay),D7
;<a0.l:�����A�h���X
_movep_read_long_d7:			;                      1
	move.b	(a0),d7
	lsl.l	#8,d7
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d7
	lsl.l	#8,d7
	move.b	(4,a0),d7
	lsl.l	#8,d7
	move.b	(6,a0),d7
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D6
;<a0.l:�����A�h���X
_movep_read_long_d6:			;                      1
	move.b	(a0),d6
	lsl.l	#8,d6
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d6
	lsl.l	#8,d6
	move.b	(4,a0),d6
	lsl.l	#8,d6
	move.b	(6,a0),d6
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D5
;<a0.l:�����A�h���X
_movep_read_long_d5:			;                      1
	move.b	(a0),d5
	lsl.l	#8,d5
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d5
	lsl.l	#8,d5
	move.b	(4,a0),d5
	lsl.l	#8,d5
	move.b	(6,a0),d5
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D4
;<a0.l:�����A�h���X
_movep_read_long_d4:			;             0
	move.b	(a0),d4
	lsl.l	#8,d4
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d4
	lsl.l	#8,d4
	move.b	(4,a0),d4
	lsl.l	#8,d4
	move.b	(6,a0),d4
	movea.l	(sp)+,a0
	rte

_movep_read_long_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_read_long_d1	;   -1
	beq	_movep_read_long_d2	;       0
;	MOVEP.L	(d16,Ay),D3
;<a0.l:�����A�h���X
_movep_read_long_d3:			;          1
	move.b	(a0),d3
	lsl.l	#8,d3
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d3
	lsl.l	#8,d3
	move.b	(4,a0),d3
	lsl.l	#8,d3
	move.b	(6,a0),d3
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D2
;<a0.l:�����A�h���X
_movep_read_long_d2:			;       0
	move.b	(a0),d2
	lsl.l	#8,d2
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d2
	lsl.l	#8,d2
	move.b	(4,a0),d2
	lsl.l	#8,d2
	move.b	(6,a0),d2
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D1
;<a0.l:�����A�h���X
_movep_read_long_d1:			;   -1
	move.b	(a0),d1
	lsl.l	#8,d1
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d1
	lsl.l	#8,d1
	move.b	(4,a0),d1
	lsl.l	#8,d1
	move.b	(6,a0),d1
	movea.l	(sp)+,a0
	rte

;	MOVEP.L	(d16,Ay),D0
;<a0.l:�����A�h���X
_movep_read_long_d0:			; 0
	move.b	(a0),d0
	lsl.l	#8,d0
	addq.l	#2,sp			;�X�^�b�N��d0���̂Ă�
					;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d0
	lsl.l	#8,d0
	move.b	(4,a0),d0
	lsl.l	#8,d0
	move.b	(6,a0),d0
	movea.l	(sp)+,a0
	rte

;�����������W�X�^,���[�h
;	MOVEP.W (d16,Ay),Dx
;<d0.w:0000ddd1s001aaa0
;<a0.l:�����A�h���X
_movep_read_word:
	lsr.w	#8,d0			;000000000000ddd1
	lsr.b	#1,d0			;0000000000000ddd
					; 0  1  2  3  4  5  6  7
	beq	_movep_read_word_d0	; 0
	subq.b	#4,d0			;   -3 -2 -1  0  1  2  3
	bmi	_movep_read_word_d123	;   -3 -2 -1
	beq	_movep_read_word_d4	;             0
_movep_read_word_d567:			;                1  2  3
	subq.b	#2,d0			;               -1  0  1
	bmi	_movep_read_word_d5	;               -1
	beq	_movep_read_word_d6	;                   0
;	MOVEP.W	(d16,Ay),D7
;<a0.l:�����A�h���X
_movep_read_word_d7:			;                      1
	move.b	(a0),d7
	lsl.w	#8,d7
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d7
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D6
;<a0.l:�����A�h���X
_movep_read_word_d6:			;                      1
	move.b	(a0),d6
	lsl.w	#8,d6
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d6
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D5
;<a0.l:�����A�h���X
_movep_read_word_d5:			;                      1
	move.b	(a0),d5
	lsl.w	#8,d5
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d5
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D4
;<a0.l:�����A�h���X
_movep_read_word_d4:			;             0
	move.b	(a0),d4
	lsl.w	#8,d4
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d4
	movea.l	(sp)+,a0
	rte

_movep_read_word_d123:			;   -3 -2 -1
	addq.b	#2,d0			;   -1  0  1
	bmi	_movep_read_word_d1	;   -1
	beq	_movep_read_word_d2	;       0
;	MOVEP.W	(d16,Ay),D3
;<a0.l:�����A�h���X
_movep_read_word_d3:			;          1
	move.b	(a0),d3
	lsl.w	#8,d3
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d3
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D2
;<a0.l:�����A�h���X
_movep_read_word_d2:			;       0
	move.b	(a0),d2
	lsl.w	#8,d2
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d2
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D1
;<a0.l:�����A�h���X
_movep_read_word_d1:			;   -1
	move.b	(a0),d1
	lsl.w	#8,d1
	move.w	(sp)+,d0		;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d1
	movea.l	(sp)+,a0
	rte

;	MOVEP.W	(d16,Ay),D0
;<a0.l:�����A�h���X
_movep_read_word_d0:			; 0
	move.b	(a0),d0
	lsl.w	#8,d0
	addq.l	#2,sp			;�X�^�b�N��d0���̂Ă�
					;(a0)���x���\��������̂ł����ɋ���
	move.b	(2,a0),d0
	movea.l	(sp)+,a0
	rte



  .elseif UNIMPLEMENTED_INTEGER=6



;----------------------------------------------------------------
;
;	�������������ߗ�O
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;MOVEP�ȊO�̖�������������
ispCall:
	move.l	(sp)+,d0
	move.l	(sp)+,d1
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	bra	_isp_unimp		;_060ISP_TABLE+$00000238
					;_060ISP_TABLE+$00

;----------------------------------------------------------------
;Unimplemented Integer Instruction
;�������������ߗ�O�������[�`��
;	MOVEP�������ʈ����ɂ��č����ɏ������Ă��܂�
;	���̑��̖������������߂̏�����ISP�ɔC���܂�
	.align	4
_060_isp_unint::
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	move.l	d1,-(sp)
	move.l	d0,-(sp)
	movea.l	(4*4+2,sp),a1		;��O��������pc
;<a1.l:��O��������pc
	move.w	(a1)+,d1		;���߃R�[�h
;<d1.w:��O��������(pc).w
;MOVEP��
	move.w	d1,d0
	and.w	#$F138,d0
	cmp.w	#$0108,d0
	bne	ispCall
;----------------------------------------------------------------
;MOVEP����
;	MOVEP.{WL} Dx,(d16,Ay)
;	MOVEP.{WL} (d16,Ay),Dx
;	�t�@���N�V�����R�[�h�̃`�F�b�N/�ύX����؍s���Ă��܂���
;	�]�����̃A�N�Z�X�G���[���l�����Ă��܂���
;	���̂悤�Ȉُ�ȃ���������͐������G�~�����[�g�ł��܂���
;		MOVEP.W Dx,(d16,SSP) (-$004A<=d16<=-$0001)
;		MOVEP.L Dx,(d16,SSP) (-$004E<=d16<=-$0001)
;<d1.w:��O��������(pc).w
;	0000ddd1ws001aaa
;		ddd	data register
;		w	read/write(0=read,1=write)
;		s	size(0=word,1=long)
;		aaa	address register
;<a1.l:��O��������pc+2
;<sp.l:�X�^�b�N�ɗ�O�������̃��W�X�^�̓��e��ێ�
;	0000	.l	d0
;	0004	.l	d0
;	0008	.l	a0
;	000C	.l	a1
;	0010	.w	sr
;	0012	.l	pc		pc�͎��̖��߂̃A�h���X�ɍX�V���邱��
;	0016	.w	��O�t�H�[�}�b�g�ԍ�,�x�N�^�I�t�Z�b�g
;	0018		��O��������ssp�̈ʒu
_movep:
	ror.b	#3,d1			;0000ddd1aaaws001,n=aaa[2]
	bpl	_movep_a0123
_movep_a4567:
	lsl.b	#2,d1			;0000ddd1aws00100,c=aaa[1],n=aaa[0]
	bcc	_movep_a45
_movep_a67:
	bpl	_movep_a6
_movep_a7:
	lea.l	(4*4+8,sp),a0		;��O��������ssp
	btst.b	#5,(4*4+0,sp)
	bne	_movep_an
	movea.l	usp,a0			;��O��������usp
	bra	_movep_an

_movep_a6:
	movea.l	a6,a0			;��O��������a6
	bra	_movep_an

_movep_a45:
	bpl	_movep_a4
_movep_a5:
	movea.l	a5,a0			;��O��������a5
	bra	_movep_an

_movep_a4:
	movea.l	a4,a0			;��O��������a4
	bra	_movep_an

_movep_a0123:
	lsl.b	#2,d1			;0000ddd1aws00100,c=aaa[1],n=aaa[0]
	bcc	_movep_a01
_movep_a23:
	bpl	_movep_a2
_movep_a3:
	movea.l	a3,a0			;��O��������a3
	bra	_movep_an

_movep_a2:
	movea.l	a2,a0			;��O��������a2
	bra	_movep_an

_movep_a01:
	bpl	_movep_a0
_movep_a1:
	movea.l	(4,sp),a0		;��O��������a1
	bra	_movep_an

_movep_a0:
	movea.l	(sp),a0			;��O��������a0
;<d1.w:0000ddd1aws00100
;<a0.l:An
;<a1.l:��O��������pc+2
_movep_an:
	adda.w	(a1)+,a0		;�f�B�X�v���[�X�����g��������
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
	lsl.b	#2,d1			;0000ddd1s0010000,c=w,n=s
	bcc	_movep_read		;write��D��
;���W�X�^��������
;	MOVEP.{WL} Dx,(d16,Ay)
;<d1.w:0000ddd1s0010000
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
_movep_write:
	lsl.w	#5,d1			;dd1s001000000000,c=ddd[2],n=ddd[1]
	bcc	_movep_write_d0123
_movep_write_d4567:
	bpl	_movep_write_d45
_movep_write_d67:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d6
_movep_write_d7:
	move.l	d7,d0
	bra	_movep_write_dn

_movep_write_d6:
	move.l	d6,d0
	bra	_movep_write_dn

_movep_write_d45:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d4
_movep_write_d5:
	move.l	d5,d0
	bra	_movep_write_dn

_movep_write_d4:
	move.l	d4,d0
	bra	_movep_write_dn

_movep_write_d0123:
	bpl	_movep_write_d01
_movep_write_d23:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d2
_movep_write_d3:
	move.l	d3,d0
	bra	_movep_write_dn

_movep_write_d2:
	move.l	d2,d0
	bra	_movep_write_dn

_movep_write_d01:
	lsl.w	#2,d1			;1s00100000000000,c=ddd[0]
	bcc	_movep_write_d0
_movep_write_d1:
	move.l	(4,sp),d0
	bra	_movep_write_dn

_movep_write_d0:
	move.l	(sp),d0
;<d0.l:Dn
;<d1.w:1s00100000000000
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
_movep_write_dn:
	lsl.w	#2,d1			;0010000000000000,c=s
	bpl	_movep_write_word	;long��D��
;���W�X�^��������,�����O���[�h
;	MOVEP.L Dx,(d16,Ay)
;<d0.l:Dn
;<d1.w:0010000000000000
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
_movep_write_long:
	rol.l	#8,d0
	tst.l	(a1)			;MOVEP�̒����2���[�h���L���b�V���ɏ悹�Ă���
	move.b	d0,(a0)			;1�o�C�g�ڂ���������
	move.w	(a1),d1			;MOVEP�̒���̃��[�h
					;�L���b�V���̓q�b�g����͂�
	rol.l	#8,d0			;�������񂾒���Ɏ���1�o�C�g��p�ӂ���
	and.w	#$F138,d1		;����̖��߂�MOVEP��?
	cmp.w	#$0108,d1
	bne	_movep_write_long_stop	;MOVEP�ł͂Ȃ�
;MOVEP�̒���̖��߂�MOVEP������
;�������݂Ȃ��璼���MOVEP��An��Dn���m�肷��
_movep_write_long_cont:
	move.w	(a1)+,d1		;�����MOVEP
					;�L���b�V���̓q�b�g����͂�
;<d1.w:�����MOVEP,0000ddd1ws001aaa
;<a1.l:����̖��߂�pc+2
	ror.b	#3,d1			;0000ddd1aaaws001,n=aaa[2]
	bpl	_movep_long_cont_a0123
_movep_long_cont_a4567:
	lsl.b	#2,d1			;0000ddd1aws00100,c=aaa[1],n=aaa[0]
	bcc	_movep_long_cont_a45
_movep_long_cont_a67:
	bpl	_movep_long_cont_a6
_movep_long_cont_a7:
	move.b	d0,(2,a0)		;2�o�C�g�ڂ���������
	rol.l	#8,d0			;�������񂾒���Ɏ���1�o�C�g��p�ӂ���





;MOVEP�̒���̖��߂�MOVEP�ł͂Ȃ�����
;�c��̃f�[�^����������ŕ��A�A�h���X���X�V���ďI���

_movep_write_long_stop:
;���A�A�h���X���X�V����
	move.l	a1,(4*4+2,sp)		;���A�A�h���X���X�V




;���W�X�^��������,���[�h
;	MOVEP.W Dx,(d16,Ay)
;<d0.l:Dn
;<d1.w:0010000000000000
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
_movep_write_word:




;�����������W�X�^
;	MOVEP.{WL} (d16,Ay),Dx
;<d1.w:0000ddd1s0010000
;<a0.l:�����A�h���X
;<a1.l:��O��������pc+4
_movep_read:
;���A�A�h���X���X�V����
	move.l	a1,(4*4+2,sp)		;���A�A�h���X���X�V
	move.b	(a0),d0			;�T�C�Y���m��̂܂�1�o�C�g�ڂ�read
					;(d16,Ay)�ŃL���b�V���̓q�b�g���Ȃ��Ƒz�肵��,
					;�E�F�C�g�̊ԂɂȂ�ׂ������̏������s��
					;�����ł̓E�F�C�g�̊Ԃ�Dn���m�肵�Ă݂�
					;����ł��E�F�C�g�����Ȃ�]��͂�
					;�������A�N�Z�X�͋ɗ͔����邱��(�L���b�V����
					;�~�X����Ƃ����ɃE�F�C�g�������Ă��܂�)
	tst.b	d1			;0000ddd1s0010000,n=s
					;_movep_read�̒���ŕ��򂷂��tst�͕s�v����,
					;�����Ă����ɓ����
	bpl	_movep_read_word	;long��D��
;�����������W�X�^,�����O���[�h
;	MOVEP.L (d16,Ay),Dx
_movep_read_long:
	lsl.w	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(2,a0),d0		;2�o�C�g�ڂ�read
	lsl.w	#4,d1			;ddd1s00100000000,s=1,n=ddd[2]
					;1�r�b�g���e�X�g����̂�c�͎g��Ȃ�
	bpl	_movep_read_long_d0123	;�A�N�Z�X�̓x�ɕ����1�`2�������
					;���߃L���b�V�������q�b�g�����,
					;����L���b�V�����~�X���Ă����Ȃ�
_movep_read_long_d4567:
	lsl.l	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(4,a0),d0		;3�o�C�g�ڂ�read
	lsl.w	#1,d1			;dd1s001000000000,s=1,n=ddd[1]
	bpl	_movep_read_long_d45
_movep_read_long_d67:
	lsl.l	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(6,a0),d0		;4�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d6
_movep_read_long_d7:
	move.l	d0,d7
	bra	_movep_read_long_dn

_movep_read_long_d6:
	move.l	d0,d6
	bra	_movep_read_long_dn

_movep_read_long_d45:
	lsl.l	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(6,a0),d0		;4�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d4
_movep_read_long_d5:
	move.l	d0,d5
	bra	_movep_read_long_dn

_movep_read_long_d4:
	move.l	d0,d4
	bra	_movep_read_long_dn

_movep_read_long_d0123:
	lsl.l	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(4,a0),d0		;3�o�C�g�ڂ�read
	lsl.w	#1,d1			;dd1s001000000000,s=1,n=ddd[1]
	bpl	_movep_read_long_d01
_movep_read_long_d23:
	lsl.l	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(6,a0),d0		;4�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d2
_movep_read_long_d3:
	move.l	d0,d3
	bra	_movep_read_long_dn

_movep_read_long_d2:
	move.l	d0,d2
_movep_read_long_dn:
	move.l	(sp)+,d0
_movep_read_long_dn_d1:
	move.l	(sp)+,d1
_movep_read_long_dn_a0:
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	rte

_movep_read_long_d01:
	lsl.l	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(6,a0),d0		;4�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=1,n=ddd[0]
	bpl	_movep_read_long_d0
_movep_read_long_d1:
	move.l	d0,d1
	move.l	(sp)+,d0
	addq.l	#4,sp			;�X�^�b�N��d1��j������
	bra	_movep_read_long_dn_a0

_movep_read_long_d0:
	addq.l	#4,sp			;�X�^�b�N��d0��j������,
					;�ǂݏo����d0�����̂܂ܕԂ�
	bra	_movep_read_long_dn_d1

;�����������W�X�^,���[�h
;	MOVEP.W (d16,Ay),Dx
_movep_read_word:
	lsl.w	#5,d1			;dd1s001000000000,s=0,c=ddd[2],n=ddd[1]
	bcc	_movep_read_word_d0123	;�A�N�Z�X�̓x�ɕ����2�`3�������
					;����L���b�V�����S���~�X���Ă�,
					;���߃L���b�V�������q�b�g���Ă����,
					;����ł��E�F�C�g�ɓ���؂�Ǝv����
					;(����؂�Ȃ��Ă����͂Ȃ�)
_movep_read_word_d4567:
	bpl	_movep_read_word_d45
_movep_read_word_d67:
	lsl.w	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(2,a0),d0		;2�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d6
_movep_read_word_d7:
	move.w	d0,d7
	bra	_movep_read_word_dn

_movep_read_word_d6:
	move.w	d0,d6
	bra	_movep_read_word_dn

_movep_read_word_d45:
	lsl.w	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(2,a0),d0		;2�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d4
_movep_read_word_d5:
	move.w	d0,d5
	bra	_movep_read_word_dn

_movep_read_word_d4:
	move.w	d0,d4
	bra	_movep_read_word_dn

_movep_read_word_d0123:
	bpl	_movep_read_word_d01
_movep_read_word_d23:
	lsl.w	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(2,a0),d0		;2�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d2
_movep_read_word_d3:
	move.w	d0,d3
	bra	_movep_read_word_dn

_movep_read_word_d2:
	move.w	d0,d2
_movep_read_word_dn:
	move.l	(sp)+,d0
_movep_read_word_dn_d1:
	move.l	(sp)+,d1
_movep_read_word_dn_a0:
	movea.l	(sp)+,a0
	movea.l	(sp)+,a1
	rte

_movep_read_word_d01:
	lsl.w	#8,d0			;�E�F�C�g�I���܂�d0���m�肵�Ȃ��̂�,
					;���̃A�N�Z�X�̒��O�ŃV�t�g����
	move.b	(2,a0),d0		;2�o�C�g�ڂ�read
	lsl.w	#1,d1			;d1s0010000000000,s=0,n=ddd[0]
	bpl	_movep_read_word_d0
_movep_read_word_d1:
	move.w	d0,d1			;d1�̏�ʃ��[�h�͔j�󂳂�Ă��Ȃ��̂�,
					;���̂܂ܕԂ�
	move.l	(sp)+,d0
	addq.l	#4,sp			;�X�^�b�N��d1��j������
	bra	_movep_read_word_dn_a0

_movep_read_word_d0:
					;d0�̏�ʃ��[�h�͔j�󂳂�Ă��Ȃ��̂�,
					;���̂܂ܕԂ�
	addq.l	#4,sp			;�X�^�b�N��d0��j������
	bra	_movep_read_word_dn_d1



  .endif



;----------------------------------------------------------------
;
;	F-line���������ߗ�O/�����ᔽ��O
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;Line 1111 Emulator (Unimplemented F-Line Opcode)
;	FLOATn.X�������ᔽ��O��F-line�ɗ��Ƃ��Ă��܂��̂ŁA
;	�����ɂ������ᔽ��O�������Ă��邱�Ƃ�����
	.dc.b	'060turbo'
	.dc.l	0
_060_fpsp_fline::
	cmpi.w	#$2000,(6,sp)		;�t�H�[�}�b�g��2�ȏ�Ȃ��FPSP�ɓn��
	bcc	_fpsp_fline
	move.l	a6,-(sp)
	movea.l	(4+2,sp),a6		;��O��������PC
;<a6.l:��O��������pc
	cmpi.b	#$FE,(a6)
	beq	feCall			;$FExx FE�t�@���N�V�����R�[��
	bhi	dosCall			;$FFxx DOS�R�[��
	cmpi.b	#$F0,(a6)
	blo	flineToPrivilege	;F-Line�łȂ���Γ����ᔽ��O
;----------------------------------------------------------------
;$FExx�ł�$FFxx�ł��Ȃ�F-Line Opcode��FPSP�ɔC����
fpspCall::
	movea.l	(sp)+,a6
	bra	_fpsp_fline		;_060FPSP_TABLE+$00001B8C
					;_060FPSP_TABLE+$30

;----------------------------------------------------------------
;DOS�R�[��
;<a6.l:��O��������pc
dosCall::
;;;	movea.l	(sp)+,a6
;;;	jmp	([vectorOldFLINE])
	cmpi.w	#$FFF5,(a6)
	bcc	dosCallThread
	movem.l	d1-d7/a0-a5,-(sp)
	move.w	(a6)+,d0		;(pc).w
	and.l	#$000000FF,d0
;<d0.l:DOS�R�[���ԍ�
	move.l	a6,(dosPC,sp)		;���A�A�h���X���X�V
	lea.l	(dosSSP,sp),a6		;��O��������ssp
	btst.b	#5,(dosSR,sp)
	bne	@f
	move.l	usp,a6			;��O��������usp
@@:
;<a6.l:�p�����[�^�̃A�h���X
	tst.w	$1C08.w			;DOS�R�[���̃��x��(��������_INDOSFLG)
	bne	@f
	move.l	sp,$1C5C.w		;DOS�R�[���Ƀ��x��0�œ������Ƃ���ssp
	move.b	d0,$1C0A.w		;���x��0�œ�����DOS�R�[���ԍ�
@@:
	addq.w	#1,$1C08.w		;DOS�R�[���̃��x��(��������_INDOSFLG)
	clr.l	$1C98.w			;DOS�R�[���ɓ����Ă���I�[�v������FCB�e�[�u��
	jsr	([$1800,d0.l*4])
;	jsr	([$1800+$0400,d0.w*4])	;DOS�R�[�����s
					;d0.l	$xxxxFFxx
					;�g��	$FFFFFFxx
					;4�{	$FFFFFCxx
					;�{���̒l���$0400����Ȃ��̂�bd�ɉ����Ă���
	clr.l	$1C98.w			;DOS�R�[���ɓ����Ă���I�[�v������FCB�e�[�u��
	subq.w	#1,$1C08.w		;DOS�R�[���̃��x��(��������_INDOSFLG)
	bne	@f
	clr.b	$1C0A.w			;���x��0�œ�����DOS�R�[���ԍ�
@@:	move.l	d0,-(sp)
	jsr	$00008740		;break�`�F�b�N
	movem.l	(sp)+,d0-d7/a0-a6
	tst.b	$1C14.w			;DOS�R�[���I�����ɃX���b�h��؂�ւ��邩(0=no,1=yes)
	bne	dosCallThreadChange
	tst.w	(sp)
	bmi	@f
	rte

@@:	ori.w	#$8000,sr
	rte

;�X���b�h�Ǘ��֌W��DOS�R�[��
dosCallThread::
	move.l	a5,-(sp)
	move.l	d0,-(sp)
	move.w	(a6)+,d0		;(pc).w
	move.l	a6,(4*3+2,sp)		;���A�A�h���X���X�V
	lea.l	(4*3+8,sp),a6		;�p�����[�^�̃A�h���X
	jmp	$0000E31C

;DOS�R�[���I�����ɃX���b�h��؂�ւ���
dosCallThreadChange::
	jmp	$0000E050

;----------------------------------------------------------------
;FE�t�@���N�V�����R�[��
;<a6.l:��O��������pc
feCall::
	move.l	d7,-(sp)
	move.w	(a6)+,d7		;��O��������(pc).w
;<d7.w:��O��������(pc).w
;<a6.l:��O��������pc+2
	move.l	a6,(4+4+2,sp)		;���A�A�h���X���X�V����
	jmp	([feJumpTable+$0200*4,pc,d7.w*4])	;�eFE�t�@���N�V�����֕���
					;+$0200*4�̓I�t�Z�b�g�̒��߂̂���
					;d7.w�𕄍��g�������	$FFFFFE00�`$FFFFFEFF
					;4�{�����		$FFFFF800�`$FFFFFBFC
					;�I�t�Z�b�g��$0200*4����Ȃ��̂ł��̕������Ă���

;----------------------------------------------------------------
;
;	�����ᔽ��O
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;�����ᔽ��O
privilegeViolation::
	move.l	a6,-(sp)
	movea.l	(4+2,sp),a6		;��O��������PC
flineToPrivilege:
	cmpi.w	#$40C0,(a6)
	blo	unknownPrivilege
	cmpi.w	#$40FF,(a6)
	bhi	unknownPrivilege
;----------------------------------------------------------------
;MOVE from SR
;	���̂܂܂ł͏������������f�����O�ɓ����ᔽ���������Ă��܂��A
;	���̂Ƃ�����MOVE from CCR�ɂȂ��Ă���̂Ŕ������o��
;	~008652:
;		move.l	a6,d0			;MOVE from CCR�ɕύX����
;		or.w	#$0200,d0
;		move.w	d0,-(a5)
;		movec.l	cacr,d0			;���߃L���b�V���t���b�V��
;		or.w	#$0008,d0
;		movec.l	d0,cacr
;		movem.l	(sp)+,d0/a5-a6
;		rte
moveFromSr::
	bset.b	#1,(a6)			;MOVE from SR��MOVE from CCR�ɂ���
					;d0�͉��Ă���̂Ŏg��Ȃ�����
	bsr	cache_flush
	movea.l	(sp)+,a6
	rte

;----------------------------------------------------------------
;���߂ł��Ȃ������ᔽ��O
;�X�[�p�[�o�C�U���[�h�ł�STOP��SR��S�r�b�g���N���A���悤�Ƃ����Ƃ��Ȃǂɔ�������
unknownPrivilege::
	move.l	(sp)+,a6
;----------------------------------------------------------------
;FPSP�ɂ����߂ł��Ȃ�F-Line Opcode������ᔽ��O�͔�����
;[$002C.w]�ɔ�΂��Ɩ������[�v�Ɋׂ��Ă��܂��̂�[$0010.w]���g��
_060_real_fline::
	jmp	([$0010.w])

;----------------------------------------------------------------
;
;	ISP��FPSP���g���T�u���[�`��
;
;----------------------------------------------------------------
;----------------------------------------------------------------
_060_real_lock_page::
_060_real_unlock_page::
	clr.l	d0
	rts

;----------------------------------------------------------------
_060_dmem_write::
_060_imem_read::
_060_dmem_read::
@@:	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne	@b
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_read_byte::
	clr.l	d0
	move.b	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_write_byte::
	move.b	d0,(a0)
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_read_word::
	clr.l	d0
	move.w	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_imem_read_word::
	move.w	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_write_word::
	move.w	d0,(a0)
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_read_long::
_060_imem_read_long::
	move.l	(a0),d0
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_dmem_write_long::
	move.l	d0,(a0)
	clr.l	d1
	rts

;----------------------------------------------------------------
_060_real_chk::
_060_real_divbyzero::
	tst.w	(sp)
	bmi	@f
	rte

@@:	move.b	#$24,(7,sp)
;----------------------------------------------------------------
_060_real_trace::
	jmp	([$0024.w])		;�g���[�X

;----------------------------------------------------------------
_060_real_access::
	jmp	([$0008.w])		;�A�N�Z�X�G���[

;----------------------------------------------------------------
_060_real_trap::
	jmp	([$001C.w])		;FTRAPcc

;----------------------------------------------------------------
_060_real_inex::
_060_real_dz::
_060_real_unfl::
_060_real_operr::
_060_real_ovfl::
_060_real_snan::
	fsave	-(sp)
	move.w	#$6000,(2,sp)
	frestore	(sp)+
	rte

;----------------------------------------------------------------
_060_real_bsun::
	fsave	-(sp)
	fmove.l	fpsr,-(sp)
	and.b	#$FE,(sp)
	fmove.l	(sp)+,fpsr
	lea.l	(12,sp),sp
	rte

;----------------------------------------------------------------
_060_real_fpu_disabled::
	move.l	d0,-(sp)
	movec.l	pcr,d0			;FPU���C�l�[�u���ɂ���
	bclr.l	#1,d0
	movec.l	d0,pcr
	move.l	(sp)+,d0
	move.l	(12,sp),(2,sp)		;���g���C
	rte

;----------------------------------------------------------------
;
;	ISP��FPSP�̏o��
;
;----------------------------------------------------------------
;----------------------------------------------------------------
_060_isp_done::
	rte

;----------------------------------------------------------------
_060_fpsp_done::
	rte

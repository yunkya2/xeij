;----------------------------------------------------------------
;
;	�X���b�h�֌W��DOS�R�[���̃p�b�`
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t03memory.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;_S_MALLOC	���C���X���b�h�̃�������Ԃ���̃u���b�N�̊m��
;<(a6).w:bit15=�v���Z�X�w��t���O(0=���s���̃v���Z�X,1=(6,a6).l��e�v���Z�X�Ƃ��Ďg�p����)
;	����8bit=���[�h(0=���ʂ���,1=�K�v�ŏ��u���b�N����,2=��ʂ���,3=�ő�u���b�N����)
;<(2,a6).l:�m�ۂ���T�C�Y
;<(6,a6).l:((a6).w��bit15��1�̂Ƃ�)�e�v���Z�X�̃������Ǘ��e�[�u��
;>d0.l:�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	$81xxxxxx=�m�ۂł���ő�̃T�C�Y,$82000000=�܂������m�ۂł��Ȃ�
;*d0,?d2-d4/a0-a5
dosSMalloc::
  debug '|s_malloc in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	movea.l	$1C50.w,a0		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	cmpa.l	$1C54.w,a0		;���s���̃X���b�h�̃X���b�h�Ǘ��e�[�u��
	beq	dosMalloc2		;���C���X���b�h���s���Ȃ��_MALLOC2�ōς܂�
;<a0.l:���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	bsr	lockBlocks		;�������܂߂����ׂẴT�u�X���b�h�̃u���b�N�����b�N����
	movea.l	$1C50.w,a3		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	movea.l	a4,a2
	movea.l	a5,a3
	bra	dosMalloc2SMalloc

;----------------------------------------------------------------
;_S_MALLOC2	���C���X���b�h�̃�������Ԃ���̃u���b�N�̊m��
;<(a6).w:bit15=�v���Z�X�w��t���O(0=���s���̃v���Z�X,1=(6,a6).l��e�v���Z�X�Ƃ��Ďg�p����)
;	����8bit=���[�h(0=���ʂ���,1=�K�v�ŏ��u���b�N����,2=��ʂ���,3=�ő�u���b�N����)
;<(2,a6).l:�m�ۂ���T�C�Y
;<(6,a6).l:((a6).w��bit15��1�̂Ƃ�)�e�v���Z�X�̃������Ǘ��e�[�u��
;>d0.l:�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0,?d2-d4/a0-a5
dosSMalloc2::
  debug '|s_malloc2 in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	movea.l	$1C50.w,a0		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	cmpa.l	$1C54.w,a0		;���s���̃X���b�h�̃X���b�h�Ǘ��e�[�u��
	beq	dosMalloc4		;���C���X���b�h���s���Ȃ��_MALLOC4�ōς܂�
;<a0.l:���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	bsr	lockBlocks		;�������܂߂����ׂẴT�u�X���b�h�̃u���b�N�����b�N����
	movea.l	$1C50.w,a3		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	movea.l	a4,a2
	movea.l	a5,a3
	bra	dosMalloc4SMalloc

;----------------------------------------------------------------
;_S_MFREE	���C���X���b�h�̃�������Ԃ���̃u���b�N�̊J��
;	���݂̃X���b�h�̃�������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)�Ȃ�΃X���b�h��j������
;	����ȊO�̓��C���X���b�h�̃������Ǘ��Ń��b�N���s�킸��_MFREE���s��
;<(a6).l:�J������u���b�N�̃��[�U�̈�̐擪
;>d0.l:�G���[�R�[�h
;*d0,?d1-d2/a0/a2-a5
dosSMfree::
  debug '|s_mfree in (ptr)=',1,(a6)
	move.w	currentThreadId,d1	;���݂̃X���b�h�ԍ�
	beq	dosMfree		;���C���X���b�h�����s���Ȃ��_MFREE���邾��
;<d1.w:���݂̃X���b�h�ԍ�
	move.l	(a6),d2			;�J������u���b�N�̃��[�U�̈�̐擪
;<d2.l:�J������u���b�N�̃��[�U�̈�̐擪
	movea.l	$1C50.w,a3		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u���̐擪�A�h���X
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:���C���X���b�h�̃�������Ԃ̐擪
;<a5.l:���C���X���b�h�̃�������Ԃ̖���+1
	movea.l	$1C54.w,a3		;���݂̃X���b�h�̃X���b�h�Ǘ��e�[�u��
;<a3.l:���݂̃X���b�h�̃X���b�h�Ǘ��e�[�u��
	move.l	(tMemStart,a3),d0	;���݂̃X���b�h�̐擪�̃u���b�N�̃w�b�_
	cmpa.l	d0,a4
	beq	dosMfreeSMfree		;���C���X���b�h�Ɠ�����������ԂȂ��_MFREE���邾��
	cmp.l	d0,d2
	bne	dosMfreeSMfree		;���݂̃X���b�h�̐擪�̃u���b�N�łȂ����_MFREE���邾��
;�u���b�N����������
	bsr	searchBlock		;���C���X���b�h�̃�������Ԃ��猟������
	bpl	dosSMfreeContinuous	;�A���������^�T�u�X���b�h
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2
	bsr	searchBlock		;���C���X���b�h�̃�������Ԃ��猟������
	bmi	dosSMfreeParamError	;�p�����[�^������

;�T�u�������^�T�u�X���b�h
;	�r���������j������
;	���C���X���b�h�̃�������ԂɕύX
;	�T�u�X���b�h�̃�������Ԃ̐e�u���b�N�̃t���O������
;	�T�u�X���b�h�̃�������Ԃ̐e�u���b�N�̃w�b�_���폜����
;	�T�u�X���b�h�̃�������Ԃ����C���X���b�h�̃�������ԂɌ�������
;<d1.w:�X���b�h�ԍ�
;<a2.l:�e�u���b�N�̃w�b�_
;<a4.l:���C���X���b�h�̃�������Ԃ̐擪
;<a5.l:���C���X���b�h�̃�������Ԃ̖���+1
	tst.b	backgroundFlag
	beq	@f
	move.w	d1,d0
	bsr	killExclusive		;�r���������j������
@@:	move.l	a4,$1C04.w		;���C���X���b�h�̃�������ԂɕύX
	move.l	a5,$1C00.w
	andi.b	#LOGICAL_MASK>>24,(Proc,a2)	;�e�u���b�N�̃t���O������
	lea.l	(User,a2),a0		;�擪�̃u���b�N�̃w�b�_
	move.l	(Proc,a2),(Proc,a0)	;�擪�̃u���b�N�̐e�v���Z�X��e�u���b�N�̐e�v���Z�X�ɂ���
	movea.l	(a2),a1			;�e�u���b�N�̒��O
	move.l	a1,(Prev,a0)		;�擪�̃u���b�N�̒��O��e�u���b�N�̒��O�ɂ���
	beq	@f
	move.l	a0,(Next,a1)		;�e�u���b�N�̒��O�̒����擪�̃u���b�N�ɂ���
@@:
1:	move.l	(Next,a0),d0
	beq	2f
	movea.l	d0,a0
	move.l	(Next,a0),d0
	bne	1b
2:
;<a0.l:�Ō�̃u���b�N�̃w�b�_
	movea.l	(Next,a2),a1
	move.l	a1,(Next,a0)		;�����̒����e�u���b�N�̒���ɂ���
	beq	@f
	move.l	a0,(Prev,a1)		;�T�u�̒���̒��O�𖖔��ɂ���
@@:
	bra	dosSMfreeSetEnd

;�A���������^�T�u�X���b�h
;	�r���������j������
;	���C���X���b�h�̃�������ԂɕύX
;	�T�u�X���b�h�̃�������Ԃ̐擪�̃u���b�N�̃t���O������
;	�T�u�X���b�h�̃�������Ԃ̒���̃_�~�[�̃u���b�N�̃w�b�_���폜����
;<d1.w:�X���b�h�ԍ�
;<a2.l:�擪�̃u���b�N�̃w�b�_
;<a3.l:���݂̃X���b�h�̃X���b�h�Ǘ��e�[�u��
;<a4.l:���C���X���b�h�̃�������Ԃ̐擪
;<a5.l:���C���X���b�h�̃�������Ԃ̖���+1
dosSMfreeContinuous:
	tst.b	backgroundFlag
	beq	@f
	move.w	d1,d0
	bsr	killExclusive		;�r���������j������
@@:	move.l	a4,$1C04.w		;���C���X���b�h�̃�������ԂɕύX
	move.l	a5,$1C00.w
	andi.b	#LOGICAL_MASK>>24,(Proc,a2)	;�擪�̃u���b�N�̃t���O������
	movea.l	(tMemEnd,a3),a5
	movea.l	a2,a0
	move.l	a2,d0
1:	cmp.l	a5,d0
	bcc	2f
	movea.l	d0,a0
	move.l	(Next,a0),d0
	bne	1b
	bra	3f
2:
;<d0.l:�Ō�̃u���b�N�̎��̃u���b�N�̃w�b�_
;<a0.l:�Ō�̃u���b�N�̃w�b�_
	cmp.l	a5,d0
	bne	3f			;��������Ԃ̒���Ƀu���b�N���Ȃ�
	movea.l	(Next,a5),a1
	move.l	a1,(Next,a0)		;�Ō�̃u���b�N�̒�����_�~�[�̃u���b�N�̒���ɂ���
	beq	@f
	move.l	a0,(Prev,a1)		;�_�~�[�̃u���b�N�̒���̒��O���Ō�̃u���b�N�ɂ���
@@:
3:
;<a2.l:�擪�̃u���b�N�̃w�b�_
dosSMfreeSetEnd:
	addq.l	#4,sp
	movem.l	(sp)+,d1-d7/a0-a4
  debug '|s_mfree done; jump to kill_pr',0
	move.l	killPrEntry,-(sp)	;_KILL_PR��
	rts

dosSMfreeParamError:
	moveq.l	#$FFFFFFF2,d0		;�p�����[�^������
  debug '|s_mfree out; illegal parameter',0
	rts

;----------------------------------------------------------------
;_S_PROCESS	�T�u�X���b�h�̃�������Ԃ̐ݒ�
;	�T�u�������^�T�u�X���b�h�̂Ƃ��T�u�X���b�h�̃�������Ԃ̐擪�̃u���b�N�̃w�b�_�����
;	�A���������^�T�u�X���b�h�̂Ƃ��T�u�X���b�h�̃�������Ԃ̒���Ƀ_�~�[�̃w�b�_�����
;	�r����������쐬����
;<(a6).w:�X���b�h�ԍ�
;<(2,a6).l:�u���b�N�̐擪�A�h���X
;<(6,a6).l:�T�u�̃������Ǘ��̃T�C�Y
;<(10,a6).l:�擪�̃u���b�N�̃T�C�Y
;>d0.l:�擪�̃u���b�N�̃��[�U�̈�̐擪
;	$FFFFxxxx=�ő�X���b�h�ԍ�,$FFFFFFF2=�u���b�N�̎w�肪�Ⴄ
;*d0,?d1-d4/d7/a0-a2/a4-a5
dosSProcess::
  debug '|s_process in (thread-id,ptr,size,head-size)=',4,(-2,a6),(2,a6),(6,a6),(10,a6)
	moveq.l	#$FFFFFFFF,d0
	move.w	($1C58).w,d0		;process�̃X���b�h��-1
	beq	dosSProcessEnd		;process���ݒ肳��Ă��Ȃ�
;<d0.l:$FFFF0000+process�̃X���b�h��-1
	move.w	(a6)+,d1		;�X���b�h�ԍ�
	beq	dosSProcessEnd		;���C���X���b�h�͎w��ł��Ȃ�
	cmp.w	d0,d1
	bhi	dosSProcessEnd		;�X���b�h�ԍ����傫������
;<d1.w:�X���b�h�ԍ�
	movea.l	$1C50.w,a3
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:���C���X���b�h�̃�������Ԃ̐擪
;<a5.l:���C���X���b�h�̃�������Ԃ̖���+1
	moveq.l	#tSize,d2
	mulu.w	d1,d2
	adda.l	d2,a3
;<a3.l:�X���b�h�Ǘ��e�[�u��
	tst.l	(tProcess,a3)
	beq	dosSProcessEnd		;���g�p�̃X���b�h
	movem.l	(a6)+,d2-d4
;<d2.l:�T�u�X���b�h�̃�������Ԃ̐擪
;<d3.l:�T�u�X���b�h�̃�������Ԃ̃T�C�Y
;<d4.l:�擪�̃u���b�N�̃T�C�Y
	move.l	#LOGICAL_SIZE-1,d0	;�I�[�o�[�t���[���Ȃ��悤�ɂ���
	cmp.l	d0,d3
	bls	@f
	move.l	d0,d3
@@:	cmp.l	d0,d4
	bls	@f
	move.l	d0,d4
@@:
	moveq.l	#$0000000F,d0
	add.l	d0,d3
	moveq.l	#$FFFFFFF0,d0
	and.w	d0,d3			;�T�C�Y��16�̔{���ɐ؂�グ��
;�u���b�N����������
	bsr	searchBlock
	bpl	dosSProcessContinuous	;�A���������^�T�u�X���b�h
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2
	bsr	searchBlock
	bmi	dosSProcessParamError	;�p�����[�^������

;�T�u�������^�T�u�X���b�h
;	�T�u�X���b�h�̃�������Ԃ̐擪�̃u���b�N�̃w�b�_�����
;<d3.l:�T�u�X���b�h�̃�������Ԃ̃T�C�Y
;<d4.l:�擪�̃u���b�N�̃T�C�Y
;<a2.l:�e�u���b�N�̃w�b�_
;<a3.l:�X���b�h�Ǘ��e�[�u��
	lea.l	(User,a2),a4		;�T�u�X���b�h�̃�������Ԃ̐擪
	lea.l	(a4,d3.l),a5		;�T�u�X���b�h�̃�������Ԃ̖���+1
;<a4.l:�T�u�X���b�h�̃�������Ԃ̐擪
;<a5.l:�T�u�X���b�h�̃�������Ԃ̖���+1
	cmpa.l	(Tail,a2),a5
	bhi	dosSProcessParamError	;�e�u���b�N������������
	lea.l	(User,a4,d4.l),a1	;�擪�̃u���b�N�̖���+1
;<a1.l:�擪�̃u���b�N�̖���+1
	cmpa.l	a5,a1
	bhi	dosSProcessParamError	;�擪�̃u���b�N���傫������
	movea.l	a4,a0			;�擪�̃u���b�N�̃w�b�_��ݒ�
	clr.l	(a0)+			;���O
	clr.l	(a0)+			;�v���Z�X
	move.l	a1,(a0)+		;����+1
	clr.l	(a0)			;����
	bra	dosSProcessSetEnd

;�A���������^�T�u�X���b�h
;	�T�u�X���b�h�̃�������Ԃ̒���Ƀ_�~�[�̃w�b�_�����
;<d3.l:�T�u�X���b�h�̃�������Ԃ̃T�C�Y
;<d4.l:�擪�̃u���b�N�̃T�C�Y
;<a2.l:�擪�̃u���b�N�̃w�b�_
;<a3.l:�X���b�h�Ǘ��e�[�u��
dosSProcessContinuous:
	movea.l	a2,a4			;�T�u�X���b�h�̃�������Ԃ̐擪
	lea.l	(a4,d3.l),a5		;�T�u�X���b�h�̃�������Ԃ̖���+1,�_�~�[�̃w�b�_
;<a4.l:�T�u�X���b�h�̃�������Ԃ̐擪
;<a5.l:�T�u�X���b�h�̃�������Ԃ̖���+1
	lea.l	(User,a5),a0		;�_�~�[�̃w�b�_�̖���+1
	cmpa.l	(Tail,a2),a0
	bhi	dosSProcessParamError	;�擪�̃u���b�N�̌��݂̃T�C�Y������������
	lea.l	(User,a4,d4.l),a1	;�擪�̃u���b�N�̖���+1
;<a1.l:�擪�̃u���b�N�̖���+1
	cmpa.l	a5,a1
	bhi	dosSProcessParamError	;�擪�̃u���b�N���傫������
	movea.l	a5,a0			;�_�~�[�̃u���b�N�̃w�b�_��ݒ�
	move.l	a4,(a0)+		;���O
	clr.l	(a0)+			;�v���Z�X
	move.l	(Tail,a4),(a0)+		;����+1
	move.l	(Next,a4),(a0)		;����
					;�擪�̃u���b�N�̃w�b�_��ݒ�
	move.l	a5,(Tail,a4)		;����+1
	move.l	a5,(Next,a5)		;����

;<d3.l:�T�u�X���b�h�̃�������Ԃ̃T�C�Y
;<d4.l:�擪�̃u���b�N�̃T�C�Y
;<a2.l:�擪�̃u���b�N�̃w�b�_
;<a3.l:�X���b�h�Ǘ��e�[�u��
;<a4.l:�T�u�X���b�h�̃�������Ԃ̐擪
;<a5.l:�T�u�X���b�h�̃�������Ԃ̖���+1
dosSProcessSetEnd:
	or.b	#$C0,(Proc,a2)		;�e�܂��͐擪�̃u���b�N�Ƀt���O���Z�b�g
	move.l	a4,(tMemStart,a3)	;�T�u�X���b�h�̃�������Ԃ�ݒ�
	move.l	a5,(tMemEnd,a3)

dosSProcessEnd:
  debug '|s_process out (ptr or max-id)=',1,d0
	rts

dosSProcessParamError:
	moveq.l	#$FFFFFFF2,d0		;�p�����[�^������
  debug '|s_process out; illegal parameter',0
	rts

;----------------------------------------------------------------
;_OPEN_PR�ǉ�����
;	�X���b�h���쐬���ꂽ����ɌĂ΂��
;	�r����������쐬����
;<d0.w:�쐬���ꂽ�X���b�h�ԍ�
dosOpenPr::
	movem.l	d0-d2/a0-a2,-(sp)
	move.w	d0,d1
	beq	dosOpenPrEnd		;�O�̂���
	tst.l	(xTable,d1.w*4)
	bpl	dosOpenPrEnd		;�O�̂���
	subq.w	#1,d0			;���C���X���b�h�̕�������
	mulu.w	#xSize2,d0
	lea.l	([exclusiveStart],d0.l),a2	;�r��������̐擪
	move.l	a2,(xTable,d1.w*4)
;<a2.l:�V�����X���b�h�̔r��������̃A�h���X

;FPU�̏�Ԃ��쐬����
	movea.l	a2,a0
	moveq.l	#120/4-1,d2
@@:	clr.l	(a0)+			;���ׂăN���A
	dbra	d2,@b
	move.w	#$6000,(xFsave+2,a2)	;NULL
;�W���n���h�����쐬����
	moveq.l	#0,d2
1:	move.w	d2,d0
	bsr	callDup			;���݂̕W���n���h���𕡐�����
	bpl	2f
	moveq.l	#-1,d0			;�r��������̕W���n���h����-1�̂Ƃ���,
					;���C���X���b�h�̔r����������g��
2:	move.w	d0,(xStdin,a2,d2.w*2)
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;�W���n���h���ϊ��e�[�u�����쐬����
	movea.l	stdHdlDup0,a0		;���݂̕W���n���h���ϊ��e�[�u��
	lea.l	(xDup0Table,a2),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;�h���C�u�Ǘ��e�[�u���̃A�h���X��ݒ肵,�e�[�u���̖{�̂��쐬����
	lea.l	(xDriveTable,a2),a1	;�h���C�u�Ǘ��e�[�u���̐擪
	move.l	a1,(xDriveTablePtr,a2)	;�h���C�u�Ǘ��e�[�u���̃A�h���X
	movea.l	$1C38.w,a0		;���݂̃h���C�u�Ǘ��e�[�u��
	moveq.l	#1,d0
	add.b	$1C74.w,d0		;�h���C�u�Ǘ��e�[�u���̌�
	mulu.w	#dSize,d0		;�h���C�u�Ǘ��e�[�u���̃T�C�Y
	lsr.w	#1,d0
	subq.w	#1,d0
@@:	move.w	(a0)+,(a1)+		;���݂̃h���C�u�Ǘ��e�[�u�����R�s�[����
	dbra	d0,@b
;�J�����g�h���C�u���쐬����
	move.b	$1C15.w,(xCurrentDrive,a2)	;���݂̃J�����g�h���C�u
;break�̃��[�h���쐬����
	move.b	#2,(xBreakMode,a2)	;���kill
dosOpenPrEnd:
	movem.l	(sp)+,d0-d2/a0-a2
	rts

;----------------------------------------------------------------
;_KILL_PR�ǉ�����
;	�X���b�h���폜���ꂽ����ɌĂ΂��
;	�r���������j������
;<d0.w:�폜���ꂽ�X���b�h�ԍ�-1
dosKillPr::
	addq.w	#1,d0
;<d0.w:�X���b�h�ԍ�
	bsr	killExclusive		;�r���������j������
	subq.w	#1,d0
	rts

;----------------------------------------------------------------
;_CHANGE_PR�ǉ�����
;	�X���b�h���؂�ւ��������ɌĂ΂��
;	�r���������؂�ւ���
;<d0.w:���̃X���b�h�ԍ�
dosChangePr::
	movem.l	d0-d2/a0-a3,-(sp)
;�r��������̕ۑ�
	move.w	currentThreadId,d1	;���݂̃X���b�h
	cmp.w	d1,d0			;�O�̂���
	beq	dosChangePrEnd
	move.w	d0,currentThreadId	;���̃X���b�h
	move.l	(xTable,d1.w*4),d0	;���݂̔r��������̐擪
	bmi	dosChangePrLoad		;�O�̂���
	movea.l	d0,a2
;<a2.l:���݂̔r��������̐擪

;FPU�̏�Ԃ�ۑ�����
	fsave		(xFsave,a2)
	fmovem.l	fpcr/fpsr/fpiar,(xFpcr,a2)
	fmovem.x	fp0-fp7,(xFp0,a2)
;�W���n���h����ۑ�����
	moveq.l	#0,d2
1:	move.w	(xStdin,a2,d2.w*2),d0
	bmi	2f
	move.w	d2,d1
	bsr	dup2
2:	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;�W���n���h���ϊ��e�[�u����ۑ�����
	movea.l	stdHdlDup0,a0		;�W���n���h���ϊ��e�[�u��
	lea.l	(xDup0Table,a2),a1
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;�h���C�u�Ǘ��e�[�u���̃A�h���X��ۑ�����(�O�̂���)
	move.l	$1C38.w,(xDriveTablePtr,a2)
;�J�����g�h���C�u��ۑ�����
	move.b	$1C15.w,(xCurrentDrive,a2)
;break�̃��[�h��ۑ�����
	move.b	$1C12.w,(xBreakMode,a2)

;�r��������̍Đ�
dosChangePrLoad:
	move.w	currentThreadId,d0	;���̃X���b�h�ԍ�
	beq	dosChangePrMain
	move.l	(xTable,d0.w*4),d0	;���̃X���b�h�̔r��������
	bmi	dosChangePrMain		;���̃X���b�h�̔r�������񂪂Ȃ����,
					;���C���X���b�h�̔r����������g��
	movea.l	d0,a2
	lea.l	mainExclusive,a3	;���C���X���b�h�̔r��������
;<a2.l:���̃X���b�h�̔r��������̃A�h���X
;<a3.l:���C���X���b�h�̔r��������̃A�h���X

;FPU�̏�Ԃ��Đ�����
	fmovem.x	(xFp0,a2),fp0-fp7
	fmovem.l	(xFpcr,a2),fpcr/fpsr/fpiar
	frestore	(xFsave,a2)
;�W���n���h�����Đ�����
	moveq.l	#0,d2
1:	move.w	d2,d0
	move.w	(xStdin,a2,d2.w*2),d1
	bpl	2f
	move.w	(xStdin,a3,d2.w*2),d1
2:	bsr	dup2
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;�W���n���h���ϊ��e�[�u�����Đ�����
	lea.l	(xDup0Table,a2),a0
	movea.l	stdHdlDup0,a1		;�W���n���h���ϊ��e�[�u��
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;�h���C�u�Ǘ��e�[�u�����Đ�����
	move.l	(xDriveTablePtr,a2),$1C38.w
;�J�����g�h���C�u���Đ�����
	move.b	(xCurrentDrive,a2),$1C15.w
;break�̃��[�h���Đ�����
	move.b	#2,$1C12.w		;�����̓T�u�X���b�h�݂̂Ȃ̂ŏ��kill
;
dosChangePrEnd:
	movem.l	(sp)+,d0-d2/a0-a3
	rts

;���C���X���b�h�̔r����������Đ�����
dosChangePrMain:
	bsr	loadMainExclusive
	bra	dosChangePrEnd

;----------------------------------------------------------------
;�r���������j������
;	�j��������A��U���C���X���b�h�̔r����������Đ�����
;<d0.w:�X���b�h�ԍ�
killExclusive:
	movem.l	d0-d2/a2,-(sp)
	move.w	d0,d1
	beq	killExclusiveEnd	;���C���X���b�h�̔r��������͔j���ł��Ȃ�
	move.l	(xTable,d1.w*4),d0
	bmi	killExclusiveEnd	;�r�������񂪑��݂��Ȃ�
	move.l	#-1,(xTable,d1.w*4)	;�r���������j������
	movea.l	d0,a2			;�r��������̐擪
;<a2.l:�r��������̃A�h���X

;�W���n���h����j������
	moveq.l	#0,d2
1:	move.w	(xStdin,a2,d2.w*2),d0
	bmi	2f
	bsr	callClose
2:	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b

;���C���X���b�h�̔r����������Đ�����
	bsr	loadMainExclusive
;
killExclusiveEnd:
	movem.l	(sp)+,d0-d2/a2
	rts

;----------------------------------------------------------------
;���C���X���b�h�̔r����������Đ�����
loadMainExclusive:
	movem.l	d0/d2/a0-a2,-(sp)
	clr.w	currentThreadId		;���C���X���b�h�̔r��������Ɉڍs

	lea.l	mainExclusive,a2
;<a2.l:���C���X���b�h�̔r��������̃A�h���X

;FPU�̏�Ԃ��Đ�����
	fmovem.x	(xFp0,a2),fp0-fp7
	fmovem.l	(xFpcr,a2),fpcr/fpsr/fpiar
	frestore	(xFsave,a2)
;�W���n���h�����Đ�����
	moveq.l	#0,d2
1:	move.w	d2,d0
	move.w	(xStdin,a2,d2.w*2),d1	;���C���X���b�h�Ȃ̂ŕ����͗L�蓾�Ȃ�
	bsr	dup2
	addq.w	#1,d2
	cmp.w	#5,d2
	blo	1b
;�W���n���h���ϊ��e�[�u�����Đ�����
	lea.l	(xDup0Table,a2),a0
	movea.l	stdHdlDup0,a1		;�W���n���h���ϊ��e�[�u��
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.w	(a0)+,(a1)+
;�h���C�u�Ǘ��e�[�u�����Đ�����
	move.l	(xDriveTablePtr,a2),$1C38.w
;�J�����g�h���C�u���Đ�����
	move.b	(xCurrentDrive,a2),$1C15.w
;break�̃��[�h���Đ�����
	move.b	(xBreakMode,a2),$1C12.w	;���C���X���b�h�Ȃ̂�break�̃��[�h�𕜌�����
;
	movem.l	(sp)+,d0/d2/a0-a2
	rts

;----------------------------------------------------------------
;�n���h���N���[�Y
;	_CLOSE���Ăяo��
;	�n���h����Human�̃v���Z�X�Ǘ��e�[�u���ŃN���[�Y����
;<d0.w:�n���h���ԍ�
;?d0
callClose:
	movem.l	d1-d7/a0-a6,-(sp)
	move.w	d0,-(sp)
	movea.l	sp,a6
	movea.l	$1C28.w,a0
	move.l	(a0),-(sp)
	move.l	$1C20.w,(a0)		;Human�̃������Ǘ��e�[�u��
	jsr	([$1800+(_CLOSE-$FF00)*4.w])
	move.l	(sp)+,([$1C28.w])
	addq.l	#2,sp
	movem.l	(sp)+,d1-d7/a0-a6
	rts

;----------------------------------------------------------------
;�n���h������
;	_DUP���Ăяo��
;	�V�����n���h����Human�̃v���Z�X�Ǘ��e�[�u���ŃI�[�v������
;<d0.w:�n���h���ԍ�
;?d0
callDup:
	movem.l	d1-d7/a0-a6,-(sp)
	move.w	d0,-(sp)
	movea.l	sp,a6
	movea.l	$1C28.w,a0
	move.l	(a0),-(sp)
	move.l	$1C20.w,(a0)		;Human�̃������Ǘ��e�[�u��
	jsr	([$1800+(_DUP-$FF00)*4.w])
	move.l	(sp)+,([$1C28.w])
	addq.l	#2,sp
	movem.l	(sp)+,d1-d7/a0-a6
	tst.l	d0
	rts

;----------------------------------------------------------------
;�����n���h���R�s�[
;	_DUP2�̃G���[�`�F�b�N�����ׂďȂ�������
;<d0.w:�R�s�[��̃n���h���ԍ�(�I�[�v������Ă��邱��)
;<d1.w:�R�s�[���̃n���h���ԍ�(�I�[�v������Ă��邱��)
;?d0-d1/a0-a1
dup2:
	bsr	getfcb
	subq.b	#1,(a0)
	move.w	d1,d0
	move.l	a1,d1
	bsr	getfcb
	addq.b	#1,(a0)
	movea.l	d1,a0
	move.w	(a1),(a0)
	rts

;----------------------------------------------------------------
;�n���h���ԍ�����FCB�e�[�u���̃A�h���X�����߂�
;	_GETFCB�̃G���[�`�F�b�N�����ׂďȂ�������
;<d0.w:�n���h���ԍ�
;>a0.l:FCB�e�[�u��
;>a1.l:�n���h��FCB�ϊ��e�[�u����̃A�h���X
;*a0-a1,?d0
getfcb:
	movea.l	stdHdlToFcb,a1		;�n���h���ԍ�=0�`5�̃n���h��FCB�ϊ��e�[�u��
	cmp.w	#6,d0
	bcs	@f
	subq.w	#6,d0
	movea.l	$1C2C.w,a1		;�n���h��FCB�ϊ��e�[�u���̐擪(1��2�o�C�g)
@@:	add.w	d0,d0
	adda.w	d0,a1
	move.w	(a1),d0
	ext.w	d0
	movea.l	stdFcbTable,a0		;FCB�ԍ�=0�`5��FCB�e�[�u��
	cmp.w	#6,d0
	bcs	@f
	subq.w	#6,d0
	movea.l	$1C30.w,a0		;FCB�e�[�u���̐擪(1��96�o�C�g)
@@:	mulu.w	#96,d0
	adda.w	d0,a0
	rts

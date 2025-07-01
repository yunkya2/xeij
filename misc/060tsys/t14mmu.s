;----------------------------------------------------------------
;
;	�A�h���X�ϊ��Ɋ֘A���郋�[�`���Q
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;�A�h���X�ϊ��e�[�u��(�f�X�N���v�^�̗̈�)
;
;	�A�h���X�ϊ��e�[�u���̓��C���������܂��̓��[�J����������ɔz�u
;	�A�h���X�ϊ��e�[�u����$00002000(8KB)�Ŋ���؂��A�h���X�ɒu��
;
;	�A�h���X�ϊ��e�[�u���̓X�[�p�[�o�C�U�̈�Ƃ���
;	�A�h���X�ϊ��e�[�u���̓��C�g�v���e�N�g����
;	�A�h���X�ϊ��e�[�u���ւ̃A�N�Z�X��FC_MMU_DATA�ɑ΂���MOVES�ōs��
;
;	�A�h���X�ϊ��e�[�u���͎���3�̃f�X�N���v�^�e�[�u�����琬��
;		���[�g�f�X�N���v�^�e�[�u��
;		�|�C���^�f�X�N���v�^�e�[�u��
;		�y�[�W�f�X�N���v�^�e�[�u��
;
;	���[�g�f�X�N���v�^�e�[�u���͉��ʑ��ɌŒ�
;	�|�C���^�f�X�N���v�^�e�[�u���͉��ʑ������ʑ��֐L��(�����𓮂���)
;	�y�[�W�f�X�N���v�^�e�[�u���͏�ʑ����牺�ʑ��֐L��(�擪�𓮂���)
;
;	�����ȃf�X�N���v�^�͕K��32�r�b�g���ׂĂ�0�ɂ���
;	�f�X�N���v�^�e�[�u���̓��e�����ׂĖ����ɂȂ�����e�[�u�����ƊJ������
;
;	�y�[�W�f�X�N���v�^�e�[�u���̌�Ƀf�X�N���v�^�̎Q�Ɛ��J�E���^�̃e�[�u��������
;		�|�C���^�f�X�N���v�^�Q�Ɛ��J�E���^�e�[�u��
;		�y�[�W�f�X�N���v�^�Q�Ɛ��J�E���^�e�[�u��
;
;	�Q�Ɛ��J�E���^�̃e�[�u���̓��e�͎Q�Ɛ�-1
;	�Q�Ɛ��J�E���^��-1�̃f�X�N���v�^�e�[�u���͖��g�p�ł��邱�Ƃ��Ӗ�����
;
;	�_���A�h���X��30�r�b�g�Ȃ̂ŁA�A�h���X�̏��2�r�b�g�̈Ⴂ�͖��������
;	���[�g�f�X�N���v�^�e�[�u����16�̃f�X�N���v�^�̃Z�b�g��8���ׂ����̂ɂȂ�
;	�_���A�h���X�̏��2�r�b�g��0�łȂ����[�g�f�X�N���v�^�͎Q�Ɛ��J�E���^�ɉe�����Ȃ�
;
;			      ���e		�A�h���X��ێ����Ă���ϐ�
;		��������������������������������descHead/rootDescHead
;		�� ���[�g�f�X�N���v�^�e�[�u�� ��
;		��������������������������������rootDescTail
;		��������������������������������pointerDescHead
;		���|�C���^�f�X�N���v�^�e�[�u����
;		��������������������������������
;		���|�C���^�f�X�N���v�^�e�[�u����
;		��������������������������������
;		��	     ���g�p	      ��
;		��������������������������������
;		���|�C���^�f�X�N���v�^�e�[�u����
;		��������������������������������
;		��	     ���g�p	      ��
;		��������������������������������
;		���|�C���^�f�X�N���v�^�e�[�u����
;		��������������������������������pointerDescTail
;		��	       ��	      ��
;		��			      ��
;		��	     ���g�p	      ��
;		��			      ��
;		��	       ��	      ��
;		��������������������������������pageDescHead
;		�� �y�[�W�f�X�N���v�^�e�[�u�� ��
;		��������������������������������
;		�� �y�[�W�f�X�N���v�^�e�[�u�� ��
;		��������������������������������
;		��	     ���g�p	      ��
;		��������������������������������
;		��	     ���g�p	      ��
;		��������������������������������
;		�� �y�[�W�f�X�N���v�^�e�[�u�� ��
;		��������������������������������pageDescTail
;		��������������������������������pointerCounterHead
;		��	     �O�ȏ�	      ��
;		��������������������������������
;		��	     �O�ȏ�	      ��
;		��������������������������������
;		��	      �|�P	      ��
;		��������������������������������
;		��	     �O�ȏ�	      ��
;		��������������������������������
;		��	      �|�P	      ��
;		��������������������������������
;		��	     �O�ȏ�	      ��
;		��������������������������������
;		��	       ��	      ��
;		��			      ��
;		��	     ���g�p	      ��
;		��			      ��
;		��	       ��	      ��
;		��������������������������������
;		��	     �O�ȏ�	      ��
;		��������������������������������
;		��	     �O�ȏ�	      ��
;		��������������������������������
;		��	      �|�P	      ��
;		��������������������������������
;		��	      �|�P	      ��
;		��������������������������������
;		��	     �O�ȏ�	      ��
;		��������������������������������pageCounterTail/descTail
;
;----------------------------------------------------------------


;----------------------------------------------------------------
;�f�X�N���v�^�̖�����
;<a1.l:�_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�X�V�O�̃y�[�W�f�X�N���v�^
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
invDesc::
	movem.l	d7/a0/a2,-(sp)
	bsr	getDesc
	move.l	d0,d7
	bmi	8f			;�f�X�N���v�^�����݂��Ȃ�
	beq	8f			;�f�X�N���v�^������
	moveq.l	#0,d0
	moves.l	d0,(a0)
;�f�X�N���v�^�e�[�u��������
	move.l	rootDescHead,d0
	bsr	getRootDesc
	movea.l	a0,a2			;���[�g�f�X�N���v�^�̃A�h���X
	and.l	#POINTER_DESC_MASK,d0	;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDesc
;�y�[�W�f�X�N���v�^�e�[�u���S�̂������ɂȂ�����|�C���^�f�X�N���v�^�𖳌�������
	move.l	a0,d0			;�|�C���^�f�X�N���v�^�̃A�h���X
	bsr	invUpPageDescTable
	bne	8f
;�|�C���^�f�X�N���v�^�e�[�u���S�̂������ɂȂ����烋�[�g�f�X�N���v�^�𖳌�������
	move.l	a2,d0			;���[�g�f�X�N���v�^�̃A�h���X
	bsr	invUpPointerDescTable
8:	move.l	d7,d0
	movem.l	(sp)+,d7/a0/a2
	rts

;----------------------------------------------------------------
;���L�f�X�N���v�^�̐ݒ�(�Ԑڃy�[�W�f�X�N���v�^���܂�)
;<d2.l:�_���A�h���X(�y�[�W�f�X�N���v�^�����݂��邱��)
;<a1.l:�_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�X�V�O�̃y�[�W�f�X�N���v�^
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;	-2	�ϊ���̃y�[�W�f�X�N���v�^�����݂��Ȃ�
comDesc::
	movem.l	d1-d2/d7/a0-a6,-(sp)
	exg.l	d2,a1
	bsr	getDesc			;�ϊ���̃y�[�W�f�X�N���v�^�����߂�
	bmi	9f
	movea.l	d2,a1
	move.l	a0,d2			;�y�[�W�f�X�N���v�^�̃A�h���X
	addq.l	#%10,d2			;PDT=%10(�Ԑ�)
	bsr	setDesc			;�Ԑڃy�[�W�f�X�N���v�^��ݒ肷��
	move.l	d0,d7
	bmi	8f
;�f�X�N���v�^�e�[�u��������
	move.l	rootDescHead,d0
	bsr	getRootDesc
	movea.l	a0,a2			;���[�g�f�X�N���v�^�̃A�h���X
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a3			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDesc
	movea.l	a0,a4			;�|�C���^�f�X�N���v�^�̃A�h���X
	and.l	pageDescMask,d0
	movea.l	d0,a5			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
;�y�[�W�f�X�N���v�^�e�[�u���̂��ׂẴy�[�W�f�X�N���v�^���A
;��l�ɑ��̃y�[�W�f�X�N���v�^�e�[�u���ւ̊Ԑڃy�[�W�f�X�N���v�^���ǂ������ׂ�
	movea.l	a5,a0
	moves.l	(a0)+,d0		;�擪�̃y�[�W�f�X�N���v�^
	moveq.l	#%11,d1
	and.l	d0,d1			;PDT
	subq.l	#%10,d1
	bne	8f			;�ԐڂłȂ�
	subq.l	#%10,d0
	move.l	d0,d1
	and.l	pageDescMask,d0
	cmp.l	d1,d0
	bne	8f			;�y�[�W�f�X�N���v�^�e�[�u���̐擪�łȂ�
	movea.l	d0,a6			;�Ԑڃy�[�W�f�X�N���v�^���w���Ă����y�[�W�f�X�N���v�^�e�[�u���̐擪
	addq.l	#%10,d1
	moveq.l	#PAGE_INDEX_SIZE-1-1,d2
@@:	addq.l	#4,d1
	moves.l	(a0)+,d0
	cmp.l	d1,d0			;�Ԑڃy�[�W�f�X�N���v�^�Ȃ̂ł��̂܂ܔ�r�ł���
	dbne	d2,@b
	bne	8f			;�قȂ�y�[�W�f�X�N���v�^������
;�y�[�W�f�X�N���v�^�e�[�u����؂藣���āA
;�Ԑڃy�[�W�f�X�N���v�^���w���Ă����y�[�W�f�X�N���v�^�e�[�u���Ɍq��
	move.l	a3,d0
	move.l	a6,d1			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
;		  U W UDT
	addq.l	#%0_0_11,d1
	bsr	setPointerDesc
;�_���A�h���X�̏��8�r�b�g���N���A�����ꍇ�̃f�X�N���v�^�e�[�u��������
	move.l	a1,d0
	and.l	#$00FFFFFF,d0
	cmpa.l	d0,a1
	beq	8f			;$00xxxxxx�Ȃ̂Ŋ֌W�Ȃ�
	move.l	a1,-(sp)
	movea.l	d0,a1			;�_���A�h���X�ύX
	move.l	rootDescHead,d0
	bsr	getRootDesc
	movea.l	(sp)+,a1
	bmi	8f			;�Ȃ��͂��͂Ȃ����O�̂���
	movea.l	a0,a4			;���[�g�f�X�N���v�^�̃A�h���X
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a5			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	cmpa.l	a3,a5
	beq	8f			;�����|�C���^�f�X�N���v�^�e�[�u���Ȃ̂Ŋ֌W�Ȃ�
;�|�C���^�f�X�N���v�^�e�[�u���̂��ׂẴ|�C���^�f�X�N���v�^���A
;�_���A�h���X�̏��8�r�b�g���N���A�����ꍇ�̃|�C���^�f�X�N���v�^�e�[�u���ƁA
;��v���Ă��邩���ׂ�
	move.l	a1,-(sp)
	movea.l	a3,a0			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	movea.l	a5,a1			;�_���A�h���X�̏��8�r�b�g���N���A�����ꍇ��
					;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	cmpPointerDescTable
	movea.l	(sp)+,a1
	bne	8f			;��v���Ȃ�
;�|�C���^�f�X�N���v�^�e�[�u����؂藣���āA
;�_���A�h���X�̏��8�r�b�g���N���A�����ꍇ�̃|�C���^�f�X�N���v�^�e�[�u���Ɍq��
	move.l	rootDescHead,d0
	moves.l	(a4),d1			;���[�g�f�X�N���v�^
	bsr	setRootDesc
8:	move.l	d7,d0
	movem.l	(sp)+,d1-d2/d7/a0-a6
	rts

9:	moveq.l	#-2,d7
	bra	8b

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�̐ݒ�
;	���̃v���O�������g�⊄�荞�݃��[�`���Ŏg�p���̗̈�͎w�肵�Ȃ�����
;<d2.l:�y�[�W�f�X�N���v�^
;<a1.l:�_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�X�V�O�̃y�[�W�f�X�N���v�^
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
setDesc::
	movem.l	d1-d2/d7/a0/a2-a5,-(sp)
	moveq.l	#0,d7			;�X�V�O�̃y�[�W�f�X�N���v�^
;PDT=%00�Ȃ�ΑS�̂�0�ɂ���
	moveq.l	#%11,d0
	and.l	d2,d0			;PDT
	bne	@f
	moveq.l	#0,d2			;PDT=%00�Ȃ�ΑS�̂�0�ɂ���
@@:
;$00000000�`$00FFFFFF�̃y�[�W�f�X�N���v�^�͖�����Ԑڂɂł��Ȃ�
	cmpa.l	#$01000000,a1
	bhs	@f
	btst.l	#0,d2
	beq	9f			;PDT=%00(����),%10(�Ԑ�)
@@:
;�f�X�N���v�^�e�[�u����H��
	move.l	rootDescHead,d0
	beq	9f			;���[�g�f�X�N���v�^�e�[�u�����Ȃ�
;���[�g�f�X�N���v�^�e�[�u�������݂���
	bsr	getRootDesc
	movea.l	a0,a2			;���[�g�f�X�N���v�^�̃A�h���X
	beq	1f			;���[�g�f�X�N���v�^������(�|�C���^�f�X�N���v�^�e�[�u�����Ȃ�)
;�|�C���^�f�X�N���v�^�e�[�u�������݂���
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a3			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDesc
	movea.l	a0,a4			;�|�C���^�f�X�N���v�^�̃A�h���X
	beq	2f			;�|�C���^�f�X�N���v�^������(�y�[�W�f�X�N���v�^�e�[�u�����Ȃ�)
;�y�[�W�f�X�N���v�^�e�[�u�������݂���
	and.l	pageDescMask,d0
	movea.l	d0,a5			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
	bsr	getPageDesc
	move.l	d0,d7			;�X�V�O�̃y�[�W�f�X�N���v�^
	beq	3f			;�y�[�W�f�X�N���v�^������
;�y�[�W�f�X�N���v�^���L��
;�L���b�V���t���b�V��
	and.l	pageMask,d0		;�����y�[�W�A�h���X
	movea.l	d0,a2			;�����y�[�W�A�h���X
	cpushp	dc,(a2)			;�f�[�^�L���b�V���v�b�V��
	cinvp	bc,(a2)			;�L���b�V��������
;�y�[�W�f�X�N���v�^�̎Q�Ɛ����`�F�b�N
3:	move.l	a5,d0			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
	bsr	getPageDescCount	;�Q�Ɛ��J�E���^�𒲂ׂ�
	beq	4f			;1�ӏ���������Q�Ƃ���Ă���
;�y�[�W�f�X�N���v�^�e�[�u����2�ӏ��ȏォ��Q�Ƃ���Ă���̂ŐV�������
	movea.l	a5,a0			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
	bsr	dupPageDescTable	;�y�[�W�f�X�N���v�^�e�[�u���𕡐�����
	bra	6f

;�|�C���^�f�X�N���v�^������(�y�[�W�f�X�N���v�^�e�[�u�����Ȃ�)
2:	bsr	callocPageDescTable	;�y�[�W�f�X�N���v�^�e�[�u�������
6:	bmi	9f			;�f�X�N���v�^�̗̈悪�s�����Ă���
	movea.l	d0,a5			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
;�|�C���^�f�X�N���v�^�̎Q�Ɛ����`�F�b�N
	move.l	a3,d0			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDescCount
	beq	5f			;1�ӏ���������Q�Ƃ���Ă���
;�|�C���^�f�X�N���v�^�e�[�u����2�ӏ��ȏォ��Q�Ƃ���Ă���̂ŐV�������
	movea.l	a3,a0			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	dupPointerDescTable	;�|�C���^�f�X�N���v�^�e�[�u���𕡐�����
	bra	7f

;���[�g�f�X�N���v�^������(�|�C���^�f�X�N���v�^�e�[�u�����Ȃ�)
1:	bsr	callocPageDescTable	;�y�[�W�f�X�N���v�^�e�[�u�������
	bmi	9f			;�f�X�N���v�^�̗̈悪�s�����Ă���
	movea.l	d0,a5			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
	bsr	callocPointerDescTable	;�|�C���^�f�X�N���v�^�e�[�u�������
7:	bmi	9f			;�f�X�N���v�^�̗̈悪�s�����Ă���
	movea.l	d0,a3			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDesc
	movea.l	a0,a4			;�|�C���^�f�X�N���v�^�̃A�h���X
;���[�g�f�X�N���v�^���X�V����
	move.l	rootDescHead,d0		;���[�g�f�X�N���v�^�e�[�u���̐擪
	move.l	a3,d1			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
;		  U W UDT
	addq.l	#%0_0_11,d1		;UDT=%11(�L��)
	bsr	setRootDesc		;���[�g�f�X�N���v�^���X�V
;�|�C���^�f�X�N���v�^��1�ӏ���������Q�Ƃ���Ă���̂Œ��ڍX�V����
5:	move.l	a3,d0			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	move.l	a5,d1			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
;		  U W UDT
	addq.l	#%0_0_11,d1		;UDT=%11(�L��)
	bsr	setPointerDesc		;�|�C���^�f�X�N���v�^���X�V
;�y�[�W�f�X�N���v�^�e�[�u����1�ӏ���������Q�Ƃ���Ă���̂Œ��ڍX�V����
;�Ԑڃy�[�W�f�X�N���v�^�ɂ��Q�Ƃ��������ꍇ�͂�����X�V����邱�ƂɂȂ�
4:	move.l	a5,d0			;�y�[�W�f�X�N���v�^�e�[�u���̐擪
	move.l	d2,d1			;�y�[�W�f�X�N���v�^
	bsr	setPageDesc		;�y�[�W�f�X�N���v�^���X�V
;��n��
8:	bsr	cleanPointerDesc
	bsr	cleanPageDesc
;�X�V�O�̃y�[�W�f�X�N���v�^��Ԃ�
	move.l	d7,d0
	movem.l	(sp)+,d1-d2/d7/a0/a2-a5
	rts

9:	moveq.l	#-1,d7
	bra	8b

;----------------------------------------------------------------
;�_���A�h���X����y�[�W�f�X�N���v�^�����߂�
;<a1.l:�_���A�h���X
;<sfc.l:FC_MMU_DATA
;>d0.l:�y�[�W�f�X�N���v�^
;	-1	�y�[�W�f�X�N���v�^���Ȃ�
;	0	�y�[�W�f�X�N���v�^������
;>a0.l:�y�[�W�f�X�N���v�^�̃A�h���X(�Ԑڃy�[�W�f�X�N���v�^�̂Ƃ�(a0)��d0)
;	0	�y�[�W�f�X�N���v�^���Ȃ�
;>n-flag:mi=�y�[�W�f�X�N���v�^���Ȃ�,pl=�y�[�W�f�X�N���v�^������
;>z-flag:(pl)ne=�y�[�W�f�X�N���v�^���L��,eq=�y�[�W�f�X�N���v�^������
getDesc::
	move.l	rootDescHead,d0
	beq	9f			;���[�g�f�X�N���v�^�e�[�u�����Ȃ�
	bsr	getRootDesc		;���[�g�f�X�N���v�^�𓾂�
	beq	9f			;���[�g�f�X�N���v�^������
;<d0.l:���[�g�f�X�N���v�^
;<a0.l:���[�g�f�X�N���v�^�̃A�h���X
	and.l	#POINTER_DESC_MASK,d0
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDesc		;�|�C���^�f�X�N���v�^�𓾂�
	beq	9f			;�|�C���^�f�X�N���v�^������
;<d0.l:�|�C���^�f�X�N���v�^
;<a0.l:�|�C���^�f�X�N���v�^�̃A�h���X
	and.l	pageDescMask,d0
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
	bsr	getPageDesc		;�y�[�W�f�X�N���v�^�𓾂�
;<d0.l:�y�[�W�f�X�N���v�^
;<a0.l:�y�[�W�f�X�N���v�^�̃A�h���X(�Ԑڃy�[�W�f�X�N���v�^�̂Ƃ�(a0)��d0)
;<n-flag:pl
;<z-flag:ne=�y�[�W�f�X�N���v�^���L��,eq=�y�[�W�f�X�N���v�^������
	rts

9:	moveq.l	#-1,d0
	suba.l	a0,a0
;<d0.l:-1
;<a0.l:0
;<n-flag:mi
	rts


;----------------------------------------------------------------
;
;	���[�g�f�X�N���v�^�̑���
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;���[�g�f�X�N���v�^���R�s�[����
;<d0.l:�R�s�[���̘_���A�h���X
;<a1.l:�R�s�[��̘_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�ύX�O�̃��[�g�f�X�N���v�^
;	-1	�G���[
copyRootDesc::
	movem.l	d1/a0-a1,-(sp)
	move.l	a1,d1			;�R�s�[��̘_���A�h���X
	movea.l	d0,a1			;�R�s�[���̘_���A�h���X
	move.l	rootDescHead,d0
	beq	9f
	bsr	getRootDesc		;�R�s�[���̃��[�g�f�X�N���v�^�����߂�
	movea.l	d1,a1			;�R�s�[��̘_���A�h���X
	move.l	d0,d1			;�R�s�[���̃��[�g�f�X�N���v�^
	move.l	rootDescHead,d0
	bsr	setRootDesc		;���[�g�f�X�N���v�^��ύX����
8:	movem.l	(sp)+,d1/a0-a1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;���[�g�f�X�N���v�^���X�V����
;<d0.l:���[�g�f�X�N���v�^�e�[�u���̐擪
;<d1.l:���[�g�f�X�N���v�^
;<a1.l:�_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�X�V�O�̃��[�g�f�X�N���v�^
;	0	���[�g�f�X�N���v�^������
;>n-flag:pl
;>z-flag:ne=���[�g�f�X�N���v�^���L��,eq=���[�g�f�X�N���v�^������
setRootDesc::
	movem.l	d2/d7/a0/a2,-(sp)
	bsr	getRootDesc		;���[�g�f�X�N���v�^�����߂�
	move.l	d0,d7
;�V�����|�C���^�f�X�N���v�^�e�[�u���̃J�E���^��1���₷
;���炷�����ɍs���ƁA���炵���i�K�Ńf�X�N���v�^�e�[�u�����J������Ă��܂���
;���₹�Ȃ��Ȃ��\��������̂ŁA���₷�����ɍs��
	move.l	d1,d0
	beq	1f
	and.l	#POINTER_DESC_MASK,d0
	bsr	incPointerDescCount
1:
;���̃|�C���^�f�X�N���v�^�e�[�u���̃J�E���^��1���炷
	move.l	d7,d0
	beq	2f
	and.l	#POINTER_DESC_MASK,d0
	bsr	decPointerDescCount
2:
;���[�g�f�X�N���v�^���X�V����
	movea.l	a0,a2
	moveq.l	#(1<<(32-LOGICAL_WIDTH))-1,d2
@@:	moves.l	d1,(a2)			;���[�g�f�X�N���v�^���X�V����
	lea.l	(4<<(LOGICAL_WIDTH-25),a2),a2
	dbra	d2,@b
	move.l	d7,d0
	movem.l	(sp)+,d2/d7/a0/a2
	rts

;----------------------------------------------------------------
;���[�g�f�X�N���v�^���擾����
;<d0.l:���[�g�f�X�N���v�^�e�[�u���̐擪
;<a1.l:�_���A�h���X
;	�����ȃr�b�g�͖��������
;<sfc.l:FC_MMU_DATA
;>d0.l:���[�g�f�X�N���v�^
;	0	���[�g�f�X�N���v�^������
;>a0.l:���[�g�f�X�N���v�^�̃A�h���X
;>n-flag:pl
;>z-flag:ne=���[�g�f�X�N���v�^���L��,eq=���[�g�f�X�N���v�^������
getRootDesc::
	movea.l	d0,a0			;���[�g�f�X�N���v�^�e�[�u���̐擪
	move.l	a1,d0			;�_���A�h���X
	bfextu	d0{32-LOGICAL_WIDTH:LOGICAL_WIDTH-25},d0	;���[�g�C���f�b�N�X�t�B�[���h
					;	�����ȃr�b�g�𖳎�����
	lea.l	(a0,d0.l*4),a0		;���[�g�f�X�N���v�^�̃A�h���X
	moves.l	(a0),d0			;���[�g�f�X�N���v�^
	btst.l	#1,d0
	bne	8f			;UDT=%10,%11(�L��)
	moveq.l	#0,d0
8:	tst.l	d0
	rts


;----------------------------------------------------------------
;
;	�|�C���^�f�X�N���v�^�̑���
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^���R�s�[����
;<d0.l:�R�s�[���̘_���A�h���X
;<a1.l:�R�s�[��̘_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�ύX�O�̃|�C���^�f�X�N���v�^
;	-1	�G���[
copyPointerDesc::
	movem.l	d1/a0-a1,-(sp)
	move.l	a1,d1			;�R�s�[��̘_���A�h���X
	movea.l	d0,a1			;�R�s�[���̘_���A�h���X
	move.l	rootDescHead,d0
	beq	9f
	bsr	getRootDesc		;�R�s�[���̃��[�g�f�X�N���v�^�����߂�
	beq	9f
	and.l	#POINTER_DESC_MASK,d0
	bsr	getPointerDesc		;�R�s�[���̃|�C���^�f�X�N���v�^�����߂�
	movea.l	d1,a1			;�R�s�[��̘_���A�h���X
	move.l	d0,d1			;�R�s�[���̃|�C���^�f�X�N���v�^
	move.l	rootDescHead,d0
	bsr	getRootDesc		;�R�s�[��̃��[�g�f�X�N���v�^�����߂�
	beq	9f
	and.l	#POINTER_DESC_MASK,d0
	bsr	setPointerDesc		;���[�g�f�X�N���v�^��ύX����
8:	movem.l	(sp)+,d1/a0-a1
	rts

9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^���X�V����
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̐擪
;<d1.l:�|�C���^�f�X�N���v�^
;<a1.l:�_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�|�C���^�f�X�N���v�^
;	0	�|�C���^�f�X�N���v�^������
;>n-flag:pl
;>z-flag:ne=�|�C���^�f�X�N���v�^���L��,eq=�|�C���^�f�X�N���v�^������
setPointerDesc::
	movem.l	d3/d7/a0,-(sp)
	move.l	d0,d3
	bsr	getPointerDescCount
	exg.l	d0,d3
	addq.l	#1,d3			;�Q�Ɛ�
	bsr	getPointerDesc
	move.l	d0,d7
;�V�����y�[�W�f�X�N���v�^�e�[�u���̃J�E���^�𑝂₷
;���炷�����ɍs���ƁA���炵���i�K�Ńf�X�N���v�^�e�[�u�����J������Ă��܂���
;���₹�Ȃ��Ȃ��\��������̂ŁA���₷�����ɍs��
	move.l	d1,d0
	beq	1f
	and.l	pageDescMask,d0
	bsr	addPageDescCount
1:
;���̃y�[�W�f�X�N���v�^�e�[�u���̃J�E���^�����炷
	move.l	d7,d0
	beq	1f
	and.l	pageDescMask,d0
	bsr	subPageDescCount
1:
;�|�C���^�f�X�N���v�^���X�V����
	moves.l	d1,(a0)
	move.l	d7,d0
	movem.l	(sp)+,d3/d7/a0
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^���擾����
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̐擪
;<a1.l:�_���A�h���X
;<sfc.l:FC_MMU_DATA
;>d0.l:�|�C���^�f�X�N���v�^
;	0	�|�C���^�f�X�N���v�^������
;>a0.l:�|�C���^�f�X�N���v�^�̃A�h���X
;>n-flag:pl
;>z-flag:ne=�|�C���^�f�X�N���v�^���L��,eq=�|�C���^�f�X�N���v�^������
getPointerDesc::
	movea.l	d0,a0			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	move.l	a1,d0			;�_���A�h���X
	bfextu	d0{7:7},d0		;�|�C���^�C���f�b�N�X�t�B�[���h
	lea.l	(a0,d0.l*4),a0		;�|�C���^�f�X�N���v�^�̃A�h���X
	moves.l	(a0),d0			;�|�C���^�f�X�N���v�^
	btst.l	#1,d0
	bne	8f			;UDT=%10,%11(�L��)
	moveq.l	#0,d0
8:	tst.l	d0
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u����1�m�ۂ���0�N���A����
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X(0�N���A����Ă���)
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;>n-flag:pl=����I��,mi=�f�X�N���v�^�̗̈悪�s�����Ă���
callocPointerDescTable::
	bsr	allocPointerDescTable
	bmi	9f
	bsr	clearPointerDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u����1��������
;<a0.l:��������|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�������ꂽ�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;>n-flag:pl=����I��,mi=�f�X�N���v�^�̗̈悪�s�����Ă���
dupPointerDescTable::
	bsr	allocPointerDescTable
	bmi	9f
	bsr	copyPointerDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u����1�m�ۂ���
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;>n-flag:pl=����I��,mi=�f�X�N���v�^�̗̈悪�s�����Ă���
allocPointerDescTable::
	movem.l	a0-a1,-(sp)
	movea.l	pointerCounterHead,a0
	movea.l	pointerDescHead,a1
	bra	2f

1:	moves.l	(a0),d0			;�Q�Ɛ�-1
	tst.l	d0
	bmi	3f			;�r���ɖ��g�p�̗̈悪������
	addq.l	#4,a0
	lea.l	(POINTER_DESC_SIZE,a1),a1
2:	cmpa.l	pointerDescTail,a1
	bne	1b
;�r���ɂ͖��g�p�̗̈悪�Ȃ�����
	lea.l	(POINTER_DESC_SIZE,a1),a1	;�|�C���^�f�X�N���v�^�e�[�u���̗̈��L�΂��Ă݂�
	cmpa.l	pageDescHead,a1
	bhi	9f			;�f�X�N���v�^�e�[�u���̗̈悪�s�����Ă���
	move.l	a1,pointerDescTail	;�|�C���^�f�X�N���v�^�e�[�u���̗̈��L�΂�
	lea.l	(-POINTER_DESC_SIZE,a1),a1
;�r���ɖ��g�p�̗̈悪������
3:	moveq.l	#-1,d0
	moves.l	d0,(a0)			;�Q�Ɛ���0��ݒ�
	move.l	a1,d0
8:	movem.l	(sp)+,a0-a1
	rts

;�f�X�N���v�^�e�[�u���̗̈悪�s�����Ă���
9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u�������ׂĖ����Ȃ�΃��[�g�f�X�N���v�^�𖳌��ɂ���
;<d0.l:���[�g�f�X�N���v�^�̃A�h���X
;>z-flag:eq=�f�X�N���v�^�𖳌��ɂ���,ne=�f�X�N���v�^�𖳌��ɂ��Ȃ�����
invUpPointerDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a2			;���[�g�f�X�N���v�^�̃A�h���X
	moves.l	(a2),d1			;���[�g�f�X�N���v�^
	and.l	#POINTER_DESC_MASK,d1	;�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
	movea.l	d1,a0
	lea.l	(POINTER_DESC_SIZE,a0.l),a1
1:	moves.l	(a0)+,d0		;�|�C���^�f�X�N���v�^
	tst.l	d0
	bne	9f
	cmpa.l	a1,a0
	blo	1b
	moveq.l	#0,d0
	moves.l	d0,(a2)			;���[�g�f�X�N���v�^�𖳌�������
	move.l	d1,d0
	bsr	freePointerDescTable	;�|�C���^�f�X�N���v�^�e�[�u�����폜����
	moveq.l	#0,d0
9:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^��1���₷
;	�܂܂��y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^�����ׂ�1�����₷
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̐擪
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
incPointerDescCount::
	movem.l	d0/a0-a2,-(sp)
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a1			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDescCount
;���݂̎Q�Ɛ���0�ł��������邱��
;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���₷
	addq.l	#1,d0
	moves.l	d0,(a0)			;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���₷
;�܂܂��y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ���1�����₷
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a1)+,d0		;�|�C���^�f�X�N���v�^
	btst.l	#1,d0
	beq	2f			;UDT=%00,%01(����)
	bsr	incPageDescCount	;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���₷
2:	cmpa.l	a2,a1
	blo	1b
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^��1���炷
;	�܂܂��y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^�����ׂ�1�����炷
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̐擪
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
decPointerDescCount::
	movem.l	d0/a0-a2,-(sp)
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a1			;�|�C���^�f�X�N���v�^�e�[�u���̐擪
	bsr	getPointerDescCount
	bmi	8f
	beq	3f			;�|�C���^�f�X�N���v�^�e�[�u�����Ȃ��Ȃ�Ƃ�
					;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ������炵�����Ȃ��悤�ɂ���
;�܂܂��y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ���1�����炷
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a1)+,d0		;�|�C���^�f�X�N���v�^
	btst.l	#1,d0
	beq	2f			;UDT=%00,%01(����)
	bsr	decPageDescCount	;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���炷
2:	cmpa.l	a2,a1
	blo	1b
;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���炷
	moves.l	(a0),d0
3:	subq.l	#1,d0
	moves.l	d0,(a0)			;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���炷
	bcc	8f
	bsr	freePointerDescTable	;�ǂ�������Q�Ƃ���Ȃ��̂ŊJ������
8:	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u����1�J������
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
freePointerDescTable::
	movem.l	d0/d3/a0-a2,-(sp)
	and.l	#POINTER_DESC_MASK,d0
	movea.l	d0,a1			;�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
	bsr	getPointerDescCount
	bmi	9f
	move.l	d0,d3			;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ�-1
	addq.l	#1,d3			;�Q�Ɛ�
;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ���0�ɂ���
	moveq.l	#-1,d0
	moves.l	d0,(a0)			;�Q�Ɛ���0�ɂ���
;�܂܂��|�C���^�f�X�N���v�^�������łȂ���΃y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ������炷
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a1)+,d0
	tst.l	d0
	bne	2f
	bsr	subPageDescCount
2:	cmpa.l	a2,a1
	blo	1b
9:	bsr	cleanPointerDesc
	movem.l	(sp)+,d0/d3/a0-a2
	rts

;----------------------------------------------------------------
;��肩���̃|�C���^�f�X�N���v�^�e�[�u��������ΊJ������
;<sfc.l:FC_MMU_DATA
cleanPointerDesc::
	movem.l	d0/a0-a1,-(sp)
	move.l	pointerDescTail,d0
	cmp.l	pointerDescHead,d0
	beq	9f			;�|�C���^�f�X�N���v�^�e�[�u�����Ȃ�
	sub.l	#POINTER_DESC_SIZE,d0	;�����̃|�C���^�f�X�N���v�^�e�[�u��
	movea.l	d0,a1			;�����̃|�C���^�f�X�N���v�^�e�[�u��
	bsr	getPointerDescCount
	bpl	9f			;��肩���̃|�C���^�f�X�N���v�^�e�[�u���͂Ȃ�
1:	cmpa.l	pointerDescHead,a1
	beq	8f			;�S����肩��������?
	lea.l	(-POINTER_DESC_SIZE,a1),a1	;1��O��
	moves.l	-(a0),d0		;�Q�Ɛ�
	tst.l	d0
	bmi	1b
8:	move.l	a1,pointerDescTail
9:	movem.l	(sp)+,d0/a0-a1
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u����1��0�N���A����
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
clearPointerDescTable::
	movem.l	d0/a1-a2,-(sp)
	movea.l	d0,a1
	lea.l	(POINTER_DESC_SIZE,a1),a2
	moveq.l	#0,d0
@@:	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a1-a2
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u����1�R�s�[����
;<d0.l:�R�s�[��̃|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<a0.l:�R�s�[���̃|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
copyPointerDescTable::
	movem.l	d0/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	(POINTER_DESC_SIZE,a1),a2
@@:	moves.l	(a0)+,d0
	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u�����r����
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<a0.l:�|�C���^�f�X�N���v�^�e�[�u���̃A�h���X
;<sfc.l:FC_MMU_DATA
;>z-flag:eq=��v,ne=�s��v
cmpPointerDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	(POINTER_DESC_SIZE,a1),a2
1:	moves.l	(a0)+,d0
	moves.l	(a1)+,d1
;		                U W UDT
	and.w	#%1111111_11111_0_1_11,d0
	and.w	#%1111111_11111_0_1_11,d1
	cmp.l	d1,d0
	bne	2f
	cmpa.l	a2,a1
	blo	1b
	moveq.l	#0,d0
2:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;�|�C���^�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^�����߂�
;<d0.l:�|�C���^�f�X�N���v�^�e�[�u���̐擪
;<sfc.l:FC_MMU_DATA
;>d0.l:�Q�Ɛ��J�E���^
;	-1	�ǂ�������Q�Ƃ���Ă��Ȃ�
;	0	1�ӏ���������Q�Ƃ���Ă���
;>a0.l:�Q�Ɛ��J�E���^�̃A�h���X
;>n-flag:mi=�ǂ�������Q�Ƃ���Ă��Ȃ�(���g�p),pl=�Q�Ƃ���Ă���(�g�p��)
;>z-flag:(pl)eq=1�ӏ���������Q�Ƃ���Ă���,ne=2�ӏ��ȏォ��Q�Ƃ���Ă���
getPointerDescCount::
	and.l	#POINTER_DESC_MASK,d0
	sub.l	pointerDescHead,d0
	asr.l	#7,d0
	lea.l	([pointerCounterHead],d0.l),a0
	moves.l	(a0),d0
	tst.l	d0
	bpl	@f
	moveq.l	#-1,d0
@@:	rts


;----------------------------------------------------------------
;
;	�y�[�W�f�X�N���v�^�̑���
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^���X�V����
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<d1.l:�y�[�W�f�X�N���v�^
;<a1.l:�_���A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�X�V�O�̃y�[�W�f�X�N���v�^
;	0	�y�[�W�f�X�N���v�^������
;>z-flag:ne=�y�[�W�f�X�N���v�^���L��,eq=�y�[�W�f�X�N���v�^������
;>n-flag:pl
setPageDesc::
	move.l	a0,-(sp)
	bsr	getPageDesc
	moves.l	d1,(a0)
	movea.l	(sp)+,a0
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^���擾����
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<a1.l:�_���A�h���X
;<sfc.l:FC_MMU_DATA
;>d0.l:�y�[�W�f�X�N���v�^
;	0	�y�[�W�f�X�N���v�^������
;>a0.l:�y�[�W�f�X�N���v�^�̃A�h���X(�Ԑڃy�[�W�f�X�N���v�^�̂Ƃ�(a0)��d0)
;>z-flag:ne=�y�[�W�f�X�N���v�^���L��,eq=�y�[�W�f�X�N���v�^������
;>n-flag:pl
getPageDesc::
	move.l	d1,-(sp)
	movea.l	d0,a0
	move.l	a1,d0			;�_���A�h���X
	move.l	pageIndexWidth,d1	;�y�[�W�C���f�b�N�X�t�B�[���h�̃r�b�g��(5�`6)
	bfextu	d0{14:d1},d0		;�y�[�W�C���f�b�N�X�t�B�[���h
	lea.l	(a0,d0.l*4),a0		;�y�[�W�f�X�N���v�^�̃A�h���X
	moves.l	(a0),d0			;�y�[�W�f�X�N���v�^
	moveq.l	#%11,d1
	and.l	d0,d1			;PDT
	beq	9f			;PDT=%00(����)
	subq.l	#%10,d1
	bne	8f			;PDT=%01,%11(�L��)
	moves.l	(-2,za0,d0.l),d0	;�y�[�W�f�X�N���v�^
	btst.l	#0,d0
	bne	8f			;PDT=%01,%11(�L��)
9:	moveq.l	#0,d0
8:	move.l	(sp)+,d1
	tst.l	d0
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u����1�m�ۂ���0�N���A����
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X(0�N���A����Ă���)
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;>n-flag:pl=����I��,mi=�f�X�N���v�^�̗̈悪�s�����Ă���
callocPageDescTable::
	bsr	allocPageDescTable
	bmi	9f
	bsr	clearPageDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u����1��������
;<a0.l:��������y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�������ꂽ�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;>n-flag:pl=����I��,mi=�f�X�N���v�^�̗̈悪�s�����Ă���
dupPageDescTable::
	bsr	allocPageDescTable
	bmi	9f
	bsr	copyPageDescTable
	tst.l	d0
9:	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u����1�m�ۂ���
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
;>d0.l:�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;	-1	�f�X�N���v�^�̗̈悪�s�����Ă���
;>n-flag:pl=����I��,mi=�f�X�N���v�^�̗̈悪�s�����Ă���
allocPageDescTable::
	movem.l	a0-a1,-(sp)
	movea.l	pageCounterTail,a0
	movea.l	pageDescTail,a1
	bra	2f

1:	suba.l	pageDescSize,a1
	moves.l	-(a0),d0		;�Q�Ɛ�-1
	tst.l	d0
	bmi	3f			;�r���ɖ��g�p�̗̈悪������
2:	cmpa.l	pageDescHead,a1
	bne	1b
;�r���ɂ͖��g�p�̗̈悪�Ȃ�����
	suba.l	pageDescSize,a1		;�y�[�W�f�X�N���v�^�e�[�u���̗̈��L�΂��Ă݂�
	cmpa.l	pointerDescTail,a1
	blo	9f			;�f�X�N���v�^�e�[�u���̗̈悪�s�����Ă���
	move.l	a1,pageDescHead		;�y�[�W�f�X�N���v�^�e�[�u���̗̈��L�΂�
	subq.l	#4,a0
;�r���ɖ��g�p�̗̈悪������
3:	moveq.l	#-1,d0
	moves.l	d0,(a0)			;�Q�Ɛ���0��ݒ�
	move.l	a1,d0
8:	movem.l	(sp)+,a0-a1
	rts

;�f�X�N���v�^�e�[�u���̗̈悪�s�����Ă���
9:	moveq.l	#-1,d0
	bra	8b

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u�������ׂĖ����Ȃ�΃f�X�N���v�^�𖳌��ɂ���
;<d0.l:�|�C���^�f�X�N���v�^�̃A�h���X
;>z-flag:eq=�f�X�N���v�^�𖳌��ɂ���,ne=�f�X�N���v�^�𖳌��ɂ��Ȃ�����
invUpPageDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a2			;�|�C���^�f�X�N���v�^�̃A�h���X
	moves.l	(a2),d1			;�|�C���^�f�X�N���v�^
	and.l	pageDescMask,d1		;�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
	movea.l	d1,a0
	lea.l	([pageDescSize],a0.l),a1
1:	moves.l	(a0)+,d0		;�y�[�W�f�X�N���v�^
	tst.l	d0
	bne	9f
	cmpa.l	a1,a0
	blo	1b
	moveq.l	#0,d0
	moves.l	d0,(a2)			;�|�C���^�f�X�N���v�^�𖳌�������
	move.l	d1,d0
	bsr	freePageDescTable	;�y�[�W�f�X�N���v�^�e�[�u�����폜����
	moveq.l	#0,d0
9:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���₷
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
incPageDescCount::
	move.l	d3,-(sp)
	moveq.l	#1,d3
	bsr	addPageDescCount
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ��𑝂₷
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<d3.l:���₷��
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
addPageDescCount::
	movem.l	d0/a0,-(sp)
	bsr	getPageDescCount
;���݂̎Q�Ɛ���0�ł��������邱��
	add.l	d3,d0
	moves.l	d0,(a0)			;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ��𑝂₷
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ���1���炷
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
decPageDescCount::
	move.l	d3,-(sp)
	moveq.l	#1,d3
	bsr	subPageDescCount
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ������炷
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<d3.l:���炷��
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
subPageDescCount::
	movem.l	d0/a0,-(sp)
	bsr	getPageDescCount
	bmi	8f
	sub.l	d3,d0
	moves.l	d0,(a0)
	bcc	8f
	bsr	freePageDescTable	;�ǂ�������Q�Ƃ���Ȃ��̂ŊJ������
8:	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u����1�J������
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
freePageDescTable::
	movem.l	d0/a0,-(sp)
	and.l	pageDescMask,d0
	bsr	getPageDescCount
	bmi	9f
	moveq.l	#-1,d0
	moves.l	d0,(a0)			;�Q�Ɛ���0�ɂ���
9:	bsr	cleanPageDesc
	movem.l	(sp)+,d0/a0
	rts

;----------------------------------------------------------------
;��肩���̃y�[�W�f�X�N���v�^�e�[�u��������ΊJ������
;<sfc.l:FC_MMU_DATA
cleanPageDesc::
	movem.l	d0/a0-a1,-(sp)
	move.l	pageDescHead,d0
	cmp.l	pageDescTail,d0
	beq	9f			;�y�[�W�f�X�N���v�^�e�[�u�����Ȃ�
	movea.l	d0,a1			;�擪�̃y�[�W�f�X�N���v�^�e�[�u��
	bsr	getPageDescCount
	bpl	9f			;��肩���̃y�[�W�f�X�N���v�^�e�[�u���͂Ȃ�
1:	lea.l	([pageDescSize],a1.l),a1	;1����
	addq.l	#4,a0
	cmpa.l	pageDescTail,a1
	beq	8f			;�S����肩��������?
	moves.l	(a0),d0			;�Q�Ɛ�
	tst.l	d0
	bmi	1b
8:	move.l	a1,pageDescHead
9:	movem.l	(sp)+,d0/a0-a1
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u����1��0�N���A����
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
clearPageDescTable::
	movem.l	d0/a1-a2,-(sp)
	movea.l	d0,a1
	lea.l	([pageDescSize],a1.l),a2
	moveq.l	#0,d0
@@:	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a1-a2
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u����1�R�s�[����
;<d0.l:�R�s�[��̃y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<a0.l:�R�s�[���̃y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<dfc.l:FC_MMU_DATA
;<sfc.l:FC_MMU_DATA
copyPageDescTable::
	movem.l	d0/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	([pageDescSize],a1.l),a2
@@:	moves.l	(a0)+,d0
	moves.l	d0,(a1)+
	cmpa.l	a2,a1
	blo	@b
	movem.l	(sp)+,d0/a0-a2
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u�����r����
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<a0.l:�y�[�W�f�X�N���v�^�e�[�u���̃A�h���X
;<sfc.l:FC_MMU_DATA
;>z-flag:eq=��v,ne=�s��v
cmpPageDescTable::
	movem.l	d0-d1/a0-a2,-(sp)
	movea.l	d0,a1
	lea.l	([pageDescSize],a1.l),a2
1:	moves.l	(a0)+,d0
	moves.l	(a1)+,d1
;		      UR G U1U0 S CM M U W PDT
	and.w	#%111_11_1__11__1_11_0_0_1_11,d0
	and.w	#%111_11_1__11__1_11_0_0_1_11,d1
	cmp.l	d1,d0
	bne	2f
	cmpa.l	a2,a1
	blo	1b
	moveq.l	#0,d0
2:	movem.l	(sp)+,d0-d1/a0-a2
	rts

;----------------------------------------------------------------
;�y�[�W�f�X�N���v�^�e�[�u���̎Q�Ɛ��J�E���^�����߂�
;<d0.l:�y�[�W�f�X�N���v�^�e�[�u���̐擪
;<sfc.l:FC_MMU_DATA
;>d0.l:�Q�Ɛ��J�E���^
;	-1	�ǂ�������Q�Ƃ���Ă��Ȃ�
;	0	1�ӏ���������Q�Ƃ���Ă���
;>a0.l:�Q�Ɛ��J�E���^�̃A�h���X
;>n-flag:mi=�ǂ�������Q�Ƃ���Ă��Ȃ�(���g�p),pl=�Q�Ƃ���Ă���(�g�p��)
;>z-flag:(pl)eq=1�ӏ���������Q�Ƃ���Ă���,ne=2�ӏ��ȏォ��Q�Ƃ���Ă���
getPageDescCount::
	and.l	pageDescMask,d0
	sub.l	pageDescTail,d0
	move.l	d1,-(sp)
	move.l	pageIndexWidth,d1
	asr.l	d1,d0			;d0�͕����Ȃ̂�lsr�͕s��
	move.l	(sp)+,d1
	lea.l	([pageCounterTail],d0.l),a0
	moves.l	(a0),d0
	tst.l	d0
	bpl	@f
	moveq.l	#-1,d0
@@:	rts


;----------------------------------------------------------------
;
;	���[�J��������
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;�_���A�h���X�͈͂�DMA�]���\�����ׂ�
;	�͈͓��ɔ�풓�y�[�W������ƃA�N�Z�X�G���[���������Ă��܂�
;<d0.l:�]������
;	0	�f�o�C�X����ǂݏo��(�������֏�������)
;	1	�f�o�C�X�֏�������(����������ǂݏo��)
;<d1.l:�_���A�h���X(�擪)
;<d2.l:�_���A�h���X(����+1)
;>n-flag:mi=DMA�]���s�\,pl=DMA�]���\
dmaAccessCheck::
	movem.l	d0-d1/d3/a0-a1,-(sp)
  debug '|dmaAccessCheck in (top,btm)=',2,d1,d2
	and.l	pageMask,d1		;�擪������y�[�W�̐擪
					;pageMask��LOGICAL_MASK�𔺂�����
	and.l	#LOGICAL_MASK,d2	;����+1
					;bit31��1�ɂȂ��Ă���Ƃ�d1�����}�X�N�����
					;�͈͂�2GB�ȏ�ɂȂ��Ă��܂�
	tst.b	localSystemArea
	bne	@f
	cmp.l	([$1C20.w],Tail),d2	;(-ls�łȂ��Ƃ�)Human�̒��Ȃ�΃`�F�b�N�͏ȗ�
	blo	4f
@@:	lea.l	(readTranslation,pc),a0
	tst.l	d0
	beq	@f
	lea.l	(writeTranslation,pc),a0
@@:	movec.l	dfc,d3
	moveq.l	#FC_SUPER_DATA,d0
	movec.l	d0,dfc
1:	movea.l	d1,a1
;<a1.l:�_���A�h���X
	jsr	(a0)			;�_���A�h���X�𕨗��A�h���X�ɕϊ�
;<a1.l:�����A�h���X
	cmpa.l	d1,a1
	bne	2f			;�����A�h���X���_���A�h���X�ƈقȂ�
					;$00000000��$01000000�ł��قȂ�Ɣ��f�����
	move.l	a1,d0
	bsr	physicalToLocal
	bpl	2f			;���[�J��������
	add.l	pageOffsetSize,d1	;���̃y�[�W�̐擪
	cmp.l	d2,d1			;�y�[�W�̐擪������+1�ȏ�Ȃ�ΏI��
	blo	1b
4:	moveq.l	#0,d0			;DMA�]���\
	bra	3f

2:	moveq.l	#-1,d0			;DMA�]���s�\
3:
  debug '|dmaAccessCheck out (0=DMA enable)=',1,d0
	movec.l	d3,dfc
	tst.l	d0
	movem.l	(sp)+,d0-d1/d3/a0-a1
	rts

;�����A�h���X�̃`�F�b�N(�f�o�C�X���烁�����֓]��)
;<a1.l:�_���A�h���X
;<dfc:�`�F�b�N����A�h���X���
;>a1.l:�����A�h���X
readTranslation:
	tst.b	noTranslation
	bne	90f
	movem.l	d0-d1/a0,-(sp)
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc			;�_���A�h���X����y�[�W�f�X�N���v�^�����߂�
	bmi	9f			;�y�[�W�f�X�N���v�^���Ȃ�
	beq	9f			;��풓
	btst.l	#PD_W_BIT,d0
	bne	9f			;���C�g�v���e�N�g����Ă���
	and.l	pageMask,d0		;�y�[�W�̐擪�A�h���X
	move.l	a1,d1
	and.l	pageOffsetMask,d1	;�I�t�Z�b�g
	or.l	d1,d0			;�y�[�W�̐擪�A�h���X�ɃI�t�Z�b�g����������
8:	movea.l	d0,a1			;�����A�h���X
	POP_SFC_DFC	d1
	movem.l	(sp)+,d0-d1/a0
90:	rts

9:	moveq.l	#-1,d0			;���s
	bra	8b

;�����A�h���X�̃`�F�b�N(����������f�o�C�X�֓]��)
;<a1.l:�_���A�h���X
;<dfc:�`�F�b�N����A�h���X���
;>a1.l:�����A�h���X
writeTranslation:
	tst.b	noTranslation
	bne	90f
	movem.l	d0-d1/a0,-(sp)
	PUSH_MMU_SFC_DFC	d0
	bsr	getDesc			;�_���A�h���X����y�[�W�f�X�N���v�^�����߂�
	bmi	9f			;�y�[�W�f�X�N���v�^���Ȃ�
	beq	9f			;��풓
	and.l	pageMask,d0		;�y�[�W�̐擪�A�h���X
	move.l	a1,d1
	and.l	pageOffsetMask,d1	;�I�t�Z�b�g
	or.l	d1,d0			;�y�[�W�̐擪�A�h���X�ɃI�t�Z�b�g����������
8:	movea.l	d0,a1			;�����A�h���X
	POP_SFC_DFC	d1
	movem.l	(sp)+,d0-d1/a0
90:	rts

9:	moveq.l	#-1,d0			;���s
	bra	8b

;----------------------------------------------------------------
;�����A�h���X�����[�J�����������w���Ă��邩���ׂ�
;<d0.l:�����A�h���X
;>d0.l:����
;	-1	���[�J���������ł͂Ȃ�
;	���̑�	���[�J���������̕����A�h���X
;>n-flag:mi=���[�J���������ł͂Ȃ�,pl=���[�J��������
physicalToLocal::
	tst.l	localMemorySize
	beq	9f
	and.l	#LOGICAL_MASK,d0
	sub.l	localMemoryStart,d0
	cmp.l	localMemorySize,d0
	bcc	9f
	add.l	localMemoryStart,d0
	rts

9:	moveq.l	#-1,d0
	rts

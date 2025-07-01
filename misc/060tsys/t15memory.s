;----------------------------------------------------------------
;
;	�������Ǘ����[�`��
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;�u���b�N�̊m�ۂ��s�����[�`���̃e�[�u��
malloc2Table::
	.dc.l	malloc20		;���ʂ���
	.dc.l	malloc21		;�K�v�ŏ��u���b�N����
	.dc.l	malloc22		;��ʂ���
	.dc.l	malloc23		;�ő�u���b�N����

;----------------------------------------------------------------
;�u���b�N�̊m��(���ʂ���)
;<d2.l:�m�ۂ���T�C�Y
;<d4.l:�e�v���Z�X�̃������Ǘ��e�[�u��
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;*d0/a1
malloc20::
	movem.l	d1-d2/a2,-(sp)
  debug '|malloc20 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;�O�̂���
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;�擪�̃u���b�N
malloc20Loop:
	cmp.l	a5,d0
	bcc	malloc20Failed		;������Ȃ�����
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc20Next		;���b�N����Ă���
	bsr	splitBlock		;�������Ăł���u���b�N�̃w�b�_�ƃT�C�Y�����߂�
	bmi	malloc20Next		;�����ł��Ȃ�
	cmp.l	d2,d1			;�T�C�Y������Ă��邩
	bhs	malloc20Found		;��������
malloc20Next:
	move.l	(Next,a2),d0		;���̃u���b�N��
	bne	malloc20Loop
malloc20Failed:
	suba.l	a1,a1
	bsr	getSize
;<d0.l:�m�ۂł���T�C�Y�̍��v
;<d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
	move.l	d1,d0			;�ő�̃T�C�Y
	or.l	#$80000000,d0		;�ŏ�ʃr�b�g�����Z�b�g����
	bra	malloc20End

malloc20Found:
	bsr	insertHeader		;�w�b�_��}������
	lea.l	(User,a1),a1		;���[�U�̈�̐擪
	add.l	a1,d2			;���[�U�̈�̖���+1
	move.l	d2,(-User+Tail,a1)	;���[�U�̈�̖���+1
	move.l	d4,(-User+Proc,a1)	;�e�v���Z�X�̃������Ǘ��e�[�u��
	moveq.l	#0,d0
malloc20End:
  debug '|malloc20 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d2/a2
	rts

;----------------------------------------------------------------
;�u���b�N�̊m��(�K�v�ŏ��u���b�N����)
;<d2.l:�m�ۂ���T�C�Y
;<d4.l:�e�v���Z�X�̃������Ǘ��e�[�u��
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;*d0/a1
malloc21::
	movem.l	d1-d3/d5/a2-a4,-(sp)
  debug '|malloc21 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;�O�̂���
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;�擪�̃u���b�N
	moveq.l	#$FFFFFFFF,d3		;���������ŏ��̃u���b�N�̃T�C�Y
	moveq.l	#0,d5			;���������ŏ��̃u���b�N
malloc21Loop:
	cmp.l	a5,d0
	bcc	malloc21Last		;������Ȃ�����
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc21Next		;���b�N����Ă���
	bsr	splitBlock		;�������Ăł���u���b�N�̃w�b�_�ƃT�C�Y�����߂�
	bmi	malloc21Next		;�����ł��Ȃ�
	cmp.l	d2,d1			;�T�C�Y������Ă��邩
	blo	malloc21Next		;����Ȃ�
	cmp.l	d3,d1			;����܂łɌ��������u���b�N�̃T�C�Y��菬������
	bhs	malloc21Next		;�傫����������
	move.l	d1,d3			;�ŏ��̃u���b�N�̃T�C�Y���X�V
	movea.l	a1,a3			;�w�b�_������ʒu���X�V
	move.l	a2,d5			;���������u���b�N�̃w�b�_���X�V
malloc21Next:
	move.l	(Next,a2),d0		;���̃u���b�N��
	bne	malloc21Loop
malloc21Last:
	move.l	d5,d0			;���������ŏ��̃u���b�N
	beq	malloc21Failed		;������Ȃ�����
	movea.l	a3,a1			;�V�����w�b�_
	movea.l	d5,a2			;���������u���b�N�̃w�b�_
	bsr	insertHeader		;�w�b�_��}������
	lea.l	(User,a1),a1		;���[�U�̈�̐擪
	add.l	a1,d2			;���[�U�̈�̖���+1
	move.l	d2,(-User+Tail,a1)	;���[�U�̈�̖���+1
	move.l	d4,(-User+Proc,a1)	;�e�v���Z�X�̃������Ǘ��e�[�u��
	moveq.l	#0,d0
malloc21End:
  debug '|malloc21 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d3/d5/a2-a4
	rts

malloc21Failed:
	suba.l	a1,a1
	bsr	getSize
;<d0.l:�m�ۂł���T�C�Y�̍��v
;<d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
	move.l	d1,d0			;�ő�̃T�C�Y
	or.l	#$80000000,d0		;�ŏ�ʃr�b�g�����Z�b�g����
	bra	malloc21End

;----------------------------------------------------------------
;�u���b�N�̊m��(��ʂ���)
;<d2.l:�m�ۂ���T�C�Y
;<d4.l:�e�v���Z�X�̃������Ǘ��e�[�u��
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;*d0/a1
malloc22::
	movem.l	d1-d2/a2-a4,-(sp)
  debug '|malloc22 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;�O�̂���
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;�擪�̃u���b�N
	suba.l	a3,a3
malloc22Loop:
	cmp.l	a5,d0
	bcc	malloc22Last		;������Ȃ�����
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc22Next		;���b�N����Ă���
	bsr	splitBlock		;�������Ăł���u���b�N�̃w�b�_�ƃT�C�Y�����߂�
	bmi	malloc22Next		;�����ł��Ȃ�
	cmp.l	d2,d1			;�T�C�Y������Ă��邩
	blo	malloc22Next		;����Ȃ�
	movea.l	a2,a3			;�Ō�Ɍ��������u���b�N�̃w�b�_���X�V
malloc22Next:
	move.l	(Next,a2),d0		;���̃u���b�N��
	bne	malloc22Loop
malloc22Last:
	move.l	a3,d0			;�Ō�Ɍ��������u���b�N
	beq	malloc22Failed		;������Ȃ�����
	movea.l	a3,a2			;���������u���b�N�̃A�h���X
	move.l	(Next,a2),d1		;����+1
	beq	1f
	cmp.l	a5,d1
	bls	2f
1:	move.l	a5,d1
2:	sub.l	d2,d1
	moveq.l	#$FFFFFFF0,d0
	and.l	d0,d1			;���[�U�̈�̐擪
	add.l	d0,d1			;�V�����w�b�_
	movea.l	a2,a1			;��������u���b�N�̃w�b�_
	lea.l	(User,a2),a3		;��������u���b�N�̃��[�U�̈�̐擪
	cmp.l	a1,d1
	beq	malloc22FreeBlock	;��������u���b�N�̒�����0�ɂȂ�Ƃ��������Ȃ�
	movea.l	d1,a1
	bsr	insertHeader		;�w�b�_��}������
malloc22FreeBlock:
	lea.l	(User,a1),a1		;���[�U�̈�̐擪
	add.l	a1,d2			;���[�U�̈�̖���+1
	move.l	d2,(-User+Tail,a1)	;���[�U�̈�̖���+1
	move.l	d4,(-User+Proc,a1)	;�e�v���Z�X�̃������Ǘ��e�[�u��
	moveq.l	#0,d0
malloc22End:
  debug '|malloc22 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d2/a2-a4
	rts

malloc22Failed:
	suba.l	a1,a1
	bsr	getSize
;<d0.l:�m�ۂł���T�C�Y�̍��v
;<d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
	move.l	d1,d0			;�ő�̃T�C�Y
	or.l	#$80000000,d0		;�ŏ�ʃr�b�g�����Z�b�g����
	bra	malloc22End

;----------------------------------------------------------------
;�u���b�N�̊m��(�ő�u���b�N����)
;<d2.l:�m�ۂ���T�C�Y
;<d4.l:�e�v���Z�X�̃������Ǘ��e�[�u��
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;*d0/a1
malloc23::
	movem.l	d1-d3/d5/a2-a4,-(sp)
  debug '|malloc23 in (size,proc)=',2,d2,d4
	cmp.l	#LOGICAL_SIZE-1,d2	;�O�̂���
	bls	@f
	move.l	#LOGICAL_SIZE-1,d2
@@:	move.l	a4,d0			;�擪�̃u���b�N
	moveq.l	#0,d3			;���������ő�̃u���b�N�̃T�C�Y
	moveq.l	#0,d5			;���������ő�̃u���b�N
malloc23Loop:
	cmp.l	a5,d0
	bcc	malloc23Last		;������Ȃ�����
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	malloc23Next		;���b�N����Ă���
	bsr	splitBlock		;�������Ăł���u���b�N�̃w�b�_�ƃT�C�Y�����߂�
	bmi	malloc23Next		;�����ł��Ȃ�
	cmp.l	d2,d1			;�T�C�Y������Ă��邩
	blo	malloc23Next		;����Ȃ�
	cmp.l	d3,d1			;����܂łɌ��������u���b�N�̃T�C�Y���傫��
	bls	malloc23Next		;��������������
	move.l	d1,d3			;�ő�̃u���b�N�̃T�C�Y���X�V
	movea.l	a1,a3			;�w�b�_������ʒu���X�V
	move.l	a2,d5			;���������u���b�N�̃w�b�_���X�V
malloc23Next:
	move.l	(Next,a2),d0		;���̃u���b�N��
	bne	malloc23Loop
malloc23Last:
	move.l	d5,d0			;���������ő�̃u���b�N
	beq	malloc23Failed		;������Ȃ�����
	movea.l	a3,a1			;�V�����w�b�_
	movea.l	d5,a2			;���������u���b�N�̃w�b�_
	bsr	insertHeader		;�w�b�_��}������
	lea.l	(User,a1),a1		;���[�U�̈�̐擪
	add.l	a1,d2			;���[�U�̈�̖���+1
	move.l	d2,(-User+Tail,a1)	;���[�U�̈�̖���+1
	move.l	d4,(-User+Proc,a1)	;�e�v���Z�X�̃������Ǘ��e�[�u��
	moveq.l	#0,d0
malloc23End:
  debug '|malloc23 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d3/d5/a2-a4
	rts

malloc23Failed:
	suba.l	a1,a1
	move.l	d3,d0			;�ő�̃T�C�Y
	or.l	#$80000000,d0		;�ŏ�ʃr�b�g�����Z�b�g����
	bra	malloc23End

;----------------------------------------------------------------
;�u���b�N�̊J��
;<d2.l:�J������u���b�N�̃��[�U�̈�̐擪
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,-1=�w�b�_��������Ȃ�
;*d0
free::
	movem.l	d2/a1-a2,-(sp)
  debug '|free in (ptr)=',1,d2
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2			;�w�b�_
	bsr	searchBlock2		;�w�b�_��T��
	bmi	freeEnd			;������Ȃ�
;<a2.l:�w�b�_
	bsr	deleteHeader		;�w�b�_���폜����
freeDone:
	moveq.l	#0,d0
freeEnd:
  debug '|free out (err)=',1,d0
	movem.l	(sp)+,d2/a1-a2
	rts

;----------------------------------------------------------------
;����̃v���Z�X���m�ۂ����u���b�N�̊J��
;	�q�v���Z�X���m�ۂ����u���b�N���J������
;<d4.l:�J������u���b�N���m�ۂ����v���Z�X�̃������Ǘ��e�[�u��
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0(��ɐ�������)
;*d0
psfree::
	movem.l	d1/a2,-(sp)
  debug '|psfree in (proc)=',1,d4
	move.l	a4,d0			;�擪�̃u���b�N
psfreeLoop:
	cmp.l	a5,d0
	bcc	psfreeEnd		;�I���
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	psfreeNext		;���b�N����Ă���
	move.l	(Next,a2),d1		;����
	cmp.l	(Proc,a2),d4		;�m�ۂ����v���Z�X
	bne	psfreeNext		;�Y�����Ȃ�
	bsr	deleteHeader		;�w�b�_���폜����
	move.l	d2,-(sp)
	move.l	d1,-(sp)
	move.l	a2,d2			;�q�v���Z�X
	bsr	psfree			;�q�v���Z�X���m�ۂ����u���b�N���J��
	move.l	(sp)+,d1
	move.l	(sp)+,d2
psfreeNext:
	move.l	d1,d0
	bne	psfreeLoop
psfreeEnd:
	moveq.l	#0,d0
  debug '|psfree out (err)=',1,d0
	movem.l	(sp)+,d1/a2
	rts

;----------------------------------------------------------------
;�u���b�N�̃T�C�Y�ύX
;	�u���b�N�͈ړ����Ȃ�
;	�V�����T�C�Y��0�Ȃ�΃u���b�N���J������
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y(0=�u���b�N���J������)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0
resizeOrFree::
	tst.l	d3			;�T�C�Y��0�Ȃ�΃u���b�N���J������
	beq	free
;----------------------------------------------------------------
;�u���b�N�̃T�C�Y�ύX
;	�u���b�N�͈ړ����Ȃ�
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0
resize::
	movem.l	d1-d3/a1-a2,-(sp)
  debug '|resize in (ptr,size)=',2,d2,d3
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2			;�w�b�_
	bsr	searchBlock2		;�w�b�_��T��
	bmi	resizeEnd		;������Ȃ�
;<a2.l:�w�b�_
	cmp.l	#LOGICAL_SIZE-1,d3	;�I�[�o�[�t���[�����Ȃ�����
	bls	@f
	move.l	#LOGICAL_SIZE-1,d3
@@:	lea.l	(User,a2,d3.l),a1	;�V�������[�U�̈�̖���+1
	move.l	(Next,a2),d0		;���[�U�̈�̖���+1�̍ő�l
	beq	1f
	cmp.l	a5,d0
	bls	2f
1:	move.l	a5,d0
2:	cmpa.l	d0,a1			;����؂邩
	bhi	resizeFailed		;����؂�Ȃ�
	move.l	a1,(Tail,a2)		;���[�U�̈�̖���+1
	moveq.l	#0,d0
resizeEnd:
  debug '|resize out (err)=',1,d0
	movem.l	(sp)+,d1-d3/a1-a2
	rts

resizeFailed:
	lea.l	(User,a2),a2		;���[�U�̈�̐擪
	sub.l	a2,d0			;�w�b�_���܂܂Ȃ��ő�̃T�C�Y
	or.l	#$80000000,d0		;�ŏ�ʃr�b�g�����Z�b�g����
	bra	resizeEnd

;----------------------------------------------------------------
;�u���b�N�̃T�C�Y�ύX
;	�u���b�N���ړ����邱�Ƃ�����
;	�ړ�����Ƃ��V�����u���b�N�͉��ʂ���m�ۂ���
;	�ړ����Ă��u���b�N���m�ۂ����v���Z�X�͕ω����Ȃ�
;	�V�����T�C�Y��0�Ȃ�΃u���b�N���J������
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y(0=�u���b�N���J������)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�ړ���̃u���b�N�̃��[�U�̈�̐擪
;*d0/a1
reallocOrFree::
	tst.l	d3			;�T�C�Y��0�Ȃ�΃u���b�N���J������
	beq	free
;----------------------------------------------------------------
;�u���b�N�̃T�C�Y�ύX
;	�u���b�N���ړ����邱�Ƃ�����
;	�ړ�����Ƃ��V�����u���b�N�͉��ʂ���m�ۂ���
;	�ړ����Ă��u���b�N���m�ۂ����v���Z�X�͕ω����Ȃ�
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�ړ���̃u���b�N�̃��[�U�̈�̐擪
;*d0/a1
realloc::
	movem.l	d1-d4/a2-a3,-(sp)
  debug '|realloc in (ptr,size)=',2,d2,d3
	moveq.l	#$FFFFFFF0,d0
	add.l	d0,d2			;�w�b�_
	bsr	searchBlock2		;�w�b�_��T��
	bmi	reallocEnd		;������Ȃ�
;�ړ������ɃT�C�Y��ς��Ă݂�
;<d3.l:�V�����T�C�Y
;<a2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
	cmp.l	#LOGICAL_SIZE-1,d3	;�I�[�o�[�t���[�����Ȃ�����
	bls	@f
	move.l	#LOGICAL_SIZE-1,d3
@@:	lea.l	(User,a2,d3.l),a1	;�V�������[�U�̈�̖���+1
	move.l	(Next,a2),d0		;���[�U�̈�̖���+1�̍ő�l
	beq	1f
	cmp.l	a5,d0
	bls	2f
1:	move.l	a5,d0
2:	cmpa.l	d0,a1			;����؂邩
	bhi	reallocPrevious		;����؂�Ȃ�
	move.l	a1,(Tail,a2)		;���[�U�̈�̖���+1
	bra	reallocDone

;<d3.l:�V�����T�C�Y
;<a2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
reallocPrevious:
	movea.l	a2,a3			;�T�C�Y��ύX����u���b�N�̃w�b�_
;<a3.l:�T�C�Y��ύX����u���b�N�̃w�b�_
	cmpa.l	a4,a3
	beq	reallocFirstBlock	;�擪�̃u���b�N
;��O�ɐL�΂��Ă݂�
;<a3.l:�T�C�Y��ύX����u���b�N�̃w�b�_
	movea.l	(Prev,a3),a2		;���O�̃u���b�N�̖��g�p�̗̈�����߂�
;<a2.l:��O�̃u���b�N
	bsr	splitBlock
	bmi	reallocOtherPlace	;��O�ɂ͂܂������L�΂��Ȃ�
;<a1.l:��O�̃u���b�N�𕪊����Ăł���u���b�N�̃w�b�_(�t���[�u���b�N�̂Ƃ��͌��̃w�b�_)
	lea.l	(User,a1),a1		;��O�ɐL�΂����ꍇ�̃��[�U�̈�̐擪
	move.l	(Next,a3),d0		;�T�C�Y��ύX����u���b�N�̖���+1
	beq	1f
	cmp.l	a5,d0
	bls	2f
1:	move.l	a5,d0
2:	sub.l	a1,d0			;��O�ɐL�΂����ꍇ�̃T�C�Y
	cmp.l	d3,d0			;����؂邩
	blo	reallocOtherPlace	;����؂�Ȃ�
	lea.l	(-User,a1),a1		;��O�ɐL�΂����ꍇ�̃w�b�_
	bsr	insertHeader		;�V�����w�b�_��}������
	move.l	(Proc,a3),(Proc,a1)	;�e�v���Z�X
	lea.l	(User,a1),a1		;��O�ɐL�΂����ꍇ�̃��[�U�̈�̐擪
;<a1.l:�V�����u���b�N�̃��[�U�̈�̐擪
;<a3.l:�T�C�Y��ύX����u���b�N�̃w�b�_
	bra	reallocDelete

;�ʂ̏ꏊ�Ɉړ�����
;<d3.l:�V�����T�C�Y
;<a3.l:�T�C�Y��ύX����u���b�N�̃w�b�_
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
reallocOtherPlace:
reallocFirstBlock:
	move.l	d3,d2			;�V�����T�C�Y
	move.l	(Proc,a3),d4		;�e�v���Z�X
	bsr	malloc20		;�ʂ̏ꏊ�Ƀu���b�N���m�ۂ���(���ʂ���)
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bmi	reallocEnd		;�m�ۂł��Ȃ�
;���̃u���b�N�̃w�b�_���폜����
;<a1.l:�V�����u���b�N�̃��[�U�̈�̐擪
;<a3.l:�T�C�Y��ύX����u���b�N�̃w�b�_
reallocDelete:
	move.l	a1,d2
;<d2.l:�V�����u���b�N�̃��[�U�̈�̐擪
	moveq.l	#$FFFFFFF0,d4
	add.l	(Tail,a3),d4
	sub.l	a3,d4			;�ړ�����f�[�^�̃T�C�Y
;<d4.l:�ړ�����f�[�^�̃T�C�Y
	movea.l	a3,a2
	bsr	deleteHeader		;���̃u���b�N�̃w�b�_���폜����
;�f�[�^���R�s�[����
;<d2.l:�V�����u���b�N�̃��[�U�̈�̐擪
;<d4.l:�ړ�����f�[�^�̃T�C�Y
;<a3.l:�T�C�Y��ύX����u���b�N�̃w�b�_
	tst.l	d4			;�ړ�����f�[�^�̃T�C�Y
	beq	reallocFreeBlock	;�ړ����ׂ��f�[�^���Ȃ�
	lea.l	(User,a3),a3		;�ړ����̃f�[�^�̐擪
	movea.l	d2,a2			;�ړ���̃f�[�^�̐擪
	subq.l	#1,d4
	lsr.l	#4,d4			;(�T�C�Y-1)/16=(�T�C�Y+15)/16-1
	swap.w	d4
reallocCopy1:
	swap.w	d4
reallocCopy0:
	move.l	(a3)+,(a2)+		;��O�Ɉړ����ďd�Ȃ邱�Ƃ�����̂ŏ����ɒ���
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	move.l	(a3)+,(a2)+
	dbra	d4,reallocCopy0
	swap.w	d4
	dbra	d4,reallocCopy1
reallocFreeBlock:
	movea.l	d2,a1
	lea.l	(a1,d3.l),a2
	move.l	a2,(-User+Tail,a1)
reallocDone:
	moveq.l	#0,d0
reallocEnd:
  debug '|realloc out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d4/a2-a3
	rts

;----------------------------------------------------------------
;�m�ۂł���T�C�Y�̎擾
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:�m�ۂł���T�C�Y�̍��v
;>d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
;*d0-d1
getSize::
	movem.l	d2-d3/a1-a2,-(sp)
  debug '|getsize in (top,btm)=',2,a4,a5
	moveq.l	#0,d2			;�m�ۂł���u���b�N�̃T�C�Y�̍��v
	moveq.l	#0,d3			;�m�ۂł���ő�̃u���b�N�̃T�C�Y
	move.l	a4,d0			;�擪�̃u���b�N
getSizeLoop:
	cmp.l	a5,d0
	bcc	getSizeEnd		;�I���
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	getSizeNext		;���b�N����Ă���
	bsr	splitBlock		;�������Ăł���u���b�N�̃w�b�_�ƃT�C�Y�����߂�
	bmi	getSizeNext		;�����ł��Ȃ�
	tst.l	d1
	beq	getSizeNext
	add.l	d1,d2			;�m�ۂł���u���b�N�̃T�C�Y�̍��v���X�V
	cmp.l	d3,d1			;����܂łɌ��������ő�̃u���b�N���傫����
	bls	getSizeNotLargest	;��������������
	move.l	d1,d3			;�ő�̃u���b�N�̃T�C�Y���X�V
getSizeNotLargest:
getSizeNext:
	move.l	(Next,a2),d0		;���̃u���b�N��
	bne	getSizeLoop
getSizeEnd:
	move.l	d2,d0			;���v�T�C�Y
	move.l	d3,d1			;�ő�̃T�C�Y
  debug '|getsize out (ttl,max)=',2,d0,d1
	movem.l	(sp)+,d2-d3/a1-a2
	rts

;----------------------------------------------------------------
;�w�b�_��T��
;	���b�N����Ă���u���b�N�͌������Ȃ�
;<d2.l:�w�b�_
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=�擪�̃u���b�N,1=�擪�ȊO�̃u���b�N,-1=���s
;>a2.l:0=���s,0�ȊO=�w�b�_
;*d0/a2
searchBlock2::
	bsr	searchBlock
	bmi	searchBlock2End		;������Ȃ�
	tst.b	(Tail,a2)
	bpl	searchBlock2Done
	suba.l	a2,a2			;���b�N����Ă���
	moveq.l	#-1,d0
searchBlock2Done:
	tst.l	d0
searchBlock2End:
	rts

;----------------------------------------------------------------
;�w�b�_��T��
;	���b�N����Ă���u���b�N����������
;<d2.l:�w�b�_
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=�擪�̃u���b�N,1=�擪�ȊO�̃u���b�N,-1=���s
;>a2.l:0=���s,0�ȊO=�w�b�_
;*d0/a2
searchBlock::
	cmp.l	a4,d2
	bcs	searchBlockFailed	;�͈͊O
	cmp.l	a5,d2
	bcc	searchBlockFailed	;�͈͊O
	move.l	a4,d0			;�擪�̃u���b�N
searchBlockLoop:
	cmp.l	a5,d0
	bcc	searchBlockFailed	;������Ȃ�����
	movea.l	d0,a2
	tst.b	(Tail,a2)
	bmi	searchBlockNext		;���b�N����Ă���
	cmpa.l	d2,a2
	beq	searchBlockFound	;��������
searchBlockNext:
	move.l	(Next,a2),d0		;���̃u���b�N��
	bne	searchBlockLoop
searchBlockFailed:
	suba.l	a2,a2			;���s
	moveq.l	#-1,d0
	bra	searchBlockEnd

searchBlockFound:
	moveq.l	#0,d0
	cmpa.l	a4,a2
	beq	searchBlockEnd		;�擪�̃u���b�N
	moveq.l	#1,d0
searchBlockEnd:
	rts

;----------------------------------------------------------------
;�������Ăł���u���b�N�̃w�b�_�ƃT�C�Y�����߂�
;<a2.l:��������u���b�N�̃w�b�_(�����ȃA�h���X�͎w��s��)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>d0.l:0=�t���[�u���b�N�Ȃ̂ŕ������Ȃ�,1=�t���[�u���b�N�ł͂Ȃ��̂ŕ�������,-1=���s
;>d1.l:0=���s,0�ȊO=�������Ăł���u���b�N�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�������Ăł���u���b�N�̃w�b�_(�t���[�u���b�N�̂Ƃ��͌��̃w�b�_)
;*d0-d1/a1
splitBlock::
  debug '|splitBlock in (header,limit)=',2,a2,a5
	lea.l	(User,a2),a1		;���[�U�̈�̐擪
	move.l	(Tail,a2),d0
	sub.l	a1,d0			;���[�U�̈�̃T�C�Y
	bne	splitBlockUsed
;�t���[�u���b�N�̂Ƃ�
	move.l	(Next,a2),d1		;����+1
	beq	1f
	cmp.l	a5,d1
	bls	2f
1:	move.l	a5,d1
2:	sub.l	a1,d1			;�m�ۂł���T�C�Y
	ble	splitBlockFailed	;�m�ۂł��Ȃ�
	movea.l	a2,a1
	moveq.l	#0,d0
  debug '|splitBlock out (split,size,header)=',3,d0,d1,a1
	rts

;�t���[�u���b�N�ł͂Ȃ��Ƃ�
splitBlockUsed:
	lea.l	(15,a1,d0.l),a1		;���[�U�̈�̖���+1+15
	move.l	a1,d1
	moveq.l	#$FFFFFFF0,d0
	and.w	d0,d1
	movea.l	d1,a1			;�V�����w�b�_
	move.l	(Next,a2),d1		;����+1
	beq	1f
	cmp.l	a5,d1
	bls	2f
1:	move.l	a5,d1
2:	sub.l	a1,d1			;�w�b�_���܂߂��T�C�Y
	ble	splitBlockFailed	;�w�b�_������Ȃ�
	add.l	d0,d1			;�m�ۂł���T�C�Y
	beq	splitBlockFailed	;�w�b�_��������Ȃ�
	moveq.l	#1,d0
  debug '|splitBlock out (split,size,header)=',3,d0,d1,a1
	rts

splitBlockFailed:
	suba.l	a1,a1
	moveq.l	#0,d1
	moveq.l	#-1,d0
  debug '|splitBlock out (split,size,header)=',3,d0,d1,a1
	rts

;----------------------------------------------------------------
;�w�b�_��}������
;	�u���b�N�𕪊����ăw�b�_����胊�X�g�ɑ}������
;	���[�U�̈�̃T�C�Y�͐ݒ肵�Ȃ�
;	�e�v���Z�X�͐ݒ肵�Ȃ�
;	�V�����w�b�_����������u���b�N�̃w�b�_�Ɠ����Ȃ�Ή������Ȃ�
;<a1.l:�V�����w�b�_
;<a2.l:��������u���b�N�̃w�b�_
;?d0
insertHeader::
	cmpa.l	a2,a1
	beq	insertHeaderFreeBlock
	move.l	a2,(Prev,a1)		;���O��ݒ�
	move.l	(Next,a2),d0
	move.l	a1,(Next,a2)		;��������u���b�N���k�߂�
	move.l	d0,(Next,a1)		;�����ݒ�
	beq	insertHeaderLastBlock
	exg.l	d0,a2
	move.l	a1,(Prev,a2)		;����̃u���b�N�̒��O��ݒ�
	exg.l	d0,a2
insertHeaderLastBlock:
insertHeaderFreeBlock:
	rts

;----------------------------------------------------------------
;�w�b�_���폜����
;	�m�ۂ����v���Z�X��0�ɂ���
;	�t���[�u���b�N�ɂ���
;	�擪�̃u���b�N�łȂ���΃w�b�_�����X�g�����菜��
;<a2.l:�폜����w�b�_�̃A�h���X(�擪�̃u���b�N�̃w�b�_�͍폜���Ȃ�)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N)
;?d0/a1
deleteHeader::
	clr.l	(Proc,a2)		;�m�ۂ����v���Z�X��0�ɂ���
	lea.l	(User,a2),a1
	move.l	a1,(Tail,a2)		;�t���[�u���b�N�ɂ���
	cmpa.l	a4,a2
	beq	deleteHeaderFirstBlock	;�擪�̃u���b�N
	move.l	(Prev,a2),a1		;���O
	move.l	(Next,a2),d0		;����
	move.l	d0,(Next,a1)		;���O�̃u���b�N�̒����ݒ�
	beq	deleteHeaderLastBlock
	exg.l	d0,a2
	move.l	a1,(Prev,a2)		;����̃u���b�N�̒��O��ݒ�
	exg.l	d0,a2
deleteHeaderLastBlock:
deleteHeaderFirstBlock:
	rts

;----------------------------------------------------------------
;�����ȊO�̘A���������^�T�u�X���b�h�̂��ׂẴu���b�N�����b�N����
;<a0.l:�����̃T�u�X���b�h�̃X���b�h�Ǘ��e�[�u��,�ʏ��[$1C54.w].l
lockBlocks::
	movem.l	d0-d4/a2-a5,-(sp)
	move.w	$1C58.w,d1		;�X���b�h��-1=�T�u�X���b�h��
	beq	lockBlocksEnd		;�T�u�X���b�h�����݂��Ȃ�
	moveq.l	#$80,d2
	movea.l	$1C50.w,a3		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	move.l	(tMemStart,a3),d3	;���C���X���b�h�̃�������Ԃ̐擪
	move.l	(tMemStart,a0),d4	;�����̃�������Ԃ̐擪
;<d1.w:�X���b�h��-1=�T�u�X���b�h��(>0)
;<d2.b:$80
;<d3.l:���C���X���b�h�̃�������Ԃ̐擪
;<d4.l:�����̃�������Ԃ̐擪
;<a0.l:�����̃T�u�X���b�h�̃X���b�h�Ǘ��e�[�u��
;<a3.l:���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	subq.w	#1,d1			;�T�u�X���b�h��-1
lockBlocksThreadLoop:
	lea.l	(tSize,a3),a3
;<a3.l:�X���b�h�Ǘ��e�[�u��
	tst.l	(tProcess,a3)
	beq	lockBlocksNextThread	;���g�p�̃X���b�h
	cmpa.l	a0,a3
	beq	lockBlocksNextThread	;�����̓��b�N���Ȃ�
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	cmpa.l	d3,a4
	beq	lockBlocksNextThread	;���C���X���b�h�Ɠ�����������ԂȂ̂Ń��b�N���Ȃ�
	cmpa.l	d4,a4
	beq	lockBlocksNextThread	;�����Ɠ�����������ԂȂ̂Ń��b�N���Ȃ�
	moveq.l	#(.not.LOGICAL_MASK)>>24,d0
	and.b	(Proc,a4),d0
	cmp.b	#$C0,d0			;�擪�̃u���b�N�ɃT�u�X���b�h�̃t���O������ΘA���������^
	bne	lockBlocksNextThread	;�T�u�������^�T�u�X���b�h�̃�������ԂȂ̂Ń��b�N���Ȃ�
	move.l	a4,d0
lockBlocksSubLoop:
	cmp.l	a5,d0
	bcc	lockBlocksNextThread
	movea.l	d0,a2
	or.b	d2,(Tail,a2)		;���b�N����
	move.l	(Next,a2),d0
	bne	lockBlocksSubLoop
lockBlocksNextThread:
	dbra	d1,lockBlocksThreadLoop
;
lockBlocksEnd:
	movem.l	(sp)+,d0-d4/a2-a5
	rts

;----------------------------------------------------------------
;�u���b�N�̃��b�N����������
;	���C���X���b�h�̃�������Ԃɂ���u���b�N�ɂ��ă��b�N����Ă������������
unlockBlocks::
	movem.l	d0-d2/a2-a5,-(sp)
	move.w	$1C58.w,d1		;�X���b�h��-1
	beq	lockBlocksEnd		;�T�u�X���b�h�����݂��Ȃ�
	moveq.l	#$7F,d2
	movea.l	$1C50.w,a3		;���C���X���b�h�̃X���b�h�Ǘ��e�[�u��
	movea.l	(tMemStart,a3),a4
	movea.l	(tMemEnd,a3),a5
;<a4.l:���C���X���b�h�̃�������Ԃ̐擪
;<a5.l:���C���X���b�h�̃�������Ԃ̖���+1
	move.l	a4,d0
unlockBlocksLoop:
	cmp.l	a5,d0
	bcc	unlockBlocksEnd
	movea.l	d0,a2
	and.b	d2,(Tail,a2)		;���b�N����������
	move.l	(Next,a2),d0
	bne	unlockBlocksLoop
unlockBlocksEnd:
	movem.l	(sp)+,d0-d2/a2-a5
	rts

;----------------------------------------------------------------
;���s���̃v���Z�X�̃������Ǘ��e�[�u���𓾂�
;>d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
;*d4
getProc::
	move.l	([$1C28.w]),d4		;���s���̃v���Z�X�̃������Ǘ��e�[�u��
	rts

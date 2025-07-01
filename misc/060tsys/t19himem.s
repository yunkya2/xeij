;----------------------------------------------------------------
;
;	_HIMEM
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ
	.include	t09version.equ

;__DEBUG__	equ	1

;TS16_VERSION
;	TS16DRV.X�ł̃o�[�W����
;	TS16DRV.X�̍Ō�̃o�[�W������$12�Ȃ̂ŁA$13�ɂ��Ă���
TS16_VERSION	equ	$13

	.cpu	68060

;----------------------------------------------------------------
;IOCS _HIMEM($F8)	�n�C����������
;	TS-6BE16�̓Y�t�f�B�X�N�ɓ����Ă���HIMEM.SYS v1.0�Ƃقڏ�ʌ݊�
;	�g��������TS-6BE16�Ǘ��h���C�o(TS16DRV.X)�Ƃقڏ�ʌ݊�
;<d1.w:�R�}���h�R�[�h
;	1	HIMEM_MALLOC
;		�u���b�N�̊m��
;			���ʃA�h���X����m�ۂ���
;			<d2.l:�m�ۂ���u���b�N�̃T�C�Y
;			>d0.l:0=����,-1=���s
;			>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	2	HIMEM_FREE
;		�u���b�N�̊J��
;			<d2.l:�J������u���b�N�̃��[�U�̈�̐擪
;				0=���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ��
;			>d0.l:0=����,-1=���s
;	3	HIMEM_GETSIZE
;		�m�ۂł���T�C�Y�̎擾
;			>d0.l:�m�ۂł���T�C�Y�̍��v
;			>d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
;	4	HIMEM_RESIZE
;		�u���b�N�̃T�C�Y�ύX
;			�u���b�N�͈ړ����Ȃ�
;			�V�����T�C�Y��0�Ȃ�΃u���b�N���J������
;			<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;			<d3.l:�V�����T�C�Y(0=�u���b�N���J������)
;			>d0.l:0=����,-1=���s
;	�ȍ~�̃R�[����HIMEM.SYS v1.0�ɂ͂Ȃ�
;	5	HIMEM_VERSION
;		_HIMEM�̃o�[�W�����̎擾
;			>d0.l:'060T'
;			>d1.l:�o�[�W����
;	6	HIMEM_CALLOC
;		�z��̂��߂̃u���b�N�̊m��
;			���ʃA�h���X����m�ۂ���
;			�m�ۂ����u���b�N��0�ŏ����������
;			<d2.l:�z��v�f��
;			<d3.l:�z��v�f�T�C�Y
;			>d0.l:0=����,-1=���s
;			>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	7	HIMEM_REALLOC
;		�u���b�N�̃T�C�Y�ύX
;			�u���b�N���ړ����邱�Ƃ�����
;			�ړ�����Ƃ��V�����u���b�N�͉��ʂ���m�ۂ���
;			�ړ����Ă��u���b�N���m�ۂ����v���Z�X�͕ω����Ȃ�
;			�V�����T�C�Y��0�Ȃ�΃u���b�N���J������
;			<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;			<d3.l:�V�����T�C�Y(0=�u���b�N���J������)
;			>d0.l:0=����,-1=���s
;			>a1.l:0=���s,0�ȊO=�ړ���̃u���b�N�̃��[�U�̈�̐擪
;	8	HIMEM_MALLOC2
;		�u���b�N�̊m��
;			<d2.l:�m�ۂ���T�C�Y
;			<d3.w:bit15=�v���Z�X�w��t���O
;					0	���s���̃v���Z�X
;					1	d4.l��e�v���Z�X�Ƃ��Ďg�p����
;				����8bit=���[�h
;					0	���ʂ���
;					1	�K�v�ŏ��u���b�N����
;					2	��ʂ���
;					3	�ő�u���b�N����
;			<d4.l:(d3.w��bit15��1�̂Ƃ�)�e�v���Z�X�̃������Ǘ��e�[�u��
;			>d0.l:0=����,$81xxxxxx=�m�ۂł���ő�̃T�C�Y,$82000000=�܂������m�ۂł��Ȃ�
;			>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	9	HIMEM_PSFREE
;		����̃v���Z�X���m�ۂ����u���b�N�̊J��
;			�q�v���Z�X���m�ۂ����u���b�N���J������
;			<d2.l:�J������u���b�N���m�ۂ����v���Z�X�̃������Ǘ��e�[�u��
;			>d0.l:0=����,-1=���s
;	10	HIMEM_GETAREA
;		_HIMEM�ŃA�N�Z�X�ł��郁������Ԃ̎擾
;			>d0.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_),-1=���s
;			>d1.l:��������Ԃ̖���+1,-1=���s
;?d0,d1-d7/a0-a6�͕ԋp�Ɏg������̂������Ĕj�󂳂�Ȃ�
	.dc.b	'060T'
	.dc.b	'TS16DRV',TS16_VERSION
	.dc.b	'HIMEM',0
iocsHimem::
	cmp.w	#(himemJumpTableEnd-himemJumpTable)/4,d1
	bcc	himemUnknownCall
	jmp	([himemJumpTable,pc,d1.w*4])

himemReserved:
himemUnknownCall:
	moveq.l	#-1,d0
	rts

himemJumpTable:
	.dc.l	himemReserved
	.dc.l	himemMalloc
	.dc.l	himemFree
	.dc.l	himemGetSize
	.dc.l	himemResize
	.dc.l	himemVersion
	.dc.l	himemCalloc
	.dc.l	himemRealloc
	.dc.l	himemMalloc2
	.dc.l	himemPsfree
	.dc.l	himemGetArea
himemJumpTableEnd:

;----------------------------------------------------------------
;_HIMEM	1	�u���b�N�̊m��
;	���ʃA�h���X����m�ۂ���
;<d2.l:�m�ۂ���u���b�N�̃T�C�Y
;>d0.l:0=����,-1=���s
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
himemMalloc::
  debug '|himemMalloc in (size)=',1,d2
	movem.l	d4/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemMallocFailed
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	bsr	malloc20		;�u���b�N�̊m��(���ʂ���)
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bpl	himemMallocEnd
	moveq.l	#-1,d0
himemMallocEnd:
  debug '|himemMalloc out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d4/a4-a5
	rts

himemMallocFailed:
	suba.l	a1,a1
	bra	himemMallocEnd

;----------------------------------------------------------------
;_HIMEM	2	�u���b�N�̊J��
;<d2.l:�J������u���b�N�̃��[�U�̈�̐擪
;	0=���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ��
;>d0.l:0=����,-1=���s
himemFree::
  debug '|himemFree in (ptr)=',1,d2
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemFreeEnd
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	tst.l	d2
	beq	himemFreeProc		;���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ��
	bsr	free
;<d0.l:0=����,-1=�w�b�_��������Ȃ�
himemFreeEnd:
  debug '|himemFree out (err)=',1,d0
	movem.l	(sp)+,a4-a5
	rts

;���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ��
himemFreeProc:
	move.l	d4,-(sp)
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	bsr	psfree
;<d0.l:0(��ɐ�������)
	move.l	(sp)+,d4
	tst.l	d0
	bra	himemFreeEnd

;----------------------------------------------------------------
;_HIMEM	3	�m�ۂł���T�C�Y�̎擾
;>d0.l:�m�ۂł���T�C�Y�̍��v
;>d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
;*d0-d1
himemGetSize::
  debug '|himemGetSize in',0
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemGetSizeFailed
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	bsr	getSize
;<d0.l:�m�ۂł���T�C�Y�̍��v
;<d1.l:��x�Ɋm�ۂł���ő�̃T�C�Y
himemGetSizeEnd:
  debug '|himemGetSize out (ttl,max)=',2,d0,d1
	movem.l	(sp)+,a4-a5
	rts

himemGetSizeFailed:
	moveq.l	#0,d0
	moveq.l	#0,d1
	bra	himemGetSizeEnd

;----------------------------------------------------------------
;_HIMEM	4	�u���b�N�̃T�C�Y�ύX
;	�u���b�N�͈ړ����Ȃ�
;	�V�����T�C�Y��0�Ȃ�΃u���b�N���J������
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y(0=�u���b�N���J������)
;>d0.l:0=����,-1=���s
;*d0
himemResize::
  debug '|himemResize in (ptr,size)=',2,d2,d3
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemResizeEnd
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	bsr	resizeOrFree
;<d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
	bpl	himemResizeEnd
	moveq.l	#-1,d0
himemResizeEnd:
  debug '|himemResize out (err)=',1,d0
	movem.l	(sp)+,a4-a5
	rts

;----------------------------------------------------------------
;_HIMEM	5	_HIMEM�̃o�[�W�����̎擾
;>d0.l:'060T'
;>d1.l:�o�[�W����
;*d0-d1
himemVersion::
	move.l	#'060T',d0
	move.l	#VERSION,d1
	rts

;----------------------------------------------------------------
;_HIMEM	6	�z��̂��߂̃u���b�N�̊m��
;	���ʃA�h���X����m�ۂ���
;	�m�ۂ����u���b�N��0�ŏ����������
;<d2.l:�z��v�f��
;<d3.l:�z��v�f�T�C�Y
;>d0.l:0=����,-1=���s
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
himemCalloc::
  debug '|himemCalloc in (cnt,size)=',2,d2,d3
	movem.l	d1-d2/d4/a2/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemCallocFailed
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	d2,d0
	move.l	d3,d1
	bsr	imul			;32bit�~32bit��64bit��Z(�����Ȃ�)
	tst.l	d0
	bne	himemCallocFailed	;�I�[�o�[�t���[
	move.l	d1,d2
	bmi	himemCallocFailed	;�I�[�o�[�t���[
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	bsr	malloc20		;�u���b�N�̊m��(���ʂ���)
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bmi	himemCallocFailed	;�m�ۂł��Ȃ�
	movea.l	a1,a2			;�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	subq.l	#1,d2
	bcs	himemCallocDone		;�T�C�Y��0
	moveq.l	#0,d0
	lsr.l	#4,d2			;(�T�C�Y-1)/16=(�T�C�Y+15)/16-1
	swap.w	d2
himemCallocClear1:
	swap.w	d2
himemCallocClear0:
	move.l	d0,(a2)+
	move.l	d0,(a2)+
	move.l	d0,(a2)+
	move.l	d0,(a2)+
	dbra	d2,himemCallocClear0
	swap.w	d2
	dbra	d2,himemCallocClear1
himemCallocDone:
	moveq.l	#0,d0
himemCallocEnd:
  debug '|himemCalloc out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d1-d2/d4/a2/a4-a5
	rts

himemCallocFailed:
	suba.l	a1,a1
	moveq.l	#-1,d0
	bra	himemCallocEnd

;----------------------------------------------------------------
;_HIMEM	7	�u���b�N�̃T�C�Y�ύX
;	�u���b�N���ړ����邱�Ƃ�����
;	�ړ�����Ƃ��V�����u���b�N�͉��ʂ���m�ۂ���
;	�ړ����Ă��u���b�N���m�ۂ����v���Z�X�͕ω����Ȃ�
;	�V�����T�C�Y��0�Ȃ�΃u���b�N���J������
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y(0=�u���b�N���J������)
;>d0.l:0=����,-1=���s
;>a1.l:0=���s,0�ȊO=�ړ���̃u���b�N�̃��[�U�̈�̐擪
himemRealloc::
  debug '|himemRealloc in (ptr,size)=',2,d2,d3
	movem.l	d1-d2/a2/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemReallocFailed
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	bsr	reallocOrFree
;>d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�ړ���̃u���b�N�̃��[�U�̈�̐擪
	bmi	himemReallocFailed
himemReallocEnd:
  debug '|himemRealloc out (err,ptr,)=',2,d0,a1
	movem.l	(sp)+,d1-d2/a2/a4-a5
	rts

himemReallocFailed:
	suba.l	a1,a1
	moveq.l	#-1,d0
	bra	himemReallocEnd

;----------------------------------------------------------------
;_HIMEM	8	�u���b�N�̊m��
;<d2.l:�m�ۂ���T�C�Y
;<d3.w:bit15=�v���Z�X�w��t���O
;		0	���s���̃v���Z�X
;		1	d4.l��e�v���Z�X�Ƃ��Ďg�p����
;	����8bit=���[�h
;		0	���ʂ���
;		1	�K�v�ŏ��u���b�N����
;		2	��ʂ���
;		3	�ő�u���b�N����
;<d4.l:(d3.w��bit15��1�̂Ƃ�)�e�v���Z�X�̃������Ǘ��e�[�u��
;>d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;>a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;*d0/a1
himemMalloc2::
  debug '|himemMalloc2 in (size,mode,proc)=',3,d2,d3,d4
	movem.l	d4/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemMalloc2Failed
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.w	d3,d0
	bmi	@f
	bsr	getProc
@@:
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	and.w	#$00FF,d0
	cmp.w	#4,d0
	bcc	himemMalloc2Failed
	jsr	([malloc2Table,pc,d0.w*4])	;�u���b�N�̊m��
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bpl	himemMalloc2End
	moveq.l	#-1,d0
himemMalloc2End:
  debug '|himemMalloc2 out (err,ptr)=',2,d0,a1
	movem.l	(sp)+,d4/a4-a5
	rts

himemMalloc2Failed:
	suba.l	a1,a1
	moveq.l	#-1,d0
	bra	himemMalloc2End

;----------------------------------------------------------------
;_HIMEM	9	����̃v���Z�X���m�ۂ����u���b�N�̊J��
;	�q�v���Z�X���m�ۂ����u���b�N���J������
;<d2.l:�J������u���b�N���m�ۂ����v���Z�X�̃������Ǘ��e�[�u��
;>d0.l:0=����,-1=���s
;*d0
himemPsfree::
  debug '|himemPsfree in (proc)=',1,d2
	movem.l	d4/a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemPsfreeEnd
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	d2,d4
;<d4.l:�J������u���b�N���m�ۂ����v���Z�X�̃������Ǘ��e�[�u��
	bsr	psfree
;<d0.l:0(��ɐ�������)
himemPsfreeEnd:
  debug '|himemPsfree out (err)=',1,d0
	movem.l	(sp)+,d4/a4-a5
	rts

;----------------------------------------------------------------
;_HIMEM	10	_HIMEM�ŃA�N�Z�X�ł��郁������Ԃ̎擾
;>d0.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_),-1=���s
;>d1.l:��������Ԃ̖���+1,-1=���s
;*d0-d1
himemGetArea::
  debug '|himemGetArea in',0
	movem.l	a4-a5,-(sp)
	bsr	himemAreaSet
	bmi	himemGetAreaFailed
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	a4,d0
	move.l	a5,d1
;<d0.l:��������Ԃ̐擪(�擪�̃u���b�N)
;<d1.l:��������Ԃ̖���+1
himemGetAreaEnd:
  debug '|himemGetArea out (top,btm)=',2,d0,d1
	movem.l	(sp)+,a4-a5
	rts

himemGetAreaFailed:
	moveq.l	#-1,d0
	moveq.l	#-1,d1
	bra	himemGetAreaEnd

;----------------------------------------------------------------
;----------------------------------------------------------------
;�g����������Ԃ��A�N�Z�X�ł��邩���ׂ�
;	�V����mpusw.r��_HIMEM�g�p����68000���[�h�ɐ؂�ւ����Ȃ��悤�ɂȂ��Ă���
;>d0.l:0=����,-1=���s
;>a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;>a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
himemAreaSet::
	tst.l	himemAreaSize
	beq	9f			;�g����������Ԏg�p�s��
	movea.l	himemAreaStart,a4
	movea.l	himemAreaEnd,a5
	moveq.l	#0,d0
	rts

9:	moveq.l	#-1,d0
	rts

;----------------------------------------------------------------
;32bit�~32bit��64bit��Z(�����Ȃ�)
;<d0.l:��搔
;<d1.l:�搔
;>d0.l:����(���)
;>d1.l:����(����)
;*d0-d1
imul::
	movem.l	d2-d4,-(sp)
	move.l	d0,d3
	move.l	d1,d4
	swap.w	d3
	swap.w	d4
	move.w	d3,d2
	mulu.w	d1,d2
	mulu.w	d0,d1
	mulu.w	d4,d0
	mulu.w	d3,d4
	add.l	d2,d0
	clr.w	d3
	addx.w	d3,d3
	swap.w	d1
	add.w	d0,d1
	swap.w	d1
	move.w	d3,d0
	swap.w	d0
	addx.l	d4,d0
	movem.l	(sp)+,d2-d4
	rts

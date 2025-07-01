;----------------------------------------------------------------
;
;	�������Ǘ��֘A��DOSCALL
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;_MALLOC	�u���b�N�̊m��(���ʂ���)
;<(a6).l:�m�ۂ���u���b�N�̃T�C�Y
;>d0.l:�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	$81xxxxxx=�m�ۂł���ő�̃T�C�Y,$82000000=�܂������m�ۂł��Ȃ�
;*d0,?d2/d4-d5/a0-a5
dosMalloc::
  debug '|malloc in (size)=',1,(a6)
	bsr	dosAreaLockMalloc
	bmi	dosMallocNever
;<a2.l:(�����)��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a3.l:(�����)��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	(a6),d2			;�m�ۂ���T�C�Y
;<d2.l:�m�ۂ���T�C�Y
	cmp.l	#$00FFFFF0,d2		;$00FFFFF0�����傫���Ƃ��͍ő�T�C�Y�̎擾�ƌ��Ȃ�
	bhi	dosMallocGetSize
;�u���b�N���m�ۂ���
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	bsr	malloc20		;�u���b�N�̊m��(���ʂ���)
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bpl	dosMallocDone
	movea.l	a2,a4
	movea.l	a3,a5
	bsr	malloc20
	bmi	dosMallocFailed
dosMallocDone:
	move.l	a1,d0
dosMallocEnd:
	bsr	dosAreaUnlock
  debug '|malloc out (ptr)=',1,d0
	tst.l	d0
	rts

;�ő�T�C�Y�̎擾
dosMallocGetSize:
	movea.l	a2,a4			;�ő�̃T�C�Y�͗D��͈͂ɐ��������ɋ��߂�
	movea.l	a3,a5
	bsr	getSize
	move.l	d1,d0			;��x�Ɋm�ۂł���ő�̃T�C�Y
dosMallocFailed:
	lsl.l	#1,d0
	beq	dosMallocNever		;�܂������m�ۂł��Ȃ�
	lsr.l	#1,d0
	cmp.l	#$00FFFFF0,d0
	bls	@f
	move.l	#$00FFFFF0,d0		;$00FFFFFF�͕s��(����1�x$00FFFFFF�ŌĂ΂�Ă��܂�����)
@@:	or.l	#$81000000,d0
	bra	dosMallocEnd

dosMallocNever:
	move.l	#$82000000,d0		;�܂������m�ۂł��Ȃ�
	bra	dosMallocEnd

;----------------------------------------------------------------
;_MALLOC3	�u���b�N�̊m��(���ʂ���)
;<(a6).l:�m�ۂ���u���b�N�̃T�C�Y
;>d0.l:�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0,?d2/d4-d5/a0-a5
dosMalloc3::
  debug '|malloc3 in (size)=',1,(a6)
  debugChar '!'
	bsr	dosAreaLockMalloc
	bmi	dosMalloc3Never
  debugChar '@'
;<a2.l:(�����)��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a3.l:(�����)��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	(a6),d2			;�m�ۂ���T�C�Y
;<d2.l:�m�ۂ���T�C�Y
;�u���b�N���m�ۂ���
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	bsr	malloc20		;�u���b�N�̊m��(���ʂ���)
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bpl	dosMalloc3Done
	movea.l	a2,a4
	movea.l	a3,a5
	bsr	malloc20
	bmi	dosMalloc3End
dosMalloc3Done:
	move.l	a1,d0
dosMalloc3End:
	bsr	dosAreaUnlock
  debug '|malloc3 out (ptr)=',1,d0
	tst.l	d0
	rts

dosMalloc3Never:
	move.l	#$80000000,d0
	bra	dosMalloc3End

;----------------------------------------------------------------
;_MFREE		�u���b�N�̊J��
;(a6).l:�J������u���b�N�̃��[�U�̈�̐擪
;	0=���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ������
;>d0.l:�G���[�R�[�h
;	$FFFFFFF7=�����ȃu���b�N���w�肵��
;*d0,?d2/d4-d5/a0-a5
dosMfree::
  debug '|mfree in (ptr)=',1,(a6)
	moveq.l	#8,d5			;�����Ȃ�,�D��Ȃ�
	bsr	dosAreaLock
	bmi	dosMfreeNotFound
;�����Ȃ�,�D��Ȃ��Ȃ̂�a2-a3��a4-a5�Ɠ���
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	(a6),d2			;�J������u���b�N�̃��[�U�̈�̐擪
	beq	dosMfreeProc		;���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ��
;<d2.l:�J������u���b�N�̃��[�U�̈�̐擪
dosMfreeSMfree::
	bsr	free
;<d0.l:0=����,-1=�w�b�_��������Ȃ�
	bmi	dosMfreeNotFound	;�J���ł��Ȃ�
dosMfreeEnd:
	bsr	dosAreaUnlock
  debug '|mfree out (error-code)=',1,d0
	tst.l	d0
	rts

;���s���̃v���Z�X���m�ۂ����u���b�N�����ׂĊJ��
dosMfreeProc:
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	bsr	psfree
;<d0.l:0(��ɐ�������)
	bra	dosMfreeEnd

dosMfreeNotFound:
	moveq.l	#$FFFFFFF7,d0		;�����ȃu���b�N���w�肵��
	bra	dosMfreeEnd

;----------------------------------------------------------------
;_SETBLOCK	�u���b�N�̃T�C�Y�ύX
;	�u���b�N�͈ړ����Ȃ�
;<(a6).l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<(4,a6).l:�V�����T�C�Y
;>d0.l:�G���[�R�[�h
;	$FFFFFFF7=�����ȃu���b�N���w�肵��
;	$81xxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0,?d2-d3/d5/a0-a5
dosSetblock::
  debug '|setblock in (ptr,size)=',2,(a6),(4,a6)
	moveq.l	#8,d5			;�����Ȃ�,�D��Ȃ�
	bsr	dosAreaLock
	bmi	dosSetblockNotFound
;�����Ȃ�,�D��Ȃ��Ȃ̂�a2-a3��a4-a5�Ɠ���
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	(a6),d2
	move.l	(4,a6),d3
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y
	cmp.l	#$00FFFFF0,d3		;$00FFFFF0�����傫���Ƃ��͍ő�T�C�Y�̎擾�ƌ��Ȃ�
	bhi	dosSetblockGetSize
;�T�C�Y��ύX����
	bsr	resize
;<d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
	bmi	dosSetblockFailed
dosSetblockEnd:
	bsr	dosAreaUnlock
  debug '|setblock out (error-code)=',1,d0
	tst.l	d0
	rts

;�ő�T�C�Y�̎擾
dosSetblockGetSize:
	moveq.l	#-1,d3			;�K���G���[���o��
	bsr	resize
dosSetblockFailed:
;<d0.l:-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
	cmp.l	#$FFFFFFFF,d0
	beq	dosSetblockNotFound
	cmp.l	#$80FFFFF0,d0
	blo	@f
	move.l	#$80FFFFF0,d0		;$80FFFFFF�͕s��(����1�x$00FFFFFF�ŌĂ΂�Ă��܂�����)
@@:	or.l	#$81000000,d0
	bra	dosSetblockEnd

dosSetblockNotFound:
	moveq.l	#$FFFFFFF7,d0		;�����ȃu���b�N���w�肵��
	bra	dosSetblockEnd

;----------------------------------------------------------------
;_SETBLOCK2	�u���b�N�̃T�C�Y�ύX
;	�u���b�N�͈ړ����Ȃ�
;<(a6).l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<(4,a6).l:�V�����T�C�Y
;>d0.l:�G���[�R�[�h
;	$FFFFFFF7=�����ȃu���b�N���w�肵��
;	$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0,?d2-d3/d5/a0-a5
dosSetblock2::
  debug '|setblock2 in (ptr,size)=',2,(a6),(4,a6)
	moveq.l	#8,d5			;�����Ȃ�,�D��Ȃ�
	bsr	dosAreaLock
	bmi	dosSetblock2NotFound
;�����Ȃ�,�D��Ȃ��Ȃ̂�a2-a3��a4-a5�Ɠ���
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
	move.l	(a6),d2
	move.l	(4,a6),d3
;<d2.l:�T�C�Y��ύX����u���b�N�̃��[�U�̈�̐擪
;<d3.l:�V�����T�C�Y
;�T�C�Y��ύX����
	bsr	resize
;<d0.l:0=����,-1=�w�b�_��������Ȃ�,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
	cmp.l	#$FFFFFFFF,d0
	beq	dosSetblock2NotFound
dosSetblock2End:
	bsr	dosAreaUnlock
  debug '|setblock2 out (error-code)=',1,d0
	tst.l	d0
	rts

dosSetblock2NotFound:
	moveq.l	#$FFFFFFF7,d0		;�����ȃu���b�N���w�肵��
	bra	dosSetblock2End

;----------------------------------------------------------------
;_MALLOC2	�u���b�N�̊m��(���[�h�w�肠��)
;<(a6).w:bit15=�v���Z�X�w��t���O(0=���s���̃v���Z�X,1=(6,a6).l��e�v���Z�X�Ƃ��Ďg�p����)
;	����8bit=���[�h(0=���ʂ���,1=�K�v�ŏ��u���b�N����,2=��ʂ���,3=�ő�u���b�N����)
;<(2,a6).l:�m�ۂ���T�C�Y
;<(6,a6).l:((a6).w��bit15��1�̂Ƃ�)�e�v���Z�X�̃������Ǘ��e�[�u��
;>d0.l:�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	$FFFFFFF2=�p�����[�^������
;	$81xxxxxx=�m�ۂł���ő�̃T�C�Y,$82000000=�܂������m�ۂł��Ȃ�
;*d0,?d2-d4/a0-a5
dosMalloc2::
  debug '|malloc2 in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	bsr	dosAreaLockMalloc
	bmi	dosMalloc2Never
;<a2.l:(�����)��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a3.l:(�����)��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
dosMalloc2SMalloc::
	move.l	(2,a6),d2		;�m�ۂ���T�C�Y
;<d2.l:�m�ۂ���T�C�Y
	cmp.l	#$00FFFFF0,d2		;00FFFFF0�����傫���Ƃ��͍ő�T�C�Y�̎擾�ƌ��Ȃ�
	bhi	dosMalloc2GetSize
;�e�v���Z�X�̃������Ǘ��e�[�u�������߂�
	bsr	getProc
	move.w	(a6),d3			;���[�h
	bpl	@f
	move.l	(6,a6),d4		;�e�v���Z�X�̃������Ǘ��e�[�u��
	and.w	#$7FFF,d3
@@:	cmp.w	#4,d3
	bcc	dosMalloc2ParamError
;�u���b�N���m�ۂ���
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	jsr	([malloc2Table,d3.w*4])	;�u���b�N�̊m��
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bpl	dosMalloc2Done
	movea.l	a2,a4
	movea.l	a3,a5
	jsr	([malloc2Table,d3.w*4])	;�u���b�N�̊m��
	bmi	dosMalloc2Failed
dosMalloc2Done:
	move.l	a1,d0
dosMalloc2End:
	bsr	dosAreaUnlock
  debug '|malloc2 out (ptr)=',1,d0
	tst.l	d0
	rts

;�ő�T�C�Y�̎擾
dosMalloc2GetSize:
	movea.l	a2,a4			;�ő�̃T�C�Y�͗D��͈͂ɐ��������ɋ��߂�
	movea.l	a3,a5
	bsr	getSize
	move.l	d1,d0			;��x�Ɋm�ۂł���ő�̃T�C�Y
dosMalloc2Failed:
	lsl.l	#1,d0
	beq	dosMalloc2Never		;�܂������m�ۂł��Ȃ�
	lsr.l	#1,d0
	cmp.l	#$00FFFFF0,d0
	bls	@f
	move.l	#$00FFFFF0,d0		;$00FFFFFF�͕s��(����1�x$00FFFFFF�ŌĂ΂�Ă��܂�����)
@@:	or.l	#$81000000,d0
	bra	dosMalloc2End

dosMalloc2Never:
	move.l	#$82000000,d0		;�܂������m�ۂł��Ȃ�
	bra	dosMalloc2End

dosMalloc2ParamError:
	moveq.l	#$FFFFFFF2,d0		;�p�����[�^������
	bra	dosMalloc2End

;----------------------------------------------------------------
;_MALLOC4	�u���b�N�̊m��(���[�h�w�肠��)
;<(a6).w:bit15=�v���Z�X�w��t���O(0=���s���̃v���Z�X,1=d4.l��e�v���Z�X�Ƃ��Ďg�p����)
;	����8bit=���[�h(0=���ʂ���,1=�K�v�ŏ��u���b�N����,2=��ʂ���,3=�ő�u���b�N����)
;<(2,a6).l:�m�ۂ���T�C�Y
;<(6,a6).l:((a6).w��bit15��1�̂Ƃ�)�e�v���Z�X�̃������Ǘ��e�[�u��
;>d0.l:�m�ۂ����u���b�N�̃��[�U�̈�̐擪
;	$FFFFFFF2=�p�����[�^������
;	$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;*d0,?d2-d5/a0-a5
dosMalloc4::
  debug '|malloc4 in (mode,size,proc)=',3,(-2,a6),(2,a6),(6,a6)
	bsr	dosAreaLockMalloc
	bmi	dosMalloc4Never
;<a2.l:(�����)��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a3.l:(�����)��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
dosMalloc4SMalloc::
	move.l	(2,a6),d2		;�m�ۂ���T�C�Y
;<d2.l:�m�ۂ���T�C�Y
	move.w	(a6),d3			;���[�h
	bpl	@f
	move.l	(6,a6),d4		;�e�v���Z�X�̃������Ǘ��e�[�u��
	and.w	#$7FFF,d3
@@:	cmp.w	#4,d3
	bcc	dosMalloc4ParamError
;�u���b�N���m�ۂ���
	bsr	getProc
;<d4.l:���s���̃v���Z�X�̃������Ǘ��e�[�u��
	jsr	([malloc2Table,d3.w*4])	;�u���b�N�̊m��
;<d0.l:0=����,$8xxxxxxx=�m�ۂł���ő�̃T�C�Y
;<a1.l:0=���s,0�ȊO=�m�ۂ����u���b�N�̃��[�U�̈�̐擪
	bpl	dosMalloc4Done
	movea.l	a2,a4
	movea.l	a3,a5
	jsr	([malloc2Table,d3.w*4])	;�u���b�N�̊m��
	bmi	dosMalloc4End
dosMalloc4Done:
	move.l	a1,d0
dosMalloc4End:
	bsr	dosAreaUnlock
  debug '|malloc4 out (ptr)=',1,d0
	tst.l	d0
	rts

dosMalloc4Never:
	move.l	#$80000000,d0		;�܂������m�ۂł��Ȃ�
	bra	dosMalloc4End

dosMalloc4ParamError:
	moveq.l	#$FFFFFFF2,d0		;�p�����[�^������
	bra	dosMalloc4End

;----------------------------------------------------------------
;�A�N�Z�X�ł��Ȃ���������Ԃ𐧌�����
;	�����ȊO�̘A���������^�T�u�X���b�h�̂��ׂẴu���b�N�����b�N����
;	_EXEC�̏ꍇ�̓v���O�����̃��[�h�͈͂̐������󂯂�
;	_EXEC�ȊO�ł̓A���P�[�g�͈͂̐������󂯂�
;	�����͗D�悵�Ċm�ۂ���͈͂ɐ�������O�͈̔͂Ȃ̂ŗD�悷��͈͂��܂�
;<d5.b:���[�h
;	0	���ʂ̂�
;	1	��ʂ̂�
;	2	�e�Ɠ������̂�
;	3	�e�Ɣ��Α��̂�
;	4	�����Ȃ�,���ʗD��
;	5	�����Ȃ�,��ʗD��
;	6	�����Ȃ�,�e�Ɠ������D��
;	7	�����Ȃ�,�e�Ɣ��Α��D��
;	8	�����Ȃ�,�D��Ȃ�
;>d0.l:0=����,-1=���s
;>a2.l:(�����)��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;>a3.l:(�����)��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;>a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;>a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
;*d0/a2-a5,?a0-a1
dosAreaLockMalloc::
	cmpi.b	#_EXEC-$FF00,$1C0A.w	;���x��0�œ�����DOS�R�[���ԍ�
	bne	dosAreaLockNotExec
;_EXEC�̂Ƃ�
	moveq.l	#1,d5			;loadhigh�̂Ƃ��͏�ʂ̂�
	tst.b	execLoadHigh
	bne	dosAreaLock
	move.b	defaultLoadArea,d5
	bra	dosAreaLock

;_EXEC�ȊO�̂Ƃ�
dosAreaLockNotExec:
	movea.l	([$1C28.w]),a0		;�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
	move.b	(pAllocArea,a0),d5
;<d5.b:���[�h
;	0	���ʂ̂�
;	1	��ʂ̂�
;	2	�e�Ɠ������̂�
;	3	�e�Ɣ��Α��̂�
;	4	�����Ȃ�,���ʗD��
;	5	�����Ȃ�,��ʗD��
;	6	�����Ȃ�,�e�Ɠ������D��
;	7	�����Ȃ�,�e�Ɣ��Α��D��
;	8	�����Ȃ�,�D��Ȃ�
dosAreaLock::
  debugByte '|dosAreaLock in (mode)=',1,d5
	movea.l	$1C54.w,a0		;���݂̃X���b�h�̃X���b�h�Ǘ��e�[�u��
	bsr	lockBlocks		;�����ȊO�̃T�u�X���b�h�̃u���b�N�����b�N����
	movea.l	$1C04.w,a4		;��������Ԃ̐擪
	movea.l	$1C00.w,a5		;��������Ԃ̖���+1
	movea.l	a4,a2			;�D�悷��͈͂ɐ�������O�̃�������Ԃ̐擪
	movea.l	a5,a3			;�D�悷��͈͂ɐ�������O�̃�������Ԃ̖���+1
	move.b	d5,d0
	beq	dosAreaLockLowerOnly	;0=���ʂ̂�
	subq.b	#2,d0
	bcs	dosAreaLockUpperOnly	;1=��ʂ̂�
	beq	dosAreaLockProcOnly	;2=�e�Ɠ������̂�
	subq.b	#2,d0
	bcs	dosAreaLockNotProcOnly	;3=�e�Ɣ��Α��̂�
	beq	dosAreaLockLower	;4=�����Ȃ�,���ʗD��
	subq.b	#2,d0
	bcs	dosAreaLockUpper	;5=�����Ȃ�,��ʗD��
	beq	dosAreaLockProc		;6=�����Ȃ�,�e�Ɠ������D��
	subq.b	#2,d0
	bcs	dosAreaLockNotProc	;7=�����Ȃ�,�e�Ɣ��Α��D��
					;8=�����Ȃ�,�D��Ȃ�
dosAreaLockEnd:
	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

dosAreaLockFailed:
	moveq.l	#-1,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;�e�Ɣ��Α��̂�
dosAreaLockNotProcOnly:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockUpperOnly
;���ʂ̂�
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockLowerOnly:
;��ʂ̕�����؂�̂Ă�
	move.l	himemAreaStart,d0	;���ʃ������̏��
	beq	@f			;��ʂ��Ȃ�
	cmpa.l	d0,a5
	bls	@f			;���ɉ��ʂ����ɐ�������Ă���
	cmpa.l	d0,a4
	bhs	dosAreaLockFailed	;��ʂ����ɐ�������Ă���
	movea.l	d0,a5			;����+1�𐧌�����
	movea.l	a5,a3			;��������������
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;�e�Ɠ������̂�
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockProcOnly:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockLowerOnly
;��ʂ̂�
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockUpperOnly:
;���ʂ̕�����؂�̂Ă�,���ʂ����Ȃ��Ƃ��͏����𖳎�����
	move.l	himemAreaStart,d0	;��ʃ������̉���
	beq	@f			;���ʂ����Ȃ��̂ŏ����𖳎�����
	cmpa.l	d0,a4
	bhs	@f			;���ɏ�ʂ����ɐ�������Ă���
	cmpa.l	d0,a5
	bls	dosAreaLockFailed	;���ʂ����ɐ�������Ă���
	movea.l	d0,a4			;�擪�𐧌�����
	movea.l	a4,a2			;��������������
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;�����Ȃ�,�e�Ɣ��Α��D��
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockNotProc:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockUpper
;�����Ȃ�,���ʗD��
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockLower:
;��ʂƉ��ʂ̋��ڂ��ׂ��ł���Ƃ�������������
	move.l	himemAreaStart,d0	;���ʃ������̏��
	beq	@f			;���ʂ����Ȃ�
	cmpa.l	d0,a5
	bls	@f			;���ɉ��ʂ����ɐ�������Ă���
	cmpa.l	d0,a4
	bhs	@f			;��ʂ����ɐ�������Ă���
	movea.l	d0,a5			;����+1�𐧌�����
					;�����͐������Ȃ�
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;�����Ȃ�,�e�Ɠ������D��
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockProc:
	cmpi.l	#$01000000,([$1C28.w])
	blo	dosAreaLockLower
;�����Ȃ�,��ʗD��
;<a0.l:�e�v���Z�X�̃v���Z�X�Ǘ��e�[�u��
dosAreaLockUpper:
;��ʂƉ��ʂ̋��ڂ��ׂ��ł���Ƃ�������������
	move.l	himemAreaStart,d0	;��ʃ������̉���
	beq	@f			;���ʂ����Ȃ��̂Ő����ł��Ȃ�
	cmpa.l	d0,a4
	bhs	@f			;���ɏ�ʂ����ɐ�������Ă���
	cmpa.l	d0,a5
	bls	@f			;���ʂ����Ȃ��̂Ő����ł��Ȃ�
	movea.l	d0,a4			;�擪�𐧌�����
					;�����͐������Ȃ�
@@:	moveq.l	#0,d0
  debug '|dosAreaLock out (d0,top,btm,top2,btm2)=',5,d0,a4,a5,a2,a3
	rts

;----------------------------------------------------------------
;�A�N�Z�X�ł��郁������Ԃ̐�������������
;	�u���b�N�̃��b�N����������
;<a4.l:��������Ԃ̐擪(�擪�̃u���b�N�̃w�b�_)
;<a5.l:��������Ԃ̖���+1(16�o�C�g�A���C�������g)
dosAreaUnlock::
	bsr	unlockBlocks
	rts

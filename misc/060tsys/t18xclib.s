;----------------------------------------------------------------
;
;	XC�̃��C�u�����̃n�C�������΍�
;
;----------------------------------------------------------------

	.include	t01dos.equ
	.include	t02const.equ

	.cpu	68060

;�u$00FFFFFE�v���u$3FFFFFFE�v
;�u$00FFFFFF�v���u$3FFFFFFF�v
;�umove.b #$FE,�`�v���uori.b #$C0,�`�v
;�ucmpi.b #$FE,�`;beq �`�v���ucmpi.b #$C0,�`;bcc �`�v
;�ucmpi.b #$FE,�`;bne �`�v���ucmpi.b #$C0,�`;bcs �`�v

MARKER	equ	.notb.(LOGICAL_MASK>>24)	;$C0

;----------------------------------------------------------------
;���[�h�����v���O������XC�̃��C�u�������g�p���Ă�����p�b�`�����Ă�
;	�L���b�V�����l�����Ă��Ȃ��̂ŁA��Ńv�b�V���Ɩ��������s������
;<a0.l:�������Ǘ��|�C���^
;<a1.l:����+1
;<a4.l:���s�J�n�A�h���X
patchXclib::
	movem.l	d0-d3/a2-a3,-(sp)
;���s�J�n�ʒu�̎�O128�o�C�g�ȓ���'XC���߲�'�̕����񂪂��邩
	lea.l	(-128,a4),a3
	moveq.l	#'X',d1
	moveq.l	#128-1,d2
@@:	cmp.b	(a3)+,d1
	dbeq	d2,@b
	bne	patchXclibEnd		;XC�̃��C�u�����ł͂Ȃ�����
	cmpi.w	#'C�',(a3)		;��A�h���X�̉\��������
	bne	@b
	cmpi.l	#'��߲',(2,a3)		;��A�h���X�̉\��������
	bne	@b
	cmpi.b	#'�',(6,a3)
	bne	@b
;���s�J�n�ʒu�̒��ォ��512�o�C�g�ȓ���_SETBLOCK�܂ł�5��$00FFFFFE��$3FFFFFFE�ɕύX
	movea.l	a4,a3
	move.w	#512/2-1,d2
1:	cmp.w	#_SETBLOCK,(a3)
	beq	3f
	cmpi.l	#$00FFFFFE,(a3)
	bne	2f
	move.b	#LOGICAL_MASK>>24,(a3)	;$00FFFFFE��$3FFFFFFE
2:	addq.l	#2,a3
	dbra	d2,1b
3:
;MALLOCP�̈ʒu���m�F����
;<a3.l:_SETBLOCK�̈ʒu
	lea.l	(22,a3),a3
	cmpi.w	#$23C8,(a3)+		;move.l a0,MALLOCP
	bne	patchXclibEnd		;��������Ă���̂���
	move.l	(a3),d3			;MALLOCP
;malloc(),free(),realloc()���C������
;<d3.l:MALLOCP
;<a0.l:�������Ǘ��e�[�u��
	lea.l	(pProgram,a0),a3	;�v���O�����̐擪
	move.l	(pBssTop,a0),d2		;bss�̐擪
	sub.l	a3,d2			;�v���O�����̃o�C�g��
	lsr.l	#1,d2			;���[�h��
	subq.l	#1,d2
	swap.w	d2
6:	swap.w	d2
5:	cmp.l	(a3),d3			;MALLOCP����������
	bne	2f
	move.l	(-4,a3),d0
;
	cmp.w	#$2279,d0		;movea.l MALLOCP,a1
	bne	3f
;movea.l MALLOCP,a1
	cmpi.l	#$157C_00FE,(-38,a3)	;move.b #$FE,(4,a2)
	bne	4f
	cmpi.w	#$0004,(-34,a3)		;
	bne	4f
;move.b #$FE,(4,a2)
;.ds.w 15
;movea.l MALLOCP,a1
;XC1��realloc()��1�Ԗڂ̃p�b�`
	move.l	#$002A_0000+MARKER,(-38,a3)	;move��ori,$FE��MARKER
4:	cmpi.l	#$0C28_00FE,(-10,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(-6,a3)		;
	bne	4f
	cmpi.b	#$66,(-4,a3)		;bne
	bne	4f
;cmpi.b #$FE,(4,a0)
;bne.s
;movea.l MALLOCP,a1
;XC1,XC2��realloc()��2�Ԗڂ̃p�b�`
	move.b	#MARKER,(-7,a3)		;$FE��MARKER
	move.b	#$65,(-4,a3)		;bne��bcs
	bra	2f

4:
3:	cmp.w	#$23CA,d0		;move.l a2,MALLOCP
	bne	3f
;move.l a2,MALLOCP
	cmpi.l	#$0C28_00FE,(14,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(18,a3)		;
	bne	4f
	cmpi.b	#$66,(20,a3)		;bne
	bne	4f
;move.l a2,MALLOCP
;.ds.w 5
;cmpi.b #$FE,(4,a0)
;bne
;XC1��malloc()��2�Ԗڂ̃p�b�`
	move.b	#MARKER,(17,a3)		;$FE��MARKER
	move.b	#$65,(20,a3)		;bne��bcs
	bra	2f

4:	cmpi.l	#$0C28_00FE,(12,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(16,a3)		;
	bne	4f
	cmpi.b	#$67,(18,a3)		;beq
	bne	4f
;move.l a2,MALLOCP
;.ds.w 4
;cmpi.b #$FE,(4,a0)
;beq
;XC1,XC2��realloc()��3�Ԗڂ̃p�b�`
	move.b	#MARKER,(15,a3)		;$FE��MARKER
	move.b	#$64,(18,a3)		;beq��bcc
4:	cmpi.l	#$C2BC_00FF,(50,a3)	;and.l #$00FFFFFF,d1
	bne	2f
	cmpi.w	#$FFFF,(54,a3)		;
	bne	2f
;move.l a2,MALLOCP
;.ds.w 23
;and.l #$00FFFFFF,d1
;XC1,XC2��realloc()��4�Ԗڂ̃p�b�`
	move.b	#LOGICAL_MASK>>24,(52,a3)	;$00FFFFFF��$3FFFFFFF�ɕύX
	bra	2f

3:	cmp.l	#$23EA_0000,d0		;move.l (0.w,a2),MALLOCP
	bne	3f
;move.l (0.w,a2),MALLOCP
	cmpi.l	#$0C28_00FE,(14,a3)	;cmpi.b #$FE,(4,a0)
	bne	4f
	cmpi.w	#$0004,(18,a3)		;
	bne	4f
	cmpi.b	#$66,(20,a3)		;bne
	bne	4f
;move.l (0.w,a2),MALLOCP
;.ds.w 5
;cmpi.b #$FE,(4,a0)
;bne
;XC2��malloc()��2�Ԗڂ̃p�b�`
	move.b	#MARKER,(17,a3)		;$FE��MARKER
	move.b	#$65,(20,a3)		;bne��bcs
	bra	2f
4:
3:	cmp.w	#$2479,d0		;movea.l MALLOCP,a2
	bne	3f
;movea.l MALLOCP,a2
	cmpi.l	#$0C2A_00FE,(4,a3)	;cmpi.b #$FE,(4,a2)
	bne	4f
	cmpi.w	#$0004,(8,a3)		;
	bne	4f
	cmpi.b	#$67,(10,a3)		;beq
	bne	4f
;movea.l MALLOCP,a2
;cmpi.b #$FE,(4,a2)
;beq
;XC1,XC2��malloc()��1�Ԗڂ̃p�b�`
	move.b	#MARKER,(7,a3)		;$FE��MARKER
	move.b	#$64,(10,a3)		;beq��bcc
	bra	2f
4:
3:	cmp.w	#$2879,d0		;movea.l MALLOCP,a4
	bne	3f
;movea.l MALLOCP,a4
	cmpi.l	#$16BC_00FE,(-6,a3)	;move.b #$FE,(a3)
	bne	4f
;move.b #$FE,(a3)
;movea.l MALLOCP,a4
;XC2��realloc()��1�Ԗڂ̃p�b�`
	move.l	#$0013_0000+MARKER,(-6,a3)	;move��ori,$FE��MARKER
	bra	2f
4:
3:	cmp.w	#$43F9,d0		;lea.l MALLOCP,a1
	bne	3f
;lea.l MALLOCP,a1
	cmpi.l	#$157C_00FE,(-8,a3)	;move.b #$FE,(4,a2)
	bne	4f
	cmpi.w	#$0004,(-4,a3)		;
	bne	4f
;move.b #$FE,(4,a2)
;lea.l MALLOCP,a1
;XC1,XC2��free()�̃p�b�`
	move.l	#$002A_0000+MARKER,(-8,a3)	;move��or,$FE��MARKER
	bra	2f
4:
3:
2:	addq.l	#2,a3
	dbra	d2,5b
	swap.w	d2
	dbra	d2,6b
patchXclibEnd:
	movem.l	(sp)+,d0-d3/a2-a3
	rts

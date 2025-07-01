;----------------------------------------------------------------
;
;	ADPCM��DMA�]����IOCS�R�[��
;
;----------------------------------------------------------------

	.include	t02const.equ
	.include	t08debug.equ

;__DEBUG__	equ	1

	.cpu	68060

;----------------------------------------------------------------
;
;	ADPCM�֌W��IOCS�R�[��
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _ADPCMOUT
;$60 ADPCM�Đ�
;<d1.w:�T���v�����O���g���Əo�̓��[�h
;	bit0�`bit1	�o�̓��[�h
;				0	�J�b�g
;				1	��
;				2	�E
;				3	���E
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
;<d2.l:�Đ�����f�[�^�̃o�C�g��
;<a1.l:�o�b�t�@�A�h���X
	.align	4,$2048
iocsAdpcmout::
	movem.l	d0-d1/d3/a0-a1/a3,-(sp)
;����I����҂�
@@:	tst.b	$0C32.w
	bne	@b
	bsr	adpcmStartWait
	tst.l	d2
	beq	iocsAdpcmoutEnd		;�T�C�Y��0
	move.b	#$02,$0C32.w
;1�Ԗڂ̃f�[�^��p�ӂ���
	move.l	a1,adpcmDataPtr
	move.l	d2,adpcmLeftSize
	move.l	d2,d0
	bsr	dataTransfer0
;OCR
;	DIR	0	MAR��DAR
;	BTD	0	DONE�Ȃ�
;	SIZE	11	�p�b�N�Ȃ�,8bit
;	CHAIN	00	�`�F�C���Ȃ�
;	REQG	10	�O���v��
;		 DIR BTD SIZE CHAIN REQG
	move.b	#%0___0___11____00___10,OCR3
	st.b	CSR3
	move.l	a3,MAR3
	move.w	d3,MTC3
;	d1.w		�T���v�����O���g��	�����U���g��	���[�g
;	$00xx		3.9KHz			4MHz		0
;	$01xx		5.2KHz			4MHz		1
;	$02xx		7.8KHz			8MHz		0
;	$03xx		10.4KHz			8MHz		1
;	$04xx		15.6KHz			8MHz		2
	move.b	$09DA.w,d0
	tas.b	d0			;4MHz
	cmp.w	#$0200,d1
	blo	@f
	sub.w	#$0200,d1
	and.b	#$7F,d0			;8MHz
@@:	move.b	d0,$09DA.w
	bsr	fmBusyWait
	move.b	#$1B,$00E90001		;FM�����A�h���X�|�[�g
	bsr	fmBusyWait
	move.b	d0,$00E90003		;FM�����f�[�^�|�[�g
;PAN(0��3,1��1,2��2,3��0)
				;BA98|76543210 BA98|76543210 BA98|76543210 BA98|76543210
				;           __            __            __            __
				;..rr|......00 ..rr|......01 ..rr|......10 ..rr|......11
	ror.b	#2,d1		;..rr|00...... ..rr|01...... ..rr|10...... ..rr|11......
	not.b	d1		;..rr|11...... ..rr|10...... ..rr|01...... ..rr|00......
	rol.b	#1,d1		;..rr|1......1 ..rr|0......1 ..rr|1......0 ..rr|0......0
	lsl.w	#1,d1		;.rr1|......10 .rr0|......10 .rr1|......00 .rr0|......00
	ror.b	#2,d1		;.rr1|10...... .rr0|10...... .rr1|00...... .rr0|00......
	lsl.w	#1,d1		;rr11|0......0 rr01|0......0 rr10|0......0 rr00|0......0
				;  ~~            ~~            ~~            ~~
	move.b	$00E9A005,d1	;rr11|7654.... rr01|7654.... rr10|7654.... rr00|7654....
	lsr.w	#4,d1		;....|rr117654 ....|rr017654 ....|rr107654 ....|rr007654
	rol.b	#4,d1		;....|7654rr11 ....|7654rr01 ....|7654rr10 ....|7654rr00
				;           ~~            ~~            ~~            ~~
;�]���J�n
	move.w	sr,-(sp)
	ori.w	#$0700,sr
	tst.l	adpcmLeftSize
	bne	1f
;�p�����Ȃ��Ƃ�
	move.l	#dmac3LastInterrupt,DMAC3NIV.w	;�]���I�����荞�ݐݒ�
;		 STR CNT HLT SAB INT
	move.b	#%1___0___0___0___1_000,CCR3	;�]���J�n,�p���Ȃ�,���荞�ݔ���
;�Đ��J�n
	move.b	d1,$00E9A005	;....|7654rr11 ....|7654rr01 ....|7654rr10 ....|7654rr00
	move.b	#$02,$00E92001
  .rept 8
	nop
  .endm
	bra	iocsAdpcmoutStarted

1:
;�p������Ƃ�
	move.l	#dmac3NormalInterrupt0,DMAC3NIV.w	;�]���I�����荞�ݐݒ�
;		 STR CNT HLT SAB INT
	move.b	#%1___1___0___0___1_000,CCR3	;�]���J�n,�p���Ȃ�,���荞�ݔ���
;�Đ��J�n
	move.b	d1,$00E9A005	;....|7654rr11 ....|7654rr01 ....|7654rr10 ....|7654rr00
	move.b	#$02,$00E92001
  .rept 8
	nop
  .endm
;2�Ԗڂ̃f�[�^��p�ӂ���
	move.l	adpcmLeftSize,d0
;	beq	iocsAdpcmoutEnd
	bsr	dataTransfer1
	move.l	a3,BAR3
	move.w	d3,BTC3
iocsAdpcmoutStarted:
	move.w	(sp)+,sr
iocsAdpcmoutEnd:
	movem.l	(sp)+,d0-d1/d3/a0-a1/a3
	rts

;----------------------------------------------------------------
;IOCS _ADPCMINP
;$61 ADPCM�^��
;<d1.w:�T���v�����O���g��
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
;<d2.l:�^������f�[�^�̃o�C�g��
;<a1.l:�o�b�t�@�A�h���X
	.align	4,$2048
iocsAdpcminp::
	move.l	vectorOldIocsAdpcminp,-(sp)
	rts

;	move.b	#$04,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMAOT
;$62 �A���C�`�F�[���ɂ��ADPCM�Đ�
;<d1.w:�T���v�����O���g���Əo�̓��[�h
;	bit0�`bit1	�o�̓��[�h
;				0	�J�b�g
;				1	��
;				2	�E
;				3	���E
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
;<d2.l:�A���C�`�F�[���e�[�u���̌�
;<a1.l:�A���C�`�F�[���e�[�u���̐擪�A�h���X
;	0000	.l	�擪�A�h���X
;	0004	.w	����
;	0006		���̃e�[�u��
;	 �F		�F
	.align	4,$2048
iocsAdpcmaot::
	move.l	vectorOldIocsAdpcmaot,-(sp)
	rts

;	move.b	#$12,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMAIN
;$63 �A���C�`�F�[���ɂ��ADPCM�^��
;<d1.w:�T���v�����O���g��
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
;<d2.l:�A���C�`�F�[���e�[�u���̌�
;<a1.l:�A���C�`�F�[���e�[�u���̐擪�A�h���X
;	0000	.l	�擪�A�h���X
;	0004	.w	����
;	0006		���̃e�[�u��
;	 �F		�F
	.align	4,$2048
iocsAdpcmain::
	move.l	vectorOldIocsAdpcmain,-(sp)
	rts

;	move.b	#$14,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMLOT
;$64 �����N�A���C�`�F�[���ɂ��ADPCM�Đ�
;<d1.w:�T���v�����O���g���Əo�̓��[�h
;	bit0�`bit1	�o�̓��[�h
;				0	�J�b�g
;				1	��
;				2	�E
;				3	���E
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
;<a1.l:�����N�A���C�`�F�[���e�[�u���̐擪�A�h���X
;	0000	.l	�擪�A�h���X
;	0004	.w	����
;	0006	.l	���̃e�[�u���A�h���X(0=�I���)
	.align	4,$2048
iocsAdpcmlot::
	move.l	vectorOldIocsAdpcmlot,-(sp)
	rts

;	move.b	#$22,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMLIN
;$65 �����N�A���C�`�F�[���ɂ��ADPCM�^��
;<d1.w:�T���v�����O���g��
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
;<a1.l:�����N�A���C�`�F�[���e�[�u���̐擪�A�h���X
;	0000	.l	�擪�A�h���X
;	0004	.w	����
;	0006	.l	���̃e�[�u���A�h���X(0=�I���)
	.align	4,$2048
iocsAdpcmlin::
	move.l	vectorOldIocsAdpcmlin,-(sp)
	rts

;	move.b	#$24,$0C32.w

;----------------------------------------------------------------
;IOCS _ADPCMSNS
;$66 ADPCM�̎��s���[�h�Z���X
;>d0.l:ADPCM�̎��s���[�h
;	$00	�������Ă��Ȃ�
;	$02	�o�͒�(_ADPCMOUT���s��)
;	$04	���͒�(_ADPCMINP���s��)
;	$12	�A���C�`�F�[���ɂ��o�͒�(_ADPCMAOT���s��)
;	$14	�A���C�`�F�[���ɂ����͒�(_ADPCMAIN���s��)
;	$22	�����N�A���C�`�F�[���ɂ��o�͒�(_ADPCMLOT���s��)
;	$24	�����N�A���C�`�F�[���ɂ����͒�(_ADPCMLIN���s��)
	.align	4,$2048
iocsAdpcmsns::
	moveq.l	#$7F,d0
	and.b	$0C32.w,d0
	rts

;----------------------------------------------------------------
;IOCS _ADPCMMOD
;$67 ADPCM�̎��s����
;<d1.b:���[�h
;	0	�I��
;	1	���~
;	2	�ĊJ
;>d0.l:�G���[�R�[�h
;	0	����I��
;	-1	�p�����[�^����������
	.align	4,$2048
iocsAdpcmmod::
	move.l	vectorOldIocsAdpcmmod,-(sp)
	rts

;----------------------------------------------------------------
;DMAC3�̏�����
	.align	4,$2048
dmac3Initialize::
;DCR3
;	XRM	10	�z�[���h�Ȃ�,�T�C�N���X�`�[��
;	DTYP	00	68000�o�X�^�C�v
;	DPS	0	8�ƃ|�[�g
;	PCL	00	�X�e�[�^�X����
;		 XRM DTYP DPS   PCL
	move.b	#%10__00___0__0_00,DCR3
;SCR
;	MAC	01	�C���N�������g
;	DAC	00	���̂܂�
;		      MAC DAC
	move.b	#%0000_01_00,SCR3
;MFC
;	FC	101	�X�[�p�[�o�C�U�f�[�^
	move.b	#%00000_101,MFC3
;CPR
;	CP	01	2�Ԗڂɍ����D��x
	move.b	#%000000_01,CPR3
;DFC
;	FC	101	�X�[�p�[�o�C�U�f�[�^
	move.b	#%00000_101,DFC3
;BFC
;	FC	101	�X�[�p�[�o�C�U�f�[�^
	move.b	#%00000_101,BFC3
	move.b	#DMAC3NIV/4,NIV3
	move.b	#DMAC3EIV/4,EIV3
	move.l	#$00E92003,DAR3
	move.l	#dmac3ErrorInterrupt,DMAC3EIV.w
	rts

;----------------------------------------------------------------
;�o�b�t�@0�̓]���I�����荞��
;�o�b�t�@1�̓]�����J�n����Ă���̂�,���̃f�[�^���o�b�t�@0�ɗp�ӂ��Čp����,
;�o�b�t�@1�̓]���I����҂�
	.align	4,$2048
dmac3NormalInterrupt0:
	ori.w	#$0700,sr
	movem.l	d0/d3/a0-a1/a3,-(sp)
	move.l	adpcmLeftSize,d0
	beq	dmac3InterruptDone
	bsr	dataTransfer0
	lea.l	(dmac3NormalInterrupt1,pc),a0
	bra	dmac3InterruptContinue

;�o�b�t�@1�̓]���I�����荞��
;�o�b�t�@0�̓]�����J�n����Ă���̂�,���̃f�[�^���o�b�t�@1�ɗp�ӂ��Čp����,
;�o�b�t�@0�̓]���I����҂�
	.align	4,$2048
dmac3NormalInterrupt1:
	ori.w	#$0700,sr
	movem.l	d0/d3/a0-a1/a3,-(sp)
	move.l	adpcmLeftSize,d0
	beq	dmac3InterruptDone
	bsr	dataTransfer1
	lea.l	(dmac3NormalInterrupt0,pc),a0
dmac3InterruptContinue:
	tst.b	CSR3
	st.b	CSR3
	move.l	a0,DMAC3NIV.w
	move.l	a3,BAR3
	move.w	d3,BTC3
;		 STR CNT HLT SAB INT
	move.b	#%0___1___0___0___1_000,CCR3	;�]���p��,���荞�ݔ���
  .rept 8
	nop
  .endm
  debug '(adpcmLeftSize,adpcmDataPtr,a3,d3)=',4,adpcmLeftSize,adpcmDataPtr,a3,d3
	movem.l	(sp)+,d0/d3/a0-a1/a3
	rte

;�Ō�̓]�����J�n����Ă���̂�,����̊��荞�݂ŏI������
dmac3InterruptDone:
	move.l	#dmac3LastInterrupt,DMAC3NIV.w
	movem.l	(sp)+,d0/d3/a0-a1/a3
	rte

;----------------------------------------------------------------
;DMAC3�G���[���荞��
;ADPCM���~���Ă���]���𒆎~����
	.align	4,$2048
dmac3LastInterrupt:
dmac3ErrorInterrupt:
	move.b	CER3,$0C33.w		;DMAC3�G���[�R�[�h
	move.b	#$01,$00E9A007		;ADPCM�����~
	move.b	#$03,$00E9A007
	move.b	#$01,$00E92001
	tst.b	CSR3			;DMAC3�����~
	st.b	CSR3
	clr.b	$0C32.w			;IOCS�R�[���ɂ��]���I��
	rte

;----------------------------------------------------------------
;�o�b�t�@0�̃f�[�^��p�ӂ���
;<d0.l:�c��T�C�Y(adpcmLeftSize,0�ȊO)
;>d3.w:DMAC3�̓]���T�C�Y
;>a3.l:DMAC3�̓]���A�h���X
;*d3/a3
;?d0/a0-a1
	.align	4,$2048
dataTransfer0:
	movea.l	adpcmBufferPtr0,a0	;16�̔{��
	bra	dataTransfer

;�o�b�t�@1�̃f�[�^��p�ӂ���
;<d0.l:�c��T�C�Y(adpcmLeftSize,0�ȊO)
;>d3.w:DMAC3�̓]���T�C�Y
;>a3.l:DMAC3�̓]���A�h���X
;*d3/a3
;?d0/a0-a1
	.align	4,$2048
dataTransfer1:
	movea.l	adpcmBufferPtr1,a0	;16�̔{��
dataTransfer:
  debug 'dataTransfer in(adpcmLeftSize,adpcmDataPtr)=',2,adpcmLeftSize,adpcmDataPtr
	cmp.l	adpcmBufferSize,d0
	bls	@f
	move.l	adpcmBufferSize,d0
@@:	sub.l	d0,adpcmLeftSize
	move.l	a0,a3
	move.w	d0,d3
	movea.l	adpcmDataPtr,a1
	move.l	a1,d0
	ror.l	#4,d0			;d0.l�̏��4bit��a1�̉���4bit
	move.w	d3,d0			;d0.l�̉��ʃ��[�h��DMAC3�̓]���T�C�Y
					;1:�œ]���T�C�Y���K�v�Ȃ̂ł킴�ƍ�������

	btst.b	#2,$0C32.w
	beq	@f
	exg.l	a0,a1			;���͂̎��͋t�����ɓ]������
@@:

	cmp.l	#$10000000,d0
	bcc	8f			;�擪��16�̔{���łȂ�
	cmpi.b	#4,$0CBC.W
	blo	8f

	sub.w	#16,d0
	bcs	1f			;�T�C�Y��16����
@@:	move16	(a1)+,(a0)+
	sub.w	#16,d0
	bcc	@b
1:	add.w	#16,d0
	beq	9f			;�T�C�Y��16�̔{��������

8:

	subq.w	#4,d0
	bcs	2f			;�T�C�Y��4����
@@:	move.l	(a1)+,(a0)+
	subq.w	#4,d0
	bcc	@b
2:	addq.w	#4,d0
	beq	9f			;�T�C�Y��4�̔{��������

@@:	move.b	(a1)+,(a0)+
	subq.w	#1,d0
	bne	@b

9:	move.l	a1,adpcmDataPtr
  debug 'dataTransfer out(adpcmLeftSize,adpcmDataPtr,a3,d3)=',4,adpcmLeftSize,adpcmDataPtr,a3,d3
	rts

;----------------------------------------------------------------
;FM�����̃r�W�[�t���O���N���A�����܂ő҂�
;�T�u���[�`���ɂ��Ȃ��Ƒ�������\��������
	.align	4,$2048
fmBusyWait:
@@:	tst.b	$00E90003
	bmi	@b
	rts

;----------------------------------------------------------------
;ADPCM�̃T���v�����O���g���ɉ������E�F�C�g
;<d1.w:�T���v�����O���g��
;	bit8�`bit14	�T���v�����O���g��
;				0	3.9KHz
;				1	5.2KHz
;				2	7.8KHz
;				3	10.4KHz
;				4	15.6KHz
;	bit15		�E�F�C�g�t���O
;				0	�T���v�����O���g���ɉ����ăE�F�C�g������
;				1	�E�F�C�g�����Ȃ�
	.align	4,$2048
adpcmStartWait:
	tst.w	d1
	bmi	@f
	move.w	d1,-(sp)
	lsr.w	#8,d1
	and.w	#7,d1
	moveq.l	#0,d0
	move.b	(adpcmStartWaitTable,pc,d1.w),d0
	bsr	wait50Micro
	move.w	(sp)+,d1
@@:	and.w	#$7FFF,d1
	rts

adpcmStartWaitTable:
	.dc.b	$0A			;500��s 0(3.9KHz)
	.dc.b	$08			;400��s 1(5.2KHz)
	.dc.b	$05			;250��s 2(7.8KHz)
	.dc.b	$04			;200��s 3(10.4KHz)
	.dc.b	$03			;150��s 4(15.6KHz)
	.dc.b	$00,$00,$00

;----------------------------------------------------------------
;50��s�P�ʂ̃E�F�C�g
;<d0.l:�҂�����(50��s�P��)
	.align	4,$2048
wait50Micro:
	movem.l	d0-d2/a0,-(sp)
	lea.l	$00E88023,a0		;MFP TCDR
	moveq.l	#0,d1
	move.b	(a0),d1
	move.b	(a0),d1
1:	moveq.l	#0,d2
	move.b	(a0),d2
	cmp.b	(a0),d2
	bcs	1b
	sub.w	d2,d1
	bcc	2f
	add.w	#200,d1
2:	exg.l	d1,d2
	sub.l	d2,d0
	bhi	1b
	movem.l	(sp)+,d0-d2/a0
	rts

;----------------------------------------------------------------
;
;	DMA�]���֌W��IOCS�R�[��
;
;----------------------------------------------------------------
;----------------------------------------------------------------
;IOCS _DMAMOVE
;$8A DMA�]��
;<d1.b:���[�h
;	bit0�`bit1	a2�̃��[�h
;				0	�J�E���g���Ȃ�
;				1	�C���N�������g
;				2	�f�N�������g
;				3	�֎~
;	bit2�`bit3	a1�̃��[�h
;				0	�J�E���g���Ȃ�
;				1	�C���N�������g
;				2	�f�N�������g
;				3	�֎~
;	bit7		�]������
;				0	a1����a2��
;				1	a2����a1��
;<d2.l:�]���f�[�^�̃o�C�g��
;<a1.l:�]�����A�h���X
;<a2.l:�]����A�h���X
;?d0/d2/a1-a2
	.align	4,$2048
iocsDmamove::
	tst.l	d2
	beq	9f
	moveq.l	#$0F,d0
	and.b	d1,d0
	tst.b	d1
	bmi	@f
	jmp	([iocsDmamoveTable0,pc,d0.l*4])

@@:	exg.l	a1,a2
	jmp	([iocsDmamoveTable1,pc,d0.l*4])

9:	rts

;(a1),(a2)
	.align	4,$2048
iocsDmamoveTable0:
	.dc.l	iocsDmamove00	;(a1),(a2)
	.dc.l	iocsDmamove01	;(a1),(a2)+
	.dc.l	iocsDmamove02	;(a1),(a2)-
	.dc.l	iocsDmamove03
	.dc.l	iocsDmamove10	;(a1)+,(a2)
	.dc.l	iocsDmamove11	;(a1)+,(a2)+
	.dc.l	iocsDmamove12	;(a1)+,(a2)-
	.dc.l	iocsDmamove13
	.dc.l	iocsDmamove20	;(a1)-,(a2)
	.dc.l	iocsDmamove21	;(a1)-,(a2)+
	.dc.l	iocsDmamove22	;(a1)-,(a2)-
	.dc.l	iocsDmamove23
	.dc.l	iocsDmamove30
	.dc.l	iocsDmamove31
	.dc.l	iocsDmamove32
	.dc.l	iocsDmamove33

;(a2),(a1)
	.align	4,$2048
iocsDmamoveTable1:
	.dc.l	iocsDmamove00	;(a2),(a1)
	.dc.l	iocsDmamove10	;(a2)+,(a1)
	.dc.l	iocsDmamove20	;(a2)-,(a1)
	.dc.l	iocsDmamove30
	.dc.l	iocsDmamove01	;(a2),(a1)+
	.dc.l	iocsDmamove11	;(a2)+,(a1)+
	.dc.l	iocsDmamove21	;(a2)-,(a1)+
	.dc.l	iocsDmamove31
	.dc.l	iocsDmamove02	;(a2),(a1)-
	.dc.l	iocsDmamove12	;(a2)+,(a1)-
	.dc.l	iocsDmamove22	;(a2)-,(a1)-
	.dc.l	iocsDmamove32
	.dc.l	iocsDmamove03
	.dc.l	iocsDmamove13
	.dc.l	iocsDmamove23
	.dc.l	iocsDmamove33

	.align	4,$2048
iocsDmamove00:	;(a1),(a2)/(a2),(a1)
iocsDmamove03:
iocsDmamove30:
iocsDmamove33:
@@:	move.b	(a1),(a2)
	subq.l	#1,d2
	bne	@b
	rts

	.align	4,$2048
iocsDmamove01:	;(a1),(a2)+/(a2),(a1)+
iocsDmamove31:
@@:	move.b	(a1),(a2)+
	subq.l	#1,d2
	bne	@b
	rts

	.align	4,$2048
iocsDmamove02:	;(a1),(a2)-/(a2),(a1)-
iocsDmamove32:
	addq.l	#1,a2
@@:	move.b	(a1),-(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a2
	rts

	.align	4,$2048
iocsDmamove10:	;(a1)+,(a2)/(a2)+,(a1)
iocsDmamove13:
@@:	move.b	(a1)+,(a2)
	subq.l	#1,d2
	bne	@b
	rts

	.align	4,$2048
iocsDmamove11:	;(a1)+,(a2)+/(a2)+,(a1)+
;	tst.l	d2
;	beq	9f
	cmp.l	#$00000010,d2
	blo	iocsDmamove11notLine
	move.l	a1,d0
	move.l	a2,d1
	eor.l	d1,d0
	and.l	#$0000000F,d0
	bne	iocsDmamove11notLine
	cmpi.b	#4,$0CBC.W
	blo	iocsDmamove11notLine
;�擪�A�h���X�̉���4bit������
	and.l	#$0000000F,d1		;�擪�A�h���X�̉���4bit(a1��a2�ŋ���)
	beq	@f			;���C���̐擪
	move.l	d2,d0
	moveq.l	#16,d2
	sub.l	d1,d2			;���̃��C���̐擪�܂ł̃o�C�g��
					;���̒l��15�ȉ�,�]���o�C�g����16�ȏ�Ȃ̂�,
					;�]�v�ɓ]�����Ă��܂��S�z�͂Ȃ�
	sub.l	d2,d0			;�c��
	bsr	iocsDmamove11notLine
	move.l	d0,d2			;d2����
@@:	sub.l	#16,d2
	blo	2f
1:	move16	(a1)+,(a2)+
	sub.l	#16,d2
	bhi	1b
2:	add.l	#16,d2
	beq	9f
iocsDmamove11notLine:
	subq.l	#4,d2
	blo	2f
1:	move.l	(a1)+,(a2)+
	subq.l	#4,d2
	bhi	1b
2:	addq.l	#4,d2
	beq	9f
@@:	move.b	(a1)+,(a2)+
	subq.l	#1,d2
	bne	@b
9:	rts

	.align	4,$2048
iocsDmamove12:	;(a1)+,(a2)-/(a2)+,(a1)-
	addq.l	#1,a2
@@:	move.b	(a1)+,-(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a2
	rts

	.align	4,$2048
iocsDmamove20:	;(a1)-,(a2)/(a2)-,(a1)
iocsDmamove23:
	addq.l	#1,a1
@@:	move.b	-(a1),(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a1
	rts

	.align	4,$2048
iocsDmamove21:	;(a1)-,(a2)+/(a2)-,(a1)+
	addq.l	#1,a1
@@:	move.b	-(a1),(a2)+
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a1
	rts

	.align	4,$2048
iocsDmamove22:	;(a1)-,(a2)-/(a2)-,(a1)-
	addq.l	#1,a1
	addq.l	#1,a2
@@:	move.b	-(a1),-(a2)
	subq.l	#1,d2
	bne	@b
	subq.l	#1,a1
	subq.l	#1,a2
	rts

;----------------------------------------------------------------
;IOCS _DMAMOV_A
;$8B �A���C�`�F�[���ɂ��DMA�]��
;<d1.b:���[�h
;	bit0�`bit1	a2�̃��[�h
;				0	�J�E���g���Ȃ�
;				1	�C���N�������g
;				2	�f�N�������g
;				3	�֎~
;	bit2�`bit3	a1�̃��[�h
;				0	�J�E���g���Ȃ�
;				1	�C���N�������g
;				2	�f�N�������g
;				3	�֎~
;	bit7		�]������
;				0	a1����a2��
;				1	a2����a1��
;<d2.l:�A���C�`�F�[���e�[�u���̌�
;<a1.l:�]�����A���C�`�F�[���e�[�u���̐擪�A�h���X
;	0000	.l	�擪�A�h���X
;	0004	.w	����
;	0006		���̃e�[�u��
;	 �F		�F
;<a2.l:�]����A�h���X
	.align	4,$2048
iocsDmamovA::
	move.l	d3,-(sp)
	move.l	d2,d3
	beq	9f
	move.l	a4,-(sp)
	move.l	a3,-(sp)
	moveq.l	#$0F,d0
	and.b	d1,d0
	tst.b	d1
	bmi	3f
	movea.l	(iocsDmamoveTable0,pc,d0.l*4),a4
	movea.l	a1,a3
1:	movea.l	(a3)+,a1
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	subq.l	#1,d3
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
9:	move.l	(sp)+,d3
	rts

3:	movea.l	(iocsDmamoveTable1,pc,d0.l*4),a4
	movea.l	a1,a3
	movea.l	a2,a1
1:	movea.l	(a3)+,a2
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	subq.l	#1,d3
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
	move.l	(sp)+,d3
	rts

;----------------------------------------------------------------
;IOCS _DMAMOV_L
;$8C �����N�A���C�`�F�[���ɂ��DMA�]��
;<d1.b:���[�h
;	bit0�`bit1	a2�̃��[�h
;				0	�J�E���g���Ȃ�
;				1	�C���N�������g
;				2	�f�N�������g
;				3	�֎~
;	bit2�`bit3	a1�̃��[�h
;				0	�J�E���g���Ȃ�
;				1	�C���N�������g
;				2	�f�N�������g
;				3	�֎~
;	bit7		�]������
;				0	a1����a2��
;				1	a2����a1��
;<a1.l:�]���������N�A���C�`�F�[���e�[�u���̐擪�A�h���X
;	0000	.l	�擪�A�h���X
;	0004	.w	����
;	0006	.l	���̃e�[�u���A�h���X(0=�I���)
;<a2.l:�]����A�h���X
	.align	4,$2048
iocsDmamovL::
	move.l	a4,-(sp)
	move.l	a3,-(sp)
	moveq.l	#$0F,d0
	and.b	d1,d0
	tst.b	d1
	bmi	3f
	movea.l	(iocsDmamoveTable0,pc,d0.l*4),a4
	move.l	a1,d0
1:	movea.l	d0,a3
	movea.l	(a3)+,a1
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	move.l	(a3)+,d0
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
	rts

3:	movea.l	(iocsDmamoveTable1,pc,d0.l*4),a4
	move.l	a1,d0
	movea.l	a2,a1
1:	movea.l	d0,a3
	movea.l	(a3)+,a2
	moveq.l	#0,d2
	move.w	(a3)+,d2
	beq	@f
	jsr	(a4)
@@:	move.l	(a3)+,d0
	bne	1b
2:	movea.l	(sp)+,a3
	movea.l	(sp)+,a4
	rts

;----------------------------------------------------------------
;IOCS _DMAMODE
;$8D DMA�]�������[�h�̎擾
;�p�����[�^�Ȃ�
;>d0.l:DMA�]�������[�h
;	0		�]�����ł͂Ȃ�
;	_DMAMOVE	_DMAMOVE�œ]����
;	_DMAMOV_A	_DMAMOV_A�œ]����
;	_DMAMOV_L	_DMAMOV_L�œ]����
	.align	4,$2048
iocsDmamode::
	moveq.l	#0,d0
	rts

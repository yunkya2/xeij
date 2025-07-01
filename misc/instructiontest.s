;========================================================================================
;  instructiontest.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac


	.cpu	68000


CRC32_REG	reg	d7


;--------------------------------------------------------------------------------
;constants

IM_BYTE		reg	0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)
IM_WORD		reg	0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)
IM_LONG		reg	0,.not.0,1<<0,.not.(1<<0),1<<1,.not.(1<<1),1<<2,.not.(1<<2),1<<4,.not.(1<<4),1<<6,.not.(1<<6),1<<7,.not.(1<<7),1<<8,.not.(1<<8),1<<9,.not.(1<<9),1<<10,.not.(1<<10),1<<12,.not.(1<<12),1<<14,.not.(1<<14),1<<15,.not.(1<<15),1<<16,.not.(1<<16),1<<17,.not.(1<<17),1<<18,.not.(1<<18),1<<20,.not.(1<<20),1<<22,.not.(1<<22),1<<23,.not.(1<<23),1<<24,.not.(1<<24),1<<25,.not.(1<<25),1<<26,.not.(1<<26),1<<28,.not.(1<<28),1<<30,.not.(1<<30),1<<31,.not.(1<<31)
IM_QUICK	reg	1,2,3,4,5,6,7,8
IM_3BIT		reg	0,1,2,3,4,5,6,7
IM_5BIT		reg	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_5BIT
IM_OFFSET	reg	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
IM_WIDTH	reg	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH

EASY		equ	0
HARD		equ	1

MC68000		equ	1
MC68010		equ	2
MC68020		equ	4
MC68030		equ	8
MC68040		equ	16
MC68060		equ	64

CCR_X		equ	%10000
CCR_N		equ	%01000
CCR_Z		equ	%00100
CCR_V		equ	%00010
CCR_C		equ	%00001


;--------------------------------------------------------------------------------
;macros

leastr	.macro	s0,an
	.data
@str:
	.dc.b	s0,0
	.text
	lea.l	@str,an
	.endm

peastr	.macro	s0,s1,s2,s3,s4,s5,s6,s7,s8,s9
	.data
@str:
	.dc.b	s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,0
	.text
	pea.l	@str
	.endm

print	.macro	s0,s1,s2,s3,s4,s5,s6,s7,s8,s9
	peastr	s0,s1,s2,s3,s4,s5,s6,s7,s8,s9
	jbsr	print_by_write
	addq.l	#4,sp
	.endm

putchar	.macro	c0
	move.w	c0,-(sp)
	jbsr	putchar_by_write
	addq.l	#2,sp
	.endm

SPC1	reg	' '
SPC2	reg	'  '
SPC3	reg	'   '
SPC4	reg	'    '
SPC5	reg	'     '
SPC6	reg	'      '
SPC7	reg	'       '
SPC8	reg	'        '
SPC9	reg	'         '
SPC10	reg	'          '
SPC11	reg	'           '
SPC12	reg	'            '
SPC13	reg	'             '
SPC14	reg	'              '
SPC15	reg	'               '
SPC16	reg	'                '
SPC17	reg	'                 '
SPC18	reg	'                  '
SPC19	reg	'                   '
SPC20	reg	'                    '
SPC21	reg	'                     '
SPC22	reg	'                      '
SPC23	reg	'                       '
SPC24	reg	'                        '
SPC25	reg	'                         '
SPC26	reg	'                          '
SPC27	reg	'                           '
SPC28	reg	'                            '
SPC29	reg	'                             '
SPC30	reg	'                              '
SPC31	reg	'                               '
SPC32	reg	'                                '
SPC33	reg	'                                 '
SPC34	reg	'                                  '
SPC35	reg	'                                   '
SPC36	reg	'                                    '
SPC37	reg	'                                     '
SPC38	reg	'                                      '
SPC39	reg	'                                       '
SPC40	reg	'                                        '

fillto	.macro	v,c,s0
~fillto = c-.sizeof.(s0)
  .if ~fillto<=0
v	reg	s0
  .else
v	reg	s0,SPC%~fillto
  .endif
	.endm


;--------------------------------------------------------------------------------
;illegal instruction

try_illegal_instruction	.macro
	move.l	#798f,abort_illegal_instruction
	.endm

catch_illegal_instruction	.macro
	tst.l	d0			;clear carry flag
798:
	jbsr	print_illegal_instruction
	.endm


;--------------------------------------------------------------------------------

TEST_LIMIT	equ	1000		;multiplies of 4
test_number = 0


;--------------------------------------------------------------------------------
;no operand

xxx_no_operand	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.w	d6,ccr
	op
	move.w	sr,d0
	jbsr	crc32_byte
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

trapcc_no_operand	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_full_data,a6	;TRAPcc
	move.w	(a6)+,d6
106:
	clr.b	trapv_instruction_flag
	move.w	d6,ccr
	op
	move.w	sr,d0
	or.b	trapv_instruction_flag,d0
	jbsr	crc32_byte
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_im?

xxx_imb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)	;IM_BYTE
	move.w	d6,ccr
	op	#im
	move.w	sr,d0
	jbsr	crc32_byte
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.w	d6,ccr
	op	#im
	move.w	sr,d0
	jbsr	crc32_byte
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

trapcc_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_full_data,a6	;TRAPcc.W #<data>
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	clr.b	trapv_instruction_flag
	move.w	d6,ccr
	op	#im
	move.w	sr,d0
	or.b	trapv_instruction_flag,d0
	jbsr	crc32_byte
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_iml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.not.0,1<<0,.not.(1<<0),1<<1,.not.(1<<1),1<<2,.not.(1<<2),1<<4,.not.(1<<4),1<<6,.not.(1<<6),1<<7,.not.(1<<7),1<<8,.not.(1<<8),1<<9,.not.(1<<9),1<<10,.not.(1<<10),1<<12,.not.(1<<12),1<<14,.not.(1<<14),1<<15,.not.(1<<15),1<<16,.not.(1<<16),1<<17,.not.(1<<17),1<<18,.not.(1<<18),1<<20,.not.(1<<20),1<<22,.not.(1<<22),1<<23,.not.(1<<23),1<<24,.not.(1<<24),1<<25,.not.(1<<25),1<<26,.not.(1<<26),1<<28,.not.(1<<28),1<<30,.not.(1<<30),1<<31,.not.(1<<31)	;IM_LONG
	move.w	d6,ccr
	op	#im
	move.w	sr,d0
	jbsr	crc32_byte
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

trapcc_iml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_full_data,a6	;TRAPcc.L #<data>
	move.w	(a6)+,d6
106:
  .irp im,0,.not.0,1<<0,.not.(1<<0),1<<1,.not.(1<<1),1<<2,.not.(1<<2),1<<4,.not.(1<<4),1<<6,.not.(1<<6),1<<7,.not.(1<<7),1<<8,.not.(1<<8),1<<9,.not.(1<<9),1<<10,.not.(1<<10),1<<12,.not.(1<<12),1<<14,.not.(1<<14),1<<15,.not.(1<<15),1<<16,.not.(1<<16),1<<17,.not.(1<<17),1<<18,.not.(1<<18),1<<20,.not.(1<<20),1<<22,.not.(1<<22),1<<23,.not.(1<<23),1<<24,.not.(1<<24),1<<25,.not.(1<<25),1<<26,.not.(1<<26),1<<28,.not.(1<<28),1<<30,.not.(1<<30),1<<31,.not.(1<<31)	;IM_LONG
	clr.b	trapv_instruction_flag
	move.w	d6,ccr
	op	#im
	move.w	sr,d0
	or.b	trapv_instruction_flag,d0
	jbsr	crc32_byte
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_dr?

xxx_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2			;Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;NBCD.B Dr
;	easy: don't test undefined N,V
nbcdeasy_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2			;Dr'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;NBCD.B Dr
;	hard: test undefined N,V
nbcdhard_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2			;Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

scc_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6	;Scc.B Dr
	move.w	(a6)+,d6
106:
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2			;Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2			;Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2			;Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_ar?

xxx_arw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Ar'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;Ar
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movea.l	d1,a2			;Ar'
	move.w	d6,ccr
	op	a2			;Ar'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a2,d0			;Ar'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Ar'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;Ar
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movea.l	d1,a2			;Ar'
	move.w	d6,ccr
	op	a2			;Ar'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a2,d0			;Ar'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mm?

xxx_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	(a0)			;(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;NBCD.B (Ar)
;	easy: don't test undefined N,V
nbcdeasy_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	(a0)			;(Ar)'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;NBCD.B (Ar)
;	hard: test undefined N,V
nbcdhard_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	(a0)			;(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

scc_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_full_data,a6	;Scc.B (Ar)
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	(a0)			;(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	(a0)			;(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	(a0)			;(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_dr?_dr?

xxx_drb_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;ABCD.B Dr,Dq
;SBCD.B Dr,Dq
;	easy: don't test undefined N,V
abcdsbcdeasy_drb_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;ABCD.B Dr,Dq
;SBCD.B Dr,Dq
;	hard: test undefined N,V
abcdsbcdhard_drb_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drb_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	word_medium_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drb_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_medium_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drw_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drw_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.W Dr,Dq
;DIVU.W Dr,Dq
;	easy: don't test undefined N,Z if V=1
diveasy_drw_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	bvc	@vc
	andi.b	#.notb.(CCR_N|CCR_Z),ccr	;easy: don't test undefined N,Z if V=1
@vc:
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.W Dr,Dq
;DIVU.W Dr,Dq
;	hard: test undefined N,Z if V=1
divhard_drw_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drl_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L Dr,Dq
;DIVU.L Dr,Dq
;	easy: don't test undefined N,Z if V=1
diveasy_drl_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	bvc	@vc
	andi.b	#.notb.(CCR_N|CCR_Z),ccr	;easy: don't test undefined N,Z if V=1
@vc:
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L Dr,Dq
;DIVU.L Dr,Dq
;	hard: test undefined N,Z if V=1
divhard_drl_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	d3,d4			;Dr',Dq'
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drl_drq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dh:Dl'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2/a3		;Dh:Dl
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dh'
	move.l	a3,d5			;Dl'
	move.w	d6,ccr
	op	d3,d4:d5		;Dr',Dh':Dl'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dh'
	jbsr	crc32_long
	move.l	d5,d0			;Dl'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2/a3		;Dh:Dl
	move.l	a3,d0
	or.l	d2,d0
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L Dr,Dh:Dl
;DIVSL.L Dr,Dh:Dl
;DIVU.L Dr,Dh:Dl
;DIVUL.L Dr,Dh:Dl
;	easy: don't test undefined N,Z if V=1
diveasy_drl_drq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dh:Dl'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2/a3		;Dh:Dl
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dh'
	move.l	a3,d5			;Dl'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	d3,d4:d5		;Dr',Dh':Dl'
	bvc	@vc
	andi.b	#.notb.(CCR_N|CCR_Z),ccr	;easy: don't test undefined N,Z if V=1
@vc:
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dh'
	jbsr	crc32_long
	move.l	d5,d0			;Dl'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2/a3		;Dh:Dl
	move.l	a3,d0
	or.l	d2,d0
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L Dr,Dh:Dl
;DIVSL.L Dr,Dh:Dl
;DIVU.L Dr,Dh:Dl
;DIVUL.L Dr,Dh:Dl
;	hard: test undefined N,Z if V=1
divhard_drl_drq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dh:Dl'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2/a3		;Dh:Dl
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dh'
	move.l	a3,d5			;Dl'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	d3,d4:d5		;Dr',Dh':Dl'
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dh'
	jbsr	crc32_long
	move.l	d5,d0			;Dl'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2/a3		;Dh:Dl
	move.l	a3,d0
	or.l	d2,d0
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_dr?_ar?

xxx_drw_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_medium_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	movea.l	d2,a4			;Aq'
	move.w	d6,ccr
	op	d3,a4			;Dr',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drl_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	movea.l	d2,a4			;Aq'
	move.w	d6,ccr
	op	d3,a4			;Dr',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_dr?_im?

xxx_drb_imb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)	;IM_BYTE
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2,#im			;Dr',#<data>
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_ar?_ar?

xxx_arl_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Ar,Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Ar
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movea.l	d1,a3			;Ar'
	movea.l	d2,a4			;Aq'
	move.w	d6,ccr
	op	a3,a4			;Ar',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a3,d0			;Ar'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mm?_dr?

xxx_mmb_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmw_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	byte_medium_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.B (Ar),Dn
;CMP2.B (An),Dn
;	easy: don't test undefined N,V
chk2cmp2easy_mmw_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	byte_medium_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.B (Ar),Dn
;CMP2.B (An),Dn
;	hard: test undefined N,V
chk2cmp2hard_mmw_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	byte_medium_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmw_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK.W (Ar),Dq
;	easy: don't test undefined Z,V,C and inside N
chkeasy_mmw_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	clr.b	chk_instruction_flag
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	andi.b	#.notb.(CCR_Z|CCR_V|CCR_C),ccr	;easy: don't test undefined Z,V,C
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	bmi	@outside		;exception occurred -> outside -> N is defined
	and.b	#.notb.CCR_N,d0		;exception not occurred -> inside -> N is not defined
@outside:
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK.W (Ar),Dq
;	hard: test undefined Z,V,C and inside N
chkhard_mmw_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmw_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.W (Ar),Dq
;DIVU.W (Ar),Dq
;	easy: don't test undefined N,Z if V=1
diveasy_mmw_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	bvc	@vc
	andi.b	#.notb.(CCR_N|CCR_Z),ccr	;easy: don't test undefined N,Z if V=1
@vc:
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.W (Ar),Dq
;DIVU.W (Ar),Dq
;	hard: test undefined N,Z if V=1
divhard_mmw_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mml_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.W (Ar),Dn
;CMP2.W (An),Dn
;	easy: don't test undefined N,V
chk2cmp2easy_mml_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.W (Ar),Dn
;CMP2.W (An),Dn
;	hard: test undefined N,V
chk2cmp2hard_mml_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mml_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK.L (Ar),Dq
;	easy: don't test undefined Z,V,C and inside N
chkeasy_mml_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	andi.b	#.notb.(CCR_Z|CCR_V|CCR_C),ccr	;easy: don't test undefined Z,V,C
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	bmi	@outside		;exception occurred -> outside -> N is defined
	and.b	#.notb.CCR_N,d0		;exception not occurred -> inside -> N is not defined
@outside:
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK.L (Ar),Dq
;	hard: test undefined Z,V,C and inside N
chkhard_mml_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L (Ar),Dq
;DIVU.L (Ar),Dq
;	easy: don't test undefined N,Z if V=1
diveasy_mml_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	bvc	@vc
	andi.b	#.notb.(CCR_N|CCR_Z),ccr	;easy: don't test undefined N,Z if V=1
@vc:
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L (Ar),Dq
;DIVU.L (Ar),Dq
;	hard: test undefined N,Z if V=1
divhard_mml_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dq'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mml_drq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dh:Dl'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2-d3		;Dh:Dl
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dh'
	move.l	d3,d5			;Dl'
	move.w	d6,ccr
	op	(a0),d4:d5		;(Ar)',Dh':Dl'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dh'
	jbsr	crc32_long
	move.l	d5,d0			;Dl'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2-d3		;Dh:Dl
	move.l	d2,d0
	or.l	d3,d0
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L (Ar),Dh:Dl
;DIVSL.L (Ar),Dh:Dl
;DIVU.L (Ar),Dh:Dl
;DIVUL.L (Ar),Dh:Dl
;	easy: don't test undefined N,Z if V=1
diveasy_mml_drq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dh:Dl'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2-d3		;Dh:Dl
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dh'
	move.l	d3,d5			;Dl'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	(a0),d4:d5		;(Ar)',Dh':Dl'
	bvc	@vc
	andi.b	#.notb.(CCR_N|CCR_Z),ccr	;easy: don't test undefined N,Z if V=1
@vc:
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dh'
	jbsr	crc32_long
	move.l	d5,d0			;Dl'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2-d3		;Dh:Dl
	move.l	d2,d0
	or.l	d3,d0
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;DIVS.L (Ar),Dh:Dl
;DIVSL.L (Ar),Dh:Dl
;DIVU.L (Ar),Dh:Dl
;DIVUL.L (Ar),Dh:Dl
;	hard: test undefined N,Z if V=1
divhard_mml_drq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dh:Dl'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2-d3		;Dh:Dl
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	move.l	d2,d4			;Dh'
	move.l	d3,d5			;Dl'
	clr.b	divide_by_zero_flag
	move.w	d6,ccr
	op	(a0),d4:d5		;(Ar)',Dh':Dl'
	move.w	sr,d0
	or.b	divide_by_zero_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dh'
	jbsr	crc32_long
	move.l	d5,d0			;Dl'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2-d3		;Dh:Dl
	move.l	d2,d0
	or.l	d3,d0
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmq_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(Ar)
101:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;Dq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(Ar)'
	move.l	d3,d4			;Dq'
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'h
	jbsr	crc32_long
	move.l	4(a0),d0		;(Ar)'l
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Dq
	bne	103b
	movem.l	(a1)+,d1-d2		;(Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.L (Ar),Dn
;CMP2.L (An),Dn
;	easy: don't test undefined N,V
chk2cmp2easy_mmq_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(Ar)
101:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;Dq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(Ar)'
	move.l	d3,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'h
	jbsr	crc32_long
	move.l	4(a0),d0		;(Ar)'l
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Dq
	bne	103b
	movem.l	(a1)+,d1-d2		;(Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.L (Ar),Dn
;CMP2.L (An),Dn
;	hard: test undefined N,V
chk2cmp2hard_mmq_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(Ar)
101:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;Dq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(Ar)'
	move.l	d3,d4			;Dq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),d4			;(Ar)',Dq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'h
	jbsr	crc32_long
	move.l	4(a0),d0		;(Ar)'l
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Dq
	bne	103b
	movem.l	(a1)+,d1-d2		;(Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mm?_ar?

xxx_mmw_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	movea.l	d2,a4			;Aq'
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.B (Ar),An
;CMP2.B (An),An
;	easy: don't test undefined N,V
chk2cmp2easy_mmw_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	movea.l	d2,a4			;Aq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.B (Ar),An
;CMP2.B (An),An
;	hard: test undefined N,V
chk2cmp2hard_mmw_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	movea.l	d2,a4			;Aq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mml_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	movea.l	d2,a4			;Aq'
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.W (Ar),An
;CMP2.W (An),An
;	easy: don't test undefined N,V
chk2cmp2easy_mml_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	movea.l	d2,a4			;Aq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.W (Ar),An
;CMP2.W (An),An
;	hard: test undefined N,V
chk2cmp2hard_mml_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(Ar)'
	movea.l	d2,a4			;Aq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmq_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(Ar)
101:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;Aq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(Ar)'
	movea.l	d3,a4			;Aq'
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'h
	jbsr	crc32_long
	move.l	4(a0),d0		;(Ar)'l
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Aq
	bne	103b
	movem.l	(a1)+,d1-d2		;(Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.L (Ar),An
;CMP2.L (An),An
;	easy: don't test undefined N,V
chk2cmp2easy_mmq_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(Ar)
101:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;Aq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(Ar)'
	movea.l	d3,a4			;Aq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'h
	jbsr	crc32_long
	move.l	4(a0),d0		;(Ar)'l
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Aq
	bne	103b
	movem.l	(a1)+,d1-d2		;(Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;CHK2.L (Ar),An
;CMP2.L (An),An
;	hard: test undefined N,V
chk2cmp2hard_mmq_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(Ar)
101:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;Aq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(Ar)'
	movea.l	d3,a4			;Aq'
	clr.b	chk_instruction_flag
	move.w	d6,ccr
	op	(a0),a4			;(Ar)',Aq'
	move.w	sr,d0
	or.b	chk_instruction_flag,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'h
	jbsr	crc32_long
	move.l	4(a0),d0		;(Ar)'l
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Aq
	bne	103b
	movem.l	(a1)+,d1-d2		;(Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_dr?_mm?

xxx_drb_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dq,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;Dq
101:
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;(Ar)
102:
	ror.l	#8,d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dq'
	move.l	d2,(a0)			;(Ar)'
	move.w	d6,ccr
	op	d3,(a0)			;Dq',(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dq'
	jbsr	crc32_long
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Ar)
	bne	102b
	move.l	(a1)+,d1		;Dq
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drw_mmw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dq,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;Dq
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;(Ar)
102:
	swap.w	d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dq'
	move.l	d2,(a0)			;(Ar)'
	move.w	d6,ccr
	op	d3,(a0)			;Dq',(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dq'
	jbsr	crc32_long
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Ar)
	bne	102b
	move.l	(a1)+,d1		;Dq
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drl_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dq,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dq
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;(Ar)
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dq'
	move.l	d2,(a0)			;(Ar)'
	move.w	d6,ccr
	op	d3,(a0)			;Dq',(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dq'
	jbsr	crc32_long
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Ar)
	bne	102b
	move.l	(a1)+,d1		;Dq
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mm?_mm?

xxx_mmb_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;(Ar)'
	lea.l	work_area+4,a4		;(Aq)'
	lea.l	byte_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	byte_medium_data,a2
	move.l	(a2)+,d2		;(Aq)
102:
	ror.l	#8,d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;(Ar)'
	move.l	d2,(a4)			;(Aq)'
	move.w	d6,ccr
	op	(a3),(a4)		;(Ar)',(Aq)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;(Aq)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Aq)
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mmw_mmw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;(Ar)'
	lea.l	work_area+4,a4		;(Aq)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;(Aq)
102:
	swap.w	d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;(Ar)'
	move.l	d2,(a4)			;(Aq)'
	move.w	d6,ccr
	op	(a3),(a4)		;(Ar)',(Aq)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;(Aq)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Aq)
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mml_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;(Ar)'
	lea.l	work_area+4,a4		;(Aq)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;(Aq)
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;(Ar)'
	move.l	d2,(a4)			;(Aq)'
	move.w	d6,ccr
	op	(a3),(a4)		;(Ar)',(Aq)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;(Aq)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Aq)
	bne	102b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mp?_mp?

xxx_mpb_mpb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)+,(Aq)+'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;(Ar)+'
	lea.l	work_area+4,a4		;(Aq)+'
	lea.l	byte_medium_data,a1
	move.l	(a1)+,d1		;(Ar)+
101:
	ror.l	#8,d1
	lea.l	byte_medium_data,a2
	move.l	(a2)+,d2		;(Aq)+
102:
	ror.l	#8,d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;(Ar)+'
	move.l	d2,(a4)			;(Aq)+'
	movea.l	a3,a5			;Ar'
	movea.l	a4,a0			;Aq'
	move.w	d6,ccr
	op	(a5)+,(a0)+		;(Ar')+',(Aq')+'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;(Ar)+'
	jbsr	crc32_long
	move.l	(a4),d0			;(Aq)+'
	jbsr	crc32_long
	subq.l	#1,a5
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	subq.l	#1,a0
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Aq)+
	bne	102b
	move.l	(a1)+,d1		;(Ar)+
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mpw_mpw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)+,(Aq)+'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;(Ar)+'
	lea.l	work_area+4,a4		;(Aq)+'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;(Ar)+
101:
	swap.w	d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;(Aq)+
102:
	swap.w	d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;(Ar)+'
	move.l	d2,(a4)			;(Aq)+'
	movea.l	a3,a5			;Ar'
	movea.l	a4,a0			;Aq'
	move.w	d6,ccr
	op	(a5)+,(a0)+		;(Ar')+',(Aq')+'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;(Ar)+'
	jbsr	crc32_long
	move.l	(a4),d0			;(Aq)+'
	jbsr	crc32_long
	subq.l	#2,a5
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	subq.l	#2,a0
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Aq)+
	bne	102b
	move.l	(a1)+,d1		;(Ar)+
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mpl_mpl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)+,(Aq)+'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;(Ar)+'
	lea.l	work_area+4,a4		;(Aq)+'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(Ar)+
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;(Aq)+
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;(Ar)+'
	move.l	d2,(a4)			;(Aq)+'
	movea.l	a3,a5			;Ar'
	movea.l	a4,a0			;Aq'
	move.w	d6,ccr
	op	(a5)+,(a0)+		;(Ar')+',(Aq')+'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;(Ar)+'
	jbsr	crc32_long
	move.l	(a4),d0			;(Aq)+'
	jbsr	crc32_long
	subq.l	#4,a5
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	subq.l	#4,a0
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(Aq)+
	bne	102b
	move.l	(a1)+,d1		;(Ar)+
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mn?_mn?

xxx_mnb_mnb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	ror.l	#8,d1
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	ror.l	#8,d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	1(a3),a5		;Ar'+1
	lea.l	1(a4),a0		;Aq'+1
	move.w	d6,ccr
	op	-(a5),-(a0)		;-(Ar')',-(Aq')'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;ABCD.B -(Ar),-(Aq)
;SBCD.B -(Ar),-(Aq)
;	easy: don't test undefined N,V
abcdsbcdeasy_mnb_mnb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	ror.l	#8,d1
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	ror.l	#8,d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	1(a3),a5		;Ar'+1
	lea.l	1(a4),a0		;Aq'+1
	move.w	d6,ccr
	op	-(a5),-(a0)		;-(Ar')',-(Aq')'
	andi.b	#.notb.(CCR_N|CCR_V),ccr	;easy: don't test undefined N,V
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;ABCD.B -(Ar),-(Aq)
;SBCD.B -(Ar),-(Aq)
;	hard: test undefined N,V
abcdsbcdhard_mnb_mnb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	ror.l	#8,d1
	lea.l	byte_heavy_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	ror.l	#8,d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	1(a3),a5		;Ar'+1
	lea.l	1(a4),a0		;Aq'+1
	move.w	d6,ccr
	op	-(a5),-(a0)		;-(Ar')',-(Aq')'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mnw_mnw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	swap.w	d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	swap.w	d2
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	2(a3),a5		;Ar'+2
	lea.l	2(a4),a0		;Aq'+2
	move.w	d6,ccr
	op	-(a5),-(a0)		;-(Ar')',-(Aq')'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mnl_mnl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	4(a3),a5		;Ar'+4
	lea.l	4(a4),a0		;Aq'+4
	move.w	d6,ccr
	op	-(a5),-(a0)		;-(Ar')',-(Aq')'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_im?_dr?

xxx_imb_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)	;IM_BYTE
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imb_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)	;IM_BYTE
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imw_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_iml_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.not.0,1<<0,.not.(1<<0),1<<1,.not.(1<<1),1<<2,.not.(1<<2),1<<4,.not.(1<<4),1<<6,.not.(1<<6),1<<7,.not.(1<<7),1<<8,.not.(1<<8),1<<9,.not.(1<<9),1<<10,.not.(1<<10),1<<12,.not.(1<<12),1<<14,.not.(1<<14),1<<15,.not.(1<<15),1<<16,.not.(1<<16),1<<17,.not.(1<<17),1<<18,.not.(1<<18),1<<20,.not.(1<<20),1<<22,.not.(1<<22),1<<23,.not.(1<<23),1<<24,.not.(1<<24),1<<25,.not.(1<<25),1<<26,.not.(1<<26),1<<28,.not.(1<<28),1<<30,.not.(1<<30),1<<31,.not.(1<<31)	;IM_LONG
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imq_drb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imq_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imq_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_im5_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Dr'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_5BIT
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	#im,d2			;#<data>,Dr'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_im?_ar?

xxx_imq_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,Ar'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;Ar
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	movea.l	d1,a2			;Ar'
	move.w	d6,ccr
	op	#im,a2			;#<data>,Ar'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a2,d0			;Ar'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_im?_mm?

xxx_imb_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)	;IM_BYTE
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imw_mmw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_iml_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.not.0,1<<0,.not.(1<<0),1<<1,.not.(1<<1),1<<2,.not.(1<<2),1<<4,.not.(1<<4),1<<6,.not.(1<<6),1<<7,.not.(1<<7),1<<8,.not.(1<<8),1<<9,.not.(1<<9),1<<10,.not.(1<<10),1<<12,.not.(1<<12),1<<14,.not.(1<<14),1<<15,.not.(1<<15),1<<16,.not.(1<<16),1<<17,.not.(1<<17),1<<18,.not.(1<<18),1<<20,.not.(1<<20),1<<22,.not.(1<<22),1<<23,.not.(1<<23),1<<24,.not.(1<<24),1<<25,.not.(1<<25),1<<26,.not.(1<<26),1<<28,.not.(1<<28),1<<30,.not.(1<<30),1<<31,.not.(1<<31)	;IM_LONG
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imq_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imq_mmw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	swap.w	d1
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imq_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
  .irp im,1,2,3,4,5,6,7,8	;IM_QUICK
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_im3_mmb	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_medium_data,a1
	move.l	(a1)+,d1		;(Ar)
101:
	ror.l	#8,d1
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,1,2,3,4,5,6,7	;IM_3BIT
	move.l	d1,(a0)			;(Ar)'
	move.w	d6,ccr
	op	#im,(a0)		;#<data>,(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_im?_ccr

xxx_imb_ccr	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,CCR'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_full_data,a1
	move.l	(a1)+,d1		;CCR
101:
  .irp im,0,.notb.0,1<<0,.notb.(1<<0),1<<1,.notb.(1<<1),1<<2,.notb.(1<<2),1<<3,.notb.(1<<3),1<<4,.notb.(1<<4),1<<5,.notb.(1<<5),1<<6,.notb.(1<<6),1<<7,.notb.(1<<7)	;IM_BYTE
	move.w	d1,ccr			;CCR
	op	#im,ccr			;#<data>,CCR
	move.w	sr,d0
	jbsr	crc32_byte
  .endm
	move.l	(a1)+,d1		;CCR
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_imw_ccr	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op #<data>,CCR'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_heavy_data,a1
	move.l	(a1)+,d1		;CCR
101:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.w	d1,ccr			;CCR
	op	#im,ccr			;#<data>,CCR
	move.w	sr,d0
	jbsr	crc32_byte
  .endm
	move.l	(a1)+,d1		;CCR
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_mw?_dr?

xxx_mwl_drw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (d16,Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(d16,Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;(d16,Ar)
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;(d16,Ar)'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	(0.w,a0),d4		;(d16,Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(d16,Ar)'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;(d16,Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mwq_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (d16,Ar),Dq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(d16,Ar)'
	lea.l	quad_light_data,a1
	movem.l	(a1)+,d1-d2		;(d16,Ar)
101:
	lea.l	word_light_data,a3
	move.l	(a3)+,d3		;Dq
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movem.l	d1-d2,(a0)		;(d16,Ar)'
	move.l	d3,d5			;Dq'
	move.w	d6,ccr
	op	(0.w,a0),d5		;(d16,Ar)',Dq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a0),d0			;(d16,Ar)'
	jbsr	crc32_long
	move.l	4(a0),d0		;(d16,Ar)'
	jbsr	crc32_long
	move.l	d5,d0			;Dq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;Dq
	bne	103b
	movem.l	(a1)+,d1-d2		;(d16,Ar)
	move.l	d1,d0
	or.l	d2,d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;xxx_dr?_mw?

xxx_drw_mwl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dq,(d16,Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(d16,Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;Dq
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2		;(d16,Ar)
102:
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dq'
	move.l	d2,(a0)			;(d16,Ar)'
	move.w	d6,ccr
	op	d3,(0.w,a0)		;Dq',(d16,Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dq'
	jbsr	crc32_long
	move.l	(a0),d0			;(d16,Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;(d16,Ar)
	bne	102b
	move.l	(a1)+,d1		;Dq
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drl_mwq	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dq,(d16,Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(d16,Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dq
101:
	lea.l	quad_light_data,a2
	movem.l	(a2)+,d2-d3		;(d16,Ar)
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d4			;Dq'
	movem.l	d2-d3,(a0)		;(d16,Ar)'
	move.w	d6,ccr
	op	d4,(0.w,a0)		;Dq',(d16,Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
	move.l	(a0),d0			;(d16,Ar)'
	jbsr	crc32_long
	move.l	4(a0),d0		;(d16,Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	movem.l	(a2)+,d2-d3		;(d16,Ar)
	move.l	d2,d0
	or.l	d3,d0
	bne	102b
	move.l	(a1)+,d1		;Dq
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;bit field

bfxxx_drss	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{#o:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
    .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	d1,d2			;Dr'
	move.w	d6,ccr
	op	d2{#of:#wi}		;Dr'{#o:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dr'
	jbsr	crc32_long
    .endm
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drsd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{#o:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{#of:d5}		;Dr'{#o:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drds	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{Do:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{d4:#wi}		;Dr'{Do:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a4)+,d4		;Do
	bne	104b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drdd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{Do:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{d4:d5}		;Dr'{Do:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a4)+,d4		;Do
	bne	104b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmss	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){#o:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_medium_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	ccr_mono_data,a6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
    .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){#of:#wi}		;(Ar)'{#o:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
    .endm
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmsd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){#o:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_medium_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){#of:d5}		;(Ar)'{#o:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmds	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){Do:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_medium_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	ccr_mono_data,a6
106:
  .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){d4:#wi}		;(Ar)'{Do:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	move.l	(a4)+,d4		;Do
	bne	104b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmdd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){Do:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_medium_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
106:
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){d4:d5}		;(Ar)'{Do:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a4)+,d4		;Do
	bne	104b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_drss	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,Dr{#o:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	long_mono_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
    .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d2,d3{#of:#wi}		;Dn',Dr'{#o:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
    .endm
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_drsd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,Dr{#o:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	long_mono_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d2,d3{#of:d5}		;Dn',Dr'{#o:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_drds	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,Dr{Do:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	long_mono_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d2,d3{d4:#wi}		;Dn',Dr'{Do:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a4)+,d4		;Do
	bne	104b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_drdd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,Dr{Do:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	long_mono_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d2,d3{d4:d5}		;Dn',Dr'{Do:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a4)+,d4		;Do
	bne	104b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_mmss	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,(Ar){#o:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	long_light_data,a0		;Dn
100:
	lea.l	oct_mono_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	ccr_mono_data,a6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
    .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	d1,(a3){#of:#wi}	;Dn',(Ar)'{#o:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
    .endm
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_mmsd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,(Ar){#o:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	long_light_data,a0		;Dn
100:
	lea.l	oct_mono_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	d1,(a3){#of:d5}		;Dn',(Ar)'{#o:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_mmds	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,(Ar){Do:#w}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	long_light_data,a0		;Dn
100:
	lea.l	oct_mono_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	ccr_mono_data,a6
106:
  .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	d1,(a3){d4:#wi}		;Dn',(Ar)'{Do:#w}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	move.l	(a4)+,d4		;Do
	bne	104b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drl_mmdd	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dn,(Ar){Do:Dw}'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	long_light_data,a0		;Dn
100:
	lea.l	oct_mono_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	ccr_mono_data,a6
106:
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	d1,(a3){d4:d5}		;Dn',(Ar)'{Do:Dw}
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a4)+,d4		;Do
	bne	104b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drss_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{#o:#w},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	long_mono_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
    .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{#of:#wi},d2		;Dr'{#o:#w},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
    .endm
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drsd_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{#o:Dw},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	long_mono_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{#of:d5},d2		;Dr'{#o:Dw},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drds_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{Do:#w},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	long_mono_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{d4:#wi},d2		;Dr'{Do:#w},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	(a4)+,d4		;Do
	bne	104b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_drdd_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr{Do:Dw},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	long_mono_data,a0
	move.l	(a0)+,d0		;Dn
100:
	movea.l	d0,a2
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	a2,d2			;Dn'
	move.l	d1,d3			;Dr'
	move.w	d6,ccr
	op	d3{d4:d5},d2		;Dr'{Do:Dw},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d2,d0			;Dn'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a0)+,d0		;Dn
	bne	100b
	move.l	(a5)+,d5		;Do
	bne	105b
	move.l	(a4)+,d4		;Do
	bne	104b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmss_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){#o:#w},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_light_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	long_mono_data,a0	;Dn
100:
	lea.l	ccr_mono_data,a6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
    .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){#of:#wi},d1	;(Ar)'{#o:#w},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
    .endm
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmsd_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){#o:Dw},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_light_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	long_mono_data,a0	;Dn
100:
	lea.l	ccr_mono_data,a6
106:
  .irp of,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31	;IM_OFFSET
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){#of:d5},d1		;(Ar)'{#o:Dw},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	(a5)+,d5		;Dw
	bne	105b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmds_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){Do:#w},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_light_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	long_mono_data,a0	;Dn
100:
	lea.l	ccr_mono_data,a6
106:
  .irp wi,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32	;IM_WIDTH
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){d4:#wi},d1		;(Ar)'{Do:#w},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
  .endm
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	(a4)+,d4		;Do
	bne	104b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bfxxx_mmdd_drl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar){Do:Dw},Dn'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area+4,a3		;(Ar)'
	lea.l	oct_light_data,a2
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
102:
	lea.l	bf_offset_data,a4
	move.l	(a4)+,d4		;Do
104:
	lea.l	bf_width_data,a5
	move.l	(a5)+,d5		;Dw
105:
	lea.l	long_mono_data,a0	;Dn
100:
	lea.l	ccr_mono_data,a6
106:
	move.l	(a0),d1			;Dn'
	movem.l	d2-d3/d6/a1,-4(a3)	;(Ar-4)',(Ar)',(Ar+4)',(Ar-8)'
	move.w	(a6),ccr
	op	(a3){d4:d5},d1		;(Ar)'{Do:Dw},Dn'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	-4(a3),d0		;(Ar-4)'
	jbsr	crc32_long
	move.l	(a3),d0			;(Ar)'
	jbsr	crc32_long
	move.l	4(a3),d0		;(Ar+4)'
	jbsr	crc32_long
	move.l	8(a3),d0		;(Ar+8)'
	jbsr	crc32_long
	move.l	d1,d0			;Dn'
	jbsr	crc32_long
	addq.l	#2,a6
	tst.w	(a6)
	bne	106b
	addq.l	#4,a0			;Dn
	tst.l	(a0)
	bne	100b
	move.l	(a5)+,d5		;Dw
	bne	105b
	move.l	(a4)+,d4		;Do
	bne	104b
	movem.l	(a2)+,d2-d3/d6/a1	;(Ar-4),(Ar),(Ar+4),(Ar+8)
	move.l	a1,d0
	or.l	d2,d0
	or.l	d3,d0
	or.l	d6,d0
	bne	102b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;pack/unpk

xxx_drw_drb_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq,#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	word_medium_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	byte_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4,#im		;Dr',Dq',#<data>
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mnw_mnb_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq),#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	swap.w	d1
	lea.l	byte_light_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	ror.l	#8,d2
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	2(a3),a5		;Ar'+2
	lea.l	1(a4),a0		;Aq'+1
	move.w	d6,ccr
	op	-(a5),-(a0),#im		;-(Ar')',-(Aq')',#<data>
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_drb_drw_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,Dq,#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	byte_light_data,a1
	move.l	(a1)+,d1		;Dr
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;Dq
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.l	d1,d3			;Dr'
	move.l	d2,d4			;Dq'
	move.w	d6,ccr
	op	d3,d4,#im		;Dr',Dq',#<data>
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d3,d0			;Dr'
	jbsr	crc32_long
	move.l	d4,d0			;Dq'
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Dq
	bne	102b
	move.l	(a1)+,d1		;Dr
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

xxx_mnb_mnw_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op -(Ar),-(Aq),#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a3		;-(Ar)'
	lea.l	work_area+4,a4		;-(Aq)'
	lea.l	byte_light_data,a1
	move.l	(a1)+,d1		;-(Ar)
101:
	ror.l	#8,d1
	lea.l	word_light_data,a2
	move.l	(a2)+,d2		;-(Aq)
102:
	swap.w	d2
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	move.l	d1,(a3)			;-(Ar)'
	move.l	d2,(a4)			;-(Aq)'
	lea.l	1(a3),a5		;Ar'+1
	lea.l	2(a4),a0		;Aq'+2
	move.w	d6,ccr
	op	-(a5),-(a0),#im		;-(Ar')',-(Aq')',#<data>
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	(a3),d0			;-(Ar)'
	jbsr	crc32_long
	move.l	(a4),d0			;-(Aq)'
	jbsr	crc32_long
	suba.l	a3,a5
	move.l	a5,d0			;Ar'-Ar
	jbsr	crc32_long
	suba.l	a4,a0
	move.l	a0,d0			;Aq'-Aq
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;-(Aq)
	bne	102b
	move.l	(a1)+,d1		;-(Ar)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;bcc/bsr/jmp/jsr/dbcc

bcc_label	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op <label>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_full_data,a6	;Bcc <label>
	move.w	(a6)+,d6
106:
	suba.l	a0,a0			;flags
	move.w	d6,ccr
	op	101f
	addq.l	#1,a0			;15=not taken
	addq.l	#2,a0			;14=too short
101:
	addq.l	#4,a0			;12=taken
	addq.l	#8,a0			;8=too long
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a0,d0			;flags
	jbsr	crc32_byte
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

bsr_label	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op <label>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	suba.l	a0,a0			;flags
	move.w	d6,ccr
	op	101f
100:
	addq.l	#1,a0			;15=not taken
	addq.l	#2,a0			;14=too short
101:
	addq.l	#4,a0			;12=taken
	addq.l	#8,a0			;8=too long
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a0,d0			;flags
	jbsr	crc32_byte
	move.l	(sp)+,d0		;pc
	sub.l	#100b,d0
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

jmp_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	101f(pc),a1		;Ar
	lea.l	ccr_light_data,a6
	move.w	(a6)+,d6
106:
	suba.l	a0,a0			;flags
	move.w	d6,ccr
	op	(a1)			;(Ar)
	addq.l	#1,a0			;15=not taken
	addq.l	#2,a0			;14=too short
101:
	addq.l	#4,a0			;12=taken
	addq.l	#8,a0			;8=too long
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a0,d0			;flags
	jbsr	crc32_byte
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

jsr_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_light_data,a6
	lea.l	101f,a1		;Ar
	move.w	(a6)+,d6
106:
	suba.l	a0,a0			;flags
	move.w	d6,ccr
	op	(a1)			;(Ar)
100:
	addq.l	#1,a0			;15=not taken
	addq.l	#2,a0			;14=too short
101:
	addq.l	#4,a0			;12=taken
	addq.l	#8,a0			;8=too long
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a0,d0			;flags
	jbsr	crc32_byte
	move.l	(sp)+,d0		;pc
	sub.l	#100b,d0
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

dbcc_drw_label	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dr,<label>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	ccr_full_data,a6	;DBcc.W Dr,<label>
	move.w	(a6)+,d6
106:
  .irp n1,$00000000,$00000001,$00008000,$00010000,$80000000
	move.l	#n1,d1			;Dr
	suba.l	a0,a0			;flags
	move.w	d6,ccr
	op	d1,101f
	addq.l	#1,a0			;15=not taken
	addq.l	#2,a0			;14=too short
101:
	addq.l	#4,a0			;12=taken
	addq.l	#8,a0			;8=too long
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0			;Dr
	jbsr	crc32_long
	move.l	a0,d0			;flags
	jbsr	crc32_byte
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;lea/pea

lea_mml_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar),Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_medium_data,a1
	move.l	(a1)+,d1		;Ar
101:
	lea.l	long_medium_data,a2
	move.l	(a2)+,d2		;Aq
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	movea.l	d1,a3			;Ar'
	movea.l	d2,a4			;Aq'
	move.w	d6,ccr
	op	(a3),a4			;(Ar)',Aq'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a3,d0			;Ar'
	jbsr	crc32_long
	move.l	a4,d0			;Aq'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2		;Aq
	bne	102b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

pea_mml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;Ar
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	movea.l	d1,a3			;Ar'
	move.w	d6,ccr
	op	(a3)			;(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	a3,d0			;Ar'
	jbsr	crc32_long
	move.l	(sp)+,d0		;Ar''
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;link/unlk

link_arl_imw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Ar,#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	movea.l	sp,a5			;old A7
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;old Ar
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.notw.0,1<<0,.notw.(1<<0),1<<1,.notw.(1<<1),1<<2,.notw.(1<<2),1<<4,.notw.(1<<4),1<<6,.notw.(1<<6),1<<7,.notw.(1<<7),1<<8,.notw.(1<<8),1<<9,.notw.(1<<9),1<<10,.notw.(1<<10),1<<12,.notw.(1<<12),1<<14,.notw.(1<<14),1<<15,.notw.(1<<15)	;IM_WORD
	movea.l	d1,a2			;old Ar'
	move.w	d6,ccr
;A7 must be the user stack pointer.
	op	a2,#im			;LINK.W Ar,#<data> == PEA.L (Ar);MOVEA.L A7,Ar;ADDA.W #<data>,A7
;A7 is broken. Don't use it as a stack pointer.
	move.w	sr,d0
	move.l	-4(a5),d2		;old Ar'
	movea.l	sp,a4			;new A7
	movea.l	a5,sp
;A7 is restored.
	jbsr	crc32_byte
	move.l	d2,d0			;old Ar'
	jbsr	crc32_long
	move.l	a2,d0			;new Ar'
	sub.l	a5,d0
	jbsr	crc32_long
	move.l	a4,d0			;new A7
	sub.l	a5,d0
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;old Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

link_arl_iml	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Ar,#<data>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	movea.l	sp,a5			;old A7
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;old Ar
101:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
  .irp im,0,.not.0,1<<0,.not.(1<<0),1<<1,.not.(1<<1),1<<2,.not.(1<<2),1<<4,.not.(1<<4),1<<6,.not.(1<<6),1<<7,.not.(1<<7),1<<8,.not.(1<<8),1<<9,.not.(1<<9),1<<10,.not.(1<<10),1<<12,.not.(1<<12),1<<14,.not.(1<<14),1<<15,.not.(1<<15),1<<16,.not.(1<<16),1<<17,.not.(1<<17),1<<18,.not.(1<<18),1<<20,.not.(1<<20),1<<22,.not.(1<<22),1<<23,.not.(1<<23),1<<24,.not.(1<<24),1<<25,.not.(1<<25),1<<26,.not.(1<<26),1<<28,.not.(1<<28),1<<30,.not.(1<<30),1<<31,.not.(1<<31)	;IM_LONG
	movea.l	d1,a2			;old Ar'
	move.w	d6,ccr
;A7 must be the user stack pointer.
	op	a2,#im			;LINK.L Ar,#<data> == PEA.L (Ar);MOVEA.L A7,Ar;ADDA.L #<data>,A7
;A7 is broken. Don't use it as a stack pointer.
	move.w	sr,d0
	move.l	-4(a5),d2		;old Ar'
	movea.l	sp,a4			;new A7
	movea.l	a5,sp
;A7 is restored.
	jbsr	crc32_byte
	move.l	d2,d0			;old Ar'
	jbsr	crc32_long
	move.l	a2,d0			;new Ar'
	sub.l	a5,d0
	jbsr	crc32_long
	move.l	a4,d0			;new A7
	sub.l	a5,d0
	jbsr	crc32_long
  .endm
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;old Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

unlk_arl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Ar'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	movea.l	sp,a5			;old A7
	lea.l	work_area,a0		;Ar
	lea.l	long_heavy_data,a1
	move.l	(a1)+,d1		;new A7
101:
	lea.l	ccr_full_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,(a0)			;new A7
	movea.l	a0,a2			;Ar'
	move.w	d6,ccr
;A7 must be the user stack pointer.
	op	a2			;UNLK Ar == MOVEA.L Ar,A7;MOVEA.L (A7)+,Ar
;A7 is broken. Don't use it as a stack pointer.
	move.w	sr,d0
	movea.l	sp,a4			;new A7
	movea.l	a5,sp
;A7 is restored.
	jbsr	crc32_byte
	move.l	(a0),d0			;new A7
	jbsr	crc32_long
	move.l	a2,d0			;Ar'
	jbsr	crc32_long
	move.l	a4,d0			;new A7
	sub.l	a0,d0
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a1)+,d1		;Ar
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;movem

movem_list_mnw	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op <list>,-(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0
	movea.l	#$55555555,a5
	lea.l	long_light_data,a1
	move.l	(a1)+,d1
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:

	move.l	d1,d4
	movea.l	a0,a3
	movea.l	d2,a4
	move.w	a5,(a3)+
	move.w	a5,(a3)+
	move.w	a5,(a3)+
	move.w	d6,ccr
	movem.w	d4/a3-a4,-(a3)
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	a4,d0
	jbsr	crc32_long
	move.w	(a0),d0
	jbsr	crc32_word
	move.w	2(a0),d0
	sub.w	a0,d0
	jbsr	crc32_word
	move.w	4(a0),d0
	jbsr	crc32_word

	move.l	d1,d4
	movea.l	d2,a3
	movea.l	a0,a4
	move.w	a5,(a4)+
	move.w	a5,(a4)+
	move.w	a5,(a4)+
	move.w	d6,ccr
	movem.w	d4/a3-a4,-(a4)
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	jbsr	crc32_long
	move.l	a4,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.w	(a0),d0
	jbsr	crc32_word
	move.w	2(a0),d0
	jbsr	crc32_word
	move.w	4(a0),d0
	sub.w	a0,d0
	jbsr	crc32_word

	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2
	bne	102b
	move.l	(a1)+,d1
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

movem_list_mnl	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op <list>,-(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0
	movea.l	#$55555555,a5
	lea.l	long_light_data,a1
	move.l	(a1)+,d1
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:

	move.l	d1,d4
	movea.l	a0,a3
	movea.l	d2,a4
	move.l	a5,(a3)+
	move.l	a5,(a3)+
	move.l	a5,(a3)+
	move.w	d6,ccr
	movem.l	d4/a3-a4,-(a3)
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	a4,d0
	jbsr	crc32_long
	move.l	(a0),d0
	jbsr	crc32_long
	move.l	4(a0),d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	8(a0),d0
	jbsr	crc32_long

	move.l	d1,d4
	movea.l	d2,a3
	movea.l	a0,a4
	move.l	a5,(a4)+
	move.l	a5,(a4)+
	move.l	a5,(a4)+
	move.w	d6,ccr
	movem.l	d4/a3-a4,-(a4)
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	jbsr	crc32_long
	move.l	a4,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	(a0),d0
	jbsr	crc32_long
	move.l	4(a0),d0
	jbsr	crc32_long
	move.l	8(a0),d0
	sub.l	a0,d0
	jbsr	crc32_long

	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2
	bne	102b
	move.l	(a1)+,d1
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

movem_mpw_list	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)+,<list>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0
	movea.l	#$55555555,a5
	lea.l	word_light_data,a1
	move.l	(a1)+,d1
101:
	lea.l	word_light_data,a2
	move.l	(a2)+,d2
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:

	movea.l	a0,a3
	move.w	d1,(a3)+
	move.w	a5,(a3)+
	move.w	d2,(a3)+
	move.l	a5,d4
	movea.l	a0,a3
	movea.l	a5,a4
	move.w	d6,ccr
	movem.w	(a3)+,d4/a3-a4
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	a4,d0
	jbsr	crc32_long

	movea.l	a0,a4
	move.w	d1,(a4)+
	move.w	d2,(a4)+
	move.w	a5,(a4)+
	move.l	a5,d4
	movea.l	a5,a3
	movea.l	a0,a4
	move.w	d6,ccr
	movem.w	(a4)+,d4/a3-a4
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	jbsr	crc32_long
	move.l	a4,d0
	sub.l	a0,d0
	jbsr	crc32_long

	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2
	bne	102b
	move.l	(a1)+,d1
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

movem_mpl_list	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op (Ar)+,<list>'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0
	movea.l	#$55555555,a5
	lea.l	long_light_data,a1
	move.l	(a1)+,d1
101:
	lea.l	long_light_data,a2
	move.l	(a2)+,d2
102:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:

	movea.l	a0,a3
	move.l	d1,(a3)+
	move.l	a5,(a3)+
	move.l	d2,(a3)+
	move.l	a5,d4
	movea.l	a0,a3
	movea.l	a5,a4
	move.w	d6,ccr
	movem.l	(a3)+,d4/a3-a4
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	a4,d0
	jbsr	crc32_long

	movea.l	a0,a4
	move.l	d1,(a4)+
	move.l	d2,(a4)+
	move.l	a5,(a4)+
	move.l	a5,d4
	movea.l	a5,a3
	movea.l	a0,a4
	move.w	d6,ccr
	movem.l	(a4)+,d4/a3-a4
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a3,d0
	jbsr	crc32_long
	move.l	a4,d0
	sub.l	a0,d0
	jbsr	crc32_long

	move.w	(a6)+,d6
	bne	106b
	move.l	(a2)+,d2
	bne	102b
	move.l	(a1)+,d1
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

;--------------------------------------------------------------------------------
;cas/cas2

cas_byte	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dc,Du,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	byte_medium_data,a1
	move.l	(a1)+,d1		;Dc
101:
	lea.l	byte_light_data,a2
	move.l	(a2)+,d2		;Du
102:
	lea.l	byte_medium_data,a3
	move.l	(a3)+,d3		;(Ar)
103:
	ror.l	#8,d3
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d4			;Dc'
	move.l	d2,d5			;Du'
	move.l	d3,(a0)			;(Ar)'
	move.w	d6,ccr
	op	d4,d5,(a0)		;Dc',Du',(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0			;Dc'
	jbsr	crc32_long
	move.l	d5,d0			;Du'
	jbsr	crc32_long
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;(Ar)
	bne	103b
	move.l	(a2)+,d2		;Du
	bne	102b
	move.l	(a1)+,d1		;Dc
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

cas_word	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dc,Du,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	word_light_data,a1
	move.l	(a1)+,d1		;Dc
101:
	lea.l	word_mono_data,a2
	move.l	(a2)+,d2		;Du
102:
	lea.l	word_light_data,a3
	move.l	(a3)+,d3		;(Ar)
103:
	swap.w	d3
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d4			;Dc'
	move.l	d2,d5			;Du'
	move.l	d3,(a0)			;(Ar)'
	move.w	d6,ccr
	op	d4,d5,(a0)		;Dc',Du',(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0			;Dc'
	jbsr	crc32_long
	move.l	d5,d0			;Du'
	jbsr	crc32_long
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;(Ar)
	bne	103b
	move.l	(a2)+,d2		;Du
	bne	102b
	move.l	(a1)+,d1		;Dc
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

cas_long	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dc,Du,(Ar)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0		;(Ar)'
	lea.l	long_light_data,a1
	move.l	(a1)+,d1		;Dc
101:
	lea.l	long_mono_data,a2
	move.l	(a2)+,d2		;Du
102:
	lea.l	long_light_data,a3
	move.l	(a3)+,d3		;(Ar)
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	move.l	d1,d4			;Dc'
	move.l	d2,d5			;Du'
	move.l	d3,(a0)			;(Ar)'
	move.w	d6,ccr
	op	d4,d5,(a0)		;Dc',Du',(Ar)'
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d4,d0			;Dc'
	jbsr	crc32_long
	move.l	d5,d0			;Du'
	jbsr	crc32_long
	move.l	(a0),d0			;(Ar)'
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	move.l	(a3)+,d3		;(Ar)
	bne	103b
	move.l	(a2)+,d2		;Du
	bne	102b
	move.l	(a1)+,d1		;Dc
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

cas2_word	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0
	lea.l	long_light_data,a1	;Dc1:Dc2
101:
	lea.l	long_mono_data,a2	;Du1:Du2
102:
	lea.l	long_light_data,a3	;(Rn1):(Rn2)
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	lea.l	(a0),a4
	lea.l	2(a0),a5
	movem.w	(a1),d1-d2
	movem.w	(a2),d3-d4
	move.w	(a3),(a4)
	move.w	2(a3),(a5)
	move.w	d6,ccr
	op	d1:d2,d3:d4,(a4):(a5)
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0
	jbsr	crc32_long
	move.l	d2,d0
	jbsr	crc32_long
	move.l	d3,d0
	jbsr	crc32_long
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a4,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	a5,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.w	(a0),d0
	jbsr	crc32_word
	move.w	2(a0),d0
	jbsr	crc32_word
	move.w	(a6)+,d6
	bne	106b
	addq.l	#4,a3
	tst.l	(a3)
	bne	103b
	addq.l	#4,a2
	tst.l	(a2)
	bne	102b
	addq.l	#4,a1
	tst.l	(a1)
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

cas2_long	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a0
	lea.l	quad_light_data,a1	;Dc1:Dc2
101:
	lea.l	quad_mono_data,a2	;Du1:Du2
102:
	lea.l	quad_light_data,a3	;(Rn1):(Rn2)
103:
	lea.l	ccr_mono_data,a6
	move.w	(a6)+,d6
106:
	lea.l	(a0),a4
	lea.l	4(a0),a5
	movem.l	(a1),d1-d2
	movem.l	(a2),d3-d4
	move.l	(a3),(a4)
	move.l	4(a3),(a5)
	move.w	d6,ccr
	op	d1:d2,d3:d4,(a4):(a5)
	move.w	sr,d0
	jbsr	crc32_byte
	move.l	d1,d0
	jbsr	crc32_long
	move.l	d2,d0
	jbsr	crc32_long
	move.l	d3,d0
	jbsr	crc32_long
	move.l	d4,d0
	jbsr	crc32_long
	move.l	a4,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	a5,d0
	sub.l	a0,d0
	jbsr	crc32_long
	move.l	(a0),d0
	jbsr	crc32_long
	move.l	4(a0),d0
	jbsr	crc32_long
	move.w	(a6)+,d6
	bne	106b
	addq.l	#8,a3
	move.l	(a3),d0
	or.l	4(a3),d0
	bne	103b
	addq.l	#8,a2
	move.l	(a2),d0
	or.l	4(a2),d0
	bne	102b
	addq.l	#8,a1
	move.l	(a1),d0
	or.l	4(a1),d0
	bne	101b
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm


;--------------------------------------------------------------------------------
;effective address

eatest	.macro	ea
	lea.l	ea,a0
	move.l	a0,d0
	sub.l	a4,d0
	jbsr	crc32_long
	.endm

zeatest	.macro	ea
	lea.l	ea,a0
	move.l	a0,d0
	jbsr	crc32_long
	.endm

lea_brief	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op <brief-format>,Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a4
	move.l	#$00008000,d5
  .irp d8,$ffffff80,$0000007c
	eatest	(d8,a4,d5.w)			;nnnn0000dddddddd
	eatest	(d8,a4,d5.w*2)			;nnnn0010dddddddd
	eatest	(d8,a4,d5.w*4)			;nnnn0100dddddddd
	eatest	(d8,a4,d5.w*8)			;nnnn0110dddddddd
	eatest	(d8,a4,d5.l)			;nnnn1000dddddddd
	eatest	(d8,a4,d5.l*2)			;nnnn1010dddddddd
	eatest	(d8,a4,d5.l*4)			;nnnn1100dddddddd
	eatest	(d8,a4,d5.l*8)			;nnnn1110dddddddd
  .endm
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm

lea_full	.macro	op,crc
	leastr	'&op',a0
	move.l	#test_number,d0
test_number = test_number+1
	jbsr	mnemonic_check
	beq	@skip
	fillto	@v,36,'&op <full-format>,Aq'
	print	@v
	jbsr	crc32_reset
	try_illegal_instruction
	lea.l	work_area,a4
	move.l	#$00008000,d5
	lea.l	work_area_start,a0
	lea.l	work_area_end,a1
	lea.l	256(a0),a2
100:	move.l	a2,(a0)+
	addq.l	#4,a2
	cmpa.l	a1,a0
	blo	100b
	eatest	(a4,d5.w)			;nnnn000100010000
	eatest	(a4,d5.w*2)			;nnnn001100010000
	eatest	(a4,d5.w*4)			;nnnn010100010000
	eatest	(a4,d5.w*8)			;nnnn011100010000
	eatest	(a4,zd5.w)			;nnnn000101010000
	eatest	(a4,zd5.w*2)			;nnnn001101010000
	eatest	(a4,zd5.w*4)			;nnnn010101010000
	eatest	(a4,zd5.w*8)			;nnnn011101010000
	eatest	(a4,d5.l)			;nnnn100100010000
	eatest	(a4,d5.l*2)			;nnnn101100010000
	eatest	(a4,d5.l*4)			;nnnn110100010000
	eatest	(a4,d5.l*8)			;nnnn111100010000
	eatest	(a4,zd5.l)			;nnnn100101010000
	eatest	(a4,zd5.l*2)			;nnnn101101010000
	eatest	(a4,zd5.l*4)			;nnnn110101010000
	eatest	(a4,zd5.l*8)			;nnnn111101010000
	eatest	([a4,d5.w])			;nnnn000100010001
	eatest	([a4,d5.w*2])			;nnnn001100010001
	eatest	([a4,d5.w*4])			;nnnn010100010001
	eatest	([a4,d5.w*8])			;nnnn011100010001
	eatest	([a4,zd5.w])			;nnnn000101010001
	eatest	([a4,zd5.w*2])			;nnnn001101010001
	eatest	([a4,zd5.w*4])			;nnnn010101010001
	eatest	([a4,zd5.w*8])			;nnnn011101010001
	eatest	([a4,d5.l])			;nnnn100100010001
	eatest	([a4,d5.l*2])			;nnnn101100010001
	eatest	([a4,d5.l*4])			;nnnn110100010001
	eatest	([a4,d5.l*8])			;nnnn111100010001
	eatest	([a4,zd5.l])			;nnnn100101010001
	eatest	([a4,zd5.l*2])			;nnnn101101010001
	eatest	([a4,zd5.l*4])			;nnnn110101010001
	eatest	([a4,zd5.l*8])			;nnnn111101010001
	eatest	([a4],d5.w)			;nnnn000100010101
	eatest	([a4],d5.w*2)			;nnnn001100010101
	eatest	([a4],d5.w*4)			;nnnn010100010101
	eatest	([a4],d5.w*8)			;nnnn011100010101
	eatest	([a4],zd5.w)			;nnnn000101010101
	eatest	([a4],zd5.w*2)			;nnnn001101010101
	eatest	([a4],zd5.w*4)			;nnnn010101010101
	eatest	([a4],zd5.w*8)			;nnnn011101010101
	eatest	([a4],d5.l)			;nnnn100100010101
	eatest	([a4],d5.l*2)			;nnnn101100010101
	eatest	([a4],d5.l*4)			;nnnn110100010101
	eatest	([a4],d5.l*8)			;nnnn111100010101
	eatest	([a4],zd5.l)			;nnnn100101010101
	eatest	([a4],zd5.l*2)			;nnnn101101010101
	eatest	([a4],zd5.l*4)			;nnnn110101010101
	eatest	([a4],zd5.l*8)			;nnnn111101010101
  .irp od,$ffff8000,$00007ffc
	eatest	([a4,d5.w],od.w)		;nnnn000100010010
	eatest	([a4,d5.w*2],od.w)		;nnnn001100010010
	eatest	([a4,d5.w*4],od.w)		;nnnn010100010010
	eatest	([a4,d5.w*8],od.w)		;nnnn011100010010
	eatest	([a4,zd5.w],od.w)		;nnnn000101010010
	eatest	([a4,zd5.w*2],od.w)		;nnnn001101010010
	eatest	([a4,zd5.w*4],od.w)		;nnnn010101010010
	eatest	([a4,zd5.w*8],od.w)		;nnnn011101010010
	eatest	([a4,d5.l],od.w)		;nnnn100100010010
	eatest	([a4,d5.l*2],od.w)		;nnnn101100010010
	eatest	([a4,d5.l*4],od.w)		;nnnn110100010010
	eatest	([a4,d5.l*8],od.w)		;nnnn111100010010
	eatest	([a4,zd5.l],od.w)		;nnnn100101010010
	eatest	([a4,zd5.l*2],od.w)		;nnnn101101010010
	eatest	([a4,zd5.l*4],od.w)		;nnnn110101010010
	eatest	([a4,zd5.l*8],od.w)		;nnnn111101010010
	eatest	([a4],d5.w,od.w)		;nnnn000100010110
	eatest	([a4],d5.w*2,od.w)		;nnnn001100010110
	eatest	([a4],d5.w*4,od.w)		;nnnn010100010110
	eatest	([a4],d5.w*8,od.w)		;nnnn011100010110
	eatest	([a4],zd5.w,od.w)		;nnnn000101010110
	eatest	([a4],zd5.w*2,od.w)		;nnnn001101010110
	eatest	([a4],zd5.w*4,od.w)		;nnnn010101010110
	eatest	([a4],zd5.w*8,od.w)		;nnnn011101010110
	eatest	([a4],d5.l,od.w)		;nnnn100100010110
	eatest	([a4],d5.l*2,od.w)		;nnnn101100010110
	eatest	([a4],d5.l*4,od.w)		;nnnn110100010110
	eatest	([a4],d5.l*8,od.w)		;nnnn111100010110
	eatest	([a4],zd5.l,od.w)		;nnnn100101010110
	eatest	([a4],zd5.l*2,od.w)		;nnnn101101010110
	eatest	([a4],zd5.l*4,od.w)		;nnnn110101010110
	eatest	([a4],zd5.l*8,od.w)		;nnnn111101010110
  .endm
  .irp od,$ffff7ffc,$00008000
	eatest	([a4,d5.w],od.l)		;nnnn000100010011
	eatest	([a4,d5.w*2],od.l)		;nnnn001100010011
	eatest	([a4,d5.w*4],od.l)		;nnnn010100010011
	eatest	([a4,d5.w*8],od.l)		;nnnn011100010011
	eatest	([a4,zd5.w],od.l)		;nnnn000101010011
	eatest	([a4,zd5.w*2],od.l)		;nnnn001101010011
	eatest	([a4,zd5.w*4],od.l)		;nnnn010101010011
	eatest	([a4,zd5.w*8],od.l)		;nnnn011101010011
	eatest	([a4,d5.l],od.l)		;nnnn100100010011
	eatest	([a4,d5.l*2],od.l)		;nnnn101100010011
	eatest	([a4,d5.l*4],od.l)		;nnnn110100010011
	eatest	([a4,d5.l*8],od.l)		;nnnn111100010011
	eatest	([a4,zd5.l],od.l)		;nnnn100101010011
	eatest	([a4,zd5.l*2],od.l)		;nnnn101101010011
	eatest	([a4,zd5.l*4],od.l)		;nnnn110101010011
	eatest	([a4,zd5.l*8],od.l)		;nnnn111101010011
	eatest	([a4],d5.w,od.l)		;nnnn000100010111
	eatest	([a4],d5.w*2,od.l)		;nnnn001100010111
	eatest	([a4],d5.w*4,od.l)		;nnnn010100010111
	eatest	([a4],d5.w*8,od.l)		;nnnn011100010111
	eatest	([a4],zd5.w,od.l)		;nnnn000101010111
	eatest	([a4],zd5.w*2,od.l)		;nnnn001101010111
	eatest	([a4],zd5.w*4,od.l)		;nnnn010101010111
	eatest	([a4],zd5.w*8,od.l)		;nnnn011101010111
	eatest	([a4],d5.l,od.l)		;nnnn100100010111
	eatest	([a4],d5.l*2,od.l)		;nnnn101100010111
	eatest	([a4],d5.l*4,od.l)		;nnnn110100010111
	eatest	([a4],d5.l*8,od.l)		;nnnn111100010111
	eatest	([a4],zd5.l,od.l)		;nnnn100101010111
	eatest	([a4],zd5.l*2,od.l)		;nnnn101101010111
	eatest	([a4],zd5.l*4,od.l)		;nnnn110101010111
	eatest	([a4],zd5.l*8,od.l)		;nnnn111101010111
  .endm
  .irp bd,$ffff8000,$00007ffc
	eatest	(bd.w,a4,d5.w)			;nnnn000100100000
	eatest	(bd.w,a4,d5.w*2)		;nnnn001100100000
	eatest	(bd.w,a4,d5.w*4)		;nnnn010100100000
	eatest	(bd.w,a4,d5.w*8)		;nnnn011100100000
	eatest	(bd.w,a4,zd5.w)			;nnnn000101100000
	eatest	(bd.w,a4,zd5.w*2)		;nnnn001101100000
	eatest	(bd.w,a4,zd5.w*4)		;nnnn010101100000
	eatest	(bd.w,a4,zd5.w*8)		;nnnn011101100000
	eatest	(bd.w,a4,d5.l)			;nnnn100100100000
	eatest	(bd.w,a4,d5.l*2)		;nnnn101100100000
	eatest	(bd.w,a4,d5.l*4)		;nnnn110100100000
	eatest	(bd.w,a4,d5.l*8)		;nnnn111100100000
	eatest	(bd.w,a4,zd5.l)			;nnnn100101100000
	eatest	(bd.w,a4,zd5.l*2)		;nnnn101101100000
	eatest	(bd.w,a4,zd5.l*4)		;nnnn110101100000
	eatest	(bd.w,a4,zd5.l*8)		;nnnn111101100000
  .endm
  .irp bd,$ffff8000,$00007ffc
	eatest	([bd.w,a4,d5.w])		;nnnn000100100001
	eatest	([bd.w,a4,d5.w*2])		;nnnn001100100001
	eatest	([bd.w,a4,d5.w*4])		;nnnn010100100001
	eatest	([bd.w,a4,d5.w*8])		;nnnn011100100001
	eatest	([bd.w,a4,zd5.w])		;nnnn000101100001
	eatest	([bd.w,a4,zd5.w*2])		;nnnn001101100001
	eatest	([bd.w,a4,zd5.w*4])		;nnnn010101100001
	eatest	([bd.w,a4,zd5.w*8])		;nnnn011101100001
	eatest	([bd.w,a4,d5.l])		;nnnn100100100001
	eatest	([bd.w,a4,d5.l*2])		;nnnn101100100001
	eatest	([bd.w,a4,d5.l*4])		;nnnn110100100001
	eatest	([bd.w,a4,d5.l*8])		;nnnn111100100001
	eatest	([bd.w,a4,zd5.l])		;nnnn100101100001
	eatest	([bd.w,a4,zd5.l*2])		;nnnn101101100001
	eatest	([bd.w,a4,zd5.l*4])		;nnnn110101100001
	eatest	([bd.w,a4,zd5.l*8])		;nnnn111101100001
	eatest	([bd.w,a4],d5.w)		;nnnn000100100101
	eatest	([bd.w,a4],d5.w*2)		;nnnn001100100101
	eatest	([bd.w,a4],d5.w*4)		;nnnn010100100101
	eatest	([bd.w,a4],d5.w*8)		;nnnn011100100101
	eatest	([bd.w,a4],zd5.w)		;nnnn000101100101
	eatest	([bd.w,a4],zd5.w*2)		;nnnn001101100101
	eatest	([bd.w,a4],zd5.w*4)		;nnnn010101100101
	eatest	([bd.w,a4],zd5.w*8)		;nnnn011101100101
	eatest	([bd.w,a4],d5.l)		;nnnn100100100101
	eatest	([bd.w,a4],d5.l*2)		;nnnn101100100101
	eatest	([bd.w,a4],d5.l*4)		;nnnn110100100101
	eatest	([bd.w,a4],d5.l*8)		;nnnn111100100101
	eatest	([bd.w,a4],zd5.l)		;nnnn100101100101
	eatest	([bd.w,a4],zd5.l*2)		;nnnn101101100101
	eatest	([bd.w,a4],zd5.l*4)		;nnnn110101100101
	eatest	([bd.w,a4],zd5.l*8)		;nnnn111101100101
    .irp od,$ffff8000,$00007ffc
	eatest	([bd.w,a4,d5.w],od.w)		;nnnn000100100010
	eatest	([bd.w,a4,d5.w*2],od.w)		;nnnn001100100010
	eatest	([bd.w,a4,d5.w*4],od.w)		;nnnn010100100010
	eatest	([bd.w,a4,d5.w*8],od.w)		;nnnn011100100010
	eatest	([bd.w,a4,zd5.w],od.w)		;nnnn000101100010
	eatest	([bd.w,a4,zd5.w*2],od.w)	;nnnn001101100010
	eatest	([bd.w,a4,zd5.w*4],od.w)	;nnnn010101100010
	eatest	([bd.w,a4,zd5.w*8],od.w)	;nnnn011101100010
	eatest	([bd.w,a4,d5.l],od.w)		;nnnn100100100010
	eatest	([bd.w,a4,d5.l*2],od.w)		;nnnn101100100010
	eatest	([bd.w,a4,d5.l*4],od.w)		;nnnn110100100010
	eatest	([bd.w,a4,d5.l*8],od.w)		;nnnn111100100010
	eatest	([bd.w,a4,zd5.l],od.w)		;nnnn100101100010
	eatest	([bd.w,a4,zd5.l*2],od.w)	;nnnn101101100010
	eatest	([bd.w,a4,zd5.l*4],od.w)	;nnnn110101100010
	eatest	([bd.w,a4,zd5.l*8],od.w)	;nnnn111101100010
	eatest	([bd.w,a4],d5.w,od.w)		;nnnn000100100110
	eatest	([bd.w,a4],d5.w*2,od.w)		;nnnn001100100110
	eatest	([bd.w,a4],d5.w*4,od.w)		;nnnn010100100110
	eatest	([bd.w,a4],d5.w*8,od.w)		;nnnn011100100110
	eatest	([bd.w,a4],zd5.w,od.w)		;nnnn000101100110
	eatest	([bd.w,a4],zd5.w*2,od.w)	;nnnn001101100110
	eatest	([bd.w,a4],zd5.w*4,od.w)	;nnnn010101100110
	eatest	([bd.w,a4],zd5.w*8,od.w)	;nnnn011101100110
	eatest	([bd.w,a4],d5.l,od.w)		;nnnn100100100110
	eatest	([bd.w,a4],d5.l*2,od.w)		;nnnn101100100110
	eatest	([bd.w,a4],d5.l*4,od.w)		;nnnn110100100110
	eatest	([bd.w,a4],d5.l*8,od.w)		;nnnn111100100110
	eatest	([bd.w,a4],zd5.l,od.w)		;nnnn100101100110
	eatest	([bd.w,a4],zd5.l*2,od.w)	;nnnn101101100110
	eatest	([bd.w,a4],zd5.l*4,od.w)	;nnnn110101100110
	eatest	([bd.w,a4],zd5.l*8,od.w)	;nnnn111101100110
    .endm
    .irp od,$ffff7ffc,$00008000
	eatest	([bd.w,a4,d5.w],od.l)		;nnnn000100100011
	eatest	([bd.w,a4,d5.w*2],od.l)		;nnnn001100100011
	eatest	([bd.w,a4,d5.w*4],od.l)		;nnnn010100100011
	eatest	([bd.w,a4,d5.w*8],od.l)		;nnnn011100100011
	eatest	([bd.w,a4,zd5.w],od.l)		;nnnn000101100011
	eatest	([bd.w,a4,zd5.w*2],od.l)	;nnnn001101100011
	eatest	([bd.w,a4,zd5.w*4],od.l)	;nnnn010101100011
	eatest	([bd.w,a4,zd5.w*8],od.l)	;nnnn011101100011
	eatest	([bd.w,a4,d5.l],od.l)		;nnnn100100100011
	eatest	([bd.w,a4,d5.l*2],od.l)		;nnnn101100100011
	eatest	([bd.w,a4,d5.l*4],od.l)		;nnnn110100100011
	eatest	([bd.w,a4,d5.l*8],od.l)		;nnnn111100100011
	eatest	([bd.w,a4,zd5.l],od.l)		;nnnn100101100011
	eatest	([bd.w,a4,zd5.l*2],od.l)	;nnnn101101100011
	eatest	([bd.w,a4,zd5.l*4],od.l)	;nnnn110101100011
	eatest	([bd.w,a4,zd5.l*8],od.l)	;nnnn111101100011
	eatest	([bd.w,a4],d5.w,od.l)		;nnnn000100100111
	eatest	([bd.w,a4],d5.w*2,od.l)		;nnnn001100100111
	eatest	([bd.w,a4],d5.w*4,od.l)		;nnnn010100100111
	eatest	([bd.w,a4],d5.w*8,od.l)		;nnnn011100100111
	eatest	([bd.w,a4],zd5.w,od.l)		;nnnn000101100111
	eatest	([bd.w,a4],zd5.w*2,od.l)	;nnnn001101100111
	eatest	([bd.w,a4],zd5.w*4,od.l)	;nnnn010101100111
	eatest	([bd.w,a4],zd5.w*8,od.l)	;nnnn011101100111
	eatest	([bd.w,a4],d5.l,od.l)		;nnnn100100100111
	eatest	([bd.w,a4],d5.l*2,od.l)		;nnnn101100100111
	eatest	([bd.w,a4],d5.l*4,od.l)		;nnnn110100100111
	eatest	([bd.w,a4],d5.l*8,od.l)		;nnnn111100100111
	eatest	([bd.w,a4],zd5.l,od.l)		;nnnn100101100111
	eatest	([bd.w,a4],zd5.l*2,od.l)	;nnnn101101100111
	eatest	([bd.w,a4],zd5.l*4,od.l)	;nnnn110101100111
	eatest	([bd.w,a4],zd5.l*8,od.l)	;nnnn111101100111
    .endm
  .endm
  .irp bd,$ffff7ffc,$00008000
	eatest	(bd.l,a4,d5.w)			;nnnn000100110000
	eatest	(bd.l,a4,d5.w*2)		;nnnn001100110000
	eatest	(bd.l,a4,d5.w*4)		;nnnn010100110000
	eatest	(bd.l,a4,d5.w*8)		;nnnn011100110000
	eatest	(bd.l,a4,zd5.w)			;nnnn000101110000
	eatest	(bd.l,a4,zd5.w*2)		;nnnn001101110000
	eatest	(bd.l,a4,zd5.w*4)		;nnnn010101110000
	eatest	(bd.l,a4,zd5.w*8)		;nnnn011101110000
	eatest	(bd.l,a4,d5.l)			;nnnn100100110000
	eatest	(bd.l,a4,d5.l*2)		;nnnn101100110000
	eatest	(bd.l,a4,d5.l*4)		;nnnn110100110000
	eatest	(bd.l,a4,d5.l*8)		;nnnn111100110000
	eatest	(bd.l,a4,zd5.l)			;nnnn100101110000
	eatest	(bd.l,a4,zd5.l*2)		;nnnn101101110000
	eatest	(bd.l,a4,zd5.l*4)		;nnnn110101110000
	eatest	(bd.l,a4,zd5.l*8)		;nnnn111101110000
  .endm
  .irp bd,$ffff7ffc,$00008000
	eatest	([bd.l,a4,d5.w])		;nnnn000100110001
	eatest	([bd.l,a4,d5.w*2])		;nnnn001100110001
	eatest	([bd.l,a4,d5.w*4])		;nnnn010100110001
	eatest	([bd.l,a4,d5.w*8])		;nnnn011100110001
	eatest	([bd.l,a4,zd5.w])		;nnnn000101110001
	eatest	([bd.l,a4,zd5.w*2])		;nnnn001101110001
	eatest	([bd.l,a4,zd5.w*4])		;nnnn010101110001
	eatest	([bd.l,a4,zd5.w*8])		;nnnn011101110001
	eatest	([bd.l,a4,d5.l])		;nnnn100100110001
	eatest	([bd.l,a4,d5.l*2])		;nnnn101100110001
	eatest	([bd.l,a4,d5.l*4])		;nnnn110100110001
	eatest	([bd.l,a4,d5.l*8])		;nnnn111100110001
	eatest	([bd.l,a4,zd5.l])		;nnnn100101110001
	eatest	([bd.l,a4,zd5.l*2])		;nnnn101101110001
	eatest	([bd.l,a4,zd5.l*4])		;nnnn110101110001
	eatest	([bd.l,a4,zd5.l*8])		;nnnn111101110001
	eatest	([bd.l,a4],d5.w)		;nnnn000100110101
	eatest	([bd.l,a4],d5.w*2)		;nnnn001100110101
	eatest	([bd.l,a4],d5.w*4)		;nnnn010100110101
	eatest	([bd.l,a4],d5.w*8)		;nnnn011100110101
	eatest	([bd.l,a4],zd5.w)		;nnnn000101110101
	eatest	([bd.l,a4],zd5.w*2)		;nnnn001101110101
	eatest	([bd.l,a4],zd5.w*4)		;nnnn010101110101
	eatest	([bd.l,a4],zd5.w*8)		;nnnn011101110101
	eatest	([bd.l,a4],d5.l)		;nnnn100100110101
	eatest	([bd.l,a4],d5.l*2)		;nnnn101100110101
	eatest	([bd.l,a4],d5.l*4)		;nnnn110100110101
	eatest	([bd.l,a4],d5.l*8)		;nnnn111100110101
	eatest	([bd.l,a4],zd5.l)		;nnnn100101110101
	eatest	([bd.l,a4],zd5.l*2)		;nnnn101101110101
	eatest	([bd.l,a4],zd5.l*4)		;nnnn110101110101
	eatest	([bd.l,a4],zd5.l*8)		;nnnn111101110101
    .irp od,$ffff8000,$00007ffc
	eatest	([bd.l,a4,d5.w],od.w)		;nnnn000100110010
	eatest	([bd.l,a4,d5.w*2],od.w)		;nnnn001100110010
	eatest	([bd.l,a4,d5.w*4],od.w)		;nnnn010100110010
	eatest	([bd.l,a4,d5.w*8],od.w)		;nnnn011100110010
	eatest	([bd.l,a4,zd5.w],od.w)		;nnnn000101110010
	eatest	([bd.l,a4,zd5.w*2],od.w)	;nnnn001101110010
	eatest	([bd.l,a4,zd5.w*4],od.w)	;nnnn010101110010
	eatest	([bd.l,a4,zd5.w*8],od.w)	;nnnn011101110010
	eatest	([bd.l,a4,d5.l],od.w)		;nnnn100100110010
	eatest	([bd.l,a4,d5.l*2],od.w)		;nnnn101100110010
	eatest	([bd.l,a4,d5.l*4],od.w)		;nnnn110100110010
	eatest	([bd.l,a4,d5.l*8],od.w)		;nnnn111100110010
	eatest	([bd.l,a4,zd5.l],od.w)		;nnnn100101110010
	eatest	([bd.l,a4,zd5.l*2],od.w)	;nnnn101101110010
	eatest	([bd.l,a4,zd5.l*4],od.w)	;nnnn110101110010
	eatest	([bd.l,a4,zd5.l*8],od.w)	;nnnn111101110010
	eatest	([bd.l,a4],d5.w,od.w)		;nnnn000100110110
	eatest	([bd.l,a4],d5.w*2,od.w)		;nnnn001100110110
	eatest	([bd.l,a4],d5.w*4,od.w)		;nnnn010100110110
	eatest	([bd.l,a4],d5.w*8,od.w)		;nnnn011100110110
	eatest	([bd.l,a4],zd5.w,od.w)		;nnnn000101110110
	eatest	([bd.l,a4],zd5.w*2,od.w)	;nnnn001101110110
	eatest	([bd.l,a4],zd5.w*4,od.w)	;nnnn010101110110
	eatest	([bd.l,a4],zd5.w*8,od.w)	;nnnn011101110110
	eatest	([bd.l,a4],d5.l,od.w)		;nnnn100100110110
	eatest	([bd.l,a4],d5.l*2,od.w)		;nnnn101100110110
	eatest	([bd.l,a4],d5.l*4,od.w)		;nnnn110100110110
	eatest	([bd.l,a4],d5.l*8,od.w)		;nnnn111100110110
	eatest	([bd.l,a4],zd5.l,od.w)		;nnnn100101110110
	eatest	([bd.l,a4],zd5.l*2,od.w)	;nnnn101101110110
	eatest	([bd.l,a4],zd5.l*4,od.w)	;nnnn110101110110
	eatest	([bd.l,a4],zd5.l*8,od.w)	;nnnn111101110110
    .endm
    .irp od,$ffff7ffc,$00008000
	eatest	([bd.l,a4,d5.w],od.l)		;nnnn000100110011
	eatest	([bd.l,a4,d5.w*2],od.l)		;nnnn001100110011
	eatest	([bd.l,a4,d5.w*4],od.l)		;nnnn010100110011
	eatest	([bd.l,a4,d5.w*8],od.l)		;nnnn011100110011
	eatest	([bd.l,a4,zd5.w],od.l)		;nnnn000101110011
	eatest	([bd.l,a4,zd5.w*2],od.l)	;nnnn001101110011
	eatest	([bd.l,a4,zd5.w*4],od.l)	;nnnn010101110011
	eatest	([bd.l,a4,zd5.w*8],od.l)	;nnnn011101110011
	eatest	([bd.l,a4,d5.l],od.l)		;nnnn100100110011
	eatest	([bd.l,a4,d5.l*2],od.l)		;nnnn101100110011
	eatest	([bd.l,a4,d5.l*4],od.l)		;nnnn110100110011
	eatest	([bd.l,a4,d5.l*8],od.l)		;nnnn111100110011
	eatest	([bd.l,a4,zd5.l],od.l)		;nnnn100101110011
	eatest	([bd.l,a4,zd5.l*2],od.l)	;nnnn101101110011
	eatest	([bd.l,a4,zd5.l*4],od.l)	;nnnn110101110011
	eatest	([bd.l,a4,zd5.l*8],od.l)	;nnnn111101110011
	eatest	([bd.l,a4],d5.w,od.l)		;nnnn000100110111
	eatest	([bd.l,a4],d5.w*2,od.l)		;nnnn001100110111
	eatest	([bd.l,a4],d5.w*4,od.l)		;nnnn010100110111
	eatest	([bd.l,a4],d5.w*8,od.l)		;nnnn011100110111
	eatest	([bd.l,a4],zd5.w,od.l)		;nnnn000101110111
	eatest	([bd.l,a4],zd5.w*2,od.l)	;nnnn001101110111
	eatest	([bd.l,a4],zd5.w*4,od.l)	;nnnn010101110111
	eatest	([bd.l,a4],zd5.w*8,od.l)	;nnnn011101110111
	eatest	([bd.l,a4],d5.l,od.l)		;nnnn100100110111
	eatest	([bd.l,a4],d5.l*2,od.l)		;nnnn101100110111
	eatest	([bd.l,a4],d5.l*4,od.l)		;nnnn110100110111
	eatest	([bd.l,a4],d5.l*8,od.l)		;nnnn111100110111
	eatest	([bd.l,a4],zd5.l,od.l)		;nnnn100101110111
	eatest	([bd.l,a4],zd5.l*2,od.l)	;nnnn101101110111
	eatest	([bd.l,a4],zd5.l*4,od.l)	;nnnn110101110111
	eatest	([bd.l,a4],zd5.l*8,od.l)	;nnnn111101110111
    .endm
  .endm
	zeatest	(za4,d5.w)			;nnnn000110010000
	zeatest	(za4,d5.w*2)			;nnnn001110010000
	zeatest	(za4,d5.w*4)			;nnnn010110010000
	zeatest	(za4,d5.w*8)			;nnnn011110010000
	zeatest	(za4,zd5.w)			;nnnn000111010000
	zeatest	(za4,zd5.w*2)			;nnnn001111010000
	zeatest	(za4,zd5.w*4)			;nnnn010111010000
	zeatest	(za4,zd5.w*8)			;nnnn011111010000
	zeatest	(za4,d5.l)			;nnnn100110010000
	zeatest	(za4,d5.l*2)			;nnnn101110010000
	zeatest	(za4,d5.l*4)			;nnnn110110010000
	zeatest	(za4,d5.l*8)			;nnnn111110010000
	zeatest	(za4,zd5.l)			;nnnn100111010000
	zeatest	(za4,zd5.l*2)			;nnnn101111010000
	zeatest	(za4,zd5.l*4)			;nnnn110111010000
	zeatest	(za4,zd5.l*8)			;nnnn111111010000
;	eatest	([za4,d5.w])			;nnnn000110010001
;	eatest	([za4,d5.w*2])			;nnnn001110010001
;	eatest	([za4,d5.w*4])			;nnnn010110010001
;	eatest	([za4,d5.w*8])			;nnnn011110010001
;	eatest	([za4,zd5.w])			;nnnn000111010001
;	eatest	([za4,zd5.w*2])			;nnnn001111010001
;	eatest	([za4,zd5.w*4])			;nnnn010111010001
;	eatest	([za4,zd5.w*8])			;nnnn011111010001
;	eatest	([za4,d5.l])			;nnnn100110010001
;	eatest	([za4,d5.l*2])			;nnnn101110010001
;	eatest	([za4,d5.l*4])			;nnnn110110010001
;	eatest	([za4,d5.l*8])			;nnnn111110010001
;	eatest	([za4,zd5.l])			;nnnn100111010001
;	eatest	([za4,zd5.l*2])			;nnnn101111010001
;	eatest	([za4,zd5.l*4])			;nnnn110111010001
;	eatest	([za4,zd5.l*8])			;nnnn111111010001
;	eatest	([za4],d5.w)			;nnnn000110010101
;	eatest	([za4],d5.w*2)			;nnnn001110010101
;	eatest	([za4],d5.w*4)			;nnnn010110010101
;	eatest	([za4],d5.w*8)			;nnnn011110010101
;	eatest	([za4],zd5.w)			;nnnn000111010101
;	eatest	([za4],zd5.w*2)			;nnnn001111010101
;	eatest	([za4],zd5.w*4)			;nnnn010111010101
;	eatest	([za4],zd5.w*8)			;nnnn011111010101
;	eatest	([za4],d5.l)			;nnnn100110010101
;	eatest	([za4],d5.l*2)			;nnnn101110010101
;	eatest	([za4],d5.l*4)			;nnnn110110010101
;	eatest	([za4],d5.l*8)			;nnnn111110010101
;	eatest	([za4],zd5.l)			;nnnn100111010101
;	eatest	([za4],zd5.l*2)			;nnnn101111010101
;	eatest	([za4],zd5.l*4)			;nnnn110111010101
;	eatest	([za4],zd5.l*8)			;nnnn111111010101
  .irp od,$ffff8000,$00007ffc
;	eatest	([za4,d5.w],od.w)		;nnnn000110010010
;	eatest	([za4,d5.w*2],od.w)		;nnnn001110010010
;	eatest	([za4,d5.w*4],od.w)		;nnnn010110010010
;	eatest	([za4,d5.w*8],od.w)		;nnnn011110010010
;	eatest	([za4,zd5.w],od.w)		;nnnn000111010010
;	eatest	([za4,zd5.w*2],od.w)		;nnnn001111010010
;	eatest	([za4,zd5.w*4],od.w)		;nnnn010111010010
;	eatest	([za4,zd5.w*8],od.w)		;nnnn011111010010
;	eatest	([za4,d5.l],od.w)		;nnnn100110010010
;	eatest	([za4,d5.l*2],od.w)		;nnnn101110010010
;	eatest	([za4,d5.l*4],od.w)		;nnnn110110010010
;	eatest	([za4,d5.l*8],od.w)		;nnnn111110010010
;	eatest	([za4,zd5.l],od.w)		;nnnn100111010010
;	eatest	([za4,zd5.l*2],od.w)		;nnnn101111010010
;	eatest	([za4,zd5.l*4],od.w)		;nnnn110111010010
;	eatest	([za4,zd5.l*8],od.w)		;nnnn111111010010
;	eatest	([za4],d5.w,od.w)		;nnnn000110010110
;	eatest	([za4],d5.w*2,od.w)		;nnnn001110010110
;	eatest	([za4],d5.w*4,od.w)		;nnnn010110010110
;	eatest	([za4],d5.w*8,od.w)		;nnnn011110010110
;	eatest	([za4],zd5.w,od.w)		;nnnn000111010110
;	eatest	([za4],zd5.w*2,od.w)		;nnnn001111010110
;	eatest	([za4],zd5.w*4,od.w)		;nnnn010111010110
;	eatest	([za4],zd5.w*8,od.w)		;nnnn011111010110
;	eatest	([za4],d5.l,od.w)		;nnnn100110010110
;	eatest	([za4],d5.l*2,od.w)		;nnnn101110010110
;	eatest	([za4],d5.l*4,od.w)		;nnnn110110010110
;	eatest	([za4],d5.l*8,od.w)		;nnnn111110010110
;	eatest	([za4],zd5.l,od.w)		;nnnn100111010110
;	eatest	([za4],zd5.l*2,od.w)		;nnnn101111010110
;	eatest	([za4],zd5.l*4,od.w)		;nnnn110111010110
;	eatest	([za4],zd5.l*8,od.w)		;nnnn111111010110
  .endm
  .irp od,$ffff7ffc,$00008000
;	eatest	([za4,d5.w],od.l)		;nnnn000110010011
;	eatest	([za4,d5.w*2],od.l)		;nnnn001110010011
;	eatest	([za4,d5.w*4],od.l)		;nnnn010110010011
;	eatest	([za4,d5.w*8],od.l)		;nnnn011110010011
;	eatest	([za4,zd5.w],od.l)		;nnnn000111010011
;	eatest	([za4,zd5.w*2],od.l)		;nnnn001111010011
;	eatest	([za4,zd5.w*4],od.l)		;nnnn010111010011
;	eatest	([za4,zd5.w*8],od.l)		;nnnn011111010011
;	eatest	([za4,d5.l],od.l)		;nnnn100110010011
;	eatest	([za4,d5.l*2],od.l)		;nnnn101110010011
;	eatest	([za4,d5.l*4],od.l)		;nnnn110110010011
;	eatest	([za4,d5.l*8],od.l)		;nnnn111110010011
;	eatest	([za4,zd5.l],od.l)		;nnnn100111010011
;	eatest	([za4,zd5.l*2],od.l)		;nnnn101111010011
;	eatest	([za4,zd5.l*4],od.l)		;nnnn110111010011
;	eatest	([za4,zd5.l*8],od.l)		;nnnn111111010011
;	eatest	([za4],d5.w,od.l)		;nnnn000110010111
;	eatest	([za4],d5.w*2,od.l)		;nnnn001110010111
;	eatest	([za4],d5.w*4,od.l)		;nnnn010110010111
;	eatest	([za4],d5.w*8,od.l)		;nnnn011110010111
;	eatest	([za4],zd5.w,od.l)		;nnnn000111010111
;	eatest	([za4],zd5.w*2,od.l)		;nnnn001111010111
;	eatest	([za4],zd5.w*4,od.l)		;nnnn010111010111
;	eatest	([za4],zd5.w*8,od.l)		;nnnn011111010111
;	eatest	([za4],d5.l,od.l)		;nnnn100110010111
;	eatest	([za4],d5.l*2,od.l)		;nnnn101110010111
;	eatest	([za4],d5.l*4,od.l)		;nnnn110110010111
;	eatest	([za4],d5.l*8,od.l)		;nnnn111110010111
;	eatest	([za4],zd5.l,od.l)		;nnnn100111010111
;	eatest	([za4],zd5.l*2,od.l)		;nnnn101111010111
;	eatest	([za4],zd5.l*4,od.l)		;nnnn110111010111
;	eatest	([za4],zd5.l*8,od.l)		;nnnn111111010111
  .endm
  .irp bd,$ffff8000,$00007ffc
	zeatest	(bd.w,za4,d5.w)			;nnnn000110100000
	zeatest	(bd.w,za4,d5.w*2)		;nnnn001110100000
	zeatest	(bd.w,za4,d5.w*4)		;nnnn010110100000
	zeatest	(bd.w,za4,d5.w*8)		;nnnn011110100000
	zeatest	(bd.w,za4,zd5.w)		;nnnn000111100000
	zeatest	(bd.w,za4,zd5.w*2)		;nnnn001111100000
	zeatest	(bd.w,za4,zd5.w*4)		;nnnn010111100000
	zeatest	(bd.w,za4,zd5.w*8)		;nnnn011111100000
	zeatest	(bd.w,za4,d5.l)			;nnnn100110100000
	zeatest	(bd.w,za4,d5.l*2)		;nnnn101110100000
	zeatest	(bd.w,za4,d5.l*4)		;nnnn110110100000
	zeatest	(bd.w,za4,d5.l*8)		;nnnn111110100000
	zeatest	(bd.w,za4,zd5.l)		;nnnn100111100000
	zeatest	(bd.w,za4,zd5.l*2)		;nnnn101111100000
	zeatest	(bd.w,za4,zd5.l*4)		;nnnn110111100000
	zeatest	(bd.w,za4,zd5.l*8)		;nnnn111111100000
  .endm
  .irp bd,$ffff8000,$00007ffc
;	eatest	([bd.w,za4,d5.w])		;nnnn000110100001
;	eatest	([bd.w,za4,d5.w*2])		;nnnn001110100001
;	eatest	([bd.w,za4,d5.w*4])		;nnnn010110100001
;	eatest	([bd.w,za4,d5.w*8])		;nnnn011110100001
;	eatest	([bd.w,za4,zd5.w])		;nnnn000111100001
;	eatest	([bd.w,za4,zd5.w*2])		;nnnn001111100001
;	eatest	([bd.w,za4,zd5.w*4])		;nnnn010111100001
;	eatest	([bd.w,za4,zd5.w*8])		;nnnn011111100001
;	eatest	([bd.w,za4,d5.l])		;nnnn100110100001
;	eatest	([bd.w,za4,d5.l*2])		;nnnn101110100001
;	eatest	([bd.w,za4,d5.l*4])		;nnnn110110100001
;	eatest	([bd.w,za4,d5.l*8])		;nnnn111110100001
;	eatest	([bd.w,za4,zd5.l])		;nnnn100111100001
;	eatest	([bd.w,za4,zd5.l*2])		;nnnn101111100001
;	eatest	([bd.w,za4,zd5.l*4])		;nnnn110111100001
;	eatest	([bd.w,za4,zd5.l*8])		;nnnn111111100001
;	eatest	([bd.w,za4],d5.w)		;nnnn000110100101
;	eatest	([bd.w,za4],d5.w*2)		;nnnn001110100101
;	eatest	([bd.w,za4],d5.w*4)		;nnnn010110100101
;	eatest	([bd.w,za4],d5.w*8)		;nnnn011110100101
;	eatest	([bd.w,za4],zd5.w)		;nnnn000111100101
;	eatest	([bd.w,za4],zd5.w*2)		;nnnn001111100101
;	eatest	([bd.w,za4],zd5.w*4)		;nnnn010111100101
;	eatest	([bd.w,za4],zd5.w*8)		;nnnn011111100101
;	eatest	([bd.w,za4],d5.l)		;nnnn100110100101
;	eatest	([bd.w,za4],d5.l*2)		;nnnn101110100101
;	eatest	([bd.w,za4],d5.l*4)		;nnnn110110100101
;	eatest	([bd.w,za4],d5.l*8)		;nnnn111110100101
;	eatest	([bd.w,za4],zd5.l)		;nnnn100111100101
;	eatest	([bd.w,za4],zd5.l*2)		;nnnn101111100101
;	eatest	([bd.w,za4],zd5.l*4)		;nnnn110111100101
;	eatest	([bd.w,za4],zd5.l*8)		;nnnn111111100101
    .irp od,$ffff8000,$00007ffc
;	eatest	([bd.w,za4,d5.w],od.w)		;nnnn000110100010
;	eatest	([bd.w,za4,d5.w*2],od.w)	;nnnn001110100010
;	eatest	([bd.w,za4,d5.w*4],od.w)	;nnnn010110100010
;	eatest	([bd.w,za4,d5.w*8],od.w)	;nnnn011110100010
;	eatest	([bd.w,za4,zd5.w],od.w)		;nnnn000111100010
;	eatest	([bd.w,za4,zd5.w*2],od.w)	;nnnn001111100010
;	eatest	([bd.w,za4,zd5.w*4],od.w)	;nnnn010111100010
;	eatest	([bd.w,za4,zd5.w*8],od.w)	;nnnn011111100010
;	eatest	([bd.w,za4,d5.l],od.w)		;nnnn100110100010
;	eatest	([bd.w,za4,d5.l*2],od.w)	;nnnn101110100010
;	eatest	([bd.w,za4,d5.l*4],od.w)	;nnnn110110100010
;	eatest	([bd.w,za4,d5.l*8],od.w)	;nnnn111110100010
;	eatest	([bd.w,za4,zd5.l],od.w)		;nnnn100111100010
;	eatest	([bd.w,za4,zd5.l*2],od.w)	;nnnn101111100010
;	eatest	([bd.w,za4,zd5.l*4],od.w)	;nnnn110111100010
;	eatest	([bd.w,za4,zd5.l*8],od.w)	;nnnn111111100010
;	eatest	([bd.w,za4],d5.w,od.w)		;nnnn000110100110
;	eatest	([bd.w,za4],d5.w*2,od.w)	;nnnn001110100110
;	eatest	([bd.w,za4],d5.w*4,od.w)	;nnnn010110100110
;	eatest	([bd.w,za4],d5.w*8,od.w)	;nnnn011110100110
;	eatest	([bd.w,za4],zd5.w,od.w)		;nnnn000111100110
;	eatest	([bd.w,za4],zd5.w*2,od.w)	;nnnn001111100110
;	eatest	([bd.w,za4],zd5.w*4,od.w)	;nnnn010111100110
;	eatest	([bd.w,za4],zd5.w*8,od.w)	;nnnn011111100110
;	eatest	([bd.w,za4],d5.l,od.w)		;nnnn100110100110
;	eatest	([bd.w,za4],d5.l*2,od.w)	;nnnn101110100110
;	eatest	([bd.w,za4],d5.l*4,od.w)	;nnnn110110100110
;	eatest	([bd.w,za4],d5.l*8,od.w)	;nnnn111110100110
;	eatest	([bd.w,za4],zd5.l,od.w)		;nnnn100111100110
;	eatest	([bd.w,za4],zd5.l*2,od.w)	;nnnn101111100110
;	eatest	([bd.w,za4],zd5.l*4,od.w)	;nnnn110111100110
;	eatest	([bd.w,za4],zd5.l*8,od.w)	;nnnn111111100110
    .endm
    .irp od,$ffff7ffc,$00008000
;	eatest	([bd.w,za4,d5.w],od.l)		;nnnn000110100011
;	eatest	([bd.w,za4,d5.w*2],od.l)	;nnnn001110100011
;	eatest	([bd.w,za4,d5.w*4],od.l)	;nnnn010110100011
;	eatest	([bd.w,za4,d5.w*8],od.l)	;nnnn011110100011
;	eatest	([bd.w,za4,zd5.w],od.l)		;nnnn000111100011
;	eatest	([bd.w,za4,zd5.w*2],od.l)	;nnnn001111100011
;	eatest	([bd.w,za4,zd5.w*4],od.l)	;nnnn010111100011
;	eatest	([bd.w,za4,zd5.w*8],od.l)	;nnnn011111100011
;	eatest	([bd.w,za4,d5.l],od.l)		;nnnn100110100011
;	eatest	([bd.w,za4,d5.l*2],od.l)	;nnnn101110100011
;	eatest	([bd.w,za4,d5.l*4],od.l)	;nnnn110110100011
;	eatest	([bd.w,za4,d5.l*8],od.l)	;nnnn111110100011
;	eatest	([bd.w,za4,zd5.l],od.l)		;nnnn100111100011
;	eatest	([bd.w,za4,zd5.l*2],od.l)	;nnnn101111100011
;	eatest	([bd.w,za4,zd5.l*4],od.l)	;nnnn110111100011
;	eatest	([bd.w,za4,zd5.l*8],od.l)	;nnnn111111100011
;	eatest	([bd.w,za4],d5.w,od.l)		;nnnn000110100111
;	eatest	([bd.w,za4],d5.w*2,od.l)	;nnnn001110100111
;	eatest	([bd.w,za4],d5.w*4,od.l)	;nnnn010110100111
;	eatest	([bd.w,za4],d5.w*8,od.l)	;nnnn011110100111
;	eatest	([bd.w,za4],zd5.w,od.l)		;nnnn000111100111
;	eatest	([bd.w,za4],zd5.w*2,od.l)	;nnnn001111100111
;	eatest	([bd.w,za4],zd5.w*4,od.l)	;nnnn010111100111
;	eatest	([bd.w,za4],zd5.w*8,od.l)	;nnnn011111100111
;	eatest	([bd.w,za4],d5.l,od.l)		;nnnn100110100111
;	eatest	([bd.w,za4],d5.l*2,od.l)	;nnnn101110100111
;	eatest	([bd.w,za4],d5.l*4,od.l)	;nnnn110110100111
;	eatest	([bd.w,za4],d5.l*8,od.l)	;nnnn111110100111
;	eatest	([bd.w,za4],zd5.l,od.l)		;nnnn100111100111
;	eatest	([bd.w,za4],zd5.l*2,od.l)	;nnnn101111100111
;	eatest	([bd.w,za4],zd5.l*4,od.l)	;nnnn110111100111
;	eatest	([bd.w,za4],zd5.l*8,od.l)	;nnnn111111100111
    .endm
  .endm
  .irp bd,$ffff8000,$00007ffc
	zeatest	(bd.l,za4,d5.w)			;nnnn000110110000
	zeatest	(bd.l,za4,d5.w*2)		;nnnn001110110000
	zeatest	(bd.l,za4,d5.w*4)		;nnnn010110110000
	zeatest	(bd.l,za4,d5.w*8)		;nnnn011110110000
	zeatest	(bd.l,za4,zd5.w)		;nnnn000111110000
	zeatest	(bd.l,za4,zd5.w*2)		;nnnn001111110000
	zeatest	(bd.l,za4,zd5.w*4)		;nnnn010111110000
	zeatest	(bd.l,za4,zd5.w*8)		;nnnn011111110000
	zeatest	(bd.l,za4,d5.l)			;nnnn100110110000
	zeatest	(bd.l,za4,d5.l*2)		;nnnn101110110000
	zeatest	(bd.l,za4,d5.l*4)		;nnnn110110110000
	zeatest	(bd.l,za4,d5.l*8)		;nnnn111110110000
	zeatest	(bd.l,za4,zd5.l)		;nnnn100111110000
	zeatest	(bd.l,za4,zd5.l*2)		;nnnn101111110000
	zeatest	(bd.l,za4,zd5.l*4)		;nnnn110111110000
	zeatest	(bd.l,za4,zd5.l*8)		;nnnn111111110000
  .endm
  .irp bd,work_area+4096
	eatest	([bd.l,za4,d5.w])		;nnnn000110110001
	eatest	([bd.l,za4,d5.w*2])		;nnnn001110110001
	eatest	([bd.l,za4,d5.w*4])		;nnnn010110110001
	eatest	([bd.l,za4,d5.w*8])		;nnnn011110110001
	eatest	([bd.l,za4,zd5.w])		;nnnn000111110001
	eatest	([bd.l,za4,zd5.w*2])		;nnnn001111110001
	eatest	([bd.l,za4,zd5.w*4])		;nnnn010111110001
	eatest	([bd.l,za4,zd5.w*8])		;nnnn011111110001
	eatest	([bd.l,za4,d5.l])		;nnnn100110110001
	eatest	([bd.l,za4,d5.l*2])		;nnnn101110110001
	eatest	([bd.l,za4,d5.l*4])		;nnnn110110110001
	eatest	([bd.l,za4,d5.l*8])		;nnnn111110110001
	eatest	([bd.l,za4,zd5.l])		;nnnn100111110001
	eatest	([bd.l,za4,zd5.l*2])		;nnnn101111110001
	eatest	([bd.l,za4,zd5.l*4])		;nnnn110111110001
	eatest	([bd.l,za4,zd5.l*8])		;nnnn111111110001
	eatest	([bd.l,za4],d5.w)		;nnnn000110110101
	eatest	([bd.l,za4],d5.w*2)		;nnnn001110110101
	eatest	([bd.l,za4],d5.w*4)		;nnnn010110110101
	eatest	([bd.l,za4],d5.w*8)		;nnnn011110110101
	eatest	([bd.l,za4],zd5.w)		;nnnn000111110101
	eatest	([bd.l,za4],zd5.w*2)		;nnnn001111110101
	eatest	([bd.l,za4],zd5.w*4)		;nnnn010111110101
	eatest	([bd.l,za4],zd5.w*8)		;nnnn011111110101
	eatest	([bd.l,za4],d5.l)		;nnnn100110110101
	eatest	([bd.l,za4],d5.l*2)		;nnnn101110110101
	eatest	([bd.l,za4],d5.l*4)		;nnnn110110110101
	eatest	([bd.l,za4],d5.l*8)		;nnnn111110110101
	eatest	([bd.l,za4],zd5.l)		;nnnn100111110101
	eatest	([bd.l,za4],zd5.l*2)		;nnnn101111110101
	eatest	([bd.l,za4],zd5.l*4)		;nnnn110111110101
	eatest	([bd.l,za4],zd5.l*8)		;nnnn111111110101
    .irp od,$ffff8000,$00007ffc
	eatest	([bd.l,za4,d5.w],od.w)		;nnnn000110110010
	eatest	([bd.l,za4,d5.w*2],od.w)	;nnnn001110110010
	eatest	([bd.l,za4,d5.w*4],od.w)	;nnnn010110110010
	eatest	([bd.l,za4,d5.w*8],od.w)	;nnnn011110110010
	eatest	([bd.l,za4,zd5.w],od.w)		;nnnn000111110010
	eatest	([bd.l,za4,zd5.w*2],od.w)	;nnnn001111110010
	eatest	([bd.l,za4,zd5.w*4],od.w)	;nnnn010111110010
	eatest	([bd.l,za4,zd5.w*8],od.w)	;nnnn011111110010
	eatest	([bd.l,za4,d5.l],od.w)		;nnnn100110110010
	eatest	([bd.l,za4,d5.l*2],od.w)	;nnnn101110110010
	eatest	([bd.l,za4,d5.l*4],od.w)	;nnnn110110110010
	eatest	([bd.l,za4,d5.l*8],od.w)	;nnnn111110110010
	eatest	([bd.l,za4,zd5.l],od.w)		;nnnn100111110010
	eatest	([bd.l,za4,zd5.l*2],od.w)	;nnnn101111110010
	eatest	([bd.l,za4,zd5.l*4],od.w)	;nnnn110111110010
	eatest	([bd.l,za4,zd5.l*8],od.w)	;nnnn111111110010
	eatest	([bd.l,za4],d5.w,od.w)		;nnnn000110110110
	eatest	([bd.l,za4],d5.w*2,od.w)	;nnnn001110110110
	eatest	([bd.l,za4],d5.w*4,od.w)	;nnnn010110110110
	eatest	([bd.l,za4],d5.w*8,od.w)	;nnnn011110110110
	eatest	([bd.l,za4],zd5.w,od.w)		;nnnn000111110110
	eatest	([bd.l,za4],zd5.w*2,od.w)	;nnnn001111110110
	eatest	([bd.l,za4],zd5.w*4,od.w)	;nnnn010111110110
	eatest	([bd.l,za4],zd5.w*8,od.w)	;nnnn011111110110
	eatest	([bd.l,za4],d5.l,od.w)		;nnnn100110110110
	eatest	([bd.l,za4],d5.l*2,od.w)	;nnnn101110110110
	eatest	([bd.l,za4],d5.l*4,od.w)	;nnnn110110110110
	eatest	([bd.l,za4],d5.l*8,od.w)	;nnnn111110110110
	eatest	([bd.l,za4],zd5.l,od.w)		;nnnn100111110110
	eatest	([bd.l,za4],zd5.l*2,od.w)	;nnnn101111110110
	eatest	([bd.l,za4],zd5.l*4,od.w)	;nnnn110111110110
	eatest	([bd.l,za4],zd5.l*8,od.w)	;nnnn111111110110
    .endm
    .irp od,$ffff7ffc,$00008000
	eatest	([bd.l,za4,d5.w],od.l)		;nnnn000110110011
	eatest	([bd.l,za4,d5.w*2],od.l)	;nnnn001110110011
	eatest	([bd.l,za4,d5.w*4],od.l)	;nnnn010110110011
	eatest	([bd.l,za4,d5.w*8],od.l)	;nnnn011110110011
	eatest	([bd.l,za4,zd5.w],od.l)		;nnnn000111110011
	eatest	([bd.l,za4,zd5.w*2],od.l)	;nnnn001111110011
	eatest	([bd.l,za4,zd5.w*4],od.l)	;nnnn010111110011
	eatest	([bd.l,za4,zd5.w*8],od.l)	;nnnn011111110011
	eatest	([bd.l,za4,d5.l],od.l)		;nnnn100110110011
	eatest	([bd.l,za4,d5.l*2],od.l)	;nnnn101110110011
	eatest	([bd.l,za4,d5.l*4],od.l)	;nnnn110110110011
	eatest	([bd.l,za4,d5.l*8],od.l)	;nnnn111110110011
	eatest	([bd.l,za4,zd5.l],od.l)		;nnnn100111110011
	eatest	([bd.l,za4,zd5.l*2],od.l)	;nnnn101111110011
	eatest	([bd.l,za4,zd5.l*4],od.l)	;nnnn110111110011
	eatest	([bd.l,za4,zd5.l*8],od.l)	;nnnn111111110011
	eatest	([bd.l,za4],d5.w,od.l)		;nnnn000110110111
	eatest	([bd.l,za4],d5.w*2,od.l)	;nnnn001110110111
	eatest	([bd.l,za4],d5.w*4,od.l)	;nnnn010110110111
	eatest	([bd.l,za4],d5.w*8,od.l)	;nnnn011110110111
	eatest	([bd.l,za4],zd5.w,od.l)		;nnnn000111110111
	eatest	([bd.l,za4],zd5.w*2,od.l)	;nnnn001111110111
	eatest	([bd.l,za4],zd5.w*4,od.l)	;nnnn010111110111
	eatest	([bd.l,za4],zd5.w*8,od.l)	;nnnn011111110111
	eatest	([bd.l,za4],d5.l,od.l)		;nnnn100110110111
	eatest	([bd.l,za4],d5.l*2,od.l)	;nnnn101110110111
	eatest	([bd.l,za4],d5.l*4,od.l)	;nnnn110110110111
	eatest	([bd.l,za4],d5.l*8,od.l)	;nnnn111110110111
	eatest	([bd.l,za4],zd5.l,od.l)		;nnnn100111110111
	eatest	([bd.l,za4],zd5.l*2,od.l)	;nnnn101111110111
	eatest	([bd.l,za4],zd5.l*4,od.l)	;nnnn110111110111
	eatest	([bd.l,za4],zd5.l*8,od.l)	;nnnn111111110111
    .endm
  .endm
	move.l	#crc,d1
	jbsr	test_check
	catch_illegal_instruction
@skip:
	.endm


;--------------------------------------------------------------------------------
;main

	.text
	.even

main:
	lea.l	(16,a0),a0
	suba.l	a0,a1
	movem.l	a0-a1,-(sp)
	DOS	_SETBLOCK
	addq.l	#8,sp

	lea.l	stack_area_end,sp

	lea.l	1(a2),a0

1:	move.b	(a0)+,d0
	beq	2f
	cmp.b	#' ',d0
	bls	1b
2:	subq.l	#1,a0

	tst.b	(a0)
	bne	@f
	print	'usage: instructiontest <leading letters of a mnemonic | all | easy | hard> ...',13,10
	jbra	exit
@@:

	move.l	a0,mnemonic_pointer

	jbsr	mpu_check
	move.b	d0,mpu_type		;0=MC68000,1=MC68010,2=MC68020,3=MC68030,4=MC68040,6=MC68060
	moveq.l	#1,d1
	lsl.b	d0,d1
	move.b	d1,mpu_mask		;1=MC68000,2=MC68010,4=MC68020,8=MC68030,16=MC68040,64=MC68060

	lea.l	test_flag,a0
	moveq.l	#0,d0
	move.l	#TEST_LIMIT/4-1,d1
	swap.w	d1
1:	swap.w	d1
2:	move.l	d0,(a0)+
	dbra	d1,2b
	swap.w	d1
	dbra	d1,1b

	st.b	last_level
	move.b	#EASY,test_level

;start
	jbsr	test_start

	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,old_ctrlvc
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCG
	addq.l	#2,sp
	move.l	d0,old_errjvc
	pea.l	new_ctrlvc
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	pea.l	new_errjvc
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp

	pea.l	new_illegal_instruction
	move.w	#4,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,old_illegal_instruction

	pea.l	new_divide_by_zero
	move.w	#5,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,old_divide_by_zero

	pea.l	new_chk_instruction
	move.w	#6,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,old_chk_instruction

	pea.l	new_trapv_instruction
	move.w	#7,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,old_trapv_instruction

	pea.l	new_privilege_instruction
	move.w	#8,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	d0,old_privilege_instruction

	pea.l	new_timerc_handler
	move.w	#69,-(sp)
	DOS	_INTVCG
	move.l	d0,old_timerc_handler
	DOS	_INTVCS
	addq.l	#6,sp

	move.l	timerc_counter,test_started

mnemonic_loop:
	movea.l	mnemonic_pointer,a0

1:	move.b	(a0)+,d0
	beq	2f
	cmp.b	#' ',d0
	bls	1b
2:	subq.l	#1,a0

	tst.b	(a0)
	jbeq	mnemonic_done

	lea.l	mnemonic_buffer,a1
	move.w	#256,d1
	bra	2f
1:	or.b	#$20,d0
	move.b	d0,(a1)+
2:	move.b	(a0)+,d0
	cmp.b	#' ',d0
	dbls	d1,1b
	sf.b	(a1)
	subq.l	#1,a0

	move.l	a0,mnemonic_pointer

	lea.l	mnemonic_buffer,a1
	cmpi.l	#'easy',(a1)+
	bne	@f
	tst.b	(a1)
	bne	@f
	move.b	#EASY,test_level
	jbra	mnemonic_loop
@@:

	lea.l	mnemonic_buffer,a1
	cmpi.l	#'hard',(a1)+
	bne	@f
	tst.b	(a1)
	bne	@f
	move.b	#HARD,test_level
	jbra	mnemonic_loop
@@:

	moveq.l	#MC68000|MC68010,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	abcdsbcdeasy_drb_drb	abcd.b,$59d7dfd3	;ABCD.B Dr,Dq
	abcdsbcdeasy_mnb_mnb	abcd.b,$d4e484fa	;ABCD.B -(Ar),-(Aq)
	bra	2f
1:
	abcdsbcdhard_drb_drb	abcd.b,$2f8ac5e7	;ABCD.B Dr,Dq
	abcdsbcdhard_mnb_mnb	abcd.b,$8e0dfdbe	;ABCD.B -(Ar),-(Aq)
2:
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	abcdsbcdeasy_drb_drb	abcd.b,$59d7dfd3	;ABCD.B Dr,Dq
	abcdsbcdeasy_mnb_mnb	abcd.b,$d4e484fa	;ABCD.B -(Ar),-(Aq)
	bra	2f
1:
	abcdsbcdhard_drb_drb	abcd.b,$025d857b	;ABCD.B Dr,Dq
	abcdsbcdhard_mnb_mnb	abcd.b,$1507632d	;ABCD.B -(Ar),-(Aq)
2:
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	abcdsbcdeasy_drb_drb	abcd.b,$59d7dfd3	;ABCD.B Dr,Dq
	abcdsbcdeasy_mnb_mnb	abcd.b,$d4e484fa	;ABCD.B -(Ar),-(Aq)
	bra	2f
1:
	abcdsbcdhard_drb_drb	abcd.b,$fddca661	;ABCD.B Dr,Dq
	abcdsbcdhard_mnb_mnb	abcd.b,$116c5546	;ABCD.B -(Ar),-(Aq)
2:
@@:

	xxx_drb_drb	add.b,$ba2388e4		;ADD.B Dr,Dq
	xxx_drw_drw	add.w,$e7fbc8a3		;ADD.W Dr,Dq
	xxx_drl_drl	add.l,$bcce150b		;ADD.L Dr,Dq
	xxx_mmb_drb	add.b,$d51d248c		;ADD.B (Ar),Dq
	xxx_mmw_drw	add.w,$ba317a97		;ADD.W (Ar),Dq
	xxx_mml_drl	add.l,$bcce150b		;ADD.L (Ar),Dq
	xxx_drb_mmb	add.b,$ae0b2d84		;ADD.B Dq,(Ar)
	xxx_drw_mmw	add.w,$c411000e		;ADD.W Dq,(Ar)
	xxx_drl_mml	add.l,$bcce150b		;ADD.L Dq,(Ar)

	xxx_drw_arl	adda.w,$7864b4b2	;ADDA.W Dr,Aq
	xxx_drl_arl	adda.l,$a980d2b5	;ADDA.L Dr,Aq
	xxx_mmw_arl	adda.w,$d3c15716	;ADDA.W (Ar),Aq
	xxx_mml_arl	adda.l,$20741812	;ADDA.L (Ar),Aq

	xxx_imb_drb	addi.b,$1cf462ed	;ADDI.B #<data>,Dr
	xxx_imw_drw	addi.w,$7db2b5b4	;ADDI.W #<data>,Dr
	xxx_iml_drl	addi.l,$0c100f02	;ADDI.L #<data>,Dr
	xxx_imb_mmb	addi.b,$661d15de	;ADDI.B #<data>,(Ar)
	xxx_imw_mmw	addi.w,$ad31479e	;ADDI.W #<data>,(Ar)
	xxx_iml_mml	addi.l,$0c100f02	;ADDI.L #<data>,(Ar)

	xxx_imq_drb	addq.b,$a47e166d	;ADDQ.B #<data>,Dr
	xxx_imq_drw	addq.w,$f99f4288	;ADDQ.W #<data>,Dr
	xxx_imq_drl	addq.l,$6f991231	;ADDQ.L #<data>,Dr
	xxx_imq_arl	addq.w,$837f7bcb	;ADDQ.W #<data>,Ar
	xxx_imq_arl	addq.l,$837f7bcb	;ADDQ.L #<data>,Ar
	xxx_imq_mmb	addq.b,$b6580973	;ADDQ.B #<data>,(Ar)
	xxx_imq_mmw	addq.w,$9a7931c6	;ADDQ.W #<data>,(Ar)
	xxx_imq_mml	addq.l,$6f991231	;ADDQ.L #<data>,(Ar)

	xxx_drb_drb	addx.b,$dbeda5fd	;ADDX.B Dr,Dq
	xxx_drw_drw	addx.w,$b3454229	;ADDX.W Dr,Dq
	xxx_drl_drl	addx.l,$037a85ec	;ADDX.L Dr,Dq
	xxx_mnb_mnb	addx.b,$ad13c3b2	;ADDX.B -(Ar),-(Aq)
	xxx_mnw_mnw	addx.w,$cbd5b63e	;ADDX.W -(Ar),-(Aq)
	xxx_mnl_mnl	addx.l,$15bb9917	;ADDX.L -(Ar),-(Aq)

	xxx_drb_drb	and.b,$41906e18		;AND.B Dr,Dq
	xxx_drw_drw	and.w,$2c0daaca		;AND.W Dr,Dq
	xxx_drl_drl	and.l,$fba5ea39		;AND.L Dr,Dq
	xxx_mmb_drb	and.b,$3dfbf163		;AND.B (Ar),Dq
	xxx_mmw_drw	and.w,$71c718fe		;AND.W (Ar),Dq
	xxx_mml_drl	and.l,$fba5ea39		;AND.L (Ar),Dq
	xxx_drb_mmb	and.b,$a279336d		;AND.B Dq,(Ar)
	xxx_drw_mmw	and.w,$f3f87216		;AND.W Dq,(Ar)
	xxx_drl_mml	and.l,$fba5ea39		;AND.L Dq,(Ar)

	xxx_imb_drb	andi.b,$9f44215b	;ANDI.B #<data>,Dr
	xxx_imw_drw	andi.w,$3b8fda41	;ANDI.W #<data>,Dr
	xxx_iml_drl	andi.l,$0f8a9ec3	;ANDI.L #<data>,Dr
	xxx_imb_mmb	andi.b,$bd297b8c	;ANDI.B #<data>,(Ar)
	xxx_imw_mmw	andi.w,$914857b2	;ANDI.W #<data>,(Ar)
	xxx_iml_mml	andi.l,$0f8a9ec3	;ANDI.L #<data>,(Ar)
	xxx_imb_ccr	andi.b,$2239fcb1	;ANDI.B #<data>,CCR
						;ANDI.W #<data>,SR

	xxx_drb_drb	asl.b,$bc2668b3		;ASL.B Dq,Dr
	xxx_drb_drw	asl.w,$7e0628a0		;ASL.W Dq,Dr
	xxx_drb_drl	asl.l,$35441d94		;ASL.L Dq,Dr
	xxx_imq_drb	asl.b,$f93dfea2		;ASL.B #<data>,Dr
	xxx_imq_drw	asl.w,$79d85741		;ASL.W #<data>,Dr
	xxx_imq_drl	asl.l,$fc0300fd		;ASL.L #<data>,Dr
	xxx_mmw		asl.w,$8b85b807		;ASL.W (Ar)

	xxx_drb_drb	asr.b,$69a8ec67		;ASR.B Dq,Dr
	xxx_drb_drw	asr.w,$9907c874		;ASR.W Dq,Dr
	xxx_drb_drl	asr.l,$92b17ac0		;ASR.L Dq,Dr
	xxx_imq_drb	asr.b,$aae7c02a		;ASR.B #<data>,Dr
	xxx_imq_drw	asr.w,$51ab942a		;ASR.W #<data>,Dr
	xxx_imq_drl	asr.l,$7f105dd0		;ASR.L #<data>,Dr
	xxx_mmw		asr.w,$b5dc712e		;ASR.W (Ar)

	bcc_label	bcc.s,$f30675e0		;BCC.S <label>
	bcc_label	bcc.w,$f30675e0		;BCC.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bcc.l,$f30675e0		;BCC.L <label>
	.cpu	68000
@@:

	xxx_drb_drl	bchg.l,$4cab4c59	;BCHG.L Dq,Dr
	xxx_im5_drl	bchg.l,$4765144d	;BCHG.L #<data>,Dr
	xxx_drb_mmb	bchg.b,$f53f2c25	;BCHG.B Dq,(Ar)
	xxx_im3_mmb	bchg.b,$d1e9dd51	;BCHG.B #<data>,(Ar)

	xxx_drb_drl	bclr.l,$7c92b253	;BCLR.L Dq,Dr
	xxx_im5_drl	bclr.l,$70780272	;BCLR.L #<data>,Dr
	xxx_drb_mmb	bclr.b,$17c5a98a	;BCLR.B Dq,(Ar)
	xxx_im3_mmb	bclr.b,$59374998	;BCLR.B #<data>,(Ar)

	bcc_label	bcs.s,$e7db1aaa		;BCS.S <label>
	bcc_label	bcs.w,$e7db1aaa		;BCS.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bcs.l,$e7db1aaa		;BCS.L <label>
	.cpu	68000
@@:

	bcc_label	beq.s,$dd300132		;BEQ.S <label>
	bcc_label	beq.w,$dd300132		;BEQ.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	beq.l,$dd300132		;BEQ.L <label>
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss	bfchg,$8e55e6c3		;BFCHG Dr{#o:#w}
	bfxxx_drsd	bfchg,$6e130235		;BFCHG Dr{#o:Dw}
	bfxxx_drds	bfchg,$a405609b		;BFCHG Dr{Do:#w}
	bfxxx_drdd	bfchg,$cd58483c		;BFCHG Dr{Do:Dw}
	bfxxx_mmss	bfchg,$6a2bf5e5		;BFCHG (Ar){#o:#w}
	bfxxx_mmsd	bfchg,$ebb0e6c5		;BFCHG (Ar){#o:Dw}
	bfxxx_mmds	bfchg,$30948a98		;BFCHG (Ar){Do:#w}
	bfxxx_mmdd	bfchg,$07b9bd50		;BFCHG (Ar){Do:Dw}
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss	bfclr,$fdef0702		;BFCLR Dr{#o:#w}
	bfxxx_drsd	bfclr,$38d8e99b		;BFCLR Dr{#o:Dw}
	bfxxx_drds	bfclr,$1f8b3a4e		;BFCLR Dr{Do:#w}
	bfxxx_drdd	bfclr,$9ecca8ae		;BFCLR Dr{Do:Dw}
	bfxxx_mmss	bfclr,$951173d5		;BFCLR (Ar){#o:#w}
	bfxxx_mmsd	bfclr,$626af488		;BFCLR (Ar){#o:Dw}
	bfxxx_mmds	bfclr,$e1a1a71f		;BFCLR (Ar){Do:#w}
	bfxxx_mmdd	bfclr,$205f25eb		;BFCLR (Ar){Do:Dw}
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss_drl	bfexts,$3284b5c6	;BFEXTS Dr{#o:#w},Dn
	bfxxx_drsd_drl	bfexts,$3211cd7a	;BFEXTS Dr{#o:Dw},Dn
	bfxxx_drds_drl	bfexts,$41a9fa9d	;BFEXTS Dr{Do:#w},Dn
	bfxxx_drdd_drl	bfexts,$93c6de8a	;BFEXTS Dr{Do:Dw},Dn
	bfxxx_mmss_drl	bfexts,$8ee51933	;BFEXTS (Ar){#o:#w},Dn
	bfxxx_mmsd_drl	bfexts,$3dd8af66	;BFEXTS (Ar){#o:Dw},Dn
	bfxxx_mmds_drl	bfexts,$f4e8c1da	;BFEXTS (Ar){Do:#w},Dn
	bfxxx_mmdd_drl	bfexts,$609a1d2b	;BFEXTS (Ar){Do:Dw},Dn
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss_drl	bfextu,$cce54f5d	;BFEXTU Dr{#o:#w},Dn
	bfxxx_drsd_drl	bfextu,$36ceff61	;BFEXTU Dr{#o:Dw},Dn
	bfxxx_drds_drl	bfextu,$060a9e9c	;BFEXTU Dr{Do:#w},Dn
	bfxxx_drdd_drl	bfextu,$92d81eee	;BFEXTU Dr{Do:Dw},Dn
	bfxxx_mmss_drl	bfextu,$31960fe9	;BFEXTU (Ar){#o:#w},Dn
	bfxxx_mmsd_drl	bfextu,$fce08199	;BFEXTU (Ar){#o:Dw},Dn
	bfxxx_mmds_drl	bfextu,$c326ca69	;BFEXTU (Ar){Do:#w},Dn
	bfxxx_mmdd_drl	bfextu,$a26ea9d5	;BFEXTU (Ar){Do:Dw},Dn
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss_drl	bfffo,$cba731bf		;BFFFO Dr{#o:#w},Dn
	bfxxx_drsd_drl	bfffo,$fa7c615c		;BFFFO Dr{#o:Dw},Dn
	bfxxx_drds_drl	bfffo,$c4260325		;BFFFO Dr{Do:#w},Dn
	bfxxx_drdd_drl	bfffo,$0706201f		;BFFFO Dr{Do:Dw},Dn
	bfxxx_mmss_drl	bfffo,$7e8e32df		;BFFFO (Ar){#o:#w},Dn
	bfxxx_mmsd_drl	bfffo,$0b63ed19		;BFFFO (Ar){#o:Dw},Dn
	bfxxx_mmds_drl	bfffo,$5271fb87		;BFFFO (Ar){Do:#w},Dn
	bfxxx_mmdd_drl	bfffo,$f19515a8		;BFFFO (Ar){Do:Dw},Dn
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drl_drss	bfins,$7c9274d3		;BFINS Dn,Dr{#o:#w}
	bfxxx_drl_drsd	bfins,$14f9b229		;BFINS Dn,Dr{#o:Dw}
	bfxxx_drl_drds	bfins,$3e7da35a		;BFINS Dn,Dr{Do:#w}
	bfxxx_drl_drdd	bfins,$4e103e86		;BFINS Dn,Dr{Do:Dw}
	bfxxx_drl_mmss	bfins,$4dff9718		;BFINS Dn,(Ar){#o:#w}
	bfxxx_drl_mmsd	bfins,$3ba5981b		;BFINS Dn,(Ar){#o:Dw}
	bfxxx_drl_mmds	bfins,$2ac8bb1c		;BFINS Dn,(Ar){Do:#w}
	bfxxx_drl_mmdd	bfins,$211932e4		;BFINS Dn,(Ar){Do:Dw}
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss	bfset,$752ba14a		;BFSET Dr{#o:#w}
	bfxxx_drsd	bfset,$454fd936		;BFSET Dr{#o:Dw}
	bfxxx_drds	bfset,$2dcc182b		;BFSET Dr{Do:#w}
	bfxxx_drdd	bfset,$2035073c		;BFSET Dr{Do:Dw}
	bfxxx_mmss	bfset,$9b7e73f4		;BFSET (Ar){#o:#w}
	bfxxx_mmsd	bfset,$6a2ee4d8		;BFSET (Ar){#o:Dw}
	bfxxx_mmds	bfset,$e7320299		;BFSET (Ar){Do:#w}
	bfxxx_mmdd	bfset,$bfbafbbf		;BFSET (Ar){Do:Dw}
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	jbeq	@f
	.cpu	68020
	bfxxx_drss	bftst,$0691408b		;BFTST Dr{#o:#w}
	bfxxx_drsd	bftst,$13843298		;BFTST Dr{#o:Dw}
	bfxxx_drds	bftst,$964242fe		;BFTST Dr{Do:#w}
	bfxxx_drdd	bftst,$73a1e7ae		;BFTST Dr{Do:Dw}
	bfxxx_mmss	bftst,$6444f5c4		;BFTST (Ar){#o:#w}
	bfxxx_mmsd	bftst,$e3f4f695		;BFTST (Ar){#o:Dw}
	bfxxx_mmds	bftst,$36072f1e		;BFTST (Ar){Do:#w}
	bfxxx_mmdd	bftst,$985c6304		;BFTST (Ar){Do:Dw}
	.cpu	68000
@@:

	bcc_label	bge.s,$56553618		;BGE.S <label>
	bcc_label	bge.w,$56553618		;BGE.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bge.l,$56553618		;BGE.L <label>
	.cpu	68000
@@:

	bcc_label	bgt.s,$f548e8da		;BGT.S <label>
	bcc_label	bgt.w,$f548e8da		;BGT.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bgt.l,$f548e8da		;BGT.L <label>
	.cpu	68000
@@:

	bcc_label	bhi.s,$ae658b96		;BHI.S <label>
	bcc_label	bhi.w,$ae658b96		;BHI.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bhi.l,$ae658b96		;BHI.L <label>
	.cpu	68000
@@:

						;BITREV.L Dr

						;BKPT #<data>

	bcc_label	ble.s,$e1958790		;BLE.S <label>
	bcc_label	ble.w,$e1958790		;BLE.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	ble.l,$e1958790		;BLE.L <label>
	.cpu	68000
@@:

	bcc_label	bls.s,$bab8e4dc		;BLS.S <label>
	bcc_label	bls.w,$bab8e4dc		;BLS.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bls.l,$bab8e4dc		;BLS.L <label>
	.cpu	68000
@@:

	bcc_label	blt.s,$42885952		;BLT.S <label>
	bcc_label	blt.w,$42885952		;BLT.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	blt.l,$42885952		;BLT.L <label>
	.cpu	68000
@@:

	bcc_label	bmi.s,$a8249454		;BMI.S <label>
	bcc_label	bmi.w,$a8249454		;BMI.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bmi.l,$a8249454		;BMI.L <label>
	.cpu	68000
@@:

	bcc_label	bne.s,$c9ed6e78		;BNE.S <label>
	bcc_label	bne.w,$c9ed6e78		;BNE.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bne.l,$c9ed6e78		;BNE.L <label>
	.cpu	68000
@@:

	bcc_label	bpl.s,$bcf9fb1e		;BPL.S <label>
	bcc_label	bpl.w,$bcf9fb1e		;BPL.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bpl.l,$bcf9fb1e		;BPL.L <label>
	.cpu	68000
@@:

	bcc_label	bra.s,$aa254bc1		;BRA.S <label>
	bcc_label	bra.w,$aa254bc1		;BRA.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bra.l,$aa254bc1		;BRA.L <label>
	.cpu	68000
@@:

	xxx_drb_drl	bset.l,$d90ff1ed	;BSET.L Dq,Dr
	xxx_im5_drl	bset.l,$0c016f23	;BSET.L #<data>,Dr
	xxx_drb_mmb	bset.b,$c7a47e1c	;BSET.B Dq,(Ar)
	xxx_im3_mmb	bset.b,$a4ba0070	;BSET.B #<data>,(Ar)

	bsr_label	bsr.s,$dbd5af72		;BSR.S <label>
	bsr_label	bsr.w,$dbd5af72		;BSR.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bsr_label	bsr.l,$dbd5af72		;BSR.L <label>
	.cpu	68000
@@:

	xxx_drb_drl	btst.l,$e9360fe7	;BTST.L Dq,Dr
	xxx_im5_drl	btst.l,$3b1c791c	;BTST.L #<data>,Dr
	xxx_drb_mmb	btst.b,$255efbb3	;BTST.B Dq,(Ar)
	xxx_im3_mmb	btst.b,$2c6494b9	;BTST.B #<data>,(Ar)
	xxx_drb_imb	btst.b,$33d6dfb4	;BTST.B Dq,#<data>

	bcc_label	bvc.s,$408986c7		;BVC.S <label>
	bcc_label	bvc.w,$408986c7		;BVC.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bvc.l,$408986c7		;BVC.L <label>
	.cpu	68000
@@:

	bcc_label	bvs.s,$5454e98d		;BVS.S <label>
	bcc_label	bvs.w,$5454e98d		;BVS.W <label>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	bcc_label	bvs.l,$5454e98d		;BVS.L <label>
	.cpu	68000
@@:

						;BYTEREV.L Dr

						;CALLM #<data>,(Ar)

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cas_byte	cas.b,$4f9b6a92		;CAS.B Dc,Du,<ea>
	cas_word	cas.w,$3ee47157		;CAS.W Dc,Du,<ea>
	cas_long	cas.l,$aae289c6		;CAS.L Dc,Du,<ea>
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cas2_word	cas2.w,$04f108a6	;CAS2.W Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)
	cas2_long	cas2.l,$45da8394	;CAS2.L Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)
	.cpu	68000
@@:

	moveq.l	#MC68000|MC68010|MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	chkeasy_mmw_drw	chk.w,$fb55061c		;CHK.W (Ar),Dq
	bra	2f
1:
	chkhard_mmw_drw	chk.w,$bfeacc3f		;CHK.W (Ar),Dq
2:
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	chkeasy_mmw_drw	chk.w,$fb55061c		;CHK.W (Ar),Dq
	bra	2f
1:
	chkhard_mmw_drw	chk.w,$18ad244c		;CHK.W (Ar),Dq
2:
@@:

	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	chkeasy_mml_drl	chk.l,$d080f9b9		;CHK.L (Ar),Dq
	bra	2f
1:
	chkhard_mml_drl	chk.l,$94578581		;CHK.L (Ar),Dq
2:
	.cpu	68000
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	chkeasy_mml_drl	chk.l,$d080f9b9		;CHK.L (Ar),Dq
	bra	2f
1:
	chkhard_mml_drl	chk.l,$10d41b6b		;CHK.L (Ar),Dq
2:
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	chk2cmp2easy_mmw_drb	chk2.b,$04ee2a55	;CHK2.B (Ar),Dn
	chk2cmp2easy_mml_drw	chk2.w,$28f43cb7	;CHK2.W (Ar),Dn
	chk2cmp2easy_mmq_drl	chk2.l,$228233f7	;CHK2.L (Ar),Dn
	chk2cmp2easy_mmw_arl	chk2.b,$20101e6b	;CHK2.B (Ar),An
	chk2cmp2easy_mml_arl	chk2.w,$9a84ce0b	;CHK2.W (Ar),An
	chk2cmp2easy_mmq_arl	chk2.l,$228233f7	;CHK2.L (Ar),An
	bra	2f
1:
	chk2cmp2hard_mmw_drb	chk2.b,$d5215e3c	;CHK2.B (Ar),Dn
	chk2cmp2hard_mml_drw	chk2.w,$2c92ad99	;CHK2.W (Ar),Dn
	chk2cmp2hard_mmq_drl	chk2.l,$facafa07	;CHK2.L (Ar),Dn
	chk2cmp2hard_mmw_arl	chk2.b,$63f1a3c5	;CHK2.B (Ar),An
	chk2cmp2hard_mml_arl	chk2.w,$9d76ddb1	;CHK2.W (Ar),An
	chk2cmp2hard_mmq_arl	chk2.l,$facafa07	;CHK2.L (Ar),An
2:
	.cpu	68000
@@:

						;CINVA *C

						;CINVL *C,(Ar)

						;CINVP *C,(Ar)

	xxx_drb		clr.b,$8d4df1d9		;CLR.B Dr
	xxx_drw		clr.w,$c35be15b		;CLR.W Dr
	xxx_drl		clr.l,$1134ee6d		;CLR.L Dr
	xxx_mmb		clr.b,$fcc44b56		;CLR.B (Ar)
	xxx_mmw		clr.w,$7707e052		;CLR.W (Ar)
	xxx_mml		clr.l,$1134ee6d		;CLR.L (Ar)

	xxx_drb_drb	cmp.b,$4f6e763c		;CMP.B Dr,Dq
	xxx_drw_drw	cmp.w,$804b4c14		;CMP.W Dr,Dq
	xxx_drl_drl	cmp.l,$4fbc6975		;CMP.L Dr,Dq
	xxx_mmb_drb	cmp.b,$d4a1cfea		;CMP.B (Ar),Dq
	xxx_mmw_drw	cmp.w,$dd81fe20		;CMP.W (Ar),Dq
	xxx_mml_drl	cmp.l,$4fbc6975		;CMP.L (Ar),Dq

	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	chk2cmp2easy_mmw_drb	cmp2.b,$6d7db09a	;CMP2.B (An),Dn
	chk2cmp2easy_mml_drw	cmp2.w,$ea8f04b0	;CMP2.W (An),Dn
	chk2cmp2easy_mmq_drl	cmp2.l,$db7173de	;CMP2.L (An),Dn
	chk2cmp2easy_mmw_arl	cmp2.b,$ef9f20ca	;CMP2.B (An),An
	chk2cmp2easy_mml_arl	cmp2.w,$fb747da1	;CMP2.W (An),An
	chk2cmp2easy_mmq_arl	cmp2.l,$db7173de	;CMP2.L (An),An
	bra	2f
1:
	chk2cmp2hard_mmw_drb	cmp2.b,$bcb2c4f3	;CMP2.B (An),Dn
	chk2cmp2hard_mml_drw	cmp2.w,$eee9959e	;CMP2.W (An),Dn
	chk2cmp2hard_mmq_drl	cmp2.l,$0339ba2e	;CMP2.L (An),Dn
	chk2cmp2hard_mmw_arl	cmp2.b,$ac7e9d64	;CMP2.B (An),An
	chk2cmp2hard_mml_arl	cmp2.w,$fc866e1b	;CMP2.W (An),An
	chk2cmp2hard_mmq_arl	cmp2.l,$0339ba2e	;CMP2.L (An),An
2:
	.cpu	68000
@@:

	xxx_drw_arl	cmpa.w,$fe84cf7b	;CMPA.W Dr,Aq
	xxx_drl_arl	cmpa.l,$6656c246	;CMPA.L Dr,Aq
	xxx_mmw_arl	cmpa.w,$640ebde6	;CMPA.W (Ar),Aq
	xxx_mml_arl	cmpa.l,$4fbc6975	;CMPA.L (Ar),Aq

	xxx_imb_drb	cmpi.b,$66d7e2fa	;CMPI.B #<data>,Dr
	xxx_imw_drw	cmpi.w,$d4730dfd	;CMPI.W #<data>,Dr
	xxx_iml_drl	cmpi.l,$9772a981	;CMPI.L #<data>,Dr
	xxx_imb_mmb	cmpi.b,$78e61573	;CMPI.B #<data>,(Ar)
	xxx_imw_mmw	cmpi.w,$4f84fb21	;CMPI.W #<data>,(Ar)
	xxx_iml_mml	cmpi.l,$9772a981	;CMPI.L #<data>,(Ar)

	xxx_mpb_mpb	cmpm.b,$00329e49	;CMPM.B (Ar)+,(Aq)+
	xxx_mpw_mpw	cmpm.w,$2d9b23fb	;CMPM.W (Ar)+,(Aq)+
	xxx_mpl_mpl	cmpm.l,$c26a4ec4	;CMPM.L (Ar)+,(Aq)+

						;CPUSHA *C

						;CPUSHL *C,(Ar)

						;CPUSHP *C,(Ar)

	dbcc_drw_label	dbcc.w,$2ef9c63f	;DBCC.W Dr,<label>

	dbcc_drw_label	dbcs.w,$d6367901	;DBCS.W Dr,<label>

	dbcc_drw_label	dbeq.w,$5837e090	;DBEQ.W Dr,<label>

	dbcc_drw_label	dbf.w,$d8a3dfc4		;DBF.W Dr,<label>

	dbcc_drw_label	dbge.w,$11bdab9f	;DBGE.W Dr,<label>

	dbcc_drw_label	dbgt.w,$0bb0fde3	;DBGT.W Dr,<label>

	dbcc_drw_label	dbhi.w,$4468ce33	;DBHI.W Dr,<label>

	dbcc_drw_label	dble.w,$f37f42dd	;DBLE.W Dr,<label>

	dbcc_drw_label	dbls.w,$bca7710d	;DBLS.W Dr,<label>

	dbcc_drw_label	dblt.w,$e97214a1	;DBLT.W Dr,<label>

	dbcc_drw_label	dbmi.w,$b472c6bd	;DBMI.W Dr,<label>

	dbcc_drw_label	dbpl.w,$4cbd7983	;DBPL.W Dr,<label>

	dbcc_drw_label	dbt.w,$206c60fa		;DBT.W Dr,<label>

	dbcc_drw_label	dbvc.w,$7d6cb2e6	;DBVC.W Dr,<label>

	dbcc_drw_label	dbvs.w,$85a30dd8	;DBVS.W Dr,<label>

	moveq.l	#MC68000|MC68010|MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drw_drl	divs.w,$340d90f7	;DIVS.W Dr,Dq
	diveasy_mmw_drl	divs.w,$b06349d4	;DIVS.W (Ar),Dq
	bra	2f
1:
	divhard_drw_drl	divs.w,$8397489e	;DIVS.W Dr,Dq
	divhard_mmw_drl	divs.w,$07f991bd	;DIVS.W (Ar),Dq
2:
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drw_drl	divs.w,$340d90f7	;DIVS.W Dr,Dq
	diveasy_mmw_drl	divs.w,$b06349d4	;DIVS.W (Ar),Dq
	bra	2f
1:
	divhard_drw_drl	divs.w,$c52eb327	;DIVS.W Dr,Dq
	divhard_mmw_drl	divs.w,$41406a04	;DIVS.W (Ar),Dq
2:
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drl	divs.l,$932003bf	;DIVS.L Dr,Dq
	diveasy_mml_drl	divs.l,$932003bf	;DIVS.L (Ar),Dq
	bra	2f
1:
	divhard_drl_drl	divs.l,$362dc5b2	;DIVS.L Dr,Dq
	divhard_mml_drl	divs.l,$362dc5b2	;DIVS.L (Ar),Dq
2:
	.cpu	68000
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drl	divs.l,$932003bf	;DIVS.L Dr,Dq
	diveasy_mml_drl	divs.l,$932003bf	;DIVS.L (Ar),Dq
	bra	2f
1:
	divhard_drl_drl	divs.l,$814f0692	;DIVS.L Dr,Dq
	divhard_mml_drl	divs.l,$814f0692	;DIVS.L (Ar),Dq
2:
	.cpu	68000
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drq	divs.l,$80563ce2	;DIVS.L Dr,Dh:Dl
	diveasy_mml_drq	divs.l,$80563ce2	;DIVS.L (Ar),Dh:Dl
	bra	2f
1:
	divhard_drl_drq	divs.l,$7f77dabd	;DIVS.L Dr,Dh:Dl
	divhard_mml_drq	divs.l,$7f77dabd	;DIVS.L (Ar),Dh:Dl
2:
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drq	divsl.l,$c5551b68	;DIVSL.L Dr,Dh:Dl
	diveasy_mml_drq	divsl.l,$c5551b68	;DIVSL.L (Ar),Dh:Dl
	bra	2f
1:
	divhard_drl_drq	divsl.l,$05df83e4	;DIVSL.L Dr,Dh:Dl
	divhard_mml_drq	divsl.l,$05df83e4	;DIVSL.L (Ar),Dh:Dl
2:
	.cpu	68000
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drq	divsl.l,$c5551b68	;DIVSL.L Dr,Dh:Dl
	diveasy_mml_drq	divsl.l,$c5551b68	;DIVSL.L (Ar),Dh:Dl
	bra	2f
1:
	divhard_drl_drq	divsl.l,$36cd1ff1	;DIVSL.L Dr,Dh:Dl
	divhard_mml_drq	divsl.l,$36cd1ff1	;DIVSL.L (Ar),Dh:Dl
2:
	.cpu	68000
@@:

	moveq.l	#MC68000|MC68010|MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drw_drl	divu.w,$585316bc	;DIVU.W Dr,Dq
	diveasy_mmw_drl	divu.w,$dc3dcf9f	;DIVU.W (Ar),Dq
	bra	2f
1:
	divhard_drw_drl	divu.w,$3efc9cea	;DIVU.W Dr,Dq
	divhard_mmw_drl	divu.w,$ba9245c9	;DIVU.W (Ar),Dq
2:
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drw_drl	divu.w,$585316bc	;DIVU.W Dr,Dq
	diveasy_mmw_drl	divu.w,$dc3dcf9f	;DIVU.W (Ar),Dq
	bra	2f
1:
	divhard_drw_drl	divu.w,$37def6b0	;DIVU.W Dr,Dq
	divhard_mmw_drl	divu.w,$b3b02f93	;DIVU.W (Ar),Dq
2:
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drl	divu.l,$5b6f00af	;DIVU.L Dr,Dq
	diveasy_mml_drl	divu.l,$5b6f00af	;DIVU.L (Ar),Dq
	bra	2f
1:
	divhard_drl_drl	divu.l,$5710e8dd	;DIVU.L Dr,Dq
	divhard_mml_drl	divu.l,$5710e8dd	;DIVU.L (Ar),Dq
2:
	.cpu	68000
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drl	divu.l,$5b6f00af	;DIVU.L Dr,Dq
	diveasy_mml_drl	divu.l,$5b6f00af	;DIVU.L (Ar),Dq
	bra	2f
1:
	divhard_drl_drl	divu.l,$ed87b30a	;DIVU.L Dr,Dq
	divhard_mml_drl	divu.l,$ed87b30a	;DIVU.L (Ar),Dq
2:
	.cpu	68000
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drq	divu.l,$8b9e20f8	;DIVU.L Dr,Dh:Dl
	diveasy_mml_drq	divu.l,$8b9e20f8	;DIVU.L (Ar),Dh:Dl
	bra	2f
1:
	divhard_drl_drq	divu.l,$90b5ea34	;DIVU.L Dr,Dh:Dl
	divhard_mml_drq	divu.l,$90b5ea34	;DIVU.L (Ar),Dh:Dl
2:
	.cpu	68000
@@:

	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drq	divul.l,$a00c7e86	;DIVUL.L Dr,Dh:Dl
	diveasy_mml_drq	divul.l,$a00c7e86	;DIVUL.L (Ar),Dh:Dl
	bra	2f
1:
	divhard_drl_drq	divul.l,$78f9868d	;DIVUL.L Dr,Dh:Dl
	divhard_mml_drq	divul.l,$78f9868d	;DIVUL.L (Ar),Dh:Dl
2:
	.cpu	68000
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	cmpi.b	#EASY,test_level
	bne	1f
	diveasy_drl_drq	divul.l,$a00c7e86	;DIVUL.L Dr,Dh:Dl
	diveasy_mml_drq	divul.l,$a00c7e86	;DIVUL.L (Ar),Dh:Dl
	bra	2f
1:
	divhard_drl_drq	divul.l,$49e4390c	;DIVUL.L Dr,Dh:Dl
	divhard_mml_drq	divul.l,$49e4390c	;DIVUL.L (Ar),Dh:Dl
2:
	.cpu	68000
@@:

	xxx_drb_drb	eor.b,$0e594f66		;EOR.B Dq,Dr
	xxx_drw_drw	eor.w,$d3f20fa8		;EOR.W Dq,Dr
	xxx_drl_drl	eor.l,$7f42ee4c		;EOR.L Dq,Dr
	xxx_drb_mmb	eor.b,$f371faba		;EOR.B Dq,(Ar)
	xxx_drw_mmw	eor.w,$2cae1833		;EOR.W Dq,(Ar)
	xxx_drl_mml	eor.l,$7f42ee4c		;EOR.L Dq,(Ar)

	xxx_imb_drb	eori.b,$8384a5ac	;EORI.B #<data>,Dr
	xxx_imw_drw	eori.w,$41648d1c	;EORI.W #<data>,Dr
	xxx_iml_drl	eori.l,$a873de83	;EORI.L #<data>,Dr
	xxx_imb_mmb	eori.b,$0d3c4c0a	;EORI.B #<data>,(Ar)
	xxx_imw_mmw	eori.w,$ffc3dc0f	;EORI.W #<data>,(Ar)
	xxx_iml_mml	eori.l,$a873de83	;EORI.L #<data>,(Ar)
	xxx_imb_ccr	eori.b,$e413323d	;EORI.B #<data>,CCR
						;EORI.W #<data>,SR

	xxx_drl_drl	exg.l,$c1dbddb4		;EXG.L Dq,Dr
	xxx_arl_arl	exg.l,$c4096fcb		;EXG.L Aq,Ar
	xxx_drl_arl	exg.l,$c4096fcb		;EXG.L Dq,Ar

	xxx_drb		ext.w,$3184496c		;EXT.W Dr
	xxx_drw		ext.l,$c0ba8203		;EXT.L Dr

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drb		extb.l,$c1841c1c	;EXTB.L Dr
	.cpu	68000
@@:

						;FABS
						;FACOS
						;FADD
						;FASIN
						;FATAN
						;FBEQ
						;FBF
						;FBGE
						;FBGL
						;FBGLE
						;FBGT
						;FBLE
						;FBLT
						;FBNE
						;FBNGE
						;FBNGL
						;FBNGLE
						;FBNGT
						;FBNLE
						;FBNLT
						;FBOGE
						;FBOGL
						;FBOGT
						;FBOLE
						;FBOLT
						;FBOR
						;FBSEQ
						;FBSF
						;FBSNE
						;FBST
						;FBT
						;FBUEQ
						;FBUGE
						;FBUGT
						;FBULE
						;FBULT
						;FBUN
						;FCMP
						;FCOS
						;FCOSH
						;FDABS
						;FDADD
						;FDBEQ
						;FDBF
						;FDBGE
						;FDBGL
						;FDBGLE
						;FDBGT
						;FDBLE
						;FDBLT
						;FDBNE
						;FDBNGE
						;FDBNGL
						;FDBNGLE
						;FDBNGT
						;FDBNLE
						;FDBNLT
						;FDBOGE
						;FDBOGL
						;FDBOGT
						;FDBOLE
						;FDBOLT
						;FDBOR
						;FDBSEQ
						;FDBSF
						;FDBSNE
						;FDBST
						;FDBT
						;FDBUEQ
						;FDBUGE
						;FDBUGT
						;FDBULE
						;FDBULT
						;FDBUN
						;FDDIV
						;FDIV
						;FDMOVE
						;FDMUL
						;FDNEG
						;FDSQRT
						;FDSUB
						;FETOX
						;FETOXM1

						;FF1.L Dr

						;FGETEXP
						;FGETMAN
						;FINT
						;FINTRZ
						;FLOG10
						;FLOG2
						;FLOGN
						;FLOGNP1
						;FMOD
						;FMOVE
						;FMOVECR
						;FMOVEM
						;FMUL
						;FNEG
						;FREM
						;FRESTORE
						;FSABS
						;FSADD
						;FSAVE
						;FSCALE
						;FSDIV
						;FSEQ
						;FSF
						;FSGE
						;FSGL
						;FSGLDIV
						;FSGLE
						;FSGLMUL
						;FSGT
						;FSIN
						;FSINCOS
						;FSINH
						;FSLE
						;FSLT
						;FSMOVE
						;FSMUL
						;FSNE
						;FSNEG
						;FSNGE
						;FSNGL
						;FSNGLE
						;FSNGT
						;FSNLE
						;FSNLT
						;FSOGE
						;FSOGL
						;FSOGT
						;FSOLE
						;FSOLT
						;FSOR
						;FSQRT
						;FSSEQ
						;FSSF
						;FSSNE
						;FSSQRT
						;FSST
						;FSSUB
						;FST
						;FSUB
						;FSUEQ
						;FSUGE
						;FSUGT
						;FSULE
						;FSULT
						;FSUN
						;FTAN
						;FTANH
						;FTENTOX
						;FTRAPEQ
						;FTRAPF
						;FTRAPGE
						;FTRAPGL
						;FTRAPGLE
						;FTRAPGT
						;FTRAPLE
						;FTRAPLT
						;FTRAPNE
						;FTRAPNGE
						;FTRAPNGL
						;FTRAPNGLE
						;FTRAPNGT
						;FTRAPNLE
						;FTRAPNLT
						;FTRAPOGE
						;FTRAPOGL
						;FTRAPOGT
						;FTRAPOLE
						;FTRAPOLT
						;FTRAPOR
						;FTRAPSEQ
						;FTRAPSF
						;FTRAPSNE
						;FTRAPST
						;FTRAPT
						;FTRAPUEQ
						;FTRAPUGE
						;FTRAPUGT
						;FTRAPULE
						;FTRAPULT
						;FTRAPUN
						;FTST
						;FTWOTOX

						;ILLEGAL

	jmp_mml		jmp,$67f073bc		;JMP <ea>

	jsr_mml		jsr,$dbd5af72		;JSR <ea>

	lea_mml_arl	lea.l,$c8cfe04d		;LEA.L (Ar),Aq
	moveq.l	#MC68000|MC68010,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	lea_brief	lea.l,$b1d175d7		;LEA.L <brief-format>,Aq
	.cpu	68000
@@:
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	lea_brief	lea.l,$68b62ff6		;LEA.L <brief-format>,Aq
	lea_full	lea.l,$dc4c31af		;LEA.L <full-format>,Aq
	.cpu	68000
@@:

	link_arl_imw	link.w,$deca662c	;LINK.W Ar,#<data>
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	link_arl_iml	link.l,$80f36ccf	;LINK.L Ar,#<data>
	.cpu	68000
@@:

						;LPSTOP.W #<data>

	xxx_drb_drb	lsl.b,$1a9611b1		;LSL.B Dq,Dr
	xxx_drb_drw	lsl.w,$c6da1c34		;LSL.W Dq,Dr
	xxx_drb_drl	lsl.l,$096f4b0f		;LSL.L Dq,Dr
	xxx_imq_drb	lsl.b,$79462761		;LSL.B #<data>,Dr
	xxx_imq_drw	lsl.w,$27562b81		;LSL.W #<data>,Dr
	xxx_imq_drl	lsl.l,$7f4e207a		;LSL.L #<data>,Dr
	xxx_mmw		lsl.w,$d2bf0fe8		;LSL.W (Ar)

	xxx_drb_drb	lsr.b,$3669426a		;LSR.B Dq,Dr
	xxx_drb_drw	lsr.w,$372a73c2		;LSR.W Dq,Dr
	xxx_drb_drl	lsr.l,$d27e97ed		;LSR.L Dq,Dr
	xxx_imq_drb	lsr.b,$efce7177		;LSR.B #<data>,Dr
	xxx_imq_drw	lsr.w,$cf798288		;LSR.W #<data>,Dr
	xxx_imq_drl	lsr.l,$0e44a881		;LSR.L #<data>,Dr
	xxx_mmw		lsr.w,$7a2da54f		;LSR.W (Ar)

	xxx_drb_drb	move.b,$68418baa	;MOVE.B Dr,Dq
	xxx_drw_drw	move.w,$66531b05	;MOVE.W Dr,Dq
	xxx_drl_drl	move.l,$e11ad812	;MOVE.L Dr,Dq
	xxx_mmb_drb	move.b,$e0aa75cf	;MOVE.B (Ar),Dq
	xxx_mmw_drw	move.w,$3b99a931	;MOVE.W (Ar),Dq
	xxx_mml_drl	move.l,$e11ad812	;MOVE.L (Ar),Dq
	xxx_drb_mmb	move.b,$e1f7c567	;MOVE.B Dr,(Aq)
	xxx_drw_mmw	move.w,$d942ebea	;MOVE.W Dr,(Aq)
	xxx_drl_mml	move.l,$e11ad812	;MOVE.L Dr,(Aq)
	xxx_mmb_mmb	move.b,$58e49dc7	;MOVE.B (Ar),(Aq)
	xxx_mmw_mmw	move.w,$36e177fb	;MOVE.W (Ar),(Aq)
	xxx_mml_mml	move.l,$e11ad812	;MOVE.L (Ar),(Aq)
	xxx_imw_ccr	move.w,$9c1feb07	;MOVE.W #<data>,CCR

						;MOVE16 (Ar)+,xxx.L
						;MOVE16 xxx.L,(Ar)+
						;MOVE16 (Ar),xxx.L
						;MOVE16 xxx.L,(Ar)
						;MOVE16 (Ar)+,(An)+

	xxx_drw_arl	movea.w,$af06a2db	;MOVEA.W Dr,Aq
	xxx_drl_arl	movea.l,$b15e75ef	;MOVEA.L Dr,Aq
	xxx_mmw_arl	movea.w,$c7cad46a	;MOVEA.W (Ar),Aq
	xxx_mml_arl	movea.l,$f6978f0c	;MOVEA.L (Ar),Aq

						;MOVEC.L Rc,Rn
						;MOVEC.L Rn,Rc

	moveq.l	#MC68000|MC68010,d0
	and.b	mpu_mask,d0
	beq	@f
	movem_list_mnw	movem.w,$0cc4fcc3	;MOVEM.W <list>,-(Ar)
	movem_list_mnl	movem.l,$44546c8a	;MOVEM.L <list>,-(Ar)
@@:
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	movem_list_mnw	movem.w,$32cd5ad5	;MOVEM.W <list>,-(Ar)
	movem_list_mnl	movem.l,$dc13bdd2	;MOVEM.L <list>,-(Ar)
@@:
	movem_mpw_list	movem.w,$2eb830a3	;MOVEM.W (Ar)+,<list>
	movem_mpl_list	movem.l,$5ae16385	;MOVEM.L (Ar)+,<list>

	moveq.l	#MC68000|MC68010|MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	xxx_mwl_drw	movep.w,$a6dd18aa	;MOVEP.W (d16,Ar),Dq
	xxx_mwq_drl	movep.l,$d658354b	;MOVEP.L (d16,Ar),Dq
	xxx_drw_mwl	movep.w,$c555c355	;MOVEP.W Dq,(d16,Ar)
	xxx_drl_mwq	movep.l,$1a1ffe32	;MOVEP.L Dq,(d16,Ar)
@@:

	xxx_imb_drl	moveq.l,$e5f37fcb	;MOVEQ.L #<data>,Dq

						;MOVES.B <ea>,Rn
						;MOVES.W <ea>,Rn
						;MOVES.L <ea>,Rn
						;MOVES.B Rn,<ea>
						;MOVES.W Rn,<ea>
						;MOVES.L Rn,<ea>

	xxx_drw_drw	muls.w,$7260105c	;MULS.W Dr,Dq
	xxx_mmw_drw	muls.w,$2faaa268	;MULS.W (Ar),Dq
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drl_drl	muls.l,$a3d64f87	;MULS.L Dr,Dl
	xxx_mml_drl	muls.l,$a3d64f87	;MULS.L (Ar),Dl
	.cpu	68000
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drl_drq	muls.l,$05610442	;MULS.L Dr,Dh:Dl
	xxx_mml_drq	muls.l,$05610442	;MULS.L (Ar),Dh:Dl
	.cpu	68000
@@:

	xxx_drw_drw	mulu.w,$69bb326e	;MULU.W Dr,Dq
	xxx_mmw_drw	mulu.w,$3471805a	;MULU.W (Ar),Dq
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drl_drl	mulu.l,$947c0abb	;MULU.L Dr,Dl
	xxx_mml_drl	mulu.l,$947c0abb	;MULU.L (Ar),Dl
	.cpu	68000
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drl_drq	mulu.l,$b4b20f40	;MULU.L Dr,Dh:Dl
	xxx_mml_drq	mulu.l,$b4b20f40	;MULU.L (Ar),Dh:Dl
	.cpu	68000
@@:

						;MVS.B <ea>,Dq
						;MVS.W <ea>,Dq

						;MVZ.B <ea>,Dq
						;MVZ.W <ea>,Dq

	moveq.l	#MC68000|MC68010,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	nbcdeasy_drb		nbcd.b,$80271387	;NBCD.B Dr
	nbcdeasy_mmb		nbcd.b,$ddfe33c4	;NBCD.B (Ar)
	bra	2f
1:
	nbcdhard_drb		nbcd.b,$4affbe37	;NBCD.B Dr
	nbcdhard_mmb		nbcd.b,$17269e74	;NBCD.B (Ar)
2:
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	nbcdeasy_drb		nbcd.b,$80271387	;NBCD.B Dr
	nbcdeasy_mmb		nbcd.b,$ddfe33c4	;NBCD.B (Ar)
	bra	2f
1:
	nbcdhard_drb		nbcd.b,$eaa54d3f	;NBCD.B Dr
	nbcdhard_mmb		nbcd.b,$b77c6d7c	;NBCD.B (Ar)
2:
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	nbcdeasy_drb		nbcd.b,$80271387	;NBCD.B Dr
	nbcdeasy_mmb		nbcd.b,$ddfe33c4	;NBCD.B (Ar)
	bra	2f
1:
	nbcdhard_drb		nbcd.b,$60ea153e	;NBCD.B Dr
	nbcdhard_mmb		nbcd.b,$3d33357d	;NBCD.B (Ar)
2:
@@:

	xxx_drb		neg.b,$96722698		;NEG.B Dr
	xxx_drw		neg.w,$9e96cde1		;NEG.W Dr
	xxx_drl		neg.l,$71f2ae60		;NEG.L Dr
	xxx_mmb		neg.b,$cbf5b84e		;NEG.B (Ar)
	xxx_mmw		neg.w,$e3ad4b57		;NEG.W (Ar)
	xxx_mml		neg.l,$71f2ae60		;NEG.L (Ar)

	xxx_drb		negx.b,$5c10fec2	;NEGX.B Dr
	xxx_drw		negx.w,$1a5f8f78	;NEGX.W Dr
	xxx_drl		negx.l,$d92c491f	;NEGX.L Dr
	xxx_mmb		negx.b,$c5e9c66c	;NEGX.B (Ar)
	xxx_mmw		negx.w,$accde309	;NEGX.W (Ar)
	xxx_mml		negx.l,$d92c491f	;NEGX.L (Ar)

	xxx_no_operand	nop,$03368893		;NOP

	xxx_drb		not.b,$f5e9e1c3		;NOT.B Dr
	xxx_drw		not.w,$7a975b51		;NOT.W Dr
	xxx_drl		not.l,$bf0d6d46		;NOT.L Dr
	xxx_mmb		not.b,$4a4309ac		;NOT.B (Ar)
	xxx_mmw		not.w,$586f0494		;NOT.W (Ar)
	xxx_mml		not.l,$bf0d6d46		;NOT.L (Ar)

	xxx_drb_drb	or.b,$f25aeb20		;OR.B Dr,Dq
	xxx_drw_drw	or.w,$389aba84		;OR.W Dr,Dq
	xxx_drl_drl	or.l,$57b12eaa		;OR.L Dr,Dq
	xxx_mmb_drb	or.b,$52f72c85		;OR.B (Ar),Dq
	xxx_mmw_drw	or.w,$655008b0		;OR.W (Ar),Dq
	xxx_mml_drl	or.l,$57b12eaa		;OR.L (Ar),Dq
	xxx_drb_mmb	or.b,$c0b538b4		;OR.B Dq,(Ar)
	xxx_drw_mmw	or.w,$7d4b75b3		;OR.W Dq,(Ar)
	xxx_drl_mml	or.l,$57b12eaa		;OR.L Dq,(Ar)

	xxx_imb_drb	ori.b,$cc424181		;ORI.B #<data>,Dr
	xxx_imw_drw	ori.w,$9459a755		;ORI.W #<data>,Dr
	xxx_iml_drl	ori.l,$562b3df4		;ORI.L #<data>,Dr
	xxx_imb_mmb	ori.b,$7fc28df5		;ORI.B #<data>,(Ar)
	xxx_imw_mmw	ori.w,$3862ccb4		;ORI.W #<data>,(Ar)
	xxx_iml_mml	ori.l,$562b3df4		;ORI.L #<data>,(Ar)
	xxx_imb_ccr	ori.b,$37300084		;ORI.B #<data>,CCR
						;ORI.W #<data>,SR

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drw_drb_imw	pack,$cc37e9ca		;PACK Dr,Dq,#<data>
	xxx_mnw_mnb_imw	pack,$2adc67ad		;PACK -(Ar),-(Aq),#<data>
	.cpu	68000
@@:

	pea_mml		pea.l,$6635c308		;PEA.L <ea>

						;PFLUSH (Ar)

						;PFLUSHA

						;PFLUSHAN

						;PFLUSHN (Ar)

						;PLPAR (Ar)

						;PLPAW (Ar)

						;PTESTR

						;PTESTW

						;RESET

	xxx_drb_drb	rol.b,$d8963326		;ROL.B Dq,Dr
	xxx_drb_drw	rol.w,$da09ed3c		;ROL.W Dq,Dr
	xxx_drb_drl	rol.l,$93b899f8		;ROL.L Dq,Dr
	xxx_imq_drb	rol.b,$a7f4f7f2		;ROL.B #<data>,Dr
	xxx_imq_drw	rol.w,$74b5744e		;ROL.W #<data>,Dr
	xxx_imq_drl	rol.l,$5196601a		;ROL.L #<data>,Dr
	xxx_mmw		rol.w,$dc448878		;ROL.W (Ar)

	xxx_drb_drb	ror.b,$d2b33d28		;ROR.B Dq,Dr
	xxx_drb_drw	ror.w,$3bde6ab1		;ROR.W Dq,Dr
	xxx_drb_drl	ror.l,$cfdde223		;ROR.L Dq,Dr
	xxx_imq_drb	ror.b,$c5f8459c		;ROR.B #<data>,Dr
	xxx_imq_drw	ror.w,$e50168db		;ROR.W #<data>,Dr
	xxx_imq_drl	ror.l,$3dafc318		;ROR.L #<data>,Dr
	xxx_mmw		ror.w,$993f8505		;ROR.W (Ar)

	xxx_drb_drb	roxl.b,$763f7f4d	;ROXL.B Dq,Dr
	xxx_drb_drw	roxl.w,$c450b9ef	;ROXL.W Dq,Dr
	xxx_drb_drl	roxl.l,$0e90dd00	;ROXL.L Dq,Dr
	xxx_imq_drb	roxl.b,$80a391d0	;ROXL.B #<data>,Dr
	xxx_imq_drw	roxl.w,$3ac477d4	;ROXL.W #<data>,Dr
	xxx_imq_drl	roxl.l,$26eb6acf	;ROXL.L #<data>,Dr
	xxx_mmw		roxl.w,$73a245d2	;ROXL.W (Ar)

	xxx_drb_drb	roxr.b,$ebee3dd2	;ROXR.B Dq,Dr
	xxx_drb_drw	roxr.w,$68538a3b	;ROXR.W Dq,Dr
	xxx_drb_drl	roxr.l,$0ceaae2e	;ROXR.L Dq,Dr
	xxx_imq_drb	roxr.b,$6cbc37d1	;ROXR.B #<data>,Dr
	xxx_imq_drw	roxr.w,$de72e683	;ROXR.W #<data>,Dr
	xxx_imq_drl	roxr.l,$3891e8ac	;ROXR.L #<data>,Dr
	xxx_mmw		roxr.w,$a3cef2e4	;ROXR.W (Ar)

						;RTD #<data>

						;RTE

						;RTM Rn

						;RTR

						;RTS

						;SATS.L Dr

	moveq.l	#MC68000|MC68010,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	abcdsbcdeasy_drb_drb	sbcd.b,$08c536c6	;SBCD.B Dr,Dq
	abcdsbcdeasy_mnb_mnb	sbcd.b,$171825fc	;SBCD.B -(Ar),-(Aq)
	bra	2f
1:
	abcdsbcdhard_drb_drb	sbcd.b,$42484006	;SBCD.B Dr,Dq
	abcdsbcdhard_mnb_mnb	sbcd.b,$6efe5298	;SBCD.B -(Ar),-(Aq)
2:
@@:
	moveq.l	#MC68020|MC68030|MC68040,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	abcdsbcdeasy_drb_drb	sbcd.b,$08c536c6	;SBCD.B Dr,Dq
	abcdsbcdeasy_mnb_mnb	sbcd.b,$171825fc	;SBCD.B -(Ar),-(Aq)
	bra	2f
1:
	abcdsbcdhard_drb_drb	sbcd.b,$b9c3f8e6	;SBCD.B Dr,Dq
	abcdsbcdhard_mnb_mnb	sbcd.b,$29acdfb1	;SBCD.B -(Ar),-(Aq)
2:
@@:
	moveq.l	#MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	cmpi.b	#EASY,test_level
	bne	1f
	abcdsbcdeasy_drb_drb	sbcd.b,$08c536c6	;SBCD.B Dr,Dq
	abcdsbcdeasy_mnb_mnb	sbcd.b,$171825fc	;SBCD.B -(Ar),-(Aq)
	bra	2f
1:
	abcdsbcdhard_drb_drb	sbcd.b,$acce4f74	;SBCD.B Dr,Dq
	abcdsbcdhard_mnb_mnb	sbcd.b,$d290f440	;SBCD.B -(Ar),-(Aq)
2:
@@:

	scc_drb		scc.b,$3fb3493d		;SCC.B Dr
	scc_mmb		scc.b,$75005b7c		;SCC.B (Ar)

	scc_drb		scs.b,$a0eeb496		;SCS.B Dr
	scc_mmb		scs.b,$14e55bdb		;SCS.B (Ar)

	scc_drb		seq.b,$9ac966f0		;SEQ.B Dr
	scc_mmb		seq.b,$4ebbfe85		;SEQ.B (Ar)

	scc_drb		sf.b,$6adbbd41		;SF.B Dr
	scc_mmb		sf.b,$1b5207ce		;SF.B (Ar)

	scc_drb		sge.b,$485f797a		;SGE.B Dr
	scc_mmb		sge.b,$762f58ee		;SGE.B (Ar)

	scc_drb		sgt.b,$dcc8d6f2		;SGT.B Dr
	scc_mmb		sgt.b,$defdb483		;SGT.B (Ar)

	scc_drb		shi.b,$53ed7abe		;SHI.B Dr
	scc_mmb		shi.b,$eecbe70a		;SHI.B (Ar)

	scc_drb		sle.b,$43952b59		;SLE.B Dr
	scc_mmb		sle.b,$bf18b424		;SLE.B (Ar)

	scc_drb		sls.b,$ccb08715		;SLS.B Dr
	scc_mmb		sls.b,$8f2ee7ad		;SLS.B (Ar)

	scc_drb		slt.b,$d70284d1		;SLT.B Dr
	scc_mmb		slt.b,$17ca5849		;SLT.B (Ar)

	scc_drb		smi.b,$8a966c0c		;SMI.B Dr
	scc_mmb		smi.b,$f35ed0ce		;SMI.B (Ar)

	scc_drb		sne.b,$05949b5b		;SNE.B Dr
	scc_mmb		sne.b,$2f5efe22		;SNE.B (Ar)

	scc_drb		spl.b,$15cb91a7		;SPL.B Dr
	scc_mmb		spl.b,$92bbd069		;SPL.B (Ar)

	scc_drb		st.b,$f58640ea		;ST.B Dr
	scc_mmb		st.b,$7ab70769		;ST.B (Ar)

						;STOP #<data>

	xxx_drb_drb	sub.b,$aa8d83a4		;SUB.B Dr,Dq
	xxx_drw_drw	sub.w,$ce0eea42		;SUB.W Dr,Dq
	xxx_drl_drl	sub.l,$df02ff19		;SUB.L Dr,Dq
	xxx_mmb_drb	sub.b,$20490a0c		;SUB.B (Ar),Dq
	xxx_mmw_drw	sub.w,$93c45876		;SUB.W (Ar),Dq
	xxx_mml_drl	sub.l,$df02ff19		;SUB.L (Ar),Dq
	xxx_drb_mmb	sub.b,$ebee7b12		;SUB.B Dq,(Ar)
	xxx_drw_mmw	sub.w,$4998b8cd		;SUB.W Dq,(Ar)
	xxx_drl_mml	sub.l,$df02ff19		;SUB.L Dq,(Ar)

	xxx_drw_arl	suba.w,$f9655d5e	;SUBA.W Dr,Aq
	xxx_drl_arl	suba.l,$3e19a1f5	;SUBA.L Dr,Aq
	xxx_mmw_arl	suba.w,$4fe9975c	;SUBA.W (Ar),Aq
	xxx_mml_arl	suba.l,$8d8b0d61	;SUBA.L (Ar),Aq

	xxx_imb_drb	subi.b,$6548d587	;SUBI.B #<data>,Dr
	xxx_imw_drw	subi.w,$da083f65	;SUBI.W #<data>,Dr
	xxx_iml_drl	subi.l,$bd5e2986	;SUBI.L #<data>,Dr
	xxx_imb_mmb	subi.b,$e19b72d5	;SUBI.B #<data>,(Ar)
	xxx_imw_mmw	subi.w,$a019a3c0	;SUBI.W #<data>,(Ar)
	xxx_iml_mml	subi.l,$bd5e2986	;SUBI.L #<data>,(Ar)

	xxx_imq_drb	subq.b,$df442035	;SUBQ.B #<data>,Dr
	xxx_imq_drw	subq.w,$ad97e2cb	;SUBQ.W #<data>,Dr
	xxx_imq_drl	subq.l,$7bd965a2	;SUBQ.L #<data>,Dr
	xxx_imq_arl	subq.w,$d49b31ca	;SUBQ.W #<data>,Ar
	xxx_imq_arl	subq.l,$d49b31ca	;SUBQ.L #<data>,Ar
	xxx_imq_mmb	subq.b,$733f7edd	;SUBQ.B #<data>,(Ar)
	xxx_imq_mmw	subq.w,$895f6ae1	;SUBQ.W #<data>,(Ar)
	xxx_imq_mml	subq.l,$7bd965a2	;SUBQ.L #<data>,(Ar)

	xxx_drb_drb	subx.b,$cd38d550	;SUBX.B Dr,Dq
	xxx_drw_drw	subx.w,$bfa9bfe7	;SUBX.W Dr,Dq
	xxx_drl_drl	subx.l,$52c67bee	;SUBX.L Dr,Dq
	xxx_mnb_mnb	subx.b,$ef4be3b4	;SUBX.B -(Ar),-(Aq)
	xxx_mnw_mnw	subx.w,$73bac18a	;SUBX.W -(Ar),-(Aq)
	xxx_mnl_mnl	subx.l,$70e4bdfd	;SUBX.L -(Ar),-(Aq)

	scc_drb		svc.b,$a812a837		;SVC.B Dr
	scc_mmb		svc.b,$9e238fee		;SVC.B (Ar)

	scc_drb		svs.b,$374f559c		;SVS.B Dr
	scc_mmb		svs.b,$ffc68f49		;SVS.B (Ar)

	xxx_drl		swap.w,$ff4afbbe	;SWAP.W Dr

	xxx_drb		tas.b,$15441690		;TAS.B Dr
	xxx_mmb		tas.b,$c53c453d		;TAS.B (Ar)

						;TRAP #<vector>

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	trapcc_no_operand	trapcc,$c7866a5a	;TRAPCC
	trapcc_imw		trapcc.w,$08209489	;TRAPCC.W #<data>
	trapcc_iml		trapcc.l,$eefc9d87	;TRAPCC.L #<data>

	trapcc_no_operand	trapcs,$82f68dbf	;TRAPCS
	trapcc_imw		trapcs.w,$f959fabe	;TRAPCS.W #<data>
	trapcc_iml		trapcs.l,$3392f53e	;TRAPCS.L #<data>

	trapcc_no_operand	trapeq,$82270921	;TRAPEQ
	trapcc_imw		trapeq.w,$5ae75c45	;TRAPEQ.W #<data>
	trapcc_iml		trapeq.l,$ebe616e3	;TRAPEQ.L #<data>

	trapcc_no_operand	trapf,$91267e8a		;TRAPF
	trapcc_imw		trapf.w,$4103eade	;TRAPF.W #<data>
	trapcc_iml		trapf.l,$c6c1838a	;TRAPF.L #<data>

	trapcc_no_operand	trapge,$349dafb9	;TRAPGE
	trapcc_imw		trapge.w,$483d37b7	;TRAPGE.W #<data>
	trapcc_iml		trapge.l,$7ece02cb	;TRAPGE.L #<data>

	trapcc_no_operand	trapgt,$a5af1d2f	;TRAPGT
	trapcc_imw		trapgt.w,$f5f11462	;TRAPGT.W #<data>
	trapcc_iml		trapgt.l,$709010e1	;TRAPGT.L #<data>

	trapcc_no_operand	traphi,$da3fc2e1	;TRAPHI
	trapcc_imw		traphi.w,$5f5216da	;TRAPHI.W #<data>
	trapcc_iml		traphi.l,$1e563252	;TRAPHI.L #<data>

	trapcc_no_operand	traple,$e0dffaca	;TRAPLE
	trapcc_imw		traple.w,$04887a55	;TRAPLE.W #<data>
	trapcc_iml		traple.l,$adfe7858	;TRAPLE.L #<data>

	trapcc_no_operand	trapls,$9f4f2504	;TRAPLS
	trapcc_imw		trapls.w,$ae2b78ed	;TRAPLS.W #<data>
	trapcc_iml		trapls.l,$c3385aeb	;TRAPLS.L #<data>

	trapcc_no_operand	traplt,$71ed485c	;TRAPLT
	trapcc_imw		traplt.w,$b9445980	;TRAPLT.W #<data>
	trapcc_iml		traplt.l,$a3a06a72	;TRAPLT.L #<data>

	trapcc_no_operand	trapmi,$e17ead4b	;TRAPMI
	trapcc_imw		trapmi.w,$426d9e91	;TRAPMI.W #<data>
	trapcc_iml		trapmi.l,$b565b306	;TRAPMI.L #<data>

	trapcc_no_operand	trapne,$c757eec4	;TRAPNE
	trapcc_imw		trapne.w,$ab9e3272	;TRAPNE.W #<data>
	trapcc_iml		trapne.l,$36887e5a	;TRAPNE.L #<data>

	trapcc_no_operand	trappl,$a40e4aae	;TRAPPL
	trapcc_imw		trappl.w,$b314f0a6	;TRAPPL.W #<data>
	trapcc_iml		trappl.l,$680bdbbf	;TRAPPL.L #<data>

	trapcc_no_operand	trapt,$d456996f		;TRAPT
	trapcc_imw		trapt.w,$b07a84e9	;TRAPT.W #<data>
	trapcc_iml		trapt.l,$1bafeb33	;TRAPT.L #<data>
	.cpu	68000
@@:

	xxx_no_operand	trapv,$03368893		;TRAPV

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	trapcc_no_operand	trapvc,$44c57c78	;TRAPVC
	trapcc_imw		trapvc.w,$4b5343f8	;TRAPVC.W #<data>
	trapcc_iml		trapvc.l,$0d6a3247	;TRAPVC.L #<data>

	trapcc_no_operand	trapvs,$01b59b9d	;TRAPVS
	trapcc_imw		trapvs.w,$ba2a2dcf	;TRAPVS.W #<data>
	trapcc_iml		trapvs.l,$d0045afe	;TRAPVS.L #<data>
	.cpu	68000
@@:

	xxx_drb		tst.b,$ed48450b		;TST.B Dr
	xxx_drw		tst.w,$d8339ec6		;TST.W Dr
	xxx_drl		tst.l,$0f744a3c		;TST.L Dr
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_arw		tst.w,$6d28f97f		;TST.W Ar
	xxx_arl		tst.l,$7ae85bfe		;TST.L Ar
	.cpu	68000
@@:
	xxx_mmb		tst.b,$ac5a5068		;TST.B (Ar)
	xxx_mmw		tst.w,$c52515d8		;TST.W (Ar)
	xxx_mml		tst.l,$0f744a3c		;TST.L (Ar)
	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_imb		tst.b,$30e1c1dc		;TST.B #<data>
	xxx_imw		tst.w,$6b28ecd2		;TST.W #<data>
	xxx_iml		tst.l,$80995333		;TST.L #<data>
	.cpu	68000
@@:

	unlk_arl	unlk,$0b6076c4		;UNLK Ar

	moveq.l	#MC68020|MC68030|MC68040|MC68060,d0
	and.b	mpu_mask,d0
	beq	@f
	.cpu	68020
	xxx_drb_drw_imw	unpk,$4359d714		;UNPK Dr,Dq,#<data>
	xxx_mnb_mnw_imw	unpk,$5316c1a7		;UNPK -(Ar),-(Aq),#<data>
	.cpu	68000
@@:

	jbra	mnemonic_loop

mnemonic_done:

new_ctrlvc:
new_errjvc:
	clr.l	abort_illegal_instruction

	move.l	timerc_counter,test_ended

	move.l	old_timerc_handler,d0
	beq	@f
	move.l	d0,-(sp)
	move.w	#69,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:

	move.l	old_privilege_instruction,d0
	beq	@f
	move.l	d0,-(sp)
	move.w	#8,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:

	move.l	old_trapv_instruction,d0
	beq	@f
	move.l	d0,-(sp)
	move.w	#7,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:

	move.l	old_chk_instruction,d0
	beq	@f
	move.l	d0,-(sp)
	move.w	#6,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:

	move.l	old_divide_by_zero,d0
	beq	@f
	move.l	d0,-(sp)
	move.w	#5,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:

	move.l	old_illegal_instruction,d0
	beq	@f
	move.l	d0,-(sp)
	move.w	#4,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
@@:

	move.l	old_ctrlvc,-(sp)
	move.w	#_CTRLVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp
	move.l	old_errjvc,-(sp)
	move.w	#_ERRJVC,-(sp)
	DOS	_INTVCS
	addq.l	#6,sp

;end
	jbsr	test_end

exit:
	DOS	_EXIT

;?d0
print_header:
	print	'processor:MC680'
	moveq.l	#'0',d0
	add.b	mpu_type,d0
	move.w	d0,-(sp)
	jbsr	putchar_by_write
	addq.l	#2,sp
	print	'0, level:'
	cmpi.b	#EASY,test_level
	bne	1f
	print	'easy',13,10
	bra	2f
1:	print	'hard',13,10
2:
;		           1111111111222222222233333333334444444444555555555566666666667777777777
;		 01234567890123456789012345678901234567890123456789012345678901234567890123456789
;		                                     $xxxxxxxx   $xxxxxxxx   OK
	print	'           instruction               expected     actual',13,10
	rts

	.align	4
old_ctrlvc:
	.dc.l	0
old_errjvc:
	.dc.l	0

	.bss

last_level:
	.ds.b	1	;-1=first,0=easy,1=hard
test_level:
	.ds.b	1	;0=easy,1=hard
mpu_type:
	.ds.b	1	;0=MC68000,1=MC68010,2=MC68020,3=MC68030,4=MC68040,6=MC68060
mpu_mask:
	.ds.b	1	;1=MC68000,2=MC68010,4=MC68020,8=MC68030,16=MC68040,64=MC68060
first_mnemonic:
	.ds.b	1	;0=not first,-1=first

	.align	4
mnemonic_pointer:
	.ds.l	1

	.align	4
work_area_start:
	.ds.b	$8000*10
work_area:
	.ds.b	$8000*10
work_area_end:

	.align	4
	.ds.b	1024*64
stack_area_end:


;--------------------------------------------------------------------------------
;test flag

	.fail	TEST_LIMIT<test_number	;TEST_LIMIT is not enough

	.bss
	.align	4
test_flag:
	.ds.b	TEST_LIMIT


;--------------------------------------------------------------------------------
;illegal instruction
	.text
	.even
new_illegal_instruction:
	tst.l	abort_illegal_instruction
	bne	10f			;abort
	move.l	old_illegal_instruction,-(sp)
	rts
;abort
10:	move.l	abort_illegal_instruction,2(sp)	;catch
	bset.b	#7,illegal_instruction_flag
	rte

	.data
illegal_instruction_flag:
	.dc.b	0
	.align	4
abort_illegal_instruction:
	.dc.l	0
old_illegal_instruction:
	.dc.l	0

;<carry flag:1=illegal instruction
	.text
	.even
print_illegal_instruction:
	bcc	@f
	pea.l	10f(pc)
	jbsr	print_by_write
	addq.l	#4,sp
	addq.l	#1,test_failed
@@:	rts
10:	.dc.b	'illegal instruction',13,10,0
	.even


;--------------------------------------------------------------------------------
;divide by zero
	.text
	.even
new_divide_by_zero:
	bset.b	#7,divide_by_zero_flag
	cmpi.b	#EASY,test_level
	bne	@f
	andi.w	#.notw.(CCR_N|CCR_Z|CCR_V),(sp)	;easy: don't test undefined N,Z,V
@@:
	andi.w	#.notw.(CCR_Z|CCR_V),(sp)	;don't test undefined Z,V
	rte

	.data
divide_by_zero_flag:
	.dc.b	0
	.align	4
old_divide_by_zero:
	.dc.l	0


;--------------------------------------------------------------------------------
;chk instruction
	.text
	.even
new_chk_instruction:
	bset.b	#7,chk_instruction_flag
	rte

	.data
chk_instruction_flag:
	.dc.b	0
	.align	4
old_chk_instruction:
	.dc.l	0


;--------------------------------------------------------------------------------
;trapv instruction
	.text
	.even
new_trapv_instruction:
	bset.b	#7,trapv_instruction_flag
	rte

	.data
trapv_instruction_flag:
	.dc.b	0
	.align	4
old_trapv_instruction:
	.dc.l	0


;--------------------------------------------------------------------------------
;privilege instruction
;	MOVE.W SR,<ea>					|-|-12346|P|*****|-----|D M+-WXZ  |0100_000_011_mmm_rrr
;	MOVE.W CCR,<ea>					|-|-12346|-|*****|-----|D M+-WXZ  |0100_001_011_mmm_rrr
	.text
	.even
new_privilege_instruction:
	movem.l	d0-d1/a0,-(sp)
	movea.l	14(sp),a0		;pc
	moveq.l	#$ffffffc0,d0
	and.w	(a0),d0			;oc
	cmp.w	#$40c0,d0
	beq	10f			;move-from-sr
	movem.l	(sp)+,d0-d1/a0
	move.l	old_privilege_instruction,-(sp)
	rts

;move-from-sr
10:	ori.w	#$0200,(a0)		;modify move-from-sr to move-from-ccr
	jbsr	cache_flush
	movem.l	(sp)+,d0-d1/a0
	rte

	.data
	.align	4
old_privilege_instruction:
	.dc.l	0


;--------------------------------------------------------------------------------
;timerc
	.text
	.even
new_timerc_handler:
	addq.l	#1,timerc_counter
	move.l	old_timerc_handler,-(sp)
	rts

	.data
	.align	4
old_timerc_handler:
	.dc.l	0
timerc_counter:
	.dc.l	0


;--------------------------------------------------------------------------------
;mnemonic
;<d0.l:test_number
;<a0.l:mnemonic
;>d0.l:0=skip,1=test
;?a0-a1
	.text
	.even
mnemonic_check:
	movem.l	a0-a2,-(sp)
	lea.l	test_flag,a2
	adda.l	d0,a2
	tst.b	(a2)
	bne	2f			;already tested
	lea.l	mnemonic_buffer,a1
	cmpi.l	#'all'<<8,(a1)
	beq	3f			;all
1:	tst.b	(a1)
	beq	3f
	cmpm.b	(a0)+,(a1)+
	beq	1b
2:	moveq.l	#0,d0			;skip
	bra	4f
3:	st.b	(a2)

	move.b	test_level,d0
	cmp.b	last_level,d0
	beq	@f
	move.b	d0,last_level
	jbsr	print_header
@@:

	move.l	timerc_counter,mnemonic_started

	moveq.l	#1,d0			;test
4:	movem.l	(sp)+,a0-a2
	rts

	.bss
	.align	4
mnemonic_buffer:
	.ds.b	256+4
	.align	4
mnemonic_started:
	.ds.l	1
mnemonic_ended:
	.ds.l	1


;--------------------------------------------------------------------------------
;test
	.text
	.even
test_start:
	clr.l	test_failed
	clr.l	test_tested
	rts

;<d1.l:expected crc32
;<CRC32_REG.l:actual crc32
;?d0
	.text
	.even
test_check:
	move.l	timerc_counter,mnemonic_ended
	movem.l	d0-d1,-(sp)
	addq.l	#1,test_tested
	move.l	d1,d0			;expected crc32
	jbsr	print_hex8
	print	'   '
	move.l	CRC32_REG,d0		;actual crc32
	jbsr	print_hex8
	cmp.l	CRC32_REG,d1
	bne	1f
	print	'   OK      '
	bra	2f
1:	print	'   ERROR   '
	addq.l	#1,test_failed
2:	move.l	mnemonic_ended,d0
	sub.l	mnemonic_started,d0
	moveq.l	#2,d1
	jbsr	print_fix
	print	's',13,10
	movem.l	(sp)+,d0-d1
	rts

test_end:
	movem.l	d0-d4,-(sp)
	move.l	test_failed,d2
;<d2.lfailed
	move.l	test_tested,d3
;<d3.l:tested
	move.l	d3,d4
	sub.l	d2,d4
;<d4.l:passed
	print	'tested:'
	move.l	d3,d0			;tested
	jbsr	print_dec
	tst.l	d3
	beq	38f			;no tests were performed
	print	', passed:'
	move.l	d4,d0			;passed
	jbsr	print_dec
	print	'('
	mulu.w	#10000,d0
	divu.w	d3,d0			;10000*passed/tested
	and.l	#$0000ffff,d0
	move.l	#10000,d4
	sub.w	d0,d4			;100-100*passed/tested
	moveq.l	#2,d1
	jbsr	print_fix
	print	'%), failed:'
	move.l	d2,d0			;failed
	jbsr	print_dec
	print	'('
	move.l	d4,d0			;100-100*passed/tested
	jbsr	print_fix
	print	'%)'
38:
	jbsr	print_crlf
	move.l	test_ended,d0
	sub.l	test_started,d0
	moveq.l	#2,d1
	jbsr	print_fix
	print	's',13,10
	movem.l	(sp)+,d0-d4
	rts

	.bss
	.align	4
test_failed:
	.ds.l	1
test_tested:
	.ds.l	1
test_started:
	.ds.l	1
test_ended:
	.ds.l	1


;--------------------------------------------------------------------------------
;ccr data
	.data

	.align	4
ccr_mono_data:
	.dc.w	0,31
;sentry
	.dc.w	0

	.align	4
ccr_light_data:
	.dc.w	%00000,%11111,%00001,%11110,%00010,%11101,%00100,%11011,%01000,%10111,%10000,%01111
;sentry
	.dc.w	0

	.align	4
ccr_full_data:
	.dc.w	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
;sentry
	.dc.w	0


;--------------------------------------------------------------------------------
;bit field data
	.data
	.align	4
bf_offset_data:
	.dc.l	0,1,7,8,9,15,16,17,23,24,25,31	;zero must appear first
	.dc.l	32,33,39,40,41,47,48,49,55,56,57,63
	.dc.l	-32,-31,-25,-24,-23,-17,-16,-15,-9,-8,-7,-1
;sentry
	.dc.l	0
bf_width_data:
	.dc.l	1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32
;sentry
	.dc.l	0


;--------------------------------------------------------------------------------
;byte data

put_byte	.macro	x
	.dc.l	x
	.dc.l	.notb.(x)
	.dc.l	$ffffff00+(x)
	.dc.l	$ffffff00+.notb.(x)
	.endm

	.data

	.align	4
byte_mono_data:
;no one
	put_byte	0
;sentry
	.dc.l	0

	.align	4
byte_light_data:
;no one
	put_byte	0
;one one
  .irp i,0,1,7
	put_byte	1<<i
  .endm
;two ones
  .irp i,0,1,7
    .irp j,0,1,7
      .if i>j
	put_byte	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,7
    .irp j,0,1,7
      .if i>j+1
	put_byte	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
byte_medium_data:
;no one
	put_byte	0
;one one
  .irp i,0,1,2,4,6,7
	put_byte	1<<i
  .endm
;two ones
  .irp i,0,1,2,4,6,7
    .irp j,0,1,2,4,6,7
      .if i>j
	put_byte	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,2,4,6,7
    .irp j,0,1,2,4,6,7
      .if i>j+1
	put_byte	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
byte_heavy_data:
;no one
	put_byte	0
;one one
  .irp i,0,1,2,3,4,5,6,7
	put_byte	1<<i
  .endm
;two ones
  .irp i,0,1,2,3,4,5,6,7
    .irp j,0,1,2,3,4,5,6,7
      .if i>j
	put_byte	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,2,3,4,5,6,7
    .irp j,0,1,2,3,4,5,6,7
      .if i>j+1
	put_byte	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
byte_full_data:
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
    .irp j,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	put_byte	(i<<4)+j
    .endm
  .endm
;sentry
	.dc.l	0


;--------------------------------------------------------------------------------
;word data

put_word	.macro	x
	.dc.l	x
	.dc.l	.notw.(x)
	.dc.l	$ffff0000+(x)
	.dc.l	$ffff0000+.notw.(x)
	.endm

	.data

	.align	4
word_mono_data:
;no one
	put_word	0
;sentry
	.dc.l	0

	.align	4
word_light_data:
;no one
	put_word	0
;one one
  .irp i,0,1,7,8,9,15
	put_word	1<<i
  .endm
;two ones
  .irp i,0,1,7,8,9,15
    .irp j,0,1,7,8,9,15
      .if i>j
	put_word	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,7,8,9,15
    .irp j,0,1,7,8,9,15
      .if i>j+1
	put_word	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
word_medium_data:
;no one
	put_word	0
;one one
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15
	put_word	1<<i
  .endm
;two ones
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15
    .irp j,0,1,2,4,6,7,8,9,10,12,14,15
      .if i>j
	put_word	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15
    .irp j,0,1,2,4,6,7,8,9,10,12,14,15
      .if i>j+1
	put_word	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
word_heavy_data:
;no one
	put_word	0
;one one
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	put_word	1<<i
  .endm
;two ones
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
    .irp j,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
      .if i>j
	put_word	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
    .irp j,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
      .if i>j+1
	put_word	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0


;--------------------------------------------------------------------------------
;long data

put_long	.macro	x
	.dc.l	x
	.dc.l	.not.(x)
	.endm

	.data

	.align	4
long_mono_data:
;no one
	put_long	0
;sentry
	.dc.l	0

	.align	4
long_light_data:
;no one
	put_long	0
;one one
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31
	put_long	1<<i
  .endm
;two ones
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31
    .irp j,0,1,7,8,9,15,16,17,23,24,25,31
      .if i>j
	put_long	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31
    .irp j,0,1,7,8,9,15,16,17,23,24,25,31
      .if i>j+1
	put_long	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
long_medium_data:
;no one
	put_long	0
;one one
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15,16,17,18,20,22,23,24,25,26,28,30,31
	put_long	1<<i
  .endm
;two ones
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15,16,17,18,20,22,23,24,25,26,28,30,31
    .irp j,0,1,2,4,6,7,8,9,10,12,14,15,16,17,18,20,22,23,24,25,26,28,30,31
      .if i>j
	put_long	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15,16,17,18,20,22,23,24,25,26,28,30,31
    .irp j,0,1,2,4,6,7,8,9,10,12,14,15,16,17,18,20,22,23,24,25,26,28,30,31
      .if i>j+1
	put_long	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0

	.align	4
long_heavy_data:
;no one
	put_long	0
;one one
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
	put_long	1<<i
  .endm
;two ones
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
    .irp j,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
      .if i>j
	put_long	(1<<i)+(1<<j)
      .endif
    .endm
  .endm
;three or more consecutive ones
  .irp i,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
    .irp j,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31
      .if i>j+1
	put_long	(2<<i)-(1<<j)
      .endif
    .endm
  .endm
;sentry
	.dc.l	0


;--------------------------------------------------------------------------------
;quad data

put_quad	.macro	xh,xl
	.dc.l	xh,xl
	.dc.l	.not.(xh),.not.(xl)
	.endm

	.data

	.align	4
quad_mono_data:
;no one
	put_quad	0,0
;sentry
	.dc.l	0,0

	.align	4
quad_light_data:
;no one
	put_quad	0,0
;one one
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31,32,33,39,40,41,47,48,49,55,56,57,63
    .if i<32
	put_quad	0,1<<i
    .else
	put_quad	1<<(i-32),0
    .endif
  .endm
;two ones
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31,32,33,39,40,41,47,48,49,55,56,57,63
    .irp j,0,1,7,8,9,15,16,17,23,24,25,31,32,33,39,40,41,47,48,49,55,56,57,63
      .if i>j
        .if i<32
	put_quad	0,(1<<i)+(1<<j)
        .elif j<32
	put_quad	1<<(i-32),1<<j
        .else
	put_quad	(1<<(i-32))+(1<<(j-32)),0
        .endif
      .endif
    .endm
  .endm
;sentry
	.dc.l	0,0


;--------------------------------------------------------------------------------
;sext data

put_sext	.macro	xh,xm,xl
	.dc.l	xh,xm,xl
	.dc.l	.not.(xh),.not.(xm),.not.(xl)
	.endm

	.data

	.align	4
sext_mono_data:
;no one
	put_sext	0,0,0
;sentry
	.dc.l	0,0,0

	.align	4
sext_light_data:
;no one
	put_sext	0,0,0
;one one
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31,32,33,39,40,41,47,48,49,55,56,57,63,64,65,71,72,73,79,80,81,87,88,89,95
    .if i<32
	put_sext	0,0,1<<i
    .elif i<64
	put_sext	0,1<<(i-32),0
    .else
	put_sext	1<<(i-64),0,0
    .endif
  .endm
;sentry
	.dc.l	0,0,0


;--------------------------------------------------------------------------------
;oct data

put_oct	.macro	x0,x1,x2,x3
	.dc.l	x0,x1,x2,x3
	.dc.l	.not.(x0),.not.(x1),.not.(x2),.not.(x3)
	.endm

	.data

	.align	4
oct_mono_data:
;no one
	put_oct	0,0,0,0
;sentry
	.dc.l	0,0,0,0

	.align	4
oct_light_data:
;no one
	put_oct	0,0,0,0
;one one
  .irp i,0,1,7,8,9,15,16,17,23,24,25,31,32,33,39,40,41,47,48,49,55,56,57,63,64,65,71,72,73,79,80,81,87,88,89,95,96,97,103,104,105,111,112,113,119,120,121,127
    .if i<32
	put_oct	0,0,0,1<<i
    .elif i<64
	put_oct	0,0,1<<(i-32),0
    .elif i<96
	put_oct	0,1<<(i-64),0,0
    .else
	put_oct	1<<(i-96),0,0,0
    .endif
  .endm
;sentry
	.dc.l	0,0,0,0

	.align	4
oct_medium_data:
;no one
	put_oct	0,0,0,0
;one one
  .irp i,0,1,2,4,6,7,8,9,10,12,14,15,16,17,18,20,22,23,24,25,26,28,30,31,32,33,34,36,38,39,40,41,42,44,46,47,48,49,50,52,54,55,56,57,58,60,62,63,64,65,66,68,70,71,72,73,74,76,78,79,80,81,82,84,86,87,88,89,90,92,94,95,96,97,98,100,102,103,104,105,106,108,110,111,112,113,114,116,118,119,120,121,122,124,126,127
    .if i<32
	put_oct	0,0,0,1<<i
    .elif i<64
	put_oct	0,0,1<<(i-32),0
    .elif i<96
	put_oct	0,1<<(i-64),0,0
    .else
	put_oct	1<<(i-96),0,0,0
    .endif
  .endm
;sentry
	.dc.l	0,0,0,0


;--------------------------------------------------------------------------------
;mpu
	.text
	.even
mpu_check:
	move.l	mpu_number,d0
	bmi	@f
	rts

@@:	movem.l	d1/a0-a1,-(sp)
;
	clr.l	-(sp)
	DOS	_SUPER
	move.l	d0,(sp)
;
	move.w	sr,-(sp)		;sr
	ori.w	#$0700,sr
	move.l	$002c.w,-(sp)		;line 1111 emulator
	move.l	$0010.w,-(sp)		;illegal instruction
	lea.l	100f(pc),a1
	move.l	a1,$0010.w
	move.l	a1,$002c.w
	movea.l	sp,a1
;MC68000
;!VBR
	moveq.l	#0,d1
	lea.l	99f(pc),a0
	.cpu	68010
	movec.l	vbr,d0
	.cpu	68000
;MC68010
;VBR && !scale factor
	moveq.l	#1,d1
	moveq.l	#1,d0
	.cpu	68020
	and.b	(*-3,pc,d0.w*2),d0
	.cpu	68010
	beq	99f
;MC68020
;CALLM
	moveq.l	#2,d1
	lea.l	29f(pc),a0
	.cpu	68020
	callm	#0,21f(pc)
	.cpu	68000
	bra	99f

;module descriptor
21:	.dc.l	0<<13|0<<24|0<<16	;option=0,type=0,accesslevel=0
	.dc.l	22f			;module entry pointer
	.dc.l	0			;module data area pointer
	.dc.l	0
;module entry
22:	.dc.w	15<<12			;Rn=sp
	.cpu	68020
	rtm	sp
	.cpu	68000

29:
;MC68030
;!CALLM && CAAR
	moveq.l	#3,d1
	lea.l	39f(pc),a0
	.cpu	68030
	movec.l	caar,d0
	.cpu	68000
	bra	99f

39:
;MC68040
;MMUSR
	moveq.l	#4,d1
	lea.l	49f(pc),a0
	.cpu	68040
	movec.l	mmusr,d0
	.cpu	68000
	bra	99f

49:
;MC68060
;PCR
	moveq.l	#6,d1
	lea.l	69f(pc),a0
	.cpu	68060
	movec.l	pcr,d0
	.cpu	68000
	bra	99f

69:
;unknown
	moveq.l	#0,d1
;
99:	move.l	(sp)+,$0010.w		;illegal instruction
	move.l	(sp)+,$002c.w		;line 1111 emulator
	move.w	(sp)+,sr		;sr
;
	DOS	_SUPER
	addq.l	#4,sp
;
	move.l	d1,d0
	movem.l	(sp)+,d1/a0-a1
	move.l	d0,mpu_number
	rts

100:	movea.l	a1,sp
	jmp	(a0)

;cache flush
;	supervisor mode only
cache_flush:
	move.l	d0,-(sp)
	jbsr	mpu_check
	subq.b	#2,d0
	bcs	9f
	subq.b	#4-2,d0
	bcc	4f
;MC68020/MC68030
	.cpu	68030
	movec.l	cacr,d0
	or.w	#$0808,d0
	movec.l	d0,cacr
	and.w	#$f7f7,d0
	movec.l	d0,cacr
	.cpu	68000
	bra	9f

;MC68040/MC68060
4:	.cpu	68040
	cpusha	bc
	.cpu	68000
9:	move.l	(sp)+,d0
	rts

	.data
	.align	4
mpu_number:
	.dc.l	-1

;--------------------------------------------------------------------------------
;crc32
  .if 0
	.text
	.even
crc32_test:
	move.l	d0,-(sp)
;crc32('A')=$d3d99e8b
	jbsr	crc32_reset
	moveq.l	#'A',d0
	jbsr	crc32_byte
	jbsr	crc32_print
	jbsr	print_crlf
;crc32('ABCD')=$db1720a5
	jbsr	crc32_reset
	move.l	#'ABCD',d0
	jbsr	crc32_long
	jbsr	crc32_print
	jbsr	print_crlf
	move.l	(sp)+,d0
	rts

crc32_print:
	move.l	d0,-(sp)
	move.l	CRC32_REG,d0
	jbsr	print_hex8
	move.l	(sp)+,d0
	rts
  .endif

	.text
	.even
crc32_reset:
	moveq.l	#0,CRC32_REG
	rts

;<d0.b:data
;<CRC32_REG.l:crc32
;>CRC32_REG.l:crc32
;?d0
	.text
	.even
crc32_byte:
	move.l	d0,-(sp)
	not.l	CRC32_REG
	eor.b	d0,CRC32_REG
	moveq.l	#0,d0
	move.b	CRC32_REG,d0
	lsr.l	#8,CRC32_REG
	lsl.w	#2,d0
	move.l	crc32_table(pc,d0.w),d0
	eor.l	d0,CRC32_REG
	not.l	CRC32_REG
	move.l	(sp)+,d0
	rts

;<d0.w:data
;<CRC32_REG.l:crc32
;>CRC32_REG.l:crc32
	.text
	.even
crc32_word:
	movem.l	d0-d1,-(sp)
	not.l	CRC32_REG
	moveq.l	#-2,d1
1:	moveq.l	#0,d0
	move.b	4(sp,d1.w),d0
	eor.b	CRC32_REG,d0
	lsr.l	#8,CRC32_REG
	lsl.w	#2,d0
	move.l	crc32_table(pc,d0.w),d0
	eor.l	d0,CRC32_REG
	addq.w	#1,d1
	bne	1b
	not.l	CRC32_REG
	movem.l	(sp)+,d0-d1
	rts

;<d0.l:data
;<CRC32_REG.l:crc32
;>CRC32_REG.l:crc32
	.text
	.even
crc32_long:
	movem.l	d0-d1,-(sp)
	not.l	CRC32_REG
	moveq.l	#-4,d1
1:	moveq.l	#0,d0
	move.b	4(sp,d1.w),d0
	eor.b	CRC32_REG,d0
	lsr.l	#8,CRC32_REG
	lsl.w	#2,d0
	move.l	crc32_table(pc,d0.w),d0
	eor.l	d0,CRC32_REG
	addq.w	#1,d1
	bne	1b
	not.l	CRC32_REG
	movem.l	(sp)+,d0-d1
	rts

	.text
	.align	4
crc32_table:
	.dc.l	$00000000,$77073096,$ee0e612c,$990951ba,$076dc419,$706af48f,$e963a535,$9e6495a3
	.dc.l	$0edb8832,$79dcb8a4,$e0d5e91e,$97d2d988,$09b64c2b,$7eb17cbd,$e7b82d07,$90bf1d91
	.dc.l	$1db71064,$6ab020f2,$f3b97148,$84be41de,$1adad47d,$6ddde4eb,$f4d4b551,$83d385c7
	.dc.l	$136c9856,$646ba8c0,$fd62f97a,$8a65c9ec,$14015c4f,$63066cd9,$fa0f3d63,$8d080df5
	.dc.l	$3b6e20c8,$4c69105e,$d56041e4,$a2677172,$3c03e4d1,$4b04d447,$d20d85fd,$a50ab56b
	.dc.l	$35b5a8fa,$42b2986c,$dbbbc9d6,$acbcf940,$32d86ce3,$45df5c75,$dcd60dcf,$abd13d59
	.dc.l	$26d930ac,$51de003a,$c8d75180,$bfd06116,$21b4f4b5,$56b3c423,$cfba9599,$b8bda50f
	.dc.l	$2802b89e,$5f058808,$c60cd9b2,$b10be924,$2f6f7c87,$58684c11,$c1611dab,$b6662d3d
	.dc.l	$76dc4190,$01db7106,$98d220bc,$efd5102a,$71b18589,$06b6b51f,$9fbfe4a5,$e8b8d433
	.dc.l	$7807c9a2,$0f00f934,$9609a88e,$e10e9818,$7f6a0dbb,$086d3d2d,$91646c97,$e6635c01
	.dc.l	$6b6b51f4,$1c6c6162,$856530d8,$f262004e,$6c0695ed,$1b01a57b,$8208f4c1,$f50fc457
	.dc.l	$65b0d9c6,$12b7e950,$8bbeb8ea,$fcb9887c,$62dd1ddf,$15da2d49,$8cd37cf3,$fbd44c65
	.dc.l	$4db26158,$3ab551ce,$a3bc0074,$d4bb30e2,$4adfa541,$3dd895d7,$a4d1c46d,$d3d6f4fb
	.dc.l	$4369e96a,$346ed9fc,$ad678846,$da60b8d0,$44042d73,$33031de5,$aa0a4c5f,$dd0d7cc9
	.dc.l	$5005713c,$270241aa,$be0b1010,$c90c2086,$5768b525,$206f85b3,$b966d409,$ce61e49f
	.dc.l	$5edef90e,$29d9c998,$b0d09822,$c7d7a8b4,$59b33d17,$2eb40d81,$b7bd5c3b,$c0ba6cad
	.dc.l	$edb88320,$9abfb3b6,$03b6e20c,$74b1d29a,$ead54739,$9dd277af,$04db2615,$73dc1683
	.dc.l	$e3630b12,$94643b84,$0d6d6a3e,$7a6a5aa8,$e40ecf0b,$9309ff9d,$0a00ae27,$7d079eb1
	.dc.l	$f00f9344,$8708a3d2,$1e01f268,$6906c2fe,$f762575d,$806567cb,$196c3671,$6e6b06e7
	.dc.l	$fed41b76,$89d32be0,$10da7a5a,$67dd4acc,$f9b9df6f,$8ebeeff9,$17b7be43,$60b08ed5
	.dc.l	$d6d6a3e8,$a1d1937e,$38d8c2c4,$4fdff252,$d1bb67f1,$a6bc5767,$3fb506dd,$48b2364b
	.dc.l	$d80d2bda,$af0a1b4c,$36034af6,$41047a60,$df60efc3,$a867df55,$316e8eef,$4669be79
	.dc.l	$cb61b38c,$bc66831a,$256fd2a0,$5268e236,$cc0c7795,$bb0b4703,$220216b9,$5505262f
	.dc.l	$c5ba3bbe,$b2bd0b28,$2bb45a92,$5cb36a04,$c2d7ffa7,$b5d0cf31,$2cd99e8b,$5bdeae1d
	.dc.l	$9b64c2b0,$ec63f226,$756aa39c,$026d930a,$9c0906a9,$eb0e363f,$72076785,$05005713
	.dc.l	$95bf4a82,$e2b87a14,$7bb12bae,$0cb61b38,$92d28e9b,$e5d5be0d,$7cdcefb7,$0bdbdf21
	.dc.l	$86d3d2d4,$f1d4e242,$68ddb3f8,$1fda836e,$81be16cd,$f6b9265b,$6fb077e1,$18b74777
	.dc.l	$88085ae6,$ff0f6a70,$66063bca,$11010b5c,$8f659eff,$f862ae69,$616bffd3,$166ccf45
	.dc.l	$a00ae278,$d70dd2ee,$4e048354,$3903b3c2,$a7672661,$d06016f7,$4969474d,$3e6e77db
	.dc.l	$aed16a4a,$d9d65adc,$40df0b66,$37d83bf0,$a9bcae53,$debb9ec5,$47b2cf7f,$30b5ffe9
	.dc.l	$bdbdf21c,$cabac28a,$53b39330,$24b4a3a6,$bad03605,$cdd70693,$54de5729,$23d967bf
	.dc.l	$b3667a2e,$c4614ab8,$5d681b02,$2a6f2b94,$b40bbe37,$c30c8ea1,$5a05df1b,$2d02ef8d


;--------------------------------------------------------------------------------
;print decimal number
;<d0.l:number
	.text
	.even
print_dec:
	movem.l	d0-d2/a0-a1,-(sp)
	lea.l	-12(sp),sp
	movea.l	sp,a0
	tst.l	d0
	bne	1f
	move.b	#'0',(a0)+
	bra	5f
1:
	lea.l	base_ten(pc),a1
2:
	move.l	(a1)+,d1
	cmp.l	d1,d0
	blo	2b
3:
	moveq.l	#'0'-1,d2
4:
	addq.b	#1,d2
	sub.l	d1,d0
	bcc	4b
	add.l	d1,d0
	move.b	d2,(a0)+
	move.l	(a1)+,d1
	bne	3b
5:
	suba.l	sp,a0
	move.l	a0,-(sp)
	pea.l	4(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10+12(sp),sp
	movem.l	(sp)+,d0-d2/a0-a1
	rts


;--------------------------------------------------------------------------------
;print fixed point decimal number
;<d0.l:fixed point decimal number * 10^d1
;<d1.b:number of digits after decimal point (>=1)
	.text
	.even
print_fix:
	movem.l	d0-d4/a0-a1,-(sp)
	moveq.l	#0,d3
	move.b	d1,d3
;<d3.l:number of digits after decimal point (>=1)
	move.l	d3,d4
	addq.w	#3,d4
	and.w	#-4,d4		;round up to multiples of four
	add.w	#12,d4		;12 bytes for integer part and decimal point
;<d4.l:buffer size
	suba.l	d4,sp
;<sp.l:buffer
	movea.l	sp,a0
	tst.l	d0
	bne	20f
;zero
	move.b	#'0',(a0)+
	move.b	#'.',(a0)+
	move.w	d3,d2		;number of digits after decimal point (>=1)
	bra	12f

11:
	move.b	#'0',(a0)+
12:
	dbra	d2,11b
	bra	80f		;print

;non-zero
20:
	lea.l	base_ten(pc),a1
;zero suppression
21:
	move.l	(a1)+,d1
	cmp.l	d1,d0
	blo	21b
;convert to decimal number
22:
	moveq.l	#'0'-1,d2
23:
	addq.b	#1,d2
	sub.l	d1,d0
	bcc	23b
	add.l	d1,d0
	move.b	d2,(a0)+
	move.l	(a1)+,d1
	bne	22b
;
	move.l	a0,d2
	sub.l	sp,d2
;<d2.l:number of digits
	cmp.w	d3,d2
	bls	40f
;number of digits > number of digits after decimal point
;insert '.'
	move.w	d3,d2		;number of digits after decimal point (>=1)
	movea.l	a0,a1
	addq.l	#1,a0
	bra	32f

31:
	move.b	-(a1),1(a1)
32:
	dbra	d2,31b
	move.b	#'.',(a1)
	bra	80f

40:
;number of digits after decimal point >= number of digits
;insert '0.00...'
	move.w	d3,d0		;number of digits after decimal point (>=1)
	sub.w	d2,d0		;number of zeros after decimal point (>=0)
	movea.l	a0,a1
	lea.l	2(a0,d0.w),a0
	bra	42f

41:
	move.b	-(a1),2(a1,d0.w)
42:
	dbra	d2,41b
	movea.l	sp,a1
	move.b	#'0',(a1)+
	move.b	#'.',(a1)+
	bra	44f

43:
	move.b	#'0',(a1)+
44:
	dbra	d0,43b

;print
80:
	suba.l	sp,a0
	move.l	a0,-(sp)	;length
	pea.l	4(sp)		;buffer
	move.w	#1,-(sp)	;stdout
	DOS	_WRITE
	lea.l	10(sp),sp
	adda.l	d4,sp
	movem.l	(sp)+,d0-d4/a0-a1
	rts

	.align	4
base_ten:
	.dc.l	1000000000
	.dc.l	100000000
	.dc.l	10000000
	.dc.l	1000000
	.dc.l	100000
	.dc.l	10000
	.dc.l	1000
	.dc.l	100
	.dc.l	10
	.dc.l	1
	.dc.l	0


;--------------------------------------------------------------------------------
;print hexadecimal number
;<d0.l:number
	.text
	.even
print_hex8:
	movem.l	d0-d2/a0,-(sp)
	lea.l	-10(sp),sp
	movea.l	sp,a0
	move.b	#'$',(a0)+
	moveq.l	#8-1,d2
2:
	rol.l	#4,d0
	moveq.l	#15,d1
	and.w	d0,d1
	move.b	10f(pc,d1.w),(a0)+
	dbra	d2,2b
	pea.l	1+8.w
	pea.l	4(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10+10(sp),sp
	movem.l	(sp)+,d0-d2/a0
	rts

10:
	.dc.b	'0123456789abcdef'


;--------------------------------------------------------------------------------
;print crlf
	.text
	.even
print_crlf:
	move.l	d0,-(sp)
	pea.l	2.w
	pea.l	10f(pc)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	move.l	(sp)+,d0
	rts

10:
	.dc.b	13,10


;--------------------------------------------------------------------------------
;print character
;<4(sp).w:character
	.text
	.even
putchar_by_write:
	move.l	d0,-(sp)
	pea.l	1.w
	pea.l	12+1(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	move.l	(sp)+,d0
	rts


;--------------------------------------------------------------------------------
;print string
;<4(sp).l:string
	.text
	.even
print_by_write:
	movem.l	d0/a0-a1,-(sp)
	movea.l	16(sp),a1
	movea.l	a1,a0
@@:
	tst.b	(a1)+
	bne	@b
	subq.l	#1,a1
	suba.l	a0,a1
	movem.l	a0-a1,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	10(sp),sp
	movem.l	(sp)+,d0/a0-a1
	rts


;--------------------------------------------------------------------------------
;end
	.end	main

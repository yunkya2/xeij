;----------------------------------------------------------------
;
;	68060 INTEGER SOFTWARE PACKAGE
;
;----------------------------------------------------------------

	.cpu	68060

	.xdef	_060ISP_TABLE

	.xdef	_isp_unimp		;_060ISP_TABLE+$00
					;_060ISP_TABLE+$00000238
	.xdef	_isp_cas		;_060ISP_TABLE+$08
					;_060ISP_TABLE+$00001630
	.xdef	_isp_cas2		;_060ISP_TABLE+$10
					;_060ISP_TABLE+$000012EE
	.xdef	_isp_cas_finish		;_060ISP_TABLE+$18
					;_060ISP_TABLE+$00001204
	.xdef	_isp_cas2_finish	;_060ISP_TABLE+$20
					;_060ISP_TABLE+$00001100
	.xdef	_isp_cas_inrange	;_060ISP_TABLE+$28
					;_060ISP_TABLE+$000012CE
	.xdef	_isp_cas_terminate	;_060ISP_TABLE+$30
					;_060ISP_TABLE+$00001288
	.xdef	_isp_cas_restart	;_060ISP_TABLE+$38
					;_060ISP_TABLE+$00001264

global	.macro
	.endm

;----------------------------------------------------------------
;ISPコールアウトテーブル
_I_CALL_TOP::
	.dc.l	_060_real_chk-_I_CALL_TOP
	.dc.l	_060_real_divbyzero-_I_CALL_TOP
	.dc.l	_060_real_trace-_I_CALL_TOP
	.dc.l	_060_real_access-_I_CALL_TOP
	.dc.l	_060_isp_done-_I_CALL_TOP
	.dc.l	_isp_cas-_I_CALL_TOP	;_060ISP_TABLE+$08-_I_CALL_TOP
					;_060ISP_TABLE+$00001630-_I_CALL_TOP
	.dc.l	_isp_cas2-_I_CALL_TOP	;_060ISP_TABLE+$10-_I_CALL_TOP
					;_060ISP_TABLE+$000012EE-_I_CALL_TOP
	.dc.l	_060_real_lock_page-_I_CALL_TOP
	.dc.l	_060_real_unlock_page-_I_CALL_TOP
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	_060_imem_read-_I_CALL_TOP
	.dc.l	_060_dmem_read-_I_CALL_TOP
	.dc.l	_060_dmem_write-_I_CALL_TOP
	.dc.l	_060_imem_read_word-_I_CALL_TOP
	.dc.l	_060_imem_read_long-_I_CALL_TOP
	.dc.l	_060_dmem_read_byte-_I_CALL_TOP
	.dc.l	_060_dmem_read_word-_I_CALL_TOP
	.dc.l	_060_dmem_read_long-_I_CALL_TOP
	.dc.l	_060_dmem_write_byte-_I_CALL_TOP
	.dc.l	_060_dmem_write_word-_I_CALL_TOP
	.dc.l	_060_dmem_write_long-_I_CALL_TOP
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	0
	.dc.l	0
;----------------------------------------------------------------
;ISP本体

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* MOTOROLA MICROPROCESSOR & MEMORY TECHNOLOGY GROUP
* M68000 Hi-Performance Microprocessor Division
* M68060 Software Package Production Release 
* 
* M68060 Software Package Copyright (C) 1993, 1994, 1995, 1996 Motorola Inc.
* All rights reserved.
* 
* THE SOFTWARE is provided on an "AS IS" basis and without warranty.
* To the maximum extent permitted by applicable law,
* MOTOROLA DISCLAIMS ALL WARRANTIES WHETHER EXPRESS OR IMPLIED,
* INCLUDING IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS
* FOR A PARTICULAR PURPOSE and any warranty against infringement with
* regard to the SOFTWARE (INCLUDING ANY MODIFIED VERSIONS THEREOF)
* and any accompanying written materials. 
* 
* To the maximum extent permitted by applicable law,
* IN NO EVENT SHALL MOTOROLA BE LIABLE FOR ANY DAMAGES WHATSOEVER
* (INCLUDING WITHOUT LIMITATION, DAMAGES FOR LOSS OF BUSINESS PROFITS,
* BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR OTHER PECUNIARY LOSS)
* ARISING OF THE USE OR INABILITY TO USE THE SOFTWARE.
* 
* Motorola assumes no responsibility for the maintenance and support
* of the SOFTWARE.  
* 
* You are hereby granted a copyright license to use, modify, and distribute the
* SOFTWARE so long as this entire notice is retained without alteration
* in any modified and/or redistributed versions, and that such modified
* versions are clearly identified as such.
* No licenses are granted by implication, estoppel or otherwise under any
* patents or trademarks of Motorola, Inc.
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*
* ireal.s:
*	This file is appended to the top of the 060ISP package
* and contains the entry points into the package. The user, in
* effect, branches to one of the branch table entries located
* after _060ISP_TABLE.
*	Also, subroutine stubs exist in this file (_isp_done for
* example) that are referenced by the ISP package itself in order
* to call a given routine. The stub routine actually performs the
* callout. The ISP code does a "bsr" to the stub routine. This
* extra layer of hierarchy adds a slight performance penalty but
* it makes the ISP code easier to read and more mainatinable.
*

_off_chk	set	$00
_off_divbyzero	set	$04
_off_trace	set	$08
_off_access	set	$0c
_off_done	set	$10

_off_cas	set	$14
_off_cas2	set	$18
_off_lock	set	$1c
_off_unlock	set	$20

_off_imr	set	$40
_off_dmr	set	$44
_off_dmw	set	$48
_off_irw	set	$4c
_off_irl	set	$50
_off_drb	set	$54
_off_drw	set	$58
_off_drl	set	$5c
_off_dwb	set	$60
_off_dww	set	$64
_off_dwl	set	$68

_060ISP_TABLE:

* Here's the table of ENTRY POINTS for those linking the package.
	bra.l	_isp_unimp
	.dc.w	$0000

	bra.l	_isp_cas
	.dc.w	$0000

	bra.l	_isp_cas2
	.dc.w	$0000

	bra.l	_isp_cas_finish
	.dc.w	$0000

	bra.l	_isp_cas2_finish
	.dc.w	$0000

	bra.l	_isp_cas_inrange
	.dc.w	$0000

	bra.l	_isp_cas_terminate
	.dc.w	$0000

	bra.l	_isp_cas_restart
	.dc.w	$0000

	.dcb.w	64/2,$51FC

*############################################################

	global	_real_chk
_real_chk:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_chk,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_real_divbyzero
_real_divbyzero:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_divbyzero,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_real_trace
_real_trace:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_trace,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_real_access
_real_access:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_access,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_isp_done
_isp_done:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_done,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

*######################################

	global	_real_cas
_real_cas:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_cas,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_real_cas2
_real_cas2:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_cas2,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_real_lock_page
_real_lock_page:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_lock,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_real_unlock_page
_real_unlock_page:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_unlock,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

*######################################

	global	_imem_read
_imem_read:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_imr,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_read
_dmem_read:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_dmr,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_write
_dmem_write:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_dmw,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_imem_read_word
_imem_read_word:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_irw,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_imem_read_long
_imem_read_long:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_irl,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_read_byte
_dmem_read_byte:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_drb,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_read_word
_dmem_read_word:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_drw,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_read_long
_dmem_read_long:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_drl,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_write_byte
_dmem_write_byte:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_dwb,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_write_word
_dmem_write_word:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_dww,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

	global	_dmem_write_long
_dmem_write_long:
	move.l	d0,-(sp)
	move.l	(_060ISP_TABLE-$80+_off_dwl,pc),d0
	pea.l	(_060ISP_TABLE-$80.l,pc,d0.l)
	move.l	$4(sp),d0
	rtd	#$4

*
* This file contains a set of define statements for constants
* in oreder to promote readability within the core code itself.
*

LOCAL_SIZE	set	96		* stack frame size(bytes)
LV	set	-LOCAL_SIZE		* stack offset

EXC_ISR	set	$4			* stack status register
EXC_IPC	set	$6			* stack pc
EXC_IVOFF	set	$a		* stacked vector offset

EXC_AREGS	set	LV+64		* offset of all address regs
EXC_DREGS	set	LV+32		* offset of all data regs

EXC_A7	set	EXC_AREGS+(7*4)		* offset of a7
EXC_A6	set	EXC_AREGS+(6*4)		* offset of a6
EXC_A5	set	EXC_AREGS+(5*4)		* offset of a5
EXC_A4	set	EXC_AREGS+(4*4)		* offset of a4
EXC_A3	set	EXC_AREGS+(3*4)		* offset of a3
EXC_A2	set	EXC_AREGS+(2*4)		* offset of a2
EXC_A1	set	EXC_AREGS+(1*4)		* offset of a1
EXC_A0	set	EXC_AREGS+(0*4)		* offset of a0
EXC_D7	set	EXC_DREGS+(7*4)		* offset of d7
EXC_D6	set	EXC_DREGS+(6*4)		* offset of d6
EXC_D5	set	EXC_DREGS+(5*4)		* offset of d5
EXC_D4	set	EXC_DREGS+(4*4)		* offset of d4
EXC_D3	set	EXC_DREGS+(3*4)		* offset of d3
EXC_D2	set	EXC_DREGS+(2*4)		* offset of d2
EXC_D1	set	EXC_DREGS+(1*4)		* offset of d1
EXC_D0	set	EXC_DREGS+(0*4)		* offset of d0

EXC_TEMP	set	LV+16		* offset of temp stack space

EXC_SAVVAL	set	LV+12		* offset of old areg value
EXC_SAVREG	set	LV+11		* offset of old areg index

SPCOND_FLG	set	LV+10		* offset of spc condition flg

EXC_CC	set	LV+8			* offset of cc register
EXC_EXTWPTR	set	LV+4		* offset of current PC
EXC_EXTWORD	set	LV+2		* offset of current ext opword
EXC_OPWORD	set	LV+0		* offset of current opword

*##########################
* SPecial CONDition FLaGs #
*##########################
mia7_flg	set	$04		* (a7)+ flag
mda7_flg	set	$08		* -(a7) flag
ichk_flg	set	$10		* chk exception flag
idbyz_flg	set	$20		* divbyzero flag
restore_flg	set	$40		* restore -(an)+ flag
immed_flg	set	$80		* immediate data flag

mia7_bit	set	$2		* (a7)+ bit
mda7_bit	set	$3		* -(a7) bit
ichk_bit	set	$4		* chk exception bit
idbyz_bit	set	$5		* divbyzero bit
restore_bit	set	$6		* restore -(a7)+ bit
immed_bit	set	$7		* immediate data bit

*########
* Misc. #
*########
BYTE	set	1			* len(byte) == 1 byte
WORD	set	2			* len(word) == 2 bytes
LONG	set	4			* len(longword) == 4 bytes

*########################################################################
* XDEF ****************************************************************	#
*	_isp_unimp(): 060ISP entry point for Unimplemented Instruction	#
*									#
*	This handler should be the first code executed upon taking the 	#
* 	"Unimplemented Integer Instruction" exception in an operating	#
*	system.								#
*									#
* XREF ****************************************************************	#
*	_imem_read_{word,long}() - read instruction word/longword	#
*	_mul64() - emulate 64-bit multiply				#
* 	_div64() - emulate 64-bit divide				#
*	_moveperipheral() - emulate "movep"				#
*	_compandset() - emulate misaligned "cas"			#
*	_compandset2() - emulate "cas2"					#
*	_chk2_cmp2() - emulate "cmp2" and "chk2"			#
*	_isp_done() - "callout" for normal final exit			#
*	_real_trace() - "callout" for Trace exception			#
*	_real_chk() - "callout" for Chk exception			#
*	_real_divbyzero() - "callout" for DZ exception			#
*	_real_access() - "callout" for access error exception		#
*									#
* INPUT ***************************************************************	#
*	- The system stack contains the Unimp Int Instr stack frame	#
* 									#
* OUTPUT **************************************************************	#
*	If Trace exception:						#
*	- The system stack changed to contain Trace exc stack frame	#
*	If Chk exception:						#
*	- The system stack changed to contain Chk exc stack frame	#
*	If DZ exception:						#
*	- The system stack changed to contain DZ exc stack frame	#
*	If access error exception:					#
*	- The system stack changed to contain access err exc stk frame	#
*	Else:								#
*	- Results saved as appropriate					#
*									#
* ALGORITHM ***********************************************************	#
*	This handler fetches the first instruction longword from	#
* memory and decodes it to determine which of the unimplemented		#
* integer instructions caused this exception. This handler then calls	#
* one of _mul64(), _div64(), _moveperipheral(), _compandset(), 		#
* _compandset2(), or _chk2_cmp2() as appropriate. 			#
*	Some of these instructions, by their nature, may produce other	#
* types of exceptions. "div" can produce a divide-by-zero exception,	#
* and "chk2" can cause a "Chk" exception. In both cases, the current	#
* exception stack frame must be converted to an exception stack frame	#
* of the correct exception type and an exit must be made through	#
* _real_divbyzero() or _real_chk() as appropriate. In addition, all	#
* instructions may be executing while Trace is enabled. If so, then	#
* a Trace exception stack frame must be created and an exit made 	#
* through _real_trace().						#
*	Meanwhile, if any read or write to memory using the		#
* _mem_{read,write}() "callout"s returns a failing value, then an	#
* access error frame must be created and an exit made through		#
* _real_access().							#
*	If none of these occur, then a normal exit is made through	#
* _isp_done().								#
*									#
*	This handler, upon entry, saves almost all user-visible 	#
* address and data registers to the stack. Although this may seem to	#
* cause excess memory traffic, it was found that due to having to	#
* access these register files for things like data retrieval and <ea>	#
* calculations, it was more efficient to have them on the stack where	#
* they could be accessed by indexing rather than to make subroutine 	#
* calls to retrieve a register of a particular index. 			#
*									#
*########################################################################

	global	_isp_unimp
_isp_unimp:
	link.w	a6,#-LOCAL_SIZE		* create room for stack frame

	movem.l	d0-d7/a0-a5,EXC_DREGS(a6)	* store d0-d7/a0-a5
	move.l	(a6),EXC_A6(a6)		* store a6

	btst	#$5,EXC_ISR(a6)		* from s or u mode?
	bne.b	uieh_s			* supervisor mode
uieh_u:
	move.l	usp,a0			* fetch user stack pointer
	move.l	a0,EXC_A7(a6)		* store a7
	bra.b	uieh_cont
uieh_s:
	lea	$c(a6),a0
	move.l	a0,EXC_A7(a6)		* store corrected sp

*##############################################################################

uieh_cont:
	clr.b	SPCOND_FLG(a6)		* clear "special case" flag

	move.w	EXC_ISR(a6),EXC_CC(a6)		* store cc copy on stack
	move.l	EXC_IPC(a6),EXC_EXTWPTR(a6)	* store extwptr on stack

*
* fetch the opword and first extension word pointed to by the stacked pc
* and store them to the stack for now
*
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$4,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_long		* fetch opword & extword
	move.l	d0,EXC_OPWORD(a6)	* store extword on stack


*########################################################################
* muls.l	0100 1100 00 |<ea>|	0*** 1100 0000 0*** 		#
* mulu.l	0100 1100 00 |<ea>|	0*** 0100 0000 0***		#
*									#
* divs.l	0100 1100 01 |<ea>|	0*** 1100 0000 0***		#
* divu.l	0100 1100 01 |<ea>|	0*** 0100 0000 0***		#
*									#
* movep.w m2r	0000 ***1 00 001***	| <displacement>  |		#
* movep.l m2r	0000 ***1 01 001***	| <displacement>  |		#
* movep.w r2m	0000 ***1 10 001***	| <displacement>  |		#
* movep.l r2m	0000 ***1 11 001***	| <displacement>  |		#
*									#
* cas.w		0000 1100 11 |<ea>|	0000 000* **00 0***		#
* cas.l		0000 1110 11 |<ea>|	0000 000* **00 0***		#
*									#
* cas2.w	0000 1100 11 111100	**** 000* **00 0***		#
*					**** 000* **00 0***		#
* cas2.l	0000 1110 11 111100	**** 000* **00 0***		#
*					**** 000* **00 0***		#
*									#
* chk2.b	0000 0000 11 |<ea>|	**** 1000 0000 0000		#
* chk2.w	0000 0010 11 |<ea>|	**** 1000 0000 0000		#
* chk2.l	0000 0100 11 |<ea>|	**** 1000 0000 0000		#
*									#
* cmp2.b	0000 0000 11 |<ea>|	**** 0000 0000 0000		#
* cmp2.w	0000 0010 11 |<ea>|	**** 0000 0000 0000		#
* cmp2.l	0000 0100 11 |<ea>|	**** 0000 0000 0000		#
*########################################################################

*
* using bit 14 of the operation word, separate into 2 groups:
* (group1) mul64, div64
* (group2) movep, chk2, cmp2, cas2, cas
*
	btst	#$1e,d0			* group1 or group2
	beq.b	uieh_group2		* go handle group2

*
* now, w/ group1, make mul64's decode the fastest since it will
* most likely be used the most.
*
uieh_group1:
	btst	#$16,d0			* test for div64
	bne.b	uieh_div64		* go handle div64

uieh_mul64:
* mul64() may use ()+ addressing and may, therefore, alter a7

	bsr.l	_mul64			* _mul64()

	btst	#$5,EXC_ISR(a6)		* supervisor mode?
	beq.w	uieh_done
	btst	#mia7_bit,SPCOND_FLG(a6)	* was a7 changed?
	beq.w	uieh_done		* no
	btst	#$7,EXC_ISR(a6)		* is trace enabled?
	bne.w	uieh_trace_a7		* yes
	bra.w	uieh_a7			* no

uieh_div64:
* div64() may use ()+ addressing and may, therefore, alter a7.
* div64() may take a divide by zero exception.

	bsr.l	_div64			* _div64()

* here, we sort out all of the special cases that may have happened.
	btst	#mia7_bit,SPCOND_FLG(a6)	* was a7 changed?
	bne.b	uieh_div64_a7		* yes
uieh_div64_dbyz:
	btst	#idbyz_bit,SPCOND_FLG(a6)	* did divide-by-zero occur?
	bne.w	uieh_divbyzero		* yes
	bra.w	uieh_done		* no
uieh_div64_a7:
	btst	#$5,EXC_ISR(a6)		* supervisor mode?
	beq.b	uieh_div64_dbyz		* no
* here, a7 has been incremented by 4 bytes in supervisor mode. we still
* may have the following 3 cases:
*	(i)	(a7)+
*	(ii)	(a7)+; trace
*	(iii)	(a7)+; divide-by-zero
*
	btst	#idbyz_bit,SPCOND_FLG(a6)	* did divide-by-zero occur?
	bne.w	uieh_divbyzero_a7	* yes
	tst.b	EXC_ISR(a6)		* no; is trace enabled?
	bmi.w	uieh_trace_a7		* yes
	bra.w	uieh_a7			* no

*
* now, w/ group2, make movep's decode the fastest since it will
* most likely be used the most.
*
uieh_group2:
	btst	#$18,d0			* test for not movep
	beq.b	uieh_not_movep


	bsr.l	_moveperipheral		* _movep()
	bra.w	uieh_done

uieh_not_movep:
	btst	#$1b,d0			* test for chk2,cmp2
	beq.b	uieh_chk2cmp2		* go handle chk2,cmp2

	swap	d0			* put opword in lo word
	cmpi.b	#$fc,d0			* test for cas2
	beq.b	uieh_cas2		* go handle cas2

uieh_cas:

	bsr.l	_compandset		* _cas()

* the cases of "cas Dc,Du,(a7)+" and "cas Dc,Du,-(a7)" used from supervisor
* mode are simply not considered valid and therefore are not handled.

	bra.w	uieh_done

uieh_cas2:

	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word		* read extension word

	tst.l	d1			* ifetch error?
	bne.w	isp_iacc		* yes

	bsr.l	_compandset2		* _cas2()
	bra.w	uieh_done

uieh_chk2cmp2:
* chk2 may take a chk exception

	bsr.l	_chk2_cmp2		* _chk2_cmp2()

* here we check to see if a chk trap should be taken
	cmpi.b	#ichk_flg,SPCOND_FLG(a6)
	bne.w	uieh_done
	bra.b	uieh_chk_trap

*##########################################################################

*
* the required emulation has been completed. now, clean up the necessary stack
* info and prepare for rte
*
uieh_done:
	move.b	EXC_CC+1(a6),EXC_ISR+1(a6)	* insert new ccodes

* if exception occurred in user mode, then we have to restore a7 in case it
* changed. we don't have to update a7  for supervisor mose because that case
* doesn't flow through here
	btst	#$5,EXC_ISR(a6)		* user or supervisor?
	bne.b	uieh_finish		* supervisor

	move.l	EXC_A7(a6),a0		* fetch user stack pointer
	move.l	a0,usp			* restore it

uieh_finish:
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5

	btst	#$7,EXC_ISR(a6)		* is trace mode on?
	bne.b	uieh_trace		* yes;go handle trace mode

	move.l	EXC_EXTWPTR(a6),EXC_IPC(a6)	* new pc on stack frame
	move.l	EXC_A6(a6),(a6)		* prepare new a6 for unlink
	unlk	a6			* unlink stack frame
	bra.l	_isp_done

*
* The instruction that was just emulated was also being traced. The trace 
* trap for this instruction will be lost unless we jump to the trace handler.
* So, here we create a Trace Exception format number two exception stack
* frame from the Unimplemented Integer Intruction Exception stack frame
* format number zero and jump to the user supplied hook "_real_trace()".
*
*		   UIEH FRAME		   TRACE FRAME
*		*****************	*****************
*		* 0x0 *  0x0f4	*	*    Current	*
*		*****************	*      PC	*
*		*    Current	*	*****************
*		*      PC 	*	* 0x2 *  0x024	*
*		*****************	*****************
*		*      SR	*	*     Next	*
*		*****************	*      PC	*
*	      ->*     Old   	*	*****************
*  from link -->*      A6	*	*      SR	*
*	        *****************	*****************
*	       /*      A7	*	*      New	* <-- for final unlink
*	      / *		*	*      A6	*
* link frame <  *****************	*****************
*	      \ ~		~	~		~
*	       \*****************	*****************
*
uieh_trace:
	move.l	EXC_A6(a6),-$4(a6)
	move.w	EXC_ISR(a6),$0.w(a6)
	move.l	EXC_IPC(a6),$8(a6)
	move.l	EXC_EXTWPTR(a6),$2(a6)
	move.w	#$2024,$6(a6)
	sub.l	#$4,a6
	unlk	a6
	bra.l	_real_trace

*
*	   UIEH FRAME		    CHK FRAME
*	*****************	*****************
*	* 0x0 *  0x0f4	*	*    Current	*
*	*****************	*      PC	*
*	*    Current	*	*****************
*	*      PC	*	* 0x2 *  0x018	*
*	*****************	*****************
*	*      SR	*	*     Next	*
*	*****************	*      PC	*
*	    (4 words)		*****************
*				*      SR	*
*				*****************
*				    (6 words)
*
* the chk2 instruction should take a chk trap. so, here we must create a
* chk stack frame from an unimplemented integer instruction exception frame
* and jump to the user supplied entry point "_real_chk()".
*
uieh_chk_trap:
	move.b	EXC_CC+1(a6),EXC_ISR+1(a6)	* insert new ccodes
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5

	move.w	EXC_ISR(a6),(a6)	* put new SR on stack
	move.l	EXC_IPC(a6),$8(a6)	* put "Current PC" on stack
	move.l	EXC_EXTWPTR(a6),$2(a6)		* put "Next PC" on stack
	move.w	#$2018,$6(a6)		* put Vector Offset on stack

	move.l	EXC_A6(a6),a6		* restore a6
	add.l	#LOCAL_SIZE,sp		* clear stack frame

	bra.l	_real_chk

*
*	   UIEH FRAME		 DIVBYZERO FRAME
*	*****************	*****************
*	* 0x0 *  0x0f4	*	*    Current	*
*	*****************	*      PC	*
*	*    Current	*	*****************
*	*      PC	*	* 0x2 *  0x014	*
*	*****************	*****************
*	*      SR	*	*     Next	*
*	*****************	*      PC	*
*	    (4 words)		*****************
*				*      SR	*
*				*****************
*				    (6 words)
*
* the divide instruction should take an integer divide by zero trap. so, here 
* we must create a divbyzero stack frame from an unimplemented integer 
* instruction exception frame and jump to the user supplied entry point 
* "_real_divbyzero()".
*
uieh_divbyzero:
	move.b	EXC_CC+1(a6),EXC_ISR+1(a6)	* insert new ccodes
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5

	move.w	EXC_ISR(a6),(a6)	* put new SR on stack
	move.l	EXC_IPC(a6),$8(a6)	* put "Current PC" on stack
	move.l	EXC_EXTWPTR(a6),$2(a6)		* put "Next PC" on stack
	move.w	#$2014,$6(a6)		* put Vector Offset on stack

	move.l	EXC_A6(a6),a6		* restore a6
	add.l	#LOCAL_SIZE,sp		* clear stack frame

	bra.l	_real_divbyzero

*
*				 DIVBYZERO FRAME
*				*****************
*				*    Current	*
*	   UIEH FRAME		*      PC	*
*	*****************	*****************
*	* 0x0 *  0x0f4	*	* 0x2 * 0x014	*
*	*****************	*****************
*	*    Current	*	*     Next	*
*	*      PC	*	*      PC	*
*	*****************	*****************
*	*      SR	*	*      SR	*
*	*****************	*****************
*	    (4 words)		    (6 words)
*
* the divide instruction should take an integer divide by zero trap. so, here 
* we must create a divbyzero stack frame from an unimplemented integer 
* instruction exception frame and jump to the user supplied entry point 
* "_real_divbyzero()".
*
* However, we must also deal with the fact that (a7)+ was used from supervisor
* mode, thereby shifting the stack frame up 4 bytes.
*
uieh_divbyzero_a7:
	move.b	EXC_CC+1(a6),EXC_ISR+1(a6)	* insert new ccodes
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5

	move.l	EXC_IPC(a6),$c(a6)	* put "Current PC" on stack
	move.w	#$2014,$a(a6)		* put Vector Offset on stack
	move.l	EXC_EXTWPTR(a6),$6(a6)		* put "Next PC" on stack

	move.l	EXC_A6(a6),a6		* restore a6
	add.l	#4+LOCAL_SIZE,sp	* clear stack frame

	bra.l	_real_divbyzero

*
*				   TRACE FRAME
*				*****************
*				*    Current	*
*	   UIEH FRAME		*      PC	*
*	*****************	*****************
*	* 0x0 *  0x0f4	*	* 0x2 * 0x024	*
*	*****************	*****************
*	*    Current	*	*     Next	*
*	*      PC	*	*      PC	*
*	*****************	*****************
*	*      SR	*	*      SR	*
*	*****************	*****************
*	    (4 words)		    (6 words)
*
* 
* The instruction that was just emulated was also being traced. The trace 
* trap for this instruction will be lost unless we jump to the trace handler.
* So, here we create a Trace Exception format number two exception stack
* frame from the Unimplemented Integer Intruction Exception stack frame
* format number zero and jump to the user supplied hook "_real_trace()".
*
* However, we must also deal with the fact that (a7)+ was used from supervisor
* mode, thereby shifting the stack frame up 4 bytes.
*
uieh_trace_a7:
	move.b	EXC_CC+1(a6),EXC_ISR+1(a6)	* insert new ccodes
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5

	move.l	EXC_IPC(a6),$c(a6)	* put "Current PC" on stack
	move.w	#$2024,$a(a6)		* put Vector Offset on stack
	move.l	EXC_EXTWPTR(a6),$6(a6)		* put "Next PC" on stack

	move.l	EXC_A6(a6),a6		* restore a6
	add.l	#4+LOCAL_SIZE,sp	* clear stack frame

	bra.l	_real_trace

*
*				   UIEH FRAME	
*				*****************
*				* 0x0 * 0x0f4	*
*	   UIEH FRAME		*****************
*	*****************	*     Next	*
*	* 0x0 *  0x0f4	*	*      PC	*	
*	*****************	*****************
*	*    Current	*	*      SR	*
*	*      PC	*	*****************
*	*****************	    (4 words)
*	*      SR	*
*	*****************
*	    (4 words)
uieh_a7:
	move.b	EXC_CC+1(a6),EXC_ISR+1(a6)	* insert new ccodes
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5

	move.w	#$00f4,$e(a6)		* put Vector Offset on stack
	move.l	EXC_EXTWPTR(a6),$a(a6)		* put "Next PC" on stack
	move.w	EXC_ISR(a6),$8(a6)	* put SR on stack

	move.l	EXC_A6(a6),a6		* restore a6
	add.l	#8+LOCAL_SIZE,sp	* clear stack frame
	bra.l	_isp_done

*#########

* this is the exit point if a data read or write fails.
* a0 = failing address
* d0 = fslw
isp_dacc:
	move.l	a0,(a6)			* save address	
	move.l	d0,-$4(a6)		* save partial fslw

	lea	-64(a6),sp
	movem.l	(sp)+,d0-d7/a0-a6	* restore d0-d7/a0-a6

	move.l	$c(sp),-(sp)		* move voff,hi(pc)
	move.l	$4(sp),$10(sp)		* store fslw
	move.l	$c(sp),$4(sp)		* store sr,lo(pc)
	move.l	$8(sp),$c(sp)		* store address
	move.l	(sp)+,$4(sp)		* store voff,hi(pc)
	move.w	#$4008,$6(sp)		* store new voff

	bra.b	isp_acc_exit

* this is the exit point if an instruction word read fails.
* FSLW:
*	misaligned = true
*	read = true
* 	size = word
* 	instruction = true
* 	software emulation error = true
isp_iacc:
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore d0-d7/a0-a5
	unlk	a6			* unlink frame
	sub.w	#$8,sp			* make room for acc frame
	move.l	$8(sp),(sp)		* store sr,lo(pc)
	move.w	$c(sp),$4(sp)		* store hi(pc)
	move.w	#$4008,$6(sp)		* store new voff
	move.l	$2(sp),$8(sp)		* store address (=pc)
	move.l	#$09428001,$c(sp)	* store fslw

isp_acc_exit:
	btst	#$5,(sp)		* user or supervisor?
	beq.b	isp_acc_exit2		* user
	bset	#$2,$d(sp)		* set supervisor TM bit
isp_acc_exit2:
	bra.l	_real_access

* if the addressing mode was (an)+ or -(an), the address register must
* be restored to it's pre-exception value before entering _real_access.
isp_restore:
	cmpi.b	#restore_flg,SPCOND_FLG(a6)	* do we need a restore?
	bne.b	isp_restore_done	* no
	clr.l	d0
	move.b	EXC_SAVREG(a6),d0	* regno to restore
	move.l	EXC_SAVVAL(a6),(EXC_AREGS,a6,d0.l*4)	* restore value
isp_restore_done:
	rts

*########################################################################
* XDEF ****************************************************************	#
*	_calc_ea(): routine to calculate effective address		#
*									#
* XREF ****************************************************************	#
* 	_imem_read_word() - read instruction word			#
* 	_imem_read_long() - read instruction longword			#
* 	_dmem_read_long() - read data longword (for memory indirect)	#
* 	isp_iacc() - handle instruction access error exception		#
*	isp_dacc() - handle data access error exception			#
*									#
* INPUT ***************************************************************	#
* 	d0 = number of bytes related to effective address (w,l)		#
*									#
* OUTPUT **************************************************************	#
*	If exiting through isp_dacc...					#
*		a0 = failing address					#
*		d0 = FSLW						#
*	elsif exiting though isp_iacc...				#
*		none							#
*	else								#
*		a0 = effective address					#
*									#
* ALGORITHM ***********************************************************	#
* 	The effective address type is decoded from the opword residing	#
* on the stack. A jump table is used to vector to a routine for the 	#
* appropriate mode. Since none of the emulated integer instructions	#
* uses byte-sized operands, only handle word and long operations.	#
*									#
* 	Dn,An	- shouldn't enter here					#
*	(An)	- fetch An value from stack				#
* 	-(An)	- fetch An value from stack; return decr value;		#
*		  place decr value on stack; store old value in case of	#
*		  future access error; if -(a7), set mda7_flg in 	#
*		  SPCOND_FLG						#
*	(An)+	- fetch An value from stack; return value;		#
*		  place incr value on stack; store old value in case of	#
*		  future access error; if (a7)+, set mia7_flg in	#
*		  SPCOND_FLG						#
*	(d16,An) - fetch An value from stack; read d16 using 		#
*		  _imem_read_word(); fetch may fail -> branch to	#
*		  isp_iacc()						#
*	(xxx).w,(xxx).l - use _imem_read_{word,long}() to fetch		#
*		  address; fetch may fail				#
*	#<data> - return address of immediate value; set immed_flg	#
*		  in SPCOND_FLG						#
*	(d16,PC) - fetch stacked PC value; read d16 using		#
*		  _imem_read_word(); fetch may fail -> branch to	#
*		  isp_iacc()						#
*	everything else - read needed displacements as appropriate w/	#
*		  _imem_read_{word,long}(); read may fail; if memory	#
* 		  indirect, read indirect address using			#
*		  _dmem_read_long() which may also fail			#
*									#
*########################################################################

	global	_calc_ea
_calc_ea:
	move.l	d0,a0			* move # bytes to a0

* MODE and REG are taken from the EXC_OPWORD.
	move.w	EXC_OPWORD(a6),d0	* fetch opcode word
	move.w	d0,d1			* make a copy

	andi.w	#$3f,d0			* extract mode field
	andi.l	#$7,d1			* extract reg  field

* jump to the corresponding function for each {MODE,REG} pair.
	move.w	(tbl_ea_mode.b,pc,d0.w*2),d0		* fetch jmp distance
	jmp	(tbl_ea_mode.b,pc,d0.w*1)	* jmp to correct ea mode

	.dc.w	$4AFC,64
tbl_ea_mode:
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode

	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode

	.dc.w	addr_ind_a0-tbl_ea_mode
	.dc.w	addr_ind_a1-tbl_ea_mode
	.dc.w	addr_ind_a2-tbl_ea_mode
	.dc.w	addr_ind_a3-tbl_ea_mode
	.dc.w	addr_ind_a4-tbl_ea_mode
	.dc.w	addr_ind_a5-tbl_ea_mode
	.dc.w	addr_ind_a6-tbl_ea_mode
	.dc.w	addr_ind_a7-tbl_ea_mode

	.dc.w	addr_ind_p_a0-tbl_ea_mode
	.dc.w	addr_ind_p_a1-tbl_ea_mode
	.dc.w	addr_ind_p_a2-tbl_ea_mode
	.dc.w	addr_ind_p_a3-tbl_ea_mode
	.dc.w	addr_ind_p_a4-tbl_ea_mode
	.dc.w	addr_ind_p_a5-tbl_ea_mode
	.dc.w	addr_ind_p_a6-tbl_ea_mode
	.dc.w	addr_ind_p_a7-tbl_ea_mode

	.dc.w	addr_ind_m_a0-tbl_ea_mode
	.dc.w	addr_ind_m_a1-tbl_ea_mode
	.dc.w	addr_ind_m_a2-tbl_ea_mode
	.dc.w	addr_ind_m_a3-tbl_ea_mode
	.dc.w	addr_ind_m_a4-tbl_ea_mode
	.dc.w	addr_ind_m_a5-tbl_ea_mode
	.dc.w	addr_ind_m_a6-tbl_ea_mode
	.dc.w	addr_ind_m_a7-tbl_ea_mode

	.dc.w	addr_ind_disp_a0-tbl_ea_mode
	.dc.w	addr_ind_disp_a1-tbl_ea_mode
	.dc.w	addr_ind_disp_a2-tbl_ea_mode
	.dc.w	addr_ind_disp_a3-tbl_ea_mode
	.dc.w	addr_ind_disp_a4-tbl_ea_mode
	.dc.w	addr_ind_disp_a5-tbl_ea_mode
	.dc.w	addr_ind_disp_a6-tbl_ea_mode
	.dc.w	addr_ind_disp_a7-tbl_ea_mode

	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode
	.dc.w	_addr_ind_ext-tbl_ea_mode

	.dc.w	abs_short-tbl_ea_mode
	.dc.w	abs_long-tbl_ea_mode
	.dc.w	pc_ind-tbl_ea_mode
	.dc.w	pc_ind_ext-tbl_ea_mode
	.dc.w	immediate-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode
	.dc.w	tbl_ea_mode-tbl_ea_mode

*##################################
* Address register indirect: (An) #
*##################################
addr_ind_a0:
	move.l	EXC_A0(a6),a0		* Get current a0
	rts

addr_ind_a1:
	move.l	EXC_A1(a6),a0		* Get current a1
	rts

addr_ind_a2:
	move.l	EXC_A2(a6),a0		* Get current a2
	rts

addr_ind_a3:
	move.l	EXC_A3(a6),a0		* Get current a3
	rts

addr_ind_a4:
	move.l	EXC_A4(a6),a0		* Get current a4
	rts

addr_ind_a5:
	move.l	EXC_A5(a6),a0		* Get current a5
	rts

addr_ind_a6:
	move.l	EXC_A6(a6),a0		* Get current a6
	rts

addr_ind_a7:
	move.l	EXC_A7(a6),a0		* Get current a7
	rts

*####################################################
* Address register indirect w/ postincrement: (An)+ #
*####################################################
addr_ind_p_a0:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A0(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A0(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$0,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a1:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A1(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A1(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$1,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a2:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A2(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A2(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$2,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a3:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A3(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A3(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$3,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a4:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A4(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A4(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$4,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a5:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A5(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A5(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$5,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a6:
	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A6(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A6(a6)		* save incremented value

	move.l	a0,EXC_SAVVAL(a6)	* save in case of access error
	move.b	#$6,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_p_a7:
	move.b	#mia7_flg,SPCOND_FLG(a6)	* set "special case" flag

	move.l	a0,d0			* copy no. bytes
	move.l	EXC_A7(a6),a0		* load current value
	add.l	a0,d0			* increment
	move.l	d0,EXC_A7(a6)		* save incremented value
	rts

*###################################################
* Address register indirect w/ predecrement: -(An) #
*###################################################
addr_ind_m_a0:
	move.l	EXC_A0(a6),d0		* Get current a0
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A0(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$0,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a1:
	move.l	EXC_A1(a6),d0		* Get current a1
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A1(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$1,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a2:
	move.l	EXC_A2(a6),d0		* Get current a2
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A2(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$2,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a3:
	move.l	EXC_A3(a6),d0		* Get current a3
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A3(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$3,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a4:
	move.l	EXC_A4(a6),d0		* Get current a4
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A4(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$4,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a5:
	move.l	EXC_A5(a6),d0		* Get current a5
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A5(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$5,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a6:
	move.l	EXC_A6(a6),d0		* Get current a6
	move.l	d0,EXC_SAVVAL(a6)	* save in case of access error
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A6(a6)		* Save decr value
	move.l	d0,a0

	move.b	#$6,EXC_SAVREG(a6)	* save regno, too
	move.b	#restore_flg,SPCOND_FLG(a6)	* set flag
	rts

addr_ind_m_a7:
	move.b	#mda7_flg,SPCOND_FLG(a6)	* set "special case" flag

	move.l	EXC_A7(a6),d0		* Get current a7
	sub.l	a0,d0			* Decrement
	move.l	d0,EXC_A7(a6)		* Save decr value
	move.l	d0,a0
	rts

*#######################################################
* Address register indirect w/ displacement: (d16, An) #
*#######################################################
addr_ind_disp_a0:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A0(a6),a0		* a0 + d16
	rts

addr_ind_disp_a1:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A1(a6),a0		* a1 + d16
	rts

addr_ind_disp_a2:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A2(a6),a0		* a2 + d16
	rts

addr_ind_disp_a3:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A3(a6),a0		* a3 + d16
	rts

addr_ind_disp_a4:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A4(a6),a0		* a4 + d16
	rts

addr_ind_disp_a5:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A5(a6),a0		* a5 + d16
	rts

addr_ind_disp_a6:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A6(a6),a0		* a6 + d16
	rts

addr_ind_disp_a7:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement
	add.l	EXC_A7(a6),a0		* a7 + d16
	rts

*#######################################################################
* Address register indirect w/ index(8-bit displacement): (dn, An, Xn) #
*    "       "         "    w/   "  (base displacement): (bd, An, Xn)  #
* Memory indirect postindexed: ([bd, An], Xn, od)		       #
* Memory indirect preindexed: ([bd, An, Xn], od)		       #
*#######################################################################
_addr_ind_ext:
	move.l	d1,-(sp)

	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word		* fetch extword in d0

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.l	(sp)+,d1

	move.l	(EXC_AREGS,a6,d1.w*4),a0	* put base in a0

	btst	#$8,d0
	beq.b	addr_ind_index_8bit	* for ext word or not?

	movem.l	d2-d5,-(sp)		* save d2-d5

	move.l	d0,d5			* put extword in d5
	move.l	a0,d3			* put base in d3

	bra.l	calc_mem_ind		* calc memory indirect

addr_ind_index_8bit:
	move.l	d2,-(sp)		* save old d2

	move.l	d0,d1
	rol.w	#$4,d1
	andi.w	#$f,d1			* extract index regno

	move.l	(EXC_DREGS,a6,d1.w*4),d1	* fetch index reg value

	btst	#$b,d0			* is it word or long?
	bne.b	aii8_long
	ext.l	d1			* sign extend word index
aii8_long:
	move.l	d0,d2
	rol.w	#$7,d2
	andi.l	#$3,d2			* extract scale value

	lsl.l	d2,d1			* shift index by scale

	extb.l	d0			* sign extend displacement
	add.l	d1,d0			* index + disp
	add.l	d0,a0			* An + (index + disp)

	move.l	(sp)+,d2		* restore old d2
	rts

*#####################
* Immediate: #<data> #
*########################################################################
* word, long: <ea> of the data is the current extension word		#
* 	pointer value. new extension word pointer is simply the old	#
* 	plus the number of bytes in the data type(2 or 4).		#
*########################################################################
immediate:
	move.b	#immed_flg,SPCOND_FLG(a6)	* set immediate flag

	move.l	EXC_EXTWPTR(a6),a0	* fetch extension word ptr
	rts

*##########################
* Absolute short: (XXX).W #
*##########################
abs_short:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word		* fetch short address

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* return <ea> in a0
	rts

*#########################
* Absolute long: (XXX).L #
*#########################
abs_long:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$4,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_long		* fetch long address

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.l	d0,a0			* return <ea> in a0
	rts

*######################################################
* Program counter indirect w/ displacement: (d16, PC) #
*######################################################
pc_ind:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word		* fetch word displacement

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.w	d0,a0			* sign extend displacement

	add.l	EXC_EXTWPTR(a6),a0	* pc + d16

* _imem_read_word() increased the extwptr by 2. need to adjust here.
	subq.l	#$2,a0			* adjust <ea>

	rts

*#########################################################
* PC indirect w/ index(8-bit displacement): (d8, PC, An) #
* "     "     w/   "  (base displacement): (bd, PC, An)  #
* PC memory indirect postindexed: ([bd, PC], Xn, od)     #
* PC memory indirect preindexed: ([bd, PC, Xn], od)      #
*#########################################################
pc_ind_ext:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word		* fetch ext word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.l	EXC_EXTWPTR(a6),a0	* put base in a0
	subq.l	#$2,a0			* adjust base

	btst	#$8,d0			* is disp only 8 bits?
	beq.b	pc_ind_index_8bit	* yes

* the indexed addressing mode uses a base displacement of size
* word or long
	movem.l	d2-d5,-(sp)		* save d2-d5

	move.l	d0,d5			* put extword in d5
	move.l	a0,d3			* put base in d3

	bra.l	calc_mem_ind		* calc memory indirect

pc_ind_index_8bit:
	move.l	d2,-(sp)		* create a temp register

	move.l	d0,d1			* make extword copy
	rol.w	#$4,d1			* rotate reg num into place
	andi.w	#$f,d1			* extract register number

	move.l	(EXC_DREGS,a6,d1.w*4),d1	* fetch index reg value

	btst	#$b,d0			* is index word or long?
	bne.b	pii8_long		* long
	ext.l	d1			* sign extend word index
pii8_long:
	move.l	d0,d2			* make extword copy
	rol.w	#$7,d2			* rotate scale value into place
	andi.l	#$3,d2			* extract scale value

	lsl.l	d2,d1			* shift index by scale

	extb.l	d0			* sign extend displacement
	add.l	d1,d0			* index + disp
	add.l	d0,a0			* An + (index + disp)

	move.l	(sp)+,d2		* restore temp register

	rts

* a5 = exc_extwptr	(global to uaeh)
* a4 = exc_opword	(global to uaeh)
* a3 = exc_dregs	(global to uaeh)

* d2 = index		(internal "     "    )
* d3 = base		(internal "     "    )
* d4 = od		(internal "     "    )
* d5 = extword		(internal "     "    )
calc_mem_ind:
	btst	#$6,d5			* is the index suppressed?
	beq.b	calc_index
	clr.l	d2			* yes, so index = 0
	bra.b	base_supp_ck
calc_index:
	bfextu	d5{#16:#4},d2
	move.l	(EXC_DREGS,a6,d2.w*4),d2
	btst	#$b,d5			* is index word or long?
	bne.b	no_ext
	ext.l	d2
no_ext:
	bfextu	d5{#21:#2},d0
	lsl.l	d0,d2
base_supp_ck:
	btst	#$7,d5			* is the bd suppressed?
	beq.b	no_base_sup
	clr.l	d3
no_base_sup:
	bfextu	d5{#26:#2},d0	* get bd size
*	beq.l		_error			# if (size == 0) it's reserved
	cmpi.b	#2,d0
	blt.b	no_bd
	beq.b	get_word_bd

	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$4,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_long

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	bra.b	chk_ind
get_word_bd:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	ext.l	d0			* sign extend bd

chk_ind:
	add.l	d0,d3			* base += bd
no_bd:
	bfextu	d5{#30:#2},d0		* is od suppressed?
	beq.w	aii_bd
	cmpi.b	#$2,d0
	blt.b	null_od
	beq.b	word_od

	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$4,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_long

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	bra.b	add_them

word_od:
	move.l	EXC_EXTWPTR(a6),a0	* fetch instruction addr
	addq.l	#$2,EXC_EXTWPTR(a6)	* incr instruction ptr
	bsr.l	_imem_read_word

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	ext.l	d0			* sign extend od
	bra.b	add_them

null_od:
	clr.l	d0
add_them:
	move.l	d0,d4
	btst	#$2,d5			* pre or post indexing?
	beq.b	pre_indexed

	move.l	d3,a0
	bsr.l	_dmem_read_long

	tst.l	d1			* dfetch error?
	bne.b	calc_ea_err		* yes

	add.l	d2,d0			* <ea> += index
	add.l	d4,d0			* <ea> += od
	bra.b	done_ea

pre_indexed:
	add.l	d2,d3			* preindexing
	move.l	d3,a0
	bsr.l	_dmem_read_long

	tst.l	d1			* ifetch error?
	bne.b	calc_ea_err		* yes

	add.l	d4,d0			* ea += od
	bra.b	done_ea

aii_bd:
	add.l	d2,d3			* ea = (base + bd) + index
	move.l	d3,d0
done_ea:
	move.l	d0,a0

	movem.l	(sp)+,d2-d5		* restore d2-d5
	rts

* if dmem_read_long() returns a fail message in d1, the package
* must create an access error frame. here, we pass a skeleton fslw
* and the failing address to the routine that creates the new frame.
* FSLW:
* 	read = true
* 	size = longword
*	TM = data
* 	software emulation error = true
calc_ea_err:
	move.l	d3,a0			* pass failing address
	move.l	#$01010001,d0		* pass fslw
	bra.l	isp_dacc

*########################################################################
* XDEF **************************************************************** #
* 	_moveperipheral(): routine to emulate movep instruction		#
*									#
* XREF **************************************************************** #
*	_dmem_read_byte() - read byte from memory			#
*	_dmem_write_byte() - write byte to memory			#
*	isp_dacc() - handle data access error exception			#
*									#
* INPUT *************************************************************** #
*	none								#
*									#
* OUTPUT ************************************************************** #
*	If exiting through isp_dacc...					#
*		a0 = failing address					#
*		d0 = FSLW						#
*	else								#
*		none							#
*									#
* ALGORITHM ***********************************************************	#
*	Decode the movep instruction words stored at EXC_OPWORD and	#
* either read or write the required bytes from/to memory. Use the	#
* _dmem_{read,write}_byte() routines. If one of the memory routines	#
* returns a failing value, we must pass the failing address and	a FSLW	#
* to the _isp_dacc() routine.						#
*	Since this instruction is used to access peripherals, make sure	#
* to only access the required bytes.					#
*									#
*########################################################################

*##########################
* movep.(w,l)	Dx,(d,Ay) #
* movep.(w,l)	(d,Ay),Dx #
*##########################
	global	_moveperipheral
_moveperipheral:
	move.w	EXC_OPWORD(a6),d1	* fetch the opcode word

	move.b	d1,d0
	andi.w	#$7,d0			* extract Ay from opcode word

	move.l	(EXC_AREGS,a6,d0.w*4),a0	* fetch ay

	add.w	EXC_EXTWORD(a6),a0	* add: an + sgn_ext(disp)

	btst	#$7,d1			* (reg 2 mem) or (mem 2 reg)
	beq.w	mem2reg

* reg2mem: fetch dx, then write it to memory
reg2mem:
	move.w	d1,d0
	rol.w	#$7,d0
	andi.w	#$7,d0			* extract Dx from opcode word

	move.l	(EXC_DREGS,a6,d0.w*4),d0	* fetch dx

	btst	#$6,d1			* word or long operation?
	beq.b	r2mwtrans

* a0 = dst addr
* d0 = Dx
r2mltrans:
	move.l	d0,d2			* store data
	move.l	a0,a2			* store addr
	rol.l	#$8,d2
	move.l	d2,d0

	bsr.l	_dmem_write_byte	* os  : write hi

	tst.l	d1			* dfetch error?
	bne.w	movp_write_err		* yes

	add.w	#$2,a2			* incr addr
	move.l	a2,a0
	rol.l	#$8,d2
	move.l	d2,d0

	bsr.l	_dmem_write_byte	* os  : write lo

	tst.l	d1			* dfetch error?
	bne.w	movp_write_err		* yes

	add.w	#$2,a2			* incr addr
	move.l	a2,a0
	rol.l	#$8,d2
	move.l	d2,d0

	bsr.l	_dmem_write_byte	* os  : write lo

	tst.l	d1			* dfetch error?
	bne.w	movp_write_err		* yes

	add.w	#$2,a2			* incr addr
	move.l	a2,a0
	rol.l	#$8,d2
	move.l	d2,d0

	bsr.l	_dmem_write_byte	* os  : write lo

	tst.l	d1			* dfetch error?
	bne.w	movp_write_err		* yes

	rts

* a0 = dst addr
* d0 = Dx
r2mwtrans:
	move.l	d0,d2			* store data
	move.l	a0,a2			* store addr
	lsr.w	#$8,d0

	bsr.l	_dmem_write_byte	* os  : write hi

	tst.l	d1			* dfetch error?
	bne.w	movp_write_err		* yes

	add.w	#$2,a2
	move.l	a2,a0
	move.l	d2,d0

	bsr.l	_dmem_write_byte	* os  : write lo

	tst.l	d1			* dfetch error?
	bne.w	movp_write_err		* yes

	rts

* mem2reg: read bytes from memory.
* determines the dest register, and then writes the bytes into it.
mem2reg:
	btst	#$6,d1			* word or long operation?
	beq.b	m2rwtrans

* a0 = dst addr
m2rltrans:
	move.l	a0,a2			* store addr

	bsr.l	_dmem_read_byte		* read first byte

	tst.l	d1			* dfetch error?
	bne.w	movp_read_err		* yes

	move.l	d0,d2

	add.w	#$2,a2			* incr addr by 2 bytes
	move.l	a2,a0

	bsr.l	_dmem_read_byte		* read second byte

	tst.l	d1			* dfetch error?
	bne.w	movp_read_err		* yes

	lsl.w	#$8,d2
	move.b	d0,d2			* append bytes

	add.w	#$2,a2			* incr addr by 2 bytes
	move.l	a2,a0

	bsr.l	_dmem_read_byte		* read second byte

	tst.l	d1			* dfetch error?
	bne.w	movp_read_err		* yes

	lsl.l	#$8,d2
	move.b	d0,d2			* append bytes

	add.w	#$2,a2			* incr addr by 2 bytes
	move.l	a2,a0

	bsr.l	_dmem_read_byte		* read second byte

	tst.l	d1			* dfetch error?
	bne.w	movp_read_err		* yes

	lsl.l	#$8,d2
	move.b	d0,d2			* append bytes

	move.b	EXC_OPWORD(a6),d1
	lsr.b	#$1,d1
	andi.w	#$7,d1			* extract Dx from opcode word

	move.l	d2,(EXC_DREGS,a6,d1.w*4)	* store dx

	rts

* a0 = dst addr
m2rwtrans:
	move.l	a0,a2			* store addr

	bsr.l	_dmem_read_byte		* read first byte

	tst.l	d1			* dfetch error?
	bne.w	movp_read_err		* yes

	move.l	d0,d2

	add.w	#$2,a2			* incr addr by 2 bytes
	move.l	a2,a0

	bsr.l	_dmem_read_byte		* read second byte

	tst.l	d1			* dfetch error?
	bne.w	movp_read_err		* yes

	lsl.w	#$8,d2
	move.b	d0,d2			* append bytes

	move.b	EXC_OPWORD(a6),d1
	lsr.b	#$1,d1
	andi.w	#$7,d1			* extract Dx from opcode word

	move.w	d2,(EXC_DREGS+2,a6,d1.w*4)	* store dx

	rts

* if dmem_{read,write}_byte() returns a fail message in d1, the package
* must create an access error frame. here, we pass a skeleton fslw
* and the failing address to the routine that creates the new frame.
* FSLW:
* 	write = true
*	size = byte
*	TM = data
*	software emulation error = true
movp_write_err:
	move.l	a2,a0			* pass failing address
	move.l	#$00a10001,d0		* pass fslw
	bra.l	isp_dacc

* FSLW:
* 	read = true
*	size = byte
*	TM = data
*	software emulation error = true
movp_read_err:
	move.l	a2,a0			* pass failing address
	move.l	#$01210001,d0		* pass fslw
	bra.l	isp_dacc

*########################################################################
* XDEF ****************************************************************	#
* 	_chk2_cmp2(): routine to emulate chk2/cmp2 instructions		#
*									#
* XREF ****************************************************************	#
*	_calc_ea(): calculate effective address				#
*	_dmem_read_long(): read operands				#
* 	_dmem_read_word(): read operands				#
*	isp_dacc(): handle data access error exception			#
*									#
* INPUT ***************************************************************	#
*	none								#
*									#
* OUTPUT **************************************************************	#
*	If exiting through isp_dacc...					#
*		a0 = failing address					#
*		d0 = FSLW						#
*	else								#
* 		none							#
*									#
* ALGORITHM ***********************************************************	#
*	First, calculate the effective address, then fetch the byte,	#
* word, or longword sized operands. Then, in the interest of 		#
* simplicity, all operands are converted to longword size whether the 	#
* operation is byte, word, or long. The bounds are sign extended 	#
* accordingly. If Rn is a data regsiter, Rn is also sign extended. If 	#
* Rn is an address register, it need not be sign extended since the 	#
* full register is always used.						#
*	The comparisons are made and the condition codes calculated.	#
* If the instruction is chk2 and the Rn value is out-of-bounds, set	#
* the ichk_flg in SPCOND_FLG.						#
*	If the memory fetch returns a failing value, pass the failing 	#
* address and FSLW to the isp_dacc() routine.				#
*									#
*########################################################################

	global	_chk2_cmp2
_chk2_cmp2:

* passing size parameter doesn't matter since chk2 & cmp2 can't do
* either predecrement, postincrement, or immediate.
	bsr.l	_calc_ea		* calculate <ea>

	move.b	EXC_EXTWORD(a6),d0	* fetch hi extension word
	rol.b	#$4,d0			* rotate reg bits into lo
	andi.w	#$f,d0			* extract reg bits

	move.l	(EXC_DREGS,a6,d0.w*4),d2	* get regval

	cmpi.b	#$2,EXC_OPWORD(a6)	* what size is operation?
	blt.b	chk2_cmp2_byte		* size == byte
	beq.b	chk2_cmp2_word		* size == word

* the bounds are longword size. call routine to read the lower
* bound into d0 and the higher bound into d1.
chk2_cmp2_long:
	move.l	a0,a2			* save copy of <ea>
	bsr.l	_dmem_read_long		* fetch long lower bound

	tst.l	d1			* dfetch error?
	bne.w	chk2_cmp2_err_l		* yes

	move.l	d0,d3			* save long lower bound
	addq.l	#$4,a2
	move.l	a2,a0			* pass <ea> of long upper bound
	bsr.l	_dmem_read_long		* fetch long upper bound

	tst.l	d1			* dfetch error?
	bne.w	chk2_cmp2_err_l		* yes

	move.l	d0,d1			* long upper bound in d1
	move.l	d3,d0			* long lower bound in d0
	bra.w	chk2_cmp2_compare	* go do the compare emulation

* the bounds are word size. fetch them in one subroutine call by
* reading a longword. sign extend both. if it's a data operation,
* sign extend Rn to long, also.
chk2_cmp2_word:
	move.l	a0,a2
	bsr.l	_dmem_read_long		* fetch 2 word bounds

	tst.l	d1			* dfetch error?
	bne.w	chk2_cmp2_err_l		* yes

	move.w	d0,d1			* place hi in %d1
	swap	d0			* place lo in %d0

	ext.l	d0			* sign extend lo bnd
	ext.l	d1			* sign extend hi bnd

	btst	#$7,EXC_EXTWORD(a6)	* address compare?
	bne.w	chk2_cmp2_compare	* yes; don't sign extend

* operation is a data register compare.
* sign extend word to long so we can do simple longword compares.
	ext.l	d2			* sign extend data word
	bra.w	chk2_cmp2_compare	* go emulate compare

* the bounds are byte size. fetch them in one subroutine call by
* reading a word. sign extend both. if it's a data operation,
* sign extend Rn to long, also.
chk2_cmp2_byte:
	move.l	a0,a2
	bsr.l	_dmem_read_word		* fetch 2 byte bounds

	tst.l	d1			* dfetch error?
	bne.w	chk2_cmp2_err_w		* yes

	move.b	d0,d1			* place hi in %d1
	lsr.w	#$8,d0			* place lo in %d0

	extb.l	d0			* sign extend lo bnd
	extb.l	d1			* sign extend hi bnd

	btst	#$7,EXC_EXTWORD(a6)	* address compare?
	bne.b	chk2_cmp2_compare	* yes; don't sign extend

* operation is a data register compare.
* sign extend byte to long so we can do simple longword compares.
	extb.l	d2			* sign extend data byte

*
* To set the ccodes correctly:
* 	(1) save 'Z' bit from (Rn - lo)
*	(2) save 'Z' and 'N' bits from ((hi - lo) - (Rn - hi))
*	(3) keep 'X', 'N', and 'V' from before instruction
*	(4) combine ccodes
*
chk2_cmp2_compare:
	sub.l	d0,d2			* (Rn - lo)
	move.w	ccr,d3			* fetch resulting ccodes
	andi.b	#$4,d3			* keep 'Z' bit
	sub.l	d0,d1			* (hi - lo)
	cmp.l	d2,d1			* ((hi - lo) - (Rn - hi))

	move.w	ccr,d4			* fetch resulting ccodes
	or.b	d4,d3			* combine w/ earlier ccodes
	andi.b	#$5,d3			* keep 'Z' and 'N'

	move.w	EXC_CC(a6),d4		* fetch old ccodes
	andi.b	#$1a,d4			* keep 'X','N','V' bits
	or.b	d3,d4			* insert new ccodes
	move.w	d4,EXC_CC(a6)		* save new ccodes

	btst	#$3,EXC_EXTWORD(a6)	* separate chk2,cmp2
	bne.b	chk2_finish		* it's a chk2

	rts

* this code handles the only difference between chk2 and cmp2. chk2 would
* have trapped out if the value was out of bounds. we check this by seeing
* if the 'N' bit was set by the operation.
chk2_finish:
	btst	#$0,d4			* is 'N' bit set?
	bne.b	chk2_trap		* yes;chk2 should trap
	rts
chk2_trap:
	move.b	#ichk_flg,SPCOND_FLG(a6)	* set "special case" flag
	rts

* if dmem_read_{long,word}() returns a fail message in d1, the package
* must create an access error frame. here, we pass a skeleton fslw
* and the failing address to the routine that creates the new frame.
* FSLW:
*	read = true
*	size = longword
*	TM = data
* 	software emulation error = true
chk2_cmp2_err_l:
	move.l	a2,a0			* pass failing address
	move.l	#$01010001,d0		* pass fslw
	bra.l	isp_dacc

* FSLW:
*	read = true
*	size = word
*	TM = data
* 	software emulation error = true
chk2_cmp2_err_w:
	move.l	a2,a0			* pass failing address
	move.l	#$01410001,d0		* pass fslw
	bra.l	isp_dacc

*########################################################################
* XDEF ****************************************************************	#
* 	_div64(): routine to emulate div{u,s}.l <ea>,Dr:Dq		#
*							64/32->32r:32q	#
*									#
* XREF ****************************************************************	#
*	_calc_ea() - calculate effective address			#
* 	isp_iacc() - handle instruction access error exception		#
*	isp_dacc() - handle data access error exception			#
*	isp_restore() - restore An on access error w/ -() or ()+	#
*									#
* INPUT ***************************************************************	#
*	none								#
*									#
* OUTPUT **************************************************************	#
* 	If exiting through isp_dacc...					#
*		a0 = failing address					#
* 		d0 = FSLW						#
*	else								#
*		none							#
*									#
* ALGORITHM ***********************************************************	#
* 	First, decode the operand location. If it's in Dn, fetch from	#
* the stack. If it's in memory, use _calc_ea() to calculate the 	#
* effective address. Use _dmem_read_long() to fetch at that address.	#
* Unless the operand is immediate data. Then use _imem_read_long().	#
* Send failures to isp_dacc() or isp_iacc() as appropriate.		#
*	If the operands are signed, make them unsigned and save	the 	#
* sign info for later. Separate out special cases like divide-by-zero	#
* or 32-bit divides if possible. Else, use a special math algorithm	#
* to calculate the result. 						#
*	Restore sign info if signed instruction. Set the condition 	#
* codes. Set idbyz_flg in SPCOND_FLG if divisor was zero. Store the 	#
* quotient and remainder in the appropriate data registers on the stack.#
*									#
*########################################################################

NDIVISOR	set	EXC_TEMP+$0
NDIVIDEND	set	EXC_TEMP+$1
NDRSAVE	set	EXC_TEMP+$2
NDQSAVE	set	EXC_TEMP+$4
DDSECOND	set	EXC_TEMP+$6
DDQUOTIENT	set	EXC_TEMP+$8
DDNORMAL	set	EXC_TEMP+$c

	global	_div64
*############
* div(u,s)l #
*############
_div64:
	move.b	EXC_OPWORD+1(a6),d0
	andi.b	#$38,d0			* extract src mode

	bne.w	dcontrolmodel_s		* %dn dest or control mode?

	move.b	EXC_OPWORD+1(a6),d0	* extract Dn from opcode
	andi.w	#$7,d0
	move.l	(EXC_DREGS,a6,d0.w*4),d7	* fetch divisor from register

dgotsrcl:
	beq.w	div64eq0		* divisor is = 0!!!

	move.b	EXC_EXTWORD+1(a6),d0	* extract Dr from extword
	move.b	EXC_EXTWORD(a6),d1	* extract Dq from extword
	andi.w	#$7,d0
	lsr.b	#$4,d1
	andi.w	#$7,d1
	move.w	d0,NDRSAVE(a6)		* save Dr for later
	move.w	d1,NDQSAVE(a6)		* save Dq for later

* fetch %dr and %dq directly off stack since all regs are saved there
	move.l	(EXC_DREGS,a6,d0.w*4),d5	* get dividend hi
	move.l	(EXC_DREGS,a6,d1.w*4),d6	* get dividend lo

* separate signed and unsigned divide
	btst	#$3,EXC_EXTWORD(a6)	* signed or unsigned?
	beq.b	dspecialcases		* use positive divide

* save the sign of the divisor
* make divisor unsigned if it's negative
	tst.l	d7			* chk sign of divisor
	slt	NDIVISOR(a6)		* save sign of divisor
	bpl.b	dsgndividend
	neg.l	d7			* complement negative divisor

* save the sign of the dividend
* make dividend unsigned if it's negative
dsgndividend:
	tst.l	d5			* chk sign of hi(dividend)
	slt	NDIVIDEND(a6)		* save sign of dividend
	bpl.b	dspecialcases

	move.w	#$0,ccr			* clear 'X' cc bit
	negx.l	d6			* complement signed dividend
	negx.l	d5

* extract some special cases:
* 	- is (dividend == 0) ?
*	- is (hi(dividend) == 0 && (divisor <= lo(dividend))) ? (32-bit div)
dspecialcases:
	tst.l	d5			* is (hi(dividend) == 0)
	bne.b	dnormaldivide		* no, so try it the long way

	tst.l	d6			* is (lo(dividend) == 0), too
	beq.w	ddone			* yes, so (dividend == 0)

	cmp.l	d6,d7			* is (divisor <= lo(dividend))
	bls.b	d32bitdivide		* yes, so use 32 bit divide

	exg	d5,d6			* q = 0, r = dividend
	bra.w	divfinish		* can't divide, we're done.

d32bitdivide:
	divul.l	d7,d5:d6		* it's only a 32/32 bit div!

	bra.b	divfinish

dnormaldivide:
* last special case:
* 	- is hi(dividend) >= divisor ? if yes, then overflow
	cmp.l	d5,d7
	bls.b	ddovf			* answer won't fit in 32 bits

* perform the divide algorithm:
	bsr.l	dclassical		* do int divide

* separate into signed and unsigned finishes.
divfinish:
	btst	#$3,EXC_EXTWORD(a6)	* do divs, divu separately
	beq.b	ddone			* divu has no processing!!!

* it was a divs.l, so ccode setting is a little more complicated...
	tst.b	NDIVIDEND(a6)		* remainder has same sign 
	beq.b	dcc			* as dividend.
	neg.l	d5			* sgn(rem) = sgn(dividend)
dcc:
	move.b	NDIVISOR(a6),d0
	eor.b	d0,NDIVIDEND(a6)	* chk if quotient is negative
	beq.b	dqpos			* branch to quot positive

* 0x80000000 is the largest number representable as a 32-bit negative
* number. the negative of 0x80000000 is 0x80000000.
	cmpi.l	#$80000000,d6		* will (-quot) fit in 32 bits?
	bhi.b	ddovf

	neg.l	d6			* make (-quot) 2's comp

	bra.b	ddone

dqpos:
	btst	#$1f,d6			* will (+quot) fit in 32 bits?
	bne.b	ddovf

ddone:
* at this point, result is normal so ccodes are set based on result.
	move.w	EXC_CC(a6),ccr
	tst.l	d6			* set %ccode bits
	move.w	ccr,EXC_CC(a6)

	move.w	NDRSAVE(a6),d0		* get Dr off stack
	move.w	NDQSAVE(a6),d1		* get Dq off stack	

* if the register numbers are the same, only the quotient gets saved.
* so, if we always save the quotient second, we save ourselves a cmp&beq
	move.l	d5,(EXC_DREGS,a6,d0.w*4)	* save remainder
	move.l	d6,(EXC_DREGS,a6,d1.w*4)	* save quotient

	rts

ddovf:
	bset	#$1,EXC_CC+1(a6)	* 'V' set on overflow
	bclr	#$0,EXC_CC+1(a6)	* 'C' cleared on overflow

	rts

div64eq0:
	andi.b	#$1e,EXC_CC+1(a6)	* clear 'C' bit on divbyzero
	ori.b	#idbyz_flg,SPCOND_FLG(a6)	* set "special case" flag
	rts

*##########################################################################
*########################################################################
* This routine uses the 'classical' Algorithm D from Donald Knuth's	#
* Art of Computer Programming, vol II, Seminumerical Algorithms.	#
* For this implementation b=2**16, and the target is U1U2U3U4/V1V2,	#
* where U,V are words of the quadword dividend and longword divisor,	#
* and U1, V1 are the most significant words.				#
* 									#
* The most sig. longword of the 64 bit dividend must be in %d5, least 	#
* in %d6. The divisor must be in the variable ddivisor, and the		#
* signed/unsigned flag ddusign must be set (0=unsigned,1=signed).	#
* The quotient is returned in %d6, remainder in %d5, unless the		#
* v (overflow) bit is set in the saved %ccr. If overflow, the dividend	#
* is unchanged.								#
*########################################################################
dclassical:
* if the divisor msw is 0, use simpler algorithm then the full blown
* one at ddknuth:

	cmpi.l	#$ffff,d7
	bhi.b	ddknuth			* go use D. Knuth algorithm

* Since the divisor is only a word (and larger than the mslw of the dividend),
* a simpler algorithm may be used :
* In the general case, four quotient words would be created by
* dividing the divisor word into each dividend word. In this case,
* the first two quotient words must be zero, or overflow would occur.
* Since we already checked this case above, we can treat the most significant
* longword of the dividend as (0) remainder (see Knuth) and merely complete 
* the last two divisions to get a quotient longword and word remainder:

	clr.l	d1
	swap	d5			* same as r*b if previous step rqd
	swap	d6			* get u3 to lsw position
	move.w	d6,d5			* rb + u3

	divu.w	d7,d5

	move.w	d5,d1			* first quotient word
	swap	d6			* get u4
	move.w	d6,d5			* rb + u4

	divu.w	d7,d5

	swap	d1
	move.w	d5,d1			* 2nd quotient 'digit'
	clr.w	d5
	swap	d5			* now remainder
	move.l	d1,d6			* and quotient

	rts

ddknuth:
* In this algorithm, the divisor is treated as a 2 digit (word) number
* which is divided into a 3 digit (word) dividend to get one quotient
* digit (word). After subtraction, the dividend is shifted and the
* process repeated. Before beginning, the divisor and quotient are
* 'normalized' so that the process of estimating the quotient digit
* will yield verifiably correct results..

	clr.l	DDNORMAL(a6)		* count of shifts for normalization
	clr.b	DDSECOND(a6)		* clear flag for quotient digits
	clr.l	d1			* %d1 will hold trial quotient
ddnchk:
	btst	#31,d7			* must we normalize? first word of 
	bne.b	ddnormalized		* divisor (V1) must be >= 65536/2
	addq.l	#$1,DDNORMAL(a6)	* count normalization shifts
	lsl.l	#$1,d7			* shift the divisor
	lsl.l	#$1,d6			* shift u4,u3 with overflow to u2
	roxl.l	#$1,d5			* shift u1,u2 
	bra.w	ddnchk
ddnormalized:

* Now calculate an estimate of the quotient words (msw first, then lsw).
* The comments use subscripts for the first quotient digit determination.
	move.l	d7,d3			* divisor
	move.l	d5,d2			* dividend mslw
	swap	d2
	swap	d3
	cmp.w	d3,d2			* V1 = U1 ?
	bne.b	ddqcalc1
	move.w	#$ffff,d1		* use max trial quotient word
	bra.b	ddadj0
ddqcalc1:
	move.l	d5,d1

	divu.w	d3,d1			* use quotient of mslw/msw

	andi.l	#$0000ffff,d1		* zero any remainder
ddadj0:

* now test the trial quotient and adjust. This step plus the
* normalization assures (according to Knuth) that the trial
* quotient will be at worst 1 too large.
	move.l	d6,-(sp)
	clr.w	d6			* word u3 left
	swap	d6			* in lsw position
ddadj1:	move.l	d7,d3
	move.l	d1,d2
	mulu.w	d7,d2			* V2q
	swap	d3
	mulu.w	d1,d3			* V1q
	move.l	d5,d4			* U1U2
	sub.l	d3,d4			* U1U2 - V1q

	swap	d4

	move.w	d4,d0
	move.w	d6,d4			* insert lower word (U3)

	tst.w	d0			* is upper word set?
	bne.w	ddadjd1

*	add.l		%d6, %d4		# (U1U2 - V1q) + U3

	cmp.l	d4,d2
	bls.b	ddadjd1			* is V2q > (U1U2-V1q) + U3 ?
	subq.l	#$1,d1			* yes, decrement and recheck
	bra.b	ddadj1
ddadjd1:
* now test the word by multiplying it by the divisor (V1V2) and comparing
* the 3 digit (word) result with the current dividend words
	move.l	d5,-(sp)		* save %d5 (%d6 already saved)
	move.l	d1,d6
	swap	d6			* shift answer to ms 3 words
	move.l	d7,d5
	bsr.l	dmm2
	move.l	d5,d2			* now %d2,%d3 are trial*divisor
	move.l	d6,d3
	move.l	(sp)+,d5		* restore dividend
	move.l	(sp)+,d6
	sub.l	d3,d6
	subx.l	d2,d5			* subtract double precision
	bcc.l	dd2nd			* no carry, do next quotient digit
	subq.l	#$1,d1			* q is one too large
* need to add back divisor longword to current ms 3 digits of dividend
* - according to Knuth, this is done only 2 out of 65536 times for random
* divisor, dividend selection.
	clr.l	d2
	move.l	d7,d3
	swap	d3
	clr.w	d3			* %d3 now ls word of divisor
	add.l	d3,d6			* aligned with 3rd word of dividend
	addx.l	d2,d5
	move.l	d7,d3
	clr.w	d3			* %d3 now ms word of divisor
	swap	d3			* aligned with 2nd word of dividend
	add.l	d3,d5
dd2nd:
	tst.b	DDSECOND(a6)		* both q words done?
	bne.b	ddremain
* first quotient digit now correct. store digit and shift the
* (subtracted) dividend 
	move.w	d1,DDQUOTIENT(a6)
	clr.l	d1
	swap	d5
	swap	d6
	move.w	d6,d5
	clr.w	d6
	st	DDSECOND(a6)		* second digit
	bra.w	ddnormalized
ddremain:
* add 2nd word to quotient, get the remainder.
	move.w	d1,DDQUOTIENT+2(a6)
* shift down one word/digit to renormalize remainder.
	move.w	d5,d6
	swap	d6
	swap	d5
	move.l	DDNORMAL(a6),d7		* get norm shift count
	beq.b	ddrn
	subq.l	#$1,d7			* set for loop count
ddnlp:
	lsr.l	#$1,d5			* shift into %d6
	roxr.l	#$1,d6
	dbf	d7,ddnlp
ddrn:
	move.l	d6,d5			* remainder
	move.l	DDQUOTIENT(a6),d6	* quotient

	rts
dmm2:
* factors for the 32X32->64 multiplication are in %d5 and %d6.
* returns 64 bit result in %d5 (hi) %d6(lo).
* destroys %d2,%d3,%d4.

* multiply hi,lo words of each factor to get 4 intermediate products
	move.l	d6,d2
	move.l	d6,d3
	move.l	d5,d4
	swap	d3
	swap	d4
	mulu.w	d5,d6			* %d6 <- lsw*lsw
	mulu.w	d3,d5			* %d5 <- msw-dest*lsw-source
	mulu.w	d4,d2			* %d2 <- msw-source*lsw-dest
	mulu.w	d4,d3			* %d3 <- msw*msw
* now use swap and addx to consolidate to two longwords
	clr.l	d4
	swap	d6
	add.w	d5,d6			* add msw of l*l to lsw of m*l product
	addx.w	d4,d3			* add any carry to m*m product
	add.w	d2,d6			* add in lsw of other m*l product
	addx.w	d4,d3			* add any carry to m*m product
	swap	d6			* %d6 is low 32 bits of final product
	clr.w	d5
	clr.w	d2			* lsw of two mixed products used,
	swap	d5			* now use msws of longwords
	swap	d2
	add.l	d2,d5
	add.l	d3,d5			* %d5 now ms 32 bits of final product
	rts

*#########
dcontrolmodel_s:
	moveq.l	#LONG,d0
	bsr.l	_calc_ea		* calc <ea>

	cmpi.b	#immed_flg,SPCOND_FLG(a6)	* immediate addressing mode?
	beq.b	dimmed			* yes

	move.l	a0,a2
	bsr.l	_dmem_read_long		* fetch divisor from <ea>

	tst.l	d1			* dfetch error?
	bne.b	div64_err		* yes

	move.l	d0,d7
	bra.w	dgotsrcl

* we have to split out immediate data here because it must be read using
* imem_read() instead of dmem_read(). this becomes especially important
* if the fetch runs into some deadly fault.
dimmed:
	addq.l	#$4,EXC_EXTWPTR(a6)
	bsr.l	_imem_read_long		* read immediate value

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.l	d0,d7
	bra.w	dgotsrcl

*#########

* if dmem_read_long() returns a fail message in d1, the package
* must create an access error frame. here, we pass a skeleton fslw
* and the failing address to the routine that creates the new frame.
* also, we call isp_restore in case the effective addressing mode was
* (an)+ or -(an) in which case the previous "an" value must be restored.
* FSLW:
* 	read = true
* 	size = longword
*	TM = data
* 	software emulation error = true
div64_err:
	bsr.l	isp_restore		* restore addr reg
	move.l	a2,a0			* pass failing address
	move.l	#$01010001,d0		* pass fslw
	bra.l	isp_dacc

*########################################################################
* XDEF ****************************************************************	#
*	_mul64(): routine to emulate mul{u,s}.l <ea>,Dh:Dl 32x32->64	#
*									#
* XREF ****************************************************************	#
*	_calc_ea() - calculate effective address			#
*	isp_iacc() - handle instruction access error exception		#
* 	isp_dacc() - handle data access error exception			#
*	isp_restore() - restore An on access error w/ -() or ()+	#
*									#
* INPUT ***************************************************************	#
*	none								#
*									#
* OUTPUT **************************************************************	#
* 	If exiting through isp_dacc...					#
*		a0 = failing address					#
*		d0 = FSLW						#
* 	else								#
*		none							#
*									#
* ALGORITHM ***********************************************************	#
*	First, decode the operand location. If it's in Dn, fetch from	#
* the stack. If it's in memory, use _calc_ea() to calculate the		#
* effective address. Use _dmem_read_long() to fetch at that address.	#
* Unless the operand is immediate data. Then use _imem_read_long().	#
* Send failures to isp_dacc() or isp_iacc() as appropriate.		#
*	If the operands are signed, make them unsigned and save the 	#
* sign info for later. Perform the multiplication using 16x16->32	#
* unsigned multiplies and "add" instructions. Store the high and low 	#
* portions of the result in the appropriate data registers on the	#
* stack. Calculate the condition codes, also.				#
*									#
*########################################################################

*############
* mul(u,s)l #
*############
	global	_mul64
_mul64:
	move.b	EXC_OPWORD+1(a6),d0	* extract src {mode,reg}
	cmpi.b	#$7,d0			* is src mode Dn or other?
	bgt.w	mul64_memop		* src is in memory

* multiplier operand in the the data register file.
* must extract the register number and fetch the operand from the stack.
mul64_regop:
	andi.w	#$7,d0			* extract Dn
	move.l	(EXC_DREGS,a6,d0.w*4),d3	* fetch multiplier

* multiplier is in %d3. now, extract Dl and Dh fields and fetch the
* multiplicand from the data register specified by Dl.
mul64_multiplicand:
	move.w	EXC_EXTWORD(a6),d2	* fetch ext word
	clr.w	d1			* clear Dh reg
	move.b	d2,d1			* grab Dh
	rol.w	#$4,d2			* align Dl byte
	andi.w	#$7,d2			* extract Dl

	move.l	(EXC_DREGS,a6,d2.w*4),d4	* get multiplicand

* check for the case of "zero" result early
	tst.l	d4			* test multiplicand
	beq.w	mul64_zero		* handle zero separately
	tst.l	d3			* test multiplier
	beq.w	mul64_zero		* handle zero separately

* multiplier is in %d3 and multiplicand is in %d4.
* if the operation is to be signed, then the operands are converted
* to unsigned and the result sign is saved for the end.
	clr.b	EXC_TEMP(a6)		* clear temp space
	btst	#$3,EXC_EXTWORD(a6)	* signed or unsigned?
	beq.b	mul64_alg		* unsigned; skip sgn calc

	tst.l	d3			* is multiplier negative?
	bge.b	mul64_chk_md_sgn	* no
	neg.l	d3			* make multiplier positive
	ori.b	#$1,EXC_TEMP(a6)	* save multiplier sgn

* the result sign is the exclusive or of the operand sign bits.
mul64_chk_md_sgn:
	tst.l	d4			* is multiplicand negative?
	bge.b	mul64_alg		* no	
	neg.l	d4			* make multiplicand positive
	eori.b	#$1,EXC_TEMP(a6)	* calculate correct sign

*########################################################################
*	63			   32				0	#
* 	----------------------------					#
* 	| hi(mplier) * hi(mplicand)|					#
* 	----------------------------					#
*		     -----------------------------			#
*		     | hi(mplier) * lo(mplicand) |			#
*		     -----------------------------			#
*		     -----------------------------			#
*		     | lo(mplier) * hi(mplicand) |			#
*		     -----------------------------			#
*	  |			   -----------------------------	#
*	--|--			   | lo(mplier) * lo(mplicand) |	#
*	  |			   -----------------------------	#
*	========================================================	#
*	--------------------------------------------------------	#
*	|	hi(result)	   |	    lo(result)         |	#
*	--------------------------------------------------------	#
*########################################################################
mul64_alg:
* load temp registers with operands
	move.l	d3,d5			* mr in %d5
	move.l	d3,d6			* mr in %d6
	move.l	d4,d7			* md in %d7
	swap	d6			* hi(mr) in lo %d6
	swap	d7			* hi(md) in lo %d7

* complete necessary multiplies:
	mulu.w	d4,d3			* [1] lo(mr) * lo(md)
	mulu.w	d6,d4			* [2] hi(mr) * lo(md)
	mulu.w	d7,d5			* [3] lo(mr) * hi(md)
	mulu.w	d7,d6			* [4] hi(mr) * hi(md)

* add lo portions of [2],[3] to hi portion of [1].
* add carries produced from these adds to [4].
* lo([1]) is the final lo 16 bits of the result.
	clr.l	d7			* load %d7 w/ zero value
	swap	d3			* hi([1]) <==> lo([1])
	add.w	d4,d3			* hi([1]) + lo([2])
	addx.l	d7,d6			*    [4]  + carry
	add.w	d5,d3			* hi([1]) + lo([3])
	addx.l	d7,d6			*    [4]  + carry
	swap	d3			* lo([1]) <==> hi([1])

* lo portions of [2],[3] have been added in to final result.
* now, clear lo, put hi in lo reg, and add to [4]
	clr.w	d4			* clear lo([2])
	clr.w	d5			* clear hi([3])
	swap	d4			* hi([2]) in lo %d4
	swap	d5			* hi([3]) in lo %d5
	add.l	d5,d4			*    [4]  + hi([2])
	add.l	d6,d4			*    [4]  + hi([3])

* unsigned result is now in {%d4,%d3}
	tst.b	EXC_TEMP(a6)		* should result be signed?
	beq.b	mul64_done		* no

* result should be a signed negative number.
* compute 2's complement of the unsigned number:
*   -negate all bits and add 1
mul64_neg:
	not.l	d3			* negate lo(result) bits
	not.l	d4			* negate hi(result) bits
	addq.l	#1,d3			* add 1 to lo(result)
	addx.l	d7,d4			* add carry to hi(result)

* the result is saved to the register file.
* for '040 compatability, if Dl == Dh then only the hi(result) is
* saved. so, saving hi after lo accomplishes this without need to
* check Dl,Dh equality.
mul64_done:
	move.l	d3,(EXC_DREGS,a6,d2.w*4)	* save lo(result)
	move.w	#$0,ccr
	move.l	d4,(EXC_DREGS,a6,d1.w*4)	* save hi(result)

* now, grab the condition codes. only one that can be set is 'N'.
* 'N' CAN be set if the operation is unsigned if bit 63 is set.
	move.w	ccr,d7			* fetch %ccr to see if 'N' set
	andi.b	#$8,d7			* extract 'N' bit

mul64_ccode_set:
	move.b	EXC_CC+1(a6),d6		* fetch previous %ccr
	andi.b	#$10,d6			* all but 'X' bit changes

	or.b	d7,d6			* group 'X' and 'N'
	move.b	d6,EXC_CC+1(a6)		* save new %ccr

	rts

* one or both of the operands is zero so the result is also zero.
* save the zero result to the register file and set the 'Z' ccode bit.
mul64_zero:
	clr.l	(EXC_DREGS,a6,d2.w*4)	* save lo(result)
	clr.l	(EXC_DREGS,a6,d1.w*4)	* save hi(result)

	moveq.l	#$4,d7			* set 'Z' ccode bit
	bra.b	mul64_ccode_set		* finish ccode set

*#########

* multiplier operand is in memory at the effective address.
* must calculate the <ea> and go fetch the 32-bit operand.
mul64_memop:
	moveq.l	#LONG,d0		* pass # of bytes
	bsr.l	_calc_ea		* calculate <ea>

	cmpi.b	#immed_flg,SPCOND_FLG(a6)	* immediate addressing mode?
	beq.b	mul64_immed		* yes

	move.l	a0,a2
	bsr.l	_dmem_read_long		* fetch src from addr (%a0)

	tst.l	d1			* dfetch error?
	bne.w	mul64_err		* yes

	move.l	d0,d3			* store multiplier in %d3

	bra.w	mul64_multiplicand

* we have to split out immediate data here because it must be read using
* imem_read() instead of dmem_read(). this becomes especially important
* if the fetch runs into some deadly fault.
mul64_immed:
	addq.l	#$4,EXC_EXTWPTR(a6)
	bsr.l	_imem_read_long		* read immediate value

	tst.l	d1			* ifetch error?
	bne.l	isp_iacc		* yes

	move.l	d0,d3
	bra.w	mul64_multiplicand

*#########

* if dmem_read_long() returns a fail message in d1, the package
* must create an access error frame. here, we pass a skeleton fslw
* and the failing address to the routine that creates the new frame.
* also, we call isp_restore in case the effective addressing mode was
* (an)+ or -(an) in which case the previous "an" value must be restored.
* FSLW:
* 	read = true
* 	size = longword
*	TM = data
* 	software emulation error = true
mul64_err:
	bsr.l	isp_restore		* restore addr reg
	move.l	a2,a0			* pass failing address
	move.l	#$01010001,d0		* pass fslw
	bra.l	isp_dacc

*########################################################################
* XDEF ****************************************************************	#
*	_compandset2(): routine to emulate cas2()			#
*			(internal to package)				#
*									#
*	_isp_cas2_finish(): store ccodes, store compare regs		#
*			    (external to package)			#
*									#
* XREF ****************************************************************	#
*	_real_lock_page() - "callout" to lock op's page from page-outs	#
*	_cas_terminate2() - access error exit				#
*	_real_cas2() - "callout" to core cas2 emulation code		#
*	_real_unlock_page() - "callout" to unlock page			#
*									#
* INPUT ***************************************************************	#
* _compandset2():							#
*	d0 = instruction extension word					#
*									#
* _isp_cas2_finish():							#
*	see cas2 core emulation code					#
* 									#
* OUTPUT **************************************************************	#
* _compandset2():							#
*	see cas2 core emulation code					#
*									#
* _isp_cas_finish():							#
*	None (register file or memroy changed as appropriate)		#
*									#
* ALGORITHM ***********************************************************	#
* compandset2():							#
*	Decode the instruction and fetch the appropriate Update and	#
* Compare operands. Then call the "callout" _real_lock_page() for each	#
* memory operand address so that the operating system can keep these	#
* pages from being paged out. If either _real_lock_page() fails, exit	#
* through _cas_terminate2(). Don't forget to unlock the 1st locked page	#
* using _real_unlock_paged() if the 2nd lock-page fails.		#
* Finally, branch to the core cas2 emulation code by calling the 	#
* "callout" _real_cas2().						#
*									#
* _isp_cas2_finish():							#
*	Re-perform the comparison so we can determine the condition	#
* codes which were too much trouble to keep around during the locked	#
* emulation. Then unlock each operands page by calling the "callout"	#
* _real_unlock_page().							#
*									#
*########################################################################

ADDR1	set	EXC_TEMP+$c
ADDR2	set	EXC_TEMP+$0
DC2	set	EXC_TEMP+$a
DC1	set	EXC_TEMP+$8

	global	_compandset2
_compandset2:
	move.l	d0,EXC_TEMP+$4(a6)		* store for possible restart
	move.l	d0,d1			* extension word in d0

	rol.w	#$4,d0
	andi.w	#$f,d0			* extract Rn2
	move.l	(EXC_DREGS,a6,d0.w*4),a1	* fetch ADDR2
	move.l	a1,ADDR2(a6)

	move.l	d1,d0

	lsr.w	#$6,d1
	andi.w	#$7,d1			* extract Du2
	move.l	(EXC_DREGS,a6,d1.w*4),d5	* fetch Update2 Op

	andi.w	#$7,d0			* extract Dc2
	move.l	(EXC_DREGS,a6,d0.w*4),d3	* fetch Compare2 Op
	move.w	d0,DC2(a6)

	move.w	EXC_EXTWORD(a6),d0
	move.l	d0,d1

	rol.w	#$4,d0
	andi.w	#$f,d0			* extract Rn1
	move.l	(EXC_DREGS,a6,d0.w*4),a0	* fetch ADDR1
	move.l	a0,ADDR1(a6)

	move.l	d1,d0

	lsr.w	#$6,d1
	andi.w	#$7,d1			* extract Du1
	move.l	(EXC_DREGS,a6,d1.w*4),d4	* fetch Update1 Op

	andi.w	#$7,d0			* extract Dc1
	move.l	(EXC_DREGS,a6,d0.w*4),d2	* fetch Compare1 Op
	move.w	d0,DC1(a6)

	btst	#$1,EXC_OPWORD(a6)	* word or long?
	sne	d7

	btst	#$5,EXC_ISR(a6)		* user or supervisor?
	sne	d6

	move.l	a0,a2
	move.l	a1,a3

	move.l	d7,d1			* pass size
	move.l	d6,d0			* pass mode
	bsr.l	_real_lock_page		* lock page
	move.l	a2,a0
	tst.l	d0			* error?
	bne.l	_cas_terminate2		* yes

	move.l	d7,d1			* pass size
	move.l	d6,d0			* pass mode
	move.l	a3,a0			* pass addr
	bsr.l	_real_lock_page		* lock page
	move.l	a3,a0
	tst.l	d0			* error?
	bne.b	cas_preterm		* yes

	move.l	a2,a0
	move.l	a3,a1

	bra.l	_real_cas2

* if the 2nd lock attempt fails, then we must still unlock the 
* first page(s).
cas_preterm:
	move.l	d0,-(sp)		* save FSLW
	move.l	d7,d1			* pass size
	move.l	d6,d0			* pass mode
	move.l	a2,a0			* pass ADDR1
	bsr.l	_real_unlock_page	* unlock first page(s)
	move.l	(sp)+,d0		* restore FSLW
	move.l	a3,a0			* pass failing addr
	bra.l	_cas_terminate2

*############################################################

	global	_isp_cas2_finish
_isp_cas2_finish:
	btst	#$1,EXC_OPWORD(a6)
	bne.b	cas2_finish_l

	move.w	EXC_CC(a6),ccr		* load old ccodes
	cmp.w	d2,d0
	bne.b	cas2_finish_w_save
	cmp.w	d3,d1
cas2_finish_w_save:
	move.w	ccr,EXC_CC(a6)		* save new ccodes

	tst.b	d4			* update compare reg?
	bne.b	cas2_finish_w_done	* no

	move.w	DC2(a6),d3		* fetch Dc2
	move.w	d1,(2+EXC_DREGS,a6,d3.w*4)	* store new Compare2 Op

	move.w	DC1(a6),d2		* fetch Dc1
	move.w	d0,(2+EXC_DREGS,a6,d2.w*4)	* store new Compare1 Op

cas2_finish_w_done:
	btst	#$5,EXC_ISR(a6)
	sne	d2
	move.l	d2,d0			* pass mode
	sf	d1			* pass size
	move.l	ADDR1(a6),a0		* pass ADDR1
	bsr.l	_real_unlock_page	* unlock page

	move.l	d2,d0			* pass mode
	sf	d1			* pass size
	move.l	ADDR2(a6),a0		* pass ADDR2
	bsr.l	_real_unlock_page	* unlock page
	rts

cas2_finish_l:
	move.w	EXC_CC(a6),ccr		* load old ccodes
	cmp.l	d2,d0
	bne.b	cas2_finish_l_save
	cmp.l	d3,d1
cas2_finish_l_save:
	move.w	ccr,EXC_CC(a6)		* save new ccodes

	tst.b	d4			* update compare reg?
	bne.b	cas2_finish_l_done	* no

	move.w	DC2(a6),d3		* fetch Dc2
	move.l	d1,(EXC_DREGS,a6,d3.w*4)	* store new Compare2 Op

	move.w	DC1(a6),d2		* fetch Dc1
	move.l	d0,(EXC_DREGS,a6,d2.w*4)	* store new Compare1 Op

cas2_finish_l_done:
	btst	#$5,EXC_ISR(a6)
	sne	d2
	move.l	d2,d0			* pass mode
	st	d1			* pass size
	move.l	ADDR1(a6),a0		* pass ADDR1
	bsr.l	_real_unlock_page	* unlock page

	move.l	d2,d0			* pass mode
	st	d1			* pass size
	move.l	ADDR2(a6),a0		* pass ADDR2
	bsr.l	_real_unlock_page	* unlock page
	rts

*#######
	global	cr_cas2
cr_cas2:
	move.l	EXC_TEMP+$4(a6),d0
	bra.w	_compandset2

*########################################################################
* XDEF ****************************************************************	#
*	_compandset(): routine to emulate cas w/ misaligned <ea>	#
*		       (internal to package)				#
*	_isp_cas_finish(): routine called when cas emulation completes	#
*			   (external and internal to package)		#
*	_isp_cas_restart(): restart cas emulation after a fault		#
*			    (external to package)			#
*	_isp_cas_terminate(): create access error stack frame on fault	#
*			      (external and internal to package)	#
*	_isp_cas_inrange(): checks whether instr addess is within range	#
*			    of core cas/cas2emulation code		#
*			    (external to package)			#
*									#
* XREF ****************************************************************	#
* 	_calc_ea(): calculate effective address				#
*									#
* INPUT ***************************************************************	#
* compandset():								#
* 	none								#
* _isp_cas_restart():							#
*	d6 = previous sfc/dfc						#
* _isp_cas_finish():							#
* _isp_cas_terminate():							#
*	a0 = failing address						#
*	d0 = FSLW							#
*	d6 = previous sfc/dfc						#
* _isp_cas_inrange():							#
*	a0 = instruction address to be checked				#
*									#
* OUTPUT **************************************************************	#
* compandset():								#
*		none							#
* _isp_cas_restart():							#
*	a0 = effective address						#
*	d7 = word or longword flag					#
* _isp_cas_finish():							#
*	a0 = effective address						#
* _isp_cas_terminate():							#
*	initial register set before emulation exception			#
* _isp_cas_inrange():							#
*	d0 = 0 => in range; -1 => out of range				#
*									#
* ALGORITHM ***********************************************************	#
*									#
* compandset():								#
*	First, calculate the effective address. Then, decode the 	#
* instruction word and fetch the "compare" (DC) and "update" (Du)	#
* operands.								#
* 	Next, call the external routine _real_lock_page() so that the	#
* operating system can keep this page from being paged out while we're	#
* in this routine. If this call fails, jump to _cas_terminate2().	#
*	The routine then branches to _real_cas(). This external routine	#
* that actually emulates cas can be supplied by the external os or	#
* made to point directly back into the 060ISP which has a routine for	#
* this purpose.								#
*									#
* _isp_cas_finish():							#
* 	Either way, after emulation, the package is re-entered at	#
* _isp_cas_finish(). This routine re-compares the operands in order to	#
* set the condition codes. Finally, these routines will call		#
* _real_unlock_page() in order to unlock the pages that were previously	#
* locked.								#
*									#
* _isp_cas_restart():							#
*	This routine can be entered from an access error handler where	#
* the emulation sequence should be re-started from the beginning.	#
*									#
* _isp_cas_terminate():							#
*	This routine can be entered from an access error handler where	#
* an emulation operand access failed and the operating system would	#
* like an access error stack frame created instead of the current 	#
* unimplemented integer instruction frame.				#
* 	Also, the package enters here if a call to _real_lock_page()	#
* fails.								#
*									#
* _isp_cas_inrange():							#
* 	Checks to see whether the instruction address passed to it in	#
* a0 is within the software package cas/cas2 emulation routines. This	#
* can be helpful for an operating system to determine whether an access	#
* error during emulation was due to a cas/cas2 emulation access.	#
*									#
*########################################################################

__DC__	set	EXC_TEMP+$8
ADDR	set	EXC_TEMP+$4

	global	_compandset
_compandset:
	btst	#$1,EXC_OPWORD(a6)	* word or long operation?
	bne.b	compandsetl		* long	

compandsetw:
	moveq.l	#$2,d0			* size = 2 bytes
	bsr.l	_calc_ea		* a0 = calculated <ea>	
	move.l	a0,ADDR(a6)		* save <ea> for possible restart
	sf	d7			* clear d7 for word size
	bra.b	compandsetfetch

compandsetl:
	moveq.l	#$4,d0			* size = 4 bytes
	bsr.l	_calc_ea		* a0 = calculated <ea>	
	move.l	a0,ADDR(a6)		* save <ea> for possible restart
	st	d7			* set d7 for longword size

compandsetfetch:
	move.w	EXC_EXTWORD(a6),d0	* fetch cas extension word
	move.l	d0,d1			* make a copy

	lsr.w	#$6,d0
	andi.w	#$7,d0			* extract Du
	move.l	(EXC_DREGS,a6,d0.w*4),d2	* get update operand

	andi.w	#$7,d1			* extract Dc
	move.l	(EXC_DREGS,a6,d1.w*4),d4	* get compare operand
	move.w	d1,__DC__(a6)		* save Dc

	btst	#$5,EXC_ISR(a6)		* which mode for exception?
	sne	d6			* set on supervisor mode

	move.l	a0,a2			* save temporarily
	move.l	d7,d1			* pass size
	move.l	d6,d0			* pass mode
	bsr.l	_real_lock_page		* lock page
	tst.l	d0			* did error occur?
	bne.w	_cas_terminate2		* yes, clean up the mess
	move.l	a2,a0			* pass addr in a0

	bra.l	_real_cas

*#######
	global	_isp_cas_finish
_isp_cas_finish:
	btst	#$1,EXC_OPWORD(a6)
	bne.b	cas_finish_l

* just do the compare again since it's faster than saving the ccodes
* from the locked routine...
cas_finish_w:
	move.w	EXC_CC(a6),ccr		* restore cc
	cmp.w	d4,d0			* do word compare
	move.w	ccr,EXC_CC(a6)		* save cc

	tst.b	d1			* update compare reg?
	bne.b	cas_finish_w_done	* no

	move.w	__DC__(a6),d3
	move.w	d0,(EXC_DREGS+2,a6,d3.w*4)	* Dc = destination

cas_finish_w_done:
	move.l	ADDR(a6),a0		* pass addr
	sf	d1			* pass size
	btst	#$5,EXC_ISR(a6)
	sne	d0			* pass mode
	bsr.l	_real_unlock_page	* unlock page
	rts

* just do the compare again since it's faster than saving the ccodes
* from the locked routine...
cas_finish_l:
	move.w	EXC_CC(a6),ccr		* restore cc
	cmp.l	d4,d0			* do longword compare
	move.w	ccr,EXC_CC(a6)		* save cc

	tst.b	d1			* update compare reg?
	bne.b	cas_finish_l_done	* no

	move.w	__DC__(a6),d3
	move.l	d0,(EXC_DREGS,a6,d3.w*4)	* Dc = destination

cas_finish_l_done:
	move.l	ADDR(a6),a0		* pass addr
	st	d1			* pass size
	btst	#$5,EXC_ISR(a6)
	sne	d0			* pass mode
	bsr.l	_real_unlock_page	* unlock page
	rts

*#######

	global	_isp_cas_restart
_isp_cas_restart:
	movec.l	d6,sfc			* restore previous sfc
	movec.l	d6,dfc			* restore previous dfc

	cmpi.b	#$fc,EXC_OPWORD+1(a6)	* cas or cas2?
	beq.l	cr_cas2			* cas2
cr_cas:
	move.l	ADDR(a6),a0		* load <ea>
	btst	#$1,EXC_OPWORD(a6)	* word or long operation?
	sne	d7			* set d7 accordingly
	bra.w	compandsetfetch

*#######

* At this stage, it would be nice if d0 held the FSLW.
	global	_isp_cas_terminate
_isp_cas_terminate:
	movec.l	d6,sfc			* restore previous sfc
	movec.l	d6,dfc			* restore previous dfc

	global	_cas_terminate2
_cas_terminate2:
	move.l	a0,a2			* copy failing addr to a2

	move.l	d0,-(sp)
	bsr.l	isp_restore		* restore An (if ()+ or -())
	move.l	(sp)+,d0

	addq.l	#$4,sp			* remove sub return addr
	subq.l	#$8,sp			* make room for bigger stack
	subq.l	#$8,a6			* shift frame ptr down, too
	move.l	#26,d1			* want to move 51 longwords
	lea	$8(sp),a0		* get address of old stack
	lea	$0.w(sp),a1		* get address of new stack
cas_term_cont:
	move.l	(a0)+,(a1)+		* move a longword
	dbra.w	d1,cas_term_cont	* keep going

	move.w	#$4008,EXC_IVOFF(a6)	* put new stk fmt, voff
	move.l	a2,EXC_IVOFF+$2(a6)	* put faulting addr on stack
	move.l	d0,EXC_IVOFF+$6(a6)	* put FSLW on stack
	movem.l	EXC_DREGS(a6),d0-d7/a0-a5	* restore user regs
	unlk	a6			* unlink stack frame
	bra.l	_real_access

*#######

	global	_isp_cas_inrange
_isp_cas_inrange:
	clr.l	d0			* clear return result
	lea	_CASHI.l(pc),a1		* load end of CAS core code
	cmp.l	a0,a1			* is PC in range?
	blt.b	cin_no			* no
	lea	_CASLO.l(pc),a1		* load begin of CAS core code
	cmp.l	a1,a0			* is PC in range?
	blt.b	cin_no			* no
	rts				* yes; return d0 = 0
cin_no:
	move.l	#-$1,d0			* out of range; return d0 = -1
	rts

*################################################################
*################################################################
*################################################################
* This is the start of the cas and cas2 "core" emulation code.	#
* This is the section that may need to be replaced by the host	#
* OS if it is too operating system-specific.			#
* Please refer to the package documentation to see how to	#
* "replace" this section, if necessary.				#
*################################################################
*################################################################
*################################################################

*       ######      ##      ######     ####
*       #	   #  #     #         #    #
*	#	  ######    ######        #
*	#	  #    #         #      #
*       ######    #    #    ######    ######

*########################################################################
* XDEF ****************************************************************	#
*	_isp_cas2(): "core" emulation code for the cas2 instruction	#
*									#
* XREF ****************************************************************	#
*	_isp_cas2_finish() - only exit point for this emulation code;	#
*			     do clean-up; calculate ccodes; store 	#
*			     Compare Ops if appropriate.		#
*									#
* INPUT ***************************************************************	#
*	*see chart below*						#
* 									#
* OUTPUT **************************************************************	#
*	*see chart below*						#
*									#
* ALGORITHM ***********************************************************	#
*	(1) Make several copies of the effective address.		#
*	(2) Save current SR; Then mask off all maskable interrupts.	#
*	(3) Save current SFC/DFC (ASSUMED TO BE EQUAL!!!); Then set 	#
*	    according to whether exception occurred in user or 		#
*	    supervisor mode.						#
*	(4) Use "plpaw" instruction to pre-load ATC with effective	#
*	    address pages(s). THIS SHOULD NOT FAULT!!! The relevant	#
*	    page(s) should have already been made resident prior to	#
* 	    entering this routine.					#
*	(5) Push the operand lines from the cache w/ "cpushl". 		#
*	    In the 68040, this was done within the locked region. In	#
* 	    the 68060, it is done outside of the locked region.		#
*	(6) Use "plpar" instruction to do a re-load of ATC entries for	#
*	    ADDR1 since ADDR2 entries may have pushed ADDR1 out of the	#
*	    ATC.							#
*	(7) Pre-fetch the core emulation instructions by executing	#
*	    one branch within each physical line (16 bytes) of the code	#
*	    before actually executing the code.				#
*	(8) Load the BUSCR w/ the bus lock value.			#
*	(9) Fetch the source operands using "moves".			#
*	(10)Do the compares. If both equal, go to step (13).		#
*	(11)Unequal. No update occurs. But, we do write the DST1 op	#
*	    back to itself (as w/ the '040) so we can gracefully unlock	#
*	    the bus (and assert LOCKE*) using BUSCR and the final move.	#
*	(12)Exit.							#
*	(13)Write update operand to the DST locations. Use BUSCR to 	#
*	    assert LOCKE* for the final write operation.		#
*	(14)Exit.							#
*									#
* 	The algorithm is actually implemented slightly differently	#
* depending on the size of the operation and the misalignment of the 	#
* operands. A misaligned operand must be written in aligned chunks or	#
* else the BUSCR register control gets confused.			#
*									#
*########################################################################

*################################################################
* THIS IS THE STATE OF THE INTEGER REGISTER FILE UPON		# 
* ENTERING _isp_cas2().						#
*								#
* D0 = xxxxxxxx							#
* D1 = xxxxxxxx							#
* D2 = cmp operand 1						#
* D3 = cmp operand 2						#
* D4 = update oper 1						#
* D5 = update oper 2						#
* D6 = 'xxxxxxff if supervisor mode; 'xxxxxx00 if user mode	#
* D7 = 'xxxxxxff if longword operation; 'xxxxxx00 if word 	#
* A0 = ADDR1							#
* A1 = ADDR2							#
* A2 = xxxxxxxx							#
* A3 = xxxxxxxx							#
* A4 = xxxxxxxx							#
* A5 = xxxxxxxx							#
* A6 = frame pointer						#
* A7 = stack pointer						#
*################################################################

*	align		0x1000
* beginning label used by _isp_cas_inrange()
	global	_CASLO
_CASLO:

	global	_isp_cas2
_isp_cas2:
	tst.b	d6			* user or supervisor mode?
	bne.b	cas2_supervisor		* supervisor
cas2_user:
	moveq.l	#$1,d0			* load user data fc
	bra.b	cas2_cont
cas2_supervisor:
	moveq.l	#$5,d0			* load supervisor data fc
cas2_cont:
	tst.b	d7			* word or longword?
	beq.w	cas2w			* word

*###
cas2l:
	move.l	a0,a2			* copy ADDR1
	move.l	a1,a3			* copy ADDR2
	move.l	a0,a4			* copy ADDR1
	move.l	a1,a5			* copy ADDR2

	addq.l	#$3,a4			* ADDR1+3
	addq.l	#$3,a5			* ADDR2+3
	move.l	a2,d1			* ADDR1

* mask interrupts levels 0-6. save old mask value.
	move.w	sr,d7			* save current SR
	ori.w	#$0700,sr		* inhibit interrupts

* load the SFC and DFC with the appropriate mode.
	movec	sfc,d6			* save old SFC/DFC
	movec	d0,sfc			* store new SFC
	movec	d0,dfc			* store new DFC

* pre-load the operand ATC. no page faults should occur here because
* _real_lock_page() should have taken care of this.
	plpaw	(a2)			* load atc for ADDR1
	plpaw	(a4)			* load atc for ADDR1+3
	plpaw	(a3)			* load atc for ADDR2
	plpaw	(a5)			* load atc for ADDR2+3

* push the operand lines from the cache if they exist.
	cpushl	dc,(a2)			* push line for ADDR1
	cpushl	dc,(a4)			* push line for ADDR1+3
	cpushl	dc,(a3)			* push line for ADDR2
	cpushl	dc,(a5)			* push line for ADDR2+2

	move.l	d1,a2			* ADDR1
	addq.l	#$3,d1
	move.l	d1,a4			* ADDR1+3
* if ADDR1 was ATC resident before the above "plpaw" and was executed
* and it was the next entry scheduled for replacement and ADDR2
* shares the same set, then the "plpaw" for ADDR2 can push the ADDR1
* entries from the ATC. so, we do a second set of "plpa"s.
	plpar	(a2)			* load atc for ADDR1
	plpar	(a4)			* load atc for ADDR1+3

* load the BUSCR values.
	move.l	#$80000000,a2		* assert LOCK* buscr value
	move.l	#$a0000000,a3		* assert LOCKE* buscr value
	move.l	#$00000000,a4		* buscr unlock value

* there are three possible mis-aligned cases for longword cas. they
* are separated because the final write which asserts LOCKE* must
* be aligned.
	move.l	a0,d0			* is ADDR1 misaligned?
	andi.b	#$3,d0
	beq.b	CAS2L_ENTER		* no
	cmpi.b	#$2,d0
	beq.w	CAS2L2_ENTER		* yes; word misaligned
	bra.w	CAS2L3_ENTER		* yes; byte misaligned

*
* D0 = dst operand 1 <-
* D1 = dst operand 2 <-
* D2 = cmp operand 1
* D3 = cmp operand 2
* D4 = update oper 1
* D5 = update oper 2
* D6 = old SFC/DFC
* D7 = old SR
* A0 = ADDR1
* A1 = ADDR2
* A2 = bus LOCK*  value
* A3 = bus LOCKE* value
* A4 = bus unlock value
* A5 = xxxxxxxx
*
	align	$10,$51FC
CAS2L_START:
	movec	a2,buscr		* assert LOCK*
	moves.l	(a1),d1			* fetch Dest2[31:0]
	moves.l	(a0),d0			* fetch Dest1[31:0]
	bra.b	CAS2L_CONT
CAS2L_ENTER:
	bra.b	(*)+16

CAS2L_CONT:
	cmp.l	d2,d0			* Dest1 - Compare1
	bne.b	CAS2L_NOUPDATE
	cmp.l	d3,d1			* Dest2 - Compare2
	bne.b	CAS2L_NOUPDATE
	moves.l	d5,(a1)			* Update2[31:0] -> DEST2
	bra.b	CAS2L_UPDATE
	bra.b	(*)+16

CAS2L_UPDATE:
	movec	a3,buscr		* assert LOCKE*
	moves.l	d4,(a0)			* Update1[31:0] -> DEST1
	movec	a4,buscr		* unlock the bus
	bra.b	cas2l_update_done
	bra.b	(*)+16

CAS2L_NOUPDATE:
	movec	a3,buscr		* assert LOCKE*
	moves.l	d0,(a0)			* Dest1[31:0] -> DEST1
	movec	a4,buscr		* unlock the bus
	bra.b	cas2l_noupdate_done
	bra.b	(*)+16

CAS2L_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CAS2L_START

*###

*################################################################
* THIS MUST BE THE STATE OF THE INTEGER REGISTER FILE UPON	# 
* ENTERING _isp_cas2().						#
*								#
* D0 = destination[31:0] operand 1				#
* D1 = destination[31:0] operand 2				#
* D2 = cmp[31:0] operand 1					#
* D3 = cmp[31:0] operand 2					#
* D4 = 'xxxxxx11 -> no reg update; 'xxxxxx00 -> update required	#
* D5 = xxxxxxxx							#
* D6 = xxxxxxxx							#
* D7 = xxxxxxxx							#
* A0 = xxxxxxxx							#
* A1 = xxxxxxxx							#
* A2 = xxxxxxxx							#
* A3 = xxxxxxxx							#
* A4 = xxxxxxxx							#
* A5 = xxxxxxxx							#
* A6 = frame pointer						#
* A7 = stack pointer						#
*################################################################

cas2l_noupdate_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	sf	d4			* indicate no update was done
	bra.l	_isp_cas2_finish

cas2l_update_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	st	d4			* indicate update was done
	bra.l	_isp_cas2_finish
*###

	align	$10,$51FC
CAS2L2_START:
	movec	a2,buscr		* assert LOCK*
	moves.l	(a1),d1			* fetch Dest2[31:0]
	moves.l	(a0),d0			* fetch Dest1[31:0]
	bra.b	CAS2L2_CONT
CAS2L2_ENTER:
	bra.b	(*)+16

CAS2L2_CONT:
	cmp.l	d2,d0			* Dest1 - Compare1
	bne.b	CAS2L2_NOUPDATE
	cmp.l	d3,d1			* Dest2 - Compare2
	bne.b	CAS2L2_NOUPDATE
	moves.l	d5,(a1)			* Update2[31:0] -> Dest2
	bra.b	CAS2L2_UPDATE
	bra.b	(*)+16

CAS2L2_UPDATE:
	swap	d4			* get Update1[31:16]
	moves.w	d4,(a0)+		* Update1[31:16] -> DEST1
	movec	a3,buscr		* assert LOCKE*
	swap	d4			* get Update1[15:0]
	bra.b	CAS2L2_UPDATE2
	bra.b	(*)+16

CAS2L2_UPDATE2:
	moves.w	d4,(a0)			* Update1[15:0] -> DEST1+0x2
	movec	a4,buscr		* unlock the bus
	bra.w	cas2l_update_done
	nop
	bra.b	(*)+16

CAS2L2_NOUPDATE:
	swap	d0			* get Dest1[31:16]
	moves.w	d0,(a0)+		* Dest1[31:16] -> DEST1
	movec	a3,buscr		* assert LOCKE*
	swap	d0			* get Dest1[15:0]
	bra.b	CAS2L2_NOUPDATE2
	bra.b	(*)+16

CAS2L2_NOUPDATE2:
	moves.w	d0,(a0)			* Dest1[15:0] -> DEST1+0x2
	movec	a4,buscr		* unlock the bus
	bra.w	cas2l_noupdate_done
	nop
	bra.b	(*)+16

CAS2L2_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CAS2L2_START

*################################

	align	$10,$51FC
CAS2L3_START:
	movec	a2,buscr		* assert LOCK*
	moves.l	(a1),d1			* fetch Dest2[31:0]
	moves.l	(a0),d0			* fetch Dest1[31:0]
	bra.b	CAS2L3_CONT
CAS2L3_ENTER:
	bra.b	(*)+16

CAS2L3_CONT:
	cmp.l	d2,d0			* Dest1 - Compare1
	bne.b	CAS2L3_NOUPDATE
	cmp.l	d3,d1			* Dest2 - Compare2
	bne.b	CAS2L3_NOUPDATE
	moves.l	d5,(a1)			* Update2[31:0] -> DEST2
	bra.b	CAS2L3_UPDATE
	bra.b	(*)+16

CAS2L3_UPDATE:
	rol.l	#$8,d4			* get Update1[31:24]
	moves.b	d4,(a0)+		* Update1[31:24] -> DEST1
	swap	d4			* get Update1[23:8]
	moves.w	d4,(a0)+		* Update1[23:8] -> DEST1+0x1
	bra.b	CAS2L3_UPDATE2
	bra.b	(*)+16

CAS2L3_UPDATE2:
	rol.l	#$8,d4			* get Update1[7:0]
	movec	a3,buscr		* assert LOCKE*
	moves.b	d4,(a0)			* Update1[7:0] -> DEST1+0x3
	bra.b	CAS2L3_UPDATE3
	nop
	bra.b	(*)+16

CAS2L3_UPDATE3:
	movec	a4,buscr		* unlock the bus
	bra.w	cas2l_update_done
	nop
	nop
	nop
	bra.b	(*)+16

CAS2L3_NOUPDATE:
	rol.l	#$8,d0			* get Dest1[31:24]
	moves.b	d0,(a0)+		* Dest1[31:24] -> DEST1
	swap	d0			* get Dest1[23:8]
	moves.w	d0,(a0)+		* Dest1[23:8] -> DEST1+0x1
	bra.b	CAS2L3_NOUPDATE2
	bra.b	(*)+16

CAS2L3_NOUPDATE2:
	rol.l	#$8,d0			* get Dest1[7:0]
	movec	a3,buscr		* assert LOCKE*
	moves.b	d0,(a0)			* Update1[7:0] -> DEST1+0x3
	bra.b	CAS2L3_NOUPDATE3
	nop
	bra.b	(*)+16

CAS2L3_NOUPDATE3:
	movec	a4,buscr		* unlock the bus
	bra.w	cas2l_noupdate_done
	nop
	nop
	nop
	bra.b	(*)+14

CAS2L3_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	bra.w	CAS2L3_START

*############################################################
*############################################################

cas2w:
	move.l	a0,a2			* copy ADDR1
	move.l	a1,a3			* copy ADDR2
	move.l	a0,a4			* copy ADDR1
	move.l	a1,a5			* copy ADDR2

	addq.l	#$1,a4			* ADDR1+1
	addq.l	#$1,a5			* ADDR2+1
	move.l	a2,d1			* ADDR1

* mask interrupt levels 0-6. save old mask value.
	move.w	sr,d7			* save current SR
	ori.w	#$0700,sr		* inhibit interrupts

* load the SFC and DFC with the appropriate mode.
	movec	sfc,d6			* save old SFC/DFC
	movec	d0,sfc			* store new SFC
	movec	d0,dfc			* store new DFC

* pre-load the operand ATC. no page faults should occur because
* _real_lock_page() should have taken care of this.
	plpaw	(a2)			* load atc for ADDR1
	plpaw	(a4)			* load atc for ADDR1+1
	plpaw	(a3)			* load atc for ADDR2
	plpaw	(a5)			* load atc for ADDR2+1

* push the operand cache lines from the cache if they exist.
	cpushl	dc,(a2)			* push line for ADDR1
	cpushl	dc,(a4)			* push line for ADDR1+1
	cpushl	dc,(a3)			* push line for ADDR2
	cpushl	dc,(a5)			* push line for ADDR2+1

	move.l	d1,a2			* ADDR1
	addq.l	#$3,d1
	move.l	d1,a4			* ADDR1+3
* if ADDR1 was ATC resident before the above "plpaw" and was executed
* and it was the next entry scheduled for replacement and ADDR2
* shares the same set, then the "plpaw" for ADDR2 can push the ADDR1
* entries from the ATC. so, we do a second set of "plpa"s.
	plpar	(a2)			* load atc for ADDR1
	plpar	(a4)			* load atc for ADDR1+3

* load the BUSCR values.
	move.l	#$80000000,a2		* assert LOCK* buscr value
	move.l	#$a0000000,a3		* assert LOCKE* buscr value
	move.l	#$00000000,a4		* buscr unlock value

* there are two possible mis-aligned cases for word cas. they
* are separated because the final write which asserts LOCKE* must
* be aligned.
	move.l	a0,d0			* is ADDR1 misaligned?
	btst	#$0,d0
	bne.w	CAS2W2_ENTER		* yes
	bra.b	CAS2W_ENTER		* no

*
* D0 = dst operand 1 <-
* D1 = dst operand 2 <-
* D2 = cmp operand 1
* D3 = cmp operand 2
* D4 = update oper 1
* D5 = update oper 2
* D6 = old SFC/DFC
* D7 = old SR
* A0 = ADDR1
* A1 = ADDR2
* A2 = bus LOCK*  value
* A3 = bus LOCKE* value
* A4 = bus unlock value
* A5 = xxxxxxxx
*
	align	$10,$51FC
CAS2W_START:
	movec	a2,buscr		* assert LOCK*
	moves.w	(a1),d1			* fetch Dest2[15:0]
	moves.w	(a0),d0			* fetch Dest1[15:0]
	bra.b	CAS2W_CONT2
CAS2W_ENTER:
	bra.b	(*)+16

CAS2W_CONT2:
	cmp.w	d2,d0			* Dest1 - Compare1
	bne.b	CAS2W_NOUPDATE
	cmp.w	d3,d1			* Dest2 - Compare2
	bne.b	CAS2W_NOUPDATE
	moves.w	d5,(a1)			* Update2[15:0] -> DEST2
	bra.b	CAS2W_UPDATE
	bra.b	(*)+16

CAS2W_UPDATE:
	movec	a3,buscr		* assert LOCKE*
	moves.w	d4,(a0)			* Update1[15:0] -> DEST1
	movec	a4,buscr		* unlock the bus
	bra.b	cas2w_update_done
	bra.b	(*)+16

CAS2W_NOUPDATE:
	movec	a3,buscr		* assert LOCKE*
	moves.w	d0,(a0)			* Dest1[15:0] -> DEST1
	movec	a4,buscr		* unlock the bus
	bra.b	cas2w_noupdate_done
	bra.b	(*)+16

CAS2W_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CAS2W_START

*###

*################################################################
* THIS MUST BE THE STATE OF THE INTEGER REGISTER FILE UPON	# 
* ENTERING _isp_cas2().						#
*								#
* D0 = destination[15:0] operand 1				#
* D1 = destination[15:0] operand 2				#
* D2 = cmp[15:0] operand 1					#
* D3 = cmp[15:0] operand 2					#
* D4 = 'xxxxxx11 -> no reg update; 'xxxxxx00 -> update required	#
* D5 = xxxxxxxx							#
* D6 = xxxxxxxx							#
* D7 = xxxxxxxx							#
* A0 = xxxxxxxx							#
* A1 = xxxxxxxx							#
* A2 = xxxxxxxx							#
* A3 = xxxxxxxx							#
* A4 = xxxxxxxx							#
* A5 = xxxxxxxx							#
* A6 = frame pointer						#
* A7 = stack pointer						#
*################################################################

cas2w_noupdate_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	sf	d4			* indicate no update was done
	bra.l	_isp_cas2_finish

cas2w_update_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	st	d4			* indicate update was done
	bra.l	_isp_cas2_finish
*###

	align	$10,$51FC
CAS2W2_START:
	movec	a2,buscr		* assert LOCK*
	moves.w	(a1),d1			* fetch Dest2[15:0]
	moves.w	(a0),d0			* fetch Dest1[15:0]
	bra.b	CAS2W2_CONT2
CAS2W2_ENTER:
	bra.b	(*)+16

CAS2W2_CONT2:
	cmp.w	d2,d0			* Dest1 - Compare1
	bne.b	CAS2W2_NOUPDATE
	cmp.w	d3,d1			* Dest2 - Compare2
	bne.b	CAS2W2_NOUPDATE
	moves.w	d5,(a1)			* Update2[15:0] -> DEST2
	bra.b	CAS2W2_UPDATE
	bra.b	(*)+16

CAS2W2_UPDATE:
	ror.l	#$8,d4			* get Update1[15:8]
	moves.b	d4,(a0)+		* Update1[15:8] -> DEST1
	movec	a3,buscr		* assert LOCKE*
	rol.l	#$8,d4			* get Update1[7:0]
	bra.b	CAS2W2_UPDATE2
	bra.b	(*)+16

CAS2W2_UPDATE2:
	moves.b	d4,(a0)			* Update1[7:0] -> DEST1+0x1
	movec	a4,buscr		* unlock the bus
	bra.w	cas2w_update_done
	nop
	bra.b	(*)+16

CAS2W2_NOUPDATE:
	ror.l	#$8,d0			* get Dest1[15:8]
	moves.b	d0,(a0)+		* Dest1[15:8] -> DEST1
	movec	a3,buscr		* assert LOCKE*
	rol.l	#$8,d0			* get Dest1[7:0]
	bra.b	CAS2W2_NOUPDATE2
	bra.b	(*)+16

CAS2W2_NOUPDATE2:
	moves.b	d0,(a0)			* Dest1[7:0] -> DEST1+0x1
	movec	a4,buscr		* unlock the bus
	bra.w	cas2w_noupdate_done
	nop
	bra.b	(*)+16

CAS2W2_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CAS2W2_START

*       ######      ##      ######
*       #	   #  #     #     
*	#	  ######    ######
*	#	  #    #         #
*       ######    #    #    ######

*########################################################################
* XDEF ****************************************************************	#
* 	_isp_cas(): "core" emulation code for the cas instruction	#
*									#
* XREF ****************************************************************	#
*	_isp_cas_finish() - only exit point for this emulation code;	#
*			    do clean-up					#
*									#
* INPUT ***************************************************************	#
* 	*see entry chart below*						#
*									#
* OUTPUT **************************************************************	#
*	*see exit chart below*						#
*									#
* ALGORITHM ***********************************************************	#
* 	(1) Make several copies of the effective address. 		#
* 	(2) Save current SR; Then mask off all maskable interrupts.	#
*	(3) Save current DFC/SFC (ASSUMED TO BE EQUAL!!!); Then set	#
*	    SFC/DFC according to whether exception occurred in user or	#
*	    supervisor mode.						#
*	(4) Use "plpaw" instruction to pre-load ATC with efective	#
*	    address page(s). THIS SHOULD NOT FAULT!!! The relevant	#
* 	    page(s) should have been made resident prior to entering 	#
*	    this routine.						#
*	(5) Push the operand lines from the cache w/ "cpushl".		#
*	    In the 68040, this was done within the locked region. In	#
*	    the 68060, it is done outside of the locked region.		#
*	(6) Pre-fetch the core emulation instructions by executing one	#
*	    branch within each physical line (16 bytes) of the code	#
*	    before actually executing the code.				#
*	(7) Load the BUSCR with the bus lock value.			#
*	(8) Fetch the source operand.					#
*	(9) Do the compare. If equal, go to step (12).			#
*	(10)Unequal. No update occurs. But, we do write the DST op back	#
*	    to itself (as w/ the '040) so we can gracefully unlock	#
*	    the bus (and assert LOCKE*) using BUSCR and the final move.	#
*	(11)Exit.							#
*	(12)Write update operand to the DST location. Use BUSCR to	#
*	    assert LOCKE* for the final write operation.		#
*	(13)Exit.							#
* 									#
* 	The algorithm is actually implemented slightly diferently	#
* depending on the size of the operation and the misalignment of the	#
* operand. A misaligned operand must be written in aligned chunks or	#
* else the BUSCR register control gets confused.			#
*									#
*########################################################################

*########################################################
* THIS IS THE STATE OF THE INTEGER REGISTER FILE UPON	#
* ENTERING _isp_cas().					#
*							#
* D0 = xxxxxxxx						#
* D1 = xxxxxxxx						#
* D2 = update operand					#
* D3 = xxxxxxxx						#
* D4 = compare operand					#
* D5 = xxxxxxxx						#
* D6 = supervisor ('xxxxxxff) or user mode ('xxxxxx00)	#
* D7 = longword ('xxxxxxff) or word size ('xxxxxx00)	#
* A0 = ADDR						#
* A1 = xxxxxxxx						#
* A2 = xxxxxxxx						#
* A3 = xxxxxxxx						#
* A4 = xxxxxxxx						#
* A5 = xxxxxxxx						#
* A6 = frame pointer					#
* A7 = stack pointer					#
*########################################################

	global	_isp_cas
_isp_cas:
	tst.b	d6			* user or supervisor mode?
	bne.b	cas_super		* supervisor
cas_user:
	moveq.l	#$1,d0			* load user data fc
	bra.b	cas_cont
cas_super:
	moveq.l	#$5,d0			* load supervisor data fc

cas_cont:
	tst.b	d7			* word or longword?
	bne.w	casl			* longword

*###
casw:
	move.l	a0,a1			* make copy for plpaw1
	move.l	a0,a2			* make copy for plpaw2
	addq.l	#$1,a2			* plpaw2 points to end of word

	move.l	d2,d3			* d3 = update[7:0]
	lsr.w	#$8,d2			* d2 = update[15:8]

* mask interrupt levels 0-6. save old mask value.
	move.w	sr,d7			* save current SR
	ori.w	#$0700,sr		* inhibit interrupts

* load the SFC and DFC with the appropriate mode.
	movec	sfc,d6			* save old SFC/DFC
	movec	d0,sfc			* load new sfc
	movec	d0,dfc			* load new dfc

* pre-load the operand ATC. no page faults should occur here because
* _real_lock_page() should have taken care of this.
	plpaw	(a1)			* load atc for ADDR
	plpaw	(a2)			* load atc for ADDR+1

* push the operand lines from the cache if they exist.
	cpushl	dc,(a1)			* push dirty data
	cpushl	dc,(a2)			* push dirty data

* load the BUSCR values.
	move.l	#$80000000,a1		* assert LOCK* buscr value
	move.l	#$a0000000,a2		* assert LOCKE* buscr value
	move.l	#$00000000,a3		* buscr unlock value

* pre-load the instruction cache for the following algorithm.
* this will minimize the number of cycles that LOCK* will be asserted.
	bra.b	CASW_ENTER		* start pre-loading icache

*
* D0 = dst operand <-
* D1 = update[15:8] operand
* D2 = update[7:0]  operand
* D3 = xxxxxxxx
* D4 = compare[15:0] operand
* D5 = xxxxxxxx
* D6 = old SFC/DFC
* D7 = old SR
* A0 = ADDR
* A1 = bus LOCK*  value
* A2 = bus LOCKE* value
* A3 = bus unlock value
* A4 = xxxxxxxx
* A5 = xxxxxxxx
*
	align	$10,$51FC
CASW_START:
	movec	a1,buscr		* assert LOCK*
	moves.w	(a0),d0			* fetch Dest[15:0]
	cmp.w	d4,d0			* Dest - Compare
	bne.b	CASW_NOUPDATE
	bra.b	CASW_UPDATE
CASW_ENTER:
	bra.b	(*)+16

CASW_UPDATE:
	moves.b	d2,(a0)+		* Update[15:8] -> DEST
	movec	a2,buscr		* assert LOCKE*
	moves.b	d3,(a0)			* Update[7:0] -> DEST+0x1
	bra.b	CASW_UPDATE2
	bra.b	(*)+16

CASW_UPDATE2:
	movec	a3,buscr		* unlock the bus
	bra.b	casw_update_done
	nop
	nop
	nop
	nop
	bra.b	(*)+16

CASW_NOUPDATE:
	ror.l	#$8,d0			* get Dest[15:8]
	moves.b	d0,(a0)+		* Dest[15:8] -> DEST
	movec	a2,buscr		* assert LOCKE*
	rol.l	#$8,d0			* get Dest[7:0]
	bra.b	CASW_NOUPDATE2
	bra.b	(*)+16

CASW_NOUPDATE2:
	moves.b	d0,(a0)			* Dest[7:0] -> DEST+0x1
	movec	a3,buscr		* unlock the bus
	bra.b	casw_noupdate_done
	nop
	nop
	bra.b	(*)+16

CASW_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CASW_START

*################################################################
* THIS MUST BE THE STATE OF THE INTEGER REGISTER FILE UPON	#
* CALLING _isp_cas_finish().					#
*								#
* D0 = destination[15:0] operand				#
* D1 = 'xxxxxx11 -> no reg update; 'xxxxxx00 -> update required	#
* D2 = xxxxxxxx							#
* D3 = xxxxxxxx							#
* D4 = compare[15:0] operand					#
* D5 = xxxxxxxx							#
* D6 = xxxxxxxx							#
* D7 = xxxxxxxx							#
* A0 = xxxxxxxx							#
* A1 = xxxxxxxx							#
* A2 = xxxxxxxx							#
* A3 = xxxxxxxx							#
* A4 = xxxxxxxx							#
* A5 = xxxxxxxx							#
* A6 = frame pointer						#
* A7 = stack pointer						#
*################################################################

casw_noupdate_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	sf	d1			* indicate no update was done
	bra.l	_isp_cas_finish

casw_update_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	st	d1			* indicate update was done
	bra.l	_isp_cas_finish

*###############

* there are two possible mis-aligned cases for longword cas. they
* are separated because the final write which asserts LOCKE* must
* be an aligned write.
casl:
	move.l	a0,a1			* make copy for plpaw1
	move.l	a0,a2			* make copy for plpaw2
	addq.l	#$3,a2			* plpaw2 points to end of longword

	move.l	a0,d1			* byte or word misaligned?
	btst	#$0,d1
	bne.w	casl2			* byte misaligned

	move.l	d2,d3			* d3 = update[15:0]
	swap	d2			* d2 = update[31:16]

* mask interrupts levels 0-6. save old mask value.
	move.w	sr,d7			* save current SR
	ori.w	#$0700,sr		* inhibit interrupts

* load the SFC and DFC with the appropriate mode.
	movec	sfc,d6			* save old SFC/DFC
	movec	d0,sfc			* load new sfc
	movec	d0,dfc			* load new dfc

* pre-load the operand ATC. no page faults should occur here because
* _real_lock_page() should have taken care of this.
	plpaw	(a1)			* load atc for ADDR
	plpaw	(a2)			* load atc for ADDR+3

* push the operand lines from the cache if they exist.
	cpushl	dc,(a1)			* push dirty data
	cpushl	dc,(a2)			* push dirty data

* load the BUSCR values.
	move.l	#$80000000,a1		* assert LOCK* buscr value
	move.l	#$a0000000,a2		* assert LOCKE* buscr value
	move.l	#$00000000,a3		* buscr unlock value

	bra.b	CASL_ENTER		* start pre-loading icache

*
* D0 = dst operand <-
* D1 = xxxxxxxx
* D2 = update[31:16] operand
* D3 = update[15:0]  operand
* D4 = compare[31:0] operand
* D5 = xxxxxxxx
* D6 = old SFC/DFC
* D7 = old SR
* A0 = ADDR
* A1 = bus LOCK*  value
* A2 = bus LOCKE* value
* A3 = bus unlock value
* A4 = xxxxxxxx
* A5 = xxxxxxxx
*
	align	$10,$51FC
CASL_START:
	movec	a1,buscr		* assert LOCK*
	moves.l	(a0),d0			* fetch Dest[31:0]
	cmp.l	d4,d0			* Dest - Compare
	bne.b	CASL_NOUPDATE
	bra.b	CASL_UPDATE
CASL_ENTER:
	bra.b	(*)+16

CASL_UPDATE:
	moves.w	d2,(a0)+		* Update[31:16] -> DEST
	movec	a2,buscr		* assert LOCKE*
	moves.w	d3,(a0)			* Update[15:0] -> DEST+0x2
	bra.b	CASL_UPDATE2
	bra.b	(*)+16

CASL_UPDATE2:
	movec	a3,buscr		* unlock the bus
	bra.b	casl_update_done
	nop
	nop
	nop
	nop
	bra.b	(*)+16

CASL_NOUPDATE:
	swap	d0			* get Dest[31:16]
	moves.w	d0,(a0)+		* Dest[31:16] -> DEST
	swap	d0			* get Dest[15:0]
	movec	a2,buscr		* assert LOCKE*
	bra.b	CASL_NOUPDATE2
	bra.b	(*)+16

CASL_NOUPDATE2:
	moves.w	d0,(a0)			* Dest[15:0] -> DEST+0x2
	movec	a3,buscr		* unlock the bus
	bra.b	casl_noupdate_done
	nop
	nop
	bra.b	(*)+16

CASL_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CASL_START

*################################################################
* THIS MUST BE THE STATE OF THE INTEGER REGISTER FILE UPON	#
* CALLING _isp_cas_finish().					#
*								#
* D0 = destination[31:0] operand				#
* D1 = 'xxxxxx11 -> no reg update; 'xxxxxx00 -> update required	#
* D2 = xxxxxxxx							#
* D3 = xxxxxxxx							#
* D4 = compare[31:0] operand					#
* D5 = xxxxxxxx							#
* D6 = xxxxxxxx							#
* D7 = xxxxxxxx							#
* A0 = xxxxxxxx							#
* A1 = xxxxxxxx							#
* A2 = xxxxxxxx							#
* A3 = xxxxxxxx							#
* A4 = xxxxxxxx							#
* A5 = xxxxxxxx							#
* A6 = frame pointer						#
* A7 = stack pointer						#
*################################################################

casl_noupdate_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupt mask level.
	move.w	d7,sr			* restore old SR

	sf	d1			* indicate no update was done
	bra.l	_isp_cas_finish

casl_update_done:

* restore previous SFC/DFC value.
	movec	d6,sfc			* restore old SFC
	movec	d6,dfc			* restore old DFC

* restore previous interrupts mask level.
	move.w	d7,sr			* restore old SR

	st	d1			* indicate update was done
	bra.l	_isp_cas_finish

*######################################
casl2:
	move.l	d2,d5			* d5 = Update[7:0]
	lsr.l	#$8,d2
	move.l	d2,d3			* d3 = Update[23:8]
	swap	d2			* d2 = Update[31:24]

* mask interrupts levels 0-6. save old mask value.
	move.w	sr,d7			* save current SR
	ori.w	#$0700,sr		* inhibit interrupts

* load the SFC and DFC with the appropriate mode.
	movec	sfc,d6			* save old SFC/DFC
	movec	d0,sfc			* load new sfc
	movec	d0,dfc			* load new dfc

* pre-load the operand ATC. no page faults should occur here because
* _real_lock_page() should have taken care of this already.
	plpaw	(a1)			* load atc for ADDR
	plpaw	(a2)			* load atc for ADDR+3

* puch the operand lines from the cache if they exist.
	cpushl	dc,(a1)			* push dirty data
	cpushl	dc,(a2)			* push dirty data

* load the BUSCR values.
	move.l	#$80000000,a1		* assert LOCK* buscr value
	move.l	#$a0000000,a2		* assert LOCKE* buscr value
	move.l	#$00000000,a3		* buscr unlock value

* pre-load the instruction cache for the following algorithm. 
* this will minimize the number of cycles that LOCK* will be asserted.
	bra.b	CASL2_ENTER		* start pre-loading icache

*
* D0 = dst operand <-
* D1 = xxxxxxxx
* D2 = update[31:24] operand
* D3 = update[23:8]  operand
* D4 = compare[31:0] operand
* D5 = update[7:0]  operand
* D6 = old SFC/DFC
* D7 = old SR
* A0 = ADDR
* A1 = bus LOCK*  value
* A2 = bus LOCKE* value
* A3 = bus unlock value
* A4 = xxxxxxxx
* A5 = xxxxxxxx
*
	align	$10,$51FC
CASL2_START:
	movec	a1,buscr		* assert LOCK*
	moves.l	(a0),d0			* fetch Dest[31:0]
	cmp.l	d4,d0			* Dest - Compare
	bne.b	CASL2_NOUPDATE
	bra.b	CASL2_UPDATE
CASL2_ENTER:
	bra.b	(*)+16

CASL2_UPDATE:
	moves.b	d2,(a0)+		* Update[31:24] -> DEST
	moves.w	d3,(a0)+		* Update[23:8] -> DEST+0x1
	movec	a2,buscr		* assert LOCKE*
	bra.b	CASL2_UPDATE2
	bra.b	(*)+16

CASL2_UPDATE2:
	moves.b	d5,(a0)			* Update[7:0] -> DEST+0x3
	movec	a3,buscr		* unlock the bus
	bra.w	casl_update_done
	nop
	bra.b	(*)+16

CASL2_NOUPDATE:
	rol.l	#$8,d0			* get Dest[31:24]
	moves.b	d0,(a0)+		* Dest[31:24] -> DEST
	swap	d0			* get Dest[23:8]
	moves.w	d0,(a0)+		* Dest[23:8] -> DEST+0x1
	bra.b	CASL2_NOUPDATE2
	bra.b	(*)+16

CASL2_NOUPDATE2:
	rol.l	#$8,d0			* get Dest[7:0]
	movec	a2,buscr		* assert LOCKE*
	moves.b	d0,(a0)			* Dest[7:0] -> DEST+0x3
	bra.b	CASL2_NOUPDATE3
	nop
	bra.b	(*)+16

CASL2_NOUPDATE3:
	movec	a3,buscr		* unlock the bus
	bra.w	casl_noupdate_done
	nop
	nop
	nop
	bra.b	(*)+16

CASL2_FILLER:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bra.b	CASL2_START

*###
*###
* end label used by _isp_cas_inrange()
	global	_CASHI
_CASHI:


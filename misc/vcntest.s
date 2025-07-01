;========================================================================================
;  vcntest.s
;  Copyright (C) 2003-2019 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac
	.include	iocscall.mac

setrgb	.macro	rgb,sym
&sym = ((((rgb>>8).and.255)>>3)<<11).or.((((rgb>>16).and.255)>>3)<<6).or.(((rgb.and.255)>>3)<<1)
	.endm

	setrgb	$F0F8FF,ALICEBLUE
	setrgb	$FAEBD7,ANTIQUEWHITE
	setrgb	$00FFFF,AQUA
	setrgb	$7FFFD4,AQUAMARINE
	setrgb	$F0FFFF,AZURE
	setrgb	$F5F5DC,BEIGE
	setrgb	$FFE4C4,BISQUE
	setrgb	$000000,BLACK
	setrgb	$FFEBCD,BLANCHEDALMOND
	setrgb	$0000FF,BLUE
	setrgb	$8A2BE2,BLUEVIOLET
	setrgb	$A52A2A,BROWN
	setrgb	$DEB887,BURLYWOOD
	setrgb	$5F9EA0,CADETBLUE
	setrgb	$7FFF00,CHARTREUSE
	setrgb	$D2691E,CHOCOLATE
	setrgb	$FF7F50,CORAL
	setrgb	$6495ED,CORNFLOWERBLUE
	setrgb	$FFF8DC,CORNSILK
	setrgb	$DC143C,CRIMSON
	setrgb	$00FFFF,CYAN
	setrgb	$00008B,DARKBLUE
	setrgb	$008B8B,DARKCYAN
	setrgb	$B8860B,DARKGOLDENROD
	setrgb	$A9A9A9,DARKGRAY
	setrgb	$006400,DARKGREEN
	setrgb	$BDB76B,DARKKHAKI
	setrgb	$8B008B,DARKMAGENTA
	setrgb	$556B2F,DARKOLIVEGREEN
	setrgb	$FF8C00,DARKORANGE
	setrgb	$9932CC,DARKORCHID
	setrgb	$8B0000,DARKRED
	setrgb	$E9967A,DARKSALMON
	setrgb	$8FBC8F,DARKSEAGREEN
	setrgb	$483D8B,DARKSLATEBLUE
	setrgb	$2F4F4F,DARKSLATEGRAY
	setrgb	$00CED1,DARKTURQUOISE
	setrgb	$9400D3,DARKVIOLET
	setrgb	$FF1493,DEEPPINK
	setrgb	$00BFFF,DEEPSKYBLUE
	setrgb	$696969,DIMGRAY
	setrgb	$1E90FF,DODGERBLUE
	setrgb	$B22222,FIREBRICK
	setrgb	$FFFAF0,FLORALWHITE
	setrgb	$228B22,FORESTGREEN
	setrgb	$FF00FF,FUCHSIA
	setrgb	$DCDCDC,GAINSBORO
	setrgb	$F8F8FF,GHOSTWHITE
	setrgb	$FFD700,GOLD
	setrgb	$DAA520,GOLDENROD
	setrgb	$808080,GRAY
	setrgb	$008000,GREEN
	setrgb	$ADFF2F,GREENYELLOW
	setrgb	$F0FFF0,HONEYDEW
	setrgb	$FF69B4,HOTPINK
	setrgb	$CD5C5C,INDIANRED
	setrgb	$4B0082,INDIGO
	setrgb	$FFFFF0,IVORY
	setrgb	$F0E68C,KHAKI
	setrgb	$E6E6FA,LAVENDER
	setrgb	$FFF0F5,LAVENDERBLUSH
	setrgb	$7CFC00,LAWNGREEN
	setrgb	$FFFACD,LEMONCHIFFON
	setrgb	$ADD8E6,LIGHTBLUE
	setrgb	$F08080,LIGHTCORAL
	setrgb	$E0FFFF,LIGHTCYAN
	setrgb	$FAFAD2,LIGHTGOLDENRODYELLOW
	setrgb	$90EE90,LIGHTGREEN
	setrgb	$D3D3D3,LIGHTGREY
	setrgb	$FFB6C1,LIGHTPINK
	setrgb	$FFA07A,LIGHTSALMON
	setrgb	$20B2AA,LIGHTSEAGREEN
	setrgb	$87CEFA,LIGHTSKYBLUE
	setrgb	$778899,LIGHTSLATEGRAY
	setrgb	$B0C4DE,LIGHTSTEELBLUE
	setrgb	$FFFFE0,LIGHTYELLOW
	setrgb	$00FF00,LIME
	setrgb	$32CD32,LIMEGREEN
	setrgb	$FAF0E6,LINEN
	setrgb	$FF00FF,MAGENTA
	setrgb	$800000,MAROON
	setrgb	$66CDAA,MEDIUMAQUAMARINE
	setrgb	$0000CD,MEDIUMBLUE
	setrgb	$BA55D3,MEDIUMORCHID
	setrgb	$9370DB,MEDIUMPURPLE
	setrgb	$3CB371,MEDIUMSEAGREEN
	setrgb	$7B68EE,MEDIUMSLATEBLUE
	setrgb	$00FA9A,MEDIUMSPRINGGREEN
	setrgb	$48D1CC,MEDIUMTURQUOISE
	setrgb	$C71585,MEDIUMVIOLETRED
	setrgb	$191970,MIDNIGHTBLUE
	setrgb	$F5FFFA,MINTCREAM
	setrgb	$FFE4E1,MISTYROSE
	setrgb	$FFE4B5,MOCCASIN
	setrgb	$FFDEAD,NAVAJOWHITE
	setrgb	$000080,NAVY
	setrgb	$FDF5E6,OLDLACE
	setrgb	$808000,OLIVE
	setrgb	$6B8E23,OLIVEDRAB
	setrgb	$FFA500,ORANGE
	setrgb	$FF4500,ORANGERED
	setrgb	$DA70D6,ORCHID
	setrgb	$EEE8AA,PALEGOLDENROD
	setrgb	$98FB98,PALEGREEN
	setrgb	$AFEEEE,PALETURQUOISE
	setrgb	$DB7093,PALEVIOLETRED
	setrgb	$FFEFD5,PAPAYAWHIP
	setrgb	$FFDAB9,PEACHPUFF
	setrgb	$CD853F,PERU
	setrgb	$FFC0CB,PINK
	setrgb	$DDA0DD,PLUM
	setrgb	$B0E0E6,POWDERBLUE
	setrgb	$800080,PURPLE
	setrgb	$FF0000,RED
	setrgb	$BC8F8F,ROSYBROWN
	setrgb	$4169E1,ROYALBLUE
	setrgb	$8B4513,SADDLEBROWN
	setrgb	$FA8072,SALMON
	setrgb	$F4A460,SANDYBROWN
	setrgb	$2E8B57,SEAGREEN
	setrgb	$FFF5EE,SEASHELL
	setrgb	$A0522D,SIENNA
	setrgb	$C0C0C0,SILVER
	setrgb	$87CEEB,SKYBLUE
	setrgb	$6A5ACD,SLATEBLUE
	setrgb	$708090,SLATEGRAY
	setrgb	$FFFAFA,SNOW
	setrgb	$00FF7F,SPRINGGREEN
	setrgb	$4682B4,STEELBLUE
	setrgb	$D2B48C,TAN
	setrgb	$008080,TEAL
	setrgb	$D8BFD8,THISTLE
	setrgb	$FF6347,TOMATO
	setrgb	$40E0D0,TURQUOISE
	setrgb	$EE82EE,VIOLET
	setrgb	$F5DEB3,WHEAT
	setrgb	$FFFFFF,WHITE
	setrgb	$F5F5F5,WHITESMOKE
	setrgb	$FFFF00,YELLOW
	setrgb	$9ACD32,YELLOWGREEN

	setrgb	$000000,TRANSPARENT

	.text

	move.w	#3,-(sp)
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

	moveq.l	#0,d1		;software keyboard off
	moveq.l	#0,d2
	IOCS	_SKEY_MOD
	IOCS	_MS_INIT
	IOCS	_MS_CURON
loop:
	moveq.l	#16,d1
;	IOCS	_CRTMOD
	bsr	crtmod
	IOCS	_B_CUROFF

refresh:
	lea.l	menus,a2
@@:	movea.l	(a2)+,a1
	bsr	print_menu
	tst.l	(a2)
	bne	@b
	lea.l	menu_test,a1
	bsr	print_menu
	lea.l	menu_reset,a1
	bsr	print_menu
	lea.l	menu_exit,a1
	bsr	print_menu

update:
	bsr	calc_vcn4
	lea.l	regs_hex4_0,a1
	bsr	hex4
	bsr	calc_vcn5
	lea.l	regs_hex4_1,a1
	bsr	hex4
	bsr	calc_vcn6
	lea.l	regs_hex4_2,a1
	bsr	hex4
;		  louirb10
	moveq.l	#%00000001,d1	;italic cyan
	bsr	b_color
	moveq.l	#colregs,d1
	moveq.l	#rowregs,d2
	bsr	b_locate
	lea.l	string_regs,a1
	bsr	b_print

wait1:
	bsr	inkey
	cmp.w	#$011B,d0
	beq	abort
	tst.l	d0
	bne	draw
	IOCS	_MS_GETDT
	tst.b	d0		;right button
	bmi	abort
	tst.w	d0		;left button
	bpl	wait1
	IOCS	_MS_CURGT
	move.l	d0,d1
	move.l	d0,d2
	swap.w	d1
	ext.l	d1		;x
	ext.l	d2		;y
	divs.w	#6,d1
	divs.w	#6,d2
	ext.l	d1		;col
	ext.l	d2		;row

	lea.l	menus,a2
@@:	movea.l	(a2)+,a1
	bsr	select_menu
	bpl	update
	tst.l	(a2)
	bne	@b

	lea.l	menu_exit,a1
	bsr	select_menu
	bpl	abort

	lea.l	menu_reset,a1
	bsr	select_menu
	bmi	@f
;col0
	move.w	#0,menu_spprw
	move.w	#1,menu_txprw
	move.w	#2,menu_grprw
	move.w	#0,menu_gr1st
	move.w	#1,menu_gr2nd
	move.w	#2,menu_gr3rd
	move.w	#3,menu_gr4th
;col1
	move.w	#1,menu_spon
	move.w	#1,menu_txon
	move.w	#1,menu_gr1on
	move.w	#1,menu_gr2on
	move.w	#1,menu_gr3on
	move.w	#1,menu_gr4on
	move.w	#0,menu_grxon
;col2
	move.w	#0,menu_grmode
	move.w	#0,menu_ahon
	move.w	#0,menu_exon
	move.w	#1,menu_exarea
	move.w	#2,menu_extranslucent
;col3
	move.w	#0,menu_txtfill
	move.w	#3,menu_sprfill
	move.w	#0,menu_sprprw
	move.w	#5,menu_bg0fill
	move.w	#7,menu_bg1fill
;col4
	move.w	#0,menu_txpalet00
	move.w	#2,menu_txpalet01
	move.w	#1,menu_sppalet10
	move.w	#1,menu_sppalet11
	move.w	#1,menu_sppalet20
	move.w	#1,menu_sppalet21
	move.w	#1,menu_sppalet30
	move.w	#1,menu_sppalet31
	move.w	#0,menu_bg0on
	move.w	#0,menu_bg1on
;col5
	move.w	#0,menu_gr0fill
	move.w	#0,menu_gr1fill
	move.w	#0,menu_gr2fill
	move.w	#0,menu_gr3fill
;col6
	move.w	#0,menu_grpalet0000
	move.w	#2,menu_grpalet0001
	move.w	#0,menu_grpalet0002
	move.w	#0,menu_grpalet0003
	move.w	#0,menu_grpalet0004
	move.w	#0,menu_grpalet0005
	move.w	#0,menu_grpalet0006
	move.w	#0,menu_grpalet0007
	move.w	#0,menu_grpalet0010
	move.w	#0,menu_grpalet0011
	move.w	#0,menu_grpalet2020
	move.w	#0,menu_grpalet2121

	bra	refresh
@@:

	lea.l	menu_test,a1
	bsr	select_menu
	bmi	wait1
draw:

	move.w	menu_grmode,d0
	add.w	d0,d0
	lea.l	grmode_to_crtmod,a0
	move.w	(a0,d0.w),d1
	IOCS	_CRTMOD
	IOCS	_B_CUROFF
	moveq.l	#0<<16|0,d1		;x,y
	IOCS	_MS_CURST
	IOCS	_G_CLR_ON
	IOCS	_SP_INIT
	IOCS	_SP_ON

	bsr	calc_vcn4
	IOCS	_G_MOD

	bsr	calc_vcn5
	IOCS	_PRIORITY

	bsr	calc_vcn6
	IOCS	_CRTMOD2

;txtfill
  .if 0
;ROM 1.3 or IOCS.X needed
	move.w	#$FFFF,-(sp)	;line style
	move.w	#256,-(sp)	;height
	move.w	#256,-(sp)	;width
	move.w	#0,-(sp)	;y
	move.w	#0,-(sp)	;x
	move.w	menu_txtfill,-(sp)	;plane select
	ori.w	#$8000,(sp)	;multiple plane mode
	movea.l	sp,a1
	IOCS	_TXFILL
	lea.l	12(sp),sp
  .else
	moveq.l	#3,d1
1:	move.w	menu_txtfill,d0	;plane select
	btst.l	d1,d0
	beq	2f
	move.w	#$FFFF,-(sp)	;line style
	move.w	#256,-(sp)	;height
	move.w	#256,-(sp)	;width
	move.w	#0,-(sp)	;y
	move.w	#0,-(sp)	;x
	move.w	d1,-(sp)	;plane select
	movea.l	sp,a1
	IOCS	_TXFILL
	lea.l	12(sp),sp
2:	dbra	d1,1b
  .endif

;sprfill
	move.l	#1,d1		;pattern number 1
	move.l	#1,d2		;size 16x16
	moveq.l	#1,d0
	and.w	menu_sprfill,d0	;palet code
	lsl.w	#2,d0
	lea.l	sp_pats,a1
	movea.l	(a1,d0.w),a1	;pattern
	IOCS	_SP_DEFCG
	moveq.l	#0,d0
	move.w	menu_sprfill,d0
	lsr.w	#1,d0		;palet block
	lsl.w	#8,d0
	move.b	#1,d0		;pattern number 1
	movea.l	d0,a4		;palet block,pattern number 1
	moveq.l	#0,d0
	move.w	menu_sprprw,d0
	movea.l	d0,a5		;priority
	movea.l	#1<<31|64,a1	;ignore vsync 1,sprite number 64..127
	movea.l	#16+16*4,a3	;y
3:	movea.l	#16+16*4,a2	;x
2:	move.l	a1,d1		;ignore vsync 1,sprite number 64..127
	move.l	a2,d2		;x
	move.l	a3,d3		;y
	move.l	a4,d4		;palet block,pattern number 1
	move.l	a5,d5		;priority
	IOCS	_SP_REGST
	addq.l	#1,a1		;ignore vsync 1,sprite number 64..127
	adda.l	#16,a2		;x
	cmpa.l	#16+16*12,a2
	blo	2b
	adda.l	#16,a3		;y
	cmpa.l	#16+16*12,a3
	blo	3b

;bg0fill
	tst.w	menu_bg0on
	bne	1f
	move.l	#0,d1		;BG page number 0
	move.l	#0,d2		;BG text area 0
	move.l	#0,d3		;off
	IOCS	_BGCTRLST
	bra	2f
1:	move.l	#0,d1		;BG page number 0
	move.l	#0,d2		;BG text area 0
	move.l	#1,d3		;on
	IOCS	_BGCTRLST
	move.l	#2,d1		;pattern number 2
	move.l	#0,d2		;size 8x8
	moveq.l	#1,d0
	and.w	menu_bg0fill,d0	;palet code
	lsl.w	#2,d0
	lea.l	sp_pats,a1
	movea.l	(a1,d0.w),a1	;pattern
	IOCS	_SP_DEFCG
	move.l	#0,d1		;BG text area 0
	moveq.l	#0,d0
	move.w	menu_bg0fill,d0
	lsr.w	#1,d0		;palet block
	lsl.w	#8,d0
	move.b	#2,d0		;palet block,pattern number 2
	or.w	#0<<15|0<<14,d0	;hrev 0,vrev 0,palet block,pattern number 2
	move.l	d0,d2		;hrev 0,vrev 0,palet block,pattern number 2
	IOCS	_BGTEXTCL
2:

;bg1fill
	tst.w	menu_bg1on
	bne	1f
	move.l	#1,d1		;BG page number 1
	move.l	#1,d2		;BG text area 1
	move.l	#0,d3		;off
	IOCS	_BGCTRLST
	bra	2f
1:	move.l	#1,d1		;BG page number 1
	move.l	#1,d2		;BG text area 1
	move.l	#1,d3		;on
	IOCS	_BGCTRLST
	move.l	#3,d1		;pattern number 3
	move.l	#0,d2		;size 8x8
	moveq.l	#1,d0
	and.w	menu_bg1fill,d0	;palet code
	lsl.w	#2,d0
	lea.l	sp_pats,a1
	movea.l	(a1,d0.w),a1	;pattern
	IOCS	_SP_DEFCG
	move.l	#1,d1		;BG text area 1
	moveq.l	#0,d0
	move.w	menu_bg1fill,d0
	lsr.w	#1,d0		;palet block
	lsl.w	#8,d0
	move.b	#3,d0		;palet block,pattern number 3
	or.w	#0<<15|0<<14,d0	;hrev 0,vrev 0,palet block,pattern number 3
	move.l	d0,d2		;hrev 0,vrev 0,palet block,pattern number 3
	IOCS	_BGTEXTCL
2:

;txpalet00
	move.l	#0,d1		;palet code 0
	move.w	menu_txpalet00,d0
	add.w	d0,d0
	lea.l	txpalet00_to_color,a0
	move.w	(a0,d0.w),d2			;color code
	IOCS	_TPALET2

;txpalet01
	move.l	#1,d1		;palet code 1
	move.w	menu_txpalet01,d0
	add.w	d0,d0
	lea.l	txpalet01_to_color,a0
	move.w	(a0,d0.w),d2			;color code
	IOCS	_TPALET2

;sppalet10
	move.l	#1<<31|1<<4|0,d1	;ignore vsync 1,palet block 1,palet code 0
	move.l	#0,d2		;palet block is specified by d1
	move.w	menu_sppalet10,d0
	add.w	d0,d0
	lea.l	sppalet10_to_color,a0
	move.w	(a0,d0.w),d3			;color code
	IOCS	_SPALET

;sppalet11
	move.l	#1<<31|1<<4|1,d1	;ignore vsync 1,palet block 1,palet code 1
	move.l	#0,d2		;palet block is specified by d1
	move.w	menu_sppalet11,d0
	add.w	d0,d0
	lea.l	sppalet11_to_color,a0
	move.w	(a0,d0.w),d3			;color code
	IOCS	_SPALET

;sppalet20
	move.l	#1<<31|2<<4|0,d1	;ignore vsync 1,palet block 2,palet code 0
	move.l	#0,d2		;palet block is specified by d1
	move.w	menu_sppalet20,d0
	add.w	d0,d0
	lea.l	sppalet20_to_color,a0
	move.w	(a0,d0.w),d3			;color code
	IOCS	_SPALET

;sppalet21
	move.l	#1<<31|2<<4|1,d1	;ignore vsync 1,palet block 2,palet code 1
	move.l	#0,d2		;palet block is specified by d1
	move.w	menu_sppalet21,d0
	add.w	d0,d0
	lea.l	sppalet21_to_color,a0
	move.w	(a0,d0.w),d3			;color code
	IOCS	_SPALET

;sppalet30
	move.l	#1<<31|3<<4|0,d1	;ignore vsync 1,palet block 3,palet code 0
	move.l	#0,d2		;palet block is specified by d1
	move.w	menu_sppalet30,d0
	add.w	d0,d0
	lea.l	sppalet30_to_color,a0
	move.w	(a0,d0.w),d3			;color code
	IOCS	_SPALET

;sppalet31
	move.l	#1<<31|3<<4|1,d1	;ignore vsync 1,palet block 3,palet code 1
	move.l	#0,d2		;palet block is specified by d1
	move.w	menu_sppalet31,d0
	add.w	d0,d0
	lea.l	sppalet31_to_color,a0
	move.w	(a0,d0.w),d3			;color code
	IOCS	_SPALET

;gr0fill
	moveq.l	#0,d1
	IOCS	_APAGE
	tst.l	d0
	bmi	@f
	move.w	menu_gr0fill,d0
	add.w	d0,d0
	lea.l	gr0fill_to_palet,a0
	move.w	(a0,d0.w),-(sp)	;palet code
	move.w	#256-1,-(sp)	;y2
	move.w	#256-1,-(sp)	;x2
	move.w	#0,-(sp)	;y1
	move.w	#0,-(sp)	;x1
	movea.l	sp,a1
	IOCS	_FILL
	lea.l	10(sp),sp
@@:

;gr1fill
	moveq.l	#1,d1
	IOCS	_APAGE
	tst.l	d0
	bmi	@f
	move.w	menu_gr1fill,d0
	add.w	d0,d0
	lea.l	gr1fill_to_palet,a0
	move.w	(a0,d0.w),-(sp)	;palet code
	move.w	#256-1,-(sp)	;y2
	move.w	#256-1,-(sp)	;x2
	move.w	#0,-(sp)	;y1
	move.w	#0,-(sp)	;x1
	movea.l	sp,a1
	IOCS	_FILL
	lea.l	10(sp),sp
@@:

;gr2fill
	moveq.l	#2,d1
	IOCS	_APAGE
	tst.l	d0
	bmi	@f
	move.w	menu_gr2fill,d0
	add.w	d0,d0
	lea.l	gr2fill_to_palet,a0
	move.w	(a0,d0.w),-(sp)	;palet code
	move.w	#256-1,-(sp)	;y2
	move.w	#256-1,-(sp)	;x2
	move.w	#0,-(sp)	;y1
	move.w	#0,-(sp)	;x1
	movea.l	sp,a1
	IOCS	_FILL
	lea.l	10(sp),sp
@@:

;gr3fill
	moveq.l	#3,d1
	IOCS	_APAGE
	tst.l	d0
	bmi	@f
	move.w	menu_gr3fill,d0
	add.w	d0,d0
	lea.l	gr3fill_to_palet,a0
	move.w	(a0,d0.w),-(sp)	;palet code
	move.w	#256-1,-(sp)	;y2
	move.w	#256-1,-(sp)	;x2
	move.w	#0,-(sp)	;y1
	move.w	#0,-(sp)	;x1
	movea.l	sp,a1
	IOCS	_FILL
	lea.l	10(sp),sp
@@:

;grpalet0000
	move.l	#0,d1			;palet code
	move.w	menu_grpalet0000,d0
	add.w	d0,d0
	lea.l	grpalet0000_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0001
	move.l	#1,d1			;palet code
	move.w	menu_grpalet0001,d0
	add.w	d0,d0
	lea.l	grpalet0001_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0002
	move.l	#2,d1			;palet code
	move.w	menu_grpalet0002,d0
	add.w	d0,d0
	lea.l	grpalet0002_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0003
	move.l	#3,d1			;palet code
	move.w	menu_grpalet0003,d0
	add.w	d0,d0
	lea.l	grpalet0003_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0004
	move.l	#4,d1			;palet code
	move.w	menu_grpalet0004,d0
	add.w	d0,d0
	lea.l	grpalet0004_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0005
	move.l	#5,d1			;palet code
	move.w	menu_grpalet0005,d0
	add.w	d0,d0
	lea.l	grpalet0005_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0006
	move.l	#6,d1			;palet code
	move.w	menu_grpalet0006,d0
	add.w	d0,d0
	lea.l	grpalet0006_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0007
	move.l	#7,d1			;palet code
	move.w	menu_grpalet0007,d0
	add.w	d0,d0
	lea.l	grpalet0007_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0010
	move.l	#$10,d1			;palet code
	move.w	menu_grpalet0010,d0
	add.w	d0,d0
	lea.l	grpalet0010_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet0011
	move.l	#$11,d1			;palet code
	move.w	menu_grpalet0011,d0
	add.w	d0,d0
	lea.l	grpalet0011_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet2020
	move.w	#$2020,d1		;palet code
	move.w	menu_grpalet2020,d0
	add.w	d0,d0
	lea.l	grpalet2020_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

;grpalet2121
	move.w	#$2121,d1		;palet code
	move.w	menu_grpalet2121,d0
	add.w	d0,d0
	lea.l	grpalet2121_to_color,a0
	move.w	(a0,d0.w),d2		;color code
	IOCS	_GPALET

wait2:
	bsr	inkey
	cmp.w	#$011B,d0
	beq	abort
	tst.l	d0
	bne	loop
	IOCS	_MS_GETDT
	tst.b	d0		;right button
	bmi	abort
	tst.w	d0		;left button
	bpl	wait2
@@:	IOCS	_MS_GETDT
	tst.w	d0		;left button
	bmi	@b
	bra	loop

abort:
	IOCS	_MS_CUROF
	moveq.l	#16,d1
;	IOCS	_CRTMOD
	bsr	crtmod
	moveq.l	#-1,d1		;software keyboard auto
	moveq.l	#0,d2
	IOCS	_SKEY_MOD

	clr.w	-(sp)
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

	DOS	_EXIT

calc_vcn4:
	movem.l	d0/a0,-(sp)
	moveq.l	#0,d1

	move.w	menu_grmode,d0
	add.w	d0,d0
	lea.l	grmode_to_vcn4,a0
	or.w	(a0,d0.w),d1

	movem.l	(sp)+,d0/a0
	rts

calc_vcn5:
	movem.l	d0/a0,-(sp)
	moveq.l	#0,d1

	move.w	menu_spprw,d0
	add.w	d0,d0
	lea.l	spprw_to_vcn5,a0
	or.w	(a0,d0.w),d1

	move.w	menu_txprw,d0
	add.w	d0,d0
	lea.l	txprw_to_vcn5,a0
	or.w	(a0,d0.w),d1

	move.w	menu_grprw,d0
	add.w	d0,d0
	lea.l	grprw_to_vcn5,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr1st,d0
	add.w	d0,d0
	lea.l	gr1st_to_vcn5,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr2nd,d0
	add.w	d0,d0
	lea.l	gr2nd_to_vcn5,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr3rd,d0
	add.w	d0,d0
	lea.l	gr3rd_to_vcn5,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr4th,d0
	add.w	d0,d0
	lea.l	gr4th_to_vcn5,a0
	or.w	(a0,d0.w),d1

	movem.l	(sp)+,d0/a0
	rts

calc_vcn6:
	movem.l	d0/a0,-(sp)
	moveq.l	#0,d1

	move.w	menu_spon,d0
	add.w	d0,d0
	lea.l	spon_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_txon,d0
	add.w	d0,d0
	lea.l	txon_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr1on,d0
	add.w	d0,d0
	lea.l	gr1on_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr2on,d0
	add.w	d0,d0
	lea.l	gr2on_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr3on,d0
	add.w	d0,d0
	lea.l	gr3on_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_gr4on,d0
	add.w	d0,d0
	lea.l	gr4on_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_grxon,d0
	add.w	d0,d0
	lea.l	grxon_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_ahon,d0
	add.w	d0,d0
	lea.l	ahon_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_exon,d0
	add.w	d0,d0
	lea.l	exon_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_exarea,d0
	add.w	d0,d0
	lea.l	exarea_to_vcn6,a0
	or.w	(a0,d0.w),d1

	move.w	menu_extranslucent,d0
	add.w	d0,d0
	lea.l	extranslucent_to_vcn6,a0
	or.w	(a0,d0.w),d1

9:

	movem.l	(sp)+,d0/a0
	rts

;<d1.w:number
;<a1.l:buffer
hex4:
	movem.l	d0/d2,-(sp)
	moveq.l	#4-1,d2
2:	rol.w	#4,d1
	moveq.l	#$0F,d0
	and.b	d1,d0
	cmp.b	#10,d0
	blo	@f
	addq.b	#7,d0
@@:	add.b	#'0',d0
	move.b	d0,(a1)+
	dbra	d2,2b
	movem.l	(sp)+,d0/d2
	rts

inkey:
	movem.l	d1,-(sp)
	moveq.l	#0,d1
	bra	2f
1:	IOCS	_B_KEYINP
	move.l	d0,d1
2:	IOCS	_B_KEYSNS
	tst.l	d0
	bne	1b
	move.l	d1,d0
	movem.l	(sp)+,d1
	rts

;<d1.w:col
;<d2.w:row=row0+2*value
;<a1.l:menu
;	0.w	current
;	4.w	col0
;	6.w	row0
;	8.w	cols
;	10.w	values
;>d0.w:value
select_menu:
	moveq.l	#0,d0
	move.w	d1,d0
	sub.w	4(a1),d0	;col0
	blo	8f
	cmp.w	8(a1),d0	;cols
	bhs	8f
	move.w	d2,d0		;row0+2*value
	sub.w	6(a1),d0	;row0
				;2*value
	blo	8f
	lsr.w	#1,d0		;2*value/2=value
	cmp.w	10(a1),d0	;value-values
	bhs	8f
	move.w	d0,(a1)		;current
	bsr	print_menu
9:	tst.l	d0
	rts
8:	moveq.l	#-1,d0
	bra	9b

;<a1.l:menu
;	0.w	current
;	4.w	col0
;	6.w	row0
;	8.w	cols
;	10.w	values
;	12.b[(cols+1)*rows]	texts
print_menu:
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	a1,a4

	moveq.l	#0,d6		;value
6:
	move.w	4(a4),d1	;col0
	move.w	6(a4),d2	;row0
	add.w	d6,d2
	add.w	d6,d2		;row0+2*value
;	IOCS	_B_LOCATE
	bsr	b_locate

	moveq.l	#%0011,d1	;white
	cmp.w	(a4),d6		;value-current
	bne	@f
;		  louirb10
	moveq.l	#%00010010,d1	;italic yellow
@@:
;	IOCS	_B_COLOR
	bsr	b_color

	move.w	8(a4),d0	;cols
	addq.w	#1,d0		;cols+1
	mulu.w	d6,d0		;(cols+1)*value
	lea.l	12(a4,d0.w),a1	;12+(cols+1)*value
;	IOCS	_B_PRINT
	bsr	b_print

	addq.w	#1,d6		;value
	cmp.w	10(a4),d6	;value-values
	blo	6b

;	moveq.l	#3,d1		;white
;	IOCS	_B_COLOR
;	IOCS	_B_CUROFF

	movem.l	(sp)+,d0-d7/a0-a6
	rts

waitkey:
	movem.l	d0,-(sp)
@@:	IOCS	_B_KEYSNS
	tst.l	d0
	beq	@b
	IOCS	_B_KEYINP
	movem.l	(sp)+,d0
	rts



;<d1.w:x
;<d2.w:y
b_locate:
	move.w	d1,cursor_x
	move.w	d2,cursor_y
	rts
cursor_x:
	.dc.w	0
cursor_y:
	.dc.w	0

;<d1.w:color
b_color:
	move.w	d1,text_color
	rts
text_color:
	.dc.w	%0011

;<a1.l:text
b_print:
	link.w	a6,#-76
	movem.l	d0-d3/a1-a2,-(sp)
	movea.l	a1,a2
1:	moveq.l	#6,d1		;6x12
	swap.w	d1
	move.b	(a2)+,d1	;character (ASCII only)
	beq	9f
	lea.l	-76(a6),a1	;pattern buffer
	IOCS	_FNTGET

	move.w	text_color,d3

	btst.l	#4,d3		;italic
	beq	@f
	lea.l	-76+4(a6),a1
  .rept 4
	move.b	(a1),d0
	lsr.b	#1,d0
	and.b	#$FC,d0
	or.b	d0,(a1)+
  .endm
	addq.l	#4,a1
  .rept 4
	move.b	(a1),d0
	add.b	d0,d0
	or.b	d0,(a1)+
  .endm
@@:

	btst.l	#2,d3		;bold
	beq	@f
	lea.l	-76+4(a6),a1
  .rept 12
	move.b	(a1),d0
	lsr.b	#1,d0
	and.b	#$FC,d0
	or.b	d0,(a1)+
  .endm
@@:

	btst.l	#5,d3		;underline
	beq	@f
	lea.l	-76+4(a6),a1
	move.b	#$FC,11(a1)
@@:

	btst.l	#6,d3		;overline
	beq	@f
	lea.l	-76+4(a6),a1
	move.b	#$FC,1(a1)
@@:

	btst.l	#7,d3		;line-through
	beq	@f
	lea.l	-76+4(a6),a1
	move.b	#$FC,6(a1)
@@:

	btst.l	#3,d3		;reverse
	beq	@f
	lea.l	-76+4(a6),a1
  .rept 12
	eori.b	#$FC,(a1)+
  .endm
@@:

	moveq.l	#%0001,d1	;plane 0
	IOCS	_TCOLOR
	move.w	cursor_x,d1
	mulu.w	#6,d1		;x
	move.w	cursor_y,d2
	mulu.w	#6,d2		;y
	lea.l	space(pc),a1
	btst.l	#0,d3		;plane 0
	beq	@f
	lea.l	-76(a6),a1	;pattern buffer
@@:	IOCS	_TEXTPUT

	moveq.l	#%0010,d1	;plane 1
	IOCS	_TCOLOR
	move.w	cursor_x,d1
	mulu.w	#6,d1		;x
	move.w	cursor_y,d2
	mulu.w	#6,d2		;y
	lea.l	space(pc),a1
	btst.l	#1,d3		;plane 1
	beq	@f
	lea.l	-76(a6),a1	;pattern buffer
@@:	IOCS	_TEXTPUT

	addq.w	#1,cursor_x
	bra	1b
9:	movem.l	(sp)+,d0-d3/a1-a2
	unlk	a6
	rts
space:
	.dc.w	6,12
	.dcb.b	12,$00

crtmod:
	movem.l	d0-d2/a1,-(sp)
	movea.l	#$0000093C,a1
	IOCS	_B_BPEEK
	cmp.b	d1,d0
	beq	1f
	IOCS	_CRTMOD
	bra	9f
1:	move.w	#$06E4,d1	;SP>TX>GR,G0>G1>G2>G3
	IOCS	_PRIORITY
	move.w	#$0020,d1	;TX
	IOCS	_CRTMOD2
	moveq.l	#3,d1
@@:	moveq.l	#-2,d2
	IOCS	_TPALET
	dbra	d1,@b
	IOCS	_B_CUROFF
  .if 0
    .if 0
;ROM 1.3 or IOCS.X needed
	move.w	#$0000,-(sp)	;line style
	move.w	#512,-(sp)	;height
	move.w	#768,-(sp)	;width
	move.w	#0,-(sp)	;y
	move.w	#0,-(sp)	;x
	move.w	#1<<15|%0011,-(sp)	;multiple plane mode,plane select
	movea.l	sp,a1
	IOCS	_TXFILL
	lea.l	12(sp),sp
    .else
	moveq.l	#3,d1
1:	move.w	#$0000,-(sp)	;line style
	move.w	#512,-(sp)	;height
	move.w	#768,-(sp)	;width
	move.w	#0,-(sp)	;y
	move.w	#0,-(sp)	;x
	move.w	d1,-(sp)	;plane select
	movea.l	sp,a1
	IOCS	_TXFILL
	lea.l	12(sp),sp
2:	dbra	d1,1b
    .endif
  .else
	moveq.l	#2,d1
	IOCS	_B_CLR_ST
  .endif
	moveq.l	#0,d1
	moveq.l	#0,d2
	IOCS	_B_LOCATE
9:	movem.l	(sp)+,d0-d2/a1
	rts



	.data

hgap=3
vgap=1

col0=(768/6-(8+hgap+8+hgap+17+hgap+11+hgap+17+hgap+13+hgap+19))>>1
col1=col0+8+hgap
col2=col1+8+hgap
col3=col2+17+hgap
col4=col3+11+hgap
col5=col4+17+hgap
col6=col5+13+hgap
;col7=col6+19+hgap

coltest=(768/6-(4+9+5+3+4))>>1
rowtest=1

colreset=coltest+4+9
rowreset=1

colexit=colreset+5+3
rowexit=1

row0=4
rowmax=row0+60

colregs=col1+1
rowregs=rowmax

	.even
menu_test:
	.dc.w	0,0
	.dc.w	coltest,rowtest,2f-1f-1,1
1:	.dc.b	'TEST',0
2:

	.even
menu_reset:
	.dc.w	0,0
	.dc.w	colreset,rowreset,2f-1f-1,1
1:	.dc.b	'RESET',0
2:

	.even
menu_exit:
	.dc.w	0,0
	.dc.w	colexit,rowexit,2f-1f-1,1
1:	.dc.b	'EXIT',0
2:

string_regs:
	.dc.b	'REGS: $'
regs_hex4_0:
	.dc.b	'xxxx'
	.dc.b	' $'
regs_hex4_1:
	.dc.b	'xxxx'
	.dc.b	' $'
regs_hex4_2:
	.dc.b	'xxxx',0

	.even
menus:
;col0
	.dc.l	menu_spprw
	.dc.l	menu_txprw
	.dc.l	menu_grprw
	.dc.l	menu_gr1st
	.dc.l	menu_gr2nd
	.dc.l	menu_gr3rd
	.dc.l	menu_gr4th
;col1
	.dc.l	menu_spon
	.dc.l	menu_txon
	.dc.l	menu_gr1on
	.dc.l	menu_gr2on
	.dc.l	menu_gr3on
	.dc.l	menu_gr4on
	.dc.l	menu_grxon
;col2
	.dc.l	menu_grmode
	.dc.l	menu_ahon
	.dc.l	menu_exon
	.dc.l	menu_exarea
	.dc.l	menu_extranslucent
;col3
	.dc.l	menu_txtfill
	.dc.l	menu_sprfill
	.dc.l	menu_sprprw
	.dc.l	menu_bg0fill
	.dc.l	menu_bg1fill
;col4
	.dc.l	menu_txpalet00
	.dc.l	menu_txpalet01
	.dc.l	menu_sppalet10
	.dc.l	menu_sppalet11
	.dc.l	menu_sppalet20
	.dc.l	menu_sppalet21
	.dc.l	menu_sppalet30
	.dc.l	menu_sppalet31
	.dc.l	menu_bg0on
	.dc.l	menu_bg1on
;col5
	.dc.l	menu_gr0fill
	.dc.l	menu_gr1fill
	.dc.l	menu_gr2fill
	.dc.l	menu_gr3fill
;col6
	.dc.l	menu_grpalet0000
	.dc.l	menu_grpalet0001
	.dc.l	menu_grpalet0002
	.dc.l	menu_grpalet0003
	.dc.l	menu_grpalet0004
	.dc.l	menu_grpalet0005
	.dc.l	menu_grpalet0006
	.dc.l	menu_grpalet0007
	.dc.l	menu_grpalet0010
	.dc.l	menu_grpalet0011
	.dc.l	menu_grpalet2020
	.dc.l	menu_grpalet2121

	.dc.l	0

col=col0
row=row0

	.even
menu_spprw:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP PRW 0',0
2:	.dc.b	'SP PRW 1',0
	.dc.b	'SP PRW 2',0
	.dc.b	'SP PRW 3',0
3:
	.even
spprw_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%01_00_00_00_00_00_00
	.dc.w	%10_00_00_00_00_00_00
	.dc.w	%11_00_00_00_00_00_00

	.even
menu_txprw:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'TX PRW 0',0
2:	.dc.b	'TX PRW 1',0
	.dc.b	'TX PRW 2',0
	.dc.b	'TX PRW 3',0
3:
	.even
txprw_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%00_01_00_00_00_00_00
	.dc.w	%00_10_00_00_00_00_00
	.dc.w	%00_11_00_00_00_00_00

	.even
menu_grprw:
	.dc.w	2,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR PRW 0',0
2:	.dc.b	'GR PRW 1',0
	.dc.b	'GR PRW 2',0
	.dc.b	'GR PRW 3',0
3:
	.even
grprw_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%00_00_01_00_00_00_00
	.dc.w	%00_00_10_00_00_00_00
	.dc.w	%00_00_11_00_00_00_00

	.even
menu_gr1st:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 1ST 0',0
2:	.dc.b	'GR 1ST 1',0
	.dc.b	'GR 1ST 2',0
	.dc.b	'GR 1ST 3',0
3:
	.even
gr1st_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%00_00_00_00_00_00_01
	.dc.w	%00_00_00_00_00_00_10
	.dc.w	%00_00_00_00_00_00_11

	.even
menu_gr2nd:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 2ND 0',0
2:	.dc.b	'GR 2ND 1',0
	.dc.b	'GR 2ND 2',0
	.dc.b	'GR 2ND 3',0
3:
	.even
gr2nd_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%00_00_00_00_00_01_00
	.dc.w	%00_00_00_00_00_10_00
	.dc.w	%00_00_00_00_00_11_00

	.even
menu_gr3rd:
	.dc.w	2,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 3RD 0',0
2:	.dc.b	'GR 3RD 1',0
	.dc.b	'GR 3RD 2',0
	.dc.b	'GR 3RD 3',0
3:
	.even
gr3rd_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%00_00_00_00_01_00_00
	.dc.w	%00_00_00_00_10_00_00
	.dc.w	%00_00_00_00_11_00_00

	.even
menu_gr4th:
	.dc.w	3,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 4TH 0',0
2:	.dc.b	'GR 4TH 1',0
	.dc.b	'GR 4TH 2',0
	.dc.b	'GR 4TH 3',0
3:
	.even
gr4th_to_vcn5:
;		 SpwTpwGpw4th3rd2nd1st
	.dc.w	%00_00_00_00_00_00_00
	.dc.w	%00_00_00_01_00_00_00
	.dc.w	%00_00_00_10_00_00_00
	.dc.w	%00_00_00_11_00_00_00

col=col1
row=row0

	.even
menu_spon:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP OFF',0
2:	.dc.b	'SP ON ',0
3:
	.even
spon_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;TX OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__1__0__0__0__0__0__0	;SP ON

	.even
menu_txon:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'TX OFF',0
2:	.dc.b	'TX ON ',0
3:
	.even
txon_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;TX OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__1__0__0__0__0__0	;TX ON

	.even
menu_gr1on:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'1ST OFF',0
2:	.dc.b	'1ST ON ',0
3:
	.even
gr1on_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;1ST OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__1	;1ST ON

	.even
menu_gr2on:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'2ND OFF',0
2:	.dc.b	'2ND ON ',0
3:
	.even
gr2on_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;2ND OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__1__0	;2ND ON

	.even
menu_gr3on:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'3RD OFF',0
2:	.dc.b	'3RD ON ',0
3:
	.even
gr3on_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;3RD OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__1__0__0	;3RD ON

	.even
menu_gr4on:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'4TH OFF',0
2:	.dc.b	'4TH ON ',0
3:
	.even
gr4on_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;4TH OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__1__0__0__0	;4TH ON

	.even
menu_grxon:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'1024 OFF',0
2:	.dc.b	'1024 ON ',0
3:
	.even
grxon_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;1024 OFF
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__1__0__0__0__0	;1024 ON

col=col2
row=row0

	.even
menu_grmode:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	' 512 x    16 x 4',0
2:	.dc.b	' 512 x   256 x 2',0
	.dc.b	' 512 x 65536 x 1',0
	.dc.b	'1024 x    16 x 1',0
3:
	.even
grmode_to_crtmod:
	.dc.w	6	; 512 x    16 x 4
	.dc.w	10	; 512 x   256 x 2
	.dc.w	14	; 512 x 65536 x 1
	.dc.w	2	;1024 x    16 x 1
	.even
grmode_to_vcn4:
	.dc.w	%0_00	; 512 x    16 x 4
	.dc.w	%0_01	; 512 x   256 x 2
	.dc.w	%0_11	; 512 x 65536 x 1
	.dc.w	%1_00	;1024 x    16 x 1

	.even
menu_ahon:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'NORMAL  ',0
2:	.dc.b	'GR+TX 00',0
3:
	.even
ahon_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;
	.dc.w	%_0__1__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;A

	.even
menu_exon:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'NORMAL          ',0
2:	.dc.b	'SPECIAL PRIORITY',0
	.dc.b	'TRANSLUCENT     ',0
3:
	.even
exon_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;
	.dc.w	%_0__0__0__1__0__0__0__0__0__0__0__0__0__0__0__0	;X
	.dc.w	%_0__0__0__1__1__0__0__0__0__0__0__0__0__0__0__0	;XH

	.even
menu_exarea:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'LSB OF COLOR CODE',0
2:	.dc.b	'LSB OF PALET CODE',0
3:
	.even
exarea_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;W
	.dc.w	%_0__0__0__0__0__1__0__0__0__0__0__0__0__0__0__0	;P

	.even
menu_extranslucent:
	.dc.w	2,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'1ST          ',0
2:	.dc.b	'1ST+SP/TX    ',0
	.dc.b	'1ST+2ND      ',0
	.dc.b	'1ST+2ND+SP/TX',0
3:
	.even
extranslucent_to_vcn6:
;		 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
;		 YS AH VH EX HF PL GG GT BC SP TX GX G4 G3 G2 G1
	.dc.w	%_0__0__0__0__0__0__0__0__0__0__0__0__0__0__0__0	;
	.dc.w	%_0__0__0__0__0__0__0__1__0__0__0__0__0__0__0__0	;T
	.dc.w	%_0__0__0__0__0__0__1__0__0__0__0__0__0__0__0__0	;G
	.dc.w	%_0__0__0__0__0__0__1__1__0__0__0__0__0__0__0__0	;GT

col=col3
row=row0

	.even
menu_txtfill:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'TXT FILL 00',0
2:	.dc.b	'TXT FILL 01',0
3:

	.even
menu_sprfill:
	.dc.w	3,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SPR FILL 00',0
2:	.dc.b	'SPR FILL 01',0
	.dc.b	'SPR FILL 10',0
	.dc.b	'SPR FILL 11',0
	.dc.b	'SPR FILL 20',0
	.dc.b	'SPR FILL 21',0
	.dc.b	'SPR FILL 30',0
	.dc.b	'SPR FILL 31',0
3:

	.even
menu_sprprw:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SPR PRW 0',0
2:	.dc.b	'SPR PRW 1',0
	.dc.b	'SPR PRW 2',0
	.dc.b	'SPR PRW 3',0
3:

	.even
menu_bg0fill:
	.dc.w	5,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'BG0 FILL 00',0
2:	.dc.b	'BG0 FILL 01',0
	.dc.b	'BG0 FILL 10',0
	.dc.b	'BG0 FILL 11',0
	.dc.b	'BG0 FILL 20',0
	.dc.b	'BG0 FILL 21',0
	.dc.b	'BG0 FILL 30',0
	.dc.b	'BG0 FILL 31',0
3:

	.even
menu_bg1fill:
	.dc.w	7,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'BG1 FILL 00',0
2:	.dc.b	'BG1 FILL 01',0
	.dc.b	'BG1 FILL 10',0
	.dc.b	'BG1 FILL 11',0
	.dc.b	'BG1 FILL 20',0
	.dc.b	'BG1 FILL 21',0
	.dc.b	'BG1 FILL 30',0
	.dc.b	'BG1 FILL 31',0
3:

col=col4
row=row0

	.even
menu_txpalet00:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'TX 00 TRANSPARENT',0
2:	.dc.b	'TX 00 BLACK+1    ',0
	.dc.b	'TX 00 GRAY       ',0
	.dc.b	'TX 00 SILVER     ',0
	.dc.b	'TX 00 WHITE      ',0
3:
	.even
txpalet00_to_color:
	.dc.w	TRANSPARENT
	.dc.w	BLACK+1
	.dc.w	GRAY
	.dc.w	SILVER
	.dc.w	WHITE

	.even
menu_txpalet01:
	.dc.w	2,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'TX 01 TRANSPARENT',0
2:	.dc.b	'TX 01 BLACK+1    ',0
	.dc.b	'TX 01 ORANGE     ',0
3:
	.even
txpalet01_to_color:
	.dc.w	TRANSPARENT
	.dc.w	BLACK+1
	.dc.w	ORANGE

	.even
menu_sppalet10:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP 10 TRANSPARENT',0
2:	.dc.b	'SP 10 PURPLE     ',0
3:
	.even
sppalet10_to_color:
	.dc.w	TRANSPARENT
	.dc.w	PURPLE

	.even
menu_sppalet11:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP 11 TRANSPARENT',0
2:	.dc.b	'SP 11 FUCHSIA    ',0
3:
	.even
sppalet11_to_color:
	.dc.w	TRANSPARENT
	.dc.w	FUCHSIA

	.even
menu_sppalet20:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP 20 TRANSPARENT',0
2:	.dc.b	'SP 20 TEAL       ',0
3:
	.even
sppalet20_to_color:
	.dc.w	TRANSPARENT
	.dc.w	TEAL

	.even
menu_sppalet21:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP 21 TRANSPARENT',0
2:	.dc.b	'SP 21 AQUA       ',0
3:
	.even
sppalet21_to_color:
	.dc.w	TRANSPARENT
	.dc.w	AQUA

	.even
menu_sppalet30:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP 30 TRANSPARENT',0
2:	.dc.b	'SP 30 OLIVE      ',0
3:
	.even
sppalet30_to_color:
	.dc.w	TRANSPARENT
	.dc.w	OLIVE

	.even
menu_sppalet31:
	.dc.w	1,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'SP 31 TRANSPARENT',0
2:	.dc.b	'SP 31 YELLOW     ',0
3:
	.even
sppalet31_to_color:
	.dc.w	TRANSPARENT
	.dc.w	YELLOW

	.even
menu_bg0on:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'BG0 OFF',0
2:	.dc.b	'BG0 ON ',0
3:

	.even
menu_bg1on:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'BG1 OFF',0
2:	.dc.b	'BG1 ON ',0
3:

col=col5
row=row0

	.even
menu_gr0fill:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR0 FILL 0000',0
2:	.dc.b	'GR0 FILL 0001',0
	.dc.b	'GR0 FILL 0002',0
	.dc.b	'GR0 FILL 0003',0
	.dc.b	'GR0 FILL 0004',0
	.dc.b	'GR0 FILL 0005',0
	.dc.b	'GR0 FILL 0006',0
	.dc.b	'GR0 FILL 0007',0
	.dc.b	'GR0 FILL 0010',0
	.dc.b	'GR0 FILL 0011',0
	.dc.b	'GR0 FILL 2020',0
	.dc.b	'GR0 FILL 2121',0
3:
	.even
gr0fill_to_palet:
	.dc.w	$0000
	.dc.w	$0001
	.dc.w	$0002
	.dc.w	$0003
	.dc.w	$0004
	.dc.w	$0005
	.dc.w	$0006
	.dc.w	$0007
	.dc.w	$0010
	.dc.w	$0011
	.dc.w	$2020
	.dc.w	$2121

	.even
menu_gr1fill:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR1 FILL 0000',0
2:	.dc.b	'GR1 FILL 0001',0
	.dc.b	'GR1 FILL 0002',0
	.dc.b	'GR1 FILL 0003',0
	.dc.b	'GR1 FILL 0004',0
	.dc.b	'GR1 FILL 0005',0
	.dc.b	'GR1 FILL 0006',0
	.dc.b	'GR1 FILL 0007',0
	.dc.b	'GR1 FILL 0010',0
	.dc.b	'GR1 FILL 0011',0
3:
	.even
gr1fill_to_palet:
	.dc.w	$0000
	.dc.w	$0001
	.dc.w	$0002
	.dc.w	$0003
	.dc.w	$0004
	.dc.w	$0005
	.dc.w	$0006
	.dc.w	$0007
	.dc.w	$0010
	.dc.w	$0011

	.even
menu_gr2fill:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR2 FILL 0000',0
2:	.dc.b	'GR2 FILL 0001',0
	.dc.b	'GR2 FILL 0002',0
	.dc.b	'GR2 FILL 0003',0
	.dc.b	'GR2 FILL 0004',0
	.dc.b	'GR2 FILL 0005',0
3:
	.even
gr2fill_to_palet:
	.dc.w	$0000
	.dc.w	$0001
	.dc.w	$0002
	.dc.w	$0003
	.dc.w	$0004
	.dc.w	$0005

	.even
menu_gr3fill:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR3 FILL 0000',0
2:	.dc.b	'GR3 FILL 0001',0
	.dc.b	'GR3 FILL 0002',0
	.dc.b	'GR3 FILL 0003',0
	.dc.b	'GR3 FILL 0004',0
	.dc.b	'GR3 FILL 0005',0
3:
	.even
gr3fill_to_palet:
	.dc.w	$0000
	.dc.w	$0001
	.dc.w	$0002
	.dc.w	$0003
	.dc.w	$0004
	.dc.w	$0005

col=col6
row=row0

	.even
menu_grpalet0000:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0000 TRANSPARENT',0
2:	.dc.b	'GR 0000 BLACK+1    ',0
	.dc.b	'GR 0000 WHITE      ',0
	.dc.b	'GR 0000 WHITE+1    ',0
3:
grpalet0000_to_color:
	.dc.w	TRANSPARENT
	.dc.w	BLACK+1
	.dc.w	WHITE
	.dc.w	WHITE+1

	.even
menu_grpalet0001:
	.dc.w	2,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0001 TRANSPARENT',0
2:	.dc.b	'GR 0001 BLACK+1    ',0
	.dc.b	'GR 0001 LIME       ',0
	.dc.b	'GR 0001 LIME+1     ',0
3:
grpalet0001_to_color:
	.dc.w	TRANSPARENT
	.dc.w	BLACK+1
	.dc.w	LIME
	.dc.w	LIME+1

	.even
menu_grpalet0002:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0002 RED  ',0
2:	.dc.b	'GR 0002 RED+1',0
3:
grpalet0002_to_color:
	.dc.w	RED
	.dc.w	RED+1

	.even
menu_grpalet0003:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0003 BLUE  ',0
2:	.dc.b	'GR 0003 BLUE+1',0
3:
grpalet0003_to_color:
	.dc.w	BLUE
	.dc.w	BLUE+1

	.even
menu_grpalet0004:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0004 FUCHSIA  ',0
2:	.dc.b	'GR 0004 FUCHSIA+1',0
3:
grpalet0004_to_color:
	.dc.w	FUCHSIA
	.dc.w	FUCHSIA+1

	.even
menu_grpalet0005:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0005 AQUA  ',0
2:	.dc.b	'GR 0005 AQUA+1',0
3:
grpalet0005_to_color:
	.dc.w	AQUA
	.dc.w	AQUA+1

	.even
menu_grpalet0006:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0006 YELLOW  ',0
2:	.dc.b	'GR 0006 YELLOW+1',0
3:
grpalet0006_to_color:
	.dc.w	YELLOW
	.dc.w	YELLOW+1

	.even
menu_grpalet0007:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0007 PURPLE  ',0
2:	.dc.b	'GR 0007 PURPLE+1',0
3:
grpalet0007_to_color:
	.dc.w	PURPLE
	.dc.w	PURPLE+1

	.even
menu_grpalet0010:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0010 TEAL  ',0
2:	.dc.b	'GR 0010 TEAL+1',0
3:
grpalet0010_to_color:
	.dc.w	TEAL
	.dc.w	TEAL+1

	.even
menu_grpalet0011:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 0011 OLIVE  ',0
2:	.dc.b	'GR 0011 OLIVE+1',0
3:
grpalet0011_to_color:
	.dc.w	OLIVE
	.dc.w	OLIVE+1

	.even
menu_grpalet2020:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 2020 TRANSPARENT',0
2:	.dc.b	'GR 2020 BLACK+1    ',0
3:
grpalet2020_to_color:
	.dc.w	TRANSPARENT
	.dc.w	BLACK+1

	.even
menu_grpalet2121:
	.dc.w	0,0
	.dc.w	col,row,2f-1f-1,(3f-1f)/(2f-1f)
row=row+2*(3f-1f)/(2f-1f)+vgap
1:	.dc.b	'GR 2121 WHITE  ',0
2:	.dc.b	'GR 2121 WHITE+1',0
3:
grpalet2121_to_color:
	.dc.w	WHITE
	.dc.w	WHITE+1

	.even
sp_pats:
	.dc.l	sp_pat0
	.dc.l	sp_pat1
	.dc.l	sp_pat2
sp_pat0:
	.dcb.l	32,$00000000	;top left,bottom left,top right,bottom right
sp_pat1:
	.dcb.l	32,$11111111	;top left,bottom left,top right,bottom right
sp_pat2:
	.dcb.l	32,$22222222	;top left,bottom left,top right,bottom right


	.end

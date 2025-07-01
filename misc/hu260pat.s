;========================================================================================
;  hu260pat.s
;  Copyright (C) 2003-2022 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	hu260pat.x
;		Human 3.02からROM Human 2.60を作るためのパッチデータ
;
;	作り方
;		has060 -i include -o hu260pat.o -w hu260pat.s
;		lk -b 1447a -o hu260pat.x hu260pat.o
;
;	Human 3.02
;		textの長さ
;			$A890
;		dataの長さ
;			$33EA
;		text+dataの長さ
;			$A890+$33EA=$DC7A
;		text+dataの先頭
;			$6800
;		text+dataの末尾+1
;			$6800+$A890+$33EA=$1447A
;
;	Human 3.02をZ形式に変換して$FC2000に配置する
;		textの長さ
;			$FC2002 $A890
;		dataの長さ
;			$FC2006 $33EA
;		text+dataの先頭
;			$FC201C
;		text+dataの末尾+1
;			$FC201C+$A890+$33EA=$FCFC96
;
;	パッチをあてる
;		textの長さ
;			$FC2002 $A890
;		dataの長さ
;			$FC2006 $33EA+?
;		パッチの先頭
;			$FC201C+$A890+$33EA=$FCFC96
;		パッチの末尾+1
;			$FC201C+$A890+$33EA+?=$FCFC96+?
;
;----------------------------------------------------------------

	.include	control.mac
	.include	doscall.mac
	.include	dosconst.equ
	.include	doswork.equ
	.include	patch.mac
	.include	push.mac

VERSION_NUMBER	equ	$023C
VERSION_STRING	reg	'2.60'

Z_START		equ	$FC2000
TEXT_START	equ	Z_START+$1C
TEXT_END	equ	$FCFFFF

	PATCH_START	TEXT_START+$A890+$33EA,TEXT_END

;----------------------------------------------------------------
;Z形式ヘッダ
;----------------------------------------------------------------
	PATCH_DATA	z_header,Z_START+$06,Z_START+$09,$000033EA

	PATCH_SIZE	patch_size
	.dc.l	$33EA+patch_size

;----------------------------------------------------------------
;scsidevの初期値
;----------------------------------------------------------------
	PATCH_DATA	scsidev,$6818-$6800+TEXT_START,$681B-$6800+TEXT_START,$011B2A1B

	.dc.l	$001B2A1B

;----------------------------------------------------------------
;タイトルの中のバージョン
;----------------------------------------------------------------
	PATCH_DATA	title,$683E-$6800+TEXT_START,$6841-$6800+TEXT_START,$332E3032

	.dc.b	VERSION_STRING

;----------------------------------------------------------------
;デバイスドライバの差し替え
;	float*.xはROM FLOATを読み込む
;	iocs.xは読み込まない
;	それ以外は指定されたファイルを読み込む
;----------------------------------------------------------------
	PATCH_DATA	load_driver,$7170-$6800+TEXT_START,$7175-$6800+TEXT_START,$803C0003

	jmp	load_driver

	PATCH_TEXT

;デバイスドライバをロードする
;<d0.w:モジュール番号<<8
;<a0.l:ファイル名
;<a1.l:空きエリアの先頭アドレス
;>d0.l:text+data+bss+comm+stackのサイズ。0=無視,負数=エラー
;>ccr:eq=無視,mi=エラー
load_driver:
	push	d1-d4/a0-a2
	move.w	d0,d2			;モジュール番号<<8
	lea.l	-NS_SIZE(sp),sp
	move.l	sp,-(sp)		;_NAMESTS形式のファイル名
	move.l	a0,-(sp)		;ファイル名
	DOS	_NAMESTS
	addq.l	#8,sp
	if	pl,<tst.l d0>
		move.l	NS_EXT-1(sp),d0	;拡張子。?012
		lsl.l	#8,d0		;012-
		or.l	#$20202020,d0
		if	eq,<cmp.l #'x   ',d0>	;拡張子が'x  '
			move.l	NS_NAME_1+1(sp),d0	;ファイル名1。1234
			move.l	NS_NAME_1+5(sp),d1	;ファイル名1。567?
			move.b	NS_NAME_1+0(sp),d0	;1230
			move.b	NS_NAME_1+4(sp),d1	;5674
			ror.l	#8,d0			;0123
			ror.l	#8,d1			;4567
			or.l	#$20202020,d0
			or.l	#$20202020,d1
			ifand	eq,<cmp.l #'iocs',d0>,eq,<cmp.l #'    ',d1>	;ファイル名1が'iocs    '
				;読み込まない
				moveq.l	#0,d0
				bra	load_driver_end
				noreturn
			else
				and.l	#$FF202020,d1
				ifand	eq,<cmp.l #'floa',d0>,eq,<cmp.l #'t   ',d1>	;ファイル名1が'float???'
				;ROM FLOATを読み込む
					movea.l	$00FF0010,a0		;ROM FLOATのX形式実行ファイルの先頭
					move.l	12(a0),d0
					add.l	16(a0),d0		;text+dataのサイズ
					move.l	20(a0),d1		;bss+comm+stackのサイズ
					move.l	d0,d2
					add.l	d1,d2			;text+data+bss+comm+stackのサイズ
					move.l	a1,d3			;ロードアドレス
					sub.l	4(a0),d3		;ロードアドレス-ベースアドレス
					move.l	24(a0),d4		;リロケートテーブルのサイズ
					movea.l	a1,a2			;リロケートするデータのアドレス
				;text+dataをコピーする
					lea.l	64(a0),a0		;textの先頭
					docontinue
						move.l	(a0)+,(a1)+
					while	cc,<subq.l #4,d0>
					addq.w	#4,d0
					forcontinue	d0
						move.b	(a0)+,(a1)+
					next
				;bss+comm+stackをクリアする
					moveq.l	#0,d0
					docontinue
						move.l	d0,(a1)+
					while	cc,<subq.l #4,d1>
					addq.w	#4,d1
					forcontinue	d1
						move.b	d0,(a1)+
					next
				;リロケートする
					if	ne,<tst.l d3>
						add.l	a0,d4			;リロケートテーブルの末尾のアドレス
						docontinue
							move.w	(a0)+,d0		;次のリロケート位置までのワードオフセットまたは1と次のリロケート位置までのロングオフセット
							break	mi
							if	eq,<cmp.w #1,d0>
								move.l	(a0)+,d0
								break	mi
							endif
							bclr.l	#0,d0
							adda.l	d0,a2			;リロケートするデータのアドレス
							if	eq
								add.l	d3,(a2)			;オフセットが偶数のときはロングのデータ
							else
								add.w	d3,(a2)			;オフセットが奇数のときはワードのデータ
							endif
						while	lo,<cmpa.l d4,a0>
					endif
					move.l	d2,d0			;text+data+bss+comm+stackのサイズ
					bra	load_driver_end
					noreturn
				endif
			endif
		endif
	endif
;指定されたファイルを読み込む
	move.w	d2,d0			;モジュール番号<<8
	move.b	#3,d0			;モジュール番号<<8|3。実行ファイルのアドレス指定ロード
	adda.l	#3<<24,a0		;X形式
	move.l	$1C00.w,-(sp)		;リミットアドレス。_MALLOCできるメモリ空間の末尾アドレス+1
	move.l	a1,-(sp)		;ロードアドレス
	move.l	a0,-(sp)		;実行ファイル名
	move.w	d0,-(sp)		;モジュール番号<<8|3
	DOS	_EXEC
	lea.l	14(sp),sp
load_driver_end:
	lea.l	NS_SIZE(sp),sp
	pop
	tst.l	d0
	rts

;----------------------------------------------------------------
;空きエリアの先頭アドレス
;	Human 3.02は起動後に不要になるDOSコールベクタテーブルの種の先頭を空きエリアの先頭にしている
;	ここではDOSコールベクタテーブルの種の後ろに追加データを置いているためDOSコールベクタテーブルは残存することになる
;----------------------------------------------------------------
	PATCH_DATA	freearea,$797E-$6800+TEXT_START,$7985-$6800+TEXT_START,$21FC0001

	PATCH_SIZE	patch_size
	move.l	#$6800+$A890+$33EA+patch_size,DOS_FREE_AREA.w

;----------------------------------------------------------------
;Humanのメモリ管理テーブル
;----------------------------------------------------------------
	PATCH_DATA	mmtable,$837A-$6800+TEXT_START,$837D-$6800+TEXT_START,$0001407A

	PATCH_SIZE	patch_size
	.dc.l	$6800+$A890+$33EA+patch_size

;----------------------------------------------------------------
;_VERNUMの値
;----------------------------------------------------------------
	PATCH_DATA	vernum,$A4B2-$6800+TEXT_START,$A4B5-$6800+TEXT_START,$303C0302

	move.w	#VERSION_NUMBER,d0

;----------------------------------------------------------------

	PATCH_END

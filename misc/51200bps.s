;========================================================================================
;  51200bps.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;--------------------------------------------------------------------------------
;名前
;	51200bps.x
;説明
;	RSDRV.SYS 2.02が組み込まれている状態で実行してください。
;	X680x0の内蔵RS-232Cポートが以下の設定になります。
;		ボーレート	51200bps (理論値は52083.3bps)
;		データ長	8ビット
;		パリティ	なし
;		ストップ	1ビット
;		フロー制御	RTS
;	相手のUSB-RS232C変換器が50000bpsに対応しているとき、誤差4%で接続できることがあります。
;--------------------------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	ppi.equ
	.include	scc.equ

;38400bps
;		  S1 PN B8    RTS   38400
	move.w	#%01_00_11_0_0_1_000_1001,d1
	IOCS	_SET232C

;スーパーバイザモード
	supervisormode

;割り込み禁止
	di

aCMD	reg	a5
aPPI	reg	a6

	lea.l	SCC_A_COMMAND,aCMD
	lea.l	PPI_PORT_A,aPPI

;ボーレートジェネレータ停止
	move.b	#14,(aCMD)		;WR14
	tst.b	(aPPI)
	tst.b	(aPPI)
;		             BRGE
	move.b	#%000_0_0_0_1_0,(aCMD)

;時定数
;	TC=5000000/(2*50000*16)-2)=1.125
;	BR=5000000/(2*(1+2)*16)=52083=51200*1.017
	move.b	#12,(aCMD)		;WR12
	tst.b	(aPPI)
	tst.b	(aPPI)
	move.b	#1,(aCMD)
	move.b	#13,(aCMD)		;WR13
	tst.b	(aPPI)
	tst.b	(aPPI)
	move.b	#0,(aCMD)

;ボーレートジェネレータ再開
	move.b	#14,(aCMD)		;WR14
	tst.b	(aPPI)
	tst.b	(aPPI)
;		             BRGE
	move.b	#%000_0_0_0_1_1,(aCMD)

;割り込み許可
	ei

;ユーザモード
	usermode

;終了
	DOS	_EXIT

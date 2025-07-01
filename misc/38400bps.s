;========================================================================================
;  38400bps.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;--------------------------------------------------------------------------------
;名前
;	38400bps.x
;説明
;	RSDRV.SYS 2.02が組み込まれている状態で実行してください。
;	X680x0の内蔵RS-232Cポートが以下の設定になります。
;		ボーレート	38400bps (理論値は39062.5bps)
;		データ長	8ビット
;		パリティ	なし
;		ストップ	1ビット
;		フロー制御	RTS
;--------------------------------------------------------------------------------

	.include	doscall.mac
	.include	iocscall.mac

;38400bps
;		  S1 PN B8    RTS   38400
	move.w	#%01_00_11_0_0_1_000_1001,d1
	IOCS	_SET232C

;終了
	DOS	_EXIT

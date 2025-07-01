;========================================================================================
;  scsi16.s
;  Copyright (C) 2003-2024 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	scsi16in.r / scsi16ex.r
;		SCSIINROM 16とSCSIEXROM 16
;
;	最終更新
;		2024-07-02
;
;	作り方
;		has060 -i include -o scsi16in.o -w scsi16.s -SSCSIEXROM=0
;		lk -b fc0000 -o scsi16in.x -x scsi16in.o
;		cv /rn scsi16in.x scsi16in.r
;		has060 -i include -o scsi16ex.o -w scsi16.s -SSCSIEXROM=1
;		lk -b ea0000 -o scsi16ex.x -x scsi16ex.o
;		cv /rn scsi16ex.x scsi16ex.r
;
;	修正箇所
;		接続されているだけで起動できなくなる機器がある
;			起動時のRequest SenseとInquiryのアロケーション長が短すぎる
;			短すぎるアロケーション長に従わない機器が接続されていると起動時に固まる
;			アロケーション長を十分な長さにする
;		書き込みに失敗する可能性がある
;			DMA転送の書き込みでバスエラーから復帰するときDMACとSPCの残りデータ数が食い違う場合がある
;			食い違ったまま復帰すると同じデータが2回出力され全体の数が合わなくなる
;			バスエラーから復帰するときSPCの残りデータ数を用いてDMACのアドレスと残りデータ数を再計算する
;		読み出しに失敗する可能性がある
;			データインフェーズからステータスフェーズに移るときACKがネゲートされるのを待たない機器があるらしい
;			FIFOが空になる前にフェーズが変わるとService Requiredが発生して異常終了する
;			FIFOが空でないときService Requiredを無視する
;		SASI HDを接続してSASIフラグをセットすると起動できなくなる
;			_B_DSKINIがd5/a2を破壊している
;			SCSIデバイスドライバ組み込みルーチンが_B_DSKINIを跨いでa2を使っていてスタックが破壊される
;			_B_DSKINIでd5/a2を保護する
;
;	追加機能
;		MC68040とMC68060に対応する
;			MC68040またはMC68060のときDMA転送開始前にキャッシュをプッシュする
;			MC68060の未実装整数命令例外の発生を避けるためMOVEP命令を使わない
;		ブロック長が2048の機器のディスクIPLとデバイスドライバを読み出せる
;			ディスクIPLの位置は$0400と$0800のどちらでもよい
;			S_READなどでd5のブロック長指数が4以上のとき3と見なす
;			NetBSD/x68kのインストールCD-ROMから起動できる
;			ディスクIPLとデバイスドライバが対応しなければブロック長が2048の機器から起動できないことに変わりはない
;			4096以上は非対応
;
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	dmac.equ
	.include	dosconst.equ
	.include	hdc.equ
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	scsicall.mac
	.include	spc.equ
	.include	sram.equ
	.include	sysport.equ
	.include	vector.equ

  .ifndef SCSI_BIOS_LEVEL
SCSI_BIOS_LEVEL	equ	16		;レベル。0=SUPER,3=XVI,4=FORMAT.X,10=X68030,16=XEiJ
  .endif
  .ifndef SCSIEXROM
SCSIEXROM	equ	0		;拡張か。0=SCSIINROM,1=SCSIEXROM
  .endif

  .if 16<=SCSI_BIOS_LEVEL
    .if SCSIEXROM
SCSI_BIOS_TITLE	reg	'SCSIEXROM 16 (2024-07-02)'
    .else
SCSI_BIOS_TITLE	reg	'SCSIINROM 16 (2024-07-02)'
    .endif
  .endif

	.cpu	68000
	.text



;--------------------------------------------------------------------------------
;	.include	sc01head.s
;--------------------------------------------------------------------------------

  .if SCSIEXROM
SPC_BASE	equ	SPC_EX_BASE	;拡張SPCベースアドレス
  .else
SPC_BASE	equ	SPC_IN_BASE	;内蔵SPCベースアドレス
  .endif

  .if SCSI_BIOS_LEVEL<=3
abs	reg	.l			;(xxx)absを絶対ロングにする
  .else
abs	reg	.w			;(xxx)absを絶対ワードにする
  .endif

dLEN	reg	d3			;データの長さ
dID	reg	d4			;(LUN<<16)|SCSI-ID
aBUF	reg	a1			;バッファのアドレス
aSPC	reg	a6			;SPC_xxx(aSPC)でSPCのレジスタを参照する

scsi_bios_start:

  .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
    .if SCSIEXROM
;----------------------------------------------------------------
;SPC
spc_ex_base:
	.dcb.b	32,$FF
    .endif
  .endif

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;ROM起動ハンドル
rom_boot_handle:
	.dc.l	rom_boot_routine				;+0
    .if SCSI_BIOS_LEVEL<>10
	.dc.l	rom_boot_routine				;+4
	.dc.l	rom_boot_routine				;+8
	.dc.l	rom_boot_routine				;+12
	.dc.l	rom_boot_routine				;+16
	.dc.l	rom_boot_routine				;+20
	.dc.l	rom_boot_routine				;+24
	.dc.l	rom_boot_routine				;+28
    .endif

;----------------------------------------------------------------
;ROM起動ハンドル+32 SCSI初期化ハンドル
scsi_init_handle:
	.dc.l	scsi_init_routine				;+32
  .endif

  .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
;----------------------------------------------------------------
;ROM起動ハンドル+36 SCSIIN/SCSIEXマジック
scsi_rom_magic:
    .if SCSIEXROM
	.dc.b	'SCSIEX'					;+36
    .else
	.dc.b	'SCSIIN'					;+36
    .endif
  .endif



;--------------------------------------------------------------------------------
;	.include	sc02boot.s
;--------------------------------------------------------------------------------

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;ROM起動ハンドル+42 SCSI BIOSレベル
scsi_bios_level:
	.dc.w	SCSI_BIOS_LEVEL					;+42

    .if 16<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
scsi_bios_title:
	.dc.b	SCSI_BIOS_TITLE,0
	.even
    .endif
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;SPCベースハンドル
;	レベル4のSPCベースハンドルはデバイスドライバが内蔵と拡張を選択する
spc_base_handle:
	.dc.l	SPC_BASE		;SPCベースアドレス
  .endif

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;SCSI初期化ルーチン
;?d0-d1/a1
scsi_init_routine:
    .if SCSI_BIOS_LEVEL<>10
;_SCSIDRVを登録する
	moveq.l	#_B_INTVCS,d0
	move.l	#$100+_SCSIDRV,d1
	lea.l	iocs_F5_SCSIDRV(pc),a1	;IOCSコール$F5 _SCSIDRV
	trap	#15
      .if SCSI_BIOS_LEVEL<=10
	if	<cmp.l a1,d0>,ne	;初回
      .else
        .if SCSIEXROM
	ifor	<cmp.l a1,d0>,ne,<btst.b #1,BIOS_SCSI_INITIALIZED.w>,eq
        .else
	ifor	<cmp.l a1,d0>,ne,<btst.b #0,BIOS_SCSI_INITIALIZED.w>,eq
        .endif
	;_SCSIDRVのベクタが自分を指していなかったまたはSCSI初期化済みフラグがセットされていないとき
      .endif
	;_S_RESETを呼び出す
		moveq.l	#_SCSIDRV,d0
		moveq.l	#_S_RESET,d1
		trap	#15
      .if 16<=SCSI_BIOS_LEVEL
		goto	<tst.b SRAM_SCSI_SASI_FLAG>,eq,scsi_init_skip	;SASI機器が接続されていない
		goto	<tst.l BIOS_SCSI_OLD_VERIFY.w>,ne,scsi_init_skip	;既に拡張されている
      .endif
	;IOCSコール$40～$4Fを登録する
		bsr	install_sasi_iocs	;SCSIバスに接続されているSASI機器をIOCSコール$40～$4Fで操作できるようにする
	;TRAP#11(BREAK)を登録する
		moveq.l	#_B_INTVCS,d0
		moveq.l	#OFFSET_TRAP_11/4,d1	;例外ベクタ$2B TRAP#11(BREAK)
		lea.l	trap_11_break(pc),a1	;TRAP#11(BREAK)
		trap	#15
      .if 16<=SCSI_BIOS_LEVEL
	;TRAP#11(BREAK)を登録してから元のベクタを保存するまでの間にBREAKキーが押される可能性がゼロではないので手順としては正しくない
		move.l	d0,BIOS_SCSI_OLD_TRAP11.l	;例外ベクタ$2B TRAP#11(BREAK)の元のベクタ
	scsi_init_skip:
      .endif
	endif
    .else
	bsr	dskini_all		;SASIハードディスクを初期化する
    .endif
	rts

;----------------------------------------------------------------
;ROM起動ルーチン-20 ROM起動マジック
;	ROM 1.3が起動するSCSI-IDを求めるときに確認する
rom_boot_magic:
	.dc.l	'SCSI'

;----------------------------------------------------------------
;ROM起動ルーチン-16 SCSIデバイスドライバ組み込みハンドル
;	Human68k 3.02がデバイスドライバを組み込むときに参照する
device_installer_handle:
	.dc.l	device_installer	;SCSIデバイスドライバ組み込みルーチン

;----------------------------------------------------------------
;ROM起動ルーチン-12 SCSIデバイスドライバ組み込みルーチンのパラメータ
;	Human68k 3.02がSCSIデバイスドライバを組み込むときに参照する
;	FORMAT2.Xがハードディスクに書き込むSCSIデバイスドライバに
;	「指定されたSCSI ROMを用いて_S_RESETを実行し、設定されていなければ_SCSIDRVを設定する」
;	という処理があり、ここを参照している
;	ここにはIOCSコール$F5 _SCSIDRVのハンドルがなければならない
device_installer_parameter:
	.dc.l	iocs_F5_SCSIDRV		;IOCSコール$F5 _SCSIDRV

;----------------------------------------------------------------
;ROM起動ルーチン-8 デバイスドライバ識別子
;	Human68k 3.02がSCSIデバイスドライバを組み込むときに確認する
device_installer_magic:
	.dc.b	'Human68k'

;----------------------------------------------------------------
;ROM起動ルーチン
rom_boot_routine:
;起動するSCSI-IDを求める
    .if SCSI_BIOS_LEVEL<>10
	IOCS	_BOOTINF
      .if 3<=SCSI_BIOS_LEVEL
	andi.l	#$00FFFFFF,d0
      .endif
	move.l	d0,d4
	subi.l	#rom_boot_handle,d4	;ROM起動ハンドルからのオフセット
	lsr.l	#2,d4			;起動するSCSI-ID
    .else
	bsr	get_scsi_id_to_boot	;起動するSCSI-IDを求める
	if	<tst.l d0>,mi
		moveq.l	#0,d0
	endif
	move.l	d0,d4			;起動するSCSI-ID
    .endif
;<d4.l:起動するSCSI-ID。-1=SCSI起動ではない
    .if SCSI_BIOS_LEVEL<>10
      .if SCSI_BIOS_LEVEL<=10
;_SCSIDRVを登録する
	moveq.l	#_B_INTVCS,d0
	move.l	#$100+_SCSIDRV,d1
	lea.l	iocs_F5_SCSIDRV(pc),a1	;IOCSコール$F5 _SCSIDRV
	trap	#15
	if	<cmp.l a1,d0>,ne	;初回
	;_S_RESETを呼び出す
		moveq.l	#_SCSIDRV,d0
		moveq.l	#_S_RESET,d1		;SPCの初期化とSCSIバスリセット
		trap	#15
	;(SCSIから起動したとき)
	;IOCSコール$40～$4Fを登録する
		bsr	install_sasi_iocs	;SCSIバスに接続されているSASI機器をIOCSコール$40～$4Fで操作できるようにする
	;TRAP#11(BREAK)を登録する
		moveq.l	#_B_INTVCS,d0
		moveq.l	#OFFSET_TRAP_11/4,d1	;例外ベクタ$2B TRAP#11(BREAK)
		lea.l	trap_11_break(pc),a1	;TRAP#11(BREAK)
		trap	#15
        .if 3<=SCSI_BIOS_LEVEL
		move.l	d0,BIOS_SCSI_OLD_TRAP11.l	;例外ベクタ$2B TRAP#11(BREAK)の元のベクタ
        .endif
	endif
      .else
	bsr	scsi_init_routine	;SCSI初期化ルーチン
      .endif
    .else
	bsr	dskini_all		;SASIハードディスクを初期化する
    .endif
;アクセス開始
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,ne,scsi_boot_failed	;起動するSCSI-IDのSASIフラグがセットされているので失敗
    .if SCSI_BIOS_LEVEL<=3
	moveq.l	#10-1,d6		;10回までリトライする
    .else
	moveq.l	#20-1,d6		;20回までリトライする
    .endif
scsi_boot_redo:
	bsr	check_confliction_1st	;本体と同じSCSI-IDの機器がないか確認する
;<d0.l:-1=本体と同じSCSI-IDの機器はない
    .if SCSI_BIOS_LEVEL<=3
	goto	<cmp.l #-1,d0>,ne,scsi_boot_failed	;本体と同じSCSI-IDの機器が接続されているので失敗
    .else
	addq.l	#1,d0
	goto	ne,scsi_boot_failed	;本体と同じSCSI-IDの機器が接続されているので失敗
    .endif
;Test Unit Ready
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_TESTUNIT,d1
	trap	#15
    .if SCSI_BIOS_LEVEL<=3
	goto	<cmp.l #0,d0>,eq,test_unit_passed	;_S_TESTUNITでCommand Completeが返った
    .else
	goto	<tst.l d0>,eq,test_unit_passed	;_S_TESTUNITでCommand Completeが返った
    .endif
	goto	<cmp.l #-1,d0>,eq,scsi_boot_retry	;エラーのときはリトライ
	goto	<cmp.l #8,d0>,eq,scsi_boot_retry	;Busyのときはリトライ
	goto	<cmp.l #2,d0>,ne,scsi_boot_failed	;Check Conditionでなければ失敗
;_S_TESTUNITでCheck Conditionが返った
;Request Sense
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_REQUEST,d1
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;Request Senseのアロケーション長が足りない
;	Request Senseのセンスデータはエラークラスによって4バイトまたは8バイト以上だがアロケーション長が3バイトになっている
;	起動時にアロケーション長よりも多くのデータを返そうとするSCSI機器が接続されて電源が入っているとハングアップする
;	参考: 電脳倶楽部111号 FDS120T.DOC
	moveq.l	#3,d3			;アロケーション長
;+++++ BUG +++++
    .else
	moveq.l	#8,d3			;アロケーション長。8以上
    .endif
    .if SCSI_BIOS_LEVEL<=3
	lea.l	$00002000.l,a1
    .else
	lea.l	$2000.w,a1
    .endif
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed
    .if SCSI_BIOS_LEVEL<=3
	lea.l	$00002000.l,a1
    .else
	lea.l	$2000.w,a1
    .endif
	move.b	(a1),d0			;センスエラーコード
	andi.b	#$70,d0
	goto	<cmpi.b #$70,d0>,ne,scsi_boot_failed	;拡張センスキーがなければ失敗
	move.b	2(a1),d0		;センスキー
	goto	eq,scsi_boot_redo	;No Senseはリトライ
	goto	<cmp.b #1,d0>,eq,scsi_boot_redo	;Recovered Errorはリトライ
	goto	<cmp.b #6,d0>,eq,scsi_boot_redo	;Unit Attentionはリトライ
    .if 10<=SCSI_BIOS_LEVEL
	goto	<cmp.b #2,d0>,eq,scsi_boot_redo	;Not Readyはリトライ
    .endif
	goto	scsi_boot_failed	;それ以外は失敗

;リトライ
scsi_boot_retry:
	dbra.w	d6,scsi_boot_redo_1
;リトライ回数が上限を超えた
	goto	scsi_boot_failed

scsi_boot_redo_1:
	goto	scsi_boot_redo

scsi_boot_failed:
	rts

;_S_TESTUNITでCommand Completeが返った
test_unit_passed:
    .if SCSI_BIOS_LEVEL<=3
	bsr	check_confliction_1st	;本体と同じSCSI-IDの機器がないか確認する
    .else
	bsr	check_confliction_2nd	;本体と同じSCSI-IDの機器がないか確認する(確認済みならば何もしない)
    .endif
;<d0.l:-1=本体と同じSCSI-IDの機器はない
    .if SCSI_BIOS_LEVEL<=3
	goto	<cmp.l #-1,d0>,ne,scsi_boot_failed	;本体と同じSCSI-IDの機器が接続されているので失敗
    .else
	addq.l	#1,d0
	goto	ne,scsi_boot_failed	;本体と同じSCSI-IDの機器が接続されているので失敗
    .endif
;Inquiry
    .if SCSI_BIOS_LEVEL<=3
	lea.l	$00002000.l,a1
    .else
	lea.l	$2000.w,a1
    .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_INQUIRY,d1
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;Inquiryのアロケーション長が足りない
;	InquiryでEVPDが0のときアロケーション長は5バイト以上でなければならないのに1バイトになっている
;	Inquiryは1回目に5バイト要求して2回目に追加データ長+5バイト要求するのが正しい
;	最初から36バイト要求しても良いが2回に分ける方が無難
	moveq.l	#1,d3
;+++++ BUG +++++
    .else
	moveq.l	#5,d3			;アロケーション長。5以上
    .endif
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;INQUIRYで失敗
    .if SCSI_BIOS_LEVEL<=3
	gotoand	<cmpi.b #$84,0.w(a1)>,ne,<tst.b 0.w(a1)>,ne,scsi_boot_failed	;SHARP MOとダイレクトアクセスデバイス以外は失敗
    .else
	ifand	<btst.b #SRAM_SCSI_IGNORE_BIT,SRAM_SCSI_MODE>,eq,<tst.b (a1)>,ne,<cmpi.b #$04,(a1)>,ne,<cmpi.b #$05,(a1)>,ne,<cmpi.b #$07,(a1)>,ne,<cmpi.b #$84,(a1)>,ne
		;タイプ無視ではなくて
		;デバイスタイプが
		;	$00(ダイレクトアクセスデバイス)
		;	$04(ライトワンスデバイス(追記型光ディスク))
		;	$05(CD-ROMデバイス)
		;	$07(光メモリデバイス(消去可能光ディスク))
		;	$84(SHARP MO)
		;ではない
		goto	scsi_boot_failed	;失敗

	endif
    .endif
;Rezero Unit
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_REZEROUNIT,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;REZEROUNITで失敗
;Read Capacity
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READCAP,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;READCAPで失敗
    .if SCSI_BIOS_LEVEL<=0
;+++++ BUG +++++
;ブロック長が2048以上のとき素通りさせているが正常に動作しない
;+++++ BUG +++++
    .elif SCSI_BIOS_LEVEL<=3
	goto	<cmpi.l #2048,4(a1)>,cc,scsi_boot_failed	;ブロック長が2048以上のときは失敗
    .elif SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;ブロック長が2048以上のとき素通りさせているが正常に動作しない
;+++++ BUG +++++
    .endif
	move.l	4(a1),d5		;ブロック長
	lsr.l	#8,d5
	lsr.l	#1,d5			;256→0,512→1,1024→2,2048→4,4096→8,…
    .if 16<=SCSI_BIOS_LEVEL
	goto	<cmp.l #4,d5>,hi,scsi_boot_failed	;ブロック長が大きすぎるので失敗
	if	eq			;2048
		moveq.l	#3,d5			;2048→3
	endif
    .endif
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
    .if SCSI_BIOS_LEVEL<=10
;$0000-$03FFを$2000-$23FFに読み込む
	moveq.l	#$0000/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;ブロック長に応じてブロック番号とブロック数を調整する
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;READで失敗
	gotoor	<cmpi.l #'X68S',0.w(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,scsi_boot_failed	;装置初期化されていないので失敗
;$0400-$07FFを$2000-$23FFに読み込む
	moveq.l	#$0400/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;ブロック長に応じてブロック番号とブロック数を調整する
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	goto	<tst.l d0>,ne,scsi_boot_failed	;READで失敗
	goto	<cmpi.b #$60,(a1)>,ne,scsi_boot_failed	;IPLの先頭がbraでないので失敗
	jsr	(a1)			;ディスクIPLを起動する
	goto	scsi_boot_failed	;ディスクIPLから帰ってきてしまったので失敗

    .else
;$0000-$07FFを$2000-$27FFに読み込む
	moveq.l	#$0000/256,d2
	moveq.l	#$0800/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	lea.l	$2000.w,a1
	SCSI	_S_READ
	goto	<tst.l d0>,ne,scsi_boot_failed	;READで失敗
	gotoor	<cmpi.l #'X68S',(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,scsi_boot_failed	;装置初期化されていないので失敗
	if	<cmpi.b #$60,$0400(a1)>,eq	;$0400-$07FFにディスクIPLがある
		;$2400-$27FFを$2000-$23FFにコピーする
		lea.l	$2000.w,a1
		move.w	#$0400/4-1,d0
		for	d0
			move.l	$0400(a1),(a1)+
		next
		move.w	#$0400/4-1,d0
		for	d0
			clr.l	(a1)+
		next
	else
	;$0400-$07FFにディスクIPLがない
	;$0800-$0FFFを$2000-$27FFに読み込む
		moveq.l	#$0800/256,d2
		moveq.l	#$0800/256,d3
		lsr.l	d5,d2
		lsr.l	d5,d3
		lea.l	$2000.w,a1
		SCSI	_S_READ
		goto	<tst.l d0>,ne,scsi_boot_failed	;READで失敗
		goto	<cmpi.b #$60,(a1)>,ne,scsi_boot_failed	;$0800-$0FFFにディスクIPLがない
	;$0800-$0FFFにディスクIPLがある
	endif
	bsr	cache_flush
	moveq.l	#0,d0
	lea.l	$2000.w,a1
	jsr	(a1)			;ディスクIPLを起動する
	goto	scsi_boot_failed	;ディスクIPLから帰ってきてしまったので失敗

    .endif

    .if SCSI_BIOS_LEVEL==10
;----------------------------------------------------------------
;起動するSCSI-IDを求める
;>d0.l:SCSI-ID(0～7,-1=SCSI起動ではない)
get_scsi_id_to_boot:
	IOCS	_BOOTINF
	andi.l	#$00FFFFFF,d0
	if	<cmp.l #$00000100,d0>,cc	;ROM起動またはSRAM起動
	;+++++ BUG +++++
	;ROM起動アドレス-20を不用意にリードしている
	;	もしもSRAM起動ならばSRAM起動ルーチンの先頭4バイトの値-20をリードすることになる
	;	起動したSCSI ROMが自分でなくてもSCSI-IDを判別できるようにしようとしたように見えるが目的が不明
		movea.l	d0,a0			;ROM起動ハンドルまたはSRAM起動アドレス
		movea.l	(a0),a0			;ROM起動アドレス
	;+++++ BUG +++++
		if	<cmpi.l #'SCSI',rom_boot_magic-rom_boot_routine(a0)>,eq	;ROM起動マジックを比較。SCSI起動
			andi.l	#31,d0			;SCSI ROMの先頭からのオフセット
			lsr.l	#2,d0			;起動するSCSI-ID
			rts

		endif
	;SCSI起動ではない
	endif
;ROM起動またはSRAM起動ではない
	moveq.l	#-1,d0
	rts
    .endif

    .if 10<=SCSI_BIOS_LEVEL
;起動できない
next_device:
	bset.b	d2,BIOS_SCSI_UNBOOTABLE.w
	addq.w	#1,d2
	goto	install_device
    .endif

;----------------------------------------------------------------
;SCSIデバイスドライバ組み込みルーチン
;	Human68kがSCSIデバイスドライバを組み込むとき最初に呼び出す
;<d2.l:(パーティションの数<<16)|組み込むSCSI-ID。初回は0。組み込むSCSI-IDが8のとき終了
;<a1.l:デバイスドライバのコピー先のアドレス
;>d2.l:次回の(パーティションの数<<16)|組み込むSCSI-ID
device_installer:
	push	d0-d1/d3-d7/a0-a6
;起動したSCSI-IDを求める
    .if SCSI_BIOS_LEVEL<>10
	IOCS	_BOOTINF
      .if 3<=SCSI_BIOS_LEVEL
	andi.l	#$00FFFFFF,d0
      .endif
	subi.l	#rom_boot_handle,d0	;ROM起動ハンドルからのオフセット
	if	cc
		lsr.l	#2,d0			;起動したSCSI-ID
		move.b	d0,d7			;起動したSCSI-ID
		goto	<cmpi.l #8,d0>,cs,install_device	;SCSI起動
	endif
	moveq.l	#-1,d7
	goto	<cmpi.l #8,d0>,eq,install_device	;起動したSCSI-IDが8。SASI起動？
	goto	<tst.b d2>,ne,install_device	;組み込むSCSI-IDが0ではない
;組み込むSCSI-IDが0
	movea.l	a1,a2
;<a2.l:デバイスドライバのコピー先のアドレス
      .if SCSI_BIOS_LEVEL<=10
;_SCSIDRVを登録する
	moveq.l	#_B_INTVCS,d0
	move.l	#$100+_SCSIDRV,d1
	lea.l	iocs_F5_SCSIDRV(pc),a1	;IOCSコール$F5 _SCSIDRV
	trap	#15
	if	<cmp.l a1,d0>,ne	;初回
	;_S_RESETを呼び出す
		moveq.l	#_SCSIDRV,d0
		moveq.l	#_S_RESET,d1		;SPCの初期化とSCSIバスリセット
		trap	#15
	;(SCSIから起動しなかったとき)
	;IOCSコール$40～$4Fを登録しない
	;TRAP#11(BREAK)を登録する
		moveq.l	#_B_INTVCS,d0
		moveq.l	#OFFSET_TRAP_11/4,d1	;例外ベクタ$2B TRAP#11(BREAK)
		lea.l	trap_11_break(pc),a1	;TRAP#11(BREAK)
		trap	#15
        .if 3<=SCSI_BIOS_LEVEL
		move.l	d0,BIOS_SCSI_OLD_TRAP11.l	;例外ベクタ$2B TRAP#11(BREAK)の元のベクタ
        .endif
	endif
      .else
	bsr	scsi_init_routine	;SCSI初期化ルーチン
      .endif
	movea.l	a2,a1
;<a1.l:デバイスドライバのコピー先のアドレス
    .else
	bsr	get_scsi_id_to_boot	;起動したSCSI-IDを求める
	if	<tst.l d0>,pl
		move.b	d0,d7			;起動したSCSI-ID
		goto	<cmpi.w #8,d0>,cs,install_device
	endif
	moveq.l	#-1,d7			;SCSI起動ではない
    .endif
;SCSI起動
;<d2.l:(パーティションの数<<16)|組み込むSCSI-ID
;<d7.l:起動したSCSI-ID。-1=SCSI起動ではない
;<a1.l:デバイスドライバのコピー先のアドレス
install_device:
	goto	<cmp.w #8,d2>,eq,install_finish	;組み込むSCSI-IDが8。終了
;本体と同じSCSI-IDの機器がないか確認する
    .if SCSI_BIOS_LEVEL<=3
	bsr	check_confliction_1st	;本体と同じSCSI-IDの機器がないか確認する
	goto	<cmp.l #-1,d0>,ne,install_finish	;本体と同じSCSI-IDの機器がある
    .else
	bsr	check_confliction_2nd	;本体と同じSCSI-IDの機器がないか確認する(確認済みならば何もしない)
	goto	<addq.l #1,d0>,ne,install_finish	;本体と同じSCSI-IDの機器がある
    .endif
;本体と同じSCSI-IDの機器はない
wait_device:
	moveq.l	#0,d4
	move.w	d2,d4			;組み込むSCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,ne,next_device	;SASIは失敗
    .if 10<=SCSI_BIOS_LEVEL
	goto	<btst.b d4,BIOS_SCSI_UNBOOTABLE.w>,ne,next_device	;起動できない
    .endif
	move.b	SRAM_SCSI_MODE,d0	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
	andi.b	#7,d0			;本体のSCSI-ID
	goto	<cmp.b d4,d0>,eq,next_device	;本体は失敗
;Test Unit Ready
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_TESTUNIT,d1
	trap	#15
	if	<cmp.l #2,d0>,ne	;Check Condition以外
		goto	<cmp.l #8,d0>,eq,wait_device	;Busyは待つ
		goto	<tst.l d0>,ne,next_device	;Check ConditionとBusy以外のエラーは失敗
	endif
;Request Sense
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_REQUEST,d1
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;Request Senseのアロケーション長が足りない
;	同上
	moveq.l	#3,d3
;+++++ BUG +++++
    .else
	moveq.l	#8,d3			;アロケーション長。8以上
    .endif
	trap	#15
	goto	<tst.l d0>,ne,next_device	;REQUESTで失敗
;Inquiry
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_INQUIRY,d1
	moveq.l	#36,d3
	trap	#15
    .if SCSI_BIOS_LEVEL<>10
	goto	<tst.l d0>,ne,next_device	;INQUIRYで失敗
    .else
	tst.l	d0
;!!! ショートで届くのにワードになっている
	bne.w	next_device		;INQUIRYで失敗
    .endif
    .if SCSI_BIOS_LEVEL<=3
	gotoand	<cmpi.b #$84,0.w(a1)>,ne,<tst.b 0.w(a1)>,ne,next_device	;SHARP MOとダイレクトアクセスデバイス以外は失敗
    .else
	ifand	<btst.b #6,SRAM_SCSI_MODE>,eq,<tst.b (a1)>,ne,<cmpi.b #$04,(a1)>,ne,<cmpi.b #$05,(a1)>,ne,<cmpi.b #$07,(a1)>,ne,<cmpi.b #$84,(a1)>,ne
	;タイプ無視ではなくて
	;デバイスタイプが
	;	$00(ダイレクトアクセスデバイス)
	;	$04(ライトワンスデバイス(追記型光ディスク))
	;	$05(CD-ROMデバイス)
	;	$07(光メモリデバイス(消去可能光ディスク))
	;	$84(SHARP MO)
	;ではない
		goto	next_device		;失敗

	endif
    .endif
;Read Capacity
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READCAP,d1
	trap	#15
	goto	<tst.l d0>,ne,next_device	;READCAPで失敗
	move.l	d2,d6			;(パーティションの数<<16)|組み込むSCSI-ID
	move.l	4(a1),d5		;ブロック長
	lsr.l	#8,d5
	lsr.l	#1,d5			;256→0,512→1,1024→2,2048→4,4096→8,…
    .if 16<=SCSI_BIOS_LEVEL
	goto	<cmp.l #4,d5>,hi,next_device	;ブロック長が大きすぎるので失敗
	if	eq			;2048
		moveq.l	#3,d5			;2048→3
	endif
    .endif
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
    .if SCSI_BIOS_LEVEL<=10
;$0800-$0BFFをa1-(a1+$03FF)に読み込む
	moveq.l	#$0800/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;ブロック長に応じてブロック番号とブロック数を調整する
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	move.l	d6,d2			;(パーティションの数<<16)|組み込むSCSI-ID
	goto	<tst.l d0>,ne,next_device	;READで失敗
	goto	<cmpi.l #'X68K',(a1)>,ne,next_device	;パーティションテーブルがない。装置初期化されていない
;SCSI起動のときは起動したSCSI-IDの自動起動のパーティションまでの自動起動または使用可能なパーティションの数を数える
;SCSI起動でないときはすべてのSCSI-IDの自動起動または使用可能なパーティションの数を数える
	swap.w	d2			;(組み込むSCSI-ID<<16)|パーティションの数
	if	<cmp.b d7,d4>,ls	;(現在のSCSI-ID)-(起動したSCSI-ID)
	;SCSI起動のときは組み込むSCSI-IDが起動したSCSI-ID以下。SCSI起動でないときはすべて
      .if SCSI_BIOS_LEVEL<=3
		if	ne			;組み込むSCSI-IDが起動したSCSI-IDと違う
			bsr	count_partition_1	;自動起動または使用可能なパーティションの数を数える
			add.w	d3,d2			;パーティションの数を加算
		else				;組み込むSCSI-IDが起動したSCSI-IDと同じ
			bsr	count_partition_2	;自動起動または使用可能なパーティションの数を自動起動のパーティションが見つかるまで数える
			add.w	d3,d2			;パーティションの数を加算
		endif
      .else
		bsr	count_partition		;自動起動または起動可能なパーティションを数える
		add.w	d3,d2			;パーティションの数を加算
      .endif
	endif
	swap.w	d2			;(パーティションの数<<16)|組み込むSCSI-ID
	move.l	d2,d6			;(パーティションの数<<16)|組み込むSCSI-ID
;$0000-$03FFを(a1)-(a1+$03FF)に読み込む
	moveq.l	#$0000/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$0400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$0400/256,d3
	bsr	adjust_block_number	;ブロック長に応じてブロック番号とブロック数を調整する
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	move.l	d6,d2			;(パーティションの数<<16)|組み込むSCSI-ID
	goto	<tst.l d0>,ne,next_device	;READで失敗
	gotoor	<cmpi.l #'X68S',0.w(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,next_device	;装置初期化されていない
;$0C00-$3FFFを(a1)-(a1+$33FF)に読み込む
	moveq.l	#$0C00/256,d2
      .if (SCSI_BIOS_LEVEL<=3)|(16<=SCSI_BIOS_LEVEL)
	lsr.l	d5,d2
	moveq.l	#$3400/256,d3
	lsr.l	d5,d3
      .else
	moveq.l	#$3400/256,d3
	bsr	adjust_block_number	;ブロック長に応じてブロック番号とブロック数を調整する
      .endif
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_READ,d1
	trap	#15
	move.l	d6,d2			;(パーティションの数<<16)|組み込むSCSI-ID
	goto	<tst.l d0>,ne,next_device	;READで失敗
    .else
;<d6.l:(パーティションの数<<16)|組み込むSCSI-ID
	movea.l	a1,a2
;<a2.l:デバイスドライバのコピー先のアドレス
;$0000-$07FFを(a2)-(a2+$07FF)に読み込む
	moveq.l	#$0000/256,d2
	moveq.l	#$0800/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	movea.l	a2,a1
	SCSI	_S_READ
	move.l	d6,d2			;(パーティションの数<<16)|組み込むSCSI-ID
	goto	<tst.l d0>,ne,next_device	;READで失敗
	gotoor	<cmpi.l #'X68S',0.w(a1)>,ne,<cmpi.l #'CSI1',4(a1)>,ne,next_device	;装置初期化されていない
;$0800-$0FFFを(a2)-(a2+$07FF)に読み込む
	moveq.l	#$0800/256,d2
	moveq.l	#$0800/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	movea.l	a2,a1
	SCSI	_S_READ
	move.l	d6,d2			;(パーティションの数<<16)|組み込むSCSI-ID
	goto	<tst.l d0>,ne,next_device	;READで失敗
	goto	<cmpi.l #'X68K',(a1)>,ne,next_device	;パーティションテーブルがない。装置初期化されていない
;SCSI起動のときは起動したSCSI-IDの自動起動のパーティションまでの自動起動または使用可能なパーティションの数を数える
;SCSI起動でないときはすべてのSCSI-IDの自動起動または使用可能なパーティションの数を数える
	swap.w	d2			;(組み込むSCSI-ID<<16)|パーティションの数
	if	<cmp.b d7,d4>,ls	;(現在のSCSI-ID)-(起動したSCSI-ID)
	;SCSI起動のときは組み込むSCSI-IDが起動したSCSI-ID以下。SCSI起動でないときはすべて
		bsr	count_partition		;自動起動または起動可能なパーティションを数える
		add.w	d3,d2			;パーティションの数を加算
	endif
	swap.w	d2			;(パーティションの数<<16)|組み込むSCSI-ID
	move.l	d2,d6			;(パーティションの数<<16)|組み込むSCSI-ID
;(a2+$0400)-(a2+$07FF)を(a2)-(a2+$03FF)にコピーする
	movea.l	a2,a1
	move.w	#$0400/4-1,d0
	for	d0
		move.l	$0400(a1),(a1)+
	next
;$1000-$3FFFを(a2+$0400)-(a2+$33FF)に読み込む
	moveq.l	#$1000/256,d2
	moveq.l	#$3000/256,d3
	lsr.l	d5,d2
	lsr.l	d5,d3
	lea.l	$0400(a2),a1
	SCSI	_S_READ
	move.l	d6,d2			;(パーティションの数<<16)|組み込むSCSI-ID
	goto	<tst.l d0>,ne,next_device	;READで失敗
	movea.l	a2,a1
    .endif
;デバイスヘッダをリロケートする
	do
		gotoor	<cmpi.l #($01.shl.24)|'SCH',14(a1)>,ne,<cmpi.l #'DISK',18(a1)>,ne,next_device	;SCSIデバイスドライバがない
		move.l	a1,d0
		add.l	d0,6(a1)		;ストラテジハンドルをリロケートする
		add.l	d0,10(a1)		;インタラプトハンドルをリロケートする
		move.l	(a1),d0			;ネクストデバイスドライバハンドル
		break	<cmp.l #-1,d0>,eq	;最後のデバイスドライバ
		add.l	a1,d0			;ネクストデバイスドライバハンドルをリロケートする
		move.l	d0,(a1)
		movea.l	d0,a1
	while	t
	swap.w	d2			;(組み込むSCSI-ID<<16)|パーティションの数
	move.b	d2,22(a1)		;最後のデバイスドライバにパーティションの数を設定する
	swap.w	d2			;(パーティションの数<<16)|組み込むSCSI-ID
    .if SCSI_BIOS_LEVEL<=3
	pop_test
	addq.w	#1,d2			;次の組み込むSCSI-ID
	rts

;次のSCSI-IDへ
next_device:
	addq.w	#1,d2			;次の組み込むSCSI-ID
	goto	install_device

install_finish:
	pop
	moveq.l	#-1,d2
	rts
    .else
	bclr.b	d2,BIOS_SCSI_UNBOOTABLE.w	;このSCSI-IDは起動可能
	addq.w	#1,d2			;次の組み込むSCSI-ID
device_installer_end:
	pop
	rts

install_finish:
	moveq.l	#-1,d2
	goto	device_installer_end
    .endif

    .if SCSI_BIOS_LEVEL<=3
;----------------------------------------------------------------
;自動起動または使用可能なパーティションを数える
;<a1.l:パーティションテーブルの先頭
;>d3.w:パーティションの数
count_partition_1:
	push	d2/a1
	moveq.l	#15-1,d2
	moveq.l	#0,d3
	for	d2
		lea.l	16(a1),a1
		continue	<tst.b (a1)>,eq	;パーティションがない
		continue	<cmpi.l #'Huma',(a1)>,ne	;Human68kのパーティションではない
		continue	<cmpi.l #'n68k',4(a1)>,ne	;Human68kのパーティションではない
		move.b	8(a1),d0		;0=自動起動,1=使用不可,2=使用可能
		continue	<btst.l #0,d0>,ne	;使用不可
		addq.w	#1,d3			;自動起動または使用可能
	next
	pop
	rts

;----------------------------------------------------------------
;自動起動または使用可能なパーティションを数える
;	自動起動のパーティションで終了する
;<a1.l:パーティションテーブルの先頭
;>d3.w:パーティションの数
count_partition_2:
	push	d2/a1
	moveq.l	#15-1,d2
	moveq.l	#0,d3
	for	d2
		lea.l	16(a1),a1
		continue	<tst.b (a1)>,eq	;パーティションがない
		continue	<cmpi.l #'Huma',(a1)>,ne	;Human68kのパーティションではない
		continue	<cmpi.l #'n68k',4(a1)>,ne	;Human68kのパーティションではない
		move.b	8(a1),d0		;0=自動起動,1=使用不可,2=使用可能
		continue	<btst.l #0,d0>,ne	;使用不可
		addq.w	#1,d3			;自動起動または使用可能
		break	<tst.b d0>,eq		;自動起動
	next
	pop
	rts
    .else
;----------------------------------------------------------------
;自動起動または使用可能なパーティションを数える
;	起動したSCSI-IDのときは自動起動のパーティションで終了する
;<ccr:(現在のSCSI-ID)-(起動したSCSI-ID)
;<a1.l:パーティションテーブルの先頭
;>d3.w:パーティションの数
count_partition:
	push	d1/d2/a1
	seq.b	d1			;-1=(現在のSCSI-ID)==(起動したSCSI-ID)
	moveq.l	#15-1,d2
	moveq.l	#0,d3
	for	d2
		lea.l	16(a1),a1
		continue	<tst.b (a1)>,eq	;パーティションがない
		continue	<cmpi.l #'Huma',(a1)>,ne	;Human68kのパーティションではない
		continue	<cmpi.l #'n68k',4(a1)>,ne	;Human68kのパーティションではない
		move.b	8(a1),d0		;0=自動起動,1=使用不可,2=使用可能
		continue	<btst.l #0,d0>,ne	;使用不可
		addq.w	#1,d3			;自動起動または使用可能
		continue	<tst.b d1>,eq	;起動したSCSI-IDではない
		break	<tst.b d0>,eq		;起動したSCSI-IDで自動起動のとき終了
	next
	pop
	rts
    .endif

    .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;本体と同じSCSI-IDの機器がないか確認する(確認済みならば何もしない)
;>d0.l:本体と同じSCSI-IDの機器がないか。0=ある,-1=ない
check_confliction_2nd:
	moveq.l	#-1,d0
	goto	<tst.b BIOS_SCSI_NOT_CONFLICT.w>,ne,check_confliction_end
    .endif
;----------------------------------------------------------------
;本体と同じSCSI-IDの機器がないか確認する
;>d0.l:本体と同じSCSI-IDの機器がないか。0=ある,-1=ない
check_confliction_1st:
    .if SCSI_BIOS_LEVEL<=3
	movem.l	d4,-(sp)
    .else
	move.l	d4,-(sp)
	st.b	BIOS_SCSI_NOT_CONFLICT.w
    .endif
	move.b	SRAM_SCSI_MODE,d4	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
	andi.b	#7,d4			;本体のSCSI-ID
	moveq.l	#_SCSIDRV,d0
	moveq.l	#_S_TESTUNIT,d1
	trap	#15
	move.l	(sp)+,d4
check_confliction_end:
	rts

    .if SCSI_BIOS_LEVEL==10
;----------------------------------------------------------------
;ブロック長に応じてブロック番号とブロック数を調整する
;<d2.l:ブロック番号。256バイト/ブロック
;<d3.l:ブロック数。256バイト/ブロック
;<d5.w:ブロック長指数。0=256,1=512,2=1024,3=2048
;>d2.l:ブロック番号
;>d3.l:ブロック数
adjust_block_number:
	if	<cmpi.w #3,d5>,cs
		lsr.l	d5,d2
		lsr.l	d5,d3
		rts

	endif
	lsr.l	#2,d2
	lsr.l	#2,d3
	rts
    .endif
  .endif



;--------------------------------------------------------------------------------
;	.include	sc03break.s
;--------------------------------------------------------------------------------

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;TRAP#11(BREAK)
;	FDとHD関連のIOCSコール($40～$4F,$F5)の処理中でなければシッピングを行う
;<d0.b:bit0:0=BREAK(CTRL+C),1=SHIFT+BREAK(CTRL+S)
trap_11_break:
	push	d0-d7/a0-a6
	if	<btst.l #0,d0>,eq	;BREAK。SHIFT+BREAKではない
		move.w	(BIOS_IOCS_NUMBER)abs,d0	;実行中のIOCSコールの番号。-1=なし
		goto	<cmp.w #$0040,d0>,cs,do_eject_all
		ifand	<cmp.w #$0050,d0>,cc,<cmp.w #_SCSIDRV,d0>,ne
		do_eject_all:
			bsr	eject_all		;シッピングする
		endif
	endif
	pop
    .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;SASIハードディスク内蔵機にSCSIボードを取り付けるとBREAKキーでSASIハードディスクをシッピングする機能が失われる
;X68000 PRO[HD]の取扱説明書に「コンピュータ本体の動作中に[BREAK]キーを押したときにも、磁気ヘッドの退避作業を行うことができます」という記述がある
;+++++ BUG +++++
	rte
    .else
	move.l	BIOS_SCSI_OLD_TRAP11.w,-(sp)	;TRAP#11(BREAK)の元のベクタ
	rts
    .endif
  .endif



;--------------------------------------------------------------------------------
;	.include	sc04eject.s
;--------------------------------------------------------------------------------

  .if SCSI_BIOS_LEVEL<>4
;----------------------------------------------------------------
;シッピングする
eject_all:
	move.w	#$8000,d1
	do
		bsr	iocs_4F_B_EJECT		;IOCSコール$4F _B_EJECT
		add.w	#$0100,d1
	while	<cmp.w #$9000,d1>,cs
	rts
  .endif



;--------------------------------------------------------------------------------
;	.include	sc05iocs1.s
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;IOCSコール$F5 _SCSIDRV
;<d1.l:SCSIコール番号
iocs_F5_SCSIDRV:
	push	d1/dLEN/aBUF/a2/aSPC
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.l #$00000010,d1>,cs,scsi_00_0F	;SCSIコール$00～$0F
	goto	<cmp.l #$00000020,d1>,cs,scsi_10_1F	;SCSIコール$10～$1F
	goto	<cmp.l #$00000040,d1>,cs,scsi_20_3F	;SCSIコール$20～$3F
;+++++ BUG +++++
;SCSIコール$40以上を指定するとSCSIコール$00～$0Fのジャンプテーブルから外れて暴走する
	goto	<cmp.l #$00000020,d1>,cs,scsi_10_1F
;本来は
;	goto	<cmp.l #$00000050,d1>,cs,scsi_40_4F	;SCSIコール$40～$4F
;	goto	scsi_10_1F		;SCSIコール$50～
;+++++ BUG +++++
  .else
	moveq.l	#$10,d0
	goto	<cmp.l d0,d1>,cs,scsi_00_0F	;SCSIコール$00～$0F
	add.l	d0,d0
	goto	<cmp.l d0,d1>,cs,scsi_10_1F	;SCSIコール$10～$1F
	add.l	d0,d0
	goto	<cmp.l d0,d1>,cs,scsi_20_3F	;SCSIコール$20～$3F
	moveq.l	#$50,d0
	goto	<cmp.l d0,d1>,cs,scsi_40_4F	;SCSIコール$40～$4F
	goto	scsi_10_1F		;SCSIコール$50～
  .endif

;SCSIコール$00～$0F
scsi_00_0F:
	lea.l	jump_00_0F(pc),a2	;SCSIコール$00～$0Fのジャンプテーブル
	goto	scsi_go

;SCSIコール$20～$3F
scsi_20_3F:
  .if SCSI_BIOS_LEVEL<=4
	sub.l	#$00000020,d1
  .else
	moveq.l	#$20,d0
	sub.l	d0,d1
  .endif
	lea.l	jump_20_3F(pc),a2	;SCSIコール$20～$3Fのジャンプテーブル
	goto	scsi_go

;SCSIコール$40～$4F
scsi_40_4F:
  .if SCSI_BIOS_LEVEL<=4
	sub.l	#$00000040,d1
  .else
	moveq.l	#$40,d0
	sub.l	d0,d1
  .endif
	lea.l	jump_40_4F(pc),a2	;SCSIコール$40～$4Fのジャンプテーブル
scsi_go:
	lsl.l	#2,d1
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_IN_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	move.l	(a2,d1.w),d1
	adda.l	d1,a2
	jsr	(a2)
	pop_test
	rts

;SCSIコール$10～$1F
;SCSIコール$50～
scsi_10_1F:
	moveq.l	#-1,d0
	pop
	rts

;未定義のSCSIコール
scsi_XX_undefined:
	moveq.l	#-1,d0
	rts

;SCSIコール$00～$0Fのジャンプテーブル
jump_00_0F:
	.dc.l	scsi_00_S_RESET-jump_00_0F	;SCSIコール$00 _S_RESET
	.dc.l	scsi_01_S_SELECT-jump_00_0F	;SCSIコール$01 _S_SELECT
	.dc.l	scsi_02_S_SELECTA-jump_00_0F	;SCSIコール$02 _S_SELECTA
	.dc.l	scsi_03_S_CMDOUT-jump_00_0F	;SCSIコール$03 _S_CMDOUT
	.dc.l	scsi_04_S_DATAIN-jump_00_0F	;SCSIコール$04 _S_DATAIN
	.dc.l	scsi_05_S_DATAOUT-jump_00_0F	;SCSIコール$05 _S_DATAOUT
	.dc.l	scsi_06_S_STSIN-jump_00_0F	;SCSIコール$06 _S_STSIN
	.dc.l	scsi_07_S_MSGIN-jump_00_0F	;SCSIコール$07 _S_MSGIN
	.dc.l	scsi_08_S_MSGOUT-jump_00_0F	;SCSIコール$08 _S_MSGOUT
	.dc.l	scsi_09_S_PHASE-jump_00_0F	;SCSIコール$09 _S_PHASE
	.dc.l	scsi_0A_S_LEVEL-jump_00_0F	;SCSIコール$0A _S_LEVEL
	.dc.l	scsi_0B_S_DATAINI-jump_00_0F	;SCSIコール$0B _S_DATAINI
	.dc.l	scsi_0C_S_DATAOUTI-jump_00_0F	;SCSIコール$0C _S_DATAOUTI
  .if SCSI_BIOS_LEVEL<=4
	.dc.l	scsi_XX_undefined-jump_00_0F	;SCSIコール$0D _S_MSGOUTEXT
  .else
	.dc.l	scsi_0D_S_MSGOUTEXT-jump_00_0F	;SCSIコール$0D _S_MSGOUTEXT
  .endif
	.dc.l	scsi_XX_undefined-jump_00_0F	;SCSIコール$0E
	.dc.l	scsi_XX_undefined-jump_00_0F	;SCSIコール$0F

;SCSIコール$20～$3Fのジャンプテーブル
jump_20_3F:
	.dc.l	scsi_20_S_INQUIRY-jump_20_3F	;SCSIコール$20 _S_INQUIRY
	.dc.l	scsi_21_S_READ-jump_20_3F	;SCSIコール$21 _S_READ
	.dc.l	scsi_22_S_WRITE-jump_20_3F	;SCSIコール$22 _S_WRITE
	.dc.l	scsi_23_S_FORMAT-jump_20_3F	;SCSIコール$23 _S_FORMAT
	.dc.l	scsi_24_S_TESTUNIT-jump_20_3F	;SCSIコール$24 _S_TESTUNIT
	.dc.l	scsi_25_S_READCAP-jump_20_3F	;SCSIコール$25 _S_READCAP
	.dc.l	scsi_26_S_READEXT-jump_20_3F	;SCSIコール$26 _S_READEXT
	.dc.l	scsi_27_S_WRITEEXT-jump_20_3F	;SCSIコール$27 _S_WRITEEXT
	.dc.l	scsi_28_S_VERIFYEXT-jump_20_3F	;SCSIコール$28 _S_VERIFYEXT
	.dc.l	scsi_29_S_MODESENSE-jump_20_3F	;SCSIコール$29 _S_MODESENSE
	.dc.l	scsi_2A_S_MODESELECT-jump_20_3F	;SCSIコール$2A _S_MODESELECT
	.dc.l	scsi_2B_S_REZEROUNIT-jump_20_3F	;SCSIコール$2B _S_REZEROUNIT
	.dc.l	scsi_2C_S_REQUEST-jump_20_3F	;SCSIコール$2C _S_REQUEST
	.dc.l	scsi_2D_S_SEEK-jump_20_3F	;SCSIコール$2D _S_SEEK
	.dc.l	scsi_2E_S_READI-jump_20_3F	;SCSIコール$2E _S_READI
	.dc.l	scsi_2F_S_STARTSTOP-jump_20_3F	;SCSIコール$2F _S_STARTSTOP
	.dc.l	scsi_30_S_SEJECT-jump_20_3F	;SCSIコール$30 _S_SEJECT
	.dc.l	scsi_31_S_REASSIGN-jump_20_3F	;SCSIコール$31 _S_REASSIGN
	.dc.l	scsi_32_S_PAMEDIUM-jump_20_3F	;SCSIコール$32 _S_PAMEDIUM
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$33
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$34
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$35
	.dc.l	scsi_36_S_DSKINI-jump_20_3F	;SCSIコール$36 _S_DSKINI
	.dc.l	scsi_37_S_FORMATB-jump_20_3F	;SCSIコール$37 _S_FORMATB
	.dc.l	scsi_38_S_BADFMT-jump_20_3F	;SCSIコール$38 _S_BADFMT
	.dc.l	scsi_39_S_ASSIGN-jump_20_3F	;SCSIコール$39 _S_ASSIGN
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$3A
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$3B
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$3C
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$3D
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$3E
	.dc.l	scsi_XX_undefined-jump_20_3F	;SCSIコール$3F

;SCSIコール$40～$4Fのジャンプテーブル
jump_40_4F:
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$40
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$41
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$42
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$43
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$44
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$45
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$46
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$47
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$48
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$49
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$4A
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$4B
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$4C
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$4D
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$4E
	.dc.l	scsi_XX_undefined-jump_40_4F	;SCSIコール$4F



;--------------------------------------------------------------------------------
;	.include	sc06iocs2.s
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;SCSIコール$00 _S_RESET SPCの初期化とSCSIバスリセット
scsi_00_S_RESET:
	push	d1/a1/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;ハードウェアリセットを開始する
	move.b	#SPC_SCTL_RD|SPC_SCTL_AE,SPC_SCTL(aSPC)	;アービトレーションフェーズあり(SCSI)
  .if 10<=SCSI_BIOS_LEVEL
	sf.b	BIOS_SCSI_NOT_CONFLICT.w	;SCSI-ID衝突確認。$00=未確認,$FF=確認済み
  .endif
;SRAMを初期化する
	move.b	SRAM_SCSI_MAGIC,d0	;SCSIマジック。'V'($56)=初期化済み
	if	<cmpi.b #'V',d0>,ne	;SRAM未初期化
		move.b	#$31,SYSPORT_SRAM	;SRAM書き込み制御。$31=許可,その他=禁止
  .if (SCSI_BIOS_LEVEL<=0)|(10<=SCSI_BIOS_LEVEL)
    .if SCSIEXROM
		move.b	#$0F,SRAM_SCSI_MODE	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
    .else
		move.b	#$07,SRAM_SCSI_MODE	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
    .endif
  .else
		if	<cmpa.l #SPC_IN_BASE,aSPC>,eq	;内蔵
			move.b	#$07,SRAM_SCSI_MODE	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
		else				;拡張
			move.b	#$0F,SRAM_SCSI_MODE	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
		endif
  .endif
		move.b	#$00,SRAM_SCSI_SASI_FLAG	;SASIフラグ
		move.b	#'V',SRAM_SCSI_MAGIC	;SCSIマジック。'V'($56)=初期化済み
		move.b	#$00,SYSPORT_SRAM	;SRAM書き込み制御。$31=許可,その他=禁止
	endif
;SRAM初期化済み
;本体のSCSI-IDを設定する
	move.b	SRAM_SCSI_MODE,d0	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
	andi.b	#7,d0			;本体のSCSI-ID
	move.b	d0,SPC_BDID(aSPC)
;SPCのレジスタをクリアする
	moveq.l	#0,d0
	move.b	d0,SPC_SCMD(aSPC)
	move.b	d0,SPC_PCTL(aSPC)
	move.b	d0,SPC_TCH(aSPC)
	move.b	d0,SPC_TCM(aSPC)
	move.b	d0,SPC_TCL(aSPC)
	move.b	d0,SPC_TEMP(aSPC)
  .if 10<=SCSI_BIOS_LEVEL
	move.b	#$00,SPC_SDGC(aSPC)
	move.w	#512,BIOS_SCSI_BLOCK_SIZE.w	;SCSI機器のブロックサイズ
  .endif
;SPC割り込みを設定する
  .if SCSI_BIOS_LEVEL<=4
	moveq.l	#_B_INTVCS,d0
    .if SCSI_BIOS_LEVEL<=0
	moveq.l	#OFFSET_SPC_IN/4,d1	;内蔵SPC割り込みベクタ
    .else
	if	<cmpa.l #SPC_IN_BASE,aSPC>,eq	;内蔵
		moveq.l	#OFFSET_SPC_IN/4,d1	;内蔵SPC割り込みベクタ
	else				;拡張
		move.l	#OFFSET_SPC_EX/4,d1	;拡張SPC割り込みベクタ
	endif
    .endif
	lea.l	spc_interrupt_routine(pc),a1	;SPC割り込みルーチン
	trap	#15
  .else
    .if SCSIEXROM
	moveq.l	#OFFSET_SPC_EX/4,d1	;拡張SPC割り込みベクタ
    .else
	moveq.l	#OFFSET_SPC_IN/4,d1	;内蔵SPC割り込みベクタ
    .endif
	lea.l	spc_interrupt_routine(pc),a1	;SPC割り込みルーチン
	IOCS	_B_INTVCS
  .endif
;ハードウェアリセットを終了する
	move.b	#SPC_SCTL_AE,SPC_SCTL(aSPC)	;アービトレーションフェーズあり(SCSI)
  .if SCSI_BIOS_LEVEL<=4
	move.b	#$00,SPC_SDGC(aSPC)
  .endif
  .if SCSI_BIOS_LEVEL<=3
	move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
	move.w	#81-1,d0		;97.2us@10MHz
    .else
	move.w	#129-1,d0		;154.8us@10MHz
    .endif
	for	d0
	next
	move.w	(sp)+,d0
  .endif
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#100/50,d0		;100us
	bsr	wait_50us		;50us単位のウェイト
  .endif
;SCSIバスリセットを開始する
	move.b	#SPC_SCMD_RO,SPC_SCMD(aSPC)
  .if SCSI_BIOS_LEVEL<=3
	move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
	move.w	#201-1,d0		;241.2us@10MHz
    .else
	move.w	BIOS_MPU_SPEED_ROM.l,d0	;MPUクロック。X68000は10MHz*250/3=833、X68030は25MHz*500/3=4167。1ms間にdbraの空ループが何回回るか
	lsr.w	#2,d0			;250us
    .endif
	for	d0
	next
	move.w	(sp)+,d0
  .endif
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#250/50,d0		;250us
	bsr	wait_50us		;50us単位のウェイト
  .endif
;SCSIバスリセットを終了する
	move.b	#$00,SPC_SCMD(aSPC)
  .if SCSI_BIOS_LEVEL<=3
	move.w	#2000/10,d0		;2s
	for	d0
		move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
		move.w	#1000*10,d0		;10ms
    .else
		move.w	BIOS_MPU_SPEED_ROM.l,d0	;MPUクロック。X68000は10MHz*250/3=833、X68030は25MHz*500/3=4167。1ms間にdbraの空ループが何回回るか
		mulu.w	#10,d0			;10ms
    .endif
		for	d0
		next
		move.w	(sp)+,d0
	next
  .else
	move.l	#2000000/50,d0		;2s
	bsr	wait_50us		;50us単位のウェイト
  .endif
  .if 16<=SCSI_BIOS_LEVEL
;SCSI初期化済みフラグをセットする
    .if SCSIEXROM
	bset.b	#1,BIOS_SCSI_INITIALIZED.w
    .else
	bset.b	#0,BIOS_SCSI_INITIALIZED.w
    .endif
  .endif
	pop
	rts

;----------------------------------------------------------------
;SPC割り込みルーチン
spc_interrupt_routine:
	push	d0/d1/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	move.b	SPC_INTS(aSPC),d0
	move.b	d0,SPC_INTS(aSPC)	;INTSをクリア
	pop
	rte

;----------------------------------------------------------------
;SCSIコール$02 _S_SELECTA
;	アービトレーションフェーズとセレクションフェーズ(メッセージアウトフェーズあり)
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:終了コード。0=正常終了,その他=(INTS<<16)|PSNS
scsi_02_S_SELECTA:
  .if SCSI_BIOS_LEVEL<=4
ints	reg	SPC_INTS(aSPC)
	push	dID/d7/aSPC
  .else
aINTS	reg	a0
ints	reg	(a0)
	push	dID/d7/aINTS/aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	SPC_INTS(aSPC),aINTS
  .endif
	move.b	#SPC_PCTL_SR_S,SPC_PCTL(aSPC)	;Selectコマンドはセレクション
;現在のコマンドが終了するまで待つ
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP|SPC_SSTS_SRIN,d0
	while	ne
  .if 10<=SCSI_BIOS_LEVEL
	move.b	ints,ints		;INTSをクリア
  .endif
	move.b	#SPC_SCMD_CC_SA,SPC_SCMD(aSPC)	;Set ATN
  .if SCSI_BIOS_LEVEL<=0
	jmp	select_common		;ここから_S_SELECT、_S_SELECTA共通
  .else
	goto	select_common		;ここから_S_SELECT、_S_SELECTA共通
  .endif

;----------------------------------------------------------------
;SCSIコール$01 _S_SELECT
;	アービトレーションフェーズとセレクションフェーズ(メッセージアウトフェーズなし)
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:終了コード。0=正常終了,その他=(INTS<<16)|PSNS
scsi_01_S_SELECT:
	push_again
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	SPC_INTS(aSPC),aINTS
  .endif
	move.b	#SPC_PCTL_SR_S,SPC_PCTL(aSPC)	;Selectコマンドはセレクション
;現在のコマンドが終了するまで待つ
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP|SPC_SSTS_SRIN,d0
	while	ne
;ここから_S_SELECT、_S_SELECTA共通
select_common:
	andi.w	#7,dID			;ターゲットのSCSI-ID
  .if SCSI_BIOS_LEVEL<=4
	move.b	#1,d0
  .else
	moveq.l	#1,d0
  .endif
	lsl.b	dID,d0
	if	<btst.b dID,SRAM_SCSI_SASI_FLAG>,eq	;SCSI機器
		or.b	SPC_BDID(aSPC),d0	;ターゲットのSCSI-IDと本体のSCSI-IDを合わせる
  .if SCSI_BIOS_LEVEL<=4
		move.b	#SPC_SCTL_AE,SPC_SCTL(aSPC)	;アービトレーションフェーズあり(SCSI)
  .else
		bset.b	#SPC_SCTL_AE_BIT,SPC_SCTL(aSPC)	;アービトレーションフェーズあり(SCSI)
  .endif
	else				;SASI機器
  .if SCSI_BIOS_LEVEL<=4
		move.b	#$00,SPC_SCTL(aSPC)	;アービトレーションフェーズなし(SASI)
  .else
		bclr.b	#SPC_SCTL_AE_BIT,SPC_SCTL(aSPC)	;アービトレーションフェーズなし(SASI)
  .endif
	endif
;応答待ち時間とアービトレーション開始遅延時間を設定する
;	応答待ち時間
;		(9*65536+196*256+15)*200ns*2=256.006us
;	アービトレーション開始遅延時間
;		(3+6)*200ns～(3+7)*200ns=1.8us～2us
  .if (SCSI_BIOS_LEVEL<=4)|(16<=SCSI_BIOS_LEVEL)
	move.b	d0,SPC_TEMP(aSPC)	;ターゲットのSCSI-IDと自分のSCSI-IDを合わせたもの
	move.w	#(9<<8)|196,d0
	move.b	d0,SPC_TCM(aSPC)	;196
	lsr.w	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;9
	move.b	#3,SPC_TCL(aSPC)	;3
  .else
	swap.w	d0			;mask<<16
	move.w	#(9<<8)|196,d0		;(mask<<16)|(9<<8)|196
	lsl.l	#8,d0			;(mask<<24)|(9<<16)|(196<<8)
	move.b	#3,d0			;(mask<<24)|(9<<16)|(196<<8)|3
	movep.l	d0,SPC_TEMP(aSPC)	;ターゲットのSCSI-IDと自分のSCSI-IDを合わせたもの
					;9
					;196
					;3
  .endif
	move.b	ints,ints		;INTSをクリア
;セレクション開始
	move.b	#SPC_SCMD_CC_SL,SPC_SCMD(aSPC)
  .if SCSI_BIOS_LEVEL<=3
	move.w	d0,-(sp)
    .if SCSI_BIOS_LEVEL<=0
	move.w	#13-1,d0		;15.6us@10MHz
    .else
	move.w	#25-1,d0		;30us@10MHz
    .endif
	for	d0
	next
	move.w	(sp)+,d0
  .endif
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#50/50,d0		;50us
	bsr	wait_50us		;50us単位のウェイト
  .endif
  .if SCSI_BIOS_LEVEL<=3
	move.b	SPC_INTS(aSPC),d0
	if	eq
		move.b	SPC_SSTS(aSPC),d0
		goto	<btst.l #SPC_SSTS_INIT_BIT,d0>,eq,select_common	;イニシエータになっていない。セレクション失敗。アービトレーションからやり直す
	endif
  .elif SCSI_BIOS_LEVEL==4
;割り込みを待つ
	do
		move.b	ints,d0
		break	ne				;割り込みあり
	;+++++ BUG +++++
	;BUSY=0でも止まるようにしたかったようだがbtst.bがmove.bになっている
	;SSTSのビット5をテストするつもりでSSTSに5を書き込んでいる
	;常にneなのでBUSY=0では止まらない
	;ループの出口がもう1つあるので無限ループにならずに済んでいる
		move.b	#SPC_SSTS_BUSY_BIT,SPC_SSTS(aSPC)
	;+++++ BUG +++++
	while	ne
  .else
;BUSY=0または割り込みを待つ
	do
		move.b	ints,d0
		break	ne				;割り込みあり
		redo	<btst.b #SPC_SSTS_BUSY_BIT,SPC_SSTS(aSPC)>,ne
		goto	<tst.b SPC_SSTS(aSPC)>,pl,select_common	;SPC_SSTS_INIT_BIT
								;BUSY=0だがイニシエータになっていない。セレクション失敗。アービトレーションからやり直す
	while	f
  .endif
;割り込みを待つ
	do
  .if SCSI_BIOS_LEVEL==4
		move.b	SPC_SSTS(aSPC),d0
		goto	<btst.l #SPC_SSTS_INIT_BIT,d0>,eq,select_common	;イニシエータになっていない。セレクション失敗。アービトレーションからやり直す
  .endif
		move.b	ints,d0
	while	eq
	goto	<cmp.b #SPC_INTS_TO,d0>,eq,selection_timeout	;セレクションタイムアウト
  .if SCSI_BIOS_LEVEL<=4
	move.b	d0,ints			;INTSをクリア
  .else
	move.b	ints,ints		;INTSをクリア
  .endif
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,selection_no_error	;コマンド終了。セレクション正常終了
;セレクションエラー終了
selection_error:
	swap.w	d0
	move.b	SPC_PSNS(aSPC),d0
;セレクション終了
selection_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;セレクション正常終了
selection_no_error:
	moveq.l	#0,d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	selection_end		;セレクション終了
  .endif

  .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;どこからも参照されていない
	moveq.l	#-1,d0
    .if SCSI_BIOS_LEVEL<=4
	pop
	rts
    .else
	goto	selection_end		;セレクション終了
    .endif
;+++++ BUG +++++
  .endif

;セレクションタイムアウト
;	セレクション応答待ち監視時間
;		((0<<16)|(2<<8)|88)*200ns*2=240us
selection_timeout:
  .if SCSI_BIOS_LEVEL==4
	moveq.l	#50/50,d0
	bsr	wait_50us		;50us単位のウェイト
  .endif
  .if (SCSI_BIOS_LEVEL<=4)|(16<=SCSI_BIOS_LEVEL)
	move.b	#0,SPC_TEMP(aSPC)	;0
	move.l	#(0<<16)|(2<<8)|88,d0
	move.b	d0,SPC_TCL(aSPC)	;88
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;2
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;0
  .else
	move.l	#(0<<16)|(2<<8)|88,d0
	movep.l	d0,SPC_TEMP(aSPC)	;0
					;0
					;2
					;88
  .endif
	move.b	#SPC_INTS_TO,ints	;タイムアウトをクリア
  .if 4<=SCSI_BIOS_LEVEL
	moveq.l	#100/50,d0		;100us
	bsr	wait_50us		;50us単位のウェイト
  .endif
;割り込みを待つ
	do
		move.b	ints,d0
	while	eq
  .if SCSI_BIOS_LEVEL<=4
	move.b	d0,ints			;INTSをクリア
  .else
	move.b	ints,ints		;INTSをクリア
  .endif
	goto	<cmp.b #SPC_INTS_TO,d0>,eq,selection_timeout_2nd	;セレクションタイムアウト(2回目)
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,selection_no_error	;コマンド終了。セレクション正常終了
;コマンド終了ではない
	goto	selection_error		;セレクションエラー終了

;セレクションタイムアウト(2回目)
selection_timeout_2nd:
;BUSY=0を待つ
	do
		btst.b	#SPC_SSTS_BUSY_BIT,SPC_SSTS(aSPC)
	while	ne
	move.b	ints,ints		;INTSをクリア
  .if SCSI_BIOS_LEVEL<=4
	goto	<btst.b #SPC_SSTS_INIT_BIT,SPC_SSTS(aSPC)>,ne,selection_no_error	;イニシエータ。セレクション正常終了
  .else
	goto	<tst.b SPC_SSTS(aSPC)>,mi,selection_no_error	;SPC_SSTS_INIT_BIT
								;イニシエータ。セレクション正常終了
  .endif
;イニシエータではない
	goto	selection_error		;セレクションエラー終了

;----------------------------------------------------------------
;SCSIコール$03 _S_CMDOUT
;	コマンドアウトフェーズ
;<dLEN.l:コマンドの長さ。グループ0,1,5は不要。グループ0は6バイト、グループ1は10バイト、グループ5は12バイト
;<a1.l:コマンドのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_03_S_CMDOUT:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	move.b	(a1),d0
	andi.b	#7<<5,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.b #0.shl.5,d0>,eq,cmdout_group_0	;グループ0($00-$1F)
  .else
	goto	eq,cmdout_group_0	;グループ0($00-$1F)
  .endif
	goto	<cmp.b #1.shl.5,d0>,eq,cmdout_group_1	;グループ1($20-$3F)
	goto	<cmp.b #5.shl.5,d0>,eq,cmdout_group_5	;グループ5($A0-$BF)
	goto	cmdout_go

;グループ0($00-$1F)
cmdout_group_0:
	moveq.l	#6,dLEN			;グループ0のコマンドは6バイト
	goto	cmdout_go

;グループ1($20-$3F)
cmdout_group_1:
	moveq.l	#10,dLEN		;グループ1のコマンドは10バイト
	goto	cmdout_go

;グループ5($A0-$BF)
cmdout_group_5:
	moveq.l	#12,dLEN		;グループ5のコマンドは12バイト
cmdout_go:
;REQ=1を待つ
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,cmdout_disconnected	;切断
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,cmdout_disconnected	;切断
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0
	goto	<cmpi.b #SPC_CMDOUT_PHASE,d0>,ne,cmdout_error	;コマンドアウトフェーズではない。エラー終了
	bsr	dataout_cpu		;CPU転送で出力する
	swap.w	d0
	goto	ne,cmdout_error		;転送失敗。エラー終了
cmdout_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;エラー終了
cmdout_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	cmdout_end
  .endif

;切断
cmdout_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	cmdout_end
  .endif

;----------------------------------------------------------------
;SCSIコール$0C _S_DATAOUTI
;	データアウトフェーズ(ソフト転送)
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_0C_S_DATAOUTI:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1を待つ
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,dataouti_disconnected	;切断
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataouti_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0	;SPC_DATAOUT_PHASE
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAOUT_PHASE,d0>,ne,dataouti_error	;データアウトフェーズではない。エラー終了
  .else
	goto	ne,dataouti_error	;データアウトフェーズではない。エラー終了
  .endif
	bsr	dataouti_transfer	;SCSI出力(ソフト転送)
	swap.w	d0
	goto	ne,dataouti_error	;転送失敗。エラー終了
dataouti_end:
  .if SCSI_BIOS_LEVEL<=4
	popm_test
  .elif SCSI_BIOS_LEVEL<=10
	popm
  .else
	pop
  .endif
	rts

;エラー終了
dataouti_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	dataouti_end
  .endif

;切断
dataouti_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	dataouti_end
  .endif

;----------------------------------------------------------------
;SCSIコール$0B _S_DATAINI
;	データインフェーズ(ソフト転送)
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_0B_S_DATAINI:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1を待つ
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,dataini_disconnected	;切断
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataini_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAIN_PHASE,d0>,ne,dataini_error	;データインフェーズではない。エラー終了
  .else
	goto	<cmpi.b #SPC_DATAIN_PHASE,d0>,ne,dataini_error	;データインフェーズではない。エラー終了
  .endif
	bsr	dataini_transfer	;SCSI入力(ソフト転送)
	swap.w	d0
	goto	ne,dataini_error	;転送失敗。エラー終了
dataini_end:
  .if SCSI_BIOS_LEVEL<=4
	popm_test
  .elif SCSI_BIOS_LEVEL<=10
	popm
  .else
	pop
  .endif
	rts

;エラー終了
dataini_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	dataini_end
  .endif

;切断
dataini_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	dataini_end
  .endif

;----------------------------------------------------------------
;SCSIコール$06 _S_STSIN
;	ステータスインフェーズ
;	ステータスバイト
;		$00 --00000-	Good
;		$02 --00001-	Check Condition
;		$04 --00010-	Condition Met
;		$08 --00100-	Busy
;		$10 --01000-	Intermediate
;		$14 --01010-	Intermediate-Condition Met
;		$18 --01100-	Reservation Conflict
;		$22 --10001-	Command Terminated
;		$28 --10100-	Queue Full
;		その他		リザーブ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_06_S_STSIN:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1を待つ
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,stsin_disconnected	;切断
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,stsin_disconnected	;切断
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_STSIN_PHASE,d0>,ne,stsin_error	;ステータスインフェーズではない。エラー終了
  .else
	goto	<cmpi.b #SPC_STSIN_PHASE,d0>,ne,stsin_error	;ステータスインフェーズではない。エラー終了
  .endif
;転送する
	moveq.l	#1,dLEN			;データの長さ
	bsr	datain_cpu		;CPU転送で入力する
	swap.w	d0
	goto	ne,stsin_error		;転送失敗。エラー終了
stsin_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;エラー終了
stsin_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	stsin_end
  .endif

;切断
stsin_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	stsin_end
  .endif

;----------------------------------------------------------------
;SCSIコール$07 _S_MSGIN
;	メッセージインフェーズ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_07_S_MSGIN:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	moveq.l	#1,dLEN			;データの長さ
  .endif
;REQ=1を待つ
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,msgin_disconnected	;切断
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,msgin_disconnected	;切断
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_MSGIN_PHASE,d0>,ne,msgin_error	;メッセージインフェーズではない。エラー終了
  .else
	goto	<cmpi.b #SPC_MSGIN_PHASE,d0>,ne,msgin_error	;メッセージインフェーズではない。エラー終了
  .endif
;転送する
  .if SCSI_BIOS_LEVEL<=4
	moveq.l	#1,dLEN			;データの長さ
  .endif
	bsr	datain_cpu		;CPU転送で入力する
	swap.w	d0
	goto	ne,msgin_error	;転送失敗。エラー終了
msgin_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;エラー終了
msgin_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	msgin_end
  .endif

;切断
msgin_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	msgin_end
  .endif

;----------------------------------------------------------------
;SCSIコール$08 _S_MSGOUT
;	メッセージアウトフェーズ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_08_S_MSGOUT:
	push	dLEN/aSPC
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,aSPC
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	moveq.l	#1,dLEN			;データの長さ
  .endif
;ここから_S_MSGOUT、_S_MSGOUTEXT共通
msgout_common:
;REQ=1を待つ
	do
  .if SCSI_BIOS_LEVEL<=4
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,msgout_disconnected	;切断
  .else
		goto	<btst.b #SPC_INTS_DC_BIT,SPC_INTS(aSPC)>,ne,msgout_disconnected	;切断
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_MSGOUT_PHASE,d0>,ne,msgout_error	;メッセージアウトフェーズではない。エラー終了
  .else
	goto	<cmpi.b #SPC_MSGOUT_PHASE,d0>,ne,msgout_error	;メッセージアウトフェーズではない。エラー終了
  .endif
;転送する
  .if SCSI_BIOS_LEVEL<=4
	moveq.l	#1,dLEN			;データの長さ
  .endif
	bsr	dataouti_transfer	;SCSI出力(ソフト転送)
	swap.w	d0
	goto	ne,msgout_error
msgout_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

;エラー終了
msgout_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	pop_test
	rts
  .else
	goto	msgout_end
  .endif

;切断
msgout_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	msgout_end
  .endif

  .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;SCSIコール$0D _S_MSGOUTEXT
;	拡張メッセージアウトフェーズ
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,-1=切断,その他=(INTS<<16)|PSNS
scsi_0D_S_MSGOUTEXT:
	push	dLEN/aSPC
	movea.l	spc_base_handle(pc),aSPC	;SPCベースハンドル
	move.b	2(aBUF),d0
	goto	eq,msgoutext_0
	subq.b	#2,d0
	goto	cs,msgoutext_1
	goto	eq,msgoutext_2
	subq.b	#1,d0
	goto	eq,msgoutext_2
	goto	msgout_common		;ここから_S_MSGOUT、_S_MSGOUTEXT共通

msgoutext_0:
	moveq.l	#5,dLEN
	goto	msgoutext_go

msgoutext_1:
	moveq.l	#3,dLEN
	goto	msgoutext_go

msgoutext_2:
	moveq.l	#2,dLEN
msgoutext_go:
	move.b	#1,(aBUF)
	move.b	dLEN,1(aBUF)
	addq.l	#2,dLEN
	goto	msgout_common		;ここから_S_MSGOUT、_S_MSGOUTEXT共通
  .endif

;----------------------------------------------------------------
;SCSIコール$09 _S_PHASE
;	フェーズセンス
;>d0.l:現在のフェーズ
scsi_09_S_PHASE:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,a6
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
	moveq.l	#0,d0
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=10
	popm
  .else
	pop
  .endif
	rts

;----------------------------------------------------------------
;SCSIコール$0A _S_LEVEL
;	バージョン
;	バージョンが3以下のときFORMAT.XがSCSIハードディスクに書き込んだSCSIデバイスドライバがバージョン4に差し替える
;>d0.l:バージョン
scsi_0A_S_LEVEL:
	moveq.l	#SCSI_BIOS_LEVEL,d0
	rts


  .if SCSI_BIOS_LEVEL<=4


;----------------------------------------------------------------
;SCSI出力(ソフト転送)
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,その他=INTS
dataouti_transfer:
	push	dLEN/aBUF
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1を待つ
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;転送開始
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;イニシエータで転送中を待つ
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;ターゲットで転送中？
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne
;1バイトずつ転送する
	do
		break	<tst.b SPC_INTS(aSPC)>,ne	;割り込みあり
		redo	<btst.b #SPC_SSTS_DF_BIT,SPC_SSTS(aSPC)>,ne	;FIFOがフルでなくなるまで待つ
		move.b	(aBUF)+,SPC_DREG(aSPC)
		subq.l	#1,dLEN
	while	ne
;割り込みを待つ
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	d0,SPC_INTS(aSPC)	;INTSをクリア
	if	<cmp.b #SPC_INTS_CC,d0>,ne
		pop_test
		rts

	endif
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(ソフト転送)
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,その他=INTS
dataini_transfer:
	push	dLEN/aBUF
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
;転送開始
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;イニシエータで転送中を待つ
dataini_wait:
	do
		move.b	SPC_SSTS(aSPC),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;ターゲットで転送中？
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne
;1バイトずつ転送する
dataini_loop:
;+++++ BUG +++++
;Service Requiredに対応していない
;	最後のデータを送信した後、ACKがFalseになるのを待たずにステータスインフェーズに移行してしまうハードディスクがあるらしい
;	最後のデータをFIFOから取り出し終わるまで本体はデータインフェーズなので、
;	フェーズの不一致で割り込み要因のService Requiredがセットされる可能性がある
;	Service Requiredがセットされると転送が中断してしまい、FIFOに残っていた最後のデータを受け取り損ねる可能性がある
;+++++ BUG +++++
	do
	;FIFOが空でなくなるまで待つ
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataini_interrupted	;割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;FIFOから1バイト読み込む
		move.b	SPC_DREG(aSPC),(aBUF)+
		subq.l	#1,dLEN
	while	ne
dataini_interrupted:
;割り込みを待つ
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	d0,SPC_INTS(aSPC)	;INTSをクリア
	if	<cmp.b #SPC_INTS_CC,d0>,ne
		pop_test
		rts

	endif
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;CPU転送で出力する
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0
dataout_cpu:
	push	dLEN/aBUF
dataout_cpu_loop:
	do
	;フェーズをセットする
		move.b	SPC_PSNS(aSPC),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1を待つ
	dataout_cpu_wait_1:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
	;1バイト出力する
		move.b	(aBUF)+,SPC_TEMP(aSPC)
		move.b	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Set ACK
	;REQ=0を待つ
	dataout_cpu_wait_2:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,ne
		move.b	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
dataout_cpu_end:
	pop
	rts

;----------------------------------------------------------------
;CPU転送で入力する
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0
datain_cpu:
	push	dLEN/aBUF
datain_cpu_loop:
	do
	;フェーズをセットする
		move.b	SPC_PSNS(aSPC),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1を待つ
	datain_cpu_wait_1:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
		move.b	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Set ACK
	;REQ=0を待つ
	datain_cpu_wait_2:
		do
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,ne
	;1バイト入力する
		move.b	SPC_TEMP(aSPC),(aBUF)+
		move.b	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,SPC_SCMD(aSPC)	;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
	pop
	rts


  .else


;----------------------------------------------------------------
;SCSI出力(ソフト転送)
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,その他=INTS
dataouti_transfer:
aINTS	reg	a2
aSSTS	reg	a3
aDREG	reg	a4
	push	d1/d2/dLEN/dID/aBUF/aINTS/aSSTS/aDREG
	lea.l	SPC_INTS(aSPC),aINTS
	lea.l	SPC_SSTS(aSPC),aSSTS
	lea.l	SPC_DREG(aSPC),aDREG
;長さが0のとき256と見なす
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;長さをセットする
    .if SCSI_BIOS_LEVEL<=10
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
    .else
	move.b	#0,SPC_TEMP(aSPC)
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
    .endif
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1を待つ
	do
	while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
;転送開始
	move.b	(aINTS),(aINTS)		;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;イニシエータで転送中を待つ
	do
		move.b	(aSSTS),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
    .if SCSI_BIOS_LEVEL<=10
	;+++++ BUG +++++
	;ターゲットのときループカウンタのd2を設定せずにループに飛び込んでいる
		goto	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq,dataouti_target	;ターゲットで転送中？
	;+++++ BUG +++++
    .else
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;ターゲットで転送中？
    .endif
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne	;イニシエータで転送中を待つ

    .if SCSI_BIOS_LEVEL<=10

;イニシエータで転送中
	move.l	dLEN,d0
	lsr.l	#3,d0			;長さ/8
	goto	eq,dataouti_less_than_8	;8バイト未満
;8バイト以上
;<d0.l:長さ/8
	move.l	d0,d2
dataouti_target:
;8バイトずつ転送する
	do
	;FIFOが空になるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,dataouti_finish	;割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,eq	;FIFOが空になるまで待つ
	;FIFOに8バイト書き込む
	;+++++ BUG +++++
	;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
	;+++++ BUG +++++
		move.l	(aBUF)+,d0
		move.b	d0,d1
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		move.b	d1,(aDREG)
	;+++++ BUG +++++
	;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
	;+++++ BUG +++++
		move.l	(aBUF)+,d0
		move.b	d0,d1
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		rol.l	#8,d0
		move.b	d0,(aDREG)
		move.b	d1,(aDREG)
		subq.l	#1,d2
	while	ne
;8バイト未満
dataouti_less_than_8:
	and.w	#7,dLEN
	beq	dataouti_finish
;1バイトずつ転送する
	subq.w	#1,dLEN
	for	dLEN
		break	<tst.b (aINTS)>,ne	;割り込みあり
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,ne	;FIFOがフルでなくなるまで待つ
		move.b	(aBUF)+,(aDREG)
	next
;後始末
dataouti_finish:
	do
		move.b	(aINTS),d0
	while	eq			;割り込みを待つ
	move.b	d0,(aINTS)		;INTSをクリア
	if	<cmp.b #SPC_INTS_CC,d0>,eq
		moveq.l	#0,d0
	endif
;+++++ BUG +++++
;INTSを返すときd0.lの上位バイトにゴミが入る
;+++++ BUG +++++
	pop
	rts

    .else

	move.w	aBUF,d0
	gotoand	<lsr.w #1,d0>,cs,<is68000 d0>,eq,dataouti_1byte	;aBUFが奇数かつ68000である。1バイトずつ転送する
;aBUFが偶数または68000でない
;8バイトずつ転送する
	while	<subq.l #8,dLEN>,hs
		goto	<tst.b (aINTS)>,ne,dataouti_finish	;割り込みあり
		redo	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,eq	;FIFOが空になるまで待つ
	;8バイト転送する。途中でFIFOがフルになっていないか確認しない
	  .rept 2
		move.l	(aBUF)+,d0
	    .rept 4
		rol.l	#8,d0
		move.b	d0,(aDREG)
	    .endm
	  .endm
	endwhile
	addq.l	#8,dLEN
;1バイトずつ転送する
dataouti_1byte:
	while	<subq.l #1,dLEN>,hs
		goto	<tst.b (aINTS)>,ne,dataouti_finish	;割り込みあり
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,ne	;FIFOがフルでなくなるまで待つ
	;1バイト転送する
		move.b	(aBUF)+,(aDREG)
	endwhile
;後始末
dataouti_finish:
	moveq.l	#0,d0
	do
		move.b	(aINTS),d0
	while	eq			;割り込みを待つ
	move.b	d0,(aINTS)		;INTSをクリア
	if	<cmp.b #SPC_INTS_CC,d0>,eq	;Command Complete
		moveq.l	#0,d0
	endif
	pop
	rts

    .endif

;----------------------------------------------------------------
;SCSI入力(ソフト転送)
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0=正常終了,その他=INTS
dataini_transfer:
aINTS	reg	a2
aSSTS	reg	a3
aDREG	reg	a4
	push	d1/d2/dLEN/aBUF/aINTS/aSSTS/aDREG
	lea.l	SPC_INTS(aSPC),aINTS
	lea.l	SPC_SSTS(aSPC),aSSTS
	lea.l	SPC_DREG(aSPC),aDREG
;長さが0のとき256と見なす
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さをセットする
    .if SCSI_BIOS_LEVEL<=10
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
    .else
	move.b	#0,SPC_TEMP(aSPC)
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
    .endif
;転送開始
	move.b	(aINTS),(aINTS)		;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;イニシエータで転送中を待つ
	do
		move.b	(aSSTS),d0
		andi.b	#SPC_SSTS_INIT|SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0
    .if SCSI_BIOS_LEVEL<=10
	;+++++ BUG +++++
	;ターゲットのときループカウンタのd2を設定せずにループに飛び込んでいる
		goto	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq,dataini_target	;ターゲットで転送中？
	;+++++ BUG +++++
    .else
		break	<cmp.b #SPC_SSTS_TARG|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,eq	;ターゲットで転送中？
    .endif
	while	<cmp.b #SPC_SSTS_INIT|SPC_SSTS_BUSY|SPC_SSTS_TRIP,d0>,ne	;イニシエータで転送中を待つ

    .if SCSI_BIOS_LEVEL<=10

;イニシエータで転送中
	goto	<tst.b SRAM_SCSI_MODE>,mi,dataini_block_transfer	;SCSI設定。ブロック|タイプ無視|バースト|ソフト|拡張|本体###
									;ブロック転送
;バイト転送
dataini_byte_transfer:
	move.l	dLEN,d0
	lsr.l	#3,d0			;長さ/8
	goto	eq,dataini_less_than_8	;8バイト未満
;8バイト以上
;<d0.l:長さ/8
	move.l	d0,d2
dataini_target:
;8バイトずつ転送する
	do
	;FIFOがフルになるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,dataini_finish	;割り込みあり
		while	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq
	;FIFOから8バイト読み込む
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
	;+++++ BUG +++++
	;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
	;+++++ BUG +++++
		move.l	d0,(aBUF)+
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
		lsl.l	#8,d0
		move.b	(aDREG),d0
	;+++++ BUG +++++
	;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
	;+++++ BUG +++++
		move.l	d0,(aBUF)+
		subq.l	#1,d2
	while	ne
;8バイト未満
dataini_less_than_8:
	and.w	#7,dLEN
	goto	eq,dataini_finish
;1バイトずつ転送する
;+++++ BUG +++++
;Service Requiredに対応していない
;	最後のデータを送信した後、ACKがFalseになるのを待たずにステータスインフェーズに移行してしまうハードディスクがあるらしい
;	最後のデータをFIFOから取り出し終わるまで本体はデータインフェーズなので、
;	フェーズの不一致で割り込み要因のService Requiredがセットされる可能性がある
;	Service Requiredがセットされると転送が中断してしまい、FIFOに残っていた最後のデータを受け取り損ねる可能性がある
;+++++ BUG +++++
	subq.w	#1,dLEN
	for	dLEN
		goto	<tst.b (aINTS)>,ne,dataini_finish	;割り込みあり
		redo	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,ne	;FIFOが空
		move.b	(aDREG),(aBUF)+		;FIFOから1バイト読み込む
	next
;後始末
dataini_finish:
	do
		move.b	(aINTS),d0
	while	eq			;割り込みを待つ
	move.b	d0,(aINTS)		;INTSをクリア
	if	<cmp.b #SPC_INTS_CC,d0>,eq
		moveq.l	#0,d0
	endif
;+++++ BUG +++++
;INTSを返すときd0.lの上位バイトにゴミが入る
;+++++ BUG +++++
	pop
	rts

;ブロック転送
dataini_block_transfer:
	moveq.l	#0,d2
	move.w	BIOS_SCSI_BLOCK_SIZE.w,d2	;SCSI機器のブロックサイズ
	goto	<cmp.l d2,dLEN>,cs,dataini_byte_transfer	;ブロックサイズ未満。バイト転送
	divu.w	d2,dLEN			;端数*$10000+ブロック数
	lsr.l	#4,d2			;ブロックサイズ/16
;1ブロックずつ転送する
	subq.l	#1,d2			;ブロックサイズ/16-1
	do
	;FIFOがフルになるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,dataini_finish	;割り込みあり
		while	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq
	;FIFOから1ブロック読み込む。途中でFIFOが空になっていないか確認しない
		move.w	d2,d1
		for	d1
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
			lsl.l	#8,d0
			move.b	(aDREG),d0
		;+++++ BUG +++++
		;68000でバッファのアドレスが奇数のときアドレスエラーが発生する
		;+++++ BUG +++++
			move.l	d0,(aBUF)+
		next
		subq.w	#1,dLEN
	while	ne
	swap.w	dLEN			;0*$10000+端数
	goto	dataini_byte_transfer	;バイト転送

    .else

	move.w	aBUF,d0
	gotoand	<lsr.w #1,d0>,cs,<is68000 d0>,eq,dataini_1byte	;aBUFが奇数かつ68000である。1バイトずつ転送する
;aBUFが偶数または68000でない
	goto	<tst.b SRAM_SCSI_MODE>,pl,dataini_8bytes	;SRAM_SCSI_BLOCK_BIT。ブロック転送しない。8バイトずつ転送する
;ブロック転送する
	moveq.l	#0,d2
	move.w	BIOS_SCSI_BLOCK_SIZE.w,d2	;SCSI機器のブロックサイズ。0でなく16で割り切れること
	while	<sub.l d2,dLEN>,hs
		move.b	(aINTS),d0
		if	ne			;割り込みあり
			add.l	d2,dLEN
			goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataini_1byte	;Service RequiredのときFIFOが空になるまで1バイトずつ転送する
			goto	dataini_finish		;それ以外は中止
		endif
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq	;FIFOがフルになるまで待つ
	;1ブロック転送する。途中でFIFOが空になっていないか確認しない
		move.w	d2,d1
		lsr.w	#4,d1
		subq.w	#1,d1			;ブロックサイズ/16-1
		for	d1
		;16バイト転送する
		  .rept 4
			move.b	(aDREG),d0
			lsl.w	#8,d0
			move.b	(aDREG),d0
			swap.w	d0
			move.b	(aDREG),d0
			lsl.w	#8,d0
			move.b	(aDREG),d0
			move.l	d0,(aBUF)+
		  .endm
		next
	endwhile
	add.l	d2,dLEN
;8バイトずつ転送する
dataini_8bytes:
	while	<subq.l #8,dLEN>,hs
		move.b	(aINTS),d0
		if	ne			;割り込みあり
			addq.l	#8,dLEN
			goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataini_1byte	;Service RequiredのときFIFOが空になるまで1バイトずつ転送する
			goto	dataini_finish		;それ以外は中止
		endif
		redo	<btst.b #SPC_SSTS_DF_BIT,(aSSTS)>,eq	;FIFOがフルになるまで待つ
	;8バイト転送する。途中でFIFOが空になっていないか確認しない
	  .rept 2
		move.b	(aDREG),d0
		lsl.w	#8,d0
		move.b	(aDREG),d0
		swap.w	d0
		move.b	(aDREG),d0
		lsl.w	#8,d0
		move.b	(aDREG),d0
		move.l	d0,(aBUF)+
	  .endm
	endwhile
	addq.l	#8,dLEN
;1バイトずつ転送する
dataini_1byte:
	while	<subq.l #1,dLEN>,hs
		move.b	(aINTS),d0
		if	ne			;割り込みあり
			ifor	<btst.l #SPC_INTS_SR_BIT,d0>,eq,<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,ne	;Service RequiredでないまたはFIFOが空のとき
				addq.l	#1,dLEN
				goto	dataini_finish
			endif
			;Service RequiredかつFIFOが空でないとき割り込みを無視する
		endif
		redo	<btst.b #SPC_SSTS_DE_BIT,(aSSTS)>,ne	;FIFOが空でなくなるまで待つ
	;1バイト転送する
		move.b	(aDREG),(aBUF)+
	endwhile
	addq.l	#1,dLEN
;後始末
dataini_finish:
	moveq.l	#0,d0
	do
		move.b	(aINTS),d0
	while	eq			;割り込みを待つ
	move.b	d0,(aINTS)		;INTSをクリア
	moveq.l	#.notb.(SPC_INTS_CC|SPC_INTS_SR),d1
	and.b	d0,d1
	ifand	<>,eq,<tst.l dLEN>,eq	;Command CompleteまたはService Requiredで最後まで転送した
		moveq.l	#0,d0
	endif
	pop
	rts

    .endif

;----------------------------------------------------------------
;CPU転送で出力する
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0
dataout_cpu:
aPSNS	reg	a2
aSCMD	reg	a3
	push	d1/d2/dLEN/aBUF/aPSNS/aSCMD
	lea.l	SPC_PSNS(aSPC),aPSNS
	lea.l	SPC_SCMD(aSPC),aSCMD
	moveq.l	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,d1	;Set ACK
	moveq.l	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,d2	;Reset ACK
	do
	;フェーズをセットする
		move.b	(aPSNS),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1を待つ
		do
		while	<tst.b (aPSNS)>,pl	;SPC_PSNS_REQ_BIT
	;1バイト出力する
		move.b	(aBUF)+,SPC_TEMP(aSPC)
		move.b	d1,(aSCMD)		;Set ACK
	;REQ=0を待つ
		do
		while	<tst.b (aPSNS)>,mi	;SPC_PSNS_REQ_BIT
		move.b	d2,(aSCMD)		;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;CPU転送で入力する
;<dLEN.l:データの長さ
;<a1.l:バッファのアドレス
;>d0.l:0
datain_cpu:
aPSNS	reg	a2
aSCMD	reg	a3
	push	d1/d2/dLEN/aBUF/aPSNS/aSCMD
	lea.l	SPC_PSNS(aSPC),aPSNS
	lea.l	SPC_SCMD(aSPC),aSCMD
	moveq.l	#SPC_SCMD_CC_SR|SPC_SCMD_IT|SPC_SCMD_PT,d1	;Set ACK
	moveq.l	#SPC_SCMD_CC_RR|SPC_SCMD_IT|SPC_SCMD_PT,d2	;Reset ACK
	do
	;フェーズをセットする
		move.b	(aPSNS),d0
		andi.b	#SPC_PHASE_MASK,d0
		move.b	d0,SPC_PCTL(aSPC)
	;REQ=1を待つ
		do
		while	<tst.b (aPSNS)>,pl	;SPC_PSNS_REQ_BIT
		move.b	d1,(aSCMD)		;Set ACK
	;REQ=0を待つ
		do
		while	<tst.b (aPSNS)>,mi	;SPC_PSNS_REQ_BIT
	;1バイト入力する
		move.b	SPC_TEMP(aSPC),(aBUF)+
		move.b	d2,(aSCMD)		;Reset ACK
		subq.l	#1,dLEN
	while	ne
	moveq.l	#0,d0
	pop
	rts


  .endif


  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Test Unit Readyコマンド
test_unit_ready_command:
	.dc.b	$00			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$24 _S_TESTUNIT
;	動作テスト
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_24_S_TESTUNIT:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
  .if SCSI_BIOS_LEVEL<=0
	lea.l	test_unit_ready_command,a2	;Test Unit Readyコマンド
  .else
	lea.l	test_unit_ready_command(pc),a2	;Test Unit Readyコマンド
  .endif
	bsr	no_dataio_command	;データインフェーズ／データアウトフェーズのない6バイトのコマンド
	pop
	unlk	a5
	rts

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Rezero Unitコマンド
rezero_unit_command:
	.dc.b	$01			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$2B _S_REZEROUNIT
;	状態設定
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_2B_S_REZEROUNIT:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
  .if SCSI_BIOS_LEVEL<=0
	lea.l	rezero_unit_command,a2	;Rezero Unitコマンド
  .else
	lea.l	rezero_unit_command(pc),a2	;Rezero Unitコマンド
  .endif
	bsr	no_dataio_command	;データインフェーズ／データアウトフェーズのない6バイトのコマンド
	pop
	unlk	a5
	rts

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read(6)コマンド
read_6_command_2nd:
	.dc.b	$08			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|論理ブロックアドレス(上位)#####
	.dc.b	$00			;2 論理ブロックアドレス(中位)
	.dc.b	$00			;3 論理ブロックアドレス(下位)
	.dc.b	$00			;4 転送データ長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$2E _S_READI
;<d2.l:ブロック番号
;<dLEN.l:ブロック数
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
;<a1.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_2E_S_READI:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
	movea.l	a1,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	read_6_command_2nd,a2	;Read(6)コマンド
    .else
	lea.l	read_6_command_2nd(pc),a2	;Read(6)コマンド
    .endif
	lea.l	-16(a5),a1
  .else
	lea.l	-16(a5),a1
	lea.l	read_6_command_2nd(pc),a2	;Read(6)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(a1)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),a1
	move.b	d6,3(a1)		;ブロック番号(下位)
	lsr.l	#8,d6
	move.b	d6,2(a1)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(a1)		;ブロック番号(上位)
  .else
	lea.l	-16(a5),a1
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(a1)			;ブロック番号
  .endif
	move.b	dLEN,4(a1)		;ブロック数
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
	goto	<tst.l d0>,ne,readcap_error
;データインフェーズ
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;ブロック長指数が4以上のとき3と見なす
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,a1
  .if SCSI_BIOS_LEVEL<=0
	bsr	scsi_0B_S_DATAINI	;SCSIコール$0B _S_DATAINI
  .else
	bsr	scsi_04_S_DATAIN	;SCSIコール$04 _S_DATAIN
  .endif
;ステータスインフェーズとメッセージインフェーズ
	goto	<cmpi.l #-1,d0>,eq,readcap_error
  .if 3<=SCSI_BIOS_LEVEL
	if	<cmpi.l #-2,d0>,ne
		bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	readi_end:
    .if SCSI_BIOS_LEVEL<=4
		pop_test
    .else
		pop
    .endif
		unlk	a5
		rts
	endif
  .endif
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
    .if 3<=SCSI_BIOS_LEVEL
	if	<tst.l d0>,eq
		moveq.l	#-2,d0
	endif
    .endif
	pop
	unlk	a5
	rts
  .else
	goto	<tst.l d0>,ne,readi_end
	moveq.l	#-2,d0
	goto	readi_end
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read Capacityコマンド
read_capacity_command:
	.dc.b	$25			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved####|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 Reserved
	.dc.b	$00			;8 Reserved#######|PMI
	.dc.b	$00			;9 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$25 _S_READCAP
;	容量確認
;<dID.l:(LUN<<16)|SCSI-ID
;<a1.l:バッファのアドレス
;	0	論理ブロックアドレス(上位)
;	1	  :
;	2	  :
;	3	論理ブロックアドレス(下位)
;	4	ブロック長(上位)
;	5	  :
;	6	  :
;	7	ブロック長(下位)
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_25_S_READCAP:
	link.w	a5,#-16
	push	d1/dLEN/d6/a1/a2/a3
	movea.l	a1,a3
;コマンドを作る
	lea.l	-16(a5),a1
  .if SCSI_BIOS_LEVEL<=0
	lea.l	read_capacity_command,a2	;Read Capacityコマンド
  .else
	lea.l	read_capacity_command(pc),a2	;Read Capacityコマンド
  .endif
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(a1)+
	next
;セレクションフェーズとコマンドアウトフェーズ
	lea.l	-16(a5),a1
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
	goto	<tst.l d0>,ne,readcap_error
;データインフェーズ
	movea.l	a3,a1
	moveq.l	#8,dLEN			;データの長さ
	bsr	scsi_0B_S_DATAINI	;SCSIコール$0B _S_DATAINI
	goto	<cmpi.l #-1,d0>,eq,readcap_error
;ステータスインフェーズとメッセージインフェーズ
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
readcap_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	unlk	a5
	rts

readcap_error:
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	pop
	unlk	a5
	rts
  .else
	goto	readcap_end
  .endif

;----------------------------------------------------------------
;セレクションフェーズとコマンドアウトフェーズ
;<dID.l:(LUN<<16)|SCSI-ID
;<a1.l:コマンド
;>d0.l:0=成功,-1=失敗
select_and_cmdout:
	push	d1/dID
;セレクションフェーズ
	move.w	#2-1,d1
	for	d1
		bsr	scsi_01_S_SELECT	;SCSIコール$01 _S_SELECT
  .if SCSI_BIOS_LEVEL<=4
		goto	<tst.l d0>,eq,select_and_cmdout_cmdout
	next
	goto	select_and_cmdout_error
  .else
	next	<tst.l d0>,ne
	goto	ne,select_and_cmdout_error
  .endif
;コマンドアウトフェーズ
select_and_cmdout_cmdout:
	swap.w	dID
	lsl.b	#5,dID			;LUN<<5
	or.b	dID,1(a1)		;LUN
	bsr	scsi_03_S_CMDOUT	;SCSIコール$03 _S_CMDOUT
	goto	<tst.l d0>,ne,select_and_cmdout_error
	moveq.l	#0,d0			;成功
select_and_cmdout_end:
  .if SCSI_BIOS_LEVEL<=4
	pop_test
  .else
	pop
  .endif
	rts

select_and_cmdout_error:
	moveq.l	#-1,d0			;失敗
  .if SCSI_BIOS_LEVEL<=4
	pop
	rts
  .else
	goto	select_and_cmdout_end
  .endif

;----------------------------------------------------------------
;データインフェーズ／データアウトフェーズのない6バイトのコマンド
;<a2.l:コマンドのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
no_dataio_command:
	lea.l	-16(a5),a1
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(a1)+
	next
	lea.l	-16(a5),a1
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
	goto	<tst.l d0>,ne,stsin_and_msgin_error
;----------------------------------------------------------------
;ステータスインフェーズとメッセージインフェーズ
;>d0.l:(MSGIN<<16)|STSIN
stsin_and_msgin:
	lea.l	-1(a5),a1
	bsr	scsi_06_S_STSIN		;SCSIコール$06 _S_STSIN
	goto	<tst.l d0>,ne,stsin_and_msgin_error
	lea.l	-2(a5),a1
	bsr	scsi_07_S_MSGIN		;SCSIコール$07 _S_MSGIN
	goto	<tst.l d0>,ne,stsin_and_msgin_error
	move.b	-2(a5),d0		;MSGIN
	swap.w	d0
	move.b	-1(a5),d0		;(MSGIN<<16)|STSIN
	rts

stsin_and_msgin_error:
	moveq.l	#-1,d0
	rts

  .if 4<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;50us単位のウェイト
;<d0.l:時間(50us単位)
wait_50us:
aTCDR	reg	a0
	push	d0/d1/d2/aTCDR
	lea.l	MFP_TCDR,aTCDR
	moveq.l	#0,d1
	move.b	(aTCDR),d1
	move.b	(aTCDR),d1
	do
		moveq.l	#0,d2
		move.b	(aTCDR),d2
		redo	<cmp.b (aTCDR),d2>,cs
		sub.w	d2,d1
		if	cs
			add.w	#200,d1
		endif
		exg.l	d1,d2
		sub.l	d2,d0
	while	hi
	pop
	rts
  .endif



;--------------------------------------------------------------------------------
;	.include	sc07iocs3.s
;--------------------------------------------------------------------------------

;----------------------------------------------------------------
;SCSIコール$05 _S_DATAOUT データアウトフェーズ
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_05_S_DATAOUT:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,a6
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1を待つ
dataout_wait:
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,dataout_disconnected	;切断
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,dataout_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0	;SPC_DATAOUT_PHASE
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAOUT_PHASE,d0>,ne,dataout_error	;データアウトフェーズではない。エラー終了
  .else
	goto	ne,dataout_error	;データアウトフェーズではない。エラー終了
  .endif
;転送開始
	bsr	dataout_transfer	;SCSI出力(DMA転送)
	swap.w	d0
	if	eq
	dataout_end:
  .if SCSI_BIOS_LEVEL<=4
		popm_test
  .elif SCSI_BIOS_LEVEL<=10
		popm
  .else
		pop
  .endif
		rts
	endif
  .if 3<=SCSI_BIOS_LEVEL
	if	<tst.w d0>,ne
		swap.w	d0
    .if SCSI_BIOS_LEVEL<=4
		popm_test
		rts
    .else
		goto	dataout_end
    .endif
	endif
  .endif
;エラー終了
dataout_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	dataout_end
  .endif

;切断
dataout_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	dataout_end
  .endif

;----------------------------------------------------------------
;SCSIコール$04 _S_DATAIN
;	データインフェーズ
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_04_S_DATAIN:
  .if SCSI_BIOS_LEVEL<=10
	pushm	aSPC
  .else
	push	aSPC
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	SPC_BASE,a6
  .else
	movea.l	spc_base_handle(pc),aSPC
  .endif
;REQ=1を待つ
	do
		move.b	SPC_INTS(aSPC),d0
		goto	<btst.l #SPC_INTS_DC_BIT,d0>,ne,datain_disconnected	;切断
  .if 10<=SCSI_BIOS_LEVEL
		goto	<btst.l #SPC_INTS_SR_BIT,d0>,ne,datain_error
  .endif
		move.b	SPC_PSNS(aSPC),d0	;SPC_PSNS_REQ_BIT
  .if SCSI_BIOS_LEVEL<=4
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
  .else
	while	pl
  .endif
;フェーズを確認する
	andi.b	#SPC_PHASE_MASK,d0
  .if SCSI_BIOS_LEVEL<=4
;+++++ BUG +++++
;余分な命令
	andi.b	#SPC_PHASE_MASK,d0
;+++++ BUG +++++
  .endif
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmp.b #SPC_DATAIN_PHASE,d0>,ne,datain_error	;データインフェーズではない。エラー終了
  .else
	goto	<cmpi.b #SPC_DATAIN_PHASE,d0>,ne,datain_error	;データインフェーズではない。エラー終了
  .endif
;転送開始
	bsr	datain_transfer		;SCSI入力(DMA転送)
	swap.w	d0
	if	eq
	datain_end:
  .if SCSI_BIOS_LEVEL<=4
		popm_test
  .elif SCSI_BIOS_LEVEL<=10
		popm
  .else
		pop
  .endif
		rts

	endif
  .if 3<=SCSI_BIOS_LEVEL
	goto	<tst.w d0>,eq,datain_error
	swap.w	d0
    .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
    .else
	goto	datain_end
    .endif
  .endif
;エラー終了
datain_error:
	move.b	SPC_PSNS(aSPC),d0
  .if SCSI_BIOS_LEVEL<=4
	popm_test
	rts
  .else
	goto	datain_end
  .endif

;切断
datain_disconnected:
	bsr	scsi_00_S_RESET		;SCSIコール$00 _S_RESET
	moveq.l	#-1,d0
  .if SCSI_BIOS_LEVEL<=4
	popm
	rts
  .else
	goto	datain_end
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Inquiryコマンド
inquiry_command:
	.dc.b	$12			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved####|EVPD
	.dc.b	$00			;2 ページコード
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 アロケーション長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$20 _S_INQUIRY
;	INQUIRYデータの要求
;	最初にアロケーション長に5を指定して追加データ長を得る
;	続いてアロケーション長に5+追加データ長を指定して追加データを得る
;<dLEN.l:アロケーション長
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;	0	クォリファイア###|デバイスタイプコード#####
;		クォリファイア
;			0	ロジカルユニットが接続されている
;			1	ロジカルユニットが接続されていない
;			3	ロジカルユニットが存在しない
;		デバイスタイプコード
;			$00	ダイレクトアクセスデバイス。磁気ディスクなど
;			$01	シーケンシャルアクセスデバイス。磁気テープなど
;			$02	プリンタデバイス
;			$03	プロセッサデバイス
;			$04	ライトワンスデバイス。追記型光ディスクなど
;			$05	CD-ROMデバイス
;			$06	スキャナデバイス
;			$07	光メモリデバイス。イレーザブル光ディスクなど
;			$08	メディアチェンジャデバイス。磁気テープライブラリ、光ディスクライブラリなど
;			$09	コミュニケーションデバイス
;			$84	SHARP MO
;	1	RMB|デバイスタイプ修飾子#######
;		RMB
;			0	固定
;			1	可換
;	2	ISOバージョン##|ECMAバージョン###|ANSIバージョン###
;		bit7-6	ISOバージョン(通常は0)
;		bit5-3	ECMAバージョン(通常は0)
;		bit2-0	ANSIバージョン
;			0	未適合
;			1	SCSI-1。ANSI X3.131-1986準拠
;			2	SCSI-2。ANSI X3T9.2/86-109準拠
;	3	AENC|TrmlOP|Reserved##|レスポンスデータ形式####
;	4	追加データ長(なければ0)
;	5～	追加データ
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_20_S_INQUIRY:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	inquiry_command,a2	;Inquiryコマンド
    .else
	lea.l	inquiry_command(pc),a2	;Inquiryコマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	inquiry_command(pc),a2	;Inquiryコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;アロケーション長
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データインフェーズ
	movea.l	a3,aBUF
	bsr	scsi_0B_S_DATAINI	;SCSIコール$0B _S_DATAINI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Request Senseコマンド
request_sense_command:
	.dc.b	$03			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 アロケーション長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$2C _S_REQUEST
;	センスデータの要求
;<dLEN.l:アロケーション長
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_2C_S_REQUEST:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	request_sense_command,a2	;Request Senseコマンド
    .else
	lea.l	request_sense_command(pc),a2	;Request Senseコマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	request_sense_command(pc),a2	;Request Senseコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;アロケーション長
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データインフェーズ
	movea.l	a3,aBUF
	bsr	scsi_0B_S_DATAINI	;SCSIコール$0B _S_DATAINI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Mode Sense(6)コマンド
mode_sense_6_command:
	.dc.b	$1A			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|R|DBD|Reserved###
	.dc.b	$00			;2 PC##|ページコード######
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 アロケーション長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$29 _S_MODESENSE
;	モードセンス
;<d2.l:(PC<<6)|ページコード
;	PC	0	現在
;		1	変更可能ビットマスク
;		2	デフォルト
;		3	保存
;	ページコード63はすべてのパラメータページを取得
;<dLEN.l:アロケーション長。4以上
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;	モードパラメータヘッダ
;	0	モードパラメータ長
;		返却できるパラメータリストのバイト数。モードパラメータヘッダを含まない。8の倍数
;	1	メディアタイプ
;	2	デバイス固有パラメータ
;		ダイレクトアクセスデバイスのデバイス固有パラメータ
;		WP#|Reserved##|DPOFUA|Reserved####
;		ビット7が1のとき書き込み禁止
;	3	ブロックディスクリプタ長
;		返却されたパラメータリストのバイト数。モードパラメータヘッダを含まない。8の倍数
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_29_S_MODESENSE:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	mode_sense_6_command,a2	;Mode Sense(6)コマンド
    .else
	lea.l	mode_sense_6_command(pc),a2	;Mode Sense(6)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	mode_sense_6_command(pc),a2	;Mode Sense(6)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;アロケーション長
  .if 3<=SCSI_BIOS_LEVEL
	move.b	d2,2(aBUF)		;(PC<<6)|ページコード。PC:0=現在,1=変更可能ビットマスク,2=デフォルト,3=保存
  .endif
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データインフェーズ
	movea.l	a3,aBUF
	bsr	scsi_0B_S_DATAINI	;SCSIコール$0B _S_DATAINI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Mode Select(6)コマンド
mode_select_6_command:
	.dc.b	$15			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|PF|Reserved###|SP
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 パラメータリスト長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$2A _S_MODESELECT
;	モードセレクト
;<d2.l:PF<<4|SP
;	PF	0	SCSI-1
;		1	SCSI-2
;	SP	0	保存しない
;		1	保存する
;<dLEN.l:パラメータリスト長
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_2A_S_MODESELECT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	mode_select_6_command,a2	;Mode Select(6)コマンド
    .else
	lea.l	mode_select_6_command(pc),a2	;Mode Select(6)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	mode_select_6_command(pc),a2	;Mode Select(6)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;パラメータリスト長
  .if 3<=SCSI_BIOS_LEVEL
	move.b	d2,1(aBUF)		;PF<<4|SP。PF:0=SCSI-1,1=SCSI-2。SP:0=保存しない,1=保存する
  .endif
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データアウトフェーズ
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSIコール$0C _S_DATAOUTI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Reassign Blocksコマンド
reassign_blocks_command:
	.dc.b	$07			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$31 _S_REASSIGN
;	再配置
;
;ディフェクトリスト
;	ヘッダ
;	  0 Reserved
;	  1 Reserved
;	  2 ディフェクトリスト長4*n(上位)
;	  3 ディフェクトリスト長4*n(下位)
;	ディフェクトディスクリプタ
;	  4+4*0+0 不良ブロックの論理ブロックアドレス(上位)
;	  4+4*0+1   :
;	  4+4*0+2   :
;	  4+4*0+3 不良ブロックの論理ブロックアドレス(下位)
;	    :
;	  4+4*(n-1)+0 不良ブロックの論理ブロックアドレス(上位)
;	  4+4*(n-1)+1   :
;	  4+4*(n-1)+2   :
;	  4+4*(n-1)+3 不良ブロックの論理ブロックアドレス(下位)
;
;<dLEN.l:データの長さ
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_31_S_REASSIGN:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	reassign_blocks_command,a2	;Reassign Blocksコマンド
    .else
	lea.l	reassign_blocks_command(pc),a2	;Reassign Blocksコマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	reassign_blocks_command(pc),a2	;Reassign Blocksコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
;セレクションフェーズとコマンドアウトフェーズ
	lea.l	-16(a5),aBUF
  .if SCSI_BIOS_LEVEL<=3
;+++++ BUG +++++
;Reservedのフィールドに書き込んでいる
	move.b	#8,4(aBUF)
;+++++ BUG +++++
  .endif
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データアウトフェーズ
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSIコール$0C _S_DATAOUTI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read(6)コマンド
read_6_command:
	.dc.b	$08			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|論理ブロックアドレス(上位)#####
	.dc.b	$00			;2 論理ブロックアドレス(中位)
	.dc.b	$00			;3 論理ブロックアドレス(下位)
	.dc.b	$00			;4 転送データ長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$21 _S_READ
;	読み込み
;<d2.l:ブロック番号
;<dLEN.l:ブロック数
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_21_S_READ:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	read_6_command,a2	;Read(6)コマンド
    .else
	lea.l	read_6_command(pc),a2	;Read(6)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	read_6_command(pc),a2	;Read(6)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),aBUF
	move.b	d6,3(aBUF)		;ブロック番号(上位)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;ブロック番号(下位)
  .else
	lea.l	-16(a5),aBUF
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;ブロック番号
  .endif
	move.b	dLEN,4(aBUF)		;ブロック数
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データインフェーズ
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;ブロック長指数が4以上のとき3と見なす
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_04_S_DATAIN	;SCSIコール$04 _S_DATAIN
  .else
	lea.l	scsi_04_S_DATAIN(pc),a0	;SCSIコール$04 _S_DATAIN
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;ソフト
		lea.l	scsi_0B_S_DATAINI(pc),a0	;SCSIコール$0B _S_DATAINI
	endif
	jsr	(a0)
  .endif
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_2	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Write(6)コマンド
write_6_command:
	.dc.b	$0A			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|論理ブロックアドレス(上位)#####
	.dc.b	$00			;2 論理ブロックアドレス(中位)
	.dc.b	$00			;3 論理ブロックアドレス(下位)
	.dc.b	$00			;4 転送データ長
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$22 _S_WRITE
;	書き出し
;<d2.l:ブロック番号
;<dLEN.l:ブロック数
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_22_S_WRITE:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	write_6_command,a2	;Write(6)コマンド
    .else
	lea.l	write_6_command(pc),a2	;Write(6)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	write_6_command(pc),a2	;Write(6)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),aBUF
	move.b	d6,3(aBUF)		;ブロック番号(下位)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;ブロック番号(上位)
  .else
	lea.l	-16(a5),aBUF
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;ブロック番号
  .endif
	move.b	dLEN,4(aBUF)		;ブロック数
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データアウトフェーズ
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;ブロック長指数が4以上のとき3と見なす
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_05_S_DATAOUT	;SCSIコール$05 _S_DATAOUT
  .else
	lea.l	scsi_05_S_DATAOUT(pc),a0	;SCSIコール$05 _S_DATAOUT
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;ソフト
		lea.l	scsi_0C_S_DATAOUTI(pc),a0	;SCSIコール$0C _S_DATAOUTI
	endif
	jsr	(a0)
  .endif
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_2	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Read(10)コマンド
read_10_command:
	.dc.b	$28			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 転送データ長(上位)
	.dc.b	$00			;8 転送データ長(下位)
	.dc.b	$00			;9 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$26 _S_READEXT
;	拡張読み込み
;<d2.l:ブロック番号
;<dLEN.l:ブロック数
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_26_S_READEXT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
  .if 10<=SCSI_BIOS_LEVEL
	goto	<tst.w dLEN>,eq,writeext_error_1
  .endif
	movea.l	aBUF,a3
;コマンドを作る
	lea.l	-16(a5),aBUF
  .if SCSI_BIOS_LEVEL<=0
	lea.l	read_10_command,a2	;Read(10)コマンド
  .else
	lea.l	read_10_command(pc),a2	;Read(10)コマンド
  .endif
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	dLEN,d6
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	move.l	dLEN,d6
  .endif
	move.l	d2,2(aBUF)		;ブロック番号
	move.b	dLEN,8(aBUF)		;ブロック数(下位)
	lsr.l	#8,dLEN
	move.b	dLEN,7(aBUF)		;ブロック数(上位)
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データインフェーズ
	move.l	d6,dLEN
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;ブロック長指数が4以上のとき3と見なす
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_04_S_DATAIN	;SCSIコール$04 _S_DATAIN
  .else
	lea.l	scsi_04_S_DATAIN(pc),a0	;SCSIコール$04 _S_DATAIN
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;ソフト
		lea.l	scsi_0B_S_DATAINI(pc),a0	;SCSIコール$0B _S_DATAINI
	endif
	jsr	(a0)
  .endif
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_2	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Write(10)コマンド
write_10_command:
	.dc.b	$2A			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 転送データ長(上位)
	.dc.b	$00			;8 転送データ長(下位)
	.dc.b	$00			;9 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$27 _S_WRITEEXT
;	拡張書き出し
;<d2.l:ブロック番号
;<dLEN.l:ブロック数
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_27_S_WRITEEXT:
	link.w	a5,#-16
	push	d1/dLEN/d6/aBUF/a2/a3
  .if 10<=SCSI_BIOS_LEVEL
	goto	<tst.w dLEN>,eq,writeext_error_1
  .endif
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	write_10_command,a2	;Write(10)コマンド
    .else
	lea.l	write_10_command(pc),a2	;Write(10)コマンド
    .endif
;ここから_S_WRITEEXT、_S_VERIFYEXT共通
writeext_verifyext_common:
	movea.l	aBUF,a3
  .else
	movea.l	aBUF,a3
  .endif
;コマンドを作る
	lea.l	-16(a5),aBUF
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	write_10_command(pc),a2	;Write(10)コマンド
  .endif
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if 10<=SCSI_BIOS_LEVEL
	lea.l	-16(a5),aBUF
;ここから_S_WRITEEXT、_S_VERIFYEXT共通
writeext_verifyext_common:
  .endif
	move.l	dLEN,d6
  .if SCSI_BIOS_LEVEL<=4
	lea.l	-16(a5),aBUF
  .endif
	move.l	d2,2(aBUF)		;ブロック番号
	move.b	dLEN,8(aBUF)		;ブロック数(下位)
	lsr.l	#8,dLEN
	move.b	dLEN,7(aBUF)		;ブロック数(上位)
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データアウトフェーズ
	move.l	d6,dLEN
	lsl.l	#8,dLEN
  .if SCSI_BIOS_LEVEL<=10
	lsl.l	d5,dLEN
  .else
;ブロック長指数が4以上のとき3と見なす
	moveq.l	#3,d0
	if	<cmp.l d0,d5>,lo
		move.l	d5,d0
	endif
	lsl.l	d0,dLEN
  .endif
	movea.l	a3,aBUF
  .if SCSI_BIOS_LEVEL<=4
	bsr	scsi_05_S_DATAOUT	;SCSIコール$05 _S_DATAOUT
  .else
	lea.l	scsi_05_S_DATAOUT(pc),a0	;SCSIコール$05 _S_DATAOUT
	if	<btst.b #SRAM_SCSI_SOFT_BIT,SRAM_SCSI_MODE>,ne	;ソフト
		lea.l	scsi_0C_S_DATAOUTI(pc),a0	;SCSIコール$0C _S_DATAOUTI
	endif
	jsr	(a0)
  .endif
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
    .if 3<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
    .endif
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop_test
	unlk	a5
	rts
  .else
writeext_stsin_2:
	goto	<cmpi.l #-1,d0>,eq,writeext_error_1
	goto	<cmpi.l #-2,d0>,eq,writeext_error_2
	goto	writeext_stsin_0

;ステータスインフェーズとメッセージインフェーズ
writeext_stsin_x:
	goto	<tst.l d0>,ne,writeext_error_1
writeext_stsin_0:
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
writeext_end:
	pop_test
	unlk	a5
	rts

;ステータスインフェーズとメッセージインフェーズ
writeext_stsin_1:
	goto	<cmpi.l #-1,d0>,ne,writeext_stsin_0
writeext_error_1:
	moveq.l	#-1,d0
	goto	writeext_end
  .endif

  .if 3<=SCSI_BIOS_LEVEL
writeext_error_2:
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	if	<tst.l d0>,eq
		moveq.l	#-2,d0
	endif
	pop
	unlk	a5
	rts
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Verify(10)コマンド
verify_10_command:
	.dc.b	$2F			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|DPO|Reserved##|BytChk|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 転送データ長(上位)
	.dc.b	$00			;8 転送データ長(下位)
	.dc.b	$00			;9 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$28 _S_VERIFYEXT
;	拡張ベリファイ
;<d2.l:ブロック番号
;<dLEN.l:ブロック数
;<dID.l:(LUN<<16)|SCSI-ID
;<d5.l:ブロック長指数。0=256,1=512,2=1024,3=2048
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_28_S_VERIFYEXT:
	link.w	a5,#-16
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .if 10<=SCSI_BIOS_LEVEL
	goto	<tst.w dLEN>,eq,writeext_error_1
  .endif
  .if SCSI_BIOS_LEVEL<=0
	lea.l	verify_10_command,a2	;Verify(10)コマンド
  .elif SCSI_BIOS_LEVEL<=4
	lea.l	verify_10_command(pc),a2	;Verify(10)コマンド
  .else
	movea.l	aBUF,a3
;コマンドを作る
	lea.l	-16(a5),aBUF
	lea.l	verify_10_command(pc),a2	;Verify(10)コマンド
	moveq.l	#10-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
  .endif
;ここから_S_WRITEEXT、_S_VERIFYEXT共通
	goto	writeext_verifyext_common

;----------------------------------------------------------------
;Format Unitコマンド
format_unit_command:
	.dc.b	$04			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|FmtData|CmpLst|ディフェクトリスト形式###
	.dc.b	$00			;2 ベンダ固有
	.dc.b	$00			;3 インタリーブ(上位)
	.dc.b	$00			;4 インタリーブ(下位)
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;SCSIコール$23 _S_FORMAT
;	フォーマット
;<dLEN.l:インタリーブ
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_23_S_FORMAT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	format_unit_command,a2	;Format Unitコマンド
    .else
	lea.l	format_unit_command(pc),a2	;Format Unitコマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	format_unit_command(pc),a2	;Format Unitコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.b	dLEN,4(aBUF)		;インタリーブ(下位)
	lsr.l	#8,dLEN
	move.b	dLEN,3(aBUF)		;インタリーブ(上位)
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Prevent-Allow Medium Removalコマンド
prevent_allow_command:
	.dc.b	$1E			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved#######|Prevent
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$32 _S_PAMEDIUM
;	イジェクト許可／イジェクト禁止
;<dLEN.l:0=イジェクト許可,1=イジェクト禁止
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_32_S_PAMEDIUM:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	prevent_allow_command,a2	;Prevent-Allow Medium Removalコマンド
    .else
	lea.l	prevent_allow_command(pc),a2	;Prevent-Allow Medium Removalコマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	prevent_allow_command(pc),a2	;Prevent-Allow Medium Removalコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	andi.b	#1,dLEN
	move.b	dLEN,4(aBUF)		;0=イジェクト許可,1=イジェクト禁止
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Start-Stop Unit(Eject SONY MO)コマンド
start_stop_unit_command:
	.dc.b	$1B			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved####|Immed
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved######|LoEj|Start
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$2F _S_STARTSTOP
;	操作許可／操作禁止
;<dLEN.l:0=操作禁止,1=操作許可,2=アンロード,3=ロード
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_2F_S_STARTSTOP:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	start_stop_unit_command,a2	;Start-Stop Unit(Eject SONY MO)コマンド
    .else
	lea.l	start_stop_unit_command(pc),a2	;Start-Stop Unit(Eject SONY MO)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	start_stop_unit_command(pc),a2	;Start-Stop Unitコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	andi.b	#3,dLEN
	move.b	dLEN,4(aBUF)		;0=操作禁止,1=操作許可,2=アンロード,3=ロード
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Load/Unload SHARP MOコマンド
load_unload_command:
	.dc.b	$C1			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|#####
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4 #######|LoEj
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;SCSIコール$30 _S_SEJECT
;	イジェクト(SHARP MO)
;	SUSIE.Xでは_S_EJECT6MO1と呼ばれている
;<dLEN.l:0=アンロード,1=ロード
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_30_S_SEJECT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	load_unload_command,a2	;Load/Unload SHARP MOコマンド
    .else
	lea.l	load_unload_command(pc),a2	;Load/Unload SHARP MOコマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	load_unload_command(pc),a2	;Load/Unload SHARP MOコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	andi.b	#1,dLEN
	move.b	dLEN,4(aBUF)		;0=アンロード,1=ロード
;セレクションフェーズとコマンドアウトフェーズ
	moveq.l	#6,dLEN			;長さ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Seek(6)コマンド
seek_6_command:
	.dc.b	$0B			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|ブロック番号(上位)#####
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$2D _S_SEEK
;	シーク
;<d2.l:ブロック番号
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_2D_S_SEEK:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	seek_6_command,a2	;Seek(6)コマンド
    .else
	lea.l	seek_6_command(pc),a2	;Seek(6)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	seek_6_command(pc),a2	;Seek(6)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	d2,d6
	lea.l	-16(a5),aBUF
	move.b	d6,3(aBUF)		;ブロック番号(下位)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;ブロック番号(上位)
  .else
	lea.l	-16(a5),aBUF
	move.l	d2,d6
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;ブロック番号
  .endif
;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=3
;+++++ BUG +++++
;Reservedのフィールドに書き込んでいる
	move.b	dLEN,4(aBUF)
;+++++ BUG +++++
  .endif
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Assign Drive(SASI)コマンド
assign_drive_sasi_command:
	.dc.b	$C2			;0 オペレーションコード
	.dc.b	$00			;1
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4
	.dc.b	$00			;5 データの長さ
  .endif

;----------------------------------------------------------------
;SCSIコール$36 _S_DSKINI
;	Assign Drive(SASI)
;<dLEN.l:データの長さ
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_36_S_DSKINI:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	assign_drive_sasi_command,a2	;Assign Drive(SASI)コマンド
    .else
	lea.l	assign_drive_sasi_command(pc),a2	;Assign Drive(SASI)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	assign_drive_sasi_command(pc),a2	;Assign Drive(SASI)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
  .if SCSI_BIOS_LEVEL<=4
	move.l	dLEN,d1
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	move.l	dLEN,d1
  .endif
	move.b	d1,5(aBUF)		;データの長さ
;セレクションフェーズとコマンドアウトフェーズ
	moveq.l	#6,dLEN
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データアウトフェーズ
	move.l	d1,dLEN
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSIコール$0C _S_DATAOUTI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Format Block(SASI)コマンド
format_block_sasi_command:
	.dc.b	$06			;0 オペレーションコード
	.dc.b	$00			;1 ブロック番号(上位)
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 インタリーブ
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;SCSIコール$37 _S_FORMATB
;	Format Block(SASI)
;<d2.l:ブロック番号
;<dLEN.l:インタリーブ
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_37_S_FORMATB:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	format_block_sasi_command,a2	;Format Block(SASI)コマンド
    .else
	lea.l	format_block_sasi_command(pc),a2	;Format Block(SASI)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	format_block_sasi_command(pc),a2	;Format Blockコマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.l	d2,d6
  .if SCSI_BIOS_LEVEL<=4
	move.b	d6,3(aBUF)		;ブロック番号(下位)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;ブロック番号(上位)
  .else
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;ブロック番号
  .endif
	move.b	dLEN,4(aBUF)		;インタリーブ
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Bad Track Format(SASI)コマンド
bad_track_format_sasi_command:
	.dc.b	$07			;0 オペレーションコード
	.dc.b	$00			;1 ブロック番号(上位)
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 インタリーブ
	.dc.b	$00			;5 コントロールバイト
  .endif

;----------------------------------------------------------------
;SCSIコール$38 _S_BADFMT
;	Bad Track Format(SASI)
;<d2.l:ブロック番号
;<dLEN.l:インタリーブ
;<dID.l:(LUN<<16)|SCSI-ID
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_38_S_BADFMT:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	bad_track_format_sasi_command,a2	;Bad Track Format(SASI)コマンド
    .else
	lea.l	bad_track_format_sasi_command(pc),a2	;Bad Track Format(SASI)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	bad_track_format_sasi_command(pc),a2	;Bad Track Format(SASI)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.l	d2,d6
  .if SCSI_BIOS_LEVEL<=4
	move.b	d6,3(aBUF)		;ブロック番号(下位)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;ブロック番号(上位)
  .else
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;ブロック番号
  .endif
	move.b	dLEN,4(aBUF)		;インタリーブ
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_x
  .endif

  .if 3<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;Assign Track(SASI)コマンド
assign_track_sasi_command:
	.dc.b	$0E			;0 オペレーションコード
	.dc.b	$00			;1 ブロック番号(上位)
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 インタリーブ
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;SCSIコール$39 _S_ASSIGN
;	Assign Track(SASI)
;<d2.l:ブロック番号
;<dLEN.l:インタリーブ
;<dID.l:(LUN<<16)|SCSI-ID
;<aBUF.l:バッファのアドレス
;>d0.l:0=成功,-1=失敗,その他=(MSGIN<<16)|STSIN
scsi_39_S_ASSIGN:
	link.w	a5,#-16
  .if SCSI_BIOS_LEVEL<=4
	push	d1/dLEN/d6/aBUF/a2/a3
  .else
	movem.l	d1/dLEN/d6/aBUF/a2/a3,-(sp)
  .endif
	movea.l	aBUF,a3
;コマンドを作る
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	assign_track_sasi_command,a2	;Assign Track(SASI)コマンド
    .else
	lea.l	assign_track_sasi_command(pc),a2	;Assign Track(SASI)コマンド
    .endif
	lea.l	-16(a5),aBUF
  .else
	lea.l	-16(a5),aBUF
	lea.l	assign_track_sasi_command(pc),a2	;Assign Track(SASI)コマンド
  .endif
	moveq.l	#6-1,d1
	for	d1
		move.b	(a2)+,(aBUF)+
	next
	lea.l	-16(a5),aBUF
	move.l	d2,d6
  .if SCSI_BIOS_LEVEL<=4
	move.b	d6,3(aBUF)		;ブロック番号(下位)
	lsr.l	#8,d6
	move.b	d6,2(aBUF)		;ブロック番号(中位)
	lsr.l	#8,d6
	move.b	d6,1(aBUF)		;ブロック番号(上位)
  .else
	and.l	#$00FFFFFF,d6
	or.l	d6,(aBUF)		;ブロック番号
  .endif
	move.b	dLEN,4(aBUF)		;インタリーブ
;セレクションフェーズとコマンドアウトフェーズ
	bsr	select_and_cmdout	;セレクションフェーズとコマンドアウトフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<tst.l d0>,ne,assign_error
  .else
	goto	<tst.l d0>,ne,writeext_error_1
  .endif
;データアウトフェーズ
	moveq.l	#4,dLEN			;長さ
	movea.l	a3,aBUF
	bsr	scsi_0C_S_DATAOUTI	;SCSIコール$0C _S_DATAOUTI
;ステータスインフェーズとメッセージインフェーズ
  .if SCSI_BIOS_LEVEL<=4
	goto	<cmpi.l #-1,d0>,eq,assign_error
	bsr	stsin_and_msgin		;ステータスインフェーズとメッセージインフェーズ
	pop_test
	unlk	a5
	rts

assign_error:
	moveq.l	#-1,d0
	pop
	unlk	a5
	rts
  .else
	goto	writeext_stsin_1	;ステータスインフェーズとメッセージインフェーズ
  .endif


  .if SCSI_BIOS_LEVEL<=3


;----------------------------------------------------------------
;SCSI出力(DMA転送)
;	MC68040またはMC68060のときはデータキャッシュをプッシュしてから呼び出す必要がある
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,その他=INTS
dataout_transfer:
	push	dLEN/aBUF
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1を待つ
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;転送開始
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)	;転送開始
	bsr	dataout_dma		;SCSI出力(DMA転送)実行
	goto	<tst.l d0>,ne,dataout_transfer_end	;転送失敗。終了
;割り込みを待つ
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,dataout_transfer_no_error
dataout_transfer_end:
	pop_test
	rts

dataout_transfer_no_error:
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,その他=INTS
datain_transfer:
	push	dLEN/aBUF
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
;転送開始
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	datain_dma		;SCSI入力(DMA転送)実行
	goto	<tst.l d0>,ne,datain_transfer_end
;割り込みを待つ
datain_transfer_wait:
	do
		move.b	SPC_INTS(aSPC),d0
	while	eq
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	goto	<cmp.b #SPC_INTS_CC,d0>,eq,datain_transfer_no_error
datain_transfer_end:
	pop_test
	rts

datain_transfer_no_error:
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;SCSI出力(DMA転送)実行
;<dLEN.l:長さ
;<aBUF.l:アドレス
dataout_dma:
aDMAC	reg	a0
	push	aDMAC/a3
;DMAを設定する
	lea.l	DMAC_1_BASE,aDMAC
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
	move.b	#DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.w	#0,DMAC_BTC(aDMAC)
	move.b	#DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;256バイトずつ転送する
	do
	;<dLEN.l:今回の残りのデータの長さ
	;<aBUF.l:今回のバッファのアドレス
		goto	<cmp.l #256,dLEN>,ls,dataout_dma_last	;残り1～256バイト
		move.l	aBUF,DMAC_MAR(aDMAC)	;バッファのアドレス
		move.w	#256,DMAC_MTC(aDMAC)	;データの長さ
	dataout_dma_continue:
	;FIFOが空になるまで待つ
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;REQ=1を待つ
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
	;DMA転送開始
		move.b	#-1,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
		nop
		nop
		nop
    .if 3<=SCSI_BIOS_LEVEL
		nop
    .endif
	;DMA転送終了を待つ
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
	;+++++ BUG +++++
	;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
	;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
		goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,dataout_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(aDMAC)>,ne,dataout_dma_error	;DMAエラーあり
		adda.l	#256,aBUF		;次回のバッファのアドレス
		sub.l	#256,dLEN		;次回の残りのデータの長さ
	while	ne
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;残り1～256バイト
dataout_dma_last:
	move.l	aBUF,DMAC_MAR(aDMAC)
	move.w	dLEN,DMAC_MTC(aDMAC)
dataout_dma_last_start:
;FIFOが空になるまで待つ
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
	while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
;REQ=1を待つ
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;DMA転送開始
	move.b	#-1,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
	move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
	nop
	nop
	nop
    .if 3<=SCSI_BIOS_LEVEL
	nop
    .endif
;DMA転送終了を待つ
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
	while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
;+++++ BUG +++++
;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
    .if SCSI_BIOS_LEVEL<=0
	goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,dataout_dma_continue
    .else
	goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,dataout_dma_last_start
    .endif
;+++++ BUG +++++
	goto	<tst.b DMAC_CER(aDMAC)>,ne,dataout_dma_error	;DMAエラーあり
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;DMAエラーあり
dataout_dma_error:
	moveq.l	#-1,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)実行
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a6.l:SPCベースアドレス
datain_dma:
aDMAC	reg	a0
	push	aDMAC/a3
;DMAを設定する
	lea.l	DMAC_1_BASE,aDMAC
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
	move.b	#DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.w	#0,DMAC_BTC(aDMAC)
	move.b	#DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;256バイトずつ転送する
	do
	;<dLEN.l:今回の残りのデータの長さ
	;<aBUF.l:今回のバッファのアドレス
		goto	<cmp.l #256,dLEN>,ls,datain_dma_last	;残り1～256バイト
		move.l	aBUF,DMAC_MAR(aDMAC)	;バッファのアドレス
		move.w	#256,DMAC_MTC(aDMAC)	;データの長さ
	datain_dma_continue:
	;FIFOが空でなくなるまで待つ
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;DMA転送開始
		move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
		nop
		nop
		nop
    .if 3<=SCSI_BIOS_LEVEL
		nop
    .endif
	;DMA転送終了を待つ
		do
			goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
	;+++++ BUG +++++
	;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
	;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
		goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,datain_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(aDMAC)>,ne,datain_dma_error	;DMAエラーあり
		adda.l	#256,aBUF		;次回のバッファのアドレス
		sub.l	#256,dLEN		;次回の残りのデータの長さ
	while	ne
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;残り1～256バイト
datain_dma_last:
	move.l	aBUF,DMAC_MAR(aDMAC)
	move.w	dLEN,DMAC_MTC(aDMAC)
datain_dma_last_start:
;FIFOが空でなくなるまで待つ
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
	while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
;DMA転送開始
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
	move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
	nop
	nop
	nop
    .if 3<=SCSI_BIOS_LEVEL
	nop
    .endif
;DMA転送終了を待つ
	do
		goto	<tst.b SPC_INTS(aSPC)>,ne,dataio_interrupted	;SPC割り込みあり
	while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
;+++++ BUG +++++
;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
	goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,datain_dma_last_start
;+++++ BUG +++++
	goto	<tst.b DMAC_CER(aDMAC)>,ne,datain_dma_error	;DMAエラーあり
	moveq.l	#0,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;DMAエラーあり
datain_dma_error:
	moveq.l	#-1,d0
    .if 3<=SCSI_BIOS_LEVEL
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
    .endif
	pop_test
	rts

;SPC割り込みあり
dataio_interrupted:
    .if SCSI_BIOS_LEVEL<=0
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA動作中止
	moveq.l	#0,d0
	pop
	rts
    .else
	move.b	SPC_INTS(aSPC),d0
	goto	<cmpi.b #SPC_INTS_CC,d0>,ne,dataio_abort	;SPCが転送終了していない
;SPCが転送終了した
	goto	<tst.w DMAC_MTC(aDMAC)>,ne,dataio_abort_2	;DMAが転送終了していない
	moveq.l	#0,d0
	goto	dataio_abort

;DMAが転送終了していない
dataio_abort_2:
	moveq.l	#-2,d0
;SPCが転送終了していない
dataio_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA動作中止
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts
    .endif


  .elif SCSI_BIOS_LEVEL<=4


;----------------------------------------------------------------
;SCSI出力(DMA転送)
;	MC68040またはMC68060のときはデータキャッシュをプッシュしてから呼び出す必要がある
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,その他=INTS
dataout_transfer:
	move.l	a3,-(sp)
	lea.l	dataout_dma(pc),a3	;SCSI出力(DMA転送)実行
	bsr	dataio_transfer		;SCSI入出力(DMA転送)
	movea.l	(sp)+,a3
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,その他=INTS
datain_transfer:
	move.l	a3,-(sp)
	lea.l	datain_dma(pc),a3	;SCSI入力(DMA転送)実行
	bsr	dataio_transfer		;SCSI入出力(DMA転送)
;キャッシュクリア
;!!! 機種がX68030のとき転送後にCACRを直接操作してデータキャッシュだけクリアしている
	push	d0/d1
	move.b	SYSPORT_MODEL,d0
	lsr.b	#4,d0
	if	<cmpi.b #14,d0>,cs	;X68030
		.cpu	68030
		movec.l	cacr,d0
		move.l	d0,d1
		bset.l	#11,d0			;データキャッシュをクリア
		movec.l	d0,cacr
		movec.l	d1,cacr
		.cpu	68000
	endif
	pop
	movea.l	(sp)+,a3
	rts

;----------------------------------------------------------------
;SCSI入出力(DMA転送)
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
;<a3.l:dataout_dmaまたはdatain_dma
;<a6.l:SPCベースアドレス
dataio_transfer:
aDMAC	reg	a2
	push	aBUF/aDMAC
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PSNS_MSG|SPC_PSNS_CD|SPC_PSNS_IO,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)	;データの長さ(下位)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;データの長さ(中位)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;データの長さ(上位)
;REQ=1を待つ
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;DMAを設定する
	lea.l	DMAC_1_BASE,aDMAC
;<a2.l:DMAチャンネルベースアドレス
	move.b	#$FF,DMAC_CSR.w(aDMAC)	;DMAC_CSRをクリア
	move.w	#0,DMAC_BTC(aDMAC)
	move.b	#DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a0
	move.l	a0,DMAC_DAR(aDMAC)
;REQ=1を待つ
	do
		move.b	SPC_PSNS(aSPC),d0
	while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
;転送開始
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)	;転送開始
	jsr	(a3)			;dataout_dmaまたはdatain_dma
	goto	<tst.l d0>,ne,dataio_transfer_end	;転送失敗。終了
;転送終了を待つ
	do
		goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataio_transfer_phase	;フェーズ不一致
	while	<btst.b #SPC_INTS_CC_BIT,SPC_INTS(aSPC)>,eq
;転送終了
	bset.b	#SPC_INTS_CC_BIT,SPC_INTS(aSPC)	;Command Completeをクリア
	moveq.l	#0,d0
	goto	dataio_transfer_end

;フェーズ不一致
dataio_transfer_phase:
	bset.b	#SPC_INTS_SR_BIT,SPC_INTS(aSPC)	;Service Requiredをクリア
	moveq.l	#-3,d0
	goto	dataio_transfer_end

;+++++ BUG +++++
;どこからも参照されていない
	moveq.l	#-1,d0
;+++++ BUG +++++
;終了
dataio_transfer_end:
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts

;----------------------------------------------------------------
;SCSI出力(DMA転送)実行
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a2.l:DMAチャンネルベースアドレス
;<a6.l:SPCベースアドレス
dataout_dma:
	push	d1/d2/dLEN/d4/d5/aBUF
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
	move.b	#DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.l	dLEN,d4
;256バイトずつ転送する
	do
		if	<cmp.l #256,dLEN>,hi
			move.l	#256,d5
		else
			move.l	dLEN,d5
		endif
	;<dLEN.l:残りのデータの長さ
	;<d4.l:残りのデータの長さ
	;<d5.l:今回転送する長さ
	;<aBUF.l:バッファのアドレス
		move.l	aBUF,DMAC_MAR(a2)	;バッファのアドレス
		move.w	d5,DMAC_MTC(a2)		;今回転送する長さ
	dataout_dma_continue:
	;FIFOが空になるまで待つ
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataout_dma_phase	;フェーズ不一致
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;REQ=1を待つ
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataout_dma_phase	;フェーズ不一致
			move.b	SPC_PSNS(aSPC),d0
		while	<btst.l #SPC_PSNS_REQ_BIT,d0>,eq
	;バスエラー対策
	;	X68000ではDMACがSPCのDREQを外部転送要求信号として使えないため、
	;	DREQが出ていないときはDTACKを出さないことでDREGへのライトを待たせている
	;	SCSI機器のデータの受け取りが遅いとバッファが一杯になりDREQが出なくなる
	;	DREGへのライトでDTACKが出ないとバスエラーが発生して転送が中断される
	;	このときDMACはバスエラーになったデータは転送されなかったと判断するが、
	;	SPCはバスエラーを感知していないので、BERRがアサートされてからASがネゲートされるまでの間に
	;	バスエラーになったはずのデータを受け取ってしまう場合がある
	;	それを検出してデータが重複しないようにする
		moveq.l	#0,d0
		move.b	SPC_TCH(aSPC),d0
		lsl.l	#8,d0
		move.b	SPC_TCM(aSPC),d0
		lsl.l	#8,d0
		move.b	SPC_TCL(aSPC),d0	;SPCが転送する残りの長さ
		move.l	d4,d1			;ブロック開始時の残りの長さ
		sub.l	d0,d1			;SPCが今回のブロックで転送した長さ
		moveq.l	#0,d0
		move.w	DMAC_MTC(a2),d0		;DMACの今回のブロックの残りの長さ
		move.l	d5,d2			;今回転送する長さ
		sub.l	d0,d2			;DMACが今回のブロックで転送した長さ
		sub.l	d2,d1			;SPCがDMACよりも多く転送した長さ
		if	ne
			add.l	d1,DMAC_MAR(a2)		;DMACが転送するアドレスを進める
			sub.w	d1,DMAC_MTC(a2)		;DMACが転送する長さを減らす
		endif
	;転送開始
		move.b	#-1,DMAC_CSR(a2)		;DMAC_CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(a2)	;転送開始
		nop
		nop
		nop
		nop
		nop
	;転送終了を待つ
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,dataout_dma_phase	;フェーズ不一致
			break	<btst.b #SPC_INTS_CC_BIT,SPC_INTS(aSPC)>,ne	;転送終了
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(a2)>,eq
	;SPCまたはDMAが転送終了した
	;+++++ BUG +++++
	;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
	;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
		goto	<btst.b #1,DMAC_CER(a2)>,ne,dataout_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(a2)>,ne,dataout_dma_error	;DMAエラーあり
		goto	<tst.w DMAC_MTC(a2)>,ne,dataout_dma_error	;DMAが転送終了していない
		adda.l	d5,aBUF			;アドレスを増やす
		sub.l	d5,d4			;長さを減らす
		sub.l	d5,dLEN			;長さを減らす
	while	ne
	moveq.l	#0,d0
	goto	dataout_dma_end		;終了

;フェーズ不一致
dataout_dma_phase:
	moveq.l	#-3,d0
	goto	dataout_dma_abort	;転送中止

;DMAエラーあり
;DMAが転送終了していない
dataout_dma_error:
	moveq.l	#-2,d0
	goto	dataout_dma_abort	;転送中止

;+++++ BUG +++++
;どこからも参照されていない
	moveq.l	#-1,d0
;+++++ BUG +++++
;転送中止
dataout_dma_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(a2)	;DMA転送中止
;終了
dataout_dma_end:
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)実行
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a2.l:DMAチャンネルベースアドレス
;<a6.l:SPCベースアドレス
datain_dma:
	push	d1/d2/dLEN/d4/d5/aBUF
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
	move.b	#DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
;256バイトずつ転送する
	do
		if	<cmp.l #256,dLEN>,hi
			move.l	#256,d5
		else
			move.l	dLEN,d5
		endif
	;<dLEN.l:残りのデータの長さ
	;<d5.l:今回転送する長さ
		move.l	aBUF,DMAC_MAR(aDMAC)	;バッファのアドレス
		move.w	d5,DMAC_MTC(aDMAC)	;今回転送する長さ
	datain_dma_continue:
	;FIFOが空でなくなるまで待つ
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,datain_dma_phase	;フェーズ不一致
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;転送開始
		move.b	#-1,DMAC_CSR(aDMAC)	;DMAC_CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;転送開始
		nop
		nop
		nop
		nop
		nop
	;転送終了を待つ
		do
			goto	<btst.b #SPC_INTS_SR_BIT,SPC_INTS(aSPC)>,ne,datain_dma_phase	;フェーズ不一致
			break	<btst.b #SPC_INTS_CC_BIT,SPC_INTS(aSPC)>,ne	;転送終了
		while	<btst.b #DMAC_CSR_COC_BIT,DMAC_CSR(aDMAC)>,eq
	;SPCまたはDMAが転送終了した
	;+++++ BUG +++++
	;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
	;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
		goto	<btst.b #1,DMAC_CER(aDMAC)>,ne,datain_dma_continue
	;+++++ BUG +++++
		goto	<tst.b DMAC_CER(aDMAC)>,ne,datain_dma_error	;DMAエラーあり
		goto	<tst.w DMAC_MTC(aDMAC)>,ne,datain_dma_error	;DMAが転送終了していない
		adda.l	d5,aBUF			;アドレスを増やす
		sub.l	d5,d4			;長さを減らす
		sub.l	d5,dLEN			;長さを減らす
	while	ne
	moveq.l	#0,d0
	goto	datain_dma_end		;終了

;フェーズ不一致
datain_dma_phase:
	moveq.l	#-3,d0
	goto	datain_dma_abort	;転送中止

;DMAエラーあり
;DMAが転送終了していない
datain_dma_error:
	moveq.l	#-2,d0
	goto	datain_dma_abort	;転送中止

;+++++ BUG +++++
;どこからも参照されていない
	moveq.l	#-1,d0
;+++++ BUG +++++
;転送中止
datain_dma_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA転送中止
;終了
datain_dma_end:
	pop
	rts


  .elif SCSI_BIOS_LEVEL<=10


;----------------------------------------------------------------
;SCSI出力(DMA転送)
;	MC68040またはMC68060のときはデータキャッシュをプッシュしてから呼び出す必要がある
;<dLEN.l:長さ
;<aBUF.l:アドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,その他=INTS
dataout_transfer:
	push	dLEN/aBUF
;長さが0のとき256と見なす
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;長さをセットする
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;REQ=1を待つ
	do
	while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
;転送開始
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	dataout_dma		;SCSI出力(DMA転送)実行
	if	<tst.l d0>,eq
	;割り込みを待つ
		do
			move.b	SPC_INTS(aSPC),d0
		while	eq
		move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
		if	<cmp.b #SPC_INTS_CC,d0>,eq
			moveq.l	#0,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
datain_transfer:
	push	dLEN/aBUF
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さが0のとき256と見なす
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;長さをセットする
	move.l	#$00FFFFFF,d0
	and.l	dLEN,d0
	movep.l	d0,SPC_TEMP(aSPC)
;転送開始
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	datain_dma		;SCSI入力(DMA転送)実行
	if	<tst.l d0>,eq
	;割り込みを待つ
		do
			move.b	SPC_INTS(aSPC),d0
		while	eq
		move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
		if	<cmp.b #SPC_INTS_CC,d0>,eq
			moveq.l	#0,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)実行
datain_dma:
	push	d1/d2/a0/a3
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
~ocr = DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
	goto	dataio_dma_common	;ここからSCSI入出力(DMA転送)実行共通

;----------------------------------------------------------------
;SCSI出力(DMA転送)実行
dataout_dma:
	push_again
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
~ocr = DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
;----------------------------------------------------------------
;ここからSCSI入出力(DMA転送)実行共通
dataio_dma_common:
	bsr	cache_flush		;DMA転送開始直前のキャッシュフラッシュ
aDMAC	reg	a0
;DMAを設定する
	lea.l	DMAC_1_BASE,aDMAC
	st.b	DMAC_CSR(aDMAC)		;DMAC_CSRをクリア
	clr.w	DMAC_BTC(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;一度に転送する長さを決める
	moveq.l	#0,d2
	move.w	#256,d2
	if	<tst.b SRAM_SCSI_MODE>,mi	;SRAM_SCSI_BLOCK_BIT ブロック
		moveq.l	#0,d2
		move.w	BIOS_SCSI_BLOCK_SIZE.l,d2	;SCSI機器のブロックサイズ
	endif
;バーストにするか
	if	<btst.b #SRAM_SCSI_BURST_BIT,SRAM_SCSI_MODE>,ne	;バースト
	;外部転送要求にする
	;DMAのREQ1がSPCのDREQに繋がっているのはX68030だけ
~dcr = DMAC_NO_HOLD_CYCLE^DMAC_BURST_TRANSFER
~ocr = DMAC_AUTO_REQUEST_MAX^DMAC_EXTERNAL_REQUEST
		eori.w	#(~dcr<<8)|~ocr,d1
	endif
;DMAC_DCRとDMAC_OCRを設定する
	move.w	d1,DMAC_DCR(aDMAC)	;DMAC_DCRとDMAC_OCR
;入力と出力で分岐する
aINTS	reg	a3
	lea.l	SPC_INTS(aSPC),aINTS
	goto	<tst.b d1>,mi,dataio_dma_input	;pl=DMAC_MEMORY_TO_DEVICE,mi=DMAC_DEVICE_TO_MEMORY
						;入力
;出力
dataio_dma_output:
	do
	;<dLEN.l:今回の残りのデータの長さ
	;<aBUF.l:今回のバッファのアドレス
		goto	<cmp.l d2,dLEN>,ls,dataio_dma_output_last	;残り1～ブロックサイズ
	dataio_dma_output_start:
	;<d2.l:今回転送する長さ
	;今回のバッファのアドレスと今回転送する長さをDMAに設定する
		move.l	aBUF,DMAC_MAR(aDMAC)	;バッファのアドレス
		move.w	d2,DMAC_MTC(aDMAC)	;今回転送する長さ
	dataio_dma_output_continue:
	;FIFOが空になるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;REQ=1を待つ
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
	;DMA転送開始
		st.b	DMAC_CSR(aDMAC)		;CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
		tst.b	(aINTS)			;空読み？
	;DMA転送終了を待つ
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;エラーがないか確認する
		move.b	DMAC_CER(aDMAC),d0
		goto	ne,dataio_dma_output_error	;DMAエラーあり
	;残りのデータの長さが0になるまで繰り返す
		adda.l	d2,aBUF			;次回のバッファのアドレス
		sub.l	d2,dLEN			;次回の残りのデータの長さ
	while	ne
	moveq.l	#0,d0
dataio_dma_output_end:
;+++++ BUG +++++
;DMAC_DARをSASIに戻していない
;+++++ BUG +++++
	pop_test
	rts

;残り1～ブロックサイズ
dataio_dma_output_last:
	move.l	dLEN,d2			;今回転送する長さは残りのデータの長さ
	goto	dataio_dma_output_start

;DMAエラーあり
dataio_dma_output_error:
;+++++ BUG +++++
;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
	goto	<btst.l #1,d0>,ne,dataio_dma_output_continue
;+++++ BUG +++++
;バスエラー以外のDMAエラー
	moveq.l	#-1,d0
	goto	dataio_dma_output_end

;SPC割り込みあり
dataio_interrupted:
	move.b	SPC_INTS(aSPC),d0
	goto	<cmpi.b #SPC_INTS_CC,d0>,ne,dataio_dma_output_abort	;SPCが転送終了していない。転送中止
;SPCが転送終了した
	moveq.l	#0,d0
	goto	<tst.w DMAC_MTC(aDMAC)>,eq,dataio_dma_output_abort	;DMAも転送終了した。転送中止
;SPCは転送終了したがDMAが転送終了していない
	moveq.l	#-2,d0
;転送中止
dataio_dma_output_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA転送中止
	goto	dataio_dma_output_end

;残り1～ブロックサイズ
dataio_dma_input_last:
	move.l	dLEN,d2			;今回転送する長さは残りのデータの長さ
	goto	dataio_dma_input_start

;入力
dataio_dma_input:
	do
	;<dLEN.l:今回の残りのデータの長さ
	;<aBUF.l:今回のバッファのアドレス
		goto	<cmp.l d2,dLEN>,ls,dataio_dma_input_last	;残り1～ブロックサイズ
	dataio_dma_input_start:
	;<d2.l:今回転送する長さ
	;今回のバッファのアドレスと今回転送する長さをDMAに設定する
		move.l	aBUF,DMAC_MAR(aDMAC)	;バッファのアドレス
		move.w	d2,DMAC_MTC(aDMAC)	;今回転送する長さ
	dataio_dma_input_continue:
	;FIFOが空でなくなるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;DMA転送開始
		st.b	DMAC_CSR(aDMAC)		;CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
		tst.b	(aINTS)			;空読み？
	;DMA転送終了を待つ
		do
			goto	<tst.b (aINTS)>,ne,dataio_interrupted	;SPC割り込みあり
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;エラーがないか確認する
		move.b	DMAC_CER(aDMAC),d0
		goto	ne,dataio_dma_input_error	;DMAエラーあり
	;残りのデータの長さが0になるまで繰り返す
		adda.l	d2,aBUF			;次回のバッファのアドレス
		sub.l	d2,dLEN			;次回の残りのデータの長さ
	while	ne
	moveq.l	#0,d0
dataio_dma_input_end:
;+++++ BUG +++++
;DMAC_DARをSASIに戻していない
;+++++ BUG +++++
	pop
	rts

;DMAエラーあり
dataio_dma_input_error:
;+++++ BUG +++++
;DMAC_CERの5ビットのエラーコードのビット1だけテストしてバスエラー(デバイスアドレス)と見なしている
;バスエラー(デバイスアドレス)のエラーコード$0Aのビット1がたまたま1だったので動いている？
	goto	<btst.l #1,d0>,ne,dataio_dma_input_continue
;+++++ BUG +++++
;バスエラー以外のDMAエラー
	moveq.l	#-1,d0
	goto	dataio_dma_input_end


  .else


;----------------------------------------------------------------
;SCSI出力(DMA転送)
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,-1=DMAエラー,その他=INTS
dataout_transfer:
	push	d1/d2/dLEN/a0/aBUF/a3
aDMAC	reg	a0
aINTS	reg	a3
	lea.l	DMAC_1_BASE,aDMAC
	lea.l	SPC_INTS(aSPC),aINTS
;キャッシュフラッシュ
	bsr	cache_flush
;長さが0のとき256と見なす
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)	;データの長さ(下位)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;データの長さ(中位)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;データの長さ(上位)
;REQ=1を待つ
	do
	while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
;SPC転送開始
	move.b	(aINTS),(aINTS)		;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
;DCRとOCRを決める
;	X68000のSPCのDREQはDMACのREQ1に繋がっていない
;	DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
~ocr = DMAC_MEMORY_TO_DEVICE|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
    .if SCSIEXROM==0
	ifand	<isX68030>,eq,<btst.b #SRAM_SCSI_BURST_BIT,SRAM_SCSI_MODE>,ne	;内蔵SCSIかつX68030かつバースト
~dcr = DMAC_NO_HOLD_CYCLE^DMAC_BURST_TRANSFER
~ocr = DMAC_AUTO_REQUEST_MAX^DMAC_EXTERNAL_REQUEST
		eori.w	#(~dcr<<8)|~ocr,d1
	endif
    .endif
;DMACを設定する
	st.b	DMAC_CSR(aDMAC)		;CSRをクリア
	clr.w	DMAC_BTC(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	move.w	d1,DMAC_DCR(aDMAC)	;DMAC_DCR,DMAC_OCR
	moveq.l	#SPC_DREG,d0
	add.l	aSPC,d0
	move.l	d0,DMAC_DAR(aDMAC)	;DARにDREGを設定
;ブロックの長さを決める
	move.l	#256,d2
	if	<tst.b SRAM_SCSI_MODE>,mi	;SRAM_SCSI_BLOCK_BIT
		move.w	BIOS_SCSI_BLOCK_SIZE.l,d2	;SCSI機器のブロックサイズ
	endif
;<d2.l:ブロックの長さ
	do
	;<dLEN.l:ブロック開始時の全体の残りの長さ
	;<aBUF.l:ブロック開始時のデータのアドレス
	;最後のブロックの長さを調整する
		if	<cmp.l dLEN,d2>,hi
			move.l	dLEN,d2
		endif
	;<d2.l:ブロックの長さ
	dataout_transfer_continue:
	;FIFOが空になるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,dataout_transfer_finish	;SPC動作終了
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,eq
	;データのアドレスとブロックの残りの長さを計算する
		moveq.l	#0,d0
		move.b	SPC_TCH(aSPC),d0	;データの長さ(上位)
		swap.w	d0
		move.b	SPC_TCM(aSPC),d0	;データの長さ(中位)
		lsl.w	#8,d0
		move.b	SPC_TCL(aSPC),d0	;データの長さ(下位)
	;<d0.l:全体の残りの長さ
		sub.l	dLEN,d0			;-(ブロックの転送した長さ)=(全体の残りの長さ)-(ブロック開始時の全体の残りの長さ)
	;<d0.l:-(ブロックの転送した長さ)
		move.l	aBUF,d1
		sub.l	d0,d1			;(データのアドレス)=(ブロック開始時のデータのアドレス)+(ブロックの転送した長さ)
	;<d1.l:データのアドレス
		add.l	d2,d0			;(ブロックの残りの長さ)=(ブロックの長さ)-(ブロックの転送した長さ)
	;<d0.l:ブロックの残りの長さ
		st.b	DMAC_CSR(aDMAC)		;CSRをクリア
		move.l	d1,DMAC_MAR(aDMAC)	;データのアドレス
		move.w	d0,DMAC_MTC(aDMAC)	;ブロックの残りの長さ
	;REQ=1を待つ
		do
			goto	<tst.b (aINTS)>,ne,dataout_transfer_finish	;SPC動作終了
		while	<tst.b SPC_PSNS(aSPC)>,pl	;SPC_PSNS_REQ_BIT
	;DMA転送開始
		st.b	DMAC_CSR(aDMAC)		;CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
		tst.b	(aINTS)			;空読み
	;DMA動作終了を待つ
		do
			goto	<tst.b (aINTS)>,ne,dataout_transfer_finish	;SPC動作終了
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;DMA動作終了
		move.b	DMAC_CER(aDMAC),d0
		if	ne			;DMAエラーあり
			goto	<cmp.b #DMAC_BUS_ERROR_DEVICE,d0>,eq,dataout_transfer_continue	;デバイスアドレスのバスエラーは継続
		;デバイスアドレスのバスエラー以外のDMAエラー
		;!!! SPCの後始末をしていない。ハングアップしそう
			moveq.l	#-1,d0
			goto	dataout_transfer_end

		endif
	;DMAエラーなし
	;データのアドレスと全体の残りの長さを更新する
		adda.l	d2,aBUF			;(データのアドレス)+=(ブロックの長さ)
		sub.l	d2,dLEN			;(全体の残りの長さ)-=(ブロックの長さ)
	while	ne			;全体の残りの長さが0になるまで繰り返す
;SPC動作終了
dataout_transfer_finish:
;SPCの後始末
	moveq.l	#0,d0
	do
		move.b	(aINTS),d0
	while	eq
	move.b	d0,(aINTS)		;INTSをクリア
	if	<cmp.b #SPC_INTS_CC,d0>,eq	;SPC転送終了
		moveq.l	#0,d0
	endif
;DMACの後始末
	if	<tst.w DMAC_MTC(aDMAC)>,ne	;MTCが0でない
		moveq.l	#-2,d0
	endif
	if	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC。DMAが転送終了していない
		move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA転送中止
	endif
;終了
dataout_transfer_end:
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)
;<dLEN.l:データの長さ
;<aBUF.l:バッファのアドレス
;<a6.l:SPCベースアドレス
;>d0.l:0=正常終了,その他=INTS
datain_transfer:
	push	dLEN/aBUF
;長さが0のとき256と見なす
	if	<tst.l dLEN>,eq
		move.w	#256,dLEN
	endif
;フェーズをセットする
	move.b	SPC_PSNS(aSPC),d0
	andi.b	#SPC_PHASE_MASK,d0
	move.b	d0,SPC_PCTL(aSPC)
;長さをセットする
	move.l	dLEN,d0
	move.b	d0,SPC_TCL(aSPC)	;データの長さ(下位)
	lsr.l	#8,d0
	move.b	d0,SPC_TCM(aSPC)	;データの長さ(中位)
	lsr.l	#8,d0
	move.b	d0,SPC_TCH(aSPC)	;データの長さ(上位)
;転送開始
	move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
	move.b	#SPC_SCMD_CC_TR,SPC_SCMD(aSPC)
	bsr	datain_dma		;SCSI入力(DMA転送)実行
	if	<tst.l d0>,eq
	;割り込みを待つ
		do
			move.b	SPC_INTS(aSPC),d0
		while	eq
		move.b	SPC_INTS(aSPC),SPC_INTS(aSPC)	;INTSをクリア
		if	<cmp.b #SPC_INTS_CC,d0>,eq
			moveq.l	#0,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;SCSI入力(DMA転送)実行
datain_dma:
	push	d1/d2/a0/a3
~dcr = DMAC_NO_HOLD_CYCLE|DMAC_HD68000_COMPATIBLE|DMAC_8_BIT_PORT|DMAC_STATUS_INPUT
;X68000のSPCのDREQはDMACのREQ1に繋がっていない
;DREQを使ってDTACKが作られるのでオートリクエスト最大速度を用いる
~ocr = DMAC_DEVICE_TO_MEMORY|DMAC_UNPACKED_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX
	move.w	#(~dcr<<8)|~ocr,d1
	bsr	cache_flush		;DMA転送開始直前のキャッシュフラッシュ
aDMAC	reg	a0
;DMAを設定する
	lea.l	DMAC_1_BASE,aDMAC
	st.b	DMAC_CSR(aDMAC)		;DMAC_CSRをクリア
	clr.w	DMAC_BTC(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_FIXED_DEVICE,DMAC_SCR(aDMAC)
	lea.l	SPC_DREG(aSPC),a3
	move.l	a3,DMAC_DAR(aDMAC)
;一度に転送する長さを決める
	moveq.l	#0,d2
	move.w	#256,d2
	if	<tst.b SRAM_SCSI_MODE>,mi	;SRAM_SCSI_BLOCK_BIT ブロック
		moveq.l	#0,d2
		move.w	BIOS_SCSI_BLOCK_SIZE.l,d2	;SCSI機器のブロックサイズ
	endif
;バーストにするか
    .if SCSIEXROM==0
	ifand	<isX68030>,eq,<btst.b #SRAM_SCSI_BURST_BIT,SRAM_SCSI_MODE>,ne	;内蔵SCSIかつX68030かつバースト
~dcr = DMAC_NO_HOLD_CYCLE^DMAC_BURST_TRANSFER
~ocr = DMAC_AUTO_REQUEST_MAX^DMAC_EXTERNAL_REQUEST
		eori.w	#(~dcr<<8)|~ocr,d1
	endif
    .endif
;DMAC_DCRとDMAC_OCRを設定する
	move.w	d1,DMAC_DCR(aDMAC)	;DMAC_DCRとDMAC_OCR
aINTS	reg	a3
	lea.l	SPC_INTS(aSPC),aINTS
	do
	;<dLEN.l:今回の残りのデータの長さ
	;<aBUF.l:今回のバッファのアドレス
		if	<cmp.l d2,dLEN>,ls	;残り1～ブロックサイズ
			move.l	dLEN,d2			;今回転送する長さは残りのデータの長さ
		endif
	;<d2.l:今回転送する長さ
	;今回のバッファのアドレスと今回転送する長さをDMAに設定する
		move.l	aBUF,DMAC_MAR(aDMAC)	;バッファのアドレス
		move.w	d2,DMAC_MTC(aDMAC)	;今回転送する長さ
	datain_dma_continue:
	;FIFOが空でなくなるまで待つ
		do
			goto	<tst.b (aINTS)>,ne,datain_dma_interrupted	;SPC割り込みあり
		while	<btst.b #SPC_SSTS_DE_BIT,SPC_SSTS(aSPC)>,ne
	;DMA転送開始
		st.b	DMAC_CSR(aDMAC)		;CSRをクリア
		move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
		tst.b	(aINTS)			;空読み
	;DMA転送終了を待つ
		do
			goto	<tst.b (aINTS)>,ne,datain_dma_interrupted	;SPC割り込みあり
		while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMAC_CSR_COC
	;エラーがないか確認する
		move.b	DMAC_CER(aDMAC),d0
		goto	ne,datain_dma_error	;DMAエラーあり
	;残りのデータの長さが0になるまで繰り返す
		adda.l	d2,aBUF			;次回のバッファのアドレス
		sub.l	d2,dLEN			;次回の残りのデータの長さ
	while	ne
	moveq.l	#0,d0
datain_dma_end:
;DMAC_DARをSASIに戻す
	move.l	#HDC_DATA,DMAC_DAR(aDMAC)
	pop
	rts

;DMAエラーあり
;<d0.b:DMAC_CER
datain_dma_error:
	goto	<cmp.b #DMAC_BUS_ERROR_DEVICE,d0>,eq,datain_dma_continue	;バスエラー
;バスエラー以外のDMAエラー
	moveq.l	#-1,d0
	goto	datain_dma_end

;SPC割り込みあり
datain_dma_interrupted:
	move.b	SPC_INTS(aSPC),d0
	goto	<cmpi.b #SPC_INTS_CC,d0>,ne,datain_dma_abort	;SPCが転送終了していない。転送中止
;SPCが転送終了した
	moveq.l	#0,d0
	goto	<tst.w DMAC_MTC(aDMAC)>,eq,datain_dma_abort	;DMAも転送終了した。転送中止
;SPCは転送終了したがDMAが転送終了していない
	moveq.l	#-2,d0
;転送中止
datain_dma_abort:
	move.b	#DMAC_CCR_SAB,DMAC_CCR(aDMAC)	;DMA転送中止
	goto	datain_dma_end


  .endif


;----------------------------------------------------------------
;	https://twitter.com/kamadox/status/1204687543200972805
;	SUPERからCompactまでの内蔵SCSIはDMA転送を使っているが、SPCのDREQはDMAコントローラに繋がっておらず、
;	代わりにDTACKとBERRで転送のタイミングを制御している。
;                                                                                                
;                                      [X68000 XVI Compact]                                      
;                                                                                                
;             MC68HC000             DOSA               HD63450                                   
;          +-------------+     +-------------+     +-------------+                               
;          |         BERR|-----|BERR   BEC0/1|-----|BEC0/1   REQ1|--+                            
;          |        DTACK|--+  +-------------+  +--|DTACK        |  |                            
;          +-------------+  |        ASA        |  +-------------+  |                            
;                           |  +-------------+  |       PEDEC       |                            
;                           +--|MPUDTACK     |  |  +-------------+  |      MB89352               
;                              |  +--DMADTACK|--+  |        HDREQ|--+  +-------------+           
;                              |  +-SYNCDTACK|-----|IOCDTK--SIREQ|-----|DREQ         |           
;                              +-------------+     +-------------+     +-------------+           
;                                                                                                
;                                             [X68030]                                           
;                                                                                                
;             MC68EC030             SAKI               HD63450                                   
;          +-------------+     +-------------+     +-------------+                               
;          |         BERR|-----|BERR   BEC0/1|-----|BEC0/1   REQ1|--+                            
;          |     DSACK0/1|--+  +-------------+  +--|DTACK        |  |                            
;          +-------------+  |       YUKI        |  +-------------+  |                            
;                           |  +-------------+  |       PEDEC       |                            
;                           +--|DSACK0/1     |  |  +-------------+  |      MB89352               
;                              |  +--DMADTACK|--+  |        HDREQ|- |  +-------------+           
;                              |  +-SYNCDTACK|-----|IOCDTK--SIREQ|--+--|DREQ         |           
;                              +-------------+     +-------------+     +-------------+           
;                                                                                                
;	DMAコントローラはSPCのDREGをアクセスするときDREQを外部転送要求として使えないので、
;	オートリクエスト最大速度でアクセスして、バスを掴んだままDREQと連動しているDTACKを待つ。
;	一定時間内に転送できず、バスエラーで強制終了させられても、転送を継続するようにプログラムされている。
;	MOなどの遅いデバイスへの書き込みで、バスエラーが宣告されるタイミングが悪いと、
;	DMAコントローラが一旦引っ込めようとしたデータをSPCが送信してしまうことがある。
;	そのまま継続すると同じデータが重複して送信される。初期のSCSI BIOSはこれが原因で書き込みに失敗することがあった。
;	データの重複はバスエラーが発生したときDMAコントローラとSPCのカウンタを比較して転送を再開する位置を補正することで回避できる。
;	ＧａｏさんのFiloP.xを用いるか、Human68k version 3.0のFORMAT.Xでフォーマットしたハードディスクから起動すると対策が施される。
;----------------------------------------------------------------



;--------------------------------------------------------------------------------
;	.include	sc08cache.s
;--------------------------------------------------------------------------------

  .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;DMA転送開始直前のキャッシュフラッシュ
cache_flush:
    .if SCSI_BIOS_LEVEL<=10
	move.l	d0,-(sp)
	if	<cmpi.b #1,BIOS_MPU_TYPE.w>,hi
		.cpu	68030
		movec.l	cacr,d0
		or.w	#$0808,d0
		movec.l	d0,cacr
		and.w	#$F7F7,d0
		movec.l	d0,cacr
		.cpu	68000
	endif
	move.l	(sp)+,d0
    .else
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
			move.l	d0,-(sp)
			.cpu	68030
		;68030のcacr
		;| 15| 14| 13| 12| 11| 10|  9|  8|  7|  6|  5|  4|  3|  2|  1|  0|
		;|  0|  0| WA|DBE| CD|CED| FD| ED|  0|  0|  0|IBE| CI|CEI| FI| EI|
		;CDとCIは1を書き込むとキャッシュクリアで常に0で読み出される。0を書き込んでも意味がない
			movec.l	cacr,d0
			or.w	#$0808,d0
			movec.l	d0,cacr
			.cpu	68000
			move.l	(sp)+,d0
		else				;040/060
			.cpu	68040
			cpusha	bc
			.cpu	68000
		endif
	endif
    .endif
	rts
  .endif



;--------------------------------------------------------------------------------
;	.include	sc09sasi.s
;--------------------------------------------------------------------------------

  .if 10<=SCSI_BIOS_LEVEL
;----------------------------------------------------------------
;SASIハードディスクを初期化する
dskini_all:
	push	d0-d4/a1/a6
	move.w	#$8000,d1
	moveq.l	#16-1,d2
	for	d2
		lea.l	0.w,a1
    .if SCSI_BIOS_LEVEL<=10
		bsr	scsi_43_B_DSKINI	;IOCSコール$43 _B_DSKINI(SCSI)
    .else
		bsr	iocs_43_B_DSKINI	;IOCSコール$43 _B_DSKINI
    .endif
		add.w	#1<<8,d1
	next
	pop
	rts
  .endif

  .if SCSI_BIOS_LEVEL<>10
;----------------------------------------------------------------
;SCSIバスに接続されているSASI機器をIOCSコール$40～$4Fで操作できるようにする
install_sasi_iocs:
	push	d0/d1/d2/d3/d4/a1/aSPC
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_SEEK,d1
	lea.l	iocs_40_B_SEEK(pc),a1	;IOCSコール$40 _B_SEEK
	trap	#15
    .if SCSI_BIOS_LEVEL<=10
	move.l	d0,(BIOS_SCSI_OLD_SEEK)abs	;IOCSコール$40 _B_SEEKの元のベクタ
    .else
	move.l	d0,(BIOS_SCSI_OLD_SEEK_16)abs	;IOCSコール$40 _B_SEEKの元のベクタ
    .endif
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_VERIFY,d1
	lea.l	iocs_41_B_VERIFY(pc),a1	;IOCSコール$41 _B_VERIFY
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_VERIFY)abs	;IOCSコール$41 _B_VERIFYの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_DSKINI,d1
	lea.l	iocs_43_B_DSKINI(pc),a1	;IOCSコール$43 _B_DSKINI
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_DSKINI)abs	;IOCSコール$43 _B_DSKINIの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_DRVSNS,d1
	lea.l	iocs_44_B_DRVSNS(pc),a1	;IOCSコール$44 _B_DRVSNS
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_DRVSNS)abs	;IOCSコール$44 _B_DRVSNSの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_WRITE,d1
	lea.l	iocs_45_B_WRITE(pc),a1	;IOCSコール$45 _B_WRITE
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_WRITE)abs	;IOCSコール$45 _B_WRITEの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_READ,d1
	lea.l	iocs_46_B_READ(pc),a1	;IOCSコール$46 _B_READ
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_READ)abs	;IOCSコール$46 _B_READの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_RECALI,d1
	lea.l	iocs_47_B_RECALI(pc),a1	;IOCSコール$47 _B_RECALI
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_RECALI)abs	;IOCSコール$47 _B_RECALIの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_ASSIGN,d1
	lea.l	iocs_48_B_ASSIGN(pc),a1	;IOCSコール$48 _B_ASSIGN
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_ASSIGN)abs	;IOCSコール$48 _B_ASSIGNの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_BADFMT,d1
	lea.l	iocs_4B_B_BADFMT(pc),a1	;IOCSコール$4B _B_BADFMT
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_BADFMT)abs	;IOCSコール$4B _B_BADFMTの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_FORMAT,d1
	lea.l	iocs_4D_B_FORMAT(pc),a1	;IOCSコール$4D _B_FORMAT
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_FORMAT)abs	;IOCSコール$4D _B_FORMATの元のベクタ
	moveq.l	#_B_INTVCS,d0
	move.w	#$100+_B_EJECT,d1
	lea.l	iocs_4F_B_EJECT(pc),a1	;IOCSコール$4F _B_EJECT
	trap	#15
	move.l	d0,(BIOS_SCSI_OLD_EJECT)abs	;IOCSコール$4F _B_EJECTの元のベクタ
;SASIハードディスクを初期化する
	move.w	#$8000,d1
	moveq.l	#16-1,d2
	for	d2
		movea.l	#0,a1
		bsr	iocs_43_B_DSKINI	;IOCSコール$43 _B_DSKINI
		add.w	#1<<8,d1
	next
	pop
	rts
  .endif

  .if SCSI_BIOS_LEVEL<>10

;----------------------------------------------------------------
;IOCSコール$40 _B_SEEK シーク
iocs_40_B_SEEK:
	move.l	(BIOS_SCSI_OLD_SEEK)abs,-(sp)	;IOCSコール$40 _B_SEEKの元のベクタ
	push	d1/d4/a5
	lea.l	scsi_2D_S_SEEK(pc),a5	;SCSIコール$2D _S_SEEK
	goto	iocs_40_44_47_48_4b_4d_common	;IOCSコール$40～$4Fの処理

;----------------------------------------------------------------
;IOCSコール$47 _B_RECALI トラック0へのシーク
iocs_47_B_RECALI:
	move.l	(BIOS_SCSI_OLD_RECALI)abs,-(sp)	;IOCSコール$47 _B_RECALIの元のベクタ
	push_again
	lea.l	scsi_2B_S_REZEROUNIT(pc),a5	;SCSIコール$2B _S_REZEROUNIT
	goto	iocs_40_44_47_48_4b_4d_common	;IOCSコール$40～$4Fの処理

;----------------------------------------------------------------
;IOCSコール$48 _B_ASSIGN
iocs_48_B_ASSIGN:
	move.l	(BIOS_SCSI_OLD_ASSIGN)abs,-(sp)	;IOCSコール$48 _B_ASSIGNの元のベクタ
	push_again
	lea.l	scsi_39_S_ASSIGN(pc),a5	;SCSIコール$39 _S_ASSIGN
	goto	iocs_40_44_47_48_4b_4d_common	;IOCSコール$40～$4Fの処理

;----------------------------------------------------------------
;IOCSコール$4B _B_BADFMT バッドトラックを使用不能にする
iocs_4B_B_BADFMT:
	move.l	(BIOS_SCSI_OLD_BADFMT)abs,-(sp)	;IOCSコール$4B _B_BADFMTの元のベクタ
	push_again
	lea.l	scsi_38_S_BADFMT(pc),a5	;SCSIコール$38 _S_BADFMT
	goto	iocs_40_44_47_48_4b_4d_common	;IOCSコール$40～$4Fの処理

;----------------------------------------------------------------
;IOCSコール$4D _B_FORMAT 物理フォーマット
iocs_4D_B_FORMAT:
	move.l	(BIOS_SCSI_OLD_FORMAT)abs,-(sp)	;IOCSコール$4D _B_FORMATの元のベクタ
	push_again
	lea.l	scsi_37_S_FORMATB(pc),a5	;SCSIコール$37 _S_FORMATB
	goto	iocs_40_44_47_48_4b_4d_common	;IOCSコール$40～$4Fの処理

;----------------------------------------------------------------
;IOCSコール$44 _B_DRVSNS
iocs_44_B_DRVSNS:
	move.l	(BIOS_SCSI_OLD_DRVSNS)abs,-(sp)	;IOCSコール$44 _B_DRVSNSの元のベクタ
	push_again
	lea.l	scsi_24_S_TESTUNIT(pc),a5	;SCSIコール$24 _S_TESTUNIT
;!!! 直後へのbra。サイズを書かないと削除される
	bra.w	iocs_40_44_47_48_4b_4d_common	;IOCSコール$40～$4Fの処理

;----------------------------------------------------------------
;ここから_B_SEEK、_B_RECALI、_B_ASSIGN、_B_BADFMT、_B_FORMAT、_B_DRVSNS共通
iocs_40_44_47_48_4b_4d_common:

  .else

;----------------------------------------------------------------
;IOCSコール$40 _B_SEEK シーク
scsi_40_B_SEEK:
	lea.l	scsi_2D_S_SEEK(pc),a0	;SCSIコール$2D _S_SEEK
	goto	scsi_40_44_47_48_4b_4d_common	;IOCSコール$40～$4F(SCSI)の処理

;----------------------------------------------------------------
;IOCSコール$47 _B_RECALI トラック0へのシーク
scsi_47_B_RECALI:
	lea.l	scsi_2B_S_REZEROUNIT(pc),a0	;SCSIコール$2B _S_REZEROUNIT
	goto	scsi_40_44_47_48_4b_4d_common	;IOCSコール$40～$4F(SCSI)の処理

;----------------------------------------------------------------
;IOCSコール$48 _B_ASSIGN
scsi_48_B_ASSIGN:
	lea.l	scsi_39_S_ASSIGN(pc),a0	;SCSIコール$39 _S_ASSIGN
	goto	scsi_40_44_47_48_4b_4d_common	;IOCSコール$40～$4F(SCSI)の処理

;----------------------------------------------------------------
;IOCSコール$4B _B_BADFMT バッドトラックを使用不能にする
scsi_4B_B_BADFMT:
	lea.l	scsi_38_S_BADFMT(pc),a0	;SCSIコール$38 _S_BADFMT
	goto	scsi_40_44_47_48_4b_4d_common	;IOCSコール$40～$4F(SCSI)の処理

;----------------------------------------------------------------
;IOCSコール$4D _B_FORMAT 物理フォーマット
scsi_4D_B_FORMAT:
	lea.l	scsi_37_S_FORMATB(pc),a0	;SCSIコール$37 _S_FORMATB
	goto	scsi_40_44_47_48_4b_4d_common	;IOCSコール$40～$4F(SCSI)の処理

;----------------------------------------------------------------
;IOCSコール$44 _B_DRVSNS
scsi_44_B_DRVSNS:
	lea.l	scsi_24_S_TESTUNIT(pc),a0	;SCSIコール$24 _S_TESTUNIT
;----------------------------------------------------------------
;ここから_B_SEEK、_B_RECALI、_B_ASSIGN、_B_BADFMT、_B_FORMAT、_B_DRVSNS共通
scsi_40_44_47_48_4b_4d_common:
	push	d1/d4/a5
	movea.l	a0,a5

  .endif

	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_40_44_47_48_4b_4d_not_hd	;HDではない
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_40_44_47_48_4b_4d_not_sasi	;SASIフラグがセットされていない
	jsr	(a5)			;SCSIコールを呼ぶ
;<d0.l:0=成功,-1=失敗,その他=MSGIN<<16|STSIN

  .if SCSI_BIOS_LEVEL<>10

    .if SCSI_BIOS_LEVEL<=10
      .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASIのステータスバイトの一部を無視する
      .endif
	goto	<tst.l d0>,ne,scsi_40_44_47_48_4b_4d_error
    .else
	goto	<btst.l #1,d0>,ne,scsi_40_44_47_48_4b_4d_error	;Check Condition
    .endif
	moveq.l	#0,d0
	pop_test
	addq.l	#4,sp			;元の処理を呼ばない
	rts

scsi_40_44_47_48_4b_4d_error:
	ori.l	#$FFFFFF00,d0
	pop_test
	addq.l	#4,sp			;元の処理を呼ばない
	rts

;SASIフラグがセットされていない
scsi_40_44_47_48_4b_4d_not_sasi:
;HDではない
iocs_40_44_47_48_4b_4d_not_hd:
	pop
	rts				;元の処理を呼ぶ

  .else

	goto	<btst.l #1,d0>,ne,scsi_40_44_47_48_4b_4d_error	;Check Condition
	moveq.l	#0,d0
scsi_40_44_47_48_4b_4d_end:
	pop
	rts

;SASIフラグがセットされていない
scsi_40_44_47_48_4b_4d_not_sasi:
	moveq.l	#-1,d0
scsi_40_44_47_48_4b_4d_error:
	ori.l	#$FFFFFF00,d0
	goto	scsi_40_44_47_48_4b_4d_end

  .endif

;----------------------------------------------------------------
;IOCSコール$4F _B_EJECT イジェクト／シッピング
;<d1.w:
;	FD	$9000|FD-ID(0～3)<<8|MFM(0～1)<<6|RETRY(0～1)<<5|SEEK(0～1)<<4
;	HD	$8000|HD-ID(0～15)<<8
;		HD-ID(0～15)=SCSI-ID(0～7)<<1|LUN(0～1)
;>d0.l:
;	FD	不定
;	HD	0以上=成功,-1以下=失敗
  .if SCSI_BIOS_LEVEL<>10
iocs_4F_B_EJECT:
	move.l	(BIOS_SCSI_OLD_EJECT)abs,-(sp)
  .else
scsi_4F_B_EJECT:
  .endif
	push	d1/d2/d3/d4/d5/d6/d7/a1/a4
	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_4f_not_hd	;HDではない
  .endif
	move.l	d4,d1
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_4f_not_sasi	;SASIフラグがセットされていない

  .if SCSI_BIOS_LEVEL<=4

	lea.l	BIOS_SASI_CAPACITY.l,a4	;SASIハードディスクの容量の配列。0=未確認,10=10MB,20=20MB,40=40MB,128=非接続
	move.l	d1,d0
	ror.w	#8,d0
	and.l	#15,d0			;HD-ID
	adda.l	d0,a4
	move.b	(a4),d0
	if	<btst.l #7,d0>,eq	;接続
		and.b	#$7F,d0
		if	ne			;確認済み
			move.l	#33*4*664,d2		;20MBシッピングゾーン
		;!!! 不要
    .if SCSI_BIOS_LEVEL<=0
			lea.l	sasi_20mb_shipping_parameter,a1	;20MBドライブパラメータ(シッピングゾーン)
    .else
			lea.l	sasi_20mb_shipping_parameter(pc),a1	;20MBドライブパラメータ(シッピングゾーン)
    .endif
			if	<cmp.b #20,d0>,ne	;20MB
				move.l	#33*8*664,d2		;40MBシッピングゾーン
			;!!! 不要
    .if SCSI_BIOS_LEVEL<=0
				lea.l	sasi_40mb_shipping_parameter,a1	;40MBドライブパラメータ(シッピングゾーン)
    .else
				lea.l	sasi_40mb_shipping_parameter(pc),a1	;40MBドライブパラメータ(シッピングゾーン)
    .endif
				if	<cmp.b #40,d0>,ne	;40MB
					move.l	#33*4*340,d2		;10MBシッピングゾーン
				;!!! 不要
    .if SCSI_BIOS_LEVEL<=0
					lea.l	sasi_10mb_shipping_parameter,a1	;10MBドライブパラメータ(シッピングゾーン)
    .else
					lea.l	sasi_10mb_shipping_parameter(pc),a1	;10MBドライブパラメータ(シッピングゾーン)
    .endif
				endif
			endif
		;!!! ROM 1.0～1.2のSASI BIOSの_B_EJECTはシッピングゾーンをSET DRIVE PARAMETERしてからSEEKしている
			bsr	scsi_2D_S_SEEK		;SCSIコール$2D _S_SEEK
		endif
	endif
;非接続または未確認
;+++++ BUG +++++
;内蔵SASIハードディスクをシッピングできなくなる
;	SASIフラグがセットされていないとき内蔵SASIハードディスクをシッピングしなければならないのに元の処理を呼んでいない
;SASIフラグがセットされていない
scsi_4f_not_sasi:
;+++++ BUG +++++
	pop_test
	addq.l	#4,sp			;元の処理を呼ばない
	rts

;HDではない
iocs_4f_not_hd:
	pop
	rts				;元の処理を呼ぶ

;+++++ BUG +++++
;どこからも参照されていない
	andi.w	#$F000,d1
	if	<cmp.w #$8000,d1>,eq
		movem.l	(sp)+,d1
		addq.l	#4,sp
		moveq.l	#0,d0
		rts

	endif
	movem.l	(sp)+,d1
	rts
;+++++ BUG +++++

  .else

	lea.l	BIOS_SASI_CAPACITY.w,a4	;SASIハードディスクの容量の配列。0=未確認,10=10MB,20=20MB,40=40MB,128=非接続
	move.w	d1,d0
	ror.w	#8,d0
	and.w	#15,d0			;HD-ID
	move.b	(a4,d0.w),d0
;!!! 不要
	ifand	<tst.b d0>,pl,<>,ne
	;接続、確認済み
		move.l	#33*4*664,d2		;20MBシッピングゾーン
		if	<cmp.b #20,d0>,ne
			move.l	#33*8*664,d2		;40MBシッピングゾーン
			if	<cmp.b #40,d0>,ne
				move.l	#33*4*340,d2		;10MBシッピングゾーン
				if	<cmp.b #10,d0>,ne
					goto	scsi_4f_end		;10MB/20MB/40MBのいずれでもない
				endif
			endif
		endif
	;!!! ROM 1.0～1.2のSASI BIOSの_B_EJECTはシッピングゾーンをSET DRIVE PARAMETERしてからSEEKしている
		bsr	scsi_2D_S_SEEK		;SCSIコール$2D _S_SEEK
		moveq.l	#0,d0
	endif
;非接続または未確認
scsi_4f_end:

    .if SCSI_BIOS_LEVEL<=10

;SASIフラグがセットされていない
scsi_4f_not_sasi:
	pop
	rts

    .else

	pop_test
	addq.l	#4,sp			;元の処理を呼ばない
	rts

;SASIフラグがセットされていない
scsi_4f_not_sasi:
;HDではない
iocs_4f_not_hd:
	pop
	rts				;元の処理を呼ぶ

    .endif

  .endif

;----------------------------------------------------------------
;IOCSコール$46 _B_READ 読み出し
;<d1.w:ドライブ
;	HD	$8000|HD-ID(0～15)<<8
;		HD-ID(0～15)=SCSI-ID(0～7)<<1|LUN(0～1)
;	FD	$9000|FD-ID(0～3)<<8|MFM(0～1)<<6|RETRY(0～1)<<5|SEEK(0～1)<<4
;<d2.l:位置
;	HD	レコード番号
;	FD	レコード長(0～7)<<24|シリンダ番号(0～)<<16|ヘッド番号(0～1)<<8|セクタ番号(1～)
;<d3.l:バイト数
;<a1.l:アドレス
;>d0.l:結果
;	HD	0以上=成功,-1以下=失敗。$FFFFFF00|エラーコード=失敗
;	FD	ST0<<24|ST1<<16|ST2<<8|シリンダ番号
;----------------------------------------------------------------
;IOCSコール$45 _B_WRITE 書き込み
;<d1.w:ドライブ
;	HD	$8000|HD-ID(0～15)<<8
;		HD-ID(0～15)=SCSI-ID(0～7)<<1|LUN(0～1)
;	FD	$9000|FD-ID(0～3)<<8|MFM(0～1)<<6|RETRY(0～1)<<5|SEEK(0～1)<<4
;<d2.l:位置
;	HD	レコード番号
;	FD	レコード長(0～7)<<24|シリンダ番号(0～)<<16|ヘッド番号(0～1)<<8|セクタ番号(1～)
;<d3.l:バイト数
;<a1.l:アドレス
;>d0.l:結果
;	HD	0以上=成功,$FFFFFF00|STSIN=失敗
;	FD	ST0<<24|ST1<<16|ST2<<8|シリンダ番号

  .if SCSI_BIOS_LEVEL<>10

iocs_46_B_READ:
	move.l	(BIOS_SCSI_OLD_READ)abs,-(sp)	;IOCSコール$46 _B_READの元のベクタ
	push	d1/d2/d3/d4/d5/d6/a1/a2/a5
	lea.l	scsi_21_S_READ(pc),a5	;SCSIコール$21 _S_READ
	goto	iocs_45_46_common	;ここから_B_READ、_B_WRITE共通

iocs_45_B_WRITE:
	move.l	(BIOS_SCSI_OLD_WRITE)abs,-(sp)	;IOCSコール$45 _B_WRITEの元のベクタ
	push_again
	lea.l	scsi_22_S_WRITE(pc),a5	;SCSIコール$22 _S_WRITE
;!!! 直後へのbra。サイズを書かないと削除される
	bra.w	iocs_45_46_common		;ここから_B_READ、_B_WRITE共通

;ここから_B_READ、_B_WRITE共通
;<a5.l:_S_READまたは_S_WRITE
iocs_45_46_common:

  .else

scsi_46_B_READ:
	lea.l	scsi_21_S_READ(pc),a0	;SCSIコール$21 _S_READ
	goto	scsi_45_46_common	;ここから_B_READ(SCSI)、_B_WRITE(SCSI)共通

scsi_45_B_WRITE:
	lea.l	scsi_22_S_WRITE(pc),a0	;SCSIコール$22 _S_WRITE
;ここから_B_READ、_B_WRITE共通
;<a0.l:_S_READまたは_S_WRITE
scsi_45_46_common:
	push	d1/d2/d3/d4/d5/d6/a1/a2/a5
	movea.l	a0,a5			;_S_READまたは_S_WRITE

  .endif

	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_45_46_not_hd	;HDではない
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_45_46_not_sasi	;SASIフラグがセットされていない
	move.l	d3,d6			;残りのバイト数
	do
		move.l	d6,d3			;残りのバイト数
		add.l	#255,d3
		lsr.l	#8,d3			;今回のレコード数。256バイト/レコード
		if	<cmp.l #256,d3>,hi
			move.l	#256,d3			;一度に転送するレコード数の上限
		endif
		moveq.l	#0,d5			;レコード長。0=256バイト/レコード
		jsr	(a5)			;_S_READまたは_S_WRITE
  .if SCSI_BIOS_LEVEL<=3
	;+++++ BUG +++++
	;_S_READまたは_S_WRITEがエラーをzで返さないと検出できない
	;+++++ BUG +++++
		goto	ne,scsi_45_46_error
  .elif SCSI_BIOS_LEVEL<=4
		andi.l	#$FFFFFF1E,d0		;SASIのステータスバイトの一部を無視する
		goto	<tst.l d0>,ne,scsi_45_46_error
  .else
		goto	<btst.l #1,d0>,ne,scsi_45_46_error	;Check Condition
  .endif
		add.l	d3,d2			;次回のレコード番号
		move.l	d3,d1
		lsl.l	#8,d1			;今回のバイト数
		adda.l	d1,a1			;次回のアドレス
		sub.l	d1,d6			;次回の残りのバイト数
	while	hi

  .if SCSI_BIOS_LEVEL<>10

	pop_test
	addq.l	#4,sp			;元の処理を呼ばない
	moveq.l	#0,d0
	rts

scsi_45_46_error:
	pop_test
	addq.l	#4,sp			;元の処理を呼ばない
	ori.l	#$FFFFFF00,d0
	rts

;SASIフラグがセットされていない
scsi_45_46_not_sasi:
;HDではない
iocs_45_46_not_hd:
	pop
	rts				;元の処理を呼ぶ

  .else

	moveq.l	#0,d0
scsi_45_46_end:
	pop
	rts

;SASIフラグがセットされていない
scsi_45_46_not_sasi:
	moveq.l	#-1,d0
scsi_45_46_error:
	ori.l	#$FFFFFF00,d0
	goto	scsi_45_46_end

  .endif

;----------------------------------------------------------------
;IOCSコール$41 _B_VERIFY ベリファイ
;<d1.w:ドライブ
;	HD	$8000|HD-ID(0～15)<<8
;		HD-ID(0～15)=SCSI-ID(0～7)<<1|LUN(0～1)
;	FD	$9000|FD-ID(0～3)<<8|MFM(0～1)<<6|RETRY(0～1)<<5|SEEK(0～1)<<4
;<d2.l:位置
;	HD	レコード番号
;	FD	レコード長(0～7)<<24|シリンダ番号(0～)<<16|ヘッド番号(0～1)<<8|セクタ番号(1～)
;<d3.l:バイト数
;<a1.l:アドレス
;>d0.l:結果
;	HD	0=一致,-2=不一致
;	FD	ST0<<24|PCN<<16
  .if SCSI_BIOS_LEVEL<>10
iocs_41_B_VERIFY:
  .else
scsi_41_B_VERIFY:
  .endif
	link.w	a4,#-256
	push	d1/d2/d3/d4/d5/d6/a1/a2
	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_b_verify_not_hd	;HDではない
	move.l	d4,d1
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_b_verify_not_sasi	;SASIフラグがセットされていない
	movea.l	a1,a2			;アドレス
	move.l	d3,d6			;残りのバイト数
	do
		move.l	d6,d3			;残りのバイト数
		if	<cmp.l #256,d3>,cc
			move.l	#256,d3			;一度に読み込むバイト数の上限。256バイト/レコード
		endif
	;!!! スーパーバイザスタックに読み込んでいる。ローカルメモリがあるときDMAが届くとは限らない
		lea.l	-256(a4),a1
  .if SCSI_BIOS_LEVEL<>10
		bsr	iocs_46_B_READ		;IOCSコール$46 _B_READ 読み出し
  .else
		bsr	scsi_46_B_READ		;IOCSコール$46 _B_READ(SCSI) 読み出し
  .endif
		move.l	d3,d5
		subq.l	#1,d5
		for	d5
			cmpm.b	(a1)+,(a2)+
			goto	ne,scsi_b_verify_error	;不一致
		next
		addq.l	#1,d2			;次回のレコード番号
		sub.l	d3,d6			;次回の残りのバイト数
	while	hi

  .if SCSI_BIOS_LEVEL<>10

	pop_test
	unlk	a4
	moveq.l	#0,d0			;一致
	rts				;元の処理を呼ばない

scsi_b_verify_error:
	moveq.l	#-2,d0			;不一致
	pop_test
	unlk	a4
	ori.l	#$FFFFFF00,d0		;-2のまま
	rts				;元の処理を呼ばない

;SASIフラグがセットされていない
scsi_b_verify_not_sasi:
;HDではない
iocs_b_verify_not_hd:
	pop
	unlk	a4
	move.l	(BIOS_SCSI_OLD_VERIFY)abs,-(sp)	;IOCSコール$41 _B_VERIFYの元のベクタ
	rts				;元の処理を呼ぶ

  .else

	moveq.l	#0,d0			;一致
scsi_b_verify_end:
	pop
	unlk	a4
	rts

scsi_b_verify_error:
	moveq.l	#-2,d0			;不一致
	ori.l	#$FFFFFF00,d0		;-2のまま
	goto	scsi_b_verify_end

;SASIフラグがセットされていない
scsi_b_verify_not_sasi:
	moveq.l	#-1,d0
	goto	scsi_b_verify_end

  .endif

;----------------------------------------------------------------
;IOCSコール$43 _B_DSKINI 初期化
;<d1.w:ドライブ
;	HD	$8000|HD-ID(0～15)<<8
;		HD-ID(0～15)=SCSI-ID(0～7)<<1|LUN(0～1)
;	FD	$9000|FD-ID(0～3)<<8
;<d2.w:
;	HD	なし
;	FD	モーター停止時間(10ms単位)。0=デフォルト(2秒)
;<a1.l:
;	HD	ドライブパラメータのアドレス。0=デフォルト
;	FD	Specifyコマンドのアドレス。0=デフォルト
;>d0.l:結果
;	HD	0=成功,$FFFFFF00|STSIN=失敗
;	FD	ST3<<24|不定
  .if SCSI_BIOS_LEVEL<>10
iocs_43_B_DSKINI:
  .else
scsi_43_B_DSKINI:
  .endif
	link.w	a4,#-256
  .if SCSI_BIOS_LEVEL<=10
;+++++ BUG +++++
;d5/a2を破壊している
	push	d1/d2/d3/d4/a1/a5
;+++++ BUG +++++
  .else
	push	d1/d2/d3/d4/d5/a1/a2/a5
  .endif
	moveq.l	#0,d4
	move.w	d1,d4
  .if SCSI_BIOS_LEVEL<>10
	andi.w	#$F000,d1
	goto	<cmp.w #$8000,d1>,ne,iocs_b_dskini_not_hd	;HDではない
  .endif
	lsr.w	#8,d4
	lsr.w	#1,d4			;SCSI-ID=HD-ID/2
	if	cs
		bset.l	#16,d4			;LUN=HD-ID%2
	endif
	andi.w	#7,d4			;SCSI-ID
	goto	<btst.b d4,SRAM_SCSI_SASI_FLAG>,eq,scsi_b_dskini_not_sasi	;SASIフラグがセットされていない
	move.l	a1,d0			;初期化パラメータ
	goto	eq,scsi_b_dskini_default	;デフォルトのドライブパラメータを使う
scsi_b_dskini_go:
	moveq.l	#10,d3			;ドライブパラメータの長さ。10バイト
	bsr	scsi_36_S_DSKINI	;SCSIコール$36 _S_DSKINI

  .if SCSI_BIOS_LEVEL<>10

    .if SCSI_BIOS_LEVEL<=10
      .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASIのステータスバイトの一部を無視する
      .endif
	goto	<tst.l d0>,ne,scsi_b_dskini_error	;失敗
    .else
	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
    .endif
    .if SCSI_BIOS_LEVEL<=3
	;!!! このbsrは$617Eで届くが$61000080になっている
	bsr.w	sasi_param_to_capacity	;ドライブパラメータからSASIハードディスクの容量を求める
    .else
	bsr	sasi_param_to_capacity	;ドライブパラメータからSASIハードディスクの容量を求める
    .endif
	moveq.l	#0,d0
	pop_test
	unlk	a4
	rts				;元の処理を呼ばない

;失敗
scsi_b_dskini_error:
	ori.l	#$FFFFFF00,d0
	pop_test
	unlk	a4
	rts				;元の処理を呼ばない

;SASIフラグがセットされていない
scsi_b_dskini_not_sasi:
;HDではない
iocs_b_dskini_not_hd:
	pop
	unlk	a4
	move.l	(BIOS_SCSI_OLD_DSKINI)abs,-(sp)	;IOCSコール$43 _B_DSKINIの元のベクタ
	rts				;元の処理を呼ぶ

  .else

	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
;ドライブパラメータからSASIハードディスクの容量を求める
	lea.l	BIOS_SASI_CAPACITY.w,a5	;SASIハードディスクの容量の配列。0=未確認,10=10MB,20=20MB,40=40MB,128=非接続
	move.w	d1,d0
	ror.w	#8,d0
	and.w	#15,d0			;HD-ID
	adda.w	d0,a5
	moveq.l	#40,d0			;40MB
	if	<cmpi.b #$07,3(a1)>,ne
		moveq.l	#20,d0			;20MB
		if	<cmpi.b #$02,4(a1)>,ne
			moveq.l	#10,d0			;10MB
		endif
	endif
	move.b	d0,(a5)
	moveq.l	#0,d0
scsi_b_dskini_end:
	pop
	unlk	a4
	rts

;SASIフラグがセットされていない
scsi_b_dskini_not_sasi:
	moveq.l	#-1,d0
;Check Condition
scsi_b_dskini_error:
	ori.l	#$FFFFFF00,d0
	goto	scsi_b_dskini_end

  .endif

;デフォルトのドライブパラメータを使う
scsi_b_dskini_default:
	moveq.l	#10,d3			;ドライブパラメータの長さ。10バイト
  .if SCSI_BIOS_LEVEL<=4
;20MBドライブパラメータ(シッピングゾーン)を設定する
    .if SCSI_BIOS_LEVEL<=0
	lea.l	sasi_20mb_shipping_parameter,a1	;20MBドライブパラメータ(シッピングゾーン)
    .else
	lea.l	sasi_20mb_shipping_parameter(pc),a1	;20MBドライブパラメータ(シッピングゾーン)
    .endif
  .else
;40MBドライブパラメータ(シッピングゾーン)を設定する
	lea.l	sasi_40mb_shipping_parameter(pc),a1	;40MBドライブパラメータ(シッピングゾーン)
  .endif
	bsr	scsi_36_S_DSKINI	;SCSIコール$36 _S_DSKINI
  .if SCSI_BIOS_LEVEL<=4
    .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASIのステータスバイトの一部を無視する
    .endif
	goto	<tst.l d0>,ne,scsi_b_dskini_error
  .else  ;10<=SCSI_BIOS_LEVEL
	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
  .endif
;レコード4から256バイト読み込む
	lea.l	-256(a4),a1
	moveq.l	#$0400/256,d2
	moveq.l	#$0100/256,d3
	moveq.l	#0,d5			;256バイト/レコード
	bsr	scsi_21_S_READ		;SCSIコール$21 _S_READ
  .if SCSI_BIOS_LEVEL<=4
    .if 4<=SCSI_BIOS_LEVEL
	andi.l	#$FFFFFF1E,d0		;SASIのステータスバイトの一部を無視する
    .endif
	goto	<tst.l d0>,ne,scsi_b_dskini_error	;読み込めない
  .else  ;10<=SCSI_BIOS_LEVEL
	goto	<btst.l #1,d0>,ne,scsi_b_dskini_error	;Check Condition
  .endif
	lea.l	-256(a4),a2
  .if SCSI_BIOS_LEVEL<=4
    .if SCSI_BIOS_LEVEL<=0
	lea.l	sasi_10mb_drive_parameter,a1	;10MBドライブパラメータ
    .else
	lea.l	sasi_10mb_drive_parameter(pc),a1	;10MBドライブパラメータ
    .endif
	goto	<cmpi.l #'X68K',0.w(a2)>,ne,scsi_b_dskini_error	;装置初期化されていない
;装置初期化されている
    .if SCSI_BIOS_LEVEL<=0
	lea.l	sasi_10mb_drive_parameter,a1	;10MBドライブパラメータ
    .else
	lea.l	sasi_10mb_drive_parameter(pc),a1	;10MBドライブパラメータ
    .endif
	move.l	4(a2),d0		;レコード数
  .else  ;10<=SCSI_BIOS_LEVEL
	goto	<cmpi.l #'X68K',(a2)+>,ne,scsi_b_dskini_error	;装置初期化されていない
;装置初期化されている
	lea.l	sasi_10mb_drive_parameter(pc),a1	;10MBドライブパラメータ
	move.l	(a2),d0			;レコード数
  .endif
	goto	<cmp.l #33*4*310+1,d0>,cs,scsi_b_dskini_go	;10MBは309シリンダだが310シリンダまで10MBと見なす
	lea.l	sasi_20mb_drive_parameter-sasi_10mb_drive_parameter(a1),a1	;20MBドライブパラメータ
	goto	<cmp.l #33*4*615+1,d0>,cs,scsi_b_dskini_go	;20MBは614シリンダだが615シリンダまで20MBと見なす
	lea.l	sasi_40mb_drive_parameter-sasi_20mb_drive_parameter(a1),a1	;40MBドライブパラメータ
	goto	scsi_b_dskini_go

  .if SCSI_BIOS_LEVEL<>10
;----------------------------------------------------------------
;ドライブパラメータからSASIハードディスクの容量を求める
;<d1.w:HD-ID<<8
;<a1.l:ドライブパラメータ
sasi_param_to_capacity:
	lea.l	BIOS_SASI_CAPACITY.l,a5	;SASIハードディスクの容量の配列。0=未確認,10=10MB,20=20MB,40=40MB,128=非接続
	move.l	d1,d0
	ror.w	#8,d0
	and.l	#15,d0			;HD-ID
	adda.l	d0,a5
	move.b	#40,d0			;40MB
	if	<cmpi.b #$07,3(a1)>,ne
		move.b	#20,d0			;20MB
		if	<cmpi.b #$02,4(a1)>,ne
			move.b	#10,d0			;10MB
		endif
	endif
	move.b	d0,(a5)
	clr.l	d0
	rts
  .endif

  .if SCSI_BIOS_LEVEL<=0
;----------------------------------------------------------------
;Test Unit Readyコマンド
test_unit_ready_command:
	.dc.b	$00			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Rezero Unitコマンド
rezero_unit_command:
	.dc.b	$01			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Read(6)コマンド
read_6_command_2nd:
	.dc.b	$08			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|論理ブロックアドレス(上位)#####
	.dc.b	$00			;2 論理ブロックアドレス(中位)
	.dc.b	$00			;3 論理ブロックアドレス(下位)
	.dc.b	$00			;4 転送データ長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Read Capacityコマンド
read_capacity_command:
	.dc.b	$25			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved####|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 Reserved
	.dc.b	$00			;8 Reserved#######|PMI
	.dc.b	$00			;9 コントロールバイト

;----------------------------------------------------------------
;Inquiryコマンド
inquiry_command:
	.dc.b	$12			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved####|EVPD
	.dc.b	$00			;2 ページコード
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 アロケーション長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Request Senseコマンド
request_sense_command:
	.dc.b	$03			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 アロケーション長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Mode Sense(6)コマンド
mode_sense_6_command:
	.dc.b	$1A			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|R|DBD|Reserved###
	.dc.b	$00			;2 PC##|ページコード######
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 アロケーション長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Mode Select(6)コマンド
mode_select_6_command:
	.dc.b	$15			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|PF|Reserved###|SP
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 パラメータリスト長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Reassign Blocksコマンド
reassign_blocks_command:
	.dc.b	$07			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Read(6)コマンド
read_6_command:
	.dc.b	$08			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|論理ブロックアドレス(上位)#####
	.dc.b	$00			;2 論理ブロックアドレス(中位)
	.dc.b	$00			;3 論理ブロックアドレス(下位)
	.dc.b	$00			;4 転送データ長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Write(6)コマンド
write_6_command:
	.dc.b	$0A			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|論理ブロックアドレス(上位)#####
	.dc.b	$00			;2 論理ブロックアドレス(中位)
	.dc.b	$00			;3 論理ブロックアドレス(下位)
	.dc.b	$00			;4 転送データ長
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Read(10)コマンド
read_10_command:
	.dc.b	$28			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 転送データ長(上位)
	.dc.b	$00			;8 転送データ長(下位)
	.dc.b	$00			;9 コントロールバイト

;----------------------------------------------------------------
;Write(10)コマンド
write_10_command:
	.dc.b	$2A			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|DPO|FUA|Reserved##|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 転送データ長(上位)
	.dc.b	$00			;8 転送データ長(下位)
	.dc.b	$00			;9 コントロールバイト

;----------------------------------------------------------------
;Verify(10)コマンド
verify_10_command:
	.dc.b	$2F			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|DPO|Reserved##|BytChk|RelAdr
	.dc.b	$00			;2 論理ブロックアドレス(上位)
	.dc.b	$00			;3   :
	.dc.b	$00			;4   :
	.dc.b	$00			;5 論理ブロックアドレス(下位)
	.dc.b	$00			;6 Reserved
	.dc.b	$00			;7 転送データ長(上位)
	.dc.b	$00			;8 転送データ長(下位)
	.dc.b	$00			;9 コントロールバイト

;----------------------------------------------------------------
;Prevent-Allow Medium Removalコマンド
prevent_allow_command:
	.dc.b	$1E			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved#####
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved#######|Prevent
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Start-Stop Unit(Eject SONY MO)コマンド
start_stop_unit_command:
	.dc.b	$1B			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|Reserved####|Immed
	.dc.b	$00			;2 Reserved
	.dc.b	$00			;3 Reserved
	.dc.b	$00			;4 Reserved######|LoEj|Start
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Load/Unload SHARP MOコマンド
load_unload_command:
	.dc.b	$C1			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|#####
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4 #######|LoEj
	.dc.b	$00			;5

;----------------------------------------------------------------
;Seek(6)コマンド
seek_6_command:
	.dc.b	$0B			;0 オペレーションコード
	.dc.b	$00			;1 LUN###|ブロック番号(上位)#####
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 Reserved
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Assign Drive(SASI)コマンド
assign_drive_sasi_command:
	.dc.b	$C2			;0 オペレーションコード
	.dc.b	$00			;1
	.dc.b	$00			;2
	.dc.b	$00			;3
	.dc.b	$00			;4
	.dc.b	$00			;5 データの長さ

;----------------------------------------------------------------
;Format Block(SASI)コマンド
format_block_sasi_command:
	.dc.b	$06			;0 オペレーションコード
	.dc.b	$00			;1 ブロック番号(上位)
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 インタリーブ
	.dc.b	$00			;5

;----------------------------------------------------------------
;Bad Track Format(SASI)コマンド
bad_track_format_sasi_command:
	.dc.b	$07			;0 オペレーションコード
	.dc.b	$00			;1 ブロック番号(上位)
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 インタリーブ
	.dc.b	$00			;5 コントロールバイト

;----------------------------------------------------------------
;Assign Track(SASI)コマンド
assign_track_sasi_command:
	.dc.b	$0E			;0 オペレーションコード
	.dc.b	$00			;1 ブロック番号(上位)
	.dc.b	$00			;2 ブロック番号(中位)
	.dc.b	$00			;3 ブロック番号(下位)
	.dc.b	$00			;4 インタリーブ
	.dc.b	$00			;5
  .endif

;----------------------------------------------------------------
;10MBドライブパラメータ
sasi_10mb_drive_parameter:
	.dc.b	$01,$01,$00,$03,$01,$35,$80,$00,$00,$00
;				~~~~~~~309
;			    ~~~4-1
  .if SCSI_BIOS_LEVEL<>10
;10MBドライブパラメータ(シッピングゾーン)
sasi_10mb_shipping_parameter:
	.dc.b	$01,$01,$00,$03,$01,$54,$80,$00,$00,$00
;				~~~~~~~340
;			    ~~~4-1
  .endif
;20MBドライブパラメータ
sasi_20mb_drive_parameter:
	.dc.b	$01,$01,$00,$03,$02,$66,$80,$00,$00,$00
;				~~~~~~~614
;			    ~~~4-1
  .if SCSI_BIOS_LEVEL<>10
;20MBドライブパラメータ(シッピングゾーン)
sasi_20mb_shipping_parameter:
	.dc.b	$01,$01,$00,$03,$02,$98,$80,$00,$00,$00
;				~~~~~~~664
;			    ~~~4-1
  .endif
;40MBドライブパラメータ
sasi_40mb_drive_parameter:
	.dc.b	$01,$01,$00,$07,$02,$66,$80,$00,$00,$00
;				~~~~~~~614
;			    ~~~8-1
;40MBドライブパラメータ(シッピングゾーン)
sasi_40mb_shipping_parameter:
	.dc.b	$01,$01,$00,$07,$02,$98,$80,$00,$00,$00
;				~~~~~~~664
;			    ~~~8-1

;----------------------------------------------------------------
;SASIハードディスク
;
;	物理構成
;		10MB	20MB	40MB
;		256	256	256	バイト/レコード
;		33	33	33	レコード/トラック
;		4	4	8	トラック/シリンダ
;		309	614	614	シリンダ/ボリューム
;		340	664	664	シッピングゾーン
;
;	SASIディスクIPL
;		IPLROMが$2000.wに読み込んで実行する
;		起動パーティションを自動または手動で選択し、選択されたパーティションのSASIパーティションIPLを$2400.wに読み込んで実行する
;		アドレス
;		$00000000	SASIディスクIPL
;
;	パーティションテーブル
;		アドレス	10MB		20MB		40MB
;		$00000400	$5836384B	$5836384B	$5836384B	X68Kマジック
;		$00000404	$00009F54	$00013C98	$00027930	レコード数(ディスクイメージのサイズ)
;				33*4*309=40788	33*4*614=81048	33*8*614=162096
;		$00000408	$00009F54	$00013C98	$00027930	代替レコード
;		$0000040C	$0000AF50	$00015660	$0002ACC0	シッピングゾーン
;				33*4*340=44880	33*4*664=87648	33*8*664=175296
;		$00000410	第1パーティションの情報
;		$00000410	$48756D61	$48756D61	$48756D61	Humaマジック
;		$00000414	$6E36386B	$6E36386B	$6E36386B	n68kマジック
;		$00000418	$00000021	$00000021	$00000021	開始レコード
;		$0000041C	$00009F2E	$00013C68	$000278F8	レコード数
;		$00000420	第2パーティションの情報
;			:
;		$000004F0	第15パーティションの情報
;		$00000500	空き
;			:
;
;	第1パーティション(10MBの装置に最大サイズのパーティションを確保した場合)
;		アドレス	セクタ
;		$00002100	$00000000	SASIパーティションIPL
;							SASIディスクIPLが$2400.wに読み込んで実行する
;							ルートディレクトリにあるHUMAN.SYSを$6800.wに読み込んで実行する
;		$00002500	$00000001	第1FAT
;		$00007500	$00000015	第2FAT
;		$0000C500	$00000029	ルートディレクトリ
;		$00010500	$00000039	データ領域
;
;	ドライブ情報(最大サイズのパーティションを確保した場合)
;		10MB	20MB	40MB
;		1024	1024	1024	バイト/セクタ
;		1	1	1	セクタ/クラスタ
;		10132	20155	40335	データ領域のクラスタ数+2
;		1	1	1	予約領域のセクタ数
;		20	40	80	1個のFAT領域に使用するセクタ数
;		41	81	161	ルートディレクトリの先頭セクタ番号
;		512	512	512	ルートディレクトリに入るエントリ数
;		57	97	177	データ領域の先頭セクタ番号
;

scsi_bios_end:

  .if SCSI_BIOS_LEVEL==0
;リロケートテーブル
	.dc.w	$0000,$0004,$0004,$0004,$0004,$0004,$0004,$0004
	.dc.w	$0004,$0038,$0004,$0014,$0144,$04C2,$0490,$001A
	.dc.w	$001C,$005E,$0156,$004A,$004A,$004A,$004A,$004C
	.dc.w	$0060,$0064,$0056,$005C,$0016,$003E,$003C,$003C
	.dc.w	$003E,$004C,$004E,$004A,$004A,$04FC,$0012,$0012
	.dc.w	$01AC,$0024,$0010
;シンボルテーブル
	.dc.w	$0201
	.dc.l	install_sasi_iocs
	.dc.b	'sainit',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_4F_B_EJECT
	.dc.b	'b_eject',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_F5_SCSIDRV
	.dc.b	'SCSI',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_00_S_RESET
	.dc.b	'S_RESET',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_01_S_SELECT
	.dc.b	'S_SELECT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_02_S_SELECTA
	.dc.b	'S_SELECTA',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_03_S_CMDOUT
	.dc.b	'S_CMDOUT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_04_S_DATAIN
	.dc.b	'S_DATAIN',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_05_S_DATAOUT
	.dc.b	'S_DATAOUT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_06_S_STSIN
	.dc.b	'S_STSIN',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_07_S_MSGIN
	.dc.b	'S_MSGIN',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_08_S_MSGOUT
	.dc.b	'S_MSGOUT',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_09_S_PHASE
	.dc.b	'S_PHASE',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_0A_S_LEVEL
	.dc.b	'S_LEVEL',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_0B_S_DATAINI
	.dc.b	'S_DATAINI',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_0C_S_DATAOUTI
	.dc.b	'S_DATAOUTI',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_24_S_TESTUNIT
	.dc.b	'testunit',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2B_S_REZEROUNIT
	.dc.b	'rezerounit',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2E_S_READI
	.dc.b	'readi',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_25_S_READCAP
	.dc.b	'readcap',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_20_S_INQUIRY
	.dc.b	'inquiry',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2C_S_REQUEST
	.dc.b	'request',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_21_S_READ
	.dc.b	'read',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_22_S_WRITE
	.dc.b	'write',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_23_S_FORMAT
	.dc.b	'format',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2F_S_STARTSTOP
	.dc.b	'startstop',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_30_S_SEJECT
	.dc.b	'seject',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2D_S_SEEK
	.dc.b	'seek',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_36_S_DSKINI
	.dc.b	'dskini',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_37_S_FORMATB
	.dc.b	'formatb',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_38_S_BADFMT
	.dc.b	'badfmt',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_39_S_ASSIGN
	.dc.b	'assign',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_29_S_MODESENSE
	.dc.b	'modesense',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_2A_S_MODESELECT
	.dc.b	'modeselect',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_31_S_REASSIGN
	.dc.b	'reassign',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_26_S_READEXT
	.dc.b	'readext',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_27_S_WRITEEXT
	.dc.b	'writeext',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_28_S_VERIFYEXT
	.dc.b	'verifyext',$00
	.even
	.dc.w	$0201
	.dc.l	scsi_32_S_PAMEDIUM
	.dc.b	'pamedium',$00
	.even
	.dc.w	$0201
	.dc.l	jump_00_0F
	.dc.b	'cmdtbl1',$00
	.even
	.dc.w	$0201
	.dc.l	jump_20_3F
	.dc.b	'cmdtbl2',$00
	.even
	.dc.w	$0201
	.dc.l	jump_40_4F
	.dc.b	'cmdtbl3',$00
	.even
	.dc.w	$0201
	.dc.l	select_and_cmdout
	.dc.b	'command',$00
	.even
	.dc.w	$0201
	.dc.l	stsin_and_msgin
	.dc.b	'ms_get',$00
	.even
	.dc.w	$0201
	.dc.l	spc_interrupt_routine
	.dc.b	'scsi_int',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu
	.dc.b	'man_out',$00
	.even
	.dc.w	$0201
	.dc.l	dataouti_transfer
	.dc.b	'prg_out',$00
	.even
	.dc.w	$0201
	.dc.l	dataini_transfer
	.dc.b	'prg_in',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu
	.dc.b	'man_in',$00
	.even
	.dc.w	$0201
	.dc.l	dataini_wait
	.dc.b	'wt_pin',$00
	.even
	.dc.w	$0201
	.dc.l	dataini_loop
	.dc.b	'st_pin',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_loop
	.dc.b	'st_mout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_wait_1
	.dc.b	'aa_mout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_wait_2
	.dc.b	'na_mout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_cpu_end
	.dc.b	'ed_mout',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu_loop
	.dc.b	'st_min',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu_wait_1
	.dc.b	'aa_min',$00
	.even
	.dc.w	$0201
	.dc.l	datain_cpu_wait_2
	.dc.b	'na_min',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_wait
	.dc.b	'dout_loop',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_transfer
	.dc.b	'dma_out',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer
	.dc.b	'dma_in',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_transfer_end
	.dc.b	'er_dout',$00
	.even
	.dc.w	$0201
	.dc.l	dataout_transfer_no_error
	.dc.b	'ed_dout',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer_end
	.dc.b	'er_din',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer_wait
	.dc.b	'ew_din',$00
	.even
	.dc.w	$0201
	.dc.l	datain_transfer_no_error
	.dc.b	'ed_din',$00
	.even
	.dc.w	$0203
	.dc.l	scsi_bios_end
	.dc.b	'allend',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_40_B_SEEK
	.dc.b	'b_seek',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_41_B_VERIFY
	.dc.b	'b_verify',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_43_B_DSKINI
	.dc.b	'b_dskini',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_44_B_DRVSNS
	.dc.b	'b_drvsns',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_45_B_WRITE
	.dc.b	'b_write',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_46_B_READ
	.dc.b	'b_read',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_47_B_RECALI
	.dc.b	'b_recali',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_48_B_ASSIGN
	.dc.b	'b_assign',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_4B_B_BADFMT
	.dc.b	'b_badfmt',$00
	.even
	.dc.w	$0201
	.dc.l	iocs_4D_B_FORMAT
	.dc.b	'b_format',$00
	.even
;空き
    .if SCSIEXROM
	.dcb.b	$2000-$1F18,$FF
    .else
	.dcb.b	$2000-$1EF8,$FF
    .endif
  .elif SCSI_BIOS_LEVEL==3
;空き
    .if SCSIEXROM
	.dcb.b	$2000-$1B1E,$FF
    .else
	.dcb.b	$2000-$1AFE,$FF
    .endif
  .endif



	.end

;========================================================================================
;  rom16pat.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;
;	rom16pat.x
;		IPLROM 1.3からIPLROM 1.6を作るためのパッチデータ
;
;	最終更新
;		2025-03-23
;
;	作り方
;		has060 -i include -o rom16pat.o -w rom16pat.s
;		lk -b fea000 -o rom16pat.x rom16pat.o
;
;	SASI IOCS
;		IPLROM 1.2のSASI IOCSの範囲は$00FF95B6～$00FF9E7D(2248バイト)
;		IPLROM 1.3のSCSI IOCSの範囲は$00FFCCB8～$00FFDCE3(4140バイト)
;		IPLROM 1.3のSCSI IOCSの場所にIPLROM 1.2のSASI IOCSをコピーしてからこのパッチを適用する
;
;	6x12フォント
;		IPLROM 1.2の6x12 ANKフォントの範囲は$00FFD45E～$00FFE045(3048バイト)
;		IPLROM 1.6の6x12 ANKフォントの範囲は$00FEF400～$00FEFFFF(3072バイト)
;		コピーして、末尾の24バイトを$00で充填する
;
;	SHARPロゴ
;		X68000ロゴを大きくできるようにSHARPロゴを
;		$00FF138C～$00FF144F(196バイト)から
;		$00FFD680～$00FFD743(196バイト)へ移動させる
;		$00FFD580～$00FFD67F(256バイト)はSASI IOCSのパッチ用に空けておく
;
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	dmac.equ
	.include	dosconst.equ
	.include	hdc.equ
	.include	iocscall.mac
	.include	key.equ
	.include	mfp.equ
	.include	misc.mac
	.include	ppi.equ
	.include	push2.mac
	.include	rtc.equ
	.include	scsicall.mac
	.include	spc.equ
	.include	sprc.equ
	.include	sram.equ
	.include	sysport.equ
	.include	vector.equ
	.include	vicon.equ

	.include	patch.mac



VERSION_NUMBER	equ	$16_250323	;バージョンと日付
VERSION_STRING	reg	'1.6 (2025-03-23)'
CRTMOD_VERSION	equ	$16_250323	;_CRTMODのバージョン

TEXT_START	equ	$00FEA000	;テキストセクションの先頭
TEXT_END	equ	$00FEF3FF	;テキストセクションの末尾

REMOVE_CRTMOD_G_CLR_ON	equ	0	;1=_CRTMODと_G_CLR_ONを外す
USE_PROPORTIONAL_IOCS	equ	0	;1=IOCSでプロポーショナルフォントを使う



;----------------------------------------------------------------
;
;	パッチデータの先頭
;
;----------------------------------------------------------------

	PATCH_START	TEXT_START,TEXT_END

	.cpu	68000



;----------------------------------------------------------------
;	_ROMVER
;		00FF0030 203C13921127           move.l	#$13921127,d0
;		00FF0036
;----------------------------------------------------------------
	PATCH_DATA	iocs_romver,$00FF0030,$00FF0035,$203C1392
	move.l	#VERSION_NUMBER,d0
	PATCH_TEXT
	.dc.b	'XEiJ IPLROM ',VERSION_STRING,13,10
	.dc.b	'CAUTION: Distribution is prohibited.',13,10
	.dc.b	26,0

;----------------------------------------------------------------
;メッセージのスタイル
;	bit0	0=ノーマルピッチ,1=プロポーショナルピッチ
;	bit1	0=左寄せ,1=中央寄せ
;	bit2	0=隙間なし,1=隙間あり
message_style::
	.dc.b	7
	.even



;----------------------------------------------------------------
;	制御レジスタの初期化とMPU/MMU/FPUのチェック
;		サブルーチンがアドレス変換を無効にするとスタックエリアが移動して戻ってこれなくなるのでjsrではなくjmpを使う
;		00FF005A 61000CE2               bsr.w	$00FF0D3E		;MPU,MMU,FPU/FPCPチェック
;		00FF005E 2E00                   move.l	d0,d7
;		00FF0060 4A07                   tst.b	d7
;		00FF0062 6710                   beq.s	$00FF0074		;68000
;		00FF0064 7000                   moveq.l	#$00,d0
;		00FF0066 4E7B0801               movec.l	d0,vbr
;		00FF006A 0C070001               cmpi.b	#$01,d7
;		00FF006E 6704                   beq.s	$00FF0074		;68010
;		00FF0070 4E7B0002               movec.l	d0,cacr			;キャッシュOFF
;		00FF0074
;----------------------------------------------------------------
	PATCH_DATA	mpu_check,$00FF005A,$00FF0073,$61000CE2
	jmp	mpu_check
	PATCH_TEXT
;----------------------------------------------------------------
;MPUチェック
;	起動直後に割り込み禁止、スタック未使用の状態でジャンプしてくる
;	IPLROM 1.3のTRAP#10はホットスタートするときMMUのアドレス変換の状態を確認せずに$00FF0038にジャンプしている
;	060turbo.sysがTRAP#10をフックしているのでホットスタートした場合もアドレス変換は既に無効化されているはずだが、
;	念のためアドレス変換が有効になっていた場合を考慮する
;	ROMのコードは変化しないので問題ないが、
;	ベクタテーブルとスタックエリアとワークエリアの内容はアドレス変換を無効にした瞬間に失われる
;	ホットスタートしたらスタックエリアやワークエリアを使う前にアドレス変換を無効にしなければならない
;<d5.l:0=コールドスタート(d0d1!='HotStart'),-1=ホットスタート(d0d1=='HotStart')
;<d6.l:エミュレータ割り込みベクタ([OFFSET_EMULATOR_INTERRUPT.w].l)&$00FFFFFF。コールドスタートのとき未定義例外処理ルーチンを指していなければ電源ON、指していればリセット
;>d7.l:MPUの種類とFPU/FPCPの有無とMMUの有無
;	bit31	MMUの有無。0=なし,1=あり
;	bit15	FPU/FPCPの有無。0=なし,1=あり
;	bit7-0	MPUの種類。0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
;?d0/a1
mpu_check:
	movea.l	sp,a1

;----------------------------------------------------------------
;MOVEC to VBR(-12346)がなければMC68000
;	MC68000かどうかのテストとVBRのクリアを同時に行う
;	不当命令例外ベクタが$0010.wにあるのはMC68000の場合とMC68010以上でVBRが0の場合
;	MC68010以上でVBRが0でないとき$0010.wを書き換えても不当命令例外を捉えられないので、
;	MC68010以上のときは最初にVBRをクリアする必要がある
;	VBRをクリアする命令はMC68000で不当命令なのでMC68000かどうかのテストを兼ねる
	lea.l	dummy_trap(pc),a0
	move.l	a0,OFFSET_ILLEGAL_INSTRUCTION.w	;例外ベクタ$04 不当命令
	lea.l	mpu_check_done(pc),a0
	moveq.l	#0,d7			;MC68000
	moveq.l	#0,d0
	.cpu	68010
	movec.l	d0,vbr
	.cpu	68000
	lea.l	dummy_trap(pc),a0
	move.l	a0,OFFSET_ILLEGAL_INSTRUCTION.w	;例外ベクタ$04 不当命令
	move.l	a0,OFFSET_LINE_1111_EMULATOR.w	;例外ベクタ$0B ライン1111エミュレータ

;----------------------------------------------------------------
;MOVEC to VBR(-12346)があってスケールファクタ(--2346)がなければMC68010
	moveq.l	#1,d7			;MC68010
@@:	moveq.l	#1,d0			;$70,$01
	.cpu	68020
	and.b	(@b-1,pc,d0.w*2),d0	;スケールファクタなし(([@b-1+1].b==$70)&1)==0,スケールファクタあり(([@b-1+1*2].b=$01)&1)==1
	.cpu	68000
	beq	mpu_check_done

;----------------------------------------------------------------
;CALLM(--2---)があればMC68020
	.cpu	68020
	lea.l	9f(pc),a0
	callm	#0,1f(pc)
	moveq.l	#2,d7			;MC68020
;		  3  2 1 0
;		  C CE F E
	move.l	#%1__0_0_0,d0
	movec.l	d0,cacr			;命令キャッシュクリア、命令キャッシュOFF
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPUあり
@@:
;MC68851のチェックは省略
	bra	mpu_check_done

;モジュールデスクリプタ
1:	.dc.l	%0<<13|0<<24|0<<16	;option=0,type=0,accesslevel=0
	.dc.l	2f			;モジュールエントリポインタ
	.dc.l	0			;モジュールデータ領域ポインタ
	.dc.l	0
;モジュールエントリ
2:	.dc.w	15<<12			;Rn=sp
	rtm	sp

9:	movea.l	a1,sp
	.cpu	68000

;----------------------------------------------------------------
;CALLM(--2---)がなくてMOVEC from CAAR(--23--)があればMC68030
	.cpu	68030
	lea.l	9f(pc),a0
	movec.l	caar,d0
	moveq.l	#3,d7			;MC68030
;		   D   C  B   A  9  8 765   4  3   2  1  0
;		  WA DBE CD CED FD ED     IBE CI CEI FI EI
	move.l	#%_0___0__1___0__0__0_000___0__1___0__0__0,d0
	movec.l	d0,cacr			;データキャッシュクリア、データキャッシュOFF、命令キャッシュクリア、命令キャッシュOFF
;		  F ECDBA   9   8 7654 3210 FEDC BA98 7654 3210
;		  E       SRE FCL   PS   IS  TIA  TIB  TIC  TID
	move.l	#%0_00000___0___0_1101_1000_0011_0100_0100_0000,-(sp)
	pmove.l	(sp),tc			;アドレス変換OFF
;		  FEDCBA98 76543210 F EDCB  A   9   8 7    654 3    210
;		      BASE     MASK E      CI R/W RWM   FCBASE   FCMASK
	move.l	#%00000000_00000000_0_0000__0___0___0_0____000_0____000,(sp)
	pmove.l	(sp),tt0		;透過変換OFF
	pmove.l	(sp),tt1
	addq.l	#4,sp
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPUあり
@@:	bsr	mmu_check_3		;MMUチェック(MC68030)
	bra	mpu_check_done

9:
	.cpu	68000

;----------------------------------------------------------------
;MOVEC from MMUSR(----4-)があればMC68040
	.cpu	68040
	lea.l	9f(pc),a0
	movec.l	mmusr,d0
	moveq.l	#4,d7			;MC68040
;		   F EDCBA9876543210  F EDCBA9876543210
;		  DE 000000000000000 IE 000000000000000
	move.l	#%_0_000000000000000__0_000000000000000,d0
	movec.l	d0,cacr			;データキャッシュOFF、命令キャッシュOFF
	cinva	bc			;データキャッシュクリア、命令キャッシュクリア
;		  F E DCBA9876543210
;		  E P 00000000000000
	move.l	#%0_0_00000000000000,d0
	movec.l	d0,tc			;アドレス変換無効
	pflusha				;アドレス変換キャッシュクリア
;		  FEDCBA98 76543210 F     ED CBA  9  8 7 65 43 2 10
;		      BASE     MASK E SFIELD     U1 U0   CM    W
	move.l	#%00000000_00000000_0_____00_000__0__0_0_00_00_0_00,d0
	movec.l	d0,itt0			;透過変換OFF
	movec.l	d0,itt1
	movec.l	d0,dtt0
	movec.l	d0,dtt1
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPUあり
@@:	bsr	mmu_check_46		;MMUチェック(MC68040/MC68060)
	bra	mpu_check_done

9:
	.cpu	68000

;----------------------------------------------------------------
;MOVEC from PCR(-----6)があればMC68060
	.cpu	68060
	lea.l	9f(pc),a0
	movec.l	pcr,d1
	moveq.l	#6,d7			;MC68060
;		    F   E   D   C   B A98   7    6    5 43210   F   E   D CBA9876543210
;		  EDC NAD ESB DPI FOC     EBC CABC CUBC       EIC NAI FIC
	move.l	#%__0___0___0___0___0_000___1____0____0_00000___0___0___0_0000000000000,d0
	movec.l	d0,cacr			;データキャッシュOFF、ストアバッファOFF、分岐キャッシュON、命令キャッシュOFF
;	リセットでキャッシュはクリアされない
;	リセットされたらキャッシュを有効にする前にキャッシュをクリアしなければならない(MC68060UM 5.3)
	cinva	bc			;データキャッシュクリア、命令キャッシュクリア
;		  F E   D   C    B    A  98  76   5  43  21 0
;		  E P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
	move.l	#%0_0___0___0____0____0__10__00___0__10__00_0,d0
	movec.l	d0,tc			;アドレス変換OFF、データキャッシュOFFプリサイスモード、命令キャッシュOFFプリサイスモード
;	リセットでアドレス変換キャッシュはクリアされない
;	リセットされたらアドレス変換を有効にする前にアドレス変換キャッシュをクリアしなければならない(MC68060UM 4.6.1)
	pflusha				;アドレス変換キャッシュクリア
;		  FEDCBA98 76543210 F     ED CBA  9  8 7 65 43 2 10
;		      BASE     MASK E SFIELD     U1 U0   CM    W
	move.l	#%00000000_00000000_0_____00_000__0__0_0_00_00_0_00,d0
	movec.l	d0,itt0			;透過変換OFF
	movec.l	d0,itt1
	movec.l	d0,dtt0
	movec.l	d0,dtt1
;		  FEDCBA9876543210 FEDCBA98      7 65432   1   0
;		  0000010000110000 REVISION EDEBUG       DFP ESS
	move.l	#%0000000000000000_00000000______0_00000___0___1,d0
	movec.l	d0,pcr			;FPU ON,スーパースカラON
	lea.l	@f(pc),a0
	fnop
	bset.l	#15,d7			;FPUあり
@@:	bsr	mmu_check_46		;MMUチェック(MC68040/MC68060)
	bra	mpu_check_done

9:
	.cpu	68000

;----------------------------------------------------------------
;不明
	moveq.l	#0,d7

;----------------------------------------------------------------
;終了
mpu_check_done:
	jmp	$00FF0074

;----------------------------------------------------------------
;ダミーの例外処理
;	a1をspにコピーしてa0にジャンプする
dummy_trap:
	movea.l	a1,sp
	jmp	(a0)

;----------------------------------------------------------------
;MMUチェック(MC68030)
mmu_check_3:
	.cpu	68030
	lea.l	-128(sp),sp
	movea.l	sp,a0
;		L/U           LIMIT                DT
	move.l	#%0_111111111111111_00000000000000_10,(a0)+
	move.l	sp,d0
	lsr.l	#4,d0
	addq.l	#2,d0
	lsl.l	#4,d0
	move.l	d0,(a0)
;			     CI   M U WP DT
	lea.l	$00000000|%0__0_0_0_0__0_01.w,a0
	movea.l	d0,a1
	moveq.l	#8-1,d0
	for	d0
		move.l	a0,(a1)+
		adda.l	#$00200000,a0
	next
;アドレス変換を有効にする
;			      CI   M U WP DT
	move.l	#$00F00000|%0__0_0_0_0__0_01,-4*8+4(a1)	;$00200000を$00F00000に変換する
	pmove.q	(sp),crp
;		  E       SRE FCL   PS   IS  TIA  TIB  TIC  TID
	move.l	#%1_00000___0___0_1101_1000_0011_0100_0100_0000,-(sp)
	pflusha
	pmove.l	(sp),tc
;8KB比較する
	lea.l	$00F00000,a1
	lea.l	$00200000,a0
	move.w	#2048-1,d0
@@:	cmpm.l	(a1)+,(a0)+
	dbne	d0,@b
	bne	@f
	bset.l	#31,d7			;MMUあり
@@:
;アドレス変換を解除する
	bclr.b	#7,(sp)			;E=0
	pmove.l	(sp),tc			;アドレス変換無効
	pflusha
	lea.l	4+128(sp),sp
	.cpu	68000
	rts

;----------------------------------------------------------------
;MMUチェック(MC68040/MC68060)
mmu_check_46:
	.cpu	68040
	lea.l	$2000.w,a1
;ルートテーブルを作る
;			   U W UDT
	lea.l	512|%00000_0_0__10(a1),a0
	moveq.l	#128-1,d0
	for	d0
		move.l	a0,(a1)+
	next
;ポインタテーブルを作る
;			   U W UDT
	lea.l	512|%00000_0_0__10(a1),a0
	moveq.l	#128-1,d0
	for	d0
		move.l	a0,(a1)+
	next
;ページテーブルを作る
	moveq.l	#32-1,d0
	for	d0
	;			    UR G U1 U0 S CM M U W PDT
		move.l	#$00FF0000|%00_1__0__0_0_10_0_0_0__01,(a1)+
	next
;$80000000～$FFFFFFFFを透過変換にする
;		      BASE     MASK E SFIELD     U1 U0   CM    W
	movea.l	#%00000000_01111111_1_____10_000__0__0_0_10_00_0_00,a1
	movec.l	a1,itt0
	movec.l	a1,dtt0
	movec.l	a1,itt1
	movec.l	a1,dtt1
;アドレス変換を有効にする
	lea.l	$2000.w,a1
	movec.l	a1,srp			;MMUがなくてもエラーにならない(MC68060UM B.2)
	movec.l	a1,urp
;		  E P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
	movea.l	#%1_1___0___0____0____0__00__00___0__00__00_0,a1
	pflusha
	cinva	bc
	movec.l	a1,tc
;8KB比較する
	lea.l	$80FF0000,a0
	lea.l	$80F00000,a1
	move.w	#2048-1,d0
@@:	cmpm.l	(a0)+,(a1)+
	dbne	d0,@b
	bne	@f
	bset.l	#31,d7			;MMUあり
@@:
;アドレス変換とトランスペアレント変換を解除する
	if	<cmp.b #6,d7>,lo	;68040
;			  E P
		movea.l	#%0_0___0___0____0____0__00__00___0__00__00_0,a1
	else				;68060
;			  E P NAD NAI FOTC FITC DCO DUO DWO DCI DUI
		movea.l	#%0_0___0___0____0____0__10__00___0__00__00_0,a1
	endif
	movec.l	a1,tc
	pflusha
	cinva	bc
	suba.l	a1,a1
	movec.l	a1,itt0
	movec.l	a1,dtt0
	movec.l	a1,itt1
	movec.l	a1,dtt1
	.cpu	68000
	rts



;----------------------------------------------------------------
;	未定義例外ベクタと未定義IOCSコールベクタのハイメモリ対策
;		68060のとき
;			未定義例外ベクタと未定義IOCSコールベクタのbit28が1のときベクタ番号を消す
;				$01xxxxxxにハイメモリがあるとき未定義ベクタを踏んでも暴走しないようにする
;				060turboのROMに合わせてハイメモリの有無に関係なく68060のときだけ行う
;				TRAP#n($002x)、MFP($004x)、IOI/DMA/SPC($006x)などはベクタ番号を消さない
;				SCC($005x)、_OPMDRV($01F0)などはベクタ番号を消す
;			未実装整数命令例外ベクタを設定する
;		スプリアス割り込みベクタを設定する
;	変更前
;		00FF008E 41FAFF70_00000000	lea.l	$00FF0000(pc),a0
;		00FF0092 2408             	move.l	a0,d2
;		00FF0094
;----------------------------------------------------------------
	PATCH_DATA	p008E,$00FF008E,$00FF0093,$41FAFF70
	jsr	p008E
	PATCH_TEXT
;<d7.l:MPUの種類とFPU/FPCPの有無とMMUの有無
;	bit31	MMUの有無。0=なし,1=あり
;	bit15	FPU/FPCPの有無。0=なし,1=あり
;	bit7-0	MPUの種類。0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
;>d6.l:$00FF0000
;?a0-a1
p008E:
	if	<cmpi.b #6,d7>,eq	;68060のとき
	;未定義例外ベクタと未定義IOCSコールベクタのbit28が1のときベクタ番号を消す
	;NMIベクタだけ未定義ではないが問題ない
		suba.l	a0,a0			;例外ベクタテーブルの先頭から
		do
			if	<btst.b #4,(a0)>,ne	;bit28が1のとき
				clr.b	(a0)			;ベクタ番号を消す
			endif
			addq.l	#4,a0
		while	<cmpa.w	#$0800,a0>,lo	;IOCSコールベクタテーブルの末尾まで
	;未実装整数命令例外処理ベクタを設定する
		lea.l	uii(pc),a1		;未実装整数命令例外処理ルーチン
		move.l	a1,OFFSET_INTEGER_INSTRUCTION.w	;例外ベクタ$3D 未実装整数命令
	endif
;スプリアス割り込みベクタを設定する
	lea.l	uii_rte(pc),a1		;未実装整数命令例外処理ルーチンのrte
	move.l	a1,OFFSET_SPURIOUS_INTERRUPT.w	;例外ベクタ$18 スプリアス割り込み
;IOCSコールベクタの設定に戻る
	move.l	#$00FF0000,d2
	rts

;----------------------------------------------------------------
;未実装整数命令例外処理ルーチン
	.cpu	68060
uii:
	pea.l	(8,sp)			;例外発生時のssp
	movem.l	d0-d7/a0-a6,-(sp)
	moveq.l	#5,d2			;スーパーバイザデータアクセスのファンクションコード
	btst.b	#5,(4*16,sp)		;例外発生時のsrのS
	bne	1f			;スーパーバイザモード
;ユーザモード
	moveq.l	#1,d2			;ユーザデータアクセスのファンクションコード
	move.l	usp,a0			;例外発生時のusp
	move.l	a0,(4*15,sp)		;例外発生時のsp
;命令コードを読み取る
1:	movea.l	(4*16+2,sp),a0		;a0=例外発生時のpc
	move.w	(a0)+,d1		;d1=命令コード,a1=pc+2
;MOVEPかどうか調べる
	move.w	d1,d0
;		  0000qqq1ws001rrr
	and.w	#%1111000100111000,d0
	cmp.w	#%0000000100001000,d0
	beq	2f			;MOVEP
;MOVEP以外
	movem.l	(sp),d0-d2		;d0/d1/d2を復元
	movea.l	(4*8,sp),a0		;a0を復元
	lea.l	(4*16,sp),sp		;破壊されていないレジスタの復元を省略する
	jmp	$00FF0770		;未定義例外処理

;MOVEP
;実効アドレスを求める
2:	moveq.l	#7,d0			;d0=0000000000000111
	and.w	d1,d0			;d0=0000000000000rrr
	movea.l	(4*8,sp,d0.w*4),a1	;a1=Ar
	adda.w	(a0)+,a1		;a0=pc+4,a1=d16+Ar=実効アドレス
;復帰アドレスを更新する
	move.l	a0,(4*16+2,sp)		;pc=pc+4
;Dqのアドレスを求める
	move.w	d1,d0			;d0=0000qqq1ws001rrr
	lsr.w	#8,d0			;d0=000000000000qqq1
	lea.l	(-2,sp,d0.w*2),a0	;d0*2=00000000000qqq10,a0=Dqのアドレス
;リード/ライト,ワード/ロングで分岐する
	add.b	d1,d1			;c=w,d1=s001rrr0
	bcs	5f			;ライト
;リード
	movec.l	sfc,d1			;ファンクションコードを保存
	movec.l	d2,sfc			;ファンクションコードを変更
	bmi	3f			;リードロング
;リードワード
;MOVEP.W (d16,Ar),Dq
	moves.b	(a1),d0			;メモリから上位バイトをリード
	lsl.w	#8,d0
	moves.b	(2,a1),d0		;メモリから下位バイトをリード
	move.w	d0,(2,a0)		;データレジスタの下位ワードへライト
	bra	4f

;リードロング
;MOVEP.L (d16,Ar),Dq
3:	moves.b	(a1),d0			;メモリから上位ワードの上位バイトをリード
	lsl.l	#8,d0
	moves.b	(2,a1),d0		;メモリから上位ワードの下位バイトをリード
	lsl.l	#8,d0
	moves.b	(4,a1),d0		;メモリから下位ワードの上位バイトをリード
	lsl.l	#8,d0
	moves.b	(6,a1),d0		;メモリから下位ワードの下位バイトをリード
	move.l	d0,(a0)			;データレジスタへライト
4:	movec.l	d1,sfc			;ファンクションコードを復元
	movem.l	(sp),d0-d7		;データレジスタのどれか1個が更新されている
	bra	8f

;ライト
5:	movec.l	dfc,d1			;ファンクションコードを保存
	movec.l	d2,dfc			;ファンクションコードを変更
	bmi	6f			;ライトロング
;ライドワード
;MOVEP.W Dq,(d16,Ar)
	move.w	(2,a0),d0		;データレジスタの下位ワードからリード
	rol.w	#8,d0
	moves.b	d0,(a1)			;メモリへ上位バイトをライト
	rol.w	#8,d0
	moves.b	d0,(2,a1)		;メモリへ下位バイトをライト
	bra	7f

;ライトロング
;MOVEP.L Dq,(d16,Ar)
6:	move.l	(a0),d0			;データレジスタからリード
	rol.l	#8,d0
	moves.b	d0,(a1)			;メモリへ上位ワードの上位バイトをライト
	rol.l	#8,d0
	moves.b	d0,(2,a1)		;メモリへ上位ワードの下位バイトをライト
	rol.l	#8,d0
	moves.b	d0,(4,a1)		;メモリへ下位ワードの上位バイトをライト
	rol.l	#8,d0
	moves.b	d0,(6,a1)		;メモリへ下位ワードの下位バイトをライト
7:	movec.l	d1,dfc			;ファンクションコードを復元
	movem.l	(sp),d0-d2		;d0/d1/d2を復元
8:	movem.l	(4*8,sp),a0-a1		;a0/a1を復元
	lea.l	(4*16,sp),sp		;破壊されていないレジスタの復元を省略する
	tst.b	(sp)			;例外発生時のsrのT
	bpl	9f			;トレースなし
;トレースあり
	ori.w	#$8000,sr		;RTEの前にsrのTをセットしてMOVEPをトレースしたように振る舞う
9:
;未実装整数命令例外処理ルーチンのrte
uii_rte:
	rte

	.cpu	68000



;----------------------------------------------------------------
;	IOCS $F5ベクタの設定
;		000000C4 2039(01)0000934E 	move.l	device_installer_parameter,d0	;ROM起動ルーチン-12 SCSIデバイスドライバ組み込みルーチンのパラメータ
;		000000CA 21C007D4         	move.l	d0,4*($100+_SCSIDRV).w	;IOCSコール$F5 _SCSIDRV
;		削除。SCSI内蔵機のときもscsi_init_routineで設定するのでここは削除
;----------------------------------------------------------------
	PATCH_DATA	p00C4,$00FF00C4,$00FF00C4+9,$203900FF
	bra.s	(*)-$00C4+$00CE



;----------------------------------------------------------------
;	SRAMの初期化
;		SRAMを初期化するときメインメモリのサイズを搭載しているサイズに合わせる
;		SASI内蔵機のとき、ROM起動ハンドルを$00E80400に、ハードディスクの台数を1にする
;		SCSI内蔵機のとき、ROM起動ハンドルを$00FC0000に、ハードディスクの台数を0にする
;			ROM起動ハンドルを標準の$00BFFFFCにするとメインメモリを12MBに増設したとき正常に動作しなくなる
;			$00E80400はすべての機種でバスエラーになるはず
;		メモリサイズの判別とSASI内蔵機とSCSI内蔵機の判別もここで行う
;	変更前
;		000000CE 41F900ED0000     	lea.l	SRAM_MAGIC,a0
;			:
;		0000010C*423900E8E00D     	locksram			;SRAM書き込み禁止
;----------------------------------------------------------------
	PATCH_DATA	p00ce,$00FF00CE,$00FF0111,$41F900ED
	jsr	p00ce
	bra.s	(*)-$00D4+$0112
	PATCH_TEXT
p00ce:
	bsr	check_memory_size
	bsr	check_hard_disk_interface
	bsr	check_sram
	rts

;メインメモリのサイズを確認する
check_memory_size:
	push	d2-d3/a2/a5
	suba.l	a2,a2
	move.l	#$55AAAA55,d3		;テストデータ
	di				;sr保存、割り込み禁止
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;バスエラーベクタ保存
	movea.l	sp,a5			;sp保存
	move.l	#@f,OFFSET_BUS_ERROR.w	;バスエラーでループを終了する
	do
		move.l	(a2),d2			;保存
		nop
		move.l	d3,(a2)			;テストデータ書き込み
		nop
		cmp.l	(a2),d3			;テストデータ読み出し、比較
		nop
		break	ne
		nop
		move.l	d2,(a2)			;復元
		nop
		adda.l	#$00100000,a2		;次の1MB
	while	<cmpa.l #$00C00000,a2>,lo	;最大12MB
@@:	movea.l	a5,sp			;sp復元
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;バスエラーベクタ復元
	ei				;sr復元
	move.l	a2,BIOS_MEMORY_SIZE.w	;起動時に確認したメインメモリのサイズ
	pop
	rts

;SASI内蔵機とSCSI内蔵機を判別する
check_hard_disk_interface:
	isSASI
	sne.b	BIOS_BUILTIN_SCSI.w	;0=SASI内蔵機,-1=SCSI内蔵機
	rts

check_sram:
	push	d0/a0-a3
	lea.l	SRAM_MAGIC,a2		;SRAMマジック
	lea.l	$00FF09E8,a3		;SRAM初期データ
	movea.l	a2,a0
	movea.l	a3,a1
	ifor	<cmpm.l (a0)+,(a1)+>,ne,<cmpm.l (a0)+,(a1)+>,ne	;SRAMは壊れている
	;SRAM書き込み許可
		unlocksram
	;SRAMの先頭256バイトをクリア
		movea.l	a2,a0
		moveq.l	#256/4-1,d0
		for	d0
			clr.l	(a0)+
		next
	;SRAM初期データを書き込む
		movea.l	a2,a0
		movea.l	a3,a1
		moveq.l	#$00FF0A43-$00FF09E8-1,d0	;SRAM初期データの長さ-1
		for	d0
			move.b	(a1)+,(a0)+
		next
	;メモリサイズを修正する
		move.l	BIOS_MEMORY_SIZE.w,SRAM_MEMORY_SIZE-SRAM_MAGIC(a2)
	;ROM起動ハンドルとハードディスクの台数を修正する
		if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI内蔵機
			move.l	#$00E80400,SRAM_ROM_BOOT_HANDLE-SRAM_MAGIC(a2)
			move.b	#1,SRAM_HDMAX-SRAM_MAGIC(a2)
		else				;SCSI内蔵機
			move.l	#$00FC0000,SRAM_ROM_BOOT_HANDLE-SRAM_MAGIC(a2)
			clr.b	SRAM_HDMAX-SRAM_MAGIC(a2)
		endif
	;SRAM常駐プログラムを無効にする
		clr.w	SRAM_PROGRAM_START-SRAM_MAGIC(a2)
	;SRAM書き込み禁止
		locksram
	endif
	pop
	rts



;----------------------------------------------------------------
;	整合を確認する
;		SCSIINROMの整合を確認する
;		判別されたメモリサイズとSRAMの設定値が合っていないときSRAMの設定値を修正するか問い合わせる
;		CLRキーが押されていたらSRAM初期化の位置に押し込む
;	変更前
;		00FF01D4 083800070807     	btst.b	#7,BIOS_BITSNS+7.w	;CLR|↓|→|↑|←|UNDO|ROLL DOWN|ROLL UP
;----------------------------------------------------------------
	PATCH_DATA	p01d4,$00FF01D4,$00FF01D4+5,$08380007
	jsr	p01d4
	PATCH_TEXT
p01d4:
	if	<btst.b #KEY_TENCLR&7,BIOS_BITSNS+(KEY_TENCLR>>3).w>,eq	;CLRキーが押されていない。押されているときneで復帰するためtst.bではなくbtst.bを使う
		bsr	check_memory_size
		bsr	check_hard_disk_interface
		bsr	test_scsiinrom
		bsr	confirm_memory_size
		moveq.l	#0,d0			;eqで復帰する
	endif
	rts

;SCSIINROMの整合を確認する
;	SASI内蔵機のときSCSIINROMがあればエラーを報告して停止する
;	SCSI内蔵機のときSCSIINROM 16がなければエラーを報告して停止する
test_scsiinrom:
	push	d0-d1/a0
	lea.l	$00FC0024,a0		;'SCSIIN'
	clr.w	d1			;0=SCSIINROMがない
	bsr	read_long
	if	<cmp.l #'SCSI',d0>,eq
		bsr	read_word
		if	<cmp.w #'IN',d0>,eq
			addq.w	#1,d1		;1=SCSIINROMがある
			bsr	read_word
			if	<cmp.w #16,d0>,eq
				addq.w	#1,d1		;2=SCSIINROM 16がある
			endif
		endif
	endif
;<d1.w:0=SCSIINROMがない,1=SCSIINROMがある,2=SCSIINROM 16がある
	if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI内蔵機のとき
		if	<tst.w d1>,ne		;SCSIINROMがある
			lea.l	100f(pc),a1		;13,10,'  SCSIINROM is not required'
			goto	20f
		endif
	else				;SCSI内蔵機のとき
		if	<cmp.w #2,d1>,ne	;SCSIINROM 16がない
			lea.l	101f(pc),a1		;13,10,'  SCSIINROM 16 is required'
			goto	20f
		endif
	endif
	pop
	rts

20:	bsr	iocs_21_B_PRINT
	do
	while	t

100:	.dc.b	13,10,'  SCSIINROM is not required',0
101:	.dc.b	13,10,'  SCSIINROM 16 is required',0
	.even

;判別されたメモリサイズとSRAMの設定値が合っていないときSRAMの設定値を修正するか問い合わせる
confirm_memory_size:
	push	d0-d1/a0-a1
	move.l	SRAM_MEMORY_SIZE,d0	;SRAMの設定値のメモリサイズ
	if	<cmp.l BIOS_MEMORY_SIZE.w,d0>,ne	;起動時に確認したメインメモリのサイズ。合っていない
		lea.l	-128(sp),sp
		movea.l	sp,a0
		lea.l	100f(pc),a1		;13,10,'  Modify memory size setting from '
		bsr	strcpy
	;	move.l	SRAM_MEMORY_SIZE,d0	;SRAMの設定値のメモリサイズ
		moveq.l	#20,d1
		lsr.l	d1,d0
		bsr	utos
		lea.l	101f(pc),a1		;'MB to '
		bsr	strcpy
		move.l	BIOS_MEMORY_SIZE.w,d0	;起動時に確認したメインメモリのサイズ
	;	moveq.l	#20,d1
		lsr.l	d1,d0
		bsr	utos
		lea.l	102f(pc),a1		;'MB? (Y/N)'
		bsr	strcpy
		movea.l	sp,a1
		bsr	iocs_21_B_PRINT
		bsr	kflush
		do
			bsr	inkey
			bsr	toupper
		whileand	<cmp.b #'Y',d0>,ne,<cmp.b #'N',d0>,ne
		if	<cmp.b #'Y',d0>,eq
			unlocksram
				move.l	BIOS_MEMORY_SIZE.w,SRAM_MEMORY_SIZE
			locksram
		endif
		lea.l	103f(pc),a1		;26
		bsr	iocs_21_B_PRINT
		lea.l	128(sp),sp
	endif
	pop
	rts

100:	.dc.b	13,10
	.dc.b	'  Modify memory size setting from ',0
101:	.dc.b	'MB to ',0
102:	.dc.b	'MB? (y/n)',0
103:	.dc.b	26,0
	.even



;----------------------------------------------------------------
;改行をコピーする
;<a0.l:コピー先
;>a0.l:コピー先の0の位置
crlf:
	move.b	#13,(a0)+
	move.b	#10,(a0)+
	clr.b	(a0)
	rts

;----------------------------------------------------------------
;符号なし整数を16進数4桁の文字列に変換する
;<d0.w:符号なし整数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
h4tos:
	push	d1-d2
	moveq.l	#4-1,d1
	for	d1
		rol.w	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	100f(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

100:	.dc.b	'0123456789ABCDEF'
	.even

;----------------------------------------------------------------
;符号なし整数を16進数8桁の文字列に変換する
;<d0.l:符号なし整数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
h8tos:
	push	d1-d2
	moveq.l	#8-1,d1
	for	d1
		rol.l	#4,d0
		moveq.l	#15,d2
		and.w	d0,d2
		move.b	100f(pc,d2.w),(a0)+
	next
	clr.b	(a0)
	pop
	rts

100:	.dc.b	'0123456789ABCDEF'
	.even

;----------------------------------------------------------------
;文字コードが0でないキーが押されるまで待つ
;>d0.b:文字コード
inkey:
	do
		IOCS	_B_KEYINP
	while	<tst.b d0>,eq
	rts

;----------------------------------------------------------------
;キー入力バッファを空にする
kflush:
	push	d0
	IOCS	_B_KEYSNS
	while	<tst.l d0>,ne
		IOCS	_B_KEYINP
		IOCS	_B_KEYSNS
	endwhile
	pop
	rts

;----------------------------------------------------------------
;文字列をコピーする
;<a0.l:コピー先
;<a1.l:コピー元
;>a0.l:コピー先の0の位置
;>a1.l:コピー元の0の次の位置
strcpy:
	do
		move.b	(a1)+,(a0)+
	while	ne
	subq.l	#1,a0
	rts

;----------------------------------------------------------------
;大文字にする
;<d0.b:文字コード
;>d0.b:文字コード
toupper:
	ifand	<cmp.b #'a',d0>,hs,<cmp.b #'z',d0>,ls
		add.b	#'A'-'a',d0
	endif
	rts

;----------------------------------------------------------------
;符号なし整数を10進数の文字列に変換する
;<d0.l:符号なし整数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
utos:
	push	d0-d2/a1
	if	<tst.l d0>,eq
		move.b	#'0',(a0)+
	else
		lea.l	utos_table(pc),a1
		do
			move.l	(a1)+,d1
		while	<cmp.l d1,d0>,lo	;引けるところまで進む
		do
			moveq.l	#'0'-1,d2
			do
				addq.b	#1,d2
				sub.l	d1,d0
			while	hs			;引ける回数を数える
			move.b	d2,(a0)+
			add.l	d1,d0			;引きすぎた分を加え戻す
			move.l	(a1)+,d1
		while	ne
	endif
	clr.b	(a0)
	pop
	rts

utos_table:
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

;----------------------------------------------------------------
;符号なし整数を10進数の文字列に変換する(ゼロ充填)
;<d0.l:符号なし整数
;<d1.l:最小桁数
;<a0.l:バッファ
;>a0.l:バッファの0の位置
utosz:
	push	d0-d2/a1
	moveq.l	#10,d2
	sub.l	d1,d2
	if	lo
		do
			move.b	#'0',(a0)+
			addq.l	#1,d2
		while	ne			;足りない0を並べる
	endif
	lea.l	utos_table(pc),a1
	for	d2
		move.l	(a1)+,d1
	next	<cmp.l d1,d0>,lo	;最小桁数または引けるところまで進む
	do
		moveq.l	#'0'-1,d2
		do
			addq.b	#1,d2
			sub.l	d1,d0
		while	hs			;引ける回数を数える
		move.b	d2,(a0)+
		add.l	d1,d0			;引きすぎた分を加え戻す
		move.l	(a1)+,d1
	while	ne
	clr.b	(a0)
	pop
	rts



  .if 0
;----------------------------------------------------------------
;バスエラーを無視して1バイト読み出す
;<a0.l:アドレス
;>d0.b:データ。バスエラーのとき0
;>a0.l:アドレス+1
;>c:cc=バスエラーなし,cs=バスエラーあり
read_byte:
	push	d1/a1
	di				;sr保存、割り込み禁止
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;バスエラーベクタ保存
	lea.l	@f(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp保存
	moveq.l	#0,d0
;		  XNZVC
	moveq.l	#%00001,d1		;c=1
	nop
	move.b	(a0)+,d0		;1バイト読み出す
	nop
	moveq.l	#%00000,d1		;c=0
@@:	movea.l	a1,sp			;sp復元
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;バスエラーベクタ復元
	ei				;sr復元
	move.w	d1,ccr
	pop
	rts
  .endif

;----------------------------------------------------------------
;バスエラーを無視して1ワード読み出す
;<a0.l:アドレス。奇数は不可
;>d0.w:データ。バスエラーのとき0
;>a0.l:アドレス+2
;>c:cc=バスエラーなし,cs=バスエラーあり
read_word:
	push	d1/a1
	di				;sr保存、割り込み禁止
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;バスエラーベクタ保存
	lea.l	@f(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp保存
	moveq.l	#0,d0
;		  XNZVC
	moveq.l	#%00001,d1		;c=1
	nop
	move.w	(a0)+,d0		;1ワード読み出す
	nop
	moveq.l	#%00000,d1		;c=0
@@:	movea.l	a1,sp			;sp復元
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;バスエラーベクタ復元
	ei				;sr復元
	move.w	d1,ccr
	pop
	rts

;----------------------------------------------------------------
;バスエラーを無視して1ロング読み出す
;<a0.l:アドレス。奇数は不可
;>d0.l:データ。バスエラーのとき0
;>a0.l:アドレス+2
;>c:cc=バスエラーなし,cs=バスエラーあり
read_long:
	push	d1/a1
	di				;sr保存、割り込み禁止
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;バスエラーベクタ保存
	lea.l	@f(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp保存
	moveq.l	#0,d0
;		  XNZVC
	moveq.l	#%00001,d1		;c=1
	nop
	move.l	(a0)+,d0		;1ロング読み出す
	nop
	moveq.l	#%00000,d1		;c=0
@@:	movea.l	a1,sp			;sp復元
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;バスエラーベクタ復元
	ei				;sr復元
	move.w	d1,ccr
	pop
	rts



;----------------------------------------------------------------
;	起動できないSCSI-IDのフラグの保存
;		このまま
;			_B_SCSIの元のベクタを移動させることにしたので起動できないSCSI-IDのフラグは移動していない
;			SASI内蔵機のときも衝突することはないはず
;		00000112 1A380CC3         	move.b	BIOS_SCSI_UNBOOTABLE.w,d5
;		00000138 11C50CC3         	move.b	d5,BIOS_SCSI_UNBOOTABLE.w
;----------------------------------------------------------------



;----------------------------------------------------------------
;	クロック計測
;		00FF013C 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;			:
;		00FF019C
;----------------------------------------------------------------
	PATCH_DATA	clock_check,$00FF013C,$00FF019B,$0C380001
	jsr	clock_check
	bra	($00FF019C)PATCH_ZL
	PATCH_TEXT
;----------------------------------------------------------------
;クロック計測
clock_check:

;システムクロックの確認
	moveq.l	#0,d0
	move.b	SYSPORT_MODEL,d0	;機種判別。$DC=X68030,$FE=XVIで16MHz,$FF=XVI以前で10MHz
					;$00FF=10MHz,$00FE=16MHz,$00DC=25MHz
	not.b	d0			;$0000=10MHz,$0001=16MHz,$0023=25MHz
	lsl.w	#4,d0			;$0000=10MHz,$0010=16MHz,$0230=25MHz
	lsr.b	#4,d0			;$0000=10MHz,$0001=16MHz,$0203=25MHz
	move.w	d0,BIOS_CLOCK_SWITCH.w	;クロックスイッチ。$0000=10MHz,$0001=16MHz,$0203=25MHz

;クロック計測のためのキャッシュON
;	68030のときは命令キャッシュとデータキャッシュをONにする
;	68040/68060のデータキャッシュと68060のストアバッファはMMUを有効にするまでONにできないので命令キャッシュだけONにする
;	SRAMのキャッシュの設定はこれより後で反映される
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;68000/68010はキャッシュなし
		move.l	#$00002101,d0		;68020/68030は命令キャッシュON(bit0)、68030はデータキャッシュON(bit8)
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,hs
			if	hi
				.cpu	68060
				movec.l	pcr,d0
				bset.l	#0,d0			;68060はスーパースカラON(bit0)
				movec.l	d0,pcr
				.cpu	68000
				move.l	#$00800000,d0		;68060はストアバッファOFF(bit29),分岐キャッシュON(bit23)
			endif
			move.w	#$8000,d0		;68040/68060はデータキャッシュOFF(bit31),命令キャッシュON(bit15)
		endif
		.cpu	68030
		movec.l	d0,cacr
		.cpu	68000
		clr.b	SYSPORT_WAIT
	endif

;クロック計測
;ROM計測
	lea.l	clock_loop(pc),a0	;計測ループ
	bsr	clock_sub		;計測サブ
	move.l	d0,BIOS_MPU_SPEED_ROM_LONG.w
	if	<cmp.l #$0000FFFF,d0>,hi
		moveq.l	#-1,d0
	endif
	move.w	d0,BIOS_MPU_SPEED_ROM.w
;RAM計測
	lea.l	-30(sp),sp
	move.l	sp,d0
	add.w	#14,d0
	and.w	#-16,d0
	movea.l	d0,a0			;16バイト境界から始まる16バイトのワークエリア
	movem.l	clock_loop(pc),d0-d2/a1	;計測ループをワークエリアにコピーする
	movem.l	d0-d2/a1,(a0)
;	スタックエリアが命令キャッシュに乗っていることはないのでキャッシュフラッシュは省略する
	bsr	clock_sub		;計測サブ
	lea.l	30(sp),sp
	move.l	d0,BIOS_MPU_SPEED_RAM_LONG.w
	if	<cmp.l #$0000FFFF,d0>,hi
		moveq.l	#-1,d0
	endif
	move.w	d0,BIOS_MPU_SPEED_RAM.w
	rts

;計測サブ
;>d0.l:計測値。0=失敗
;?d1-d2/a1
clock_sub:
aTCDCR	reg	a1
	lea.l	MFP_TCDCR,aTCDCR
;回数初期化
	moveq.l	#22-8+1,d2
	do
		subq.w	#1,d2
		move.l	#1<<22,d0
		lsr.l	d2,d0
		subq.l	#1,d0
	;割り込み禁止
		di
	;タイマ保存
		move.b	MFP_IERB-MFP_TCDCR(aTCDCR),-(sp)
		move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(sp)
		move.b	MFP_TCDCR-MFP_TCDCR(aTCDCR),-(sp)
	;タイマ設定
		andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み禁止
		andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み停止。IPRBクリア
	;カウント停止
		move.b	#0,(aTCDCR)		;Timer-C/Dカウント停止
		do
		while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ
	;カウント開始
		move.b	#0,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタクリア
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
		move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/Dカウント開始
						;Timer-Cは1/200プリスケール(50us)
						;Timer-Dは1/4プリスケール(1us)
	;計測
		jsr	(a0)
	;カウント停止
		move.b	#0,(aTCDCR)		;Timer-C/Dカウント停止
		do
		while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ
	;タイマ取得
		moveq.l	#0,d0
		moveq.l	#0,d1
		sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-Cカウント数
		sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-Dカウント数(オーバーフローあり)
	;タイマ復元
		move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタ復元
		move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
		move.b	(sp)+,(aTCDCR)
		move.b	(sp)+,MFP_IMRB-MFP_TCDCR(aTCDCR)
		move.b	(sp)+,MFP_IERB-MFP_TCDCR(aTCDCR)
	;割り込み許可
		ei
	;カウンタ合成
		mulu.w	#50,d0
		if	<cmp.b d1,d0>,hi
			add.w	#256,d0
		endif
		move.b	d1,d0			;0|us
	whileand	<tst.w d2>,ne,<cmp.w #5000,d0>,lo	;5000usに満たなければ回数を2倍にして計測し直す
	if	<tst.w d0>,ne
	;補正
		lea.l	clock_scale(pc),a1
		moveq.l	#0,d1
		move.b	BIOS_MPU_TYPE.w,d1
		if	<cmp.w #6,d1>,ls
			lsl.w	#2,d1
			adda.w	d1,a1
		endif
		move.l	(a1),d1
		lsr.l	d2,d1			;d1=H|L
		divu.w	d0,d1			;d1=vc?(H|L)%us|(H|L)/us:H|L
		if	vc
			move.w	d1,d0			;d0=0|(H|L)/us
		else
			move.l	d1,d2			;d2=H|L
			clr.w	d2			;d2=H|0
			swap.w	d2			;d2=0|H
			divu.w	d0,d2			;d2=(0|H)%us|(0|H)/us
			swap.w	d0			;d0=us|0
			move.w	d2,d0			;d0=us|(0|H)/us
			swap.w	d0			;d0=(0|H)/us|us
			move.w	d1,d2			;d2=(0|H)%us|L
			divu.w	d0,d2			;d2=((0|H)%us|L)%us|((0|H)%us|L)/us
			move.w	d2,d0			;d0=(0|H)/us|((0|H)%us|L)/us
		endif
	endif
	rts

;計測ループ
	.align	16,$2048		;内側のdbraを.align 4にする。RAM計測が.align 16なのでROM計測も.align 16にする
clock_loop:
	forlong	d0
	next
	rts

	.align	4
clock_scale:
	.dc.l	4194304000	;68000
	.dc.l	4194304000	;68010
	.dc.l	4194304000	;68020
	.dc.l	4194304000	;68030
	.dc.l	2796202667	;68040
	.dc.l	0
	.dc.l	699050667	;68060

;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  |           |c/n|   f   |u/n=c/n/f|  n | u=u/n*n|  J  |      K=c/n/J*2^22      |             CB8=K/(2^22/n)/u            |        f=CB8*J        |
;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  |68000/68010| 12| 10.000|  1.200  |2^13|9830.400|0.012|4194304000=12/0.012*2^22|  833.333=4194304000/(2^22/2^13)/9830.400| 10.000=  833.333*0.012|
;  |           |   | 16.667|  0.720  |2^13|5898.240|     |                        | 1388.889=4194304000/(2^22/2^13)/5898.240| 16.667= 1388.889*0.012|
;  |           |   | 25.000|  0.480  |2^14|7864.320|     |                        | 2083.333=4194304000/(2^22/2^14)/7864.320| 25.000= 2083.333*0.012|
;  |           |   | 33.333|  0.360  |2^14|5898.240|     |                        | 2777.778=4194304000/(2^22/2^14)/5898.240| 33.333= 2777.778*0.012|
;  |           |   | 50.000|  0.240  |2^15|7864.320|     |                        | 4166.667=4194304000/(2^22/2^15)/7864.320| 50.000= 4166.667*0.012|
;  |           |   | 66.666|  0.180  |2^15|5898.240|     |                        | 5555.556=4194304000/(2^22/2^15)/5898.240| 66.667= 5555.556*0.012|
;  |           |   |100.000|  0.120  |2^16|7864.320|     |                        | 8333.333=4194304000/(2^22/2^16)/7864.320|100.000= 8333.333*0.012|
;  |           |   |750.000|  0.016  |2^19|8388.608|     |                        |62500.000=4194304000/(2^22/2^19)/8388.608|750.000=62500.000*0.012|
;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  |68020/68030|  6| 25.000|  0.240  |2^15|7864.320|0.006|4194304000= 6/0.006*2^22| 4166.667=4194304000/(2^22/2^15)/7864.320| 25.000= 4166.667*0.006|
;  |           |   | 33.333|  0.180  |2^15|5898.240|     |                        | 5555.556=4194304000/(2^22/2^15)/5898.240| 33.333= 5555.556*0.006|
;  |           |   | 50.000|  0.120  |2^16|7864.320|     |                        | 8333.333=4194304000/(2^22/2^16)/7864.320| 50.000= 8333.333*0.006|
;  |           |   |375.000|  0.016  |2^19|8388.608|     |                        |62500.000=4194304000/(2^22/2^19)/8388.608|375.000=62500.000*0.006|
;  +-----------+---+-------+---------+----+--------+     +------------------------+-----------------------------------------+-----------------------+
;  |   68040   |  4| 25.000|  0.160  |2^15|5242.880|     |2796202667= 4/0.006*2^22| 4166.667=2796202667/(2^22/2^15)/5242.880| 25.000= 4166.667*0.006|
;  +-----------+---+-------+---------+----+--------+     +------------------------+-----------------------------------------+-----------------------+
;  |   68060   |  1| 33.333|  0.030  |2^18|7864.320|     | 699050667= 1/0.006*2^22| 5555.556= 699050667/(2^22/2^18)/7864.320| 33.333= 5555.556*0.006|
;  |           |   | 50.000|  0.020  |2^18|5242.880|     |                        | 8333.333= 699050667/(2^22/2^18)/5242.880| 50.000= 8333.333*0.006|
;  |           |   | 66.667|  0.015  |2^19|7864.320|     |                        |11111.111= 699050667/(2^22/2^19)/7864.320| 66.667=11111.111*0.006|
;  |           |   | 75.000|  0.013  |2^19|6990.507|     |                        |12500.000= 699050667/(2^22/2^19)/6990.507| 75.000=12500.000*0.006|
;  +-----------+---+-------+---------+----+--------+-----+------------------------+-----------------------------------------+-----------------------+
;  凡例
;    c/n  dbraループ1回のサイクル数
;    f    動作周波数(MHz)
;    u/n  dbraループ1回の所要時間(マイクロ秒)
;    n    dbraループ回数。2の累乗でuが5000以上10000未満になるように調整する
;    u    dbraループn回の所要時間(マイクロ秒)
;    J    68000/68010のとき0.012、68020/68030/68030/68060は0.006
;         dbraで分岐するときのサイクル数が68000は12サイクル、68030は6サイクルであることに由来する
;    K    c/n/J*2^22。テーブルから取り出す。2^22はKを2^32未満で最大にして誤差を減らすための係数
;    CB8  [$0CB8].wの値。ROMで計測した動作周波数。X68000はf*250/3、X68030はf*500/3。12倍または6倍することでf*1000として用いる
;  補足
;    68000/68010のdbraは10サイクルだがROMのときはウエイトがかかるので12サイクルになる
;    RAMのときはDRAMのリフレッシュの影響で(1+0.22/f)倍くらいになる



;----------------------------------------------------------------
;	不具合
;		MC68000のときエリアセットのポートをリードしようとして起動できない
;	解説
;		IPLROM 1.2までMOVE.B $00,$00E86001だったところがIPLROM 1.3でCLR.B $00E86001に変更された
;		MC68000のCLR.Bはライトの前にリードする
;		エリアセットのポート$00E86001は真にライトオンリーでリードするとバスエラーになる
;		したがってMC68000ではCLR.B $00E86001がバスエラーになる
;		X68000にX68030のROMを乗せると起動できない原因の1つ
;		エミュレータでCLR.Bのリードが省略されている場合は起動できる
;	対策
;		SF.BもリードするのでCLR.BをSF.Bに変更しても駄目
;		直前のアラーム起動の処理$00FF05BEから復帰したときA0は常にRTCのアドレス$00E8A000を指しているのでこれを使う
;	参考
;		ふってぃさんの一連の考察
;		https://twitter.com/futtyt/status/1332591514963197953
;	変更前
;		00FF01B2  423900E86001          clr.b   $00E86001
;		00FF01B8
;----------------------------------------------------------------
	PATCH_DATA	area_set,$00FF01B2,$00FF01B7,$423900E8
;<a0.l:$00E8A000
	move.b	#$00,$00E86001-$00E8A000(a0)



;----------------------------------------------------------------
;	LCD対応キー
;	変更前
;		00FF0252  7213                  moveq.l	#$13,d1
;		00FF0254  43F80800              lea.l	BIOS_BITSNS.w,a1
;		00FF0258  082900050005          btst.b	#5,5(a1)		;Vキー。N|B|V|C|X|Z|]}|:*
;		00FF025E  660A                  bne.s	$00FF026A
;		00FF0260  7210                  moveq.l	#$10,d1
;		00FF0262  082900070005          btst.b	#7,5(a1)		;Nキー。N|B|V|C|X|Z|]}|:*
;		00FF0268  6718                  beq.s	$00FF0282
;		00FF026A  13FC003100E8E00D      move.b	#$31,$00E8E00D		;SRAM書き込み許可
;		00FF0272  13C100ED001D          move.b	d1,$00ED001D		;起動時の画面モード
;		00FF0278  423900E8E00D          clr.b	$00E8E00D		;SRAM書き込み禁止
;		00FF027E  70104E4F              IOCS	_CRTMOD
;		00FF0282
;----------------------------------------------------------------
	PATCH_DATA	lcd_key,$00FF0252,$00FF0281,$721343F8
	jsr	lcd_key
	bra	($00FF0282)PATCH_ZL
	PATCH_TEXT
lcd_key:
	moveq.l	#0,d1
	if	<btst.b #KEY_L&7,BIOS_BITSNS+(KEY_L>>3).w>,ne	;Lキーが押されている
		move.w	#$4C00+16,d1		;画面モード16(768x512)LCD向け
;	elif	<btst.b #KEY_N&7,BIOS_BITSNS+(KEY_N>>3).w>,mi	;Nキーが押されている
	elif	<tst.b BIOS_BITSNS+(KEY_N>>3).w>,mi	;Nキーが押されている
		move.w	#$4300+16,d1		;画面モード16(768x512)CRT向け
	elif	<btst.b #KEY_T&7,BIOS_BITSNS+(KEY_T>>3).w>,ne	;Tキーが押されている
		move.w	#$4300+3,d1		;画面モード3(256x240ノンインターレース)CRT向け
	elif	<btst.b #KEY_V&7,BIOS_BITSNS+(KEY_V>>3).w>,ne	;Vキーが押されている
		move.w	#$4C00+19,d1		;画面モード19(640x480)LCD向け
	endif
	bclr.b	#0,BIOS_STARTUP_FLAGS.w	;HITANYKEY=0
	if	<tst.w d1>,ne
		bset.b	#0,BIOS_STARTUP_FLAGS.w	;HITANYKEY=1
		unlocksram
		move.b	d1,SRAM_CRTMOD		;起動時の画面モード
		locksram
		IOCS	_CRTMOD
	endif
	rts



;----------------------------------------------------------------
;	ROMデバッガ
;		OPT.2キーが押されているとき、SRAMにあるROMデバッガ起動フラグをOFFまたはCONのときAUXに、AUXのときOFFに変更します
;		Dキーが押されているとき、SRAMにあるROMデバッガ起動フラグをOFFまたはAUXのときCONに、CONのときOFFに変更します
;		OPT.2キーの効果が一時的なものから永続的なものに変更されていることに注意してください
;	変更前
;		00FF0286 423809DE		clr.b	$09DE.w
;		00FF028A 1038080E		move.b	$080E.w,d0
;		00FF028E 123900ED0058		move.b	$00ED0058,d1
;		00FF0294 B300			eor.b	d1,d0
;		00FF0296 08000003		btst.l	#3,d0
;		00FF029A 670C			beq	$00FF02A8
;		00FF029C 11FC000109DE		move.b	#1,$09DE.w
;		00FF02A2 207AFD64		movea.l	$00FF0008(pc),a0
;		00FF02A6 4E90			jsr	(a0)
;		00FF02A8
;----------------------------------------------------------------
	PATCH_DATA	p0286,$00FF0286,$00FF02A7,$423809DE
	jsr	p0286
	bra	($00FF02A8)PATCH_ZL
	PATCH_TEXT
p0286:
	lea.l	SRAM_ROMDB,a0
	move.b	(a0),d0			;0=OFF,-1=AUX,1=CON
	do
		moveq.l	#1,d1			;1=CON
		if	<btst.b #KEY_D&7,BIOS_BITSNS+(KEY_D>>3).w>,eq	;Dキーが押されていない
			neg.b	d1			;-1=AUX
			break	<btst.b #KEY_OPT2&7,BIOS_BITSNS+(KEY_OPT2>>3).w>,eq	;OPT.2キーが押されていない
		endif
	;DキーまたはOPT.2キーが押されている
		if	<cmp.b d0,d1>,eq	;フラグと同じキーが押されている
			clr.b	d1			;0=OFF
		endif
		if	<cmp.b d0,d1>,ne	;フラグが変化する
			move.b	d1,d0
			lea.l	SYSPORT_SRAM,a1
			move.b	#$31,(a1)
			move.b	d0,(a0)
			clr.b	(a1)
		endif
	while	f
	neg.b	d0			;0=OFF,1=AUX,-1=CON
	move.b	d0,BIOS_ROMDB.w
	if	ne			;1=AUX,-1=CON
		movea.l	$00FF0008,a0		;ROMデバッガの開始アドレス
		jsr	(a0)			;ROMデバッガを起動する
	endif
	rts



;----------------------------------------------------------------
;	68040/68060のときデバイスドライバがMMUを有効にするまでデータキャッシュをOFFにする
;	変更前
;		00FF02A8 7202                   moveq.l	#$02,d1
;		00FF02AA 70AC                   moveq.l	#_SYS_STAT,d0
;		00FF02AC 4E4F                   trap	#15
;		00FF02AE
;----------------------------------------------------------------
	PATCH_DATA	cache_start,$00FF02A8,$00FF02AD,$720270AC
	jsr	cache_start
	PATCH_TEXT
cache_start:
	push	d2
	moveq.l	#0,d2
	move.b	SRAM_CACHE,d2		;キャッシュ設定。------|データ|命令
	if	<cmpi.b #4,BIOS_MPU_TYPE.w>,hs	;68040/68060
		and.b	#.notb.%10,d2		;データキャッシュOFF
	endif
	bsr	cache_set		;キャッシュ設定
	pop
	rts



;----------------------------------------------------------------
;	Hit any key
;	変更前
;		00FF02B2 43FA08D4               lea.l	$00FF0B88(pc),a1	;$1A
;		00FF02B6 61000470               bsr.w	$00FF0728		;文字列表示
;		00FF02BA
;----------------------------------------------------------------
	PATCH_DATA	hitanykey,$00FF02B2,$00FF02B9,$43FA08D4
	jsr	hitanykey
	PATCH_TEXT
hitanykey:
	if	<btst.b #0,BIOS_STARTUP_FLAGS.w>,ne	;HITANYKEY
		lea.l	-64(sp),sp
		movea.l	sp,a0
		bsr	crlf
		bsr	start_proportional
		lea.l	100f(pc),a1		;'  Hit any key'
		bsr	strcpy
		bsr	end_proportional
		bsr	crlf
		movea.l	sp,a1
		bsr	iocs_21_B_PRINT
		lea.l	64(sp),sp
		do
			redo	<btst.b #KEY_L&7,BIOS_BITSNS+(KEY_L>>3).w>,ne	;Lキーが押されている
		;	redo	<btst.b #KEY_N&7,BIOS_BITSNS+(KEY_N>>3).w>,ne	;Nキーが押されている
			redo	<tst.b BIOS_BITSNS+(KEY_N>>3).w>,mi	;Nキーが押されている
			redo	<btst.b #KEY_T&7,BIOS_BITSNS+(KEY_T>>3).w>,ne	;Tキーが押されている
			redo	<btst.b #KEY_V&7,BIOS_BITSNS+(KEY_V>>3).w>,ne	;Vキーが押されている
		while	f			;L/N/T/Vキーが離されるまで待つ
		bsr	kflush			;キーバッファを空にする
		bsr	inkey			;キーが押されるまで待つ
	endif
	rts

100:	.dc.b	'  Hit any key',0
	.even

;----------------------------------------------------------------
;プロポーショナルピッチ開始
start_proportional:
	lea.l	100f(pc),a1
	bra	10f

;プロポーショナルピッチ終了
end_proportional:
	lea.l	101f(pc),a1
10:
	goto	<btst.b #0,message_style(pc)>,ne,strcpy	;プロポーショナルピッチ
	clr.b	(a0)
	rts

100:	.dc.b	27,'[26m',0
101:	.dc.b	27,'[50m',0
	.even



;----------------------------------------------------------------
;	XF3,XF4,XF5を押しながら起動したときのキャッシュOFF
;	変更前
;		00FF0336 7000                   moveq.l	#$00,d0
;		00FF0338 4E7B0002               movec.l	d0,cacr			;キャッシュOFF
;		00FF033C
;----------------------------------------------------------------
	PATCH_DATA	xf345_cache_off,$00FF0336,$00FF033B,$70004E7B
	jsr	cache_off		;キャッシュOFF



;----------------------------------------------------------------
;	XF1,XF2を押しながら起動したときのキャッシュOFF
;	変更前
;		00FF0380 7000                   moveq.l	#$00,d0
;		00FF0382 4E7B0002               movec.l	d0,cacr			;キャッシュOFF
;		00FF0386
;----------------------------------------------------------------
	PATCH_DATA	xf12_cache_off,$00FF0380,$00FF0385,$70004E7B
	jsr	cache_off		;キャッシュOFF



;----------------------------------------------------------------
;	未定義例外処理
;		68000のときバスエラーとアドレスエラーの例外スタックフレームを掘り起こさない
;			TRAP#14(エラー表示)がSSWとACCESS ADDRESSとINSTRUCTION REGISTERにアクセスできる
;		68000以外のときPCの最上位バイトが$02～$0Fならばそれをベクタ番号として使う
;			X68030で未定義のFライン命令を実行したとき「エラー($000B)が発生しました」ではなく
;			「おかしな命令を実行しました」と表示される
;	変更前
;		00FF0762 7E00             	moveq.l	#$00,d7
;		00FF0764 3E2F0006         	move.w	$0006(sp),d7
;		00FF0768 CE7C0FFF         	and.w	#$0FFF,d7		;ベクタオフセット
;		00FF076C E44F             	lsr.w	#2,d7			;ベクタ番号
;		00FF076E 6042_000007B2    	bra	$00FF07B2		;白窓表示
;		00FF0770 61000002_00000774	bsr	$00FF0774
;		00FF0774 2E1F             	move.l	(sp)+,d7		;$00FF0774そのもの
;		00FF0776 4A380CBC         	tst.b	BIOS_MPU_TYPE.w
;		00FF077A 66E6_00000762    	bne	$00FF0762
;		00FF077C 4247             	clr.w	d7
;		00FF077E 4847             	swap.w	d7
;		00FF0780 E04F             	lsr.w	#8,d7
;		00FF0782 BE7C0003         	cmp.w	#$0003,d7
;		00FF0786 622A_000007B2    	bhi	$00FF07B2
;		00FF0788 5C8F             	addq.l	#6,sp
;		00FF078A 4847             	swap.w	d7
;		00FF078C 3E1F             	move.w	(sp)+,d7		;命令コード
;		00FF078E 2C6F0002         	movea.l	$0002(sp),a6		;PC
;		00FF0792 BE56             	cmp.w	(a6),d7
;		00FF0794 6714_000007AA    	beq	$00FF07AA
;		00FF0796 BE66             	cmp.w	-(a6),d7
;		00FF0798 6710_000007AA    	beq	$00FF07AA
;		00FF079A BE66             	cmp.w	-(a6),d7
;		00FF079C 670C_000007AA    	beq	$00FF07AA
;		00FF079E BE66             	cmp.w	-(a6),d7
;		00FF07A0 6708_000007AA    	beq	$00FF07AA
;		00FF07A2 BE66             	cmp.w	-(a6),d7
;		00FF07A4 6704_000007AA    	beq	$00FF07AA
;		00FF07A6 BE66             	cmp.w	-(a6),d7
;		00FF07A8 6604_000007AE    	bne	$00FF07AE
;		00FF07AA 2F4E0002         	move.l	a6,$0002(sp)		;PCをエラーが発生した命令まで戻す
;		00FF07AE 4247             	clr.w	d7
;		00FF07B0 4847             	swap.w	d7
;		00FF07B2 2C4F             	movea.l	sp,a6
;		00FF07B4 4E4E             	trap	#14
;		00FF07B6 303C00FF         	move.w	#_ABORTJOB,d0
;		00FF07BA 4E4F             	trap	#15
;		00FF07BC 60F8_000007B6    	bra	$00FF07B6		;無限ループ
;		00FF07BE
;----------------------------------------------------------------
	PATCH_DATA	p0770,$00FF0770,$00FF0775,$61000002
	jsr	p0770			;ここでPCをプッシュする。jmpはPCの最上位バイトが消えてしまうので不可
	PATCH_TEXT
p0770:
	moveq.l	#0,d7
	move.b	(sp),d7			;PCの最上位バイト
	addq.l	#4,sp
	movea.l	sp,a6			;SRの位置。68000のバスエラーとアドレスエラーを除く
	if	<tst.b BIOS_MPU_TYPE.w>,eq	;68000
		ifor	<cmp.b #$02,d7>,eq,<cmp.b #$03,d7>,eq	;バスエラーとアドレスエラー
		;	MC68000UM 6-17
		;	0.w
		;	  15-5 4   3   2-0
		;	  X    R/W I/N FC
		;	  R/W  0=Write,1=Read
		;	  I/N  0=Instruction,1=Not
		;	2.l  ACCESS ADDRESS
		;	6.w  INSTRUCTION REGISTER
		;	8.w  STATUS REGISTER
		;	10.l  PROGRAM COUNTER
			swap.w	d7
			move.w	6(sp),d7		;命令コード
			movea.l	10(sp),a6		;PC
			do
				if	<cmp.w (a6),d7>,ne
					if	<cmp.w -(a6),d7>,ne
						if	<cmp.w -(a6),d7>,ne
							if	<cmp.w -(a6),d7>,ne
								if	<cmp.w -(a6),d7>,ne
									break	<cmp.w -(a6),d7>,ne
								endif
							endif
						endif
					endif
					move.l	a6,10(sp)		;PCをエラーが発生した命令まで戻す
				endif
			while	f
			clr.w	d7
			swap.w	d7
			lea.l	8(sp),a6		;SRの位置。SPを掘り起こさない
		endif
	else				;68000以外
		ifor	<cmp.b #$02,d7>,lo,<cmp.b #$0F,d7>,hi	;$02～$0F以外
			move.w	6(sp),d7		;フォーマットとベクタオフセット
			and.w	#$0FFF,d7		;ベクタオフセット
			lsr.w	#2,d7			;ベクタ番号
		endif
	endif
	trap	#14			;TRAP#14(エラー表示)
10:	IOCS	_ABORTJOB
	goto	10b			;無限ループ



;----------------------------------------------------------------
;	IOCS _ABORTJOB
;		TRAP#14(エラー表示)の変更に合わせて表示を変更する
;	変更前
;		00FF07BE 6128			bsr	$00FF07E8		;画面モードによってテキスト画面の表示位置を調節する
;		00FF07C0 43F900FF0B53		lea.l	$00FF0B53,a1		;エラーが発生しました。リセットしてください。
;		00FF07C6 6100FF60		bsr	$00FF0728		;文字列表示
;		00FF07CA 60FE			bra	$00FF07CA		;無限ループ
;----------------------------------------------------------------
	PATCH_DATA	p07BE,$00FF07BE,$00FF07CB,$612843F9
	jsr	p07BE
	PATCH_TEXT
p07BE:
	lea.l	-64(sp),sp
	movea.l	sp,a0
	bsr	start_proportional
	lea.l	100f(pc),a1		;'  Press the RESET switch'
	bsr	strcpy
	bsr	end_proportional
	movea.l	sp,a1
	bsr	iocs_21_B_PRINT
	lea.l	64(sp),sp
10:
	goto	10b			;無限ループ

100:	.dc.b	'  Press the RESET switch',0
	.even



;----------------------------------------------------------------
;	起動画面
;	変更前
;		00FF0E76 48E7F0E0       	movem.l	d0-d3/a0-a2,-(sp)
;		00FF0E7A 6100025C       	bsr	$00FF10D8		;起動音
;		00FF0E7E 6120           	bsr	$00FF0EA0		;ロゴ
;		00FF0E80 7200           	moveq.l	#$00,d1
;		00FF0E82 70AC4E4F       	IOCS	_SYS_STAT
;		00FF0E86 2600           	move.l	d0,d3
;		00FF0E88 61000182       	bsr	$00FF100C		;ROMのバージョン
;		00FF0E8C 615C           	bsr	$00FF0EEA		;MPUの種類と動作周波数
;		00FF0E8E 610000EE       	bsr	$00FF0F7E		;FPU/FPCPの有無
;		00FF0E92 610000F8       	bsr	$00FF0F8C		;MMUの有無
;		00FF0E96 61000104       	bsr	$00FF0F9C		;メインメモリのサイズ
;		00FF0E9A 4CDF070F       	movem.l	(sp)+,d0-d3/a0-a2
;		00FF0E9E 4E75           	rts
;		00FF0EA0
;----------------------------------------------------------------
	PATCH_DATA	ipl_message,$00FF0E76,$00FF0E9F,$48E7F0E0
	jmp	ipl_message
	PATCH_TEXT
;----------------------------------------------------------------
;起動画面を表示する
ipl_message:
	push	d0-d7/a0-a6,128
;キー確認
;	SRAM_XEIJは_CRTMODで初期化済み
	lea.l	SRAM_XEIJ,a0
	lea.l	SYSPORT_SRAM,a1
	moveq.l	#$31,d2
	if	<btst.b #0,BIOS_STARTUP_FLAGS.w>,ne	;HITANYKEY
		move.b	d2,(a1)			;unlocksram
		bclr.b	#SRAM_XEIJ_QUIET_BIT,(a0)	;起動画面を表示する
		clr.b	(a1)			;locksram
	elif	<btst.b #KEY_Q&7,BIOS_BITSNS+(KEY_Q>>3).w>,ne	;Qキーが押されている
		move.b	d2,(a1)			;unlocksram
		bset.b	#SRAM_XEIJ_QUIET_BIT,(a0)	;起動画面を表示しない
		clr.b	(a1)			;locksram
	endif
	if	<btst.b #SRAM_XEIJ_QUIET_BIT,(a0)>,eq	;起動画面を表示する
		jsr	$00FF10D8		;起動音
		jsr	$00FF0EA0		;ロゴ
		moveq.l	#0,d1
		IOCS	_SYS_STAT
		move.l	d0,d7			;MPUステータス
	;<d7.l:MPUステータス
		movea.l	sp,a6			;文字列バッファ
	;<a6.l:文字列バッファ
		movea.l	a6,a0
		if	<btst.b #2,message_style(pc)>,ne	;隙間あり
			bsr	crlf
		endif
		bsr	start_proportional
		movea.l	a6,a1
		bsr	iocs_21_B_PRINT
	;メッセージ
		bsr	ipl_message_romver	;ROMのバージョンを表示する
		bsr	ipl_message_model	;機種を表示する
		bsr	ipl_message_series	;シリーズを表示する
		bsr	ipl_message_mpu		;MPUの種類と動作周波数を表示する
		bsr	ipl_message_mmu		;MMUの有無を表示する
		bsr	ipl_message_fpu		;FPU/FPCPの有無と種類を表示する
		bsr	ipl_message_memory	;メインメモリの範囲と容量を表示する
		bsr	ipl_message_exmemory	;拡張メモリの範囲と容量を表示する
		bsr	ipl_message_coprocessor	;コプロセッサの有無と種類を表示する
		bsr	ipl_message_dmac_clock	;DMACの動作周波数を表示する
		bsr	ipl_message_rtc_dttm	;RTCの日時を表示する
		bsr	ipl_message_hd_type	;内蔵ハードディスクインターフェイスの種類を表示する
		bsr	ipl_message_boot_device	;起動デバイスを表示する
	;テキストカーソルを下から7行目に移動させる
		movea.l	a6,a0
		move.b	#27,(a0)+
		move.b	#'=',(a0)+
		moveq.l	#' '-6,d0
		add.w	BIOS_CONSOLE_BOTTOM.w,d0
		move.b	d0,(a0)+		;行
		move.b	#' '+0,(a0)+		;桁
		bsr	end_proportional
		movea.l	a6,a1
		bsr	iocs_21_B_PRINT
	endif
	pop
	rts

;----------------------------------------------------------------
;左の列を表示する
;<a1.l:文字列。コロンを含まない
;<a6.l:文字列バッファ
;?d0/a0-a1
print_left_column:
	movea.l	a6,a0			;文字列バッファ
	if	<btst.b #1,message_style(pc)>,ne	;中央寄せ
		move.b	#27,(a0)+
		move.b	#'[',(a0)+
		moveq.l	#1,d0
		add.w	BIOS_CONSOLE_RIGHT.w,d0
		lsl.w	#2,d0			;コンソールの幅(px)/2
		bsr	utos
		move.b	#'r',(a0)+		;左の列を中央までの右寄せで表示する
		bsr	strcpy
		lea.l	100f(pc),a1		;' : ',1
		bsr	strcpy
	else				;左寄せ
		move.l	a1,d0
		if	<btst.b #0,message_style(pc)>,ne	;プロポーショナルピッチ
			lea.l	101f(pc),a1		;27,'[320l'。左寄せ40文字
		else				;ノーマルピッチ
			lea.l	102f(pc),a1		;27,'[304l'。左寄せ38文字
		endif
		bsr	strcpy
		movea.l	d0,a1
		bsr	strcpy
		lea.l	103f(pc),a1		;1,' : '
		bsr	strcpy
	endif
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	' : ',1,0
101:	.dc.b	27,'[320l',0
102:	.dc.b	27,'[304l',0
103:	.dc.b	1,' : ',0
	.even

;----------------------------------------------------------------
;ROMのバージョンを表示する
;<a6.l:文字列バッファ
;?d0-d1/a0-a1
ipl_message_romver:
	lea.l	100f(pc),a1		;'ROM version'
	bsr	print_left_column
	IOCS	_ROMVER
;BCD変換
	move.l	d0,d1			;abcdefgh
	clr.w	d0			;abcd0000
	sub.l	d0,d1			;0000efgh
	swap.w	d0			;0000abcd
	lsl.l	#4,d0			;000abcd0
	lsl.l	#4,d1			;000efgh0
	lsr.w	#4,d0			;000a0bcd
	lsr.w	#4,d1			;000e0fgh
	lsl.l	#8,d0			;0a0bcd00
	lsl.l	#8,d1			;0e0fgh00
	lsr.w	#4,d0			;0a0b0cd0
	lsr.w	#4,d1			;0e0f0gh0
	lsr.b	#4,d0			;0a0b0c0d
	lsr.b	#4,d1			;0e0f0g0h
	or.l	#$30303030,d0		;3a3b3c3d
	or.l	#$30303030,d1		;3e3f3g3h
;バージョン
	movea.l	a6,a0			;文字列バッファ
	rol.l	#8,d0
	move.b	d0,(a0)+
	move.b	#'.',(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
;日付
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	rol.l	#8,d0
	if	<cmp.b #'8',d0>,hs
		move.b	#'1',(a0)+
		move.b	#'9',(a0)+
	else
		move.b	#'2',(a0)+
		move.b	#'0',(a0)+
	endif
	move.b	d0,(a0)+
	rol.l	#8,d0
	move.b	d0,(a0)+
	move.b	#'-',(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	move.b	#'-',(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	rol.l	#8,d1
	move.b	d1,(a0)+
	move.b	#')',(a0)+
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'ROM Version',0
	.even

;----------------------------------------------------------------
;機種を表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?a0-a1
ipl_message_model:
	if	<cmpi.l #'NAME',$00FFFFE0>,ne	;機種名がない
		rts
	endif
	lea.l	100f(pc),a1		;'Model'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	$00FFFFE4,a1
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Model',0
	.even

;----------------------------------------------------------------
;シリーズを表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?a0-a1
ipl_message_series:
	lea.l	100f(pc),a1		;'Series'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	101f(pc),a1		;'X68000'
	if	<isX68030>,eq
		lea.l	102f(pc),a1		;'X68030'
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Series',0
101:	.dc.b	'X68000',0
102:	.dc.b	'X68030',0
	.even

;----------------------------------------------------------------
;MPUの種類と動作周波数を表示する
;	XCとMC
;		000/010/020/030/040はMC
;		060はリビジョン5までXC、リビジョン6からMC
;			http://www.ppa.pl/forum/amiga/29981/68060-pcr
;			?	リビジョン0
;			F43G	リビジョン1
;			G65V	リビジョン5
;			G59Y	?
;			E41J	リビジョン6
;	無印とECとLC
;		000/010/020は無印
;		030はMMUがないときEC、MMUがあるとき無印
;		040/060はMMUがないときEC、MMUがあってFPUがないときLC、MMUとFPUがあるとき無印
;	リビジョンナンバー
;		060のとき末尾に-dddでリビジョンナンバーを表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0-d2/a0-a1
ipl_message_mpu:
	lea.l	100f(pc),a1		;'Microprocessor'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
;型番
	moveq.l	#-1,d2			;リビジョンナンバー。-1=リビジョンナンバーなし
	moveq.l	#'M',d1
	if	<cmp.b #6,d7>,eq	;060
		.cpu	68060
		movec.l	pcr,d0
		.cpu	68000
		lsr.l	#8,d0
		moveq.l	#0,d2
		move.b	d0,d2			;リビジョンナンバー
		if	<cmp.b #6,d2>,lo
			moveq.l	#'X',d1		;060はリビジョン5までXC
		endif
	endif
	move.b	d1,(a0)+		;'M'または'X'
	lea.l	101f(pc),a1		;'C68'
	bsr	strcpy
	do
		break	<cmp.b #3,d7>,lo	;000/010/020は無印
		moveq.l	#'E',d1			;030/040/060でMMUがないときEC
		if	<btst.l #14,d7>,ne	;030/040/060でMMUがあるとき
			break	<cmp.b #3,d7>,eq	;030でMMUがあるとき無印
			break	<tst.w d7>,mi		;040/060でMMUとFPUがあるとき無印
			moveq.l	#'L',d1			;040/060でMMUがあってFPUがないときLC
		endif
		move.b	d1,(a0)+		;'E'または'L'
		move.b	#'C',(a0)+		;'C'
	while	f
	move.b	#'0',(a0)+		;'0'
	moveq.l	#'0',d1
	add.b	d7,d1
	move.b	d1,(a0)+		;'0'～'6'
	move.b	#'0',(a0)+		;'0'
	move.l	d2,d0			;リビジョンナンバー
	if	pl
		move.b	#'-',(a0)+
		moveq.l	#3,d1
		bsr	utosz
	endif
;動作周波数
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	move.l	d7,d0
	clr.w	d0
	swap.w	d0			;動作周波数(MHz)*10
	bsr	utos
	move.b	-1(a0),(a0)+		;小数点以下1桁目を後ろにずらす
	move.b	#'.',-2(a0)		;小数点を押し込む
	lea.l	102f(pc),a1		;'MHz)'
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Microprocessor',0
101:	.dc.b	'C68',0
102:	.dc.b	'MHz)',0
	.even

;----------------------------------------------------------------
;FPU/FPCPの有無と種類を表示する
;	030はfmovecr.x #1,fp0が0のときMC68881、さもなくばMC68882
;	040/060はon-chip
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0/a0-a1
ipl_message_fpu:
	if	<tst.w d7>,pl		;FPU/FPCPなし
		rts
	endif
	lea.l	100f(pc),a1		;'Floating-Point Unit (FPU)'
	if	<cmp.b #4,d7>,lo	;020/030
		lea.l	101f(pc),a1		;'Floating-Point Coprocessor (FPCP)'
	endif
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	102f(pc),a1		;'on-chip'
	if	<cmp.b #4,d7>,lo	;020/030
		lea.l	103f(pc),a1		;'MC68881'
		.cpu	68030
		fmovecr.x	#1,fp0		;0=MC68881,0以外=MC68882
		fmove.x	fp0,-(sp)
		.cpu	68000
		move.l	(sp)+,d0
		or.l	(sp)+,d0
		or.l	(sp)+,d0
		if	ne
			lea.l	104f(pc),a1		;'MC68882'
		endif
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Floating-Point Unit (FPU)',0
101:	.dc.b	'Floating-Point Coprocessor (FPCP)',0
102:	.dc.b	'on-chip',0
103:	.dc.b	'MC68881',0
104:	.dc.b	'MC68882',0
	.even

;----------------------------------------------------------------
;MMUの有無を表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0/a0-a1
ipl_message_mmu:
	if	<btst.l #14,d7>,eq	;MMUなし
		rts
	endif
	lea.l	100f(pc),a1		;'Memory Management Unit (MMU)'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	101f(pc),a1		;'on-chip'
	if	<cmp.b #3,d7>,lo	;020
		lea.l	102f(pc),a1		;'MC68851'
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Memory Management Unit (MMU)',0
101:	.dc.b	'on-chip',0
102:	.dc.b	'MC68851',0
	.even

;----------------------------------------------------------------
;メインメモリの範囲と容量を表示する
;	$00100000-$00BFFFFFについて1MB単位でメインメモリの有無を確認し、メインメモリが存在する範囲を表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0-d1/a0-a1
ipl_message_memory:
	lea.l	100f(pc),a1		;'Main Memory'
	bsr	print_left_column
	moveq.l	#0,d0			;開始アドレス
	move.l	BIOS_MEMORY_SIZE.w,d1	;終了アドレス(これを含まない)
;----------------------------------------------------------------
;メモリの範囲と容量を表示する
;<d0.l:開始アドレス
;<d1.l:終了アドレス(これを含まない)
;<a6.l:文字列バッファ
;?d0/a0-a1
ipl_message_memory_sub:
	movea.l	a6,a0			;文字列バッファ
	move.b	#'$',(a0)+
	bsr	h8tos			;開始アドレス
	move.b	#'-',(a0)+
	move.b	#'$',(a0)+
	move.l	d0,-(sp)		;開始アドレス
	move.l	d1,d0			;終了アドレス(これを含まない)
	subq.l	#1,d0			;終了アドレス(これを含む)
	bsr	h8tos
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	move.l	d1,d0			;終了アドレス(これを含まない)
	sub.l	(sp)+,d0		;終了アドレス(これを含まない)-開始アドレス=容量
	clr.w	d0
	swap.w	d0
	lsr.w	#4,d0			;容量(16MB単位)
	bsr	utos
	lea.l	101f(pc),a1		;'MB)'
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Main Memory',0
101:	.dc.b	'MB)',0
	.even

;----------------------------------------------------------------
;拡張メモリの範囲と容量を表示する
;	$01000000-$FFFFFFFFについて16MB単位で独立した拡張メモリの有無を確認し、拡張メモリが存在する範囲を表示する
;	手順
;		各ページの同じオフセットに上位のページから順に異なるデータを書き込む
;		下位のページに書き込んだことで上位のページのデータが変化した場合は上位のページは存在しないと判断する
;		$2000-$21FFをワークとして使用する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0-d1/a0-a3/a5
ipl_message_exmemory:
;	if	<cmp.b #2,d7>,lo	;000/010
;		rts
;	endif
;確認開始
	di				;sr保存、割り込み禁止
	move.l	OFFSET_BUS_ERROR.w,-(sp)	;バスエラーベクタ保存
	movea.l	sp,a5			;sp保存
;読み出し、保存
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2			;ページの先頭。a2=page<<24
	lea.l	$2200.w,a1		;保存領域。a1=$2100+page
	lea.l	$2100.w,a0		;結果領域。a0=$2000+page
	move.w	#$00FF,d1		;ページ番号。d1=page
	for	d1
		suba.l	#$01000000,a2
		subq.l	#1,a1
		st.b	-(a0)			;$FF=読み出し失敗
		nop
		move.b	(a2),(a1)		;読み出し、保存。-(a1)はバスエラーのときずれるので不可
		nop
		sf.b	(a0)			;$00=読み出し成功
	@@:	movea.l	a5,sp			;sp復元
	next
;書き込み
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2
	lea.l	$2100.w,a0
	move.w	#$00FF,d1
	for	d1
		suba.l	#$01000000,a2
		if	<tst.b -(a0)>,eq	;$00=読み出し成功のとき
			st.b	(a0)			;$FF=書き込み失敗
			nop
			move.b	d1,(a2)			;書き込み
			nop
			sf.b	(a0)			;$00=読み出し成功かつ書き込み成功,$FF=読み出し失敗または書き込み失敗
		@@:	movea.l	a5,sp			;sp復元
		endif
	next
;比較
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2
	lea.l	$2100.w,a0
	move.w	#$00FF,d1
	for	d1
		suba.l	#$01000000,a2
		if	<tst.b -(a0)>,eq	;$00=読み出し成功かつ書き込み成功のとき
			nop
			cmp.b	(a2),d1			;比較
			nop
			sne.b	(a0)			;$00=一致,$FF=読み出し失敗または書き込み失敗または不一致
		@@:	movea.l	a5,sp			;sp復元
		endif
	next
;復元
	move.l	#@f,OFFSET_BUS_ERROR.w
	suba.l	a2,a2
	lea.l	$2200.w,a1
	move.w	#$00FF,d1
	for	d1
		suba.l	#$01000000,a2
		nop
		move.b	-(a1),(a2)		;復元
		nop
	@@:	movea.l	a5,sp			;sp復元
	next
;確認終了
	move.l	(sp)+,OFFSET_BUS_ERROR.w	;バスエラーベクタ復元
	ei				;sr復元
;表示
	suba.l	a2,a2			;開始位置。a2=$2000+page。0=page-1に拡張メモリはない
	lea.l	$2000+1.w,a3		;終了位置。a3=$2000+page
	do
		if	<tst.b (a3)>,eq		;ある
			continue	<move.l a2,d0>,ne	;ある→ある
		;ない→ある
			movea.l	a3,a2			;開始位置
		else				;ない
			continue	<move.l a2,d0>,eq	;ない→ない
		;ある→ない
			bsr	ipl_message_exmemory_sub	;拡張メモリの範囲と容量を1つ表示する
			suba.l	a2,a2			;開始位置
		endif
	while	<addq.l #1,a3>,<cmpa.w #$20FF,a3>,ls
	if	<move.l a2,d0>,ne	;ある→ない
		bsr	ipl_message_exmemory_sub	;拡張メモリの範囲と容量を1つ表示する
	endif
;後始末
	lea.l	$2000.w,a0
	moveq.l	#($2200-$2000)/4-1,d0
	for	d0
		clr.l	(a0)+
	next
	rts

;----------------------------------------------------------------
;拡張メモリの範囲と容量を1つ表示する
;<a2.l:$2000+page。開始位置
;<a3.l:$2000+page。終了位置(これを含まない)
;<a6.l:文字列バッファ
;?d0-d1/a0-a1
ipl_message_exmemory_sub:
	lea.l	100f(pc),a1		;'Extension Memory'
	bsr	print_left_column
	move.l	a2,d0
	swap.w	d0
	lsl.l	#8,d0			;開始アドレス
	move.l	a3,d1
	swap.w	d1
	lsl.l	#8,d1			;終了アドレス(これを含まない)
	goto	ipl_message_memory_sub

100:	.dc.b	'Extension Memory',0
	.even

;----------------------------------------------------------------
;コプロセッサの有無と種類を表示する
;	マザーボードコプロセッサ
;		040/060でFC=7の$00022000にCIRがある
;	数値演算プロセッサボード1
;		$00E9E000にCIRがある
;	数値演算プロセッサボード2
;		$00E9E080にCIRがある
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
ipl_message_coprocessor:
;マザーボードコプロセッサ
	if	<cmp.b #4,d7>,hs	;040/060
		bsr	copro_check_1
		if	<tst.l d0>,pl		;マザーボードコプロセッサがある
			lea.l	105f(pc),a1		;'Motherboard Coprocessor'
			bsr	print_left_column
			movea.l	a6,a0			;文字列バッファ
			lea.l	103f(pc),a1		;'MC68881'
			if	<tst.l d0>,ne
				lea.l	104f(pc),a1		;'MC68882'
			endif
			bsr	strcpy
			bsr	crlf
			movea.l	a6,a1			;文字列バッファ
			bsr	iocs_21_B_PRINT
		endif
	endif
;数値演算プロセッサボード1
	moveq.l	#0,d0
	bsr	copro_check_2
	if	<tst.l d0>,pl		;数値演算プロセッサボード1がある
		lea.l	106f(pc),a1		;'Extension Coprocessor #1'
		bsr	print_left_column
		movea.l	a6,a0			;文字列バッファ
		lea.l	103f(pc),a1		;'MC68881'
		if	<tst.l d0>,ne
			lea.l	104f(pc),a1		;'MC68882'
		endif
		bsr	strcpy
		bsr	crlf
		movea.l	a6,a1			;文字列バッファ
		bsr	iocs_21_B_PRINT
	endif
;数値演算プロセッサボード2
	moveq.l	#1,d0
	bsr	copro_check_2
	if	<tst.l d0>,pl		;数値演算プロセッサボード2がある
		lea.l	107f(pc),a1		;'Extension Coprocessor #2'
		bsr	print_left_column
		movea.l	a6,a0			;文字列バッファ
		lea.l	103f(pc),a1		;'MC68881',13,10
		if	<tst.l d0>,ne
			lea.l	104f(pc),a1		;'MC68882',13,10
		endif
		bsr	strcpy
		bsr	crlf
		movea.l	a6,a1			;文字列バッファ
		bsr	iocs_21_B_PRINT
	endif
	rts

105:	.dc.b	'Motherboard Coprocessor',0
106:	.dc.b	'Extension Coprocessor #1',0
107:	.dc.b	'Extension Coprocessor #2',0
103:	.dc.b	'MC68881',0
104:	.dc.b	'MC68882',0
	.even

;----------------------------------------------------------------
;マザーボードコプロセッサの有無と種類を調べる
;	1ms以内に判別できなければ諦める。Timer-Cが動作していること
;>d0.l:-1=なし,0=MC68881,1=MC68882
	.cpu	68060
copro_check_1:
	moveq.l	#-1,d0			;-1=なし
	if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;000/010/020/030
		rts
	endif
	push	d1-d5/a0-a3
	lea.l	$00022000,a0		;マザーボードコプロセッサのCIR
;<a0.l:FPCP_CIR
	lea.l	MFP_TCDR,a3
;<a3.l:MFP_TCDR
	move.w	sr,d2			;sr保存
;<d2.w:srの元の値
	ori.w	#$0700,sr		;割り込み禁止
	move.b	(a3),d3
	sub.b	#20,d3			;50us*20=1ms
	if	ls
		add.b	#200,d3
	endif
;<d3.b:1ms後のMFP_TCDRの値
	movec.l	dfc,d4			;dfc保存
;<d4.l:dfcの元の値
	movec.l	sfc,d5			;sfc保存
;<d5.l:sfcの元の値
	moveq.l	#7,d1			;CPU空間
	movec.l	d1,dfc
	movec.l	d1,sfc
	movea.l	OFFSET_BUS_ERROR.w,a2	;バスエラー保存
;<a2.l:バスエラーの元のベクタ
	lea.l	copro_check_1_abort(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp保存
;<a1.l:spの元の値
	clr.w	d1			;null
	moves.w	d1,$06(a0)		;restore
	moves.w	$06(a0),d1		;restore
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_1_abort	;タイムアウト
		moves.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$5C01,d1		;fmovecr.x #$01,fp0
	moves.w	d1,$0A(a0)		;command
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_1_abort	;タイムアウト
		moves.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$6800,d1		;fmove.x fp0,<mem>
	moves.w	d1,$0A(a0)		;command
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_1_abort	;タイムアウト
		moves.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
;	while	<cmp.w #$320C,d1>,ne	;extended to mem
	while	<cmp.w #$8900,d1>,eq	;busy
	moves.l	$10(a0),d0		;operand
	moves.l	$10(a0),d1		;operand
	or.l	d1,d0
	moves.l	$10(a0),d1		;operand
	or.l	d1,d0			;0=MC68881
	if	ne
		moveq.l	#1,d0			;1=MC68882
	endif
copro_check_1_abort:
	movea.l	a1,sp			;sp復元
	move.l	a2,OFFSET_BUS_ERROR.w	;バスエラー復元
	movec.l	d5,sfc			;sfc復元
	movec.l	d4,dfc			;dfc復元
	move.w	d2,sr			;sr復元
	pop
	rts
	.cpu	68000

;----------------------------------------------------------------
;数値演算プロセッサボードの有無と種類を調べる
;	1ms以内に判別できなければ諦める。Timer-Cが動作していること
;<d0.l:0=数値演算プロセッサボード1,1=数値演算プロセッサボード2
;>d0.l:-1=なし,0=MC68881,1=MC68882
copro_check_2:
	push	d1-d3/a0-a3
	lea.l	$00E9E000,a0		;数値演算プロセッサボード1のCIR
	if	<tst.l d0>,ne
		lea.l	$00E9E080-$00E9E000(a0),a0	;数値演算プロセッサボード2のCIR
	endif
;<a0.l:FPCP_CIR
	lea.l	MFP_TCDR,a3
;<a3.l:MFP_TCDR
	moveq.l	#-1,d0			;-1=なし
;<d0.l:-1=なし,0=MC68881,1=MC68882
	move.w	sr,d2			;sr保存
;<d2.w:srの元の値
	ori.w	#$0700,sr		;割り込み禁止
	move.b	(a3),d3
	sub.b	#20,d3			;50us*20=1ms
	if	ls
		add.b	#200,d3
	endif
;<d3.b:1ms後のMFP_TCDRの値
	movea.l	OFFSET_BUS_ERROR.w,a2	;バスエラー保存
;<a2.l:バスエラーの元のベクタ
	lea.l	copro_check_2_abort(pc),a1
	move.l	a1,OFFSET_BUS_ERROR.w
	movea.l	sp,a1			;sp保存
;<a1.l:spの元の値
	move.w	#$0000,$06(a0)		;restore,null
	tst.w	$06(a0)			;restore
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_2_abort	;タイムアウト
		move.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$5C01,$0A(a0)		;command,fmovecr.x #$01,fp0
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_2_abort	;タイムアウト
		move.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
	while	<cmp.w #$0802,d1>,ne	;idle
	move.w	#$6800,$0A(a0)		;command,fmove.x fp0,<mem>
	do
		goto	<cmp.b (a3),d3>,eq,copro_check_2_abort	;タイムアウト
		move.w	(a0),d1			;response
	;	and.w	#$7FFF,d1		;clear CA
;	while	<cmp.w #$320C,d1>,ne	;extended to mem
	while	<cmp.w #$8900,d1>,eq	;busy
	move.l	$10(a0),d0		;operand
	move.l	$10(a0),d1		;operand
	or.l	d1,d0
	move.l	$10(a0),d1		;operand
	or.l	d1,d0			;0=MC68881
	if	ne
		moveq.l	#1,d0			;1=MC68882
	endif
copro_check_2_abort:
	movea.l	a1,sp			;sp復元
	move.l	a2,OFFSET_BUS_ERROR.w	;バスエラー復元
	move.w	d2,sr			;sr復元。割り込み許可
	pop
	rts

;----------------------------------------------------------------
;DMACの動作周波数を表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0-d2/a0-a1
ipl_message_dmac_clock:
	lea.l	100f(pc),a1		;'Direct Memory Access Controller (DMAC)'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	101f(pc),a1		;'HD63450 (Main Memory:'
	bsr	strcpy
	lea.l	$6800.w,a2
	bsr	measure_dmac_clock
	bsr	utos
	lea.l	102f(pc),a1		;'%, SRAM:'
	bsr	strcpy
	lea.l	$00ED0000,a2
	bsr	measure_dmac_clock
	bsr	utos
	lea.l	103f(pc),a1		;'%)',13,10
	bsr	strcpy
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Direct Memory Access Controller (DMAC)',0
101:	.dc.b	'HD63450 (Main Memory:',0
102:	.dc.b	'%, SRAM:',0
103:	.dc.b	'%)',13,10,0
	.even

;----------------------------------------------------------------
;DMACの動作周波数を計測する
;	DMACが(a2)から(a2)へ5000ワード転送するのにかかる時間をus単位で計る
;	10MHzの10サイクル/ワードを100%とする%値を返す
;<a2.l:アドレス
;>d0.l:DMACの動作速度。10MHzの10サイクル/ワードを100%とする%値
measure_dmac_clock:
	push	d1-d2/a0-a1
aDMAC	reg	a0
	lea.l	DMAC_2_BASE,aDMAC
aTCDCR	reg	a1
	lea.l	MFP_TCDCR,aTCDCR
;キャッシュ禁止
	bsr	cache_off
	move.l	d0,d2
;割り込み禁止
	di
;SRAM書き込み許可
	unlocksram
;DMAC保存
	move.b	DMAC_DCR(aDMAC),-(sp)
	move.b	DMAC_OCR(aDMAC),-(sp)
	move.b	DMAC_SCR(aDMAC),-(sp)
	move.b	DMAC_MFC(aDMAC),-(sp)
	move.b	DMAC_CPR(aDMAC),-(sp)
	move.b	DMAC_DFC(aDMAC),-(sp)
;DMAC設定
	st.b	DMAC_CSR(aDMAC)		;CSRクリア
	move.b	#DMAC_BURST_TRANSFER|DMAC_HD68000_COMPATIBLE|DMAC_16_BIT_PORT|DMAC_STATUS_INPUT,DMAC_DCR(aDMAC)
	move.b	#DMAC_MEMORY_TO_DEVICE|DMAC_16_BIT_OPERAND|DMAC_NO_CHAINING|DMAC_AUTO_REQUEST_MAX,DMAC_OCR(aDMAC)
	move.b	#DMAC_INCREMENT_MEMORY|DMAC_INCREMENT_DEVICE,DMAC_SCR(aDMAC)
	move.b	#DMAC_HIGHEST_PRIORITY,DMAC_CPR(aDMAC)
	move.b	#DMAC_SUPERVISOR_DATA,DMAC_MFC(aDMAC)
	move.b	#DMAC_SUPERVISOR_DATA,DMAC_DFC(aDMAC)
	move.l	a2,DMAC_MAR(aDMAC)	;転送元
	move.l	a2,DMAC_DAR(aDMAC)	;転送先
	move.w	#5000,DMAC_MTC(aDMAC)	;転送オペランド数
;タイマ保存
	move.b	MFP_IERB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	MFP_IMRB-MFP_TCDCR(aTCDCR),-(sp)
	move.b	(aTCDCR),-(sp)
;タイマ設定
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IERB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み停止
	andi.b	#.notb.(MFP_B_TIMERC_MASK|MFP_B_TIMERD_MASK),MFP_IMRB-MFP_TCDCR(aTCDCR)	;Timer-C/D割り込み禁止
	move.b	#0,(aTCDCR)		;Timer-C/Dカウント停止
	do
	while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ
	move.b	#0,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタクリア
	move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
;カウント開始
	move.b	#MFP_50US<<4|MFP_1US,(aTCDCR)	;Timer-C/Dカウント開始
						;Timer-Cは1/200プリスケール(50us)
						;Timer-Dは1/4プリスケール(1us)
;DMA転送実行
;	DMA転送中はMPUのバスアクセスが制限されることに注意
	move.b	#DMAC_CCR_STR,DMAC_CCR(aDMAC)	;DMA転送開始
  .rept 8
	nop				;12.5MHzで7サイクル(560ns)待つ
  .endm
	do
	while	<tst.b DMAC_CSR(aDMAC)>,pl	;DMA転送終了を待つ
;カウント停止
	move.b	#0,(aTCDCR)		;Timer-C/Dカウント停止
	do
	while	<tst.b (aTCDCR)>,ne	;完全に停止するまで待つ
;タイマ取得
	moveq.l	#0,d0
	sub.b	MFP_TCDR-MFP_TCDCR(aTCDCR),d0	;Timer-Cカウント数
	moveq.l	#0,d1
	sub.b	MFP_TDDR-MFP_TCDCR(aTCDCR),d1	;Timer-Dカウント数(オーバーフローあり)
;タイマ復元
	move.b	#200,MFP_TCDR-MFP_TCDCR(aTCDCR)	;Timer-Cカウンタ復元
	move.b	#0,MFP_TDDR-MFP_TCDCR(aTCDCR)	;Timer-Dカウンタクリア
	move.b	(sp)+,(aTCDCR)
	move.b	(sp)+,MFP_IMRB-MFP_TCDCR(aTCDCR)
	move.b	(sp)+,MFP_IERB-MFP_TCDCR(aTCDCR)
;DMAC復元
	st.b	DMAC_CSR(aDMAC)		;CSRクリア
	move.b	(sp)+,DMAC_DFC(aDMAC)
	move.b	(sp)+,DMAC_CPR(aDMAC)
	move.b	(sp)+,DMAC_MFC(aDMAC)
	move.b	(sp)+,DMAC_SCR(aDMAC)
	move.b	(sp)+,DMAC_OCR(aDMAC)
	move.b	(sp)+,DMAC_DCR(aDMAC)
;SRAM書き込み禁止
	locksram
;割り込み許可
	ei
;カウンタ合成
	mulu.w	#50,d0
	if	<cmp.b d1,d0>,hi
		add.w	#256,d0
	endif
	move.b	d1,d0
	subq.w	#1,d0
;<d0.l:SRAMからSRAMへ5000ワードDMA転送するのにかかった時間(us)。0～12799
;10サイクル/ワードで10MHzを100%とする%値を求める
;	10(サイクル/ワード)/(d0/5000)(us/ワード)/10(MHz)*100 = 10*5000/d0*10
	move.l	#10*5000*10,d1		;d1=被除数
	divu.w	d0,d1			;d1=余り<<16|商
	swap.w	d1			;d1=商<<16|余り
	lsr.w	#1,d0			;d0=除数/2
	sub.w	d1,d0			;d0=除数/2-余り。x=除数/2<余り?1:0
	swap.w	d1			;d1=余り<<16|商
	moveq.l	#0,d0
	addx.w	d1,d0
;<d0.l:10MHzの10サイクル/ワードを100%とする%値
;キャッシュ許可
	move.l	d0,d1
	bsr	cache_set
	move.l	d1,d0
	pop
	rts


;----------------------------------------------------------------
;RTCの日時を表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0-d2/a0-a1
ipl_message_rtc_dttm:
	lea.l	100f(pc),a1		;'Real Time Clock (RTC)'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	101f(pc),a1		;'RP5C15 ('
	bsr	strcpy
;RTCから日時を読み出す
	bsr	readrtc
	if	pl
		bsr	checkdttm
	endif
;<d0.l:0=正常,-1=異常
;<d1.l:曜日<<28|西暦年<<16|月<<8|月通日
;<d2.l:時<<16|分<<8|秒
;異常のとき取り消し線開始
	if	<tst.l d0>,mi
		lea.l	102f(pc),a1		;27,'[9m'
		bsr	strcpy
	endif
;日時を文字列に変換する
	bsr	dttmtos
;異常のとき取り消し線終了
	if	<tst.l d0>,mi
		lea.l	103f(pc),a1		;27,'[29m'
		bsr	strcpy
	endif
	lea.l	104f(pc),a1		;')',13,10
	bsr	strcpy
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Real Time Clock (RTC)',0
101:	.dc.b	'RP5C15 (',0
102:	.dc.b	27,'[9m',0
103:	.dc.b	27,'[29m',0
104:	.dc.b	')',13,10,0
	.even

;--------------------------------------------------------------------------------
;日時を文字列に変換する
;<d1.l:曜日<<28|西暦年<<16|月<<8|月通日
;<d2.l:時<<16|分<<8|秒
;<a0.l:バッファ
;>a0.l:0の位置
dttmtos:
	push	d0-d2
	swap.w	d1			;d1.l:月<<24|月通日<<16|曜日<<12|西暦年
	move.l	#$00000FFF,d0
	and.w	d1,d0			;d0.l:西暦年
	bsr	utos
	move.b	#'-',(a0)+
	rol.l	#8,d1			;d1.l:月通日<<24|曜日<<20|西暦年<<8|月
	moveq.l	#0,d0
	move.b	d1,d0			;d0.l:月
	bsr	50f
	move.b	#'-',(a0)+
	rol.l	#8,d1			;d1.l:曜日<<28|西暦年<<16|月<<8|月通日
	moveq.l	#0,d0
	move.b	d1,d0			;d0.l:月通日
	bsr	50f
	move.b	#' ',(a0)+
	move.b	#'(',(a0)+
	rol.l	#4,d1			;d1.l:西暦年<<20|月<<12|月通日<<4|曜日
	moveq.l	#$0F,d0
	and.b	d1,d0			;d0.l:曜日
	if	<cmp.b #7,d0>,hi
		moveq.l	#7,d0
	endif
	lsl.b	#2,d0			;4*曜日
	lea.l	100f(pc,d0.w),a1
	bsr	strcpy
	move.b	#')',(a0)+
	move.b	#' ',(a0)+
	swap.w	d2			;d2.l:分<<24|秒<<16|時
	moveq.l	#0,d0
	move.b	d2,d0			;d0.l:時
	bsr	50f
	move.b	#':',(a0)+
	rol.l	#8,d2			;d2.l:秒<<24|時<<8|分
	moveq.l	#0,d0
	move.b	d2,d0			;d0.l:分
	bsr	50f
	move.b	#':',(a0)+
	rol.l	#8,d2			;d2.l:|時<<16|分<<8|秒
	moveq.l	#0,d0
	move.b	d2,d0			;d0.l:秒
	bsr	50f
	pop
	rts

50:	if	<cmp.b #10,d0>,lo
		move.b	#'0',(a0)+
	endif
	goto	utos

100:	.dc.b	'Sun',0
	.dc.b	'Mon',0
	.dc.b	'Tue',0
	.dc.b	'Wed',0
	.dc.b	'Thu',0
	.dc.b	'Fri',0
	.dc.b	'Sat',0
	.dc.b	'???',0
	.even

;--------------------------------------------------------------------------------
;RTCから日時を読み出す
;	スーパーバイザモードで呼び出すこと
;>d0.l:0=正常,-1=異常
;>d1.l:曜日<<28|西暦年<<16|月<<8|月通日
;>d2.l:時<<16|分<<8|秒
;	曜日	正常のとき0～6。0=日曜日,…,6=土曜日
;	西暦年	正常のとき1980～2079
;	月	正常のとき1～12
;	月通日	正常のとき1～月の日数
;	時	正常のとき0～23
;	分	正常のとき0～59
;	秒	正常のとき0～59
;	異常のとき範囲外の値が返ることがある
;>ccr:pl=正常,mi=異常
;	異常の内容
;	・BCDが異常
readrtc:
	push	d3-d4/d7/a0-a2
	moveq.l	#0,d7			;正常
aRTC	reg	a1
rtc	reg	-RTC_MODE(aRTC)
	lea.l	RTC_MODE,aRTC
aPPIA	reg	a2
	lea.l	PPI_PORT_A,aPPIA
;------------------------------------------------
;RTCのレジスタを読み出す
;	複数のレジスタを読み出している間に時計が進みレジスタの内容が変化する場合がある
;	上位から読んで最下位が0のとき(繰り上がりにかかる時間待ってから)読み直す
	moveq.l	#2-1,d4
	for	d4
		moveq.l	#RTC_MODE_BANK_MASK,d0
		or.b	(RTC_MODE)rtc,d0
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		move.b	d0,(RTC_MODE)rtc	;バンク1
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		moveq.l	#$01,d2
		and.b	(RTC_1_TWENTY_FOUR)rtc,d2	;0=12時間計,1=24時間計
		subq.b	#1,d0
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		move.b	d0,(RTC_MODE)rtc	;バンク0
		tst.b	(aPPIA)
		tst.b	(aPPIA)
		moveq.l	#$07,d1
		and.b	(RTC_0_DAY_OF_WEEK)rtc,d1	;曜日カウンタ
		lea.l	(RTC_0_TEN_YEARS+1)rtc,a0	;10年カウンタの直後
		moveq.l	#6-1,d3
		for	d3
			moveq.l	#$0F,d0
			and.w	-(a0),d0		;10年カウンタ→1日カウンタ
			lsl.l	#4,d1
			or.b	d0,d1
		next
		subq.l	#2,a0			;曜日カウンタを跨ぐ。10時カウンタの直後
		moveq.l	#6-1,d3
		for	d3
			moveq.l	#$0F,d0
			and.w	-(a0),d0		;10時カウンタ→1秒カウンタ
			lsl.l	#4,d2
			or.b	d0,d2
		next
		moveq.l	#$0F,d0
		and.b	d2,d0			;最下位
	next	eq			;0でなければ終了
;<d1.l:曜日<<24|(西暦年-1980)(BCD)<<16|月(BCD)<<8|月通日(BCD)
;<d2.l:時(BCD)<<16|分(BCD)<<8|秒(BCD)
;------------------------------------------------
;日付をデコードする
	move.l	d1,d0
	bsr	decode3bcd		;2桁*3組のBCDをデコードする
;<d0.l:曜日<<24|(西暦年-1980)<<16|月<<8|月通日
	if	mi			;異常
		moveq.l	#-1,d7			;異常
	endif
;曜日をずらして西暦年に1980を加える
	swap.w	d0			;mmdd0wyy
	ror.w	#8,d0			;mmddyy0w
	lsl.b	#4,d0			;mmddyyw0
	rol.w	#8,d0			;mmddw0yy
	add.w	#1980,d0		;mmddwyyy
	swap.w	d0			;wyyymmdd
	move.l	d0,d1
;<d1.l:曜日<<28|西暦年<<16|月<<8|月通日
;------------------------------------------------
;時刻をデコードする
	move.l	d2,d0
	bsr	decode3bcd		;2桁*3組のBCDをデコードする
;<d0.l:時<<16|分<<8|秒
	if	mi			;異常
		moveq.l	#-1,d7			;異常
	endif
	move.l	d0,d2
;<d2.l:時<<16|分<<8|秒
;------------------------------------------------
;終了
	move.l	d7,d0
	pop
	rts

;--------------------------------------------------------------------------------
;RTCから読み出した日時に異常がないか確認する
;<d1.l:曜日<<28|西暦年<<16|月<<8|月通日
;<d2.l:時<<16|分<<8|秒
;>d0.l:0=正常,-1=異常
;>ccr:pl=正常,mi=異常
;	異常の内容
;	・2023月2日29日や31時などの存在しない日時
;	・_ROMVERの日付より前の明らかに過去の日付
;	・曜日が違う
checkdttm:
	push	d3-d5/a0
;------------------------------------------------
;日付を分解する
	move.l	d1,d5			;d5.l:曜日<<28|西暦年<<16|月<<8|月通日
	moveq.l	#0,d3
	move.b	d5,d3			;d3.l:月通日。正常のとき1～月の日数
	lsr.w	#8,d5			;d5.l:曜日<<28|西暦年<<16|月
	moveq.l	#0,d4
	move.b	d5,d4			;d4.l:月。正常のとき1～12
	swap.w	d5			;d5.l:月<<16|曜日<<12|西暦年
	and.l	#$00000FFF,d5		;d5.l:西暦年。正常のとき1980～2079
;<d3.l:月通日。正常のとき1～月の日数
;<d4.l:月。正常のとき1～12
;<d5.l:西暦年。正常のとき1980～2079
;------------------------------------------------
;西暦年の範囲を確認する
	gotoor	<cmp.w #1980,d5>,lo,<cmp.w #2079,d5>,hi,90f	;西暦年が1980より小さいまたは2079より大きい
;------------------------------------------------
;月の範囲を確認する
	gotoor	<tst.w d4>,eq,<cmp.w #12,d4>,hi,90f	;月が0または12より大きい
;------------------------------------------------
;月通日の範囲を確認する
	moveq.l	#0,d0
	if	<cmp.b #2,d4>,eq	;2月
		moveq.l	#3,d0
		and.b	d5,d0			;西暦年&3
		seq.b	d0			;0=閏年ではない年の2月,-1=閏年の2月
		neg.b	d0			;0=閏年ではない年の2月,1=閏年の2月
	endif
	lea.l	daysofmonth(pc),a0
	add.b	-1(a0,d4.w),d0		;d0.l:月の日数
	gotoor	<tst.w d3>,eq,<cmp.w d0,d3>,hi,90f	;月通日が0または月の日数より大きい
;------------------------------------------------
;_ROMVERの日付と比較する
	IOCS	_ROMVER
	bsr	decode3bcd		;2桁*3組のBCDをデコードする
;<d0.l:_ROMVERのバージョン<<24|_ROMVERの西暦年の下2桁<<16|_ROMVERの月<<8|_ROMVERの月通日
;_ROMVERの西暦年と比較する
	swap.w	d0			;d0.w:_ROMVERのバージョン<<24|_ROMVERの西暦年の下2桁
	and.w	#$00FF,d0		;d0.w:_ROMVERの西暦年の下2桁
	add.w	#1900,d0
	if	<cmp.w #1950,d0>,lo
		add.w	#2000-1900,d0	;d0.w:_ROMVERの西暦年
	endif
	goto	<cmp.w d0,d5>,lo,90f	;_ROMVERの西暦年より前
	if	eq			;_ROMVERの西暦年と同じ
	;_ROMVERの月と比較する
		swap.w	d0			;d0.w:_ROMVERの月<<8|_ROMVERの月通日
		ror.w	#8,d0			;d0.w:_ROMVERの月通日<<8|_ROMVERの月
		goto	<cmp.b d0,d4>,lo,90f	;_ROMVERの月より前
		if	eq			;_ROMVERの月と同じ
		;_ROMVERの月通日と比較する
			rol.w	#8,d0			;d0.w:_ROMVERの月<<8|_ROMVERの月通日
			goto	<cmp.b d0,d3>,lo,90f	;_ROMVERの月通日より前
		endif
	endif
;------------------------------------------------
;曜日を確認する
	if	<cmp.w #2,d4>,ls	;1月と2月を
		subq.w	#1,d5			;前年の
		add.w	#12,d4			;13月と14月にする
	endif
	move.l	d5,d0			;d0.l:西暦年
	mulu.w	#365,d0			;d0.l:365*西暦年
	lsr.w	#2,d5			;d5.l:floor(西暦年/4)
	add.l	d5,d0			;d0.l:365*西暦年+floor(西暦年/4)
	addq.w	#1,d4			;d4.l:月+1
	mulu.w	#306,d4			;d4.l:306*(月+1)
  .if 1
	divu.w	#10,d4			;d4.w:floor(306*(月+1))/10。被除数は306*4=1224～306*15=4590
	ext.l	d4			;d4.l:floor(306*(月+1))/10
  .else
	mulu.w	#3277,d4
	add.l	d4,d4
	clr.w	d4
	swap.w	d4			;d4.l:floor(306*(月+1))/10
  .endif
	add.l	d4,d0			;d0.l:365*西暦年+floor(西暦年/4)+floor(306*(月+1))/10
	add.l	d3,d0			;d0.l:365*西暦年+floor(西暦年/4)+floor(306*(月+1))/10+月通日
	sub.l	#723256,d0		;d0.l:365*西暦年+floor(西暦年/4)+floor(306*(月+1))/10+月通日-723256。1980年1月1日は2、2079年12月31日は36526
	divu.w	#7,d0
	swap.w	d0			;d0.w:日付の曜日。0～6
	move.l	d1,d3			;d3.l:曜日<<28|西暦年<<16|月<<8|月通日
	rol.l	#4,d3			;d3.l:西暦年<<20|月<<12|月通日<<4|曜日
	and.w	#$000F,d3		;d3.w:RTCが返した曜日
	goto	<cmp.w d0,d3>,ne,90f	;曜日が違う
;------------------------------------------------
;時刻の範囲を確認する
	move.l	d2,d0
	goto	<cmp.b #59,d0>,hi,90f	;秒が範囲外
	lsr.w	#8,d0
	goto	<cmp.b #59,d0>,hi,90f	;分が範囲外
	swap.w	d0
	goto	<cmp.b #23,d0>,hi,90f	;時が範囲外
;------------------------------------------------
;正常終了
	moveq.l	#0,d0
80:	pop
	rts

;------------------------------------------------
;異常終了
90:	moveq.l	#-1,d0
	goto	80b

;------------------------------------------------
;閏年でない年の月の日数
daysofmonth:
	.dc.b	31,28,31,30,31,30,31,31,30,31,30,31
	.even

;--------------------------------------------------------------------------------
;2桁*3組のBCDをデコードする
;<d0.l:$WWXXYYZZ
;>d0.l:$WW<<24|x<<16|y<<8|z
;	上位8ビットは変化しない
;	x,y,zの最大値は正常のとき9*10+9=99、異常のとき15*10+15=165
;>ccr:pl=正常,mi=異常
decode3bcd:
	push	d1-d4/d7
	moveq.l	#0,d7			;d7.l:0=正常,-1=異常
	moveq.l	#10,d4			;d4.l:10
	moveq.l	#3-1,d3			;d3.w:2,1,0
	for	d3
		moveq.l	#$0F,d1
		and.b	d0,d1			;d1.b:下位4bit
		lsr.b	#4,d0			;d0.b:上位4bit
		ifor	<cmp.b d4,d1>,hs,<cmp.b d4,d0>,hs	;下位4bitが10以上または上位4bitが10以上
			moveq.l	#-1,d7			;異常
		endif
		move.b	d0,d2			;d2.b:上位4bit
		lsl.b	#2,d0			;d0.b:上位4bit*4
		add.b	d2,d0			;d0.b:上位4bit*5
		add.b	d0,d0			;d0.b:上位4bit*10
		add.b	d1,d0			;d0.b:上位4bit*10+下位4bit
		ror.l	#8,d0			;$ZZ,$YY,$XXの順
	next
	ror.l	#8,d0			;$WWはそのまま
	tst.l	d7
	pop
	rts


;----------------------------------------------------------------
;内蔵ハードディスクインターフェイスの種類を表示する
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0/a0-a1
ipl_message_hd_type:
	lea.l	100f(pc),a1		;'Built-in Hard Disk Interface'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	lea.l	101f(pc),a1		;'SASI'
	if	<isSASI>,ne
		lea.l	102f(pc),a1		;'SCSI'
	endif
	bsr	strcpy
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Built-in Hard Disk Interface',0
101:	.dc.b	'SASI',0
102:	.dc.b	'SCSI',0
	.even

;----------------------------------------------------------------
;起動デバイスを表示する
;	SRAM_ROM_BOOT_HANDLE	ROM起動ハンドル
;	SRAM_SRAM_BOOT_ADDRESS	SRAM起動アドレス
;	SRAM_BOOT_DEVICE	起動デバイス。$0000=STD,$8xxx=HD,$9xxx=FD,$Axxx=ROM,$Bxxx=SRAM
;		$0000	STD
;		$8xxx	HD n
;		$9xxx	FD n
;		$A000	ROM $xxxxxxxx
;			$00E9F020	XEiJ HFS
;			$00EA0020-	Expansion SCSI n
;			$00EA9000-	PhantomX VDISK n
;			$00FC0000-	Built-in SCSI n
;		$B000	SRAM $xxxxxxxx
;<d7.l:MPUステータス
;<a6.l:文字列バッファ
;?d0-d1/a0-a1
ipl_message_boot_device:
	lea.l	100f(pc),a1		;'Boot Device'
	bsr	print_left_column
	movea.l	a6,a0			;文字列バッファ
	move.w	SRAM_BOOT_DEVICE,d0	;起動デバイス
	if	eq			;$0000
		lea.l	101f(pc),a1		;'STD'
		bsr	strcpy
	elifor	<cmp.w #$8000,d0>,lo,<cmp.w #$C000,d0>,hs
		lea.l	102f(pc),a1		;'Unknown $'
		bsr	h4tos
	elif	<cmp.w #$9000,d0>,lo	;$8xxx
		lea.l	103f(pc),a1		;'SASI HD '
		bsr	strcpy
		lsr.w	#8,d0
		moveq.l	#$0F,d1
		and.l	d1,d0
		bsr	utos
	elif	<cmp.w #$A000,d0>,lo	;$9xxx
		lea.l	104f(pc),a1		;'FD '
		bsr	strcpy
		lsr.w	#8,d0
		moveq.l	#$07,d1
		and.l	d1,d0
		bsr	utos
	elif	<cmp.w #$B000,d0>,lo	;$Axxx
		move.l	SRAM_ROM_BOOT_HANDLE,d0	;ROM起動ハンドル
		moveq.l	#3,d1
		and.w	d0,d1
		if	<cmp.l #$00E9F020,d0>,eq
			lea.l	105f(pc),a1		;'XEiJ HFS'
			bsr	strcpy
		elifand	<cmp.l #$00EA0020,d0>,hs,<cmp.l #$00EA0020+4*8,d0>,lo,<tst.l d1>,eq
			lea.l	106f(pc),a1		;'Expansion SCSI '
			bsr	strcpy
			lsr.w	#2,d0
			moveq.l	#7,d1
			and.l	d1,d0
			bsr	utos
		elifand	<cmp.l #$00EA9000,d0>,hs,<cmp.l #$00EA9000+4*8,d0>,lo,<tst.l d1>,eq
			lea.l	107f(pc),a1		;'PhantomX VDISK '
			bsr	strcpy
			lsr.w	#2,d0
			moveq.l	#7,d1
			and.l	d1,d0
			bsr	utos
		elifand	<cmp.l #$00FC0000,d0>,hs,<cmp.l #$00FC0000+4*8,d0>,lo,<tst.l d1>,eq
			lea.l	108f(pc),a1		;'Built-in SCSI '
			bsr	strcpy
			lsr.w	#2,d0
			moveq.l	#7,d1
			and.l	d1,d0
			bsr	utos
		else
			lea.l	109f(pc),a1		;'ROM $'
			bsr	strcpy
			bsr	h8tos
		endif
	else				;$Bxxx
		lea.l	110f(pc),a1		;'SRAM $'
		bsr	strcpy
		move.l	SRAM_SRAM_BOOT_ADDRESS,d0	;SRAM起動アドレス
		bsr	h8tos
	endif
	bsr	crlf
	movea.l	a6,a1			;文字列バッファ
	goto	iocs_21_B_PRINT

100:	.dc.b	'Boot Device',0
101:	.dc.b	'STD',0
102:	.dc.b	'Unknown $',0
103:	.dc.b	'SASI HD ',0
104:	.dc.b	'FD ',0
105:	.dc.b	'XEiJ HFS',0
106:	.dc.b	'Expansion SCSI ',0
107:	.dc.b	'PhantomX VDISK ',0
108:	.dc.b	'Built-in SCSI ',0
109:	.dc.b	'ROM $',0
110:	.dc.b	'SRAM $',0
	.even



;----------------------------------------------------------------
;	SHARPロゴ
;	変更前
;		00FF0EC0 43FA04CA		lea.l	$00FF138C(pc),a1	;SHARPロゴ
;		00FF0EC4 343C0000		move.w	#$0000,d2
;		00FF0EC8
;----------------------------------------------------------------
	PATCH_DATA	sharp_logo,$00FF0EC0,$00FF0EC7,$43FA04CA
	lea.l	$00FFD680,a1
	clr.w	d2



;----------------------------------------------------------------
;	不具合
;		クロック表示ルーチンでA6レジスタの最上位バイトが破壊される
;		https://stdkmd.net/bugsx68k/#rom_clocka6
;	変更前
;		00000F0C 4E56FFFC         	link.w	a6,#-4
;		00000F10 1D7C00000000     	move.b	#$00,$0000.w(a6)
;----------------------------------------------------------------



;----------------------------------------------------------------
;	不具合
;		メインメモリが9MBのとき起動時に19MBと表示される
;	変更前
;		00000FD4 6A0A_00000FE0    	bpl	~FF0FE0			;9MB以上
;----------------------------------------------------------------



;----------------------------------------------------------------
;	起動音
;		起動音を鳴らすとFM音源ドライバが誤動作することがある不具合を修正する
;		https://stdkmd.net/bugsx68k/#rom_chime
;		起動音のキーコードを変更できるようにする
;----------------------------------------------------------------
	PATCH_DATA	play_stupsnd,$00FF10D8,$00FF118F,$4A3900ED

CH	equ	0

KC	equ	76
KF	equ	5
TM	equ	2500/100

FLCON	equ	(1<<3)|3		;|FL###|CON###|
SLOT	equ	%1101			;|C2|M2|C1|M1|
WAVE	equ	0
SYNC	equ	1
SPEED	equ	0
PMD	equ	0
AMD	equ	0
PMS	equ	0
AMS	equ	0
PAN	equ	%11			;|R|L|

M1AR	equ	6
M1D1R	equ	11
M1D2R	equ	4
M1RR	equ	4
M1D1L	equ	0
M1TL	equ	29
M1KS	equ	0
M1MUL	equ	0
M1DT1	equ	0
M1DT2	equ	3
M1AMSEN	equ	1

C1AR	equ	31
C1D1R	equ	6
C1D2R	equ	0
C1RR	equ	2
C1D1L	equ	2
C1TL	equ	40
C1KS	equ	2
C1MUL	equ	1
C1DT1	equ	0
C1DT2	equ	3
C1AMSEN	equ	1

M2AR	equ	3
M2D1R	equ	2
M2D2R	equ	7
M2RR	equ	2
M2D1L	equ	3
M2TL	equ	28
M2KS	equ	1
M2MUL	equ	3
M2DT1	equ	0
M2DT2	equ	1
M2AMSEN	equ	1

C2AR	equ	31
C2D1R	equ	21
C2D2R	equ	6
C2RR	equ	4
C2D1L	equ	2
C2TL	equ	2
C2KS	equ	1
C2MUL	equ	1
C2DT1	equ	0
C2DT2	equ	0
C2AMSEN	equ	1

play_stupsnd:
	push	d0-d4/a0
	move.b	SRAM_STARTUP_SOUND,d3	;0=off,1..255=on,2..127=kc
	if	ne			;on
		moveq.l	#$08,d1			;KeyOff
		moveq.l	#(0<<3)|CH,d2		;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
		lea.l	stupsnd_data(pc),a0	;レジスタデータの配列
		moveq.l	#$20+CH,d1		;レジスタアドレス
		moveq.l	#28-1,d4		;0..27
		for	d4
			move.b	(a0)+,d2		;レジスタデータ
			ifand	<cmp.b #$28+CH,d1>,eq,<cmp.b #2,d3>,ge	;2..127=kc。キーコードが指定されている
				move.b	d3,d2
			endif
			bsr	stupsnd_opmset
			addq.b	#8,d1			;次のレジスタアドレス
		next
		moveq.l	#6-1,d4			;28..39
		for	d4
			move.b	(a0)+,d1		;レジスタアドレス
			move.b	(a0)+,d2		;レジスタデータ
			bsr	stupsnd_opmset
		next
		moveq.l	#$08,d1			;KeyOn
		moveq.l	#(SLOT<<3)|CH,d2	;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
		moveq.l	#0,d0
		move.w	(a0)+,d0		;40..41。tm@100us
		add.l	d0,d0			;tm@50us
		jsr	wait_50us		;50us単位のウェイト
	;	moveq.l	#$08,d1			;KeyOff
		moveq.l	#(0<<3)|CH,d2		;|-|C2|M2|C1|M1|CH###|
		bsr	stupsnd_opmset
	endif
	pop
	rts

stupsnd_opmset:
	IOCS	_OPMSET
	rts

;レジスタデータ(42バイト)。偶数アドレスに配置すること
	.even
stupsnd_data:
  .ifdef STUPSNDDAT
	.insert	stupsnd.dat
  .else
	.dc.b	(PAN<<6)|FLCON		;0 $20+CH |PAN##|FL###|CON###|
	.dc.b	KC			;1 $28+CH |-|KC#######|
	.dc.b	KF<<2			;2 $30+CH |KF######|--|
	.dc.b	(PMS<<4)|AMS		;3 $38+CH |-|PMS###|--|AMS##|
	.dc.b	(M1DT1<<4)|M1MUL	;4 $40+CH M1 |-|DT1###|MUL####|
	.dc.b	(M2DT1<<4)|M2MUL	;5 $48+CH M2
	.dc.b	(C1DT1<<4)|C1MUL	;6 $50+CH C1
	.dc.b	(C2DT1<<4)|C2MUL	;7 $58+CH C2
	.dc.b	M1TL			;8 $60+CH M1 |-|TL#######|
	.dc.b	M2TL			;9 $68+CH M2
	.dc.b	C1TL			;10 $70+CH C1
	.dc.b	C2TL			;11 $78+CH C2
	.dc.b	(M1KS<<6)|M1AR		;12 $80+CH M1 |KS##|-|AR#####|
	.dc.b	(M2KS<<6)|M2AR		;13 $88+CH M2
	.dc.b	(C1KS<<6)|C1AR		;14 $90+CH C1
	.dc.b	(C2KS<<6)|C2AR		;15 $98+CH C2
	.dc.b	(M1AMSEN<<7)|M1D1R	;16 $A0+CH M1 |AMSEN|--|D1R#####|
	.dc.b	(M2AMSEN<<7)|M2D1R	;17 $A8+CH M2
	.dc.b	(C1AMSEN<<7)|C1D1R	;18 $B0+CH C1
	.dc.b	(C2AMSEN<<7)|C2D1R	;19 $B8+CH C2
	.dc.b	(M1DT2<<6)|M1D2R	;20 $C0+CH M1 |DT2##|-|D2R#####|
	.dc.b	(M2DT2<<6)|M2D2R	;21 $C8+CH M2
	.dc.b	(C1DT2<<6)|C1D2R	;22 $D0+CH C1
	.dc.b	(C2DT2<<6)|C2D2R	;23 $D8+CH C2
	.dc.b	(M1D1L<<4)|M1RR		;24 $E0+CH M1 |D1L####|RR####|
	.dc.b	(M2D1L<<4)|M2RR		;25 $E8+CH M2
	.dc.b	(C1D1L<<4)|C1RR		;26 $F0+CH C1
	.dc.b	(C2D1L<<4)|C2RR		;27 $F8+CH C2
	.dc.b	$18,SPEED		;28,29 $18 |LFRQ########|
	.dc.b	$19,(0<<7)|AMD		;30,31 $19 |0|AMD#######|
	.dc.b	$19,(1<<7)|PMD		;32,33 $19 |1|PMD#######|
	.dc.b	$1B,WAVE		;34,35 $1B |CT1|CT2|----|WAVE##|
	.dc.b	$01,SYNC<<1		;36,37 $01 |------|LFORESET|-|
	.dc.b	$01,0<<1		;38,39 $01 |------|LFORESET|-|
	.dc.w	TM			;40,41 tm@100us
					;42
	.even
  .endif



;----------------------------------------------------------------
;	不具合
;		起動メッセージのMemory Managiment Unitのスペルが間違っている
;		https://stdkmd.net/bugsx68k/#rom_mmu
;	対策
;		Memory Management Unit
;	変更前
;		00001254 4D656D6F7279204D 	.dc.b	'Memory Managiment Unit(MMU) : On-Chip MMU',$0D,$0A,$00
;		         616E6167696D656E 
;		         7420556E6974284D 
;		         4D5529203A204F6E 
;		         2D43686970204D4D 
;		         550D0A00         
;----------------------------------------------------------------



;----------------------------------------------------------------
;	TRAP#14(エラー表示)
;		「エラーが発生しました。リセットしてください。」だけでは分からないエラーの内容を表示する
;	変更前
;		00FF1458 41FAF364		lea.l	$00FF07BE(pc),a0	;TRAP#14(エラー表示)
;		00FF145C 21C800B8		move.l	a0,OFFSET_TRAP_14.w
;----------------------------------------------------------------
	PATCH_DATA	trap14,$00FF1458,$00FF145F,$41FAF364
	move.l	#trap14,OFFSET_TRAP_14.w
	PATCH_TEXT
;<d7.w:エラー番号
;	$00xx	未定義例外
;	$01xx	未定義IOCSコール
;	$301F	NMI
;	$7009	プリンタオフライン
;<a6.l:SRの位置。$7009のときセットされない
trap14:
;文字列バッファを確保する
	lea.l	-128(sp),sp		;文字列バッファ
;エラーメッセージを作る
;	Bus error on writing to $XXXXXXXX at $XXXXXXXX
;	Bus error on reading from $XXXXXXXX at $XXXXXXXX
;	Address error on writing to $XXXXXXXX at $XXXXXXXX
;	Address error on reading from $XXXXXXXX at $XXXXXXXX
;	Error $XXXX at $XXXXXXXX
	movea.l	sp,a0			;文字列バッファ
	bsr	start_proportional
	move.b	#' ',(a0)+
	move.b	#' ',(a0)+
	moveq.l	#-2,d0
	and.w	d7,d0
	subq.w	#2,d0
	if	eq			;バスエラーとアドレスエラー
		move.b	BIOS_MPU_TYPE.w,d0
		if	eq			;68000
		;	MC68000UM 6-17
		;	0.w
		;	  15-5 4   3   2-0
		;	  X    R/W I/N FC
		;	  R/W  0=Write,1=Read
		;	  I/N  0=Instruction,1=Not
		;	2.l  ACCESS ADDRESS
		;	6.w  INSTRUCTION REGISTER
		;	8.w  STATUS REGISTER
		;	10.l  PROGRAM COUNTER
			moveq.l	#$10,d0
			and.b	1-8(a6),d0		;0=Write,その他=Read
			movea.l	2-8(a6),a2		;Address
		elif	<subq.b #1,d0>,eq	;68010
		;	MC68000UM 6-18
		;	0.w  STATUS REGISTER
		;	2.l  PROGRAM COUNTER
		;	6.w  FORMAT $A VECTOR OFFSET
		;	8.w  SPECIAL STATUS WORD
		;	  15 14 13 12 11 10 9  8  7-3 2-0
		;	  RR X  IF DF RM HB BY RW X   FC
		;	  RW  0=Write,1=Read
		;	10.l  FAULT ADDRESS
		;	14.w  UNUSED, RESERVED
		;	16.w  DATA OUTPUT BUFFER
		;	18.w  UNUSED, RESERVED
		;	20.w  DATA INPUT BUFFER
		;	22.w  UNUSED, RESERVED
		;	24.w  INSTRUCTION INPUT BUFFER
		;	26.w  VERSION NUMBER INTERNAL INFORMATION, 16 WORDS
		;	58バイト。実際に書き込まれるのは52バイト
			moveq.l	#$01,d0
			and.b	8(a6),d0		;0=Write,その他=Read
			movea.l	10(a6),a2		;Address
		elif	<subq.b #4-1,d0>,lo	;68020/68030
		;68020/68030
		;	MC68020UM 6-23/MC68030UM 8-28
		;	10.w  SPECIAL STATUS WORD
		;	  15 14 13 12 11-9 8  7  6  5-4  3 2-0
		;	  FC FB RC RB X    DF RM RW SIZE X FC
		;	  RW  0=Write,1=Read
		;	16.l  DATA CYCLE FAULT ADDRESS
			moveq.l	#$40,d0
			and.b	11(a6),d0		;0=Write,その他=Read
			movea.l	16(a6),a2		;Address
		elif	eq			;68040
		;	MC68040UM 8-24
		;	12.w  SPECIAL STATUS WORD
		;	  15 14 13 12 11 10  9  8  7 6-5  4-3 2-0
		;	  CP CU CT CM MA ATC LK RW X SIZE TT  TM
		;	  RW  0=Write,1=Read
		;	20.l  FAULT ADDRESS
			moveq.l	#$01,d0
			and.b	12(a6),d0		;0=Write,その他=Read
			movea.l	20(a6),a2		;Address
		elif	<cmp.w #2,d7>,eq	;68060のバスエラー
		;	MC68060UM 8-21
		;	8.l  FAULT ADDRESS
		;	12.l  FAULT STATUS LONG WORD
		;	  31-28 27 26 25 24-23 22-21 20-19 18-16 15 14  13  12  11  10 9  8  7  6   5  4  3   2   1 0
		;	  X     MA X  LK RW    SIZE  TT    TM    IO PBE SBE PTA PTB IL PF SP WP TWE RE WE TTR BPE X SEE
		;	  RW  00=Undefined,Reserved,01=Write,10=Read,11=Read-Modify-Write
		;	  SIZE  00=Byte,01=Word,10=Long,11=Double Precision or MOVE16
			moveq.l	#$01,d0
			and.b	12(a6),d0		;0=Write,その他=Read
			if	ne			;Read or Read-Modify-Write
				ifand	<tst.b 13(a6)>,mi,<btst.b #4,15(a6)>,ne	;Read-Modify-Write and Bus Error on Write
					moveq.l	#0,d0		;0=Write,その他=Read
				endif
			endif
			movea.l	8(a6),a2		;Address
		else				;68060のアドレスエラー
		;	MC68060UM 8-7
		;	8.l  FAULT ADDRESS
			moveq.l	#1,d0			;Read
			movea.l	8(a6),a2		;Address
			addq.l	#1,a2			;bit0が0になっているので1に戻す
		endif
		lea.l	101f(pc),a1		;'Bus'
		subq.w	#2,d7
		if	ne
			lea.l	102f-101f(a1),a1	;'Address'
		endif
		bsr	strcpy
		lea.l	103f(pc),a1		;' error on '
		bsr	strcpy
		lea.l	104f(pc),a1		;'writing to $'
		if	<tst.b d0>,ne
			lea.l	105f-104f(a1),a1	;'reading from $'
		endif
		bsr	strcpy
		move.l	a2,d0
		bsr	h8tos			;XXXXXXXX
	elif	<cmp.w #12,d7>,lo		;4～11
		PATCH_lea	sysstat,trap14_message,a1
		move.w	d7,d0
		add.w	d0,d0
		adda.w	-2*4(a1,d0.w),a1
		bsr	strcpy
	elif	<cmp.w #$301F,d7>,eq		;NMI
		lea.l	106f(pc),a1		;'NMI'
		bsr	strcpy
	else				;その他未定義例外と未定義IOCSコール
		lea.l	107f(pc),a1		;'Error $'
		bsr	strcpy
		move.w	d7,d0
		bsr	h4tos			;XXXX
	endif
	if	<cmp.w #$7009,d7>,ne
		lea.l	108f(pc),a1		;' at $'
		bsr	strcpy
		move.l	2(a6),d0		;PC
		bsr	h8tos
	endif
	bsr	end_proportional
	bsr	crlf
;エラーメッセージを表示する
	movea.l	sp,a1
	bsr	iocs_21_B_PRINT
;文字列バッファを開放する
	lea.l	128(sp),sp
;常に中止
;	キー入力を待たず直ちにリセット待ちにする
10:	IOCS	_ABORTJOB
	goto	10b			;無限ループ

101:	.dc.b	'Bus',0
102:	.dc.b	'Address',0
103:	.dc.b	' error on ',0
104:	.dc.b	'writing to $',0
105:	.dc.b	'reading from $',0
106:	.dc.b	'NMI',0
107:	.dc.b	'Error $',0
108:	.dc.b	' at $',0
	.even



;----------------------------------------------------------------
;	IOI HDCINTベクタの設定
;		このまま。IPLROM 1.2とIPLROM 1.3で同じ。SPCINTとは関係ない
;	変更前
;		000017FC 047E             	.dc.w	~FF1C76-~FF17F8		;[$0188.w].l:[$0062]:HDCINT ハードディスクのステータス割り込み
;		00001C76 4E73             	rte
;----------------------------------------------------------------



;----------------------------------------------------------------
;	DMAC 1の初期化
;		このまま。IPLROM 1.2とIPLROM 1.3で同じ
;	変更前
;		0000180A 4480             	.dc.b	$00E84044-$00E84000,$80	;[$00E84044].b:DMA 1 DCR(XRM##|DTYP##|DPS|-|PCL##)
;		0000180C 4604             	.dc.b	$00E84046-$00E84000,$04	;[$00E84046].b:DMA 1 SCR(----|MAC##|DAC##)
;		0000180E 6905             	.dc.b	$00E84069-$00E84000,$05	;[$00E84069].b:DMA 1 MFC
;		00001810 6D02             	.dc.b	$00E8406D-$00E84000,$02	;[$00E8406D].b:DMA 1 CPR
;		00001812 7105             	.dc.b	$00E84071-$00E84000,$05	;[$00E84071].b:DMA 1 DFC
;----------------------------------------------------------------



;----------------------------------------------------------------
;	DMAC 1 DARの初期化
;		SASI内蔵機のときHDC_DATAを設定する
;		SCSI内蔵機のとき削除。IPLROM 1.3は無意味な値を設定している
;	変更前
;		00001788 237A7BB2_0000933C	move.l	spc_base_handle(pc),DMAC_DAR+DMAC_1_BASE-DMAC_0_BASE(a1)
;		         0054             
;----------------------------------------------------------------
	PATCH_DATA	p1788,$00FF1788,$00FF1788+5,$237A7BB2
	jsr	p1788
	PATCH_TEXT
p1788:
	if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI内蔵機
		move.l	#HDC_DATA,DMAC_DAR+DMAC_1_BASE-DMAC_0_BASE(a1)
	else				;SCSI内蔵機
		clr.l	DMAC_DAR+DMAC_1_BASE-DMAC_0_BASE(a1)
	endif
	rts



;----------------------------------------------------------------
;	SASIポートまたはSCSIポートの初期化
;		SASI内蔵機のときSASIポートを初期化する
;		SCSI内蔵機で拡張SCSIがないときSCSIINROMのscsi_init_routineを呼び出す
;	変更前
;		000017D6 70F5             	moveq.l	#_SCSIDRV,d0
;		000017D8 7200             	moveq.l	#_S_RESET,d1
;		000017DA 4E4F             	trap	#15
;----------------------------------------------------------------
	PATCH_DATA	p17D6,$00FF17D6,$00FF17D6+5,$70F57200
	jsr	p17d6
	PATCH_TEXT
p17d6:
	push	d0-d1/a0-a1
	if	<tst.b BIOS_BUILTIN_SCSI.w>,eq	;SASI内蔵機
	;SASIポートを初期化する
		do
			break	<tst.l BIOS_ALARM_MINUTE.l>,ne
		while	<cmpi.w #6000-100*1,BIOS_TC_MINUTE_COUNTER.l>,cc	;起動後1秒まで待つ
		move.w	#$8000,d1
		do
			suba.l	a1,a1
			IOCS	_B_DSKINI
			if	<cmpi.w #100*30,BIOS_TC_MINUTE_COUNTER.l>,cc	;起動後30秒までは
				redo	<cmp.b #$04,d0>,eq	;$04でリトライ
			endif
			break	<tst.b d0>,ne
			add.w	#$0100,d1
		while	<cmp.w #$9000,d1>,ne
	else				;SCSI内蔵機
		lea.l	$00EA0044,a0		;'SCSIEX'
		bsr	read_long
		if	<cmp.l #'SCSI',d0>,eq
			bsr	read_word
			goto	<cmp.w #'EX',d0>,eq,@f	;拡張SCSIがある
		endif
	;拡張SCSIがない
	;SCSIINROMのscsi_init_routineを呼び出す
		movea.l	$00FC0020,a1		;scsi_init_handle
		jsr	(a1)
	@@:
	endif
	pop
	rts



;----------------------------------------------------------------
;	不具合
;		電卓を使うと実行中のプログラムが誤動作することがある
;		https://stdkmd.net/bugsx68k/#rom_dentakud3
;	変更前
;		00FF3BFC 48E76000               movem.l	d1-d2,-(sp)
;		00FF3C00
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_1st,$00FF3BFC,$00FF3BFF,$48E76000
	movem.l	d1-d3,-(sp)
;----------------------------------------------------------------
;	変更前
;		00FF3C16 4CDF0006               movem.l	(sp)+,d1-d2
;		00FF3C1A
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_2nd,$00FF3C16,$00FF3C19,$4CDF0006
	movem.l	(sp)+,d1-d3
;----------------------------------------------------------------
;	変更前
;		00FF3C1C 4CDF0006               movem.l	(sp)+,d1-d2
;		00FF3C20
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_3rd,$00FF3C1C,$00FF3C1F,$4CDF0006
	movem.l	(sp)+,d1-d3
;----------------------------------------------------------------
;	変更前
;		00FF3C5A 48E76000               movem.l	d1-d2,-(sp)
;		00FF3C5E
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_4th,$00FF3C5A,$00FF3C5D,$48E76000
	movem.l	d1-d3,-(sp)
;----------------------------------------------------------------
;	変更前
;		00FF3C76 4CDF0006               movem.l	(sp)+,d1-d2
;		00FF3C7A
;----------------------------------------------------------------
	PATCH_DATA	dentaku_d3_5th,$00FF3C76,$00FF3C79,$4CDF0006
	movem.l	(sp)+,d1-d3



;----------------------------------------------------------------
;	不具合
;		カーソルが画面の最下行にあると電卓が画面外に表示される
;		https://stdkmd.net/bugsx68k/#rom_dentaku64
;	対策
;		電卓の表示位置を決める処理にY座標を調整するコードを追加する
;		直前にある電卓OFFルーチンを詰めてできた隙間にY座標を調整するコードを押し込んでそれを呼び出す
;	変更前
;		00FF4444 3F00                   move.w	d0,-(sp)
;		00FF4446 3F3C0010               move.w	#$0010,-(sp)
;		00FF444A 3F3C00B8               move.w	#$00B8,-(sp)
;		00FF444E 3F380BFE               move.w	BIOS_DEN_Y.w,-(sp)	;電卓表示Y座標
;		00FF4452 3F380BFC               move.w	BIOS_DEN_X.w,-(sp)	;電卓表示X座標
;		00FF4456 3F3C0002               move.w	#$0002,-(sp)
;		00FF445A 61002368               bsr.w	$00FF67C4		;_TXFILL実行
;		00FF445E 4FEF000C               lea.l	$000C(sp),sp
;		00FF4462 4267                   clr.w	-(sp)
;		00FF4464 3F3C0010               move.w	#$0010,-(sp)
;		00FF4468 3F3C00B8               move.w	#$00B8,-(sp)
;		00FF446C 3F380BFE               move.w	BIOS_DEN_Y.w,-(sp)	;電卓表示Y座標
;		00FF4470 3F380BFC               move.w	BIOS_DEN_X.w,-(sp)	;電卓表示X座標
;		00FF4474 3F3C0003               move.w	#$0003,-(sp)
;		00FF4478 6100234A               bsr.w	$00FF67C4		;_TXFILL実行
;		00FF447C 4FEF000C               lea.l	$000C(sp),sp
;		00FF4480 301F                   move.w	(sp)+,d0
;		00FF4482 6704                   beq.s	$00FF4488
;		00FF4484 610065D6               bsr.w	$00FFAA5C		;IOCS _MS_CURON
;		00FF4488 4CDF7FFE               movem.l	(sp)+,d1-d7/a0-a6
;		00FF448C 4E75                   rts
;		00FF448E
;----------------------------------------------------------------
	PATCH_DATA	dentaku64_1st,$00FF4444,$00FF448D,$3F003F3C
;電卓OFF
	move.w	d0,-(sp)
	move.l	#184<<16|16,-(sp)
	move.l	BIOS_DEN_X.w,-(sp)	;電卓表示X座標。BIOS_DEN_Y 電卓表示Y座標
	move.w	#2,-(sp)
	bsr	($00FF67C4)PATCH_ZL	;_TXFILL実行
	clr.w	10(sp)
	addq.w	#1,(sp)			;3
	bsr	($00FF67C4)PATCH_ZL	;_TXFILL実行
	lea.l	12(sp),sp
	move.w	(sp)+,d0
	if	ne
		bsr	($00FFAA5C)PATCH_ZL	;IOCS _MS_CURON
	endif
	movem.l	(sp)+,d1-d7/a0-a6
	rts

dentaku64:
	addq.w	#1,d1			;カーソルの次の行
	ifand	<cmp.w #32,d1>,hs,<cmp.w BIOS_CONSOLE_BOTTOM.w,d1>,hi	;32以上かつコンソールの範囲外
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コンソールの最下行
		if	ne			;コンソールが2行以上ある
			subq.w	#1,d1			;コンソールの下から2番目の行
		endif
	endif
	rts
;----------------------------------------------------------------
;	変更前
;		00FF44A6 5241                   addq.w	#1,d1			;カーソルの次の行
;		00FF44A8 E941                   asl.w	#4,d1
;----------------------------------------------------------------
	PATCH_DATA	dentaku64_2nd,$00FF44A6,$00FF44A7,$5241E941
	PATCH_bsr	dentaku64_1st,dentaku64



;----------------------------------------------------------------
;	不具合
;		ソフトキーボードの↑キーの袋文字が閉じていない
;		https://stdkmd.net/bugsx68k/#rom_softkeyboard
;	変更前
;		00005AA8 2B80             	.dc.b	__M_M_MM,M_______
;----------------------------------------------------------------
	PATCH_DATA	softkeyboard,$00FF5AA8,$00FF5AA9,$2B800A00
	.dc.b	__MMM_MM,M_______



;----------------------------------------------------------------
;	不具合
;		_DEFCHRでフォントサイズに0が指定されたとき8に読み替える処理が文字コードも0のときしか機能していない
;		_DEFCHRでフォントサイズに6を指定できない
;		_DEFCHRで_FNTADRがフォントパターンをBIOS_FNTADR_BUFFER.wに作成して返したときそこに上書きしても保存されないのにエラーにならない
;		_DEFCHRでフォントアドレスがX68030のハイメモリや060turboのローカルメモリを指しているとROMと誤認してエラーになる
;	変更前
;		00FF6ADA 70FF                   moveq.l	#$FF,d0
;		00FF6ADC 48E76040               movem.l	d1-d2/a1,-(sp)
;		00FF6AE0 2401                   move.l	d1,d2
;		00FF6AE2 4842                   swap.w	d2
;		00FF6AE4 6604                   bne.s	$00FF6AEA
;		00FF6AE6 343C0008               move.w	#$0008,d2
;		00FF6AEA B47C0006               cmp.w	#$0006,d2
;		00FF6AEE 6722                   beq.s	$00FF6B12
;		00FF6AF0 20780458               movea.l	$0458.w,a0		;[$0458.w].l:[$0116]_FNTADR
;		00FF6AF4 4E90                   jsr	(a0)
;		00FF6AF6 2040                   movea.l	d0,a0
;		00FF6AF8 70FF                   moveq.l	#$FF,d0
;		00FF6AFA B1FC00F00000           cmpa.l	#$00F00000,a0		;ROMならキャンセル
;		00FF6B00 6410                   bcc.s	$00FF6B12
;		00FF6B02 5242                   addq.w	#1,d2
;		00FF6B04 5241                   addq.w	#1,d1
;		00FF6B06 C4C1                   mulu.w	d1,d2
;		00FF6B08 5342                   subq.w	#1,d2
;		00FF6B0A 10D9                   move.b	(a1)+,(a0)+
;		00FF6B0C 51CAFFFC               dbra.w	d2,$00FF6B0A
;		00FF6B10 4280                   clr.l	d0
;		00FF6B12 4CDF0206               movem.l	(sp)+,d1-d2/a1
;		00FF6B16 4E75                   rts
;		00FF6B18
;----------------------------------------------------------------
	PATCH_DATA	defchr,$00FF6ADA,$00FF6B17,$70FF48E7
;----------------------------------------------------------------
;IOCSコール$0F _DEFCHR フォントパターン設定
;<d1.l:フォントサイズ<<16|文字コード
;	フォントサイズ
;		0,8	8x16,16x16
;		12,24	12x24,24x24
;<a1.l:フォントパターンの先頭アドレス
;>d0.l:0=正常終了,-1=エラー
iocs_0F_DEFCHR:
	push	d1/d2/a0/a1
	move.l	d1,d2
	swap.w	d2
	movea.l	4*($100+_FNTADR).w,a0	;IOCSコール$16 _FNTADR フォントアドレスの取得
	jsr	(a0)
;<d0.l:フォントアドレス
;<d1.w:横方向のバイト数-1
;<d2.w:縦方向のドット数-1
	movea.l	d0,a0			;フォントアドレス
	moveq.l	#-1,d0
;フォントアドレスがROMを指しているときは上書きできないので失敗
	ifor	<cmpa.l #$00F00000,a0>,lo,<cmpa.l #$01000000,a0>,hs
	;フォントアドレスがBIOS_FNTADR_BUFFER.wを指しているときは上書きしても保存されないので失敗
		if	<cmpa.w #BIOS_FNTADR_BUFFER.w,a0>,ne
		;フォントパターンをコピーする
			addq.w	#1,d1
			addq.w	#1,d2
			mulu.w	d2,d1
			subq.w	#1,d1
			for	d1
				move.b	(a1)+,(a0)+
			next
			moveq.l	#0,d0
		endif
	endif
	pop
	rts



  .if REMOVE_CRTMOD_G_CLR_ON=0

;----------------------------------------------------------------
;	_CRTMOD
;	変更前
;		00006B18 48E77060         	movem.l	d1-d3/a1-a2,-(sp)
;			:
;		00006B8C                  iocs_10_CRTMOD:
;		00006B8C 41F900E80028     	lea.l	CRTC_MODE_RESOLUTION,a0	;メモリモードと解像度
;			:
;		00007042 0400028001E00001 	.dc.w	1024,640,480,1
;----------------------------------------------------------------
	PATCH_DATA	crtmod,$00FF6B8C,$00FF6B91,$41F900E8
	jmp	iocs_10_CRTMOD
	PATCH_TEXT
;----------------------------------------------------------------
;IOCSコール$10 _CRTMOD 画面モードの取得と設定
;<d1.w:設定後の画面モード
;	$01xx	初期化しない
;	$16FF	バージョン確認。$16_xxxxxx(CRT向け)または$96_xxxxxx(LCD向け)を返す
;	$43xx	CRT向け。SRAMに保存する。$43FFはSRAMの変更のみ
;	$4Cxx	LCD向け。SRAMに保存する。$4CFFはSRAMの変更のみ
;	$56FF	バージョン確認。$16_xxxxxxを返す
;	$FFFF	取得のみ
;>d0.l:設定前の画面モード。バージョン確認は$16_xxxxxxまたは$96_xxxxxxを返す
;----------------------------------------------------------------
;	画面モード
;
;	画面モード	解像度	画面サイズ	実画面サイズ	色数	ページ数
;	0		高	512x512		1024x1024	16	1
;	1		低	512x512		1024x1024	16	1
;	2		高	256x256		1024x1024	16	1
;	3		低	256x256		1024x1024	16	1
;	4		高	512x512		512x512		16	4
;	5		低	512x512		512x512		16	4
;	6		高	256x256		512x512		16	4
;	7		低	256x256		512x512		16	4
;	8		高	512x512		512x512		256	2
;	9		低	512x512		512x512		256	2
;	10		高	256x256		512x512		256	2
;	11		低	256x256		512x512		256	2
;	12		高	512x512		512x512		65536	1
;	13		低	512x512		512x512		65536	1
;	14		高	256x256		512x512		65536	1
;	15		低	256x256		512x512		65536	1
;	16		高	768x512		1024x1024	16	1
;	17		中	1024x424	1024x1024	16	1
;	18		中	1024x848	1024x1024	16	1
;	19		VGA	640x480		1024x1024	16	1
;	20		高	768x512		512x512		256	2
;	21		中	1024x424	512x512		256	2
;	22		中	1024x848	512x512		256	2
;	23		VGA	640x480		512x512		256	2
;	24		高	768x512		512x512		65536	1
;	25		中	1024x424	512x512		65536	1
;	26		中	1024x848	512x512		65536	1
;	27		VGA	640x480		512x512		65536	1
;	$100+(0～27)	初期化しない
;	-1	取得のみ
;
;	以下は拡張
;	28		高	384x256		1024x1024	16	1
;	29		高	384x256		512x512		16	4
;	30		高	384x256		512x512		256	2
;	31		高	384x256		512x512		65536	1
;	32		高	512x512(正方形)	1024x1024	16	1
;	33		高	512x512(正方形)	512x512		16	4
;	34		高	512x512(正方形)	512x512		256	2
;	35		高	512x512(正方形)	512x512		65536	1
;	36		高	256x256(正方形)	1024x1024	16	1
;	37		高	256x256(正方形)	512x512		16	4
;	38		高	256x256(正方形)	512x512		256	2
;	39		高	256x256(正方形)	512x512		65536	1
;	40		高	512x256		1024x1024	16	1
;	41		高	512x256		512x512		16	4
;	42		高	512x256		512x512		256	2
;	43		高	512x256		512x512		65536	1
;	44		高	512x256(※)	1024x1024	16	1
;	45		高	512x256(※)	512x512		16	4
;	46		高	512x256(※)	512x512		256	2
;	47		高	512x256(※)	512x512		65536	1
;	※スプライトは512x512
;
;----------------------------------------------------------------
;	いろいろ
;
;	CRT向けとLCD向け
;		各画面モードの同期周波数をそれぞれCRT向けとLCD向けに分ける
;		SRAM_XEIJのSRAM_XEIJ_LCD_BITが0のときCRT向け、1のときLCD向けの同期周波数で出力する
;
;	画面モード17
;		水平24.699kHz、垂直53.116Hz、1024x424、実画面1024x1024、16色
;		X68000初代からあるが未公開
;		LCD向けのときは画面モード16の上下を削る
;
;	画面モード18
;		水平24.699kHz、垂直53.116Hz、1024x848(インターレース)、実画面1024x1024、16色
;		X68000初代からあるが未公開
;		LCD向けのときは画面モード16の上下を削ってインターレースにする
;
;	画面モード19(VGAモード)
;		水平31.469kHz、垂直59.940Hz、640x480、実画面1024x1024、16色
;		X68000 Compactで追加された
;		CRT向けのときは画面モード16の周囲を削る
;		LCD向けのときはそのまま
;
;	画面モード20～23
;		画面モード16～19を実画面512x512、256色に変更したもの
;		X68030で追加された。未公開
;
;	画面モード24～27
;		画面モード16～19を実画面512x512、65536色に変更したもの
;		X68030で追加された。未公開
;
;	グラフィックパレットのバグ(IPLROM 1.0～1.3)
;		_CRTMODが指定された画面モードと異なる色数でグラフィックパレットを初期化する
;			https://stdkmd.net/bugsx68k/#rom_crtmod_gpalet
;		256x256は16色、512x512は256色、それ以外は65536色になる
;
;	画面モード20～27のバグ(IPLROM 1.3)
;		画面モードに20～27が指定されたとき画面モードを16～19にしてから256色または65536色に変更しているが、
;		このときBIOSワークエリアの画面モードを16～19のまま放置している
;		続けて_G_CLR_ONを呼び出すと画面モードが16～19なので16色に戻ってしまう
;
;	クリッピングエリアのバグ(IPLROM 1.3)
;		_CRTMODで画面モードを22または26にするとクリッピングエリアが512x848になる
;
;	VGAオシレータの問題
;		初代～XVIにはVGAオシレータがないのでVGAモードが正しい同期周波数で出力されない
;		VGAオシレータがある場合
;			(50.350MHz/2)/(8*100)=31.469kHz
;			(50.350MHz/2)/(8*100*525)=59.940Hz
;		VGAオシレータがない場合
;			(69.552MHz/3)/(8*100)=28.980kHz
;			(69.552MHz/3)/(8*100*525)=55.200Hz
;		大きく外れるわけではないのでマルチスキャンモニタは追従できるが気持ち悪い
;
;	VGAオシレータの有無の判別
;		VGAモードの垂直周期はVGAオシレータがあるとき16.683ms、ないとき18.116ms
;		垂直同期割り込みの間にTimer-Cが1周10msと7.5ms進んだかどうかでVGAオシレータの有無を判別できるはず
;		後で試す？
;
;----------------------------------------------------------------
;	同期信号とCRTC設定値の関係
;
;	HT	水平周期カラム数
;	HS	水平同期パルスカラム数
;	HB	水平バックポーチカラム数
;	HD	水平映像期間カラム数
;	HF	水平フロントポーチカラム数
;	VT	垂直周期ラスタ数
;	VS	垂直同期パルスラスタ数
;	VB	垂直バックポーチラスタ数
;	VD	垂直映像期間ラスタ数
;	VF	垂直フロントポーチラスタ数
;
;	R00	HT-1=HS+HB+HD+HF-1	水平フロントポーチ終了カラム
;	R01	HS-1			水平同期パルス終了カラム
;	R02	HS+HB-5			水平バックポーチ終了カラム-4
;	R03	HS+HB+HD-5		水平映像期間終了カラム-4
;	R04	VT-1=VS+VB+VD+VF-1	垂直フロントポーチ終了ラスタ
;	R05	VS-1			垂直同期パルス終了ラスタ
;	R06	VS+VB-1			垂直バックポーチ終了ラスタ
;	R07	VS+VB+VD-1		垂直映像期間終了ラスタ
;
;----------------------------------------------------------------
;	オシレータと分周比とR20LとHRLの関係
;
;	OSC/DIV	R20L	HRL
;	38/8	%0**00	*
;	38/4	%0**01	*
;	38/8	%0**1*	*
;	69/6	%1**00	0
;	69/8	%1**00	1
;	69/3	%1**01	0
;	69/4	%1**01	1
;	69/2	%1**10	*	スプライト不可
;	50/2	%1**11	*	スプライト不可。Compactから
;
;----------------------------------------------------------------
;	CRTC設定値(CRT向け)
;
;	CRT 0/4/8/12: 512x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   91   9  17  81      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   92  10  12  64   6  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*92)=31.500kHz (69.552MHz/3)/(8*92*568)=55.458Hz
;	  64/92=0.696 512/568=0.901 (0.696/0.901)/(512/512)=0.772
;	  31k
;
;	CRT 1/5/9/13: 512x512 15.980kHz 61.463Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %00101   0   75   3   5  69      259   2  16 256     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 38.864   4   76   4   6  64   2  260   3  14 240   3 |
;	  +------------------------------------------------------+
;	  (38.864MHz/4)/(8*76)=15.980kHz (38.864MHz/4)/(8*76*260)=61.463Hz
;	  64/76=0.842 240/260=0.923 (0.842/0.923)/(512/512)=0.912
;	  15k インターレース
;
;	CRT 2/6/10/14: 256x256 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   45   4   6  38      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   46   5   6  32   3  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*46)=31.500kHz (69.552MHz/6)/(8*46*568)=55.458Hz
;	  32/46=0.696 512/568=0.901 (0.696/0.901)/(256/256)=0.772
;	  31k ラスタ2度読み
;
;	CRT 3/7/11/15: 256x256 15.980kHz 61.463Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %00000   0   37   1   0  32      259   2  16 256     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 38.864   8   38   2   3  32   1  260   3  14 240   3 |
;	  +------------------------------------------------------+
;	  (38.864MHz/8)/(8*38)=15.980kHz (38.864MHz/8)/(8*38*260)=61.463Hz
;	  32/38=0.842 240/260=0.923 (0.842/0.923)/(256/256)=0.912
;	  15k
;
;	CRT 16/20/24: 768x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  28 124      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  18  96   9  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  96/138=0.696 512/568=0.901 (0.696/0.901)/(768/512)=0.514
;	  31k
;
;	CRT 17/21/25: 1024x424 24.699kHz 53.116Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  175  15  31 159      464   7  32 456     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  176  16  20 128  12  465   8  25 424   8 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*176)=24.699kHz (69.552MHz/2)/(8*176*465)=53.116Hz
;	  128/176=0.727 424/465=0.912 (0.727/0.912)/(1024/424)=0.330
;	  24k
;
;	CRT 18/22/26: 1024x848 24.699kHz 53.116Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %11010   0  175  15  31 159      464   7  32 456     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  176  16  20 128  12  465   8  25 424   8 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*176)=24.699kHz (69.552MHz/2)/(8*176*465)=53.116Hz
;	  128/176=0.727 424/465=0.912 (0.727/0.912)/(1024/848)=0.661
;	  24k インターレース
;
;	CRT 19/23/27: 640x480 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  36 116      567   5  56 536     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  26  80  17  568   6  51 480  31 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  80/138=0.580 480/568=0.845 (0.580/0.845)/(640/480)=0.514
;	  31k
;
;	CRT 28/29/30/31: 384x256 31.963kHz 56.273Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  11  59      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7   9  48   4  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*568)=56.273Hz
;	  48/68=0.706 512/568=0.901 (0.706/0.901)/(384/256)=0.522
;	  31k ラスタ2度読み
;
;	CRT 32/33/34/35: 512x512 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  137  14  44 108      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  138  15  34  64  25  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*138)=31.500kHz (69.552MHz/2)/(8*138*568)=55.458Hz
;	  64/138=0.464 512/568=0.901 (0.464/0.901)/(512/512)=0.514
;	  31k
;
;	CRT 36/37/38/39: 256x256 31.963kHz 56.273Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  19  51      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7  17  32  12  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*568)=56.273Hz
;	  32/68=0.471 512/568=0.901 (0.471/0.901)/(256/256)=0.522
;	  31k ラスタ2度読み
;
;	CRT 40/41/42/43/44/45/46/47: 512x256 31.500kHz 55.458Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   0   91   9  17  81      567   5  40 552     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   92  10  12  64   6  568   6  35 512  15 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*92)=31.500kHz (69.552MHz/3)/(8*92*568)=55.458Hz
;	  64/92=0.696 512/568=0.901 (0.696/0.901)/(512/256)=0.386
;	  31k
;
;----------------------------------------------------------------
;	CRTC設定値(LCD向け)
;
;	LCD 0/4/8/12: 512x512 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   81   5  11  75      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 512/625=0.819 (0.780/0.819)/(512/512)=0.953
;	  SVGA
;
;	LCD 1/5/9/13: 512x512 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10101   0   81   5  11  75      624   1  83 563     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  82 480  61 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 480/625=0.768 (0.780/0.768)/(512/512)=1.016
;	  SVGA
;
;	LCD 2/6/10/14: 256x256 34.500kHz 55.200Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   41   2   3  35      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   42   3   5  32   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*42)=34.500kHz (69.552MHz/6)/(8*42*625)=55.200Hz
;	  32/42=0.762 512/625=0.819 (0.762/0.819)/(256/256)=0.930
;	  SVGA ラスタ2度読み
;
;	LCD 3/7/11/15: 256x256 34.500kHz 55.200Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10000   0   41   2   3  35      624   1  83 563     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   6   42   3   5  32   2  625   2  82 480  61 |
;	  +------------------------------------------------------+
;	  (69.552MHz/6)/(8*42)=34.500kHz (69.552MHz/6)/(8*42*625)=55.200Hz
;	  32/42=0.762 480/625=0.768 (0.762/0.768)/(256/256)=0.992
;	  SVGA ラスタ2度読み
;
;	LCD 16/20/24: 768x512 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  19 115      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 512/625=0.819 (0.774/0.819)/(768/512)=0.630
;	  SVGA
;
;	LCD 17/21/25: 768x600 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  19 115      624   1  23 623     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  22 600   1 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 600/625=0.960 (0.774/0.960)/(768/600)=0.630
;	  SVGA
;
;	LCD 18/22/26: 768x1024 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %11010   0  123   8  19 115      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  15  96   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  96/124=0.774 512/625=0.819 (0.774/0.819)/(768/1024)=1.260
;	  SVGA インターレース
;
;	LCD 19/23/27: 640x480 31.469kHz 59.940Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10111   0   99  11  13  93      524   1  34 514     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 50.350   2  100  12   6  80   2  525   2  33 480  10 |
;	  +------------------------------------------------------+
;	  (50.350MHz/2)/(8*100)=31.469kHz (50.350MHz/2)/(8*100*525)=59.940Hz
;	  80/100=0.800 480/525=0.914 (0.800/0.914)/(640/480)=0.656
;	  VGA
;
;	LCD 28/29/30/31: 384x256 31.963kHz 51.141Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  11  59      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7   9  48   4  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*625)=51.141Hz
;	  48/68=0.706 512/625=0.819 (0.706/0.819)/(384/256)=0.574
;	  ラスタ2度読み
;
;	LCD 32/33/34/35: 512x512 35.056kHz 56.090Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10110   0  123   8  35  99      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   2  124   9  31  64  20  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/2)/(8*124)=35.056kHz (69.552MHz/2)/(8*124*625)=56.090Hz
;	  64/124=0.516 512/625=0.819 (0.516/0.819)/(512/512)=0.630
;	  SVGA
;
;	LCD 36/37/38/39: 256x256 31.963kHz 51.141Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   1   67   6  19  51      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   4   68   7  17  32  12  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/4)/(8*68)=31.963kHz (69.552MHz/4)/(8*68*625)=51.141Hz
;	  32/68=0.471 512/625=0.819 (0.471/0.819)/(256/256)=0.574
;	  ラスタ2度読み
;
;	LCD 40/41/42/43/44/45/46/47: 512x256 35.341kHz 56.546Hz
;	  +------------------------------------------------------+
;	  |   R20L HRL  R00 R01 R02 R03      R04 R05 R06 R07     |
;	  | %10001   0   81   5  11  75      624   1  67 579     |
;	  +------------------------------------------------------+
;	  |    OSC DIV   HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 69.552   3   82   6  10  64   2  625   2  66 512  45 |
;	  +------------------------------------------------------+
;	  (69.552MHz/3)/(8*82)=35.341kHz (69.552MHz/3)/(8*82*625)=56.546Hz
;	  64/82=0.780 512/625=0.819 (0.780/0.819)/(512/256)=0.476
;	  SVGA
;
;	【参考】VGA: 640x480 31.469kHz 59.940Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 25.175      100  12   6  80   2  525   2  33 480  10 |
;	  +------------------------------------------------------+
;	  25.175MHz/(8*100)=31.469kHz (25.175MHz/1)/(8*100*525)=59.940Hz
;	  80/100=0.800 480/525=0.914 (0.800/0.914)/(640/480)=0.656
;
;	【参考】SVGA: 800x600 35.156kHz 56.250Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 36.000      128   9  16 100   3  625   2  22 600   1 |
;	  +------------------------------------------------------+
;	  36.000MHz/(8*128)=35.156kHz (36.000MHz/1)/(8*128*625)=56.250Hz
;	  100/128=0.781 600/625=0.960 (0.781/0.960)/(800/600)=0.610
;
;	【参考】SVGA: 800x600 37.879kHz 60.317Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 40.000      132  16  11 100   5  628   4  23 600   1 |
;	  +------------------------------------------------------+
;	  40.000MHz/(8*132)=37.879kHz (40.000MHz/1)/(8*132*628)=60.317Hz
;	  100/132=0.758 600/628=0.955 (0.758/0.955)/(800/600)=0.595
;
;	【参考】SVGA: 800x600 46.875kHz 75.000Hz
;	  +------------------------------------------------------+
;	  |    OSC       HT  HS  HB  HD  HF   VT  VS  VB  VD  VF |
;	  | 49.500      132  10  20 100   2  625   3  21 600   1 |
;	  +------------------------------------------------------+
;	  49.500MHz/(8*132)=46.875kHz (49.500MHz/1)/(8*132*625)=75.000Hz
;	  100/132=0.758 600/625=0.960 (0.758/0.960)/(800/600)=0.592
;
;----------------------------------------------------------------

;パラメータ1
	.offset	0
crtmod_param_1_width:	.ds.w	1
crtmod_param_1_height:	.ds.w	1
crtmod_param_1_r20h:	.ds.b	1
			.ds.b	1
crtmod_param_1_2nd:	.ds.w	1
crtmod_param_1_size:
	.text

;パラメータ2
	.offset	0
crtmod_param_2_r20l:	.ds.b	1
crtmod_param_2_hrl:	.ds.b	1
crtmod_param_2_r00:	.ds.w	1
crtmod_param_2_r01:	.ds.w	1
crtmod_param_2_r02:	.ds.w	1
crtmod_param_2_r03:	.ds.w	1
crtmod_param_2_r04:	.ds.w	1
crtmod_param_2_r05:	.ds.w	1
crtmod_param_2_r06:	.ds.w	1
crtmod_param_2_r07:	.ds.w	1
crtmod_param_2_r08:	.ds.w	1
crtmod_param_2_size:
	.text

crtmod_param_1	.macro	width,height,r20h,offset2nd
	.dc.w	width
	.dc.w	height
	.dc.b	r20h			;R20H
	.dc.b	0
	.dc.w	crtmod_param_2_size*offset2nd
	.endm

crtmod_param_2	.macro	r20l,hrl,ht,hs,hb,hd,hf,vt,vs,vb,vd,vf,r08
	.fail	(ht.and.1)!=0
	.fail	ht!=hs+hb+hd+hf
	.fail	vt!=vs+vb+vd+vf
	.dc.b	r20l			;R20L
	.dc.b	hrl			;HRL
	.dc.w	hs+hb+hd+hf-1		;R00
	.dc.w	hs-1			;R01
	.dc.w	hs+hb-5			;R02
	.dc.w	hs+hb+hd-5		;R03
	.dc.w	vs+vb+vd+vf-1		;R04
	.dc.w	vs-1			;R05
	.dc.w	vs+vb-1			;R06
	.dc.w	vs+vb+vd-1		;R07
	.dc.w	r08			;R08
	.endm

crtmod_modes	equ	(crtmod_table_1_crt_end-crtmod_table_1_crt)/crtmod_param_1_size	;画面モードの数

	.text
	.even
iocs_10_CRTMOD:
dMM	reg	d3			;メモリモード
dPM	reg	d4			;設定前の画面モード
aE8	reg	a2			;(～)E8のベースアドレス
aEB	reg	a3			;(～)EBのベースアドレス
aED	reg	a4			;(～)EDのベースアドレス
aP1	reg	a5			;パラメータ1のアドレス
aP2	reg	a6			;パラメータ2のアドレス
	push	d1-d2/dMM/dPM/a0-a1/aE8/aEB/aED/aP1/aP2

;(～)E8でアクセスする
;	$00E80000	CRTC
;	$00E82000	VICON
;	$00E84000	DMAC
;	$00E86000	SUPERAREA
;	$00E88000	MFP
;	$00E8A000	RTC
;	$00E8C000	PRNPORT
;	$00E8E000	SYSPORT
	lea.l	$00E88000,aE8
E8	reg	-$00E88000(aE8)

;(～)EBでアクセスする
;	$00EB0000	SPRC
	lea.l	$00EB8000,aEB
EB	reg	-$00EB8000(aEB)

;(～)EDでアクセスする
;	$00ED0000	SRAM
	lea.l	$00ED8000,aED
ED	reg	-$00ED8000(aED)

;SRAMを初期化する
	moveq.l	#$60,d0
	moveq.l	#$F0,d2
	and.b	(SRAM_XEIJ)ED,d2
	if	<cmp.b d0,d2>,ne	;初期化されていない
		move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
		move.b	d0,(SRAM_XEIJ)ED	;初期化する
		clr.b	(SYSPORT_SRAM)E8	;locksram
	endif

;バージョン確認
	move.l	#CRTMOD_VERSION,d0
	goto	<cmp.w #$56FF,d1>,eq,@f
	if	<cmp.w #$16FF,d1>,eq
		if	<btst.b #SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED>,ne
			bset.l	#31,d0
		endif
@@:		goto	crtmod_pop

	endif

;設定前の画面モードを確認する
	moveq.l	#0,dPM
	move.b	BIOS_CRTMOD.w,dPM	;設定前の画面モード
	swap.w	dPM
;<dPM.l:設定前の画面モード<<16

;初期化するか
	move.w	d1,dPM
	clr.b	dPM
	sub.w	dPM,d1
;<d1.w:画面モード
;<dPM.w:$0000=初期化する,$0100=初期化しない,$4300=CRT向け,$4C00=LCD向け

;CRT向けとLCD向けのスイッチの切り替え
	if	<cmp.w #$4300,dPM>,eq	;CRT向け
		move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
		bclr.b	#SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED
		clr.b	(SYSPORT_SRAM)E8	;locksram
		clr.w	dPM			;初期化する
	elif	<cmp.w #$4C00,dPM>,eq	;LCD向け
		move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
		bset.b	#SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED
		clr.b	(SYSPORT_SRAM)E8	;locksram
		clr.w	dPM			;初期化する
	endif
;<dPM.w:$0000=初期化する,$0100=初期化しない

;取得のみか
;	IPLROM 1.0～1.3は$FFFFを除いて設定後の画面モードが範囲外のとき何もしない
;	ここでは$FFFFを含めて設定後の画面モードが範囲外のとき取得のみとする
;	ただし$43FFと$4CFFはCRT向けとLCD向けのスイッチの切り替えだけ行う
	goto	<cmp.w #crtmod_modes,d1>,hs,crtmod_end	;設定後の画面モードが範囲外

;設定する

;パラメータ1のアドレスを求める
	lea.l	crtmod_table_1_crt(pc),aP1
	if	<btst.b #SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED>,ne	;LCD向け
		lea.l	crtmod_table_1_lcd(pc),aP1
	endif
	move.w	d1,d0
  .if crtmod_param_1_size=8
	lsl.w	#3,d0
  .else
	mulu.w	#crtmod_param_1_size,d0
  .endif
	adda.w	d0,aP1
;<aP1.l:パラメータ1のアドレス

;パラメータ2のアドレスを求める
	lea.l	crtmod_table_2(pc),aP2
	adda.w	crtmod_param_1_2nd(aP1),aP2
;<aP2.l:パラメータ2のアドレス

;メモリモードを確認する
	moveq.l	#7,dMM
	and.b	crtmod_param_1_r20h(aP1),dMM	;メモリモード。0～7
;<dMM.w:メモリモード。0～7

;初期化するか
	if	<tst.w dPM>,eq

	;初期化する

	;設定後の画面モードを保存する
		move.b	d1,BIOS_CRTMOD.w	;設定後の画面モード

	;グラフィック画面OFF、テキスト画面OFF、スプライト画面OFF
		clr.w	(VICON_VISIBLE)E8

	;テキストカーソルOFF
		IOCS	_B_CUROFF

	;テキストプレーン0～1をクリアする
	;	ラスタコピーを使うと速いがコードが長くなる
	;	初回はCRTCが動いていないのでラスタコピーが終わらない
		move.w	#$0133,(CRTC_ACCESS)E8	;同時アクセス開始
		moveq.l	#0,d0
		lea.l	$00E00000,a0		;テキストVRAM
		move.w	#($00E20000-$00E00000)/(4*2)-1,d1	;16384回
		for	d1
			move.l	d0,(a0)+
			move.l	d0,(a0)+
		next
		move.w	#$0033,(CRTC_ACCESS)E8	;同時アクセス終了

	;グラフィック画面使用不可
		clr.w	BIOS_GRAPHIC_PALETS.w	;グラフィック画面の色数-1。0=グラフィック画面使用不可

	;初期化する/しない共通
		bsr	crtmod_common

	;CRTCコマンド停止
		clr.w	(CRTC_ACTION)E8

	;グラフィックパレットを初期化する
  .ifdef CRTMOD_REPRODUCE_BUG		;バグを再現させる
		moveq.l	#3,d0
		and.b	crtmod_param_2_r20l(aP2),d0	;水平解像度。256x256=256色,512x512=512色,768x512=65536色
  .else
		move.w	dMM,d0			;メモリモード。0～7
  .endif
		bsr	initialize_gpalet	;グラフィックパレットを初期化する

	;グラフィックストレージON
	;	IPLROM 1.0～1.3の_CRTMODはグラフィックストレージONの状態で復帰する
		bset.b	#CRTC_GRAPHIC_STORAGE_BIT,(CRTC_MODE_BYTE)E8	;グラフィックストレージON

	;テキストカーソルON
		IOCS	_B_CURON

	;テキストパレットを初期化する
		lea.l	(SRAM_TEXT_PALET_0)ED,a0
		lea.l	(VICON_TSPALET)E8,a1
		move.l	(a0)+,(a1)+		;0,1
		move.l	(a0)+,(a1)+		;2,3
		move.l	(a0),d0			;d0=4|8
		move.l	d0,d1			;d1=4|8
		swap.w	d0			;d0=8|4
		move.w	d0,(a1)+		;4
		move.w	d0,(a1)+		;5
		move.w	d0,(a1)+		;6
		move.w	d0,(a1)+		;7
		move.w	d1,d0			;d0=8|8
		move.l	d0,(a1)+		;8,9
		move.l	d0,(a1)+		;10,11
		move.l	d0,(a1)+		;12,13
		move.l	d0,(a1)+		;14,15

	;コントラストを初期化する
		move.b	(SRAM_CONTRAST)ED,(SYSPORT_CONTRAST)E8

	;スプライトコントローラを設定する
~i = SPRC_SPRITE_OFF|SPRC_BG_1_TEXT_1|SPRC_BG_1_OFF|SPRC_BG_0_TEXT_0|SPRC_BG_0_OFF
		move.w	#~i,(SPRC_CONTROL)EB

	;テキスト画面ON
		move.w	#VICON_TXON_MASK,(VICON_VISIBLE)E8

	;優先順位を設定する
~i = 0<<VICON_SPPR_BIT|1<<VICON_TXPR_BIT|2<<VICON_GRPR_BIT			;SP>TX>GR
~j = 3<<VICON_G4TH_BIT|2<<VICON_G3RD_BIT|1<<VICON_G2ND_BIT|0<<VICON_G1ST_BIT	;G1>G2>G3>G4
		move.w	#~i|~j,(VICON_PRIORITY)E8

	else

	;初期化しない

	;設定後の画面モードを保存する
		move.b	d1,BIOS_CRTMOD.w	;設定後の画面モード

	;グラフィック画面使用不可
		clr.w	BIOS_GRAPHIC_PALETS.w	;グラフィック画面の色数-1。0=グラフィック画面使用不可

	;初期化する/しない共通
		bsr	crtmod_common

	;グラフィック画面が表示されているか
		moveq.l	#VICON_GXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,d0
		and.w	(VICON_VISIBLE)E8,d0
		if	ne			;グラフィック画面が表示されているとき

		;メモリモードを設定する
		;	ストレージは変化しない
			moveq.l	#.not.7,d0
			and.b	(CRTC_MODE_BYTE)E8,d0
			or.b	dMM,d0
			move.b	d0,(CRTC_MODE_BYTE)E8
			move.w	dMM,(VICON_MEMORY_MODE)E8

		;BIOSワークエリアを初期化する
			move.l	#$00C00000,BIOS_GRAPHIC_PAGE.w
			if	<cmp.w #4,dMM>,lo	;メモリモード0～3。512x512ドット
				move.l	#2*512,BIOS_GRAPHIC_Y_OFFSET.w
				if	<cmp.w #1,dMM>,lo	;メモリモード0。512x512ドット、16色、4ページ
					move.w	#16-1,BIOS_GRAPHIC_PALETS.w
				elif	eq			;メモリモード1。512x512ドット、256色、2ページ
					move.w	#256-1,BIOS_GRAPHIC_PALETS.w
				else				;メモリモード2～3。512x512ドット、65536色、1ページ
					move.w	#65536-1,BIOS_GRAPHIC_PALETS.w
				endif
			else					;メモリモード4～7。1024x1024ドット、16色、1ページ
				move.l	#2*1024,BIOS_GRAPHIC_Y_OFFSET.w
				move.w	#16-1,BIOS_GRAPHIC_PALETS.w
			endif

		endif

	endif

;終了
;<dPM.l:設定前の画面モード<<16
crtmod_end:
	clr.w	dPM
	swap.w	dPM			;設定前の画面モード
	move.l	dPM,d0
crtmod_pop:
	pop
	rts

;初期化する/しない共通
crtmod_common:

;CRTCとシステムポートのR20,HRL,R00～R07を設定する
;	すべての画面モードがメモリモード3になる
;	ストレージはOFFになる
	move.w	#3<<8,d2		;R20H(新)
	move.b	crtmod_param_2_r20l(aP2),d2	;R20L(新)
;<d2.w:R20(新)
	lea.l	dot_clock_rank(pc),a0
	moveq.l	#%00011111,d0
	and.b	(CRTC_RESOLUTION_BYTE)E8,d0	;R20L(古)
	moveq.l	#SYSPORT_HRL,d1
	and.b	(SYSPORT_MISC)E8,d1
	neg.b	d1
	addx.b	d0,d0				;R20L<<1|HRL(古)
	move.b	(a0,d0.w),d0			;古いドットクロックのランク
	moveq.l	#%00011111,d1
	and.b	d2,d1				;R20L(新)
	add.b	d1,d1
	add.b	crtmod_param_2_hrl(aP2),d1	;R20L<<1|HRL(新)
	move.b	(a0,d1.w),d1			;新しいドットクロックのランク
	if	<cmp.b d0,d1>,lo	;ドットクロックが下がる
		move.w	d2,(CRTC_MODE_RESOLUTION)E8	;R20
		tst.b	crtmod_param_2_hrl(aP2)
		bsne.b	#SYSPORT_HRL_BIT,(SYSPORT_MISC)E8	;HRL
		lea.l	(CRTC_H_SYNC_END)E8,a0	;R01
		lea.l	crtmod_param_2_r01(aP2),a1
		move.w	(a1)+,(a0)+		;R01
		move.l	(a1)+,(a0)+		;R02,R03
		move.l	(a1)+,(a0)+		;R04,R05
		move.l	(a1)+,(a0)+		;R06,R07
		move.w	crtmod_param_2_r00(aP2),(CRTC_H_FRONT_END)E8	;R00
	else				;ドットクロックが同じか上がる
		lea.l	(CRTC_H_FRONT_END)E8,a0	;R00
		lea.l	crtmod_param_2_r00(aP2),a1
		move.l	(a1)+,(a0)+		;R00,R01
		move.l	(a1)+,(a0)+		;R02,R03
		move.l	(a1)+,(a0)+		;R04,R05
		move.l	(a1)+,(a0)+		;R06,R07
		move.w	d2,(CRTC_MODE_RESOLUTION)E8	;R20
		tst.b	crtmod_param_2_hrl(aP2)
		bsne.b	#SYSPORT_HRL_BIT,(SYSPORT_MISC)E8	;HRL
	endif

;CRTCのR08を設定する
;	外部同期水平アジャスト
;	スーパーインポーズするときビデオの映像とX68000の映像を重ねるために、
;	ビデオとX68000の水平同期パルスの先頭の時間差を38.863632MHzのサイクル数で指定する
;	低解像度512x512のとき
;		水平同期パルス幅は4キャラクタ。R01=4-1=3
;		水平バックポーチは6キャラクタ。R02=4+6-5=5
;		外部同期水平アジャストは44
;		perl -e "print((4.7+4.7)*38.863632-(4*8*(4+6))-1)"
;		44.3181408
;	低解像度256x256のとき。1ドット追加する
;		水平同期パルス幅は2キャラクタ。R01=2-1=1
;		水平バックポーチは3キャラクタ。R02=2+3-5=0
;		外部同期水平アジャストは36
;		perl -e "print((4.7+4.7)*38.863632-(8*(8*(2+3)+1))-1)"
;		36.3181408
	move.w	crtmod_param_2_r08(aP2),(CRTC_ADJUST)E8	;R08

;CRTCのR09～R19,R21～R24を初期化する
	moveq.l	#0,d0
	lea.l	(CRTC_RASTER)E8,a0	;R09
	move.w	d0,(a0)+		;R09
	move.l	d0,(a0)+		;R10,R11
	move.l	d0,(a0)+		;R12,R13
	move.l	d0,(a0)+		;R14,R15
	move.l	d0,(a0)+		;R16,R17
	move.l	d0,(a0)+		;R18,R19
	addq.l	#2,a0
	move.w	#$0033,(a0)+		;R21
	move.l	d0,(a0)+		;R22,R23
	move.w	d0,(a0)+		;R24

;ビデオコントローラのメモリモードを設定する
;	すべての画面モードがメモリモード3になる
	move.w	#3,(VICON_MEMORY_MODE)E8

;スプライトコントローラを初期化する
;解像度
	moveq.l	#%1_11_11,d1
	and.b	crtmod_param_2_r20l(aP2),d1	;R20L
;<d1.w:解像度
;水平バックポーチ終了カラム
	moveq.l	#4,d0
	add.w	crtmod_param_2_r02(aP2),d0
	move.w	d0,(SPRC_H_BACK_END)EB	;スプライト水平バックポーチ終了カラム。R02+4
;水平フロントポーチ終了カラム
;	水平バックポーチ終了カラムを設定後130us待ってから水平フロントポーチ終了カラムを設定する
;	水平フロントポーチ終了カラムは水平256ドットのときはR00と同じ値、それ以外は255
;		Inside X68000に低解像度256x256のときだけR00と同じ値を、それ以外は255を設定すると書かれているが、
;		高解像度256x256のときも255にするとスプライトが崩れる場合がある
;		水平512ドットのときは255にしないと水平256ドットから水平512ドットに切り替えたときスプライトの水平方向の位置がずれることがある
;	IPLROM 1.3はdbraでX68030 25MHzのとき500us待っている。060turboのときウエイトが不足する
	moveq.l	#500/50,d0		;500us
	bsr	wait_50us		;50us単位のウェイト
	moveq.l	#%0_00_11,d0
	and.b	d1,d0
	if	eq			;水平256ドット
		move.w	crtmod_param_2_r00(aP2),(SPRC_H_FRONT_END)EB	;スプライト水平フロントポーチ終了カラム。R00
	else				;水平256ドット以外
		move.w	#255,(SPRC_H_FRONT_END)EB	;スプライト水平フロントポーチ終了カラム。255
	endif
;垂直バックポーチ終了ラスタ
	move.w	crtmod_param_2_r06(aP2),(SPRC_V_BACK_END)EB	;スプライト垂直バックポーチ終了ラスタ。R06
;解像度
	moveq.l	#-36,d0
	add.b	BIOS_CRTMOD.w,d0
	ifand	<>,pl,<subq.b #4,d0>,lo	;36/37/38/39 256x256(正方形)
		moveq.l	#%10000,d1		;スプライトは256x256
	elifand	<subq.b #4,d0>,hs,<subq.b #4,d0>,lo	;44/45/46/47 512x256(※)
		moveq.l	#%10101,d1		;スプライトは512x512
	endif
	move.w	d1,(SPRC_RESOLUTION)EB	;スプライト解像度。--------|---|高解像度|垂直サイズ##|水平サイズ##

;グラフィック画面のクリッピングエリア
;	画面モード20～27は表示画面が実画面より大きいことに注意する
	move.w	crtmod_param_1_width(aP1),d0	;幅
	move.w	crtmod_param_1_height(aP1),d1	;高さ
	if	<cmp.w #4,dMM>,lo	;メモリモード0～3。512x512まで
		move.w	#512,d2
		if	<cmp.w d2,d0>,hi
			move.w	d2,d0
		endif
		if	<cmp.w d2,d1>,hi
			move.w	d2,d1
		endif
	endif
	subq.w	#1,d0			;X最大
	subq.w	#1,d1			;Y最大
	clr.l	BIOS_GRAPHIC_LEFT.w	;BIOS_GRAPHIC_TOP
	move.w	d0,BIOS_GRAPHIC_RIGHT.w
	move.w	d1,BIOS_GRAPHIC_BOTTOM.w

;グラフィックVRAMのY方向のオフセット
					;dMM=   0    1    2    3    4    5    6    7
	moveq.l	#4,d0			; d0=   4    4    4    4    4    4    4    4
	and.w	dMM,d0			; d0=   0    0    0    0    4    4    4    4
	addq.w	#4,d0			; d0=   4    4    4    4    8    8    8    8
	lsl.w	#8,d0			; d0=1024 1024 1024 1024 2048 2048 2048 2048
	move.l	d0,BIOS_GRAPHIC_Y_OFFSET.w

;グラフィック画面のページ数
					;dMM=0 1 2  3  4  5  6  7
	moveq.l	#4,d0			; d0=4 4 4  4  4  4  4  4
	lsr.b	dMM,d0			; d0=4 2 1  0  0  0  0  0
	seq.b	d1			; d1=0 0 0 -1 -1 -1 -1 -1
	sub.b	d1,d0			; d0=4 2 1  1  1  1  1  1
	move.b	d0,BIOS_GRAPHIC_PAGES.w

;テキスト画面の位置
	move.l	#$00E00000,BIOS_TEXT_PLANE.w
	clr.l	BIOS_CONSOLE_OFFSET.w

;テキスト画面の大きさ
	move.w	crtmod_param_1_width(aP1),d0	;幅
	move.w	crtmod_param_1_height(aP1),d1	;高さ
	lsr.w	#3,d0			;幅/8
	lsr.w	#4,d1			;高さ/16。424は16で割り切れないことに注意
	subq.w	#1,d0			;幅/8-1
	subq.w	#1,d1			;高さ/16-1
	move.w	d0,BIOS_CONSOLE_RIGHT.w
	move.w	d1,BIOS_CONSOLE_BOTTOM.w

;テキストカーソルの位置
	clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW

;マウスカーソルの移動範囲
	clr.l	d1
	move.l	BIOS_GRAPHIC_RIGHT,d2	;BIOS_GRAPHIC_BOTTOM
	IOCS	_MS_LIMIT		;IOCSコール$77 _MS_LIMIT マウスカーソルの移動範囲を設定する

	rts

;パラメータ1(CRT向け)
crtmod_table_1_crt:
;			 WIDTH HEIGHT R20H  2ND    1ST
	crtmod_param_1	   512,   512,   4,   0  ; CRT 0
	crtmod_param_1	   512,   512,   4,   1  ; CRT 1
	crtmod_param_1	   256,   256,   4,   2  ; CRT 2
	crtmod_param_1	   256,   256,   4,   3  ; CRT 3
	crtmod_param_1	   512,   512,   0,   0  ; CRT 4
	crtmod_param_1	   512,   512,   0,   1  ; CRT 5
	crtmod_param_1	   256,   256,   0,   2  ; CRT 6
	crtmod_param_1	   256,   256,   0,   3  ; CRT 7
	crtmod_param_1	   512,   512,   1,   0  ; CRT 8
	crtmod_param_1	   512,   512,   1,   1  ; CRT 9
	crtmod_param_1	   256,   256,   1,   2  ; CRT 10
	crtmod_param_1	   256,   256,   1,   3  ; CRT 11
	crtmod_param_1	   512,   512,   3,   0  ; CRT 12
	crtmod_param_1	   512,   512,   3,   1  ; CRT 13
	crtmod_param_1	   256,   256,   3,   2  ; CRT 14
	crtmod_param_1	   256,   256,   3,   3  ; CRT 15
	crtmod_param_1	   768,   512,   4,   4  ; CRT 16
	crtmod_param_1	  1024,   424,   4,   5  ; CRT 17
	crtmod_param_1	  1024,   848,   4,   6  ; CRT 18
	crtmod_param_1	   640,   480,   4,   7  ; CRT 19
	crtmod_param_1	   768,   512,   1,   4  ; CRT 20
	crtmod_param_1	  1024,   424,   1,   5  ; CRT 21
	crtmod_param_1	  1024,   848,   1,   6  ; CRT 22
	crtmod_param_1	   640,   480,   1,   7  ; CRT 23
	crtmod_param_1	   768,   512,   3,   4  ; CRT 24
	crtmod_param_1	  1024,   424,   3,   5  ; CRT 25
	crtmod_param_1	  1024,   848,   3,   6  ; CRT 26
	crtmod_param_1	   640,   480,   3,   7  ; CRT 27
	crtmod_param_1	   384,   256,   4,   8  ; CRT 28
	crtmod_param_1	   384,   256,   0,   8  ; CRT 29
	crtmod_param_1	   384,   256,   1,   8  ; CRT 30
	crtmod_param_1	   384,   256,   3,   8  ; CRT 31
	crtmod_param_1	   512,   512,   4,   9  ; CRT 32
	crtmod_param_1	   512,   512,   0,   9  ; CRT 33
	crtmod_param_1	   512,   512,   1,   9  ; CRT 34
	crtmod_param_1	   512,   512,   3,   9  ; CRT 35
	crtmod_param_1	   256,   256,   4,  10  ; CRT 36
	crtmod_param_1	   256,   256,   0,  10  ; CRT 37
	crtmod_param_1	   256,   256,   1,  10  ; CRT 38
	crtmod_param_1	   256,   256,   3,  10  ; CRT 39
	crtmod_param_1	   512,   256,   4,  22  ; CRT 40
	crtmod_param_1	   512,   256,   0,  22  ; CRT 41
	crtmod_param_1	   512,   256,   1,  22  ; CRT 42
	crtmod_param_1	   512,   256,   3,  22  ; CRT 43
	crtmod_param_1	   512,   256,   4,  22  ; CRT 44
	crtmod_param_1	   512,   256,   0,  22  ; CRT 45
	crtmod_param_1	   512,   256,   1,  22  ; CRT 46
	crtmod_param_1	   512,   256,   3,  22  ; CRT 47
crtmod_table_1_crt_end:

;パラメータ1(LCD向け)
crtmod_table_1_lcd:
;			 WIDTH HEIGHT R20H  2ND    1ST
	crtmod_param_1	   512,   512,   4,  11  ; LCD 0
	crtmod_param_1	   512,   512,   4,  12  ; LCD 1
	crtmod_param_1	   256,   256,   4,  13  ; LCD 2
	crtmod_param_1	   256,   256,   4,  14  ; LCD 3
	crtmod_param_1	   512,   512,   0,  11  ; LCD 4
	crtmod_param_1	   512,   512,   0,  12  ; LCD 5
	crtmod_param_1	   256,   256,   0,  13  ; LCD 6
	crtmod_param_1	   256,   256,   0,  14  ; LCD 7
	crtmod_param_1	   512,   512,   1,  11  ; LCD 8
	crtmod_param_1	   512,   512,   1,  12  ; LCD 9
	crtmod_param_1	   256,   256,   1,  13  ; LCD 10
	crtmod_param_1	   256,   256,   1,  14  ; LCD 11
	crtmod_param_1	   512,   512,   3,  11  ; LCD 12
	crtmod_param_1	   512,   512,   3,  12  ; LCD 13
	crtmod_param_1	   256,   256,   3,  13  ; LCD 14
	crtmod_param_1	   256,   256,   3,  14  ; LCD 15
	crtmod_param_1	   768,   512,   4,  15  ; LCD 16
	crtmod_param_1	   768,   600,   4,  16  ; LCD 17
	crtmod_param_1	   768,  1024,   4,  17  ; LCD 18
	crtmod_param_1	   640,   480,   4,  18  ; LCD 19
	crtmod_param_1	   768,   512,   1,  15  ; LCD 20
	crtmod_param_1	   768,   600,   1,  16  ; LCD 21
	crtmod_param_1	   768,  1024,   1,  17  ; LCD 22
	crtmod_param_1	   640,   480,   1,  18  ; LCD 23
	crtmod_param_1	   768,   512,   3,  15  ; LCD 24
	crtmod_param_1	   768,   600,   3,  16  ; LCD 25
	crtmod_param_1	   768,  1024,   3,  17  ; LCD 26
	crtmod_param_1	   640,   480,   3,  18  ; LCD 27
	crtmod_param_1	   384,   256,   4,  19  ; LCD 28
	crtmod_param_1	   384,   256,   0,  19  ; LCD 29
	crtmod_param_1	   384,   256,   1,  19  ; LCD 30
	crtmod_param_1	   384,   256,   3,  19  ; LCD 31
	crtmod_param_1	   512,   512,   4,  20  ; LCD 32
	crtmod_param_1	   512,   512,   0,  20  ; LCD 33
	crtmod_param_1	   512,   512,   1,  20  ; LCD 34
	crtmod_param_1	   512,   512,   3,  20  ; LCD 35
	crtmod_param_1	   256,   256,   4,  21  ; LCD 36
	crtmod_param_1	   256,   256,   0,  21  ; LCD 37
	crtmod_param_1	   256,   256,   1,  21  ; LCD 38
	crtmod_param_1	   256,   256,   3,  21  ; LCD 39
	crtmod_param_1	   512,   256,   4,  23  ; LCD 40
	crtmod_param_1	   512,   256,   0,  23  ; LCD 41
	crtmod_param_1	   512,   256,   1,  23  ; LCD 42
	crtmod_param_1	   512,   256,   3,  23  ; LCD 43
	crtmod_param_1	   512,   256,   4,  23  ; LCD 44
	crtmod_param_1	   512,   256,   0,  23  ; LCD 45
	crtmod_param_1	   512,   256,   1,  23  ; LCD 46
	crtmod_param_1	   512,   256,   3,  23  ; LCD 47

;パラメータ2
crtmod_table_2:
;			   R20L  HRL    HT   HS   HB   HD   HF    VT   VS   VB   VD   VF   R08    2ND  1ST
	crtmod_param_2	 %10101,   0,   92,  10,  12,  64,   6,  568,   6,  35, 512,  15,   27  ;   0  CRT 0/4/8/12
	crtmod_param_2	 %00101,   0,   76,   4,   6,  64,   2,  260,   3,  14, 240,   3,   44  ;   1  CRT 1/5/9/13
	crtmod_param_2	 %10000,   0,   46,   5,   6,  32,   3,  568,   6,  35, 512,  15,   27  ;   2  CRT 2/6/10/14
	crtmod_param_2	 %00000,   0,   38,   2,   3,  32,   1,  260,   3,  14, 240,   3,   36  ;   3  CRT 3/7/11/15
	crtmod_param_2	 %10110,   0,  138,  15,  18,  96,   9,  568,   6,  35, 512,  15,   27  ;   4  CRT 16/20/24
	crtmod_param_2	 %10110,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   5  CRT 17/21/25
	crtmod_param_2	 %11010,   0,  176,  16,  20, 128,  12,  465,   8,  25, 424,   8,   27  ;   6  CRT 18/22/26
	crtmod_param_2	 %10110,   0,  138,  15,  26,  80,  17,  568,   6,  51, 480,  31,   27  ;   7  CRT 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  568,   6,  35, 512,  15,   27  ;   8  CRT 28/29/30/31
	crtmod_param_2	 %10110,   0,  138,  15,  34,  64,  25,  568,   6,  35, 512,  15,   27  ;   9  CRT 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  568,   6,  35, 512,  15,   27  ;  10  CRT 36/37/38/39
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  66, 512,  45,   27  ;  11  LCD 0/4/8/12
	crtmod_param_2	 %10101,   0,   82,   6,  10,  64,   2,  625,   2,  82, 480,  61,   27  ;  12  LCD 1/5/9/13
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  66, 512,  45,   27  ;  13  LCD 2/6/10/14
	crtmod_param_2	 %10000,   0,   42,   3,   5,  32,   2,  625,   2,  82, 480,  61,   27  ;  14  LCD 3/7/11/15
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  15  LCD 16/20/24
	crtmod_param_2	 %10110,   0,  124,   9,  15,  96,   4,  625,   2,  22, 600,   1,   27  ;  16  LCD 17/21/25
	crtmod_param_2	 %11010,   0,  124,   9,  15,  96,   4,  625,   2,  66, 512,  45,   27  ;  17  LCD 18/22/26
	crtmod_param_2	 %10111,   0,  100,  12,   6,  80,   2,  525,   2,  33, 480,  10,   27  ;  18  LCD 19/23/27
	crtmod_param_2	 %10001,   1,   68,   7,   9,  48,   4,  625,   2,  66, 512,  45,   27  ;  19  LCD 28/29/30/31
	crtmod_param_2	 %10110,   0,  124,   9,  31,  64,  20,  625,   2,  66, 512,  45,   27  ;  20  LCD 32/33/34/35
	crtmod_param_2	 %10001,   1,   68,   7,  17,  32,  12,  625,   2,  66, 512,  45,   27  ;  21  LCD 36/37/38/39
	crtmod_param_2	 %10001,   0,   92,  10,  12,  64,   6,  568,   6,  35, 512,  15,   27  ;  22  CRT 40/41/42/43/44/45/46/47
	crtmod_param_2	 %10001,   0,   82,   6,  10,  64,   2,  625,   2,  66, 512,  45,   27  ;  23  LCD 40/41/42/43/44/45/46/47

;R20L<<1|HRL→ドットクロックのランク
;	rank	R20L	HRL	osc	div	dotclk	mode
;	7	1**10	*	69.552	2	34.776	768x512(高)
;	6	1**11	*	50.350	2	25.175	640x480
;	5	1**01	0	69.552	3	23.184	512x512(高)
;	4	1**01	1	69.552	4	17.388	384x256
;	3	1**00	0	69.552	6	11.592	256x256(高)
;	2	0**01	*	38.864	4	9.716	512x512(低)
;	1	1**00	1	69.552	8	8.694
;	0	0**00	*	38.864	8	4.858	256x256(低)
;	0	0**1*	*	38.864	8	4.858
dot_clock_rank:
  .rept 4
	.dc.b	0	;0**00 0
	.dc.b	0	;0**00 1
	.dc.b	2	;0**01 0
	.dc.b	2	;0**01 1
	.dc.b	0	;0**10 0
	.dc.b	0	;0**10 1
	.dc.b	0	;0**11 0
	.dc.b	0	;0**11 1
  .endm
  .rept 4
	.dc.b	3	;1**00 0
	.dc.b	1	;1**00 1
	.dc.b	5	;1**01 0
	.dc.b	4	;1**01 1
	.dc.b	7	;1**10 0
	.dc.b	7	;1**10 1
	.dc.b	6	;1**11 0
	.dc.b	6	;1**11 1
  .endm

  .endif  ;REMOVE_CRTMOD_G_CLR_ON



;----------------------------------------------------------------
;	6x12 ANKフォント
;		X68000のCGROMとIPLROM 1.3を組み合わせると6x12 ANKフォントを表示できない
;		IPLROM 1.6は6x12 ANKフォントを$00FEF400～$00FEFFFF(3072バイト)に置く
;	変更前
;		000073F6 203C00FBF400     	move.l	#$00FBF400,d0
;----------------------------------------------------------------
	PATCH_DATA	p73F6,$00FF73F6,$00FF73F6+5,$203C00FB
		move.l	#$00FEF400,d0



;----------------------------------------------------------------
;	IOCS _SET232C
;	ボーレート8=19200bpsを使えるようにする
;		IPLROM 1.3のIOCS _SET232Cはボーレート8=19200bpsを選択できるが、SCC WR13:WR12の値が間違っており、
;		スタートビットで同期してもストップビットまでにおよそ1ビットずれてしまうので使えなかった
;		(5000000/2/16)/19200-2=6.138
;		(5000000/2/16)/(7+2)=17361.111=19200*0.904  誤
;		(5000000/2/16)/(6+2)=19531.250=19200*1.017  正
;	ボーレート9=38400bpsと10=76800bpsを選択できるようにする
;		使えるとは限らない
;		RTS/CTSに対応していないので実用性は不明
;		SCCの動作周波数が7.5MHzのとき9=57600bpsと10=115200bpsになる
;	RTS/CTSの選択を確実に無視する
;		RTS/CTSには対応していないが選択されているだけでボーレート4=1200bpsになってしまう問題があった
;
;					変更前				変更後
;		00FF7A1A 4240		clr.w	d0			=
;		00FF7A1C 1001		move.b	d1,d0			=
;	A	00FF7A1E B03C		cmp.b	#$09,d0			movea.l	d1,a0
;		00FF7A20 0009						and.b	#$7F,d1
;		00FF7A22 6504		bcs	$00FF7A28
;		00FF7A24 303C		move.w	#$0004,d0		cmp.b	#11,d1
;		00FF7A26 0004
;		00FF7A28 D040		add.w	d0,d0			blo	$00FF7A2C
;		00FF7A2A 41FA		lea.l	$00FF7AE2(pc),a0	moveq.l	#4,d1
;		00FF7A2C 00B6						bsr.w	$00FF7AE2
;		00FF7A2E 3030		move.w	$00(a0,d0.w),d0
;		00FF7A30 0000						move.l	a0,d1
;		00FF7A32
;	B	00FF7AE2 0821		.dc.w	$0821			move.w	#2083,d0
;		00FF7AE4 0410		.dc.w	$0410
;		00FF7AE6 0207		.dc.w	$0207			lsr.w	d1,d0
;		00FF7AE8 0102		.dc.w	$0102			moveq.l	#-2,d1
;		00FF7AEA 0080		.dc.w	$0080			addx.w	d1,d0
;		00FF7AEC 003F		.dc.w	$003F			rts
;		00FF7AEE 001F		.dc.w	$001F			=
;		00FF7AF0 000E		.dc.w	$000E			=
;		00FF7AF2 0007		.dc.w	$0007	;6が正しい	=
;		00FF7AF4
;----------------------------------------------------------------
	PATCH_DATA	p7a1e,$00FF7A1E,$00FF7A31,$B03C0009
;A
;<d1.b:ボーレートの番号
;	0=75bps,1=150bps,2=300bps,3=600bps,4=1200bps,5=2400bps,6=4800bps,7=9600bps,8=19200bps,9=38400bps,10=76800bps
	movea.l	d1,a0			;d1を保存する
	and.b	#$7F,d1			;RTS/CTSの選択を確実に無視する
	if	<cmp.b #11,d1>,hs	;ボーレートの番号が0～10の範囲外のとき
		moveq.l	#4,d1			;ボーレート4=1200bpsにする
	endif
	bsr.w	($00FF7AE2)PATCH_ZL	;Bを呼び出す
	move.l	a0,d1			;d1を復元する
;<d0.w:SCC WR13:WR12の値

	PATCH_DATA	p7ae2,$00FF7AE2,$00FF7AED,$08210410
;B
	move.w	#2083,d0		;(5000000Hz/2/16)/75bps=2083.333を
	lsr.w	d1,d0			;ボーレートの番号の分だけ右にシフトして
	moveq.l	#-2,d1			;2を引いて
	addx.w	d1,d0			;四捨五入する
	rts				;0→2081,1→1040,2→519,3→258,4→128,5→63,6→31,7→14,8→6,9→2,10→0



;----------------------------------------------------------------
;	DMA転送開始直前のキャッシュフラッシュ
;	変更前
;		00FF8284 2F00                   move.l	d0,-(sp)
;		00FF8286 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;		00FF828C 6314                   bls.s	$00FF82A2
;		00FF828E 4E7A0002               movec.l	cacr,d0
;		00FF8292 807C0808               or.w	#$0808,d0
;		00FF8296 4E7B0002               movec.l	d0,cacr
;		00FF829A C07CF7F7               and.w	#$F7F7,d0
;		00FF829E 4E7B0002               movec.l	d0,cacr
;		00FF82A2 201F                   move.l	(sp)+,d0
;		00FF82A4 4E75                   rts
;		00FF82A6
;----------------------------------------------------------------
	PATCH_DATA	dma_cache_flush,$00FF8284,$00FF82A5,$2F000C38
	jmp	cache_flush



;----------------------------------------------------------------
;	割り込み関係のIOCSコールのハイメモリ対策
;		割り込み関係のIOCSコールは割り込みが未使用かどうかをベクタが$01000000以上かどうかで判断している
;		ベクタがハイメモリを指していると未使用と誤認する
;		ベクタの上位8bitがベクタ番号と一致しているかどうかに変更する
;		以下のIOCSコールが該当する
;			$43	iocs_6A_OPMINTST
;			$44	iocs_6B_TIMERDST
;			$4D	iocs_6C_VDISPST
;			$4E	iocs_6D_CRTCRAS
;			$4F	iocs_6E_HSYNCST
;			$63	iocs_6F_PRNINTST
;	変更前
;		00FF85D4 007C0700         	ori.w	#$0700,sr		;割り込み禁止
;		00FF85D8 E548             	lsl.w	#2,d0			;ベクタオフセット
;		00FF85DA 3040             	movea.w	d0,a0			;a0.l:ベクタオフセット
;		00FF85DC 2009             	move.l	a1,d0			;変更後のベクタ
;		00FF85DE 670C_000085EC    	beq.s	$00FF85EC		;解除
;		00FF85E0 2010             	move.l	(a0),d0			;d0.l:変更前のベクタ
;	>>>>>	00FF85E2 0C8001000000     	cmpi.l	#$01000000,d0		;変更前のベクタにベクタ番号が付いているか
;		00FF85E8 6504_000085EE    	bcs.s	$00FF85EE		;変更前のベクタにベクタ番号が付いていないので使用中
;		00FF85EA                  ;変更前のベクタにベクタ番号が付いているので未使用
;		00FF85EA 2089             	move.l	a1,(a0)			;ベクタを変更する
;		00FF85EC 4E75             	rts				;個々のIOCSコールへ戻る
;		00FF85EE                  ;変更前のベクタにベクタ番号が付いていないので使用中
;		00FF85EE 4A9F             	tst.l	(sp)+			;個々のIOCSコールへ戻らない
;		00FF85F0                  ;使用中のときTRAP#15のrteまで割り込み禁止のままになる
;		00FF85F0 4E75             	rts				;IOCSコールから復帰する
;		00FF85F2
;		
;----------------------------------------------------------------
	PATCH_DATA	p85E2,$00FF85E2,$00FF85E7,$0C800100
	jsr	p85E2
	PATCH_TEXT
;<d0.l:変更前のベクタ
;<a0.l:ベクタオフセット
;>c:cc=未使用,cs=使用中
p85E2:
	push	d0-d1
	move.w	a0,d1			;d1.w:ベクタオフセット
	lsr.w	#2,d1			;d1.b:ベクタ番号
	rol.l	#8,d0			;d0.b:変更前のベクタの上位8bit
	cmp.b	d1,d0			;eq=未使用,ne=使用中
	sne.b	d0			;d1.b:$00=未使用,$FF=使用中
	add.b	d0,d0			;cc=未使用,cs=使用中
	pop
	rts



;----------------------------------------------------------------
;	不具合
;		_MS_LIMITでY方向の範囲を1007までしか設定できない
;		https://stdkmd.net/bugsx68k/#rom_mslimit
;	変更前
;		00FFABA4 B27C03F0               cmp.w	#$03F0,d1
;		00FFABA8
;----------------------------------------------------------------
	PATCH_DATA	mslimit_1st,$00FFABA4,$00FFABA7,$B27C03F0
	cmp.w	#$0400,d1
;----------------------------------------------------------------
;	変更前
;		00FFABB4 B47C03F0               cmp.w	#$03F0,d2
;		00FFABB8
;----------------------------------------------------------------
	PATCH_DATA	mslimit_2nd,$00FFABB4,$00FFABB7,$B47C03F0
	cmp.w	#$0400,d2



;----------------------------------------------------------------
;	_MS_ONTMのキャッシュ制御
;	変更前
;		00FFAC72 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;		00FFAC78 630C                   bls.s	$00FFAC86
;		00FFAC7A 4E7A0002               movec.l	cacr,d0
;		00FFAC7E 2F00                   move.l	d0,-(sp)
;		00FFAC80 7001                   moveq.l	#$01,d0			;EI=1,ED=0
;		00FFAC82 4E7B0002               movec.l	d0,cacr
;		00FFAC86
;----------------------------------------------------------------
	PATCH_DATA	ms_ontm_cache_1st,$00FFAC72,$00FFAC85,$0C380001
	jsr	cache_on_i	;データキャッシュOFF,命令キャッシュON
	move.l	d0,-(sp)
	bra	($00FFAC86)PATCH_ZL
;----------------------------------------------------------------
;	変更前
;		00FFACE8 0C3800010CBC           cmpi.b	#$01,BIOS_MPU_TYPE.w
;		00FFACEE 6306                   bls.s	$00FFACF6
;		00FFACF0 201F                   move.l	(sp)+,d0
;		00FFACF2 4E7B0002               movec.l	d0,cacr
;		00FFACF6
;----------------------------------------------------------------
	PATCH_DATA	ms_ontm_cache_2nd,$00FFACE8,$00FFACF5,$0C380001
	move.l	(sp)+,d2
	jsr	cache_set	;キャッシュ設定
	bra	($00FFACF6)PATCH_ZL



  .if REMOVE_CRTMOD_G_CLR_ON=0

;----------------------------------------------------------------
;	_G_CLR_ON
;	変更前
;		0000B326*48E76040         	movem.l	~pushrl,-(sp)
;			:
;		0000B660*FFFE             	.dc.w	(31<<11)|(31<<6)|(31<<1)
;----------------------------------------------------------------
	PATCH_DATA	g_clr_on,$00FFB326,$00FFB331,$48E76040
	jmp	iocs_90_G_CLR_ON
	PATCH_TEXT
;----------------------------------------------------------------
;IOCSコール$90 _G_CLR_ON グラフィック画面の消去とパレット初期化と表示ON
;パラメータなし
	.text
	.even
iocs_90_G_CLR_ON:
dMM	reg	d3			;メモリモード
aE8	reg	a2			;(～)E8のベースアドレス
aED	reg	a4			;(～)EDのベースアドレス
aP1	reg	a5			;パラメータ1のアドレス
	push	d0-d1/dMM/a0/aE8/aED/aP1

;(～)E8でアクセスする
;	$00E80000	CRTC
;	$00E82000	VICON
;	$00E84000	DMAC
;	$00E86000	SUPERAREA
;	$00E88000	MFP
;	$00E8A000	RTC
;	$00E8C000	PRNPORT
;	$00E8E000	SYSPORT
	lea.l	$00E88000,aE8
E8	reg	-$00E88000(aE8)

;(～)EDでアクセスする
;	$00ED0000	SRAM
	lea.l	$00ED8000,aED
ED	reg	-$00ED8000(aED)

;現在の画面モードを確認する
	moveq.l	#0,d1
	move.b	BIOS_CRTMOD.w,d1	;現在の画面モード
	if	<cmp.w #crtmod_modes,d1>,hs	;現在の画面モードが範囲外のとき
		move.b	(SRAM_CRTMOD)ED,d1		;起動時の画面モードを使う
		if	<cmp.w #crtmod_modes,d1>,hs	;起動時の画面モードも範囲外のとき
			moveq.l	#16,d1			;16を使う
  .if 0
			move.b	#$31,(SYSPORT_SRAM)E8	;unlocksram
			move.b	d1,(SRAM_CRTMOD)ED
			clr.b	(SYSPORT_SRAM)E8	;locksram
  .endif
		endif
	endif

;<d1.l:画面モード

;パラメータ1のアドレスを求める
	lea.l	crtmod_table_1_crt(pc),aP1
	if	<btst.b #SRAM_XEIJ_LCD_BIT,(SRAM_XEIJ)ED>,ne	;LCD向け
		lea.l	crtmod_table_1_lcd(pc),aP1
	endif
	move.w	d1,d0
  .if crtmod_param_1_size=8
	lsl.w	#3,d0
  .else
	mulu.w	#crtmod_param_1_size,d0
  .endif
	adda.w	d0,aP1
;<aP1.l:パラメータ1のアドレス

;メモリモードを確認する
	moveq.l	#7,dMM
	and.b	crtmod_param_1_r20h(aP1),dMM	;メモリモード。0～7
;<dMM.w:メモリモード。0～7

;テキスト画面のみON
	move.w	#VICON_TXON_MASK,(VICON_VISIBLE)E8

;グラフィックストレージON
	bset.b	#CRTC_GRAPHIC_STORAGE_BIT,(CRTC_MODE_BYTE)E8	;グラフィックストレージON

;グラフィックVRAMをクリアする
	lea.l	$00C00000,a0
	moveq.l	#0,d0
	moveq.l	#-1,d1			;1024*512/8=65536回
	for	d1
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	next

;グラフィックストレージOFF
;メモリモードを設定する
	move.b	dMM,(CRTC_MODE_BYTE)E8
	move.w	dMM,(VICON_MEMORY_MODE)E8

;BIOSワークエリアを初期化する
	move.l	#$00C00000,BIOS_GRAPHIC_PAGE.w
	if	<cmp.w #4,dMM>,lo	;メモリモード0～3。512x512ドット
		move.l	#2*512,BIOS_GRAPHIC_Y_OFFSET.w
		if	<cmp.w #1,dMM>,lo	;メモリモード0。512x512ドット、16色、4ページ
			move.w	#16-1,BIOS_GRAPHIC_PALETS.w
		elif	eq			;メモリモード1。512x512ドット、256色、2ページ
			move.w	#256-1,BIOS_GRAPHIC_PALETS.w
		else				;メモリモード2～3。512x512ドット、65536色、1ページ
			move.w	#65536-1,BIOS_GRAPHIC_PALETS.w
		endif
	else					;メモリモード4～7。1024x1024ドット、16色、1ページ
		move.l	#2*1024,BIOS_GRAPHIC_Y_OFFSET.w
		move.w	#16-1,BIOS_GRAPHIC_PALETS.w
	endif

;グラフィックパレットを初期化する
	move.w	dMM,d0
	bsr	initialize_gpalet

;テキスト画面ON、グラフィック画面ON
;	if	<cmp.w #4,dMM>,lo	;メモリモード0～3。512x512ドット
;		move.w	#VICON_TXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,(VICON_VISIBLE)E8
;	else				;メモリモード4～7。1024x1024ドット
;		move.w	#VICON_TXON_MASK|VICON_GXON_MASK,(VICON_VISIBLE)E8
;	endif
;	IPLROM 1.0～1.3は1024x1024ドットと512x512ドットを両方ONにしている
	move.w	#VICON_TXON_MASK|VICON_GXON_MASK|VICON_G4ON_MASK|VICON_G3ON_MASK|VICON_G2ON_MASK|VICON_G1ON_MASK,(VICON_VISIBLE)E8

	pop
	rts

;----------------------------------------------------------------
;グラフィックパレットを初期化する
;<d0.w:メモリモード。0～7
	.text
	.even
initialize_gpalet:
	push	d0-d4/a0-a1
	lea.l	VICON_GPALET,a0
	ifor	<tst.w d0>,eq,<cmp.w #4,d0>,hs	;メモリモード0。512x512ドット、16色、4ページ
						;メモリモード4～7。1024x1024ドット、16色、1ページ
		lea.l	gpalet_16_array(pc),a1
		moveq.l	#16/2-1,d0
		for	d0
			move.l	(a1)+,(a0)+
		next
	elif	<cmp.w #1,d0>,eq	;メモリモード1。512x512ドット、256色、2ページ
		move.l	#%0000000000010010_0000000000010010,d1
		moveq.l	#%0000000000000000_0000000000000000,d4
		do
			moveq.l	#%0000000000000000_0000000000001000,d3
			moveq.l	#8-1,d2
			for	d2
				move.l	d4,d0
				and.l	#%1111101111111111_1111101111111111,d0
				or.l	d3,d0
				and.l	#%1111111111011111_1111111111011111,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	d1,d0
				move.l	d0,(a0)+
				add.l	#%0000000100100000_0000000100100000,d3
			next
			add.l	#%0101010000000000_0101010000000000,d4
		while	cc
	else				;メモリモード2～3。512x512ドット、65536色、1ページ
		move.l	#$00_01_00_01,d0
		move.l	#$02_02_02_02,d1
		moveq.l	#256/2-1,d2
		for	d2
			move.l	d0,(a0)+
			add.l	d1,d0
		next
	endif
	pop
	rts

;グラフィック16色パレット
gpalet_16_array:
	dcrgb	0,0,0
	dcrgb	10,10,10
	dcrgb	0,0,16
	dcrgb	0,0,31
	dcrgb	16,0,0
	dcrgb	31,0,0
	dcrgb	16,0,16
	dcrgb	31,0,31
	dcrgb	0,16,0
	dcrgb	0,31,0
	dcrgb	0,16,16
	dcrgb	0,31,31
	dcrgb	16,16,0
	dcrgb	31,31,0
	dcrgb	21,21,21
	dcrgb	31,31,31

;----------------------------------------------------------------
;50us単位のウェイト
;<d0.l:時間(50us単位)
	.text
	.even
wait_50us:
  .if 0
;Timer-Cを使う
;	Timer-Cが1/200プリスケール(50us)で動作していなければならない
aTCDR	reg	a0
	push	d0-d2/aTCDR
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
  .else
;dbra空ループを使う
;	BIOS_MPU_SPEED_ROM.wとBIOS_MPU_TYPE.wが設定されていなければならない
	push	d0-d3
	subq.l	#1,d0
	if	cc
		move.l	BIOS_MPU_SPEED_ROM_LONG.w,d1
		if	eq
			move.w	BIOS_MPU_SPEED_ROM.w,d1
		endif
	;	上限を20bitとして50usあたりのdbraの回数を求める
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;000/010/020/030
			move.w	#205,d2			;2**12*50/1000=204.8
		elif	eq			;040
			move.w	#307,d2			;2**12*50/1000*6/4=307.2
		else				;060
			move.w	#1229,d2		;2**12*50/1000*6/1=1228.8
		endif
		move.l	d1,d3			;d3=H|L
		swap.w	d3			;d3=L|H
		mulu.w	d2,d3			;d3=c*H
		mulu.w	d2,d1			;d1=c*L
		swap.w	d3
		clr.w	d3			;d3=c*H|0
		add.l	d3,d1			;d1=c*(H|L)
		and.w	#$F000,d1		;43210___
		rol.l	#4,d1			;3210___4
		swap.w	d1			;___43210  50usあたりのdbraの回数
		subq.l	#1,d1
		move.l	d1,d2
		forlong	d0
			move.l	d2,d1
			.align	16,$2048
			forlong	d1
			next
		next
	endif
	pop
	rts
  .endif

  .endif  ;REMOVE_CRTMOD_G_CLR_ON



;----------------------------------------------------------------
;	不具合
;		_GPALETで65536色モードのパレットを正しく取得できない
;		https://stdkmd.net/bugsx68k/#rom_gpalet
;	変更前
;		00FFB740 16300000               move.b	$00(a0,d0.w),d3
;		00FFB744
;----------------------------------------------------------------
	PATCH_DATA	gpalet,$00FFB740,$00FFB743,$16300000
	move.b	2(a0,d0.w),d3



;----------------------------------------------------------------
;	不具合
;		_SYS_STATのコードが間違っている
;		https://stdkmd.net/bugsx68k/#rom_sysstat
;	変更前
;		00FFC75A 48E76000               movem.l	d1-d2,-(sp)
;			:
;		00FFC818
;----------------------------------------------------------------
	PATCH_DATA	sysstat,$00FFC75A,$00FFC817,$48E76000
	jmp	iocs_AC_SYS_STAT

;余った領域をtrap#14で使う
trap14_message:
200:
	.dc.w	204f-200b
	.dc.w	205f-200b
	.dc.w	206f-200b
	.dc.w	207f-200b
	.dc.w	208f-200b
	.dc.w	209f-200b
	.dc.w	210f-200b
	.dc.w	211f-200b
204:	.dc.b	'Illegal instruction',0
205:	.dc.b	'Zero divide',0
206:	.dc.b	'CHK instruction',0
207:	.dc.b	'TRAPV instruction',0
208:	.dc.b	'Privilege violation',0
209:	.dc.b	'Trace',0
210:	.dc.b	'Line 1010 emulator',0
211:	.dc.b	'Line 1111 emulator',0
	.even

	PATCH_TEXT
;----------------------------------------------------------------
;IOCSコール$AC _SYS_STAT システム環境の取得と設定
;<d1.w:モード
;	0	MPUステータス取得
;		>d0.l:MPUステータス
;			bit31-16	MPUの動作周波数。MHz値*10
;			bit15		FPU/FPCPの有無。0=なし,1=あり
;			bit14		MMUの有無。0=なし,1=あり
;			bit7-0		MPUの種類。0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
;	1	キャッシュ取得
;		>d0.l:現在のキャッシュの状態
;			bit1	データキャッシュは0=OFF,1=ON
;			bit0	命令キャッシュは0=OFF,1=ON
;	2	キャッシュ設定(SRAM設定値)
;		>d0.l:設定後のキャッシュの状態
;			bit1	データキャッシュを0=OFF,1=ONにした
;			bit0	命令キャッシュを0=OFF,1=ONにした
;	3	キャッシュフラッシュ
;	4	キャッシュ設定
;		<d2.l:設定後のキャッシュの状態
;			bit1	データキャッシュを0=OFF,1=ONにする
;			bit0	命令キャッシュを0=OFF,1=ONにする
;		>d0.l:設定前のキャッシュの状態
;			bit1	データキャッシュは0=OFF,1=ONだった
;			bit0	命令キャッシュは0=OFF,1=ONだった
iocs_AC_SYS_STAT:
	moveq.l	#-1,d0
	ifor	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs,<tst.w d1>,eq	;000/010はモード0以外はエラー
		if	<cmp.w #5,d1>,lo		;モード5以上はエラー
			push	d1
			add.w	d1,d1
			move.w	100f(pc,d1.w),d1
			jsr	100f(pc,d1.w)
			pop
		endif
	endif
	rts

100:
	.dc.w	mpu_status-100b		;0 MPUステータス取得
	.dc.w	cache_get-100b		;1 キャッシュ取得
	.dc.w	cache_default-100b	;2 キャッシュ設定(SRAM設定値)
	.dc.w	cache_flush-100b	;3 キャッシュフラッシュ
	.dc.w	cache_set-100b		;4 キャッシュ設定

;----------------------------------------------------------------
;MPUステータス取得
;>d0.l:MPUステータス
;	bit31-16	MPUの動作周波数。MHz値*10
;	bit15		FPU/FPCPの有無。0=なし,1=あり
;	bit14		MMUの有無。0=なし,1=あり
;	bit7-0		MPUの種類。0=68000,1=68010,2=68020,3=68030,4=68040,6=68060
mpu_status:
	move.l	BIOS_MPU_SPEED_ROM_LONG.w,d0
;	if	eq			;IPLROM 1.6以外で使うとき必要
;		move.w	BIOS_MPU_SPEED_ROM.w,d0
;	endif
	move.l	d0,-(sp)		;x1
	add.l	d0,d0			;x2
	add.l	(sp)+,d0		;x3
	add.l	d0,d0			;x6
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,lo	;68000/68010
		add.l	d0,d0			;x12
	endif
	add.l	#50,d0
	divu.w	#100,d0			;MHz値*10
;	if	vs			;6553.6MHz以上
;		moveq.l	#-1,d0
;	endif
	swap.w	d0			;ssssssss ssssssss ........ ........
	clr.w	d0			;ssssssss ssssssss 00000000 00000000
	tst.b	BIOS_MMU_TYPE.w
	sne.b	d0			;ssssssss ssssssss 00000000 mmmmmmmm
	ror.w	#1,d0			;ssssssss ssssssss m0000000 0mmmmmmm
	tst.b	BIOS_FPU_TYPE.w
	sne.b	d0			;ssssssss ssssssss m0000000 ffffffff
	ror.w	#1,d0			;ssssssss ssssssss fm000000 0fffffff
	move.b	BIOS_MPU_TYPE.w,d0	;ssssssss ssssssss fm000000 pppppppp
	rts

;----------------------------------------------------------------
;キャッシュ取得
;>d0.l:現在のキャッシュの状態
;	bit1	データキャッシュは0=OFF,1=ON
;	bit0	命令キャッシュは0=OFF,1=ON
;	000/010のときは0を返す
cache_get:
	moveq.l	#0,d0
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		.cpu	68030
		movec.l	cacr,d0
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
							;........ ........ .......d .......i
			ror.l	#1,d0			;i....... ........ ........ d.......
			rol.b	#1,d0			;i....... ........ ........ .......d
		else				;040/060
							;d....... ........ i....... ........
			swap.w	d0			;i....... ........ d....... ........
			rol.w	#1,d0			;i....... ........ ........ .......d
		endif
		rol.l	#1,d0			;........ ........ ........ ......di
		and.l	#3,d0			;00000000 00000000 00000000 000000di
		.cpu	68000
	endif
	rts

;----------------------------------------------------------------
;キャッシュ設定(SRAM設定値)
;>d0.l:設定後のキャッシュの状態
;	bit1	データキャッシュを0=OFF,1=ONにした
;	bit0	命令キャッシュを0=OFF,1=ONにした
;	000/010のときは0を返す
cache_default:
	push	d2
	moveq.l	#0,d2
	move.b	SRAM_CACHE,d2		;キャッシュ設定。------|データ|命令
	bsr	cache_set		;キャッシュ設定
	pop
	rts

;----------------------------------------------------------------
;キャッシュフラッシュ
cache_flush:
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		.cpu	68030
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
			push	d0
			movec.l	cacr,d0
			or.w	#$0808,d0
			movec.l	d0,cacr
		;	and.w	#$F7F7,d0
		;	movec.l	d0,cacr
			pop
		else				;040/060
			.cpu	68040
			cpusha	bc
		endif
		.cpu	68000
	endif
	rts

;----------------------------------------------------------------
;キャッシュ設定
;<d2.l:設定後のキャッシュの状態
;	bit1	データキャッシュを0=OFF,1=ONにする
;	bit0	命令キャッシュを0=OFF,1=ONにする
;	000/010のときは何もしない
;>d0.l:設定前のキャッシュの状態
;	bit1	データキャッシュは0=OFF,1=ONだった
;	bit0	命令キャッシュは0=OFF,1=ONだった
;	000/010のときは0を返す
cache_set:
	moveq.l	#0,d0
	if	<cmpi.b #2,BIOS_MPU_TYPE.w>,hs	;020/030/040/060
		.cpu	68030
		push	d1-d3
		moveq.l	#3,d3			;d3 00000000 00000000 00000000 00000011
		and.l	d3,d2			;d2 00000000 00000000 00000000 000000di
		ror.l	#1,d2			;   i0000000 00000000 00000000 0000000d
		movec.l	cacr,d0
		if	<cmpi.b #4,BIOS_MPU_TYPE.w>,lo	;020/030
							;d0 ........ ........ .......d .......i
			neg.w	d2			;d2 i0000000 00000000 dddddddd dddddddd
			and.w	#$2101.shr.1,d2		;   i0000000 00000000 000d0000 d0000000
			rol.l	#1,d2			;   00000000 00000000 00d0000d 0000000i
			move.l	d0,d1			;d1 ........ ........ .......d .......i
			and.w	#.notw.$2101,d1		;   ........ ........ ..0....0 .......0
			or.w	d2,d1			;   ........ ........ ..d....d .......i
			movec.l	d1,cacr
			ror.l	#1,d0			;d0 i....... ........ ........ d.......
			rol.b	#1,d0			;   i....... ........ ........ .......d
		else				;040/060
							;d0 d....... ........ i....... ........
			.cpu	68040
			ror.w	#1,d2			;d2 i0000000 00000000 d0000000 00000000
			swap.w	d2			;   d0000000 00000000 i0000000 00000000
			move.l	d0,d1			;d1 d....... ........ i....... ........
			and.l	#.not.$80008000,d1	;   0....... ........ 0....... ........
			or.l	d2,d1			;   d....... ........ i....... ........
			movec.l	d1,cacr
			not.l	d2
			and.l	d0,d2			;設定前&~設定後
			if	mi			;データキャッシュがON→OFF
				cpusha	dc			;データキャッシュをプッシュして無効化
			endif
			if	<tst.w d2>,mi		;命令キャッシュがON→OFF
				cinva	ic			;命令キャッシュと分岐キャッシュを無効化
			endif
			swap.w	d0			;d0 i....... ........ d....... ........
			rol.w	#1,d0			;   i....... ........ ........ .......d
		endif
		rol.l	#1,d0			;   ........ ........ ........ ......di
		and.l	d3,d0			;   00000000 00000000 00000000 000000di
		pop
		.cpu	68000
	endif
	rts

;----------------------------------------------------------------
;キャッシュOFF
;>d0.l:設定前のキャッシュの状態
;	bit1	データキャッシュは0=OFF,1=ONだった
;	bit0	命令キャッシュは0=OFF,1=ONだった
;	000/010のときは0を返す
cache_off:
	push	d2
	moveq.l	#0,d2
	bsr	cache_set		;キャッシュ設定
	pop
	rts

;----------------------------------------------------------------
;データキャッシュOFF,命令キャッシュON
;>d0.l:設定前のキャッシュの状態
;	bit1	データキャッシュは0=OFF,1=ONだった
;	bit0	命令キャッシュは0=OFF,1=ONだった
;	000/010のときは0を返す
cache_on_i:
	push	d2
	moveq.l	#1,d2			;データキャッシュOFF,命令キャッシュON
	bsr	cache_set		;キャッシュ設定
	pop
	rts



;----------------------------------------------------------------
;
;	_SP_INIT でバスエラーが発生する (IPLROM 1.0/1.1/1.2/1.3)
;	https://stdkmd.net/bugsx68k/#rom_spinit
;
;	症状
;	スプライトを表示できないとき _SP_INIT が -1 を返さずバスエラーで止まることがある。
;
;	発生条件
;	画面モード 18 (1024x848) または画面モード 19 (640x480; VGA モード) で _SP_INIT を呼び出したとき。
;
;	原因
;	ハードウェアの制約で、CRTC の R20 ($00E80028) の下位 5 ビットが %1??1? のとき、スプライトを表示できない。
;	スプライトを表示できないとき、スプライトスクロールレジスタ ($00EB0000～$00EB07FF) または
;	スプライト PCG・テキストエリア ($00EB8000～$00EBFFFF) にアクセスすると、バスエラーが発生する。
;	スプライト関連の IOCS コールは、画面モード 16 (768x512) と画面モード 17 (1024x424) の %10110 のときだけ、スプライトを表示できないと判断する。
;	画面モード 18 の %11010 と画面モード 19 の %10111 を含む %1001? と %10111 と %11?1? はスプライトを表示できると誤って判断され、
;	_SP_INIT がアクセスできないスプライトスクロールレジスタを初期化しようとしてバスエラーが発生する。
;
;	補足
;	画面モード 17 (1024x424) と画面モード 18 (1024x848) は IPLROM 1.0 からあるが未公開。
;	画面モード 19 (640x480; VGA モード) は X68000 Compact の IPLROM 1.2 で追加された。
;
;	メモ
;	このバスエラーはエミュレータでは再現されないことがある。
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;	変更前
;		00FFCC9E 303900E80028           move.w	$00E80028,d0		;[$00E80028].w:CRTC R20 メモリモード/解像度(高解像度|垂直解像度|水平解像度)
;		00FFCCA4 024000FF               andi.w	#$00FF,d0
;		00FFCCA8 0C400016               cmpi.w	#$0016,d0
;		00FFCCAC 6606                   bne.s	$00FFCCB4
;		00FFCCAE 70FF                   moveq.l	#$FF,d0
;		00FFCCB0 588F                   addq.l	#4,sp
;		00FFCCB2 4E75                   rts
;
;		00FFCCB4 7000                   moveq.l	#$00,d0
;		00FFCCB6 4E75                   rts
;
;		00FFCCB8
;----------------------------------------------------------------

	PATCH_DATA	spinit,$00FFCC9E,$00FFCCB7,$303900E8
;スプライトを表示できるか
;	スプライト関連のIOCSコールの先頭で呼び出される
;	表示できないときは-1を返してIOCSコールから復帰する
;>d0.l:0=スプライトを表示できる,-1=スプライトを表示できない
	moveq.l	#%10010,d0
	and.w	$00E80028,d0		;CRTC R20
	if	<cmp.w #%10010,d0>,eq	;%1??1?。スプライトを表示できない
		moveq.l	#-1,d0			;スプライトを表示できない
		addq.l	#4,sp			;IOCSコールから復帰する
	else				;その他。スプライトを表示できる
		moveq.l	#0,d0			;スプライトを表示できる
	endif
	rts



;----------------------------------------------------------------
;
;	グラフィック関係のIOCSコールがリバースモードになったままになる
;	https://stdkmd.net/bugsx68k/#rom_drawmode
;
;----------------------------------------------------------------

;----------------------------------------------------------------
;	変更前
;		00FFDCEA B07CFFFF               cmp.w	#$FFFF,d0
;		00FFDCEE
;----------------------------------------------------------------

	PATCH_DATA	drawmode,$00FFDCEA,$00FFDCED,$B07CFFFF
	cmp.w	#-1,d1



;----------------------------------------------------------------
;
;	プロポーショナルピッチコンソール
;	改良というより魔改造
;	動作は遅く、編集は困難になる
;
;----------------------------------------------------------------

  .if USE_PROPORTIONAL_IOCS

	PATCH_DATA	timer_c_cursor,$00FF1D8C,$00FF1D91,$4A380992
	jmp	timer_c_cursor

	PATCH_DATA	iocs_1E_B_CURON,$00FF79CE,$00FF79D3,$4A380993
	jmp	iocs_1E_B_CURON

	PATCH_DATA	iocs_1F_B_CUROFF,$00FF79EA,$00FF79EF,$4A380993
	jmp	iocs_1F_B_CUROFF

	PATCH_DATA	iocs_20_B_PUTC,$00FF96AE,$00FF96B3,$2F016100
	jmp	iocs_20_B_PUTC

	PATCH_DATA	iocs_21_B_PRINT,$00FF96BC,$00FF96C3,$48E74020
	jmp	iocs_21_B_PRINT

	PATCH_DATA	iocs_22_B_COLOR,$00FF96D8,$00FF96DD,$700041F8
	jmp	iocs_22_B_COLOR

	PATCH_DATA	iocs_23_B_LOCATE,$00FF96F4,$00FF96FB,$20380974
	jmp	iocs_23_B_LOCATE

	PATCH_DATA	iocs_24_B_DOWN_S,$00FF9724,$00FF972B,$6100E2C4
	jmp	iocs_24_B_DOWN_S

	PATCH_DATA	iocs_25_B_UP_S,$00FF9730,$00FF9737,$6100E2B8
	jmp	iocs_25_B_UP_S

	PATCH_DATA	iocs_26_B_UP,$00FF973C,$00FF9741,$2F016100
	jmp	iocs_26_B_UP

	PATCH_DATA	iocs_27_B_DOWN,$00FF9748,$00FF974D,$2F016100
	jmp	iocs_27_B_DOWN

	PATCH_DATA	iocs_28_B_RIGHT,$00FF9754,$00FF9759,$2F016100
	jmp	iocs_28_B_RIGHT

	PATCH_DATA	iocs_29_B_LEFT,$00FF9760,$00FF9765,$2F016100
	jmp	iocs_29_B_LEFT

	PATCH_DATA	iocs_2A_B_CLR_ST,$00FF9772,$00FF9779,$48E77848
	jmp	iocs_2A_B_CLR_ST

	PATCH_DATA	iocs_2B_B_ERA_ST,$00FF9780,$00FF9787,$48E77848
	jmp	iocs_2B_B_ERA_ST

	PATCH_DATA	iocs_2C_B_INS,$00FF9796,$00FF979D,$48E77F78
	jmp	iocs_2C_B_INS

	PATCH_DATA	iocs_2D_B_DEL,$00FF97A4,$00FF97AB,$48E77F78
	jmp	iocs_2D_B_DEL

	PATCH_DATA	iocs_2E_B_CONSOL,$00FF97BA,$00FF97C1,$6100E22E
	jmp	iocs_2E_B_CONSOL

	PATCH_DATA	iocs_AE_OS_CURON,$00FFC87E,$00FFC883,$31F809BA
	jmp	iocs_AE_OS_CURON

	PATCH_DATA	iocs_AF_OS_CUROF,$00FFC8AC,$00FFC8B1,$4EB900FF
	jmp	iocs_AF_OS_CUROF

  .endif

	PATCH_TEXT



;コンソール拡張
BIOS_ATTRIBUTE_2	equ	$0D30		;.b 文字属性2。-|上付き|下付き|上線|丸囲み|四角囲み|プロポーショナル|波線
BIOS_SUPERSCRIPT_BIT	equ	 6		;上付き
BIOS_SUPERSCRIPT	equ	%01000000
BIOS_SUBSCRIPT_BIT	equ	  5		;下付き
BIOS_SUBSCRIPT		equ	%00100000
BIOS_OVERLINE_BIT	equ	    4		;上線
BIOS_OVERLINE		equ	%00010000
BIOS_ENCIRCLE_BIT	equ	     3		;丸囲み
BIOS_ENCIRCLE		equ	%00001000
BIOS_FRAME_BIT		equ	      2		;四角囲み
BIOS_FRAME		equ	%00000100
BIOS_PROPORTIONAL_BIT	equ	       1	;プロポーショナル
BIOS_PROPORTIONAL	equ	%00000010
BIOS_WAVELINE_BIT	equ	        0	;波線
BIOS_WAVELINE		equ	%00000001
BIOS_CURSOR_FRACTION	equ	$0D31		;.b カーソルの桁座標の端数。0～7
BIOS_SAVED_ATTRIBUTE_2	equ	$0D32		;.b ESC [sで保存された文字属性2
BIOS_SAVED_FRACTION	equ	$0D33		;.b ESC [sで保存されたカーソルの桁座標の端数
BIOS_BUFFER_REQUEST	equ	$0D34		;.w バッファの文字列を表示する領域のドット幅。0=バッファ出力中ではない
BIOS_BUFFER_WIDTH	equ	$0D36		;.w バッファの文字列のドット幅
BIOS_BUFFER_POINTER	equ	$0D38		;.l バッファの書き込み位置
BIOS_BUFFER_ARRAY	equ	$0D3C		;.w[64] バッファ。右寄せ、中央寄せで使う
BIOS_CONSOLE_STATUS	equ	$0DBC		;.b コンソールの状態。----|左寄せ|中央寄せ|右寄せ|連結
BIOS_ALIGN_LEFT_BIT	equ	     3		;左寄せ
BIOS_ALIGN_LEFT		equ	%00001000
BIOS_ALIGN_CENTER_BIT	equ	      2		;中央寄せ
BIOS_ALIGN_CENTER	equ	%00000100
BIOS_ALIGN_RIGHT_BIT	equ	       1	;右寄せ
BIOS_ALIGN_RIGHT	equ	%00000010
BIOS_CONNECTION_BIT	equ	        0	;連結。最後に描画した文字は斜体でその後カーソルを動かしていない。次も斜体ならば詰めて描画する
BIOS_CONNECTION		equ	%00000001
;				$0DBD		;.b[3]

;----------------------------------------------------------------
;カーソル点滅処理ルーチン
;	Timer-C割り込みルーチンから500ms間隔で呼ばれる
timer_c_cursor:
	if	<tst.b BIOS_CURSOR_ON.w>,ne	;カーソルを表示するとき
		ifor	<tst.w BIOS_CURSOR_NOT_BLINK.w>,eq,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;点滅させるか、描かれていないとき
			if	<btst.b #1,CRTC_ACCESS>,eq	;CRTCのマスクが使用中でないとき
				bsr	toggle_cursor		;カーソルを反転させる
				not.b	BIOS_CURSOR_DRAWN.w	;カーソルが描かれているか。0=描かれていない,-1=描かれている
			endif
		endif
	endif
	rts

;----------------------------------------------------------------
;カーソルを反転させる
toggle_cursor:
	push	d0-d2/a0-a2
	move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
	swap.w	d0
	clr.w	d0			;65536*行座標
	lsr.l	#5,d0			;128*16*行座標
	move.w	BIOS_CURSOR_COLUMN.w,d1	;カーソルの桁座標
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d1	;右端で止まる
	endif
	add.w	d1,d0
	add.l	BIOS_CONSOLE_OFFSET.w,d0
	add.l	#$00E00000,d0		;カーソルのアドレス
	movea.l	d0,a2
	move.w	CRTC_ACCESS,-(sp)
	bclr.b	#0,CRTC_ACCESS		;同時アクセスOFF
***	move.w	BIOS_CURSOR_PATTERN.w,d1
***	if	eq
***		moveq.l	#-1,d1
***	endif
	moveq.l	#$80,d1
	move.b	BIOS_CURSOR_FRACTION.w,d0
	lsr.b	d0,d1
	bsr	toggle_cursor_1		;プレーン0を反転
***	lsr.w	#8,d1
	adda.l	#$00020000,a2
	bsr	toggle_cursor_1		;プレーン1を反転
	move.w	(sp)+,CRTC_ACCESS
	pop
	rts

toggle_cursor_1:
	move.w	BIOS_CURSOR_START.w,d2	;カーソル描画開始ライン*4
	jmp	@f(pc,d2.w)
@@:	eor.b	d1,(a2)
	movea.l	a0,a0			;nop
  .irp row,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
	eor.b	d1,128*row(a2)
  .endm
	rts

;----------------------------------------------------------------
;IOCSコール$1E _B_CURON カーソルを表示する
iocs_1E_B_CURON:
	ifand	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq,<tst.b BIOS_CURSOR_ON.w>,eq	;許可されていて表示していないとき
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;タイマカウンタ。1回目を10ms*5=50ms後に発生させる
		st.b	BIOS_CURSOR_ON.w	;表示している
		clr.b	BIOS_CURSOR_DRAWN.w	;描かれていない
	endif
	rts

;----------------------------------------------------------------
;IOCSコール$1F _B_CUROFF カーソルを表示しない
iocs_1F_B_CUROFF:
	if	<tst.b BIOS_CURSOR_PROHIBITED.w>,eq	;許可されているとき
		move.w	#5,BIOS_TC_CURSOR_COUNTER.w	;タイマカウンタ。1回目を10ms*5=50ms後に発生させる
		clr.b	BIOS_CURSOR_ON.w	;表示していない
		if	<tst.b BIOS_CURSOR_DRAWN.w>,ne	;描かれているとき
			bsr	toggle_cursor		;カーソルを反転させる
			clr.b	BIOS_CURSOR_DRAWN.w	;描かれていない
		endif
	endif
	rts

;----------------------------------------------------------------
;IOCSコール$20 _B_PUTC 文字を表示する
;<d1.w:文字コード
;>d0.l:表示後のカーソルの桁座標<<16|カーソルの行座標
iocs_20_B_PUTC:
	bsr	putc			;1文字表示
	move.l	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標<<16|カーソルの行座標
	rts

;----------------------------------------------------------------
;IOCSコール$21 _B_PRINT 文字列を表示する
;<a1.l:文字列のアドレス
;>d0.l:表示後のカーソルの桁座標<<16|カーソルの行座標
;>a1.l:文字列の末尾の0の次のアドレス。マニュアルに書いてある。変更不可
iocs_21_B_PRINT:
	push	d1
	dostart
		bsr	putc			;1文字表示
	start
		moveq.l	#0,d1
		move.b	(a1)+,d1
	while	ne
	pop
	move.l	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標<<16|カーソルの行座標
	rts

;----------------------------------------------------------------
;IOCSコール$22 _B_COLOR 文字属性を設定する
;<d1.w:文字属性。-1=取得のみ
;	0	黒
;	1	水色
;	2	黄色
;	3	白
;	4+	太字
;	8+	反転
;>d0.l:設定前の文字属性。-1=設定値が範囲外
iocs_22_B_COLOR:
	push	d1
	moveq.l	#0,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;文字属性2。-|上付き|下付き|上線|丸囲み|四角囲み|プロポーショナル|波線
	lsl.w	#8,d0
	move.b	BIOS_ATTRIBUTE_1.w,d0	;文字属性1。取り消し線|下線|斜体|細字|反転|太字|プレーン##
	if	<cmp.w #-1,d1>,ne	;設定するとき
		if	<cmp.w #$7FFF,d1>,ls	;設定値が範囲内のとき
			move.b	d1,BIOS_ATTRIBUTE_1.w
			lsr.w	#8,d1
			move.b	d1,BIOS_ATTRIBUTE_2.w
		else				;設定値が範囲外のとき
			moveq.l	#-1,d0
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$23 _B_LOCATE カーソルの座標を設定する
;<d1.w:カーソルの桁座標の端数<<8|カーソルの桁座標。-1=取得のみ
;<d2.w:カーソルの行座標
;>d0.l:設定前のカーソルの座標。カーソルの桁座標の端数<<24|カーソルの桁座標<<16|カーソルの行座標。-1=設定値が範囲外
;>d1.l:(IOCS.X,1.3以上)取得のみのときd0.lと同じ
iocs_23_B_LOCATE:
	moveq.l	#0,d0
	move.b	BIOS_CURSOR_FRACTION.w,d0
	ror.l	#8,d0
	or.l	BIOS_CURSOR_COLUMN.w,d0	;BIOS_CURSOR_ROW。カーソルの桁座標の端数<<24|カーソルの桁座標<<16|カーソルの行座標
	if	<cmp.w #-1,d1>,eq	;取得のみ
		move.l	d0,d1
		rts
	endif
	push	d1/d3
	move.w	d1,d3
	and.w	#$00FF,d1		;カーソルの桁座標
	lsr.w	#8,d3			;カーソルの桁座標の端数
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls,<cmp.w #7,d3>,ls	;設定値が範囲内のとき
;		push	d0
		bsr	iocs_1F_B_CUROFF
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		move.b	d3,BIOS_CURSOR_FRACTION.w
		bsr	iocs_1E_B_CURON
;		pop	d0
	else				;設定値が範囲外のとき
		moveq.l	#-1,d0
	endif
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$24 _B_DOWN_S カーソルを1行下へ。下端ではスクロールアップ
;>d0.l:0
iocs_24_B_DOWN_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$25 _B_UP_S カーソルを1行上へ。上端ではスクロールダウン
;>d0.l:0
iocs_25_B_UP_S:
	push	d1-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi	;上端ではないとき
		subq.w	#1,d0			;1行上へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;上端のとき
		moveq.l	#0,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;コピー元の下端の行座標
		moveq.l	#1,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		moveq.l	#0,d0			;上端の行座標
		moveq.l	#0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$26 _B_UP カーソルをn行上へ。上端を超えるときは動かない
;<d1.b:移動する行数。0=1行
;>d0.l:0=成功,-1=失敗。上端を超える。このときカーソルは動かない
iocs_26_B_UP:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
	sub.w	d1,d0			;n行上へ
	if	mi			;上端を超える
		moveq.l	#-1,d1
	else				;上端を超えない
		move.w	d0,BIOS_CURSOR_ROW.w
		moveq.l	#0,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$27 _B_DOWN カーソルをn行下へ。下端で止まる
;<d1.b:移動する行数。0=1行
;>d0.l:0
iocs_27_B_DOWN:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
	add.w	d1,d0			;n行下へ
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;下端を超える
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;下端で止まる
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$28 _B_RIGHT カーソルをn桁右へ。右端で止まる
;<d1.w:移動する桁数。0=1桁
;>d0.l:0
iocs_28_B_RIGHT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標
	add.w	d1,d0			;n行右へ
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;右端を超える
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;右端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$29 _B_LEFT カーソルをn桁左へ。左端で止まる
;<d1.w:移動する桁数。0=1桁
;>d0.l:0
iocs_29_B_LEFT:
	push	d1
	bsr	iocs_1F_B_CUROFF
	and.w	#$00FF,d1
	if	eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標
	sub.w	d1,d0			;n行左へ
	if	mi			;左端を超える
		clr.w	d0			;左端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$2A _B_CLR_ST 範囲を選択して画面を消去
;<d1.b:範囲。0=カーソルから右下まで,1=左上からカーソルまで,2=左上から右下まで。カーソルを左上へ
;>d0.l:0=成功,-1=失敗。引数がおかしい
iocs_2A_B_CLR_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=カーソルから右下まで
		bsr	putc_csi_0J		;ESC [0J カーソルから右下まで消去する
		moveq.l	#0,d1
	elif	eq			;1=左上からカーソルまで
		bsr	putc_csi_1J		;ESC [1J 左上からカーソルまで消去する
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=左上から右下まで
		bsr	putc_csi_2J		;ESC [2J 左上から右下まで消去する。カーソルを左上へ
		moveq.l	#0,d1
	else
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2B _B_ERA_ST 範囲を選択して行を消去
;<d1.b:範囲。0=カーソルから右端まで,1=左端からカーソルまで,2=左端から右端まで
;>d0.l:0=成功,-1=失敗。引数がおかしい
iocs_2B_B_ERA_ST:
	push	d1
	bsr	iocs_1F_B_CUROFF
	if	<subq.b #1,d1>,lo	;0=カーソルから右端まで
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
		moveq.l	#0,d1
	elif	eq			;1=左端からカーソルまで
		bsr	putc_csi_1K		;ESC [1K 左端からカーソルまで消去する
		moveq.l	#0,d1
	elif	<subq.b #3-1,d1>,lo	;2=左端から右端まで
		bsr	putc_csi_2K		;ESC [2K 左端から右端まで消去する
		moveq.l	#0,d1
	else				;引数がおかしい
		moveq.l	#-1,d1
	endif
	bsr	iocs_1E_B_CURON
	move.l	d1,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2C _B_INS カーソルから下にn行挿入。カーソルを左端へ
;<d1.w:挿入する行数。0=1行
;>d0.l:0
iocs_2C_B_INS:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_L		;ESC [nL カーソルから下にn行挿入。カーソルを左端へ
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2D _B_DEL カーソルから下をn行削除。カーソルを左端へ
;<d1.w:削除する行数。0=1行
;>d0.l:0
iocs_2D_B_DEL:
	push	d1
	bsr	iocs_1F_B_CUROFF
	bsr	putc_csi_M		;ESC [nM カーソルから下をn行削除。カーソルを左端へ
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCSコール$2E _B_CONSOL コンソールの範囲を設定。カーソルを左上へ
;<d1.l:左上Xドット座標<<16|左上Yドット座標。-1=取得のみ。左上Xドット座標は8の倍数、左上Yドット座標は4の倍数
;<d2.l:右端の桁座標<<16|下端の行座標。-1=取得のみ
;>d0.l:0
;>d1.l:設定前の左上Xドット座標<<16|左上Yドット座標
;>d2.l:設定前の右端の桁座標<<16|下端の行座標
iocs_2E_B_CONSOL:
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CONSOLE_OFFSET.w,d0
	if	<cmp.l #-1,d1>,ne
		and.l	#($03F8<<16)|$03FC,d1
		move.l	d1,d0
		swap.w	d0		;左上Xドット座標
		lsr.w	#3,d0		;左上Xドット座標/8
		ext.l	d1
		lsl.l	#7,d1		;左上Yドット座標*128
		add.w	d0,d1
		move.l	BIOS_CONSOLE_OFFSET.w,d0
		move.l	d1,BIOS_CONSOLE_OFFSET.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w。カーソルを左上へ
	endif
	moveq.l	#127,d1
	and.w	d0,d1			;左上Xドット座標/8
	lsl.w	#3,d1			;左上Xドット座標
	swap.w	d1
	lsr.l	#7,d0			;左上Yドット座標
	move.w	d0,d1			;設定前の左上Xドット座標<<16|左上Yドット座標
	move.l	BIOS_CONSOLE_RIGHT.w,d0	;BIOS_CONSOLE_BOTTOM.w
	if	<cmp.l #-1,d2>,ne
		and.l	#127<<16|63,d2
		move.l	d2,BIOS_CONSOLE_RIGHT.w	;BIOS_CONSOLE_BOTTOM.w
		clr.l	BIOS_CURSOR_COLUMN.w	;BIOS_CURSOR_ROW.w。カーソルを左上へ
	endif
	move.l	d0,d2			;設定前の右端の桁座標<<16|下端の行座標
	bsr	iocs_1E_B_CURON
	moveq.l	#0,d0
	rts

;----------------------------------------------------------------
;IOCSコール$AE _OS_CURON カーソルの表示を許可する
iocs_AE_OS_CURON:
	move.w	BIOS_TC_CURSOR_PERIOD.w,BIOS_TC_CURSOR_COUNTER.w	;タイマカウンタを初期値にする
	di				;割込み禁止
	ifor	<tst.b BIOS_CURSOR_PROHIBITED.w>,ne,<tst.b BIOS_CURSOR_DRAWN.w>,eq	;禁止されているか描かれていないとき
		bsr	toggle_cursor		;カーソルを反転させる
		st.b	BIOS_CURSOR_DRAWN.w	;描かれている
	endif
	st.b	BIOS_CURSOR_ON.w		;表示している
	sf.b	BIOS_CURSOR_PROHIBITED.w	;許可されている
	ei				;割り込み許可
	rts

;----------------------------------------------------------------
;IOCSコール$AF _OS_CUROF カーソルの表示を禁止する
iocs_AF_OS_CUROF:
	bsr	iocs_1F_B_CUROFF
	st.b	BIOS_CURSOR_PROHIBITED.w	;禁止されている
	rts

;----------------------------------------------------------------
;1文字表示
;<d1.w:文字コード
putc:
	push	d0-d1
	if	<move.b BIOS_PUTC_POOL.w,d0>,eq	;1バイト目のとき
		if	<cmp.w #$001F,d1>,ls	;$0000～$001Fのとき
			bsr	putc_control		;制御文字を処理する
		elif	<cmp.w #$007F,d1>,ls	;$0020～$007Fのとき
			if	<cmp.w #$005C,d1>,eq	;$005Cのとき
				if	<btst.b #0,SRAM_XCHG>,ne	;文字変換フラグ。-----|$7C｜/$82￤|$7E￣/$81～|$5C￥/$80＼
					move.w	#$0080,d1		;$5C→$80
				endif
			elif	<cmp.w #$007E,d1>,eq	;$007Eのとき
				if	<btst.b #1,SRAM_XCHG>,ne	;文字変換フラグ。-----|$7C｜/$82￤|$7E￣/$81～|$5C￥/$80＼
					move.w	#$0081,d1		;$7E→$81
				endif
			elif	<cmp.w #$007C,d1>,eq	;$007Cのとき
				if	<btst.b #2,SRAM_XCHG>,ne	;文字変換フラグ。-----|$7C｜/$82￤|$7E￣/$81～|$5C￥/$80＼
					move.w	#$0082,d1		;$7C→$82
				endif
			endif
			bsr	putc_output		;画面に描くまたはバッファに出力する
		elif	<cmp.w #$009F,d1>,ls	;$0080～$009Fのとき
			move.b	d1,BIOS_PUTC_POOL.w	;1バイト目のプール
		elif	<cmp.w #$00DF,d1>,ls	;$00A0～$00DFのとき
			bsr	putc_output		;画面に描くまたはバッファに出力する
		elif	<cmp.w #$00FF,d1>,ls	;$00E0～$00FFのとき
			move.b	d1,BIOS_PUTC_POOL.w	;1バイト目のプール
		else				;$0100～$FFFFのとき
			bsr	putc_output		;画面に描くまたはバッファに出力する
		endif
	else				;2バイト目のとき
		if	<cmp.b #$1B,d0>,eq	;1バイト目が$1Bのとき。エスケープシーケンスの出力中
			bsr	putc_escape		;エスケープシーケンスを処理する
		else				;1バイト目が$1Bではないとき
			clr.b	BIOS_PUTC_POOL.w	;1バイト目を消費する
			lsl.w	#8,d0			;1バイト目<<8
			move.b	d1,d0			;1バイト目<<8|2バイト目
			move.w	d0,d1			;1バイト目<<8|2バイト目。1バイト目があるときd1.wの上位バイトは無視される
			bsr	putc_output		;画面に描くまたはバッファに出力する
		endif
	endif
	pop
	rts

;----------------------------------------------------------------
;バッファ出力を終了する
putc_finish_buffer:
	push	d0-d6/a0-a1
	move.w	BIOS_BUFFER_REQUEST.w,d0
	goto	eq,putc_finish_buffer_end	;バッファ出力中ではない
;<d0.w:バッファの文字列を表示する領域のドット幅
	move.w	BIOS_BUFFER_WIDTH.w,d1
;<d1.w:バッファの文字列のドット幅
	movea.l	BIOS_BUFFER_POINTER.w,a0
;<a0.l:バッファの書き込み位置=文字列の直後
	lea.l	BIOS_BUFFER_ARRAY.w,a1
;<a1.l:バッファ=文字列の先頭
	clr.w	BIOS_BUFFER_REQUEST.w	;バッファ出力終了。再帰呼び出しで表示するのでその前に終了すること
	clr.w	BIOS_BUFFER_WIDTH.w
	move.l	a1,BIOS_BUFFER_POINTER.w
	sub.w	d1,d0			;余るドット数
;<d0.w:余るドット数
	if	ls			;余らないとき
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;左寄せで余るとき
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;右側の余った範囲を消去する
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	elif	<bclr.b #BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w>,ne	;右寄せで余るとき
	;左側の余った範囲を消去する
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	elif	<bclr.b #BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w>,ne	;中央寄せで余るとき
	;左側の余った範囲を消去する
		move.w	d0,d6
		lsr.w	#1,d0			;左側の余った範囲のドット幅
		sub.w	d0,d6			;右側の余った範囲のドット幅
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	;文字列を表示する
		do
			move.w	(a1)+,d1
			bsr	putc_output
		while	<cmpa.w a0,a1>,lo
	;右側の余った範囲を消去する
		move.w	d6,d0
		moveq.l	#0,d4
		move.b	BIOS_CURSOR_FRACTION.w,d4	;d4=左端の桁座標の端数
		add.w	d4,d0
		subq.w	#1,d0
		moveq.l	#7,d5
		and.w	d0,d5				;d5=右端の桁座標の端数
		lsr.w	#3,d0
		move.w	BIOS_CURSOR_COLUMN.w,d2		;d2=左端の桁座標
		add.w	d2,d0
		move.w	d0,d3				;d3=右端の桁座標
		move.w	BIOS_CURSOR_ROW.w,d0		;d0=上端の行座標
		move.w	d0,d1				;d1=下端の行座標
		bsr	putc_clear
	;カーソルを動かす
		addq.w	#1,d5
		if	<cmp.w #8,d5>,hs
			subq.w	#8,d5
			addq.w	#1,d3
		endif
		move.w	d3,BIOS_CURSOR_COLUMN.w
		move.b	d5,BIOS_CURSOR_FRACTION.w
	endif
putc_finish_buffer_end:
	pop
	rts

;----------------------------------------------------------------
;制御文字を処理する
;<d1.w:文字コード
putc_control:
	push	d0-d1
;バッファ出力を終了する
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;バッファ出力中
		bsr	putc_finish_buffer	;バッファ出力を終了する
	endif
;カーソルが右端からはみ出しているときBSでなければ改行する
	move.w	BIOS_CURSOR_COLUMN.w,d0	;カーソルの桁座標
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi,<cmp.w #$0008,d1>,ne	;カーソルが右端からはみ出しているかつBSではないとき
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;制御文字を処理する
	add.w	d1,d1
	move.w	putc_control_jump_table(pc,d1.w),d1
	jsr	putc_control_jump_table(pc,d1.w)
	pop
	rts

putc_control_jump_table:
	.dc.w	putc_00_NL-putc_control_jump_table	;制御文字$00 NL 
	.dc.w	putc_01_SH-putc_control_jump_table	;制御文字$01 SH 
	.dc.w	putc_02_SX-putc_control_jump_table	;制御文字$02 SX 
	.dc.w	putc_03_EX-putc_control_jump_table	;制御文字$03 EX 
	.dc.w	putc_04_ET-putc_control_jump_table	;制御文字$04 ET 
	.dc.w	putc_05_EQ-putc_control_jump_table	;制御文字$05 EQ 
	.dc.w	putc_06_AK-putc_control_jump_table	;制御文字$06 AK 
	.dc.w	putc_07_BL-putc_control_jump_table	;制御文字$07 BL ベルを鳴らす
	.dc.w	putc_08_BS-putc_control_jump_table	;制御文字$08 BS カーソルを1桁左へ。左端では1行上の右端へ。上端では何もしない
	.dc.w	putc_09_HT-putc_control_jump_table	;制御文字$09 HT カーソルを次のタブ桁へ。なければ1行下の左端へ。下端ではスクロールアップして左端へ
	.dc.w	putc_0A_LF-putc_control_jump_table	;制御文字$0A LF カーソルを1行下へ。下端ではスクロールアップ
	.dc.w	putc_0B_VT-putc_control_jump_table	;制御文字$0B VT カーソルを1行上へ。上端では何もしない
	.dc.w	putc_0C_FF-putc_control_jump_table	;制御文字$0C FF カーソルを1桁右へ。右端では1行下の左端へ。下端ではスクロールアップして左端へ
	.dc.w	putc_0D_CR-putc_control_jump_table	;制御文字$0D CR カーソルを左端へ
	.dc.w	putc_0E_SO-putc_control_jump_table	;制御文字$0E SO 
	.dc.w	putc_0F_SI-putc_control_jump_table	;制御文字$0F SI 
	.dc.w	putc_10_DE-putc_control_jump_table	;制御文字$10 DE 
	.dc.w	putc_11_D1-putc_control_jump_table	;制御文字$11 D1 
	.dc.w	putc_12_D2-putc_control_jump_table	;制御文字$12 D2 
	.dc.w	putc_13_D3-putc_control_jump_table	;制御文字$13 D3 
	.dc.w	putc_14_D4-putc_control_jump_table	;制御文字$14 D4 
	.dc.w	putc_15_NK-putc_control_jump_table	;制御文字$15 NK 
	.dc.w	putc_16_SN-putc_control_jump_table	;制御文字$16 SN 
	.dc.w	putc_17_EB-putc_control_jump_table	;制御文字$17 EB 
	.dc.w	putc_18_CN-putc_control_jump_table	;制御文字$18 CN 
	.dc.w	putc_19_EM-putc_control_jump_table	;制御文字$19 EM 
	.dc.w	putc_1A_SB-putc_control_jump_table	;制御文字$1A SB 左上から右下まで消去。カーソルを左上へ
	.dc.w	putc_1B_EC-putc_control_jump_table	;制御文字$1B EC エスケープシーケンス開始
	.dc.w	putc_1C_FS-putc_control_jump_table	;制御文字$1C FS 
	.dc.w	putc_1D_GS-putc_control_jump_table	;制御文字$1D GS 
	.dc.w	putc_1E_RS-putc_control_jump_table	;制御文字$1E RS カーソルを左上へ
	.dc.w	putc_1F_US-putc_control_jump_table	;制御文字$1F US 

;----------------------------------------------------------------
;制御文字$00 NL 
putc_00_NL:
	rts

;----------------------------------------------------------------
;制御文字$01 SH 
putc_01_SH:
	rts

;----------------------------------------------------------------
;制御文字$02 SX 
putc_02_SX:
	rts

;----------------------------------------------------------------
;制御文字$03 EX 
putc_03_EX:
	rts

;----------------------------------------------------------------
;制御文字$04 ET 
putc_04_ET:
	rts

;----------------------------------------------------------------
;制御文字$05 EQ 
putc_05_EQ:
	rts

;----------------------------------------------------------------
;制御文字$06 AK 
putc_06_AK:
	rts

;----------------------------------------------------------------
;制御文字$07 BL ベルを鳴らす
putc_07_BL:
	push	d0-d2/a0-a1
	move.l	BIOS_BEEP_DATA.w,d0	;BEEP音のADPCMデータのアドレス。-1=BIOS_BEEP_EXTENSIONを使う
	moveq.l	#-1,d1
	if	<cmp.l d1,d0>,eq
		movea.l	BIOS_BEEP_EXTENSION.w,a0	;BEEP処理まるごと差し換えルーチンのアドレス。BIOS_BEEP_DATA=-1のとき有効
		jsr	(a0)
	else
		move.w	#4<<8|3,d1
		moveq.l	#0,d2
		move.w	BIOS_BEEP_LENGTH.w,d2	;BEEP音のADPCMデータのバイト数。0=無音
		movea.l	d0,a1
		IOCS	_ADPCMOUT
	endif
	pop
	rts

;----------------------------------------------------------------
;制御文字$08 BS カーソルを1桁左へ。左端では1行上の右端へ。上端では何もしない
putc_08_BS:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	ne
		subq.w	#1,d0			;1桁左へ
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else
		move.w	BIOS_CURSOR_ROW.w,d0
		if	ne
			subq.w	#1,d0			;1行上へ
			move.w	d0,BIOS_CURSOR_ROW.w
			move.w	BIOS_CONSOLE_RIGHT.w,BIOS_CURSOR_COLUMN.w	;右端へ
			clr.b	BIOS_CURSOR_FRACTION.w
		endif
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$09 HT カーソルを次のタブ桁へ。なければ1行下の左端へ。下端ではスクロールアップして左端へ
putc_09_HT:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	addq.w	#8,d0
	and.w	#-8,d0			;次のタブ桁へ
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,ls	;範囲内
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;範囲外
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0A LF カーソルを1行下へ。下端ではスクロールアップ
putc_0A_LF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0B VT カーソルを1行上へ。上端では何もしない
putc_0B_VT:
	push	d0
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	hi
		subq.w	#1,d0			;1行上へ
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0C FF カーソルを1桁右へ。右端では1行下の左端へ。下端ではスクロールアップして左端へ
putc_0C_FF:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_COLUMN.w,d0
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,lo	;右端ではないとき
		addq.w	#1,d0			;1桁右へ
		move.w	d0,BIOS_CURSOR_COLUMN.w
		clr.b	BIOS_CURSOR_FRACTION.w
	else				;右端のとき
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0D CR カーソルを左端へ
putc_0D_CR:
	push	d0
	bsr	iocs_1F_B_CUROFF
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$0E SO 
putc_0E_SO:
	rts

;----------------------------------------------------------------
;制御文字$0F SI 
putc_0F_SI:
	rts

;----------------------------------------------------------------
;制御文字$10 DE 
putc_10_DE:
	rts

;----------------------------------------------------------------
;制御文字$11 D1 
putc_11_D1:
	rts

;----------------------------------------------------------------
;制御文字$12 D2 
putc_12_D2:
	rts

;----------------------------------------------------------------
;制御文字$13 D3 
putc_13_D3:
	rts

;----------------------------------------------------------------
;制御文字$14 D4 
putc_14_D4:
	rts

;----------------------------------------------------------------
;制御文字$15 NK 
putc_15_NK:
	rts

;----------------------------------------------------------------
;制御文字$16 SN 
putc_16_SN:
	rts

;----------------------------------------------------------------
;制御文字$17 EB 
putc_17_EB:
	rts

;----------------------------------------------------------------
;制御文字$18 CN 
putc_18_CN:
	rts

;----------------------------------------------------------------
;制御文字$19 EM 
putc_19_EM:
	rts

;----------------------------------------------------------------
;制御文字$1A SB 左上から右下まで消去。カーソルを左上へ
putc_1A_SB:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;上端の行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	clr.l	BIOS_CURSOR_COLUMN.w	;左上へ
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;制御文字$1B EC エスケープシーケンス開始
putc_1B_EC:
	move.b	#$1B,BIOS_PUTC_POOL.w	;1バイト目のプール
	move.l	#BIOS_ESCAPE_BUFFER,BIOS_ESCAPE_POINTER.w	;エスケープシーケンスバッファの書き込み位置
	rts

;----------------------------------------------------------------
;制御文字$1C FS 
putc_1C_FS:
	rts

;----------------------------------------------------------------
;制御文字$1D GS 
putc_1D_GS:
	rts

;----------------------------------------------------------------
;制御文字$1E RS カーソルを左上へ
putc_1E_RS:
	bsr	iocs_1F_B_CUROFF
	clr.l	BIOS_CURSOR_COLUMN.w
	bsr	iocs_1E_B_CURON
	rts

;----------------------------------------------------------------
;制御文字$1F US 
putc_1F_US:
	rts

;----------------------------------------------------------------
;エスケープシーケンスを処理する
;<d1.w:文字コード
putc_escape:
	push	d0/a0
	movea.l	BIOS_ESCAPE_POINTER.w,a0
	move.b	d1,(a0)+
	if	<cmpa.l #BIOS_ESCAPE_BUFFER+10,a0>,lo
		move.l	a0,BIOS_ESCAPE_POINTER.w
	endif
	move.b	BIOS_ESCAPE_BUFFER.w,d0	;エスケープシーケンスの最初の文字
	if	<cmp.b #'[',d0>,eq	;ESC [
		moveq.l	#$20,d0
		or.b	d1,d0
		ifand	<cmp.b #'`',d0>,hs,<cmp.b #'z',d0>,ls	;'@'～'Z','`'～'z'
			bsr	putc_csi
		endif
	elif	<cmp.b #'*',d0>,eq	;ESC *
		bsr	putc_esc_ast
	elif	<cmp.b #'=',d0>,eq	;ESC =
		if	<cmpa.l #BIOS_ESCAPE_BUFFER+3,a0>,eq
			bsr	putc_esc_equ
		endif
	elif	<cmp.b #'D',d0>,eq	;ESC D
		bsr	putc_esc_D
	elif	<cmp.b #'E',d0>,eq	;ESC E
		bsr	putc_esc_E
	elif	<cmp.b #'M',d0>,eq	;ESC M
		bsr	putc_esc_M
	else				;その他
		clr.b	BIOS_PUTC_POOL.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC *
;	左上から右下まで消去。カーソルを左上へ
putc_esc_ast:
	push	d0-d1
	bsr	iocs_1F_B_CUROFF
	clr.w	d0			;上端の行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	clr.l	BIOS_CURSOR_COLUMN.w	;カーソルを左上へ
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC = r c
;	カーソルをr-' '行,c-' '桁へ。rとcは文字
putc_esc_equ:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	moveq.l	#0,d1
	moveq.l	#0,d2
	move.b	BIOS_ESCAPE_BUFFER+2.w,d1	;桁。' '=0
	move.b	BIOS_ESCAPE_BUFFER+1.w,d2	;行。' '=0
	moveq.l	#' ',d0
	sub.w	d0,d1			;桁座標
	sub.w	d0,d2			;行座標
	ifand	<cmp.w BIOS_CONSOLE_RIGHT.w,d1>,ls,<cmp.w BIOS_CONSOLE_BOTTOM.w,d2>,ls	;コンソールの範囲内のとき
		move.w	d1,BIOS_CURSOR_COLUMN.w
		move.w	d2,BIOS_CURSOR_ROW.w
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC D
;	カーソルを1行下へ。下端ではスクロールアップ
;	_B_DOWN_Sと同じ
putc_esc_D:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC E
;	カーソルを1行下の左端へ。下端ではスクロールアップ
putc_esc_E:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
		addq.w	#1,d0			;1行下へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;下端のとき
		moveq.l	#1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		moveq.l	#0,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC M
;	カーソルを1行上へ。上端ではスクロールダウン
;	_B_UP_Sと同じ
putc_esc_M:
	push	d0-d2
	bsr	iocs_1F_B_CUROFF
	move.w	BIOS_CURSOR_ROW.w,d0
	if	<tst.w d0>,hi		;上端ではないとき
		subq.w	#1,d0			;1行上へ
		move.w	d0,BIOS_CURSOR_ROW.w
	else				;上端のとき
		moveq.l	#0,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1
		subq.w	#1,d1			;コピー元の下端の行座標
		moveq.l	#1,d2			;コピー先の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		moveq.l	#0,d0			;上端の行座標
		moveq.l	#0,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;ESC [
;	https://en.wikipedia.org/wiki/ANSI_escape_code
;	http://nanno.dip.jp/softlib/man/rlogin/ctrlcode.html
putc_csi:
	push	d0-d3/a0
	bsr	iocs_1F_B_CUROFF
	move.l	BIOS_CSI_EXTENSION.w,d0	;エスケープシーケンス丸ごと差し替えルーチン
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	else
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		move.w	(a0)+,d0
		if	<cmp.w #'[>',d0>,eq	;ESC [>
			move.w	(a0)+,d0
			if	<cmp.w #'5l',d0>,eq	;ESC [>5l カーソルON
				sf.b	BIOS_CURSOR_PROHIBITED.w
			elif	<cmp.w #'5h',d0>,eq	;ESC [>5h カーソルOFF
				st.b	BIOS_CURSOR_PROHIBITED.w
			else
				bsr	putc_csi_extension
			endif
		elif	<cmp.w #'[?',d0>,eq	;ESC [?
			move.w	(a0)+,d0
			if	<cmp.w #'4l',d0>,eq	;ESC [?4l ジャンプスクロール
				clr.w	BIOS_SMOOTH_SCROLL.w
			elif	<cmp.w #'4h',d0>,eq	;ESC [?4h 8ドットスムーススクロール
				move.w	#2,BIOS_SMOOTH_SCROLL.w
			else
				bsr	putc_csi_extension
			endif
		else
			lea.l	BIOS_ESCAPE_BUFFER+1.w,a0	;[の次
			moveq.l	#0,d0
			moveq.l	#-1,d1			;1番目の数値
			moveq.l	#-1,d2			;2番目の数値
			moveq.l	#-1,d3			;3番目の数値
			do
				move.b	(a0)+,d0
			while	<cmp.b #' ',d0>,eq
			ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				moveq.l	#0,d1
				do
					sub.b	#'0',d0
					mulu.w	#10,d1
					add.w	d0,d1
					move.b	(a0)+,d0
				whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
				if	<cmp.b #';',d0>,eq
					do
						move.b	(a0)+,d0
					while	<cmp.b #' ',d0>,eq
					ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						moveq.l	#0,d2
						do
							sub.b	#'0',d0
							mulu.w	#10,d2
							add.w	d0,d2
							move.b	(a0)+,d0
						whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
						if	<cmp.b #';',d0>,eq
							do
								move.b	(a0)+,d0
							while	<cmp.b #' ',d0>,eq
							ifand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
								moveq.l	#0,d3
								do
									sub.b	#'0',d0
									mulu.w	#10,d3
									add.w	d0,d3
									move.b	(a0)+,d0
								whileand	<cmp.b #'0',d0>,hs,<cmp.b #'9',d0>,ls
							endif
						endif
					endif
				endif
			endif
			if	<cmp.b #'@',d0>,eq
				bsr	putc_csi_at		;ESC [n@ カーソルから右にn桁挿入
			elif	<cmp.b #'A',d0>,eq
				bsr	putc_csi_A		;ESC [nA カーソルをn行上へ。上端を超えるときは動かない
			elif	<cmp.b #'B',d0>,eq
				bsr	putc_csi_B		;ESC [nB カーソルをn行下へ。下端で止まる
			elif	<cmp.b #'C',d0>,eq
				bsr	putc_csi_C		;ESC [nC カーソルをn桁右へ。右端で止まる
			elif	<cmp.b #'D',d0>,eq
				bsr	putc_csi_D		;ESC [nD カーソルをn桁左へ。左端で止まる
			elif	<cmp.b #'H',d0>,eq
				bsr	putc_csi_H		;ESC [r;cH カーソルをr-1行,c-1桁へ
			elif	<cmp.b #'J',d0>,eq
				bsr	putc_csi_J		;ESC [nJ 画面を消去する
			elif	<cmp.b #'K',d0>,eq
				bsr	putc_csi_K		;ESC [nK 行を消去する
			elif	<cmp.b #'L',d0>,eq
				bsr	putc_csi_L		;ESC [nL カーソルから下にn行挿入。カーソルを左端へ
			elif	<cmp.b #'M',d0>,eq
				bsr	putc_csi_M		;ESC [nM カーソルから下をn行削除。カーソルを左端へ
			elif	<cmp.b #'P',d0>,eq
				bsr	putc_csi_P		;ESC [nP カーソルから右をn桁削除
			elif	<cmp.b #'R',d0>,eq
				bsr	putc_csi_R		;ESC [r;cR CSR(Cursor Position Report)
			elif	<cmp.b #'X',d0>,eq
				bsr	putc_csi_X		;ESC [nX カーソルから右をn桁消去
			elif	<cmp.b #'c',d0>,eq
				bsr	putc_csi_c		;ESC [nc 中央寄せ
			elif	<cmp.b #'f',d0>,eq
				bsr	putc_csi_f		;ESC [r;cf カーソルをr-1行,c-1桁へ
			elif	<cmp.b #'l',d0>,eq
				bsr	putc_csi_l		;ESC [nl 左寄せ
			elif	<cmp.b #'m',d0>,eq
				bsr	putc_csi_m		;ESC [nm 文字属性を設定する
			elif	<cmp.b #'n',d0>,eq
				bsr	putc_csi_n		;ESC [nn DSR(Device Status Report)
			elif	<cmp.b #'r',d0>,eq
				bsr	putc_csi_r		;ESC [nr 右寄せ
			elif	<cmp.b #'s',d0>,eq
				bsr	putc_csi_s		;ESC [ns カーソルの座標と文字属性を保存する
			elif	<cmp.b #'u',d0>,eq
				bsr	putc_csi_u		;ESC [nu カーソルの座標と文字属性を復元する
			else
				bsr	putc_csi_extension
			endif
		endif
	endif
	clr.b	BIOS_PUTC_POOL.w
	bsr	iocs_1E_B_CURON
	pop
	rts

;----------------------------------------------------------------
;拡張エスケープシーケンス処理ルーチンを呼び出す
putc_csi_extension:
	push	d0/a0
	move.l	BIOS_ESCAPE_EXTENSION.w,d0
	if	ne
		lea.l	BIOS_ESCAPE_BUFFER.w,a0
		movejsr	d0
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [n@ カーソルから右にn桁挿入
;<d1.w:挿入する桁数。0=1桁
putc_csi_at:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
;
;	ＡＢＣＤＥＦＧＨＩ
;	ＡＢＣ　　　　ＤＥ
;
	move.w	BIOS_CURSOR_COLUMN.w,d4
	add.w	d1,d4			;カーソルの桁座標+挿入する桁数=移動先の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3
	sub.w	d4,d3			;コンソールの右端-移動先の桁座標=移動する部分の桁数-1
	if	lo			;すべて押し出される
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
	else				;移動する部分がある
		move.w	BIOS_CURSOR_ROW.w,d0	;行座標
		swap.w	d0
		clr.w	d0			;65536*行座標
		lsr.l	#5,d0			;128*16*行座標
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;行の左端のアドレス
		movea.l	a2,a3
		adda.w	BIOS_CURSOR_COLUMN.w,a2	;カーソルのアドレス
		adda.w	d3,a2			;移動元の右端のアドレス
		adda.w	BIOS_CONSOLE_RIGHT.w,a3	;行の右端のアドレス=移動先の右端のアドレス
		do				;プレーンのループ
			moveq.l	#16-1,d2
			for	d2			;ラスタのループ
				lea.l	1(a2),a0		;移動元の右端のアドレス+1
				lea.l	1(a3),a1		;移動先の右端のアドレス+1
				move.w	d3,d1			;移動する部分の桁数-1
				for	d1			;桁のループ
					move.b	-(a0),-(a1)
				next
				lea.l	128(a2),a2		;次のラスタ
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;次のプレーン
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
		move.w	d4,d3
		subq.w	#1,d3			;右端の桁座標
		moveq.l	#0,d4			;左端の桁座標の端数
		moveq.l	#7,d5			;右端の桁座標の端数
		bsr	putc_clear		;行を消去する
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nA カーソルをn行上へ。上端を超えるときは動かない
;<d1.w:移動する行数。0=1行
putc_csi_A:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	sub.w	d1,d0			;n行上へ
	if	hs			;上端を超えないとき
		move.w	d0,BIOS_CURSOR_ROW.w
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nB カーソルをn行下へ。下端で止まる
;<d1.w:移動する行数。0=1桁
putc_csi_B:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
	add.w	d1,d0			;n行下へ
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,hi	;下端を超えるとき
		move.w	BIOS_CONSOLE_BOTTOM.w,d0	;下端で止まる
	endif
	move.w	d0,BIOS_CURSOR_ROW.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nC カーソルをn桁右へ。右端で止まる
;<d1.w:移動する桁数。0=1桁
putc_csi_C:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	add.w	d1,d0			;n桁右へ
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d0>,hi	;右端を超えるとき
		move.w	BIOS_CONSOLE_RIGHT.w,d0	;右端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nD カーソルをn桁左へ。左端で止まる
;<d1.w:移動する桁数。0=1桁
putc_csi_D:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d0
	sub.w	d1,d0			;n桁左へ
	if	lo			;左端を超えるとき
		moveq.l	#0,d0			;左端で止まる
	endif
	move.w	d0,BIOS_CURSOR_COLUMN.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cf カーソルをr-1行,c-1桁へ
;<d1.w:移動先の行座標+1。0=上端。下端で止まる
;<d2.w:移動先の桁座標+1。0=左端。右端で止まる
putc_csi_f:
;----------------------------------------------------------------
;ESC [r;cH カーソルをr-1行,c-1桁へ
;<d1.w:移動先の行座標+1。0=上端。下端で止まる
;<d2.w:移動先の桁座標+1。0=左端。右端で止まる
putc_csi_H:
	push	d1-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=上端
	endif
	subq.w	#1,d1
	if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d1>,hi
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端で止まる
	endif
	ifor	<cmp.w #-1,d2>,eq,<tst.w d2>,eq
		moveq.l	#1,d2			;0=左端
	endif
	subq.w	#1,d2
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d2>,hi
		move.w	BIOS_CONSOLE_RIGHT.w,d2	;右端で止まる
	endif
	move.w	d2,BIOS_CURSOR_COLUMN.w
	move.w	d1,BIOS_CURSOR_ROW.w
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nJ 画面を消去する
;<d1.w:0=カーソルから右下まで,1=左上からカーソルまで,2=左上から右下まで。カーソルを左上へ
putc_csi_J:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0J		;ESC [0J カーソルから右下まで消去する
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1J		;ESC [1J 左上からカーソルまで消去する
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2J		;ESC [2J 左上から右下まで消去する。カーソルを左上へ
	endif
	rts

;----------------------------------------------------------------
;ESC [0J カーソルから右下まで消去する
putc_csi_0J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0
	move.w	BIOS_CONSOLE_BOTTOM.w,d1
	if	<cmp.w d1,d0>,lo		;下端ではないとき
	;	move.w	BIOS_CURSOR_ROW.w,d0
		addq.w	#1,d0			;上端の行座標
	;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
	moveq.l	#0,d4
	move.b	BIOS_CURSOR_FRACTION.w,d4	;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [1J 左上からカーソルまで消去する
putc_csi_1J:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d1
	if	<tst.w d1>,hi			;上端ではないとき
		clr.w	d0			;上端の行座標
	;	move.w	BIOS_CURSOR_ROW.w,d1
		subq.w	#1,d1			;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	moveq.l	#0,d2			;左端の桁座標
	move.w	BIOS_CURSOR_COLUMN.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5
	add.b	BIOS_CURSOR_FRACTION.w,d5	;右端の桁座標の端数
	if	<cmp.w #7,d5>,hi	;次の桁のとき
		if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,lo	;右端ではないとき
			addq.w	#1,d3
			subq.w	#8,d5
		else				;右端のとき
			moveq.l	#7,d5
		endif
	endif
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [2J 左上から右下まで消去する。カーソルを左上へ
putc_csi_2J:
	push	d0-d1
	moveq.l	#0,d0			;上端の行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	clr.l	BIOS_CURSOR_COLUMN.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nK 行を消去する
;<d1.w:0=カーソルから右端まで,1=左端からカーソルまで,2=左端から右端まで
putc_csi_K:
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
	elif	<cmp.w #1,d1>,eq
		bsr	putc_csi_1K		;ESC [1K 左端からカーソルまで消去する
	elif	<cmp.w #2,d1>,eq
		bsr	putc_csi_2K		;ESC [2K 左端から右端まで消去する
	endif
	rts

;----------------------------------------------------------------
;ESC [0K カーソルから右端まで消去する
putc_csi_0K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [1K 左端からカーソルまで消去する
putc_csi_1K:
	push	d0-d5
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	moveq.l	#0,d2			;左端の桁座標
	move.w	BIOS_CURSOR_COLUMN.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [2K 左端から右端まで消去する
putc_csi_2K:
	push	d0-d1
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	bsr	putc_clear_rows		;行を消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [nL カーソルから下にn行挿入。カーソルを左端へ
;<d1.w:挿入する行数。0=1行
putc_csi_L:
	push	d0-d2
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:カーソルの行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d2	;コンソールの行数-1
	addq.w	#1,d2			;コンソールの行数
	sub.w	d0,d2			;カーソルから下の行数
	sub.w	d1,d2			;画面内に残る行数
;<d2.w:画面内に残る行数
	if	ls			;画面内に残る行がない。すべて画面外に押し出される
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│□□□│
	;  │▲▲▲│  │□□□│
	;  │■■■│  │□□□│
	;  └───┘  └───┘
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	else				;画面内に残る行がある
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│□□□│\d1
	;  │▲▲▲│  │□□□│/
	;  │■■■│  │●●●│)d2
	;  └───┘  └───┘
		add.w	d0,d2
		subq.w	#1,d2			;コピー元の下端の行座標
		add.w	d0,d1			;コピー先の上端の行座標
		exg.l	d1,d2
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;コピー元の上端の行座標
		bsr	putc_copy_rows		;行をコピーする
		exg.l	d1,d2
		subq.w	#1,d1			;下端の行座標
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nM カーソルから下をn行削除。カーソルを左端へ
;<d1.w:削除する行数。0=1行
putc_csi_M:
	push	d0-d3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1行
	endif
	move.w	BIOS_CURSOR_ROW.w,d0
;<d0.w:カーソルの行座標
	move.w	BIOS_CONSOLE_BOTTOM.w,d3	;コンソールの行数-1
	addq.w	#1,d3			;コンソールの行数
	sub.w	d0,d3			;カーソルから下の行数
	sub.w	d1,d3			;画面内に残る行数
;<d3.w:画面内に残る行数
	if	ls			;画面内に残る行がない。すべて削除される
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│□□□│
	;  │▲▲▲│  │□□□│
	;  │■■■│  │□□□│
	;  └───┘  └───┘
	;;;	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;下端の行座標
		bsr	putc_clear_rows		;行を消去する
	else				;画面内に残る行がある
	;  ┌───┐  ┌───┐
	;  │      │  │      │
	;  │      │  │      │
	;d0│●●●│→│■■■│)d3
	;  │▲▲▲│  │□□□│\d1
	;  │■■■│  │□□□│/
	;  └───┘  └───┘
	;;;	move.w	BIOS_CURSOR_ROW.w,d0
		move.w	d0,d2			;コピー先の上端の行座標
		add.w	d1,d0			;コピー元の上端の行座標
		move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		bsr	putc_copy_rows		;行をコピーする
		move.w	d2,d0
		add.w	d3,d0			;上端の行座標
	;;;	move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
		bsr	putc_clear_rows		;行を消去する
	endif
	clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
	clr.b	BIOS_CURSOR_FRACTION.w
	pop
	rts

;----------------------------------------------------------------
;ESC [nP カーソルから右をn桁削除
;<d1.w:削除する桁数。0=1桁
putc_csi_P:
	push	d0-d5/a0-a3
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
;
;	ＡＢＣＤＥＦＧＨＩ
;	ＡＢＣＨＩ　　　　
;
	move.w	BIOS_CURSOR_COLUMN.w,d4	;カーソルの桁座標
	add.w	d1,d4			;カーソルの桁座標+削除する桁数=移動元の左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;コンソールの右端の桁座標=移動元の右端の桁座標
	sub.w	d4,d3			;移動元の右端の桁座標-移動元の左端の桁座標=移動する部分の桁数-1
	if	lo			;すべて削除される
		bsr	putc_csi_0K		;ESC [0K カーソルから右端まで消去する
	else				;移動する部分がある
		move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標
		swap.w	d0
		clr.w	d0			;65536*カーソルの行座標
		lsr.l	#5,d0			;128*16*カーソルの行座標
		add.l	BIOS_CONSOLE_OFFSET.w,d0
		add.l	#$00E00000,d0
		movea.l	d0,a2			;カーソルの行の左端のアドレス
		movea.l	a2,a3
		adda.w	d4,a2			;カーソルの行の左端のアドレス+移動元の左端の桁座標=移動元の左端のアドレス
		adda.w	BIOS_CURSOR_COLUMN.w,a3	;カーソルの行の左端のアドレス+カーソルの桁座標=カーソルのアドレス=移動先の左端のアドレス
		do				;プレーンのループ
			moveq.l	#16-1,d2
			for	d2			;ラスタのループ
				movea.l	a2,a0			;移動元の左端のアドレス
				movea.l	a3,a1			;移動先の左端のアドレス
				move.w	d3,d1			;移動する部分の桁数-1
				for	d1			;桁のループ
					move.b	(a0)+,(a1)+
				next
				lea.l	128(a2),a2		;次のラスタ
				lea.l	128(a3),a3
			next
			adda.l	#-128*16+128*1024,a2	;次のプレーン
			adda.l	#-128*16+128*1024,a3
		while	<cmpa.l #$00E40000,a2>,lo
		move.w	BIOS_CURSOR_ROW.w,d0	;カーソルの行座標=消去する範囲の上端の行座標
		move.w	d0,d1			;カーソルの行座標=消去する範囲の下端の行座標
		move.w	BIOS_CURSOR_COLUMN.w,d2	;カーソルの桁座標
		add.w	d3,d2			;カーソルの桁座標+移動する範囲の桁数-1
		addq.w	#1,d2			;カーソルの桁座標+移動する範囲の桁数=消去する範囲の左端の桁座標
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;コンソールの右端の桁座標=消去する範囲の右端の桁座標
		moveq.l	#0,d4			;消去する範囲の左端の桁座標の端数
		moveq.l	#7,d5			;消去する範囲の右端の桁座標の端数
		bsr	putc_clear		;行を消去する
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [r;cR CPR(Cursor Position Report)
;	DSR(Device Status Report)の返答。ここでは何もしない
putc_csi_R:
	rts

;----------------------------------------------------------------
;ESC [nX カーソルから右をn桁消去
;<d1.w:消去する桁数。0=1桁
putc_csi_X:
	push	d0-d5
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1			;0=1桁
	endif
	move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
	move.w	d2,d3
	add.w	d1,d3
	subq.w	#1,d3			;右端の桁座標
	if	<cmp.w BIOS_CONSOLE_RIGHT.w,d3>,hi	;右端を超えるとき
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端で止まる
	endif
	move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
	move.w	d0,d1			;下端の行座標
	moveq.l	#7,d4
	and.b	BIOS_CURSOR_FRACTION.w,d4	;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;ESC [nc 中央寄せ
;<d1.w:ドット幅
putc_csi_c:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	if	<cmp.w d0,d1>,ls	;大きすぎない
		bset.b	#BIOS_ALIGN_CENTER_BIT,BIOS_CONSOLE_STATUS.w	;中央寄せ
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;バッファ出力開始
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nl 左寄せ
;<d1.w:ドット幅
putc_csi_l:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	if	<cmp.w d0,d1>,ls	;大きすぎない
		bset.b	#BIOS_ALIGN_LEFT_BIT,BIOS_CONSOLE_STATUS.w	;左寄せ
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;バッファ出力開始
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [nm 文字属性を設定する
;	0	リセット
;	1	太字
;	2	細字
;	3	斜体
;	4	下線
;	5	(遅い点滅)
;	6	(速い点滅)
;	7	反転
;	8	(秘密)
;	9	取り消し線
;	11～19	(代替フォント1～9)
;	20	(ブラックレター)
;	21	波線
;	22	太字、細字解除
;	23	斜体解除、(ブラックレター解除)
;	24	下線、波線解除
;	25	(遅い点滅解除、速い点滅解除)
;	26	プロポーショナル
;	27	反転解除
;	28	(秘密解除)
;	29	取り消し線解除
;	30	黒
;	31	水色
;	32	黄色
;	33	白
;	34	太字、黒
;	35	太字、水色
;	36	太字、黄色
;	37	太字、白
;	40	反転、黒
;	41	反転、水色
;	42	反転、黄色
;	43	反転、白
;	44	反転、太字、黒
;	45	反転、太字、水色
;	46	反転、太字、黄色
;	47	反転、太字、白
;	50	プロポーショナル解除
;	51	四角囲み
;	52	丸囲み
;	53	上線
;	54	四角囲み、丸囲み解除
;	55	上線解除
;	73	上付き
;	74	下付き
;	75	上付き、下付き解除
;<d1.w:属性。-1=指定なし
;<d2.w:属性。-1=指定なし
;<d3.w:属性。-1=指定なし
putc_csi_m:
	push	d1
	bsr	putc_csi_m_1
	if	<cmp.w #-1,d2>,ne
		move.w	d2,d1
		bsr	putc_csi_m_1
	endif
	if	<cmp.w #-1,d3>,ne
		move.w	d3,d1
		bsr	putc_csi_m_1
	endif
	pop
	rts

;?d1
putc_csi_m_1:
;太字と反転のみトグル動作。その他はONまたはOFFのどちらか
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		move.b	#3,BIOS_ATTRIBUTE_1.w	;文字属性1。取り消し線|下線|斜体|細字|反転|太字|プレーン##
		clr.b	BIOS_ATTRIBUTE_2.w	;文字属性2。-|上付き|下付き|上線|丸囲み|四角囲み|プロポーショナル|波線
	elif	<cmp.w #1,d1>,eq
		bchg.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;太字
		if	eq			;OFF→ONのとき
			bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;細字解除
		endif
	elif	<cmp.w #2,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;太字解除
		bset.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;細字
	elif	<cmp.w #3,d1>,eq
		bset.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;斜体
	elif	<cmp.w #4,d1>,eq
		bset.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;下線
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;波線解除
	elif	<cmp.w #7,d1>,eq
		bchg.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;反転
	elif	<cmp.w #9,d1>,eq
		bset.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;取り消し線
	elif	<cmp.w #21,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;下線解除
		bset.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;波線
	elif	<cmp.w #22,d1>,eq
		bclr.b	#BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w	;太字解除
		bclr.b	#BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w	;細字解除
	elif	<cmp.w #23,d1>,eq
		bclr.b	#BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w	;斜体解除
	elif	<cmp.w #24,d1>,eq
		bclr.b	#BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w	;下線解除
		bclr.b	#BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w	;波線解除
	elif	<cmp.w #26,d1>,eq
		bset.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;プロポーショナル
	elif	<cmp.w #27,d1>,eq
		bclr.b	#BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w	;反転解除
	elif	<cmp.w #29,d1>,eq
		bclr.b	#BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w	;取り消し線解除
	elifand	<cmp.w #30,d1>,hs,<cmp.w #37,d1>,ls
		sub.w	#30,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elifand	<cmp.w #40,d1>,hs,<cmp.w #47,d1>,ls
		sub.w	#40,d1
		addq.b	#8,d1
		andi.b	#$F0,BIOS_ATTRIBUTE_1.w
		or.b	d1,BIOS_ATTRIBUTE_1.w
	elif	<cmp.w #50,d1>,eq
		bclr.b	#BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w	;プロポーショナル解除
	elif	<cmp.w #51,d1>,eq
		bset.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;四角囲み
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;丸囲み解除
	elif	<cmp.w #52,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;四角囲み解除
		bset.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;丸囲み
	elif	<cmp.w #53,d1>,eq
		bset.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;上線
	elif	<cmp.w #54,d1>,eq
		bclr.b	#BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w	;四角囲み解除
		bclr.b	#BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w	;丸囲み解除
	elif	<cmp.w #55,d1>,eq
		bclr.b	#BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w	;上線解除
	elif	<cmp.w #73,d1>,eq
		bset.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;上付き
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;下付き解除
	elif	<cmp.w #74,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;上付き解除
		bset.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;下付き
	elif	<cmp.w #75,d1>,eq
		bclr.b	#BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;上付き解除
		bclr.b	#BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w	;下付き解除
	endif
	rts

;----------------------------------------------------------------
;ESC [nn DSR(Device Status Report)
;<d1.w:6
putc_csi_n:
	push	d0-d2/a0
	if	<cmp.w #6,d1>,eq	;CPR(Cursor Position Report)
		move.w	#$0100+27,d2
		bsr	20f
		move.w	#$1C00+'[',d2
		bsr	20f
		move.w	BIOS_CURSOR_ROW.w,d0
		bsr	10f
		move.w	#$2700+';',d2
		bsr	20f
		move.w	BIOS_CURSOR_COLUMN.w,d0
		bsr	10f
		move.w	#$1400+'R',d2
		bsr	20f
	endif
	pop
	rts

;数値+1を文字列に変換してキー入力バッファに書き込む
;<d0.b:数値。255は不可。ここでは1を省略しない
;?d0-d2/a0
10:	addq.b	#1,d0
	move.l	#(1<<24)+(10<<16)+(100<<8),d1
	do
		lsr.l	#8,d1
	while	<cmp.b d1,d0>,lo
	do
		moveq.l	#-2,d2
		do
			addq.w	#2,d2
			sub.b	d1,d0
		while	hs
		move.w	15f(pc,d2.w),d2
		bsr	20f
		add.b	d1,d0
		lsr.l	#8,d1
	while	<tst.b d1>,ne
	rts

15:	.dc.w	$0B00+'0'
	.dc.w	$0200+'1'
	.dc.w	$0300+'2'
	.dc.w	$0400+'3'
	.dc.w	$0500+'4'
	.dc.w	$0600+'5'
	.dc.w	$0700+'6'
	.dc.w	$0800+'7'
	.dc.w	$0900+'8'
	.dc.w	$0A00+'9'

;キー入力バッファに書き込む
;<d2.w:(スキャンコード<<8)+文字コード
;?a0
20:	di
	if	<cmpi.w #64,BIOS_KEY_REMAINING.w>,lo	;キー入力バッファに残っているデータの数が64未満のとき
		movea.l	BIOS_KEY_WRITTEN.w,a0	;最後に書き込んだ位置
		addq.l	#2,a0			;今回書き込む位置
		if	<cmpa.w #BIOS_KEY_BUFFER+2*64.w,a0>,hs	;末尾を超えたら
			lea.l	BIOS_KEY_BUFFER.w,a0	;先頭に戻る
		endif
		move.w	d2,(a0)			;書き込む
		move.l	a0,BIOS_KEY_WRITTEN.w	;最後に書き込んだ位置
		addq.w	#1,BIOS_KEY_REMAINING.w	;キー入力バッファに残っているデータの数
	endif
	ei
	rts

;----------------------------------------------------------------
;ESC [nr 右寄せ
;<d1.w:ドット幅
putc_csi_r:
	push	d0-d1
	ifor	<cmp.w #-1,d1>,eq,<tst.w d1>,eq
		moveq.l	#1,d1
	endif
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	if	<cmp.w d0,d1>,ls	;大きすぎない
		bset.b	#BIOS_ALIGN_RIGHT_BIT,BIOS_CONSOLE_STATUS.w	;右寄せ
		move.l	#BIOS_BUFFER_ARRAY,BIOS_BUFFER_POINTER.w
		clr.w	BIOS_BUFFER_WIDTH.w
		move.w	d1,BIOS_BUFFER_REQUEST.w	;バッファ出力開始
	endif
	pop
	rts

;----------------------------------------------------------------
;ESC [ns カーソルの座標と文字属性を保存する
;<d1.w:-1
putc_csi_s:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_CURSOR_ROW.w,BIOS_SAVED_ROW.w
		move.w	BIOS_CURSOR_COLUMN.w,BIOS_SAVED_COLUMN.w
		move.b	BIOS_CURSOR_FRACTION.w,BIOS_SAVED_FRACTION.w
		move.b	BIOS_ATTRIBUTE_1.w,BIOS_SAVED_ATTRIBUTE_1.w
		move.b	BIOS_ATTRIBUTE_2.w,BIOS_SAVED_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;ESC [nu カーソルの座標と文字属性を復元する
;<d1.w:-1
putc_csi_u:
	if	<cmp.w #-1,d1>,eq
		move.w	BIOS_SAVED_ROW.w,BIOS_CURSOR_ROW.w
		move.w	BIOS_SAVED_COLUMN.w,BIOS_CURSOR_COLUMN.w
		move.b	BIOS_SAVED_FRACTION.w,BIOS_CURSOR_FRACTION.w
		move.b	BIOS_SAVED_ATTRIBUTE_1.w,BIOS_ATTRIBUTE_1.w
		move.b	BIOS_SAVED_ATTRIBUTE_2.w,BIOS_ATTRIBUTE_2.w
	endif
	rts

;----------------------------------------------------------------
;画面に描くまたはバッファに出力する
;<d1.w:文字コード
putc_output:
	push	d0-d7/a0-a2
	lea.l	-4*16-4*16(sp),sp	;フォントデータとマスクデータ
;<(sp).l[16]:フォントデータ
;<4*16(sp).l[16]:マスクデータ
	move.w	d1,d7
;<d7.w:文字コード
;----------------
;フォントアドレスとドット幅を求める
	ifand	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne,<cmp.w #$0020,d1>,hs,<cmp.w #$0082,d1>,ls	;プロポーショナルにする
		lea.l	proportional_font(pc),a0	;プロポーショナルフォント($20～$82)
		sub.w	#$0020,d1
		mulu.w	#2+2*16,d1
		adda.l	d1,a0			;フォントアドレス
		move.w	(a0)+,d6		;ドット幅。1～16
		moveq.l	#1,d2			;16ドットデータ
	else				;プロポーショナルにしない
		moveq.l	#8,d2
		IOCS	_FNTADR
	;<d0.l:フォントアドレス
	;<d1.w:横方向のドット数<<16|横方向のバイト数-1
	;<d2.w:縦方向のドット数-1
		movea.l	d0,a0			;フォントアドレス
		move.w	d1,d2			;0=8ドットデータ,1=16ドットデータ
		swap.w	d1
		move.w	d1,d6			;ドット幅。1～16
	endif
;<d2.w:0=8ドットデータ,1=16ドットデータ
;<d6.w:ドット幅。1～16
;<(a0).b[16]:8ドットデータ
;または
;<(a0).w[16]:16ドットデータ
;----------------
;バッファに出力するか
	if	<tst.w BIOS_BUFFER_REQUEST.w>,ne	;バッファ出力中
		movea.l	BIOS_BUFFER_POINTER.w,a0	;バッファの書き込み位置
		goto	<cmpa.l #BIOS_BUFFER_ARRAY+2*64,a0>,hs,putc_output_end	;バッファが一杯のときは無視する
		move.w	d7,(a0)+		;文字コード
		move.l	a0,BIOS_BUFFER_POINTER.w	;書き込み位置を進める
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;プロポーショナルのとき
			if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;太字のとき
				addq.w	#1,d6			;幅が1ドット増える
			endif
			if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;斜体のとき
				addq.w	#3,d6			;幅が3ドット増える
				bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
				if	ne	;連結のとき
					subq.w	#3,BIOS_BUFFER_WIDTH.w	;3ドット詰める
					if	cs
						clr.w	BIOS_BUFFER_WIDTH.w	;念の為
					endif
				endif
			else				;斜体ではないとき
				bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			endif
		endif
		add.w	d6,BIOS_BUFFER_WIDTH.w	;幅を加える
		goto	putc_output_end
	endif
;----------------
;カーソルOFF
;	斜体のとき位置がずれるのでその前にカーソルを消す
	bsr	iocs_1F_B_CUROFF
;----------------
;フォントデータを作る
	movea.l	sp,a1			;フォントデータ
	moveq.l	#0,d0
	if	<tst.w d2>,eq		;8ドットデータのとき
		moveq.l	#16-1,d3
		for	d3
			move.b	(a0)+,(a1)+
			move.b	d0,(a1)+		;clr
			move.w	d0,(a1)+		;clr
		next
	else				;16ドットデータのとき
		moveq.l	#16-1,d3
		for	d3
			move.w	(a0)+,(a1)+
			move.w	d0,(a1)+		;clr
		next
	endif
;<(sp).l[16]:フォントデータ
;----------------
;太字
;	全体を右に1ドットずらしてORする
;	プロポーショナルのときは幅が1ドット増える
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
;>d6.w:ドット幅。1～17
	if	<btst.b #BIOS_BOLD_BIT,BIOS_ATTRIBUTE_1.w>,ne	;太字のとき
		movea.l	sp,a1			;フォントデータ
		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;プロポーショナルのとき
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;右に1ドットずらして
				or.l	d1,d0			;ORする
				move.l	d0,(a1)+
			next
			addq.w	#1,d6			;幅が1ドット増える
		else				;プロポーショナルではないとき
			moveq.l	#1,d2
			ror.l	d6,d2
			neg.l	d2
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				move.l	d0,d1
				lsr.l	#1,d0			;右に1ドットずらして
				or.l	d1,d0			;ORする
				and.l	d2,d0			;幅を増やさない
				move.l	d0,(a1)+
			next
		endif
	endif
;----------------
;細字
;	上下左右のいずれかが1で、メッシュが1のとき、1を0にする
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_FAINT_BIT,BIOS_ATTRIBUTE_1.w>,ne	;細字のとき
		movea.l	sp,a1			;フォントデータ
		move.l	#$AAAAAAAA,d2
		moveq.l	#1,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
		rol.l	d0,d2
		moveq.l	#16-1,d3
		for	d3
			move.l	(a1),d0
			move.l	d0,d1
			lsr.l	#1,d1			;左
			lsl.l	#1,d0			;右
			or.l	d1,d0
			if	<cmpa.l sp,a1>,ne
				or.l	-4(a1),d0	;上
			endif
			if	<tst.w d3>,ne
				or.l	4(a1),d0	;下
			endif
			and.l	d2,d0			;メッシュ
			not.l	d0
			and.l	d0,(a1)+
			rol.l	#1,d2
		next
	endif
;----------------
;下線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_UNDERLINE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;下線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*15(a1)
	endif
;----------------
;取り消し線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_STRIKETHROUGH_BIT,BIOS_ATTRIBUTE_1.w>,ne	;取り消し線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*8(a1)
	endif
;----------------
;波線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_WAVELINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;波線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d2
		ror.l	d6,d2
		neg.l	d2
		moveq.l	#3,d0
		and.b	BIOS_CURSOR_FRACTION.w,d0
  .if 0
		move.l	#$CCCCCCCC,d1
		rol.l	d0,d1
		move.l	d1,d0			;11001100
		not.l	d1			;00110011
		and.l	d2,d0
		and.l	d2,d1
		or.l	d0,4*14(a1)
		or.l	d1,4*15(a1)
  .else
		move.l	#$88888888,d1
		move.l	#$55555555,d3
		rol.l	d0,d1			;10001000
		rol.l	d0,d3			;01010101
		move.l	d1,d0
		rol.l	#2,d0			;00100010
		and.l	d2,d0
		and.l	d2,d1
		and.l	d2,d3
		or.l	d0,4*13(a1)
		or.l	d3,4*14(a1)
		or.l	d1,4*15(a1)
  .endif
	endif
;----------------
;四角囲み
	if	<btst.b #BIOS_FRAME_BIT,BIOS_ATTRIBUTE_2.w>,ne	;四角囲みのとき
	;16x16の中央に寄せる
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16を12x12に縮小する
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16の中央に寄せる
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;四角を付ける
		movea.l	sp,a0
		or.l	#$FFFF0000,(a0)+
		moveq.l	#14-1,d3
		for	d3
			or.l	#$80010000,(a0)+
		next
		or.l	#$FFFF0000,(a0)+
	endif
;----------------
;丸囲み
	if	<btst.b #BIOS_ENCIRCLE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;丸囲みのとき
	;16x16の中央に寄せる
		moveq.l	#16,d1
		sub.w	d6,d1
		if	hs
			lsr.w	#1,d1
			movea.l	sp,a1
			moveq.l	#16-1,d3
			for	d3
				move.l	(a1),d0
				lsr.l	d1,d0
				move.l	d0,(a1)+
			next
			moveq.l	#16,d6
		endif
	;16x16を12x12に縮小する
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
	;16x16の中央に寄せる
		lea.l	4*12(sp),a0
		lea.l	4*14(sp),a1
		moveq.l	#12-1,d3
		for	d3
			move.l	-(a0),d0
			lsr.l	#2,d0
			move.l	d0,-(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
	;丸を付ける
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tandi.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print($t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%1111111111111111_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0111111111111110_0000000000000000,(a0)+
		andi.l	#%0011111111111100_0000000000000000,(a0)+
		andi.l	#%0001111111111000_0000000000000000,(a0)+
		andi.l	#%0000011111100000_0000000000000000,(a0)+
		movea.l	sp,a0
	;	perl -e "for$y(0..15){print qq(\t\tori.l\t#%);for$x(0..15){$t=($x-7.5)*($x-7.5)+($y-7.5)*($y-7.5);print(7**2<=$t&&$t<=8**2?'1':'0');}print qq(_0000000000000000,(a0)+\n);}"
		ori.l	#%0000011111100000_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%1000000000000001_0000000000000000,(a0)+
		ori.l	#%0100000000000010_0000000000000000,(a0)+
		ori.l	#%0110000000000110_0000000000000000,(a0)+
		ori.l	#%0011000000001100_0000000000000000,(a0)+
		ori.l	#%0001100000011000_0000000000000000,(a0)+
		ori.l	#%0000011111100000_0000000000000000,(a0)+
	endif
;----------------
;上線
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_OVERLINE_BIT,BIOS_ATTRIBUTE_2.w>,ne	;上線のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		or.l	d0,4*0(a1)
	endif
;----------------
;下付き
;	4x4の上2ドットと左2ドットをそれぞれORで1ドットにすることで、4x4を3x3に縮小する
;	SX-Windowと同じ方法
;	縦16ドットを12ドットに縮小し、下から1ドットの高さに配置する
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
;>d6.w:ドット幅。1～12
	if	<btst.b #BIOS_SUBSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;下付きのとき
		lea.l	subscript_pattern(pc),a2
		lea.l	4*16(sp),a0
		lea.l	4*15(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			subq.l	#8,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		;
			subq.l	#4,a0
			subq.l	#4,a1
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
		next
		clr.l	4*0(sp)
		clr.l	4*1(sp)
		clr.l	4*2(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;上付き
;	4x4の上2ドットと左2ドットをそれぞれORで1ドットにすることで、4x4を3x3に縮小する
;	SX-Windowと同じ方法
;	縦16ドットを12ドットに縮小し、上から0ドットの高さに配置する
;<d6.w:ドット幅。1～16
;<(sp).l[16]:フォントデータ
;>d6.w:ドット幅。1～12
	if	<btst.b #BIOS_SUPERSCRIPT_BIT,BIOS_ATTRIBUTE_2.w>,ne	;上付きのとき
		lea.l	subscript_pattern(pc),a2
		lea.l	4*0(sp),a0
		lea.l	4*0(sp),a1
		moveq.l	#0,d0
		moveq.l	#4-1,d3
		for	d3
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.b	4(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#6,d2
			move.b	5(a0),d0
			move.b	(a2,d0.w),d2
			lsl.w	#2,d2
			or.w	d2,d1
			move.w	d1,(a1)
			addq.l	#8,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		;
			move.b	(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#6,d1
			move.b	1(a0),d0
			move.b	(a2,d0.w),d1
			lsl.w	#2,d1
			move.w	d1,(a1)
			addq.l	#4,a0
			addq.l	#4,a1
		next
		clr.l	4*12(sp)
		clr.l	4*13(sp)
		clr.l	4*14(sp)
		clr.l	4*15(sp)
		moveq.l	#3,d0
		and.w	d6,d0
		lsr.w	#2,d6
		move.w	d6,d1
		add.w	d6,d6
		add.w	d1,d6
		add.w	d0,d6
	endif
;----------------
;反転
;	全体を反転させる
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
	if	<btst.b #BIOS_REVERSE_BIT,BIOS_ATTRIBUTE_1.w>,ne	;反転のとき
		movea.l	sp,a1			;フォントデータ
		moveq.l	#1,d0
		ror.l	d6,d0
		neg.l	d0
		moveq.l	#16-1,d3
		for	d3
			eor.l	d0,(a1)+
		next
	endif
;----------------
;マスクデータを作る
;<d6.w:ドット幅。1～17
;>4*16(sp).l[16]:マスクデータ
	lea.l	4*16(sp),a1		;マスクデータ
	moveq.l	#1,d0
	ror.l	d6,d0
	neg.l	d0
	moveq.l	#16-1,d3
	for	d3
		move.l	d0,(a1)+
	next
;----------------
;斜体
;	全体を右に0～3ドットずらす
;	プロポーショナルのとき幅が3ドット増える
;	斜体を続けて描画するときカーソルが動かなかったら3ドット詰める
;<d6.w:ドット幅。1～17
;<(sp).l[16]:フォントデータ
;<4*16(sp).l[16]:マスクデータ
;>d6.w:ドット幅。1～20
	if	<btst.b #BIOS_ITALIC_BIT,BIOS_ATTRIBUTE_1.w>,ne	;斜体のとき
		movea.l	sp,a0			;フォントデータ
		lea.l	4*16(sp),a1		;マスクデータ
*		if	<btst.b #BIOS_PROPORTIONAL_BIT,BIOS_ATTRIBUTE_2.w>,ne	;プロポーショナルのとき
			moveq.l	#3,d3
			do
				moveq.l	#4-1,d2
				for	d2
					move.l	(a0),d0
					lsr.l	d3,d0
					move.l	d0,(a0)+
					move.l	(a1),d0
					lsr.l	d3,d0
					move.l	d0,(a1)+
				next
				subq.w	#1,d3
			while	ne
			addq.w	#3,d6			;幅が3ドット増える
			bset.b #BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
			if	ne			;連結のとき
				subq.b	#3,BIOS_CURSOR_FRACTION.w	;3ドット詰める
				if	cs
					addq.b	#8,BIOS_CURSOR_FRACTION.w
					subq.w	#1,BIOS_CURSOR_COLUMN.w
					if	cs
						clr.w	BIOS_CURSOR_COLUMN.w	;念の為
						clr.b	BIOS_CURSOR_FRACTION.w
					endif
				endif
			endif
*		else				;プロポーショナルではないとき
*			moveq.l	#1,d4
*			ror.l	d6,d4
*			neg.l	d4
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#2,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a1)+
*			next
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsr.l	#1,d0
*				and.l	d4,d0			;幅を増やさない
*				move.l	d0,(a1)+
*			next
*			lea.l	4*4(a0),a0
*			lea.l	4*4(a1),a1
*			moveq.l	#4-1,d2
*			for	d2
*				move.l	(a0),d0
*				lsl.l	#1,d0
*				move.l	d0,(a0)+
*				move.l	(a1),d0
*				lsl.l	#1,d0
*				move.l	d0,(a1)+
*			next
*		endif
	else				;斜体ではないとき
		bclr.b	#BIOS_CONNECTION_BIT,BIOS_CONSOLE_STATUS.w
	endif
;----------------
;現在の行に入り切らなければ改行する
;<d6.w:ドット幅
	move.w	BIOS_CONSOLE_RIGHT.w,d0
	addq.w	#1,d0
	lsl.w	#3,d0			;コンソールのドット幅
	move.w	BIOS_CURSOR_COLUMN.w,d1
	lsl.w	#3,d1
	add.b	BIOS_CURSOR_FRACTION.w,d1	;カーソルのXドット座標
	sub.w	d1,d0			;コンソールのドット幅-カーソルのXドット座標=残りドット幅
	if	le			;残りドット幅<=0。既にはみ出している
	;改行する
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	elif	<cmp.w d6,d0>,lt	;残りドット幅<ドット幅。入り切らない
	;残りを空白で埋める
		move.w	BIOS_CURSOR_ROW.w,d0	;上端の行座標
		move.w	d0,d1			;下端の行座標
		move.w	BIOS_CURSOR_COLUMN.w,d2	;左端の桁座標
		move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
		moveq.l	#7,d4
		and.b	BIOS_CURSOR_FRACTION.w,d4	;左端の桁座標の端数
		moveq.l	#7,d5			;右端の桁座標の端数
		bsr	putc_clear		;消去する
		;改行する
		move.w	BIOS_CURSOR_ROW.w,d0
		if	<cmp.w BIOS_CONSOLE_BOTTOM.w,d0>,lo	;下端ではないとき
			addq.w	#1,d0			;1行下へ
			move.w	d0,BIOS_CURSOR_ROW.w
		else				;下端のとき
			moveq.l	#1,d0			;コピー元の上端の行座標
			move.w	BIOS_CONSOLE_BOTTOM.w,d1	;コピー元の下端の行座標
			moveq.l	#0,d2			;コピー先の上端の行座標
			bsr	putc_copy_rows		;行をコピーする
			move.w	BIOS_CONSOLE_BOTTOM.w,d0	;上端の行座標
			move.w	d0,d1			;下端の行座標
			bsr	putc_clear_rows		;行を消去する
		endif
		clr.w	BIOS_CURSOR_COLUMN.w	;左端へ
		clr.b	BIOS_CURSOR_FRACTION.w
	endif
;----------------
;文字を描く
;<d6.w:ドット幅
;<(sp).l[16]:フォントデータ
;<4*16(sp).l[16]:マスクデータ
	move.w	BIOS_CURSOR_ROW.w,d0	;行座標
	move.w	BIOS_CURSOR_COLUMN.w,d1	;桁座標
	moveq.l	#7,d2
	and.b	BIOS_CURSOR_FRACTION.w,d2	;桁座標の端数
	move.w	d6,d3			;ドット幅
	moveq.l	#3,d4
	and.b	BIOS_ATTRIBUTE_1.w,d4	;プレーン
	movea.l	sp,a0			;フォントデータ
	lea.l	4*16(sp),a1		;マスクデータ
	bsr	putc_draw		;文字を描く
;----------------
;カーソルを進める
;<d6.w:ドット幅
	add.b	BIOS_CURSOR_FRACTION.w,d6	;カーソルの桁座標の端数+ドット幅
	moveq.l	#7,d0
	and.w	d6,d0
	move.b	d0,BIOS_CURSOR_FRACTION.w	;カーソルの桁座標の端数
	lsr.w	#3,d6
	add.w	d6,BIOS_CURSOR_COLUMN.w	;カーソルの桁座標。ちょうど右端になる場合があるがここでは改行しない
;----------------
;カーソルON
	bsr	iocs_1E_B_CURON
;----------------
putc_output_end:
	lea.l	4*16+4*16(sp),sp	;フォントデータとマスクデータ
	pop
	rts

;----------------------------------------------------------------
;下付きで使うパターン
;	□□■□■■□■
subscript_pattern:
  .irp ff,%00000000,%10000000,%10000000,%10000000
    .irp ee,%00000000,%01000000
      .irp dd,%00000000,%00100000
        .irp cc,%00000000,%00010000,%00010000,%00010000
          .irp bb,%00000000,%00001000
            .irp aa,%00000000,%00000100
	.dc.b	ff+ee+dd+cc+bb+aa
            .endm
          .endm
        .endm
      .endm
    .endm
  .endm

;----------------------------------------------------------------
;文字を描く
;<d0.l:行座標
;<d1.l:桁座標
;<d2.l:桁座標の端数
;<d3.l:ドット幅
;<d4.l:プレーン。文字属性1の下位2ビット
;<(a0).l[16]:フォントデータ。左寄せ。リバースを含めて加工済み
;<(a1).l[16]:マスクデータ。左寄せ。書き込むビットが1
putc_draw:
	push	d0-d5/a0-a4
;----------------
;アドレスを求める
	swap.w	d0
	clr.w	d0			;65536*行座標
	lsr.l	#5,d0			;128*16*行座標
	add.w	d1,d0			;128*16*行座標+桁座標
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;描き始めるアドレスのオフセット
	add.l	#$00E00000,d0		;描き始めるアドレス
	bclr.l	#0,d0			;偶数にする
	if	ne
		addq.w	#8,d2
	endif
;<d2.w:桁座標の端数。0～15
	movea.l	d0,a4
;<a4.l:描き始めるアドレス。偶数
;?d0-d1
;----------------
	add.w	d2,d3			;桁座標の端数+ドット幅
;<d3.w:桁座標の端数+ドット幅
;----------------
;1ワードに収まるか、2ワードに跨るか、3ワードに跨るか
	if	<cmp.w #16,d3>,ls
	;----------------
	;1ワードに収まるとき
		do				;プレーンのループ
			lsr.b	#1,d4
			if	cs			;プレーンに描画するとき
				movea.l	a0,a2			;フォントデータ
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.w	(a2)+,d0		;フォント
					move.w	(a3)+,d1		;マスク
					lsr.w	d2,d0
					lsr.w	d2,d1
					not.w	d1
					and.w	(a4),d1			;くり抜いて
					or.w	d1,d0			;合わせて
					move.w	d0,(a4)+		;書き込む
					addq.l	#4-2,a2
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;次のラスタ
				next
			else				;プレーンを消去するとき
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.w	(a3)+,d1		;マスク
					lsr.w	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;くり抜く
					addq.l	#4-2,a3
					lea.l	128-2(a4),a4		;次のラスタ
				next
			endif
			adda.l	#-128*16+128*1024,a4	;次のプレーン
		while	<cmpa.l #$00E40000,a4>,lo
	elif	<cmp.w #32,d3>,ls
	;----------------
	;2ワードに跨るとき
		do				;プレーンのループ
			lsr.b	#1,d4
			if	cs			;プレーンに描画するとき
				movea.l	a0,a2			;フォントデータ
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a2)+,d0		;フォント
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;くり抜いて
					or.l	d1,d0			;合わせて
					move.l	d0,(a4)+		;書き込む
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;次のラスタ
				next
			else				;プレーンを消去するとき
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;くり抜く
				;	addq.l	#4-4,a3
					lea.l	128-4(a4),a4		;次のラスタ
				next
			endif
			adda.l	#-128*16+128*1024,a4	;次のプレーン
		while	<cmpa.l #$00E40000,a4>,lo
	else
	;----------------
	;3ワードに跨るとき
		do				;プレーンのループ
			lsr.b	#1,d4
			if	cs			;プレーンに描画するとき
				movea.l	a0,a2			;フォントデータ
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a2)+,d0		;フォント
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.l	d1
					and.l	(a4),d1			;くり抜いて
					or.l	d1,d0			;合わせて
					move.l	d0,(a4)+		;書き込む
					move.w	-2(a2),d0		;フォント
					move.w	-2(a3),d1		;マスク
					swap.w	d0
					swap.w	d1
					clr.w	d0
					clr.w	d1
					lsr.l	d2,d0
					lsr.l	d2,d1
					not.w	d1
					and.w	(a4),d1			;くり抜いて
					or.w	d1,d0			;合わせて
					move.w	d0,(a4)+		;書き込む
				;	addq.l	#4-4,a2
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;次のラスタ
				next
			else				;プレーンを消去するとき
				movea.l	a1,a3			;マスクデータ
				moveq.l	#16-1,d5
				for	d5			;ラスタのループ
					move.l	(a3)+,d1		;マスク
					lsr.l	d2,d1
					not.l	d1
					and.l	d1,(a4)+		;くり抜く
					move.w	-2(a3),d1		;マスク
					swap.w	d1
					clr.w	d1
					lsr.l	d2,d1
					not.w	d1
					and.w	d1,(a4)+		;くり抜く
				;	addq.l	#4-4,a3
					lea.l	128-6(a4),a4		;次のラスタ
				next
			endif
			adda.l	#-128*16+128*1024,a4	;次のプレーン
		while	<cmpa.l #$00E40000,a4>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;行をコピーする
;	  ┌─────┐  ┌─────┐
;	  │          │┌├─────┤
;	  ├─────┤┘│    ↓    │d2
;	d0│    ↓    │  │    ↓    │
;	  │    ↓    │  │    ↓    │
;	d1│    ↓    │┌├─────┤
;	  ├─────┤┘│          │
;	  └─────┘  └─────┘
;	  ┌─────┐  ┌─────┐
;	  ├─────┤┐│          │
;	d0│    ↑    │└├─────┤
;	  │    ↑    │  │    ↑    │d2
;	d1│    ↑    │  │    ↑    │
;	  ├─────┤┐│    ↑    │
;	  │          │└├─────┤
;	  └─────┘  └─────┘
;<d0.w:コピー元の上端の行座標
;<d1.w:コピー元の下端の行座標
;<d2.w:コピー先の上端の行座標
putc_copy_rows:
	push	d0-d3/a0
	move.l	BIOS_CONSOLE_OFFSET.w,d3	;コンソールの左上のアドレスのオフセット
	lsr.l	#7,d3			;コンソールの上端のYドット座標
	lsr.w	#2,d3			;コンソールの上端のラスタブロック番号
	sub.w	d0,d1			;コピー元の下端の行座標-コピー元の上端の行座標=コピーする行数-1
	lsl.w	#2,d1			;コピーするラスタブロック数-4
	addq.w	#3,d1			;コピーするラスタブロック数-1
;<d1.w:コピーするラスタブロック数-1
	lsl.w	#2,d0
	add.w	d3,d0			;コピー元の上端のラスタブロック番号
;<d0.w:コピー元の上端のラスタブロック番号
	lsl.w	#2,d2
	add.w	d3,d2			;コピー先の上端のラスタブロック番号
;<d2.w:コピー先の上端のラスタブロック番号
	if	<cmp.w d0,d2>,ls	;上にずらすとき
		move.w	#$0101,d3		;ラスタブロック番号の増分
	else				;下にずらすとき
		add.w	d1,d0			;コピー元の下端のラスタブロック番号
		add.w	d1,d2			;コピー先の下端のラスタブロック番号
		move.w	#$FEFF,d3		;ラスタブロック番号の増分
	endif
;<d0.w:コピー元のラスタブロック番号
;<d2.w:コピー先のラスタブロック番号
;<d3.w:ラスタブロック番号の増分
	lsl.w	#8,d0			;コピー元のラスタブロック番号<<8
	move.b	d2,d0			;コピー元のラスタブロック番号<<8|コピー先のラスタブロック番号
;<d0.w:コピー元のラスタブロック番号<<8|コピー先のラスタブロック番号
aGPDR	reg	a0
	lea.l	MFP_GPDR,aGPDR		;GPIPデータレジスタ。HSYNC|RINT|-|VDISP|OPMIRQ|POWER|EXPWON|ALARM
	move.w	sr,d2
	for	d1			;ラスタブロックのループ
		do
		while	<tst.b (aGPDR)>,mi	;水平表示期間を待つ
		ori.w	#$0700,sr		;割り込みを禁止する
		do
		while	<tst.b (aGPDR)>,pl	;水平帰線期間を待つ
		move.w	d0,CRTC_BLOCK-MFP_GPDR(aGPDR)	;ラスタブロック番号を設定する
		move.w	#$0008,CRTC_ACTION-MFP_GPDR(aGPDR)	;ラスタコピーをONにする。2回目以降は不要
		move.w	d2,sr			;割り込みを許可する
		add.w	d3,d0			;次のラスタブロックへ
	next
	do
	while	<tst.b (aGPDR)>,mi	;水平表示期間を待つ
	ori.w	#$0700,sr		;割り込みを禁止する
	do
	while	<tst.b (aGPDR)>,pl	;水平帰線期間を待つ
	move.w	d2,sr			;割り込みを許可する
	clr.w	CRTC_ACTION-MFP_GPDR(aGPDR)	;ラスタコピーをOFFにする。必要
	pop
	rts

;----------------------------------------------------------------
;行を消去する
;<d0.w:上端の行座標
;<d1.w:下端の行座標
putc_clear_rows:
	push	d2-d5
	moveq.l	#0,d2			;左端の桁座標
	move.w	BIOS_CONSOLE_RIGHT.w,d3	;右端の桁座標
	moveq.l	#0,d4			;左端の桁座標の端数
	moveq.l	#7,d5			;右端の桁座標の端数
	bsr	putc_clear		;消去する
	pop
	rts

;----------------------------------------------------------------
;消去する
;	消去は空白の描画と同じ。背景色で塗り潰す
;		文字属性		文字色	背景色
;		0			黒	黒
;		1			水色	黒
;		2			黄色	黒
;		3			白	黒
;		4		太字	黒	黒
;		5		太字	水色	黒
;		6		太字	黄色	黒
;		7		太字	白	黒
;		8	反転		黒	黒
;		9	反転		黒	水色
;		10	反転		黒	黄色
;		11	反転		黒	白
;		12	反転	太字	黒	黒
;		13	反転	太字	黒	水色
;		14	反転	太字	黒	黄色
;		15	反転	太字	黒	白
;<d0.w:上端の行座標
;<d1.w:下端の行座標
;<d2.w:左端の桁座標
;<d3.w:右端の桁座標
;<d4.w:左端の桁座標の端数。0～7。これを含む
;<d5.w:右端の桁座標の端数。0～7。これを含む
putc_clear:
	push	d0-d7/a0-a3
;----------------
;ラスタ数を求める
	sub.w	d0,d1			;下端の行座標-上端の行座標=行数-1
	addq.w	#1,d1			;行数
	lsl.w	#4,d1			;16*行数=ラスタ数
	subq.w	#1,d1			;ラスタ数-1
	movea.w	d1,a3
;<a3.w:ラスタ数-1
;?d1
;----------------
;アドレスを求める
	swap.w	d0
	clr.w	d0			;65536*行座標
	lsr.l	#5,d0			;128*16*行座標
	add.l	BIOS_CONSOLE_OFFSET.w,d0	;上端の行の左上のアドレスのオフセット
	add.l	#$00E00000,d0		;上端の行の左上のアドレス
	ext.l	d2
	ext.l	d3
	add.l	d0,d2			;左上のアドレス
	add.l	d0,d3			;右上のアドレス
;<d2.l:左上のアドレス
;<d3.l:右上のアドレス
;?d0
;----------------
;アドレスを偶数にする
;	桁座標ではなくアドレスを偶数にする
;	_B_CONSOLはコンソールの左端のアドレスを偶数に制限していない
	bclr.l	#0,d2
	if	ne
		addq.w	#8,d4
	endif
;<d2.l:左上のアドレス。偶数
;<d4.w:左端の桁座標の端数。0～15
	bclr.l	#0,d3
	if	ne
		addq.w	#8,d5
	endif
;<d3.l:右上のアドレス。偶数
;<d5.w:右端の桁座標の端数。0～15
	movea.l	d2,a2
;<a2.l:左上のアドレス。偶数
;----------------
;ワード数を求める
	sub.w	d2,d3			;右端のアドレス-左端のアドレス=2*(ワード数-1)
	lsr.w	#1,d3			;ワード数-1
;<d3.w:ワード数-1
;?d2
;----------------
;マスクを作る
	moveq.l	#-1,d6
	move.w	#$8000,d7
	lsr.w	d4,d6			;左端の書き込む部分が1のマスク。$FFFF,$7FFF,…,$0003,$0001
	asr.w	d5,d7			;右端の書き込む部分が1のマスク。$8000,$C000,…,$FFFE,$FFFF
;<d6.w:左端の書き込む部分が1のマスク。$FFFF,$7FFF,…,$0003,$0001
;<d7.w:右端の書き込む部分が1のマスク。$8000,$C000,…,$FFFE,$FFFF
;?d4-d5
;----------------
;データを作る
	moveq.l	#%1111,d0
	and.b	BIOS_ATTRIBUTE_1.w,d0	;プレーン##
;		  111111
;		  5432109876543210
	move.w	#%1100110000000000,d2	;背景色が黄色または白。プレーン1を塗り潰す
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
	swap.w	d2
;		  111111
;		  5432109876543210
	move.w	#%1010101000000000,d2	;背景色が水色または白。プレーン0を塗り潰す
	btst.l	d0,d2
	sne.b	d2
	ext.w	d2
;<d2.l:プレーン1のデータ<<16|プレーン0のデータ
;----------------
;1ワードか1ワードではないか
	if	<tst.w d3>,eq
	;----------------
	;1ワードのとき
		and.w	d7,d6
	;<d6.w:書き込む部分が1のマスク
		and.w	d6,d2
		swap.w	d2
		and.w	d6,d2
		swap.w	d2
	;<d2.l:プレーン1のデータ<<16|プレーン0のデータ
		not.w	d6
	;<d6.w:書き込まない部分が1のマスク
		do				;プレーンのループ
			movea.l	a2,a0			;左上のアドレス→左端のアドレス
			move.w	a3,d1			;ラスタ数-1
			for	d1			;ラスタのループ
				move.w	(a0),d0
				and.w	d6,d0			;マスク
				or.w	d2,d0			;データ
				move.w	d0,(a0)
				lea.l	128(a0),a0		;次の左端のアドレス
			next
			swap.w	d2			;次のプレーンのデータ
			adda.l	#128*1024,a2		;次のプレーンの左上のアドレス
		while	<cmpa.l #$00E40000,a2>,lo
	else
	;----------------
	;1ワードではないとき
		subq.w	#1,d3
	;<d3.w:左端と右端の間のワード数。0～
		move.l	d2,d4
		move.l	d2,d5
	;<d4.l:プレーン1のデータ<<16|プレーン0のデータ
	;<d5.l:プレーン1のデータ<<16|プレーン0のデータ
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
		and.w	d6,d4
		and.w	d7,d5
		swap.w	d4
		swap.w	d5
	;<d4.l:プレーン1の左端のデータ<<16|プレーン0の左端のデータ
	;<d5.l:プレーン1の右端のデータ<<16|プレーン0の右端のデータ
		not.w	d6
		not.w	d7
	;<d6.w:左端の書き込まない部分が1のマスク。$0000,$8000,…,$FFFC,$FFFE
	;<d7.w:右端の書き込まない部分が1のマスク。$7FFF,$3FFF,…,$0001,$0000
		do				;プレーンのループ
			movea.l	a2,a1			;左上のアドレス→左端のアドレス
			move.w	a3,d1			;ラスタ数-1
			for	d1			;ラスタのループ
				movea.l	a1,a0			;左端のアドレス→桁のアドレス
			;左端
				move.w	(a0),d0
				and.w	d6,d0			;左端のマスク
				or.w	d4,d0			;左端のデータ
				move.w	d0,(a0)+
			;左端と右端の間
				move.w	d3,d0			;左端と右端の間のワード数。0～
				forcontinue	d0
					move.w	d2,(a0)+		;データ
				next
			;右端
				move.w	(a0),d0
				and.w	d7,d0			;右端のマスク
				or.w	d5,d0			;右端のデータ
				move.w	d0,(a0)+
				lea.l	128(a1),a1		;次の左端のアドレス
			next
			swap.w	d2			;次のプレーンのデータ
			swap.w	d4			;次のプレーンの左端のデータ
			swap.w	d5			;次のプレーンの右端のデータ
			adda.l	#128*1024,a2		;次のプレーンの左上のアドレス
		while	<cmpa.l #$00E40000,a2>,lo
	endif
	pop
	rts

;----------------------------------------------------------------
;プロポーショナルフォント($20～$82)
proportional_font:
	.dc.w	6	;$20   
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$21 ！
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0111000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$22 ”
	.dc.w	%0000000000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0010001000000000
	.dc.w	%0010001000000000
	.dc.w	%0100010000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$23 ＃
	.dc.w	%0000000000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0001001000000000
	.dc.w	%0111111100000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%0010010000000000
	.dc.w	%1111111000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0100100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$24 ＄
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%1001001000000000
	.dc.w	%1101000000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%0001011000000000
	.dc.w	%1001001000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$25 ％
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001000010000000
	.dc.w	%1001000100000000
	.dc.w	%1001001000000000
	.dc.w	%0110010000000000
	.dc.w	%0000100000000000
	.dc.w	%0001001100000000
	.dc.w	%0010010010000000
	.dc.w	%0100010010000000
	.dc.w	%1000010010000000
	.dc.w	%0000001100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$26 ＆
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%1000100000000000
	.dc.w	%0101000000000000
	.dc.w	%0011000000000000
	.dc.w	%0100100100000000
	.dc.w	%1000010100000000
	.dc.w	%1000001000000000
	.dc.w	%1000010100000000
	.dc.w	%0111100010000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$27 ’
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$28 （
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$29 ）
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2A ＊
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%1001001000000000
	.dc.w	%0101010000000000
	.dc.w	%0011100000000000
	.dc.w	%0101010000000000
	.dc.w	%1001001000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$2B ＋
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%1111111000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$2C ，
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2D －
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2E ．
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$2F ／
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$30 ０
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$31 １
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001100000000000
	.dc.w	%0011100000000000
	.dc.w	%0111100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$32 ２
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100000000000000
	.dc.w	%1111111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$33 ３
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0001110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$34 ４
	.dc.w	%0000000000000000
	.dc.w	%0000001000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111000000000
	.dc.w	%0001111000000000
	.dc.w	%0011011000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1111111100000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$35 ５
	.dc.w	%0000000000000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%0000011000000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$36 ６
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%0111110000000000
	.dc.w	%1110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$37 ７
	.dc.w	%0000000000000000
	.dc.w	%1111111100000000
	.dc.w	%1100001100000000
	.dc.w	%1100011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$38 ８
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$39 ９
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011111000000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3A ：
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$3B ；
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3C ＜
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3D ＝
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3E ＞
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$3F ？
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$40 ＠
	.dc.w	%0000000000000000
	.dc.w	%0001111100000000
	.dc.w	%0010000010000000
	.dc.w	%0100000001000000
	.dc.w	%1000111001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001001001000000
	.dc.w	%1001110110000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0011111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$41 Ａ
	.dc.w	%0000000000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0001011000000000
	.dc.w	%0010001100000000
	.dc.w	%0010001100000000
	.dc.w	%0011111100000000
	.dc.w	%0100000110000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$42 Ｂ
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$43 Ｃ
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$44 Ｄ
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0110001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110001100000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$45 Ｅ
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$46 Ｆ
	.dc.w	%0000000000000000
	.dc.w	%1111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000010000000
	.dc.w	%0110000000000000
	.dc.w	%0110001000000000
	.dc.w	%0111111000000000
	.dc.w	%0110001000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$47 Ｇ
	.dc.w	%0000000000000000
	.dc.w	%0001111010000000
	.dc.w	%0110000110000000
	.dc.w	%1100000010000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100001111000000
	.dc.w	%1100000010000000
	.dc.w	%1100000010000000
	.dc.w	%0110000100000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$48 Ｈ
	.dc.w	%0000000000000000
	.dc.w	%1111001111000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111111110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%1111001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$49 Ｉ
	.dc.w	%0000000000000000
	.dc.w	%1111110000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%0011000000000000
	.dc.w	%1111110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$4A Ｊ
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%1100110000000000
	.dc.w	%0011000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4B Ｋ
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111110000000000
	.dc.w	%0110011000000000
	.dc.w	%0110011000000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$4C Ｌ
	.dc.w	%0000000000000000
	.dc.w	%1111000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000010000000
	.dc.w	%0110000110000000
	.dc.w	%1111111110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	13	;$4D Ｍ
	.dc.w	%0000000000000000
	.dc.w	%1110000001110000
	.dc.w	%0110000001100000
	.dc.w	%0111000001100000
	.dc.w	%0111000011100000
	.dc.w	%0111100011100000
	.dc.w	%0101100101100000
	.dc.w	%0101110101100000
	.dc.w	%0100111001100000
	.dc.w	%0100111001100000
	.dc.w	%0100010001100000
	.dc.w	%1110010011110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	12	;$4E Ｎ
	.dc.w	%0000000000000000
	.dc.w	%1100000011100000
	.dc.w	%0110000001000000
	.dc.w	%0111000001000000
	.dc.w	%0111100001000000
	.dc.w	%0101110001000000
	.dc.w	%0100111001000000
	.dc.w	%0100011101000000
	.dc.w	%0100001111000000
	.dc.w	%0100000111000000
	.dc.w	%0100000011000000
	.dc.w	%1110000001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$4F Ｏ
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%0110000110000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$50 Ｐ
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$51 Ｑ
	.dc.w	%0000000000000000
	.dc.w	%0001111000000000
	.dc.w	%0110000110000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1100000011000000
	.dc.w	%1101110011000000
	.dc.w	%1111011110000000
	.dc.w	%0110001100000000
	.dc.w	%0001111100000000
	.dc.w	%0000000110000000
	.dc.w	%0000000011000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$52 Ｒ
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%0110000110000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000011000000
	.dc.w	%0110000110000000
	.dc.w	%0111111000000000
	.dc.w	%0110111000000000
	.dc.w	%0110011100000000
	.dc.w	%0110001110000000
	.dc.w	%1111000111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$53 Ｓ
	.dc.w	%0000000000000000
	.dc.w	%0001110100000000
	.dc.w	%0110001100000000
	.dc.w	%1100000100000000
	.dc.w	%1110000000000000
	.dc.w	%0111000000000000
	.dc.w	%0011110000000000
	.dc.w	%0000111000000000
	.dc.w	%0000011100000000
	.dc.w	%1000001100000000
	.dc.w	%1100011000000000
	.dc.w	%1011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$54 Ｔ
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100110011000000
	.dc.w	%1000110001000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0011111100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$55 Ｕ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0000111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$56 Ｖ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	16	;$57 Ｗ
	.dc.w	%0000000000000000
	.dc.w	%1111000110001110
	.dc.w	%0110000110000100
	.dc.w	%0011000111000100
	.dc.w	%0011000111000100
	.dc.w	%0011001011001000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0001101001101000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000110000110000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$58 Ｘ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000111000000000
	.dc.w	%0001001100000000
	.dc.w	%0010001100000000
	.dc.w	%0100000110000000
	.dc.w	%1110001111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$59 Ｙ
	.dc.w	%0000000000000000
	.dc.w	%1111000111000000
	.dc.w	%0110000010000000
	.dc.w	%0011000100000000
	.dc.w	%0011000100000000
	.dc.w	%0001101000000000
	.dc.w	%0001101000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0000110000000000
	.dc.w	%0001111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	11	;$5A Ｚ
	.dc.w	%0000000000000000
	.dc.w	%1111111111000000
	.dc.w	%1100000011000000
	.dc.w	%1000000110000000
	.dc.w	%0000001100000000
	.dc.w	%0000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000001000000
	.dc.w	%1100000011000000
	.dc.w	%1111111111000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5B ［
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5C ￥
	.dc.w	%0000000000000000
	.dc.w	%1000001000000000
	.dc.w	%1000001000000000
	.dc.w	%0100010000000000
	.dc.w	%0100010000000000
	.dc.w	%0010100000000000
	.dc.w	%0010100000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0111110000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5D ］
	.dc.w	%0000000000000000
	.dc.w	%0111000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$5E ＾
	.dc.w	%0000000000000000
	.dc.w	%0001000000000000
	.dc.w	%0010100000000000
	.dc.w	%0100010000000000
	.dc.w	%1000001000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$5F ＿
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$60 ｀
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$61 ａ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110000000000
	.dc.w	%1100111000000000
	.dc.w	%0000011000000000
	.dc.w	%0011111000000000
	.dc.w	%0110011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100111000000000
	.dc.w	%0111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$62 ｂ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0110000110000000
	.dc.w	%0111001100000000
	.dc.w	%1101111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$63 ｃ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$64 ｄ
	.dc.w	%0000000000000000
	.dc.w	%0000011100000000
	.dc.w	%0000001100000000
	.dc.w	%0000001100000000
	.dc.w	%0011101100000000
	.dc.w	%0110011100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011101110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$65 ｅ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%1100000000000000
	.dc.w	%1100000000000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$66 ｆ
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$67 ｇ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111110100000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%0111110000000000
	.dc.w	%1100000000000000
	.dc.w	%0111111000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0111111000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$68 ｈ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$69 ｉ
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$6A ｊ
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0011100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%0001100000000000
	.dc.w	%1101100000000000
	.dc.w	%0111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6B ｋ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110111000000000
	.dc.w	%0110010000000000
	.dc.w	%0110100000000000
	.dc.w	%0111000000000000
	.dc.w	%0111100000000000
	.dc.w	%0110110000000000
	.dc.w	%0110011000000000
	.dc.w	%1111011100000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	5	;$6C ｌ
	.dc.w	%0000000000000000
	.dc.w	%1110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	15	;$6D ｍ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1101111011110000
	.dc.w	%0111011110111000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%0110001100011000
	.dc.w	%1111011110111100
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$6E ｎ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%1111011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$6F ｏ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0011110000000000
	.dc.w	%0110011000000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%1100001100000000
	.dc.w	%0110011000000000
	.dc.w	%0011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$70 ｐ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0111011100000000
	.dc.w	%0110111000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$71 ｑ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111011100000000
	.dc.w	%1110111000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1100011000000000
	.dc.w	%1110111000000000
	.dc.w	%0111011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000011000000000
	.dc.w	%0000111100000000
	.dc.w	%0000000000000000
	.dc.w	9	;$72 ｒ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110111000000000
	.dc.w	%0111001100000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$73 ｓ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0111101000000000
	.dc.w	%1100011000000000
	.dc.w	%1100001000000000
	.dc.w	%0111100000000000
	.dc.w	%0011110000000000
	.dc.w	%1000011000000000
	.dc.w	%1100011000000000
	.dc.w	%1011110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	7	;$74 ｔ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%1111100000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110000000000000
	.dc.w	%0110110000000000
	.dc.w	%0011100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$75 ｕ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1110011100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110001100000000
	.dc.w	%0110011100000000
	.dc.w	%0011110110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	9	;$76 ｖ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0110010000000000
	.dc.w	%0011010000000000
	.dc.w	%0011100000000000
	.dc.w	%0011100000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	14	;$77 ｗ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001000111000
	.dc.w	%0110001100010000
	.dc.w	%0110001100010000
	.dc.w	%0011010110100000
	.dc.w	%0011010110100000
	.dc.w	%0001110011100000
	.dc.w	%0001100011000000
	.dc.w	%0000100001000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$78 ｘ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111011100000000
	.dc.w	%0110001000000000
	.dc.w	%0011010000000000
	.dc.w	%0001100000000000
	.dc.w	%0001110000000000
	.dc.w	%0010011000000000
	.dc.w	%0100001100000000
	.dc.w	%1110011110000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	10	;$79 ｙ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111001110000000
	.dc.w	%0110000100000000
	.dc.w	%0110000100000000
	.dc.w	%0011001000000000
	.dc.w	%0011001000000000
	.dc.w	%0001110000000000
	.dc.w	%0001110000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0110000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7A ｚ
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%1111111000000000
	.dc.w	%1000011000000000
	.dc.w	%0000110000000000
	.dc.w	%0001100000000000
	.dc.w	%0011000000000000
	.dc.w	%0110000000000000
	.dc.w	%1100001000000000
	.dc.w	%1111111000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7B ｛
	.dc.w	%0000000000000000
	.dc.w	%0001100000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0100000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7C ｜
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7D ｝
	.dc.w	%0000000000000000
	.dc.w	%1100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0001000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%1100000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$7E ￣
	.dc.w	%0000000000000000
	.dc.w	%1111100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$7F DL
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$80 ＼
	.dc.w	%0000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%1000000000000000
	.dc.w	%0100000000000000
	.dc.w	%0100000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0001000000000000
	.dc.w	%0001000000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000100000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	8	;$81 ～
	.dc.w	%0000000000000000
	.dc.w	%0110000000000000
	.dc.w	%1001001000000000
	.dc.w	%0000110000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	6	;$82 ￤
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0010000000000000
	.dc.w	%0000000000000000
	.dc.w	%0000000000000000



;----------------------------------------------------------------
;
;	SASI IOCS
;
;----------------------------------------------------------------

SASI_OFFSET	equ	-$95B6+$CCB8

;----------------------------------------------------------------
;	絶対アドレス
;		リロケートする
;	変更前
;		000095BE 49F9(01)00009E30 	lea.l	sasi_seek_command,a4		;SEEKコマンド
;----------------------------------------------------------------
	PATCH_DATA	p95be,$00FF95BE+SASI_OFFSET,$00FF95BE+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E30+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		00009650 49F9(01)00009E3C 		lea.l	sasi_set_drive_parameter_command,a4	;SET DRIVE PARAMETERコマンド
;----------------------------------------------------------------
	PATCH_DATA	p9650,$00FF9650+SASI_OFFSET,$00FF9650+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		0000965E 49F9(01)00009E60 			lea.l	sasi_20mb_shipping_parameter,a4	;20MBドライブパラメータ(シッピングゾーン)
;----------------------------------------------------------------
	PATCH_DATA	p965E,$00FF965E+SASI_OFFSET,$00FF965E+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E60+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		00009684 43F9(01)00009E42 					lea.l	sasi_10mb_drive_parameter,a1	;10MBドライブパラメータ
;----------------------------------------------------------------
	PATCH_DATA	p9684,$00FF9684+SASI_OFFSET,$00FF9684+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009694 43F9(01)00009E42 						lea.l	sasi_10mb_drive_parameter,a1	;10MBドライブパラメータ
;----------------------------------------------------------------
	PATCH_DATA	p9694,$00FF9694+SASI_OFFSET,$00FF9694+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		000096C8 49F9(01)00009E3C 						lea.l	sasi_set_drive_parameter_command,a4		;SET DRIVE PARAMETERコマンド
;----------------------------------------------------------------
	PATCH_DATA	p96C8,$00FF96C8+SASI_OFFSET,$00FF96C8+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		00009728 49F9(01)00009E0C 	lea.l	sasi_test_drive_ready_command,a4	;TEST DRIVE READYコマンド
;----------------------------------------------------------------
	PATCH_DATA	p9728,$00FF9728+SASI_OFFSET,$00FF9728+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E0C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		000097B0 49F9(01)00009E2A 	lea.l	sasi_write_command,a4	;WRITEコマンド
;----------------------------------------------------------------
	PATCH_DATA	p97B0,$00FF97B0+SASI_OFFSET,$00FF97B0+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E2A+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		00009854 49F9(01)00009E24 	lea.l	sasi_read_command,a4		;READコマンド
;----------------------------------------------------------------
	PATCH_DATA	p9854,$00FF9854+SASI_OFFSET,$00FF9854+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E24+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		000098A6 49F9(01)00009E36 	lea.l	sasi_format_alternate_track_command,a4		;FORAMT ALTERNATE TRACKコマンド
;----------------------------------------------------------------
	PATCH_DATA	p98A6,$00FF98A6+SASI_OFFSET,$00FF98A6+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E36+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		000098D6 49F9(01)00009E1E 	lea.l	sasi_format_bad_track_command,a4	;FORMAT BAD TRACKコマンド
;----------------------------------------------------------------
	PATCH_DATA	p98D6,$00FF98D6+SASI_OFFSET,$00FF98D6+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E1E+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		000098FE 49F9(01)00009E18 	lea.l	sasi_format_track_command,a4		;FORMAT TRACKコマンド
;----------------------------------------------------------------
	PATCH_DATA	p98FE,$00FF98FE+SASI_OFFSET,$00FF98FE+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E18+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		0000993A 43F9(01)00009E56 	lea.l	sasi_20mb_drive_parameter,a1	;20MBドライブパラメータ
;----------------------------------------------------------------
	PATCH_DATA	p993A,$00FF993A+SASI_OFFSET,$00FF993A+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E56+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009946 43F9(01)00009E6A 		lea.l	sasi_40mb_drive_parameter,a1	;40MBドライブパラメータ
;----------------------------------------------------------------
	PATCH_DATA	p9946,$00FF9946+SASI_OFFSET,$00FF9946+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E6A+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009952 43F9(01)00009E42 			lea.l	sasi_10mb_drive_parameter,a1	;10MBドライブパラメータ
;----------------------------------------------------------------
	PATCH_DATA	p9952,$00FF9952+SASI_OFFSET,$00FF9952+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009972 43F9(01)00009E42 				lea.l	sasi_10mb_drive_parameter,a1	;10MBドライブパラメータ
;----------------------------------------------------------------
	PATCH_DATA	p9972,$00FF9972+SASI_OFFSET,$00FF9972+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E42+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		000099B2 49F9(01)00009E3C 		lea.l	sasi_set_drive_parameter_command,a4	;SET DRIVE PARAMETERコマンド
;----------------------------------------------------------------
	PATCH_DATA	p99B2,$00FF99B2+SASI_OFFSET,$00FF99B2+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		000099FE 43F9(01)00009E60 			lea.l	sasi_20mb_shipping_parameter,a1
;----------------------------------------------------------------
	PATCH_DATA	p99FE,$00FF99FE+SASI_OFFSET,$00FF99FE+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E60+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009A10 43F9(01)00009E74 				lea.l	sasi_40mb_shipping_parameter,a1
;----------------------------------------------------------------
	PATCH_DATA	p9A10,$00FF9A10+SASI_OFFSET,$00FF9A10+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E74+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009A22 43F9(01)00009E4C 					lea.l	sasi_10mb_shipping_parameter,a1
;----------------------------------------------------------------
	PATCH_DATA	p9A22,$00FF9A22+SASI_OFFSET,$00FF9A22+5+SASI_OFFSET,$43F900FF
	lea.l	$00FF9E4C+SASI_OFFSET,a1
;----------------------------------------------------------------
;	変更前
;		00009A2E 49F9(01)00009E3C 				lea.l	sasi_set_drive_parameter_command,a4	;SET DRIVE PARAMETERコマンド
;----------------------------------------------------------------
	PATCH_DATA	p9A2E,$00FF9A2E+SASI_OFFSET,$00FF9A2E+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E3C+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		00009A48 49F9(01)00009E30 							lea.l	sasi_seek_command,a4	;SEEKコマンド
;----------------------------------------------------------------
	PATCH_DATA	p9A48,$00FF9A48+SASI_OFFSET,$00FF9A48+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E30+SASI_OFFSET,a4
;----------------------------------------------------------------
;	変更前
;		00009D76 49F9(01)00009E12 		lea.l	sasi_recalibrate_command,a4	;RECALIBRATEコマンド
;----------------------------------------------------------------
	PATCH_DATA	p9D76,$00FF9D76+SASI_OFFSET,$00FF9D76+5+SASI_OFFSET,$49F900FF
	lea.l	$00FF9E12+SASI_OFFSET,a4

;----------------------------------------------------------------
;	SASIベリファイ(1024バイト以下)
;	問題
;		https://twitter.com/kamadox/status/1361214698226479109
;		IOCS _B_VERIFYがSASIハードディスクのとき対象をスーパーバイザスタックに読み込んでメモリ上でデータを比較している
;		つまりOSの検査を受けていないバッファにDMA転送している
;		この構造はまずい。ローカルメモリがあるときスーパーバイザスタックにDMAが届くとは限らない
;	対策
;		比較するデータは直前にディスクに書き込んだデータでありそのバッファはDMA転送可能な領域にあることが期待できる
;		(1)バッファの先頭アドレスが$00F00000～$00FFFFFFの範囲にあるとき比較を行わず常に成功を返す
;		(2)比較するデータをバッファからスタックへコピーする
;		(3)比較されるデータをディスクからバッファへ読み込む
;		(4)読み込み成功のときバッファとスタックを比較する
;		(5)読み込み失敗または不一致のとき比較するデータをスタックからバッファへコピーする
;----------------------------------------------------------------
	PATCH_DATA	p9618,$00FF9618+SASI_OFFSET,$00FF963F+SASI_OFFSET,$4FEFFC00
	jmp	sasi_verify_1024
	PATCH_TEXT
;<d1.w:$8000|HD-ID(0～15)<<8
;<d2.l:レコード番号
;<d3.w:バイト数。1024以下
;<a1.l:バッファの先頭アドレス
;>d0.l:0=成功,-2=失敗
sasi_verify_1024:
	push	d4/a0-a1/a6,1024
;(1)バッファの先頭アドレスが$00F00000～$00FFFFFFの範囲にあるとき比較を行わず常に成功を返す
	moveq.l	#0,d0			;成功
	gotoand	<cmpa.l #$00F00000,a1>,hs,<cmpa.l #$00FFFFFF,a1>,ls,90f
;(2)比較するデータをバッファからスタックへコピーする
	movea.l	a1,a6			;バッファ
;	movea.l	a6,a1			;バッファ
	movea.l	sp,a0			;スタック
	move.w	d3,d4
	subq.w	#1,d4
	for	d4
		move.b	(a1)+,(a0)+
	next
;(3)比較されるデータをディスクからバッファへ読み込む
	movea.l	a6,a1			;バッファ
	jsr	$00FF9826+SASI_OFFSET	;sasi_read_modify。d1-d3/a1/a6は破壊されない
	goto	<tst.b d0>,ne,10f	;読み込み失敗
;読み込み成功
;(4)読み込み成功のときバッファとスタックを比較する
	moveq.l	#0,d0			;成功
;	movea.l	a6,a1			;バッファ
	movea.l	sp,a0			;スタック
	move.w	d3,d4
	subq.w	#1,d4
	for	d4
		cmpm.b	(a1)+,(a0)+
	next	eq
	goto	eq,90f			;一致
;不一致
	moveq.l	#-2,d0			;失敗
;(5)読み込み失敗または不一致のとき比較するデータをスタックからバッファへコピーする
10:	movea.l	sp,a1			;スタック
	movea.l	a6,a0			;バッファ
	move.w	d3,d4
	subq.w	#1,d4
	for	d4
		move.b	(a1)+,(a0)+
	next
90:	pop
	rts

;----------------------------------------------------------------
;	sasi_write_retryのループ
;		これはリトライ回数なのでこのまま
;	変更前
;		00009798 3F3C0064         	move.w	#100,-(sp)
;----------------------------------------------------------------

;----------------------------------------------------------------
;	sasi_read_retryのループ
;		これはリトライ回数なのでこのまま
;	変更前
;		0000983C 3F3C0064         	move.w	#100,-(sp)
;----------------------------------------------------------------

;----------------------------------------------------------------
;	sasi_preprocessのループ
;		バスフリーフェーズを待つ。要調整
;	変更前
;		00009AA4 203C000000C8     	move.l	#201-1,d0
;----------------------------------------------------------------
	PATCH_DATA	p9AA4,$00FF9AA4+SASI_OFFSET,$00FF9AA4+5+SASI_OFFSET,$203C0000
	move.w	BIOS_MPU_SPEED_ROM.w,d0
	lsr.w	#2,d0			;(10*1000/12)/4=208

;----------------------------------------------------------------
;	sasi_do_selectのループ
;		バスフリーフェーズを待つ。要調整
;	変更前
;		00009B24 203C000007D0     		move.l	#2001-1,d0
;----------------------------------------------------------------
	PATCH_DATA	p9B24,$00FF9B24+SASI_OFFSET,$00FF9B24+5+SASI_OFFSET,$203C0000
	jsr	p9b24
	PATCH_TEXT
p9b24:
	move.w	BIOS_MPU_SPEED_ROM.w,d0
	mulu.w	#3,d0			;(10*1000/12)*3=2500
	rts
;----------------------------------------------------------------
;	変更前
;		00009B34*51C8FFF4_00009B2A	dbra	~~forDn,~~redo68
;----------------------------------------------------------------
	PATCH_DATA	p9B34,$00FF9B34+SASI_OFFSET,$00FF9B34+3+SASI_OFFSET,$51C8FFF4
	subq.l	#1,d0
	bcc.s	(*)-$9B36+$9B2A

;----------------------------------------------------------------
;	sasi_do_select_10のループ
;		BSYがセットされるのを待つ。要調整
;	変更前
;		00009B64 203C00001388     	move.l	#5000,d0
;----------------------------------------------------------------
	PATCH_DATA	p9B64,$00FF9B64+SASI_OFFSET,$00FF9B64+5+SASI_OFFSET,$203C0000
	jsr	p9b64
	PATCH_TEXT
p9b64:
	move.w	BIOS_MPU_SPEED_ROM.w,d0
	mulu.w	#6,d0			;(10*1000/12)*6=5000
	rts

;----------------------------------------------------------------
;	sasi_stsin_msginのsasi_wait_statusの引数
;		ステータスフェーズとメッセージフェーズを待つ。要調整
;	変更前
;		00009B94 2A3C004C4B40     	move.l	#5000000,d5
;----------------------------------------------------------------
	PATCH_DATA	p9B94,$00FF9B94+SASI_OFFSET,$00FF9B94+5+SASI_OFFSET,$2A3C004C
	jsr	p9b94
	PATCH_TEXT
p9b94:
	move.w	BIOS_MPU_SPEED_ROM.w,d5
	mulu.w	#6000,d5		;(10*1000/12)*6000=5000000
	rts
;----------------------------------------------------------------
;	変更前
;		00009BA8 2A3C0001E848     		move.l	#125000,d5
;----------------------------------------------------------------
	PATCH_DATA	p9BA8,$00FF9BA8+SASI_OFFSET,$00FF9BA8+5+SASI_OFFSET,$2A3C0001
	jsr	p9ba8
	PATCH_TEXT
p9ba8:
	move.w	BIOS_MPU_SPEED_ROM.w,d5
	mulu.w	#150,d5			;(10*1000/12)*150=125000
	rts

;----------------------------------------------------------------
;	sasi_receive_senseのループ
;		データインフェーズを待つ。要調整
;	変更前
;		00009C3E 283C0003D090     		move.l	#250000,d4
;----------------------------------------------------------------
	PATCH_DATA	p9C3E,$00FF9C3E+SASI_OFFSET,$00FF9C3E+5+SASI_OFFSET,$283C0003
	jsr	p9c3e
	PATCH_TEXT
p9c3e:
	move.w	BIOS_MPU_SPEED_ROM.w,d4
	mulu.w	#300,d4			;(10*1000/12)*300=250000
	rts

;----------------------------------------------------------------
;	sasi_send_commandのループ
;		コマンドフェーズを待つ。要調整
;	変更前
;		00009CC6 243C0003D090     		move.l	#250000,d2
;----------------------------------------------------------------
	PATCH_DATA	p9CC6,$00FF9CC6+SASI_OFFSET,$00FF9CC6+5+SASI_OFFSET,$243C0003
	jsr	p9cc6
	PATCH_TEXT
p9cc6:
	move.w	BIOS_MPU_SPEED_ROM.w,d2
	mulu.w	#300,d2			;(10*1000/12)*300=250000
	rts

;----------------------------------------------------------------
;	sasi_command_startのループ
;		コマンドフェーズを待つ。最初の5バイトと最後の1バイト。要調整
;	変更前
;		00009D14 243C0003D090     		move.l	#250000,d2
;----------------------------------------------------------------
	PATCH_DATA	p9D14,$00FF9D14+SASI_OFFSET,$00FF9D14+5+SASI_OFFSET,$243C0003
	jsr	p9d14
	PATCH_TEXT
p9d14:
	move.w	BIOS_MPU_SPEED_ROM.w,d2
	mulu.w	#300,d2			;(10*1000/12)*300=250000
	rts
;----------------------------------------------------------------
;	変更前
;		00009D40 243C0003D090     	move.l	#250000,d2
;----------------------------------------------------------------
	PATCH_DATA	p9D40,$00FF9D40+SASI_OFFSET,$00FF9D40+5+SASI_OFFSET,$243C0003
	jsr	p9d40
	PATCH_TEXT
p9d40:
	move.w	BIOS_MPU_SPEED_ROM.w,d2
	mulu.w	#300,d2			;(10*1000/12)*300=250000
;DMA転送前のキャッシュフラッシュ
;	コマンドの最後の1バイトを送信する直前にキャッシュをフラッシュしておく
;	$00FF9E02の転送開始の直前で時間をかけるとDMACが最初の外部転送要求を見逃す可能性がある
	bra	cache_flush

;----------------------------------------------------------------
;	sasi_mpuout_10byteのループ
;		データアウトフェーズを待つ。要調整
;	変更前
;		00009DA0 283C0003D090     		move.l	#250000,d4
;----------------------------------------------------------------
	PATCH_DATA	p9DA0,$00FF9DA0+SASI_OFFSET,$00FF9DA0+5+SASI_OFFSET,$283C0003
	jsr	p9da0
	PATCH_TEXT
p9da0:
	move.w	BIOS_MPU_SPEED_ROM.w,d4
	mulu.w	#300,d4			;(10*1000/12)*300=250000
	rts

;----------------------------------------------------------------
;	sasi_do_recalibrateのsasi_wait_statusの引数
;		ステータスフェーズを待つ。要調整
;	変更前
;		00009D82 2A3C004C4B40     			move.l	#5000000,d5
;----------------------------------------------------------------
	PATCH_DATA	p9D82,$00FF9D82+SASI_OFFSET,$00FF9D82+5+SASI_OFFSET,$2A3C004C
	jsr	p9d82
	PATCH_TEXT
p9d82:
	move.w	BIOS_MPU_SPEED_ROM.w,d5
	mulu.w	#6000,d5		;(10*1000/12)*6000=5000000
	rts



;----------------------------------------------------------------
;	IOCS$4xのHDの処理
;		SCSI内蔵機のとき何もせずエラーを返す
;			SCSI内蔵機のときIOCS$4xのHDの処理はここに来る前に終わっている
;		SASI内蔵機のときSASI IOCSにジャンプする
;	変更前
;		00008704 670009B2_000090B8        beq     scsi_40_B_SEEK          ;IOCSコール$40 _B_SEEK(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8704,$00FF8704,$00FF8704+3,$670009B2
;	beq.w	(*)-$8704+$95B6+SASI_OFFSET	;sasi_40_B_SEEK
	PATCH_beq.w	pD580,pD580_40
;----------------------------------------------------------------
;	変更前
;		0000874A 67000A9C_000091E8        beq     scsi_41_B_VERIFY        ;IOCSコール$41 _B_VERIFY(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p874A,$00FF874A,$00FF874A+3,$67000A9C
;	beq.w	(*)-$874A+$95DA+SASI_OFFSET	;sasi_41_B_VERIFY
	PATCH_beq.w	pD580,pD580_41
;----------------------------------------------------------------
;	変更前
;		0000884C 67000A02_00009250        beq     scsi_43_B_DSKINI        ;IOCSコール$43 _B_DSKINI(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p884C,$00FF884C,$00FF884C+3,$67000A02
;	beq.w	(*)-$884C+$9640+SASI_OFFSET	;sasi_43_B_DSKINI
	PATCH_beq.w	pD580,pD580_43
;----------------------------------------------------------------
;	変更前
;		00008890 67000844_000090D6        beq     scsi_44_B_DRVSNS        ;IOCSコール$44 _B_DRVSNS(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8890,$00FF8890,$00FF8890+3,$67000844
;	beq.w	(*)-$8890+$9720+SASI_OFFSET	;sasi_44_B_DRVSNS
	PATCH_beq.w	pD580,pD580_44
;----------------------------------------------------------------
;	変更前
;		000088D0 670008B0_00009182        beq     scsi_45_B_WRITE         ;IOCSコール$45 _B_WRITE(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p88D0,$00FF88D0,$00FF88D0+3,$670008B0
;	beq.w	(*)-$88D0+$9744+SASI_OFFSET	;sasi_45_B_WRITE
	PATCH_beq.w	pD580,pD580_45
;----------------------------------------------------------------
;	変更前
;		00008950 6700082A_0000917C        beq     scsi_46_B_READ          ;IOCSコール$46 _B_READ(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8950,$00FF8950,$00FF8950+3,$6700082A
;	beq.w	(*)-$8950+$97E8+SASI_OFFSET	;sasi_46_B_READ
	PATCH_beq.w	pD580,pD580_46
;----------------------------------------------------------------
;	変更前
;		000089C6 670006F6_000090BE        beq     scsi_47_B_RECALI        ;IOCSコール$47 _B_RECALI(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p89C6,$00FF89C6,$00FF89C6+3,$670006F6
;	beq.w	(*)-$89C6+$988C+SASI_OFFSET	;sasi_47_B_RECALI
	PATCH_beq.w	pD580,pD580_47
;----------------------------------------------------------------
;	変更前
;		00008A96 6700062C_000090C4        beq     scsi_48_B_ASSIGN        ;IOCSコール$48 _B_ASSIGN(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8A96,$00FF8A96,$00FF8A96+3,$6700062C
;	beq.w	(*)-$8A96+$989E+SASI_OFFSET	;sasi_48_B_ASSIGN
	PATCH_beq.w	pD580,pD580_48
;----------------------------------------------------------------
;	変更前
;		00008B2E 6700059A_000090CA        beq     scsi_4B_B_BADFMT        ;IOCSコール$4B _B_BADFMT(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8B2E,$00FF8B2E,$00FF8B2E+3,$6700059A
;	beq.w	(*)-$8B2E+$98CE+SASI_OFFSET	;sasi_4B_B_BADFMT
	PATCH_beq.w	pD580,pD580_4B
;----------------------------------------------------------------
;	変更前
;		00008B80 6700054E_000090D0        beq     scsi_4D_B_FORMAT        ;IOCSコール$4D _B_FORMAT(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8B80,$00FF8B80,$00FF8B80+3,$6700054E
;	beq.w	(*)-$8B80+$98F6+SASI_OFFSET	;sasi_4D_B_FORMAT
	PATCH_beq.w	pD580,pD580_4D
;----------------------------------------------------------------
;	変更前
;		00008D4C 670003C6_00009114        beq     scsi_4F_B_EJECT         ;IOCSコール$4F _B_EJECT(SCSI)
;----------------------------------------------------------------
	PATCH_DATA	p8D4C,$00FF8D4C,$00FF8D4C+3,$670003C6
;	beq.w	(*)-$8D4C+$99D0+SASI_OFFSET	;sasi_4F_B_EJECT
	PATCH_beq.w	pD580,pD580_4F
;----------------------------------------------------------------
;	変更前
;		0000D580 102E0009         		move.b	SPC_INTS(aSPC),d0
;----------------------------------------------------------------
;	PATCH_DATA	pD580,$00FFD580,$00FFDCE3,$102E0009
	PATCH_DATA	pD580,$00FFD580,$00FFD67F,$102E0009
pD580_40:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF95B6+SASI_OFFSET)PATCH_ZL	;sasi_40_B_SEEK
pD580_41:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF95DA+SASI_OFFSET)PATCH_ZL	;sasi_41_B_VERIFY
pD580_43:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF9640+SASI_OFFSET)PATCH_ZL	;sasi_43_B_DSKINI
pD580_44:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF9720+SASI_OFFSET)PATCH_ZL	;sasi_44_B_DRVSNS
pD580_45:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF9744+SASI_OFFSET)PATCH_ZL	;sasi_45_B_WRITE
pD580_46:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF97E8+SASI_OFFSET)PATCH_ZL	;sasi_46_B_READ
pD580_47:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF988C+SASI_OFFSET)PATCH_ZL	;sasi_47_B_RECALI
pD580_48:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF989E+SASI_OFFSET)PATCH_ZL	;sasi_48_B_ASSIGN
pD580_4B:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF98CE+SASI_OFFSET)PATCH_ZL	;sasi_4B_B_BADFMT
pD580_4D:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF98F6+SASI_OFFSET)PATCH_ZL	;sasi_4D_B_FORMAT
pD580_4F:
	goto	<tst.b BIOS_BUILTIN_SCSI.w>,ne,pD580_error
	goto	($00FF99D0+SASI_OFFSET)PATCH_ZL	;sasi_4F_B_EJECT
pD580_error:
	moveq.l	#-1,d0
	rts



;----------------------------------------------------------------
;
;	パッチデータの末尾
;
;----------------------------------------------------------------

	PATCH_END



	.end

;========================================================================================
;  sprdrv.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;タイトル
;	拡張スプライト・バックグラウンドドライバ
;名前
;	sprdrv.x
;バージョン
;	(2025-04-10)
;機能
;	スプライト・バックグラウンド関連のIOCSコールでXEiJの拡張機能を使用できるようにします。
;	_SP_INITで拡張機能を有効にしたプロセスが終了するとき拡張機能を無効にします。
;XEiJの設定
;	4096個のパターンをONにしてリセットしてください。
;	スプライトの枚数は128/256/504/1016のいずれか、768x512でスプライトを表示、512x512でBG1を表示に対応します。
;	ラスタあたりのスプライトの枚数は1016にしておくとよいでしょう。
;使用法
;	device=sprdrv.x <オプション>
;	  または
;	A>sprdrv.x <オプション>
;オプション
;	-c	常駐確認
;		常駐確認を行い、結果をメッセージと終了コードで返します。
;	-d	後始末なし
;		現在のプロセスの終了シーケンスに後始末の処理を追加しません。
;		初期化のプロセスが分かれている場合に指定します。
;		終了シーケンスの変更が他のプログラムやOSのパッチと衝突する場合にも指定します。
;	-e	後始末あり(デフォルト)
;		拡張機能を使用するとき、現在のプロセスの終了シーケンスに後始末の処理を追加します。
;	-q	静粛
;		オプションが違うとき以外、メッセージを表示しません。
;	-r	常駐解除
;		常駐部分がデバイスドライバのとき、ベクタを復元してデバイスドライバを切り離します。
;		常駐部分がメモリブロックのとき、ベクタを復元してメモリブロックを開放します。
;		常駐後にベクタが変更されて常駐部分を指していないときは解除できません。
;	-v	バージョン確認
;		タイトルとバージョンを表示して正常終了します。
;終了コード
;	0	解除しました
;	1	オプションが違います
;	2	常駐しています
;	3	常駐していません
;	4	ベクタが変更されています。解除できません
;	65536	常駐しました
;更新履歴
;	2025-04-07
;		初版。
;	2025-04-10
;		_SP_REGST/_SP_REGGTのスプライトの番号を連番に変更しました。
;		_BGTEXTSTを修正しました。
;----------------------------------------------------------------
;バンク制御
;	  15   14   13   12   11   10    9    8    7    6    5    4    3    2    1    0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|                                                                | モード  |移動|
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	移動
;		移動	テキストエリアの移動
;		0	しない
;		1	する
;	モード
;		モード	パターン数	スプライト反転	テキスト反転
;		0	256		可		可
;		1	1024		可		可
;		2	4096		不可		不可
;		3	4096		可		不可
;		反転不可を補うため、_SP_DEFCGにパターンを反転する機能が追加されています。
;キャラクタ
;	  15   14   13   12   11   10    9    8    7    6    5    4    3    2    1    0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|上下|左右|         | パレットブロック  |             パターン番号              |  モード0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|上下|左右|番号上位 | パレットブロック  |           パターン番号下位            |  モード1
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	| パターン番号上位  | パレットブロック  |           パターン番号下位            |  モード2,3
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;プライオリティ
;	  15   14   13   12   11   10    9    8    7    6    5    4    3    2    1    0
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|                                                                |豆腐|優先順位 |  モード0,1,2
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	|上下|左右|                                                      |豆腐|優先順位 |  モード3
;	+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;	優先順位
;	0	表示しない
;	1	バックグラウンド0＞バックグラウンド1＞スプライト
;	2	バックグラウンド0＞スプライト＞バックグラウンド1
;	3	スプライト＞バックグラウンド0＞バックグラウンド1
;----------------------------------------------------------------
;IOCS $C0 _SP_INIT
;	機能	スプライト・バックグラウンドを初期化します。
;		_SP_INITで拡張機能を有効にしたプロセスが終了するとき拡張機能を無効にします。
;	入力	レジスタ	値
;		d1.l		'SPRD'$53505244	拡張機能を使用する
;		d2.l		0～7		バンク制御
;	出力	レジスタ	値
;		d0.l		-3		拡張機能を使用できない
;				-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C1 _SP_ON
;	機能	スプライト画面を表示します。
;	入力	なし
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C2 _SP_OFF
;	機能	スプライト画面を表示しません。
;	入力	なし
;	出力	レジスタ	値
;		d0.l		0		正常終了
;----------------------------------------------------------------
;IOCS $C3 _SP_CGCLR
;	機能	パターンをゼロクリアします。
;	入力	レジスタ	値
;		d1.w		0～4095		パターン番号
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C4 _SP_DEFCG
;	機能	パターンを設定します。
;		パターンを反転する機能が追加されています。
;	入力	レジスタ	値
;		d1.w		0～4095		パターン番号
;		d2.w[15]	0～1		上下反転
;		d2.w[14]	0～1		左右反転
;		d2.b		0～1		サイズ。0=8x8,1=16x16
;		a1.l		偶数		バッファのアドレス
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C5 _SP_GTPCG
;	機能	パターンを取得します。
;	入力	レジスタ	値
;		d1.w		0～4095		パターン番号
;		d2.b		0～1		サイズ。0=8x8,1=16x16
;		a1.l		偶数		バッファのアドレス
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C6 _SP_REGST
;	機能	スプライトスクロールレジスタを設定します。
;		豆腐ビットをクリアします。
;	入力	レジスタ	値
;		d1.l[31]	1		VDISPの立ち下がりを待たない
;		d1.w		0～1015		スプライト番号(連番)
;		d2.l[31]	1		X座標を設定しない
;		d2.w		0～1023		X座標
;		d3.l[31]	1		Y座標を設定しない
;		d3.w		0～1023		Y座標
;		d4.l[31]	1		キャラクタを設定しない
;		d4.w		0～65535	キャラクタ
;		d5.l[31]	1		プライオリティを設定しない
;		d5.w		0～65535	プライオリティ
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C7 _SP_REGGT
;	機能	スプライトスクロールレジスタを取得します。
;	入力	レジスタ	値
;		d1.w		0～1015		スプライト番号(連番)
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;		d2.l		0～1023		X座標
;		d3.l		0～1023		Y座標
;		d4.l		0～65535	キャラクタ
;		d5.l		0～65535	プライオリティ
;----------------------------------------------------------------
;IOCS $C8 _BGSCRLST
;	機能	バックグラウンドスクロールレジスタを設定します。
;	入力	レジスタ	値
;		d1.l[31]	1		VDISPの立ち下がりを待たない
;		d1.b		0～1		バックグラウンド番号
;		d2.l[31]	1		X座標を設定しない
;		d2.w		0～1023		X座標
;		d3.l[31]	1		Y座標を設定しない
;		d3.w		0～1023		Y座標
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $C9 _BGSCRLGT
;	機能	バックグラウンドスクロールレジスタを取得します。
;	入力	レジスタ	値
;		d1.b		0～1		バックグラウンド番号
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;		d2.l		0～1023		X座標
;		d3.l		0～1023		Y座標
;----------------------------------------------------------------
;IOCS $CA _BGCTRLST
;	機能	バックグラウンド制御レジスタを設定します。
;	入力	レジスタ	値
;		d1.b		0～1		バックグラウンド番号
;		d2.l[31]	1		テキストエリア番号を設定しない
;		d2.b		0～1		テキストエリア番号
;		d3.l[31]	1		表示の有無を設定しない
;		d3.b		0～1		表示の有無
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $CB _BGCTRLGT
;	機能	バックグラウンド制御レジスタを取得します
;	入力	レジスタ	値
;		d1.b		0～1		バックグラウンド番号
;	出力	レジスタ	値
;		d0.l		-1		スプライト画面を使用できない
;				0～7		テキストエリア番号<<1|表示の有無
;----------------------------------------------------------------
;IOCS $CC _BGTEXTCL
;	機能	バックグラウンドテキストをキャラクタで埋め尽くします。
;		疑似グラフィック画面を作る機能が追加されています。
;	入力	レジスタ	値
;		d1.w[15～8]	$00		キャラクタで埋め尽くす
;				$10		疑似グラフィック画面を作る
;		d1.b		0～1		テキストエリア番号
;		d2.w		0～65535	キャラクタ／パレットブロック
;	出力	レジスタ	値
;		d0.l		-3		拡張機能を使用できない
;				-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $CD _BGTEXTST
;	機能	バックグラウンドテキストにキャラクタを書き込みます。
;		疑似グラフィック画面に書き込む機能が追加されています。
;	入力	レジスタ	値
;		d1.w[15～8]	$00		キャラクタを書き込む
;				$10		疑似グラフィック画面に1ドット書き込む
;		d1.b		0～1		テキストエリア番号
;		d2.w		0～1023		X座標
;		d3.w		0～1023		Y座標
;		d4.w		0～65535	キャラクタ／パレットコード
;	出力	レジスタ	値
;		d0		-3		拡張機能を使用できない
;				-1		スプライト画面を使用できない
;				0		正常終了
;----------------------------------------------------------------
;IOCS $CE _BGTEXTGT
;	機能	バックグラウンドテキストからキャラクタを読み出します。
;		疑似グラフィック画面から読み出す機能が追加されています。
;	入力	レジスタ	値
;		d1.w[15～8]	$00		キャラクタを読み出す
;				$10		疑似グラフィック画面から1ドット読み出す
;		d1.b		0～1		テキストエリア番号
;		d2.w		0～1023		X座標
;		d3.w		0～1023		Y座標
;	出力	レジスタ	値
;		d0.l		-3		拡張機能を使用できない
;				-1		スプライト画面を使用できない
;				0～65535	キャラクタ／パレットコード
;----------------------------------------------------------------
;IOCS $CF _SPALET
;	機能	スプライトパレットを設定または取得します。
;		パレットブロック0は指定できません。
;	入力	レジスタ	値
;		d1.l[31]	1		VDISPの立ち下がりを待たない
;		d1.b		0～255		パレットブロック<<4|パレットコード
;		d2.b		0～15		パレットブロック(優先)
;		d3.l[31]	0		設定
;				1		取得
;		d3.w		0～65535	カラーコード
;	出力	レジスタ	値
;		d0.l		-2		パレットブロック0が指定された
;				0～65535	設定前のカラーコード
;----------------------------------------------------------------

	.include	bioswork.equ
	.include	control2.mac
	.include	crtc.equ
	.include	doscall.mac
	.include	dosconst.equ
	.include	doswork.equ
	.include	iocscall.mac
	.include	mfp.equ
	.include	misc.mac
	.include	push2.mac
	.include	sprc.equ
	.include	vector.equ
	.include	vicon.equ

DEVICE_NAME	reg	'/*SPRD*/'
JAPANESE_TITLE	reg	'拡張スプライト・バックグラウンドドライバ'
ENGLISH_TITLE	reg	'Extended sprite and background driver'
VERSION_STRING	reg	'(2025-04-10)'
PROGRAM_NAME	reg	'sprdrv.x'
PROGRAMEN_NAME	reg	'sprdrven.x'

  .ifndef ENGLISH
ENGLISH		equ	0
  .endif

;----------------------------------------------------------------
;プログラムの先頭
	.text
program_head:

;デバイスヘッダ
	.dc.l	-1			;次のデバイスヘッダ。-1=デバイスヘッダのリストの末尾
	.dc.w	$8000			;デバイスタイプ。キャラクタデバイス
	.dc.l	strategy_routine	;ストラテジルーチン
	.dc.l	interrupt_routine	;インタラプトルーチン
	.dc.b	DEVICE_NAME		;デバイス名

;ベクタテーブル
vector_table:
	.dc.w	4*($100+_SP_INIT)	;オフセット
	.dc.l	iocs_C0_SP_INIT		;新しいベクタ
	.dc.l	0			;古いベクタ
	.dc.w	4*($100+_SP_ON)
	.dc.l	iocs_C1_SP_ON
	.dc.l	0
	.dc.w	4*($100+_SP_OFF)
	.dc.l	iocs_C2_SP_OFF
	.dc.l	0
	.dc.w	4*($100+_SP_CGCLR)
	.dc.l	iocs_C3_SP_CGCLR
	.dc.l	0
	.dc.w	4*($100+_SP_DEFCG)
	.dc.l	iocs_C4_SP_DEFCG
	.dc.l	0
	.dc.w	4*($100+_SP_GTPCG)
	.dc.l	iocs_C5_SP_GTPCG
	.dc.l	0
	.dc.w	4*($100+_SP_REGST)
	.dc.l	iocs_C6_SP_REGST
	.dc.l	0
	.dc.w	4*($100+_SP_REGGT)
	.dc.l	iocs_C7_SP_REGGT
	.dc.l	0
	.dc.w	4*($100+_BGSCRLST)
	.dc.l	iocs_C8_BGSCRLST
	.dc.l	0
	.dc.w	4*($100+_BGSCRLGT)
	.dc.l	iocs_C9_BGSCRLGT
	.dc.l	0
	.dc.w	4*($100+_BGCTRLST)
	.dc.l	iocs_CA_BGCTRLST
	.dc.l	0
	.dc.w	4*($100+_BGCTRLGT)
	.dc.l	iocs_CB_BGCTRLGT
	.dc.l	0
	.dc.w	4*($100+_BGTEXTCL)
	.dc.l	iocs_CC_BGTEXTCL
	.dc.l	0
	.dc.w	4*($100+_BGTEXTST)
	.dc.l	iocs_CD_BGTEXTST
	.dc.l	0
	.dc.w	4*($100+_BGTEXTGT)
	.dc.l	iocs_CE_BGTEXTGT
	.dc.l	0
	.dc.w	4*($100+_SPALET)
	.dc.l	iocs_CF_SPALET
	.dc.l	0
	.dc.w	0

;フラグ
cleanup_flag:
	.dc.b	-1			;-1=後始末あり,0=後始末なし
	.even

;リクエストヘッダのアドレス
request_header:
	.dc.l	0

;ストラテジルーチン
strategy_routine:
	move.l	a5,request_header
	rts

;インタラプトルーチン
interrupt_routine:
	push	d0-d7/a0-a6
	movea.l	request_header(pc),a5
	moveq.l	#0,d0
	move.b	2(a5),d0		;コマンド番号
	if	<cmp.w #(jump_table_end-jump_table)/2,d0>,hs	;範囲外
		moveq.l	#(jump_table_end-jump_table)/2,d0
	endif
	add.w	d0,d0
	move.w	jump_table(pc,d0.w),d0
	jsr	jump_table(pc,d0.w)
	move.b	d0,3(a5)		;エラーコード下位
	lsr.w	#8,d0
	move.b	d0,4(a5)		;エラーコード上位
	pop
	rts

;デバイスコマンドのジャンプテーブル
jump_table:
	.dc.w	initialize-jump_table		;デバイスコマンド0 初期化
	.dc.w	command_error-jump_table	;デバイスコマンド1 ディスク交換チェック
	.dc.w	command_error-jump_table	;デバイスコマンド2 BPBテーブルの再構築
	.dc.w	ioctrl_input-jump_table		;デバイスコマンド3 _IOCTRLによる入力
	.dc.w	input-jump_table		;デバイスコマンド4 入力
	.dc.w	control_sense-jump_table	;デバイスコマンド5 コントロール/センス
	.dc.w	input_status-jump_table		;デバイスコマンド6 入力ステータス
	.dc.w	input_flush-jump_table		;デバイスコマンド7 入力バッファフラッシュ
	.dc.w	output-jump_table		;デバイスコマンド8 出力(ベリファイなし)
	.dc.w	output-jump_table		;デバイスコマンド9 出力(ベリファイあり)
	.dc.w	output_status-jump_table	;デバイスコマンド10 出力ステータス
	.dc.w	no_error-jump_table		;デバイスコマンド11 正常終了
	.dc.w	ioctrl_output-jump_table	;デバイスコマンド12 _IOCTRLによる出力
jump_table_end:
	.dc.w	command_error-jump_table	;範囲外 コマンドエラー

;デバイスコマンド1 ディスク交換チェック
;デバイスコマンド2 BPBテーブルの再構築
;コマンドエラー
command_error:
	move.w	#IGNORE|ABORT|UNKNOWN_COMMAND,d0	;無視(I) 中止(A) デバイスドライバに無効なコマンドを指定しました
	rts

;デバイスコマンド3 _IOCTRLによる入力
ioctrl_input:
;	movea.l	14(a5),a1		;アドレス
	goto	command_error

;デバイスコマンド4 入力
input:
	movea.l	14(a5),a1		;アドレス
	move.l	18(a5),d3		;長さ
	docontinue
		clr.b	(a1)+
	while	<subq.l #1,d3>,cc
	moveq.l	#0,d0			;常に成功する(終わるまで復帰しない)
	rts

;デバイスコマンド5 コントロール/センス
control_sense:
	clr.b	13(a5)			;データ
	moveq.l	#0,d0			;常に成功する
	rts

;デバイスコマンド6 入力ステータス
input_status:
	moveq.l	#1,d0			;0=入力バッファが空ではないので入力できる,1=入力バッファが空なので入力できない
	rts

;デバイスコマンド7 入力バッファフラッシュ
input_flush:
	moveq.l	#0,d0			;常に成功する
	rts

;デバイスコマンド8 出力(ベリファイなし)
;デバイスコマンド9 出力(ベリファイあり)
output:
;	movea.l	14(a5),a1		;アドレス
;	move.l	18(a5),d3		;長さ
	moveq.l	#0,d0			;常に成功する(終わるまで復帰しない)
	rts

;デバイスコマンド10 出力ステータス
output_status:
	moveq.l	#1,d0			;0=出力バッファが満杯ではないので出力できる,1=出力バッファが満杯なので出力できない
	rts

;デバイスコマンド11 正常終了
no_error:
	moveq.l	#0,d0			;常に成功する
	rts

;デバイスコマンド12 _IOCTRLによる出力
ioctrl_output:
;	movea.l	14(a5),a1		;アドレス
	goto	command_error



;----------------------------------------------------------------
;ワークエリア
original_exitvc:
	.dc.l	0			;変更前の_EXITVC。0=変更していない
original_sr:
	.dc.w	0			;変更前のsr
text_area:
	.dc.l	SPRC_TEXT_0		;現在のテキストエリア0
sprite_max:
	.dc.w	127			;スプライト番号の最大値。127,255,511,1023
bank_available:
	.dc.b	0			;-1=バンクあり,0=バンクなし
extended_1xx1x:
	.dc.b	1			;%1xx1xのときスプライト画面を使用できるか。-1=使える,0=使えない,1=未確認
	.even

;----------------------------------------------------------------
;_EXITVCルーチン
;	_EXITVCを用いて親プロセスの_EXECの直後に処理を追加する
;	そのままだと親プロセスがユーザモードのときスーパーバイザ領域にある(デバイスドライバの中にある)コードを実行できない
;	親プロセスのsrを変更してスーパーパイザモードで追加の処理を実行してから変更前のsrを復元する
exitvc_routine:
;後始末する
	push	d0-d1/a0
	move.b	cleanup_flag(pc),d0
	if	ne			;後始末あり
		moveq.l	#0,d1
		bsr	iocs_C0_SP_INIT
	endif
	pop
;変更前のsrを復元して、変更前の_EXITVC(他に_EXITVCに追加された処理がなければ親プロセスの_EXECの直後)へジャンプする
	if	<tst.b BIOS_MPU_TYPE.w>,ne
		clr.w	-(sp)
	endif
	move.l	original_exitvc(pc),-(sp)	;変更前の_EXITVC
	clr.l	original_exitvc
	move.w	original_sr(pc),-(sp)	;変更前のsr
	clr.w	original_sr
	rte

;----------------------------------------------------------------
;スプライト画面を使用できるか確認する
;	IOCSコールの先頭で呼び出す
;	スプライト画面を使用できるとき何もしない
;	スプライト画面を使用できないときd0.l=-1でIOCSコールを終了する
;?d0/a0
check_sprite:
	moveq.l	#.not.%10010,d0
	or.b	CRTC_RESOLUTION_BYTE,d0	;R20L。%1xx1xのときだけ%11111111
	not.b	d0			;%1xx1xのときだけ%00000000
	do
		break	ne			;%1xx1xではない。使用できる
		move.b	extended_1xx1x(pc),d0	;%1xx1xのときスプライト画面を使用できるか
		break	mi			;-1=使用できる
		if	ne			;1=未確認
		;%1xx1xのときスプライト画面を使用できるか確認する
			moveq.l	#-1,d0
			move.l	OFFSET_BUS_ERROR.w,-(sp)
			movea.l	sp,a0
			move.l	#@f,OFFSET_BUS_ERROR.w
			nop
			move.w	SPRC_SCROLL,d0		;スプライトスクロールレジスタをリードしてみる
			nop
		@@:	movea.l	a0,sp
			move.l	(sp)+,OFFSET_BUS_ERROR.w
			tst.w	d0			;バスエラーが発生したかX座標が負のときmi、さもなくばpl
			spl.b	extended_1xx1x		;-1=使用できる,0=使用できない
			break	pl			;使用できる
		endif
		moveq.l	#-1,d0			;スプライト画面を使用できない
		addq.l	#4,sp			;IOCSコールを終了する
	while	f
	rts

;----------------------------------------------------------------
;VDISPの立ち下がりを待つ
vdisp_falling_edge:
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,eq
	do
	while	<btst.b #MFP_G_VDISP_BIT,MFP_GPDR>,ne
	rts

;----------------------------------------------------------------
;IOCS $C0 _SP_INIT
;	スプライト・バックグラウンドを初期化します。
;	_SP_INITで拡張機能を有効にしたプロセスが終了するとき拡張機能を無効にします。
;<d1.l:'SPRD'$53505244=拡張機能を使用する
;<d2.l:バンク制御
;>d0.l:-3=拡張機能を使用できない,-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C0_SP_INIT:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	push	d1-d7/a1-a4/a6
	lea.l	$00EB8000,a6
EB	reg	-$00EB8000(a6)
;拡張機能を使用する／使用しない
	moveq.l	#-1,d6
	if	<cmp.l #'SPRD',d1>,eq	;拡張機能を使用する
		moveq.l	#7,d6
		and.w	d2,d6			;バンク制御
	endif
;<d6.l:-1=拡張機能を使用しない,0～7=バンク制御
;スプライトの番号の最大値を求める
	lea.l	(SPRC_SCROLL)EB,a0	;スプライトスクロールレジスタのX座標
	move.w	#1024-1,d7
	do
		move.w	d7,d0			;番号
		lsl.w	#3,d0			;8*番号
		break	<tst.w (a0,d0.w)>,pl	;あれば終了
		lsr.w	#1,d7			;なければ半分にする
	while	<tst.b d7>,mi		;128-1で終了
;<d7.w:スプライトの番号の最大値
;d1-d4/a1-a4をゼロにする
	moveq.l	#0,d1
  .irp rn,d2,d3,d4,a1,a2,a3,a4
	move.l	d1,rn
  .endm
;スプライトコントロールレジスタをゼロクリアする
	move.w	d1,(SPRC_CONTROL)EB
;バックグラウンドスクロールレジスタをゼロクリアする
	movem.l	d1-d2,(SPRC_BG_0_X)EB
;スプライトスクロールレジスタをゼロクリアする
	lea.l	(SPRC_SCROLL)EB,a0
	move.w	d7,d0			;スプライトの番号の最大値。127,255,511,1023
	lsr.w	#5-3,d0			;8*欠番を含む枚数/32-1。31,63,127,255
	moveq.l	#8*256/32-1,d5
	if	<cmp.w d5,d0>,hi	;256枚より多いとき
		for	d5
			movem.l	d1-d4/a1-a4,(a0)	;256枚クリアして
			lea.l	32(a0),a0
		next
		lea.l	8*8(a0),a0		;8枚飛ばす
		sub.w	#8*(256+8)/32,d0
	endif
	for	d0
		movem.l	d1-d4/a1-a4,(a0)
		lea.l	32(a0),a0
	next
;パターンとテキストエリアをゼロクリアする
	move.w	(SPRC_BANK_NUMBER)EB,d0
	if	mi			;バンクなし
	;パターンとテキストエリアをゼロクリアする
		lea.l	(SPRC_PATTERN)EB,a0
		move.w	#128*256/32-1,d0
		for	d0
			movem.l	d1-d4/a1-a4,(a0)
			lea.l	32(a0),a0
		next
	else				;バンクあり
		lsr.w	#1,d0
		if	cs			;テキストエリア移動あり
		;テキストエリアをゼロクリアする
			lea.l	(SPRC_BANK_TEXT_0)EB,a0
			move.w	#2*64*64*2/32-1,d0
			for	d0
				movem.l	d1-d4/a1-a4,(a0)
				lea.l	32(a0),a0
			next
		endif
	;パターンをゼロクリアする
		moveq.l	#15,d5			;バンク番号。15～0。バンク0が選択された状態で終了する
		for	d5
			move.b	d5,(SPRC_BANK_NUMBER)EB	;バンク番号
			lea.l	(SPRC_PATTERN)EB,a0
			move.w	#128*256/32-1,d0
			for	d0
				movem.l	d1-d4/a1-a4,(a0)
				lea.l	32(a0),a0
			next
		next
	endif
;スプライトパレットを初期化する
	lea.l	VICON_TSPALET+2*16,a0	;パレットブロック1～15
	movem.l	100f(pc),d1-d4/a1-a4	;カラーコードの初期値
	bsr	vdisp_falling_edge	;VDISPの立ち下がりを待つ
	moveq.l	#15-1,d0
	for	d0
		movem.l	d1-d4/a1-a4,(a0)
		lea.l	32(a0),a0
	next
;拡張機能を使用する／使用しない
	if	<tst.l d6>,mi		;拡張機能を使用しない
		if	<tst.w (SPRC_BANK_NUMBER)EB>,pl	;バンク番号レジスタがある
			clr.l	(SPRC_BANK_CONTROL)EB	;バンク制御レジスタとバンク番号レジスタをゼロクリアする
		endif
		move.l	#SPRC_TEXT_0,text_area	;移動前のテキストエリア
		move.w	#127,sprite_max		;スプライトの番号の最大値
		sf.b	bank_available		;バンクなし
	elif	<tst.w (SPRC_BANK_NUMBER)EB>,mi	;バンク番号レジスタがない
		moveq.l	#-3,d0			;拡張機能を使用できない
	else				;拡張機能を使用する
	;後始末の準備
		move.b	cleanup_flag(pc),d0
		if	ne			;後始末あり
			movea.l	DOS_PROCESS_HANDLE.w,a0	;プロセスハンドル
			movea.l	(a0),a0			;実行中のプロセスのメモリ管理ポインタ
			lea.l	original_exitvc(pc),a1	;変更前の_EXITVCのハンドル
			lea.l	original_sr(pc),a2	;変更前のsrのハンドル
			lea.l	exitvc_routine(pc),a3	;変更後の_EXITVC
			lea.l	OFFSET_DOS+4*(_EXITVC&$FF).w,a4	;_EXITVCのハンドル
			if	<tst.l (a1)>,eq		;自分を登録していない
				move.l	(a4),(a1)		;_EXITVCを保存する
				move.l	a3,(a4)			;_EXITVCを変更する
				move.l	a3,MM_EXITVC(a0)	;実行中のプロセスの_EXITVCを変更する
				move.w	MM_SR(a0),(a2)		;実行中のプロセスの親プロセスのsrを保存する
				ori.w	#$2000,MM_SR(a0)	;実行中のプロセスの親プロセスのsrを変更する
			endif
		endif
	;拡張機能を有効にする
		move.w	d6,(SPRC_BANK_CONTROL)EB	;バンク制御
		lea.l	(SPRC_TEXT_0)EB,a0	;移動前のテキストエリア
		if	<btst.l #0,d6>,ne
			lea.l	(SPRC_BANK_TEXT_0)EB,a0	;移動後のテキストエリア
		endif
		move.l	a0,text_area
		move.w	d7,sprite_max		;スプライトの番号の最大値
		st.b	bank_available		;バンクあり
		moveq.l	#0,d0			;正常終了
	endif
	pop
	rts

;カラーコードの初期値
100:	dcrgb	0,0,0			;0=黒
	dcrgb	10,10,10		;1=暗い灰色
	dcrgb	0,0,16			;2=暗い青
	dcrgb	0,0,31			;3=青
	dcrgb	16,0,0			;4=暗い赤
	dcrgb	31,0,0			;5=赤
	dcrgb	16,0,16			;6=暗い紫
	dcrgb	31,0,31			;7=紫
	dcrgb	0,16,0			;8=暗い緑
	dcrgb	0,31,0			;9=緑
	dcrgb	0,16,16			;10=暗い水色
	dcrgb	0,31,31			;11=水色
	dcrgb	16,16,0			;12=暗い黄色
	dcrgb	31,31,0			;13=黄色
	dcrgb	21,21,21		;14=明るい灰色
	dcrgb	31,31,31		;15=白

;----------------------------------------------------------------
;IOCS $C1 _SP_ON
;	スプライト画面を表示します。
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C1_SP_ON:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	ori.w	#VICON_SPON_MASK,VICON_VISIBLE
	ori.w	#SPRC_SPRITE_ON,SPRC_CONTROL
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $C2 _SP_OFF
;	スプライト画面を表示しません。
;>d0.l:0=正常終了
iocs_C2_SP_OFF:
	andi.w	#.notw.VICON_SPON_MASK,VICON_VISIBLE
	andi.w	#.notw.SPRC_SPRITE_ON,SPRC_CONTROL
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $C3 _SP_CGCLR
;	パターンをゼロクリアします。
;<d1.w:パターン番号
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C3_SP_CGCLR:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	push	d1
	lea.l	SPRC_PATTERN,a0
	move.b	bank_available(pc),d0
	if	ne			;バンクあり
		move.w	d1,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;バンク番号
	endif
	and.w	#$00FF,d1		;バンク内パターン番号
	lsl.w	#7,d1
	adda.w	d1,a0
	moveq.l	#0,d0
	moveq.l	#128/4-1,d1
	for	d1
		move.l	d0,(a0)+
	next
;	moveq.l	#0,d0			;正常終了
	pop
	rts

;----------------------------------------------------------------
;IOCS $C4 _SP_DEFCG
;	パターンを設定します。
;	パターンを反転する機能が追加されています。
;<d1.w:パターン番号
;<d2.w[15]:上下反転
;<d2.w[14]:左右反転
;<d2.b:サイズ。0=8x8,1=16x16
;<a1.l:バッファのアドレス。偶数
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C4_SP_DEFCG:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	push	d1-d2/a1
	lea.l	SPRC_PATTERN,a0
	do
		if	<tst.b d2>,eq		;8x8
			move.b	bank_available(pc),d0
			if	ne			;バンクあり
				move.w	d1,d0
				lsr.w	#2,d0
				move.w	d0,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;バンク番号
			endif
			and.w	#$03FF,d1		;バンク内8x8パターン番号
			lsl.w	#5,d1
			adda.w	d1,a0
			add.w	d2,d2
			if	cc			;上下反転しない
				if	pl			;左右反転しない
					moveq.l	#8-1,d2
					for	d2
						move.l	(a1)+,(a0)+		;上→下
					next
					break
				else				;左右反転する
					moveq.l	#8-1,d2
					for	d2
						move.l	(a1)+,d0		;上→下
						bsr	hexrev
						move.l	d0,(a0)+		;上→下
					next
					break
				endif
			else				;上下反転する
				lea.l	32(a1),a1		;上→下
				if	pl			;左右反転しない
					moveq.l	#8-1,d2
					for	d2
						move.l	-(a1),(a0)+		;下→上／上→下
					next
					break
				else				;左右反転する
					moveq.l	#8-1,d2
					for	d2
						move.l	-(a1),d0		;下→上
						bsr	hexrev
						move.l	d0,(a0)+		;上→下
					next
					break
				endif
			endif
		else				;16x16
			move.b	bank_available(pc),d0
			if	ne			;バンクあり
				move.w	d1,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;バンク番号
			endif
			and.w	#$00FF,d1		;バンク内16x16パターン番号
			lsl.w	#7,d1
			adda.w	d1,a0
			add.w	d2,d2
			if	cc			;上下反転しない
				if	pl			;左右反転しない
					moveq.l	#32-1,d2
					for	d2
						move.l	(a1)+,(a0)+		;左上→左下=右上→右下
					next
					break
				else				;左右反転する
					lea.l	64(a1),a1		;左上→右上
					moveq.l	#16-1,d2
					for	d2
						move.l	(a1)+,d0		;右上→右下
						bsr	hexrev
						move.l	d0,(a0)+		;左上→左下=右上
					next
					lea.l	-128(a1),a1		;右下→左上
					moveq.l	#16-1,d2
					for	d2
						move.l	(a1)+,d0		;左上→左下
						bsr	hexrev
						move.l	d0,(a0)+		;左下=右上→右下
					next
					break
				endif
			else				;上下反転する
				if	pl			;左右反転しない
					lea.l	64(a1),a1		;左上→左下
					moveq.l	#16-1,d2
					for	d2
						move.l	-(a1),(a0)+		;左下→左上／左上→左下=右上
					next
					lea.l	128(a1),a1		;左上→右下
					moveq.l	#16-1,d2
					for	d2
						move.l	-(a1),(a0)+		;右下→右上／左下=右上→右下
					next
					break
				else				;左右反転する
					lea.l	128(a1),a1		;左上→右下
					moveq.l	#32-1,d2
					for	d2
						move.l	-(a1),d0		;右下→右上=左下→左上
						bsr	hexrev
						move.l	d0,(a0)+		;左上→左下=右上→右下
					next
				;	break
				endif
			endif
		endif
	while	f
	moveq.l	#0,d0			;正常終了
	pop
	rts

;左右反転
;<d0.l:パターン
;>d0.l:左右反転したパターン
;?d1
hexrev:
					;d0=ABCDEFGH
	move.l	d0,d1			;d1=ABCDEFGH
	and.l	#$00FF00FF,d1		;d1=00CD00GH
	eor.l	d1,d0			;d0=AB00EF00
	swap.w	d1			;d1=00GH00CD
	or.l	d1,d0			;d0=ABGHEFCD
	move.l	d0,d1			;d1=ABGHEFCD
	and.l	#$0F0F0F0F,d1		;d1=0B0H0F0D
	eor.l	d1,d0			;d0=A0G0E0C0
	rol.l	#8,d1			;d1=0H0F0D0B
	or.l	d1,d0			;d0=AHGFEDCB
	rol.l	#4,d0			;d0=HGFEDCBA
	rts

;----------------------------------------------------------------
;IOCS $C5 _SP_GTPCG
;	パターンを取得します。
;<d1.w:パターン番号
;<d2.b:サイズ。0=8x8,1=16x16
;<a1.l:バッファのアドレス。偶数
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C5_SP_GTPCG:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	push	d1-d2/a1
	lea.l	SPRC_PATTERN,a0
	if	<tst.b d2>,eq		;8x8
		move.b	bank_available(pc),d0
		if	ne			;バンクあり
			move.w	d1,d0
			lsr.w	#2,d0
			move.w	d0,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;バンク番号
		endif
		and.w	#$03FF,d1		;バンク内8x8パターン番号
		lsl.w	#5,d1
		moveq.l	#8-1,d2
	else				;16x16
		move.b	bank_available(pc),d0
		if	ne			;バンクあり
			move.w	d1,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;バンク番号
		endif
		and.w	#$00FF,d1		;バンク内16x16パターン番号
		lsl.w	#7,d1
		moveq.l	#32-1,d2
	endif
	adda.w	d1,a0
	for	d2
		move.l	(a0)+,(a1)+
	next
	moveq.l	#0,d0
	pop
	rts

;----------------------------------------------------------------
;IOCS $C6 _SP_REGST
;	スプライトスクロールレジスタを設定します。
;	豆腐ビットをクリアします。
;<d1.l[31]:1=VDISPの立ち下がりを待たない
;<d1.w:スプライト番号(連番)
;<d2.l[31]:1=X座標を設定しない
;<d2.w:X座標
;<d3.l[31]:1=Y座標を設定しない
;<d3.w:Y座標
;<d4.l[31]:1=キャラクタを設定しない
;<d4.w:キャラクタ
;<d5.l[31]:1=プライオリティを設定しない
;<d5.w:プライオリティ
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C6_SP_REGST:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	move.w	d1,d0
	and.w	sprite_max(pc),d0	;0～1015/1016～1023
	do
		if	<cmp.w #256,d0>,hs	;256～1015/1016～1023
			addq.w	#8,d0			;264～1023/1024～1031
			break	<cmp.w sprite_max(pc),d0>,hi	;1024～1031
		endif
		lea.l	SPRC_SCROLL,a0
		lsl.w	#3,d0
		adda.w	d0,a0
		if	<tst.l d1>,pl
			bsr	vdisp_falling_edge	;VDISPの立ち下がりを待つ
		endif
		if	<tst.l d2>,pl
			move.w	d2,(a0)			;X座標
		endif
		if	<tst.l d3>,pl
			move.w	d3,2(a0)		;Y座標
		endif
		if	<tst.l d4>,pl
			move.w	d4,4(a0)		;キャラクタ
		endif
		if	<tst.l d5>,pl
			moveq.l	#.not.4,d0		;豆腐ビットをクリアする
			and.w	d5,d0
			move.w	d0,6(a0)		;プライオリティ
		endif
	while	f
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $C7 _SP_REGGT
;	スプライトスクロールレジスタを取得します。
;<d1.w:スプライト番号(連番)
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;>d2.l:X座標
;>d3.l:Y座標
;>d4.l:キャラクタ
;>d5.l:プライオリティ
;?a0
iocs_C7_SP_REGGT:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#0,d5
	move.w	d1,d0
	and.w	sprite_max(pc),d0	;0～1015/1016～1023
	do
		if	<cmp.w #256,d0>,hs	;256～1015/1016～1023
			addq.w	#8,d0			;264～1023/1024～1031
			break	<cmp.w sprite_max(pc),d0>,hi	;1024～1031
		endif
		lea.l	SPRC_SCROLL,a0
		lsl.w	#3,d0
		adda.w	d0,a0
		move.w	(a0)+,d2		;X座標
		move.w	(a0)+,d3		;Y座標
		move.w	(a0)+,d4		;キャラクタ
		move.w	(a0)+,d5		;プライオリティ
	while	f
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $C8 _BGSCRLST
;	バックグラウンドスクロールレジスタを設定します。
;<d1.l[31]:1=VDISPの立ち下がりを待たない
;<d1.b:バックグラウンド番号
;<d2.l[31]:1=X座標を設定しない
;<d2.w:X座標
;<d3.l[31]:1=Y座標を設定しない
;<d3.w:Y座標
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_C8_BGSCRLST:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	lea.l	SPRC_BG_0_X,a0
	if	<tst.b d1>,ne
		addq.l	#SPRC_BG_1_X-SPRC_BG_0_X,a0
	endif
	if	<tst.l d1>,pl
		bsr	vdisp_falling_edge	;VDISPの立ち下がりを待つ
	endif
	if	<tst.l d2>,pl
		move.w	d2,(a0)			;X座標
	endif
	if	<tst.l d3>,pl
		move.w	d3,2(a0)		;Y座標
	endif
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $C9 _BGSCRLGT
;	バックグラウンドスクロールレジスタを取得します。
;<d1.b:バックグラウンド番号
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;>d2.l:X座標
;>d3.l:Y座標
;?a0
iocs_C9_BGSCRLGT:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	lea.l	SPRC_BG_0_X,a0
	if	<tst.b d1>,ne
		addq.l	#SPRC_BG_1_X-SPRC_BG_0_X,a0
	endif
	moveq.l	#0,d2
	moveq.l	#0,d3
	move.w	(a0)+,d2		;X座標
	move.w	(a0)+,d3		;Y座標
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $CA _BGCTRLST
;	バックグラウンド制御レジスタを設定します。
;<d1.b:バックグラウンド番号
;<d2.l[31]:1=テキストエリア番号を設定しない
;<d2.b:テキストエリア番号
;<d3.l[31]:1=表示の有無を設定しない
;<d3.b:表示の有無
;>d0.l:-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_CA_BGCTRLST:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	move.w	SPRC_CONTROL,d0
	if	<tst.b d1>,eq		;バックグラウンド0
		if	<tst.l d2>,pl		;テキストエリア番号を設定する
			and.w	#.notw.%000_110,d0
			if	<tst.b d2>,ne		;テキストエリア1
				addq.w	#%000_010,d0
			endif
		endif
		if	<tst.l d3>,pl		;表示の有無を設定する
			and.w	#.notw.%000_001,d0
			if	<tst.b d3>,ne		;表示あり
				addq.w	#%000_001,d0
			endif
		endif
	else				;バックグラウンド1
		if	<tst.l d2>,pl		;テキストエリア番号を設定する
			and.w	#.notw.%110_000,d0
			if	<tst.b d2>,ne		;テキストエリア1
				add.w	#%010_000,d0
			endif
		endif
		if	<tst.l d3>,pl		;表示の有無を設定する
			and.w	#.notw.%001_000,d0
			if	<tst.b d3>,ne		;表示あり
				addq.w	#%001_000,d0
			endif
		endif
	endif
	move.w	d0,SPRC_CONTROL
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $CB _BGCTRLGT
;	バックグラウンド制御レジスタを取得します
;<d1.b:バックグラウンド番号
;>d0.l:-1=スプライト画面を使用できない,0～7=テキストエリア番号<<1|表示の有無
;?a0
iocs_CB_BGCTRLGT:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	moveq.l	#0,d0
	move.w	SPRC_CONTROL,d0
	if	<tst.b d1>,ne
		lsr.w	#3,d0
	endif
	and.w	#%111,d0
	rts

;----------------------------------------------------------------
;IOCS $CC _BGTEXTCL
;	バックグラウンドテキストをキャラクタで埋め尽くします。
;	疑似グラフィック画面を作る機能が追加されています。
;<d1.w[15～8]:$00=キャラクタで埋め尽くす,$10=疑似グラフィック画面を作る
;<d1.b:テキストエリア番号
;<d2.w:キャラクタ／パレットブロック
;>d0.l:-3=拡張機能を使用できない,-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_CC_BGTEXTCL:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	if	<cmp.w #$0FFF,d1>,ls	;キャラクタを書き込む
		push	d1-d4/a1-a4
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		move.w	d2,d0
		swap.w	d2
		move.w	d0,d2
	  .irp rn,d1,d3,d4,a1,a2,a3,a4
		move.l	d2,rn
	  .endm
		move.w	#2*64*64/32-1,d0
		for	d0
			movem.l	d1-d4/a1-a4,(a0)
			lea.l	32(a0),a0
		next
		pop
	else				;疑似グラフィック画面を作る
		move.b	bank_available(pc),d0
		if	eq			;バンクなし
			moveq.l	#-3,d0			;拡張機能を使用できない
			rts
		endif
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		moveq.l	#$0F,d0
		and.w	d2,d0			;パレットブロック
		lsl.w	#8,d0			;パターン番号上位4bit<<12|パレットブロック<<8|パターン番号下位8bit
		do
			do
			  .rept 8
				move.w	d0,(a0)+
				addq.b	#1,d0
			  .endm
			while	cc
			add.w	#1<<12,d0
		while	cc
	endif
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $CD _BGTEXTST
;	バックグラウンドテキストにキャラクタを書き込みます。
;	疑似グラフィック画面に書き込む機能が追加されています。
;<d1.w[15～8]:$00=キャラクタを書き込む,$10=疑似グラフィック画面に1ドット書き込む
;<d1.b:テキストエリア番号
;<d2.w:X座標
;<d3.w:Y座標
;<d4.w:キャラクタ／パレットコード
;>d0.l:-3=拡張機能を使用できない,-1=スプライト画面を使用できない,0=正常終了
;?a0
iocs_CD_BGTEXTST:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	if	<cmp.w #$0FFF,d1>,ls	;キャラクタを書き込む
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		moveq.l	#63,d0			;00111111
		and.b	d3,d0			;00YYYYYY
		move.b	d0,-(sp)		;00YYYYYY
		move.w	(sp)+,d0		;00YYYYYY........
		move.b	d2,d0			;00YYYYYY..XXXXXX
		add.b	d0,d0			;00YYYYYY.XXXXXX0
		add.b	d0,d0			;00YYYYYYXXXXXX00
		lsr.w	#1,d0			;000YYYYYYXXXXXX0
		move.w	d4,(a0,d0.w)
	else				;疑似グラフィック画面に1ドット書き込む
		move.b	bank_available(pc),d0
		if	eq			;バンクなし
			moveq.l	#-3,d0			;拡張機能を使用できない
			rts
		endif
		push	d1-d3
		lea.l	SPRC_PATTERN,a0
		moveq.l	#%00011,d1
		and.w	SPRC_RESOLUTION-SPRC_PATTERN(a0),d1	;水平サイズ
		if	eq			;8x8
			ifand	<cmp.w #511,d2>,ls,<cmp.w #511,d3>,ls	;範囲内
			;512x512ドットの画面が64x64個の8x8ドット(32バイト)のパターンに分割されている
			;画面座標(%LLLLLLTXX,%BBHHHHYYY)
			;8x8パターン座標(%LLLLLL,%BBHHHH) 8x8パターン内座標(%TXX,%YYY)
			;8x8パターン番号%BBHHHHLLLLLL バンク番号%BB バンク内8x8パターン番号%HHHHLLLLLL
			;ワードアドレス$00EB8000+%HHHHLLLLLLYYYT0 ワード内ビット番号%XX00^%1100
				moveq.l	#%111,d0		;d2.w=%LLLLLLTXX
				moveq.l	#%111,d1		;d3.w=%BBHHHHYYY
				and.w	d2,d0			;d0.l=%TXX
				and.w	d3,d1			;d1.l=%YYY
				lsr.w	#3,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBHHHH000
				add.w	d3,d3			;d3.w=%BBHHHH0000
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BB バンク番号
				and.w	#$00FF,d3		;d3.w=%HHHH0000
				add.w	d3,d3			;d3.w=%HHHH00000
				add.w	d3,d3			;d3.w=%HHHH000000
				or.w	d3,d2			;d2.w=%HHHHLLLLLL バンク内8x8パターン番号
				lsl.w	#3,d2			;d2.w=%HHHHLLLLLL000,x=0
				or.w	d2,d1			;d1.w=%HHHHLLLLLLYYY
				roxr.b	#3,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT
				add.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHHHLLLLLLYYYT0 ワードアドレス
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ワード内ビット番号
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP パレットコード
				move.w	(a0),d3			;ワードを読み出す
				ror.w	d0,d3			;目的の位置を下位4bitへ移動する
				and.w	#$FFF0,d3		;下位4bitを消す
				or.w	d1,d3			;下位4bitにパレットコードを入れる
				rol.w	d0,d3			;元の位置に戻す
				move.w	d3,(a0)			;ワードを書き戻す
			endif
		else				;16x16
			ifand	<cmp.w #1023,d2>,ls,<cmp.w #1023,d3>,ls	;範囲内
			;1024x1024ドットの画面が64x64個の16x16ドット(128バイト)のパターンに分割されている
			;画面座標(%LLLLLLSTXX,%BBBBHHYYYY)
			;パターン座標(%LLLLLL,%BBBBHH) パターン内座標(%STXX,%YYYY)
			;パターン番号%BBBBHHLLLLLL バンク番号%BBBB バンク内パターン番号%HHLLLLLL
			;ワードアドレス$00EB8000+%HHLLLLLLSYYYYT0 ワード内ビット番号%XX00^%1100
				moveq.l	#%1111,d0		;d2.w=%LLLLLLSTXX
				moveq.l	#%1111,d1		;d3.w=%BBBBHHYYYY
				and.w	d2,d0			;d0.l=%STXX
				and.w	d3,d1			;d1.l=%YYYY
				lsr.w	#4,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBBBHH0000
				add.w	d3,d3			;d3.w=%BBBBHH00000
				add.w	d3,d3			;d3.w=%BBBBHH000000,x=0
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BBBB バンク番号
				and.w	#$00FF,d3		;d3.w=%HH000000
				or.w	d3,d2			;d2.w=%HHLLLLLL バンク内パターン番号
				roxr.b	#4,d0			;d0.b=%TXX00000,x=S
				addx.w	d2,d2			;d2.w=%HHLLLLLLS
				lsl.w	#4,d2			;d2.w=%HHLLLLLLS0000
				or.w	d2,d1			;d1.w=%HHLLLLLLSYYYY
				add.b	d0,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT
				add.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHLLLLLLSYYYYT0 ワードアドレス
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ワード内ビット番号
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP パレットコード
				move.w	(a0),d3			;ワードを読み出す
				ror.w	d0,d3			;目的の位置を下位4bitへ移動する
				and.w	#$FFF0,d3		;下位4bitを消す
				or.w	d1,d3			;下位4bitにパレットコードを入れる
				rol.w	d0,d3			;元の位置に戻す
				move.w	d3,(a0)			;ワードを書き戻す
			endif
		endif
		pop
	endif
	moveq.l	#0,d0			;正常終了
	rts

;----------------------------------------------------------------
;IOCS $CE _BGTEXTGT
;	バックグラウンドテキストからキャラクタを読み出します。
;	疑似グラフィック画面から読み出す機能が追加されています。
;<d1.w[15～8]:$00=キャラクタを読み出す,$10=疑似グラフィック画面から1ドット読み出す
;<d1.b:テキストエリア番号
;<d2.w:X座標
;<d3.w:Y座標
;>d0.l:-3=拡張機能を使用できない,-1=スプライト画面を使用できない,0～65535=キャラクタ／パレットコード
;?a0
iocs_CE_BGTEXTGT:
	bsr	check_sprite		;スプライト画面を使用できるか確認する
	if	<cmp.w #$0FFF,d1>,ls	;キャラクタを読み出す
		movea.l	text_area,a0
		if	<tst.b d1>,ne
			lea.l	2*64*64(a0),a0
		endif
		moveq.l	#63,d0			;00111111 ここで上位ワードをクリアする
		and.b	d3,d0			;00YYYYYY
		move.b	d0,-(sp)		;00YYYYYY
		move.w	(sp)+,d0		;00YYYYYY........
		move.b	d2,d0			;00YYYYYY..XXXXXX
		add.b	d0,d0			;00YYYYYY.XXXXXX0
		add.b	d0,d0			;00YYYYYYXXXXXX00
		lsr.w	#1,d0			;000YYYYYYXXXXXX0
		move.w	(a0,d0.w),d0
	else				;疑似グラフィック画面から1ドット読み出す
		move.b	bank_available(pc),d0
		if	eq			;バンクなし
			moveq.l	#-3,d0			;拡張機能を使用できない
			rts
		endif
		push	d1-d3
		lea.l	SPRC_PATTERN,a0
		moveq.l	#0,d0			;範囲外
		moveq.l	#%00011,d1
		and.w	SPRC_RESOLUTION-SPRC_PATTERN(a0),d1	;水平サイズ
		if	eq			;8x8
			ifand	<cmp.w #511,d2>,ls,<cmp.w #511,d3>,ls	;範囲内
			;512x512ドットの画面が64x64個の8x8ドット(32バイト)のパターンに分割されている
			;画面座標(%LLLLLLTXX,%BBHHHHYYY)
			;8x8パターン座標(%LLLLLL,%BBHHHH) 8x8パターン内座標(%TXX,%YYY)
			;8x8パターン番号%BBHHHHLLLLLL バンク番号%BB バンク内8x8パターン番号%HHHHLLLLLL
			;ワードアドレス$00EB8000+%HHHHLLLLLLYYYT0 ワード内ビット番号%XX00^%1100
				moveq.l	#%111,d0		;d2.w=%LLLLLLTXX
				moveq.l	#%111,d1		;d3.w=%BBHHHHYYY
				and.w	d2,d0			;d0.l=%TXX
				and.w	d3,d1			;d1.l=%YYY
				lsr.w	#3,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBHHHH000
				add.w	d3,d3			;d3.w=%BBHHHH0000
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BB バンク番号
				and.w	#$00FF,d3		;d3.w=%HHHH0000
				add.w	d3,d3			;d3.w=%HHHH00000
				add.w	d3,d3			;d3.w=%HHHH000000
				or.w	d3,d2			;d2.w=%HHHHLLLLLL バンク内8x8パターン番号
				lsl.w	#3,d2			;d2.w=%HHHHLLLLLL000,x=0
				or.w	d2,d1			;d1.w=%HHHHLLLLLLYYY
				roxr.b	#3,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT
				add.w	d1,d1			;d1.w=%HHHHLLLLLLYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHHHLLLLLLYYYT0 ワードアドレス
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ワード内ビット番号
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP パレットコード
				move.w	(a0),d3			;ワードを読み出す
				ror.w	d0,d3			;目的の位置を下位4bitへ移動する
				moveq.l	#$0F,d0
				and.w	d3,d0			;下位4bitを読み出す
			endif
		else				;16x16
			ifand	<cmp.w #1023,d2>,ls,<cmp.w #1023,d3>,ls	;範囲内
			;1024x1024ドットの画面が64x64個の16x16ドット(128バイト)のパターンに分割されている
			;画面座標(%LLLLLLSTXX,%BBBBHHYYYY)
			;パターン座標(%LLLLLL,%BBBBHH) パターン内座標(%STXX,%YYYY)
			;パターン番号%BBBBHHLLLLLL バンク番号%BBBB バンク内パターン番号%HHLLLLLL
			;ワードアドレス$00EB8000+%HHLLLLLLSYYYYT0 ワード内ビット番号%XX00^%1100
				moveq.l	#%1111,d0		;d2.w=%LLLLLLSTXX
				moveq.l	#%1111,d1		;d3.w=%BBBBHHYYYY
				and.w	d2,d0			;d0.l=%STXX
				and.w	d3,d1			;d1.l=%YYYY
				lsr.w	#4,d2			;d2.w=%LLLLLL
				eor.w	d1,d3			;d3.w=%BBBBHH0000
				add.w	d3,d3			;d3.w=%BBBBHH00000
				add.w	d3,d3			;d3.w=%BBBBHH000000,x=0
				move.w	d3,SPRC_BANK_NUMBER-SPRC_PATTERN(a0)	;%BBBB バンク番号
				and.w	#$00FF,d3		;d3.w=%HH000000
				or.w	d3,d2			;d2.w=%HHLLLLLL バンク内パターン番号
				roxr.b	#4,d0			;d0.b=%TXX00000,x=S
				addx.w	d2,d2			;d2.w=%HHLLLLLLS
				lsl.w	#4,d2			;d2.w=%HHLLLLLLS0000
				or.w	d2,d1			;d1.w=%HHLLLLLLSYYYY
				add.b	d0,d0			;d0.b=%XX000000,x=T
				addx.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT
				add.w	d1,d1			;d1.w=%HHLLLLLLSYYYYT0
				adda.w	d1,a0			;a0=$00EB8000+%HHLLLLLLSYYYYT0 ワードアドレス
				lsr.b	#4,d0			;d0.b=%XX00
				eori.b	#%1100,d0		;d0.b=%XX00^%1100 ワード内ビット番号
				moveq.l	#%1111,d1
				and.w	d4,d1			;d1.w=%PPPP パレットコード
				move.w	(a0),d3			;ワードを読み出す
				ror.w	d0,d3			;目的の位置を下位4bitへ移動する
				moveq.l	#$0F,d0
				and.w	d3,d0			;下位4bitを読み出す
			endif
		endif
		pop
	endif
	rts

;----------------------------------------------------------------
;IOCS $CF _SPALET
;	スプライトパレットを設定または取得します。
;	パレットブロック0は指定できません。
;<d1.l[31]:1=VDISPの立ち下がりを待たない
;<d1.b:パレットブロック<<4|パレットコード
;<d2.b:パレットブロック(優先)
;<d3.l[31]:0=設定,1=取得
;<d3.w:カラーコード
;>d0.l:-2=パレットブロック0が指定された,0～65535=設定前のカラーコード
;?a0
iocs_CF_SPALET:
	move.b	d2,-(sp)
	moveq.l	#$0F,d0			;ここで上位ワードをクリアする
	and.b	d1,d0			;0<<4|パレットコード
	lsl.b	#4,d2			;d2のパレットブロック<<4|0
	if	ne			;d2にパレットブロックがある
		or.b	d2,d0			;d2のパレットブロック<<4|パレットコード
	else
		goto	<cmp.b d1,d0>,eq,20f	;d2とd1のどちらにもパレットブロックがない
		move.b	d1,d0		;d1のパレットブロック<<4|パレットコード
	endif
	lea.l	VICON_TSPALET,a0
	add.w	d0,d0
	adda.w	d0,a0
	if	<tst.l d1>,pl
		bsr	vdisp_falling_edge	;VDISPの立ち下がりを待つ
	endif
	move.w	(a0),d0			;取得
	if	<tst.l d3>,pl
		move.w	d3,(a0)			;設定
	endif
10:	move.b	(sp)+,d2
	rts

20:	moveq.l	#-2,d0			;パレットブロック0が指定された
	goto	10b

;----------------------------------------------------------------
;デバイスドライバの末尾
device_tail:



dFLAG	reg	d4			;-1=常駐していない,0=常駐部分はデバイスドライバ,1=常駐部分はメモリブロック
aRESI	reg	a2			;常駐部分のプログラムの先頭。0=常駐していない
aPREV	reg	a3			;デバイスドライバとして常駐しているとき直前のデバイスドライバ。さもなくば最後のデバイスドライバ
aSELF	reg	a4			;自分のプログラムの先頭
r	reg	-program_head(aSELF)

;----------------------------------------------------------------
;デバイスコマンド0 初期化
initialize:
	lea.l	program_head(pc),aSELF	;自分のプログラムの先頭

;オプションを確認する
	movea.l	18(a5),a0		;引数の並び。区切りは0、末尾は0,0。先頭はデバイスファイル名
	do
	while	<tst.b (a0)+>,ne	;デバイスファイル名を読み飛ばす
	dostart
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,option_error	;1文字目が-,/でない
		move.b	(a0)+,d0		;2文字目
		goto	eq,option_error		;-,/の後に文字がない
		jbsr	tolower
		if	<cmp.b #'d',d0>,eq	;-d 後始末なし
			goto	<tst.b (enable_flag)r>,ne,option_error	;-d -eは同時に指定できない
			st.b	(disable_flag)r
		elif	<cmp.b #'e',d0>,eq	;-e 後始末あり
			goto	<tst.b (disable_flag)r>,ne,option_error	;-d -eは同時に指定できない
			st.b	(enable_flag)r
		elif	<cmp.b #'q',d0>,eq	;-q 静粛
			st.b	(quiet_flag)r
		else
			goto	option_error
		endif
		tst.b	(a0)+			;引数の区切り
		goto	ne,option_error		;余分な文字がある
	start
		move.b	(a0)+,d0		;次の引数の1文字目
	while	ne

;後始末の設定
	if	<tst.b (disable_flag)r>,ne	;後始末なし
		sf.b	(cleanup_flag)r
	elif	<tst.b (enable_flag)r>,ne	;後始末あり
		st.b	(cleanup_flag)r
	endif

;ベクタを変更する
	lea.l	vector_table(pc),a0	;ベクタテーブル
	bsr	set_vector		;ベクタを変更する

;改行とタイトルを表示する
	if	<tst.b (quiet_flag)r>,eq
		jbsr	printcrlf
		lea.l	title_message(pc),a0
		jbsr	print
	endif

;デバイスドライバの末尾を設定して正常終了する
	move.l	#device_tail,14(a5)	;デバイスドライバの末尾
	moveq.l	#0,d0			;正常終了する
	rts

;オプションエラー
option_error:

;改行とエラーメッセージを表示する。-qは無効
	jbsr	printcrlf
	lea.l	program_colon(pc),a0
	jbsr	print
	lea.l	wrong_message(pc),a0
	jbsr	print

;デバイスドライバを組み込まない
	move.w	#ABORT|MISCELLANEOUS_ERROR,d0	;中止(A) エラーが発生しました
	rts

;----------------------------------------------------------------
;実行開始
execution_start:
	lea.l	program_head(pc),aSELF	;自分のプログラムの先頭

;オプションを確認する
	lea.l	1(a2),a0		;コマンドライン
	dostart
		addq.l	#1,a0
		gotoand	<cmp.b #'-',d0>,ne,<cmp.b #'/',d0>,ne,usage_exit	;1文字目が-,/でない
		move.b	(a0)+,d0		;2文字目
		goto	eq,usage_exit		;-,/の後に文字がない
		jbsr	tolower
		if	<cmp.b #'c',d0>,eq	;-c 常駐確認
			gotoor	<tst.b (release_flag)r>,ne,<tst.b (version_flag)r>,ne,usage_exit	;-c -r -vは同時に指定できない
			st.b	(check_flag)r
		elif	<cmp.b #'d',d0>,eq	;-d 後始末なし
			gotoor	<tst.b (enable_flag)r>,ne,<tst.b (release_flag)r>,ne,usage_exit	;-d -e -rは同時に指定できない
			st.b	(disable_flag)r
		elif	<cmp.b #'e',d0>,eq	;-e 後始末あり
			gotoor	<tst.b (disable_flag)r>,ne,<tst.b (release_flag)r>,ne,usage_exit	;-d -e -rは同時に指定できない
			st.b	(enable_flag)r
		elif	<cmp.b #'q',d0>,eq	;-q 静粛
			st.b	(quiet_flag)r
		elif	<cmp.b #'r',d0>,eq	;-r 常駐解除
			gotoor	<tst.b (check_flag)r>,ne,<tst.b (version_flag)r>,ne,usage_exit	;-c -r -vは同時に指定できない
			gotoor	<tst.b (disable_flag)r>,ne,<tst.b (enable_flag)r>,ne,usage_exit	;-d -e -rは同時に指定できない
			st.b	(release_flag)r
		elif	<cmp.b #'v',d0>,eq	;-v バージョン確認
			gotoor	<tst.b (check_flag)r>,ne,<tst.b (release_flag)r>,ne,usage_exit	;-c -r -vは同時に指定できない
			st.b	(version_flag)r
		else
			goto	usage_exit
		endif
		move.b	(a0),d0			;次の文字
		break	eq
		jbsr	isspace
		goto	ne,usage_exit		;余分な文字がある
	start
		jbsr	nextword		;空白を読み飛ばす
	while	ne

;スーパーバイザモードへ移行する
	supervisormode
;常駐部分を探す
	do
	;デバイスドライバを探す
		moveq.l	#0,dFLAG		;常駐部分はデバイスドライバ
		movea.l	DOS_HUMAN_MEMORY.w,a0	;Human68kの先頭。これより手前はスーパーバイザスタックエリア
		move.w	#'NU',d0		;NULデバイスドライバ=デバイスドライバのリストの先頭を探す。必ずある
		lea.l	DH_NAME(a0),a0
		do
			do
			while	<cmp.w (a0)+,d0>,ne
		whileor	<cmpi.l #'L   ',2-2(a0)>,ne,<cmpi.w #'  ',6-2(a0)>,ne,<cmpi.w #$8024,DH_TYPE-(DH_NAME+2)(a0)>,ne
		lea.l	-(DH_NAME+2)(a0),aRESI	;NULデバイスドライバ
		movem.l	DH_NAME(aSELF),d0-d1	;自分のデバイス名
		do
			break2and	<cmp.l DH_NAME(aRESI),d0>,eq,<cmp.l DH_NAME+4(aRESI),d1>,eq	;デバイス名が同じ
			movea.l	aRESI,aPREV		;デバイスドライバ→直前のデバイスドライバ
			movea.l	DH_NEXT(aRESI),aRESI	;次のデバイスドライバ
		while	<cmpa.w #-1,aRESI>,ne
	;メモリブロックを探す
		moveq.l	#1,dFLAG		;常駐部分はメモリブロック
		movea.l	DOS_HUMAN_MEMORY.w,aRESI	;メモリブロックのリストの先頭
		dostart
			if	<cmpi.b #-1,MM_PARENT(aRESI)>,eq	;常駐している。自分はここで取り除く
				lea.l	MM_PROGRAM+DH_NAME+8(aRESI),a0	;常駐部分のデバイス名の直後
				ifand	<cmpa.l MM_TAIL(aRESI),a0>,ls,<cmp.l -(a0),d1>,eq,<cmp.l -(a0),d0>,eq	;長さが足りていてデバイス名が同じ
					lea.l	MM_PROGRAM(aRESI),aRESI	;常駐部分のプログラムの先頭
					break2
				endif
			endif
		start
			movea.l MM_NEXT(aRESI),aRESI	;次のメモリ管理テーブル
		while	<cmpa.w #0,aRESI>,ne
		moveq.l	#-1,dFLAG		;常駐していない
	while	f
;<dFLAG.l:-1=常駐していない,0=常駐部分はデバイスドライバ,1=常駐部分はメモリブロック
;<aRESI.l:常駐部分のプログラムの先頭。0=常駐していない
;<aPREV.l:デバイスドライバとして常駐しているとき直前のデバイスドライバ。さもなくば最後のデバイスドライバ

;バージョン確認
	if	<tst.b (version_flag)r>,ne	;バージョン確認
		moveq.l	#1,d1			;タイトル
		moveq.l	#0,d2			;正常終了
		goto	message_exit
	endif

;常駐確認
	if	<tst.b (check_flag)r>,ne	;常駐確認
		moveq.l	#2+4,d1			;プログラム名とメッセージ
		moveq.l	#2,d2			;エラー終了。常駐しています
		lea.l	already_message(pc),a1	;常駐しています
		if	<tst.l dFLAG>,mi	;常駐していない
			moveq.l	#3,d2			;エラー終了。常駐していません
			lea.l	not_yet_message(pc),a1	;常駐していません
		endif
		goto	message_exit
	endif

;後始末の設定
	if	<tst.b (disable_flag)r>,ne	;後始末なし
		sf.b	(cleanup_flag)r
	elif	<tst.b (enable_flag)r>,ne	;後始末あり
		st.b	(cleanup_flag)r
	endif

;解除
	if	<tst.b (release_flag)r>,ne	;解除

	;常駐していないのに解除しようとしたらエラー
		if	<tst.l dFLAG>,mi	;常駐していない
			moveq.l	#2+4,d1			;プログラム名とメッセージ
			moveq.l	#3,d2			;エラー終了。常駐していません
			lea.l	not_yet_message(pc),a1	;常駐していません
			goto	message_exit
		endif

	;ベクタが変更されていたらエラー
		lea.l	(vector_table-program_head)(aRESI),a0	;常駐部分のベクタテーブル
		bsr	check_vector		;ベクタを確認する
		if	ne			;ベクタが変更されている
			moveq.l	#2+4,d1			;プログラム名とメッセージ
			moveq.l	#4,d2			;エラー終了。ベクタが変更されています。解除できません
			lea.l	vector_message(pc),a1	;ベクタが変更されています。解除できません
			goto	message_exit
		endif

	;初期化する
		moveq.l	#0,d1
		bsr	iocs_C0_SP_INIT

	;ベクタを復元する
		lea.l	(vector_table-program_head)(aRESI),a0	;常駐部分のベクタテーブル
		bsr	release_vector		;ベクタを復元する

	;デバイスドライバを切り離す／メモリブロックを開放する
		if	<tst.l dFLAG>,eq	;常駐部分はデバイスドライバ
			move.l	DH_NEXT(aRESI),DH_NEXT(aPREV)	;直前のデバイスドライバの次のデバイスドライバは次のデバイスドライバ(-1を含む)
		else				;常駐部分はメモリブロック
			pea.l	MM_SIZE-MM_PROGRAM(aRESI)	;常駐部分のメモリブロックの先頭
			DOS	_MFREE
			addq.l	#4,sp
		endif

	;正常終了する
		moveq.l	#2+4,d1			;プログラム名とメッセージ
		moveq.l	#0,d2			;正常終了
		lea.l	released_message(pc),a1	;解除しました
		goto	message_exit

	endif

;常駐しているのに常駐しようとしたらエラー
	if	<tst.l dFLAG>,pl	;常駐している
	;設定変更
		ifor	<tst.b (disable_flag)r>,ne,<tst.b (enable_flag)r>,ne
			move.b	(cleanup_flag)r,cleanup_flag-program_head(aRESI)
			lea.l	disabled_message(pc),a0	;後始末なし
			if	ne			;後始末あり
				lea.l	enabled_message(pc),a0	;後始末あり
			endif
			moveq.l	#2+4,d1			;プログラム名とメッセージ
			moveq.l	#0,d2			;正常終了
			goto	message_exit
		endif
		moveq.l	#2+4,d1			;プログラム名とメッセージ
		moveq.l	#2,d2			;エラー終了。常駐しています
		lea.l	already_message(pc),a1	;常駐しています
		goto	message_exit
	endif

;ベクタを変更する
	lea.l	vector_table(pc),a0	;ベクタテーブル
	bsr	set_vector		;ベクタを変更する

;デバイスドライバを接続する
;	move.l	aSELF,(aPREV)		;最後のデバイスドライバの次のデバイスドライバを自分にする

;初期化する
	moveq.l	#0,d1
	bsr	iocs_C0_SP_INIT

;常駐終了する
	moveq.l	#1+2+4,d1		;タイトルとプログラム名とメッセージ
	moveq.l	#-1,d2			;常駐終了
	lea.l	resident_message(pc),a1	;常駐しました
	goto	message_exit

;ユーザモードへ復帰して終了する
;<d1.l:1=タイトルを表示する,2=プログラム名を表示する,4=メッセージを表示する
;<d2.w:終了コード。-1=常駐終了,0=正常終了,1～=エラー終了
;<a1.l:メッセージ
message_exit:
;ユーザモードへ復帰する
	usermode
	if	<tst.b (quiet_flag)r>,eq
		if	<btst.l #0,d1>,ne	;タイトルを表示する
			lea.l	title_message(pc),a0
			jbsr	print
		endif
		if	<btst.l #1,d1>,ne	;プログラム名を表示する
			lea.l	program_colon(pc),a0
			jbsr	print
		endif
		if	<btst.l #2,d1>,ne	;メッセージを表示する
			movea.l	a1,a0
			jbsr	print
		endif
	endif
;終了する
	if	<tst.w d2>,mi		;常駐終了
		clr.w	-(sp)
		move.l	#device_tail-program_head,-(sp)
		DOS	_KEEPPR
	endif
	move.w	d2,-(sp)
	DOS	_EXIT2

;タイトルと使用法を表示して終了する
usage_exit:
;タイトルと使用法を表示する。-qは無効
	lea.l	title_message(pc),a0
	jbsr	print
	lea.l	usage_message(pc),a0
	jbsr	print
;終了する
	move.w	#1,-(sp)
	DOS	_EXIT2

;----------------------------------------------------------------
;ベクタを変更する
;	スーパーバイザモードで呼び出すこと
;<a0.l:ベクタテーブル
set_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;オフセット
		move.l	(a1),d0
		move.l	(a0)+,(a1)		;新しいベクタ
		move.l	d0,(a0)+		;古いベクタ
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;ベクタを確認する
;	スーパーバイザモードで呼び出すこと
;<a0.l:常駐部分のベクタテーブル
;>ccr:eq=ベクタは変更されていない,ne=ベクタが変更されている
check_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;オフセット
		move.l	(a1),d0
		break	<cmp.l (a0)+,d0>,ne	;新しいベクタが現在のベクタと一致しなければ失敗
		addq.l	#4,a0			;古いベクタを読み飛ばす
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;ベクタを復元する
;	スーパーバイザモードで呼び出すこと
;<a0.l:常駐部分のベクタテーブル
release_vector:
	push	d0/a0-a1
	dostart
		movea.w	d0,a1			;オフセット
		addq.l	#4,a0			;新しいベクタを読み飛ばす
		move.l	(a0)+,(a1)		;古いベクタ
	start
		move.w	(a0)+,d0
	while	ne
	pop
	rts

;----------------------------------------------------------------
;文字列
  .if ENGLISH
title_message:
	.dc.b	ENGLISH_TITLE,' ',VERSION_STRING,13,10,0
program_colon:
	.dc.b	PROGRAMEN_NAME,': ',0
usage_message:
	.dc.b	'  device = ',PROGRAM_NAME,' <option>',13,10
	.dc.b	'    or',13,10
	.dc.b	'  A>',PROGRAM_NAME,' <option>',13,10
	.dc.b	'    -c    Resident check',10
	.dc.b	'    -d    Disable cleanup',10
	.dc.b	'    -e    Enable cleanup',10
	.dc.b	'    -q    Quiet',13,10
	.dc.b	'    -r    Release',13,10
	.dc.b	'    -v    Version check',13,10,0
wrong_message:
	.dc.b	'Wrong option',13,10,0
already_message:
	.dc.b	'Already resident',13,10,0
resident_message:
	.dc.b	'Resident',13,10,0
not_yet_message:
	.dc.b	'Not yet resident',13,10,0
vector_message:
	.dc.b	'Vector has been changed, unable to release',13,10,0
released_message:
	.dc.b	'Released',13,10,0
disabled_message:
	.dc.b	'Cleanup is disabled',13,10,0
enabled_message:
	.dc.b	'Cleanup is enabled',13,10,0
  .else
title_message:
	.dc.b	JAPANESE_TITLE,' ',VERSION_STRING,13,10,0
program_colon:
	.dc.b	PROGRAM_NAME,': ',0
usage_message:
	.dc.b	'  device = ',PROGRAM_NAME,' <オプション>',13,10
	.dc.b	'    または',13,10
	.dc.b	'  A>',PROGRAM_NAME,' <オプション>',13,10
	.dc.b	'    -c    常駐確認',13,10
	.dc.b	'    -d    後始末なし',10
	.dc.b	'    -e    後始末あり',10
	.dc.b	'    -q    静粛',13,10
	.dc.b	'    -r    常駐解除',13,10
	.dc.b	'    -v    バージョン確認',13,10,0
wrong_message:
	.dc.b	'オプションが違います',13,10,0
already_message:
	.dc.b	'常駐しています',13,10,0
resident_message:
	.dc.b	'常駐しました',13,10,0
not_yet_message:
	.dc.b	'常駐していません',13,10,0
vector_message:
	.dc.b	'ベクタが変更されています。解除できません',13,10,0
released_message:
	.dc.b	'解除しました',13,10,0
disabled_message:
	.dc.b	'後始末なし',13,10,0
enabled_message:
	.dc.b	'後始末あり',13,10,0
  .endif
	.even

	.data

;----------------------------------------------------------------
;フラグ
check_flag:
	.dc.b	0			;-c 常駐確認
disable_flag:
	.dc.b	0			;-d 後始末なし
enable_flag:
	.dc.b	0			;-e 後始末あり
quiet_flag:
	.dc.b	0			;-q 静粛
release_flag:
	.dc.b	0			;-r 常駐解除
version_flag:
	.dc.b	0			;-v バージョン確認
	.even



	.text
	.even

;----------------------------------------------------------------
;空白文字か \s
;<d0.b:文字
;>z:eq=空白文字,ne=空白文字ではない(0を含む)
isspace::
	if	<cmp.b #' ',d0>,ne
		ifand	<cmp.b #9,d0>,hs,<cmp.b #13,d0>,ls	;\t\n\v\f\r
			cmp.b	d0,d0
		endif
	endif
	rts

;----------------------------------------------------------------
;空白を読み飛ばす
;<a0.l:文字列
;>d0.l:最初の空白以外の文字または0
;>a0.l:最初の空白以外の文字または0の位置
;>z:ne=空白以外の文字がある,eq=空白以外の文字がない
nextword::
	moveq.l	#0,d0
	do
		move.b	(a0)+,d0		;次の文字
		break	eq			;0ならば終了
		jbsr	isspace			;空白か
	while	eq			;空白ならば繰り返す
	subq.l	#1,a0			;進み過ぎた分戻る
	tst.l	d0
	rts

;----------------------------------------------------------------
;文字列を表示する
;<a0.l:文字列
print::
	push	d0
	jbsr	strlen
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	move.w	#1,-(sp)
	DOS	_WRITE
	lea.l	(10,sp),sp
	pop
	rts

;----------------------------------------------------------------
;改行を表示する
printcrlf::
	move.l	a0,-(sp)
	lea.l	100f(pc),a0		;13,10
	jbsr	print
	movea.l	(sp)+,a0
	rts

100:	.dc.b	13,10,0
	.even

;----------------------------------------------------------------
;文字列比較
;<a0.l:文字列0
;<a1.l:文字列1
;>ccr:eq=文字列0==文字列1,lo=文字列0<文字列1,hi=文字列1<文字列0
strcmp::
	push	d0/a0-a1
	do
		move.b	(a0)+,d0
		if	eq
			cmp.b	(a1)+,d0
			break
		endif
		cmp.b	(a1)+,d0
	while	eq
	pop
	rts

;----------------------------------------------------------------
;文字列の長さを数える
;<a0.l:文字列
;>d0.l:長さ
strlen::
	move.l	a0,d0			;d0=先頭
	do
	while	<tst.b (a0)+>,ne		;0の次の位置まで進む
	subq.l	#1,a0			;進み過ぎた分戻る。a0=0の位置
	exg.l	d0,a0			;d0=末尾,a0=先頭
	sub.l	a0,d0			;d0=末尾-先頭=長さ
	rts

;----------------------------------------------------------------
;小文字にする
;<d0.b:文字
;>d0.b:文字
tolower::
	ifand	<cmp.b #'A',d0>,hs,<cmp.b #'Z',d0>,ls	;大文字
		add.b	#'a'-'A',d0		;小文字にする
	endif
	rts



;----------------------------------------------------------------
;プログラムの末尾
	.bss
	.even
program_end:

	.end	execution_start

;========================================================================================
;  adotr.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac
	.include	control2.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	push2.mac


  .if STEP=1

dBLK	reg	d4	;ブロックの末尾(4の倍数)
aOUT1	reg	a1	;出力ポインタ1(偶数)
aOUT2	reg	a2	;出力ポインタ2(偶数)
aIN	reg	a3	;入力ポインタ(4の倍数)
aEND	reg	a4	;全体の末尾(4の倍数)

;<a1.l:全体の末尾+α。長さ0は不可
step1:
	clr.l	d2
	lea.l	step1_data(pc,d2.w),aIN	;入力ポインタ(4の倍数)
	add.l	a1,d2
	and.w	#-4,d2			;端数を切り捨てる
	movea.l	d2,aEND			;全体の末尾(4の倍数)
	movea.l	aIN,aOUT1		;出力ポインタ1(偶数)
	do
	;ブロックの末尾を求める
		moveq.l	#4*16,dBLK
		add.l	aIN,dBLK		;先頭+4*16=最長の末尾
		clr.l	d0
		add.l	aEND,d0			;全体の末尾
		sub.l	dBLK,d0			;-最長の末尾
		subx.l	d1,d1			;全体の末尾<最長の末尾?-1:0
		and.l	d1,d0			;全体の末尾<最長の末尾?全体の末尾-最長の末尾:0
		add.l	d0,dBLK			;(全体の末尾<最長の末尾?全体の末尾:最長の末尾)=ブロックの末尾
	;下位31ビットを変換する
	;	4桁の224進数→31ビット整数。224**4=$96100000
		movea.l	aOUT1,aOUT2		;出力ポインタ2(偶数)
		do
			move.l	#-$20202020,d1
			add.l	(aIN)+,d1		;4桁の224進数
			clr.l	d0			;31ビット整数
			moveq.l	#40,d3
			do
				movea.l	d0,a0			;1倍
				lsl.l	#3,d0			;8倍
				sub.l	a0,d0			;7倍
				lsl.l	#5,d0			;224倍
				rol.l	#8,d1			;4桁の224進数の上位から
				add.l	d1,d0			;1桁ずつ取り出して加える
				sf.b	d1			;全体を加えてから
				sub.l	d1,d0			;余分な桁を引き戻す
				lsr.w	#1,d3			;20,10,5,2余り1
			while	cc
			move.l	d0,(aOUT1)+		;31ビット整数
		while	<cmpa.l dBLK,aIN>,lo
	;上位1ビットを加える
	;	0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	0xxxxxxxxxxxxxxxPQR0000000000000
	;		↓
	;	Pxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	Qxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	;	Rxxxxxxxxxxxxxxx
		move.w	-(aOUT1),d1		;最後の2バイトから
		do
			clr.l	d0
			add.w	d1,d1			;1ビットずつ取り出して
			roxr.l	#1,d0
			add.l	d0,(aOUT2)+		;上位1ビットに加える
		while	<cmpa.l aOUT1,aOUT2>,lo
	while	<cmpa.l aEND,aIN>,lo
;キャッシュフラッシュする
	lea.l	1f+(2f-1f)*2-32(pc),a0
	moveq.l	#-(2f-1f),d2
	.cpu	68020
	jmp	32(a0,d2.w*2)
	.cpu	68000
1:	clr.w	d1
	addq.w	#3,d1
	IOCS	_SYS_STAT
2:
;実行する
;<a1.l:末尾(4の倍数+2)
	.align	4,$2048			;movea.l a0,a0

;データ
;	data:	エンコードされたデータ.l[]
;		α($1A)
;	a1:
step1_data:

  .endif	;STEP=1


  .if STEP=2

dOUTEND	reg	d3	;.l 出力バッファの末尾
dDICBIT	reg	d4	;.b 辞書のページ数のビット数。1～15
dDICEND	reg	d5	;.l 辞書の末尾(偶数)
dTEMP	reg	d6	;.b ビット読み出しの一時保管場所。上位dLEFTビットが残っている
dLEFT	reg	d7	;.b dTEMPの残りビット数
aOUTBUF	reg	a1	;.l 出力バッファの先頭(偶数)
aINPPTR	reg	a2	;.l 入力ポインタ
aINPEND	reg	a3	;.l 入力バッファの末尾(偶数)
aOUTPTR	reg	a4	;.l 出力ポインタ
aDICBUF	reg	a5	;.l 辞書の先頭(偶数)。アドレス.l,長さ.l
aDICPTR	reg	a6	;.l 辞書ポインタ

;<a1.l:入力バッファの末尾。先頭の出力バッファの長さを含めて長さ4以下は不可
step2:
;出力バッファの先頭
	moveq.l	#1,d0			;入力バッファの末尾を偶数に切り上げる
	add.l	a1,d0
	and.w	#-2,d0
	movea.l	d0,aOUTBUF		;出力バッファの先頭(偶数)
;ビット読み出しの準備
	moveq.l	#0,dTEMP		;ビット読み出しの一時保管場所
	moveq.l	#0,dLEFT		;dTEMPの残りビット数
	lea.l	step2_data(pc),aINPPTR	;入力バッファの先頭→入力ポインタ
;出力バッファの末尾
	moveq.l	#24,d1
	bsr	get_bits
	move.l	d0,dOUTEND		;出力バッファの長さ
	add.l	aOUTBUF,dOUTEND		;+出力バッファの先頭=出力バッファの末尾
;辞書の先頭
	moveq.l	#1,d0			;出力バッファの末尾を偶数に切り上げる
	add.l	dOUTEND,d0
	and.w	#-2,d0
	movea.l	d0,aDICBUF		;辞書の先頭(偶数)
;辞書のページ数のビット数
	moveq.l	#4,d1
	bsr	get_bits
	goto	eq,data_error		;0は不可
	move.b	d0,dDICBIT		;辞書のページ数のビット数
;辞書の末尾(偶数)
	moveq.l	#8,dDICEND
	lsl.l	dDICBIT,dDICEND		;8*辞書のページ数=辞書の長さ
	add.l	aDICBUF,dDICEND		;+辞書の先頭=辞書の末尾(偶数)
;メモリを確保する
	DOS	_GETPDB
	move.l	dDICEND,d1
	sub.l	d0,d1
	move.l	d1,-(sp)		;メモリブロックの長さ
	move.l	d0,-(sp)		;メモリブロックの先頭
	DOS	_SETBLOCK
	addq.l	#8,sp
	goto	<tst.l d0>,mi,out_of_memory
;辞書を初期化する
;	未定義エントリを参照したときエラーにするため
	moveq.l	#0,d0
	movea.l	aDICBUF,a0
	do
		move.l	d0,(a0)+
		move.l	d0,(a0)+
	while	<cmpa.l dDICEND,a0>,lo
;変数を初期化する
	movea.l	aOUTBUF,aOUTPTR		;出力バッファの先頭→出力ポインタ
	movea.l	aDICBUF,aDICPTR		;辞書の先頭→辞書ポインタ(偶数)
;解凍ループ
	do
	;入力バッファの末尾を踏み越えていないか
		goto	<cmpa.l aOUTBUF,aINPPTR>,hs,data_error
	;辞書にあるか
		moveq.l	#1,d1
		bsr	get_bits
		if	eq			;0=辞書にない
		;辞書に登録する
			move.l	aOUTPTR,(aDICPTR)+	;新しい単語の先頭
			moveq.l	#1,d0
			move.l	d0,(aDICPTR)+		;新しい単語の長さ
		else				;1=辞書にある
		;辞書のページ番号を読み出す
			move.b	dDICBIT,d1
			bsr	get_bits
		;辞書から取り出す
			lsl.l	#3,d0			;8*辞書のページ番号
			move.l	(aDICBUF,d0.l),a0	;a0.l:辞書にある単語の先頭
			move.l	4(aDICBUF,d0.l),d0	;d0.l:辞書にある単語の長さ
		;エントリが定義されているか
			goto	eq,data_error
		;出力バッファの末尾を踏み越えないか
		;	ここで止めないとメモリブロックの末尾を踏み越える可能性がある
			addq.l	#1,d0			;辞書にある単語の長さ+1
			move.l	d0,d1
			add.l	aOUTPTR,d1
			goto	<cmp.l dOUTEND,d1>,hi,data_error
		;辞書に登録する
			move.l	aOUTPTR,(aDICPTR)+	;新しい単語の先頭
			move.l	d0,(aDICPTR)+		;辞書にある単語の長さ+1→新しい単語の長さ
		;辞書にある単語を出力する
			subq.l	#2,d0			;辞書にある単語の長さ-1
			forlong	d0
				move.b	(a0)+,(aOUTPTR)+
			next
		endif
	;文字を出力する
		move.b	(aINPPTR)+,(aOUTPTR)+
	;辞書ポインタを巻き戻す
		if	<cmpa.l dDICEND,aDICPTR>,eq
			movea.l aDICBUF,aDICPTR
		endif
	while	<cmpa.l dOUTEND,aOUTPTR>,lo
;キャッシュフラッシュする
	moveq.l	#-(2f-1f),d0
	.cpu	68020
	jmp	1f+(2f-1f)*2(pc,d0.w*2)
	.cpu	68000
1:	moveq.l	#3,d1
	IOCS	_SYS_STAT
2:
;実行する
	movea.l	aOUTBUF,a0		;出力バッファの先頭
	jmp	(a0)

print_exit:
	DOS	_PRINT
	DOS	_EXIT

out_of_memory:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'out of memory',13,10,0
	.even

data_error:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'data error',13,10,0
	.even

;<d1.b:読み出すビット数
;>d0.l:読み出したデータ
;>z:eq=0,ne=0以外
;?d1-d2
get_bits:
	moveq.l	#0,d0			;読み出したデータ。上位24ビットを使う
	do
		if	<tst.b dLEFT>,eq	;dTEMPが空
			move.b	(aINPPTR)+,dTEMP	;新しいdTEMP
			addq.b	#8,dLEFT		;dTEMPの残りビット数
		endif
		move.b	d1,d2
		if	<cmp.b dLEFT,d2>,hi
			move.b	dLEFT,d2	;d2.b:min(読み出すビット数,dTEMPの残りビット数)
		endif
		move.b	dTEMP,d0		;読み出したデータの
		lsl.l	d2,d0			;下位に押し込む
		lsl.b	d2,dTEMP		;dTEMPの上位から押し出す
		sub.b	d2,dLEFT		;dTEMPの残りビット数
		sub.b	d2,d1			;読み出すビット数の残り
	while	ne
	lsr.l	#8,d0			;読み出したデータ
	rts

;データ
;	入力バッファ、出力バッファ、辞書
step2_data:

  .endif	;STEP=2


  .if STEP=3

dLENGTH	reg	d3	;.l 本体の長さ
aNAME	reg	a2	;.l ファイル名
aBODY	reg	a3	;.l 本体
aTABLE	reg	a4	;.l CRC32テーブル
aEND	reg	a5	;.l CRC32テーブルの末尾

	.offset	0
NAME:	.ds.b	24
DATE:	.ds.l	1
CRC32:	.ds.l	1
LENGTH:	.ds.l	1
BODY:
	.text

;バッファを構成する
	lea.l	step3_data(pc),aNAME	;ファイル名
	move.l	LENGTH-NAME(aNAME),dLENGTH	;本体の長さ
	lea.l	BODY-NAME(aNAME),aBODY	;本体
	move.l	aBODY,d0		;本体
	add.l	dLENGTH,d0		;+本体の長さ=本体の末尾
	addq.l	#1,d0
	and.w	#-2,d0			;偶数に繰り上げる
	movea.l	d0,aTABLE		;CRC32テーブル
	lea.l	4*256(aTABLE),aEND	;CRC32テーブルの末尾
;メモリを確保する
	DOS	_GETPDB
	move.l	aEND,d1
	sub.l	d0,d1
	move.l	d1,-(sp)		;メモリブロックの長さ
	move.l	d0,-(sp)		;メモリブロックの先頭
	DOS	_SETBLOCK
	addq.l	#8,sp
	goto	<tst.l d0>,mi,out_of_memory
;CRC32テーブルを作る
	movea.l	aTABLE,a0
	moveq.l	#0,d1
	do
		move.l	d1,d0
		moveq.l	#8-1,d2
		for	d2
			lsr.l	#1,d0
			if	cs
				eori.l	#$EDB88320,d0
			endif
		next
		move.l	d0,(a0)+
		addq.b	#1,d1
	while	cc
;CRC32を計算する
	movea.l	aTABLE,a1
	moveq.l	#0,d0			;CRC32
	move.l	dLENGTH,d1		;本体の長さ
	movea.l	aBODY,a0		;本体
	not.l	d0
	forcontinuelong	d1
		moveq.l	#0,d2
		move.b	(a0)+,d2
		eor.b	d0,d2
		lsr.l	#8,d0
		lsl.w	#2,d2
		move.l	(a1,d2.l),d2
		eor.l	d2,d0
	next
	not.l	d0
;CRC32を比較する
	goto	<cmp.l CRC32-NAME(aNAME),d0>,ne,crc_error
;ファイルを作る
	move.w	#$0020,-(sp)
	move.l	aNAME,-(sp)
	DOS	_CREATE
	addq.l	#6,sp
	goto	<tst.l d0>,mi,cannot_write
	move.l	dLENGTH,-(sp)
	move.l	aBODY,-(sp)
	move.w	d0,-(sp)
	DOS	_WRITE
	move.l	d0,d1
	move.l	DATE-NAME(aNAME),2(sp)
	DOS	_FILEDATE
	DOS	_CLOSE
	lea.l	10(sp),sp
	if	<cmp.l dLENGTH,d1>,ne
		move.l	aNAME,-(sp)
		DOS	_DELETE
		addq.l	#4,sp
		goto	cannot_write
	endif
;正常終了
	move.l	aNAME,-(sp)
	DOS	_PRINT
	pea.l	@f(pc)
print_exit:
	DOS	_PRINT
	DOS	_EXIT
@@:	.dc.b	' created',13,10,0
	.even

out_of_memory:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'out of memory',13,10,0
	.even

crc_error:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'crc error',13,10,0
	.even

cannot_write:
	pea.l	@f(pc)
	goto	print_exit
@@:	.dc.b	'cannot write',13,10,0
	.even

;データ
;	data:	ファイル名.b[24]
;		日時.l
;		正しい本体のCRC32.l
;		本体の長さ.l
;		本体.b[本体の長さ]
;		.even
;	a1:	CRC32テーブル
step3_data:

  .endif	;STEP=3



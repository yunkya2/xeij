;========================================================================================
;  spr1016test.s
;  Copyright (C) 2003-2025 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

;----------------------------------------------------------------
;spr1016test.x
;	XEiJの拡張機能をテストします。以下の設定で実行してください。
;	・スプライトの枚数1016
;	・4096個のパターン
;	・768x512でスプライトを表示
;	・ラスタあたりのスプライトの枚数1016
;	・sprdrv.xを組み込む
;	何かキーを押すと終了します。
;	X68000実機では動きません。
;更新履歴
;	2025-04-07
;		初版。
;	2025-04-10
;		IOCS _SP_REGSTのスプライト番号の変更に追従しました。
;----------------------------------------------------------------

	.include	control2.mac
	.include	doscall.mac
	.include	fefunc.mac
	.include	forvar.mac
	.include	iocscall.mac
	.include	misc.mac
	.include	sprc.equ

;画面モードを変更する
	move.l	#14<<16|3,-(sp)		;ファンクションキー表示なし
	DOS	_CONCTRL
	addq.l	#4,sp
	move.w	d0,-(sp)
	move.l	#16<<16|0,-(sp)		;768x512グラフィックなし
	DOS	_CONCTRL
	addq.l	#4,sp
	move.w	d0,-(sp)

;スプライト画面を初期化する
	move.l	#'SPRD',d1		;拡張機能を使用する
	move.l	#2<<1|1,d2		;パターン4096個、テキストエリア移動あり
	IOCS	_SP_INIT

;軌道を作る
;	x=16+floor(OX+AX*sin(AF*t)-BX*sin(BF*t))
;	y=16+floor(OY+AY*cos(AF*t)+BY*cos(BF*t))
N	equ	1016			;要素数
M	equ	23			;分割数
PI	fset	3.14159265358979323846	;円周率
TI	fequ	2.0*PI/(M*N)		;t/位置番号
OX	fequ	376.0			;中心X
OY	fequ	248.0			;中心Y
RX	fequ	360.0			;全体の半径X
RY	fequ	240.0			;全体の半径Y
AF	fequ	6.0			;大円の周波数
BF	fequ	23.0			;小円の周波数
PA	fequ	5.0			;大円の割合
PB	fequ	2.0			;小円の割合
AX	fequ	RX*PA/(PA+PB)		;大円の半径X
AY	fequ	RY*PA/(PA+PB)		;大円の半径Y
BX	fequ	RX*PB/(PA+PB)		;小円の半径X
BY	fequ	RY*PB/(PA+PB)		;小円の半径Y
	.data
	.even
ti:	.dc.d	TI
af:	.dc.d	AF
bf:	.dc.d	BF
ax:	.dc.d	AX
bx:	.dc.d	BX
ox:	.dc.d	OX
ay:	.dc.d	AY
by:	.dc.d	BY
oy:	.dc.d	OY
	.bss
	.even
;軌道(位置番号*4→座標)
orbit:
	.dc.w	2*M*N
	.text
	lea.l	orbit(pc),a0		;軌道
	moveq.l	#0,d7			;d7=i 位置番号
	do
		move.l	d7,d0			;d0=i
		FPACK	__LTOD			;d0d1=i
		movem.l	ti(pc),d2-d3		;d2d3=ti
		FPACK	__DMUL			;d0d1=ti*i=t
		move.l	d0,d4
		move.l	d1,d5			;d4d5=t
		movem.l	af(pc),d2-d3		;d2d3=af
		FPACK	__DMUL			;d0d1=af*t
		movea.l	d0,a2
		movea.l	d1,a3			;a2a3=af*t
		move.l	d4,d0
		move.l	d5,d1			;d0d1=t
		movem.l	bf(pc),d2-d3		;d2d3=bf
		FPACK	__DMUL			;d0d1=bf*t
		movea.l	d0,a4
		movea.l	d1,a5			;a4a5=bf*t
		FPACK	__SIN			;d0d1=sin(bf*t)
		movem.l	bx(pc),d2-d3		;d2d3=bx
		FPACK	__DMUL			;d0d1=bx*sin(bf*t)
		move.l	d0,d4
		move.l	d1,d5			;d4d5=bx*sin(bf*t)
		move.l	a2,d0
		move.l	a3,d1			;d0d1=af*t
		FPACK	__SIN			;d0d1=sin(af*t)
		movem.l	ax(pc),d2-d3		;d2d3=ax
		FPACK	__DMUL			;d0d1=ax*sin(af*t)
		move.l	d4,d2
		move.l	d5,d3			;d2d3=bx*sin(bf*t)
		FPACK	__DSUB			;d0d1=ax*sin(af*t)-bx*sin(bf*t)
		movem.l	ox(pc),d2-d3		;d2d3=ox
		FPACK	__DADD			;d0d1=ox+ax*sin(af*t)-bx*sin(bf*t)
		FPACK	__DFLOOR		;d0d1=floor(ox+ax*sin(af*t)-bx*sin(bf*t))
		FPACK	__DTOL			;d0=floor(ox+ax*sin(af*t)-bx*sin(bf*t))
		add.l	#16,d0			;d0=16+floor(ox+ax*sin(af*t)-bx*sin(bf*t))=x
		move.l	d0,d6			;d6=x
		move.l	a4,d0
		move.l	a5,d1			;d0d1=bf*t
		FPACK	__COS			;d0d1=cos(bf*t)
		movem.l	by(pc),d2-d3		;d2d3=by
		FPACK	__DMUL			;d0d1=by*cos(bf*t)
		move.l	d0,d4
		move.l	d1,d5			;d4d5=by*cos(bf*t)
		move.l	a2,d0
		move.l	a3,d1			;d0d1=af*t
		FPACK	__COS			;d0d1=cos(af*t)
		movem.l	ay(pc),d2-d3		;d2d3=ay
		FPACK	__DMUL			;d0d1=ay*cos(af*t)
		move.l	d4,d2
		move.l	d5,d3			;d2d3=by*cos(bf*t)
		FPACK	__DADD			;d0d1=ay*cos(af*t)+by*cos(bf*t)
		movem.l	oy(pc),d2-d3		;d2d3=oy
		FPACK	__DADD			;d0d1=oy+ay*cos(af*t)+by*cos(bf*t)
		FPACK	__DFLOOR		;d0d1=floor(oy+ay*cos(af*t)+by*cos(bf*t))
		FPACK	__DTOL			;d0=floor(oy+ay*cos(af*t)+by*cos(bf*t))
		add.l	#16,d0			;d0=16+floor(oy+ay*cos(af*t)+by*cos(bf*t))=y
		move.w	d6,(a0)+		;x
		move.w	d0,(a0)+		;y
		addq.l	#1,d7			;i++
	while	<cmp.l	#M*N,d7>,lo

;パレットを設定する
;	パレットブロック1～15、パレットコード1～15の225色を使う
;	j=0～224	色番号
;	h=floor(HJ*j)
;	s=31
;	v=floor(VO+VR*cos(VF*TJ*j))
	.data
	.even
hj:	.dc.d	192.0/225.0
vftj:	.dc.d	AF*2.0*PI/225.0
vr:	.dc.d	10.0
vo:	.dc.d	20.0
;色番号→パレットブロック
color_to_block:
	forvar	i,0,224,<.dc.b (i/15)+1>
;色番号→パレットコード
color_to_code:
	forvar	i,0,224,<.dc.b (i.mod.15)+1>
	.text
	lea.l	color_to_block(pc),a4	;色番号→パレットブロック
	lea.l	color_to_code(pc),a5	;色番号→パレットコード
	moveq.l	#0,d7			;d7=j 色番号
	do
		move.l	d7,d0			;d0=j
		FPACK	__LTOD			;d0d1=j
		move.l	d0,d4
		move.l	d1,d5			;d4d5=j
		movem.l	hj(pc),d2-d3		;d2d3=hj
		FPACK	__DMUL			;d0d1=hj*j
		FPACK	__DFLOOR		;d0d1=floor(hj*j)=h
		FPACK	__DTOL			;d0=h
		move.l	d0,d6			;d6=h
		move.l	d4,d0
		move.l	d5,d1			;d0d1=p
		movem.l	vftj(pc),d2-d3		;d2d3=vf*tj
		FPACK	__DMUL			;d0d1=vf*tj*j=vf*t
		FPACK	__COS			;d0d1=cos(vf*t)
		movem.l	vr(pc),d2-d3		;d2d3=vr
		FPACK	__DMUL			;d0d1=vr*cos(vf*t)
		movem.l	vo(pc),d2-d3		;d2d3=vo
		FPACK	__DADD			;d0d1=vo+vr*cos(vf*t)
		FPACK	__DFLOOR		;d0d1=floor(vo+vr*cos(vf*t))=V
		FPACK	__DTOL			;d0=v
		move.l	d6,d1			;d1=h
		swap.w	d1			;d1=h<<16
		move.w	#31<<8,d1		;d1=h<<16|s<<8
		move.b	d0,d1			;d1=h<<16|s<<8|v
		IOCS	_HSVTORGB		;d0=カラーコード
		move.w	d0,d3			;d3=カラーコード
		moveq.l	#0,d2
		move.b	(a4,d7.w),d2		;d2=b パレットブロック
		moveq.l	#0,d1
		move.b	(a5,d7.w),d1		;d1=c パレットコード
		if	<tst.w d7>,ne
			bset.l	#31,d1
		endif
		IOCS	_SPALET
		addq.w	#1,d7			;p++
	while	<cmp.w	#225,d7>,lo

;パターンを定義する
	.data
	.even
;要素番号*2→文字
elem_to_moji:
	.dc.b	'亜唖娃阿哀愛挨姶逢葵茜穐悪握渥旭葦芦鯵梓圧斡扱宛姐虻飴絢綾鮎或粟袷安庵按暗案闇鞍杏以伊位依偉囲夷委威'
	.dc.b	'尉惟意慰易椅為畏異移維緯胃萎衣謂違遺医井亥域育郁磯一壱溢逸稲茨芋鰯允印咽員因姻引飲淫胤蔭院陰隠韻吋右'
	.dc.b	'宇烏羽迂雨卯鵜窺丑碓臼渦嘘唄欝蔚鰻姥厩浦瓜閏噂云運雲荏餌叡営嬰影映曳栄永泳洩瑛盈穎頴英衛詠鋭液疫益駅'
	.dc.b	'悦謁越閲榎厭円園堰奄宴延怨掩援沿演炎焔煙燕猿縁艶苑薗遠鉛鴛塩於汚甥凹央奥往応押旺横欧殴王翁襖鴬鴎黄岡'
	.dc.b	'沖荻億屋憶臆桶牡乙俺卸恩温穏音下化仮何伽価佳加可嘉夏嫁家寡科暇果架歌河火珂禍禾稼箇花苛茄荷華菓蝦課嘩'
	.dc.b	'貨迦過霞蚊俄峨我牙画臥芽蛾賀雅餓駕介会解回塊壊廻快怪悔恢懐戒拐改魁晦械海灰界皆絵芥蟹開階貝凱劾外咳害'
	.dc.b	'崖慨概涯碍蓋街該鎧骸浬馨蛙垣柿蛎鈎劃嚇各廓拡撹格核殻獲確穫覚角赫較郭閣隔革学岳楽額顎掛笠樫橿梶鰍潟割'
	.dc.b	'喝恰括活渇滑葛褐轄且鰹叶椛樺鞄株兜竃蒲釜鎌噛鴨栢茅萱粥刈苅瓦乾侃冠寒刊勘勧巻喚堪姦完官寛干幹患感慣憾'
	.dc.b	'換敢柑桓棺款歓汗漢澗潅環甘監看竿管簡緩缶翰肝艦莞観諌貫還鑑間閑関陥韓館舘丸含岸巌玩癌眼岩翫贋雁頑顔願'
	.dc.b	'企伎危喜器基奇嬉寄岐希幾忌揮机旗既期棋棄機帰毅気汽畿祈季稀紀徽規記貴起軌輝飢騎鬼亀偽儀妓宜戯技擬欺犠'
	.dc.b	'疑祇義蟻誼議掬菊鞠吉吃喫桔橘詰砧杵黍却客脚虐逆丘久仇休及吸宮弓急救朽求汲泣灸球究窮笈級糾給旧牛去居巨'
	.dc.b	'拒拠挙渠虚許距鋸漁禦魚亨享京供侠僑兇競共凶協匡卿叫喬境峡強彊怯恐恭挟教橋況狂狭矯胸脅興蕎郷鏡響饗驚仰'
	.dc.b	'凝尭暁業局曲極玉桐粁僅勤均巾錦斤欣欽琴禁禽筋緊芹菌衿襟謹近金吟銀九倶句区狗玖矩苦躯駆駈駒具愚虞喰空偶'
	.dc.b	'寓遇隅串櫛釧屑屈掘窟沓靴轡窪熊隈粂栗繰桑鍬勲君薫訓群軍郡卦袈祁係傾刑兄啓圭珪型契形径恵慶慧憩掲携敬景'
	.dc.b	'桂渓畦稽系経継繋罫茎荊蛍計詣警軽頚鶏芸迎鯨劇戟撃激隙桁傑欠決潔穴結血訣月件倹倦健兼券剣喧圏堅嫌建憲懸'
	.dc.b	'拳捲検権牽犬献研硯絹県肩見謙賢軒遣鍵険顕験鹸元原厳幻弦減源玄現絃舷言諺限乎個古呼固姑孤己庫弧戸故枯湖'
	.dc.b	'狐糊袴股胡菰虎誇跨鈷雇顧鼓五互伍午呉吾娯後御悟梧檎瑚碁語誤護醐乞鯉交佼侯候倖光公功効勾厚口向后喉坑垢'
	.dc.b	'好孔孝宏工巧巷幸広庚康弘恒慌抗拘控攻昂晃更杭校梗構江洪浩港溝甲皇硬稿糠紅紘絞綱耕考肯肱腔膏航荒行衡講'
	.dc.b	'貢購郊酵鉱砿鋼閤降項香高鴻剛劫号合壕拷濠豪轟麹克刻告国穀酷鵠黒獄漉腰甑忽惚骨狛込此頃今困坤墾婚恨懇昏'
	.dc.b	'昆根梱混痕紺艮魂些佐叉唆嵯左差査沙瑳砂詐鎖裟坐座挫債催再最哉塞妻宰彩才採栽歳済災采犀砕砦祭斎細菜裁載'
	.dc.b	'際剤在材罪財冴坂阪堺榊肴咲崎埼碕'
;要素番号→パレットコード
elem_to_code:
	forvar	i,0,N-1,<.dc.b ((i*225/N).mod.15)+1>
	.text
	lea.l	-(4+2*16+4*32)(sp),sp	;フォントサイズ、フォントデータ、パターンデータ
	lea.l	elem_to_moji(pc),a3	;要素番号*2→文字
	lea.l	elem_to_code(pc),a5	;要素番号→パレットコード
	moveq.l	#0,d4			;要素番号
	do
	;フォントデータを得る
		move.w	(a3)+,d1		;文字
		moveq.l	#0,d2			;16x16
		movea.l	sp,a1			;フォントサイズ、フォントデータ
		IOCS	_FNTGET
	;パレットコードを用意する
		move.b	(a5)+,d5		;パレットコード
	;フォントデータからパターンデータを作る
		lea.l	4(sp),a0		;フォントデータ
		lea.l	4+2*16(sp),a1		;パターンデータ
	;左半分
		moveq	#16-1,d3
		for	d3
			move.b	(a0)+,d0		;上→下
			addq.l	#1,a0
		;	moveq.l	#0,d1
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d5,d1
				endif
			next
			move.l	d1,(a1)+		;左上→左下=右上
		next
		lea.l	-2*16(a0),a0		;下→上
	;右半分
		moveq	#16-1,d3
		for	d3
			addq.l	#1,a0			;上→下
			move.b	(a0)+,d0
		;	moveq.l	#0,d1
			moveq.l	#8-1,d2
			for	d2
				lsl.l	#4,d1
				add.b	d0,d0
				if	cs
					or.b	d5,d1
				endif
			next
			move.l	d1,(a1)+		;左下=右上→右下
		next
	;パターンを定義する
		move.l	d4,d1			;パターン番号=要素番号
		moveq.l	#1,d2			;16x16
		lea.l	4+2*16(sp),a1		;パターンデータ
		IOCS	_SP_DEFCG
		addq.w	#1,d4			;要素番号++
	while	<cmp.w #N,d4>,lo
	lea.l	4+2*16+4*32(sp),sp

;カーソル表示OFF
	IOCS	_B_CUROFF

;スプライト表示ON
	IOCS	_SP_ON

;動かす
	.data
	.even
;要素番号*2→キャラクタ
elem_to_char:
	forvar	i,0,N-1,<.dc.w ((i&$F00)<<4)|(((i*225/N)/15+1)<<8)|(i&$FF)>
	.text
	lea.l	orbit(pc),a2		;軌道の先頭→要素0の座標のアドレス
	movea.l	a2,a3			;軌道の先頭
	move.l	#4*M*N,d6		;軌道の長さ
	adda.l	d6,a3			;軌道の末尾
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	movea.l	#$80000000,a5
	do
		lea.l	elem_to_char(pc),a4	;要素番号*2→キャラクタ
		movea.l	a2,a1			;要素の座標のアドレス
		moveq.l	#0,d1			;要素0はVDISPの立ち下がりを待つ
		moveq.l	#0,d7			;要素番号
		do
			move.w	d7,d1			;スプライト番号(連番)
			move.w	(a1)+,d2		;X座標
			move.w	(a1)+,d3		;Y座標
			move.w	(a4)+,d4		;キャラクタ
			moveq.l	#3,d5			;プライオリティ
			IOCS	_SP_REGST
			move.l	a5,d1			;要素0以外はVDISPの立ち下がりを待たない
			lea.l	4*(M-1)(a1),a1		;要素の座標のアドレス+=分割数*4
			if	<cmpa.l a3,a1>,hs	;末尾に達した
				suba.l	d6,a1			;巻き戻す
			endif
			addq.w	#1,d7			;要素番号++
		while	<cmp.w #N,d7>,lo
		addq.l	#4,a2			;要素0の座標のアドレス+=4
		if	<cmpa.l a3,a2>,hs	;末尾に達した
			suba.l	d6,a2			;巻き戻す
		endif
		bsr	inkey0
	while	eq			;何かキーが押されるまで繰り返す

;スプライト表示OFF
	IOCS	_SP_OFF

;カーソル表示ON
	IOCS	_B_CURON

;画面モードを復元する
	move.w	#16,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp
	move.w	#14,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

;終了
	DOS	_EXIT

;----------------------------------------------------------------
;文字コードが0でないキーを入力する。押されていなくても待たない
;>d0.l:文字コード。0=押されていない
inkey0::
	dostart
		IOCS	_B_KEYINP		;キーバッファから取り除く
		break	<tst.b d0>,ne		;文字コードが0でないキーが押されたとき終了
	start
		IOCS	_B_KEYSNS		;キーバッファを先読みする
	while	<tst.l d0>,ne		;何か押されているとき繰り返す
	and.l	#$000000FF,d0		;文字コード
	rts

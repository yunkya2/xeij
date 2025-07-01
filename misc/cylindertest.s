;========================================================================================
;  cylindertest.s
;  Copyright (C) 2003-2023 Makoto Kamada
;
;  This file is part of the XEiJ (X68000 Emulator in Java).
;  You can use, modify and redistribute the XEiJ if the conditions are met.
;  Read the XEiJ License for more details.
;  https://stdkmd.net/xeij/
;========================================================================================

	.include	doscall.mac
	.include	iocscall.mac
	.include	control2.mac

	clr.w	-(sp)			;768x512
	move.w	#16,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

	lea.l	kanji,a2		;Š¿Žš‚Å–„‚ßs‚­‚·
	moveq.l	#0,d5
	do
		moveq.l	#3,d1			;•¶Žš‘®«
		moveq.l	#0,d2			;Œ…À•W
		move.l	d5,d3			;sÀ•W
		moveq.l	#128-1,d4		;•\Ž¦‚·‚éŒ…”-1
		movea.l	a2,a1			;•¶Žš—ñ‚ÌƒAƒhƒŒƒX
		IOCS	_B_PUTMES
		lea.l	128(a2),a2
		addq.w	#1,d5
	while	<cmp.w #64,d5>,lo

	move.w	#-384+2,d4		;X•ûŒü‚ÌƒXƒNƒ[ƒ‹ˆÊ’u
	move.w	#-256+2,d5		;Y•ûŒü‚ÌƒXƒNƒ[ƒ‹ˆÊ’u
	do
		lea.l	$00E80014,a1		;ƒXƒNƒ[ƒ‹‚³‚¹‚é
		move.w	d4,d1
		swap.w	d1
		move.w	d5,d1
		and.l	#$03FF03FF,d1
		IOCS	_B_LPOKE
		IOCS	_B_SFTSNS		;ƒL[‘€ì‚ÅƒXƒNƒ[ƒ‹ˆÊ’u‚ð•ÏX‚·‚é
		moveq.l	#1,d2
		if	<btst.l #1,d0>,ne	;CTRL
			moveq.l	#16,d2
		endif
		IOCS	_B_KEYINP
		if	<cmp.w #$3600,d0>,eq	;HOME
			move.w	#-384,d4
			move.w	#-256,d5
		elif	<cmp.w #$3B00,d0>,eq	;©
			sub.w	d2,d4
		elif	<cmp.w #$3C00,d0>,eq	;ª
			sub.w	d2,d5
		elif	<cmp.w #$3D00,d0>,eq	;¨
			add.w	d2,d4
		elif	<cmp.w #$3E00,d0>,eq	;«
			add.w	d2,d5
		endif
	while	<cmp.b #$1B,d0>,ne	;ESC

	clr.w	-(sp)			;768x512
	move.w	#16,-(sp)
	DOS	_CONCTRL
	addq.l	#4,sp

	DOS	_EXIT

kanji:
	.dc.b	'ˆŸˆ ˆ¡ˆ¢ˆ£ˆ¤ˆ¥ˆ¦ˆ§ˆ¨ˆ©ˆªˆ«ˆ¬ˆ­ˆ®ˆ¯ˆ°ˆ±ˆ²ˆ³ˆ´ˆµˆ¶ˆ·ˆ¸ˆ¹ˆºˆ»ˆ¼ˆ½ˆ¾'
	.dc.b	'ˆ¿ˆÀˆÁˆÂˆÃˆÄˆÅˆÆˆÇˆÈˆÉˆÊˆËˆÌˆÍˆÎˆÏˆÐˆÑˆÒˆÓˆÔˆÕˆÖˆ×ˆØˆÙˆÚˆÛˆÜˆÝˆÞ'
	.dc.b	'ˆßˆàˆáˆâˆãˆäˆåˆæˆçˆèˆéˆêˆëˆìˆíˆîˆïˆðˆñˆòˆóˆôˆõˆöˆ÷ˆøˆùˆúˆûˆü‰@‰A'
	.dc.b	'‰B‰C‰D‰E‰F‰G‰H‰I‰J‰K‰L‰M‰N‰O‰P‰Q‰R‰S‰T‰U‰V‰W‰X‰Y‰Z‰[‰\‰]‰^‰_‰`‰a'
	.dc.b	'‰b‰c‰d‰e‰f‰g‰h‰i‰j‰k‰l‰m‰n‰o‰p‰q‰r‰s‰t‰u‰v‰w‰x‰y‰z‰{‰|‰}‰~‰€‰‰‚'
	.dc.b	'‰ƒ‰„‰…‰†‰‡‰ˆ‰‰‰Š‰‹‰Œ‰‰Ž‰‰‰‘‰’‰“‰”‰•‰–‰—‰˜‰™‰š‰›‰œ‰‰ž‰Ÿ‰ ‰¡‰¢'
	.dc.b	'‰£‰¤‰¥‰¦‰§‰¨‰©‰ª‰«‰¬‰­‰®‰¯‰°‰±‰²‰³‰´‰µ‰¶‰·‰¸‰¹‰º‰»‰¼‰½‰¾‰¿‰À‰Á‰Â'
	.dc.b	'‰Ã‰Ä‰Å‰Æ‰Ç‰È‰É‰Ê‰Ë‰Ì‰Í‰Î‰Ï‰Ð‰Ñ‰Ò‰Ó‰Ô‰Õ‰Ö‰×‰Ø‰Ù‰Ú‰Û‰Ü‰Ý‰Þ‰ß‰à‰á‰â'
	.dc.b	'‰ã‰ä‰å‰æ‰ç‰è‰é‰ê‰ë‰ì‰í‰î‰ï‰ð‰ñ‰ò‰ó‰ô‰õ‰ö‰÷‰ø‰ù‰ú‰û‰üŠ@ŠAŠBŠCŠDŠE'
	.dc.b	'ŠFŠGŠHŠIŠJŠKŠLŠMŠNŠOŠPŠQŠRŠSŠTŠUŠVŠWŠXŠYŠZŠ[Š\Š]Š^Š_Š`ŠaŠbŠcŠdŠe'
	.dc.b	'ŠfŠgŠhŠiŠjŠkŠlŠmŠnŠoŠpŠqŠrŠsŠtŠuŠvŠwŠxŠyŠzŠ{Š|Š}Š~Š€ŠŠ‚ŠƒŠ„Š…Š†'
	.dc.b	'Š‡ŠˆŠ‰ŠŠŠ‹ŠŒŠŠŽŠŠŠ‘Š’Š“Š”Š•Š–Š—Š˜Š™ŠšŠ›ŠœŠŠžŠŸŠ Š¡Š¢Š£Š¤Š¥Š¦'
	.dc.b	'Š§Š¨Š©ŠªŠ«Š¬Š­Š®Š¯Š°Š±Š²Š³Š´ŠµŠ¶Š·Š¸Š¹ŠºŠ»Š¼Š½Š¾Š¿ŠÀŠÁŠÂŠÃŠÄŠÅŠÆ'
	.dc.b	'ŠÇŠÈŠÉŠÊŠËŠÌŠÍŠÎŠÏŠÐŠÑŠÒŠÓŠÔŠÕŠÖŠ×ŠØŠÙŠÚŠÛŠÜŠÝŠÞŠßŠàŠáŠâŠãŠäŠåŠæ'
	.dc.b	'ŠçŠèŠéŠêŠëŠìŠíŠîŠïŠðŠñŠòŠóŠôŠõŠöŠ÷ŠøŠùŠúŠûŠü‹@‹A‹B‹C‹D‹E‹F‹G‹H‹I'
	.dc.b	'‹J‹K‹L‹M‹N‹O‹P‹Q‹R‹S‹T‹U‹V‹W‹X‹Y‹Z‹[‹\‹]‹^‹_‹`‹a‹b‹c‹d‹e‹f‹g‹h‹i'
	.dc.b	'‹j‹k‹l‹m‹n‹o‹p‹q‹r‹s‹t‹u‹v‹w‹x‹y‹z‹{‹|‹}‹~‹€‹‹‚‹ƒ‹„‹…‹†‹‡‹ˆ‹‰‹Š'
	.dc.b	'‹‹‹Œ‹‹Ž‹‹‹‘‹’‹“‹”‹•‹–‹—‹˜‹™‹š‹›‹œ‹‹ž‹Ÿ‹ ‹¡‹¢‹£‹¤‹¥‹¦‹§‹¨‹©‹ª'
	.dc.b	'‹«‹¬‹­‹®‹¯‹°‹±‹²‹³‹´‹µ‹¶‹·‹¸‹¹‹º‹»‹¼‹½‹¾‹¿‹À‹Á‹Â‹Ã‹Ä‹Å‹Æ‹Ç‹È‹É‹Ê'
	.dc.b	'‹Ë‹Ì‹Í‹Î‹Ï‹Ð‹Ñ‹Ò‹Ó‹Ô‹Õ‹Ö‹×‹Ø‹Ù‹Ú‹Û‹Ü‹Ý‹Þ‹ß‹à‹á‹â‹ã‹ä‹å‹æ‹ç‹è‹é‹ê'
	.dc.b	'‹ë‹ì‹í‹î‹ï‹ð‹ñ‹ò‹ó‹ô‹õ‹ö‹÷‹ø‹ù‹ú‹û‹üŒ@ŒAŒBŒCŒDŒEŒFŒGŒHŒIŒJŒKŒLŒM'
	.dc.b	'ŒNŒOŒPŒQŒRŒSŒTŒUŒVŒWŒXŒYŒZŒ[Œ\Œ]Œ^Œ_Œ`ŒaŒbŒcŒdŒeŒfŒgŒhŒiŒjŒkŒlŒm'
	.dc.b	'ŒnŒoŒpŒqŒrŒsŒtŒuŒvŒwŒxŒyŒzŒ{Œ|Œ}Œ~Œ€ŒŒ‚ŒƒŒ„Œ…Œ†Œ‡ŒˆŒ‰ŒŠŒ‹ŒŒŒŒŽ'
	.dc.b	'ŒŒŒ‘Œ’Œ“Œ”Œ•Œ–Œ—Œ˜Œ™ŒšŒ›ŒœŒŒžŒŸŒ Œ¡Œ¢Œ£Œ¤Œ¥Œ¦Œ§Œ¨Œ©ŒªŒ«Œ¬Œ­Œ®'
	.dc.b	'Œ¯Œ°Œ±Œ²Œ³Œ´ŒµŒ¶Œ·Œ¸Œ¹ŒºŒ»Œ¼Œ½Œ¾Œ¿ŒÀŒÁŒÂŒÃŒÄŒÅŒÆŒÇŒÈŒÉŒÊŒËŒÌŒÍŒÎ'
	.dc.b	'ŒÏŒÐŒÑŒÒŒÓŒÔŒÕŒÖŒ×ŒØŒÙŒÚŒÛŒÜŒÝŒÞŒßŒàŒáŒâŒãŒäŒåŒæŒçŒèŒéŒêŒëŒìŒíŒî'
	.dc.b	'ŒïŒðŒñŒòŒóŒôŒõŒöŒ÷ŒøŒùŒúŒûŒü@ABCDEFGHIJKLMNOPQ'
	.dc.b	'RSTUVWXYZ[\]^_`abcdefghijklmnopq'
	.dc.b	'rstuvwxyz{|}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’'
	.dc.b	'“”•–—˜™š›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²'
	.dc.b	'³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒ'
	.dc.b	'ÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñò'
	.dc.b	'óôõö÷øùúûüŽ@ŽAŽBŽCŽDŽEŽFŽGŽHŽIŽJŽKŽLŽMŽNŽOŽPŽQŽRŽSŽTŽU'
	.dc.b	'ŽVŽWŽXŽYŽZŽ[Ž\Ž]Ž^Ž_Ž`ŽaŽbŽcŽdŽeŽfŽgŽhŽiŽjŽkŽlŽmŽnŽoŽpŽqŽrŽsŽtŽu'
	.dc.b	'ŽvŽwŽxŽyŽzŽ{Ž|Ž}Ž~Ž€ŽŽ‚ŽƒŽ„Ž…Ž†Ž‡ŽˆŽ‰ŽŠŽ‹ŽŒŽŽŽŽŽŽ‘Ž’Ž“Ž”Ž•Ž–'
	.dc.b	'Ž—Ž˜Ž™ŽšŽ›ŽœŽŽžŽŸŽ Ž¡Ž¢Ž£Ž¤Ž¥Ž¦Ž§Ž¨Ž©ŽªŽ«Ž¬Ž­Ž®Ž¯Ž°Ž±Ž²Ž³Ž´ŽµŽ¶'
	.dc.b	'Ž·Ž¸Ž¹ŽºŽ»Ž¼Ž½Ž¾Ž¿ŽÀŽÁŽÂŽÃŽÄŽÅŽÆŽÇŽÈŽÉŽÊŽËŽÌŽÍŽÎŽÏŽÐŽÑŽÒŽÓŽÔŽÕŽÖ'
	.dc.b	'Ž×ŽØŽÙŽÚŽÛŽÜŽÝŽÞŽßŽàŽáŽâŽãŽäŽåŽæŽçŽèŽéŽêŽëŽìŽíŽîŽïŽðŽñŽòŽóŽôŽõŽö'
	.dc.b	'Ž÷ŽøŽùŽúŽûŽü@ABCDEFGHIJKLMNOPQRSTUVWXY'
	.dc.b	'Z[\]^_`abcdefghijklmnopqrstuvwxy'
	.dc.b	'z{|}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š'
	.dc.b	'›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º'
	.dc.b	'»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚ'
	.dc.b	'ÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùú'
	.dc.b	'ûü@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]'
	.dc.b	'^_`abcdefghijklmnopqrstuvwxyz{|}'
	.dc.b	'~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œž'
	.dc.b	'Ÿ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾'
	.dc.b	'¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞ'
	.dc.b	'ßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûü‘@‘A'
	.dc.b	'‘B‘C‘D‘E‘F‘G‘H‘I‘J‘K‘L‘M‘N‘O‘P‘Q‘R‘S‘T‘U‘V‘W‘X‘Y‘Z‘[‘\‘]‘^‘_‘`‘a'
	.dc.b	'‘b‘c‘d‘e‘f‘g‘h‘i‘j‘k‘l‘m‘n‘o‘p‘q‘r‘s‘t‘u‘v‘w‘x‘y‘z‘{‘|‘}‘~‘€‘‘‚'
	.dc.b	'‘ƒ‘„‘…‘†‘‡‘ˆ‘‰‘Š‘‹‘Œ‘‘Ž‘‘‘‘‘’‘“‘”‘•‘–‘—‘˜‘™‘š‘›‘œ‘‘ž‘Ÿ‘ ‘¡‘¢'
	.dc.b	'‘£‘¤‘¥‘¦‘§‘¨‘©‘ª‘«‘¬‘­‘®‘¯‘°‘±‘²‘³‘´‘µ‘¶‘·‘¸‘¹‘º‘»‘¼‘½‘¾‘¿‘À‘Á‘Â'
	.dc.b	'‘Ã‘Ä‘Å‘Æ‘Ç‘È‘É‘Ê‘Ë‘Ì‘Í‘Î‘Ï‘Ð‘Ñ‘Ò‘Ó‘Ô‘Õ‘Ö‘×‘Ø‘Ù‘Ú‘Û‘Ü‘Ý‘Þ‘ß‘à‘á‘â'
	.dc.b	'‘ã‘ä‘å‘æ‘ç‘è‘é‘ê‘ë‘ì‘í‘î‘ï‘ð‘ñ‘ò‘ó‘ô‘õ‘ö‘÷‘ø‘ù‘ú‘û‘ü’@’A’B’C’D’E'
	.dc.b	'’F’G’H’I’J’K’L’M’N’O’P’Q’R’S’T’U’V’W’X’Y’Z’[’\’]’^’_’`’a’b’c’d’e'
	.dc.b	'’f’g’h’i’j’k’l’m’n’o’p’q’r’s’t’u’v’w’x’y’z’{’|’}’~’€’’‚’ƒ’„’…’†'
	.dc.b	'’‡’ˆ’‰’Š’‹’Œ’’Ž’’’‘’’’“’”’•’–’—’˜’™’š’›’œ’’ž’Ÿ’ ’¡’¢’£’¤’¥’¦'
	.dc.b	'’§’¨’©’ª’«’¬’­’®’¯’°’±’²’³’´’µ’¶’·’¸’¹’º’»’¼’½’¾’¿’À’Á’Â’Ã’Ä’Å’Æ'
	.dc.b	'’Ç’È’É’Ê’Ë’Ì’Í’Î’Ï’Ð’Ñ’Ò’Ó’Ô’Õ’Ö’×’Ø’Ù’Ú’Û’Ü’Ý’Þ’ß’à’á’â’ã’ä’å’æ'
	.dc.b	'’ç’è’é’ê’ë’ì’í’î’ï’ð’ñ’ò’ó’ô’õ’ö’÷’ø’ù’ú’û’ü“@“A“B“C“D“E“F“G“H“I'
	.dc.b	'“J“K“L“M“N“O“P“Q“R“S“T“U“V“W“X“Y“Z“[“\“]“^“_“`“a“b“c“d“e“f“g“h“i'
	.dc.b	'“j“k“l“m“n“o“p“q“r“s“t“u“v“w“x“y“z“{“|“}“~“€““‚“ƒ“„“…“†“‡“ˆ“‰“Š'
	.dc.b	'“‹“Œ““Ž“““‘“’“““”“•“–“—“˜“™“š“›“œ““ž“Ÿ“ “¡“¢“£“¤“¥“¦“§“¨“©“ª'
	.dc.b	'“«“¬“­“®“¯“°“±“²“³“´“µ“¶“·“¸“¹“º“»“¼“½“¾“¿“À“Á“Â“Ã“Ä“Å“Æ“Ç“È“É“Ê'
	.dc.b	'“Ë“Ì“Í“Î“Ï“Ð“Ñ“Ò“Ó“Ô“Õ“Ö“×“Ø“Ù“Ú“Û“Ü“Ý“Þ“ß“à“á“â“ã“ä“å“æ“ç“è“é“ê'
	.dc.b	'“ë“ì“í“î“ï“ð“ñ“ò“ó“ô“õ“ö“÷“ø“ù“ú“û“ü”@”A”B”C”D”E”F”G”H”I”J”K”L”M'
	.dc.b	'”N”O”P”Q”R”S”T”U”V”W”X”Y”Z”[”\”]”^”_”`”a”b”c”d”e”f”g”h”i”j”k”l”m'
	.dc.b	'”n”o”p”q”r”s”t”u”v”w”x”y”z”{”|”}”~”€””‚”ƒ”„”…”†”‡”ˆ”‰”Š”‹”Œ””Ž'
	.dc.b	'”””‘”’”“”””•”–”—”˜”™”š”›”œ””ž”Ÿ” ”¡”¢”£”¤”¥”¦”§”¨”©”ª”«”¬”­”®'
	.dc.b	'”¯”°”±”²”³”´”µ”¶”·”¸”¹”º”»”¼”½”¾”¿”À”Á”Â”Ã”Ä”Å”Æ”Ç”È”É”Ê”Ë”Ì”Í”Î'
	.dc.b	'”Ï”Ð”Ñ”Ò”Ó”Ô”Õ”Ö”×”Ø”Ù”Ú”Û”Ü”Ý”Þ”ß”à”á”â”ã”ä”å”æ”ç”è”é”ê”ë”ì”í”î'
	.dc.b	'”ï”ð”ñ”ò”ó”ô”õ”ö”÷”ø”ù”ú”û”ü•@•A•B•C•D•E•F•G•H•I•J•K•L•M•N•O•P•Q'
	.dc.b	'•R•S•T•U•V•W•X•Y•Z•[•\•]•^•_•`•a•b•c•d•e•f•g•h•i•j•k•l•m•n•o•p•q'
	.dc.b	'•r•s•t•u•v•w•x•y•z•{•|•}•~•€••‚•ƒ•„•…•†•‡•ˆ•‰•Š•‹•Œ••Ž•••‘•’'
	.dc.b	'•“•”•••–•—•˜•™•š•›•œ••ž•Ÿ• •¡•¢•£•¤•¥•¦•§•¨•©•ª•«•¬•­•®•¯•°•±•²'
	.dc.b	'•³•´•µ•¶•·•¸•¹•º•»•¼•½•¾•¿•À•Á•Â•Ã•Ä•Å•Æ•Ç•È•É•Ê•Ë•Ì•Í•Î•Ï•Ð•Ñ•Ò'
	.dc.b	'•Ó•Ô•Õ•Ö•×•Ø•Ù•Ú•Û•Ü•Ý•Þ•ß•à•á•â•ã•ä•å•æ•ç•è•é•ê•ë•ì•í•î•ï•ð•ñ•ò'
	.dc.b	'•ó•ô•õ•ö•÷•ø•ù•ú•û•ü–@–A–B–C–D–E–F–G–H–I–J–K–L–M–N–O–P–Q–R–S–T–U'
	.dc.b	'–V–W–X–Y–Z–[–\–]–^–_–`–a–b–c–d–e–f–g–h–i–j–k–l–m–n–o–p–q–r–s–t–u'
	.dc.b	'–v–w–x–y–z–{–|–}–~–€––‚–ƒ–„–…–†–‡–ˆ–‰–Š–‹–Œ––Ž–––‘–’–“–”–•––'
	.dc.b	'–—–˜–™–š–›–œ––ž–Ÿ– –¡–¢–£–¤–¥–¦–§–¨–©–ª–«–¬–­–®–¯–°–±–²–³–´–µ–¶'
	.dc.b	'–·–¸–¹–º–»–¼–½–¾–¿–À–Á–Â–Ã–Ä–Å–Æ–Ç–È–É–Ê–Ë–Ì–Í–Î–Ï–Ð–Ñ–Ò–Ó–Ô–Õ–Ö'
	.dc.b	'–×–Ø–Ù–Ú–Û–Ü–Ý–Þ–ß–à–á–â–ã–ä–å–æ–ç–è–é–ê–ë–ì–í–î–ï–ð–ñ–ò–ó–ô–õ–ö'
	.dc.b	'–÷–ø–ù–ú–û–ü—@—A—B—C—D—E—F—G—H—I—J—K—L—M—N—O—P—Q—R—S—T—U—V—W—X—Y'
	.dc.b	'—Z—[—\—]—^—_—`—a—b—c—d—e—f—g—h—i—j—k—l—m—n—o—p—q—r—s—t—u—v—w—x—y'
	.dc.b	'—z—{—|—}—~—€——‚—ƒ—„—…—†—‡—ˆ—‰—Š—‹—Œ——Ž———‘—’—“—”—•—–———˜—™—š'
	.dc.b	'—›—œ——ž—Ÿ— —¡—¢—£—¤—¥—¦—§—¨—©—ª—«—¬—­—®—¯—°—±—²—³—´—µ—¶—·—¸—¹—º'
	.dc.b	'—»—¼—½—¾—¿—À—Á—Â—Ã—Ä—Å—Æ—Ç—È—É—Ê—Ë—Ì—Í—Î—Ï—Ð—Ñ—Ò—Ó—Ô—Õ—Ö—×—Ø—Ù—Ú'
	.dc.b	'—Û—Ü—Ý—Þ—ß—à—á—â—ã—ä—å—æ—ç—è—é—ê—ë—ì—í—î—ï—ð—ñ—ò—ó—ô—õ—ö—÷—ø—ù—ú'
	.dc.b	'—û—ü˜@˜A˜B˜C˜D˜E˜F˜G˜H˜I˜J˜K˜L˜M˜N˜O˜P˜Q˜R˜S˜T˜U˜V˜W˜X˜Y˜Z˜[˜\˜]'
	.dc.b	'˜^˜_˜`˜a˜b˜c˜d˜e˜f˜g˜h˜i˜j˜k˜l˜m˜n˜o˜p˜q˜r˜Ÿ˜ ˜¡˜¢˜£˜¤˜¥˜¦˜§˜¨˜©'
	.dc.b	'˜ª˜«˜¬˜­˜®˜¯˜°˜±˜²˜³˜´˜µ˜¶˜·˜¸˜¹˜º˜»˜¼˜½˜¾˜¿˜À˜Á˜Â˜Ã˜Ä˜Å˜Æ˜Ç˜È˜É'
	.dc.b	'˜Ê˜Ë˜Ì˜Í˜Î˜Ï˜Ð˜Ñ˜Ò˜Ó˜Ô˜Õ˜Ö˜×˜Ø˜Ù˜Ú˜Û˜Ü˜Ý˜Þ˜ß˜à˜á˜â˜ã˜ä˜å˜æ˜ç˜è˜é'
	.dc.b	'˜ê˜ë˜ì˜í˜î˜ï˜ð˜ñ˜ò˜ó˜ô˜õ˜ö˜÷˜ø˜ù˜ú˜û˜ü™@™A™B™C™D™E™F™G™H™I™J™K™L'
	.dc.b	'™M™N™O™P™Q™R™S™T™U™V™W™X™Y™Z™[™\™]™^™_™`™a™b™c™d™e™f™g™h™i™j™k™l'
	.dc.b	'™m™n™o™p™q™r™s™t™u™v™w™x™y™z™{™|™}™~™€™™‚™ƒ™„™…™†™‡™ˆ™‰™Š™‹™Œ™'
	.dc.b	'™Ž™™™‘™’™“™”™•™–™—™˜™™™š™›™œ™™ž™Ÿ™ ™¡™¢™£™¤™¥™¦™§™¨™©™ª™«™¬™­'
	.dc.b	'™®™¯™°™±™²™³™´™µ™¶™·™¸™¹™º™»™¼™½™¾™¿™À™Á™Â™Ã™Ä™Å™Æ™Ç™È™É™Ê™Ë™Ì™Í'
	.dc.b	'™Î™Ï™Ð™Ñ™Ò™Ó™Ô™Õ™Ö™×™Ø™Ù™Ú™Û™Ü™Ý™Þ™ß™à™á™â™ã™ä™å™æ™ç™è™é™ê™ë™ì™í'
	.dc.b	'™î™ï™ð™ñ™ò™ó™ô™õ™ö™÷™ø™ù™ú™û™üš@šAšBšCšDšEšFšGšHšIšJšKšLšMšNšOšP'
	.dc.b	'šQšRšSšTšUšVšWšXšYšZš[š\š]š^š_š`šašbšcšdšešfšgšhšišjškšlšmšnšošp'
	.dc.b	'šqšršsštšušvšwšxšyšzš{š|š}š~š€šš‚šƒš„š…š†š‡šˆš‰šŠš‹šŒššŽššš‘'
	.dc.b	'š’š“š”š•š–š—š˜š™ššš›šœššžšŸš š¡š¢š£š¤š¥š¦š§š¨š©šªš«š¬š­š®š¯š°š±'
	.dc.b	'š²š³š´šµš¶š·š¸š¹šºš»š¼š½š¾š¿šÀšÁšÂšÃšÄšÅšÆšÇšÈšÉšÊšËšÌšÍšÎšÏšÐšÑ'
	.dc.b	'šÒšÓšÔšÕšÖš×šØšÙšÚšÛšÜšÝšÞšßšàšášâšãšäšåšæšçšèšéšêšëšìšíšîšïšðšñ'
	.dc.b	'šòšóšôšõšöš÷šøšùšúšûšü›@›A›B›C›D›E›F›G›H›I›J›K›L›M›N›O›P›Q›R›S›T'
	.dc.b	'›U›V›W›X›Y›Z›[›\›]›^›_›`›a›b›c›d›e›f›g›h›i›j›k›l›m›n›o›p›q›r›s›t'
	.dc.b	'›u›v›w›x›y›z›{›|›}›~›€››‚›ƒ›„›…›†›‡›ˆ›‰›Š›‹›Œ››Ž›››‘›’›“›”›•'
	.dc.b	'›–›—›˜›™›š›››œ››ž›Ÿ› ›¡›¢›£›¤›¥›¦›§›¨›©›ª›«›¬›­›®›¯›°›±›²›³›´›µ'
	.dc.b	'›¶›·›¸›¹›º›»›¼›½›¾›¿›À›Á›Â›Ã›Ä›Å›Æ›Ç›È›É›Ê›Ë›Ì›Í›Î›Ï›Ð›Ñ›Ò›Ó›Ô›Õ'
	.dc.b	'›Ö›×›Ø›Ù›Ú›Û›Ü›Ý›Þ›ß›à›á›â›ã›ä›å›æ›ç›è›é›ê›ë›ì›í›î›ï›ð›ñ›ò›ó›ô›õ'
	.dc.b	'›ö›÷›ø›ù›ú›û›üœ@œAœBœCœDœEœFœGœHœIœJœKœLœMœNœOœPœQœRœSœTœUœVœWœX'
	.dc.b	'œYœZœ[œ\œ]œ^œ_œ`œaœbœcœdœeœfœgœhœiœjœkœlœmœnœoœpœqœrœsœtœuœvœwœx'
	.dc.b	'œyœzœ{œ|œ}œ~œ€œœ‚œƒœ„œ…œ†œ‡œˆœ‰œŠœ‹œŒœœŽœœœ‘œ’œ“œ”œ•œ–œ—œ˜œ™'
	.dc.b	'œšœ›œœœœžœŸœ œ¡œ¢œ£œ¤œ¥œ¦œ§œ¨œ©œªœ«œ¬œ­œ®œ¯œ°œ±œ²œ³œ´œµœ¶œ·œ¸œ¹'
	.dc.b	'œºœ»œ¼œ½œ¾œ¿œÀœÁœÂœÃœÄœÅœÆœÇœÈœÉœÊœËœÌœÍœÎœÏœÐœÑœÒœÓœÔœÕœÖœ×œØœÙ'
	.dc.b	'œÚœÛœÜœÝœÞœßœàœáœâœãœäœåœæœçœèœéœêœëœìœíœîœïœðœñœòœóœôœõœöœ÷œøœù'
	.dc.b	'œúœûœü@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\'
	.dc.b	']^_`abcdefghijklmnopqrstuvwxyz{|'
	.dc.b	'}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œ'
	.dc.b	'žŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½'
	.dc.b	'¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝ'
	.dc.b	'Þßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüž@'
	.dc.b	'žAžBžCžDžEžFžGžHžIžJžKžLžMžNžOžPžQžRžSžTžUžVžWžXžYžZž[ž\ž]ž^ž_ž`'
	.dc.b	'žažbžcždžežfžgžhžižjžkžlžmžnžožpžqžržsžtžužvžwžxžyžzž{ž|ž}ž~ž€ž'
	.dc.b	'ž‚žƒž„ž…ž†ž‡žˆž‰žŠž‹žŒžžŽžžž‘ž’ž“ž”ž•ž–ž—ž˜ž™žšž›žœžžžžŸž ž¡'

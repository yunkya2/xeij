#========================================================================================
#  opcode.pl
#  Copyright (C) 2003-2019 Makoto Kamada
#
#  This file is part of the XEiJ (X68000 Emulator in Java).
#  You can use, modify and redistribute the XEiJ if the conditions are met.
#  Read the XEiJ License for more details.
#  https://stdkmd.net/xeij/
#========================================================================================

use strict;  #厳密な文法に従う
use warnings;  #警告を表示する
use utf8;  #UTF-8で記述する
binmode STDOUT, ':encoding(cp932)';  #標準出力はcp932(Shift_JISでは'～'(\uff5e)が使えない)
binmode STDERR, ':encoding(cp932)';  #標準エラー出力はcp932(Shift_JISでは'～'(\uff5e)が使えない)

$| = 1;



#BASEはオペコード順
#                                                                                                   111111111111111111111111111111
#         111111111122222222223333333333444444444455555555556666666666777777777788888888889999999999000000000011111111112222222222
#123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
my $BASE = <<'XXXXXXXXXX';
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ORI.B #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_000_000_mmm_rrr-{data}
ORI.B #<data>,CCR				|-|012346|-|*****|*****|          |0000_000_000_111_100-{data}
ORI.W #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_000_001_mmm_rrr-{data}
ORI.W #<data>,SR				|-|012346|P|*****|*****|          |0000_000_001_111_100-{data}
ORI.L #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_000_010_mmm_rrr-{data}
BITREV.L Dr					|-|------|-|-----|-----|D         |0000_000_011_000_rrr	(ISA_C)
CMP2.B <ea>,Rn					|-|--234S|-|-UUUU|-U*U*|  M  WXZP |0000_000_011_mmm_rrr-rnnn000000000000
CHK2.B <ea>,Rn					|-|--234S|-|-UUUU|-U*U*|  M  WXZP |0000_000_011_mmm_rrr-rnnn100000000000
BTST.L Dq,Dr					|-|012346|-|--U--|--*--|D         |0000_qqq_100_000_rrr
MOVEP.W (d16,Ar),Dq				|-|01234S|-|-----|-----|          |0000_qqq_100_001_rrr-{data}
BTST.B Dq,<ea>					|-|012346|-|--U--|--*--|  M+-WXZPI|0000_qqq_100_mmm_rrr
BCHG.L Dq,Dr					|-|012346|-|--U--|--*--|D         |0000_qqq_101_000_rrr
MOVEP.L (d16,Ar),Dq				|-|01234S|-|-----|-----|          |0000_qqq_101_001_rrr-{data}
BCHG.B Dq,<ea>					|-|012346|-|--U--|--*--|  M+-WXZ  |0000_qqq_101_mmm_rrr
BCLR.L Dq,Dr					|-|012346|-|--U--|--*--|D         |0000_qqq_110_000_rrr
MOVEP.W Dq,(d16,Ar)				|-|01234S|-|-----|-----|          |0000_qqq_110_001_rrr-{data}
BCLR.B Dq,<ea>					|-|012346|-|--U--|--*--|  M+-WXZ  |0000_qqq_110_mmm_rrr
BSET.L Dq,Dr					|-|012346|-|--U--|--*--|D         |0000_qqq_111_000_rrr
MOVEP.L Dq,(d16,Ar)				|-|01234S|-|-----|-----|          |0000_qqq_111_001_rrr-{data}
BSET.B Dq,<ea>					|-|012346|-|--U--|--*--|  M+-WXZ  |0000_qqq_111_mmm_rrr
ANDI.B #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_001_000_mmm_rrr-{data}
ANDI.B #<data>,CCR				|-|012346|-|*****|*****|          |0000_001_000_111_100-{data}
ANDI.W #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_001_001_mmm_rrr-{data}
ANDI.W #<data>,SR				|-|012346|P|*****|*****|          |0000_001_001_111_100-{data}
ANDI.L #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_001_010_mmm_rrr-{data}
BYTEREV.L Dr					|-|------|-|-----|-----|D         |0000_001_011_000_rrr	(ISA_C)
CMP2.W <ea>,Rn					|-|--234S|-|-UUUU|-U*U*|  M  WXZP |0000_001_011_mmm_rrr-rnnn000000000000
CHK2.W <ea>,Rn					|-|--234S|-|-UUUU|-U*U*|  M  WXZP |0000_001_011_mmm_rrr-rnnn100000000000
SUBI.B #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0000_010_000_mmm_rrr-{data}
SUBI.W #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0000_010_001_mmm_rrr-{data}
SUBI.L #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0000_010_010_mmm_rrr-{data}
FF1.L Dr					|-|------|-|-UUUU|-**00|D         |0000_010_011_000_rrr	(ISA_C)
CMP2.L <ea>,Rn					|-|--234S|-|-UUUU|-U*U*|  M  WXZP |0000_010_011_mmm_rrr-rnnn000000000000
CHK2.L <ea>,Rn					|-|--234S|-|-UUUU|-U*U*|  M  WXZP |0000_010_011_mmm_rrr-rnnn100000000000
ADDI.B #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0000_011_000_mmm_rrr-{data}
ADDI.W #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0000_011_001_mmm_rrr-{data}
ADDI.L #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0000_011_010_mmm_rrr-{data}
RTM Rn						|-|--2---|-|UUUUU|*****|          |0000_011_011_00n_nnn
CALLM #<data>,<ea>				|-|--2---|-|-----|-----|  M  WXZP |0000_011_011_mmm_rrr-00000000dddddddd
BTST.L #<data>,Dr				|-|012346|-|--U--|--*--|D         |0000_100_000_000_rrr-{data}
BTST.B #<data>,<ea>				|-|012346|-|--U--|--*--|  M+-WXZP |0000_100_000_mmm_rrr-{data}
BCHG.L #<data>,Dr				|-|012346|-|--U--|--*--|D         |0000_100_001_000_rrr-{data}
BCHG.B #<data>,<ea>				|-|012346|-|--U--|--*--|  M+-WXZ  |0000_100_001_mmm_rrr-{data}
BCLR.L #<data>,Dr				|-|012346|-|--U--|--*--|D         |0000_100_010_000_rrr-{data}
BCLR.B #<data>,<ea>				|-|012346|-|--U--|--*--|  M+-WXZ  |0000_100_010_mmm_rrr-{data}
BSET.L #<data>,Dr				|-|012346|-|--U--|--*--|D         |0000_100_011_000_rrr-{data}
BSET.B #<data>,<ea>				|-|012346|-|--U--|--*--|  M+-WXZ  |0000_100_011_mmm_rrr-{data}
EORI.B #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_101_000_mmm_rrr-{data}
EORI.B #<data>,CCR				|-|012346|-|*****|*****|          |0000_101_000_111_100-{data}
EORI.W #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_101_001_mmm_rrr-{data}
EORI.W #<data>,SR				|-|012346|P|*****|*****|          |0000_101_001_111_100-{data}
EORI.L #<data>,<ea>				|-|012346|-|-UUUU|-**00|D M+-WXZ  |0000_101_010_mmm_rrr-{data}
CAS.B Dc,Du,<ea>				|-|--2346|-|-UUUU|-****|  M+-WXZ  |0000_101_011_mmm_rrr-0000000uuu000ccc
CMPI.B #<data>,<ea>				|-|01----|-|-UUUU|-****|D M+-WXZ  |0000_110_000_mmm_rrr-{data}
CMPI.B #<data>,<ea>				|-|--2346|-|-UUUU|-****|D M+-WXZP |0000_110_000_mmm_rrr-{data}
CMPI.W #<data>,<ea>				|-|01----|-|-UUUU|-****|D M+-WXZ  |0000_110_001_mmm_rrr-{data}
CMPI.W #<data>,<ea>				|-|--2346|-|-UUUU|-****|D M+-WXZP |0000_110_001_mmm_rrr-{data}
CMPI.L #<data>,<ea>				|-|01----|-|-UUUU|-****|D M+-WXZ  |0000_110_010_mmm_rrr-{data}
CMPI.L #<data>,<ea>				|-|--2346|-|-UUUU|-****|D M+-WXZP |0000_110_010_mmm_rrr-{data}
CAS.W Dc,Du,<ea>				|-|--2346|-|-UUUU|-****|  M+-WXZ  |0000_110_011_mmm_rrr-0000000uuu000ccc	(68060 software emulate misaligned <ea>)
CAS2.W Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)		|-|--234S|-|-UUUU|-****|          |0000_110_011_111_100-rnnn000uuu000ccc(1)-rnnn_000_uuu_000_ccc(2)
MOVES.B <ea>,Rn					|-|-12346|P|-----|-----|  M+-WXZ  |0000_111_000_mmm_rrr-rnnn000000000000
MOVES.B Rn,<ea>					|-|-12346|P|-----|-----|  M+-WXZ  |0000_111_000_mmm_rrr-rnnn100000000000
MOVES.W <ea>,Rn					|-|-12346|P|-----|-----|  M+-WXZ  |0000_111_001_mmm_rrr-rnnn000000000000
MOVES.W Rn,<ea>					|-|-12346|P|-----|-----|  M+-WXZ  |0000_111_001_mmm_rrr-rnnn100000000000
MOVES.L <ea>,Rn					|-|-12346|P|-----|-----|  M+-WXZ  |0000_111_010_mmm_rrr-rnnn000000000000
MOVES.L Rn,<ea>					|-|-12346|P|-----|-----|  M+-WXZ  |0000_111_010_mmm_rrr-rnnn100000000000
CAS.L Dc,Du,<ea>				|-|--2346|-|-UUUU|-****|  M+-WXZ  |0000_111_011_mmm_rrr-0000000uuu000ccc	(68060 software emulate misaligned <ea>)
CAS2.L Dc1:Dc2,Du1:Du2,(Rn1):(Rn2)		|-|--234S|-|-UUUU|-****|          |0000_111_011_111_100-rnnn000uuu000ccc(1)-rnnn_000_uuu_000_ccc(2)
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
MOVE.B <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_qqq_000_mmm_rrr
MOVE.B <ea>,(Aq)				|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_qqq_010_mmm_rrr
MOVE.B <ea>,(Aq)+				|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_qqq_011_mmm_rrr
MOVE.B <ea>,-(Aq)				|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_qqq_100_mmm_rrr
MOVE.B <ea>,(d16,Aq)				|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_qqq_101_mmm_rrr
MOVE.B <ea>,(d8,Aq,Rn.wl)			|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_qqq_110_mmm_rrr
MOVE.B <ea>,(xxx).W				|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_000_111_mmm_rrr
MOVE.B <ea>,(xxx).L				|-|012346|-|-UUUU|-**00|D M+-WXZPI|0001_001_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
MOVE.L <ea>,Dq					|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_qqq_000_mmm_rrr
MOVEA.L <ea>,Aq					|-|012346|-|-----|-----|DAM+-WXZPI|0010_qqq_001_mmm_rrr
MOVE.L <ea>,(Aq)				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_qqq_010_mmm_rrr
MOVE.L <ea>,(Aq)+				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_qqq_011_mmm_rrr
MOVE.L <ea>,-(Aq)				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_qqq_100_mmm_rrr
MOVE.L <ea>,(d16,Aq)				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_qqq_101_mmm_rrr
MOVE.L <ea>,(d8,Aq,Rn.wl)			|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_qqq_110_mmm_rrr
MOVE.L <ea>,(xxx).W				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_000_111_mmm_rrr
MOVE.L <ea>,(xxx).L				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0010_001_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
MOVE.W <ea>,Dq					|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_qqq_000_mmm_rrr
MOVEA.W <ea>,Aq					|-|012346|-|-----|-----|DAM+-WXZPI|0011_qqq_001_mmm_rrr
MOVE.W <ea>,(Aq)				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_qqq_010_mmm_rrr
MOVE.W <ea>,(Aq)+				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_qqq_011_mmm_rrr
MOVE.W <ea>,-(Aq)				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_qqq_100_mmm_rrr
MOVE.W <ea>,(d16,Aq)				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_qqq_101_mmm_rrr
MOVE.W <ea>,(d8,Aq,Rn.wl)			|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_qqq_110_mmm_rrr
MOVE.W <ea>,(xxx).W				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_000_111_mmm_rrr
MOVE.W <ea>,(xxx).L				|-|012346|-|-UUUU|-**00|DAM+-WXZPI|0011_001_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
NEGX.B <ea>					|-|012346|-|*UUUU|*****|D M+-WXZ  |0100_000_000_mmm_rrr
NEGX.W <ea>					|-|012346|-|*UUUU|*****|D M+-WXZ  |0100_000_001_mmm_rrr
NEGX.L <ea>					|-|012346|-|*UUUU|*****|D M+-WXZ  |0100_000_010_mmm_rrr
MOVE.W SR,<ea>					|-|0-----|-|*****|-----|D M+-WXZ  |0100_000_011_mmm_rrr	(68000 and 68008 read before move)
MOVE.W SR,<ea>					|-|-12346|P|*****|-----|D M+-WXZ  |0100_000_011_mmm_rrr
CHK.L <ea>,Dq					|-|--2346|-|-UUUU|-*UUU|D M+-WXZPI|0100_qqq_100_mmm_rrr
CHK.W <ea>,Dq					|-|012346|-|-UUUU|-*UUU|D M+-WXZPI|0100_qqq_110_mmm_rrr
LEA.L <ea>,Aq					|-|012346|-|-----|-----|  M  WXZP |0100_qqq_111_mmm_rrr
CLR.B <ea>					|-|012346|-|-UUUU|-0100|D M+-WXZ  |0100_001_000_mmm_rrr	(68000 and 68008 read before clear)
CLR.W <ea>					|-|012346|-|-UUUU|-0100|D M+-WXZ  |0100_001_001_mmm_rrr	(68000 and 68008 read before clear)
CLR.L <ea>					|-|012346|-|-UUUU|-0100|D M+-WXZ  |0100_001_010_mmm_rrr	(68000 and 68008 read before clear)
MOVE.W CCR,<ea>					|-|-12346|-|*****|-----|D M+-WXZ  |0100_001_011_mmm_rrr
NEG.B <ea>					|-|012346|-|UUUUU|*****|D M+-WXZ  |0100_010_000_mmm_rrr
NEG.W <ea>					|-|012346|-|UUUUU|*****|D M+-WXZ  |0100_010_001_mmm_rrr
NEG.L <ea>					|-|012346|-|UUUUU|*****|D M+-WXZ  |0100_010_010_mmm_rrr
MOVE.W <ea>,CCR					|-|012346|-|UUUUU|*****|D M+-WXZPI|0100_010_011_mmm_rrr
NOT.B <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_011_000_mmm_rrr
NOT.W <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_011_001_mmm_rrr
NOT.L <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_011_010_mmm_rrr
MOVE.W <ea>,SR					|-|012346|P|UUUUU|*****|D M+-WXZPI|0100_011_011_mmm_rrr
NBCD.B <ea>					|-|012346|-|UUUUU|*U*U*|D M+-WXZ  |0100_100_000_mmm_rrr
LINK.L Ar,#<data>				|-|--2346|-|-----|-----|          |0100_100_000_001_rrr-{data}
SWAP.W Dr					|-|012346|-|-UUUU|-**00|D         |0100_100_001_000_rrr
BKPT #<data>					|-|-12346|-|-----|-----|          |0100_100_001_001_ddd
PEA.L <ea>					|-|012346|-|-----|-----|  M  WXZP |0100_100_001_mmm_rrr
EXT.W Dr					|-|012346|-|-UUUU|-**00|D         |0100_100_010_000_rrr
MOVEM.W <list>,<ea>				|-|012346|-|-----|-----|  M -WXZ  |0100_100_010_mmm_rrr-llllllllllllllll
EXT.L Dr					|-|012346|-|-UUUU|-**00|D         |0100_100_011_000_rrr
MOVEM.L <list>,<ea>				|-|012346|-|-----|-----|  M -WXZ  |0100_100_011_mmm_rrr-llllllllllllllll
EXTB.L Dr					|-|--2346|-|-UUUU|-**00|D         |0100_100_111_000_rrr
TST.B <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_101_000_mmm_rrr
TST.B <ea>					|-|--2346|-|-UUUU|-**00|        PI|0100_101_000_mmm_rrr
TST.W <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_101_001_mmm_rrr
TST.W <ea>					|-|--2346|-|-UUUU|-**00| A      PI|0100_101_001_mmm_rrr
TST.L <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_101_010_mmm_rrr
TST.L <ea>					|-|--2346|-|-UUUU|-**00| A      PI|0100_101_010_mmm_rrr
TAS.B <ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |0100_101_011_mmm_rrr
ILLEGAL						|-|012346|-|-----|-----|          |0100_101_011_111_100
MULU.L <ea>,Dl					|-|--2346|-|-UUUU|-***0|D M+-WXZPI|0100_110_000_mmm_rrr-0lll000000000hhh	(h is not used)
MULU.L <ea>,Dh:Dl				|-|--234S|-|-UUUU|-***0|D M+-WXZPI|0100_110_000_mmm_rrr-0lll010000000hhh	(if h=l then result is not defined)
MULS.L <ea>,Dl					|-|--2346|-|-UUUU|-***0|D M+-WXZPI|0100_110_000_mmm_rrr-0lll100000000hhh	(h is not used)
MULS.L <ea>,Dh:Dl				|-|--234S|-|-UUUU|-***0|D M+-WXZPI|0100_110_000_mmm_rrr-0lll110000000hhh	(if h=l then result is not defined)
DIVU.L <ea>,Dq					|-|--2346|-|-UUUU|-***0|D M+-WXZPI|0100_110_001_mmm_rrr-0qqq000000000qqq
DIVUL.L <ea>,Dr:Dq				|-|--2346|-|-UUUU|-***0|D M+-WXZPI|0100_110_001_mmm_rrr-0qqq000000000rrr	(q is not equal to r)
DIVU.L <ea>,Dr:Dq				|-|--234S|-|-UUUU|-***0|D M+-WXZPI|0100_110_001_mmm_rrr-0qqq010000000rrr	(q is not equal to r)
DIVS.L <ea>,Dq					|-|--2346|-|-UUUU|-***0|D M+-WXZPI|0100_110_001_mmm_rrr-0qqq100000000qqq
DIVSL.L <ea>,Dr:Dq				|-|--2346|-|-UUUU|-***0|D M+-WXZPI|0100_110_001_mmm_rrr-0qqq100000000rrr	(q is not equal to r)
DIVS.L <ea>,Dr:Dq				|-|--234S|-|-UUUU|-***0|D M+-WXZPI|0100_110_001_mmm_rrr-0qqq110000000rrr	(q is not equal to r)
SATS.L Dr					|-|------|-|-UUUU|-**00|D         |0100_110_010_000_rrr	(ISA_B)
MOVEM.W <ea>,<list>				|-|012346|-|-----|-----|  M+ WXZP |0100_110_010_mmm_rrr-llllllllllllllll
MOVEM.L <ea>,<list>				|-|012346|-|-----|-----|  M+ WXZP |0100_110_011_mmm_rrr-llllllllllllllll
TRAP #<vector>					|-|012346|-|-----|-----|          |0100_111_001_00v_vvv
LINK.W Ar,#<data>				|-|012346|-|-----|-----|          |0100_111_001_010_rrr-{data}
UNLK Ar						|-|012346|-|-----|-----|          |0100_111_001_011_rrr
MOVE.L Ar,USP					|-|012346|P|-----|-----|          |0100_111_001_100_rrr
MOVE.L USP,Ar					|-|012346|P|-----|-----|          |0100_111_001_101_rrr
RESET						|-|012346|P|-----|-----|          |0100_111_001_110_000
NOP						|-|012346|-|-----|-----|          |0100_111_001_110_001
STOP #<data>					|-|012346|P|UUUUU|*****|          |0100_111_001_110_010-{data}
RTE						|-|012346|P|UUUUU|*****|          |0100_111_001_110_011
RTD #<data>					|-|-12346|-|-----|-----|          |0100_111_001_110_100-{data}
RTS						|-|012346|-|-----|-----|          |0100_111_001_110_101
TRAPV						|-|012346|-|---*-|-----|          |0100_111_001_110_110
RTR						|-|012346|-|UUUUU|*****|          |0100_111_001_110_111
MOVEC.L Rc,Rn					|-|-12346|P|-----|-----|          |0100_111_001_111_010-rnnncccccccccccc
MOVEC.L Rn,Rc					|-|-12346|P|-----|-----|          |0100_111_001_111_011-rnnncccccccccccc
JSR <ea>					|-|012346|-|-----|-----|  M  WXZP |0100_111_010_mmm_rrr
JMP <ea>					|-|012346|-|-----|-----|  M  WXZP |0100_111_011_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ADDQ.B #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0101_qqq_000_mmm_rrr
ADDQ.W #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0101_qqq_001_mmm_rrr
ADDQ.W #<data>,Ar				|-|012346|-|-----|-----| A        |0101_qqq_001_001_rrr
ADDQ.L #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0101_qqq_010_mmm_rrr
ADDQ.L #<data>,Ar				|-|012346|-|-----|-----| A        |0101_qqq_010_001_rrr
ST.B <ea>					|-|012346|-|-----|-----|D M+-WXZ  |0101_000_011_mmm_rrr
DBT.W Dr,<label>				|-|012346|-|-----|-----|          |0101_000_011_001_rrr-{offset}
TRAPT.W #<data>					|-|--2346|-|-----|-----|          |0101_000_011_111_010-{data}
TRAPT.L #<data>					|-|--2346|-|-----|-----|          |0101_000_011_111_011-{data}
TRAPT						|-|--2346|-|-----|-----|          |0101_000_011_111_100
SUBQ.B #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0101_qqq_100_mmm_rrr
SUBQ.W #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0101_qqq_101_mmm_rrr
SUBQ.W #<data>,Ar				|-|012346|-|-----|-----| A        |0101_qqq_101_001_rrr
SUBQ.L #<data>,<ea>				|-|012346|-|UUUUU|*****|D M+-WXZ  |0101_qqq_110_mmm_rrr
SUBQ.L #<data>,Ar				|-|012346|-|-----|-----| A        |0101_qqq_110_001_rrr
SF.B <ea>					|-|012346|-|-----|-----|D M+-WXZ  |0101_000_111_mmm_rrr
DBF.W Dr,<label>				|-|012346|-|-----|-----|          |0101_000_111_001_rrr-{offset}
TRAPF.W #<data>					|-|--2346|-|-----|-----|          |0101_000_111_111_010-{data}
TRAPF.L #<data>					|-|--2346|-|-----|-----|          |0101_000_111_111_011-{data}
TRAPF						|-|--2346|-|-----|-----|          |0101_000_111_111_100
SHI.B <ea>					|-|012346|-|--*-*|-----|D M+-WXZ  |0101_001_011_mmm_rrr
DBHI.W Dr,<label>				|-|012346|-|--*-*|-----|          |0101_001_011_001_rrr-{offset}
TRAPHI.W #<data>				|-|--2346|-|--*-*|-----|          |0101_001_011_111_010-{data}
TRAPHI.L #<data>				|-|--2346|-|--*-*|-----|          |0101_001_011_111_011-{data}
TRAPHI						|-|--2346|-|--*-*|-----|          |0101_001_011_111_100
SLS.B <ea>					|-|012346|-|--*-*|-----|D M+-WXZ  |0101_001_111_mmm_rrr
DBLS.W Dr,<label>				|-|012346|-|--*-*|-----|          |0101_001_111_001_rrr-{offset}
TRAPLS.W #<data>				|-|--2346|-|--*-*|-----|          |0101_001_111_111_010-{data}
TRAPLS.L #<data>				|-|--2346|-|--*-*|-----|          |0101_001_111_111_011-{data}
TRAPLS						|-|--2346|-|--*-*|-----|          |0101_001_111_111_100
SCC.B <ea>					|-|012346|-|----*|-----|D M+-WXZ  |0101_010_011_mmm_rrr
DBCC.W Dr,<label>				|-|012346|-|----*|-----|          |0101_010_011_001_rrr-{offset}
TRAPCC.W #<data>				|-|--2346|-|----*|-----|          |0101_010_011_111_010-{data}
TRAPCC.L #<data>				|-|--2346|-|----*|-----|          |0101_010_011_111_011-{data}
TRAPCC						|-|--2346|-|----*|-----|          |0101_010_011_111_100
SCS.B <ea>					|-|012346|-|----*|-----|D M+-WXZ  |0101_010_111_mmm_rrr
DBCS.W Dr,<label>				|-|012346|-|----*|-----|          |0101_010_111_001_rrr-{offset}
TRAPCS.W #<data>				|-|--2346|-|----*|-----|          |0101_010_111_111_010-{data}
TRAPCS.L #<data>				|-|--2346|-|----*|-----|          |0101_010_111_111_011-{data}
TRAPCS						|-|--2346|-|----*|-----|          |0101_010_111_111_100
SNE.B <ea>					|-|012346|-|--*--|-----|D M+-WXZ  |0101_011_011_mmm_rrr
DBNE.W Dr,<label>				|-|012346|-|--*--|-----|          |0101_011_011_001_rrr-{offset}
TRAPNE.W #<data>				|-|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}
TRAPNE.L #<data>				|-|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}
TRAPNE						|-|--2346|-|--*--|-----|          |0101_011_011_111_100
SEQ.B <ea>					|-|012346|-|--*--|-----|D M+-WXZ  |0101_011_111_mmm_rrr
DBEQ.W Dr,<label>				|-|012346|-|--*--|-----|          |0101_011_111_001_rrr-{offset}
TRAPEQ.W #<data>				|-|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}
TRAPEQ.L #<data>				|-|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}
TRAPEQ						|-|--2346|-|--*--|-----|          |0101_011_111_111_100
SVC.B <ea>					|-|012346|-|---*-|-----|D M+-WXZ  |0101_100_011_mmm_rrr
DBVC.W Dr,<label>				|-|012346|-|---*-|-----|          |0101_100_011_001_rrr-{offset}
TRAPVC.W #<data>				|-|--2346|-|---*-|-----|          |0101_100_011_111_010-{data}
TRAPVC.L #<data>				|-|--2346|-|---*-|-----|          |0101_100_011_111_011-{data}
TRAPVC						|-|--2346|-|---*-|-----|          |0101_100_011_111_100
SVS.B <ea>					|-|012346|-|---*-|-----|D M+-WXZ  |0101_100_111_mmm_rrr
DBVS.W Dr,<label>				|-|012346|-|---*-|-----|          |0101_100_111_001_rrr-{offset}
TRAPVS.W #<data>				|-|--2346|-|---*-|-----|          |0101_100_111_111_010-{data}
TRAPVS.L #<data>				|-|--2346|-|---*-|-----|          |0101_100_111_111_011-{data}
TRAPVS						|-|--2346|-|---*-|-----|          |0101_100_111_111_100
SPL.B <ea>					|-|012346|-|-*---|-----|D M+-WXZ  |0101_101_011_mmm_rrr
DBPL.W Dr,<label>				|-|012346|-|-*---|-----|          |0101_101_011_001_rrr-{offset}
TRAPPL.W #<data>				|-|--2346|-|-*---|-----|          |0101_101_011_111_010-{data}
TRAPPL.L #<data>				|-|--2346|-|-*---|-----|          |0101_101_011_111_011-{data}
TRAPPL						|-|--2346|-|-*---|-----|          |0101_101_011_111_100
SMI.B <ea>					|-|012346|-|-*---|-----|D M+-WXZ  |0101_101_111_mmm_rrr
DBMI.W Dr,<label>				|-|012346|-|-*---|-----|          |0101_101_111_001_rrr-{offset}
TRAPMI.W #<data>				|-|--2346|-|-*---|-----|          |0101_101_111_111_010-{data}
TRAPMI.L #<data>				|-|--2346|-|-*---|-----|          |0101_101_111_111_011-{data}
TRAPMI						|-|--2346|-|-*---|-----|          |0101_101_111_111_100
SGE.B <ea>					|-|012346|-|-*-*-|-----|D M+-WXZ  |0101_110_011_mmm_rrr
DBGE.W Dr,<label>				|-|012346|-|-*-*-|-----|          |0101_110_011_001_rrr-{offset}
TRAPGE.W #<data>				|-|--2346|-|-*-*-|-----|          |0101_110_011_111_010-{data}
TRAPGE.L #<data>				|-|--2346|-|-*-*-|-----|          |0101_110_011_111_011-{data}
TRAPGE						|-|--2346|-|-*-*-|-----|          |0101_110_011_111_100
SLT.B <ea>					|-|012346|-|-*-*-|-----|D M+-WXZ  |0101_110_111_mmm_rrr
DBLT.W Dr,<label>				|-|012346|-|-*-*-|-----|          |0101_110_111_001_rrr-{offset}
TRAPLT.W #<data>				|-|--2346|-|-*-*-|-----|          |0101_110_111_111_010-{data}
TRAPLT.L #<data>				|-|--2346|-|-*-*-|-----|          |0101_110_111_111_011-{data}
TRAPLT						|-|--2346|-|-*-*-|-----|          |0101_110_111_111_100
SGT.B <ea>					|-|012346|-|-***-|-----|D M+-WXZ  |0101_111_011_mmm_rrr
DBGT.W Dr,<label>				|-|012346|-|-***-|-----|          |0101_111_011_001_rrr-{offset}
TRAPGT.W #<data>				|-|--2346|-|-***-|-----|          |0101_111_011_111_010-{data}
TRAPGT.L #<data>				|-|--2346|-|-***-|-----|          |0101_111_011_111_011-{data}
TRAPGT						|-|--2346|-|-***-|-----|          |0101_111_011_111_100
SLE.B <ea>					|-|012346|-|-***-|-----|D M+-WXZ  |0101_111_111_mmm_rrr
DBLE.W Dr,<label>				|-|012346|-|-***-|-----|          |0101_111_111_001_rrr-{offset}
TRAPLE.W #<data>				|-|--2346|-|-***-|-----|          |0101_111_111_111_010-{data}
TRAPLE.L #<data>				|-|--2346|-|-***-|-----|          |0101_111_111_111_011-{data}
TRAPLE						|-|--2346|-|-***-|-----|          |0101_111_111_111_100
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
BRA.W <label>					|-|012346|-|-----|-----|          |0110_000_000_000_000-{offset}
BRA.S <label>					|-|012346|-|-----|-----|          |0110_000_000_sss_sss	(s is not equal to 0)
BRA.S <label>					|-|012346|-|-----|-----|          |0110_000_001_sss_sss
BRA.S <label>					|-|012346|-|-----|-----|          |0110_000_010_sss_sss
BRA.S <label>					|-|01----|-|-----|-----|          |0110_000_011_sss_sss
BRA.S <label>					|-|--2346|-|-----|-----|          |0110_000_011_sss_sss	(s is not equal to 63)
BRA.L <label>					|-|--2346|-|-----|-----|          |0110_000_011_111_111-{offset}
BSR.W <label>					|-|012346|-|-----|-----|          |0110_000_100_000_000-{offset}
BSR.S <label>					|-|012346|-|-----|-----|          |0110_000_100_sss_sss	(s is not equal to 0)
BSR.S <label>					|-|012346|-|-----|-----|          |0110_000_101_sss_sss
BSR.S <label>					|-|012346|-|-----|-----|          |0110_000_110_sss_sss
BSR.S <label>					|-|01----|-|-----|-----|          |0110_000_111_sss_sss
BSR.S <label>					|-|--2346|-|-----|-----|          |0110_000_111_sss_sss	(s is not equal to 63)
BSR.L <label>					|-|--2346|-|-----|-----|          |0110_000_111_111_111-{offset}
BHI.W <label>					|-|012346|-|--*-*|-----|          |0110_001_000_000_000-{offset}
BHI.S <label>					|-|012346|-|--*-*|-----|          |0110_001_000_sss_sss	(s is not equal to 0)
BHI.S <label>					|-|012346|-|--*-*|-----|          |0110_001_001_sss_sss
BHI.S <label>					|-|012346|-|--*-*|-----|          |0110_001_010_sss_sss
BHI.S <label>					|-|01----|-|--*-*|-----|          |0110_001_011_sss_sss
BHI.S <label>					|-|--2346|-|--*-*|-----|          |0110_001_011_sss_sss	(s is not equal to 63)
BHI.L <label>					|-|--2346|-|--*-*|-----|          |0110_001_011_111_111-{offset}
BLS.W <label>					|-|012346|-|--*-*|-----|          |0110_001_100_000_000-{offset}
BLS.S <label>					|-|012346|-|--*-*|-----|          |0110_001_100_sss_sss	(s is not equal to 0)
BLS.S <label>					|-|012346|-|--*-*|-----|          |0110_001_101_sss_sss
BLS.S <label>					|-|012346|-|--*-*|-----|          |0110_001_110_sss_sss
BLS.S <label>					|-|01----|-|--*-*|-----|          |0110_001_111_sss_sss
BLS.S <label>					|-|--2346|-|--*-*|-----|          |0110_001_111_sss_sss	(s is not equal to 63)
BLS.L <label>					|-|--2346|-|--*-*|-----|          |0110_001_111_111_111-{offset}
BCC.W <label>					|-|012346|-|----*|-----|          |0110_010_000_000_000-{offset}
BCC.S <label>					|-|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)
BCC.S <label>					|-|012346|-|----*|-----|          |0110_010_001_sss_sss
BCC.S <label>					|-|012346|-|----*|-----|          |0110_010_010_sss_sss
BCC.S <label>					|-|01----|-|----*|-----|          |0110_010_011_sss_sss
BCC.S <label>					|-|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)
BCC.L <label>					|-|--2346|-|----*|-----|          |0110_010_011_111_111-{offset}
BCS.W <label>					|-|012346|-|----*|-----|          |0110_010_100_000_000-{offset}
BCS.S <label>					|-|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)
BCS.S <label>					|-|012346|-|----*|-----|          |0110_010_101_sss_sss
BCS.S <label>					|-|012346|-|----*|-----|          |0110_010_110_sss_sss
BCS.S <label>					|-|01----|-|----*|-----|          |0110_010_111_sss_sss
BCS.S <label>					|-|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)
BCS.L <label>					|-|--2346|-|----*|-----|          |0110_010_111_111_111-{offset}
BNE.W <label>					|-|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}
BNE.S <label>					|-|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)
BNE.S <label>					|-|012346|-|--*--|-----|          |0110_011_001_sss_sss
BNE.S <label>					|-|012346|-|--*--|-----|          |0110_011_010_sss_sss
BNE.S <label>					|-|01----|-|--*--|-----|          |0110_011_011_sss_sss
BNE.S <label>					|-|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)
BNE.L <label>					|-|--2346|-|--*--|-----|          |0110_011_011_111_111-{offset}
BEQ.W <label>					|-|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}
BEQ.S <label>					|-|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)
BEQ.S <label>					|-|012346|-|--*--|-----|          |0110_011_101_sss_sss
BEQ.S <label>					|-|012346|-|--*--|-----|          |0110_011_110_sss_sss
BEQ.S <label>					|-|01----|-|--*--|-----|          |0110_011_111_sss_sss
BEQ.S <label>					|-|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)
BEQ.L <label>					|-|--2346|-|--*--|-----|          |0110_011_111_111_111-{offset}
BVC.W <label>					|-|012346|-|---*-|-----|          |0110_100_000_000_000-{offset}
BVC.S <label>					|-|012346|-|---*-|-----|          |0110_100_000_sss_sss	(s is not equal to 0)
BVC.S <label>					|-|012346|-|---*-|-----|          |0110_100_001_sss_sss
BVC.S <label>					|-|012346|-|---*-|-----|          |0110_100_010_sss_sss
BVC.S <label>					|-|01----|-|---*-|-----|          |0110_100_011_sss_sss
BVC.S <label>					|-|--2346|-|---*-|-----|          |0110_100_011_sss_sss	(s is not equal to 63)
BVC.L <label>					|-|--2346|-|---*-|-----|          |0110_100_011_111_111-{offset}
BVS.W <label>					|-|012346|-|---*-|-----|          |0110_100_100_000_000-{offset}
BVS.S <label>					|-|012346|-|---*-|-----|          |0110_100_100_sss_sss	(s is not equal to 0)
BVS.S <label>					|-|012346|-|---*-|-----|          |0110_100_101_sss_sss
BVS.S <label>					|-|012346|-|---*-|-----|          |0110_100_110_sss_sss
BVS.S <label>					|-|01----|-|---*-|-----|          |0110_100_111_sss_sss
BVS.S <label>					|-|--2346|-|---*-|-----|          |0110_100_111_sss_sss	(s is not equal to 63)
BVS.L <label>					|-|--2346|-|---*-|-----|          |0110_100_111_111_111-{offset}
BPL.W <label>					|-|012346|-|-*---|-----|          |0110_101_000_000_000-{offset}
BPL.S <label>					|-|012346|-|-*---|-----|          |0110_101_000_sss_sss	(s is not equal to 0)
BPL.S <label>					|-|012346|-|-*---|-----|          |0110_101_001_sss_sss
BPL.S <label>					|-|012346|-|-*---|-----|          |0110_101_010_sss_sss
BPL.S <label>					|-|01----|-|-*---|-----|          |0110_101_011_sss_sss
BPL.S <label>					|-|--2346|-|-*---|-----|          |0110_101_011_sss_sss	(s is not equal to 63)
BPL.L <label>					|-|--2346|-|-*---|-----|          |0110_101_011_111_111-{offset}
BMI.W <label>					|-|012346|-|-*---|-----|          |0110_101_100_000_000-{offset}
BMI.S <label>					|-|012346|-|-*---|-----|          |0110_101_100_sss_sss	(s is not equal to 0)
BMI.S <label>					|-|012346|-|-*---|-----|          |0110_101_101_sss_sss
BMI.S <label>					|-|012346|-|-*---|-----|          |0110_101_110_sss_sss
BMI.S <label>					|-|01----|-|-*---|-----|          |0110_101_111_sss_sss
BMI.S <label>					|-|--2346|-|-*---|-----|          |0110_101_111_sss_sss	(s is not equal to 63)
BMI.L <label>					|-|--2346|-|-*---|-----|          |0110_101_111_111_111-{offset}
BGE.W <label>					|-|012346|-|-*-*-|-----|          |0110_110_000_000_000-{offset}
BGE.S <label>					|-|012346|-|-*-*-|-----|          |0110_110_000_sss_sss	(s is not equal to 0)
BGE.S <label>					|-|012346|-|-*-*-|-----|          |0110_110_001_sss_sss
BGE.S <label>					|-|012346|-|-*-*-|-----|          |0110_110_010_sss_sss
BGE.S <label>					|-|01----|-|-*-*-|-----|          |0110_110_011_sss_sss
BGE.S <label>					|-|--2346|-|-*-*-|-----|          |0110_110_011_sss_sss	(s is not equal to 63)
BGE.L <label>					|-|--2346|-|-*-*-|-----|          |0110_110_011_111_111-{offset}
BLT.W <label>					|-|012346|-|-*-*-|-----|          |0110_110_100_000_000-{offset}
BLT.S <label>					|-|012346|-|-*-*-|-----|          |0110_110_100_sss_sss	(s is not equal to 0)
BLT.S <label>					|-|012346|-|-*-*-|-----|          |0110_110_101_sss_sss
BLT.S <label>					|-|012346|-|-*-*-|-----|          |0110_110_110_sss_sss
BLT.S <label>					|-|01----|-|-*-*-|-----|          |0110_110_111_sss_sss
BLT.S <label>					|-|--2346|-|-*-*-|-----|          |0110_110_111_sss_sss	(s is not equal to 63)
BLT.L <label>					|-|--2346|-|-*-*-|-----|          |0110_110_111_111_111-{offset}
BGT.W <label>					|-|012346|-|-***-|-----|          |0110_111_000_000_000-{offset}
BGT.S <label>					|-|012346|-|-***-|-----|          |0110_111_000_sss_sss	(s is not equal to 0)
BGT.S <label>					|-|012346|-|-***-|-----|          |0110_111_001_sss_sss
BGT.S <label>					|-|012346|-|-***-|-----|          |0110_111_010_sss_sss
BGT.S <label>					|-|01----|-|-***-|-----|          |0110_111_011_sss_sss
BGT.S <label>					|-|--2346|-|-***-|-----|          |0110_111_011_sss_sss	(s is not equal to 63)
BGT.L <label>					|-|--2346|-|-***-|-----|          |0110_111_011_111_111-{offset}
BLE.W <label>					|-|012346|-|-***-|-----|          |0110_111_100_000_000-{offset}
BLE.S <label>					|-|012346|-|-***-|-----|          |0110_111_100_sss_sss	(s is not equal to 0)
BLE.S <label>					|-|012346|-|-***-|-----|          |0110_111_101_sss_sss
BLE.S <label>					|-|012346|-|-***-|-----|          |0110_111_110_sss_sss
BLE.S <label>					|-|01----|-|-***-|-----|          |0110_111_111_sss_sss
BLE.S <label>					|-|--2346|-|-***-|-----|          |0110_111_111_sss_sss	(s is not equal to 63)
BLE.L <label>					|-|--2346|-|-***-|-----|          |0110_111_111_111_111-{offset}
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
MOVEQ.L #<data>,Dq				|-|012346|-|-UUUU|-**00|          |0111_qqq_0dd_ddd_ddd
MVS.B <ea>,Dq					|-|------|-|-UUUU|-**00|D M+-WXZPI|0111_qqq_100_mmm_rrr	(ISA_B)
MVS.W <ea>,Dq					|-|------|-|-UUUU|-**00|D M+-WXZPI|0111_qqq_101_mmm_rrr	(ISA_B)
MVZ.B <ea>,Dq					|-|------|-|-UUUU|-0*00|D M+-WXZPI|0111_qqq_110_mmm_rrr	(ISA_B)
MVZ.W <ea>,Dq					|-|------|-|-UUUU|-0*00|D M+-WXZPI|0111_qqq_111_mmm_rrr	(ISA_B)
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
OR.B <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|1000_qqq_000_mmm_rrr
OR.W <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|1000_qqq_001_mmm_rrr
OR.L <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|1000_qqq_010_mmm_rrr
DIVU.W <ea>,Dq					|-|012346|-|-UUUU|-***0|D M+-WXZPI|1000_qqq_011_mmm_rrr
SBCD.B Dr,Dq					|-|012346|-|UUUUU|*U*U*|          |1000_qqq_100_000_rrr
SBCD.B -(Ar),-(Aq)				|-|012346|-|UUUUU|*U*U*|          |1000_qqq_100_001_rrr
OR.B Dq,<ea>					|-|012346|-|-UUUU|-**00|  M+-WXZ  |1000_qqq_100_mmm_rrr
PACK Dr,Dq,#<data>				|-|--2346|-|-----|-----|          |1000_qqq_101_000_rrr-{data}
PACK -(Ar),-(Aq),#<data>			|-|--2346|-|-----|-----|          |1000_qqq_101_001_rrr-{data}
OR.W Dq,<ea>					|-|012346|-|-UUUU|-**00|  M+-WXZ  |1000_qqq_101_mmm_rrr
UNPK Dr,Dq,#<data>				|-|--2346|-|-----|-----|          |1000_qqq_110_000_rrr-{data}
UNPK -(Ar),-(Aq),#<data>			|-|--2346|-|-----|-----|          |1000_qqq_110_001_rrr-{data}
OR.L Dq,<ea>					|-|012346|-|-UUUU|-**00|  M+-WXZ  |1000_qqq_110_mmm_rrr
DIVS.W <ea>,Dq					|-|012346|-|-UUUU|-***0|D M+-WXZPI|1000_qqq_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
SUB.B <ea>,Dq					|-|012346|-|UUUUU|*****|D M+-WXZPI|1001_qqq_000_mmm_rrr
SUB.W <ea>,Dq					|-|012346|-|UUUUU|*****|DAM+-WXZPI|1001_qqq_001_mmm_rrr
SUB.L <ea>,Dq					|-|012346|-|UUUUU|*****|DAM+-WXZPI|1001_qqq_010_mmm_rrr
SUBA.W <ea>,Aq					|-|012346|-|-----|-----|DAM+-WXZPI|1001_qqq_011_mmm_rrr
SUBX.B Dr,Dq					|-|012346|-|*UUUU|*****|          |1001_qqq_100_000_rrr
SUBX.B -(Ar),-(Aq)				|-|012346|-|*UUUU|*****|          |1001_qqq_100_001_rrr
SUB.B Dq,<ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1001_qqq_100_mmm_rrr
SUBX.W Dr,Dq					|-|012346|-|*UUUU|*****|          |1001_qqq_101_000_rrr
SUBX.W -(Ar),-(Aq)				|-|012346|-|*UUUU|*****|          |1001_qqq_101_001_rrr
SUB.W Dq,<ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1001_qqq_101_mmm_rrr
SUBX.L Dr,Dq					|-|012346|-|*UUUU|*****|          |1001_qqq_110_000_rrr
SUBX.L -(Ar),-(Aq)				|-|012346|-|*UUUU|*****|          |1001_qqq_110_001_rrr
SUB.L Dq,<ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1001_qqq_110_mmm_rrr
SUBA.L <ea>,Aq					|-|012346|-|-----|-----|DAM+-WXZPI|1001_qqq_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ALINE #<data>					|-|012346|-|UUUUU|*****|          |1010_ddd_ddd_ddd_ddd (line 1010 emulator)
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
CMP.B <ea>,Dq					|-|012346|-|-UUUU|-****|D M+-WXZPI|1011_qqq_000_mmm_rrr
CMP.W <ea>,Dq					|-|012346|-|-UUUU|-****|DAM+-WXZPI|1011_qqq_001_mmm_rrr
CMP.L <ea>,Dq					|-|012346|-|-UUUU|-****|DAM+-WXZPI|1011_qqq_010_mmm_rrr
CMPA.W <ea>,Aq					|-|012346|-|-UUUU|-****|DAM+-WXZPI|1011_qqq_011_mmm_rrr
EOR.B Dq,<ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |1011_qqq_100_mmm_rrr
CMPM.B (Ar)+,(Aq)+				|-|012346|-|-UUUU|-****|          |1011_qqq_100_001_rrr
EOR.W Dq,<ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |1011_qqq_101_mmm_rrr
CMPM.W (Ar)+,(Aq)+				|-|012346|-|-UUUU|-****|          |1011_qqq_101_001_rrr
EOR.L Dq,<ea>					|-|012346|-|-UUUU|-**00|D M+-WXZ  |1011_qqq_110_mmm_rrr
CMPM.L (Ar)+,(Aq)+				|-|012346|-|-UUUU|-****|          |1011_qqq_110_001_rrr
CMPA.L <ea>,Aq					|-|012346|-|-UUUU|-****|DAM+-WXZPI|1011_qqq_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
AND.B <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|1100_qqq_000_mmm_rrr
AND.W <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|1100_qqq_001_mmm_rrr
AND.L <ea>,Dq					|-|012346|-|-UUUU|-**00|D M+-WXZPI|1100_qqq_010_mmm_rrr
MULU.W <ea>,Dq					|-|012346|-|-UUUU|-***0|D M+-WXZPI|1100_qqq_011_mmm_rrr
ABCD.B Dr,Dq					|-|012346|-|UUUUU|*U*U*|          |1100_qqq_100_000_rrr
ABCD.B -(Ar),-(Aq)				|-|012346|-|UUUUU|*U*U*|          |1100_qqq_100_001_rrr
AND.B Dq,<ea>					|-|012346|-|-UUUU|-**00|  M+-WXZ  |1100_qqq_100_mmm_rrr
EXG.L Dq,Dr					|-|012346|-|-----|-----|          |1100_qqq_101_000_rrr
EXG.L Aq,Ar					|-|012346|-|-----|-----|          |1100_qqq_101_001_rrr
AND.W Dq,<ea>					|-|012346|-|-UUUU|-**00|  M+-WXZ  |1100_qqq_101_mmm_rrr
EXG.L Dq,Ar					|-|012346|-|-----|-----|          |1100_qqq_110_001_rrr
AND.L Dq,<ea>					|-|012346|-|-UUUU|-**00|  M+-WXZ  |1100_qqq_110_mmm_rrr
MULS.W <ea>,Dq					|-|012346|-|-UUUU|-***0|D M+-WXZPI|1100_qqq_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ADD.B <ea>,Dq					|-|012346|-|UUUUU|*****|D M+-WXZPI|1101_qqq_000_mmm_rrr
ADD.W <ea>,Dq					|-|012346|-|UUUUU|*****|DAM+-WXZPI|1101_qqq_001_mmm_rrr
ADD.L <ea>,Dq					|-|012346|-|UUUUU|*****|DAM+-WXZPI|1101_qqq_010_mmm_rrr
ADDA.W <ea>,Aq					|-|012346|-|-----|-----|DAM+-WXZPI|1101_qqq_011_mmm_rrr
ADDX.B Dr,Dq					|-|012346|-|*UUUU|*****|          |1101_qqq_100_000_rrr
ADDX.B -(Ar),-(Aq)				|-|012346|-|*UUUU|*****|          |1101_qqq_100_001_rrr
ADD.B Dq,<ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1101_qqq_100_mmm_rrr
ADDX.W Dr,Dq					|-|012346|-|*UUUU|*****|          |1101_qqq_101_000_rrr
ADDX.W -(Ar),-(Aq)				|-|012346|-|*UUUU|*****|          |1101_qqq_101_001_rrr
ADD.W Dq,<ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1101_qqq_101_mmm_rrr
ADDX.L Dr,Dq					|-|012346|-|*UUUU|*****|          |1101_qqq_110_000_rrr
ADDX.L -(Ar),-(Aq)				|-|012346|-|*UUUU|*****|          |1101_qqq_110_001_rrr
ADD.L Dq,<ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1101_qqq_110_mmm_rrr
ADDA.L <ea>,Aq					|-|012346|-|-----|-----|DAM+-WXZPI|1101_qqq_111_mmm_rrr
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ASR.B #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_000_000_rrr
LSR.B #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_000_001_rrr
ROXR.B #<data>,Dr				|-|012346|-|*UUUU|***0*|          |1110_qqq_000_010_rrr
ROR.B #<data>,Dr				|-|012346|-|-UUUU|-**0*|          |1110_qqq_000_011_rrr
ASR.B Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_000_100_rrr
LSR.B Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_000_101_rrr
ROXR.B Dq,Dr					|-|012346|-|*UUUU|***0*|          |1110_qqq_000_110_rrr
ROR.B Dq,Dr					|-|012346|-|-UUUU|-**0*|          |1110_qqq_000_111_rrr
ASR.W #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_001_000_rrr
LSR.W #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_001_001_rrr
ROXR.W #<data>,Dr				|-|012346|-|*UUUU|***0*|          |1110_qqq_001_010_rrr
ROR.W #<data>,Dr				|-|012346|-|-UUUU|-**0*|          |1110_qqq_001_011_rrr
ASR.W Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_001_100_rrr
LSR.W Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_001_101_rrr
ROXR.W Dq,Dr					|-|012346|-|*UUUU|***0*|          |1110_qqq_001_110_rrr
ROR.W Dq,Dr					|-|012346|-|-UUUU|-**0*|          |1110_qqq_001_111_rrr
ASR.L #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_010_000_rrr
LSR.L #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_010_001_rrr
ROXR.L #<data>,Dr				|-|012346|-|*UUUU|***0*|          |1110_qqq_010_010_rrr
ROR.L #<data>,Dr				|-|012346|-|-UUUU|-**0*|          |1110_qqq_010_011_rrr
ASR.L Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_010_100_rrr
LSR.L Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_010_101_rrr
ROXR.L Dq,Dr					|-|012346|-|*UUUU|***0*|          |1110_qqq_010_110_rrr
ROR.L Dq,Dr					|-|012346|-|-UUUU|-**0*|          |1110_qqq_010_111_rrr
ASR.W <ea>					|-|012346|-|UUUUU|***0*|  M+-WXZ  |1110_000_011_mmm_rrr
ASL.B #<data>,Dr				|-|012346|-|UUUUU|*****|          |1110_qqq_100_000_rrr
LSL.B #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_100_001_rrr
ROXL.B #<data>,Dr				|-|012346|-|*UUUU|***0*|          |1110_qqq_100_010_rrr
ROL.B #<data>,Dr				|-|012346|-|-UUUU|-**0*|          |1110_qqq_100_011_rrr
ASL.B Dq,Dr					|-|012346|-|UUUUU|*****|          |1110_qqq_100_100_rrr
LSL.B Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_100_101_rrr
ROXL.B Dq,Dr					|-|012346|-|*UUUU|***0*|          |1110_qqq_100_110_rrr
ROL.B Dq,Dr					|-|012346|-|-UUUU|-**0*|          |1110_qqq_100_111_rrr
ASL.W #<data>,Dr				|-|012346|-|UUUUU|*****|          |1110_qqq_101_000_rrr
LSL.W #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_101_001_rrr
ROXL.W #<data>,Dr				|-|012346|-|*UUUU|***0*|          |1110_qqq_101_010_rrr
ROL.W #<data>,Dr				|-|012346|-|-UUUU|-**0*|          |1110_qqq_101_011_rrr
ASL.W Dq,Dr					|-|012346|-|UUUUU|*****|          |1110_qqq_101_100_rrr
LSL.W Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_101_101_rrr
ROXL.W Dq,Dr					|-|012346|-|*UUUU|***0*|          |1110_qqq_101_110_rrr
ROL.W Dq,Dr					|-|012346|-|-UUUU|-**0*|          |1110_qqq_101_111_rrr
ASL.L #<data>,Dr				|-|012346|-|UUUUU|*****|          |1110_qqq_110_000_rrr
LSL.L #<data>,Dr				|-|012346|-|UUUUU|***0*|          |1110_qqq_110_001_rrr
ROXL.L #<data>,Dr				|-|012346|-|*UUUU|***0*|          |1110_qqq_110_010_rrr
ROL.L #<data>,Dr				|-|012346|-|-UUUU|-**0*|          |1110_qqq_110_011_rrr
ASL.L Dq,Dr					|-|012346|-|UUUUU|*****|          |1110_qqq_110_100_rrr
LSL.L Dq,Dr					|-|012346|-|UUUUU|***0*|          |1110_qqq_110_101_rrr
ROXL.L Dq,Dr					|-|012346|-|*UUUU|***0*|          |1110_qqq_110_110_rrr
ROL.L Dq,Dr					|-|012346|-|-UUUU|-**0*|          |1110_qqq_110_111_rrr
ASL.W <ea>					|-|012346|-|UUUUU|*****|  M+-WXZ  |1110_000_111_mmm_rrr
LSR.W <ea>					|-|012346|-|UUUUU|*0*0*|  M+-WXZ  |1110_001_011_mmm_rrr
LSL.W <ea>					|-|012346|-|UUUUU|***0*|  M+-WXZ  |1110_001_111_mmm_rrr
ROXR.W <ea>					|-|012346|-|*UUUU|***0*|  M+-WXZ  |1110_010_011_mmm_rrr
ROXL.W <ea>					|-|012346|-|*UUUU|***0*|  M+-WXZ  |1110_010_111_mmm_rrr
ROR.W <ea>					|-|012346|-|-UUUU|-**0*|  M+-WXZ  |1110_011_011_mmm_rrr
ROL.W <ea>					|-|012346|-|-UUUU|-**0*|  M+-WXZ  |1110_011_111_mmm_rrr
BFTST <ea>{#o:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_011_mmm_rrr-00000ooooo0wwwww
BFTST <ea>{#o:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_011_mmm_rrr-00000ooooo100www
BFTST <ea>{Do:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_011_mmm_rrr-0000100ooo0wwwww
BFTST <ea>{Do:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_011_mmm_rrr-0000100ooo100www
BFEXTU <ea>{#o:#w},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_111_mmm_rrr-0nnn0ooooo0wwwww
BFEXTU <ea>{#o:Dw},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_111_mmm_rrr-0nnn0ooooo100www
BFEXTU <ea>{Do:#w},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_111_mmm_rrr-0nnn100ooo0wwwww
BFEXTU <ea>{Do:Dw},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_100_111_mmm_rrr-0nnn100ooo100www
BFCHG <ea>{#o:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_101_011_mmm_rrr-00000ooooo0wwwww
BFCHG <ea>{#o:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_101_011_mmm_rrr-00000ooooo100www
BFCHG <ea>{Do:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_101_011_mmm_rrr-0000100ooo0wwwww
BFCHG <ea>{Do:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_101_011_mmm_rrr-0000100ooo100www
BFEXTS <ea>{#o:#w},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_101_111_mmm_rrr-0nnn0ooooo0wwwww
BFEXTS <ea>{#o:Dw},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_101_111_mmm_rrr-0nnn0ooooo100www
BFEXTS <ea>{Do:#w},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_101_111_mmm_rrr-0nnn100ooo0wwwww
BFEXTS <ea>{Do:Dw},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_101_111_mmm_rrr-0nnn100ooo100www
BFCLR <ea>{#o:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_110_011_mmm_rrr-00000ooooo0wwwww
BFCLR <ea>{#o:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_110_011_mmm_rrr-00000ooooo100www
BFCLR <ea>{Do:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_110_011_mmm_rrr-0000100ooo0wwwww
BFCLR <ea>{Do:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_110_011_mmm_rrr-0000100ooo100www
BFFFO <ea>{#o:#w},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_110_111_mmm_rrr-0nnn0ooooo0wwwww
BFFFO <ea>{#o:Dw},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_110_111_mmm_rrr-0nnn0ooooo100www
BFFFO <ea>{Do:#w},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_110_111_mmm_rrr-0nnn100ooo0wwwww
BFFFO <ea>{Do:Dw},Dn				|-|--2346|-|-UUUU|-**00|D M  WXZP |1110_110_111_mmm_rrr-0nnn100ooo100www
BFSET <ea>{#o:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_011_mmm_rrr-00000ooooo0wwwww
BFSET <ea>{#o:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_011_mmm_rrr-00000ooooo100www
BFSET <ea>{Do:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_011_mmm_rrr-0000100ooo0wwwww
BFSET <ea>{Do:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_011_mmm_rrr-0000100ooo100www
BFINS Dn,<ea>{#o:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_111_mmm_rrr-0nnn0ooooo0wwwww
BFINS Dn,<ea>{#o:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_111_mmm_rrr-0nnn0ooooo100www
BFINS Dn,<ea>{Do:#w}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_111_mmm_rrr-0nnn100ooo0wwwww
BFINS Dn,<ea>{Do:Dw}				|-|--2346|-|-UUUU|-**00|D M  WXZ  |1110_111_111_mmm_rrr-0nnn100ooo100www
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
PFLUSHA						|-|---3--|P|-----|-----|          |1111_000_000_000_000-0010010000000000
PFLUSHA						|-|--M---|P|-----|-----|          |1111_000_000_000_000-0010010000000000
PFLUSH SFC,#<mask>				|-|---3--|P|-----|-----|          |1111_000_000_000_000-00110000mmm00000
PFLUSH DFC,#<mask>				|-|---3--|P|-----|-----|          |1111_000_000_000_000-00110000mmm00001
PFLUSH Dn,#<mask>				|-|---3--|P|-----|-----|          |1111_000_000_000_000-00110000mmm01nnn
PFLUSH #<data>,#<mask>				|-|---3--|P|-----|-----|          |1111_000_000_000_000-00110000mmm10ddd
PFLUSH SFC,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011000mmmm00000
PFLUSH DFC,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011000mmmm00001
PFLUSH Dn,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011000mmmm01nnn
PFLUSH #<data>,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011000mmmm1dddd
PFLUSHS SFC,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011010mmmm00000
PFLUSHS DFC,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011010mmmm00001
PFLUSHS Dn,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011010mmmm01nnn
PFLUSHS #<data>,#<mask>				|-|--M---|P|-----|-----|          |1111_000_000_000_000-0011010mmmm1dddd
PMOVE.L TC,<ea>					|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0100001000000000
PMOVE.B CAL,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0101001000000000
PMOVE.B VAL,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0101011000000000
PMOVE.B SCC,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0101101000000000
PMOVE.W AC,<ea>					|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0101111000000000
PMOVE.W PSR,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0110001000000000
PMOVE.W PCSR,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-0110011000000000
PMOVE.W BADn,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-01110010000nnn00
PMOVE.W BACn,<ea>				|-|--M---|P|-----|-----|DAM+-WXZ  |1111_000_000_mmm_rrr-01110110000nnn00
PMOVE.L <ea>,TC					|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0100000000000000
PMOVE.B <ea>,CAL				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0101000000000000
PMOVE.B <ea>,VAL				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0101010000000000
PMOVE.B <ea>,SCC				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0101100000000000
PMOVE.W <ea>,AC					|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0101110000000000
PMOVE.W <ea>,PSR				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0110000000000000
PMOVE.W <ea>,PCSR				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-0110010000000000
PMOVE.W <ea>,BADn				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-01110000000nnn00
PMOVE.W <ea>,BACn				|-|--M---|P|-----|-----|DAM+-WXZPI|1111_000_000_mmm_rrr-01110100000nnn00
FLINE #<data>					|-|012346|-|UUUUU|UUUUU|          |1111_ddd_ddd_ddd_ddd (line 1111 emulator)
PMOVE.L <ea>,TTn				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00001n0000000000
PMOVEFD.L <ea>,TTn				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00001n0100000000
PMOVE.L TTn,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00001n1000000000
PLOADW SFC,<ea>					|-|--M3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010000000000000
PLOADW DFC,<ea>					|-|--M3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010000000000001
PLOADW Dn,<ea>					|-|--M3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010000000001nnn
PLOADW #<data>,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010000000010ddd
PLOADW #<data>,<ea>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-001000000001dddd
PLOADR SFC,<ea>					|-|--M3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010001000000000
PLOADR DFC,<ea>					|-|--M3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010001000000001
PLOADR Dn,<ea>					|-|--M3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010001000001nnn
PLOADR #<data>,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010001000010ddd
PLOADR #<data>,<ea>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-001000100001dddd
PVALID.L VAL,<ea>				|-|--M---|-|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010100000000000
PVALID.L An,<ea>				|-|--M---|-|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0010110000000nnn
PFLUSH SFC,#<mask>,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00111000mmm00000
PFLUSH DFC,#<mask>,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00111000mmm00001
PFLUSH Dn,#<mask>,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00111000mmm01nnn
PFLUSH #<data>,#<mask>,<ea>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-00111000mmm10ddd
PFLUSH SFC,#<mask>,<ea>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011100mmmm00000
PFLUSH DFC,#<mask>,<ea>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011100mmmm00001
PFLUSH Dn,#<mask>,<ea>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011100mmmm01nnn
PFLUSH #<data>,#<mask>,<ea>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011100mmmm1dddd
PFLUSHS SFC,#<mask>,<ea>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011110mmmm00000
PFLUSHS DFC,#<mask>,<ea>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011110mmmm00001
PFLUSHS Dn,#<mask>,<ea>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011110mmmm01nnn
PFLUSHS #<data>,#<mask>,<ea>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0011110mmmm1dddd
PMOVE.L <ea>,TC					|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100000000000000
PMOVEFD.L <ea>,TC				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100000100000000
PMOVE.L TC,<ea>					|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100001000000000
PMOVE.Q DRP,<ea>				|-|--M---|P|-----|-----|  M+-WXZ  |1111_000_000_mmm_rrr-0100011000000000
PMOVE.Q <ea>,SRP				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100100000000000
PMOVEFD.Q <ea>,SRP				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100100100000000
PMOVE.Q SRP,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100101000000000
PMOVE.Q SRP,<ea>				|-|--M---|P|-----|-----|  M+-WXZ  |1111_000_000_mmm_rrr-0100101000000000
PMOVE.Q <ea>,CRP				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100110000000000
PMOVEFD.Q <ea>,CRP				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100110100000000
PMOVE.Q CRP,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0100111000000000
PMOVE.Q CRP,<ea>				|-|--M---|P|-----|-----|  M+-WXZ  |1111_000_000_mmm_rrr-0100111000000000
PMOVE.W <ea>,MMUSR				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0110000000000000
PMOVE.W MMUSR,<ea>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-0110001000000000
PTESTW SFC,<ea>,#<level>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000000000
PTESTW SFC,<ea>,#<level>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000000000
PTESTW DFC,<ea>,#<level>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000000001
PTESTW DFC,<ea>,#<level>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000000001
PTESTW Dn,<ea>,#<level>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000001nnn
PTESTW Dn,<ea>,#<level>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000001nnn
PTESTW #<data>,<ea>,#<level>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll0000010ddd
PTESTW #<data>,<ea>,#<level>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll000001dddd
PTESTW SFC,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn00000
PTESTW SFC,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn00000
PTESTW DFC,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn00001
PTESTW DFC,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn00001
PTESTW Dn,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn01nnn
PTESTW Dn,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn01nnn
PTESTW #<data>,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn10ddd
PTESTW #<data>,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll01nnn1dddd
PTESTR SFC,<ea>,#<level>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000000000
PTESTR SFC,<ea>,#<level>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000000000
PTESTR DFC,<ea>,#<level>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000000001
PTESTR DFC,<ea>,#<level>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000000001
PTESTR Dn,<ea>,#<level>				|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000001nnn
PTESTR Dn,<ea>,#<level>				|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000001nnn
PTESTR #<data>,<ea>,#<level>			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll1000010ddd
PTESTR #<data>,<ea>,#<level>			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll100001dddd
PTESTR SFC,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn00000
PTESTR SFC,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn00000
PTESTR DFC,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn00001
PTESTR DFC,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn00001
PTESTR Dn,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn01nnn
PTESTR Dn,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn01nnn
PTESTR #<data>,<ea>,#<level>,An			|-|---3--|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn10ddd
PTESTR #<data>,<ea>,#<level>,An			|-|--M---|P|-----|-----|  M  WXZ  |1111_000_000_mmm_rrr-100lll11nnn1dddd
PMOVE.Q <ea>,DRP				|-|--M---|P|-----|-----|  M+-WXZPI|1111_000_000_mmm_rrr-0100010000000000
PMOVE.Q <ea>,SRP				|-|--M---|P|-----|-----|  M+-WXZPI|1111_000_000_mmm_rrr-0100100000000000
PMOVE.Q <ea>,CRP				|-|--M---|P|-----|-----|  M+-WXZPI|1111_000_000_mmm_rrr-0100110000000000
PFLUSHR <ea>					|-|--M---|P|-----|-----|  M+-WXZPI|1111_000_000_mmm_rrr-1010000000000000
PSBS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000000
PSBC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000001
PSLS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000010
PSLC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000011
PSSS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000100
PSSC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000101
PSAS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000110
PSAC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000000111
PSWS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001000
PSWC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001001
PSIS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001010
PSIC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001011
PSGS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001100
PSGC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001101
PSCS.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001110
PSCC.B <ea>					|-|--M---|P|-----|-----|D M+-WXZ  |1111_000_001_mmm_rrr-0000000000001111
PDBBS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000000-{offset}
PDBBC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000001-{offset}
PDBLS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000010-{offset}
PDBLC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000011-{offset}
PDBSS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000100-{offset}
PDBSC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000101-{offset}
PDBAS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000110-{offset}
PDBAC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000000111-{offset}
PDBWS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001000-{offset}
PDBWC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001001-{offset}
PDBIS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001010-{offset}
PDBIC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001011-{offset}
PDBGS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001100-{offset}
PDBGC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001101-{offset}
PDBCS.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001110-{offset}
PDBCC.W Dr,<label>				|-|--M---|P|-----|-----|          |1111_000_001_001_rrr-0000000000001111-{offset}
PTRAPBS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000000-{data}
PTRAPBC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000001-{data}
PTRAPLS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000010-{data}
PTRAPLC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000011-{data}
PTRAPSS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000100-{data}
PTRAPSC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000101-{data}
PTRAPAS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000110-{data}
PTRAPAC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000000111-{data}
PTRAPWS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001000-{data}
PTRAPWC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001001-{data}
PTRAPIS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001010-{data}
PTRAPIC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001011-{data}
PTRAPGS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001100-{data}
PTRAPGC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001101-{data}
PTRAPCS.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001110-{data}
PTRAPCC.W #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_010-0000000000001111-{data}
PTRAPBS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000000-{data}
PTRAPBC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000001-{data}
PTRAPLS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000010-{data}
PTRAPLC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000011-{data}
PTRAPSS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000100-{data}
PTRAPSC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000101-{data}
PTRAPAS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000110-{data}
PTRAPAC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000000111-{data}
PTRAPWS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001000-{data}
PTRAPWC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001001-{data}
PTRAPIS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001010-{data}
PTRAPIC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001011-{data}
PTRAPGS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001100-{data}
PTRAPGC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001101-{data}
PTRAPCS.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001110-{data}
PTRAPCC.L #<data>				|-|--M---|P|-----|-----|          |1111_000_001_111_011-0000000000001111-{data}
PTRAPBS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000000
PTRAPBC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000001
PTRAPLS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000010
PTRAPLC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000011
PTRAPSS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000100
PTRAPSC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000101
PTRAPAS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000110
PTRAPAC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000000111
PTRAPWS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001000
PTRAPWC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001001
PTRAPIS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001010
PTRAPIC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001011
PTRAPGS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001100
PTRAPGC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001101
PTRAPCS						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001110
PTRAPCC						|-|--M---|P|-----|-----|          |1111_000_001_111_100-0000000000001111
PBBS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_000-{offset}
PBBC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_001-{offset}
PBLS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_010-{offset}
PBLC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_011-{offset}
PBSS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_100-{offset}
PBSC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_101-{offset}
PBAS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_110-{offset}
PBAC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_000_111-{offset}
PBWS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_000-{offset}
PBWC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_001-{offset}
PBIS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_010-{offset}
PBIC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_011-{offset}
PBGS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_100-{offset}
PBGC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_101-{offset}
PBCS.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_110-{offset}
PBCC.W <label>					|-|--M---|P|-----|-----|          |1111_000_010_001_111-{offset}
PBBS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_000-{offset}
PBBC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_001-{offset}
PBLS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_010-{offset}
PBLC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_011-{offset}
PBSS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_100-{offset}
PBSC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_101-{offset}
PBAS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_110-{offset}
PBAC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_000_111-{offset}
PBWS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_000-{offset}
PBWC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_001-{offset}
PBIS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_010-{offset}
PBIC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_011-{offset}
PBGS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_100-{offset}
PBGC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_101-{offset}
PBCS.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_110-{offset}
PBCC.L <label>					|-|--M---|P|-----|-----|          |1111_000_011_001_111-{offset}
PSAVE <ea>					|-|--M---|P|-----|-----|  M -WXZ  |1111_000_100_mmm_rrr
PRESTORE <ea>					|-|--M---|P|-----|-----|  M+ WXZP |1111_000_101_mmm_rrr
FTST.X FPm					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmm0000111010
FMOVE.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0000000
FINT.X FPm,FPn					|-|--CCS6|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0000001
FSINH.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0000010
FINTRZ.X FPm,FPn				|-|--CCS6|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0000011
FSQRT.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0000100
FLOGNP1.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0000110
FETOXM1.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001000
FTANH.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001001
FATAN.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001010
FASIN.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001100
FATANH.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001101
FSIN.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001110
FTAN.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0001111
FETOX.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0010000
FTWOTOX.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0010001
FTENTOX.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0010010
FLOGN.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0010100
FLOG10.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0010101
FLOG2.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0010110
FABS.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011000
FCOSH.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011001
FNEG.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011010
FACOS.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011100
FCOS.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011101
FGETEXP.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011110
FGETMAN.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0011111
FDIV.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100000
FMOD.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100001
FADD.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100010
FMUL.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100011
FSGLDIV.X FPm,FPn				|-|--CCS6|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100100
FREM.X FPm,FPn					|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100101
FSCALE.X FPm,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100110
FSGLMUL.X FPm,FPn				|-|--CCS6|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0100111
FSUB.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0101000
FCMP.X FPm,FPn					|-|--CC46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn0111000
FSMOVE.X FPm,FPn				|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1000000
FSSQRT.X FPm,FPn				|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1000001
FDMOVE.X FPm,FPn				|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1000100
FDSQRT.X FPm,FPn				|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1000101
FSABS.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1011000
FSNEG.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1011010
FDABS.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1011100
FDNEG.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1011110
FSDIV.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1100000
FSADD.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1100010
FSMUL.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1100011
FDDIV.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1100100
FDADD.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1100110
FDMUL.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1100111
FSSUB.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1101000
FDSUB.X FPm,FPn					|-|----46|-|-----|-----|          |1111_001_000_000_000-000mmmnnn1101100
FSINCOS.X FPm,FPc:FPs				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-000mmmsss0110ccc
FMOVECR.X #ccc,FPn				|-|--CCSS|-|-----|-----|          |1111_001_000_000_000-010111nnn0cccccc
FMOVE.L FPn,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-011000nnn0000000
FMOVE.S FPn,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-011001nnn0000000
FMOVE.W FPn,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-011100nnn0000000
FMOVE.B FPn,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-011110nnn0000000
FMOVE.L FPIAR,<ea>				|-|--CC46|-|-----|-----|DAM+-WXZ  |1111_001_000_mmm_rrr-1010010000000000
FMOVEM.L FPIAR,<ea>				|-|--CC46|-|-----|-----|DAM+-WXZ  |1111_001_000_mmm_rrr-1010010000000000
FMOVE.L FPSR,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-1010100000000000
FMOVEM.L FPSR,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-1010100000000000
FMOVE.L FPCR,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-1011000000000000
FMOVEM.L FPCR,<ea>				|-|--CC46|-|-----|-----|D M+-WXZ  |1111_001_000_mmm_rrr-1011000000000000
FTST.L <ea>					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-0100000000111010
FMOVE.L <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0000000
FINT.L <ea>,FPn					|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0000001
FSINH.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0000010
FINTRZ.L <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0000011
FSQRT.L <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0000100
FLOGNP1.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0000110
FETOXM1.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001000
FTANH.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001001
FATAN.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001010
FASIN.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001100
FATANH.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001101
FSIN.L <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001110
FTAN.L <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0001111
FETOX.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0010000
FTWOTOX.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0010001
FTENTOX.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0010010
FLOGN.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0010100
FLOG10.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0010101
FLOG2.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0010110
FABS.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011000
FCOSH.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011001
FNEG.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011010
FACOS.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011100
FCOS.L <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011101
FGETEXP.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011110
FGETMAN.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0011111
FDIV.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100000
FMOD.L <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100001
FADD.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100010
FMUL.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100011
FSGLDIV.L <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100100
FREM.L <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100101
FSCALE.L <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100110
FSGLMUL.L <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0100111
FSUB.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0101000
FCMP.L <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn0111000
FSMOVE.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1000000
FSSQRT.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1000001
FDMOVE.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1000100
FDSQRT.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1000101
FSABS.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1011000
FSNEG.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1011010
FDABS.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1011100
FDNEG.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1011110
FSDIV.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1100000
FSADD.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1100010
FSMUL.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1100011
FDDIV.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1100100
FDADD.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1100110
FDMUL.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1100111
FSSUB.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1101000
FDSUB.L <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000nnn1101100
FSINCOS.L <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010000sss0110ccc
FTST.S <ea>					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-0100010000111010
FMOVE.S <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0000000
FINT.S <ea>,FPn					|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0000001
FSINH.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0000010
FINTRZ.S <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0000011
FSQRT.S <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0000100
FLOGNP1.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0000110
FETOXM1.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001000
FTANH.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001001
FATAN.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001010
FASIN.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001100
FATANH.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001101
FSIN.S <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001110
FTAN.S <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0001111
FETOX.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0010000
FTWOTOX.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0010001
FTENTOX.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0010010
FLOGN.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0010100
FLOG10.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0010101
FLOG2.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0010110
FABS.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011000
FCOSH.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011001
FNEG.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011010
FACOS.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011100
FCOS.S <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011101
FGETEXP.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011110
FGETMAN.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0011111
FDIV.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100000
FMOD.S <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100001
FADD.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100010
FMUL.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100011
FSGLDIV.S <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100100
FREM.S <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100101
FSCALE.S <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100110
FSGLMUL.S <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0100111
FSUB.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0101000
FCMP.S <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn0111000
FSMOVE.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1000000
FSSQRT.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1000001
FDMOVE.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1000100
FDSQRT.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1000101
FSABS.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1011000
FSNEG.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1011010
FDABS.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1011100
FDNEG.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1011110
FSDIV.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1100000
FSADD.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1100010
FSMUL.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1100011
FDDIV.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1100100
FDADD.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1100110
FDMUL.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1100111
FSSUB.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1101000
FDSUB.S <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001nnn1101100
FSINCOS.S <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010001sss0110ccc
FTST.W <ea>					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-0101000000111010
FMOVE.W <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0000000
FINT.W <ea>,FPn					|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0000001
FSINH.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0000010
FINTRZ.W <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0000011
FSQRT.W <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0000100
FLOGNP1.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0000110
FETOXM1.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001000
FTANH.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001001
FATAN.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001010
FASIN.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001100
FATANH.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001101
FSIN.W <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001110
FTAN.W <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0001111
FETOX.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0010000
FTWOTOX.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0010001
FTENTOX.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0010010
FLOGN.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0010100
FLOG10.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0010101
FLOG2.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0010110
FABS.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011000
FCOSH.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011001
FNEG.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011010
FACOS.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011100
FCOS.W <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011101
FGETEXP.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011110
FGETMAN.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0011111
FDIV.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100000
FMOD.W <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100001
FADD.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100010
FMUL.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100011
FSGLDIV.W <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100100
FREM.W <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100101
FSCALE.W <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100110
FSGLMUL.W <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0100111
FSUB.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0101000
FCMP.W <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn0111000
FSMOVE.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1000000
FSSQRT.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1000001
FDMOVE.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1000100
FDSQRT.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1000101
FSABS.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1011000
FSNEG.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1011010
FDABS.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1011100
FDNEG.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1011110
FSDIV.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1100000
FSADD.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1100010
FSMUL.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1100011
FDDIV.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1100100
FDADD.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1100110
FDMUL.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1100111
FSSUB.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1101000
FDSUB.W <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100nnn1101100
FSINCOS.W <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010100sss0110ccc
FTST.B <ea>					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-0101100000111010
FMOVE.B <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0000000
FINT.B <ea>,FPn					|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0000001
FSINH.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0000010
FINTRZ.B <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0000011
FSQRT.B <ea>,FPn				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0000100
FLOGNP1.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0000110
FETOXM1.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001000
FTANH.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001001
FATAN.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001010
FASIN.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001100
FATANH.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001101
FSIN.B <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001110
FTAN.B <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0001111
FETOX.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0010000
FTWOTOX.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0010001
FTENTOX.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0010010
FLOGN.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0010100
FLOG10.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0010101
FLOG2.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0010110
FABS.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011000
FCOSH.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011001
FNEG.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011010
FACOS.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011100
FCOS.B <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011101
FGETEXP.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011110
FGETMAN.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0011111
FDIV.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100000
FMOD.B <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100001
FADD.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100010
FMUL.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100011
FSGLDIV.B <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100100
FREM.B <ea>,FPn					|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100101
FSCALE.B <ea>,FPn				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100110
FSGLMUL.B <ea>,FPn				|-|--CCS6|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0100111
FSUB.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0101000
FCMP.B <ea>,FPn					|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn0111000
FSMOVE.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1000000
FSSQRT.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1000001
FDMOVE.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1000100
FDSQRT.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1000101
FSABS.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1011000
FSNEG.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1011010
FDABS.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1011100
FDNEG.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1011110
FSDIV.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1100000
FSADD.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1100010
FSMUL.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1100011
FDDIV.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1100100
FDADD.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1100110
FDMUL.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1100111
FSSUB.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1101000
FDSUB.B <ea>,FPn				|-|----46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110nnn1101100
FSINCOS.B <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-010110sss0110ccc
FMOVE.L <ea>,FPIAR				|-|--CC46|-|-----|-----|DAM+-WXZPI|1111_001_000_mmm_rrr-1000010000000000
FMOVEM.L <ea>,FPIAR				|-|--CC46|-|-----|-----|DAM+-WXZPI|1111_001_000_mmm_rrr-1000010000000000
FMOVE.L <ea>,FPSR				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-1000100000000000
FMOVEM.L <ea>,FPSR				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-1000100000000000
FMOVE.L <ea>,FPCR				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-1001000000000000
FMOVEM.L <ea>,FPCR				|-|--CC46|-|-----|-----|D M+-WXZPI|1111_001_000_mmm_rrr-1001000000000000
FMOVE.X FPn,<ea>				|-|--CC46|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-011010nnn0000000
FMOVE.P FPn,<ea>{#k}				|-|--CCSS|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-011011nnnkkkkkkk
FMOVE.D FPn,<ea>				|-|--CC46|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-011101nnn0000000
FMOVE.P FPn,<ea>{Dk}				|-|--CCSS|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-011111nnnkkk0000
FMOVEM.L FPSR/FPIAR,<ea>			|-|--CC46|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-1010110000000000
FMOVEM.L FPCR/FPIAR,<ea>			|-|--CC46|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-1011010000000000
FMOVEM.L FPCR/FPSR,<ea>				|-|--CC46|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-1011100000000000
FMOVEM.L FPCR/FPSR/FPIAR,<ea>			|-|--CC46|-|-----|-----|  M+-WXZ  |1111_001_000_mmm_rrr-1011110000000000
FMOVEM.X #<data>,<ea>				|-|--CC46|-|-----|-----|  M  WXZ  |1111_001_000_mmm_rrr-11110000dddddddd
FMOVEM.X <list>,<ea>				|-|--CC46|-|-----|-----|  M  WXZ  |1111_001_000_mmm_rrr-11110000llllllll
FMOVEM.X Dl,<ea>				|-|--CC4S|-|-----|-----|  M  WXZ  |1111_001_000_mmm_rrr-111110000lll0000
FMOVEM.L <ea>,FPSR/FPIAR			|-|--CC46|-|-----|-----|  M+-WXZP |1111_001_000_mmm_rrr-1000110000000000
FMOVEM.L <ea>,FPCR/FPIAR			|-|--CC46|-|-----|-----|  M+-WXZP |1111_001_000_mmm_rrr-1001010000000000
FMOVEM.L <ea>,FPCR/FPSR				|-|--CC46|-|-----|-----|  M+-WXZP |1111_001_000_mmm_rrr-1001100000000000
FMOVEM.L <ea>,FPCR/FPSR/FPIAR			|-|--CC46|-|-----|-----|  M+-WXZP |1111_001_000_mmm_rrr-1001110000000000
FMOVEM.X <ea>,#<data>				|-|--CC46|-|-----|-----|  M+ WXZP |1111_001_000_mmm_rrr-11010000dddddddd
FMOVEM.X <ea>,<list>				|-|--CC46|-|-----|-----|  M+ WXZP |1111_001_000_mmm_rrr-11010000llllllll
FMOVEM.X <ea>,Dl				|-|--CC4S|-|-----|-----|  M+ WXZP |1111_001_000_mmm_rrr-110110000lll0000
FTST.X <ea>					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-0100100000111010
FMOVE.X <ea>,FPn				|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0000000
FINT.X <ea>,FPn					|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0000001
FSINH.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0000010
FINTRZ.X <ea>,FPn				|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0000011
FSQRT.X <ea>,FPn				|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0000100
FLOGNP1.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0000110
FETOXM1.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001000
FTANH.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001001
FATAN.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001010
FASIN.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001100
FATANH.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001101
FSIN.X <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001110
FTAN.X <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0001111
FETOX.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0010000
FTWOTOX.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0010001
FTENTOX.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0010010
FLOGN.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0010100
FLOG10.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0010101
FLOG2.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0010110
FABS.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011000
FCOSH.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011001
FNEG.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011010
FACOS.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011100
FCOS.X <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011101
FGETEXP.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011110
FGETMAN.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0011111
FDIV.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100000
FMOD.X <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100001
FADD.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100010
FMUL.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100011
FSGLDIV.X <ea>,FPn				|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100100
FREM.X <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100101
FSCALE.X <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100110
FSGLMUL.X <ea>,FPn				|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0100111
FSUB.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0101000
FCMP.X <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn0111000
FSMOVE.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1000000
FSSQRT.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1000001
FDMOVE.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1000100
FDSQRT.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1000101
FSABS.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1011000
FSNEG.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1011010
FDABS.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1011100
FDNEG.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1011110
FSDIV.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1100000
FSADD.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1100010
FSMUL.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1100011
FDDIV.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1100100
FDADD.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1100110
FDMUL.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1100111
FSSUB.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1101000
FDSUB.X <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010nnn1101100
FSINCOS.X <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010010sss0110ccc
FTST.P <ea>					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-0100110000111010
FMOVE.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0000000
FINT.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0000001
FSINH.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0000010
FINTRZ.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0000011
FSQRT.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0000100
FLOGNP1.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0000110
FETOXM1.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001000
FTANH.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001001
FATAN.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001010
FASIN.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001100
FATANH.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001101
FSIN.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001110
FTAN.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0001111
FETOX.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0010000
FTWOTOX.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0010001
FTENTOX.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0010010
FLOGN.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0010100
FLOG10.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0010101
FLOG2.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0010110
FABS.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011000
FCOSH.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011001
FNEG.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011010
FACOS.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011100
FCOS.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011101
FGETEXP.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011110
FGETMAN.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0011111
FDIV.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100000
FMOD.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100001
FADD.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100010
FMUL.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100011
FSGLDIV.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100100
FREM.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100101
FSCALE.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100110
FSGLMUL.P <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0100111
FSUB.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0101000
FCMP.P <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn0111000
FSMOVE.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1000000
FSSQRT.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1000001
FDMOVE.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1000100
FDSQRT.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1000101
FSABS.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1011000
FSNEG.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1011010
FDABS.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1011100
FDNEG.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1011110
FSDIV.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1100000
FSADD.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1100010
FSMUL.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1100011
FDDIV.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1100100
FDADD.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1100110
FDMUL.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1100111
FSSUB.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1101000
FDSUB.P <ea>,FPn				|-|----SS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011nnn1101100
FSINCOS.P <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010011sss0110ccc
FTST.D <ea>					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-0101010000111010
FMOVE.D <ea>,FPn				|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0000000
FINT.D <ea>,FPn					|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0000001
FSINH.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0000010
FINTRZ.D <ea>,FPn				|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0000011
FSQRT.D <ea>,FPn				|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0000100
FLOGNP1.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0000110
FETOXM1.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001000
FTANH.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001001
FATAN.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001010
FASIN.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001100
FATANH.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001101
FSIN.D <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001110
FTAN.D <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0001111
FETOX.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0010000
FTWOTOX.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0010001
FTENTOX.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0010010
FLOGN.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0010100
FLOG10.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0010101
FLOG2.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0010110
FABS.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011000
FCOSH.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011001
FNEG.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011010
FACOS.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011100
FCOS.D <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011101
FGETEXP.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011110
FGETMAN.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0011111
FDIV.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100000
FMOD.D <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100001
FADD.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100010
FMUL.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100011
FSGLDIV.D <ea>,FPn				|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100100
FREM.D <ea>,FPn					|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100101
FSCALE.D <ea>,FPn				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100110
FSGLMUL.D <ea>,FPn				|-|--CCS6|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0100111
FSUB.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0101000
FCMP.D <ea>,FPn					|-|--CC46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn0111000
FSMOVE.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1000000
FSSQRT.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1000001
FDMOVE.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1000100
FDSQRT.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1000101
FSABS.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1011000
FSNEG.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1011010
FDABS.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1011100
FDNEG.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1011110
FSDIV.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1100000
FSADD.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1100010
FSMUL.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1100011
FDDIV.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1100100
FDADD.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1100110
FDMUL.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1100111
FSSUB.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1101000
FDSUB.D <ea>,FPn				|-|----46|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101nnn1101100
FSINCOS.D <ea>,FPc:FPs				|-|--CCSS|-|-----|-----|  M+-WXZPI|1111_001_000_mmm_rrr-010101sss0110ccc
FMOVEM.X #<data>,-(Ar)				|-|--CC46|-|-----|-----|    -     |1111_001_000_100_rrr-11100000dddddddd
FMOVEM.X <list>,-(Ar)				|-|--CC46|-|-----|-----|    -     |1111_001_000_100_rrr-11100000llllllll
FMOVEM.X Dl,-(Ar)				|-|--CC4S|-|-----|-----|    -     |1111_001_000_100_rrr-111010000lll0000
FMOVEM.L #<data>,#<data>,FPSR/FPIAR		|-|--CC4S|-|-----|-----|         I|1111_001_000_111_100-1000110000000000-{data}
FMOVEM.L #<data>,#<data>,FPCR/FPIAR		|-|--CC4S|-|-----|-----|         I|1111_001_000_111_100-1001010000000000-{data}
FMOVEM.L #<data>,#<data>,FPCR/FPSR		|-|--CC4S|-|-----|-----|         I|1111_001_000_111_100-1001100000000000-{data}
FMOVEM.L #<data>,#<data>,#<data>,FPCR/FPSR/FPIAR|-|--CC4S|-|-----|-----|         I|1111_001_000_111_100-1001110000000000-{data}
FSF.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000000
FSEQ.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000001
FSOGT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000010
FSOGE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000011
FSOLT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000100
FSOLE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000101
FSOGL.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000110
FSOR.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000000111
FSUN.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001000
FSUEQ.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001001
FSUGT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001010
FSUGE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001011
FSULT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001100
FSULE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001101
FSNE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001110
FST.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000001111
FSSF.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010000
FSSEQ.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010001
FSGT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010010
FSGE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010011
FSLT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010100
FSLE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010101
FSGL.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010110
FSGLE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000010111
FSNGLE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011000
FSNGL.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011001
FSNLE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011010
FSNLT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011011
FSNGE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011100
FSNGT.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011101
FSSNE.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011110
FSST.B <ea>					|-|--CC4S|-|-----|-----|D M+-WXZ  |1111_001_001_mmm_rrr-0000000000011111
FDBF Dr,<label>					|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000000-{offset}
FDBEQ Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000001-{offset}
FDBOGT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000010-{offset}
FDBOGE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000011-{offset}
FDBOLT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000100-{offset}
FDBOLE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000101-{offset}
FDBOGL Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000110-{offset}
FDBOR Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000111-{offset}
FDBUN Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001000-{offset}
FDBUEQ Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001001-{offset}
FDBUGT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001010-{offset}
FDBUGE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001011-{offset}
FDBULT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001100-{offset}
FDBULE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001101-{offset}
FDBNE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001110-{offset}
FDBT Dr,<label>					|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000001111-{offset}
FDBSF Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010000-{offset}
FDBSEQ Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010001-{offset}
FDBGT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010010-{offset}
FDBGE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010011-{offset}
FDBLT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010100-{offset}
FDBLE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010101-{offset}
FDBGL Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010110-{offset}
FDBGLE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000010111-{offset}
FDBNGLE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011000-{offset}
FDBNGL Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011001-{offset}
FDBNLE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011010-{offset}
FDBNLT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011011-{offset}
FDBNGE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011100-{offset}
FDBNGT Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011101-{offset}
FDBSNE Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011110-{offset}
FDBST Dr,<label>				|-|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000011111-{offset}
FTRAPF.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000000-{data}
FTRAPEQ.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000001-{data}
FTRAPOGT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000010-{data}
FTRAPOGE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000011-{data}
FTRAPOLT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000100-{data}
FTRAPOLE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000101-{data}
FTRAPOGL.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000110-{data}
FTRAPOR.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000000111-{data}
FTRAPUN.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001000-{data}
FTRAPUEQ.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001001-{data}
FTRAPUGT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001010-{data}
FTRAPUGE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001011-{data}
FTRAPULT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001100-{data}
FTRAPULE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001101-{data}
FTRAPNE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001110-{data}
FTRAPT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000001111-{data}
FTRAPSF.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010000-{data}
FTRAPSEQ.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010001-{data}
FTRAPGT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010010-{data}
FTRAPGE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010011-{data}
FTRAPLT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010100-{data}
FTRAPLE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010101-{data}
FTRAPGL.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010110-{data}
FTRAPGLE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000010111-{data}
FTRAPNGLE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011000-{data}
FTRAPNGL.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011001-{data}
FTRAPNLE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011010-{data}
FTRAPNLT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011011-{data}
FTRAPNGE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011100-{data}
FTRAPNGT.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011101-{data}
FTRAPSNE.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011110-{data}
FTRAPST.W #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_010-0000000000011111-{data}
FTRAPF.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000000-{data}
FTRAPEQ.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000001-{data}
FTRAPOGT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000010-{data}
FTRAPOGE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000011-{data}
FTRAPOLT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000100-{data}
FTRAPOLE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000101-{data}
FTRAPOGL.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000110-{data}
FTRAPOR.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000000111-{data}
FTRAPUN.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001000-{data}
FTRAPUEQ.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001001-{data}
FTRAPUGT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001010-{data}
FTRAPUGE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001011-{data}
FTRAPULT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001100-{data}
FTRAPULE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001101-{data}
FTRAPNE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001110-{data}
FTRAPT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000001111-{data}
FTRAPSF.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010000-{data}
FTRAPSEQ.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010001-{data}
FTRAPGT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010010-{data}
FTRAPGE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010011-{data}
FTRAPLT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010100-{data}
FTRAPLE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010101-{data}
FTRAPGL.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010110-{data}
FTRAPGLE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000010111-{data}
FTRAPNGLE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011000-{data}
FTRAPNGL.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011001-{data}
FTRAPNLE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011010-{data}
FTRAPNLT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011011-{data}
FTRAPNGE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011100-{data}
FTRAPNGT.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011101-{data}
FTRAPSNE.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011110-{data}
FTRAPST.L #<data>				|-|--CC4S|-|-----|-----|          |1111_001_001_111_011-0000000000011111-{data}
FTRAPF						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000000
FTRAPEQ						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000001
FTRAPOGT					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000010
FTRAPOGE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000011
FTRAPOLT					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000100
FTRAPOLE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000101
FTRAPOGL					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000110
FTRAPOR						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000000111
FTRAPUN						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001000
FTRAPUEQ					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001001
FTRAPUGT					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001010
FTRAPUGE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001011
FTRAPULT					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001100
FTRAPULE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001101
FTRAPNE						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001110
FTRAPT						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000001111
FTRAPSF						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010000
FTRAPSEQ					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010001
FTRAPGT						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010010
FTRAPGE						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010011
FTRAPLT						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010100
FTRAPLE						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010101
FTRAPGL						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010110
FTRAPGLE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000010111
FTRAPNGLE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011000
FTRAPNGL					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011001
FTRAPNLE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011010
FTRAPNLT					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011011
FTRAPNGE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011100
FTRAPNGT					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011101
FTRAPSNE					|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011110
FTRAPST						|-|--CC4S|-|-----|-----|          |1111_001_001_111_100-0000000000011111
FBF.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_000-{offset}
FBEQ.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_001-{offset}
FBOGT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_010-{offset}
FBOGE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_011-{offset}
FBOLT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_100-{offset}
FBOLE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_101-{offset}
FBOGL.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_110-{offset}
FBOR.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_000_111-{offset}
FBUN.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_000-{offset}
FBUEQ.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_001-{offset}
FBUGT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_010-{offset}
FBUGE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_011-{offset}
FBULT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_100-{offset}
FBULE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_101-{offset}
FBNE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_110-{offset}
FBT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_001_111-{offset}
FBSF.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_000-{offset}
FBSEQ.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_001-{offset}
FBGT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_010-{offset}
FBGE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_011-{offset}
FBLT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_100-{offset}
FBLE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_101-{offset}
FBGL.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_110-{offset}
FBGLE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_010_111-{offset}
FBNGLE.W <label>				|-|--CC46|-|-----|-----|          |1111_001_010_011_000-{offset}
FBNGL.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_001-{offset}
FBNLE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_010-{offset}
FBNLT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_011-{offset}
FBNGE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_100-{offset}
FBNGT.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_101-{offset}
FBSNE.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_110-{offset}
FBST.W <label>					|-|--CC46|-|-----|-----|          |1111_001_010_011_111-{offset}
FBF.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_000-{offset}
FBEQ.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_001-{offset}
FBOGT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_010-{offset}
FBOGE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_011-{offset}
FBOLT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_100-{offset}
FBOLE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_101-{offset}
FBOGL.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_110-{offset}
FBOR.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_000_111-{offset}
FBUN.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_000-{offset}
FBUEQ.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_001-{offset}
FBUGT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_010-{offset}
FBUGE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_011-{offset}
FBULT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_100-{offset}
FBULE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_101-{offset}
FBNE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_110-{offset}
FBT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_001_111-{offset}
FBSF.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_000-{offset}
FBSEQ.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_001-{offset}
FBGT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_010-{offset}
FBGE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_011-{offset}
FBLT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_100-{offset}
FBLE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_101-{offset}
FBGL.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_110-{offset}
FBGLE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_010_111-{offset}
FBNGLE.L <label>				|-|--CC46|-|-----|-----|          |1111_001_011_011_000-{offset}
FBNGL.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_001-{offset}
FBNLE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_010-{offset}
FBNLT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_011-{offset}
FBNGE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_100-{offset}
FBNGT.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_101-{offset}
FBSNE.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_110-{offset}
FBST.L <label>					|-|--CC46|-|-----|-----|          |1111_001_011_011_111-{offset}
FSAVE <ea>					|-|--CC46|P|-----|-----|  M -WXZ  |1111_001_100_mmm_rrr
FRESTORE <ea>					|-|--CC46|P|-----|-----|  M+ WXZP |1111_001_101_mmm_rrr
CINVL NC,(Ar)					|-|----46|P|-----|-----|          |1111_010_000_001_rrr
CINVP NC,(Ar)					|-|----46|P|-----|-----|          |1111_010_000_010_rrr
CINVA NC					|-|----46|P|-----|-----|          |1111_010_000_011_000
CPUSHL NC,(Ar)					|-|----46|P|-----|-----|          |1111_010_000_101_rrr
CPUSHP NC,(Ar)					|-|----46|P|-----|-----|          |1111_010_000_110_rrr
CPUSHA NC					|-|----46|P|-----|-----|          |1111_010_000_111_000
CINVL DC,(Ar)					|-|----46|P|-----|-----|          |1111_010_001_001_rrr
CINVP DC,(Ar)					|-|----46|P|-----|-----|          |1111_010_001_010_rrr
CINVA DC					|-|----46|P|-----|-----|          |1111_010_001_011_000
CPUSHL DC,(Ar)					|-|----46|P|-----|-----|          |1111_010_001_101_rrr
CPUSHP DC,(Ar)					|-|----46|P|-----|-----|          |1111_010_001_110_rrr
CPUSHA DC					|-|----46|P|-----|-----|          |1111_010_001_111_000
CINVL IC,(Ar)					|-|----46|P|-----|-----|          |1111_010_010_001_rrr
CINVP IC,(Ar)					|-|----46|P|-----|-----|          |1111_010_010_010_rrr
CINVA IC					|-|----46|P|-----|-----|          |1111_010_010_011_000
CPUSHL IC,(Ar)					|-|----46|P|-----|-----|          |1111_010_010_101_rrr
CPUSHP IC,(Ar)					|-|----46|P|-----|-----|          |1111_010_010_110_rrr
CPUSHA IC					|-|----46|P|-----|-----|          |1111_010_010_111_000
CINVL BC,(Ar)					|-|----46|P|-----|-----|          |1111_010_011_001_rrr
CINVP BC,(Ar)					|-|----46|P|-----|-----|          |1111_010_011_010_rrr
CINVA BC					|-|----46|P|-----|-----|          |1111_010_011_011_000
CPUSHL BC,(Ar)					|-|----46|P|-----|-----|          |1111_010_011_101_rrr
CPUSHP BC,(Ar)					|-|----46|P|-----|-----|          |1111_010_011_110_rrr
CPUSHA BC					|-|----46|P|-----|-----|          |1111_010_011_111_000
PFLUSHN (Ar)					|-|----46|P|-----|-----|          |1111_010_100_000_rrr
PFLUSH (Ar)					|-|----46|P|-----|-----|          |1111_010_100_001_rrr
PFLUSHAN					|-|----46|P|-----|-----|          |1111_010_100_010_000
PFLUSHA						|-|----46|P|-----|-----|          |1111_010_100_011_000
PTESTW (Ar)					|-|----4-|P|-----|-----|          |1111_010_101_001_rrr
PTESTR (Ar)					|-|----4-|P|-----|-----|          |1111_010_101_101_rrr
PLPAW (Ar)					|-|-----6|P|-----|-----|          |1111_010_110_001_rrr
PLPAR (Ar)					|-|-----6|P|-----|-----|          |1111_010_111_001_rrr
MOVE16 (Ar)+,xxx.L				|-|----46|-|-----|-----|          |1111_011_000_000_rrr-{address}
MOVE16 xxx.L,(Ar)+				|-|----46|-|-----|-----|          |1111_011_000_001_rrr-{address}
MOVE16 (Ar),xxx.L				|-|----46|-|-----|-----|          |1111_011_000_010_rrr-{address}
MOVE16 xxx.L,(Ar)				|-|----46|-|-----|-----|          |1111_011_000_011_rrr-{address}
MOVE16 (Ar)+,(An)+				|-|----46|-|-----|-----|          |1111_011_000_100_rrr-1nnn000000000000
LPSTOP.W #<data>				|-|-----6|P|-----|-----|          |1111_100_000_000_000-0000000111000000-{data}
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
OR.B #<data>,<ea>				|A|012346|-|-UUUU|-**00|  M+-WXZ  |0000_000_000_mmm_rrr-{data}	[ORI.B #<data>,<ea>]
OR.W #<data>,<ea>				|A|012346|-|-UUUU|-**00|  M+-WXZ  |0000_000_001_mmm_rrr-{data}	[ORI.W #<data>,<ea>]
OR.L #<data>,<ea>				|A|012346|-|-UUUU|-**00|  M+-WXZ  |0000_000_010_mmm_rrr-{data}	[ORI.L #<data>,<ea>]
AND.B #<data>,<ea>				|A|012346|-|-UUUU|-**00|  M+-WXZ  |0000_001_000_mmm_rrr-{data}	[ANDI.B #<data>,<ea>]
AND.W #<data>,<ea>				|A|012346|-|-UUUU|-**00|  M+-WXZ  |0000_001_001_mmm_rrr-{data}	[ANDI.W #<data>,<ea>]
AND.L #<data>,<ea>				|A|012346|-|-UUUU|-**00|  M+-WXZ  |0000_001_010_mmm_rrr-{data}	[ANDI.L #<data>,<ea>]
SUB.B #<data>,<ea>				|A|012346|-|UUUUU|*****|  M+-WXZ  |0000_010_000_mmm_rrr-{data}	[SUBI.B #<data>,<ea>]
SUB.W #<data>,<ea>				|A|012346|-|UUUUU|*****|  M+-WXZ  |0000_010_001_mmm_rrr-{data}	[SUBI.W #<data>,<ea>]
SUB.L #<data>,<ea>				|A|012346|-|UUUUU|*****|  M+-WXZ  |0000_010_010_mmm_rrr-{data}	[SUBI.L #<data>,<ea>]
EOR.B #<data>,<ea>				|A|012346|-|-UUUU|-**00|D M+-WXZ  |0000_101_000_mmm_rrr-{data}	[EORI.B #<data>,<ea>]
EOR.W #<data>,<ea>				|A|012346|-|-UUUU|-**00|D M+-WXZ  |0000_101_001_mmm_rrr-{data}	[EORI.W #<data>,<ea>]
EOR.L #<data>,<ea>				|A|012346|-|-UUUU|-**00|D M+-WXZ  |0000_101_010_mmm_rrr-{data}	[EORI.L #<data>,<ea>]
CMP.B #<data>,<ea>				|A|01----|-|-UUUU|-****|  M+-WXZ  |0000_110_000_mmm_rrr-{data}	[CMPI.B #<data>,<ea>]
CMP.B #<data>,<ea>				|A|--2346|-|-UUUU|-****|  M+-WXZP |0000_110_000_mmm_rrr-{data}	[CMPI.B #<data>,<ea>]
CMP.W #<data>,<ea>				|A|01----|-|-UUUU|-****|  M+-WXZ  |0000_110_001_mmm_rrr-{data}	[CMPI.W #<data>,<ea>]
CMP.W #<data>,<ea>				|A|--2346|-|-UUUU|-****|  M+-WXZP |0000_110_001_mmm_rrr-{data}	[CMPI.W #<data>,<ea>]
CMP.L #<data>,<ea>				|A|01----|-|-UUUU|-****|  M+-WXZ  |0000_110_010_mmm_rrr-{data}	[CMPI.L #<data>,<ea>]
CMP.L #<data>,<ea>				|A|--2346|-|-UUUU|-****|  M+-WXZP |0000_110_010_mmm_rrr-{data}	[CMPI.L #<data>,<ea>]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
MOVE.L <ea>,Aq					|A|012346|-|-----|-----|DAM+-WXZPI|0010_qqq_001_mmm_rrr	[MOVEA.L <ea>,Aq]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
MOVE.W <ea>,Aq					|A|012346|-|-----|-----|DAM+-WXZPI|0011_qqq_001_mmm_rrr	[MOVEA.W <ea>,Aq]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
JBSR.L <label>					|A|012346|-|-----|-----|          |0100_111_010_111_001-{address}	[JSR <label>]
JBRA.L <label>					|A|012346|-|-----|-----|          |0100_111_011_111_001-{address}	[JMP <label>]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
SNF.B <ea>					|A|012346|-|-----|-----|D M+-WXZ  |0101_000_011_mmm_rrr	[ST.B <ea>]
DBNF.W Dr,<label>				|A|012346|-|-----|-----|          |0101_000_011_001_rrr-{offset}	[DBT.W Dr,<label>]
TPNF.W #<data>					|A|--2346|-|-----|-----|          |0101_000_011_111_010-{data}	[TRAPT.W #<data>]
TPT.W #<data>					|A|--2346|-|-----|-----|          |0101_000_011_111_010-{data}	[TRAPT.W #<data>]
TRAPNF.W #<data>				|A|--2346|-|-----|-----|          |0101_000_011_111_010-{data}	[TRAPT.W #<data>]
TPNF.L #<data>					|A|--2346|-|-----|-----|          |0101_000_011_111_011-{data}	[TRAPT.L #<data>]
TPT.L #<data>					|A|--2346|-|-----|-----|          |0101_000_011_111_011-{data}	[TRAPT.L #<data>]
TRAPNF.L #<data>				|A|--2346|-|-----|-----|          |0101_000_011_111_011-{data}	[TRAPT.L #<data>]
TPNF						|A|--2346|-|-----|-----|          |0101_000_011_111_100	[TRAPT]
TPT						|A|--2346|-|-----|-----|          |0101_000_011_111_100	[TRAPT]
TRAPNF						|A|--2346|-|-----|-----|          |0101_000_011_111_100	[TRAPT]
SNT.B <ea>					|A|012346|-|-----|-----|D M+-WXZ  |0101_000_111_mmm_rrr	[SF.B <ea>]
DBNT.W Dr,<label>				|A|012346|-|-----|-----|          |0101_000_111_001_rrr-{offset}	[DBF.W Dr,<label>]
DBRA.W Dr,<label>				|A|012346|-|-----|-----|          |0101_000_111_001_rrr-{offset}	[DBF.W Dr,<label>]
TPF.W #<data>					|A|--2346|-|-----|-----|          |0101_000_111_111_010-{data}	[TRAPF.W #<data>]
TPNT.W #<data>					|A|--2346|-|-----|-----|          |0101_000_111_111_010-{data}	[TRAPF.W #<data>]
TRAPNT.W #<data>				|A|--2346|-|-----|-----|          |0101_000_111_111_010-{data}	[TRAPF.W #<data>]
TPF.L #<data>					|A|--2346|-|-----|-----|          |0101_000_111_111_011-{data}	[TRAPF.L #<data>]
TPNT.L #<data>					|A|--2346|-|-----|-----|          |0101_000_111_111_011-{data}	[TRAPF.L #<data>]
TRAPNT.L #<data>				|A|--2346|-|-----|-----|          |0101_000_111_111_011-{data}	[TRAPF.L #<data>]
TPF						|A|--2346|-|-----|-----|          |0101_000_111_111_100	[TRAPF]
TPNT						|A|--2346|-|-----|-----|          |0101_000_111_111_100	[TRAPF]
TRAPNT						|A|--2346|-|-----|-----|          |0101_000_111_111_100	[TRAPF]
INC.B <ea>					|A|012346|-|UUUUU|*****|D M+-WXZ  |0101_001_000_mmm_rrr	[ADDQ.B #1,<ea>]
INC.W <ea>					|A|012346|-|UUUUU|*****|D M+-WXZ  |0101_001_001_mmm_rrr	[ADDQ.W #1,<ea>]
INC.W Ar					|A|012346|-|-----|-----| A        |0101_001_001_001_rrr	[ADDQ.W #1,Ar]
INC.L <ea>					|A|012346|-|UUUUU|*****|D M+-WXZ  |0101_001_010_mmm_rrr	[ADDQ.L #1,<ea>]
INC.L Ar					|A|012346|-|-----|-----| A        |0101_001_010_001_rrr	[ADDQ.L #1,Ar]
SNLS.B <ea>					|A|012346|-|--*-*|-----|D M+-WXZ  |0101_001_011_mmm_rrr	[SHI.B <ea>]
DBNLS.W Dr,<label>				|A|012346|-|--*-*|-----|          |0101_001_011_001_rrr-{offset}	[DBHI.W Dr,<label>]
TPHI.W #<data>					|A|--2346|-|--*-*|-----|          |0101_001_011_111_010-{data}	[TRAPHI.W #<data>]
TPNLS.W #<data>					|A|--2346|-|--*-*|-----|          |0101_001_011_111_010-{data}	[TRAPHI.W #<data>]
TRAPNLS.W #<data>				|A|--2346|-|--*-*|-----|          |0101_001_011_111_010-{data}	[TRAPHI.W #<data>]
TPHI.L #<data>					|A|--2346|-|--*-*|-----|          |0101_001_011_111_011-{data}	[TRAPHI.L #<data>]
TPNLS.L #<data>					|A|--2346|-|--*-*|-----|          |0101_001_011_111_011-{data}	[TRAPHI.L #<data>]
TRAPNLS.L #<data>				|A|--2346|-|--*-*|-----|          |0101_001_011_111_011-{data}	[TRAPHI.L #<data>]
TPHI						|A|--2346|-|--*-*|-----|          |0101_001_011_111_100	[TRAPHI]
TPNLS						|A|--2346|-|--*-*|-----|          |0101_001_011_111_100	[TRAPHI]
TRAPNLS						|A|--2346|-|--*-*|-----|          |0101_001_011_111_100	[TRAPHI]
DEC.B <ea>					|A|012346|-|UUUUU|*****|D M+-WXZ  |0101_001_100_mmm_rrr	[SUBQ.B #1,<ea>]
DEC.W <ea>					|A|012346|-|UUUUU|*****|D M+-WXZ  |0101_001_101_mmm_rrr	[SUBQ.W #1,<ea>]
DEC.W Ar					|A|012346|-|-----|-----| A        |0101_001_101_001_rrr	[SUBQ.W #1,Ar]
DEC.L <ea>					|A|012346|-|UUUUU|*****|D M+-WXZ  |0101_001_110_mmm_rrr	[SUBQ.L #1,<ea>]
DEC.L Ar					|A|012346|-|-----|-----| A        |0101_001_110_001_rrr	[SUBQ.L #1,Ar]
SNHI.B <ea>					|A|012346|-|--*-*|-----|D M+-WXZ  |0101_001_111_mmm_rrr	[SLS.B <ea>]
DBNHI.W Dr,<label>				|A|012346|-|--*-*|-----|          |0101_001_111_001_rrr-{offset}	[DBLS.W Dr,<label>]
TPLS.W #<data>					|A|--2346|-|--*-*|-----|          |0101_001_111_111_010-{data}	[TRAPLS.W #<data>]
TPNHI.W #<data>					|A|--2346|-|--*-*|-----|          |0101_001_111_111_010-{data}	[TRAPLS.W #<data>]
TRAPNHI.W #<data>				|A|--2346|-|--*-*|-----|          |0101_001_111_111_010-{data}	[TRAPLS.W #<data>]
TPLS.L #<data>					|A|--2346|-|--*-*|-----|          |0101_001_111_111_011-{data}	[TRAPLS.L #<data>]
TPNHI.L #<data>					|A|--2346|-|--*-*|-----|          |0101_001_111_111_011-{data}	[TRAPLS.L #<data>]
TRAPNHI.L #<data>				|A|--2346|-|--*-*|-----|          |0101_001_111_111_011-{data}	[TRAPLS.L #<data>]
TPLS						|A|--2346|-|--*-*|-----|          |0101_001_111_111_100	[TRAPLS]
TPNHI						|A|--2346|-|--*-*|-----|          |0101_001_111_111_100	[TRAPLS]
TRAPNHI						|A|--2346|-|--*-*|-----|          |0101_001_111_111_100	[TRAPLS]
SHS.B <ea>					|A|012346|-|----*|-----|D M+-WXZ  |0101_010_011_mmm_rrr	[SCC.B <ea>]
SNCS.B <ea>					|A|012346|-|----*|-----|D M+-WXZ  |0101_010_011_mmm_rrr	[SCC.B <ea>]
SNLO.B <ea>					|A|012346|-|----*|-----|D M+-WXZ  |0101_010_011_mmm_rrr	[SCC.B <ea>]
DBHS.W Dr,<label>				|A|012346|-|----*|-----|          |0101_010_011_001_rrr-{offset}	[DBCC.W Dr,<label>]
DBNCS.W Dr,<label>				|A|012346|-|----*|-----|          |0101_010_011_001_rrr-{offset}	[DBCC.W Dr,<label>]
DBNLO.W Dr,<label>				|A|012346|-|----*|-----|          |0101_010_011_001_rrr-{offset}	[DBCC.W Dr,<label>]
TPCC.W #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TPHS.W #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TPNCS.W #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TPNLO.W #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TRAPHS.W #<data>				|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TRAPNCS.W #<data>				|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TRAPNLO.W #<data>				|A|--2346|-|----*|-----|          |0101_010_011_111_010-{data}	[TRAPCC.W #<data>]
TPCC.L #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TPHS.L #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TPNCS.L #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TPNLO.L #<data>					|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TRAPHS.L #<data>				|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TRAPNCS.L #<data>				|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TRAPNLO.L #<data>				|A|--2346|-|----*|-----|          |0101_010_011_111_011-{data}	[TRAPCC.L #<data>]
TPCC						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
TPHS						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
TPNCS						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
TPNLO						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
TRAPHS						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
TRAPNCS						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
TRAPNLO						|A|--2346|-|----*|-----|          |0101_010_011_111_100	[TRAPCC]
SLO.B <ea>					|A|012346|-|----*|-----|D M+-WXZ  |0101_010_111_mmm_rrr	[SCS.B <ea>]
SNCC.B <ea>					|A|012346|-|----*|-----|D M+-WXZ  |0101_010_111_mmm_rrr	[SCS.B <ea>]
SNHS.B <ea>					|A|012346|-|----*|-----|D M+-WXZ  |0101_010_111_mmm_rrr	[SCS.B <ea>]
DBLO.W Dr,<label>				|A|012346|-|----*|-----|          |0101_010_111_001_rrr-{offset}	[DBCS.W Dr,<label>]
DBNCC.W Dr,<label>				|A|012346|-|----*|-----|          |0101_010_111_001_rrr-{offset}	[DBCS.W Dr,<label>]
DBNHS.W Dr,<label>				|A|012346|-|----*|-----|          |0101_010_111_001_rrr-{offset}	[DBCS.W Dr,<label>]
TPCS.W #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TPLO.W #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TPNCC.W #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TPNHS.W #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TRAPLO.W #<data>				|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TRAPNCC.W #<data>				|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TRAPNHS.W #<data>				|A|--2346|-|----*|-----|          |0101_010_111_111_010-{data}	[TRAPCS.W #<data>]
TPCS.L #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TPLO.L #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TPNCC.L #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TPNHS.L #<data>					|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TRAPLO.L #<data>				|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TRAPNCC.L #<data>				|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TRAPNHS.L #<data>				|A|--2346|-|----*|-----|          |0101_010_111_111_011-{data}	[TRAPCS.L #<data>]
TPCS						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
TPLO						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
TPNCC						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
TPNHS						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
TRAPLO						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
TRAPNCC						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
TRAPNHS						|A|--2346|-|----*|-----|          |0101_010_111_111_100	[TRAPCS]
SNEQ.B <ea>					|A|012346|-|--*--|-----|D M+-WXZ  |0101_011_011_mmm_rrr	[SNE.B <ea>]
SNZ.B <ea>					|A|012346|-|--*--|-----|D M+-WXZ  |0101_011_011_mmm_rrr	[SNE.B <ea>]
SNZE.B <ea>					|A|012346|-|--*--|-----|D M+-WXZ  |0101_011_011_mmm_rrr	[SNE.B <ea>]
DBNEQ.W Dr,<label>				|A|012346|-|--*--|-----|          |0101_011_011_001_rrr-{offset}	[DBNE.W Dr,<label>]
DBNZ.W Dr,<label>				|A|012346|-|--*--|-----|          |0101_011_011_001_rrr-{offset}	[DBNE.W Dr,<label>]
DBNZE.W Dr,<label>				|A|012346|-|--*--|-----|          |0101_011_011_001_rrr-{offset}	[DBNE.W Dr,<label>]
TPNE.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TPNEQ.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TPNZ.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TPNZE.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TRAPNEQ.W #<data>				|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TRAPNZ.W #<data>				|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TRAPNZE.W #<data>				|A|--2346|-|--*--|-----|          |0101_011_011_111_010-{data}	[TRAPNE.W #<data>]
TPNE.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TPNEQ.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TPNZ.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TPNZE.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TRAPNEQ.L #<data>				|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TRAPNZ.L #<data>				|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TRAPNZE.L #<data>				|A|--2346|-|--*--|-----|          |0101_011_011_111_011-{data}	[TRAPNE.L #<data>]
TPNE						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
TPNEQ						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
TPNZ						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
TPNZE						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
TRAPNEQ						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
TRAPNZ						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
TRAPNZE						|A|--2346|-|--*--|-----|          |0101_011_011_111_100	[TRAPNE]
SNNE.B <ea>					|A|012346|-|--*--|-----|D M+-WXZ  |0101_011_111_mmm_rrr	[SEQ.B <ea>]
SNNZ.B <ea>					|A|012346|-|--*--|-----|D M+-WXZ  |0101_011_111_mmm_rrr	[SEQ.B <ea>]
SZE.B <ea>					|A|012346|-|--*--|-----|D M+-WXZ  |0101_011_111_mmm_rrr	[SEQ.B <ea>]
DBNNE.W Dr,<label>				|A|012346|-|--*--|-----|          |0101_011_111_001_rrr-{offset}	[DBEQ.W Dr,<label>]
DBNNZ.W Dr,<label>				|A|012346|-|--*--|-----|          |0101_011_111_001_rrr-{offset}	[DBEQ.W Dr,<label>]
DBZE.W Dr,<label>				|A|012346|-|--*--|-----|          |0101_011_111_001_rrr-{offset}	[DBEQ.W Dr,<label>]
TPEQ.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TPNNE.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TPNNZ.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TPZE.W #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TRAPNNE.W #<data>				|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TRAPNNZ.W #<data>				|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TRAPZE.W #<data>				|A|--2346|-|--*--|-----|          |0101_011_111_111_010-{data}	[TRAPEQ.W #<data>]
TPEQ.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TPNNE.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TPNNZ.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TPZE.L #<data>					|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TRAPNNE.L #<data>				|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TRAPNNZ.L #<data>				|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TRAPZE.L #<data>				|A|--2346|-|--*--|-----|          |0101_011_111_111_011-{data}	[TRAPEQ.L #<data>]
TPEQ						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
TPNNE						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
TPNNZ						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
TPZE						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
TRAPNNE						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
TRAPNNZ						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
TRAPZE						|A|--2346|-|--*--|-----|          |0101_011_111_111_100	[TRAPEQ]
SNVS.B <ea>					|A|012346|-|---*-|-----|D M+-WXZ  |0101_100_011_mmm_rrr	[SVC.B <ea>]
DBNVS.W Dr,<label>				|A|012346|-|---*-|-----|          |0101_100_011_001_rrr-{offset}	[DBVC.W Dr,<label>]
TPNVS.W #<data>					|A|--2346|-|---*-|-----|          |0101_100_011_111_010-{data}	[TRAPVC.W #<data>]
TPVC.W #<data>					|A|--2346|-|---*-|-----|          |0101_100_011_111_010-{data}	[TRAPVC.W #<data>]
TRAPNVS.W #<data>				|A|--2346|-|---*-|-----|          |0101_100_011_111_010-{data}	[TRAPVC.W #<data>]
TPNVS.L #<data>					|A|--2346|-|---*-|-----|          |0101_100_011_111_011-{data}	[TRAPVC.L #<data>]
TPVC.L #<data>					|A|--2346|-|---*-|-----|          |0101_100_011_111_011-{data}	[TRAPVC.L #<data>]
TRAPNVS.L #<data>				|A|--2346|-|---*-|-----|          |0101_100_011_111_011-{data}	[TRAPVC.L #<data>]
TPNVS						|A|--2346|-|---*-|-----|          |0101_100_011_111_100	[TRAPVC]
TPVC						|A|--2346|-|---*-|-----|          |0101_100_011_111_100	[TRAPVC]
TRAPNVS						|A|--2346|-|---*-|-----|          |0101_100_011_111_100	[TRAPVC]
SNVC.B <ea>					|A|012346|-|---*-|-----|D M+-WXZ  |0101_100_111_mmm_rrr	[SVS.B <ea>]
DBNVC.W Dr,<label>				|A|012346|-|---*-|-----|          |0101_100_111_001_rrr-{offset}	[DBVS.W Dr,<label>]
TPNVC.W #<data>					|A|--2346|-|---*-|-----|          |0101_100_111_111_010-{data}	[TRAPVS.W #<data>]
TPVS.W #<data>					|A|--2346|-|---*-|-----|          |0101_100_111_111_010-{data}	[TRAPVS.W #<data>]
TRAPNVC.W #<data>				|A|--2346|-|---*-|-----|          |0101_100_111_111_010-{data}	[TRAPVS.W #<data>]
TPNVC.L #<data>					|A|--2346|-|---*-|-----|          |0101_100_111_111_011-{data}	[TRAPVS.L #<data>]
TPVS.L #<data>					|A|--2346|-|---*-|-----|          |0101_100_111_111_011-{data}	[TRAPVS.L #<data>]
TRAPNVC.L #<data>				|A|--2346|-|---*-|-----|          |0101_100_111_111_011-{data}	[TRAPVS.L #<data>]
TPNVC						|A|--2346|-|---*-|-----|          |0101_100_111_111_100	[TRAPVS]
TPVS						|A|--2346|-|---*-|-----|          |0101_100_111_111_100	[TRAPVS]
TRAPNVC						|A|--2346|-|---*-|-----|          |0101_100_111_111_100	[TRAPVS]
SNMI.B <ea>					|A|012346|-|-*---|-----|D M+-WXZ  |0101_101_011_mmm_rrr	[SPL.B <ea>]
DBNMI.W Dr,<label>				|A|012346|-|-*---|-----|          |0101_101_011_001_rrr-{offset}	[DBPL.W Dr,<label>]
TPNMI.W #<data>					|A|--2346|-|-*---|-----|          |0101_101_011_111_010-{data}	[TRAPPL.W #<data>]
TPPL.W #<data>					|A|--2346|-|-*---|-----|          |0101_101_011_111_010-{data}	[TRAPPL.W #<data>]
TRAPNMI.W #<data>				|A|--2346|-|-*---|-----|          |0101_101_011_111_010-{data}	[TRAPPL.W #<data>]
TPNMI.L #<data>					|A|--2346|-|-*---|-----|          |0101_101_011_111_011-{data}	[TRAPPL.L #<data>]
TPPL.L #<data>					|A|--2346|-|-*---|-----|          |0101_101_011_111_011-{data}	[TRAPPL.L #<data>]
TRAPNMI.L #<data>				|A|--2346|-|-*---|-----|          |0101_101_011_111_011-{data}	[TRAPPL.L #<data>]
TPNMI						|A|--2346|-|-*---|-----|          |0101_101_011_111_100	[TRAPPL]
TPPL						|A|--2346|-|-*---|-----|          |0101_101_011_111_100	[TRAPPL]
TRAPNMI						|A|--2346|-|-*---|-----|          |0101_101_011_111_100	[TRAPPL]
SNPL.B <ea>					|A|012346|-|-*---|-----|D M+-WXZ  |0101_101_111_mmm_rrr	[SMI.B <ea>]
DBNPL.W Dr,<label>				|A|012346|-|-*---|-----|          |0101_101_111_001_rrr-{offset}	[DBMI.W Dr,<label>]
TPMI.W #<data>					|A|--2346|-|-*---|-----|          |0101_101_111_111_010-{data}	[TRAPMI.W #<data>]
TPNPL.W #<data>					|A|--2346|-|-*---|-----|          |0101_101_111_111_010-{data}	[TRAPMI.W #<data>]
TRAPNPL.W #<data>				|A|--2346|-|-*---|-----|          |0101_101_111_111_010-{data}	[TRAPMI.W #<data>]
TPMI.L #<data>					|A|--2346|-|-*---|-----|          |0101_101_111_111_011-{data}	[TRAPMI.L #<data>]
TPNPL.L #<data>					|A|--2346|-|-*---|-----|          |0101_101_111_111_011-{data}	[TRAPMI.L #<data>]
TRAPNPL.L #<data>				|A|--2346|-|-*---|-----|          |0101_101_111_111_011-{data}	[TRAPMI.L #<data>]
TPMI						|A|--2346|-|-*---|-----|          |0101_101_111_111_100	[TRAPMI]
TPNPL						|A|--2346|-|-*---|-----|          |0101_101_111_111_100	[TRAPMI]
TRAPNPL						|A|--2346|-|-*---|-----|          |0101_101_111_111_100	[TRAPMI]
SNLT.B <ea>					|A|012346|-|-*-*-|-----|D M+-WXZ  |0101_110_011_mmm_rrr	[SGE.B <ea>]
DBNLT.W Dr,<label>				|A|012346|-|-*-*-|-----|          |0101_110_011_001_rrr-{offset}	[DBGE.W Dr,<label>]
TPGE.W #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_011_111_010-{data}	[TRAPGE.W #<data>]
TPNLT.W #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_011_111_010-{data}	[TRAPGE.W #<data>]
TRAPNLT.W #<data>				|A|--2346|-|-*-*-|-----|          |0101_110_011_111_010-{data}	[TRAPGE.W #<data>]
TPGE.L #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_011_111_011-{data}	[TRAPGE.L #<data>]
TPNLT.L #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_011_111_011-{data}	[TRAPGE.L #<data>]
TRAPNLT.L #<data>				|A|--2346|-|-*-*-|-----|          |0101_110_011_111_011-{data}	[TRAPGE.L #<data>]
TPGE						|A|--2346|-|-*-*-|-----|          |0101_110_011_111_100	[TRAPGE]
TPNLT						|A|--2346|-|-*-*-|-----|          |0101_110_011_111_100	[TRAPGE]
TRAPNLT						|A|--2346|-|-*-*-|-----|          |0101_110_011_111_100	[TRAPGE]
SNGE.B <ea>					|A|012346|-|-*-*-|-----|D M+-WXZ  |0101_110_111_mmm_rrr	[SLT.B <ea>]
DBNGE.W Dr,<label>				|A|012346|-|-*-*-|-----|          |0101_110_111_001_rrr-{offset}	[DBLT.W Dr,<label>]
TPLT.W #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_111_111_010-{data}	[TRAPLT.W #<data>]
TPNGE.W #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_111_111_010-{data}	[TRAPLT.W #<data>]
TRAPNGE.W #<data>				|A|--2346|-|-*-*-|-----|          |0101_110_111_111_010-{data}	[TRAPLT.W #<data>]
TPLT.L #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_111_111_011-{data}	[TRAPLT.L #<data>]
TPNGE.L #<data>					|A|--2346|-|-*-*-|-----|          |0101_110_111_111_011-{data}	[TRAPLT.L #<data>]
TRAPNGE.L #<data>				|A|--2346|-|-*-*-|-----|          |0101_110_111_111_011-{data}	[TRAPLT.L #<data>]
TPLT						|A|--2346|-|-*-*-|-----|          |0101_110_111_111_100	[TRAPLT]
TPNGE						|A|--2346|-|-*-*-|-----|          |0101_110_111_111_100	[TRAPLT]
TRAPNGE						|A|--2346|-|-*-*-|-----|          |0101_110_111_111_100	[TRAPLT]
SNLE.B <ea>					|A|012346|-|-***-|-----|D M+-WXZ  |0101_111_011_mmm_rrr	[SGT.B <ea>]
DBNLE.W Dr,<label>				|A|012346|-|-***-|-----|          |0101_111_011_001_rrr-{offset}	[DBGT.W Dr,<label>]
TPGT.W #<data>					|A|--2346|-|-***-|-----|          |0101_111_011_111_010-{data}	[TRAPGT.W #<data>]
TPNLE.W #<data>					|A|--2346|-|-***-|-----|          |0101_111_011_111_010-{data}	[TRAPGT.W #<data>]
TRAPNLE.W #<data>				|A|--2346|-|-***-|-----|          |0101_111_011_111_010-{data}	[TRAPGT.W #<data>]
TPGT.L #<data>					|A|--2346|-|-***-|-----|          |0101_111_011_111_011-{data}	[TRAPGT.L #<data>]
TPNLE.L #<data>					|A|--2346|-|-***-|-----|          |0101_111_011_111_011-{data}	[TRAPGT.L #<data>]
TRAPNLE.L #<data>				|A|--2346|-|-***-|-----|          |0101_111_011_111_011-{data}	[TRAPGT.L #<data>]
TPGT						|A|--2346|-|-***-|-----|          |0101_111_011_111_100	[TRAPGT]
TPNLE						|A|--2346|-|-***-|-----|          |0101_111_011_111_100	[TRAPGT]
TRAPNLE						|A|--2346|-|-***-|-----|          |0101_111_011_111_100	[TRAPGT]
SNGT.B <ea>					|A|012346|-|-***-|-----|D M+-WXZ  |0101_111_111_mmm_rrr	[SLE.B <ea>]
DBNGT.W Dr,<label>				|A|012346|-|-***-|-----|          |0101_111_111_001_rrr-{offset}	[DBLE.W Dr,<label>]
TPLE.W #<data>					|A|--2346|-|-***-|-----|          |0101_111_111_111_010-{data}	[TRAPLE.W #<data>]
TPNGT.W #<data>					|A|--2346|-|-***-|-----|          |0101_111_111_111_010-{data}	[TRAPLE.W #<data>]
TRAPNGT.W #<data>				|A|--2346|-|-***-|-----|          |0101_111_111_111_010-{data}	[TRAPLE.W #<data>]
TPLE.L #<data>					|A|--2346|-|-***-|-----|          |0101_111_111_111_011-{data}	[TRAPLE.L #<data>]
TPNGT.L #<data>					|A|--2346|-|-***-|-----|          |0101_111_111_111_011-{data}	[TRAPLE.L #<data>]
TRAPNGT.L #<data>				|A|--2346|-|-***-|-----|          |0101_111_111_111_011-{data}	[TRAPLE.L #<data>]
TPLE						|A|--2346|-|-***-|-----|          |0101_111_111_111_100	[TRAPLE]
TPNGT						|A|--2346|-|-***-|-----|          |0101_111_111_111_100	[TRAPLE]
TRAPNGT						|A|--2346|-|-***-|-----|          |0101_111_111_111_100	[TRAPLE]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
JBRA.W <label>					|A|012346|-|-----|-----|          |0110_000_000_000_000-{offset}	[BRA.W <label>]
JBRA.S <label>					|A|012346|-|-----|-----|          |0110_000_000_sss_sss	(s is not equal to 0)	[BRA.S <label>]
JBRA.S <label>					|A|012346|-|-----|-----|          |0110_000_001_sss_sss	[BRA.S <label>]
JBRA.S <label>					|A|012346|-|-----|-----|          |0110_000_010_sss_sss	[BRA.S <label>]
JBRA.S <label>					|A|01----|-|-----|-----|          |0110_000_011_sss_sss	[BRA.S <label>]
JBRA.S <label>					|A|--2346|-|-----|-----|          |0110_000_011_sss_sss	(s is not equal to 63)	[BRA.S <label>]
JBSR.W <label>					|A|012346|-|-----|-----|          |0110_000_100_000_000-{offset}	[BSR.W <label>]
JBSR.S <label>					|A|012346|-|-----|-----|          |0110_000_100_sss_sss	(s is not equal to 0)	[BSR.S <label>]
JBSR.S <label>					|A|012346|-|-----|-----|          |0110_000_101_sss_sss	[BSR.S <label>]
JBSR.S <label>					|A|012346|-|-----|-----|          |0110_000_110_sss_sss	[BSR.S <label>]
JBSR.S <label>					|A|01----|-|-----|-----|          |0110_000_111_sss_sss	[BSR.S <label>]
JBSR.S <label>					|A|--2346|-|-----|-----|          |0110_000_111_sss_sss	(s is not equal to 63)	[BSR.S <label>]
BNLS.W <label>					|A|012346|-|--*-*|-----|          |0110_001_000_000_000-{offset}	[BHI.W <label>]
JBHI.W <label>					|A|012346|-|--*-*|-----|          |0110_001_000_000_000-{offset}	[BHI.W <label>]
JBNLS.W <label>					|A|012346|-|--*-*|-----|          |0110_001_000_000_000-{offset}	[BHI.W <label>]
BNLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_000_sss_sss	(s is not equal to 0)	[BHI.S <label>]
JBHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_000_sss_sss	(s is not equal to 0)	[BHI.S <label>]
JBNLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_000_sss_sss	(s is not equal to 0)	[BHI.S <label>]
JBLS.L <label>					|A|012346|-|--*-*|-----|          |0110_001_000_000_110-0100111011111001-{address}	[BHI.S (*)+8;JMP <label>]
JBNHI.L <label>					|A|012346|-|--*-*|-----|          |0110_001_000_000_110-0100111011111001-{address}	[BHI.S (*)+8;JMP <label>]
BNLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_001_sss_sss	[BHI.S <label>]
JBHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_001_sss_sss	[BHI.S <label>]
JBNLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_001_sss_sss	[BHI.S <label>]
BNLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_010_sss_sss	[BHI.S <label>]
JBHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_010_sss_sss	[BHI.S <label>]
JBNLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_010_sss_sss	[BHI.S <label>]
BNLS.S <label>					|A|01----|-|--*-*|-----|          |0110_001_011_sss_sss	[BHI.S <label>]
BNLS.S <label>					|A|--2346|-|--*-*|-----|          |0110_001_011_sss_sss	(s is not equal to 63)	[BHI.S <label>]
JBHI.S <label>					|A|01----|-|--*-*|-----|          |0110_001_011_sss_sss	[BHI.S <label>]
JBHI.S <label>					|A|--2346|-|--*-*|-----|          |0110_001_011_sss_sss	(s is not equal to 63)	[BHI.S <label>]
JBNLS.S <label>					|A|01----|-|--*-*|-----|          |0110_001_011_sss_sss	[BHI.S <label>]
JBNLS.S <label>					|A|--2346|-|--*-*|-----|          |0110_001_011_sss_sss	(s is not equal to 63)	[BHI.S <label>]
BNLS.L <label>					|A|--2346|-|--*-*|-----|          |0110_001_011_111_111-{offset}	[BHI.L <label>]
BNHI.W <label>					|A|012346|-|--*-*|-----|          |0110_001_100_000_000-{offset}	[BLS.W <label>]
JBLS.W <label>					|A|012346|-|--*-*|-----|          |0110_001_100_000_000-{offset}	[BLS.W <label>]
JBNHI.W <label>					|A|012346|-|--*-*|-----|          |0110_001_100_000_000-{offset}	[BLS.W <label>]
BNHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_100_sss_sss	(s is not equal to 0)	[BLS.S <label>]
JBLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_100_sss_sss	(s is not equal to 0)	[BLS.S <label>]
JBNHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_100_sss_sss	(s is not equal to 0)	[BLS.S <label>]
JBHI.L <label>					|A|012346|-|--*-*|-----|          |0110_001_100_000_110-0100111011111001-{address}	[BLS.S (*)+8;JMP <label>]
JBNLS.L <label>					|A|012346|-|--*-*|-----|          |0110_001_100_000_110-0100111011111001-{address}	[BLS.S (*)+8;JMP <label>]
BNHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_101_sss_sss	[BLS.S <label>]
JBLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_101_sss_sss	[BLS.S <label>]
JBNHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_101_sss_sss	[BLS.S <label>]
BNHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_110_sss_sss	[BLS.S <label>]
JBLS.S <label>					|A|012346|-|--*-*|-----|          |0110_001_110_sss_sss	[BLS.S <label>]
JBNHI.S <label>					|A|012346|-|--*-*|-----|          |0110_001_110_sss_sss	[BLS.S <label>]
BNHI.S <label>					|A|01----|-|--*-*|-----|          |0110_001_111_sss_sss	[BLS.S <label>]
BNHI.S <label>					|A|--2346|-|--*-*|-----|          |0110_001_111_sss_sss	(s is not equal to 63)	[BLS.S <label>]
JBLS.S <label>					|A|01----|-|--*-*|-----|          |0110_001_111_sss_sss	[BLS.S <label>]
JBLS.S <label>					|A|--2346|-|--*-*|-----|          |0110_001_111_sss_sss	(s is not equal to 63)	[BLS.S <label>]
JBNHI.S <label>					|A|01----|-|--*-*|-----|          |0110_001_111_sss_sss	[BLS.S <label>]
JBNHI.S <label>					|A|--2346|-|--*-*|-----|          |0110_001_111_sss_sss	(s is not equal to 63)	[BLS.S <label>]
BNHI.L <label>					|A|--2346|-|--*-*|-----|          |0110_001_111_111_111-{offset}	[BLS.L <label>]
BHS.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
BNCS.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
BNLO.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
JBCC.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
JBHS.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
JBNCS.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
JBNLO.W <label>					|A|012346|-|----*|-----|          |0110_010_000_000_000-{offset}	[BCC.W <label>]
BHS.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
BNCS.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
BNLO.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
JBCC.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
JBHS.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
JBNCS.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
JBNLO.S <label>					|A|012346|-|----*|-----|          |0110_010_000_sss_sss	(s is not equal to 0)	[BCC.S <label>]
JBCS.L <label>					|A|012346|-|----*|-----|          |0110_010_000_000_110-0100111011111001-{address}	[BCC.S (*)+8;JMP <label>]
JBLO.L <label>					|A|012346|-|----*|-----|          |0110_010_000_000_110-0100111011111001-{address}	[BCC.S (*)+8;JMP <label>]
JBNCC.L <label>					|A|012346|-|----*|-----|          |0110_010_000_000_110-0100111011111001-{address}	[BCC.S (*)+8;JMP <label>]
JBNHS.L <label>					|A|012346|-|----*|-----|          |0110_010_000_000_110-0100111011111001-{address}	[BCC.S (*)+8;JMP <label>]
BHS.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
BNCS.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
BNLO.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
JBCC.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
JBHS.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
JBNCS.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
JBNLO.S <label>					|A|012346|-|----*|-----|          |0110_010_001_sss_sss	[BCC.S <label>]
BHS.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
BNCS.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
BNLO.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
JBCC.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
JBHS.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
JBNCS.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
JBNLO.S <label>					|A|012346|-|----*|-----|          |0110_010_010_sss_sss	[BCC.S <label>]
BHS.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
BHS.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
BNCS.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
BNCS.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
BNLO.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
BNLO.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
JBCC.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
JBCC.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
JBHS.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
JBHS.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
JBNCS.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
JBNCS.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
JBNLO.S <label>					|A|01----|-|----*|-----|          |0110_010_011_sss_sss	[BCC.S <label>]
JBNLO.S <label>					|A|--2346|-|----*|-----|          |0110_010_011_sss_sss	(s is not equal to 63)	[BCC.S <label>]
BHS.L <label>					|A|--2346|-|----*|-----|          |0110_010_011_111_111-{offset}	[BCC.L <label>]
BNCS.L <label>					|A|--2346|-|----*|-----|          |0110_010_011_111_111-{offset}	[BCC.L <label>]
BNLO.L <label>					|A|--2346|-|----*|-----|          |0110_010_011_111_111-{offset}	[BCC.L <label>]
BLO.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
BNCC.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
BNHS.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
JBCS.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
JBLO.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
JBNCC.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
JBNHS.W <label>					|A|012346|-|----*|-----|          |0110_010_100_000_000-{offset}	[BCS.W <label>]
BLO.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
BNCC.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
BNHS.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
JBCS.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
JBLO.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
JBNCC.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
JBNHS.S <label>					|A|012346|-|----*|-----|          |0110_010_100_sss_sss	(s is not equal to 0)	[BCS.S <label>]
JBCC.L <label>					|A|012346|-|----*|-----|          |0110_010_100_000_110-0100111011111001-{address}	[BCS.S (*)+8;JMP <label>]
JBHS.L <label>					|A|012346|-|----*|-----|          |0110_010_100_000_110-0100111011111001-{address}	[BCS.S (*)+8;JMP <label>]
JBNCS.L <label>					|A|012346|-|----*|-----|          |0110_010_100_000_110-0100111011111001-{address}	[BCS.S (*)+8;JMP <label>]
JBNLO.L <label>					|A|012346|-|----*|-----|          |0110_010_100_000_110-0100111011111001-{address}	[BCS.S (*)+8;JMP <label>]
BLO.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
BNCC.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
BNHS.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
JBCS.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
JBLO.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
JBNCC.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
JBNHS.S <label>					|A|012346|-|----*|-----|          |0110_010_101_sss_sss	[BCS.S <label>]
BLO.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
BNCC.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
BNHS.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
JBCS.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
JBLO.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
JBNCC.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
JBNHS.S <label>					|A|012346|-|----*|-----|          |0110_010_110_sss_sss	[BCS.S <label>]
BLO.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
BLO.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
BNCC.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
BNCC.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
BNHS.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
BNHS.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
JBCS.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
JBCS.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
JBLO.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
JBLO.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
JBNCC.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
JBNCC.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
JBNHS.S <label>					|A|01----|-|----*|-----|          |0110_010_111_sss_sss	[BCS.S <label>]
JBNHS.S <label>					|A|--2346|-|----*|-----|          |0110_010_111_sss_sss	(s is not equal to 63)	[BCS.S <label>]
BLO.L <label>					|A|--2346|-|----*|-----|          |0110_010_111_111_111-{offset}	[BCS.L <label>]
BNCC.L <label>					|A|--2346|-|----*|-----|          |0110_010_111_111_111-{offset}	[BCS.L <label>]
BNHS.L <label>					|A|--2346|-|----*|-----|          |0110_010_111_111_111-{offset}	[BCS.L <label>]
BNEQ.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
BNZ.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
BNZE.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
JBNE.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
JBNEQ.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
JBNZ.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
JBNZE.W <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_000-{offset}	[BNE.W <label>]
BNEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
BNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
BNZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
JBNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
JBNEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
JBNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
JBNZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_000_sss_sss	(s is not equal to 0)	[BNE.S <label>]
JBEQ.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
JBNEQ.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
JBNNE.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
JBNNZ.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
JBNZ.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
JBNZE.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
JBZE.L <label>					|A|012346|-|--*--|-----|          |0110_011_000_000_110-0100111011111001-{address}	[BNE.S (*)+8;JMP <label>]
BNEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
BNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
BNZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
JBNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
JBNEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
JBNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
JBNZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_001_sss_sss	[BNE.S <label>]
BNEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
BNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
BNZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
JBNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
JBNEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
JBNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
JBNZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_010_sss_sss	[BNE.S <label>]
BNEQ.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
BNEQ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
BNZ.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
BNZ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
BNZE.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
BNZE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
JBNE.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
JBNE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
JBNEQ.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
JBNEQ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
JBNZ.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
JBNZ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
JBNZE.S <label>					|A|01----|-|--*--|-----|          |0110_011_011_sss_sss	[BNE.S <label>]
JBNZE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_011_sss_sss	(s is not equal to 63)	[BNE.S <label>]
BNEQ.L <label>					|A|--2346|-|--*--|-----|          |0110_011_011_111_111-{offset}	[BNE.L <label>]
BNZ.L <label>					|A|--2346|-|--*--|-----|          |0110_011_011_111_111-{offset}	[BNE.L <label>]
BNZE.L <label>					|A|--2346|-|--*--|-----|          |0110_011_011_111_111-{offset}	[BNE.L <label>]
BNNE.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
BNNZ.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
BZE.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
JBEQ.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
JBNNE.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
JBNNZ.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
JBZE.W <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_000-{offset}	[BEQ.W <label>]
BNNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
BNNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
BZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
JBEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
JBNNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
JBNNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
JBZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_100_sss_sss	(s is not equal to 0)	[BEQ.S <label>]
JBNE.L <label>					|A|012346|-|--*--|-----|          |0110_011_100_000_110-0100111011111001-{address}	[BEQ.S (*)+8;JMP <label>]
BNNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
BNNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
BZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
JBEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
JBNNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
JBNNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
JBZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_101_sss_sss	[BEQ.S <label>]
BNNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
BNNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
BZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
JBEQ.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
JBNNE.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
JBNNZ.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
JBZE.S <label>					|A|012346|-|--*--|-----|          |0110_011_110_sss_sss	[BEQ.S <label>]
BNNE.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
BNNE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
BNNZ.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
BNNZ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
BZE.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
BZE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
JBEQ.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
JBEQ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
JBNNE.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
JBNNE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
JBNNZ.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
JBNNZ.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
JBZE.S <label>					|A|01----|-|--*--|-----|          |0110_011_111_sss_sss	[BEQ.S <label>]
JBZE.S <label>					|A|--2346|-|--*--|-----|          |0110_011_111_sss_sss	(s is not equal to 63)	[BEQ.S <label>]
BNNE.L <label>					|A|--2346|-|--*--|-----|          |0110_011_111_111_111-{offset}	[BEQ.L <label>]
BNNZ.L <label>					|A|--2346|-|--*--|-----|          |0110_011_111_111_111-{offset}	[BEQ.L <label>]
BZE.L <label>					|A|--2346|-|--*--|-----|          |0110_011_111_111_111-{offset}	[BEQ.L <label>]
BNVS.W <label>					|A|012346|-|---*-|-----|          |0110_100_000_000_000-{offset}	[BVC.W <label>]
JBNVS.W <label>					|A|012346|-|---*-|-----|          |0110_100_000_000_000-{offset}	[BVC.W <label>]
JBVC.W <label>					|A|012346|-|---*-|-----|          |0110_100_000_000_000-{offset}	[BVC.W <label>]
BNVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_000_sss_sss	(s is not equal to 0)	[BVC.S <label>]
JBNVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_000_sss_sss	(s is not equal to 0)	[BVC.S <label>]
JBVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_000_sss_sss	(s is not equal to 0)	[BVC.S <label>]
JBNVC.L <label>					|A|012346|-|---*-|-----|          |0110_100_000_000_110-0100111011111001-{address}	[BVC.S (*)+8;JMP <label>]
JBVS.L <label>					|A|012346|-|---*-|-----|          |0110_100_000_000_110-0100111011111001-{address}	[BVC.S (*)+8;JMP <label>]
BNVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_001_sss_sss	[BVC.S <label>]
JBNVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_001_sss_sss	[BVC.S <label>]
JBVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_001_sss_sss	[BVC.S <label>]
BNVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_010_sss_sss	[BVC.S <label>]
JBNVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_010_sss_sss	[BVC.S <label>]
JBVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_010_sss_sss	[BVC.S <label>]
BNVS.S <label>					|A|01----|-|---*-|-----|          |0110_100_011_sss_sss	[BVC.S <label>]
BNVS.S <label>					|A|--2346|-|---*-|-----|          |0110_100_011_sss_sss	(s is not equal to 63)	[BVC.S <label>]
JBNVS.S <label>					|A|01----|-|---*-|-----|          |0110_100_011_sss_sss	[BVC.S <label>]
JBNVS.S <label>					|A|--2346|-|---*-|-----|          |0110_100_011_sss_sss	(s is not equal to 63)	[BVC.S <label>]
JBVC.S <label>					|A|01----|-|---*-|-----|          |0110_100_011_sss_sss	[BVC.S <label>]
JBVC.S <label>					|A|--2346|-|---*-|-----|          |0110_100_011_sss_sss	(s is not equal to 63)	[BVC.S <label>]
BNVS.L <label>					|A|--2346|-|---*-|-----|          |0110_100_011_111_111-{offset}	[BVC.L <label>]
BNVC.W <label>					|A|012346|-|---*-|-----|          |0110_100_100_000_000-{offset}	[BVS.W <label>]
JBNVC.W <label>					|A|012346|-|---*-|-----|          |0110_100_100_000_000-{offset}	[BVS.W <label>]
JBVS.W <label>					|A|012346|-|---*-|-----|          |0110_100_100_000_000-{offset}	[BVS.W <label>]
BNVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_100_sss_sss	(s is not equal to 0)	[BVS.S <label>]
JBNVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_100_sss_sss	(s is not equal to 0)	[BVS.S <label>]
JBVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_100_sss_sss	(s is not equal to 0)	[BVS.S <label>]
JBNVS.L <label>					|A|012346|-|---*-|-----|          |0110_100_100_000_110-0100111011111001-{address}	[BVS.S (*)+8;JMP <label>]
JBVC.L <label>					|A|012346|-|---*-|-----|          |0110_100_100_000_110-0100111011111001-{address}	[BVS.S (*)+8;JMP <label>]
BNVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_101_sss_sss	[BVS.S <label>]
JBNVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_101_sss_sss	[BVS.S <label>]
JBVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_101_sss_sss	[BVS.S <label>]
BNVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_110_sss_sss	[BVS.S <label>]
JBNVC.S <label>					|A|012346|-|---*-|-----|          |0110_100_110_sss_sss	[BVS.S <label>]
JBVS.S <label>					|A|012346|-|---*-|-----|          |0110_100_110_sss_sss	[BVS.S <label>]
BNVC.S <label>					|A|01----|-|---*-|-----|          |0110_100_111_sss_sss	[BVS.S <label>]
BNVC.S <label>					|A|--2346|-|---*-|-----|          |0110_100_111_sss_sss	(s is not equal to 63)	[BVS.S <label>]
JBNVC.S <label>					|A|01----|-|---*-|-----|          |0110_100_111_sss_sss	[BVS.S <label>]
JBNVC.S <label>					|A|--2346|-|---*-|-----|          |0110_100_111_sss_sss	(s is not equal to 63)	[BVS.S <label>]
JBVS.S <label>					|A|01----|-|---*-|-----|          |0110_100_111_sss_sss	[BVS.S <label>]
JBVS.S <label>					|A|--2346|-|---*-|-----|          |0110_100_111_sss_sss	(s is not equal to 63)	[BVS.S <label>]
BNVC.L <label>					|A|--2346|-|---*-|-----|          |0110_100_111_111_111-{offset}	[BVS.L <label>]
BNMI.W <label>					|A|012346|-|-*---|-----|          |0110_101_000_000_000-{offset}	[BPL.W <label>]
JBNMI.W <label>					|A|012346|-|-*---|-----|          |0110_101_000_000_000-{offset}	[BPL.W <label>]
JBPL.W <label>					|A|012346|-|-*---|-----|          |0110_101_000_000_000-{offset}	[BPL.W <label>]
BNMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_000_sss_sss	(s is not equal to 0)	[BPL.S <label>]
JBNMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_000_sss_sss	(s is not equal to 0)	[BPL.S <label>]
JBPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_000_sss_sss	(s is not equal to 0)	[BPL.S <label>]
JBMI.L <label>					|A|012346|-|-*---|-----|          |0110_101_000_000_110-0100111011111001-{address}	[BPL.S (*)+8;JMP <label>]
JBNPL.L <label>					|A|012346|-|-*---|-----|          |0110_101_000_000_110-0100111011111001-{address}	[BPL.S (*)+8;JMP <label>]
BNMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_001_sss_sss	[BPL.S <label>]
JBNMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_001_sss_sss	[BPL.S <label>]
JBPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_001_sss_sss	[BPL.S <label>]
BNMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_010_sss_sss	[BPL.S <label>]
JBNMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_010_sss_sss	[BPL.S <label>]
JBPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_010_sss_sss	[BPL.S <label>]
BNMI.S <label>					|A|01----|-|-*---|-----|          |0110_101_011_sss_sss	[BPL.S <label>]
BNMI.S <label>					|A|--2346|-|-*---|-----|          |0110_101_011_sss_sss	(s is not equal to 63)	[BPL.S <label>]
JBNMI.S <label>					|A|01----|-|-*---|-----|          |0110_101_011_sss_sss	[BPL.S <label>]
JBNMI.S <label>					|A|--2346|-|-*---|-----|          |0110_101_011_sss_sss	(s is not equal to 63)	[BPL.S <label>]
JBPL.S <label>					|A|01----|-|-*---|-----|          |0110_101_011_sss_sss	[BPL.S <label>]
JBPL.S <label>					|A|--2346|-|-*---|-----|          |0110_101_011_sss_sss	(s is not equal to 63)	[BPL.S <label>]
BNMI.L <label>					|A|--2346|-|-*---|-----|          |0110_101_011_111_111-{offset}	[BPL.L <label>]
BNPL.W <label>					|A|012346|-|-*---|-----|          |0110_101_100_000_000-{offset}	[BMI.W <label>]
JBMI.W <label>					|A|012346|-|-*---|-----|          |0110_101_100_000_000-{offset}	[BMI.W <label>]
JBNPL.W <label>					|A|012346|-|-*---|-----|          |0110_101_100_000_000-{offset}	[BMI.W <label>]
BNPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_100_sss_sss	(s is not equal to 0)	[BMI.S <label>]
JBMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_100_sss_sss	(s is not equal to 0)	[BMI.S <label>]
JBNPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_100_sss_sss	(s is not equal to 0)	[BMI.S <label>]
JBNMI.L <label>					|A|012346|-|-*---|-----|          |0110_101_100_000_110-0100111011111001-{address}	[BMI.S (*)+8;JMP <label>]
JBPL.L <label>					|A|012346|-|-*---|-----|          |0110_101_100_000_110-0100111011111001-{address}	[BMI.S (*)+8;JMP <label>]
BNPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_101_sss_sss	[BMI.S <label>]
JBMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_101_sss_sss	[BMI.S <label>]
JBNPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_101_sss_sss	[BMI.S <label>]
BNPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_110_sss_sss	[BMI.S <label>]
JBMI.S <label>					|A|012346|-|-*---|-----|          |0110_101_110_sss_sss	[BMI.S <label>]
JBNPL.S <label>					|A|012346|-|-*---|-----|          |0110_101_110_sss_sss	[BMI.S <label>]
BNPL.S <label>					|A|01----|-|-*---|-----|          |0110_101_111_sss_sss	[BMI.S <label>]
BNPL.S <label>					|A|--2346|-|-*---|-----|          |0110_101_111_sss_sss	(s is not equal to 63)	[BMI.S <label>]
JBMI.S <label>					|A|01----|-|-*---|-----|          |0110_101_111_sss_sss	[BMI.S <label>]
JBMI.S <label>					|A|--2346|-|-*---|-----|          |0110_101_111_sss_sss	(s is not equal to 63)	[BMI.S <label>]
JBNPL.S <label>					|A|01----|-|-*---|-----|          |0110_101_111_sss_sss	[BMI.S <label>]
JBNPL.S <label>					|A|--2346|-|-*---|-----|          |0110_101_111_sss_sss	(s is not equal to 63)	[BMI.S <label>]
BNPL.L <label>					|A|--2346|-|-*---|-----|          |0110_101_111_111_111-{offset}	[BMI.L <label>]
BNLT.W <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_000_000-{offset}	[BGE.W <label>]
JBGE.W <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_000_000-{offset}	[BGE.W <label>]
JBNLT.W <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_000_000-{offset}	[BGE.W <label>]
BNLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_sss_sss	(s is not equal to 0)	[BGE.S <label>]
JBGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_sss_sss	(s is not equal to 0)	[BGE.S <label>]
JBNLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_sss_sss	(s is not equal to 0)	[BGE.S <label>]
JBLT.L <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_000_110-0100111011111001-{address}	[BGE.S (*)+8;JMP <label>]
JBNGE.L <label>					|A|012346|-|-*-*-|-----|          |0110_110_000_000_110-0100111011111001-{address}	[BGE.S (*)+8;JMP <label>]
BNLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_001_sss_sss	[BGE.S <label>]
JBGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_001_sss_sss	[BGE.S <label>]
JBNLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_001_sss_sss	[BGE.S <label>]
BNLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_010_sss_sss	[BGE.S <label>]
JBGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_010_sss_sss	[BGE.S <label>]
JBNLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_010_sss_sss	[BGE.S <label>]
BNLT.S <label>					|A|01----|-|-*-*-|-----|          |0110_110_011_sss_sss	[BGE.S <label>]
BNLT.S <label>					|A|--2346|-|-*-*-|-----|          |0110_110_011_sss_sss	(s is not equal to 63)	[BGE.S <label>]
JBGE.S <label>					|A|01----|-|-*-*-|-----|          |0110_110_011_sss_sss	[BGE.S <label>]
JBGE.S <label>					|A|--2346|-|-*-*-|-----|          |0110_110_011_sss_sss	(s is not equal to 63)	[BGE.S <label>]
JBNLT.S <label>					|A|01----|-|-*-*-|-----|          |0110_110_011_sss_sss	[BGE.S <label>]
JBNLT.S <label>					|A|--2346|-|-*-*-|-----|          |0110_110_011_sss_sss	(s is not equal to 63)	[BGE.S <label>]
BNLT.L <label>					|A|--2346|-|-*-*-|-----|          |0110_110_011_111_111-{offset}	[BGE.L <label>]
BNGE.W <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_000_000-{offset}	[BLT.W <label>]
JBLT.W <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_000_000-{offset}	[BLT.W <label>]
JBNGE.W <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_000_000-{offset}	[BLT.W <label>]
BNGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_sss_sss	(s is not equal to 0)	[BLT.S <label>]
JBLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_sss_sss	(s is not equal to 0)	[BLT.S <label>]
JBNGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_sss_sss	(s is not equal to 0)	[BLT.S <label>]
JBGE.L <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_000_110-0100111011111001-{address}	[BLT.S (*)+8;JMP <label>]
JBNLT.L <label>					|A|012346|-|-*-*-|-----|          |0110_110_100_000_110-0100111011111001-{address}	[BLT.S (*)+8;JMP <label>]
BNGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_101_sss_sss	[BLT.S <label>]
JBLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_101_sss_sss	[BLT.S <label>]
JBNGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_101_sss_sss	[BLT.S <label>]
BNGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_110_sss_sss	[BLT.S <label>]
JBLT.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_110_sss_sss	[BLT.S <label>]
JBNGE.S <label>					|A|012346|-|-*-*-|-----|          |0110_110_110_sss_sss	[BLT.S <label>]
BNGE.S <label>					|A|01----|-|-*-*-|-----|          |0110_110_111_sss_sss	[BLT.S <label>]
BNGE.S <label>					|A|--2346|-|-*-*-|-----|          |0110_110_111_sss_sss	(s is not equal to 63)	[BLT.S <label>]
JBLT.S <label>					|A|01----|-|-*-*-|-----|          |0110_110_111_sss_sss	[BLT.S <label>]
JBLT.S <label>					|A|--2346|-|-*-*-|-----|          |0110_110_111_sss_sss	(s is not equal to 63)	[BLT.S <label>]
JBNGE.S <label>					|A|01----|-|-*-*-|-----|          |0110_110_111_sss_sss	[BLT.S <label>]
JBNGE.S <label>					|A|--2346|-|-*-*-|-----|          |0110_110_111_sss_sss	(s is not equal to 63)	[BLT.S <label>]
BNGE.L <label>					|A|--2346|-|-*-*-|-----|          |0110_110_111_111_111-{offset}	[BLT.L <label>]
BNLE.W <label>					|A|012346|-|-***-|-----|          |0110_111_000_000_000-{offset}	[BGT.W <label>]
JBGT.W <label>					|A|012346|-|-***-|-----|          |0110_111_000_000_000-{offset}	[BGT.W <label>]
JBNLE.W <label>					|A|012346|-|-***-|-----|          |0110_111_000_000_000-{offset}	[BGT.W <label>]
BNLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_000_sss_sss	(s is not equal to 0)	[BGT.S <label>]
JBGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_000_sss_sss	(s is not equal to 0)	[BGT.S <label>]
JBNLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_000_sss_sss	(s is not equal to 0)	[BGT.S <label>]
JBLE.L <label>					|A|012346|-|-***-|-----|          |0110_111_000_000_110-0100111011111001-{address}	[BGT.S (*)+8;JMP <label>]
JBNGT.L <label>					|A|012346|-|-***-|-----|          |0110_111_000_000_110-0100111011111001-{address}	[BGT.S (*)+8;JMP <label>]
BNLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_001_sss_sss	[BGT.S <label>]
JBGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_001_sss_sss	[BGT.S <label>]
JBNLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_001_sss_sss	[BGT.S <label>]
BNLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_010_sss_sss	[BGT.S <label>]
JBGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_010_sss_sss	[BGT.S <label>]
JBNLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_010_sss_sss	[BGT.S <label>]
BNLE.S <label>					|A|01----|-|-***-|-----|          |0110_111_011_sss_sss	[BGT.S <label>]
BNLE.S <label>					|A|--2346|-|-***-|-----|          |0110_111_011_sss_sss	(s is not equal to 63)	[BGT.S <label>]
JBGT.S <label>					|A|01----|-|-***-|-----|          |0110_111_011_sss_sss	[BGT.S <label>]
JBGT.S <label>					|A|--2346|-|-***-|-----|          |0110_111_011_sss_sss	(s is not equal to 63)	[BGT.S <label>]
JBNLE.S <label>					|A|01----|-|-***-|-----|          |0110_111_011_sss_sss	[BGT.S <label>]
JBNLE.S <label>					|A|--2346|-|-***-|-----|          |0110_111_011_sss_sss	(s is not equal to 63)	[BGT.S <label>]
BNLE.L <label>					|A|--2346|-|-***-|-----|          |0110_111_011_111_111-{offset}	[BGT.L <label>]
BNGT.W <label>					|A|012346|-|-***-|-----|          |0110_111_100_000_000-{offset}	[BLE.W <label>]
JBLE.W <label>					|A|012346|-|-***-|-----|          |0110_111_100_000_000-{offset}	[BLE.W <label>]
JBNGT.W <label>					|A|012346|-|-***-|-----|          |0110_111_100_000_000-{offset}	[BLE.W <label>]
BNGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_100_sss_sss	(s is not equal to 0)	[BLE.S <label>]
JBLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_100_sss_sss	(s is not equal to 0)	[BLE.S <label>]
JBNGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_100_sss_sss	(s is not equal to 0)	[BLE.S <label>]
JBGT.L <label>					|A|012346|-|-***-|-----|          |0110_111_100_000_110-0100111011111001-{address}	[BLE.S (*)+8;JMP <label>]
JBNLE.L <label>					|A|012346|-|-***-|-----|          |0110_111_100_000_110-0100111011111001-{address}	[BLE.S (*)+8;JMP <label>]
BNGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_101_sss_sss	[BLE.S <label>]
JBLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_101_sss_sss	[BLE.S <label>]
JBNGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_101_sss_sss	[BLE.S <label>]
BNGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_110_sss_sss	[BLE.S <label>]
JBLE.S <label>					|A|012346|-|-***-|-----|          |0110_111_110_sss_sss	[BLE.S <label>]
JBNGT.S <label>					|A|012346|-|-***-|-----|          |0110_111_110_sss_sss	[BLE.S <label>]
BNGT.S <label>					|A|01----|-|-***-|-----|          |0110_111_111_sss_sss	[BLE.S <label>]
BNGT.S <label>					|A|--2346|-|-***-|-----|          |0110_111_111_sss_sss	(s is not equal to 63)	[BLE.S <label>]
JBLE.S <label>					|A|01----|-|-***-|-----|          |0110_111_111_sss_sss	[BLE.S <label>]
JBLE.S <label>					|A|--2346|-|-***-|-----|          |0110_111_111_sss_sss	(s is not equal to 63)	[BLE.S <label>]
JBNGT.S <label>					|A|01----|-|-***-|-----|          |0110_111_111_sss_sss	[BLE.S <label>]
JBNGT.S <label>					|A|--2346|-|-***-|-----|          |0110_111_111_sss_sss	(s is not equal to 63)	[BLE.S <label>]
BNGT.L <label>					|A|--2346|-|-***-|-----|          |0110_111_111_111_111-{offset}	[BLE.L <label>]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
IOCS <name>					|A|012346|-|UUUUU|UUUUU|          |0111_000_0dd_ddd_ddd-0100111001001111	[MOVEQ.L #<data>,D0;TRAP #15]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
SUB.W <ea>,Aq					|A|012346|-|-----|-----|DAM+-WXZPI|1001_qqq_011_mmm_rrr	[SUBA.W <ea>,Aq]
CLR.W Ar					|A|012346|-|-----|-----| A        |1001_rrr_011_001_rrr	[SUBA.W Ar,Ar]
SUB.L <ea>,Aq					|A|012346|-|-----|-----|DAM+-WXZPI|1001_qqq_111_mmm_rrr	[SUBA.L <ea>,Aq]
CLR.L Ar					|A|012346|-|-----|-----| A        |1001_rrr_111_001_rrr	[SUBA.L Ar,Ar]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
SXCALL <name>					|A|012346|-|UUUUU|*****|          |1010_0dd_ddd_ddd_ddd	[ALINE #<data>]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
CMP.W <ea>,Aq					|A|012346|-|-UUUU|-****|DAM+-WXZPI|1011_qqq_011_mmm_rrr	[CMPA.W <ea>,Aq]
CMP.L <ea>,Aq					|A|012346|-|-UUUU|-****|DAM+-WXZPI|1011_qqq_111_mmm_rrr	[CMPA.L <ea>,Aq]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ADD.W <ea>,Aq					|A|012346|-|-----|-----|DAM+-WXZPI|1101_qqq_011_mmm_rrr	[ADDA.W <ea>,Aq]
ADD.L <ea>,Aq					|A|012346|-|-----|-----|DAM+-WXZPI|1101_qqq_111_mmm_rrr	[ADDA.L <ea>,Aq]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
ASR.B Dr					|A|012346|-|UUUUU|***0*|          |1110_001_000_000_rrr	[ASR.B #1,Dr]
LSR.B Dr					|A|012346|-|UUUUU|***0*|          |1110_001_000_001_rrr	[LSR.B #1,Dr]
ROXR.B Dr					|A|012346|-|*UUUU|***0*|          |1110_001_000_010_rrr	[ROXR.B #1,Dr]
ROR.B Dr					|A|012346|-|-UUUU|-**0*|          |1110_001_000_011_rrr	[ROR.B #1,Dr]
ASR.W Dr					|A|012346|-|UUUUU|***0*|          |1110_001_001_000_rrr	[ASR.W #1,Dr]
LSR.W Dr					|A|012346|-|UUUUU|***0*|          |1110_001_001_001_rrr	[LSR.W #1,Dr]
ROXR.W Dr					|A|012346|-|*UUUU|***0*|          |1110_001_001_010_rrr	[ROXR.W #1,Dr]
ROR.W Dr					|A|012346|-|-UUUU|-**0*|          |1110_001_001_011_rrr	[ROR.W #1,Dr]
ASR.L Dr					|A|012346|-|UUUUU|***0*|          |1110_001_010_000_rrr	[ASR.L #1,Dr]
LSR.L Dr					|A|012346|-|UUUUU|***0*|          |1110_001_010_001_rrr	[LSR.L #1,Dr]
ROXR.L Dr					|A|012346|-|*UUUU|***0*|          |1110_001_010_010_rrr	[ROXR.L #1,Dr]
ROR.L Dr					|A|012346|-|-UUUU|-**0*|          |1110_001_010_011_rrr	[ROR.L #1,Dr]
ASL.B Dr					|A|012346|-|UUUUU|*****|          |1110_001_100_000_rrr	[ASL.B #1,Dr]
LSL.B Dr					|A|012346|-|UUUUU|***0*|          |1110_001_100_001_rrr	[LSL.B #1,Dr]
ROXL.B Dr					|A|012346|-|*UUUU|***0*|          |1110_001_100_010_rrr	[ROXL.B #1,Dr]
ROL.B Dr					|A|012346|-|-UUUU|-**0*|          |1110_001_100_011_rrr	[ROL.B #1,Dr]
ASL.W Dr					|A|012346|-|UUUUU|*****|          |1110_001_101_000_rrr	[ASL.W #1,Dr]
LSL.W Dr					|A|012346|-|UUUUU|***0*|          |1110_001_101_001_rrr	[LSL.W #1,Dr]
ROXL.W Dr					|A|012346|-|*UUUU|***0*|          |1110_001_101_010_rrr	[ROXL.W #1,Dr]
ROL.W Dr					|A|012346|-|-UUUU|-**0*|          |1110_001_101_011_rrr	[ROL.W #1,Dr]
ASL.L Dr					|A|012346|-|UUUUU|*****|          |1110_001_110_000_rrr	[ASL.L #1,Dr]
LSL.L Dr					|A|012346|-|UUUUU|***0*|          |1110_001_110_001_rrr	[LSL.L #1,Dr]
ROXL.L Dr					|A|012346|-|*UUUU|***0*|          |1110_001_110_010_rrr	[ROXL.L #1,Dr]
ROL.L Dr					|A|012346|-|-UUUU|-**0*|          |1110_001_110_011_rrr	[ROL.L #1,Dr]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode
                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
FDBRA Dr,<label>				|A|--CC4S|-|-----|-----|          |1111_001_001_001_rrr-0000000000000000-{offset}	[FDBF Dr,<label>]
FNOP						|A|--CC46|-|-----|-----|          |1111_001_010_000_000-0000000000000000	[FBF.W (*)+2]
FBRA.W <label>					|A|--CC46|-|-----|-----|          |1111_001_010_001_111-{offset}	[FBT.W <label>]
FBRA.L <label>					|A|--CC46|-|-----|-----|          |1111_001_011_001_111-{offset}	[FBT.L <label>]
FPACK <data>					|A|012346|-|UUUUU|*****|          |1111_111_0dd_ddd_ddd	[FLINE #<data>]
DOS <data>					|A|012346|-|UUUUU|UUUUU|          |1111_111_1dd_ddd_ddd	[FLINE #<data>]
------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------
XXXXXXXXXX



my $COMMENT = <<'XXXXXXXXXX';
ADDA.W <ea>,Aq
  ソースを符号拡張してロングで加算する

ADDQ.W #<data>,Ar
  ソースを符号拡張してロングで加算する

ASL.B #<data>,Dr
ASL.B Dq,Dr
  算術左シフトバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*00 Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................ｲｳｴｵｶｷｸ0 ｱｲ**ｱ Z=ｲｳｴｵｶｷｸ==0,V=ｱｲ!=0/-1
     :
     7 ........................ｸ0000000 ｷｸ**ｷ Z=ｸ==0,V=ｱｲｳｴｵｶｷｸ!=0/-1
     8 ........................00000000 ｸ01*ｸ V=ｱｲｳｴｵｶｷｸ!=0
     9 ........................00000000 001*0 V=ｱｲｳｴｵｶｷｸ!=0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  ASRで元に戻せないときセット。他はクリア
    C  countが0のときクリア。他は最後に押し出されたビット

ASL.W #<data>,Dr
ASL.W Dq,Dr
ASL.W <ea>
  算術左シフトワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ0 ｱｲ**ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0,V=ｱｲ!=0/-1
     :
    15 ................ﾀ000000000000000 ｿﾀ**ｿ Z=ﾀ==0,V=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ!=0/-1
    16 ................0000000000000000 ﾀ01*ﾀ V=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ!=0
    17 ................0000000000000000 001*0 V=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ!=0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  ASRで元に戻せないときセット。他はクリア
    C  countが0のときクリア。他は最後に押し出されたビット

ASL.L #<data>,Dr
ASL.L Dq,Dr
  算術左シフトロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ**0 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ0 ｱｲ**ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0,V=ｱｲ!=0/-1
     :
    31 ﾐ0000000000000000000000000000000 ﾏﾐ**ﾏ Z=ﾐ==0,V=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ!=0/-1
    32 00000000000000000000000000000000 ﾐ01*ﾐ V=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ!=0
    33 00000000000000000000000000000000 001*0 V=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ!=0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  ASRで元に戻せないときセット。他はクリア
    C  countが0のときクリア。他は最後に押し出されたビット

ASR.B #<data>,Dr
ASR.B Dq,Dr
  算術右シフトバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*00 Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................ｱｱｲｳｴｵｶｷ ｸｱ*0ｸ Z=ｱｲｳｴｵｶｷ==0
     2 ........................ｱｱｱｲｳｴｵｶ ｷｱ*0ｷ Z=ｱｲｳｴｵｶ==0
     3 ........................ｱｱｱｱｲｳｴｵ ｶｱ*0ｶ Z=ｱｲｳｴｵ==0
     4 ........................ｱｱｱｱｱｲｳｴ ｵｱ*0ｵ Z=ｱｲｳｴ==0
     5 ........................ｱｱｱｱｱｱｲｳ ｴｱ*0ｴ Z=ｱｲｳ==0
     6 ........................ｱｱｱｱｱｱｱｲ ｳｱ*0ｳ Z=ｱｲ==0
     7 ........................ｱｱｱｱｱｱｱｱ ｲｱ*0ｲ Z=ｱ==0
     8 ........................ｱｱｱｱｱｱｱｱ ｱｱ*0ｱ Z=ｱ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

ASR.W #<data>,Dr
ASR.W Dq,Dr
ASR.W <ea>
  算術右シフトワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................ｱｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ ﾀｱ*0ﾀ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ==0
     :
    15 ................ｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱ ｲｱ*0ｲ Z=ｱ==0
    16 ................ｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱ ｱｱ*0ｱ Z=ｱ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

ASR.L #<data>,Dr
ASR.L Dq,Dr
  算術右シフトロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 ｱｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ ﾐｱ*0ﾐ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ==0
     :
    31 ｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱ ｲｱ*0ｲ Z=ｱ==0
    32 ｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱ ｱｱ*0ｱ Z=ｱ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

BITREV.L Dr
  Drのビットの並びを逆順にする。CCRは変化しない

BYTEREV.L Dr
  Drのバイトの並びを逆順にする。CCRは変化しない

CHK2.B <ea>,Rn
  <ea>から下限と上限をリードしてRnが範囲内か調べる
  CHK2.B <ea>,Anは下限と上限をそれぞれロングに符号拡張してロングで比較する
  Rnが下限または上限と等しいときZをセットする
  Rnが範囲外のときCをセットする。このときCHK instruction例外が発生する
  060ISPのソースは注釈に誤りが多いので注釈ではなくコードを参考にする
  CCR
    X  変化しない
    N  変化しない(M68000PRMでは未定義)
    Z  Rn-LB==0||Rn-LB==UB-LB
    V  変化しない(M68000PRMでは未定義)
    C  Rn-LB>UB-LB(符号なし比較)

CHK2.W <ea>,Rn
  <ea>から下限と上限をリードしてRnが範囲内か調べる
  CHK2.W <ea>,Anは下限と上限をそれぞれロングに符号拡張してロングで比較する
  Rnが下限または上限と等しいときZをセットする
  Rnが範囲外のときCをセットする。このときCHK instruction例外が発生する
  060ISPのソースは注釈に誤りが多いので注釈ではなくコードを参考にする
  CCR
    X  変化しない
    N  変化しない(M68000PRMでは未定義)
    Z  Rn-LB==0||Rn-LB==UB-LB
    V  変化しない(M68000PRMでは未定義)
    C  Rn-LB>UB-LB(符号なし比較)

CHK2.L <ea>,Rn
  <ea>から下限と上限をリードしてRnが範囲内か調べる
  Rnが下限または上限と等しいときZをセットする
  Rnが範囲外のときCをセットする。このときCHK instruction例外が発生する
  060ISPのソースは注釈に誤りが多いので注釈ではなくコードを参考にする
  CCR
    X  変化しない
    N  変化しない(M68000PRMでは未定義)
    Z  Rn-LB==0||Rn-LB==UB-LB
    V  変化しない(M68000PRMでは未定義)
    C  Rn-LB>UB-LB(符号なし比較)

CMP2.B <ea>,Rn
  <ea>から下限と上限をリードしてRnが範囲内か調べる
  CMP2.B <ea>,Anは下限と上限をそれぞれロングに符号拡張してロングで比較する
  Rnが下限または上限と等しいときZをセットする
  Rnが範囲外のときCをセットする
  060ISPのソースは注釈に誤りが多いので注釈ではなくコードを参考にする
  CCR
    X  変化しない
    N  変化しない(M68000PRMでは未定義)
    Z  Rn-LB==0||Rn-LB==UB-LB
    V  変化しない(M68000PRMでは未定義)
    C  Rn-LB>UB-LB(符号なし比較)

CMP2.W <ea>,Rn
  <ea>から下限と上限をリードしてRnが範囲内か調べる
  CMP2.W <ea>,Anは下限と上限をそれぞれロングに符号拡張してロングで比較する
  Rnが下限または上限と等しいときZをセットする
  Rnが範囲外のときCをセットする
  060ISPのソースは注釈に誤りが多いので注釈ではなくコードを参考にする
  CCR
    X  変化しない
    N  変化しない(M68000PRMでは未定義)
    Z  Rn-LB==0||Rn-LB==UB-LB
    V  変化しない(M68000PRMでは未定義)
    C  Rn-LB>UB-LB(符号なし比較)

CMP2.L <ea>,Rn
  <ea>から下限と上限をリードしてRnが範囲内か調べる
  Rnが下限または上限と等しいときZをセットする
  Rnが範囲外のときCをセットする
  060ISPのソースは注釈に誤りが多いので注釈ではなくコードを参考にする
  CCR
    X  変化しない
    N  変化しない(M68000PRMでは未定義)
    Z  Rn-LB==0||Rn-LB==UB-LB
    V  変化しない(M68000PRMでは未定義)
    C  Rn-LB>UB-LB(符号なし比較)

CMPA.W <ea>,Aq
  ソースを符号拡張してロングで比較する

DIVS.W <ea>,Dq
  DIVSの余りの符号は被除数と一致
  M68000PRMでDIVS.Wのアドレッシングモードがデータ可変と書かれているのはデータの間違い

DIVU.W <ea>,Dq
  M68000PRMでDIVU.Wのオーバーフローの条件が16bit符号あり整数と書かれているのは16bit符号なし整数の間違い

DIVS.L <ea>,Dq
  32bit被除数Dq/32bit除数<ea>→32bit商Dq

DIVU.L <ea>,Dq
  32bit被除数Dq/32bit除数<ea>→32bit商Dq

DIVS.L <ea>,Dr:Dq
  64bit被除数Dr:Dq/32bit除数<ea>→32bit余りDr:32bit商Dq
  M68000PRMでDIVS.Lのアドレッシングモードがデータ可変と書かれているのはデータの間違い

DIVU.L <ea>,Dr:Dq
  64bit被除数Dr:Dq/32bit除数<ea>→32bit余りDr:32bit商Dq

DIVSL.L <ea>,Dr:Dq
  32bit被除数Dq/32bit除数<ea>→32bit余りDr:32bit商Dq

DIVUL.L <ea>,Dr:Dq
  32bit被除数Dq/32bit除数<ea>→32bit余りDr:32bit商Dq

FF1.L Dr
  Drの最上位の1のbit31からのオフセットをDrに格納する
  Drが0のときは32になる

LINK.W Ar,#<data>
  PEA.L (Ar);MOVEA.L A7,Ar;ADDA.W #<data>,A7と同じ
  LINK.W A7,#<data>はA7をデクリメントする前の値がプッシュされ、A7に#<data>が加算される

LINK.L Ar,#<data>
  PEA.L (Ar);MOVEA.L A7,Ar;ADDA.L #<data>,A7と同じ
  LINK.L A7,#<data>はA7をデクリメントする前の値がプッシュされ、A7に#<data>が加算される

LSL.B #<data>,Dr
LSL.B Dq,Dr
  論理左シフトバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*00 Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................ｲｳｴｵｶｷｸ0 ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸ==0
     :
     7 ........................ｸ0000000 ｷｸ*0ｷ Z=ｸ==0
     8 ........................00000000 ｸ010ｸ
     9 ........................00000000 00100
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

LSL.W #<data>,Dr
LSL.W Dq,Dr
LSL.W <ea>
  論理左シフトワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ0 ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     :
    15 ................ﾀ000000000000000 ｿﾀ*0ｿ Z=ﾀ==0
    16 ................0000000000000000 ﾀ010ﾀ
    17 ................0000000000000000 00100
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

LSL.L #<data>,Dr
LSL.L Dq,Dr
  論理左シフトロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ0 ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     :
    31 ﾐ0000000000000000000000000000000 ﾏﾐ*0ﾏ Z=ﾐ==0
    32 00000000000000000000000000000000 ﾐ010ﾐ
    33 00000000000000000000000000000000 00100
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

LSR.B #<data>,Dr
LSR.B Dq,Dr
  論理右シフトバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*00 Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................0ｱｲｳｴｵｶｷ ｸ0*0ｸ Z=ｱｲｳｴｵｶｷ==0
     2 ........................00ｱｲｳｴｵｶ ｷ0*0ｷ Z=ｱｲｳｴｵｶ==0
     3 ........................000ｱｲｳｴｵ ｶ0*0ｶ Z=ｱｲｳｴｵ==0
     4 ........................0000ｱｲｳｴ ｵ0*0ｵ Z=ｱｲｳｴ==0
     5 ........................00000ｱｲｳ ｴ0*0ｴ Z=ｱｲｳ==0
     6 ........................000000ｱｲ ｳ0*0ｳ Z=ｱｲ==0
     7 ........................0000000ｱ ｲ0*0ｲ Z=ｱ==0
     8 ........................00000000 ｱ010ｱ
     9 ........................00000000 00100
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

LSR.W #<data>,Dr
LSR.W Dq,Dr
LSR.W <ea>
  論理右シフトワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................0ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ ﾀ0*0ﾀ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ==0
     :
    15 ................000000000000000ｱ ｲ0*0ｲ Z=ｱ==0
    16 ................0000000000000000 ｱ010ｱ
    17 ................0000000000000000 00100
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

LSR.L #<data>,Dr
LSR.L Dq,Dr
  論理右シフトロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 0ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ ﾐ0*0ﾐ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ==0
     :
    31 0000000000000000000000000000000ｱ ｲ0*0ｲ Z=ｱ==0
    32 00000000000000000000000000000000 ｱ010ｱ
    33 00000000000000000000000000000000 00100
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は最後に押し出されたビット

MOVEA.W <ea>,Aq
  ワードデータをロングに符号拡張してAqの全体を更新する

MOVE16 (Ar)+,xxx.L
MOVE16 xxx.L,(Ar)+
MOVE16 (Ar),xxx.L
MOVE16 xxx.L,(Ar)
MOVE16 (Ar)+,(An)+
  アドレスの下位4bitは無視される
  ポストインクリメントで16増えるとき下位4bitは変化しない

MOVES.B <ea>,Rn
  MOVES.B <ea>,DnはDnの最下位バイトだけ更新する
  MOVES.B <ea>,Anはバイトデータをロングに符号拡張してAnの全体を更新する
  SFC=1,2,5,6はアドレス変換あり、SFC=0,3,4はアドレス変換なし、
  SFC=7はCPU空間なのでコプロセッサが割り当てられている領域以外はバスエラーになる

MOVES.B Rn,<ea>
  DFC=1,2,5,6はアドレス変換あり、DFC=0,3,4はアドレス変換なし、
  DFC=7はCPU空間なのでコプロセッサが割り当てられている領域以外はバスエラーになる

MOVES.W <ea>,Rn
  MOVES.W <ea>,DnはDnの下位ワードだけ更新する
  MOVES.W <ea>,Anはワードデータをロングに符号拡張してAnの全体を更新する
  SFC=1,2,5,6はアドレス変換あり、SFC=0,3,4はアドレス変換なし、
  SFC=7はCPU空間なのでコプロセッサが割り当てられている領域以外はバスエラーになる

MOVES.W Rn,<ea>
  DFC=1,2,5,6はアドレス変換あり、DFC=0,3,4はアドレス変換なし、
  DFC=7はCPU空間なのでコプロセッサが割り当てられている領域以外はバスエラーになる

MOVES.L <ea>,Rn
  SFC=1,2,5,6はアドレス変換あり、SFC=0,3,4はアドレス変換なし、
  SFC=7はCPU空間なのでコプロセッサが割り当てられている領域以外はバスエラーになる

MOVES.L Rn,<ea>
  DFC=1,2,5,6はアドレス変換あり、DFC=0,3,4はアドレス変換なし、
  DFC=7はCPU空間なのでコプロセッサが割り当てられている領域以外はバスエラーになる

MVS.B <ea>,Dq
  バイトデータをロングに符号拡張してDqの全体を更新する

MVS.W <ea>,Dq
  ワードデータをロングに符号拡張してDqの全体を更新する

MVZ.B <ea>,Dq
  バイトデータをロングにゼロ拡張してDqの全体を更新する

MVZ.W <ea>,Dq
  ワードデータをロングにゼロ拡張してDqの全体を更新する

PACK Dr,Dq,#<data>
PACK -(Ar),-(Aq),#<data>
  PACK/UNPKは第1オペランドのソースと第2オペランドのデスティネーションのサイズが違う。パックされていない方がワードでされている方がバイト
  10の位を4ビット右または左にシフトする。第3オペランドの補正値はワードでパックされていない方に加算する。CCRは変化しない

PLPAR (Ar)
  ReadだがSFCではなくDFCを使う

ROL.B #<data>,Dr
ROL.B Dq,Dr
  左ローテートバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*00 Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................ｲｳｴｵｶｷｸｱ Xｲ*0ｱ Z=ｱｲｳｴｵｶｷｸ==0
     :
     7 ........................ｸｱｲｳｴｵｶｷ Xｸ*0ｷ Z=ｱｲｳｴｵｶｷｸ==0
     8 ........................ｱｲｳｴｵｶｷｸ Xｱ*0ｸ Z=ｱｲｳｴｵｶｷｸ==0
  CCR
    X  常に変化しない
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は結果の最下位ビット

ROL.W #<data>,Dr
ROL.W Dq,Dr
ROL.W <ea>
  左ローテートワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀｱ Xｲ*0ｱ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     :
    15 ................ﾀｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ Xﾀ*0ｿ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
    16 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*0ﾀ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
  CCR
    X  常に変化しない
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は結果の最下位ビット

ROL.L #<data>,Dr
ROL.L Dq,Dr
  左ローテートロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐｱ Xｲ*0ｱ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     :
    31 ﾐｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ Xﾐ*0ﾏ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
    32 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*0ﾐ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
  CCR
    X  常に変化しない
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は結果の最下位ビット

ROR.B #<data>,Dr
ROR.B Dq,Dr
  右ローテートバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*00 Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................ｸｱｲｳｴｵｶｷ Xｸ*0ｸ Z=ｱｲｳｴｵｶｷｸ==0
     :
     7 ........................ｲｳｴｵｶｷｸｱ Xｲ*0ｲ Z=ｱｲｳｴｵｶｷｸ==0
     8 ........................ｱｲｳｴｵｶｷｸ Xｱ*0ｱ Z=ｱｲｳｴｵｶｷｸ==0
  CCR
    X  常に変化しない
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は結果の最上位ビット

ROR.W #<data>,Dr
ROR.W Dq,Dr
ROR.W <ea>
  右ローテートワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................ﾀｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ Xﾀ*0ﾀ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     :
    15 ................ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀｱ Xｲ*0ｲ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
    16 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*0ｱ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
  CCR
    X  常に変化しない
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は結果の最上位ビット

ROR.L #<data>,Dr
ROR.L Dq,Dr
  右ローテートロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*00 Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 ﾐｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ Xﾐ*0ﾐ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     :
    31 ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐｱ Xｲ*0ｲ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
    32 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*0ｱ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
  CCR
    X  常に変化しない
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときクリア。他は結果の最上位ビット

ROXL.B #<data>,Dr
ROXL.B Dq,Dr
  拡張左ローテートバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*0X Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................ｲｳｴｵｶｷｸX ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸX==0
     2 ........................ｳｴｵｶｷｸXｱ ｲｳ*0ｲ Z=ｱｳｴｵｶｷｸX==0
     :
     7 ........................ｸXｱｲｳｴｵｶ ｷｸ*0ｷ Z=ｱｲｳｴｵｶｸX==0
     8 ........................Xｱｲｳｴｵｶｷ ｸX*0ｸ Z=ｱｲｳｴｵｶｷX==0
     9 ........................ｱｲｳｴｵｶｷｸ Xｱ*0X Z=ｱｲｳｴｵｶｷｸ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときXのコピー。他は最後に押し出されたビット

ROXL.W #<data>,Dr
ROXL.W Dq,Dr
ROXL.W <ea>
  拡張左ローテートワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀX ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀX==0
     2 ................ｳｴｵｶｷｸｹｺｻｼｽｾｿﾀXｱ ｲｳ*0ｲ Z=ｱｳｴｵｶｷｸｹｺｻｼｽｾｿﾀX==0
     :
    15 ................ﾀXｱｲｳｴｵｶｷｸｹｺｻｼｽｾ ｿﾀ*0ｿ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾﾀX==0
    16 ................Xｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ ﾀX*0ﾀ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿX==0
    17 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときXのコピー。他は最後に押し出されたビット

ROXL.L #<data>,Dr
ROXL.L Dq,Dr
  拡張左ローテートロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐX ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐX==0
     2 ｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐXｱ ｲｳ*0ｲ Z=ｱｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐX==0
     :
    31 ﾐXｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎ ﾏﾐ*0ﾏ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾐX==0
    32 Xｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ ﾐX*0ﾐ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏX==0
    33 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときXのコピー。他は最後に押し出されたビット

ROXR.B #<data>,Dr
ROXR.B Dq,Dr
  拡張右ローテートバイト
       ........................ｱｲｳｴｵｶｷｸ XNZVC
     0 ........................ｱｲｳｴｵｶｷｸ Xｱ*0X Z=ｱｲｳｴｵｶｷｸ==0
     1 ........................Xｱｲｳｴｵｶｷ ｸX*0ｸ Z=ｱｲｳｴｵｶｷX==0
     2 ........................ｸXｱｲｳｴｵｶ ｷｸ*0ｷ Z=ｱｲｳｴｵｶｸX==0
     3 ........................ｷｸXｱｲｳｴｵ ｶｷ*0ｶ Z=ｱｲｳｴｵｷｸX==0
     4 ........................ｶｷｸXｱｲｳｴ ｵｶ*0ｵ Z=ｱｲｳｴｶｷｸX==0
     5 ........................ｵｶｷｸXｱｲｳ ｴｵ*0ｴ Z=ｱｲｳｵｶｷｸX==0
     6 ........................ｴｵｶｷｸXｱｲ ｳｴ*0ｳ Z=ｱｲｴｵｶｷｸX==0
     7 ........................ｳｴｵｶｷｸXｱ ｲｳ*0ｲ Z=ｱｳｴｵｶｷｸX==0
     8 ........................ｲｳｴｵｶｷｸX ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸX==0
     9 ........................ｱｲｳｴｵｶｷｸ Xｱ*0X Z=ｱｲｳｴｵｶｷｸ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときXのコピー。他は最後に押し出されたビット

ROXR.W #<data>,Dr
ROXR.W Dq,Dr
ROXR.W <ea>
  拡張右ローテートワード
       ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ XNZVC
     0 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
     1 ................Xｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ ﾀX*0ﾀ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿX==0
     2 ................ﾀXｱｲｳｴｵｶｷｸｹｺｻｼｽｾ ｿﾀ*0ｿ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾﾀX==0
     :
    15 ................ｳｴｵｶｷｸｹｺｻｼｽｾｿﾀXｱ ｲｳ*0ｲ Z=ｱｳｴｵｶｷｸｹｺｻｼｽｾｿﾀX==0
    16 ................ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀX ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀX==0
    17 ................ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときXのコピー。他は最後に押し出されたビット

ROXR.L #<data>,Dr
ROXR.L Dq,Dr
  拡張右ローテートロング
       ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ XNZVC
     0 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
     1 Xｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏ ﾐX*0ﾐ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏX==0
     2 ﾐXｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎ ﾏﾐ*0ﾏ Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾐX==0
     :
    31 ｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐXｱ ｲｳ*0ｲ Z=ｱｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐX==0
    32 ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐX ｱｲ*0ｱ Z=ｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐX==0
    33 ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ Xｱ*0X Z=ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐ==0
  CCR
    X  countが0のとき変化しない。他は最後に押し出されたビット
    N  結果の最上位ビット
    Z  結果が0のときセット。他はクリア
    V  常にクリア
    C  countが0のときXのコピー。他は最後に押し出されたビット

SATS.L Dr
  VがセットされていたらDrを符号が逆で絶対値が最大の値にする(直前のDrに対する演算を飽和演算にする)

STOP #<data>
    1. #<data>をsrに設定する
    2. pcを進める
    3. 以下のいずれかの条件が成立するまで停止する
      3a. トレース
      3b. マスクされているレベルよりも高い割り込み要求
      3c. リセット
  コアと一緒にデバイスを止めるわけにいかないので、ここでは条件が成立するまで同じ命令を繰り返すループ命令として実装する

SUBA.W <ea>,Aq
  ソースを符号拡張してロングで減算する

SUBQ.W #<data>,Ar
  ソースを符号拡張してロングで減算する

UNLK Ar
  MOVEA.L Ar,A7;MOVEA.L (A7)+,Arと同じ
  UNLK A7はMOVEA.L A7,A7;MOVEA.L (A7)+,A7すなわちMOVEA.L (A7),A7と同じ
  ソースオペランドのポストインクリメントはデスティネーションオペランドが評価される前に完了しているとみなされる
    例えばMOVE.L (A0)+,(A0)+はMOVE.L (A0),(4,A0);ADDQ.L #8,A0と同じ
    MOVEA.L (A0)+,A0はポストインクリメントされたA0が(A0)から読み出された値で上書きされるのでMOVEA.L (A0),A0と同じ
  M68000PRMにUNLK Anの動作はAn→SP;(SP)→An;SP+4→SPだと書かれているがこれはn=7の場合に当てはまらない
  余談だが68040の初期のマスクセットはUNLK A7を実行すると固まるらしい

UNPK Dr,Dq,#<data>
UNPK -(Ar),-(Aq),#<data>
  PACK/UNPKは第1オペランドのソースと第2オペランドのデスティネーションのサイズが違う。パックされていない方がワードでされている方がバイト
  10の位を4ビット右または左にシフトする。第3オペランドの補正値はワードでパックされていない方に加算する。CCRは変化しない

XXXXXXXXXX

my $COMMENT_HASH = {};
{
  foreach my $block (split /\n\n/, $COMMENT) {
    foreach my $key (grep /^[^ ]/, split /\n/, $block) {
      $COMMENT_HASH->{$key} = $block;
    }
  }
}



#s = untabify (s)
#  tabをすべて空白にする
#  文字の幅は考慮しない
#GLOBAL
sub untabify {
  my ($s) = @_;
  while ($s =~ s/^([^\t]*)(\t+)/$1 . (' ' x (8 * (length $2) - (7 & length $1)))/egm) {
  }
  $s;
}

#s = tabify (s, p)
#  空白をタブに変換する
#  文字の幅は考慮しない
#GLOBAL
sub tabify {
  my ($s, $p) = @_;
  defined $p or $p = 8;  #タブ幅
  index ($s, "\t") >= 0 and $s = untabify ($s, $p);  #タブをすべて空白にする
  my @s = ();
  foreach my $l (split /(?<=\n)/, $s) {  #各行について
    my @l = ();  #$lを後ろから削って@lに転送する
    while ($l =~ /(?!= )( +)([^ ]*)$/) {  #最後の空白の並びを探す
      push @l, $2;  #最後の空白の並びの右側の空白を含まない部分または""
      $l = $`;  #最後の空白の並びの左側の空白以外で終わっている部分または""
      my $h = length $l;  #最後の空白の並びの先頭の位置
      my $t = $h + length $1;  #最後の空白の並びの末尾の位置
      my $i = int $h / $p;  #先頭のタブブロック
      my $j = int $t / $p;  #末尾のタブブロック
      if ($i == $j) {
        push @l, ' ' x ($t - $h);
      } else {
        push @l, ' ' x ($t % $p);  #端数
        push @l, "\t" x ($j - $i);
      }
    }
    push @l, $l;
    push @s, reverse @l;
  }
  join '', @s;
}

sub untabify1 {
  my ($s) = @_;
  $s =~ s/(?<nottab>[^\t]*)(?<tab>\t+)/$+{'nottab'} . (' ' x (8 - (length ($+{'nottab'}) & 7))) . ('        ' x (length ($+{'tab'}) - 1))/e;
  $s;
}
#sub untabify {
#  my ($s) = @_;
#  $s =~ s/(?<nottab>[^\t]*)(?<tab>\t+)/$+{'nottab'} . (' ' x (8 - (length ($+{'nottab'}) & 7))) . ('        ' x (length ($+{'tab'}) - 1))/eg;
#  $s;
#}

my @data = map {
  my $line = $_;
  $line =~ s/\r?\n$//;
  #$line = untabify ($line);
  $line = untabify1 ($line);
  $line =~ /^.{48}\|.\|......\|.\|.....\|.....\|..........\|...._..._..._..._.../ or die "ERROR:正規表現不一致\n$line\n";
  my $mnemonic = $line =~ /^(?<mnemonic>\w+)/ ? $+{'mnemonic'} : '';
  my $size = $line =~ /^\w+\.(?<size>\w+)/ ? $+{'size'} : '';
  my $operand = $line =~ /^[^ ]+ (?<operand>[^ \|]+)/ ? $+{'operand'} : '';
  my $operands = [];
  {
    my $s = $operand;
    while ($s =~ /^(?:[^,\(\)\[\]\{\}]|\([^\(\)]*\)|\[[^\[\]]*\]|\{[^\{\}]*\})+/) {
      push @$operands, $&;
      $s = $';
      $s =~ /^,/ and $s = $';
    }
    $s eq '' or die $operand;
  }
  my $alias = substr ($line, 49, 1);
  my $mpu = substr ($line, 51, 6);
  my $firstmpu = $mpu =~ /(?<firstmpu>\w)/ ? $+{'firstmpu'} : '';
  my $addressing = substr ($line, 72, 10);
  my $code = $line =~ /^.{83}(?<code>\S+)/ ? $+{'code'} : '';
  $code =~ /^(....)_(...)_(...)_(...)_(...)/ or die "ERROR:第1オペコードの'_'の位置が合わない\n$line\n";
  my $mask = "$1$2$3$4$5";
  $mask =~ s/[^01]/x/g;
  my $bits = $mask;
  $bits =~ tr/01x/010/;  #0,1はそのまま、それ以外を0にする
  $bits = eval "0b$bits";
  $mask =~ tr/01x/110/;  #0,1を1に、それ以外を0にする
  $mask = eval "0b$mask";
  my $tenbits = ($bits & $mask) >> 6;  #マスク済みの上位10bit
  my @tenbitss = ($tenbits);
  my $bitsmin = $bits;
  my $bitsmax = $bits;
  my $sixbits = $bits & 0b111_111;
  my $sixbitsmin = $sixbits;
  my $sixbitsmax = $sixbits;
  my $temp = $code;
  if ($temp =~ s/^(...._..._..._)mmm_rrr/${1}000_000/) {
    if ($addressing =~ /D/) {
      $bitsmin |= 0b0000_000_000_000_000;
      $sixbitsmin = 0b000_000;
    } elsif ($addressing =~ /A/) {
      $bitsmin |= 0b0000_000_000_001_000;
      $sixbitsmin = 0b001_000;
    } elsif ($addressing =~ /M/) {
      $bitsmin |= 0b0000_000_000_010_000;
      $sixbitsmin = 0b010_000;
    } elsif ($addressing =~ /\+/) {
      $bitsmin |= 0b0000_000_000_011_000;
      $sixbitsmin = 0b011_000;
    } elsif ($addressing =~ /\-/) {
      $bitsmin |= 0b0000_000_000_100_000;
      $sixbitsmin = 0b100_000;
    } elsif ($addressing =~ /W/) {
      $bitsmin |= 0b0000_000_000_101_000;
      $sixbitsmin = 0b101_000;
    } elsif ($addressing =~ /X/) {
      $bitsmin |= 0b0000_000_000_110_000;
      $sixbitsmin = 0b110_000;
    } elsif ($addressing =~ /Z/) {
      $bitsmin |= 0b0000_000_000_111_000;
      $sixbitsmin = 0b111_000;
    } elsif ($addressing =~ /P/) {
      $bitsmin |= 0b0000_000_000_111_010;
      $sixbitsmin = 0b111_010;
    } elsif ($addressing =~ /I/) {
      $bitsmin |= 0b0000_000_000_111_100;
      $sixbitsmin = 0b111_100;
    } else {
      die "ERROR:mmm_rrrがあるのにアドレッシングモードがない\n$line\n";
    }
    if ($addressing =~ /I/) {
      $bitsmax |= 0b0000_000_000_111_100;
      $sixbitsmax = 0b111_100;
    } elsif ($addressing =~ /P/) {
      $bitsmax |= 0b0000_000_000_111_011;
      $sixbitsmax = 0b111_011;
    } elsif ($addressing =~ /Z/) {
      $bitsmax |= 0b0000_000_000_111_001;
      $sixbitsmax = 0b111_001;
    } elsif ($addressing =~ /X/) {
      $bitsmax |= 0b0000_000_000_110_111;
      $sixbitsmax = 0b110_111;
    } elsif ($addressing =~ /W/) {
      $bitsmax |= 0b0000_000_000_101_111;
      $sixbitsmax = 0b101_111;
    } elsif ($addressing =~ /\-/) {
      $bitsmax |= 0b0000_000_000_100_111;
      $sixbitsmax = 0b100_111;
    } elsif ($addressing =~ /\+/) {
      $bitsmax |= 0b0000_000_000_011_111;
      $sixbitsmax = 0b011_111;
    } elsif ($addressing =~ /M/) {
      $bitsmax |= 0b0000_000_000_010_111;
      $sixbitsmax = 0b010_111;
    } elsif ($addressing =~ /A/) {
      $bitsmax |= 0b0000_000_000_001_111;
      $sixbitsmax = 0b001_111;
    } elsif ($addressing =~ /D/) {
      $bitsmax |= 0b0000_000_000_000_111;
      $sixbitsmax = 0b000_111;
    } else {
      die "ERROR:mmm_rrrがあるのにアドレッシングモードがない\n$line\n";
    }
  } elsif ($temp =~ s/^(...._..._..._..._)rrr/${1}000/) {
    $addressing =~ /[ZPI]/ and die "ERROR:rrrがあるのにrrrが必要でないアドレッシングモードが書いてある\n$line\n";
    $bitsmin &= ~0b0000_000_000_000_111;
    $bitsmax |= 0b0000_000_000_000_111;
    $sixbitsmin &= ~0b000_111;
    $sixbitsmax |= 0b000_111;
    if ($temp =~ s/^(...._)rrr(_..._..._...)/${1}000${2}/) {  #CLR.wl Ar
      $bitsmin &= ~0b0000_111_000_000_000;
      $bitsmax |= 0b0000_111_000_000_000;
      @tenbitss = map {
        my $t = $_ & ~0b0000_111_000;
        my @t = ();
        foreach my $r (0b000 .. 0b111) {
          push @t, $t | $r << 3; }
        @t;
      } @tenbitss;
    }
  } else {
    $addressing =~ /[-+DAMWX]/ and die "ERROR:rrrがないのにrrrが必要なアドレッシングモードが書いてある\n$line\n";
  }
  if ($temp =~ s/^(...._)qqq(_..._..._...)/${1}000${2}/) {
    $bitsmin &= ~0b0000_111_000_000_000;
    $bitsmax |= 0b0000_111_000_000_000;
    @tenbitss = map {
      my $t = $_ & ~0b0000_111_000;
      my @t = ();
      foreach my $q (0b000 .. 0b111) {
        push @t, $t | $q << 3; }
      @t;
    } @tenbitss;
  }
  if ($temp =~ s/^(...._)ddd_ddd_ddd_ddd/${1}000_000_000_000/) {  #<line 1010 emulator>, <line 1111 emulator>
    $bitsmin &= ~0b0000_111_111_111_111;
    $bitsmax |= 0b0000_111_111_111_111;
    $sixbitsmin = 0b000_000;
    $sixbitsmax = 0b111_111;
    @tenbitss = map {
      my $t = $_ & ~0b0000_111_111;
      my @t = ();
      foreach my $d (0b000_000 .. 0b111_111) {
        push @t, $t | $d; }
      @t;
    } @tenbitss;
  } elsif ($temp =~ s/^(...._.)dd_ddd_ddd_ddd/${1}00_000_000_000/) {  #SXCALL
    $bitsmin &= ~0b0000_011_111_111_111;
    $bitsmax |= 0b0000_011_111_111_111;
    $sixbitsmin = 0b000_000;
    $sixbitsmax = 0b111_111;
    @tenbitss = map {
      my $t = $_ & ~0b0000_011_111;
      my @t = ();
      foreach my $d (0b00_000 .. 0b11_111) {
        push @t, $t | $d; }
      @t;
    } @tenbitss;
  } elsif ($temp =~ s/^(...._..._.)dd_ddd_ddd/${1}00_000_000/) {  #MOVEQなど。qqqと共存する場合がある
    $bitsmin &= ~0b0000_000_011_111_111;
    $bitsmax |= 0b0000_000_011_111_111;
    $sixbitsmin = 0b000_000;
    $sixbitsmax = 0b111_111;
    @tenbitss = map {
      my $t = $_ & ~0b0000_000_011;
      my @t = ();
      foreach my $d (0b00 .. 0b11) {
        push @t, $t | $d; }
      @t;
    } @tenbitss;
  } elsif ($temp =~ s/^(...._..._..._)sss_sss/${1}000_000/) {
    $bitsmin &= ~0b0000_000_000_111_111;
    $bitsmax |= 0b0000_000_000_111_111;
    $sixbitsmin = 0b000_000;
    $sixbitsmax = 0b111_111;
  } elsif ($temp =~ s/^(...._..._..._..)n_nnn/${1}0_000/) {  #RTM Rn
    $bitsmin &= ~0b0000_000_000_001_111;
    $bitsmax |= 0b0000_000_000_001_111;
    $sixbitsmin &= ~0b001_111;
    $sixbitsmax |= 0b001_111;
  } elsif ($temp =~ s/^(...._..._..._..)v_vvv/${1}0_000/) {  #TRAP #<vector>
    $bitsmin &= ~0b0000_000_000_001_111;
    $bitsmax |= 0b0000_000_000_001_111;
    $sixbitsmin &= ~0b001_111;
    $sixbitsmax |= 0b001_111;
  } elsif ($temp =~ s/^(...._..._..._..._)ddd/${1}000/) {  #BKPT #<data>
    $bitsmin &= ~0b0000_000_000_000_111;
    $bitsmax |= 0b0000_000_000_000_111;
    $sixbitsmin &= ~0b000_111;
    $sixbitsmax |= 0b000_111;
  }
  $temp =~ /^[01]{4}(?:_[01]{3}){4}/ or die "ERROR:不明なワイルドカード\n$line\n";
  my $tabified = substr $line, 0, 48;
  #$tabified = tabify ($tabified);
  $tabified =~ s/(?<space> +)$/"\t" x (length ($+{'space'}) + 7 >> 3)/e;  #ニモニックの末尾の空白だけタブにする
  $tabified .= substr $line, 48;
  {
    line => $line,
    tabified => $tabified,
    code => $code,
    mask => $mask,
    bits => $bits,
    tenbits => $tenbits,
    tenbitss => [@tenbitss],
    bitsmin => $bitsmin,
    bitsmax => $bitsmax,
    sixbitsmax => $sixbitsmax,
    sixbitsmin => $sixbitsmin,
    alias => $alias,
    mpu => $mpu,
    firstmpu => $firstmpu,
    mnemonic => $mnemonic,
    size => $size,
    operand => $operand,
    operands => $operands
    }
} grep /^\w/, split /(?<=\n)/, $BASE;

my $SEPARATOR = "------------------------------------------------+-+------+-+-----+-----+----------+-------------------------------------\n";
my $HEAD1     = "                                                | |  MPU | |CCin |CCout|addressing|     1st opcode         2nd opcode\n";
my $HEAD2     = "                           A:alias P:privileged |A|012346|P|XNZVC|XNZVC|DAM+-WXZPI|bbbb_bbb_bbb_bbb_bbb-bbbbbbbbbbbbbbbb\n";

if (1) {
  print "\n";
  print "\n";
  print "\n";
  print "================================================================================\n";
  print "\tHAS060.X添付ドキュメント用(オペコード順)\n";
  print "================================================================================\n";
  my $prev_section = '';
  foreach my $info (sort {  #エイリアス→コード→ニモニック→MPU
    $a->{'alias'} cmp $b->{'alias'} ||
      $a->{'bitsmin'} <=> $b->{'bitsmin'} ||
        $a->{'bitsmax'} <=> $b->{'bitsmax'} ||
          $a->{'code'} cmp $b->{'code'} ||
            $a->{'mnemonic'} cmp $b->{'mnemonic'} ||
              $a->{'firstmpu'} cmp $b->{'firstmpu'} ||
                die "ERROR:比較失敗\n$a->{'line'}\n$b->{'line'}\n"
                } @data) {
    my $section = substr $info->{'code'}, 0, 4;
    if ($prev_section ne $section) {
      $prev_section = $section;
      print $SEPARATOR;
      print $HEAD1;
      print $HEAD2;
      print $SEPARATOR;
    }
    print "$info->{'tabified'}\n";
  }
  print $SEPARATOR;
  print "\n";
}

if (1) {
  print "\n";
  print "\n";
  print "================================================================================\n";
  print "\tHAS060.X添付ドキュメント用(ニモニック順)\n";
  print "================================================================================\n";
  my $prev_section = '';
  foreach my $info (sort {  #ニモニック→コード→エイリアス→MPU
    $a->{'mnemonic'} cmp $b->{'mnemonic'} ||
      $a->{'alias'} cmp $b->{'alias'} ||
        $a->{'bitsmin'} <=> $b->{'bitsmin'} ||
          $a->{'bitsmax'} <=> $b->{'bitsmax'} ||
            $a->{'code'} cmp $b->{'code'} ||
              $a->{'firstmpu'} cmp $b->{'firstmpu'} ||
                die "ERROR:比較失敗\n$a->{'line'}\n$b->{'line'}\n"
                } @data) {
    my $section = substr $info->{'mnemonic'}, 0, 1;
    if ($prev_section ne $section) {
      $prev_section = $section;
      print $SEPARATOR;
      print $HEAD1;
      print $HEAD2;
      print $SEPARATOR;
    }
    print "$info->{'tabified'}\n";
  }
  print $SEPARATOR;
  print "\n";
}

if (1) {
  print "\n";
  print "\n";
  print "\n";
  print "================================================================================\n";
  print "\tアセンブラ用\n";
  print "================================================================================\n";
  my $mnemonic_to_info_array = {};
  my $mnemonic_array = [];
  foreach my $info (sort {  #ニモニック→コード→MPU→エイリアス
    $a->{'mnemonic'} cmp $b->{'mnemonic'} ||
      $a->{'bitsmin'} <=> $b->{'bitsmin'} ||
        $a->{'bitsmax'} <=> $b->{'bitsmax'} ||
          $a->{'code'} cmp $b->{'code'} ||
            $a->{'firstmpu'} cmp $b->{'firstmpu'} ||
              $a->{'alias'} cmp $b->{'alias'} ||
                die "ERROR:比較失敗\n$a->{'line'}\n$b->{'line'}\n"
                } @data) {
    my $mnemonic = $info->{'mnemonic'};
    if (!exists $mnemonic_to_info_array->{$mnemonic}) {
      $mnemonic_to_info_array->{$mnemonic} = [];
      push @$mnemonic_array, $mnemonic;
    }
    push @{$mnemonic_to_info_array->{$mnemonic}}, $info;
  }
  my $prev_section = '';
  foreach my $mnemonic (@$mnemonic_array) {
    my $section = substr $mnemonic, 0, 1;
    if ($prev_section ne $section) {
      $prev_section = $section;
      print "      //$SEPARATOR";
      print "      //$HEAD1";
      print "      //$HEAD2";
      print "      //$SEPARATOR";
    }
    foreach my $info (@{$mnemonic_to_info_array->{$mnemonic}}) {
      my $line = $info->{'line'};
      $line = untabify ($line);
      print "      //$line\n";
    }
    my $lower_mnemonic = lc $mnemonic;
    print "    case \"$lower_mnemonic\":\n";
    print "      break;\n";
    print "\n";
  }
  print "\n";
  foreach my $mnemonic (@$mnemonic_array) {
    my $lower_mnemonic = lc $mnemonic;
    print "    \"$lower_mnemonic,\" +\n";
  }
}

if (1) {
  my $map = {};  #map->{mnemonic}={size=>{b=>1,...},minimum=>minimum,maximum=>maximum}
  for my $info (@data) {
    my $mnemonic = $info->{'mnemonic'};
    $mnemonic =~ tr/A-Z/a-z/;
    my $box = $map->{$mnemonic} // ($map->{$mnemonic} = {
      size => {
        u => '-',
        b => '-',
        w => '-',
        l => '-',
        s => '-',
        d => '-',
        x => '-',
        p => '-',
        q => '-'
        },
      minimum => 99,
      maximum => -1
      });
    my $size = $info->{'size'};
    $size or $size = 'u';
    $size =~ tr/A-Z/a-z/;
    exists $box->{'size'}->{$size} or die $info->{'line'};
    $box->{'size'}->{$size} = $size;
    my $operands = $info->{'operands'};
    my $count = 0 + @$operands;
    $box->{'minimum'} <= $count or $box->{'minimum'} = $count;
    $box->{'maximum'} >= $count or $box->{'maximum'} = $count;
  }
  print "\n";
  print "\n";
  print "\n";
  for my $mnemonic (sort { $a cmp $b } keys %$map) {
    my $box = $map->{$mnemonic};
    my $size = $box->{'size'};
    my $minimum = $box->{'minimum'};
    my $maximum = $box->{'maximum'};
    my $sizetext = join '', map { $size->{$_} } qw(u b w l q s d x p);
    print "    \"$sizetext $minimum $maximum $mnemonic,\" +\n";
  }
}

if (1) {
  foreach my $pair ([0, '0.....'],
                    [1, '.1....'],
                    [2, '..[2C]...'],
                    [3, '...[3C]..'],
                    [4, '....[4S].'],
                    [6, '.....[6S]']) {
    my ($mpunum, $mpurex) = @$pair;
    my @subdata = grep { $_->{'mpu'} =~ /$mpurex/ || $_->{'mpu'} eq '------' } @data;
    #alineとflineを探して一旦取り除く
    #  alineとflineに含まれる命令が1個のgroupにまとめられてしまわないようにする
    my ($alineinfo) = grep { ($_->{'bitsmin'} == 0xa000 && $_->{'bitsmax'} == 0xafff) } @subdata;
    my ($flineinfo) = grep { ($_->{'bitsmin'} == 0xf000 && $_->{'bitsmax'} == 0xffff) } @subdata;
    $alineinfo && $flineinfo or die;
    @subdata = grep {
      !($_->{'bitsmin'} == 0xa000 && $_->{'bitsmax'} == 0xafff ||
        $_->{'bitsmin'} == 0xf000 && $_->{'bitsmax'} == 0xffff) } @subdata;
    #tenbitsとgroupidの対応をtenbits==groupidで初期化する
    my @tenbits_to_groupid = (0 .. 1023);
    my $continue;
    do {
      $continue = 0;
      foreach my $info (@subdata) {
        #同じinfoに含まれるtenbitsのgroupidをその中で最小のものに統一する
        my $groupid = 1024;
        foreach my $tenbits (@{$info->{'tenbitss'}}) {
          $groupid <= $tenbits_to_groupid[$tenbits] or $groupid = $tenbits_to_groupid[$tenbits];
        }
        foreach my $tenbits (@{$info->{'tenbitss'}}) {
          if ($groupid < $tenbits_to_groupid[$tenbits]) {
            $tenbits_to_groupid[$tenbits] = $groupid;
            $continue = 1;
          }
        }
      }
      #変化しなくなるまで繰り返す
    } while ($continue);
    #infoをgroupidで分類する
    my %groupid_to_group = ();
    foreach my $info (@subdata) {
      my $groupid = $tenbits_to_groupid[$info->{'tenbitss'}->[0]];  #このgroupidは不連続
      exists $groupid_to_group{$groupid} or $groupid_to_group{$groupid} = { infos => [] };
      push @{$groupid_to_group{$groupid}->{'infos'}}, $info;
    }
    my @groups = values %groupid_to_group;
    #groupに含まれるすべてのtenbitsのリストを作る
    foreach my $group (@groups) {
      my %tenbits_set = ();
      foreach my $info (@{$group->{'infos'}}) {
        foreach my $tenbits (@{$info->{'tenbitss'}}) {
          $tenbits_set{$tenbits} = 1;
        }
      }
      $group->{'tenbitss'} = [sort { $a <=> $b } keys %tenbits_set];
    }
    #alineとflineのgroupを作る
    #  alineとflineに含まれる命令を除いた残り全部のgroupを作る
    my $alinegroup = { infos => [$alineinfo] };
    my $flinegroup = { infos => [$flineinfo] };
    foreach my $afgroup ($alinegroup, $flinegroup) {
      my $info = $afgroup->{'infos'}->[0];
      my $tenbitsmin = $info->{'tenbits'} == 0xa000 >> 6 ? 0xa000 >> 6 : 0xf000 >> 6;
      my $tenbitsmax = $tenbitsmin + (0x0fff >> 6);
      my %tenbits_set = map { $_ => 1 } $tenbitsmin .. $tenbitsmax;
      foreach my $group (@groups) {
        foreach my $tenbits (@{$group->{'tenbitss'}}) {
          delete $tenbits_set{$tenbits};
        }
      }
      $afgroup->{'tenbitss'} = [sort { $a <=> $b } keys %tenbits_set];
    }
    push @groups, $alinegroup;
    push @groups, $flinegroup;
    #groupに含まれる最小のtenbitsでgroupをソートする
    @groups = sort { $a->{'tenbitss'}->[0] <=> $b->{'tenbitss'}->[0] } @groups;
    #group毎にinfoをソートする
    foreach my $group (@groups) {
      $group->{'infos'} = [sort {  #コードMIN→コードMAX→コード→エイリアス→ニモニック→MPU MIN
        $a->{'tenbitss'}->[0] <=> $b->{'tenbitss'}->[0] ||
          $a->{'tenbitss'}->[$#{$a->{'tenbitss'}}] <=> $b->{'tenbitss'}->[$#{$b->{'tenbitss'}}] ||
            $a->{'sixbitsmin'} <=> $b->{'sixbitsmin'} ||
              $a->{'sixbitsmax'} <=> $b->{'sixbitsmax'} ||
                $a->{'code'} cmp $b->{'code'} ||
                  $a->{'alias'} cmp $b->{'alias'} ||
                    $a->{'mnemonic'} cmp $b->{'mnemonic'} ||
                      $a->{'firstmpu'} cmp $b->{'firstmpu'} ||
                        die "ERROR:比較失敗\n$a->{'line'}\n$b->{'line'}\n"
                        } @{$group->{'infos'}}];
    }
    print "\n";
    print "\n";
    print "\n";
    print "================================================================================\n";
    print "\tエミュレータ用(MC680${mpunum}0命令分岐)\n";
    print "================================================================================\n";
    print "\n";
    print "        irpSwitch:\n";
    print "          switch (XEiJ.regOC >>> 6) {  //第1オペコードの上位10ビット。XEiJ.regOCはゼロ拡張されているので0b1111_111_111&を省略\n";
    print "\n";
    foreach my $group (@groups) {
      my $tenbits0 = $group->{'tenbitss'}->[0];
      if ($tenbits0 == 0b0100_111_001_000_000 >> 6) {  #TRAP/LINK/UNLK/MOVE USP/RESET/NOP/STOP/RTE/RTD/RTS/TRAPV/RTR/MOVEC
        printf "          case 0b%04b_%03b_%03b:\n", $tenbits0 >> 6, $tenbits0 >> 3 & 7, $tenbits0 & 7;
        print "            switch (XEiJ.regOC & 0b111_111) {\n";
        print "\n";
        foreach my $info (@{$group->{'infos'}}) {
          print "              //$SEPARATOR";
          print "              //$HEAD1";
          print "              //$HEAD2";
          print "              //$SEPARATOR";
          my $line = $info->{'line'};
          $line = untabify ($line);
          print "              //$line\n";
          my $sixbitsmin = $info->{'sixbitsmin'};
          my $sixbitsmax = $info->{'sixbitsmax'};
          for (my $sixbits = $sixbitsmin; $sixbits <= $sixbitsmax; $sixbits++) {
            printf "            case 0b%03b_%03b:\n", $sixbits >> 3 & 7, $sixbits & 7;
          }
          print "              break irpSwitch;\n";
          print "\n";
        }
        print "            default:\n";
        print "\n";
        print "            }  //switch XEiJ.regOC & 0b111_111\n";
      } else {
        print "            //$SEPARATOR";
        print "            //$HEAD1";
        print "            //$HEAD2";
        print "            //$SEPARATOR";
        foreach my $info (@{$group->{'infos'}}) {
          my $line = $info->{'line'};
          $line = untabify ($line);
          print "            //$line\n";
        }
        foreach my $tenbits (@{$group->{'tenbitss'}}) {
          printf "          case 0b%04b_%03b_%03b:\n", $tenbits >> 6, $tenbits >> 3 & 7, $tenbits & 7;
        }
      }
      if (!(($tenbits0 & 0b1111_000_011) == 0b0110_000_001 ||
            ($tenbits0 & 0b1111_000_011) == 0b0110_000_010 && $mpunum == 0)) {
        print "            break irpSwitch;\n";
        print "\n";
      }
    }
    print "          default:\n";
    print "\n";
    print "          }  //switch XEiJ.regOC >>> 6\n";
    print "\n";
    print "\n";
    print "\n";
    print "\n";
    print "================================================================================\n";
    print "\tエミュレータ用(MC680${mpunum}0命令処理)\n";
    print "================================================================================\n";
    print "\n";
    foreach my $group (@groups) {
      my $tenbits0 = $group->{'tenbitss'}->[0];
      if ($tenbits0 == 0b0100_111_001_000_000 >> 6) {  #TRAP/LINK/UNLK/MOVE USP/RESET/NOP/STOP/RTE/RTD/RTS/TRAPV/RTR/MOVEC
        foreach my $info (@{$group->{'infos'}}) {
          print "  //$SEPARATOR";
          print "  //$HEAD1";
          print "  //$HEAD2";
          print "  //$SEPARATOR";
          my $line = $info->{'line'};
          $line = untabify ($line);
          print "  //$line\n";
          $line =~ /^(?<key>[^ ](?:[^ ]| (?! ))*)  / or die $line;
          my $key = $+{'key'};
          if (exists $COMMENT_HASH->{$key}) {
            my $block = $COMMENT_HASH->{$key};
            print "  //\n";
            print map { "  //$_\n" } split /\n/, $block;
          }
          print "\n";
        }
      } else {
        print "  //$SEPARATOR";
        print "  //$HEAD1";
        print "  //$HEAD2";
        print "  //$SEPARATOR";
        my $hash = ();
        foreach my $info (@{$group->{'infos'}}) {
          my $line = $info->{'line'};
          $line = untabify ($line);
          print "  //$line\n";
          $line =~ /^(?<key>[^ ](?:[^ ]| (?! ))*)  / or die $line;
          my $key = $+{'key'};
          exists $COMMENT_HASH->{$key} and $hash->{$COMMENT_HASH->{$key}} = 1;
        }
        if (keys %$hash) {
          foreach my $block (sort { $a cmp $b } keys %$hash) {
            print "  //\n";
            print map { "  //$_\n" } split /\n/, $block;
          }
        }
        if (!(($tenbits0 & 0b1111_000_011) == 0b0110_000_001 ||
              ($tenbits0 & 0b1111_000_011) == 0b0110_000_010 && $mpunum == 0)) {
          print "\n";
        }
      }
    }

  }  #for pair
}


__END__


HFSBOOT						|-|012346|-|-----|-----|          |0100_111_000_000_000
HFSINST						|-|012346|-|-----|-----|          |0100_111_000_000_001
HFSSTR						|-|012346|-|-----|-----|          |0100_111_000_000_010
HFSINT						|-|012346|-|-----|-----|          |0100_111_000_000_011


STRLDSR.W #<data>				|-|------|P|*****|*****|          |0100_000_011_100_111-0100011011111100-{data}	(ISA_C)
HALT						|-|------|P|-----|-----|          |0100_101_011_001_000	(ISA_A)
PULSE						|-|------|-|-----|-----|          |0100_101_011_001_100	(ISA_A)
REMU.L <ea>,Dr:Dq				|-|------|-|-UUUU|-***0|D M+-W    |0100_110_001_mmm_rrr-0qqq000000000rrr	(ISA_A, q is not equal to r)
REMS.L <ea>,Dr:Dq				|-|------|-|-UUUU|-***0|D M+-W    |0100_110_001_mmm_rrr-0qqq100000000rrr	(ISA_A, q is not equal to r)
MOV3Q.L #<data>,<ea>				|-|------|-|-UUUU|-**00|DAM+-WXZ  |1010_qqq_101_mmm_rrr	(ISA_B)
INTOUCH (Ar)					|-|------|P|-----|-----|          |1111_010_000_101_rrr	(ISA_B)
WDDATA.B <ea>					|-|------|-|-----|-----|  M+-WXZ  |1111_101_100_mmm_rrr	(ISA_A)
WDDATA.W <ea>					|-|------|-|-----|-----|  M+-WXZ  |1111_101_101_mmm_rrr	(ISA_A)
WDDATA.L <ea>					|-|------|-|-----|-----|  M+-WXZ  |1111_101_110_mmm_rrr	(ISA_A)
WDEBUG.L <ea>					|-|------|P|-----|-----|  M  W    |1111_101_111_mmm_rrr-0000000000000011	(ISA_A)


  //REMU.L <ea>,Dr:Dq
  //  32bit被除数Dq/32bit除数<ea>→32bit余りDr
  //REMS.L <ea>,Dr:Dq
  //  32bit被除数Dq/32bit除数<ea>→32bit余りDr
  //    M68000ファミリのDIV*L.LとColdFireファミリのREM*.Lはオペコードが同じ
  //      DIV*L.Lは余りと商が格納されるがREM*.Lは余りだけが格納されるらしい
